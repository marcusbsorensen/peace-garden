<?php
/**
 * Every page on the site, none of them with a file extension, served with the
 * type it is — and the plant renderer, and the door to the plot service.
 *
 * **Why this file exists at all.** The design in Server/README.md was a pile of
 * static files and an `.htaccess` that gave `/s`, `/g`, `/t` and the
 * association file their content types. peacegarden.app on 20i does not run
 * Apache: the vhost is nginx talking to PHP-FPM and nothing else, so no
 * `.htaccess` anywhere on the host is ever read. Nothing says so — a
 * `RewriteRule` that never fires and a `ForceType` that never applies both look
 * exactly like a file that is being served — and the symptom is at the far end:
 * `/s` arrives as `application/octet-stream` and the browser saves it instead
 * of drawing it. Checked 4 September 2026 by putting a redirect and a header in
 * an `.htaccess` and watching neither happen.
 *
 * What nginx *does* offer is in its own vhost, and this file is the half of it
 * that was left for us to write:
 *
 *     location / { try_files $uri $uri/ @dispatch; }
 *     location @dispatch { if (-f $document_root/index.php) { rewrite ^ /index.php last; } }
 *
 * So a path with no file behind it arrives here with `REQUEST_URI` intact. The
 * pages therefore live in `.pages/`, off the paths they are served at —
 * a file at `/s` would win at `try_files` and be served as a download again,
 * which is the failure this file exists to fix. The leading dot is not
 * decoration: nginx's own `location ~ /\.(?!well-known(?:/|$)) { deny all; }`
 * makes the directory unreachable from outside, so there is one address for
 * each page rather than two.
 *
 * The cost is that every page needs PHP to be up. Static files did not.
 * That is a real trade and it is the one the host leaves available: `/s` is the
 * path in every link already minted and it cannot grow a `.html`, so either it
 * is served by something that can set a header or it is served wrongly.
 *
 * On a host that does read `.htaccess`, the file beside this one routes paths
 * here rather than serving them itself, so the two agree — though it names
 * only the first four, `/s`, `/g`, `/t` and the association file.
 */

declare(strict_types=1);

/**
 * Path → the file under `.pages/`, and the type it is.
 *
 * Named one by one rather than derived from the filesystem. A rule that turns
 * any file in a directory into a page is a rule that serves whatever is left in
 * that directory by accident; a table of one line per path cannot.
 */
