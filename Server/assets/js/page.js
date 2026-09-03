// `/s` — the page a seed lands on.
//
// The whole of what it does: read the fragment, settle a language, draw what
// the link already holds, and offer the reader a way to grow it. It asks the
// origin for two files — the manifest and one passage bank — and for nothing
// else, ever. **No field of the fragment goes into a query string, a fetch, or
// an image URL.** That property is the reason the payload lives in the fragment
// at all, and it is the one thing in this file worth guarding in review.
//
// The modules under it are shared on purpose. A plant page at `/p/…` reads the
// same manifest, negotiates the same way, draws its labels from the same
// catalogue and picks its passage with the same two derived facts. What that
// page adds is a service, an identity and a moderation surface — see
// docs/WEBSITE.md — and none of it belongs here.

import { direction, manifest, negotiate, readable, remember, tracks, uppercases } from "./languages.js";
import { loadStrings } from "./strings.js";
import { loadBank, placement, choose } from "./passages.js";
import { parse } from "./link.js";
import { register, setSheetTitle } from "./keys.js";

const el = (id) => document.getElementById(id);

const state = {
  languages: [],
  link: null,
  trouble: null,
  /// A chooser selection, which outranks even `?l=` — it is the most recent
  /// thing the reader said.
  chosen: null,
};

/// How old the plant is, in the reader's own language and with no string of
/// ours behind it.
///
/// `Intl` already carries every plural rule and every unit name for every
/// language a browser can be set to, which is the difference between one label
/// in the catalogue and one commission per language for *day*, *days*, *month*
/// and the rest. docs/WEBSITE.md's table lists the age under *needs a word*;
/// this is the word arriving from somewhere that already had it.
function age(date, locale) {
  const days = Math.max(0, Math.floor((Date.now() - date.getTime()) / 86400000));
  try {
    const relative = new Intl.RelativeTimeFormat(locale, { numeric: "auto" });
    if (days < 30) return relative.format(-days, "day");
    if (days < 365) return relative.format(-Math.round(days / 30), "month");
    return relative.format(-Math.round(days / 365), "year");
  } catch {
    return new Intl.DateTimeFormat(locale, { dateStyle: "long" }).format(date);
  }
}

function fill(element, ...children) {
  element.replaceChildren(...children);
}

function span(className, text) {
  const node = document.createElement("span");
  node.className = className;
  node.textContent = text;
  return node;
}

function buildChooser(languages, code, onPick) {
  const select = el("language");
  if (!select.options.length) {
    for (const language of readable(languages)) {
      const option = document.createElement("option");
      option.value = language.code;
      // The endonym, because somebody looking for their own language is
      // looking for their own word for it.
      option.textContent = language.endonym;
      option.lang = language.code;
      select.append(option);
    }
    select.addEventListener("change", () => onPick(select.value));
  }
  select.value = code;
}

/// Which render is the current one. Two languages picked in quick succession
/// each wait on a fetch, and the second must win however the two land.
let generation = 0;

