// The garden as a place with directions in it.
//
// A plant page can be arrived at from a link. A *garden* has to be walked, and
// walking needs three things this design did not have: somewhere to be, a way
// to be somewhere else, and a reason for one place to be next to another.
//
// **The reason is already in the app.** `Quotes.Theme.position` gives every
// theme a point in four dimensions — company, motion, duration, register — and
// those four were written to say what a theme *is*. Projecting them to two and
// laying the areas out on the result means the map is not decoration: walking
// right goes from the still and the long-span toward the moving and the
// momentary, walking down goes from the solitary toward the shared. Two areas
// are neighbours because the themes are neighbours.
//
// Nothing here talks to a service. It is the geometry, and it is written so it
// can be checked before the plot service exists — see `selfTest` at the foot.

/// The ten areas, laid out five by two.
///
/// Assigned by projecting the ten `Theme.position` vectors onto their first two
/// principal components — which carry 85% of the variance — and then solving
/// the assignment to grid cells that minimises total squared displacement. The
/// arithmetic is in the commit that added this file; the result is baked here
/// because a browser should not be doing a singular value decomposition to draw
/// a map, and because **the map must not move**. A garden whose areas rearrange
/// when a theme's position is tuned is a garden nobody can learn.
///
/// The first axis came out as motion minus duration, the second as company
/// almost alone. That is what the two sentences above are describing.
export const AREAS = Object.freeze([
  Object.freeze({ theme: "waiting", x: 0, y: 0 }),
  Object.freeze({ theme: "ground", x: 1, y: 0 }),
  Object.freeze({ theme: "beginnings", x: 2, y: 0 }),
  Object.freeze({ theme: "renewal", x: 3, y: 0 }),
  Object.freeze({ theme: "travel", x: 4, y: 0 }),
  Object.freeze({ theme: "peace", x: 0, y: 1 }),
  Object.freeze({ theme: "kinship", x: 1, y: 1 }),
  Object.freeze({ theme: "pattern", x: 2, y: 1 }),
  Object.freeze({ theme: "light", x: 3, y: 1 }),
  Object.freeze({ theme: "meeting", x: 4, y: 1 }),
]);

export const MAP_WIDTH = 5;
export const MAP_HEIGHT = 2;

/// How many cells an area is across. Fixed, and deliberately far larger than
/// any area will hold.
///
/// **A plant's cell is derived from its seed and never moves.** The alternative
/// — sorting an area's plants and laying them out in order — reshuffles every
/// plant after the insertion point each time somebody shares one, so a place
/// you visited yesterday is somebody else's today. Deriving the cell costs a
/// sparse grid and buys a garden that stays put.
///
/// 256 x 256 is 65,536 cells per area, 655,360 in the garden.
export const AREA_SIZE = 256;

/// Where a plant stands, from the seed alone.
///
/// Two independent slices of the seed's own hex, so x and y do not co-vary. The
/// seed is already a hash — `SeedID` is a SHA-256 digest — so there is nothing
/// to gain by hashing it again, and a second hash would be one more thing that
/// has to agree between the app, the site and the service.
///
/// **Two plants can land on one cell and that is allowed.** Resolving a
/// collision by probing would make a position depend on who arrived first,
/// which is exactly the property this function exists to avoid. A shared cell
/// is drawn as more than one plant standing together, which a garden can do and
/// a spreadsheet cannot.
export function cellFor(seedHex) {
  if (typeof seedHex !== "string" || !/^[0-9a-f]{16,}$/i.test(seedHex)) {
    throw new TypeError("a seed is at least sixteen hex characters");
  }
  const x = parseInt(seedHex.slice(0, 8), 16) % AREA_SIZE;
  const y = parseInt(seedHex.slice(8, 16), 16) % AREA_SIZE;
  return { x, y };
}

/// The area a theme names, or `null` if it names none.
export function areaFor(theme) {
  return AREAS.find((area) => area.theme === theme) ?? null;
}

export const DIRECTIONS = Object.freeze({
  up: Object.freeze({ dx: 0, dy: -1 }),
  down: Object.freeze({ dx: 0, dy: 1 }),
  left: Object.freeze({ dx: -1, dy: 0 }),
  right: Object.freeze({ dx: 1, dy: 0 }),
});

/// The area you reach by leaving this one in a direction, or `null` at the edge.
///
/// The map does not wrap. A garden you can walk off the end of is a garden with
/// an edge, which is a true thing about it and easier to hold than a torus.
export function neighbouringArea(theme, direction) {
  const from = areaFor(theme);
  const step = DIRECTIONS[direction];
  if (!from || !step) return null;
  const x = from.x + step.dx;
  const y = from.y + step.dy;
  if (x < 0 || y < 0 || x >= MAP_WIDTH || y >= MAP_HEIGHT) return null;
  return AREAS.find((area) => area.x === x && area.y === y) ?? null;
}

