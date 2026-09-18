<?php
declare(strict_types=1);

/**
 * The plot service, at /api/…, same-origin with the pages (WEBSITE.md, 2 September).
 *
 *   GET  /api/walk                 how many plots the Long Walk has opened
 *   GET  /api/walk/plot/{n}        a plot's plantings: seed, parents, meeting, spot
 *   POST /api/walk/plant           plants one arrival by the rule
 *
 * **Planting is closed until sign-in and consent exist.** A plant goes up only
 * when both gardeners have said so, and the service has no way yet to know who
 * is asking; until it does, the write answers 403 unless `open_for_planting`
 * is set in `.api/config.php`, which is for a local copy only.
 *
 * Reached from `index.php`, which hands over any path under /api/.
 */

require_once __DIR__ . '/Seeds.php';
require_once __DIR__ . '/WalkStore.php';

function respond(int $status, array $body): never
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-cache');
    header('X-Content-Type-Options: nosniff');
    header('X-Robots-Tag: noindex');
    exit(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_PRESERVE_ZERO_FRACTION));
}

function settings(): array
{
    $file = __DIR__ . '/config.php';
    $given = is_file($file) ? require $file : [];
    return $given + [
        // Outside public_html, beside it, so the file is never a URL.
        'dsn' => 'sqlite:' . dirname(__DIR__, 2) . '/peacegarden-data/walk.sqlite',
        'user' => null,
        'password' => null,
        'open_for_planting' => false,
    ];
}

function store(array $settings): WalkStore
{
    if (str_starts_with($settings['dsn'], 'sqlite:')) {
        $directory = dirname(substr($settings['dsn'], strlen('sqlite:')));
        if (!is_dir($directory)) mkdir($directory, 0700, true);
    }
    return WalkStore::open($settings['dsn'], $settings['user'], $settings['password']);
}

function route(string $method, string $path): never
{
    $settings = settings();

    if ($path === '/api/walk' && $method === 'GET') {
        respond(200, ['plots' => store($settings)->plots()]);
    }

    if (preg_match('#\A/api/walk/plot/(0|[1-9][0-9]{0,5})\z#', $path, $m) && $method === 'GET') {
        $plot = (int) $m[1];
        respond(200, ['plot' => $plot, 'plantings' => store($settings)->plot($plot)]);
    }

    if ($path === '/api/walk/plant' && $method === 'POST') {
        if (!$settings['open_for_planting']) {
            respond(403, ['error' => 'The Long Walk opens for planting once sharing has sign-in and both gardeners\' consent.']);
        }
        $raw = file_get_contents('php://input', false, null, 0, 4096);
        $body = json_decode($raw === false ? '' : $raw, true);
        if (!is_array($body)) respond(400, ['error' => 'The body is a JSON object.']);

        $seed = $body['seed'] ?? null;
        $parents = $body['parents'] ?? null;
        $encounter = $body['encounter'] ?? null;
        $height = $body['height'] ?? null;
        $family = $body['family'] ?? null;
        if (!Seeds::isHex32($seed) || !is_array($parents) || count($parents) !== 2
            || !Seeds::isHex32($parents[0] ?? null) || !Seeds::isHex32($parents[1] ?? null)
            || !Seeds::isHex32($encounter)) {
            respond(400, ['error' => 'seed, parents (two) and encounter are each 64 lowercase hex characters.']);
        }
        // What the rule places by, from the grown plant, which only the phone
        // can grow. Held to the range a plant can actually reach.
        if (!(is_float($height) || is_int($height)) || $height < 0.05 || $height > 4.0
            || !is_int($family) || $family < 0 || $family > 6) {
            respond(400, ['error' => 'height is metres, 0.05 to 4; family is 0 to 6.']);
        }
        if (Seeds::cross($parents[0], $parents[1], $encounter) !== $seed) {
            respond(422, ['error' => 'That seed is not the cross of those parents at that meeting.']);
        }
        [$planting, $new] = store($settings)->plant($seed, $parents[0], $parents[1], $encounter, (float) $height, $family);
        respond($new ? 201 : 200, $planting);
    }

    respond(404, ['error' => 'No such route.']);
}

try {
    route($_SERVER['REQUEST_METHOD'] ?? 'GET', $GLOBALS['path']);
} catch (Throwable $error) {
    error_log('plot service: ' . $error->getMessage());
    respond(500, ['error' => 'The plot service could not answer.']);
}
