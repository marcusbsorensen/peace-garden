// Shadows, worked out from the triangles that cast them.
//
// **A shadow is where the thing is, seen from the sun.** Every triangle of a
// plant or a hedge is slid along the sun's direction down onto the ground and
// laid into a small grid, and each cell counts how many layers of it the sun
// has to get through. A stack of broad leaves over the stem lays three or four
// layers and comes out as a dark pool; a spindly umbel lays a few thin strokes
// that the blur then all but dissolves. The size of a plant's shadow is what it
// actually puts between the sun and the ground, not how far its widest twig
// reaches — which was the first pass's fault: a wiry plant with two long
// branches got a pool it had nothing to cast, and a dense rosette a small one.
//
// **Near the ground sharp, high up soft.** Each triangle's share is split
// between two grids by how high it is: what is low is blurred a little and
// counts fully, what is high is blurred a lot and counts for less — a contact
// shadow's look, which is what the eye reads as standing on the ground, with
// the lean of a cast shadow for where the light is.
//
// **Nothing here is a line or a circle.** The shape is the thing's own, the
// edge is a blur, and the grid is faded to nothing at its own border, so the
// square it is drawn on never shows.
//
// This file only counts; `longwalk.js` lays the answer on the ground and
// multiplies it into what is already drawn there.

