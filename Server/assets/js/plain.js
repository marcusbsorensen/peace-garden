// A page that is only words.
//
// `/`, `/download`, `/wild` and `/privacy` have no seed, no plant and no
// garden — they are
// prose and a language chooser, which is the smallest thing this site does.
// `page.js` and `walk.js` both open by settling four facts about a language and
// then get on with their real work; this module is that opening and nothing
// after it, shared by the two pages that have no real work.
//
// **Written once rather than twice, and not folded into `page.js`.** The seed
// page carries a link parser, a renderer and a passage bank, none of which a
// privacy notice has any use for, and a reader who arrives here should not be
// fetching them.

import { direction, manifest, negotiate, readable, remember, tracks, uppercases } from "./languages.js";
import { AREA_KEYS, loadStrings } from "./strings.js";

const el = (id) => document.getElementById(id);

const state = { languages: [], chosen: null, strings: null, settled: null };

/// Things to do again whenever a language is settled.
///
/// **`[data-s]` covers a label that is written into the page and nothing
/// else.** The map at the foot of an area page is built from `garden.js`, and
/// its cells are named by area names — so a reader who changes the chooser
/// would otherwise be left with five Greek labels and a map that answers in
/// English. This is how a page says *and me*.
const listeners = [];

/// Run something now if a language has already been settled, and again every
/// time one is settled after that.
export function whenSettled(run) {
  listeners.push(run);
  if (state.strings) run(state.strings);
}

/// Negotiate, dress the page, and build the chooser.
///
/// The same four facts `/s` and `/g` settle — which language the labels are in,
/// which way the page runs, and whether its labels may be tracked. There is no
/// fourth here because there is no passage: a bank is chosen for a quotation,
/// and these pages have none.
async function settle() {
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
    // A paragraph still in English inside an Arabic document is reordered at
    // its punctuation unless it is marked as English. See strings.js §dress —
    // and on this page it is most of the words rather than an edge case, since
    // a language part way through its commission has the prose and not yet
    // this.
    state.strings.dress(node, node.dataset.s);
  }
  // A control drawn as a glyph, with its words as its name rather than its
  // face: the pad under an area's plot. The name is the catalogue's, so it is
  // in the reader's language, and the tooltip is the same words for anybody
  // with a pointer who wonders what a ring with an arrow on it does. Written
  // here and not into the markup because English in an `aria-label` is a name
  // nobody can translate.
  for (const node of document.querySelectorAll("[data-s-label]")) {
    const words = state.strings.t(node.dataset.sLabel);
    node.setAttribute("aria-label", words);
    node.title = words;
    state.strings.dress(node, node.dataset.sLabel);
  }
  el("language-label").textContent = state.strings.t("language");

  // The front page names the ten areas under its garden paragraph. They are
  // read out of `AREA_KEYS` rather than written into the page, because the map
  // already carries them in every language that has been named — so this list
  // is in the reader's own words on the same day the map is, and on no other
  // day. Absent on the pages that have no such list, which is most of them.
  const areas = el("areas");
  if (areas) {
    const named = Object.values(AREA_KEYS).map((key) => state.strings.t(key));
    // The reader's own list separator would be a nineteenth commission for a
    // row of names nobody reads as a sentence. A middle dot is not a word.
    areas.textContent = named.join(" · ");
  }

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
      await settle();
    });
  }
  select.value = state.settled.ui;

  for (const run of listeners) run(state.strings);
}

async function main() {
  state.languages = await manifest();
  await settle();
  document.body.dataset.ready = "1";
  return state.strings;
}

/// The settled strings, for a page that has words of its own to say later.
///
/// `/walk` says two things after the page is dressed — *growing the plants*
/// and *nothing has been planted here yet* — and it cannot say them in the
/// reader's language until the negotiation above has finished. Exported as the
/// promise rather than as the value because a module that imports this one
/// runs the moment it is fetched, which is long before a manifest has come
/// back over the network.
///
/// A module is loaded once however many times it is imported, so importing
/// this from a page script does not settle the language twice: it waits on the
/// same negotiation the page's own `<script>` tag started.
export const dressed = main();
