// Plots of the Long Walk, drawn the way the app draws a plot: a floating
// slab of ground seen in true isometric, a mown path down the middle, a tall
// yew behind the far border and a low hedge in front of the near one.
//
// The module plants the arrivals by the Long Walk's rule and grows each one;
// this file draws the ground and puts each plant on its spot. The numbers for
// the ground, path, hedges and light are the app's, from GardenGround.swift,
// GardenStructures.swift and PlotView.swift.

import { ROLES, decode, takeResult, link, attribute, multiply } from './plant.js';

export const SIDE = 5.2;    // LongWalk.plotSide, and QuietGarden.plotSide
const PATH_HALF = 0.6;      // LongWalk.pathHalfWidth
const HEDGE_FROM = 2.3;     // LongWalk.hedgeFrom
export const RIM_DEPTH = 0.95;  // GardenGround.rimDepth
export const HEDGE = { thickness: 0.36, tall: 2.0, low: 0.7 };

export const COLOUR = {
  turf: [0.235, 0.265, 0.190],
  grass: [0.285, 0.320, 0.225],
  humus: [0.205, 0.158, 0.116],
  earth: [0.375, 0.300, 0.232],
  bedrock: [0.340, 0.330, 0.318],
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
// shadow away from it.
export const LIGHT = {
  sun: [-0.3320, 0.8829, 0.3320],
  sunColour: [1.00, 0.96, 0.88],
  strength: 0.76,
  sky: [0.40, 0.48, 0.60],
  bounce: [0.27, 0.25, 0.20],
};

// The app's shading, shared by the ground and the plants so they sit in one light.
const SHADE = `
uniform vec3 sun, sunColour, sky, bounce;
uniform float strength;
vec3 shade(vec3 albedo, vec3 n) {
  float hemi = 0.5 + 0.5 * n.y;
  vec3 ambient = sky * hemi + bounce * (1.0 - hemi);
  vec3 direct = pow(max(dot(n, sun), 0.0), 0.9) * strength * sunColour;
  return albedo * (ambient + direct);
}`;

const GROUND_VERTEX = `#version 300 es
in vec3 position; in vec3 normal; in vec3 colour;
uniform mat4 viewProjection;
out vec3 vNormal; out vec3 vColour;
void main() { vNormal = normal; vColour = colour; gl_Position = viewProjection * vec4(position, 1.0); }`;

// `opacity` is 1 for everything but glass, which is drawn last and seen through.
// Premultiplied, because the canvas is.
const GROUND_FRAGMENT = `#version 300 es
precision highp float;
in vec3 vNormal; in vec3 vColour;
uniform float opacity;
${SHADE}
out vec4 outColour;
void main() { outColour = vec4(shade(vColour, normalize(vNormal)) * opacity, opacity); }`;

const PLANT_VERTEX = `#version 300 es
in vec3 position; in vec3 normal; in vec2 uv;
uniform mat4 viewProjection;
uniform vec3 offset;
out vec3 vNormal; out vec2 vUV;
void main() { vNormal = normal; vUV = uv; gl_Position = viewProjection * vec4(position + offset, 1.0); }`;

const PLANT_FRAGMENT = `#version 300 es
precision highp float;
in vec3 vNormal; in vec2 vUV;
uniform sampler2D colour;
${SHADE}
out vec4 outColour;
void main() {
  vec3 n = normalize(gl_FrontFacing ? vNormal : -vNormal);
  outColour = vec4(shade(texture(colour, vUV).rgb, n), 1.0);
}`;

// **The stage is not the walk's.** Everything in it — the GL plumbing, the
// isometric camera, the quarter turns, the plant program — is what a plot is,
// and the Quiet Garden's page uses the same one with its own ground. The one
// thing an area supplies is how its ground is built. When a third area wants
// it, this belongs in a module of its own rather than in the first area that
// happened to need it.
export function makePlotStage(canvas, span, e, buildTheGround = buildGround) {
  const gl = canvas.getContext('webgl2', { antialias: true, alpha: true, premultipliedAlpha: true });
  if (!gl) throw new Error('This browser has no WebGL2.');
  const ground = program(gl, GROUND_VERTEX, GROUND_FRAGMENT, ['position', 'normal', 'colour'], ['offset', 'opacity']);
  const plantProgram = program(gl, PLANT_VERTEX, PLANT_FRAGMENT, ['position', 'normal', 'uv'], ['offset', 'colour']);

  const plants = [];
  let turn = 0;
  let groundMesh = null;
  // **Glass, for the one area that has any.** A ground builder may hand back a
  // `glass` mesh beside its own, and it is drawn after the plants, blended and
  // without writing depth, so what stands under it shows through. The Cold
  // Frame's lights are the first thing in the garden a reader has to see
  // through; every other area returns no glass and draws exactly as it did.
  let glassMesh = null;
  let glassOpacity = 1;
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
    if (glassMesh) glassMesh.release();
    glassMesh = built.glass ? withPieces(gl, ground, upload(gl, ground, built.glass), built.pieces, 'glass') : null;
    glassOpacity = built.glass?.opacity ?? 1;
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

    for (const [p, extra] of [[ground, null], [plantProgram, null]]) {
      gl.useProgram(p.program);
      gl.uniformMatrix4fv(p.at.viewProjection, false, viewProjection);
      gl.uniform3fv(p.at.sun, LIGHT.sun);
      gl.uniform3fv(p.at.sunColour, LIGHT.sunColour);
      gl.uniform3fv(p.at.sky, LIGHT.sky);
      gl.uniform3fv(p.at.bounce, LIGHT.bounce);
      gl.uniform1f(p.at.strength, LIGHT.strength);
    }

    gl.useProgram(ground.program);
    gl.uniform1f(ground.at.opacity, 1);
    groundMesh.draw();

    gl.useProgram(plantProgram.program);
    gl.uniform1i(plantProgram.at.colour, 0);
    gl.activeTexture(gl.TEXTURE0);
    for (const plant of plants) {
      gl.uniform3fv(plantProgram.at.offset, [plant.x, plant.lift, plant.z]);
      for (const part of plant.parts) {
        gl.bindTexture(gl.TEXTURE_2D, plant.textures[part.role]);
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
    const parts = grown.parts.map((part) => {
      const vao = gl.createVertexArray();
      gl.bindVertexArray(vao);
      const buffers = [
        attribute(gl, plantProgram.at.position, part.positions, 3),
        attribute(gl, plantProgram.at.normal, part.normals, 3),
        attribute(gl, plantProgram.at.uv, part.uvs, 2),
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
    plants.push({ x, z, lift, parts, textures, who, height, reach });
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
  return { add, clear, turnBy, draw, rebuild, turn: () => turn, view, held, lookAt, carried, seams, onScreen,
           pick, named, toward, toScreen };
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
export const SEED = { ground: 2026, verge: 7, floor: 5, hedge: { '-1': 31, '1': 32 } };

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

  // Its sides hang from that outline, down to a floor as rough as a clod's,
  // in the app's strata: humus, earth, then bedrock.
  const strata = [[0, COLOUR.humus], [0.16, COLOUR.earth], [0.58, COLOUR.earth], [1, COLOUR.bedrock]];
  let around = 0;
  const floor = outline.map((p, i) => {
    if (i > 0) around += Math.hypot(p[0] - outline[i - 1][0], p[1] - outline[i - 1][1]);
    return RIM_DEPTH * (1 + 0.22 * wander(around, 1, SEED.floor));
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

  // The hedges: one length each side, grown rather than built, the tall yew on
  // whichever side is further from the viewer.
  for (const side of [-1, 1]) {
    const height = side === farSide ? HEDGE.tall : HEDGE.low;
    const mesh = readStructure(
      takeResult(e, e.pg_hedge(length - 0.9, height, HEDGE.thickness, SEED.hedge[side], 1, 0)));
    const x = side * (HEDGE_FROM + HEDGE.thickness / 2);
    for (let t = 0; t < mesh.indices.length; t += 3) {
      const corners = [0, 1, 2].map((k) => mesh.indices[t + k]);
      for (const v of corners) {
        const p = [mesh.positions[v * 3] + x, mesh.positions[v * 3 + 1], mesh.positions[v * 3 + 2]];
        const tone = 0.9 + 0.2 * hash(Math.round(p[1] * 37) * 131 + Math.round(p[2] * 29));
        vertex(p, [mesh.normals[v * 3], mesh.normals[v * 3 + 1], mesh.normals[v * 3 + 2]], COLOUR.yew.map((c) => c * tone));
      }
    }
  }
  return { positions: new Float32Array(positions), normals: new Float32Array(normals), colours: new Float32Array(colours) };
}

export function readOutline(e, width, length, seed) {
  const bytes = takeResult(e, e.pg_outline(width, length, seed));
  const count = new DataView(bytes).getUint32(0, true);
  const xz = new Float32Array(bytes.slice(4, 4 + count * 8));
  return Array.from({ length: count }, (_, i) => [xz[i * 2], xz[i * 2 + 1]]);
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

function program(gl, vertex, fragment, attributes, extraUniforms) {
  const p = link(gl, vertex, fragment);
  const at = {};
  for (const name of attributes) at[name] = gl.getAttribLocation(p, name);
  for (const name of ['viewProjection', 'sun', 'sunColour', 'sky', 'bounce', 'strength', ...extraUniforms]) {
    at[name] = gl.getUniformLocation(p, name);
  }
  return { program: p, at };
}

function upload(gl, p, mesh) {
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
// plants, as the app frames a plot with headroom above and the slab's depth
// below. `cx`, `cy`, `w` and `h` are the window, in metres across the screen;
// `content` is the part of it the plot fills, which is narrower than the
// window on a wide screen and shorter on a tall one. A closer look may move
// anywhere inside `content` and nowhere outside it.
function frame(view, aspect, span) {
  const h = SIDE / 2, L = (SIDE * span) / 2;
  let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
  for (const x of [-h, h]) for (const y of [-RIM_DEPTH, 2.3]) for (const z of [-L, L]) {
    const vx = view[0] * x + view[4] * y + view[8] * z;
    const vy = view[1] * x + view[5] * y + view[9] * z;
    minX = Math.min(minX, vx); maxX = Math.max(maxX, vx);
    minY = Math.min(minY, vy); maxY = Math.max(maxY, vy);
  }
  const margin = 1.06;
  const contentW = (maxX - minX) * margin, contentH = (maxY - minY) * margin;
  let w = contentW, hgt = contentH;
  if (w / hgt > aspect) hgt = w / aspect; else w = hgt * aspect;
  const cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
  return { cx, cy, w, h: hgt, content: { w: contentW, h: contentH } };
}

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
// It is also about where a border's flowers are, so it is the plants that stay
// put under the middle of the window through a turn, not the soil.
const ABOVE = (2.3 - RIM_DEPTH) / 2;

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
