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
| `InpPullbackTriggerAtrBuffer` | 0（無効） | Pullback Entry Trigger（確認足の再加速判定）が、タッチ足高安値を単に上回る/下回るだけでなくATR基準の余裕幅を要求するようにする追加条件。0は無効化（既定挙動、従来のIsPullbackTriggerと完全一致）。2026-08-23追加、詳細はTASKS.md参照 |
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
| `InpEntryUseStagedPipeline` | false | 段階的Entry判定パイプライン（Market Regime→HTF Bias→Setup→Entry Trigger）を有効化する（2026-08-22追加）。falseの間は既存方式と完全に同一の判定・発注挙動を維持する。詳細は本節末尾および`docs/backtesting.md`「段階的Entry判定パイプライン」を参照 |
| `InpEntryRequireMarketRegimeTrend` | true | `InpEntryUseStagedPipeline=true`の場合のみ有効。市場レジームがRange/Unknownの確定足でEntry候補を棄却する（2026-08-22追加） |
| `InpRegimeTrendAdxMin` | 20 | 市場レジーム判定用のADX下限。下回るとRange判定（Entry判定のADXフィルタとは独立） |
| `InpRegimeAtrBaselinePeriod` | 50 | ボラティリティ判定用ATRベースライン（単純平均）の算出本数 |
| `InpRegimeHighVolatilityRatio` | 1.3 | ATR/ベースライン比がこの値以上でHighVolatility判定 |
| `InpRegimeLowVolatilityRatio` | 0.7 | ATR/ベースライン比がこの値以下でLowVolatility判定 |
| `InpRegimeMaSlopeLookback` | 5 | トレンド方向判定用、H1 EMA(Fast)の参照本数（現在値と何本前を比較するか） |

市場レジーム判定（`InpRegime*`）自体は`CMarketRegimeClassifier`（既存、変更なし）が行う。`InpEntryUseStagedPipeline=false`（既定値）では、この判定結果は監査ログ記録のみに使われ、Entry判定・発注・既存ポジション管理には一切影響しない（判定と売買制御の分離）。`InpEntryUseStagedPipeline=true`にした場合のみ、`InpEntryRequireMarketRegimeTrend`に従いRange/Unknown判定をEntry棄却条件として使用する。詳細は`docs/backtesting.md`「条件別分析」および「段階的Entry判定パイプライン」を参照。

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

`InpEntryUseStagedPipeline=false`（既定値）では、Stage 1のRange/Unknown棄却ゲートが働かない点を除き、判定式は既存方式と完全に同一である（`IsPullback`は内部で`IsPullbackSetup && IsPullbackTrigger`として再定義されているが、数式は変更前と等価）。`true`にすると、Stage 1でRange/Unknown判定の確定足を追加で棄却する（`InpEntryRequireMarketRegimeTrend=true`の場合）。

各段階の合否は、`CANDIDATE`イベント（Entry成立時のみ）と、`InpEntryUseStagedPipeline=true`の場合に限り毎確定足で記録される新規イベント`ENTRY_PIPELINE`（`stage_market_regime`・`stage_htf_bias`・`stage_breakout_setup_passed`・`stage_breakout_trigger_passed`・`stage_pullback_setup_passed`・`stage_pullback_trigger_passed`・`final_status`・`reason_code`・`reason`）へ記録される。`InpEntryUseStagedPipeline=false`のままでは`ENTRY_PIPELINE`イベントは記録されず、既存の監査ログ量・スキーマに影響しない。

