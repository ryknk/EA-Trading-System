#property copyright "EA-Trading-System"
#property strict

// Strategy Tester（Every tick based on real ticks）内で生成されるM1バーを、バイナリファイルへ書き出す診断用Expert。
// 発注・Symbol変更は行わない。terminalのtick読み取りAPIが直近月で一部しか返さないSymbolについて、Testerが全tickから
// 生成するバーを取り出し、BarsFileToolでバー履歴を補正するために使う（DECISIONS.md DEC-033）。
// 出力: Terminal\Common\Files\EaTradingSystem\Diagnostics\<InpOutputFile>（MqlRates配列のバイナリ）。

input string InpOutputFile = "bars-export.bin";
input string InpFrom       = "2026.02.01"; // 出力範囲の開始（この日時以降のバー）
input string InpTo         = "2026.09.01"; // 出力範囲の終了（この日時未満のバー）

MqlRates g_bars[];
int      g_count=0;
datetime g_current_bar=0;
datetime g_from=0;
datetime g_to=0;

int OnInit()
  {
   g_from=StringToTime(InpFrom);
   g_to=StringToTime(InpTo);
   if(g_from<=0 || g_to<=g_from)
      return INIT_PARAMETERS_INCORRECT;
   ArrayResize(g_bars,0,500000);
   return INIT_SUCCEEDED;
  }

void OnTick()
  {
   const datetime bar_time=iTime(_Symbol,PERIOD_M1,0);
   if(bar_time==g_current_bar)
      return;
   if(g_current_bar!=0)
     {
      // 新しいM1バーが始まった時点で、直前に確定したバー（shift=1）を記録する。
      MqlRates closed[];
      if(CopyRates(_Symbol,PERIOD_M1,1,1,closed)==1 && closed[0].time>=g_from && closed[0].time<g_to)
        {
         ArrayResize(g_bars,g_count+1,500000);
         g_bars[g_count]=closed[0];
         g_count++;
        }
     }
   g_current_bar=bar_time;
  }

void OnDeinit(const int reason)
  {
   if(g_count<=0)
     {
      Print("EXPORT_EMPTY bars=0");
      return;
     }
   FolderCreate("EaTradingSystem\\Diagnostics",FILE_COMMON);
   const int handle=FileOpen("EaTradingSystem\\Diagnostics\\"+InpOutputFile,FILE_WRITE|FILE_BIN|FILE_COMMON);
   if(handle==INVALID_HANDLE)
     {
      PrintFormat("EXPORT_FILE_OPEN_FAILED error=%d",GetLastError());
      return;
     }
   const uint written=FileWriteArray(handle,g_bars,0,g_count);
   FileClose(handle);
   PrintFormat("EXPORT_COMPLETED symbol=%s bars=%d written=%u first=%s last=%s",_Symbol,g_count,written,
               TimeToString(g_bars[0].time,TIME_DATE|TIME_MINUTES),TimeToString(g_bars[g_count-1].time,TIME_DATE|TIME_MINUTES));
  }
