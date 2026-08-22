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
* [x] **監査ログ不具合修正後、Exit分析結果を踏まえて建値ストップ移動（1R）を追加し、同一IS期間で再実行する**（2026-08-17実施。詳細は2.3節の監査バグ修正記録を参照。エントリー条件側の閾値調整ではなく、初のExit（決済管理）側の修正。含み益が「建値〜当初SL距離」の`InpBreakevenTriggerR`倍（既定1.0）に達したらSLを建値へ引き上げる。`mt5/Include/Trading/PositionManager.mqh`（`CBreakevenStopRules`・`CPositionManager::MoveToBreakeven`新設）・`mt5/Include/Core/Config.mqh`（`enable_breakeven_stop`/`breakeven_trigger_r_multiple`追加）・`mt5/Experts/CoreEA.mq5`・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`を変更、`mt5/Tests/TestTradingRules.mq5`に単体テスト追加。MQL5コンパイル（9ターゲット）・7 Script Test全PASS確認済み）。結果は`results/backtests/20260817-154204-USDJPY-H1/`: 取引数158・約定数316、総損益-55,284円、Profit Factor 0.87、Sharpe -1.15、期待利得-349.90円、ロング101件/勝率47.52%、ショート57件/勝率29.82%、最大連敗8件（-31,385円）。**評価: 純損益(-71,643→-55,284円、+16,359円改善)・期待利得(-447.77→-349.90円)・Sharpe(-1.19→-1.15)・勝率(30.63%→41.14%、+10.5pt)・最大連敗(11件-57,572円→8件-31,385円)が同時に改善し、これまでのエントリー条件側の調整では見られなかった明確な複数指標同時改善となった。一方でProfit Factorは0.87のまま横ばいで、収益性基準（PF>1）には未達**。`trade_breakdown`によるExit分析で内訳を確認したところ、SL決済120件中33件（27.5%、平均pnl+83.6円）が建値付近で決済され実質無害化された一方、TP決済が49件→38件へ11件減少しており、一部トレードが建値到達後に押し戻されて建値ストップで決済され、本来到達していたはずのTP利益（平均9,473円）を取りこぼした可能性がある（ホイッスル現象）。Giveback比率は平均5.65→4.00、完全反転率67.8%→61.6%へ改善したが、依然半数超のトレードで含み益からの反転が発生しており、1Rという固定閾値が最適とは限らない。**総合評価: リスク管理指標は明確に改善する一方、収益性の根本指標（PF）は横ばいであり効果は部分的。次の一手候補: (a) トリガー水準のスイープ（0.5R/1.5R/2.0R等でTP取りこぼしとSL被害軽減のバランス点を探る）、(b) 建値+αのバッファ、(c) 部分利確との組み合わせ**。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] `InpBreakevenTriggerR`のトリガー水準スイープ（0.5/0.75/1.0/1.25/1.5/2.0）を実施する（2026-08-17実施。ロジック変更なし、`mt5/test-config/StrategyTester-USDJPY-H1.ini`の`InpBreakevenTriggerR`のみ変更し6水準で同一IS期間を再実行）。

  | TriggerR | 取引数 | 約定数 | PF | Sharpe | 期待利得 | 最大連敗 | 純損益 |
  |---|---:|---:|---:|---:|---:|---:|---:|
  | 0.5 | 143 | 286 | 0.78 | -2.37 | -468.53円 | 6件(-29,275円) | -67,000円 |
  | 0.75 | 171 | 342 | 0.85 | -1.34 | -354.06円 | 7件(-30,280円) | -60,544円 |
  | **1.00** | **158** | **316** | **0.87** | **-1.15** | **-349.90円** | 8件(-31,385円) | **-55,284円** |
  | 1.25 | 159 | 318 | 0.86 | -1.32 | -410.17円 | 9件(-41,765円) | -65,217円 |
  | 1.50 | 108 | 216 | 0.80 | -2.03 | -636.81円 | 9件(-43,825円) | -68,775円 |
  | 2.00（退化） | 160 | 320 | 0.87 | -1.19 | -447.77円 | 11件(-57,572円) | -71,643円 |

  各run: `results/backtests/20260817-162746-USDJPY-H1/`(0.5)、`results/backtests/20260817-162947-USDJPY-H1/`(0.75)、`results/backtests/20260817-154204-USDJPY-H1/`(1.0、既存流用)、`results/backtests/20260817-163158-USDJPY-H1/`(1.25)、`results/backtests/20260817-163403-USDJPY-H1/`(1.5)、`results/backtests/20260817-163612-USDJPY-H1/`(2.0)。

  **評価: TriggerR=1.0が6水準中、純損益・PF（0.87で2.0と同率1位）・Sharpe・期待利得・最大連敗のすべてで最良、または最良タイの結果となった**。0.75→1.00→1.25にかけて指標が滑らかに改善→ピーク→悪化する単峰形状になっており（PF: 0.85→0.87→0.86、Sharpe: -1.34→-1.15→-1.32）、1.0が孤立した外れ値ではなく緩やかな山の頂点に位置することを確認した。TriggerR=2.0は`InpRiskRewardRatio=2.0`（TP=2R）と数値が一致するため、建値到達前にTPへ到達し建値ストップが実質発動しない退化ケースであり、建値ストップ無効時のベースライン（`results/backtests/20260817-151603-USDJPY-H1/`、PF0.87・純損益-71,643円）と完全一致することを確認した（実装の健全性検証としても機能）。低トリガー（0.5・0.75）は早すぎる建値移動によりTP到達前の押し戻しで利益を取りこぼす一方、高トリガー（1.25・1.5）はSL被害軽減の恩恵が減り、特に1.5は取引数が108件へ大きく減少（資金回転率低下）した上に最大連敗の金額が悪化するなど、両極端で悪化する結果になった。**結論: TriggerR=1.0（デフォルト値のまま）を維持することを推奨する**。ただし全水準でPFは1未満であり、収益性基準（PF>1）には未到達のままである点は変わらない。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] 建値ストップ(1.0R)に加え、部分利確（1R到達で現在volumeの50%を利確、残りをTPまで引っ張る）を追加し、同一IS期間で再実行する（2026-08-17実施。`mt5/Include/Trading/PositionManager.mqh`（`CPartialTakeProfitRules`・`CPositionManager::ClosePartial`新設、`Monitor()`内で建値ストップより先に評価）・`mt5/Include/Core/Config.mqh`（`enable_partial_take_profit`/`partial_take_profit_trigger_r`/`partial_take_profit_close_fraction`追加）・`mt5/Experts/CoreEA.mq5`・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`を変更、`mt5/Tests/TestTradingRules.mq5`に単体テスト12件を追加。GlobalVariableベースのべき等性（`EmergencyClose`と同一パターン）で二重約定を防止し、Volume Step/Min未満への丸め・分割不可判定を実装。MQL5コンパイル（9ターゲット）・7 Script Test全PASS確認済み）。結果は`results/backtests/20260817-171319-USDJPY-H1/`: MT5レポートの取引数は232件・約定数392件だが、部分決済により1候補が複数行に分割カウントされるため、`trade_breakdown`でposition単位に再集計すると真のトレード数は160件（建値ストップのみの158件とほぼ同水準）。純損益-65,025円、Profit Factor 0.85、Sharpe -1.59、最大連敗6件（-29,345円）。**評価: 逆効果**。真のトレード数がほぼ同数（158→160）にもかかわらず、純損益(-55,284→-65,025円、-9,741円悪化)・PF(0.87→0.85)・Sharpe(-1.15→-1.59)がいずれも悪化した（最大連敗のみ8件-31,385円→6件-29,345円で改善）。close_reason別に再集計したところ、**TP到達件数は38件で変化がないのに、TP到達トレードの平均利益が9,408円→7,229円（-23.2%）へ大幅減少**していることが直接の原因と判明。部分利確のトリガー水準(1.0R)が建値ストップと同一に設定されているため、価格が1Rへ到達した時点で半分の利益を早期確定してしまい、最終的にTP(2R)まで到達したはずのトレードの半分もそこで打ち切ってしまう（1R+2Rの半々=1.5R、フル建玉のTP到達2Rより劣る）。Giveback完全反転率は67.8%→61.6%→52.3%と一貫して改善しており、含み益から完全に損失へ転落するトレードは着実に減少しているが、この改善効果はTP到達トレードの取りこぼしを相殺できていない。**この設定（TriggerR=1.0・fraction=0.5）での部分利確導入は推奨しない**。次の一手候補: (a) 部分利確のトリガーを建値ストップより低く設定（例: 0.5R）しTP到達トレードへの侵食を抑える、(b) `close_fraction`を縮小（例: 0.25〜0.33）、(c) 部分利確を撤回し建値ストップ単体（PF0.87、`20260817-154204-USDJPY-H1/`）へ差し戻す。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] 部分利確のトリガーを1.0R→1.5Rへ変更し、同一IS期間で再実行する（2026-08-17実施。`mt5/test-config/StrategyTester-USDJPY-H1.ini`の`InpPartialTakeProfitTriggerR`のみ変更）。**再実行の結果（`results/backtests/20260817-172255-USDJPY-H1/`）、約定数316件・PF0.87・純損益-55,284円と建値ストップ単体（`20260817-154204-USDJPY-H1/`）の数値と完全一致し、部分決済が一件も発生していない実装バグを発見した**。原因は`CPartialTakeProfitRules::ShouldClosePartial`のリスク基準（建値〜当初SL距離）を毎Tickの現在の`POSITION_SL`から算出していたこと。建値ストップ（1.0R、部分利確の1.5Rより低いトリガー）が先に発動しSLを建値へ移動すると、以降risk_distanceが0になり、それより高いトリガーの部分利確判定が永久にfalseを返す状態になっていた。**修正**: `mt5/Include/Trading/PositionManager.mqh`へ`InitialStopLoss()`を新設し、ポジションの当初SL（建値ストップ発動前の値）をGlobalVariableで一度だけ固定保存、部分利確のリスク基準にはこの不変の当初SL参照を使うよう変更（建値ストップ自身のべき等性判定は従来どおり現在のSLを参照、変更不要）。この不具合は既存の単体テスト（`InitialStopLoss`を経由しない直接呼び出し）では検出されず、Strategy Tester実データでの統合検証で初めて発見された。MQL5コンパイル（9ターゲット）・7 Script Test全PASS確認済み。修正後、約定数が316→376件へ増加し部分決済が実際に発生していることを確認した上で再実行した。結果は`results/backtests/20260817-172754-USDJPY-H1/`: position単位の真のトレード数162件、純損益-56,364円、Profit Factor 0.87、Sharpe -1.24、最大連敗7件（-35,136円）、TP到達38件・平均利益8,388円。**評価: 1.0Rトリガーで見られた明確な悪化（PF0.85、TP平均利益7,229円）は大幅に緩和され、PFは建値ストップ単体と同水準（0.87）まで回復した。しかし建値ストップ単体（純損益-55,284円、Sharpe-1.15、TP平均利益9,408円）と比較すると、純損益(-1,080円)・Sharpe(-0.09)・最大連敗額(-31,385→-35,136円)はいずれもわずかに劣り、TP平均利益も9,408円には届かない。実質的に横ばい〜わずかに劣る結果であり、この構成（部分利確1.5R・50%）を追加導入する積極的な理由はない**。次の一手候補: (a) トリガーをさらに高く（1.75R等）またはclose_fractionを縮小する余地はあるが収穫逓減の可能性が高い、(b) 部分利確を撤回し建値ストップ単体へ差し戻す、(c) 別のExit手法（ATRトレーリング等）へ切り替える。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] 当初SL固定バグ修正が、修正前に実行した部分利確@1.0Rの結果（`results/backtests/20260817-171319-USDJPY-H1/`、PF0.85・純損益-65,025円）に影響していないか再検証する（2026-08-17実施。バグは「部分利確のトリガーが建値ストップより高い場合、建値ストップが先に発動した後のTickで判定不能になる」というものであり、トリガーが同一（1.0R=1.0R）の場合は条件を満たす最初のTickで両者ともまだ現在SL=当初SLのため、理論上は影響を受けないと判断した上で、念のため実データで検証した）。`InpPartialTakeProfitTriggerR=1.0`（修正後のコードのまま）で再実行した結果（`results/backtests/20260817-195007-USDJPY-H1/`）、約定数392件・PF0.85・純損益-65,025円と、修正前の実行結果と完全一致することを確認した。**結論: 部分利確@1.0Rの結果は当初SL固定バグの影響を受けておらず、既存の評価（1.0Rトリガーは逆効果）は修正不要でそのまま有効**。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] 部分利確を撤回し建値ストップ単体（PF0.87、`20260817-154204-USDJPY-H1/`）へ差し戻した上で、ATRトレーリングストップ（含み益が一定を超えたらATR倍率でSLを追従）を追加し、建値ストップ移動とどちらが有効か比較する（2026-08-17実施。**撤回**: `mt5/Include/Trading/PositionManager.mqh`から`CPartialTakeProfitRules`・`CPositionManager::ClosePartial`・`m_partial_tp_key_prefix`を削除、`mt5/Include/Core/Config.mqh`・`mt5/Experts/CoreEA.mq5`・`mt5/Tests/TestTradingRules.mq5`・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`から部分利確関連の入力・テスト・記述を除去。**追加**: 含み益が「建値〜当初SL距離」の`InpAtrTrailingTriggerR`倍（既定1.0、建値ストップと同一トリガーで比較しやすくした）に達したらトレーリングを開始し、以降は現在Bid/AskからATR×`InpAtrTrailingAtrMultiple`（既定2.0）だけ離れた位置へSLを保護方向にのみ追従させる`CAtrTrailingStopRules`を新設。トレーリング開始判定には当初SL固定参照（`InitialStopLoss`、部分利確用から流用・repurpose）を使用。`MoveToBreakeven`を汎用`ModifyStopLoss`へリネームし建値ストップ・ATRトレーリング両方から共用。ATR用インジケーターハンドルを新設し`CEAController::Shutdown()`から`CPositionManager::Shutdown()`を呼ぶよう追加。`mt5/Tests/TestTradingRules.mq5`へ`CAtrTrailingStopRules`の単体テスト14件を追加。**建値ストップとATRトレーリングどちらが有効か比較するため、本runでは`InpEnableBreakevenStop=false`としATRトレーリング単体で評価した**。MQL5コンパイル（9ターゲット）・7 Script Test全PASS確認済み）。結果は`results/backtests/20260817-200615-USDJPY-H1/`: 取引数131・約定数262、純損益-82,038円、Profit Factor 0.76、Sharpe -2.61、最大連敗6件（-28,045円）。**評価: ATRトレーリングストップは建値ストップ単体より大幅に悪化した。純損益(-55,284→-82,038円、-26,754円悪化)・PF(0.87→0.76)・Sharpe(-1.15→-2.61)がいずれも顕著に悪化し、これまで試した全ての追加調整の中で最も悪い結果**。原因はTP到達件数が38件→19件へ半減したこと。TP到達トレードの平均保有時間も約40時間→約16時間へ短縮しており、トレンドがTP(2R)へ到達する途中の通常の押し戻しを、2.0×ATRという比較的タイトなトレーリング幅が繰り返し捉えてしまい、本来到達したはずのTPまで到達できずに手前で決済されるケースが約半数に達していると考えられる。Giveback完全反転率は54.4%（建値ストップ単体の61.6%より改善）で損失トレードの部分救済という観点では優れているが、TP到達半減という損失を相殺できていない。**建値ストップ移動の方が明確に優れている。今回の設定（1.0Rトリガー・2.0×ATR幅）でのATRトレーリングストップ導入は推奨しない**。次の一手候補: (a) 建値ストップ単体（PF0.87、`20260817-154204-USDJPY-H1/`）を現状の最良状態として維持する、(b) ATRトレーリング幅を広げて（例: 3.0〜4.0×ATR）再試行する、(c) 別のレバー（ML/Decision API選別効果の検証等）へ切り替える。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] ATRトレーリングストップを撤回し建値ストップ単体（PF0.87、`20260817-154204-USDJPY-H1/`）へ差し戻した上で、シグナル失効による早期Exit（エントリー根拠＝トレンド/ADXが消失したら満期を待たず決済）を追加し、同一IS期間で再実行する（2026-08-17実施。**撤回**: `mt5/Include/Trading/PositionManager.mqh`から`CAtrTrailingStopRules`・ATRインジケーターハンドル・`CPositionManager::Shutdown()`を削除、`mt5/Include/Core/Config.mqh`・`mt5/Experts/CoreEA.mq5`・`mt5/Tests/TestTradingRules.mq5`・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`・`mt5/Include/Core/EAController.mqh`から関連する入力・テスト・記述・呼び出しを除去。**追加**: 保有中ポジションのエントリー根拠（D1/H4トレンド一致、H1/H4 ADX）を確定足ベースで再検証し、いずれかが消失したら満期(SL/TP)を待たず市場成行で決済する。RSI・エントリーパターンは再チェックしない。`mt5/Include/Strategy/TrendFollowingStrategy.mqh`へ`IsTrendStillValid()`（判断ロジック、`Evaluate()`と同じ指標ハンドルを再利用、データ取得不能時はfalse-safeで保有継続）、`mt5/Include/Trading/PositionManager.mqh`へ`CloseOnSignalInvalidation()`（決済メカニズム、`EmergencyClose`と同じGlobalVariableべき等性パターン）、`mt5/Include/Core/EAController.mqh`へ`EvaluateSignalInvalidationExits()`（Strategy参照とPositionManager実行を仲介するオーケストレーション、既存ポジション監視の一部として新規候補評価より先に実行）を新設。Strategyから直接発注処理を呼び出さないという責務境界を維持するため、判断（Strategy）と実行（PositionManager）をController（EAController）が仲介する設計とした。建値ストップは有効のまま（両機能の組み合わせ）で評価。MQL5コンパイル（9ターゲット）・7 Script Test全PASS確認済み）。結果は`results/backtests/20260817-203110-USDJPY-H1/`: 取引数201・約定数402、純損益-50,214円、Profit Factor 0.87、Sharpe -1.22、最大連敗9件（-22,627円）。**評価: これまで試した3つのExit側施策（部分利確、ATRトレーリング、シグナル失効Exit）の中で唯一、純損益・期待利得・平均損失のいずれも建値ストップ単体を上回る改善を示した**。純損益(-55,284→-50,214円、+5,070円改善)・期待利得(-349.90→-249.82円)が改善し、真のトレード数も158→201件(+27%)へ増加（保有時間短縮により同一期間内での機会回転数が増加）。PFは0.87で横ばい、Sharpeはわずかに悪化(-1.15→-1.22)したが、ATRトレーリング(-2.61)・部分利確@1.0R(-1.59)ほどの悪化ではない。close_reason別に再集計したところ、新設の「EXPERT」（シグナル失効Exit）は86件発生し純損益はほぼゼロ(-2,630円)・PF0.97とほぼ収支均衡しており、従来なら平均-4,486円の全損に至っていたはずのトレードの一部を平均-1,509円という小さな損失で早期に打ち切ることに成功している（SL件数は120→87件へ減少）。TP到達件数は38→28件へ減少したが、TP到達トレードの平均利益はむしろ9,408→9,611円へわずかに上昇しており、部分利確・ATRトレーリングで見られた「TP到達トレードの利益を削る」副作用はほとんど見られない。Giveback完全反転率は64.2%（建値ストップ単体の61.6%よりやや悪化）だが、中央値Giveback比率は2.11→1.30へ大幅縮小し、反転の規模自体は抑制されている。**ただしPFは1未満のままで収益性基準には未達**。次の一手候補: (a) この状態を新たな最良候補として採用し次フェーズへ進む、(b) シグナル失効判定の条件を調整（H4 ADXのみ・H1 ADXのみに絞る等）して更なる改善余地を探る、(c) RR比・エントリー閾値の再調整（Exit側の挙動が変わったため、以前のRRスイープ結果が依然最適とは限らない）。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] シグナル失効判定の条件をTrend+H1 ADXのみ・Trend+H4 ADXのみへそれぞれ絞り込み（H1/H4 ADXいずれかを無効化）、同一IS期間で再実行する（2026-08-17実施。`mt5/Include/Strategy/TrendFollowingStrategy.mqh`（`IsTrendStillValid`が`signal_exit_check_trend`/`signal_exit_check_h1_adx`/`signal_exit_check_h4_adx`の3つの粒度別トグルに応じて各条件を個別にon/off）・`mt5/Include/Core/Config.mqh`（同3フィールド追加、3条件すべて無効化する組み合わせは`INVALID_EVENT`扱い）・`mt5/Experts/CoreEA.mq5`・`mt5/test-config/StrategyTester-USDJPY-H1.ini`・`docs/configuration.md`を変更。決済メカニズム自体は無変更。MQL5コンパイル（9ターゲット）・7 Script Test全PASS確認済み）。

  | 判定条件 | 取引数 | PF | Sharpe | 期待利得 | EXPERT件数 | TP到達件数 | TP平均利益 | 純損益 |
  |---|---:|---:|---:|---:|---:|---:|---:|---:|
  | Trend+H1 ADX+H4 ADX（前回） | 201 | 0.87 | -1.22 | -249.82円 | 86 | 28 | 9,611円 | -50,214円 |
  | **Trend+H1 ADXのみ** | **208** | **0.89** | **-1.00** | **-211.73円** | 84 | **31** | **9,678円** | **-44,039円** |
  | Trend+H4 ADXのみ | 120 | 0.87 | -1.35 | -337.36円 | 17 | 26 | 9,526円 | -40,483円 |

  各run: `results/backtests/20260817-204940-USDJPY-H1/`(H1 ADXのみ)、`results/backtests/20260817-205208-USDJPY-H1/`(H4 ADXのみ)。前回（3条件）は`results/backtests/20260817-203110-USDJPY-H1/`を再利用。

  **評価: Trend+H1 ADXのみへ絞り込むと、3条件版よりPF(0.87→0.89)・Sharpe(-1.22→-1.00)・純損益(-50,214→-44,039円)のすべてが改善し、これまでの全Exit側施策の中で最良のPF・Sharpeを記録した**。EXPERT（早期Exit）件数は84件と3条件版（86件）とほぼ変わらず早期Exit自体の質は維持されたまま、TP到達件数が28→31件へ増加し、TP到達トレードの平均利益も9,611→9,678円へさらに改善した。これは、H4 ADXチェックがH1 ADXチェックと重複する情報（同じ趣旨のトレンド強度指標で相関が高い、エントリー側のADXスイープでも確認済みの知見）に基づき、本来ならTPへ到達していたはずのトレードの一部を不要に早期終了させていたことを示唆する。**Trend+H4 ADXのみ**の結果は対照的で、EXPERT件数がわずか17件（H4 ADX＝4時間足は変化が緩やかで早期Exitの発動機会自体が乏しい）にとどまり、真のトレード数も120件と3水準中最少。純損益の絶対額は-40,483円と最良だが、これは主にトレード数自体が少ないこと（絶対的な母数減少）による面が大きく、Sharpe(-1.35)は3水準中最悪。**結論: Trend+H1 ADXのみを新たな最良状態として採用することを推奨する**。ただしPFは0.89とまだ1未満で、収益性基準には引き続き未達。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する。ini設定はTrend+H1 ADXのみへ更新済み）
