// A plot of the Home Ground, drawn the way the app draws a plot: a floating
// slab of dark soil seen in true isometric, three raised beds mounded up out of
// it with trodden paths between, and a crop standing in rows across each bed.
//
// **Lazy beds that follow the land**, since 2 October 2026 (option A of the
// layouts Marcus approved that day): the three beds sway together in a lazy S,
// as hand-dug ridges follow the ground, and the rows run square to the curve.
// Each bed's line is the table's (`tables/home_ground_beds.js`, made offline),
// and a plot is mirrored or not by its number (`pg_plot_variant`), so one plot
// sways one way and the next the other. **A bold curve, finely wandering**:
// the sway is the shape, and each side of a bed strays off it by no more than
// a spade would.
//
// **Everything is soil, and nothing is ruled.** A bed is the ground's own
// relief, 8 cm high with soft shoulders, as a no-dig bed is made; there are no
// boards, because a board is a ruled line. The paths are the same soil trodden
// paler and flatter, and **the edge of a path is the shoulder of a bed**, not a
// line drawn between them. Each side and each end of a bed wanders by a few
// centimetres on its own, and its corners are rounded, so no bed has a straight
// edge.
//
// **A sown bed is raked and an unsown one is dug.** Which beds a plot's crops
// have claimed is a fact about the plants, so the page reads it off the spots
// the service sends and builds the ground again: a bed with plants in it is
// fine and even, and one waiting to be sown is rougher, in clods, which is what
// an unsown bed in a kitchen garden looks like.
//
// **Every plant stands on the bed where it is**: the stage lifts each one by
// the ground's height at its spot, which on a bed's top is the full 8 cm less a
// little of the dome.
//
// The rule that decides where each plant stands is SeedCore's `HomeGround`,
// through the module. This file draws the soil and puts each plant on the spot
// the service gives it; the plot's own numbers come from `pg_ground_plan`
// rather than being written down again.

import { decode, takeResult } from './plant.js';
import { SIDE, hash, readOutline } from './longwalk.js';
import { hangSide } from './slab.js';
import { footing, raiseTrough } from './water.js';
import { PLAIN, applyVariantToCurve, variantFromModule } from './variant.js';
import { homeGroundBeds } from './tables/home_ground_beds.js';

// Seeds for this area's dressing, its own and not another area's.
const GROUND = { ground: 6173, floor: 59, crumb: 97, drift: 131, clod: 157, edge: 181, trough: 197 };

// **A dipping trough at the near end of a path**, where the can is filled on
// the way in. The Home Ground is a step up from the foot of the garden and has
// no ground to spare for a pond — the beds take it — so its water is held in
// stone. Lengthways down the path between the middle bed and the one east of
// it as the table draws the plot, which is 0.45 m wide, and ending inside the
// plot's edge, which comes in no nearer than 2.42 m. Laid across the headland
// instead it had room for 0.24 m of width and read as a block. The beds run
// straight at their ends, so the path does where the trough stands.
const TROUGH = { z: 1.98, across: 0.36, deep: 0.8 };

/// The soil: the colour the map gives this area — `LOOK.ground` in `gates.js`,
/// brought down by the quarter a plot is lit up by, as the Seedbed's tilth and
/// the Coppice's litter are. Darker than the tilth, which is the same earth
/// raked fine for sowing. The Wild Fields' earth starts from it too
/// (`wildground.js`).
export const SOIL = [0.242, 0.185, 0.138];

/// A path: the same soil trodden flat, paler for it and a little greyer,
/// because feet press the crumb together and dry its face. And the Wild
/// Fields' earth where visitors have worn it (`wildground.js`).
export const PATH = [0.315, 0.262, 0.212];

/// How high a bed stands over its paths, at its middle.
const RAISED = 0.08;

/// How far a bed's side or end wanders off its line, either way, at most.
/// **2.5 cm, since the beds sway** (it was 4.5 when they ran straight): the
/// sway is the bold curve and this is the fine wander on it, and a bed's side
/// has only so far to go before the slab's edge.
const WANDER = 0.025;

/// How round a bed's corners are.
const CORNER = 0.22;

