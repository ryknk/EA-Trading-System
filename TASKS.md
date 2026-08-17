# 1. 目的

このファイルは、今後実施する開発・検証・運用準備タスクを管理する。

現在の本番移行判定は **NO-GO** である。

完了状態は、次の記号で管理する。

```text
[ ] 未着手
[-] 作業中
[x] 完了
[!] Blocked
```

タスクを完了扱いにする場合は、可能な限りテスト結果、ログ、レポート、スクリーンショット、Git Commit SHAなどの証跡を残す。

---

# 2. 最優先タスク

## 2.1 Strategy Tester

**2026-08-10決定: ブローカーをXMTrading-MT5からOANDA証券MT5（東京サーバー）へ切り替える。** 理由は、XMTrading-MT5がUSDJPYのreal tickデータを2022年1月分以降しか保持しておらず、2015年以降を対象にした検証ができないため（詳細は本節末尾の原因調査結果を参照）。OANDA証券のデモ口座開設完了後、Strategy Testerを再実行し、以後はOANDA側データを正式なIn-Sample/Out-of-Sample系列として扱う。以下のXMTrading結果は削除せず参考記録として保持するが、正式な受入基準比較・OOS・Walk Forwardの対象にはしない。

* [ ] OANDA証券デモ口座の開設を完了する（ユーザー作業）
* [ ] OANDA証券MT5（東京サーバー）端末をインストールする
* [ ] `tools/link-mt5.ps1`のJunction先をOANDA MT5端末のデータフォルダへ向け直す（`-TerminalData`パラメータで指定）
* [ ] OANDA側のUSDJPY Symbol仕様を確認する（Symbol名表記、Digits、Volume Min/Max/Step、Tick Size/Value、Stop Level/Freeze Level、レバレッジ=国内規制上限25倍、スワップ体系）
* [x] OANDA側でUSDJPYのreal tick履歴を2015年以降で取得する（2026-08-16試行、**失敗**）
* [x] `.\tools\run-strategy-tester.ps1`をOANDA側データで再実行する（2026-08-16、2015.01.01-2025.12.31指定で完走、exit=0）
* [x] 新しいレポートを`results/backtests/<run-id>-USDJPY-H1/`へ保存する（`results/backtests/20260816-113850-USDJPY-H1/`）
* [ ] 新結果を踏まえてHANDOFF.md / `docs/production-readiness-report.md` / `docs/production-readiness-checklist.md`を更新する

**2026-08-16重大な判明事項: OANDA証券でもreal tickの深い履歴は取得できなかった。** 実行は完走したが「ヒストリー品質2%リアルティック」となり、ほぼ全期間が合成tickだった。OANDA-Japan MT5 Demoサーバーの`.../ticks/USDJPY/`を確認したところ、real tickの`.tkc`ファイルは2025-09〜2026-08の約1年分（一部欠落あり）しか存在せず、2015〜2024年分は皆無だった。詳細は`results/backtests/20260816-113850-USDJPY-H1/INVALID-2pct-real-ticks.md`。

比較: XMTrading-MT5は2022-01以降（約4.5年分）のreal tickを保持していたのに対し、OANDA-Japan MT5 Demoは2025-09以降（約1年分）しか保持していない。**ブローカー切替はreal tick履歴の深さを改善するどころか悪化させた。** これはブローカー固有の問題ではなく、MT5デモ口座サーバー一般がraw tickレベルの長期履歴を保持しない構造的制約である可能性が高い（Real口座や有償tickデータベンダーでの挙動は未確認）。

* [x] 2015年以降のreal tick取得という当初目標をどう扱うか判断する（**2026-08-16解決**: OANDA証券のWeb版Tickダウンロードツールから2016年9月以降のUSDJPY real tick CSV（120か月分、圧縮4.0GB）を取得。MT5デモ口座サーバーのライブtickキャッシュとは別に、Custom Symbol `USDJPY_HIST`（`USDJPY`の仕様を複製）へ`mt5/Tools/ImportOandaTicks.mq5`経由で投入する方式を確立した。詳細は`DECISIONS.md` DEC-023を参照）

**2026-08-16: Custom Symbol `USDJPY_HIST`への投入完了。** 全119ファイル・約8億8,097万tick（9月分の825万tickと合わせ累計約8億8,922万tick、2016-09〜2026-08）をパースエラー0件で投入した。Strategy Testerで2016年9月単月・2020年通年（月境界をまたぐ12か月）の両方について「ヒストリー品質100%リアルティック」を確認済み（`results/backtests/oanda-hist-validation-2016-09/`、`results/backtests/oanda-hist-validation-2020/`）。2020年通年のMock ALLOW実行では総損益-83,262円・取引数117（正式なIS/OOS期間としてはまだ採用しておらず、スポットチェック目的の参考値）。

