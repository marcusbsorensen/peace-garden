// Water under a lotus in the Wild Fields: a prototype, drawn for Marcus to
// choose from pictures (2 October 2026). Only `/dev/wild?water=a|b|c` reads
// it; `/wild` passes no water and draws exactly what it drew before.
//
// docs/WEB-GARDENS.md §*Who stands beside it*, *Not built*: a water lily
// released into the field lies on grass, and whether the wild has ponds is a
// question for a render. The wild is unarranged and nobody digs it, so the
// water has to read as found rather than made. Three answers:
//
// - **`a`, a pool where it stands.** Every lotus has a seep the size of its
//   pads, at a level of its own, the uphill side cut by the water and the
//   downhill side held by a lip of turf a few centimetres high. Its margin is
//   wet grass, then mud, then shallows, and the shore wanders. Lotuses whose
//   pools touch share one.
// - **`b`, the hollow holds water.** The land decides. From each lotus the
//   way water would run downhill is followed to the hollow it ends in, and if
//   that hollow is near, it holds a shallow pond to its own contour. A lotus
//   inside the pond floats in it; a lotus on a rise lies in a damp patch, with
//   water standing in the low spots between the tussocks.
// - **`c`, the gardens' own pool.** `water.js`'s `sinkPool` with the Cold
//   Frame tank's bank, dug under each lotus as a garden digs it: round, a lip
//   of silt, the water five centimetres down. What the Cold Frame does, carried
//   out here unchanged, for comparison with two that were not made.
//
// **The water is the gardens' water.** `COLOUR.shallows` and `COLOUR.depths`,
// opaque at depth, lit by the same sum as the field's ground, so the fireflies'
// light falls on it as it falls on grass. `c` is opaque to the edge as a
// garden's is; `a` and `b` let the first few millimetres of depth thin into
// the mud, which is what makes a shore soft rather than cut.
//
// **What it does not do: the Milky Way.** The gardens' water reflects nothing
// — still water there is a colour, not a window — and the sky is a canvas of
// its own behind the stage, so there is nothing for the water to show of it.
// The fireflies are another matter: each one over water has a faint image in
// it (`flyOver`), which the gardens' water has never had.
//
// **How it is drawn.** The field's ground is a 0.3 m grid, and a shore drawn
// on that would be a polygon of 0.3 m sides. So where there is water the
// stage draws those cells again at under 4 cm (`wildfields.js`, `refine`),
// asking this module for the floor and the water level at every point, and
// lays water wherever the floor is below the level: the Seedbed's flooded
// drill's rule, so a shore stops of its own accord where the ground comes up
// through it rather than being cut to a drawn line.

import { COLOUR } from './longwalk.js';
import { SIDE, groundHeight } from './wildfields.js';

/// The two genus roots of the lotus (`PlantName`: few `Lir`, many `Nyx`). The
/// head is the archetype's own root, so a plant whose name starts with one of
/// these is a water lily.
export const LOTUS_HEADS = new Set(['Lir', 'Nyx']);

// The colours the margin goes toward: grass that stands in wet ground, darker
// and cooler than the field's (which is already the turf at `DUSK`), and the
// silt the gardens line their water with.
const RUSH = [0.140, 0.180, 0.122];
const SILT = COLOUR.silt;
// A bank the water has cut, or a garden pool was dug into: grown over, and
// wet, so the rush's green with some of the earth in it rather than bare.
const BANK = RUSH.map((v, k) => v * 0.7 + SILT[k] * 0.3);

// MARK: - Noise

// A smooth value noise that comes round with the field, so a pool met again
// across the seam is the same pool.
function lattice(a, b, salt) {
  let h = (Math.imul(a, 374761393) + Math.imul(b, 668265263) + Math.imul(salt, 2246822519)) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  h ^= h >>> 16;
  return ((h >>> 0) / 4294967295) * 2 - 1;
}

