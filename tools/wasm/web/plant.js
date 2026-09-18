// Grows a plant with SeedCore compiled to WebAssembly and draws it with WebGL2.
//
// The module does all of the growing; this file only draws what it is given.
// That is the point of the arrangement: there is one implementation of the
// plant, and it is the one on the phone.

const ROLES = ['stem', 'leaf', 'petal', 'centre', 'stamen'];

// The module asks WASI for a clock, some randomness and somewhere to print.
// Nothing else it imports is ever called while growing a plant, so everything
// else answers "not supported".
function wasiShim(memoryRef) {
  const ENOSYS = 52, EBADF = 8;
  const view = () => new DataView(memoryRef.memory.buffer);
  const decoder = new TextDecoder();
  const known = {
    args_sizes_get: (argc, size) => { view().setUint32(argc, 0, true); view().setUint32(size, 0, true); return 0; },
    environ_sizes_get: (count, size) => { view().setUint32(count, 0, true); view().setUint32(size, 0, true); return 0; },
    args_get: () => 0,
    environ_get: () => 0,
    clock_time_get: (_id, _precision, out) => {
      view().setBigUint64(out, BigInt(Math.round(performance.timeOrigin + performance.now())) * 1000000n, true);
      return 0;
    },
    clock_res_get: (_id, out) => { view().setBigUint64(out, 1000n, true); return 0; },
    random_get: (pointer, length) => {
      crypto.getRandomValues(new Uint8Array(memoryRef.memory.buffer, pointer, length));
      return 0;
    },
    fd_write: (fd, iovs, count, written) => {
      let text = '', total = 0;
      for (let i = 0; i < count; i++) {
        const base = view().getUint32(iovs + i * 8, true);
        const length = view().getUint32(iovs + i * 8 + 4, true);
        text += decoder.decode(new Uint8Array(memoryRef.memory.buffer, base, length));
        total += length;
      }
      (fd === 2 ? console.error : console.log)(text);
      view().setUint32(written, total, true);
      return 0;
    },
    fd_prestat_get: () => EBADF,
    proc_exit: (code) => { throw new Error(`the plant module exited with ${code}`); },
  };
  return new Proxy(known, { get: (target, name) => target[name] ?? (() => ENOSYS) });
}

export async function loadGrower(url) {
  const memoryRef = {};
  const { instance } = await WebAssembly.instantiateStreaming(fetch(url), {
    wasi_snapshot_preview1: wasiShim(memoryRef),
  });
  memoryRef.memory = instance.exports.memory;
  instance.exports._initialize();

  return function grow(seedHex) {
    const e = instance.exports;
    const text = new TextEncoder().encode(seedHex.trim().toLowerCase());
    const pointer = e.pg_alloc(text.length);
    new Uint8Array(e.memory.buffer, pointer, text.length).set(text);
    const started = performance.now();
    const length = e.pg_grow(pointer, text.length);
    const took = performance.now() - started;
    e.pg_free(pointer);
    if (length === 0) return null;
    // Copied out, because the next call reuses the module's buffer.
    const bytes = new Uint8Array(e.memory.buffer, e.pg_result(), length).slice();
    return { ...decode(bytes.buffer), took };
  };
}

function decode(buffer) {
  const data = new DataView(buffer);
  let at = 0;
  const u32 = () => { const v = data.getUint32(at, true); at += 4; return v; };
  const f32s = (n) => { const v = new Float32Array(buffer.slice(at, at + n * 4)); at += n * 4; return v; };

  const magic = new TextDecoder().decode(new Uint8Array(buffer, 0, 4));
  if (magic !== 'PGP1') throw new Error(`not a plant buffer: ${magic}`);
  at = 4;
  const partCount = u32();
  const bounds = f32s(6);
  const parts = [];
  for (let i = 0; i < partCount; i++) {
    const role = ROLES[u32()];
    const vertices = u32(), indexCount = u32();
    const positions = f32s(vertices * 3);
    const normals = f32s(vertices * 3);
    const uvs = f32s(vertices * 2);
    const indices = new Uint32Array(buffer.slice(at, at + indexCount * 4)); at += indexCount * 4;
    parts.push({ role, positions, normals, uvs, indices });
  }
  const textures = {};
  for (const role of ROLES) {
    const side = u32();
    textures[role] = { side, pixels: new Uint8Array(buffer.slice(at, at + side * side * 4)) };
    at += side * side * 4;
  }
  return { parts, textures, min: bounds.slice(0, 3), max: bounds.slice(3, 6) };
}

