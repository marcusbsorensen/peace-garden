// The side of a plot: a solid slab of earth hanging under the rim, with one
// lower edge, lit as planes and banded — the app's `GardenGround.side`, drawn
// in WebGL so that a plot on the phone and a plot in the browser are the same
// object.
//
// **Asked for on 2 October 2026**, the night the app's plot became a slab
// (Marcus: *less like it is melting away with the soil below, and more like a
// solid slab of earth with organic contours that is floating*). The website's
// sides had been upright banks to a ragged floor, three flat colours down
// them and a normal per eight centimetres of rim, which lit the bank in
// stripes. Marcus approved the app's slab and asked for the website's plots to
// match it. `docs/ARRANGING.md` §*A keel that tapers to nothing* has the
// reasoning; `docs/WEB-GARDENS.md` §*The plot's side as a solid slab* has what
// is different here and why.
//
// **What is the app's, number for number:** the depth, the taper and how it
// eases, the lower edge's wander and the sag under a dip in the rim, where the
// three strata change and how each is graded, the faint layers in them, and
// the stones — how often, how big, where, what shape and what colour.
//
// **What is the web's:** the light (`LIGHT` in `longwalk.js`, the fixed noon
// sun, gamma-correct), and so how much lighter than its materials the side is
// drawn (`LIFT`) and how far a stone's upper face is turned to a sky with the
// sun high in it; and the Long Walk's outline, three plots end to end, and so
// which way the side is drawn in. The geometry is built here once per plot;
// the bands, the layers and their edges are worked out per pixel by the
// side's own shader, so they stay sharp at every zoom and cost a few thousand
// triangles rather than tens of thousands.
//
// **The same every visit.** Everything here comes from the plot's outline and
// a salt the area already has for its floor; nothing is random.
//
// This file is a leaf: it imports nothing, so `longwalk.js` and every area
// that builds a ground can import it without a cycle.

/// How deep the near side reads from the front, in metres. `GardenGround.rimDepth`.
export const RIM_DEPTH = 0.95;

/// How far in the side has come by its lower edge. `GardenGround.taper`.
export const TAPER = 0.20;

/// How deep the side really is: `RIM_DEPTH` and half the taper, because a side
/// drawn in at its foot is a side whose foot has moved up the screen by half
/// the taper, and the near side should still show 0.95 m. `GardenGround.sideDepth`.
export const SIDE_DEPTH = RIM_DEPTH + TAPER / 2;

/// What the side is made of, top to bottom: `GardenGround`'s humus, earth,
/// bedrock and stone. `COLOUR` in `longwalk.js` reads the first three from here.
export const STRATA = {
  humus: [0.205, 0.158, 0.116],
  earth: [0.375, 0.300, 0.232],
  bedrock: [0.340, 0.330, 0.318],
  stone: [0.455, 0.437, 0.415],
};

/// The rock the lower part is made of: the bedrock with some stone in it, so
/// that a side facing a little down by the time it reaches it does not come
/// out the same brown as the earth. `GardenGround.rock`.
const ROCK = mix(STRATA.bedrock, STRATA.stone, 0.45);

/// How much lighter the side is drawn than its materials.
///
/// **Measured, the app's way, against this page's light** (2 October 2026).
/// Leaning in, the side faces a little down, and under a noon sun 62° up that
/// costs the face in the sun a fifth of its light: at the materials' own
/// colours it came out at 42 of 255 averaged down the face, against 52 for the
/// upright bank. At 1.2 the face in the sun is as bright as the bank was (51)
/// and the face in shade a little brighter (33 against 27), which keeps it
/// clear of the night sky behind it. The app's 1.45 is for its own light,
/// which is not gamma-correct; here it would draw the face in shade half as
/// bright again as the bank was.
export const LIFT = 1.2;

/// How far either side the facing is smoothed, in metres, so the outline's
/// finest wander does not light the side in stripes and a bay still turns its
/// own way to the light. The app's eighteen centimetres.
const FACING = 0.18;

