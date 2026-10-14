// The plant module, in Node, for the crawler's seeding: the same WASI stand-in
// as tools/wasm/send-arrivals.mjs, with the module's own naming beside it.
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

export async function engine(file = fileURLToPath(new URL('../../../Server/.pages/PlantWasm.wasm', import.meta.url))) {
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
  const { instance } = await WebAssembly.instantiate(await readFile(file), { wasi_snapshot_preview1: wasi });
  const e = instance.exports;
  memory = e.memory;
  e._initialize();
  const result = (length) => JSON.parse(new TextDecoder().decode(new Uint8Array(memory.buffer, e.pg_result(), length)));
  return {
    exports: e,
    lineage: (n, kind = '') => result(e[kind ? `pg_${kind}_lineage` : 'pg_lineage'](n)),
    name(plant) {
      const words = new TextEncoder().encode([plant.seed, ...plant.parents, plant.encounter].join(' '));
      const pointer = e.pg_alloc(words.length);
      new Uint8Array(memory.buffer, pointer, words.length).set(words);
      const length = e.pg_name(pointer, words.length);
      e.pg_free(pointer);
      return length ? result(length) : null;
    },
  };
}
