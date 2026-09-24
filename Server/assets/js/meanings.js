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
// the site says, commissioned since 24 September and falling back in silence
// where a language has none yet. The heads
// and roots are proper nouns and travel as they are. The subtheme labels, the
// instances under them and the epithet glosses are English data here rather
// than sixty more commissions: they are the project's own record of what it
// attributed to what, quoted, and a table a reader looks things up in. If they
// are ever commissioned, moving them into the catalogue is mechanical.

import { AREA_KEYS } from "./strings.js";
import { BUILT, LOOK } from "./gates.js";
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

// ── The drawing kit ─────────────────────────────────────────────────────────
// What the glyphs below are built from. Every one is drawn to BRAND.md §3.2 as
// the pad's and `LOOK`'s are: monoline, even weight, round free ends, no filled
// shape, on a 20-unit grid, stroked at 1.25 by the stylesheet. Written as small
// functions rather than as long literal paths where a shape repeats — a leaf is
// a leaf whether it is a young shoot's or an olive's — and rounded to two places
// so the paths stay short enough to read.
const r2 = (value) => Math.round(value * 100) / 100;

const ring = (cx, cy, r) =>
  `M${r2(cx - r)} ${r2(cy)}a${r} ${r} 0 1 0 ${r2(2 * r)} 0a${r} ${r} 0 1 0 ${r2(-2 * r)} 0`;

// A stroke of no length, which a round cap draws as a dot.
const dot = (x, y) => `M${x} ${y}h0`;

// A leaf: a pointed lens from its base at `x, y`, pointing along `angle` in
// degrees as the screen measures them (0 to the right, -90 straight up), with
// its midrib drawn two-thirds of the way when `rib` is set.
function leaf(x, y, angle, length, width, rib = false) {
  const a = (angle * Math.PI) / 180;
  const ux = Math.cos(a), uy = Math.sin(a);
  const nx = -uy, ny = ux;
  const at = (along, across) => `${r2(x + ux * along + nx * across)} ${r2(y + uy * along + ny * across)}`;
  const w = width * 1.3;
  let d = `M${at(0, 0)}C${at(length * 0.3, w)} ${at(length * 0.75, w * 0.8)} ${at(length, 0)}`;
  d += `C${at(length * 0.75, -w * 0.8)} ${at(length * 0.3, -w)} ${at(0, 0)}`;
  if (rib) d += `M${at(0, 0)}L${at(length * 0.66, 0)}`;
  return d;
}

// The same leaf with a toothed edge: a zigzag round the same outline.
function toothedLeaf(x, y, angle, length, width) {
  const a = (angle * Math.PI) / 180;
  const ux = Math.cos(a), uy = Math.sin(a);
  const nx = -uy, ny = ux;
  const at = (along, across) => `${r2(x + ux * along + nx * across)} ${r2(y + uy * along + ny * across)}`;
  const steps = 10;
  const side = (sign) => {
    const points = [];
    for (let i = 1; i < steps; i += 1) {
      const t = i / steps;
      const half = width * Math.pow(Math.sin(Math.PI * t), 0.75) * (i % 2 ? 1.25 : 0.8);
      points.push(at(length * t, sign * half));
    }
    return points;
  };
  const up = side(1), down = side(-1).reverse();
  return `M${at(0, 0)}L${[...up, at(length, 0), ...down, at(0, 0)].join("L")}M${at(0, 0)}L${at(length * 0.66, 0)}`;
}

// A pointed-cell hexagon, for the comb.
function hex(cx, cy, s) {
  const w = (Math.sqrt(3) * s) / 2;
  const points = [[0, -s], [w, -s / 2], [w, s / 2], [0, s], [-w, s / 2], [-w, -s / 2]];
  return `M${points.map(([px, py]) => `${r2(cx + px)} ${r2(cy + py)}`).join("L")}Z`;
}

// Rays round a centre, from `inner` to `outer`, at the given angles.
const rays = (cx, cy, inner, outer, angles) =>
  angles
    .map((deg) => {
      const a = (deg * Math.PI) / 180;
      const c = Math.cos(a), s = Math.sin(a);
      return `M${r2(cx + c * inner)} ${r2(cy + s * inner)}L${r2(cx + c * outer)} ${r2(cy + s * outer)}`;
    })
    .join("");

