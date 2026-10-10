// The map at the foot of an area page and the gateways out past its plot put
// every neighbour on the same side.
//
//   node tools/reference/check_gateways.mjs
//
// An area page shows the garden's neighbours twice: as cells on the small map
// at its foot (`gates.js`), and as slabs of their ground out past the plot,
// each carrying its area's glyph (`beside.js`, `longwalk.js`). Marcus found
// on 10 October 2026 that the two did not seem to agree. Under Arabic or
// Hebrew they did not: the map's grid followed the writing direction and
// mirrored, and the gateways, like the pad's arrows, did not. Both now take
// their way round from one place, `screenWay` in `garden.js`, and this holds
// them to it and to the map as it was laid out — written down here rather
// than read back from `garden.js`, so a change to the map has to be made here
// too, on purpose.
//
// What it checks, for each of the ten areas:
//
// - `garden.js` has the neighbours below, each the way below;
// - the map at the foot of the page marks exactly those that are open as
//   beside it, each drawn that way from the reader's own cell;
// - the gateways are those same areas, each with its own glyph from `LOOK`;
// - at every quarter turn and on a phone's, a laptop's and a tablet's
//   canvas, each gateway is drawn, stands that way from the plot — more that
//   way than across it — and carries a glyph, but for the two a wall hides
//   (`HIDDEN`);
// - and the stylesheet pins both maps' grids left to right, which is the
//   half of the fault that lived in CSS.

import { readFile } from 'node:fs/promises';
import { AREAS, neighboursOf, screenWay } from '../../Server/assets/js/garden.js';
import { BUILT, LOOK, mapCells } from '../../Server/assets/js/gates.js';
import { areasBeside } from '../../Server/assets/js/beside.js';
import { placeBeside } from '../../Server/assets/js/longwalk.js';

// The map, five by two (docs/WEBSITE.md):
//
//   waiting  ground   beginnings  renewal  travel
//   peace    kinship  pattern     light    meeting
const MAP = {
  waiting: { right: 'ground', down: 'peace' },
  ground: { left: 'waiting', right: 'beginnings', down: 'kinship' },
  beginnings: { left: 'ground', right: 'renewal', down: 'pattern' },
  renewal: { left: 'beginnings', right: 'travel', down: 'light' },
  travel: { left: 'renewal', down: 'meeting' },
  peace: { up: 'waiting', right: 'kinship' },
  kinship: { up: 'ground', left: 'peace', right: 'pattern' },
  pattern: { up: 'beginnings', left: 'kinship', right: 'light' },
  light: { up: 'renewal', left: 'pattern', right: 'meeting' },
  meeting: { up: 'travel', left: 'light' },
};

// Which way each direction is on the screen, `[across, up]`.
const WAY = { up: [0, 1], down: [0, -1], left: [-1, 0], right: [1, 0] };

// How many plots' length each page's stage is framed to (`makePlotStage`):
// the Long Walk shows three end to end, every other area one, with a quarter
// more for air.
const SPAN = { travel: 3 };

// How tall the walls along each area's far edges are, in metres: the ground
// builders' `walls`, the yew round the Quiet Garden and behind the Long
// Walk's far border. Everywhere else nothing taller than a person's knee
// stands at the edge.
const WALLS = { travel: 2.0, peace: 2.0 };

// Canvases the gateways must work in, in CSS pixels: a phone, two laptops,
// a tablet held upright.
const CANVASES = [['a phone', 390, 388], ['a laptop', 1280, 495], ['a wide laptop', 1512, 540], ['a tablet', 768, 563]];

// **The two glyphs a wall hides**, and only these. The Quiet Garden's upper
// neighbour stands wholly behind its yew, which Marcus saw and kept on 27
// September 2026 (what a wall does to what is beyond it); the slab is still
// drawn. And on a phone, at the two turns that put the Long Walk's yew at its
// left-hand end, the Coppice shows too little below the yew for a glyph.
const HIDDEN = new Set(['peace up', 'travel left a phone 0', 'travel left a phone 2']);

let checks = 0;
const failures = [];
const fail = (line) => { if (failures.length < 12) failures.push(line); };
const same = (what, expected, got) => {
  checks++;
  if (JSON.stringify(expected) !== JSON.stringify(got)) {
    fail(`${what}: expected ${JSON.stringify(expected)}, found ${JSON.stringify(got)}`);
  }
};

