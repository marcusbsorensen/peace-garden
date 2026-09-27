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

import { COLOUR, SIDE, readOutline } from './longwalk.js';

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
///
/// One call gives a floor everything it needs, so the outline is read once and
/// the caller passes the same options to `sinkPool`.
export function rimOf(e, { at = [0, 0], across, seed }) {
  const scale = across / SIDE;
  const grown = readOutline(e, SIDE, SIDE, seed);
  const rim = ringAt(grown, scale * (1 + (2 * POOL.lip) / across), at);
  const loop = Array.from({ length: POOL.steps }, (_, i) => rim(i / POOL.steps));
  return { rim, steps: POOL.steps, inside: (x, z) => encloses(loop, x, z) };
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

export function sinkPool(e, { tri, quad }, { at = [0, 0], across, seed }) {
  const scale = across / SIDE;
  const grown = readOutline(e, SIDE, SIDE, seed);
  const edge = ringAt(grown, scale, at);
  const rim = ringAt(grown, scale * (1 + (2 * POOL.lip) / across), at);

  // The rim: bare wet earth between the floor and the water, lying a whisker
  // over whatever the floor has drawn on it.
  for (let i = 0; i < POOL.steps; i++) {
    const u = i / POOL.steps, v = (i + 1) / POOL.steps;
    const a = rim(u), b = rim(v), c = edge(v), d = edge(u);
    quad([a[0], POOL.over, a[1]], [b[0], POOL.over, b[1]],
         [c[0], POOL.over, c[1]], [d[0], POOL.over, d[1]],
         [0, 1, 0], COLOUR.silt);
  }

  // The dish: the water's edge falling away to a floor, in silt. Its own
  // middle is a point, so it is a fan and not a ring — a pool this size has no
  // flat bottom worth the triangles.
  for (let i = 0; i < POOL.steps; i++) {
    const u = i / POOL.steps, v = (i + 1) / POOL.steps;
    const a = edge(u), b = edge(v);
    const normal = fall(a, b, at);
    tri([a[0], POOL.over, a[1]], [b[0], POOL.over, b[1]], [at[0], -POOL.deep, at[1]],
        normal, COLOUR.silt);
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

/// A closed outline read by how far round it you are rather than by which
/// point you are on, so a floor can be fanned between two of them: a pool's
/// rim and a plot's edge have different numbers of points and no index in one
/// means anything in the other.
export function walkRound(outline) {
  return ringAt(outline, 1, [0, 0]);
}

/// A closed outline, scaled about its own middle and moved to `at`, read by
/// how far round it you are rather than by which point you are on — so two
/// loops with different point counts can be walked together.
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
    return [at[0] + scale * (a[0] + (b[0] - a[0]) * t),
            at[1] + scale * (a[1] + (b[1] - a[1]) * t)];
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
