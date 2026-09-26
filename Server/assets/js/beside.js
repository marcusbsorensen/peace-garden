// The areas beside this one, for the glimpse of them out past the plot.
//
// **A garden you can walk out of should look like one.** Since 26 September
// the pad crosses the map: pressed against the end of the line with an area
// that way, a direction leaves for that area's page (`movepad.js`). Nothing in
// the drawing said there was anything out there. The map at the foot of the
// page says it, but a map is a diagram of a garden and not the garden, and a
// reader looking at the plot had no reason to think the plot was one of ten.
// So each open neighbour is drawn as a second slab of ground, small and dim,
// out in the sky on the side its key points to: `longwalk.js` builds and
// draws it, and this says what there is to draw.
//
// **There is one map and this reads it.** `garden.js` says which area lies
// which way, `gates.js` whether it is open and what colour its ground is.
// Neither is written down here a second time, and this file is the third to
// read that pair after `walk.js` and `movepad.js`.
//
// **Not a word of it is a word.** A named slab is forty-one translations, and
// the reader already has every area's name — in their own language — on the
// map at the foot of the page, which is also where they can press one.

import { DIRECTIONS, MAP_WIDTH, neighbouringArea } from './garden.js';
import { BUILT, LOOK } from './gates.js';

// **`LOOK`'s colours are grounds as the eye sees them and the shader wants
// what the ground is made of.** `gates.js` says so itself: its ten were made
// by taking `longwalk.js`'s albedos up about a quarter, which is what a plot
// comes out at under the garden's midday. This takes that quarter back off,
// so the slab beside the plot is painted in the same coin as the plot — and
// the map's ten colours stay the only ten there are.
const LIT = 1.25;

/// The open areas next to `theme`: which way each lies, what its ground is
/// made of, and the seed its outline is grown from.
///
/// **The seed is the area's own cell on the map**, so a place is the same
/// shape whichever side of it you stand on — the Knot Garden glimpsed from the
/// Seedbed and from the Glasshouse is one place seen twice, not two. It is not
/// the seed that area's page grows its own plot from: those belong to the ten
/// ground modules and none of them is exported, and importing all ten to draw
/// a slab a hundred and forty pixels wide would load the whole garden to show
/// the edge of it.
export function areasBeside(theme) {
  return Object.keys(DIRECTIONS).flatMap((direction) => {
    const area = neighbouringArea(theme, direction);
    if (!area || !BUILT[area.theme]) return [];
    return [{
      direction,
      theme: area.theme,
      seed: area.y * MAP_WIDTH + area.x,
      ground: albedo(LOOK[area.theme].ground),
    }];
  });
}

// `#rrggbb` as the ground shader takes it.
function albedo(hex) {
  return [1, 3, 5].map((at) => parseInt(hex.slice(at, at + 2), 16) / 255 / LIT);
}
