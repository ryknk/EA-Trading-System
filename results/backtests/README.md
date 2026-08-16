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
