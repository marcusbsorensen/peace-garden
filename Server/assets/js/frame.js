// A plot of the Cold Frame, drawn the way the app draws a plot: a floating slab
// of ground seen in true isometric, gravel all over it, four low frames of
// boards standing on it with their lights propped open, and young plants in two
// ranks inside each.
//
// **The first page in the garden with something to see through.** The frames'
// glass is handed to the stage as `glass`, which `makePlotStage` draws after the
// plants, blended and without writing depth — so a seedling under a light is
// seen through it rather than hidden by it. Every other area hands back no glass
// and draws as it always did.
//
// **Every plant is grown young.** `pg_grow_young` and `pg_grow_hybrid_young` are
// `pg_grow` and `pg_grow_hybrid` at `ColdFrame.drawn`: a young plant with its
// first buds showing colour. Where it stands was decided by the height it will
// grow to; what is drawn is the height it is now.
//
// The rule that decides where each plant stands is SeedCore's `ColdFrame`,
// through the module. This file draws the ground and the frames and puts each
// plant on the spot the service gives it; the plot's own numbers come from
// `pg_frame_plan` rather than being written down again here.

import { decode, takeResult } from './plant.js';
import { COLOUR, RIM_DEPTH, SIDE, hash, readOutline, readStructure } from './longwalk.js';

// Seeds for this area's dressing, its own and not another area's, so seven
// plots do not share one wandering edge.
const FRAME = { ground: 5153, floor: 37, grain: 59, soil: 83, box: 1301, lights: 1361, glass: 1427 };

/// The frames' boards: deal, weathered paler than the bench's oak, as the
/// Seedbed's labels are — a frame is knocked together from the same stock a
/// nursery label is cut from, and at `COLOUR.timber` its front wall, facing
/// away from this sun, went nearly black against the gravel.
const BOARD = [0.64, 0.57, 0.47];

/// The lights' bars, painted: a frame light's bars are white-leaded or painted,
/// because bare wood that is wet all winter rots at the joints. Paler than the
/// boards so the lights read as a lid set on the box rather than as more box.
const BAR = [0.80, 0.79, 0.74];

/// The soil inside a frame, which is not the gravel round it: a frame stands on
/// a bed of its own, darker and finer, and a seedling stands in that.
const SOIL = [0.300, 0.240, 0.180];

/// The glass: the sky it reflects, at a seventh of full strength. Clear glass is
/// seen by what it reflects and by where it doubles, which `Organic.frameGlass`
/// gives it as a ripple and as laps between panes.
const GLASS = [0.78, 0.85, 0.92];
const GLASS_OPACITY = 0.14;

export function plan(e) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_frame_plan())));
}

// MARK: - The ground

