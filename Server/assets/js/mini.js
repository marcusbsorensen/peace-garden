// **The miniatures on the gateways**: each neighbouring area's own layout,
// very simplified, laid on the slab of ground that stands for it out past the
// plot (`BESIDE` in `longwalk.js`).
//
// **Why the gateways carry these and not glyphs** (10 October 2026). For a day
// each slab carried its area's map glyph, pale and ringed, laid flat on its
// top, so a reader who could not tell a dimmed terracotta from a dimmed green
// could match a slab to its cell on the map by shape. Marcus: the mix did not
// work. A white symbol lying on ground lit and shaded like the plot beside it
// is two kinds of drawing in one picture. So a slab now shows what is
// actually there — the Knot Garden's rings of box, the Glasshouse's round
// house, the Cold Frame's kidney of water — in the plot's own light, at the
// slab's size: a neighbouring plot seen from further off, which is what a slab
// always said it was. Shape still carries identity, because the ten layouts
// differ by shape. The map's glyphs stay symbols (28 September): a map is a
// diagram and the view is not.
//
// **Read from the area's own plan, never drawn again by hand.** Each area's
// module says what its miniature is (`miniature`, beside its `plan`), from the
// same plan export and the same place table its own page draws from, so a
// miniature cannot come to disagree with the plot it stands for. This file is
// only the few kinds of shape they are laid with:
//
// - `patch`: a flat piece of ground of its own colour — a pond, a glade, a
//   round of paving, a drift — filled from a point that sees its whole edge,
//   paler or darker at its rim if it says so (`rim`), as water is.
// - `ribbon`: a strip along a line — a ride, a drill, a mown way, a rill —
//   its width breathing and its ends rounded.
// - `ridge`: a raised run along a line, soft-shouldered — box, yew, a raised
//   bed — its top undulating and its faces bulging as `Organic.hedge`'s do.
// - `house`: a round house — the Glasshouse — its wall going up from a
//   wandering foot, its dome on the eaves, its ribs painted on.
// - `tree`: a trunk and a lumpy crown, flat-shaded, as the Orchard's are.
// - `box`: a low box with a sloping lid and softened corners — a cold frame,
//   a bench.
//
// Plants are left out. A slab is a few hundred pixels at most, and a plant at
// half a plot's size is a speck that says nothing about which area it is.
//
// **No straight lines.** Every edge here wanders a little by a seeded noise,
// as every edge in the garden does, so a miniature is the same shape on every
// visit and on every device.
//
// **Cheap, and made once.** A miniature is a few thousand triangles, laid
// when the page says where it stands and kept; a turn re-lays only the two
// that depend on where the eye is (the Long Walk's yew and the Quiet Garden's
// hedges are tall on the far side and low on the near), and keeps those too.

/// Where each area's miniature is said, by theme: that area's own module,
/// loaded only when a page has it beside it. Named rather than imported, so
/// `check_gateways.mjs` can read that each one says it.
export const MINIATURES = Object.freeze({
  travel: './longwalk.js',
  peace: './quietgarden.js',
  meeting: './crossing.js',
  kinship: './orchard.js',
  pattern: './knot.js',
  beginnings: './seedbed.js',
  waiting: './frame.js',
  light: './glasshouse.js',
  renewal: './coppice.js',
  ground: './ground.js',
});

/// **What an area's miniature is**, as its own module says it from its own
/// plan: `{ floor, shapes }`, the colour its ground is and the shapes on it —
/// or, where they depend on where the eye is, a function of the eye that
/// answers them. Null for an area with no miniature.
export async function miniatureOf(e, theme) {
  const file = MINIATURES[theme];
  if (!file) return null;
  const module = await import(file);
  return module.miniature ? module.miniature(e) : null;
}

