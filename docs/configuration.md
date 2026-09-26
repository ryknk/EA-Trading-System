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
| `InpBreakoutBufferPoints` | 0 | ブレイク閾値へのbuffer（2026-08-17、効果不十分のため0へ差し戻し、詳細はTASKS.md参照） |
| `InpPullbackAtrTolerance` | 0.15 | 押し目のATR許容幅（2026-08-17、誤発注抑制のため0.25→0.15へ縮小。押し目判定も1本足からタッチ足(shift2)＋確認足(shift1)の2本足確認へ変更。確認足のEMA近接制約・タッチ足の逆行性制約はいずれも効果不十分のため撤回済み、詳細はTASKS.md参照） |
| `InpPullbackTriggerAtrBuffer` | 0.10 | Pullback Entry Trigger（確認足の再加速判定）が、タッチ足高安値を単に上回る/下回るだけでなくATR基準の余裕幅を要求するようにする追加条件。0は無効化（従来のIsPullbackTriggerと完全一致）。2026-08-23追加、2026-09-13に4銘柄Fold1-5検証（純利益+3.1%、発火頻度低いが新規リスクなし）を経て既定値0.10へ更新。詳細はTASKS.md参照 |
| `InpRsiBuyMin` / `InpRsiBuyMax` | 50 / 75 | BUY RSI範囲（2026-08-17、55への引き上げは逆効果と判明したため50へ差し戻し、詳細はTASKS.md参照） |
| `InpRsiSellMin` / `InpRsiSellMax` | 25 / 50 | SELL RSI範囲（2026-08-17、45への引き下げは逆効果と判明したため50へ差し戻し、詳細はTASKS.md参照） |
| `InpMinimumAtrPoints` | 10 | 最低volatility |
| `InpAdxPeriod` | 14 | ADX（トレンド強度）期間（2026-08-17追加、詳細はTASKS.md参照） |
| `InpMinimumAdx` | 20 | H1 ADXの最低閾値。下回るとトレンド強度不足として候補を棄却（2026-08-17追加。25への引き上げは逆効果と判明したため20へ差し戻し、`results/backtests/20260817-104528-USDJPY-H1/`が現時点の最良状態、詳細はTASKS.md参照） |
| `InpMinimumConfirmationAdx` | 20 | H4（`InpConfirmationTimeframe`）ADXの最低閾値。H1 ADXフィルタに加えた多段フィルタとして、下回るとトレンド強度不足として候補を棄却（2026-08-17追加、詳細はTASKS.md参照） |
| `InpMaximumAdx` | 0（無効） | H1 ADXの上限閾値。上回るとエグゾーション（過熱）局面として候補を棄却。0は無効化（既定挙動）。2026-08-23追加、詳細はTASKS.md参照 |
| `InpStopAtrMultiple` | 2 | SLのATR倍率（初期実装からATRベース。2026-08-17、1.0/1.25/1.5/1.75/2.0/2.5/3.0でスイープし、1.5が純損益・PFで最良だったが隣接水準(1.25/1.75)が非単調に悪化しIS期間への過学習リスクがあるため2.0を維持、詳細はTASKS.md参照） |
| `InpRiskRewardRatio` | 2 | TP/SL比（初期実装からATRベース。2026-08-17、1.5/2.0/2.5/3.0でスイープし2.0が最良と再確認、詳細はTASKS.md参照） |
| `InpEnableBreakout` / `InpEnablePullback` | true / true | entry pattern有効化 |
| `InpEntryUseStagedPipeline` | true | 段階的Entry判定パイプライン（Market Regime→HTF Bias→Setup→Entry Trigger）を有効化する（2026-08-22追加、2026-09-13にFold1-5検証結果を受けて既定trueへ更新）。falseにすると既存方式（Stage 1のRange/Unknown棄却ゲートなし）と完全に同一の判定・発注挙動に戻る。詳細は本節末尾および`docs/backtesting.md`「段階的Entry判定パイプライン」を参照 |
| `InpEntryRequireMarketRegimeTrend` | true | `InpEntryUseStagedPipeline=true`の場合のみ有効。市場レジームがRange/Unknownの確定足でEntry候補を棄却する（2026-08-22追加） |
| `InpRegimeTrendAdxMin` | 40 | 市場レジーム判定用のADX下限。下回るとRange判定（Entry判定のADXフィルタとは独立）。2026-09-13、Fold1 Train/Walk Forwardスイープ（2026-08-22/23、TASKS.md参照）で一貫して最良と確認された40へ既定値を更新し、同時に`InpEntryUseStagedPipeline`も既定`true`へ更新したため実際にEntry判定へ反映される（`InpEntryUseStagedPipeline=false`にすると本フィールドはログ記録専用に戻る） |
| `InpRegimeAtrBaselinePeriod` | 50 | ボラティリティ判定用ATRベースライン（単純平均）の算出本数 |
| `InpRegimeHighVolatilityRatio` | 1.3 | ATR/ベースライン比がこの値以上でHighVolatility判定 |
| `InpRegimeLowVolatilityRatio` | 0.7 | ATR/ベースライン比がこの値以下でLowVolatility判定 |
| `InpRegimeMaSlopeLookback` | 5 | トレンド方向判定用、H1 EMA(Fast)の参照本数（現在値と何本前を比較するか） |

市場レジーム判定（`InpRegime*`）自体は`CMarketRegimeClassifier`（既存、変更なし）が行う。`InpEntryUseStagedPipeline=false`にすると、この判定結果は監査ログ記録のみに使われ、Entry判定・発注・既存ポジション管理には一切影響しない（判定と売買制御の分離）。`InpEntryUseStagedPipeline=true`（既定値）では、`InpEntryRequireMarketRegimeTrend`に従いRange/Unknown判定をEntry棄却条件として使用する。詳細は`docs/backtesting.md`「条件別分析」および「段階的Entry判定パイプライン」を参照。

