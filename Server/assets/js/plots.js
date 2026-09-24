// Where the garden's plants come from.
//
// **There is a plot service, and it does not answer these questions.** It was
// decided on 2 September and built: 20i with a database on it, holding the Long
// Walk — arrivals placed into plots of forty-eight along a path, which `/walk`
// draws. The ten themed areas below are a different garden with no table behind
// them, so this module is still the shape of a hole, and still a stand-in that
// fills it well enough to walk around in.
//
// **The stand-in is marked as one and cannot be mistaken for the service.** It
// invents seeds, and every page that draws from it says so. The point of having
// it now is that the geometry in `garden.js`, the pad, and the whole keyboard
// walk can be looked at and argued about before anybody writes a schema — which
// is the cheapest moment to find out that walking a garden does not feel the
// way it read.

import { AREAS, AREA_SIZE, cellFor } from "./garden.js";
import { GENUS_HEADS, GENUS_TAILS, placement } from "./passages.js";

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

  // **The genus is built from the real syllables, and the area is read off it.**
  // It used to draw an area and a syllable separately, from a list of its own
  // that still had `wyn` in it weeks after the app renamed it `Vin` — so a
  // plant could be drawn in *peace* under a name that files it under *kinship*,
  // and its page would then give it a passage from the wrong theme. Now the head and
  // the ending are the app's own, from `PlantName` by way of `passages.js`, and
  // `placement` decides the area exactly as it does for a real name. Only the
  // epithet is still invented here, and an epithet says nothing about either.
  //
  // One consequence, and it is the true one: a theme with three heads gets
  // half as many plants again as a theme with two, as it will in the garden.
  const EPITHETS = ["nocticola", "stellifolia", "vivescens", "glacina", "pluvata", "umbrata", "ferrifolia", "cinifolia"];
  const pick = (list) => list[Math.floor(next() * list.length)];

  const plants = [];
  for (let i = 0; i < count; i += 1) {
    const s = hex(64);
    const genus = `${pick(GENUS_HEADS)}${pick(GENUS_TAILS)}`;
    const { theme } = placement(genus);
    const { x, y } = cellFor(s);
    plants.push({
      id: s.slice(0, 12),
      seed: s,
      theme,
      x,
      y,
      name: `${genus} ${pick(EPITHETS)}`,
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

/// The garden the map draws: the stand-in, always.
///
/// **This used to ask the plot service first**, at `/api/count`, and fall back
/// to the stand-in when it was refused. The service never had that route, or
/// any of the five a whole-garden source would need — it grew one route per
/// area instead, which each area's own page reads — so every visit to `/g`
/// logged a 404 and got the stand-in anyway. Removed 24 September 2026. An open
/// area is no longer drawn here at all (`walk.js` `goTo` sends it to its page),
/// so what the stand-in covers is the areas not open yet, which is the truth.
///
/// A page is still told which it got, because *the difference has to be on the
/// screen*. A garden of invented plants that does not say so is the one thing
/// this file must never become.
export async function source() {
  return demoSource();
}

export { AREA_SIZE };
