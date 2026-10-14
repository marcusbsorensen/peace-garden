// What a copy of the site serves, path by path, without a browser:
//
// - `tools/deploy.sh --check`'s rows, with the same wanted status and type,
//   and the rows it does not have: every page in Server/index.php's table,
//   every area's read route, and a miss that must be a 404;
// - the association file, parsed, and its Team ID against project.yml;
// - every public file in Server/ and every page, fetched and hashed, so two
//   runs (local and live) can be compared file by file;
// - every internal link the crawl found, if given the crawl's results.
//
//   node tools/masstest/site/checks.mjs --base http://127.0.0.1:8822 --name local --out <dir> [--links <results.jsonl>]
//   node tools/masstest/site/checks.mjs --base http://127.0.0.1:8830 --name live  --out <dir>   (through proxy.mjs)
//
// GET only. Against the live site, go through proxy.mjs, which holds the
// whole run to two requests a second and fetches each address once.
import { createHash } from 'node:crypto';
import { readFile, readdir, writeFile, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join, relative } from 'node:path';
import { createInterface } from 'node:readline';
import { createReadStream } from 'node:fs';
import { SERVER } from './lib/site.mjs';

const args = Object.fromEntries(process.argv.slice(2).reduce((acc, a, i, all) => {
  if (a.startsWith('--')) acc.push([a.slice(2), all[i + 1] && !all[i + 1].startsWith('--') ? all[i + 1] : '1']);
  return acc;
}, []));
const base = (args.base || 'http://127.0.0.1:8822').replace(/\/$/, '');
const name = args.name || 'local';
const out = args.out || 'masstest-out';
await mkdir(out, { recursive: true });

// deploy.sh's rows, in its order, then the ones it leaves out.
const DEPLOY = [
  ['/', 200, 'text/html'], ['/s', 200, 'text/html'], ['/g', 200, 'text/html'], ['/garden', 200, 'text/html'],
  ['/download', 200, 'text/html'], ['/wild', 200, 'text/html'], ['/walk', 200, 'text/html'], ['/t', 200, 'text/html'],
  ['/meanings', 200, 'text/html'], ['/glasshouse', 200, 'text/html'], ['/coppice', 200, 'text/html'],
  ['/ground', 200, 'text/html'], ['/.well-known/apple-app-site-association', 200, 'application/json'],
  ['/assets/site.css', 200, 'text/css'], ['/assets/js/page.js', 200, 'application/javascript'],
  ['/assets/js/frontpage.js', 200, 'application/javascript'], ['/assets/js/longwalk.js', 200, 'application/javascript'],
  ['/assets/js/sky.js', 200, 'application/javascript'], ['/assets/js/plant.js', 200, 'application/javascript'],
  ['/plant.wasm', 200, 'application/wasm'], ['/assets/js/glasshouse.js', 200, 'application/javascript'],
  ['/assets/js/glasshousepage.js', 200, 'application/javascript'], ['/api/glasshouse', 200, 'application/json'],
  ['/assets/js/coppice.js', 200, 'application/javascript'], ['/assets/js/coppicepage.js', 200, 'application/javascript'],
  ['/api/coppice', 200, 'application/json'], ['/assets/js/ground.js', 200, 'application/javascript'],
  ['/assets/js/groundpage.js', 200, 'application/javascript'], ['/api/ground', 200, 'application/json'],
  ['/assets/js/plantpanel.js', 200, 'application/javascript'], ['/assets/js/shadow.js', 200, 'application/javascript'],
  ['/assets/js/slab.js', 200, 'application/javascript'], ['/assets/places.json', 200, 'application/json'],
  ['/assets/stars.bin', 200, 'application/octet-stream'], ['/assets/icon.svg', 200, 'image/svg+xml'],
  ['/assets/favicon.svg', 200, 'image/svg+xml'], ['/assets/mark-dark.svg', 200, 'image/svg+xml'],
  ['/assets/mark-light.svg', 200, 'image/svg+xml'], ['/languages.json', 200, 'application/json'],
  ['/strings/fr.json', 200, 'application/json'], ['/passages/fr.json', 200, 'application/json'],
  ['/favicon.ico', 200, 'image/'], ['/strings/en.json', 404, 'text/html'], ['/README.md', 404, 'text/html'],
  ['/.api/curate.php', 403, 'text/html'],
].map(([path, status, type]) => ({ path, status, type, list: 'deploy' }));
const EXTRA = [
  ...['/quiet', '/cross', '/orchard', '/knot', '/seedbed', '/frame', '/privacy'].map((path) => ({ path, status: 200, type: 'text/html' })),
  ...['garden', 'walk', 'quiet', 'cross', 'orchard', 'knot', 'seedbed', 'frame', 'wild'].map((a) => ({ path: `/api/${a}`, status: 200, type: 'application/json' })),
  ...['walk', 'quiet', 'cross', 'orchard', 'knot', 'seedbed', 'frame', 'glasshouse', 'coppice', 'ground'].map((a) => ({ path: `/api/${a}/plot/0`, status: 200, type: 'application/json' })),
  { path: '/api/wild/tile/0/0', status: 200, type: 'application/json' },
  { path: '/no-such-page-masstest', status: 404, type: 'text/html' },
  { path: '/testers.json', status: 200, type: 'application/json' },
].map((row) => ({ ...row, list: 'extra' }));