/// The nearest plant in a direction, within one area.
///
/// `occupied` is the area's plants as `{ x, y, … }`; the service supplies it and
/// this decides which one the pad's arrow points at. Nearest is measured along
/// the direction of travel first and sideways second, so walking right crosses
/// the area in a line rather than veering toward whatever happens to be closest
/// as the crow flies — **a walk should feel like a walk**.
///
/// Ties break on the sideways distance and then on the seed, so the same press
/// in the same place always lands on the same plant.
export function stepWithin(occupied, from, direction) {
  const step = DIRECTIONS[direction];
  if (!step) return null;
  const along = (p) => (p.x - from.x) * step.dx + (p.y - from.y) * step.dy;
  const aside = (p) => Math.abs((p.x - from.x) * step.dy - (p.y - from.y) * step.dx);

  let best = null;
  for (const plant of occupied) {
    const forward = along(plant);
    if (forward <= 0) continue;
    // A cone rather than a ray: a strict ray finds almost nothing on a sparse
    // grid, and a plant three cells over and one along is plainly "to the
    // right" to a person looking at it.
    if (aside(plant) > forward) continue;
    const rank = [forward, aside(plant), plant.seed ?? ""];
    if (!best || compare(rank, best.rank) < 0) best = { plant, rank };
  }
  return best ? best.plant : null;
}

function compare(a, b) {
  for (let i = 0; i < a.length; i += 1) {
    if (a[i] < b[i]) return -1;
    if (a[i] > b[i]) return 1;
  }
  return 0;
}

/// Somewhere else, chosen without a reason.
///
/// The wander this is for is the point of the whole feature, so it is worth
/// being honest about what "random" means here: uniform over *plants*, not over
/// areas, so a busy area comes up more often than an empty one. A garden where
/// every area is equally likely would send a visitor to the same four plants in
/// `waiting` over and over while `meeting` filled up unvisited.
export function randomPlant(occupied, random = Math.random) {
  if (!occupied.length) return null;
  return occupied[Math.floor(random() * occupied.length)];
}

/// Everything standing on one cell, in a stable order.
export function stackAt(occupied, x, y) {
  return occupied
    .filter((plant) => plant.x === x && plant.y === y)
    .sort((a, b) => String(a.seed ?? "").localeCompare(String(b.seed ?? "")));
}

/// Checks the geometry without a service, a network or a browser.
///
///     node --input-type=module -e "import('./Server/assets/js/garden.js').then(m => m.selfTest())"
export function selfTest() {
  const fail = (message) => {
    throw new Error(`garden.js: ${message}`);
  };

  if (AREAS.length !== 10) fail("ten themes, ten areas");
  const seen = new Set(AREAS.map((a) => `${a.x},${a.y}`));
  if (seen.size !== AREAS.length) fail("two areas on one cell");

  // A cell is the seed's and stays the seed's.
  const seed = "13c94f5faf1e439ececc86abb39de6df5c8effd788c1ad5fc71cf1df22a51cfb";
  const once = cellFor(seed);
  const twice = cellFor(seed);
  if (once.x !== twice.x || once.y !== twice.y) fail("a cell moved");
  if (once.x < 0 || once.x >= AREA_SIZE) fail("a cell left the area");

  // Walking off the map is walking off the map.
  if (neighbouringArea("waiting", "up") !== null) fail("the map wrapped");
  if (neighbouringArea("waiting", "left") !== null) fail("the map wrapped");
  if (neighbouringArea("waiting", "right")?.theme !== "ground") fail("wrong neighbour");
  if (neighbouringArea("waiting", "down")?.theme !== "peace") fail("wrong neighbour");
  if (neighbouringArea("meeting", "right") !== null) fail("the map wrapped");

  // A walk goes the way it was pointed.
  const plants = [
    { x: 10, y: 10, seed: "a" },
    { x: 14, y: 11, seed: "b" },
    { x: 40, y: 10, seed: "c" },
    { x: 10, y: 40, seed: "d" },
    { x: 10, y: 2, seed: "e" },
  ];
  const here = { x: 10, y: 10 };
  if (stepWithin(plants, here, "right")?.seed !== "b") fail("right went wrong");
  if (stepWithin(plants, here, "down")?.seed !== "d") fail("down went wrong");
  if (stepWithin(plants, here, "up")?.seed !== "e") fail("up went wrong");
  if (stepWithin(plants, here, "left") !== null) fail("found a plant to the left");

  // A stack is a stack.
  const stacked = stackAt([...plants, { x: 10, y: 10, seed: "z" }], 10, 10);
  if (stacked.length !== 2) fail("a stacked cell lost a plant");

  return "garden.js: every check passed";
}
