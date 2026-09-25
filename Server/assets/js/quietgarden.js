// A plot of the Quiet Garden, drawn the way the app draws a plot: a floating
// slab of ground seen in true isometric, mown all over, a hedge round all four
// sides of it, and a bench in one corner with a single plant beside it.
//
// **It is a room, so the page shows one of them.** The Long Walk draws three
// plots end to end because a walk is a length you look down. An enclosure is
// not: you are inside one or you are in the next one, and three hedged rooms
// side by side would be three gardens rather than one seen properly.
//
// The rule that decides where each plant stands is SeedCore's `QuietGarden`,
// through the module — this file draws the ground and puts each plant on the
// spot the service gives it. The room's own numbers come from `pg_room_plan`
// rather than being written down again here.

import { decode, takeResult } from './plant.js';
import { COLOUR, HEDGE, RIM_DEPTH, SEED, SIDE, hash, keepToPlot, readOutline, readStructure } from './longwalk.js';

// Seeds for this area's dressing, so a room is the same shape on every visit.
// Its own, not the walk's: two areas drawing from one seed would be two plots
// with the same hedge wobble, which is the sort of thing an eye catches
// without being able to say why.
const ROOM = { ground: 4091, floor: 17, bench: 88, hedge: [211, 212, 213, 214], mow: 29 };

// How the four hedges stand. They are drawn low on the two sides nearest the
// viewer for the reason the walk's are — Marcus, 18 September — because a 2 m
// hedge between the reader and the room hides the room.
// Each run reaches a hedge's thickness past the corner, and its ends are cut
// square rather than domed, so the end of one is buried inside the side of the
// next. A domed end falls to the ground over half the hedge's height — a metre
// on the tall ones — which leaves a notch at every corner that no overlap
// short of hanging the hedge off the plot would cover.
const past = (from) => 2 * (from + HEDGE.thickness);

export function plan(e) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_room_plan())));
}

// MARK: - The ground

