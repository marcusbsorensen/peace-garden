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
import { loadModule } from './plant.js';
import { makeSky } from './sky.js';
import { dressed } from './plain.js';
import { openMovePad } from './movepad.js';
import { SIDE, flyOver, makeWildStage } from './wildfields.js';

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

async function field() {
  const engine = await loadModule(document.documentElement.dataset.module || '/plant.wasm');
  const { standing } = await (await fetch('/api/wild')).json();
  const from = await opening(standing);
  if (!from) say('wildEmpty');

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
  });
  flyOver(el('flies'), stage);

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
  await openMovePad({
    nav: el('keys'), canvas: el('stage'), stage, plots: 1, roam: true,
    show: async () => { await stage.settled(); },
    turned: () => sky?.draw(),
  });
}

field().catch((trouble) => {
  console.warn('no field:', trouble);
  say('wildAway');
});
