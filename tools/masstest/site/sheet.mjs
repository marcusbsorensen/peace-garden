// Contact sheets of faults: crops and screenshots laid out with captions,
// rendered by the same browser into one JPEG per sheet.
//
//   node tools/masstest/site/sheet.mjs <spec.json> <out-dir>
//
// spec.json: [{ "name": "01-contrast", "title": "…", "note": "…", "width": 1400, "cols": 4,
//               "tiles": [{ "file": "/abs/crop.jpg", "caption": "front · ar · 375 · dark" }] }]
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { tmpdir } from 'node:os';
import { launch } from './lib/browser.mjs';

const [specFile, outDir] = process.argv.slice(2);
const specs = JSON.parse(await readFile(specFile, 'utf8'));
await mkdir(outDir, { recursive: true });
const browser = await launch();
const escape = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
for (const spec of specs) {
  const width = spec.width || 1400;
  const cols = spec.cols || 4;
  const html = `<!doctype html><meta charset="utf-8"><style>
    body{margin:0;padding:20px;background:#1b1b1b;color:#eee;font:14px/1.35 -apple-system,Helvetica,Arial,sans-serif;width:${width - 40}px}
    h1{font-size:20px;margin:0 0 4px} p.note{margin:0 0 14px;color:#bbb;max-width:${width - 80}px}
    .grid{display:grid;grid-template-columns:repeat(${cols},1fr);gap:12px;align-items:start}
    figure{margin:0;background:#2a2a2a;padding:6px;border-radius:6px}
    img{display:block;max-width:100%;max-height:${spec.maxTile || 520}px;margin:0 auto;object-fit:contain;background:#000}
    figcaption{font-size:12px;color:#ddd;margin-top:5px;word-break:break-word}
  </style><h1>${escape(spec.title)}</h1>${spec.note ? `<p class="note">${escape(spec.note)}</p>` : ''}
  <div class="grid">${spec.tiles.map((t) => `<figure><img src="${pathToFileURL(t.file)}"><figcaption>${escape(t.caption)}</figcaption></figure>`).join('')}</div>`;
  const file = join(tmpdir(), `masstest-sheet-${spec.name}.html`);
  await writeFile(file, html);
  const ctx = await browser.newContext({ viewport: { width, height: 800 }, deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  await page.goto(pathToFileURL(file).href, { waitUntil: 'load' });
  await page.screenshot({ path: join(outDir, `${spec.name}.jpg`), type: 'jpeg', quality: spec.quality || 62, fullPage: true });
  await ctx.close();
  console.log(`${spec.name}.jpg: ${spec.tiles.length} tiles`);
}
await browser.close();
