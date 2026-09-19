<?php
declare(strict_types=1);

/**
 * The rate limit: one caller cannot fill the walk.
 *
 * Run: php tools/reference/check_limits.php
 *
 * Four things, and each is a way the limit could be there and do nothing:
 *
 *   - it counts, and refuses once the allowance is gone,
 *   - a different caller has its own allowance,
 *   - a different route has its own allowance,
 *   - an hour later the allowance is back.
 *
 * The last is the one worth a test of its own. A limit that counted for ever
 * would lock somebody out of their own garden by the second week, and nothing
 * about using the app would reveal it until then.
 */

require_once __DIR__ . '/../../Server/.api/Limits.php';

$failures = 0;
function check(string $what, bool $held): void
{
    global $failures;
    if (!$held) { $failures++; fwrite(STDERR, "FAILED  $what\n"); }
    else fwrite(STDOUT, "ok      $what\n");
}

$file = sys_get_temp_dir() . '/peacegarden-limits-' . getmypid() . '.sqlite';
@unlink($file);
$db = new PDO('sqlite:' . $file, null, null, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);
$limits = new Limits($db);

$now = 1_700_000_000;
$offer = '/api/walk/offer';
[$allowed, $window] = Limits::ROUTES[$offer];

// MARK: It counts

$refusedAt = null;
for ($i = 1; $i <= $allowed + 3; $i++) {
    $wait = $limits->wait($offer, '198.51.100.7', $now);
    if ($wait !== null && $refusedAt === null) $refusedAt = $i;
}
check("the allowance is exactly $allowed", $refusedAt === $allowed + 1);
check('and it says how long to wait', $limits->wait($offer, '198.51.100.7', $now) === $window);
check('the wait counts down', $limits->wait($offer, '198.51.100.7', $now + 100) === $window - 100);

// MARK: Somebody else is somebody else

check('another caller has its own allowance',
      $limits->wait($offer, '198.51.100.8', $now) === null);

// MARK: So is another route

check('another route has its own allowance',
      $limits->wait('/api/walk/answer', '198.51.100.7', $now) === null);

// MARK: The hour passes

check('the allowance comes back', $limits->wait($offer, '198.51.100.7', $now + $window) === null);
check('and it is a whole allowance, not one more attempt', (function () use ($limits, $offer, $now, $window, $allowed) {
    for ($i = 1; $i < $allowed; $i++) {
        if ($limits->wait($offer, '198.51.100.7', $now + $window + 1) !== null) return false;
    }
    return true;
})());

// MARK: A route with no limit is not limited

check('a route with no limit passes', $limits->wait('/api/walk', '198.51.100.7', $now) === null);

// MARK: What is kept

$rows = $db->query('SELECT bucket FROM rate_limits')->fetchAll();
check('the buckets say nothing about who', count($rows) > 0 && !array_filter(
    $rows, fn ($row) => str_contains($row['bucket'], '198.51.100')
));
check('a bucket is a fixed-width digest', count(array_filter(
    $rows, fn ($row) => strlen((string) $row['bucket']) !== 32
)) === 0);

// Two installs, same caller, different buckets: the salt is per database.
$second = sys_get_temp_dir() . '/peacegarden-limits2-' . getmypid() . '.sqlite';
@unlink($second);
$otherDb = new PDO('sqlite:' . $second, null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                                                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
$other = new Limits($otherDb);
$other->wait($offer, '198.51.100.7', $now);
$here = $db->query('SELECT bucket FROM rate_limits ORDER BY bucket')->fetchAll(PDO::FETCH_COLUMN);
$there = $otherDb->query('SELECT bucket FROM rate_limits ORDER BY bucket')->fetchAll(PDO::FETCH_COLUMN);
check('the same caller buckets differently on another install',
      array_intersect($here, $there) === []);

@unlink($file);
@unlink($second);

if ($failures > 0) {
    fwrite(STDERR, "\n$failures checks failed.\n");
    exit(1);
}
fwrite(STDOUT, "\nOne caller cannot fill the walk.\n");
