// A plot of the Orchard, drawn the way the app draws a plot: a floating slab of
// ground seen in true isometric, a meadow of long grass, five trees on a
// quincunx each nudged a little off it, a mown crescent under each outer tree
// and a mown disc under the middle one, one mown way wandering through, and the
// planting of each guild standing in its mown grass.
//
// **It is one place, so the page shows one plot.** The Long Walk draws three end
// to end because a walk is a length you look down. An orchard is not: it is a
// pattern you look into, and five trees in a quincunx is the whole of what there
// is to see.
//
// **A meadow orchard since 2 October 2026** (Marcus's choice,
// `design/garden-layouts-2026-10-02/RESEARCH.md` §*The Orchard*, option A).
// The mown grass is still the guilds made visible — grass left long between the
// trees and cut where the planting stands, so a visitor sees which four belong
// to which tree without a line drawn anywhere — but an outer guild is now a
// crescent at its tree's drip line, turned toward the middle tree, and its mown
// grass is a crescent too. The middle tree keeps its ring and its disc. One mown
// way joins them, in at one edge and out at the other: the households turned
// toward each other, and a way that leads on out of the plot.
//
// The rule that decides where each plant stands is SeedCore's `Orchard`, through
// the module — this file draws the ground and puts each plant on the spot the
// service gives it. The plot's own numbers come from `pg_orchard_plan`, and
// where this plot's trunks, way, pond and crescents lie, turned for the plot as
// its plants are, from `pg_orchard_layout`, rather than being written down
// again here.

import { decode, takeResult } from './plant.js';
import { COLOUR, SIDE, keepToPlot, readOutline, readStructure, rimReach } from './longwalk.js';
import { hangSide } from './slab.js';
import { floorAround, rimOf, sinkPool } from './water.js';

// Seeds for this area's dressing, so a plot is the same shape on every visit.
// Its own, not the walk's, the room's or the crossing's: four areas drawing from
// one seed would be four plots with the same wandering edge, which is the sort
// of thing an eye catches without being able to say why.
const GROVE = { ground: 6301, floor: 29, rough: 83, mow: 97, tree: 1103, pond: 1117, way: 1129 };

// **A dipping pond in the meadow**, in one of the two pockets the crowns
// frame, which the table chose clear of every place by 0.80 m. The Orchard is
// one step up from the foot of the garden, where water still lies open, so it
// is dug and not built. 0.64 m of water and its 0.10 m of wet earth.
const POND = { across: 0.64 };

// How wide the mown grass is either side of a crescent's line, and of the
// way's: wide enough that a crescent's plants stand in cut grass, and the way
// a path for one.
const MOWN = { crescent: 0.34, way: 0.25, disc: 0.32 };

export function plan(e) {
  const place = JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_orchard_plan())));
  // The plot on show, as it is laid: plot 0 until a plot is grown, when the
  // page asks for that plot's and builds its ground again.
  place.layout = layout(e, 0);
  return place;
}

// **Plot `plot` as it is laid**: its variant, its five trunks (the middle
// first), its mown way, its pond and each outer guild's mown arc, turned for
// the plot by the module from the rule's own table.
export function layout(e, plot) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_orchard_layout(plot))));
}

// MARK: - The ground

