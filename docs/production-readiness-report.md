# 本番準備状況レポート

評価日: 2026-07-21（2026-09-17、Final Holdout結果を反映し6/7/13/14節を更新。2026-09-22、tick欠落修正後の再検証結果を7.5節に追記）  
対象: CoreEA 1.13 / Phase 13  
判定: **NO-GO**

## 1. エグゼクティブサマリー

既存の責務分離（Strategy、External Decision、Risk、Trading、Logging）とフェイルセーフ方針は維持されている。Risk Managerは外部ALLOW後に最新市場・口座状態で再計算され、1つでもGuard、Margin、OrderCheckが失敗すれば注文しない。既存ポジション監視は候補生成より前に実行される。

Phase 13ではMQL5の実コンパイル、Script実行、Python/Lambda/CDK回帰試験を実施し、安全境界、Strategy単位停止、Tester用Mock、LLM Shadow Mode、ML評価指標、CloudWatch Alarm、再現用バックテスト設定を追加した。自動試験は通過し、Strategy Testerも2025年USDJPY/H1で完走したが、総損益-95,024円・Profit Factor 0.59・最大Drawdown 10%到達という損失結果であった（2026-08-09時点、受入基準未凍結のため合否未判定）。

**2026-09-17追記**: その後rule-based StrategyでのIn-Sample凍結・Walk Forward・Final Holdoutを完了した。Final Holdout（2025-01〜2026-08、4銘柄）の結果、Walk Forward（+290.4円/トレード）から期待値の符号が反転する成績悪化（-160.2円/トレード）を確認した。原因分析の結果、これは特定パラメータの過学習ではなく、戦略の実質勝率が2021年以降緩やかに悪化し続けている構造的なトレンドの延長であることが判明した（詳細は7/7.5/13/14節）。この所見に加え、AWS dev実通信、LLM実通信、Demo/VPSは依然未検証である。このため実資金運用は **NO-GO** とする。

**2026-09-22追記**: 既存Custom Symbolのtick欠落（0.641%、`DECISIONS.md` DEC-037）を修正・再投入した後、IS・Walk Forward・Final Holdoutを再実行し影響を確認した。取引数・純利益は無視できない幅で変化した（Final Holdoutは純利益-28,991円→-18,349円、損失37%縮小）が、年次expectancyのトレンド形状とFinal Holdoutでの符号反転という中核的な結論、NO-GO判定は変わらない（詳細は7.5節末尾）。

### 現状リポジトリ監査

- アーキテクチャ: CoreEA/Controllerが確定足Strategyを起点にDecision API、Risk Manager、Order Managerへ進み、Position Managerを候補処理より先に実行する。AWSはHTTP API、Decision/Telemetry Lambda、DynamoDB、S3、CloudWatch/SNSをCDKでdev・staging・production分離する。
- 実装済み: MQL5 Strategy/Risk/Trading/API/監査、HMAC認証・Replay対策、ML線形baselineと校正、LLM構造化VETO、DynamoDB監査、分析指標、IaC、開発release gate。
- 暫定・未実装: 実市場model artifact、定期Heartbeat、MT5レポートimporter、Shadow効果の統計評価、AWS実環境の障害注入、MQL5 VPS運用証跡。
- テスト状況: 純粋ルールと外部境界の自動テストは整備されている。一方、Broker状態を使う日付・position・margin/order統合、real tickバックテスト、実クラウド経路は未検証である。
- 本番リスク: 実データ成績と約定再現性が不明、外部依存障害時の実測がない、無候補時の死活監視がない、運用通知と緊急手順が演習されていない。

## 2. テスト結果

| 区分 | 結果 | 証跡・注記 |
|---|---|---|
| MetaEditor compile | PASS | EA＋7 Script、全て0 errors / 0 warnings |
| MQL5 Script runtime | PASS | 7/7で `TEST_SUITE_PASS` |
| Python/Lambda/CDK unit | PASS | 78 passed |
| CDK synth | PASS | dev stack synth完了 |
| Strategy Tester | LOCALLY TESTED（損益結果は要判断） | 2026-08-16、OANDA証券MT5・`USDJPY_HIST`・In-Sample期間（2017-09〜2020-12、DEC-025）で完走。総損益-65,696円、PF 0.66、最大DD9%（詳細は`results/backtests/20260816-193344-USDJPY-H1/run-metadata.json`）。XMTrading時代の2025年単年実行（総損益-95,024円、PF 0.59）は参考記録として保持 |
| AWS dev integration | NOT VERIFIED | AWS認証・endpointを使用していない |
| LLM provider実通信 | NOT VERIFIED | API key/modelを使用していない |
| Demo/MQL5 VPS | NOT VERIFIED | 未接続 |

