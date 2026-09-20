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
import { makeWalkStage, growFromService } from './longwalk.js';
import { makeSky } from './sky.js';
import { dressed } from './plain.js';

// Three plots at a time: the one in front of the reader and its neighbours
// either side, which is as much as fits on a phone held upright and is the
// span the walk was drawn for.
const SPAN = 3;

const el = (id) => document.getElementById(id);
const note = el('note');

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
  const engine = await loadModule('/plant.wasm');
  const stage = makeWalkStage(el('stage'), SPAN, engine);

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
    keepClear: () => [...document.querySelectorAll('.page .heading, .page .walk-about, .page .walk-note, .page .walk-keys, .page .masthead, .page .foot')]
      .map((node) => node.getBoundingClientRect())
      .filter((box) => box.width > 0 && box.height > 0),
  }).then((made) => { sky = made; }).catch((trouble) => {
    // No sky is a worse walk, not a broken one — but a sky that silently is
    // not there is an hour of somebody's life, so it says why.
    console.warn('no sky:', trouble);
  });

  const turn = (quarters) => { stage.turnBy(quarters); sky?.draw(); };
  el('left').addEventListener('click', () => turn(-1));
  el('right').addEventListener('click', () => turn(1));

  const { plots: opened } = await (await fetch('/api/walk')).json();
  if (!opened) {
    await say('walkEmpty');
    return;
  }

  let from = 0;
  const growing = () => say('walkGrowing');
  const show = async () => {
    el('back').disabled = from === 0;
    el('on').disabled = from + SPAN >= opened;
    await growFromService(engine, stage, from,
                          Math.max(0, Math.min(SPAN, opened - from)), growing);
    note.hidden = true;
  };

  el('back').addEventListener('click', () => { from = Math.max(0, from - SPAN); show(); });
  el('on').addEventListener('click', () => { from = Math.min(opened - 1, from + SPAN); show(); });
  el('keys').hidden = false;
  await show();
}

walk().catch((trouble) => {
  // The walk is the page. If it cannot be drawn, the page says so in words
  // rather than leaving a reader looking at an empty night and wondering
  // whether that is the garden.
  console.warn('no walk:', trouble);
  say('walkAway');
});
