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
const THEME = 'peace';
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

async function room() {
  const engine = await loadModule(document.documentElement.dataset.module || '/plant.wasm');
  // The room's own numbers — where the hedge stands, where the bench does —
  // come from the module rather than being written down again here, so the
  // page cannot disagree with the rule about the shape of the place.
  // **One plot, framed as though there were a little more than one.** The walk
  // gets three plots end to end, which is a wide, low shape that sits under the
  // page's own words. A single square room framed tight touches the sides of
  // its band; a quarter more than a plot's side is the margin that leaves air
  // round the hedge, so the room reads as a place rather than as a texture.
  // The room's plan is kept, so each plot can say which way round it is laid
  // (`growRoomFromService`) and the ground be laid that way.
  const room = plan(engine);
  const stage = makePlotStage(el('stage'), 1.25, engine, makeRoomGround(room));
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

  const { plots: opened } = await (await fetch('/api/quiet')).json();
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
      await growRoomFromService(engine, stage, plot, growing, room);
      note.hidden = true;
    },
    turned: () => sky?.draw(),
  });
}

room().catch((trouble) => {
  console.warn('no room:', trouble);
  say('quietAway');
});