export function makeRoomGround(room) {
  return function buildRoomGround(farSide, span, e, eye) {
    const positions = [], normals = [], colours = [];
    const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
    // What throws a shadow on the lawn: the hedge round and the bench, handed
    // to the stage as `casting`.
    const casting = [];
    const casts = (p, nn, c) => { vertex(p, nn, c); casting.push(...p); };
    const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
    const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => {
      tri(a, b, c, n, ca, cb, cc); tri(a, c, d, n, ca, cc, cd);
    };

    // The slab's top: the same worn, wandering outline the walk's plot has,
    // filled from the middle. Square here, because a room is.
    const outline = readOutline(e, SIDE, SIDE, ROOM.ground);
    const n = outline.length;
    for (let i = 0; i < n; i++) {
      const a = outline[i], b = outline[(i + 1) % n];
      tri([0, 0, 0], [a[0], 0, a[1]], [b[0], 0, b[1]], [0, 1, 0], COLOUR.turf);
    }

    // **Mown all over, not in borders.** The walk stripes its path and leaves
    // its borders rough; here the grass is the garden, so the stripes run the
    // whole width of the room and out under the hedges. A mower goes up and
    // back, so they alternate, and they wander because the mower did.
    //
    // **Mown to the plot's edge and no further** (25 September 2026). Each
    // stripe was one quad 2.54 m either side of the middle, over an edge that
    // comes in to 2.42 m, so the lawn ran past the slab with ruled ends. Now a
    // stripe runs a little past the plot in narrow pieces, each corner kept to
    // it, so its ends follow the edge's own wander.
    const stripe = 0.42;
    const rows = Math.ceil(SIDE / stripe) + 1;
    const onPlot = keepToPlot(outline);
    const half = SIDE / 2 + 0.06;
    const pieces = 40;
    for (let r = 0; r < rows; r++) {
      const z0 = -SIDE / 2 + r * stripe, z1 = z0 + stripe;
      if (z0 >= SIDE / 2) break;
      const edge = (z) => 0.05 * (e.pg_verge(z * 1.7, r % 2 ? 1 : -1, ROOM.mow) / 0.14);
      const c = COLOUR.grass.map((v) => v * (r % 2 ? 1.05 : 0.95));
      // The stripe's two wandering sides, read at each end as before and
      // carried straight across between them.
      const near = [z0 + edge(z0), z0 + edge(z0 + 3)], far = [z1 + edge(z1), z1 + edge(z1 + 3)];
      const at = (u, side) => {
        const [x, z] = onPlot(-half + 2 * half * u, side[0] + (side[1] - side[0]) * u);
        return [x, 0.004, z];
      };
      for (let k = 0; k < pieces; k++) {
        const u0 = k / pieces, u1 = (k + 1) / pieces;
        quad(at(u0, near), at(u1, near), at(u1, far), at(u0, far), [0, 1, 0], c);
      }
    }

    // Its sides hang from the outline down to a floor as rough as a clod's, in
    // the app's strata. The walk's arithmetic, because it is the same slab.
    const strata = [[0, COLOUR.humus], [0.16, COLOUR.earth], [0.58, COLOUR.earth], [1, COLOUR.bedrock]];
    let around = 0;
    const floor = outline.map((p, i) => {
      if (i > 0) around += Math.hypot(p[0] - outline[i - 1][0], p[1] - outline[i - 1][1]);
      return RIM_DEPTH * (1 + 0.22 * (e.pg_verge(around, 1, ROOM.floor) / 0.14));
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

    // **The hedge round.** Four runs, each turned a quarter from the last, all
    // of them overlapping their neighbours at the corners. Tall on the two
    // sides away from the viewer and low on the two nearest, so the reader is
    // looking into the room over a low hedge rather than at the back of a tall
    // one.
    const from = room.hedgeFrom + HEDGE.thickness / 2;
    const runs = [
      { turn: false, at: -from }, { turn: false, at: from },
      { turn: true, at: -from }, { turn: true, at: from },
    ];
    runs.forEach((run, i) => {
      // Which way this run faces: the sign of the axis it stands on, against
      // the direction the camera is looking from.
      const near = run.turn ? run.at * eye[2] > 0 : run.at * eye[0] > 0;
      const height = near ? HEDGE.low : HEDGE.tall;
      const mesh = readStructure(
        takeResult(e, e.pg_hedge(past(room.hedgeFrom), height, HEDGE.thickness, ROOM.hedge[i], 0, 0)));
      place(mesh, run.turn, run.turn ? [0, 0, run.at] : [run.at, 0, 0], COLOUR.yew, casts);
    });

    // **The bench**, in its own corner, turned to face the middle of the lawn.
    // It lies across its corner, along the diagonal, which is how a seat is
    // put into the angle of two hedges: the length of it faces the middle of
    // the lawn rather than one of the sides.
    const bench = readStructure(takeResult(e, e.pg_bench(1.5, 0.45, 0.42, ROOM.bench)));
    placeTurned(bench, room.bench, Math.atan2(room.bench[1], room.bench[0]), COLOUR.timber, casts);

    return {
      positions: new Float32Array(positions),
      normals: new Float32Array(normals),
      colours: new Float32Array(colours),
      casting: new Float32Array(casting),
    };
  };
}

/// A structure's triangles, moved into place, with the grain that keeps a
/// single colour from reading as plastic.
function place(mesh, turn, at, colour, vertex) {
  for (let t = 0; t < mesh.indices.length; t += 3) {
    for (const k of [0, 1, 2]) {
      const v = mesh.indices[t + k];
      const raw = [mesh.positions[v * 3], mesh.positions[v * 3 + 1], mesh.positions[v * 3 + 2]];
      const nRaw = [mesh.normals[v * 3], mesh.normals[v * 3 + 1], mesh.normals[v * 3 + 2]];
      const p = turn ? [raw[2], raw[1], raw[0]] : raw;
      const nn = turn ? [nRaw[2], nRaw[1], nRaw[0]] : nRaw;
      const here = [p[0] + at[0], p[1] + at[1], p[2] + at[2]];
      const tone = 0.9 + 0.2 * hash(Math.round(here[1] * 37) * 131 + Math.round(here[2] * 29));
      vertex(here, nn, colour.map((c) => c * tone));
    }
  }
}

/// The same, turned by an arbitrary angle about y: the bench looks diagonally
/// into the room, which no quarter turn gives.
function placeTurned(mesh, at, angle, colour, vertex) {
  const c = Math.cos(angle), s = Math.sin(angle);
  const spin = (v) => [v[0] * c - v[2] * s, v[1], v[0] * s + v[2] * c];
  for (let t = 0; t < mesh.indices.length; t += 3) {
    for (const k of [0, 1, 2]) {
      const v = mesh.indices[t + k];
      const p = spin([mesh.positions[v * 3], mesh.positions[v * 3 + 1], mesh.positions[v * 3 + 2]]);
      const nn = spin([mesh.normals[v * 3], mesh.normals[v * 3 + 1], mesh.normals[v * 3 + 2]]);
      const here = [p[0] + at[0], p[1], p[2] + at[1]];
      const tone = 0.92 + 0.16 * hash(Math.round(here[0] * 53) * 97 + Math.round(here[2] * 41));
      vertex(here, nn, colour.map((x) => x * tone));
    }
  }
}

// MARK: - Growing a room

// **Letting go of the thread** between plants, the way the walk does: a plot of
// ten is quick, but the module still builds a mesh a plant and a page that
// cannot answer a finger while it does is a page that looks broken.
const SLICE = 16;
const breathe = () => new Promise((resume) => setTimeout(resume, 0));

// Grows one plot from the plot service. A planting with no parents was minted
// rather than crossed — the ambassador beside the bench — and grows from its
// seed alone.
export async function growRoomFromService(e, stage, plot, report) {
  stage.clear();
  const { plantings } = await (await fetch(`/api/quiet/plot/${plot}`)).json();
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

// The workbench's version: a room the module invents, for judging the template
// before anybody has planted anything in it.
export async function plantVisitors(e, total, report) {
  let arrived = 0;
  let since = performance.now();
  while (arrived < total) {
    e.pg_room_arrive();
    arrived += 1;
    if (performance.now() - since > SLICE) {
      report(`Planting by the rule: ${arrived} of ${total} arrived`);
      await breathe();
      since = performance.now();
    }
  }
  return e.pg_room_plots();
}

export async function growInvented(e, stage, plot, report) {
  stage.clear();
  const count = e.pg_room_count(plot);
  let since = performance.now();
  for (let i = 0; i < count; i++) {
    const length = e.pg_room_grow(plot, i);
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

export function describeRoom(e, plot) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_room_describe(plot))));
}
