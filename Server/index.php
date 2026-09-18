<?php
/**
 * The four paths that have no file extension, served with the type they are.
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
 * four pages therefore live in `.pages/`, off the paths they are served at —
 * a file at `/s` would win at `try_files` and be served as a download again,
 * which is the failure this file exists to fix. The leading dot is not
 * decoration: nginx's own `location ~ /\.(?!well-known(?:/|$)) { deny all; }`
 * makes the directory unreachable from outside, so there is one address for
 * each page rather than two.
 *
 * The cost is that these four paths need PHP to be up. Static files did not.
 * That is a real trade and it is the one the host leaves available: `/s` is the
 * path in every link already minted and it cannot grow a `.html`, so either it
 * is served by something that can set a header or it is served wrongly.
 *
 * On a host that does read `.htaccess`, the file beside this one routes the
 * same four paths here rather than serving them itself, so the two agree.
 */

declare(strict_types=1);

/**
 * Path → the file under `.pages/`, and the type it is.
 *
 * Named one by one rather than derived from the filesystem. A rule that turns
 * any file in a directory into a page is a rule that serves whatever is left in
 * that directory by accident; four lines of table cannot.
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

// A seed link is opened once and then often re-opened from the same message, so
// a conditional request is worth answering. The tag is of the bytes, so it
// changes when the page does and not when the upload runs.
$etag = '"' . md5($body) . '"';
header('ETag: ' . $etag);
if (trim($_SERVER['HTTP_IF_NONE_MATCH'] ?? '') === $etag) {
    http_response_code(304);
    exit;
}

header('Content-Type: ' . $type);
header('Content-Length: ' . strlen($body));
// The type is declared, so there is nothing to be gained by letting a browser
// guess a different one.
header('X-Content-Type-Options: nosniff');
echo $body;
