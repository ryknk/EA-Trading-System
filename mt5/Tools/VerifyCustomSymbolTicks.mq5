#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// Custom Symbolのtick数・最初/最後のtick時刻を数える読み取り専用スクリプト（データの変更は行わない）。
// tick取込パイプライン（tools/tick-data.ps1 verify）が、変換結果（manifest）との突き合わせに使う。
// 時刻はすべてMT5サーバー時刻の時計表示をそのままエポックとしたもの（Importerが投入した値と同じ基準）。

input string InpSymbol      = "USDJPY_HIST"; // 検証するCustom Symbol
input string InpFromDate    = "2020.01.01";  // 開始日時（含む、サーバー時刻）
input string InpToDate      = "2020.02.01";  // 終了日時（含まない、サーバー時刻）
input int    InpWindowHours = 24;            // CopyTicksRange()1回あたりの時間幅（メモリ使用量の上限）

void OnStart()
  {
   if(!SymbolSelect(InpSymbol, true))
     {
      PrintFormat("TICKVERIFY_ABORTED reason=SYMBOL_SELECT_FAILED symbol=%s error=%d", InpSymbol, GetLastError());
      return;
     }

   const datetime from = StringToTime(InpFromDate);
   const datetime to = StringToTime(InpToDate);
   if(from <= 0 || to <= from || InpWindowHours < 1)
     {
      PrintFormat("TICKVERIFY_ABORTED reason=INVALID_RANGE from=%s to=%s", InpFromDate, InpToDate);
      return;
     }

   long total = 0;
   long first_msc = 0;
   long last_msc = 0;
   int windows = 0;
   int failed_windows = 0;
   const long step = (long)InpWindowHours * 3600;

   for(long cursor = (long)from; cursor < (long)to; cursor += step)
     {
      const long window_end = MathMin(cursor + step, (long)to);
      MqlTick ticks[];
      ResetLastError();
      // CopyTicksRangeの範囲は両端を含むため、次の窓との重複を避けて終端を1ms手前にする
      const int copied = CopyTicksRange(InpSymbol, ticks, COPY_TICKS_ALL, (ulong)cursor * 1000, (ulong)window_end * 1000 - 1);
      windows++;
      if(copied < 0)
        {
         failed_windows++;
         PrintFormat("TICKVERIFY_WINDOW_FAILED from=%s error=%d", TimeToString((datetime)cursor, TIME_DATE|TIME_SECONDS), GetLastError());
         continue;
        }
      PrintFormat("TICKVERIFY_WINDOW from=%s ticks=%d", TimeToString((datetime)cursor, TIME_DATE|TIME_SECONDS), copied);
      if(copied == 0)
         continue;
      if(total == 0)
         first_msc = (long)ticks[0].time_msc;
      last_msc = (long)ticks[copied - 1].time_msc;
      total += copied;
     }

   PrintFormat("TICKVERIFY_RESULT symbol=%s ticks=%I64d first_msc=%I64d last_msc=%I64d windows=%d failed_windows=%d",
               InpSymbol, total, first_msc, last_msc, windows, failed_windows);
  }
