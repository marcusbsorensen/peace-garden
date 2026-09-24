// The move pad under every area's plot: how a reader moves about an area, as
// opposed to out of it, which is the minimap's job.
//
// **One pad, written here, for all nine areas.** It used to be two chevrons and
// two rings copied into each page's markup and wired by each page's script;
// now each page has an empty `#keys` and hands this module its stage, how many
// plots it has and how to show one. What is on the pad, what the keys do and
// what the canvas answers to are therefore the same on every area page by
// construction.
//
// ## What it does
//
// - **Four directions, in the viewer's frame.** Up is up the screen whichever
//   way the plot has been turned. Closer in than the whole plot, a direction
//   moves the window across the plot; at the whole plot there is nothing to
//   move across, so it is a way to the next plot or nowhere.
// - **The plots of an area lie end to end**, the next one further along the
//   ground's z — which is how the Long Walk lays its three side by side, and
//   the only arrangement the plot service knows: it answers with a count, and
//   plot n + 1 is the one opened after plot n. So which side of the screen the
//   next plot is on depends on the turn, and is worked out from the camera
//   (`stage.onScreen`) rather than assumed. On this projection the line of
//   plots always runs more across the screen than up it, so left and right are
//   the ways along it, and up and down only ever move the window.
// - **The window stays over the plot**, and runs along a side it is pressed
//   against (`hold` in `longwalk.js`), so there is always a plant in the
//   middle of it.
// - **Going past the edge is a second press.** Moving the window up to the
//   edge the plot shares with the next one stops there; pressing that way
//   again crosses to it, arriving over the same point of ground carried across
//   the seam, as close as you were — so crossing reads as walking on rather
//   than as a new page, and one press the other way goes back. A held key
//   stops at the edge and does not carry on across: a plot that has to be
//   fetched and grown is not something to fall into by holding a key a moment
//   too long.
// - **Closer and further**, from the whole plot to near enough to see one
//   flower (`CLOSEST` in `longwalk.js`), about the middle of the window.
//   Pinching the plot, or a trackpad's pinch, does the same about the fingers.
//   Closer in, the plot can be dragged. The plain scroll wheel and a finger
//   moving up the page are left alone.
// - **The rings turn**, as they did, and a turn goes round whatever is in the
//   middle of the window.
//
// ## The keys
//
// Registered with `keys.js`, so `?` lists them, labelled by the buttons they
// press: the arrows and WASD move, `+` and `=` come closer, `-` goes further,
// `0` and Home go back to the whole plot, `Q` and `[` turn anticlockwise, `E`
// and `]` clockwise. `keys.js` already keeps them out of the way of a reader
// typing, or choosing a language.
//
// **Up and down fall through to the page when they have nothing to do**, so a
// reader at the whole plot still scrolls the page with the arrow keys as on
// any other page.
//
// ## Glyphs, and the words are their names
//
// No button has a word on its face. Each has `data-s-label`, and its words —
// in the reader's language — are its `aria-label` and tooltip. Monoline, even
// weight, round free ends, per BRAND.md §3.2. **Nothing on the pad mirrors
// under a right-to-left language**: up, down, left and right are directions on
// the screen, a magnifier is a magnifier, and clockwise is a direction in the
// world.

import { register, setSheetTitle } from './keys.js';
import { whenSettled } from './plain.js';

// The glyphs, on the 20-unit square every pad glyph is drawn on. The two
// chevrons that were Back and On are left and right; up and down are the same
// chevron turned. The magnifier is a ring and a handle with a plus or a minus
// in it, and the rings are the two that were there.
const LENS = 'M3.25 8.5A5.25 5.25 0 1 0 13.75 8.5A5.25 5.25 0 1 0 3.25 8.5M12.3 12.3L16.5 16.5';
const KEYS = [
  { go: 'up', label: 'moveUp', path: 'M4.5 12.75L10 7.25L15.5 12.75' },
  { go: 'left', label: 'moveLeft', path: 'M12.75 4.5L7.25 10L12.75 15.5' },
  { go: 'right', label: 'moveRight', path: 'M7.25 4.5L12.75 10L7.25 15.5' },
  { go: 'down', label: 'moveDown', path: 'M4.5 7.25L10 12.75L15.5 7.25' },
  { go: 'in', label: 'zoomIn', path: `${LENS}M6.25 8.5H10.75M8.5 6.25V10.75` },
  { go: 'out', label: 'zoomOut', path: `${LENS}M6.25 8.5H10.75` },
  { go: 'anti', label: 'walkTurnAnti', path: 'M6.27 4.68A6.5 6.5 0 1 0 13.73 4.68M16.96 4.34L13.73 4.68L14.07 7.91' },
  { go: 'clock', label: 'walkTurnClock', path: 'M13.73 4.68A6.5 6.5 0 1 1 6.27 4.68M5.93 7.91L6.27 4.68L3.04 4.34' },
];