固定値を最適化結果だけで変更しない。変更前にOOS期間と受入基準を固定し、Walk Forwardとデモで再検証する。

### 段階的Entry判定パイプライン（`InpEntryUseStagedPipeline`）

`CTrendFollowingStrategy::Evaluate()`は、既存の単一関数による閾値判定を、次の4段階として明示的に区別できる構造を持つ（2026-08-22追加）。

```text
Stage 1 Market Regime  : CMarketRegimeClassifier（既存の再利用、Trend/Range判定）
Stage 2 HTF Bias        : D1/H4 EMAトレンド一致（既存のCTrendFollowingRules::TrendDirection、変更なし）
Stage 3 Setup            : 押し目/戻り成立（CTrendFollowingRules::IsPullbackSetup）、
                            またはブレイクアウトのレンジ形成
Stage 4 Entry Trigger    : Setup成立後の再加速（CTrendFollowingRules::IsPullbackTrigger）、
                            またはレンジ突破（CTrendFollowingRules::IsBreakout、既存、変更なし）
```

`InpEntryUseStagedPipeline=false`にすると、Stage 1のRange/Unknown棄却ゲートが働かない点を除き、判定式は既存方式と完全に同一である（`IsPullback`は内部で`IsPullbackSetup && IsPullbackTrigger`として再定義されているが、数式は変更前と等価）。`true`（既定値）では、Stage 1でRange/Unknown判定の確定足を追加で棄却する（`InpEntryRequireMarketRegimeTrend=true`の場合）。

**既定値true採用の経緯（2026-09-13、ユーザー判断）**: `InpRegimeTrendAdxMin=40`を実際にEntry判定へ反映させる目的で既定`true`へ更新した。Fold1-5検証（EarlyAdverseExit ON・TriggerR=0.75を土台）で、無効化時はトレード数が5倍（525→2,642件）に急増するが、これは`entry_adx`が20台まで許容されることによる低品質トレードの薄利多売であり、1トレードあたりの期待値は290.4円→95.6円、簡易最大DDは77,100円→171,984円へ悪化することを確認した。純利益の絶対額は無効化の方が大きい（+65.7%）が、質・リスク両面で有効化（既定値）が優れていると判断した。詳細はTASKS.md参照。Final Holdoutでの最終確認は未実施。

各段階の合否は、`CANDIDATE`イベント（Entry成立時のみ）と、`InpEntryUseStagedPipeline=true`の場合に限り毎確定足で記録される新規イベント`ENTRY_PIPELINE`（`stage_market_regime`・`stage_htf_bias`・`stage_breakout_setup_passed`・`stage_breakout_trigger_passed`・`stage_pullback_setup_passed`・`stage_pullback_trigger_passed`・`final_status`・`reason_code`・`reason`）へ記録される。`InpEntryUseStagedPipeline=false`のままでは`ENTRY_PIPELINE`イベントは記録されず、既存の監査ログ量・スキーマに影響しない。

既存方式（false）と段階的方式（true）の比較は、同一IS期間で`InpEntryUseStagedPipeline`のみを変更した2回のStrategy Tester実行を、`docs/backtesting.md`の既存手順（Net Profit・Profit Factor・Sharpe・取引数等）で比較する。段階的方式のみ、`ENTRY_PIPELINE`ログから各Stageの棄却件数も追加で確認できる。

### トレンド継続反転Exit（`InpEnableTrendReversalExit`、2026-09-12追加）

OOS分析（`python.analysis.trade_breakdown`の`reversal_from_profit`/`giveback_from_peak_profit`）で、トレンド相場の負けトレードの多くが「含み益に到達→反転→初期SL到達」のパターンを辿っていることが確認された。本Exitは、初期SL/TPの契約自体を変更せず、トレンド継続が崩れたと判断できる場合に初期SLへ到達する前の早期決済を行う。

**対象**: `InpMagicNumber`（トレンドフォロー戦略）が保有するポジションのみ。レンジ戦略（`InpMeanReversionMagicNumber`）は対象外（既存のRange Filter/BB Width Exitで別途管理する）。

**判定フロー（反転検知→継続確認→Exit）**:

```text
1. Trendレジーム確認: CMarketRegimeClassifierの現在値（既存のH1 ADX/EMA(Fast)ハンドル・regime_*設定を再利用）が
   TrendUp/TrendDownの間のみ有効。Range/Unknownへ変わったら監視状態を破棄し、既存のSL/TP・他のExitへ委ねる。
2. Activation: 含み益ピーク（Peak Favorable Price、Tick単位で追跡）が「建値〜当初SL距離（初期リスク）」の
   InpTrendReversalActivationR倍以上に到達するまでは監視しない。
3. 反転検知: Peakからの逆行がInpTrendReversalRetraceR倍（R）以上になったら「反転」を検知する。
4. 継続確認: 反転検知がInpTrendReversalConfirmationTicks回連続で継続したら決済する（一時的なTickノイズによる
   誤Exitを防ぐ）。Peak方向へ戻れば確認カウンタは0へリセットされ、再度反転すればカウントをやり直す。
5. Exit: 市場成行で決済する（初期SL/TP自体は変更しない）。
```

Long/Short対称に実装されている（`CTrendReversalExitRules`、`mt5/Include/Trading/PositionManager.mqh`）。当初SL（`initial_stop_loss`）はATRトレーリング等によるSL変更の影響を受けないよう、初回検知時にCTimeStopTrackerと同じ考え方で固定する（`CTrendReversalTracker`、CTimeStopTrackerとは目的が異なる別系統として独立管理し、`InpEnableTimeStop`の有効・無効に関わらず動作する）。