/// The shapes of a miniature, in plot metres with y up, laid as one mesh at
/// `scale`. `keep` takes a point in plot metres onto the slab's own wandering
/// outline (`keepToPlot`), so nothing overhangs it.
export function layMiniature(shapes, { keep = (x, z) => [x, z], scale = 1 } = {}) {
  const positions = [], normals = [], colours = [];
  const vertex = (p, n, c) => {
    positions.push(p[0] * scale, p[1] * scale, p[2] * scale);
    normals.push(...n);
    colours.push(...c);
  };
  const lay = { vertex, keep };
  for (const [k, shape] of shapes.entries()) {
    const seed = shape.seed ?? 97 + k * 131;
    if (shape.kind === 'patch') patch(lay, shape, seed);
    else if (shape.kind === 'ribbon') ribbon(lay, shape, seed);
    else if (shape.kind === 'ridge') ridge(lay, shape, seed);
    else if (shape.kind === 'house') house(lay, shape, seed);
    else if (shape.kind === 'tree') tree(lay, shape, seed);
    else if (shape.kind === 'box') box(lay, shape, seed);
  }
  return { positions: new Float32Array(positions), normals: new Float32Array(normals), colours: new Float32Array(colours) };
}

/// A round as a closed line, `n` points round, for the shapes that are round:
/// wandering off its true circle by a few per cent, as a dug pond or a laid
/// basin does (`raiseTrough`'s `round`), the same way on every visit.
export function circle([x, z], r, n = 40) {
  const seed = Math.round((x * 131 + z * 71 + r * 37) * 100);
  return Array.from({ length: n }, (_, i) => {
    const a = (i / n) * 2 * Math.PI;
    // Round the loop's own length, so the wander comes back to where it began.
    const k = i / n * 6, j = Math.floor(k), f = k - j, w = f * f * (3 - 2 * f);
    const at = (m) => hash((m % 6) * 7.31 + seed * 0.0131) * 2 - 1;
    const wobble = 1 + 0.03 * (at(j) + (at(j + 1) - at(j)) * w);
    return [x + r * wobble * Math.cos(a), z + r * wobble * Math.sin(a)];
  });
}

/// **A round basin of stone with water in it**, as `raiseTrough` stands one:
/// `across` wide over its wall, `height` to its lip, the water a hand under
/// the lip. Two shapes, a ring and the water inside it. `stone` and `water`
/// are the stage's own colours (`COLOUR` in `longwalk.js`), passed in, since
/// this file reads nothing of the stage's.
export function basin(at, across, height, { stone, depths, shallows }) {
  const wall = 0.07;
  return [
    { kind: 'ridge', line: circle(at, across / 2 - wall / 2), closed: true, half: wall / 2 * 1.4, height, colour: stone },
    { kind: 'patch', loop: circle(at, across / 2 - wall), colour: depths, rim: shallows, rise: Math.max(0.006, height - 0.06) },
  ];
}

/// A colour taken lighter or darker by `k`.
export const tone = (colour, k) => colour.map((v) => v * k);

const UP = [0, 1, 0];

// MARK: - The shapes

/// **A flat piece of ground of its own colour**, laid `rise` over the slab's
/// top, filled from `at` — a point that sees the whole of its edge, as a dish
/// falling to it does — or from its middle. `rim`, if given, is the colour at
/// its edge, eased into `colour` a third of the way in: shallows round deep
/// water.
function patch({ vertex, keep }, { loop, at = null, colour, rim = colour, rise = 0.006 }, seed) {
  const edge = resample(loop, true, 0.07, 96).map(([x, z]) => keep(x, z));
  const [cx, cz] = at ?? middle(edge);
  const n = edge.length;
  const inner = edge.map(([x, z]) => [cx + (x - cx) * 0.66, cz + (z - cz) * 0.66]);
  const centre = [cx, rise, cz];
  const lift = ([x, z]) => [x, rise, z];
  const mottle = (i) => 0.96 + 0.08 * noise(seed, i * 0.37);
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    const ci = tone(colour, mottle(i)), cj = tone(colour, mottle(j));
    tri3(vertex, centre, lift(inner[i]), lift(inner[j]), UP, colour, ci, cj);
    tri3(vertex, lift(inner[i]), lift(edge[i]), lift(edge[j]), UP, ci, rim, rim);
    tri3(vertex, lift(inner[i]), lift(edge[j]), lift(inner[j]), UP, ci, rim, cj);
  }
}

