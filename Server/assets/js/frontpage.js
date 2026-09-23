// The front, at `/`.
//
// Two things the markup cannot do by itself: grow the plant on the stage, and
// draw the ten cards.
//
// **The plant is the child of a demonstration meeting**, `pg_front_meeting`,
// grown by `pg_grow_hybrid` — the app's own cross over two parents minted from
// fixed words. So it is what the app would grow from those two seeds, and it is
// nobody's. `?meeting=` is not read here, though the workbench reads it: a page
// that can be asked by its query string for a different plant is a page that
// can be linked to as if that plant meant something.
//
// **The cards are the map, read as a list.** Each is an area of `garden.js` in
// its `gates.js` ground colour with its glyph, what its plants mean from
// `meanings.js`, and its name — so a card cannot disagree with the area page it
// opens, or with the minimap at that page's foot.
import { loadModule, takeResult, decode, makeStage } from './plant.js';
import { AREAS } from './garden.js';
import { AREA_KEYS } from './strings.js';
import { BUILT, LOOK } from './gates.js';
import { themeRow } from './meanings.js';
import { whenSettled } from './plain.js';

const el = (id) => document.getElementById(id);
const SVG = 'http://www.w3.org/2000/svg';

// The demonstration meeting. Chosen by looking: the third is a plant that
// reads at the size of a stage and turns well.
const MEETING = 3;

async function grow() {
  const e = await loadModule(document.documentElement.dataset.module || '/plant.wasm');
  const words = new TextDecoder().decode(takeResult(e, e.pg_front_meeting(MEETING)));
  const bytes = new TextEncoder().encode(words);
  const at = e.pg_alloc(bytes.length);
  new Uint8Array(e.memory.buffer, at, bytes.length).set(bytes);
  const length = e.pg_grow_hybrid(at, bytes.length);
  e.pg_free(at);
  if (!length) throw new Error('the front meeting grew nothing');
  const grown = decode(takeResult(e, length));
  // Shown before drawing, so the canvas has a size to draw at.
  el('plant-stage').hidden = false;
  makeStage(el('plant')).show(grown);
}

// A browser with no WebGL2, or no module, has the words and the cards, which
// are the page. Nothing is said about the plant it could not draw.
grow().catch((trouble) => console.warn('no front plant:', trouble));

function glyph(path) {
  const svg = document.createElementNS(SVG, 'svg');
  svg.setAttribute('viewBox', '0 0 20 20');
  svg.setAttribute('aria-hidden', 'true');
  svg.setAttribute('focusable', 'false');
  const line = document.createElementNS(SVG, 'path');
  line.setAttribute('d', path);
  svg.append(line);
  return svg;
}

// Drawn again whenever the chooser changes, so it clears what it drew.
whenSettled((strings) => {
  // The canvas's name is the page's own heading: what the plant is.
  el('plant').setAttribute('aria-label', strings.t('tagline'));

  const cards = el('cards');
  cards.replaceChildren();
  // Open areas first, in map order, then the ones still to come.
  const order = [...AREAS].sort((p, q) =>
    (BUILT[q.theme] ? 1 : 0) - (BUILT[p.theme] ? 1 : 0) || p.y - q.y || p.x - q.x);
  for (const area of order) {
    const href = BUILT[area.theme];
    const card = document.createElement(href ? 'a' : 'div');
    card.className = href ? 'front-card' : 'front-card front-card--closed';
    if (href) card.href = href;
    card.style.setProperty('--area-ground', LOOK[area.theme].ground);

    const meaningKey = themeRow(area.theme).meaning;
    const meaning = document.createElement('p');
    meaning.className = 'front-card__meaning';
    meaning.textContent = strings.t(meaningKey);
    strings.dress(meaning, meaningKey);

    const nameKey = AREA_KEYS[area.theme];
    const name = document.createElement('h3');
    name.className = 'front-card__name';
    name.textContent = strings.t(nameKey);
    strings.dress(name, nameKey);

    card.append(glyph(LOOK[area.theme].glyph), meaning, name);
    if (!href) {
      const closed = document.createElement('span');
      closed.className = 'front-card__closed';
      closed.textContent = strings.t('notYet');
      strings.dress(closed, 'notYet');
      card.append(closed);
    }
    cards.append(card);
  }
});
