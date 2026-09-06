#ifndef EA_TRADING_SYSTEM_TRADE_ANALYTICS_TRACKER_MQH
#define EA_TRADING_SYSTEM_TRADE_ANALYTICS_TRACKER_MQH

// MFE/MAE/Peak時刻の更新ロジック（純粋関数）。ライブのポジション状態（PositionsTotal等）に
// 依存しないため、単体テストで直接検証できる（2026-09-06追加、「含み益からの反転→SL到達」の
// 損失分析でPeak到達時刻・Peak後の最大逆行を求めるために新設）。
class CTradeAnalyticsRules
  {
public:
   // 建玉中の含み損益(profit)の観測を1件反映する。
   // mfe_timeはmfeが最後に更新された時刻（＝新たな高値が更新された瞬間）。
   // post_peak_maeはmfe_time以降（直近Peak確定後）に観測された含み損益の最小値であり、
   // 新たな高値が更新されるたびに現在値へリセットされる（＝直近Peakからの逆行幅を表す）。
   static void UpdateExtreme(const double profit,const datetime now,
                             double &mfe,datetime &mfe_time,double &mae,double &post_peak_mae)
     {
      if(profit>mfe)
        {
         mfe=profit;
         mfe_time=now;
         post_peak_mae=profit;
         return;
        }
      if(profit<post_peak_mae)
         post_peak_mae=profit;
      if(profit<mae)
         mae=profit;
     }
  };

// 分析専用のMFE（最大含み益）・MAE（最大含み損）・Peak到達時刻・Peak後の最大逆行の追跡。
// 売買判断・発注・既存ポジション管理には一切関与しないベストエフォートの記録機能。
// EA再起動をまたいで保有中のポジションは、再起動後のTick分のみ追跡対象となる（既知の制約）。
class CTradeAnalyticsTracker
  {
private:
   struct SPositionExtreme
     {
      ulong    ticket;
      double   mfe;
      datetime mfe_time;
      double   mae;
      double   post_peak_mae;
     };
   SPositionExtreme m_extremes[];
   ulong            m_magic_number;
   ulong            m_secondary_magic_number;
   bool             m_initialized;

   int Find(const ulong ticket)
     {
      for(int index=0; index<ArraySize(m_extremes); index++)
         if(m_extremes[index].ticket==ticket) return index;
      return -1;
     }

public:
   CTradeAnalyticsTracker(void) { m_magic_number=0; m_secondary_magic_number=0; m_initialized=false; }

   // secondary_magic_number=0（既定）は「セカンダリ戦略なし」を意味し、primaryのみを追跡する
   // （レンジ戦略追加、2026-08-24。PositionManager::IsManagedPositionと同じ考え方）。
   void Initialize(const ulong magic_number,const ulong secondary_magic_number=0)
     {
      m_magic_number=magic_number;
      m_secondary_magic_number=secondary_magic_number;
      ArrayResize(m_extremes,0);
      m_initialized=true;
     }

   // 建玉中の含み損益（価格損益+スワップ、手数料除く）の最大・最小値を更新する。
   void Update(void)
     {
      if(!m_initialized) return;
      const int total=PositionsTotal();
      const datetime now=TimeCurrent();
      for(int index=0; index<total; index++)
        {
         const ulong ticket=PositionGetTicket(index);
         if(ticket==0) continue;
         const long magic=PositionGetInteger(POSITION_MAGIC);
         if(magic!=(long)m_magic_number &&
            (m_secondary_magic_number==0 || magic!=(long)m_secondary_magic_number))
            continue;
         const double profit=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
         int slot=Find(ticket);
         if(slot<0)
           {
            slot=ArraySize(m_extremes);
            ArrayResize(m_extremes,slot+1);
            m_extremes[slot].ticket=ticket;
            m_extremes[slot].mfe=profit;
            m_extremes[slot].mfe_time=now;
            m_extremes[slot].mae=profit;
            m_extremes[slot].post_peak_mae=profit;
            continue;
           }
         CTradeAnalyticsRules::UpdateExtreme(profit,now,m_extremes[slot].mfe,m_extremes[slot].mfe_time,
                                             m_extremes[slot].mae,m_extremes[slot].post_peak_mae);
        }
     }

   // ポジション決済時に最終値を取り出す。追跡データが無ければfalse（未対応として扱う）。
   bool Finalize(const ulong ticket,double &mfe,double &mae,datetime &mfe_time,double &post_peak_mae)
     {
      const int slot=Find(ticket);
      if(slot<0) return false;
      mfe=m_extremes[slot].mfe;
      mae=m_extremes[slot].mae;
      mfe_time=m_extremes[slot].mfe_time;
      post_peak_mae=m_extremes[slot].post_peak_mae;
      const int last=ArraySize(m_extremes)-1;
      m_extremes[slot]=m_extremes[last];
      ArrayResize(m_extremes,last);
      return true;
     }
  };

#endif