const ROUTES = [
    // The front. It answered 403 until 16 September, which was the host's
    // default for a directory with nothing in it and read as a broken domain
    // to anybody who typed the name rather than following a link.
    '/' => ['index', 'text/html; charset=utf-8'],
    '/s' => ['s', 'text/html; charset=utf-8'],
    '/g' => ['g', 'text/html; charset=utf-8'],
    // The same file as `/g`, under the word rather than the letter. `/g` is in
    // links already minted and cannot be retired; this is what the front page
    // points at, because a path somebody may read aloud should be a word.
    '/garden' => ['g', 'text/html; charset=utf-8'],
    '/download' => ['download', 'text/html; charset=utf-8'],
    '/wild' => ['wild', 'text/html; charset=utf-8'],
    '/walk' => ['walk', 'text/html; charset=utf-8'],
    // The second built area, since 21 September. Its own page rather than a
    // query on `/walk`: the two are laid out by different rules, shown a
    // different number of plots at a time, and described in different words.
    '/quiet' => ['quiet', 'text/html; charset=utf-8'],
    // The third, the same day. Three areas, three pages: the moment a `?area=`
    // on one page would have to branch on layout, plot count and prose is the
    // moment it is three pages wearing one URL.
    '/cross' => ['cross', 'text/html; charset=utf-8'],
    // The fourth, and the one that settled it: an area whose rule leaves
    // part of the plot deliberately bare needs its own words as much as its
    // own drawing, and neither would survive a shared page.
    '/orchard' => ['orchard', 'text/html; charset=utf-8'],
    // The fifth, on 22 September. The first area whose prose has to explain a
    // rule about colour rather than about height, which is the clearest case
    // yet for a page of its own.
    '/knot' => ['knot', 'text/html; charset=utf-8'],
    // The sixth, on 23 September, and the first whose page has to say something
    // the drawing cannot: a row label carries no writing, so which kind claimed
    // which drill is written under the plot in words.
    '/seedbed' => ['seedbed', 'text/html; charset=utf-8'],
    // The seventh, on 23 September, and the first whose plants are drawn as
    // something other than what they will be: young, under glass, placed by
    // the height they will grow to.
    '/frame' => ['frame', 'text/html; charset=utf-8'],
    // The eighth, on 24 September, and the first whose plants do not all
    // stand on the ground: three in four are potted on the staging, set out as
    // a run of colour, and the tallest stand in a border along the back.
    '/glasshouse' => ['glasshouse', 'text/html; charset=utf-8'],
    // The ninth, on 24 September, and the first that knows the year: a wood
    // cut one band a winter, whose ferns on their stools are drawn at the
    // stage the service says their coupe is in.
    '/coppice' => ['coppice', 'text/html; charset=utf-8'],
    // The tenth and last, on 24 September: a kitchen garden whose crops are
    // the three forms its genus roots name, a crop to a bed.
    '/ground' => ['ground', 'text/html; charset=utf-8'],
    // What the names mean, on 23 September: the table every area page links
    // to, saying what brings a plant to each area and what its two words say.
    '/meanings' => ['meanings', 'text/html; charset=utf-8'],
    '/t' => ['t', 'text/html; charset=utf-8'],
    // A privacy notice is a mandatory App Store listing field, so this path is
    // load-bearing for the submission rather than decorative. See
    // Server/.pages/privacy.
    '/privacy' => ['privacy', 'text/html; charset=utf-8'],
    // No extension, and `application/json` or iOS declines the domain without
    // saying why. Apple's CDN currently parses the file whatever the header
    // says — it reported `Apple-Origin-Format: json` while the origin was still
    // answering `application/octet-stream` — but that is Apple being lenient
    // about a rule Apple documents, and leniency is not a thing to build on.
    '/.well-known/apple-app-site-association' => [
        'apple-app-site-association', 'application/json',
    ],
];

// **What every answer from here says about itself**, since 14 October 2026.
//
// Only what PHP answers: the pages, the plant renderer, the plot service and
// the misses. `/assets/`, `/strings/`, `/passages/` and the other static files
// are served by nginx before this file is reached, and nothing in this
// repository sets a header on those (Server/README.md §Headers).
//
// - HSTS without `includeSubDomains`: this is the one name the site has, and a
//   rule over every subdomain is a promise about hosts this file never sees.
//   A year, so a browser that has been here once never asks over `http://`
//   again, including after nginx's own directory redirect, which answers with
//   `http://` (`.htaccess` says where).
// - `strict-origin-when-cross-origin`: a link out from a seed page carries the
//   origin and no path, so where somebody was is not handed on, and nothing
//   that only ever links to itself loses anything.
// - `nosniff` everywhere rather than on two responses: every type here is
//   declared.
// - PHP names itself and its version on every response (`X-Powered-By:
//   PHP/8.3.35` on 13 October). That is the host's `expose_php`, which is not
//   ours to set, so it is taken off here instead.
header_remove('X-Powered-By');
header('Strict-Transport-Security: max-age=31536000');
header('Referrer-Policy: strict-origin-when-cross-origin');
header('X-Content-Type-Options: nosniff');

/**
 * Whether a conditional request already holds these bytes.
 *
 * `If-None-Match` is a list, may say `*`, and may carry a tag made weak on the
 * way (`W/"…"`, which nginx does to a tag on a response it compresses); a
 * comparison of the whole header with one tag missed all three. Where there is
 * no `If-None-Match`, `If-Modified-Since` is asked instead, so a cache in front
 * of this host that passes on only the date still gets its 304 (RFC 9110
 * §13.1.3: the tag wins when both are sent).
 */
