<?php
declare(strict_types=1);

/**
 * The plot service, at /api/…, same-origin with the pages (WEBSITE.md, 2 September).
 *
 *   GET  /api/walk                 how many plots the Long Walk has opened
 *   GET  /api/walk/plot/{n}        a plot's plantings: seed, parents, meeting, spot
 *   POST /api/walk/offer           one gardener offers a plant, addressed to the other
 *   POST /api/walk/pending         what is waiting on these tokens, either way round
 *   POST /api/walk/answer          the other gardener says yes or no
 *   POST /api/walk/withdraw        either of them takes it back
 *   POST /api/walk/plant           plants one arrival directly, for the test harness
 *
 * **Nothing is planted by one gardener alone.** A plant made at a meeting is
 * grown from both parents' seeds, so showing it publishes the other gardener's
 * seed too, and it takes both of them (WEBSITE.md, amended 18 September). The
 * asking is `Offers.php`: an offer is addressed to the sixteen bytes its
 * recipient minted at that meeting, and only that phone can answer it. There is
 * no account anywhere in it, and the service never learns a name.
 *
 * **`/plant` stays shut**, because it is the one route that plants without
 * anybody being asked. It answers 403 unless `open_for_planting` is set in
 * `.api/config.php`, which is for a local copy and for the reference check.
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

/** The request's JSON object, or a 400. */
function readBody(int $limit = 8192): array
{
    $raw = file_get_contents('php://input', false, null, 0, $limit);
    $body = json_decode($raw === false ? '' : $raw, true);
    if (!is_array($body)) respond(400, ['error' => 'The body is a JSON object.']);
    return $body;
}

/**
 * One plant, checked as far as a service can check it.
 *
 * The seed has to be the cross of those two parents at that meeting, which is
 * what stops an invented plant being put in the walk — `Seeds::cross` is
 * SeedCore's own derivation, held to it in CI. The height and family are the
 * two the placement rule needs and the two only a grown plant can give, so they
 * are taken on trust and held to the range a plant can actually reach.
 */
function checkedPlant(mixed $plant): array
{
    if (!is_array($plant)) respond(400, ['error' => 'plant is a JSON object.']);
    $seed = $plant['seed'] ?? null;
    $parents = $plant['parents'] ?? null;
    $encounter = $plant['encounter'] ?? null;
    $height = $plant['height'] ?? null;
    $family = $plant['family'] ?? null;
    if (!Seeds::isHex32($seed) || !is_array($parents) || count($parents) !== 2
        || !Seeds::isHex32($parents[0] ?? null) || !Seeds::isHex32($parents[1] ?? null)
        || !Seeds::isHex32($encounter)) {
        respond(400, ['error' => 'seed, parents (two) and encounter are each 64 lowercase hex characters.']);
    }
    if (!(is_float($height) || is_int($height)) || $height < 0.05 || $height > 4.0
        || !is_int($family) || $family < 0 || $family > 6) {
        respond(400, ['error' => 'height is metres, 0.05 to 4; family is 0 to 6.']);
    }
    if (Seeds::cross($parents[0], $parents[1], $encounter) !== $seed) {
        respond(422, ['error' => 'That seed is not the cross of those parents at that meeting.']);
    }
    return ['seed' => $seed, 'parents' => [$parents[0], $parents[1]], 'encounter' => $encounter,
            'height' => (float) $height, 'family' => $family];
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

    if ($path === '/api/walk/offer' && $method === 'POST') {
        $body = readBody();
        $to = $body['to'] ?? null;
        $from = $body['from'] ?? null;
        if (!Seeds::isHex16($to) || !Seeds::isHex16($from) || $to === $from) {
            respond(400, ['error' => 'to and from are each 32 lowercase hex characters, and are not the same token.']);
        }
        $plant = checkedPlant($body['plant'] ?? null);
        [$offer, $new] = store($settings)->offers()->offer(
            $plant['seed'], $to, $from, $plant['parents'][0], $plant['parents'][1],
            $plant['encounter'], $plant['height'], $plant['family'], time()
        );
        respond($new ? 201 : 200, ['offer' => $offer]);
    }

    if ($path === '/api/walk/pending' && $method === 'POST') {
        $body = readBody();
        $tokens = $body['tokens'] ?? null;
        // Capped, because the request is a bag of tokens and an uncapped bag is
        // a way to ask the service about arbitrarily many at once. A garden of
        // three hundred meetings asks in three requests.
        if (!is_array($tokens) || count($tokens) > 128) {
            respond(400, ['error' => 'tokens is an array of at most 128 tokens.']);
        }
        foreach ($tokens as $token) {
            if (!Seeds::isHex16($token)) respond(400, ['error' => 'Each token is 32 lowercase hex characters.']);
        }
        respond(200, ['offers' => store($settings)->offers()->touching(array_values($tokens))]);
    }

    if ($path === '/api/walk/answer' && $method === 'POST') {
        $body = readBody();
        $seed = $body['seed'] ?? null;
        $to = $body['to'] ?? null;
        $yes = $body['yes'] ?? null;
        if (!Seeds::isHex32($seed) || !Seeds::isHex16($to) || !is_bool($yes)) {
            respond(400, ['error' => 'seed is 64 hex characters, to is 32, and yes is a boolean.']);
        }
        $answered = store($settings)->offers()->answer($seed, $to, $yes, time());
        // The same answer whether there is no such offer or the token is wrong,
        // so the route cannot be used to find out which plants have been offered.
        if ($answered === null) respond(404, ['error' => 'No offer for that plant at that token.']);
        respond(200, $answered);
    }

    if ($path === '/api/walk/withdraw' && $method === 'POST') {
        $body = readBody();
        $seed = $body['seed'] ?? null;
        $token = $body['token'] ?? null;
        if (!Seeds::isHex32($seed) || !Seeds::isHex16($token)) {
            respond(400, ['error' => 'seed is 64 hex characters and token is 32.']);
        }
        $offer = store($settings)->offers()->withdraw($seed, $token, time());
        if ($offer === null) respond(404, ['error' => 'No offer for that plant at that token.']);
        respond(200, ['offer' => $offer]);
    }

    if ($path === '/api/walk/plant' && $method === 'POST') {
        if (!$settings['open_for_planting']) {
            respond(403, ['error' => 'The Long Walk opens for planting once sharing has sign-in and both gardeners\' consent.']);
        }
        $plant = checkedPlant(readBody(4096));
        [$planting, $new] = store($settings)->plant(
            $plant['seed'], $plant['parents'][0], $plant['parents'][1],
            $plant['encounter'], $plant['height'], $plant['family']
        );
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
