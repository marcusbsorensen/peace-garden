// Walking the garden: the map, an area, a plant, and the keyboard through all
// three.
//
// The state lives in the fragment — `#`, `#waiting`, `#waiting/1a2b3c` — so the
// back button walks backwards, a place can be linked to, and nothing about
// where somebody is standing goes to the origin in a query string. That is the
// same property `/s` guards for the seed payload, kept here for the same
// reason: a fragment is the one part of a URL a server never sees.
//
// **Every action is registered with `keys.js` rather than wired to a listener**,
// so `?` lists all of them and the sheet cannot fall behind. Rows in that sheet
// are labelled by the controls below, which is why the pad's buttons carry real
// `aria-label`s rather than being four unnamed arrows.

import { AREAS, areaFor, neighbouringArea, randomPlant, stepWithin } from "./garden.js";
import { register, setSheetTitle } from "./keys.js";
import { loadStrings } from "./strings.js";
import { source } from "./plots.js";

const el = (id) => document.getElementById(id);

const state = { plots: null, where: { area: null, plant: null }, cache: new Map() };

/// The area names are English and stay English — see docs/FOR-REVIEW.md §2 for
/// the argument, which is the one the app already makes about plant names: a
/// proper noun travels better than a translation of one. If Marcus decides
/// otherwise these become catalogue keys and this table goes away.
const AREA_NAMES = {
  waiting: "The Cold Frame",
  ground: "The Root Ground",
  beginnings: "The Seedbed",
  renewal: "The Coppice",
  travel: "The Long Walk",
  peace: "The Quiet Garden",
  kinship: "The Orchard",
  pattern: "The Knot Garden",
  light: "The Glasshouse",
  meeting: "The Crossing",
};

async function plantsIn(theme) {
  if (!state.cache.has(theme)) state.cache.set(theme, await state.plots.area(theme));
  return state.cache.get(theme);
}

// MARK: - Where we are

function readFragment() {
  const [area, plant] = decodeURIComponent(location.hash.slice(1)).split("/");
  state.where = {
    area: areaFor(area) ? area : null,
    plant: plant || null,
  };
}

function goTo(area, plant) {
  const next = [area, plant].filter(Boolean).map(encodeURIComponent).join("/");
  location.hash = next ? `#${next}` : "";
}

// MARK: - Drawing

function drawMap(counts) {
  const grid = el("map-grid");
  if (grid.childElementCount) return;
  for (const area of AREAS) {
    const cell = document.createElement("button");
    cell.type = "button";
    cell.className = "garden-cell";
    cell.style.gridColumn = String(area.x + 1);
    cell.style.gridRow = String(area.y + 1);
    cell.dataset.theme = area.theme;

    const name = document.createElement("span");
    name.className = "garden-cell__name";
    name.textContent = AREA_NAMES[area.theme];

    // How full an area is, drawn rather than counted out in a language. A
    // number here would be a string; a row of dots is the same fact and travels
    // everywhere. The count is on the label for anybody listening rather than
    // looking.
    const fill = document.createElement("span");
    fill.className = "garden-cell__fill";
    fill.style.setProperty("--fill", String(Math.min(1, (counts[area.theme] ?? 0) / 40)));

    cell.append(name, fill);
    cell.setAttribute("aria-label", `${AREA_NAMES[area.theme]}, ${counts[area.theme] ?? 0}`);
    cell.addEventListener("click", () => goTo(area.theme));
    grid.append(cell);
  }
}

async function drawArea(theme) {
  el("area-name").textContent = AREA_NAMES[theme];
  const plot = el("area-plot");
  const plants = await plantsIn(theme);
  plot.replaceChildren();
  // The area's 256 cells across are drawn as a proportional field rather than a
  // grid of boxes: a plant's position is its position, and quantising it to a
  // few columns for the sake of a tidy layout would throw away the thing the
  // pad steps through.
  for (const plant of plants) {
    const dot = document.createElement("button");
    dot.type = "button";
    dot.className = "plot-plant";
    dot.style.insetInlineStart = `${(plant.x / 256) * 100}%`;
    dot.style.insetBlockStart = `${(plant.y / 256) * 100}%`;
    dot.setAttribute("aria-label", plant.name);
    dot.addEventListener("click", () => goTo(theme, plant.id));
    plot.append(dot);
  }
  plot.setAttribute("aria-label", `${AREA_NAMES[theme]}, ${plants.length}`);
}

async function drawPlant(theme, id) {
  const plant = (await plantsIn(theme)).find((p) => p.id === id);
  if (!plant) return goTo(theme);
  el("plant-name").textContent = plant.name;
  el("plant-where").textContent = AREA_NAMES[theme];

  // A direction with nothing in it is disabled rather than hidden: the pad is a
  // fixed shape, and an arrow that comes and goes is a pad that moves under the
  // hand. Its absence is said in the disabled state instead.
  const plants = await plantsIn(theme);
  for (const key of el("pad").querySelectorAll("[data-go]")) {
    const direction = key.dataset.go;
    key.disabled = !stepWithin(plants, plant, direction) && !neighbouringArea(theme, direction);
    key.onclick = () => walk(direction);
  }
  return undefined;
}