// A drop of water hanging point-up, its round belly centred on `x`, its point
// at `top`, `size` the belly's radius.
const drop = (x, top, size) =>
  `M${x} ${top}C${r2(x - size * 0.7)} ${r2(top + size * 1.3)} ${r2(x - size)} ${r2(top + size * 1.9)} ${r2(x - size)} ${r2(top + size * 2.4)}` +
  `a${size} ${size} 0 0 0 ${r2(2 * size)} 0` +
  `C${r2(x + size)} ${r2(top + size * 1.9)} ${r2(x + size * 0.7)} ${r2(top + size * 1.3)} ${x} ${top}Z`;

// A petal seen flat, its stalk end at the foot of the grid.
const PETAL = "M10 17.5C4.5 14.5 3.8 4 10 3C16.2 4 15.5 14.5 10 17.5Z";

// A flower seen from above: five round petals about a centre, each an arc of
// radius `petal` bulging out between two points on a circle of radius `r`.
function blossom(cx, cy, r, petal) {
  const at = (k) => {
    const a = ((-90 + 36 + 72 * k) * Math.PI) / 180;
    return `${r2(cx + Math.cos(a) * r)} ${r2(cy + Math.sin(a) * r)}`;
  };
  let d = `M${at(0)}`;
  for (let k = 1; k <= 5; k += 1) d += `A${petal} ${petal} 0 1 1 ${at(k % 5)}`;
  return d + "Z";
}

// A small bird seen from below, as a child draws one: two arcs meeting.
const bird = (x, y, w) => `M${r2(x - w)} ${y}q${r2(w / 2)} ${r2(-w / 2)} ${w} 0q${r2(w / 2)} ${r2(-w / 2)} ${w} 0`;

