// A plot of the Knot Garden, drawn the way the app draws a plot: a floating
// slab of ground seen in true isometric, gravel all over it, a ring of low
// clipped box round the middle and four rings woven through it inside a
// softened square edging, and a block of one colour standing in each of the
// eight compartments: four lenses where the rings overlap, four crescents
// outside them.
//
// **It is one pattern, so the page shows one plot.** The Long Walk draws three
// end to end because a walk is a length you look down. A knot is not: it is a
// figure you look into from above, and two of them side by side read as neither
// one knot nor two.
//
// **The weave is the whole area, and it is drawn rather than implied.** At each
// of the eight crossings one band carries on through and swells a little, as a
// clipped hedge does where two runs meet, and the other stops square against
// its face and starts again on the far side. Going round the middle ring it is
// over, under, over, under, so every small ring is over at one of its two
// crossings and under at the other. Five rings simply overlapping would be a
// drawing of circles; the alternation is the difference between that and a
// knot.
//
// **Every line is a curve, laid by hand.** Rings, as the research's sketch drew
// them (option A, 2 October 2026): formal, but each strays off its true circle
// by up to a centimetre, as box planted along a string line does, and the
// edging is a squircle rather than a square. The lines are the table's
// (`tables/knot_garden_rings.js`, made offline from
// `tools/layouts/tables/knot_garden_rings.py`), which also says where each
// crossing is and which band rides over there; this file sweeps a run of box
// along each.
//
// It is also how a real knot garden is made. Living hedge cannot be woven, so a
// Tudor knot is planted exactly this way — the under-band interrupted, the
// over-band continuous — and the eye does the rest.
//
// The rule that decides where each plant stands is SeedCore's `KnotGarden`,
// through the module — this file draws the ground and the knot and puts each
// plant on the spot the service gives it. The plot's own numbers come from
// `pg_knot_plan` rather than being written down again here.

import { decode, takeResult } from './plant.js';
import { COLOUR, SIDE, hash, keepToPlot, readOutline } from './longwalk.js';
import { hangSide } from './slab.js';
import { raiseTrough } from './water.js';
import { knotGardenRings } from './tables/knot_garden_rings.js';

// The basin in the middle of the knot. The small rings come no nearer the
// middle than 0.54 m, and a band is 0.09 m either side of its line, which
// leaves 0.45 m clear all round: a basin 0.60 m across stands 15 cm inside
// that.
const BASIN = { across: 0.60, height: 0.08 };

// Seeds for this area's dressing, so a plot is the same shape on every visit.
// Its own, not the walk's, the room's, the crossing's or the orchard's: five
// areas drawing from one seed would be five plots with the same wandering edge,
// which is the sort of thing an eye catches without being able to say why.
const KNOT = { ground: 7417, floor: 31, grain: 53, basin: 691 };

export function plan(e) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_knot_plan())));
}

// MARK: - The ground

