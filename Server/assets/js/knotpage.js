// The Knot Garden, on the page.
//
// **It draws what the plot service holds and nothing else.** The module that
// puts a plot on a canvas, `knot.js`, can also invent one — five hundred
// arrivals planted by the same rule, which is how the template was argued about
// before anybody had planted anything in it. That belongs to the workbench at
// `/dev/knot` and not here, for the reason `walkpage.js` gives: a page that can
// be asked by its own query string to show plants nobody grew is a page that
// can be linked to as if those plants were real.
//
// **One plot at a time**, as the Quiet Garden's, the Crossing's and the
// Orchard's pages are. A walk is a length you look down, so `/walk` shows three
// end to end; a knot is a figure, and two side by side read as neither one knot
// nor two.
import { loadModule } from './plant.js';
import { makePlotStage } from './longwalk.js';
import { growKnotFromService, makeKnotGround, plan } from './knot.js';
import { makeSky } from './sky.js';
import { dressed, whenSettled } from './plain.js';
import { openWays } from './gates.js';

const el = (id) => document.getElementById(id);
const note = el('note');

// Where this page stands on the map. The bar says it, the link back to the
// garden carries it, and `gates.js` marks it on the map at the foot of the
// page — all three from this one word.
//
// **Drawn whether or not the plot service answers.** A page that cannot reach
// its plants is exactly the page a reader needs a way out of.
const THEME = 'pattern';
whenSettled((strings) => openWays(THEME, strings));

const say = async (key) => {
  const strings = await dressed;
  note.textContent = strings.t(key);
  strings.dress(note, key);
  note.hidden = false;
};

async function place() {
  const engine = await loadModule(document.documentElement.dataset.module || '/plant.wasm');
  // The plot's own numbers — where the knot's runs and the edging lie, how
  // thick and how high a band is — come from the module rather than being
  // written down again here, so the page cannot disagree with the rule about
  // where a compartment begins.
  // **One plot, framed as though there were a little more than one**, the
  // Quiet Garden's margin: a single square framed tight touches the sides of
  // its band, and a plot with air round it reads as a place you are looking
  // into rather than a texture filling the screen.
  const stage = makePlotStage(el('stage'), 1.25, engine, makeKnotGround(plan(engine)));

  let sky = null;
  makeSky(el('sky'), {
    quarterTurns: () => stage.turn(),
    // Only the bar is in the sky now — the heading, the paragraph and the keys
    // are below the drawing, where the mask has already taken the stars off.
    keepClear: () => [...document.querySelectorAll('.page .masthead')]
      .map((node) => node.getBoundingClientRect())
      .filter((box) => box.width > 0 && box.height > 0),
  }).then((made) => { sky = made; }).catch((trouble) => {
    console.warn('no sky:', trouble);
  });

  const turn = (quarters) => { stage.turnBy(quarters); sky?.draw(); };
  el('left').addEventListener('click', () => turn(-1));
  el('right').addEventListener('click', () => turn(1));

  const { plots: opened } = await (await fetch('/api/knot')).json();
  if (!opened) {
    await say('walkEmpty');
    return;
  }

  let plot = 0;
  const growing = () => say('walkGrowing');
  const show = async () => {
    el('back').disabled = plot === 0;
    el('on').disabled = plot + 1 >= opened;
    await growKnotFromService(engine, stage, plot, growing);
    note.hidden = true;
  };

  el('back').addEventListener('click', () => { plot = Math.max(0, plot - 1); show(); });
  el('on').addEventListener('click', () => { plot = Math.min(opened - 1, plot + 1); show(); });
  el('keys').hidden = false;
  await show();
}

place().catch((trouble) => {
  console.warn('no knot garden:', trouble);
  say('knotAway');
});
