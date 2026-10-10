#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// 2つのCustom Symbolのtickを月単位で1件ずつ突き合わせる読み取り専用スクリプト（tickは変更しない）。
// RebuildBarsFromTicks後のtickが書き戻し前のバックアップと一致するかの確認に使う。
// InpMode="create"は、InpSymbolBを複製元InpSymbolAの仕様で空のCustom Symbolとして作成するだけ。
// InpMode="delete"はInpSymbolBだけを削除する（InpSymbolAは削除しない）。

input string InpMode       = "compare";    // compare / create / delete
input string InpSymbolA    = "JP225_HIST"; // 現行データ
input string InpSymbolB    = "JP225_CHK";  // 検証用（バックアップ側）
input string InpFromMonth  = "2020.04";
input string InpToMonth    = "2026.09";

datetime NextMonthStart(const datetime month_start)
  {
   MqlDateTime parts;
   TimeToStruct(month_start,parts);
   parts.mon++;
   if(parts.mon>12)
     { parts.mon=1; parts.year++; }
   parts.day=1; parts.hour=0; parts.min=0; parts.sec=0;
   return StructToTime(parts);
  }

bool TicksEqual(const MqlTick &a,const MqlTick &b)
  {
   return a.time_msc==b.time_msc && a.bid==b.bid && a.ask==b.ask &&
          a.last==b.last && a.volume==b.volume && a.flags==b.flags;
  }

void CompareMonths()
  {
   const datetime first=StringToTime(InpFromMonth+".01");
   const datetime last=StringToTime(InpToMonth+".01");
   if(first<=0 || last<first)
     {
      PrintFormat("CMP_ABORTED reason=INVALID_MONTH_RANGE");
      return;
     }
   SymbolSelect(InpSymbolA,true);
   SymbolSelect(InpSymbolB,true);
   int months=0,equal_months=0,differing_months=0,failed_months=0;
   long total_a=0,total_b=0;
   for(datetime month=first;month<=last;month=NextMonthStart(month))
     {
      const ulong from_msc=(ulong)((long)month*1000);
      const ulong to_msc=(ulong)((long)NextMonthStart(month)*1000-1);
      MqlTick a[],b[];
      ResetLastError();
      const int count_a=CopyTicksRange(InpSymbolA,a,COPY_TICKS_ALL,from_msc,to_msc);
      const int err_a=GetLastError();
      ResetLastError();
      const int count_b=CopyTicksRange(InpSymbolB,b,COPY_TICKS_ALL,from_msc,to_msc);
      const int err_b=GetLastError();
      months++;
      if(count_a<0 || count_b<0)
        {
         PrintFormat("CMP_MONTH_FAILED month=%s count_a=%d err_a=%d count_b=%d err_b=%d",
                     TimeToString(month,TIME_DATE),count_a,err_a,count_b,err_b);
         failed_months++;
         continue;
        }
      total_a+=count_a;
      total_b+=count_b;
      long mismatches=0;
      int first_mismatch=-1;
      const int common=MathMin(count_a,count_b);
      for(int i=0;i<common;i++)
        {
         if(!TicksEqual(a[i],b[i]))
           {
            mismatches++;
            if(first_mismatch<0)
               first_mismatch=i;
           }
        }
      if(count_a==count_b && mismatches==0)
        {
         equal_months++;
         PrintFormat("CMP_MONTH_EQUAL month=%s ticks=%d",TimeToString(month,TIME_DATE),count_a);
        }
      else
        {
         differing_months++;
         PrintFormat("CMP_MONTH_DIFF month=%s count_a=%d count_b=%d mismatched_ticks=%I64d first_mismatch_index=%d",
                     TimeToString(month,TIME_DATE),count_a,count_b,mismatches,first_mismatch);
        }
     }
   PrintFormat("CMP_SUMMARY a=%s b=%s months=%d equal=%d different=%d failed=%d total_a=%I64d total_b=%I64d",
               InpSymbolA,InpSymbolB,months,equal_months,differing_months,failed_months,total_a,total_b);
  }

void OnStart()
  {
   if(InpMode=="create")
     {
      bool is_custom=false;
      if(SymbolExist(InpSymbolB,is_custom))
        {
         PrintFormat("CMP_CREATE_ABORTED reason=ALREADY_EXISTS symbol=%s",InpSymbolB);
         return;
        }
      if(!CustomSymbolCreate(InpSymbolB,"Custom\\EaTradingSystem\\Verify",InpSymbolA))
        {
         PrintFormat("CMP_CREATE_FAILED symbol=%s error=%d",InpSymbolB,GetLastError());
         return;
        }
      PrintFormat("CMP_CREATED symbol=%s",InpSymbolB);
      return;
     }
   if(InpMode=="delete")
     {
      bool is_custom=false;
      if(InpSymbolB==InpSymbolA || !SymbolExist(InpSymbolB,is_custom) || !is_custom)
        {
         PrintFormat("CMP_DELETE_ABORTED symbol=%s",InpSymbolB);
         return;
        }
      SymbolSelect(InpSymbolB,false);
      PrintFormat("CMP_DELETE_%s symbol=%s",CustomSymbolDelete(InpSymbolB) ? "COMPLETED" : "FAILED",InpSymbolB);
      return;
     }
   CompareMonths();
  }
