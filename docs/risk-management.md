# リスク管理

## 優先順位

リスク管理コンポーネント（Risk Manager）は常に最終決定者で、異常時は拒否する。評価順はシステム健全性、緊急停止、最大DD、日次損失、スプレッド、SL妥当性、ポジションサイズ、反対方向ポジション・同一方向ポジション数上限・最小エントリー距離（Exposure Guard）、総オープンリスク上限（Open Risk Guard）、必要証拠金・余剰証拠金、証拠金維持率（Margin Level）、`OrderCheck` とする。

## 初期上限

- 1取引のリスク: 有効証拠金の0.5%
- 日次損失: 日次開始有効証拠金の2%。実現損益と未実現損失を含む保守的な値で停止
- 最大ドローダウン: 最高有効証拠金から10%
- 最大同時ポジション数: 設定値（初期1、口座全体）
- 同一銘柄・同一方向の最大同時ポジション数: 設定値（初期1、`InpMaxSameDirectionPositions`）
- 総オープンリスク（口座全体の既存ポジションのSLリスク合計＋新規候補）: 有効証拠金の2%（`InpMaxOpenRiskPercent`）
- 証拠金維持率（Margin Level）: 150%を下回れば新規エントリー拒否（`InpMinMarginLevelPercent`）
- マーチンゲール、損失後のロット増加、無制限のポジション追加: 禁止

日付境界はブローカーサーバー時刻を正とし、タイムゾーン・DSTをログに残す。再起動でガードがリセットされないよう、取引履歴と永続化した最高値から復元する。復元不能時は新規注文を拒否する。

Phase 3では日次開始有効証拠金と日次ロックを日付付きターミナルグローバル変数へ、口座全体の最高有効証拠金とDDロックを口座ログイン付きグローバル変数へ保存する。初回起動が日中の場合、当日取引履歴から開始残高を逆算し、現在の有効証拠金との大きい方を基準値にする。前日から持ち越したポジションの午前0時時点の有効証拠金は復元できないため、これは損失を小さく見積もらないための保守的近似である。Phase 9の日次スナップショット導入後に正確な基準値へ置き換える。

日次ロックはブローカー日付変更で新しいキーへ移行する。DDロックは有効証拠金の回復やEA再起動では解除しない。原因レビュー、口座状態確認、ログ保全の後、MT5グローバル変数画面で対象口座の `ETS.DD.LOCK.<login>` を運用者が明示的に削除した場合だけ解除される。最高有効証拠金は原則削除しない。

## ポジションサイズ計算

`risk_budget = equity × risk_rate`。1ロットのSL損失は可能なら `OrderCalcProfit(direction, symbol, 1.0, entry, stop)` の絶対値で口座通貨換算し、無効時のみティックサイズ・ティック価値から算出する。`raw_lot = risk_budget / loss_per_lot` を取引数量の刻み幅へ必ず切り下げ、最小値未満なら取引しない。最大値、数量上限、既存エクスポージャー、必要証拠金、余剰証拠金、ストップ・フリーズレベル、`OrderCheck`を検査する。切り上げは禁止する。

Phase 3のエントリー価格はシグナルバー終値ではなく、リスク評価時点のBUY Ask・SELL Bidで再計算する。現在価格でSLの方向またはブローカーのストップレベルが不正になれば拒否する。余剰証拠金の初期留保率は20%。全口座のポジション数を上限判定に含める。

## 複数ポジション同時保有の安全設計（2026-08-23追加）

`InpMaxSameDirectionPositions=1`（既定値）の間は、従来どおり同一銘柄に既存ポジションがあれば方向・マジックナンバーを問わず新規追加を拒否する（`OPPOSITE_DIRECTION_POSITION_EXISTS`または`MAX_SAME_DIRECTION_POSITIONS`）。ユーザーが明示的に`InpMaxSameDirectionPositions>1`へ引き上げた場合のみ、以下の制限付きでピラミッディングを許可する。