/// **A strip along a line**, `half` either side of it and `rise` over the
/// slab's top: its width breathing by a tenth and each edge wandering a
/// couple of centimetres, its ends rounded unless it is `closed`. A `corner`
/// squares its ends off to a bed's, rounded that much at each corner, inside
/// the line's own length rather than past it.
function ribbon({ vertex, keep }, { line, half, colour, rise = 0.008, closed = false, corner = null }, seed) {
  let pts = resample(line, closed, 0.06, 400);
  if (corner && !closed) pts = trim(pts, corner);
  const n = pts.length;
  if (n < 2) return;
  const along = lengths(pts, closed);
  const left = [], right = [];
  for (let i = 0; i < n; i++) {
    const [sx, sz] = sideOf(pts, i, closed);
    const breathe = half * (1 + 0.1 * noise(seed, along[i] * 1.1));
    const l = breathe + 0.02 * noise(seed + 7, along[i] * 1.7);
    const r = breathe + 0.02 * noise(seed + 13, along[i] * 1.7);
    left.push(keep(pts[i][0] + sx * l, pts[i][1] + sz * l));
    right.push(keep(pts[i][0] - sx * r, pts[i][1] - sz * r));
  }
  const at = (p) => [p[0], rise, p[1]];
  const shade = (i) => tone(colour, 0.95 + 0.1 * (0.5 + 0.5 * noise(seed + 29, along[i] * 2.3)));
  const spans = closed ? n : n - 1;
  for (let i = 0; i < spans; i++) {
    const j = (i + 1) % n;
    tri3(vertex, at(left[i]), at(left[j]), at(right[j]), UP, shade(i), shade(j), shade(j));
    tri3(vertex, at(left[i]), at(right[j]), at(right[i]), UP, shade(i), shade(j), shade(i));
  }
  if (closed) return;
  // Each end rounded with a fan: from the left edge, out past the end, round
  // to the right — a half round, or with a `corner` a squared end, its
  // corners rounded (a superellipse, so the end itself still bows).
  const steps = corner ? 10 : 6;
  for (const [end, toward] of [[0, 1], [n - 1, n - 2]]) {
    const [x, z] = pts[end];
    const dx = x - pts[toward][0], dz = z - pts[toward][1], dl = Math.hypot(dx, dz) || 1;
    const ox = dx / dl, oz = dz / dl;
    const lx = left[end][0] - x, lz = left[end][1] - z;
    const w = (Math.hypot(lx, lz) + Math.hypot(right[end][0] - x, right[end][1] - z)) / 2;
    const ll = Math.hypot(lx, lz) || 1;
    const out = corner ?? w;
    const fan = [];
    for (let k = 0; k <= steps; k++) {
      const t = (k / steps) * Math.PI;
      const c = Math.cos(t), s = Math.sin(t);
      const squared = corner ? 1 / Math.pow(Math.abs(c) ** 4 + s ** 4, 0.25) : 1;
      fan.push(keep(x + (c * w * lx / ll + s * out * ox) * squared, z + (c * w * lz / ll + s * out * oz) * squared));
    }
    const hub = keep(x, z);
    for (let k = 0; k < steps; k++) tri3(vertex, at(hub), at(fan[k]), at(fan[k + 1]), UP, shade(end), shade(end), shade(end));
  }
}

