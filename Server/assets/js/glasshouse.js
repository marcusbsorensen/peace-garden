// A plot of the Glasshouse, drawn the way the app draws a plot: a floating slab
// of ground seen in true isometric, laid with quarry tiles, a round house of
// painted bars and glass standing on it, a ring of slatted staging round its
// inside with a clay pot under every plant on it, and a round soil bed in the
// middle under the crown of the dome.
//
// **The colour wheel, since 2 October 2026** (option A of
// `design/garden-layouts-2026-10-02/RESEARCH.md`): the twelve bands of hue go
// round the staging, blue-green just past the door to yellow just before it,
// and the door is in the gap between, the green these plants avoid. It was a
// span house with straight staging along its sunny side until then.
//
// **The first page whose plants do not all stand on the ground.** Three in four
// of them are potted on the staging, 0.83 m off the floor, and the service says
// so: a planting here carries a `lift` beside its spot, and the stage stands the
// plant that far up. A pot is drawn under every planting with a lift, so the
// ground is built again for each plot — a staging with eleven pots on it is not
// one with twenty.
//
// **The glass is the Cold Frame's, a whole house of it.** It is handed to the
// stage as `glass` and drawn after the plants, blended and without writing
// depth, so everything under the roof is seen through it.
//
// The rule that decides where each plant stands is SeedCore's `Glasshouse`,
// through the module. This file draws the floor, the bed and the trough, sets
// the module's house, staging and pots where they stand, and puts each plant on
// the spot the service gives it. The plot's own numbers come from
// `pg_glasshouse_plan`, and the outlines it draws to — the wall, the staging's
// line and the bed — from the place table the rule reads its places from
// (`tables/glasshouse_wheel.js`), so the floor cannot disagree with the house.

import { decode, takeResult } from './plant.js';
import { COLOUR, SIDE, hash, keepToPlot, readOutline, readStructure } from './longwalk.js';
import { hangSide } from './slab.js';
import { glasshouseWheel } from './tables/glasshouse_wheel.js';

// Seeds for this area's dressing, its own and not another area's.
const GLASS_SEED = { ground: 6421, floor: 43, tile: 61, soil: 89, border: 97, frame: 1511,
  glass: 1523, staging: 1549, pot: 1571, trough: 1583, band: 1597 };

/// The floor: quarry tiles, the colour the map gives this area — `LOOK.light` in
/// `gates.js`, brought down by the quarter a plot is lit up by. A glasshouse
/// floor is tiled or bricked so it can be damped down on a hot day, and the
/// water held in it keeps the air moist.
const TILE = [0.433, 0.282, 0.210];

/// A clay pot, fresher and oranger than the floor it stands above: a new pot is
/// the colour of the clay, and a tile has been walked on.
const POT = [0.60, 0.355, 0.24];

/// The compost in a pot, darker than the bed's soil because it is kept
/// watered.
const COMPOST = [0.215, 0.170, 0.130];

/// The bed's soil: the Cold Frame's, a bed's own ground rather than the floor
/// round it.
const SOIL = [0.300, 0.240, 0.180];

/// The staging: deal, weathered paler than the bench's oak, as the Cold Frame's
/// boards are, and for their reason — at `COLOUR.timber` its underside, facing
/// away from this sun, went nearly black against the floor.
const BOARD = [0.64, 0.57, 0.47];

/// The house's bars, painted, as a glasshouse's timber always is.
const BAR = [0.82, 0.81, 0.76];

/// The glass: the sky it reflects, faint. The Cold Frame's at 7% had one layer
/// of glass over its plants; here there are two or three between the eye and
/// anything under the roof — the dome itself, and the wall on the near side
/// and the far — so each is fainter, and the laps and the ripple are what show
/// it is there.
const GLASS = [0.78, 0.85, 0.92];
const GLASS_OPACITY = 0.05;

