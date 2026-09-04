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
import { direction, manifest, negotiate, readable, remember, tracks, uppercases } from "./languages.js";
import { register, setSheetTitle } from "./keys.js";
import { loadStrings } from "./strings.js";
import { loadBank, placement, choose } from "./passages.js";
import { source } from "./plots.js";
import { drawBar, signIn, signedIn } from "./testers.js";

const el = (id) => document.getElementById(id);

const state = {
  plots: null,
  where: { area: null, plant: null },
  cache: new Map(),
  languages: [],
  /// A chooser selection, which outranks `?l=` — it is the most recent thing
  /// the reader said. Same rule as `/s`.
  chosen: null,
  strings: null,
  settled: null,
};

/// The area names are English and stay English. **Settled by Marcus on
/// 4 September**; the reasoning is in docs/WEBSITE.md, under *Walking it*.
///
/// It is the argument the app already makes about a plant's binomial: a proper
/// noun travels better than a translation of one. So this is a table rather
/// than ten catalogue keys, and it costs nothing — ten keys would have been
/// four hundred and twenty commissions at the multiplier as it stands.
///
/// Which also means **an area name is the one piece of the site's writing that
/// is not translated**, so it is not a place to put a sentence. Ten proper
/// nouns is what was decided; a description here would quietly reintroduce the
/// cost that choosing them avoided.
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
  await drawPassage(plant);

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

/// A hex seed as the bytes it stands for.
function bytes(hex) {
  const out = new Uint8Array(Math.floor(hex.length / 2));
  for (let i = 0; i < out.length; i += 1) {
    out[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  }
  return out;
}

/// The line under a plant, in the reader's language and nobody else's.
///
/// **This is the argument in docs/WEBSITE.md §"The garden, walked in one
/// language at a time" becoming visible.** The passage is not a property of the
/// plant: the plant carries a theme and a subtheme, both derived from its name,
/// both language-neutral, and the reader's own bank supplies the words. Change
/// the chooser and the same plant says something else — not a translation of
/// what it said before, because no bank is a translation of another.
///
/// In the app that rule is something you are told. Here it is something you can
/// do, because a browser can hold two languages one after the other and a phone
/// only ever has one.
async function drawPassage(plant) {
  const block = el("passage");
  const { theme, subtheme } = placement(plant.name);
  const bank = await loadBank(state.settled.bank);
  // `choose` folds bytes, not text. A plot record carries its seed as hex —
  // which is how `SeedID` encodes itself and how it travels — so it is unpacked
  // here rather than stored twice.
  const passage = choose(bank, theme, subtheme, bytes(plant.seed));
  block.hidden = !passage;
  if (!passage) return;
  block.lang = state.settled.bank;
  // The one element that can disagree with the page it is on.
  block.dir = direction(state.settled.bank);
  el("passage-text").textContent = passage.text;
  el("passage-source").textContent = state.settled.isBorrowed
    ? `${passage.source} · ${state.strings.t("inEnglish")}`
    : passage.source;
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

// MARK: - Language

/// Negotiate, dress the page, and build the chooser. The same four facts `/s`
/// settles — which language the labels are in, which bank the passage comes
/// from, which way the page runs, and whether its labels may be tracked.
async function settle() {
  // A tester outranks everything, including `?l=`, because standing in one is
  // an instruction about the whole page rather than a wish about one reading.
  // It is written into `state.chosen` rather than handed to `negotiate`
  // separately so that there is still exactly one answer to *what language is
  // this* — the alternative was a second override that agreed with the first
  // most of the time.
  const tester = signedIn();
  if (tester) state.chosen = tester;

  state.settled = negotiate(state.languages, {
    ...(state.chosen ? { override: state.chosen } : {}),
  });
  state.strings = await loadStrings(state.settled.ui);

  const root = document.documentElement;
  root.lang = state.settled.ui;
  root.toggleAttribute("data-keeps-case", !uppercases(state.settled.ui));
  root.toggleAttribute("data-untracked", !tracks(state.settled.ui));
  root.dir = direction(state.settled.ui);

  for (const node of document.querySelectorAll("[data-s]")) {
    node.textContent = state.strings.t(node.dataset.s);
    // See strings.js §dress, and the note beside `#invented` in `/g`.
    state.strings.dress(node, node.dataset.s);
  }
  el("language-label").textContent = state.strings.t("language");
  setSheetTitle(state.strings.t("keys"));

  const select = el("language");
  if (!select.options.length) {
    for (const language of readable(state.languages)) {
      const option = document.createElement("option");
      option.value = language.code;
      // The endonym, because somebody looking for their own language is
      // looking for their own word for it.
      option.textContent = language.endonym;
      option.lang = language.code;
      select.append(option);
    }
    select.addEventListener("change", async () => {
      state.chosen = select.value;
      remember(select.value);
      // There is exactly one tester per language, so while somebody is standing
      // in one the chooser *is* the way between them: changing the language and
      // changing who you are standing in are the same act, and letting them
      // come apart would leave a bar saying `Test-DA-Gartner` over a page drawn
      // in Greek.
      if (signedIn()) signIn(select.value);
      await settle();
      await drawBar(onLeave);
      await render();
    });
  }
  select.value = state.settled.ui;
}

/// Leaving a tester hands the page back to the reader's own browser: the
/// chooser's remembered value, then `navigator.languages`. `state.chosen` has
/// to be cleared for that, or the language the tester pinned would outlive it.
async function onLeave() {
  state.chosen = null;
  await settle();
  await render();
}

// MARK: - Boot

async function main() {
  state.plots = await source();
  el("invented").hidden = !state.plots.invented;
  state.languages = await manifest();
  await settle();
  // Draws nothing at all when nobody is signed in, which is why it is
  // unconditional. See `testers.js`.
  await drawBar(onLeave);

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

  // The chooser is on `c`, not on `l`, and `/s` was moved to match.
  //
  // `l` is the walk's right hand — hjkl — and registering the chooser there too
  // shadowed it silently: first match wins, the direction was registered first,
  // and the sheet cheerfully listed both. The sheet is supposed to be the thing
  // that cannot lie about the keys, so `keys.js` now says so out loud when two
  // actions claim the same key.
  register({
    keys: ["c"],
    group: "go",
    target: () => el("language-label"),
    run: () => {
      const select = el("language");
      if (!select) return false;
      select.focus();
      try {
        select.showPicker?.();
      } catch {
        /* focused is enough */
      }
      return true;
    },
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