* [x] シグナル失効Exitの設計をH1 ADXとH4 ADX/Trendで差別化する（H1 ADX弱体化＝一部利確50%、Trend反転/H4 ADX弱体化＝完全決済）よう調整し、同一IS期間で再実行する（2026-08-17実施。`mt5/Include/Strategy/TrendFollowingStrategy.mqh`へ`ESignalExitAction` enum（NONE/PARTIAL/FULL）を新設し`IsTrendStillValid()`を`EvaluateSignalExit()`へ改名（戻り値bool→enum）。H1 ADX弱体化は`SIGNAL_EXIT_PARTIAL`、Trend反転・H4 ADX弱体化は`SIGNAL_EXIT_FULL`を返す。`mt5/Include/Trading/PositionManager.mqh`へ`CSignalExitVolumeRules`（Volume Step/Min考慮の決済量算出）・`ClosePartialOnSignalWeakening()`（一部利確の実行メカニズム、`CloseOnSignalInvalidation`とは独立したGlobalVariable名前空間でべき等性を担保）を新設。`mt5/Include/Core/EAController.mqh`の`EvaluateSignalInvalidationExits()`を`ESignalExitAction`に応じて完全決済/一部利確を振り分けるよう変更。`mt5/Include/Core/Config.mqh`・`mt5/Experts/CoreEA.mq5`へ`InpSignalExitPartialCloseFraction`（既定0.5）を追加。MQL5コンパイル（9ターゲット）・7 Script Test全PASS確認済み）。結果は`results/backtests/20260817-212453-USDJPY-H1/`: MT5レポートの取引数226件・約定数393件は一部利確による分割カウントのため、`trade_breakdown`でposition単位に再集計すると真のトレード数167件。純損益-51,376円、Profit Factor 0.86、Sharpe -1.26、最大連敗10件（-28,238円）。**評価: 効果は逆効果**。直前の最良状態（Trend+H1 ADXのみ・全条件完全決済、PF0.89・Sharpe-1.00・純損益-44,039円）と比較し、純損益(-7,337円悪化)・PF(-0.03)・Sharpe(-0.26)のいずれも悪化した。close_reason別では、TP到達件数は31→33件へわずかに増加したが、TP到達トレードの平均利益は9,678→8,454円へ低下しており、部分利確でTP到達前に一部利益を早期確定してしまう効果（過去に試した「部分利確@1.0R」と同種のTP希薄化）が再発している。真のトレード数も167件（H1のみ完全決済版の208件より少ない）で、一部利確では1回のイベントで口座資金の半分しか解放されないため資金回転が鈍った可能性がある。**H1 ADXを一部利確、Trend/H4 ADXを完全決済とするハイブリッド設計は、H1 ADXも含め全条件を完全決済とする現行の最良状態（Trend+H1 ADXのみ、`20260817-204940-USDJPY-H1/`）に劣り、推奨しない**。次の一手候補: (a) 一部利確を撤回しTrend+H1 ADXのみ・全条件完全決済へ差し戻す（推奨）、(b) 一部利確の割合を縮小（例: 25%）して再試行する、(c) 別のレバーへ切り替える。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] SL/TPの算出方式を確認したうえで、SLのATR倍率(`InpStopAtrMultiple`)とTP/SL比(`InpRiskRewardRatio`)をスイープし、同一IS期間で再実行する（2026-08-17実施。**前提確認**: エントリー時のSL/TPは初期実装（Initial commit）の時点から`stop_distance=atr*InpStopAtrMultiple`（SL）/`stop_distance*InpRiskRewardRatio`（TP）というATRベースの計算式であり、固定pips方式は存在しなかった。ユーザーへ確認のうえ、既存パラメータ値自体のスイープとして実施。**前段の撤回**: 直前の一部利確ハイブリッド設計（`20260817-212453-USDJPY-H1/`、「推奨しない」と結論済み）を、`mt5/Include/Strategy/TrendFollowingStrategy.mqh`の`ESignalExitAction` enum・`EvaluateSignalExit()`を削除し`IsTrendStillValid()`（bool返却）へ復元、`mt5/Include/Trading/PositionManager.mqh`から`CSignalExitVolumeRules`・`ClosePartialOnSignalWeakening()`を削除、`mt5/Include/Core/EAController.mqh`・`Config.mqh`・`CoreEA.mq5`から関連コードを除去する形で完全に差し戻した。差し戻し後の確認実行（`results/backtests/20260817-214400-USDJPY-H1/`）は既知の最良状態`20260817-204940-USDJPY-H1`（純損益-44,039円・PF0.89・Sharpe-1.00・取引数208）とすべての指標が完全一致し、退行がないことを確認済み。MQL5コンパイル（9ターゲット）・7 Script Test全PASS確認済み。

  この最良状態（Trend+H1 ADXのみ・全条件完全決済、建値ストップ・シグナル失効Exit有効）を固定した上で、`InpStopAtrMultiple`（RR=2.0固定）と`InpRiskRewardRatio`（StopAtrMultiple=2.0固定）を独立にスイープした。

  | InpStopAtrMultiple | 純損益 | PF | Sharpe | 期待利得 | 取引数 |
  |---|---:|---:|---:|---:|---:|
  | 1.0 | -88,827円 | 0.72 | -5.00 | -734.11円 | 121 |
  | 1.25 | -67,214円 | 0.83 | -2.61 | -417.48円 | 161 |
  | **1.5** | **-33,483円** | **0.91** | -1.21 | -213.27円 | 157 |
  | 1.75 | -55,736円 | 0.88 | -1.30 | -264.15円 | 211 |
  | 2.0（基準・現行値） | -44,039円 | 0.89 | **-1.00** | **-211.73円** | 208 |
  | 2.5 | -60,194円 | 0.84 | -1.39 | -300.97円 | 200 |
  | 3.0 | -65,878円 | 0.79 | -1.69 | -359.99円 | 183 |

  | InpRiskRewardRatio | 純損益 | PF | Sharpe | 期待利得 | 取引数 |
  |---|---:|---:|---:|---:|---:|
  | 1.5 | -59,301円 | 0.88 | -1.40 | -252.34円 | 235 |
  | 2.0（基準・現行値） | **-44,039円** | **0.89** | -1.00 | -211.73円 | 208 |
  | 2.5 | -51,984円 | 0.87 | -1.14 | -265.22円 | 196 |
  | 3.0 | -44,293円 | 0.88 | **-0.97** | -236.86円 | 187 |

  各run: `results/backtests/20260817-214808/215752/215151/215943/215340/215538-USDJPY-H1/`（StopAtrMultiple軸）、`results/backtests/20260817-220201/220357/220556-USDJPY-H1/`（RiskRewardRatio軸）。

  **RiskRewardRatioは滑らかで安定**: RR=2.0が純損益・PFで最良、RR=3.0がSharpeでわずかに上回るが僅差であり、隣接水準間で単調に近い変化を示す（エントリー側の過去のRRスイープでも2.0付近が山の頂点と確認済み）。**現行のRR=2.0を維持することを推奨する**。

  **StopAtrMultipleは非単調でギザギザしている**: StopAtrMultiple=1.5が純損益・PFで唯一現行値(2.0)を上回るが、その両隣（1.25は-67,214円・PF0.83、1.75は-55,736円・PF0.88）はいずれも現行値より悪化しており、滑らかな山を形成していない。`trade_breakdown`で1.5と2.0(基準)のclose_reason内訳を比較すると、EXPERT（シグナル失効Exit）件数が84件→33件へ大きく減少する一方、SL件数(93→92)・TP件数(31→32)・TP平均利益(9,678→9,931円)はほぼ変わらず、純損益改善の大半はEXPERT決済の減少（早期Exitが発動する前にSL/TPへ先に到達するケースが増えた）で説明できる。`InpMaxOpenPositions=1`の単一ポジション制約下ではSL距離の微小な変更が個々の決済タイミングを通じて以降のトレード系列全体を分岐させるため（経路依存性）、この1.5での改善が構造的に頑健な効果なのか、本IS期間固有の偶然の系列一致なのかをIS内の指標だけでは判別できない。**総合評価: RR=2.0は現行値の維持を推奨。StopAtrMultipleの1.5は魅力的だが、隣接水準での非単調な挙動は本IS期間への過学習リスクを示唆するため、DEC-024/025のIS/OOS分離方針に基づき、IS単体の結果だけで現行値(2.0)から1.5へ変更することは推奨しない**。次の一手候補: (a) 現行値(StopAtrMultiple=2.0, RiskRewardRatio=2.0)を維持し次のレバーへ進む（推奨）、(b) StopAtrMultiple=1.5をWalk Forward評価の対象候補として記録しておき、Walk Forward各Foldで頑健性を確認する、(c) 別のレバーへ切り替える。ini設定はStopAtrMultiple=2.0・RiskRewardRatio=2.0（現行値）へ復元済み。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] 実装済みの時間切れ決済（Time Stop）ロジックを有効化し、同一IS期間で再実行する（2026-08-17実施。ロジック自体はユーザーにより作業ツリーへ既に実装済み（`mt5/Include/Trading/PositionManager.mqh`の`CTimeStopRules`/`CTimeStopTracker`/`CloseOnTimeStop`、`mt5/Include/Core/EAController.mqh`の`EvaluateTimeStopExits()`、`mt5/Include/Core/Config.mqh`・`mt5/Experts/CoreEA.mq5`の`InpEnableTimeStop`/`InpMaxHoldingBars`（既定20）/`InpTimeStopRequireMinMfe`/`InpTimeStopMinMfeR`（既定0.5R）、`mt5/Tests/TestTradingRules.mq5`の単体テスト9件）で、本セッションでの新規実装ではない。Entry後の経過H1確定足数が`InpMaxHoldingBars`を超えたら、`InpTimeStopRequireMinMfe=true`の場合は保有中の含み益ピーク（peak favorable price）が「建値〜当初SL距離」の`InpTimeStopMinMfeR`倍に到達済みなら見送り（通常のSL/TP/建値ストップ/シグナル失効Exitへ委ねる）、未到達なら市場成行で決済する。既存ポジション監視の一部としてシグナル失効Exitの直後・新規候補評価より前に実行される。コンパイル（9ターゲット）・7 Script Test全PASS確認済みのうえ、既知の最良状態（Trend+H1 ADXのみ全条件完全決済・建値ストップ・StopAtrMultiple/RR=2.0、`20260817-214400-USDJPY-H1/`）へ`InpEnableTimeStop=true`のみを追加して初めて有効化・実行）。結果は`results/backtests/20260817-232606-USDJPY-H1/`: 取引数209、純損益-48,223円、Profit Factor 0.89、Sharpe -1.10、期待利得-230.73円。**評価: ベースライン（純損益-44,039円・PF0.89・Sharpe-1.00・取引数208）と比較し、PFは同水準だが純損益(-4,184円悪化)・Sharpe(-0.10悪化)・期待利得(-230.73→-211.73円から悪化)といずれもわずかに悪化した**。決済コメント（`TIMESTOP_*`/`SIGNAL_*`）を集計したところ、Time Stopが実際の決済トリガーとなったのは209件中わずか**2件**（`MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED`）のみで、既存のシグナル失効Exit（`SIGNAL_ADX_TOO_LOW`は166→164件、`SIGNAL_TREND_REVERSED`は2件のまま）とほぼ完全に重複する領域でわずかに競合しているに過ぎない。`trade_breakdown`のclose_reason別内訳では、TP件数・平均利益（31件・9,678円）はベースラインと完全一致、EXPERT（早期Exit合計）も84件で同数（純損益はわずかに改善: -7,472→-6,982円）だが、SL件数が93→94件へ1件増加し純損益が-336,593→-341,267円へ悪化しており、これが全体の悪化の主因である。この1件の差はTime Stop自体が直接発生させたものではなく、`InpMaxOpenPositions=1`の単一ポジション制約下で決済タイミングが1〜2件シフトしたことによる以降のトレード系列全体の分岐（経路依存性、`InpStopAtrMultiple`スイープで観測したのと同種の現象）に起因すると考えられる。**総合評価: 現行既定値（MaxHoldingBars=20時間、最低MFE 0.5R要求）ではTime Stopはほぼ発動せず（209件中2件）、既存のシグナル失効Exitとほぼ完全に重複しており独自の効果を発揮していない。効果は軽微だがマイナス**。次の一手候補: (a) Time Stopを無効化し既知の最良状態（`20260817-214400-USDJPY-H1/`、PF0.89・Sharpe-1.00・純損益-44,039円）へ差し戻す、(b) MaxHoldingBarsをより大きな値（例: 48/72/100時間）へ引き上げ、シグナル失効Exitでは捕捉できない「方向感なく長期間停滞したポジション」という異なる失敗モードを狙う、(c) 最低MFE要求(`InpTimeStopRequireMinMfe`)を外し無条件の時間切れ決済を試す。当初はini設定をfalseへ戻したが、**ユーザー指示によりTime Stopを既定で有効化する方針へ変更**（2026-08-17）。`mt5/Include/Core/Config.mqh`の`SetDefaultConfig`（`enable_time_stop`をfalse→true）・`mt5/Experts/CoreEA.mq5`の`InpEnableTimeStop`既定値（false→true）・`mt5/test-config/StrategyTester-USDJPY-H1.ini`（`InpEnableTimeStop=true`）を変更。コンパイル（9ターゲット）・7 Script Test全PASS確認済み。本IS期間の実測（純損益-4,184円・Sharpe-0.10、いずれもわずかに悪化）はポジションが無期限に保有され続けることを防ぐセーフティネットとしての価値とは別軸の判断であり、ユーザーは収益性指標の悪化を把握したうえでリスク管理方針として有効化を採用した。ini設定に変更はなく既に実行済みの`20260817-232606-USDJPY-H1/`がこの方針での結果に相当するため、追加のバックテストは実施していない。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] Buy/Sell別・時間帯別・曜日別・相場レジーム別で勝率の有意差を分析する（2026-08-17実施。`20260817-232606-USDJPY-H1/`（現行方針状態: Trend+H1 ADXのみ全条件完全決済・建値ストップ・Time Stop有効、取引数209）の`trade_breakdown`をカイ二乗検定＋Fisher正確検定（多重比較はBonferroni補正）で検証。**Buy/Sell**: BUY 133件36.8% vs SELL 76件27.6%、χ²検定p=0.23で有意差なし。**時間帯**: NewYork 54件48.1%が最高、London 45件24.4%が最低（χ²検定p=0.06で全体は有意水準未達）。NewYork vs London（p=0.02）・NewYork vs Tokyo（p=0.04）は補正前なら有意水準0.05未満だが、6ペア比較のBonferroni補正後閾値(0.0083)はいずれも下回らず統計的に頑健な差ではない。**曜日**: Tue 49件42.9%が最高だが全ペアで補正前p値も0.05を上回り有意差なし（χ²検定p=0.56）。

  **相場レジーム別の分析中、`market_regime_trend`/`market_regime_volatility`のbreakdownが常に空配列になるバグを発見**。原因調査の結果、監査ログの相関ID(`trade_candidate_id`、`'{ea_id}-{symbol}-{unix_time}'`形式・本EA/銘柄では34文字)が`mt5/Include/Trading/OrderManager.mqh::Submit()`でMQL5のDeal Comment上限31文字により末尾3文字（timestamp下3桁）が切り捨てられ格納されていたため、CANDIDATE/RISK_DECISION監査イベント（切り捨てなしの完全なIDを記録）と、`mt5/Include/Core/EAController.mqh::CandidateForPosition()`がDeal Commentから復元してTRADE_CLOSED等へ使う相関IDが常に不一致となり、`python/analysis/trade_breakdown.py`でのCANDIDATE由来フィールド（`entry_atr`/`entry_adx`/`market_regime_trend`/`market_regime_volatility`/`atr_band`/`adx_band`）とRISK_DECISION由来フィールド（`risk_budget`）のマージが恒常的に失敗していたことが判明（本セッションを含むこれまでの全実行で発生していた不具合）。close_reason・giveback・MFE/MAE等（TRADE_CLOSED/TRADE_ANALYTICS由来で、いずれもCandidateForPosition経由の同一の（誤っていたが内部的には一貫した）IDを使うため相互には整合していた）は影響を受けておらず、これまで報告した分析結果は無効ではない。

  **修正**: `mt5/Include/Trading/OrderManager.mqh`のDeal Commentを、切り捨てられうる完全な`trade_candidate_id`ではなく一意性を持つentry_bar時刻のみ（`IntegerToString(signal.signal_bar_time)`、最大10桁で31文字制限内）を格納するよう変更。`mt5/Include/Core/EAController.mqh::CandidateForPosition()`を、復元したentry_bar時刻から`StringFormat("%s-%s-%s",ea_id,symbol,comment)`でCANDIDATE/RISK_DECISIONと同じ完全な形式のIDを再構築するよう変更。取引実行・SL/TP・リスク判断には一切影響しない監査ログ専用の修正。コンパイル（9ターゲット）・7 Script Test全PASS確認済み。修正後に再実行（`results/backtests/20260817-235122-USDJPY-H1/`）し、修正前run（`20260817-232606-USDJPY-H1/`）と純損益・PF・Sharpe・取引数が完全一致することを確認、取引挙動に影響がないことを検証済み。

  修正後の相場レジーム別分析（取引数209）: **market_regime_trend**（TrendDown 97件32.0% vs TrendUp 112件34.8%、χ²検定p=0.77）、**market_regime_volatility**（HighVolatility 20件25.0%・LowVolatility 10件30.0%・NormalVolatility 179件34.6%、χ²検定p=0.67、High/Lowはサンプル数が少なく検出力不足）のいずれも有意差なし。副産物として同時に修正された**atr_band**（χ²検定p=0.63）・**adx_band**（χ²検定p=0.14、ADX高帯ほど勝率が高い傾向は見えるが有意水準未達）も有意差なし。

  **総合評価: Buy/Sell・時間帯・曜日・相場レジーム（トレンド/ボラティリティ）・ATR帯・ADX帯のいずれの区分でも統計的に有意な勝率差は確認できなかった**。209件を4〜5分割した各グループ（10〜179件）では検出力が不足しており、原因分析・改善案の提示は見送る（有意でない差に因果ストーリーを組み立てると根拠のない仮説になるため）。NewYorkセッションの勝率がやや高い傾向（補正前pのみ有意水準未満）は仮説として記録するが、DEC-024/025のIS/OOS分離方針に基づき、この単一IS期間・209件のデータだけでフィルタ実装等の判断は行わない。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] **単一条件の閾値調整（PF0.88〜0.89付近で頭打ち）から脱却するため、Entry判定を「Market Regime→HTF Bias→Setup→Entry Trigger→Entry」の段階的構造へ再設計する（ユーザー依頼、2026-08-22実施）。** 既存の`CTrendFollowingStrategy::Evaluate()`は実質的に同じ順序で判定していたが、各段階の合否がログへ残らず、既存の`CMarketRegimeClassifier`（分析専用）がEntry判定に未使用だった。新規input `InpEntryUseStagedPipeline`（既定値`false`）で既存方式と切替可能にし、`false`の間は既存方式と判定式・発注挙動が完全に同一であることを、コード変更前後のStrategy Tester再実行（同一IS期間2017-09-01〜2020-12-31、`results/backtests/20260822-171514-USDJPY-H1/`=変更前コード、`results/backtests/20260822-170849-USDJPY-H1/`=変更後コード）で実証した（総損益-48,223円・PF0.89・Sharpe-1.10・取引数209で完全一致、既存の最良状態`20260817-232606-USDJPY-H1/`とも一致）。`InpEntryUseStagedPipeline=true`（`InpEntryRequireMarketRegimeTrend`既定値`true`）にすると、Market RegimeがRange/Unknownの確定足を追加棄却するが、`InpRegimeTrendAdxMin`と既存`InpMinimumAdx`が既定値でともに20.0のため、既定設定では新設ゲートが既存のADX下限フィルタと完全に重複し、最終的な採用/棄却集合・収益指標は変化しないことを実測確認した（`results/backtests/20260822-171814-USDJPY-H1/`、同一の209件・PF0.89・Sharpe-1.10）。Setup/Trigger分離（`CTrendFollowingRules::IsPullbackSetup`/`IsPullbackTrigger`、`IsPullback`はその合成として再定義、数式は変更前と等価）・新規監査イベント`ENTRY_PIPELINE`（`InpEntryUseStagedPipeline=true`時のみ、毎確定足の成立/否決とStage別理由を記録）・`python.analysis.trade_breakdown.entry_pipeline_funnel_summary()`（Stage別棄却件数集計）を追加した。変更ファイル: `mt5/Include/Signal/SignalResult.mqh`・`mt5/Include/Strategy/TrendFollowingRules.mqh`・`mt5/Include/Strategy/TrendFollowingStrategy.mqh`・`mt5/Include/Core/Config.mqh`・`mt5/Include/Core/EAController.mqh`・`mt5/Include/Logging/TradeLogger.mqh`・`mt5/Experts/CoreEA.mq5`・`mt5/Tests/TestTrendFollowingRules.mq5`・`python/analysis/trade_breakdown.py`・`python/analysis/reports.py`・`python/tests/test_trade_breakdown.py`・`contracts/trade-breakdown-report.schema.json`・`docs/configuration.md`・`docs/backtesting.md`。設計判断の詳細は`DECISIONS.md` DEC-027参照。副産物として、`CTradeLogRules::SafeEventType`（`mt5/Include/Logging/TradeLogger.mqh`）に`TIME_STOP_EXIT`が含まれておらず、`InpEnableTimeStop=true`でTime Stop決済が発生してもTIME_STOP_EXIT監査イベントが一度も書き込まれていなかった既存不具合（Python側`reports.py`は当初からTIME_STOP_EXITに対応済みで、MQL5側だけが書き込みを拒否していた）を発見・修正した（修正前0件→修正後1件以上のイベント記録を確認）。MQL5コンパイル（9ターゲット、0 errors/0 warnings）・8 Script Test全PASS（`TestMarketRegimeClassifier`・`TestDecisionApiRules`はTerminal Exit Code 1の既知事象のみ、PASSマーカー・アサーションは全成功）・Python単体テスト97件全PASS（新規4件を含む）で検証済み。**未検証・残存事項**: `InpEntryUseStagedPipeline=true`にした場合の実際の収益性改善効果（Market Regime方向性一致条件を含む拡張の要否）はOOS期間（2021-01〜2024-12）を含め未検証。DEC-024/025のIS/OOS分離方針に従い、方針が固まった上でOOS検証は一度だけ行う。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
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