export function makeFrameGround(place) {
  return function buildFrameGround(farSide, span, e, eye) {
    const positions = [], normals = [], colours = [];
    const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
    const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
    const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => {
      tri(a, b, c, n, ca, cb, cc); tri(a, c, d, n, ca, cc, cd);
    };
    const UP = [0, 1, 0];

    const outline = readOutline(e, SIDE, SIDE, FRAME.ground);
    const n = outline.length;
    for (let i = 0; i < n; i++) {
      const a = outline[i], b = outline[(i + 1) % n];
      tri([0, 0, 0], [a[0], 0, a[1]], [b[0], 0, b[1]], UP, COLOUR.gravel);
    }

    // Where a frame's soil is, inside its boards. Frames are asked of the plan,
    // so the soil cannot come to stand anywhere the rule's frames do not.
    const inside = (x, z) => place.frames.some(([fx, fz]) =>
      Math.abs(x - fx) < place.length / 2 - 0.03 && Math.abs(z - fz) < place.depth / 2 - 0.03);

    // **The gravel is the Knot Garden's**, jittered lattice and per-face tone,
    // for the reason `knot.js` §The ground sets out: a regular grid of flat
    // faces draws a tiled floor however small it is. Its own seeds, and it
    // leaves out the cells a frame stands on, where the soil is drawn instead.
    const half = SIDE / 2 - 0.06;
    const lattice = (cell, from, to) => {
      const stepsX = Math.ceil((to[0] - from[0]) / cell), stepsZ = Math.ceil((to[1] - from[1]) / cell);
      const grid = [];
      for (let i = 0; i <= stepsX; i++) {
        const row = [];
        for (let j = 0; j <= stepsZ; j++) {
          const edge = i === 0 || j === 0 || i === stepsX || j === stepsZ;
          const shift = edge ? 0 : cell * 0.34;
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
      + 0.07 * (e.pg_verge(x * 0.62, -1, FRAME.ground) / 0.14)
      + 0.06 * (e.pg_verge(z * 0.54, 1, FRAME.ground) / 0.14);
    sheet(lattice(0.06, [-half, -half], [half, half]), 0.003,
      (i, j, k, p) => COLOUR.gravel.map((v) => v * drift(p[0], p[1]) * (0.87 + 0.25 * hash(i * 131 + j * 37 + k * 7 + FRAME.grain))),
      (x, z) => !inside(x, z));

    // **The soil in each frame**, finer and darker, and flat-toned per face as
    // the Seedbed's tilth is — crumbs, not a surface. Its spread is half the
    // gravel's, because a crumb of earth does not catch the light the way a
    // chipping does.
    for (const [fx, fz] of place.frames) {
      const hx = place.length / 2 - 0.03, hz = place.depth / 2 - 0.03;
      sheet(lattice(0.045, [fx - hx, fz - hz], [fx + hx, fz + hz]), 0.006,
        (i, j, k, p) => SOIL.map((v) => v * drift(p[0], p[1]) * (0.92 + 0.14 * hash(i * 131 + j * 37 + k * 7 + FRAME.soil))),
        () => true);
    }

    // MARK: The frames
    //
    // Three meshes from `Organic`, set at each frame's middle: the box of
    // boards, the lights' bars and their blocks, and the glass. The first two
    // join the ground; the glass is gathered and handed back on its own.
    const glass = { positions: [], normals: [], colours: [] };
    const glassVertex = (p, nn, c) => { glass.positions.push(...p); glass.normals.push(...nn); glass.colours.push(...c); };
    place.frames.forEach(([fx, fz], f) => {
      const at = [fx, 0, fz];
      set(readStructure(takeResult(e, e.pg_frame_box(FRAME.box + f))), at, BOARD, 0.24, vertex);
      set(readStructure(takeResult(e, e.pg_frame_lights(FRAME.lights + f))), at, BAR, 0.1, vertex);
      set(readStructure(takeResult(e, e.pg_frame_glass(FRAME.glass + f))), at, GLASS, 0, glassVertex);
    });

    // Its sides hang from the outline down to a floor as rough as a clod's, in
    // the app's strata. The walk's arithmetic, because it is the same slab.
    const strata = [[0, COLOUR.humus], [0.16, COLOUR.earth], [0.58, COLOUR.earth], [1, COLOUR.bedrock]];
    let around = 0;
    const floor = outline.map((p, i) => {
      if (i > 0) around += Math.hypot(p[0] - outline[i - 1][0], p[1] - outline[i - 1][1]);
      return RIM_DEPTH * (1 + 0.22 * (e.pg_verge(around, 1, FRAME.floor) / 0.14));
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
  };
}

/// A structure, moved to where it stands, with a grain across it read off where
/// each vertex is in the world — so four frames cut from one mesh are not four
/// identical pieces of wood. `grain` is how far the tone wanders: boards more,
/// painted bars less, glass not at all.
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

// **Letting go of the thread** between plants, the way the other six do.
const SLICE = 16;
const breathe = () => new Promise((resume) => setTimeout(resume, 0));

// Grows one plot from the plot service, every plant young. A planting with no
// parents was minted rather than crossed — the ambassador in the first frame —
// and grows from its seed alone.
export async function growFrameFromService(e, stage, plot, report) {
  stage.clear();
  const { plantings } = await (await fetch(`/api/frame/plot/${plot}`)).json();
  let since = performance.now();
  for (const [i, p] of plantings.entries()) {
    const lineage = p.parents ?? [];
    const words = new TextEncoder().encode(
      lineage.length === 2 ? [p.seed, ...lineage, p.encounter].join(' ') : p.seed,
    );
    const pointer = e.pg_alloc(words.length);
    new Uint8Array(e.memory.buffer, pointer, words.length).set(words);
    const length = lineage.length === 2
      ? e.pg_grow_hybrid_young(pointer, words.length)
      : e.pg_grow_young(pointer, words.length);
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

// The workbench's version: a Cold Frame the module invents, for judging the
// template before anybody has released anything into it.
export async function plantVisitors(e, total, report) {
  let arrived = 0;
  let since = performance.now();
  while (arrived < total) {
    e.pg_frame_arrive();
    arrived += 1;
    if (performance.now() - since > SLICE) {
      report(`Planting by the rule: ${arrived} of ${total} arrived`);
      await breathe();
      since = performance.now();
    }
  }
  return e.pg_frame_plots();
}

export async function growInvented(e, stage, plot, report) {
  stage.clear();
  const count = e.pg_frame_count(plot);
  let since = performance.now();
  for (let i = 0; i < count; i++) {
    const length = e.pg_frame_grow(plot, i);
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

export function describeFrame(e, plot) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_frame_describe(plot))));
}
