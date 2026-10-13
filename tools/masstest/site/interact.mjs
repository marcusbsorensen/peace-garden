// The parts of the site a crawl that only loads pages cannot see.
//
//   node tools/masstest/site/interact.mjs --base http://127.0.0.1:8822 --out <dir> [--live]
//
// 1. The language chooser on every page: pick Hebrew in the bar; does the page
//    redraw in it, right to left, and is the choice remembered on the next page
//    opened without `?l=`? Does `?l=` still outrank it?
// 2. Negotiation without `?l=` from the browser's own languages: da-DK, pt-BR,
//    nb/no, zh-Hant-TW, sr-Latn-RS, sw (none of ours), and an empty list.
// 3. On every area page at 375 px: the viewport losing 100 px of height, as a
//    phone's toolbar does on scroll: does the plot regrow ("Growing the
//    plants…") or stay?
// 4. Every page on a phone held sideways (812 × 375): overflow and clipping.
// 5. The keyboard sheet (`?`) on every page that has one.
// 6. The fragments area pages link to (/meanings#theme, /garden#theme).
// 7. Stillness under reduced motion, once the page has finished growing.
//
// `--only chooser,negotiation,resize,landscape,anchors,stillness` runs a part.
//
// Results: <out>/interact.json. Read-only: nothing here submits or posts.
import { mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { launch, contextOptions } from './lib/browser.mjs';
import { initScript, audit } from './lib/inpage.mjs';
import { PAGES, pinned, urlFor } from './lib/site.mjs';

const args = Object.fromEntries(process.argv.slice(2).reduce((acc, a, i, all) => {
  if (a.startsWith('--')) acc.push([a.slice(2), all[i + 1] && !all[i + 1].startsWith('--') ? all[i + 1] : '1']);
  return acc;
}, []));
const base = (args.base || 'http://127.0.0.1:8822').replace(/\/$/, '');
const out = args.out || 'masstest-out';
const live = args.live === '1';
const only = args.only ? new Set(args.only.split(',')) : null;
const run = (part) => !only || only.has(part);
await mkdir(join(out, 'interact'), { recursive: true });
const pin = await pinned();
for (const p of PAGES) if (p.hash === 'PINNED') p.hashValue = pin;
const origin = new URL(base).origin;

const browser = await launch();
const results = { chooser: [], negotiation: [], resize: [], landscape: [], keys: [] };

async function newPage(options) {
  const ctx = await browser.newContext(contextOptions(options));
  await ctx.addInitScript(initScript);
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e.message).slice(0, 300)));
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text().slice(0, 300)); });
  if (live) {
    await page.route('**/*', (route) => (route.request().method() !== 'GET' || !route.request().url().startsWith(origin)
      ? route.abort('blockedbyclient') : route.continue()));
  }
  return { ctx, page, errors };
}
async function settle(page, ms = 1200) {
  await page.waitForLoadState('networkidle', { timeout: 8000 }).catch(() => {});
  await page.waitForTimeout(ms);
}
const state = (page) => page.evaluate(() => {
  let stored = null;
  try { stored = localStorage.getItem('site.language.v1'); } catch { /* none */ }
  const select = document.querySelector('#language, select.chooser__select');
  const h = document.querySelector('h1, .heading');
  return { lang: document.documentElement.lang, dir: document.documentElement.dir || getComputedStyle(document.documentElement).direction,
    chooser: select ? select.value : null, options: select ? select.options.length : 0, stored,
    heading: h ? h.textContent.replace(/\s+/g, ' ').trim().slice(0, 80) : null, url: location.pathname + location.search };
});

// 1. The chooser.
for (const p of run('chooser') ? PAGES : []) {
  const { ctx, page, errors } = await newPage({ width: 375, scheme: 'dark' });
  try {
    await page.goto(urlFor(base, p, null), { waitUntil: 'load', timeout: 60000 });
    await settle(page);
    const before = await state(page);
    let after = null, next = null, outranked = null, navigated = false;
    const select = page.locator('#language, select.chooser__select').first();
    if (await select.count()) {
      const t = Date.now();
      page.once('framenavigated', () => { navigated = true; });
      await select.selectOption('he');
      await page.waitForTimeout(1500);
      after = { ...(await state(page)), ms: Date.now() - t };
      await page.goto(`${base}/privacy`, { waitUntil: 'load' });
      await settle(page, 600);
      next = await state(page);
      await page.goto(`${base}/privacy?l=da`, { waitUntil: 'load' });
      await settle(page, 600);
      outranked = await state(page);
    }
    results.chooser.push({ page: p.id, before, after, navigated, next, outranked, errors });
  } catch (e) {
    results.chooser.push({ page: p.id, crash: String(e.message).slice(0, 300) });
  }
  await ctx.close();
}