* [x] 正式なIn-Sample/Out-of-Sample/Walk Forward期間を`USDJPY_HIST`（2016-09〜2026-08の範囲内）で確定する（2026-08-16確定、`DECISIONS.md` DEC-024参照。開発・In-Sample=2016-09〜2020-12、OOS/Walk Forward評価=2021-01〜2024-12、Final Holdout=2025-01〜2026-08、Walk Forwardは4年学習→1年検証のローリング5Fold。ユーザー指定の開始日2016-01は`USDJPY_HIST`の実データ開始2016-09と矛盾していたため、実際に取得済みの範囲へ補正した）
* [x] In-Sample期間でStrategy Testerを実行し、`run-metadata.json`を作成する（2026-08-16実施。当初期間2016-09〜2020-12で実行したところ取引数0件の異常が判明し、原因調査の結果Tester開始日が`USDJPY_HIST`実データ最古日（2016-08-31）に近すぎ、D1/H4インジケーターのウォームアップに必要なバッファ（実測で9〜10か月必要）が不足していたことが判明。詳細な原因調査・二分探索の経緯は`results/backtests/20260816-180519-USDJPY-H1/ANOMALY-zero-trades.md`、期間補正は`DECISIONS.md` DEC-025を参照。開始日を**2017-09-01**へ補正した上で正式再実行し完走（`results/backtests/20260816-193344-USDJPY-H1/`）: ヒストリー品質100%リアルティック、取引数55・約定数110、総損益-65,696円、Profit Factor 0.66、最大DD 96,450円（9%）、Sharpe -3.20、期待利得-1,194.47円、ロング40件/勝率27.50%、ショート15件/勝率20.00%、最大連敗17件（-80,818円）。受入基準未凍結のため合否は未判定）
* [x] In-Sample結果（PF 0.66、勝率25.45%、最大連敗17件）を踏まえ、ブレイクアウトのだまし対策として`InpBreakoutBufferPoints`を0→10へ変更し、同一IS期間（2017-09-01〜2020-12-31）で再実行する（2026-08-17実施、`mt5/Experts/CoreEA.mq5`・`mt5/Include/Core/Config.mqh`・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`を変更、MQL5コンパイル・7 Script Test全PASS確認済み。結果は`results/backtests/20260817-090348-USDJPY-H1/`: 取引数53・約定数106、総損益-68,194円、Profit Factor 0.64、Sharpe -3.34、期待利得-1,286.68円、ロング38件/勝率26.32%、ショート15件/勝率20.00%、最大連敗17件（-80,550円）。**評価: 効果はほぼなし（誤差範囲内でわずかに悪化）**。取引数が55→53と2件しか減らず、修正前後で2017-09-01〜09-15の連続損失トレード列（注文#2〜#13）が価格・SL/TPまで完全一致しており、これらはバッファの影響を受けないプルバックパターン由来である可能性が高い。バッファ単独では損失の主因（プルバック側の誤発注、またはD1/H4トレンド判定の遅行性）に到達できておらず、追加調整（プルバック条件の厳格化、複数バー確認、トレンド強度フィルタ等）が必要と判断。ユーザー指示によりこの修正は2026-08-17に`InpBreakoutBufferPoints=0.0`へ差し戻し済み）
* [x] 上記を踏まえ、プルバック条件の厳格化（ATR許容幅縮小、複数バー確認）のみを修正し、同一IS期間で再実行する（2026-08-17実施。`mt5/Include/Strategy/TrendFollowingRules.mqh`の`IsPullback`を単一足条件から「タッチ足(shift2、EMA近接判定)＋確認足(shift1、終値がEMA・自身の始値・タッチ足高値を上回る)」の2本足確認へ変更し、`InpPullbackAtrTolerance`を0.25→0.15へ縮小（`mt5/Include/Strategy/TrendFollowingStrategy.mqh`・`mt5/Include/Core/Config.mqh`・`mt5/Experts/CoreEA.mq5`・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`も変更、`mt5/Tests/TestTrendFollowingRules.mq5`を新シグネチャに合わせて更新し新規の否定ケースを追加、MQL5コンパイル・7 Script Test全PASS確認済み）。結果は`results/backtests/20260817-100327-USDJPY-H1/`: 取引数185・約定数370、総損益-78,510円、Profit Factor 0.87、Sharpe -1.03、期待利得-424.38円、ロング121件/勝率28.93%、ショート64件/勝率34.38%、最大連敗14件（-66,890円）。**評価: 1トレードあたりの質は大幅改善（PF0.66→0.87、勝率25.45%→30.81%、Sharpe -3.20→-1.03、期待利得-1,194.47円→-424.38円、ショート勝率20.00%→34.38%）したが、想定に反しトレード数が55→185件(約3.4倍)へ急増し、期待値が依然マイナスのため総損益はむしろ-65,696円→-78,510円へ悪化。効果は不十分、追加調整が必要と判断**。原因はタッチ条件（EMA近接）と反転条件（終値がタッチ足高値を上回る）を別々の足に分離した設計にあると考えられる: トレンド中に頻発する「通常の陽線がタッチ足の高値を上回るだけ」のパターンまで拾ってしまい、単一足で両方同時に満たす必要があった旧条件より発生頻度が増えてしまった（厳格化ではなく緩和の方向に作用）。PFは0.87でまだ1未満のため収益性基準を満たさない。次の一手としては、確認足自身もEMAから大きく離れていないことを条件に加える、あるいはトレード数を絞る別のフィルタ（トレンド強度等）の追加が候補。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] 上記を踏まえ、プルバックの確認足(shift1)自身もEMAから大きく乖離していないこと（`entry_fast_ema+tolerance`以内）を追加条件化し、同一IS期間で再実行する（2026-08-17実施。`mt5/Include/Strategy/TrendFollowingRules.mqh`の`IsPullback`へ確認足のEMA近接制約を追加、既存の`InpPullbackAtrTolerance`(0.15)をそのまま流用しパラメータ変更なし。`mt5/Tests/TestTrendFollowingRules.mq5`に新規否定ケースを追加、MQL5コンパイル・7 Script Test全PASS確認済み）。結果は`results/backtests/20260817-101916-USDJPY-H1/`: 取引数149・約定数298、総損益-86,279円、Profit Factor 0.82、Sharpe -1.45、期待利得-579.05円、ロング97件/勝率27.84%、ショート52件/勝率32.69%、最大連敗9件（-43,202円）。**評価: 狙い通りトレード数(185→149件、-19.5%)と最大連敗(14→9件、-66,890円→-43,202円)は大きく改善したが、直前の状態(2本足確認のみ)との比較ではProfit Factor(0.87→0.82)・勝率(30.81%→29.53%)・Sharpe(-1.03→-1.45)・期待利得(-424.38→-579.05円)・純損益(-78,510→-86,279円)がいずれも悪化しており、この単体の追加制約としては効果不十分**。EMAから大きく離れた確認足（強いモメンタムでタッチ足高値を突破）の方がむしろ継続の確度が高く、EMA近傍にとどまる弱い突破の方が失敗しやすいという逆の仮説を支持する結果になった。当初のベースライン(55件・PF0.66・Sharpe-3.20・最大連敗17件)との比較ではSharpe・期待利得・最大連敗は依然大幅改善しているが、3回の修正いずれもProfit Factor>1（収益性基準）には未達。次の一手はユーザー判断待ち（例: EMA近接制約の撤回、トレンド強度フィルタの追加、ML/Decision APIを有効化した状態での再検証など）。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] 上記を踏まえ、EMA近接制約を撤回し、2本足確認＋ATR許容幅縮小の状態（`results/backtests/20260817-100327-USDJPY-H1/`、PF0.87）を土台として、タッチ足(shift2)自身がトレンドに逆行する調整足であること（BUY: `touch_close<touch_open`、SELL: `touch_close>touch_open`）を追加条件化し、同一IS期間で再実行する（2026-08-17実施。`mt5/Include/Strategy/TrendFollowingRules.mqh`の`IsPullback`からEMA近接制約を除去しタッチ足逆行性制約へ差し替え、`mt5/Include/Strategy/TrendFollowingStrategy.mqh`で`touch_open`/`touch_close`を新規読取、`mt5/Tests/TestTrendFollowingRules.mq5`を新シグネチャ・新規否定ケースに更新、`docs/configuration.md`更新。MQL5コンパイル・7 Script Test全PASS確認済み）。結果は`results/backtests/20260817-103255-USDJPY-H1/`: 取引数90・約定数180、総損益-91,889円、Profit Factor 0.70、Sharpe -2.78、期待利得-1,020.99円、ロング50件/勝率22.00%、ショート40件/勝率32.50%、最大連敗13件（-61,126円）。**評価: 取引数は185→90件へ約半減し絞り込み自体は達成したが、Profit Factor(0.87→0.70)・勝率(30.81%→26.67%)・Sharpe(-1.03→-2.78)・期待利得(-424.38→-1,020.99円)・純損益(-78,510→-91,889円)がいずれも土台から大きく悪化し、当初ベースライン(PF0.66)に近い水準まで後退した。効果不十分、この修正は推奨しない**。これでEMA近接制約(PF0.82)・タッチ足逆行性制約(PF0.70)という2方向の追加制約がいずれも土台(PF0.87)からの改善に失敗したことになり、2本足確認＋ATR許容幅縮小(PF0.87)がこれまでのプルバック厳格化アプローチの中で最良の結果である。これ以上プルバック条件を絞り込む方向の調整は逆効果の可能性が高く、別レバー（トレンド強度フィルタの追加、ML/Decision API有効化、あるいはPF0.87の土台へ差し戻して現状維持）への切り替えをユーザーに提案する。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] 上記を踏まえ、タッチ足逆行性制約を撤回し土台（2本足確認＋ATR許容幅縮小、PF0.87、`results/backtests/20260817-100327-USDJPY-H1/`）へ差し戻した上で、トレンド強度フィルタ（H1 ADX、期間14、閾値`InpMinimumAdx=20.0`未満は候補棄却）を新規追加し、同一IS期間で再実行する（2026-08-17実施。`mt5/Include/Strategy/TrendFollowingRules.mqh`・`mt5/Tests/TestTrendFollowingRules.mq5`は土台の2本足確認版へ差し戻し。`mt5/Include/Core/Config.mqh`（`adx_period`/`minimum_adx`フィールド追加、バリデーション追加）・`mt5/Experts/CoreEA.mq5`（`InpAdxPeriod`/`InpMinimumAdx`入力追加）・`mt5/Include/Strategy/TrendFollowingStrategy.mqh`（`iADX`ハンドル追加、`ATR_TOO_LOW`と同じインライン閾値ゲートとして`ADX_TOO_LOW`を追加）・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`を変更。MQL5コンパイル・7 Script Test全PASS確認済み）。結果は`results/backtests/20260817-104528-USDJPY-H1/`: 取引数174・約定数348、総損益-68,530円、Profit Factor 0.88、Sharpe -1.02、期待利得-393.85円、ロング114件/勝率30.70%、ショート60件/勝率31.67%、最大連敗13件（-62,944円）。**評価: 土台からトレード数を185→174件(-5.9%)へわずかに絞り込みつつ、Profit Factor(0.87→0.88)・勝率(30.81%→31.03%)・Sharpe(-1.03→-1.02)・期待利得(-424.38→-393.85円)・純損益(-78,510→-68,530円)・最大連敗(14→13件)のすべてが同時に改善**。これまでの3回の追加調整（ブレイクアウトバッファ、EMA近接制約、タッチ足逆行性制約）はいずれもトレード数削減と引き換えに質を悪化させたが、今回のADXフィルタは初めて全指標が同方向（改善）に動いた。当初ベースライン（修正前、55件・PF0.66・純損益-65,696円）と比較しても、純損益はほぼ同水準まで回復しつつ、勝率・Sharpe・期待利得・最大連敗は大幅に上回っている。**ただしProfit Factorは0.88とまだ1未満で収益性基準（PF>1）は未達成であり、絞り込み幅も相対的に小さい（-5.9%）ため、方向性は正しいが規模としてはまだ不十分、追加調整が必要と判断**。次の一手候補: ADX閾値をより高く（例: 25〜30）設定し絞り込み幅を拡大する。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] 上記を踏まえ、`InpMinimumAdx`を20→25へ引き上げ、同一IS期間で再実行する（2026-08-17実施。`mt5/Experts/CoreEA.mq5`・`mt5/Include/Core/Config.mqh`・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`のみ変更、ロジック変更なし。MQL5コンパイル・7 Script Test全PASS確認済み）。結果は`results/backtests/20260817-110009-USDJPY-H1/`: 取引数147・約定数294、総損益-94,761円、Profit Factor 0.81、Sharpe -1.53、期待利得-644.63円、ロング101件/勝率29.70%、ショート46件/勝率28.26%、最大連敗11件（-51,429円）。**評価: トレード数は174→147件(-15.5%)へさらに絞り込まれたが、Profit Factor(0.88→0.81)・勝率(31.03%→29.25%)・Sharpe(-1.02→-1.53)・期待利得(-393.85→-644.63円)・純損益(-68,530→-94,761円)はいずれも悪化（最大連敗のみ13→11件で改善）。効果は逆効果、この引き上げは推奨しない**。これはEMA近接制約・タッチ足逆行性制約で観測されたのと同じパターンで、ADX閾値20は既にローカルな最適点に近く、それ以上の絞り込みは収益に貢献するトレードまで除外してしまう。**ADX閾値20（`results/backtests/20260817-104528-USDJPY-H1/`、PF0.88・純損益-68,530円）が、これまでの全調整の中で最良の結果であり、この状態への差し戻しを推奨する**。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] `InpMinimumAdx`を25→20へ差し戻す（2026-08-17実施。`mt5/Experts/CoreEA.mq5`・`mt5/Include/Core/Config.mqh`・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`を変更、コンパイル全PASS確認済み。パラメータ・ロジックとも`results/backtests/20260817-104528-USDJPY-H1/`と完全一致する状態のため、決定論的なStrategy Tester再実行は行わず同runを現時点の最良状態として採用。現状の到達点: 2本足プルバック確認＋ATR許容幅0.15＋ADX≧20、取引数174、Profit Factor 0.88、Sharpe -1.02、期待利得-393.85円、純損益-68,530円、最大連敗13件。PFは1未満のため収益性基準は依然未達成）
* [x] 上記を踏まえ、RSI帯域を強モメンタム方向へ狭め（`InpRsiBuyMin`50→55、`InpRsiSellMax`50→45、過熱側の`InpRsiBuyMax`=75/`InpRsiSellMin`=25は据え置き）、同一IS期間で再実行する（2026-08-17実施。`mt5/Experts/CoreEA.mq5`・`mt5/Include/Core/Config.mqh`・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`のみ変更、ロジック変更なし。MQL5コンパイル・7 Script Test全PASS確認済み）。結果は`results/backtests/20260817-113242-USDJPY-H1/`: 取引数163・約定数326、総損益-85,409円、Profit Factor 0.84、Sharpe -1.42、期待利得-523.98円、ロング108件/勝率30.56%、ショート55件/勝率29.09%、最大連敗11件（-55,213円）。**評価: トレード数は174→163件(-6.3%)へ絞り込まれたが、Profit Factor(0.88→0.84)・勝率(31.03%→30.06%)・Sharpe(-1.02→-1.42)・期待利得(-393.85→-523.98円)・純損益(-68,530→-85,409円)はいずれも悪化（最大連敗のみ13→11件で改善）。効果不十分、この修正は推奨しない**。これでEMA近接制約・タッチ足逆行性制約・ADX閾値25への引き上げに続き、**現在の最良状態（土台+ADX20、PF0.88）への追加の絞り込みは4回連続でいずれも逆効果**となった。これは偶然ではなく、この状態が閾値調整による改善余地をほぼ使い切った局所最適に近いことを強く示唆する。ADX20の状態（`results/backtests/20260817-104528-USDJPY-H1/`）への差し戻しをユーザーに提案し、単一パラメータの閾値調整という同方向のアプローチは限界に達した可能性が高いため、別レバー（RR比の見直し、ML/Decision API側の選別効果の検証等）への切り替えを提案する。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] RSI帯域の狭小化を差し戻し（`InpRsiBuyMin`55→50、`InpRsiSellMax`45→50）、現状の最良状態（土台+ADX≧20、`results/backtests/20260817-104528-USDJPY-H1/`と同一設定）へ戻した上で、Risk/Reward比（`InpRiskRewardRatio`）を1.0/1.25/1.5/1.75/2.0/2.5/3.0の7水準で比較する（2026-08-17実施。RSI差し戻しは`mt5/Experts/CoreEA.mq5`・`mt5/Include/Core/Config.mqh`・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`を変更しコンパイル全PASS確認済み。RR以外はロジック変更なしのためRR=2.0は`results/backtests/20260817-104528-USDJPY-H1/`を再利用し、残り6水準を新規実行）。

  | RR | 取引数 | PF | 勝率 | 損益分岐勝率 | 差 | Sharpe | 期待利得 | 最大DD | 最大連敗 | 純損益 |
  |---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
  | 1.00 | 177 | 0.82 | 45.76% | 50.00% | -4.24pt | -2.55 | -463.73円 | 100,427円(10%) | 6件(-27,599円) | -82,081円 |
  | 1.25 | 157 | 0.80 | 39.49% | 44.44% | -4.95pt | -2.52 | -569.12円 | 96,920円(10%) | 6件(-27,056円) | -89,352円 |
  | 1.50 | 137 | 0.80 | 35.04% | 40.00% | -4.96pt | -2.22 | -622.89円 | 101,970円(10%) | 9件(-40,259円) | -85,336円 |
  | 1.75 | 185 | 0.86 | 33.51% | 36.36% | -2.85pt | -1.38 | -440.68円 | 102,021円(10%) | 11件(-52,236円) | -81,525円 |
  | **2.00** | **174** | **0.88** | **31.03%** | **33.33%** | **-2.30pt** | **-1.02** | **-393.85円** | 103,364円(10%) | 13件(-62,944円) | -68,530円 |
  | 2.50 | 77 | 0.73 | 23.38% | 28.57% | -5.19pt | -1.78 | -993.74円 | 97,421円(10%) | 11件(-51,807円) | -76,518円 |
  | 3.00 | 95 | 0.83 | 22.11% | 25.00% | -2.89pt | -1.15 | -621.43円 | 99,744円(10%) | 11件(-52,532円) | **-59,036円**（純利益は最良） |

  各run: `results/backtests/20260817-114304-USDJPY-H1/`(1.0)、`results/backtests/20260817-114448-USDJPY-H1/`(1.25)、`results/backtests/20260817-114631-USDJPY-H1/`(1.5)、`results/backtests/20260817-114814-USDJPY-H1/`(1.75)、`results/backtests/20260817-104528-USDJPY-H1/`(2.0、既存流用)、`results/backtests/20260817-115004-USDJPY-H1/`(2.5)、`results/backtests/20260817-115146-USDJPY-H1/`(3.0)。

  **評価: 現行デフォルトのRR=2.0が、PF・Sharpe・期待利得・損益分岐勝率との差のいずれにおいても7水準中最良であり、既に妥当な選択だったことが確認された。純利益のみで見るとRR=3.0が最良(-59,036円)だが、これは取引数が少なく(95件)ペイオフを拡大しただけの効果で、PF(0.83)・Sharpe(-1.15)はRR=2.0に劣る。「利益額だけでRRを選ぶべきではない」というユーザーの懸念どおりの結果になった。全7水準ともPFは1未満で、損益分岐勝率との差は-2.3pt〜-5.2ptの範囲に収まっており、RRをどう調整しても勝率不足（約束的莫大な不足ではなく数ポイントの恒常的な不足）は解消されない。これはRR比の調整では解決できない、エントリーシグナル自体の勝率不足が根本原因であることを改めて裏付ける結果である。取引数がRRによって大きく変動する(77〜185件)のは、`InpMaxOpenPositions=1`により1トレードが約定中は新規候補を検討できないため、TPが近い（低RR）ほど早く決済され回転率が上がる副次効果であり、エントリー条件自体の変化ではない点に留意。**

  **OOSでの安定性について**: DEC-024/025で確立したIS/OOS分離方針（OOS結果を見た後に同じOOS期間へ再最適化しない）に基づき、本スイープはOOS期間（2021-01〜2024-12）では一切検証していない。IS内での安定性の代替指標として、RR=1.75〜2.0にかけてPF(0.86→0.88)・Sharpe(-1.38→-1.02)・期待利得(-440.68→-393.85)が滑らかに単調改善しており、RR=2.0が孤立した外れ値ではなく緩やかな山の頂点に位置することが確認できる（RR=2.5は取引数77件と少なくノイズの影響を受けやすい外れ値の可能性がある）。ただしこれはIS単体の観察であり、真のOOS安定性の証明にはならない。RR=2.0を含む現状の最良状態を正式にOOS/Walk Forwardで検証するのは、TASKS.md既存タスクの「Walk Forward各Fold」実行時に一度だけ行うべきであり、本スイープの結果を理由にOOS期間を先取りして確認することはしない。

  **結論: 現行のRR=2.0を維持することを推奨する。RR比の変更では収益性基準（PF>1）に到達できないことが明確になったため、追加調整が必要**。次の一手候補: エントリーシグナル自体の勝率改善（ML/Decision API側の選別効果の検証等）。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] RR=2.0（変更不要、既にデフォルト値）を維持した上で、H4（`InpConfirmationTimeframe`）のADXも確認する多段フィルタを追加し、同一IS期間で再実行する（2026-08-17実施。`mt5/Include/Core/Config.mqh`（`minimum_confirmation_adx`フィールド追加・バリデーション追加）・`mt5/Experts/CoreEA.mq5`（`InpMinimumConfirmationAdx=20.0`入力追加）・`mt5/Include/Strategy/TrendFollowingStrategy.mqh`（`m_h4_adx_handle`追加、H1 ADXと同じインライン閾値ゲートとして`CONFIRMATION_ADX_TOO_LOW`を追加）・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`を変更。MQL5コンパイル・7 Script Test全PASS確認済み）。結果は`results/backtests/20260817-120451-USDJPY-H1/`: 取引数160・約定数320、総損益-71,643円、Profit Factor 0.87、Sharpe -1.19、期待利得-447.77円、ロング100件/勝率30.00%、ショート60件/勝率31.67%、最大連敗11件（-57,572円）。**評価: トレード数は174→160件(-8.0%)へ絞り込まれたが、Profit Factor(0.88→0.87)・勝率(31.03%→30.63%)・Sharpe(-1.02→-1.19)・期待利得(-393.85→-447.77円)・純損益(-68,530→-71,643円)はいずれもわずかに悪化（最大連敗のみ13→11件で改善）。悪化幅は過去の失敗例（ADX閾値25、RSI帯域狭小化）ほど大きくないが、効果不十分でありこの修正は推奨しない**。これで現在の最良状態（H1 ADX≥20単体、PF0.88）への追加の絞り込みは**5回連続**（EMA近接制約、タッチ足逆行性制約、ADX閾値25、RSI帯域狭小化、H4 ADX多段化）でいずれも悪化という結果になった。H1 ADXとH4 ADXは同じ趣旨のトレンド強度指標で相関が高いと見られ、H4側の追加閾値は既にH1側とD1/H4 EMAトレンド一致フィルタで捕捉済みの情報と重複している可能性が高い。**エントリー条件側の閾値調整というアプローチ全体が限界に達したと判断し、次に進むならML/Decision API側の選別効果の検証など、根本的に異なるレバーへの切り替えを強く推奨する**。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [ ] Walk Forward各Fold（Fold1: 学習2017-09〜2019-12/検証2020 〜 Fold5: 学習2020-01〜2023-12/検証2024、DEC-025でFold1学習開始を補正）を実行する。rule-based Strategyには学習ステップがないため、当面は各Foldの検証年についてのみ固定パラメータでStrategy Testerを実行する（学習を伴うWalk Forward評価は3.3節のML評価タスクで別途実施する）
