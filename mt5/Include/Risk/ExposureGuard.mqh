#ifndef EA_TRADING_SYSTEM_EXPOSURE_GUARD_MQH
#define EA_TRADING_SYSTEM_EXPOSURE_GUARD_MQH

class CExposureGuard
  {
public:
   static bool IsPositionCountAllowed(const int current_positions,const int max_positions)
     {
      return current_positions>=0 && max_positions>0 && current_positions<max_positions;
     }

   // 同一銘柄・同一方向の追加を許可するか。Netting口座は複数ポジションを個別のticketとして
   // 保持できず自動的に一本化されるため、effective_max（呼び出し側でNetting時は1に丸め済み）を渡す。
   static bool IsSameDirectionAdditionAllowed(const int same_direction_count,const int effective_max_same_direction)
     {
      return same_direction_count>=0 && effective_max_same_direction>0 &&
             same_direction_count<effective_max_same_direction;
     }

   // 反対方向の既存ポジションは常に禁止する（両建てはHedging口座でも本タスクの対象外、
   // 既存のDUPLICATE_POSITION相当の安全側挙動を維持する）。
   static bool IsOppositeDirectionBlocking(const bool opposite_direction_position_exists)
     {
      return opposite_direction_position_exists;
     }

   // 同一方向への追加エントリーが、既存ポジションの建値から十分離れているか（ナンピン的な
   // 近接積み増しの防止）。min_distance_points<=0なら無効化（既定挙動）。
   static bool IsEntryDistanceSufficient(const double candidate_price,const double nearest_same_direction_open_price,
                                         const double min_distance_points,const double point)
     {
      if(min_distance_points<=0.0) return true;
      if(point<=0.0 || candidate_price<=0.0 || nearest_same_direction_open_price<=0.0) return false;
      return MathAbs(candidate_price-nearest_same_direction_open_price)+1.0e-9>=min_distance_points*point;
     }

   // Netting口座では同一銘柄・同一方向の複数ポジションを独立したticketとして維持できない
   // （ブローカー側で自動的に一本化される）ため、設定値に関わらず1へ丸める。
   static int EffectiveMaxSameDirection(const int configured_max,const ENUM_ACCOUNT_MARGIN_MODE margin_mode)
     {
      if(margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_NETTING) return 1;
      return configured_max;
     }

   bool Evaluate(const string symbol,const ENUM_POSITION_TYPE proposed_type,const double candidate_price,
                 const double proposed_volume,const int max_positions,const int max_same_direction_positions,
                 const double min_entry_distance_points,string &reason_code,string &error)
     {
      reason_code="";
      error="";
      if(max_positions<1 || max_same_direction_positions<1 || proposed_volume<=0.0)
        { error="INVALID_EXPOSURE_INPUT"; return false; }
      const int total=PositionsTotal();
      if(!IsPositionCountAllowed(total,max_positions))
        { reason_code="POSITION_LIMIT"; return true; }

      const ENUM_ACCOUNT_MARGIN_MODE margin_mode=(ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
      const int effective_max_same_direction=EffectiveMaxSameDirection(max_same_direction_positions,margin_mode);
      const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);

      int same_direction_count=0;
      double nearest_same_direction_open_price=0.0;
      double nearest_same_direction_distance=-1.0;
      for(int index=0; index<total; index++)
        {
         const ulong ticket=PositionGetTicket(index);
         if(ticket==0)
           { error="POSITION_ENUMERATION_FAILED"; return false; }
         const string position_symbol=PositionGetString(POSITION_SYMBOL);
         if(position_symbol!=symbol)
            continue;
         const ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(position_type!=proposed_type)
           {
            // 反対方向の既存ポジションは、方向・マジックナンバーを問わず追加を禁止する。
            reason_code="OPPOSITE_DIRECTION_POSITION_EXISTS";
            return true;
           }
         same_direction_count++;
         const double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
         const double distance=(candidate_price>0.0 && open_price>0.0 ? MathAbs(candidate_price-open_price) : -1.0);
         if(distance>=0.0 && (nearest_same_direction_distance<0.0 || distance<nearest_same_direction_distance))
           {
            nearest_same_direction_distance=distance;
            nearest_same_direction_open_price=open_price;
           }
        }

      if(!IsSameDirectionAdditionAllowed(same_direction_count,effective_max_same_direction))
        { reason_code="MAX_SAME_DIRECTION_POSITIONS"; return true; }

      if(same_direction_count>0 &&
         !IsEntryDistanceSufficient(candidate_price,nearest_same_direction_open_price,min_entry_distance_points,point))
        { reason_code="MIN_ENTRY_DISTANCE"; return true; }

      const double volume_limit=SymbolInfoDouble(symbol,SYMBOL_VOLUME_LIMIT);
      if(volume_limit>0.0 && proposed_volume>volume_limit+1.0e-12)
        { reason_code="EXPOSURE_LIMIT"; return true; }
      return true;
     }
  };

#endif