export function plan(e) {
  const place = JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_ground_plan())));
  // Which beds are sown in the plot on show. Empty until a plot is grown; the
  // page fills it and asks the stage to build its ground again.
  place.sown = new Set();

  // **Each bed's line, as the plot on show is laid**: the table's, mirrored if
  // the plot is, and read by z every centimetre, because the ground asks
  // where a bed's middle is some forty thousand times. A line never doubles
  // back down the plot, so z names one point of it.
  const STEP = 0.01, FROM = -SIDE / 2;
  const across = [];
  place.lay = (variant = PLAIN) => {
    place.variant = variant;
    across.length = 0;
    for (let b = 0; b < place.beds; b++) {
      const line = applyVariantToCurve(variant, homeGroundBeds.curves[`bed${b}`][0].points);
      const xs = [];
      for (let z = FROM, k = 0; z <= -FROM + 1e-9; z = FROM + ++k * STEP) {
        let i = 0;
        while (i < line.length - 2 && line[i + 1][1] < z) i++;
        const [ax, az] = line[i], [bx, bz] = line[i + 1];
        const t = Math.min(1, Math.max(0, (z - az) / (bz - az)));
        xs.push(ax + (bx - ax) * t);
      }
      across.push(xs);
    }
  };
  place.lay(PLAIN);
  // Where bed `b`'s middle is at `z`, and how far it leans there.
  place.centre = (b, z) => {
    const xs = across[b];
    const k = Math.min(xs.length - 2, Math.max(0, (z - FROM) / STEP));
    const i = Math.floor(k);
    return { x: xs[i] + (xs[i + 1] - xs[i]) * (k - i), lean: (xs[i + 1] - xs[i]) / STEP };
  };

  // **Each bed's four edges, wandering**: the west and east sides as a curve
  // down the bed, the north and south ends as a curve across it, each its own
  // noise. Sampled once, every 5 cm, and read between samples, because the
  // ground asks for them some forty thousand times.
  const curve = (seed, side, scale) => {
    const step = 0.05, from = -SIDE / 2 - step;
    const samples = [];
    for (let t = from; t <= SIDE / 2 + 2 * step; t += step) {
      samples.push(WANDER * (e.pg_verge(t * scale, side, seed) / 0.14));
    }
    return (t) => {
      const k = Math.min(samples.length - 2, Math.max(0, (t - from) / step));
      const i = Math.floor(k);
      return samples[i] + (samples[i + 1] - samples[i]) * (k - i);
    };
  };
  const edges = place.bedX.map((_, b) => ({
    west: curve(GROUND.edge + b * 11, -1, 1.6),
    east: curve(GROUND.edge + b * 11, 1, 1.6),
    north: curve(GROUND.edge + b * 11 + 5, -2, 2.2),
    south: curve(GROUND.edge + b * 11 + 5, 2, 2.2),
  }));

  // **How far a point is outside a bed's top**, negative inside it: a rounded
  // box bent along the bed's line, whose sides are the wandering edges above.
  // Across is measured square to the line, so a bed is 1.2 m wide where it
  // leans as well as where it runs straight down the plot.
  const outside = (b, x, z) => {
    const w = edges[b], c = place.centre(b, z);
    const across = (x - c.x) / Math.hypot(1, c.lean);
    const dx = Math.abs(across) - (place.bedWidth / 2 + (across < 0 ? w.west(z) : w.east(z)));
    const dz = Math.abs(z) - (place.bedLength / 2 + (z < 0 ? w.north(x) : w.south(x)));
    const qx = dx + CORNER, qz = dz + CORNER;
    return Math.hypot(Math.max(qx, 0), Math.max(qz, 0)) + Math.min(Math.max(qx, qz), 0) - CORNER;
  };
  const smooth = (a, b, v) => { const t = Math.min(1, Math.max(0, (v - a) / (b - a))); return t * t * (3 - 2 * t); };

  // Which bed a point is on or nearest, and how far outside its top.
  place.bedAt = (x, z) => {
    let best = 0, far = Infinity;
    for (let b = 0; b < place.bedX.length; b++) {
      const o = outside(b, x, z);
      if (o < far) { far = o; best = b; }
    }
    return { bed: best, outside: far };
  };

  // **The ground's height anywhere on the plot**, so the soil and the plants
  // agree on it. A bed rises from its path over a shoulder 16 cm wide and is
  // domed a little across its top, as soil heaped by a spade is; a path is
  // level, as trodden soil is.
  place.height = (x, z) => {
    const { bed, outside: o } = place.bedAt(x, z);
    const c = place.centre(bed, z);
    const across = Math.min(1, Math.abs(x - c.x) / Math.hypot(1, c.lean) / (place.bedWidth / 2));
    return RAISED * (1 - smooth(-0.10, 0.06, o)) * (1 - 0.18 * across * across);
  };
  return place;
}

/// Which bed a plant is standing in, from where it stands. The wire says where,
/// not which, as the Seedbed's does; the beds are 1.65 m apart and a plant is
/// never more than 0.45 m from its bed's middle. Asked of the plot as it is
/// laid, so `place.lay` the plot's variant first.
export function bedOf(place, x, z) {
  let best = 0;
  for (let b = 1; b < place.beds; b++) {
    if (Math.abs(x - place.centre(b, z).x) < Math.abs(x - place.centre(best, z).x)) best = b;
  }
  return best;
}

