// The Wild Fields, drawn: one ground with no edge, the plants somebody let go
// standing where their seeds put them, and the night they stand in.
//
// **Not a plot, so not the plot stage.** Every area page draws a floating
// slab, framed whole, with a rim and sky under it (`makePlotStage` in
// `longwalk.js`), and that is what a made garden is: it has an edge and
// somebody's work inside it. The wild has neither (docs/WEB-GARDENS.md §*The
// Wild Fields*). So this stage frames a window onto ground that runs on past
// it in every direction, and the reader walks it by moving the window rather
// than by choosing a plot.
//
// **What it shares with the plot stage, and why.** A plant is lit by the same
// shader the gardens light it with — `PLANT_FRAGMENT`, exported from
// `longwalk.js` — with the fireflies' light added to it here and nothing taken
// away, so a plant released from the Long Walk is the same plant out here, in a
// different light. The camera is the same true isometric, turned in the same
// quarter turns, and the pad under it is the same pad (`movepad.js`, with
// `roam`). What is the field's own is the ground, the light and the fireflies.
//
// **The field comes round.** It is `SIDE` metres across and its far edges meet
// its near ones (SeedCore's `WildFields`), so the stage works in unwrapped
// metres — walk east for long enough and the numbers keep rising — and reads
// each tile of the field it can see by wrapping its own coordinates round. The
// same plant can be met again by walking far enough, which is what an edgeless
// field of a fixed size is.
//
// **Lit by the Milky Way and by fireflies, and nothing else.** No sun, no
// lamps: nobody put anything out. The galaxy is the app's own night light
// (`GardenLight.galaxyAtFullest`, overhead and cool), the sky and the ground's
// bounce are the app's by night, and the fireflies are the app's drift of them
// (`GardenLamps`: their colour, their reach, how little of the ground they
// paint). They are simply there — so many to a tile, placed by the tile, not
// by the plants — which is the one light the wild has of its own.

import { ROLES, YOUNG, decode, takeResult, attribute, multiply } from './plant.js';
import { PLANT_VERTEX, PLANT_FRAGMENT, COLOUR, program, upload, hash } from './longwalk.js';

// SeedCore's `WildFields`, and the service's `WildFields.php`.
export const SIDE = 64;
export const TILE = 8;
export const TILES = 8;

/// Where a seed stands: two bytes across and the next two along, each in the
/// middle of its step. The service sends this with every planting; it is here
/// for the workbench, which invents plants the service has never seen.
export function spotOf(seedHex) {
  const across = parseInt(seedHex.slice(0, 4), 16);
  const along = parseInt(seedHex.slice(4, 8), 16);
  return [(across + 0.5) / 65536 * SIDE, (along + 0.5) / 65536 * SIDE];
}

// **The night.** The app's numbers by night (`GardenLight.swift`): the galaxy
// at its fullest as the one directional light, a little off the zenith so a
// swell of ground has a lit side and a dark one; the sky and the bounce at
// their night colours, with the moon's share taken out because the wild has
// no moon in it.
//
// **A third brighter than the app's galaxy**, and the ground a little darker
// than the gardens' turf, both judged on renders of a field of a thousand
// (1 October 2026). At the app's own strength a released plant out here was a
// dark green shape on a dark green field: the app's night has a moon in it as
// well, and a plot a few metres across, and this has neither.
export const NIGHT = {
  sun: normalise([-0.30, 0.88, 0.36]),
  sunColour: [0.30, 0.34, 0.46],
  strength: 1.35,
  sky: [0.060, 0.078, 0.130],
  bounce: [0.034, 0.040, 0.058],
};

// The fireflies: `GardenLamps` for `.fireflies`. Their colour; how far their
// light reaches, in metres; how much of a lantern's pool they cast; and how
// high the drift hangs. Two drifts a tile, which over a view of a dozen metres
// is half a dozen in sight: enough that the field has light of its own, few
// enough that the dark is still the dark.
export const FIREFLY = { colour: [0.80, 1.00, 0.48], reach: 0.95, pool: 0.28, height: 0.45, perTile: 2, each: 8 };

// How many drifts light the ground and the plants at once: the nearest to the
// middle of the window. Further ones still blink; at that distance their light
// on the ground is under a pixel's worth.
const LIT = 24;