/// **The painted band along the staging** (Marcus, 2 October 2026): a thin
/// strip of colour painted by hand along the top of the staging's outer slat,
/// the one by the glass, under the pots' rims, shading through the twelve bands
/// of hue round the ring in the order the pots stand in them. So the colour
/// wheel reads at a glance with only a few plants on it, or none in flower.
/// **On the outer slat, as the research's sketch drew it**: from the page's
/// eye the near half of the ring shows its outer edge and the far half shows
/// over its own staging, so the whole wheel reads; on the front slat the near
/// half was hidden behind its own boards. Where it lies across the ring
/// (`offset`, the outer slat's middle, from the staging's middle line), how
/// wide its paint is either side of that, how far the paint feathers into the
/// boards, how far each edge wanders, how far it stands off the slat, the step
/// it is laid in, and how long it takes to thin to nothing at each end. How
/// strong and how light its colour is: chalky, softer than the flowers it keys.
const BAND = { offset: 0.1575, half: 0.024, feather: 0.009, wander: 0.006, lift: 0.0015,
  step: 0.02, ends: 0.09, saturation: 0.50, value: 0.78 };

/// The trough under the staging: how wide it is across the ring, how thick its
/// stone, how high it stands, and how far below its lip the water lies. Narrow
/// enough to stand between the staging's legs.
const TROUGH = { across: 0.24, wall: 0.045, height: 0.30, freeboard: 0.05, from: -1.1, to: 1.1 };

export function plan(e) {
  const place = JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_glasshouse_plan())));
  // Where the pots stand in the plot on show, as [x, z]. Empty until a plot is
  // grown; the page fills it and asks the stage to build its ground again.
  place.pots = [];
  return place;
}

// MARK: - The outlines

/// A closed outline the table lays by turn — point `i` at turn `i / n` — read
/// back as its radius at any turn, so the floor can ask how far out the wall or
/// the bed is in any direction.
function byTurn(points) {
  const radii = points.map(([x, z]) => Math.hypot(x, z));
  const n = radii.length;
  return (turn) => {
    const at = (((turn % 1) + 1) % 1) * n;
    const i = Math.floor(at), t = at - i;
    return radii[i % n] * (1 - t) + radii[(i + 1) % n] * t;
  };
}

/// Which way a point lies from the middle, as a turn from `x+` toward `z+`.
const turnOf = (x, z) => {
  const t = Math.atan2(z, x) / (2 * Math.PI);
  return t < 0 ? t + 1 : t;
};

/// The table's outlines: the wall, the bed, and the staging's middle line.
export function outlines() {
  const curve = (name) => glasshouseWheel.curves[name][0].points;
  return { wall: byTurn(curve('house')), bed: byTurn(curve('bed')), line: curve('staging') };
}

// MARK: - The ground

