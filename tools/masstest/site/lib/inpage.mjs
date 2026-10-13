// What the crawler asks of a page once it has settled, and what it plants in
// the page before any of the page's own scripts run. Both are sent into the
// browser as source, so each must stand alone: no imports, no closures.

/// Runs before the page's scripts: records every WebAssembly compile and
/// instantiation and how it ended, every WebGL context asked for and whether
/// one came back, lost contexts, animation frames, unhandled rejections, and
/// the largest contentful paint and layout shifts as the browser reports them.
export function initScript() {
  const pg = (window.__pg = {
    wasm: [], gl: [], glLost: 0, raf: 0, rejections: [], lcp: null, lcpElement: null, cls: 0, shifts: 0, fcp: null,
  });
  for (const fn of ['instantiateStreaming', 'instantiate', 'compileStreaming', 'compile']) {
    const orig = WebAssembly[fn];
    if (typeof orig !== 'function') continue;
    WebAssembly[fn] = function (...args) {
      const rec = { fn, t: Math.round(performance.now()) };
      pg.wasm.push(rec);
      return orig.apply(this, args).then(
        (r) => { rec.ok = true; rec.ms = Math.round(performance.now() - rec.t); return r; },
        (e) => { rec.ok = false; rec.error = String(e && e.message || e); throw e; },
      );
    };
  }
  // When the document first takes the language it was asked for.
  new MutationObserver(() => { if (pg.langAt === undefined) pg.langAt = Math.round(performance.now()); })
    .observe(document.documentElement, { attributes: true, attributeFilter: ['lang'] });
  const getContext = HTMLCanvasElement.prototype.getContext;
  HTMLCanvasElement.prototype.getContext = function (type, ...rest) {
    const ctx = getContext.call(this, type, ...rest);
    if (/webgl/i.test(String(type))) {
      pg.gl.push({ type: String(type), ok: !!ctx });
      if (!this.__pgWatched) {
        this.__pgWatched = true;
        this.addEventListener('webglcontextlost', () => { pg.glLost += 1; });
      }
    }
    return ctx;
  };
  const raf = window.requestAnimationFrame;
  window.requestAnimationFrame = function (cb) { pg.raf += 1; return raf.call(window, cb); };
  window.addEventListener('unhandledrejection', (e) => {
    pg.rejections.push(String(e.reason && (e.reason.stack || e.reason.message) || e.reason).slice(0, 400));
  });
  try {
    new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        pg.lcp = Math.round(entry.startTime);
        const el = entry.element;
        pg.lcpElement = el ? `${el.tagName.toLowerCase()}${el.className && typeof el.className === 'string' ? '.' + el.className.split(/\s+/).join('.') : ''}` : (entry.url || null);
      }
    }).observe({ type: 'largest-contentful-paint', buffered: true });
    new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        if (!entry.hadRecentInput) { pg.cls += entry.value; pg.shifts += 1; }
      }
    }).observe({ type: 'layout-shift', buffered: true });
    new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) if (entry.name === 'first-contentful-paint') pg.fcp = Math.round(entry.startTime);
    }).observe({ type: 'paint', buffered: true });
  } catch { /* an older engine; the numbers stay null */ }
}