function valueNoise(x, z, cell, salt) {
  const n = Math.round(SIDE / cell), c = SIDE / n;
  const fx = x / c, fz = z / c, ix = Math.floor(fx), iz = Math.floor(fz);
  const tx = fx - ix, tz = fz - iz;
  const sx = tx * tx * (3 - 2 * tx), sz = tz * tz * (3 - 2 * tz);
  const w = (a) => ((a % n) + n) % n;
  const v00 = lattice(w(ix), w(iz), salt), v10 = lattice(w(ix + 1), w(iz), salt);
  const v01 = lattice(w(ix), w(iz + 1), salt), v11 = lattice(w(ix + 1), w(iz + 1), salt);
  return (v00 + (v10 - v00) * sx) + ((v01 + (v11 - v01) * sx) - (v00 + (v10 - v00) * sx)) * sz;
}

/// The ground's small relief, which the 0.3 m grid cannot carry: tussocks and
/// the hollows between them, about half a metre across. Only drawn where there
/// is water, and only near the shore, where it is what makes the shore wander.
const tussock = (x, z) => 0.65 * valueNoise(x, z, 0.62, 11) + 0.35 * valueNoise(x, z, 0.27, 12);
// A slower one for how far the wet reaches into the grass.
const reach = (x, z) => valueNoise(x, z, 1.3, 21);
// A finer one for the low spots in a flush, where water stands between the
// tussocks: a hand or two across.
const pocks = (x, z) => 0.6 * valueNoise(x, z, 0.46, 31) + 0.4 * valueNoise(x, z, 0.21, 32);

const smooth = (a, b, x) => {
  const t = Math.min(1, Math.max(0, (x - a) / (b - a)));
  return t * t * (3 - 2 * t);
};
const mix = (a, b, t) => a.map((v, k) => v + (b[k] - v) * t);
const wrap = (d) => d - SIDE * Math.round(d / SIDE);

/// An outline's wander, from a seed's own bytes: `1 + Σ a cos(hθ + φ)` over a
/// few low harmonics, so a pool is lobed and uneven but never ragged.
function wander(seed, amplitudes) {
  const byte = (k) => parseInt(seed.slice(8 + 2 * k, 10 + 2 * k), 16) / 255;
  const terms = amplitudes.map((a, i) => [i + 2, a * (0.5 + byte(2 * i)), byte(2 * i + 1) * 2 * Math.PI]);
  return (theta) => terms.reduce((s, [h, a, p]) => s + a * Math.cos(h * theta + p), 1);
}

// MARK: - The three