/// Rows down the side. The bands are drawn per pixel, so these carry only the
/// taper's curve and the lean of the light, and eight is finer than either.
const ROWS = 8;

/// Stones: one chance in a little under two every half metre of rim.
const SLOT = 0.5;

/// How few pixels across a stone may be before it is not drawn, because a
/// stone that small is a speck rather than a stone.
const SPECK = 4;

/// The side hung from a plot's outline.
///
/// `outline` is `readOutline`'s answer, anticlockwise from above, at the
/// plot's own size. `salt` is the area's own floor seed, so each area's lower
/// edge undulates its own way. `scale` shrinks the whole slab after it is
/// worked out, for the neighbours seen through a gateway: they are a plot of
/// this garden seen from further off, not a smaller kind of thing. `top`, if
/// given, is the ground's height at each point of the outline; every plot on
/// the website is level at its rim today, so it is 0 everywhere, and where it
/// dips — the app's ravine — the lower edge sags under the dip in a curve.
///
/// Answers `{ positions, normals, places, hangs, indices }` for the side's
/// program (`sideShaders`): where each point is, which way it faces, where it
/// is on the side in metres (round the rim, down from it, and the perimeter
/// and salt the shader needs), and how the strata hang there. A stone carries
/// its own colour in `hangs` and a negative last component to say so.
export function hangSide(outline, { salt = 0, scale = 1, top = null } = {}) {
  // **Hung once a plot.** A turn builds the ground again and hands this the
  // same outline, and the side is the same side from every quarter — so it is
  // kept, keyed on the outline's points themselves, rather than worked out
  // four times for the four ways round: a few milliseconds a turn for the
  // Long Walk's on a laptop, and about four times that on a phone.
  const print = outline.reduce((sum, [x, z], i) => sum + x * (i + 1) + z * (i + 7), 0);
  const key = top ? null : `${salt}:${scale}:${outline.length}:${print}`;
  if (key !== null && HUNG.has(key)) return HUNG.get(key);
  const side = hangAnew(outline, salt, scale, top);
  if (key !== null) {
    if (HUNG.size > 24) HUNG.clear();
    HUNG.set(key, side);
  }
  return side;
}

// The sides already hung, by outline (`hangSide`): the page's own plot and
// the few beside it.
const HUNG = new Map();