// 2. Negotiation.
for (const locale of run('negotiation') ? ['da-DK', 'pt-BR', 'no-NO', 'nb-NO', 'zh-TW', 'sr-Latn-RS', 'sw-KE', 'he-IL', 'kl-GL', 'cy-GB'] : []) {
  for (const id of ['front', 'walk']) {
    const p = PAGES.find((x) => x.id === id);
    const { ctx, page, errors } = await newPage({ width: 375, scheme: 'dark', locale });
    try {
      await page.goto(urlFor(base, p, null), { waitUntil: 'load', timeout: 60000 });
      await settle(page, 800);
      results.negotiation.push({ locale, page: id, ...(await state(page)), navigatorLanguages: await page.evaluate(() => navigator.languages), errors });
    } catch (e) {
      results.negotiation.push({ locale, page: id, crash: String(e.message).slice(0, 300) });
    }
    await ctx.close();
  }
}

// 3. The toolbar: 100 px of height lost and given back.
for (const p of run('resize') ? PAGES.filter((x) => x.night) : []) {
  const { ctx, page, errors } = await newPage({ width: 375, scheme: 'dark' });
  try {
    await page.goto(urlFor(base, p, 'en'), { waitUntil: 'load', timeout: 60000 });
    await settle(page, 2500);
    const growing = () => page.evaluate(() => /Growing the plants/.test(document.body.innerText));
    const wasmBefore = await page.evaluate(() => window.__pg.wasm.length);
    const at0 = await growing();
    await page.setViewportSize({ width: 375, height: 712 });
    const seen = [];
    let elapsed = 0;
    for (const ms of [60, 200, 500, 1200, 3000]) {
      await page.waitForTimeout(ms - elapsed);
      elapsed = ms;
      seen.push({ ms, growing: await growing() });
    }
    await page.screenshot({ path: join(out, 'interact', `resize-${p.id}.jpg`), type: 'jpeg', quality: 55 });
    await page.setViewportSize({ width: 375, height: 812 });
    await page.waitForTimeout(200);
    const back = await growing();
    results.resize.push({ page: p.id, at0, seen, backGrowing: back, wasmBefore, wasmAfter: await page.evaluate(() => window.__pg.wasm.length), errors });
  } catch (e) {
    results.resize.push({ page: p.id, crash: String(e.message).slice(0, 300) });
  }
  await ctx.close();
}

// 4. A phone held sideways, and 5. the keyboard sheet.
if (run('landscape')) {
  const { ctx, page, errors } = await newPage({ width: 812, scheme: 'dark' });
  await page.setViewportSize({ width: 812, height: 375 });
  for (const p of PAGES) {
    for (const lang of ['en', 'de', 'ar']) {
      try {
        await page.goto(urlFor(base, p, lang), { waitUntil: 'load', timeout: 60000 });
        await settle(page);
        const a = await page.evaluate(audit, { rtl: lang === 'ar' });
        await page.screenshot({ path: join(out, 'interact', `landscape-${p.id}-${lang}.jpg`), type: 'jpeg', quality: 50 });
        results.landscape.push({ page: p.id, lang, scrollableX: a.scrollableX, wide: a.wide, clipped: a.clipped, spills: a.spills,
          overlaps: a.overlaps, offscreenText: a.offscreenText, docHeight: a.docHeight, canvases: a.canvases });
      } catch (e) {
        results.landscape.push({ page: p.id, lang, crash: String(e.message).slice(0, 300) });
      }
    }
  }
  await ctx.close();
  const k = await newPage({ width: 1280, scheme: 'dark' });
  for (const p of PAGES) {
    try {
      await k.page.goto(urlFor(base, p, 'de'), { waitUntil: 'load', timeout: 60000 });
      await settle(k.page);
      await k.page.keyboard.press('?');
      await k.page.waitForTimeout(500);
      const sheet = await k.page.evaluate(() => {
        const d = document.querySelector('dialog[open], .keys-sheet, [class*="sheet"]:not([hidden])');
        return d ? { sel: d.className || d.tagName, text: d.innerText.replace(/\s+/g, ' ').slice(0, 300), focusInside: d.contains(document.activeElement) } : null;
      });
      let a = null;
      if (sheet) {
        a = await k.page.evaluate(audit, { rtl: false });
        await k.page.screenshot({ path: join(out, 'interact', `keys-${p.id}-de.jpg`), type: 'jpeg', quality: 55 });
        await k.page.keyboard.press('Escape');
        await k.page.waitForTimeout(300);
      }
      const closed = sheet ? await k.page.evaluate(() => !document.querySelector('dialog[open]')) : null;
      results.keys.push({ page: p.id, sheet, closed, clipped: a && a.clipped, spills: a && a.spills, fellBack: a && a.fellBack.map((f) => f.key || f.text) });
    } catch (e) {
      results.keys.push({ page: p.id, crash: String(e.message).slice(0, 300) });
    }
  }
  await k.ctx.close();
}