/// `kind` is `a`, `b` or `c`; `lotuses` every lotus in the field as
/// `{ seed, spot: [x, z], reach }`, where `reach` is how far its pads lie from
/// the stem, measured from the grown plant.
export function makeWildWater(kind, lotuses) {
  const features = kind === 'a' ? seeps(lotuses)
    : kind === 'b' ? hollows(lotuses)
    : kind === 'c' ? gardenPools(lotuses)
    : [];
  const soft = kind !== 'c';
  const lotusSeeds = new Set(lotuses.map((l) => l.seed));

  // Every feature whose bounds hold a point, with the point in its own frame.
  function near(x, z) {
    const out = [];
    for (const f of features) {
      const dx = wrap(x - f.at[0]), dz = wrap(z - f.at[1]);
      if (dx >= f.box[0] && dx <= f.box[2] && dz >= f.box[1] && dz <= f.box[3]) out.push([f, dx, dz]);
    }
    return out;
  }

  /// The floor, the water's level and the floor's colour at a point, given
  /// the field's ground there `G` and its colour `base`.
  function sample(x, z, G, base) {
    let delta = 0, level = -Infinity, wet = 0, mud = 0, bare = 0, deep = null, lip = 0;
    for (const [f, dx, dz] of near(x, z)) {
      const s = f.sample(dx, dz, G, x, z);
      delta += s.delta;
      if (s.level > level) { level = s.level; deep = s.deep ?? null; }
      wet = Math.max(wet, s.wet ?? 0);
      mud = Math.max(mud, s.mud ?? 0);
      bare = Math.max(bare, s.bare ?? 0);
      lip = Math.max(lip, s.lip ?? 0);
    }
    const floor = G + delta;
    let colour = base;
    if (wet > 0) colour = mix(colour, RUSH, 0.5 * wet);
    if (bare > 0) colour = mix(colour, BANK, 0.45 * bare);
    if (mud > 0) colour = mix(colour, SILT, 0.7 * mud);
    if (lip > 0) colour = mix(colour, SILT, lip);
    // Nothing is darkened for being under the water: the water hides the
    // floor beyond its first few millimetres, and a floor coloured by which
    // side of the shore each point of the grid fell on would draw the grid
    // along the shore, a tooth to every cell.
    return { floor, level, colour, deep };
  }

  /// The water's colour at a point `w` under its surface; `deep` is a
  /// feature's own say, where it has one (`c` shades by how far in from the
  /// rim, as `sinkPool`'s fan does).
  function waterTone(w, deep) {
    return mix(COLOUR.shallows, COLOUR.depths, deep ?? smooth(0, 0.09, w));
  }

  /// The field's own cells, by number, that the stage should draw finer
  /// inside `[x0, x1] × [z0, z1]`.
  function cells(x0, z0, x1, z1, step) {
    const keys = new Set();
    for (const f of features) {
      for (let sx = -1; sx <= 1; sx++) {
        for (let sz = -1; sz <= 1; sz++) {
          const ax = f.at[0] + sx * SIDE, az = f.at[1] + sz * SIDE;
          const bx0 = Math.max(x0, ax + f.box[0]), bx1 = Math.min(x1, ax + f.box[2]);
          const bz0 = Math.max(z0, az + f.box[1]), bz1 = Math.min(z1, az + f.box[3]);
          if (bx0 > bx1 || bz0 > bz1) continue;
          for (let i = Math.floor(bx0 / step); i <= Math.floor(bx1 / step); i++) {
            for (let j = Math.floor(bz0 / step); j <= Math.floor(bz1 / step); j++) keys.add(`${i},${j}`);
          }
        }
      }
    }
    return { has: (i, j) => keys.has(`${i},${j}`), size: keys.size };
  }

  /// What is seen at a point, on the field's own ground: the water if there
  /// is any, else the floor. For the feet under the plants.
  function surfaceAt(x, z) {
    const G = groundHeight(x, z);
    const { floor, level } = sample(x, z, G, [0, 0, 0]);
    return Math.max(floor, level);
  }

  /// The water's level at a point, or null where there is none: for the
  /// fireflies' reflections.
  function levelAt(x, z) {
    const G = groundHeight(x, z);
    const { floor, level } = sample(x, z, G, [0, 0, 0]);
    return level > floor + 0.004 ? level : null;
  }

  /// Where a plant's foot stands. A lotus lies on the water if there is
  /// water under it — in `c` five centimetres above it, as a lily in the Cold
  /// Frame's tank stands on the yard's level with the water below — and
  /// anything else stands on the floor, in the water if it fell in some.
  function footAt(x, z, planting) {
    const G = groundHeight(x, z);
    const near0 = near(x, z);
    const { floor, level } = sample(x, z, G, [0, 0, 0]);
    if (!lotusSeeds.has(planting?.seed)) return floor;
    if (kind === 'c') {
      const pool = near0.find(([f]) => f.rimLevel !== undefined);
      if (pool) return pool[0].rimLevel;
    }
    return level > floor ? level + 0.004 : floor;
  }

  return {
    kind, features, sample, waterTone, cells, surfaceAt, levelAt, footAt,
    // How deep the water is where it has thinned to nothing at the shore,
    // in metres; none for a garden's, which is opaque to its edge.
    feather: soft ? 0.005 : 0,
    overlay: (x0, z0, x1, z1) => overlay(features, x0, z0, x1, z1),
  };
}

// MARK: a — a pool where it stands

const SEEP = {
  // How far open water reaches past the pads, how deep it lies in the middle,
  // how steeply the uphill side is cut, and how high the turf lip is that
  // holds the downhill side.
  past: 0.26, deep: 0.12, cut: 1.0, lip: 0.035,
  // How steeply the floor crosses the level at the shore, in metres of rise
  // per pool radius.
  shelf: 0.25,
  // Where between the lowest point of the shore and the highest the water
  // lies, as a share of the shore below it.
  level: 0.3,
  // How far the tussocks rise and fall at the shore.
  tussock: 0.015,
};