/// What each name-start was taken from, drawn.
///
/// **One picture per root, and the picture is the gloss**, said as literally as
/// a 20-point drawing can say it, so a reader with no Latin, no Greek and no
/// English can still read a name: a crescent is night in every language the
/// site speaks. Where two glosses would come out as one picture they are drawn
/// apart on purpose — night is a crescent with a star, the moon is the full
/// moon; dew is a drop on a blade of grass, dew again is a drop in a turning
/// arrow; the west wind is three long streams, a gust one tight whirl.
///
/// Read by `head` below, so each head in `THEMES` carries its own drawing, and
/// the area page and `/meanings` draw from the one place. They do not mirror
/// under a right-to-left language: a dog faces the way it faces, and a wind out
/// of the west blows from the west whichever way a page is read.
const HEAD_GLYPHS = Object.freeze({
  // Night: a crescent moon, with a star in the dark beside it.
  Nyx: "M12 4.5A6.5 6.5 0 1 0 12 16.5A7 7 0 0 1 12 4.5ZM16 3.6V7M14.3 5.3H17.7" + dot(16.6, 11.2),
  // Shade: a parasol planted in the ground — the word *umbrella* is *umbra*,
  // made small — with its shadow at its foot.
  Umbr:
    "M3 10A7 7 0 0 1 17 10A2.33 2.33 0 0 0 12.33 10A2.33 2.33 0 0 0 7.67 10A2.33 2.33 0 0 0 3 10ZM10 3V2.2M10 10V17.2M5.5 17.2H14.5",
  // The grain: an ear of wheat, two pairs of kernels and one at the tip.
  Cer:
    "M10 18V7.5" +
    leaf(10, 15.5, -140, 4.2, 1.3) + leaf(10, 15.5, -40, 4.2, 1.3) +
    leaf(10, 11.8, -140, 4.2, 1.3) + leaf(10, 11.8, -40, 4.2, 1.3) +
    leaf(10, 8.2, -90, 4.6, 1.2) + "M10 3.6V1.8",
  // Low wet ground: reeds, one with its head, standing in water.
  Fen:
    "M8 14.5V7.2M8 7.2C7.2 6.2 7.2 4.2 8 3.2C8.8 4.2 8.8 6.2 8 7.2M11 14.5C11 11 12 8.2 14.3 5.2M5.6 14.5C5.6 12 5 10.2 3.6 8.4" +
    "M2.5 15.5c1.25-.9 2.5-.9 3.75 0s2.5.9 3.75 0 2.5-.9 3.75 0 2.5.9 3.75 0M5 18.2c1.25-.9 2.5-.9 3.75 0s2.5.9 3.75 0",
  // The earth's skin: the ground's surface with grass on it, and the layers of
  // soil it covers.
  Pell:
    "M2.5 9C6.5 8 13.5 8 17.5 9M5.5 8.4V5.8M7.3 8.3L8.3 6.2M13 8.3L12.2 6M14.8 8.5V6.3M4.5 12.7H15.5M6.5 16.2H13.5" + dot(9, 14.5),
  // A young shoot: a seedling's two first leaves over the ground.
  Thal: "M4 17.2H16M10 17.2V9" + leaf(10, 11.6, -155, 5.6, 1.6) + leaf(10, 9, -35, 5.8, 1.7),
  // Lily: the fleur-de-lis, the lily as it has been drawn for a thousand years.
  Lir:
    "M10 2.5C12 5 12 8 10 11C8 8 8 5 10 2.5ZM6.5 11.5H13.5M9.3 11C6.5 11 3 9.5 3.5 6.5C4 5 6 5.2 6 6.8" +
    "M10.7 11C13.5 11 17 9.5 16.5 6.5C16 5 14 5.2 14 6.8M8.4 11.5C8.2 14 7 16 5.5 16.8M11.6 11.5C11.8 14 13 16 14.5 16.8M10 11.5V17.5",
  // The spring: a blossom, five petals open round its heart.
  Ver: blossom(10, 10.4, 2.9, 2.5) + ring(10, 10.4, 1),
  // Dew: a blade of grass, with a drop gathered at its tip.
  Dros: "M4.5 18C5.5 11 9.5 6.5 15.5 4.5C12.5 8.5 9 12.5 7 18" + drop(15.5, 8.8, 1.7),
  // Dew again: a drop, inside an arrow that comes round to where it began.
  Ros: drop(10, 6.6, 2.3) + "M15.16 5.34A7.3 7.3 0 1 1 4.84 5.34M2.65 5.53L4.84 5.34L4.65 7.53",
  // The west wind: three long streams of air out of the west, curling at the
  // end of their run.
  Zeph: "M2.5 7H12a2.2 2.2 0 1 0-2.2-2.2M2.5 10.5H15.3a2.2 2.2 0 1 1-2.2 2.2M2.5 14H8.5",
  // A gust: one tight whirl of air, and the rush that carries it.
  Ael: "M2.5 14.5H10.5a4 4 0 1 0-4-4a2.2 2.2 0 0 0 2.2 2.2a1 1 0 0 0 1-1M4.5 17.5H13",
  // The salt sea: rows of waves.
  Hal:
    "M2.5 7c1.25-1.2 2.5-1.2 3.75 0s2.5 1.2 3.75 0 2.5-1.2 3.75 0 2.5 1.2 3.75 0" +
    "M2.5 11c1.25-1.2 2.5-1.2 3.75 0s2.5 1.2 3.75 0 2.5-1.2 3.75 0 2.5 1.2 3.75 0" +
    "M2.5 15c1.25-1.2 2.5-1.2 3.75 0s2.5 1.2 3.75 0 2.5-1.2 3.75 0 2.5 1.2 3.75 0",
  // The olive: a sprig, its narrow leaves in pairs and one fruit hanging.
  Ol:
    "M3.5 17.5C7 14 10.5 10 15 4.5" +
    leaf(6.2, 14.8, -95, 4.2, 0.9) + leaf(6.2, 14.8, -5, 4.2, 0.9) +
    leaf(10, 10.7, -100, 4.2, 0.9) + leaf(10, 10.7, -10, 4.2, 0.9) + leaf(15, 4.5, -50, 2.6, 0.8) +
    "M12.6 7.6L14.2 9.4" + ring(15, 10.8, 1.4),
  // A clear sky: the sun high in it with nothing round it, and birds.
  Bel: ring(14.5, 5.5, 2) + bird(6, 9, 2.4) + bird(10.4, 12.4, 1.8) + "M2.5 16.5H17.5",
  // A bond: two links of a chain, each through the other.
  Vin:
    "M4.53 15.47A4.2 2.2 -45 1 1 10.47 9.53A4.2 2.2 -45 1 1 4.53 15.47Z" +
    "M9.53 10.47A4.2 2.2 -45 1 1 15.47 4.53A4.2 2.2 -45 1 1 9.53 10.47Z",
  // The dog that waits at the door: a dog, sitting, looking out.
  Cyn:
    "M6 17.5C5.6 14.5 6 11.8 8 10.2C9.3 9.2 10.4 8.6 11 7.4L11.6 4.8C11.9 3.9 12.7 3.5 13.6 3.7L15.4 4.4L17.2 5.6L16.9 6.7L14.6 7.2" +
    "C14 8.6 14.2 10.5 14.4 12.4C14.6 14.3 14.2 16 13.8 17.5M12.6 4.1L11.8 7M4.5 17.5H15M11 17.5V13.8M6.2 15.4C4.4 15.6 3.2 14.6 3 12.8",
  // The shapely: a Greek jar, all curve, which is what *kalos* was said of.
  Cal:
    "M8.3 3.2C8.7 5 8.7 5.8 7.6 6.8C4.6 9.4 4.8 13.6 8.2 17H11.8C15.2 13.6 15.4 9.4 12.4 6.8C11.3 5.8 11.3 5 11.7 3.2M6.8 3.2H13.2" +
    "M8.4 4.8C6.3 4.4 5.4 6 6.2 7.8M11.6 4.8C13.7 4.4 14.6 6 13.8 7.8",
  // Five: the five of a die.
  Quin:
    "M5.5 3.5H14.5A2 2 0 0 1 16.5 5.5V14.5A2 2 0 0 1 14.5 16.5H5.5A2 2 0 0 1 3.5 14.5V5.5A2 2 0 0 1 5.5 3.5Z" +
    ring(7, 7, 0.6) + ring(13, 7, 0.6) + ring(10, 10, 0.6) + ring(7, 13, 0.6) + ring(13, 13, 0.6),
  // The sun: a disc with its rays all round.
  El: ring(10, 10, 3.3) + rays(10, 10, 5.4, 7.5, [0, 45, 90, 135, 180, 225, 270, 315]),
  // Dawn: the sun half over the horizon, its first rays going up.
  Aur: "M2.5 14.5H17.5M6 14.5A4 4 0 0 1 14 14.5M6.5 17.5H13.5" + rays(10, 14.5, 5.6, 7.6, [-90, -45, -135, -165, -15]),
  // The moon: the full moon, with its seas.
  Sel: ring(10, 10, 6.8) + ring(7.6, 8, 1.5) + ring(12.8, 12.4, 1.1) + ring(12.2, 6.6, 0.7),
  // Honey: the comb, three cells of it.
  Mel: hex(7.4, 7.2, 3.1) + hex(12.77, 7.2, 3.1) + hex(10.09, 11.85, 3.1) + "M10.09 14.95V16.2" + dot(10.09, 18),
  // The place arrived at: a pin in the map, standing on its ground.
  Ith: "M10 17C10 17 4.5 11.8 4.5 8a5.5 5.5 0 0 1 11 0C15.5 11.8 10 17 10 17Z" + ring(10, 8, 2) + "M6.5 18.2H13.5",
});