export function makeGlasshouseGround(place) {
  function buildGlasshouseGround(farSide, span, e) {
    const positions = [], normals = [], colours = [];
    const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
    const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
    const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => {
      tri(a, b, c, n, ca, cb, cc); tri(a, c, d, n, ca, cc, cd);
    };
    const UP = [0, 1, 0];
    const { wall, bed, line } = outlines();

    const outline = readOutline(e, SIDE, SIDE, GLASS_SEED.ground);
    const n = outline.length;
    for (let i = 0; i < n; i++) {
      const a = outline[i], b = outline[(i + 1) % n];
      tri([0, 0, 0], [a[0], 0, a[1]], [b[0], 0, b[1]], UP, TILE);
    }

    const drift = (x, z) => 1
      + 0.05 * (e.pg_verge(x * 0.62, -1, GLASS_SEED.ground) / 0.14)
      + 0.05 * (e.pg_verge(z * 0.54, 1, GLASS_SEED.ground) / 0.14);
    const tileTone = (seed, p) => TILE.map((v) => v * drift(p[0], p[1]) * (0.88 + 0.22 * hash(seed + GLASS_SEED.tile)));
    const inside = (x, z, edge) => Math.hypot(x, z) < edge(turnOf(x, z));

    // **Outside the house: the Knot Garden's jittered lattice, a tone to a
    // tile.** A quarry-tile floor is a grid by nature, and a ruled grid is the
    // one thing this garden does not draw — so the corners are nudged off
    // true, each tile takes its own tone, and the lines between them are where
    // one tone meets the next rather than lines at all. A tile a little under
    // a third of a metre, which is what a quarry tile is. **Laid a little
    // wider than the plot and kept to it** (`keepToPlot`), and kept outside
    // the wall, where the house's own floor takes over.
    const half = SIDE / 2 + 0.06;
    const onPlot = keepToPlot(outline);
    const cell = 0.29, steps = Math.ceil((2 * half) / cell);
    const grid = [];
    for (let i = 0; i <= steps; i++) {
      const row = [];
      for (let j = 0; j <= steps; j++) {
        const edge = i === 0 || j === 0 || i === steps || j === steps;
        const shift = edge ? 0 : cell * 0.12;
        row.push(onPlot(
          Math.max(-half, Math.min(half, -half + i * cell + shift * (hash(i * 7919 + j * 104729 - half * 1e3) - 0.5) * 2)),
          Math.max(-half, Math.min(half, -half + j * cell + shift * (hash(i * 6733 + j * 92831 - half * 1e3) - 0.5) * 2)),
        ));
      }
      grid.push(row);
    }
    const flat = (p, lift) => [p[0], lift, p[1]];
    for (let i = 0; i < steps; i++) {
      for (let j = 0; j < steps; j++) {
        const a = grid[i][j], b = grid[i + 1][j], c = grid[i + 1][j + 1], d = grid[i][j + 1];
        if (inside((a[0] + c[0]) / 2, (a[1] + c[1]) / 2, (t) => wall(t) + 0.04)) continue;
        const seed = i * 131 + j * 37;
        if (hash(i * 31 + j * 17 + 30) < 0.5) {
          tri(flat(a, 0.003), flat(b, 0.003), flat(c, 0.003), UP, tileTone(seed, a));
          tri(flat(a, 0.003), flat(c, 0.003), flat(d, 0.003), UP, tileTone(seed + 1, c));
        } else {
          tri(flat(a, 0.003), flat(b, 0.003), flat(d, 0.003), UP, tileTone(seed + 2, a));
          tri(flat(b, 0.003), flat(c, 0.003), flat(d, 0.003), UP, tileTone(seed + 3, c));
        }
      }
    }

    // **Inside: the same tiles laid in rings**, from the bed out to the wall,
    // as a round floor is laid. Each ring follows the bed's wander on its
    // inside and the wall's on its outside, so no two are the same width all
    // the way round; each tile is cut where its own joint falls, a little off
    // even, and the joints of one ring fall where they will against the next,
    // as a floor laid by eye has them.
    const rings = 5;
    const at = (turn, f) => {
      const r = bed(turn) + (wall(turn) - bed(turn)) * f;
      return [Math.cos(turn * 2 * Math.PI) * r, Math.sin(turn * 2 * Math.PI) * r];
    };
    for (let k = 0; k < rings; k++) {
      const f0 = k / rings, f1 = (k + 1) / rings;
      const middle = place.bedRadius + (place.radius - place.bedRadius) * (f0 + f1) / 2;
      const count = Math.max(8, Math.round((2 * Math.PI * middle) / 0.29));
      const phase = hash(k * 977 + 5);
      const joint = (j) => (j + phase + (j % count === 0 ? 0 : 0.3 * (hash(k * 389 + (j % count) * 53) - 0.5))) / count;
      for (let j = 0; j < count; j++) {
        const t0 = joint(j), t1 = joint(j + 1);
        const tone = tileTone(k * 4099 + j * 61 + 7, at(t0, f0));
        const pieces = Math.max(2, Math.ceil(((t1 - t0) * 2 * Math.PI * middle) / 0.06));
        for (let s = 0; s < pieces; s++) {
          const ta = t0 + ((t1 - t0) * s) / pieces, tb = t0 + ((t1 - t0) * (s + 1)) / pieces;
          quad(flat(at(ta, f0), 0.004), flat(at(ta, f1), 0.004), flat(at(tb, f1), 0.004), flat(at(tb, f0), 0.004),
               UP, tone);
        }
      }
    }

    // **The bed: soil, in a round in the middle**, its edge cut by hand: the
    // table's wandering outline. Laid as the border's soil was, in small
    // tones, on a fine jittered lattice kept to the bed.
    const soilCell = 0.045, reach = place.bedRadius + 0.08, soilSteps = Math.ceil((2 * reach) / soilCell);
    const soil = [];
    for (let i = 0; i <= soilSteps; i++) {
      const row = [];
      for (let j = 0; j <= soilSteps; j++) {
        const x = -reach + i * soilCell + soilCell * 0.34 * (hash(i * 7919 + j * 104729 + 17) - 0.5) * 2;
        const z = -reach + j * soilCell + soilCell * 0.34 * (hash(i * 6733 + j * 92831 + 17) - 0.5) * 2;
        // Pulled in to the bed's edge where it would run past it, so the bed
        // ends on its own outline rather than on the lattice's steps.
        const r = Math.hypot(x, z), edge = bed(turnOf(x, z));
        row.push(r > edge ? [x * edge / r, z * edge / r] : [x, z]);
      }
      soil.push(row);
    }
    for (let i = 0; i < soilSteps; i++) {
      for (let j = 0; j < soilSteps; j++) {
        const a = soil[i][j], b = soil[i + 1][j], c = soil[i + 1][j + 1], d = soil[i][j + 1];
        if (![a, b, c, d].some(([x, z]) => inside(x, z, (t) => bed(t) - 0.001))) continue;
        for (const [k, [p, q, r]] of [[a, b, c], [a, c, d]].entries()) {
          const tone = SOIL.map((v) => v * drift(p[0], p[1])
            * (0.92 + 0.14 * hash(i * 131 + j * 37 + k * 7 + GLASS_SEED.soil)));
          tri(flat(p, 0.006), flat(q, 0.006), flat(r, 0.006), UP, tone);
        }
      }
    }

    // MARK: The house, the staging and the pots
    //
    // Meshes from `Organic`, each built where it stands: the house round the
    // middle of the plot, the staging round inside it, and a pot and its
    // compost under every potted plant in the plot on show. The glass is
    // gathered and handed back on its own.
    set(readStructure(takeResult(e, e.pg_glasshouse_frame(GLASS_SEED.frame))), [0, 0, 0], BAR, 0.06, vertex);
    set(readStructure(takeResult(e, e.pg_glasshouse_staging(GLASS_SEED.staging))), [0, 0, 0], BOARD, 0.24, vertex);
    // **A trough under the staging**, where a glasshouse keeps its water: at
    // hand for the can, out of the way of the walk, and warmed by the house so
    // it is never cold on a seedling's roots. Stone and standing on the tiles,
    // because the Glasshouse is partway up the garden and water there is held
    // rather than found. Bent to the ring, under its `x+` side, low enough to
    // clear the boards and narrow enough to stand between the legs.
    raiseRingTrough(e, { tri, quad }, line);
    // **The painted band**, along the staging by the glass, under the pots.
    paintBand(e, { quad }, line, place);
    // **A threshold stone across the doorway**, half in and half out, worn
    // to a rounded slab: where the floor is walked most, and what tells the
    // eye from any side that the gap in the wall is the way in.
    layThreshold(e, { tri, quad }, wall(place.doorTurn), place);
    // Three pots and three fillings, turned out of three seeds and handed out
    // by where each stands, so the staging is not one pot twenty-four times.
    const pots = [0, 1, 2].map((k) => readStructure(takeResult(e, e.pg_glasshouse_pot(GLASS_SEED.pot + k))));
    const fills = [0, 1, 2].map((k) => readStructure(takeResult(e, e.pg_glasshouse_soil(GLASS_SEED.pot + k))));
    for (const [x, z] of place.pots) {
      const k = Math.floor(hash(Math.round(x * 97) * 131 + Math.round(z * 89)) * 3) % 3;
      set(pots[k], [x, place.stagingTop, z], POT, 0.12, vertex);
      set(fills[k], [x, place.stagingTop, z], COMPOST, 0.1, vertex);
    }

    const glass = { positions: [], normals: [], colours: [] };
    const glassVertex = (p, nn, c) => { glass.positions.push(...p); glass.normals.push(...nn); glass.colours.push(...c); };
    set(readStructure(takeResult(e, e.pg_glasshouse_glass(GLASS_SEED.glass))), [0, 0, 0], GLASS, 0, glassVertex);

    // Its side: the slab every plot hangs from its outline (`slab.js`), the
    // floor seed saying how its lower edge undulates.
    const slab = hangSide(outline, { salt: GLASS_SEED.floor });

    return {
      positions: new Float32Array(positions),
      normals: new Float32Array(normals),
      colours: new Float32Array(colours),
      side: slab,
      glass: {
        positions: new Float32Array(glass.positions),
        normals: new Float32Array(glass.normals),
        colours: new Float32Array(glass.colours),
        opacity: GLASS_OPACITY,
      },
    };
  }
  // **What a potted plant's shadow lies on**: the compost in its pot, 7.5 cm
  // from the middle to the wall and domed 6 mm (`Organic.potSoil`). Kept
  // inside it, and a little over the dome, so it never hangs past the rim.
  return Object.assign(buildGlasshouseGround, { seat: { radius: 0.068, rise: 0.008 } });
}