既存方式（false）と段階的方式（true）の比較は、同一IS期間で`InpEntryUseStagedPipeline`のみを変更した2回のStrategy Tester実行を、`docs/backtesting.md`の既存手順（Net Profit・Profit Factor・Sharpe・取引数等）で比較する。段階的方式のみ、`ENTRY_PIPELINE`ログから各Stageの棄却件数も追加で確認できる。

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
| `InpBreakevenTriggerR` | 1.0 | 含み益が「建値〜当初SL距離（初期リスク）」の何倍に達したら建値へSLを引き上げるか（2026-08-17追加）。`InpEnableTradeMutations=false`では発動しない。0.5/0.75/1.25/1.5/2.0とのスイープ比較で1.0が純損益・PF・Sharpe・期待利得・最大連敗のすべてで最良またはタイの結果を確認済み（詳細はTASKS.md参照）。部分利確（1R/1.5Rトリガー）・ATRトレーリングストップ（1.0Rトリガー・2.0×ATR幅）をいずれも試したが建値ストップ単体を上回らなかったため撤回済み |
| `InpEnableSignalInvalidationExit` | true | シグナル失効による早期Exitの有効化（2026-08-17追加、詳細はTASKS.md参照）。エントリー根拠（D1/H4トレンド一致・H1/H4 ADX）が保有中に消失したら決済する。RSI・エントリーパターンは再チェックしない。`InpEnableTradeMutations=false`では発動しない |
| `InpSignalExitCheckTrend` | true | シグナル失効判定にD1/H4トレンド反転チェックを含めるか（2026-08-17追加） |
| `InpSignalExitCheckH1Adx` | true | シグナル失効判定にH1 ADX閾値チェックを含めるか（2026-08-17追加） |
| `InpSignalExitCheckH4Adx` | false | シグナル失効判定にH4 ADX閾値チェックを含めるか（2026-08-17追加。H1 ADXと相関が高く冗長でTP到達を妨げるため、Trend+H1 ADXのみが最良と判明しfalseへ変更。`results/backtests/20260817-204940-USDJPY-H1/`が現時点の最良状態）。3条件すべてを無効化する組み合わせは`INVALID`扱い。いずれかの条件に該当したら完全決済する（一部利確は試行の結果TP希薄化により逆効果と判明し撤回済み、詳細はTASKS.md参照） |
| `InpEnableTimeStop` | true | 時間切れ決済（Time Stop）の有効化。エントリー後、`InpMaxHoldingBars`本（entry_timeframe換算の確定足数）経過しても決済されていないポジションを成行決済する。`InpEnableTradeMutations=false`では発動しない。2026-08-17、既知の最良状態（Trend+H1 ADXのみ全条件完全決済のシグナル失効Exit）上で既定値（20本・最低MFE0.5R要求）で有効化し検証したところ、実際の発動は209件中2件のみで既存のシグナル失効Exitとほぼ完全に重複し、本IS期間では純損益がわずかに悪化（-44,039→-48,223円）した。この結果を踏まえたうえで、ユーザー判断によりリスク管理上の方針として既定trueを維持することを決定（ポジションが無期限に保有され続けることを防ぐセーフティネットとして、IS単体での純損益への影響とは別に採用）。詳細はTASKS.md参照 |
| `InpMaxHoldingBars` | 20 | Time Stopが発動する経過バー数の上限（entry_timeframe換算）。`InpEnableTimeStop=true`時は1以上が必須 |
| `InpTimeStopRequireMinMfe` | true | trueの場合、`InpMaxHoldingBars`経過時点で保有中のMFE（最大含み益、価格ベースのピーク追跡、`InpBreakevenTriggerR`と同じ「建値〜当初SL距離」をR換算）が`InpTimeStopMinMfeR`未満のときのみTime Stopを発動する。到達済みなら通常のSL/TP/建値ストップに委ねる |
| `InpTimeStopMinMfeR` | 0.5 | Time Stopの最低MFE閾値（R倍数）。`InpTimeStopRequireMinMfe=true`時は0より大きい値が必須 |
| `InpEnableEntryTimingAnalysis` | false | Entry Timing比較分析（分析専用、実注文なし）を有効化する（2026-08-22追加）。プルバックSetupについて即時Entry・1本待ち・2本待ち・Trigger待ちの4方式をShadow Tradeとして並行シミュレートし監査ログへ記録する。falseの間はIndicatorハンドルすら作成せずコスト0で、既存の売買判断・発注には一切影響しない。詳細は`docs/backtesting.md`「Entry Timing比較分析」を参照 |
| `InpEntryTimingMaxWaitBars` | 6 | Trigger待ち(WAIT_TRIGGER)方式がTriggerの成立を探す最大バー数。この本数を超えてもTriggerが成立しない場合はWAIT_TRIGGERのShadow Tradeを生成しない（`InpEnableEntryTimingAnalysis=true`時は1以上が必須） |
| `InpEntryTimingMaxHoldingBars` | 20 | Shadow Trade（IMMEDIATE/WAIT_1_BAR/WAIT_2_BARS/WAIT_TRIGGERいずれも）の最大追跡バー数。SL/TP未到達のままこの本数へ達すると`EXPIRED`としてその時点の価格で打ち切る（`InpEnableEntryTimingAnalysis=true`時は1以上が必須） |

`InpEnableTradeMutations` は最後に有効化する。Risk Manager、Decision API、LLMがALLOWでも、この値がfalseなら新規発注しない。本番ゲート未達の状態でtrueにしてはならない。

## レンジ相場逆張り戦略設定（2026-08-24仕様変更）

