// Plots of the Long Walk, drawn the way the app draws a plot: a floating
// slab of ground seen in true isometric, a mown path down the middle, a tall
// yew behind the far border and a low hedge in front of the near one.
//
// The module plants the arrivals by the Long Walk's rule and grows each one;
// this file draws the ground and puts each plant on its spot. The numbers for
// the ground, path, hedges and light are the app's, from GardenGround.swift,
// GardenStructures.swift and PlotView.swift.

import { ROLES, YOUNG, decode, takeResult, link, attribute, multiply } from './plant.js';
import { castShadow } from './shadow.js';
import { areasBeside } from './beside.js';
import { raiseRill } from './water.js';
import { RIM_DEPTH, STRATA, hangSide, sideShaders } from './slab.js';

export const SIDE = 5.2;    // LongWalk.plotSide, and QuietGarden.plotSide
const PATH_HALF = 0.6;      // LongWalk.pathHalfWidth
const HEDGE_FROM = 2.3;     // LongWalk.hedgeFrom
// GardenGround.rimDepth, which the slab's side (`slab.js`) is hung from.
export { RIM_DEPTH };
export const HEDGE = { thickness: 0.36, tall: 2.0, low: 0.7 };

// **Sky under the plot, so the area below it has somewhere to be.** The window
// used to stop at the bottom of the rim and the plot sat in the middle of it,
// which left about a third of a metre of sky underneath — less than a slab
// shows, so the four wide pages with an area below them drew nothing there
// while their down key went somewhere (26 September).
//
// The headroom above could not pay for it: 2.3 m over the soil is a 2 m hedge
// and 30 cm, and taking any of it cuts the yew. So the window is this much
// taller instead and the plot rides at the top of it, which is 0.7 m of sky
// below and a plot drawn at 92% of the size it was. `ABOVE` moves with this —
// the two are the same number seen from either end, and if they part company
// the whole view stops being the view a look is held at.
const UNDER = 0.7;

export const COLOUR = {
  turf: [0.235, 0.265, 0.190],
  grass: [0.285, 0.320, 0.225],
  // The slab's strata, the app's, kept with the slab (`slab.js`).
  humus: STRATA.humus,
  earth: STRATA.earth,
  bedrock: STRATA.bedrock,
  yew: [0.27, 0.39, 0.27],
  // Oak left out: grey with the warmth still under it. Picked against the
  // yew beside it rather than against a swatch, the way the hedge's own
  // brightening was.
  timber: [0.44, 0.40, 0.345],
  // The Crossing's paving. Cooler than the timber and lighter than the
  // bedrock under the slab, so a roundel reads as laid stone rather than as
  // the plot's own rock showing through — picked against the grass it is
  // surrounded by, the way the timber was picked against the yew.
  stone: [0.345, 0.330, 0.302],
  // **Still water, which this garden had none of until 27 September**, though
  // `Archetype.lotus` has been a water lily since the shapes changed on the
  // 24th and was being sown in a drill. Two colours and not one, because water
  // is the only surface here that is darker where it is deeper: `shallows` at
  // the rim where the dish shows through, `depths` over the middle. Picked
  // against the turf around a pool rather than against a swatch, and kept
  // below it, because still water in daylight reads as a hole in the lawn and
  // not as a bright thing lying on it.
  shallows: [0.172, 0.200, 0.196],
  depths: [0.098, 0.126, 0.152],
  // The dish under the water: the plot's own earth, wetted. Darker and a shade
  // cooler than `humus`, which is what wet soil does.
  silt: [0.132, 0.112, 0.094],
  // The Orchard's trees, both picked against the grass and against the yew
  // rather than against a swatch.
  //
  // `leaf` is warmer and lighter than the yew because a fruit tree in leaf is
  // not a clipped hedge: the yew's blue-green is what a dense evergreen does
  // with light, and an orchard canopy is thinner, younger and yellower. It also
  // has to survive being the largest coloured area on the page — five canopies
  // cover more of a plot than anything else in this garden — so it sits a step
  // above the grass rather than a leap.
  leaf: [0.315, 0.400, 0.215],
  // `bark` is much darker than the bench's timber and browner than the
  // bedrock. A living trunk standing in its own canopy's shade is the darkest
  // thing on the slab, and drawing it at plank brightness made five pale posts.
  bark: [0.268, 0.222, 0.188],
  // The Knot Garden's ground. Picked against the grass the other four areas
  // stand on rather than against a swatch: it has to read as *not lawn* from
  // the first glance, because it is the only area whose floor is not green,
  // and it has to stay under the planting rather than glare out from between
  // it. Warm rather than neutral — a neutral pale grey under this sky's blue
  // ambient comes out lilac, which is the fault the Crossing's paving had on
  // its first pass.
  gravel: [0.470, 0.436, 0.376],
  // The Seedbed's ground. Fine tilth: soil raked down to a crumb, which is
  // neither the grass four areas stand on nor the Knot's gravel. Picked against
  // both — darker and browner than the gravel, because raked soil takes light
  // and gives little of it back, and warmer than the bedrock under the slab so
  // the bed does not read as the plot's own rock scraped bare. It also has to
  // stay under a part-sown drill without competing: most of this area is
  // ground, and ground that glares is a bed nobody looks into.
  tilth: [0.330, 0.268, 0.200],
  // The Knot Garden's hedging. Clipped box, not the walk's yew: box is a
  // fresher, yellower green, and at ankle height in full light it takes far
  // more of the sun than a 2 m yew wall does. Picked against the gravel it
  // stands in, which is the brightest ground in the garden — against that, the
  // yew read as a shadow rather than as a hedge.
  box: [0.288, 0.378, 0.226],
};

// Midday, GardenGround.swift. Read by the Coppice too, which lays a stool's
// shadow away from it, and by the stage, which lays every plant's and every
// hedge's shadow from it.
//
// **Re-tuned on 27 September 2026, when the shading became gamma-correct.**
// These are quantities of light now and add in linear space, where before
// they were multiplied into an sRGB colour — so the old numbers said
// something different and were chosen against a different curve. `sun` did
// not move: it is a direction, every shadow in the garden is laid from it,
// and it is the app's.
//
// A midday outdoors, as the numbers: the sun carries nearly all of it, the
// sky about an eighth and blue with it, and the ground throws back a warm
// twentieth. A face turned away from all three reads at about a third of one
// turned into them, which is the contrast a clear noon has.
export const LIGHT = {
  sun: [-0.3320, 0.8829, 0.3320],
  sunColour: [1.00, 0.96, 0.88],
  strength: 1.0,
  sky: [0.10, 0.13, 0.19],
  bounce: [0.080, 0.072, 0.055],
};

// The app's shading, shared by the ground and the plants so they sit in one light.
//
// **Gamma-correct since 27 September 2026.** Until then this multiplied an
// sRGB colour by the light and wrote the product straight out, which is
// wrong twice over: a texture's bytes are not a quantity of light, and light
// does not add in sRGB. The single-plant viewer had done it properly from
// the start (`plant.js`), so the garden and the page a visitor reaches from
// it disagreed about the same plant. Albedo is taken to linear on the way
// in, every light adds there, and the sum is encoded once on the way out.
//
// **`lightAt` is separate so a highlight can be added in the right space.**
// A specular is light, not albedo, so it belongs in the sum before the
// encode; a plant adds one (`PLANT_FRAGMENT`) and the ground does not.
//
// **The terminator is true Lambert again.** It used to be `pow(NdotL, 0.9)`,
// which lifts the shaded side — a fudge for the missing gamma, since without
// the encode everything below mid grey came out too dark. With the encode
// doing that job properly the exponent is 1 and the falloff is the physical
// one.
const SHADE = `
uniform vec3 sun, sunColour, sky, bounce;
uniform float strength;
vec3 lightAt(vec3 n) {
  float hemi = 0.5 + 0.5 * n.y;
  return sky * hemi + bounce * (1.0 - hemi) + max(dot(n, sun), 0.0) * strength * sunColour;
}
vec3 encode(vec3 linear) { return pow(max(linear, vec3(0.0)), vec3(1.0 / 2.2)); }
vec3 toLinear(vec3 srgb) { return pow(max(srgb, vec3(0.0)), vec3(2.2)); }
vec3 shade(vec3 albedo, vec3 n) {
  return encode(toLinear(albedo) * lightAt(n));
}`;

// `offset` is where the mesh stands: nowhere for a plot's own ground, which is
// built where it is drawn, and out past it for the slabs of the areas beside
// this one, which are one mesh apiece drawn wherever the turn and the window
// put them (`BESIDE`).
const GROUND_VERTEX = `#version 300 es
in vec3 position; in vec3 normal; in vec3 colour;
uniform mat4 viewProjection;
uniform vec3 offset;
out vec3 vNormal; out vec3 vColour;
void main() { vNormal = normal; vColour = colour; gl_Position = viewProjection * vec4(position + offset, 1.0); }`;

// `opacity` is 1 for everything but glass, which is drawn last and seen through.
// Premultiplied, because the canvas is. `upOnly` is for marking where shadows
// may fall (`draw`): only what faces up, which is ground and not the slab's
// sides.
const GROUND_FRAGMENT = `#version 300 es
precision highp float;
in vec3 vNormal; in vec3 vColour;
uniform float opacity;
uniform bool upOnly;
${SHADE}
out vec4 outColour;
void main() {
  if (upOnly && normalize(vNormal).y < 0.5) discard;
  outColour = vec4(shade(vColour, normalize(vNormal)) * opacity, opacity);
}`;

// **The slab's side has a program of its own** (`slab.js`), since 2 October
// 2026: its bands and the faint layers in them are worked out per pixel from
// where on the side a pixel is, which a colour per vertex could only carry on
// a mesh many times as fine. Lit by `SHADE`, as the ground is, and
// with the ground's `offset` and `opacity`, so a neighbour's side stands where
// its top does and is dimmed with it.
const SIDE_SHADERS = sideShaders(SHADE);

export const PLANT_VERTEX = `#version 300 es
in vec3 position; in vec3 normal; in vec2 uv; in float age;
uniform mat4 viewProjection;
uniform vec3 offset;
out vec3 vNormal; out vec2 vUV; out float vAge; out vec3 vWorld;
void main() {
  vNormal = normal; vUV = uv; vAge = age;
  vWorld = position + offset;
  gl_Position = viewProjection * vec4(position + offset, 1.0);
}`;