* **反対方向は常に禁止**: 同一銘柄で既存ポジションと反対方向の候補は、`InpMaxSameDirectionPositions`の値に関わらず常に拒否する（両建て・ドテンは本機能の対象外）。
* **同一方向は上限まで許可**: 同一銘柄・同一方向の既存ポジション数が`InpMaxSameDirectionPositions`未満の場合のみ追加を許可する（`CExposureGuard::Evaluate`）。
* **最小エントリー距離**: `InpMinSameDirectionEntryDistancePoints>0`の場合、直近の同方向ポジションの建値から最低この距離だけ離れていなければ追加を拒否する（`MIN_ENTRY_DISTANCE`）。近接した価格帯へのナンピン的な積み増しを防止する。
* **各ポジションは独立してサイジングされる**: 追加エントリーも通常のCandidateと同じく`InpRiskPerTradePercent`ベースでPosition Sizerが算出する。既存ポジションの含み損に応じてロットを増やす仕組みは存在しない（禁止実装のマーチンゲール・損失後のロット増加を回避）。
* **総オープンリスク上限が最終的な歯止め**: 個々のポジション数制限とは独立に、口座全体の既存ポジションのSLリスク合計＋新規候補のリスクが`InpMaxOpenRiskPercent`を超えれば拒否する（`MAX_OPEN_RISK_EXCEEDED`、下記参照）。
* **Netting口座では常に1**: `ACCOUNT_MARGIN_MODE_RETAIL_NETTING`の口座では、同一銘柄・同一方向の複数ポジションを独立したticketとして維持できず自動的に一本化されるため、`InpMaxSameDirectionPositions`の設定値に関わらず実効上限を1として扱う（`CExposureGuard::EffectiveMaxSameDirection`）。OANDA証券MT5（本番想定）はHedging口座であることを確認済み（HANDOFF.md）。
* **ポジション単位の管理はticketベース**: `CPositionManager`のEmergency Close・建値ストップ・シグナル失効Exit・Time Stopはいずれも`PositionSelectByTicket`とticket単位のGlobalVariableべき等性キーで動作しており、複数ポジション同時保有時も各ポジションを独立して管理する（本機能追加による変更なし、既存設計のまま対応済み）。
* **重複エントリー防止**: 同一確定足からの複数エントリーは、`COrderManager`の`ETS.ORDER.LAST.<login>.<magic>.<symbol>`キー（signal_bar_time以下の候補を拒否）により従来どおり1バー1エントリーに制限される。複数ポジションは異なる確定足でのみ積み増しされる。

## 総オープンリスク管理（Open Risk Guard、2026-08-23追加）

新規エントリー候補の評価時、`COpenRiskGuard`が口座全体（他EA・手動注文を含む）の既存ポジションについて、現在設定されているSLへ到達した場合の損失額（`OrderCalcProfit(direction, symbol, volume, open_price, stop_loss)`の絶対値）を合算し、新規候補の推定SLリスク（`decision.estimated_stop_loss`）を加えた合計が、有効証拠金の`InpMaxOpenRiskPercent`を超えないかを判定する（`MAX_OPEN_RISK_EXCEEDED`）。

SL未設定、またはSLの方向が不正（BUYでSL≧建値等）で計算不能なポジションが1件でもあれば、総リスクを過小評価しないよう安全側で新規エントリーを拒否する（`RISK_STATE_UNAVAILABLE`/`OPEN_RISK_UNCALCULABLE`）。ただしSL未設定ポジションが自EA管理下（magic一致）であれば、`CPositionManager::Monitor`が先に検知し`UNPROTECTED_POSITION`として新規注文を止めるため、この経路に到達するのは主に他EA・手動注文にSL未設定ポジションが存在する場合である。

## Margin Level監視（2026-08-23追加）

`InpMinMarginLevelPercent>0`かつ`ACCOUNT_MARGIN>0`（既存ポジションが存在する状態）のとき、証拠金維持率（`ACCOUNT_MARGIN_LEVEL`）がこの閾値を下回れば新規エントリーを拒否する（`MARGIN_LEVEL_TOO_LOW`）。既存の`InpMinimumFreeMarginPercent`（必要証拠金に対する余剰証拠金の留保率）とは独立した指標で、口座全体の証拠金維持率という別の角度からの安全網として追加した。既存ポジション管理（SL/TP・建値ストップ・Time Stop等）には影響しない。ブローカー固有のロスコール・追証水準は未確認（NOT VERIFIED）のため、実運用前にOANDA証券の実際の水準を確認し、必要に応じて閾値を調整すること。DrawdownGuard/DailyLossGuardと異なり永続ロックは行わない（市場変動で回復しうる指標のため、都度判定）。

## 理由コード

`DD_LIMIT`, `DAILY_LOSS_LIMIT`, `EXPOSURE_LIMIT`, `POSITION_LIMIT`, `DUPLICATE_POSITION`, `OPPOSITE_DIRECTION_POSITION_EXISTS`, `MAX_SAME_DIRECTION_POSITIONS`, `MIN_ENTRY_DISTANCE`, `MAX_OPEN_RISK_EXCEEDED`, `INVALID_STOP`, `SIZE_BELOW_MIN`, `MARGIN_INSUFFICIENT`, `MARGIN_LEVEL_TOO_LOW`, `SPREAD_TOO_WIDE`, `ORDER_CHECK_FAILED`, `RISK_STATE_UNAVAILABLE` を安定した機械可読コードとして記録する。
