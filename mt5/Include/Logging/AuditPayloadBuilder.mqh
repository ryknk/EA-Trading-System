#ifndef EA_TRADING_SYSTEM_AUDIT_PAYLOAD_BUILDER_MQH
#define EA_TRADING_SYSTEM_AUDIT_PAYLOAD_BUILDER_MQH

#include <EaTradingSystem/External/CryptoUtils.mqh>

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
// 決済イベントのPayload組み立てのみを提供する（研究計測イベントはResearch/TimingAnalysisHook.mqh）。
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
   // mfe_time: mfeが最後に更新された時刻（Peak到達時刻）。
   // post_peak_mae: mfe_time以降（直近Peak確定後）に観測された含み損益の最小値。
   static string BuildClosedPositionAnalyticsPayload(const ulong position_ticket,const double mfe,const double mae,
                                                      const datetime mfe_time,const double post_peak_mae)
     {
      string payload="{";
      payload+="\"position_ticket\":"+JString(StringFormat("%I64u",position_ticket))+",";
      payload+="\"mfe\":"+JNumber(mfe)+",";
      payload+="\"mae\":"+JNumber(mae)+",";
      payload+="\"mfe_time\":"+JString(Iso8601Utc(mfe_time))+",";
      payload+="\"post_peak_mae\":"+JNumber(post_peak_mae)+"}";
      return payload;
     }
  };

#endif
