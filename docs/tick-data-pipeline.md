# tickデータ取得・MT5変換パイプライン

外部データソースのヒストリカルtickを取得し、共通形式へ正規化・検証したうえで、MT5のCustom Symbolへ投入してStrategy Testerで使えるようにする。既存のOANDA tick運用（既存の`USDJPY_HIST`等のCustom Symbol、`DECISIONS.md` DEC-023）は変更していない。Importer（`mt5/Tools/ImportOandaTicks.mq5`）はtick欠落の修正のため変更した（下記、DEC-037）。設計判断は`DECISIONS.md` DEC-036。

## 全体像

```text
Provider(取得) -> raw/ -> normalize -> normalized/ -> validate -> convert -> mt5/(タブCSV)
   -> import(既存ImportOandaTicks.mq5) -> verify(VerifyCustomSymbolTicks.mq5) -> history quality(Strategy Tester)
```

| 層 | 場所 | 責務 |
| --- | --- | --- |
| 入口 | `tools/tick-data.ps1` | Python CLIの呼び出し、MT5端末の操作（Importer・検証スクリプトの起動、Journal回収） |
| 処理本体 | `python/tickdata/` | chunk分割・retry・resume・正規化・検証・変換・manifest |
| Provider | `python/tickdata/providers/` | データソース固有の取得とパース（`dukascopy`・`csvfile`・`mock`） |
| Node Adapter | `tools/tick-data/dukascopy-download.mjs` | dukascopy-nodeで1チャンク分を取得するだけ。chunk・retry・resumeはPython側 |
| MT5 | `mt5/Tools/ImportOandaTicks.mq5`（既存。DEC-037で欠落を修正）、`mt5/Tools/VerifyCustomSymbolTicks.mq5`（新規・読み取り専用） | Custom Symbolへの投入、tick数・最初/最後の時刻の確認 |

ProviderはAdapterで、後段は共通tickだけを扱う。新しいデータソースは`TickProvider`（`download_chunk`と`iter_rows`）を実装して`register_provider`へ登録すれば追加できる。

## 共通tick形式

正規化済みCSV（`tickdata-csv-v1`）: `timestamp_ms,bid,ask,bid_volume,ask_volume`。`timestamp_ms`はUTCエポックミリ秒。symbol・provider・取得範囲は数億行へ繰り返さず、データセットのmanifest（`dataset.json`）に持つ。

## データ保存先

`tick/pipeline/<dataset_id>/`（`tick/`はGit管理外）。`dataset_id = <provider>-<SYMBOL>-<from>-<to>`。

```text
dataset.json      manifest兼進捗状態（chunkごとの状態・checksum・件数、検証・変換・取込・照合・品質の結果）
validation.json   検証結果（機械可読）
raw/              Providerの出力（chunk単位、SHA-256を記録）
normalized/       共通形式（chunk単位）
mt5/              MT5タブCSV（サーバー時刻の暦月ごと。ImportOandaTicks.mq5が読む形式）
import-*.log      取込時のMT5 Journal抜粋 / verify-*.log 照合時の抜粋
```

## 設定ファイル

`tools/tick-data/profiles/*.json`。秘密情報は持たない。主なキー: `provider`・`symbol`・`from`・`to`・`timezone`（UTCのみ）・`chunk_unit`（`day`/`month`）・`storage_root`・`provider_options`・`retry`・`validation`・`server_time`・`mt5`。CLI引数（`-Provider`等）は設定ファイルの値を上書きする。

