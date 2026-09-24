<?php
declare(strict_types=1);

/**
 * The five-minute clean-up: what cron runs does what the privacy page says.
 *
 * Run: php tools/reference/check_sweep.php
 *
 * It runs `Server/.api/sweep.php` the way cron does — as its own process,
 * pointed at a database by `PG_WALK_DSN` — against a throwaway SQLite file with
 * something in it to clear and something in it to keep:
 *
 *   - a rate-limit window that has ended goes, and one still open stays,
 *   - an offer that has waited thirty days lapses and is erased, and a fresh
 *     one stays,
 *   - a second run changes nothing, and neither do four at once,
 *   - it says nothing when there was nothing to do, and never a token or seed.
 */

require_once __DIR__ . '/../../Server/.api/Seeds.php';
require_once __DIR__ . '/../../Server/.api/Limits.php';
require_once __DIR__ . '/../../Server/.api/WalkStore.php';

$failures = 0;
function check(string $what, bool $held): void
{
    global $failures;
    if (!$held) { $failures++; fwrite(STDERR, "FAILED  $what\n"); }
    else fwrite(STDOUT, "ok      $what\n");
}

$file = sys_get_temp_dir() . '/peacegarden-sweep-' . getmypid() . '.sqlite';
@unlink($file);
$dsn = 'sqlite:' . $file;
$sweep = dirname(__DIR__, 2) . '/Server/.api/sweep.php';

/** Starts one run of the sweep, as cron would, and hands back the process. */
function start(string $sweep, string $dsn): array
{
    $process = proc_open(['php', $sweep], [1 => ['pipe', 'w'], 2 => ['pipe', 'w']], $pipes,
                         null, ['PG_WALK_DSN' => $dsn, 'PATH' => getenv('PATH')]);
    return [$process, $pipes];
}