function seeps(lotuses) {
  const pools = lotuses.map((l) => ({ ...l, R: l.reach + SEEP.past, wave: wander(l.seed, [0.11, 0.075, 0.05, 0.035]) }));
  return clusters(pools, (a, b) => Math.hypot(wrap(a.spot[0] - b.spot[0]), wrap(a.spot[1] - b.spot[1])) < 1.05 * (a.R + b.R))
    .map(seep);
}

function seep(members) {
  const at = members[0].spot;
  const local = members.map((m) => ({ ...m, ox: wrap(m.spot[0] - at[0]), oz: wrap(m.spot[1] - at[1]) }));
  const R = Math.max(...local.map((m) => m.R));
  // How far out a point is, in pool radii: the nearest member's, blended
  // where two meet so a shared pool has a waist rather than a crease.
  const rho = (dx, dz) => {
    let best = Infinity;
    for (const m of local) {
      const ex = dx - m.ox, ez = dz - m.oz;
      const r = Math.hypot(ex, ez) / (m.R * m.wave(Math.atan2(ez, ex)));
      best = smin(best, r, 0.35);
    }
    return best;
  };
  // **The level**: low on the shore but not at its lowest, so on a slope the
  // water has cut a little into the ground above it and is held by a lip of
  // turf below, as a seep on a hillside is, rather than lying at the foot of
  // a scrape dug level into the hill.
  const shore = [];
  for (const m of local) {
    for (let k = 0; k < 72; k++) {
      const t = (k / 72) * 2 * Math.PI, r = m.R * m.wave(t);
      const px = m.ox + Math.cos(t) * r, pz = m.oz + Math.sin(t) * r;
      if (rho(px, pz) < 0.97) continue;
      shore.push(groundHeight(at[0] + px, at[1] + pz));
    }
  }
  shore.sort((a, b) => a - b);
  const L = shore[Math.floor(shore.length * SEEP.level)];
  const extent = 2.5 * R;
  const box = [
    Math.min(...local.map((m) => m.ox)) - extent, Math.min(...local.map((m) => m.oz)) - extent,
    Math.max(...local.map((m) => m.ox)) + extent, Math.max(...local.map((m) => m.oz)) + extent,
  ];
  return {
    at, box, level: L,
    sample(dx, dz, G, x, z) {
      const p = rho(dx, dz);
      if (p > 2.4) return { delta: 0 };
      // **The floor crosses the level at the shore on a slope, never
      // flat**, so the shore is where it is and the grid cannot draw it: a
      // floor that only touched the level there would be under it and over it
      // cell by cell, and the shore would be a row of teeth.
      //
      // Inside, the dish, falling from the shore to the middle; near the
      // shore it is the dish whatever the field does, which on the downhill
      // side is the turf the water is held by.
      const dish = L - SEEP.deep * Math.pow(Math.max(0, 1 - p * p), 1.5) - SEEP.shelf * R * (1 - p);
      // Outside, the bank the water has cut into the slope above it, and on
      // the downhill side the lip of turf holding it, a few centimetres over
      // the water, which falls back to the field's own ground a little way out.
      const held = L + Math.min(SEEP.lip, SEEP.shelf * R * (p - 1));
      const floor0 = p < 1
        ? Math.min(dish, G + (dish - G) * smooth(0.5, 0.85, p))
        : Math.max(Math.min(G, L + SEEP.cut * R * (p - 1)),
                   p <= 1.3 ? held : held + (G - held) * smooth(1.3, 1.7, p));
      const fade = 1 - smooth(2.0, 2.4, p);
      const bump = smooth(0.6, 0.8, p) * (1 - smooth(1.2, 1.5, p));
      const t = tussock(x, z);
      const delta = (floor0 - G) * fade + SEEP.tussock * t * bump;
      const cutBy = Math.max(0, G - floor0) * fade;
      return {
        delta,
        level: p < 1.15 ? L : -Infinity,
        wet: 0.7 * (1 - smooth(1.0, 1.35 + 0.15 * reach(x, z), p)),
        mud: (1 - smooth(0.92, 1.08 + 0.06 * reach(x + 7, z), p)) * smooth(0.0, 0.6, -t),
        bare: smooth(0.004, 0.03, cutBy),
      };
    },
  };
}

