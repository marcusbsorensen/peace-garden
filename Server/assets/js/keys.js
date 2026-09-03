// Every action on the site, reachable from the keyboard.
//
// One registry, one listener, and a sheet that lists what is registered. A page
// declares its actions here rather than attaching its own `keydown`, so that
// the sheet is complete by construction: **there is no way to add a shortcut
// that the sheet does not know about**, because the sheet is the registry.
//
// ## The sheet costs one string, not fifteen
//
// docs/WEBSITE.md defends a low string count with a multiplier: every label is
// seventeen labels, and will be twenty-five, and then thirty-three. A shortcut
// sheet with its own wording for *Language*, *Random plant*, *Go up* and the
// rest would be about fifteen new strings, which is two hundred and fifty-five
// commissions to explain a keyboard.
//
// So it has none. **Each row is labelled by the control it operates**, read off
// that control's own text at the moment the sheet opens — text that is already
// in the reader's language because it is already on the screen. The only new
// string in the catalogue is the sheet's own title.
//
// It also means the sheet cannot drift: rename a button and its row renames
// itself, and a control that has no visible name is a control the sheet will
// show as blank, which is a bug report rather than a translation job.
//
// ## What does not get a shortcut
//
// Single letters only, no modifiers. A shortcut with a modifier is a shortcut
// competing with the browser, and this site has few enough actions that it does
// not need to. Nothing fires while the reader is typing.

const actions = [];
let sheet = null;
let listening = false;

/// Register one action.
///
/// - `keys`: the keys that run it, as they arrive in `KeyboardEvent.key`.
///   Several because a direction wants both `ArrowLeft` and `h`.
/// - `target`: the control this operates, or a function returning it. The sheet
///   reads its label from here, and an action with no target needs `label`.
/// - `label`: only for an action with no control of its own on the page.
/// - `group`: rows are listed in registration order within a group.
/// - `run`: what to do. Returning `false` means "not applicable now", and the
///   key falls through to the browser.
/// - `when`: an optional guard; a false answer hides the row and ignores the key.
export function register({ keys, target = null, label = null, group = "", run, when = null }) {
  if (!Array.isArray(keys) || !keys.length) throw new TypeError("an action needs keys");
  if (typeof run !== "function") throw new TypeError("an action needs something to run");
  actions.push({ keys, target, label, group, run, when });
  listen();
  return () => {
    const at = actions.findIndex((a) => a.run === run);
    if (at >= 0) actions.splice(at, 1);
  };
}

/// Everything registered, for the sheet and for tests.
export function registered() {
  return actions.filter((action) => !action.when || action.when());
}

function resolve(action) {
  const node = typeof action.target === "function" ? action.target() : action.target;
  const text = node?.getAttribute?.("aria-label") || node?.textContent?.trim();
  return { node, label: action.label ?? text ?? "" };
}

/// True while the reader is putting words somewhere, in which case a letter is
/// a letter. `isContentEditable` covers the name field on a plot page.
function typing(event) {
  const node = event.target;
  if (!node || node === document.body) return false;
  if (node.isContentEditable) return true;
  const tag = node.tagName;
  return tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT";
}

function listen() {
  if (listening) return;
  listening = true;
  document.addEventListener("keydown", (event) => {
    if (event.defaultPrevented || typing(event)) return;
    // A shortcut never competes with the browser's own.
    if (event.metaKey || event.ctrlKey || event.altKey) return;

    if (event.key === "Escape" && sheet) {
      closeSheet();
      event.preventDefault();
      return;
    }
    if (event.key === "?") {
      toggleSheet();
      event.preventDefault();
      return;
    }

    for (const action of actions) {
      if (!action.keys.includes(event.key)) continue;
      if (action.when && !action.when()) continue;
      if (action.run(event) === false) continue;
      event.preventDefault();
      return;
    }
  });
}

// MARK: - The sheet

export function toggleSheet() {
  if (sheet) closeSheet();
  else openSheet();
}

/// `title` is the one string this module needs. The caller passes it in from the
/// catalogue rather than this module importing one, so `keys.js` stays a
/// mechanism and the words stay in one place.
let sheetTitle = "Keys";
export function setSheetTitle(text) {
  if (text) sheetTitle = text;
}

export function openSheet() {
  if (sheet) return;
  const rows = registered()
    .map((action) => ({ keys: action.keys, ...resolve(action), group: action.group }))
    .filter((row) => row.label);

  sheet = document.createElement("div");
  sheet.className = "keysheet";
  sheet.setAttribute("role", "dialog");
  sheet.setAttribute("aria-modal", "true");

  const panel = document.createElement("div");
  panel.className = "keysheet-panel";

  const heading = document.createElement("h2");
  heading.textContent = sheetTitle;
  heading.id = "keysheet-title";
  sheet.setAttribute("aria-labelledby", heading.id);
  panel.append(heading);

  // The sheet documents its own key, labelled with its own heading — so `?`
  // reads as "? — Keys", and the one string this module costs does two jobs.
  //
  // Escape is not listed. Closing a dialog with it is a convention the reader
  // already has and the `role="dialog"` announces, and giving it a row would
  // mean commissioning the word *close* in seventeen languages to say something
  // nobody needed telling.
  rows.unshift({ keys: ["?"], label: sheetTitle, group: "" });

  const list = document.createElement("dl");
  let lastGroup = null;
  for (const row of rows) {
    if (row.group !== lastGroup && row.group) {
      const rule = document.createElement("div");
      rule.className = "keysheet-rule";
      list.append(rule);
      lastGroup = row.group;
    }
    const term = document.createElement("dt");
    for (const key of row.keys) {
      const cap = document.createElement("kbd");
      // `ArrowLeft` is not what is written on the key.
      cap.textContent = { ArrowLeft: "←", ArrowRight: "→", ArrowUp: "↑", ArrowDown: "↓" }[key] ?? key;
      term.append(cap);
    }
    const detail = document.createElement("dd");
    detail.textContent = row.label;
    list.append(term, detail);
  }
  panel.append(list);

  // No close button.
  //
  // A ✕ needs an accessible name, and the only name for it is the word *close*
  // — seventeen commissions to label a control that three gestures already
  // cover: Escape, `?` again, and a click outside. An unnamed button would be
  // worse than no button. This sheet is a keyboard affordance and every way out
  // of it is one a keyboard already has.
  sheet.append(panel);
  sheet.addEventListener("click", (event) => {
    if (event.target === sheet) closeSheet();
  });
  document.body.append(sheet);

  // Focus moves into the dialog so a screen reader reads it and Escape is
  // heard here rather than by whatever was focused before.
  panel.tabIndex = -1;
  panel.focus();
}

export function closeSheet() {
  sheet?.remove();
  sheet = null;
}

/// Checks the registry without a browser beyond a DOM.
export function selfTest() {
  const before = actions.length;
  let ran = 0;
  const drop = register({ keys: ["t"], label: "test", run: () => { ran += 1; } });
  if (actions.length !== before + 1) throw new Error("keys.js: nothing registered");
  if (!registered().some((a) => a.label === "test")) throw new Error("keys.js: not listed");
  const hidden = register({ keys: ["u"], label: "hidden", run: () => {}, when: () => false });
  if (registered().some((a) => a.label === "hidden")) throw new Error("keys.js: a guard was ignored");
  drop();
  hidden();
  if (actions.length !== before) throw new Error("keys.js: nothing was dropped");
  return "keys.js: every check passed";
}
