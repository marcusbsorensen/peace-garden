// The Coppice, on the page.
//
// **It draws what the plot service holds and nothing else.** The module that
// puts a plot on a canvas, `coppice.js`, can also invent one — five hundred of
// this area's own plants, placed by the same rule, in any year — which belongs
// to the workbench at `/dev/coppice` and not here, for the reason `walkpage.js`
// gives: a page that can be asked by its own query string to show plants nobody
// grew is a page that can be linked to as if those plants were real. The same
// goes for the year: this page shows the one the service says it is.
//
// **One plot at a time**, as every area but the walk is: three coupes are the
// whole of the rotation, and a plot is where all three stages stand at once.
//
// **No words for the stages.** Which band is cut this winter is what the page
// draws — the pale faces, the croziers, the open floor — and naming it would
// mean saying *the far band* or *the near one*, which a quarter turn makes
// wrong. The paragraph a screen reader hears says the wood is cut in turn. What
// does sit under the heading is the block every area has, saying what the
// plants here mean — see `meanings.js`.
import { loadModule } from './plant.js';
import { makePlotStage } from './longwalk.js';
import { growCoppiceFromService, makeCoppiceGround, plan } from './coppice.js';
import { makeSky } from './sky.js';
import { dressed, whenSettled } from './plain.js';
import { openWays } from './gates.js';
import { showGathers } from './meanings.js';

const el = (id) => document.getElementById(id);
const note = el('note');

// Where this page stands on the map: the bar, the link back to the garden and
// the minimap at the foot of the page all read this one word. Drawn whether or
// not the plot service answers, because a page that cannot reach its plants is
// exactly the page a reader needs a way out of.
const THEME = 'renewal';
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
  // Where the coupes, the rides and the stools stand come from the module, so
  // the page cannot disagree with the rule about where a fern is. **One plot,
  // framed as though there were a little more than one**, the Quiet Garden's
  // margin.
  const wood = plan(engine);
  const stage = makePlotStage(el('stage'), 1.25, engine, makeCoppiceGround(wood));

  let sky = null;
  makeSky(el('sky'), {
    quarterTurns: () => stage.turn(),
    keepClear: () => [...document.querySelectorAll('.page .masthead')]
      .map((node) => node.getBoundingClientRect())
      .filter((box) => box.width > 0 && box.height > 0),
  }).then((made) => { sky = made; }).catch((trouble) => {
    console.warn('no sky:', trouble);
  });

  const turn = (quarters) => { stage.turnBy(quarters); sky?.draw(); };
  el('left').addEventListener('click', () => turn(-1));
  el('right').addEventListener('click', () => turn(1));

  const { plots: opened } = await (await fetch('/api/coppice')).json();
  if (!opened) {
    await say('walkEmpty');
    return;
  }

  let plot = 0;
  const growing = () => say('walkGrowing');
  const show = async () => {
    el('back').disabled = plot === 0;
    el('on').disabled = plot + 1 >= opened;
    await growCoppiceFromService(engine, stage, wood, plot, growing);
    note.hidden = true;
  };

  el('back').addEventListener('click', () => { plot = Math.max(0, plot - 1); show(); });
  el('on').addEventListener('click', () => { plot = Math.min(opened - 1, plot + 1); show(); });
  el('keys').hidden = false;
  await show();
}

place().catch((trouble) => {
  console.warn('no coppice:', trouble);
  say('coppiceAway');
});
