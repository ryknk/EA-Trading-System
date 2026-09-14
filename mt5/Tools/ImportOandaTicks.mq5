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
   if(!SymbolSelect(InpSourceSymbol, true))
     {
      PrintFormat("SOURCE_SYMBOL_SELECT_FAILED symbol=%s error=%d", InpSourceSymbol, GetLastError());
     }
   else
     {
      MqlTick t;
      for(int i = 0; i < 20 && !SymbolInfoTick(InpSourceSymbol, t); i++)
         Sleep(200);
      PrintFormat("SOURCE_SYMBOL_READY symbol=%s digits=%d point=%.5f", InpSourceSymbol,
                  (int)SymbolInfoInteger(InpSourceSymbol, SYMBOL_DIGITS),
                  SymbolInfoDouble(InpSourceSymbol, SYMBOL_POINT));
     }
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

// CustomTicksAdd()は原因不明のエラー（本環境ではGetLastError()=5310）で
// 特定バッチが拒否されることがある。1件単位まで再帰的に分割して切り分け、
// 個別tickが最後まで拒否される場合のみそのtickをスキップして継続する
// （数億件規模の投入が1件の不整合データで全体停止しないようにするため）。
long AddTicksChunk(MqlTick &send[], int offset, int cnt, const string &filename, long &skipped)
  {
   if(cnt <= 0)
      return 0;
   MqlTick chunk[];
   ArrayResize(chunk, cnt);
   ArrayCopy(chunk, send, 0, offset, cnt);
   int added = CustomTicksAdd(InpCustomSymbol, chunk);
   if(added >= 0)
      return added;

   if(cnt == 1)
     {
      PrintFormat("CUSTOM_TICKS_ADD_SKIPPED_SINGLE file=%s error=%d time=%s bid=%.5f ask=%.5f",
                  filename, GetLastError(), TimeToString(chunk[0].time, TIME_DATE|TIME_SECONDS), chunk[0].bid, chunk[0].ask);
      skipped++;
      return 0;
     }

   int half = cnt / 2;
   long a = AddTicksChunk(send, offset, half, filename, skipped);
   long b = AddTicksChunk(send, offset + half, cnt - half, filename, skipped);
   return a + b;
  }

bool FlushBatch(MqlTick &batch[], int &count, const string &filename, const long line_no, long &total_ticks, long &skipped_ticks)
  {
   if(count <= 0)
      return true;
   MqlTick send[];
   ArrayResize(send, count);
   ArrayCopy(send, batch, 0, 0, count);
   total_ticks += AddTicksChunk(send, 0, count, filename, skipped_ticks);
   count = 0;
   return true;
  }

bool ImportFile(const string &filename, long &total_ticks, long &skipped_ticks)
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
   long file_skipped_before = skipped_ticks;
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
         FlushBatch(batch, count, filename, line_no, total_ticks, skipped_ticks);
        }
     }
   FlushBatch(batch, count, filename, line_no, total_ticks, skipped_ticks);
   FileClose(handle);
   PrintFormat("FILE_IMPORTED file=%s ticks=%d skipped=%d parse_failures=%d", filename,
               total_ticks - file_ticks_before, skipped_ticks - file_skipped_before, parse_failures);
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
   long skipped = 0;
   ulong start_ms = GetTickCount64();
   for(int i = 0; i < ArraySize(files); i++)
     {
      if(!ImportFile(files[i], total, skipped))
        {
         PrintFormat("IMPORT_ABORTED_AT file=%s files_done=%d total_ticks_so_far=%d", files[i], i, total);
         return;
        }
     }
   ulong elapsed_ms = GetTickCount64() - start_ms;
   PrintFormat("IMPORT_COMPLETED symbol=%s files=%d total_ticks=%d skipped_ticks=%d elapsed_ms=%I64u", InpCustomSymbol, ArraySize(files), total, skipped, elapsed_ms);
  }
