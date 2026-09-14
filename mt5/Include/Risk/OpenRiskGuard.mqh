#ifndef EA_TRADING_SYSTEM_OPEN_RISK_GUARD_MQH
#define EA_TRADING_SYSTEM_OPEN_RISK_GUARD_MQH

// 口座全体（他EA・手動注文を含む）の既存ポジションについて、現在のSLへ到達した場合の
// 損失額を合算し、新規候補のリスクを加えた総オープンリスクがMaxOpenRiskPercentを
// 超えないかを判定する。ExposureGuardのPositionsTotal()方式（口座全体を対象とする）と
// 集計範囲を揃えている。
class COpenRiskGuardRules
  {
public:
   // 1ポジションの「現在のSLに到達した場合の損失額」（口座通貨、正の値）。
   // SL未設定・計算不能な場合はfalseを返す（安全側で呼び出し元がリスク計算不能として扱う）。
   static bool PositionRiskAmount(const string symbol,const ENUM_POSITION_TYPE type,
                                  const double volume,const double open_price,const double stop_loss,
                                  double &risk_amount)
     {
      risk_amount=0.0;
      if(volume<=0.0 || open_price<=0.0 || stop_loss<=0.0) return false;
      if(type==POSITION_TYPE_BUY && stop_loss>=open_price) return false;
      if(type==POSITION_TYPE_SELL && stop_loss<=open_price) return false;
      if(type!=POSITION_TYPE_BUY && type!=POSITION_TYPE_SELL) return false;
      const ENUM_ORDER_TYPE order_type=(type==POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      double profit=0.0;
      ResetLastError();
      if(!OrderCalcProfit(order_type,symbol,volume,open_price,stop_loss,profit) ||
         !MathIsValidNumber(profit) || profit>=0.0)
         return false;
      risk_amount=MathAbs(profit);
      return true;
     }

   static bool IsWithinLimit(const double existing_total_risk,const double candidate_risk,
                             const double equity,const double max_open_risk_rate)
     {
      if(!MathIsValidNumber(existing_total_risk) || !MathIsValidNumber(candidate_risk) ||
         existing_total_risk<0.0 || candidate_risk<0.0 || equity<=0.0 || max_open_risk_rate<=0.0)
         return false;
      return (existing_total_risk+candidate_risk)<=equity*max_open_risk_rate+0.01;
     }
  };

class COpenRiskGuard
  {
public:
   // 口座全体の既存ポジションについてSLリスクを合算する。SL未設定・計算不能なポジションが
   // 1件でもあれば安全側でfalseを返す（総リスクを過小評価しないため）。
   bool TotalExistingRisk(double &total_risk,string &error)
     {
      total_risk=0.0;
      error="";
      const int total=PositionsTotal();
      for(int index=0; index<total; index++)
        {
         const ulong ticket=PositionGetTicket(index);
         if(ticket==0)
           { error="POSITION_ENUMERATION_FAILED"; return false; }
         const string symbol=PositionGetString(POSITION_SYMBOL);
         const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         const double volume=PositionGetDouble(POSITION_VOLUME);
         const double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
         const double stop_loss=PositionGetDouble(POSITION_SL);
         double risk_amount=0.0;
         if(!COpenRiskGuardRules::PositionRiskAmount(symbol,type,volume,open_price,stop_loss,risk_amount))
           { error="OPEN_RISK_UNCALCULABLE"; return false; }
         total_risk+=risk_amount;
        }
      return true;
     }

   bool Evaluate(const double candidate_risk,const double equity,const double max_open_risk_rate,
                 double &open_risk_rate,string &reason_code,string &error)
     {
      reason_code="";
      error="";
      open_risk_rate=0.0;
      double existing_total_risk=0.0;
      if(!TotalExistingRisk(existing_total_risk,error))
         return false;
      if(candidate_risk<0.0 || equity<=0.0 || max_open_risk_rate<=0.0)
        { error="INVALID_OPEN_RISK_INPUT"; return false; }
      open_risk_rate=(existing_total_risk+candidate_risk)/equity;
      if(!COpenRiskGuardRules::IsWithinLimit(existing_total_risk,candidate_risk,equity,max_open_risk_rate))
        { reason_code="MAX_OPEN_RISK_EXCEEDED"; return true; }
      return true;
     }
  };

#endif
