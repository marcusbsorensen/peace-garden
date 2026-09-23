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
// website has no business in it. `walk.js` reads `BUILT` from here too, so the
// hub and the map at the foot of an area cannot come to disagree about which
// six are open.

import { AREA_KEYS } from "./strings.js";
import { AREAS, areaFor } from "./garden.js";

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
  // Named, and not dressed. `dress` marks a borrowed English label `dir="ltr"`
  // as well as `lang="en"`, and on the map itself that would pin the grid left
  // to right under Arabic or Hebrew — the one thing the map must not do.
  map.setAttribute("aria-label", strings.t("gardenTitle"));

  for (const area of AREAS) {
    const here = area.theme === theme;
    const href = BUILT[area.theme];
    const cell = document.createElement(href && !here ? "a" : "span");
    cell.className = "minimap__cell";
    cell.style.gridColumn = String(area.x + 1);
    cell.style.gridRow = String(area.y + 1);

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
