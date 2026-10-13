<?php
// The live host, as near as PHP's own server can stand in for it.
//
//   PHP_CLI_SERVER_WORKERS=6 php -S 127.0.0.1:8822 -t Server tools/masstest/site/router.php
//
// peacegarden.app is nginx in front of PHP-FPM, and Server/README.md names
// the three lines of its vhost that decide what a path is:
//
//     location ~ /\.(?!well-known(?:/|$)) { deny all; }
//     location / { try_files $uri $uri/ @dispatch; }
//     location @dispatch { if (-f $document_root/index.php) { rewrite ^ /index.php last; } }
//
// So: a dot-segment anywhere but `.well-known` is a 403 before anything else;
// a file that exists is served by nginx itself, typed from nginx's own
// `mime.types` (not PHP's, which types `.js` differently); and everything else
// reaches `index.php` with `REQUEST_URI` intact. `tools/wasm/dev-router.php`
// is the workbench's router and serves files with PHP's types and `/dev/`
// pages besides, which is right for building and wrong for checking what the
// host sends; this is the second.
//
// Two things the upload does that the router copies, because a local
// directory holds files the host never sees: `tools/deploy.sh` leaves out
// `README.md` (sender-side filter) and `.DS_Store`, so both are misses here.
//
// nginx and 20i's CDN compress JavaScript, CSS, JSON and SVG on the way out
// (measured on the live host; Server/index.php notes it does not compress
// wasm, which `index.php` serves pre-compressed itself). Done here too, so a
// page's weight measured locally is the weight a phone downloads.
//
// Not part of the site and never uploaded: it lives in tools/, not Server/.

$root = rtrim($_SERVER['DOCUMENT_ROOT'], '/');
$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
$path = is_string($path) ? rawurldecode($path) : '/';
if ($path === '') $path = '/';

if (preg_match('#/\.(?!well-known(?:/|$))#', $path)) {
    http_response_code(403);
    header('Content-Type: text/html');
    echo "<html><head><title>403 Forbidden</title></head><body><center><h1>403 Forbidden</h1></center></body></html>\n";
    return true;
}

$excluded = ['/README.md'];
$file = $root . $path;
$isExcluded = in_array($path, $excluded, true) || basename($path) === '.DS_Store';

if (!$isExcluded && $path !== '/' && is_file($file)) {
    $types = [
        'html' => 'text/html', 'htm' => 'text/html', 'css' => 'text/css',
        'js' => 'application/javascript', 'mjs' => 'application/javascript',
        'json' => 'application/json', 'svg' => 'image/svg+xml', 'png' => 'image/png',
        'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'gif' => 'image/gif',
        'webp' => 'image/webp', 'ico' => 'image/x-icon', 'txt' => 'text/plain',
        'wasm' => 'application/wasm', 'woff2' => 'font/woff2', 'woff' => 'font/woff',
        'xml' => 'text/xml', 'pdf' => 'application/pdf',
    ];
    $ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
    $type = $types[$ext] ?? 'application/octet-stream';
    $mtime = (int) filemtime($file);
    $size = (int) filesize($file);
    $etag = '"' . dechex($mtime) . '-' . dechex($size) . '"';
    header('ETag: ' . $etag);
    header('Last-Modified: ' . gmdate('D, d M Y H:i:s', $mtime) . ' GMT');
    if (trim($_SERVER['HTTP_IF_NONE_MATCH'] ?? '') === $etag) {
        http_response_code(304);
        return true;
    }
    $compressible = in_array($type, ['text/css', 'application/javascript', 'application/json',
                                     'image/svg+xml', 'text/html', 'text/plain', 'text/xml'], true);
    $body = file_get_contents($file);
    header('Content-Type: ' . $type . (str_starts_with($type, 'text/') ? '; charset=utf-8' : ''));
    if ($compressible && str_contains($_SERVER['HTTP_ACCEPT_ENCODING'] ?? '', 'gzip') && $size > 256) {
        $body = gzencode($body, 6);
        header('Content-Encoding: gzip');
        header('Vary: Accept-Encoding');
    }
    header('Content-Length: ' . strlen($body));
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'HEAD') echo $body;
    return true;
}

if (!$isExcluded && $path !== '/' && is_dir($file)) {
    // nginx's `$uri/` with no index file in the directory and autoindex off.
    http_response_code(str_ends_with($path, '/') ? 403 : 301);
    if (!str_ends_with($path, '/')) header('Location: ' . $path . '/');
    header('Content-Type: text/html');
    return true;
}

// @dispatch
$_SERVER['SCRIPT_NAME'] = '/index.php';
$_SERVER['SCRIPT_FILENAME'] = $root . '/index.php';
require $root . '/index.php';
return true;
