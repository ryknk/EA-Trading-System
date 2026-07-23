# 1. 目的

このファイルは、`EA-Trading-System` におけるGit、Branch、Commit、Pull Request、Reviewの運用ルールを定義する。

安全性に関わる変更を追跡可能にし、変更理由、テスト結果、Rollback方法をGit履歴から確認できる状態を目指す。

---

# 2. 基本原則

* `master` を安定Branchとして扱う。
* 作業は原則として専用Branchで行う。
* 1つのBranchへ無関係な変更を混在させない。
* ユーザーの未コミット変更を上書きしない。
* Secret、Build Output、Backtest生成物をCommitしない。
* 安全性に関する変更は、理由とテストを必ず記録する。
* 実行していない試験を「PASS」と記載しない。
* 大規模な自動整形だけの差分を機能変更へ混在させない。

---

# 3. 作業開始前

作業開始時に次を確認する。

```powershell
git status
git branch --show-current
git remote -v
git log --oneline --decorate -10
```

未コミット差分がある場合は、誰が作成した変更かを確認する。

既存差分を削除、上書き、Revertしない。

---

# 4. Branch運用

# 4.1 Branch作成

原則として最新の`master`からBranchを作成する。

```powershell
git switch master
git pull --ff-only
git switch -c <branch-name>
```

ローカルに未コミット変更がある場合、無理にBranchを切り替えない。

# 4.2 Branch名

次の形式を使用する。

```text
<type>/<short-description>
```

使用する主なType：

* `feature/`: 新機能
* `fix/`: 不具合修正
* `test/`: テスト追加・改善
* `docs/`: 文書変更
* `refactor/`: 外部挙動を変えない構造改善
* `infra/`: AWS・CDK
* `security/`: 認証・Secret・権限
* `release/`: リリース準備
* `chore/`: 保守作業

例：

```text
fix/decision-api-exit-code
test/strategy-tester-broker-config
infra/dev-alarm-validation
docs/phase13-handoff
security/hmac-key-rotation
```

Branch名に個人情報、口座番号、Secret、長いIssue説明を含めない。

# 4.3 長期間のBranch

長期間Branchを放置しない。

大きな作業は、独立して検証可能な小さなBranchやPull Requestへ分割する。

---

# 5. Commit運用

# 5.1 Commit単位

1つのCommitは、1つの論理的な変更へ集中させる。

良い例：

* Risk Guardの境界条件修正と対応テスト
* API Schema変更とClient・Server・Contract Test更新
* Alarm追加とCDK Test更新
* 文書のみの更新

避ける例：

* MQL5修正、AWS変更、README整形を1Commitへ混在
* 機能変更と全ファイルのFormatter適用を混在
* 複数の無関係な不具合修正を1Commitへ集約

# 5.2 Commit Message

次の形式を推奨する。

```text
<type>: <summary>
```

Type：

* `feat`
* `fix`
* `test`
* `docs`
* `refactor`
* `infra`
* `security`
* `chore`

例：

```text
fix: keep position monitoring active during API failures
test: cover risk guard boundary conditions
infra: add DynamoDB system error alarms
docs: separate tasks and design decisions
security: validate HMAC key rotation workflow
```

Summaryは命令形または変更内容が明確な現在形で書く。

曖昧なMessageを避ける。

```text
update
fix bug
changes
work
misc
```

# 5.3 Commit本文

安全性、互換性、運用に影響する変更では、本文へ次を記載する。

* 変更理由
* 安全境界への影響
* 実行したテスト
* 未実行のテスト
* MigrationやRollback上の注意

# 5.4 Commit前の確認

```powershell
git status
git diff
git diff --cached
```

次を確認する。

* 対象外のファイルが含まれていない
* Secretが含まれていない
* Build Outputが含まれていない
* Backtest結果が含まれていない
* Debug Codeが残っていない
* 文書更新が必要な変更で、文書が更新されている
* Testが追加または更新されている

---

# 6. Pull Request運用

# 6.1 Pull Requestの目的

Pull Requestは、変更の安全性、正当性、テスト、運用影響を確認するために使用する。

小規模な個人開発であっても、重要な安全変更ではPull Requestを推奨する。

# 6.2 Pull Request本文

最低限、次を記載する。

```markdown
# 変更概要

# 変更理由

# 対象ファイル

# 安全性への影響
- 新規注文:
- 既存ポジション管理:
- Risk Manager:
- 外部障害時:
- Secret:
- production:

# テスト
- [ ] Unit Test
- [ ] MQL5 Compile
- [ ] MQL5 Script Test
- [ ] CDK Test
- [ ] CDK Synth
- [ ] Development Release Gate

# 未確認事項

# Rollback方法

# 関連文書
```

該当しない項目には「該当なし」と記載する。

# 6.3 Draft Pull Request

次の場合はDraftとして作成する。

* 実装途中
* Test未完了
* 外部環境が必要
* 設計Reviewが必要
* 安全上の懸念が残っている

---

# 7. Review観点

Reviewでは、コードStyleだけでなく次を確認する。

## 7.1 安全性

