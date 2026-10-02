// Water in the Wild Fields: the hollows hold it, near a lotus.
//
// **Chosen by Marcus on 2 October 2026, from renders** (docs/WEB-GARDENS.md
// §*Water under a lotus*): of a pool dug under every lotus, a garden's pool,
// and the land holding the water, the land. The wild is unarranged and nobody
// digs it, so the water is found rather than made: it lies where the field's
// own swells would hold it.
//
// - **A hollow holds a pond once a lotus sheds water into it.** From a lotus
//   the way water would run downhill is followed to the hollow it ends in, and
//   if that is within `HOLLOW.run` of it, the hollow holds a shallow pond to
//   its own contour. The field's relief is fixed, so its hollows are known
//   before any plant is: fourteen, six of which hold the full depth.
// - **A lotus in the pond floats on it.** One a little above the water raises
//   the pond to take it in, if the hollow can hold that much.
// - **A lotus anywhere else lies in a damp patch**: the ground round it wet,
//   and water standing in the low spots between the tussocks. Most land here.
// - **Any other plant whose seed puts it in a pond stands where it stands**,
//   on a tussock that comes up just through the water, so its foot is seen
//   and nothing of it is drowned.
//
// **The water is the gardens' water.** `COLOUR.shallows` and `COLOUR.depths`,
// lit by the same sum as the field's ground, so the fireflies' light falls on
// it as it falls on grass; the stage adds what a still pond at night shows
// and a garden's water does not, the sky in it (`wildfields.js`).
//
// **How it is drawn.** The field's ground is a 0.3 m grid, and a shore drawn
// on that would be a polygon of 0.3 m sides. So where there is water the
// stage draws those cells again at under 4 cm (`wildfields.js`, `refine`),
// asking this module for the floor and the water level at every point, and
// lays water wherever the floor is below the level: the Seedbed's flooded
// drill's rule, so a shore stops of its own accord where the ground comes up
// through it rather than being cut to a drawn line.

import { COLOUR } from './longwalk.js';
import { takeResult } from './plant.js';

/// The two genus roots of the lotus (`PlantName`: few `Lir`, many `Nyx`). The
/// head is the archetype's own root, so a plant whose name starts with one of
/// these is a water lily.
export const LOTUS_HEADS = new Set(['Lir', 'Nyx']);

/// Whether a planting is a water lily, by its name: the module's, from the
/// same words the field grows it from — its seed, or its seed, both parents
/// and the meeting of noughts the field does not keep (`wildfields.js`).
export function isLotus(e, planting) {
  const lineage = planting.parents ?? [];
  const words = new TextEncoder().encode(
    lineage.length === 2 ? [planting.seed, ...lineage, '0'.repeat(64)].join(' ') : planting.seed);
  const pointer = e.pg_alloc(words.length);
  new Uint8Array(e.memory.buffer, pointer, words.length).set(words);
  const length = e.pg_name(pointer, words.length);
  e.pg_free(pointer);
  if (!length) return false;
  return LOTUS_HEADS.has(JSON.parse(new TextDecoder().decode(takeResult(e, length))).head);
}

// The colours the margin goes toward: grass that stands in wet ground, darker
// and cooler than the field's (which is already the turf at `DUSK`), and the
// silt the gardens line their water with.
const RUSH = [0.140, 0.180, 0.122];
const SILT = COLOUR.silt;

const HOLLOW = {
  // How far from a lotus the water it would shed may run and still be near.
  run: 7,
  // How deep a hollow holds water at most, and how wide a pond may be before
  // the hollow is too open to hold one: wider than this and it spills.
  depth: 0.12, area: 22,
  // How far over the water a lotus may stand and still be taken in, the pond
  // rising to five centimetres over its spot.
  raise: 0.2, over: 0.05,
  // The grid a hollow's pond is found on, and how far round it to look.
  cell: 0.1, look: 6,
  // How far the wet reaches up the bank, and the mud, in height above the
  // water.
  wet: 0.07, mud: 0.012,
  tussock: 0.022,
};

