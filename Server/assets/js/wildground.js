// The Wild Fields' ground, close to: grass in tufts, stones sunk in the turf,
// and the earth showing between them (2 October 2026).
//
// **Why.** Marcus, 2 October: *the textures of the earth have to be more
// realistic in the Wild Fields … Otherwise the difference between the
// landscape itself and the incredible detail of the plants is too jarring.*
// A released plant is grown from its seed with veined leaves and ribbed
// stems; the field it stood on was one smooth shaded sheet, so every plant
// read as laid on a cloth.
//
// **Three things, drawn three ways.**
//
// - **Tufts of grass**, real geometry: one clump of blades drawn once and
//   stood in thousands of places (instancing), each stood at its own height,
//   turned, combed over by the wind and coloured by where it grows. Some carry
//   a seed head on a stalk. Close to, the short grass between them is drawn
//   the same way, many times denser and a few centimetres high.
// - **Pebbles**, real geometry too: one lumpy stone drawn once and stood
//   sunk in the turf wherever the field has one, each a shape and a colour of
//   its own.
// - **The earth and the sward between them**, in the ground's own shader:
//   a mat of short grass where the tufts are thick, and where they are thin,
//   earth — the Home Ground's soil and its crumb (a jittered lattice, a tone
//   to a crumb, wider where the soil is loose and narrower where feet have
//   pressed it), clods, a fine grain and the odd pale grit; moss in damp
//   hollows.
//
// **Near and far, in a view with no distance.** The field is drawn in true
// isometric, so nothing on the screen is further off than anything else; what
// changes is how close the reader has come. So the levels of detail go by
// zoom, not by distance: the tufts are drawn with fewer blades the further
// out the look is, the stones with fewer facets, and each grain of the earth
// fades to its own average tone once it is smaller than a pixel, rather than
// shimmering. At the widest look the field still reads as textured pasture
// because the tufts and the crumb are still there, only coarser.
//
// **Placed by where it is.** Every tuft and every stone comes from the
// square metre it stands in, by a hash of that square's number on the field —
// the field's own number, wrapped, so the ground everyone sees is the same and
// meets itself where the field comes round. Within a square, places are drawn
// at random and kept or dropped by how thick the grass is there, so no grid
// shows; how thick it is, and where the earth shows, is one sum of noise the
// page and the shader both work out (`fieldNoise`, `coverAt`), so the tufts
// stand where the ground under them is grass and not on bare earth. Every
// noise is on a lattice turned off the field's axes by a whole step (`ab`),
// which keeps it at an angle to everything and still lets it come round: no
// ruled lines, no tile.
//
// **Lit as the plants are.** The same sum (`lightAt`: the galaxy, the night
// sky, the bounce) and the fireflies added to it by the field (`light`, which
// is `withFireflies` in `wildfields.js`), and the same darkening under a plant
// as its foot gives the ground.
//
// **Two inputs, for the field's other layers, that default to nothing.**
// `wear` — 0 to 1, where visitors have walked: tufts thin, shorten and are
// pressed flat, and give way to bare earth trodden paler and flatter, its
// crumb pressed together. `wet` — 0 to 1, towards water: the earth darkens to
// mud and glistens, the grass grows taller, stiffer and darker, like sedge,
// and gives out at the water's edge. Each is GLSL defining `float wearAt(vec2
// p)` or `float wetAt(vec2 p)` over the field's unwrapped metres, with any
// uniforms it needs and a `bind` that sets them; `fieldInput` makes one from a
// function of the field sampled into a texture. The stage gives them the worn
// paths (`wornGround` in `wear.js`) and the ponds' wet (`wetness` in
// `wildwater.js`), joined on 2 October 2026.
//
// **Not done: sway.** The stage draws when the window moves and not
// otherwise (`flyOver`'s note); grass that swayed would have the whole field,
// a thousand plants with it, drawn thirty times a second to move blades a
// few millimetres. The tufts are combed by the wind instead — neighbours lean
// together, the way grass lies after weather — which is free.

import { COLOUR, program } from './longwalk.js';
import { PATH, SOIL } from './ground.js';

// SeedCore's `WildFields`: the field's side, in metres. The same number as
// `SIDE` in `wildfields.js`, which this cannot import without going round in a
// circle; `groundDetail` refuses a stage that disagrees.
const FIELD = 64;

// A square of the field: what a tuft or a stone is placed by, and what is
// drawn or not as a whole.
const PATCH = 1;
const PATCHES = FIELD / PATCH;

// Squares kept grown for the visit, at most: about a field's width walked in
// every direction, and a few megabytes; and of the short grass, which is
// many times denser and only drawn close to, a few looks' worth.
const KEPT = 2400;
const KEPT_SHORT = 240;

// **The short grass between the tufts is drawn only close to**: from where a
// pixel of the screen covers `SHORT.from` metres, growing to its full height
// by `SHORT.full`. Further out its blades are thinner than a pixel and the
// mat's own colour stands for them.
const SHORT = { from: 0.0019, full: 0.0012 };

// How far past what is seen the tufts and stones are gathered, in metres:
// how far the window can walk before they are gathered again.
const HELD = 1;

// MARK: - Noise that comes round with the field

// **Integers, so the page and the GPU agree.** A tuft is placed by the page
// and the earth under it is drawn by the shader, and if they disagreed about
// where the grass is thick there would be tufts on bare earth. A hash on
// integers gives the same bits on both; the smooth part between lattice points
// is ordinary arithmetic and agrees to a rounding.
function mixBits(h) {
  h ^= h >>> 16; h = Math.imul(h, 0x7feb352d);
  h ^= h >>> 15; h = Math.imul(h, 0x846ca68b);
  h ^= h >>> 16;
  return h >>> 0;
}

function latticeBits(i, j, nx, ny, salt) {
  const x = ((i % nx) + nx) % nx, z = ((j % ny) + ny) % ny;
  return mixBits(Math.imul(x, 0x8da6b343) ^ mixBits((Math.imul(z, 0xd8163841) + salt) | 0));
}

// **Each noise is a lattice turned off the field's axes by a whole step**:
// `ab` turns it by atan(b / a), and `n` is how many cells there are along
// each turned axis for one side of the field. Because the turn is by whole
// numbers, walking a field's width across moves the lattice by a whole number
// of its own periods, so it comes round with the field; and because it is
// turned, nothing in it lines up with anything else.
const LAYER = {
  // How thick the grass is: three sizes of patch, five metres, two and a
  // half, and two thirds of a metre, and the tussocks, a fifth of a metre.
  coarse: { ab: [3, 1], n: [4, 4], salt: 101 },
  mid: { ab: [2, 1], n: [12, 12], salt: 202 },
  fine: { ab: [1, 2], n: [48, 48], salt: 303 },
  tussock: { ab: [3, 2], n: [96, 96], salt: 404 },
  // Where the grass has been left to grow rank, a couple of metres across.
  rank: { ab: [1, 3], n: [8, 8], salt: 505 },
  // Which way the wind has combed it: very slow, so a stretch of field lies
  // one way.
  comb: { ab: [2, -1], n: [3, 3], salt: 606 },
  // Where the earth shows between tussocks: gaps of a fifth of a metre, their
  // edges broken at seven centimetres and at three.
  gaps: { ab: [2, -1], n: [160, 160], salt: 707 },
  gaps2: { ab: [3, 2], n: [256, 256], salt: 717 },
  gaps3: { ab: [1, -3], n: [640, 640], salt: 727 },
  // Damp and dry, stony patches, moss.
  damp: { ab: [3, -1], n: [10, 10], salt: 808 },
  stony: { ab: [1, -2], n: [6, 6], salt: 909 },
  moss: { ab: [1, 3], n: [40, 40], salt: 1515 },
  // The short grass lying in the mat: a blade to every eight millimetres.
  litter: { ab: [2, -1], n: [3584, 3584], salt: 1414 },
  // The earth, close to: crumbs of a centimetre and a quarter, clods of six,
  // and a grain of four millimetres.
  crumb: { ab: [1, 2], n: [2304, 2304], salt: 1111 },
  clod: { ab: [3, 1], n: [320, 320], salt: 1212 },
  grain: { ab: [2, 1], n: [7168, 7168], salt: 1313 },
};

// How big a cell of a layer is, in metres.
const cellOf = ({ ab: [a, b], n }) => FIELD / (Math.max(...n) * Math.hypot(a, b));

/// A smooth noise of the field, 0 to 1, at `x`, `z` metres, on a layer above.
/// Written out longhand, because the page asks it some thousands of times a
/// square metre as it grows the field.
export function fieldNoise(x, z, layer) {
  const a = layer.ab[0], b = layer.ab[1], nx = layer.n[0], ny = layer.n[1], salt = layer.salt;
  const qx = (a * x + b * z) * nx / FIELD, qz = (a * z - b * x) * ny / FIELD;
  const ix = Math.floor(qx), iz = Math.floor(qz);
  const fx = qx - ix, fz = qz - iz;
  const ux = fx * fx * (3 - 2 * fx), uz = fz * fz * (3 - 2 * fz);
  const p = (latticeBits(ix, iz, nx, ny, salt) >>> 8) / 16777216;
  const q = (latticeBits(ix + 1, iz, nx, ny, salt) >>> 8) / 16777216;
  const r = (latticeBits(ix, iz + 1, nx, ny, salt) >>> 8) / 16777216;
  const s = (latticeBits(ix + 1, iz + 1, nx, ny, salt) >>> 8) / 16777216;
  const near = p + (q - p) * ux, far = r + (s - r) * ux;
  return near + (far - near) * uz;
}

