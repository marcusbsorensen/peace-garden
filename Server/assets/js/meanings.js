// What the plants in each area mean, and how a plant's name says so.
//
// **Every area gathers the plants of one theme, and until this file the site
// said so nowhere.** An area page described its layout — a hedge round a lawn,
// four frames on gravel — and left the reader to guess why *these* plants were
// standing in it. The answer is in the name: the head of the genus carries the
// theme, the ending of the genus carries which of the theme's three parts the
// plant's words are drawn from, and the epithet says the one way the plant most
// departs from its genus. docs/NAMES-AND-THEMES.md is the record of the first
// two and `Epithet.swift` of the third.
//
// **One table, read by two pages.** The block under each area's paragraph and
// the lookup at `/meanings` are both drawn from `THEMES` below, so the short
// account on an area page and the long one in the table cannot come to say
// different things. It is the same argument `gates.js` makes for the map.
//
// **What is copied here, and what is only checked.** The heads, their roots and
// the three parts are mirrored from the app — `Areas.genusHeads`,
// `docs/NAMES-AND-THEMES.md` and `Quotes.Subtheme` — because the roots and the
// labels exist nowhere the website can read them. Which head means which theme
// and which ending picks which third already exist on this site, in
// `passages.js`, so `selfTest` holds this table to that one rather than
// trusting two copies to agree.
//
// **What is in the catalogue and what is not.** The one-line meaning of each
// theme is new prose, so it is a key in `strings.js` like every other sentence
// the site says, English-only for now and falling back in silence. The heads
// and roots are proper nouns and travel as they are. The subtheme labels, the
// instances under them and the epithet glosses are English data here rather
// than sixty more commissions: they are the project's own record of what it
// attributed to what, quoted, and a table a reader looks things up in. If they
// are ever commissioned, moving them into the catalogue is mechanical.

import { AREA_KEYS } from "./strings.js";
import { BUILT } from "./gates.js";
import { subthemeOf, syllables, themeOf } from "./passages.js";

/// The genus endings, banded as `Quotes.subtheme(of:in:)` bands them: the first
/// three pick a theme's first part, the next three its second, the last four
/// its third. **Ten endings over three parts, 3/3/4**, which suits the bank —
/// the last part is the words and sayings and is reliably the largest.
export const ENDINGS = Object.freeze([
  Object.freeze(["ia", "is", "a"]),
  Object.freeze(["ea", "ina", "ora"]),
  Object.freeze(["yne", "era", "ula", "ynth"]),
]);

const head = (syllable, from, root, gloss) => Object.freeze({ syllable, from, root, gloss });
const part = (key, label, instances) => Object.freeze({ key, label, instances });

