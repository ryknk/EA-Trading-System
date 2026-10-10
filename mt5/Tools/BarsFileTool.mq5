#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// ExportM1BarsEAが書き出したM1バーのバイナリファイルを、Custom Symbolのバー履歴と比較、または取り込む。
// InpMode="compare": 読み取り専用。ファイルのバーとterminalのM1バーを月別に突き合わせて件数・相違を出力する。
// InpMode="import" : InpImportFrom〜InpImportToのバーだけをCustomRatesReplaceで置き換える（tickは変更しない）。
// InpMode="delete" : InpImportFrom〜InpImportToのM1バーだけをCustomRatesDeleteで削除する（tickは変更しない）。
//                    バー履歴がtickと整合しないと、Testerが実tickを受け取れず合成tickで補う事象への対処
//                    （誤ったバーを削除し、Testerに全tickから生成させる、DECISIONS.md DEC-033）。

input string InpMode       = "compare";
input string InpSymbol     = "JP225_HIST";
input string InpInputFile  = "bars-export.bin";
input string InpImportFrom = "2026.02.01"; // importの置換範囲（この日時以降）
input string InpImportTo   = "2026.09.01"; // importの置換範囲（この日時未満）

bool BarsEqual(const MqlRates &a,const MqlRates &b)
  {
   return a.time==b.time && MathAbs(a.open-b.open)<1.0e-9 && MathAbs(a.high-b.high)<1.0e-9 &&
          MathAbs(a.low-b.low)<1.0e-9 && MathAbs(a.close-b.close)<1.0e-9;
  }

bool LoadFile(MqlRates &bars[])
  {
   const int handle=FileOpen("EaTradingSystem\\Diagnostics\\"+InpInputFile,FILE_READ|FILE_BIN|FILE_COMMON);
   if(handle==INVALID_HANDLE)
     {
      PrintFormat("BARS_FILE_OPEN_FAILED error=%d",GetLastError());
      return false;
     }
   const uint count=FileReadArray(handle,bars);
   FileClose(handle);
   PrintFormat("BARS_FILE_LOADED bars=%u",count);
   return count>0;
  }

// terminalのCopyRatesは1回の取得で約10万本までしか返さないため、月単位で取得して突き合わせる。
void CompareBars()
  {
   MqlRates file_bars[];
   if(!LoadFile(file_bars))
      return;
   const int n=ArraySize(file_bars);
   MqlDateTime start_parts;
   TimeToStruct(file_bars[0].time,start_parts);
   start_parts.day=1; start_parts.hour=0; start_parts.min=0; start_parts.sec=0;
   datetime month=StructToTime(start_parts);
   int i=0;
   long total_equal=0,total_diff=0,total_only_file=0,total_only_term=0;
   while(i<n)
     {
      MqlDateTime parts;
      TimeToStruct(month,parts);
      parts.mon++;
      if(parts.mon>12)
        { parts.mon=1; parts.year++; }
      const datetime next_month=StructToTime(parts);
      MqlRates term_bars[];
      ResetLastError();
      const int term_count=CopyRates(InpSymbol,PERIOD_M1,month,next_month-1,term_bars);
      if(term_count<0)
        {
         PrintFormat("BARS_MONTH_FAILED month=%s error=%d",TimeToString(month,TIME_DATE),GetLastError());
         return;
        }
      int t=0;
      int equal=0,diff=0,only_file=0,only_term=0;
      while((i<n && file_bars[i].time<next_month) || t<term_count)
        {
         const datetime never=(datetime)LONG_MAX;
         const datetime ft=(i<n && file_bars[i].time<next_month ? file_bars[i].time : never);
         const datetime tt=(t<term_count ? term_bars[t].time : never);
         if(ft==tt)
           {
            if(BarsEqual(file_bars[i],term_bars[t])) equal++; else diff++;
            i++; t++;
           }
         else if(ft<tt)
           { only_file++; i++; }
         else
           { only_term++; t++; }
        }
      PrintFormat("BARS_MONTH month=%s equal=%d diff=%d only_file=%d only_terminal=%d",
                  TimeToString(month,TIME_DATE),equal,diff,only_file,only_term);
      total_equal+=equal; total_diff+=diff; total_only_file+=only_file; total_only_term+=only_term;
      month=next_month;
     }
   PrintFormat("BARS_COMPARE_COMPLETED equal=%I64d diff=%I64d only_file=%I64d only_terminal=%I64d",
               total_equal,total_diff,total_only_file,total_only_term);
  }

void ImportBars()
  {
   MqlRates file_bars[];
   if(!LoadFile(file_bars))
      return;
   const datetime from=StringToTime(InpImportFrom);
   const datetime to=StringToTime(InpImportTo);
   MqlRates selected[];
   int count=0;
   ArrayResize(selected,0,ArraySize(file_bars));
   for(int i=0;i<ArraySize(file_bars);i++)
     {
      if(file_bars[i].time>=from && file_bars[i].time<to)
        {
         ArrayResize(selected,count+1,ArraySize(file_bars));
         selected[count]=file_bars[i];
         count++;
        }
     }
   if(count<=0)
     {
      Print("BARS_IMPORT_ABORTED reason=NO_BARS_IN_RANGE");
      return;
     }
   ResetLastError();
   const int replaced=CustomRatesReplace(InpSymbol,selected[0].time,selected[count-1].time,selected);
   PrintFormat("BARS_IMPORT_%s symbol=%s selected=%d replaced=%d first=%s last=%s error=%d",
               replaced>=0 ? "COMPLETED" : "FAILED",InpSymbol,count,replaced,
               TimeToString(selected[0].time,TIME_DATE|TIME_MINUTES),TimeToString(selected[count-1].time,TIME_DATE|TIME_MINUTES),GetLastError());
  }

void DeleteBars()
  {
   const datetime from=StringToTime(InpImportFrom);
   const datetime to=StringToTime(InpImportTo);
   if(from<=0 || to<=from)
     {
      Print("BARS_DELETE_ABORTED reason=INVALID_RANGE");
      return;
     }
   ResetLastError();
   const int deleted=CustomRatesDelete(InpSymbol,from,to-1);
   PrintFormat("BARS_DELETE_%s symbol=%s from=%s to=%s deleted=%d error=%d",deleted>=0 ? "COMPLETED" : "FAILED",InpSymbol,
               TimeToString(from,TIME_DATE|TIME_MINUTES),TimeToString(to-1,TIME_DATE|TIME_MINUTES),deleted,GetLastError());
  }

void OnStart()
  {
   bool is_custom=false;
   if(!SymbolExist(InpSymbol,is_custom) || !is_custom)
     {
      PrintFormat("BARS_ABORTED reason=NOT_A_CUSTOM_SYMBOL symbol=%s",InpSymbol);
      return;
     }
   SymbolSelect(InpSymbol,true);
   if(InpMode=="delete")
      DeleteBars();
   else if(InpMode=="import")
      ImportBars();
   else
      CompareBars();
  }