const head = (syllable, from, root, gloss) =>
  Object.freeze({ syllable, from, root, gloss, glyph: HEAD_GLYPHS[syllable] });
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

// For the second words' drawings: the ground a stem stands on, a stem, and a
// flower at the top of one.
const GROUND = "M3 17.5H17";
const stem = (x, top) => `M${x} 17.5V${top}`;
const flowerOn = (x, y) => ring(x, y, 1.4);

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
///
/// **Each with a drawing of the trait**, to the heads' rules, and where a row is
/// a pair the drawing is the pair side by side — a short stem beside a tall one
/// — because the contrast is what the two words say. The six colours are the
/// one place a glyph here is not drawn in the ink: a row that means *golden* is
/// drawn golden. Colour belongs to the plants, and these are the plants'
/// colours; each tinted drawing is a list of `[path, colour]` pairs rather
/// than one path.
export const EPITHETS = Object.freeze([
  // A short stem beside a tall one, each with its flower.
  ["nana · elata", "a short stem · a tall one",
    GROUND + stem(6.5, 13.4) + flowerOn(6.5, 12) + stem(13.5, 5) + flowerOn(13.5, 3.6)],
  // A stem of one line beside a stem with girth.
  ["gracilis · crassicaulis", "a slender stem · a thick one",
    GROUND + stem(6.5, 4) + "M12.2 17.5V5.2A1.4 1.4 0 0 1 15 5.2V17.5"],
  // A stem leaning over from the ground.
  ["declinata", "a stem that leans", GROUND + "M6.5 17.5C7.5 12 10.5 8.5 15 6.5" + flowerOn(16.2, 5.9)],
  // Two strands wound round each other.
  ["contorta", "a twisted stem", GROUND + "M8.2 17.5C12.6 14.5 12.6 11.5 8.2 8.5S8.2 4.3 11.8 2.6M11.8 17.5C7.4 14.5 7.4 11.5 11.8 8.5S11.8 4.3 8.2 2.6"],
  // A stem bending in the air, and the air that moves it.
  ["flexuosa", "a stem that sways",
    GROUND + "M8.5 17.5C8.5 13 12.5 11 11 5.6" + flowerOn(10.6, 4.2) + "M14.4 9.8c.9.8.9 2.3 0 3.1M16.3 8.8c1.6 1.4 1.6 3.9 0 5.3"],
  // A short leaf beside a long one.
  ["brevifolia · longifolia", "short leaves · long ones", leaf(6, 17.5, -90, 6, 1.9, true) + leaf(14, 17.5, -90, 15, 1.9, true)],
  // A narrow leaf beside a broad one.
  ["angustifolia · latifolia", "narrow leaves · broad ones", leaf(5.5, 17.5, -90, 15, 1.1, true) + leaf(13, 17.5, -90, 15, 3.8, true)],
  // A leaf with a smooth edge beside one with a toothed edge.
  ["integrifolia · serratifolia", "smooth-edged leaves · toothed ones", leaf(6, 17.5, -90, 14, 2.4, true) + toothedLeaf(14, 17.5, -90, 14, 2.4)],
  // Leaves held up from one stem, and hanging from the other.
  ["erecta · pendula", "leaves held up · leaves that droop",
    GROUND + stem(5.5, 5) + leaf(5.5, 10, -130, 4.6, 1) + leaf(5.5, 10, -50, 4.6, 1) +
    stem(14.5, 5) + leaf(14.5, 6.2, 125, 4.6, 1) + leaf(14.5, 6.2, 55, 4.6, 1)],
  // Leaves spread flat, out to either side.
  ["patentifolia", "leaves that spread wide", GROUND + stem(10, 4) + leaf(10, 10.5, 180, 7, 1.2) + leaf(10, 10.5, 0, 7, 1.2)],
  // A stem crowded with leaves.
  ["foliosa", "many leaves",
    GROUND + stem(10, 2.8) +
    [15, 12.8, 10.6, 8.4, 6.2, 4].map((y, i) => leaf(10, y, i % 2 ? -25 : -155, 4.4, 0.9)).join("")],
  // A leaf striped with a second colour along its length.
  ["variegata", "variegated leaves", leaf(10, 17.5, -90, 15, 4.2, true) + leaf(10, 16, -90, 11.5, 2.2)],
  // A stem branching and branching again into a spray of flowers.
  ["paniculata", "a wide spray of flowers",
    "M10 18V9.5M10 13L5 8M10 13L15 8M10 9.5L7.2 5M10 9.5L12.8 5M10 9.5V3.8M5 8L3 7.2M15 8L17 7.2" +
    [[5, 8], [15, 8], [7.2, 5], [12.8, 5], [10, 3.8], [3, 7.2], [17, 7.2]].map(([x, y]) => ring(x, y, 0.7)).join("")],
  // One flower's colour three ways: pale, dark and vivid.
  ["pallida · obscura · vivida", "pale flowers · dark · vivid",
    [[ring(4.3, 10, 2.5), "#e2aac6"], [ring(10, 10, 2.5), "#8a2f5c"], [ring(15.7, 10, 2.5), "#ec2d86"]]],
  // Golden, blue, red.
  ["aurea · caerulea · rubra", "golden flowers · blue · red",
    [[ring(4.3, 10, 2.5), "#e0a82e"], [ring(10, 10, 2.5), "#4f86dc"], [ring(15.7, 10, 2.5), "#d8413b"]]],
  // A petal with a band of edge inside its outline.
  ["marginata", "petals edged in another colour", PETAL + "M10 15.4C6.2 13.2 5.8 5.7 10 5C14.2 5.7 13.8 13.2 10 15.4Z"],
  // A petal clouded with drifting marks, as stone is.
  ["marmorata", "marbled petals", PETAL + "M6.6 8.4C8.5 7.8 9.5 9.6 11.6 8.6M6.4 12.3C8.2 11.4 10.2 13.6 13.2 12.2M9 5.8C10 6.2 11.2 5.5 12 6"],
  // A petal with its veins drawn.
  ["venosa", "veined petals", PETAL + "M10 17.5V6M10 13.5L7 10.5M10 13.5L13 10.5M10 10L7.8 7.4M10 10L12.2 7.4"],
  // A flower open under a crescent moon.
  ["noctiflora", "flowers that open at night",
    "M9 18V12.2M9 12.2C6 12.2 4.4 10 4.4 7.4L6.8 9L9 6.2L11.2 9L13.6 7.4C13.6 10 12 12.2 9 12.2" +
    "M16 2.8A3 3 0 1 0 17.8 7.6A3.3 3.3 0 0 1 16 2.8Z"],
  // A plant with nothing to single it out: a stem, two leaves, a flower.
  ["vulgaris", "nothing remarkable: an ordinary member of its genus",
    GROUND + stem(10, 7.2) + leaf(10, 13, -150, 4.2, 1.1) + leaf(10, 11, -30, 4.2, 1.1) + flowerOn(10, 5.6)],
].map(([words, says, glyph]) => Object.freeze({ words, says, glyph })));

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

