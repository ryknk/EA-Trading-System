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
* [x] 段階的Entry判定パイプライン（`InpEntryUseStagedPipeline`）を有効化し、同一IS期間で再実行する（2026-08-22実施。ロジック自体はユーザーにより作業ツリーへ既に実装済み（`mt5/Include/Strategy/TrendFollowingStrategy.mqh`のStage 1 Market Regime→Stage 2 Higher Timeframe Bias→Stage 3 Setup→Stage 4 Entry Trigger構成、`mt5/Include/Core/EAController.mqh`の`ENTRY_PIPELINE`診断監査イベント、`mt5/Include/Core/Config.mqh`・`mt5/Experts/CoreEA.mq5`の`InpEntryUseStagedPipeline`/`InpEntryRequireMarketRegimeTrend`（既定false/true））で、本セッションでの新規実装ではない。Stage 1は市場レジーム判定（`CMarketRegimeClassifier::ClassifyTrend`、既存の分析専用ロジックを流用）がRange/Unknownの場合に`REGIME_NOT_TRENDING`で候補を棄却する新規のEntry拒否ゲート。コンパイル（9ターゲット）・7 Script Test全PASS確認済みのうえ、既知の最良状態（`20260817-235122-USDJPY-H1/`）へ`InpEntryUseStagedPipeline=true`のみを追加して初めて有効化・実行）。結果は`results/backtests/20260822-174935-USDJPY-H1/`: 純損益-48,223円、PF0.89、Sharpe-1.10、取引数209——**ベースラインと純損益・PF・Sharpe・取引数・Long/Short内訳のすべてが完全一致**。

  **評価: 現状は完全なno-op**。有効化のみで記録される`ENTRY_PIPELINE`診断ログ（全20,762確定足）を集計すると、Stage 1の`REGIME_NOT_TRENDING`は3,902件で最頻の棄却理由だったが、最終的なCandidate成立件数（`CANDIDATE`監査イベント、1,303件）はベースラインと完全一致しており、Stage 1が棄却した3,902件はいずれも、Stage 1が無くても後段のゲートで棄却されていたことを意味する。**根本原因は設定値の重複**: `CMarketRegimeClassifier::ClassifyTrend`は`adx<trend_adx_min`で即Range判定するが、`InpRegimeTrendAdxMin`の既定値(20.0)は`InpMinimumAdx`（Stage 2以降の`ADX_TOO_LOW`ゲートの閾値）の既定値と完全に同一かつ同じH1 ADX値を参照するため、Stage 1のADXによるRange判定はStage 2の`ADX_TOO_LOW`ゲートの数学的な部分集合になっている（`adx<20`で棄却される候補は両ゲートで必ず棄却され、Stage 1が単独で追加棄却する候補は存在しない）。**総合評価: 段階的Entry判定パイプラインを既定値のまま有効化しても実質的な効果はなく、純損益・PF・Sharpeいずれも改善も悪化もしていない**。次の一手候補: (a) `InpRegimeTrendAdxMin`を`InpMinimumAdx`より高い値（例: 25/30）に設定しStage 1が真に追加的な閾値として機能するようにする、(b) Stage 1のRange判定にADX以外の要素（H1 EMA Slopeの方向一致等）の寄与を強める、(c) 現状維持のまま無効化に戻す（追加の監査ログ量増加を避けるため）。ini設定は`InpEntryUseStagedPipeline=true`のまま維持（ユーザーからの追加指示待ち）。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] **重大: 監査ログ（audit-\*.jsonl）が複数回のStrategy Tester実行間で累積し、`trade_breakdown`等の深掘り分析が他run混入データで汚染されるバグを発見・修正**（2026-08-22実施。`InpRegimeTrendAdxMin`スイープ40の`trade_breakdown`深掘り中に、`ENTRY_PIPELINE`の`REGIME_NOT_TRENDING`件数が直前のADX=20 no-op runと同一の3,902件になっている不審な一致に気づき調査。原因: `mt5/Include/Logging/TradeLogger.mqh`のAudit書き込みは`FileOpen(...,FILE_READ|FILE_WRITE|...)`＋`FileSeek(handle,0,SEEK_END)`による意図的な追記方式（本番運用でのEA再起動時に監査証跡を失わないための正しい設計）だが、Strategy Testerが実行間で同一のTester Agentフォルダ（`%APPDATA%\MetaQuotes\Tester\<TerminalID>\Agent-127.0.0.1-3000\MQL5\Files\EaTradingSystem\Audit\`）を使い回すため、`tools/run-strategy-tester.ps1`が実行前にこのディレクトリをクリアしていないと、同一カレンダー日付のJSONLファイルへ複数run分のイベントが積み重なる。`TRADE_CLOSED`のタイムスタンプ範囲を検証したところ、本セッションの複数の過去run（`20260817-214400-USDJPY-H1/`等、直近のADXスイープに限らない）でも、取引数はMT5 .htmレポートと偶然一致していたにもかかわらず、最終タイムスタンプがIS期間終了(2020-12-31)ではなく2019年前半で止まっており、同種の汚染が存在していたことを確認した。**影響範囲**: MT5 Tester自身が生成する.htmレポートのヘッドライン指標（純損益・PF・Sharpe・取引数、run固有のファイル名で生成されるため汚染の影響を受けない）に基づくこれまでの全評価・意思決定は有効。一方、`python/analysis/trade_breakdown.py`による深掘り分析（close_reason内訳、Buy/Sell・時間帯・曜日・相場レジーム別、Giveback、保有時間帯等）は、汚染された監査ログに基づいていた期間について**再検証が必要**（本セッションの範囲では確認できる限り遡って影響がある可能性が高いが、どのroundがどの程度汚染されていたかは個別に検証しない限り不明）。**修正**: `tools/run-strategy-tester.ps1`のStrategy Tester起動前に、既存の`audit-*.jsonl`を削除するクリーンアップ処理を追加。修正後、`InpRegimeTrendAdxMin=40`runを再実行し、`TRADE_CLOSED`のタイムスタンプ範囲がIS全期間(2017-09-07〜2020-12-16)に及び、件数が.htmレポートの77件と一致することを確認した（`results/backtests/20260822-183152-USDJPY-H1/`）。取引実行・SL/TP・リスク判断のロジックには一切変更なし（純粋なテストツールの不具合）。**ユーザーへの報告事項**: 本セッションでこれまで報告したBuy/Sell・時間帯・曜日・相場レジーム別の有意差分析、close_reason別の詳細内訳等、`trade_breakdown`に基づく分析結果は、対象runの監査ログが汚染されていた可能性があり、厳密には未確認として扱うべき。再検証が必要な場合はユーザーの指示により個別のrunを再実行して確認する。）

* [x] `InpEntryUseStagedPipeline=true`のうえで`InpRegimeTrendAdxMin`を`InpMinimumAdx`(20)より高い値でスイープする（2026-08-22実施。25/30/35/40/45/50の6水準で同一IS期間を再実行。コード変更なし、iniの`InpRegimeTrendAdxMin`のみ変更）。

  | InpRegimeTrendAdxMin | 純損益 | PF | Sharpe | 取引数 | 最大DD |
  |---|---:|---:|---:|---:|---:|
  | 20（基準・no-op、`20260822-174935`） | -48,223円 | 0.89 | -1.10 | 209 | 10% |
  | 25（`20260822-180615`） | -52,229円 | 0.86 | -1.20 | 185 | 10% |
  | 30（`20260822-181010`） | -87,400円 | 0.78 | -2.15 | 169 | 10% |
  | 35（`20260822-181359`） | -47,578円 | 0.86 | -1.48 | 135 | 7% |
  | **40（`20260822-183152`、監査ログ修正後に再検証済み）** | **+15,511円** | **1.09** | **+0.80** | 77 | 3% |
  | 45（`20260822-182133`） | -31,697円 | 0.73 | -2.89 | 44 | 6% |
  | 50（`20260822-182459`） | +5,352円 | 1.12 | +0.80 | 18 | 2% |

  **評価: `InpRegimeTrendAdxMin=40`が本セッション探索全体を通じて初めてPF>1・Sharpe>0を達成した**。`trade_breakdown`（監査ログ汚染修正後の`20260822-183152`で検証、position単位77件がMT5レポートと一致）による内訳: TP到達19件（構成比24.7%、既存ベースラインの14.9%より高い）・SL45件（構成比58.4%）・EXPERT（早期Exit）13件が純利益+7,529円・勝率53.8%・PF2.05——**EXPERTクローズが明確な純プラスとなったのは本セッションの全Exit側施策を通じて初めて**。強いトレンド局面（ADX≥40）に絞ることで、大きな値幅を捉えやすくなっている可能性がある。

  一方、**35→40→45→50の推移が非単調**（35:PF0.86→40:PF1.09で改善→45:PF0.73へ急悪化→50:PF1.12で再び改善）であり、本IS期間固有のノイズへの過学習リスクを強く示唆する。取引数も209→77（40）→18（50）と閾値上昇に伴い急減しており、50はサンプル数不足（18件）で統計的な意味を持たない。40（n=77）は本スイープの中では相対的にサンプル数が確保されているが、それでも小さい部類である。

  **総合評価: `InpRegimeTrendAdxMin=40`は本セッション最有力の候補だが、非単調な挙動とサンプル数の少なさから、IS単体の結果だけでの採用は推奨しない（DEC-024/025のIS/OOS分離方針）**。次の一手候補: (a) `InpRegimeTrendAdxMin=40`をWalk Forward評価の最優先候補として記録する（推奨）、(b) 40付近をさらに細かく（37/38/39/41/42等）スイープし単調性を確認する、(c) 現状維持（no-op状態）に戻す。ini設定は`InpRegimeTrendAdxMin=40`のまま維持（ユーザーからの追加指示待ち）。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] Walk Forward各Fold（年次: 2021/2022/2023/2024、DEC-024のOOS/Walk Forward評価期間を年次分割）を実行する（2026-08-23実施、ユーザー依頼）。rule-based Strategyには学習ステップがないため、凍結済みIS最良パラメータセット（`InpRegimeTrendAdxMin=40`、`InpEntryUseStagedPipeline=true`、他は2026-08-22 IS凍結時点の設定のまま）を各年に固定で適用しStrategy Testerを実行した（学習を伴うWalk Forward評価は3.3節のML評価タスクで別途実施する）。各Foldは独立したTester実行（`InpTesterResetPersistentState=true`により口座残高100万円・永続状態とも年初にリセット）。監査JSONLから`python/analysis/reports.py`で機械的にPF/Sharpe/純損益等を算出（既存run-metadataのMT5レポート値と算出方法をそろえるため、継続run（2021-2024通し）も同じ手法で再計算した）。

  **年次Fold結果**:

  | Fold | 取引数 | 純損益 | PF | Sharpe | 勝率 | 最大DD |
  |---|---|---|---|---|---|---|
  | 2021 | 28 | +13,995円 | 1.22 | +0.42 | 39.3% | 32,871円(3.24%) |
  | 2022 | 30 | +11,866円 | 1.21 | +0.10 | 50.0% | 28,558円(2.86%) |
  | 2023 | 21 | +6,224円 | 1.15 | +0.24 | 33.3% | 27,779円(2.76%) |
  | 2024 | 25 | -19,124円 | 0.68 | -0.84 | 32.0% | 32,708円(3.27%) |
  | Fold合計 | 104 | +12,961円 | — | — | — | — |
  | 継続run（2021-01〜2024-12通し実行、参考） | 105 | +5,294円 | 1.02 | +0.06 | 39.0% | 38,842円 |

  **年次不安定性（重大な懸念）**: PFが2021→2022→2023→2024で1.22→1.21→1.15→0.68と単調に悪化し、2024年は唯一の明確な負け年（Sharpe-0.84、期待値-765円/取引）。TP到達率（close_reason=TP/取引数）も28.6%→23.3%→23.8%→16.0%と同様に単調減少しており（`SL`はいずれの年も14〜18件と大きく変わらない）、単年の偶然ではなく複数年にわたる緩やかな劣化トレンドとして観測される。

  **方向別内訳（2024年に構造変化）**: 2021〜2023年はいずれもBUYが主たる利益源（2021: BUY+19,374円/SELL-5,379円、2022: BUY+5,002円/SELL+6,864円、2023: BUY+20,129円/SELL-13,905円）だったが、2024年は**BUY自体が-14,871円と初めて負け**、SELLも-4,253円で両建てで損失（全期間OOS内訳で確認済みのBUY優位・SELL劣位という構造が2024年に崩れている）。USDJPYは2024年半ばに大幅な急落・乱高下（実勢相場のトレンド反転）を経験しており、これが本戦略のトレンドフォロー前提（ADX高水準＝強いトレンド継続を期待）と整合しない値動きだった可能性がある。

  **継続run vs Fold合計の乖離（手法上の重要な発見）**: 年次Foldを独立に実行し合算した純損益（+12,961円）は、同一パラメータで2021-2024を通しで1回実行した場合の純損益（+5,294円）の2倍以上に達する。取引数はほぼ同数（104 vs 105）であるため、実際に発生した取引自体はほぼ同じだが、各取引のロットサイズ（残高に対するリスク%ベース）が異なる。年次Foldは各年とも口座残高100万円からの再スタートのため、2021〜2023年の含み益を2024年へ引き継がない。継続runでは2021〜2023年の利益で残高が増加した状態で2024年の損失局面を迎えるため、より大きいロットで損失を出し、同じ取引系列でも損益が悪化する。**これは実運用（残高は継続的に変動する）に近い挙動は継続runの方であり、年次Fold合算の+12,961円は実態より楽観的な数字である**。複利効果と「利益が出た後に悪い年が来る」経路依存性が、本パラメータセットのリスクをFold単体の平均像より深刻に見せる。

  **総合評価: Walk Forwardの結果は、IS期間で唯一PF>1を達成した`InpRegimeTrendAdxMin=40`構成が、OOS期間の前半（2021-2023、PF1.15〜1.22）ではおおむね頑健だったものの、直近の2024年で明確に破綻していることを示している。DEC-024/025のIS/OOS分離方針により、本結果を理由とした現IS期間（2017-09〜2020-12）パラメータの再チューニングは行わない。** 残存リスクと次のIS改訂時の調整案は本回答の対話メッセージを参照（`git`未コミットのため、対応方針が固まるまでcommitは保留する）。

## 2.1.1 ローリングWalk Forward検証（新規、2026-08-23ユーザー指定）

過去データで作った戦略が直後の未知データでも機能するかを検証するため、3年学習→1年検証を1年ずつロールする方式（Train2016-2018→Test2019、…、Train2021-2023→Test2024の6Fold）を新規に開始する。ユーザーとの事前合意事項:

* 2021-2024を含むFoldのTest結果は、本セッションで既にOOS/年次Foldとして一度観測済みのため、厳密な意味でのブラインド検証ではない（データ汚染は解消できない、既知の限界として記録）。真にブラインドなのは2025-01〜2026-08のFinal Holdoutのみ。
* 各Foldの「Train」は当初EA既定値から開始する方針だったが、**2026-08-23にユーザー指定で方針変更: 凍結済みIS最良パラメータセット（`InpRegimeTrendAdxMin=40`・`InpEntryUseStagedPipeline=true`等、`mt5/test-config/StrategyTester-USDJPY-H1.ini`のまま）をベースに適用し、そこから調整する方針とする。** 既定値ベースラインの`mt5/test-config/StrategyTester-USDJPY-H1-wfo-baseline.ini`と`tools/run-strategy-tester.ps1`の`-Template`引数は、比較用の参考記録として残す。
* **重要な限界（2026-08-23確認）**: 凍結IS最良パラメータセットは、元々IS期間全体（2017-09〜2020-12）を使って調整されたものである。したがってTrain区間が2017-09〜2020-12の部分区間となるFold1・Fold2（Test=2019・2020）は、「既知のパラメータを既知のデータの一部で再確認」しているに過ぎず、Testもその元のIS期間内（2019・2020）に含まれるため真のブラインド検証にならない。Fold3以降（Train開始が2018-01以降でTestが2021年以降）から初めて、元のIS期間外のデータに対する検証となる。

* [x] Fold1のTrain区間でStrategy Testerを実行する（2026-08-23実施）。当初ユーザー指定のTrain=2016-2018はDEC-025の制約（USDJPY_HISTのD1/H4インジケーターウォームアップに実データ最古日2016-08-31から約9〜10か月のバッファが必要で、不足するとテスト実行中も指標が回復しない）に抵触し、`results/backtests/20260823-125642-USDJPY-H1/`で取引0件・`SIGNAL_ERROR code=MARKET_DATA_UNAVAILABLE` 14,365件（実行全期間にわたって回復せず）という既知の異常パターンを再現した。ユーザーへ確認の上、**Fold1のみTrain開始日を2017-09-01へ補正**（Train=2017-09〜2018-12、約16か月、他Foldより短い。Fold2以降はTrain開始が元々2017-01・2018-01…であり、Fold2（2017-2019）も同様に2017-09-01へ補正が必要、Fold3以降（2018-01開始）は補正不要）、Test年（2019〜2024）は元の表を維持する方針で合意した。補正後、EA既定値ベースライン（`results/backtests/20260823-130244-USDJPY-H1/`）で取引数171・純損益-7,755円・PF0.98・Sharpe-0.07を確認したが、ユーザー指定により凍結IS最良パラメータセットを適用する方針へ変更し、同一Train区間（2017-09-01〜2018-12-27実績）で再実行（`results/backtests/20260823-131654-USDJPY-H1/`）: 取引数36・純損益+10,065円・PF1.12・Sharpe+0.27・勝率41.7%・最大DD21,309円(2.08%)。既定値ベースラインより明確に良好だが、上記の限界（このTrain区間は元のIS期間の一部）を踏まえると当然の結果であり、新規の汎化性能を示すものではない。
* [x] Fold1のTrain区間（2017-09〜2018-12）内で、凍結IS最良パラメータセットをベースに`InpStopAtrMultiple`（1.5/1.75/2.0/2.25/2.5）・`InpRiskRewardRatio`（1.5/1.75/2.0）・`InpRegimeTrendAdxMin`（30/35/40/45/50）をスイープする（2026-08-23実施、ユーザー依頼）。取引数増加によるサンプル信頼性向上のため`InpMaxOpenPositions`を既定値1から**5**へ変更して全runに適用（ユーザー指定）。追加の検証値は導入せず指定範囲のみ実施（結果が非単調だったため、追加は次の一手候補として記録するに留めた）。全11通り（各レバー1軸のみ変更、他は基準値StopATR=2.0/RR=2.0/ADX=40で固定）を実行、詳細は`results/backtests/fold1-train-sweep-20260823-summary.json`参照。

  | レバー | 値 | 取引数 | 純損益 | PF | Sharpe |
  |---|---|---|---|---|---|
  | 基準値 | ATR2.0/RR2.0/ADX40 | 36 | +10,065円 | 1.12 | +0.27 |
  | StopAtrMultiple | 1.5 | 39 | **+29,140円** | **1.33** | **+0.78** |
  | StopAtrMultiple | 1.75 | 36 | +2,820円 | 1.03 | +0.09 |
  | StopAtrMultiple | 2.25 | 36 | -8,610円 | 0.89 | -0.21 |
  | StopAtrMultiple | 2.5 | 35 | -10,330円 | 0.86 | -0.28 |
  | RiskRewardRatio | 1.5 | 37 | +4,948円 | 1.06 | +0.14 |
  | RiskRewardRatio | 1.75 | 36 | +516円 | 1.01 | +0.03 |
  | RegimeTrendAdxMin | 30 | 87 | -48,328円 | 0.76 | -0.81 |
  | RegimeTrendAdxMin | 35 | 57 | -8,188円 | 0.94 | -0.15 |
  | RegimeTrendAdxMin | 45 | 15 | -11,834円 | 0.73 | -0.43 |
  | RegimeTrendAdxMin | 50 | 7 | -4,965円 | 0.80 | -0.23 |

  **`InpMaxOpenPositions=5`は本EAでは常に無効（2026-08-23、ユーザー質問を受けて根本原因を特定）**: 基準値（ATR2.0/RR2.0/ADX40, MaxOpenPositions=5）の取引数36件は、以前の同一パラメータ・`InpMaxOpenPositions=1`のrun（`20260823-131654`）と完全一致した。当初「ADX=40は候補生成頻度が低く同時保有が発生しないため」と推測したが、これは誤りだった。実際には基準値runでも`RISK_DECISION`が`DUPLICATE_POSITION`理由で12件拒否されており（ADX30では79件、ADX35では47件、ADX45では7件）、同時保有の試行自体は発生している。真因は`mt5/Include/Risk/ExposureGuard.mqh`の`Evaluate()`にある: `InpMaxOpenPositions`は`IsPositionCountAllowed(total,max_positions)`で正しく評価されるが、その直後に**同一シンボルに既存ポジションが1件でもあれば`max_positions`の値に関わらず無条件で追加を拒否する**別ルール（`reason_code=DUPLICATE_POSITION`、「Any existing position in the symbol blocks additions, preventing averaging and pyramiding.」というコメントどおり、ナンピン・ピラミッディング防止のための意図的な安全設計、`CLAUDE.md`第14節の禁止事項と一致）が存在する。本EA・本バックテストは単一シンボル（USDJPY_HIST）のみを取引するため、この同一シンボル排他ルールが実質的に同時保有数を常に1へ固定し、`InpMaxOpenPositions`を何に設定しても（1でも5でも）挙動が変わらない。**バグではなく設計どおりの安全機構だが、単一シンボル運用では`InpMaxOpenPositions`は事実上無効なパラメータであり、取引数を増やす目的では機能しない。** 取引数を増やすには、Entry条件（ADX閾値等）を緩めるほかなく、その場合はPFが悪化するトレードオフがある（本節既存の測定結果参照）。

  **`InpStopAtrMultiple=1.5`が突出（要警戒）**: PF1.33・純利益29,140円と全組み合わせ中最良だが、隣接値（1.75:PF1.03、2.0:PF1.12）に対し非単調。元のIS期間全体（2017-09〜2020-12）での過去のStopAtrMultipleスイープでも同一パターン（1.5のみ突出、1.25/1.75は悪化）が確認済みであり、本Train区間は元のIS期間の部分集合（真に独立した検証ではない）であるため、この一致は過学習リスクの再確認にとどまり新規のロバスト性の証拠にはならない。

  **`InpRegimeTrendAdxMin=40`（現行値）は本Train区間内でも最良のPF**: 30/35/45/50のいずれも下回った。ただし45（n=15）・50（n=7）はサンプル数が少なく統計的な意味を持たない。

  **`InpRiskRewardRatio`は明確な優劣なし**: 1.5/1.75/2.0いずれもPFが1.0近辺で拮抗しており、現行値2.0が3値中では最良。

  **総合評価**: 現行のADX=40・RR=2.0は本Train区間でも妥当性が確認できた（変更の根拠なし）。StopAtrMultiple=1.5は魅力的な数値だが、既知の非単調パターンの再現であり単独の根拠として採用しない。追加の調整はユーザーの評価を待つ（本節末尾の対話メッセージ参照）。

* [x] 複数ポジション保有の設計見直し（コミット`88baacb`）後、Fold1のTrain区間でATR2.0/RR2.0/ADX40を基準に新規リスクパラメータを適用し再実施する（2026-08-23実施、ユーザー依頼）。`InpRiskPerTradePercent=1.0`・`InpDailyLossLimitPercent=3.0`・`InpMaxSameDirectionPositions=2`・`InpMaxOpenRiskPercent=3.0`・`InpMinMarginLevelPercent=300.0`を適用（`InpMaxOpenPositions`はユーザー指定になかったが、`Config.mqh`のバリデーション制約`max_same_direction_positions<=max_open_positions`を満たすため2へ設定、推論による補完）。`InpMinSameDirectionEntryDistancePoints`を観測ATR（約145pt）・StopAtrMultiple=2.0時の典型SL距離（約290pt）を参考に0/50/100/200/300ptでスイープした。詳細は`results/backtests/fold1-train-multipos-sweep-20260823-summary.json`参照。

  | dist(pt) | 取引数 | 純損益 | PF | Sharpe | 最大DD率 |
  |---|---|---|---|---|---|
  | 0（距離制約は無効） | 43 | -1,630円 | 0.99 | +0.02 | 6.05% |
  | 50 | 42 | +7,232円 | 1.04 | +0.11 | 5.17% |
  | **100** | 40 | **+28,882円** | **1.16** | **+0.35** | 4.14% |
  | 200 | 37 | +17,807円 | 1.11 | +0.26 | 4.19% |
  | 300 | 36 | +17,474円 | 1.10 | +0.25 | 4.19% |
  | 参考: 見直し前（単一ポジション、RiskPerTrade0.5%） | 36 | +10,065円 | 1.12 | +0.27 | 2.08% |

  **機構の動作確認**: `MIN_ENTRY_DISTANCE`拒否件数はdist値に対し単調増加（50pt:1件→100pt:4件→200pt:9件→300pt:11件）し、監査ログで意図どおりの動作を確認した。一方`MAX_OPEN_RISK_EXCEEDED`・`MARGIN_LEVEL_TOO_LOW`は全runで一度も発火せず、`InpMaxOpenRiskPercent=3%`・`InpMinMarginLevelPercent=300%`が実際に拒否として機能することは本Train区間では未検証（コードレビューでは正しく実装されていることを確認済み）。

  **リスク量倍増との分離**: `InpRiskPerTradePercent`を0.5%→1.0%へ倍増した影響で、積み増しがほぼ発生しないdist=300（取引数36、単一ポジション基準と同数）でも$純利益・$最大DDとも基準のおよそ2倍規模（DD率2.08%→4.19%）になった。これは積み増し効果ではなくリスク量そのものを倍にした結果であり、混同しないよう分離して評価する必要がある。

  **dist=0（距離制約が無効。`docs/configuration.md`に明記のとおり、これは「制約が無効化される」既定挙動であり「積み増し無制限が有効になる」設定ではない。2026-08-23ユーザー指摘を受け訂正）は明確に悪化**（PF0.99・Sharpe+0.02、DD率6.05%）。距離制約なしでの同方向積み増しは`CLAUDE.md`が禁止する「無制限のポジション追加」に近い劣化パターンを再現しており、距離制約の必要性を裏付けた。

  **dist=100ptが本スイープ中最良**（PF1.16・Sharpe+0.35・純利益+28,882円）で、DD率（4.14%）はdist200/300とほぼ同水準ながらより高い純利益・PFを達成しており、単なるリスク量増加（dist=300で近似）を超える効果を示唆する。ただしn=40と少数であり、本Train区間内での単一の山であるため、本セッションで繰り返し確認されてきた過学習パターン（StopAtrMultiple=1.5、ADX=40等）と同様の再現性リスクに留意が必要。

  **総合評価: `InpMinSameDirectionEntryDistancePoints=100`を有力候補として記録するが、単独のTrain区間内スイープの結果であり採用は保留する。** 残存リスクと追加の調整要否はユーザーの評価を待つ（本節末尾の対話メッセージ参照）。

* [x] `InpMaxOpenRiskPercent`・`InpMinMarginLevelPercent`の実効性をストレステストで確認する（2026-08-23実施、ユーザー依頼）。同一Train区間（2017-09〜2018-12）・dist=100pt構成をベースに、各ガードのみ一時的に厳格化して再実行した。詳細は`results/backtests/fold1-train-multipos-sweep-20260823-summary.json`の`stress_test_results`参照。

  * `InpMaxOpenRiskPercent`を3%→**1.5%**（`InpRiskPerTradePercent`=1%以上という制約上の実質的な下限に近い値）へ厳格化: `MAX_OPEN_RISK_EXCEEDED`が6件発火し、機構が正しく動作することを確認した（`results/backtests/20260823-165435-USDJPY-H1/`）。
  * `InpMinMarginLevelPercent`を300%→**10000%**（通常の証拠金維持率を大きく上回る極端な値）へ厳格化: `MARGIN_LEVEL_TOO_LOW`が6件発火し、機構が正しく動作することを確認した（`results/backtests/20260823-165615-USDJPY-H1/`）。なお本チェックは`AccountInfoDouble(ACCOUNT_MARGIN)>0`（既存ポジションが1件以上ある状態）でのみ評価されるため、10000%でも新規ポジション0件の候補（最初の1件目）は拒否されない仕様であり、これは意図どおりの挙動。
  * 両runとも拒否対象は「2件目以降の同方向積み増し候補」に限られ、取引数・純損益（36件・+17,474円・PF1.10）はdist=300pt runと完全一致した。

  **総合評価: 両ガードとも実データで正しく拒否として発火することを確認した。安全機構としての実効性に問題は見つからなかった。** ユーザー指摘（2026-08-23）を受け、`InpMinSameDirectionEntryDistancePoints=0`の挙動説明を「積み増し無制限」から`docs/configuration.md`記載どおりの「距離制約が無効化される」へ訂正した（本節上部のdist=0の記述を修正済み）。

* [x] Fold1のTest区間（2019年）でブラインド検証を実施する（2026-08-23実施、ユーザー依頼）。Train区間で確認した構成（ADX40/StopATR2.0/RR2.0、dist=100pt、`InpMaxOpenRiskPercent`=3%、`InpMinMarginLevelPercent`=300%）に、ユーザー指定で`InpMaxOpenPositions`を2から**5**へ変更して適用した（`Config.mqh`の制約`max_same_direction_positions<=max_open_positions`は2<=5で充足）。詳細は`results/backtests/fold1-test2019-20260823-summary.json`参照（`results/backtests/20260823-172448-USDJPY-H1/`）。

  | 区間 | 取引数 | 純損益 | PF | Sharpe | 最大DD率 |
  |---|---|---|---|---|---|
  | Train（2017-09〜2018-12、単一ポジション構成の参考値） | 36 | +10,065円 | 1.12 | +0.27 | 2.08% |
  | **Test（2019、本run）** | 20 | **-80,988円** | **0.39** | **-1.65** | 9.19% |

  **重要な警告シグナル**: Test区間はTrain区間から一転して大幅に悪化した。TP到達率は15%（3/20件）に留まり、決済の70%（14/20件）がSLヒットで終わっている。`InpMaxOpenPositions=5`は本区間では一度も制約として機能せず（`POSITION_LIMIT`拒否0件）、実際の制約は`InpMaxSameDirectionPositions=2`（3件拒否）と`InpMinSameDirectionEntryDistancePoints=100`（7件拒否）だった。

  **解釈上の留意点（本節冒頭の限界と合わせて評価する必要がある）**: Test=2019は凍結IS最良パラメータセットの元の調整期間（IS=2017-09〜2020-12）の内側にあるため、厳密な意味でのブラインド検証ではない。ただしFold1のTrain区間自体（2017-09〜2018-12）は2019年データを一切参照していないため、「Train区間での調整結果が、その直後の未知期間へ汎化するか」という観点では意味のある悪化シグナルである。CLAUDE.mdの原則（推測で実装しない、危険な状態で動くことを避ける）に照らし、この結果を無視して次のFoldへ進むべきではない。

* [x] Test=2019の悪化要因を`python.analysis.trade_breakdown`で分析する（2026-08-23実施、ユーザー依頼）。詳細は`results/backtests/20260823-172448-USDJPY-H1/breakdown/trade-breakdown-report.md`参照。

  **主要因1: TrendUp判定エントリーの壊滅的失敗が損失の87%を占める**。`market_regime_trend=TrendUp`の9件は勝率0%・純損益-70,630円（総損失-80,988円の87%）。対する`TrendDown`の11件は勝率27.3%・純損益-10,358円と相対的に軽微。2019年のUSDJPYは1〜4月に108→112へ上昇後、5〜8月に106近辺まで下落し11〜12月に109台へ戻すという往復相場で、持続的な一方向トレンドが乏しかったことと整合する。

  **主要因2: 高ADX（エグゾーション圏）エントリーの全滅**。`adx_band=ADX_47.36-60.35`の7件は勝率0%・純損益-52,247円。ADXが極端に高い局面（既にトレンドが伸び切った状態）でのエントリーが軒並み失敗しており、順張りの「高値掴み・安値掴み」に近いパターンが疑われる。

  **主要因3: 大多数の負けトレードはエントリー直後にほぼ含み益を作れずSLへ直行**。負け17件中12件はMFE_R<0.5（含み益が最大リスクの半分未満）で反転しており、決済管理（Breakeven等）では救えない「エントリー精度」の問題。残り5件はMFE_R 0.6〜1.4まで到達後に反転しており、うち大半は既存のBreakeven機構（`InpBreakevenTriggerR=1.0`）で小損失に抑えられていたが、1件（2019-01-22、MFE_R0.91で僅かに閾値未達）はBreakeven発動直前で反転し-1.12Rの損失となった。

  **総合評価**: 2019年はGiveback比率が極端に高く（平均546%・中央値279%、負けトレード全17件が一度含み益化してから反転）、Train区間（2017-09〜2018-12）と異なり持続的トレンドが乏しい往復相場だったことが、トレンドフォロー戦略の構造的な不利として表れたと考えられる。

* [x] **「C. Setup/Trigger条件の強化」を実装し、Train区間で再検証する（ユーザー依頼、2026-08-23実施）。** 悪化要因3（負け17件中12件がMFE_R<0.5でSLへ直行）へ対応するため、Pullback Entry Trigger（`CTrendFollowingRules::IsPullbackTrigger`）に、タッチ足高安値を単に上回る/下回るだけでなくATR基準の余裕幅を要求する追加条件`trigger_atr_buffer`を導入した。既存の`IsBreakout`が持つbuffer機構（`breakout_buffer_points`）と同じ設計パターンを踏襲し、新規input `InpPullbackTriggerAtrBuffer`（既定値`0.0`＝無効、従来挙動と完全一致）で制御する。B案（高ADX局面での新規エントリー抑制）・D案（レジームフィルタ強化）は、今回のTest=2019で観測された具体的な閾値をそのまま使うと後付け最適化になるリスクが高いため対象外とし、ユーザー指定どおりC案のみに絞った。

  変更ファイル: `mt5/Include/Strategy/TrendFollowingRules.mqh`（`IsPullbackTrigger`・`IsPullback`にデフォルト引数`atr`・`trigger_atr_buffer`を追加、既定値0.0で数式上従来と完全等価）・`mt5/Include/Strategy/TrendFollowingStrategy.mqh`（呼び出し2箇所に`m_config.pullback_trigger_atr_buffer`を追加）・`mt5/Include/Core/Config.mqh`（新規フィールド`pullback_trigger_atr_buffer`、既定値0.0、validation追加）・`mt5/Experts/CoreEA.mq5`（新規input `InpPullbackTriggerAtrBuffer`、配線）・`mt5/Tests/TestTrendFollowingRules.mq5`（新規4アサーション）・`docs/configuration.md`。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS（`TestTrendFollowingRules`は新規4アサーション含む23件全PASS、他は既知事象と同じTerminal Exit Code 1のみ）で確認済み。

  Train区間（2017-09〜2018-12、現行の複数ポジション構成: ADX40/StopATR2.0/RR2.0/dist=100pt/`InpMaxOpenPositions=5`/`InpMaxSameDirectionPositions=2`/`InpMaxOpenRiskPercent=3%`/`InpMinMarginLevelPercent=300%`）で`InpPullbackTriggerAtrBuffer`を0.00/0.05/0.10/0.15/0.20でスイープした。

  | buffer | 取引数 | 純損益 | PF | Sharpe | 最大DD率 | 勝率 |
  |---|---|---|---|---|---|---|
  | 0.00（無効、従来挙動） | 40 | +28,882円 | 1.161 | +0.348 | 4.14% | 45.0% |
  | 0.05 | 39 | +30,801円 | 1.174 | +0.369 | 3.96% | 46.2% |
  | 0.10 | 39 | +30,801円 | 1.174 | +0.369 | 3.96% | 46.2% |
  | 0.15 | 39 | +30,801円 | 1.174 | +0.369 | 3.96% | 46.2% |
  | 0.20 | 38 | +40,535円 | 1.239 | +0.478 | 4.00% | 47.4% |

  **後方互換性の確認**: buffer=0.00は、この節で先に確認したdist=100pt構成のTrain結果（取引数40・純損益+28,882円・PF1.16・Sharpe+0.35・DD率4.14%）と完全一致し、コード変更が既定値で従来挙動を一切変えていないことを実データで確認した。

  **機構の動作確認**: buffer引き上げにより除外された取引は、0.00→0.05で1件（2018-09-07 BUY、-1,919円）、0.05→0.20で1件（2017-09-27 BUY、-9,826円）のみで、いずれも負けトレードだった。「弱いTrigger（タッチ足高安値を僅かに超えるだけの再加速）を除外する」という設計意図どおりに機能しており、除外対象が偶然ではなく損失トレードに偏っていることを確認した。

  **総合評価: 方向性としては改善が見られ、設計意図（弱いTriggerの除外）どおりに機能していることも確認できたが、効果の実体はTrain区間40件中わずか1〜2件の除外に留まる薄いサンプルであり、本セッションで繰り返し指摘してきた過学習リスク（StopAtrMultiple=1.5、ADX=40等の単一区間内での「山」）と同様の注意が必要**。特にbuffer=0.20が最良となっているのは、スイープ範囲の端点で1件を追加除外した結果であり、単独の根拠として採用すべきではない。0.05〜0.15が同一取引セットで安定していることから、採用する場合はプラトーの中間である0.10を候補とするのが0.20の端点选択より穏当と考える。

  **未対応の残存課題**: 本変更は悪化要因3（エントリー直後の即時反転）の一部にのみ対応するものであり、悪化要因1（TrendUp判定エントリーの0/9勝、総損失の87%）・悪化要因2（高ADX局面エントリーの0/7勝）には一切対応していない（ユーザー指定によりC案のみに限定したため）。Test=2019の悪化を包括的に説明・改善する変更ではなく、部分的な改善候補である。

  **次のステップに関する提案**: IS/OOS分離の原則上、この閾値をTest=2019の結果を見て調整することは避けるべきである（本ラウンドはTrain区間のみを使用しており、この点は遵守済み）。採用する場合は、(1) buffer=0.10を暫定候補として固定し、(2) Test=2019で一度だけ確認する、という手順を推奨する。ただし要因1・2が未対応のままでは、Test=2019の大幅な悪化（-80,988円）を覆すほどの改善は期待できない可能性が高い。

* [x] **`InpPullbackTriggerAtrBuffer=0.10`をベースライン（現状の設定）として固定し、「D. レジームフィルタの強化」を実装してTrain区間で再検証する（ユーザー依頼、2026-08-23実施）。** 悪化要因1（TrendUp判定エントリーの0/9勝、Test=2019総損失の87%）へ対応する狙いで、既存の市場レジーム判定（`CMarketRegimeClassifier::ClassifyTrend`、H1 ADX＋EMAスロープに基づく単発判定）を「直近1本だけでなく、過去N本連続でTrend状態（Range/Unknownでない）が継続していること」を要求する形へ強化した。トレンドへ切り替わった直後の不安定な状態（＝まだ持続性が確認できていない状態）でのEntryを避ける狙いで、新規input `InpRegimeTrendPersistenceBars`（既定値`1`＝従来の単発判定と完全等価）で制御する。既存の`stage_market_regime_passed`ゲート（Stage 1、`InpEntryUseStagedPipeline=true`時のみ有効）を拡張する形で実装し、ログ用の`market_regime_trend`フィールド（直近1本の分類、trade_breakdown等で参照）は変更していない。

  変更ファイル: `mt5/Include/Strategy/TrendFollowingStrategy.mqh`（新規private method `IsRegimeTrendPersistent`、Stage 1ゲートへ組み込み）・`mt5/Include/Core/Config.mqh`（新規フィールド`regime_trend_persistence_bars`、既定値1、validation追加）・`mt5/Experts/CoreEA.mq5`（新規input `InpRegimeTrendPersistenceBars`、配線）。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS（既存23アサーション、回帰なし）で確認済み。`IsRegimeTrendPersistent`は既存の`CMarketRegimeClassifier::ClassifyTrend`（`TestMarketRegimeClassifier`で単体テスト済み）を複数本ループで呼び出すのみの薄い集約ロジックであり、単体テストは追加せず、以下のTrain区間フル実行（既存の`ReadAtrBaseline`・`ReadBreakoutRange`等の他の複数本参照ヘルパーと同様、統合テストのみで検証する既存方針を踏襲）で検証した。

  Train区間（2017-09〜2018-12、現行の複数ポジション構成＋`InpPullbackTriggerAtrBuffer=0.10`固定）で`InpRegimeTrendPersistenceBars`を1（無効・従来挙動）/2/3/4/5でスイープした。

  | persistence(本) | 取引数 | 純損益 | PF | Sharpe | 最大DD率 | 勝率 |
  |---|---|---|---|---|---|---|
  | 1（無効、従来挙動） | 39 | +30,801円 | 1.174 | +0.369 | 3.96% | 46.2% |
  | 2 | 28 | -5,249円 | 0.964 | -0.037 | 6.88% | 46.4% |
  | 3 | 22 | -24,706円 | 0.792 | -0.333 | 5.55% | 45.5% |
  | 4 | 20 | -4,651円 | 0.954 | -0.044 | 4.59% | 50.0% |
  | 5 | 19 | 5,626円 | 1.063 | +0.109 | 3.63% | 52.6% |

  **後方互換性の確認**: persistence=1は、先に確認した`InpPullbackTriggerAtrBuffer=0.10`単独のTrain結果（取引数39・純損益+30,801円・PF1.174・Sharpe+0.369・DD率3.96%）と完全一致し、コード変更が既定値で従来挙動を一切変えていないことを確認した。

  **メカニズムの調査**: persistence=1→3で除外された21件を分析したところ、勝ちトレード9件・負けトレード12件が混在し、除外された取引群の純損益合計は**+26,555円（プラス）**だった。すなわちレジーム持続性フィルタは、狙っていた「不安定な状態での負けトレード」だけでなく、それと同程度以上に「トレンド転換直後の初動を捉える質の良い勝ちトレード」も一緒に除外してしまっており、悪化要因1（TrendUp判定の質）の改善という設計意図とは逆方向に作用していた。

  **総合評価: 「D. レジームフィルタの強化」は、本Train区間の実データでは性能を悪化させる結果となり、採用を推奨しない。** persistence=2〜4は純損益・PF・Sharpeのいずれも悪化（PF<1、Sharpeマイナス）し、persistence=5でわずかに回復するものの依然としてpersistence=1（現行ベースライン）を下回る。これは「レジーム転換直後を避ける」という設計仮説が、少なくとも本Train区間・本実装方式では成立しなかったことを示す、明確な反証結果である。B案（ADX上限フィルタ）とは異なりTest=2019データを一切参照していないため、これはIS/OOS分離の原則に沿った正当なTrain内検証の結果であり、過学習ではなく「仮説が誤っていた」という判断ができる。

  **残存課題**: 悪化要因1（TrendUp判定エントリーの0/9勝、Test=2019総損失の87%）は依然として未対応のまま残っている。今回の反証結果を踏まえると、単純な「持続性要求」というアプローチでは対応できない可能性が高く、別のアプローチ（例: HTF Bias側の強化、方向別の追加確認条件、あるいはレジーム判定ロジック自体の見直し）を検討する必要がある。悪化要因2（高ADX局面エントリーの0/7勝）も引き続き未対応。`InpRegimeTrendPersistenceBars`は既定値1（無効）のまま据え置き、EA既定値・Tester ini構成のいずれにも1以外の値は適用していない。

* [x] **「B. 高ADX局面での新規エントリー抑制」を実装し、Train区間で再検証する（ユーザー依頼、2026-08-23実施）。** 悪化要因2（Test=2019で`ADX 47.4〜60.4`帯のエントリー7件が0勝、-52,247円）へ対応する狙いで、H1 ADXの上限閾値`InpMaximumAdx`（既定値`0.0`＝無効）を新規追加した。既存の`InpMinimumAdx`（下限フィルタ）と対称の設計で、上回るとエグゾーション（過熱）局面として候補を棄却する。**Test=2019で観測された具体的な閾値（47.36等の分位点境界）は使わず**、TAの慣習的な区切り値（50/55/60/65）とTrain区間自体のADX分布（39件・平均45.4・最大65.5）から選んだ値でスイープした。

  変更ファイル: `mt5/Include/Strategy/TrendFollowingStrategy.mqh`（`ADX_TOO_HIGH`ゲート追加）・`mt5/Include/Core/Config.mqh`（新規フィールド`maximum_adx`、既定値0.0、validation追加）・`mt5/Experts/CoreEA.mq5`（新規input `InpMaximumAdx`、配線）・`docs/configuration.md`。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS（回帰なし）で確認済み。

  Train区間（2017-09〜2018-12、現行構成＋`InpPullbackTriggerAtrBuffer=0.10`固定）で`InpMaximumAdx`を無効(0)/65/60/55/50でスイープした。

  | maxADX | 取引数 | 純損益 | PF | Sharpe | 最大DD率 | 勝率 |
  |---|---|---|---|---|---|---|
  | 無効(0、従来挙動) | 39 | +30,801円 | 1.174 | +0.369 | 3.96% | 46.2% |
  | 65 | 38 | +10,920円 | 1.062 | +0.164 | 3.96% | 44.7% |
  | 60 | 38 | +10,920円 | 1.062 | +0.164 | 3.96% | 44.7% |
  | 55 | 35 | +11,778円 | 1.076 | +0.180 | 3.98% | 45.7% |
  | 50 | 33 | +1,893円 | 1.013 | +0.053 | 4.79% | 45.5% |

  **メカニズムの調査**: 無効(0)→65で除外された唯一の1件（2018-01-24 05:00 SELL）は**+20,040円の大きな勝ちトレード**だった。以降の段階的な閾値引き下げでも、除外される取引は勝ち（+19,456円・+19,695円）と負け（-9,976円・-10,011円・-10,261円）が混在するが、除外される勝ちトレードの金額が負けトレードより大きく、閾値を厳しくするほど純損益が悪化する構造だった。

  **総合評価: 「B. 高ADX局面での新規エントリー抑制」は、本Train区間の実データでは性能を悪化させる結果となり、採用を推奨しない。** 全swept値（65/60/55/50）が無効(0)を明確に下回った。重要なのは、Test=2019で「高ADX＝壊滅的な負け」だったパターンが、Train区間（2017-09〜2018-12）では真逆に「高ADX＝最大級の勝ちトレード」として現れたことである。これは「高ADX＝エグゾーション」という仮説がTest=2019に固有のパターンであり、Train区間へ一般化できないことを示す強い反証であり、この観点に基づく閾値を安易にTest=2019の分位点から借用していた場合、典型的な後付け最適化（過学習）に陥っていたリスクを裏付ける結果でもある。

  **残存課題**: 悪化要因2（高ADX局面エントリーの0/7勝）はTrain内では反証されたが、Test=2019で実際に発生した損失パターンとしては依然として未説明のまま残っている。C案（buffer=0.10）以外に採用可能な改善策は本ラウンドまでで見つかっていない。B案・D案がいずれもTrain区間で反証されたことを踏まえると、Test=2019の悪化は単純な入口フィルタの追加では解消できない、より構造的な問題（トレンドフォロー戦略が往復相場に本質的に不利、というTASKS.md冒頭の分析どおり）である可能性が高まっている。`InpMaximumAdx`は既定値0（無効）のまま据え置き、EA既定値・Tester ini構成のいずれにも0以外の値は適用していない。

* [x] **C案（`InpPullbackTriggerAtrBuffer=0.10`）を適用した状態でTest=2019を一度だけ再実行し、確認する（ユーザー依頼、2026-08-23実施）。** B案・D案採用見送りに伴い、C案のみを適用した構成（IS最良パラメータセット＋複数ポジション構成＋`InpPullbackTriggerAtrBuffer=0.10`、`InpMaximumAdx`・`InpRegimeTrendPersistenceBars`は既定値のまま）でTest=2019（`results/backtests/20260823-204224-USDJPY-H1/`）を実行した。IS/OOS分離の原則に従い、Test区間へのアクセスはこの1回に限定した。

  **結果: 元のTest=2019結果（`results/backtests/20260823-172448-USDJPY-H1/`、buffer無効）と完全に同一（取引数20・純損益-80,988円・PF0.386・Sharpe-1.645・DD率9.19%・勝率15.0%）**。`trades-normalized.csv`を突き合わせたところ全20件が完全一致するバイナリレベルの同一結果であり、`InpPullbackTriggerAtrBuffer=0.10`はTest=2019区間では一度も発火しなかった（Train区間で除外していた「弱いTrigger」パターンが、たまたまTest=2019の候補群には存在しなかった）。

  **総合評価: C案はTest=2019に対して一切の改善効果を持たなかった。** これは、C案がTrain区間内のごく少数（40件中1〜2件）の除外に依拠した薄い効果だったという既報の懸念を裏付ける結果であり、Test=2019の悪化はC/B/D案のいずれによっても改善されないことが確定した。エントリー側のフィルタ強化（B/C/D案）だけでは対応できないことが、Train・Test両方の実データで示された。**なお、この直後にF案（決済管理強化）の実装を開始した記録が残っていたが、これは誤って送信された別プロンプトによるものであり、ユーザー確認の上で2026-08-23に取り消した（`mt5/Include/Trading/PositionManager.mqh`・`mt5/Include/Core/Config.mqh`・`mt5/Experts/CoreEA.mq5`・`docs/configuration.md`・`mt5/Tests/TestTradingRules.mq5`への未コミット変更を`git checkout HEAD --`でコミット済み状態へ復元）。** ユーザー指定によりE案（ロールフォワード継続、Fold2以降）を優先する方針とする。

* [x] Fold2（Train2017-09〜2019-12→Test2020）を現状の調整（IS最良パラメータセット＋複数ポジション構成＋`InpPullbackTriggerAtrBuffer=0.10`、`InpMaximumAdx`・`InpRegimeTrendPersistenceBars`は既定値）で実行する（ユーザー依頼、2026-08-23実施）。

  | 区間 | 取引数 | 純損益 | PF | Sharpe | 最大DD率 | 勝率 |
  |---|---|---|---|---|---|---|
  | Train（2017-09〜2019-12、`results/backtests/20260823-205804-USDJPY-H1/`） | 64 | +14,919円 | 1.046 | +0.126 | 6.87% | 39.1% |
  | **Test（2020、`results/backtests/20260823-210123-USDJPY-H1/`）** | 25 | **+51,141円** | **1.529** | **+0.664** | 4.26% | 36.0% |

  **Fold1との対比**: Fold1のTest=2019（取引数20・純損益-80,988円・PF0.39・Sharpe-1.65）とは対照的に、Fold2のTest=2020は取引数こそ少ないものの明確に良好な結果（PF1.53・Sharpe+0.66）となった。これは2019年の悪化が、往復相場全般に共通する構造的な弱点ではなく、2019年固有の相場環境（トレンド期間の乏しさ）に起因していた可能性を示唆する。ただし判断にはFold3以降の追加データが必要。

  **留意点**: Fold2のTrain区間（2017-09〜2019-12）は、Fold1のTrain区間（2017-09〜2018-12、単一継続run）を含む延長区間だが、継続run内の取引数・損益はFold1単体の結果（39件・+30,801円）と単純合算にならない（本セッションで既知のDD_LIMIT発動・ポジション状態の連続性等による差異、詳細はTASKS.md該当節参照）。

* [x] Fold3（Train2018-2020→Test2021）を現状の調整で実行する（ユーザー依頼、2026-08-23実施）。Train開始は2018-01-01（DEC-025補正不要、Fold1・Fold2のみ2017-09-01への補正が必要だった）。

  | 区間 | 取引数 | 純損益 | PF | Sharpe | 最大DD率 | 勝率 |
  |---|---|---|---|---|---|---|
  | Train（2018〜2020、`results/backtests/20260823-211033-USDJPY-H1/`） | 72 | +5,995円 | 1.017 | +0.063 | 9.19% | 34.7% |
  | **Test（2021、`results/backtests/20260823-211401-USDJPY-H1/`）** | 31 | **+25,888円** | **1.175** | **+0.391** | 6.46% | 38.7% |

  **Fold1〜3のTest結果まとめ**: Fold1(2019) -80,988円・PF0.39／Fold2(2020) +51,141円・PF1.53／Fold3(2021) +25,888円・PF1.18。3年中2年がプラスとなり、2019年が引き続き外れ値の位置づけである。Fold4以降で傾向を確認する必要がある。

* [x] Fold4（Train2019-2021→Test2022）を現状の調整で実行する（ユーザー依頼、2026-08-23実施）。

  | 区間 | 取引数 | 純損益 | PF | Sharpe | 最大DD率 | 勝率 |
  |---|---|---|---|---|---|---|
  | Train（2019〜2021、`results/backtests/20260823-211728-USDJPY-H1/`） | 76 | -9,144円 | 0.975 | -0.011 | 9.19% | 31.6% |
  | **Test（2022、`results/backtests/20260823-212058-USDJPY-H1/`）** | 37 | **+86,073円** | **1.626** | **+0.744** | 5.33% | 54.1% |

  **Fold1〜4のTest結果まとめ**: Fold1(2019) -80,988円・PF0.39／Fold2(2020) +51,141円・PF1.53／Fold3(2021) +25,888円・PF1.18／Fold4(2022) +86,073円・PF1.63（現時点最良）。4年中3年がプラスとなり、2019年が引き続き唯一の外れ値である。Fold5・6で傾向を確認する必要がある。

* [x] Fold5（Train2020-2022→Test2023）を現状の調整で実行する（ユーザー依頼、2026-08-23実施）。

  | 区間 | 取引数 | 純損益 | PF | Sharpe | 最大DD率 | 勝率 |
  |---|---|---|---|---|---|---|
  | Train（2020〜2022、`results/backtests/20260823-212513-USDJPY-H1/`） | 93 | +171,860円 | 1.429 | +0.611 | 6.48% | 44.1% |
  | **Test（2023、`results/backtests/20260823-212914-USDJPY-H1/`）** | 16 | **-72,990円** | **0.214** | **-1.553** | 8.97% | 12.5% |

  **重要な修正: 「2019年が唯一の外れ値」という直前までの見立ては誤りだった。** Fold5のTest=2023は、Fold1のTest=2019（-80,988円・PF0.39・勝率15.0%）と酷似する悪化パターン（-72,990円・PF0.21・勝率12.5%、5Fold中最悪のPF）を示した。**Fold1〜5のTest結果まとめ**: 2019 -80,988円・PF0.39／2020 +51,141円・PF1.53／2021 +25,888円・PF1.18／2022 +86,073円・PF1.63／2023 -72,990円・PF0.21。5年中2年（2019・2023）が明確な悪化年であり、「往復相場的な年は約5年に2回程度の頻度で発生し、その年は大きく損失を出す」という、単発の外れ値ではなくパターンとして捉えるべき可能性が高まった。Fold6（2024）の結果を踏まえて総合評価する必要がある。

* [x] **Fold6（Train2021-2023→Test2024）を現状の調整で実行し、ローリングWalk Forward検証（Fold1〜6）を完了する（ユーザー依頼、2026-08-23実施）。**

  | 区間 | 取引数 | 純損益 | PF | Sharpe | 最大DD率 | 勝率 |
  |---|---|---|---|---|---|---|
  | Train（2021〜2023、`results/backtests/20260823-213227-USDJPY-H1/`） | 80 | +30,958円 | 1.083 | +0.177 | 9.32% | 41.2% |
  | **Test（2024、`results/backtests/20260823-213615-USDJPY-H1/`）** | 31 | **-28,272円** | **0.800** | **-0.477** | 6.57% | 35.5% |

  **Fold1〜6 Test結果 総括表**

  | Fold | Test年 | 取引数 | 純損益 | PF | Sharpe |
  |---|---|---|---|---|---|
  | 1 | 2019 | 20 | -80,988円 | 0.39 | -1.65 |
  | 2 | 2020 | 25 | +51,141円 | 1.53 | +0.66 |
  | 3 | 2021 | 31 | +25,888円 | 1.18 | +0.39 |
  | 4 | 2022 | 37 | +86,073円 | 1.63 | +0.74 |
  | 5 | 2023 | 16 | -72,990円 | 0.21 | -1.55 |
  | 6 | 2024 | 31 | -28,272円 | 0.80 | -0.48 |

  **合算結果（6年・160取引を単純合算）**: 純損益**-19,148円**（初期資金100万円に対し-1.9%）、集計Profit Factor**0.974**（gross_profit合算/|gross_loss合算|）、集計勝率**35.6%**。プラスの年3回（2020・2021・2022）・マイナスの年3回（2019・2023・2024）で、年別の振れ幅が非常に大きい（最良+86,073円〜最悪-80,988円）。

  **総合評価: 凍結IS最良パラメータセット＋本セッションで確認した調整（複数ポジション構成、`InpPullbackTriggerAtrBuffer=0.10`）は、6年間の真のブラインドWalk Forward検証において、集計PFが1を下回り、正味でわずかにマイナスとなった。** これはIS期間（2017-09〜2020-12）で確認された良好な指標（PF1.12前後）が、その後の未知期間へ安定して汎化していないことを意味する。B案・D案（本節前段）がTrain区間で反証されたことと合わせ、単純な入口フィルタの調整では対応できない、より根本的な課題（IS期間が偶然良好なトレンド局面を多く含んでいた可能性、またはトレンドフォロー戦略自体が長期的に見て明確な正のエッジを持たない可能性）を示唆する。`docs/production-readiness-report.md`のNO-GO判定を継続する根拠として重要な発見であり、IS最良パラメータセットをそのまま本番相当の候補として扱うべきではない。次の一手（IS期間自体の再定義・再調整、戦略ロジックの根本的見直し、あるいはこの結果を受け入れて本番化を見送る判断）はユーザーの評価を待つ。

## 2.1.2 戦略ロジックの根本的見直し: I案（サイジングのレジーム適応、2026-08-23ユーザー指定）

* [x] **I案（直近実績に基づくリスク量の適応的縮小）を実装し、Train区間で検証する（ユーザー依頼、2026-08-23実施）。** Fold1〜6の合算結果（集計PF0.974、正味マイナス）を受け、B案・D案（事前にレジームを予測して入口を絞る）とは異なる方向性として、事前予測を行わず**実際に悪い結果が続いた場合にのみ**リスク量を縮小する仕組みを実装した。

  **実装**: 新規`mt5/Include/Risk/AdaptiveSizingGuard.mqh`。`CAdaptiveSizingRules::RiskMultiplier()`（純粋関数、直近`lookback_trades`件の決済済みポジション数が閾値に満たない場合は1.0、勝率が`win_rate_trigger`を下回る場合のみ`reduced_multiplier`を返す）と`CAdaptiveSizingGuard::RecentWinRate()`（`HistorySelect`＋`DEAL_POSITION_ID`集約で、指定magicの直近N件の決済済みポジション＝部分決済は1件扱いの勝率を算出、取得不能時はfalse-safeでtrade_count=0を返す）。`RiskManager::Evaluate()`のポジションサイジング直前に組み込み、`risk_rate = risk_per_trade_rate × multiplier`として`CPositionSizer::Calculate`へ渡す。新規input `InpEnableAdaptiveSizing`（既定`false`）・`InpAdaptiveSizingLookbackTrades`（既定10）・`InpAdaptiveSizingWinRateTrigger`（既定0.30）・`InpAdaptiveSizingReducedMultiplier`（既定0.5）。`SRiskDecision`へ`adaptive_risk_multiplier`（既定1.0）を追加し、`RISK_DECISION`監査ペイロードへ記録して動作確認できるようにした。CLAUDE.md 14章「損失後の自動Lot増加」の禁止事項とは逆方向（縮小のみ、1.0を上回ることはない）であり抵触しない。

  変更ファイル: `mt5/Include/Risk/AdaptiveSizingGuard.mqh`（新規）・`mt5/Include/Risk/RiskManager.mqh`・`mt5/Include/Risk/RiskDecision.mqh`・`mt5/Include/Core/Config.mqh`・`mt5/Include/Core/EAController.mqh`・`mt5/Experts/CoreEA.mq5`・`mt5/Tests/TestRiskGuards.mq5`（新規9アサーション）・`docs/configuration.md`。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS（`TestRiskGuards`は新規9アサーション含む全PASS）。既定値（`InpEnableAdaptiveSizing=false`）でTrain区間（2017-09〜2018-12）を再実行し、直前の`InpPullbackTriggerAtrBuffer=0.10`単独結果（取引数39・純損益+30,801円・PF1.1735・Sharpe+0.369）と完全一致することを確認し、後方互換性を実データで確認した（`results/backtests/20260823-215645-USDJPY-H1/`）。

  **有効化してのTrain区間スイープ**（lookback=10・reduced_multiplier=0.5固定、win_rate_trigger 0.20/0.30/0.40/0.45）:

  | trigger | 発火回数 | 取引数 | 純損益 | PF | Sharpe |
  |---|---|---|---|---|---|
  | 0.20 | 0 | 39 | +30,801円 | 1.174 | +0.369 |
  | 0.30 | 0 | 39 | +30,801円 | 1.174 | +0.369 |
  | 0.40 | 0 | 39 | +30,801円 | 1.174 | +0.369 |
  | **0.45** | **8** | 39 | **-6,000円** | **0.964** | **-0.048** |

  **機構の動作確認**: 監査ログ（`RISK_DECISION.adaptive_risk_multiplier`）とTRADE_CLOSEDの時刻を突き合わせ、各承認時点の「直近10件決済済みポジションの勝率」を手動再計算したところ、本Train区間内の最小値はちょうど0.40（狭義未満条件のため0.20/0.30/0.40では一度も発火しない）で、0.45で初めて8回発火することを確認した。実装は設計どおり正しく動作している。

  **重要な発見: 発火した8件中7件が勝ちトレード（+926円〜+9,883円）、負けは1件（-4,899円）のみだった。** 「直近成績が悪化した直後に縮小する」という設計は、本Train区間では成績悪化の直後に訪れた回復局面（勝ちトレードの連続）まで縮小してしまい、結果的に純損益を+30,801円→-6,000円へ悪化させた。これは、実現成績の平均回帰（悪い後には良いことが多い）という統計的な性質に対し、単純な勝率トリガーが構造的に不利に働くことを示す、原理的な限界である。

  **総合評価: I案（勝率ベースの単純な縮小トリガー）は、少なくとも本Train区間・本パラメータでは効果が実証できず、緩い閾値（0.20〜0.40）では単に発火せず無意味、やや踏み込んだ閾値（0.45）では回復局面を巻き込んで悪化させるという、いずれの側でも採用の根拠が得られなかった。** ただし本セッションで繰り返し指摘してきた注意点と同様、これは単一の39取引・16か月という薄いサンプルでの結果であり、より長い区間（例: Fold5 Train、93取引）や異なる指標（勝率でなく直近PF・R倍数平均等の連続値）で改めて検証する余地は残る。既定値（`InpEnableAdaptiveSizing=false`）のまま据え置き、EA既定値・Tester ini構成のいずれにも変更を適用していない。

* [x] **I案を連続値指標（直近平均R倍数相当）ベースへ再設計する（ユーザー依頼、2026-08-23実施）。** 二値閾値方式（勝率が閾値を下回った瞬間に固定倍率へ切り替わる）が「境界を跨いだ直後の回復トレードまで一律に巻き込む」という原理的な弱点を持っていたことを踏まえ、`avg_r`（直近`lookback_trades`件の損益を、現在の基準リスク額`equity×risk_per_trade_rate`で正規化したものの平均）が0未満の場合にのみ、その絶対値に比例して滑らかに縮小する設計へ変更した。`multiplier = clamp(1.0 + sensitivity×avg_r, floor_multiplier, 1.0)`（`avg_r>=0`では常に1.0、拡大方向へは働かない）。

  変更ファイル: `mt5/Include/Risk/AdaptiveSizingGuard.mqh`（`RecentWinRate`→`RecentAverageR`、`RiskMultiplier`のシグネチャを連続値方式へ全面書き換え）・`mt5/Include/Risk/RiskManager.mqh`（呼び出し箇所を更新、`base_risk_amount=equity×risk_per_trade_rate`を算出して渡す）・`mt5/Include/Core/Config.mqh`（`adaptive_sizing_win_rate_trigger`/`adaptive_sizing_reduced_multiplier`を`adaptive_sizing_sensitivity`（既定1.0）/`adaptive_sizing_floor_multiplier`（既定0.5）へ置換）・`mt5/Experts/CoreEA.mq5`（input名を`InpAdaptiveSizingSensitivity`/`InpAdaptiveSizingFloorMultiplier`へ変更）・`mt5/Tests/TestRiskGuards.mq5`（12アサーションへ全面更新）・`docs/configuration.md`。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS（`TestRiskGuards`新規12アサーション含む）。既定値（`InpEnableAdaptiveSizing=false`）でTrain区間を再実行し、直前の結果（取引数39・純損益+30,801円・PF1.173543・Sharpe+0.369203）と完全一致することを確認し、後方互換性を実データで確認した（`results/backtests/20260824-001235-USDJPY-H1/`）。

  **有効化してのTrain区間スイープ**（lookback=10固定、sensitivity/floor_multiplierを変更）:

  | sensitivity | floor | 発火回数 | 取引数 | 純損益 | PF | Sharpe |
  |---|---|---|---|---|---|---|
  | （無効、参考） | — | 0 | 39 | +30,801円 | 1.174 | +0.369 |
  | 1.0 | 0.5 | 13 | 39 | +20,376円 | 1.117 | +0.267 |
  | 2.0 | 0.5 | 14 | 39 | +4,392円 | 1.026 | +0.085 |
  | 2.0 | 0.3 | 14 | 39 | +4,392円 | 1.026 | +0.085 |（floor未到達、最大縮小は0.622倍に留まりfloor=0.3は非拘束）

  **機構の動作確認**: sensitivity=1.0/floor=0.5の縮小発動13件のうち内訳が判明した12件は、勝ちトレード10件（合計+113,007円、全額サイズ時換算）・負けトレード2件（合計-18,418円）だった。連続値方式は二値方式より発動が滑らか（0.83〜0.99倍の範囲で段階的）になったが、**縮小が勝ちトレードに偏るという根本的な性質は解消されなかった**。

  **総合評価: 連続値方式への再設計は、実装としては二値方式より洗練された（境界での急激な悪化を避け、段階的に縮小する）ものの、収益性の観点では改善しなかった。** sensitivity・floorのいずれの組み合わせでも、無効時（+30,801円）を上回る結果は得られず、感度を上げるほど（sensitivity 1.0→2.0）純損益はむしろ悪化した（+20,376円→+4,392円）。これは実装方式（二値か連続値か）の問題ではなく、**「直近の実現成績が近い将来の成績を予測する」という前提自体が、本Train区間のデータでは成立していない（むしろ平均回帰的で、悪い後には良い結果が来やすい）ことを示す、より根本的な反証**と考えられる。

  **残存課題・今後の判断材料**: B案・D案（入口側の事前予測）、I案二値方式・連続値方式（出口側の事後反応）と、性質の異なる4つのアプローチがいずれもTrain区間で反証された。これは個々の実装の巧拙ではなく、「過去の限られた情報から近い将来の相場・トレード成績の良否を予測する」というアプローチ全般が、本戦略・本データセットでは十分な予測力を持たない可能性を示唆する。次に検討すべきは、予測に依存しないアプローチ（例: IV案のポートフォリオ化＝トレンドフォロー以外の戦略との分散）か、あるいはこの制約を受け入れた上での本番化見送りの継続である。既定値（`InpEnableAdaptiveSizing=false`）のまま据え置き、EA既定値・Tester ini構成のいずれにも変更を適用していない。

* [x] **III案（regime分類器の高度化）・II案（平均回帰の新規戦略）を実装し、Train区間で検証する（ユーザー依頼、2026-08-24実施）。** B案・D案（入口の事前予測）・I案（出口の事後反応）がいずれも反証されたことを踏まえ、「トレンドフォロー以外のアプローチ」として、既存のトレンドフォロー戦略とは独立した第二の候補生成源＝平均回帰戦略を追加した。

  **III案（regime分類器の高度化）**: 既存の`CMarketRegimeClassifier`（ADX＋MAスロープ）はB案・D案でいずれも反証済みのため、これを置き換えるのではなく、独立した確認軸としてChoppiness Index（E.W.Dreiss考案、価格経路効率性に基づくトレンド/レンジ判定、100に近いほどレンジ）を新設した。新規`mt5/Include/Filter/ChoppinessIndex.mqh`（`CChoppinessIndex::Calculate`・`IsChoppy`、いずれも純粋関数）。既存ATRインジケーターの平滑化値をTrue Range代用として合算する簡略実装（新規インジケーターハンドルを増やさない設計を優先）。

  **II案（平均回帰の新規戦略）**: 新規`mt5/Include/Strategy/MeanReversionStrategy.mqh`（`IStrategy`実装）。Choppiness Indexが閾値以上（レンジ相場確認）の場合のみ活動し、Bollinger Band下限＋RSI売られすぎでBUY、上限＋買われすぎでSELL、TPはBand中心線・SLはATR倍率という古典的な平均回帰ロジック。既存のトレンドフォロー戦略が該当確定足で候補を生成しなかった場合のみ評価される排他制御とし、両戦略が同一口座へ同時発注することを避けた。既存のRisk Manager・PositionManager・監査ログ基盤（同一magic number）をそのまま共有する設計とし、新たな安全機構は追加していない（Risk Managerの最終拒否権は両戦略に等しく適用される、CLAUDE.md 4.1準拠）。

  変更ファイル: `mt5/Include/Filter/ChoppinessIndex.mqh`（新規）・`mt5/Include/Strategy/MeanReversionStrategy.mqh`（新規）・`mt5/Include/Signal/SignalResult.mqh`（`ENTRY_PATTERN_MEAN_REVERSION`追加）・`mt5/Include/Core/Config.mqh`（新規フィールド8件、既定`enable_mean_reversion_strategy=false`）・`mt5/Include/Core/EAController.mqh`（第二の`CSignalEngine`インスタンスを追加、トレンドフォロー戦略が候補なしの確定足でのみ評価）・`mt5/Experts/CoreEA.mq5`（新規input 8件）・`mt5/Tests/TestMarketRegimeClassifier.mq5`（Choppiness Index 10アサーション）・`mt5/Tests/TestTrendFollowingRules.mq5`（平均回帰エントリー判定6アサーション）・`docs/configuration.md`。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS（新規16アサーション含む）。既定値（`InpEnableMeanReversionStrategy=false`）でTrain区間を再実行し、直前結果（取引数39・純損益+30,801円・PF1.173543）と完全一致することを確認し、後方互換性を実証済み（`results/backtests/20260824-004124-USDJPY-H1/`・`20260824-005316-USDJPY-H1/`）。

  **機構の動作確認と発見された不具合**: `InpEnableMeanReversionStrategy=true`かつ既定閾値（Choppiness最小61.8）でTrain区間を実行したところ、平均回帰候補が0件だった。原因調査のため一時的に閾値を0（無効化）にして再実行したところ361件の平均回帰候補が生成され、ロジック自体は正しく動作していることを確認した。あわせてChoppiness値の実測分布（361件、最小10.95・最大60.24・平均33.6）を確認し、**既定閾値61.8は本データセット・本簡略実装（ATR平滑化値の代用）のスケールに対して厳しすぎ、一度も到達しない値だった**ことが判明した（TA文献の慣習値をそのまま採用したことが原因、詳細はdocs/configuration.md参照）。また、この過程で**`EAController::CandidateForPosition()`のtrade_candidate_id復元ロジックが平均回帰戦略のID形式（`{ea_id}-MR-{symbol}-{bar_time}`）に対応しておらず、TRADE_CLOSED側のIDが不一致となりPython側`by_strategy`集計が"UNKNOWN"に分類される不具合を発見・修正した**（`CandidateForPosition`はDeal Commentから`{ea_id}-{symbol}-{bar_time}`形式のみを復元する実装のため、平均回帰戦略のID形式をトレンドフォロー戦略と同一形式へ変更して解消。両戦略は排他制御によりID衝突しないため安全）。修正後、`by_strategy`が正しく"MEAN_REVERSION"として分類されることを確認した。

  **Train区間での検証**（Choppiness閾値を実測分布に基づき50.0へ調整。61.8のままでは一度も発火しないため、実測データに基づく現実的な値へ変更）:

  | 構成 | 取引数 | 純損益 | PF | Sharpe |
  |---|---|---|---|---|
  | 平均回帰無効（参考、既存ベースライン） | 39 | +30,801円 | 1.174 | +0.369 |
  | 平均回帰有効・Choppiness閾値50 | 52 | -1,472円 | 0.993 | +0.019 |

  戦略別内訳（Choppiness閾値50）: BREAKOUT 28件・+50,158円・PF1.41（トレンドフォロー、既存とほぼ同水準）／PULLBACK 11件・-19,056円・PF0.64（トレンドフォロー、既存とほぼ同水準）／**MEAN_REVERSION 13件・-32,574円・PF0.0・勝率0%**（新規、全13件が損失）。

  **総合評価: II案（平均回帰戦略）は、本Train区間では明確に機能しなかった。** 13件全てが損失となり、既存のトレンドフォロー戦略単体の好成績（+30,801円）を、追加した平均回帰の損失（-32,574円）がほぼ相殺し、合算では正味わずかにマイナス（-1,472円）となった。B案・D案・I案（二値/連続値）に続き、これで5つ目の性質の異なるアプローチが本Train区間で反証されたことになる。

  **残存課題**: (1) Choppiness Indexの簡略実装（ATR平滑化値をTrue Range代用）により、閾値のスケールが標準的なChoppiness Indexの慣習値と一致しない。正式なTrue Range（各足の高安値・前足終値から算出、平滑化しない値）ベースへ改めるべきか検討の余地がある。(2) 平均回帰エントリー条件（Band接触＋RSI閾値のみ）が単純すぎ、真の反発を確認する追加条件（例: 反発を示す確定足のロウソク足形状、出来高等）を欠く可能性がある。(3) SL幅（ATR×1.5）とTP（Band中心線）の比率が、13件全敗という結果から見て不適切だった可能性がある。(4) 本検証は単一Train区間（39→52取引、16か月）に基づくものであり、他のアプローチと同様、単一区間での過学習リスクに注意が必要。`InpEnableMeanReversionStrategy`は既定値false（無効）のまま据え置き、EA既定値・Tester ini構成のいずれにも変更を適用していない。

* [x] **上記II案（平均回帰）の残存課題(2)(3)を踏まえ、ユーザー指示によりレンジ相場逆張りロジックの仕様を全面的に変更する（2026-08-24実施）。** RSI閾値によるBand接触のみのEntryから、「Band外側へのブレイク→次の確定足でBand内側へ復帰」という2本足確認パターンへ変更し、Range FilterもChoppiness Index単独からChoppiness Index（`InpMeanReversionChoppinessMin`以上）＋ADX（`InpMeanReversionAdxMax`未満）の複合判定へ強化した。RSI関連パラメータ（`mean_reversion_rsi_oversold`/`overbought`）は削除。SLはエントリー価格からの単純なATR倍率ではなく、Lower/Upper Bandまたは直近レンジ高安値（`InpMeanReversionBbPeriod`本）のうち保守的な方の外側にATR×`InpMeanReversionStopAtrMultiple`（既定1.0、旧1.5から変更）のバッファを設ける方式へ変更。TPはBB Middle既定のまま、将来比較用に反対側Band方式（`InpMeanReversionTakeProfitMode`）を追加。新規の強制決済ロジック（Range Filter解除／レンジ上限下限の確定足Closeブレイク／BB Width急拡大`InpMeanReversionBbWidthLookback`・`InpMeanReversionBbWidthExpansionRatio`のいずれか）と、トレンド戦略とは独立した時間切れ決済（`InpMeanReversionMaxHoldingBars`、既定20本）を追加した。レンジ戦略のポジションをトレンドロジックへ引き継がない設計を明確にするため、専用Magic Number（`InpMeanReversionMagicNumber`、既定26072002）でポジションを識別するよう変更し、`CPositionProtectionRules::IsManagedPosition`に3引数オーバーロード（プライマリ/セカンダリのいずれかに一致すれば管理下と判定）を追加して`PositionManager::Monitor`（保護SL安全網・建値ストップ）・`OnTradeTransaction`・`EAController::AuditDailySnapshots`がレンジポジションも正しく対象にするよう拡張した。`RiskManager::Evaluate`・`OrderManager::Submit`は`signal.entry_pattern`に応じて発注時のMagic Numberを切り替える。トレンド戦略専用の`EvaluateSignalInvalidationExits`/`EvaluateTimeStopExits`（プライマリMagic Numberのみを対象とする2引数版`IsManagedPosition`を維持）はロジック・挙動とも一切変更しておらず、新設の`EvaluateMeanReversionForcedExits`/`EvaluateMeanReversionTimeStopExits`と完全に独立している。

  変更ファイル: `mt5/Include/Strategy/MeanReversionStrategy.mqh`（全面書き換え）・`mt5/Include/Core/Config.mqh`（RSIフィールド2件削除、新規フィールド7件）・`mt5/Include/Core/EAController.mqh`（新規メソッド2件・`AuditDailySnapshots`のMagic判定拡張）・`mt5/Include/Trading/PositionManager.mqh`（`IsManagedPosition`3引数オーバーロード追加）・`mt5/Include/Risk/RiskManager.mqh`・`mt5/Include/Trading/OrderManager.mqh`（Magic Number切替）・`mt5/Experts/CoreEA.mq5`（input 2件削除・7件追加）・`mt5/Tests/TestTrendFollowingRules.mq5`（平均回帰ルール群のアサーションを新ロジックへ全面更新）・`mt5/Tests/TestTradingRules.mq5`（3引数`IsManagedPosition`のアサーション追加）・`docs/configuration.md`。`mt5/Include/Filter/ChoppinessIndex.mqh`・`mt5/Include/Signal/SignalResult.mqh`（`ENTRY_PATTERN_MEAN_REVERSION`）は変更なし（既存のまま再利用）。トレンドフォロー戦略側のファイル（`TrendFollowingStrategy.mqh`・`TrendFollowingRules.mqh`）は一切変更していない。

  **検証**: `.\tools\release-gate.ps1 -Mode Development`全体（必須文書チェック・秘密情報スキャン・JSON contracts検証・Python Phase12テスト119件・MQL5コンパイル10ターゲット0 errors/0 warnings・MQL5 Script Test 9件）が完走しPASSすることを確認済み。**未実施・未確認**: 新仕様でのStrategy Tester実データ検証（IS/OOS区間での取引数・PF・Sharpe等）は未実施であり、`InpEnableMeanReversionStrategy`は既定値false（無効）のまま据え置いている。有効化して検証する場合は、旧仕様の検証（残存課題(2)(3)）が新仕様でどう変化したかをTrain区間で確認したうえで判断すること。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する。

* [x] **上記のBand内復帰判定（次の1本のみ）を、ユーザー指示により最大N本以内の復帰を許容するReentry Window方式へ修正する（2026-08-24実施）。** レンジ相場ではBand内への復帰に数本を要するケースがあるため、`CMeanReversionRules::EntryDirection`（touch/entryの2本固定判定）を`EntryDirectionWithReentry`（配列ベース、可変長の窓）へ置き換えた。新規input `InpMeanReversionMaxReentryBars`（既定3、`mean_reversion_max_reentry_bars`）で、Band外側へのブレイクから何本以内の復帰を許可するか外部パラメータ化する。ブレイク（Reentry待ち開始）が起きた最初の確定足からの経過本数（gap）を、窓内の連続ブレイク本数（streak）として算出し、streakが窓の境界（`max_reentry_bars`本）に達している場合のみ、その1本先（`max_reentry_bars+2`本目）のBand外側継続有無を追加参照して「ブレイクが窓より前から継続していたか（期限切れ）」を判定する設計とした。これにより、復帰した確定足の直前の足（touch）がまだBand外側だった場合のみを新規の復帰事象として扱い（既に内側へ戻っていた足がある場合はその時点で判定済みのはずなので二重に発火しない＝同一ブレイクからの複数回エントリー防止）、`MaxReentryBars=1`では実質的に従来の「次の1本で復帰」と同等になる（単発ブレイクの場合は完全一致。ブレイクが2本以上継続していた場合は、従来実装にはなかった期限切れ判定が新たに働き拒否する、より厳密な挙動になる）。SL/TP・Range Filter・強制決済・時間切れ決済・リスク管理・Magic Number識別など、他のロジックは一切変更していない。

  変更ファイル: `mt5/Include/Strategy/MeanReversionStrategy.mqh`（`EntryDirection`を`EntryDirectionWithReentry`へ置換、`ReadReentryWindow`新設、`Evaluate`を窓読み取りへ変更）・`mt5/Include/Core/Config.mqh`（`mean_reversion_max_reentry_bars`追加、既定3、`ValidateConfig`に1以上の制約追加）・`mt5/Experts/CoreEA.mq5`（`InpMeanReversionMaxReentryBars`追加）・`mt5/Tests/TestTrendFollowingRules.mq5`（`SetReentryWindow3`/`SetReentryWindow5`ヘルパー新設、Entry関連アサーションを新API・新シナリオ（MaxReentryBars=1の従来相当ケース・期限切れケース、MaxReentryBars=3の境界成立ケース・期限切れケース、SELL対称ケース、不正入力ケース）へ全面更新）・`docs/configuration.md`。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・MQL5 Script Test 9件全PASS（新規Reentry Windowアサーション含む、ログで個別PASS確認済み）・`.\tools\release-gate.ps1 -Mode Development`全体PASS。**未実施**: Strategy Tester実データ検証（`InpEnableMeanReversionStrategy`は既定値false据え置き）。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する。

* [x] **保有中レンジポジションの強制決済条件を、ユーザー指示によりRange Filter（CI/ADX閾値）の一時的な跨ぎで反応しない設計へ修正する（2026-08-24実施）。** それまでの`IsRangeStillValid`は、新規エントリー用のRange Filter（CI>60かつADX<25）が保有中に1バーでも解除されると即座に決済していたが、CI/ADXは指標のノイズで閾値付近を頻繁に跨ぐため過剰反応（ホイッスル）の懸念があった。ユーザー指示により、Range Filterは新規エントリー条件としてのみ用い、保有中ポジションの決済判断からは完全に除去した。代わりに、レンジ崩壊を示すより強い2条件（(a)レンジ高値/安値の確定足ブレイク、(b)ADX急伸）を新設し、既存のBB Width急拡大と合わせた3条件で強制決済を判定する構成へ変更した。(a)は従来Bollinger Bandを参照していた`IsRangeBreak`を、実際の直近スイング高安値（`ReadRecentRange`、SL算出と同じ参照）を参照するよう変更（統計的な構成物であるBandではなく価格構造そのものを見る、より強い条件への変更）。(b)は新設`CMeanReversionExitRules::IsAdxSurging`（ADXが`InpMeanReversionForcedExitAdxThreshold`＝既定30.0を超え、かつ直近確定足間で上昇中の両方を要求、単純な閾値跨ぎでは反応しない）。あわせて、エントリー条件とポジション強制決済条件をコード上も明確に分離するというユーザー指示に従い、`CMeanReversionRules`を`CMeanReversionEntryRules`（Range Filter・Reentry Window付きEntry判定・SL/TP算出）と`CMeanReversionExitRules`（レンジブレイク・ADX急伸・BB Width急拡大）の2クラスへ分割した。

  変更ファイル: `mt5/Include/Strategy/MeanReversionStrategy.mqh`（`CMeanReversionRules`を`CMeanReversionEntryRules`/`CMeanReversionExitRules`へ分割、`IsRangeBreak`の参照をBandから直近スイング高安値へ変更、`IsAdxSurging`新設、`IsRangeStillValid`からRange Filterチェックを除去しADX急伸チェックを追加）・`mt5/Include/Core/Config.mqh`（`mean_reversion_forced_exit_adx_threshold`追加、既定30.0、`ValidateConfig`に0<x<=100の制約追加）・`mt5/Experts/CoreEA.mq5`（`InpMeanReversionForcedExitAdxThreshold`追加）・`mt5/Tests/TestTrendFollowingRules.mq5`（`CMeanReversionRules::`参照を`CMeanReversionEntryRules::`/`CMeanReversionExitRules::`へ更新、`IsAdxSurging`のアサーション5件・`IsRangeBreak`の未方向ケース1件を追加）・`docs/configuration.md`。エントリー条件（Range Filter・Reentry Window・SL/TP算出）・時間切れ決済・Magic Number識別・他の安全機構は一切変更していない。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・MQL5 Script Test 9件全PASS（新規`IsAdxSurging`アサーション含む、ログで個別PASS確認済み）・`.\tools\release-gate.ps1 -Mode Development`全体PASS。**未実施**: Strategy Tester実データ検証（`InpEnableMeanReversionStrategy`は既定値false据え置き）。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する。

* [x] **上記のRange Filter解除トリガー（このセッション中に一時`IsRangeQualityLost`＝強制決済専用のCI/ADX別閾値へ差し戻されていた）を、ユーザー指示により「警戒状態＋猶予期間」の状態機械へ再修正する（2026-08-25実施）。** Range Filterが1バーでも解除されると即座に決済する挙動は、レンジが一時的に崩れただけでもTP到達前に決済される頻度が高いという問題を残したまま（`IsRangeQualityLost`は判定式こそ変わっていたが、依然として「解除を検知した確定足で即決済」という即時性は同じだった）。ユーザー指示により、Range Filter自体の判定条件（`CMeanReversionEntryRules::IsRangeFilterActive`、CI>60かつADX<25、エントリーと完全に同一）は一切変更せず、保有ポジションの決済判断だけを「解除を検知したら即決済」から「解除を検知したら警戒状態へ移行し、最大`InpMeanReversionRangeExitGraceBars`本（既定3、新規input）以内に確定足Closeが直近レンジ高値/安値を明確にブレイクした場合のみ決済、猶予期間内にRange Filterが再成立すれば通常状態へ復帰、猶予期間超過時は決済せず既存SL/TP等の管理に委ねる」という状態機械へ変更した。`IsRangeQualityLost`（強制決済専用のCI/ADX別閾値、`mean_reversion_forced_exit_adx_threshold`/`_choppiness_max`）は廃止し、既存のRange Filter閾値をそのまま再利用する設計に統一した（パラメータの二重管理を解消）。ticket単位の警戒状態は新設`CRangeExitGraceTracker`（`MeanReversionStrategy.mqh`内、`CTimeStopTracker`と同じ「レコードの有無で状態を表す」設計だがStrategy層がTrading層へ依存しないよう同ファイル内に定義）で追跡し、`IsRangeStillValid`のシグネチャに`ticket`引数を追加した。BB Width急拡大は警戒状態と独立した常時有効な条件として維持（変更なし）。あわせて、強制決済回数・TP到達率・SL到達率を区別できるようにという要望に応え、既存の監査イベント`RANGE_EXIT`（reason_code別に既に区別可能だった）をPython側`python/analysis/trade_breakdown.py`でも`TIME_STOP_EXIT`と同じパターンで結合するよう拡張し（`range_exit_reason_code`/`range_exit_triggered`列、`range_exit_summary()`、Markdownレポートへの新セクション）、実際にレポートから参照可能にした。

  変更ファイル: `mt5/Include/Strategy/MeanReversionStrategy.mqh`（`IsRangeQualityLost`削除、`CRangeExitGraceTracker`新設、`IsRangeStillValid`を状態機械へ全面書き換え、`ElapsedGraceBars`ヘルパー追加）・`mt5/Include/Core/Config.mqh`（`mean_reversion_forced_exit_adx_threshold`/`_choppiness_max`削除、`mean_reversion_range_exit_grace_bars`追加、既定3）・`mt5/Include/Core/EAController.mqh`（`IsRangeStillValid`呼び出しへ`ticket`引数追加、コメント更新）・`mt5/Experts/CoreEA.mq5`（`InpMeanReversionForcedExitAdxThreshold`/`InpMeanReversionForcedExitChoppinessMax`削除、`InpMeanReversionRangeExitGraceBars`追加）・`mt5/Tests/TestTrendFollowingRules.mq5`（`IsRangeQualityLost`のアサーション6件を削除、状態機械はticket単位の状態を要するため`IsTrendStillValid`と同様に静的関数テストの対象外である旨をコメントで明記）・`docs/configuration.md`・`python/analysis/trade_breakdown.py`（`_extract_range_exit_context`・`range_exit_summary`新設、`range_exit_reason_code`/`range_exit_triggered`列、Markdownレポート新セクション）・`python/tests/test_trade_breakdown.py`（新規アサーション3件）・`contracts/trade-breakdown-report.schema.json`（`range_exit`プロパティ追加）。エントリー条件（Range Filter判定式・Reentry Window・SL/TP算出）・時間切れ決済・Magic Number識別・他の安全機構は一切変更していない。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・MQL5 Script Test 9件全PASS・Python単体テスト121件全PASS（`test_trade_breakdown.py`新規3件含む）・`.\tools\release-gate.ps1 -Mode Development`全体PASS。**未実施**: Strategy Tester実データ検証（`InpEnableMeanReversionStrategy`は既定値false据え置き）。状態機械（警戒状態・猶予期間の遷移）自体は、ticket単位の永続状態とライブ確定足データを要するため、`IsTrendStillValid`と同様に本セッションでは静的単体テストの対象外とした（実データ検証はStrategy Tester側で行う必要がある、詳細は未実施）。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する。

* [x] **上記の新仕様（Band外側ブレイク→Reentry Window内復帰、Choppiness＋ADX複合Range Filter、専用Magic Number、強制決済・独立Time Stop）について、未実施だったStrategy Tester実データ検証をTrain区間で実施する（ユーザー依頼「レンジ相場逆張りロジックを変更したため、再度検証してください」、2026-08-24実施）。** 検証対象はコミット`4391801`（`git status`はクリーン、作業ツリーはコミット済み状態と完全一致）の既定パラメータ（`InpMeanReversionChoppinessMin=60.0`・`InpMeanReversionAdxMax=25.0`・`InpMeanReversionMaxReentryBars=3`・`InpMeanReversionStopAtrMultiple=1.0`・`InpMeanReversionTakeProfitMode=0`・`InpMeanReversionBbWidthLookback=20`・`InpMeanReversionBbWidthExpansionRatio=1.5`・`InpMeanReversionMaxHoldingBars=20`・`InpMeanReversionMagicNumber=26072002`）。

  **後方互換性の確認**: `InpEnableMeanReversionStrategy=false`（既定）でTrain区間を再実行し、直前結果（取引数39・純損益+30,801円・PF1.173543）と完全一致することを確認した（`results/backtests/20260824-201301-USDJPY-H1/`）。

  **Train区間での検証結果**（`InpEnableMeanReversionStrategy=true`、既定パラメータ、`results/backtests/20260824-201448-USDJPY-H1/`）:

  | 構成 | 取引数 | 純損益 | PF | Sharpe |
  |---|---|---|---|---|
  | 平均回帰無効（参考、既存ベースライン） | 39 | +30,801円 | 1.174 | +0.369 |
  | **平均回帰有効・新仕様・既定パラメータ** | 44 | **+20,780円** | **1.111** | **+0.324** |

  戦略別内訳: BREAKOUT 28件・+49,514円・PF1.40（トレンドフォロー、既存とほぼ同水準）／PULLBACK 11件・-18,693円・PF0.65（トレンドフォロー、既存とほぼ同水準）／**MEAN_REVERSION 5件・-10,041円・PF0.07・勝率20%**（新規）。

  **旧仕様との比較**: 旧仕様（RSI＋Band接触のみ、Choppiness単独Filter）は13件全敗・-32,574円だった。新仕様は5件・1勝4敗・-10,041円で、**取引数・損失額とも大幅に縮小し、合算結果への悪影響は明確に軽減された**（合算純損益: 旧-1,472円→新+20,780円）。ただし依然として平均回帰単体は正味マイナスであり、既存トレンドフォロー戦略の収益を目減りさせている状態は変わらない。

  **機構の動作確認**: 5件全ての`close_reason`が`EXPERT`（EA発の強制決済）であり、SL・TPいずれの到達でもなかった。保有時間は全件1〜2時間（H1で1〜2本）と極めて短く、新設の`EvaluateMeanReversionForcedExits`（Range Filter解除／レンジブレイク／BB Width急拡大）が意図どおり発火していることを確認した。個別にどの条件が発火したかは監査JSONLへ構造化記録されておらず（`PrintFormat`のコンソールログのみ）、本ラウンドでは判別していない（残存課題として後述）。`SYSTEM_ERROR`が1件（`INVALID_TRADE_GEOMETRY`）記録されたが、これはSL/TP幾何整合性チェックによるfail-safeな候補拒否であり、発注や既存ポジション管理には影響していない。

  **総合評価: 新仕様は旧仕様からの明確な改善だが、平均回帰単体としては依然として収益に寄与していない。** 全5件がSL・TP到達前にRange Filter解除等の強制決済で切り上げられていることから、**「Entry条件（Choppiness≥60かつADX<25という厳格な複合条件）が成立する瞬間は、その状態自体が長続きしにくい」**という構造的な問題が示唆される。エントリーが成立するほど厳格なレンジ状態を要求すると、その状態はほぼ同時に終わりやすく、平均回帰が効果を発揮する前に強制決済されてしまう可能性が高い。

  **残存課題**:
  1. Entry条件とExit条件（強制決済）の厳格さのバランスが取れておらず、エントリー直後に強制決済される構造的パターンが疑われる。強制決済側の条件（特にBB Width Expansion Ratio=1.5、比較的厳しい）を緩めるか、Entry条件を緩めて母数を増やすか、いずれかの検討が必要。
  2. 強制決済の発火理由（RANGE_FILTER_RELEASED/RANGE_BREAK/BB_WIDTH_EXPANSION）が監査JSONLに構造化記録されておらず、5件それぞれの正確な原因を機械的に特定できなかった。原因分析を今後も行う場合は、`TIME_STOP_EXIT`と同様の専用監査イベント追加を検討する必要がある。
  3. n=5と極めて少数のサンプルであり、本セッションで繰り返し指摘してきたとおり単一Train区間・少数サンプルからの結論は過学習リスクを伴う。良化・悪化どちらの方向についても断定は避けるべき。
  4. `InpEnableMeanReversionStrategy`は既定値false（無効）のまま据え置き、EA既定値・Tester ini構成のいずれにも変更を適用していない。

* [x] **レンジ戦略の強制決済（`EvaluateMeanReversionForcedExits`/`EvaluateMeanReversionTimeStopExits`）の発火理由を判別できるよう、専用監査イベント`RANGE_EXIT`を追加する（ユーザー依頼、2026-08-24実施）。** 既存の`TIME_STOP_EXIT`（トレンド戦略のTime Stop専用診断イベント）と同じ設計パターンを踏襲し、ローカル監査のみ（Telemetry契約は変更しない）で`position_ticket`・`reason_code`（`RANGE_FILTER_RELEASED`/`RANGE_BREAK`/`BB_WIDTH_EXPANSION`/`MEAN_REVERSION_MAX_HOLDING_BARS`のいずれか）・`elapsed_bars`を記録する。

  実装過程で2件の不具合を発見・修正した。(1) `mt5/Include/Logging/TradeLogger.mqh`の`CTradeLogRules::SafeEventType`（監査イベント種別の許可リスト）に`RANGE_EXIT`を追加しないと、ローカル監査ログへの書き込み自体が黙って失敗する構造だった（2026-08-17に`TIME_STOP_EXIT`で発生した既知の不具合パターンと同種、TASKS.md該当節参照）。(2) 決済実行（`CloseOnSignalInvalidation`/`CloseOnTimeStop`）の**後**に`PositionGetString`/`PositionGetInteger`で`symbol`・`position_identifier`を取得しようとしていた箇所が2か所あり、決済済みポジションに対する取得順序として不安全だったため、既存の`EvaluateTimeStopExits`と同じ安全な順序（決済実行**前**に必要な識別子を確保する）へ修正した。(3) `python/analysis/reports.py`の`SUPPORTED_AUDIT_EVENTS`（監査JSONLの許可イベント種別、厳格な集合一致チェック）に`RANGE_EXIT`が含まれておらず、`RANGE_EXIT`イベントを含む監査ログに対し`python.analysis.reports`の実行が`ValueError: unsupported audit event type`で失敗することを実行時に発見・修正した（`python/analysis/trade_breakdown.py`は許容的な実装のため影響なし）。

  変更ファイル: `mt5/Include/Core/EAController.mqh`（`EvaluateMeanReversionForcedExits`・`EvaluateMeanReversionTimeStopExits`へ`RANGE_EXIT`監査呼び出しと識別子取得順序の修正）・`mt5/Include/Logging/TradeLogger.mqh`（許可リストへ追加）・`python/analysis/reports.py`（`SUPPORTED_AUDIT_EVENTS`へ追加）。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS。既定値（`InpEnableMeanReversionStrategy=false`）でTrain区間を再実行し、直前結果（取引数39・純損益+30,801円・PF1.173543）と完全一致することを確認し、後方互換性を実証した（`results/backtests/20260824-202925-USDJPY-H1/`）。`InpEnableMeanReversionStrategy=true`・既定パラメータでTrain区間を再実行し（`results/backtests/20260824-203106-USDJPY-H1/`）、取引数・純損益（44件・+20,780円）が前回ラウンドと完全一致すること（純粋加算のみで挙動に影響しないことの確認）、および`RANGE_EXIT`イベントが5件正しく記録されることを確認した。`.\tools\release-gate.ps1 -Mode Development`全体（必須文書チェック・秘密情報スキャン・JSON contracts検証・Python Phase12テスト119件・MQL5コンパイル・MQL5 Script Test）もPASSした。

  **発火理由の内訳が判明**: 前ラウンドで残存課題としていた「5件の強制決済の内訳が不明」という点が解消された。5件中**4件が`RANGE_FILTER_RELEASED`**（Choppiness≥60かつADX<25という複合条件が、エントリー成立直後の0〜2本以内に再び満たされなくなった）、**1件が`RANGE_BREAK`**（確定足Closeがレンジ外へ明確にブレイク）で、`BB_WIDTH_EXPANSION`・`MEAN_REVERSION_MAX_HOLDING_BARS`の発火は0件だった。これは前ラウンドで立てた仮説（「エントリーが成立するほど厳格なレンジ状態は、その状態自体が長続きしにくい」）を実データで裏付ける結果であり、**Range Filterの条件自体（特にADX上限25という閾値）が、成立から解除までの継続時間を極端に短くしている主因である可能性が高い**。

  **残存課題**: (1) `RANGE_FILTER_RELEASED`が支配的要因と判明したため、次の調整候補はADX上限（`InpMeanReversionAdxMax`、既定25）またはChoppiness閾値（`InpMeanReversionChoppinessMin`、既定60）の緩和検討だが、これは単一Train区間の観測に基づく後付け調整になりやすく、過学習リスクに注意が必要（本セッションで繰り返し確認された罠と同種）。(2) n=5と極めて少数のサンプルのままであり、発火理由の内訳（4:1:0:0）も統計的に脆弱。(3) `InpEnableMeanReversionStrategy`は既定値false（無効）のまま据え置き。

* [x] **上記残存課題(1)を受け、Choppiness閾値（`InpMeanReversionChoppinessMin`）を緩める方向でスイープする（ユーザー依頼、2026-08-24実施）。** Fold1 Train（16か月、n=5と少数）だけではサンプル不足が懸念されたため、ユーザー指定によりFold5 Train（2020〜2022、3年間、既存ベースラインで93取引）も追加で用いた。

  **Fold1 Train（2017-09〜2018-12）でのスイープ結果**（`InpMeanReversionAdxMax`等は既定値のまま、Choppiness閾値のみ変更）:

  | Choppiness閾値 | 合算取引数 | 合算純損益 | 合算PF | MR取引数 | MR純損益 | MR PF | MR勝率 |
  |---|---|---|---|---|---|---|---|
  | 30（大幅に緩和） | 87 | -55,231円 | 0.802 | 48 | -85,957円 | 0.187 | 17% |
  | 35 | 81 | -59,197円 | 0.787 | 42 | -89,923円 | 0.141 | 17% |
  | 40 | 74 | -52,907円 | 0.805 | 35 | -82,322円 | 0.148 | 17% |
  | 45 | 61 | -25,948円 | 0.895 | 22 | -57,307円 | 0.156 | 18% |
  | 50 | 52 | +2,138円 | 1.010 | 13 | -28,615円 | 0.116 | 15% |
  | 55（既定60に近い） | 46 | +18,377円 | 1.095 | 7 | -12,224円 | 0.290 | 29% |

  **Fold5 Train（2020〜2022）での追試結果**（3点のみ、傾向確認目的）:

  | Choppiness閾値 | 合算取引数 | 合算純損益 | 合算PF | MR取引数 | MR純損益 | MR PF | MR勝率 |
  |---|---|---|---|---|---|---|---|
  | 40（緩和） | 96 | -166,809円 | 0.604 | 46 | -178,902円 | 0.019 | 4% |
  | 50 | 47 | -45,486円 | 0.762 | 19 | -74,444円 | 0.007 | 5% |
  | 60（既定） | 107 | +127,869円 | 1.294 | 14 | -40,988円 | 0.049 | 14% |

  **総合評価: 「緩める方向」は完全に反証された。二つの独立したTrain区間（Fold1・Fold5）の両方で、Choppiness閾値を下げるほど取引数は増えるが、勝率・PF・純損益のいずれも一貫して悪化するという、極めて明瞭な単調悪化パターンが再現した。** Fold5では閾値40でMR勝率がわずか4%（46件中2件未満の勝ち）まで落ち込み、既定値60（勝率14%）と比べても著しく悪い。これはユーザーが当初想定した仮説（「厳格すぎる条件がRANGE_FILTER_RELEASEDを招くなら、緩めれば改善するはず」）とは逆の結果であり、**既定の厳格な閾値（Choppiness≥60）は、たとえ早期強制決済を頻発させているとしても、緩めた場合よりも損失を抑える方向に機能している**ことを示す。2つの独立した区間で同一方向の結果が再現しているため、単一区間の過学習という通常の懸念は低いと判断できる。

  **残存課題**: (1) 「緩める」方向の調整は明確に否定されたが、「さらに厳しくする」方向（閾値65・70等）や、ADX上限側の調整（`InpMeanReversionAdxMax`を25より厳格化）は未検証。(2) MEAN_REVERSIONのPF・勝率はどの閾値でも1.0/50%を大きく下回っており、閾値調整だけでは正のエッジを作れない可能性が高い。エントリー条件・SL/TP設計自体の再考が必要かもしれない。(3) `InpEnableMeanReversionStrategy`は既定値false（無効）のまま据え置き、EA既定値・Tester ini構成のいずれにも変更を適用していない。

* [x] **閾値を下げた場合の損失原因の内訳分析を実施する（ユーザー依頼、2026-08-24実施）。** 分析の過程で、`CTradeAnalyticsTracker`（MFE・MAE追跡）が`m_config.magic_number`（トレンド戦略の主Magic Number）のみでポジションをフィルタしており、専用Magic Numberを使うレンジ戦略のポジションを一切追跡していなかった（レンジ戦略追加時の見落とし）ため、`mfe`/`mae`/`mfe_r`/`mae_r`が全件NaNになる不具合を発見・修正した。`PositionManager::IsManagedPosition`の3引数オーバーロードと同じ設計（`secondary_magic_number`引数、既定0＝セカンダリなし）で`CTradeAnalyticsTracker::Initialize`を拡張し、`EAController`の初期化呼び出しへ`m_config.mean_reversion_magic_number`を渡すよう変更した。

  変更ファイル: `mt5/Include/Logging/TradeAnalyticsTracker.mqh`（`Initialize`にsecondary_magic_number引数追加、`Update`のフィルタ条件拡張）・`mt5/Include/Core/EAController.mqh`（初期化呼び出しの引数追加）。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS。既定値でTrain区間を再実行し、直前結果（取引数39・純損益+30,801円・PF1.173543）と完全一致することを確認し、後方互換性を実証した（`results/backtests/20260824-212459-USDJPY-H1/`）。

  **損失原因の内訳（`RANGE_EXIT`理由コード別、Fold1 Train）**:

  | Choppiness閾値 | RANGE_FILTER_RELEASED | RANGE_BREAK | BB_WIDTH_EXPANSION | Time Stop |
  |---|---|---|---|---|
  | 30（緩） | 23（48%） | 13（27%） | **11（23%）** | 1（2%） |
  | 40（緩） | 19（54%） | 11（31%） | **4（11%）** | 1（3%） |
  | 45 | 14（64%） | 8（36%） | 0（0%） | 0（0%） |
  | 50 | 10（77%） | 3（23%） | 0（0%） | 0（0%） |
  | 55（既定60に近い） | 5（71%） | 2（29%） | 0（0%） | 0（0%） |

  `RANGE_FILTER_RELEASED`はどの閾値でも支配的要因（48〜77%）で構成比は大きく変わらないが、**`BB_WIDTH_EXPANSION`（BB幅の急拡大）が閾値45以上では一度も発生しないのに対し、閾値30・40では11〜23%を占める新規の失敗モードとして出現する**。

  **MFE・MAE分析（Choppiness閾値40 vs 55、Fold1 Train）**: 修正済みのMFE/MAE追跡データを用いて比較したところ、閾値40（緩、n=35）は平均MFE_R **0.205**（リスクの20.5%相当まで含み益が伸びた時点で反転）に対し、閾値55（厳、n=7）は平均MFE_R **0.317**と、より大きく含み益を伸ばせていた（MAE_Rは両者ともほぼ同水準、-0.41前後）。負けトレードのうち一度でも含み益になった割合は、閾値40で82.8%、閾値55で100%。

  **総合評価: 閾値を緩めると、単に「弱い」平均回帰セットアップ（反発の伸びが小さい、MFE_Rが低い）が大量に混入し、さらにBB幅急拡大という閾値45以上では存在しなかった新しい失敗モードまで発生するようになる。** Choppiness Indexが高いほど、レンジの「往復の純度」が高く、真の平均回帰が起きやすい条件であることを裏付ける結果であり、閾値の緩和はこの「純度」を犠牲にする方向の変更であるため、単純な緩和では改善しない。

  **「閾値を下げつつ損失を回避する方法」の検討（未検証の仮説、提案のみ）**:
  1. **BB幅の急拡大を事前に排除する**: エントリー時点でのBB幅が過去平均に対して既に拡大傾向にある場合は候補から除外する（現在は決済側の`IsBbWidthExpanded`しか使っていないが、同じ判定をEntry側のフィルタとしても使う）。閾値30・40で新たに出現した`BB_WIDTH_EXPANSION`（11〜23%）を狙い撃ちで防げる可能性がある。
  2. **MFE_Rに応じた早期の部分利確・建値化**: 閾値を緩めた場合の平均MFE_Rが0.2程度に留まることを踏まえ、より小さいR（例: 0.15〜0.2R）で部分利確または建値ストップへ移行する仕組みを追加すれば、反転前に一部の含み益を確定できる可能性がある。ただし現在は5〜35件という少数サンプルからの推定であり、この対策の効果自体を別途検証する必要がある。
  3. **どちらも未検証の仮説であり、本ラウンドでは提案に留める**。過去の類似ケース（B案・D案・I案）と同様、新しい仮説をTrain区間で検証してから採用可否を判断する必要がある。閾値を緩めること自体を単独で採用する根拠は、本ラウンドの分析でも得られなかった。

* [x] **レンジポジションの強制決済条件を再設計する（別セッションによる実装、2026-08-24実施、commit `de89651`）。** 前回分析で判明した「`RANGE_FILTER_RELEASED`（Choppiness/ADXの一時的な閾値跨ぎ1本のみで反応）が支配的要因であり、決済タイミングがMAEに対して平均73.5%の水準（ほぼ最悪値近辺）に達してから発動する」という根本原因を踏まえ、エントリー条件（`CMeanReversionEntryRules`、Range Filter＝Choppiness/ADX閾値）と保有中ポジションの強制決済条件（`CMeanReversionExitRules`）をクラスレベルで分離。強制決済条件を以下へ変更した。
  1. `RANGE_FILTER_RELEASED`（Choppiness/ADXの閾値跨ぎ）を**削除**。エントリー条件のRange Filterは新規エントリー成立判定にのみ使用し、保有中ポジションの決済判断には使わない方針へ変更。
  2. `RANGE_BREAK`: 判定基準をBollinger Bandから、直近`InpMeanReversionBbPeriod`本の実際のスイング高安値（Recent Range）へ変更。
  3. `ADX_SURGE`（新規）: ADXが新設の`InpMeanReversionForcedExitAdxThreshold`（既定30.0、Range Filterの`InpMeanReversionAdxMax`＝25より高い閾値）を超え、かつ直近確定足間で上昇中の場合のみ発動（閾値跨ぎの一時的な上下動では反応しない）。
  4. `BB_WIDTH_EXPANSION`は変更なし。時間切れ決済（`MEAN_REVERSION_MAX_HOLDING_BARS`）も変更なし。

  変更ファイル: `mt5/Include/Strategy/MeanReversionStrategy.mqh`（`CMeanReversionRules`を`CMeanReversionEntryRules`／`CMeanReversionExitRules`へ分離、`IsRangeStillValid`のロジック変更）・`mt5/Include/Core/Config.mqh`（`mean_reversion_forced_exit_adx_threshold`追加、既定30.0、Validationに範囲チェック追加）・`mt5/Experts/CoreEA.mq5`（`InpMeanReversionForcedExitAdxThreshold`追加）・`docs/configuration.md`（強制決済条件の記述更新）・`mt5/Tests/TestTrendFollowingRules.mq5`（クラス名変更に伴うテスト更新）。同commitに、前回ラウンドで実施した`CTradeAnalyticsTracker`のsecondary_magic_number対応（MFE/MAE追跡バグ修正）も含まれている。

  **検証**（本ラウンド実施）: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS・`.\tools\release-gate.ps1 -Mode Development`全体（必須文書チェック・秘密情報スキャン・JSON contracts検証・Python Phase12テスト119件・MQL5コンパイル・MQL5 Script Test）もPASS。Fold1 Train（2017-09〜2018-12、`results/backtests/20260824-224338-USDJPY-H1/`）とFold5 Train（2020-01〜2022-12、`results/backtests/20260824-224506-USDJPY-H1/`）の2区間で既定パラメータ（`InpMeanReversionChoppinessMin=60`・`InpMeanReversionForcedExitAdxThreshold=30`）を用いて実データ検証した。

  | 区間 | 合算取引数 | 合算純損益 | 合算PF | トレンドのみ取引数 | トレンドのみ純損益 | MR取引数 | MR純損益 | MR勝率 |
  |---|---|---|---|---|---|---|---|---|
  | Fold1 Train | 41 | +24,432円 | 1.133 | 39 | +30,426円 | 2 | -5,994円 | 0% |
  | Fold5 Train | 98 | +143,424円 | 1.347 | 93 | +166,791円 | 5 | -23,367円 | 0% |

  **旧ロジック（`RANGE_FILTER_RELEASED`あり、前回検証時点）との比較**: Fold5 Train・閾値60において、MR取引数は14件→**5件**、MR純損益は-40,988円→**-23,367円**、合算純損益は+127,869円→**+143,424円**（改善）。取引数が大幅に減った主因は、強制決済が発動しにくくなり保有時間が延びたため（`elapsed_bars`は旧ロジックの1〜3本から、新ロジックでは2〜20本へ延長）、同一期間内に成立する往復回数自体が減ったことによる。

  **決済理由の内訳**: Fold1（`ADX_SURGE`1件・`MEAN_REVERSION_MAX_HOLDING_BARS`1件）、Fold5（`ADX_SURGE`5件、100%）。**`RANGE_BREAK`（新設のRecent Range構造ブレイク判定）は両区間で1件も発動しなかった**。新設した3条件のうち、実際に機能しているのは`ADX_SURGE`のみで、企図した「レンジ崩壊のより強い構造的シグナル」としての`RANGE_BREAK`は未検証のまま（本データでは出番がなかった）。

  **残存する根本問題**: MFE/MAE（修正済み追跡データ）を突き合わせたところ、Fold5の5敗全てで、決済時点のpnlがMAEに対して平均**71.2%**の水準（49〜89%）に達していた時点で決済されており、これは旧ロジックの`RANGE_FILTER_RELEASED`時点の平均73.5%とほぼ同水準だった。**強制決済のトリガー条件を変更しても、「決済がほぼ最悪値近辺で発動する」という非対称な問題自体は解消されていない**。Fold1のticket94はMFE 4,903まで含み益を伸ばした後、`MEAN_REVERSION_MAX_HOLDING_BARS`（20本経過）まで持ち越されて-4,773の損失で終わっており、含み益を保全する仕組みが無いまま反転を許している典型例。

  **総合評価: 今回の再設計は、決済条件を「弱いシグナル（閾値跨ぎ1本）」から「より強いシグナル（ADX急伸・実際のレンジ構造ブレイク）」へ変更するという方向性は妥当であり、Fold5では取引数・損失額とも縮小し合算パフォーマンスも改善した。しかし核心的な問題（決済がMAE近辺まで引きずられてから発動する非対称性）は未解決であり、MR単体の勝率は両区間とも0%（n=2、n=5と極めて少数）のままである。** 取引数が大幅に減ったことでサンプルがさらに小さくなり、本ラウンドの結論の頑健性は前回以上に低い。

  **残存課題**:
  1. n=2・n=5という極めて少数のサンプルであり、勝率0%という結果を含め、統計的な結論を出すには他Foldでの追試が必須。
  2. `RANGE_BREAK`が両区間で1度も発動しておらず、この条件の実効性自体が未検証。より長い/別の期間で発動事例を集める必要がある。
  3. 決済のタイミングがMAE近辺に偏る根本問題（前回ラウンドで指摘、今回も再現）は未解決。前回提案した「MFE_Rに応じた早期の部分利確・建値化」等、含み益保全の仕組みを別途検討する必要があるが、これも未検証の仮説。
  4. `InpEnableMeanReversionStrategy`は既定値`false`（無効）のまま据え置き、EA既定値・Tester ini構成のいずれにも変更を適用していない。

* [x] **強制決済条件を「CI<50 OR ADX>30」相当（ADX_SURGE、上昇中要求）から「CI<50 AND ADX>30」（新設`RANGE_QUALITY_LOST`、上昇中要求を削除）へ変更する（ユーザー依頼、2026-08-24実施）。** ユーザー確認により、既存の`ADX_SURGE`を置き換える変更として実装した。`CMeanReversionExitRules::IsRangeQualityLost(choppiness,adx,choppiness_max,adx_min)`を新設し、`choppiness<choppiness_max && adx>adx_min`のAND条件のみで判定する（「上昇中」要求は削除）。新規config `mean_reversion_forced_exit_choppiness_max`（既定50.0）を追加、既存`mean_reversion_forced_exit_adx_threshold`（既定30.0）を流用。

  変更ファイル: `mt5/Include/Strategy/MeanReversionStrategy.mqh`（`IsAdxSurging`を`IsRangeQualityLost`へ置換、`IsRangeStillValid`のロジック更新）・`mt5/Include/Core/Config.mqh`（`mean_reversion_forced_exit_choppiness_max`追加）・`mt5/Experts/CoreEA.mq5`（`InpMeanReversionForcedExitChoppinessMax`追加）・`docs/configuration.md`・`mt5/Tests/TestTrendFollowingRules.mq5`（テスト更新、6アサーション）。MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS。

  **【重要】検証中に、この変更とは独立した既存の監査ログバグを発見した。** `EAController::OnTradeTransaction()`が`HistoryDealGetInteger(deal,DEAL_MAGIC)!=m_config.magic_number`（トレンド戦略の主Magic Numberのみ）でフィルタしており、`mean_reversion_magic_number`を考慮していない（初回コミットから存在する構造的な不備、レンジ戦略追加時に未更新）。`m_pending_closed_positions`（`TRADE_CLOSED`監査イベントの生成元）はこの同じフィルタの内側でのみ積まれるため、**レンジ戦略のポジションがSL/TPヒット（ブローカー側の自動決済）で決済された場合、`DEAL`・`TRADE_CLOSED`・`TRADE_ANALYTICS`の監査イベントが一切記録されない**。一方、EA自身が`CloseOnSignalInvalidation`/`CloseOnTimeStop`で能動的に決済した場合（`RANGE_BREAK`・`RANGE_QUALITY_LOST`・`BB_WIDTH_EXPANSION`・`MEAN_REVERSION_MAX_HOLDING_BARS`）は、決済リクエストがEA自身の呼び出しで完結するため`DEAL_MAGIC`が同期的に確定し、正しく記録される（`RANGE_EXIT`監査イベント自体は`OnTradeTransaction`を経由しない別経路のため、この不具合の影響を受けない）。

  Fold5 Train（AND条件版）でMR CANDIDATE 26件・OrderSubmission 25件accepted・`RANGE_EXIT`イベント0件・`TRADE_CLOSED`（pattern=MEAN_REVERSION）0件という不自然な結果から発覚。Strategy Testerの生ログ（`TRADE_DEAL`行）とTester .htmレポートの総損益を突き合わせて検証した結果、25件全てのMRポジションが実際には正常にSL/TP等で決済されており（.htm総損益123,205円と、監査ログ由来のトレンドのみ集計166,737円との差-43,532円が、行方不明だったMR分の実際の純損益と一致）、**EAの発注・リスク管理・決済処理自体は正しく機能しているが、監査ログ（ローカルJSONL）だけが該当分を欠落させていた**ことを確認した。

  **本セッションのMean Reversion戦略関連の分析全般への影響**: この不具合は本ラウンドで新たに発覚したが、`OnTradeTransaction`のロジック自体は初回コミットから不変であり、レンジ戦略を検証した過去のラウンド（II案実装以降の全ラウンド）は同一の欠落を抱えていたと考えられる。特に、EA強制決済（`RANGE_EXIT`）で決済された取引は相対的に記録されやすく、SL/TPで自然決済された取引（利益が伸びたトレードを含む可能性が高い）が相対的に記録されにくいという**非ランダムな欠落パターン**であるため、過去に報告した勝率・PF・取引数（特に「MR勝率0%」「RANGE_FILTER_RELEASED支配的」等の結論）は、実際の取引全体ではなく、EA強制決済で捕捉できた一部の取引のみに基づいていた可能性が高く、**過小・偏った推定だった**と考えられる。ただし、`RANGE_EXIT`イベント自体が示す「捕捉できた強制決済の理由内訳」自体は正しい（別経路のため）。

  **Strategy Tester生ログとの突合により再構成した正しい実績（Fold1・Fold5 Train、変更前後）**:

  | 区間 | 強制決済ロジック | MR取引数 | MR純損益 | MR勝率 | 合算取引数 | 合算純損益 |
  |---|---|---|---|---|---|---|
  | Fold1 Train | ADX_SURGE（変更前） | 12 | -12,507円 | 58.3% | 51（+1件保有中） | +17,919円 |
  | Fold1 Train | RANGE_QUALITY_LOST（AND、変更後） | 12 | **-20,915円** | 58.3% | 51（+1件保有中） | +8,815円 |
  | Fold5 Train | ADX_SURGE（変更前） | 25 | -45,526円 | 56.0% | 118 | +121,265円 |
  | Fold5 Train | RANGE_QUALITY_LOST（AND、変更後） | 25 | **-43,532円** | 64.0% | 118 | **+123,205円**（Tester .htm総損益と完全一致） |

  取引数・エントリー条件は変更していないため両ロジックで同数（12件・25件）。AND条件への変更は、Fold5では純損益・勝率とも改善（-45,526→-43,532円、56%→64%）した一方、Fold1では悪化した（-12,507→-20,915円、勝率は同数7勝のまま損失側の損切りが深くなった）。**方向性は区間により逆転しており、一貫した改善効果があるとは言えない。**

  **総合評価: 今回のAND条件変更自体は実装・テストとも問題ない。しかし、本ラウンドで発見した監査ログ欠落バグは、これまでのMean Reversion戦略検証（II案実装以降の全ラウンド）の信頼性に疑義を生じさせる重大な問題であり、優先的な対応が必要と判断する。** 実際の売買判断・発注・リスク管理・SL/TP執行は正しく機能しており安全性への影響はないが、分析・意思決定の根拠となってきた集計値（勝率・PF・純損益・RANGE_EXIT理由別内訳の分母）の多くが不正確だった可能性が高い。

  **残存課題**:
  1. `OnTradeTransaction`の`DEAL_MAGIC`フィルタを`mean_reversion_magic_number`にも対応させる修正が必要（未実施、対応方針をユーザーに確認してから着手する）。
  2. 修正後、II案（サイジングのレジーム適応、影響なし・adaptive sizingは別ガード）を除く、Mean Reversion戦略に関わる過去ラウンドの結論（Choppiness閾値スイープ、閾値60での損失原因分析、ADX_SURGE版の強制決済検証等）を再検証する必要がある。
  3. Telemetry（HTTP送信）がこの監査ログと同じ経路の影響を受けるかは未確認（`InpTelemetryEnabled=false`のTester実行のため、本ラウンドでは検証できていない）。
  4. `InpEnableMeanReversionStrategy`は既定値`false`（無効）のまま据え置き、EA既定値・Tester ini構成のいずれにも変更を適用していない。

* [x] **`OnTradeTransaction`の`DEAL_MAGIC`フィルタを`mean_reversion_magic_number`にも対応させ、過去のMR関連ラウンドを再検証する（ユーザー依頼、2026-08-25実施）。** `CPositionProtectionRules::IsManagedPosition`の3引数版（既存、プライマリ/セカンダリいずれかに一致すれば管理下と判定）を用い、`HistoryDealGetInteger(deal,DEAL_MAGIC)!=m_config.magic_number`という単純比較を`IsManagedPosition(magic,m_config.magic_number,m_config.mean_reversion_magic_number)`へ置換した。変更ファイル: `mt5/Include/Core/EAController.mqh`のみ（1箇所）。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS。`.\tools\release-gate.ps1 -Mode Development`（必須文書・秘密情報・JSON contracts・Python 119件・MQL5コンパイル・Script Test）全PASS。後方互換性: `InpEnableMeanReversionStrategy=false`でFold5 Trainを再実行し、取引数93・純損益+171,860円がII案実装当初の基準値と完全一致（`results/backtests/20260824-235401-USDJPY-H1/`）。効果確認: `InpEnableMeanReversionStrategy=true`（既定閾値60）でFold1・Fold5 Trainを再実行し、MR取引数（Fold1:12件、Fold5:25件）・純損益が、Strategy Tester生ログ（`TRADE_DEAL`）から独立に再構成した正しい値（前回ラウンドで算出）と完全一致することを確認した（Fold5合算純損益+123,205円はTester .htm総損益と一致、`results/backtests/20260825-000323-USDJPY-H1/`・`20260825-000853-USDJPY-H1/`）。**修正後は`DEAL`・`TRADE_CLOSED`・`TRADE_ANALYTICS`・`RANGE_EXIT`のいずれもMRポジションを漏れなく記録することを確認した。**

  **過去のMR関連ラウンドの再検証（Choppiness閾値スイープ、修正済み監査ログで再実行）**:

  | 区間 | 閾値 | MR取引数 | MR純損益 | MR勝率 | MR PF | 合算純損益 |
  |---|---|---:|---:|---:|---:|---:|
  | Fold1 Train | 30 | 97 | +14,477円 | 55.7% | 1.052 | +44,213円 |
  | Fold1 Train | 35 | 91 | +10,345円 | 58.2% | 1.037 | +40,081円 |
  | Fold1 Train | 40 | 80 | -34,195円 | 57.5% | 0.870 | -5,132円 |
  | Fold1 Train | 45 | 59 | -22,521円 | 62.7% | 0.894 | +7,669円 |
  | Fold1 Train | 50 | 40 | -72,612円 | 55.0% | 0.576 | -43,901円 |
  | Fold1 Train | 55 | 23 | +5,891円 | 69.6% | 1.092 | +36,039円 |
  | Fold1 Train | 60（既定） | 12 | -20,915円 | 58.3% | 0.530 | +8,815円 |
  | Fold5 Train | 40 | 34 | -37,587円 | 55.9% | 0.701 | -18,241円 |
  | Fold5 Train | 50 | 36 | -62,998円 | 52.8% | 0.586 | -35,576円 |
  | Fold5 Train | 60（既定） | 25 | -43,532円 | 64.0% | 0.530 | +123,205円 |

  **旧報告（監査ログ欠落バグの影響下）との比較で判明した誤り**: 旧報告では「MR勝率0〜29%」「閾値を緩めるほど単調に悪化」としていたが、修正後の正しいデータでは**MR勝率は全閾値で52〜70%**であり、「勝率0%」は誤りだった（EA強制決済で捕捉できていた少数の取引だけが低勝率に偏っていたため）。また「単調悪化」という傾向も再現せず、**両区間・全閾値でMR純損益・PFは閾値に対して非単調（ノイズ状）に変動する**ことが判明した。「閾値を緩める方向は完全に反証された」という前回の結論は撤回する。

  **閾値60での損失原因の再分析（正しいデータで再実施）**: Fold5 Train（n=25、修正済みRANGE_EXIT・TRADE_ANALYTICS）を精査したところ、**25件全てがSL（9件）またはTP（16件）で直接決済されており、`RANGE_QUALITY_LOST`・`RANGE_BREAK`・`BB_WIDTH_EXPANSION`のいずれも一度も発動していなかった**（AND条件化により強制決済がほぼ発動しなくなったことの裏付け）。旧報告の「決済がMAE近辺まで引きずられる非対称性」という説明は、実際には母数の94%（117件中94件、旧集計での「行方不明」分）を欠いた状態での誤った結論であり、撤回する。

  正しい損失原因は、**Take Profit（BB中心線）とStop Loss（Band外側+ATRバッファ）の非対称なリスクリワード比**である。平均利益 = 49,075円÷16件 = 3,067円、平均損失 = 92,607円÷9件 = 10,290円で、**平均損失は平均利益の約3.35倍**。64%という高い勝率にもかかわらず、1回あたりの損益サイズの非対称性だけでPF0.530（正味-43,532円）まで悪化している。これはBB中心線（basis、Band幅の中央）がBand外側+ATRバッファ（SL）よりも構造的にエントリー価格に近いことに起因する、設計上のリスクリワード問題であり、Choppiness閾値の調整では解決しない。

  **総合評価: 監査ログ欠落バグの修正により、過去のMR戦略検証の結論の多くが不正確だったことが判明した。修正後のデータでは、MR戦略単体は「勝率は高いが1回あたりの損益が非対称（TPが近すぎる）」という、これまでとは全く異なる性質の課題を抱えていることが分かった。** Choppiness閾値・ADX関連の強制決済条件の調整は、少なくとも閾値60ではほぼ意味を持たない（強制決済が実質発動しないため）。

  **残存課題**:
  1. TP方式（`InpMeanReversionTakeProfitMode`、既定`MEAN_REVERSION_TP_BB_MIDDLE`）を`MEAN_REVERSION_TP_OPPOSITE_BAND`（反対側Band、より遠いTP）へ変更した場合にリスクリワード比が改善するかは未検証。
  2. SL幅（`InpMeanReversionStopAtrMultiple`、既定1.0）を狭める、またはTPをより遠くする、のいずれかがPF改善に有効かは未検証であり、Train区間での個別検証が必要。
  3. Choppiness閾値スイープの非単調性の原因（区間・閾値ごとに異なる相場構成による可能性）は未分析。
  4. Telemetry（HTTP送信）が同じ監査経路の影響を受けていたかは引き続き未確認（`InpTelemetryEnabled=false`のTester実行のため）。
  5. `InpEnableMeanReversionStrategy`は既定値`false`（無効）のまま据え置き、EA既定値・Tester ini構成のいずれにも変更を適用していない。全結果は未コミット。

* [x] **強制決済条件をレンジ相場判定（エントリー条件と同一のCI/ADX閾値）へ復帰し、TP方式を`MEAN_REVERSION_TP_OPPOSITE_BAND`へ変更して再検証する（ユーザー依頼、2026-08-25実施）。**

  **強制決済条件の復帰**: `CMeanReversionExitRules::IsRangeQualityLost`（専用閾値によるAND条件）を削除し、`IsRangeStillValid`の該当箇所を`CMeanReversionEntryRules::IsRangeFilterActive(choppiness,adx,m_config.mean_reversion_choppiness_min,m_config.mean_reversion_adx_max)`の否定（reason_code=`RANGE_FILTER_RELEASED`）へ復帰した。あわせて、不要になった専用config `mean_reversion_forced_exit_adx_threshold`・`mean_reversion_forced_exit_choppiness_max`（struct・既定値・validation・`InpMeanReversionForcedExitAdxThreshold`/`InpMeanReversionForcedExitChoppinessMax`入力）を削除した。`RANGE_BREAK`（スイング高安値ベース）・`BB_WIDTH_EXPANSION`は変更していない。

  変更ファイル: `mt5/Include/Strategy/MeanReversionStrategy.mqh`・`mt5/Include/Core/Config.mqh`・`mt5/Experts/CoreEA.mq5`・`docs/configuration.md`・`mt5/Tests/TestTrendFollowingRules.mq5`（`IsRangeQualityLost`用6アサーション削除、Range Filter解除判定は冒頭の`IsRangeFilterActive`アサーションで引き続きカバー）。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS・`.\tools\release-gate.ps1 -Mode Development`全PASS。後方互換性: `InpEnableMeanReversionStrategy=false`でFold1 Trainを再実行し、取引数39・純損益+30,801円が既知の基準値と完全一致（`results/backtests/20260825-014833-USDJPY-H1/`、config構造体からのフィールド削除が既存挙動へ影響しないことを確認）。

  **TP方式変更**: `InpMeanReversionTakeProfitMode=1`（`MEAN_REVERSION_TP_OPPOSITE_BAND`）をTester ini上書きで指定し、強制決済条件の復帰版・変更前（BB Middle）双方と比較した。

  **再検証結果（Fold1・Fold5 Train）**:

  | 区間 | 強制決済条件 | TP方式 | MR取引数 | MR純損益 | MR勝率 | MR PF | RANGE_EXIT率 |
  |---|---|---|---:|---:|---:|---:|---:|
  | Fold1 Train | RANGE_QUALITY_LOST（変更前） | BB Middle | 12 | -20,915円 | 58.3% | 0.530 | 0%（0/12） |
  | Fold1 Train | RANGE_FILTER_RELEASED（復帰後） | BB Middle | 12 | **-9,863円** | 58.3% | 0.637 | 33%（4/12） |
  | Fold1 Train | RANGE_FILTER_RELEASED（復帰後） | Opposite Band | 13 | -21,468円 | 46.2% | 0.471 | 54%（7/13） |
  | Fold5 Train | RANGE_QUALITY_LOST（変更前） | BB Middle | 25 | -43,532円 | 64.0% | 0.530 | 0%（0/25） |
  | Fold5 Train | RANGE_FILTER_RELEASED（復帰後） | BB Middle | 25 | **-31,711円** | 48.0% | 0.407 | 56%（14/25） |
  | Fold5 Train | RANGE_FILTER_RELEASED（復帰後） | Opposite Band | 28 | -37,224円 | 32.1% | 0.531 | 71%（20/28） |

  **強制決済条件を戻したことによる影響（ユーザー質問への回答）**: 明確な問題は確認されなかった。むしろ、**両区間ともMR純損益が改善した**（Fold1: -20,915→-9,863円、Fold5: -43,532→-31,711円）。勝率は低下した（Fold1は同率、Fold5は64.0%→48.0%）が、`RANGE_FILTER_RELEASED`がエントリー直後の弱いレンジ状態を早期に検知して損失を小さいうちに打ち切るため、深いSL到達（1件あたり平均-10,290円）を一部回避できたことが要因と考えられる（勝率は下がるがPFは改善、Fold1: 0.530→0.637、Fold5: 0.530→0.407で悪化＝区間により効果が異なる点には注意）。取引数はFold1・Fold5とも変化なし（12件・25件、エントリー条件は変更していないため）。

  **TP方式変更（反対側Band）の効果**: **両区間で悪化した**（Fold1: -9,863→-21,468円、Fold5: -31,711→-37,224円）。原因は、`RANGE_FILTER_RELEASED`を強制決済条件へ復帰させたことで、より遠いTP（反対側Band）に到達する前にレンジ状態が解除され強制決済される頻度が増加したため（RANGE_EXIT率: Fold1 33%→54%、Fold5 56%→71%）。TPを遠くしても、その前に強制決済で刈り取られてしまい、狙った利幅を享受できていない。

  **総合評価: 強制決済条件をレンジ相場判定へ戻すこと自体は両区間で純損益を改善させた（勝率低下と引き換えに大きな損失を回避する効果）。一方、TP方式の変更（反対側Bandへ）は、強制決済条件との相互作用により両区間で悪化した。** 「エントリー条件と強制決済条件を分離する」という前回の設計変更は、少なくとも今回の2区間では純損益の面で悪化要因だったことになる。TP距離を伸ばす調整は、強制決済がエントリー条件と連動している現在の設計とは相性が悪く、両立させるには別のアプローチ（例: 強制決済とは独立した最小保有時間の確保、TP距離とRange Filterの持続性を踏まえた設計）が必要と考えられる。

  **残存課題**:
  1. MR単体は依然として全ケースでPF<1（0.407〜0.637）であり、今回の2種類の変更のいずれもMR戦略を黒字化するには至っていない。
  2. TP方式変更の悪化は強制決済条件との相互作用による可能性が高いが、強制決済条件を無効化した状態でのTP方式単体の効果は未検証。
  3. SL幅（`InpMeanReversionStopAtrMultiple`）の調整は依然未検証。
  4. Choppiness閾値スイープの非単調性の原因は未分析のまま。
  5. Telemetry（HTTP送信）が監査ログと同じ経路の影響を受けていたかは引き続き未確認。
  6. `InpEnableMeanReversionStrategy`は既定値`false`（無効）のまま据え置き、EA既定値・Tester ini構成のいずれにも変更を適用していない。全結果は未コミット。

* [x] **強制決済条件とレンジ相場判定の分離設計（コード構造）を維持する（ユーザー依頼、2026-08-25実施）。** 前タスクの復帰作業で`IsRangeStillValid`が`CMeanReversionEntryRules::IsRangeFilterActive`を直接呼び出す実装になっており、エントリー側クラスへの直接依存が生じていた（2026-08-24に導入した「エントリー条件とはコード上も明確に分離する」設計原則から逸脱）。`CMeanReversionExitRules`へ`IsRangeFilterReleased(choppiness,adx,choppiness_min,adx_max)`を新設し、`IsRangeStillValid`はこちらを呼ぶよう変更した。**config閾値（`mean_reversion_choppiness_min`/`mean_reversion_adx_max`）はエントリー条件と共用のまま**（前タスクの検証で共用の方が両区間とも純損益が改善したため、値自体は分離しない）。エントリー側クラスへの直接呼び出しをなくし、決済判断ロジックが`CMeanReversionExitRules`内で完結する構造のみを復元した。

  変更ファイル: `mt5/Include/Strategy/MeanReversionStrategy.mqh`（`IsRangeFilterReleased`新設、`IsRangeStillValid`の呼び出し先変更、クラスコメント更新）・`mt5/Tests/TestTrendFollowingRules.mq5`（`IsRangeFilterReleased`の単体テスト4件追加: Choppiness低下・ADX上限到達・両条件維持時に解除されないこと・NaN ADXでのfail-safe close）。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS（新規4アサーション含む）。Fold5 Trainを再実行し、取引数25・純損益-31,711円・勝率48.0%が、リファクタ前（エントリー側クラスへ直接依存していた版）の結果と完全一致することを確認し、純粋な構造変更（挙動に影響しない）であることを実証した（`results/backtests/20260825-020748-USDJPY-H1/`）。

  **残存課題**: 前タスクの残存課題（TP方式単体効果の切り分け、SL幅調整、Choppiness閾値スイープの非単調性）は未着手のまま。`InpEnableMeanReversionStrategy`は既定値`false`のまま、全結果未コミット。

* [x] **強制決済のパラメータをエントリー条件とは独立に指定したいというユーザー要望により、直前タスクで削除した`IsRangeQualityLost`（専用閾値によるAND条件判定）を復元する（2026-08-25実施）。** `IsRangeFilterReleased`（エントリーとconfig閾値を共用する方式）を削除し、`IsRangeQualityLost(choppiness,adx,choppiness_max,adx_min)`と、専用config`mean_reversion_forced_exit_adx_threshold`（既定30.0）・`mean_reversion_forced_exit_choppiness_max`（既定50.0）を復元した。`IsRangeStillValid`の判定順序も、削除前の実装（`RANGE_BREAK`→`RANGE_QUALITY_LOST`→`BB_WIDTH_EXPANSION`）へ復帰した。

  変更ファイル: `mt5/Include/Strategy/MeanReversionStrategy.mqh`（`IsRangeQualityLost`復元・`IsRangeStillValid`の呼び出し先と判定順序を復帰）・`mt5/Include/Core/Config.mqh`（専用config 2件復元）・`mt5/Experts/CoreEA.mq5`（`InpMeanReversionForcedExitAdxThreshold`/`InpMeanReversionForcedExitChoppinessMax`復元）・`docs/configuration.md`・`mt5/Tests/TestTrendFollowingRules.mq5`（`IsRangeQualityLost`用6アサーション復元）。

  **検証**: MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS（復元した6アサーション含む）。Fold5 Trainを再実行し、取引数25・純損益-43,532円・勝率64.0%・PF0.530が、削除前の`IsRangeQualityLost`実装時の実績と完全一致することを確認した（`results/backtests/20260825-022710-USDJPY-H1/`）。

  現状のパラメータ（強制決済: Choppiness<50かつADX>30、エントリー: Choppiness≥60かつADX<25）では、直前タスクで検証したとおり強制決済が実質発動しない（0/25件）ため、現行の既定値のままでは「パラメータ分離」の効果はまだ現れていない。分離された`InpMeanReversionForcedExitChoppinessMax`/`InpMeanReversionForcedExitAdxThreshold`を、エントリー閾値とは異なる値へ個別にチューニングする余地が生まれた、という点が本タスクの主な意味である。

  **残存課題**: 分離されたパラメータをどのように調整すべきかは未検証（本タスクは復元のみ、チューニングは未実施）。前タスクまでの残存課題（TP方式単体効果の切り分け、SL幅調整、Choppiness閾値スイープの非単調性）も未着手のまま。`InpEnableMeanReversionStrategy`は既定値`false`のまま、全結果未コミット。

* [x] 監査ログ汚染バグの影響を受けていた可能性がある分析（Buy/Sell・時間帯・曜日・相場レジーム・ATR帯・ADX帯別の有意差分析）を再検証する（2026-08-22実施。`InpEntryUseStagedPipeline=false`（Buy/Sell等の分析時点の構成）へ一時的に戻し、修正済み`tools/run-strategy-tester.ps1`で同一IS期間を再実行（`results/backtests/20260822-195446-USDJPY-H1/`）。**検証手順**: (1) 純損益-48,223円・PF0.89・Sharpe-1.10・取引数209がベースラインと完全一致することを確認。(2) `InpEntryUseStagedPipeline=false`で実行したにもかかわらず`ENTRY_PIPELINE`イベント（staged pipeline有効時のみ記録されるはずの診断ログ）が0件であることを確認し、前回発見した汚染（他run由来の`ENTRY_PIPELINE`混入）が本runには存在しないことを確認。(3) `trade_breakdown`を再実行し、direction/session/weekday/market_regime_trend/market_regime_volatility/atr_band/adx_bandの全内訳が、既報の値（Buy/Sell・時間帯・曜日別分析および相場レジーム別分析の回でそれぞれ報告した数値）と完全一致することを確認。**結論: Buy/Sell・時間帯・曜日・相場レジーム（トレンド/ボラティリティ）・ATR帯・ADX帯別の分析結果はいずれも汚染の影響を受けておらず、既報の「統計的に有意な勝率差は確認できなかった」という結論は有効**。汚染が実際に混入していたのは`InpRegimeTrendAdxMin`スイープの40番run（`20260822-181739`）のみであり、これは前タスクで既に修正済みツールにより再実行・再評価済み（`20260822-183152`、結果は変化なし）。

  **副次的な重要発見（バグではなく仕様どおりの安全機構）**: 本re-verification中、監査ログの`TRADE_CLOSED`/`DEAL`/`ORDER_SUBMISSION`が2019-04-29で止まる一方、`CANDIDATE`/`RISK_DECISION`はIS期間全体（〜2020-12-30）にわたって記録され続けている現象を発見。調査したところ、2019-05-01以降の`RISK_DECISION`391件はすべて`REJECTED`/`reason_code=DD_LIMIT`（最大ドローダウン制限）であり、Risk Managerの安全機構が正しく発動し、以降の新規注文を意図どおり永続的に拒否し続けていたことが判明した（`InpMaxDrawdownPercent`既定10%、多くのrunのTester .htmレポートで`max_drawdown_pct=10%`と一致）。**これはバグではなく設計どおりの安全動作**だが、本セッションで報告してきたIS期間の各種指標（取引数・純損益等）の一部は、実際には2017-09〜2020-12の全期間ではなく、DD_LIMIT発動までの実質的なより短い期間（現行最良状態の場合は2017-09〜2019-04の約1.6年）における結果である可能性がある。ADX≥40のような高収益設定ではDD_LIMITが発動せず全期間（2017-09〜2020-12）にわたって取引が継続していることを別途確認済み（`results/backtests/20260822-183152-USDJPY-H1/`のTRADE_CLOSEDタイムスタンプ範囲）。この点はWalk Forward各Fold実行時・OOS検証時に留意する必要がある（DD_LIMIT発動の有無・時期をFoldごとに確認することを推奨）。
* [x] **Entryタイミング自体の妥当性を検証できるよう、Entry Timing比較分析機能を実装する（ユーザー依頼、2026-08-22実施）。** 同一のプルバックSetupについて、IMMEDIATE（即時Entry）・WAIT_1_BAR（1本待ち）・WAIT_2_BARS（2本待ち）・WAIT_TRIGGER（Trigger成立待ち）の4方式を実注文なしのShadow Tradeとして並行シミュレートする新規`CEntryTimingAnalyzer`（`mt5/Include/Logging/EntryTimingAnalyzer.mqh`）を追加した。既存Strategy/PositionManager/RiskManager/OrderManagerから完全に独立した自己完結モジュールとし（実注文を一切生成しない、既存の売買判断には一切影響しない）、新規input `InpEnableEntryTimingAnalysis`（既定値`false`、無効時はIndicatorハンドルすら作成せずコスト0）・`InpEntryTimingMaxWaitBars`（既定6）・`InpEntryTimingMaxHoldingBars`（既定20）で制御する。ブレイクアウトパターンはSetupとTriggerが同一の価格事象でありSetup/Trigger間に待機できる中間状態が存在しないため、プルバックのみを対象とした（詳細は`DECISIONS.md` DEC-028）。各Variantの結果（entry_price/SL/TP/wait_bars/bars_held/MFE・MAE(R倍数)/exit_reason/pnl_r(R倍数)/Entry後1・2・3・5・10・20本時点の価格推移R倍数）を新規監査イベント`ENTRY_TIMING_TRADE`へ、Setup成立からEntry確定までの逆行・順行（pre_entry_mae_r/pre_entry_mfe_r、到達時刻付き）とTrigger成立可否を`ENTRY_TIMING_SETUP`へ記録する。新規`python/analysis/entry_timing.py`（`variant_summary()`でVariant別Trades/Win Rate/Profit Factor/Expectancy/Net Profit/Max Drawdown（すべてR倍数、既存`drawdown.py`を再利用）/平均MFE・MAE/価格推移チェックポイント平均を集計、`pre_entry_excursion_summary()`で逆行・順行とTrigger成立率を集計）・`contracts/entry-timing-report.schema.json`・単体テスト7件を追加。過去データへ最も適合する待機方式を自動採用する処理は実装していない（4方式を常に並行記録するのみ、優劣判断はユーザーの分析に委ねる）。

  MQL5コンパイル（10ターゲット、0 errors/0 warnings）・9 Script Test全PASS（新規`TestEntryTimingAnalyzer`、39アサーション全PASS、他既知事象と同じTerminal Exit Code 1のみ）・Python単体テスト105件全PASS（新規7件含む）で検証済み。実データ検証として2018-01〜2018-06（`USDJPY_HIST`、`InpEnableEntryTimingAnalysis=true`）でStrategy Testerを実行し、145 Setup・523 Shadow Tradeが記録され`python.analysis.entry_timing`が正常にレポートを生成することを確認した（`results/backtests/20260822-214842-USDJPY-H1/`）。同区間でIMMEDIATE（win_rate 47.6%・PF1.13・net_profit +9.23R）→WAIT_1_BAR（PF1.07）→WAIT_2_BARS（PF0.99）→WAIT_TRIGGER（win_rate 42.0%・PF0.86・net_profit -6.55R）と、待機するほど成績が悪化する一貫した傾向が観測されたが、これは6か月間・単一区間のみのサンプルであり、正式なIS/OOS期間での分析はまだ実施していない（あくまで機能実証目的の暫定観測）。実装過程で、Setup完了イベントの`trigger_wait_bars`が実際のShadow Tradeの`wait_bars`と食い違う実装バグ（完了イベント出力が後続バーへずれる場合に発生）を発見・修正済み（詳細はDEC-028）。`InpEnableEntryTimingAnalysis=false`（既定値）ではENTRY_TIMING_*イベントが一切記録されないこと、既存の`trade_breakdown`分析パイプラインが新規イベント型と混在しても正常動作することも実データで確認済み。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] Entry Timing比較分析を正式なIS期間（2017-09〜2020-12）で実行し、Entryタイミングの妥当性を検証する（2026-08-22実施。既知の最良状態（Trend+H1 ADXのみ全条件完全決済・建値ストップ・StopAtrMultiple/RR=2.0・Time Stop有効・`InpRegimeTrendAdxMin=40`）の上で`InpEnableEntryTimingAnalysis=true`（`InpEntryTimingMaxWaitBars=6`・`InpEntryTimingMaxHoldingBars=20`、いずれも既定値）を追加して実行。MQL5コンパイル（10ターゲット）・9 Script Test全PASS確認済み。Shadow Trade専用機能のため実際の売買結果（純損益+15,511円・PF1.09・Sharpe+0.80・取引数77）は`InpEnableEntryTimingAnalysis`追加前と完全一致し、影響がないことを確認した。

  **`python/analysis/entry_timing.py`の不具合を発見・修正**: 正式なIS期間の実データ（Setup 1,101件）で`python.analysis.entry_timing`を実行したところ、Max Drawdown基準値（`DRAWDOWN_BASELINE_R`、当時100R）を、IMMEDIATE/WAIT_1_BAR/WAIT_2_BARSの累積損益（それぞれ-110.27R/-117.59R/-99.16R）が下回りequityが0以下になったため、`drawdown.build_drawdown_curve`の安全チェック（実資金の破産に相当する不正値として例外送出）がトリップした。サンプル期間（2018-01〜2018-06、6か月）では累積損失がこの規模に達しておらず潜在化していた。基準値を10,000Rへ引き上げて修正（相対指標という設計意図は維持）。`python/tests/test_entry_timing.py`（7件）は修正後も全PASS。`DECISIONS.md` DEC-028へ追記済み。

  | Variant | Trades | 勝率 | PF | 期待値(R) | 純損益(R) | 最大DD(R) |
  |---|---:|---:|---:|---:|---:|---:|
  | IMMEDIATE | 1,101 | 38.1% | 0.82 | -0.100 | -110.27 | 130.43 |
  | WAIT_1_BAR | 1,101 | 37.7% | 0.81 | -0.107 | -117.59 | 140.93 |
  | WAIT_2_BARS | 1,101 | 38.9% | 0.84 | -0.090 | -99.16 | 133.68 |
  | **WAIT_TRIGGER** | 597 | **40.9%** | **0.94** | **-0.033** | **-19.54** | **45.93** |

  Setup観測数1,101件のうちTrigger成立は597件（54.2%）。Setup成立からEntryまでの平均逆行(MAE)は-0.63R、平均順行(MFE)は+0.47R。

  **評価: WAIT_TRIGGER（Trigger＝再加速の成立を待つ方式）が、勝率・PF・期待値・純損益・最大DDのすべての指標で他3方式を明確に上回った**。IMMEDIATE〜WAIT_2_BARSの3方式は互いに大差なく（PF0.81〜0.84）、固定本数の待機自体には価値がなく、「再加速の確認」という質的な条件こそが重要であることを示唆する。現行の実戦略（`CTrendFollowingStrategy`）はタッチ足(shift2)・確認足(shift1)の固定1本ギャップでTrigger相当の確認を行っており、本分析の柔軟なWAIT_TRIGGER（Setup後最大6本まで待機）とは厳密には同一の定義ではないが、方向性としては同じ「確認を待つ」設計であり、**これを支持する結果**である。

  **重要な注意点（サンプル期間との比較）**: 実装検証時のサンプル期間（2018-01〜2018-06、6か月）では、待機するほど成績が悪化する**正反対の傾向**（IMMEDIATE PF1.13が最良、WAIT_TRIGGER PF0.86が最悪）が観測されていた。正式なIS期間（3年超、Setup数1,101件）ではこの順位が完全に逆転しており、6か月という短い観測期間の結果が全期間の傾向を代表しないことを如実に示している。これはWalk Forward各Foldの評価期間（1年）でも同様の不安定性が起こりうることを示唆しており、単一Foldの結果だけで判断せず複数Fold・OOS全体での安定性を確認する必要がある。

  また、本分析はSL/TP幾何のみのShadow Tradeであり、建値ストップ・シグナル失効Exit・Time Stop・ADXレジームフィルタ等、実戦略が持つExit管理・Entry追加フィルタを一切含まないため、WAIT_TRIGGER単体でもPF0.94と1未満である点は実戦略のPF1.09と単純比較できない（Entry timingという単一要因を切り出した分析であり、比較対象が異なる）。

  **総合評価: Entryタイミングは「確認を待つ」現行方針が妥当であることが、より頑健な正式IS期間のデータで支持された。次の一手候補**: (a) 現行のTrigger確認方式を維持する（推奨、追加調整は不要）、(b) `InpEntryTimingMaxWaitBars`をスイープしTrigger成立率とPFのトレードオフを確認する、(c) 現行戦略のタッチ足・確認足の固定1本ギャップを、本分析のWAIT_TRIGGERのような柔軟な待機（複数本まで探索）へ変更する仮説をさらに検証する（ただし6か月サンプルとの逆転が示すとおり過学習リスクがあるため、OOS/Walk Forwardでの確認を経ずに実戦略へ適用しない）。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] コスト感応度分析（Spread/Commission/Swap/Slippage）を、OANDA証券での運用を想定した設定で正式なIS期間（2017-09〜2020-12）に対し実施する（2026-08-22実施。**OANDA証券のコスト条件確認**: 公式サイト（[oanda.jp/course](https://www.oanda.jp/course)）をWebFetchで確認し、MT5対応の東京サーバー2コース（裁量プラン・スタンダードプラン）はいずれも取引手数料無料（Commission=0円）であることを確認。`USDJPY_HIST`は`CustomSymbolCreate`でOANDA接続時点の実`USDJPY`からSpread（実tick）・Swap仕様を複製済みのため、既存のStrategy Tester設定（Commission=0円が既定）が既にOANDA証券の実態を反映しており、追加のコスト条件変更は不要と判断した（詳細は3.1節「Spread、Commission、Swap、Slippageのデータ条件を決定する」参照）。既知の最良状態（Trend+H1 ADXのみ全条件完全決済・建値ストップ・StopAtrMultiple/RR=2.0・Time Stop有効・`InpRegimeTrendAdxMin=40`）で実行し、コンパイル（10ターゲット）・9 Script Test・Python単体テスト37件全PASS確認済み。純損益+15,511円・PF1.09・取引数77はコスト感応度分析追加前と完全一致。

  `python.analysis.cost_sensitivity`（`results/backtests/20260822-230027-USDJPY-H1/cost-sensitivity-report/`）による結果:

  | 指標 | コスト込み（実績） | コスト除外時（推定） | 差分 |
  |---|---:|---:|---:|
  | 純損益 | 15,511円 | 37,802円 | -22,291円 |
  | Profit Factor | 1.087 | 1.229 | -0.14 |
  | 勝率 | 36.4% | 48.1% | -11.7pt |
  | 期待値 | 201.44円 | 490.94円 | -289.49円 |
  | Sharpe | 0.18 | 0.42 | -0.24 |

  コスト内訳（総コスト22,291円、77件全トレードでpoint_value取得可能）: Spreadコスト合計17,317円（77.7%）、Slippageコスト合計0円、Commission合計0円、Swap合計-4,974円（スワップは収益ではなく追加コストとして寄与）。**理論上の税引前(コスト除外)利益37,802円のうち、59.0%（22,291円）が取引コストで失われている。**

  コスト水準別（`total_cost`の実データ三分位）: Low Cost（27件、平均コスト-20.9円=スワップ収益がSpreadを上回る）はPF1.53と極めて良好。Normal Cost（24件、平均150.8円）はPF0.85で純損益-10,253円の赤字。High Cost（26件、平均739.8円）はPF0.95で純損益-2,621円の小幅赤字。**コスト水準が上がるほど成績が悪化する明確な傾向があり**、コストが単なる一律控除ではなく、収益性の低いトレード（≒質の低いエントリー）ほど高コストになりやすいという相関を示唆する（因果関係は未検証の仮説）。

  **総合評価: PF1.09という現行の最良状態の収益性は、取引コストに対して脆弱な薄いエッジである**。理論上の利益の約6割がコスト（主にSpread）で失われており、Commission=0円というOANDA証券の有利な条件下でもこの結果である。さらに、本バックテストのSlippage合計は0円（Testerの約定モデルが市場成行注文を要求価格どおりに約定させている）であり、これは楽観的な仮定である可能性が高い。実際のOANDA証券ライブ環境では、指標発表時・薄商い時間帯のSpread拡大や、Market Executionでの実際のSlippageが発生しうるため、本結果はコスト面で最良ケースに近い。**追加の調整が必要**: (a) Demo口座でのフォワードテスト時にSlippage・約定品質を実測し、本バックテストの楽観的仮定（Slippage=0）とのギャップを確認する（優先度高、本番移行前の必須ゲート）、(b) High/Normal Costトレードが低品質エントリーと相関するという仮説を、`atr_band`・`session`等の既存`trade_breakdown`の切り口と`cost_tier`を突き合わせて検証する、(c) Spreadコストの影響が大きい銘柄特性を踏まえ、StopAtrMultiple等でリスク幅を拡大しコスト比率を相対的に下げる方向性を検討する（ただし過去のスイープでStopAtrMultiple変更は非単調な挙動を示しており慎重な検証が必要）。ini設定・コード変更は行っていない（分析専用ラウンド）。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] **In-Sample凍結（2026-08-22、ユーザー指示）。以後、OOS/Walk Forward結果を理由とした本パラメータセットの変更は行わない（DEC-024/025のIS/OOS分離方針）。** 現行`mt5/test-config/StrategyTester-USDJPY-H1.ini`の`[TesterInputs]`をIS期間（2017-09〜2020-12）における最終確定パラメータセットとする。デフォルト値からの変更点（IS内チューニングで確定した項目）:

  | パラメータ | 値 | 既定値 | 根拠 |
  |---|---|---|---|
  | `InpEntryUseStagedPipeline` | true | false | 段階的Entry判定パイプライン有効化 |
  | `InpRegimeTrendAdxMin` | 40.0 | 20.0 | 唯一PF>1を達成した閾値（`20260822-183152`他、本節参照） |
  | `InpEnableBreakevenStop` | true | true | 建値ストップ、`InpBreakevenTriggerR=1.0`が最良（トリガー水準スイープ済み） |
  | `InpEnableSignalInvalidationExit` | true | true | シグナル失効Exit有効 |
  | `InpSignalExitCheckTrend` / `InpSignalExitCheckH1Adx` | true / true | true / true | Trend反転・H1 ADX弱体化で完全決済 |
  | `InpSignalExitCheckH4Adx` | **false** | true | H4 ADXはH1 ADXと重複しTP到達を妨げるため無効化 |
  | `InpEnableTimeStop` | true | true | ユーザー指示によりリスク管理方針として有効化（IS単体では純損益わずかに悪化するが維持） |
  | `InpMaxHoldingBars`/`InpTimeStopRequireMinMfe`/`InpTimeStopMinMfeR` | 20 / true / 0.5 | 同左 | 既定値のまま採用 |
  | `InpStopAtrMultiple` / `InpRiskRewardRatio` | 2.0 / 2.0 | 2.0 / 2.0 | スイープの結果、既定値が最も安定（1.5は非単調で過学習リスクありのため不採用） |
  | `InpMinimumAdx` / `InpMinimumConfirmationAdx` | 20.0 / 20.0 | 20.0 / 20.0 | 既定値のまま |
  | `InpPullbackAtrTolerance` | 0.15 | 0.15 | 既定値のまま（2026-08-17確定済み） |
  | `InpEnableEntryTimingAnalysis` | false | false | 分析専用機能のため本番相当設定では無効 |

  この状態でのIS実績（`20260822-183152-USDJPY-H1`他）: 純損益+15,511円、Profit Factor 1.09、Sharpe +0.80、取引数77、最大DD 3%。コスト感応度分析で理論上の利益の約59%がコストに失われる薄いエッジであること、`InpRegimeTrendAdxMin`が隣接水準（35/45）に対し非単調でIS期間固有の過学習リスクがあることを踏まえたうえで、ユーザー判断によりこの状態を凍結してOOSへ進む。次はOOS期間（2021-01〜2024-12）で本節と同一パラメータでのStrategy Tester初回実行を行う。未コミットの作業ツリー差分のため、凍結の証跡としてのcommitはユーザー指示があるまで保留する）
* [x] **OOS期間（2021-01〜2024-12）で、凍結したIS最良パラメータセットの初回評価を実行する**（2026-08-22実施。パラメータ変更は一切行わず、`tools/run-strategy-tester.ps1`を`-FromDate 2021.01.01 -ToDate 2024.12.31`で実行。結果は`results/backtests/20260822-235947-USDJPY-H1/`: 純損益+5,294円、Profit Factor 1.02、Sharpe +0.20、取引数105、最大DD 4%。

  | | IS（`20260822-183152`） | OOS（`20260822-235947`） |
  |---|---:|---:|
  | 純損益 | +15,511円 | +5,294円 |
  | Profit Factor | 1.09 | **1.02** |
  | Sharpe | +0.80 | **+0.20** |
  | 取引数 | 77 | 105 |

  **PF・Sharpeともに大きく低下しており、IS段階で既に指摘していた過学習リスク（`InpRegimeTrendAdxMin`の隣接水準に対する非単調な挙動、サンプル数の少なさ）と整合する結果**。コスト感応度分析（OOS）では、コスト除外時利益29,985円のうち82.3%（24,691円）がコスト（Spread中心）で失われており、ISの59.0%よりさらに深刻。コスト込みPFは1.02とほぼ収支均衡ラインで、未計測のSlippage（引き続きSlippage=0の楽観的仮定）を考慮すればマイナスへ転じる可能性が高い。direction別ではBUY（89件、PF1.12、純利益+23,295円）とSELL（16件、PF0.52、純損失-18,001円）で顕著な差があり、2021-2024の実勢USDJPYが大幅な円安トレンドだった期間特性と整合する（ISでのBuy/Sell有意差検定は「有意差なし」だった点との対比）。close_reason別ではTP平均利益(9,447円)・SL平均損失(-4,063円)はISとほぼ同水準で安定していたが、EXPERT（早期Exit）がISでは概ね収支均衡だったのに対しOOSでは明確なマイナス(-3,873円)だった。

  **副次的発見（安全性への影響なし）**: OOS期間中の2022-02-25〜2022-04-11に監査ログの`SYSTEM_ERROR`（`POSITION_MANAGER`/`UNKNOWN_ERROR`）が162件記録された。同期間のDEAL/TRADE_CLOSEDイベントを確認したところポジションの開閉・SL/TP到達は正常に継続しており、保護SLが失われた形跡はない。`EAController::AuditSystemError()`が`PositionManager::Monitor()`のerror文字列を`reason_code`として記録する際、空文字列等で`SafeCorrelationId`検証に失敗すると`UNKNOWN_ERROR`へフォールバックし、実際の詳細理由が失われ原因調査ができない状態であることが判明（監査ログの観測性の問題であり、取引実行・ポジション保護への影響はない）。今回は分析専用ラウンドのためコード修正は行っていない。

  **総合評価: DEC-024/025のIS/OOS分離方針に基づき、本結果を理由としたIS期間パラメータの再変更は行わない。** OOSでの明確な性能劣化（PF1.09→1.02、Sharpe0.80→0.20）と、コスト感応度のさらなる悪化（59%→82.3%）は、本パラメータセットが依然として本番投入の水準に達していないことを示している。次の一手候補: (a) Walk Forward各Fold（2021/2022/2023/2024の年次）で年ごとの安定性を確認する（本節既存タスク参照）、(b) `AuditSystemError`の詳細理由欠落を修正する（安全性には影響しないが、将来の障害調査のため）、(c) Demo口座でのSlippage実測（6節参照）を優先し、コスト面での実行可能性を先に見極める。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] `AuditSystemError`の詳細理由欠落を修正する（2026-08-23実施、ユーザー依頼）。原因は`mt5/Include/Core/EAController.mqh`の`POSITION_MANAGER`向け呼び出し1箇所のみで、実際の詳細理由（`position_error`）を`AuditSystemError()`の第2引数（`reason_code`、`CTradeLogRules::SafeCorrelationId`検証を通過しないとフォールバック値`UNKNOWN_ERROR`へ置換される）へ渡し、第3引数（`reason`、検証なしの自由文字列）には固定の一般文言のみを渡していたため、フォールバック発生時に詳細情報が完全に失われていた。他3箇所の呼び出し（`RISK_MANAGER`・`SIGNAL_ENGINE`×2）は元から詳細を`reason`側に渡す設計になっており対象外。**修正**: `POSITION_MANAGER`呼び出しも他3箇所と同じパターン（`reason_code`は固定の安全な識別子`POSITION_MONITOR_ERROR`、詳細は`reason`側で運ぶ）へ統一。取引実行・ポジション保護判断には一切触れていない（監査ログ専用の変更）。コンパイル（10ターゲット）・9 Script Test全PASS確認済み。

  **再検証**: 同一OOS期間（2021-01〜2024-12）で再実行し、純損益+5,294円・PF1.02・Sharpe+0.20・取引数105が修正前と完全一致（退行なし）を確認。修正後、当該162件の`SYSTEM_ERROR`の`reason_code`は安定して`POSITION_MONITOR_ERROR`となり（`UNKNOWN_ERROR`は解消）、`reason`に実際の詳細（`"Managed position monitoring failed: EMERGENCY_ORDER_CHECK_FAILED retcode=0 comment="`）が記録されるようになった。

  **修正により判明した根本原因の詳細**: `PositionManager::EmergencyClose()`内の`OrderCheck()`呼び出しが`retcode=0`・空`comment`で失敗している（`OrderCheck()`自体が失敗、Broker側の具体的な拒否コードではない）。全162件が2022-02（99件）・2022-04（63件）の2つの期間にのみ集中しており、OOS全体（2021-2024）の他期間には一切出現しない局所的な事象であることを確認。ポジション保護（Broker側SL）自体は同期間中も継続しており実害はない。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
* [x] **`EMERGENCY_ORDER_CHECK_FAILED retcode=0`が2022-02/04にのみ発生する根本原因を調査し、追加修正を実施する**（2026-08-23実施、ユーザー依頼）。

  **調査手順**: (1) 該当ポジション（ticket=68、ticket=74）の`TRADE_CLOSED`を確認したところ、いずれも金曜〜月曜の週跨ぎ保有で、`exit_spread_points`が通常3〜6ptに対し80pt・147ptと異常に拡大しており週末ギャップでの決済と判明。(2) `HasValidProtectiveStop`と同じbid/ask健全性チェック（`CPositionProtectionRules::HasValidMarketData`新設）を`EmergencyClose`/`CloseOnSignalInvalidation`/`CloseOnTimeStop`のOrderCheck前へ追加し再実行したが、エラーは解消せず、bid/ask自体は不正値ではないことが判明（この健全性チェック自体は将来の異常値混入に対する妥当な防御であり残置）。(3) `GetLastError()`・`price`・`bid`・`ask`を診断メッセージへ追加し再実行した結果、`last_error=0`（真のエラーなし）かつbid/askとも正常値（例: bid=124.025 ask=124.085）であることを確認。(4) 既存の`COrderCheckRules::IsAccepted()`のコメント・単体テスト（`mt5/Tests/TestTradingRules.mq5`の`"OrderCheck bool success accepts documented retcode zero"`）から、**OrderCheckは成功時（bool戻り値true）でもretcode=0（TRADE_RETCODE_DONEではなく"Done"相当の0）を返すことがMQL5仕様上ある**ことを再確認。`EmergencyClose()`は`ModifyStopLoss`/`CloseOnSignalInvalidation`/`CloseOnTimeStop`の3箇所と異なり`COrderCheckRules::IsAccepted`を使わず`check.retcode!=TRADE_RETCODE_DONE`という独自の不完全な判定をしており、retcode=0の正当な成功ケースを常に失敗と誤判定していたことが真の原因と判明。

  **修正**: `mt5/Include/Trading/PositionManager.mqh`の`EmergencyClose()`を、他3箇所と同じ`COrderCheckRules::IsAccepted(check_ok,check.retcode)`による判定へ統一。あわせて`CPositionProtectionRules::HasValidMarketData()`を新設し`HasValidProtectiveStop`と3つの決済メソッドで共通利用するようリファクタ、診断メッセージへ`last_error`/`price`/`bid`/`ask`を追加。`mt5/Tests/TestTradingRules.mq5`へ`HasValidMarketData`の単体テスト5件を追加。取引実行・ポジション保護判断のロジック自体には触れていない。コンパイル（10ターゲット）・9 Script Test全PASS確認済み。

  **修正後の再検証で判明した真の根本原因**: 修正により`OrderCheck`が正しく通過するようになった結果、同一箇所は今度は`OrderSend()`が`retcode=10018 (TRADE_RETCODE_MARKET_CLOSED)`・`comment=Market closed`で失敗することが判明した。**これはコードのバグではなく、週末クローズ中の現実の市場制約である**: ポジションのSLが週末の価格ギャップで見かけ上無効化され（`HasValidProtectiveStop`がfalseと判定）、EAが安全網として`EmergencyClose`を試みるが、市場が閉場しているため実際に成行注文を送信できない。ポジション自体はBroker側の指値SL注文（市場閉場中でも有効なスタンディングオーダー）により保護され続けており、月曜の取引再開時に正常にSL決済されている（前段で確認した80pt/147ptの`exit_spread_points`はこのギャップによるもの）。

  **再検証**: 同一OOS期間で再実行し、純損益+5,294円・PF1.02・Sharpe+0.20・取引数105が完全一致（退行なし）することを確認。修正後の162件の内訳は、160件が`EMERGENCY_CLOSE_ALREADY_ATTEMPTED`（初回試行でべき等性フラグが正しく設定されるようになり、以降のTickで無駄なOrderSend再試行をしなくなった）、残り2件が`EMERGENCY_CLOSE_FAILED retcode=10018 comment=Market closed`（正確な失敗理由）となり、以前の不透明な`EMERGENCY_ORDER_CHECK_FAILED retcode=0`から診断精度が大幅に改善した。

  **安全性への意義**: 本バグは、`EmergencyClose`が呼び出される稀な条件（`HasValidProtectiveStop`がfalseと判定される状況）で`OrderCheck`がretcode=0を返した場合に常に失敗する、という潜在的な安全網の欠陥だった。過去のIS/OOS全期間で`EmergencyClose`が呼び出しを試みたのは本件（週末ギャップ）が初めてであり実害はなかったが、今後、取引時間中に何らかの理由で正規のポジション保護が失われた場合の安全網が機能しない可能性があったため、安全性に関わる重要な修正である。未コミットの作業ツリー差分のため、対応方針が固まるまでcommitは保留する）
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
* [x] Spread、Commission、Swap、Slippageのデータ条件を決定する（2026-08-22決定。**Spread**: `USDJPY_HIST`は`mt5/Tools/ImportOandaTicks.mq5`が`CustomSymbolCreate`の`origin_name`にOANDA証券MT5口座接続時点の実`USDJPY`を指定して仕様を複製しており、Bid/Askも実tickデータをそのまま使用するためヒストリカルなOANDA実勢スプレッドを再現している（`DECISIONS.md`参照）。**Commission**: OANDA証券公式サイト（[oanda.jp/course](https://www.oanda.jp/course)、WebFetchで確認）で、MT5対応の東京サーバー2コース（裁量プラン・スタンダードプラン、いずれもUSD/JPYスプレッド0.3〜0.7銭程度）はいずれも「取引手数料：無料」であることを確認。Strategy Testerの既定Commission（0円）はOANDA MT5の実態と一致しており変更不要と判断した。**Swap**: `CustomSymbolCreate`が実`USDJPY`からSwap仕様も複製するため、OANDA証券の実際のSwap Rateを反映している（前提: Custom Symbol作成時にOANDA証券MT5口座へ接続済みであったこと、`DECISIONS.md` DEC-023参照）。**Slippage**: EA側の許容上限は`InpMaxDeviationPoints`（既定10 Point）。実際に発生するSlippageはStrategy Testerの実tickベース約定シミュレーション（`Model=4`、`ExecutionMode=0`）に委ねており、これはSpread同様「過去データへ最も都合よく適合する値を注入しない」という本プロジェクトの分析方針に沿う。ただし本IS期間の実行では`ORDER_SUBMISSION.slippage_points`の合計が0（`results/backtests/20260822-230027-USDJPY-H1/`のコスト感応度分析で確認）であり、Testerの約定モデルが楽観的（Slippage無し）である可能性を残存リスクとして記録する。詳細な評価は2.1節のコスト感応度分析エントリを参照）
* [ ] Data Quality Checkを実装または実行する

## 3.2 検証期間

* [x] In-Sample期間を固定する（`DECISIONS.md` DEC-024/025で2017-09〜2020-12に確定済み。2026-08-22、本節2.1のIS凍結エントリでパラメータセットも確定し、期間・パラメータ両方が固定された）
* [ ] Calibration期間を固定する（rule-based Strategyには学習・確率較正ステップが存在しないため現時点で対象外。ML学習パイプライン導入時に別途検討する）
* [x] Out-of-Sample期間を固定する（`DECISIONS.md` DEC-024で2021-01〜2024-12に確定済み）
* [ ] Label Horizonに応じたgapを固定する（rule-based Strategyには教師ラベルが存在しないため現時点で対象外。ML学習パイプライン導入時に別途検討する）
* [x] OOS確認後に同じ期間を再利用しない運用を確立する（本セッション全体を通じ、IS期間のみでのパラメータ探索・OOS/Walk Forward期間への非先取りを一貫して実施（例: 2.1節各エントリの「OOS期間を先取りして確認することはしない」等の記述）。2026-08-22のIS凍結以降は、OOS/Walk Forward結果を理由とした本パラメータセットの再変更を行わない運用を明文化した）

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

**Slippage・約定品質の実測計画（2026-08-22策定、コード・設定変更なし・計画書のみ）**: コスト感応度分析（2.1節参照）で、本バックテストのSlippage合計が0円（Testerの約定モデルが市場成行注文を要求価格どおりに約定させる楽観的仮定）と判明したため、Demo口座での実測を計画する。**6.1観測モード・6.2障害試験は未着手（全項目`[ ]`）であり、6.3取引モードは下記の順序どおりこれらの完了後にのみ着手する**（TASKS.md既存の明記どおり）。以下は各フェーズの具体的な設定値・所要期間・分析方法の計画であり、実行（EAをDemo口座のチャートへアタッチする、AutoTradingを有効化する等）はユーザーが手動で行う必要がある（Claude Codeからは実行できないGUI操作）。

* **6.1観測モードの推奨EA入力値**: `InpEnableTradeMutations=false`（既定値のまま）・`InpAuditFileEnabled=true`（既定値のまま）。`InpDecisionApiEnabled=true`にする場合はAWS Decision APIスタックのdev環境が到達可能である必要があり（`docs/aws-infrastructure.md`参照）、現時点でAWS dev実通信は未検証（CLAUDE.md「現在の安全状態」参照）。AWS側の準備がまだの場合は、`InpDecisionApiEnabled=false`のまま観測モードを開始し、ローカルRisk判定・監査ログ・Broker Symbol仕様の確認から進める代替順序も検討可能（ただしこの場合Decision API関連項目は別途スケジュールする必要がある）。所要期間の目安: 各項目を最低1回確認できるまで、数日〜1週間程度。
* **6.2障害試験**: 多くの項目（Emergency Stop、Strategy Stop、Spread急拡大、Margin不足、OrderCheck失敗、約定拒否、Stop Level/Freeze Level違反等）はDemo口座上でMT5設定操作・注文操作により再現可能。Decision API/AWS関連の障害試験（Timeout、HTTP 4xx/5xx/429、不正JSON、request ID不一致、TTL切れ、Clock Skew、Replay、DynamoDB障害）はAWS dev環境が前提となるため、6.1で`InpDecisionApiEnabled=true`の検証を実施する場合にあわせて計画する。
* **6.3取引モード（Slippage・約定品質の実測、本計画の主目的）**:
  - 前提: 「ユーザー承認を得る」「設定の証跡を保存する」を経てから`InpEnableTradeMutations=true`へ変更する（TASKS.md既存の順序どおり）。
  - 推奨EA入力値: 現行の最良状態（本節2.1参照、Trend+H1 ADXのみ全条件完全決済・建値ストップ・StopAtrMultiple/RR=2.0・Time Stop有効・`InpEntryUseStagedPipeline=true`・`InpRegimeTrendAdxMin=40.0`・`InpSignalExitCheckH4Adx=false`）と同一のパラメータをDemo口座のEA InputsタブへExpert Advisor起動時に設定する。Decision APIは、6.1で検証済みならそのまま有効、未検証なら`InpDecisionApiEnabled=false`で純粋にRisk Manager・ローカルルールのみでの約定挙動を先に確認する案も検討可（Decision APIの可否とSlippage計測は独立した関心事のため）。
  - **サンプルサイズと所要期間の見積り**: `InpRegimeTrendAdxMin=40`は正式IS期間（3.3年）で77トレード（年間約23件、月間2件弱）と取引頻度が低い。Slippage統計として意味を持たせるには最低20〜30トレード程度のサンプルが望ましく、現行の高選別的な設定のままでは**数か月（目安3〜6か月）を要する見込み**。より早くSlippageサンプルを収集したい場合、**Slippage計測に限っては、より取引頻度の高い設定（例: `InpEntryUseStagedPipeline=false`でStaged Pipelineを無効化した基準構成、年間約200件）に一時的に切り替える**という代替案もある（Slippageは主にBroker側の約定メカニズムに起因し、Entry選別ロジックの違いに大きく依存しないという前提に基づく仮説であり、この前提自体の妥当性はユーザー判断による）。どちらの方針を採るかはユーザーが決定する。
  - **計測する指標**: 既存の監査ログ基盤がそのまま使える（追加のコード変更は不要）。`ORDER_SUBMISSION.slippage_points`（Entry Slippage）、`CANDIDATE.spread_points`・`TRADE_CLOSED.exit_spread_points`（Entry/Exit Spread）、`TRADE_CLOSED.commission`・`swap`。
  - **分析方法**: 十分なトレード数が蓄積された時点で、Demo口座のAudit JSONL（`InpAuditLogDirectory`配下）を`results/`配下へ複製し、既存の`python.analysis.cost_sensitivity`・`python.analysis.trade_breakdown`をそのまま実行する（新規ツール開発は不要）。得られたSlippage・Spread実測値を、本バックテストの仮定（Slippage=0、Spread=ヒストリカル実tick、Commission=0）と比較し、乖離があればコスト感応度分析（2.1節）の`pnl_before_cost`との差分を実測値ベースで再計算する。
  - **ロールバック・安全性**: Demo口座のため実資金リスクはないが、CLAUDE.mdの安全原則（新規注文拒否・既存ポジション保護継続を優先）は同様に適用する。異常時は`InpEmergencyStop=true`で新規注文のみ即時停止可能（既存ポジション管理は継続、6.4参照）。

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
