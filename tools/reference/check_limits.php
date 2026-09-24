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
 *
 * And a fifth, which is about what is kept rather than what is allowed: a
 * scrambled address is gone at the first request after its hour, every time.
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
check('a bucket is not the address written down', count($rows) > 0 && !array_filter(
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

// MARK: Gone within the hour, every time

// **Not on a draw.** Until 24 September a window that had ended was dropped on
// one request in fifty, so a bucket outlived its hour by however long the dice
// took. Now every request that touches the table drops every window that has
// ended — asked here fifty times in a row, by a caller and a route that have
// nothing to do with the rows being dropped, so a draw would have to be lucky
// fifty times to pass.
$bucketsAt = fn (PDO $db) => $db->query('SELECT bucket, started_at FROM rate_limits ORDER BY started_at')
                                ->fetchAll(PDO::FETCH_KEY_PAIR);
$clock = $now + 10 * $window;
$gone = true;
for ($i = 0; $i < 50; $i++) {
    $limits->wait($offer, "203.0.113.$i", $clock);          // a window opens
    $limits->wait('/api/walk/pending', '192.0.2.1', $clock + $window);   // an hour later, somebody else
    $left = $bucketsAt($db);
    // What may be left is the window that opened just now, and nothing older.
    if (array_filter($left, fn ($started) => (int) $started <= $clock) !== []) $gone = false;
    $clock += $window + 1;
}
check('every window that has ended is gone at the next request, fifty times out of fifty', $gone);

$limits->wait($offer, '203.0.113.200', $clock);
$limits->wait($offer, '203.0.113.201', $clock + $window - 1);
check('a window still open is kept', in_array($clock, array_map('intval', $bucketsAt($db)), true));
$limits->wait($offer, '203.0.113.202', $clock + $window);
check('and gone at the first request after its hour',
      !in_array($clock, array_map('intval', $bucketsAt($db)), true));

@unlink($file);
@unlink($second);

if ($failures > 0) {
    fwrite(STDERR, "\n$failures checks failed.\n");
    exit(1);
}
fwrite(STDOUT, "\nOne caller cannot fill the walk.\n");
