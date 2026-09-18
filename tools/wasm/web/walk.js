// Plots of the Long Walk, drawn the way the app draws a plot: a floating
// slab of ground seen in true isometric, a mown path down the middle, a tall
// yew behind the far border and a low hedge in front of the near one.
//
// The module plants the arrivals by the Long Walk's rule and grows each one;
// this file draws the ground and puts each plant on its spot. The numbers for
// the ground, path, hedges and light are the app's, from GardenGround.swift,
// GardenStructures.swift and PlotView.swift.

import { ROLES, decode, takeResult, link, attribute, multiply } from './plant.js';

const SIDE = 5.2;           // LongWalk.plotSide
const PATH_HALF = 0.6;      // LongWalk.pathHalfWidth
const HEDGE_FROM = 2.3;     // LongWalk.hedgeFrom
const RIM_DEPTH = 0.95;     // GardenGround.rimDepth
const HEDGE = { thickness: 0.36, tall: 2.0, low: 0.7, piece: 0.4, overlap: 0.03 };

const COLOUR = {
  turf: [0.235, 0.265, 0.190],
  grass: [0.285, 0.320, 0.225],
  humus: [0.205, 0.158, 0.116],
  earth: [0.375, 0.300, 0.232],
  bedrock: [0.340, 0.330, 0.318],
  yew: [0.27, 0.39, 0.27],
};

// Midday, GardenGround.swift.
const LIGHT = {
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

const GROUND_FRAGMENT = `#version 300 es
precision highp float;
in vec3 vNormal; in vec3 vColour;
${SHADE}
out vec4 outColour;
void main() { outColour = vec4(shade(vColour, normalize(vNormal)), 1.0); }`;

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

export function makeWalkStage(canvas, span = 1) {
  const gl = canvas.getContext('webgl2', { antialias: true, alpha: true, premultipliedAlpha: true });
  if (!gl) throw new Error('This browser has no WebGL2.');
  const ground = program(gl, GROUND_VERTEX, GROUND_FRAGMENT, ['position', 'normal', 'colour'], ['offset']);
  const plantProgram = program(gl, PLANT_VERTEX, PLANT_FRAGMENT, ['position', 'normal', 'uv'], ['offset', 'colour']);

  const plants = [];
  let turn = 0;
  let groundMesh = null;

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
    groundMesh = upload(gl, ground, buildGround(farSide, span));
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

    const view = lookAlong(eye());
    const projection = fit(view, width / height, span);
    const viewProjection = multiply(projection, view);

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
    groundMesh.draw();

    gl.useProgram(plantProgram.program);
    gl.uniform1i(plantProgram.at.colour, 0);
    gl.activeTexture(gl.TEXTURE0);
    for (const plant of plants) {
      gl.uniform3fv(plantProgram.at.offset, [plant.x, 0, plant.z]);
      for (const part of plant.parts) {
        gl.bindTexture(gl.TEXTURE_2D, plant.textures[part.role]);
        gl.bindVertexArray(part.vao);
        gl.drawElements(gl.TRIANGLES, part.count, gl.UNSIGNED_INT, 0);
      }
    }
    gl.bindVertexArray(null);
  }

  function add(x, z, grown) {
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
    plants.push({ x, z, parts, textures });
    draw();
  }

  // Takes every plant off the stage, for moving along the walk.
  function clear() {
    for (const plant of plants) {
      for (const part of plant.parts) { part.buffers.forEach((b) => gl.deleteBuffer(b)); gl.deleteVertexArray(part.vao); }
      Object.values(plant.textures).forEach((t) => gl.deleteTexture(t));
    }
    plants.length = 0;
    draw();
  }

  function turnBy(quarters) {
    turn = (turn + quarters + 4) % 4;
    rebuildGround();
    draw();
  }

  rebuildGround();
  new ResizeObserver(draw).observe(canvas);
  return { add, clear, turnBy, draw };
}

