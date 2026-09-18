// Stands in for phones sending plants to the plot service, until phones can.
//
//   node tools/wasm/send-arrivals.mjs http://localhost:8803 120
//
// Each arrival is a real crossing grown by SeedCore in the browser module:
// its seed, both parents, the meeting, and the height and colour family a phone
// would read from the grown plant. They go to POST /api/walk/plant one at a
// time, in order, the way arrivals would, so the service places them by its
// PHP rule. Only a local copy with `open_for_planting` set will take them.
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const [base = 'http://localhost:8803', count = '48'] = process.argv.slice(2);

let memory;
const view = () => new DataView(memory.buffer);
const wasi = new Proxy({
  args_sizes_get: (a, b) => { view().setUint32(a, 0, true); view().setUint32(b, 0, true); return 0; },
  environ_sizes_get: (a, b) => { view().setUint32(a, 0, true); view().setUint32(b, 0, true); return 0; },
  args_get: () => 0, environ_get: () => 0,
  clock_time_get: (_i, _p, out) => { view().setBigUint64(out, 1n, true); return 0; },
  random_get: (p, n) => { crypto.getRandomValues(new Uint8Array(memory.buffer, p, n)); return 0; },
  fd_prestat_get: () => 8,
}, { get: (known, name) => known[name] ?? (() => 52) });

const file = fileURLToPath(new URL('./web/PlantWasm.wasm', import.meta.url));
const { instance } = await WebAssembly.instantiate(await readFile(file), { wasi_snapshot_preview1: wasi });
const e = instance.exports;
memory = e.memory;
e._initialize();

const tally = {};
for (let n = 0; n < Number(count); n++) {
  const length = e.pg_lineage(n);
  const body = new TextDecoder().decode(new Uint8Array(memory.buffer, e.pg_result(), length));
  const response = await fetch(`${base}/api/walk/plant`, { method: 'POST', body });
  tally[response.status] = (tally[response.status] ?? 0) + 1;
  if (response.status >= 400) {
    console.error(`arrival ${n}: ${response.status} ${await response.text()}`);
    process.exit(1);
  }
}
const walk = await (await fetch(`${base}/api/walk`)).json();
console.log(`Sent ${count} arrivals: ${JSON.stringify(tally)}. The walk has ${walk.plots} plots.`);