/// **A raised run along a line**: `Organic.section` swept along it at a
/// handful of points round, `half` wide either side and `height` tall, its
/// top undulating by a twentieth and its faces bulging where it has grown, as
/// the Knot's box and the walk's yew do. Darker at its foot, where it shades
/// itself. Closed runs meet themselves; open ones are capped.
function ridge({ vertex, keep }, { line, half, height, colour, closed = false, step = 0.14, around = 8 }, seed) {
  const pts = resample(line, closed, step, 300);
  const n = pts.length;
  if (n < 2) return;
  const along = lengths(pts, closed);
  // Each point of the section is kept to the slab rather than the line, so a
  // run near the edge is pressed against it, as `hedgeToPlot` presses a
  // plot's own, rather than hanging out over the sky.
  const rings = pts.map((p, i) => {
    const [sx, sz] = sideOf(pts, i, closed);
    const width = half * (1 + 0.06 * noise(seed, along[i] * 2.1));
    const top = height * (1 + 0.06 * noise(seed + 3, along[i] * 1.3));
    const ring = [];
    for (let k = 0; k <= around; k++) {
      const [ox, oy, nx, ny] = section(k / around, width, top);
      const bulge = oy === 0 ? 1 : 1 + 0.04 * noise(seed + 11 + k, along[i] * 2.7);
      const [x, z] = keep(p[0] + sx * ox * bulge, p[1] + sz * ox * bulge);
      ring.push({ p: [x, oy, z], n: [sx * nx, ny, sz * nx] });
    }
    return ring;
  });
  const shade = (q) => tone(colour, (0.72 + 0.34 * Math.min(1, q.p[1] / Math.max(height, 0.01)))
    * (0.95 + 0.1 * hash(Math.round(q.p[0] * 23) * 131 + Math.round(q.p[2] * 23) + seed)));
  const spans = closed ? n : n - 1;
  for (let i = 0; i < spans; i++) {
    const r0 = rings[i], r1 = rings[(i + 1) % n];
    for (let k = 0; k < around; k++) {
      const a = r0[k], b = r0[k + 1], c = r1[k], d = r1[k + 1];
      for (const v of [a, b, c, b, d, c]) vertex(v.p, v.n, shade(v));
    }
  }
  if (closed) return;
  for (const [end, sign] of [[0, -1], [n - 1, 1]]) {
    const ring = rings[end];
    const [tx, tz] = tangentOf(pts, end, false);
    const mid = ring.reduce((m, v) => [m[0] + v.p[0] / ring.length, m[1] + v.p[1] / ring.length, m[2] + v.p[2] / ring.length], [0, 0, 0]);
    const nn = [tx * sign, 0, tz * sign];
    for (let k = 0; k < around; k++) {
      vertex(mid, nn, shade({ p: mid }));
      vertex(ring[k].p, nn, shade(ring[k]));
      vertex(ring[k + 1].p, nn, shade(ring[k + 1]));
    }
  }
}

/// **A round house**: a wall standing on a foot `radiusAt(turn)` out from
/// `at` all the way round, `eaves` high, and a dome on it to `crown`. The
/// panes are `colour` — the house's inside seen through its glass — and
/// `ribs` of them, and the eaves, are painted `rib`, as its frame stands.
function house({ vertex }, { at = [0, 0], radiusAt, eaves, crown, colour, rib, ribs = 16 }, seed) {
  const round = ribs * 6;
  const caps = 6;
  const h = crown - eaves;
  // Rows up the house: the foot, the eaves, and the dome's rings to the top.
  const rows = [{ y: 0, f: 1, up: 0 }, { y: eaves * 0.94, f: 1, up: 0 }, { y: eaves, f: 1, up: 0.05 }];
  for (let k = 1; k <= caps; k++) {
    const phi = (k / caps) * Math.PI / 2;
    rows.push({ y: eaves + h * Math.sin(phi), f: Math.cos(phi), up: phi });
  }
  const point = (row, j) => {
    const turn = j / round;
    const a = turn * 2 * Math.PI;
    const r = radiusAt(turn) * row.f;
    return [at[0] + r * Math.cos(a), row.y, at[1] + r * Math.sin(a)];
  };
  const normal = (row, j) => {
    const a = (j / round) * 2 * Math.PI;
    const r = radiusAt(j / round);
    // The dome as an ellipse in its own section: across by the radius, up by
    // the rise from the eaves to the crown.
    const c = Math.cos(row.up) / r, s = Math.sin(row.up) / Math.max(h, 0.01);
    const l = Math.hypot(c, s) || 1;
    return [Math.cos(a) * c / l, s / l, Math.sin(a) * c / l];
  };
  const isRib = (j) => j % (round / ribs) === 0;
  for (let r = 0; r + 1 < rows.length; r++) {
    const lower = rows[r], upper = rows[r + 1];
    for (let j = 0; j < round; j++) {
      const a = point(lower, j), b = point(lower, j + 1), c = point(upper, j + 1), d = point(upper, j);
      // The eaves band and the ribs are the frame; the rest is glass.
      const frame = r === 1 || isRib(j);
      const base = frame ? rib : colour;
      const k = 0.94 + 0.12 * hash(j * 31 + r * 7 + seed);
      const c0 = tone(base, k);
      vertex(a, normal(lower, j), c0); vertex(b, normal(lower, j + 1), c0); vertex(c, normal(upper, j + 1), c0);
      vertex(a, normal(lower, j), c0); vertex(c, normal(upper, j + 1), c0); vertex(d, normal(upper, j), c0);
    }
  }
}