// Plants arrivals by the rule until there are `total`, reporting as it goes.
export async function plantArrivals(e, total, report) {
  let arrived = 0;
  while (arrived < total) {
    e.pg_walk_arrive();
    arrived += 1;
    if (arrived % 10 === 0) { report(`Planting by the rule: ${arrived} of ${total} arrived`); await frame(); }
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
  for (let k = 0; k < span; k++) {
    const plot = first + k;
    const along = (k - (span - 1) / 2) * SIDE;
    const count = e.pg_walk_count(plot);
    for (let i = 0; i < count; i++) {
      const length = e.pg_walk_grow(plot, i);
      const buffer = takeResult(e, length);
      const spot = new Float32Array(buffer.slice(0, 8));
      stage.add(spot[0], spot[1] + along, decode(buffer.slice(8)));
      if (i % 4 === 3) { report(`Growing plot ${plot + 1}: ${i + 1} of ${count}`); await frame(); }
    }
  }
}

// Grows `span` plots from the plot service, as a visitor's page will: the
// service says what is planted where, with each plant's lineage, and the
// module grows each plant from that lineage.
export async function growFromService(e, stage, first, span, report) {
  stage.clear();
  const plots = [];
  for (let k = 0; k < span; k++) {
    const plot = first + k;
    const { plantings } = await (await fetch(`/api/walk/plot/${plot}`)).json();
    plots.push(plantings.length);
    const along = (k - (span - 1) / 2) * SIDE;
    for (const [i, p] of plantings.entries()) {
      const words = new TextEncoder().encode([p.seed, ...p.parents, p.encounter].join(' '));
      const pointer = e.pg_alloc(words.length);
      new Uint8Array(e.memory.buffer, pointer, words.length).set(words);
      const length = e.pg_grow_hybrid(pointer, words.length);
      e.pg_free(pointer);
      if (length === 0) continue;
      stage.add(p.spot[0], p.spot[1] + along, decode(takeResult(e, length)));
      if (i % 4 === 3) { report(`Growing plot ${plot + 1}: ${i + 1} of ${plantings.length}`); await frame(); }
    }
  }
  return plots;
}

const frame = () => new Promise((resolve) => requestAnimationFrame(() => resolve()));

// MARK: - The ground

function buildGround(farSide, span) {
  const positions = [], normals = [], colours = [];
  const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => {
    for (const [p, col] of [[a, ca], [b, cb], [c, cc], [a, ca], [c, cc], [d, cd]]) {
      positions.push(...p); normals.push(...n); colours.push(...col);
    }
  };
  const box = (x0, x1, y0, y1, z0, z1, colour) => {
    quad([x0, y1, z0], [x1, y1, z0], [x1, y1, z1], [x0, y1, z1], [0, 1, 0], colour);
    quad([x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1], [0, 0, 1], colour);
    quad([x0, y0, z0], [x1, y0, z0], [x1, y1, z0], [x0, y1, z0], [0, 0, -1], colour);
    quad([x1, y0, z0], [x1, y0, z1], [x1, y1, z1], [x1, y1, z0], [1, 0, 0], colour);
    quad([x0, y0, z0], [x0, y0, z1], [x0, y1, z1], [x0, y1, z0], [-1, 0, 0], colour);
  };
  const h = SIDE / 2, L = (SIDE * span) / 2;

  // The slab: turf on top, strata down its sides.
  quad([-h, 0, -L], [h, 0, -L], [h, 0, L], [-h, 0, L], [0, 1, 0], COLOUR.turf);
  const strata = [[0, COLOUR.humus], [0.16, COLOUR.earth], [0.58, COLOUR.earth], [1, COLOUR.bedrock]];
  for (let i = 0; i < strata.length - 1; i++) {
    const [f0, c0] = strata[i], [f1, c1] = strata[i + 1];
    const y0 = -f0 * RIM_DEPTH, y1 = -f1 * RIM_DEPTH;
    for (const s of [-1, 1]) {
      quad([-h, y1, s * L], [h, y1, s * L], [h, y0, s * L], [-h, y0, s * L], [0, 0, s], c1, c1, c0, c0);
      quad([s * h, y1, -L], [s * h, y1, L], [s * h, y0, L], [s * h, y0, -L], [s, 0, 0], c1, c1, c0, c0);
    }
  }

  // The mown path, in three stripes along it.
  const band = (2 * PATH_HALF) / 3;
  [1.07, 0.95, 1.07].forEach((k, i) => {
    const x0 = -PATH_HALF + i * band, x1 = x0 + band;
    const c = COLOUR.grass.map((v) => v * k);
    quad([x0, 0.005, -L], [x1, 0.005, -L], [x1, 0.005, L], [x0, 0.005, L], [0, 1, 0], c);
  });

  // The hedges, clipped boxes along each border, cut to one top line.
  const pieces = Math.floor(SIDE / HEDGE.piece);
  for (let k = 0; k < span; k++) for (const side of [-1, 1]) {
    const start = (k - (span - 1) / 2) * SIDE - (pieces * HEDGE.piece) / 2;
    const height = side === farSide ? HEDGE.tall : HEDGE.low;
    const centre = side * (HEDGE_FROM + HEDGE.thickness / 2);
    for (let i = 0; i < pieces; i++) {
      const z0 = start + i * HEDGE.piece - HEDGE.overlap / 2;
      const z1 = z0 + HEDGE.piece + HEDGE.overlap;
      const tone = 0.94 + 0.12 * hash((k * pieces + i) * 7 + (side > 0 ? 3 : 0));
      box(centre - HEDGE.thickness / 2, centre + HEDGE.thickness / 2, 0, height, z0, z1, COLOUR.yew.map((v) => v * tone));
    }
  }
  return { positions: new Float32Array(positions), normals: new Float32Array(normals), colours: new Float32Array(colours) };
}

function hash(n) {
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

// A view looking along -direction at the plot's middle, y up.
function lookAlong(direction) {
  const z = direction;
  const x = normalise3(cross3([0, 1, 0], z));
  const y = cross3(z, x);
  return [x[0], y[0], z[0], 0, x[1], y[1], z[1], 0, x[2], y[2], z[2], 0, 0, 0, 0, 1];
}

// Orthographic, fitted to the plot, its hedges and its tallest plants, as the
// app frames a plot with headroom above and the slab's depth below.
function fit(view, aspect, span) {
  const h = SIDE / 2, L = (SIDE * span) / 2;
  let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
  for (const x of [-h, h]) for (const y of [-RIM_DEPTH, 2.3]) for (const z of [-L, L]) {
    const vx = view[0] * x + view[4] * y + view[8] * z;
    const vy = view[1] * x + view[5] * y + view[9] * z;
    minX = Math.min(minX, vx); maxX = Math.max(maxX, vx);
    minY = Math.min(minY, vy); maxY = Math.max(maxY, vy);
  }
  const margin = 1.06;
  let w = (maxX - minX) * margin, hgt = (maxY - minY) * margin;
  if (w / hgt > aspect) hgt = w / aspect; else w = hgt * aspect;
  const cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
  const l = cx - w / 2, r = cx + w / 2, b = cy - hgt / 2, t = cy + hgt / 2, n = -20, f = 20;
  return [2 / (r - l), 0, 0, 0, 0, 2 / (t - b), 0, 0, 0, 0, -2 / (f - n), 0,
    -(r + l) / (r - l), -(t + b) / (t - b), -(f + n) / (f - n), 1];
}

function cross3(a, b) { return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]; }
function normalise3(v) { const l = Math.hypot(...v); return v.map((x) => x / l); }
