// Paths that visitors wear, in the Wild Fields: what a page counts as walking,
// what it sends, and how the field draws what everybody's walking has worn.
//
// Proposed by Marcus and accepted on 18 September 2026 on exactly these
// terms (docs/WEB-GARDENS.md §*Paths that visitors wear*); built on 2
// October 2026 for /dev only. The service's half is `Server/.api/WildWear.php`,
// and it answers only where `config.php` turns wear on. Where it does not —
// the live site — `GET /api/wild` says nothing about wear, and `wildpage.js`
// neither records nor draws any of this.
//
// **Walking is moving, not looking.** The page counts the ground cells the
// middle of the window crosses while the visitor drags the field or presses
// one of the pad's four directions, and nothing else: not a turn, not coming
// closer, not going to a plant, not the glide home, not where the window
// rests. Somebody standing to look at a plant wears nothing, which is also
// true of grass.
//
// **What is sent is which cells, and nothing more.** A batch is the cells
// crossed since the last one, each once, sorted so that it says nothing of
// the order they were walked in, sent at most twice a minute and when the
// page is put away. No cookie, no identifier, no referrer, nothing about the
// page or the visitor; a batch that fails is dropped, never kept to send
// later.
//
// **Drawn as the ground itself worn**, never as a line laid on it: this
// answers how worn the ground is at a point (`wearAt`), through a slow wander
// and a fine breakup so that a path made of square cells has soft, uneven
// edges and no straight line anywhere, and the ground's detail
// (`wildground.js`, 2 October 2026) does the rest — the tufts thin, shorten
// and are pressed flat, and give way to bare earth, trodden paler and its
// crumb pressed together.

import { SIDE } from './wildfields.js';

// The service's grid (`WildWear::CELL`, `CELLS`), held to it by
// `tools/reference/check_wild_wear.php`: half a metre, 128 to a side.
export const CELL = 0.5;
export const CELLS = 128;

// The least wear drawn at all, in crossings: `WildWear::SEEN`, which the
// service sends; this one is for a field the workbench invents. Above the
// most one visitor can add to a cell in a day, so one visitor shows nothing.
export const SEEN = 8;

// The wear drawn as the most trodden: a little short of the most a cell can
// hold (the day's cap over a day's fading, about 260), so a path many people
// walk every day is as worn as a path can look. Between `SEEN` and this the
// ground pales by the logarithm, because footfall runs over orders of
// magnitude and a path walked twice as much is not twice as bare.
const FULL = 160;

// The service's rule, for a field the workbench invents (`WildWear.php`).
const HALF_LIFE = 30;
const CAP = 6;
const FLOOR = 0.5;

// How often a batch goes, at most, in milliseconds, and how many cells one
// may hold (`WildWear::MOST`). Half a minute keeps a visitor who walks for an
// hour without stopping under the route's limit.
const EVERY = 30000;
const MOST = 256;
// Batches waiting at once, at most: a visitor who walks faster than this
// leaves the rest of their walk unworn, which costs nothing.
const QUEUED = 4;

// A step longer than this between one look and the next is not a step: the
// window was put somewhere, not walked there.
const JUMP = 4;
// How long one press of a direction walks for, in milliseconds: the pad eases
// the window over about this long (`EASE` in `movepad.js`).
const LINGER = 700;

const mod = (a, n) => ((a % n) + n) % n;

/// The cell a point of the field is in, wrapped round the field.
export function cellOf(x, z) {
  return [mod(Math.floor(x / CELL), CELLS), mod(Math.floor(z / CELL), CELLS)];
}

/// Every cell the line from `a` to `b` crosses into, in order, wrapped — not
/// the one it starts in, which was counted on the way into it. Both points
/// are `[x, z]` in the field's unwrapped metres.
export function crossed([ax, az], [bx, bz]) {
  let i = Math.floor(ax / CELL), j = Math.floor(az / CELL);
  const ei = Math.floor(bx / CELL), ej = Math.floor(bz / CELL);
  const dx = bx - ax, dz = bz - az;
  const si = Math.sign(dx), sj = Math.sign(dz);
  const di = si ? CELL / Math.abs(dx) : Infinity, dj = sj ? CELL / Math.abs(dz) : Infinity;
  let ti = si > 0 ? ((i + 1) * CELL - ax) / dx : si < 0 ? (i * CELL - ax) / dx : Infinity;
  let tj = sj > 0 ? ((j + 1) * CELL - az) / dz : sj < 0 ? (j * CELL - az) / dz : Infinity;
  const out = [];
  for (let guard = 0; (i !== ei || j !== ej) && guard < 4 * CELLS; guard++) {
    if (ti < tj) { i += si; ti += di; } else { j += sj; tj += dj; }
    out.push([mod(i, CELLS), mod(j, CELLS)]);
  }
  return out;
}

