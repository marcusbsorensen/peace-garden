// The Orchard, on the page.
//
// **It draws what the plot service holds and nothing else.** The module that
// puts a plot on a canvas, `orchard.js`, can also invent one — five hundred
// arrivals planted by the same rule, which is how the template was argued about
// before anybody had planted anything in it. That belongs to the workbench at
// `/dev/orchard` and not here, for the reason `walkpage.js` gives: a page that
// can be asked by its own query string to show plants nobody grew is a page
// that can be linked to as if those plants were real.
//
// **One plot at a time**, as the Quiet Garden's and the Crossing's pages are. A
// walk is a length you look down, so `/walk` shows three end to end; an orchard
// is a pattern you look into, and two quincunxes side by side read as ten trees
// rather than as five and five.
import { loadModule } from './plant.js';
import { makePlotStage } from './longwalk.js';
import { growOrchardFromService, makeOrchardGround, plan, trees } from './orchard.js';
import { makeSky } from './sky.js';
import { dressed } from './plain.js';

const el = (id) => document.getElementById(id);
const note = el('note');

const say = async (key) => {
  const strings = await dressed;
  note.textContent = strings.t(key);
  strings.dress(note, key);
  note.hidden = false;
};

async function place() {
  const engine = await loadModule(document.documentElement.dataset.module || '/plant.wasm');
  // The plot's own numbers — how far out the trees stand, how far a guild sits
  // from its trunk — and the five trunks themselves come from the module rather
  // than being written down again here, so the page cannot disagree with the
  // rule about the shape of the place or about where a tree is.
  // **One plot, framed as though there were a little more than one**, the
  // Quiet Garden's margin and for its reason: a single square framed tight
  // fills the middle of the screen and the page's prose lands on the planting.
  const stage = makePlotStage(el('stage'), 1.25, engine,
                              makeOrchardGround(plan(engine), trees(engine)));

  let sky = null;
  makeSky(el('sky'), {
    quarterTurns: () => stage.turn(),
    keepClear: () => [...document.querySelectorAll('.page .heading, .page .walk-about, .page .walk-note, .page .walk-keys, .page .masthead, .page .foot')]
      .map((node) => node.getBoundingClientRect())
      .filter((box) => box.width > 0 && box.height > 0),
  }).then((made) => { sky = made; }).catch((trouble) => {
    console.warn('no sky:', trouble);
  });

  const turn = (quarters) => { stage.turnBy(quarters); sky?.draw(); };
  el('left').addEventListener('click', () => turn(-1));
  el('right').addEventListener('click', () => turn(1));

  const { plots: opened } = await (await fetch('/api/orchard')).json();
  if (!opened) {
    await say('walkEmpty');
    return;
  }

  let plot = 0;
  const growing = () => say('walkGrowing');
  const show = async () => {
    el('back').disabled = plot === 0;
    el('on').disabled = plot + 1 >= opened;
    await growOrchardFromService(engine, stage, plot, growing);
    note.hidden = true;
  };

  el('back').addEventListener('click', () => { plot = Math.max(0, plot - 1); show(); });
  el('on').addEventListener('click', () => { plot = Math.min(opened - 1, plot + 1); show(); });
  el('keys').hidden = false;
  await show();
}

place().catch((trouble) => {
  console.warn('no orchard:', trouble);
  say('orchardAway');
});
