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
// Offered and not yet answered, which is the only state in which an offer holds
// a plant at all — and the state in which losing the kind would lose it for
// good, because the plant is placed when the answer comes and nothing then can
// read the name off it again.
$store->offers()->offer($seeds[0], str_repeat('1', 32), str_repeat('2', 32),
    str_repeat('a', 64), str_repeat('b', 64), str_repeat('c', 64), 1.0, 0, 1_700_000_000,
    'beginnings', 'paniculata');
// One planting in each of the other seven areas, so the copy is proved to carry
// every open area rather than only the one this check grew up around. A table
// left out of KEPT dumps as no rows at all, which is exactly what a silent data
// loss looks like.
$store->plantInto('peace', str_repeat('d', 64), str_repeat('a', 64), str_repeat('b', 64),
                  str_repeat('c', 64), 1.4, 2);
$store->plantInto('meeting', str_repeat('e', 64), str_repeat('a', 64), str_repeat('b', 64),
                  str_repeat('c', 64), 0.8, 3);
$store->plantInto('kinship', str_repeat('f', 64), str_repeat('a', 64), str_repeat('b', 64),
                  str_repeat('c', 64), 1.1, 1);
$store->plantInto('pattern', str_repeat('9', 64), str_repeat('a', 64), str_repeat('b', 64),
                  str_repeat('c', 64), 1.2, 5);
// The Seedbed's carries a kind, which is the one trait no other area stores. A
// copy that carried the row and dropped the column would restore a bed whose
// drills are claimed by nothing, and every later arrival would be sown in the
// wrong drill — silently, because the rule would still be self-consistent.
$store->plantInto('beginnings', str_repeat('8', 64), str_repeat('a', 64), str_repeat('b', 64),
                  str_repeat('c', 64), 1.3, 2, 'contorta');
$store->plantInto('waiting', str_repeat('7', 64), str_repeat('a', 64), str_repeat('b', 64),
                  str_repeat('c', 64), 0.9, 6);
// The Glasshouse's carries a hue, the one trait no other area stores. A copy
// that dropped the column would restore a staging whose pots stand in bands
// nothing records, and the next arrival of that colour would be placed as if
// its neighbours were pale — silently, as the Seedbed's kind would be.
$store->plantInto('light', str_repeat('6', 64), str_repeat('a', 64), str_repeat('b', 64),
                  str_repeat('c', 64), 0.9, 4, '', 0.8);
// The Coppice's carries a habit, the one trait no other area stores. A copy
// that dropped it would restore a wood whose stools stand empty of what was
// on them, and a fern arriving next would find the floor's one-fern cap
// already spent or never spent — silently, as the others would.
$store->plantInto('renewal', str_repeat('5', 64), str_repeat('a', 64), str_repeat('b', 64),
                  str_repeat('c', 64), 0.7, 5, '', null, 'fern');
// The Home Ground's carries a crop, which claims a bed. A copy that dropped it
// would restore beds nothing says are sown, and the next arrival would claim
// one already standing full of another crop — silently, as the others would.
$store->plantInto('ground', str_repeat('4', 64), str_repeat('a', 64), str_repeat('b', 64),
                  str_repeat('c', 64), 0.2, 3, '', null, 'succulent');
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
// The key a withdrawn offer's fingerprints are made under. Without it a
// restored `walk_offers` could no longer recognise a withdrawn plant offered
// again, so it travels with the offers.
check('the copy carries the offers\' key', ($counts['offer_key'] ?? -1) === 1);
check('the copy counts the arrival lock', ($counts['long_walk_lock'] ?? -1) === 1);
check('the copy holds the Quiet Garden', ($counts['quiet_garden'] ?? -1) === 1);
check('the copy holds the Crossing', ($counts['crossing'] ?? -1) === 1);
check('the copy counts the Crossing lock', ($counts['crossing_lock'] ?? -1) === 1);
// The Orchard was never checked here, which is the gap this row closes: it
// opened on 21 September and the copy has been carrying it on trust since.
check('the copy holds the Orchard', ($counts['orchard'] ?? -1) === 1);
check('the copy holds the Knot Garden', ($counts['knot_garden'] ?? -1) === 1);
check('the copy counts the Knot Garden lock', ($counts['knot_garden_lock'] ?? -1) === 1);
check('the copy holds the Seedbed', ($counts['seedbed'] ?? -1) === 1);
check('the copy counts the Seedbed lock', ($counts['seedbed_lock'] ?? -1) === 1);
check('the copy holds the Cold Frame', ($counts['cold_frame'] ?? -1) === 1);
check('the copy counts the Cold Frame lock', ($counts['cold_frame_lock'] ?? -1) === 1);
check('the copy holds the Glasshouse', ($counts['glasshouse'] ?? -1) === 1);
check('the copy counts the Glasshouse lock', ($counts['glasshouse_lock'] ?? -1) === 1);
check('the copy holds the Coppice', ($counts['coppice'] ?? -1) === 1);
check('the copy counts the Coppice lock', ($counts['coppice_lock'] ?? -1) === 1);
check('the copy holds the Home Ground', ($counts['home_ground'] ?? -1) === 1);
check('the copy counts the Home Ground lock', ($counts['home_ground_lock'] ?? -1) === 1);

