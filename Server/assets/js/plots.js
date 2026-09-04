// Where the garden's plants come from.
//
// The plot service does not exist yet — 20i with a database on it, decided 2
// September, unbuilt. This module is the shape of the hole it will fill, and a
// stand-in that fills it well enough to walk around in.
//
// **The stand-in is marked as one and cannot be mistaken for the service.** It
// invents seeds, and every page that draws from it says so. The point of having
// it now is that the geometry in `garden.js`, the pad, and the whole keyboard
// walk can be looked at and argued about before anybody writes a schema — which
// is the cheapest moment to find out that walking a garden does not feel the
// way it read.

import { AREAS, AREA_SIZE, cellFor } from "./garden.js";

/// What a source has to answer. Three questions, all of them ordinary.
///
/// - `area(theme)` — every plant in one area.
/// - `plant(id)` — one plant.
/// - `count()` — how many there are in total, for the map.
///
/// A plant is `{ id, seed, theme, x, y, name, birth }`. `x` and `y` are derived
/// from `seed` by `cellFor` and are stored only because the service will want to
/// index on them; a source that computed them fresh every time would be equally
/// correct and slower.

/// A garden of invented plants, for looking at before there is a service.
///
/// Deterministic from `count` alone, so two people looking at the same build see
/// the same garden and can talk about it. The seeds are not real: nothing here
/// has been minted, nobody shared any of it, and a name drawn below is a
/// synthesised binomial with no person behind it.
export function demoSource({ count = 240, seed = 20260903 } = {}) {
  // A small deterministic generator, because `Math.random` cannot be seeded and
  // a garden that reshuffles on reload is not a place.
  let state = seed >>> 0;
  const next = () => {
    // xorshift32. Not for anything that matters; this draws scenery.
    state ^= state << 13; state >>>= 0;
    state ^= state >>> 17;
    state ^= state << 5; state >>>= 0;
    return state / 0x100000000;
  };
  const hex = (n) => Array.from({ length: n }, () => "0123456789abcdef"[Math.floor(next() * 16)]).join("");

  const SYLLABLES = ["ael", "wyn", "lir", "sel", "dros", "hal", "quin", "elu", "bel", "nor", "cyn", "vir"];
  const TAILS = ["ora", "ynth", "isia", "una", "ella", "inia"];
  const EPITHETS = ["nocticola", "stellifolia", "vivescens", "glacina", "pluvata", "umbrata", "ferrifolia", "cinifolia"];
  const pick = (list) => list[Math.floor(next() * list.length)];

  const plants = [];
  for (let i = 0; i < count; i += 1) {
    const s = hex(64);
    const theme = AREAS[Math.floor(next() * AREAS.length)].theme;
    const { x, y } = cellFor(s);
    plants.push({
      id: s.slice(0, 12),
      seed: s,
      theme,
      x,
      y,
      name: `${pick(SYLLABLES)}${pick(TAILS)} ${pick(EPITHETS)}`.replace(/^./, (c) => c.toUpperCase()),
      birth: new Date(Date.now() - Math.floor(next() * 400) * 86400000),
    });
  }

  const byTheme = new Map(AREAS.map((area) => [area.theme, []]));
  for (const plant of plants) byTheme.get(plant.theme).push(plant);

  return {
    /// True, and every page that uses this source has to say so.
    invented: true,
    area: async (theme) => byTheme.get(theme) ?? [],
    plant: async (id) => plants.find((p) => p.id === id) ?? null,
    count: async () => plants.length,
    counts: async () => Object.fromEntries(AREAS.map((a) => [a.theme, byTheme.get(a.theme).length])),
    all: async () => plants,
  };
}

/// The real one, when there is one.
///
/// Same origin as the pages, which is the reason the plot service was put on
/// 20i alongside them: it removes a whole class of question about where a
/// request goes and what it carries. Nothing here sends a fragment, a name or a
/// coordinate — the queries are a theme and a pair of small integers.
export function serviceSource({ base = "/api" } = {}) {
  const get = async (path) => {
    const response = await fetch(`${base}${path}`, { headers: { accept: "application/json" } });
    if (!response.ok) throw new Error(`plot service: ${response.status}`);
    return response.json();
  };
  return {
    invented: false,
    area: (theme) => get(`/area/${encodeURIComponent(theme)}`),
    plant: (id) => get(`/plant/${encodeURIComponent(id)}`),
    count: () => get("/count").then((d) => d.total),
    counts: () => get("/counts"),
    all: () => get("/all"),
  };
}

/// Whichever is available, preferring the real one.
///
/// A page asks once and is told which it got, because *the difference has to be
/// on the screen*. A garden of invented plants that does not say so is the one
/// thing this file must never become.
export async function source() {
  try {
    const live = serviceSource();
    await live.count();
    return live;
  } catch {
    return demoSource();
  }
}

export { AREA_SIZE };