/// The threshold: a slab of stone a little wider than the doorway, its outline
/// a wandering oval, standing 3.5 cm proud of the tiles across the wall line.
function layThreshold(e, { tri, quad }, wallAt, place) {
  const a = place.doorTurn * 2 * Math.PI;
  const out = [Math.cos(a), Math.sin(a)], along = [-out[1], out[0]];
  const centre = [out[0] * wallAt, out[1] * wallAt];
  const high = 0.035, steps = 40;
  const rim = Array.from({ length: steps }, (_, k) => {
    const t = (k / steps) * 2 * Math.PI;
    const wander = 1 + 0.06 * (e.pg_verge(k * 0.31, 2, GLASS_SEED.trough + 7) / 0.14);
    const u = Math.cos(t) * (place.doorHalf + 0.08) * wander, v = Math.sin(t) * 0.17 * wander;
    return [centre[0] + along[0] * u + out[0] * v, centre[1] + along[1] * u + out[1] * v];
  });
  const top = COLOUR.stone.map((c) => c * 1.18), face = COLOUR.stone.map((c) => c * 0.95);
  for (let k = 0; k < steps; k++) {
    const p = rim[k], q = rim[(k + 1) % steps];
    tri([centre[0], high, centre[1]], [q[0], high, q[1]], [p[0], high, p[1]], [0, 1, 0], top);
    let nx = q[1] - p[1], nz = -(q[0] - p[0]);
    const len = Math.hypot(nx, nz) || 1;
    nx /= len; nz /= len;
    if (nx * (p[0] - centre[0]) + nz * (p[1] - centre[1]) < 0) { nx = -nx; nz = -nz; }
    quad([p[0], 0, p[1]], [q[0], 0, q[1]], [q[0], high, q[1]], [p[0], high, p[1]], [nx, 0, nz], face);
  }
}

