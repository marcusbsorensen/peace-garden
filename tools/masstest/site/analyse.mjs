// Reads a crawl's results and the checks beside them, and says what went wrong
// where: every fault grouped by its cause, with the pages, languages and
// widths it was seen at, an example to reproduce, and the crops taken.
//
//   node tools/masstest/site/analyse.mjs --out <dir> [--results results.jsonl] [--name local]
//
// Writes <dir>/summary-<name>.json and <dir>/summary-<name>.md.
import { createReadStream, existsSync } from 'node:fs';
import { readFile, writeFile, readdir } from 'node:fs/promises';
import { createInterface } from 'node:readline';
import { join } from 'node:path';
import { EN, KEYS } from '../../../Server/assets/js/strings.js';
import { SERVER } from './lib/site.mjs';

const args = Object.fromEntries(process.argv.slice(2).reduce((acc, a, i, all) => {
  if (a.startsWith('--')) acc.push([a.slice(2), all[i + 1] && !all[i + 1].startsWith('--') ? all[i + 1] : '1']);
  return acc;
}, []));
const out = args.out || 'masstest-out';
const name = args.name || 'local';
const resultsFile = args.results || join(out, 'results.jsonl');

// The seeded names and places beside wild plants are the same in every
// language on purpose; they are data, not the site's words.
const SEEDED = new Set(['Marcus', 'Ane-Sofie Kristiansen', 'Ζωή', 'محمد عبد الرحمن', 'שרה', 'Иван', '美咲', 'Siobhán Ní Bhriain',
  'Bartholomew Featherstonehaugh-Cholmondeley Jr.', 'Józef', 'Þórunn', 'Kalaallit Nunaat Inuk', 'Margate',
  'The long bench by the harbour wall at Broadstairs', 'København', 'القاهرة', 'ירושלים', 'Reykjavík', '東京', 'Nuuk', 'Gdańsk',
  'Ciudad de México, Coyoacán, junto a la fuente']);
