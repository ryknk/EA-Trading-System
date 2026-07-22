# Phase 3 実装記録

## 実装前

目的は、すべての上流判断より優先され、異常時に新規注文を拒否するRisk Managerを実装すること。変更対象はConfig/CoreEA入力、`mt5/Include/Risk`、SpreadFilter、Controller、リスクテストである。再起動、口座通貨換算、ブローカーの数量・ストップ・約定方式、ネッティング・ヘッジ口座の差を主要リスクとして扱った。

## 実装内容

- 初期値: 1取引0.5%、日次損失2%、最大DD 10%、最大ポジション1、余剰証拠金の留保20%
- `OrderCalcProfit`を優先し、ティック価値・ティックサイズを代替手段にした口座通貨建てPositionSizer
- 最小値・最大値・刻み幅の検査と、常に切り下げる取引数量の正規化
- ブローカーサーバー日付の日次開始有効証拠金、当日ロック、履歴からの初回復元
- 口座全体の最高有効証拠金と永続DDロック
- 全口座ポジション上限、同一シンボル追加禁止、シンボル数量上限
- Bid・Ask・ポイントによるSpreadFilter
- 最新価格でのSL方向、ストップレベル、必要証拠金、証拠金留保、`OrderCheck`
- リスク状態をシグナルの有無に関係なく毎ティック監視
- `RISK_REJECTED` / `RISK_WOULD_ALLOW`ログ。注文送信は未実装

## テスト・検証結果

- `TestPositionSizer.mq5`: リスク予算、有効証拠金ゼロ、刻み幅への切り下げ、最小値未満、最大値制限の5ケース
- `TestRiskGuards.mq5`: DailyLossGuard、DrawdownGuard、SpreadFilterの境界値・不正値12ケース
- Phase 2のシグナルルール11ケースと合わせ、純粋ルールの検証項目は28ケース
- すべてのMQLインクルード解決、波括弧対応を静的確認
- `OrderCheck`が1箇所、`OrderSend` / `OrderSendAsync` / `CTrade` / `PositionOpen` / `WebRequest`が0箇所であることを確認
- Phase 3完了時点ではMetaEditorが未導入だったが、2026年7月20日に実コンパイルとテスト実行が成功

## 残課題

- 初回日中起動の日次基準値は保守的近似。Phase 9のスナップショットで精密化する
- ターミナルグローバル変数のバックアップ・破損、ブローカー日付・DST、入出金をデモ口座で検証する
- Phase 4でOrder Manager / Position Managerを実装し、発注直前にもRisk Managerと`OrderCheck`を再実行する（完了済み）
- Phase 4でも外部API承認前の注文は禁止し、実際の注文接続時期を明示する
