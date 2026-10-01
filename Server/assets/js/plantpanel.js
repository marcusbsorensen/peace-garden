// A plant's panel: what opens when a plant on an area page is tapped.
//
// **Its name, what the name means, and one passage** — decided by Marcus on 24
// September (docs/WEB-GARDENS.md §*A plant's panel, decided*), in the order the
// app's own name sheet sets them out (`NameMeaningView` in SeedView.swift): the
// binomial with its two meaningful pieces lit, the theme as a dictionary sets a
// word, the theme's three parts with this plant's at full strength, and then
// the passage. The ambassador of an area says so.
//
// **Everything here follows from the seed and nothing else.** The plot service
// sends a planting's seed, its parents and its meeting and nothing about the
// two people, and that is all this reads: the name from the module that grew
// the plant (`pg_name`), the meaning from the one table `/meanings` is drawn
// from (`meanings.js`), and the passage from the reader's own bank by the
// app's own draw (`passages.js`). No name, no note, no date — those belong to
// a plant's own page (docs/WEBSITE.md), which is a second consent this panel
// does not need because it publishes nothing the garden did not already show.
//
// **The passage is the one the app gave at the meeting**, for a reader on the
// same bank. `Quotes.passage(for:)` takes its theme from the two parents —
// mostly one of theirs, sometimes one between them — its part from the child's
// own name, and its line from the child's seed; so does this. That theme can
// differ from the one the name means, and when it does the panel says the
// name's meaning and the meeting's passage, as the app would. An ambassador was
// never crossed, so it has no meeting and no passage in the app; it is given
// the one its own name and seed draw, which is the rule the seed page at `/s`
// follows.
//
// **A postcard is a link to the plant**: this area, this plot, and the first
// twelve characters of the seed, which is how the stand-in garden in `plots.js`
// already names a plant and is one plant in a million million in a plot of
// fifty. `?plot=` is counted from one because a reader may read it; the seed is
// after the `#` because the page is the only thing that needs it, as on `/s`.
// Nothing is stored anywhere to make one, and nothing needs to be: opening the
// link grows the plot again and finds the plant in it.
//
// **One module for the ten area pages**, handed to the pad (`movepad.js`),
// which tells it about taps, plots and the `p` key. A page adds one line.

import { whenSettled } from './plain.js';
import { choose, loadBank, placement, sharedTheme, subthemeOf } from './passages.js';
import { splitEntry, themeRow } from './meanings.js';
import { AREA_KEYS, EN } from './strings.js';
import { direction } from './languages.js';
import { takeResult } from './plant.js';

// A fingertip, in CSS pixels, around what a plant covers on the screen: how
// far from a plant a tap may land and still be a tap on it.
const FINGER = 22;

// How many characters of the seed a postcard carries. See above.
const MARK = 12;