* `server_time`は**必須**（convert時）。MT5のtick・バーはサーバー時刻の時計表示をそのままエポックとして保持するため、D1・H4の境界がこの規則で決まる。`utc` / `{"mode":"fixed","offset_hours":2}` / `ny_close`（NY現地時刻+7時間。米国DSTに追従するGMT+2/+3）。
* **`ny_close`はOANDA-Japan MT5のサーバー時刻と一致することを確認した**（2026-09-21）。`tick/OANDA`の2017-03のUSDJPY tickで、週明けの最初のtickが米国DST開始（3/12）の前後とも月曜00:00台（3/6・3/13・3/20・3/27）で、欧州DST開始（3/26）に追従しない。2016-09の月ファイルの先頭が`2016.08.31 18:00`（JST 9/1 0:00 = UTC 15:00 + 3時間）であることとも整合する。ただし他Brokerには使えない。
* `mt5.custom_symbol`は既存の`*_HIST`（OANDA tick由来）と別名にする。サンプルは`USDJPY_DUKA`・`USDJPY_DUKA_TEST`。

## CLI

```powershell
.\tools\tick-data.ps1 <download|normalize|validate|convert|import|verify|status|diff|run> -Config <profile>
```

各工程は独立して実行でき、完了済みの工程・chunkはスキップされる（`-Force`で再実行）。`run`は`download -> normalize -> validate -> convert -> import -> verify`を連続実行する（`-Target Normalized`ならvalidateまで。MT5を使わない）。`-HistoryQuality`を付けるとverifyで短いStrategy Testerも実行する。

```powershell
# ユーザー指定の例に相当する1コマンド（設定ファイルを使わない場合）
.\tools\tick-data.ps1 run -Provider dukascopy -Symbol USDJPY -FromDate 2016.09.01 -ToDate 2020.12.31 `
  -ServerTime ny_close -CustomSymbol USDJPY_DUKA