async function render() {
  const { area, plant } = state.where;
  el("map").hidden = Boolean(area);
  el("area").hidden = !area || Boolean(plant);
  el("plant").hidden = !plant;

  if (!area) return drawMap(await state.plots.counts());
  if (!plant) return drawArea(area);
  return drawPlant(area, plant);
}

// MARK: - Walking

/// One step. Within the area if there is anything that way, into the next area
/// if there is not, and nowhere at the edge of the map.
async function walk(direction) {
  const { area, plant: id } = state.where;
  if (!area) {
    // On the map, a direction moves between areas rather than between plants.
    //
    // **The first press picks somewhere; it does not walk from somewhere.**
    // Starting the cursor at `waiting` implicitly and then immediately stepping
    // off it means the top-left area is the one place on the map an arrow can
    // never land you, which is a strange thing to be true of a corner.
    if (!state.hover) {
      state.hover = AREAS[0].theme;
      highlight();
      return;
    }
    // The map keeps its five columns at every width and scrolls sideways when
    // it must, so a direction here always means what it means on the map. See
    // the note beside `.garden-grid` in site.css for why it does not wrap.
    const next = neighbouringArea(state.hover, direction);
    if (next) {
      state.hover = next.theme;
      highlight();
    }
    return;
  }
  const plants = await plantsIn(area);
  const from = id ? plants.find((p) => p.id === id) : { x: 128, y: 128 };
  const next = from && stepWithin(plants, from, direction);
  if (next) return goTo(area, next.id);

  // Off the edge of the area, into the one beside it — landing on the plant
  // nearest the edge you came through, so the walk carries on in a line rather
  // than restarting in the middle.
  const over = neighbouringArea(area, direction);
  if (!over) return undefined;
  const arrivals = await plantsIn(over.theme);
  if (!arrivals.length) return goTo(over.theme);
  const entry = { up: { x: from.x, y: 256 }, down: { x: from.x, y: -1 },
                  left: { x: 256, y: from.y }, right: { x: -1, y: from.y } }[direction];
  const landing = stepWithin(arrivals, entry, direction) ?? arrivals[0];
  return goTo(over.theme, landing.id);
}

function highlight() {
  for (const cell of el("map-grid").children) {
    cell.classList.toggle("is-hovered", cell.dataset.theme === state.hover);
  }
  el("map-grid").querySelector(".is-hovered")?.focus();
}

/// Somewhere else, chosen without a reason. The point of the whole thing.
async function wander() {
  const plant = randomPlant(await state.plots.all());
  if (plant) goTo(plant.theme, plant.id);
}

// MARK: - Boot

async function main() {
  state.plots = await source();
  el("invented").hidden = !state.plots.invented;

  // SEAM — this page draws no catalogue yet. `/s` negotiates a language and
  // fills `[data-s]` from it, and this will do the same when the garden is read
  // one language at a time (docs/WEBSITE.md). Until then the two strings it
  // needs are the English ones, from the same catalogue `/s` reads.
  const strings = await loadStrings("en");
  for (const node of document.querySelectorAll("[data-s]")) {
    node.textContent = strings.t(node.dataset.s);
  }
  setSheetTitle(strings.t("keys"));

  const directions = [
    ["up", ["ArrowUp", "k"]],
    ["down", ["ArrowDown", "j"]],
    ["left", ["ArrowLeft", "h"]],
    ["right", ["ArrowRight", "l"]],
  ];
  for (const [direction, keys] of directions) {
    register({
      keys,
      group: "walk",
      target: () => el("pad").querySelector(`[data-go="${direction}"]`),
      run: () => { walk(direction); },
    });
  }

  register({
    keys: ["Enter"],
    group: "walk",
    label: "Enter",
    when: () => !state.where.area && Boolean(state.hover),
    run: () => goTo(state.hover),
  });

  // Both of these are labelled by a control rather than by a string in this
  // file. An action whose name lives only in the script is a name nobody can
  // translate, and three of them had crept in here before the sheet showed them
  // side by side with the rows that label themselves.
  //
  // `g` borrows the wordmark, which is a proper noun and needs no commission.
  // Random gets the one new catalogue string on this page, and the button that
  // carries it is on the screen for anybody without a keyboard.
  const away = el("random");
  away.addEventListener("click", () => wander());
  register({
    keys: ["r"],
    group: "go",
    target: () => away,
    run: () => { wander(); },
  });

  register({
    keys: ["g"],
    group: "go",
    target: () => el("wordmark"),
    when: () => Boolean(state.where.area),
    run: () => goTo(null),
  });

  readFragment();
  await render();
  window.addEventListener("hashchange", async () => {
    readFragment();
    await render();
  });
  document.body.dataset.ready = "1";
}

main();
