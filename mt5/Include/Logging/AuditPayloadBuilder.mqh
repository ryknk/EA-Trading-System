#ifndef EA_TRADING_SYSTEM_AUDIT_PAYLOAD_BUILDER_MQH
#define EA_TRADING_SYSTEM_AUDIT_PAYLOAD_BUILDER_MQH

#include <EaTradingSystem/External/CryptoUtils.mqh>
#include <EaTradingSystem/Logging/EntryTimingAnalyzer.mqh>

// TRADE_CLOSEDイベントのPayload組み立てに必要な情報（ClosedPositionProcessorが決済履歴から集計する）。
struct SClosedPositionEvent
  {
   ulong    position_ticket;
   string   direction;
   datetime open_time;
   datetime close_time;
   double   volume;
   double   open_price;
   double   close_price;
   string   close_reason;
   double   pnl;
   double   commission;
   double   swap;
   double   exit_spread_points;
   double   point_value;
  };

// Audit用JSON Payload生成の軽量な共通処理。汎用JSONライブラリを目的とせず、本プロジェクトの
// Audit Payloadに必要な最小限のエスケープ・数値/真偽値変換・ISO 8601変換、および
// Entry Timing分析イベント・決済イベントのPayload組み立てのみを提供する。
// 既存のJSONフィールド名・値・型・ログ形式は変更しない。
class CAuditPayloadBuilder
  {
public:
   static string JString(const string value) { return "\""+CCryptoUtils::JsonEscape(value)+"\""; }
   static string JNumber(const double value) { return DoubleToString(value,10); }
   static string JBool(const bool value) { return value ? "true" : "false"; }

   static string Iso8601Utc(const datetime value)
     {
      MqlDateTime parts;
      TimeToStruct(value,parts);
      return StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",
                          parts.year,parts.mon,parts.day,parts.hour,parts.min,parts.sec);
     }

   // ENTRY_TIMING_SETUPイベントのPayload。
   static string BuildEntryTimingSetupPayload(const SEntryTimingSetupEvent &setup)
     {
      string payload="{";
      payload+="\"setup_bar_time\":"+JString(Iso8601Utc(setup.setup_bar_time))+",";
      payload+="\"direction\":"+JString(SignalDirectionToString(setup.direction))+",";
      payload+="\"pre_entry_mfe_price\":"+JNumber(setup.pre_entry_mfe_price)+",";
      payload+="\"pre_entry_mfe_r\":"+JNumber(setup.pre_entry_mfe_r)+",";
      payload+="\"pre_entry_mfe_time\":"+JString(Iso8601Utc(setup.pre_entry_mfe_time))+",";
      payload+="\"pre_entry_mae_price\":"+JNumber(setup.pre_entry_mae_price)+",";
      payload+="\"pre_entry_mae_r\":"+JNumber(setup.pre_entry_mae_r)+",";
      payload+="\"pre_entry_mae_time\":"+JString(Iso8601Utc(setup.pre_entry_mae_time))+",";
      payload+="\"trigger_found\":"+JBool(setup.trigger_found)+",";
      payload+="\"trigger_wait_bars\":"+IntegerToString(setup.trigger_wait_bars)+"}";
      return payload;
     }

   // ENTRY_TIMING_TRADEイベントのPayload。
   static string BuildEntryTimingTradePayload(const SEntryTimingTradeEvent &trade)
     {
      string checkpoints="{";
      for(int checkpoint_index=0; checkpoint_index<CEntryTimingRules::CheckpointCount(); checkpoint_index++)
        {
         if(!trade.checkpoint_valid[checkpoint_index]) continue;
         if(StringLen(checkpoints)>1) checkpoints+=",";
         checkpoints+="\"bars_"+IntegerToString(CEntryTimingRules::CheckpointBars(checkpoint_index))+"\":"+
                      JNumber(trade.checkpoint_r[checkpoint_index]);
        }
      checkpoints+="}";
      string payload="{";
      payload+="\"variant\":"+JString(EntryTimingVariantToString(trade.variant))+",";
      payload+="\"entry_bar_time\":"+JString(Iso8601Utc(trade.entry_bar_time))+",";
      payload+="\"direction\":"+JString(SignalDirectionToString(trade.direction))+",";
      payload+="\"entry_price\":"+JNumber(trade.entry_price)+",";
      payload+="\"stop_loss\":"+JNumber(trade.stop_loss)+",";
      payload+="\"take_profit\":"+JNumber(trade.take_profit)+",";
      payload+="\"wait_bars\":"+IntegerToString(trade.wait_bars)+",";
      payload+="\"bars_held\":"+IntegerToString(trade.bars_held)+",";
      payload+="\"mfe_r\":"+JNumber(trade.mfe_r)+",";
      payload+="\"mae_r\":"+JNumber(trade.mae_r)+",";
      payload+="\"exit_reason\":"+JString(trade.exit_reason)+",";
      payload+="\"exit_price\":"+JNumber(trade.exit_price)+",";
      payload+="\"pnl_r\":"+JNumber(trade.pnl_r)+",";
      payload+="\"checkpoint_r\":"+checkpoints+"}";
      return payload;
     }

   // TRADE_CLOSEDイベントのPayload。
   static string BuildClosedPositionPayload(const SClosedPositionEvent &closed)
     {
      string payload="{";
      payload+="\"position_ticket\":"+JString(StringFormat("%I64u",closed.position_ticket))+",";
      payload+="\"direction\":"+JString(closed.direction)+",";
      payload+="\"open_time\":"+JString(Iso8601Utc(closed.open_time))+",";
      payload+="\"close_time\":"+JString(Iso8601Utc(closed.close_time))+",";
      payload+="\"volume\":"+JNumber(closed.volume)+",";
      payload+="\"open_price\":"+JNumber(closed.open_price)+",";
      payload+="\"close_price\":"+JNumber(closed.close_price)+",";
      payload+="\"close_reason\":"+JString(closed.close_reason)+",";
      payload+="\"pnl\":"+JNumber(closed.pnl)+",";
      payload+="\"commission\":"+JNumber(closed.commission)+",";
      payload+="\"swap\":"+JNumber(closed.swap)+",";
      payload+="\"exit_spread_points\":"+JNumber(closed.exit_spread_points)+",";
      payload+="\"point_value\":"+JNumber(closed.point_value)+"}";
      return payload;
     }

   // TRADE_ANALYTICSイベントのPayload。
   static string BuildClosedPositionAnalyticsPayload(const ulong position_ticket,const double mfe,const double mae)
     {
      string payload="{";
      payload+="\"position_ticket\":"+JString(StringFormat("%I64u",position_ticket))+",";
      payload+="\"mfe\":"+JNumber(mfe)+",";
      payload+="\"mae\":"+JNumber(mae)+"}";
      return payload;
     }
  };

#endif