// **How close the field is seen.** The window's shorter side is this many
// metres at the opening look — about what an area page's band shows of its
// plot, so a plant out here is the size it was in the garden it left — and
// `CLOSEST` at the nearest, the plot stage's nearest, so a flower is the same
// size under a finger here as there.
const VIEW = 4.6;
const CLOSEST = 0.9;

// How far above the ground the point a look is held over sits: a stem's height.
const ABOVE = 0.3;

// **The ground.** A grid this fine, out this far past what the window shows,
// built again when the middle of the window has walked this far from the
// middle it was built round.
const STEP = 0.3;
const MARGIN = 4;
const WALKED = 3;

// The relief: a few long swells, each a whole number of waves across the
// field so the ground meets itself where the field comes round. Wavelengths of
// nine to thirty metres and about a metre and a half from the lowest hollow to
// the highest rise, which is a pasture's lie of the land rather than a bed's.
const SWELLS = [
  [1, 2, 0.42, 0.3], [3, 1, 0.30, 2.1], [2, -3, 0.24, 4.0], [5, 2, 0.12, 1.3], [4, -6, 0.06, 5.2],
];
// And the colour's own, slower and on other waves, so the lusher patches are
// not simply the hollows.
const PATCHES = [[2, 1, 1.7], [-1, 3, 0.4], [4, 3, 2.9]];

export function groundHeight(x, z) {
  let h = 0;
  for (const [i, j, a, p] of SWELLS) h += a * Math.cos((2 * Math.PI * (i * x + j * z)) / SIDE + p);
  return h;
}

function groundSlope(x, z) {
  let dx = 0, dz = 0;
  for (const [i, j, a, p] of SWELLS) {
    const s = -a * Math.sin((2 * Math.PI * (i * x + j * z)) / SIDE + p) * (2 * Math.PI) / SIDE;
    dx += s * i;
    dz += s * j;
  }
  return [dx, dz];
}

// How much darker the field's grass is than a garden's turf: rougher, longer
// and unmown, which takes more of the light and gives less back.
const DUSK = 0.82;

function groundColour(x, z) {
  let m = 0;
  for (const [i, j, p] of PATCHES) m += Math.cos((2 * Math.PI * (i * x + j * z)) / SIDE + p);
  m = 0.5 + m / 6;
  const h = groundHeight(x, z);
  // Lusher in the hollows, where water would lie, and a grain of grass at the
  // grid's own scale so the ground is a sward rather than a sheet.
  const wet = 0.94 + 0.10 * Math.max(-1, Math.min(1, -h / 0.8));
  const ix = Math.round(mod(x, SIDE) / STEP), iz = Math.round(mod(z, SIDE) / STEP);
  const grain = 0.90 + 0.18 * hash(ix * 7919 + iz * 104729);
  return COLOUR.turf.map((t, k) => (t + (COLOUR.grass[k] - t) * m) * wet * grain * DUSK);
}

// **The fireflies' light, added to every light the plant shader already
// sums.** Inserted into `PLANT_FRAGMENT` rather than written out again beside
// it, so the plant is lit here exactly as it is in the gardens plus this. The
// two lines it relies on are checked as it is made, so a change to the garden's
// shader that moved them stops this page loudly rather than lighting it wrong.
const FLY_LIGHT = `
uniform vec4 flies[${LIT}];
uniform vec3 flyColour;
uniform float flyReach;
vec3 fireflies(vec3 p, vec3 n) {
  vec3 sum = vec3(0.0);
  for (int i = 0; i < ${LIT}; i++) {
    vec3 to = flies[i].xyz - p;
    float d = length(to);
    float fall = 1.0 - smoothstep(0.0, flyReach, d);
    float facing = 0.35 + 0.65 * max(dot(n, to / max(d, 1e-4)), 0.0);
    sum += flyColour * flies[i].w * fall * fall * facing;
  }
  return sum;
}
`;
const LIGHT_AT = 'vec3 lightAt(vec3 n) {';
const LIGHT_SUM = 'return sky * hemi + bounce * (1.0 - hemi) + max(dot(n, sun), 0.0) * strength * sunColour;';

function withFireflies(fragment) {
  if (!fragment.includes(LIGHT_AT) || !fragment.includes(LIGHT_SUM)) {
    throw new Error('the garden\'s shader has changed shape: the Wild Fields cannot add the fireflies to it');
  }
  return fragment
    .replace(LIGHT_AT, `${FLY_LIGHT}\n${LIGHT_AT}`)
    .replace(LIGHT_SUM, LIGHT_SUM.replace(';', ' + fireflies(vWorld, n);'));
}