// The same, for the GPU.
const NOISE_GLSL = `
uint fieldMix(uint h) {
  h ^= h >> 16u; h *= 0x7feb352du;
  h ^= h >> 15u; h *= 0x846ca68bu;
  h ^= h >> 16u;
  return h;
}
vec2 fieldTurn(vec2 p, ivec2 ab, vec2 n) {
  return vec2(float(ab.x) * p.x + float(ab.y) * p.y, float(ab.x) * p.y - float(ab.y) * p.x) * n / ${FIELD.toFixed(1)};
}
uint fieldBits(vec2 c, vec2 n, uint salt) {
  uvec2 w = uvec2(mod(c, n));
  return fieldMix(w.x * 0x8da6b343u ^ fieldMix(w.y * 0xd8163841u + salt));
}
float fieldHash(vec2 c, vec2 n, uint salt) { return float(fieldBits(c, n, salt) >> 8u) / 16777216.0; }
float fieldNoise(vec2 p, ivec2 ab, vec2 n, uint salt) {
  vec2 q = fieldTurn(p, ab, n);
  vec2 i = floor(q), f = q - i, u = f * f * (3.0 - 2.0 * f);
  float a = fieldHash(i, n, salt), b = fieldHash(i + vec2(1.0, 0.0), n, salt);
  float c = fieldHash(i + vec2(0.0, 1.0), n, salt), d = fieldHash(i + vec2(1.0, 1.0), n, salt);
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
`;

// A layer's arguments, written out for the GPU.
const glsl = ({ ab: [a, b], n: [nx, ny], salt }) => `ivec2(${a}, ${b}), vec2(${nx.toFixed(1)}, ${ny.toFixed(1)}), ${salt}u`;

// MARK: - How thick the grass is

// **The sward is pasture**, chosen by Marcus on 2 October 2026 from renders
// of two (`design/wild-ground-2026-10-02/`): grazed short, 4 to 15 cm, with
// earth showing between the tussocks and rank patches the animals left; what
// the docs have called the field. The other was a meadow, uncut, a span high,
// thick and seeding; it is in those renders and in this file's history.
//
// `candidates` is how many places a square metre tries, and so the most
// tufts it can hold; `low` and `gain` turn the noise into how thick the grass
// is; `height` the range of a tuft's height in metres, `rankLift` how much
// taller a rank one is; `heads` and `rankHeads` how often a tuft has gone to
// seed; `bare` where between thin and thick the earth stops showing;
// `stones` how stony; `short` how many places a square metre tries for the
// short grass between the tufts, drawn only close to, and `shortHeight` how
// tall that is.
export const PASTURE = { candidates: 150, low: 0.2, gain: 1.8, height: [0.05, 0.13], rank: 0.62, rankLift: 1.75,
                         heads: 0.04, rankHeads: 0.4, bare: [0.05, 0.17], stones: 1, short: 380,
                         shortHeight: [0.03, 0.07] };

const clamp01 = (v) => Math.min(1, Math.max(0, v));
const smooth = (a, b, v) => { const t = clamp01((v - a) / (b - a)); return t * t * (3 - 2 * t); };

/// How thick the grass is at a point, 0 to 1, and with the tussocks in it.
/// `y` is the ground's height there: lusher in the hollows, thinner on the
/// rises. Never quite bald: the thinnest patch of a pasture is still grass.
function swardAt(sward, x, z, y) {
  const c = fieldNoise(x, z, LAYER.coarse), m = fieldNoise(x, z, LAYER.mid), f = fieldNoise(x, z, LAYER.fine);
  return clamp01((0.5 * c + 0.3 * m + 0.2 * f - sward.low - 0.1 * y) * sward.gain);
}
export function coverAt(sward, x, z, y) {
  return (0.15 + 0.85 * swardAt(sward, x, z, y)) * (0.3 + 0.7 * smooth(0.3, 0.75, fieldNoise(x, z, LAYER.tussock)));
}

/// **Where the earth shows**, 0 to 1: more where the grass is thin, but in
/// gaps a hand or two across between tussocks, shaped by their own finer
/// noise so that thin ground is many small gaps and not one bald patch, and
/// ragged at every edge.
export function openAt(sward, x, z, cover) {
  const b = 0.45 * fieldNoise(x, z, LAYER.gaps) + 0.3 * fieldNoise(x, z, LAYER.gaps2)
    + 0.25 * fieldNoise(x, z, LAYER.gaps3);
  return 1 - smooth(sward.bare[0], sward.bare[1], 0.3 * cover + 1.2 * (b - 0.5) + 0.28);
}

const COVER_GLSL = (sward) => `
float swardAt(vec2 p, float y) {
  float c = fieldNoise(p, ${glsl(LAYER.coarse)});
  float m = fieldNoise(p, ${glsl(LAYER.mid)});
  float f = fieldNoise(p, ${glsl(LAYER.fine)});
  return clamp((0.5 * c + 0.3 * m + 0.2 * f - ${sward.low.toFixed(3)} - 0.1 * y) * ${sward.gain.toFixed(3)}, 0.0, 1.0);
}
float coverAt(vec2 p, float y) {
  return (0.15 + 0.85 * swardAt(p, y)) * (0.3 + 0.7 * smoothstep(0.3, 0.75, fieldNoise(p, ${glsl(LAYER.tussock)})));
}
float openAt(vec2 p, float cover) {
  float b = 0.45 * fieldNoise(p, ${glsl(LAYER.gaps)}) + 0.3 * fieldNoise(p, ${glsl(LAYER.gaps2)})
    + 0.25 * fieldNoise(p, ${glsl(LAYER.gaps3)});
  return 1.0 - smoothstep(${sward.bare[0].toFixed(3)}, ${sward.bare[1].toFixed(3)}, 0.3 * cover + 1.2 * (b - 0.5) + 0.28);
}
`;

// MARK: - The inputs

/// The field's other layers, until they are given: nothing worn, nothing wet.
export const NOTHING = {
  wear: { glsl: 'float wearAt(vec2 p) { return 0.0; }', uniforms: [], bind() {} },
  wet: { glsl: 'float wetAt(vec2 p) { return 0.0; }', uniforms: [], bind() {} },
};

/// An input made from a function of the field, `at(x, z)` answering 0 to 1
/// at a point in metres, sampled `cells` to a side into a texture that repeats
/// as the field does, read smoothly between samples. `name` is `wear` or
/// `wet`; `unit` the texture unit it is bound to (the plants use 0 and 1, the
/// worn paths' own texture 2, the sky the ponds mirror 4). `set(at)` samples
/// it again; `set(at, { within })` only inside those boxes, `[x0, z0, x1,
/// z1]` in the field's metres, which may run past its edges.
export function fieldInput(name, at, { cells = 256, unit = 3 } = {}) {
  const values = new Float32Array(cells * cells);
  const size = FIELD / cells;
  const sampleOne = (fn, i, j) => {
    values[j * cells + i] = clamp01(fn((i + 0.5) * size, (j + 0.5) * size));
  };
  const sample = (fn, within = null) => {
    if (!within) {
      for (let j = 0; j < cells; j++) for (let i = 0; i < cells; i++) sampleOne(fn, i, j);
      return;
    }
    const done = new Uint8Array(cells * cells);
    for (const [x0, z0, x1, z1] of within) {
      const i0 = Math.floor(x0 / size - 0.5), i1 = Math.min(i0 + cells - 1, Math.ceil(x1 / size - 0.5));
      const j0 = Math.floor(z0 / size - 0.5), j1 = Math.min(j0 + cells - 1, Math.ceil(z1 / size - 0.5));
      for (let j = j0; j <= j1; j++) {
        for (let i = i0; i <= i1; i++) {
          const wi = mod(i, cells), wj = mod(j, cells);
          if (done[wj * cells + wi]) continue;
          done[wj * cells + wi] = 1;
          sampleOne(fn, wi, wj);
        }
      }
    }
  };
  sample(at);
  let texture = null, dirty = true;
  const sampler = `${name}Field`;
  return {
    glsl: `uniform sampler2D ${sampler};\nfloat ${name}At(vec2 p) { return texture(${sampler}, p / ${FIELD.toFixed(1)}).r; }`,
    uniforms: [sampler],
    set(fn, { within = null } = {}) { sample(fn, within); dirty = true; },
    bind(gl, where) {
      if (where[sampler] == null) return;
      gl.activeTexture(gl.TEXTURE0 + unit);
      if (!texture) {
        texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
      }
      gl.bindTexture(gl.TEXTURE_2D, texture);
      if (dirty) {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.R16F, cells, cells, 0, gl.RED, gl.FLOAT, values);
        dirty = false;
      }
      gl.uniform1i(where[sampler], unit);
      gl.activeTexture(gl.TEXTURE0);
    },
  };
}