トレンドフォロー戦略とは独立した第二の候補生成源。レンジ端（Bollinger Band外側）からの平均回帰を狙う。トレンドフォロー戦略が本確定足で候補を生成しなかった場合のみ評価され（両戦略が同一口座へ同時発注することを避ける排他制御）、既存のRisk Manager・PositionManager・監査ログ基盤をそのまま共有するが、`InpMeanReversionMagicNumber`により別のMagic Numberでポジションを識別する（トレンドフォロー戦略のポジションと混同しない）。`InpEnableMeanReversionStrategy=false`（既定）では初期化も評価も一切行われず、既存挙動を変えない。

**Range Filter**: Choppiness Index（`InpMeanReversionChoppinessMin`以上）かつADX（`InpMeanReversionAdxMax`未満）の両方を満たす場合のみレンジ相場と判定する。

**Entry**: 確定足のCloseがBand外側へブレイクした場合（Reentry待ち開始）、その後`InpMeanReversionMaxReentryBars`本以内に確定足のCloseがBand内側へ復帰した最初の確定足でのみ成立する（タッチのみでは反応しない。期限内に復帰しなければシグナル破棄。同一ブレイクから複数回エントリーしない）。

**SL**: Lower/Upper Bandまたは直近レンジ高安値（`InpMeanReversionBbPeriod`本）のうち保守的な方の外側に、ATR×`InpMeanReversionStopAtrMultiple`のバッファを設ける。

**強制決済**（トレンド戦略へは引き継がず、レンジポジションを決済したうえで新規エントリーのみ停止する。その後はトレンド戦略が通常どおり独立してエントリー判定を行う。2026-08-24仕様変更: エントリー条件のRange Filter（CI/ADX閾値）は新規エントリーの成立条件としてのみ用い、保有中ポジションの決済判断には使わない。CI/ADXの一時的な閾値跨ぎ1本だけを理由に決済すると過剰反応になるため、強制決済はレンジ崩壊を示すより強い条件に限定する）: 以下のいずれかで確定足ベースに決済する。
1. レンジ高値/安値（直近`InpMeanReversionBbPeriod`本の実際のスイング高安値。Bollinger Bandではない）を確定足Closeで明確にブレイク
2. ADXが`InpMeanReversionForcedExitAdxThreshold`を超え、かつ直近確定足間で上昇中（強いトレンドの急発生）
3. BB Widthが過去`InpMeanReversionBbWidthLookback`本平均の`InpMeanReversionBbWidthExpansionRatio`倍以上に急拡大

エントリー条件（`CMeanReversionEntryRules`）と強制決済条件（`CMeanReversionExitRules`）はコード上も別クラスへ分離している。

**時間切れ決済**: `InpMeanReversionMaxHoldingBars`本（entry_timeframe換算）を経過したら無条件で成行決済する（トレンド戦略のTime Stopとはパラメータ・判断ロジックとも独立）。

| 設定 | 初期値 | 意味 |
|---|---:|---|
| `InpEnableMeanReversionStrategy` | false | レンジ相場逆張り戦略の有効化 |
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
| `InpMeanReversionForcedExitAdxThreshold` | 30.0 | 強制決済: このADXを超え、かつ上昇中の場合に決済する（Range Filterの`InpMeanReversionAdxMax`より高い、強いトレンド発生を示す閾値） |
| `InpMeanReversionMaxHoldingBars` | 20 | 時間切れ決済が発動する経過バー数の上限（entry_timeframe換算） |
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
| `InpAuditFileEnabled` | true | 日別JSONL監査 |
| `InpAuditLogDirectory` | `EaTradingSystem\\Audit` | `MQL5\\Files`配下の出力先 |
| `InpTelemetryEnabled` | false | AWS監査送信 |
| `InpTelemetryApiUrl` | 空 | `/v1/trade-events`で終わるHTTPS URL |
| `InpTelemetryTimeoutMs` | 1500 | 監査送信timeout |

Telemetry失敗は取引判断や既存ポジション管理へ影響しない。ローカルJSONLを先に保存し、AWS欠損時の正本とする。

## AWS CDK context

`environment`、`ml_model_key`、`ml_model_sha256`、`llm_provider`、`llm_model`、`llm_shadow_mode`、`alarm_email`、`enable_dashboard`、`metrics_enabled`、`log_level` をdeploy時に指定できる。秘密値はcontextへ渡さない。`llm_shadow_mode` は既定でtrueで、有効なLLM VETOを記録するが最終判定へ適用しない。LLM timeout・不正出力・provider errorはShadow ModeでもVETOである。productionではモデルobjectとchecksum、固定LLM model、prompt version、SNS購読、予算通知を証跡へ記録する。