// MARK: Walking

const MOVES = new Set(['up', 'down', 'left', 'right']);
const WALK_KEYS = new Set(['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'w', 'a', 's', 'd', 'W', 'A', 'S', 'D']);
// The pad's other keys (`movepad.js`): each of them looks rather than walks,
// so pressing one ends a walk the pad's ease is still carrying.
const LOOK_KEYS = new Set(['+', '=', '-', '0', 'Home', 'q', 'e', '[', ']', 'p', 'Q', 'E', 'P']);

/// Counts the cells the window crosses while the visitor walks, and sends
/// them now and then. `canvas` is the field's, `nav` the pad's (or any bar of
/// buttons, on the workbench). Answers `looked(point)`, which the stage calls
/// with the ground under the middle of the window whenever it moves.
export function walkOn({ canvas, nav = null, send = sendCells, every = EVERY }) {
  const pointers = new Set();
  let pressed = 0;
  let last = null;

  // A finger or the mouse's main button on the field drags it (`movepad.js`);
  // two fingers pinch, which is coming closer, not walking.
  canvas.addEventListener('pointerdown', (event) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    pointers.add(event.pointerId);
    pressed = 0;
  });
  const lifted = (event) => pointers.delete(event.pointerId);
  canvas.addEventListener('pointerup', lifted);
  canvas.addEventListener('pointercancel', lifted);
  canvas.addEventListener('lostpointercapture', lifted);
  // A press of one of the pad's four directions walks for as long as the pad
  // eases the window there; any other key of the pad's ends it.
  nav?.addEventListener('click', (event) => {
    const go = event.target.closest?.('button')?.dataset?.go;
    pressed = MOVES.has(go) ? performance.now() + LINGER : 0;
  }, true);
  window.addEventListener('keydown', (event) => {
    if (event.metaKey || event.ctrlKey || event.altKey) return;
    if (event.target?.closest?.('input, select, textarea, [contenteditable]')) return;
    if (WALK_KEYS.has(event.key)) pressed = performance.now() + LINGER;
    else if (LOOK_KEYS.has(event.key)) pressed = 0;
  }, true);
  canvas.addEventListener('click', () => { pressed = 0; });
  const walking = () => pointers.size === 1 || performance.now() < pressed;

  // The batches waiting: each a set of cell numbers, the last one filling.
  const batches = [];
  let timer = 0;
  function add([x, z]) {
    let open = batches[batches.length - 1];
    if (!open || open.size >= MOST) {
      if (batches.length >= QUEUED) return;
      open = new Set();
      batches.push(open);
    }
    open.add(z * CELLS + x);
    if (!timer) timer = setTimeout(next, every);
  }
  // Sorted, so the batch is a set of places and not a route.
  const cellsOf = (batch) => [...batch].sort((a, b) => a - b).map((n) => [n % CELLS, Math.floor(n / CELLS)]);
  function next() {
    timer = 0;
    const batch = batches.shift();
    if (batch?.size) send(cellsOf(batch));
    if (batches.length) timer = setTimeout(next, every);
  }
  // Everything waiting, when the page is put away: a walk that ended with
  // the tab is still a walk.
  function flush() {
    clearTimeout(timer);
    timer = 0;
    while (batches.length) {
      const batch = batches.shift();
      if (batch.size) send(cellsOf(batch));
    }
  }
  document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'hidden') flush(); });
  window.addEventListener('pagehide', flush);

  return {
    looked(point) {
      const here = [point[0], point[2]];
      if (last && walking()) {
        const step = Math.hypot(here[0] - last[0], here[1] - last[1]);
        if (step > 0 && step <= JUMP) for (const cell of crossed(last, here)) add(cell);
      }
      last = here;
    },
    flush,
  };
}