`TestDecisionApiRules`は全AssertionとPASSマーカーを出したがTerminal process exit codeは1だった。他の6 Scriptは0。テストランナーはAssertion/PASSマーカーを正としているが、exit code差異は未解消事項として追跡する。

**2026-08-16、本番運用ブローカーをOANDA証券MT5へ切り替えたことに伴い（`DECISIONS.md` DEC-023）、`tools/compile-mql5.ps1`・`tools/run-mql5-tests.ps1`等のデフォルト対象をOANDA端末へ変更し、OANDA環境で上記のCompileとScript Testを再実行した。** 結果は同一（EA＋7 Script全て0 errors/0 warnings、7/7でAssertion/PASSマーカー確認、`TestDecisionApiRules`のみ同じexit code 1）。OANDA-Japan MT5 Demoはhedging mode口座であることをTerminal Journalで確認しており、XMTrading側の口座方式（未確認のまま）とは異なる可能性があるが、少なくとも純粋ルールレベルのテストはOANDA環境でも同一結果だった。

## 3. MQL5ビルド結果

`tools/link-mt5.ps1`でInclude、Experts、Testsの3 Junctionを確認した。`tools/compile-mql5.ps1`をMetaEditor build 6034で実行し、CoreEA、TestTrendFollowingRules、TestPositionSizer、TestRiskGuards、TestTradingRules、TestDecisionApiRules、TestAuditRules、TestProductionSafetyRulesが全て0 errors / 0 warningsだった。build logは `build/metaeditor/` に保存される。

## 4. 単体テスト結果

PositionSizerは残高/Equity相当0、risk 0/負値、SL損失0、極小/極大損失、min未満、max超過、step切捨て、TickSize/TickValue異常を純粋ルールで確認した。Spreadは通常、直前、一致、超過、crossed quote、Bid/Ask/point異常を確認した。Daily LossとDDは0、直前、一致、超過、無効baselineを確認した。Exposureは0、上限未満、一致、超過、同一Symbol拒否を確認した。

DailyLossの日付切替、Broker server time、永続lock、Balance更新、実ポジション列挙、BUY/SELL混在はコードレビュー済みだが、実口座状態を使う統合実行は `NOT VERIFIED` である。Risk統合の「外部ALLOWでもRisk拒否なら発注しない」は既存TestTradingRulesとController順序で確認した。

## 5. Strategy Tester結果

2026-07-21 23:13、USDJPY/H1、2025-01-01〜2025-12-31、Every tick based on real ticks（100%リアルティック）、Mock ALLOW（`InpTesterDecisionMode=1`, `InpTesterFixedMlProbability=0.65`）、`InpEnableTradeMutations=true`（Strategy Tester内のみ、EA既定値は変更せず）で完走した。Broker表示は`XMTrading-MT5`/`Tradexfin Limited`だが、Demo口座かReal口座かは記録がなく **NOT VERIFIED**。

結果: 総損益 -95,024円（総利益135,076円、総損失-230,100円）、Profit Factor 0.59、Sharpe -4.09、最大Drawdown 95,024円（残高比10%、上限到達）、取引数66（ロング6/勝率0%、ショート60/勝率26.67%）、最大連敗9（-43,130円）。手数料合計0円、スワップ合計-10,846円、価格損益合計-84,178円。全132注文が`filled`で、拒否・requoteに該当する注文は現れなかった。証跡は`results/backtests/20260721-231302-USDJPY-H1/`（`.htm`/`.png`/`tester.ini`/`run-metadata.json`）。この実行はXMTrading-MT5時代の参考記録であり、正式なIn-Sample/OOS/Walk Forward系列としては扱わない（本節末尾参照）。

**2026-08-16、In-Sample期間の正式実行完了。** OANDA証券MT5・Custom Symbol `USDJPY_HIST`・DEC-024/DEC-025で確定した期間（2017-09-01〜2020-12-31）でStrategy Testerを実行した。当初期間（2016-09開始）ではCustom Symbolのインジケーターウォームアップバッファ不足により取引数0件の異常が発生し、原因調査（`results/backtests/20260816-180519-USDJPY-H1/ANOMALY-zero-trades.md`）を経て開始日を2017-09-01へ補正した（DEC-025）。