// MARK: - The ground's shader

// The light every surface on the field is lit by, word for word what the
// plants have (`SHADE` in `longwalk.js`), so `withFireflies` finds it here.
const SHADE_GLSL = `
uniform vec3 sun, sunColour, sky, bounce;
uniform float strength;
vec3 lightAt(vec3 n) {
  float hemi = 0.5 + 0.5 * n.y;
  return sky * hemi + bounce * (1.0 - hemi) + max(dot(n, sun), 0.0) * strength * sunColour;
}
vec3 encode(vec3 linear) { return pow(max(linear, vec3(0.0)), vec3(1.0 / 2.2)); }
vec3 toLinear(vec3 srgb) { return pow(max(srgb, vec3(0.0)), vec3(2.2)); }
`;

const rgb = (c) => `vec3(${c.map((v) => v.toFixed(3)).join(', ')})`;

// The earth's colours: the Home Ground's soil, dry; the gardens' humus,
// damp, both brought down by the field's dusk as its grass is; the Home
// Ground's path where feet have pressed it; and the gardens' silt for mud.
const EARTH = {
  dry: SOIL.map((v, k) => (v * 0.35 + [0.235, 0.212, 0.188][k] * 0.65) * 1.08),
  damp: COLOUR.humus.map((v, k) => (v * 0.35 + [0.195, 0.178, 0.158][k] * 0.65) * 1.0),
  trodden: PATH.map((v) => v * 0.86),
  mud: COLOUR.silt,
  moss: [0.18, 0.225, 0.085],
  straw: [0.40, 0.36, 0.25],
  grit: COLOUR.gravel,
};

// **A jittered lattice of crumbs**, as the Knot Garden's gravel and the Home
// Ground's soil are laid, here per pixel because a field cannot be a mesh at a
// centimetre: the nearest crumb's own number, which way its middle is, and
// how near the next one is, for the crevice between them.
const CRUMB_GLSL = `
struct Crumb { float id; vec2 to; float edge; };
Crumb crumbAt(vec2 p, ivec2 ab, vec2 n, uint salt) {
  vec2 q = fieldTurn(p, ab, n);
  vec2 i = floor(q), f = q - i;
  float d1 = 9.0, d2 = 9.0, id = 0.0;
  vec2 to = vec2(0.0);
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      vec2 c = i + vec2(float(x), float(y));
      uint h = fieldBits(c, n, salt);
      vec2 o = vec2(float(x), float(y)) + 0.5 + 0.8 * (vec2(float(h & 0xffffu), float(h >> 16u)) / 65535.0 - 0.5) - f;
      float d = dot(o, o);
      if (d < d1) { d2 = d1; d1 = d; to = o; id = float(fieldMix(h) >> 8u) / 16777216.0; }
      else if (d < d2) { d2 = d; }
    }
  }
  // Back from the turned lattice to the field's own directions, still in
  // crumbs: how far from its middle, as a share of a crumb.
  vec2 back = vec2(float(ab.x) * to.x - float(ab.y) * to.y, float(ab.y) * to.x + float(ab.x) * to.y)
    / length(vec2(ab));
  return Crumb(id, back, sqrt(d2) - sqrt(d1));
}
`;

// **The short grass in the mat**: in each cell of a turned lattice one blade,
// a stroke of its own length and its own way, thickest in its middle; the
// nearest drawn over the mat's depths. Answers how much of a blade covers the
// point, and the blade's own tone and whether it is dead.
const STROKE_GLSL = `
vec3 strokeAt(vec2 p, ivec2 ab, vec2 n, uint salt, float combed) {
  vec2 q = fieldTurn(p, ab, n);
  vec2 i = floor(q), f = q - i;
  vec3 best = vec3(0.0, 0.5, 0.0);
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      vec2 c = i + vec2(float(x), float(y));
      uint h = fieldBits(c, n, salt);
      uint g = fieldMix(h);
      vec2 middle = vec2(float(x), float(y)) + 0.5 + 0.7 * (vec2(float(h & 0xffffu), float(h >> 16u)) / 65535.0 - 0.5);
      float turn = combed + (float(g & 0xffffu) / 65535.0 - 0.5) * 2.4;
      float half_ = 0.5 + 0.5 * float((g >> 16u) & 0xffu) / 255.0;
      vec2 way = vec2(cos(turn), sin(turn));
      vec2 rel = f - middle;
      float along = clamp(dot(rel, way), -half_, half_);
      float off = length(rel - way * along);
      float width = 0.2 * (0.35 + 0.65 * (1.0 - abs(along) / half_));
      float cover = 1.0 - smoothstep(0.55 * width, width, off);
      if (cover > best.x) best = vec3(cover, float(g >> 24u) / 255.0, step(0.9, fract(float(h) / 4294967296.0 * 31.0)));
    }
  }
  return best;
}
`;

/// The ground's fragment shader, with the two inputs. Its `main` keeps the
/// ground's own two inputs from the vertices: the colour the field's patches
/// and hollows give it (`groundColour` in `wildfields.js`), and its normal.
export function groundFragment(sward, { wear = NOTHING.wear, wet = NOTHING.wet } = {}) {
  const cell = (layer) => cellOf(LAYER[layer]).toFixed(5);
  return `#version 300 es
precision highp float;
in vec3 vNormal; in vec3 vColour; in vec3 vWorld;
uniform vec3 look;
${SHADE_GLSL}
${NOISE_GLSL}
${COVER_GLSL(sward)}
${CRUMB_GLSL}
${STROKE_GLSL}
${wear.glsl}
${wet.glsl}
out vec4 outColour;

void main() {
  vec2 p = mod(vWorld.xz, ${FIELD.toFixed(1)});
  // How much of the field one pixel covers, in metres: anything finer than
  // about this fades to its own average rather than shimmering.
  float pixel = max(length(dFdx(vWorld.xz)), length(dFdy(vWorld.xz)));
  #define SEEN(size) (1.0 - smoothstep(0.3 * (size), 0.9 * (size), pixel))
  float worn = clamp(wearAt(vWorld.xz), 0.0, 1.0);
  float wet = clamp(wetAt(vWorld.xz), 0.0, 1.0);
  float y = vWorld.y;

  // The clumps the grass grows in, a fifth of a metre and seven centimetres.
  float clumps = 0.6 * fieldNoise(p, ${glsl(LAYER.tussock)}) + 0.4 * fieldNoise(p, ${glsl(LAYER.gaps2)});

  // **Where the earth shows**: in gaps between the tussocks, the same gaps
  // the page kept tufts out of; and wherever feet have worn the grass away,
  // its edge broken by the clumps that hold on longest.
  float cover = coverAt(p, y);
  float bare = max(openAt(p, cover), smoothstep(0.1, 0.5, worn + 0.4 * (clumps - 0.5)));
  float mud = smoothstep(0.45, 0.9, wet + 0.25 * (clumps - 0.5));

  // **The mat**: what lies under and between the tufts — the short grass's
  // own dark depths, darker where the tufts over it are thick, and mottled by
  // the clumps it grows in, lighter on their tops and darker between, which
  // is what grass looks like from further off than a blade. The blades lying
  // in it are drawn below, over the earth as well.
  float combed = fieldNoise(p, ${glsl(LAYER.comb)}) * 12.5664;
  vec3 depths = vColour * 0.8 * mix(1.0, 0.82, smoothstep(0.25, 0.85, cover)) * (0.75 + 0.5 * clumps);
  vec3 lying = vColour * 1.22 * (0.85 + 0.3 * clumps);
  vec3 lusher = mix(vec3(1.0), vec3(0.82, 1.0, 0.86), smoothstep(0.2, 0.7, wet));
  depths *= lusher;
  lying *= lusher;

  // **The earth**: damp or dry by a slow wander, trodden paler where feet
  // have pressed it; crumbs, clods and a grain; a crevice between crumbs.
  float damp = clamp(fieldNoise(p, ${glsl(LAYER.damp)}) * 1.3 - 0.25 - 0.25 * y + 0.8 * wet, 0.0, 1.0);
  vec3 soil = mix(${rgb(EARTH.dry)}, ${rgb(EARTH.damp)}, damp);
  float pressed = smoothstep(0.1, 0.8, worn);
  soil = mix(soil, ${rgb(EARTH.trodden)}, pressed * (1.0 - mud));
  float seenCrumb = SEEN(${cell('crumb')});
  float seenClod = SEEN(${cell('clod')});
  float seenGrain = SEEN(${cell('grain')});
  // Only worked out where there is earth to see: most of a field is grass.
  Crumb crumb = Crumb(0.5, vec2(0.0), 1.0), clod = Crumb(0.5, vec2(0.0), 1.0);
  // The crumbs' lattice pushed about by a noise of its own a few
  // centimetres across, so they are lumps of all shapes and not a paving.
  vec2 pushed = p + 0.007 * (vec2(fieldNoise(p, ${glsl(LAYER.gaps3)}), fieldNoise(p + 7.3, ${glsl(LAYER.gaps3)})) - 0.5);
  if ((bare > 0.001 || mud > 0.001) && seenCrumb > 0.0) crumb = crumbAt(pushed, ${glsl(LAYER.crumb)});
  if (bare > 0.001 && seenClod > 0.0) clod = crumbAt(pushed, ${glsl(LAYER.clod)});
  float grain = seenGrain > 0.0 ? fieldNoise(p, ${glsl(LAYER.grain)}) : 0.5;
  // A crumb's own tone: a wide spread where the soil is loose, a narrow one
  // where feet have pressed it (the Home Ground's rule).
  float spread = mix(0.32, 0.1, pressed);
  float tone = 1.0 + spread * (crumb.id - 0.5) * seenCrumb + 0.2 * (clod.id - 0.5) * seenClod * (1.0 - pressed);
  tone *= 1.0 + 0.22 * (grain - 0.5) * seenGrain;
  // A crevice only here and there between them: crumbs touch.
  float opens = smoothstep(0.35, 0.7, fieldNoise(pushed, ${glsl(LAYER.gaps3)}));
  float crevice = mix(1.0, mix(0.7, 1.0, smoothstep(0.0, 0.16, crumb.edge)), seenCrumb * opens * (1.0 - 0.6 * pressed));
  crevice *= mix(1.0, mix(0.8, 1.0, smoothstep(0.0, 0.2, clod.edge)), seenClod * (1.0 - pressed));
  vec3 earth = soil * tone * crevice;
  // The odd pale grain of grit.
  float grit = step(mix(0.985, 0.994, pressed), fract(crumb.id * 97.31)) * seenCrumb;
  earth = mix(earth, ${rgb(EARTH.grit)} * (0.8 + 0.4 * grain), 0.6 * grit * (1.0 - mud));
  // Each crumb and clod a little dome, so the galaxy finds them; pressed
  // flatter where trodden.
  vec2 tilt = -(crumb.to * 0.6 * seenCrumb + clod.to * 0.5 * seenClod) * (1.0 - 0.75 * pressed);

  // **Moss** in the damp hollows, where the grass is thin and nobody walks.
  float moss = smoothstep(0.66, 0.84, fieldNoise(p, ${glsl(LAYER.moss)}) + 0.2 * (clumps - 0.5))
    * smoothstep(0.2, 0.6, damp) * (1.0 - smoothstep(0.1, 0.4, worn)) * (1.0 - mud);
  vec3 mossy = ${rgb(EARTH.moss)} * (0.7 + 0.45 * crumb.id * seenCrumb + 0.25 * (grain - 0.5) * seenGrain);

  // **Mud**, towards water: the silt, a little darker the wetter, glistening.
  vec3 muddy = ${rgb(EARTH.mud)} * 1.3 * (0.9 + 0.2 * crumb.id * seenCrumb) * mix(1.0, 0.85, smoothstep(0.9, 1.0, wet));

  // **The short grass lies over the earth as well as the mat**, thinning
  // across a gap rather than stopping at its edge, so the edge is blades.
  vec3 under = mix(depths, earth, bare);
  float lies = 1.0 - smoothstep(0.25, 0.95, bare);
  vec3 albedo = mix(under, lying, 0.38 * lies);
  float seenLitter = SEEN(0.005);
  if (lies > 0.0 && seenLitter > 0.0) {
    vec3 stroke = strokeAt(p, ${glsl(LAYER.litter)}, combed);
    vec3 blade = mix(lying * (0.78 + 0.35 * stroke.y), ${rgb(EARTH.straw)} * (0.5 + 0.3 * stroke.y), 0.45 * stroke.z);
    albedo = mix(albedo, mix(under, blade, 0.65 * stroke.x * lies), seenLitter);
  }
  albedo = mix(albedo, mossy, moss * bare);
  albedo = mix(albedo, muddy, mud);
  tilt *= bare * (1.0 - 0.6 * mud);
  vec3 n = normalize(normalize(vNormal) + vec3(tilt.x, 0.0, tilt.y));
  vec3 halfway = normalize(sun + look);
  float facing = max(dot(n, halfway), 0.0);
  float shine = (pow(facing, 12.0) * 0.3 + pow(facing, 60.0) * 0.8) * mud * (0.6 + 0.4 * crumb.id);
  outColour = vec4(encode(toLinear(albedo) * lightAt(n) + shine * strength * sunColour), 1.0);
}`;
}

