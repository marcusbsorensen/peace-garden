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
import { growOrchardFromService, makeOrchardGround, plan } from './orchard.js';
import { makeSky } from './sky.js';
import { dressed, whenSettled } from './plain.js';
import { openWays } from './gates.js';
import { openMovePad } from './movepad.js';
import { plantPanel } from './plantpanel.js';
import { showGathers } from './meanings.js';

const el = (id) => document.getElementById(id);
const note = el('note');

// Where this page stands on the map. The bar says it, the link back to the
// garden carries it, `gates.js` marks it on the map at the foot of the page,
// the pad leaves the area by it, and the slabs of the areas beside this one
// are drawn out in the sky from it — all five from this one word.
//
// **Drawn whether or not the plot service answers.** A page that cannot reach
// its plants is exactly the page a reader needs a way out of.
const THEME = 'kinship';
whenSettled((strings) => openWays(THEME, strings));
// And what the plants here mean, under the paragraph. The same one word says
// which row of `meanings.js` to read, so the block cannot name another area.
whenSettled((strings) => showGathers(THEME, strings));

const say = async (key) => {
  const strings = await dressed;
  note.textContent = strings.t(key);
  strings.dress(note, key);
  note.hidden = false;
};

async function place() {
  const engine = await loadModule(document.documentElement.dataset.module || '/plant.wasm');
  // The plot's own numbers — how far out the trees stand, how far a guild sits
  // from its trunk — and each plot's trunks, way and crescents, turned for the
  // plot, come from the module rather than being written down again here, so
  // the page cannot disagree with the rule about the shape of the place or
  // about where a tree is.
  // **One plot, framed as though there were a little more than one**, the
  // Quiet Garden's margin: a single square framed tight touches the sides of
  // its band, and a plot with air round it reads as a place you are looking
  // into rather than a texture filling the screen.
  const grove = plan(engine);
  const stage = makePlotStage(el('stage'), 1.25, engine, makeOrchardGround(grove));
  // And the areas beside this one, as slabs out in the sky past the plot:
  // the same one word again, and `beside.js` reads the map from it.
  stage.beside(THEME);

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

  const { plots: opened } = await (await fetch('/api/orchard')).json();
  if (!opened) {
    await say('walkEmpty');
    return;
  }

  // The pad: moving about this plot and on to the next, closer and further,
  // and turning. `movepad.js`, the same on every area page.
  const growing = () => say('walkGrowing');
  await openMovePad({
    nav: el('keys'), canvas: el('stage'), stage, theme: THEME, plots: opened,
    // A tap on a plant opens its panel (`plantpanel.js`), the same on every
    // area page, and a postcard to one of this area's plants lands here.
    plants: plantPanel({ theme: THEME, engine }),
    show: async (plot) => {
      await growOrchardFromService(engine, stage, grove, plot, growing);
      note.hidden = true;
    },
    turned: () => sky?.draw(),
  });
}

place().catch((trouble) => {
  console.warn('no orchard:', trouble);
  say('orchardAway');
});