* Error時にALLOWしていないか
* Risk Managerを迂回していないか
* 既存ポジション管理を外部依存へ結合していないか
* 古い候補やALLOWを再利用していないか
* Lot、SL、TP、Margin、Spreadの扱いが安全か
* productionの安全な初期値を変更していないか

## 7.2 セキュリティ

* Secretがコード、ログ、Testへ含まれていないか
* IAMが広すぎないか
* 認証やReplay対策を弱めていないか
* Account情報をログへ出していないか
* DynamoDB TTLの対象が正しいか

## 7.3 データ・ML

* 未来情報を使用していないか
* OOS情報がTrainingへ混入していないか
* Calibration期間が分離されているか
* Metric定義を変更していないか
* Model ArtifactのVersionとchecksumを維持しているか

## 7.4 API契約

* JSON Schemaが更新されているか
* MQL5 ClientとLambdaの両方が更新されているか
* Backward Compatibilityが考慮されているか
* 未知Fieldを黙って受け入れていないか

## 7.5 運用

* AlarmやLogへの影響があるか
* Rollback可能か
* 文書が更新されているか
* 新しい未完了作業が`TASKS.md`へ追加されているか
* 新しい設計判断が`DECISIONS.md`へ記録されているか

---

# 8. 必須テスト

変更内容に応じて必要なTestを実行する。

## 8.1 MQL5変更

```powershell
.\tools\compile-mql5.ps1
.\tools\run-mql5-tests.ps1
```

## 8.2 Python・Lambda・ML・LLM変更

関連するPytestを実行する。

可能であれば全体Testを実行する。

## 8.3 CDK変更

```powershell
cd infra
cdk synth -c environment=dev
```

AWSへ変更を加える前に `cdk diff` を確認する。

## 8.4 重要な変更

```powershell
.\tools\release-gate.ps1 -Mode Development
```

# 8.5 Test未実行時

環境不足などでTestできない場合、Pull Requestへ次を記載する。

* 実行できなかったTest
* 理由
* 必要な環境
* 代替確認
* 残るRisk
* 実行予定のコマンド

---

# 9. Merge方針

* Review可能な状態になるまでMergeしない。
* 必須Testが失敗している状態でMergeしない。
* 未解決の安全上の懸念がある場合はMergeしない。
* Secret混入が疑われる場合はMergeしない。
* productionへの影響が不明な場合はMergeしない。
* 文書と実装が矛盾した状態でMergeしない。

Repository設定が許す場合、履歴を読みやすくするためSquash Mergeを基本候補とする。

ただし、複数Commitの履歴自体に意味がある場合は、通常MergeまたはRebase Mergeを選択できる。

Merge方式はRepository設定と運用状況に合わせて統一する。

---

# 10. `master`への直接変更

原則として、重要な実装変更を`master`へ直接Commitしない。

次のような軽微な変更では、ユーザー判断により直接変更を許容できる。

* 誤字修正
* リンク修正
* コメント修正
* 挙動を変更しない小さな文書修正

次は専用BranchとReviewを使用する。

* MQL5売買処理
* Risk Manager
* Position Manager
* Order Manager
* SL・TP
* 認証・HMAC
* Replay防止
* API契約
* ML・LLM
* AWS CDK
* IAM
* Secret
* Release Gate
* production設定

---

# 11. Release BranchとTag

Release BranchやTagは、実際にRelease Candidateを管理する必要が生じた時点で導入する。

導入する場合の候補：

```text
release/<version>
```

Tag候補：

```text
v<major>.<minor>.<patch>
```

Tag作成前に、少なくとも次を確認する。

* Development Release Gate
* Version更新
* CHANGELOGまたはRelease Note
* Production Evidenceの状態
* 未確認事項
* Rollback先
* Model Version
* Prompt Version
* AWS Environment

本番GateがNO-GOの状態で、production承認を意味するTagを作成しない。

---

# 12. 禁止するGit操作

ユーザーの明示的な依頼なしに次を実行しない。

```text
git reset --hard
git clean -fd
git push --force
git push --force-with-lease
git rebase --onto
git filter-branch
git filter-repo
```

また、明示的な依頼なしに次を行わない。

* Branch削除
* Tag削除
* History Rewrite
* Remote変更
* 大量ファイル削除
* Commit
* Push
* Pull Request作成

---

# 13. SecretをCommitした場合

Secret混入が判明した場合、単に最新Commitから削除するだけでは不十分である。

次を行う。

1. Secretの利用を停止する。
2. SecretをRotationまたは失効する。
3. 影響範囲を確認する。
4. Git履歴からの削除方法を検討する。
5. Log、CI Artifact、Pull Request上の露出を確認する。
6. Incidentとして記録する。
7. 再発防止TestまたはScanを追加する。

秘密値そのものをIssue、Pull Request、Chatへ転載しない。

---

# 14. 文書管理

変更内容に応じて次を更新する。

* 設計仕様: `docs/`
* 今後の作業: `TASKS.md`
* 設計判断: `DECISIONS.md`
* Claude Code規約: `CLAUDE.md`
* Git運用: `CONTRIBUTING.md`
* 引き継ぎ状況: `HANDOFF.md`

一時的な作業メモを、恒久的な仕様文書として放置しない。
