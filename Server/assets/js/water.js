// Water in the ground: a pool sunk into a plot, for the plants that want it.
//
// **The garden had none until 27 September.** No pond, pool, rill or tank in
// any of the ten, while `Archetype.lotus` has been modelled as a water lily
// since the shapes changed on the 24th — pads that lie one against another,
// a flower smaller than the pads — and was being sown in a drill. Marcus asked
// where the water was and the answer was nowhere.
//
// **Every area needs one, not the ones that suit it.** An area comes from the
// seed's theme and not from the plant's shape, so a lotus lands in whichever
// of the ten its own seed names. One pond in one area would catch a tenth of
// them and leave the rest standing in soil, which is the fault it was dug to
// fix. So this is a shared builder rather than a thing the Quiet Garden owns,
// and each area calls it with the size and the place its own layout allows.
//
// **The floor has to give way to it, and that is the whole of the work.** The
// first try laid the dish over the lawn on the grounds that a rim drawn above
// the mown stripes would hide what was under it. It does not: a pool is sunk,
// so its water lies *below* the floor, and the floor goes on covering it. What
// came out was a dark outline drawn on the grass.
//
// So an area's floor is cut. Two things this offers do the cutting, and a
// floor needs both: `rimOf` gives the loop to fan the floor out from, in place
// of the point in the middle it fanned from before, and `inside` says whether
// a piece of an overlay — a mown stripe, a raked drill — falls in the pool and
// should not be drawn. An overlay clipped piece by piece leaves an edge as
// ragged as its pieces are wide, which is why the rim is wider than that.

import { COLOUR, SIDE, readOutline, rimReach } from './longwalk.js';

export const POOL = {
  // How far the rim of bare wet earth reaches out past the water.
  lip: 0.10,
  // How far the dish falls from the rim to its floor, and how far below the
  // rim the water lies. The difference is the shallows a reader sees through
  // at the edge: enough to say there is a bottom, not enough to say how far.
  deep: 0.24,
  surface: 0.05,
  // Clear of the lawn's own overlays — a mown stripe sits at 4 mm — so the rim
  // never fights the grass for the same pixels.
  over: 0.007,
  // How many steps the rim and the water are walked in. The outlines this is
  // built from have their own counts, so both loops are read by how far round
  // they are rather than by index, and this is that walk's length.
  steps: 96,
};

/// Sink a pool into a plot's floor: the wet rim, the dish, and the water.
///
/// `at` is where its middle stands on the plot, `across` how wide it is, and
/// `seed` its own, so two pools are not one pool drawn twice. `tri` and `quad`
/// are the caller's own emitters, because every ground builder in this garden
/// keeps its vertices in its own arrays and handing them over is cheaper than
/// handing back a mesh to be copied in.
///
/// **Grown at a plot's size and then shrunk**, the way a neighbour slab is:
/// `Organic.outline` wanders a fixed 22 cm inward whatever size it is asked
/// for, so a pool asked for at 1.6 m across would come back with a plot's
/// whole wander in a fifth of the room and read as a puddle in a bomb crater
/// rather than as a basin.
/// The pool's outer rim as a floor has to know it: `rim(u)` walks the loop the
/// floor fans out from, `inside(x, z)` says whether a point is in the pool and
/// should not be drawn, and `steps` is how many pieces the loop is walked in.
/// `round` is a round pool's, the same as `sinkPool` takes.
///
/// One call gives a floor everything it needs, so the outline is read once and
/// the caller passes the same options to `sinkPool`.
///
/// **A pool laid out by hand** passes its own `outline` instead (2 October
/// 2026): the water's edge, a closed loop of [x, z] on the plot, as an area's
/// place table draws it and its plot's variant turns it — the Quiet Garden's
/// pool off the middle, the Cold Frame's kidney pond. The rim is that loop
/// pushed out by the lip all round, whichever way the loop runs; `across`,
/// `seed` and `round` are not read. `at` is then where the dish falls to: the
/// deepest water, which the loop has to be seen whole from.
///
/// `inWater(x, z)` says whether a point is inside the water's own edge, which
/// is what an overlay drawn above the rim's lip has to keep out of: the lip
/// lies over whatever reaches under it, and the water does not.
export function rimOf(e, { at = [0, 0], across, deep = across, seed, round = false, outline = null }) {
  let rim, edge;
  if (outline) {
    ({ rim, edge } = laidOut(outline));
  } else {
    const grown = shapeOf(e, seed, round);
    rim = ringAt(grown, [(across + 2 * POOL.lip) / SIDE, (deep + 2 * POOL.lip) / SIDE], at);
    edge = ringAt(grown, [across / SIDE, deep / SIDE], at);
  }
  const loop = Array.from({ length: POOL.steps }, (_, i) => rim(i / POOL.steps));
  const water = Array.from({ length: POOL.steps }, (_, i) => edge(i / POOL.steps));
  return { rim, steps: POOL.steps, inside: (x, z) => encloses(loop, x, z), inWater: (x, z) => encloses(water, x, z) };
}

