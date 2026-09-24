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
// `0` and Home glide back to the whole plot, as the middle of the pad does, `Q` and `[` turn anticlockwise, `E`
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
// In the order the pad reads, row by row, so the keyboard's Tab walks it as
// the eye does.
const KEYS = [
  { go: 'clock', label: 'walkTurnClock', path: 'M13.73 4.68A6.5 6.5 0 1 1 6.27 4.68M5.93 7.91L6.27 4.68L3.04 4.34' },
  { go: 'up', label: 'moveUp', path: 'M4.5 12.75L10 7.25L15.5 12.75' },
  { go: 'anti', label: 'walkTurnAnti', path: 'M6.27 4.68A6.5 6.5 0 1 0 13.73 4.68M16.96 4.34L13.73 4.68L14.07 7.91' },
  { go: 'left', label: 'moveLeft', path: 'M12.75 4.5L7.25 10L12.75 15.5' },
  // Home: a filled dot in a square, the plot and the middle of it (Marcus).
  { go: 'home', label: 'moveHome', path: 'M6 4.5H14A1.5 1.5 0 0 1 15.5 6V14A1.5 1.5 0 0 1 14 15.5H6A1.5 1.5 0 0 1 4.5 14V6A1.5 1.5 0 0 1 6 4.5Z',
    dot: 'M10 8.25A1.75 1.75 0 1 1 10 11.75A1.75 1.75 0 1 1 10 8.25Z' },
  { go: 'right', label: 'moveRight', path: 'M7.25 4.5L12.75 10L7.25 15.5' },
  { go: 'out', label: 'zoomOut', path: `${LENS}M6.25 8.5H10.75` },
  { go: 'down', label: 'moveDown', path: 'M4.5 7.25L10 12.75L15.5 7.25' },
  { go: 'in', label: 'zoomIn', path: `${LENS}M6.25 8.5H10.75M8.5 6.25V10.75` },
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

// **The way home is a glide, not an ease.** The middle of the pad takes the
// look back to the whole plot the way a camera would: pulling back and
// panning together, slow at both ends, so the reader sees where they were
// go by on the way out and keeps their bearings. Its length grows with how far
// there is to come — how many times closer, and how far across — between
// these two, in milliseconds. Marcus, 24 September.
const GLIDE_LEAST = 450;
const GLIDE_MOST = 1200;
const stillness = window.matchMedia('(prefers-reduced-motion: reduce)');

/// Puts the pad in `nav` and answers to it, to the keys and to the canvas.
///
/// - `stage`: the area's `makePlotStage`.
/// - `plots`: how many the plot service has opened.
/// - `step`: how many plots one crossing moves, which is how many the page
///   shows at once — three on the walk, one everywhere else.
/// - `show(first)`: grows the plots from `first`; may be slow, is awaited.
/// - `turned()`: after a turn, for the sky, which faces the way the camera does.
/// - `plants`: what a tap on a plant opens — `plantpanel.js`, the same on every
///   area page. Told when a plot is about to go and when one has been grown,
///   and asked which plot to open on, which is how a postcard lands.
///
/// Shows the first plot, and resolves when it is grown.
export async function openMovePad({ nav, canvas, stage, plots, step = 1, show: grow, turned = () => {}, plants = null }) {
  const buttons = build(nav);
  // The plot a postcard names, or the first. Rounded down to a page of `step`,
  // because the walk only ever shows its plots three at a time from a multiple
  // of three, and a postcard to its fifth plot opens on the fourth to sixth.
  const asked = Math.min(Math.max(0, plants?.start?.() ?? 0), Math.max(0, plots - 1));
  let at = asked - (asked % step);
  let busy = false;

  // Growing a plot takes the plants the panel may be showing off the stage, so
  // it is told first; and told again once the new ones stand, so a postcard
  // can find its plant among them.
  const show = async (first) => {
    plants?.leaving?.();
    await grow(first);
    plants?.shown?.(first);
  };

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
  let gliding = false;
  function ease() {
    // Anything asked for during a glide takes over from wherever it has got
    // to, rather than waiting for it to land.
    if (gliding) {
      cancelAnimationFrame(easing);
      easing = 0;
      gliding = false;
    }
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

  const atHome = () => target.zoom <= 1 + 1e-3
    && Math.abs(target.x) < 1e-3 && Math.abs(target.y) < 1e-3;

  // Back to the whole plot of the plot you are on, by a glide. The turn is
  // kept: a reader who has turned the plot has chosen which way to face.
  //
  // The pan is spread over the zoom rather than over the time. Moved evenly in
  // metres, the look would race across the ground while it is close and crawl
  // once it is far; moved with the width of the window, it crosses the screen
  // at a steady pace the whole way out.
  function home() {
    cancelAnimationFrame(easing);
    easing = 0;
    const from = stage.view();
    Object.assign(target, stage.held({ zoom: 1, x: 0, y: 0 }));
    const to = { ...target };
    const span = Math.abs(Math.log(to.zoom / from.zoom));
    const wide = canvas.clientWidth * stage.view(1).metresPerPixel;
    const far = Math.hypot(to.x - from.x, to.y - from.y) / wide;
    const length = stillness.matches ? 0
      : Math.min(GLIDE_MOST, GLIDE_LEAST + 260 * span + 500 * far);
    refresh();
    if (length === 0) {
      stage.lookAt(to);
      return;
    }
    const zoomed = Math.abs(1 / to.zoom - 1 / from.zoom) > 1e-6;
    const start = performance.now();
    gliding = true;
    const tick = (now) => {
      if (!gliding) return;
      const t = Math.min(1, (now - start) / length);
      const s = t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
      const zoom = from.zoom * Math.pow(to.zoom / from.zoom, s);
      const u = zoomed ? (1 / zoom - 1 / from.zoom) / (1 / to.zoom - 1 / from.zoom) : s;
      stage.lookAt(t < 1 ? { zoom, x: from.x + (to.x - from.x) * u, y: from.y + (to.y - from.y) * u } : to);
      if (t < 1) {
        easing = requestAnimationFrame(tick);
      } else {
        easing = 0;
        gliding = false;
      }
    };
    easing = requestAnimationFrame(tick);
  }

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
      home: !atHome(),
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
    in: () => closer(STEP), out: () => closer(1 / STEP), home: () => home(),
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
  register({ keys: ['-'], group: 'look', target: buttons.out, when: visible, run: () => { closer(1 / STEP); } });
  // Home, the middle of the pad: the same glide, and nothing to do (so the key
  // falls through to the page) when the whole plot is already in view.
  register({
    keys: ['0', 'Home'], group: 'look', target: buttons.home, when: visible,
    run: () => {
      if (atHome()) return false;
      home();
      return true;
    },
  });
  register({ keys: ['q', '['], group: 'look', target: buttons.anti, when: visible, run: () => { turn(-1); } });
  register({ keys: ['e', ']'], group: 'look', target: buttons.clock, when: visible, run: () => { turn(1); } });
  // The plant in the middle of the window, for a reader without a pointer:
  // move the window to it with the pad's keys, then `p`. Listed in the `?`
  // sheet under the pad's own keys.
  if (plants) {
    register({
      keys: ['p'], group: 'look', label: () => plants.keyLabel(), when: visible,
      run: () => {
        const box = canvas.getBoundingClientRect();
        return plants.tapped(box.left + box.width / 2, box.top + box.height / 2, { nearest: true }) !== false;
      },
    });
  }

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

  // **A tap is a press that neither moved nor had company.** The drag and the
  // pinch above use the same fingers, so a tap is read from its own record of
  // them rather than theirs: one pointer down, lifted within a few pixels of
  // where it went down, with no second finger at any point. It is answered on
  // the `click` that follows rather than on the lift, so the panel it opens is
  // not under the finger when the browser sends that click on — and a finger
  // that scrolled the page instead is cancelled by the browser and never
  // clicks at all.
  const SLOP = 8;
  const down = new Set();
  let tap = null;
  canvas.addEventListener('pointerdown', (event) => {
    down.add(event.pointerId);
    tap = down.size === 1 && (event.pointerType !== 'mouse' || event.button === 0)
      ? { x: event.clientX, y: event.clientY } : null;
  });
  canvas.addEventListener('pointermove', (event) => {
    if (tap && Math.hypot(event.clientX - tap.x, event.clientY - tap.y) > SLOP) tap = null;
  });
  const up = (event) => { down.delete(event.pointerId); };
  canvas.addEventListener('pointerup', up);
  canvas.addEventListener('pointercancel', (event) => { up(event); tap = null; });
  canvas.addEventListener('click', (event) => {
    const was = tap;
    tap = null;
    if (was && plants && !busy) plants.tapped(event.clientX, event.clientY);
  });

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
  // What the panel needs of the pad: which plot is showing, and a way to go to
  // a plant — `zoom` times closer, with the plant `[dx, dy]` CSS pixels from the
  // middle of the window (right and down), as a glide.
  plants?.attach?.({
    stage, canvas,
    at: () => at,
    busy: () => busy,
    go: (point, zoom, [dx, dy] = [0, 0]) => {
      const there = stage.toward(point, zoom);
      const metres = stage.view(there.zoom).metresPerPixel;
      Object.assign(target, stage.held({ ...there, x: there.x - dx * metres, y: there.y + dy * metres }));
      if (stillness.matches) {
        cancelAnimationFrame(easing);
        easing = 0;
        stage.lookAt(target);
        refresh();
      } else {
        ease();
        refresh();
      }
    },
  });
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
    if (key.dot) {
      const dot = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      dot.setAttribute('d', key.dot);
      dot.setAttribute('class', 'pad-glyph__dot');
      svg.append(dot);
    }
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
