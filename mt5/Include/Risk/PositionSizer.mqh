#ifndef EA_TRADING_SYSTEM_POSITION_SIZER_MQH
#define EA_TRADING_SYSTEM_POSITION_SIZER_MQH

#include <EaTradingSystem/Signal/SignalResult.mqh>

class CPositionSizerRules
  {
public:
   static double RawVolume(const double equity,const double risk_rate,const double loss_per_lot)
     {
      if(!MathIsValidNumber(equity) || !MathIsValidNumber(risk_rate) || !MathIsValidNumber(loss_per_lot) ||
         equity<=0.0 || risk_rate<=0.0 || loss_per_lot<=0.0)
         return 0.0;
      const double result=equity*risk_rate/loss_per_lot;
      return (MathIsValidNumber(result) && result>0.0 ? result : 0.0);
     }

   static double TickLossPerLot(const double entry_price,const double stop_loss,
                                const double tick_size,const double tick_value)
     {
      if(!MathIsValidNumber(entry_price) || !MathIsValidNumber(stop_loss) ||
         !MathIsValidNumber(tick_size) || !MathIsValidNumber(tick_value) ||
         entry_price<=0.0 || stop_loss<=0.0 || entry_price==stop_loss ||
         tick_size<=0.0 || tick_value<=0.0)
         return 0.0;
      const double result=MathAbs(entry_price-stop_loss)/tick_size*tick_value;
      return (MathIsValidNumber(result) && result>0.0 ? result : 0.0);
     }

   static double FloorVolume(const double raw_volume,const double volume_min,
                             const double volume_max,const double volume_step)
     {
      if(!MathIsValidNumber(raw_volume) || !MathIsValidNumber(volume_min) ||
         !MathIsValidNumber(volume_max) || !MathIsValidNumber(volume_step) ||
         raw_volume<=0.0 || volume_min<=0.0 || volume_max<volume_min || volume_step<=0.0)
         return 0.0;
      const double capped=MathMin(raw_volume,volume_max);
      const double floored=MathFloor((capped+1.0e-12)/volume_step)*volume_step;
      if(floored+1.0e-12<volume_min)
         return 0.0;
      return MathMin(floored,volume_max);
     }
  };

class CPositionSizer
  {
private:
   int VolumeDigits(const double step)
     {
      int digits=0;
      double scaled=step;
      while(digits<8 && MathAbs(scaled-MathRound(scaled))>1.0e-8)
        {
         scaled*=10.0;
         digits++;
        }
      return digits;
     }

public:
   bool Calculate(const string symbol,const ESignalDirection direction,
                  const double entry_price,const double stop_loss,const double equity,
                  const double risk_rate,double &volume,double &risk_budget,
                  double &loss_per_lot,string &error)
     {
      volume=0.0;
      risk_budget=0.0;
      loss_per_lot=0.0;
      error="";
      if(direction!=SIGNAL_DIRECTION_BUY && direction!=SIGNAL_DIRECTION_SELL)
        { error="INVALID_DIRECTION"; return false; }
      if(entry_price<=0.0 || stop_loss<=0.0 || equity<=0.0 || risk_rate<=0.0)
        { error="INVALID_SIZING_INPUT"; return false; }
      if((direction==SIGNAL_DIRECTION_BUY && stop_loss>=entry_price) ||
         (direction==SIGNAL_DIRECTION_SELL && stop_loss<=entry_price))
        { error="INVALID_STOP"; return false; }

      const ENUM_ORDER_TYPE order_type=(direction==SIGNAL_DIRECTION_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      double profit=0.0;
      if(OrderCalcProfit(order_type,symbol,1.0,entry_price,stop_loss,profit) &&
         MathIsValidNumber(profit) && profit<0.0)
         loss_per_lot=MathAbs(profit);
      else
        {
         const double tick_size=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
         double tick_value=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
         if(tick_value<=0.0)
            tick_value=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
         if(tick_size<=0.0 || tick_value<=0.0)
           { error="TICK_VALUE_UNAVAILABLE"; return false; }
         loss_per_lot=CPositionSizerRules::TickLossPerLot(entry_price,stop_loss,tick_size,tick_value);
        }
      if(loss_per_lot<=0.0 || !MathIsValidNumber(loss_per_lot))
        { error="LOSS_PER_LOT_INVALID"; return false; }

      const double volume_min=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
      const double volume_max=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
      const double volume_step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
      risk_budget=equity*risk_rate;
      const double raw=CPositionSizerRules::RawVolume(equity,risk_rate,loss_per_lot);
      volume=CPositionSizerRules::FloorVolume(raw,volume_min,volume_max,volume_step);
      if(volume<=0.0)
        { error="SIZE_BELOW_MIN"; return false; }
      volume=NormalizeDouble(volume,VolumeDigits(volume_step));
      if(volume*loss_per_lot>risk_budget+0.01)
        { error="RISK_BUDGET_EXCEEDED"; volume=0.0; return false; }
      return true;
     }
  };

#endif