// MARK: b — the hollow holds water

const HOLLOW = {
  // How far from a lotus the water it would shed may run and still be near.
  run: 7,
  // How deep a hollow holds water at most, and how wide a pond may be before
  // the hollow is too open to hold one: wider than this and it spills.
  depth: 0.12, area: 22,
  // The grid a hollow's pond is found on, and how far round it to look.
  cell: 0.1, look: 6,
  // How far the wet reaches up the bank, and the mud, in height above the
  // water.
  wet: 0.07, mud: 0.012,
  tussock: 0.022,
};

function hollows(lotuses) {
  // One pond a hollow, however many lotuses shed water into it.
  const ponds = [];
  for (const l of lotuses) {
    const bottom = downhill(l.spot);
    if (!bottom) continue;
    let i = ponds.findIndex((p) => Math.hypot(wrap(p.bottom[0] - bottom[0]), wrap(p.bottom[1] - bottom[1])) < 0.8);
    if (i < 0) {
      const pond = fillHollow(bottom);
      if (!pond) continue;
      ponds.push(pond);
      i = ponds.length - 1;
    }
    // In the pond if its spot is under the water; else, if the hollow is
    // only a little below it, the pond rises to take it in, as long as the
    // hollow can hold that much.
    if (!ponds[i].holds(l.spot)) ponds[i] = ponds[i].raisedTo(groundHeight(...l.spot) + 0.05) ?? ponds[i];
  }
  const damp = lotuses.filter((l) => !ponds.some((p) => p.holds(l.spot)));
  return ponds.map(pondFeature).concat(damp.map(dampPatch));
}

/// Where water at `from` would end up: down the slope, until it stops. Null
/// if it runs further than a lotus could be said to be near.
function downhill(from) {
  let [x, z] = from, run = 0;
  const e = 0.01;
  for (let k = 0; k < 600; k++) {
    const gx = (groundHeight(x + e, z) - groundHeight(x - e, z)) / (2 * e);
    const gz = (groundHeight(x, z + e) - groundHeight(x, z - e)) / (2 * e);
    const g = Math.hypot(gx, gz);
    if (g < 2e-4) break;
    const step = Math.min(0.12, g * 1.5);
    x -= (gx / g) * step; z -= (gz / g) * step; run += step;
    if (run > HOLLOW.run) return null;
  }
  return [x, z];
}

/// The pond a hollow holds: the water at the deepest level up to `depth` that
/// keeps it inside the hollow and no wider than `area`. Null if the hollow is
/// too open to hold a pond at all.
function fillHollow(bottom, wanted = null) {
  const n = Math.round((2 * HOLLOW.look) / HOLLOW.cell) + 1, c = (n - 1) / 2;
  const heights = new Float32Array(n * n);
  for (let j = 0; j < n; j++) {
    for (let i = 0; i < n; i++) {
      heights[j * n + i] = groundHeight(bottom[0] + (i - c) * HOLLOW.cell, bottom[1] + (j - c) * HOLLOW.cell);
    }
  }
  const floor = groundHeight(...bottom);
  const flood = (W) => {
    const inside = new Uint8Array(n * n);
    const stack = [c * n + c];
    inside[c * n + c] = 1;
    let count = 0;
    while (stack.length) {
      const k = stack.pop();
      count++;
      const i = k % n, j = (k - i) / n;
      if (i === 0 || j === 0 || i === n - 1 || j === n - 1) return null;
      for (const q of [k - 1, k + 1, k - n, k + n]) {
        if (!inside[q] && heights[q] < W) { inside[q] = 1; stack.push(q); }
      }
    }
    const area = count * HOLLOW.cell * HOLLOW.cell;
    return { inside, area };
  };
  const fits = (W, area = HOLLOW.area) => {
    const f = flood(W);
    return f && f.area <= area ? f : null;
  };
  let W = null, filled = null;
  if (wanted !== null) {
    filled = fits(wanted, HOLLOW.area * 1.4);
    W = filled ? wanted : null;
  } else {
    let lo = 0.025, hi = HOLLOW.depth;
    if (!fits(floor + lo)) return null;
    for (let k = 0; k < 18; k++) {
      const mid = (lo + hi) / 2;
      if (fits(floor + mid)) lo = mid; else hi = mid;
    }
    W = floor + lo;
    filled = fits(W);
  }
  if (!filled) return null;
  const pond = { bottom, W, n, c, inside: filled.inside, area: filled.area };
  pond.holds = ([x, z]) => {
    const i = Math.round(wrap(x - bottom[0]) / HOLLOW.cell + c), j = Math.round(wrap(z - bottom[1]) / HOLLOW.cell + c);
    return i >= 0 && j >= 0 && i < n && j < n && filled.inside[j * n + i] === 1 && groundHeight(x, z) < W - 0.02;
  };
  pond.raisedTo = (level) => (level > W && level - floor < 0.2 ? fillHollow(bottom, level) : null);
  return pond;
}

