<?php
// The whole site, locally, with the plot service behind it — same-origin, the
// way the live host is:
//
//   php -S localhost:8803 -t Server tools/wasm/dev-router.php
//
// **Why the document root is `Server/` and no longer `tools/wasm/web`.** The
// Long Walk used to be a workbench page with its own copy of the modules that
// draw it. It is a page on the site now (`/walk`), those modules live in
// `Server/assets/js/`, and a second copy of `sky.js` beside a first is the one
// thing the sky was ported carefully to avoid. So there is one copy, the site
// serves it, and this serves the site.
//
// Three kinds of path:
//
// - `/api/…` is the plot service, through `Server/index.php` as the live host
//   routes it. Planting is open only if `Server/.api/config.php` opens it.
// - `/dev/…` is the workbench: pages that are **not** in `Server/` and are
//   therefore never deployed, drawing from the same `/assets/` the real pages
//   draw from. `/dev/walk` invents a walk of a few hundred arrivals so the
//   geometry can be argued about while the real one is empty; `/dev/plant`
//   grows one plant from one seed.
// - Anything else is a file under `Server/` if there is one — PHP's own server
//   handles those when this returns false — and otherwise a page out of
//   `Server/index.php`'s table.
$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';

if (str_starts_with($path, '/api/')) {
    require __DIR__ . '/../../Server/index.php';
    return true;
}

// **The module is never cached locally.** The live host sends it with a day's
// max-age, which is right for a file whose name changes when its contents do
// and wrong for one that is rebuilt every few minutes: a browser inside that
// day serves the old module without asking, and the page then runs yesterday's
// Swift against today's JavaScript. That has cost two wrong readings already —
// exports that were there reported missing, and a walk that opened empty when
// it no longer does. So here, and only here, it revalidates every time.
$GLOBALS['pg_no_cache'] = true;

$bench = ['/dev/walk' => 'web/walk.html', '/dev/quiet' => 'web/quiet.html',
          '/dev/cross' => 'web/cross.html',
          '/dev/orchard' => 'web/orchard.html',
          '/dev/knot' => 'web/knot.html',
          '/dev/plant' => 'web/index.html'];
if (isset($bench[$path])) {
    header('Content-Type: text/html; charset=utf-8');
    header('Cache-Control: no-store');
    readfile(__DIR__ . '/' . $bench[$path]);
    return true;
}

// An extensionless path with no file behind it is a page. `.pages/` is not a
// second address for one: nginx refuses dot-directories on the live host and
// this refuses them here for the same reason.
if (str_starts_with($path, '/.pages')) {
    http_response_code(403);
    return true;
}
if (!is_file(__DIR__ . '/../../Server' . $path)) {
    require __DIR__ . '/../../Server/index.php';
    return true;
}
return false;