/// Works out a shadow. `each(visit)` calls `visit(ax, ay, az, bx, by, bz, cx,
/// cy, cz)` once for every triangle that casts, `y` being height above the
/// surface the shadow falls on. `look` says how:
///
/// - `sun`: the direction towards the sun.
/// - `cell`: the grid's cell in metres, at most — a big footprint gets coarser
///   cells rather than more of them, up to `most` cells a side.
/// - `rect`: `[x0, z0, x1, z1]` to lay it over, and clip it to, or none for the
///   footprint's own bounds plus room for the blur.
/// - `near`, `far`: how far the low and the high layers are blurred, in
///   metres; `high` is the height by which a part has gone over to the high
///   layer, and `faint` how much a high part counts beside a low one.
/// - `layers`: how quickly layers darken towards `darkest` — the ground's
///   light lost where the most is in the way — which a pile approaches and
///   does not pass, so ten leaves are not ten times one.
///
/// Answers the grid as `loss`, how much of the ground's light is taken at each
/// cell (0–255 for 0–1), with where it lies.
export function castShadow(each, look) {
  const slide = [-look.sun[0] / look.sun[1], -look.sun[2] / look.sun[1]];

  // Where it lies: its own bounds with room for the far blur round them, or
  // the rect it was given.
  let x0, z0, x1, z1;
  if (look.rect) {
    [x0, z0, x1, z1] = look.rect;
  } else {
    x0 = z0 = Infinity; x1 = z1 = -Infinity;
    const grow = (x, y, z) => {
      const h = Math.max(0, y), px = x + slide[0] * h, pz = z + slide[1] * h;
      if (px < x0) x0 = px; if (px > x1) x1 = px;
      if (pz < z0) z0 = pz; if (pz > z1) z1 = pz;
    };
    each((ax, ay, az, bx, by, bz, cx, cy, cz) => { grow(ax, ay, az); grow(bx, by, bz); grow(cx, cy, cz); });
    if (!(x1 >= x0)) return null;
    const room = 3 * look.far + 2 * look.cell;
    x0 -= room; z0 -= room; x1 += room; z1 += room;
  }
  const cell = Math.max(look.cell, Math.max(x1 - x0, z1 - z0) / look.most);
  const w = Math.max(4, Math.ceil((x1 - x0) / cell)), h = Math.max(4, Math.ceil((z1 - z0) / cell));
  const near = new Float32Array(w * h), far = new Float32Array(w * h);
  const perCell = 1 / (cell * cell);

  // **Laying a triangle in.** One smaller than a couple of cells is spread by
  // its area over the four cells round its middle, so a thousand slivers of a
  // frond add up to the frond rather than to whichever cell centres they
  // happened to cover. A bigger one covers every cell whose middle is in it.
  each((ax, ay, az, bx, by, bz, cx, cy, cz) => {
    const ha = Math.max(0, ay), hb = Math.max(0, by), hc = Math.max(0, cy);
    const u0 = (ax + slide[0] * ha - x0) / cell, v0 = (az + slide[1] * ha - z0) / cell;
    const u1 = (bx + slide[0] * hb - x0) / cell, v1 = (bz + slide[1] * hb - z0) / cell;
    const u2 = (cx + slide[0] * hc - x0) / cell, v2 = (cz + slide[1] * hc - z0) / cell;
    const t = smooth(0, look.high, (ha + hb + hc) / 3);
    const low = 1 - t, high = t * look.faint;
    const twice = (u1 - u0) * (v2 - v0) - (u2 - u0) * (v1 - v0);
    const area = Math.abs(twice) / 2;
    if (area < 1e-9) return;
    if (area < 2) {
      const u = (u0 + u1 + u2) / 3 - 0.5, v = (v0 + v1 + v2) / 3 - 0.5;
      const i = Math.floor(u), j = Math.floor(v), fu = u - i, fv = v - j;
      for (const [di, dj, share] of [[0, 0, (1 - fu) * (1 - fv)], [1, 0, fu * (1 - fv)],
                                     [0, 1, (1 - fu) * fv], [1, 1, fu * fv]]) {
        const ii = i + di, jj = j + dj;
        if (ii < 0 || jj < 0 || ii >= w || jj >= h) continue;
        near[jj * w + ii] += low * area * share;
        far[jj * w + ii] += high * area * share;
      }
      return;
    }
    const sign = twice > 0 ? 1 : -1;
    const iMin = Math.max(0, Math.floor(Math.min(u0, u1, u2))), iMax = Math.min(w - 1, Math.ceil(Math.max(u0, u1, u2)));
    const jMin = Math.max(0, Math.floor(Math.min(v0, v1, v2))), jMax = Math.min(h - 1, Math.ceil(Math.max(v0, v1, v2)));
    for (let j = jMin; j <= jMax; j++) {
      const pv = j + 0.5;
      for (let i = iMin; i <= iMax; i++) {
        const pu = i + 0.5;
        const e0 = ((u1 - u0) * (pv - v0) - (v1 - v0) * (pu - u0)) * sign;
        const e1 = ((u2 - u1) * (pv - v1) - (v2 - v1) * (pu - u1)) * sign;
        const e2 = ((u0 - u2) * (pv - v2) - (v0 - v2) * (pu - u2)) * sign;
        if (e0 >= 0 && e1 >= 0 && e2 >= 0) { near[j * w + i] += low; far[j * w + i] += high; }
      }
    }
  });

  blur(near, w, h, Math.max(1, Math.round(look.near / cell)));
  blur(far, w, h, Math.max(1, Math.round(look.far / cell)));

  // Layers to light lost, and faded to exactly nothing over the grid's last
  // few cells, so the edge of what it is drawn on is never seen.
  const loss = new Uint8Array(w * h);
  const edge = Math.max(2, look.edge ?? 3);
  for (let j = 0; j < h; j++) {
    const fj = smooth(0, edge, Math.min(j, h - 1 - j));
    for (let i = 0; i < w; i++) {
      const fade = fj * smooth(0, edge, Math.min(i, w - 1 - i));
      const layers = near[j * w + i] + far[j * w + i];
      loss[j * w + i] = Math.round(255 * fade * look.darkest * (1 - Math.exp(-look.layers * layers)));
    }
  }
  return { x0, z0, cell, w, h, loss };
}

function smooth(a, b, v) {
  const t = Math.min(1, Math.max(0, (v - a) / (b - a)));
  return t * t * (3 - 2 * t);
}

/// Three box blurs each way, which is near enough a Gaussian and costs the same
/// whatever the radius. Nothing outside the grid is counted, so a footprint
/// blurred against its edge thins towards it rather than piling up.
function blur(grid, w, h, r) {
  const line = new Float32Array(Math.max(w, h));
  const pass = (count, length, at) => {
    for (let k = 0; k < count; k++) {
      for (let n = 0; n < 3; n++) {
        for (let i = 0; i < length; i++) line[i] = grid[at(k, i)];
        let sum = 0;
        for (let i = 0; i < r && i < length; i++) sum += line[i];
        for (let i = 0; i < length; i++) {
          if (i + r < length) sum += line[i + r];
          if (i - r - 1 >= 0) sum -= line[i - r - 1];
          grid[at(k, i)] = sum / (2 * r + 1);
        }
      }
    }
  };
  pass(h, w, (j, i) => j * w + i);
  pass(w, h, (i, j) => j * w + i);
}