結果: ヒストリー品質100%リアルティック、取引数55・約定数110、総損益 **-65,696円**（総利益128,620円、総損失-194,316円）、Profit Factor **0.66**、Sharpe **-3.20**、最大Drawdown 96,450円（残高比9%）、期待利得-1,194.47円、ロング40件/勝率27.50%、ショート15件/勝率20.00%、最大連敗17件（-80,818円）。証跡は`results/backtests/20260816-193344-USDJPY-H1/`（`.htm`/`.png`/`tester.ini`/`run-metadata.json`）。受入基準は未凍結のため合否は未判定。

一方、以下は本実行でも **NOT VERIFIED** のまま。
- Terminal/EAログ（Journal/Expertsタブ）が保存されておらず、Spread/Margin/OrderCheckの拒否動作は未検証（本実行では拒否が1件も発生していない）
- 事前固定された受入基準がなく、上記結果の合否は未判定
- Demo/Real口座の区別
- Git Commit SHA（実行時刻がリポジトリ最初のコミットより前のため対応するSHAが存在しない）

2026-08-10、上記の期間制約の原因を確定した。Broker（XMTrading-MT5/Tradexfin Limited）はUSDJPYのreal tickデータを2022年1月分以降しか保持しておらず、2020-2021を指定すると「ヒストリー品質0%リアルティック」（OHLCからの合成tick）に自動的に切り替わることを確認した（`results/backtests/20260810-144215-USDJPY-H1/`、この結果はNOT VERIFIED扱いで損益評価に使用しない）。この制約を受け、**ブローカーをOANDA証券MT5（東京サーバー）へ切り替え、2015年以降のreal tickデータで検証をやり直す方針を決定した。** OANDA証券デモ口座開設完了後にStrategy Testerを再実行し、以後はOANDA側データを正式なIn-Sample/Out-of-Sample/Walk Forward系列とする。上記のXMTrading-MT5実行結果（総損益-95,024円等）は参考記録として保持するが、production release gateの証跡としては使用しない。

## 6. Out-of-Sample結果

production候補ML Modelを用いた評価は未実施のため **NOT VERIFIED**（3.3節参照）。期間は2026-08-16に確定した（`DECISIONS.md` DEC-024、DEC-025で補正）: 開発・In-Sample=2017-09〜2020-12、OOS/Walk Forward評価=2021-01〜2024-12、Final Holdout=2025-01〜2026-08（EA・Model・閾値確定後に一度だけ評価）。OOSを閾値調整へ再利用してはならない。

一方、rule-based Strategy（ML/LLM未適用、Mock ALLOW）でのOOS・Walk Forward・Final Holdout自体はLocally Testedである。詳細は7節・7.5節を参照。

## 7. Walk Forward結果

TimeSeriesSplitとgapの実装・合成データ試験はPASSした。ML学習を伴うWalk Forward評価は **NOT VERIFIED**（3.3節参照）。

rule-based Strategy（凍結済みIS最良パラメータセット）でのWalk Forward（年次Fold、2021-2024、`TASKS.md` 2.1.1/2.1.3節）はLocally Testedである。単一銘柄（USDJPY）・コア戦略のみでの年次結果は、PFが2021→2024年にかけて1.22→1.21→1.15→**0.68**と単調悪化し、TP到達率（実質勝率）も28.6%→23.3%→23.8%→**16.0%**と単調減少する「重大な懸念」（`TASKS.md` 2.1.1節）が記録されている。単年の偶然ではなく複数年にわたる緩やかな劣化トレンドであり、2024年半ばのUSDJPY急落・乱高下がトレンドフォロー前提（強いトレンド継続）と整合しなかった可能性が指摘されている。4銘柄・現行設定一式でのWalk Forward合計は525トレード・純利益+152,469円・PF1.150・期待値+290.4円/トレード（`TASKS.md` 2.1節）。

**2026-09-17追記（4銘柄合計での再測定）**: 現行の確定パラメータ一式で2020-2024年次Fold・4銘柄を再測定した（`TASKS.md` 2.1.4節）。年次期待値は2020年+400.6円/トレード→2021年+551.2円→**2022年+581.9円（ピーク）**→2023年+103.7円→**2024年-151.9円（赤字転落）**と、単一銘柄の記録以上に明確な単調悪化を示した。4銘柄いずれも2024年前後に悪化しており銘柄固有の問題ではない。