/// A pool's own outline as its water's edge and its rim, each walked in
/// `POOL.steps` points that pair off one to one: the edge resampled evenly
/// along its length, and each of its points pushed out by the lip. Read by how
/// far round, as `ringAt`'s loops are.
function laidOut(outline) {
  const along = ringAt(outline, [1, 1], [0, 0]);
  const edge = Array.from({ length: POOL.steps }, (_, i) => along(i / POOL.steps));
  const rim = pushedOut(edge, POOL.lip);
  const at = (loop) => (u) => loop[((Math.round(u * POOL.steps) % POOL.steps) + POOL.steps) % POOL.steps];
  return { edge: at(edge), rim: at(rim) };
}

/// A closed loop pushed out by `by` metres all round, each point along the
/// outward normal there. Which way is out is read off which way the loop runs
/// (its signed area), since a plot's mirror reverses it.
function pushedOut(loop, by) {
  const n = loop.length;
  let twice = 0;
  for (let i = 0; i < n; i++) {
    const a = loop[i], b = loop[(i + 1) % n];
    twice += a[0] * b[1] - b[0] * a[1];
  }
  const out = twice > 0 ? 1 : -1;
  return loop.map((p, i) => {
    const a = loop[(i + n - 1) % n], b = loop[(i + 1) % n];
    const tx = b[0] - a[0], tz = b[1] - a[1], l = Math.hypot(tx, tz) || 1;
    return [p[0] + (out * tz / l) * by, p[1] - (out * tx / l) * by];
  });
}

/// The middle of the area a closed loop holds, for a dish to fall to when the
/// caller has no deeper point to say.
export function middleOf(loop) {
  let twice = 0, cx = 0, cz = 0;
  for (let i = 0, n = loop.length; i < n; i++) {
    const a = loop[i], b = loop[(i + 1) % n];
    const cross = a[0] * b[1] - b[0] * a[1];
    twice += cross;
    cx += (a[0] + b[0]) * cross;
    cz += (a[1] + b[1]) * cross;
  }
  return [cx / (3 * twice), cz / (3 * twice)];
}

/// **A floor round a pool that is not in the middle of the plot.** `rimOf`'s
/// loop and a plot's outline walked together by how far round each is, which
/// is what the Quiet Garden fans between, only tiles the ground between them
/// when both go round the same middle. Off the middle, the two walks drift out
/// of step and their quads fold over one another — and a fold can lay turf
/// across the water. So this walks round the pool instead: each step of its
/// rim, and the plot's edge straight out from the pool's own middle through it,
/// which the edge is always far enough round to answer.
///
/// For a round pool, whose rim is walked evenly by angle. `colour` is a colour
/// or a function of where on the floor, for a floor with its own mottle: a
/// dressing laid over it stops a piece short of the rim, and the floor that
/// shows there has to be the dressing's colour or it draws a halo.
///
/// A pool with its own `outline` (`rimOf`) is walked round that instead; its
/// `at` has to see the whole of it, as a dish falling to it does.
export function floorAround(e, { quad }, outline, { at, across, seed, outline: pool = null }, colour) {
  const tone = typeof colour === 'function' ? colour : () => colour;
  const { rim, steps } = rimOf(e, { at, across, seed, round: true, outline: pool });
  const out = (p) => {
    const dx = p[0] - at[0], dz = p[1] - at[1], l = Math.hypot(dx, dz) || 1;
    const r = rimReach(outline, at, dx / l, dz / l);
    return [at[0] + (dx / l) * r, at[1] + (dz / l) * r];
  };
  for (let i = 0; i < steps; i++) {
    const a = rim(i / steps), b = rim((i + 1) / steps), c = out(b), d = out(a);
    quad([a[0], 0, a[1]], [b[0], 0, b[1]], [c[0], 0, c[1]], [d[0], 0, d[1]], [0, 1, 0],
         tone(...a), tone(...b), tone(...c), tone(...d));
  }
}