// **Every leaf on a plant samples one texture at the same coordinates**, so
// without this they come out identical to the pixel, which is most of why a
// web plant read as moulded rather than grown. `maturity` is the one channel
// SeedCore carries for exactly this, and the app has used it since it was
// written; the wasm buffer started sending it on 27 September 2026.
//
// `1 - age` so a brand new surface is fully tinted and a grown one is
// untouched, eased the app's way — tissue colours up quickly at first and
// then spends a long time finishing.
// **And the surface, since 27 September 2026.** A leaf drawn with one colour
// and one flat normal has a single uniform sheen wherever you look at it,
// which is what reads as moulded plastic; `PaletteRamp.relief` has described
// the veins standing proud of the blade, the quilting between them and the
// ribbing on a stem since it was written, and the app has lit plants by it
// all along. The bake is one texture: the tangent-space normal in red and
// green, the roughness in blue (`PlantBuffer.bakeRelief`).
//
// **The tangent frame is found per pixel** rather than carried on the mesh.
// A leaf's vertices have no tangents and adding them would be a third
// attribute and a change to every builder; the screen-space derivatives of
// the world position and the texture coordinate give the same frame for the
// cost of four subtractions, which is the standard cotangent trick. It is
// undefined on a degenerate triangle, so the frame falls back to the vertex
// normal when the derivatives vanish.
//
// **The highlight is small on purpose.** This garden lights flat, and the
// app learnt that taking roughness far down on the raised ground gave every
// ridge a specular hot enough to burn out the detail it was meant to show.
// What is wanted is a vein catching the light against matte tissue, not a
// wet leaf.
export const PLANT_FRAGMENT = `#version 300 es
precision highp float;
in vec3 vNormal; in vec2 vUV; in float vAge; in vec3 vWorld;
uniform sampler2D colour;
uniform sampler2D relief;
uniform vec4 young;
uniform vec3 look;
${SHADE}
out vec4 outColour;

vec3 bentBy(vec3 n, vec3 p, vec2 uv, vec3 tangentNormal) {
  vec3 dp1 = dFdx(p), dp2 = dFdy(p);
  vec2 duv1 = dFdx(uv), duv2 = dFdy(uv);
  vec3 across = cross(dp2, n), along = cross(n, dp1);
  vec3 t = across * duv1.x + along * duv2.x;
  vec3 b = across * duv1.y + along * duv2.y;
  float scale = max(dot(t, t), dot(b, b));
  if (scale <= 0.0) return n;
  float invmax = inversesqrt(scale);
  return normalize(mat3(t * invmax, b * invmax, n) * tangentNormal);
}

void main() {
  vec3 n = normalize(gl_FrontFacing ? vNormal : -vNormal);
  vec3 albedo = texture(colour, vUV).rgb;
  float fresh = 1.0 - clamp(vAge, 0.0, 1.0);
  fresh = fresh * fresh * (3.0 - 2.0 * fresh);
  albedo = mix(albedo, young.rgb, fresh * young.a);

  vec3 surface = texture(relief, vUV).rgb;
  vec2 slope = surface.rg * 2.0 - 1.0;
  vec3 lit = bentBy(n, vWorld, vUV, vec3(slope, sqrt(max(0.0, 1.0 - dot(slope, slope)))));

  // **Only the relief catches the light.** A highlight computed the same way
  // at every pixel lies evenly over a flat surface, and a large area of even
  // sheen is what reads as sheet metal — a water lily's pad is the worst
  // case in the garden, a broad flat disc facing a sun almost overhead.
  // Gating on how steeply the relief runs here puts the shine on the veins
  // and the ribs, where a real leaf carries it, and leaves the blade between
  // them matte.
  float ridge = clamp(length(slope) * 2.4, 0.0, 1.0);
  float gloss = 1.0 - surface.b;
  vec3 halfway = normalize(sun + look);
  float spec = pow(max(dot(lit, halfway), 0.0), mix(10.0, 90.0, gloss)) * gloss * gloss * 0.22 * ridge;
  // The highlight is light and adds where the other light adds, before the
  // encode. Added after it, it was a wash over the top rather than a sheen.
  outColour = vec4(encode(toLinear(albedo) * lightAt(lit) + spec * sunColour * strength), 1.0);
}`;

// **A shadow is a darkening, not a colour.** It is drawn over the ground
// already on the screen and multiplies it (`DST_COLOR, ZERO`), so gravel stays
// gravel and a path stays a path under it, only darker; painting a shadow
// colour would lay one flat tone over stones of a dozen. `loss` is how much of
// the ground's light it takes, worked out in `shadow.js`; `fade` lets a shadow
// kept to a pot's compost go to nothing before the rim.
const SHADOW_VERTEX = `#version 300 es
in vec3 position; in vec2 uv; in float fade;
uniform mat4 viewProjection;
out vec2 vUV; out float vFade;
void main() { vUV = uv; vFade = fade; gl_Position = viewProjection * vec4(position, 1.0); }`;

const SHADOW_FRAGMENT = `#version 300 es
precision highp float;
in vec2 vUV; in float vFade;
uniform sampler2D loss;
out vec4 outColour;
void main() { outColour = vec4(vec3(1.0 - texture(loss, vUV).r * vFade), 1.0); }`;

// **What a plant's shadow is, and a hedge's.** Not a shadow map — the page is
// one pass — but each one's own triangles laid on the ground from the sun's
// side, once, when it is added (`shadow.js` says how). A close look at the
// Knot Garden without them showed plants laid over the gravel rather than
// growing out of it, and box that floated.
//
// - `plant`: a plant's. Low parts blurred 2 cm and counted fully, parts over
//   40 cm blurred 7 cm and counted at half, so a flower head high on a spire is
//   a faint smudge well off to the side and the leaves at the foot are the
//   dark. Six in ten of the ground's light is left under a dense pile, at
//   most; two shadows overlapping multiply, and two together are still ground.
// - `hedge`: what a ground builder hands the stage as `casting` — the Knot's
//   box, the Cold Frame's boxes, the Seedbed's labels, the Quiet Garden's
//   hedge round and bench, the Long Walk's yew and low hedge. Solid, so
//   darker, and blurred less near its foot: clipped box has an edge. A 2 m
//   yew's shadow is a metre long, and its far edge — the shadow of the hedge's
//   top — wanders a fifth either way and is blurred wider, so it reads as
//   clipped yew and not as a ruled line; what of it falls past the plot falls
//   on nothing (`draw`).
// - `canopy`: an orchard tree's crown, handed back as `canopy`. A pool under
//   it, leaning away from the sun at half the slide, broken by dapple, and
//   light: eight tenths of the grass's light is left at its darkest.
// - `above` is how far a shadow floats over the surface it lies on, clear of
//   the highest dressing any ground lays over its floor (6 mm, the Cold
//   Frame's and the Glasshouse border's soil), so it never fights one.
const SHADOW = {
  plant: { cell: 0.012, most: 112, near: 0.02, far: 0.07, high: 0.4, faint: 0.5, layers: 1.1, darkest: 0.42 },
  hedge: { cell: 0.02, most: 1024, near: 0.015, far: 0.08, high: 0.6, faint: 0.8, layers: 1.6, darkest: 0.45, wander: 0.18 },
  canopy: { cell: 0.02, most: 1024, near: 0.06, far: 0.12, high: 1, faint: 1, layers: 1.2, darkest: 0.22, lean: 0.5,
    wander: 0.15, dapple: 0.75 },
  above: 0.01,
  // How far apart the points of the mesh a shadow is drawn on are, so it
  // follows a bed's shoulder or a hollow in the litter.
  step: 0.12,
};

// **The areas beside this one, out in the sky past the plot.** One slab per
// open neighbour on the map (`beside.js`), ground only: the wandering outline
// a plot has, the strata under it and that area's own colour, with nothing
// standing on it. A glimpse, so that a reader can see the garden goes on and
// which way, without leaving.
//
// **Where it stands is the screen's business and how it is held is the
// camera's**, and those are two different sentences. A slab goes out in the
// direction of the key that reaches it, because that is the promise the pad
// makes — what a reader sees on the left is what Left takes them to, whatever
// the plot's turn. It is drawn at the plot's own attitude, so it turns as the
// plot turns and reads as the same kind of thing in the same world.
//
// **A slab comes out from behind the plot, and does not float apart from
// it.** It was built the other way on 26 September — the same slabs standing
// clear in the sky with a hand's breadth of stars between — and Marcus's word
// for it was disjointed, which was right. Four separate objects hanging in
// the dark say four places exist; ground running out from under the plot's
// own edge says one garden. `lap` is how far behind the plot's near edge a
// slab's own edge sits, and it is why there is nothing to float: the plot,
// being nearer, hides that much of each of them.
//
// **Further off still has to be drawn, because this projection will not draw
// it.** Orthographic: nothing shrinks with distance, so a neighbour at a
// plot's size would be a second plot competing with the first. It is `scale`
// of one and at `dim` of its light — the ground shader's `opacity`, which the
// canvas carries through to the sky behind it, so half of what you see out
// there is sky. The two together are what say *over there*; either alone said
// *smaller* or *in shadow*. `scale` is 0.5 rather than the 0.35 the floating
// slabs used, because `lap` of it is behind the plot and only the rest shows.
//
// `depth` is how far behind the plot a slab stands, along the eye. On an
// orthographic projection that moves it nowhere on the screen. It is there so
// that wherever a slab and the plot meet the plot wins — which is what makes
// `lap` a lap and not an overlap — and so that a slab's own underside cannot
// come out in front of its top.
//
// `least` is how much of a slab must still show past the plot. A slab showing
// less than that, or reaching past the edge of the canvas, is not drawn.
//
// **Below a single plot the sky is there because it was asked for.** Fitted
// to the plot alone — 2.3 m of headroom over the soil, 0.95 of rim below, the
// plot in the middle — the canvas left about a third of a metre underneath,
// which is not enough to show a slab under it however far it laps. That is
// what `UNDER` buys, and a plot drawn at 92% of its old size is what it cost.
// Lapping further instead buys it back at full size, and Marcus was shown
// both: it turns the neighbour below into a dark band at the plot's near edge
// rather than a place, and he kept the sky (27 September).
//
// `closest` is the last zoom a slab is drawn at. Closer in than the whole
// plot a reader is looking at ground rather than at the horizon — and a slab
// is never drawn part off the canvas, because the edge of a canvas is a
// straight line and this garden has none of those.
const BESIDE = {
  scale: 0.5,
  dim: 0.5,
  depth: 14,
  lap: 1.7,
  least: 0.35,
  closest: 1.2,
  // How far a slab's underside can hang below `RIM_DEPTH`, for the box a
  // slab is placed by. It was the most the old floor's wander added. The
  // slab's lower edge (`slab.js`) comes less far down the screen than this
  // everywhere — 1.05 m and an eighth at the very most, less what the taper
  // lifts it by — so it is left as it was, and the neighbours stand where
  // Marcus last saw them.
  deepest: 1.22,
};

