// The Quiet Garden, on the page.
//
// **It draws what the plot service holds and nothing else.** The module that
// puts a room on a canvas, `quietgarden.js`, can also invent one — five hundred
// arrivals planted by the same rule, which is how the template was argued about
// before anybody had planted anything in it. That belongs to the workbench at
// `/dev/quiet` and not here, for the reason `walkpage.js` gives: a page that can
// be asked by its own query string to show plants nobody grew is a page that
// can be linked to as if those plants were real.
//
// **One room at a time.** The walk shows three plots end to end because a walk
// is a length you look down. An enclosure is not: you are in one or you are in
// the next, and three hedged rooms side by side would be three gardens rather
// than one seen properly.
import { loadModule } from './plant.js';
import { makePlotStage } from './longwalk.js';
import { growRoomFromService, makeRoomGround, plan } from './quietgarden.js';
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

async function room() {
  const engine = await loadModule(document.documentElement.dataset.module || '/plant.wasm');
  // The room's own numbers — where the hedge stands, where the bench does —
  // come from the module rather than being written down again here, so the
  // page cannot disagree with the rule about the shape of the place.
  // **One plot, framed as though there were a little more than one.** The walk
  // gets three plots end to end, which is a wide, low shape that sits under the
  // page's own words. A single square room framed tight fills the middle of the
  // screen and the prose lands on the lawn. A quarter more than a plot's side
  // is the margin that leaves the hedge clear of the heading.
  const stage = makePlotStage(el('stage'), 1.25, engine, makeRoomGround(plan(engine)));

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

  const { plots: opened } = await (await fetch('/api/quiet')).json();
  if (!opened) {
    await say('walkEmpty');
    return;
  }

  let plot = 0;
  const growing = () => say('walkGrowing');
  const show = async () => {
    el('back').disabled = plot === 0;
    el('on').disabled = plot + 1 >= opened;
    await growRoomFromService(engine, stage, plot, growing);
    note.hidden = true;
  };

  el('back').addEventListener('click', () => { plot = Math.max(0, plot - 1); show(); });
  el('on').addEventListener('click', () => { plot = Math.min(opened - 1, plot + 1); show(); });
  el('keys').hidden = false;
  await show();
}

room().catch((trouble) => {
  console.warn('no room:', trouble);
  say('quietAway');
});