## 7.5 Final Holdout結果（2026-09-16/17実施）

Final Holdout（2025-01〜2026-08、EA・パラメータ確定後に一度だけ評価、4銘柄: USDJPY/EURJPY/EURUSD/GBPJPY_HIST）を実施した。結果は4銘柄合計181トレード・純利益**-28,991円**・期待値**-160.2円/トレード**（Walk Forwardの+290.4円/トレードから符号が反転）。詳細な結果・原因分析は`TASKS.md` 2.1.4節を参照。

原因分析の結果、Fold1-5で採用したEarlyAdverseExit等の特定パラメータの過学習ではなく、**戦略コア（Entry判定・TP/SL構造）の実質勝率が2022年をピークに緩やかに悪化し続けているトレンドの延長**であることが判明した（7節のWalk Forward年次内訳と整合、2024年の赤字転落水準がFinal Holdoutでもほぼそのまま継続）。

**根本原因の絞り込み（2026-09-17追加分析）**: 市場レジーム分布・ADX強度は2020-2025年で安定しており、Entry判定の"入力側"は劣化していない。BUY/SELLの優位方向は年ごとに不規則に反転しており、方向性判定自体に系統的な優位性が乏しい可能性がある。**最も具体的な発見は、含み益到達トレードにおいて「Peak確定後の逆行幅」（`post_peak_mae_r`、-0.845〜-0.898Rでほぼ一定）は変わらない一方、「含み益ピークの大きさ」（`mfe_r`平均）が0.983→0.813へ緩やかに単調減少していること**である。これは「トレンドが崩れた後にどこまで戻されるか」ではなく「一度トレンドに乗った後にどこまで伸びるか」自体が縮小していることを示す。

**訂正（2026-09-17、In-Sample期間まで遡った追加測定）**: 上記の「2020年以降の単調減少」が恒久的な構造変化か循環的な現象かを切り分けるため、In-Sample期間（2017-2019）まで遡ってmfe_rを測定したところ、**2018年に既にFinal Holdoutを下回る深い落ち込み（mfe_r 0.725、期待値-910.2円/トレード）が発生し、翌2019年から2022年にかけて回復していたことが判明した**。つまりmfe_rの低下は2022年以降に初めて起きた現象ではない。`post_peak_mae_r`（逆行幅）は全期間（2017-2026）を通じて-0.845〜-0.923の狭いレンジで安定しており、これは循環・構造変化いずれの局面でも変わらない戦略の恒常的な特性である。**「2022年ピークからの恒久的な劣化」と断定するのは時期尚早であり、正確には「2018年型の一時的な落ち込みか、今回（2023年〜Final Holdoutまで4年目）は本当に恒久的な構造変化かは、現時点のデータでは判別できない」というのが誠実な結論である**（2018年の落ち込みは1年で回復したのに対し、今回は既に4年継続しており回復の兆しが見られない点は懸念材料）。市場のボラティリティ構造の変化（大きく伸びる相場→小さく動いてレンジへ回帰しやすい相場）という仮説は依然有力だが、確定的な証拠ではない。

**他資産クラスでの確認（2026-09-19、JP225/US30/XAUUSD、初見資産・確認目的のみ、`TASKS.md` 2.1.4節 追加分析3の結果）**: FX4銘柄が円・ユーロクロスで相関が高い可能性があるため、Custom Symbol仕様を修正（DEC-033）した上で3資産のmfe_rを測定した。2021→2024のmfe_r低下は3資産でも見られた（0.868→0.734）が、**2025-2026は0.818へ反発し期待値も黒字（+418円/トレード）**で、FX4銘柄（0.813、-160円）とは異なった。ただし、トレード数が少ない（期間別29〜125件）、資産間のばらつきが大きい、2025-2026はスプレッド拒否がXAUUSD 42.9%・JP225 19.6%で結果を歪める可能性がある、といった限界があり、**FX固有とも市場全体の変化とも断定できない**。恒久的か循環的かは引き続き**未確定**であり、NO-GO判定は変わらない。

