// A read-only, rate-limited, caching window onto the live site, so the
// crawler can look at peacegarden.app without leaning on it.
//
//   node tools/masstest/site/proxy.mjs --port 8830 --log <dir>/proxy.log
//
// Then point crawl.mjs (with --live) and checks.mjs at http://127.0.0.1:8830.
//
// What it guarantees, whatever the browser behind it asks for:
//
// - **GET only.** Any other method is answered 405 here and never sent on.
//   HEAD is sent on as a GET and answered without the body.
// - **Only paths a reader can GET**: the pages in Server/index.php's table,
//   static files (/assets/, /strings/, /passages/, /languages.json,
//   /testers.json, /favicon.ico, /plant.wasm, /.well-known/…), a few known
//   misses the deploy check reads (/README.md, /strings/en.json,
//   /.api/curate.php), and the plot service's read routes — /api/garden, an
//   area's count and its plots, the Wild Fields' count and tiles. Every write
//   route is a POST, and refused above; anything else under /api/ is
//   refused here as well (405), so nothing that writes can be reached even
//   by a GET.
// - **At most two requests a second**, one at a time, to the live host,
//   with a User-Agent naming this as Peace Garden's own check.
// - **Each address fetched once.** A page's `?l=` is not sent on (index.php
//   reads only the path, so every language gets the same bytes), and every
//   response is kept for the life of the proxy and served again from memory.
//
// Each request sent on is logged: time, method, path, status, bytes.
import http from 'node:http';
import https from 'node:https';
import { appendFileSync } from 'node:fs';

const args = Object.fromEntries(process.argv.slice(2).reduce((acc, a, i, all) => {
  if (a.startsWith('--')) acc.push([a.slice(2), all[i + 1] && !all[i + 1].startsWith('--') ? all[i + 1] : '1']);
  return acc;
}, []));
const port = Number(args.port || 8830);
const upstream = new URL(args.upstream || 'https://peacegarden.app');
const gap = Number(args.gap || 500);
const log = args.log || null;
const UA = 'PeaceGardenSiteCheck/1.0 (Peace Garden\'s own read-only site check; GET only, 2 req/s; +https://peacegarden.app)';

const PAGES = new Set(['/', '/s', '/g', '/garden', '/download', '/wild', '/walk', '/quiet', '/cross', '/orchard', '/knot',
  '/seedbed', '/frame', '/glasshouse', '/coppice', '/ground', '/meanings', '/t', '/privacy']);
const AREAS = 'walk|quiet|cross|orchard|knot|seedbed|frame|glasshouse|coppice|ground';
const READS = [
  /^\/api\/garden$/,
  new RegExp(`^/api/(${AREAS})$`),
  new RegExp(`^/api/(${AREAS})/plot/(0|[1-9][0-9]{0,5})$`),
  /^\/api\/wild$/,
  /^\/api\/wild\/tile\/[0-9]{1,2}\/[0-9]{1,2}$/,
];
const STATIC = [/^\/assets\/[A-Za-z0-9_./-]+$/, /^\/strings\/[a-z-]+\.json$/, /^\/passages\/[a-z-]+\.json$/,
  /^\/(languages|testers)\.json$/, /^\/favicon\.ico$/, /^\/plant\.wasm$/, /^\/\.well-known\/apple-app-site-association$/,
  /^\/README\.md$/, /^\/\.api\/curate\.php$/, /^\/no-such-page-masstest$/];

function allowed(path) {
  if (PAGES.has(path)) return true;
  if (path.startsWith('/api/')) return READS.some((r) => r.test(path));
  return STATIC.some((r) => r.test(path));
}

const cache = new Map();
let queue = Promise.resolve();
let last = 0;
let sent = 0;

function fetchUpstream(path) {
  const job = queue.then(async () => {
    const wait = last + gap - Date.now();
    if (wait > 0) await new Promise((r) => setTimeout(r, wait));
    last = Date.now();
    sent += 1;
    return new Promise((resolve) => {
      const started = Date.now();
      const req = https.request({
        host: upstream.hostname, port: 443, path, method: 'GET',
        headers: { 'user-agent': UA, 'accept-encoding': 'gzip, br', accept: '*/*' },
        timeout: 30000,
      }, (res) => {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => {
          const body = Buffer.concat(chunks);
          if (log) appendFileSync(log, `${new Date().toISOString()} GET ${path} ${res.statusCode} ${body.length} ${Date.now() - started}ms\n`);
          resolve({ status: res.statusCode, headers: res.headers, body });
        });
      });
      req.on('timeout', () => req.destroy(new Error('timeout')));
      req.on('error', (e) => {
        if (log) appendFileSync(log, `${new Date().toISOString()} GET ${path} ERR ${e.message}\n`);
        resolve({ status: 502, headers: { 'content-type': 'text/plain' }, body: Buffer.from(`upstream: ${e.message}\n`) });
      });
      req.end();
    });
  });
  queue = job.catch(() => {});
  return job;
}

const HOP = new Set(['connection', 'keep-alive', 'transfer-encoding', 'content-length', 'alt-svc']);
http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://local');
  const path = decodeURIComponent(url.pathname);
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    if (log) appendFileSync(log, `${new Date().toISOString()} REFUSED ${req.method} ${req.url}\n`);
    res.writeHead(405, { 'content-type': 'text/plain', allow: 'GET, HEAD' });
    return res.end('This window onto the live site is read-only.\n');
  }
  if (!allowed(path)) {
    if (log) appendFileSync(log, `${new Date().toISOString()} REFUSED GET ${req.url}\n`);
    res.writeHead(405, { 'content-type': 'text/plain' });
    return res.end('Not a path this check reads.\n');
  }
  const upstreamPath = PAGES.has(path) ? url.pathname : url.pathname + url.search;
  let entry = cache.get(upstreamPath);
  if (!entry) {
    entry = fetchUpstream(upstreamPath);
    cache.set(upstreamPath, entry);
  }
  const { status, headers, body } = await entry;
  const out = {};
  for (const [k, v] of Object.entries(headers)) if (!HOP.has(k)) out[k] = v;
  if (out.location) out.location = String(out.location).replace(upstream.origin, `http://127.0.0.1:${port}`);
  out['content-length'] = body.length;
  out['x-mt-proxy'] = 'live';
  res.writeHead(status, out);
  res.end(req.method === 'HEAD' ? undefined : body);
}).listen(port, '127.0.0.1', () => {
  console.log(`Read-only window onto ${upstream.origin} at http://127.0.0.1:${port} (one request every ${gap} ms)`);
});

process.on('SIGTERM', () => {
  if (log) appendFileSync(log, `${new Date().toISOString()} STOP sent=${sent} cached=${cache.size}\n`);
  process.exit(0);
});
