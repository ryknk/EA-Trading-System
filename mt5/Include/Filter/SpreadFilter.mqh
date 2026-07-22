#ifndef EA_TRADING_SYSTEM_SPREAD_FILTER_MQH
#define EA_TRADING_SYSTEM_SPREAD_FILTER_MQH

class CSpreadFilter
  {
public:
   static bool IsAllowed(const double bid,const double ask,const double point,const double max_spread_points)
     {
      if(bid<=0.0 || ask<=0.0 || ask<bid || point<=0.0 || max_spread_points<=0.0)
         return false;
      return (ask-bid)/point<=max_spread_points+1.0e-9;
     }

   bool Evaluate(const string symbol,const double max_spread_points,double &spread_points,string &error)
     {
      spread_points=0.0;
      error="";
      MqlTick tick;
      const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      if(point<=0.0 || !SymbolInfoTick(symbol,tick))
        { error="SPREAD_DATA_UNAVAILABLE"; return false; }
      spread_points=(tick.ask-tick.bid)/point;
      if(!IsAllowed(tick.bid,tick.ask,point,max_spread_points))
        { error="SPREAD_TOO_WIDE"; return false; }
      return true;
     }
  };

#endif