// MARK: - Tufts

// A blade's vertex: where its root is in the tuft (`root`, on a unit disc);
// the blade (`blade`: its length as a share of the tuft's height, its width as
// a share of a blade's, how far it leans out from upright at the root and how
// much further it bends by the tip, both in radians); where on it the vertex
// is (`at`: how far along, which edge, which way the blade faces, and the
// blade's own number); and what it is (`kind`: 0 a blade, 1 a seed stalk, 2
// and 3 the two crossed halves of its head).
const TUFT_FLOATS = 11;

const unit = (n) => { const x = Math.sin(n * 12.9898 + 78.233) * 43758.5453; return x - Math.floor(x); };

function tuftMesh(blades, segments, headSegments, stalks = false) {
  const data = [], indices = [];
  const vertex = (root, blade, t, side, facing, id, kind) => {
    data.push(root[0], root[1], ...blade, t, side, facing, id, kind);
    return data.length / TUFT_FLOATS - 1;
  };
  // A strip up the blade from root to point: two vertices a level, and the
  // point.
  const strip = (root, blade, facing, id, kind, levels, pointed) => {
    const rows = [];
    const last = pointed ? levels - 1 : levels;
    for (let k = 0; k <= last; k++) {
      const t = k / levels;
      rows.push([vertex(root, blade, t, -1, facing, id, kind), vertex(root, blade, t, 1, facing, id, kind)]);
    }
    for (let k = 0; k < rows.length - 1; k++) {
      const [a, b] = rows[k], [c, d] = rows[k + 1];
      indices.push(a, b, c, b, d, c);
    }
    if (pointed) {
      const tip = vertex(root, blade, 1, 0, facing, id, kind);
      const [a, b] = rows[rows.length - 1];
      indices.push(a, b, tip);
    }
  };
  for (let b = 0; b < blades; b++) {
    // Round the tuft by the golden angle, so no two blades stand in a row.
    const around = b * 2.39996 + (unit(b * 3.1 + 0.7) - 0.5) * 0.5;
    const r = 0.25 + 0.75 * Math.sqrt((b + 0.5) / blades);
    const root = [Math.cos(around) * r, Math.sin(around) * r];
    const facing = around + (unit(b * 8.3) - 0.5) * 0.8;
    // The outer blades lean out further and bend over more; one in a few is
    // nearly upright.
    const blade = [(1 - 0.35 * r) * (0.6 + 0.4 * unit(b * 5.7 + 1.3)), 0.7 + 0.6 * unit(b * 9.1 + 2.2),
                   0.08 + 0.5 * r * r + 0.22 * unit(b * 4.3), 0.25 + 1.1 * unit(b * 6.6 + 0.4) * r];
    strip(root, blade, facing, unit(b * 11.7 + 0.9), 0, segments, true);
  }
  // Two stalks for a tuft gone to seed, taller than its blades, each with a
  // head of two crossed halves.
  for (let s = 0; s < (stalks ? 2 : 0); s++) {
    const around = 0.4 + s * 2.7;
    const root = [Math.cos(around) * 0.2, Math.sin(around) * 0.2];
    const blade = [1.3 + 0.35 * s, 0.32, 0.05 + 0.1 * s, 0.18 + 0.22 * s];
    const id = 0.25 + 0.5 * s;
    strip(root, blade, around, id, 1, Math.max(2, segments - 1), false);
    strip(root, blade, around, id, 2, headSegments, false);
    strip(root, blade, around, id, 3, headSegments, false);
  }
  return { data: new Float32Array(data), indices: new Uint16Array(indices) };
}

// Fewer blades, and fewer joints in each, the further out the look is: by
// how many metres one pixel of the screen covers.
const TUFT_LEVELS = [
  { finer: 0.0016, blades: 22, segments: 4, head: 5 },
  { finer: 0.0034, blades: 15, segments: 3, head: 4 },
  { finer: Infinity, blades: 10, segments: 2, head: 3 },
];

// A tuft where it stands: 16 numbers.
// - `place`: x, y, z, and how it is turned;
// - `form`: its height, how far it leans, which way, and whether it has gone
//   to seed;
// - `tint`: its green, and how dry it is;
// - `more`: how much a plant beside it shades it, how much of its height it
//   keeps beside a plant's stem, where it comes in the order of giving way to
//   feet, and a number of its own for its blades.
const TUFT = 16;