$fresh = static function (string $etag, ?int $mtime = null): bool {
    $tags = $_SERVER['HTTP_IF_NONE_MATCH'] ?? null;
    if (is_string($tags) && trim($tags) !== '') {
        foreach (explode(',', $tags) as $tag) {
            $tag = trim($tag);
            if ($tag === '*' || preg_replace('#^W/#', '', $tag) === $etag) {
                return true;
            }
        }
        return false;
    }
    $since = $_SERVER['HTTP_IF_MODIFIED_SINCE'] ?? null;
    if ($mtime === null || !is_string($since)) {
        return false;
    }
    $at = strtotime($since);
    return $at !== false && $at >= $mtime;
};

/**
 * A 304, with no `Content-Type`. PHP otherwise adds its default, `text/html`,
 * to an answer that has no body to describe — and on the renderer's address a
 * cache that believed it would be holding a WebAssembly module labelled as a
 * page, which `instantiateStreaming` refuses.
 */
$notModified = static function (): never {
    ini_set('default_mimetype', '');
    header_remove('Content-Type');
    http_response_code(304);
    exit;
};

/**
 * Which build of the plant renderer is on this server: its mtime and size, the
 * mark the pages ask for it by (`PG_MODULE` below) and the one `/plant.wasm`
 * checks before it promises a reader the bytes will never change.
 */
$moduleStamp = static function (): string {
    $module = __DIR__ . '/.pages/PlantWasm.wasm';
    return is_file($module)
        ? dechex((int) filemtime($module)) . '-' . dechex((int) filesize($module))
        : 'x';
};

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
$path = is_string($path) ? rawurldecode($path) : '/';

// An empty path is the root, and the root is a page now. Normalised here
// rather than given its own entry, so the table stays one path per line.
if ($path === '') {
    $path = '/';
}

// The plot service has its own router; everything under /api/ is its.
if (str_starts_with($path, '/api/')) {
    require __DIR__ . '/.api/router.php';
    exit;
}