決済時、監査ログへ`TREND_REVERSAL_EXIT`イベント（`reason_code`固定値`TrendReversalConfirmed`、`trend_direction`、`peak_price`、`peak_mfe_r_multiple`、`retracement_r_multiple`、`confirmation_count`）が記録される（ローカル監査のみ、TIME_STOP_EXIT/RANGE_EXITと同じく既存TRADE_CLOSEDの契約は変更しない）。`python.analysis.trade_breakdown.trend_reversal_exit_summary()`でBaseline（`InpEnableTrendReversalExit=false`）とON（true）のバックテスト結果を比較できる。詳細は`docs/backtesting.md`「トレンド継続反転Exit比較分析」を参照。

### 初期逆行Exit（`InpEnableEarlyAdverseExit`、2026-09-12追加）

トレンド継続反転Exit（ConfirmationTicksスイープ、`docs/backtesting.md`「トレンド継続反転Exit比較分析」）導入後のOOS分析で、SLへ至った負けトレードの92.5%（254件中235件）が`InpTrendReversalActivationR`（含み益ピークによる反転監視の開始ライン）へ一度も到達していないと判明した。トレンド継続反転Exitは含み益ピークの存在を前提とするため、この92.5%の損失パターンには構造的に対処できない。本Exitは、含み益ピークを一切参照せず、建値からの逆行のみを基準にすることで、この損失パターンに対処する。

**対象**: `InpMagicNumber`（トレンドフォロー戦略）が保有するポジションのみ。レンジ戦略（`InpMeanReversionMagicNumber`）は対象外。トレンド継続反転Exitと異なり、現在の市場レジーム（TrendUp/TrendDown/Range）は判定条件にしない（判断が含み益ピークではなく建値からの絶対距離のみに基づくため）。

**判定フロー（逆行検知→継続確認→Exit）**:

```text
1. 逆行検知: 建値からの逆行が「建値〜当初SL距離（初期リスク）」のInpEarlyAdverseExitTriggerR倍以上になったら検知する。
   含み益ピークへの到達は問わない（一度も含み益に転じていないトレードにも適用される）。
2. 継続確認: 逆行検知がInpEarlyAdverseExitConfirmationTicks回連続で継続したら決済する（一時的なTickノイズによる
   誤Exitを防ぐ）。逆行が解消（トリガー未満へ回復）すれば確認カウンタは0へリセットされ、再度検知すればカウントをやり直す。
3. Exit: 市場成行で決済する（初期SL/TP自体は変更しない）。
```

Long/Short対称に実装されている（`CEarlyAdverseExitRules`、`mt5/Include/Trading/PositionManager.mqh`）。当初SL（`initial_stop_loss`）はATRトレーリング等によるSL変更の影響を受けないよう、初回検知時に固定する（`CEarlyAdverseExitTracker`、CTrendReversalTrackerと異なり含み益ピークを扱わない別系統として独立管理する）。継続確認（`HasConfirmedReversal`）の判定ロジックは`CTrendReversalExitRules`と完全に同一のため、そのまま再利用している。

決済時、監査ログへ`EARLY_ADVERSE_EXIT`イベント（`reason_code`固定値`EarlyAdverseConfirmed`、`adverse_r_multiple`、`confirmation_count`）が記録される（ローカル監査のみ、既存TRADE_CLOSEDの契約は変更しない）。`python.analysis.trade_breakdown.early_adverse_exit_summary()`でBaseline（`InpEnableEarlyAdverseExit=false`）とON（true）のバックテスト結果を比較できる。トレンド継続反転Exitと同時に有効化した場合、含み益ピークからの反転がトリガー到達より先に確定するトレードでは、トレンド継続反転Exit側が先に決済する（評価順序は`CEAController::OnTick`参照）。

`InpEarlyAdverseExitTriggerR`を1.0以上にする運用は推奨しない。`InpStopAtrMultiple`によるSL到達（1.0R相当）より先に、または同時に発動する意味がなくなるため。

**既定値の採用経緯（2026-09-13、ユーザー判断）**: Fold1-5でのスイープ検証（`docs/backtesting.md`「初期逆行Exit比較分析」）で、TriggerR=0.3〜0.65は明確に有害（発動率60%超、正常なトレードまで大量に早期決済し純利益がBaselineを下回る）と判明した一方、TriggerR=0.70〜0.85の範囲でBaselineを上回った。純利益単体では0.70が最大（Fold×銘柄20区分中12区分で改善）だったが、0.75の方が改善区分数が多く（14区分）頑健性が高いと判断し、`InpEnableEarlyAdverseExit=true`・`InpEarlyAdverseExitTriggerR=0.75`を既定値として採用した。**この採用はFold1-5への複数回のパラメータ適合に基づくものであり、Final Holdout（2025-01〜2026-08）での最終確認は未実施**（詳細はTASKS.md参照）。

## リスク・注文設定

