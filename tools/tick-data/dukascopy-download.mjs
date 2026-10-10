// dukascopy-nodeで指定範囲（UTC、[from, to)）のtickを取得し、CSVとして書き出す薄いAdapter。
// chunk分割・resume・checksum・atomic renameはPython側（python/tickdata）が担う。ここで行うのは、
// Dukascopyのレート制限（HTTP 429）で範囲全体を失わないための「1時間単位の取得と待機・再試行」だけ。
//
// 使い方: node dukascopy-download.mjs --instrument usdjpy --from 2020-03-05T00:00:00.000Z --to 2020-03-06T00:00:00.000Z --out <file>
//   任意: --batch-pause-ms(時間ごとの待機、既定0。DECISIONS.md DEC-040参照) --retry-count(既定4) --retry-pause-ms(初回の待機、以後倍々、既定30000)
// 出力列: timestamp(UTCエポックms),askPrice,bidPrice,askVolume,bidVolume
import { createWriteStream } from "node:fs";
import { once } from "node:events";
import { getHistoricalRates } from "dukascopy-node";

const HOUR_MS = 3_600_000;

function parseArgs(argv) {
  const values = {};
  for (let index = 0; index < argv.length; index += 2) {
    const key = argv[index];
    if (!key.startsWith("--") || index + 1 >= argv.length) {
      throw new Error(`不正な引数です: ${key}`);
    }
    values[key.slice(2)] = argv[index + 1];
  }
  for (const required of ["instrument", "from", "to", "out"]) {
    if (!values[required]) {
      throw new Error(`--${required}が必要です`);
    }
  }
  return values;
}

const sleep = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

async function fetchHour(instrument, startMs, endMs, retryCount, retryPauseMs) {
  for (let attempt = 0; ; attempt += 1) {
    try {
      return await getHistoricalRates({
        instrument,
        dates: { from: new Date(startMs), to: new Date(endMs) },
        timeframe: "tick",
        format: "json",
        useCache: false,
        batchSize: 1,
        retryCount: 0,
      });
    } catch (error) {
      if (attempt >= retryCount) {
        throw error;
      }
      const pause = retryPauseMs * 2 ** attempt;
      console.error(`dukascopy-download: ${error.message} (hour=${new Date(startMs).toISOString()}), ${pause}ms後に再試行 ${attempt + 1}/${retryCount}`);
      await sleep(pause);
    }
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const fromMs = new Date(args.from).getTime();
  const toMs = new Date(args.to).getTime();
  if (Number.isNaN(fromMs) || Number.isNaN(toMs) || toMs <= fromMs) {
    throw new Error(`期間が不正です: ${args.from} - ${args.to}`);
  }
  const pauseMs = Number(args["batch-pause-ms"] ?? 0);
  const retryCount = Number(args["retry-count"] ?? 4);
  const retryPauseMs = Number(args["retry-pause-ms"] ?? 30000);

  const output = createWriteStream(args.out, { encoding: "utf8" });
  output.write("timestamp,askPrice,bidPrice,askVolume,bidVolume\n");
  let written = 0;
  let cursor = fromMs;
  while (cursor < toMs) {
    const hourEnd = Math.min((Math.floor(cursor / HOUR_MS) + 1) * HOUR_MS, toMs);
    const ticks = await fetchHour(args.instrument, cursor, hourEnd, retryCount, retryPauseMs);
    for (const tick of ticks) {
      // 区間は[cursor, hourEnd)。library側の境界の扱いに依存しない
      if (tick.timestamp < cursor || tick.timestamp >= hourEnd) {
        continue;
      }
      const line = `${tick.timestamp},${tick.askPrice},${tick.bidPrice},${tick.askVolume ?? 0},${tick.bidVolume ?? 0}\n`;
      if (!output.write(line)) {
        await once(output, "drain");
      }
      written += 1;
    }
    cursor = hourEnd;
    if (cursor < toMs) {
      await sleep(pauseMs);
    }
  }
  output.end();
  await once(output, "finish");
  console.error(`dukascopy-download: instrument=${args.instrument} ticks=${written}`);
}

main().catch((error) => {
  console.error(`dukascopy-download: ${error.message}`);
  process.exit(1);
});