export function makeOrchardGround(place) {
  return function buildOrchardGround(farSide, span, e, eye) {
    const { trunks, way, pond: pondAt, crescents } = place.layout;
    const positions = [], normals = [], colours = [];
    const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
    const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
    const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => {
      tri(a, b, c, n, ca, cb, cc); tri(a, c, d, n, ca, cc, cd);
    };
    const UP = [0, 1, 0];

    const outline = readOutline(e, SIDE, SIDE, GROVE.ground);
    const n = outline.length;
    // Walked out from the pond's rim rather than fanned from the middle, so
    // the pond has a hole to lie in. See `floorAround`.
    const pond = { at: pondAt, across: POND.across, seed: GROVE.pond, round: true };
    const { inside: inPond } = rimOf(e, pond);

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
    // The floor under the meadow is walked out from the pond, and is the
    // meadow's own mottle rather than plain turf: a cell with a corner in the
    // pond is left out, and what shows in its place has to be the same grass.
    floorAround(e, { quad }, outline, pond, rough);
    const inward = (p, k) => [p[0] * (k / rings), p[1] * (k / rings)];
    for (let i = 0; i < n; i++) {
      const a = outline[i], b = outline[(i + 1) % n];
      for (let k = 0; k < rings; k++) {
        const [a0, a1, b0, b1] = [inward(a, k), inward(a, k + 1), inward(b, k), inward(b, k + 1)];
        if ([a0, a1, b0, b1].some((p) => inPond(p[0], p[1]))) continue;
        quad([a0[0], 0.003, a0[1]], [a1[0], 0.003, a1[1]], [b1[0], 0.003, b1[1]], [b0[0], 0.003, b0[1]], UP,
             rough(...a0), rough(...a1), rough(...b1), rough(...b0));
      }
    }

    // The lesser of two, with the corner between them rounded over `k`, and
    // never more than either.
    const softer = (a, b, k) => {
      const h = Math.max(k - Math.abs(a - b), 0) / k;
      return Math.min(a, b) - h * h * k / 4;
    };

    // Cut grass is brighter than the meadow round it, and each patch is mown a
    // fraction differently, so the cuts are not copies of each other.
    const cutTone = (t) => COLOUR.grass.map((v) => v * (0.96 + 0.07 * ((t * 7) % 5) / 4));

    // **The mown way**, first and lowest, so where it meets a crescent or the
    // middle disc the two cuts run together. A path for one, its edges
    // wandering and its width breathing by a tenth, as a mower is walked by
    // eye; and it stops on the plot's edge, where the table's line runs on past
    // it into the sky.
    const keep = keepToPlot(outline);
    const inPlot = (x, z) => {
      let within = false;
      for (let i = 0, j = n - 1; i < n; j = i++) {
        const a = outline[i], b = outline[j];
        if ((a[1] > z) !== (b[1] > z) && x < (b[0] - a[0]) * (z - a[1]) / (b[1] - a[1]) + a[0]) within = !within;
      }
      return within;
    };
    const onPlot = [];
    for (let i = 0; i < way.length; i++) {
      const [x, z] = way[i];
      if (inPlot(x, z)) {
        if (!onPlot.length && i > 0) onPlot.push(way[i - 1]);
        onPlot.push(way[i]);
      } else if (onPlot.length) {
        onPlot.push(way[i]);
        break;
      }
    }
    mowAlong(onPlot, MOWN.way, 0.0045, cutTone(5), GROVE.way, false);

    // **A mown crescent under each outer tree**, along the table's arc through
    // its four places and a little past them, its ends rounded, its edges
    // wandering. Mown to the plot's edge and stopping on it where a crown's
    // horn comes near the rim.
    for (const [g, arc] of crescents.entries()) {
      mowAlong(arc, MOWN.crescent, 0.0052, cutTone(g + 1), GROVE.mow + g + 1, true);
    }

    // **A mown disc under the middle tree**, a little wider than the ring that
    // stands in it so the planting is inside the cut rather than on its edge.
    // Its rim wanders, because a mower goes round a trunk by eye.
    //
    // The wander is read off **where a point on the rim actually is**, not off
    // how far round it is. An angle wraps from one back to zero and leaves a
    // step there; a position does not, because the rim closes in space and so
    // does the noise it is sampled from. `Organic.tree` does the same thing for
    // the same reason.
    //
    // **And it stays on the plot**, as every disc did since 25 September 2026:
    // where the edge is nearer than the disc, the cut runs to the edge and
    // stops on it, rounded where the circle turns onto it. The middle tree's is
    // never near the edge, but the rule is the plot's.
    const discRadius = place.middleRadius + MOWN.disc;
    const fan = 96;
    {
      const trunk = trunks[0];
      const rim = [];
      for (let a = 0; a <= fan; a++) {
        const turn = (a / fan) * Math.PI * 2;
        const cx = Math.cos(turn), cz = Math.sin(turn);
        const wander = 1
          + 0.07 * (e.pg_verge(cx * 1.4, -1, GROVE.mow) / 0.14)
          + 0.06 * (e.pg_verge(cz * 1.2, 1, GROVE.mow) / 0.14);
        const r = softer(discRadius * wander, rimReach(outline, trunk, cx, cz) - 0.004, 0.12);
        rim.push([trunk[0] + r * cx, trunk[1] + r * cz]);
      }
      const cut = cutTone(0);
      for (let a = 0; a < fan; a++) {
        tri([trunk[0], 0.006, trunk[1]],
            [rim[a][0], 0.006, rim[a][1]],
            [rim[a + 1][0], 0.006, rim[a + 1][1]], UP, cut);
      }
    }

    // **A strip of mown grass along a line**: `half` either side of it, the
    // width breathing by a tenth and each edge wandering a few centimetres, by
    // the verge noise read off how far along the line it is — which never
    // wraps, because a line has two ends. `capped` rounds each end with a
    // fan, so a crescent's horns are cut round rather than square. Every point
    // is kept on the plot (`keepToPlot`): past the edge it is pulled straight
    // in onto it.
    function mowAlong(line, half, y, colour, seed, capped) {
      if (line.length < 2) return;
      let along = 0;
      const left = [], right = [], centre = [];
      for (let i = 0; i < line.length; i++) {
        const [x, z] = line[i];
        if (i) along += Math.hypot(x - line[i - 1][0], z - line[i - 1][1]);
        const a = line[Math.max(0, i - 1)], b = line[Math.min(line.length - 1, i + 1)];
        const tl = Math.hypot(b[0] - a[0], b[1] - a[1]) || 1;
        const nx = -(b[1] - a[1]) / tl, nz = (b[0] - a[0]) / tl;
        const breathe = half * (1 + 0.10 * (e.pg_verge(along * 1.1, 2, seed) / 0.14));
        const l = breathe + 0.03 * (e.pg_verge(along * 1.7, -1, seed) / 0.14);
        const r = breathe + 0.03 * (e.pg_verge(along * 1.7, 1, seed) / 0.14);
        left.push(keep(x + nx * l, z + nz * l));
        right.push(keep(x - nx * r, z - nz * r));
        centre.push(keep(x, z));
      }
      const at = (p) => [p[0], y, p[1]];
      for (let i = 0; i + 1 < line.length; i++) {
        quad(at(left[i]), at(left[i + 1]), at(right[i + 1]), at(right[i]), UP, colour);
      }
      if (!capped) return;
      for (const [end, toward] of [[0, 1], [line.length - 1, line.length - 2]]) {
        const [x, z] = line[end];
        const dx = x - line[toward][0], dz = z - line[toward][1], dl = Math.hypot(dx, dz) || 1;
        const ox = dx / dl, oz = dz / dl;
        const from = left[end], to = right[end];
        const fanAt = [];
        const steps = 10;
        for (let k = 0; k <= steps; k++) {
          // Round from the left edge, out past the end, to the right edge.
          const t = (k / steps) * Math.PI;
          const lx = from[0] - x, lz = from[1] - z, rx = to[0] - x, rz = to[1] - z;
          const w = (Math.hypot(lx, lz) + Math.hypot(rx, rz)) / 2;
          const sx = Math.cos(t) * (lx / (Math.hypot(lx, lz) || 1)) + Math.sin(t) * ox;
          const sz = Math.cos(t) * (lz / (Math.hypot(lx, lz) || 1)) + Math.sin(t) * oz;
          fanAt.push(keep(x + sx * w, z + sz * w));
        }
        for (let k = 0; k < steps; k++) tri(at(centre[end]), at(fanAt[k]), at(fanAt[k + 1]), UP, colour);
      }
    }

    // The pond, after the meadow and the discs, so its rim lies over them.
    sinkPool(e, { tri, quad }, pond);

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

    // Its side: the slab every plot hangs from its outline (`slab.js`), the
    // floor seed saying how its lower edge undulates.
    const slab = hangSide(outline, { salt: GROVE.floor });

    return {
      positions: new Float32Array(positions),
      normals: new Float32Array(normals),
      colours: new Float32Array(colours),
      side: slab,
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
// its seed alone. **The ground is laid for the plot first**, turned and nudged
// by its number as the service turned its plants.
export async function growOrchardFromService(e, stage, place, plot, report) {
  stage.clear();
  const { plantings } = await (await fetch(`/api/orchard/plot/${plot}`)).json();
  place.layout = layout(e, plot);
  stage.rebuild();
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

export async function growInvented(e, stage, place, plot, report) {
  stage.clear();
  place.layout = layout(e, plot);
  stage.rebuild();
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