// How far the flush reaches past the pads, how much the ground between the
// tussocks dips, and how far under the ground's own level the water stands:
// water lies in about a fifth of the flush, a centimetre deep at most.
const DAMP = { past: 0.6, dip: 0.03, under: 0.007 };

// How far from a pond's water its margin reaches before it has faded out
// altogether, in metres.
const POND_ZONE = [1.0, 1.8];

// The tussock a plant in a pond stands on: how far over the water its top
// is, how wide the top, how far out it has gone under, and how far it falls
// by then: gently, so the water meets it on a slope it can draw.
const TUSSOCK = { over: 0.015, top: 0.14, foot: 0.5, under: 0.18 };

const smooth = (a, b, x) => {
  const t = Math.min(1, Math.max(0, (x - a) / (b - a)));
  return t * t * (3 - 2 * t);
};
const mix = (a, b, t) => a.map((v, k) => v + (b[k] - v) * t);

/// The field's water, given the module and the field's own ground: its size,
/// whose edges meet, and its height everywhere. The stage hands over every
/// planting the service answers (`know`) and the reach of every lotus it grows
/// (`grew`); `version` changes whenever that changed what is drawn.
export function makeWildWater(e, { side, height }) {
  const wrap = (d) => d - side * Math.round(d / side);
  const home = (v) => ((v % side) + side) % side;

  // MARK: Noise

  // A smooth value noise that comes round with the field, so a pond met again
  // across the seam is the same pond.
  function lattice(a, b, salt) {
    let h = (Math.imul(a, 374761393) + Math.imul(b, 668265263) + Math.imul(salt, 2246822519)) | 0;
    h = Math.imul(h ^ (h >>> 13), 1274126177);
    h ^= h >>> 16;
    return ((h >>> 0) / 4294967295) * 2 - 1;
  }
  function valueNoise(x, z, cell, salt) {
    const n = Math.round(side / cell), c = side / n;
    const fx = x / c, fz = z / c, ix = Math.floor(fx), iz = Math.floor(fz);
    const tx = fx - ix, tz = fz - iz;
    const sx = tx * tx * (3 - 2 * tx), sz = tz * tz * (3 - 2 * tz);
    const w = (a) => ((a % n) + n) % n;
    const v00 = lattice(w(ix), w(iz), salt), v10 = lattice(w(ix + 1), w(iz), salt);
    const v01 = lattice(w(ix), w(iz + 1), salt), v11 = lattice(w(ix + 1), w(iz + 1), salt);
    const top = v00 + (v10 - v00) * sx;
    return top + ((v01 + (v11 - v01) * sx) - top) * sz;
  }
  /// The ground's small relief, which the 0.3 m grid cannot carry: tussocks
  /// and the hollows between them, about half a metre across. Only drawn where
  /// there is water, and only near the shore, where it makes the shore wander.
  const tussock = (x, z) => 0.65 * valueNoise(x, z, 0.62, 11) + 0.35 * valueNoise(x, z, 0.27, 12);
  // A slower one for how far the wet reaches into the grass.
  const reach = (x, z) => valueNoise(x, z, 1.3, 21);
  // A finer one for the low spots in a flush, where water stands between the
  // tussocks: a hand or two across.
  const pocks = (x, z) => 0.6 * valueNoise(x, z, 0.46, 31) + 0.4 * valueNoise(x, z, 0.21, 32);

  /// An outline's wander, from a seed's own bytes: `1 + Σ a cos(hθ + φ)` over
  /// a few low harmonics, so a patch is lobed and uneven but never ragged.
  function wander(seed, amplitudes) {
    const byte = (k) => parseInt(seed.slice(8 + 2 * k, 10 + 2 * k), 16) / 255;
    const terms = amplitudes.map((a, i) => [i + 2, a * (0.5 + byte(2 * i)), byte(2 * i + 1) * 2 * Math.PI]);
    return (theta) => terms.reduce((s, [h, a, p]) => s + a * Math.cos(h * theta + p), 1);
  }

  // MARK: The hollows, known before any plant is

  /// Where water at `from` would end up: down the slope, until it stops. Null
  /// if it runs further than a lotus could be said to be near.
  function downhill(from, limit = HOLLOW.run) {
    let [x, z] = from, run = 0;
    const d = 0.01;
    for (let k = 0; k < 800; k++) {
      const gx = (height(x + d, z) - height(x - d, z)) / (2 * d);
      const gz = (height(x, z + d) - height(x, z - d)) / (2 * d);
      const g = Math.hypot(gx, gz);
      if (g < 2e-4) break;
      const step = Math.min(0.12, g * 1.5);
      x -= (gx / g) * step; z -= (gz / g) * step; run += step;
      if (run > limit) return null;
    }
    return [home(x), home(z)];
  }

  // Every hollow in the field: the bottom of each local low of its swells,
  // found on a quarter-metre grid and settled by running downhill from there.
  const hollows = (() => {
    const n = Math.round(side / 0.25), step = side / n;
    const h = new Float64Array(n * n);
    for (let j = 0; j < n; j++) for (let i = 0; i < n; i++) h[j * n + i] = height(i * step, j * step);
    const found = [];
    for (let j = 0; j < n; j++) {
      for (let i = 0; i < n; i++) {
        const v = h[j * n + i];
        let lowest = true;
        for (let dj = -1; dj <= 1 && lowest; dj++) {
          for (let di = -1; di <= 1; di++) {
            if ((di || dj) && h[((j + dj + n) % n) * n + ((i + di + n) % n)] <= v) { lowest = false; break; }
          }
        }
        if (lowest) found.push({ bottom: downhill([i * step, j * step], 2) ?? [i * step, j * step], ponds: new Map() });
      }
    }
    return found;
  })();

  const hollowOf = (bottom) => hollows.findIndex((h) =>
    Math.hypot(wrap(h.bottom[0] - bottom[0]), wrap(h.bottom[1] - bottom[1])) < 0.8);

  /// The pond a hollow holds at `wanted` — or, given none, at the deepest
  /// level up to `depth` that keeps it inside the hollow and no wider than
  /// `area`. Null if the hollow cannot hold that, or any pond at all. Kept, so
  /// a hollow is filled once a level however many lotuses ask.
  function pondAt(index, wanted = null) {
    const hollow = hollows[index];
    const key = wanted === null ? 'least' : wanted.toFixed(4);
    if (hollow.ponds.has(key)) return hollow.ponds.get(key);
    const pond = fill(hollow.bottom, wanted);
    hollow.ponds.set(key, pond);
    return pond;
  }

  function fill(bottom, wanted) {
    const n = Math.round((2 * HOLLOW.look) / HOLLOW.cell) + 1, c = (n - 1) / 2;
    const heights = new Float32Array(n * n);
    for (let j = 0; j < n; j++) {
      for (let i = 0; i < n; i++) {
        heights[j * n + i] = height(bottom[0] + (i - c) * HOLLOW.cell, bottom[1] + (j - c) * HOLLOW.cell);
      }
    }
    const floor = height(...bottom);
    const flood = (W, most) => {
      const inside = new Uint8Array(n * n);
      const stack = [c * n + c];
      inside[c * n + c] = 1;
      let count = 0;
      while (stack.length) {
        const k = stack.pop();
        count++;
        const i = k % n, j = (k - i) / n;
        if (i === 0 || j === 0 || i === n - 1 || j === n - 1) return null;
        if (count * HOLLOW.cell * HOLLOW.cell > most) return null;
        for (const q of [k - 1, k + 1, k - n, k + n]) {
          if (!inside[q] && heights[q] < W) { inside[q] = 1; stack.push(q); }
        }
      }
      return { inside, area: count * HOLLOW.cell * HOLLOW.cell };
    };
    let W, filled;
    if (wanted !== null) {
      if (wanted - floor > HOLLOW.raise) return null;
      W = wanted;
      filled = flood(W, HOLLOW.area * 1.4);
    } else {
      let lo = 0.025, hi = HOLLOW.depth;
      if (!flood(floor + lo, HOLLOW.area)) return null;
      for (let k = 0; k < 18; k++) {
        const mid = (lo + hi) / 2;
        if (flood(floor + mid, HOLLOW.area)) lo = mid; else hi = mid;
      }
      W = floor + lo;
      filled = flood(W, HOLLOW.area);
    }
    if (!filled) return null;
    const { inside } = filled;
    const at = ([x, z]) => {
      const i = Math.round(wrap(x - bottom[0]) / HOLLOW.cell + c), j = Math.round(wrap(z - bottom[1]) / HOLLOW.cell + c);
      return i >= 0 && j >= 0 && i < n && j < n && inside[j * n + i] === 1;
    };
    return {
      bottom, W, n, c, inside, area: filled.area,
      // Under its water, and by how much: a lotus floats only on enough of it.
      holds: (spot, by = 0) => at(spot) && height(...spot) < W - by,
    };
  }

  // MARK: What has arrived, and what it makes

  const known = new Map();
  let features = [];
  let tussocks = [];
  let dirty = false;
  let version = 0;
  let signature = '';

  /// Every planting the service has answered, lotus or not: a lotus decides
  /// where water lies, and any other plant may stand in it.
  function know(plantings) {
    let added = false;
    for (const p of plantings) {
      if (known.has(p.seed)) continue;
      const spot = [home(p.spot[0]), home(p.spot[1])];
      const lotus = isLotus(e, p);
      let hollow = -1;
      if (lotus) {
        const bottom = downhill(spot);
        if (bottom) hollow = hollowOf(bottom);
      }
      known.set(p.seed, { seed: p.seed, spot, lotus, hollow, reach: null });
      added = true;
    }
    if (added) dirty = true;
    return settle();
  }

  /// A lotus has been grown, so how far its pads reach is known: the size of
  /// its damp patch, if it lies in one.
  function grew(planting, padReach) {
    const record = known.get(planting.seed);
    if (!record?.lotus || record.reach === padReach) return settle();
    record.reach = padReach;
    dirty = true;
    return settle();
  }

  /// Works out the water again from everything known, and says whether what
  /// is drawn changed. **The same plants give the same water in any order**:
  /// each lotus's claim on its hollow is weighed against the hollow's own
  /// pond, and the pond takes the highest that it can hold.
  function settle() {
    if (!dirty) return false;
    dirty = false;
    const byHollow = new Map();
    for (const r of known.values()) {
      if (!r.lotus || r.hollow < 0) continue;
      if (!byHollow.has(r.hollow)) byHollow.set(r.hollow, []);
      byHollow.get(r.hollow).push(r);
    }
    const ponds = [];
    for (const [index, lotuses] of [...byHollow].sort((a, b) => a[0] - b[0])) {
      const least = pondAt(index);
      if (!least) continue;
      let W = least.W;
      for (const l of lotuses) {
        if (least.holds(l.spot, 0.02)) continue;
        const wanted = Math.round((height(...l.spot) + HOLLOW.over) * 1e4) / 1e4;
        if (wanted > W && pondAt(index, wanted)) W = wanted;
      }
      ponds.push({ index, pond: W === least.W ? least : pondAt(index, W) });
    }
    const held = (r, by) => ponds.some(({ pond }) => pond.holds(r.spot, by));
    const damp = [...known.values()].filter((r) => r.lotus && r.reach !== null && !held(r, 0.02))
      .sort((a, b) => (a.seed < b.seed ? -1 : 1));
    const standing = [...known.values()].filter((r) => !r.lotus && held(r, 0.005))
      .sort((a, b) => (a.seed < b.seed ? -1 : 1));
    const next = [
      ...ponds.map(({ index, pond }) => `p${index}@${pond.W.toFixed(4)}`),
      ...damp.map((r) => `d${r.seed.slice(0, 12)}@${r.reach.toFixed(3)}`),
      ...standing.map((r) => `t${r.seed.slice(0, 12)}`),
    ].join(' ');
    if (next === signature) return false;
    signature = next;
    features = ponds.map(({ pond }) => pondFeature(pond)).concat(damp.map(dampPatch));
    tussocks = standing.map((r) => {
      const level = ponds.find(({ pond }) => pond.holds(r.spot, 0.005)).pond.W;
      return { at: r.spot, top: level + TUSSOCK.over, shape: wander(r.seed, [0.16, 0.10, 0.06, 0.04]),
               key: `t${r.seed.slice(0, 12)}@${level.toFixed(4)}` };
    });
    version++;
    return true;
  }

  /// A hollow's pond as the ground draws it: how far each point of the grid is
  /// from the water, so the wet margin and the tussocks fade out before the
  /// fine ground ends. Kept with the pond, as it is worked out once.
  function pondFeature(pond) {
    if (pond.feature) return pond.feature;
    const { n, c, inside, W, bottom } = pond;
    // Distance to the water, in cells, by a chamfer passed both ways.
    const far = new Float32Array(n * n).fill(1e9);
    for (let k = 0; k < n * n; k++) if (inside[k]) far[k] = 0;
    const steps = [[-1, 0, 1], [0, -1, 1], [-1, -1, 1.414], [1, -1, 1.414], [1, 0, 1], [0, 1, 1], [1, 1, 1.414], [-1, 1, 1.414]];
    const pass = (forward) => {
      for (let jj = 0; jj < n; jj++) {
        const j = forward ? jj : n - 1 - jj;
        for (let ii = 0; ii < n; ii++) {
          const i = forward ? ii : n - 1 - ii, k = j * n + i;
          for (const [di, dj, d] of steps) {
            const a = i + di, b = j + dj;
            if (a < 0 || b < 0 || a >= n || b >= n) continue;
            far[k] = Math.min(far[k], far[b * n + a] + d);
          }
        }
      }
    };
    pass(true); pass(false); pass(true);
    const distance = (dx, dz) => {
      const fi = dx / HOLLOW.cell + c, fj = dz / HOLLOW.cell + c;
      const i = Math.max(0, Math.min(n - 2, Math.floor(fi))), j = Math.max(0, Math.min(n - 2, Math.floor(fj)));
      const u = Math.min(1, Math.max(0, fi - i)), v = Math.min(1, Math.max(0, fj - j));
      const f = (a, b) => far[b * n + a];
      return HOLLOW.cell * ((f(i, j) * (1 - u) + f(i + 1, j) * u) * (1 - v) + (f(i, j + 1) * (1 - u) + f(i + 1, j + 1) * u) * v);
    };
    let x0 = Infinity, z0 = Infinity, x1 = -Infinity, z1 = -Infinity;
    for (let k = 0; k < n * n; k++) {
      if (!inside[k]) continue;
      const i = k % n, j = (k - i) / n;
      x0 = Math.min(x0, (i - c) * HOLLOW.cell); x1 = Math.max(x1, (i - c) * HOLLOW.cell);
      z0 = Math.min(z0, (j - c) * HOLLOW.cell); z1 = Math.max(z1, (j - c) * HOLLOW.cell);
    }
    // The fine ground runs out to where the margin has faded.
    const margin = 2.0;
    pond.feature = {
      at: bottom, box: [x0 - margin, z0 - margin, x1 + margin, z1 + margin],
      key: `p${bottom[0].toFixed(2)},${bottom[1].toFixed(2)}@${W.toFixed(4)}`,
      covers: (dx, dz, slack) => distance(dx, dz) < POND_ZONE[1] + slack,
      sample(dx, dz, G, x, z) {
        const d = distance(dx, dz);
        const zone = 1 - smooth(POND_ZONE[0], POND_ZONE[1], d);
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
    return pond.feature;
  }

  /// A lotus on a rise: the ground round it wet, and water standing in the
  /// hollows between the tussocks, as a flush on a hillside holds it.
  function dampPatch(l) {
    const R = l.reach + DAMP.past;
    const shape = wander(l.seed, [0.12, 0.08, 0.05, 0.03]);
    return {
      at: l.spot, box: [-2 * R, -2 * R, 2 * R, 2 * R],
      key: `d${l.seed.slice(0, 12)}@${l.reach.toFixed(3)}`,
      // Its outline wanders out by at most about two fifths, and nothing of it
      // reaches past one and a half of it.
      covers: (dx, dz, slack) => Math.hypot(dx, dz) < 2.2 * R + slack,
      sample(dx, dz, G, x, z) {
        const p = Math.hypot(dx, dz) / (R * shape(Math.atan2(dz, dx)));
        if (p > 1.6) return { delta: 0 };
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

  // MARK: What the stage asks

  // Every feature whose bounds hold a point, with the point in its own frame,
  // from those given.
  function near(x, z, among = features) {
    const out = [];
    for (const f of among) {
      const dx = wrap(x - f.at[0]), dz = wrap(z - f.at[1]);
      if (dx >= f.box[0] && dx <= f.box[2] && dz >= f.box[1] && dz <= f.box[3]) out.push([f, dx, dz]);
    }
    return out;
  }

  // The features and tussocks whose bounds meet `[x0, x1] × [z0, z1]`.
  function within(x0, z0, x1, z1) {
    const meets = (at, box) => {
      const dx = wrap((x0 + x1) / 2 - at[0]), dz = wrap((z0 + z1) / 2 - at[1]);
      const hx = (x1 - x0) / 2, hz = (z1 - z0) / 2;
      return dx + hx >= box[0] && dx - hx <= box[2] && dz + hz >= box[1] && dz - hz <= box[3];
    };
    const reachOf = [-1.4 * TUSSOCK.foot, -1.4 * TUSSOCK.foot, 1.4 * TUSSOCK.foot, 1.4 * TUSSOCK.foot];
    const local = { features: features.filter((f) => meets(f.at, f.box)), tussocks: tussocks.filter((t) => meets(t.at, reachOf)) };
    // What is there, named, so a stage can tell whether it changed.
    local.key = [...local.features.map((f) => f.key), ...local.tussocks.map((t) => t.key)].sort().join(' ');
    return local;
  }

  /// The floor, the water's level and the floor's colour at a point, given
  /// the field's ground there `G` and its colour `base`; `local` is `within`'s
  /// answer for a region the point is in, to save asking every feature.
  function sample(x, z, G, base, local = null) {
    let delta = 0, level = -Infinity, wet = 0, mud = 0;
    for (const [f, dx, dz] of near(x, z, local?.features)) {
      const s = f.sample(dx, dz, G, x, z);
      delta += s.delta;
      if (s.level > level) level = s.level;
      wet = Math.max(wet, s.wet ?? 0);
      mud = Math.max(mud, s.mud ?? 0);
    }
    let floor = G + delta;
    // A plant standing in a pond stands on its tussock, which comes up
    // through the water under it and goes under again a little way out.
    let grass = 0;
    for (const t of local?.tussocks ?? tussocks) {
      const dx = wrap(x - t.at[0]), dz = wrap(z - t.at[1]);
      if (Math.hypot(dx, dz) > TUSSOCK.foot * 1.4) continue;
      // Lobed, as a tussock is, rather than turned.
      const r = Math.hypot(dx, dz) / t.shape(Math.atan2(dz, dx));
      if (r > TUSSOCK.foot) continue;
      floor = Math.max(floor, t.top - TUSSOCK.under * smooth(TUSSOCK.top, TUSSOCK.foot, r));
      grass = Math.max(grass, 1 - smooth(TUSSOCK.top, TUSSOCK.foot, r));
    }
    let colour = base;
    if (wet > 0) colour = mix(colour, RUSH, 0.5 * wet);
    if (mud > 0) colour = mix(colour, SILT, 0.7 * mud);
    if (grass > 0) colour = mix(colour, RUSH, 0.6 * grass);
    // Nothing is darkened for being under the water: the water hides the
    // floor beyond its first few millimetres, and a floor coloured by which
    // side of the shore each point of the grid fell on would draw the grid
    // along the shore, a tooth to every cell.
    return { floor, level, colour };
  }

  /// The water's colour at a point `w` under its surface: the gardens' two,
  /// lighter in the shallows where the floor shows through.
  const waterTone = (w) => mix(COLOUR.shallows, COLOUR.depths, smooth(0, 0.09, w));

  /// The field's own cells, by number, that the stage should draw finer
  /// inside `[x0, x1] × [z0, z1]`.
  /// Only the cells some feature reaches into, rather than every cell of its
  /// bounds: a pond's bounds are a box round a shape that is not one.
  ///
  /// With them, `key` names the features drawn there, so the stage can tell
  /// whether something that has arrived changed the ground it has built.
  function cells(x0, z0, x1, z1, step) {
    const keys = new Set();
    const slack = step * 0.75;
    for (const f of features) {
      for (let sx = -1; sx <= 1; sx++) {
        for (let sz = -1; sz <= 1; sz++) {
          const ax = f.at[0] + sx * side, az = f.at[1] + sz * side;
          const bx0 = Math.max(x0, ax + f.box[0]), bx1 = Math.min(x1, ax + f.box[2]);
          const bz0 = Math.max(z0, az + f.box[1]), bz1 = Math.min(z1, az + f.box[3]);
          if (bx0 > bx1 || bz0 > bz1) continue;
          for (let i = Math.floor(bx0 / step); i <= Math.floor(bx1 / step); i++) {
            for (let j = Math.floor(bz0 / step); j <= Math.floor(bz1 / step); j++) {
              if (f.covers((i + 0.5) * step - ax, (j + 0.5) * step - az, slack)) keys.add(`${i},${j}`);
            }
          }
        }
      }
    }
    return { has: (i, j) => keys.has(`${i},${j}`), key: within(x0, z0, x1, z1).key };
  }

  /// Where to look for lotuses that might fill a hollow near `[x0, x1] ×
  /// [z0, z1]`: each hollow that can hold a pond and lies within a lotus's
  /// run of it, as a point in the same unwrapped metres, and how far round it.
  function catchments(x0, z0, x1, z1) {
    const out = [];
    // A pond at its widest and its margin, which is how far from its bottom
    // a hollow can be and still be seen.
    const seen = HOLLOW.look / 2 + POND_ZONE[1];
    hollows.forEach((h, index) => {
      for (let sx = -1; sx <= 1; sx++) {
        for (let sz = -1; sz <= 1; sz++) {
          const x = h.bottom[0] + sx * side, z = h.bottom[1] + sz * side;
          if (x < x0 - seen || x > x1 + seen || z < z0 - seen || z > z1 + seen) continue;
          if (pondAt(index)) out.push({ at: [x, z], radius: HOLLOW.run });
        }
      }
    });
    return out;
  }

  /// What is seen at a point: the water if there is any, else the floor.
  function surfaceAt(x, z) {
    const { floor, level } = sample(x, z, height(x, z), [0, 0, 0]);
    return Math.max(floor, level);
  }

  /// The water's level at a point, or null where there is none.
  function levelAt(x, z) {
    const { floor, level } = sample(x, z, height(x, z), [0, 0, 0]);
    return level > floor + 0.004 ? level : null;
  }

  /// Where a plant's foot stands: a lotus on the water if there is water
  /// under it, anything else on the floor — its tussock, in a pond.
  function footAt(x, z, planting) {
    const { floor, level } = sample(x, z, height(x, z), [0, 0, 0]);
    return known.get(planting?.seed)?.lotus && level > floor ? level + 0.004 : floor;
  }

  return {
    know, grew, sample, within, waterTone, cells, catchments, surfaceAt, levelAt, footAt,
    get version() { return version; },
    // For the workbench: the hollows, and how much water each holds at least.
    hollows: () => hollows.map((h, index) => ({ at: h.bottom, floor: height(...h.bottom), least: pondAt(index)?.W ?? null })),
  };
}