const TUFT_VERTEX = (inputs) => `#version 300 es
in vec2 root; in vec4 blade; in vec4 at; in float kind;
in vec4 place; in vec4 form; in vec4 tint; in vec4 more;
uniform mat4 viewProjection;
uniform float pixel, scale;
${inputs}
out vec3 vWorld; out vec3 vNormal; out vec3 vColour; out float vAlong; out float vShade;

// A blade's spine, per metre of its length, at \`t\` along it: an arc in its
// own upright plane, leaving the root \`a0\` from upright and bending through
// \`bend\` more by the point. Answers how far out and how far up.
vec2 arc(float t, float a0, float bend) {
  if (abs(bend) < 1e-3) return t * vec2(sin(a0), cos(a0));
  return vec2(cos(a0) - cos(a0 + bend * t), sin(a0 + bend * t) - sin(a0)) / bend;
}

void main() {
  float worn = clamp(wearAt(place.xz), 0.0, 1.0);
  float wet = clamp(wetAt(place.xz), 0.0, 1.0);
  // **Thinned by feet and by water**, each tuft at its own place in the order
  // of giving way, so a path's edge is ragged and not a line.
  float holds = (1.0 - smoothstep(0.08, 0.8, worn)) * (1.0 - smoothstep(0.86, 0.97, wet));
  bool seed = kind > 0.5;
  if (more.z >= holds || (seed && (form.w < 0.5 || worn > 0.25))) {
    gl_Position = vec4(0.0, 0.0, 2.0, 1.0);
    return;
  }
  // Towards water the grass grows taller, stiffer and broader: sedge.
  float sedge = smoothstep(0.3, 0.75, wet);
  float H = scale * form.x * more.y * mix(1.0, 0.32, smoothstep(0.0, 0.7, worn)) * (1.0 + 0.6 * sedge);
  float lean = form.y * (1.0 - 0.6 * sedge) + 1.3 * worn;
  float a0 = blade.z * (1.0 - 0.5 * sedge) * (0.8 + 0.4 * more.w);
  float bend = blade.w * (1.0 - 0.6 * sedge) + 0.9 * worn;
  float L = H * blade.x * (seed ? 1.0 : mix(0.75, 1.15, fract(at.w * 5.3 + more.w * 3.1)));
  float width = blade.y * mix(0.0040, 0.0062, sedge) * mix(0.9, 1.15, more.w);
  vec2 facing = vec2(cos(at.z), sin(at.z));
  vec3 base = vec3(root.x, 0.0, root.y) * (0.02 + 0.28 * H) * mix(0.8, 1.2, more.w);
  float t = at.x;

  vec3 spine, along, across;
  float w;
  if (kind < 1.5) {
    vec2 s = arc(t, a0, bend);
    float a = a0 + bend * t;
    spine = base + vec3(facing.x * s.x, s.y, facing.y * s.x) * L;
    along = vec3(facing.x * sin(a), cos(a), facing.y * sin(a));
    // A blade twists a little as it goes.
    float twist = (at.w - 0.5) * 1.4 * t;
    vec3 level = vec3(-facing.y, 0.0, facing.x);
    across = level * cos(twist) + cross(along, level) * sin(twist);
    w = seed ? 0.0012 : width * (1.0 - t * t) * mix(0.7, 1.0, smoothstep(0.0, 0.3, t));
    // **Never thinner than a pixel**, tapering to its point all the same: a
    // blade drawn thinner than the screen can show flickers and greys out, and
    // the further out the look the fewer blades a tuft is drawn with, so each
    // must carry its share of the green.
    w = max(w, pixel * (seed ? 0.7 : 1.1) * (1.0 - t));
  } else {
    // The head, on the top of its stalk and going on the way the stalk goes.
    vec2 s = arc(1.0, a0, bend);
    float a = a0 + bend;
    vec3 top = base + vec3(facing.x * s.x, s.y, facing.y * s.x) * L;
    along = vec3(facing.x * sin(a), cos(a), facing.y * sin(a));
    spine = top + along * clamp(0.28 * L, 0.018, 0.055) * t;
    float turn = at.z + (kind - 2.0) * 1.5708;
    across = normalize(cross(along, vec3(cos(turn), 0.0, sin(turn))));
    w = max(0.007, 1.2 * pixel) * pow(max(sin(3.14159 * t), 0.0), 0.6);
  }
  vec3 local = spine + across * at.y * 0.5 * w;
  vec3 normal = cross(across, along);

  // Turned where it stands.
  float c = cos(place.w), sn = sin(place.w);
  mat2 turned = mat2(c, sn, -sn, c);
  local.xz = turned * local.xz;
  normal.xz = turned * normal.xz;
  // **Combed by the wind, or pressed down by feet**: sheared the way it leans,
  // more the higher up, and brought down so it lies over rather than growing.
  vec2 lies = vec2(cos(form.z), sin(form.z));
  float k = lean * local.y / max(H, 0.01);
  local.xz += lies * k * local.y;
  local.y /= sqrt(1.0 + k * k);
  normal.xz -= lies * k * normal.y;

  vWorld = place.xyz + local;
  vNormal = normalize(normal);
  vAlong = kind > 1.5 ? 1.0 : t;
  vShade = more.x;

  // **Its colour**: the tuft's green, darker down in the tuft and lighter at
  // the tips; some blades died back to straw and the dry ones' tips with
  // them; sedge's darker, bluer green towards water; a seed head the colour
  // of ripe grass, some with a purple bloom.
  vec3 straw = ${rgb([0.47, 0.42, 0.29])};
  vec3 c0 = tint.rgb * mix(0.55, 1.22, t);
  float dead = step(at.w, tint.a * 0.4);
  c0 = mix(c0, straw * mix(0.7, 1.05, t), max(dead, tint.a * t * t * t));
  c0 = mix(c0, ${rgb([0.14, 0.215, 0.15])} * mix(0.6, 1.2, t), sedge);
  if (seed) {
    vec3 ripe = mix(straw * 0.92, ${rgb([0.40, 0.31, 0.33])}, step(0.6, fract(more.w * 7.0)));
    c0 = kind < 1.5 ? mix(tint.rgb * 0.9, straw * 0.85, t) : ripe * mix(0.85, 1.1, at.w);
  }
  vColour = c0;
  gl_Position = viewProjection * vec4(vWorld, 1.0);
}`;

const TUFT_FRAGMENT = `#version 300 es
precision highp float;
in vec3 vWorld; in vec3 vNormal; in vec3 vColour; in float vAlong; in float vShade;
${SHADE_GLSL}
out vec4 outColour;
void main() {
  // **A blade is thin**, and lit as much through itself and by the sky round
  // it as off its face: its normal is taken most of the way to the sky's,
  // whichever face is seen. Darker down in the tuft, where its neighbours
  // shade it.
  vec3 n = normalize(gl_FrontFacing ? vNormal : -vNormal);
  n = normalize(n + vec3(0.0, 1.2, 0.0));
  float deep = mix(0.4, 1.0, smoothstep(0.0, 0.7, vAlong));
  outColour = vec4(encode(toLinear(vColour) * deep * lightAt(n)) * vShade, 1.0);
}`;

// MARK: - Pebbles

// A pebble is a ball, made lumpy and flattened where it stands. Two levels:
// 320 faces close to, 80 further out.
function ball(levels) {
  const t = (1 + Math.sqrt(5)) / 2;
  let points = [[-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0], [0, -1, t], [0, 1, t], [0, -1, -t], [0, 1, -t],
                [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1]].map(norm);
  let faces = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2],
               [10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11],
               [6, 2, 10], [8, 6, 7], [9, 8, 1]];
  for (let l = 0; l < levels; l++) {
    const middle = new Map();
    const half = (a, b) => {
      const key = a < b ? `${a},${b}` : `${b},${a}`;
      if (!middle.has(key)) { middle.set(key, points.length); points.push(norm(points[a].map((v, i) => v + points[b][i]))); }
      return middle.get(key);
    };
    faces = faces.flatMap(([a, b, c]) => {
      const ab = half(a, b), bc = half(b, c), ca = half(c, a);
      return [[a, ab, ca], [b, bc, ab], [c, ca, bc], [ab, bc, ca]];
    });
  }
  return { data: new Float32Array(points.flat()), indices: new Uint16Array(faces.flat()) };
}
function norm(v) { const l = Math.hypot(...v); return v.map((x) => x / l); }

// A pebble where it stands, 16 numbers: `place` (x, the ground's height, z,
// how it is turned), `size` (half its width, height and depth, and how much
// of it is sunk), `tone` (its colour, and a number of its own for its
// lumps), `more` (how much a plant beside it shades it).
const STONE = 16;

const STONE_VERTEX = (inputs) => `#version 300 es
in vec3 position;
in vec4 place; in vec4 size; in vec4 tone; in vec4 more;
uniform mat4 viewProjection;
${inputs}
out vec3 vWorld; out vec3 vRound; out vec3 vColour; out float vRise; out float vWet; out float vShade;
void main() {
  vec3 v = position;
  float h = tone.w * 6.2831;
  // Lumpy, by three waves of its own over the ball, so no two are alike.
  float r = 1.0 + 0.15 * sin(dot(v, vec3(2.1, 1.3, -1.7)) * 1.7 + h)
    + 0.09 * sin(dot(v, vec3(-1.1, 2.6, 0.7)) * 2.9 + h * 3.0)
    + 0.05 * sin(dot(v, vec3(3.3, -0.4, 2.1)) * 4.3 + h * 7.0);
  vec3 p = v * r * size.xyz;
  float c = cos(place.w), s = sin(place.w);
  p.xz = mat2(c, s, -s, c) * p.xz;
  vRound = normalize(vec3(v.x / size.x, v.y / size.y, v.z / size.z));
  vRound.xz = mat2(c, s, -s, c) * vRound.xz;
  // Sunk into the turf by a share of its height.
  p.y -= size.w * size.y;
  vRise = p.y / size.y;
  vWorld = place.xyz + p;
  vColour = tone.rgb;
  vWet = clamp(wetAt(place.xz), 0.0, 1.0);
  vShade = more.x;
  gl_Position = viewProjection * vec4(vWorld, 1.0);
}`;