* [ ] Final Holdout期間（2025-01〜2026-08）は、EA・MLモデル・閾値・SL/TP等を確定し他の全ゲートが完了するまで実行しない（一度だけの評価として温存する）
* [x] 新結果を踏まえてHANDOFF.md / `docs/production-readiness-report.md` / `docs/production-readiness-checklist.md`を更新する（2026-08-16実施）

---

`results/backtests/20260721-231302-USDJPY-H1/`に、実行済みレポート（`ets-20260721-231302-USDJPY-H1.htm`/`.png`）が存在することを2026-07-23の調査で確認した。USDJPY/H1、2025.01.01-2025.12.31、100% real ticks、Mock ALLOW（`InpTesterDecisionMode=1`, `InpTesterFixedMlProbability=0.65`）、`InpEnableTradeMutations=true`（Strategy Tester内のみ）で完走している。結果は総損益 **-95,024円**、Profit Factor **0.59**、最大Drawdown **10%（口座上限到達）**、取引数66、ロング勝率0%/ショート勝率26.67%、最大連敗9。ただしHANDOFF.md、`docs/production-readiness-report.md`、`docs/production-readiness-checklist.md`はこの結果を反映しておらず「口座未指定で未開始」のまま更新が必要（未実施）。同ディレクトリ以前の3回の試行（`20260721-220506`,`20260721-230456`,`20260721-231041`）は`tester.ini`のみでレポートが生成されておらず失敗している。