| 設定 | 初期値 | 意味 |
|---|---:|---|
| `InpRiskPerTradePercent` | 0.5% | 1取引の最大リスク |
| `InpEnableAdaptiveSizing` | false | 直近の実現成績（平均R倍数相当の連続値）に応じてリスク量を滑らかに縮小する機能の有効化（2026-08-23追加、2026-08-23に勝率の二値閾値方式から連続値方式へ再設計）。相場が悪いかを事前予測せず、実際に悪い結果が続いた場合にのみリスク量を縮小する（詳細はTASKS.md参照）。falseでは従来どおり`InpRiskPerTradePercent`をそのまま使用する |
| `InpAdaptiveSizingLookbackTrades` | 10 | 直近何件の決済済みポジション（部分決済は1件扱い）で平均R倍数相当を算出するか。`InpEnableAdaptiveSizing=false`では未使用。直近の該当件数がこれに満たない場合は縮小なし（1.0倍）として扱う |
| `InpAdaptiveSizingSensitivity` | 1.0 | 直近平均R（0未満の場合のみ）に乗じて1.0から減算する感度係数。値が大きいほど同じ悪化幅に対して縮小が強くなる。`InpEnableAdaptiveSizing=false`では未使用 |
| `InpAdaptiveSizingFloorMultiplier` | 0.5 | 縮小倍率の下限（0.5＝最大でも半分まで）。`InpRiskPerTradePercent`へ乗じる倍率は`[InpAdaptiveSizingFloorMultiplier, 1.0]`の範囲でクランプされる。`InpEnableAdaptiveSizing=false`では未使用 |
| `InpDailyLossLimitPercent` | 2% | 日次新規注文停止閾値 |
| `InpMaxDrawdownPercent` | 10% | 口座全体のDD停止閾値 |
| `InpMaxOpenPositions` | 1 | 最大同時ポジション数（口座全体、他EA・手動注文を含む） |
| `InpMaxSameDirectionPositions` | 1 | 同一銘柄・同一方向への最大同時ポジション数（2026-08-23追加）。既定値1は従来どおり同一銘柄への追加を実質禁止する。1より大きい値にすると、`InpMinSameDirectionEntryDistancePoints`・`InpMaxOpenRiskPercent`の範囲内で制限付きピラミッディングを許可する。反対方向の既存ポジションは値に関わらず常に拒否（`OPPOSITE_DIRECTION_POSITION_EXISTS`）。Netting口座（`ACCOUNT_MARGIN_MODE_RETAIL_NETTING`）では複数ポジションを独立したticketとして維持できないため、設定値に関わらず1として扱う |
| `InpMaxOpenRiskPercent` | 2% | 総オープンリスク上限（2026-08-23追加）。口座全体の既存ポジション（他EA・手動注文を含む）が現在のSLへ到達した場合の損失合計に、新規候補のリスクを加えた額が、有効証拠金のこの割合を超える場合は新規エントリーを拒否（`MAX_OPEN_RISK_EXCEEDED`）。SL未設定など計算不能なポジションが1件でもあれば安全側で新規エントリーを拒否する（`RISK_STATE_UNAVAILABLE`/`OPEN_RISK_UNCALCULABLE`）。`InpRiskPerTradePercent`以上である必要がある |
| `InpMinSameDirectionEntryDistancePoints` | 0（無効） | 同一銘柄・同一方向への追加エントリー時、直近の同方向ポジションの建値からこのPoint数以上離れていることを要求する（2026-08-23追加、ナンピン的な近接積み増しの防止）。0は無効化（既定挙動） |
| `InpMinMarginLevelPercent` | 150% | 証拠金維持率（Margin Level）がこの値を下回る場合は新規エントリーを拒否する（2026-08-23追加、`MARGIN_LEVEL_TOO_LOW`）。既存ポジション管理には影響しない。0で無効化。ブローカー固有のロスカット水準は未確認（NOT VERIFIED）のため、実運用前にOANDA証券の実際の水準を確認すること |
| `InpMaxSpreadPoints` | 30 | 最大spread |
| `InpMinimumFreeMarginPercent` | 20% | 最低free margin率 |
| `InpMagicNumber` | 26072001 | EA所有取引の識別子 |
| `InpMaxDeviationPoints` | 10 | 最大許容deviation |
| `InpEmergencyStop` | false | trueで新規注文を即時停止 |
| `InpStrategyEnabled` | true | falseでStrategyの新規候補処理を停止。既存ポジション監視は継続 |
| `InpEnableTradeMutations` | false | 発注・決済変更の主安全フラグ |
| `InpCloseUnprotectedPositions` | true | 保護SLなしの所有positionを緊急決済対象にする |
| `InpEnableBreakevenStop` | true | 建値ストップ移動の有効化（2026-08-17追加、詳細はTASKS.md参照） |
| `InpBreakevenTriggerR` | 1.0 | 含み益が「建値〜当初SL距離（初期リスク）」の何倍に達したら建値へSLを引き上げるか（2026-08-17追加）。`InpEnableTradeMutations=false`では発動しない。単一銘柄IS期間での0.5/0.75/1.25/1.5/2.0スイープ比較で1.0が純損益・PF・Sharpe・期待利得・最大連敗のすべてで最良またはタイの結果を確認済み（詳細はTASKS.md 2.1参照）。部分利確（1R/1.5Rトリガー）は建値ストップ単体を上回らなかったため撤回済み。ATRトレーリングストップは2026-08-17に単一銘柄IS期間の1点（1.0Rトリガー・2.0×ATR幅）でのみ検証し撤回したが、2026-09-05に4銘柄OOS・2次元グリッドで再検証した結果は建値ストップ単体と拮抗〜やや上回る結果となった（詳細はTASKS.md 2.1.3参照、Final Holdout未確認のため採用は保留） |
| `InpEnableAtrTrailingStop` | false | ATRトレーリングストップの有効化（`mt5/Include/Trading/PositionManager.mqh`の`CAtrTrailingStopRules`、2026-09-05再実装）。トリガーR×ATR倍率の2次元グリッド検証結果はTASKS.md 2.1.3参照。建値ストップと同時に有効化すると、建値到達後も`ShouldTrail`の当初SL基準判定により建値ストップと独立して動作し続ける（両立可能だが評価は分離して実施） |
| `InpAtrTrailingTriggerR` | 1.0 | 含み益が「建値〜当初SL距離（初期リスク）」の何倍に達したらATRトレーリングを開始するか。開始判定は当初SL（エントリー時点の固定値）を基準にするため、建値ストップ等による現在SLの変更に影響されない |
| `InpAtrTrailingAtrMultiple` | 2.0 | トレーリング開始後、現在Bid/AskからATRの何倍離れた位置へSLを追従させるか。保護方向にのみ動かし緩めない |
| `InpEnableSignalInvalidationExit` | true | シグナル失効による早期Exitの有効化（2026-08-17追加、詳細はTASKS.md参照）。エントリー根拠（D1/H4トレンド一致・H1/H4 ADX）が保有中に消失したら決済する。RSI・エントリーパターンは再チェックしない。`InpEnableTradeMutations=false`では発動しない |
| `InpSignalExitCheckTrend` | true | シグナル失効判定にD1/H4トレンド反転チェックを含めるか（2026-08-17追加） |
| `InpSignalExitCheckH1Adx` | true | シグナル失効判定にH1 ADX閾値チェックを含めるか（2026-08-17追加） |
| `InpSignalExitCheckH4Adx` | false | シグナル失効判定にH4 ADX閾値チェックを含めるか（2026-08-17追加。H1 ADXと相関が高く冗長でTP到達を妨げるため、Trend+H1 ADXのみが最良と判明しfalseへ変更。`results/backtests/20260817-204940-USDJPY-H1/`が現時点の最良状態）。3条件すべてを無効化する組み合わせは`INVALID`扱い。いずれかの条件に該当したら完全決済する（一部利確は試行の結果TP希薄化により逆効果と判明し撤回済み、詳細はTASKS.md参照） |
| `InpEnableTimeStop` | true | 時間切れ決済（Time Stop）の有効化。エントリー後、`InpMaxHoldingBars`本（entry_timeframe換算の確定足数）経過しても決済されていないポジションを成行決済する。`InpEnableTradeMutations=false`では発動しない。2026-08-17、既知の最良状態（Trend+H1 ADXのみ全条件完全決済のシグナル失効Exit）上で既定値（20本・最低MFE0.5R要求）で有効化し検証したところ、実際の発動は209件中2件のみで既存のシグナル失効Exitとほぼ完全に重複し、本IS期間では純損益がわずかに悪化（-44,039→-48,223円）した。この結果を踏まえたうえで、ユーザー判断によりリスク管理上の方針として既定trueを維持することを決定（ポジションが無期限に保有され続けることを防ぐセーフティネットとして、IS単体での純損益への影響とは別に採用）。詳細はTASKS.md参照 |
| `InpMaxHoldingBars` | 20 | Time Stopが発動する経過バー数の上限（entry_timeframe換算）。`InpEnableTimeStop=true`時は1以上が必須 |
| `InpTimeStopRequireMinMfe` | true | trueの場合、`InpMaxHoldingBars`経過時点で保有中のMFE（最大含み益、価格ベースのピーク追跡、`InpBreakevenTriggerR`と同じ「建値〜当初SL距離」をR換算）が`InpTimeStopMinMfeR`未満のときのみTime Stopを発動する。到達済みなら通常のSL/TP/建値ストップに委ねる |
| `InpTimeStopMinMfeR` | 0.5 | Time Stopの最低MFE閾値（R倍数）。`InpTimeStopRequireMinMfe=true`時は0より大きい値が必須。2026-09-13、EarlyAdverseExit導入後にこの免除条件の緩和（無効化）・強化（1.0Rへ引き上げ）の両方をFold1-5で検証したが、いずれもBaselineを下回った（免除無効化は決済トレードの91.2%が決済時点で既にプラスだったにもかかわらず強制決済してしまうため）。既定の0.5から変更しないこと。詳細はTASKS.md参照 |
| `InpEnableEntryTimingAnalysis` | false | Entry Timing比較分析（分析専用、実注文なし）を有効化する（2026-08-22追加）。プルバックSetupについて即時Entry・1本待ち・2本待ち・Trigger待ちの4方式をShadow Tradeとして並行シミュレートし監査ログへ記録する。falseの間はIndicatorハンドルすら作成せずコスト0で、既存の売買判断・発注には一切影響しない。詳細は`docs/backtesting.md`「Entry Timing比較分析」を参照 |
| `InpEntryTimingMaxWaitBars` | 6 | Trigger待ち(WAIT_TRIGGER)方式がTriggerの成立を探す最大バー数。この本数を超えてもTriggerが成立しない場合はWAIT_TRIGGERのShadow Tradeを生成しない（`InpEnableEntryTimingAnalysis=true`時は1以上が必須） |
| `InpEntryTimingMaxHoldingBars` | 20 | Shadow Trade（IMMEDIATE/WAIT_1_BAR/WAIT_2_BARS/WAIT_TRIGGERいずれも）の最大追跡バー数。SL/TP未到達のままこの本数へ達すると`EXPIRED`としてその時点の価格で打ち切る（`InpEnableEntryTimingAnalysis=true`時は1以上が必須） |
| `InpEnableTrendReversalExit` | false | トレンド継続反転Exit（Trend Reversal Exit）の有効化（2026-09-12追加）。OOS分析で確認された「含み益ピーク→反転→初期SL到達」の損失パターンを、初期SLへ到達する前の早期決済で抑制する。`InpEnableTradeMutations=false`では発動しない。既定値はOFF（安全側）。2026-09-13のEarlyAdverseExitとの併用検証では集計値上最良の結果だったが、Fold単位の改善区分数が単独設定より少なく頑健性が低い上、現行既定TriggerR（0.75）での再検証も未実施のため、Fold1-5への過剰適合回避を優先し既定`false`のまま据え置いた（判断理由の詳細は`docs/backtesting.md`「初期逆行Exit比較分析」の「TrendReversalExitを不採用のまま据え置いた理由」を参照）。詳細は本節末尾「トレンド継続反転Exit」を参照 |
| `InpTrendReversalActivationR` | 1.0 | 反転監視を開始する最低到達ライン。含み益ピークが「建値〜当初SL距離（初期リスク）」のこの倍数（R）以上に達するまでは監視自体を行わない。`InpEnableTrendReversalExit=true`時は0より大きい値が必須 |
| `InpTrendReversalRetraceR` | 0.5 | 反転検知の閾値。含み益ピークからの逆行が初期リスクのこの倍数（R）以上になったら「反転」として検知する。`InpEnableTrendReversalExit=true`時は0より大きい値が必須 |
| `InpTrendReversalConfirmationTicks` | 5 | 反転検知が何Tick連続で継続したら決済するか（一時的なTickノイズによる誤Exitを防ぐ継続確認）。Peak方向へ戻れば0へリセットされる。`InpEnableTrendReversalExit=true`時は1以上が必須 |
| `InpEnableEarlyAdverseExit` | true | 初期逆行Exit（Early Adverse Exit）の有効化（2026-09-12追加、2026-09-13にFold1-5検証結果を受けてユーザー判断により既定trueへ採用）。OOS分析で、SLへ至る負けトレードの多くがInpTrendReversalActivationRへ一度も到達していないと判明したため、含み益ピークの存在を前提にしないExitとして新設した。`InpEnableTradeMutations=false`では発動しない。詳細は本節末尾「初期逆行Exit」を参照 |
| `InpEarlyAdverseExitTriggerR` | 0.75 | 逆行検知の閾値。建値からの逆行が「建値〜当初SL距離（初期リスク）」のこの倍数（R）以上になったら検知する。`InpEnableEarlyAdverseExit=true`時は0より大きい値が必須（1.0以上は非推奨、本節末尾参照） |
| `InpEarlyAdverseExitConfirmationTicks` | 5 | 逆行検知が何Tick連続で継続したら決済するか（一時的なTickノイズによる誤Exitを防ぐ継続確認）。逆行が解消すれば0へリセットされる。`InpEnableEarlyAdverseExit=true`時は1以上が必須 |