// Which way a direction lies on the screen: the axis — across, then up — and
// which end of it. **The screen's axes and not the plot's**, because the pad's
// are, and a slab that disagreed with the pad would be lying about where a key
// goes.
const BESIDE_WAY = { left: [0, -1], right: [0, 1], up: [1, 1], down: [1, -1] };

// **The stage is not the walk's.** Everything in it — the GL plumbing, the
// isometric camera, the quarter turns, the plant program — is what a plot is,
// and the Quiet Garden's page uses the same one with its own ground. The one
// thing an area supplies is how its ground is built. When a third area wants
// it, this belongs in a module of its own rather than in the first area that
// happened to need it.
export function makePlotStage(canvas, span, e, buildTheGround = buildGround) {
  // A stencil, for keeping shadows on the ground (`draw`).
  const gl = canvas.getContext('webgl2', { antialias: true, alpha: true, premultipliedAlpha: true, stencil: true });
  if (!gl) throw new Error('This browser has no WebGL2.');
  const ground = program(gl, GROUND_VERTEX, GROUND_FRAGMENT, ['position', 'normal', 'colour'], ['offset', 'opacity', 'upOnly']);
  const plantProgram = program(gl, PLANT_VERTEX, PLANT_FRAGMENT,
                               ['position', 'normal', 'uv', 'age'],
                               ['offset', 'colour', 'relief', 'young', 'look']);
  const shadowProgram = program(gl, SHADOW_VERTEX, SHADOW_FRAGMENT, ['position', 'uv', 'fade'], ['loss']);
  const sideProgram = program(gl, SIDE_SHADERS.vertex, SIDE_SHADERS.fragment,
                              ['position', 'normal', 'place', 'hang'], ['offset', 'opacity']);
  // **What a plant's shadow lies on.** An area whose floor is not level says
  // how high it is anywhere (`height`, on the builder it hands the stage), so
  // a shadow on a bed's shoulder or a hollow in the litter follows it rather
  // than going under it. An area with plants off the floor — in a pot, on a
  // stool — says how wide and how uneven what they stand in is (`seat`), and
  // their shadow is kept to it rather than hanging in the air past its edge.
  // An area with low structures hands back `casting` beside its ground mesh:
  // the triangles that throw a shadow on the floor, drawn as one (`hedges`).
  const floorAt = buildTheGround.height ?? (() => 0);
  const seat = buildTheGround.seat ?? { radius: 0.1, rise: 0.01 };

  const plants = [];
  let turn = 0;
  let groundMesh = null;
  // The slab's side under it, which every ground builder hands back as `side`
  // (`hangSide`) and which is drawn by its own program.
  let sideMesh = null;
  // **Glass, for the one area that has any.** A ground builder may hand back a
  // `glass` mesh beside its own, and it is drawn after the plants, blended and
  // without writing depth, so what stands under it shows through. The Cold
  // Frame's lights are the first thing in the garden a reader has to see
  // through; every other area returns no glass and draws exactly as it did.
  let glassMesh = null;
  let glassOpacity = 1;
  // The shadow the ground's own structures throw, if it hands any back.
  let hedges = null;
  // The slabs of the areas beside this one, if the page has said where it
  // stands (`beside`). One mesh apiece, built once: a turn moves them about
  // the screen but does not change their shape, and a page that rebuilt three
  // slabs on every quarter turn would have made turning cost four times what
  // it costs.
  let besides = [];
  // The last frame's view and projection together, which `pick` reads.
  let drawn = null;

  // **How close, and where.** `zoom` is how many times closer than the whole
  // plot, which is 1 and is the view every area page opened on before it could
  // be zoomed. `x` and `y` are how far the middle of the window has moved from
  // the middle of that whole view, in metres across the screen — the viewer's
  // frame, not the plot's, so right is right whichever way the plot is turned.
  // `movepad.js` is what moves them; this only keeps them over the plot.
  const look = { zoom: 1, x: 0, y: 0 };
  let aspect = 1;

  // The camera looks down (1, 1, 1), turned in quarter turns about the plot.
  function eye() {
    const angle = turn * Math.PI / 2;
    const c = Math.cos(angle), s = Math.sin(angle);
    return [c + s, 1, -s + c].map((v) => v / Math.sqrt(3));
  }

  function rebuildGround() {
    if (groundMesh) groundMesh.release();
    // The tall hedge goes on whichever side is further from the viewer.
    const farSide = eye()[0] > 0 ? -1 : 1;
    // The eye as well, because an area with a hedge on all four sides needs to
    // know which two of them are the near ones and a single sign cannot say.
    const built = buildTheGround(farSide, span, e, eye());
    groundMesh = withPieces(gl, ground, upload(gl, ground, built), built.pieces, 'opaque');
    if (sideMesh) sideMesh.release();
    sideMesh = built.side ? uploadSide(gl, sideProgram, built.side) : null;
    if (glassMesh) glassMesh.release();
    glassMesh = built.glass ? withPieces(gl, ground, upload(gl, ground, built.glass), built.pieces, 'glass') : null;
    glassOpacity = built.glass?.opacity ?? 1;
    // **The hedges' shadow is built again with the ground**, because a turn
    // can move the Long Walk's tall yew to the other side. Laid over the
    // stage's whole ground and clipped to it: a 2 m wall's shadow is a metre
    // long, and what falls past the plot's edge falls on nothing.
    if (hedges) releaseShadow(hedges);
    hedges = null;
    const casts = [[built.casting, SHADOW.hedge], [built.canopy, SHADOW.canopy]]
      .filter(([c]) => c?.length)
      .map(([c, look]) => castShadow((visit) => {
        for (let i = 0; i < c.length; i += 9) visit(c[i], c[i + 1], c[i + 2], c[i + 3], c[i + 4], c[i + 5], c[i + 6], c[i + 7], c[i + 8]);
      }, { ...look, sun: LIGHT.sun, rect: [-extent.x, -extent.z, extent.x, extent.z] }));
    if (casts.length) {
      // Two over one grid — the Orchard's trunks and its crowns — are one
      // texture: the light each leaves, multiplied.
      const [first, ...rest] = casts;
      for (const other of rest) {
        for (let k = 0; k < first.loss.length; k++) {
          first.loss[k] = Math.round(255 - (255 - first.loss[k]) * (255 - other.loss[k]) / 255);
        }
      }
      hedges = layShadow(first, 0, 0, (px, pz) => floorAt(px, pz) + SHADOW.above);
    }
  }

  function draw() {
    const ratio = window.devicePixelRatio || 1;
    const width = Math.round(canvas.clientWidth * ratio), height = Math.round(canvas.clientHeight * ratio);
    if (canvas.width !== width || canvas.height !== height) { canvas.width = width; canvas.height = height; }
    gl.viewport(0, 0, width, height);
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.enable(gl.DEPTH_TEST);
    gl.disable(gl.CULL_FACE);

    aspect = width / height || 1;
    const view = lookAlong(eye());
    const all = frame(view, aspect, span);
    // A window made smaller can leave the look too close, or off the plot.
    Object.assign(look, hold(look, all));
    const projection = ortho(all.cx + look.x, all.cy + look.y, all.w / look.zoom, all.h / look.zoom);
    const viewProjection = multiply(projection, view);
    // Kept for `pick`, which has to find a plant where it was last drawn.
    drawn = viewProjection;

    for (const [p, extra] of [[ground, null], [sideProgram, null], [plantProgram, null]]) {
      gl.useProgram(p.program);
      gl.uniformMatrix4fv(p.at.viewProjection, false, viewProjection);
      gl.uniform3fv(p.at.sun, LIGHT.sun);
      gl.uniform3fv(p.at.sunColour, LIGHT.sunColour);
      gl.uniform3fv(p.at.sky, LIGHT.sky);
      gl.uniform3fv(p.at.bounce, LIGHT.bounce);
      gl.uniform1f(p.at.strength, LIGHT.strength);
    }

    gl.useProgram(ground.program);
    gl.uniform1i(ground.at.upOnly, 0);
    // The areas beside this one, out past the plot and behind it. Before the
    // plot, dimmed, and depth-tested like everything else — the plot is drawn
    // over whatever it covers, which is how a nearer slab behaves.
    drawBeside(view, all);
    gl.uniform1f(ground.at.opacity, 1);
    gl.uniform3fv(ground.at.offset, HERE);
    groundMesh.draw();
    if (sideMesh) {
      gl.useProgram(sideProgram.program);
      gl.uniform1f(sideProgram.at.opacity, 1);
      gl.uniform3fv(sideProgram.at.offset, HERE);
      sideMesh.draw();
      gl.useProgram(ground.program);
    }

    // **Where a shadow may fall: on ground, seen.** The ground is drawn once
    // more into the stencil only, keeping just what faces up, so a shadow
    // reaching past the plot's wandering edge is not laid down the slab's side
    // or out over the sky, and one under a hedge is not laid on its flank.
    gl.clear(gl.STENCIL_BUFFER_BIT);
    gl.enable(gl.STENCIL_TEST);
    gl.stencilFunc(gl.ALWAYS, 1, 0xff);
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.REPLACE);
    gl.colorMask(false, false, false, false);
    gl.depthMask(false);
    gl.depthFunc(gl.LEQUAL);
    gl.uniform1i(ground.at.upOnly, 1);
    groundMesh.draw();
    gl.uniform1i(ground.at.upOnly, 0);
    gl.depthFunc(gl.LESS);
    gl.colorMask(true, true, true, true);

    // The shadows, after the ground they darken and before the plants that
    // stand in them. Depth-tested, so a hedge or a pot in front of one keeps
    // it; not depth-written, so they do not hide each other or anything after.
    gl.stencilFunc(gl.EQUAL, 1, 0xff);
    gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
    gl.useProgram(shadowProgram.program);
    gl.uniformMatrix4fv(shadowProgram.at.viewProjection, false, viewProjection);
    gl.uniform1i(shadowProgram.at.loss, 0);
    gl.activeTexture(gl.TEXTURE0);
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.DST_COLOR, gl.ZERO);
    for (const shadow of [hedges, ...plants.map((plant) => plant.shadow)]) {
      if (!shadow) continue;
      gl.bindTexture(gl.TEXTURE_2D, shadow.texture);
      gl.bindVertexArray(shadow.vao);
      gl.drawElements(gl.TRIANGLES, shadow.count, gl.UNSIGNED_SHORT, 0);
    }
    gl.depthMask(true);
    gl.disable(gl.BLEND);
    gl.disable(gl.STENCIL_TEST);

    gl.useProgram(plantProgram.program);
    gl.uniform1i(plantProgram.at.colour, 0);
    gl.uniform1i(plantProgram.at.relief, 1);
    // Where the eye is, for the highlight. The projection is orthographic, so
    // this is one direction for the whole plot rather than a vector per pixel.
    gl.uniform3fv(plantProgram.at.look, eye());
    for (const plant of plants) {
      gl.uniform3fv(plantProgram.at.offset, [plant.x, plant.lift, plant.z]);
      for (const part of plant.parts) {
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, plant.textures[part.role]);
        gl.activeTexture(gl.TEXTURE1);
        gl.bindTexture(gl.TEXTURE_2D, plant.relief[part.role]);
        // What a young one of this part is coloured toward. Set per part
        // rather than per plant: a bud's petals and the leaves under them
        // are different ages and go different ways.
        gl.uniform4fv(plantProgram.at.young, YOUNG[ROLES[part.role]] ?? [0, 0, 0, 0]);
        gl.bindVertexArray(part.vao);
        gl.drawElements(gl.TRIANGLES, part.count, gl.UNSIGNED_INT, 0);
      }
    }
    gl.bindVertexArray(null);

    if (glassMesh) {
      gl.useProgram(ground.program);
      gl.uniform1f(ground.at.opacity, glassOpacity);
      gl.enable(gl.BLEND);
      gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
      gl.depthMask(false);
      glassMesh.draw();
      gl.depthMask(true);
      gl.disable(gl.BLEND);
    }
  }

  // **Where the slabs beside the plot stand, and whether each is drawn.**
  //
  // In metres across the screen and up it, the window's own frame and the one
  // `frame` answers in, turned into a place in the world at the very end:
  // on an orthographic projection an offset along the view's own axes lands
  // exactly where it was asked to. The across axis is level, so a slab sent
  // left or right stays on the plot's own ground plane; one sent up or down is
  // lifted clear of it, which is a thing this projection cannot show and so
  // does not have to be paid for.
  //
  // Where it goes is measured off the plot and not off the window, so it holds
  // its place against the plot's edge as a reader comes closer rather than
  // sliding about the screen with the zoom. What that costs is that one can
  // fall off the edge of the canvas on the way in, and then it is not drawn.
  function drawBeside(view, all) {
    if (!besides.length || look.zoom > BESIDE.closest) return;
    const plot = corners(view, extent.x, extent.z, -RIM_DEPTH * BESIDE.deepest, 0);
    const half = (SIDE * BESIDE.scale) / 2;
    const box = spread(corners(view, half, half, -RIM_DEPTH * BESIDE.deepest * BESIDE.scale, 0));
    const size = [[box.minX, box.maxX], [box.minY, box.maxY]];
    const wide = all.w / look.zoom / 2, tall = all.h / look.zoom / 2;
    const pane = [[all.cx + look.x - wide, all.cx + look.x + wide],
                  [all.cy + look.y - tall, all.cy + look.y + tall]];
    const { x: across, y: up, z: back } = axes(view);

    const placed = [];
    for (const slab of besides) {
      const [axis, sign] = BESIDE_WAY[slab.direction];
      const [low, high] = size[axis];
      const [near, far] = sign > 0 ? [low, high] : [high, low];
      // How far the plot comes this way, over the band of screen the slab
      // stands in rather than corner to corner (`reachOver`).
      const band = reachOver(plot, 1 - axis, size[1 - axis][0], size[1 - axis][1]);
      const reach = sign > 0 ? band.max : band.min;
      const at = [0, 0];
      // **Its near edge sits `lap` inside the plot's**, and the plot, being
      // nearer, hides that much of it. There is no sky to share out and no
      // distance to choose — except that the canvas can insist: a slab goes as
      // far out as there is room for and no further out than `lap` says, so on
      // a phone, where a plot fills all but a few per cent of the width, the
      // ones to the side lap further and show a wedge rather than nothing.
      at[axis] = reach - sign * BESIDE.lap - near;
      const most = pane[axis][sign > 0 ? 1 : 0] - far;
      if (sign * (at[axis] - most) > 0) at[axis] = most;
      // **And enough of it must still come out the other side.** A slab and
      // the plot are the same shape at the same attitude, so their edges on
      // the screen are parallel and what shows past the plot is a strip of one
      // width all along — which makes this a straight subtraction, the slab's
      // own reach less the lap, and constant for a given direction. It can
      // still fail: a slab is shorter across the screen than up it on this
      // projection, so a lap that leaves a margin sideways can swallow one
      // whole going up.
      if (sign * (at[axis] + far - reach) < BESIDE.least) continue;
      // **Whole on the canvas, on both axes, or not drawn at all** — because
      // the edge of a canvas is a straight line and this garden has none of
      // those. With nothing to spare: the line above has already pulled it in
      // as far as it will go, and a margin on top of that would refuse the
      // slab below the plot the sky `UNDER` was bought for.
      // **And then it stands on its own terrace.** The garden falls along the
      // map's long axis, so a neighbour to one side is up a step and the other
      // down one. A rise is world height, and this projection sends world
      // height straight up the screen and nowhere else — the across axis is
      // level — so adding it to the screen offset is the same picture as
      // lifting the slab, and it keeps every test below honest about where the
      // slab actually ends up. Only the sides are ever off the level: up and
      // down lead to the other row of the same column, which is level ground.
      at[1] += slab.rise * up[1];
      if (at[axis] + low < pane[axis][0] || at[axis] + high > pane[axis][1]) continue;
      if (at[1 - axis] + size[1 - axis][0] < pane[1 - axis][0]
          || at[1 - axis] + size[1 - axis][1] > pane[1 - axis][1]) continue;
      placed.push([slab, [0, 1, 2].map((i) => at[0] * across[i] + at[1] * up[i] - BESIDE.depth * back[i])]);
    }
    // Each slab's top with the ground's program and then each one's side with
    // the side's, so the page changes program twice and not twice a slab.
    gl.uniform1f(ground.at.opacity, BESIDE.dim);
    for (const [slab, offset] of placed) {
      gl.uniform3fv(ground.at.offset, offset);
      slab.mesh.draw();
    }
    gl.useProgram(sideProgram.program);
    gl.uniform1f(sideProgram.at.opacity, BESIDE.dim);
    for (const [slab, offset] of placed) {
      gl.uniform3fv(sideProgram.at.offset, offset);
      slab.side.draw();
    }
    gl.useProgram(ground.program);
  }

  // **Where this page stands on the map**, which is the one thing about the
  // garden the stage cannot work out for itself. The page says it, as it says
  // it to the bar, to the minimap and to the pad, and everything the slabs
  // beside the plot are follows from that word (`beside.js`).
  //
  // Built here and once. A turn moves them about the screen and does not
  // change them, so nothing is rebuilt on a turn.
  function beside(theme) {
    for (const slab of besides) { slab.mesh.release(); slab.side.release(); }
    besides = areasBeside(theme).map((area) => {
      const built = besideGround(e, area.seed, area.ground);
      return {
        direction: area.direction,
        // The terrace, at the slab's own size: a neighbour drawn half a plot
        // across stands half a step higher, or the ground would disagree with
        // itself about how far away it is.
        rise: area.rise * BESIDE.scale,
        mesh: upload(gl, ground, built),
        side: uploadSide(gl, sideProgram, built.side),
      };
    });
    draw();
  }

  // `lift` is how far off the ground the plant stands: nothing, everywhere but
  // the Glasshouse, whose staging stands its pots 0.83 m off the floor.
  //
  // `who` is what the plot service said about the plant — its seed, its
  // parents, its meeting and its plot — kept beside the mesh so a tap on it can
  // be answered with its name (`plantpanel.js`). A stage filled by a workbench's
  // invented plants passes none, and those plants cannot be picked.
  function add(x, z, grown, lift = 0, who = null) {
    const textures = {};
    for (const role of ROLES) {
      const t = grown.textures[role];
      const texture = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, t.side, t.side, 0, gl.RGBA, gl.UNSIGNED_BYTE, t.pixels);
      gl.generateMipmap(gl.TEXTURE_2D);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      textures[role] = texture;
    }
    // **And the surface beside the colour**: the normal in red and green
    // and the roughness in blue, sampled at the same coordinates, so a
    // vein is lit where it is drawn (`PlantBuffer.bakeRelief`).
    const relief = {};
    for (const role of ROLES) {
      const t = grown.relief[role];
      const texture = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, t.side, t.side, 0, gl.RGBA, gl.UNSIGNED_BYTE, t.pixels);
      gl.generateMipmap(gl.TEXTURE_2D);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      relief[role] = texture;
    }
    const parts = grown.parts.map((part) => {
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
    // How tall and how wide it stands, from the grown mesh's bounds, for
    // `pick`: a tap anywhere on a spire should find the spire.
    const height = Math.max(0, grown.max?.[1] ?? 0);
    const reach = Math.max(0.05, ...[0, 2].flatMap((i) => [Math.abs(grown.min?.[i] ?? 0), Math.abs(grown.max?.[i] ?? 0)]));
    plants.push({ x, z, lift, parts, textures, relief, who, height, reach, shadow: shadowUnder(x, z, lift, grown) });
  }

  // **The shadow under a plant**, from its own triangles (`shadow.js`), built
  // once when it is added. It falls away from the sun as the sun is in the
  // world's frame, so it turns with the plot.
  //
  // **A plant off the floor shadows what it stands in**: the compost in its pot
  // or the cut face of its stool, kept inside it and faded out before its rim,
  // so none of it hangs in the air past the pot. The Coppice's stool already
  // throws its own shadow on the litter, so a fern on one is not given a second
  // there — the two would stack into a hole under every stool.
  function shadowUnder(x, z, lift, grown) {
    const cast = castShadow((visit) => {
      for (const { positions: p, indices } of grown.parts) {
        for (let t = 0; t < indices.length; t += 3) {
          const a = indices[t] * 3, b = indices[t + 1] * 3, c = indices[t + 2] * 3;
          visit(p[a], p[a + 1], p[a + 2], p[b], p[b + 1], p[b + 2], p[c], p[c + 1], p[c + 2]);
        }
      }
    }, { ...SHADOW.plant, sun: LIGHT.sun });
    if (!cast) return null;
    const seated = lift > floorAt(x, z) + 0.02;
    return seated
      ? layShadow(cast, x, z, () => lift + seat.rise, seat.radius)
      : layShadow(cast, x, z, (px, pz) => floorAt(px, pz) + SHADOW.above);
  }

  // **Laying a shadow on the ground**: its loss as a texture, and a mesh to
  // draw it on — a sheet over its grid, a point every `step`, each at `surface`
  // where it is, so it follows the ground; or, `within` a pot or a stool, a
  // disc of that radius round the foot, faded to nothing at its rim.
  function layShadow({ x0, z0, cell, w, h, loss }, dx, dz, surface, within = 0) {
    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.R8, w, h, 0, gl.RED, gl.UNSIGNED_BYTE, loss);
    gl.pixelStorei(gl.UNPACK_ALIGNMENT, 4);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    const positions = [], uvs = [], fades = [], indices = [];
    const point = (lx, lz, fade) => {
      positions.push(dx + lx, surface(dx + lx, dz + lz), dz + lz);
      uvs.push((lx - x0) / (w * cell), (lz - z0) / (h * cell));
      fades.push(fade);
    };
    if (within > 0) {
      // Faded from a third of the way out, and its rim wandering by the
      // plant's place, so the edge of a pot's shadow is not a ring drawn on
      // the compost.
      const around = 24, shares = [0.2, 0.4, 0.6, 0.8, 1];
      const key = Math.round(dx * 997) * 7919 + Math.round(dz * 991) * 104729;
      const phase = [1, 2, 3].map((k) => hash(key + k * 0.37) * Math.PI * 2);
      point(0, 0, 1);
      for (const share of shares) {
        const t0 = Math.min(1, Math.max(0, (share - 0.35) / 0.65));
        const fade = 1 - t0 * t0 * (3 - 2 * t0);
        for (let a = 0; a < around; a++) {
          const t = (a / around) * Math.PI * 2;
          const r = within * share * (1 - 0.1 * (1 + 0.6 * Math.sin(2 * t + phase[0])
            + 0.3 * Math.sin(3 * t + phase[1]) + 0.2 * Math.sin(5 * t + phase[2])) / 2.1);
          point(Math.cos(t) * r, Math.sin(t) * r, fade);
        }
      }
      for (let a = 0; a < around; a++) indices.push(0, 1 + a, 1 + (a + 1) % around);
      for (let r = 0; r < shares.length - 1; r++) {
        for (let a = 0; a < around; a++) {
          const i = 1 + r * around + a, j = 1 + r * around + (a + 1) % around;
          indices.push(i, i + around, j, j, i + around, j + around);
        }
      }
    } else {
      const across = Math.max(2, Math.ceil((w * cell) / SHADOW.step));
      const along = Math.max(2, Math.ceil((h * cell) / SHADOW.step));
      for (let j = 0; j <= along; j++) {
        for (let i = 0; i <= across; i++) point(x0 + (w * cell * i) / across, z0 + (h * cell * j) / along, 1);
      }
      for (let j = 0; j < along; j++) {
        for (let i = 0; i < across; i++) {
          const k = j * (across + 1) + i;
          indices.push(k, k + across + 1, k + 1, k + 1, k + across + 1, k + across + 2);
        }
      }
    }
    const vao = gl.createVertexArray();
    gl.bindVertexArray(vao);
    const buffers = [
      attribute(gl, shadowProgram.at.position, new Float32Array(positions), 3),
      attribute(gl, shadowProgram.at.uv, new Float32Array(uvs), 2),
      attribute(gl, shadowProgram.at.fade, new Float32Array(fades), 1),
    ];
    const indexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(indices), gl.STATIC_DRAW);
    buffers.push(indexBuffer);
    gl.bindVertexArray(null);
    return { vao, buffers, texture, count: indices.length };
  }

  function releaseShadow(shadow) {
    shadow.buffers.forEach((b) => gl.deleteBuffer(b));
    gl.deleteVertexArray(shadow.vao);
    gl.deleteTexture(shadow.texture);
  }

  // **Adding a plant does not draw the walk.** It used to, and that made
  // filling a plot quadratic: every plant redrew every plant already standing,
  // so three full plots were a hundred and forty scene renders of up to a
  // hundred and forty plants each. The work is all on the GPU, so it does not
  // show up as time spent in `add` — it shows up as the frame the grower waits
  // for afterwards taking a second and a half.
  //
  // Whoever is filling the stage says when to draw, which is once a batch.
  // `clear` and `turnBy` still draw on their own, because they are one
  // change each and the answer has to be on screen when they return.

  // Takes every plant off the stage, for moving along the walk.
  function clear() {
    for (const plant of plants) {
      for (const part of plant.parts) { part.buffers.forEach((b) => gl.deleteBuffer(b)); gl.deleteVertexArray(part.vao); }
      Object.values(plant.textures).forEach((t) => gl.deleteTexture(t));
      if (plant.shadow) releaseShadow(plant.shadow);
    }
    plants.length = 0;
    draw();
  }

  // **A turn goes round what you are looking at**, not round the middle of the
  // plot. Close in on one plant and turn, and it is the same plant in the
  // middle of the window from its other side — found by taking the point of
  // ground under the middle of the window before the turn and putting it back
  // there after. From the whole view nothing has moved, so nothing changes.
  function turnBy(quarters) {
    const kept = underMiddle(look);
    turn = (turn + quarters + 4) % 4;
    rebuildGround();
    Object.assign(look, over(kept, look.zoom));
    draw();
  }

  // How far the plots on this stage run each way from its middle, on the
  // ground: a plot's half-width across, and along, as many plots as the stage
  // holds. A `span` past a whole number is margin — the Quiet Garden's 1.25 —
  // and not ground.
  const extent = { x: SIDE / 2, z: (SIDE * Math.max(1, Math.floor(span))) / 2 };

  // The point under the middle of a look, `ABOVE` the soil.
  function underMiddle({ x: px, y: py }) {
    const view = lookAlong(eye());
    const whole = frame(view, aspect, span);
    const { x, y, z } = axes(view);
    const vx = whole.cx + px, vy = whole.cy + py;
    const t = (ABOVE - vx * x[1] - vy * y[1]) / z[1];
    return [0, 1, 2].map((i) => vx * x[i] + vy * y[i] + t * z[i]);
  }

  // The look `zoom` times closer with `point` in the middle of it.
  function over(point, zoom) {
    const view = lookAlong(eye());
    const whole = frame(view, aspect, span);
    const { x, y } = axes(view);
    return { zoom, x: dot3(point, x) - whole.cx, y: dot3(point, y) - whole.cy };
  }

  // **Where a look may be: over the plot.** The point under the middle of the
  // window stays on the plot's own ground, so however close the look and
  // wherever it has been moved, there is a plant in the middle of it rather
  // than a corner of empty sky — which is what keeping the window inside the
  // drawing's box on the screen gave, because an isometric plot is a diamond
  // in that box, not the box.
  //
  // The ground it may range over grows with the zoom, from the one point in
  // the middle at the whole view — so that the whole view is exactly the one
  // every area page had before it could be zoomed — to nearly all of the plot
  // at the closest. A direction pressed against an edge runs along it, the way
  // a hand on a wall follows it.
  function hold({ zoom, x, y }, all) {
    const nearest = Math.min(Math.max(zoom, 1), closest(all));
    const point = underMiddle({ x, y });
    const room = 1 - 1 / nearest;
    point[0] = Math.min(Math.max(point[0], -extent.x * room), extent.x * room);
    point[2] = Math.min(Math.max(point[2], -extent.z * room), extent.z * room);
    return over(point, nearest);
  }

  const whole = () => frame(lookAlong(eye()), aspect, span);

  // A look kept to where a look may be, without drawing it — for `movepad.js`,
  // which asks where a key would go before deciding what the key does.
  function held(wanted) {
    return hold({ ...look, ...wanted }, whole());
  }

  // Where the look is, how close it can come, and how many metres across the
  // screen a pixel of the canvas is at `zoom`, for a drag or a pinch.
  function view(zoom = look.zoom) {
    const all = whole();
    const most = closest(all);
    return {
      ...look,
      closest: most,
      metresPerPixel: all.w / Math.min(Math.max(zoom, 1), most) / (canvas.clientWidth || 1),
    };
  }

  // Moves the look, kept to where a look may be, and draws. Answers where it
  // ended up, which is not always where it was asked to go.
  function lookAt(wanted) {
    Object.assign(look, held(wanted));
    draw();
    return { ...look };
  }

  // The look on the plot `along` plots further down the line (-1 is back),
  // arrived at from this one: the same point of ground carried across the seam
  // between them, so a look that leaves by one plot's edge comes in by the
  // next one's facing edge, as close as it was.
  function carried(wanted, along) {
    const point = underMiddle({ ...look, ...wanted });
    point[2] -= along * 2 * extent.z;
    return hold(over(point, wanted.zoom ?? look.zoom), whole());
  }

  // Whether a look is at the seam with the plot before this one (`back`) or
  // after it (`on`): the point under its middle as far along the plot as a
  // look that close may go. At the whole view it is at both, because it may go
  // nowhere.
  function seams(wanted) {
    const at = held(wanted);
    const room = 1 - 1 / at.zoom;
    const z = underMiddle(at)[2];
    const give = 1e-3 + extent.z * room * 1e-3;
    return { back: z <= -extent.z * room + give, on: z >= extent.z * room - give };
  }

  // Where a direction on the ground is on the screen, in the viewer's frame,
  // x to the right and y up — how `movepad.js` knows which side of the screen
  // the next plot along is on after a turn.
  function onScreen(direction) {
    const { x, y } = axes(lookAlong(eye()));
    return [dot3(direction, x), dot3(direction, y)];
  }

  // Builds the ground again without turning, for an area whose ground depends
  // on which plot is showing: the Glasshouse draws a pot under each potted
  // plant, and a plot with eleven pots on its staging is not one with twenty.
  function rebuild() {
    rebuildGround();
    draw();
  }

  // MARK: Which plant

  // Where a point in the world was last drawn, in CSS pixels from the
  // canvas's top-left corner.
  function toScreen([x, y, z]) {
    const m = drawn;
    const cx = m[0] * x + m[4] * y + m[8] * z + m[12];
    const cy = m[1] * x + m[5] * y + m[9] * z + m[13];
    return [(cx + 1) / 2 * canvas.clientWidth, (1 - cy) / 2 * canvas.clientHeight];
  }

  // **The plant under a tap**: the one whose stem, drawn from its foot to its
  // top as it stands on the screen, passes nearest the point, if that is near
  // enough. Near enough is a fingertip plus the plant's own half-width at this
  // zoom, so a close look at one broad plant takes a tap anywhere on it, and a
  // whole plot of small ones takes one near the one meant. Two plants the same
  // distance away go to the one in front. Only plants the service named can be
  // picked. `px` and `py` are CSS pixels from the canvas's top-left; with no
  // `slop` the nearest plant is answered however far away it is, which is what
  // the keyboard asks for.
  function pick(px, py, slop = null) {
    if (!drawn) return null;
    const perMetre = 1 / view().metresPerPixel;
    const facing = eye();
    let best = null, bestGap = Infinity, bestDepth = -Infinity;
    for (const plant of plants) {
      if (!plant.who) continue;
      const foot = toScreen([plant.x, plant.lift, plant.z]);
      const top = toScreen([plant.x, plant.lift + plant.height, plant.z]);
      const gap = Math.max(0, segmentGap(px, py, foot, top) - (slop === null ? 0 : plant.reach * perMetre));
      if (slop !== null && gap > slop) continue;
      const depth = dot3([plant.x, plant.lift, plant.z], facing);
      if (gap < bestGap - 0.5 || (Math.abs(gap - bestGap) <= 0.5 && depth > bestDepth)) {
        best = plant; bestGap = gap; bestDepth = depth;
      }
    }
    return best && { ...best.who, at: [best.x, best.lift + best.height / 2, best.z], height: best.height };
  }

  // The plants the service named, for finding one by its seed.
  function named() {
    return plants.filter((plant) => plant.who)
      .map((plant) => ({ ...plant.who, at: [plant.x, plant.lift + plant.height / 2, plant.z], height: plant.height }));
  }

  // The look `zoom` times closer with `point` in the middle of it, kept to
  // where a look may be — for going to a plant.
  function toward(point, zoom) {
    return hold(over(point, zoom), whole());
  }

  rebuildGround();
  new ResizeObserver(draw).observe(canvas);
  // `turn` is read by the sky, which has to face the way the camera does.
  return { add, clear, turnBy, draw, rebuild, beside, turn: () => turn, view, held, lookAt, carried, seams,
           onScreen, pick, named, toward, toScreen };
}