/// **The trough, bent to the ring of staging**: a channel of stone along the
/// staging's middle line, `TROUGH.from` to `TROUGH.to` metres either side of
/// the line's point nearest `x+`, its two ends rounded, its walls wandering a
/// few millimetres as hewn stone does, and water a hand's width under the lip.
/// `water.js`'s troughs are fanned from a middle and so cannot bend; this one is
/// walked along its line instead.
function raiseRingTrough(e, { tri, quad }, line) {
  // The line walked by length, and the point on it nearest `x+`.
  const run = [0];
  for (let i = 1; i < line.length; i++) {
    run.push(run[i - 1] + Math.hypot(line[i][0] - line[i - 1][0], line[i][1] - line[i - 1][1]));
  }
  let middle = 0;
  for (let i = 1; i < line.length; i++) if (line[i][0] > line[middle][0]) middle = i;
  const pointAt = (s) => {
    let i = 1;
    while (i < line.length - 1 && run[i] < s) i++;
    const t = (s - run[i - 1]) / (run[i] - run[i - 1] || 1);
    const [ax, az] = line[i - 1], [bx, bz] = line[i];
    const x = ax + (bx - ax) * t, z = az + (bz - az) * t, r = Math.hypot(x, z);
    return { x, z, ox: x / r, oz: z / r };
  };
  const steps = 36, cap = 8;
  const from = run[middle] + TROUGH.from, to = run[middle] + TROUGH.to;
  const hewn = (k, side) => 0.004 * (e.pg_verge(k * 0.07, side, GLASS_SEED.trough) / 0.14);
  // Each side's points along the length, then each end round in a half circle:
  // one closed loop at `half` from the line, read at a given width.
  const loop = (half) => {
    const out = [];
    const side = (sign) => {
      const pts = [];
      for (let k = 0; k <= steps; k++) {
        const p = pointAt(from + ((to - from) * k) / steps);
        const w = half + hewn(k, sign);
        pts.push([p.x + p.ox * w * sign, p.z + p.oz * w * sign]);
      }
      return pts;
    };
    const end = (s, sign) => {
      const p = pointAt(s), ahead = pointAt(s + 0.01 * sign);
      const tx = (ahead.x - p.x) / 0.01 * sign, tz = (ahead.z - p.z) / 0.01 * sign;
      const len = Math.hypot(tx, tz) || 1;
      const pts = [];
      for (let k = 1; k < cap; k++) {
        const a = (Math.PI * k) / cap;
        const across = Math.cos(a) * half * sign, along = Math.sin(a) * half;
        pts.push([p.x + p.ox * across + (tx / len) * along * sign, p.z + p.oz * across + (tz / len) * along * sign]);
      }
      return pts;
    };
    out.push(...side(1), ...end(to, 1), ...side(-1).reverse(), ...end(from, -1));
    return out;
  };
  const outer = loop(TROUGH.across / 2), inner = loop(TROUGH.across / 2 - TROUGH.wall);
  const lip = TROUGH.height, level = lip - TROUGH.freeboard;
  const face = COLOUR.stone, foot = COLOUR.stone.map((c) => c * 0.82);
  const top = COLOUR.stone.map((c) => c * 1.08), within = COLOUR.stone.map((c) => c * 0.7);
  const m = outer.length;
  for (let i = 0; i < m; i++) {
    const a = outer[i], b = outer[(i + 1) % m], ai = inner[i], bi = inner[(i + 1) % m];
    let nx = b[1] - a[1], nz = -(b[0] - a[0]);
    const len = Math.hypot(nx, nz) || 1;
    nx /= len; nz /= len;
    // Outward from the loop: away from the inner loop's matching point.
    if (nx * (a[0] - ai[0]) + nz * (a[1] - ai[1]) < 0) { nx = -nx; nz = -nz; }
    quad([a[0], 0, a[1]], [b[0], 0, b[1]], [b[0], lip, b[1]], [a[0], lip, a[1]], [nx, 0, nz], foot, foot, face, face);
    quad([a[0], lip, a[1]], [b[0], lip, b[1]], [bi[0], lip, bi[1]], [ai[0], lip, ai[1]], [0, 1, 0], top);
    quad([ai[0], lip, ai[1]], [bi[0], lip, bi[1]], [bi[0], level, bi[1]], [ai[0], level, ai[1]], [-nx, 0, -nz], within);
  }
  // The water: a strip between the inner loop's two long sides, and a fan
  // across each rounded end.
  const sideA = inner.slice(0, steps + 1);
  const sideB = inner.slice(steps + cap, 2 * steps + cap + 1).reverse();
  const wet = (p) => [p[0], level, p[1]];
  for (let k = 0; k < steps; k++) {
    const a = sideA[k], b = sideA[k + 1], c = sideB[k + 1], d = sideB[k];
    quad(wet(a), wet(b), wet(c), wet(d), [0, 1, 0], COLOUR.shallows, COLOUR.shallows, COLOUR.depths, COLOUR.depths);
  }
  for (const [startAt, endAt, pivot] of [[steps, steps + cap, sideA[steps]], [2 * steps + cap, inner.length, sideA[0]]]) {
    for (let k = startAt; k < endAt; k++) {
      const a = inner[k], b = inner[(k + 1) % inner.length];
      tri([pivot[0], level, pivot[1]], [a[0], level, a[1]], [b[0], level, b[1]], [0, 1, 0], COLOUR.shallows);
    }
  }
}

