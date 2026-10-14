// The browser, and the two npm modules the crawler needs, from wherever they
// were installed. Nothing here is committed with its dependencies: install
// them in a scratch folder and point PG_MASSTEST_MODULES at its node_modules,
// or install them beside this file (its .gitignore keeps them out of git).
import { createRequire } from 'node:module';
import { existsSync } from 'node:fs';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const here = fileURLToPath(new URL('..', import.meta.url));
const modules = process.env.PG_MASSTEST_MODULES || join(here, 'node_modules');
const require = createRequire(join(modules, 'noop.js'));

export const { chromium, webkit } = require('playwright-core');
export const axeSource = () => readFile(require.resolve('axe-core/axe.min.js'), 'utf8');

/// The browser to drive. PG_CHROME names one; otherwise Playwright's own
/// Chromium if it is whole, and the installed Google Chrome if it is not.
export function executable() {
  if (process.env.PG_CHROME) return process.env.PG_CHROME;
  const cache = join(process.env.HOME, 'Library/Caches/ms-playwright');
  for (const build of ['chromium-1248', 'chromium-1217']) {
    const app = join(cache, build, 'chrome-mac-arm64/Google Chrome for Testing.app');
    if (existsSync(join(app, 'Contents/Frameworks'))) return join(app, 'Contents/MacOS/Google Chrome for Testing');
  }
  return '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
}

/// `PG_BROWSER=webkit` drives Playwright's own WebKit instead (since 14 October
/// 2026), the engine of every browser on an iPhone or iPad. It is Playwright's
/// build, installed with `node <modules>/playwright-core/cli.js install webkit`,
/// not Safari, but it is the same engine: layout, fonts, wasm, WebGL and CSP.
export async function launch() {
  if (process.env.PG_BROWSER === 'webkit') return webkit.launch({ headless: true });
  return chromium.launch({ executablePath: executable(), headless: true });
}

/// A phone below 600 px, a tablet below 1000, a laptop above.
export function contextOptions({ width, scheme = 'dark', motion = 'no-preference', locale = 'en-GB', userAgent }) {
  const phone = width < 600;
  const tablet = !phone && width < 1000;
  return {
    viewport: { width, height: phone ? 812 : tablet ? 1024 : 800 },
    deviceScaleFactor: 1,
    isMobile: phone || tablet,
    hasTouch: phone || tablet,
    colorScheme: scheme,
    reducedMotion: motion,
    locale,
    ...(userAgent ? { userAgent } : {}),
  };
}