**6資産への拡張（2026-09-19、米国株指数US100/US500/US2000を追加、DEC-035、`TASKS.md` 2.1.4節 追加分析3の結果（続き））**: 上記の「2025-2026の反発」は、米国株指数3資産を加えた6資産では再現しなかった。米国株指数3資産は時間的なトレンドを示さず（mfe_r 0.663→0.711→0.755→0.660→0.668）、**6資産合算のmfe_rは0.729→0.770→0.764→0.696→0.731とほぼ一定**で、FX4銘柄の低下（0.945→0.813）と異なる。ただし、米国株指数は調査初年から既に期待値が負でTP到達率が損益分岐を大きく下回り（この戦略は元からエッジがない）、FX4銘柄の「エッジが失われる変化」を検出できない（床効果）。したがって、「市場全体の構造変化」を支持する証拠は得られなかったが、**FX固有とも断定できない**（エッジのない資産による希釈でも説明できる）。あわせて、直前の3資産の集計で`SIZE_BELOW_MIN`拒否（高ボラティリティ局面の候補が選別的に除外される。US500 14.5%、XAUUSD 9.5%、2025-2026年は6資産合算で10.2%）を見落としていたことを訂正した。恒久的か循環的かは引き続き**未確定**で、NO-GO判定は変わらない。

いずれにせよ、単純なパラメータ再調整では解決しない可能性が高く、Final Holdoutは一度きりの評価のため既に消費済みであり、代替期間は確保されていない（`DECISIONS.md` DEC-024）。

実施過程で監査ログ（`ACCOUNT_SNAPSHOT`）の記録頻度に関する不具合（Strategy Tester内での`TimeGMT()`の巻き戻りに対する非頑健性）を発見・修正した（コミット`aa6d2cb`）。売買判断・発注・実トレード結果には影響しない監査ログ専用の修正であることを確認済み。

**2026-09-22追記: tick欠落修正後の再検証（`DECISIONS.md` DEC-037）。** 既存Custom Symbol（`*_HIST`）に投入されていたtickの0.641%欠落を元zipからの再投入で補修した（DEC-037、`docs/tick-data-pipeline.md`）ことを受け、EA・パラメータを一切変更せず（`Config.mqh`・`CoreEA.mq5`は2026-09-17以降無変更）、IS期間の一部（2017-09〜2019-12）・Walk Forward（2020-2024）・Final Holdoutを再実行し、tick修正による影響を確認した。

| 検証 | 取引数（旧→新） | 純利益（旧→新） | 差分 |
|---|---|---|---|
| IS期間（2017-09〜2019-12、4銘柄・12ケース） | 216→216 | -46,582円→-46,324円 | +258円（+0.6%） |
| Walk Forward（2020-2024、4銘柄・20ケース） | 520→521 | +157,169円→+169,416円 | +12,247円（+7.8%） |
| Final Holdout（2025-01〜2026-08、4銘柄・4ケース） | 181→182 | -28,991円→-18,349円 | +10,642円（損失37%縮小） |

**Final Holdout再実行結果（4銘柄、tick修正後）**:

| 銘柄 | 純利益 | PF | Sharpe | 勝率 | 取引数 | 最大DD |
|---|---:|---:|---:|---:|---:|---:|
| USDJPY | -47,401円 | 0.50 | -1.48 | 17.9% | 39 | 5.3% |
| EURJPY | +7,175円 | 1.08 | 0.17 | 32.6% | 46 | 3.5% |
| EURUSD | +32,721円 | 1.38 | 0.68 | 30.2% | 43 | 3.9% |
| GBPJPY | -10,844円 | 0.91 | -0.23 | 27.8% | 54 | 3.3% |
| **4銘柄合計** | **-18,349円** | — | — | — | **182** | — |

**所見**: IS期間はほぼ無変化（差分0.6%）だが、Walk Forward・Final Holdoutでは取引数自体が一部変わり（それぞれ+1件）、純利益も無視できない幅で変化した（Walk Forward+7.8%、Final Holdout損失37%縮小）。ケース単位ではさらに大きな振れが見られた（例: Walk Forward GBPJPY-2021が-7,714円、USDJPY-2023が-9,736円、Final HoldoutはGBPJPYが-21,902円→-10,844円と変化の大半を占めた）。EAのEntry/Exit確認ロジックが連続tick数（`InpTrendReversalConfirmationTicks`等）を用いるため、復元されたtickが確認タイミング・約定価格を変え得ることが要因と考えられる（未検証の仮説）。監査ログの`SYSTEM_ERROR`件数（Market closed時の緊急決済失敗、既知の挙動）も旧78件→新81件と近い水準で、新規の異常は確認していない。

