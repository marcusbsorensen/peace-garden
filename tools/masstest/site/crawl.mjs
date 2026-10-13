// Crawls every page of the site in every language, at a phone's, a tablet's
// and a laptop's width, light and dark, and writes what each page did.
//
//   node tools/masstest/site/crawl.mjs --base http://127.0.0.1:8822 --out <dir>
//
// Options (all optional):
//   --pages front,walk,…    page ids from lib/site.mjs (default: all)
//   --langs en,da,…         language codes (default: all in languages.json)
//   --widths 375,1280       main pass widths
//   --schemes light,dark    prefers-color-scheme for the main pass
//   --variants plain,panel,tablet,motion
//                           plain  = every page × language × width × scheme
//                           panel  = area pages opened on a plant (postcard link), dark
//                           tablet = 768 px, a sample of languages, dark
//                           motion = reduced motion against full motion, en and ar, 375 px
//   --sample en,ar,…        languages for light on the night pages and the panel at 1280
//   --concurrency 6         pages at once
//   --axe 1                 run axe-core on every page (0 to skip)
//   --shots 1               keep a JPEG of every page (0 for none)
//   --settle 1200           ms to wait after the network goes quiet
//   --live                  the base is the read-only proxy (proxy.mjs): every
//                           request that is not a GET to the base is refused
//                           in the browser before it leaves, and recorded
//
// Results go to <out>/results.jsonl, one line a page, appended as each
// finishes, so a run that stops can be started again and skips what it has.
import { mkdir, appendFile, readFile, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { launch, contextOptions, axeSource } from './lib/browser.mjs';
import { initScript, audit } from './lib/inpage.mjs';
import { PAGES, RTL, pinned, languages, plantLinks, urlFor } from './lib/site.mjs';
import { difference } from './lib/png.mjs';

const args = Object.fromEntries(process.argv.slice(2).reduce((acc, a, i, all) => {
  if (a.startsWith('--')) acc.push([a.slice(2), all[i + 1] && !all[i + 1].startsWith('--') ? all[i + 1] : '1']);
  return acc;
}, []));
const base = (args.base || 'http://127.0.0.1:8822').replace(/\/$/, '');
const out = args.out || 'masstest-out';
const live = args.live === '1';
const concurrency = Number(args.concurrency || 6);
const settle = Number(args.settle || 1200);
const useAxe = args.axe !== '0';
const shots = args.shots !== '0';
const variants = new Set((args.variants || 'plain,panel,tablet,motion').split(','));
const widths = (args.widths || '375,1280').split(',').map(Number);
const schemes = (args.schemes || 'light,dark').split(',');

await mkdir(join(out, 'shots'), { recursive: true });
const resultsFile = join(out, 'results.jsonl');
const done = new Set();
if (existsSync(resultsFile)) {
  for (const line of (await readFile(resultsFile, 'utf8')).split('\n')) {
    if (!line) continue;
    try { done.add(JSON.parse(line).job.key); } catch { /* a torn last line */ }
  }
}

const allLangs = await languages(base);
const langs = args.langs ? args.langs.split(',') : allLangs;
const pages = args.pages ? PAGES.filter((p) => args.pages.split(',').includes(p.id)) : PAGES;
const pin = await pinned();
for (const p of PAGES) if (p.hash === 'PINNED') p.hashValue = pin;
const links = variants.has('panel') ? await plantLinks(base) : {};
const axe = useAxe ? await axeSource() : null;

// The languages crawled where a full sweep would repeat itself: light on the
// always-dark area pages, and the panel at laptop width.
const SAMPLE = (args.sample || 'en,ar,he,da,de,fi,ja,kl').split(',');
const jobs = [];
const add = (job) => {
  job.key = [job.variant, job.page.id, job.lang, job.width, job.scheme, job.motion].join('|');
  if (!done.has(job.key)) jobs.push(job);
};
if (variants.has('plain')) {
  for (const lang of langs) for (const page of pages) for (const width of widths) for (const scheme of schemes) {
    if (page.night && scheme === 'light' && !SAMPLE.includes(lang)) continue;
    add({ variant: 'plain', page, lang, width, scheme, motion: 'no-preference' });
  }
}
if (variants.has('panel')) {
  for (const lang of langs) for (const page of pages.filter((p) => links[p.id])) for (const width of widths) {
    if (width > 600 && !SAMPLE.includes(lang)) continue;
    add({ variant: 'panel', page, lang, width, scheme: 'dark', motion: 'no-preference', extra: links[page.id] });
  }
}
if (variants.has('tablet')) {
  for (const lang of ['en', 'da', 'de', 'ar', 'ja', 'fi'].filter((l) => langs.includes(l))) for (const page of pages) {
    add({ variant: 'tablet', page, lang, width: 768, scheme: 'dark', motion: 'no-preference' });
  }
}
if (variants.has('motion')) {
  for (const lang of ['en', 'ar'].filter((l) => langs.includes(l))) for (const page of pages) {
    add({ variant: 'motion', page, lang, width: 375, scheme: 'dark', motion: 'reduce' });
    if (lang === 'en') add({ variant: 'motion', page, lang, width: 375, scheme: 'dark', motion: 'no-preference' });
  }
}

console.log(`${jobs.length} pages to visit (${done.size} already done) on ${base}${live ? ' (live, read-only)' : ''}`);
const browser = await launch();
const contexts = new Map();
async function contextFor(job) {
  const key = `${job.width}|${job.scheme}|${job.motion}|${job.variant === 'motion' ? 'm' : ''}`;
  if (!contexts.has(key)) {
    contexts.set(key, (async () => {
      const ctx = await browser.newContext(contextOptions(job));
      await ctx.addInitScript(initScript);
      return ctx;
    })());
  }
  return contexts.get(key);
}

async function crop(page, selector, file) {
  const loc = page.locator(selector).first();
  if (!(await loc.count())) return null;
  await loc.scrollIntoViewIfNeeded({ timeout: 3000 }).catch(() => {});
  const box = await loc.boundingBox();
  if (!box) return null;
  const vp = page.viewportSize();
  const x = Math.max(0, box.x - 24);
  const y = Math.max(0, box.y - 24);
  const width = Math.min(vp.width - x, box.width + 48);
  const height = Math.min(vp.height - y, box.height + 48);
  if (width < 8 || height < 8) return null;
  await page.screenshot({ path: file, type: 'jpeg', quality: 60, clip: { x, y, width, height }, timeout: 10000 });
  return file;
}

const origin = new URL(base).origin;
async function visit(job) {
  const ctx = await contextFor(job);
  const page = await ctx.newPage();
  const url = urlFor(base, job.page, job.lang, job.extra);
  const rec = { job: { key: job.key, variant: job.variant, page: job.page.id, lang: job.lang, width: job.width, scheme: job.scheme, motion: job.motion, url },
    console: [], errors: [], failed: [], http: [], external: [], blocked: [] };
  page.on('console', (m) => {
    if (['error', 'warning', 'assert'].includes(m.type())) {
      const loc = m.location();
      rec.console.push({ type: m.type(), text: m.text().slice(0, 500), at: loc && loc.url ? `${loc.url.replace(origin, '').replace(/\?v=[^:]*/, '')}:${loc.lineNumber}` : null });
    }
  });
  page.on('pageerror', (e) => rec.errors.push(String(e.stack || e.message).slice(0, 800)));
  page.on('requestfailed', (r) => {
    const why = r.failure() && r.failure().errorText;
    if (why === 'net::ERR_ABORTED' && r.resourceType() === 'media') return;
    rec.failed.push({ url: r.url().replace(origin, ''), why, type: r.resourceType(), method: r.method() });
  });
  page.on('response', (r) => {
    if (r.status() >= 400) rec.http.push({ url: r.url().replace(origin, ''), status: r.status(), type: r.request().resourceType() });
  });
  page.on('request', (r) => {
    if (!r.url().startsWith(origin) && !r.url().startsWith('data:') && !r.url().startsWith('blob:')) rec.external.push(`${r.method()} ${r.url().slice(0, 120)}`);
  });
  if (live) {
    await page.route('**/*', (route) => {
      const r = route.request();
      if (r.method() !== 'GET' || !r.url().startsWith(origin)) {
        rec.blocked.push(`${r.method()} ${r.url().slice(0, 160)}`);
        return route.abort('blockedbyclient');
      }
      return route.continue();
    });
  }
  const t0 = Date.now();
  try {
    const response = await page.goto(url, { waitUntil: 'load', timeout: 60000 });
    rec.status = response ? response.status() : null;
    rec.type = response ? response.headers()['content-type'] : null;
    await page.waitForLoadState('networkidle', { timeout: 8000 }).catch(() => { rec.noIdle = true; });
    await page.waitForTimeout(job.variant === 'panel' ? settle + 1500 : settle);
    rec.loadMs = Date.now() - t0;
    rec.audit = await page.evaluate(audit, { rtl: RTL.has(job.lang) });
    if (job.variant === 'motion') {
      const raf0 = await page.evaluate(() => window.__pg.raf);
      const a = await page.screenshot({ type: 'png' });
      await page.waitForTimeout(1500);
      const b = await page.screenshot({ type: 'png' });
      const raf1 = await page.evaluate(() => window.__pg.raf);
      rec.stills = { changed: Math.round(difference(a, b) * 10000) / 10000, rafPerSecond: Math.round((raf1 - raf0) / 1.5) };
    }
    if (axe) {
      await page.addScriptTag({ content: axe });
      rec.axe = await page.evaluate(async () => {
        const r = await window.axe.run(document, {
          runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa', 'best-practice'] },
          resultTypes: ['violations'],
        });
        return r.violations.map((v) => ({
          id: v.id, impact: v.impact, help: v.help, count: v.nodes.length,
          nodes: v.nodes.slice(0, 4).map((n) => ({
            target: n.target.join(' '),
            html: n.html.slice(0, 160),
            data: v.id === 'color-contrast' && n.any[0] && n.any[0].data
              ? { fg: n.any[0].data.fgColor, bg: n.any[0].data.bgColor, ratio: n.any[0].data.contrastRatio, need: n.any[0].data.expectedContrastRatio, size: n.any[0].data.fontSize }
              : undefined,
          })),
        }));
      });
    }
    if (shots) {
      const dir = join(out, 'shots', job.variant, job.page.id);
      await mkdir(dir, { recursive: true });
      const stem = join(dir, `${job.lang}-${job.width}-${job.scheme}${job.motion === 'reduce' ? '-reduce' : ''}`);
      // One crop of each kind of fault the audit marked, as evidence.
      const kinds = { clip: '[data-mt-clip]', spill: '[data-mt-spill]', overlap: '[data-mt-overlap]', wide: '[data-mt-wide]', offtext: '[data-mt-offtext]' };
      const contrast = (rec.axe || []).find((v) => v.id === 'color-contrast');
      if (contrast) kinds.contrast = contrast.nodes[0].target;
      rec.crops = {};
      for (const [kind, selector] of Object.entries(kinds)) {
        const file = await crop(page, selector, `${stem}-${kind}.jpg`).catch(() => null);
        if (file) rec.crops[kind] = file;
      }
      await page.evaluate(() => window.scrollTo(0, 0));
      // A full-page capture resizes the viewport, and an area page regrows its
      // plot when the viewport changes, so those get the top and the foot
      // of the page at the size it was read at instead.
      const drawn = (rec.audit.canvases || []).length && (rec.audit.pg.gl || []).length;
      if (drawn) {
        await page.waitForTimeout(250);
        await page.screenshot({ path: `${stem}.jpg`, type: 'jpeg', quality: 55, timeout: 15000 }).catch(() => {});
        if (rec.audit.docHeight > rec.audit.viewport.h + 40) {
          await page.evaluate(() => window.scrollTo(0, document.documentElement.scrollHeight));
          await page.waitForTimeout(250);
          await page.screenshot({ path: `${stem}-foot.jpg`, type: 'jpeg', quality: 55, timeout: 15000 }).catch(() => {});
          rec.shotFoot = `${stem}-foot.jpg`;
        }
      } else {
        await page.screenshot({ path: `${stem}.jpg`, type: 'jpeg', quality: 55, fullPage: true, timeout: 30000 }).catch(() => {});
      }
      rec.shot = `${stem}.jpg`;
    }
  } catch (error) {
    rec.crash = String(error.message || error).slice(0, 500);
    rec.loadMs = Date.now() - t0;
  } finally {
    await page.close().catch(() => {});
  }
  await appendFile(resultsFile, JSON.stringify(rec) + '\n');
  return rec;
}

const started = Date.now();
let finished = 0;
let next = 0;
async function worker() {
  while (next < jobs.length) {
    const job = jobs[next++];
    const rec = await visit(job);
    finished++;
    if (finished % 50 === 0 || finished === jobs.length) {
      const per = (Date.now() - started) / finished;
      console.log(`${finished}/${jobs.length}  ${Math.round((Date.now() - started) / 1000)} s  eta ${Math.round(per * (jobs.length - finished) / 1000)} s  last ${rec.job.key} ${rec.crash ? 'CRASH' : rec.status}`);
    }
  }
}
await Promise.all(Array.from({ length: concurrency }, worker));
await browser.close();
await writeFile(join(out, 'crawl-done.json'), JSON.stringify({ base, live, jobs: jobs.length, seconds: Math.round((Date.now() - started) / 1000), at: new Date().toISOString() }));
console.log(`Done: ${finished} pages in ${Math.round((Date.now() - started) / 1000)} s.`);