`InpEnableTradeMutations` は最後に有効化する。Risk Manager、Decision API、LLMがALLOWでも、この値がfalseなら新規発注しない。本番ゲート未達の状態でtrueにしてはならない。

## 戦略実行モード（2026-09-05追加）

Trend戦略とRange（Mean Reversion）戦略の新規エントリー可否を、複数の有効/無効フラグの組み合わせではなく`InpStrategyMode`（`EStrategyMode`）一つで一元管理する。

| 値 | 名前 | 実行される新規エントリー処理 |
|---:|---|---|
| 0 | `STRATEGY_MODE_TREND_ONLY`（既定） | Trend戦略のみ。Range戦略は初期化・評価とも行われない（従来の`InpEnableMeanReversionStrategy=false`と同じ挙動） |
| 1 | `STRATEGY_MODE_MEAN_REVERSION_ONLY` | Range戦略のみ。Trend戦略のEntry判定自体は従来どおり実行されるが、その候補は新規発注に使わない |
| 2 | `STRATEGY_MODE_COMBINED` | 両戦略。Trend戦略が本確定足で候補を生成しなかった場合のみRange戦略を評価する（従来の`InpEnableMeanReversionStrategy=true`と同じ挙動） |

Trend・Rangeいずれのモードでも、Entry/Exit条件そのもの、Risk・Lot計算・Order・Position・Logging等の共通基盤、Magic Numberによる戦略識別（`InpMagicNumber`/`InpMeanReversionMagicNumber`）は変更しない。既存ポジションの管理・決済（`PositionManager::Monitor`、`PositionExitEvaluator`の各Exit判定）はモードに関わらず常に継続する。`STRATEGY_MODE_MEAN_REVERSION_ONLY`または`STRATEGY_MODE_COMBINED`を選んだ場合、`config.enable_mean_reversion_strategy`は自動的にtrueへ導出され、Range戦略のパラメータ検証（後述）が適用される。

