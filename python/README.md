# Python ML基盤

## セットアップ

Python 3.12仮想環境で `pip install -r python/requirements.txt` を実行する。テストはリポジトリルートから `.\tools\test-phase10.ps1` で実行する。

## 学習入力

CSVは時刻順に処理され、1ファイルを1symbol・1timeframeへ限定する。必要列は `timestamp`、`symbol`、`timeframe`、`direction`、`current_price`、`spread_points`、`rsi`、`atr`、`ema_distance_ratio`、`recent_return`、`volatility`、`hour`、`day_of_week`、`entry_price`、`stop_loss`、`take_profit`、`risk_reward_ratio`、`label_win`、`label_return` である。

`label_win` と `label_return` は将来情報から作る目的変数であり、特徴量へ含めない。同一バー内でTP/SLへ到達した曖昧標本と、評価期間内にどちらにも到達しない打切り標本は、採用方針を決めるまで学習から除外する。

## 学習コマンド

```powershell
$env:PYTHONPATH='.'
python -m python.ml.training.train_baseline `
  --input data/training/USDJPY-H1.csv `
  --output python/ml/models/USDJPY/H1/baseline-v1 `
  --model-version baseline-v1 `
  --gap 24
```

出力された `model.json` と `metadata.json` を確認し、実データのOOS受入基準を満たした場合だけ環境別S3へ配置する。`metadata.json` のSHA-256をCDK context `ml_model_sha256` に設定する。成果物をGitへ直接登録しない。

## パフォーマンス分析

`python.analysis.reports` はPhase 9の日別監査JSONLを複数読み込み、日をまたぐ候補と決済を相関する。正規化CSVを使う場合の列は `trade_id`、`trade_candidate_id`、`symbol`、`strategy`、`direction`、`open_time`、`close_time`、`volume`、`open_price`、`close_price`、`net_pnl`、`commission`、`swap` である。時刻にはUTC offsetを必須とし、`net_pnl` は手数料・スワップ・fee込みとする。

```powershell
$env:PYTHONPATH='.'
python -m python.analysis.reports --input trades.csv --initial-balance 1000000 --output build/report
```

`performance-summary.json`、`report.md`、`trades-normalized.csv`、`equity-curve.csv`、`monthly-performance.csv` を生成する。口座スナップショットがある場合は含み損益を反映した最大DDを優先する。
