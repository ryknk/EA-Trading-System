#ifndef EA_TRADING_SYSTEM_SYMBOL_BAR_REBUILD_MQH
#define EA_TRADING_SYSTEM_SYMBOL_BAR_REBUILD_MQH

// Custom Symbolのバー履歴が失われたとき（Digits変更等）に、保持されているtickを同じ内容で
// CustomTicksReplaceへ書き戻し、バー履歴を再生成する共用ヘルパー。tickの値は変更しない。
// 月単位で処理する。apply=falseは件数確認のみ。
// 【重要】JP225_HIST・US30_HIST・XAUUSD_HISTの直近月（JP225 2026-02〜08、US30 2026-05〜08、XAUUSD 2026-08）は、
// CopyTicksRange/CopyTicksが実データの約1%（64の倍数件）しか返さず、そのままCustomTicksReplaceで書き戻すとtickが
// 欠落する（2026-09-19実測、tkcが4.7〜41MB→0.07〜0.35MBに縮小）。実行前に必ずapply=falseで件数を確認し、
// tkcファイルをバックアップすること。

datetime RebuildNextMonth(const datetime month_start)
  {
   MqlDateTime parts;
   TimeToStruct(month_start,parts);
   parts.mon++;
   if(parts.mon>12)
     { parts.mon=1; parts.year++; }
   parts.day=1; parts.hour=0; parts.min=0; parts.sec=0;
   return StructToTime(parts);
  }

// tickの読み取りが安定するまで（連続2回同件数）再読み込みする。直近月で、初回の読み取りが実データの
// 約1%しか返さない事象（64の倍数件）があったため（2026-09-19、DECISIONS.md DEC-033）。
// 戻り値: 読み取ったtick件数（<0 = 失敗、0 = 該当なし）。attemptsに要した読み取り回数を返す。
int ReadTicksStable(const string symbol,MqlTick &ticks[],const long from_msc,const long to_msc,
                    const int max_attempts,const int wait_ms,int &attempts)
  {
   int previous=-1;
   int count=-1;
   attempts=0;
   for(int i=0;i<max_attempts;i++)
     {
      attempts++;
      ResetLastError();
      count=CopyTicksRange(symbol,ticks,COPY_TICKS_ALL,(ulong)from_msc,(ulong)to_msc);
      if(count>=0 && count==previous)
         return count;
      previous=count;
      Sleep(wait_ms);
     }
   return -2; // 安定しなかった
  }

// CopyTicksRangeが直近月で一部しか返さない場合の代替として、CopyTicks（開始時刻＋件数指定）を
// 分割して読み、[from_msc,to_msc]の範囲のtickを結合する。戻り値: 読み取った件数（<0 = 失敗）。
int ReadTicksChunked(const string symbol,MqlTick &ticks[],const long from_msc,const long to_msc)
  {
   ArrayResize(ticks,0);
   const int chunk=200000;
   long cursor=from_msc;
   long total=0;
   for(int guard=0;guard<2000;guard++)
     {
      MqlTick part[];
      ResetLastError();
      const int count=CopyTicks(symbol,part,COPY_TICKS_ALL,(ulong)cursor,chunk);
      if(count<0)
         return -1;
      if(count==0)
         break;
      int keep=count;
      while(keep>0 && part[keep-1].time_msc>to_msc)
         keep--;
      if(keep>0)
        {
         ArrayResize(ticks,(int)(total+keep),1000000);
         ArrayCopy(ticks,part,(int)total,0,keep);
         total+=keep;
        }
      if(keep<count)
         break;
      cursor=part[count-1].time_msc+1;
     }
   return (int)total;
  }

// 戻り値: 失敗した月数（-1 = 引数不正）。total_ticksに処理したtick総数を返す。
int RebuildBarsFromTicksRange(const string symbol,const string from_month,const string to_month,
                              const bool apply,long &total_ticks)
  {
   total_ticks=0;
   const datetime first=StringToTime(from_month+".01");
   const datetime last=StringToTime(to_month+".01");
   if(first<=0 || last<first)
     {
      PrintFormat("REBUILD_ABORTED reason=INVALID_MONTH_RANGE from=%s to=%s",from_month,to_month);
      return -1;
     }
   SymbolSelect(symbol,true);
   int failed_months=0;
   for(datetime month=first;month<=last;month=RebuildNextMonth(month))
     {
      const long from_msc=(long)month*1000;
      const long to_msc=(long)RebuildNextMonth(month)*1000-1;
      MqlTick ticks[];
      int attempts=0;
      const int count=ReadTicksStable(symbol,ticks,from_msc,to_msc,20,500,attempts);
      if(count<0)
        {
         PrintFormat("REBUILD_MONTH_FAILED month=%s step=COPY count=%d attempts=%d error=%d",
                     TimeToString(month,TIME_DATE),count,attempts,GetLastError());
         failed_months++;
         continue;
        }
      if(count==0)
        {
         PrintFormat("REBUILD_MONTH_EMPTY month=%s",TimeToString(month,TIME_DATE));
         continue;
        }
      if(!apply)
        {
         MqlTick chunked[];
         const int chunked_count=ReadTicksChunked(symbol,chunked,from_msc,to_msc);
         PrintFormat("REBUILD_DRY_RUN month=%s ticks=%d attempts=%d chunked=%d",TimeToString(month,TIME_DATE),count,attempts,chunked_count);
         total_ticks+=count;
         continue;
        }
      ResetLastError();
      const int replaced=CustomTicksReplace(symbol,from_msc,to_msc,ticks);
      if(replaced<0)
        {
         PrintFormat("REBUILD_MONTH_FAILED month=%s step=REPLACE ticks=%d error=%d",TimeToString(month,TIME_DATE),count,GetLastError());
         failed_months++;
         continue;
        }
      PrintFormat("REBUILD_MONTH_DONE month=%s copied=%d replaced=%d attempts=%d",TimeToString(month,TIME_DATE),count,replaced,attempts);
      total_ticks+=replaced;
     }
   return failed_months;
  }

#endif