IS/OOS/Walk Forwardの個別検証時は、同一の`.set`/`.ini`から`InpStrategyMode`の値だけを変えてTrendOnly・MeanReversionOnly・Combinedの3パターンを再実行することで、単独評価と併用結果を比較できる。

## レンジ相場逆張り戦略設定（2026-08-24仕様変更、2026-09-05: 有効化方法を`InpStrategyMode`へ統一）

トレンドフォロー戦略とは独立した第二の候補生成源。レンジ端（Bollinger Band外側）からの平均回帰を狙う。`STRATEGY_MODE_COMBINED`ではトレンドフォロー戦略が本確定足で候補を生成しなかった場合のみ評価され（両戦略が同一口座へ同時発注することを避ける排他制御）、`STRATEGY_MODE_MEAN_REVERSION_ONLY`ではトレンドフォロー戦略の候補有無に関わらず常に評価される。既存のRisk Manager・PositionManager・監査ログ基盤をそのまま共有するが、`InpMeanReversionMagicNumber`により別のMagic Numberでポジションを識別する（トレンドフォロー戦略のポジションと混同しない）。`InpStrategyMode=STRATEGY_MODE_TREND_ONLY`（既定）では初期化も評価も一切行われず、既存挙動を変えない。

**Range Filter**: Choppiness Index（`InpMeanReversionChoppinessMin`以上）かつADX（`InpMeanReversionAdxMax`未満）の両方を満たす場合のみレンジ相場と判定する。

