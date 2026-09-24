// A plot of the Coppice, drawn the way the app draws a plot: a floating slab
// of woodland floor seen in true isometric, leaf litter with moss in its
// hollows, two rides trodden across it, and a stool of old wood under every
// fern the rotation cuts.
//
// **The first page that draws the year.** A fern on a stool is grown at its
// coupe's stage — cut this winter, regrowing, or grown — which the service
// sends beside its spot, and its stool's cut face is pale in the winter it was
// cut and weathers grey over the two after. The page never reads its own clock:
// the stages are the service's, worked out from the date where the plants are
// kept, so two visitors either side of midnight see one wood.
//
// **The first ground that is not level.** A woodland floor rises and falls,
// gently, so no two stools stand at one height, and every plant stands on the
// floor where it is rather than on a plane under it: the stage lifts each one by
// the floor's height at its spot, and a fern on a stool by the stool's as well.
//
// **Nothing here is a straight line**: not the rides, not a stool's outline,
// not a shadow, not the rim. The rides are trodden rather than mown, so they
// are litter worn paler with no stripes, bowing and changing width, and a coupe
// has no edge but them.
//
// The rule that decides where each plant stands is SeedCore's `Coppice`,
// through the module. This file draws the floor, the rides and the stools, and
// puts each plant on the spot the service gives it; the plot's own numbers come
// from `pg_coppice_plan` rather than being written down again.

import { decode, takeResult } from './plant.js';
import { COLOUR, LIGHT, RIM_DEPTH, SIDE, hash, readOutline, readStructure } from './longwalk.js';

// Seeds for this area's dressing, its own and not another area's.
const COPPICE = { ground: 7151, floor: 47, relief: 53, litter: 67, moss: 71, width: 89,
  ride: { '-1': 79, '1': 83 } };

/// The leaf litter: the colour the map gives this area — `LOOK.renewal` in
/// `gates.js`, brought down by the quarter a plot is lit up by, as the
/// Glasshouse's tiles are.
const LITTER = [0.295, 0.232, 0.160];

/// A ride: the same litter trodden to a crumb and paler for it, and greyer,
/// because what feet break up is the brown in a leaf.
const RIDE = [0.372, 0.318, 0.246];

/// Moss, where the floor dips and the wet stands longest. Dark and yellowish,
/// a floor moss rather than a lawn: at the grass's green it read as turf
/// showing through the leaves.
const MOSS = [0.205, 0.262, 0.122];

/// A stool's bark: old wood, grey over brown, and darker than the litter's
/// lightest leaves. At the timber's brightness a stool's side, square to this
/// sun, read as a pale drum rather than as the stump of something.
const BARK = [0.235, 0.200, 0.165];

/// A stool's cut face, by its coupe's stage: fresh wood the winter it was cut,
/// weathering the year after, and grey the year the coupe is grown.
const FACE = [[0.80, 0.68, 0.48], [0.55, 0.51, 0.44], [0.35, 0.35, 0.32]];

/// How much more light each stage lets onto the floor. **A cut coupe is open**,
/// and a grown one is under its ferns, so the band cut this winter reads as the
/// glade it is even where no stool stands in it yet — which is what the
/// service's `stages` are for. Gentle, because the plants are the page.
const OPEN = [1.10, 1.0, 0.94];

/// How far the floor rises and falls either side of level, at most.
const RELIEF = 0.05;

export function plan(e) {
  const place = JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_coppice_plan())));
  // The stools in the plot on show, and each coupe's stage. Empty until a plot
  // is grown; the page fills them and asks the stage to build its ground again.
  place.stools = [];
  place.stages = null;
  // **The floor's height anywhere on the plot**, so the ground and the plants
  // agree on it. Level at the rim, where the slab's sides hang from, and rising
  // and falling inside it; the rim is where every other area's ground is.
  place.height = (x, z) => {
    const m = Math.max(Math.abs(x), Math.abs(z));
    const f = Math.min(1, Math.max(0, (2.25 - m) / 0.5));
    return RELIEF * f * f * (3 - 2 * f) * e.pg_coppice_relief(x, z, COPPICE.relief);
  };
  return place;
}

// MARK: - The ground