/// A hollow's pond as the ground draws it: how far each point of the grid is
/// from the water, so the wet margin and the tussocks can fade out before the
/// fine ground ends.
function pondFeature(pond) {
  const { n, c, inside, W, bottom } = pond;
  // Distance to the water, in cells, by a two-pass chamfer.
  const far = new Float32Array(n * n).fill(1e9);
  for (let k = 0; k < n * n; k++) if (inside[k]) far[k] = 0;
  const pass = (order) => {
    for (const j of order(n)) {
      for (const i of order(n)) {
        const k = j * n + i;
        for (const [di, dj, d] of [[-1, 0, 1], [0, -1, 1], [-1, -1, 1.414], [1, -1, 1.414], [1, 0, 1], [0, 1, 1], [1, 1, 1.414], [-1, 1, 1.414]]) {
          const a = i + di, b = j + dj;
          if (a < 0 || b < 0 || a >= n || b >= n) continue;
          far[k] = Math.min(far[k], far[b * n + a] + d);
        }
      }
    }
  };
  const up = (m) => [...Array(m).keys()], down = (m) => up(m).reverse();
  pass(up); pass(down); pass(up);
  const distance = (dx, dz) => {
    const fi = dx / HOLLOW.cell + c, fj = dz / HOLLOW.cell + c;
    const i = Math.max(0, Math.min(n - 2, Math.floor(fi))), j = Math.max(0, Math.min(n - 2, Math.floor(fj)));
    const u = Math.min(1, Math.max(0, fi - i)), v = Math.min(1, Math.max(0, fj - j));
    const f = (a, b) => far[b * n + a];
    return HOLLOW.cell * ((f(i, j) * (1 - u) + f(i + 1, j) * u) * (1 - v) + (f(i, j + 1) * (1 - u) + f(i + 1, j + 1) * u) * v);
  };
  // The fine ground runs out to where the margin has faded.
  let x0 = Infinity, z0 = Infinity, x1 = -Infinity, z1 = -Infinity;
  for (let k = 0; k < n * n; k++) {
    if (!inside[k]) continue;
    const i = k % n, j = (k - i) / n;
    x0 = Math.min(x0, (i - c) * HOLLOW.cell); x1 = Math.max(x1, (i - c) * HOLLOW.cell);
    z0 = Math.min(z0, (j - c) * HOLLOW.cell); z1 = Math.max(z1, (j - c) * HOLLOW.cell);
  }
  const margin = 2.6;
  return {
    at: bottom, box: [x0 - margin, z0 - margin, x1 + margin, z1 + margin], level: W, pond,
    sample(dx, dz, G, x, z) {
      const d = distance(dx, dz);
      const zone = 1 - smooth(1.4, 2.4, d);
      if (zone <= 0) return { delta: 0 };
      const t = tussock(x, z);
      // Tussocks only where the ground is near the water's level: that is
      // where they decide which side of the shore a point is on.
      const shore = 1 - smooth(0.03, 0.10, Math.abs(G - W));
      // And the middle a little deeper than the land's own curve, which is
      // shallow everywhere: a pond scoured by its own water.
      const scour = 0.05 * smooth(0.02, 0.12, W - G) * (1 - smooth(0, 0.15, d));
      const delta = (HOLLOW.tussock * t * shore - scour) * zone;
      const above = G + delta - W;
      return {
        delta,
        level: d < 0.5 ? W : -Infinity,
        wet: zone * (1 - smooth(0.0, HOLLOW.wet + 0.03 * reach(x, z), above)),
        mud: zone * (1 - smooth(0.0, HOLLOW.mud + 0.008 * reach(x + 5, z), above)) * (0.4 + 0.6 * smooth(0.0, 0.6, -t)),
      };
    },
  };
}

