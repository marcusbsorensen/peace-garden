// A plot of the Knot Garden, drawn the way the app draws a plot: a floating
// slab of ground seen in true isometric, gravel all over it, two bands of low
// clipped box woven over and under each other inside a square edging, and a
// block of one colour standing in each of the eight compartments.
//
// **It is one pattern, so the page shows one plot.** The Long Walk draws three
// end to end because a walk is a length you look down. A knot is not: it is a
// figure you look into from above, and two of them side by side read as neither
// one knot nor two.
//
// **The weave is the whole area, and it is drawn rather than implied.** At each
// of the four crossings one band carries on through and swells a little, as a
// clipped hedge does where two runs meet, and the other stops square against
// its face and starts again on the far side. Which does which alternates round
// the knot, so every run is over at one of its two crossings and under at the
// other. Two bands simply overlapping would be a grid; the alternation is the
// difference between a grid and a knot.
//
// **The bands curve, which is the other half of that difference.** Interlaced
// straight runs are a weave, and a weave drawn with a ruler still reads as a
// grid: there is no line for the eye to follow through a crossing. Each band
// is in three stretches — an arm, the inner stretch between its two crossings,
// and the other arm — and the inner one bows in toward the empty middle while
// the arms bow out, so a band arrives at a crossing turning and leaves it
// turning the same way. The four inner stretches close round the middle as a
// ring of four arcs. The bows are zero at the crossings, so the crossings do
// not move and neither does any plant.
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
import { COLOUR, RIM_DEPTH, SIDE, hash, readOutline, readStructure } from './longwalk.js';

