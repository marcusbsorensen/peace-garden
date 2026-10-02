// A plot of the Crossing, drawn the way the app draws a plot: a floating slab
// of ground seen in true isometric, grass all over it, four mown paths turning
// in to a round of paving, and the planting standing in the rough grass of the
// four quarters between them.
//
// **Four ways turning in, since 2 October 2026** (Marcus; `Crossing.swift`
// says why). The paths come in from the middles of the sides and all turn the
// same way to meet the round, narrowing as they go, so the quarters between
// them are commas wrapped round the basin. Their centre lines are the table's
// (`tables/crossing_ways.js`), turned and mirrored by the plot's number as the
// plants are (`variantFromModule`); a mirror sets them turning the other way.
//
// **It is one place, so the page shows one plot.** The Long Walk draws three
// end to end because a walk is a length you look down. A crossing is not: it is
// somewhere you arrive at, and four paths meeting is the whole of what there is
// to see.
//
// The rule that decides where each plant stands is SeedCore's `Crossing`,
// through the module — this file draws the ground and puts each plant on the
// spot the service gives it. The plot's own numbers come from `pg_cross_plan`
// rather than being written down again here.

import { raiseTrough } from './water.js';
import { decode, takeResult } from './plant.js';
import { COLOUR, SIDE, keepToPlot, readOutline, readStructure } from './longwalk.js';
import { hangSide } from './slab.js';
import { PLAIN, applyVariantToCurve, variantFromModule } from './variant.js';
import { crossingWays } from './tables/crossing_ways.js';

// Seeds for this area's dressing, so a plot is the same shape on every visit.
// Its own, not the walk's or the room's: three areas drawing from one seed
// would be three plots with the same wandering edge, which is the sort of thing
// an eye catches without being able to say why.
const CROSS = { ground: 5107, floor: 23, roundel: 61, rough: 71, mow: [37, 41, 43, 47], basin: 83 };

export function plan(e) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_cross_plan())));
}

// MARK: - The ground