// MARK: - The ground

export function makeGroundGround(place) {
  function buildHomeGround(farSide, span, e) {
    const positions = [], normals = [], colours = [];
    const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
    const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
    const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => {
      tri(a, b, c, n, ca, cb, cc); tri(a, c, d, n, ca, cc, cd);
    };
    const smooth = (a, b, v) => { const t = Math.min(1, Math.max(0, (v - a) / (b - a))); return t * t * (3 - 2 * t); };
    const mix = (a, b, t) => a.map((v, i) => v + (b[i] - v) * t);

    const outline = readOutline(e, SIDE, SIDE, GROUND.ground);
    const n = outline.length;

    // A slow wander under the crumb, so a bed is damper in one corner and
    // drier in another: the Seedbed's drift, for the reason it gives.
    const drift = (x, z) => 0.05 * (e.pg_verge(x * 0.55, -1, GROUND.drift) / 0.14)
      + 0.04 * (e.pg_verge(z * 0.5, 1, GROUND.drift) / 0.14);

    // **The soil's colour at a place, before a crumb's own tone**: a bed's
    // soil on its top and down its shoulder, the path's at its foot. The path
    // begins where the bed has nearly come down to it, so a shoulder is soil
    // going into shade, not a stripe of path colour up its side.
    const soil = (x, z, h) => {
      const trodden = 1 - smooth(0.0, 0.45, h / RAISED);
      return mix(SOIL, PATH, trodden);
    };

    // **The crumb: the Knot Garden's jittered lattice**, a tone to a crumb, at
    // five centimetres, over the whole square, and the corners that fall off
    // the slab moved in onto its rim, as the Coppice's are, so the paths run
    // out to the edge and meet it where it is.
    const inside = (x, z) => {
      let within = false;
      for (let i = 0, j = n - 1; i < n; j = i++) {
        const a = outline[i], b = outline[j];
        if ((a[1] > z) !== (b[1] > z) && x < (b[0] - a[0]) * (z - a[1]) / (b[1] - a[1]) + a[0]) within = !within;
      }
      return within;
    };
    const ontoRim = (x, z) => {
      let best = null, far = Infinity;
      for (let i = 0; i < n; i++) {
        const a = outline[i], b = outline[(i + 1) % n];
        const dx = b[0] - a[0], dz = b[1] - a[1];
        const t = Math.min(1, Math.max(0, ((x - a[0]) * dx + (z - a[1]) * dz) / (dx * dx + dz * dz)));
        const p = [a[0] + dx * t, a[1] + dz * t];
        const d = (p[0] - x) ** 2 + (p[1] - z) ** 2;
        if (d < far) { far = d; best = p; }
      }
      return best;
    };

    // **A dug bed is in clods.** Only where a bed waits to be sown: a lump or
    // a hollow of up to a centimetre and a half every few crumbs, so the bed
    // reads as turned earth rather than as a raked one nobody has used.
    const clod = (x, z, i, j) => {
      const { bed, outside: o } = place.bedAt(x, z);
      if (place.sown.has(bed) || o > -0.04) return 0;
      return 0.015 * (hash(Math.floor(i / 2) * 389 + Math.floor(j / 2) * 107 + GROUND.clod) - 0.5) * 2
        * smooth(-0.04, -0.14, o);
    };

    const cell = 0.05, half = SIDE / 2, steps = Math.ceil(SIDE / cell);
    const grid = [];
    for (let i = 0; i <= steps; i++) {
      const row = [];
      for (let j = 0; j <= steps; j++) {
        const edge = i === 0 || j === 0 || i === steps || j === steps;
        const shift = edge ? 0 : cell * 0.34;
        let x = -half + i * cell + shift * (hash(i * 7919 + j * 104729 + 2.3) - 0.5) * 2;
        let z = -half + j * cell + shift * (hash(i * 6733 + j * 92831 + 4.1) - 0.5) * 2;
        if (!inside(x, z)) [x, z] = ontoRim(x, z);
        row.push([x, place.height(x, z) + clod(x, z, i, j), z]);
      }
      grid.push(row);
    }

    const face = (a, b, c, key) => {
      const e1 = [b[0] - a[0], b[1] - a[1], b[2] - a[2]], e2 = [c[0] - a[0], c[1] - a[1], c[2] - a[2]];
      const nn = [e1[2] * e2[1] - e1[1] * e2[2], e1[0] * e2[2] - e1[2] * e2[0], e1[1] * e2[0] - e1[0] * e2[1]];
      const l = Math.hypot(...nn);
      if (l < 1e-12) return;
      const up = nn[1] < 0 ? -1 : 1;
      const x = (a[0] + b[0] + c[0]) / 3, h = (a[1] + b[1] + c[1]) / 3, z = (a[2] + b[2] + c[2]) / 3;
      // A crumb's own tone: a wide spread on a bed, where the soil is loose,
      // a narrow one on a path, where feet have pressed it smooth; widest of
      // all on a dug bed. Soil is crumbs, not a surface.
      const { bed, outside: o } = place.bedAt(x, z);
      const onBed = 1 - smooth(-0.02, 0.08, o);
      const spread = 0.10 + onBed * (place.sown.has(bed) ? 0.14 : 0.24);
      const tone = 1 - spread / 2 + spread * hash(key * 5.3 + GROUND.crumb);
      const colour = soil(x, z, h).map((v) => v * tone * (1 + drift(x, z)));
      tri(a, b, c, nn.map((v) => up * v / l), colour);
    };
    for (let i = 0; i < steps; i++) {
      for (let j = 0; j < steps; j++) {
        const a = grid[i][j], b = grid[i + 1][j], c = grid[i + 1][j + 1], d = grid[i][j + 1];
        const key = i * 131 + j * 37;
        if (hash(key + 0.5) < 0.5) { face(a, b, c, key); face(a, c, d, key + 0.25); }
        else { face(a, b, d, key); face(b, c, d, key + 0.25); }
      }
    }

    // In the path east of the middle bed as the table draws it, wherever the
    // plot's variant puts that.
    const trough = {
      at: [(place.centre(1, TROUGH.z).x + place.centre(2, TROUGH.z).x) / 2, TROUGH.z],
      across: TROUGH.across, deep: TROUGH.deep,
    };
    raiseTrough(e, { tri, quad }, {
      ...trough, seed: GROUND.trough, height: 0.34, base: footing(place.height, trough),
    });

    // Its side: the slab every plot hangs from its outline (`slab.js`), the
    // floor seed saying how its lower edge undulates.
    const slab = hangSide(outline, { salt: GROUND.floor });

    return {
      positions: new Float32Array(positions),
      normals: new Float32Array(normals),
      colours: new Float32Array(colours),
      side: slab,
    };
  }
  // **The stage's plant shadows lie on this soil too**, so it is told how high
  // the soil is: a shadow on a bed's shoulder follows the shoulder down.
  return Object.assign(buildHomeGround, { height: place.height });
}

