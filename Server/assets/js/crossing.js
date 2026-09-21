// A plot of the Crossing, drawn the way the app draws a plot: a floating slab
// of ground seen in true isometric, two mown paths crossing at a round of
// paving, and a bed in each of the four quarters.
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

import { decode, takeResult } from './plant.js';
import { COLOUR, RIM_DEPTH, SIDE, readOutline, readStructure } from './longwalk.js';

// Seeds for this area's dressing, so a plot is the same shape on every visit.
// Its own, not the walk's or the room's: three areas drawing from one seed
// would be three plots with the same wandering edge, which is the sort of thing
// an eye catches without being able to say why.
const CROSS = { ground: 5107, floor: 23, roundel: 61, mow: [37, 41] };

export function plan(e) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_cross_plan())));
}

// MARK: - The ground

export function makeCrossGround(place) {
  return function buildCrossGround(farSide, span, e, eye) {
    const positions = [], normals = [], colours = [];
    const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
    const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
    const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => {
      tri(a, b, c, n, ca, cb, cc); tri(a, c, d, n, ca, cc, cd);
    };
    const UP = [0, 1, 0];

    // **The slab's top is soil, and the paths are laid over it.** The other way
    // round — grass everywhere with four beds cut into it — would mean drawing
    // four L-shaped holes with two wandering edges each. A quadripartite garden
    // is beds with paths through them, so drawing it that way round is both
    // simpler and truer.
    const outline = readOutline(e, SIDE, SIDE, CROSS.ground);
    const n = outline.length;
    for (let i = 0; i < n; i++) {
      const a = outline[i], b = outline[(i + 1) % n];
      tri([0, 0, 0], [a[0], 0, a[1]], [b[0], 0, b[1]], UP, COLOUR.humus);
    }

    // **The two paths, mown and crossing.** Each is a run of stripes across its
    // own width, alternating because a mower goes up and back, with both long
    // edges wandering because a bed's edge was dug rather than drawn. The walk's
    // path is the same path; this one is simply crossed by another.
    const half = SIDE / 2 - 0.06;
    const wide = place.pathHalfWidth;
    const stripe = 0.42;
    const rows = Math.ceil(SIDE / stripe) + 1;
    // 0.05 m of wander, scaled off `pg_verge`'s own range, as the room's mowing
    // does.
    const wander = (along, side, seed) => 0.05 * (e.pg_verge(along * 1.7, side, seed) / 0.14);

    for (const [axis, seed] of [[0, CROSS.mow[0]], [1, CROSS.mow[1]]]) {
      for (let r = 0; r < rows; r++) {
        const a0 = -SIDE / 2 + r * stripe;
        if (a0 >= SIDE / 2) break;
        const a1 = Math.min(SIDE / 2, a0 + stripe);
        if (a0 < -half || a1 > half) continue;
        const c = COLOUR.grass.map((v) => v * (r % 2 ? 1.05 : 0.95));
        // The near and far edges of this stripe, each wandering along the
        // path's own length.
        const lo0 = -wide + wander(a0, -1, seed), lo1 = -wide + wander(a1, -1, seed);
        const hi0 = wide + wander(a0, 1, seed), hi1 = wide + wander(a1, 1, seed);
        const at = (along, across) => (axis === 0
          ? [across, 0.005, along]
          : [along, 0.005, across]);
        quad(at(a0, lo0), at(a0, hi0), at(a1, hi1), at(a1, lo1), UP, c);
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

    // Its sides hang from the outline down to a floor as rough as a clod's, in
    // the app's strata. The walk's arithmetic, because it is the same slab.
    const strata = [[0, COLOUR.humus], [0.16, COLOUR.earth], [0.58, COLOUR.earth], [1, COLOUR.bedrock]];
    let around = 0;
    const floor = outline.map((p, i) => {
      if (i > 0) around += Math.hypot(p[0] - outline[i - 1][0], p[1] - outline[i - 1][1]);
      return RIM_DEPTH * (1 + 0.22 * (e.pg_verge(around, 1, CROSS.floor) / 0.14));
    });
    for (let i = 0; i < n; i++) {
      const j = (i + 1) % n, a = outline[i], b = outline[j];
      const dx = b[0] - a[0], dz = b[1] - a[1], l = Math.hypot(dx, dz);
      const normal = [dz / l, 0, -dx / l];
      for (let k = 0; k < strata.length - 1; k++) {
        const [f0, c0] = strata[k], [f1, c1] = strata[k + 1];
        quad([a[0], -f0 * floor[i], a[1]], [b[0], -f0 * floor[j], b[1]],
             [b[0], -f1 * floor[j], b[1]], [a[0], -f1 * floor[i], a[1]], normal, c0, c0, c1, c1);
      }
    }

    return {
      positions: new Float32Array(positions),
      normals: new Float32Array(normals),
      colours: new Float32Array(colours),
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
// rather than crossed — the ambassador on the first quarter's diagonal — and
// grows from its seed alone.
export async function growCrossFromService(e, stage, plot, report) {
  stage.clear();
  const { plantings } = await (await fetch(`/api/cross/plot/${plot}`)).json();
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
    stage.add(p.spot[0], p.spot[1], decode(takeResult(e, length)));
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

export async function growInvented(e, stage, plot, report) {
  stage.clear();
  const count = e.pg_cross_count(plot);
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