* [x] Demo Broker口座へログインする（実行成功の前提として達成。ただしDemo口座かReal口座かは未確認 — Broker表示は`XMTrading-MT5`/`Tradexfin Limited`）
* [x] Broker上のUSDJPYの実Symbol名を確認する（`USDJPY`表記で実行できている）
* [x] USDJPYのreal tick履歴を取得する（2025年分のみ。2020-2025期間では3回とも開始できず、原因未確認）
* [x] `mt5/test-config/StrategyTester-USDJPY-H1.ini` を確認する
* [x] `.\tools\run-strategy-tester.ps1 -TimeoutSeconds 900` を実行する（2026-07-21 23:13に完了）
* [x] Strategy Testerレポートが生成されることを確認する（`.htm`/`.png`が存在）
* [ ] TerminalログとEAログを保存する（2026-08-09調査: `results/backtests/20260721-231302-USDJPY-H1/`には`.htm`/`.png`/`tester.ini`のみが存在し、Journal/Expertsタブのログファイルは見つからない。保存先・保存有無は依然未確認）
* [x] Entry、Exit、SL、TP、Lot計算を確認する（2026-08-09、レポート内`注文`/`取引`テーブルを精査。132注文・66決済すべて`filled`、Entryコメント`trend-ea-v1-USDJPY-<bar time>`とExitコメント`sl <price>`/`tp <price>`が対応し、SL/TP価格とLot(0.03〜0.17、0.5%リスクに応じ変動)に矛盾なし。Commission合計0、Swap合計-10,846円、価格損益合計-84,178円で総損益-95,024円と一致することを確認。詳細は`run-metadata.json`の`metrics`を参照）
* [ ] Spread、Margin、OrderCheckの拒否動作を確認する（2026-08-09調査: 132注文はすべて`filled`で、拒否・requoteに該当する注文はレポートに1件も現れなかった。したがって拒否動作そのものは本実行では検証できていない。EAログが残っていないため追加確認も不可）
* [x] 実行条件とGit Commit SHAをMetadataへ記録する（`results/backtests/20260721-231302-USDJPY-H1/run-metadata.json`を作成。ただし実行時刻2026-07-21 23:13:02はリポジトリ最初のコミット651bcc5(2026-07-22 20:07:10)より前のため、対応するGit Commit SHAは存在せず記録不可＝`null`）
* [ ] 結果を事前固定した受入基準と比較する（受入基準自体がまだ文書化・凍結されていない — ユーザー判断待ち）
* [x] HANDOFF.md / `docs/production-readiness-report.md` / `docs/production-readiness-checklist.md`の「口座未指定で未開始」という記載を、実際の完走結果に合わせて更新する（2026-08-09実施）
* [x] 2020-2025期間で開始できなかった原因（tick履歴不足、Symbol仕様、Broker側制約等）を確認し、正式な検証対象期間を決定する（2026-08-10確認: 過去の`account is not specified`失敗は、当時の実行スクリプトのReport出力パス形式に起因していたとみられ、現行の`tools/run-strategy-tester.ps1`では再現しない（2020.01.01-2021.12.31を指定した実行がexit=0で正常終了）。ただし本質的な制約が判明: Broker（XMTrading-MT5/Tradexfin Limited）はUSDJPYのreal tickデータを**2022年1月分以降しか保持していない**（`.../ticks/USDJPY/`に202201.tkc以降のみ存在。OHLC M1バーは2016年から存在するが、real tickはない）。2020-2021を指定して実行すると、MT5がOHLCから合成tickを自動生成し「ヒストリー品質0%リアルティック」で完走してしまう（`results/backtests/20260810-144215-USDJPY-H1/INVALID-0pct-real-ticks.md`に詳細記録、このディレクトリの結果は無効・参考専用）。**結論: 2020〜2021年を含むreal tickベースの検証は本Broker/口座では不可能。** この結論を受け、2026-08-10にOANDA証券MT5への切替とOANDA側での2015年以降real tick取得が決定した（本節冒頭を参照）。XMTrading側での期間拡大は行わない）
* [ ] 今回の結果（総損益-95,024円、Profit Factor 0.59、最大DD10%到達、ロング勝率0%/6件、ショート勝率26.67%/60件）を踏まえ、Strategyパラメータの見直し・再実行・期間拡大のいずれで進めるかを判断する（ユーザー判断待ち。詳細は作業報告を参照）