// Plants arrivals by the rule until there are `total`, reporting as it goes.
export async function plantArrivals(e, total, report) {
  let arrived = 0;
  let since = performance.now();
  while (arrived < total) {
    e.pg_walk_arrive();
    arrived += 1;
    if (performance.now() - since > SLICE) { report(`Planting by the rule: ${arrived} of ${total} arrived`); await breathe(); since = performance.now(); }
  }
  return e.pg_walk_plots();
}

// A plot's plantings, as the rule placed them: slot and traits.
export function describe(e, plot) {
  const length = e.pg_walk_describe(plot);
  return JSON.parse(new TextDecoder().decode(takeResult(e, length)));
}

// Grows `span` plots from `first`, laid end to end down the walk, one plant at a time.
export async function growPlots(e, stage, first, span, report) {
  stage.clear();
  let since = performance.now();
  for (let k = 0; k < span; k++) {
    const plot = first + k;
    const along = (k - (span - 1) / 2) * SIDE;
    const count = e.pg_walk_count(plot);
    for (let i = 0; i < count; i++) {
      const length = e.pg_walk_grow(plot, i);
      const buffer = takeResult(e, length);
      const spot = new Float32Array(buffer.slice(0, 8));
      stage.add(spot[0], spot[1] + along, decode(buffer.slice(8)));
      if (performance.now() - since > SLICE) {
        report(`Growing plot ${plot + 1}: ${i + 1} of ${count}`);
        stage.draw();
        await breathe();
        since = performance.now();
      }
    }
  }
  stage.draw();
}