// How far the flush reaches past the pads, how much the ground between the
// tussocks dips, and how far under the ground's own level the water stands:
// water lies in about a fifth of the flush, a centimetre deep at most.
const DAMP = { past: 0.6, dip: 0.03, under: 0.007 };

/// A lotus on a rise: the ground round it wet, and water standing in the
/// hollows between the tussocks, as a flush on a hillside holds it.
function dampPatch(l) {
  const R = l.reach + DAMP.past;
  const wave = wander(l.seed, [0.12, 0.08, 0.05, 0.03]);
  const box = [-2 * R, -2 * R, 2 * R, 2 * R];
  return {
    at: l.spot, box,
    sample(dx, dz, G, x, z) {
      const p = Math.hypot(dx, dz) / (R * wave(Math.atan2(dz, dx)));
      if (p > 1.9) return { delta: 0 };
      const held = 1 - smooth(0.75, 1.05, p);
      const t = pocks(x, z);
      return {
        delta: held * DAMP.dip * t,
        // Water stands where the ground dips far enough: about one point in
        // five across the flush, and none at its edge.
        level: G - DAMP.under - 0.06 * (1 - held),
        wet: 1 - smooth(0.85, 1.3 + 0.2 * reach(x, z), p),
        mud: held * smooth(-0.05, -0.2, t),
      };
    },
  };
}

// MARK: c — the gardens' own pool

// `water.js`'s `POOL` and the Cold Frame tank's bank, at a lotus's size.
// `apron` is how far past the rim the ground stays at the rim's level before
// the bank it was dug into climbs, so the lip ring lies on level ground to its
// edge and nothing of the bank comes up through it.
const GARDEN = { lip: 0.10, deep: 0.24, surface: 0.05, bank: 0.25, past: 0.17, apron: 0.07 };

function gardenPools(lotuses) {
  const pools = lotuses.map((l) => ({ ...l, R: l.reach + GARDEN.past }));
  return clusters(pools, (a, b) => Math.hypot(wrap(a.spot[0] - b.spot[0]), wrap(a.spot[1] - b.spot[1])) < 1.05 * (a.R + b.R))
    .map(gardenPool);
}

