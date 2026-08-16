# 本番運用前チェックリスト

最終更新: 2026-07-21。`[x]` はPhase 13で実行証跡を確認した項目だけを示す。コードレビューのみ、外部環境未接続、実市場データ未評価の項目は未チェックとする。

## MQL5

- [x] 0 compile errors
- [x] 0 warnings
- [x] Unit Tests pass
- [ ] Strategy Tester pass（2026-08-16にOANDA証券MT5・Custom Symbol `USDJPY_HIST`・In-Sample期間（2017-09〜2020-12、DEC-024/DEC-025）で完走、総損益-65,696円/PF 0.66の損失結果。受入基準未凍結のためpass/fail判定は保留。XMTrading-MT5時代の2025年単年実行（総損益-95,024円/PF 0.59）は参考記録。詳細は`docs/production-readiness-report.md`5節）

## Risk

- [x] PositionSizer verified（純粋ルールScriptテスト）
- [x] DailyLossGuard verified（境界・異常状態Scriptテスト）
- [x] DrawdownGuard verified（境界・異常状態Scriptテスト）
- [x] ExposureGuard verified（件数・同一Symbol純粋ルールScriptテスト）
- [ ] Kill Switch verified（コード・純粋ルールは確認済み。実ポジション保有中の端末試験は未実施）

## AWS

- [ ] API verified（dev実通信未実施）
- [x] Timeout verified（Lambda/MQL単体異常系。実通信は未検証）
- [x] Error handling verified（単体テスト。dev障害注入は未検証）
- [x] Replay protection verified（単体テスト。dev実通信は未検証）
- [ ] Monitoring verified（CDK synthのみ。Alarm通知到達は未検証）

## ML

- [x] No data leakage（実装レビューと合成データテスト）
- [ ] Out-of-Sample evaluated（実市場データ未評価）
- [ ] Walk Forward evaluated（合成データのみ。実市場データ未評価）
- [x] Threshold documented（0.50〜0.70の事前固定比較を実装）
- [ ] Model version recorded（production候補artifact未作成）

## LLM

- [x] Shadow Mode enabled（IaC既定true、VETO記録・非適用を単体テスト）
- [x] Invalid output handling verified（単体テスト）
- [x] Timeout handling verified（単体テスト。実API未検証）
- [ ] LLM effectiveness evaluated（Shadow実績ログなし）

## Operations

- [ ] Demo Forward Test completed
- [ ] MQL5 VPS verified
- [x] Backup / Restore procedure documented（既存operations/release gate）
- [x] Emergency procedure documented
- [ ] EA Heartbeat verified（独立した定期Heartbeatは未実装）
