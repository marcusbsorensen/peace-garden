// The ways in and out of an area: the bar at the head of a page, and the map at
// its foot.
//
// **The garden had a hub and no edges.** `/g` could send a visitor to any of
// the built areas and nothing could send them anywhere afterwards, so every
// step of a walk went back through the map. The foot of an area page named its
// open neighbours for a while, one worded gate apiece; it draws the whole map
// now, small, with the reader's own area marked in it. The map is `garden.js`'s
// `AREAS`, read rather than written down again. There is one map.
//
// **Which areas are open is a different fact from where they are**, and it
// lives here rather than in `garden.js`: that file is the geometry, written so
// it can be checked with no browser and no site, and a table of paths on this
// website has no business in it. `walk.js` reads `BUILT` from here too, and so
// does `movepad.js`, which is how a reader walks off the edge of one area into
// the next — so the hub, the map at the foot of an area and the pad cannot come
// to disagree about which ten are open.

import { AREA_KEYS } from "./strings.js";
import { AREAS, COLUMN_RISE, DIRECTIONS, areaFor, neighbouringArea } from "./garden.js";

/// The areas with a page of their own, by theme.
///
/// When one opens, it is added here and it lights up on the map at the foot of
/// every area page without anything else changing.
export const BUILT = Object.freeze({
  travel: "/walk",
  peace: "/quiet",
  meeting: "/cross",
  kinship: "/orchard",
  pattern: "/knot",
  beginnings: "/seedbed",
  waiting: "/frame",
  light: "/glasshouse",
  renewal: "/coppice",
  ground: "/ground",
});

/// What each area looks like on the map: the colour of its ground, and a glyph
/// of its layout.
///
/// **The ground is the colour its page draws it**, lit: `COLOUR` in
/// `longwalk.js` is an albedo, and a plot on screen comes out about a quarter
/// brighter than it under the garden's midday, so these are those values
/// brought up to what the eye sees on the slab. Four areas stand on grass and
/// are green here, which is true of them; the glyph is what tells them apart.
/// Each area not yet built was given the ground its layout names, so the map
/// was already the garden it would be: the Glasshouse's tiles, the Coppice's
/// woodland floor and the Home Ground's dark soil were all on it before they
/// opened, and the soil is the colour `ground.js` brings down onto its beds.
///
/// **A glyph is the one shape each layout is known by**, drawn to BRAND.md §3.2
/// as the pad's are: monoline, even weight, round free ends, on a 20-unit grid.
/// A dot is a stroke of no length, which a round cap draws as a dot. Nothing is
/// written in a cell, for the reason the cells are unnamed on the page: at this
/// size a word would be the loudest thing there. Glyphs do not mirror under a
/// right-to-left language — a cold frame is higher at its back whichever way a
/// page is read.
const ring = (cx, cy, r) =>
  `M${cx - r} ${cy}a${r} ${r} 0 1 0 ${2 * r} 0a${r} ${r} 0 1 0 ${-2 * r} 0`;
const dot = (x, y) => `M${x} ${y}h0`;
// A bed seen from above, 3.9 wide and 14 long, its corners eased: `x` is where
// its top edge starts, after the corner. Relative, so no corner is arithmetic
// that JavaScript can round into 11.249999999999998.
const bed = (x) =>
  `M${x} 3h2.5a.7 .7 0 0 1 .7 .7v12.6a.7 .7 0 0 1 -.7 .7h-2.5a.7 .7 0 0 1 -.7 -.7v-12.6a.7 .7 0 0 1 .7 -.7Z`;