/** Waits for a run and returns [exit status, what it printed, what it complained of]. */
function finish(array $run): array
{
    [$process, $pipes] = $run;
    $out = stream_get_contents($pipes[1]);
    $err = stream_get_contents($pipes[2]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    return [proc_close($process), $out, $err];
}

// MARK: Something to clear, and something to keep

$now = time();
$store = WalkStore::open($dsn);
$db = $store->connection();
$limits = new Limits($db);
$limits->wait('/api/walk/offer', '198.51.100.1', $now - Limits::WINDOW - 5);   // ended five seconds ago
$limits->wait('/api/walk/pending', '198.51.100.2', $now - 60);                 // a minute into its window

$offers = $store->offers();
$cross = function (int $n): array {
    $a = hash('sha256', "sweep a $n");
    $b = hash('sha256', "sweep b $n");
    $e = hash('sha256', "sweep meeting $n");
    return ['seed' => Seeds::cross($a, $b, $e), 'a' => $a, 'b' => $b, 'encounter' => $e,
            'to' => substr(hash('sha256', "sweep to $n"), 0, 32),
            'from' => substr(hash('sha256', "sweep from $n"), 0, 32)];
};
$stale = $cross(1);
$fresh = $cross(2);
$offers->offer($stale['seed'], $stale['to'], $stale['from'], $stale['a'], $stale['b'], $stale['encounter'],
               1.0, 1, $now - Offers::LAPSES_AFTER - 5);
$offers->offer($fresh['seed'], $fresh['to'], $fresh['from'], $fresh['a'], $fresh['b'], $fresh['encounter'],
               1.0, 1, $now - 86400);
unset($offers, $limits, $store, $db);

$read = function () use ($dsn): array {
    $db = new PDO($dsn, null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                                     PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
    return [
        'windows' => $db->query('SELECT bucket, started_at, hits FROM rate_limits ORDER BY started_at')->fetchAll(),
        'offers' => $db->query('SELECT * FROM walk_offers ORDER BY offer')->fetchAll(),
    ];
};
$held = function (array $state, array $plant): bool {
    $flat = json_encode($state);
    foreach (['seed', 'a', 'b', 'encounter', 'to', 'from'] as $field) {
        if (str_contains($flat, $plant[$field])) return true;
    }
    return false;
};
check('the database starts with both windows and both offers',
      count($read()['windows']) === 2 && count($read()['offers']) === 2);

// MARK: One run

[$status, $said, $complained] = finish(start($sweep, $dsn));
$after = $read();
check('the sweep runs without complaint' . ($complained === '' ? '' : ": $complained"),
      $status === 0 && $complained === '');
check('it says what went, in counts', preg_match('/1 rate-limit window ended, 1 offer lapsed/', $said) === 1);
check('and nothing else', !$held(['said' => $said], $stale) && !str_contains($said, '198.51.100'));
check('the window that had ended is gone', count($after['windows']) === 1
      && (int) $after['windows'][0]['started_at'] === $now - 60);
check('the offer that waited thirty days has lapsed', ($after['offers'][0]['state'] ?? null) === Offers::WITHDRAWN
      && (int) $after['offers'][0]['answered_at'] === $now - 5);
check('and nothing of it is left', !$held($after, $stale));
check('the fresh offer is untouched', ($after['offers'][1]['state'] ?? null) === Offers::OFFERED
      && $after['offers'][1]['seed'] === $fresh['seed']);

// MARK: Again, and four at once

[$status, $said] = finish(start($sweep, $dsn));
check('a second run changes nothing', $status === 0 && $read() === $after);
check('and says nothing, having had nothing to do', $said === '');

$runs = array_map(fn () => start($sweep, $dsn), range(1, 4));
$ended = array_map('finish', $runs);
check('four runs at once all finish cleanly',
      array_filter($ended, fn ($r) => $r[0] !== 0) === []);
check('and leave the database exactly as one did', $read() === $after);

// **Beside a request.** The phone that was offered the lapsed plant asks about
// it after the sweep, and hears it was withdrawn — the erasure the sweep made
// is the one the service reads, not a second one on top of it.
$store = WalkStore::open($dsn);
$heard = $store->offers()->touching([$stale['to']], $now);
check('a phone asking afterwards hears it lapsed, by its token', ($heard[0] ?? null) === [
    'seed' => '', 'to' => $stale['to'], 'from' => '', 'state' => Offers::WITHDRAWN,
    'offeredAt' => $now - Offers::LAPSES_AFTER - 5, 'answeredAt' => $now - 5,
]);
check('and a request sweeping the same offer again erases nothing twice', $store->offers()->lapse($now) === 0
      && $read() === $after);

// **The race itself.** Two things read the same waiting offer, and one erases
// it first. The other still holds the row as it was read — in the clear — and
// its erasure must update nothing, or it would fingerprint the fingerprints and
// the offer could never be found again. Driven directly, because two processes
// on one SQLite file take turns and would never show it.
$racing = $cross(3);
$first = $store->offers();
$first->offer($racing['seed'], $racing['to'], $racing['from'], $racing['a'], $racing['b'], $racing['encounter'],
              1.0, 1, $now - Offers::LAPSES_AFTER - 1);
$query = $store->connection()->prepare('SELECT * FROM walk_offers WHERE seed = ?');
$query->execute([$racing['seed']]);
$asRead = $query->fetch();
check('the racing offer was read waiting, in the clear', ($asRead['state'] ?? null) === Offers::OFFERED);
check('one side lapses it', $first->lapse($now) === 1);
$settled = $read();
$second = $store->offers();
$late = Closure::bind(fn (array $row) => $this->erase($row, Offers::WITHDRAWN, 0), $second, Offers::class);
check('the other, erasing the row it read, changes nothing', $late($asRead) === false && $read() === $settled);
check('and the offer is still found by its token', ($second->touching([$racing['to']], $now)[0]['state'] ?? null)
      === Offers::WITHDRAWN);
unset($store, $first, $second, $late);

// MARK: As often as the hour needs

// `Limits` counts on a sweep every SWEPT_EVERY seconds to keep an address
// inside the hour, and nothing in PHP can make cron do that. What can be held
// is that the two places that give the cron line give that one.
$line = '*/' . intdiv(Limits::SWEPT_EVERY, 60)
      . ' * * * * /usr/bin/php $HOME/public_html/.api/sweep.php >> $HOME/backups/sweep.log 2>&1';
$repo = dirname(__DIR__, 2);
check('the README gives the cron line at the interval Limits counts on',
      str_contains((string) file_get_contents("$repo/Server/README.md"), $line));
check('and --install-cron installs that line', str_contains((string) file_get_contents("$repo/tools/backup.sh"), "'$line'"));

// MARK: Only from cron

check('it is a command, not a page: it refuses to run under a web server',
      str_contains((string) file_get_contents($sweep), "PHP_SAPI !== 'cli'"));

@unlink($file);

if ($failures > 0) {
    fwrite(STDERR, "\n$failures checks failed.\n");
    exit(1);
}
fwrite(STDOUT, "\nThe sweep clears what has ended and nothing else.\n");