const STONE_FRAGMENT = `#version 300 es
precision highp float;
in vec3 vWorld; in vec3 vRound; in vec3 vColour; in float vRise; in float vWet; in float vShade;
uniform vec3 look;
${SHADE_GLSL}
${NOISE_GLSL}
out vec4 outColour;
void main() {
  // Facets from the surface as drawn, half and half with the ball's own
  // roundness: a field stone, worn but not a marble.
  vec3 facet = normalize(cross(dFdx(vWorld), dFdy(vWorld)));
  if (dot(facet, look) < 0.0) facet = -facet;
  vec3 n = normalize(facet + normalize(vRound));
  // Speckled, and darker where it goes into the soil, which is damp there.
  vec2 p = mod(vWorld.xz + vWorld.y * 0.7, ${FIELD.toFixed(1)});
  float speck = fieldNoise(p, ivec2(2, 1), vec2(9000.0, 9000.0), 77u);
  vec3 albedo = vColour * (0.86 + 0.28 * speck) * mix(0.5, 1.0, smoothstep(-0.25, 0.45, vRise));
  albedo *= mix(1.0, 0.62, vWet);
  vec3 halfway = normalize(sun + look);
  float shine = pow(max(dot(n, halfway), 0.0), mix(24.0, 70.0, vWet)) * mix(0.06, 0.3, vWet);
  outColour = vec4(encode(toLinear(albedo) * lightAt(n) + shine * strength * sunColour) * vShade, 1.0);
}`;

// What a pebble may be made of, and how often: the gardens' own stones. The
// slab's bedrock darkened to flint; the Knot's gravel, pale; the Crossing's
// paving; the gardens' earth for ironstone.
const STONES = [
  [0.45, COLOUR.bedrock.map((v) => v * 0.78)],
  [0.25, COLOUR.gravel],
  [0.2, COLOUR.stone],
  [0.1, COLOUR.earth.map((v) => v * 1.05)],
];

// MARK: - The detail, on a stage

