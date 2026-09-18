<?php
// A local copy of the plot service beside the browser pages, same-origin as
// the live site will be:
//
//   php -S localhost:8803 -t tools/wasm/web tools/wasm/dev-router.php
//
// /api/… goes to the real service in Server/; everything else is a file in
// tools/wasm/web. Planting is open only if Server/.api/config.php opens it.
$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
if (str_starts_with($path, '/api/')) {
    require __DIR__ . '/../../Server/index.php';
    return true;
}
return false;