const SVG = "http://www.w3.org/2000/svg";

/// A drawing — one of this file's or one of `LOOK`'s — as an inline SVG hidden
/// from a screen reader: whatever it depicts is said in words beside it, so
/// the drawing adds nothing a listener is missing. `glyph` is one path, or a
/// list of `[path, colour]` pairs for the second words that are colours.
function drawn(glyph, className) {
  const svg = document.createElementNS(SVG, "svg");
  svg.setAttribute("class", className);
  svg.setAttribute("viewBox", "0 0 20 20");
  svg.setAttribute("aria-hidden", "true");
  svg.setAttribute("focusable", "false");
  const parts = typeof glyph === "string" ? [[glyph, null]] : glyph;
  for (const [d, colour] of parts) {
    const path = document.createElementNS(SVG, "path");
    path.setAttribute("d", d);
    if (colour) path.style.stroke = colour;
    svg.append(path);
  }
  return svg;
}

/// An area as the map draws it: its ground, with its layout's glyph on it. The
/// same tile as a cell of the map at the foot of an area page, so a reader who
/// has walked the garden knows each entry by its picture before its word.
function tile(theme, className) {
  const look = LOOK[theme];
  const span = make("span", `meanings-tile ${className}`);
  span.style.setProperty("--area-ground", look.ground);
  span.append(drawn(look.glyph, "meanings-tile__glyph"));
  return span;
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

  // **Set as a dictionary entry**, since 24 September: the theme's word as the
  // headword, what it means as the definition, and the three parts as its
  // numbered senses. It is the one thing on the page that says why these
  // plants are here rather than somewhere else, which is what a reader looks a
  // word up for. The headword is the way to the whole table, at this row, and
  // carries the bar's book so it reads as one.
  const { word, definition } = splitEntry(strings.t(row.meaning));
  const entry = make("p", "gathers__entry");
  strings.dress(entry, row.meaning);
  if (word) {
    const link = make("a", "gathers__word");
    link.href = `/meanings#${theme}`;
    link.title = strings.t("meaningsTitle");
    link.append(make("dfn", null, word), drawn(BOOK, "gathers__book"));
    entry.append(link, " ");
  }
  entry.append(make("span", "gathers__definition", definition));

  // **The name-starts as drawings and nothing else.** A line of syllables and
  // roots cost the pad and the map their place above the fold on a laptop, and
  // Marcus chose the fold (23 September); the drawings sit at the end of the
  // headword's line instead, and cost the panel no height. Each is named in
  // words for a screen reader and in its tooltip — *Nyx, night* — and the
  // roots in full are on `/meanings`, a link away. They are the entry's own
  // drawings there, so the two read as one entry at two sizes.
  const heads = english(make("ul", "gathers__heads"));
  for (const one of row.heads) {
    const item = make("li", "gathers__glyph");
    item.title = `${one.syllable}, ${one.gloss}`;
    item.append(drawn(one.glyph, "gathers__head-glyph"), make("span", "visually-hidden", `${one.syllable}, ${one.gloss}`));
    heads.append(item);
  }

  const senses = english(make("ol", "gathers__senses"));
  for (const part of row.parts) senses.append(make("li", "gathers__part", part.label));

  block.append(entry, heads, senses);
  block.hidden = false;
}

