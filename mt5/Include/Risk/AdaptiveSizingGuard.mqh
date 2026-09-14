#ifndef EA_TRADING_SYSTEM_ADAPTIVE_SIZING_GUARD_MQH
#define EA_TRADING_SYSTEM_ADAPTIVE_SIZING_GUARD_MQH

// HistorySelect範囲の実装上限（3年、日数）。取引頻度に対し十分に余裕を持たせた値。
#define ADAPTIVE_SIZING_LOOKBACK_WINDOW_DAYS 1095

// 直近の実現成績に応じてリスク量を縮小する、レジーム予測に依存しないサイジング調整。
// 「これから来る相場が悪いか」を事前に判定しようとした既存の入口フィルタ案（ADX上限・レジーム
// 持続性等）はいずれもTrain区間で反証済み（詳細はTASKS.md参照）。本ガードは事前予測を行わず、
// 実際に悪い結果が続いた場合にのみ縮小方向へ反応する。CLAUDE.md 14章が禁止する「損失後の自動
// Lot増加」とは逆方向（縮小のみ、既定値1.0を上回ることはない）であり抵触しない。
//
// 2026-08-23再設計: 当初は勝率の二値閾値（下回れば固定倍率へ即座に切替）だったが、Train区間の
// 実データ検証で「悪化直後の回復局面まで一律に縮小してしまい、純損益をむしろ悪化させる」ことが
// 判明した（詳細はTASKS.md参照）。連続値指標（直近取引の平均R倍数相当）と、その大きさに比例して
// 滑らかに縮小する設計へ変更し、境界値付近での急激な切替による取りこぼしを緩和する。
class CAdaptiveSizingRules
  {
public:
   // trade_countがlookback_tradesに満たない（データ不足）場合、またはavg_rが0以上（直近成績が
   // 損益分岐点以上）の場合は1.0（縮小なし）を返す。avg_r<0の場合、sensitivity倍だけ1.0から
   // 減算し、floor_multiplierを下限としてクランプする（拡大方向へは働かない）。
   static double RiskMultiplier(const int trade_count,const int lookback_trades,
                                const double avg_r,const double sensitivity,
                                const double floor_multiplier)
     {
      if(lookback_trades<1 || sensitivity<0.0 || floor_multiplier<=0.0 || floor_multiplier>1.0)
         return 1.0;
      if(trade_count<lookback_trades)
         return 1.0;
      if(avg_r>=0.0)
         return 1.0;
      const double raw=1.0+sensitivity*avg_r;
      return MathMax(floor_multiplier,MathMin(1.0,raw));
     }
  };

class CAdaptiveSizingGuard
  {
public:
   // 指定magicのポジションについて、直近最大lookback_trades件（決済済みポジション単位、部分決済は
   // 1件扱い）の平均R倍数相当（各ポジションの損益をbase_risk_amountで正規化した値の平均）を求める。
   // base_risk_amountは呼び出し側でequity×risk_per_trade_rate（既定リスク率、adaptive_sizing適用前の
   // 基準値）として算出し、過去の各取引が実際に使ったリスク量ではなく「現在の基準で見た場合の
   // おおよそのR」として一貫した尺度で評価する。取得不能時はfalse-safe
   // （呼び出し側はtrade_count=0のままRiskMultiplier=1.0となる）。
   bool RecentAverageR(const ulong magic_number,const int lookback_trades,
                       const double base_risk_amount,
                       double &avg_r,int &trade_count,string &error)
     {
      avg_r=0.0;
      trade_count=0;
      error="";
      if(lookback_trades<1)
        { error="INVALID_LOOKBACK_TRADES"; return false; }
      if(base_risk_amount<=0.0)
        { error="INVALID_BASE_RISK_AMOUNT"; return false; }
      const datetime now=TimeTradeServer();
      if(now<=0)
        { error="SERVER_TIME_UNAVAILABLE"; return false; }
      const datetime from=now-ADAPTIVE_SIZING_LOOKBACK_WINDOW_DAYS*86400;
      if(!HistorySelect(from,now))
        { error="HISTORY_SELECT_FAILED"; return false; }

      const int total=HistoryDealsTotal();
      if(total<=0)
         return true; // 履歴なし＝データ不足（trade_count=0のまま）

      ulong  seen_positions[];
      double position_pnl[];
      int    seen_count=0;

      for(int index=total-1; index>=0 && trade_count<lookback_trades; index--)
        {
         const ulong ticket=HistoryDealGetTicket(index);
         if(ticket==0)
           { error="HISTORY_DEAL_UNAVAILABLE"; return false; }
         if((ulong)HistoryDealGetInteger(ticket,DEAL_MAGIC)!=magic_number)
            continue;
         const ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket,DEAL_TYPE);
         if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL)
            continue;
         const ENUM_DEAL_ENTRY deal_entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY);
         if(deal_entry!=DEAL_ENTRY_OUT && deal_entry!=DEAL_ENTRY_OUT_BY)
            continue;
         const ulong position_id=(ulong)HistoryDealGetInteger(ticket,DEAL_POSITION_ID);
         const double pnl=HistoryDealGetDouble(ticket,DEAL_PROFIT)+HistoryDealGetDouble(ticket,DEAL_COMMISSION)+
                          HistoryDealGetDouble(ticket,DEAL_SWAP)+HistoryDealGetDouble(ticket,DEAL_FEE);

         int slot=-1;
         for(int s=0; s<seen_count; s++)
            if(seen_positions[s]==position_id) { slot=s; break; }
         if(slot<0)
           {
            slot=seen_count;
            seen_count++;
            ArrayResize(seen_positions,seen_count);
            ArrayResize(position_pnl,seen_count);
            seen_positions[slot]=position_id;
            position_pnl[slot]=0.0;
            trade_count++;
           }
         position_pnl[slot]+=pnl;
        }

      double sum_r=0.0;
      for(int s=0; s<seen_count; s++)
         sum_r+=position_pnl[s]/base_risk_amount;
      avg_r=(trade_count>0 ? sum_r/trade_count : 0.0);
      return true;
     }
  };

#endif
