# 設定

## 設定の原則

EA設定は用途別に管理し、dev、staging・デモ、productionで設定ファイルを分ける。共有鍵、AWS認証情報、LLM APIキーをEA inputや設定ファイルへ保存しない。production設定の変更前後はスクリーンショットまたはエクスポートを監査証跡として保全する。

初期運用資金100万円はコードへ固定しない。EAのリスク予算は実口座の `ACCOUNT_EQUITY` を基準にするため、EA割当資金を他資産から分離した専用口座で運用する。分析時の初期残高は `python.analysis.reports --initial-balance` で指定する。

## 戦略設定

| 設定 | 初期値 | 意味 |
|---|---:|---|
| `InpEaId` | `trend-ea-v1` | EA・監査の識別子 |
| `InpSymbol` | 空 | 空ならチャートsymbol |
| `InpTrendTimeframe` | D1 | 大局トレンド |
| `InpConfirmationTimeframe` | H4 | トレンド確認 |
| `InpEntryTimeframe` | H1 | 確定足エントリー判定 |
| `InpFastEmaPeriod` / `InpSlowEmaPeriod` | 50 / 200 | EMA期間 |
| `InpRsiPeriod` / `InpAtrPeriod` | 14 / 14 | RSI・ATR期間 |
| `InpBreakoutLookback` | 20 | ブレイクアウト参照本数 |
| `InpBreakoutBufferPoints` | 0 | ブレイク閾値へのbuffer |
| `InpPullbackAtrTolerance` | 0.25 | 押し目のATR許容幅 |
| `InpRsiBuyMin` / `InpRsiBuyMax` | 50 / 75 | BUY RSI範囲 |
| `InpRsiSellMin` / `InpRsiSellMax` | 25 / 50 | SELL RSI範囲 |
| `InpMinimumAtrPoints` | 10 | 最低volatility |
| `InpStopAtrMultiple` | 2 | SLのATR倍率 |
| `InpRiskRewardRatio` | 2 | TP/SL比 |
| `InpEnableBreakout` / `InpEnablePullback` | true / true | entry pattern有効化 |

固定値を最適化結果だけで変更しない。変更前にOOS期間と受入基準を固定し、Walk Forwardとデモで再検証する。

## リスク・注文設定

| 設定 | 初期値 | 意味 |
|---|---:|---|
| `InpRiskPerTradePercent` | 0.5% | 1取引の最大リスク |
| `InpDailyLossLimitPercent` | 2% | 日次新規注文停止閾値 |
| `InpMaxDrawdownPercent` | 10% | 口座全体のDD停止閾値 |
| `InpMaxOpenPositions` | 1 | 最大同時ポジション数 |
| `InpMaxSpreadPoints` | 30 | 最大spread |
| `InpMinimumFreeMarginPercent` | 20% | 最低free margin率 |
| `InpMagicNumber` | 26072001 | EA所有取引の識別子 |
| `InpMaxDeviationPoints` | 10 | 最大許容deviation |
| `InpEmergencyStop` | false | trueで新規注文を即時停止 |
| `InpStrategyEnabled` | true | falseでStrategyの新規候補処理を停止。既存ポジション監視は継続 |
| `InpEnableTradeMutations` | false | 発注・決済変更の主安全フラグ |
| `InpCloseUnprotectedPositions` | true | 保護SLなしの所有positionを緊急決済対象にする |

`InpEnableTradeMutations` は最後に有効化する。Risk Manager、Decision API、LLMがALLOWでも、この値がfalseなら新規発注しない。本番ゲート未達の状態でtrueにしてはならない。

## Decision API・ML設定

| 設定 | 初期値 | 意味 |
|---|---:|---|
| `InpDecisionApiEnabled` | false | 外部判断APIの有効化 |
| `InpDecisionApiUrl` | 空 | `/v1/trade-decisions`で終わるHTTPS URL |
| `InpDecisionApiKeyId` | 空 | 失効可能なEA別key ID |
| `InpDecisionApiSecretFile` | `EaTradingSystem\\decision-api-secret.txt` | `MQL5\\Files`配下の共有鍵ファイル |
| `InpDecisionApiTimeoutMs` | 4500 | API timeout |
| `InpDecisionMaxClockSkewSeconds` | 60 | 許容UTC時刻差 |
| `InpDecisionMaxTtlSeconds` | 60 | 応答の最大有効期間 |
| `InpMlMinWinProbability` | 0.60 | EA側の最小勝率再検査 |
| `InpMlMinExpectedReturn` | 0 | EA側の最小期待return再検査 |

URLはMT5のWebRequest許可リストへ登録する。API無効、timeout、HTTPエラー、認証エラー、不正JSON、期限切れ、ML・LLMエラーはすべて新規注文拒否である。

Strategy Testerだけで `InpTesterDecisionMode` を使用できる。0はフェイルセーフVETO、1は常時ALLOW、2は常時VETO、3は固定ML確率、4はERROR、5はtimeout相当である。通常端末で0以外を指定すると初期化を拒否する。`InpTesterFixedMlProbability` の既定値は0.65である。

## 監査・Telemetry設定

| 設定 | 初期値 | 意味 |
|---|---:|---|
| `InpAuditFileEnabled` | true | 日別JSONL監査 |
| `InpAuditLogDirectory` | `EaTradingSystem\\Audit` | `MQL5\\Files`配下の出力先 |
| `InpTelemetryEnabled` | false | AWS監査送信 |
| `InpTelemetryApiUrl` | 空 | `/v1/trade-events`で終わるHTTPS URL |
| `InpTelemetryTimeoutMs` | 1500 | 監査送信timeout |

Telemetry失敗は取引判断や既存ポジション管理へ影響しない。ローカルJSONLを先に保存し、AWS欠損時の正本とする。

## AWS CDK context

`environment`、`ml_model_key`、`ml_model_sha256`、`llm_provider`、`llm_model`、`llm_shadow_mode`、`alarm_email`、`enable_dashboard`、`metrics_enabled`、`log_level` をdeploy時に指定できる。秘密値はcontextへ渡さない。`llm_shadow_mode` は既定でtrueで、有効なLLM VETOを記録するが最終判定へ適用しない。LLM timeout・不正出力・provider errorはShadow ModeでもVETOである。productionではモデルobjectとchecksum、固定LLM model、prompt version、SNS購読、予算通知を証跡へ記録する。