**中核的な結論は変わらない**: 年次expectancyの上昇→2022年ピーク→下降というトレンド形状（新: 2020 +377.8円→2021 +523.0円→2022 +682.2円→2023 +93.5円→2024 -69.6円→Final Holdout -100.8円/トレード）、「Final HoldoutがWalk Forwardから明確に悪化し符号が反転する」という所見（新: WF+325.2円/トレード→FH-100.8円/トレード）、およびNO-GO判定は、tick修正後も維持される。本節上部の数値（旧tickデータによる測定値）は当時の記録として保持するが、最新の状態は本追記を正とする。詳細は`TASKS.md` 2.1.4節、`docs/tick-data-pipeline.md`を参照。

**FXメジャーペアへの拡張（2026-09-22〜23、AUDUSD/USDCAD/NZDUSD、初見資産・確認目的のみ、`TASKS.md` 2.1.4節 追加分析3の結果（続き）、`DECISIONS.md` DEC-036〜040）**: FX4銘柄・上記の非FX6資産（JP225/US30/XAUUSD/US100/US500/US2000）に続き、「FX同士でも円・ユーロを含まない通貨ペア」を新規実装のDukascopy tick取得パイプラインで確認した。3ペア合算のmfe_rは2021年0.795→2022年0.749→2023年0.789→2024年0.849→2025-2026年0.750と上下に変動し、**FX4銘柄の一貫した単調低下（0.945→0.813）は再現しない**。ただし3ペアは2021年時点で既にmfe_r 0.795・期待値の大半が赤字という低い水準から始まっており、非FX6資産と同様の「床効果」（そもそもエッジが薄く、エッジが失われていく変化自体を検出できない）の可能性がある。このため「円・ユーロクロス固有」を積極的に支持する証拠にも、「市場全体の構造変化」を否定する証拠にもならない。トレード数が少ない（全期間合算413件）等の限界も非FX資産と同様。恒久的か循環的かは引き続き**未確定**であり、NO-GO判定は変わらない。

**FXメジャーペアをIS期間相当まで拡張＋GBPUSD新規追加（2026-09-23〜24、`TASKS.md` 2.1.4節 追加分析3の結果（続き））**: 上記3ペア検証は2021-2026のみだったため、確定パラメータのまま検証範囲をIS期間相当（2016-09〜、既存FX4銘柄と同じDEC-023基準）まで拡張し、円・ユーロを含まない4銘柄目としてGBPUSDを新規追加した。4銘柄合算のmfe_rは2017年0.859→2018年0.777→2019年1.012→2020年0.837→2021年0.811→2022年0.720（底）→2023年0.814→2024年0.876→2025-2026年0.785と推移した。**2018年の落ち込み（0.777）はFX4銘柄の2018年（0.725）とほぼ同時期・同方向**であり、「2018年型の落ち込みは循環的・市場全体の現象」という仮説を支持する新たな材料が得られた。**一方、2020年以降の経路はFX4銘柄の一貫した単調減少（0.983→0.945→0.931ピーク→0.889→0.813）とは明確に異なり**、4銘柄合算は2022年を底（0.720）として2023-2024年に回復しており、FX4銘柄がまだピーク圏にあった2022年時点で既に底を打っているという逆方向の動きが見られた。この結果は「2018年型は市場全体で循環的に起きるが、2022年以降のFX4銘柄の劣化はそれとは別に円・ユーロクロス固有の要因が重なっている」という、前回より解像度の高い仮説を示唆する。ただし年間トレード数が十数〜百件程度と少なく統計的検定は行っておらず、決定的な証拠ではない。恒久的か循環的かは引き続き**未確定**であり、NO-GO判定は変わらない。

