// A plot of the Orchard, drawn the way the app draws a plot: a floating slab of
// ground seen in true isometric, meadow grass all over it, five trees standing
// in a quincunx, a mown disc under each, and the planting of a guild standing in
// the mown grass round every trunk.
//
// **It is one place, so the page shows one plot.** The Long Walk draws three end
// to end because a walk is a length you look down. An orchard is not: it is a
// pattern you look into, and five trees in a quincunx is the whole of what there
// is to see.
//
// **The mown discs are the guilds made visible.** Grass is left long between the
// trees, as an orchard's is, and cut back round each trunk, as an orchard's is —
// so the same thing that is right horticulturally is the thing that shows a
// visitor which four plants belong to which tree, without a line being drawn
// anywhere. A guild stands inside its own disc.
//
// The rule that decides where each plant stands is SeedCore's `Orchard`, through
// the module — this file draws the ground and puts each plant on the spot the
// service gives it. The plot's own numbers, and where the five trunks stand,
// come from `pg_orchard_plan` and `pg_orchard_trees` rather than being written
// down again here.

import { decode, takeResult } from './plant.js';
import { COLOUR, RIM_DEPTH, SIDE, readOutline, readStructure } from './longwalk.js';

// Seeds for this area's dressing, so a plot is the same shape on every visit.
// Its own, not the walk's, the room's or the crossing's: four areas drawing from
// one seed would be four plots with the same wandering edge, which is the sort
// of thing an eye catches without being able to say why.
const GROVE = { ground: 6301, floor: 29, rough: 83, mow: 97, tree: 1103 };

export function plan(e) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_orchard_plan())));
}

// Where the five trunks stand, from the rule rather than from a copy of it.
export function trees(e) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_orchard_trees())));
}

// MARK: - The ground

