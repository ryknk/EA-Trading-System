#ifndef EA_TRADING_SYSTEM_EXPOSURE_GUARD_MQH
#define EA_TRADING_SYSTEM_EXPOSURE_GUARD_MQH

class CExposureGuard
  {
public:
   static bool IsPositionCountAllowed(const int current_positions,const int max_positions)
     {
      return current_positions>=0 && max_positions>0 && current_positions<max_positions;
     }

   static bool IsSymbolAdditionAllowed(const bool same_symbol_position_exists)
     {
      return !same_symbol_position_exists;
     }

   bool Evaluate(const string symbol,const double proposed_volume,const int max_positions,string &reason_code,string &error)
     {
      reason_code="";
      error="";
      if(max_positions<1 || proposed_volume<=0.0)
        { error="INVALID_EXPOSURE_INPUT"; return false; }
      const int total=PositionsTotal();
      if(!IsPositionCountAllowed(total,max_positions))
        { reason_code="POSITION_LIMIT"; return true; }

      for(int index=0; index<total; index++)
        {
         const ulong ticket=PositionGetTicket(index);
         if(ticket==0)
           { error="POSITION_ENUMERATION_FAILED"; return false; }
         const string position_symbol=PositionGetString(POSITION_SYMBOL);
         if(position_symbol==symbol)
           {
            // Any existing position in the symbol blocks additions, preventing averaging and pyramiding.
            reason_code="DUPLICATE_POSITION";
            return true;
           }
        }
      const double volume_limit=SymbolInfoDouble(symbol,SYMBOL_VOLUME_LIMIT);
      if(volume_limit>0.0 && proposed_volume>volume_limit+1.0e-12)
        { reason_code="EXPOSURE_LIMIT"; return true; }
      return true;
     }
  };

#endif
