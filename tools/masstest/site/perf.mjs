// Page weight, LCP and CLS for every page, on a phone on a slow connection.
//
//   node tools/masstest/site/perf.mjs --base http://127.0.0.1:8822 --out <dir> [--langs en,de] [--live]
//
// 375 × 812, touch, and Chrome DevTools' own "Slow 4G" numbers — 150 ms of
// latency, 1.6 Mbit/s down, 750 kbit/s up — with the CPU slowed four times.
// Each page is opened cold (a new context, nothing cached), then opened again
// in the same context (what a returning reader pays).
//
// Bytes are what crossed the wire (`encodedDataLength`), so compression
// counts. LCP and CLS are what Chrome reports to the page; LCP ignores a
// WebGL canvas, so on the area pages it is the largest text or image rather
// than the plot.
import { mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { launch, contextOptions } from './lib/browser.mjs';
import { initScript } from './lib/inpage.mjs';
import { PAGES, pinned, urlFor } from './lib/site.mjs';

const args = Object.fromEntries(process.argv.slice(2).reduce((acc, a, i, all) => {
  if (a.startsWith('--')) acc.push([a.slice(2), all[i + 1] && !all[i + 1].startsWith('--') ? all[i + 1] : '1']);
  return acc;
}, []));
const base = (args.base || 'http://127.0.0.1:8822').replace(/\/$/, '');
const out = args.out || 'masstest-out';
const langs = (args.langs || 'en').split(',');
const only = args.pages ? args.pages.split(',') : null;
const live = args.live === '1';
const origin = new URL(base).origin;
await mkdir(out, { recursive: true });
const pin = await pinned();
for (const p of PAGES) if (p.hash === 'PINNED') p.hashValue = pin;

const browser = await launch();
const rows = [];

async function measure(page, cdp, url) {
  const requests = new Map();
  let bytes = 0;
  const byType = {};
  cdp.removeAllListeners('Network.requestWillBeSent');
  cdp.removeAllListeners('Network.loadingFinished');
  cdp.removeAllListeners('Network.responseReceived');
  cdp.on('Network.requestWillBeSent', (e) => requests.set(e.requestId, { url: e.request.url, type: e.type }));
  cdp.on('Network.responseReceived', (e) => { const r = requests.get(e.requestId); if (r) { r.status = e.response.status; r.cached = e.response.fromDiskCache || e.response.fromMemoryCache; } });
  cdp.on('Network.loadingFinished', (e) => {
    bytes += e.encodedDataLength;
    const r = requests.get(e.requestId);
    const type = r ? r.type : 'Other';
    byType[type] = (byType[type] || 0) + e.encodedDataLength;
    if (r) r.bytes = e.encodedDataLength;
  });
  const t0 = Date.now();
  await page.goto(url, { waitUntil: 'load', timeout: 120000 });
  const load = Date.now() - t0;
  await page.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => {});
  const idle = Date.now() - t0;
  await page.waitForTimeout(1500);
  const pg = await page.evaluate(() => ({ shiftSources: window.__pg.shiftSources || [], langAt: window.__pg.langAt, lcp: window.__pg.lcp, lcpElement: window.__pg.lcpElement, cls: window.__pg.cls, shifts: window.__pg.shifts, fcp: window.__pg.fcp,
    wasm: window.__pg.wasm.map((w) => ({ ok: w.ok, ready: w.t + (w.ms || 0) })) }));
  const list = [...requests.values()];
  const biggest = list.filter((r) => r.bytes).sort((a, b) => b.bytes - a.bytes).slice(0, 4)
    .map((r) => `${r.url.replace(origin, '').replace(/\?v=[^&]*/, '')} ${Math.round(r.bytes / 1024)} KB`);
  return { load, idle, bytes, requests: list.length, notModified: list.filter((r) => r.status === 304).length, byType, biggest, ...pg, cls: Math.round(pg.cls * 1000) / 1000 };
}

for (const lang of langs) {
  for (const p of PAGES.filter((x) => !only || only.includes(x.id))) {
    const ctx = await browser.newContext(contextOptions({ width: 375, scheme: 'dark' }));
    await ctx.addInitScript(initScript);
    // No request interception here even when live, because it would turn the
    // browser's cache off and the warm figure would mean nothing; the proxy
    // is what holds a live run to reading.
    const page = await ctx.newPage();
    const cdp = await ctx.newCDPSession(page);
    await cdp.send('Network.enable');
    await cdp.send('Network.emulateNetworkConditions', { offline: false, latency: 150, downloadThroughput: (1.6 * 1024 * 1024) / 8, uploadThroughput: (750 * 1024) / 8 });
    await cdp.send('Emulation.setCPUThrottlingRate', { rate: 4 });
    const url = urlFor(base, p, lang);
    try {
      const cold = await measure(page, cdp, url);
      const warm = await measure(page, cdp, url);
      rows.push({ page: p.id, lang, url, cold, warm });
      console.log(`${p.id.padEnd(10)} ${lang} cold ${Math.round(cold.bytes / 1024)} KB ${cold.requests} req LCP ${cold.lcp} CLS ${cold.cls} load ${cold.load} | warm ${Math.round(warm.bytes / 1024)} KB`);
    } catch (e) {
      rows.push({ page: p.id, lang, url, crash: String(e.message).slice(0, 300) });
    }
    await ctx.close();
  }
}
await browser.close();
await writeFile(join(out, `perf${live ? '-live' : ''}${only ? '-' + only.join('-') : ''}.json`), JSON.stringify(rows, null, 1));
