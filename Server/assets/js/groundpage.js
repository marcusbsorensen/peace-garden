// The Home Ground, on the page.
//
// **It draws what the plot service holds and nothing else.** The module that
// puts a plot on a canvas, `ground.js`, can also invent one — five hundred of
// this area's own plants, placed by the same rule — which belongs to the
// workbench at `/dev/ground` and not here, for the reason `walkpage.js` gives:
// a page that can be asked by its own query string to show plants nobody grew
// is a page that can be linked to as if those plants were real.
//
// **One plot at a time**, as every area but the walk is: a kitchen garden is a
// rectangle you stand at the end of, and two of them end to end would read as
// one garden with a seam.
//
// **No words for the crops.** Which bed holds spires, umbels or rosettes is
// what the page draws, and three shapes nobody takes for each other say it
// before any label could. What does sit under the heading is the block every
// area has, saying what the plants here mean — see `meanings.js`.
import { loadModule } from './plant.js';
import { makePlotStage } from './longwalk.js';
import { growGroundFromService, makeGroundGround, plan } from './ground.js';
import { makeSky } from './sky.js';
import { dressed, whenSettled } from './plain.js';
import { openWays } from './gates.js';
import { openMovePad } from './movepad.js';
import { plantPanel } from './plantpanel.js';
import { showGathers } from './meanings.js';

const el = (id) => document.getElementById(id);
const note = el('note');

// Where this page stands on the map: the bar, the link back to the garden, the
// minimap at the foot of the page, the pad's way off the edge of the area and
// the slabs of the areas beside this one, out in the sky past the plot, all
// read this one word. Drawn whether or not the plot service answers,
// because a page that cannot reach its plants is exactly the page a reader
// needs a way out of.
const THEME = 'ground';
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
  // Where the beds stand and how each crop is spaced come from the module, so
  // the page cannot disagree with the rule about where a row runs. **One plot,
  // framed as though there were a little more than one**, the Quiet Garden's
  // margin.
  const ground = plan(engine);
  const stage = makePlotStage(el('stage'), 1.25, engine, makeGroundGround(ground));
  // And the areas beside this one, as slabs out in the sky past the plot:
  // the same one word again, and `beside.js` reads the map from it.
  stage.beside(THEME);

  let sky = null;
  makeSky(el('sky'), {
    quarterTurns: () => stage.turn(),
    keepClear: () => [...document.querySelectorAll('.page .masthead')]
      .map((node) => node.getBoundingClientRect())
      .filter((box) => box.width > 0 && box.height > 0),
  }).then((made) => { sky = made; }).catch((trouble) => {
    console.warn('no sky:', trouble);
  });

  const { plots: opened } = await (await fetch('/api/ground')).json();
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
      await growGroundFromService(engine, stage, ground, plot, growing);
      note.hidden = true;
    },
    turned: () => sky?.draw(),
  });
}

place().catch((trouble) => {
  console.warn('no home ground:', trouble);
  say('groundAway');
});