/// The audit itself. Returns plain data; the crawler decides what is a fault.
export function audit(opts) {
  const vw = document.documentElement.clientWidth;
  const vh = window.innerHeight;
  const cut = (s, n = 120) => (s.length > n ? s.slice(0, n) + '…' : s);
  const norm = (s) => String(s || '').replace(/\s+/g, ' ').trim();
  const selectorOf = (el) => {
    if (!el || el.nodeType !== 1) return '';
    const parts = [];
    for (let e = el; e && e.nodeType === 1 && parts.length < 4; e = e.parentElement) {
      let part = e.tagName.toLowerCase();
      if (e.id) { part += `#${e.id}`; parts.unshift(part); break; }
      const cls = typeof e.className === 'string' ? e.className.trim().split(/\s+/).filter(Boolean).slice(0, 2) : [];
      if (cls.length) part += '.' + cls.join('.');
      const key = e.getAttribute && (e.getAttribute('data-s') || e.getAttribute('data-s-label'));
      if (key) part += `[data-s=${key}]`;
      parts.unshift(part);
    }
    return parts.join(' > ');
  };
  const shown = (el) => {
    if (!el || !el.isConnected) return false;
    if (typeof el.checkVisibility === 'function' && !el.checkVisibility({ checkOpacity: true, checkVisibilityCSS: true })) return false;
    const r = el.getBoundingClientRect();
    return r.width > 0 && r.height > 0;
  };
  const deliberatelyHidden = (el) => {
    for (let e = el; e && e !== document.body; e = e.parentElement) {
      if (e.classList && (e.classList.contains('visually-hidden') || e.classList.contains('sr-only'))) return true;
      if (e.getAttribute && e.getAttribute('aria-hidden') === 'true' && e.tagName !== 'svg') return true;
      const cs = getComputedStyle(e);
      if (cs.clip && cs.clip !== 'auto' && /rect\(0/.test(cs.clip)) return true;
      if (cs.clipPath && /inset\(50%/.test(cs.clipPath)) return true;
      const r = e.getBoundingClientRect();
      if (r.width <= 1 && r.height <= 1) return true;
    }
    return false;
  };
  const html = document.documentElement;
  const out = {
    url: location.href,
    title: document.title,
    lang: html.getAttribute('lang'),
    dir: html.getAttribute('dir') || getComputedStyle(html).direction,
    bodyDir: getComputedStyle(document.body).direction,
    scrollWidth: html.scrollWidth,
    clientWidth: vw,
    docHeight: html.scrollHeight,
  };
  const x0 = window.scrollX;
  window.scrollTo(1e6, window.scrollY);
  const xr = Math.abs(window.scrollX);
  window.scrollTo(-1e6, window.scrollY);
  const xl = Math.abs(window.scrollX);
  window.scrollTo(x0, window.scrollY);
  out.scrollableX = Math.max(xr, xl);

  // Elements reaching past the viewport's sides.
  const all = [...document.body.querySelectorAll('*')];
  const wide = [];
  for (const el of all) {
    if (['SCRIPT', 'STYLE', 'NOSCRIPT', 'TEMPLATE', 'OPTION'].includes(el.tagName)) continue;
    if (!shown(el)) continue;
    const cs = getComputedStyle(el);
    if (cs.position === 'fixed' && el.getAttribute('aria-hidden') === 'true') continue;
    const r = el.getBoundingClientRect();
    if (r.right > vw + 1 || r.left < -1) {
      if (deliberatelyHidden(el)) continue;
      // Clipped by an ancestor narrower than the viewport is the ancestor's business.
      let clipped = false;
      for (let a = el.parentElement; a && a !== document.body && a !== html; a = a.parentElement) {
        const acs = getComputedStyle(a);
        if (acs.overflowX !== 'visible') {
          const ar = a.getBoundingClientRect();
          if (ar.right <= vw + 1 && ar.left >= -1) { clipped = true; break; }
        }
      }
      if (!clipped) wide.push(el);
    }
  }
  const wideSet = new Set(wide);
  out.wide = wide
    .filter((el) => ![...el.querySelectorAll('*')].some((c) => wideSet.has(c)))
    .slice(0, 8)
    .map((el) => {
      el.setAttribute('data-mt-wide', '');
      const r = el.getBoundingClientRect();
      return { sel: selectorOf(el), left: Math.round(r.left), right: Math.round(r.right), width: Math.round(r.width), text: cut(norm(el.textContent), 60) };
    });
  out.wideCount = wideSet.size;

  // Text: clipped by an ancestor, truncated with an ellipsis, or spilling out
  // of its own box; and every visible string, for the translation comparison.
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  const clipped = [];
  const spills = [];
  const offscreen = [];
  const scrollers = new Set();
  const strings = new Map();
  const rects = [];
  const range = document.createRange();
  for (let node = walker.nextNode(); node; node = walker.nextNode()) {
    const text = norm(node.nodeValue);
    if (!text) continue;
    const el = node.parentElement;
    if (!el || ['SCRIPT', 'STYLE', 'NOSCRIPT', 'TEMPLATE', 'OPTION', 'SELECT', 'TITLE'].includes(el.tagName)) continue;
    if (el.closest('select, svg text')) continue;
    if (!shown(el)) continue;
    const hidden = deliberatelyHidden(el);
    range.selectNodeContents(node);
    const list = [...range.getClientRects()].filter((r) => r.width > 0 && r.height > 0);
    if (!list.length) continue;
    const tr = list.reduce((u, r) => ({ left: Math.min(u.left, r.left), right: Math.max(u.right, r.right), top: Math.min(u.top, r.top), bottom: Math.max(u.bottom, r.bottom) }),
      { left: Infinity, right: -Infinity, top: Infinity, bottom: -Infinity });
    const langEl = el.closest('[lang]');
    const keyEl = el.closest('[data-s]');
    const record = strings.get(text) || { text: cut(text, 200), n: 0, lang: langEl ? langEl.getAttribute('lang') : null, key: keyEl ? keyEl.getAttribute('data-s') : null, hidden };
    record.n += 1;
    strings.set(text, record);
    if (hidden) continue;
    rects.push({ el, list: list.slice(0, 8), text, layer: el.closest('dialog[open], [popover], .plant-panel') || [...(function* up(e) { for (; e; e = e.parentElement) yield e; })(el)].find((e) => getComputedStyle(e).position === 'fixed') || null });
    const inScroller = (() => {
      for (let a = el.parentElement; a && a !== document.body; a = a.parentElement) {
        const acs = getComputedStyle(a);
        if (/(auto|scroll)/.test(acs.overflowX) && a.scrollWidth > a.clientWidth + 1) return true;
      }
      return false;
    })();
    if ((tr.right > vw + 1 || tr.left < -1) && !inScroller) {
      el.setAttribute('data-mt-offtext', '');
      offscreen.push({ sel: selectorOf(el), text: cut(text, 60), left: Math.round(tr.left), right: Math.round(tr.right) });
    }
    // An ancestor that clips.
    for (let a = el; a && a !== html; a = a.parentElement) {
      const acs = getComputedStyle(a);
      const cx = acs.overflowX !== 'visible';
      const cy = acs.overflowY !== 'visible';
      if (!cx && !cy) continue;
      const ar = a.getBoundingClientRect();
      const left = ar.left + a.clientLeft, top = ar.top + a.clientTop;
      const right = left + a.clientWidth, bottom = top + a.clientHeight;
      const outX = cx && (tr.left < left - 1 || tr.right > right + 1);
      const outY = cy && (tr.top < top - 1 || tr.bottom > bottom + 1);
      if (outX || outY) {
        const scrolls = /(auto|scroll)/.test(acs.overflowX + acs.overflowY) && (a.scrollWidth > a.clientWidth + 1 || a.scrollHeight > a.clientHeight + 1);
        if (scrolls) scrollers.add(selectorOf(a));
        else if (!(a === document.body || a === html)) {
          a.setAttribute('data-mt-clip', '');
          clipped.push({ sel: selectorOf(el), by: selectorOf(a), axis: outX ? (outY ? 'xy' : 'x') : 'y', text: cut(text, 60),
            over: Math.round(Math.max(left - tr.left, tr.right - right, top - tr.top, tr.bottom - bottom)) });
        }
      }
      break;
    }
    const cs = getComputedStyle(el);
    if (cs.textOverflow === 'ellipsis' && el.scrollWidth > el.clientWidth + 1) {
      el.setAttribute('data-mt-clip', '');
      clipped.push({ sel: selectorOf(el), by: 'ellipsis', axis: 'x', text: cut(text, 60), over: el.scrollWidth - el.clientWidth });
    }
    // Spilling out of its own box, where the box is a block of its own.
    if (!/^inline$|^contents$/.test(cs.display)) {
      const er = el.getBoundingClientRect();
      const over = Math.max(er.left - tr.left, tr.right - er.right, tr.bottom - er.bottom - 2);
      if (over > 2) {
        el.setAttribute('data-mt-spill', '');
        spills.push({ sel: selectorOf(el), text: cut(text, 60), over: Math.round(over), box: `${Math.round(er.width)}x${Math.round(er.height)}` });
      }
    }
  }
  out.scrollers = [...scrollers].slice(0, 10);
  out.clipped = clipped.slice(0, 20);
  out.clippedCount = clipped.length;
  out.spills = spills.slice(0, 20);
  out.spillCount = spills.length;
  out.offscreenText = offscreen.slice(0, 10);
  out.offscreenTextCount = offscreen.length;

  // Text over text: two strings from elements neither inside the other.
  const overlaps = [];
  for (let i = 0; i < rects.length && overlaps.length < 12; i++) {
    for (let j = i + 1; j < rects.length && overlaps.length < 12; j++) {
      const a = rects[i], b = rects[j];
      if (a.el === b.el || a.el.contains(b.el) || b.el.contains(a.el)) continue;
      // An overlay over the page is meant to cover it.
      if (a.layer !== b.layer) continue;
      // Line box against line box: a paragraph's union would cover an inline
      // word set beside it on the same line.
      let w = 0, h = 0;
      for (const ra of a.list) {
        for (const rb of b.list) {
          const ww = Math.min(ra.right, rb.right) - Math.max(ra.left, rb.left);
          const hh = Math.min(ra.bottom, rb.bottom) - Math.max(ra.top, rb.top);
          if (ww > 4 && hh > 4 && ww * hh > w * h) { w = ww; h = hh; }
        }
      }
      if (w > 4 && h > 4) {
        a.el.setAttribute('data-mt-overlap', '');
        overlaps.push({ a: selectorOf(a.el), at: cut(a.text, 40), b: selectorOf(b.el), bt: cut(b.text, 40), w: Math.round(w), h: Math.round(h) });
      }
    }
  }
  out.overlaps = overlaps;

  out.strings = [...strings.values()].slice(0, 500);

  // The catalogue's own view: which keys came back in English, and every key's words.
  out.fellBack = [...document.querySelectorAll('body [lang="en"]')]
    .filter((el) => shown(el))
    .map((el) => ({ key: el.getAttribute('data-s') || el.getAttribute('data-s-label') || (el.closest('[data-s]') && el.closest('[data-s]').getAttribute('data-s')) || null, sel: selectorOf(el), text: cut(norm(el.textContent), 80) }))
    .slice(0, 60);
  out.keys = {};
  for (const el of document.querySelectorAll('[data-s]')) out.keys[el.getAttribute('data-s')] = cut(norm(el.textContent), 200);
  out.labels = {};
  for (const el of document.querySelectorAll('[data-s-label]')) {
    out.labels[el.getAttribute('data-s-label')] = cut(norm(el.getAttribute('aria-label') || el.getAttribute('title') || ''), 120);
  }
  out.emptyKeys = [...document.querySelectorAll('[data-s]')].filter((el) => shown(el) && !norm(el.textContent)).map((el) => el.getAttribute('data-s'));
  const visibleText = norm(document.body.innerText);
  out.rawKeys = [...new Set((visibleText.match(/(?<![\w.])[a-z]+(?:[A-Z][a-z0-9]+)+(?![\w])/g) || []))].filter((w) => !/^(iPhone|iPad|iOS|macOS)$/.test(w)).slice(0, 20);
  out.placeholders = [...new Set(visibleText.match(/\{[A-Za-z_]+\}|\bundefined\b|\bNaN\b|\[object Object\]|\bnull\b/g) || [])];

  // Links, anchors and images.
  out.links = [...new Set([...document.querySelectorAll('a[href]')].map((a) => a.getAttribute('href')))].slice(0, 200);
  out.badAnchors = [...document.querySelectorAll('a[href^="#"]')].map((a) => a.getAttribute('href'))
    .filter((h) => h.length > 1 && !/^#p=/.test(h) && !document.getElementById(decodeURIComponent(h.slice(1)))).slice(0, 10);
  out.imgNoAlt = [...document.querySelectorAll('img')].filter((i) => !i.hasAttribute('alt')).map((i) => i.getAttribute('src')).slice(0, 10);
  out.imgBroken = [...document.querySelectorAll('img')].filter((i) => i.complete && i.naturalWidth === 0 && shown(i)).map((i) => i.currentSrc || i.getAttribute('src')).slice(0, 10);
  out.controlsNoName = [...document.querySelectorAll('button, a[href], select, input, [role="button"]')]
    .filter((el) => shown(el) && !norm(el.textContent) && !el.getAttribute('aria-label') && !el.getAttribute('title') && !el.getAttribute('aria-labelledby') && !(el.labels && el.labels.length && [...el.labels].some((l) => norm(l.textContent))))
    .map((el) => selectorOf(el)).slice(0, 10);

  // Right to left: the document, and runs set against it.
  const rtlChars = /[֐-ࣿיִ-﷿ﹰ-﻿]/;
  const latinOnly = /^[\x20-\x7E -ɏ‐-‧]+$/;
  const bar = document.querySelector('.bar__home');
  const ways = document.querySelector('.bar__ways');
  out.bar = bar && ways ? { home: Math.round(bar.getBoundingClientRect().left), ways: Math.round(ways.getBoundingClientRect().left) } : null;
  if (opts && opts.rtl) {
    const ltrWithRtl = [];
    const rtlLatinPunct = [];
    for (const el of all) {
      if (!el.childNodes.length || !shown(el)) continue;
      const own = [...el.childNodes].filter((n) => n.nodeType === 3).map((n) => n.nodeValue).join('').trim();
      if (!own) continue;
      const dir = getComputedStyle(el).direction;
      if (dir === 'ltr' && rtlChars.test(own) && !el.closest('select')) ltrWithRtl.push({ sel: selectorOf(el), text: cut(own, 50) });
      if (dir === 'rtl' && latinOnly.test(own) && /[.!?:;,)]$|^[(]/.test(own) && own.split(' ').length > 1) rtlLatinPunct.push({ sel: selectorOf(el), text: cut(own, 50) });
    }
    out.rtl = { ltrWithRtl: ltrWithRtl.slice(0, 10), ltrWithRtlCount: ltrWithRtl.length, rtlLatinPunct: rtlLatinPunct.slice(0, 10), rtlLatinPunctCount: rtlLatinPunct.length };
  }

  // The chooser.
  const select = document.querySelector('#language, select.chooser__select');
  out.chooser = select ? { options: select.options.length, value: select.value } : null;

  // What the init script saw.
  const pg = window.__pg || {};
  out.pg = { langAt: pg.langAt, wasm: pg.wasm, gl: pg.gl, glLost: pg.glLost, rejections: pg.rejections, lcp: pg.lcp, lcpElement: pg.lcpElement, cls: Math.round((pg.cls || 0) * 1000) / 1000, shifts: pg.shifts, fcp: pg.fcp, raf: pg.raf };
  out.canvases = [...document.querySelectorAll('canvas')].filter(shown).map((c) => `${c.width}x${c.height}`);
  out.animations = document.getAnimations ? document.getAnimations().filter((a) => a.playState === 'running').length : null;
  out.viewport = { w: vw, h: vh };
  return out;
}