**Entry**: 確定足のCloseがBand外側へブレイクした場合（Reentry待ち開始）、その後`InpMeanReversionMaxReentryBars`本以内に確定足のCloseがBand内側へ復帰した最初の確定足でのみ成立する（タッチのみでは反応しない。期限内に復帰しなければシグナル破棄。同一ブレイクから複数回エントリーしない）。`InpMeanReversionRestrictToTokyoSession=true`（既定false）の場合、エントリー確定足の時刻（UTC相当、`python.analysis.trade_breakdown`のSession区分と同一境界）がTokyoセッション（hour∈[0,8)∪[22,24)）外であれば候補を棄却する（2026-08-26追加、既存分析でTokyoセッションのみが唯一プラスだったことを踏まえた検証用オプション）。

**SL**: Lower/Upper Bandまたは直近レンジ高安値（`InpMeanReversionBbPeriod`本）のうち保守的な方の外側に、ATR×`InpMeanReversionStopAtrMultiple`のバッファを設ける。

**強制決済**（トレンド戦略へは引き継がず、レンジポジションを決済したうえで新規エントリーのみ停止する。その後はトレンド戦略が通常どおり独立してエントリー判定を行う。2026-08-25仕様変更: Range Filter解除だけを理由とした即時決済は、レンジが一時的に崩れただけでもTP到達前に決済される頻度が高すぎたため廃止し、「警戒状態」への移行に変更した。2026-08-26仕様変更: 当初の「確定足ベースで最大N本の猶予期間」は猶予が短くブレイクを十分に検知できていなかったため、警戒状態中はBid/Askを毎Tick監視し、ブレイクが実時間で一定秒数継続した場合のみ決済する方式へ変更した）:

1. **BB Width急拡大**: BB Widthが過去`InpMeanReversionBbWidthLookback`本平均の`InpMeanReversionBbWidthExpansionRatio`倍以上に急拡大した場合、警戒状態と無関係に常時決済する（変更なし）。
2. **Range Filter解除→警戒状態→Tick監視によるブレイク確認**: Range Filter（エントリーと完全に同一の判定・閾値、`InpMeanReversionChoppinessMin`/`InpMeanReversionAdxMax`。判定条件自体は変更しない）が解除されただけでは決済しない。解除を検知したポジションを「警戒状態」へ移行し、以降は毎TickでBid/Ask（実勢価格）を監視する。BUYは`Bid<RangeLow-ATR×InpMeanReversionBreakAtrMultiplier`、SELLは`Ask>RangeHigh+ATR×InpMeanReversionBreakAtrMultiplier`をブレイク条件とする（RangeLow/RangeHighは直近`InpMeanReversionRangeBreakLookback`本の確定足高安値、エントリー側SLの参照本数とは独立）。ブレイク条件を初めて満たした実時刻からタイマーを開始し、`InpMeanReversionBreakConfirmSeconds`秒（既定30、Tick数ではなく実時間）以上継続した場合のみ強制決済する。継続中に価格がBreakLevelの内側へ戻ればタイマーをリセットし、再度ブレイクすれば新たにタイマーが開始する。警戒状態中にRange Filterが再成立すれば警戒状態・タイマーとも解除して通常状態へ復帰し、決済されなかった場合は既存SL/TP等の管理に委ねる（ticket単位の状態はポジションごとに独立管理し、決済理由を問わずポジション決済時に必ずクリアする）。

エントリー条件（`CMeanReversionEntryRules`）と強制決済条件（`CMeanReversionExitRules`・`CMeanReversionStrategy::IsRangeStillValid`の状態機械）はコード上も分離している。強制決済の発火理由（`TICK_BREAK_EXIT`/`BB_WIDTH_EXPANSION`/`MEAN_REVERSION_MAX_HOLDING_BARS`）は監査イベント`RANGE_EXIT`のreason_codeへ記録され、従来のSL・TPとは区別できる（`trade_candidate_id`で`TRADE_CLOSED`と紐付け可能、`TIME_STOP_EXIT`と同じ形式）。MT5のclose_reason（SL/TP/SO/EXPERT）はEA発注による決済をすべて"EXPERT"に一括りにするため、強制決済回数・TP到達率・SL到達率を区別するにはRANGE_EXITイベント側のreason_codeを参照する必要がある。`python/analysis/trade_breakdown.py`は`RANGE_EXIT`イベントを`range_exit_reason_code`/`range_exit_triggered`列として結合し、`range_exit_summary()`でreason_code別の件数・純損益を集計する（`TIME_STOP_EXIT`と同じ結合方式、2026-08-25追加）。

**時間切れ決済**: `InpMeanReversionMaxHoldingBars`本（entry_timeframe換算）を経過したら無条件で成行決済する（トレンド戦略のTime Stopとはパラメータ・判断ロジックとも独立）。