/// One batch to the service: the cells and nothing else. No credentials, so
/// no cookie even if the site ever set one; no referrer; never cached; let to
/// finish if the page is closing; and dropped, not retried, if it fails.
export function sendCells(cells) {
  fetch('/api/wild/wear', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ cells }),
    credentials: 'omit',
    cache: 'no-store',
    referrerPolicy: 'no-referrer',
    keepalive: true,
  }).catch(() => {});
}

// MARK: Drawing

/// The worn ground, for `makeWildStage`'s `wear`, which is the ground's
/// detail's `wear` input (`wildground.js`): GLSL defining `float wearAt(vec2
/// p)` over the field's unwrapped metres (`glsl`), the one uniform it adds
/// (`uniforms`), and the field's wear bound as a small texture — one texel a
/// cell, repeating as the field does — each time the ground, its tufts or its
/// stones are drawn (`bind`). `set(cells)` gives it the field's wear,
/// `[[x, z, wear], …]` as `GET /api/wild/wear` answers.
export function wornGround({ seen = SEEN } = {}) {
  const levels = new Float32Array(CELLS * CELLS);
  let texture = null;
  let dirty = true;
  return {
    glsl: `${WEAR_GLSL}\nfloat wearAt(vec2 p) { return wornAt(vec3(p.x, 0.0, p.y)); }`,
    uniforms: ['wear'],
    set(cells) {
      levels.fill(0);
      for (const [x, z, w] of cells ?? []) {
        if (Number.isInteger(x) && Number.isInteger(z) && x >= 0 && x < CELLS && z >= 0 && z < CELLS) {
          levels[z * CELLS + x] = trodden(w, seen);
        }
      }
      dirty = true;
    },
    bind(gl, at) {
      gl.activeTexture(gl.TEXTURE2);
      if (!texture) {
        texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
      }
      gl.bindTexture(gl.TEXTURE_2D, texture);
      // Half floats, which WebGL2 filters everywhere: eight bits would show
      // as steps along an edge read this finely.
      if (dirty) {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.R16F, CELLS, CELLS, 0, gl.RED, gl.FLOAT, levels);
        dirty = false;
      }
      gl.uniform1i(at.wear, 2);
      gl.activeTexture(gl.TEXTURE0);
    },
  };
}

/// How trodden a cell is drawn, 0 to 1, from its wear in crossings.
function trodden(wear, seen) {
  if (!(wear > seen)) return 0;
  return Math.min(1, Math.log(wear / seen) / Math.log(FULL / seen));
}