/// Whether a point is inside a closed loop: the ray-crossing count, which is
/// the whole of it for a loop this simple. A pool's rim never doubles back on
/// itself — it is a plot's own outline shrunk, and that is convex enough.
function encloses(loop, x, z) {
  let n = loop.length, within = false;
  for (let i = 0, j = n - 1; i < n; j = i++) {
    const a = loop[i], b = loop[j];
    if ((a[1] > z) !== (b[1] > z)
        && x < a[0] + ((z - a[1]) / (b[1] - a[1])) * (b[0] - a[0])) within = !within;
  }
  return within;
}

/// `lining` is what the rim and the dish are made of. Silt by default, which is
/// a pool dug into the ground; stone for water that has been built — a rill's
/// channel, a tank's kerb — where the ground climbs and has to be told where to
/// hold its water.
///
/// `outline` is a pool laid out by hand, as `rimOf` takes it: the water's edge
/// is that loop, and `at` is the deepest water the dish falls to.
export function sinkPool(e, { tri, quad }, {
  at = [0, 0], across, deep = across, seed, lining = COLOUR.silt, round = false, bank = null, outline = null,
}) {
  let edge, rim;
  if (outline) {
    ({ edge, rim } = laidOut(outline));
  } else {
    const grown = shapeOf(e, seed, round);
    edge = ringAt(grown, [across / SIDE, deep / SIDE], at);
    rim = ringAt(grown, [(across + 2 * POOL.lip) / SIDE, (deep + 2 * POOL.lip) / SIDE], at);
  }

  // The rim: bare wet earth between the floor and the water, lying a whisker
  // over whatever the floor has drawn on it.
  for (let i = 0; i < POOL.steps; i++) {
    const u = i / POOL.steps, v = (i + 1) / POOL.steps;
    const a = rim(u), b = rim(v), c = edge(v), d = edge(u);
    quad([a[0], POOL.over, a[1]], [b[0], POOL.over, b[1]],
         [c[0], POOL.over, c[1]], [d[0], POOL.over, d[1]],
         [0, 1, 0], lining);
  }

  // **A bank, for a pool too big to fall to its middle** (the Cold Frame's
  // tank, 29 September 2026). The dish below falls from its rim to one point
  // in the middle, so the water, lying a little under the rim, meets it a
  // fixed share of the way in — a fifth — and a pool three metres across
  // showed a third of a metre of wet silt all round, its lilies sitting on
  // it. With `bank`, the dish falls to its floor within that many metres of
  // the edge instead, and the water reaches to within a few centimetres of
  // the rim whatever the pool's size. The floor under it is not drawn: the
  // water is opaque. The pools that do not ask for one are as they were.
  if (bank) {
    const inner = (p) => {
      const dx = p[0] - at[0], dz = p[1] - at[1], l = Math.hypot(dx, dz) || 1;
      const k = Math.max(0, (l - bank) / l);
      return [at[0] + dx * k, at[1] + dz * k];
    };
    const slope = Math.hypot(bank, POOL.deep);
    for (let i = 0; i < POOL.steps; i++) {
      const u = i / POOL.steps, v = (i + 1) / POOL.steps;
      const a = edge(u), b = edge(v), c = inner(b), d = inner(a);
      const mx = (a[0] + b[0]) / 2 - at[0], mz = (a[1] + b[1]) / 2 - at[1], out = Math.hypot(mx, mz) || 1;
      const normal = [(mx / out) * (POOL.deep / slope), bank / slope, (mz / out) * (POOL.deep / slope)];
      quad([a[0], POOL.over, a[1]], [b[0], POOL.over, b[1]],
           [c[0], -POOL.deep, c[1]], [d[0], -POOL.deep, d[1]], normal, lining);
    }
  }

  // The dish: the water's edge falling away to a floor, in silt. Its own
  // middle is a point, so it is a fan and not a ring — a pool this size has no
  // flat bottom worth the triangles.
  for (let i = 0; bank === null && i < POOL.steps; i++) {
    const u = i / POOL.steps, v = (i + 1) / POOL.steps;
    const a = edge(u), b = edge(v);
    const normal = fall(a, b, at);
    tri([a[0], POOL.over, a[1]], [b[0], POOL.over, b[1]], [at[0], -POOL.deep, at[1]],
        normal, lining);
  }

  // The water: a fan at its own level, dark over the middle and lighter at the
  // rim where the dish is close under it. Opaque — this garden lights flat and
  // has no reflections to give, so still water is a colour and not a window,
  // and a translucent surface would only show the silt it is meant to be over.
  for (let i = 0; i < POOL.steps; i++) {
    const u = i / POOL.steps, v = (i + 1) / POOL.steps;
    const a = edge(u), b = edge(v);
    tri([at[0], -POOL.surface, at[1]], [a[0], -POOL.surface, a[1]], [b[0], -POOL.surface, b[1]],
        [0, 1, 0], COLOUR.depths, COLOUR.shallows, COLOUR.shallows);
  }
}