**JPY建て別ペア（AUDJPY/CADJPY）による要因の切り分け（2026-09-24〜25、`TASKS.md` 2.1.4節 追加分析3の結果（続き））**: 上記の「円・ユーロクロス固有」仮説について、劣化が「JPY建てであること」自体に起因するのか、それとも既存FX4銘柄に固有なのかを切り分けるため、既存FX4銘柄（USDJPY/EURJPY/GBPJPY）とは別のJPY建てペア（AUDJPY・CADJPY）を新規に検証した。結果、AUDJPY/CADJPYはFX4銘柄の「2022年ピーク→単調減少」パターンではなく、円・ユーロ非依存4ペアの「上下動」パターンに近い動きを示した（FX4銘柄がピーク圏（0.931）にあった2022年、AUDJPY/CADJPYは既に低下局面（0.752）に入り、2023年に底（0.714）を打って2024年に回復）。**もしJPY建てそのものが2022年以降の劣化の主要因なら、AUDJPY/CADJPYもFX4銘柄と同様の単調減少を示すはずだが、実際には示していない。** これにより、2022年以降の劣化は「JPY建て全般の問題」ではなく、「既存FX4銘柄（USDJPY/EURJPY/EURUSD/GBPJPY）に、より狭く限定される現象である可能性」が強まった。ただしAUDJPY・CADJPYは商品国通貨で既存4銘柄とは経済的性質が異なり、年間取引数も10〜60件程度と少なく、決定的な証拠ではない。恒久的か循環的かは引き続き**未確定**であり、NO-GO判定は変わらない。

**ベンチマーク受入基準の判定（2026-09-26実施、`DECISIONS.md` DEC-041・`TASKS.md` 3.2節）**: MSCI ACWI指数自体が無料公開されていないため、これを追跡するeMAXIS Slim全世界株式（オール・カントリー）の基準価額（分配金実績ゼロのため配当込み相当、信託報酬控除後の値）を代替指標として使用し、Walk Forward（2020-2024）・Final Holdout（2025-2026）の既存結果でベンチマーク受入基準（税引き後CAGRとSharpe比の両方で上回ること）を判定した。**両期間とも不合格。** Walk Forwardは税引き後CAGR 2.51%（ベンチマーク15.81%）・Sharpe比0.641（ベンチマーク1.147）、Final Holdoutは税引き後CAGR -1.11%（ベンチマーク18.28%）・Sharpe比-0.170（ベンチマーク1.407）。この期間は世界株式市場が非常に好調だったため差が大きく開いたが、**「戦略の期待値低下が循環的か恒久的か」という論点とは独立に、この検証期間における機会コストの観点でEAは明確に劣後している。** 厳密にはMSCI ACWI指数そのものではなく追跡ファンドの基準価額（トラッキング誤差を含む）である点に注意。詳細は`build/benchmark-check/`（Git管理外）を参照。

## 8. ML検証

特徴量生成、時系列順序、train/calibration/OOS間gap、train期間だけのScaler fit、校正期間分離をレビューした。合成OOS値を変更してもtraining scalerが変化しないテストがある。ROC-AUC、Brier Score、Log Loss、Precision、Recall、F1、return MAEと、0.50/0.55/0.60/0.65/0.70のTrade Count、return合計、Profit Factor、DD、Expectancy比較を出力する。

Probability calibrationは独立calibration期間のPlatt Scalingである。実市場でのcalibration curve、期間別安定性、コスト込み収益性は **NOT VERIFIED**。モデル複雑化は行っていない。

## 9. LLM Shadow評価

AWS側に `LLM_SHADOW_MODE` を追加し、既定trueとした。有効なVETOは `llm.status=VETO` と監査情報を保存しつつ最終ALLOWへ非適用とする。Timeout、不正JSON、UNKNOWN、BUY/SELL、欠落、confidence範囲外などのエラーはShadow中でもVETOを維持する。

PythonにA（LLM未適用）とB（記録済みVETO除外）を同一定義で比較する関数を追加した。Shadow実績ログがないため効果は **NOT VERIFIED**。有効性が実務的・統計的に確認できるまでproductionでVETO適用を推奨しない。

## 10. AWS統合結果

API Gateway→Lambda→ML→LLM→DynamoDBの単体・メモリrepository試験はPASSした。API認証、timestamp、nonce、idempotency、期限、ML/LLM失敗、Telemetry validationはテスト対象である。AWS devへdeployしていないため、実サービス横断フローは **NOT VERIFIED**。

## 11. 異常系テスト結果

単体テストでは4xx相当validation/auth、重複request、ML error、LLM error/timeout/invalid、repository conditional conflict、不正入力を安全側へ処理する。MQL5はHTTP非200、WebRequest失敗、空/過大response、不正JSON、request_id mismatch、期限切れをVETOにする。API待ち時間は既定4500msで、失敗後も次Tickで既存ポジション監視を先に実行する。

Lambda実timeout、API Gateway実5xx、DynamoDB実障害、429、ネットワーク遮断のdev障害注入は **NOT VERIFIED**。

