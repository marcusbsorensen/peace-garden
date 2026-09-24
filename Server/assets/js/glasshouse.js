// A plot of the Glasshouse, drawn the way the app draws a plot: a floating slab
// of ground seen in true isometric, laid with quarry tiles, a span house of
// painted bars and glass standing on it, slatted staging down its sunny side
// with a clay pot under every plant on it, and a soil border along the back.
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
// through the module. This file draws the ground, the house, the staging and
// the pots, and puts each plant on the spot the service gives it; the plot's own
// numbers come from `pg_glasshouse_plan` rather than being written down again.

import { decode, takeResult } from './plant.js';
import { COLOUR, RIM_DEPTH, SIDE, hash, readOutline, readStructure } from './longwalk.js';

// Seeds for this area's dressing, its own and not another area's.
const GLASS_SEED = { ground: 6421, floor: 43, tile: 61, soil: 89, border: 97, frame: 1511,
  glass: 1523, staging: 1549, pot: 1571 };

/// The floor: quarry tiles, the colour the map gives this area — `LOOK.light` in
/// `gates.js`, brought down by the quarter a plot is lit up by. A glasshouse
/// floor is tiled or bricked so it can be damped down on a hot day, and the
/// water held in it keeps the air moist.
const TILE = [0.433, 0.282, 0.210];

/// A clay pot, fresher and oranger than the floor it stands above: a new pot is
/// the colour of the clay, and a tile has been walked on.
const POT = [0.60, 0.355, 0.24];

/// The compost in a pot, darker than the border's soil because it is kept
/// watered.
const COMPOST = [0.215, 0.170, 0.130];

/// The border's soil: the Cold Frame's, a bed's own ground rather than the
/// floor round it.
const SOIL = [0.300, 0.240, 0.180];

/// The staging: deal, weathered paler than the bench's oak, as the Cold Frame's
/// boards are, and for their reason — at `COLOUR.timber` its underside, facing
/// away from this sun, went nearly black against the floor.
const BOARD = [0.64, 0.57, 0.47];

/// The house's bars, painted, as a glasshouse's timber always is.
const BAR = [0.82, 0.81, 0.76];

/// The glass: the sky it reflects, faint. The Cold Frame's at 7% had one layer
/// of glass over its plants; here there are two or three between the eye and
/// anything under the roof — the roof itself, and a side wall or a gable — so
/// each is fainter, and the laps and the ripple are what show it is there.
const GLASS = [0.78, 0.85, 0.92];
const GLASS_OPACITY = 0.05;