/// A line walked by length: how long it is, and where it is a given length
/// along, with the way out from the middle of the house there.
function walk(line) {
  const run = [0];
  for (let i = 1; i < line.length; i++) {
    run.push(run[i - 1] + Math.hypot(line[i][0] - line[i - 1][0], line[i][1] - line[i - 1][1]));
  }
  const at = (s) => {
    let i = 1;
    while (i < line.length - 1 && run[i] < s) i++;
    const t = (s - run[i - 1]) / (run[i] - run[i - 1] || 1);
    const [ax, az] = line[i - 1], [bx, bz] = line[i];
    const x = ax + (bx - ax) * t, z = az + (bz - az) * t, r = Math.hypot(x, z);
    return { x, z, ox: x / r, oz: z / r };
  };
  // How far along the line the point of it nearest `[x, z]` is.
  const along = ([x, z]) => {
    let best = Infinity, found = 0;
    for (let i = 1; i < line.length; i++) {
      const [ax, az] = line[i - 1], [bx, bz] = line[i];
      const dx = bx - ax, dz = bz - az;
      const t = Math.min(1, Math.max(0, ((x - ax) * dx + (z - az) * dz) / (dx * dx + dz * dz || 1)));
      const d = Math.hypot(ax + dx * t - x, az + dz * t - z);
      if (d < best) { best = d; found = run[i - 1] + (run[i] - run[i - 1]) * t; }
    }
    return found;
  };
  return { total: run[run.length - 1], at, along };
}