const GROUND_VERTEX = `#version 300 es
in vec3 position; in vec3 normal; in vec3 colour;
uniform mat4 viewProjection;
out vec3 vNormal; out vec3 vColour; out vec3 vWorld;
void main() { vNormal = normal; vColour = colour; vWorld = position; gl_Position = viewProjection * vec4(position, 1.0); }`;

// The ground's light is the plants' light: the same sum, the same encode.
const GROUND_FRAGMENT = withFireflies(`#version 300 es
precision highp float;
in vec3 vNormal; in vec3 vColour; in vec3 vWorld;
uniform vec3 sun, sunColour, sky, bounce;
uniform float strength;
vec3 lightAt(vec3 n) {
  float hemi = 0.5 + 0.5 * n.y;
  return sky * hemi + bounce * (1.0 - hemi) + max(dot(n, sun), 0.0) * strength * sunColour;
}
vec3 encode(vec3 linear) { return pow(max(linear, vec3(0.0)), vec3(1.0 / 2.2)); }
vec3 toLinear(vec3 srgb) { return pow(max(srgb, vec3(0.0)), vec3(2.2)); }
out vec4 outColour;
void main() { outColour = vec4(encode(toLinear(vColour) * lightAt(normalize(vNormal))), 1.0); }`);

// **Where a plant meets the ground.** No sun, so no cast shadow — but grass
// under a plant gets less of the sky than grass in the open, and without that
// a plant reads as laid on the field rather than growing out of it. A soft
// darkening the width of the plant's foot, draped on the ground, multiplied
// over it.
const FOOT_VERTEX = `#version 300 es
in vec3 position; in vec2 uv;
uniform mat4 viewProjection;
out vec2 vUV;
void main() { vUV = uv; gl_Position = viewProjection * vec4(position, 1.0); }`;
const FOOT_FRAGMENT = `#version 300 es
precision highp float;
in vec2 vUV;
out vec4 outColour;
void main() {
  float r = length(vUV);
  float dark = 0.55 * (1.0 - smoothstep(0.15, 1.0, r));
  outColour = vec4(vec3(1.0 - dark), 1.0);
}`;