// **The plant renderer, compressed by hand.**
//
// It is eight megabytes of Swift built for wasm32, and nginx here gzips
// JavaScript, CSS and JSON but not `application/wasm` — measured against the
// live host on 20 September: `/assets/js/longwalk.js` comes back
// `content-encoding: gzip` and the module comes back whole. The vhost is not
// ours to add a MIME type to, so the one part of this host we do control
// serves it instead.
//
// The copies are built by `tools/wasm/build.sh` and live in `.pages/`, which
// nginx refuses outright because it is a dot-directory — so this is the only
// way to them, and there is no second address serving the module uncompressed.
//
// Eight megabytes becomes 2.8 with gzip and 2.1 with brotli. `readfile`
// streams, so none of it is held in memory.
//
// **Brotli does not arrive, and the reason is in front of this host.** 20i
// puts a CDN in front of the origin, and it normalises `Accept-Encoding` on
// the way through to cut its cache variants: a request for `br, gzip` reaches
// PHP as `gzip`, and a request for `br` alone reaches it with nothing at all —
// measured both ways on 20 September. So every browser gets the gzip. The
// brotli branch stays because it is three lines, it is right, it works on the
// local server, and it starts working by itself the day that CDN changes or
// the site moves. What it is not is a saving anybody is getting today.
if ($path === '/plant.wasm') {
    $accepts = $_SERVER['HTTP_ACCEPT_ENCODING'] ?? '';
    $forms = [['br', '.br'], ['gzip', '.gz']];
    $file = __DIR__ . '/.pages/PlantWasm.wasm';
    $encoding = null;
    foreach ($forms as [$token, $suffix]) {
        // A plain substring test: these two tokens are not prefixes of any
        // other encoding name, and a `q=0` on one of them is a browser nobody
        // has.
        if (str_contains($accepts, $token) && is_file($file . $suffix)) {
            $file .= $suffix;
            $encoding = $token;
            break;
        }
    }
    if (!is_file($file)) {
        // Built rather than committed, so the way this goes missing is a
        // deploy from a clone that has never run the build. That is a fault at
        // this end, not in the request.
        http_response_code(500);
        header('Content-Type: text/plain; charset=utf-8');
        exit("The plant renderer is missing from this server.\n");
    }

    // Of the bytes on disk, by way of size and mtime rather than a hash: this
    // is megabytes, and hashing it on every request to save sending it is the
    // wrong way round.
    $mtime = (int) filemtime($file);
    $etag = '"' . dechex($mtime) . '-' . dechex((int) filesize($file)) . '"';

    // **Kept for ever at the address that names this build, and asked about
    // every time at the one that does not.**
    //
    // This was `max-age=86400, must-revalidate` on the reasoning that a module
    // changes rarely. The flaw was that a new build was *not* a new URL — the
    // day the Quiet Garden opened, a browser that had visited `/walk` the day
    // before was told `/quiet` could not be reached, because the module it had
    // did not have the room in it. Then it was `no-cache` everywhere, on the
    // reasoning that the ETag makes a return visit one small conditional
    // request. On the live host it does not: on 13 October a conditional
    // request with the right tag came back `200` and the whole three
    // megabytes, cache status MISS at the origin and the CDN, so every visit
    // to every page that grows a plant downloaded the module again
    // (design/mass-test-2026-10-13/site/README.md, finding L1). The tag is
    // lost somewhere in front of this host, which is not ours to fix.
    //
    // Every page now asks for the module as `/plant.wasm?v=<stamp>`, and the
    // stamp changes when the bytes do. So when the stamp asked for is this
    // build's, the answer can promise never to change: a year, `immutable`, no
    // revalidation, whatever the CDN does with conditional requests. A new
    // build is a new address, and the old promise is about bytes nobody will
    // ask for again. A stamp that is not this build's — a page cached from
    // before a deploy — is answered with this build and `no-cache`, so the
    // newer bytes are never filed under an older name for a year. The bare
    // `/plant.wasm` keeps `no-cache` too: nothing promises it.
    //
    // **`private`: the year is the reader's browser's, not the CDN's.** A
    // browser keys what it keeps on the whole address, query and all, so a
    // new stamp is always a new entry there. Whether 20i's CDN keys on the
    // query is not something this repository can see or test, and a CDN that
    // did not would answer a new build's address with the old module for a
    // year, with no way to purge it. The CDN was not keeping the module before
    // either (MISS on 13 October), so nothing is given up.
    //
    // A development copy says `no-store` instead, because there the module is
    // rebuilt every few minutes. `tools/wasm/dev-router.php` sets that.
    $asked = $_GET['v'] ?? null;
    $cache = match (true) {
        (bool) ($GLOBALS['pg_no_cache'] ?? false) => 'no-store, max-age=0',
        is_string($asked) && $asked === $moduleStamp() => 'private, max-age=31536000, immutable',
        default => 'public, no-cache',
    };
    // Said on a 304 as well as a 200: a cache updates what it holds from the
    // headers of the 304 it is given.
    header('ETag: ' . $etag);
    header('Last-Modified: ' . gmdate('D, d M Y H:i:s', $mtime) . ' GMT');
    header('Vary: Accept-Encoding');
    header('Cache-Control: ' . $cache);
    if ($fresh($etag, $mtime)) {
        $notModified();
    }

    header('Content-Type: application/wasm');
    if ($encoding !== null) {
        header('Content-Encoding: ' . $encoding);
    }
    header('Content-Length: ' . filesize($file));
    readfile($file);
    exit;
}

if (!isset(ROUTES[$path])) {
    // A miss is a miss, including `/strings/en.json`, which is fetched for
    // every language except the one written into `strings.js` and is *meant*
    // to be absent. `loadStrings` reads the status, so this has to be one.
    http_response_code(404);
    header('Content-Type: text/html; charset=utf-8');
    exit("<!doctype html><title>404</title>\n");
}

[$name, $type] = ROUTES[$path];
$file = __DIR__ . '/.pages/' . $name;