export const LOOK = Object.freeze({
  // A frame seen from its end: the ground, a low front, a high back, and the
  // light resting on the back and propped at the front, with a seedling under it.
  waiting: { ground: "#968b78",
    glyph: "M2.5 16H17.5M4.5 16V12.5M15.5 16V8.2M15.8 7.4L4 9.8M10 16V13.4M10 14.2c1.3-.2 2-.9 2.2-2" },
  // Three beds from above, a crop to each: spires as short upright strokes,
  // umbels as flat heads, succulents as rosettes packed close. The three
  // marks differ in shape, not just in number, so the crops still tell apart
  // at 20px, where a ring the size of a rosette closes into a dot.
  ground: { ground: "#4d3b2c",
    glyph: `${bed(2.5)}${bed(8.75)}${bed(15)}M3.75 5.4V7M3.75 9.2V10.8M3.75 13V14.6M9.55 6.2H10.45M9.55 10H10.45M9.55 13.8H10.45${dot(16.25, 5.6)}${dot(16.25, 8.4)}${dot(16.25, 11.2)}${dot(16.25, 14)}` },
  // Three drills, and the label at the head of them.
  beginnings: { ground: "#6a5641",
    glyph: "M7.5 6H17M7.5 10H17M7.5 14H17M4 16.5V8.5M2.6 8.9L4.9 5.6" },
  // A stool with its poles, new wood fanning from an old cut.
  renewal: { ground: "#5e4a33",
    glyph: "M6 16.5H14M10 16.5V3.5M10 16.5L5.8 5M10 16.5L14.2 5M8 16.5L3.5 9M12 16.5L16.5 9" },
  // A walk seen down its length: two borders drawing together.
  travel: { ground: "#5b6648",
    glyph: "M3 17.5L8.7 2.5M17 17.5L11.3 2.5" },
  // An enclosure: a hedge round, one tree, one bench.
  peace: { ground: "#56654a",
    glyph: `M5.5 3.5H14.5A2 2 0 0 1 16.5 5.5V14.5A2 2 0 0 1 14.5 16.5H5.5A2 2 0 0 1 3.5 14.5V5.5A2 2 0 0 1 5.5 3.5Z${ring(7.8, 7.8, 1.8)}M11 13.2H13.8` },
  // Five trees on a quincunx.
  kinship: { ground: "#66704a",
    glyph: `${ring(5, 5, 1.7)}${ring(15, 5, 1.7)}${ring(10, 10, 1.7)}${ring(5, 15, 1.7)}${ring(15, 15, 1.7)}` },
  // A square and a diamond woven through each other: the oldest knot there is.
  pattern: { ground: "#968b78",
    glyph: "M5 5H15V15H5ZM10 2.5L17.5 10L10 17.5L2.5 10Z" },
  // A glasshouse end-on: a pitched roof and its glazing bars.
  light: { ground: "#8a5a43",
    glyph: "M2.5 16.5H17.5M3.5 16.5V9L10 3.5L16.5 9V16.5M10 3.5V16.5M6.7 6.3V16.5M13.3 6.3V16.5" },
  // Four paths meeting at a round of paving.
  meeting: { ground: "#5b6648",
    glyph: `${ring(10, 10, 2.8)}M10 2.5V7.2M10 12.8V17.5M2.5 10H7.2M12.8 10H17.5` },
});

/// The bar's link back to the hub, from an area.
///
/// `/g` reads `location.hash` for the area it should open on — `readFragment`
/// in `walk.js` — so returning to the map from the Knot Garden can put the
/// reader back in the Knot Garden rather than at the top of a map they have to
/// find their place in again.
export function hubHref(theme) {
  return areaFor(theme) ? `/garden#${encodeURIComponent(theme)}` : "/garden";
}

/// Point the bar's link at this area of the map, and draw the map at the foot
/// of the page, once the language has settled.
///
/// `strings` is the settled catalogue from `plain.js`. Nothing here is written
/// before it arrives, because every word of it is an area's name and those are
/// the reader's own.
///
/// **It is written to be run again.** The chooser settles a second language
/// without reloading the page, and an area's name is one of the things that
/// changes when it does — so the map is cleared and drawn afresh rather than
/// added to. `plain.js`'s `whenSettled` is what calls it each time.
export function openWays(theme, strings) {
  const hub = document.getElementById("bar-hub");
  if (hub) hub.href = hubHref(theme);

  const map = document.getElementById("minimap");
  if (!map) return;
  drawMap(map, theme, strings);
}

