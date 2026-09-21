<?php
declare(strict_types=1);

/**
 * The backup's own reading of itself, held to the failures it exists to catch.
 *
 * `check_restore.php` proves a copy comes back, and wants a MariaDB to do it.
 * This proves the part that runs every night and has nobody watching: that a
 * copy cut short is refused rather than filed, that what a copy says it holds
 * is what was in the database, and that pruning removes the oldest and never
 * the newest. It runs on SQLite, so it runs anywhere, and it is in CI.
 */

require_once __DIR__ . '/../../Server/.api/LongWalk.php';
require_once __DIR__ . '/../../Server/.api/Offers.php';
require_once __DIR__ . '/../../Server/.api/WalkStore.php';
require_once __DIR__ . '/../../Server/.api/backup.php';

$checks = 0;
$failures = [];

function check(string $what, bool $true): void
{
    global $checks, $failures;
    $checks++;
    if (!$true) {
        $failures[] = $what;
        echo "  BAD   $what\n";
    }
}

function threw(string $what, string $words, callable $doing): void
{
    try {
        $doing();
        check("$what", false);
    } catch (Throwable $trouble) {
        check("$what", str_contains($trouble->getMessage(), $words));
    }
}

function scratch(): string
{
    $where = sys_get_temp_dir() . '/peace-garden-backup-' . bin2hex(random_bytes(6));
    mkdir($where, 0700, true);
    return $where;
}

function clear(string $where): void
{
    foreach (glob("$where/*") ?: [] as $file) {
        unlink($file);
    }
    rmdir($where);
}

$room = scratch();
$into = scratch();

// MARK: A walk with something in it

$walkFile = "$room/walk.sqlite";
$dsn = "sqlite:$walkFile";
$store = WalkStore::open($dsn);
$seeds = [];
for ($i = 0; $i < 4; $i++) {
    $seed = str_repeat(dechex($i + 1), 64);
    $seeds[] = $seed;
    $store->plant($seed, str_repeat('a', 64), str_repeat('b', 64), str_repeat('c', 64),
                  1.0 + $i * 0.4, $i % 3);
}
$store->offers()->offer($seeds[0], str_repeat('1', 32), str_repeat('2', 32),
    str_repeat('a', 64), str_repeat('b', 64), str_repeat('c', 64), 1.0, 0, 1_700_000_000);
// One planting in each of the other three areas, so the copy is proved to carry
// every open area rather than only the one this check grew up around. A table
// left out of KEPT dumps as no rows at all, which is exactly what a silent data
// loss looks like.
$store->plantInto('peace', str_repeat('d', 64), str_repeat('a', 64), str_repeat('b', 64),
                  str_repeat('c', 64), 1.4, 2);
$store->plantInto('meeting', str_repeat('e', 64), str_repeat('a', 64), str_repeat('b', 64),
                  str_repeat('c', 64), 0.8, 3);
$store->plantInto('kinship', str_repeat('f', 64), str_repeat('a', 64), str_repeat('b', 64),
                  str_repeat('c', 64), 1.1, 1);
unset($store);

// MARK: Taking one

putenv("PG_WALK_DSN=$dsn");
$ran = [];
$status = 0;
exec(sprintf('php %s %s 2>&1', escapeshellarg(dirname(__DIR__, 2) . '/Server/.api/backup.php'),
     escapeshellarg($into)), $ran, $status);
check('a copy is taken without complaint: ' . implode(' ', $ran), $status === 0);

$copies = glob("$into/walk-*.sql.gz") ?: [];
check('the copy is on disk', count($copies) === 1);
$copy = $copies[0] ?? '';

