// The Long Walk, on the page.
//
// **It draws what the plot service holds and nothing else.** The module that
// puts a walk on a canvas, `longwalk.js`, can also invent one — a few hundred
// arrivals planted by the same rule, which is how the geometry was argued
// about before anybody had planted anything. That belongs to the workbench at
// `/dev/walk` and not here: a page that can be asked by its own query string
// to show plants nobody grew is a page that can be linked to as if those
// plants were real.
//
// **Nothing here counts anything out loud.** An early version said which plots
// were on screen and how full each one was, which is the right thing for a
// workbench and turns a walk into a readout. What is left is one line, and
// only while there is something to wait for.
import { loadModule } from './plant.js';
import { makePlotStage, growFromService } from './longwalk.js';
import { makeSky } from './sky.js';
import { dressed, whenSettled } from './plain.js';
import { openWays } from './gates.js';
import { openMovePad } from './movepad.js';
import { showGathers } from './meanings.js';

// Three plots at a time: the one in front of the reader and its neighbours
// either side, which is as much as fits on a phone held upright and is the
// span the walk was drawn for.
const SPAN = 3;

const el = (id) => document.getElementById(id);
const note = el('note');

// Where this page stands on the map. The bar says it, the link back to the
// garden carries it, and `gates.js` marks it on the map at the foot of the
// page — all three from this one word.
//
// **Drawn whether or not the plot service answers.** A page that cannot reach
// its plants is exactly the page a reader needs a way out of.
const THEME = 'travel';
whenSettled((strings) => openWays(THEME, strings));
// And what the plants here mean, under the paragraph. The same one word says
// which row of `meanings.js` to read, so the block cannot name another area.
whenSettled((strings) => showGathers(THEME, strings));

// The words arrive with `plain.js`, which settles a language over the network,
// so this page can be running before there is anything to say it in.
// Everything said here goes through this, and it waits.
const say = async (key) => {
  const strings = await dressed;
  note.textContent = strings.t(key);
  strings.dress(note, key);
  note.hidden = false;
};

async function walk() {
  // Eight megabytes of Swift, fetched once. Everything that grows a plant on
  // this page uses this one instance: `loadModule` compiles and instantiates,
  // and calling it a second time would fetch and compile the whole thing
  // again.
  const engine = await loadModule(document.documentElement.dataset.module || '/plant.wasm');
  const stage = makePlotStage(el("stage"), SPAN, engine);

  // The same sky the app draws, and it turns with the walk: turning is the
  // reader going round to another side, so what they can see of the sky goes
  // round with them — a quarter of it a quarter turn, back where it started
  // after four.
  //
  // It keeps off the page's own words by dimming rather than by being cut out
  // of a rectangle, the way the sun and the moon do in the app.
  let sky = null;
  makeSky(el('sky'), {
    quarterTurns: () => stage.turn(),
    // Only the bar is in the sky now — the heading, the paragraph and the keys
    // are below the drawing, where the mask has already taken the stars off.
    keepClear: () => [...document.querySelectorAll('.page .masthead')]
      .map((node) => node.getBoundingClientRect())
      .filter((box) => box.width > 0 && box.height > 0),
  }).then((made) => { sky = made; }).catch((trouble) => {
    // No sky is a worse walk, not a broken one — but a sky that silently is
    // not there is an hour of somebody's life, so it says why.
    console.warn('no sky:', trouble);
  });

  const { plots: opened } = await (await fetch('/api/walk')).json();
  if (!opened) {
    await say('walkEmpty');
    return;
  }

  // The pad, the same on every area page (`movepad.js`). A crossing here moves
  // the three plots on screen on by three, which is what paging always did:
  // the next three are the ones beyond the edge of these.
  const growing = () => say('walkGrowing');
  await openMovePad({
    nav: el('keys'), canvas: el('stage'), stage, plots: opened, step: SPAN,
    show: async (from) => {
      await growFromService(engine, stage, from,
                            Math.max(0, Math.min(SPAN, opened - from)), growing);
      note.hidden = true;
    },
    turned: () => sky?.draw(),
  });
}

walk().catch((trouble) => {
  // The walk is the page. If it cannot be drawn, the page says so in words
  // rather than leaving a reader looking at an empty night and wondering
  // whether that is the garden.
  console.warn('no walk:', trouble);
  say('walkAway');
});
