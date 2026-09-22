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
// true = CustomTicksReplace()で各バッチの時刻範囲を置換して投入する（既定）。
// CustomTicksAdd()は、呼び出しごとに末尾128 tickがMT5に永続化されない（端末再起動後に取得できない）ことを
// 実機で確認したため（0.64%欠落。2026-09-21、docs/tick-data-pipeline.md）。false = 従来のCustomTicksAdd()。
input bool   InpUseReplace   = true;

MqlTick g_batch[];              // 未送信のtick（ファイルをまたいで保持する）
int     g_count = 0;
long    g_last_replaced_to = -1; // これまでに置換した時刻範囲の終端（ms）
bool    g_fallback_logged = false;

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

// chunkをCustom Symbolへ書き込み、受理したtick数（失敗時は負）を返す。
// InpUseReplace時は、chunkの時刻範囲[最小, 最大]を置換する。範囲が直前までの範囲と重なる（入力が時刻順でない）
// 場合は、既に投入したtickを消さないよう従来のCustomTicksAdd()へ切り替える。
int WriteTicks(MqlTick &chunk[])
  {
   if(!InpUseReplace)
      return CustomTicksAdd(InpCustomSymbol, chunk);

   const int n = ArraySize(chunk);
   long from_msc = chunk[0].time_msc;
   long to_msc = chunk[0].time_msc;
   for(int i = 1; i < n; i++)
     {
      from_msc = MathMin(from_msc, chunk[i].time_msc);
      to_msc = MathMax(to_msc, chunk[i].time_msc);
     }
   if(from_msc <= g_last_replaced_to)
     {
      if(!g_fallback_logged)
         PrintFormat("REPLACE_FALLBACK_ADD reason=OVERLAPPING_RANGE from_msc=%I64d last_replaced_to=%I64d", from_msc, g_last_replaced_to);
      g_fallback_logged = true;
      return CustomTicksAdd(InpCustomSymbol, chunk);
     }
   const int written = CustomTicksReplace(InpCustomSymbol, from_msc, to_msc, chunk);
   if(written >= 0)
      g_last_replaced_to = to_msc;
   return written;
  }

// 同一msのtickの途中では分割しない（置換範囲が隣のchunkのtickを消すため）。分割位置が無ければ-1。
int FindSplitPoint(MqlTick &send[], int offset, int cnt)
  {
   int half = cnt / 2;
   if(!InpUseReplace)
      return half;
   for(int i = half; i < cnt; i++)
      if(send[offset + i].time_msc != send[offset + i - 1].time_msc)
         return i;
   for(int i = half - 1; i >= 1; i--)
      if(send[offset + i].time_msc != send[offset + i - 1].time_msc)
         return i;
   return -1;
  }

// 書き込みは原因不明のエラー（本環境ではGetLastError()=5310）で特定バッチが拒否されることがある。
// 1件単位まで再帰的に分割して切り分け、個別tickが最後まで拒否される場合のみそのtickをスキップして継続する
// （数億件規模の投入が1件の不整合データで全体停止しないようにするため）。
long AddTicksChunk(MqlTick &send[], int offset, int cnt, const string &filename, long &skipped)
  {
   if(cnt <= 0)
      return 0;
   MqlTick chunk[];
   ArrayResize(chunk, cnt);
   ArrayCopy(chunk, send, 0, offset, cnt);
   int added = WriteTicks(chunk);
   if(added >= 0)
      return added;

   if(cnt == 1)
     {
      PrintFormat("CUSTOM_TICKS_ADD_SKIPPED_SINGLE file=%s error=%d time=%s bid=%.5f ask=%.5f",
                  filename, GetLastError(), TimeToString(chunk[0].time, TIME_DATE|TIME_SECONDS), chunk[0].bid, chunk[0].ask);
      skipped++;
      return 0;
     }

   int half = FindSplitPoint(send, offset, cnt);
   if(half < 0)
     {
      PrintFormat("CUSTOM_TICKS_ADD_SKIPPED_SAME_MS file=%s error=%d ticks=%d", filename, GetLastError(), cnt);
      skipped += cnt;
      return 0;
     }
   long a = AddTicksChunk(send, offset, half, filename, skipped);
   long b = AddTicksChunk(send, offset + half, cnt - half, filename, skipped);
   return a + b;
  }

// final_flush=false のとき、末尾の同一msのtickは次のバッチへ持ち越す（置換範囲が重ならないようにするため）。
bool FlushBatch(const string &filename, long &total_ticks, long &skipped_ticks, const bool final_flush)
  {
   if(g_count <= 0)
      return true;
   int send_count = g_count;
   if(InpUseReplace && !final_flush)
     {
      int keep = 1;
      while(keep < g_count && g_batch[g_count - 1 - keep].time_msc == g_batch[g_count - 1].time_msc)
         keep++;
      if(keep < g_count)
         send_count = g_count - keep;
     }
   MqlTick send[];
   ArrayResize(send, send_count);
   ArrayCopy(send, g_batch, 0, 0, send_count);
   total_ticks += AddTicksChunk(send, 0, send_count, filename, skipped_ticks);
   const int rest = g_count - send_count;
   for(int i = 0; i < rest; i++)
      g_batch[i] = g_batch[send_count + i];
   g_count = rest;
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
      g_batch[g_count] = tick;
      g_count++;
      if(g_count >= InpBatchSize)
         FlushBatch(filename, total_ticks, skipped_ticks, false);
     }
   FlushBatch(filename, total_ticks, skipped_ticks, false);
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
   ArrayResize(g_batch, InpBatchSize);
   for(int i = 0; i < ArraySize(files); i++)
     {
      if(!ImportFile(files[i], total, skipped))
        {
         PrintFormat("IMPORT_ABORTED_AT file=%s files_done=%d total_ticks_so_far=%d", files[i], i, total);
         return;
        }
     }
   FlushBatch("(final)", total, skipped, true);
   ulong elapsed_ms = GetTickCount64() - start_ms;
   PrintFormat("IMPORT_COMPLETED symbol=%s files=%d total_ticks=%d skipped_ticks=%d elapsed_ms=%I64u", InpCustomSymbol, ArraySize(files), total, skipped, elapsed_ms);
  }