## 2.2 `TestDecisionApiRules` の終了コード

**2026-08-16追記**: 本番運用ブローカーをOANDA証券MT5へ切り替え（`DECISIONS.md` DEC-023）、`tools/compile-mql5.ps1`・`tools/run-mql5-tests.ps1`・`tools/run-strategy-tester.ps1`・`tools/release-gate.ps1`・`tools/link-mt5.ps1`のデフォルト対象をOANDA端末へ変更した上で、Compile・7 Script Testを再実行した。結果はXMTrading環境と同一（全PASS、`TestDecisionApiRules`のみexit code 1）。この事象はBroker固有ではなく、Script/Runner/Terminal設定側の問題であることが裏付けられた。

**2026-08-17追記**: 市場レジーム判定ロジック追加に伴う新規`TestMarketRegimeClassifier`でも同じ事象（`TEST_SUITE_PASS`・全アサーションPASSだがTerminal Exit Code 1）を確認した。特定のテスト内容に依存しない再現性が高まり、Script/Runner/Terminal設定側の問題であるという既存の推定をさらに裏付ける。

* [ ] `TEST_SUITE_PASS` にもかかわらずProcess Exit Code 1となる状態を再現する
* [ ] MT5 Terminal側の終了理由を確認する
* [ ] Script、Runner、Terminal設定のどこに原因があるか特定する
* [ ] テスト結果判定方法が誤検知しないことを確認する
* [ ] 修正後に全MQL5 Script Testを再実行する