/// The ten themes, in map order — the top row of the garden left to right, then
/// the bottom — which is the order `AREA_KEYS` names them in.
///
/// `heads` are the genus syllables that bring a plant to this area, each with
/// the root it was taken from as `docs/NAMES-AND-THEMES.md` §The map records
/// it: `from` is `Gk` or `L`, and is null where the record gives no language —
/// `Fen` is the English word, and `Ith` is Ithaca, a place. `Vin` is *vinculum*,
/// a bond, and **not** the vine; `PlantName.genusHeads` says why that matters.
///
/// `parts` are the theme's three subthemes, in the order the endings pick them,
/// with the instances the thirty passages were read into — the table in
/// docs/NAMES-AND-THEMES.md §The subthemes, word for word. `key` is the
/// `Quotes.Subtheme` case, and is what `selfTest` checks the order by.
///
/// `meaning` is the catalogue key for the theme's one line.
export const THEMES = Object.freeze([
  Object.freeze({
    theme: "waiting",
    meaning: "meaningWaiting",
    heads: [head("Nyx", "Gk", "Nyx", "night"), head("Umbr", "L", "umbra", "shade")],
    parts: [
      part("heldBack", "Held back", "dormancy, stratification, marcescence"),
      part("theLongCount", "The long count", "Masada dates, Beal's bottles, bamboo mast years"),
      part("standingAndWatching", "Standing and watching", "patiens, abide, the gardener's shadow"),
    ],
  }),
  Object.freeze({
    theme: "ground",
    meaning: "meaningGround",
    heads: [
      head("Cer", "L", "Ceres", "the grain"),
      head("Fen", null, "fen", "low wet ground"),
      head("Pell", "L", "pellis", "the earth's skin"),
    ],
    parts: [
      part("theSoilItself", "The soil itself", "rhizosphere, a teaspoon of earth, Darwin's worms"),
      part("aPlaceYouAreFrom", "A place you are from", "querencia, Heimat, petrichor"),
      part("aKeptPlace", "A kept place", "pairidaeza, colere, garden as enclosure"),
    ],
  }),
  Object.freeze({
    theme: "beginnings",
    meaning: "meaningBeginnings",
    heads: [
      head("Thal", "Gk", "thallos", "a young shoot"),
      head("Lir", "Gk", "leirion", "lily"),
      head("Ver", "L", "ver", "the spring"),
    ],
    parts: [
      part("theFirstAct", "The first act", "germination, imbibition, radicle, meristem"),
      part("smallToLarge", "Small to large", "the acorn, the coco de mer against orchid dust"),
      part("whatAStartSettles", "What a start settles", "the Bramley pip, prime and primrose"),
    ],
  }),
  Object.freeze({
    theme: "renewal",
    meaning: "meaningRenewal",
    // *Dew, and dew again*: the two roots are the one word in Greek and in
    // Latin, and the record says so rather than finding a second sense.
    heads: [head("Dros", "Gk", "drosos", "dew"), head("Ros", "L", "ros", "dew again")],
    parts: [
      part("cutAndComeAgain", "Cut and come again", "coppicing, epicormic buds, the Hiroshima ginkgos"),
      part("theTurningYear", "The turning year", "If Winter comes, spring as water"),
      part("madeWhole", "Made whole", "kintsugi, resurgam, anastasis, convalesce"),
    ],
  }),
  Object.freeze({
    theme: "travel",
    meaning: "meaningTravel",
    heads: [
      head("Zeph", "Gk", "Zephyros", "the west wind"),
      head("Ael", "Gk", "aellē", "a gust"),
      head("Hal", "Gk", "hals", "the salt sea"),
    ],
    parts: [
      part("howASeedGoes", "How a seed goes", "anemochory, sea beans, the dandelion's vortex"),
      part("theRoad", "The road", "ad ripam, peregrinus, travel and travail"),
      part("farOff", "Far off", "Fernweh, tramontane, serendipity"),
    ],
  }),
  Object.freeze({
    theme: "peace",
    meaning: "meaningPeace",
    // *Bellus* has four defensible roots; the one said of weather was taken
    // because *serenus*, a clear sky with no wind in it, is in the Peace bank.
    heads: [head("Ol", "L", "oliva", "the olive"), head("Bel", "L", "bellus", "a clear sky")],
    parts: [
      part("quietAsASound", "Quiet as a sound", "psithurism, snow, the anechoic chamber"),
      part("theWordsForStopping", "The words for stopping", "pax, serenus, quietus, sabbath"),
      part("atEase", "At ease", "hygge, sobremesa, shinrin-yoku"),
    ],
  }),
  Object.freeze({
    theme: "kinship",
    meaning: "meaningKinship",
    heads: [head("Vin", "L", "vinculum", "a bond"), head("Cyn", "Gk", "kyōn", "the dog that waits at the door")],
    parts: [
      part("grownTogether", "Grown together", "inosculation, grafting, lichen, mycorrhiza"),
      part("theWordsForIt", "The words for it", "sibb, God-sib, companion, kind and kin"),
      part("twoPeople", "Two people", "Donne, Montaigne, Hávamál, ubuntu"),
    ],
  }),
  Object.freeze({
    theme: "pattern",
    meaning: "meaningPattern",
    // The family table in docs/TAXONOMY.md still has these two on each other's
    // flower; `PlantName.roots` is right, and the theme is the same either way.
    heads: [head("Cal", "Gk", "kalos", "the shapely"), head("Quin", "L", "quinque", "five")],
    parts: [
      part("counted", "Counted", "the golden angle, Fibonacci spirals, quincunx"),
      part("fittedTogether", "Fitted together", "tessellation, decussate leaves, Turing patterns"),
      part("orderNamed", "Order named", "cosmos, rhythm, ordo, the anthology"),
    ],
  }),
  Object.freeze({
    theme: "light",
    meaning: "meaningLight",
    heads: [
      head("El", "Gk", "hēlios", "the sun"),
      head("Aur", "L", "aurora", "dawn"),
      head("Sel", "Gk", "Selēnē", "the moon"),
    ],
    parts: [
      part("theEdgesOfTheDay", "The edges of the day", "gloaming, alpenglow, apricity, gökotta"),
      part("readingTheLight", "Reading the light", "photoperiodism, heliotropism, the day's eye"),
      part("lightItself", "Light itself", "lux, solstice, phosphorus, the eight minutes"),
    ],
  }),
  Object.freeze({
    theme: "meeting",
    meaning: "meaningMeeting",
    // `Ith` could as easily be Gk *ithys*, straight. Ithaca was chosen because
    // Meeting needed a second head and an arrival is what a meeting is.
    heads: [head("Mel", "Gk", "meli", "honey"), head("Ith", null, "Ithaca", "the place arrived at")],
    parts: [
      part("theMoment", "The moment", "kairos, clinamen, ichigo ichie"),
      part("twoThatNeedEachOther", "Two that need each other", "fig and wasp, yucca moth, Ophrys"),
      part("theMannersOfIt", "The manners of it", "xenia, limen, interfulgence"),
    ],
  }),
]);

