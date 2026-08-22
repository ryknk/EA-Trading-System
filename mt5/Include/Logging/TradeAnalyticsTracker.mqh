#ifndef EA_TRADING_SYSTEM_TRADE_ANALYTICS_TRACKER_MQH
#define EA_TRADING_SYSTEM_TRADE_ANALYTICS_TRACKER_MQH

// 分析専用のMFE（最大含み益）・MAE（最大含み損）追跡。
// 売買判断・発注・既存ポジション管理には一切関与しないベストエフォートの記録機能。
// EA再起動をまたいで保有中のポジションは、再起動後のTick分のみ追跡対象となる（既知の制約）。
class CTradeAnalyticsTracker
  {
private:
   struct SPositionExtreme
     {
      ulong  ticket;
      double mfe;
      double mae;
     };
   SPositionExtreme m_extremes[];
   ulong            m_magic_number;
   bool             m_initialized;

   int Find(const ulong ticket)
     {
      for(int index=0; index<ArraySize(m_extremes); index++)
         if(m_extremes[index].ticket==ticket) return index;
      return -1;
     }

public:
   CTradeAnalyticsTracker(void) { m_magic_number=0; m_initialized=false; }

   void Initialize(const ulong magic_number)
     {
      m_magic_number=magic_number;
      ArrayResize(m_extremes,0);
      m_initialized=true;
     }

   // 建玉中の含み損益（価格損益+スワップ、手数料除く）の最大・最小値を更新する。
   void Update(void)
     {
      if(!m_initialized) return;
      const int total=PositionsTotal();
      for(int index=0; index<total; index++)
        {
         const ulong ticket=PositionGetTicket(index);
         if(ticket==0 || PositionGetInteger(POSITION_MAGIC)!=(long)m_magic_number) continue;
         const double profit=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
         int slot=Find(ticket);
         if(slot<0)
           {
            slot=ArraySize(m_extremes);
            ArrayResize(m_extremes,slot+1);
            m_extremes[slot].ticket=ticket;
            m_extremes[slot].mfe=profit;
            m_extremes[slot].mae=profit;
            continue;
           }
         if(profit>m_extremes[slot].mfe) m_extremes[slot].mfe=profit;
         if(profit<m_extremes[slot].mae) m_extremes[slot].mae=profit;
        }
     }

   // ポジション決済時に最終値を取り出す。追跡データが無ければfalse（未対応として扱う）。
   bool Finalize(const ulong ticket,double &mfe,double &mae)
     {
      const int slot=Find(ticket);
      if(slot<0) return false;
      mfe=m_extremes[slot].mfe;
      mae=m_extremes[slot].mae;
      const int last=ArraySize(m_extremes)-1;
      m_extremes[slot]=m_extremes[last];
      ArrayResize(m_extremes,last);
      return true;
     }
  };

#endif