function hangAnew(outline, salt, scale, top) {
  const n = outline.length;
  const along = new Float64Array(n);
  for (let v = 1; v < n; v++) {
    along[v] = along[v - 1] + Math.hypot(outline[v][0] - outline[v - 1][0], outline[v][1] - outline[v - 1][1]);
  }
  const perimeter = along[n - 1] + Math.hypot(outline[0][0] - outline[n - 1][0], outline[0][1] - outline[n - 1][1]);

  // Outward, as the direction of travel turned a quarter clockwise, over
  // `FACING` either side.
  const span = Math.max(1, Math.round(FACING / (perimeter / n)));
  const outward = outline.map((_, v) => {
    const a = outline[(v - span + n) % n], b = outline[(v + span) % n];
    const tx = b[0] - a[0], tz = b[1] - a[1], l = Math.hypot(tx, tz);
    return l > 1e-9 ? [tz / l, -tx / l] : [1, 0];
  });

  // How the side hangs at each point of the rim, in metres down from the
  // ground's edge: the lower edge undulating by about a tenth of the depth
  // over a pace and a half, with a finer wander a third as large; under a dip
  // in the rim, sagging to keep half a metre of side, eased over a quarter of
  // a metre so the sag is a curve; and each boundary wandering on its own.
  const wander = (s, wavelength, k) => roundTheLoop(s, perimeter, wavelength, salt * 16 + k);
  const hang = outline.map((_, v) => {
    const s = along[v];
    const rim = top ? top[v] : 0;
    const floor = -SIDE_DEPTH * (1 + 0.09 * wander(s, 1.7, 1) + 0.03 * wander(s, 0.6, 2));
    const under = rim - 0.5, ease = 0.25;
    const h = clamp(0.5 + 0.5 * (under - floor) / ease, 0, 1);
    const deep = rim - (under + (floor - under) * h - ease * h * (1 - h));
    const humus = Math.min(deep * 0.3, 0.15 + 0.03 * wander(s, 0.9, 3));
    const rock = Math.min(Math.max(deep * 0.58 + 0.07 * wander(s, 1.3, 4), humus + 0.12), deep - 0.12);
    return { top: rim, deep, humus, rock, tone: 1 + 0.045 * wander(s, 0.8, 5) };
  });

  // **Drawn in along the way the rim faces, not toward the middle.** The app
  // draws its square plot in toward the middle. Nine plots here are the same
  // square, but the Long Walk is three of them end to end, and drawn toward
  // the middle its long sides would have leant in barely 7 cm near its ends.
  // Along the smoothed facing the side leans in by the whole taper all the way
  // round, a little under the rim and more toward the lower edge, so it meets
  // the edge at an angle and the edge is a firm one; on a square plot that is
  // within 5 cm of the app's anywhere, and the same at the middle of each side
  // and at each corner.
  const inset = (f) => TAPER * (0.55 * f + 0.45 * f * f);
  const lean = (f, deep) => TAPER / deep * (0.55 + 0.9 * f);
  const world = (v, down) => {
    const h = hang[v], f = clamp(down / h.deep, 0, 1), d = inset(f), [ox, oz] = outward[v];
    return [outline[v][0] - ox * d, h.top - f * h.deep, outline[v][1] - oz * d];
  };
  // **Lit as a plane**: the way the rim faces there, turned down by the lean.
  const facing = (v, f) => {
    const [ox, oz] = outward[v], l = lean(f, hang[v].deep), m = Math.hypot(ox, l, oz);
    return [ox / m, -l / m, oz / m];
  };

  const positions = [], normals = [], places = [], hangs = [], indices = [];
  const put = (p, normal, place, held) => {
    positions.push(p[0] * scale, p[1] * scale, p[2] * scale);
    normals.push(...normal);
    places.push(...place);
    hangs.push(...held);
    return positions.length / 3 - 1;
  };

  // A column a point of the rim, and the first again at the end with the
  // whole perimeter as its distance round, so the loop closes without a seam
  // in anything the shader works out from that distance.
  for (let c = 0; c <= n; c++) {
    const v = c % n, h = hang[v], s = c === n ? perimeter : along[v];
    for (let r = 0; r <= ROWS; r++) {
      const f = r / ROWS;
      put(world(v, f * h.deep), facing(v, f), [s, f * h.deep, perimeter, salt], [h.humus, h.rock, h.deep, h.tone]);
    }
  }
  for (let c = 0; c < n; c++) {
    for (let r = 0; r < ROWS; r++) {
      const a = c * (ROWS + 1) + r, b = a + ROWS + 1;
      indices.push(a, b, b + 1, a, b + 1, a + 1);
    }
  }

  // **A few stones sitting in the rock**, and the odd one up in the earth: the
  // app's, each a lump wider than it is tall with nine corners at uneven
  // distances, drawn as the shadow it sits in, its body, and an upper face
  // turned a little toward the sky. Close in tone to the rock round it, since
  // smooth round stones a shade lighter read as rivets. Each layer stands a
  // few millimetres proud of the one under it, which is less than a pixel at
  // any zoom a page allows and is what keeps them from fighting for depth.
  const place = (s, down) => {
    const wrapped = ((s % perimeter) + perimeter) % perimeter;
    const v = before(along, wrapped), w = (v + 1) % n;
    const run = (w === 0 ? perimeter : along[w]) - along[v];
    const t = run > 1e-9 ? (wrapped - along[v]) / run : 0;
    const p = world(v, down), q = world(w, down);
    return [p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t, p[2] + (q[2] - p[2]) * t];
  };
  for (let k = 0; k < Math.floor(perimeter / SLOT); k++) {
    const g = (i, j) => grain(k + salt * 4099, i, j);
    if (g(7, 51) >= 0.45) continue;
    const s = (k + 0.2 + 0.6 * g(7, 52)) * SLOT;
    const v = before(along, s), h = hang[v];
    const inRock = g(7, 53) < 0.75;
    const width = inRock ? 0.06 + 0.07 * g(7, 55) : 0.04 + 0.03 * g(7, 55);
    const tall = width * (0.55 + 0.25 * g(7, 56));
    const centre = inRock
      ? h.rock + (h.deep - h.rock) * (0.25 + 0.45 * g(7, 54))
      : h.humus + (h.rock - h.humus) * (0.35 + 0.4 * g(7, 54));
    if (!(centre - tall > h.humus + 0.02 && centre + tall < h.deep - 0.05)) continue;

    const wall = facing(v, centre / h.deep);
    // The upper face turned toward the sky by less than the app's 0.22: under
    // a sun 62° up, which the app's hours mostly are not, that much turned it
    // into the sun and it came out two fifths brighter than the rock round it,
    // a row of rivets along the face in the light. At 0.08 it is a fifth
    // brighter there, and in the shade a few per cent, as the app's upper
    // face is on a side in shade.
    const up = normalise([wall[0], wall[1] + 0.08, wall[2]]);
    const around = sideColour(centre, h.humus, h.rock, h.deep);
    const body = mix(ROCK, STRATA.stone, 0.2).map((x) => x * LIFT * (0.96 + 0.08 * g(7, 59)));
    const layer = (size, lift, colour, normal, proud) => {
      const spot = (ds, dd) => {
        const p = place(s + ds, centre - lift * tall + dd);
        return [[p[0] + wall[0] * proud, p[1] + wall[1] * proud, p[2] + wall[2] * proud], [s + ds, centre - lift * tall + dd]];
      };
      const held = [...colour, -1];
      const [middle, at] = spot(0, 0);
      const first = put(middle, normal, [at[0], at[1], width, salt], held);
      for (let i = 0; i < 9; i++) {
        const angle = (i + 0.5 * (g(i, 57) - 0.5)) / 9 * 2 * Math.PI;
        const r = size * (0.74 + 0.36 * g(i, 58));
        const [p, q] = spot(width * r * Math.cos(angle), tall * r * Math.sin(angle));
        put(p, normal, [q[0], q[1], width, salt], held);
      }
      for (let i = 0; i < 9; i++) indices.push(first, first + 1 + i, first + 1 + ((i + 1) % 9));
    };
    layer(1.03, -0.3, around.map((x) => x * 0.78), wall, 0.0015);
    layer(1, 0, body, wall, 0.003);
    layer(0.62, 0.32, body, up, 0.0045);
  }

  return {
    positions: new Float32Array(positions),
    normals: new Float32Array(normals),
    places: new Float32Array(places),
    hangs: new Float32Array(hangs),
    indices: new Uint32Array(indices),
  };
}