// MARK: - Drawing

const VERTEX = `#version 300 es
in vec3 position; in vec3 normal; in vec2 uv;
uniform mat4 viewProjection;
out vec3 vNormal; out vec2 vUV;
void main() {
  vNormal = normal; vUV = uv;
  gl_Position = viewProjection * vec4(position, 1.0);
}`;

// Lit from above and in front, with sky from everywhere. Double-sided, like the
// app's materials: a petal's back is lit as its own face, not seen through.
const FRAGMENT = `#version 300 es
precision highp float;
in vec3 vNormal; in vec2 vUV;
uniform sampler2D colour;
uniform vec3 sun;
out vec4 outColour;
void main() {
  vec3 n = normalize(gl_FrontFacing ? vNormal : -vNormal);
  vec3 albedo = texture(colour, vUV).rgb;
  albedo = pow(albedo, vec3(2.2));
  float direct = max(dot(n, sun), 0.0);
  float sky = 0.5 + 0.5 * n.y;
  vec3 lit = albedo * (0.85 * direct + 0.35 * sky);
  outColour = vec4(pow(lit, vec3(1.0 / 2.2)), 1.0);
}`;

export function makeStage(canvas) {
  const gl = canvas.getContext('webgl2', { antialias: true, alpha: true, premultipliedAlpha: true });
  if (!gl) throw new Error('This browser has no WebGL2.');
  const program = link(gl, VERTEX, FRAGMENT);
  const at = {
    position: gl.getAttribLocation(program, 'position'),
    normal: gl.getAttribLocation(program, 'normal'),
    uv: gl.getAttribLocation(program, 'uv'),
    viewProjection: gl.getUniformLocation(program, 'viewProjection'),
    colour: gl.getUniformLocation(program, 'colour'),
    sun: gl.getUniformLocation(program, 'sun'),
  };

  let plant = null, turn = 0.6, tilt = 0.18, dragging = null;

  function show(grown) {
    if (plant) release(gl, plant);
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
        attribute(gl, at.position, part.positions, 3),
        attribute(gl, at.normal, part.normals, 3),
        attribute(gl, at.uv, part.uvs, 2),
      ];
      const indexBuffer = gl.createBuffer();
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
      gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, part.indices, gl.STATIC_DRAW);
      buffers.push(indexBuffer);
      return { vao, buffers, count: part.indices.length, role: part.role };
    });
    gl.bindVertexArray(null);
    plant = { parts, textures, min: grown.min, max: grown.max };
    draw();
  }

  function draw() {
    const ratio = window.devicePixelRatio || 1;
    const width = Math.round(canvas.clientWidth * ratio), height = Math.round(canvas.clientHeight * ratio);
    if (canvas.width !== width || canvas.height !== height) { canvas.width = width; canvas.height = height; }
    gl.viewport(0, 0, width, height);
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    if (!plant) return;

    gl.enable(gl.DEPTH_TEST);
    gl.disable(gl.CULL_FACE);
    gl.useProgram(program);

    const size = [0, 1, 2].map((i) => plant.max[i] - plant.min[i]);
    const centre = [(plant.min[0] + plant.max[0]) / 2, plant.min[1] + size[1] * 0.5, (plant.min[2] + plant.max[2]) / 2];
    const reach = Math.max(size[1], Math.hypot(size[0], size[2])) * 0.5;
    const fov = 0.6;
    const distance = reach / Math.sin(fov / 2) * 1.1;
    const eye = [
      centre[0] + distance * Math.cos(tilt) * Math.sin(turn),
      centre[1] + distance * Math.sin(tilt),
      centre[2] + distance * Math.cos(tilt) * Math.cos(turn),
    ];
    const projection = perspective(fov, width / height, distance * 0.05, distance * 4);
    gl.uniformMatrix4fv(at.viewProjection, false, multiply(projection, lookAt(eye, centre)));
    gl.uniform3fv(at.sun, normalise([0.4, 0.8, 0.45]));
    gl.uniform1i(at.colour, 0);
    gl.activeTexture(gl.TEXTURE0);
    for (const part of plant.parts) {
      gl.bindTexture(gl.TEXTURE_2D, plant.textures[part.role]);
      gl.bindVertexArray(part.vao);
      gl.drawElements(gl.TRIANGLES, part.count, gl.UNSIGNED_INT, 0);
    }
    gl.bindVertexArray(null);
  }

  canvas.addEventListener('pointerdown', (e) => { dragging = { x: e.clientX, y: e.clientY, turn, tilt }; canvas.setPointerCapture(e.pointerId); });
  canvas.addEventListener('pointermove', (e) => {
    if (!dragging) return;
    turn = dragging.turn - (e.clientX - dragging.x) * 0.01;
    tilt = Math.max(-0.2, Math.min(1.3, dragging.tilt + (e.clientY - dragging.y) * 0.01));
    draw();
  });
  canvas.addEventListener('pointerup', () => { dragging = null; });
  new ResizeObserver(draw).observe(canvas);

  return { show };
}