## 2.3 条件別分析（Entry/Exit）機能

* [x] `python.analysis.trade_breakdown`によるEntry側の条件別分析（方向・時間帯・曜日・ATR/ADX帯・保有時間・MFE/MAE・市場レジーム別のTrades/Win Rate/PF/Expectancy/Net Profit集計）を実装する（本セッション以前に実装済み。詳細は`docs/backtesting.md`「条件別分析」節を参照）
* [x] Exit（決済）側の分析を追加する（2026-08-17実施。ユーザー依頼「エントリーではなくExitを分析する方法」への対応。(1) `mt5/Include/Core/EAController.mqh`の`TRADE_CLOSED`ペイロードへMT5 `DEAL_REASON`を`close_reason`として追加記録（`DealReasonName()`ヘルパー新設、`SL`/`TP`/`SO`/`EXPERT`/`CLIENT`等）。(2) `python/analysis/reports.py`の`TRADE_CLOSED`必須フィールド検証へ`close_reason`を追加。(3) `python/analysis/trade_breakdown.py`へ`close_reason`・決済時刻基準の`close_weekday`/`close_session`（既存のEntry基準`weekday`/`session`とは別集計）・Giveback比率`giveback_ratio`=`(mfe-net_pnl)/mfe`とその分位帯`giveback_band`を追加し、`BREAKDOWN_COLUMNS`へ組み込んだ。あわせて`giveback_summary()`（平均/中央値Giveback比率、完全反転割合）を新設しレポートへ追加。(4) Telemetry API契約（`services/decision_api/src/decision_api/event_validation.py`の`PAYLOAD_FIELDS["TRADE_CLOSED"]`/`SAFE_TEXT_FIELDS`）が同じ`TRADE_CLOSED`ペイロードを検証するため未更新だと新フィールドが拒否されることが判明し、あわせて更新（`contracts/trade-event-request.schema.json`は`payload`をゆるい`object`型として定義しているため契約ファイル自体の変更は不要）。`python/tests/test_analysis.py`・`python/tests/test_trade_breakdown.py`・`services/decision_api/tests/support.py`のfixtureを更新し新規テストケースを追加。MQL5コンパイル（9ターゲット）・7 Script Test全PASS、Python側`python/tests`・`services/decision_api/tests`合計92件全PASS確認済み。現時点のEAにはトレーリングストップ・時間切れ決済のロジックがないため、`close_reason`は実質的にSL到達／TP到達／保護SLなしのEmergency close（`EXPERT`）の3種類のみとなる。未コミットの作業ツリー差分のため、commitはユーザー指示があるまで保留する）
* [x] **重大バグ発見・修正: `TRADE_CLOSED`・`TRADE_ANALYTICS`監査イベントが実バックテストで一度も記録されていなかった**（2026-08-17発見・修正）。上記Exit分析機能を検証するため同一IS期間でStrategy Testerを再実行し`trade_breakdown`を実行したところ、160件の実トレードに対し相関できたトレードが0件だった。Strategy Tester自身のレポート（`.htm`、MT5内部集計）とEA監査JSONLを直接比較した結果、決済デタッチ（特にSL/TP自動執行によるもの）について`HistoryDealGetInteger/Double(transaction.deal, DEAL_ENTRY/DEAL_PRICE/DEAL_VOLUME/DEAL_PROFIT等)`が`OnTradeTransaction(TRADE_TRANSACTION_DEAL_ADD)`通知の時点でゼロ値を返しており（`DEAL_POSITION_ID`・`DEAL_SYMBOL`・`DEAL_MAGIC`は正しく読めるが、価格・volume・entry種別・損益系は未確定）、結果として決済判定条件`entry==DEAL_ENTRY_OUT`が常にfalseとなり`TRADE_CLOSED`ブロックへ到達すらしていなかったことが判明。新規建玉（EA自身の`OrderSend`）側は正しく記録されており、影響は決済デタッチのみ。**修正**: [EAController.mqh](mt5/Include/Core/EAController.mqh)を変更。(1) `OnTradeTransaction`内、デタッチ自身のentry種別・価格・volumeは`HistoryDealGetXxx`に依存せず、`MqlTradeTransaction`構造体が直接持つ`transaction.price`/`transaction.volume`と、ライブの`PositionSelectByTicket`による残存有無判定（構造体・ライブ状態はいずれも履歴DB確定を待たない）で代替。`InpMaxOpenPositions=1`・部分決済ロジックなしのためIN/OUTの二値判定で十分。(2) `TRADE_CLOSED`/`TRADE_ANALYTICS`の確定処理は`SPendingClosedPosition`キュー（`m_pending_closed_positions[]`）へ積み、`OnTick`側の新規`ProcessPendingClosedPositions()`で次Tick以降に履歴が確定してから集計する方式へ変更（`HistorySelectByPosition`が失敗する間はキューに残し再試行）。売買判断・発注・既存ポジション管理には一切触れていない（監査専用の変更）。MQL5コンパイル（9ターゲット）・7 Script Test全PASS確認済み。**再検証**: 同一IS期間で再実行した結果（`results/backtests/20260817-151603-USDJPY-H1/`）、総損益-71,643円・PF0.87・Sharpe-1.19・取引数160・約定数320と、修正前（`20260817-145221-USDJPY-H1/`、監査バグ修正前だが同一トレーディングロジック）・修正前の全過去ラウンドと完全一致。**MT5内部集計（Strategy Testerの`.htm`レポート）はこの監査バグの影響を一切受けていないことを実測で確認**（監査ログはMT5の取引判断・発注そのものには使われない、audit専用の下流ログのため）。修正後は`TRADE_CLOSED`=160件・`TRADE_ANALYTICS`=160件で全トレードと相関でき、先頭トレード（2017-09-01 SELL、SL決済、pnl=-5,328円）はStrategy Testerレポートの実績と完全一致することを確認した。
* [x] 修正後の監査データで`trade_breakdown`を実行しExit側を分析する（2026-08-17実施。詳細は本文の回答を参照。close_reason別: SL 111件/TP 49件、Emergency Close 0件。損失トレード111件中103件（92.8%）が一度含み益（MFE>0、平均2,752円）に達してからSLに到達しており、Giveback比率の中央値は2.25。原因はSL/TPを固定するだけの静的ブラケット注文で、建値へのSL引き上げ・トレーリング・部分利確等の動的Exit管理が一切ないこと。改善案（建値ストップ、部分利確、ATRトレーリング、シグナル失効による早期Exit）を提示した。未実装、ユーザー判断待ち）