// Grows `span` plots from the plot service, as a visitor's page will: the
// service says what is planted where, with each plant's lineage, and the
// module grows each plant from that lineage — or, for the one plant with no
// lineage, from its seed.
export async function growFromService(e, stage, first, span, report) {
  stage.clear();
  const plots = [];
  let since = performance.now();
  for (let k = 0; k < span; k++) {
    const plot = first + k;
    const { plantings } = await (await fetch(`/api/walk/plot/${plot}`)).json();
    plots.push(plantings.length);
    const along = (k - (span - 1) / 2) * SIDE;
    for (const [i, p] of plantings.entries()) {
      // **Two plants grow two ways.** Nearly everything down here is a hybrid,
      // and a hybrid's traits come from its parents, so it is grown from its
      // whole lineage. The one plant that is not is the ambassador standing at
      // the head of plot 0: it was minted, so it has no parents and no meeting,
      // and it grows from its seed alone. The service says which by sending an
      // empty `parents`.
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
      stage.add(p.spot[0], p.spot[1] + along, decode(takeResult(e, length)), 0, { ...p, plot });
      // A batch of four, then one draw and one frame: the walk fills in in
      // handfuls, which is what a growing garden should look like, and the
      // page stays answerable to a finger throughout.
      if (performance.now() - since > SLICE) {
        report(`Growing plot ${plot + 1}: ${i + 1} of ${plantings.length}`);
        stage.draw();
        await breathe();
        since = performance.now();
      }
    }
  }
  stage.draw();
  return plots;
}