/// Makes the panel for one area page. `theme` is the page's own, for naming
/// the area an ambassador stands for; `engine` is the module the page grows
/// its plants with, asked for their names.
///
/// `cover` is what stands over the plants, for the one area that has any: the
/// Cold Frame's lights (`frame.js`, `makeFrameLids`). A tap is its before it is
/// the plants' — `cover.tapped(x, y, plant)`, with the plant the same tap found,
/// answers whether it took it — and a plant's panel opens only once
/// `cover.uncover(plant)` has lifted whatever is over it. A tap that finds
/// neither is `cover.missed()`.
///
/// **The Wild Fields use it too** (1 October 2026), with two things of their
/// own. `place` is where a plant is, for a postcard, in a field that has no
/// plots — `{ read, address, finds, text }`, each standing in for the plot's
/// own below. `beside(plant, strings)` is what stands beside a plant there:
/// the names and the place and month its two gardeners chose to show, as
/// nodes to set under its name, or nothing.
export function plantPanel({ theme, engine, cover = null, place = null, beside = null }) {
  let pad = null;
  let strings = null;
  let settled = null;
  let open = null;       // the plant the panel is showing, as the stage has it
  let shown = null;      // what was worked out for it: its name, for a postcard
  let returnTo = null;
  let generation = 0;
  let asking = 0;        // which `show` is the latest, while a cover lifts

  const postcard = (place?.read ?? readPostcard)();
  const finds = place?.finds ?? ((one, card) => one.plot === card.plot && one.seed.toLowerCase().startsWith(card.mark));
  const dialog = build();

  whenSettled((words, facts) => {
    strings = words;
    settled = facts;
    if (open) render(open);
  });

  // MARK: What the pad asks

  const hooks = {
    // The plot a postcard names, counted from nought as the service counts.
    start: () => postcard?.plot ?? 0,
    attach: (given) => { pad = given; },
    // A tap at a point on the screen, or the `p` key asking for the plant in
    // the middle. Answers false when there is no plant there.
    tapped: (clientX, clientY, { nearest = false } = {}) => {
      const plant = pickAt(clientX, clientY, nearest);
      if (!nearest && coverTook(clientX, clientY, plant)) return true;
      if (!plant) {
        if (!nearest) cover?.missed();
        return false;
      }
      show(plant, { move: true });
      return true;
    },
    // The plants on the stage are about to go.
    leaving: () => {
      asking += 1;
      close({ quietly: true });
    },
    // A plot has been grown: if a postcard is waiting for a plant in it, go to
    // that plant and open its panel. Once — a postcard is an arrival, not a
    // standing instruction — and a seed that is not here just leaves the plot
    // open, which is where the link said to go.
    shown: () => {
      if (!postcard || postcard.done) return;
      postcard.done = true;
      const plant = pad.stage.named().find((one) => finds(one, postcard));
      if (plant) show(plant, { move: true, arriving: true });
    },
    keyLabel: () => strings?.t('plantKey') ?? '',
  };
  return hooks;

  // MARK: Finding the plant

  function pickAt(clientX, clientY, nearest) {
    if (!pad || pad.busy()) return null;
    const box = pad.canvas.getBoundingClientRect();
    return pad.stage.pick(clientX - box.left, clientY - box.top, nearest ? null : FINGER);
  }

  // Whether a tap was the cover's: the glass of a shut frame, which opens.
  function coverTook(clientX, clientY, plant) {
    if (!cover || !pad || pad.busy()) return false;
    const box = pad.canvas.getBoundingClientRect();
    return cover.tapped(clientX - box.left, clientY - box.top, plant);
  }

  // How close to come to a plant: near enough that the clear part of the
  // drawing's shorter side is a little over twice its height, so a low rosette
  // and a tree each fill about half of it — and never closer than the pad
  // itself can come.
  function closeness(plant, clear) {
    const whole = pad.stage.view(1);
    const across = Math.min(clear.width, clear.height) * whole.metresPerPixel;
    const wanted = Math.max(1.4, plant.height * 2.4);
    return Math.min(whole.closest, Math.max(1, across / wanted));
  }

  // **The part of the drawing the panel leaves clear**, and how far its middle
  // is from the drawing's, in CSS pixels: the band above the panel on a phone,
  // where it rises from the foot of the screen, or the side of it the panel is
  // not on, on a wider window. The plant goes to the middle of that rather than
  // of the drawing, which on a phone would put it under the panel.
  function clearOf() {
    const stage = pad.canvas.getBoundingClientRect();
    const panel = dialog.querySelector('.plant-panel__body').getBoundingClientRect();
    const covers = panel.top < stage.bottom && panel.bottom > stage.top
      && panel.left < stage.right && panel.right > stage.left;
    const parts = covers ? [
      { left: stage.left, right: stage.right, top: stage.top, bottom: Math.min(stage.bottom, panel.top) },
      { left: stage.left, right: Math.min(stage.right, panel.left), top: stage.top, bottom: stage.bottom },
      { left: Math.max(stage.left, panel.right), right: stage.right, top: stage.top, bottom: stage.bottom },
    ] : [stage];
    const room = (part) => Math.max(0, part.right - part.left) * Math.max(0, part.bottom - part.top);
    const best = parts.reduce((a, b) => (room(b) > room(a) ? b : a));
    // Too little of the drawing left to matter: the middle of all of it.
    const part = room(best) > 120 * 120 ? best : stage;
    return {
      width: part.right - part.left,
      height: part.bottom - part.top,
      dx: (part.left + part.right - stage.left - stage.right) / 2,
      dy: (part.top + part.bottom - stage.top - stage.bottom) / 2,
    };
  }

  // MARK: Opening and closing

  async function show(plant, { move = false, arriving = false } = {}) {
    // **What is over the plant is lifted first**, and the panel opens once
    // it is: a seedling in a shut frame is seen into before it is read about.
    const mine = (asking += 1);
    if (cover && (!(await cover.uncover(plant)) || mine !== asking)) return;
    open = plant;
    if (!dialog.open) {
      // Where focus goes back to. A postcard arrives with nothing focused.
      returnTo = arriving ? null : document.activeElement;
      dialog.showModal();
    }
    dialog.querySelector('.plant-panel__body').focus();
    const done = await render(plant);
    // Then the plant is brought to the middle of what the panel leaves clear,
    // closer if the look was further off than the plant wants — never pulled
    // back out from a closer look. After the words, because the passage is
    // what sets how tall the panel stands.
    if (!done || !move || open !== plant) return;
    const clear = clearOf();
    pad.go(plant.at, Math.max(pad.stage.view().zoom, closeness(plant, clear)), [clear.dx, clear.dy]);
  }

  function close({ quietly = false } = {}) {
    if (!dialog.open) return;
    if (quietly) returnTo = null;
    // The close event does the rest.
    dialog.close();
  }

  // MARK: What it says

  async function render(plant) {
    if (!strings) return false;
    const mine = (generation += 1);
    const named = nameOf(plant);
    status('');
    if (!named) {
      // A seed the module cannot read is not a plant this page grew; there is
      // nothing to say about it, so the panel does not stay open saying nothing.
      close();
      return false;
    }
    const { theme: meaningTheme, subtheme: part } = placement(named.name);
    // The meeting's passage: see the head of this file.
    const passageTheme = named.pair ? sharedTheme(named.pair) : meaningTheme;
    const passagePart = named.pair ? subthemeOf(named.tail, passageTheme) : part;
    shown = { plant, named };
    fillName(named);
    fillAmbassador(plant);
    fillBeside(plant);
    fillMeaning(named, meaningTheme, part);
    for (const [selector, key] of [['.plant-panel__send', 'plantPostcard'], ['.plant-panel__close', 'plantClose']]) {
      const button = dialog.querySelector(selector);
      button.textContent = strings.t(key);
      strings.dress(button, key);
    }

    const figure = dialog.querySelector('.plant-panel__passage');
    figure.hidden = true;
    const bank = await loadBank(settled.bank);
    if (mine !== generation) return false;
    const passage = choose(bank, passageTheme, passagePart, seedBytes(plant.seed));
    figure.hidden = !passage;
    if (passage) {
      // The one run on the panel that can be in a different language from the
      // page, and so a different direction; `page.js` says why at length.
      figure.lang = settled.bank;
      figure.dir = direction(settled.bank);
      figure.querySelector('p').textContent = passage.text;
      figure.querySelector('footer').textContent = settled.isBorrowed
        ? `${passage.source} · ${strings.t('inEnglish')}`
        : passage.source;
    }
    return true;
  }

  // The binomial as the app's name sheet sets it: the head and the ending at
  // full strength, what lies between them and the epithet faint, a dot where
  // the head stops. Latin, and left to right in every language.
  function fillName({ name, head, tail }) {
    const node = dialog.querySelector('.plant-panel__name');
    const [genus, ...rest] = name.split(' ');
    node.replaceChildren();
    node.setAttribute('aria-label', name);
    if (genus.startsWith(head) && genus.endsWith(tail) && head.length + tail.length <= genus.length) {
      node.append(
        make('span', 'plant-panel__lit', head),
        make('span', 'plant-panel__faint', `·${genus.slice(head.length, genus.length - tail.length)}`),
        make('span', 'plant-panel__lit', tail),
      );
    } else {
      node.append(make('span', 'plant-panel__lit', genus));
    }
    node.append(make('span', 'plant-panel__faint', ` ${rest.join(' ')}`));
  }

  // The area's ambassador is the plant the service sends with no parents: it
  // was minted rather than crossed, and stands at the head of the first plot.
  function fillAmbassador(plant) {
    const node = dialog.querySelector('.plant-panel__ambassador');
    const is = !(plant.parents?.length);
    node.hidden = !is;
    if (is) {
      node.textContent = strings.t('plantAmbassador', { area: areaIn('plantAmbassador') });
      strings.dress(node, 'plantAmbassador');
    }
  }

  // Who chose to stand beside it, in the Wild Fields: nothing at all for a
  // plant nobody named, and nothing on an area page, which has no `beside`.
  function fillBeside(plant) {
    const node = dialog.querySelector('.plant-panel__beside');
    const nodes = beside?.(plant, strings) ?? [];
    node.replaceChildren(...nodes);
    node.hidden = nodes.length === 0;
  }

  // What the name means, as the block under the area's heading says it and in
  // the same words: the theme's headword, a link to its entry at `/meanings`,
  // with its definition, and the syllable it came from after it; then the three
  // parts, this plant's lit and marked with its ending.
  function fillMeaning({ head, tail }, meaningTheme, part) {
    const row = themeRow(meaningTheme);
    const entry = dialog.querySelector('.plant-panel__entry');
    const parts = dialog.querySelector('.plant-panel__parts');
    entry.replaceChildren();
    parts.replaceChildren();
    if (!row) return;
    const { word, definition } = splitEntry(strings.t(row.meaning));
    strings.dress(entry, row.meaning);
    if (word) {
      const link = make('a', 'plant-panel__word', word);
      link.href = `/meanings#${meaningTheme}`;
      link.title = strings.t('meaningsTitle');
      entry.append(link, ' ');
    }
    entry.append(make('span', null, definition), ' ', latin(make('span', 'plant-panel__head', `${head}-`)));
    for (const one of row.parts) {
      const chosen = one.key === part;
      const item = strings.dress(make('li', chosen ? 'plant-panel__part plant-panel__part--here' : 'plant-panel__part',
        strings.t(one.string)), one.string);
      if (chosen) {
        item.setAttribute('aria-current', 'true');
        item.append(' ', latin(make('span', 'plant-panel__tail', `-${tail}`)));
      }
      parts.append(item);
    }
  }

  // The area's name for a sentence to carry: in the sentence's own language.
  // A sentence still in English with an Arabic name set into it is two
  // languages in one line and neither reads, so while `key` falls back, the
  // name it carries is the English one too.
  function areaIn(key) {
    return strings.borrowed(key) ? EN[AREA_KEYS[theme]] : strings.t(AREA_KEYS[theme]);
  }

  function nameOf(plant) {
    const lineage = plant.parents ?? [];
    const words = new TextEncoder().encode(
      lineage.length === 2 ? [plant.seed, ...lineage, plant.encounter].join(' ') : plant.seed,
    );
    const pointer = engine.pg_alloc(words.length);
    new Uint8Array(engine.memory.buffer, pointer, words.length).set(words);
    const length = engine.pg_name(pointer, words.length);
    engine.pg_free(pointer);
    if (!length) return null;
    return JSON.parse(new TextDecoder().decode(takeResult(engine, length)));
  }

  // MARK: The postcard

  function address(plant) {
    if (place) return place.address(plant, MARK);
    const url = new URL(location.pathname, location.origin);
    url.searchParams.set('plot', String(plant.plot + 1));
    url.hash = `p=${plant.seed.slice(0, MARK).toLowerCase()}`;
    return url.href;
  }

  async function send() {
    if (!shown) return;
    const { plant, named } = shown;
    const url = address(plant);
    const text = place ? place.text(named.name, strings)
      : strings.t('plantPostcardText', { name: named.name, area: areaIn('plantPostcardText') });
    if (navigator.share) {
      try {
        await navigator.share({ title: named.name, text, url });
        return;
      } catch (trouble) {
        // Put away by the reader, which is an answer and not a failure.
        if (trouble?.name === 'AbortError') return;
      }
    }
    try {
      await navigator.clipboard.writeText(url);
      status(strings.t('plantCopied'), 'plantCopied');
    } catch {
      // No clipboard either: the link itself, chosen, for the reader to copy.
      status(strings.t('plantCopyThis'), 'plantCopyThis', url);
    }
  }

  function status(text, key = null, url = null) {
    const node = dialog.querySelector('.plant-panel__status');
    node.replaceChildren();
    if (text) {
      node.append(text);
      if (key) strings.dress(node, key);
    }
    if (url) {
      const field = make('input', 'plant-panel__link');
      field.type = 'text';
      field.readOnly = true;
      field.value = url;
      field.dir = 'ltr';
      field.setAttribute('aria-label', text);
      node.append(field);
      field.focus();
      field.select();
    }
  }

  // MARK: The markup

  function build() {
    const node = document.createElement('dialog');
    node.className = 'plant-panel';
    node.setAttribute('aria-labelledby', 'plant-panel-name');
    const body = make('div', 'plant-panel__body');
    body.tabIndex = -1;

    const top = make('div', 'plant-panel__top');
    const name = latin(make('p', 'plant-name plant-panel__name'));
    name.id = 'plant-panel-name';
    const closer = make('button', 'quiet-button plant-panel__close');
    closer.type = 'button';
    closer.addEventListener('click', () => close());
    top.append(name, closer);

    const ambassador = make('p', 'plant-panel__ambassador');
    const besideIt = make('div', 'plant-panel__beside');
    besideIt.hidden = true;
    const entry = make('p', 'plant-panel__entry');
    const parts = make('ol', 'plant-panel__parts');

    const figure = make('blockquote', 'passage plant-panel__passage');
    figure.append(make('p'), make('footer', 'label'));
    figure.hidden = true;

    const actions = make('div', 'plant-panel__actions');
    const sender = make('button', 'quiet-button plant-panel__send');
    sender.type = 'button';
    sender.addEventListener('click', send);
    actions.append(sender);
    const said = make('p', 'plant-panel__status');
    said.setAttribute('role', 'status');

    body.append(top, ambassador, besideIt, entry, parts, figure, actions, said);
    node.append(body);

    // A key pressed in the panel is the panel's: the pad's arrows and letters
    // stay where they are while somebody reads. Escape still closes it, which
    // the dialog does by itself.
    node.addEventListener('keydown', (event) => event.stopPropagation());
    // A tap outside the panel closes it — or, if it lands on another plant,
    // opens that one instead, so a reader can go from plant to plant. On the
    // glass of a shut frame it closes the panel and opens that frame.
    node.addEventListener('click', (event) => {
      if (event.target !== node) return;
      const inside = body.getBoundingClientRect();
      const { clientX: x, clientY: y } = event;
      if (x >= inside.left && x <= inside.right && y >= inside.top && y <= inside.bottom) return;
      const plant = pickAt(x, y, false);
      if (coverTook(x, y, plant)) close();
      else if (plant) show(plant, { move: true });
      else close();
    });
    node.addEventListener('close', () => {
      open = null;
      shown = null;
      generation += 1;
      // A postcard's address is let go once its panel is closed, so a reload
      // opens the plot rather than the panel again.
      if (location.hash.startsWith('#p=')) history.replaceState(null, '', location.pathname + location.search);
      if (returnTo?.isConnected) returnTo.focus();
      returnTo = null;
    });
    document.body.append(node);
    return node;
  }
}

/// `?plot=` and `#p=`, if this page was opened from a postcard.
function readPostcard() {
  const mark = location.hash.match(/^#p=([0-9a-f]{6,64})$/i)?.[1];
  if (!mark) return null;
  const asked = Number.parseInt(new URLSearchParams(location.search).get('plot') ?? '1', 10);
  return { plot: Number.isFinite(asked) && asked >= 1 ? asked - 1 : 0, mark: mark.toLowerCase(), done: false };
}

function seedBytes(hex) {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) bytes[i] = Number.parseInt(hex.slice(2 * i, 2 * i + 2), 16);
  return bytes;
}

// A run of Latin inside a page that may run either way.
function latin(node) {
  node.lang = 'la';
  node.dir = 'ltr';
  return node;
}

function make(tag, className = null, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}