/// One `meaning*` line as a headword and its definition.
///
/// Every English line is *Word: what it means*, and a translation is asked to
/// keep the colon. One that did not — or a full-width colon, as Chinese and
/// Japanese write it — is still read right: the first colon of either kind
/// splits it, and a line with none is all definition and no headword, which
/// is a plain sentence rather than a broken entry.
export function splitEntry(text) {
  const at = text.search(/[:：]/);
  if (at < 1) return { word: null, definition: text.trim() };
  return { word: text.slice(0, at).trim(), definition: text.slice(at + 1).trim() };
}

/// The bar's open book, small, beside a headword. The same path as the bar's
/// and the app's `MeaningsGlyph`.
export const BOOK = "M10 5.2C8.2 3.9 5.4 3.5 2.75 3.9V15.4C5.4 15 8.2 15.4 10 16.7C11.8 15.4 14.6 15 17.25 15.4V3.9C14.6 3.5 11.8 3.9 10 5.2ZM10 5.2V16.7";

/// Everything `/meanings` draws: the worked example, the ten areas as tiles to
/// find an entry by, the ten entries, and the second words.
export function showMeanings(strings) {
  showExample(strings);
  showIndex(strings);
  showLexicon(strings);
  showEpithets();
}

function showExample(strings) {
  const figure = document.getElementById("example");
  if (!figure) return;
  figure.replaceChildren();

  const { head: syllable, tail } = syllables(EXAMPLE.genus);
  const theme = themeOf(syllable);
  const partKey = subthemeOf(tail, theme);
  const row = themeRow(theme);
  const partIndex = row.parts.findIndex((entry) => entry.key === partKey);
  const headEntry = row.heads.find((entry) => entry.syllable === syllable);
  const epithet = EPITHETS.find((entry) => entry.words === EXAMPLE.epithet);
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

  // What each piece says, under it, with the mark the rest of the page gives
  // that piece: the head's drawing, the sense's number, the second word's
  // drawing. A reader who reads none of the words can still match each piece
  // to its place further down by the picture.
  const keyed = make("dl", "meanings-example__key");
  const say = (mark, term, description, isEnglish) => {
    const pair = make("div", "meanings-example__pair");
    const dt = make("dt", "meanings-example__term");
    dt.append(mark, make("span", null, term));
    const dd = make("dd", "meanings-example__says", description);
    if (isEnglish) english(dd);
    pair.append(dt, dd);
    keyed.append(pair);
    return dd;
  };
  const area = say(drawn(headEntry.glyph, "meanings-example__glyph"), syllable, strings.t(AREA_KEYS[theme]), false);
  strings.dress(area, AREA_KEYS[theme]);
  const number = make("span", "meanings-example__number", String(partIndex + 1));
  number.setAttribute("aria-hidden", "true");
  say(number, `-${tail}`, row.parts[partIndex].label, true);
  say(drawn(epithet.glyph, "meanings-example__glyph"), EXAMPLE.epithet, epithet.says, true);

  figure.append(name, keyed);
  figure.hidden = false;
}

