// The Seedbed, on the page.
//
// **It draws what the plot service holds and nothing else.** The module that
// puts a plot on a canvas, `seedbed.js`, can also invent one — five hundred
// arrivals sown by the same rule, which is how the template was argued about
// before anybody had sown anything in it. That belongs to the workbench at
// `/dev/seedbed` and not here, for the reason `walkpage.js` gives: a page that
// can be asked by its own query string to show plants nobody grew is a page that
// can be linked to as if those plants were real.
//
// **One plot at a time**, as the Quiet Garden's, the Crossing's, the Orchard's
// and the Knot Garden's pages are. A walk is a length you look down, so `/walk`
// shows three end to end; a bed is a rectangle you read across, and two of them
// end to end read as one bed with a seam in it.
//
// **This is the one area page with a list of its own under the paragraph.**
// Every area has the block saying what its plants mean (`meanings.js`); past
// that, the others say what the area is and let the drawing say the rest, which works
// because the drawing is the whole of what the rule did. Here it is not: a
// drill's kind is the fact the area is built on, and `Organic.rowLabel` cannot
// carry it — nothing is written on a label, because at this scale a word is four
// pixels tall and would fight the plants. So the labels stand in the bed and the
// words are on the page, where they can be read and translated.
import { loadModule } from './plant.js';
import { makePlotStage } from './longwalk.js';
import { describeSeedbed, drillAt, growSeedbedFromService, makeSeedbedGround, plan, readDrills }
  from './seedbed.js';
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
const THEME = 'beginnings';
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

/// The six drills, written out: what claimed each one, and how far along it is
/// sown.
///
/// **A count drawn rather than written, the way the map draws how full an area
/// is.** Eight marks, one a place, filled from the end the drill fills from — so
/// a reader sees *three of eight* without the page owning a string that says
/// three of eight in forty-three languages. The number itself is on the row's
/// own label for anybody listening rather than looking, which is what
/// `/g`'s cells do with theirs.
///
/// **The kind is set in the serif**, which this site reserves for the binomial a
/// plant is given. An epithet is half a binomial and is the half that was chosen
/// to say what the plant is like, so it belongs in that voice and in no other —
/// and it is a proper noun, so it is the same word in every language the page is
/// read in.
function writeDrills(list, drills, places) {
  list.replaceChildren();
  for (const drill of drills) {
    const row = document.createElement('li');
    row.className = 'drill';

    const kind = document.createElement('span');
    kind.className = 'drill__kind';
    // An unclaimed drill has no name and is not given one. Nothing is sown in
    // it, so there is nothing for it to be named after — which is the honest
    // half of what a part-sown bed looks like.
    kind.textContent = drill.kind ?? '';

    const marks = document.createElement('span');
    marks.className = 'drill__places';
    marks.setAttribute('role', 'img');
    marks.setAttribute('aria-label', `${drill.kind ?? ''} ${drill.sown}/${places}`.trim());
    for (let place = 0; place < places; place++) {
      const mark = document.createElement('span');
      mark.className = place < drill.sown ? 'drill__place drill__place--sown' : 'drill__place';
      marks.append(mark);
    }

    row.append(kind, marks);
    list.append(row);
  }
  list.hidden = false;
}

async function place() {
  const engine = await loadModule(document.documentElement.dataset.module || '/plant.wasm');
  // The bed's own numbers — where the six drills run, where the eight places sit
  // along one, where a label stands — come from the module rather than being
  // written down again here, so the page cannot disagree with the rule about
  // where a drill is.
  // **One plot, framed as though there were a little more than one**, the Quiet
  // Garden's margin: a single square framed tight touches the ends of its
  // drills, and a plot with air round it reads as a place you are looking into
  // rather than a texture filling the screen.
  const bed = plan(engine);
  const stage = makePlotStage(el('stage'), 1.25, engine, makeSeedbedGround(bed));
  // And the areas beside this one, as slabs out in the sky past the plot:
  // the same one word again, and `beside.js` reads the map from it.
  stage.beside(THEME);

  // **The wire says where a plant stands, not what it is.** `SeedbedStore` keeps
  // the epithet in a column — the rule is built on it — and `planting` sends the
  // five fields every area sends: a seed, its parents, its meeting and a spot.
  // The drill is recovered from the spot, which is exact enough to be certain of
  // (0.035 m of nudge across a 0.74 m gap), but the epithet cannot be recovered
  // from anything, because reading it means growing the plant and asking its
  // name.
  //
  // So the kinds this page can name are the ones the module itself holds: asked
  // before anything has been invented, `pg_seedbed_describe` is the Seedbed as
  // it opened, and the ambassador standing at the head of the first drill is the
  // same plant, by the same seed, that the service sends. A drill claimed by an
  // arrival is counted and left unnamed until the wire carries what the store
  // already has.
  const kinds = new Map(describeSeedbed(engine, 0).map((p) => [p.seed, p.traits.kind]));

  let sky = null;
  makeSky(el('sky'), {
    quarterTurns: () => stage.turn(),
    // Only the bar is in the sky now — the heading, the paragraph, the drills
    // and the keys are below the drawing, where the mask has already taken the
    // stars off.
    keepClear: () => [...document.querySelectorAll('.page .masthead')]
      .map((node) => node.getBoundingClientRect())
      .filter((box) => box.width > 0 && box.height > 0),
  }).then((made) => { sky = made; }).catch((trouble) => {
    console.warn('no sky:', trouble);
  });

  const { plots: opened } = await (await fetch('/api/seedbed')).json();
  if (!opened) {
    await say('walkEmpty');
    return;
  }

  // The pad: moving about this bed and on to the next, closer and further, and
  // turning. `movepad.js`, the same on every area page.
  const growing = () => say('walkGrowing');
  const show = async (plot) => {
    const plantings = await growSeedbedFromService(engine, stage, plot, growing);
    writeDrills(el('drills'), readDrills(bed, plantings.map((p) => ({
      drill: drillAt(bed, p.spot[0]),
      kind: kinds.get(p.seed),
      span: p.span,
    }))), bed.places);
    note.hidden = true;
  };

  await openMovePad({
    nav: el('keys'), canvas: el('stage'), stage, theme: THEME, plots: opened, show,
    // A tap on a plant opens its panel (`plantpanel.js`), the same on every
    // area page, and a postcard to one of this area's plants lands here.
    plants: plantPanel({ theme: THEME, engine }),
    turned: () => sky?.draw(),
  });
}

place().catch((trouble) => {
  console.warn('no seedbed:', trouble);
  say('seedbedAway');
});