const ENGLISH = /\b(the|and|your|with|from|that|this|which|you|their|they|what|when|where|isn't|doesn't|can't)\b/i;
const ENVALUES = new Set(Object.values(EN).map((v) => String(v).replace(/\s+/g, ' ').trim()));

const groups = new Map();
function note(kind, cause, job, detail = {}) {
  const key = `${kind}::${cause}`;
  let g = groups.get(key);
  if (!g) {
    g = { kind, cause, pages: new Set(), langs: new Set(), widths: new Set(), schemes: new Set(), variants: new Set(), n: 0, examples: [], crops: [] };
    groups.set(key, g);
  }
  g.n += 1;
  g.pages.add(job.page); g.langs.add(job.lang); g.widths.add(job.width); g.schemes.add(job.scheme); g.variants.add(job.variant);
  if (g.examples.length < 4) g.examples.push({ url: job.url, width: job.width, scheme: job.scheme, motion: job.motion, ...detail });
  if (detail.crop && g.crops.length < 12) g.crops.push({ file: detail.crop, page: job.page, lang: job.lang, width: job.width, scheme: job.scheme });
}

const counts = { pages: 0, byVariant: {}, byWidth: {}, langs: new Set(), routes: new Set(), crashed: 0, loadMs: [], axeRuns: 0 };
const english = new Map(); // context -> Set of strings on the English page
const others = [];          // [context, job, strings] for the comparison afterwards

// The last reading of each page wins: a `--redo` appends a second one.
const latest = new Map();
const lines = createInterface({ input: createReadStream(resultsFile) });
for await (const line of lines) {
  if (!line) continue;
  try { const r = JSON.parse(line); latest.set(r.job.key, line); } catch { continue; }
}
let retried = 0;
for (const line of latest.values()) {
  const r = JSON.parse(line);
  if (r.retry) retried += 1;
  const job = r.job;
  counts.pages += 1;
  counts.byVariant[job.variant] = (counts.byVariant[job.variant] || 0) + 1;
  counts.byWidth[job.width] = (counts.byWidth[job.width] || 0) + 1;
  counts.langs.add(job.lang); counts.routes.add(job.page);
  if (r.loadMs) counts.loadMs.push(r.loadMs);
  if (r.crash) { counts.crashed += 1; note('crash', r.crash.split('\n')[0].slice(0, 120), job); continue; }
  if (r.status !== 200) note('status', `${r.status}`, job);
  for (const c of r.console) note(c.type === 'error' ? 'console-error' : 'console-warning', `${c.text.replace(/\d+/g, 'N').slice(0, 160)} @ ${c.at || '?'}`, job);
  for (const e of r.errors) note('exception', e.split('\n').slice(0, 2).join(' | ').slice(0, 200), job);
  for (const f of r.failed) note('request-failed', `${f.method} ${f.url.replace(/\?.*$/, '')} ${f.why}`, job);
  for (const h of r.http) if (!(h.status === 404 && h.url === '/strings/en.json')) note('http', `${h.status} ${h.url.replace(/\?.*$/, '')}`, job);
  for (const x of r.external || []) note('external-request', x.replace(/\?.*$/, ''), job);
  for (const b of r.blocked || []) note('blocked-write', b.replace(/\?.*$/, ''), job);
  const a = r.audit;
  if (!a) continue;
  if (r.noIdle) note('slow', 'network never went quiet within 8 s', job);
  for (const w of a.pg.wasm || []) if (w.ok === false) note('wasm', `${w.fn} failed: ${w.error}`, job);
  if ((a.pg.wasm || []).some((w) => w.ok === undefined)) note('wasm', 'instantiation still pending when read', job);
  for (const g of a.pg.gl || []) if (!g.ok) note('webgl', `${g.type} context refused`, job);
  if (a.pg.glLost) note('webgl', 'context lost', job);
  for (const rej of a.pg.rejections || []) note('rejection', rej.split('\n')[0].slice(0, 160), job);
  if (a.scrollableX > 0) note('h-overflow', `${job.page} scrolls sideways at ${job.width}`, job, { by: a.scrollableX, wide: a.wide.slice(0, 3), crop: r.crops && r.crops.wide });
  for (const w of a.wide || []) if (!(a.scrollableX > 0)) note('beyond-edge', w.sel, job, { text: w.text, left: w.left, right: w.right, crop: r.crops && r.crops.wide });
  for (const c of a.clipped || []) note('text-clipped', `${c.sel}  by  ${c.by}`, job, { text: c.text, over: c.over, axis: c.axis, crop: r.crops && r.crops.clip });
  for (const s of a.spills || []) note('text-spills', s.sel, job, { text: s.text, over: s.over, box: s.box, crop: r.crops && r.crops.spill });
  for (const o of a.overlaps || []) note('text-overlap', `${o.a}  ×  ${o.b}`, job, { a: o.at, b: o.bt, crop: r.crops && r.crops.overlap });
  for (const o of a.offscreenText || []) note('text-offscreen', o.sel, job, { text: o.text, crop: r.crops && r.crops.offtext });
  // /t, the test roster, is English by design (it says so, and stands a
  // reader in a language by its own buttons rather than by `?l=`).
  const roster = job.page === 't';
  if (job.lang !== 'en' && !roster) {
    for (const f of a.fellBack || []) note('fallback-en', f.key || `(no key) ${f.sel}`, job, { text: f.text });
    if (a.lang !== job.lang) note('lang-attr', `html lang="${a.lang}" for ${job.lang}`, job);
  }
  for (const k of a.rawKeys || []) if (KEYS.includes(k)) note('raw-key', k, job);
  for (const p of a.placeholders || []) note('placeholder', p, job);
  for (const k of a.emptyKeys || []) note('empty-key', k, job);
  for (const i of a.imgNoAlt || []) note('img-no-alt', i, job);
  for (const i of a.imgBroken || []) note('img-broken', i, job);
  for (const c of a.controlsNoName || []) note('control-no-name', c, job);
  for (const h of a.badAnchors || []) note('bad-anchor', h, job);
  if (['ar', 'he', 'fa', 'ur'].includes(job.lang) && !roster) {
    if (a.dir !== 'rtl') note('rtl', `document is ${a.dir}`, job);
    if (a.bar && a.bar.home < a.bar.ways) note('rtl', 'bar not mirrored: wordmark left of the ways', job);
    for (const x of (a.rtl && a.rtl.ltrWithRtl) || []) note('rtl', `left-to-right box holding ${job.lang} text: ${x.sel}`, job, { text: x.text });
    for (const x of (a.rtl && a.rtl.rtlLatinPunct) || []) note('rtl', `Latin run with end punctuation in a right-to-left box: ${x.sel}`, job, { text: x.text });
  }
  if (r.axe) {
    counts.axeRuns += 1;
    for (const v of r.axe) {
      const node = v.nodes[0] || {};
      note(`axe-${v.impact || 'n/a'}`, `${v.id}: ${node.target || ''}`, job,
        { help: v.help, count: v.count, data: node.data, html: node.html, crop: v.id === 'color-contrast' ? r.crops && r.crops.contrast : undefined });
    }
  }
  if (r.stills && job.motion === 'reduce' && (r.stills.changed > 0.001 || r.stills.rafPerSecond > 5)) {
    note('motion', `${job.page} moves under reduced motion`, job, r.stills);
  }
  if (r.stills) note('motion-measure', `${job.page} ${job.motion}`, job, r.stills);
  const ctx = `${job.variant}|${job.page}|${job.width}|${job.scheme}|${job.motion}`;
  const strings = (a.strings || []).filter((s) => !s.hidden).map((s) => ({ text: s.text, lang: s.lang, key: s.key }));
  if (job.lang === 'en') english.set(ctx, new Set(strings.map((s) => s.text)));
  else others.push([ctx, job, strings]);
}

// English left on a page in another language, that the catalogue does not
// know it left: words written into the markup or a script, not a key.
for (const [ctx, job, strings] of others) {
  if (job.page === 't') continue;
  const en = english.get(ctx);
  if (!en) continue;
  for (const s of strings) {
    if (!en.has(s.text) || SEEDED.has(s.text)) continue;
    if (s.lang === 'la' || s.lang === 'en') continue; // Latin is meant; lang="en" is the fallback, counted above
    const letters = (s.text.match(/\p{L}/gu) || []).length;
    if (letters < 4) continue;
    if (!(ENGLISH.test(s.text) || ENVALUES.has(s.text))) continue;
    note('english-unmarked', s.text.slice(0, 100), job, { key: s.key });
  }
}

// The catalogues themselves.
const stringsDir = join(SERVER, 'strings');
const catalogue = { keys: KEYS.length, languages: 0, missingEverywhere: [], partial: {}, perLanguage: {} };
for (const f of (await readdir(stringsDir)).filter((x) => x.endsWith('.json'))) {
  const code = f.replace('.json', '');
  const s = (JSON.parse(await readFile(join(stringsDir, f), 'utf8')).strings) || {};
  catalogue.languages += 1;
  const have = KEYS.filter((k) => typeof s[k] === 'string' && s[k].trim());
  catalogue.perLanguage[code] = have.length;
  for (const k of KEYS) if (!have.includes(k)) catalogue.partial[k] = (catalogue.partial[k] || 0) + 1;
}
catalogue.missingEverywhere = Object.entries(catalogue.partial).filter(([, n]) => n === catalogue.languages).map(([k]) => k);
for (const k of catalogue.missingEverywhere) delete catalogue.partial[k];

const load = counts.loadMs.sort((x, y) => x - y);
const summary = {
  name,
  retried,
  counts: { ...counts, langs: counts.langs.size, routes: counts.routes.size, loadMs: undefined,
    loadMedian: load[Math.floor(load.length / 2)], loadP95: load[Math.floor(load.length * 0.95)] },
  catalogue,
  groups: [...groups.values()].map((g) => ({ ...g, pages: [...g.pages], langs: [...g.langs].sort(), widths: [...g.widths], schemes: [...g.schemes], variants: [...g.variants] }))
    .sort((x, y) => x.kind.localeCompare(y.kind) || y.n - x.n),
};
await writeFile(join(out, `summary-${name}.json`), JSON.stringify(summary, null, 1));

// A readable digest.
const byKind = {};
for (const g of summary.groups) {
  byKind[g.kind] = byKind[g.kind] || { causes: 0, hits: 0, pages: new Set(), langs: new Set() };
  byKind[g.kind].causes += 1; byKind[g.kind].hits += g.n;
  g.pages.forEach((p) => byKind[g.kind].pages.add(p)); g.langs.forEach((l) => byKind[g.kind].langs.add(l));
}
const md = [];
md.push(`# ${name}: ${counts.pages} pages, ${counts.routes.size} routes, ${counts.langs.size} languages`);
md.push(`read again after settling: ${retried}`);
md.push(`variants ${JSON.stringify(counts.byVariant)}; widths ${JSON.stringify(counts.byWidth)}; crashed ${counts.crashed}; axe runs ${counts.axeRuns}; load median ${summary.counts.loadMedian} ms, p95 ${summary.counts.loadP95} ms`);
md.push('');
md.push('| kind | distinct causes | hits | routes | languages |');
md.push('| --- | ---: | ---: | ---: | ---: |');
for (const [kind, k] of Object.entries(byKind).sort()) md.push(`| ${kind} | ${k.causes} | ${k.hits} | ${k.pages.size} | ${k.langs.size} |`);
md.push('');
for (const g of summary.groups) {
  if (g.kind === 'motion-measure') continue;
  md.push(`- **${g.kind}** ${g.cause} — ${g.n}× on ${g.pages.join(',')} | langs ${g.langs.length} (${g.langs.slice(0, 8).join(',')}${g.langs.length > 8 ? '…' : ''}) | widths ${g.widths.join(',')} | ${g.schemes.join(',')} | e.g. ${g.examples[0] && g.examples[0].url}${g.examples[0] && g.examples[0].text ? ` "${g.examples[0].text}"` : ''}${g.examples[0] && g.examples[0].data ? ` ${JSON.stringify(g.examples[0].data)}` : ''}`);
}
md.push('');
md.push(`Catalogue: ${catalogue.keys} keys × ${catalogue.languages} languages; ${catalogue.missingEverywhere.length} keys in no language: ${catalogue.missingEverywhere.join(' ')}`);
md.push(`Partial: ${Object.entries(catalogue.partial).map(([k, n]) => `${k} missing in ${n}`).join('; ')}`);
md.push(`Per language: ${Object.entries(catalogue.perLanguage).map(([c, n]) => `${c} ${n}`).join(', ')}`);
await writeFile(join(out, `summary-${name}.md`), md.join('\n') + '\n');
console.log(`${name}: ${counts.pages} pages, ${summary.groups.length} fault groups -> ${join(out, `summary-${name}.md`)}`);