| 設定 | 初期値 | 意味 |
|---|---:|---|
| `InpStrategyMode` | `STRATEGY_MODE_TREND_ONLY` | 戦略実行モード（詳細は「戦略実行モード」節参照）。`STRATEGY_MODE_MEAN_REVERSION_ONLY`/`STRATEGY_MODE_COMBINED`を選ぶと以下のRangeパラメータ検証が有効になる |
| `InpMeanReversionBbPeriod` | 20 | Bollinger Bandの期間。SL算出の直近レンジ高安値の参照本数としても使う |
| `InpMeanReversionBbDeviation` | 2.0 | Bollinger Bandの標準偏差倍率 |
| `InpMeanReversionChoppinessPeriod` | 14 | Choppiness Index（`CChoppinessIndex`）の算出期間 |
| `InpMeanReversionChoppinessMin` | 60.0 | Range Filter: この値以上のChoppiness Indexでのみレンジ相場とみなす |
| `InpMeanReversionAdxMax` | 25.0 | Range Filter: このADX未満でのみレンジ相場とみなす（`InpAdxPeriod`を共用） |
| `InpMeanReversionStopAtrMultiple` | 1.0 | SLのBand/直近レンジ高安値からのATRバッファ倍率 |
| `InpMeanReversionMaxReentryBars` | 3 | Band外側へのブレイクから、Band内側への復帰を待つ最大本数（Reentry Window）。1の場合は「次の1本で復帰」のみを許可する従来相当の挙動になる |
| `InpMeanReversionTakeProfitMode` | `MEAN_REVERSION_TP_BB_MIDDLE` | TP方式。既定はBB Middle（中心線）到達。`MEAN_REVERSION_TP_OPPOSITE_BAND`で反対側Band到達に切替可能（将来比較用） |
| `InpMeanReversionBbWidthLookback` | 20 | BB Width急拡大判定の平均算出本数 |
| `InpMeanReversionBbWidthExpansionRatio` | 1.5 | 現在のBB Widthが過去平均の何倍以上で強制決済するか |
| `InpMeanReversionRangeBreakLookback` | 20 | 強制決済（レンジブレイク）判定用の直近レンジ高安値（RangeLow/RangeHigh）の参照本数。エントリー側SLの参照本数（`InpMeanReversionBbPeriod`）とは独立（2026-08-25追加） |
| `InpMeanReversionBreakAtrMultiplier` | 0.25 | 警戒状態中のTickブレイク判定で、RangeLow/RangeHighに加えるATRバッファの倍率（2026-08-26追加） |
| `InpMeanReversionBreakConfirmSeconds` | 5 | 警戒状態中、ブレイク条件が実時間で何秒継続したら強制決済するか（Tick数ではなく実時間、2026-08-26追加）。2026-08-30のスイープ（TASKS.md参照）で0秒に近いほど単調に純損益が改善することが判明し、2026-09-13に既定値を30→5へ更新した（他Foldでの再現性は未確認。MR戦略自体は既定`InpStrategyMode=STRATEGY_MODE_TREND_ONLY`のため現状無効） |
| `InpMeanReversionRestrictToTokyoSession` | false | trueの場合、エントリー確定足がTokyoセッション（UTC相当hour∈[0,8)∪[22,24)）外であれば候補を棄却する |
| `InpMeanReversionMaxHoldingBars` | 10 | 時間切れ決済が発動する経過バー数の上限（entry_timeframe換算）。2026-08-26、Fold1〜6 Trainスイープで20本が最悪と判明したため10本へ変更（詳細はTASKS.md参照） |
| `InpMeanReversionMagicNumber` | 26072002 | レンジ戦略ポジション識別用のMagic Number（`InpMagicNumber`とは別値が必須） |

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
| `InpAuditFileEnabled` | true | JSONL監査 |
| `InpAuditLogDirectory` | `EaTradingSystem\\Audit` | `Common\\Files`配下の出力先（2026-09-07変更、旧: `MQL5\\Files`配下） |
| `InpAuditRunId` | 空 | 監査ファイル名を`audit-<run_id>.jsonl`にする実行単位の識別子。空の場合（既定値、通常運用）は従来どおり日付単位の`audit-YYYYMMDD.jsonl`にフォールバックする |
| `InpTelemetryEnabled` | false | AWS監査送信 |
| `InpTelemetryApiUrl` | 空 | `/v1/trade-events`で終わるHTTPS URL |
| `InpTelemetryTimeoutMs` | 1500 | 監査送信timeout |

Telemetry失敗は取引判断や既存ポジション管理へ影響しない。ローカルJSONLを先に保存し、AWS欠損時の正本とする。

**2026-09-07変更: 監査JSONLの保存先を`FILE_COMMON`へ変更した。** 従来はサンドボックス化された`<data folder>\MQL5\Files\<InpAuditLogDirectory>`（Strategy Tester実行時はTester Agent固有のサンドボックス配下）に保存していたが、VM実行でMT5終了後にTester Agentのサンドボックスがcleanupされると、HTM reportは回収できるのに監査JSONLだけ消失する問題があった。`FILE_COMMON`（`Terminal\Common\Files\<InpAuditLogDirectory>`、同一Windowsユーザーの全MT5ターミナルで共有）はTester Agentのサンドボックスの外にあるため影響を受けない。`tools/run-strategy-tester.ps1`はStrategy Tester実行のたびにReport名と同一の値を`InpAuditRunId`へ設定し、`audit-<ReportName>.jsonl`という実行単位で一意なファイル名にする（Common領域が複数ターミナル・複数実行で共有されるため、実行間・ケース間のログ混入を防ぐ目的）。詳細は`docs/backtesting.md`とDECISIONS.md DEC-030を参照。

## AWS CDK context

`environment`、`ml_model_key`、`ml_model_sha256`、`llm_provider`、`llm_model`、`llm_shadow_mode`、`alarm_email`、`enable_dashboard`、`metrics_enabled`、`log_level` をdeploy時に指定できる。秘密値はcontextへ渡さない。`llm_shadow_mode` は既定でtrueで、有効なLLM VETOを記録するが最終判定へ適用しない。LLM timeout・不正出力・provider errorはShadow ModeでもVETOである。productionではモデルobjectとchecksum、固定LLM model、prompt version、SNS購読、予算通知を証跡へ記録する。