export function makeKnotGround(place) {
  return function buildKnotGround(farSide, span, e, eye) {
    const positions = [], normals = [], colours = [];
    const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
    const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
    const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => {
      tri(a, b, c, n, ca, cb, cc); tri(a, c, d, n, ca, cc, cd);
    };
    const UP = [0, 1, 0];

    const outline = readOutline(e, SIDE, SIDE, KNOT.ground);
    const n = outline.length;
    for (let i = 0; i < n; i++) {
      const a = outline[i], b = outline[(i + 1) % n];
      tri([0, 0, 0], [a[0], 0, a[1]], [b[0], 0, b[1]], UP, COLOUR.gravel);
    }

    // **Gravel, and the grain is the whole difficulty.** The other four areas'
    // ground is grass, which is a surface: a tone carried on the corners of a
    // grid and interpolated across it, so no cell edge shows anywhere. Gravel
    // is not a surface, it is a heap of stones, and the same smooth
    // interpolation drew wet sand.
    //
    // So this is the opposite arithmetic: a tone **per triangle**, not per
    // corner, flat across the face, which is what makes each one a chipping
    // catching the light its own way. It is the roundel's finding — paving is
    // faces — at a twentieth of the size.
    //
    // **Too coarse is shingle and too fine is sand**, and the first pass was
    // neither: it was a tiled floor. A square grid of cells, each split on the
    // same diagonal and each flat-toned, draws a checkerboard however small the
    // cells are and however hard the tones vary — the eye finds the grid before
    // it finds the stones, because the grid is the only thing in the picture
    // that repeats exactly.
    //
    // So the lattice is jittered before anything is drawn, by up to a third of
    // a cell, and the diagonal each cell is split on is chosen by the same
    // noise. Nothing is square, nothing is parallel to its neighbour, and there
    // is no line to find. **It is the grid's regularity that had to go, not its
    // size** — the cell is what it was.
    //
    // The grain is set by what a stone comes out as on screen rather than by
    // what a stone is: at a plot this size a centimetre of pea gravel is a
    // fraction of a pixel and dissolves into dither, while a hand's breadth is
    // a beach.
    // **Laid a little wider than the plot and kept to it** (`keepToPlot`), since
    // 25 September 2026: laid inside a 2.54 m square over an edge that comes in
    // to 2.42 m, it ran past the slab with a ruled edge and four corners in the
    // sky. Now it ends on the plot's own wandering edge.
    const half = SIDE / 2 + 0.06;
    const onPlot = keepToPlot(outline);
    const cell = 0.06;
    const steps = Math.ceil((half * 2) / cell);
    const lattice = [];
    for (let i = 0; i <= steps; i++) {
      const row = [];
      for (let j = 0; j <= steps; j++) {
        const edgeOfSheet = i === 0 || j === 0 || i === steps || j === steps;
        const shift = edgeOfSheet ? 0 : cell * 0.34;
        row.push(onPlot(
          Math.max(-half, Math.min(half, -half + i * cell + shift * (hash(i * 7919 + j * 104729) - 0.5) * 2)),
          Math.max(-half, Math.min(half, -half + j * cell + shift * (hash(i * 6733 + j * 92831) - 0.5) * 2)),
        ));
      }
      lattice.push(row);
    }
    // A slow wander under the grain, so a gravel walk is lighter where it is
    // worn and darker where it is not. Without it, several thousand stones of
    // independent tone average out to one flat grey at arm's length.
    const drift = (x, z) => 1
      + 0.07 * (e.pg_verge(x * 0.62, -1, KNOT.ground) / 0.14)
      + 0.06 * (e.pg_verge(z * 0.54, 1, KNOT.ground) / 0.14);
    const stone = (i, j, k, x, z) =>
      COLOUR.gravel.map((v) => v * drift(x, z) * (0.87 + 0.25 * hash(i * 131 + j * 37 + k * 7 + KNOT.grain)));
    const up = (p) => [p[0], 0.003, p[1]];
    for (let i = 0; i < steps; i++) {
      for (let j = 0; j < steps; j++) {
        const a = lattice[i][j], b = lattice[i + 1][j], c = lattice[i + 1][j + 1], d = lattice[i][j + 1];
        // Two triangles, two stones, and the diagonal they are split on turns
        // with the noise: all four corners of a cell are already off the grid,
        // and this is what stops the *splits* lining up into one.
        if (hash(i * 31 + j * 17 + KNOT.grain) < 0.5) {
          tri(up(a), up(b), up(c), UP, stone(i, j, 0, a[0], a[1]));
          tri(up(a), up(c), up(d), UP, stone(i, j, 1, c[0], c[1]));
        } else {
          tri(up(a), up(b), up(d), UP, stone(i, j, 2, a[0], a[1]));
          tri(up(b), up(c), up(d), UP, stone(i, j, 3, c[0], c[1]));
        }
      }
    }

    // **A basin in the empty middle**, which the four small rings close round.
    // The Knot is halfway up the garden, where water is held rather than
    // found, so it is a ring of stone standing on the gravel — low, a band's
    // height and less, so it lies inside the knot rather than standing up out
    // of it. Sunk flush, it read as a drain.
    raiseTrough(e, { tri, quad }, {
      across: BASIN.across, height: BASIN.height, seed: KNOT.basin, round: true,
    });

    // MARK: The knot

    // **What the box throws on the gravel**: every triangle of every run, handed
    // to the stage beside the ground as `casting`, which lays them down from
    // the sun's side. At ankle height that is a hand's width of shade on the
    // side away from the light, which is what sits a band in the gravel rather
    // than on it.
    const casting = [];
    const cast = (p, nn, c) => { vertex(p, nn, c); casting.push(...p); };
    for (const run of knotRuns(place)) sweepHedge(run, place, cast);

    // Its side: the slab every plot hangs from its outline (`slab.js`), the
    // floor seed saying how its lower edge undulates.
    const slab = hangSide(outline, { salt: KNOT.floor });

    return {
      positions: new Float32Array(positions),
      normals: new Float32Array(normals),
      colours: new Float32Array(colours),
      side: slab,
      casting: new Float32Array(casting),
    };
  };
}

