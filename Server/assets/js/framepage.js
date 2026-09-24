// The Cold Frame, on the page.
//
// **It draws what the plot service holds and nothing else.** The module that
// puts a plot on a canvas, `frame.js`, can also invent one — five hundred of
// this area's own plants, placed by the same rule — which belongs to the
// workbench at `/dev/frame` and not here, for the reason `walkpage.js` gives: a
// page that can be asked by its own query string to show plants nobody grew is
// a page that can be linked to as if those plants were real.
//
// **One plot at a time**, as every area but the walk is: four frames are a
// square you look into, and two of them side by side are eight frames in a
// yard with no reason to be one plot rather than another.
//
// **No list under the paragraph.** The Seedbed writes its drills out because a
// drill's kind cannot be drawn; here what claims a frame is a colour, and the
// first buds of the young plants in it already show it. What does sit under it
// is the block every area has, saying what the plants here mean — see
// `meanings.js`.
import { loadModule } from './plant.js';
import { makePlotStage } from './longwalk.js';
import { growFrameFromService, makeFrameGround, makeFrameLids, plan } from './frame.js';
import { makeSky } from './sky.js';
import { dressed, whenSettled } from './plain.js';
import { openWays } from './gates.js';
import { openMovePad } from './movepad.js';
import { plantPanel } from './plantpanel.js';
import { showGathers } from './meanings.js';

const el = (id) => document.getElementById(id);
const note = el('note');

// Where this page stands on the map: the bar, the link back to the garden and
// the minimap at the foot of the page all read this one word. Drawn whether or
// not the plot service answers, because a page that cannot reach its plants is
// exactly the page a reader needs a way out of.
const THEME = 'waiting';
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
  // Where the four frames stand and how high their walls are come from the
  // module, so the page cannot disagree with the rule about where a frame is.
  // **One plot, framed as though there were a little more than one**, the
  // Quiet Garden's margin.
  const frames = plan(engine);
  // The frames' lights, which a tap on their glass opens (`frame.js`, §The
  // lights, which open). Kept here, because the stage builds the ground again
  // at every turn and a frame propped open stays open through one.
  const lids = makeFrameLids(frames);
  const stage = makePlotStage(el('stage'), 1.25, engine, makeFrameGround(frames, lids));
  lids.attach(stage);

  let sky = null;
  makeSky(el('sky'), {
    quarterTurns: () => stage.turn(),
    keepClear: () => [...document.querySelectorAll('.page .masthead')]
      .map((node) => node.getBoundingClientRect())
      .filter((box) => box.width > 0 && box.height > 0),
  }).then((made) => { sky = made; }).catch((trouble) => {
    console.warn('no sky:', trouble);
  });

  const { plots: opened } = await (await fetch('/api/frame')).json();
  if (!opened) {
    await say('walkEmpty');
    return;
  }

  // The pad: moving about this plot and on to the next, closer and further,
  // and turning. `movepad.js`, the same on every area page.
  const growing = () => say('walkGrowing');
  await openMovePad({
    nav: el('keys'), canvas: el('stage'), stage, plots: opened,
    // A tap on a plant opens its panel (`plantpanel.js`), the same on every
    // area page, and a postcard to one of this area's plants lands here.
    // Here the lights are asked about a tap first, and a plant's frame is
    // opened before its panel.
    plants: plantPanel({ theme: THEME, engine, cover: lids }),
    show: async (plot) => {
      // Another plot's frames are shut: what was opened was opened here.
      lids.shut();
      await growFrameFromService(engine, stage, plot, growing);
      note.hidden = true;
    },
    turned: () => sky?.draw(),
  });
}

place().catch((trouble) => {
  console.warn('no cold frame:', trouble);
  say('frameAway');
});