// **Letting go of the thread, without waiting for a frame to come round.**
//
// These loops used to pause on `requestAnimationFrame`, on the reasoning that
// a frame is how often there is any point drawing. That is true when frames
// arrive sixty times a second and false the moment they do not: a tab the
// compositor has decided is not worth painting gets one frame a second, and a
// walk that pauses thirty-five times then takes thirty-five seconds to grow
// while the work in it adds up to two. It is not a rare case — a background
// tab, a hidden pane, a phone with the screen off mid-load — and there is no
// warning, because nothing is wrong: every plant still appears, just slowly
// enough that a reader leaves.
//
// A macrotask has no such opinion. It returns as soon as the event loop is
// free, which is what these pauses are actually for: letting a finger, a tap
// or a resize be answered between batches. What is drawn still reaches the
// screen on the compositor's own schedule, which is where that decision
// belongs.
//
// `setTimeout(0)` is clamped to about four milliseconds after a few nested
// calls, and these are nested hundreds deep. A `MessageChannel` is not
// clamped.
//
// Built on first use rather than on import: a listening port is an open handle,
// and a module that holds one from the moment it is loaded keeps a Node process
// alive for ever merely by being imported. Nothing imports this outside a
// browser today. Something will.
const breathe = (() => {
  let channel = null;
  let waiting = [];
  return () => new Promise((resolve) => {
    if (!channel) {
      channel = new MessageChannel();
      channel.port1.onmessage = () => { const go = waiting; waiting = []; go.forEach((done) => done()); };
    }
    waiting.push(resolve);
    channel.port2.postMessage(0);
  });
})();

// How long to work before letting go, in milliseconds. About one frame at
// sixty a second: long enough that the pauses are a small part of the whole,
// short enough that nothing waits noticeably to be answered. Counted rather
// than assumed, because a plant takes eleven milliseconds to grow on a Mac and
// several times that on a phone — a batch of a fixed number of plants is a
// different length of freeze on every device.
const SLICE = 16;

// MARK: - The ground

// Seeds for the walk's dressing, so it is the same shape on every visit.
export const SEED = { ground: 2026, verge: 7, floor: 5, hedge: { '-1': 31, '1': 32 }, rill: 1621 };