// Seeds for this area's dressing, so a plot is the same shape on every visit.
// Its own, not the walk's, the room's, the crossing's or the orchard's: five
// areas drawing from one seed would be five plots with the same wandering edge,
// which is the sort of thing an eye catches without being able to say why.
const KNOT = { ground: 7417, floor: 31, grain: 53, band: 601, edging: 641, bridge: 673 };

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
    const half = SIDE / 2 - 0.06;
    const cell = 0.06;
    const steps = Math.ceil((half * 2) / cell);
    const lattice = [];
    for (let i = 0; i <= steps; i++) {
      const row = [];
      for (let j = 0; j <= steps; j++) {
        const edgeOfSheet = i === 0 || j === 0 || i === steps || j === steps;
        const shift = edgeOfSheet ? 0 : cell * 0.34;
        row.push([
          Math.max(-half, Math.min(half, -half + i * cell + shift * (hash(i * 7919 + j * 104729) - 0.5) * 2)),
          Math.max(-half, Math.min(half, -half + j * cell + shift * (hash(i * 6733 + j * 92831) - 0.5) * 2)),
        ]);
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

    // MARK: The knot

    const band = place.bandHalfThickness * 2;
    const from = place.bandFrom;
    const high = place.bandHeight;

    let mark = 0;
    // One run of hedging, along x or along z, from `a` to `b` on that axis and
    // standing on the other at `fixed`. Its ends are cut square rather than
    // domed — every one of them is buried, either in the edging or inside the
    // band that crosses over it — which is what `domed: 0` is for, and the
    // reason the Quiet Garden's enclosure needed it first.
    // `bow` stands the stretch's middle off the straight line between its two
    // ends, toward the axis it is fixed on — the same number in the mesh's own
    // frame either way round, because `lay` puts a run's own x on whichever
    // axis it is fixed to.
    const run = (alongX, fixed, a, b, height, thickness, bow = 0) => {
      const length = b - a, mid = (a + b) / 2;
      const mesh = readStructure(
        takeResult(e, e.pg_hedge(length, height, thickness, KNOT.band + mark++, 0, bow)));
      lay(mesh, alongX, alongX ? [mid, 0, fixed] : [fixed, 0, mid], vertex);
    };

    // **The knot, and the square edging round it**, as the rule lays them out:
    // three stretches to each of the four runs, which is a run cut at the
    // crossing it dives under and cut again at the crossing it rides over,
    // where its two bows change hand. `KnotGarden.weave` says which is which
    // and why, and the page draws what it is given — a second copy of a weave
    // here is a thing that can drift from the rule a compartment is measured
    // against without either of them looking wrong.
    for (const b of place.weave) run(b.alongX, b.at, b.from, b.to, high, band, b.bow);

    // **The swelling where a band rides over.** A clipped hedge is thicker and
    // a little taller where two runs meet and have grown into each other, and
    // that lump is what turns a band passing a broken one into a band passing
    // *over* it. Without it the crossing reads as a gap in one hedge; with it
    // the eye takes the continuous run as the near one and the knot closes.
    //
    // It is a piece of hedge and not a lift of the run itself, because a run is
    // over at one of its crossings and under at the other: a run raised along
    // its whole length would ride over both.
    //
    // It also sits on the joint where a band's inner stretch meets its arm,
    // which is at the over-crossing and is where the two bows change hand.
    // Nothing needs covering there — a bow leaves both its ends flat, so the
    // two stretches meet along the same line — but a lump is welcome on a seam
    // all the same.
    //
    // Straight, and it can be: a stretch is flat at its ends, so the band under
    // the swell is running along its own axis and not across it.
    const swellHigh = high + 0.055, swellThick = band + 0.055, swellLong = 0.58;
    for (const s of [from, -from]) {
      // The run along z at x = s is over at z = +s; the run along x at z = s is
      // over at x = −s. The two sentences above, read the other way round.
      run(false, s, s - swellLong / 2, s + swellLong / 2, swellHigh, swellThick);
      run(true, s, -s - swellLong / 2, -s + swellLong / 2, swellHigh, swellThick);
    }

    // Its sides hang from the outline down to a floor as rough as a clod's, in
    // the app's strata. The walk's arithmetic, because it is the same slab.
    const strata = [[0, COLOUR.humus], [0.16, COLOUR.earth], [0.58, COLOUR.earth], [1, COLOUR.bedrock]];
    let around = 0;
    const floor = outline.map((p, i) => {
      if (i > 0) around += Math.hypot(p[0] - outline[i - 1][0], p[1] - outline[i - 1][1]);
      return RIM_DEPTH * (1 + 0.22 * (e.pg_verge(around, 1, KNOT.floor) / 0.14));
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

/// A run of hedging, moved into place, with the grain that keeps a single
/// colour from reading as plastic. `alongX` swaps the mesh's own length onto
/// the other axis — `pg_hedge` runs along z and half of these run across.
///
/// The grain is read off where a vertex is in the world rather than where it is
/// in its own run, so that two runs meeting at a crossing do not show a seam of
/// two different greens.
function lay(mesh, alongX, at, vertex) {
  for (let t = 0; t < mesh.indices.length; t += 3) {
    for (const k of [0, 1, 2]) {
      const v = mesh.indices[t + k];
      const raw = [mesh.positions[v * 3], mesh.positions[v * 3 + 1], mesh.positions[v * 3 + 2]];
      const rawN = [mesh.normals[v * 3], mesh.normals[v * 3 + 1], mesh.normals[v * 3 + 2]];
      const p = alongX ? [raw[2], raw[1], raw[0]] : raw;
      const nn = alongX ? [rawN[2], rawN[1], rawN[0]] : rawN;
      const here = [p[0] + at[0], p[1] + at[1], p[2] + at[2]];
      const tone = 0.9 + 0.2 * hash(Math.round(here[0] * 41) * 131 + Math.round(here[2] * 41) + Math.round(here[1] * 67));
      vertex(here, nn, COLOUR.box.map((c) => c * tone));
    }
  }
}

// MARK: - Growing a plot

// **Letting go of the thread** between plants, the way the other four do:
// thirty-two is the most any area holds, and the module still builds a mesh a
// plant, so a page that cannot answer a finger while it does is a page that
// looks broken.
const SLICE = 16;
const breathe = () => new Promise((resume) => setTimeout(resume, 0));

// Grows one plot from the plot service. A planting with no parents was minted
// rather than crossed — the ambassador in the north compartment — and grows
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
