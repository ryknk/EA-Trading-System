#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// Custom Symbolのtickから月別のスプレッド分布と価格水準を集計する読み取り専用スクリプト（tick・仕様は変更しない）。
// 非FX資産のInpMaxSpreadPoints固定値（DEC-034）が、価格水準の変動に対して妥当かの確認に使う。
// 集計は「全tick」と「各時間の最初のtick（H1候補の評価時点に近い）」の2種類。
// 直近月はterminalのtick読み取りAPIが一部しか返さない（DEC-033）ため、その月の標本は間引かれている。

input string InpSymbol     = "JP225_HIST";
input string InpFromMonth  = "2020.01";
input string InpToMonth    = "2026.08";
input double InpFixedPoints = 110.0;   // 現行のInpMaxSpreadPoints
input double InpRatio       = 0.000227; // FX4銘柄の中央値（価格比）
input string InpOutputFile  = "spread-profile.tsv";

#define BIN_COUNT 20001

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

double Percentile(const long &bins[],const long total,const double q)
  {
   if(total<=0)
      return 0.0;
   const long target=(long)MathCeil(total*q);
   long cumulative=0;
   for(int i=0;i<BIN_COUNT;i++)
     {
      cumulative+=bins[i];
      if(cumulative>=target)
         return (double)i;
     }
   return (double)(BIN_COUNT-1);
  }

long CountAbove(const long &bins[],const double limit)
  {
   long above=0;
   for(int i=0;i<BIN_COUNT;i++)
      if((double)i>limit+1.0e-9)
         above+=bins[i];
   return above;
  }

void OnStart()
  {
   const datetime first=StringToTime(InpFromMonth+".01");
   const datetime last=StringToTime(InpToMonth+".01");
   if(first<=0 || last<first || !SymbolSelect(InpSymbol,true))
     {
      Print("SPREADPROF_ABORTED reason=INVALID_INPUT");
      return;
     }
   const double point=SymbolInfoDouble(InpSymbol,SYMBOL_POINT);
   if(point<=0.0)
     {
      Print("SPREADPROF_ABORTED reason=INVALID_POINT");
      return;
     }
   const int handle=FileOpen(InpOutputFile,FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(handle==INVALID_HANDLE)
     {
      PrintFormat("SPREADPROF_ABORTED reason=FILE_OPEN_FAILED error=%d",GetLastError());
      return;
     }
   FileWriteString(handle,"symbol\tmonth\tscope\tn\tmean_price\tmed_pts\tp90_pts\tp99_pts\tmean_pts\t"
                          "over_fixed\tratio_pts\tover_ratio\n");
   for(datetime month=first;month<=last;month=NextMonthStart(month))
     {
      long all_bins[BIN_COUNT],hour_bins[BIN_COUNT];
      ArrayInitialize(all_bins,0);
      ArrayInitialize(hour_bins,0);
      long all_n=0,hour_n=0;
      double price_sum=0.0,all_spread_sum=0.0,hour_spread_sum=0.0,hour_price_sum=0.0;
      const datetime month_end=NextMonthStart(month);
      long last_hour=-1;
      for(datetime day=month;day<month_end;day+=86400)
        {
         MqlTick ticks[];
         const int count=CopyTicksRange(InpSymbol,ticks,COPY_TICKS_ALL,(ulong)((long)day*1000),
                                        (ulong)((long)MathMin((long)day+86400,(long)month_end)*1000-1));
         if(count<=0)
            continue;
         for(int i=0;i<count;i++)
           {
            if(ticks[i].bid<=0.0 || ticks[i].ask<ticks[i].bid)
               continue;
            const double spread_points=(ticks[i].ask-ticks[i].bid)/point;
            int bin=(int)MathRound(spread_points);
            if(bin>=BIN_COUNT) bin=BIN_COUNT-1;
            all_bins[bin]++;
            all_n++;
            price_sum+=ticks[i].bid;
            all_spread_sum+=spread_points;
            const long hour_key=(long)ticks[i].time/3600;
            if(hour_key!=last_hour)
              {
               last_hour=hour_key;
               hour_bins[bin]++;
               hour_n++;
               hour_spread_sum+=spread_points;
               hour_price_sum+=ticks[i].bid;
              }
           }
        }
      if(all_n<=0)
         continue;
      const string month_text=TimeToString(month,TIME_DATE);
      const double mean_price=price_sum/all_n;
      const double ratio_points=InpRatio*mean_price/point;
      FileWriteString(handle,StringFormat("%s\t%s\tall\t%I64d\t%.2f\t%.0f\t%.0f\t%.0f\t%.2f\t%.4f\t%.1f\t%.4f\n",
                      InpSymbol,month_text,all_n,mean_price,Percentile(all_bins,all_n,0.5),
                      Percentile(all_bins,all_n,0.9),Percentile(all_bins,all_n,0.99),all_spread_sum/all_n,
                      (double)CountAbove(all_bins,InpFixedPoints)/all_n,ratio_points,
                      (double)CountAbove(all_bins,ratio_points)/all_n));
      if(hour_n>0)
         FileWriteString(handle,StringFormat("%s\t%s\thour\t%I64d\t%.2f\t%.0f\t%.0f\t%.0f\t%.2f\t%.4f\t%.1f\t%.4f\n",
                         InpSymbol,month_text,hour_n,hour_price_sum/hour_n,Percentile(hour_bins,hour_n,0.5),
                         Percentile(hour_bins,hour_n,0.9),Percentile(hour_bins,hour_n,0.99),hour_spread_sum/hour_n,
                         (double)CountAbove(hour_bins,InpFixedPoints)/hour_n,ratio_points,
                         (double)CountAbove(hour_bins,ratio_points)/hour_n));
      FileFlush(handle);
     }
   FileClose(handle);
   PrintFormat("SPREADPROF_DONE symbol=%s file=%s",InpSymbol,InpOutputFile);
  }