## 12. セキュリティレビュー

作業ツリーをAWS Access Key、Secret Key、OpenAI形式key、Slack token、private key、Broker passwordの代表patternで走査し一致なし。履歴情報を持つ通常のGit repositoryではないため、Git履歴全体のsecret scanは **NOT VERIFIED**。`.gitignore`へ`.set`、decision secret、API key text、生成バックテストdirectoryを追加した。

EAは長期AWS鍵を持たず、失効可能なkey IDとHMAC共有鍵ファイルを使う。server側secretはSSM SecureStringを使用する。HTTPS、timestamp、nonce、request_id/idempotency、response TTL検証がある。実際の鍵ローテーションと侵害対応訓練は未実施。

## 13. 残存リスク

1. Strategy TesterはIn-Sample期間（2017-09〜2020-12、OANDA証券MT5・`USDJPY_HIST`、DEC-024/DEC-025）について完走したが総損益-65,696円・PF 0.66の損失結果であり、受入基準未凍結のため合否未判定。**この数値は2026-08-16時点（EarlyAdverseExit・StagedPipeline等の現行パラメータ確定前、かつ2026-09-22のtick欠落修正前）のもので、現行設定・修正後tickでの単一銘柄・全IS期間（2017-09〜2020-12）での再実行はしていない**（IS期間の一部・2017-09〜2019-12・4銘柄については7.5節末尾のとおり再実行済みで、純利益差は+0.6%と小さい）。
2. **Final Holdout（2025-01〜2026-08、2026-09-17実施）で、Walk Forward結果から成績が明確に崩れることを確認した**（期待値+290.4円/トレード→-160.2円/トレード、符号反転）。原因分析の結果、特定パラメータの過学習ではなく、戦略コアの実質勝率（トレンドの持続力・伸びしろ）が2023年以降緩やかに悪化し続けていることが判明した（詳細は7/7.5節、`TASKS.md` 2.1.4節）。**ただしIn-Sample期間まで遡ると2018年にも同様の落ち込み（Final Holdout以上に深い）が発生し1年で回復した前例があり、今回が恒久的な構造変化か2018年型の循環的な落ち込みが長引いているだけかは、現時点のデータでは判別できない**（2018年は1年で回復したのに対し今回は既に4年継続しており回復の兆しがない点は懸念材料）。いずれにせよ単純なパラメータ再調整では解決しない可能性が高い。Final Holdoutは一度きりの評価のため既に消費済みで、代替期間は確保されていない。**2026-09-22、tick欠落修正後に再実行し、純利益-28,991円→-18,349円（損失37%縮小）へ変化したが、符号反転・トレンド形状・NO-GO判定は維持されることを確認した（7.5節末尾参照）。**
3. Demoは未完了で、Risk実データ挙動が不明。
4. AWS dev実通信と障害注入、Alarm通知到達が未検証。
5. 独立した定期EA Heartbeatが未実装で、無候補時間帯の死活判定が弱い。
6. Kill Switchはコード・純粋ルールのみで、保有position中のSL/TP/安全決済継続を端末で実証していない。
7. LLM Shadowの効果ログがなく、LLMを本番判断へ適用する根拠がない。
8. `TestDecisionApiRules`のTerminal exit code 1を調査する必要がある。
9. production用model checksum、endpoint、通知、Budget、rollback drill、VPS secret配布が未確定。

## 14. 本番移行判定

**NO-GO**。Final Holdout（2025-01〜2026-08）の結果、Walk Forwardから成績が明確に崩れることが確認された（13節2.参照）。この悪化が恒久的な戦略優位性の喪失か、2018年に前例のある循環的な落ち込みの延長かは現時点では未確定だが、いずれの場合でも実弾を投入する前に見極めが必要な水準である。これは実装・運用面の未検証事項（AWS/Demo/VPS等）とは別種の、より根本的な課題である。現時点で許可できるのは、ローカル開発とAWS dev/stagingでの非取引検証、および `InpEnableTradeMutations=false` のDemo観測準備までである。Final Holdoutでの成績悪化が恒久的なものか循環的なものかが判別できない限り、小額実口座・productionへの昇格は推奨しない。単純な設定の再調整によるFinal Holdout再実施は、新しい評価期間の確保が必要な上、問題の根本原因（恒久的か循環的かの見極め）に対処しない限り同じ結果を繰り返すリスクが高い。