// MARK: What a restore writes back

// A row count says the row is there and says nothing about its columns, and the
// Seedbed has one no other area has. So the copy is opened and read: this is a
// SQLite walk, so what the gz carries after the preamble is the database file
// itself, which is exactly what a restore puts back.
$restoredKind = null;
$restoredDrill = null;
$restoredOffer = null;
$restoredHue = null;
$restoredHabit = null;
$restoredCrop = null;
if ($copy !== '') {
    $whole = gzdecode((string) file_get_contents($copy)) ?: '';
    $marker = "-- A SQLite file follows, not SQL.\n";
    $tail = "\n" . COMPLETED . "\n";
    $from = strpos($whole, $marker);
    $to = strrpos($whole, $tail);
    if ($from !== false && $to !== false) {
        $file = "$into/restored.sqlite";
        file_put_contents($file, substr($whole, $from + strlen($marker), $to - $from - strlen($marker)));
        try {
            $back = new PDO("sqlite:$file", null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
            $row = $back->query('SELECT kind, drill FROM seedbed')->fetch(PDO::FETCH_ASSOC);
            $restoredKind = $row['kind'] ?? null;
            $restoredDrill = $row === false ? null : (int) $row['drill'];
            $waiting = $back->query('SELECT kind FROM walk_offers')->fetch(PDO::FETCH_ASSOC);
            $restoredOffer = $waiting === false ? null : $waiting['kind'];
            $potted = $back->query('SELECT hue FROM glasshouse')->fetch(PDO::FETCH_ASSOC);
            $restoredHue = $potted === false ? null : (float) $potted['hue'];
            $stool = $back->query('SELECT habit FROM coppice')->fetch(PDO::FETCH_ASSOC);
            $restoredHabit = $stool === false ? null : $stool['habit'];
            $sown = $back->query('SELECT crop, bed FROM home_ground')->fetch(PDO::FETCH_ASSOC);
            $restoredCrop = $sown === false ? null : [$sown['crop'], (int) $sown['bed']];
            unset($back);
        } catch (Throwable) {
            // Left null, which is what the checks below report.
        }
        unlink($file);
    }
}
check('a restored Seedbed row still knows its kind', $restoredKind === 'contorta');
// And it is not the drill the ambassador holds, which is the answer a kind
// dropped on the way through would have given.
check('and the drill that kind claimed', $restoredDrill === 1);
check('an offer still in flight keeps its kind too', $restoredOffer === 'paniculata');
check('a restored Glasshouse row still knows its hue', $restoredHue === 0.8);
check('a restored Coppice row still knows its habit', $restoredHabit === 'fern');
check('a restored Home Ground row still knows its crop, and the bed it claimed', $restoredCrop === ['Pell', 1]);

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
// Pruned on the day of the newest, so the thirty days reach back over all of
// them and it is the count alone that decides.
$dropped = prune($keeping, gmmktime(0, 0, 0, 1, KEEP + 5, 2026));
$left = glob("$keeping/walk-*.sql.gz") ?: [];
check('pruning drops the extras', $dropped === 5);
check('pruning leaves as many as it keeps', count($left) === KEEP);
sort($left);
check('pruning keeps the newest', str_contains(end($left), sprintf('01-%02d', KEEP + 5)));
check('pruning takes the oldest first', !str_contains(implode(' ', $left), 'walk-2026-01-01'));
check('pruning a folder with few in it takes none', prune($into) === 0);

// **And thirty days, not only thirty copies.** A week of cron not running
// leaves fewer than thirty copies reaching further back than thirty days, and
// the privacy page promises the days. The newest stays whatever its age.
$aging = scratch();
$day = 86400;
$taken = gmmktime(3, 17, 0, 9, 24, 2026);
foreach ([45, 31, 30, 29, 1, 0] as $daysAgo) {
    touch(sprintf('%s/walk-%s.sql.gz', $aging, gmdate('Y-m-d\\THis\\Z', $taken - $daysAgo * $day)));
}
touch("$aging/walk-by-hand.sql.gz");
check('copies older than thirty days go, however few there are', prune($aging, $taken + 60) === 3);
$kept = array_map('basename', glob("$aging/walk-*.sql.gz") ?: []);
check('the ones inside thirty days stay', count($kept) === 4 && in_array('walk-2026-08-26T031700Z.sql.gz', $kept, true));
check('a copy with no stamp in its name is not pruned', in_array('walk-by-hand.sql.gz', $kept, true));
$stale = scratch();
foreach ([90, 75, 61] as $daysAgo) {
    touch(sprintf('%s/walk-%s.sql.gz', $stale, gmdate('Y-m-d\\THis\\Z', $taken - $daysAgo * $day)));
}
prune($stale, $taken);
check('the newest copy stays, however old',
      array_map('basename', glob("$stale/walk-*.sql.gz") ?: []) === ['walk-2026-07-25T031700Z.sql.gz']);

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