---

# 3. 実市場データとモデル

## 3.1 データ準備

* [ ] 使用する市場データSourceを決定する
* [ ] データ利用条件とライセンスを確認する
* [ ] TimezoneとDSTの扱いを決定する
* [ ] Point-in-time整合性を確認する
* [ ] Spread、Commission、Swap、Slippageのデータ条件を決定する
* [ ] Data Quality Checkを実装または実行する

## 3.2 検証期間

* [ ] In-Sample期間を固定する
* [ ] Calibration期間を固定する
* [ ] Out-of-Sample期間を固定する
* [ ] Label Horizonに応じたgapを固定する
* [ ] OOS確認後に同じ期間を再利用しない運用を確立する

## 3.3 ML評価

* [ ] 実市場データでTrainingを実行する
* [ ] Probability Calibrationを実行する
* [ ] OOS評価を実行する
* [ ] Walk Forward評価を実行する
* [ ] 閾値候補を比較する
* [ ] 取引コスト込みで評価する
* [ ] 期間別・相場環境別の安定性を確認する
* [x] IS/OOS/Walk Forwardの過学習疑いを自動診断する機能を実装する（2026-08-16実装、`python/analysis/overfitting.py`。`DECISIONS.md` DEC-026参照。実データでの診断実行は未実施）
* [ ] 実際のIS/OOS/Walk Forward各期間の`performance-summary.json`で過学習疑い診断を実行する
* [ ] production候補Model Artifactを生成する
* [ ] Model VersionとSHA-256を記録する
* [ ] Model Artifactと評価Reportを保管する

---

# 4. AWS dev

## 4.1 初回デプロイ

* [ ] 使用するAWS Accountを確定する
* [ ] 使用するAWS Regionを確定する
* [ ] AWS CLIの認証先を確認する
* [ ] CDK Bootstrapの要否を確認する
* [ ] ModelとLLMを未設定にしたフェイルセーフ状態で`cdk diff`を確認する
* [ ] dev StackをDeployする
* [ ] CloudFormation Outputを記録する
* [ ] Decision API URLを記録する
* [ ] Telemetry API URLを記録する
* [ ] DynamoDB Tableを記録する
* [ ] Model Bucketを記録する
* [ ] SNS Topicを記録する

## 4.2 Secretと認証

* [ ] Decision API用HMAC共有鍵を安全に生成する
* [ ] Server側SecretをSSM SecureStringへ登録する
* [ ] EA側Secret Fileを作成する
* [ ] SecretがGit、ログ、Shell Historyへ残っていないことを確認する
* [ ] 正常な署名付きRequestを送信する
* [ ] 不正署名を拒否することを確認する
* [ ] Clock Skewを拒否することを確認する
* [ ] Nonce Replayを拒否することを確認する
* [ ] Duplicate RequestのIdempotencyを確認する

## 4.3 実通信

* [ ] Decision APIの正常応答を確認する
* [ ] DecisionがDynamoDBへ保存されることを確認する
* [ ] Telemetry APIの正常応答を確認する
* [ ] Trade EventがDynamoDBへ保存されることを確認する
* [ ] Candidate IndexからDecisionとEventを取得する
* [ ] CloudWatch Logsを確認する
* [ ] EMF Metricsを確認する

## 4.4 Alarm

* [ ] SNS Email Subscriptionを承認する
* [ ] Lambda Error Alarmを試験する
* [ ] API 5xx Alarmを試験する
* [ ] ML Error Alarmを試験する
* [ ] LLM Error Alarmを試験する
* [ ] DynamoDB System Error Alarmの検証方法を決定する
* [ ] Alarm通知が実際に到達することを確認する
* [ ] Alarm復旧時の挙動を確認する
* [ ] AWS Budgetsを設定する
* [ ] 費用異常通知を設定する

## 4.5 障害試験

* [ ] Lambda Timeout
* [ ] API Gateway 5xx
* [ ] HTTP 429
* [ ] DynamoDB Error
* [ ] S3 Model取得失敗
* [ ] Model checksum不一致
* [ ] SSM Parameter取得失敗
* [ ] Network切断
* [ ] DNS障害
* [ ] TLS障害
* [ ] Telemetry障害

---

# 5. LLM API

## 5.1 接続準備