/// The ten areas as the map's tiles, five by two in the garden's own order, each
/// a way to its entry. **A contents drawn rather than written**: each tile is
/// named by its area's own name, commissioned in every language, for a screen
/// reader and in its tooltip, and says nothing on the screen.
function showIndex(strings) {
  const nav = document.getElementById("index");
  if (!nav) return;
  nav.replaceChildren();
  // Named, and not dressed, for the reason the map is not: `dress` would pin to
  // left to right a grid that must follow the writing direction.
  nav.setAttribute("aria-label", strings.t("gardenTitle"));
  for (const row of THEMES) {
    const key = AREA_KEYS[row.theme];
    const link = make("a", "meanings-index__link");
    link.href = `#${row.theme}`;
    link.setAttribute("aria-label", strings.t(key));
    link.title = strings.t(key);
    link.append(tile(row.theme, "meanings-index__tile"));
    nav.append(link);
  }
  nav.hidden = false;
}

/// The ten entries, one per area, in map order.
///
/// **Set as a dictionary sets a word.** The theme is the headword, with the
/// area's tile before it and the area's name after it, where a dictionary puts
/// the part of speech; then the definition; then the etymology — the
/// name-starts that bring a plant here, each drawn, the syllable in the serif
/// and the root it was taken from. The three parts are the numbered senses, in
/// a column of their own on a wide window, each with the endings that choose
/// it and the instances its passages were read into.
///
/// The headword and the definition are the area page's own, split from the one
/// `meaning*` line by `splitEntry`, so this entry and the small one under the
/// area's drawing cannot come to differ.
function showLexicon(strings) {
  const list = document.getElementById("lexicon");
  if (!list) return;
  list.replaceChildren();
  for (const row of THEMES) list.append(entryNode(row, strings));
}

