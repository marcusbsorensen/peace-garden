<?php
declare(strict_types=1);

/**
 * The clean-up every five minutes, for the hours nobody asks the service
 * anything.
 *
 * **Why it exists.** The service tidies as it answers: every limited request
 * drops the rate-limit windows that have ended (`Limits::sweep`), and every
 * `offer` and `pending` request lapses the offers that have waited thirty days
 * (`Offers::lapse`). That is exact while people are using it and says nothing
 * about a quiet week, when the last caller's scrambled address and an offer
 * nobody will answer both sit there until somebody comes. The privacy page
 * promises an hour and thirty days, and those have to hold when nobody comes,
 * so cron runs this every five minutes and does both. Five, not sixty: a
 * rate-limit window is fifty-five minutes, and a sweep five minutes after it
 * ends is what keeps a scrambled address inside the hour (`Limits::WINDOW`).
 *
 * **Run it from cron, on the server**, beside `backup.php` and read the same
 * way: `config.php` names the database, and `PG_WALK_DSN` points it elsewhere
 * for the reference check. Server/README.md gives the crontab line, every five
 * minutes, and `tools/backup.sh --install-cron` installs it; it is not written
 * out here because its minute field would close this comment.
 *
 * **Safe beside the service and beside itself.** Opening the store runs the
 * same idempotent migrations a request runs. The rate-limit sweep is a single
 * DELETE. A lapse only erases an offer that is still exactly as it was read,
 * so a request lapsing the same offer at the same moment, or a second run of
 * this, updates nothing (`Offers::erase`). Run it twice, or twenty times, and
 * the database ends the same.
 *
 * Quiet when there was nothing to do, one line when there was, so the log is a
 * record of what went and when rather than of cron being alive. It says counts
 * and nothing else: no bucket, no token, no seed.
 */

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/backup.php';   // `configuration()`, and nothing is taken
require_once __DIR__ . '/Limits.php';
require_once __DIR__ . '/WalkStore.php';

try {
    $config = configuration();
    $store = WalkStore::open($config['dsn'], $config['user'] ?? null, $config['password'] ?? null);
    $now = time();
    $windows = (new Limits($store->connection()))->sweep($now);
    $offers = $store->offers()->lapse($now);
    // **And the paths visitors wear fade on a quiet day too** (2 October
    // 2026), where wear is turned on: the first sweep of a day fades the
    // field, so a path nobody walks is grass again on time rather than when
    // the next visitor comes (`WildWear::settle`).
    $grassed = WildWear::on($config) ? $store->wear()->settle($now) : 0;
} catch (Throwable $trouble) {
    fwrite(STDERR, gmdate('Y-m-d H:i:s') . '  no sweep: ' . $trouble->getMessage() . "\n");
    exit(1);
}

if ($windows > 0 || $offers > 0 || $grassed > 0) {
    printf("%s  %d rate-limit window%s ended, %d offer%s lapsed%s\n", gmdate('Y-m-d H:i:s'),
        $windows, $windows === 1 ? '' : 's', $offers, $offers === 1 ? '' : 's',
        $grassed > 0 ? sprintf(', %d worn cell%s grass again', $grassed, $grassed === 1 ? '' : 's') : '');
}
exit(0);
