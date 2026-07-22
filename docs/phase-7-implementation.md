# Phase 7 実装記録

## 実装前

### 実装目的

時系列データの未来情報を混入させずに学習・校正・OOS評価できる基盤と、Lambdaで小さく安全に実行できるML推論を実装する。MLが拒否または異常の場合はLLMを呼び出さず、新規注文をVETOする。

### 変更ファイル

- `python/ml/features/`: 学習・推論共通の特徴量定義とTP/SL先着ラベル
- `python/ml/training/`: 時系列分割、基準モデル学習、評価、JSON成果物出力
- `services/decision_api/src/decision_api/ml.py`: Lambda用JSONモデル検証・S3読込み・推論
- `services/decision_api/src/decision_api/service.py`: ML閾値判定と異常時VETO
- `infra/`: モデルキー、チェックサム、閾値設定
- `python/tests/`、`services/decision_api/tests/`、`infra/tests/`: 正常・異常系テスト
- `tools/test-phase7.ps1`: Phase 7一括検証

### 設計判断

- 初期モデルは標準化付き正則化ロジスティック回帰とRidge回帰とする。勝率の説明容易性、再現性、小データでの安定性、線形係数を安全なJSONへ変換できる点を優先した。
- LightGBMは非線形モデルがOOS・ウォークフォワードで基準モデルを安定して上回り、確率校正後も改善が確認された場合だけ候補とする。
- 学習期間、確率校正期間、最終OOS期間を時系列順に分離し、境界には設定可能なgapを置く。ランダム分割は使用しない。
- Lambdaではscikit-learnやpickleを読み込まない。モデル係数、標準化値、校正係数を厳格JSONとして読み、S3オブジェクトのSHA-256を照合する。
- 1モデルは1symbol・1timeframeに限定し、特徴量名と順序を固定する。
- ML通過後もPhase 8のLLMが未実装である間は `VETO / LLM_NOT_IMPLEMENTED` とする。

### 想定リスク

- バックテスト由来のラベルは約定、スプレッド、スリッページを完全には再現しない。
- 同じOHLCバー内でTPとSLへ到達した場合は順序が不明である。楽観的に勝ちとせず `AMBIGUOUS` として除外する。
- 確率校正は市場レジーム変化で劣化する。Brier score、選択率、実運用校正曲線を継続監視する。
- S3、モデルJSON、チェックサム、特徴量スキーマの異常は推論エラーとなる。すべてVETOへ倒す。
- 合成データのテスト成功は収益性を示さない。実データでのOOS・ウォークフォワードは未実施である。

## 実装後

### 実装内容

- direction、RSI、ATR比率、EMA乖離、方向付きEMA乖離、直近return、volatility、spread、時刻周期、曜日周期、RR、SL/TP距離の15特徴量を固定した。
- 学習データの欠損、NaN/Infinity、重複時刻、複数symbol/timeframe混在、価格関係、ラベル異常を拒否する。
- TP/SL先着、取引コスト控除、未到達 `CENSORED`、同一バー両到達 `AMBIGUOUS` を実装した。
- 学習・校正・OOSの三分割と5分割TimeSeriesSplitウォークフォワードを実装した。標準化は学習区間だけでfitする。
- OOSでBrier score、ROC AUC、閾値時precision、選択率、return MAEを記録する。
- 勝率モデルを独立した校正期間でPlatt校正し、expected returnはRidge回帰で推定する。
- `model.json` と学習期間・分割・評価値・ライブラリ版・SHA-256を含む `metadata.json` を出力する。
- Lambdaは64 KiB上限、重複キー禁止、完全フィールド一致、有限数、特徴量順序、モデル版、対象symbol/timeframe、SHA-256を検証してから一度だけロードし再利用する。
- 閾値未達は `ML_THRESHOLD_NOT_MET`、推論異常は `ML_INFERENCE_ERROR`、通過後は `LLM_NOT_IMPLEMENTED` としてすべて現段階ではVETOする。

### テスト結果

- Python 3.12 / pytest: 36件成功。
- 対象: 特徴量の学習・Lambda完全一致、異常データ、TP/SL/曖昧/打切りラベル、時系列gap、OOSリーク防止、成果物checksum、厳格JSON、対象scope、S3改ざん、推論閾値、推論例外、Lambda/API/CDK回帰。
- CDK synth: 成功。
- 実データ学習、S3アップロード、AWS deploy、MQL5との実API疎通は未実施。

### 残課題

- 信頼できるヒストリカルデータを用意し、手数料・スプレッド・スリッページ込みのラベルを生成する。
- 最低サンプル数、OOS Brier score、選択率、最大DDなどのモデル採用基準を実データ前に確定する。
- 確率校正曲線とsymbol/timeframe別の安定性を確認し、基準モデルを上回る場合だけLightGBMを比較採用する。
- Phase 8でLLMプロバイダー抽象化を実装し、ML通過時だけ呼び出す。
- Phase 9で候補ごとのモデル版、勝率、期待return、拒否理由を監査データへ拡張する。

