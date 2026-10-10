#ifndef EA_TRADING_SYSTEM_SYMBOL_SPEC_DUMP_MQH
#define EA_TRADING_SYSTEM_SYMBOL_SPEC_DUMP_MQH

// Symbol仕様（リスク計算・スプレッド判定・証拠金計算に関わる項目）をタブ区切りで書き出す診断用ヘルパー。
// 読み取り専用で、Symbolの作成・変更・削除は行わない。DiagnoseSymbolSpec（Script）と
// DiagnoseSymbolSpecEA（Strategy Tester用Expert）から共用する。

void Emit(const int handle,const string symbol,const string key,const string value)
  {
   FileWrite(handle,symbol,key,value);
   PrintFormat("SPEC %s %s=%s",symbol,key,value);
  }

void DumpInteger(const int handle,const string symbol,const string key,const ENUM_SYMBOL_INFO_INTEGER prop)
  {
   long value=0;
   ResetLastError();
   if(SymbolInfoInteger(symbol,prop,value))
      Emit(handle,symbol,key,IntegerToString(value));
   else
      Emit(handle,symbol,key,"ERR"+IntegerToString(GetLastError()));
  }

void DumpDouble(const int handle,const string symbol,const string key,const ENUM_SYMBOL_INFO_DOUBLE prop)
  {
   double value=0.0;
   ResetLastError();
   if(SymbolInfoDouble(symbol,prop,value))
      Emit(handle,symbol,key,DoubleToString(value,10));
   else
      Emit(handle,symbol,key,"ERR"+IntegerToString(GetLastError()));
  }

void DumpString(const int handle,const string symbol,const string key,const ENUM_SYMBOL_INFO_STRING prop)
  {
   string value="";
   ResetLastError();
   if(SymbolInfoString(symbol,prop,value))
      Emit(handle,symbol,key,value);
   else
      Emit(handle,symbol,key,"ERR"+IntegerToString(GetLastError()));
  }