const KEEP = ['content-type', 'content-encoding', 'cache-control', 'etag', 'last-modified', 'vary', 'x-content-type-options',
  'x-robots-tag', 'strict-transport-security', 'content-security-policy', 'referrer-policy', 'permissions-policy',
  'x-frame-options', 'server', 'expires', 'age', 'x-cache', 'cf-cache-status'];

const sha = (buf) => createHash('sha256').update(buf).digest('hex').slice(0, 16);
// A page names each script and the stylesheet by its copy's mtime and size,
// and carries an import map of the same; neither says anything about the
// words, so they come out before two copies of a page are compared.
const normalisePage = (text) => text
  .replace(/\?v=[0-9a-fx-]+/g, '?v=')
  .replace(/<script type="importmap">[^<]*<\/script>\n?/g, '');

async function get(path) {
  const t = Date.now();
  try {
    const r = await fetch(base + path, { redirect: 'manual', headers: { 'accept-encoding': 'gzip, br' } });
    const body = Buffer.from(await r.arrayBuffer());
    const headers = {};
    for (const k of KEEP) if (r.headers.get(k) !== null) headers[k] = r.headers.get(k);
    return { status: r.status, headers, body, ms: Date.now() - t };
  } catch (e) {
    return { status: 0, headers: {}, body: Buffer.alloc(0), error: String(e.cause && e.cause.code || e.message), ms: Date.now() - t };
  }
}

const result = { base, name, at: new Date().toISOString(), rows: [], files: {}, aasa: null, links: [] };

for (const row of [...DEPLOY, ...EXTRA]) {
  const r = await get(row.path);
  const type = (r.headers['content-type'] || '').toLowerCase();
  const ok = r.status === row.status && type.startsWith(row.type);
  result.rows.push({ ...row, got: r.status, gotType: type, ok, headers: r.headers, bytes: r.body.length, hash: sha(r.body), error: r.error,
    sample: row.path.startsWith('/api/') ? r.body.toString('utf8').slice(0, 160) : undefined });
}

// The association file.
{
  const r = await get('/.well-known/apple-app-site-association');
  const yml = await readFile(join(SERVER, '..', 'project.yml'), 'utf8').catch(() => '');
  const team = (yml.match(/DEVELOPMENT_TEAM:\s*([A-Z0-9]+)/) || [])[1] || null;
  try {
    const json = JSON.parse(r.body.toString('utf8'));
    const appID = json.applinks.details[0].appIDs[0];
    result.aasa = { ok: true, appID, team: appID.split('.')[0], projectTeam: team, matches: appID.split('.')[0] === team,
      appclips: json.appclips || null, paths: json.applinks.details[0].components || json.applinks.details[0].paths || null, hash: sha(r.body) };
  } catch (e) {
    result.aasa = { ok: false, error: e.message, status: r.status };
  }
}