async function render() {
  const mine = (generation += 1);
  const settled = negotiate(state.languages, {
    ...(state.chosen ? { override: state.chosen } : {}),
  });
  const strings = await loadStrings(settled.ui);
  if (mine !== generation) return;
  const t = strings.t;

  document.documentElement.lang = settled.ui;
  // Uppercasing is a transformation that can lose a letter, so it is decided
  // per language rather than applied by one rule to all of them.
  document.documentElement.toggleAttribute("data-keeps-case", !uppercases(settled.ui));
  // Tracking is a separate question from case and a sharper one: on Arabic,
  // letter-spacing severs the joins. See languages.js §NEVER_TRACKED.
  document.documentElement.toggleAttribute("data-untracked", !tracks(settled.ui));
  document.documentElement.dir = direction(settled.ui);

  for (const node of document.querySelectorAll("[data-s]")) {
    node.textContent = t(node.dataset.s);
  }
  el("language-label").textContent = t("language");
  // The sheet's own heading, and the only word the keyboard layer needs: every
  // other row in it is labelled by the control it operates.
  setSheetTitle(t("keys"));
  buildChooser(state.languages, settled.ui, (code) => {
    state.chosen = code;
    remember(code);
    render();
  });

  const notice = el("notice");
  notice.hidden = !state.trouble;
  if (state.trouble) notice.textContent = t(state.trouble);

  el("about").hidden = Boolean(state.link);
  el("seed").hidden = !state.link;
  if (!state.link) return;

  const link = state.link;
  el("seed").querySelector("h1").textContent =
    t(link.kind === "r" ? "replyTitle" : "seedTitle");

  el("plant-name").textContent = link.plantName;
  el("sent-by").textContent = t("sentBy", {
    name: link.displayName.trim() || t("gardener"),
  });

  const planted = el("planted");
  const when = document.createElement("time");
  when.dateTime = link.birth.toISOString();
  when.className = "value";
  when.textContent = age(link.birth, settled.ui);
  when.title = new Intl.DateTimeFormat(settled.ui, { dateStyle: "long" }).format(link.birth);
  fill(planted, span("label", t("planted")), document.createTextNode(" "), when);

  // The theme and the subtheme are read off the plant's own name, which is the
  // app's own mechanism: the head of the genus carries the theme and the ending
  // carries the subtheme, and both were in the seed before either mattered.
  //
  // SEAM — which plant's name. On an offer link this is the *sender's* plant,
  // because the plant the two seeds would make together does not exist until
  // the reader has a seed of their own, and minting one is what the App Clip is
  // for. So the passage on this page belongs to the plant that arrived rather
  // than to the pair. The app folds the child seed to pick the line; this folds
  // the seed the link carries, which is the same mechanism over the only bytes
  // a static page has. docs/WEBSITE.md describes the derivation for a *shared
  // plant* page, where the plant is the joint one and the question does not
  // arise. Whoever builds the renderer settles it, because they have to decide
  // the same thing about what to draw.
  const { theme, subtheme } = placement(link.plantName);
  const bank = await loadBank(settled.bank);
  if (mine !== generation) return;
  const passage = choose(bank, theme, subtheme, link.seed);

  const passageBlock = el("passage");
  passageBlock.hidden = !passage;
  if (passage) {
    passageBlock.lang = settled.bank;
    // **The one element on the page that can disagree with the page.** A
    // borrowed bank means the passage is in a different language from the
    // chrome around it, and once one of the two is Arabic or Hebrew that is a
    // different direction as well — a Hebrew reader with no Hebrew bank gets a
    // right-to-left page with a left-to-right passage in it, and the passage
    // has to say so or the punctuation lands at the wrong end of the line.
    passageBlock.dir = direction(settled.bank);
    el("passage-text").textContent = passage.text;
    // A borrowed language is named, and only here. A label that fell back to
    // English says so nowhere — a label is short and a fallback in one is not
    // the conspicuous case. The passage is the one moment the site speaks at
    // length, so it is the one place it has to be said.
    el("passage-source").textContent = settled.isBorrowed
      ? `${passage.source} · ${t("inEnglish")}`
      : passage.source;
  }
}

/// Reads the fragment into `state`.
///
/// It is not in the request line, not in `Referer`, and not in a log, and
/// nothing below sends it anywhere.
async function readFragment() {
  const fragment = window.location.hash.replace(/^#/, "");
  state.link = null;
  state.trouble = null;
  if (!fragment) return;
  try {
    state.link = await parse(fragment);
  } catch (error) {
    state.trouble = error.reason || "damaged";
  }
}

async function main() {
  // Set by the script for itself: a page whose script never arrives is a
  // visible page rather than an invisible one.
  document.body.dataset.loading = "1";
  state.languages = await manifest();
  await readFragment();

  // The one action this page has. It is registered rather than wired directly
  // so that it appears in the sheet under `?` alongside everything a garden
  // page adds — see keys.js, where the sheet *is* the registry.
  register({
    // `c`, not `l`: the garden walks with hjkl and the two pages must not
    // disagree about a letter. See the note in walk.js.
    keys: ["c"],
    target: () => el("language-label"),
    run: () => {
      const select = el("language");
      if (!select || select.hidden) return false;
      select.focus();
      // Safari and Firefox ignore `showPicker` on a select they did not open
      // from a click, and throw rather than no-op. Focus is the part that
      // matters; opening it is a courtesy where it is allowed.
      try {
        select.showPicker?.();
      } catch {
        /* focused is enough */
      }
    },
  });

  try {
    await render();
  } finally {
    document.body.dataset.ready = "1";
  }

  // A fragment changing is a same-document navigation, so nothing reloads.
  // This is how somebody arrives from the page with no seed in it, and how the
  // back button behaves once they have.
  window.addEventListener("hashchange", async () => {
    await readFragment();
    await render();
  });
}

main();