/// The second word of a name, and what it says about the plant.
///
/// From `Epithet.describing`, which gives a plant the one true thing about it
/// that fewest of its relatives could say. **Grouped by what they describe and
/// paired where a trait has two ends**, because a reader looking up *nana* is
/// helped by finding *elata* beside it. Leaves and stem are measured against
/// the plant's own genus; colour is measured against every plant, because a
/// genus constrains no colour and *aurea* means golden however golden its
/// neighbours are.
///
/// Written in the feminine, which nine genus endings in ten take. After `-ynth`
/// the `-a` becomes `-us` — *paniculatus* — and *rubra* becomes *ruber*; the
/// `-is` words do not change.
export const EPITHETS = Object.freeze([
  ["nana · elata", "a short stem · a tall one"],
  ["gracilis · crassicaulis", "a slender stem · a thick one"],
  ["declinata", "a stem that leans"],
  ["contorta", "a twisted stem"],
  ["flexuosa", "a stem that sways"],
  ["brevifolia · longifolia", "short leaves · long ones"],
  ["angustifolia · latifolia", "narrow leaves · broad ones"],
  ["integrifolia · serratifolia", "smooth-edged leaves · toothed ones"],
  ["erecta · pendula", "leaves held up · leaves that droop"],
  ["patentifolia", "leaves that spread wide"],
  ["foliosa", "many leaves"],
  ["variegata", "variegated leaves"],
  ["paniculata", "a wide spray of flowers"],
  ["pallida · obscura · vivida", "pale flowers · dark · vivid"],
  ["aurea · caerulea · rubra", "golden flowers · blue · red"],
  ["marginata", "petals edged in another colour"],
  ["marmorata", "marbled petals"],
  ["venosa", "veined petals"],
  ["noctiflora", "flowers that open at night"],
  ["vulgaris", "nothing remarkable: an ordinary member of its genus"],
].map(([words, says]) => Object.freeze({ words, says })));

/// The name the table page takes apart as its example.
///
/// *Nyx* is night and the Cold Frame; *-ora* is the long count; *noctiflora*
/// opens at night. Chosen because every syllable of it says something and
/// they all say the same thing, which is the design working. `selfTest` reads
/// it back through `passages.js`, so it cannot come to be filed wrongly.
export const EXAMPLE = Object.freeze({ genus: "Nyxora", epithet: "noctiflora" });

/// The row for one theme.
export function themeRow(theme) {
  return THEMES.find((row) => row.theme === theme) || null;
}

// A run of English data inside a page that may be in any language. Marked as
// English for the same reason `strings.dress` marks a borrowed key: an unmarked
// English run inside a right-to-left document is reordered at its punctuation.
function english(node) {
  node.lang = "en";
  node.dir = "ltr";
  return node;
}

