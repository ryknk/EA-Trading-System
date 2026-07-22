# Phase 4 実装記録

## 実装前

目的は、Risk承認からブローカー要求までの責務をOrder Managerへ分離し、既存ポジション保護を外部API非依存のPosition Managerへ分離すること。二重発注、部分約定、ネッティング・ヘッジ口座の差、SL欠落、価格変動、約定方式を主要リスクとした。取引判断APIがないため、新規注文を実際には到達不能にすることを前提とした。

## 実装内容

- シグナル、外部ALLOW、Risk、取引数量、変更許可設定による承認チェーン
- 最新Bid・Askを使った成行要求と送信直前の`OrderCheck`
- 候補バー時刻の永続的な冪等性ガード。曖昧な失敗を自動再試行しない
- 承認・拒否・部分約定の戻り値、チケット、約定価格、数量、スリッページの結果DTO
- EAのマジックナンバーに一致するポジションを毎ティック最初に監視
- 保護SL欠落・ギャップ越え時の新規注文停止
- 外部API非依存の全量緊急決済とチケット単位の永続的な再試行ガード
- Position Manager異常をRisk Managerの`RISK_STATE_UNAVAILABLE`へ連携
- EA約定の取引イベントログ
- `enable_trade_mutations=false`を初期値に設定
- Phase 4 Controllerの`external_approved=false`を不変値として設定

## テスト・検証結果

- `TestTradingRules.mq5`に承認チェーン6、ブローカー戻り値4、ポジション保護・マジックナンバー8の計18ケースを追加
- 全MQLインクルードと波括弧の対応を静的確認
- `OrderSend`はOrder Managerの新規注文とPosition Managerの緊急決済の2箇所だけ
- Controllerに外部承認falseの強制ゲートが存在することを静的確認
- Phase 4完了後の2026年7月20日に、MetaEditorでエラー・警告なしのコンパイルと全テスト実行が成功

## 残課題

- デモ環境のネッティング・ヘッジ両口座で成行決済、部分約定、再クオート、市場休止を検証する
- 取引イベントと即時OrderSend結果の相関・永続化はPhase 9で実装する
- Phase 5で署名付き取引判断APIクライアントを追加し、応答が検証済みALLOWの場合だけ外部ゲートへ渡す
- Phase 5統合時に処理順を戦略 → 外部判定 → Risk再評価 → 注文へ変更する
