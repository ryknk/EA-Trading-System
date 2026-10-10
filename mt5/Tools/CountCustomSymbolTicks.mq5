#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// Custom Symbolのtick数を、時刻範囲ごとに数える読み取り専用スクリプト（データの変更は行わない）。
// 範囲はMQL5\Files配下のテキストファイルで渡す。1行 = "from|to|expected"（サーバー時刻、秒精度、fromを含みtoを含まない。
// expectedは期待するtick数で、比較しない場合は空）。tools/reimport-oanda-ticks.ps1 が投入後の件数照合に使う。

input string InpSymbol      = "USDJPY_HIST";
input string InpWindowsFile = "EaTradingSystem\\TickReimport\\windows.txt";

void OnStart()
  {
   if(!SymbolSelect(InpSymbol, true))
     {
      PrintFormat("TICKCOUNT_ABORTED reason=SYMBOL_SELECT_FAILED symbol=%s error=%d", InpSymbol, GetLastError());
      return;
     }
   const int handle = FileOpen(InpWindowsFile, FILE_READ | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE)
     {
      PrintFormat("TICKCOUNT_ABORTED reason=WINDOWS_FILE_OPEN_FAILED path=%s error=%d", InpWindowsFile, GetLastError());
      return;
     }

   int windows = 0;
   while(!FileIsEnding(handle))
     {
      const string line = FileReadString(handle);
      string parts[];
      if(StringSplit(line, '|', parts) != 3)
         continue;
      const long from = (long)StringToTime(parts[0]);
      const long to = (long)StringToTime(parts[1]);
      long total = 0, first_msc = 0, last_msc = 0;
      int failed = 0;
      for(long cursor = from; cursor < to; cursor += 3600)
        {
         const long window_end = MathMin(cursor + 3600, to);
         MqlTick ticks[];
         ResetLastError();
         const int copied = CopyTicksRange(InpSymbol, ticks, COPY_TICKS_ALL, (ulong)cursor * 1000, (ulong)window_end * 1000 - 1);
         if(copied < 0)
           {
            failed++;
            continue;
           }
         if(copied == 0)
            continue;
         if(total == 0)
            first_msc = (long)ticks[0].time_msc;
         last_msc = (long)ticks[copied - 1].time_msc;
         total += copied;
        }
      PrintFormat("TICKCOUNT symbol=%s from=%s to=%s ticks=%I64d expected=%s first_msc=%I64d last_msc=%I64d failed=%d",
                  InpSymbol, parts[0], parts[1], total, parts[2], first_msc, last_msc, failed);
      windows++;
     }
   FileClose(handle);
   PrintFormat("TICKCOUNT_DONE symbol=%s windows=%d", InpSymbol, windows);
  }