function gardenPool(members) {
  const first = members[0].spot;
  const offs = members.map((m) => [wrap(m.spot[0] - first[0]), wrap(m.spot[1] - first[1])]);
  const mid = [offs.reduce((s, o) => s + o[0], 0) / offs.length, offs.reduce((s, o) => s + o[1], 0) / offs.length];
  const at = [first[0] + mid[0], first[1] + mid[1]];
  const R = Math.max(...members.map((m, i) => Math.hypot(offs[i][0] - mid[0], offs[i][1] - mid[1]) + m.R));
  // Hewn, not turned: the few per cent `roundOutline` wanders by.
  const wave = wander(members[0].seed, [0.018, 0.012, 0.008, 0.005]);
  const edgeAt = (t) => R * wave(t);
  const rimAt = (t) => edgeAt(t) + GARDEN.lip;
  let lowest = Infinity;
  for (let k = 0; k < 96; k++) {
    const t = (k / 96) * 2 * Math.PI, r = rimAt(t);
    lowest = Math.min(lowest, groundHeight(at[0] + Math.cos(t) * r, at[1] + Math.sin(t) * r));
  }
  const rim = lowest - 0.003;
  const extent = R + GARDEN.lip + 1.4;
  return {
    at, box: [-extent, -extent, extent, extent], rimLevel: rim, edgeAt, rimAt,
    sample(dx, dz, G) {
      const r = Math.hypot(dx, dz), t = Math.atan2(dz, dx);
      const edge = edgeAt(t), outer = rimAt(t);
      if (r > extent) return { delta: 0 };
      // The dish falling within `bank` of the edge, as the tank's does; the
      // lip level from the edge to the rim; and past the rim, where the
      // field climbs, the bank the pool was dug into.
      let floor;
      if (r <= edge) floor = rim - GARDEN.deep * Math.min(1, (edge - r) / GARDEN.bank);
      else if (r <= outer + GARDEN.apron) floor = rim;
      else floor = Math.min(G, rim + 0.6 * (r - outer - GARDEN.apron));
      const fade = 1 - smooth(extent - 0.3, extent, r);
      const delta = (floor - G) * fade;
      return {
        delta,
        level: r < edge ? rim - GARDEN.surface : -Infinity,
        deep: 1 - Math.min(1, r / edge),
        // The silt is under the lip ring (`overlay`) and inside it, so the
        // ring's outer edge is the line between silt and grass.
        lip: r <= edge + GARDEN.lip * 0.5 ? 1 : 0,
        bare: r > outer ? smooth(0.004, 0.03, (G - floor) * fade) : 0,
      };
    },
  };
}

/// The lip of each garden pool, laid over its floor as `sinkPool` lays its
/// rim: a ring of silt between the water's edge and the rim, its outer edge
/// drawn exactly rather than left to the grid.
function overlay(features, x0, z0, x1, z1) {
  const positions = [], normals = [], colours = [];
  const steps = 96;
  for (const f of features) {
    if (f.rimLevel === undefined) continue;
    for (let sx = -1; sx <= 1; sx++) {
      for (let sz = -1; sz <= 1; sz++) {
        const ax = f.at[0] + sx * SIDE, az = f.at[1] + sz * SIDE;
        if (ax + f.box[2] < x0 || ax + f.box[0] > x1 || az + f.box[3] < z0 || az + f.box[1] > z1) continue;
        const y = f.rimLevel + 0.003;
        for (let k = 0; k < steps; k++) {
          const t0 = (k / steps) * 2 * Math.PI, t1 = ((k + 1) / steps) * 2 * Math.PI;
          const a = [ax + Math.cos(t0) * f.rimAt(t0), y, az + Math.sin(t0) * f.rimAt(t0)];
          const b = [ax + Math.cos(t1) * f.rimAt(t1), y, az + Math.sin(t1) * f.rimAt(t1)];
          const c = [ax + Math.cos(t1) * f.edgeAt(t1), y, az + Math.sin(t1) * f.edgeAt(t1)];
          const d = [ax + Math.cos(t0) * f.edgeAt(t0), y, az + Math.sin(t0) * f.edgeAt(t0)];
          for (const v of [a, b, c, a, c, d]) { positions.push(...v); normals.push(0, 1, 0); colours.push(...SILT); }
        }
      }
    }
  }
  return positions.length ? { positions: new Float32Array(positions), normals: new Float32Array(normals),
                              colours: new Float32Array(colours) } : null;
}

// MARK: - Arithmetic

/// Groups of things that touch, by `touching`, transitively.
function clusters(items, touching) {
  const parent = items.map((_, i) => i);
  const find = (i) => (parent[i] === i ? i : (parent[i] = find(parent[i])));
  for (let i = 0; i < items.length; i++) {
    for (let j = i + 1; j < items.length; j++) {
      if (touching(items[i], items[j])) parent[find(i)] = find(j);
    }
  }
  const groups = new Map();
  items.forEach((item, i) => {
    const root = find(i);
    if (!groups.has(root)) groups.set(root, []);
    groups.get(root).push(item);
  });
  return [...groups.values()];
}

/// A smooth minimum: two pools that meet run into one another with a waist.
function smin(a, b, k) {
  if (!Number.isFinite(a)) return b;
  const h = Math.max(k - Math.abs(a - b), 0) / k;
  return Math.min(a, b) - (h * h * k) / 4;
}