// How worn the ground is. `wornAt` reads the wear under a point — pushed
// about by a slow noise a metre and a half across, so the cells' edges
// wander, and softened over a cell, then broken up finely at the edge and a
// little in the middle, where tufts survive in any real path. Read by the
// ground, its tufts and its stones alike (`wildground.js`), which is why it is
// a point of the field and not a fragment of one shader.
const WEAR_GLSL = `
uniform sampler2D wear;
float wearHash(vec2 p) {
  vec3 q = fract(vec3(p.xyx) * 0.1031);
  q += dot(q, q.yzx + 33.33);
  return fract((q.x + q.y) * q.z);
}
float wearNoise(vec2 p) {
  vec2 i = floor(p), f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(wearHash(i), wearHash(i + vec2(1.0, 0.0)), u.x),
             mix(wearHash(i + vec2(0.0, 1.0)), wearHash(i + vec2(1.0, 1.0)), u.x), u.y);
}
// The wear between cells, read as a smooth cubic B-spline over them rather
// than straight between neighbours, which would leave every edge a run of
// short straight pieces a cell long. Four filtered reads make the sixteen.
vec4 wearCubic(float v) {
  vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
  vec4 s = n * n * n;
  float x = s.x, y = s.y - 4.0 * s.x, z = s.z - 4.0 * s.y + 6.0 * s.x;
  return vec4(x, y, z, 6.0 - x - y - z) / 6.0;
}
float wearRead(vec2 p) {
  vec2 t = p / ${CELL.toFixed(2)} - 0.5;
  vec2 f = fract(t);
  t -= f;
  vec4 xc = wearCubic(f.x), yc = wearCubic(f.y);
  vec4 c = t.xxyy + vec2(-0.5, 1.5).xyxy;
  vec4 s = vec4(xc.xz + xc.yw, yc.xz + yc.yw);
  vec4 o = (c + vec4(xc.yw, yc.yw) / s) / ${CELLS.toFixed(1)};
  float a = texture(wear, o.xz).r, b = texture(wear, o.yz).r, d = texture(wear, o.xw).r, e = texture(wear, o.yw).r;
  float sx = s.x / (s.x + s.y), sy = s.z / (s.z + s.w);
  return mix(mix(e, d, sx), mix(b, a, sx), sy);
}
float wornAt(vec3 w) {
  vec2 p = w.xz;
  p += (vec2(wearNoise(p * 0.65 + 7.31), wearNoise(p * 0.65 - 11.7)) - 0.5) * 0.7;
  float s = wearRead(p);
  if (s <= 0.002) return 0.0;
  // Where the grass gives up: a definite edge, ragged at every scale from a
  // stride down to a tuft, rather than a fade.
  float rough = wearNoise(p * 2.9) * 0.36 + wearNoise(p * 7.3 + 3.1) * 0.28
    + wearNoise(p * 19.0 - 5.7) * 0.22 + wearNoise(p * 43.0 + 1.9) * 0.14;
  float edge = smoothstep(0.13, 0.16, s + (rough - 0.5) * 0.2);
  // And how bare inside it: a faint path is grass pressed down, a busy one
  // earth, and either is mottled where some of the grass holds on, and
  // grained finely where it does not.
  float hold = wearNoise(p * 3.7 + 9.0) * 0.6 + wearNoise(p * 11.0 - 2.3) * 0.4;
  float grain = wearNoise(p * 37.0 - 4.4);
  float depth = mix(0.38, 1.0, smoothstep(0.15, 0.7, s)) * (0.62 + 0.38 * hold) * (0.88 + 0.12 * grain);
  return edge * depth;
}
`;

// MARK: Reading the field's wear

/// The field's wear from the service, or nothing if it cannot be had.
export async function wearOfField() {
  try {
    const answer = await fetch('/api/wild/wear', { credentials: 'omit', cache: 'no-store' });
    return answer.ok ? (await answer.json()).wear ?? [] : [];
  } catch {
    return [];
  }
}

// MARK: Inventing it, for the workbench