// MARK: - Contained water, for the ground that climbs

export const TROUGH = {
  // How thick the stone is, how high it stands off the floor, and how far
  // below its top the water lies. A trough brimming to the lip reads as a
  // mirror laid on a plinth; a hand's width down reads as held.
  wall: 0.07,
  height: 0.34,
  freeboard: 0.06,
  steps: 72,
};

/// A basin walled in stone, standing on the floor rather than sunk into it.
///
/// **The grading, approved 27 September 2026**: open water at the foot of the
/// garden, where water gathers, and contained water — tanks, troughs, a rill —
/// as the ground climbs, where it has to be carried and held. A pool is the
/// first; this is the second. It stands on whatever the floor has drawn, so
/// nothing has to give way to it, and its walls are what hide the ground
/// inside them.
///
/// Its outline is a plot's, grown at a plot's size and squeezed, the way a
/// pool's is, so its walls wander and nothing about it is ruled. The inside is
/// the same outline squeezed further, which thins the wall a little where the
/// outline wanders in and thickens it where it wanders out, as hewn stone does.
///
/// `tri` and `quad` are the caller's, and a caller that shadows what stands
/// off its floor passes the emitters that cast.
///
/// `base` is the height it stands on, for a floor that is not the plot's own —
/// the Crossing's roundel stands 5 cm proud.
///
/// `round` gives it a round outline instead of a plot's squared one, for a
/// basin standing on round paving. It wanders all the same.
export function raiseTrough(e, { tri, quad }, {
  at = [0, 0], across, deep = across, seed, height = TROUGH.height, base = 0, round = false,
}) {
  const grown = shapeOf(e, seed, round);
  const outer = ringAt(grown, [across / SIDE, deep / SIDE], at);
  const inner = ringAt(grown, [(across - 2 * TROUGH.wall) / SIDE, (deep - 2 * TROUGH.wall) / SIDE], at);
  const lip = base + height, level = lip - TROUGH.freeboard;
  const face = COLOUR.stone, foot = COLOUR.stone.map((c) => c * 0.82);
  const top = COLOUR.stone.map((c) => c * 1.08), within = COLOUR.stone.map((c) => c * 0.7);

  for (let i = 0; i < TROUGH.steps; i++) {
    const u = i / TROUGH.steps, v = (i + 1) / TROUGH.steps;
    const a = outer(u), b = outer(v), ai = inner(u), bi = inner(v);
    const out = away(a, b, at);

    // The outer face, darker at the foot where it meets the ground.
    quad([a[0], base, a[1]], [b[0], base, b[1]], [b[0], lip, b[1]], [a[0], lip, a[1]],
         out, foot, foot, face, face);
    // The lip.
    quad([a[0], lip, a[1]], [b[0], lip, b[1]], [bi[0], lip, bi[1]], [ai[0], lip, ai[1]],
         [0, 1, 0], top);
    // The inner face, down to the water, in its own shadow.
    quad([ai[0], lip, ai[1]], [bi[0], lip, bi[1]], [bi[0], level, bi[1]], [ai[0], level, ai[1]],
         [-out[0], 0, -out[2]], within);
    // The water, lighter at the wall where the stone shows through it.
    tri([at[0], level, at[1]], [ai[0], level, ai[1]], [bi[0], level, bi[1]],
        [0, 1, 0], COLOUR.depths, COLOUR.shallows, COLOUR.shallows);
  }
}