/// The side's two shaders, around `shade`, the light every surface in the
/// garden is lit by (`SHADE` in `longwalk.js`), so the side is lit as the
/// ground and the plants are and not by a second copy.
///
/// The fragment works out what the side is made of where it is: the band from
/// how far down it is against where this stretch of side's boundaries lie,
/// graded inside each band as the app grades it, with its edges softened over
/// a pixel and a half so they never stair-step; the faint layers in each band,
/// which thicken and thin along the side and meet themselves round the loop;
/// and the slow tone that wanders along it. A stone has its colour already.
export function sideShaders(shade) {
  const vec = (c) => `vec3(${c.map((x) => x.toFixed(4)).join(', ')})`;
  const vertex = `#version 300 es
in vec3 position; in vec3 normal; in vec4 place; in vec4 hang;
uniform mat4 viewProjection;
uniform vec3 offset;
out vec3 vNormal; out vec4 vPlace; out vec4 vHang;
void main() {
  vNormal = normal; vPlace = place; vHang = hang;
  gl_Position = viewProjection * vec4(position + offset, 1.0);
}`;
  const fragment = `#version 300 es
precision highp float;
precision highp int;
in vec3 vNormal; in vec4 vPlace; in vec4 vHang;
uniform float opacity;
${shade}
const vec3 HUMUS = ${vec(STRATA.humus)};
const vec3 EARTH = ${vec(STRATA.earth)};
const vec3 ROCK = ${vec(ROCK)};
const float LIFT = ${LIFT.toFixed(4)};
out vec4 outColour;

float grain(ivec3 p) {
  uint h = (uint(p.x) * 73856093u) ^ (uint(p.y) * 19349663u) ^ (uint(p.z) * 83492791u);
  h ^= h >> 16u; h *= 0x7feb352du; h ^= h >> 15u; h *= 0x846ca68bu; h ^= h >> 16u;
  return float(h) * (1.0 / 4294967296.0);
}

// Smooth noise over the side, -1 to 1, as \`Organic.noise\` is.
float noise(vec2 p, int seed) {
  vec2 cell = floor(p), f = p - cell;
  f = f * f * (3.0 - 2.0 * f);
  ivec2 i = ivec2(cell);
  float a = grain(ivec3(i, seed)), b = grain(ivec3(i + ivec2(1, 0), seed));
  float c = grain(ivec3(i + ivec2(0, 1), seed)), d = grain(ivec3(i + ivec2(1, 1), seed));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y) * 2.0 - 1.0;
}

// The faint layers, as sediment lies: a slow wander along the side and a
// short one down it. Eased into itself over the last metre of the loop.
float layersAt(float s, float down, int seed) {
  return (noise(vec2(s / 1.2, down / 0.08), seed) + 0.5 * noise(vec2(s / 0.45, down / 0.035), seed + 1)) / 1.5;
}
float layers(float s, float down, float perimeter, int seed) {
  float here = layersAt(s, down, seed);
  if (s <= perimeter - 1.0) return here;
  float t = s - (perimeter - 1.0);
  return mix(here, layersAt(s - perimeter, down, seed), t * t * (3.0 - 2.0 * t));
}

// \`GardenGround.sideColour\`, with each boundary softened over \`aa\`.
vec3 strata(float down, float humusTo, float rockFrom, float bottom, float aa) {
  float fh = down / max(humusTo, 1e-4);
  vec3 humus = mix(HUMUS * 0.94, mix(HUMUS, EARTH, 0.3), clamp((fh - 0.45) / 0.55, 0.0, 1.0));
  float fe = (down - humusTo) / max(rockFrom - humusTo, 1e-4);
  vec3 earth = fe < 0.2
    ? mix(mix(EARTH, HUMUS, 0.16), EARTH, clamp(fe / 0.2, 0.0, 1.0))
    : mix(EARTH, mix(EARTH, ROCK, 0.25), clamp((fe - 0.75) / 0.25, 0.0, 1.0));
  float fr = (down - rockFrom) / max(bottom - rockFrom, 1e-4);
  vec3 rock = mix(mix(EARTH, ROCK, 0.6), ROCK, clamp(fr / 0.3, 0.0, 1.0));
  vec3 upper = mix(humus, earth, smoothstep(-aa, aa, down - humusTo));
  return mix(upper, rock, smoothstep(-aa, aa, down - rockFrom)) * LIFT;
}

void main() {
  vec3 albedo;
  if (vHang.w < 0.0) {
    // A stone, too few pixels across to be anything but a speck.
    if (vPlace.z < ${SPECK.toFixed(1)} * fwidth(vPlace.x)) discard;
    albedo = vHang.rgb;
  } else {
    float down = vPlace.y;
    float aa = 0.75 * fwidth(down) + 1e-5;
    int seed = int(vPlace.w + 0.5) * 4 + 1;
    float faint = mix(0.025, 0.05, smoothstep(-aa, aa, down - vHang.x));
    albedo = strata(down, vHang.x, vHang.y, vHang.z, aa) * vHang.w
      * (1.0 + faint * layers(vPlace.x, down, vPlace.z, seed));
  }
  outColour = vec4(shade(albedo, normalize(vNormal)) * opacity, opacity);
}`;
  return { vertex, fragment };
}