/// **A tree**: a trunk tapering up into a crown, the crown a lumpy ball
/// flat-shaded a face at a time — the Orchard's finding, that one normal a
/// triangle reads as clumps of leaves and smooth normals as a balloon — and
/// darker underneath, where its own leaves shade it.
function tree({ vertex }, { at, trunk, base, tall, wide, leaf, bark }, seed) {
  const [x, z] = at;
  // The trunk: six sides, up into the crown.
  const sides = 6;
  const top = base + (tall - base) * 0.3;
  for (let k = 0; k < sides; k++) {
    const a0 = (k / sides) * 2 * Math.PI, a1 = ((k + 1) / sides) * 2 * Math.PI;
    const p = (a, r, y) => [x + r * Math.cos(a), y, z + r * Math.sin(a)];
    const n0 = [Math.cos(a0), 0, Math.sin(a0)], n1 = [Math.cos(a1), 0, Math.sin(a1)];
    const foot = tone(bark, 0.85), head = tone(bark, 1.05);
    vertex(p(a0, trunk, 0), n0, foot); vertex(p(a1, trunk, 0), n1, foot); vertex(p(a1, trunk * 0.6, top), n1, head);
    vertex(p(a0, trunk, 0), n0, foot); vertex(p(a1, trunk * 0.6, top), n1, head); vertex(p(a0, trunk * 0.6, top), n0, head);
  }
  // The crown: a ball of rings, each point pushed in or out a little.
  const lat = 6, lon = 10;
  const cy = (base + tall) / 2, ry = (tall - base) / 2, rx = wide / 2;
  const grid = [];
  for (let i = 0; i <= lat; i++) {
    const phi = -Math.PI / 2 + (i / lat) * Math.PI;
    const row = [];
    for (let j = 0; j < lon; j++) {
      const a = (j / lon) * 2 * Math.PI + (i % 2) * Math.PI / lon;
      const lump = (i === 0 || i === lat) ? 1 : 1 + 0.16 * (hash(i * 37 + j * 11 + seed) - 0.5) * 2;
      row.push([x + rx * lump * Math.cos(phi) * Math.cos(a), cy + ry * lump * Math.sin(phi), z + rx * lump * Math.cos(phi) * Math.sin(a)]);
    }
    grid.push(row);
  }
  const face = (a, b, c) => {
    const u = [b[0] - a[0], b[1] - a[1], b[2] - a[2]], w = [c[0] - a[0], c[1] - a[1], c[2] - a[2]];
    let nn = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]];
    const l = Math.hypot(...nn) || 1;
    nn = nn.map((v) => v / l);
    // Outward: away from the crown's middle.
    const m = [(a[0] + b[0] + c[0]) / 3 - x, (a[1] + b[1] + c[1]) / 3 - cy, (a[2] + b[2] + c[2]) / 3 - z];
    if (nn[0] * m[0] + nn[1] * m[1] + nn[2] * m[2] < 0) nn = nn.map((v) => -v);
    const height = Math.min(1, Math.max(0, ((a[1] + b[1] + c[1]) / 3 - base) / Math.max(0.3, tall - base)));
    const colour = tone(leaf, 0.74 + 0.34 * height);
    vertex(a, nn, colour); vertex(b, nn, colour); vertex(c, nn, colour);
  };
  for (let i = 0; i < lat; i++) {
    for (let j = 0; j < lon; j++) {
      const a = grid[i][j], b = grid[i][(j + 1) % lon], c = grid[i + 1][(j + 1) % lon], d = grid[i + 1][j];
      face(a, b, c);
      face(a, c, d);
    }
  }
}