// MARK: - The runs of box

/// **The knot as runs of box to sweep**: each one a line of points, closed or
/// open, and how it is to swell. Read off the table: the middle ring, the four
/// small rings and the edging as laid, and the eight crossings with which band
/// rides over at each (`KnotGarden.over(at:)`: the middle ring at the even
/// ones, the small ring at the odd).
///
/// - **An under-band is cut**: it stops where its line comes within
///   `bandHalfThickness − tuck` of the over-band's line, which is its end
///   hidden that far inside the over-band's face, and starts again on the far
///   side. So the middle ring is four runs and each small ring one, open.
/// - **An over-band swells** at each crossing it rides: a short run along it,
///   thicker and taller at the crossing and easing back to the band's own size
///   `swellReach` along either way, so it merges with the band it lies on.
/// - The edging is whole.
export function knotRuns(place, table = knotGardenRings) {
  const line = (name) => table.curves[name][0].points;
  const bands = ['middle', 'ring0', 'ring1', 'ring2', 'ring3'].map(line);
  const crossings = line('crossings');
  const overAt = (i) => (i % 2 === 0 ? 0 : 1 + (i >> 1));
  const underAt = (i) => (i % 2 === 0 ? 1 + (i >> 1) : 0);
  const reach = place.bandHalfThickness - place.tuck;

  const runs = [];
  bands.forEach((points, b) => {
    // Where this band dives under: the crossings it is the under-band at.
    const dives = crossings.map((c, i) => ({ c, over: bands[overAt(i)] }))
      .filter((_, i) => underAt(i) === b);
    const n = points.length;
    // A point of the band is cut away if it is near one of its dives and
    // within `reach` of the band riding over there.
    const cut = points.map((p) => dives.some(({ c, over }) =>
      Math.hypot(p[0] - c[0], p[1] - c[1]) < 0.5 && distanceTo(p, over) < reach));
    if (!cut.some(Boolean)) {
      runs.push({ points, closed: true, kind: 'band' });
      return;
    }
    // The runs between the cuts, starting just after one, each ended exactly
    // where its line reaches `reach` from the band over it.
    const start = cut.findIndex((c, i) => c && !cut[(i + 1) % n]);
    let run = null;
    for (let k = 1; k <= n; k++) {
      const i = (start + k) % n;
      const before = (i - 1 + n) % n;
      if (!cut[i] && cut[before]) {
        run = [edge(points[before], points[i], dives, reach)];
      }
      if (!cut[i]) run?.push(points[i]);
      if (cut[i] && run && !cut[before]) {
        run.push(edge(points[i], points[before], dives, reach));
        runs.push({ points: run, closed: false, kind: 'band' });
        run = null;
      }
    }
  });

  // The swellings, along the band that rides over at each crossing.
  crossings.forEach((c, i) => {
    const over = bands[overAt(i)];
    const n = over.length;
    let at = 0;
    for (let k = 1; k < n; k++) {
      if (Math.hypot(over[k][0] - c[0], over[k][1] - c[1]) < Math.hypot(over[at][0] - c[0], over[at][1] - c[1])) at = k;
    }
    // The stretch of it either side of the crossing that is within reach.
    const near = (k) => {
      const p = over[((k % n) + n) % n];
      return Math.hypot(p[0] - c[0], p[1] - c[1]) <= place.swellReach;
    };
    let from = at;
    while (near(from - 1) && at - from < n) from -= 1;
    const points = [];
    for (let k = from; near(k) && k - from < n; k++) points.push(over[((k % n) + n) % n]);
    runs.push({ points, closed: false, kind: 'swell', at: c });
  });

  runs.push({ points: line('edging'), closed: true, kind: 'band' });
  return runs;
}

/// How far a point is from the nearest part of a closed line.
function distanceTo(p, points) {
  let best = Infinity;
  for (let i = 0, n = points.length; i < n; i++) {
    const a = points[i], b = points[(i + 1) % n];
    const dx = b[0] - a[0], dz = b[1] - a[1];
    const m = dx * dx + dz * dz;
    const t = m === 0 ? 0 : Math.min(1, Math.max(0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dz) / m));
    best = Math.min(best, Math.hypot(p[0] - a[0] - dx * t, p[1] - a[1] - dz * t));
  }
  return best;
}

