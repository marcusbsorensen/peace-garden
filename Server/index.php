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
    '/s' => ['s', 'text/html; charset=utf-8'],
    '/g' => ['g', 'text/html; charset=utf-8'],
    '/t' => ['t', 'text/html; charset=utf-8'],
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

// The root answers 403 here because it answered 403 before this file existed,
// and whether peacegarden.app/ is anything at all is an open question in
// docs/WEBSITE.md rather than one to settle by accident. Without this, `/`
// would fall to the index and quietly become whatever this script returns.
if ($path === '/' || $path === '') {
    http_response_code(403);
    header('Content-Type: text/html; charset=utf-8');
    exit("<!doctype html><title>403</title>\n");
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
