// A page that is only words.
//
// `/privacy` and `/support` have no seed, no plant and no garden — they are
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
import { loadStrings } from "./strings.js";

const el = (id) => document.getElementById(id);

const state = { languages: [], chosen: null, strings: null, settled: null };

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
  el("language-label").textContent = state.strings.t("language");

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
}

async function main() {
  state.languages = await manifest();
  await settle();
  document.body.dataset.ready = "1";
}

main();
