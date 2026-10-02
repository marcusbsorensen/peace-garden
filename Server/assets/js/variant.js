// Which way round a plot is laid: turned, mirrored, and which of its area's
// feature variants it takes, chosen from the plot's number. A port of
// SeedCore's `WebGardens/PlotVariant.swift`, which says why, held to it by
// `tools/reference/check_plot_variant.mjs` over the vectors the Swift records.
//
// The page needs it to draw a plot's ground the way the service placed its
// plants: a ride, a pond's outline, a bench, turned and mirrored as the places
// were. The service sends each planting's spot already turned; this is for
// everything else on the plot, and for the neighbours seen through the
// gateways.
//
// A space is { turns: 1 | 2 | 4, mirror: bool, nudges: n }, as the area
// declares it (`Coppice.variants`, `Coppice::VARIANTS`). A variant is
// { turn: 0..3, mirror: bool, nudge: n }. Thirty-two-bit integers throughout:
// `Math.imul` multiplies as Swift's `&*` does, and `>>> 0` keeps a value
// unsigned.

/// The plot as its area's tables draw it: every area's plot 0.
export const PLAIN = Object.freeze({ turn: 0, mirror: false, nudge: 0 });

/// How many variants a space holds.
export function variantCount(space) {
  return space.turns * (space.mirror ? 2 : 1) * space.nudges;
}

/// The n-th variant of a space: the turn changing fastest, then the mirror,
/// then the feature variant.
export function nthVariant(space, n) {
  const mirrors = space.mirror ? 2 : 1;
  return {
    turn: (n % space.turns) * (4 / space.turns),
    mirror: Math.floor(n / space.turns) % mirrors === 1,
    nudge: Math.floor(n / (space.turns * mirrors)),
  };
}

/// The variant of plot `plot` of the area named `area`, asked of the plant
/// module (`pg_plot_variant`), which reads the space the area declares in
/// SeedCore — so a page that has the module needs no copy of any space.
/// Null for a name that is no area.
export function variantFromModule(e, area, plot) {
  const text = new TextEncoder().encode(area);
  const pointer = e.pg_alloc(text.length);
  new Uint8Array(e.memory.buffer, pointer, text.length).set(text);
  const packed = e.pg_plot_variant(pointer, text.length, plot);
  e.pg_free(pointer);
  if (packed < 0) return null;
  return { turn: packed & 3, mirror: (packed & 4) !== 0, nudge: packed >> 3 };
}

/// The variant of plot `plot` of the area named `area` (`travel`, `renewal`),
/// from a space given here: the service's, or the plan's.
export function plotVariant(plot, area, space) {
  return dealtVariant(plot, areaSalt(area), space);
}

/// The variant of a plot from its number and a salt: dealt in shuffled
/// blocks, every variant once a block, plot 0 plain, no plot as the one
/// before it.
export function dealtVariant(plot, salt, space) {
  const count = variantCount(space);
  if (count <= 1 || plot <= 0) return nthVariant(space, 0);
  if (count === 2) return nthVariant(space, plot % 2);
  return nthVariant(space, deck(Math.floor(plot / count), count, salt)[plot % count]);
}

function deck(block, count, salt) {
  const d = shuffle(block, count, salt);
  if (block === 0) {
    const plain = d.indexOf(0);
    [d[0], d[plain]] = [d[plain], d[0]];
  } else {
    const before = block === 1
      ? deck(0, count, salt)[count - 1]
      : shuffle(block - 1, count, salt)[count - 1];
    if (d[0] === before) [d[0], d[1]] = [d[1], d[0]];
  }
  return d;
}

function shuffle(block, count, salt) {
  const d = Array.from({ length: count }, (_, i) => i);
  const start = mix32((mix32(salt) ^ block) >>> 0);
  for (let i = count - 1; i > 0; i--) {
    const j = mix32((start ^ i) >>> 0) % (i + 1);
    [d[i], d[j]] = [d[j], d[i]];
  }
  return d;
}

/// FNV-1a over an area's name.
export function areaSalt(area) {
  let hash = 0x811c9dc5;
  for (const byte of new TextEncoder().encode(area)) {
    hash = Math.imul((hash ^ byte) >>> 0, 0x01000193) >>> 0;
  }
  return hash;
}

/// Chris Wellons's lowbias32, as the Swift's `mix32`.
export function mix32(input) {
  let x = input >>> 0;
  x = (x ^ (x >>> 16)) >>> 0;
  x = Math.imul(x, 0x7feb352d) >>> 0;
  x = (x ^ (x >>> 15)) >>> 0;
  x = Math.imul(x, 0x846ca68b) >>> 0;
  x = (x ^ (x >>> 16)) >>> 0;
  return x;
}

/// Where a place in the area's table stands on this plot: mirrored, then
/// turned, about the plot's middle; a quarter turn takes x+ to z+. Exact, as
/// in the Swift. Returns [x, z]. A direction turns the same way.
export function applyVariant(variant, x, z) {
  if (variant.mirror) x = 0 - x;
  switch (variant.turn & 3) {
    case 0: return [x, z];
    case 1: return [0 - z, x];
    case 2: return [0 - x, 0 - z];
    default: return [z, 0 - x];
  }
}

/// The other way: where a point on this plot is in the area's table.
export function undoVariant(variant, x, z) {
  const [bx, bz] = applyVariant({ turn: (4 - (variant.turn & 3)) & 3, mirror: false, nudge: 0 }, x, z);
  return variant.mirror ? [0 - bx, bz] : [bx, bz];
}

/// A closed or open curve from an area's table, turned and mirrored for this
/// plot: [[x, z], ...] in, the same out. Mirroring reverses which way a loop
/// runs; a drawing that cares reverses it back.
export function applyVariantToCurve(variant, points) {
  return points.map(([x, z]) => applyVariant(variant, x, z));
}