// No straight line anywhere in the garden: the ground's outline, its sides,
// the path's verges and the hedges all come from SeedCore's `Organic`, the
// shapes the app draws, through the module.
function buildGround(farSide, span, e) {
  const positions = [], normals = [], colours = [];
  const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
  const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
  const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => { tri(a, b, c, n, ca, cb, cc); tri(a, c, d, n, ca, cc, cd); };
  const length = SIDE * span;
  const wander = (along, side, seed) => e.pg_verge(along, side, seed) / 0.14; // -1…1

  // The slab's top: its worn, wandering outline, filled from the middle.
  const outline = readOutline(e, SIDE, length, SEED.ground);
  const n = outline.length;
  for (let i = 0; i < n; i++) {
    const a = outline[i], b = outline[(i + 1) % n];
    tri([0, 0, 0], [a[0], 0, a[1]], [b[0], 0, b[1]], [0, 1, 0], COLOUR.turf);
  }

  // Its side: the slab every plot hangs from its outline (`slab.js`), the
  // floor seed saying how its lower edge undulates.
  const slab = hangSide(outline, { salt: SEED.floor });

  // The mown path: verges cut by eye, stripes that follow them, and ends that
  // wander across as well as along.
  const step = 0.1, start = -length / 2 + 0.32, end = length / 2 - 0.32;
  const rows = Math.round((end - start) / step);
  const across = (z) => {
    const left = -PATH_HALF + e.pg_verge(z, -1, SEED.verge);
    const right = PATH_HALF + e.pg_verge(z, 1, SEED.verge);
    const width = right - left;
    return [left, left + width / 3 + 0.02 * wander(z, 2, SEED.verge),
            left + 2 * width / 3 + 0.02 * wander(z, 3, SEED.verge), right];
  };
  const endShift = (x, side) => 0.07 * wander(x * 3 + side * 17, 4, SEED.verge);
  for (let r = 0; r < rows; r++) {
    const z0 = start + r * step, z1 = z0 + step;
    const b0 = across(z0), b1 = across(z1);
    [1.07, 0.95, 1.07].forEach((k, s) => {
      const c = COLOUR.grass.map((v) => v * k);
      const za = (x) => (r === 0 ? z0 + endShift(x, -1) : z0);
      const zb = (x) => (r === rows - 1 ? z1 + endShift(x, 1) : z1);
      quad([b0[s], 0.005, za(b0[s])], [b0[s + 1], 0.005, za(b0[s + 1])],
           [b1[s + 1], 0.005, zb(b1[s + 1])], [b1[s], 0.005, zb(b1[s])], [0, 1, 0], c);
    });
  }

  // **A rill down the middle of the path.** The Long Walk is at the head of
  // the garden, where water has come furthest, and it is led along the walk
  // in stone rather than lying anywhere in it. It follows the middle of the
  // path as the verges wander, and swings slowly across it as well: laid down
  // the exact middle, even a wandering one, it drew a rule down the page. It
  // stops short of both ends so the walk can be entered on the grass.
  const middle = (z) => {
    const b = across(z);
    return (b[0] + b[3]) / 2 + 0.2 * wander(z * 0.45, 5, SEED.rill);
  };
  raiseRill(e, { tri, quad }, { centre: middle, from: start + 0.9, to: end - 0.9, seed: SEED.rill });

  // The hedges: one length each side, grown rather than built, the tall yew on
  // whichever side is further from the viewer. Each throws its shadow on the
  // border in front of it (`casting`).
  // **On the plot** (`hedgeToPlot`): the inner face where the rule has it, the
  // outer side pressed onto the plot's own edge. The tone is read off where
  // the hedge was grown, so pressing it does not move its grain.
  const casting = [];
  const onPlot = hedgeToPlot(outline, [HEDGE_FROM, Infinity]);
  for (const side of [-1, 1]) {
    const height = side === farSide ? HEDGE.tall : HEDGE.low;
    const mesh = readStructure(
      takeResult(e, e.pg_hedge(length - 0.9, height, HEDGE.thickness, SEED.hedge[side], 1, 0)));
    const x = side * (HEDGE_FROM + HEDGE.thickness / 2);
    for (let t = 0; t < mesh.indices.length; t += 3) {
      const corners = [0, 1, 2].map((k) => mesh.indices[t + k]);
      for (const v of corners) {
        const grown = [mesh.positions[v * 3] + x, mesh.positions[v * 3 + 1], mesh.positions[v * 3 + 2]];
        const fit = onPlot(grown[0], grown[2]);
        const p = [fit.at[0], grown[1], fit.at[1]];
        const tone = 0.9 + 0.2 * hash(Math.round(grown[1] * 37) * 131 + Math.round(grown[2] * 29));
        vertex(p, pressNormal([mesh.normals[v * 3], mesh.normals[v * 3 + 1], mesh.normals[v * 3 + 2]], fit),
               COLOUR.yew.map((c) => c * tone));
        casting.push(...p);
      }
    }
  }
  return { positions: new Float32Array(positions), normals: new Float32Array(normals), colours: new Float32Array(colours),
           casting: new Float32Array(casting), side: slab };
}

// **A slab of the next area's ground, with nothing standing on it.**
//
// Grown the way an area's own builder grows its floor — the same `Organic`
// outline, the same strata hanging off it — at a plot's own size, and then
// shrunk. Shrunk rather than grown small: `Organic.outline` wanders a fixed
// 22 cm inward whatever size it is asked for, so a slab grown at a third of a
// plot would have three times a plot's wander and would read as a different
// kind of thing. What this draws is a plot of this garden, seen from further
// off.
//
// **And nothing else comes with it.** No plants, no structures, no shadow: a
// slab a hundred and forty pixels across has no room for any of them, and a
// page that grew them would pay for three more gardens to show the edges of
// three.
function besideGround(e, seed, ground) {
  const positions = [], normals = [], colours = [];
  const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
  const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
  const scale = BESIDE.scale;

  const grown = readOutline(e, SIDE, SIDE, seed);
  const outline = grown.map(([x, z]) => [x * scale, z * scale]);
  const n = outline.length;
  for (let i = 0; i < n; i++) {
    const a = outline[i], b = outline[(i + 1) % n];
    tri([0, 0, 0], [a[0], 0, a[1]], [b[0], 0, b[1]], [0, 1, 0], ground);
  }

  // Its side is the slab every plot hangs (`slab.js`), worked out on the
  // outline as it was grown and then shrunk with it — so its lower edge
  // wanders at a plot's own rate round it rather than at twice it, and its
  // bands and stones are a plot's, seen from further off.
  return { positions: new Float32Array(positions), normals: new Float32Array(normals),
           colours: new Float32Array(colours), side: hangSide(grown, { salt: seed, scale }) };
}

export function readOutline(e, width, length, seed) {
  const bytes = takeResult(e, e.pg_outline(width, length, seed));
  const count = new DataView(bytes).getUint32(0, true);
  const xz = new Float32Array(bytes.slice(4, 4 + count * 8));
  return Array.from({ length: count }, (_, i) => [xz[i * 2], xz[i * 2 + 1]]);
}

// How far a line from `from` heading `(dx, dz)` runs before it leaves the
// plot: the nearest crossing of the outline.
export function rimReach(outline, from, dx, dz) {
  let best = Infinity;
  for (let i = 0, n = outline.length; i < n; i++) {
    const a = outline[i], b = outline[(i + 1) % n];
    const ex = b[0] - a[0], ez = b[1] - a[1];
    const det = dx * ez - dz * ex;
    if (Math.abs(det) < 1e-9) continue;
    const wx = a[0] - from[0], wz = a[1] - from[1];
    const along = (wx * ez - wz * ex) / det;
    const on = (wx * dz - wz * dx) / det;
    if (along > 0 && on >= 0 && on <= 1) best = Math.min(best, along);
  }
  return best;
}

// **Keeping a dressing on the slab.** Gravel, tilth, tiles, grass: each area
// lays its floor as a sheet, and a sheet laid square over a wandering outline
// either overhangs it into the sky or stops short of it with a ruled edge. This
// answers a point on the plot as it is and a point past the edge pulled
// straight in, towards the middle, onto the edge — so a sheet laid a little
// wider than the plot and passed through it ends exactly on the plot's own
// wandering edge. Straight in rather than to the nearest point on the edge,
// because the outline goes once round the middle and so neighbours stay in
// order. 4 mm inside, which is what a chord between two pulled points can bow
// out where the edge dents in. The Coppice's `ontoRim` did this first.
export function keepToPlot(outline) {
  let nearest = Infinity;
  for (const [x, z] of outline) nearest = Math.min(nearest, Math.hypot(x, z));
  return (x, z) => {
    const r = Math.hypot(x, z);
    if (r < nearest - 0.01) return [x, z];
    const rim = rimReach(outline, [0, 0], x / r, z / r) - 0.004;
    return r <= rim ? [x, z] : [x * rim / r, z * rim / r];
  };
}

// **Keeping a hedge on the slab.** The walk's and the room's hedges stand
// with their inner face 2.3 m out, where the rule puts it, and were grown
// 0.36 m thick — past an edge that wanders between 2.42 and 2.56 m, and at the
// room's corners past an edge that is rounded where the hedges meet square.
// Marcus, 25 September 2026: pulled inside, the places the plants stand in
// kept exactly. So the inner face does not move — nothing inside
// `inner` (the half-sizes of the rectangle the inner faces stand on) is
// touched — and what lies beyond it is drawn in towards the inner face, onto
// the band between it and the edge: along a side straight across the hedge,
// and at a corner fanned from the inner corner. The squeeze is a tanh, so the
// hedge keeps its own shape near its inner face and only its outer side is
// pressed, ending on the edge and following its wander. Answers the point and
// the factor its depth was pressed by at that point, for the normals.
export function hedgeToPlot(outline, inner) {
  const memo = new Map();
  const room = (key, q, dx, dz) => {
    let d = memo.get(key);
    if (d === undefined) { d = rimReach(outline, q, dx, dz) - 0.006; memo.set(key, d); }
    return Math.max(0.02, d);
  };
  return (x, z) => {
    const qx = Math.max(-inner[0], Math.min(inner[0], x)), qz = Math.max(-inner[1], Math.min(inner[1], z));
    const ox = x - qx, oz = z - qz, u = Math.hypot(ox, oz);
    if (u < 1e-9) return { at: [x, z], across: [1, 0], pressed: 1, spread: 1 };
    const dx = ox / u, dz = oz / u;
    const corner = ox !== 0 && oz !== 0;
    const key = corner
      ? `c${Math.sign(ox)}${Math.sign(oz)}:${Math.round(Math.atan2(dz, dx) * 180)}`
      : ox !== 0 ? `x${Math.sign(ox)}:${Math.round(qz * 100)}` : `z${Math.sign(oz)}:${Math.round(qx * 100)}`;
    const depth = room(key, [qx, qz], dx, dz);
    const t = Math.tanh(u / depth);
    return {
      at: [qx + dx * depth * t, qz + dz * depth * t],
      across: [dx, dz],
      pressed: Math.max(0.02, 1 - t * t),
      spread: corner ? (depth * t) / u : 1,
    };
  };
}

// A normal carried through `hedgeToPlot`: a surface pressed flat across the
// hedge turns to face across it, so the component across is divided by how
// hard it was pressed.
export function pressNormal(n, fit) {
  const [dx, dz] = fit.across;
  const along = n[0] * dx + n[2] * dz;
  const px = n[0] - along * dx, pz = n[2] - along * dz;
  const m = [along / fit.pressed * dx + px / fit.spread, n[1], along / fit.pressed * dz + pz / fit.spread];
  const l = Math.hypot(m[0], m[1], m[2]) || 1;
  return [m[0] / l, m[1] / l, m[2] / l];
}

