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
 *   GET  /api/coppice              the same, for the Coppice
 *   GET  /api/coppice/plot/{n}     the same, for the Coppice, with the year of its
 *                                  rotation, each coupe's stage in it, and each
 *                                  fern on a stool drawn at its coupe's stage
 *   GET  /api/ground               the same, for the Home Ground
 *   GET  /api/ground/plot/{n}      the same, for the Home Ground
 *   POST /api/walk/offer           one gardener offers a plant, addressed to the other
 *   POST /api/walk/pending         what is waiting on these tokens, either way round
 *   POST /api/walk/answer          the other gardener says yes or no
 *   POST /api/walk/withdraw        either of them takes it back
 *   POST /api/walk/plant           plants one arrival directly, for the test harness
 *   GET  /api/wild                 the Wild Fields: how big, and how many stand in each tile
 *   GET  /api/wild/tile/{x}/{z}    what stands in one tile: seed, parents, spot
 *   POST /api/wild/release         one gardener lets a plant go into the Wild Fields
 *   POST /api/wild/answer          either of its two gardeners says what of theirs stands beside it
 *   GET  /api/wild/wear            the paths visitors have worn: a number per worn ground cell
 *   POST /api/wild/wear            a batch of ground cells a visitor's window crossed while walking
 *
 * **The two wear routes are off unless this copy turns them on**, with
 * `'wear' => true` in `.api/config.php` (since 2 October 2026, `WildWear.php`).
 * The live site's `config.php` is written on the server and does not say so,
 * so there they answer 404 as any unknown route does, `GET /api/wild` says
 * nothing about wear, and the page records nothing and draws nothing. Wear
 * is the first thing on the site that learns where people go, and it stays
 * off until the privacy page says so in every language
 * (`docs/WEB-GARDENS.md` §*Paths that visitors wear*).
 *
 * **The Wild Fields are not an area** (`WildStore.php`, since 1 October
 * 2026). Nothing in them is placed by a rule: a released plant stands where
 * its seed says (`WildFields.php`), and there is no asking, because releasing
 * is one gardener letting go of their own copy (`docs/PHASES.md`, *Releasing
 * is one person's*). What a release does check is in the route below.
 *
 * **Nothing is planted by one gardener alone.** A plant made at a meeting is
 * grown from both parents' seeds, so showing it publishes the other gardener's
 * seed too, and it takes both of them (WEBSITE.md, amended 18 September). The
 * asking is `Offers.php`: an offer is addressed to the sixteen bytes its
 * recipient minted at that meeting, and only that phone can answer it. There is
 * no account anywhere in it, and the service never learns a name.
 *
 * **Taking back deletes, and an unanswered offer lapses after thirty days.**
 * Either way the seed, the parents, the meeting and the traits leave the
 * database, and a planting keeps only its place (`TakenBack.php`,
 * `Offers.php`).
 *
 * **`/plant` stays shut**, because it is the one route that plants without
 * anybody being asked. It answers 403 unless `open_for_planting` is set in
 * `.api/config.php`, which is for a local copy and for the reference check.
 *
 * **All ten areas are open**, and the service says which: the Seedbed
 * (`beginnings`), the Cold Frame (`waiting`), the Coppice (`renewal`), the
 * Glasshouse (`light`), the Knot Garden (`pattern`), the Home Ground
 * (`ground`), the Long Walk (`travel`), the Crossing (`meeting`), the Orchard
 * (`kinship`) and the Quiet Garden (`peace`). The Home Ground opened last, on
 * 24 September 2026.
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
        // Paths that visitors wear in the Wild Fields. Off; see above.
        'wear' => false,
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

    // **The habit, the plant's archetype's name**: `fern`, `star`, `umbel`. The
    // fifth trait, read by two areas — a fern stands on a stool in the Coppice
    // and is cut with its coupe, and in the Home Ground the habit names the
    // crop. Absent means the empty habit, which is what every plant offered
    // before the Coppice opened carries; the Coppice reads it as a star, and the
    // Home Ground sows it as an umbel.
    // Lower-case letters only, as `Archetype` spells them, and 16 at most, the
    // column's width.
    $habit = $plant['habit'] ?? '';
    if (!is_string($habit) || !preg_match('/\A[a-z]{0,16}\z/', $habit)) {
        respond(400, ['error' => 'habit is a plant\'s archetype: up to 16 lower-case letters, or absent.']);
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
            'hue' => $hue === null ? null : (float) $hue, 'habit' => $habit];
}