/// **A low box with a sloping lid**: `size` across and deep, turned `angle`
/// about `at`, its back `back` high and its front `front`, its corners
/// rounded and its sides bulging by a centimetre, so not one edge of it is
/// ruled. The sides are `colour` and the lid `top`, with `bars` across it
/// from back to front if it has them — a frame's glazing bars.
function box({ vertex }, { at, size: [sx, sz], angle = 0, back, front, colour, top, bars = null }, seed) {
  const c = Math.cos(angle), s = Math.sin(angle);
  const place = (u, v) => [at[0] + u * c - v * s, at[1] + u * s + v * c];
  const corner = Math.min(sx, sz) * 0.07;
  const hx = sx / 2 - corner, hz = sz / 2 - corner;
  // Round the footprint: four arcs and the sides between, each side bowed.
  const loop = [];
  const centres = [[hx, -hz], [hx, hz], [-hx, hz], [-hx, -hz]];
  centres.forEach(([ux, vz], q) => {
    for (let k = 0; k <= 3; k++) {
      const a = -Math.PI / 2 + (q + k / 3) * Math.PI / 2;
      loop.push([ux + corner * Math.cos(a), vz + corner * Math.sin(a)]);
    }
    // The side from this corner to the next, bowed out a little.
    const [nx, nz] = centres[(q + 1) % 4];
    const out = -Math.PI / 2 + (q + 1) * Math.PI / 2;
    for (let k = 1; k < 4; k++) {
      const t = k / 4, bow = 0.012 * Math.sin(t * Math.PI) * (1 + 0.5 * noise(seed, q * 3 + t));
      loop.push([ux + (nx - ux) * t + (corner + bow) * Math.cos(out), vz + (nz - vz) * t + (corner + bow) * Math.sin(out)]);
    }
  });
  const height = (v) => back + (front - back) * (v / sz + 0.5);
  const n = loop.length;
  for (let i = 0; i < n; i++) {
    const [u0, v0] = loop[i], [u1, v1] = loop[(i + 1) % n];
    const [x0, z0] = place(u0, v0), [x1, z1] = place(u1, v1);
    const ex = x1 - x0, ez = z1 - z0, el = Math.hypot(ex, ez) || 1;
    const nn = [ez / el, 0, -ex / el];
    const y0 = height(v0), y1 = height(v1);
    const foot = tone(colour, 0.82), head = colour;
    vertex([x0, 0, z0], nn, foot); vertex([x1, y1, z1], nn, head); vertex([x1, 0, z1], nn, foot);
    vertex([x0, 0, z0], nn, foot); vertex([x0, y0, z0], nn, head); vertex([x1, y1, z1], nn, head);
  }
  // The lid, a fan from its middle, tilted with the slope.
  const tilt = (front - back) / sz;
  const ln = [s * tilt, 1, -c * tilt];
  const ll = Math.hypot(...ln);
  const lidN = ln.map((v) => v / ll);
  const [mx, mz] = place(0, 0);
  const mid = [mx, height(0), mz];
  for (let i = 0; i < n; i++) {
    const [u0, v0] = loop[i], [u1, v1] = loop[(i + 1) % n];
    const [x0, z0] = place(u0, v0), [x1, z1] = place(u1, v1);
    vertex(mid, lidN, top); vertex([x1, height(v1), z1], lidN, top); vertex([x0, height(v0), z0], lidN, top);
  }
  if (!bars) return;
  // The bars, a hair over the lid, each bowing by a few millimetres.
  for (let k = 0; k < bars.count; k++) {
    const u = -sx / 2 + (sx * (k + 0.5)) / bars.count;
    const steps = 4;
    for (let j = 0; j < steps; j++) {
      const va = -sz / 2 + (sz * j) / steps, vb = -sz / 2 + (sz * (j + 1)) / steps;
      const bow = (v) => 0.004 * Math.sin(((v / sz) + 0.5) * Math.PI) * (1 + noise(seed + k, k * 0.7));
      const lift = (u2, v) => { const [x, z] = place(u2 + bow(v), v); return [x, height(v) + 0.008, z]; };
      const w = bars.width / 2;
      vertex(lift(u - w, va), lidN, bars.colour); vertex(lift(u + w, va), lidN, bars.colour); vertex(lift(u + w, vb), lidN, bars.colour);
      vertex(lift(u - w, va), lidN, bars.colour); vertex(lift(u + w, vb), lidN, bars.colour); vertex(lift(u - w, vb), lidN, bars.colour);
    }
  }
}

// MARK: - Lines