// Which way each direction moves the window, in the viewer's frame.
const MOVES = { left: ['x', -1], right: ['x', 1], up: ['y', 1], down: ['y', -1] };

// How far one press moves the window, as a part of the window: a third, so a
// few presses cross a plot and the plant you were looking at is still in view
// after one. A held key repeats about thirty times a second, and moves a
// fifteenth each time, which is a steady walk rather than a blur.
const PRESS = 1 / 3;
const HELD = 1 / 15;

// How much closer one press comes: a factor of √2, so two presses are twice as
// close, and the whole plot to the closest look is about six presses.
const STEP = Math.SQRT2;

// How quickly the look catches up with where it has been asked to be, in
// milliseconds: the time to cover about two thirds of the way.
const EASE = 90;

/// Puts the pad in `nav` and answers to it, to the keys and to the canvas.
///
/// - `stage`: the area's `makePlotStage`.
/// - `plots`: how many the plot service has opened.
/// - `step`: how many plots one crossing moves, which is how many the page
///   shows at once — three on the walk, one everywhere else.
/// - `show(first)`: grows the plots from `first`; may be slow, is awaited.
/// - `turned()`: after a turn, for the sky, which faces the way the camera does.
///
/// Shows the first plot, and resolves when it is grown.
export async function openMovePad({ nav, canvas, stage, plots, step = 1, show, turned = () => {} }) {
  const buttons = build(nav);
  let at = 0;
  let busy = false;

  // Where the look is going, which the stage catches up with frame by frame.
  // Every decision is made against this rather than against where the look has
  // got to, so two quick presses make two moves rather than one and a half.
  const target = { zoom: 1, x: 0, y: 0 };

  // MARK: Moving

  // The plot on one side of the screen, if there is one: along the line of
  // plots, which way along depending on where the camera stands.
  const along = (side) => {
    if (side !== 'left' && side !== 'right') return 0;
    const [across] = stage.onScreen([0, 0, 1]);
    return (side === 'right' ? 1 : -1) * Math.sign(across);
  };
  const neighbour = (side) => {
    const way = along(side);
    const next = at + way * step;
    return way && next >= 0 && next < plots ? next : null;
  };

  // Whether the look is at the edge this plot shares with the one on `side`:
  // the whole of that edge is a way through, not only its corner.
  const atSeam = (side) => {
    const way = along(side);
    const seam = stage.seams(target);
    return (way > 0 && seam.on) || (way < 0 && seam.back);
  };

  // Whether the look can go no further that way: asked to move a couple of
  // pixels, it does not move that way at all. Against a plot's side it can
  // still run along the side, so it is only stuck in the corner the key
  // leads to.
  const atEdge = (side) => {
    const [axis, sign] = MOVES[side];
    const nudge = 2 * stage.view(target.zoom).metresPerPixel;
    const moved = stage.held({ ...target, [axis]: target[axis] + sign * nudge });
    return sign * (moved[axis] - target[axis]) < nudge / 20;
  };

  // Asks the look to go somewhere, kept to what the stage allows there.
  function aim(next) {
    Object.assign(target, stage.held(next));
    ease();
    refresh();
  }

  // Straight there, for a finger on the plot, which has to stay under it.
  function snap(next) {
    aim(next);
    cancelAnimationFrame(easing);
    easing = 0;
    stage.lookAt(target);
  }

  let easing = 0;
  let last = 0;
  function ease() {
    if (easing) return;
    last = performance.now();
    const tick = (now) => {
      const k = 1 - Math.exp(-(now - last) / EASE);
      last = now;
      const from = stage.view();
      const zoom = from.zoom * Math.pow(target.zoom / from.zoom, k);
      const x = from.x + (target.x - from.x) * k;
      const y = from.y + (target.y - from.y) * k;
      const metres = from.metresPerPixel;
      const there = Math.abs(Math.log(target.zoom / zoom)) < 1e-3
        && Math.abs(target.x - x) < metres / 4 && Math.abs(target.y - y) < metres / 4;
      stage.lookAt(there ? target : { zoom, x, y });
      easing = there ? 0 : requestAnimationFrame(tick);
    };
    easing = requestAnimationFrame(tick);
  }

  // One press of a direction. Answers false when there was nothing to do,
  // so that the key can fall through to the page.
  function move(side, repeating = false) {
    const [axis, sign] = MOVES[side];
    const next = neighbour(side);
    if (next !== null && atSeam(side)) {
      if (!repeating) cross(next);
      return true;
    }
    if (!atEdge(side)) {
      const { metresPerPixel } = stage.view(target.zoom);
      const across = (axis === 'x' ? canvas.clientWidth : canvas.clientHeight) * metresPerPixel;
      aim({ ...target, [axis]: target[axis] + sign * across * (repeating ? HELD : PRESS) });
      return true;
    }
    return false;
  }

  // Crosses to plot `next`, arriving at the edge that faces the plot you
  // left, as close as you were.
  async function cross(next) {
    if (busy) return;
    busy = true;
    Object.assign(target, stage.carried(target, Math.sign(next - at)));
    at = next;
    cancelAnimationFrame(easing);
    easing = 0;
    stage.lookAt(target);
    refresh();
    try {
      await show(at);
    } finally {
      busy = false;
      refresh();
    }
  }

  const closer = (factor) => aim({ ...target, zoom: target.zoom * factor });
  const whole = () => aim({ zoom: 1, x: 0, y: 0 });

  function turn(quarters) {
    // Finished moving first, so the turn goes round where the look was going.
    cancelAnimationFrame(easing);
    easing = 0;
    stage.lookAt(target);
    stage.turnBy(quarters);
    const { zoom, x, y } = stage.view();
    Object.assign(target, { zoom, x, y });
    turned();
    refresh();
  }

  // MARK: The buttons

  // A key with nothing to do says so, and stays where it is and stays focused:
  // `aria-disabled` rather than `disabled`, because a disabled button drops the
  // keyboard's focus to the top of the page, which is the last thing a reader
  // holding Enter on *closer* wants when they reach the closest look.
  function refresh() {
    const { closest } = stage.view();
    const can = {
      up: !atEdge('up'),
      down: !atEdge('down'),
      left: !atEdge('left') || neighbour('left') !== null,
      right: !atEdge('right') || neighbour('right') !== null,
      in: target.zoom < closest - 1e-3,
      out: target.zoom > 1 + 1e-3,
      anti: true,
      clock: true,
    };
    for (const [go, button] of Object.entries(buttons)) {
      button.setAttribute('aria-disabled', String(!can[go]));
    }
    canvas.classList.toggle('walk-stage--close', target.zoom > 1 + 1e-3);
  }

  const press = {
    up: () => move('up'), down: () => move('down'),
    left: () => move('left'), right: () => move('right'),
    in: () => closer(STEP), out: () => closer(1 / STEP),
    anti: () => turn(-1), clock: () => turn(1),
  };
  for (const [go, button] of Object.entries(buttons)) {
    button.addEventListener('click', () => {
      if (button.getAttribute('aria-disabled') === 'true') return;
      press[go]();
    });
  }

  // MARK: The keys

  whenSettled((strings) => setSheetTitle(strings.t('keys')));
  const visible = () => !nav.hidden;
  for (const [side, keys] of [['up', ['ArrowUp', 'w']], ['left', ['ArrowLeft', 'a']],
                              ['down', ['ArrowDown', 's']], ['right', ['ArrowRight', 'd']]]) {
    register({
      keys, group: 'move', target: buttons[side], when: visible,
      run: (event) => move(side, event.repeat),
    });
  }
  register({ keys: ['+', '='], group: 'look', target: buttons.in, when: visible, run: () => { closer(STEP); } });
  // Further, and all the way out: one row in the sheet, because going back to
  // the whole plot is what the minus key does when it is held long enough.
  register({
    keys: ['-', '0', 'Home'], group: 'look', target: buttons.out, when: visible,
    run: (event) => {
      if (event.key === '-') closer(1 / STEP);
      else if (target.zoom > 1 + 1e-3) whole();
      else return false;
      return true;
    },
  });
  register({ keys: ['q', '['], group: 'look', target: buttons.anti, when: visible, run: () => { turn(-1); } });
  register({ keys: ['e', ']'], group: 'look', target: buttons.clock, when: visible, run: () => { turn(1); } });

  // MARK: The canvas

  // Fingers and a mouse on the plot. Only closer in does a drag move anything,
  // and only then does the canvas keep a finger from scrolling the page
  // (`walk-stage--close` in site.css); at the whole plot a finger moving up the
  // page scrolls it, as on any other page, and two fingers pinch.
  const fingers = new Map();
  let pinch = null;

  const spread = () => {
    const [a, b] = [...fingers.values()];
    return { distance: Math.hypot(a.x - b.x, a.y - b.y), x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 };
  };

  // Closer by `factor`, keeping the point under (px, py) on the canvas where it
  // is — the fingers', or the pointer's.
  function closerAbout(factor, px, py) {
    const box = canvas.getBoundingClientRect();
    const metres = stage.view(target.zoom).metresPerPixel;
    const u = (px - box.left - box.width / 2) * metres;
    const v = -(py - box.top - box.height / 2) * metres;
    const { closest } = stage.view();
    const zoom = Math.min(Math.max(target.zoom * factor, 1), closest);
    const kept = 1 - target.zoom / zoom;
    return { zoom, x: target.x + u * kept, y: target.y + v * kept };
  }

  canvas.addEventListener('pointerdown', (event) => {
    if (event.pointerType === 'mouse' && (event.button !== 0 || target.zoom <= 1 + 1e-3)) return;
    fingers.set(event.pointerId, { x: event.clientX, y: event.clientY });
    canvas.setPointerCapture?.(event.pointerId);
    if (fingers.size === 2) pinch = spread();
  });
  canvas.addEventListener('pointermove', (event) => {
    const finger = fingers.get(event.pointerId);
    if (!finger) return;
    if (fingers.size === 1 && target.zoom > 1 + 1e-3) {
      const metres = stage.view(target.zoom).metresPerPixel;
      snap({ ...target, x: target.x - (event.clientX - finger.x) * metres,
             y: target.y + (event.clientY - finger.y) * metres });
      canvas.classList.add('walk-stage--held');
    }
    finger.x = event.clientX;
    finger.y = event.clientY;
    if (fingers.size === 2 && pinch) {
      const now = spread();
      const metres = stage.view(target.zoom).metresPerPixel;
      const next = closerAbout(now.distance / (pinch.distance || now.distance), now.x, now.y);
      snap({ ...next, x: next.x - (now.x - pinch.x) * metres, y: next.y + (now.y - pinch.y) * metres });
      pinch = now;
    }
  });
  const lift = (event) => {
    fingers.delete(event.pointerId);
    pinch = fingers.size === 2 ? spread() : null;
    if (!fingers.size) canvas.classList.remove('walk-stage--held');
  };
  canvas.addEventListener('pointerup', lift);
  canvas.addEventListener('pointercancel', lift);

  // A trackpad's pinch arrives as a wheel with the control key down, in every
  // browser but Safari, which sends its own gesture events. The plain wheel is
  // the page's.
  canvas.addEventListener('wheel', (event) => {
    if (!event.ctrlKey) return;
    event.preventDefault();
    snap(closerAbout(Math.exp(-event.deltaY * 0.01), event.clientX, event.clientY));
  }, { passive: false });
  let gesture = 1;
  canvas.addEventListener('gesturestart', (event) => { event.preventDefault(); gesture = 1; });
  canvas.addEventListener('gesturechange', (event) => {
    event.preventDefault();
    snap(closerAbout(event.scale / gesture, event.clientX, event.clientY));
    gesture = event.scale;
  });

  // A window made smaller can make the look too close or off the plot.
  new ResizeObserver(() => aim(target)).observe(canvas);

  nav.hidden = false;
  refresh();
  await show(at);
}

// The pad's markup: one grid, three by three — the four directions as a
// cross, the rings in its left-hand corners and the magnifiers in its right.
// See site.css §The pad.
function build(nav) {
  const buttons = {};
  const pad = document.createElement('span');
  pad.className = 'walk-keys__pad';
  nav.replaceChildren(pad);
  for (const key of KEYS) {
    const button = document.createElement('button');
    button.className = 'pad-key';
    button.type = 'button';
    button.dataset.go = key.go;
    button.dataset.sLabel = key.label;
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('class', 'pad-glyph');
    svg.setAttribute('viewBox', '0 0 20 20');
    svg.setAttribute('aria-hidden', 'true');
    svg.setAttribute('focusable', 'false');
    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', key.path);
    svg.append(path);
    button.append(svg);
    pad.append(button);
    buttons[key.go] = button;
  }
  // Written here as well as by `plain.js`, because these buttons may be made
  // after it has dressed the page.
  whenSettled((strings) => {
    for (const button of Object.values(buttons)) {
      const words = strings.t(button.dataset.sLabel);
      button.setAttribute('aria-label', words);
      button.title = words;
      strings.dress(button, button.dataset.sLabel);
    }
  });
  return buttons;
}