/// A hue, a turn of the circle with red at 0 as a plant's is, as paint.
function paint(hue, saturation, value) {
  const h = (((hue % 1) + 1) % 1) * 6, k = Math.floor(h), f = h - k;
  const p = value * (1 - saturation), q = value * (1 - saturation * f), t = value * (1 - saturation * (1 - f));
  return [[value, t, p], [q, value, p], [p, value, t], [p, q, value], [t, p, value], [value, p, q]][k % 6];
}

/// **The band painted along the staging**: laid along the staging's middle
/// line at the outer slat, a short step at a time, each step a hue. Where a
/// step stands round the ring says which hue: each band of the twelve is at
/// its middle hue midway between its two pots, and the colour shades evenly
/// from one band's middle to the next, so the band runs blue-green past the
/// door, through blue, violet, magenta, red and orange, to yellow before it,
/// with no seam where one band of pots gives way to the next. The wheel's cut
/// and its bands' edges are the rule's (`pg_glasshouse_plan`), and where the
/// pots stand is the table's, so the paint cannot disagree with the pots.
///
/// **Painted by hand**: each edge of the paint wanders on its own by a few
/// millimetres and feathers into the boards over the last centimetre, each
/// step's tone is a little off the last, as a brush leaves it, and it thins
/// to a rounded end a little in from each end of the staging.
function paintBand(e, { quad }, line, place) {
  const { total, at, along } = walk(line);
  const bands = place.bandEdges.length + 1;
  const edges = [0, ...place.bandEdges, 1];
  const pots = Array.from({ length: bands }, () => []);
  for (const [x, z, bed, band] of glasshouseWheel.places[0]) {
    if (bed === 0) pots[band].push(along([x, z]));
  }
  // Knots: how far along the line, and how far round the wheel past its cut.
  const knots = [[0, 0],
    ...pots.map((ss, b) => [ss.reduce((a, v) => a + v, 0) / ss.length, (edges[b] + edges[b + 1]) / 2]),
    [total, 1]];
  const wheelAt = (s) => {
    let i = 1;
    while (i < knots.length - 1 && knots[i][0] < s) i++;
    const [s0, u0] = knots[i - 1], [s1, u1] = knots[i];
    return u0 + (u1 - u0) * Math.min(1, Math.max(0, (s - s0) / (s1 - s0 || 1)));
  };
  const noise = (s, side) => e.pg_verge(s * 2.3, side, GLASS_SEED.band) / 0.14;
  const y = place.stagingTop + BAND.lift, UP = [0, 1, 0];
  const from = 0.03, to = total - 0.03, steps = Math.ceil((to - from) / BAND.step);
  let last = null;
  for (let k = 0; k <= steps; k++) {
    const s = from + ((to - from) * k) / steps;
    const p = at(s);
    // A rounded end: the half width a quarter ellipse over the last `ends`.
    const t = Math.min(1, Math.min(s - from, to - s) / BAND.ends);
    const taper = Math.sqrt(1 - (1 - t) * (1 - t));
    const middle = BAND.offset + 0.5 * BAND.wander * noise(s, 3) * taper;
    const inner = (BAND.half + BAND.wander * noise(s, -1)) * taper;
    const outer = (BAND.half + BAND.wander * noise(s, 1)) * taper;
    const feather = BAND.feather * taper;
    const across = [middle - inner - feather, middle - inner, middle + outer, middle + outer + feather]
      .map((o) => [p.x + p.ox * o, y, p.z + p.oz * o]);
    const tone = 0.94 + 0.08 * hash(k * 389 + GLASS_SEED.band);
    const colour = paint(place.cut + wheelAt(s), BAND.saturation, BAND.value).map((c) => c * tone);
    const step = { across, colour };
    if (last) {
      const [a0, a1, a2, a3] = last.across, [b0, b1, b2, b3] = step.across;
      const [ca, cb] = [last.colour, step.colour];
      // Feathered edge, paint, feathered edge: board colour at the outside.
      quad(a0, b0, b1, a1, UP, BOARD, BOARD, cb, ca);
      quad(a1, b1, b2, a2, UP, ca, cb, cb, ca);
      quad(a2, b2, b3, a3, UP, ca, cb, BOARD, BOARD);
    }
    last = step;
  }
}