// MARK: - Growing a plot

// **Letting go of the thread** between plants, the way the other nine do: a
// plot here can hold ninety.
const SLICE = 16;
const breathe = () => new Promise((resume) => setTimeout(resume, 0));

// Grows one plot from the plot service. A planting with no parents was minted
// rather than crossed — the ambassador at the head of the west bed — and grows
// from its seed alone. **The sown beds are read off the spots first**, and the
// ground built again, so the plants are grown into beds that are already raked.
export async function growGroundFromService(e, stage, place, plot, report) {
  stage.clear();
  const { plantings } = await (await fetch(`/api/ground/plot/${plot}`)).json();
  place.lay(variantFromModule(e, 'ground', plot) ?? PLAIN);
  place.sown = new Set(plantings.map((p) => bedOf(place, p.spot[0], p.spot[1])));
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
    const [x, z] = p.spot;
    stage.add(x, z, decode(takeResult(e, length)), place.height(x, z), { ...p, plot });
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

// The workbench's version: a Home Ground the module invents, for judging the
// template before anybody has released anything into it.
export async function plantVisitors(e, total, report) {
  let arrived = 0;
  let since = performance.now();
  while (arrived < total) {
    e.pg_ground_arrive();
    arrived += 1;
    if (performance.now() - since > SLICE) {
      report(`Sowing by the rule: ${arrived} of ${total} arrived`);
      await breathe();
      since = performance.now();
    }
  }
  return e.pg_ground_plots();
}

export async function growInvented(e, stage, place, plot, report) {
  stage.clear();
  const count = e.pg_ground_count(plot);
  const grown = [];
  for (let i = 0; i < count; i++) grown.push(takeResult(e, e.pg_ground_grow(plot, i)));
  const spots = grown.map((buffer) => Array.from(new Float32Array(buffer.slice(0, 8))));
  place.lay(variantFromModule(e, 'ground', plot) ?? PLAIN);
  place.sown = new Set(spots.map(([x, z]) => bedOf(place, x, z)));
  stage.rebuild();
  let since = performance.now();
  for (const [i, buffer] of grown.entries()) {
    const [x, z] = spots[i];
    stage.add(x, z, decode(buffer.slice(8)), place.height(x, z));
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

export function describeGround(e, plot) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_ground_describe(plot))));
}
