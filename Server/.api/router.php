<?php
declare(strict_types=1);

/**
 * The plot service, at /api/…, same-origin with the pages (WEBSITE.md, 2 September).
 *
 *   GET  /api/garden               the ten areas, and which a plant can stand in
 *   GET  /api/walk                 how many plots the Long Walk has opened
 *   GET  /api/walk/plot/{n}        a plot's plantings: seed, parents, meeting, spot
 *   GET  /api/quiet                the same, for the Quiet Garden
 *   GET  /api/quiet/plot/{n}       the same, for the Quiet Garden
 *   GET  /api/cross                the same, for the Crossing
 *   GET  /api/cross/plot/{n}       the same, for the Crossing
 *   GET  /api/orchard              the same, for the Orchard
 *   GET  /api/orchard/plot/{n}     the same, for the Orchard
 *   GET  /api/knot                 the same, for the Knot Garden
 *   GET  /api/knot/plot/{n}        the same, for the Knot Garden
 *   GET  /api/seedbed              the same, for the Seedbed
 *   GET  /api/seedbed/plot/{n}     the same, for the Seedbed
 *   GET  /api/frame                the same, for the Cold Frame
 *   GET  /api/frame/plot/{n}       the same, for the Cold Frame
 *   GET  /api/glasshouse           the same, for the Glasshouse
 *   GET  /api/glasshouse/plot/{n}  the same, for the Glasshouse, each planting
 *                                  with how far off the floor it stands
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
 * **Eight of ten areas are open**, and the service says which: the Seedbed
 * (`beginnings`), the Cold Frame (`waiting`), the Glasshouse (`light`), the
 * Knot Garden (`pattern`), the Long Walk (`travel`), the Crossing (`meeting`),
 * the Orchard (`kinship`) and the Quiet Garden (`peace`). The other two have
 * names, layouts and a place on the map and no placement rule, so a plant
 * cannot stand in them.
 * `Areas.php` is the list and `GET /api/garden` is how a phone learns it
 * without being told by a version of itself.
 *
 * **The asking is the garden's, though its routes are spelled `/api/walk/…`.**
 * An offer carries the area its plant belongs to and is planted there when it
 * is answered; the spelling stays because it is a live address that a deployed
 * page and an installed app both call, and an installed app cannot be asked to
 * learn a new one. What is the travel area's alone is `GET /api/walk` and
 * `GET /api/walk/plot/{n}`, and every other open area has its own pair beside
 * them, listed above.
 *
 * **Plot 0 opens with the Long Walk's ambassador in it**, which is not a row
 * and is not in any of the routes above: `WalkStore` derives its slot from the
 * pinned seed in `Ambassadors.php` and serves it at the head of the plot, with
 * an empty `parents` because it was minted rather than crossed. So the walk has
 * had one plot and one plant in it since the garden opened, and nothing anybody
 * can offer, answer or withdraw touches it.
 *
 * Reached from `index.php`, which hands over any path under /api/.
 */

require_once __DIR__ . '/Areas.php';
require_once __DIR__ . '/Seeds.php';
require_once __DIR__ . '/Limits.php';
require_once __DIR__ . '/WalkStore.php';