/// The point between `inside` (cut away) and `outside` (kept) where the line
/// is exactly `reach` from the band riding over it: halved down to a
/// millimetre, so the cut end stands where the rule says rather than wherever
/// the nearest of the table's points happened to fall.
function edge(inside, outside, dives, reach) {
  const away = (p) => Math.min(...dives.map(({ over }) => distanceTo(p, over)));
  let a = inside, b = outside;
  for (let k = 0; k < 8; k++) {
    const m = [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2];
    if (away(m) < reach) a = m; else b = m;
  }
  return b;
}

/// A run of clipped box swept along a line: soft-shouldered, its top an
/// undulating line and its faces bulging a little where it has grown, as
/// `Organic.hedge` draws a straight one, and of the same section. Closed
/// runs meet themselves with no seam; open ones end square, because every end
/// is buried inside the band it dives under.
///
/// The section turns with the line, so a ring keeps its thickness all the way
/// round. A swelling (`kind: 'swell'`) is the same section grown thicker and
/// taller toward the crossing it sits on.
function sweepHedge(run, place, emit) {
  const { points, closed } = run;
  const n = points.length;
  if (n < 2) return;
  const half = place.bandHalfThickness, high = place.bandHeight;
  const AROUND = 14;
  // Distance along the run, for the noise to wander by.
  const along = [0];
  for (let i = 1; i < n; i++) {
    along.push(along[i - 1] + Math.hypot(points[i][0] - points[i - 1][0], points[i][1] - points[i - 1][1]));
  }
  const total = along[n - 1] + (closed ? Math.hypot(points[0][0] - points[n - 1][0], points[0][1] - points[n - 1][1]) : 0);
  const seed = Math.round((points[0][0] * 131 + points[0][1] * 71) * 100);
  // Smooth value noise along the run, which on a closed run comes round to
  // where it began.
  const cells = closed ? Math.max(3, Math.round(total / 0.35)) : 0;
  const noise = (s, salt) => {
    const t = closed ? (s / total) * cells : s / 0.35;
    const i = Math.floor(t), f = t - i, w = f * f * (3 - 2 * f);
    const at = (k) => hash(((closed ? ((k % cells) + cells) % cells : k) * 7.31) + seed * 0.013 + salt) * 2 - 1;
    return at(i) + (at(i + 1) - at(i)) * w;
  };

  const rings = points.map((p, i) => {
    const a = closed ? points[(i - 1 + n) % n] : points[Math.max(0, i - 1)];
    const b = closed ? points[(i + 1) % n] : points[Math.min(n - 1, i + 1)];
    const tx = b[0] - a[0], tz = b[1] - a[1];
    const l = Math.hypot(tx, tz) || 1;
    // The side the section's first face is on: the line's direction turned
    // a quarter back, as `Organic.hedge` has x+ beside a run along z+.
    const sx = tz / l, sz = -tx / l;
    let grow = 0;
    if (run.kind === 'swell') {
      const d = Math.hypot(p[0] - run.at[0], p[1] - run.at[1]) / place.swellReach;
      grow = d >= 1 ? 0 : (1 - d * d) * (1 - d * d);
    }
    const width = half + place.swellThicker * grow;
    const top = (high + place.swellTaller * grow) * (1 + 0.08 * noise(along[i], 3.1));
    const out = [];
    for (let k = 0; k <= AROUND; k++) {
      const [ox, oy, nx, ny] = section(k / AROUND, width, top);
      const bump = 1 + 0.035 * noise(along[i] * 2.7 + k * 0.9, 7.7) / Math.max(width, 0.05);
      const across = ox * (oy === 0 ? 1 : bump);
      const y = oy === 0 ? 0 : oy * (1 + 0.02 * noise(along[i] * 3.3, 5.3));
      out.push({
        p: [p[0] + sx * across, y, p[1] + sz * across],
        n: [sx * nx, ny, sz * nx],
      });
    }
    return out;
  });

  const tone = (q) => COLOUR.box.map((c) => c * (0.9 + 0.2 * hash(Math.round(q[0] * 41) * 131
    + Math.round(q[2] * 41) + Math.round(q[1] * 67))));
  const spans = closed ? n : n - 1;
  for (let i = 0; i < spans; i++) {
    const r0 = rings[i], r1 = rings[(i + 1) % n];
    for (let k = 0; k < AROUND; k++) {
      const a = r0[k], b = r0[k + 1], c = r1[k], d = r1[k + 1];
      // Wound so the faces point outward, as `Organic.hedge`'s are.
      for (const v of [a, b, c, b, d, c]) emit(v.p, v.n, tone(v.p));
    }
  }
}

