#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// OANDAのtick履歴CSV（タブ区切り: <DATE> <TIME> <BID> <ASK> <LAST> <VOLUME>）を、
// 実Symbolの仕様を複製したCustom Symbolへ投入する。これにより、Broker側のライブキャッシュが
// 保持していない期間についても、Strategy Testerで「Every tick based on real ticks」を実行できる。
//
// 投入元ファイルはMQL5\Files\<InpDataFolder>\配下に置くこと（ダウンロード先フォルダへの
// Junctionで構わない）。ファイル名は昇順の辞書順で処理するため、月次ファイルは
// ソート順が時系列と一致する命名にすること（例: ticks_USDJPY-oj5k_2016-09.csv）。

input string InpSourceSymbol = "USDJPY";                 // 仕様の複製元となる実Symbol
input string InpCustomSymbol = "USDJPY_HIST";             // 作成・投入先のCustom Symbol名
input string InpCustomPath   = "EaTradingSystem\\History"; // Market WatchでのグループPath
input string InpDataFolder   = "EaTradingSystem\\OandaTicks"; // MQL5\Files配下、*.csvを置くフォルダ
input string InpSingleFile   = "";                        // 指定時はこのファイルのみ投入。空ならInpDataFolder内の*.csv全件
input int    InpBatchSize    = 20000;                     // CustomTicksAdd()1回あたりのtick数
input bool   InpResetSymbol  = false;                     // true = 投入前に既存のCustom Symbol履歴を削除する

bool EnsureCustomSymbol()
  {
   bool is_custom = false;
   bool exists = SymbolExist(InpCustomSymbol, is_custom);
   if(exists && InpResetSymbol)
     {
      SymbolSelect(InpCustomSymbol, false); // 削除前にMarket Watchから選択解除しておく必要がある
      if(!CustomSymbolDelete(InpCustomSymbol))
        {
         PrintFormat("CUSTOM_SYMBOL_DELETE_FAILED symbol=%s error=%d", InpCustomSymbol, GetLastError());
         return false;
        }
      exists = false;
      PrintFormat("CUSTOM_SYMBOL_RESET symbol=%s", InpCustomSymbol);
     }
   if(!exists)
     {
      if(!CustomSymbolCreate(InpCustomSymbol, InpCustomPath, InpSourceSymbol))
        {
         PrintFormat("CUSTOM_SYMBOL_CREATE_FAILED symbol=%s origin=%s error=%d", InpCustomSymbol, InpSourceSymbol, GetLastError());
         return false;
        }
      PrintFormat("CUSTOM_SYMBOL_CREATED symbol=%s cloned_from=%s", InpCustomSymbol, InpSourceSymbol);
     }
   if(!SymbolSelect(InpCustomSymbol, true))
     {
      PrintFormat("CUSTOM_SYMBOL_SELECT_FAILED symbol=%s error=%d", InpCustomSymbol, GetLastError());
      return false;
     }
   return true;
  }

bool ParseLine(const string &line, MqlTick &tick)
  {
   string parts[];
   int n = StringSplit(line, '\t', parts);
   if(n < 4)
      return false;

   string date_part = parts[0];
   string time_part = parts[1];
   double bid = StringToDouble(parts[2]);
   double ask = StringToDouble(parts[3]);
   if(bid <= 0.0 || ask <= 0.0 || ask < bid)
      return false;

   int dot = StringFind(time_part, ".");
   int msec = 0;
   string time_no_ms = time_part;
   if(dot >= 0)
     {
      msec = (int)StringToInteger(StringSubstr(time_part, dot + 1));
      time_no_ms = StringSubstr(time_part, 0, dot);
     }
   datetime t = StringToTime(date_part + " " + time_no_ms);
   if(t <= 0)
      return false;

   ZeroMemory(tick);
   tick.time = t;
   tick.time_msc = (long)t * 1000 + msec;
   tick.bid = bid;
   tick.ask = ask;
   tick.last = 0;
   tick.volume = 0;
   tick.flags = TICK_FLAG_BID | TICK_FLAG_ASK;
   return true;
  }

bool FlushBatch(MqlTick &batch[], int &count, const string &filename, const long line_no, long &total_ticks)
  {
   if(count <= 0)
      return true;
   MqlTick send[];
   ArrayResize(send, count);
   ArrayCopy(send, batch, 0, 0, count);
   int added = CustomTicksAdd(InpCustomSymbol, send);
   if(added < 0)
     {
      PrintFormat("CUSTOM_TICKS_ADD_FAILED file=%s line=%d error=%d", filename, line_no, GetLastError());
      return false;
     }
   total_ticks += added;
   count = 0;
   return true;
  }

bool ImportFile(const string &filename, long &total_ticks)
  {
   string path = InpDataFolder + "\\" + filename;
   int handle = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE)
     {
      PrintFormat("FILE_OPEN_FAILED path=%s error=%d", path, GetLastError());
      return false;
     }

   if(!FileIsEnding(handle))
      FileReadString(handle); // ヘッダー行を読み飛ばす

   MqlTick batch[];
   ArrayResize(batch, InpBatchSize);
   int count = 0;
   long file_ticks_before = total_ticks;
   long line_no = 1;
   long parse_failures = 0;

   while(!FileIsEnding(handle))
     {
      string line = FileReadString(handle);
      line_no++;
      if(StringLen(line) == 0)
         continue;
      MqlTick tick;
      if(!ParseLine(line, tick))
        {
         parse_failures++;
         continue;
        }
      batch[count] = tick;
      count++;
      if(count >= InpBatchSize)
        {
         if(!FlushBatch(batch, count, filename, line_no, total_ticks))
           {
            FileClose(handle);
            return false;
           }
        }
     }
   if(!FlushBatch(batch, count, filename, line_no, total_ticks))
     {
      FileClose(handle);
      return false;
     }
   FileClose(handle);
   PrintFormat("FILE_IMPORTED file=%s ticks=%d parse_failures=%d", filename, total_ticks - file_ticks_before, parse_failures);
   return true;
  }

void OnStart()
  {
   if(!EnsureCustomSymbol())
     {
      Print("IMPORT_ABORTED reason=CUSTOM_SYMBOL_SETUP_FAILED");
      return;
     }

   string files[];
   if(StringLen(InpSingleFile) > 0)
     {
      ArrayResize(files, 1);
      files[0] = InpSingleFile;
     }
   else
     {
      string name;
      long search = FileFindFirst(InpDataFolder + "\\*.csv", name);
      if(search == INVALID_HANDLE)
        {
         PrintFormat("NO_FILES_FOUND folder=%s error=%d", InpDataFolder, GetLastError());
         return;
        }
      int n = 0;
      do
        {
         ArrayResize(files, n + 1);
         files[n] = name;
         n++;
        }
      while(FileFindNext(search, name));
      FileFindClose(search);
      ArraySort(files);
     }

   if(ArraySize(files) == 0)
     {
      Print("IMPORT_ABORTED reason=NO_FILES");
      return;
     }

   long total = 0;
   ulong start_ms = GetTickCount64();
   for(int i = 0; i < ArraySize(files); i++)
     {
      if(!ImportFile(files[i], total))
        {
         PrintFormat("IMPORT_ABORTED_AT file=%s files_done=%d total_ticks_so_far=%d", files[i], i, total);
         return;
        }
     }
   ulong elapsed_ms = GetTickCount64() - start_ms;
   PrintFormat("IMPORT_COMPLETED symbol=%s files=%d total_ticks=%d elapsed_ms=%I64u", InpCustomSymbol, ArraySize(files), total, elapsed_ms);
  }
