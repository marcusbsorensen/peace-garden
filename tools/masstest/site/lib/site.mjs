// What the site is, for the crawler: its pages, its languages, and the
// deep links that open a plant's panel on each area page.
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

export const SERVER = fileURLToPath(new URL('../../../../Server/', import.meta.url));

/// `night` marks the area pages, whose `body.night` is dark whatever the
/// reader's system says, so light is crawled for a sample of languages there.
///
/// Every page in `ROUTES` in Server/index.php, plus the seed page with the
/// pinned offer in its fragment (`PINNED` in link.js), which is what a seed
/// link actually opens.
export const PAGES = [
  { id: 'front', path: '/' },
  { id: 's', path: '/s' },
  { id: 's-offer', path: '/s', hash: 'PINNED' },
  { id: 'g', path: '/g' },
  { id: 'garden', path: '/garden' },
  { id: 'download', path: '/download' },
  { id: 'wild', path: '/wild', area: 'wild', night: true },
  { id: 'walk', path: '/walk', area: 'walk', night: true },
  { id: 'quiet', path: '/quiet', area: 'quiet', night: true },
  { id: 'cross', path: '/cross', area: 'cross', night: true },
  { id: 'orchard', path: '/orchard', area: 'orchard', night: true },
  { id: 'knot', path: '/knot', area: 'knot', night: true },
  { id: 'seedbed', path: '/seedbed', area: 'seedbed', night: true },
  { id: 'frame', path: '/frame', area: 'frame', night: true },
  { id: 'glasshouse', path: '/glasshouse', area: 'glasshouse', night: true },
  { id: 'coppice', path: '/coppice', area: 'coppice', night: true },
  { id: 'ground', path: '/ground', area: 'ground', night: true },
  { id: 'meanings', path: '/meanings' },
  { id: 't', path: '/t' },
  { id: 'privacy', path: '/privacy' },
];

export const RTL = new Set(['ar', 'he', 'fa', 'ur', 'yi']);

export async function pinned() {
  const source = await readFile(new URL('assets/js/link.js', `file://${SERVER}`), 'utf8');
  const m = source.match(/export const PINNED =([\s\S]*?);/);
  return m ? [...m[1].matchAll(/"([^"]*)"/g)].map((x) => x[1]).join('') : '';
}

export async function languages(base, fetcher = fetch) {
  try {
    const r = await fetcher(`${base}/languages.json`);
    if (r.ok) return (await r.json()).languages.map((l) => l.code);
  } catch { /* fall through to the checkout's copy */ }
  const file = JSON.parse(await readFile(new URL('languages.json', `file://${SERVER}`), 'utf8'));
  return file.languages.map((l) => l.code);
}

/// A plant to open on each area page: the first planting in plot 0 that has
/// parents (so not the ambassador, which is minted and has none), and for
/// the Wild Fields the first one with names beside it.
export async function plantLinks(base, fetcher = fetch) {
  const links = {};
  for (const page of PAGES.filter((p) => p.area && p.area !== 'wild')) {
    try {
      const r = await fetcher(`${base}/api/${page.area}/plot/0`);
      const j = await r.json();
      const plant = (j.plantings || []).find((p) => p.parents && p.parents.length === 2) || (j.plantings || [])[0];
      if (plant) links[page.id] = { search: 'plot=1', hash: `p=${plant.seed.slice(0, 12)}` };
    } catch { /* no panel variant for this area */ }
  }
  try {
    const r = await fetcher(`${base}/api/wild`);
    const j = await r.json();
    for (const [x, z] of (j.standing || []).slice(0, 12)) {
      const t = await (await fetcher(`${base}/api/wild/tile/${x}/${z}`)).json();
      const plant = (t.plantings || []).find((p) => p.shown && p.shown.names && p.shown.names.length) || null;
      if (plant) { links.wild = { search: '', hash: `p=${plant.seed.slice(0, 12)}` }; break; }
    }
    if (!links.wild && j.standing && j.standing.length) {
      const [x, z] = j.standing[0];
      const t = await (await fetcher(`${base}/api/wild/tile/${x}/${z}`)).json();
      if (t.plantings && t.plantings[0]) links.wild = { search: '', hash: `p=${t.plantings[0].seed.slice(0, 12)}` };
    }
  } catch { /* none */ }
  return links;
}

export function urlFor(base, page, lang, extra = {}) {
  const params = new URLSearchParams();
  if (lang) params.set('l', lang);
  if (extra.search) for (const [k, v] of new URLSearchParams(extra.search)) params.set(k, v);
  const q = params.toString();
  const hash = extra.hash || page.hashValue || '';
  return `${base}${page.path}${q ? '?' + q : ''}${hash ? '#' + hash : ''}`;
}
