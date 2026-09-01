# バックテスト結果

このディレクトリには、Strategy Testerからエクスポートしたレポートと、`run-metadata.template.json`を複製して記録した実行条件を同じ実行IDで保存します。

未実行の値を推測で記入してはいけません。未取得項目は `null` とし、Production Readiness Reportでは `NOT VERIFIED` と扱います。

## 2026-08-10: ブローカー切替について

ブローカーをXMTrading-MT5からOANDA証券MT5へ切り替える方針が決定した（理由: XMTrading-MT5はUSDJPYのreal tickデータを2022年1月分以降しか保持しておらず、2015年以降を対象にした検証ができないため）。OANDA証券デモ口座開設完了後、Strategy Testerを再実行し、以後はOANDA側データを正式な検証系列とする。

XMTrading時代の結果（`20260721-231302-USDJPY-H1/`：完走した2025年分実行結果、`20260810-144215-USDJPY-H1/`：2020-2021のreal tick欠如を示す診断記録）は削除せず、参考記録として保持する。理由の詳細は各ディレクトリ内のファイル、および`TASKS.md` 2.1・`HANDOFF.md`を参照。異なるBrokerの結果を同一のIS/OOS系列として混在させないこと。

## 2026-08-16: OANDAデモのtickキャッシュも不十分、Custom Symbolで解決

OANDA-Japan MT5 Demoサーバーのライブtickキャッシュも直近約1年分しか保持しておらず、`20260816-113850-USDJPY-H1/`は「ヒストリー品質2%リアルティック」の無効データとなった（`INVALID-2pct-real-ticks.md`参照）。

OANDA証券のWeb版Tickダウンロードツールから取得した2016年9月〜2026年8月のUSDJPY real tick CSVを、`USDJPY`の仕様を複製したCustom Symbol「USDJPY_HIST」へ投入する方式（`DECISIONS.md` DEC-023、`mt5/Tools/ImportOandaTicks.mq5`）で解決した。`oanda-hist-validation-2016-09/`・`oanda-hist-validation-2020/`はこの投入方式の品質検証記録であり、いずれも「ヒストリー品質100%リアルティック」を確認済み。ただし正式なIn-Sample/Out-of-Sample期間としてはまだ確定していないため、これらの損益数値をproduction release gateの証跡として扱わないこと。

今後の実市場tick検証・Strategy Testerは、Symbolに`USDJPY`ではなく`USDJPY_HIST`を指定して実行する。

## 2026-08-16: In-Sample/Out-of-Sample/Walk Forward期間の確定と補正

`DECISIONS.md` DEC-024で当初、開発・In-Sample=2016-09〜2020-12、OOS/Walk Forward評価=2021-01〜2024-12、Final Holdout=2025-01〜2026-08を確定した。

その後、2016-09開始でStrategy Testerを実行したところ、対象期間全体（26,882本のH1確定足）で取引数0件の異常が判明した（`20260816-180519-USDJPY-H1/ANOMALY-zero-trades.md`）。原因は、Tester開始日が`USDJPY_HIST`実データ最古日（2016-08-31）に近すぎ、D1/H4インジケーターのウォームアップに必要なバッファ（二分探索の結果、実測で9〜10か月必要と判明）が不足していたことだった。この結果を受け、`DECISIONS.md` DEC-025でIn-Sample開始日を**2017-09-01**へ補正した。`mt5/test-config/StrategyTester-USDJPY-H1.ini`の既定値もIn-Sample期間（`USDJPY_HIST`、2017-09-01〜2020-12-31）へ更新済み。

補正後の期間でIn-Sample正式実行を完了した（`20260816-193344-USDJPY-H1/`）: ヒストリー品質100%リアルティック、取引数55、総損益-65,696円、Profit Factor 0.66、最大DD9%。受入基準は未凍結のため合否は未判定。

## 2026-09-01: 複数ケース実行基盤の追加（Cross-Asset Validation向け、未実行）

`tools/run-strategy-tester.ps1`へ`-CaseFile`を追加し、単体実行と同じ処理を複数銘柄・複数期間で順番に実行できるようにした（`docs/backtesting.md`「複数ケース実行」参照）。結果は `<run-id>-cases/` 配下、ケースごとの`manifest.json`・`summary.csv`・`summary.md`で確認できる。

初期確認用に`mt5/test-config/cases/cross-symbol-2020-2024.json`（EURJPY/EURUSD/GBPJPY×2020-2024、計15ケース）を作成したが、**このセッションの権限設定でterminal64.exeの起動がブロックされたため、実機でのStrategy Tester実行・動作確認は未実施（NOT VERIFIED）である**。CaseFileのバリデーション・ケース継続処理・manifest/summary生成ロジックは、ダミーInstallPathによるドライラン（Strategy Tester自体は起動せずTerminal未検出で全15ケースが意図どおりFailed記録され、後続ケースへ継続し、manifest.json/summary.csvが正しく生成されることを確認済み）で検証した。

なお、`USDJPY_HIST`以外（EURJPY・EURUSD・GBPJPY等）にはOANDA Web版Tickダウンロードツールからのreal tick投入（DEC-023と同じ方式）を行っていない。ブローカーのライブtickキャッシュは直近1年程度しか保持しないため（DEC-023参照）、2020-2023年のケースは「ヒストリー品質」が100%リアルティックに満たない可能性が高い。実行前に品質を確認し、不足する場合はUSDJPY_HISTと同様にCustom Symbolへreal tickを投入する対応を検討すること。
