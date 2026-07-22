# Phase 2 実装記録

## 実装前

目的は、注文・外部API・リスク計算から分離された基本EAと戦略契約を構築し、確定足だけから追跡可能な取引候補を生成すること。

変更対象は `mt5/Experts/CoreEA.mq5`、`mt5/Include/Core`、`Strategy`、`Signal`、`mt5/Tests`。戦略が注文責務を持たず、H1の新しいバーにつき一度だけ評価し、データ取得不能時は候補を作らない方針とした。主なリスクは未確定足参照、複数時間足の時刻差、指標の初期化・データ不足、価格精度である。

## 実装内容

- 全パラメータを入力値から `SEaConfig` へ写し、起動時に整合性を検証
- `IStrategy` で初期化、終了、評価、名称取得を抽象化
- D1/H4トレンド、H1ブレイクアウト・押し目、RSI/ATR条件を実装
- 判定式を市場データ取得から分離した `CTrendFollowingRules`
- シグナル状態、方向、パターン、候補ID、バー時刻、SL/TP候補、理由コードをDTO化
- シグナルエンジンが現在のバー時刻を保持し、新しいバーで確定足（shift 1）を一度だけ評価
- 戦略のハンドルを終了時と初期化失敗時に解放
- Controllerは候補・シグナルなし・エラーをログ出力するだけで、取引APIを持たない

## テスト・検証結果

- 純粋ルールテストにトレンド整合・不整合、RSI、BUY/SELLブレイクアウト、境界値、BUY/SELL押し目、方向なしの11ケースを追加
- ソース全体に `OrderSend`、`CTrade`、Buy/Sell、PositionOpen、WebRequestが存在しないことを静的確認
- Phase 2完了時点ではMetaEditorが未導入だったが、2026年7月20日に実コンパイルとテスト実行が成功

## 残課題

- ブローカーのシンボル接尾辞、履歴データ準備時間、ターミナル再接続時の挙動を実機確認する
- Phase 3でRisk Manager、PositionSizer、DailyLossGuard、DrawdownGuard、ExposureGuardを実装する（完了済み）
- スプレッド・時間・ボラティリティフィルターの独立コンポーネント化はRisk/Filter Phaseで行う
- Phase 4までは注文を実装しない