/// `Organic.section`: a point round a hedge's cross-section, `t` running from
/// the ground on one face, up, round the shoulder, across the top, and down to
/// the ground on the other; and the outward normal there. [x, y, nx, ny].
function section(t, halfWidth, height) {
  const shoulder = Math.min(halfWidth * 0.8, height * 0.4);
  const side = height - shoulder;
  const across = 2 * (halfWidth - shoulder);
  const arc = Math.PI / 2 * shoulder;
  const total = 2 * side + 2 * arc + across;
  let p = t * total;
  if (p <= side) return [halfWidth, p, 1, 0];
  p -= side;
  if (p <= arc) {
    const a = p / shoulder, c = Math.cos(a), s = Math.sin(a);
    return [halfWidth - shoulder + shoulder * c, side + shoulder * s, c, s];
  }
  p -= arc;
  if (p <= across) return [halfWidth - shoulder - p, height, 0, 1];
  p -= across;
  if (p <= arc) {
    const a = p / shoulder, c = Math.cos(a), s = Math.sin(a);
    return [-(halfWidth - shoulder) - shoulder * s, side + shoulder * c, -s, c];
  }
  p -= arc;
  return [-halfWidth, Math.max(0, side - p), -1, 0];
}

// MARK: - Growing a plot

// **Letting go of the thread** between plants, the way the other four do:
// thirty-two is the most any area holds, and the module still builds a mesh a
// plant, so a page that cannot answer a finger while it does is a page that
// looks broken.
const SLICE = 16;
const breathe = () => new Promise((resume) => setTimeout(resume, 0));

// Grows one plot from the plot service. A planting with no parents was minted
// rather than crossed — the ambassador in the north-east lens — and grows
// from its seed alone.
export async function growKnotFromService(e, stage, plot, report) {
  stage.clear();
  const { plantings } = await (await fetch(`/api/knot/plot/${plot}`)).json();
  let since = performance.now();
  for (const [i, p] of plantings.entries()) {
    const lineage = p.parents ?? [];
    const words = new TextEncoder().encode(
      lineage.length === 2 ? [p.seed, ...lineage, p.encounter].join(' ') : p.seed,
    );
    const pointer = e.pg_alloc(words.length);
    new Uint8Array(e.memory.buffer, pointer, words.length).set(words);
    const length = lineage.length === 2
      ? e.pg_grow_hybrid(pointer, words.length)
      : e.pg_grow(pointer, words.length);
    e.pg_free(pointer);
    if (length === 0) continue;
    stage.add(p.spot[0], p.spot[1], decode(takeResult(e, length)), 0, { ...p, plot });
    if (performance.now() - since > SLICE) {
      report(`Growing: ${i + 1} of ${plantings.length}`);
      stage.draw();
      await breathe();
      since = performance.now();
    }
  }
  stage.draw();
  return plantings.length;
}

// The workbench's version: a Knot Garden the module invents, for judging the
// template before anybody has planted anything in it.
export async function plantVisitors(e, total, report) {
  let arrived = 0;
  let since = performance.now();
  while (arrived < total) {
    e.pg_knot_arrive();
    arrived += 1;
    if (performance.now() - since > SLICE) {
      report(`Planting by the rule: ${arrived} of ${total} arrived`);
      await breathe();
      since = performance.now();
    }
  }
  return e.pg_knot_plots();
}

export async function growInvented(e, stage, plot, report) {
  stage.clear();
  const count = e.pg_knot_count(plot);
  let since = performance.now();
  for (let i = 0; i < count; i++) {
    const length = e.pg_knot_grow(plot, i);
    const buffer = takeResult(e, length);
    const spot = new Float32Array(buffer.slice(0, 8));
    stage.add(spot[0], spot[1], decode(buffer.slice(8)));
    if (performance.now() - since > SLICE) {
      report(`Growing: ${i + 1} of ${count}`);
      stage.draw();
      await breathe();
      since = performance.now();
    }
  }
  stage.draw();
  return count;
}

export function describeKnot(e, plot) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_knot_describe(plot))));
}