export function plan(e) {
  const place = JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_glasshouse_plan())));
  // Where the pots stand in the plot on show, as [x, z]. Empty until a plot is
  // grown; the page fills it and asks the stage to build its ground again.
  place.pots = [];
  return place;
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

    const outline = readOutline(e, SIDE, SIDE, GLASS_SEED.ground);
    const n = outline.length;
    for (let i = 0; i < n; i++) {
      const a = outline[i], b = outline[(i + 1) % n];
      tri([0, 0, 0], [a[0], 0, a[1]], [b[0], 0, b[1]], UP, TILE);
    }

    // **The border's soil, and where it ends.** A strip along the back of the
    // house, inside the glass, its edges cut by hand rather than ruled: each
    // side wanders a few centimetres with the verge noise the walk's path is
    // cut with.
    const wander = (along, side) => e.pg_verge(along, side, GLASS_SEED.border) / 0.14;
    const halfLength = place.length / 2 - 0.12;
    const back = place.borderZ - 0.40, front = place.borderZ + 0.40;
    const inBorder = (x, z) =>
      Math.abs(x) < halfLength + 0.03 * wander(z * 3, 1)
      && z > back + 0.03 * wander(x, 2)
      && z < front + 0.04 * wander(x, 3);

    // **The tiles: the Knot Garden's jittered lattice, a tone to a tile.** A
    // quarry-tile floor is a grid by nature, and a ruled grid is the one thing
    // this garden does not draw — so the corners are nudged off true, each tile
    // takes its own tone, and the lines between them are where one tone meets
    // the next rather than lines at all. A tile a little under a third of a
    // metre, which is what a quarry tile is.
    const half = SIDE / 2 - 0.06;
    const lattice = (cell, from, to, jitter) => {
      const stepsX = Math.ceil((to[0] - from[0]) / cell), stepsZ = Math.ceil((to[1] - from[1]) / cell);
      const grid = [];
      for (let i = 0; i <= stepsX; i++) {
        const row = [];
        for (let j = 0; j <= stepsZ; j++) {
          const edge = i === 0 || j === 0 || i === stepsX || j === stepsZ;
          const shift = edge ? 0 : cell * jitter;
          row.push([
            Math.max(from[0], Math.min(to[0], from[0] + i * cell + shift * (hash(i * 7919 + j * 104729 + from[0] * 1e3) - 0.5) * 2)),
            Math.max(from[1], Math.min(to[1], from[1] + j * cell + shift * (hash(i * 6733 + j * 92831 + from[1] * 1e3) - 0.5) * 2)),
          ]);
        }
        grid.push(row);
      }
      return grid;
    };
    const sheet = (grid, lift, tone, keep) => {
      const at = (p) => [p[0], lift, p[1]];
      for (let i = 0; i < grid.length - 1; i++) {
        for (let j = 0; j < grid[0].length - 1; j++) {
          const a = grid[i][j], b = grid[i + 1][j], c = grid[i + 1][j + 1], d = grid[i][j + 1];
          if (!keep((a[0] + c[0]) / 2, (a[1] + c[1]) / 2)) continue;
          if (hash(i * 31 + j * 17 + lift * 1e4) < 0.5) {
            tri(at(a), at(b), at(c), UP, tone(i, j, 0, a)); tri(at(a), at(c), at(d), UP, tone(i, j, 1, c));
          } else {
            tri(at(a), at(b), at(d), UP, tone(i, j, 2, a)); tri(at(b), at(c), at(d), UP, tone(i, j, 3, c));
          }
        }
      }
    };
    const drift = (x, z) => 1
      + 0.05 * (e.pg_verge(x * 0.62, -1, GLASS_SEED.ground) / 0.14)
      + 0.05 * (e.pg_verge(z * 0.54, 1, GLASS_SEED.ground) / 0.14);
    sheet(lattice(0.29, [-half, -half], [half, half], 0.12), 0.003,
      (i, j, k, p) => TILE.map((v) => v * drift(p[0], p[1]) * (0.88 + 0.22 * hash(i * 131 + j * 37 + GLASS_SEED.tile))),
      (x, z) => !inBorder(x, z));
    sheet(lattice(0.045, [-halfLength - 0.1, back - 0.1], [halfLength + 0.1, front + 0.1], 0.34), 0.006,
      (i, j, k, p) => SOIL.map((v) => v * drift(p[0], p[1]) * (0.92 + 0.14 * hash(i * 131 + j * 37 + k * 7 + GLASS_SEED.soil))),
      inBorder);

    // MARK: The house, the staging and the pots
    //
    // Meshes from `Organic`, each set where it stands: the house's bars at the
    // middle of the plot, the staging down the sunny side, and a pot and its
    // compost under every potted plant in the plot on show. The glass is
    // gathered and handed back on its own.
    set(readStructure(takeResult(e, e.pg_glasshouse_frame(GLASS_SEED.frame))), [0, 0, 0], BAR, 0.06, vertex);
    set(readStructure(takeResult(e, e.pg_glasshouse_staging(GLASS_SEED.staging))), [0, 0, place.stagingZ],
      BOARD, 0.24, vertex);
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

    // Its sides hang from the outline down to a floor as rough as a clod's, in
    // the app's strata. The walk's arithmetic, because it is the same slab.
    const strata = [[0, COLOUR.humus], [0.16, COLOUR.earth], [0.58, COLOUR.earth], [1, COLOUR.bedrock]];
    let around = 0;
    const floor = outline.map((p, i) => {
      if (i > 0) around += Math.hypot(p[0] - outline[i - 1][0], p[1] - outline[i - 1][1]);
      return RIM_DEPTH * (1 + 0.22 * (e.pg_verge(around, 1, GLASS_SEED.floor) / 0.14));
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
// rather than crossed — the ambassador on the staging — and grows from its seed
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