/**
 * What one gardener chooses to show beside a plant in the Wild Fields: their
 * gardener name, where they met and the month they met, each the value to
 * show or absent for not. Since 1 October 2026 (`WildStore.php`).
 *
 * **No free text beyond what the phone already kept.** The name is the one
 * the gardener chose for meetings, at most 48 characters as the app holds it;
 * the place is the meeting's place as the phone kept it, at most 64; the month
 * is `YYYY-MM`. None may carry a control or a formatting character, so
 * nothing shown can reorder or hide the text around it. Absent and null are
 * both *not shown*, which is the default for all three.
 */
function checkedShown(mixed $shown): array
{
    if ($shown === null) return ['name' => null, 'place' => null, 'month' => null];
    if (!is_array($shown)) respond(400, ['error' => 'shown is a JSON object, or absent.']);
    $text = function (mixed $value, int $most, string $what) {
        if ($value === null) return null;
        $value = is_string($value) ? trim($value) : $value;
        if (!is_string($value) || !preg_match('/\A[^\p{Cc}\p{Cf}\p{Zl}\p{Zp}]{1,' . $most . '}\z/u', $value)) {
            respond(400, ['error' => "$what is 1 to $most characters with no control characters, or absent."]);
        }
        return $value;
    };
    $month = $shown['month'] ?? null;
    if ($month !== null && (!is_string($month) || !preg_match('/\A[0-9]{4}-(0[1-9]|1[0-2])\z/', $month))) {
        respond(400, ['error' => 'month is YYYY-MM, or absent.']);
    }
    return ['name' => $text($shown['name'] ?? null, 48, 'name'),
            'place' => $text($shown['place'] ?? null, 64, 'place'),
            'month' => $month];
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
        'error' => 'That is more writing than this service takes from one place in under an hour.',
        'retryAfter' => $wait,
    ]);
}