/// A structure, moved to where it stands, with a grain across it read off where
/// each vertex is in the world, as `frame.js` sets its boards. `grain` is how far
/// the tone wanders: boards more, painted bars less, glass not at all.
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

// MARK: - Growing a plot

// **Letting go of the thread** between plants, the way the other seven do.
const SLICE = 16;
const breathe = () => new Promise((resume) => setTimeout(resume, 0));

// Grows one plot from the plot service. A planting with no parents was minted
// rather than crossed — the ambassador, in the middle of the bed — and grows from its seed
// alone. The pots are set out first, from the plantings' lifts, so the plants
// are grown into a staging that already has their pots on it.
export async function growGlasshouseFromService(e, stage, place, plot, report) {
  stage.clear();
  const { plantings } = await (await fetch(`/api/glasshouse/plot/${plot}`)).json();
  place.pots = plantings.filter((p) => (p.lift ?? 0) > 0).map((p) => p.spot);
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
    stage.add(p.spot[0], p.spot[1], decode(takeResult(e, length)), p.lift ?? 0, { ...p, plot });
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

// The workbench's version: a Glasshouse the module invents, for judging the
// template before anybody has released anything into it.
export async function plantVisitors(e, total, report) {
  let arrived = 0;
  let since = performance.now();
  while (arrived < total) {
    e.pg_glasshouse_arrive();
    arrived += 1;
    if (performance.now() - since > SLICE) {
      report(`Planting by the rule: ${arrived} of ${total} arrived`);
      await breathe();
      since = performance.now();
    }
  }
  return e.pg_glasshouse_plots();
}

export async function growInvented(e, stage, place, plot, report) {
  stage.clear();
  const count = e.pg_glasshouse_count(plot);
  const grown = [];
  for (let i = 0; i < count; i++) {
    const length = e.pg_glasshouse_grow(plot, i);
    grown.push(takeResult(e, length));
  }
  // The pots first, as the service's plots are drawn: every planting with a lift.
  place.pots = grown.map((buffer) => new Float32Array(buffer.slice(0, 12)))
    .filter((head) => head[2] > 0).map((head) => [head[0], head[1]]);
  stage.rebuild();
  let since = performance.now();
  for (const [i, buffer] of grown.entries()) {
    const head = new Float32Array(buffer.slice(0, 12));
    stage.add(head[0], head[1], decode(buffer.slice(12)), head[2]);
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

export function describeGlasshouse(e, plot) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_glasshouse_describe(plot))));
}
