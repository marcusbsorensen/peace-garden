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
import { makeWildWater } from './wildwater.js';
import { fieldInput, groundDetail } from './wildground.js';

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
  // Lusher in the hollows, where water would lie. The grain the grid used to
  // carry, a tone a vertex every 30 cm, is the ground's detail's now
  // (`wildground.js`), finer and with no triangles in it.
  const wet = 0.94 + 0.10 * Math.max(-1, Math.min(1, -h / 0.8));
  return COLOUR.turf.map((t, k) => (t + (COLOUR.grass[k] - t) * m) * wet * DUSK);
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
const FLY_UNIFORMS = ['flies', 'flyColour', 'flyReach'];
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
// Its fragment shader is the ground's detail's (`groundFragment` in
// `wildground.js`, 2 October 2026): the sward between the tufts and the earth
// where it thins, and what the field's other layers say is worn or wet.

// **The water** (`wildwater.js`, chosen 2 October 2026). The gardens' water
// — their two colours, lit by the ground's own sum, fireflies and all — and
// what a still pond shows at night that a garden's water, which is a colour
// rather than a window, never has: the sky in it, broken up by the wind.
//
// - **The stars it mirrors are the sky's own** (`sky.js`), read from the
//   canvas they are drawn on behind the field: the same column of the sky,
//   and an altitude that climbs toward the zenith the nearer the water is to
//   the reader, as a pond seen from above shows it. Dimmed, as dark water
//   gives back little, and made to waver by the ripples. Plausible rather
//   than exact: an orthographic view has no one angle to mirror the sky at.
// - **The ripples** are slow, low swells of three sizes drifting different
//   ways, each turned its own way so nothing in them runs straight, and held
//   still for a reader who has asked for less motion. They tilt the surface a
//   few degrees, which moves the stars about and changes how much the water
//   gives back: a Fresnel sheen of the night sky's own colour, brighter where
//   a ripple turns the surface further from the eye.
// - **Only where there is depth to it.** The shallows show the floor, so the
//   sky comes in over the first few centimetres, and a puddle in a damp patch
//   shows almost none. The opacity at the shore is worked out for each pixel
//   from how deep the water is there, not carried from the corners, which
//   would draw every triangle of the shore as a tooth.
const WATER_VERTEX = `#version 300 es
in vec3 position; in vec3 normal; in vec3 colour; in float depth;
uniform mat4 viewProjection;
out vec3 vNormal; out vec3 vColour; out vec3 vWorld; out float vDepth;
void main() { vNormal = normal; vColour = colour; vWorld = position; vDepth = depth; gl_Position = viewProjection * vec4(position, 1.0); }`;
const WATER_FRAGMENT = withFireflies(`#version 300 es
precision highp float;
in vec3 vNormal; in vec3 vColour; in vec3 vWorld; in float vDepth;
uniform vec3 sun, sunColour, sky, bounce;
uniform float strength;
uniform float time, starlit;
uniform vec3 look, across, toward;
uniform vec2 screen;
uniform sampler2D starlight;
vec3 lightAt(vec3 n) {
  float hemi = 0.5 + 0.5 * n.y;
  return sky * hemi + bounce * (1.0 - hemi) + max(dot(n, sun), 0.0) * strength * sunColour;
}
vec3 encode(vec3 linear) { return pow(max(linear, vec3(0.0)), vec3(1.0 / 2.2)); }
vec3 toLinear(vec3 srgb) { return pow(max(srgb, vec3(0.0)), vec3(2.2)); }
float hash(vec2 p) { p = fract(p * vec2(127.1, 311.7)); p += dot(p, p + 19.19); return fract(p.x * p.y); }
float noise(vec2 p) {
  vec2 i = floor(p), f = fract(p), u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float swell(vec2 p) {
  vec2 a = mat2(0.80, -0.60, 0.60, 0.80) * p * 1.7 + vec2(0.050, 0.031) * time;
  vec2 b = mat2(0.28, 0.96, -0.96, 0.28) * p * 3.9 + vec2(-0.071, 0.043) * time;
  vec2 c = mat2(-0.53, 0.85, -0.85, -0.53) * p * 9.1 + vec2(0.029, -0.090) * time;
  return 0.55 * noise(a) + 0.30 * noise(b) + 0.15 * noise(c);
}
out vec4 outColour;
const float FEATHER = 0.005;
const float RIPPLE = 0.021;
void main() {
  vec3 base = toLinear(vColour) * lightAt(normalize(vNormal));
  vec2 p = vWorld.xz;
  float d = 0.02;
  vec3 n = normalize(vec3(-(swell(p + vec2(d, 0.0)) - swell(p - vec2(d, 0.0))) * RIPPLE / (2.0 * d), 1.0,
                          -(swell(p + vec2(0.0, d)) - swell(p - vec2(0.0, d))) * RIPPLE / (2.0 * d)));
  // How much of the sky the water gives back, against how much it gives back
  // lying still: Schlick's, for water.
  float still = 0.02 + 0.98 * pow(1.0 - look.y, 5.0);
  float glance = (0.02 + 0.98 * pow(1.0 - max(dot(n, look), 0.0), 5.0)) / still;
  float open = smoothstep(0.01, 0.06, vDepth);
  // The sky this water shows: the column above it, and an altitude from low
  // over the horizon near the top of the window to high near the foot, moved
  // by the ripples about twice as far as they tilt the water, as a mirror
  // moves what it shows.
  vec2 at = gl_FragCoord.xy / screen;
  float altitude = 15.0 + 70.0 * (1.0 - at.y) + 90.0 * dot(n, toward);
  vec2 onSky = vec2(at.x + 0.28 * dot(n, across), 0.5 - altitude / 180.0);
  // Drawn out a little down the view, as a light on moving water is, rather
  // than a sharp point.
  vec2 down = vec2(0.0, 1.0 / screen.y);
  vec3 star = (texture(starlight, onSky - down).rgb + texture(starlight, onSky).rgb
               + texture(starlight, onSky + down).rgb) / 3.0;
  vec3 mirrored = toLinear(star) * 0.42 * starlit;
  vec3 sheen = sky * 0.12;
  vec3 colour = base + open * glance * (sheen + mirrored);
  outColour = vec4(encode(colour), smoothstep(0.0, FEATHER, vDepth));
}`);