/// The outline water is cut or built to, a plot across: a plot's own, or with
/// `round`, a circle. Both are squeezed to size by `ringAt`.
function shapeOf(e, seed, round) {
  return round ? roundOutline(e, seed) : readOutline(e, SIDE, SIDE, seed);
}

/// A circle a plot across, wandering in and out by a few per cent: hewn, not
/// turned. Walked the way `readOutline`'s loops are, so `ringAt` takes either.
function roundOutline(e, seed, n = 96) {
  const r = SIDE / 2;
  return Array.from({ length: n }, (_, i) => {
    const t = (i / n) * 2 * Math.PI;
    const wander = 1 + 0.025 * (e.pg_verge(t * r, 1, seed) / 0.14);
    return [Math.cos(t) * r * wander, Math.sin(t) * r * wander];
  });
}

export const RILL = {
  // The water's width, the stone either side of it, and how far the stone
  // stands proud of the grass. Low enough to step over, which is what a rill
  // in a walk has to be.
  water: 0.12,
  kerb: 0.05,
  rise: 0.05,
  freeboard: 0.015,
  step: 0.1,
};

/// **A rill: water led along a channel of stone.** The third kind the grading
/// names, for the head of the garden, where water has come the furthest and is
/// carried rather than kept.
///
/// `centre(z)` is where its middle is at each point along its length, from
/// `from` to `to`, so it follows whatever it runs down — a path whose verges
/// were cut by eye gives a rill that was laid by eye. Its water wanders in
/// width as well, a little either side, and its ends are round. Nothing in it
/// is ruled, though a rill is the straightest thing in any garden.
export function raiseRill(e, { tri, quad }, { centre, from, to, seed }) {
  const UP = [0, 1, 0];
  const half = (z, side) => (RILL.water / 2) * (1 + 0.14 * (e.pg_verge(z * 2.3, side, seed) / 0.14));
  const top = RILL.rise, level = RILL.rise - RILL.freeboard;
  const face = COLOUR.stone, foot = COLOUR.stone.map((c) => c * 0.82);
  const lip = COLOUR.stone.map((c) => c * 1.08), within = COLOUR.stone.map((c) => c * 0.7);

  const rows = Math.max(2, Math.round((to - from) / RILL.step));
  const side = [];
  for (let i = 0; i <= rows; i++) {
    const z = from + ((to - from) * i) / rows, c = centre(z);
    const l = c - half(z, -1), r = c + half(z, 1);
    side.push({ z, c, l, r, lo: l - RILL.kerb, ro: r + RILL.kerb });
  }

  for (let i = 0; i < rows; i++) {
    const a = side[i], b = side[i + 1];
    // The water, darker down its middle.
    quad([a.l, level, a.z], [a.c, level, a.z], [b.c, level, b.z], [b.l, level, b.z], UP,
         COLOUR.shallows, COLOUR.depths, COLOUR.depths, COLOUR.shallows);
    quad([a.c, level, a.z], [a.r, level, a.z], [b.r, level, b.z], [b.c, level, b.z], UP,
         COLOUR.depths, COLOUR.shallows, COLOUR.shallows, COLOUR.depths);
    // The two kerbs' tops.
    quad([a.lo, top, a.z], [a.l, top, a.z], [b.l, top, b.z], [b.lo, top, b.z], UP, lip);
    quad([a.r, top, a.z], [a.ro, top, a.z], [b.ro, top, b.z], [b.r, top, b.z], UP, lip);
    // Their outer faces, down to the grass.
    quad([a.lo, 0, a.z], [b.lo, 0, b.z], [b.lo, top, b.z], [a.lo, top, a.z], [-1, 0, 0], foot, foot, face, face);
    quad([a.ro, 0, a.z], [b.ro, 0, b.z], [b.ro, top, b.z], [a.ro, top, a.z], [1, 0, 0], foot, foot, face, face);
    // Their inner faces, down to the water.
    quad([a.l, top, a.z], [b.l, top, b.z], [b.l, level, b.z], [a.l, level, a.z], [1, 0, 0], within);
    quad([a.r, top, a.z], [b.r, top, b.z], [b.r, level, b.z], [a.r, level, a.z], [-1, 0, 0], within);
  }

  // The ends: the channel turned round in a half circle, stone and water both.
  const cap = (end, dir) => {
    const cx = (end.l + end.r) / 2, inner = (end.r - end.l) / 2, outer = inner + RILL.kerb;
    const at = (radius, t) => [cx + radius * Math.cos(t), end.z + dir * radius * Math.sin(t)];
    const k = 12;
    for (let j = 0; j < k; j++) {
      const t0 = (j / k) * Math.PI, t1 = ((j + 1) / k) * Math.PI;
      const i0 = at(inner, t0), i1 = at(inner, t1), o0 = at(outer, t0), o1 = at(outer, t1);
      const out = [Math.cos((t0 + t1) / 2), 0, dir * Math.sin((t0 + t1) / 2)];
      tri([cx, level, end.z], [i0[0], level, i0[1]], [i1[0], level, i1[1]], UP,
          COLOUR.depths, COLOUR.shallows, COLOUR.shallows);
      quad([i0[0], top, i0[1]], [o0[0], top, o0[1]], [o1[0], top, o1[1]], [i1[0], top, i1[1]], UP, lip);
      quad([o0[0], 0, o0[1]], [o1[0], 0, o1[1]], [o1[0], top, o1[1]], [o0[0], top, o0[1]], out,
           foot, foot, face, face);
      quad([i0[0], top, i0[1]], [i1[0], top, i1[1]], [i1[0], level, i1[1]], [i0[0], level, i0[1]],
           [-out[0], 0, -out[2]], within);
    }
  };
  cap(side[0], -1);
  cap(side[rows], 1);
}