$counts = [];
if ($copy !== '') {
    $handle = gzopen($copy, 'rb');
    while (($line = gzgets($handle)) !== false && str_starts_with($line, '--')) {
        if (preg_match('/^-- rows (\w+) (\d+)/', $line, $found)) {
            $counts[$found[1]] = (int) $found[2];
        }
    }
    gzclose($handle);
}
check('the copy says how many arrivals it holds', ($counts['long_walk'] ?? -1) === 4);
check('the copy says how many offers it holds', ($counts['walk_offers'] ?? -1) === 1);
check('the copy counts the arrival lock', ($counts['long_walk_lock'] ?? -1) === 1);
check('the copy holds the Quiet Garden', ($counts['quiet_garden'] ?? -1) === 1);
check('the copy holds the Crossing', ($counts['crossing'] ?? -1) === 1);
check('the copy counts the Crossing lock', ($counts['crossing_lock'] ?? -1) === 1);

// MARK: Reading it back

check('a whole copy reads back', (static function () use ($copy, $counts): bool {
    try {
        readItBack($copy, $counts);
        return true;
    } catch (Throwable) {
        return false;
    }
})());

// The failure the whole thing is for: a copy cut short is a valid gzip of a
// valid beginning, and restores most of the walk saying nothing.
$short = "$into/short.sql.gz";
$out = gzopen($short, 'wb');
gzwrite($out, substr(gzdecode((string) file_get_contents($copy)) ?: '', 0, 200));
gzclose($out);
threw('a copy cut short is refused', 'cut short', static fn() => readItBack($short, $counts));

// And a copy of a database that had rows but holds none of that table.
$missing = "$into/missing.sql.gz";
$out = gzopen($missing, 'wb');
gzwrite($out, "-- Peace Garden\n-- Dump completed\n");
gzclose($out);
threw('a table left out of a copy is refused', 'not in the copy',
      static fn() => readItBack($missing, ['long_walk' => 4]));

// An empty database is not a broken copy: nothing was there to leave out.
check('an empty walk copies cleanly', (static function () use ($missing): bool {
    try {
        readItBack($missing, ['long_walk' => 0, 'long_walk_lock' => 0, 'walk_offers' => 0]);
        return true;
    } catch (Throwable) {
        return false;
    }
})());

// MARK: Keeping a few

$keeping = scratch();
for ($i = 1; $i <= KEEP + 5; $i++) {
    touch(sprintf('%s/walk-2026-01-%02dT000000Z.sql.gz', $keeping, $i));
}
$dropped = prune($keeping);
$left = glob("$keeping/walk-*.sql.gz") ?: [];
check('pruning drops the extras', $dropped === 5);
check('pruning leaves as many as it keeps', count($left) === KEEP);
sort($left);
check('pruning keeps the newest', str_contains(end($left), sprintf('01-%02d', KEEP + 5)));
check('pruning takes the oldest first', !str_contains(implode(' ', $left), 'walk-2026-01-01'));
check('pruning a folder with few in it takes none', prune($into) === 0);

// MARK: Reading the configuration

$parts = dsnParts('mysql:host=db.example;port=3307;dbname=walks;charset=utf8mb4');
check('a dsn names its host', $parts['host'] === 'db.example');
check('a dsn names its port', $parts['port'] === '3307');
check('a dsn names its database', $parts['dbname'] === 'walks');
check('a dsn left plain is the local one', dsnParts('mysql:dbname=walks')['host'] === '127.0.0.1');
threw('a dsn naming no database is refused', 'names no database',
      static fn() => dsnParts('mysql:host=db.example'));

$file = optionFile(['user' => 'gardener', 'password' => 'pa ss#word'],
                   ['host' => '127.0.0.1', 'port' => '3306']);
check('the password goes in a file rather than a command line',
      str_contains($file, 'password="pa ss#word"'));
check('the option file is an option file', str_starts_with($file, "[client]\n"));
threw('a password that would break out of the option file is refused', 'cannot go in an option file',
      static fn() => optionFile(['user' => 'gardener', 'password' => 'say "no"'],
                                ['host' => '127.0.0.1', 'port' => '3306']));

// MARK: The word

clear($room);
clear($into);
clear($keeping);

echo "\n";
if ($failures === []) {
    echo "The copy is a copy: $checks checks.\n";
    exit(0);
}
printf("The backup is not safe yet: %d of %d checks failed.\n", count($failures), $checks);
exit(1);