/// The ground's detail for a stage on `gl`. `side` is the field's (it must be
/// this module's); `height(x, z)` the ground's height and `colour(x, z)` its
/// colour, both on unwrapped metres; `wear` and `wet` the inputs, or nothing;
/// `light` what the field adds to every light (`withFireflies`); `lit` the
/// uniforms that adds. The sward is the pasture (`PASTURE`).
export function groundDetail(gl, { side, height, colour, wear = null, wet = null, light = (f) => f, lit = [] }) {
  if (side !== FIELD) throw new Error(`the ground's detail is for a field ${FIELD} m across, not ${side}`);
  const kind = PASTURE;
  const inputs = { wear: wear ?? NOTHING.wear, wet: wet ?? NOTHING.wet };
  const inputGLSL = `${inputs.wear.glsl}\n${inputs.wet.glsl}`;
  const inputUniforms = [...inputs.wear.uniforms, ...inputs.wet.uniforms];

  const tuftProgram = program(gl, TUFT_VERTEX(inputGLSL), light(TUFT_FRAGMENT),
                              ['root', 'blade', 'at', 'kind', 'place', 'form', 'tint', 'more'],
                              ['pixel', 'scale', ...lit, ...inputUniforms]);
  const stoneProgram = program(gl, STONE_VERTEX(inputGLSL), light(STONE_FRAGMENT),
                               ['position', 'place', 'size', 'tone', 'more'], ['look', ...lit, ...inputUniforms]);

  // The instances in sight, in one buffer each, refilled when what is in
  // sight changes.
  const tuftBuffer = gl.createBuffer();
  const headBuffer = gl.createBuffer();
  const stoneBuffer = gl.createBuffer();
  const shortBuffer = gl.createBuffer();
  const instanced = (p, names, buffer, stride) => {
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    names.forEach((name, k) => {
      const at = p.at[name];
      if (at < 0) return;
      gl.enableVertexAttribArray(at);
      gl.vertexAttribPointer(at, 4, gl.FLOAT, false, stride * 4, k * 16);
      gl.vertexAttribDivisor(at, 1);
    });
  };
  const meshOf = (p, mesh, layout, instances) => {
    const vao = gl.createVertexArray();
    gl.bindVertexArray(vao);
    const vertices = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vertices);
    gl.bufferData(gl.ARRAY_BUFFER, mesh.data, gl.STATIC_DRAW);
    const stride = layout.reduce((sum, [, n]) => sum + n, 0);
    let offset = 0;
    for (const [name, n] of layout) {
      const at = p.at[name];
      if (at >= 0) {
        gl.enableVertexAttribArray(at);
        gl.vertexAttribPointer(at, n, gl.FLOAT, false, stride * 4, offset * 4);
      }
      offset += n;
    }
    const index = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, mesh.indices, gl.STATIC_DRAW);
    instances();
    gl.bindVertexArray(null);
    return { vao, count: mesh.indices.length };
  };
  // Each level twice: the blades, drawn for every tuft, and the stalks and
  // heads, drawn only for the tufts gone to seed.
  const TUFT_LAYOUT = [['root', 2], ['blade', 4], ['at', 4], ['kind', 1]];
  const tuftLevels = TUFT_LEVELS.map((level) => ({
    finer: level.finer,
    blades: meshOf(tuftProgram, tuftMesh(level.blades, level.segments, level.head), TUFT_LAYOUT,
                   () => instanced(tuftProgram, ['place', 'form', 'tint', 'more'], tuftBuffer, TUFT)),
    heads: meshOf(tuftProgram, tuftMesh(0, level.segments, level.head, true), TUFT_LAYOUT,
                  () => instanced(tuftProgram, ['place', 'form', 'tint', 'more'], headBuffer, TUFT)),
  }));
  const shortMesh = meshOf(tuftProgram, tuftMesh(14, 2, 0), TUFT_LAYOUT,
                           () => instanced(tuftProgram, ['place', 'form', 'tint', 'more'], shortBuffer, TUFT));
  const stoneLevels = [[0.002, 2], [Infinity, 1]].map(([finer, levels]) => ({
    finer,
    ...meshOf(stoneProgram, ball(levels), [['position', 3]],
              () => instanced(stoneProgram, ['place', 'size', 'tone', 'more'], stoneBuffer, STONE)),
  }));

  // MARK: Growing a square

  // Every square grown this visit, by its number on the field.
  const grown = new Map();

  function grow(wi, wj) {
    const key = wj * PATCHES + wi;
    let patch = grown.get(key);
    if (patch) return patch;
    const started = performance.now();
    const rand = stream(latticeBits(wi, wj, PATCHES, PATCHES, 7919));
    const tufts = [], heads = [];
    for (let k = 0; k < kind.candidates; k++) {
      const x = (wi + rand()) * PATCH, z = (wj + rand()) * PATCH;
      const y = height(x, z);
      const thick = coverAt(kind, x, z, y);
      const keep = rand();
      if (keep >= thick || keep >= thick * (1 - 0.9 * openAt(kind, x, z, thick))) continue;
      const rank = fieldNoise(x, z, LAYER.rank) > kind.rank;
      const r = [rand(), rand(), rand(), rand(), rand(), rand(), rand(), rand()];
      const [low, high] = kind.height;
      const tall = (low + (high - low) * r[0] ** 1.4) * (rank ? kind.rankLift : 1) * (0.85 + 0.3 * thick);
      // The wind's combing: a slow field of directions, each tuft a little
      // its own way.
      const combed = fieldNoise(x, z, LAYER.comb) * 4 * Math.PI + (r[1] - 0.5) * 0.9;
      const lean = 0.06 + 0.24 * r[2] + (rank ? 0.12 : 0);
      const head = r[3] < (rank ? kind.rankHeads : kind.heads) ? 1 : 0;
      // Its green: the field's own where it stands, lifted, lusher where the
      // grass is thick, and each tuft its own way towards yellow or blue.
      const ground = colour(x, z);
      const lush = 0.85 + 0.3 * thick;
      const hue = (r[4] - 0.5) * 2;
      const tint = [ground[0] * 1.55 * lush * (1 + 0.12 * hue), ground[1] * 1.6 * lush,
                    ground[2] * 1.15 * lush * (1 - 0.2 * hue)];
      const dry = clamp01(0.08 + 0.3 * r[5] + (rank ? 0.3 : 0) + 0.25 * y);
      tufts.push(x, y, z, r[6] * 2 * Math.PI, tall, lean, combed, head, ...tint, dry, 1, 1, r[7], rand());
      if (head) heads.push(...tufts.slice(-TUFT));
    }

    // **Stones**: a few anywhere, more on stony ground, and now and then a
    // little scatter of them together, as a field turns them up. Most of
    // those under thick grass would never be seen, so they are kept mostly
    // where the earth shows.
    const stones = [];
    const cx = (wi + 0.5) * PATCH, cz = (wj + 0.5) * PATCH;
    const stony = smooth(0.35, 0.8, fieldNoise(cx, cz, LAYER.stony));
    const stone = (x, z, big) => {
      const r = [rand(), rand(), rand(), rand(), rand(), rand()];
      const y = height(x, z);
      if (r[5] > 0.3 + 0.7 * openAt(kind, x, z, coverAt(kind, x, z, y)) && !big) return;
      const size = big ? 0.03 + 0.035 * r[0] : 0.005 + 0.026 * r[0] ** 1.8;
      const pick = r[1];
      let sum = 0;
      const [, made] = STONES.find(([share]) => (sum += share) > pick) ?? STONES[0];
      const light = 0.7 + 0.28 * r[2];
      stones.push(x, y, z, r[3] * 2 * Math.PI,
                  size * (0.8 + 0.5 * r[4]), size * (0.45 + 0.35 * rand()), size * (0.8 + 0.5 * rand()), 0.25 + 0.35 * rand(),
                  ...made.map((v) => v * light), rand(), 1, 0, 0, 0);
    };
    const singles = Math.floor(rand() * (5 + 10 * stony) * kind.stones + 0.5);
    for (let k = 0; k < singles; k++) stone((wi + rand()) * PATCH, (wj + rand()) * PATCH, rand() < 0.05);
    if (rand() < (0.08 + 0.25 * stony) * kind.stones) {
      const ax = (wi + rand()) * PATCH, az = (wj + rand()) * PATCH;
      const spread = 0.08 + 0.2 * rand();
      const many = 4 + Math.floor(rand() * 10);
      for (let k = 0; k < many; k++) {
        const a = rand() * 2 * Math.PI, d = spread * Math.sqrt(-2 * Math.log(1 - 0.95 * rand()));
        stone(ax + Math.cos(a) * d, az + Math.sin(a) * d, rand() < 0.08);
      }
    }
    patch = { tufts: new Float32Array(tufts), heads: new Float32Array(heads), stones: new Float32Array(stones) };
    grown.set(key, patch);
    work.grow += performance.now() - started;
    if (grown.size > KEPT) grown.delete(grown.keys().next().value);
    return patch;
  }

  // **The short grass**, a square at a time and only when it is to be drawn:
  // the same thickness and gaps as the tufts, a few centimetres high, packed
  // close, greener and less dry.
  const grownShort = new Map();
  function growShort(wi, wj) {
    const key = wj * PATCHES + wi;
    let short = grownShort.get(key);
    if (short) return short;
    const rand = stream(latticeBits(wi, wj, PATCHES, PATCHES, 104729));
    const out = [];
    for (let k = 0; k < kind.short; k++) {
      const x = (wi + rand()) * PATCH, z = (wj + rand()) * PATCH;
      const y = height(x, z);
      const thick = 0.35 + 0.65 * coverAt(kind, x, z, y);
      const keep = rand();
      if (keep >= thick || keep >= thick * (1 - 0.95 * openAt(kind, x, z, thick))) continue;
      const r = [rand(), rand(), rand(), rand(), rand()];
      const [low, high] = kind.shortHeight;
      const ground = colour(x, z);
      const hue = (r[3] - 0.5) * 2;
      out.push(x, y, z, r[0] * 2 * Math.PI, low + (high - low) * r[1],
               0.05 + 0.2 * r[2], fieldNoise(x, z, LAYER.comb) * 4 * Math.PI, 0,
               ground[0] * 1.35 * (1 + 0.12 * hue), ground[1] * 1.45, ground[2] * 1.05 * (1 - 0.2 * hue),
               0.05 + 0.15 * r[4], 1, 1, rand(), rand());
    }
    short = new Float32Array(out);
    grownShort.set(key, short);
    if (grownShort.size > KEPT_SHORT) grownShort.delete(grownShort.keys().next().value);
    return short;
  }

  // MARK: The plants standing on it

  // Each plant's foot, by every square it reaches into, unwrapped. A plant
  // arriving or leaving lays again only the squares it stands in (`renew`),
  // and only if they are held: plants mostly come and go at the far edge of
  // the ground, well out of sight.
  let feet = new Map();
  const renew = new Set();
  function standing(plants) {
    const before = feet;
    feet = new Map();
    for (const plant of plants) {
      const reach = Math.max(plant.foot, plant.flat ?? 0);
      for (let i = Math.floor((plant.x - reach) / PATCH); i <= Math.floor((plant.x + reach) / PATCH); i++) {
        for (let j = Math.floor((plant.z - reach) / PATCH); j <= Math.floor((plant.z + reach) / PATCH); j++) {
          const key = `${i},${j}`;
          if (!feet.has(key)) feet.set(key, []);
          feet.get(key).push(plant);
        }
      }
    }
    const same = (a = [], b = []) => a.length === b.length && a.every((plant, k) => plant === b[k]);
    for (const key of new Set([...before.keys(), ...feet.keys()])) {
      if (!same(before.get(key), feet.get(key))) renew.add(key);
    }
  }

  // **Under a plant**: the same darkening its foot gives the ground
  // (`FOOT_FRAGMENT` in `wildfields.js`), and shorter by its stem, so its
  // lowest leaves are not drowned; none right at the stem. And nothing at all
  // under leaves that lie flat on the ground — a water lily's pads, out of
  // the water (`flat`, how far they reach, joined 2 October 2026): a tuft or
  // a stone there would come up through the leaf.
  function besidePlants(out, from, count, stride, near, tuft) {
    if (!near) return;
    for (let k = 0; k < count; k++) {
      const o = from + k * stride;
      let shade = 1, keep = 1;
      for (const plant of near) {
        const d = Math.hypot(out[o] - plant.x, out[o + 2] - plant.z);
        if (d < (plant.flat ?? 0)) {
          if (tuft) out[o + 14] = 2;
          else out[o + 4] = out[o + 5] = out[o + 6] = 0;
        }
        const r = d / plant.foot;
        if (r >= 1) continue;
        shade *= 1 - 0.55 * (1 - smooth(0.15, 1, r));
        keep = Math.min(keep, 0.35 + 0.65 * smooth(0.12, 0.75, r));
        if (tuft && r < 0.14) out[o + 14] = 2;
      }
      out[o + 12] = shade;
      if (tuft) out[o + 13] = keep;
    }
  }

  // MARK: What is in sight

  let held = null, heldAt = 1;
  let dirty = true;
  // What the detail has cost the page, in milliseconds, for the workbench.
  const work = { grow: 0, lay: 0, lays: 0, relays: 0 };
  // What is in sight, each kind in one buffer: the tufts, the heads of those
  // gone to seed, the stones, and the short grass when it is drawn.
  const pool = (buffer, stride, tuft) => ({
    buffer, stride, tuft, data: new Float32Array(0), top: 0, runs: new Map(), free: [], held: null,
  });
  const pools = {
    tufts: pool(tuftBuffer, TUFT, true),
    heads: pool(headBuffer, TUFT, true),
    stones: pool(stoneBuffer, STONE, false),
    short: pool(shortBuffer, TUFT, true),
  };
  const live = (p) => p.top - p.free.reduce((sum, run) => sum + run.count, 0);

  // The squares a look can see: every square in the ground's reach whose
  // middle, widened by its own half-diagonal, a tall tuft and `margin` more
  // metres, lands on the screen.
  function inSight(m, [cx, cz, reach], margin = 0) {
    const out = [];
    const rx = (1.1 + margin) * Math.hypot(m[0], m[4], m[8]), ry = (1.1 + margin) * Math.hypot(m[1], m[5], m[9]);
    for (let i = Math.floor((cx - reach) / PATCH); i <= Math.floor((cx + reach) / PATCH); i++) {
      for (let j = Math.floor((cz - reach) / PATCH); j <= Math.floor((cz + reach) / PATCH); j++) {
        const x = (i + 0.5) * PATCH, z = (j + 0.5) * PATCH, y = height(x, z);
        const sx = m[0] * x + m[4] * y + m[8] * z + m[12];
        const sy = m[1] * x + m[5] * y + m[9] * z + m[13];
        if (Math.abs(sx) < 1 + rx && Math.abs(sy) < 1 + ry) out.push([i, j]);
      }
    }
    return out;
  }

  // **Each square held has its own run of its pool's buffer, and keeps it.**
  // A square coming into sight is laid into a free run or at the end; one
  // going out of sight is blanked where it lies — a tuft given way, a stone of
  // no size — and its run freed. So a walk writes the few squares each step
  // brings in rather than the thousands it keeps, which was most of what
  // walking cost. When the buffer is full, or more of it is holes than half
  // of what is laid, it is laid again from the start.
  function lay(p, squares, holds, fresh) {
    const started = performance.now();
    const wanted = new Map(squares.map(([i, j]) => [`${i},${j}`, [i, j]]));
    let fits = !fresh && p.data.length > 0;
    if (fits) {
      for (const [key, run] of p.runs) {
        if (wanted.has(key)) continue;
        blank(p, run);
        p.free.push(run);
        p.runs.delete(key);
      }
      for (const [key, [i, j]] of wanted) {
        const had = p.runs.get(key);
        if (had && !renew.has(key)) continue;
        const values = holds(mod(i, PATCHES), mod(j, PATCHES));
        const count = values.length / p.stride;
        let run = had && had.count === count ? had : null;
        if (had && !run) { blank(p, had); p.free.push(had); p.runs.delete(key); }
        run ??= claim(p, count);
        if (!run) { fits = false; break; }
        write(p, run, values, i, j, true);
        p.runs.set(key, run);
      }
      if (fits && p.top - live(p) > live(p) / 2 + 512) fits = false;
    }
    if (!fits) relay(p, wanted, holds);
    work.lay += performance.now() - started;
    work.lays++;
  }

  // A free run of at least `count`, or the end of what is laid if there is
  // room; the rest of a longer free run stays free (and blank).
  function claim(p, count) {
    const k = p.free.findIndex((run) => run.count >= count);
    if (k >= 0) {
      const [run] = p.free.splice(k, 1);
      if (run.count > count) p.free.push({ at: run.at + count, count: run.count - count });
      return { at: run.at, count };
    }
    if ((p.top + count) * p.stride > p.data.length) return null;
    const run = { at: p.top, count };
    p.top += count;
    return run;
  }

  // Every square laid again from the start, with room to spare.
  function relay(p, wanted, holds) {
    const pieces = [...wanted].map(([key, [i, j]]) => [key, i, j, holds(mod(i, PATCHES), mod(j, PATCHES))]);
    const total = pieces.reduce((sum, [, , , values]) => sum + values.length, 0);
    const room = Math.ceil(total * 1.5) + 64 * p.stride;
    if (p.data.length < room) p.data = new Float32Array(room);
    p.runs.clear();
    p.free = [];
    p.top = 0;
    for (const [key, i, j, values] of pieces) {
      const run = { at: p.top, count: values.length / p.stride };
      p.top += run.count;
      write(p, run, values, i, j, false);
      p.runs.set(key, run);
    }
    gl.bindBuffer(gl.ARRAY_BUFFER, p.buffer);
    gl.bufferData(gl.ARRAY_BUFFER, p.data, gl.DYNAMIC_DRAW);
    work.relays++;
  }

  // A square's own, moved from the field's own square to the one in sight,
  // and shaded beside the plants.
  function write(p, run, values, i, j, upload) {
    const wi = mod(i, PATCHES), wj = mod(j, PATCHES);
    const dx = (i - wi) * PATCH, dz = (j - wj) * PATCH;
    const at = run.at * p.stride;
    p.data.set(values, at);
    for (let o = at; o < at + values.length; o += p.stride) { p.data[o] += dx; p.data[o + 2] += dz; }
    besidePlants(p.data, at, run.count, p.stride, feet.get(`${i},${j}`), p.tuft);
    if (upload) send(p, run);
  }

  function blank(p, run) {
    for (let k = 0; k < run.count; k++) {
      const o = (run.at + k) * p.stride;
      if (p.tuft) p.data[o + 14] = 2;
      else p.data[o + 4] = p.data[o + 5] = p.data[o + 6] = 0;
    }
    send(p, run);
  }

  function send(p, run) {
    if (!run.count) return;
    gl.bindBuffer(gl.ARRAY_BUFFER, p.buffer);
    gl.bufferSubData(gl.ARRAY_BUFFER, run.at * p.stride * 4, p.data, run.at * p.stride, run.count * p.stride);
  }

  /// Draws the tufts and the stones in sight. The stage has set the light on
  /// `programs` already; `around` is the middle of the ground as built and how
  /// far it reaches, `metresPerPixel` how much of the field a pixel of the
  /// canvas covers.
  //
  // **What is laid reaches a little past what is seen** (`HELD`), and is laid
  // again only when a square that is seen is not there, a plant has come or
  // gone in one, or the look has come closer or gone further.
  function draw(viewProjection, { around, metresPerPixel }) {
    const seen = inSight(viewProjection, around);
    const missing = (squares) => !squares || seen.some(([i, j]) => !squares.has(`${i},${j}`));
    const touched = (squares) => squares && [...renew].some((key) => squares.has(key));
    const close = metresPerPixel < SHORT.from;
    const zoomed = Math.abs(Math.log(metresPerPixel / heldAt)) > 0.3;
    const pairs = (squares) => [...squares].map((key) => key.split(',').map(Number));
    if (dirty || zoomed || missing(held) || touched(held)) {
      const squares = dirty || zoomed || missing(held) ? inSight(viewProjection, around, HELD) : pairs(held);
      heldAt = metresPerPixel;
      lay(pools.tufts, squares, (wi, wj) => grow(wi, wj).tufts, dirty);
      lay(pools.heads, squares, (wi, wj) => grow(wi, wj).heads, dirty);
      lay(pools.stones, squares, (wi, wj) => grow(wi, wj).stones, dirty);
      held = new Set(squares.map(([i, j]) => `${i},${j}`));
    }
    const short = pools.short;
    if (close && (dirty || missing(short.held) || touched(short.held))) {
      // The short grass is many times denser, so it is held closer.
      const squares = dirty || missing(short.held) ? inSight(viewProjection, around, HELD / 3) : pairs(short.held);
      lay(short, squares, growShort, dirty || !short.held);
      short.held = new Set(squares.map(([i, j]) => `${i},${j}`));
    }
    if (!close) short.held = null;
    renew.clear();
    dirty = false;
    const tufted = (p, mesh, scale) => {
      gl.useProgram(tuftProgram.program);
      gl.uniform1f(tuftProgram.at.pixel, metresPerPixel);
      gl.uniform1f(tuftProgram.at.scale, scale);
      bindInputs(tuftProgram.at);
      gl.bindVertexArray(mesh.vao);
      gl.drawElementsInstanced(gl.TRIANGLES, mesh.count, gl.UNSIGNED_SHORT, 0, p.top);
    };
    if (close && short.top) tufted(short, shortMesh, smooth(SHORT.from, SHORT.full, metresPerPixel));
    const level = tuftLevels.find((l) => metresPerPixel < l.finer);
    if (pools.tufts.top) tufted(pools.tufts, level.blades, 1);
    if (pools.heads.top) tufted(pools.heads, level.heads, 1);
    if (pools.stones.top) {
      gl.useProgram(stoneProgram.program);
      bindInputs(stoneProgram.at);
      const facets = stoneLevels.find((l) => metresPerPixel < l.finer);
      gl.bindVertexArray(facets.vao);
      gl.drawElementsInstanced(gl.TRIANGLES, facets.count, gl.UNSIGNED_SHORT, 0, pools.stones.top);
    }
    gl.bindVertexArray(null);
  }

  function bindInputs(at) {
    inputs.wear.bind(gl, at);
    inputs.wet.bind(gl, at);
  }

  return {
    // The ground's fragment shader, to be lit by the field and drawn by the
    // stage, and the uniforms it adds.
    fragment: groundFragment(kind, inputs),
    uniforms: ['look', ...inputUniforms],
    programs: [tuftProgram, stoneProgram],
    bindInputs,
    standing,
    draw,
    // Something on the field changed what an input answers: draw it again.
    // With `regrow`, the ground's height changed too (water arriving digs a
    // pond's floor): every square is grown again on the new ground — or, given
    // boxes (`[x0, z0, x1, z1]` in the field's metres, as the water's
    // `changes` answers), only the squares they reach, laid again where they
    // lie and the rest left alone.
    changed({ regrow = false } = {}) {
      if (Array.isArray(regrow)) {
        const reached = (wi, wj) => regrow.some(([x0, z0, x1, z1]) =>
          Math.abs(wrap((wi + 0.5) * PATCH - (x0 + x1) / 2)) <= (x1 - x0 + PATCH) / 2
          && Math.abs(wrap((wj + 0.5) * PATCH - (z0 + z1) / 2)) <= (z1 - z0 + PATCH) / 2);
        for (const cache of [grown, grownShort]) {
          for (const key of [...cache.keys()]) if (reached(key % PATCHES, Math.floor(key / PATCHES))) cache.delete(key);
        }
        for (const squares of [held, pools.short.held]) {
          for (const key of squares ?? []) {
            const [i, j] = key.split(',').map(Number);
            if (reached(mod(i, PATCHES), mod(j, PATCHES))) renew.add(key);
          }
        }
        return;
      }
      dirty = true;
      if (regrow) { grown.clear(); grownShort.clear(); }
    },
    counts: () => ({ tufts: live(pools.tufts), heads: live(pools.heads), stones: live(pools.stones),
                     short: pools.short.held ? live(pools.short) : 0, drawn: pools.tufts.top,
                     squares: held?.size ?? 0, grown: grown.size,
                     work: Object.fromEntries(Object.entries(work).map(([k, v]) => [k, Math.round(v * 10) / 10])) }),
  };
}

// MARK: - Arithmetic

// A stream of numbers from 0 to 1 from a seed, always the same for the same
// seed (mulberry32).
function stream(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function mod(a, n) { return ((a % n) + n) % n; }

// A distance along the field, the short way round.
function wrap(d) { return d - FIELD * Math.round(d / FIELD); }