/// `GardenGround.sideColour`, for the ground a stone's shadow sits on.
function sideColour(down, humusTo, rockFrom, bottom) {
  const { humus, earth } = STRATA;
  let base;
  if (down < humusTo) {
    const f = down / Math.max(humusTo, 1e-6);
    base = mix(humus.map((x) => x * 0.94), mix(humus, earth, 0.3), (f - 0.45) / 0.55);
  } else if (down < rockFrom) {
    const f = (down - humusTo) / Math.max(rockFrom - humusTo, 1e-6);
    base = f < 0.2
      ? mix(mix(earth, humus, 0.16), earth, f / 0.2)
      : mix(earth, mix(earth, ROCK, 0.25), (f - 0.75) / 0.25);
  } else {
    const f = (down - rockFrom) / Math.max(bottom - rockFrom, 1e-6);
    base = mix(mix(earth, ROCK, 0.6), ROCK, f / 0.3);
  }
  return base.map((x) => x * LIFT);
}

/// A slow wander round a closed loop, about -1 to 1, that meets itself with no
/// seam: a whole number of knots round the loop, eased through with a
/// Catmull-Rom curve, because a smoothstep is flat at every knot and a lower
/// edge made of it undulates in a row of little plateaus.
/// `GardenGround.roundTheLoop`.
function roundTheLoop(along, perimeter, wavelength, salt) {
  const knots = Math.max(3, Math.round(perimeter / wavelength));
  const t = along / perimeter * knots;
  const i = Math.floor(t), f = t - i;
  const knot = (k) => grain(((k % knots) + knots) % knots, salt, 61) * 2 - 1;
  const p0 = knot(i - 1), p1 = knot(i), p2 = knot(i + 1), p3 = knot(i + 2);
  const f2 = f * f, f3 = f2 * f;
  return 0.5 * (2 * p1 + (p2 - p0) * f + (2 * p0 - 5 * p1 + 4 * p2 - p3) * f2 + (3 * p1 - p0 - 3 * p2 + p3) * f3);
}

/// A fixed number in 0…1 for three whole numbers, so a bank of earth is the
/// same bank every time it is drawn. The side's shader hashes the same way.
function grain(a, b, salt = 0) {
  let h = Math.imul(a | 0, 73856093) ^ Math.imul(b | 0, 19349663) ^ Math.imul(salt | 0, 83492791);
  h ^= h >>> 16; h = Math.imul(h, 0x7feb352d);
  h ^= h >>> 15; h = Math.imul(h, 0x846ca68b);
  h ^= h >>> 16;
  return (h >>> 0) / 4294967296;
}

// The last point of the rim at or before `s` metres round it.
function before(along, s) {
  let low = 0, high = along.length - 1;
  while (low < high) {
    const middle = (low + high + 1) >> 1;
    if (along[middle] <= s) low = middle; else high = middle - 1;
  }
  return low;
}

function mix(a, b, t) {
  const k = clamp(t, 0, 1);
  return a.map((x, i) => x + (b[i] - x) * k);
}
function clamp(x, lo, hi) { return Math.min(Math.max(x, lo), hi); }
function normalise(v) { const l = Math.hypot(...v); return v.map((x) => x / l); }
