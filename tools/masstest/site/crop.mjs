// Evidence crops: open a page, outline one element, and capture it with a
// margin, for a finding's contact sheet.
//
//   node tools/masstest/site/crop.mjs <spec.json> <out-dir>
//
// spec.json: [{ "name": "walk-de-growing", "url": "http://127.0.0.1:8822/walk?l=de", "width": 375,
//               "scheme": "dark", "selector": "#note", "settle": 0, "margin": 60, "page": false }]
// `selector` may be omitted (or `page: true`) for the viewport; `scroll` scrolls
// the element into the middle first; `key` presses a key before capturing.
import { readFile, mkdir } from 'node:fs/promises';
import { join } from 'node:path';
import { launch, contextOptions } from './lib/browser.mjs';

const [specFile, outDir] = process.argv.slice(2);
const specs = JSON.parse(await readFile(specFile, 'utf8'));
await mkdir(outDir, { recursive: true });
const browser = await launch();
for (const s of specs) {
  const ctx = await browser.newContext(contextOptions({ width: s.width || 375, scheme: s.scheme || 'dark', motion: s.motion || 'no-preference' }));
  const page = await ctx.newPage();
  if (s.height) await page.setViewportSize({ width: s.width, height: s.height });
  try {
    await page.goto(s.url, { waitUntil: 'load', timeout: 60000 });
    await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {});
    await page.waitForTimeout(s.settle ?? 1500);
    if (s.key) { await page.keyboard.press(s.key); await page.waitForTimeout(500); }
    const file = join(outDir, `${s.name}.jpg`);
    if (s.selector && !s.page) {
      const loc = page.locator(s.selector).first();
      await loc.scrollIntoViewIfNeeded({ timeout: 5000 }).catch(() => {});
      await loc.evaluate((el) => { el.style.outline = '2px solid #ff3b30'; el.style.outlineOffset = '2px'; });
      const box = await loc.boundingBox();
      const vp = page.viewportSize();
      const m = s.margin ?? 40;
      const x = Math.max(0, box.x - m), y = Math.max(0, box.y - m);
      await page.screenshot({ path: file, type: 'jpeg', quality: 65,
        clip: { x, y, width: Math.min(vp.width - x, box.width + 2 * m), height: Math.min(vp.height - y, box.height + 2 * m) } });
    } else {
      await page.screenshot({ path: file, type: 'jpeg', quality: 60, fullPage: !!s.full });
    }
    console.log(`${s.name}.jpg`);
  } catch (e) {
    console.log(`${s.name}: ${String(e.message).split('\n')[0]}`);
  }
  await ctx.close();
}
await browser.close();