void DumpSymbol(const int handle,const string symbol,const double probe_price,const double probe_stop)
  {
   bool is_custom=false;
   if(!SymbolExist(symbol,is_custom))
     {
      Emit(handle,symbol,"EXISTS","false");
      return;
     }
   Emit(handle,symbol,"EXISTS","true");
   Emit(handle,symbol,"IS_CUSTOM_EXIST_API",is_custom ? "true" : "false");
   SymbolSelect(symbol,true);
   MqlTick tick;
   for(int i=0;i<20 && !SymbolInfoTick(symbol,tick);i++)
      Sleep(200);
   DumpInteger(handle,symbol,"SYMBOL_DIGITS",SYMBOL_DIGITS);
   DumpDouble(handle,symbol,"SYMBOL_POINT",SYMBOL_POINT);
   DumpDouble(handle,symbol,"SYMBOL_TRADE_TICK_SIZE",SYMBOL_TRADE_TICK_SIZE);
   DumpDouble(handle,symbol,"SYMBOL_TRADE_TICK_VALUE",SYMBOL_TRADE_TICK_VALUE);
   DumpDouble(handle,symbol,"SYMBOL_TRADE_TICK_VALUE_PROFIT",SYMBOL_TRADE_TICK_VALUE_PROFIT);
   DumpDouble(handle,symbol,"SYMBOL_TRADE_TICK_VALUE_LOSS",SYMBOL_TRADE_TICK_VALUE_LOSS);
   DumpDouble(handle,symbol,"SYMBOL_TRADE_CONTRACT_SIZE",SYMBOL_TRADE_CONTRACT_SIZE);
   DumpInteger(handle,symbol,"SYMBOL_TRADE_CALC_MODE",SYMBOL_TRADE_CALC_MODE);
   DumpInteger(handle,symbol,"SYMBOL_TRADE_MODE",SYMBOL_TRADE_MODE);
   DumpInteger(handle,symbol,"SYMBOL_TRADE_EXEMODE",SYMBOL_TRADE_EXEMODE);
   DumpInteger(handle,symbol,"SYMBOL_FILLING_MODE",SYMBOL_FILLING_MODE);
   DumpInteger(handle,symbol,"SYMBOL_CHART_MODE",SYMBOL_CHART_MODE);
   DumpInteger(handle,symbol,"SYMBOL_SPREAD_FLOAT",SYMBOL_SPREAD_FLOAT);
   DumpInteger(handle,symbol,"SYMBOL_SPREAD",SYMBOL_SPREAD);
   DumpInteger(handle,symbol,"SYMBOL_TRADE_STOPS_LEVEL",SYMBOL_TRADE_STOPS_LEVEL);
   DumpInteger(handle,symbol,"SYMBOL_TRADE_FREEZE_LEVEL",SYMBOL_TRADE_FREEZE_LEVEL);
   DumpInteger(handle,symbol,"SYMBOL_SWAP_MODE",SYMBOL_SWAP_MODE);
   DumpDouble(handle,symbol,"SYMBOL_VOLUME_MIN",SYMBOL_VOLUME_MIN);
   DumpDouble(handle,symbol,"SYMBOL_VOLUME_MAX",SYMBOL_VOLUME_MAX);
   DumpDouble(handle,symbol,"SYMBOL_VOLUME_STEP",SYMBOL_VOLUME_STEP);
   DumpDouble(handle,symbol,"SYMBOL_VOLUME_LIMIT",SYMBOL_VOLUME_LIMIT);
   DumpDouble(handle,symbol,"SYMBOL_MARGIN_INITIAL",SYMBOL_MARGIN_INITIAL);
   DumpDouble(handle,symbol,"SYMBOL_MARGIN_MAINTENANCE",SYMBOL_MARGIN_MAINTENANCE);
   DumpDouble(handle,symbol,"SYMBOL_MARGIN_HEDGED",SYMBOL_MARGIN_HEDGED);
   double initial_rate=0.0,maintenance_rate=0.0;
   ResetLastError();
   if(SymbolInfoMarginRate(symbol,ORDER_TYPE_BUY,initial_rate,maintenance_rate))
     {
      Emit(handle,symbol,"MARGIN_RATE_BUY_INITIAL",DoubleToString(initial_rate,6));
      Emit(handle,symbol,"MARGIN_RATE_BUY_MAINTENANCE",DoubleToString(maintenance_rate,6));
     }
   else
      Emit(handle,symbol,"MARGIN_RATE_BUY","ERR"+IntegerToString(GetLastError()));
   ResetLastError();
   if(SymbolInfoMarginRate(symbol,ORDER_TYPE_SELL,initial_rate,maintenance_rate))
     {
      Emit(handle,symbol,"MARGIN_RATE_SELL_INITIAL",DoubleToString(initial_rate,6));
      Emit(handle,symbol,"MARGIN_RATE_SELL_MAINTENANCE",DoubleToString(maintenance_rate,6));
     }
   else
      Emit(handle,symbol,"MARGIN_RATE_SELL","ERR"+IntegerToString(GetLastError()));
   DumpString(handle,symbol,"SYMBOL_CURRENCY_BASE",SYMBOL_CURRENCY_BASE);
   DumpString(handle,symbol,"SYMBOL_CURRENCY_PROFIT",SYMBOL_CURRENCY_PROFIT);
   DumpString(handle,symbol,"SYMBOL_CURRENCY_MARGIN",SYMBOL_CURRENCY_MARGIN);
   DumpString(handle,symbol,"SYMBOL_PATH",SYMBOL_PATH);
   DumpString(handle,symbol,"SYMBOL_DESCRIPTION",SYMBOL_DESCRIPTION);
   DumpInteger(handle,symbol,"SYMBOL_CUSTOM",SYMBOL_CUSTOM);
   DumpInteger(handle,symbol,"SYMBOL_SELECT",SYMBOL_SELECT);

   ZeroMemory(tick);
   const bool has_tick=SymbolInfoTick(symbol,tick);
   Emit(handle,symbol,"TICK_AVAILABLE",has_tick ? "true" : "false");
   if(has_tick)
     {
      Emit(handle,symbol,"TICK_BID",DoubleToString(tick.bid,10));
      Emit(handle,symbol,"TICK_ASK",DoubleToString(tick.ask,10));
      const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      if(point>0.0)
         Emit(handle,symbol,"TICK_SPREAD_IN_POINTS",DoubleToString((tick.ask-tick.bid)/point,4));
     }

   // EAのPositionSizer/RiskManagerと同じAPIを、同じ引数の作り方で呼び出す。
   double price=probe_price;
   if(price<=0.0 && has_tick)
      price=tick.bid;
   if(price>0.0)
     {
      const double stop_distance=(probe_stop>0.0 ? probe_stop : price*0.01);
      double profit=0.0;
      ResetLastError();
      const bool profit_ok=OrderCalcProfit(ORDER_TYPE_BUY,symbol,1.0,price,price-stop_distance,profit);
      Emit(handle,symbol,"PROBE_PRICE",DoubleToString(price,10));
      Emit(handle,symbol,"PROBE_STOP_DISTANCE",DoubleToString(stop_distance,10));
      Emit(handle,symbol,"ORDER_CALC_PROFIT_OK",profit_ok ? "true" : "false");
      Emit(handle,symbol,"ORDER_CALC_PROFIT_ERR",IntegerToString(GetLastError()));
      Emit(handle,symbol,"ORDER_CALC_PROFIT_1LOT_SL",DoubleToString(profit,4));
      double margin=0.0;
      ResetLastError();
      const bool margin_ok=OrderCalcMargin(ORDER_TYPE_BUY,symbol,1.0,price,margin);
      Emit(handle,symbol,"ORDER_CALC_MARGIN_OK",margin_ok ? "true" : "false");
      Emit(handle,symbol,"ORDER_CALC_MARGIN_ERR",IntegerToString(GetLastError()));
      Emit(handle,symbol,"ORDER_CALC_MARGIN_1LOT",DoubleToString(margin,4));
     }
  }

void ListBrokerSymbols(const int handle,const string filter_csv)
  {
   string filters[];
   const int filter_count=StringSplit(filter_csv,',',filters);
   const int total=SymbolsTotal(false);
   for(int i=0;i<total;i++)
     {
      const string name=SymbolName(i,false);
      string upper=name;
      StringToUpper(upper);
      for(int f=0;f<filter_count;f++)
        {
         string token=filters[f];
         StringTrimLeft(token);
         StringTrimRight(token);
         StringToUpper(token);
         if(StringLen(token)>0 && StringFind(upper,token)>=0)
           {
            Emit(handle,name,"LISTED","true");
            break;
           }
        }
     }
  }

#endif