/// A summer's wear on a field nobody has walked, so it can be judged before
/// anybody has (`/dev/wild?wear=demo`). Desire lines between plants — from a
/// hub near `from` out to its neighbours, on through a few of them, and a
/// thin web of them across the rest of the field — each walked some number
/// of times a day, by walkers who wander a little either side of the line
/// and meet at its ends, with one busy line left halfway through to show it
/// fading, and a few walkers a day going wherever, who should show nothing.
/// Worn by the service's own rule: once a walker, capped a day, faded a day.
///
/// `spots` are the plants' places, `[x, z]` in metres. Answers the wear,
/// `[[x, z, wear], …]`, the hub to open over, and the lines.
export function inventWear(spots, { from = [SIDE / 2, SIDE / 2], days = 150 } = {}) {
  const near = (point, among, least = 0) => among
    .map((spot) => ({ spot, far: Math.hypot(spot[0] - point[0], spot[1] - point[1]) }))
    .filter(({ far }) => far > least)
    .sort((a, b) => a.far - b.far);
  const hub = near(from, spots)[0]?.spot ?? from;
  const around = near(hub, spots, 2.5).filter(({ far }) => far < 11).map(({ spot }) => spot);
  const lines = [];
  const line = (a, b, rate, until = days) => lines.push({ a, b, rate, until, bend: lines.length });
  // From the hub, busy to faint, and one busy line walked only until midsummer.
  [5, 3, 1.4, 0.7].forEach((rate, k) => { if (around[k]) line(hub, around[k], rate); });
  if (around[4]) line(hub, around[4], 5, Math.round(days / 3));
  // On from the two busiest, each to the next plant beyond it.
  for (const k of [0, 1]) {
    const from = around[k];
    if (!from) continue;
    const beyond = near(from, spots, 2.5).find(({ spot }) => spot !== hub && !around.slice(0, 5).includes(spot));
    if (beyond) line(from, beyond.spot, 2 - k * 0.8);
  }
  // A thin web over the rest of the field.
  for (let k = 0; k < 36; k++) {
    const a = spots[Math.floor(unit(k * 7.13) * spots.length)];
    const b = a && near(a, spots, 2.5)[1 + Math.floor(unit(k * 3.7) * 2)]?.spot;
    if (b && Math.hypot(b[0] - a[0], b[1] - a[1]) < 12) line(a, b, 0.3 + unit(k * 9.1) * 1.8);
  }

  const wear = new Float64Array(CELLS * CELLS);
  const today = new Uint8Array(CELLS * CELLS);
  const fade = 2 ** (-1 / HALF_LIFE);
  const walk = (points) => {
    const cells = new Set();
    for (let k = 1; k < points.length; k++) {
      for (const [x, z] of crossed(points[k - 1], points[k])) cells.add(z * CELLS + x);
    }
    for (const n of cells) if (today[n] < CAP) { wear[n] += 1; today[n] += 1; }
  };
  for (let day = 0; day < days; day++) {
    lines.forEach((l, k) => {
      if (day >= l.until) return;
      const walkers = Math.floor(l.rate + unit(day * 31.7 + k * 5.3));
      for (let w = 0; w < walkers; w++) walk(path(l, unit(day * 13.1 + k * 2.9 + w * 0.71)));
    });
    // Somebody going wherever: a few a day, each once, nowhere twice.
    for (let w = 0; w < 4; w++) {
      const a = [unit(day * 3.3 + w) * SIDE, unit(day * 5.9 + w * 1.3) * SIDE];
      const turn = unit(day * 7.7 + w * 2.1) * Math.PI * 2;
      walk(path({ a, b: [a[0] + Math.cos(turn) * 6, a[1] + Math.sin(turn) * 6], bend: day * 4 + w }, 0.5));
    }
    if (day < days - 1) {
      for (let n = 0; n < wear.length; n++) {
        wear[n] *= fade;
        if (wear[n] < FLOOR) wear[n] = 0;
      }
      today.fill(0);
    }
  }
  const cells = [];
  for (let n = 0; n < wear.length; n++) {
    if (wear[n] >= FLOOR) cells.push([n % CELLS, Math.floor(n / CELLS), Math.round(wear[n] * 100) / 100]);
  }
  return { wear: cells, hub, lines: lines.map(({ a, b, rate, until }) => ({ a, b, rate, until })) };
}

// One walker's way along a line: a gentle curve of the line's own, never
// straight, which the walker follows a little to one side — `side` from 0 to
// 1 — drifting back to meet the line at either end, and stopping a step short
// of each plant rather than walking through it.
function path({ a, b, bend }, side) {
  const dx = b[0] - a[0], dz = b[1] - a[1];
  const length = Math.hypot(dx, dz) || 1;
  const nx = -dz / length, nz = dx / length;
  const b1 = (unit(bend * 1.91) - 0.5) * 0.36 * length, b2 = (unit(bend * 2.73) - 0.5) * 0.36 * length;
  const wander = (side - 0.5) * 0.3;
  const wobble = unit(bend * 5.1 + side * 17) * Math.PI * 2;
  const points = [];
  const steps = Math.ceil(length / 0.1);
  const stop = Math.min(0.4, length / 4) / length;
  for (let s = 0; s <= steps; s++) {
    const t = stop + (1 - 2 * stop) * (s / steps);
    const u = 1 - t;
    // A cubic through the two ends, its middle pulled to one side or both.
    const along = [3 * u * u * t, 3 * u * t * t];
    const off = along[0] * b1 + along[1] * b2
      + Math.sin(Math.PI * t) * (wander + 0.08 * Math.sin(t * 9 + wobble));
    points.push([a[0] + dx * t + nx * off, a[1] + dz * t + nz * off]);
  }
  return points;
}

// A number from 0 to 1 that is always the same for the same `n`.
function unit(n) {
  const x = Math.sin(n * 12.9898 + 78.233) * 43758.5453;
  return x - Math.floor(x);
}