/// Makes the stage on `canvas`. `source(x, z)` answers a tile of the field —
/// `x` and `z` wrapped, 0 to `TILES` − 1 — as plantings `{ seed, parents,
/// spot }`, the way `GET /api/wild/tile/{x}/{z}` does. `from` is the point of
/// the field the window opens over, in metres.
export function makeWildStage(canvas, e, { source, from = [SIDE / 2, SIDE / 2], report = () => {} }) {
  const gl = canvas.getContext('webgl2', { antialias: true, alpha: true, premultipliedAlpha: true });
  if (!gl) throw new Error('This browser has no WebGL2.');
  const ground = program(gl, GROUND_VERTEX, GROUND_FRAGMENT, ['position', 'normal', 'colour'],
                         ['flies', 'flyColour', 'flyReach']);
  const plantProgram = program(gl, PLANT_VERTEX, withFireflies(PLANT_FRAGMENT),
                               ['position', 'normal', 'uv', 'age'],
                               ['offset', 'colour', 'relief', 'young', 'look', 'flies', 'flyColour', 'flyReach']);
  const footProgram = program(gl, FOOT_VERTEX, FOOT_FRAGMENT, ['position', 'uv'], []);

  // Where the window opens, on the ground, and how it has moved since — in
  // metres across and up the screen, the frame `movepad.js` works in, so that
  // the middle of the pad goes back to where the reader came in.
  const origin = [from[0], ABOVE + groundHeight(from[0], from[1]), from[1]];
  const look = { zoom: 1, x: 0, y: 0 };
  let turn = 0;
  let aspect = 1;
  let drawn = null;

  let groundMesh = null;
  let builtRound = null;
  let reach = 0;

  // Every tile in sight, by its unwrapped number, and what stands in it.
  const tiles = new Map();
  // What the service said about each tile of the field, and each plant grown,
  // kept for the visit: walking back over ground already seen fetches and
  // grows nothing.
  const answered = new Map();
  const grown = new Map();
  let feet = null;

  function eye() {
    const angle = turn * Math.PI / 2;
    const c = Math.cos(angle), s = Math.sin(angle);
    return normalise([c + s, 1, -s + c]);
  }

  function axes() {
    const z = eye();
    const x = normalise(cross([0, 1, 0], z));
    return { x, y: cross(z, x), z };
  }

  // The window's size in metres across and up the screen, at a zoom.
  function windowAt(zoom) {
    const shorter = VIEW / zoom;
    return aspect >= 1 ? { w: shorter * aspect, h: shorter } : { w: shorter, h: shorter / aspect };
  }

  const closest = () => VIEW / CLOSEST;

  // The point of ground under the middle of a look, `ABOVE` it.
  function underMiddle({ x, y }) {
    const { x: X, y: Y, z: Z } = axes();
    const sx = dot(origin, X) + x, sy = dot(origin, Y) + y;
    const t = (origin[1] - sx * X[1] - sy * Y[1]) / Z[1];
    return [0, 1, 2].map((i) => sx * X[i] + sy * Y[i] + t * Z[i]);
  }

  // The look with `point` in the middle of it.
  function over(point, zoom) {
    const { x: X, y: Y } = axes();
    return { zoom, x: dot(point, X) - dot(origin, X), y: dot(point, Y) - dot(origin, Y) };
  }

  // **Where a look may be: anywhere.** The field has no edge, so nothing is
  // held to anything but how close and how far.
  function held(wanted) {
    const next = { ...look, ...wanted };
    return { ...next, zoom: Math.min(Math.max(next.zoom, 1), closest()) };
  }

  function view(zoom = look.zoom) {
    const z = Math.min(Math.max(zoom, 1), closest());
    return { ...look, closest: closest(), metresPerPixel: windowAt(z).w / (canvas.clientWidth || 1) };
  }

  function lookAt(wanted) {
    Object.assign(look, held(wanted));
    draw();
    walked();
    return { ...look };
  }

  function turnBy(quarters) {
    const kept = underMiddle(look);
    turn = (turn + quarters + 4) % 4;
    Object.assign(look, over(kept, look.zoom));
    draw();
  }

  // MARK: The ground

  // How far the ground must run from the middle of the window to fill it at
  // the furthest look: half its width across, and half its height along the
  // ground, which this angle stretches by √3.
  function reachNeeded() {
    const { w, h } = windowAt(1);
    return Math.hypot(w / 2, (h * Math.sqrt(3)) / 2) + MARGIN;
  }

  function buildGround(middle, radius) {
    // On the field's own grid, so ground built round one middle and ground
    // built round the next agree vertex for vertex where they overlap, and a
    // rebuild is not seen.
    const cx = Math.round(middle[0] / STEP) * STEP, cz = Math.round(middle[2] / STEP) * STEP;
    const n = Math.ceil(radius / STEP);
    const side = 2 * n + 1;
    const points = new Float32Array(side * side * 3), normals = new Float32Array(side * side * 3),
          colours = new Float32Array(side * side * 3);
    for (let j = 0; j < side; j++) {
      for (let i = 0; i < side; i++) {
        const x = cx + (i - n) * STEP, z = cz + (j - n) * STEP, k = (j * side + i) * 3;
        points[k] = x; points[k + 1] = groundHeight(x, z); points[k + 2] = z;
        const [dx, dz] = groundSlope(x, z);
        const l = Math.hypot(dx, 1, dz);
        normals[k] = -dx / l; normals[k + 1] = 1 / l; normals[k + 2] = -dz / l;
        colours.set(groundColour(x, z), k);
      }
    }
    const positions = [], ns = [], cs = [];
    const corner = (i, j) => {
      const k = (j * side + i) * 3;
      positions.push(points[k], points[k + 1], points[k + 2]);
      ns.push(normals[k], normals[k + 1], normals[k + 2]);
      cs.push(colours[k], colours[k + 1], colours[k + 2]);
    };
    for (let j = 0; j < side - 1; j++) {
      for (let i = 0; i < side - 1; i++) {
        corner(i, j); corner(i, j + 1); corner(i + 1, j);
        corner(i + 1, j); corner(i, j + 1); corner(i + 1, j + 1);
      }
    }
    if (groundMesh) groundMesh.release();
    groundMesh = upload(gl, ground, { positions: new Float32Array(positions), normals: new Float32Array(ns),
                                      colours: new Float32Array(cs) });
    builtRound = [cx, cz];
    reach = radius;
  }

  // MARK: The plants

  // Every unwrapped tile the ground reaches.
  function tilesInSight() {
    const [cx, cz] = builtRound;
    const out = [];
    for (let ux = Math.floor((cx - reach) / TILE); ux <= Math.floor((cx + reach) / TILE); ux++) {
      for (let uz = Math.floor((cz - reach) / TILE); uz <= Math.floor((cz + reach) / TILE); uz++) {
        out.push([ux, uz]);
      }
    }
    return out;
  }

  // Called whenever the window has moved: builds the ground again if the
  // window has walked far enough from where it was built, and brings in the
  // tiles that have come into sight and lets go of the ones that have left.
  let fetching = Promise.resolve();
  function walked() {
    const middle = underMiddle(look);
    const needed = reachNeeded();
    if (builtRound && Math.hypot(middle[0] - builtRound[0], middle[2] - builtRound[1]) < WALKED
        && reach >= needed) return;
    buildGround(middle, needed);
    const wanted = new Set(tilesInSight().map(([ux, uz]) => `${ux},${uz}`));
    for (const [key, tile] of tiles) {
      if (!wanted.has(key)) { tile.plants.forEach(releasePlant); tiles.delete(key); }
    }
    drift();
    rebuildFeet();
    draw();
    // One fill at a time, in order, and a tile that could not be fetched is
    // simply not there yet: the next walk asks for it again.
    fetching = fetching.then(() => fill(wanted)).catch((trouble) => {
      console.warn('a tile of the field could not be grown:', trouble);
      report(false, trouble);
    });
  }

  async function fill(wanted) {
    let since = performance.now();
    for (const key of wanted) {
      if (tiles.has(key) || !builtRound) continue;
      const [ux, uz] = key.split(',').map(Number);
      const tx = mod(ux, TILES), tz = mod(uz, TILES);
      const here = `${tx},${tz}`;
      if (!answered.has(here)) answered.set(here, await source(tx, tz));
      // The window may have walked on while that was asked.
      if (!tilesInSight().some(([a, b]) => a === ux && b === uz)) continue;
      const tile = { plants: [] };
      tiles.set(key, tile);
      const shiftX = (ux - tx) * TILE, shiftZ = (uz - tz) * TILE;
      for (const p of answered.get(here)) {
        const shape = growOne(p);
        if (!shape) continue;
        const x = p.spot[0] + shiftX, z = p.spot[1] + shiftZ;
        tile.plants.push(addPlant(x, groundHeight(x, z), z, shape, p));
        if (performance.now() - since > 16) {
          rebuildFeet();
          draw();
          report(true);
          await breathe();
          since = performance.now();
          // Walked away from while it was growing: let go of what has been
          // grown into it, since nothing else now holds it.
          if (tiles.get(key) !== tile) { tile.plants.forEach(releasePlant); tile.plants.length = 0; break; }
        }
      }
    }
    rebuildFeet();
    draw();
    report(false);
  }

  // **A released plant is grown from its seed and both parents**, as a hybrid
  // is in every garden. The meeting is not sent — the field does not keep it —
  // and the module does not read it for anything but the lineage it writes
  // down (`Genome.hybrid`), so it is handed a meeting of noughts. A planting
  // with no parents, which only the workbench invents, grows from its seed.
  const NO_MEETING = '0'.repeat(64);
  function growOne(p) {
    if (grown.has(p.seed)) return grown.get(p.seed);
    const lineage = p.parents ?? [];
    const words = new TextEncoder().encode(
      lineage.length === 2 ? [p.seed, ...lineage, NO_MEETING].join(' ') : p.seed);
    const pointer = e.pg_alloc(words.length);
    new Uint8Array(e.memory.buffer, pointer, words.length).set(words);
    const length = lineage.length === 2 ? e.pg_grow_hybrid(pointer, words.length) : e.pg_grow(pointer, words.length);
    e.pg_free(pointer);
    const shape = length === 0 ? null : decode(takeResult(e, length));
    grown.set(p.seed, shape);
    return shape;
  }

  function texture(t) {
    const handle = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, handle);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, t.side, t.side, 0, gl.RGBA, gl.UNSIGNED_BYTE, t.pixels);
    gl.generateMipmap(gl.TEXTURE_2D);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    return handle;
  }

  function addPlant(x, y, z, shape, who) {
    const textures = {}, relief = {};
    for (const role of ROLES) {
      textures[role] = texture(shape.textures[role]);
      relief[role] = texture(shape.relief[role]);
    }
    const parts = shape.parts.map((part) => {
      const vao = gl.createVertexArray();
      gl.bindVertexArray(vao);
      const buffers = [
        attribute(gl, plantProgram.at.position, part.positions, 3),
        attribute(gl, plantProgram.at.normal, part.normals, 3),
        attribute(gl, plantProgram.at.uv, part.uvs, 2),
        attribute(gl, plantProgram.at.age, part.maturity, 1),
      ];
      const indexBuffer = gl.createBuffer();
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
      gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, part.indices, gl.STATIC_DRAW);
      buffers.push(indexBuffer);
      return { vao, buffers, count: part.indices.length, role: part.role };
    });
    gl.bindVertexArray(null);
    const foot = Math.max(0.12, Math.min(0.6,
      0.7 * Math.max(...[0, 2].flatMap((i) => [Math.abs(shape.min?.[i] ?? 0), Math.abs(shape.max?.[i] ?? 0)]))));
    return { x, y, z, parts, textures, relief, foot, height: Math.max(0, shape.max?.[1] ?? 0), who };
  }

  function releasePlant(plant) {
    for (const part of plant.parts) { part.buffers.forEach((b) => gl.deleteBuffer(b)); gl.deleteVertexArray(part.vao); }
    Object.values(plant.textures).forEach((t) => gl.deleteTexture(t));
    Object.values(plant.relief).forEach((t) => gl.deleteTexture(t));
  }

  const standing = () => [...tiles.values()].flatMap((tile) => tile.plants);

  // Each plant's foot, draped on the ground: a five-by-five sheet over its
  // radius, so it follows a slope rather than cutting into it.
  function rebuildFeet() {
    if (feet) { feet.buffers.forEach((b) => gl.deleteBuffer(b)); gl.deleteVertexArray(feet.vao); feet = null; }
    const positions = [], uvs = [], indices = [];
    for (const plant of standing()) {
      const base = positions.length / 3;
      for (let j = 0; j <= 4; j++) {
        for (let i = 0; i <= 4; i++) {
          const u = i / 2 - 1, v = j / 2 - 1;
          const x = plant.x + u * plant.foot, z = plant.z + v * plant.foot;
          positions.push(x, groundHeight(x, z) + 0.01, z);
          uvs.push(u, v);
        }
      }
      for (let j = 0; j < 4; j++) {
        for (let i = 0; i < 4; i++) {
          const k = base + j * 5 + i;
          indices.push(k, k + 5, k + 1, k + 1, k + 5, k + 6);
        }
      }
    }
    if (!indices.length) return;
    const vao = gl.createVertexArray();
    gl.bindVertexArray(vao);
    const buffers = [
      attribute(gl, footProgram.at.position, new Float32Array(positions), 3),
      attribute(gl, footProgram.at.uv, new Float32Array(uvs), 2),
    ];
    const indexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint32Array(indices), gl.STATIC_DRAW);
    buffers.push(indexBuffer);
    gl.bindVertexArray(null);
    feet = { vao, buffers, count: indices.length };
  }

  // MARK: The fireflies

  // Every drift on the ground in sight: where it hangs, and the seed of its
  // own wandering. Placed by the tile it is in, so a drift is where it was on
  // every visit and the same drift is met again where the field comes round.
  let drifts = [];
  function drift() {
    drifts = [];
    for (const [ux, uz] of tilesInSight()) {
      const tx = mod(ux, TILES), tz = mod(uz, TILES);
      for (let k = 0; k < FIREFLY.perTile; k++) {
        const key = (tx * TILES + tz) * 31 + k * 7 + 1;
        const x = ux * TILE + hash(key * 1.37) * TILE, z = uz * TILE + hash(key * 2.11) * TILE;
        const y = groundHeight(x, z) + FIREFLY.height * (0.7 + 0.6 * hash(key * 3.07));
        drifts.push({ at: [x, y, z], seed: key });
      }
    }
  }

  function litBy() {
    const middle = underMiddle(look);
    const near = drifts
      .map((d) => ({ d, far: Math.hypot(d.at[0] - middle[0], d.at[2] - middle[2]) }))
      .sort((a, b) => a.far - b.far).slice(0, LIT);
    const flies = new Float32Array(LIT * 4);
    near.forEach(({ d }, i) => flies.set([...d.at, FIREFLY.pool], i * 4));
    return flies;
  }

  // MARK: Drawing

  function draw() {
    const ratio = window.devicePixelRatio || 1;
    const width = Math.round(canvas.clientWidth * ratio), height = Math.round(canvas.clientHeight * ratio);
    if (!width || !height) return;
    if (canvas.width !== width || canvas.height !== height) { canvas.width = width; canvas.height = height; }
    aspect = width / height || 1;
    if (!groundMesh) return;
    gl.viewport(0, 0, width, height);
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.enable(gl.DEPTH_TEST);
    gl.disable(gl.CULL_FACE);

    const { x: X, y: Y, z: Z } = axes();
    const viewM = [X[0], Y[0], Z[0], 0, X[1], Y[1], Z[1], 0, X[2], Y[2], Z[2], 0, 0, 0, 0, 1];
    const { w, h } = windowAt(look.zoom);
    const cx = dot(origin, X) + look.x, cy = dot(origin, Y) + look.y;
    const depth = dot(underMiddle(look), Z);
    const viewProjection = multiply(ortho(cx, cy, w, h, depth - 80, depth + 80), viewM);
    drawn = viewProjection;
    const flies = litBy();

    for (const p of [ground, plantProgram]) {
      gl.useProgram(p.program);
      gl.uniformMatrix4fv(p.at.viewProjection, false, viewProjection);
      gl.uniform3fv(p.at.sun, NIGHT.sun);
      gl.uniform3fv(p.at.sunColour, NIGHT.sunColour);
      gl.uniform3fv(p.at.sky, NIGHT.sky);
      gl.uniform3fv(p.at.bounce, NIGHT.bounce);
      gl.uniform1f(p.at.strength, NIGHT.strength);
      gl.uniform4fv(p.at.flies, flies);
      gl.uniform3fv(p.at.flyColour, FIREFLY.colour);
      gl.uniform1f(p.at.flyReach, FIREFLY.reach);
    }

    gl.useProgram(ground.program);
    groundMesh.draw();

    if (feet) {
      gl.useProgram(footProgram.program);
      gl.uniformMatrix4fv(footProgram.at.viewProjection, false, viewProjection);
      gl.enable(gl.BLEND);
      gl.blendFunc(gl.DST_COLOR, gl.ZERO);
      gl.depthMask(false);
      gl.depthFunc(gl.LEQUAL);
      gl.bindVertexArray(feet.vao);
      gl.drawElements(gl.TRIANGLES, feet.count, gl.UNSIGNED_INT, 0);
      gl.bindVertexArray(null);
      gl.depthFunc(gl.LESS);
      gl.depthMask(true);
      gl.disable(gl.BLEND);
    }

    gl.useProgram(plantProgram.program);
    gl.uniform1i(plantProgram.at.colour, 0);
    gl.uniform1i(plantProgram.at.relief, 1);
    gl.uniform3fv(plantProgram.at.look, Z);
    for (const plant of standing()) {
      gl.uniform3fv(plantProgram.at.offset, [plant.x, plant.y, plant.z]);
      for (const part of plant.parts) {
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, plant.textures[part.role]);
        gl.activeTexture(gl.TEXTURE1);
        gl.bindTexture(gl.TEXTURE_2D, plant.relief[part.role]);
        gl.uniform4fv(plantProgram.at.young, YOUNG[ROLES[part.role]] ?? [0, 0, 0, 0]);
        gl.bindVertexArray(part.vao);
        gl.drawElements(gl.TRIANGLES, part.count, gl.UNSIGNED_INT, 0);
      }
    }
    gl.bindVertexArray(null);
  }

  // Where a point of the field was last drawn, in CSS pixels from the
  // canvas's top-left corner.
  function toScreen([x, y, z]) {
    if (!drawn) return [NaN, NaN];
    const m = drawn;
    const sx = m[0] * x + m[4] * y + m[8] * z + m[12];
    const sy = m[1] * x + m[5] * y + m[9] * z + m[13];
    return [(sx + 1) / 2 * canvas.clientWidth, (1 - sy) / 2 * canvas.clientHeight];
  }

  // What `movepad.js` asks of a stage that has plots, answered for a field
  // that has none: there is no seam to cross and no next plot along.
  const seams = () => ({ back: false, on: false });
  const carried = (wanted) => held(wanted);
  function onScreen(direction) {
    const { x: X, y: Y } = axes();
    return [dot(direction, X), dot(direction, Y)];
  }

  // How many pixels a metre is at this look, for the fireflies.
  const pixelsPerMetre = () => 1 / view().metresPerPixel;

  new ResizeObserver(() => { draw(); walked(); }).observe(canvas);
  draw();
  walked();

  return {
    draw, turnBy, turn: () => turn, view, held, lookAt, carried, seams, onScreen, toScreen,
    drifts: () => drifts, pixelsPerMetre, standing, settled: () => fetching,
  };
}