checks++;
if (Object.keys(MAP).length !== AREAS.length || AREAS.some((a) => !MAP[a.theme])) {
  fail(`the map here names ${Object.keys(MAP).length} areas and garden.js ${AREAS.length}`);
}
for (const [direction, way] of Object.entries(WAY)) same(`screenWay(${direction})`, way, [...screenWay(direction)]);

for (const { theme } of AREAS) {
  const pinned = MAP[theme] ?? {};
  const sorted = (o) => Object.fromEntries(Object.entries(o).sort());

  // The map itself.
  same(`${theme}'s neighbours in garden.js`, sorted(pinned),
       sorted(Object.fromEntries(neighboursOf(theme).map((n) => [n.direction, n.area.theme]))));

  // The map at the foot of the page: where each marked cell is drawn from
  // the reader's own, counted as the grid counts, left to right and down.
  const open = Object.fromEntries(Object.entries(pinned).filter(([, next]) => BUILT[next]));
  const cells = mapCells(theme);
  const here = cells.filter((c) => c.here);
  same(`${theme}'s own cell on its map`, [theme], here.map((c) => c.area.theme));
  if (here.length === 1) {
    const marked = {};
    for (const cell of cells.filter((c) => c.beside)) {
      const way = [Math.sign(cell.column - here[0].column), -Math.sign(cell.row - here[0].row)];
      const direction = Object.keys(WAY).find((d) => WAY[d][0] === way[0] && WAY[d][1] === way[1]) ?? `[${way}]`;
      marked[direction] = cell.area.theme;
    }
    same(`the map at the foot of ${theme}'s page`, sorted(open), sorted(marked));
  }

  // The gateways: which, which way, and which glyph.
  const slabs = areasBeside(theme);
  same(`${theme}'s gateways`, sorted(open), sorted(Object.fromEntries(slabs.map((s) => [s.direction, s.theme]))));
  for (const slab of slabs) {
    same(`the way ${theme}'s ${slab.direction} gateway carries`, WAY[slab.direction], [...slab.way]);
    checks++;
    if (slab.glyph !== LOOK[slab.theme]?.glyph) fail(`${theme}'s ${slab.direction} gateway carries another area's glyph`);
  }

  // Where they are drawn, at every turn, on every canvas.
  const span = SPAN[theme] ?? 1.25;
  for (const [canvas, width, height] of CANVASES) {
    for (const turn of [0, 1, 2, 3]) {
      const placed = placeBeside(slabs, { turn, aspect: width / height, span, width, walls: WALLS[theme] ?? 0 });
      for (const slab of slabs) {
        const where = `${theme}'s ${slab.direction} gateway on ${canvas}, turned ${turn}`;
        const p = placed.find((q) => q.slab === slab);
        checks++;
        if (!p) { fail(`${where} is not drawn`); continue; }
        const [across, up] = WAY[slab.direction];
        const along = p.at[0] * across + p.at[1] * up;
        const aside = Math.abs(p.at[0] * up - p.at[1] * across);
        checks++;
        if (!(along > aside)) fail(`${where} stands at ${p.at.map((v) => v.toFixed(2))}, not ${slab.direction} of the plot`);
        const hidden = HIDDEN.has(`${theme} ${slab.direction}`) || HIDDEN.has(`${theme} ${slab.direction} ${canvas} ${turn}`);
        checks++;
        if (!p.glyph && !hidden) fail(`${where} has no room for its glyph`);
        if (p.glyph && hidden) fail(`${where} has a glyph where its wall was thought to hide it: take it off HIDDEN`);
      }
    }
  }
}

// The half that lived in the stylesheet: a grid follows the writing direction
// unless it is told otherwise.
const css = await readFile(new URL('../../Server/assets/site.css', import.meta.url), 'utf8');
for (const selector of ['.minimap', '.garden-grid']) {
  checks++;
  const rule = css.match(new RegExp(`(?:^|\\n)${selector.replace('.', '\\.')} \\{([^}]*)\\}`));
  if (!rule || !/direction:\s*ltr\s*;/.test(rule[1])) fail(`site.css does not pin ${selector} left to right`);
}

if (failures.length) {
  console.error('The map and the gateways disagree about where the neighbours are:');
  for (const line of failures) console.error(`  ${line}`);
  console.error('\nThe way round is screenWay in Server/assets/js/garden.js; the map is mapCells in gates.js,'
    + '\nthe gateways areasBeside in beside.js and placeBeside in longwalk.js.');
  process.exit(1);
}

console.log(`The map at the foot of all ten areas and their gateways put every neighbour on the same side, `
  + `at four turns on ${CANVASES.length} canvases: ${checks} checks.`);