function attribute(gl, location, values, size) {
  const buffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferData(gl.ARRAY_BUFFER, values, gl.STATIC_DRAW);
  gl.enableVertexAttribArray(location);
  gl.vertexAttribPointer(location, size, gl.FLOAT, false, 0, 0);
  return buffer;
}

function release(gl, plant) {
  for (const part of plant.parts) { part.buffers.forEach((b) => gl.deleteBuffer(b)); gl.deleteVertexArray(part.vao); }
  Object.values(plant.textures).forEach((t) => gl.deleteTexture(t));
}

function link(gl, vertexSource, fragmentSource) {
  const program = gl.createProgram();
  for (const [type, source] of [[gl.VERTEX_SHADER, vertexSource], [gl.FRAGMENT_SHADER, fragmentSource]]) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(shader));
    gl.attachShader(program, shader);
  }
  gl.linkProgram(program);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(program));
  return program;
}

// Column-major 4 × 4 matrices, as WebGL takes them.
function perspective(fov, aspect, near, far) {
  const f = 1 / Math.tan(fov / 2), r = 1 / (near - far);
  return [f / aspect, 0, 0, 0, 0, f, 0, 0, 0, 0, (far + near) * r, -1, 0, 0, 2 * far * near * r, 0];
}

function lookAt(eye, target) {
  const z = normalise(eye.map((v, i) => v - target[i]));
  const x = normalise(cross([0, 1, 0], z));
  const y = cross(z, x);
  const dot = (a) => a[0] * eye[0] + a[1] * eye[1] + a[2] * eye[2];
  return [x[0], y[0], z[0], 0, x[1], y[1], z[1], 0, x[2], y[2], z[2], 0, -dot(x), -dot(y), -dot(z), 1];
}

function multiply(a, b) {
  const out = new Array(16).fill(0);
  for (let c = 0; c < 4; c++) for (let r = 0; r < 4; r++) for (let k = 0; k < 4; k++) out[c * 4 + r] += a[k * 4 + r] * b[c * 4 + k];
  return out;
}

function cross(a, b) { return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]; }
function normalise(v) { const l = Math.hypot(...v); return v.map((x) => x / l); }
