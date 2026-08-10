# バックテスト結果

このディレクトリには、Strategy Testerからエクスポートしたレポートと、`run-metadata.template.json`を複製して記録した実行条件を同じ実行IDで保存します。

未実行の値を推測で記入してはいけません。未取得項目は `null` とし、Production Readiness Reportでは `NOT VERIFIED` と扱います。

## 2026-08-10: ブローカー切替について

ブローカーをXMTrading-MT5からOANDA証券MT5へ切り替える方針が決定した（理由: XMTrading-MT5はUSDJPYのreal tickデータを2022年1月分以降しか保持しておらず、2015年以降を対象にした検証ができないため）。OANDA証券デモ口座開設完了後、Strategy Testerを再実行し、以後はOANDA側データを正式な検証系列とする。

XMTrading時代の結果（`20260721-231302-USDJPY-H1/`：完走した2025年分実行結果、`20260810-144215-USDJPY-H1/`：2020-2021のreal tick欠如を示す診断記録）は削除せず、参考記録として保持する。理由の詳細は各ディレクトリ内のファイル、および`TASKS.md` 2.1・`HANDOFF.md`を参照。異なるBrokerの結果を同一のIS/OOS系列として混在させないこと。