```

終了コード: 0=成功 / 1=想定外 / 2=設定・入力不正 / 3=一部chunk未完了（再実行で再開） / 4=検証失敗・変換拒否 / 5=MT5取込・照合・品質の失敗 / 6=Provider環境不備（Node未導入等） / 7=データセットがロック中 / 8=diffに差分あり。

## 大容量・中断再開

* 全件をメモリへ載せない。chunk（既定は1日、`chunk_unit: month`で暦月）を1行ずつ処理する。
* rawは`.part`へ書き、完了後に`os.replace`でrename。manifestもatomic保存で、chunkごとに保存する。`.part`や途中停止したchunkを「完了」と扱わない（完了判定はmanifestの記録＋ファイルサイズ）。
* 失敗chunkは`failed`として残り（exit 3）、同じコマンドの再実行で未完了分だけ再開する。retryは指数バックオフ（`retry`設定）。Node未導入など再試行しても直らない失敗は即中断する（exit 6）。
* 空データ（ヘッダーのみ）は`empty`として記録する。土曜の空は想定内、それ以外は検証でwarningになる。
* 同一データセットの並行実行は`dataset.lock`で拒否する。

## 検証（validate）

MT5へ渡す前に`validation.json`と`dataset.json`へ記録する。**error（FAIL）**: 未取得・未正規化chunk、checksum不一致、時刻の逆行、範囲外時刻、非有限値、価格0以下、bid>ask、有効tick0件、symbol不一致、rejected率が`max_rejected_ratio`超過。**warning（WARN）**: 連続重複（chunk境界）、`max_gap_seconds`超の欠落（週末を除く）、連続tick間の`max_price_jump_ratio`超の価格飛び、rejected行あり、想定外の空chunk。convertは検証がPASS/WARNで、検証後にデータが変わっていない場合だけ実行できる。

正規化（normalize）は不正行（パース不能・非有限・価格0以下・bid>ask・負のvolume・chunk範囲外）を除外して理由別に件数を記録し、連続する完全重複を除去する。時刻の逆行は並べ替えず、validateでエラーにする。

## Provider

| Provider | 用途 | 制約 |
| --- | --- | --- |
| `dukascopy` | Dukascopyの無料tick（USDJPY等、2016年以前も可）。要Node.js 18以上と`npm ci --prefix tools/tick-data`。 | Dukascopy側のレート制限（HTTP 429）。短時間に大量のリクエストを送ると弾かれることがある（実測: 過去の連続試験中に、1日分が繰り返しHTTP 429で失敗する状態になった）ため、Node Adapterは1時間ごとに取得して`batch_pause_ms`（既定500、2026-09-23に3,000から引き下げ。下記「速度」参照）待機し、429などは`retry_pause_ms`（既定30000、倍々）で再試行する。ライセンス・利用条件は**未確認**。Bid/Askの取得元・価格はOANDAと同一ではない。 |
| `csvfile` | 取得済みCSV（OANDA証券のMT5標準タブ形式`mt5-tab`、または`header-csv`、zip可）の取込。`source_time`（サーバー時刻の規則）が必須。 | 月単位chunk（`chunk_unit: month`）と`source_pattern`（`{yyyy}`・`{mm}`）でファイルへ対応付ける。DST切替の重複時刻（市場休場中）は復元できない。 |
| `mock` | 決定的な合成tick。テスト・配線確認専用。 | 市場データとして使わない。 |

**Tickstory**: GUI操作を前提にせず、パイプラインへ組み込まない。Tickstoryが出力したCSVは、列がmt5-tabまたはheader-csv（`timestamp,bid,ask`のUTCエポックms）に一致すれば`csvfile`で取り込める。TickstoryのCSV形式・CLI自動化の可否は**未確認（NOT VERIFIED）**で、実機で確認していない。共通tick形式は特定ツールの仕様に依存しない。

### Dukascopyの速度（2026-09-23調査）

数年規模のAUDUSD取得（2020-01-01〜2026-08-31、2,435日）に関連して調査した。当初はソース読み取り・GitHub Issue確認・ローカルデータ集計のみ（Dukascopyへの追加リクエストなし）で行ったが、`batch_pause_ms`の安全域検証はAUDUSDジョブが停止したことを確認した後（プロセス・進捗とも無変化を確認済み）に、実際のDukascopyへのリクエストを伴う試験として実施した。

* **観測ペース**: 実行中ジョブの実測で約97秒/日（849日で22時間53分）。数年分では約65時間、2〜3日分の短期テスト時に観測した約72秒/日より遅い（応答データ量が年・ボラティリティにより変わるため）。
* **`batchSize=1`（現状の実装）は、ライブラリ作者自身が429対策として推奨している設定**（[dukascopy-node#124](https://github.com/Leo4815162342/dukascopy-node/issues/124)、`--batch-size 1 --retries 10`を案内）。ライブラリ既定の`batchSize=10`・`pauseBetweenBatchesMs=1000`（並列10件）は、429を避ける目的には使えない。
* **`batch_pause_ms`の安全域を、AUDUSDジョブ停止後（2026-09-23、後述）に検証した。** 2000/1500/1000/500/0msの各値で1日分（24リクエスト）を個別に試したところ、**いずれも429なしで成功した**（以前の「1,500msで429が再発した」という記録は、当時の別要因（同時実行していた他の試験等）による可能性がある。原因の特定はしていない）。さらに実運用に近い持続負荷を確認するため、間隔ゼロで連続実行する試験を行った: 500msで15日連続（360リクエスト）、0msで20日連続（480リクエスト）、いずれも429・失敗0件だった。**この結果を受け、既定を500msへ引き下げた**（`tools/tick-data/dukascopy-download.mjs`の既定値、および既存プロファイル`tools/tick-data/profiles/*.json`の値を両方変更。詳細は`DECISIONS.md` DEC-039）。0msの方がテスト量は多かったが、サービスへの配慮とサーバー負荷変動に対する余裕を残すため、明示的な間隔が残る500msを採用した。
* **今回の検証の限界**: 実施した試験は最大でも連続480リクエスト（20日相当）にとどまり、実際のジョブが行う**数千日規模・数十時間にわたる連続実行**でも同様に安全かは未検証。また検証はUSDJPYのみ・特定の時間帯のみで行っており、他銘柄・他の時間帯・サーバー高負荷時の挙動は未確認。429が発生した場合は既存の`retry_pause_ms`（既定30000、倍々）による再試行で吸収される設計だが、新しい既定値でも長時間ジョブでは念のため進捗を時々確認することを推奨する。
* **安全に確認できた無駄: 土曜（UTC終日）は市場休場でtickが常に0件**。稼働中ジョブの完了済み122件の土曜チャンクすべてで確認した（例外0件）。従来の実装は、空とわかっている土曜も24時間分のリクエスト＋待機（約85〜97秒）を律儀に行っていた。
* **金曜・日曜の部分休場帯も、すでにダウンロード済みの生CSVから正確な境界を求めた**（2020-01〜2022-05、金曜123件・日曜122件、追加のDukascopyリクエストは発生させていない）。金曜は全件が21:59:59以前に終了し（例外0件）、日曜は全件が21:00:00以降に開始した（最早21:00:00.066、例外0件）。DSTの影響も含めてこの範囲では境界が安定していたため、当初懸念していた「DST依存で切り捨てリスクがある」という判断を撤回し、金曜22:00 UTC・日曜21:00 UTCを安全な境界として採用した。
* **`skip_weekend_closed_hours`オプションを追加した（既定`true`、2026-09-23）。** 有効時は、土曜チャンクはリクエストを送らず即座に空ファイルを書き、金曜チャンクは取得範囲を22:00 UTCまでに、日曜チャンクは21:00 UTCからに縮める。週168時間のうち休場としてスキップ可能な時間は土曜24h＋金曜2h＋日曜21h＝47h（**週の約28%**）。2,435日規模のジョブでは理論上**約18時間**（65時間ベース）の短縮が見込める（未実測）。
* **既定をtrueにした理由**: 本プロジェクトの本番ブローカーはOANDA証券のみ（DEC-023）で、OANDA証券がMT5で提供する銘柄は全てFXであり、週末取引される銘柄（暗号資産等）を一切扱っていないことを、公式サイト（取引全コース比較・株価指数/商品CFD取引時間ページ）とデモ口座の`SymbolInfoSessionTrade`直接照会の両方で確認した（`DECISIONS.md` DEC-038）。このため既定でスキップしても実用上安全と判断した。
* **他ブローカー・他銘柄へ転用する場合の注意**: 一般のMT5ブローカーには週末も取引される銘柄（暗号資産CFD等）を提供するところがある。そのような銘柄を本Providerで取得する場合は、プロファイルへ`"provider_options": {"skip_weekend_closed_hours": false, ...}`を明示指定すること。既定trueのまま使うと該当銘柄の週末tickが欠落する。
* **境界値の限界**: 金曜・日曜の境界は2020-01〜2022-05（完了済み範囲）のAUDUSD実データに基づく。未取得の2022-06〜2026-08で同じ境界が成り立つ保証はない（未確認）。外国為替市場の週次休場慣行（NY時間17時）は長期間変わっていないため変動は考えにくいと判断したが、確定的な裏付けではない。また、この境界値はFX固有であり、OANDA証券の商品CFD（例: 北海ブレント原油は土曜5:59 JST終了・月曜7:01 JST再開）を含む他の資産クラスにはそのまま適用できない。

**今回変更しなかった項目（要追加検証）**:

* `batchSize`の引き上げ（ライブラリの並列取得機能）、複数チャンクの並列実行は、いずれもDukascopyへの同時接続数が増えるため、今回のシーケンシャルな安全域検証とは別のリスク（同時接続数自体の制限）があり得る。今回は検証しなかった。

## MT5への投入・確認

* **import**: 既存`ImportOandaTicks.mq5`を再利用する（Providerごとの別Importerは作らない）。入力はMT5のStartUp設定＋`MQL5\Presets\tick-data-import.set`で渡し、`MQL5\Files\EaTradingSystem\TickImport\<dataset_id>`（変換済み`mt5/`へのJunction）を読む。複製元の実Symbolの仕様をCustom Symbolへ複製し、実Symbolの履歴には触れない。
* **既存データ保護**: Custom Symbolが既にtick履歴を持つ場合は中止する。同じデータの再投入は範囲置換のため重複せず件数も変わらない（修正後の実機確認）が、別データの範囲は置換で上書きされるため、追記・再投入は`-AllowExistingSymbol`、完全にやり直す場合は`-AllowExistingSymbol -ResetCustomSymbol`（Custom Symbolを削除して再作成）を明示する。実Symbolと同名の指定も拒否する。
* **verify**: `VerifyCustomSymbolTicks.mq5`（読み取り専用）でMT5上のtick数・最初/最後の時刻を数え、変換結果と突き合わせる（受理されなかったtick数は期待値から除く）。`-HistoryQuality`は既存`run-strategy-tester.ps1 -CaseFile`で短いTesterを実行し、レポートの「ヒストリー品質」とtick数を記録する（照合が不一致でも実行し、終了コードは失敗を優先）。既定のTemplateはMT5標準EAを使う`StrategyTester-TickQuality-M1.ini`（CoreEAはインジケーターのウォームアップに長い履歴が必要で、短いデータセットではtick 0のまま終了するため。`-QualityTemplate`で変更可）。**tick数0は成功にしない**。
* 取込・照合・品質の結果はmanifestの`import`・`mt5_verification`・`history_quality`に記録される。`import`は`complete`（クリーン）/ `complete_with_skips`（MT5が一部tickを受理せず）/ `incomplete`。
* MT5端末を閉じてから実行する。ホスト実行のみ対応（VM実行は未対応）。
* MT5の起動は既定で、画面表示・フォーカス奪取を避ける非表示デスクトップ方式（`-HostUseIsolatedSession`、既定true、`run-strategy-tester.ps1`・`run-mql5-tests.ps1`と同じCreateDesktopEx方式、DEC-031）を使う。`tools/tick-data.ps1`・`tools/reimport-oanda-ticks.ps1`（`-HistoryQuality`/`TesterCheck`が内部で呼ぶ`run-strategy-tester.ps1`にも引き継ぐ）のいずれも対応する。管理者権限は不要。`-HostUseIsolatedSession $false`で従来の`-WindowStyle Hidden`方式へフォールバックできる。

## ImportOandaTicks.mq5のtick欠落と修正（2026-09-21）

**事象**: 従来のImporterは`CustomTicksAdd()`で投入しており、**呼び出し（バッチ）ごとに末尾128 tickがMT5に永続化されなかった**（端末を再起動すると取得できない。`IMPORT_COMPLETED`は全件受理と報告する）。Dukascopyサンプル（894,250 tick）でバッチ20,000なら45×128=5,760件（0.64%）が欠け、既存`USDJPY_HIST`（OANDA由来）も2016-08-31の1日で66,878件中384件（3バッチ分）が欠けていた。

**切り分け結果（実機、使い捨てのプローブで確認）**:

* 呼び出し直後は全件がメモリ上で読める（`CopyTicksRange`）が、端末を終了して再起動すると128件少ない。`ShutdownTerminal`ではなく通常のウィンドウ終了や`TerminalClose`でも、待機を入れても同じ。
* 256件以下の呼び出しは、DBへ書かれず1件も永続化されない。257件以上では末尾128件だけが欠ける（5,000件を257件ずつ→2,549件欠落、300件ずつ→欠落も比例）。
* 時刻が複数の日にまたがる呼び出し（疎なtickの2〜7日分）では欠けなかったため、Dukascopy 5日分のような密なデータや、1日以内に収まる呼び出しで顕在化する。全条件は特定していない（未確認）。
* **`CustomTicksReplace()`（各バッチの時刻範囲を置換）は全件が永続化された**（894,250件、最後のtickも一致）。単一呼び出しでも、バッチ分割でも同じ。

**修正**: `InpUseReplace`（既定true）を追加し、各バッチを`CustomTicksReplace(最小msc, 最大msc)`で投入する。追加の対応: ①同一msのtickの途中でバッチを分割しない（置換範囲が隣のtickを消すため。ファイルをまたぐ場合も持ち越す）、②入力が時刻順でなく範囲が重なる場合は従来の`CustomTicksAdd()`へ切り替え（`REPLACE_FALLBACK_ADD`を出力。既存tickを消さない）。`InpUseReplace=false`で従来動作に戻せる。入力ファイル形式・パラメータ・出力マーカーは変更していない。

**確認結果（修正後、実機）**: Dukascopyサンプル894,250 tick — MT5上の件数と最初/最後の時刻が一致し、全tickの（bid, ask, 時刻）の順序付きchecksumも元ファイルと一致。Strategy Testerは100%リアルティック。同じ投入の再実行（`-AllowExistingSymbol`）でも件数は変わらない（従来は重複・不一致）。複数ファイル（月境界）の投入、同一msが3件ずつ続くデータをバッチ500で投入しても全件保持。従来動作（`InpUseReplace=false`）では同じデータが3,000件中2,232件になった。

## 既存`*_HIST`（OANDA由来）の再投入（2026-09-21〜22、実施済み）

旧Importerが投入した既存の10銘柄は、いずれも同じ欠落を持っていた。元のzip（`tick/OANDA/`）から修正済みImporterで再投入した（`tools/reimport-oanda-ticks.ps1`）。

**欠落量の調査（再投入前、実機）**: 10銘柄×2か月（各銘柄の最初の月と中間の月、計20ファイル）で、元データの件数とMT5上の件数を比べた。**19ファイルは「128×バッチ数」（バッチ20,000件、最後の端数バッチは min(128, 件数)）と1件も違わず一致**し、欠落は0.642%（72,621,330件中465,950件）だった。残る1ファイル（XAUUSD 2024-07）は予測より30件多く欠けていた（旧Importerで受理されなかったtickがあったと推定。未確認。再投入後は元データと一致）。

**方法**: `CustomTicksReplace`は既存の範囲を書き換えるため、Custom Symbolの仕様・履歴の削除は行わず（`InpResetSymbol=false`）、元のCSVをそのまま置換投入して欠けたtickだけを補った。バーも再生成される（USDJPY 2016-09で、H1バーが再投入前後で僅かに変わることを確認）。事前に`bases\Custom`（tick・バー約26GB）と`symbols.custom.dat`をバックアップし（`D:\Backup\mt5-custom-before-tickfix-20260921`）、ツールはバックアップの存在を確認してから実行する。

* **バッチは1,000,000**: 既存データの範囲置換は呼び出しごとに月ファイルを書き直すため、バッチ20,000だと遅い（USDJPY 2016-09の1か月で852秒、1,000,000では36秒）。
* **中断・再実行**: 置換は冪等なので、途中で止まっても同じコマンドで再実行できる。

**結果（全10銘柄、全月ファイル）**:

| 銘柄 | ファイル数 | 元データのtick数 | 補われたtick（概算） | 件数照合 | Tester照合 |
| --- | ---: | ---: | ---: | ---: | ---: |
| USDJPY_HIST | 120 | 889,219,143 | 5,698,889 | 116/120 | 4/4 |
| EURJPY_HIST | 120 | 1,267,357,103 | 8,118,833 | 117/120 | 3/3 |
| EURUSD_HIST | 120 | 778,211,281 | 4,987,307 | 114/120 | 6/6 |
| GBPJPY_HIST | 120 | 1,236,662,531 | 7,922,304 | 116/120 | 4/4 |
| JP225_HIST | 76 | 75,298,364 | 486,656 | 68/76 | 8/8 |
| US100_HIST | 76 | 361,908,338 | 2,320,518 | 74/76 | 2/2 |
| US2000_HIST | 76 | 132,824,281 | 854,528 | 71/76 | 5/5 |
| US30_HIST | 76 | 142,839,254 | 918,816 | 71/76 | 5/5 |
| US500_HIST | 76 | 97,461,775 | 628,735 | 69/76 | 7/7 |
| XAUUSD_HIST | 51 | 257,945,452 | 1,654,400 | 49/51 | 2/2 |
| 合計 | | 5,239,727,522 | 33,590,986（0.641%） | | |

Importerは全銘柄で、受理数＝元データの行数、skip 0、パース失敗0を報告した。件数照合はMT5上のtick数（`CountCustomSymbolTicks.mq5`、月ファイルごと）と元データの行数、Tester照合は直近月でCopyTicksRangeが過少になる（下記）月について、Strategy Testerのtick数と元CSVの同範囲の行数の比較。**全ファイルが、どちらかで元データと完全一致**した。

* **`CopyTicksRange`の制約（新たに確認）**: 直近8か月ほど（2025-12以降）の月は、`CopyTicksRange`がtickを一部（0.6〜数%）しか返さない（DEC-033の「約1%」と同じ現象と思われる）。Strategy Testerのtick数は元データと一致したため、データは完全で、読み取りAPI側の制約と判断した。よって直近月の照合はTesterで行う。
* **Testerは範囲の最終秒のtickを含めない**（実測: EURUSD 2026-05で4件、2026-08で2件）。期待値は終端の1秒前までで数える（ツールに反映済み）。
* **内容の一致**: JP225 2023-07-11の1日（20,734 tick）の（時刻・bid・ask）の順序付きchecksumが元CSVと一致した（Digits 1の価格が丸められないことの確認）。Dukascopyサンプルでも同様（上記）。
* **再投入後の動作**: 10銘柄すべてで、Strategy Tester（CoreEA、2024-03-04〜08）が完走し、100%リアルティックだった。既存の仕様（Digits・契約サイズ等）は変更していない。
* **ツールの不具合（修正済み）**: 取込が日付をまたぐとJournalが翌日のファイルへ移り、`IMPORT_COMPLETED`を読み落とす（GBPJPYで発生、データは正常に取り込まれていた）。翌日以降のログも読むようにした。
* **未評価**: 0.64%のtick欠落と、再生成されたバーの微小な変化が、過去のバックテスト結果（IS・Walk Forward・Final Holdout等）に与えた影響。過去の結果は再投入前のtickで得た値で、再実行していない。

```powershell
# 1銘柄の例（MT5を閉じて実行。Prepare→Import→Verify→Cleanup）
.\tools\reimport-oanda-ticks.ps1 -CustomSymbol USDJPY_HIST -SourceSymbol USDJPY `
  -ZipDir "tick\OANDA\USDJPY_201609~" -BackupPath D:\Backup\mt5-custom-before-tickfix-20260921
# 件数照合で不一致の月のTester補完検証だけをやり直す場合: -Phase TesterCheck
```
## 実行手順（USDJPYサンプル）

```powershell
npm ci --prefix tools/tick-data
.\tools\tick-data.ps1 run -Config tools\tick-data\profiles\dukascopy-USDJPY-sample.json -HistoryQuality -QualityFromDate 2020.03.04 -QualityToDate 2020.03.06
.\tools\tick-data.ps1 status -Config tools\tick-data\profiles\dukascopy-USDJPY-sample.json
```

全期間（2016-09〜2020-12）は`dukascopy-USDJPY.json`。中断しても同じコマンドの再実行で再開できる。同じ期間を再取得した場合は`diff -Other <旧dataset.json>`でchunkのchecksum差分を確認できる。既存の`run-strategy-tester.ps1`は無変更で、取込後は`-CaseFile`のケースの`symbol`へCustom Symbol名を指定して使う。

## テスト

`python/tests/test_tickdata_core.py`・`test_tickdata_pipeline.py`（`.\tools\test-phase10.ps1`に含まれる）。外部通信は行わず、Providerはmock・偽subprocessで置き換える。実Dukascopy・MT5実機での確認結果は`DECISIONS.md` DEC-036を参照。