// 6. The fragments every area page links to: /meanings#<theme> must land on
//    that theme's entry, which the page builds in script; /garden#<theme>
//    must open the map on that area.
results.anchors = [];
if (run('anchors')) {
  const { ctx, page } = await newPage({ width: 375, scheme: 'dark' });
  for (const theme of ['travel', 'peace', 'meeting', 'kinship', 'pattern', 'beginnings', 'waiting', 'light', 'renewal', 'ground']) {
    try {
      await page.goto(`${base}/meanings?l=en#${theme}`, { waitUntil: 'load', timeout: 60000 });
      await settle(page, 800);
      const m = await page.evaluate((id) => {
        const el = document.getElementById(id);
        return el ? { found: true, top: Math.round(el.getBoundingClientRect().top), scrollY: Math.round(window.scrollY) } : { found: false };
      }, theme);
      await page.goto(`${base}/garden?l=en#${theme}`, { waitUntil: 'load', timeout: 60000 });
      await settle(page, 800);
      const g = await page.evaluate(() => ({ hash: location.hash, heading: (document.querySelector('h1, .heading, [data-s^="area"]') || {}).textContent || null }));
      results.anchors.push({ theme, meanings: m, garden: g });
    } catch (e) {
      results.anchors.push({ theme, crash: String(e.message).slice(0, 200) });
    }
  }
  await ctx.close();
}

// 7. Stillness: with reduced motion asked for, and the page given ten seconds
//    to finish growing, does anything on screen still move? Two captures
//    three seconds apart, compared pixel by pixel.
results.stillness = [];
if (run('stillness')) {
  const { difference } = await import('./lib/png.mjs');
  for (const motion of ['reduce', 'no-preference']) {
    const { ctx, page } = await newPage({ width: 375, scheme: 'dark', motion });
    for (const p of PAGES.filter((x) => x.night || x.id === 'front')) {
      try {
        await page.goto(urlFor(base, p, 'en'), { waitUntil: 'load', timeout: 60000 });
        await settle(page, 10000);
        const raf0 = await page.evaluate(() => window.__pg.raf);
        const a = await page.screenshot({ type: 'png' });
        await page.waitForTimeout(3000);
        const b = await page.screenshot({ type: 'png' });
        const raf1 = await page.evaluate(() => window.__pg.raf);
        results.stillness.push({ page: p.id, motion, changed: Math.round(difference(a, b) * 100000) / 100000, rafPerSecond: Math.round((raf1 - raf0) / 3) });
      } catch (e) {
        results.stillness.push({ page: p.id, motion, crash: String(e.message).slice(0, 200) });
      }
    }
    await ctx.close();
  }
}

await browser.close();
const file = join(out, only ? `interact-${[...only].join('-')}.json` : 'interact.json');
await writeFile(file, JSON.stringify(results, null, 1));
console.log(`interact: ${results.chooser.length} choosers, ${results.negotiation.length} negotiations, ${results.resize.length} resizes, ${results.landscape.length} landscape, ${results.keys.length} keyboard sheets, ${results.anchors.length} anchors, ${results.stillness.length} stillness -> ${file}`);
