#ifndef EA_TRADING_SYSTEM_AUDIT_EVENT_PUBLISHER_MQH
#define EA_TRADING_SYSTEM_AUDIT_EVENT_PUBLISHER_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Logging/TradeLogger.mqh>
#include <EaTradingSystem/External/TelemetryApiClient.mqh>

// ローカルAudit記録とTelemetry送信の調停に責務を限定する。
//   1) ローカルAuditイベントを記録する
//   2) 必要な場合のみTelemetryへ送信する
//   3) Telemetry障害が取引処理へ影響しないようにする
// ローカル監査記録をTelemetry送信より先に保存し、Telemetryはベストエフォート（失敗してもログ出力のみ）とする。
class CAuditEventPublisher
  {
private:
   CTradeLogger        m_trade_logger;
   CTelemetryApiClient m_telemetry_client;
   SEaConfig           m_config;

public:
   void Initialize(const SEaConfig &config)
     {
      m_config=config;
      string audit_error;
      if(!m_trade_logger.Initialize(m_config,audit_error))
         PrintFormat("AUDIT_LOGGER_INIT_FAILED code=%s terminal_logging=true",audit_error);
      else if(StringLen(audit_error)>0)
         PrintFormat("AUDIT_LOGGER_INIT_WARNING code=%s terminal_logging=true",audit_error);
      string telemetry_error;
      if(!m_telemetry_client.Initialize(m_config,telemetry_error))
         PrintFormat("TELEMETRY_INIT_FAILED code=%s trading_impact=none",telemetry_error);
     }

   void Shutdown(void)
     {
      m_telemetry_client.Shutdown();
      m_trade_logger.Shutdown();
     }

   void Audit(const string event_type,const string candidate_id,const string request_id,
              const string symbol,const string payload,const bool send_remote)
     {
      string event_id,body,error;
      datetime event_time=0;
      if(!m_trade_logger.Record(event_type,CTradeLogRules::SafeIdentifier(candidate_id,"unlinked"),
                                (StringLen(request_id)>0 ? CTradeLogRules::SafeIdentifier(request_id,"") : ""),
                                CTradeLogRules::SafeIdentifier(symbol,m_config.symbol),payload,
                                event_id,event_time,body,error))
        {
         PrintFormat("AUDIT_LOCAL_WRITE_FAILED type=%s candidate_id=%s code=%s",event_type,candidate_id,error);
         return;
        }
      if(send_remote && m_telemetry_client.Enabled())
        {
         string telemetry_error;
         if(!m_telemetry_client.Send(body,event_id,event_time,telemetry_error))
            PrintFormat("TELEMETRY_UPLOAD_FAILED event_id=%s candidate_id=%s type=%s code=%s trading_impact=none",
                        event_id,candidate_id,event_type,telemetry_error);
        }
     }
  };

#endif