function route(string $method, string $path): never
{
    $settings = settings();

    // **Wear, where it is off, is not there at all** — refused before the rate
    // limit, so a batch sent to a copy that has not turned it on is not even
    // counted against its sender.
    if ($path === '/api/wild/wear' && $settings['wear'] !== true) {
        respond(404, ['error' => 'No such route.']);
    }

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
        $seedbed = store($settings)->seedbed();
        // **`water` is which drills of this plot are flooded**, a fact about
        // the plot rather than about any plant in it: the page digs the bed
        // before it grows anything into it.
        respond(200, ['plot' => $plot, 'plantings' => $seedbed->plot($plot),
                      'water' => $seedbed->water($plot)]);
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

    if ($path === '/api/coppice' && $method === 'GET') {
        respond(200, ['plots' => store($settings)->coppice()->plots()]);
    }

    // **The first route that answers with the date in it.** The year of the
    // rotation is today's in UTC, worked out here and sent with the plot, so a
    // page never asks its own clock and two visitors either side of midnight
    // see one wood.
    if (preg_match('#\A/api/coppice/plot/(0|[1-9][0-9]{0,5})\z#', $path, $m) && $method === 'GET') {
        $plot = (int) $m[1];
        $year = Coppice::yearOn(time());
        respond(200, ['plot' => $plot, 'year' => $year, 'stages' => CoppiceStore::stages($plot, $year),
                      'plantings' => store($settings)->coppice()->plot($plot, $year)]);
    }

    if ($path === '/api/ground' && $method === 'GET') {
        respond(200, ['plots' => store($settings)->homeGround()->plots()]);
    }

    if (preg_match('#\A/api/ground/plot/(0|[1-9][0-9]{0,5})\z#', $path, $m) && $method === 'GET') {
        $plot = (int) $m[1];
        respond(200, ['plot' => $plot, 'plantings' => store($settings)->homeGround()->plot($plot)]);
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
            $plant['kind'], $plant['hue'], $plant['habit']
        );
        // Released to the Wild Fields, by either gardener, and so not offered
        // anywhere: a plant stands in one public place. 410 rather than 409,
        // because 409 is the area-not-open refusal and the phone has its own
        // sentence for each.
        if ($offer === false) {
            respond(410, ['error' => 'This plant has been released to the Wild Fields.']);
        }
        // Offered already, by somebody holding a different pair of tokens. Said
        // without either of them — see `Offers::offer`.
        if ($offer === null) {
            respond(409, ['error' => 'This plant has already been offered.']);
        }
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
        // **And the Wild Fields', on the same request** (1 October 2026): a
        // plant one of these meetings grew that either gardener has released,
        // with what each chose to show beside it. One poll rather than two, so
        // the *Alert me* switch, which stops this request, stops both.
        $asked = array_values($tokens);
        $store = store($settings);
        respond(200, ['offers' => $store->offers()->touching($asked, time()),
                      'wild' => $store->wild()->touching($asked)]);
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

    // **The field, and what stands in each part of it.** Nothing in either
    // answer names a person, a meeting or a time: the field keeps none of them.
    if ($path === '/api/wild' && $method === 'GET') {
        // `wear` only where wear is on: the cells' size and how many go
        // across, how many a batch may hold, and the least wear drawn — which
        // is how the page knows to record and draw it at all.
        $wear = $settings['wear'] !== true ? [] : ['wear' => [
            'cell' => WildWear::CELL, 'cells' => WildWear::CELLS, 'most' => WildWear::MOST,
            'seen' => WildWear::SEEN,
        ]];
        respond(200, ['side' => WildFields::SIDE, 'tile' => WildFields::TILE, 'tiles' => WildFields::TILES,
                      'standing' => store($settings)->wild()->standing()] + $wear);
    }

    // **The paths visitors have worn**, faded to today: `[[x, z, wear], …]`,
    // one entry for each cell worn past `WildWear::FLOOR`, wear in crossings.
    // Nothing in it is about anybody: it is the whole field's footfall,
    // counted per cell and fading, and the same answer for everyone who asks.
    if ($path === '/api/wild/wear' && $method === 'GET') {
        respond(200, ['wear' => store($settings)->wear()->field(time())]);
    }

    // **The cells a visitor's window crossed while walking.** `{cells: [[x,
    // z], …]}`, at most `WildWear::MOST`, in no order, sent by the page now
    // and then while somebody drags the field or presses the pad's four
    // directions (`wear.js`). Each adds one crossing to its cell, once per
    // batch and up to the day's cap. The body says which cells and nothing
    // else; nothing about the request is written but those counts, and the
    // answer is how many cells it held — the request's own number, so it
    // says nothing about what anybody else has walked.
    if ($path === '/api/wild/wear' && $method === 'POST') {
        $cells = readBody()['cells'] ?? null;
        if (!WildWear::isBatch($cells)) {
            respond(400, ['error' => 'cells is a list of 1 to ' . WildWear::MOST . ' pairs [x, z], each 0 to '
                                     . (WildWear::CELLS - 1) . '.']);
        }
        respond(200, ['taken' => store($settings)->wear()->walked($cells, time())]);
    }

    if (preg_match('#\A/api/wild/tile/([0-9]{1,2})/([0-9]{1,2})\z#', $path, $m) && $method === 'GET') {
        [$x, $z] = [(int) $m[1], (int) $m[2]];
        // The page wraps its own coordinates round the field before it asks,
        // so a tile past the last is a page that has not, and is refused
        // rather than answered with nothing.
        if ($x >= WildFields::TILES || $z >= WildFields::TILES) {
            respond(404, ['error' => 'The field is ' . WildFields::TILES . ' tiles each way, counted from 0.']);
        }
        respond(200, ['tile' => [$x, $z], 'plantings' => store($settings)->wild()->tile($x, $z)]);
    }

    // **Letting a plant go.** `{seed, parents, encounter, token?}`, from the
    // app's Release, held three seconds on the plant's own screen.
    //
    // - **What is checked:** that the seed is the cross of those parents at that
    //   meeting, as an offer is checked, so nothing invented under somebody
    //   else's lineage stands in the field; and, for a plant the asking has
    //   ever held, that the caller holds one of its two tokens (`letGo`).
    // - **What is kept:** the seed and both parents, which is what a browser
    //   grows a hybrid from, and nothing else. The meeting is read to check the
    //   cross and dropped; the token is compared and dropped; no time is
    //   written anywhere.
    // - **Once per plant.** A plant already standing is answered with where it
    //   stands, whoever asks, so a phone whose first answer was lost can ask
    //   again and be told the release took.
    //
    // **And, since 1 October 2026, `theirs` and `shown`.** `theirs` is the
    // token the other phone minted at the meeting, and with `token` it is
    // what lets each of the two answer for themselves about what stands beside
    // the plant (`WildStore::beside`); both are kept as fingerprints only.
    // `shown` is the releaser's choice of what to show — their name, where
    // they met, the month — and absent means nothing (`checkedShown`). A plant
    // already standing is answered for whichever of its two gardeners
    // `token` is, so the other phone releasing its own copy answers too; a
    // stranger's token, or one for a plant released without names, changes
    // nothing.
    if ($path === '/api/wild/release' && $method === 'POST') {
        $body = readBody();
        $seed = $body['seed'] ?? null;
        $parents = $body['parents'] ?? null;
        $encounter = $body['encounter'] ?? null;
        $token = $body['token'] ?? null;
        $theirs = $body['theirs'] ?? null;
        if (!Seeds::isHex32($seed) || !is_array($parents) || count($parents) !== 2
            || !Seeds::isHex32($parents[0] ?? null) || !Seeds::isHex32($parents[1] ?? null)
            || !Seeds::isHex32($encounter)) {
            respond(400, ['error' => 'seed, parents (two) and encounter are each 64 lowercase hex characters.']);
        }
        if ($token !== null && !Seeds::isHex16($token)) {
            respond(400, ['error' => 'token is 32 lowercase hex characters, or absent.']);
        }
        if ($theirs !== null && (!Seeds::isHex16($theirs) || $token === null || $theirs === $token)) {
            respond(400, ['error' => 'theirs is 32 lowercase hex characters, sent with token and not the same, or absent.']);
        }
        $shown = checkedShown($body['shown'] ?? null);
        if ($theirs === null && array_filter($shown) !== []) {
            respond(400, ['error' => 'shown is sent with token and theirs, or not at all.']);
        }
        if (Seeds::cross($parents[0], $parents[1], $encounter) !== $seed) {
            respond(422, ['error' => 'That seed is not the cross of those parents at that meeting.']);
        }
        $store = store($settings);
        if ($store->wild()->find($seed) !== null) {
            $beside = $theirs === null ? null : $store->wild()->answer($seed, $token, $shown);
            respond(200, ['planting' => $store->wild()->find($seed)] + ($beside ? ['beside' => $beside] : []));
        }
        if (!$store->offers()->letGo($seed, $token, time())) {
            // The same answer whether there was no token or the wrong one, as
            // `answer` and `withdraw` give, so the route says nothing about
            // which plants have been offered beyond what was already public.
            respond(403, ['error' => 'This plant has stood in the garden, and only the two who grew it can release it.']);
        }
        [$planting, $new] = $store->wild()->release($seed, $parents[0], $parents[1]);
        $beside = $theirs === null ? null : $store->wild()->beside($seed, $token, $theirs, $shown);
        // Read again, so the planting answered carries what was just chosen.
        if ($beside !== null) $planting = $store->wild()->find($seed) ?? $planting;
        respond($new ? 201 : 200, ['planting' => $planting] + ($beside ? ['beside' => $beside] : []));
    }

    // **What stands beside a released plant, answered by one of its two
    // gardeners.** `{seed, token, shown}`: `token` is this phone's own from
    // the meeting, and `shown` the whole of its choice — name, place, month,
    // each absent for not shown — so the first answer, a change and a
    // withdrawal are one request. Either of the two, at any time, without
    // the other: a name is its owner's alone, and the place and the month
    // stand only while both have chosen the same (`WildStore::answer`).
    if ($path === '/api/wild/answer' && $method === 'POST') {
        $body = readBody();
        $seed = $body['seed'] ?? null;
        $token = $body['token'] ?? null;
        if (!Seeds::isHex32($seed) || !Seeds::isHex16($token)) {
            respond(400, ['error' => 'seed is 64 hex characters and token is 32.']);
        }
        $seen = store($settings)->wild()->answer($seed, $token, checkedShown($body['shown'] ?? null));
        // One answer for no such plant, a plant released without names, and
        // somebody else's token, as `/api/walk/answer` gives.
        if ($seen === null) respond(404, ['error' => 'No released plant at that token.']);
        respond(200, ['beside' => $seen]);
    }

    if ($path === '/api/walk/plant' && $method === 'POST') {
        if (!$settings['open_for_planting']) {
            respond(403, ['error' => 'The garden opens for planting once sharing has sign-in and both gardeners\' consent.']);
        }
        $plant = checkedPlant(readBody(4096));
        [$planting, $new] = store($settings)->plantInto(
            $plant['area'], $plant['seed'], $plant['parents'][0], $plant['parents'][1],
            $plant['encounter'], $plant['height'], $plant['family'], $plant['kind'], $plant['hue'],
            $plant['habit']
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
