#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// Custom Symbolのtick・M1バー・H1バーの取得可否を確認する読み取り専用スクリプト（データの変更は行わない）。

input string InpSymbol   = "JP225_HIST";
input string InpFromDate = "2024.03.04";
input string InpToDate   = "2024.03.06";

void OnStart()
  {
   const datetime from=StringToTime(InpFromDate);
   const datetime to=StringToTime(InpToDate);
   MqlTick ticks[];
   const int tick_count=CopyTicksRange(InpSymbol,ticks,COPY_TICKS_ALL,(ulong)from*1000,(ulong)to*1000);
   PrintFormat("HISTCHECK symbol=%s ticks=%d error=%d",InpSymbol,tick_count,GetLastError());
   if(tick_count>0)
      PrintFormat("HISTCHECK first_tick bid=%.5f ask=%.5f last_tick bid=%.5f ask=%.5f",
                  ticks[0].bid,ticks[0].ask,ticks[tick_count-1].bid,ticks[tick_count-1].ask);
   if(tick_count>0)
     {
      // 現在のDigits（小数桁数）を超える精度のtickが含まれるか（Digits変更で丸められるか）を確認する。
      const double scale=MathPow(10.0,(int)SymbolInfoInteger(InpSymbol,SYMBOL_DIGITS));
      int fine_bid=0,fine_ask=0;
      for(int i=0;i<tick_count;i++)
        {
         if(MathAbs(ticks[i].bid*scale-MathRound(ticks[i].bid*scale))>1.0e-6) fine_bid++;
         if(MathAbs(ticks[i].ask*scale-MathRound(ticks[i].ask*scale))>1.0e-6) fine_ask++;
        }
      PrintFormat("HISTCHECK digits=%d ticks_finer_than_digits bid=%d ask=%d of %d",
                  (int)SymbolInfoInteger(InpSymbol,SYMBOL_DIGITS),fine_bid,fine_ask,tick_count);
     }
   MqlRates rates[];
   ResetLastError();
   const int m1=CopyRates(InpSymbol,PERIOD_M1,from,to,rates);
   PrintFormat("HISTCHECK M1_bars=%d error=%d",m1,GetLastError());
   ResetLastError();
   const int h1=CopyRates(InpSymbol,PERIOD_H1,from,to,rates);
   PrintFormat("HISTCHECK H1_bars=%d error=%d",h1,GetLastError());
   PrintFormat("HISTCHECK SeriesBars M1=%d H1=%d",Bars(InpSymbol,PERIOD_M1),Bars(InpSymbol,PERIOD_H1));
  }