$body = @file_get_contents($file);
if ($body === false) {
    // The page is missing from the upload rather than from the request. Saying
    // 404 here would read as "no such page" and send somebody to look at their
    // link; 500 sends them to look at the deploy, which is where it is.
    http_response_code(500);
    header('Content-Type: text/plain; charset=utf-8');
    exit("The page is missing from this server.\n");
}

// **A paragraph that is there only while what it describes is running.**
//
// Since 2 October 2026 the privacy page has a paragraph on the paths visitors
// wear in the Wild Fields (`privacy9`), and wear runs only where `config.php`
// turns it on. A page that described it on a site where it is off would be
// saying something untrue about the site in front of the reader, so the page
// marks the paragraph with a pair of `wear` comments and this keeps what is
// between them only where wear is on — the same switch, read the same way,
// as the routes (`WildWear::on`). Removed here rather than hidden by the
// page's script, so where wear is off the words are not in the page at all.
if (str_contains($body, '<!--wear-->')) {
    require_once __DIR__ . '/.api/settings.php';
    require_once __DIR__ . '/.api/WildWear.php';
    $body = WildWear::on(settings())
        ? preg_replace('#<!--/?wear-->#', '', $body)
        : preg_replace('#[ \t]*<!--wear-->.*?<!--/wear-->\n?#s', '', $body);
}

// **The module's address carries which build it is.**
//
// `/plant.wasm` is eight megabytes at a path that never changes, so a browser
// or a CDN that has one has no way to know a new one exists. Revalidating
// helps and is not enough: 20i's CDN holds a response for its full max-age and
// is not ours to purge, so the day the Quiet Garden opened a returning visitor
// was told the area could not be reached for up to a day after it had been.
//
// So the pages that load it ask for it by a name that changes when the bytes
// do — the same mtime-and-size stamp the module's own ETag is made of. A page
// is served by this file and a JavaScript module is not, which is why the
// stamp is put in the page and read from there rather than written into
// `walkpage.js`. `PG_MODULE` in a page is this, and a page without it is
// untouched.
//
// Since 14 October 2026 the stamp is also what lets `/plant.wasm` above be
// kept for a year: an address that names its build can promise its bytes.
if (str_contains($body, 'PG_MODULE')) {
    $body = str_replace('PG_MODULE', '/plant.wasm?v=' . $moduleStamp(), $body);
}

// **So does every script and the stylesheet, since 24 September 2026.**
//
// The same fault as the module's, one layer up. nginx serves `/assets/` itself,
// before this file is reached, and sends no `Cache-Control` — so a browser
// keeps a script for as long as its own heuristic says (a tenth of the time
// since the file last changed), and 20i's CDN keeps one copy per encoding it
// has normalised to. The day the dictionary shipped, a returning browser ran
// the new pages against yesterday's `meanings.js`: the panels drew, and the
// words in them did not, with nothing in the console to say why.
//
// Two halves, because a module is reached two ways:
//
// - a `src` or `href` written in the page gets the file's stamp in its query,
//   the same mtime-and-size stamp as the module's;
// - a module imported by another — `./meanings.js` from `walkpage.js` — is
//   given its stamped address by an import map written into the head, which
//   every browser this site supports reads. Its keys are the unstamped
//   addresses, so a relative import resolves to one and is sent on.
//
// A page's entry script and the same module imported from elsewhere must end
// up at one address, or the browser runs two copies and `plain.js`'s settled
// language is held twice. Both halves use the one stamp, so they do.
$assets = __DIR__ . '/assets';
$stampOf = static function (string $relative) use ($assets): ?string {
    $file = $assets . '/' . $relative;
    return is_file($file) ? dechex((int) filemtime($file)) . '-' . dechex((int) filesize($file)) : null;
};
$body = preg_replace_callback(
    '#\b(src|href)="/assets/([A-Za-z0-9_./-]+\.(?:js|css))"#',
    static function (array $m) use ($stampOf): string {
        $stamp = $stampOf($m[2]);
        return $stamp === null ? $m[0] : "{$m[1]}=\"/assets/{$m[2]}?v={$stamp}\"";
    },
    $body
);
// The import map is the one script written into a page rather than fetched,
// so it is the one the page's Content-Security-Policy names by its hash.
$inline = [];
if (str_contains($body, 'type="module"')) {
    $imports = [];
    foreach (glob($assets . '/js/*.js') ?: [] as $file) {
        $name = basename($file);
        $imports["/assets/js/{$name}"] = "/assets/js/{$name}?v=" . $stampOf("js/{$name}");
    }
    $map = json_encode(['imports' => $imports], JSON_UNESCAPED_SLASHES);
    $inline[] = "'sha256-" . base64_encode(hash('sha256', $map, true)) . "'";
    // Before any module script, which the head is: an import map that arrives
    // after the first module has started loading is ignored.
    $body = preg_replace('#</head>#', "  <script type=\"importmap\">{$map}</script>\n  </head>", $body, 1);
}