// A structure's mesh: `pg_hedge` and `pg_bench` answer in the same shape.
export function readStructure(bytes) {
  const view = new DataView(bytes);
  const vertices = view.getUint32(0, true), indices = view.getUint32(4, true);
  let at = 8;
  const positions = new Float32Array(bytes.slice(at, at + vertices * 12)); at += vertices * 12;
  const normals = new Float32Array(bytes.slice(at, at + vertices * 12)); at += vertices * 12;
  return { positions, normals, indices: new Uint32Array(bytes.slice(at, at + indices * 4)) };
}

export function hash(n) {
  const x = Math.sin(n * 12.9898) * 43758.5453;
  return x - Math.floor(x);
}

// MARK: - GL plumbing
//
// `program` and `upload` are exported, with the plant's two shaders above,
// for the Wild Fields (`wildfields.js`): a field with no edge cannot be a plot
// on this stage, and a second copy of how a plant is lit would be two lights.

export function program(gl, vertex, fragment, attributes, extraUniforms) {
  const p = link(gl, vertex, fragment);
  const at = {};
  for (const name of attributes) at[name] = gl.getAttribLocation(p, name);
  for (const name of ['viewProjection', 'sun', 'sunColour', 'sky', 'bounce', 'strength', ...extraUniforms]) {
    at[name] = gl.getUniformLocation(p, name);
  }
  return { program: p, at };
}

export function upload(gl, p, mesh) {
  const vao = gl.createVertexArray();
  gl.bindVertexArray(vao);
  const buffers = [
    attribute(gl, p.at.position, mesh.positions, 3),
    attribute(gl, p.at.normal, mesh.normals, 3),
    attribute(gl, p.at.colour, mesh.colours, 3),
  ];
  gl.bindVertexArray(null);
  const count = mesh.positions.length / 3;
  return {
    draw() { gl.bindVertexArray(vao); gl.drawArrays(gl.TRIANGLES, 0, count); gl.bindVertexArray(null); },
    release() { buffers.forEach((b) => gl.deleteBuffer(b)); gl.deleteVertexArray(vao); },
  };
}

// The slab's side (`hangSide`): four attributes and an index, since its
// columns share their points and a side is hundreds of them round.
function uploadSide(gl, p, mesh) {
  const vao = gl.createVertexArray();
  gl.bindVertexArray(vao);
  const buffers = [
    attribute(gl, p.at.position, mesh.positions, 3),
    attribute(gl, p.at.normal, mesh.normals, 3),
    attribute(gl, p.at.place, mesh.places, 4),
    attribute(gl, p.at.hang, mesh.hangs, 4),
  ];
  const index = gl.createBuffer();
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index);
  gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, mesh.indices, gl.STATIC_DRAW);
  gl.bindVertexArray(null);
  const count = mesh.indices.length;
  return {
    draw() { gl.bindVertexArray(vao); gl.drawElements(gl.TRIANGLES, count, gl.UNSIGNED_INT, 0); gl.bindVertexArray(null); },
    release() { buffers.forEach((b) => gl.deleteBuffer(b)); gl.deleteBuffer(index); gl.deleteVertexArray(vao); },
  };
}

// **Pieces that move**, for the one area that has any: the Cold Frame's
// lights, which open (`frame.js`). A ground builder may hand back `pieces`, a
// function answering them as they stand now — `{ opaque, glass }`, each a mesh
// in the ground's shape or null — and the same answer until one moves. They are
// drawn with the ground and with its glass, and uploaded only when they have
// moved. Every other area hands back none, and this is `mesh` as it was.
function withPieces(gl, p, mesh, pieces, which) {
  if (!pieces) return mesh;
  let from = null, piece = null;
  return {
    draw() {
      mesh.draw();
      const now = pieces();
      if (now !== from) {
        piece?.release();
        piece = now[which] ? upload(gl, p, now[which]) : null;
        from = now;
      }
      piece?.draw();
    },
    release() { mesh.release(); piece?.release(); },
  };
}

// A view looking along -direction at the plot's middle, y up.
function lookAlong(direction) {
  const z = direction;
  const x = normalise3(cross3([0, 1, 0], z));
  const y = cross3(z, x);
  return [x[0], y[0], z[0], 0, x[1], y[1], z[1], 0, x[2], y[2], z[2], 0, 0, 0, 0, 1];
}

// The whole view: the window fitted to the plot, its hedges and its tallest
// plants, with headroom above, the rim's depth below, and `UNDER` of sky
// below that. `cx`, `cy`, `w` and `h` are the window, in metres across the
// screen;
// `content` is the part of it the plot fills, which is narrower than the
// window on a wide screen and shorter on a tall one. A closer look may move
// anywhere inside `content` and nowhere outside it.
function frame(view, aspect, span) {
  const { minX, maxX, minY, maxY } =
    spread(corners(view, SIDE / 2, (SIDE * span) / 2, -RIM_DEPTH - UNDER, 2.3));
  const margin = 1.06;
  const contentW = (maxX - minX) * margin, contentH = (maxY - minY) * margin;
  let w = contentW, hgt = contentH;
  if (w / hgt > aspect) hgt = w / aspect; else w = hgt * aspect;
  const cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
  return { cx, cy, w, h: hgt, content: { w: contentW, h: contentH } };
}

// The eight corners of a box about the plot's middle, where the view puts them
// on the screen: metres across and up, in the window's own frame. Numbered so
// that two corners joined by an edge of the box differ in one bit, which is
// what `reachOver` walks.
function corners(view, hx, hz, low, high) {
  const out = [];
  for (const x of [-hx, hx]) for (const y of [low, high]) for (const z of [-hz, hz]) {
    out.push([view[0] * x + view[4] * y + view[8] * z, view[1] * x + view[5] * y + view[9] * z]);
  }
  return out;
}

// The box on the screen those corners fill.
function spread(points) {
  const along = (i) => points.map((p) => p[i]);
  return { minX: Math.min(...along(0)), maxX: Math.max(...along(0)),
           minY: Math.min(...along(1)), maxY: Math.max(...along(1)) };
}

// **How far the plot reaches, over one band of the screen.**
//
// `band` is the axis the band is measured along — 0 for a band of columns, 1
// for a band of rows — and the answer is how far the drawing reaches on the
// other axis between `lo` and `hi`.
//
// **A box on this projection is a six-sided figure**, and its furthest points
// up, down, left and right are four single corners. Over the narrow band a
// slab beside it stands in, it reaches nowhere near as far. On the walk that
// is the difference between putting a slab below three plots' near corner,
// which is off the bottom of the canvas, and putting it in the sky under the
// middle of them, where there is room for it.
//
// The figure is convex, so its furthest point within a band is on its edge:
// each of the box's twelve edges is cut to the band and both ends of what is
// left are looked at. A band that misses the drawing altogether — which
// nothing here asks for — is answered corner to corner.
function reachOver(points, band, lo, hi) {
  const other = 1 - band;
  let min = Infinity, max = -Infinity;
  const see = (v) => { min = Math.min(min, v); max = Math.max(max, v); };
  for (let i = 0; i < points.length; i++) {
    for (const bit of [4, 2, 1]) {
      const j = i ^ bit;
      if (j < i) continue;
      const p = points[i], q = points[j];
      const run = q[band] - p[band];
      let from = 0, to = 1;
      if (Math.abs(run) < 1e-9) {
        if (p[band] < lo || p[band] > hi) continue;
      } else {
        const a = (lo - p[band]) / run, b = (hi - p[band]) / run;
        from = Math.max(0, Math.min(a, b));
        to = Math.min(1, Math.max(a, b));
        if (from > to) continue;
      }
      see(p[other] + (q[other] - p[other]) * from);
      see(p[other] + (q[other] - p[other]) * to);
    }
  }
  if (min > max) { const all = points.map((p) => p[other]); return { min: Math.min(...all), max: Math.max(...all) }; }
  return { min, max };
}

// A mesh drawn where it was built, which is everything but a slab beside the
// plot (`BESIDE`).
const HERE = [0, 0, 0];

// Orthographic, looking at (cx, cy) through a window w by h.
function ortho(cx, cy, w, hgt) {
  const l = cx - w / 2, r = cx + w / 2, b = cy - hgt / 2, t = cy + hgt / 2, n = -20, f = 20;
  return [2 / (r - l), 0, 0, 0, 0, 2 / (t - b), 0, 0, 0, 0, -2 / (f - n), 0,
    -(r + l) / (r - l), -(t + b) / (t - b), -(f + n) / (f - n), 1];
}

// **How close a look can come**: near enough that the window's shorter side is
// this many metres, which puts one flower of a plant across a finger's width
// of a phone's screen at the page's own angle. Measured against the window
// rather than as a fixed number of times closer, so a phone and a wide desktop
// window both stop at the same nearness to a plant.
const CLOSEST = 0.9;

// How far above the soil the point a look is held over sits, in metres: the
// middle of the height `frame` fits the whole view to, so that the whole view's
// own middle is over the middle of the plot and holding it there moves nothing.
// **It follows `UNDER`, and must.** Sky under the plot is sky the window's
// middle sits lower against, and a held point that stayed where it was would
// pull the plot back down into it — the whole view would no longer be the
// view a look is held at, and opening a page would nudge. It comes out a
// third of a metre up, which is a stem rather than a border's flowers, so it
// is nearer the soil than the flowers that stays put through a turn.
const ABOVE = (2.3 - RIM_DEPTH - UNDER) / 2;

function closest(whole) {
  return Math.max(1, Math.min(whole.w, whole.h) / CLOSEST);
}

// A view's own axes in the world: right across the screen, up it, and back
// towards the eye.
function axes(view) {
  return { x: [view[0], view[4], view[8]], y: [view[1], view[5], view[9]], z: [view[2], view[6], view[10]] };
}

function dot3(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }
// How far (px, py) is from the segment between two points on the screen.
function segmentGap(px, py, [ax, ay], [bx, by]) {
  const dx = bx - ax, dy = by - ay;
  const length = dx * dx + dy * dy;
  const t = length ? Math.min(1, Math.max(0, ((px - ax) * dx + (py - ay) * dy) / length)) : 0;
  return Math.hypot(px - (ax + t * dx), py - (ay + t * dy));
}
function cross3(a, b) { return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]; }
function normalise3(v) { const l = Math.hypot(...v); return v.map((x) => x / l); }
