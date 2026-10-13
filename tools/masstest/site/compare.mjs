// Two checks.mjs runs side by side — a local copy and the live site — and
// every difference between them: rows whose status or type differ, headers
// one sends and the other does not, files present in one only, files whose
// bytes differ (pages compared with their build stamps taken out), and for a
// language catalogue, which keys differ.
//
//   node tools/masstest/site/compare.mjs <checks-local.json> <checks-live.json> [out.json]
import { readFile, writeFile } from 'node:fs/promises';

const [aFile, bFile, outFile] = process.argv.slice(2);
const a = JSON.parse(await readFile(aFile, 'utf8'));
const b = JSON.parse(await readFile(bFile, 'utf8'));
const diff = { a: a.name, b: b.name, rows: [], headers: [], files: [], strings: [], module: null, aasa: null };

const rowsB = new Map(b.rows.map((r) => [r.path, r]));
for (const ra of a.rows) {
  const rb = rowsB.get(ra.path);
  if (!rb) continue;
  if (ra.got !== rb.got || ra.gotType.split(';')[0] !== rb.gotType.split(';')[0]) {
    diff.rows.push({ path: ra.path, [a.name]: `${ra.got} ${ra.gotType}`, [b.name]: `${rb.got} ${rb.gotType}` });
  }
  for (const h of new Set([...Object.keys(ra.headers), ...Object.keys(rb.headers)])) {
    if (['etag', 'last-modified', 'age', 'content-type', 'x-cache', 'cf-cache-status', 'expires', 'server'].includes(h)) continue;
    const va = ra.headers[h] ?? null, vb = rb.headers[h] ?? null;
    if (va !== vb) diff.headers.push({ path: ra.path, header: h, [a.name]: va, [b.name]: vb });
  }
}
// The live host's own headers, whatever the local copy does.
diff.liveOnlyHeaders = [...new Set(b.rows.flatMap((r) => Object.keys(r.headers)))].sort();
diff.server = [...new Set(b.rows.map((r) => r.headers.server).filter(Boolean))];

for (const path of new Set([...Object.keys(a.files), ...Object.keys(b.files)])) {
  const fa = a.files[path], fb = b.files[path];
  if (!fa || !fb || fa.status !== fb.status) {
    diff.files.push({ path, [a.name]: fa ? fa.status : 'absent', [b.name]: fb ? fb.status : 'absent' });
    continue;
  }
  if (fa.hash !== fb.hash) diff.files.push({ path, change: 'bytes differ', [a.name]: fa.bytes, [b.name]: fb.bytes });
  if (fa.strings && fb.strings) {
    const keys = new Set([...Object.keys(fa.strings), ...Object.keys(fb.strings)]);
    for (const k of keys) {
      if (JSON.stringify(fa.strings[k] ?? null) !== JSON.stringify(fb.strings[k] ?? null)) {
        diff.strings.push({ file: path, key: k, [a.name]: fa.strings[k] ?? null, [b.name]: fb.strings[k] ?? null });
      }
    }
  }
}
const pa = a.files['/walk'], pb = b.files['/walk'];
diff.module = { [a.name]: pa && pa.module, [b.name]: pb && pb.module };
diff.aasa = { [a.name]: a.aasa, [b.name]: b.aasa };

if (outFile) await writeFile(outFile, JSON.stringify(diff, null, 1));
console.log(`rows differing: ${diff.rows.length}; header differences: ${diff.headers.length}; files differing: ${diff.files.length}; catalogue keys differing: ${diff.strings.length}`);
for (const r of diff.rows) console.log('  row', JSON.stringify(r));
for (const f of diff.files) console.log('  file', JSON.stringify(f));
for (const s of diff.strings.slice(0, 20)) console.log('  key', JSON.stringify(s).slice(0, 240));
const byHeader = {};
for (const h of diff.headers) (byHeader[h.header] = byHeader[h.header] || []).push(h);
for (const [h, list] of Object.entries(byHeader)) console.log(`  header ${h}: ${list.length} paths, e.g. ${JSON.stringify(list[0])}`);
console.log(`  module stamp: ${JSON.stringify(diff.module)}`);
console.log(`  live headers seen: ${diff.liveOnlyHeaders.join(', ')}; server: ${diff.server.join(', ')}`);
