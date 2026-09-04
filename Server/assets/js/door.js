// The test door: the latch, the roster, and the way into the garden.
//
// `testers.js` holds what a tester is and why there are no accounts. This file
// is only the screen.

import { roster, signIn, unlock, unlocked } from "./testers.js";

const el = (id) => document.getElementById(id);

/// Where a tester lands. The garden rather than `/s`, because `/s` needs a seed
/// in its fragment to have anything to say and the garden has ten areas of
/// plants to walk immediately.
const LANDING = "/g";

let all = [];

function draw(rows) {
  const list = el("roster-list");
  list.replaceChildren();
  for (const tester of rows) {
    const item = document.createElement("li");
    const button = document.createElement("button");
    button.type = "button";
    button.className = "roster__row";

    const who = document.createElement("span");
    who.className = "roster__who";
    who.textContent = tester.id;

    // The endonym, because somebody looking for a language is looking for its
    // own word for itself — the same rule the chooser follows. The English name
    // is beside it because this page is read by whoever is building the site
    // rather than by a reader of the language.
    const what = document.createElement("span");
    what.className = "roster__what";
    what.textContent = `${tester.name} · ${tester.endonym}`;
    what.lang = tester.code;

    button.append(who, what);
    button.addEventListener("click", () => {
      signIn(tester.code);
      window.location.assign(LANDING);
    });
    item.append(button);
    list.append(item);
  }
  if (!rows.length) {
    const empty = document.createElement("li");
    empty.className = "roster__empty body quiet";
    empty.textContent = "Nobody by that name.";
    list.append(empty);
  }
}

/// Matches the identity, the language code, the English name and the endonym,
/// so `da`, `Danish`, `Dansk` and `Gartner` all find the same row.
function filter(term) {
  const needle = term.trim().toLowerCase();
  if (!needle) return all;
  return all.filter((tester) =>
    [tester.id, tester.code, tester.name, tester.endonym, tester.gardener]
      .some((field) => String(field).toLowerCase().includes(needle)),
  );
}

async function open() {
  el("door").hidden = true;
  el("roster").hidden = false;
  all = await roster();
  draw(all);
  el("filter").addEventListener("input", (event) => draw(filter(event.target.value)));
  el("filter").focus();
}

function main() {
  // A latch already lifted in this browser stays lifted. The point of it is to
  // keep the roster out of the way of somebody who wanders in, not to be a
  // ritual for whoever is working.
  if (unlocked()) {
    open();
    return;
  }

  el("door").addEventListener("submit", (event) => {
    event.preventDefault();
    if (unlock(el("word").value)) {
      open();
      return;
    }
    // No count, no lockout, no delay. It guards a list of invented names.
    el("door-note").textContent = "Not that one.";
    el("word").select();
  });
  el("word").focus();
}

main();