export function makeOrchardGround(place, trunks) {
  return function buildOrchardGround(farSide, span, e, eye) {
    const positions = [], normals = [], colours = [];
    const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
    const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
    const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => {
      tri(a, b, c, n, ca, cb, cc); tri(a, c, d, n, ca, cc, cd);
    };
    const UP = [0, 1, 0];

    const outline = readOutline(e, SIDE, SIDE, GROVE.ground);
    const n = outline.length;
    for (let i = 0; i < n; i++) {
      const a = outline[i], b = outline[(i + 1) % n];
      tri([0, 0, 0], [a[0], 0, a[1]], [b[0], 0, b[1]], UP, COLOUR.turf);
    }

    // **Meadow grass, mottled.** The Crossing's arithmetic exactly, because it
    // is the same long grass: quads carrying a tone at each corner
    // rather than over each face, so neighbours share corners and no cell edge
    // shows anywhere. An orchard's sward is rougher than a crossing's quarters
    // if anything — it is cut once a year, not left between paths — so it is
    // drawn a shade darker and varying a shade harder.
    //
    // **Laid on the outline, not on a square.** It was a grid 2.54 m either
    // way, and the plot's wandering edge comes in to 2.42 m: the meadow ran
    // past the slab on nearly every side, as a ruled edge with its four corners
    // sticking out into the sky. It is now rings drawn in from the outline
    // itself — the outline goes once round the middle, so each of its points
    // can be walked straight in — and so the meadow stops exactly where the
    // ground does, on the ground's own wandering edge.
    const cell = 0.26;
    const rings = Math.ceil(SIDE / 2 / cell);
    const rough = (x, z) => COLOUR.turf.map((v) => v * 0.87 * (1
      + 0.15 * (e.pg_verge(x * 1.31, -1, GROVE.rough) / 0.14)
      + 0.12 * (e.pg_verge(z * 1.07, 1, GROVE.rough) / 0.14)));
    const inward = (p, k) => [p[0] * (k / rings), p[1] * (k / rings)];
    for (let i = 0; i < n; i++) {
      const a = outline[i], b = outline[(i + 1) % n];
      for (let k = 0; k < rings; k++) {
        const [a0, a1, b0, b1] = [inward(a, k), inward(a, k + 1), inward(b, k), inward(b, k + 1)];
        quad([a0[0], 0.003, a0[1]], [a1[0], 0.003, a1[1]], [b1[0], 0.003, b1[1]], [b0[0], 0.003, b0[1]], UP,
             rough(...a0), rough(...a1), rough(...b1), rough(...b0));
      }
    }

    // How far a line from `from` heading `(dx, dz)` runs before it leaves the
    // plot: the nearest crossing of the outline.
    const reach = (from, dx, dz) => {
      let best = Infinity;
      for (let i = 0; i < n; i++) {
        const a = outline[i], b = outline[(i + 1) % n];
        const ex = b[0] - a[0], ez = b[1] - a[1];
        const det = dx * ez - dz * ex;
        if (Math.abs(det) < 1e-9) continue;
        const wx = a[0] - from[0], wz = a[1] - from[1];
        const along = (wx * ez - wz * ex) / det;
        const on = (wx * dz - wz * dx) / det;
        if (along > 0 && on >= 0 && on <= 1) best = Math.min(best, along);
      }
      return best;
    };
    // The lesser of two, with the corner between them rounded over `k`, and
    // never more than either.
    const softer = (a, b, k) => {
      const h = Math.max(k - Math.abs(a - b), 0) / k;
      return Math.min(a, b) - h * h * k / 4;
    };

    // **A mown disc under each tree**, a little wider than the guild that stands
    // in it so the planting is inside the cut rather than on its edge. Its rim
    // wanders, because a mower goes round a trunk by eye.
    //
    // The wander is read off **where a point on the rim actually is**, not off
    // how far round it is. An angle wraps from one back to zero and leaves a
    // step there; a position does not, because the rim closes in space and so
    // does the noise it is sampled from. `Organic.tree` does the same thing for
    // the same reason.
    //
    // **And it stays on the plot.** The four outer trunks stand 1.70 m out and
    // the plot's edge is only 0.74–0.78 m beyond them, so a disc of 1.07 m
    // radius hung a third of a metre over the slab's side into the sky. Where
    // the edge is nearer than the disc, the cut now runs to the edge and stops
    // on it, as a lawn is mown to the lip of a bank — on the plot's own
    // wandering edge, and rounded where the circle turns onto it, so the rim
    // has no corner. It stops *on* the edge, not short of it: a guild's outer
    // plant can stand within a centimetre of the edge (6 mm, in the workbench's
    // five hundred), and a strip of meadow left there
    // would put it out of its own disc, or draw a ruled-looking hairline round
    // the slab where it is thin. (The 4 mm is what a chord between two rim
    // points bows past the edge where it dents inward.)
    const discRadius = place.guildRadius + 0.32;
    const fan = 96;
    for (const [t, trunk] of trunks.entries()) {
      const rim = [];
      for (let a = 0; a <= fan; a++) {
        const turn = (a / fan) * Math.PI * 2;
        const cx = Math.cos(turn), cz = Math.sin(turn);
        const wander = 1
          + 0.07 * (e.pg_verge(cx * 1.4, -1, GROVE.mow + t) / 0.14)
          + 0.06 * (e.pg_verge(cz * 1.2, 1, GROVE.mow + t) / 0.14);
        const r = softer(discRadius * wander, reach(trunk, cx, cz) - 0.004, 0.12);
        rim.push([trunk[0] + r * cx, trunk[1] + r * cz]);
      }
      // Cut grass is brighter than the meadow round it, and each disc is mown a
      // fraction differently, so five discs are not five copies.
      const tone = 0.96 + 0.07 * ((t * 7) % 5) / 4;
      const cut = COLOUR.grass.map((v) => v * tone);
      for (let a = 0; a < fan; a++) {
        tri([trunk[0], 0.006, trunk[1]],
            [rim[a][0], 0.006, rim[a][1]],
            [rim[a + 1][0], 0.006, rim[a + 1][1]], UP, cut);
      }
    }

    // **The five trees.** Each is `Organic.tree` through the module, standing on
    // the trunk the rule gives. They vary — a quincunx of five identical trees
    // is a diagram — but they vary by a little, because an orchard is planted
    // in one season from one stock and its trees are siblings.
    const CROWN_BASE = 2.10;
    const casting = [], canopy = [];
    for (const [t, trunk] of trunks.entries()) {
      const wobbleSeed = GROVE.tree + t * 17;
      const tall = 3.15 + 0.26 * ((t * 11) % 7) / 6;
      const wide = 1.44 + 0.18 * ((t * 5) % 4) / 3;
      const mesh = readStructure(takeResult(e, e.pg_tree(tall, wide, CROWN_BASE, wobbleSeed)));
      // **Shaded flat, which is what the roundel taught.** Smooth normals over a
      // lumpy canopy average the lumps away and give one broad highlight: a
      // green balloon on a stick, which is exactly what the first pass drew.
      // One normal and one tone a triangle, both read off where the triangle
      // actually is, turns the same mesh into clumps of foliage catching the
      // light at their own angles. The trunk is flat-shaded too, which costs
      // nothing — bark is not a polished surface either.
      for (let i = 0; i < mesh.indices.length; i += 3) {
        const corner = [0, 1, 2].map((k) => {
          const v = mesh.indices[i + k];
          return [mesh.positions[v * 3], mesh.positions[v * 3 + 1], mesh.positions[v * 3 + 2]];
        });
        const normal = [0, 1, 2].map((k) => {
          const v = mesh.indices[i + k];
          return [mesh.normals[v * 3], mesh.normals[v * 3 + 1], mesh.normals[v * 3 + 2]];
        });

        // **The tone is read off each corner, not off the face.** Taken per
        // face from a hash of where the face is, it drew a star at the top of
        // every canopy: at the pole the triangles are tiny and touching, so
        // neighbours got wildly different greens. The mesh showing through its
        // own shading, which is the roundel's fourth pass again in another
        // form. Read smoothly off a vertex's own height, it cannot.
        //
        // **A canopy is darker underneath**, because its own leaves shade it —
        // half a stop across the canopy's height. That is the whole of the
        // variation now, and it is enough: the lumpiness does the rest through
        // the light, which is what it is for.
        const my = (corner[0][1] + corner[1][1] + corner[2][1]) / 3;
        // Bark below the canopy and leaf above it. The join is a hand's breadth
        // inside the canopy, where the trunk carries on up but is already
        // hidden by the leaves round it.
        const inCanopy = my > CROWN_BASE + 0.06;
        const base = inCanopy ? COLOUR.leaf : COLOUR.bark;
        const toneAt = (y) => (inCanopy
          ? 0.74 + 0.34 * Math.min(1, Math.max(0, (y - CROWN_BASE) / Math.max(0.3, tall - CROWN_BASE)))
          : 0.82 + 0.26 * Math.min(1, y / CROWN_BASE));

        corner.forEach((p, k) => vertex([trunk[0] + p[0], p[1], trunk[1] + p[2]], normal[k],
                                        base.map((c) => c * toneAt(p[1]))));
        // **Its shade**: the crown handed to the stage as `canopy`, laid as a
        // dappled pool; the foot of the trunk as `casting`, a plant's contact
        // shadow. Only the foot, because a bare trunk's whole shadow is a
        // two-metre ruled stripe across the grass.
        const at = corner.map((p) => [trunk[0] + p[0], p[1], trunk[1] + p[2]]).flat();
        if (inCanopy) canopy.push(...at);
        else if (my < 0.6) casting.push(...at);
      }
    }

    // Its sides hang from the outline down to a floor as rough as a clod's, in
    // the app's strata. The walk's arithmetic, because it is the same slab.
    const strata = [[0, COLOUR.humus], [0.16, COLOUR.earth], [0.58, COLOUR.earth], [1, COLOUR.bedrock]];
    let around = 0;
    const floor = outline.map((p, i) => {
      if (i > 0) around += Math.hypot(p[0] - outline[i - 1][0], p[1] - outline[i - 1][1]);
      return RIM_DEPTH * (1 + 0.22 * (e.pg_verge(around, 1, GROVE.floor) / 0.14));
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
      casting: new Float32Array(casting),
      canopy: new Float32Array(canopy),
    };
  };
}

// MARK: - Growing a plot

// **Letting go of the thread** between plants, the way the other three do:
// twenty is quick, but the module still builds a mesh a plant, and a page that
// cannot answer a finger while it does is a page that looks broken.
const SLICE = 16;
const breathe = () => new Promise((resume) => setTimeout(resume, 0));

// Grows one plot from the plot service. A planting with no parents was minted
// rather than crossed — the ambassador under the middle tree — and grows from
// its seed alone.
export async function growOrchardFromService(e, stage, plot, report) {
  stage.clear();
  const { plantings } = await (await fetch(`/api/orchard/plot/${plot}`)).json();
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

// The workbench's version: an Orchard the module invents, for judging the
// template before anybody has planted anything in it.
export async function plantVisitors(e, total, report) {
  let arrived = 0;
  let since = performance.now();
  while (arrived < total) {
    e.pg_orchard_arrive();
    arrived += 1;
    if (performance.now() - since > SLICE) {
      report(`Planting by the rule: ${arrived} of ${total} arrived`);
      await breathe();
      since = performance.now();
    }
  }
  return e.pg_orchard_plots();
}

export async function growInvented(e, stage, plot, report) {
  stage.clear();
  const count = e.pg_orchard_count(plot);
  let since = performance.now();
  for (let i = 0; i < count; i++) {
    const length = e.pg_orchard_grow(plot, i);
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

export function describeOrchard(e, plot) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_orchard_describe(plot))));
}