function make(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

/// One head: the syllable in the serif the site keeps for plant names, and its
/// root after it. `withLanguage` adds the *Gk* or *L* the record gives, which
/// the table has room for and an area page does not.
function headNode(entry, withLanguage) {
  const unit = make("span", "gathers__name");
  unit.append(make("i", "gathers__head", entry.syllable));
  const root = english(make("span", "gathers__root"));
  const from = withLanguage && entry.from ? `${entry.from} ` : "";
  root.textContent = ` ${from}${entry.root}, ${entry.gloss}`;
  unit.append(root);
  return unit;
}

/// The block under an area's paragraph: what this theme is, the syllables that
/// bring a plant here, the three parts, and the way to the whole table.
///
/// **Four short lines, and the count was the brief.** An area page is a drawing
/// with words under it, and every line added here pushes the pad and the map
/// further from the plot. The instances under each part, the roots' languages
/// and the endings are all one tap away at `/meanings`.
///
/// Called from `whenSettled`, so it is drawn afresh when the chooser changes;
/// it clears what it drew rather than adding to it, as `openWays` does.
export function showGathers(theme, strings) {
  const block = document.getElementById("gathers");
  const row = themeRow(theme);
  if (!block || !row) return;
  block.replaceChildren();

  const meaning = make("p", "body gathers__meaning", strings.t(row.meaning));
  strings.dress(meaning, row.meaning);

  // **No names line here.** Which name-starts bring a plant to this area, and
  // their roots, are on `/meanings`, a link away: on the area page they cost
  // the pad and the map their place above the fold on a laptop, and Marcus
  // chose the fold (23 September).
  const parts = english(make("p", "label gathers__parts"));
  row.parts.forEach((entry, index) => {
    if (index) parts.append(" ");
    parts.append(make("span", "gathers__part", entry.label));
  });

  const more = make("p", "gathers__more");
  const link = make("a", "gathers__link", strings.t("meaningsTitle"));
  link.href = `/meanings#${theme}`;
  strings.dress(link, "meaningsTitle");
  more.append(link);

  block.append(meaning, parts, more);
  block.hidden = false;
}

/// Everything `/meanings` draws: the worked example, the ten themes and the
/// second words.
export function showMeanings(strings) {
  showExample(strings);
  showThemes(strings);
  showEpithets(strings);
}

function showExample(strings) {
  const figure = document.getElementById("example");
  if (!figure) return;
  figure.replaceChildren();

  const { head: syllable, tail } = syllables(EXAMPLE.genus);
  const theme = themeOf(syllable);
  const partKey = subthemeOf(tail, theme);
  const row = themeRow(theme);
  const middle = EXAMPLE.genus.slice(syllable.length, EXAMPLE.genus.length - tail.length);

  // The name, with the two syllables that carry meaning at full strength and
  // anything between them faint, split at the head by a dot as a dictionary
  // splits a word — *Nyxora* on its own does not show where *Nyx* stops.
  const name = make("p", "plant-name meanings-example__name");
  // A binomial runs left to right in every language; under Arabic or Hebrew
  // its pieces would otherwise be laid out in reverse order.
  name.dir = "ltr";
  name.append(
    make("span", "meanings-example__lit", syllable),
    make("span", "meanings-example__between", `·${middle}`),
    make("span", "meanings-example__lit", tail),
    document.createTextNode(" "),
    make("span", "meanings-example__lit", EXAMPLE.epithet)
  );

  // What each piece says, in a row: the area it names, the part, the trait.
  const keyed = make("dl", "meanings-example__key");
  const say = (term, description, isEnglish) => {
    const pair = make("div", "meanings-example__pair");
    pair.append(make("dt", "meanings-example__term", term));
    const dd = make("dd", "meanings-example__says", description);
    if (isEnglish) english(dd);
    pair.append(dd);
    keyed.append(pair);
    return dd;
  };
  const area = say(syllable, strings.t(AREA_KEYS[theme]), false);
  strings.dress(area, AREA_KEYS[theme]);
  say(`-${tail}`, row.parts.find((entry) => entry.key === partKey).label, true);
  say(EXAMPLE.epithet, EPITHETS.find((entry) => entry.words === EXAMPLE.epithet).says, true);

  figure.append(name, keyed);
  figure.hidden = false;
}

function showThemes(strings) {
  const body = document.getElementById("themes-body");
  if (!body) return;
  body.replaceChildren();

  // Headings: three from the catalogue, and the three parts headed by their
  // endings, which are pieces of a name and need no language at all.
  const heads = document.getElementById("themes-head");
  if (heads) {
    heads.replaceChildren();
    const tr = make("tr");
    for (const key of ["meaningsArea", "meaningsMeaning", "meaningsNames"]) {
      const th = make("th", "label", strings.t(key));
      th.scope = "col";
      strings.dress(th, key);
      tr.append(th);
    }
    for (const band of ENDINGS) {
      const th = make("th", "meanings-endings", band.map((tail) => `-${tail}`).join(" "));
      th.scope = "col";
      tr.append(th);
    }
    heads.append(tr);
  }

  for (const row of THEMES) {
    const tr = make("tr");
    tr.id = row.theme;
    // The row a reader came from an area page to find. Marked by a class
    // rather than left to `:target`, because the row did not exist when the
    // browser read the fragment.
    if (location.hash === `#${row.theme}`) tr.classList.add("meanings-row--here");

    // The area, a link where there is a page to go to, and said to be closed
    // where there is not.
    const area = make("th", "meanings-area");
    area.scope = "row";
    const name = strings.t(AREA_KEYS[row.theme]);
    const path = BUILT[row.theme];
    const title = path ? make("a", "meanings-area__name", name) : make("span", "meanings-area__name", name);
    if (path) title.href = path;
    strings.dress(title, AREA_KEYS[row.theme]);
    area.append(title);
    if (!path) {
      const closed = make("span", "label meanings-area__closed", strings.t("notYet"));
      strings.dress(closed, "notYet");
      area.append(closed);
    }
    tr.append(area);

    const meaning = make("td", "body meanings-meaning", strings.t(row.meaning));
    meaning.dataset.label = strings.t("meaningsMeaning");
    strings.dress(meaning, row.meaning);
    tr.append(meaning);

    const names = make("td", "meanings-names");
    names.dataset.label = strings.t("meaningsNames");
    for (const entry of row.heads) names.append(headNode(entry, true));
    tr.append(names);

    row.parts.forEach((entry, index) => {
      const cell = english(make("td", "meanings-part"));
      cell.dataset.label = ENDINGS[index].map((tail) => `-${tail}`).join(" ");
      cell.append(
        make("span", "meanings-part__label", entry.label),
        make("span", "meanings-part__instances", entry.instances)
      );
      tr.append(cell);
    });

    body.append(tr);
  }
}

function showEpithets(strings) {
  const body = document.getElementById("epithets-body");
  if (!body) return;
  body.replaceChildren();

  const heads = document.getElementById("epithets-head");
  if (heads) {
    heads.replaceChildren();
    const tr = make("tr");
    for (const key of ["meaningsWord", "meaningsSays"]) {
      const th = make("th", "label", strings.t(key));
      th.scope = "col";
      strings.dress(th, key);
      tr.append(th);
    }
    heads.append(tr);
  }

  for (const entry of EPITHETS) {
    const tr = make("tr");
    tr.append(make("td", "meanings-word", entry.words));
    tr.append(english(make("td", "meanings-says", entry.says)));
    body.append(tr);
  }
}

/// Holds this table to the one the site already reads names by.
///
///     node --input-type=module -e "import('./Server/assets/js/meanings.js').then(m => m.selfTest())"
///
/// **Every head once, in the theme `passages.js` puts it in; every ending
/// picking the part it is listed under; the ten in the order the map names
/// them; and the example filed where it says it is.** A drift in any of these
/// would still read perfectly well on the page, which is why it is checked
/// rather than looked at.
export function selfTest() {
  const fail = (message) => {
    throw new Error(`meanings.js: ${message}`);
  };

  const order = THEMES.map((row) => row.theme).join(" ");
  if (order !== Object.keys(AREA_KEYS).join(" ")) fail(`themes out of map order: ${order}`);

  const syllablesSeen = THEMES.flatMap((row) => row.heads.map((entry) => entry.syllable));
  if (syllablesSeen.length !== 24) fail(`${syllablesSeen.length} heads, not twenty-four`);
  if (new Set(syllablesSeen).size !== 24) fail("a head is claimed twice");

  for (const row of THEMES) {
    for (const entry of row.heads) {
      if (themeOf(entry.syllable) !== row.theme) {
        fail(`${entry.syllable} is ${themeOf(entry.syllable)} on the site, ${row.theme} here`);
      }
    }
    if (row.parts.length !== 3) fail(`${row.theme} has ${row.parts.length} parts`);
    ENDINGS.forEach((band, index) => {
      for (const tail of band) {
        const picked = subthemeOf(tail, row.theme);
        if (picked !== row.parts[index].key) {
          fail(`-${tail} picks ${picked} in ${row.theme}, listed as ${row.parts[index].key}`);
        }
      }
    });
  }

  if (ENDINGS.flat().length !== 10) fail("ten endings");

  const { head: syllable, tail } = syllables(EXAMPLE.genus);
  if (syllable !== "Nyx" || tail !== "ora") fail(`the example reads as ${syllable} + ${tail}`);
  if (subthemeOf(tail, themeOf(syllable)) !== "theLongCount") fail("the example is filed wrongly");
  if (!EPITHETS.some((entry) => entry.words === EXAMPLE.epithet)) fail("the example's epithet is not in the table");

  return true;
}