/// A line taken to points about `step` apart, and no more than `most` of
/// them: what the table lays at a centimetre or two, a miniature needs at a
/// hand's breadth.
function resample(line, closed, step, most) {
  const pts = closed ? [...line, line[0]] : line;
  const along = [0];
  for (let i = 1; i < pts.length; i++) along.push(along[i - 1] + Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]));
  const total = along[along.length - 1];
  if (total <= 0) return line.slice();
  const count = Math.max(closed ? 8 : 2, Math.min(most, Math.round(total / step) + (closed ? 0 : 1)));
  const out = [];
  let i = 1;
  for (let k = 0; k < count; k++) {
    const s = closed ? (k / count) * total : (k / (count - 1)) * total;
    while (i < pts.length - 1 && along[i] < s) i++;
    const t = (s - along[i - 1]) / (along[i] - along[i - 1] || 1);
    out.push([pts[i - 1][0] + (pts[i][0] - pts[i - 1][0]) * t, pts[i - 1][1] + (pts[i][1] - pts[i - 1][1]) * t]);
  }
  return out;
}

/// An open line with `d` taken off each end.
function trim(pts, d) {
  const along = lengths(pts, false);
  const total = along[along.length - 1];
  if (total <= 2 * d) return pts.slice(0, 1);
  const at = (s) => {
    let i = 1;
    while (i < pts.length - 1 && along[i] < s) i++;
    const t = (s - along[i - 1]) / (along[i] - along[i - 1] || 1);
    return [pts[i - 1][0] + (pts[i][0] - pts[i - 1][0]) * t, pts[i - 1][1] + (pts[i][1] - pts[i - 1][1]) * t];
  };
  return [at(d), ...pts.filter((_, i) => along[i] > d && along[i] < total - d), at(total - d)];
}

function lengths(pts, closed) {
  const along = [0];
  for (let i = 1; i < pts.length; i++) along.push(along[i - 1] + Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]));
  return along;
}

function tangentOf(pts, i, closed) {
  const n = pts.length;
  const a = closed ? pts[(i - 1 + n) % n] : pts[Math.max(0, i - 1)];
  const b = closed ? pts[(i + 1) % n] : pts[Math.min(n - 1, i + 1)];
  const tx = b[0] - a[0], tz = b[1] - a[1], l = Math.hypot(tx, tz) || 1;
  return [tx / l, tz / l];
}

/// The line's direction turned a quarter back, as `Organic.hedge` has x+
/// beside a run along z+.
function sideOf(pts, i, closed) {
  const [tx, tz] = tangentOf(pts, i, closed);
  return [tz, -tx];
}

function middle(loop) {
  let x = 0, z = 0;
  for (const p of loop) { x += p[0]; z += p[1]; }
  return [x / loop.length, z / loop.length];
}

/// `Organic.section`, as `knot.js` sweeps it: a point round a hedge's
/// cross-section, `t` from the ground on one face, up, round the shoulder,
/// across the top and down the other; and the outward normal there.
function section(t, halfWidth, height) {
  const shoulder = Math.min(halfWidth * 0.8, height * 0.4);
  const side = height - shoulder;
  const across = 2 * (halfWidth - shoulder);
  const arc = Math.PI / 2 * shoulder;
  const total = 2 * side + 2 * arc + across;
  let p = t * total;
  if (p <= side) return [halfWidth, p, 1, 0];
  p -= side;
  if (p <= arc) {
    const a = p / shoulder, c = Math.cos(a), s = Math.sin(a);
    return [halfWidth - shoulder + shoulder * c, side + shoulder * s, c, s];
  }
  p -= arc;
  if (p <= across) return [halfWidth - shoulder - p, height, 0, 1];
  p -= across;
  if (p <= arc) {
    const a = p / shoulder, c = Math.cos(a), s = Math.sin(a);
    return [-(halfWidth - shoulder) - shoulder * s, side + shoulder * c, -s, c];
  }
  p -= arc;
  return [-halfWidth, Math.max(0, side - p), -1, 0];
}

// MARK: - Noise

function hash(n) {
  const x = Math.sin(n * 12.9898) * 43758.5453;
  return x - Math.floor(x);
}

/// Smooth value noise along a line, -1 to 1, a cell every 35 cm.
function noise(seed, s) {
  const t = s / 0.35;
  const i = Math.floor(t), f = t - i, w = f * f * (3 - 2 * f);
  const at = (k) => hash(k * 7.31 + seed * 0.0131) * 2 - 1;
  return at(i) + (at(i + 1) - at(i)) * w;
}

function tri3(vertex, a, b, c, n, ca, cb, cc) {
  vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc);
}