export function makeCrossGround(place) {
  // Which way round the plot is laid: the plot's, set by whoever grows it
  // (`growCrossFromService`, `growInvented`) before the stage is rebuilt.
  place.variant ??= PLAIN;
  return function buildCrossGround(farSide, span, e, eye) {
    const positions = [], normals = [], colours = [];
    const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
    const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
    const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => {
      tri(a, b, c, n, ca, cb, cc); tri(a, c, d, n, ca, cc, cd);
    };
    const UP = [0, 1, 0];

    // **The slab's top is grass, and the paths are mown through it.** It was
    // bare soil until Marcus looked at it: four brown quarters with one plant
    // standing in them read as a plot waiting to be planted rather than as a
    // garden. Grass all over, cut short where you walk and left rough where you
    // do not, is what a quadripartite garden of this kind actually is — and it
    // means the quarters need no edges drawn at all, because a mown path's own
    // edge is the only boundary there is.
    const outline = readOutline(e, SIDE, SIDE, CROSS.ground);
    const n = outline.length;
    for (let i = 0; i < n; i++) {
      const a = outline[i], b = outline[(i + 1) % n];
      tri([0, 0, 0], [a[0], 0, a[1]], [b[0], 0, b[1]], UP, COLOUR.turf);
    }

    // **Rough grass, mottled.** One flat green over four quarters is a snooker
    // table. These are quads carrying a tone at each corner rather than over
    // each face, so neighbours share their corners and the shading runs
    // continuous — no cell edge anywhere, which is the whole point of not
    // drawing the quarters as shapes.
    //
    // **Laid on the outline, not on a square**, as the Orchard's meadow is
    // since 25 September 2026: a grid 2.54 m either way over an edge that comes
    // in to 2.42 m ran past the slab with a ruled edge and four corners in the
    // sky. Rings drawn in from the outline itself end where the ground does.
    const cell = 0.26;
    const rings = Math.ceil(SIDE / 2 / cell);
    // Darker than the turf it is drawn from, and varying hard. Grass left long
    // is both: it takes less light than a cut sward and it is uneven, and the
    // two together are the whole difference between a lawn and a meadow. 0.9
    // also buys the mown paths their contrast — `COLOUR.grass` is a fifth
    // brighter than `COLOUR.turf` to begin with, so against this the cut runs
    // read as a third brighter, which is what a path through grass looks like
    // from above.
    const rough = (x, z) => COLOUR.turf.map((v) => v * 0.9 * (1
      + 0.13 * (e.pg_verge(x * 1.31, -1, CROSS.rough) / 0.14)
      + 0.11 * (e.pg_verge(z * 1.07, 1, CROSS.rough) / 0.14)));
    const inward = (p, k) => [p[0] * (k / rings), p[1] * (k / rings)];
    for (let i = 0; i < n; i++) {
      const a = outline[i], b = outline[(i + 1) % n];
      for (let k = 0; k < rings; k++) {
        const [a0, a1, b0, b1] = [inward(a, k), inward(a, k + 1), inward(b, k), inward(b, k + 1)];
        quad([a0[0], 0.003, a0[1]], [a1[0], 0.003, a1[1]], [b1[0], 0.003, b1[1]], [b0[0], 0.003, b0[1]], UP,
             rough(...a0), rough(...a1), rough(...b1), rough(...b0));
      }
    }

    // **The four paths, mown, turning in.** Each is a run of stripes across
    // its own width, alternating because a mower goes up and back, with both
    // long edges wandering because the mower was steered by eye. Against the
    // rough grass either side they are the lighter, tidier thing, which is how
    // a path through grass reads from above. Each follows its centre line from
    // the table and narrows from `pathHalfWidth` where it comes onto the plot
    // to `pathHalfWidthAtRound` where it meets the paving.
    //
    // **Each path runs to the plot's edge and stops on it**: every corner of
    // every piece is kept to the plot, so its end follows the edge's wander
    // rather than cutting a chord.
    const keep = keepToPlot(outline);
    const halfAt = (r) => {
      const t = Math.min(1, Math.max(0, (r - place.roundelRadius) / (SIDE / 2 - place.roundelRadius)));
      return place.pathHalfWidthAtRound
        + (place.pathHalfWidth - place.pathHalfWidthAtRound) * t * t * (3 - 2 * t);
    };
    // 0.05 m of wander, scaled off `pg_verge`'s own range, as the room's
    // mowing does.
    const wander = (along, side, seed) => 0.05 * (e.pg_verge(along * 1.7, side, seed) / 0.14);
    const stripe = 0.42;
    const step = 0.06;
    const pieces = 4;
    for (let q = 0; q < 4; q++) {
      const line = applyVariantToCurve(place.variant, crossingWays.curves[`way${q}`][0].points);
      // Walked from the outside in, a step at a time by length.
      const run = [0];
      for (let i = 1; i < line.length; i++) {
        run.push(run[i - 1] + Math.hypot(line[i][0] - line[i - 1][0], line[i][1] - line[i - 1][1]));
      }
      const total = run[run.length - 1];
      const at = (s) => {
        let i = 1;
        while (i < line.length - 1 && run[i] < s) i++;
        const t = (s - run[i - 1]) / (run[i] - run[i - 1] || 1);
        const a = line[i - 1], b = line[i];
        const dx = b[0] - a[0], dz = b[1] - a[1], l = Math.hypot(dx, dz) || 1;
        return { x: a[0] + dx * t, z: a[1] + dz * t, nx: -dz / l, nz: dx / l };
      };
      const seed = CROSS.mow[q];
      const rows = Math.ceil(total / step);
      for (let r = 0; r < rows; r++) {
        const s0 = r * step, s1 = Math.min(total, (r + 1) * step);
        const a = at(s0), b = at(s1);
        const tone = Math.floor(((s0 + s1) / 2) / stripe) % 2;
        const c = COLOUR.grass.map((v) => v * (tone ? 1.05 : 0.95));
        // Each side of the path at each end of this piece, wandering along
        // the path's own length.
        const side = (p, s, sign) => {
          const half = halfAt(Math.hypot(p.x, p.z)) + wander(s, sign, seed);
          return [p.x + p.nx * half * sign, p.z + p.nz * half * sign];
        };
        const a0 = side(a, s0, -1), a1 = side(a, s0, 1), b0 = side(b, s1, -1), b1 = side(b, s1, 1);
        const mix = (p, q2, u) => [p[0] + (q2[0] - p[0]) * u, p[1] + (q2[1] - p[1]) * u];
        const lift = (p) => { const [x, z] = keep(p[0], p[1]); return [x, 0.005, z]; };
        for (let k = 0; k < pieces; k++) {
          const u0 = k / pieces, u1 = (k + 1) / pieces;
          quad(lift(mix(a0, a1, u0)), lift(mix(a0, a1, u1)), lift(mix(b0, b1, u1)), lift(mix(b0, b1, u0)), UP, c);
        }
      }
    }

    // **The paving where they cross**, which is the first structure in this
    // garden that is neither hedge nor bench. It stands proud of the ground
    // rather than flush with it, and its own rim is what makes it read as laid.
    const roundel = readStructure(
      takeResult(e, e.pg_roundel(place.roundelRadius, 0.05, CROSS.roundel)));
    // **Flat, and a stone at a time.** Smoothed across, with one tone over the
    // whole disc, it was a lid: a polished object dropped into a garden. Paving
    // is faces — each stone catching the light its own way, each a slightly
    // different grey, with a joint you can see between them. So the roundel is
    // the one thing on this page shaded flat: one normal and one tone a
    // triangle, both taken from where the triangle actually is.
    for (let t = 0; t < roundel.indices.length; t += 3) {
      const corner = [0, 1, 2].map((k) => {
        const v = roundel.indices[t + k];
        return [roundel.positions[v * 3], roundel.positions[v * 3 + 1], roundel.positions[v * 3 + 2]];
      });
      const u = [0, 1, 2].map((i) => corner[1][i] - corner[0][i]);
      const w = [0, 1, 2].map((i) => corner[2][i] - corner[0][i]);
      const face = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]];
      const length = Math.hypot(face[0], face[1], face[2]) || 1;
      const nn = [face[0] / length, face[1] / length, face[2] / length];
      // Which stone this face belongs to: courses laid across the roundel, and
      // stones along each course, offset by the course so the joints do not
      // line up into a grid. Both read off the middle of the face, so one
      // stone comes out one tone.
      const mx = (corner[0][0] + corner[1][0] + corner[2][0]) / 3;
      const mz = (corner[0][2] + corner[1][2] + corner[2][2]) / 3;
      const course = Math.floor((mx * 0.71 + mz * 0.71) / 0.115);
      const stone = Math.floor((mz * 0.71 - mx * 0.71) / 0.145 + course * 0.41);
      const grain = Math.abs(Math.sin(course * 12.9898 + stone * 78.233) * 43758.5453) % 1;
      const tone = 0.90 + 0.17 * grain;
      for (const p of corner) vertex(p, nn, COLOUR.stone.map((c) => c * tone));
    }

    // **A basin where the four paths meet.** The Crossing is at the head of
    // the garden, where water has to be carried and held rather than found, so
    // it is contained: a stone basin standing on the paving, not a pool sunk in
    // it. See `raiseTrough`.
    raiseTrough(e, { tri, quad }, {
      at: [0, 0], across: place.roundelRadius * 1.15, seed: CROSS.basin, base: 0.05, round: true, height: 0.2,
    });

    // Its side: the slab every plot hangs from its outline (`slab.js`), the
    // floor seed saying how its lower edge undulates.
    const slab = hangSide(outline, { salt: CROSS.floor });

    return {
      positions: new Float32Array(positions),
      normals: new Float32Array(normals),
      colours: new Float32Array(colours),
      side: slab,
    };
  };
}