// Every public file, and every page.
async function walk(dir) {
  const found = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('.') || entry.name === 'README.md') continue;
    const full = join(dir, entry.name);
    if (entry.isDirectory()) found.push(...await walk(full));
    else found.push(full);
  }
  return found;
}
const files = (await walk(SERVER)).map((f) => '/' + relative(SERVER, f)).filter((p) => p !== '/index.php').sort();
const pages = ['/', '/s', '/g', '/garden', '/download', '/wild', '/walk', '/quiet', '/cross', '/orchard', '/knot', '/seedbed',
  '/frame', '/glasshouse', '/coppice', '/ground', '/meanings', '/t', '/privacy'];
for (const path of [...pages, ...files]) {
  if (path === '/strings/en.json') continue;
  const r = await get(path);
  const isPage = pages.includes(path);
  const text = isPage ? r.body.toString('utf8') : null;
  const entry = { status: r.status, type: r.headers['content-type'] || null, encoding: r.headers['content-encoding'] || null,
    bytes: r.body.length, hash: sha(isPage ? Buffer.from(normalisePage(text)) : r.body) };
  if (isPage) {
    entry.module = (text.match(/\/plant\.wasm\?v=([0-9a-fx-]+)/) || [])[1] || null;
    entry.stamps = [...text.matchAll(/(?:src|href)="(\/assets\/[^"?]+)\?v=([0-9a-fx-]+)"/g)].map((m) => `${m[1]}@${m[2]}`);
  }
  if (path.startsWith('/strings/') && r.status === 200) {
    try { entry.strings = JSON.parse(r.body.toString('utf8')).strings; } catch { /* hashed only */ }
  }
  result.files[path] = entry;
}

// Internal links, from a crawl's results.
if (args.links && existsSync(args.links)) {
  const hrefs = new Map();
  const lines = createInterface({ input: createReadStream(args.links) });
  for await (const line of lines) {
    if (!line) continue;
    let rec;
    try { rec = JSON.parse(line); } catch { continue; }
    for (const href of (rec.audit && rec.audit.links) || []) {
      if (/^(https?:)?\/\//.test(href) && !href.includes('peacegarden.app')) { hrefs.set(href, hrefs.get(href) || rec.job.page); continue; }
      if (/^(mailto|tel|sms|javascript):/.test(href)) continue;
      if (href.startsWith('#')) continue;
      hrefs.set(href, hrefs.get(href) || rec.job.page);
    }
  }
  for (const [href, from] of hrefs) {
    if (/^https?:\/\//.test(href) && !href.includes('peacegarden.app')) { result.links.push({ href, from, external: true }); continue; }
    const u = new URL(href.replace(/^https?:\/\/peacegarden\.app/, ''), 'http://x');
    const r = await get(u.pathname);
    let anchor = null;
    if (u.hash && !/^#p=/.test(u.hash) && r.status === 200) anchor = r.body.toString('utf8').includes(`id="${decodeURIComponent(u.hash.slice(1))}"`);
    result.links.push({ href, from, status: r.status, anchor });
  }
}

const file = join(out, `checks-${name}.json`);
await writeFile(file, JSON.stringify(result, null, 1));
const bad = result.rows.filter((r) => !r.ok);
console.log(`${name}: ${result.rows.length} rows, ${bad.length} not as wanted; ${Object.keys(result.files).length} files hashed; ${result.links.length} links. -> ${file}`);
for (const r of bad) console.log(`  BAD ${r.path} ${r.got} ${r.gotType} (wanted ${r.status} ${r.type})`);