export function makeCoppiceGround(place) {
  return function buildCoppiceGround(farSide, span, e) {
    const positions = [], normals = [], colours = [];
    const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
    const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
    const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => {
      tri(a, b, c, n, ca, cb, cc); tri(a, c, d, n, ca, cc, cd);
    };
    const smooth = (a, b, v) => { const t = Math.min(1, Math.max(0, (v - a) / (b - a))); return t * t * (3 - 2 * t); };
    const mix = (a, b, t) => a.map((v, i) => v + (b[i] - v) * t);

    const outline = readOutline(e, SIDE, SIDE, COPPICE.ground);
    const n = outline.length;

    // **The rides.** Each wanders off its line by up to `rideWander` and
    // changes its width along its length by a few centimetres either way, with
    // the verge noise the walk's path is cut with — but trodden, so there is no
    // verge: the litter goes paler towards the middle of a ride and the edge is
    // wherever the feet stopped.
    const wander = (along, side, seed) => e.pg_verge(along, side, seed) / 0.14;
    const rideLine = (x, side) => side * place.rideZ + place.rideWander * wander(x, side, COPPICE.ride[side]);
    const rideHalf = (x, side) => place.rideWidth / 2 * (1 + 0.12 * wander(x * 1.3, side * 2, COPPICE.width));
    const trodden = (x, z, rough) => {
      let worn = 0;
      for (const side of [-1, 1]) {
        const out = Math.abs(z - rideLine(x, side)) / rideHalf(x, side) + rough;
        worn = Math.max(worn, (1 - smooth(0.62, 1.04, out)) * (0.8 + 0.2 * (1 - Math.min(1, out))));
      }
      return worn;
    };

    // **Which coupe a place is in, and how open it is**: a blend across the
    // two rides, so the change from one band's light to the next happens under
    // the feet on a ride and never along a drawn edge.
    const open = (x, z) => {
      if (!place.stages) return 1;
      const past = [-1, 1].map((side) => smooth(-rideHalf(x, side), rideHalf(x, side), z - rideLine(x, side)));
      const share = [1 - past[0], past[0] - past[1], past[1]];
      return share.reduce((sum, w, coupe) => sum + w * OPEN[place.stages[coupe]], 0);
    };

    // The floor's colour at a place, before a leaf's own tone: litter, moss in
    // the hollows, the rides worn over both, lit as its coupe is.
    const floor = (x, z, h, rough) => {
      const worn = trodden(x, z, rough);
      const moss = smooth(-0.008, -0.026, h + 0.012 * rough) * (1 - worn);
      return mix(mix(LITTER, MOSS, moss), RIDE, worn).map((v) => v * open(x, z));
    };

    // **The litter: the Knot Garden's jittered lattice, a tone to a leaf.** A
    // cell of six centimetres, which is a leaf fallen flat, over the whole
    // square, and the corners that fall off the slab moved in onto its rim, so
    // the floor and the rides run right out to the edge and meet it where it is.
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
    const cell = 0.06, half = SIDE / 2, steps = Math.ceil(SIDE / cell);
    const grid = [];
    for (let i = 0; i <= steps; i++) {
      const row = [];
      for (let j = 0; j <= steps; j++) {
        const edge = i === 0 || j === 0 || i === steps || j === steps;
        const shift = edge ? 0 : cell * 0.34;
        let x = -half + i * cell + shift * (hash(i * 7919 + j * 104729 + 3.1) - 0.5) * 2;
        let z = -half + j * cell + shift * (hash(i * 6733 + j * 92831 + 5.7) - 0.5) * 2;
        if (!inside(x, z)) [x, z] = ontoRim(x, z);
        row.push([x, place.height(x, z), z]);
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
      const rough = 0.36 * (hash(key * 3.7 + COPPICE.litter) - 0.5);
      const base = floor(x, z, h, rough);
      // A leaf's own tone: most of them the litter's brown a little lighter or
      // darker, one in eight still warm from the autumn and one in twelve
      // dark and wet. Less of all of it on a ride, where the leaves are broken.
      const worn = trodden(x, z, 0);
      const pick = hash(key * 1.3 + COPPICE.litter * 7);
      const leaf = pick < 0.125 ? [1.14, 0.95, 0.74] : pick < 0.21 ? [0.74, 0.74, 0.74] : [1, 1, 1];
      const spread = 0.34 - 0.2 * worn;
      const tone = 1 - spread / 2 + spread * hash(key * 5.3 + COPPICE.moss);
      const colour = base.map((v, k) => v * tone * (1 + (leaf[k] - 1) * (1 - worn)));
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

    // MARK: The stools
    //
    // A stool under every fern the service says stands on one, from `Organic`
    // through the module and grown from the fern's own seed: its shadow first,
    // laid on the floor, then its bark, then its cut face, coloured by its
    // coupe's stage. **A stool's shadow is its footprint moved away from the
    // light**, as a hedge's is in the app, so its edge wanders as the stool's
    // does and it follows the floor it falls on.
    const rise = Math.max(0.12, LIGHT.sun[1]);
    const away = [-LIGHT.sun[0] / rise * place.stoolHeight, -LIGHT.sun[2] / rise * place.stoolHeight];
    for (const { spot: [x, z], stage, seed } of place.stools) {
      const g = place.height(x, z);
      const foot = readFootprint(takeResult(e, e.pg_coppice_footprint(seed)));
      const shaded = (p) => {
        const px = x + p[0] + away[0], pz = z + p[1] + away[1];
        const h = place.height(px, pz);
        return [[px, h + 0.005, pz], floor(px, pz, h, 0).map((v) => v * 0.5)];
      };
      const middle = shaded([0, 0]);
      const ring = foot.map((p) => shaded([p[0] * 0.55, p[1] * 0.55]));
      const rim = foot.map(shaded);
      for (let k = 0; k < foot.length; k++) {
        const l = (k + 1) % foot.length;
        tri(middle[0], ring[l][0], ring[k][0], [0, 1, 0], middle[1], ring[l][1], ring[k][1]);
        quad(ring[k][0], ring[l][0], rim[l][0], rim[k][0], [0, 1, 0], ring[k][1], ring[l][1], rim[l][1], rim[k][1]);
      }
      set(readStructure(takeResult(e, e.pg_coppice_stool(seed))), [x, g, z], BARK, 0.22, vertex);
      set(readStructure(takeResult(e, e.pg_coppice_face(seed))), [x, g, z], FACE[stage] ?? FACE[2], 0.08, vertex);
    }

    // Its sides hang from the outline down to a floor as rough as a clod's, in
    // the app's strata. The walk's arithmetic, because it is the same slab.
    const strata = [[0, COLOUR.humus], [0.16, COLOUR.earth], [0.58, COLOUR.earth], [1, COLOUR.bedrock]];
    let around = 0;
    const bottom = outline.map((p, i) => {
      if (i > 0) around += Math.hypot(p[0] - outline[i - 1][0], p[1] - outline[i - 1][1]);
      return RIM_DEPTH * (1 + 0.22 * (e.pg_verge(around, 1, COPPICE.floor) / 0.14));
    });
    for (let i = 0; i < n; i++) {
      const j = (i + 1) % n, a = outline[i], b = outline[j];
      const dx = b[0] - a[0], dz = b[1] - a[1], l = Math.hypot(dx, dz);
      const normal = [dz / l, 0, -dx / l];
      for (let k = 0; k < strata.length - 1; k++) {
        const [f0, c0] = strata[k], [f1, c1] = strata[k + 1];
        quad([a[0], -f0 * bottom[i], a[1]], [b[0], -f0 * bottom[j], b[1]],
             [b[0], -f1 * bottom[j], b[1]], [a[0], -f1 * bottom[i], a[1]], normal, c0, c0, c1, c1);
      }
    }

    return {
      positions: new Float32Array(positions),
      normals: new Float32Array(normals),
      colours: new Float32Array(colours),
    };
  };
}

/// Where a stool meets the ground, as `pg_coppice_footprint` answers: the same
/// shape as the ground's outline.
function readFootprint(bytes) {
  const count = new DataView(bytes).getUint32(0, true);
  const xz = new Float32Array(bytes.slice(4, 4 + count * 8));
  return Array.from({ length: count }, (_, i) => [xz[i * 2], xz[i * 2 + 1]]);
}

/// A structure, moved to where it stands, with a grain across it read off where
/// each vertex is in the world, as `frame.js` sets its boards. `grain` is how far
/// the tone wanders: bark more, a cut face less.
function set(mesh, at, colour, grain, vertex) {
  for (let t = 0; t < mesh.indices.length; t += 3) {
    for (const k of [0, 1, 2]) {
      const v = mesh.indices[t + k];
      const p = [mesh.positions[v * 3] + at[0], mesh.positions[v * 3 + 1] + at[1], mesh.positions[v * 3 + 2] + at[2]];
      const nn = [mesh.normals[v * 3], mesh.normals[v * 3 + 1], mesh.normals[v * 3 + 2]];
      const tone = 1 - grain / 2 + grain * hash(Math.round(p[0] * 53) * 131 + Math.round(p[2] * 47) + Math.round(p[1] * 71));
      vertex(p, nn, colour.map((c) => c * tone));
    }
  }
}

/// The number a planting's stool is grown from: the first four bytes of its
/// seed, as `Coppice.Planting.stoolSeed` reads them, so the stool here is the
/// one drawn anywhere else.
const stoolSeed = (hex) => parseInt(hex.slice(0, 8), 16) >>> 0;

// MARK: - Growing a plot

// **Letting go of the thread** between plants, the way the other eight do.
const SLICE = 16;
const breathe = () => new Promise((resume) => setTimeout(resume, 0));

// Grows one plot from the plot service. A planting with no parents was minted
// rather than crossed — the ambassador in the first coupe — and grows from its
// seed alone. **A planting with a stage stands on a stool** and is grown at that
// stage; one without is a star, or a fern on the floor, and is grown at its
// best. The stools are set out first, so the plants are grown into a floor that
// already has them.
export async function growCoppiceFromService(e, stage, place, plot, report) {
  stage.clear();
  const { stages, plantings } = await (await fetch(`/api/coppice/plot/${plot}`)).json();
  place.stages = stages;
  place.stools = plantings.filter((p) => p.stage !== null && p.stage !== undefined)
    .map((p) => ({ spot: p.spot, stage: p.stage, seed: stoolSeed(p.seed) }));
  stage.rebuild();
  let since = performance.now();
  for (const [i, p] of plantings.entries()) {
    const lineage = p.parents ?? [];
    const staged = p.stage ?? -1;
    const words = new TextEncoder().encode(
      lineage.length === 2 ? [p.seed, ...lineage, p.encounter].join(' ') : p.seed,
    );
    const pointer = e.pg_alloc(words.length);
    new Uint8Array(e.memory.buffer, pointer, words.length).set(words);
    const length = lineage.length === 2
      ? e.pg_grow_hybrid_coppiced(pointer, words.length, staged)
      : e.pg_grow_coppiced(pointer, words.length, staged);
    e.pg_free(pointer);
    if (length === 0) continue;
    const [x, z] = p.spot;
    stage.add(x, z, decode(takeResult(e, length)), place.height(x, z) + (staged >= 0 ? place.stoolHeight : 0));
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

// The workbench's version: a Coppice the module invents, for judging the
// template before anybody has released anything into it.
export async function plantVisitors(e, total, report) {
  let arrived = 0;
  let since = performance.now();
  while (arrived < total) {
    e.pg_coppice_arrive();
    arrived += 1;
    if (performance.now() - since > SLICE) {
      report(`Planting by the rule: ${arrived} of ${total} arrived`);
      await breathe();
      since = performance.now();
    }
  }
  return e.pg_coppice_plots();
}

export async function growInvented(e, stage, place, plot, year, report) {
  stage.clear();
  const count = e.pg_coppice_count(plot);
  const grown = [];
  for (let i = 0; i < count; i++) {
    const length = e.pg_coppice_grow(plot, i, year);
    grown.push(takeResult(e, length));
  }
  // The stools first, as the service's plots are drawn: every planting with a
  // stage.
  const heads = grown.map((buffer) => ({
    spot: Array.from(new Float32Array(buffer.slice(0, 8))),
    stage: new Float32Array(buffer.slice(8, 12))[0],
    seed: new Uint32Array(buffer.slice(12, 16))[0],
  }));
  place.stages = [0, 1, 2].map((coupe) => e.pg_coppice_stage(plot, coupe, year));
  place.stools = heads.filter((head) => head.stage >= 0);
  stage.rebuild();
  let since = performance.now();
  for (const [i, buffer] of grown.entries()) {
    const { spot: [x, z], stage: staged } = heads[i];
    stage.add(x, z, decode(buffer.slice(16)), place.height(x, z) + (staged >= 0 ? place.stoolHeight : 0));
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

export function describeCoppice(e, plot) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_coppice_describe(plot))));
}
