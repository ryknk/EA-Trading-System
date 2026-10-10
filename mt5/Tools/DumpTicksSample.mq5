#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// 指定期間のtickをCopyTicksRangeで読み、先頭の数件・日別件数・flags等の内訳を出力する読み取り専用スクリプト。
// terminalのtick読み取りAPIが直近月で一部しか返す原因（返されるtickの正体）の調査に使う。

input string InpSymbol = "JP225_HIST";
input string InpFrom   = "2026.02.01";
input string InpTo     = "2026.03.01";
input int    InpRows   = 30;

void OnStart()
  {
   const datetime from=StringToTime(InpFrom);
   const datetime to=StringToTime(InpTo);
   MqlTick ticks[];
   const int count=CopyTicksRange(InpSymbol,ticks,COPY_TICKS_ALL,(ulong)from*1000,(ulong)to*1000);
   PrintFormat("DUMP symbol=%s range=%s..%s count=%d",InpSymbol,InpFrom,InpTo,count);
   if(count<=0)
      return;
   for(int i=0;i<MathMin(InpRows,count);i++)
      PrintFormat("DUMP_ROW i=%d time_msc=%I64d %s bid=%.4f ask=%.4f last=%.4f vol=%I64u vol_real=%.2f flags=%u",
                  i,ticks[i].time_msc,TimeToString(ticks[i].time,TIME_DATE|TIME_SECONDS),
                  ticks[i].bid,ticks[i].ask,ticks[i].last,ticks[i].volume,ticks[i].volume_real,ticks[i].flags);
   // flags・last・volumeの内訳
   int with_last=0,with_volume=0,unsorted=0,dup_time=0;
   uint flag_kinds[8];
   int flag_counts[8];
   ArrayInitialize(flag_counts,0);
   ArrayInitialize(flag_kinds,0);
   int kinds=0;
   for(int i=0;i<count;i++)
     {
      if(ticks[i].last!=0.0) with_last++;
      if(ticks[i].volume!=0) with_volume++;
      if(i>0 && ticks[i].time_msc<ticks[i-1].time_msc) unsorted++;
      if(i>0 && ticks[i].time_msc==ticks[i-1].time_msc) dup_time++;
      int k=-1;
      for(int j=0;j<kinds;j++)
         if(flag_kinds[j]==ticks[i].flags) { k=j; break; }
      if(k<0 && kinds<8)
        { flag_kinds[kinds]=ticks[i].flags; k=kinds; kinds++; }
      if(k>=0) flag_counts[k]++;
     }
   PrintFormat("DUMP_SUMMARY with_last=%d with_volume=%d unsorted=%d same_time_msc=%d",with_last,with_volume,unsorted,dup_time);
   for(int j=0;j<kinds;j++)
      PrintFormat("DUMP_FLAGS flags=%u count=%d",flag_kinds[j],flag_counts[j]);
   // 日別件数
   int day_count=0;
   datetime day=0;
   string line="";
   for(int i=0;i<count;i++)
     {
      const datetime d=ticks[i].time-(ticks[i].time%86400);
      if(d!=day)
        {
         if(day!=0)
            line+=StringFormat("%s=%d ",TimeToString(day,TIME_DATE),day_count);
         day=d; day_count=0;
        }
      day_count++;
     }
   line+=StringFormat("%s=%d",TimeToString(day,TIME_DATE),day_count);
   PrintFormat("DUMP_DAYS %s",line);
  }