function entryNode(row, strings) {
  const areaKey = AREA_KEYS[row.theme];
  const item = make("li", "entry");
  item.id = row.theme;
  // The entry a reader came from an area page to find. Marked by a class
  // rather than left to `:target`, because the entry did not exist when the
  // browser read the fragment.
  if (location.hash === `#${row.theme}`) item.classList.add("entry--here");

  // The headword, and the area beside it. A line with no colon in some
  // translation has no headword to give, and the area's name stands in.
  const { word, definition } = splitEntry(strings.t(row.meaning));
  const top = make("div", "entry__top");
  const heading = make("h2", "entry__word", word || strings.t(areaKey));
  strings.dress(heading, word ? row.meaning : areaKey);

  // The area, a link where there is a page to go to, and said to be closed
  // where there is not.
  const where = make("p", "label entry__area");
  const path = BUILT[row.theme];
  const name = make(path ? "a" : "span", "entry__area-name", strings.t(areaKey));
  if (path) name.href = path;
  strings.dress(name, areaKey);
  where.append(name);
  if (!path) {
    const closed = make("span", "entry__closed", strings.t("notYet"));
    strings.dress(closed, "notYet");
    where.append(" ", closed);
  }
  top.append(tile(row.theme, "entry__tile"), heading, where);

  const meaning = make("p", "entry__definition", definition);
  strings.dress(meaning, row.meaning);

  // The etymology: each name-start, drawn, then the root it was taken from and
  // what the root means. A description list because it is one — a syllable,
  // and what it stands for.
  const lead = make("p", "label entry__lead", strings.t("meaningsNames"));
  strings.dress(lead, "meaningsNames");
  const heads = make("dl", "entry__heads");
  for (const one of row.heads) {
    const line = make("div", "entry__head");
    const term = make("dt", "entry__syllable");
    term.append(drawn(one.glyph, "entry__glyph"), make("i", null, one.syllable));
    const root = english(make("dd", "entry__root"));
    if (one.from) root.append(make("span", "entry__from", one.from), " ");
    root.append(make("i", "entry__etymon", one.root), " ", make("q", "entry__gloss", one.gloss));
    line.append(term, root);
    heads.append(line);
  }

  const main = make("div", "entry__main");
  main.append(top, meaning, lead, heads);

  // The three parts as the numbered senses, the number drawn by the list. The
  // list itself follows the page's direction, so under Arabic or Hebrew the
  // numbers stand at the right and the column's rule between the two halves;
  // only the English runs inside it are marked as English.
  const senses = make("ol", "entry__senses");
  row.parts.forEach((part, index) => {
    const sense = make("li", "entry__sense");
    const label = make("p", "entry__sense-label");
    label.append(
      english(make("span", null, part.label)),
      english(make("span", "entry__endings", ENDINGS[index].map((tail) => `-${tail}`).join(" ")))
    );
    const instances = make("p", "entry__instances");
    instances.append(english(make("span", null, part.instances)));
    sense.append(label, instances);
    senses.append(sense);
  });

  item.append(main, senses);
  return item;
}

/// The second words, as a glossary: each with its drawing, the words in the
/// serif, and what they say under them.
function showEpithets() {
  const list = document.getElementById("epithets");
  if (!list) return;
  list.replaceChildren();
  for (const entry of EPITHETS) {
    const row = make("div", "glossary__row");
    const term = make("dt", "glossary__word");
    term.append(drawn(entry.glyph, "glossary__glyph"), make("i", null, entry.words));
    // The English run marked inside the definition rather than on it, so the
    // line still starts where the page's lines start.
    const says = make("dd", "glossary__says");
    says.append(english(make("span", null, entry.says)));
    row.append(term, says);
    list.append(row);
  }
  list.hidden = false;
}

/// Holds this table to the one the site already reads names by.
///
///     node --input-type=module -e "import('./Server/assets/js/meanings.js').then(m => m.selfTest())"
///
/// **Every head once, in the theme `passages.js` puts it in; every ending
/// picking the part it is listed under; the ten in the order the map names
/// them; the example filed where it says it is; and a drawing, its own, for
/// every head and every second word.** A drift in any of these
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

  // A head with no drawing would be drawn as an empty square on both pages,
  // and two heads with one drawing would say two roots are one.
  const drawings = THEMES.flatMap((row) => row.heads.map((entry) => entry.glyph));
  if (drawings.some((d) => typeof d !== "string" || !d.startsWith("M"))) fail("a head has no drawing");
  if (new Set(drawings).size !== drawings.length) fail("two heads share a drawing");
  if (Object.keys(HEAD_GLYPHS).length !== 24) fail("a drawing for a head that is not in the table");
  if (EPITHETS.some((entry) => !entry.glyph || !entry.glyph.length)) fail("a second word has no drawing");

  const { head: syllable, tail } = syllables(EXAMPLE.genus);
  if (syllable !== "Nyx" || tail !== "ora") fail(`the example reads as ${syllable} + ${tail}`);
  if (subthemeOf(tail, themeOf(syllable)) !== "theLongCount") fail("the example is filed wrongly");
  if (!EPITHETS.some((entry) => entry.words === EXAMPLE.epithet)) fail("the example's epithet is not in the table");

  return true;
}