/// The height to stand a trough on over a floor that is not level — the
/// Coppice's litter, the Home Ground's beds: a little under the lowest point
/// beneath its outer wall, so it is set into the ground on every side rather
/// than floating off it on one.
export function footing(height, { at, across, deep = across }) {
  let lowest = Infinity;
  for (let k = 0; k < 24; k++) {
    const t = (k / 24) * 2 * Math.PI;
    lowest = Math.min(lowest, height(at[0] + Math.cos(t) * across / 2, at[1] + Math.sin(t) * deep / 2));
  }
  return Math.min(lowest, height(at[0], at[1])) - 0.02;
}

/// The level outward normal of a wall between two points on a loop around `at`.
function away(a, b, at) {
  let nx = b[1] - a[1], nz = -(b[0] - a[0]);
  const len = Math.hypot(nx, nz) || 1;
  nx /= len; nz /= len;
  const mx = (a[0] + b[0]) / 2 - at[0], mz = (a[1] + b[1]) / 2 - at[1];
  return nx * mx + nz * mz < 0 ? [-nx, 0, -nz] : [nx, 0, nz];
}

/// A closed outline read by how far round it you are rather than by which
/// point you are on, so a floor can be fanned between two of them: a pool's
/// rim and a plot's edge have different numbers of points and no index in one
/// means anything in the other.
export function walkRound(outline) {
  return ringAt(outline, [1, 1], [0, 0]);
}

/// A closed outline, scaled about its own middle and moved to `at`, read by
/// how far round it you are rather than by which point you are on — so two
/// loops with different point counts can be walked together.
///
/// `scale` is a pair, because a tank is longer than it is wide and a pool is
/// not: the outline is grown at a plot's size and squeezed to fit, which is
/// what keeps its wander in proportion (see the note at the top).
function ringAt(outline, scale, at) {
  const n = outline.length;
  const run = [0];
  for (let i = 1; i <= n; i++) {
    const p = outline[i % n], q = outline[i - 1];
    run.push(run[i - 1] + Math.hypot(p[0] - q[0], p[1] - q[1]));
  }
  const total = run[n];
  return (u) => {
    const want = ((u % 1) + 1) % 1 * total;
    let i = 1;
    while (i < n && run[i] < want) i++;
    const t = (want - run[i - 1]) / (run[i] - run[i - 1] || 1);
    const a = outline[i - 1], b = outline[i % n];
    return [at[0] + scale[0] * (a[0] + (b[0] - a[0]) * t),
            at[1] + scale[1] * (a[1] + (b[1] - a[1]) * t)];
  };
}

/// The outward normal of a dish's wall between two points on its rim: level
/// along the rim, tipped by how steeply the wall falls to the middle.
function fall(a, b, at) {
  const mx = (a[0] + b[0]) / 2 - at[0], mz = (a[1] + b[1]) / 2 - at[1];
  const out = Math.hypot(mx, mz) || 1;
  const run = Math.hypot(out, POOL.deep);
  return [(mx / out) * (POOL.deep / run), out / run, (mz / out) * (POOL.deep / run)];
}