* [ ] LLM Providerを確定する
* [ ] 固定Model IDを確定する
* [ ] Prompt Versionを確定する
* [ ] API KeyをSSM SecureStringへ登録する
* [ ] `llm_shadow_mode=true` を確認する
* [ ] CDK Diffを確認する
* [ ] dev Stackを再Deployする

## 5.2 実通信

* [ ] 実LLM APIへの接続を確認する
* [ ] 構造化されたALLOWを確認する
* [ ] 構造化されたVETOを確認する
* [ ] Timeout時のVETOを確認する
* [ ] Provider Error時のVETOを確認する
* [ ] 不正JSON時のVETOを確認する
* [ ] 必須Field欠落時のVETOを確認する
* [ ] 不正Decision値を拒否する
* [ ] Confidence範囲外を拒否する
* [ ] Secretがログへ出ていないことを確認する

## 5.3 Shadow Mode評価

* [ ] Shadow Modeログを一定期間蓄積する
* [ ] LLM未適用の結果を作成する
* [ ] 記録済みVETO適用時の結果を作成する
* [ ] VETO率を測定する
* [ ] 誤VETOを分析する
* [ ] Net Profitへの影響を分析する
* [ ] Drawdownへの影響を分析する
* [ ] 取引数への影響を分析する
* [ ] API Latencyを分析する
* [ ] Token使用量と費用を分析する
* [ ] 実務上の効果量を評価する
* [ ] productionでVETOを適用するか判断する

---

# 6. Demo口座

## 6.1 観測モード

次の設定で開始する。

```text
InpDecisionApiEnabled = true
InpTelemetryEnabled = true
InpEnableTradeMutations = false
```

* [ ] Strategy候補生成を確認する
* [ ] Decision API Requestを確認する
* [ ] ML判定を確認する
* [ ] LLM Shadow判定を確認する
* [ ] Risk判定を確認する
* [ ] ローカルJSONLを確認する
* [ ] TelemetryとDynamoDBを確認する
* [ ] Clock Skewを確認する
* [ ] API Latencyを確認する
* [ ] Broker Symbol仕様を確認する

## 6.2 障害試験

* [ ] Emergency Stop
* [ ] Strategy Stop
* [ ] Decision API停止
* [ ] API Timeout
* [ ] HTTP 4xx
* [ ] HTTP 5xx
* [ ] HTTP 429
* [ ] 不正JSON
* [ ] request ID不一致
* [ ] TTL切れ
* [ ] Clock Skew
* [ ] Replay
* [ ] ML Error
* [ ] LLM Error
* [ ] LLM Timeout
* [ ] DynamoDB障害
* [ ] Network切断
* [ ] Spread急拡大
* [ ] Margin不足
* [ ] OrderCheck失敗
* [ ] 約定拒否
* [ ] Stop Level違反
* [ ] Freeze Level違反

## 6.3 取引モード

観測モードと障害試験完了後にのみ実施する。

* [ ] ユーザー承認を得る
* [ ] 設定の証跡を保存する
* [ ] `InpEnableTradeMutations=true` に変更する
* [ ] 新規Entryを確認する
* [ ] Lot計算を確認する
* [ ] SL・TPを確認する
* [ ] Spread Guardを確認する
* [ ] Position Limitを確認する
* [ ] 約定とSlippageを確認する
* [ ] Exitを確認する
* [ ] MT5再起動後のPosition再認識を確認する

## 6.4 既存ポジション保護

* [ ] ポジション保有中にEmergency Stopを有効化する
* [ ] 新規注文が停止することを確認する
* [ ] 既存ポジション監視が継続することを確認する
* [ ] Broker側SLが維持されることを確認する
* [ ] TPが維持されることを確認する
* [ ] 保護SLなしPositionの検出を確認する
* [ ] 緊急決済を確認する
* [ ] Decision API停止中の管理継続を確認する
* [ ] LLM停止中の管理継続を確認する
* [ ] Telemetry停止中の管理継続を確認する

---

# 7. MQL5 VPS

* [ ] WebRequest許可URLを設定する
* [ ] EA Inputを確認する
* [ ] AutoTrading設定を確認する
* [ ] Secret Fileの配置方法を確認する
* [ ] VPS上でSecret Fileを読み込めることを確認する
* [ ] VPSからDecision APIへ接続する
* [ ] VPSからTelemetry APIへ接続する
* [ ] UTCとBroker Server Timeを確認する
* [ ] Audit JSONLを確認する
* [ ] VPS同期後の設定維持を確認する
* [ ] VPS再起動後のEA復旧を確認する
* [ ] VPS再起動後のPosition認識を確認する
* [ ] SL・TP継続を確認する
* [ ] Emergency Stopを確認する
* [ ] 外部障害時の新規注文拒否を確認する
* [ ] 長時間連続運転を実施する
* [ ] Weekend跨ぎを確認する
* [ ] Market Close・Openを確認する
* [ ] ログ容量と保持方法を確認する

---

# 8. 運用・監視の残タスク

* [ ] 独立した定期EA Heartbeatを設計する
* [ ] Heartbeatを実装する
* [ ] 無候補時間帯の死活判定を実装する
* [ ] MT5 Report Importerの必要性を評価する
* [ ] 必要ならMT5 Report Importerを実装する
* [ ] Telemetry自動再送キューの必要性を評価する
* [ ] 必要なら再送キューを実装する
* [ ] Secret Rotation手順を作成する
* [ ] Secret Rotationを演習する
* [ ] Incident Response手順を作成する
* [ ] 緊急停止と手動決済を演習する
* [ ] Model Rollbackを演習する
* [ ] CDK Rollbackを演習する

---

# 9. 小額実口座

以下の全項目完了後のみ着手する。

* [ ] Strategy Tester合格
* [ ] OOS合格
* [ ] Walk Forward合格
* [ ] AWS dev実通信合格
* [ ] LLM Shadow評価完了
* [ ] Demo障害試験合格
* [ ] Demo取引モード合格
* [ ] MQL5 VPS継続運転合格
* [ ] Alarm通知確認
* [ ] Kill Switch実証
* [ ] SL・TP継続実証
* [ ] 運用・Rollback手順の演習
* [ ] ユーザーによる明示的承認

---

# 10. Production Gate

* [ ] OOS Reportを保管する
* [ ] Walk Forward Reportを保管する
* [ ] Demo Reportを保管する
* [ ] Small Real Reportを保管する
* [ ] ML Model Versionを記録する
* [ ] ML Model SHA-256を記録する
* [ ] LLM Provider・Model・Prompt Versionを記録する
* [ ] AWS AccountとRegionを記録する
* [ ] VPS Secret File確認を記録する
* [ ] SNS通知確認を記録する
* [ ] Budgets確認を記録する
* [ ] Rollback Drill結果を記録する
* [ ] Production Evidence JSONを作成する
* [ ] Production Release Gateを実行する
* [ ] 承認者と承認時刻を記録する