/// The garden's ten areas, five by two, as ten small cells.
///
/// **Three kinds of cell, and only one of them is a link.** The area the
/// reader is standing in is filled. The other built areas are drawn in the
/// hairline and are links to their pages. The areas not yet open are drawn
/// fainter still, and are neither links nor stops for the keyboard nor
/// anything a screen reader is told about: a closed area has nowhere to send
/// anybody, and a place in the tab order that goes nowhere is worse than none.
///
/// Placed by `x` and `y` on a CSS grid rather than by the order they are
/// written in, so the picture is the table and cannot drift from it — and a
/// grid's columns follow the writing direction, so under Arabic or Hebrew the
/// map mirrors exactly as `/g`'s does.
///
/// **Names without words on the page.** Each lit cell is named for a screen
/// reader and in its tooltip by the area's own name from `AREA_KEYS`, which is
/// commissioned in every language the map has; nothing is written inside a
/// cell, because at this size a name would be the loudest thing on the page.
function drawMap(map, theme, strings) {
  map.replaceChildren();
  // **The ones standing beside the reader in the viewport**, marked so that
  // the corner and the canvas are plainly the same garden: the slab out to the
  // left of the plot is this cell, and a reader who looks from one to the
  // other should not have to work that out.
  //
  // The same test `areasBeside` makes in `beside.js`, made again here in four
  // lines rather than imported, because that module reads `BUILT` and `LOOK`
  // from this one and importing it back would close a cycle. `BUILT` is the
  // whole of the rule and it is defined at the top of this file.
  const beside = new Set(Object.keys(DIRECTIONS)
    .map((direction) => neighbouringArea(theme, direction)?.theme)
    .filter((next) => next && BUILT[next]));
  // Named, and not dressed. `dress` marks a borrowed English label `dir="ltr"`
  // as well as `lang="en"`, and on the map itself that would pin the grid left
  // to right under Arabic or Hebrew — the one thing the map must not do.
  map.setAttribute("aria-label", strings.t("gardenTitle"));
  // How far the garden falls end to end, so the stylesheet can leave room at
  // the top for the lift without the number being written down twice.
  map.style.setProperty("--map-fall", String(Math.max(...COLUMN_RISE)));

  for (const area of AREAS) {
    const here = area.theme === theme;
    const href = BUILT[area.theme];
    const cell = document.createElement(href && !here ? "a" : "span");
    cell.className = "minimap__cell";
    cell.style.gridColumn = String(area.x + 1);
    cell.style.gridRow = String(area.y + 1);
    // How high this column stands, in metres, for the stylesheet to lift the
    // cell by. The map is the garden's ground and the garden's ground falls
    // from one end to the other, so the picture in the corner is a slope.
    cell.style.setProperty("--rise", String(COLUMN_RISE[area.x]));
    if (beside.has(area.theme)) cell.classList.add("minimap__cell--beside");
    const look = LOOK[area.theme];
    cell.style.setProperty("--area-ground", look.ground);
    cell.append(glyph(look.glyph));

    if (!href) {
      cell.classList.add("minimap__cell--closed");
      cell.setAttribute("aria-hidden", "true");
    } else {
      const key = AREA_KEYS[area.theme];
      const name = strings.t(key);
      cell.setAttribute("aria-label", name);
      cell.title = name;
      strings.dress(cell, key);
      if (here) {
        cell.classList.add("minimap__cell--here");
        // Named, and marked as where the reader is, but not a link: a link to
        // the page already open is a stop in the tab order that goes nowhere.
        cell.setAttribute("role", "img");
        cell.setAttribute("aria-current", "location");
      } else {
        cell.href = href;
      }
    }
    map.append(cell);
  }
  map.hidden = false;
}

/// One area's glyph, drawn as the pad's are and hidden from a screen reader:
/// the cell carries the area's name, and the drawing says nothing more.
function glyph(d) {
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("class", "minimap__glyph");
  svg.setAttribute("viewBox", "0 0 20 20");
  svg.setAttribute("aria-hidden", "true");
  svg.setAttribute("focusable", "false");
  const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
  path.setAttribute("d", d);
  svg.append(path);
  return svg;
}
