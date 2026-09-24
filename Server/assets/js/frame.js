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

/// The glass: the sky it reflects, at a fourteenth of full strength. Clear glass is
/// seen by what it reflects and by where it doubles, which `Organic.frameGlass`
/// gives it as a ripple and as laps between panes.
///
/// **Halved from a seventh, 24 September 2026.** With one seedling in a plot
/// the frames read as lids shut over bare soil; Marcus asked whether the beds
/// were covered. Lighter, the soil and a lone plant show through.
const GLASS = [0.78, 0.85, 0.92];
const GLASS_OPACITY = 0.07;

export function plan(e) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_frame_plan())));
}

// MARK: - The ground

// `lids` is the frames' lights (`makeFrameLids`), which the page keeps so it
// can open them; the workbench passes none and gets lights that stay shut.
export function makeFrameGround(place, lids = makeFrameLids(place)) {
  return function buildFrameGround(farSide, span, e, eye) {
    const positions = [], normals = [], colours = [];
    const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
    // What throws a shadow on the gravel and the soil: each frame's box of
    // boards, handed to the stage as `casting`. Not the lights' bars — a bar's
    // shadow is a ruled line — and not the glass.
    const casting = [];
    const casts = (p, nn, c) => { vertex(p, nn, c); casting.push(...p); };
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
    // boards, the lights' bars and their blocks, and the glass. The box and the
    // blocks join the ground. **The lights and their glass do not**, since 24
    // September 2026: a frame opens when its glass is tapped, so they are
    // `lids`, handed to the stage as `pieces` it draws as they stand now.
    const made = lids.make(e);
    place.frames.forEach(([fx, fz], f) => {
      set(readStructure(takeResult(e, e.pg_frame_box(FRAME.box + f))), [fx, 0, fz], BOARD, 0.24, casts);
      const { positions: p, normals: nn, colours: c } = made[f].blocks;
      for (let v = 0; v < p.length; v += 3) vertex([p[v], p[v + 1], p[v + 2]], [nn[v], nn[v + 1], nn[v + 2]], [c[v], c[v + 1], c[v + 2]]);
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
      casting: new Float32Array(casting),
      // Every pane is in a light, so the glass the ground itself hands back is
      // none; it carries the opacity the lights' glass is drawn at.
      glass: { positions: new Float32Array(0), normals: new Float32Array(0), colours: new Float32Array(0),
               opacity: GLASS_OPACITY },
      pieces: lids.pieces,
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

// MARK: - The lights, which open
//
// **A tap on a frame's glass opens that frame** — Marcus, 24 September 2026: a
// reader reaching for a seedling under the glass was tapping the glass, so the
// glass answers by lifting out of the way, the way a frame's light is lifted
// to get at what is under it. Both lights of the frame swing up together on a
// hinge along the high back edge, where a light rests on the back wall, and
// are propped there on a stay each, stood on the block the light was resting
// on. One frame is open at a time: opening another shuts it, and so does a tap
// on nothing, or going to another plot. Closing the plant panel leaves it open,
// because the reader is still looking into it.
//
// **Glass first while shut.** A tap that lands on a shut frame's light opens
// that frame and opens no panel, even with a seedling under the finger; the
// next tap, into the open frame, finds the plant. A plant that stands in front
// of that glass in an open frame still takes the tap. A plant is found by the
// stem the page drew for it (`longwalk.js`, `pick`), so a tall one standing up
// out of a shut frame can be tapped where it shows outside the glass — and,
// like one found by the `p` key or a postcard, has its frame opened before its
// panel opens (`plantpanel.js`, `cover`).

/// How far a light is swung up to be propped open, and how long a whole swing
/// takes. A real light propped for work stands at about this, far enough to
/// reach under and not so far that it goes over and pulls on its hinges.
const OPEN = 60 * Math.PI / 180;
const SWING = 520;
const stillness = window.matchMedia('(prefers-reduced-motion: reduce)');

/// How thick a stay is, as a share of a light's bar: it is a stick, not a
/// piece of the light.
const STAY = 0.7;

export function makeFrameLids(place) {
  const lids = place.frames.map(() => ({ angle: 0, from: 0, to: 0, start: 0, waiting: [] }));
  let made = null;
  let stage = null;
  let shown = null;
  let shownAt = null;
  let ticking = 0;

  // **Built once from the module**, the first time the ground is, and kept:
  // the ground is built again at every turn, and the lights stand where they
  // stand whichever way the plot is seen from.
  //
  // The lights mesh is ten bars and two blocks, each a plank of its own and
  // so a piece of the mesh joined to nothing else. The blocks are the two that
  // reach down below the front of the lights' underside — they stay on the
  // front wall when the lights go up — and the first stile down the slope is
  // the stick a stay is cut from.
  function make(e) {
    if (made) return made;
    const underside = (z) => place.backWall
      + (place.frontWall + place.propped - place.backWall) * Math.min(1, Math.max(0, (z + place.depth / 2) / place.depth));
    made = place.frames.map(([fx, fz], f) => {
      const at = [fx, 0, fz];
      const lights = readStructure(takeResult(e, e.pg_frame_lights(FRAME.lights + f)));
      const glassMesh = readStructure(takeResult(e, e.pg_frame_glass(FRAME.glass + f)));
      const parts = components(lights);
      const bounds = parts.map((triangles) => boundsOf(lights, triangles));
      const low = place.frontWall + place.propped / 2;
      const isBlock = bounds.map((b) => b.min[1] < low);
      const stile = bounds.findIndex((b, i) => !isBlock[i] && b.max[2] - b.min[2] > place.depth * 0.9);

      const bars = flat(lights, parts.filter((_, i) => !isBlock[i]).flat(), at, BAR, 0.1);
      const blocks = flat(lights, parts.filter((_, i) => isBlock[i]).flat(), at, BAR, 0.1);
      const glass = flat(glassMesh, [...glassMesh.indices], at, GLASS, 0);

      // The hinge: along the top of the back rail, the highest and furthest
      // back the lights reach.
      let hy = -Infinity, hz = Infinity;
      for (let v = 0; v < bars.positions.length; v += 3) {
        hy = Math.max(hy, bars.positions[v + 1]);
        hz = Math.min(hz, bars.positions[v + 2] - fz);
      }

      // Where each stay stands: on top of a block, which is where the light
      // was resting — so the stay's head is that same point of the light,
      // lifted with it.
      const rests = bounds.filter((_, i) => isBlock[i])
        .map((b) => [(b.min[0] + b.max[0]) / 2, b.max[1], (b.min[2] + b.max[2]) / 2]);

      // The stick, laid out along its own length: how far along it each
      // vertex is (0 to 1), how far across, and how far up off the light's
      // underside — the stile taken back off the slope it was sheared onto.
      const sb = bounds[stile];
      const cx = (sb.min[0] + sb.max[0]) / 2;
      const stick = flat(lights, parts[stile], [0, 0, 0], BOARD, 0.24);
      const along = [], across = [], off = [];
      for (let v = 0; v < stick.positions.length; v += 3) {
        const z = stick.positions[v + 2];
        along.push((z - sb.min[2]) / (sb.max[2] - sb.min[2]));
        across.push((stick.positions[v] - cx) * STAY);
        off.push(stick.positions[v + 1] - underside(z));
      }
      const deep = Math.max(...off);
      const up = off.map((y) => (y - deep / 2) * STAY);

      // The light's four corners, a little above its underside, for finding
      // it on the screen.
      const corners = [[-1, -1], [1, -1], [1, 1], [-1, 1]].map(([sx, sz]) => {
        const z = sz * place.depth / 2;
        return [sx * place.length / 2, underside(z) + 0.02, z];
      });

      return { at, bars, blocks, glass, hinge: [hy, hz], rests, stick: { ...stick, along, across, up }, corners };
    });
    return made;
  }

  // A point of frame `f`'s lights, given about its middle, swung up by
  // `angle` about the hinge and set where the frame stands.
  function swung(f, [x, y, z], angle, normal = false) {
    const { at, hinge: [hy, hz] } = made[f];
    const c = Math.cos(angle), s = Math.sin(angle);
    if (normal) return [x, y * c + z * s, -y * s + z * c];
    const dy = y - hy, dz = z - hz;
    return [x + at[0], hy + dy * c + dz * s + at[1], hz - dy * s + dz * c + at[2]];
  }

  function swingAll(f, mesh, angle) {
    const p = new Float32Array(mesh.positions.length), n = new Float32Array(mesh.normals.length);
    const [ax, , az] = made[f].at;
    for (let v = 0; v < p.length; v += 3) {
      const q = swung(f, [mesh.positions[v] - ax, mesh.positions[v + 1], mesh.positions[v + 2] - az], angle);
      const m = swung(f, [mesh.normals[v], mesh.normals[v + 1], mesh.normals[v + 2]], angle, true);
      p.set(q, v); n.set(m, v);
    }
    return { positions: p, normals: n, colours: mesh.colours };
  }

  // A stay from the top of a block to the point of the light that rested on
  // it: the stick, stretched to fit and leant back to meet the light.
  function stays(f, angle) {
    const { at, rests, stick } = made[f];
    const out = { positions: [], normals: [], colours: [] };
    for (const rest of rests) {
      const foot = [rest[0] + at[0], rest[1], rest[2] + at[2]];
      const head = swung(f, rest, angle);
      const a = [0, head[1] - foot[1], head[2] - foot[2]];
      const length = Math.hypot(a[1], a[2]);
      a[1] /= length; a[2] /= length;
      const n = [0, a[2], -a[1]];
      for (let v = 0, k = 0; v < stick.positions.length; v += 3, k += 1) {
        const t = stick.along[k] * length;
        out.positions.push(foot[0] + stick.across[k], foot[1] + t * a[1] + stick.up[k] * n[1],
                           foot[2] + t * a[2] + stick.up[k] * n[2]);
        const [nx, ny, nz] = [stick.normals[v], stick.normals[v + 1], stick.normals[v + 2]];
        out.normals.push(nx, ny * n[1] + nz * a[1], ny * n[2] + nz * a[2]);
      }
      out.colours.push(...stick.colours);
    }
    return out;
  }

  // **The lights as they stand now**, for the stage: every frame's bars (and
  // stays, once a light is up) as one mesh, and every frame's glass as
  // another. The same answer while nothing has moved, which the stage takes
  // to mean there is nothing to upload.
  const cache = [];
  function pieces() {
    if (!made) return { opaque: null, glass: null };
    const now = lids.map((lid) => `${lid.angle}:${lid.to}`).join();
    if (shown && now === shownAt) return shown;
    const opaque = [], glass = [];
    lids.forEach((lid, f) => {
      const propped = lid.to === OPEN && lid.angle === OPEN;
      const key = `${lid.angle}:${propped}`;
      if (cache[f]?.key !== key) {
        const up = lid.angle !== 0;
        cache[f] = {
          key,
          bars: up ? swingAll(f, made[f].bars, lid.angle) : made[f].bars,
          glass: up ? swingAll(f, made[f].glass, lid.angle) : made[f].glass,
          stays: propped ? stays(f, lid.angle) : null,
        };
      }
      opaque.push(cache[f].bars);
      if (cache[f].stays) opaque.push(cache[f].stays);
      glass.push(cache[f].glass);
    });
    shown = { opaque: join(opaque), glass: join(glass) };
    shownAt = now;
    return shown;
  }

  // MARK: Opening and shutting

  function swing(f, to) {
    const lid = lids[f];
    if (lid.to === to) return;
    lid.from = lid.angle;
    lid.to = to;
    lid.start = performance.now();
    if (to !== OPEN) settle(lid, false);
  }

  function settle(lid, opened) {
    const waiting = lid.waiting;
    lid.waiting = [];
    waiting.forEach((resolve) => resolve(opened));
  }

  // Every light towards where it is going, eased at both ends as a hand lifts
  // a light: a little slow off the wall and slowing onto the stay.
  function tick(now) {
    ticking = 0;
    let moving = false;
    for (const lid of lids) {
      if (lid.angle === lid.to) continue;
      const length = SWING * Math.abs(lid.to - lid.from) / OPEN;
      const t = stillness.matches || length === 0 ? 1 : Math.min(1, (now - lid.start) / length);
      const s = t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
      lid.angle = t >= 1 ? lid.to : lid.from + (lid.to - lid.from) * s;
      if (lid.angle === lid.to) {
        if (lid.to === OPEN) settle(lid, true);
      } else {
        moving = true;
      }
    }
    stage?.draw();
    if (moving) ticking = requestAnimationFrame(tick);
  }

  function go() {
    if (!ticking) ticking = requestAnimationFrame(tick);
  }

  // Opens frame `f` and shuts any other. Resolves true once it is propped
  // open, or false if something shut it first.
  function openOnly(f) {
    lids.forEach((_, i) => { if (i !== f) swing(i, 0); });
    const lid = lids[f];
    if (lid.to === OPEN && lid.angle === OPEN) {
      go();
      return Promise.resolve(true);
    }
    swing(f, OPEN);
    const opened = new Promise((resolve) => lid.waiting.push(resolve));
    go();
    return opened;
  }

  // MARK: Which frame

  // The frame a point on the ground is inside, or -1.
  function frameAt(x, z) {
    return place.frames.findIndex(([fx, fz]) =>
      Math.abs(x - fx) < place.length / 2 && Math.abs(z - fz) < place.depth / 2);
  }

  // The camera's direction, as `makePlotStage`'s `eye` has it: further along
  // it is nearer the reader.
  function eye() {
    const angle = stage.turn() * Math.PI / 2;
    const c = Math.cos(angle), s = Math.sin(angle);
    return [c + s, 1, -s + c].map((v) => v / Math.sqrt(3));
  }

  // **A tap on a shut frame's glass**, at (px, py) in CSS pixels from the
  // canvas's corner: the light's four corners where they were last drawn,
  // and whether the tap is inside them. `plant` is the plant the same tap
  // found, if any, which keeps the tap only if it stands in an open frame (or
  // none) in front of that glass. Answers whether the tap was the glass's.
  function tapped(px, py, plant = null) {
    if (!stage || !made) return false;
    const facing = eye();
    let hit = -1, nearest = -Infinity;
    lids.forEach((lid, f) => {
      if (lid.to !== 0) return;
      const corners = made[f].corners.map((corner) => swung(f, corner, lid.angle));
      if (!inside(px, py, corners.map((corner) => stage.toScreen(corner)))) return;
      const middle = [0, 1, 2].map((i) => corners.reduce((sum, corner) => sum + corner[i], 0) / 4);
      const depth = dot(middle, facing);
      if (depth > nearest) { hit = f; nearest = depth; }
    });
    if (hit < 0) return false;
    if (plant) {
      const theirs = frameAt(plant.at[0], plant.at[2]);
      if ((theirs < 0 || lids[theirs].to === OPEN) && dot(plant.at, facing) > nearest) return false;
    }
    openOnly(hit);
    return true;
  }

  return {
    make,
    pieces,
    tapped,
    attach: (given) => { stage = given; },
    // Before a plant's panel opens: its frame, if it stands in one. Resolves
    // true when the plant can be seen into.
    uncover: (plant) => {
      const f = frameAt(plant.at[0], plant.at[2]);
      return f < 0 ? Promise.resolve(true) : openOnly(f);
    },
    // A tap that found neither glass nor plant: whatever is open shuts.
    missed: () => {
      lids.forEach((_, i) => swing(i, 0));
      go();
    },
    // Another plot: every light shut at once, before its plants are grown.
    shut: () => {
      for (const lid of lids) {
        settle(lid, false);
        Object.assign(lid, { angle: 0, from: 0, to: 0 });
      }
    },
  };
}

// The pieces of a mesh joined to nothing else, each as its own list of
// indices, in the order the mesh was built.
function components(mesh) {
  const parent = Array.from({ length: mesh.positions.length / 3 }, (_, i) => i);
  const find = (i) => { while (parent[i] !== i) { parent[i] = parent[parent[i]]; i = parent[i]; } return i; };
  for (let t = 0; t < mesh.indices.length; t += 3) {
    const a = find(mesh.indices[t]);
    for (const k of [1, 2]) { const b = find(mesh.indices[t + k]); if (b !== a) parent[b] = a; }
  }
  const groups = new Map();
  for (let t = 0; t < mesh.indices.length; t += 3) {
    const root = find(mesh.indices[t]);
    if (!groups.has(root)) groups.set(root, []);
    groups.get(root).push(mesh.indices[t], mesh.indices[t + 1], mesh.indices[t + 2]);
  }
  return [...groups.values()];
}

function boundsOf(mesh, indices) {
  const min = [Infinity, Infinity, Infinity], max = [-Infinity, -Infinity, -Infinity];
  for (const v of indices) {
    for (const i of [0, 1, 2]) {
      min[i] = Math.min(min[i], mesh.positions[v * 3 + i]);
      max[i] = Math.max(max[i], mesh.positions[v * 3 + i]);
    }
  }
  return { min, max };
}

// Some of a mesh's triangles, set where they stand by `set`, as flat arrays.
function flat(mesh, indices, at, colour, grain) {
  const out = { positions: [], normals: [], colours: [] };
  set({ positions: mesh.positions, normals: mesh.normals, indices }, at, colour, grain, (p, n, c) => {
    out.positions.push(...p); out.normals.push(...n); out.colours.push(...c);
  });
  return { positions: new Float32Array(out.positions), normals: new Float32Array(out.normals),
           colours: new Float32Array(out.colours) };
}

function join(meshes) {
  const total = meshes.reduce((sum, m) => sum + m.positions.length, 0);
  const out = { positions: new Float32Array(total), normals: new Float32Array(total), colours: new Float32Array(total) };
  let at = 0;
  for (const m of meshes) {
    out.positions.set(m.positions, at); out.normals.set(m.normals, at); out.colours.set(m.colours, at);
    at += m.positions.length;
  }
  return out;
}

// Whether (x, y) is inside the polygon `points`, by counting crossings.
function inside(x, y, points) {
  let within = false;
  for (let i = 0, j = points.length - 1; i < points.length; j = i++) {
    const [xi, yi] = points[i], [xj, yj] = points[j];
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) within = !within;
  }
  return within;
}

function dot(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }

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