/// The fireflies themselves, over the field: each drift a handful of very
/// small lights wandering about its middle and blinking on their own clocks,
/// the app's `Fireflies` drawn in a browser. On a canvas of their own over the
/// stage, because they move and the field does not: the field is drawn when
/// the window moves, and this thirty times a second.
///
/// Still, and steadily lit, for a reader who has asked for less motion.
export function flyOver(canvas, stage) {
  const context = canvas.getContext('2d');
  const still = window.matchMedia('(prefers-reduced-motion: reduce)');
  const [r, g, b] = FIREFLY.colour.map((v) => Math.round(v * 255));
  let last = 0;
  let frame = 0;
  const paint = (now) => {
    frame = requestAnimationFrame(paint);
    if (now - last < 33 && !still.matches) return;
    last = now;
    const ratio = window.devicePixelRatio || 1;
    const width = canvas.clientWidth, height = canvas.clientHeight;
    if (canvas.width !== Math.round(width * ratio)) canvas.width = Math.round(width * ratio);
    if (canvas.height !== Math.round(height * ratio)) canvas.height = Math.round(height * ratio);
    context.setTransform(ratio, 0, 0, ratio, 0, 0);
    context.clearRect(0, 0, width, height);
    context.globalCompositeOperation = 'lighter';
    const metre = stage.pixelsPerMetre();
    const time = still.matches ? 0 : now / 1000;
    for (const drift of stage.drifts()) {
      for (let i = 0; i < FIREFLY.each; i++) {
        const phase = hash(drift.seed * 13 + i * 3.1) * Math.PI * 2;
        const speed = 0.25 + hash(drift.seed * 17 + i * 4.3) * 0.35;
        const wander = 0.10 + hash(drift.seed * 19 + i * 5.7) * 0.22;
        const lift = (hash(drift.seed * 23 + i * 6.1) - 0.5) * 0.3;
        const at = [
          drift.at[0] + Math.cos(time * speed + phase) * wander,
          drift.at[1] + lift + Math.sin(time * speed * 1.3 + phase * 0.7) * wander * 0.5,
          drift.at[2] + Math.sin(time * speed * 0.8 + phase * 1.9) * wander,
        ];
        const [x, y] = stage.toScreen(at);
        if (!(x > -20 && x < width + 20 && y > -20 && y < height + 20)) continue;
        const blink = still.matches ? 0.6 : Math.max(0, Math.sin(time * (1.1 + speed) + phase * 3));
        const alpha = 0.25 + 0.75 * blink;
        const halo = Math.min(16, Math.max(2.5, (0.02 + 0.05 * blink) * metre));
        const glow = context.createRadialGradient(x, y, 0, x, y, halo);
        glow.addColorStop(0, `rgb(${r} ${g} ${b} / ${alpha * 0.5})`);
        glow.addColorStop(1, `rgb(${r} ${g} ${b} / 0)`);
        context.fillStyle = glow;
        context.beginPath();
        context.arc(x, y, halo, 0, Math.PI * 2);
        context.fill();
        context.fillStyle = `rgb(${r} ${g} ${b} / ${alpha})`;
        context.beginPath();
        context.arc(x, y, Math.max(0.9, Math.min(2.2, 0.012 * metre)), 0, Math.PI * 2);
        context.fill();
      }
    }
  };
  frame = requestAnimationFrame(paint);
  return { stop: () => cancelAnimationFrame(frame) };
}

// MARK: Arithmetic

function ortho(cx, cy, w, h, near, far) {
  // `near` and `far` are depths along the view's own back axis, which points
  // at the eye: the larger, the nearer.
  const l = cx - w / 2, r = cx + w / 2, b = cy - h / 2, t = cy + h / 2;
  return [2 / (r - l), 0, 0, 0, 0, 2 / (t - b), 0, 0, 0, 0, -2 / (far - near), 0,
    -(r + l) / (r - l), -(t + b) / (t - b), (far + near) / (far - near), 1];
}

const breathe = () => new Promise((resume) => setTimeout(resume, 0));
function mod(a, n) { return ((a % n) + n) % n; }
function dot(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }
function cross(a, b) { return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]; }
function normalise(v) { const l = Math.hypot(...v); return v.map((x) => x / l); }
