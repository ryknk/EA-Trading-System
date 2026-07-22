# 取引判断API Lambda

Phase 9では、取引判断APIの入力検証、HMAC認証、リプレイ防止、冪等性、ML推論、ML通過時だけのLLM構造化判断に加え、取引イベントAPIと候補ID単位のDynamoDB監査保存を実装しています。LLM未設定・timeout・refusal・不正JSON・provider errorはVETOです。Telemetry障害は売買判断へ影響せず、LLM ALLOW後もEA内Risk Managerが最終判断します。

ローカルテストはリポジトリルートで次を実行します。

```powershell
$env:PYTHONPATH='services/decision_api/src;services/decision_api/tests;infra'
.\tools\test-phase9.ps1
```