function respond(int $status, array $body): never
{
    // A refusal is worth a line in the log, and the line is the status and the
    // route only. A body here carries tokens, and a token in a log is a way to
    // answer for somebody: the one thing the address being secret is for.
    if ($status >= 400) {
        error_log(sprintf('plot service: %d on %s', $status, $GLOBALS['path'] ?? '?'));
    }
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

/**
 * The store, opened once a request.
 *
 * Held, because the rate limit asks for it before the route does and two
 * `WalkStore::open` calls are two connections and two runs of the migrations
 * for one request.
 */
function store(array $settings): WalkStore
{
    static $open = null;
    if ($open !== null) return $open;

    if (str_starts_with($settings['dsn'], 'sqlite:')) {
        $directory = dirname(substr($settings['dsn'], strlen('sqlite:')));
        if (!is_dir($directory)) mkdir($directory, 0700, true);
    }
    return $open = WalkStore::open($settings['dsn'], $settings['user'], $settings['password']);
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
 * SeedCore's own derivation, held to it in CI. The height, the family, the kind
 * and the hue are the four the placement rules need and the four only a grown
 * plant can give, so they are taken on trust and held to what a plant can
 * actually be.
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

    // **The kind, which is the plant's epithet**, and the third trait a rule can
    // want: the Seedbed claims a drill by it. Absent means the empty kind, which
    // is what every plant offered before 23 September carries and what the other
    // five areas ignore.
    //
    // Lower case, because every epithet is built that way (`Epithet.Form`), so a
    // capital is a sign that something upstream is wrong rather than something
    // to take quietly — two spellings of one kind would be two drills. Held to
    // 64 characters, which is the column's width.
    $kind = $plant['kind'] ?? '';
    if (!is_string($kind) || !preg_match('/\A[a-z]{0,64}\z/', $kind)) {
        respond(400, ['error' => 'kind is a plant\'s epithet: up to 64 lower-case letters, or absent.']);
    }

    // **The hue, as a turn of the colour circle**: 0 up to but not including 1,
    // as the genome holds it. The fourth trait, and the Glasshouse's alone — it
    // stands a pot at its place in the staging's spectrum. Absent means null,
    // which is what every plant offered before 24 September carries and what
    // the Glasshouse reads as it reads a pale flower: any free pot.
    //
    // A number, never a string, and taken as the exact double the phone sent:
    // it is the seed's bytes through arithmetic alone, so it is the same double
    // here as on the phone, and a band edge falls the same side of it in both.
    $hue = $plant['hue'] ?? null;
    if ($hue !== null && (!(is_float($hue) || is_int($hue)) || $hue < 0 || $hue >= 1)) {
        respond(400, ['error' => 'hue is a turn of the colour circle, 0 up to 1, or absent.']);
    }
    if (Seeds::cross($parents[0], $parents[1], $encounter) !== $seed) {
        respond(422, ['error' => 'That seed is not the cross of those parents at that meeting.']);
    }

    // **Which area it belongs to**, which the phone works out from the plant's
    // own genus head — `Arrangement.theme(of:)`, the same ten themes that order
    // the passages. Absent means the Long Walk, because that is where every
    // plant offered before today went and an older app must keep working.
    //
    // **The area is taken on trust, exactly as the height and the colour family
    // are.** A service cannot grow the plant to check any of the three; what it
    // can check is that the seed really is the cross of those parents at that
    // meeting, which is the thing that stops one person planting in another's
    // name. A caller who lies about the area misfiles their own plant.
    $area = $plant['area'] ?? 'travel';
    if (!Areas::exists($area)) {
        respond(400, ['error' => 'area is one of the garden\'s ten, or absent for the Long Walk.']);
    }
    if (!Areas::isOpen($area)) {
        // 409 rather than 400: the request is well formed and would be right on
        // another day. The phone says so in those words — the area is not open
        // yet, rather than something is wrong with your plant.
        respond(409, ['error' => 'That area of the garden is not open yet.', 'area' => $area,
                      'open' => Areas::OPEN]);
    }

    return ['seed' => $seed, 'parents' => [$parents[0], $parents[1]], 'encounter' => $encounter,
            'height' => (float) $height, 'family' => $family, 'area' => $area, 'kind' => $kind,
            'hue' => $hue === null ? null : (float) $hue];
}

/**
 * Stops here if this caller has written too often lately.
 *
 * Before the body is read and before anything is looked up, so a caller that
 * is over its limit costs the service a counter and nothing else. `Limits.php`
 * says what is kept and for how long — a salted bucket and a count, never an
 * address.
 */
function withinLimits(array $settings, string $path): void
{
    $wait = (new Limits(store($settings)->connection()))
        ->wait($path, Limits::caller($_SERVER), time());
    if ($wait === null) return;

    header('Retry-After: ' . $wait);
    respond(429, [
        'error' => 'That is more writing than this service takes from one place in an hour.',
        'retryAfter' => $wait,
    ]);
}

function route(string $method, string $path): never
{
    $settings = settings();

    // Every route that writes, and `pending` too: it is the one a phone calls
    // unprompted, so it is the one a script would call in a loop.
    if ($method === 'POST' && isset(Limits::ROUTES[$path])) {
        withinLimits($settings, $path);
    }

    // **The whole garden, named, before anything is offered to it.** A phone
    // asks this to find out whether the area its plant belongs to is built,
    // because the alternative is a version of the app deciding that for itself
    // and being wrong the day an area opens. **The app has asked since 21
    // September** — until then it read its own compiled list and this route
    // had no caller but the website, which was the thing it was built to
    // prevent happening quietly.
    //
    // It carries nothing and takes nothing: no token, no body, no limit. It is
    // the one route here that says nothing about whoever asked.
    if ($path === '/api/garden' && $method === 'GET') {
        respond(200, ['areas' => Areas::all()]);
    }

    if ($path === '/api/walk' && $method === 'GET') {
        respond(200, ['plots' => store($settings)->plots()]);
    }

    if (preg_match('#\A/api/walk/plot/(0|[1-9][0-9]{0,5})\z#', $path, $m) && $method === 'GET') {
        $plot = (int) $m[1];
        respond(200, ['plot' => $plot, 'plantings' => store($settings)->plot($plot)]);
    }

    if ($path === '/api/quiet' && $method === 'GET') {
        respond(200, ['plots' => store($settings)->room()->plots()]);
    }

    if (preg_match('#\A/api/quiet/plot/(0|[1-9][0-9]{0,5})\z#', $path, $m) && $method === 'GET') {
        $plot = (int) $m[1];
        respond(200, ['plot' => $plot, 'plantings' => store($settings)->room()->plot($plot)]);
    }

    if ($path === '/api/cross' && $method === 'GET') {
        respond(200, ['plots' => store($settings)->cross()->plots()]);
    }

    if (preg_match('#\A/api/cross/plot/(0|[1-9][0-9]{0,5})\z#', $path, $m) && $method === 'GET') {
        $plot = (int) $m[1];
        respond(200, ['plot' => $plot, 'plantings' => store($settings)->cross()->plot($plot)]);
    }

    if ($path === '/api/orchard' && $method === 'GET') {
        respond(200, ['plots' => store($settings)->orchard()->plots()]);
    }

    if (preg_match('#\A/api/orchard/plot/(0|[1-9][0-9]{0,5})\z#', $path, $m) && $method === 'GET') {
        $plot = (int) $m[1];
        respond(200, ['plot' => $plot, 'plantings' => store($settings)->orchard()->plot($plot)]);
    }

    if ($path === '/api/knot' && $method === 'GET') {
        respond(200, ['plots' => store($settings)->knot()->plots()]);
    }

    if (preg_match('#\A/api/knot/plot/(0|[1-9][0-9]{0,5})\z#', $path, $m) && $method === 'GET') {
        $plot = (int) $m[1];
        respond(200, ['plot' => $plot, 'plantings' => store($settings)->knot()->plot($plot)]);
    }

    if ($path === '/api/seedbed' && $method === 'GET') {
        respond(200, ['plots' => store($settings)->seedbed()->plots()]);
    }

    if (preg_match('#\A/api/seedbed/plot/(0|[1-9][0-9]{0,5})\z#', $path, $m) && $method === 'GET') {
        $plot = (int) $m[1];
        respond(200, ['plot' => $plot, 'plantings' => store($settings)->seedbed()->plot($plot)]);
    }

    if ($path === '/api/frame' && $method === 'GET') {
        respond(200, ['plots' => store($settings)->coldFrame()->plots()]);
    }

    if (preg_match('#\A/api/frame/plot/(0|[1-9][0-9]{0,5})\z#', $path, $m) && $method === 'GET') {
        $plot = (int) $m[1];
        respond(200, ['plot' => $plot, 'plantings' => store($settings)->coldFrame()->plot($plot)]);
    }

    if ($path === '/api/glasshouse' && $method === 'GET') {
        respond(200, ['plots' => store($settings)->glasshouse()->plots()]);
    }

    if (preg_match('#\A/api/glasshouse/plot/(0|[1-9][0-9]{0,5})\z#', $path, $m) && $method === 'GET') {
        $plot = (int) $m[1];
        respond(200, ['plot' => $plot, 'plantings' => store($settings)->glasshouse()->plot($plot)]);
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
            $plant['encounter'], $plant['height'], $plant['family'], time(), $plant['area'],
            $plant['kind'], $plant['hue']
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
            respond(403, ['error' => 'The garden opens for planting once sharing has sign-in and both gardeners\' consent.']);
        }
        $plant = checkedPlant(readBody(4096));
        [$planting, $new] = store($settings)->plantInto(
            $plant['area'], $plant['seed'], $plant['parents'][0], $plant['parents'][1],
            $plant['encounter'], $plant['height'], $plant['family'], $plant['kind'], $plant['hue']
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