// **What a page may load, since 14 October 2026: its own files and nothing
// else.** Every page is already that — no analytics, no font CDN, no
// third-party anything, each page's head says so — and the policy makes it a
// rule the browser keeps rather than a habit. Each part is what the pages
// need and no more:
//
// - scripts from this site, the import map by its hash (above), and
//   `wasm-unsafe-eval`, without which a browser refuses to compile the plant
//   renderer. It allows WebAssembly and nothing else: `eval` stays refused.
// - styles, images, fonts, and every `fetch` (the plot service, the
//   catalogues, the passage banks, the renderer, the sky's stars) from this
//   site, under `default-src`. A style set from a script (`--area-ground` on a
//   front card) is not an inline style in the policy's sense; none of the
//   pages has a `style` attribute or a `<style>` block.
// - **one exception, for WebKit's own `<select>`**: every browser on an iPhone
//   draws a `<select>` with a style attribute inside its own shadow tree, and
//   refuses it under a policy without `'unsafe-inline'` for style attributes
//   — one refusal on every page with the language chooser, logged in Safari's
//   console, found by the crawler's WebKit pass and reproduced on a page with
//   nothing in it but an empty `<select>`. The refusal changes nothing on
//   screen (the bar is pixel for pixel the same either way), but a console
//   with a refusal on every page is one where a real one goes unseen. So
//   style *attributes* are allowed (`style-src-attr`); `<style>` blocks and
//   stylesheets from elsewhere are not, and scripts are untouched. A browser that does not know
//   `style-src-attr` falls back to `default-src` and refuses them, as before.
// - no plug-ins, no `<base>`, a form only to this site (the tester door on
//   `/t`), and no page of this site inside somebody else's frame.
//
// Checked with the site crawler on 14 October 2026: no refusal on any page in
// any of the 43 languages in Chrome, or in five of them in WebKit. A new
// inline script, a `<style>` block, or a file from another host will be
// refused by the browser and named in its console — which is the point — so
// add it here first.
$policy = implode('; ', [
    "default-src 'self'",
    "script-src 'self' 'wasm-unsafe-eval'" . ($inline ? ' ' . implode(' ', $inline) : ''),
    "style-src-attr 'unsafe-inline'",
    "object-src 'none'",
    "base-uri 'none'",
    "form-action 'self'",
    "frame-ancestors 'none'",
]);

// A seed link is opened once and then often re-opened from the same message, so
// a conditional request is worth answering. The tag is of the bytes, so it
// changes when the page does and not when the upload runs — and, since the
// module's stamp is in them, when a new module is deployed.
$etag = '"' . md5($body) . '"';
header('ETag: ' . $etag);
// On a 304 as well, for a cache that refreshes what it holds from one.
// (Browsers keep the `Content-` headers they stored with the page, so a page
// kept from before the policy gets it when its bytes next change — which the
// deploy that brought the policy did to every page, by changing the
// stylesheet's stamp.)
if (str_starts_with($type, 'text/html')) {
    header('Content-Security-Policy: ' . $policy);
}
if ($fresh($etag)) {
    $notModified();
}

header('Content-Type: ' . $type);
header('Content-Length: ' . strlen($body));
echo $body;
