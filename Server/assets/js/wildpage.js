// The Wild Fields, on the page.
//
// **It draws what the plot service holds and nothing else**, for the reason
// `walkpage.js` gives: a page that could be asked by its own address to show
// plants nobody let go would be a page that could be linked to as if they had.
// Invented fields are the workbench's, at `/dev/wild`.
//
// **It opens over a plant.** The field is about four thousand square metres
// and a window shows a dozen across, so a reader set down in its middle would
// most likely be looking at grass. The service says how many plants stand in
// each tile; the page picks a tile in proportion to them and a plant in it, at
// random, and opens with that plant in the middle — *somewhere at random*, as
// the garden's own map has it. Nothing about the choice is kept or sent.
//
// **A plant opens the panel the areas use** (`plantpanel.js`, 1 October
// 2026): its name, what it means, its passage, and what its two gardeners
// chose to show beside it — their names, and the place and the month they met
// once both chose them. A postcard is `/wild#p=` and the first twelve
// characters of the seed, and the first eight of those are where it stands,
// so a postcard, or the app's *See it in the Wild Fields*, opens the page over
// the plant and then opens the plant.
//
// **Paths that visitors wear, only where the service has them on** (2
// October 2026, on /dev only; `wear.js`). `GET /api/wild` carries `wear` only
// where `config.php` turns it on, which the live site's does not; without it
// this page does not load `wear.js` at all, counts nothing, sends nothing and
// draws the ground as it was.
import { loadModule } from './plant.js';
import { makeSky } from './sky.js';
import { dressed } from './plain.js';
import { openMovePad } from './movepad.js';
import { plantPanel } from './plantpanel.js';
import { SIDE, flyOver, makeWildStage, spotOf } from './wildfields.js';

const el = (id) => document.getElementById(id);
const note = el('note');

const say = async (key) => {
  const strings = await dressed;
  note.textContent = strings.t(key);
  strings.dress(note, key);
  note.hidden = false;
};

// Where to open: a plant, chosen in proportion to where they stand, or the
// middle of the field when nothing has been released yet.
async function opening(standing) {
  const total = standing.reduce((sum, [, , n]) => sum + n, 0);
  if (!total) return null;
  let pick = Math.random() * total;
  const [x, z] = standing.find(([, , n]) => (pick -= n) < 0) ?? standing[standing.length - 1];
  const { plantings } = await (await fetch(`/api/wild/tile/${x}/${z}`)).json();
  return plantings[Math.floor(Math.random() * plantings.length)]?.spot ?? null;
}

// `#p=` and at least eight hex characters of a seed: a postcard to one plant.
function postcard() {
  const mark = location.hash.match(/^#p=([0-9a-f]{8,64})$/i)?.[1];
  return mark ? { mark: mark.toLowerCase(), done: false } : null;
}

// Who chose to stand beside a plant, for the panel: the names, then the place
// and the month, each on its own line. The names and the place are the
// gardeners' own words in their own script, so each runs in its own
// direction; the month is written by the reader's browser in the page's
// language.
//
// **Each of those words is isolated, and the line runs the page's way** (2
// October 2026). With `dir="auto"` the first strong letter set the line, so
// on a Japanese page a name in Hebrew turned the whole by-line right to left
// and *が育てた* landed on the wrong side of it. FSI…PDI keeps each name and
// the place to its own direction inside the line, and the line itself keeps
// the direction `dress` gives it: the page's, or English's where the string
// fell back.
const isolated = (words) => `\u2068${words}\u2069`;

function beside(plant, strings) {
  const shown = plant.shown;
  if (!shown || !strings) return [];
  const lines = [];
  const names = shown.names ?? [];
  if (names.length) {
    const key = names.length === 1 ? 'wildByOne' : 'wildByTwo';
    const line = text('p', 'plant-panel__ambassador',
      strings.t(key, names.length === 1
        ? { name: isolated(names[0]) }
        : { a: isolated(names[0]), b: isolated(names[1]) }));
    strings.dress(line, key);
    lines.push(line);
  }
  const month = monthWords(shown.month);
  const where = [shown.place && isolated(shown.place), month].filter(Boolean).join(' · ');
  if (where) {
    lines.push(text('p', 'plant-panel__ambassador plant-panel__met', where));
  }
  return lines;
}

function monthWords(month) {
  const [year, number] = (month ?? '').split('-').map(Number);
  if (!year || !number) return null;
  try {
    return new Intl.DateTimeFormat(document.documentElement.lang || 'en',
      { month: 'long', year: 'numeric', timeZone: 'UTC' }).format(new Date(Date.UTC(year, number - 1, 15)));
  } catch {
    return month;
  }
}

function text(tag, className, words) {
  const node = document.createElement(tag);
  node.className = className;
  node.textContent = words;
  return node;
}

async function field() {
  const engine = await loadModule(document.documentElement.dataset.module || '/plant.wasm');
  const { standing, wear } = await (await fetch('/api/wild')).json();
  // A postcard opens over its plant: the seed's first eight characters are
  // where it stands, so nothing need be fetched to go there.
  const card = postcard();
  const from = card ? spotOf(card.mark) : await opening(standing);
  if (!from) say('wildEmpty');

  // Wear, if the service has it on and counts the cells this page counts.
  const wearing = wear ? await import('./wear.js')
    .then((m) => (wear.cell === m.CELL && wear.cells === m.CELLS ? m : null))
    .catch(() => null) : null;
  const worn = wearing ? wearing.wornGround({ seen: wear.seen }) : null;
  let walker = null;

  const stage = makeWildStage(el('stage'), engine, {
    from: from ?? [SIDE / 2, SIDE / 2],
    source: async (x, z) => {
      const answer = await fetch(`/api/wild/tile/${x}/${z}`);
      if (!answer.ok) throw new Error(`tile ${x}, ${z}: ${answer.status}`);
      return (await answer.json()).plantings;
    },
    report: (growing) => {
      if (growing) say('walkGrowing');
      else if (from) note.hidden = true;
    },
    wear: worn,
    looked: (point) => walker?.looked(point),
  });
  flyOver(el('flies'), stage);
  if (wearing) {
    walker = wearing.walkOn({ canvas: el('stage'), nav: el('keys') });
    wearing.wearOfField().then((cells) => { worn.set(cells); stage.draw(); });
  }

  let sky = null;
  makeSky(el('sky'), {
    milkyWay: true,
    quarterTurns: () => stage.turn(),
    keepClear: () => [...document.querySelectorAll('.page .masthead')]
      .map((node) => node.getBoundingClientRect())
      .filter((box) => box.width > 0 && box.height > 0),
  }).then((made) => { sky = made; }).catch((trouble) => {
    console.warn('no sky:', trouble);
  });

  // The pad, the same as every area's, roaming: one field, no plots to step
  // between and no edge to leave the area by, so the four directions only
  // ever walk.
  const plants = plantPanel({
    theme: null,
    engine,
    beside,
    place: {
      read: () => card,
      finds: (one, wanted) => one.seed.toLowerCase().startsWith(wanted.mark),
      address: (plant, length) => {
        const url = new URL('/wild', location.origin);
        url.hash = `p=${plant.seed.slice(0, length).toLowerCase()}`;
        return url.href;
      },
      text: (name, strings) => strings.t('wildPostcardText', { name }),
    },
  });
  await openMovePad({
    nav: el('keys'), canvas: el('stage'), stage, plots: 1, roam: true, plants,
    show: async () => { await stage.settled(); },
    turned: () => sky?.draw(),
  });
}

field().catch((trouble) => {
  console.warn('no field:', trouble);
  say('wildAway');
});