// MARK: - Growing a plot

// **Letting go of the thread** between plants, the way the walk and the room
// do: twenty-four is quick, but the module still builds a mesh a plant, and a
// page that cannot answer a finger while it does is a page that looks broken.
const SLICE = 16;
const breathe = () => new Promise((resume) => setTimeout(resume, 0));

// Grows one plot from the plot service. A planting with no parents was minted
// rather than crossed — the ambassador, in the first quarter's middle rank since 28 September 2026 — and
// grows from its seed alone.
export async function growCrossFromService(e, stage, plot, report, place = null) {
  stage.clear();
  const { plantings } = await (await fetch(`/api/cross/plot/${plot}`)).json();
  // The paths laid as this plot's number says, before anything is set by them.
  if (place) {
    place.variant = variantFromModule(e, 'meeting', plot) ?? PLAIN;
    stage.rebuild();
  }
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

// The workbench's version: a Crossing the module invents, for judging the
// template before anybody has planted anything in it.
export async function plantVisitors(e, total, report) {
  let arrived = 0;
  let since = performance.now();
  while (arrived < total) {
    e.pg_cross_arrive();
    arrived += 1;
    if (performance.now() - since > SLICE) {
      report(`Planting by the rule: ${arrived} of ${total} arrived`);
      await breathe();
      since = performance.now();
    }
  }
  return e.pg_cross_plots();
}

export async function growInvented(e, stage, plot, report, place = null) {
  stage.clear();
  const count = e.pg_cross_count(plot);
  if (place) {
    place.variant = variantFromModule(e, 'meeting', plot) ?? PLAIN;
    stage.rebuild();
  }
  let since = performance.now();
  for (let i = 0; i < count; i++) {
    const length = e.pg_cross_grow(plot, i);
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

export function describeCross(e, plot) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_cross_describe(plot))));
}