// How many times finer the ground is drawn where there is water: under 4 cm,
// so a shore is a curve and not a polygon of the field's 0.3 m cells.
const FINE = 8;

// The texture units the field's own textures are bound to. The plants use 0
// and 1, and the worn paths 2 (`wear.js`); the wet is 3, and the sky the
// water mirrors 4.
const WET = 3;
const STARLIGHT = 4;

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
///
/// **The ground in detail** (2 October 2026; `wildground.js`): tufts of grass,
/// pebbles, and the earth between them, in the pasture Marcus chose that day.
/// What visitors have worn and what the water has wetted are its two inputs.
///
/// **Paths that visitors wear** (2 October 2026, on /dev only; `wear.js`):
/// `wear`, when given, is the worn ground — GLSL defining `wearAt` over the
/// field, with the texture it reads and a `bind` — and the ground's detail
/// thins, flattens and gives way to bare earth where it says; and
/// `looked(point)` is told the ground under the middle of the window each time
/// the window moves or turns. The field knows nothing else about either.
///
/// **The wet is the water's own** (`wildwater.js`): 1 under a pond or a
/// puddle, and towards that its margin's wet and mud, sampled into a texture
/// the ground's detail reads (`fieldInput`), and sampled again whenever what
/// has arrived changes the water.
export function makeWildStage(canvas, e, { source, from = [SIDE / 2, SIDE / 2], report = () => {},
                                          wear = null, looked = () => {} }) {
  const gl = canvas.getContext('webgl2', { antialias: true, alpha: true, premultipliedAlpha: true });
  if (!gl) throw new Error('This browser has no WebGL2.');
  // **The field's water** (`wildwater.js`): what the hollows hold near the
  // lotuses the service has answered so far, and its surface for the ground
  // as last built.
  const water = makeWildWater(e, { side: SIDE, height: groundHeight });
  // The ground's detail stands on the floor the water has dug rather than over
  // it, and reads how wet the ground is from the water.
  const wet = fieldInput('wet', water.wetness, { unit: WET });
  const detail = groundDetail(gl, { side: SIDE, height: water.floorAt, colour: groundColour, wear, wet,
                                    light: withFireflies, lit: FLY_UNIFORMS });
  const ground = program(gl, GROUND_VERTEX, withFireflies(detail.fragment), ['position', 'normal', 'colour'],
                         [...FLY_UNIFORMS, ...detail.uniforms]);
  const waterProgram = program(gl, WATER_VERTEX, WATER_FRAGMENT, ['position', 'normal', 'colour', 'depth'],
    [...FLY_UNIFORMS, 'time', 'starlit', 'look', 'across', 'toward', 'screen', 'starlight']);
  let sheet = null;
  // The sky's canvas, which the water mirrors, as a texture: uploaded when the
  // page says the sky was drawn again, and once a minute, as the sky turns.
  let skySource = null, skyTexture = null, skyAt = -Infinity, skyStale = false;
  // What drawing has cost, for the workbench to report: each frame's work on
  // this side of the GPU, each time the ground was built again for water, and
  // each time the wet was sampled again for it.
  const cost = { frames: [], rebuilds: [], builds: [], wetted: [] };
  const plantProgram = program(gl, PLANT_VERTEX, withFireflies(PLANT_FRAGMENT),
                               ['position', 'normal', 'uv', 'age'],
                               ['offset', 'colour', 'relief', 'young', 'look', ...FLY_UNIFORMS]);
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
    looked(groundUnder(look));
    return { ...look };
  }

  function turnBy(quarters) {
    const kept = underMiddle(look);
    turn = (turn + quarters + 4) % 4;
    Object.assign(look, over(kept, look.zoom));
    draw();
    looked(groundUnder(look));
  }

  // The ground itself under the middle of a look, where `underMiddle` is a
  // point at one height: down the line of sight until it meets the swells.
  // Each step closes most of the gap, because no swell is as steep as the
  // line of sight.
  function groundUnder({ x, y }) {
    const { x: X, y: Y, z: Z } = axes();
    const sx = dot(origin, X) + x, sy = dot(origin, Y) + y;
    let t = (origin[1] - sx * X[1] - sy * Y[1]) / Z[1];
    const at = () => [0, 1, 2].map((i) => sx * X[i] + sy * Y[i] + t * Z[i]);
    for (let k = 0; k < 8; k++) {
      const p = at();
      t += (groundHeight(p[0], p[2]) - p[1]) / Z[1];
    }
    return at();
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
    const started = performance.now();
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
    // The cells the water asks to have drawn finer, by the field's own cell
    // numbers, are left out here and drawn by `refine`.
    const box = [cx - n * STEP, cz - n * STEP, cx + n * STEP, cz + n * STEP];
    const finer = water.cells(...box, STEP);
    const left = [];
    const first = [Math.round(cx / STEP) - n, Math.round(cz / STEP) - n];
    for (let j = 0; j < side - 1; j++) {
      for (let i = 0; i < side - 1; i++) {
        if (finer.has(first[0] + i, first[1] + j)) { left.push([i, j]); continue; }
        corner(i, j); corner(i, j + 1); corner(i + 1, j);
        corner(i + 1, j); corner(i, j + 1); corner(i + 1, j + 1);
      }
    }
    const fine = refine(left.map(([i, j]) => [first[0] + i, first[1] + j]));
    const wet = fine.wet;
    if (groundMesh) groundMesh.release();
    groundMesh = upload(gl, ground, { positions: joined([positions, ...fine.positions]),
                                      normals: joined([ns, ...fine.normals]), colours: joined([cs, ...fine.colours]) });
    sheet?.release();
    sheet = wet.positions.length ? uploadSheet(wet) : null;
    // Where there is water deep enough for its ripples to show, which is
    // all the drawing for them waits on.
    open = null;
    for (let k = 0; k < wet.depths.length; k++) {
      if (wet.depths[k] < 0.02) continue;
      const x = wet.positions[k * 3], y = wet.positions[k * 3 + 1], z = wet.positions[k * 3 + 2];
      if (!open) open = [x, y, z, x, y, z];
      open = [Math.min(open[0], x), Math.min(open[1], y), Math.min(open[2], z),
              Math.max(open[3], x), Math.max(open[4], y), Math.max(open[5], z)];
    }
    builtRound = [cx, cz];
    builtFor = { middle, box, version: water.version, key: finer.key };
    reach = radius;
    cost.builds.push(performance.now() - started);
    ripple();
  }

  // **When what has arrived changes the water, the ground is built again
  // where it stands**, and every plant is set again on what is now under it.
  // The window does not move, and nothing else is fetched or grown.
  let builtFor = null, refreshed = -Infinity, wetFor = water.version;
  function refresh({ soon = false } = {}) {
    const built = !builtFor || builtFor.version === water.version;
    if (built && wetFor === water.version) return;
    // While a tile is still growing, no more than four times a second: a
    // lotus set on water the ground has not yet flooded waits that long.
    if (soon && performance.now() - refreshed < 250) return;
    refreshed = performance.now();
    wetted();
    if (built) return;
    // Only if it changed the water on the ground that is built: most lotuses
    // that arrive change water somewhere else.
    if (water.cells(...builtFor.box, STEP).key === builtFor.key) {
      builtFor.version = water.version;
      return;
    }
    const started = performance.now();
    buildGround(builtFor.middle, reach);
    for (const plant of standing()) plant.y = water.footAt(plant.x, plant.z, plant.who);
    rebuildFeet();
    cost.rebuilds.push(performance.now() - started);
  }

  // **And the ground's detail is told how wet the field now is**: the wet
  // sampled again from the water, wherever it changed, and the tufts and
  // stones grown again on the floor it has dug — sedge at a pond's margin,
  // nothing where the water is.
  function wetted() {
    if (wetFor === water.version) return;
    const started = performance.now();
    wetFor = water.version;
    wet.set(water.wetness);
    detail.changed({ regrow: true });
    cost.wetted.push(performance.now() - started);
  }

  // **The ground again under 4 cm, where there is water** (`wildwater.js`).
  // Each cell left out above is drawn as `FINE` × `FINE` cells, its height and
  // colour read between the field's own corners so its edges meet the cells
  // beside it exactly, and then handed to the water for the floor it has dug
  // and the colour it has wetted. The water lies at its level wherever the
  // floor is under it, cut at the shore along the line where the two cross,
  // so a shore is where the ground comes up through the water rather than an
  // edge anybody drew.
  //
  // **Each cell is worked out once for the water that reaches it, and kept**,
  // by its number and that water's: a lotus arriving, or the window walking
  // on, works out again only the cells whose water changed. Worked out afresh
  // every time, the ground near a pond took seventy milliseconds to build,
  // and it is built again for every lotus that arrives near it.
  const refined = new Map();
  function refine(cells) {
    const h = STEP / FINE;
    const done = cells.map(([ix, iz]) => {
      const local = water.within(ix * STEP - h, iz * STEP - h, (ix + 1) * STEP + h, (iz + 1) * STEP + h);
      const key = `${ix},${iz} ${local.key}`;
      let cell = refined.get(key);
      if (!cell) {
        cell = refineCell(ix, iz, local);
        if (refined.size > 8000) refined.clear();
        refined.set(key, cell);
      }
      return cell;
    });
    return {
      positions: done.map((c) => c.positions), normals: done.map((c) => c.normals), colours: done.map((c) => c.colours),
      wet: { positions: joined(done.map((c) => c.wet.positions)), normals: joined(done.map((c) => c.wet.normals)),
             colours: joined(done.map((c) => c.wet.colours)), depths: joined(done.map((c) => c.wet.depths)) },
    };
  }

  // Arrays, end to end, as one.
  function joined(parts) {
    const all = new Float32Array(parts.reduce((n, part) => n + part.length, 0));
    let at = 0;
    for (const part of parts) { all.set(part, at); at += part.length; }
    return all;
  }

  // One cell of the field at `FINE` × `FINE`, with a point of the fine grid
  // all round it so the floor's slope at its edges is read across them.
  function refineCell(ix, iz, local) {
    const N = FINE + 3, h = STEP / FINE;
    const at = (a, b) => (b + 1) * N + (a + 1);
    // The field's own corners, as its 0.3 m grid has them.
    const corners = new Map();
    const corner = (gx, gz) => {
      const key = `${gx},${gz}`;
      if (!corners.has(key)) {
        const x = gx * STEP, z = gz * STEP;
        corners.set(key, { y: groundHeight(x, z), colour: groundColour(x, z), slope: groundSlope(x, z) });
      }
      return corners.get(key);
    };
    const X = new Float32Array(N * N), Z = new Float32Array(N * N), G = new Float32Array(N * N);
    const floor = new Float32Array(N * N), level = new Float32Array(N * N);
    const tone = new Float32Array(N * N * 3), slope = new Float32Array(N * N * 2);
    for (let b = -1; b <= FINE + 1; b++) {
      for (let a = -1; a <= FINE + 1; a++) {
        const gx = ix + Math.floor(a / FINE), gz = iz + Math.floor(b / FINE);
        const u = (a - Math.floor(a / FINE) * FINE) / FINE, v = (b - Math.floor(b / FINE) * FINE) / FINE;
        const c00 = corner(gx, gz), c10 = corner(gx + 1, gz), c01 = corner(gx, gz + 1), c11 = corner(gx + 1, gz + 1);
        const between = (read) => (read(c00) * (1 - u) + read(c10) * u) * (1 - v) + (read(c01) * (1 - u) + read(c11) * u) * v;
        const k = at(a, b), x = ix * STEP + a * h, z = iz * STEP + b * h, g = between((c) => c.y);
        const s = water.sample(x, z, g, [0, 1, 2].map((i) => between((c) => c.colour[i])), local);
        X[k] = x; Z[k] = z; G[k] = g;
        floor[k] = s.floor;
        level[k] = Number.isFinite(s.level) ? s.level : s.floor - 1;
        tone.set(s.colour, k * 3);
        slope[k * 2] = between((c) => c.slope[0]);
        slope[k * 2 + 1] = between((c) => c.slope[1]);
      }
    }
    // The floor's normal: the field's own slope, and the slope of what the
    // water has dug or heaped on it, across the fine grid.
    const dug = (k) => floor[k] - G[k];
    const positions = [], normals = [], colours = [];
    const vertex = (a, b) => {
      const k = at(a, b);
      const sx = slope[k * 2] + (dug(at(a + 1, b)) - dug(at(a - 1, b))) / (2 * h);
      const sz = slope[k * 2 + 1] + (dug(at(a, b + 1)) - dug(at(a, b - 1))) / (2 * h);
      const l = Math.hypot(sx, 1, sz);
      positions.push(X[k], floor[k], Z[k]);
      normals.push(-sx / l, 1 / l, -sz / l);
      colours.push(tone[k * 3], tone[k * 3 + 1], tone[k * 3 + 2]);
    };
    const wet = { positions: [], normals: [], colours: [], depths: [] };
    const wetVertex = (p) => {
      wet.positions.push(p.x, p.y, p.z);
      wet.normals.push(0, 1, 0);
      wet.colours.push(...water.waterTone(p.w));
      wet.depths.push(p.w);
    };
    // One triangle of the fine grid, cut to where the water is over the floor.
    const flood = (ks) => {
      const vs = ks.map((k) => ({ x: X[k], z: Z[k], y: level[k], f: floor[k], w: level[k] - floor[k] }));
      if (vs.every((p) => p.w <= 0)) return;
      const shape = [];
      for (let m = 0; m < 3; m++) {
        const p = vs[m], q = vs[(m + 1) % 3];
        if (p.w > 0) shape.push(p);
        if ((p.w > 0) !== (q.w > 0)) {
          const t = p.w / (p.w - q.w);
          const y = p.f + (q.f - p.f) * t;
          shape.push({ x: p.x + (q.x - p.x) * t, z: p.z + (q.z - p.z) * t, y, f: y, w: 0 });
        }
      }
      for (let m = 1; m + 1 < shape.length; m++) { wetVertex(shape[0]); wetVertex(shape[m]); wetVertex(shape[m + 1]); }
    };
    for (let b = 0; b < FINE; b++) {
      for (let a = 0; a < FINE; a++) {
        vertex(a, b); vertex(a, b + 1); vertex(a + 1, b);
        vertex(a + 1, b); vertex(a, b + 1); vertex(a + 1, b + 1);
        flood([at(a, b), at(a, b + 1), at(a + 1, b)]);
        flood([at(a + 1, b), at(a, b + 1), at(a + 1, b + 1)]);
      }
    }
    return { positions: new Float32Array(positions), normals: new Float32Array(normals),
             colours: new Float32Array(colours),
             wet: { positions: new Float32Array(wet.positions), normals: new Float32Array(wet.normals),
                    colours: new Float32Array(wet.colours), depths: new Float32Array(wet.depths) } };
  }

  function uploadSheet(mesh) {
    const vao = gl.createVertexArray();
    gl.bindVertexArray(vao);
    const buffers = [
      attribute(gl, waterProgram.at.position, mesh.positions, 3),
      attribute(gl, waterProgram.at.normal, mesh.normals, 3),
      attribute(gl, waterProgram.at.colour, mesh.colours, 3),
      attribute(gl, waterProgram.at.depth, mesh.depths, 1),
    ];
    gl.bindVertexArray(null);
    const count = mesh.positions.length / 3;
    return {
      draw() { gl.bindVertexArray(vao); gl.drawArrays(gl.TRIANGLES, 0, count); gl.bindVertexArray(null); },
      release() { buffers.forEach((b) => gl.deleteBuffer(b)); gl.deleteVertexArray(vao); },
    };
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

  // A tile as the service answered it, asked once a visit, and told to the
  // water when it first comes: a lotus in it may fill a hollow, and any plant
  // in it may stand in one.
  async function answer(tx, tz) {
    const here = `${tx},${tz}`;
    if (!answered.has(here)) {
      answered.set(here, await source(tx, tz));
      water.know(answered.get(here));
    }
    return answered.get(here);
  }

  async function fill(wanted) {
    let since = performance.now();
    for (const key of wanted) {
      if (tiles.has(key) || !builtRound) continue;
      const [ux, uz] = key.split(',').map(Number);
      const tx = mod(ux, TILES), tz = mod(uz, TILES);
      const plantings = await answer(tx, tz);
      // The window may have walked on while that was asked.
      if (!tilesInSight().some(([a, b]) => a === ux && b === uz)) continue;
      const tile = { plants: [] };
      tiles.set(key, tile);
      const shiftX = (ux - tx) * TILE, shiftZ = (uz - tz) * TILE;
      for (const p of plantings) {
        const shape = growOne(p);
        if (!shape) continue;
        water.grew(p, padsOf(shape));
        const x = p.spot[0] + shiftX, z = p.spot[1] + shiftZ;
        tile.plants.push(addPlant(x, water.footAt(x, z, p), z, shape, p));
        if (performance.now() - since > 16) {
          refresh({ soon: true });
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
    // **Lotuses out of sight whose water runs into a hollow in sight**: their
    // tiles are asked for and told to the water, and not grown, so a pond is
    // the same pond whichever way the reader walked to it.
    if (builtRound) {
      const [cx, cz] = builtRound;
      for (const { at, radius } of water.catchments(cx - reach, cz - reach, cx + reach, cz + reach)) {
        for (let ux = Math.floor((at[0] - radius) / TILE); ux <= Math.floor((at[0] + radius) / TILE); ux++) {
          for (let uz = Math.floor((at[1] - radius) / TILE); uz <= Math.floor((at[1] + radius) / TILE); uz++) {
            await answer(mod(ux, TILES), mod(uz, TILES));
          }
        }
      }
    }
    refresh();
    rebuildFeet();
    draw();
    report(false);
  }

  // How far a plant's leaves lie from its stem, from the grown mesh's bounds:
  // for a lotus, how far its pads reach.
  function padsOf(shape) {
    return Math.max(0.05, ...[0, 2].flatMap((i) => [Math.abs(shape.min?.[i] ?? 0), Math.abs(shape.max?.[i] ?? 0)]));
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
    detail.standing(standing());
    if (feet) { feet.buffers.forEach((b) => gl.deleteBuffer(b)); gl.deleteVertexArray(feet.vao); feet = null; }
    const positions = [], uvs = [], indices = [];
    for (const plant of standing()) {
      const base = positions.length / 3;
      for (let j = 0; j <= 4; j++) {
        for (let i = 0; i <= 4; i++) {
          const u = i / 2 - 1, v = j / 2 - 1;
          const x = plant.x + u * plant.foot, z = plant.z + v * plant.foot;
          positions.push(x, water.surfaceAt(x, z) + 0.01, z);
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

  // **The water moves, so while open water is in the window the field is
  // drawn again thirty times a second**; otherwise, and for a reader who has
  // asked for less motion, it is drawn only when the window moves, as it
  // always was. A damp patch's puddles are too shallow for ripples to show
  // and do not count.
  const still = window.matchMedia('(prefers-reduced-motion: reduce)');
  const began = performance.now();
  let rippling = 0, lastFrame = 0, open = null;
  function inWindow(box) {
    if (!box || !drawn) return false;
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
    for (const x of [box[0], box[3]]) {
      for (const y of [box[1], box[4]]) {
        for (const z of [box[2], box[5]]) {
          const [sx, sy] = toScreen([x, y, z]);
          x0 = Math.min(x0, sx); x1 = Math.max(x1, sx); y0 = Math.min(y0, sy); y1 = Math.max(y1, sy);
        }
      }
    }
    return x1 >= 0 && y1 >= 0 && x0 <= canvas.clientWidth && y0 <= canvas.clientHeight;
  }
  function ripple() {
    if (rippling || !sheet || still.matches) return;
    const frame = (now) => {
      rippling = 0;
      if (!sheet || still.matches) return;
      rippling = requestAnimationFrame(frame);
      if (now - lastFrame < 33 || !inWindow(open)) return;
      lastFrame = now;
      draw();
    };
    rippling = requestAnimationFrame(frame);
  }
  still.addEventListener?.('change', () => { ripple(); draw(); });

  // Nothing yet for the water to mirror: a texture of one dark pixel.
  const darkness = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, darkness);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array([0, 0, 0, 0]));

  function uploadSky() {
    if (!skySource?.width || !skySource?.height) return;
    if (!skyTexture) skyTexture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, skyTexture);
    gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, skySource);
    gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, false);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    skyAt = performance.now();
    skyStale = false;
  }

  function draw() {
    const began0 = performance.now();
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

    for (const p of [ground, plantProgram, waterProgram, ...detail.programs]) {
      gl.useProgram(p.program);
      gl.uniformMatrix4fv(p.at.viewProjection, false, viewProjection);
      gl.uniform3fv(p.at.look, Z);
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
    detail.bindInputs(ground.at);
    groundMesh.draw();

    // The water: after the ground, over the floor it lies in, writing depth so
    // what stands in it is under it; blended only where a shore thins.
    if (sheet) {
      if (skySource && (skyStale || performance.now() - skyAt > 60000)) uploadSky();
      gl.useProgram(waterProgram.program);
      gl.uniform1f(waterProgram.at.time, still.matches ? 0 : (performance.now() - began) / 1000);
      gl.uniform1f(waterProgram.at.starlit, skyTexture ? 1 : 0);
      gl.uniform3fv(waterProgram.at.look, Z);
      gl.uniform3fv(waterProgram.at.across, X);
      gl.uniform3fv(waterProgram.at.toward, normalise([Z[0], 0, Z[2]]));
      gl.uniform2f(waterProgram.at.screen, width, height);
      gl.activeTexture(gl.TEXTURE0 + STARLIGHT);
      gl.bindTexture(gl.TEXTURE_2D, skyTexture ?? darkness);
      gl.uniform1i(waterProgram.at.starlight, STARLIGHT);
      gl.activeTexture(gl.TEXTURE0);
      gl.enable(gl.BLEND);
      gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
      gl.enable(gl.POLYGON_OFFSET_FILL);
      gl.polygonOffset(-1, -2);
      sheet.draw();
      gl.disable(gl.POLYGON_OFFSET_FILL);
      gl.disable(gl.BLEND);
    }

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

    // The tufts and the stones, over the ground and its feet, under the
    // plants; by how much of the field a pixel of the canvas covers.
    detail.draw(viewProjection, { around: [...builtRound, reach], metresPerPixel: w / width });

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
    cost.frames.push(performance.now() - began0);
    if (cost.frames.length > 600) cost.frames.shift();
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

  // MARK: Tapping a plant (1 October 2026)

  // **What the areas' panel asks of a stage**, answered for the field, so a
  // released plant opens the same panel as a planted one (`plantpanel.js`):
  // its name, what the name means, its passage, and — the field's own — who
  // chose to stand beside it. A planting is handed over as the service sent
  // it, with the meeting of noughts it was grown with (`growOne`), so the
  // panel names it as the field grew it.
  const named = () => standing().filter((plant) => plant.who).map(describe);
  function describe(plant) {
    return { ...plant.who, encounter: NO_MEETING, at: [plant.x, plant.y + plant.height / 2, plant.z],
             height: plant.height };
  }

  // The plant under a tap, as `longwalk.js` finds one: the stem drawn from
  // foot to top on the screen, nearest the point, within a fingertip and the
  // plant's own half-width; the one in front where two are as near. With no
  // `slop`, the nearest whatever the distance, which is what `p` asks for.
  function pick(px, py, slop = null) {
    if (!drawn) return null;
    const perMetre = pixelsPerMetre();
    const facing = eye();
    let best = null, bestGap = Infinity, bestDepth = -Infinity;
    for (const plant of standing()) {
      if (!plant.who) continue;
      const foot = toScreen([plant.x, plant.y, plant.z]);
      const top = toScreen([plant.x, plant.y + plant.height, plant.z]);
      const gap = Math.max(0, segmentGap(px, py, foot, top) - (slop === null ? 0 : plant.foot * perMetre));
      if (slop !== null && gap > slop) continue;
      const depth = dot([plant.x, plant.y, plant.z], facing);
      if (gap < bestGap - 0.5 || (Math.abs(gap - bestGap) <= 0.5 && depth > bestDepth)) {
        best = plant; bestGap = gap; bestDepth = depth;
      }
    }
    return best && describe(best);
  }

  // The look `zoom` times closer with `point` in the middle of it, for going
  // to a plant. Anywhere is a place a look may be, so nothing holds it back.
  const toward = (point, zoom) => held(over(point, zoom));

  new ResizeObserver(() => { draw(); walked(); }).observe(canvas);
  draw();
  walked();

  return {
    draw, turnBy, turn: () => turn, view, held, lookAt, carried, seams, onScreen, toScreen,
    drifts: () => drifts, pixelsPerMetre, standing, settled: () => fetching, pick, named, toward,
    // The water, for the fireflies' reflections in it.
    waterAt: (x, z) => water.levelAt(x, z), surfaceAt: (x, z) => water.surfaceAt(x, z), facing: eye,
    // The sky's canvas, for the water to mirror: the page hands it over once
    // it is drawn, and again whenever it draws it afresh.
    reflect(sky) { skySource = sky; skyStale = true; if (sheet) draw(); },
    // For the workbench: what drawing has cost, where the hollows are, and
    // how much of the ground's detail is in sight.
    cost: () => ({ frames: [...cost.frames], rebuilds: [...cost.rebuilds], builds: [...cost.builds],
                   wetted: [...cost.wetted], rippling: Boolean(sheet) && !still.matches && inWindow(open) }),
    hollows: () => water.hollows(),
    counts: () => detail.counts(),
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
  // Where a firefly's image in still water is: mirrored in the water's level,
  // and seen at the point of the water the view's ray meets on its way to it.
  // Null over dry ground, and always on `/wild`, which has no water.
  const reflected = ([x, y, z]) => {
    if (!stage.waterAt) return null;
    const towards = stage.facing();
    let level = stage.surfaceAt(x, z);
    for (let k = 0; k < 2; k++) {
      const s = (y - level) / towards[1];
      const seen = stage.waterAt(x + s * towards[0], z + s * towards[2]);
      if (seen === null || y <= seen) return null;
      level = seen;
    }
    return [x, 2 * level - y, z];
  };
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
        // **Its reflection, where there is water under it** (the prototype's
        // water only): still water is a mirror, and seen down this view a
        // firefly's image lies as far under the surface as the firefly is
        // over it, seen in the water a little nearer the reader. Faint, as a
        // reflection off dark water at this angle is.
        // It is broken up by the same breeze as the water: it sways a
        // little either way, is drawn out down the view as a light on moving
        // water is, and comes and goes.
        const image = reflected(at);
        if (image) {
          const [ix, iy] = stage.toScreen(image);
          const size = Math.max(0.7, Math.min(1.6, 0.009 * metre));
          const sway = 0.7 * Math.sin(time * 1.7 + phase * 2.3) + 0.4 * Math.sin(time * 2.9 + phase);
          const drawn = 1.8 + 0.6 * Math.sin(time * 2.3 + phase * 1.7);
          const shimmer = 0.75 + 0.25 * Math.sin(time * 3.1 + phase);
          context.fillStyle = `rgb(${r} ${g} ${b} / ${alpha * 0.32 * shimmer})`;
          context.beginPath();
          context.ellipse(ix + sway * size, iy, size, size * drawn, 0, 0, Math.PI * 2);
          context.fill();
        }
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
// How far (px, py) is from the segment between two points on the screen, as
// `longwalk.js` measures it for a tap.
function segmentGap(px, py, [ax, ay], [bx, by]) {
  const dx = bx - ax, dy = by - ay;
  const length = dx * dx + dy * dy;
  const t = length ? Math.min(1, Math.max(0, ((px - ax) * dx + (py - ay) * dy) / length)) : 0;
  return Math.hypot(px - (ax + t * dx), py - (ay + t * dy));
}
