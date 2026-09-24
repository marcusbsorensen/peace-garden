<?php
declare(strict_types=1);

/**
 * Proves a copy of the walk restores — as the same walk, not merely as rows.
 *
 * Run by `tools/backup.sh --restore-test`, which is what puts the two empty
 * databases in front of it. It is not in CI, because it wants a MariaDB of the
 * kind the copies came from and CI has none; `check_backup.php` is the part
 * that runs everywhere.
 *
 * **What a weaker test would miss.** A dump reloads without complaint and a
 * row count matches, and the walk is still wrong: the arrival order has been
 * lost, so every plant after the first stands where a different plant stood.
 * Nothing about the restored rows says so — each one is individually
 * plausible. So this does not inspect the restore, it *replays* it: every
 * arrival is planted again, in order, into a second empty database by the same
 * rule that planted it the first time, and every column of every row has to
 * come back the same. The Long Walk is append-only and its placing is a pure
 * function of what arrived before, which is exactly what makes this checkable
 * and exactly what makes losing the order unrecoverable.
 *
 *   php tools/reference/check_restore.php <copy.sql.gz> <restored dsn> <replayed dsn> [user] [password]
 *   php tools/reference/check_restore.php --sow <dsn> [user] [password] [arrivals]
 *
 * The second form sows a walk for the rehearsal to copy. See `--rehearse` in
 * tools/backup.sh for why a test of an empty walk is not yet a test.
 */

require_once __DIR__ . '/../../Server/.api/LongWalk.php';
require_once __DIR__ . '/../../Server/.api/Offers.php';
require_once __DIR__ . '/../../Server/.api/WalkStore.php';

if (($argv[1] ?? '') === '--sow') {
    sow($argv[2] ?? '', $argv[3] ?? null, $argv[4] ?? null, (int) ($argv[5] ?? 24));
    exit(0);
}

/**
 * A walk with something in it: enough arrivals to fill a plot and start
 * another, heights all over so the placing rule has ordering to do, three
 * families so it has company to keep, and two taken back so a hidden row is
 * in the copy. Every seed is made from its number, so the walk is the same
 * walk every time this is run and a difference means something.
 */
function sow(string $dsn, ?string $user, ?string $password, int $arrivals): void
{
    $store = WalkStore::open($dsn, $user, $password);
    $sown = [];
    for ($i = 0; $i < $arrivals; $i++) {
        $seed = hash('sha256', "peace garden rehearsal seed $i");
        $sown[] = $seed;
        $store->plant(
            $seed,
            hash('sha256', "parent a $i"),
            hash('sha256', "parent b $i"),
            hash('sha256', "encounter $i"),
            0.6 + fmod($i * 0.37, 1.8),
            $i % 3
        );
    }
    // Two taken back, so the copy carries a row that is in the walk and not in
    // the drawing — the case a restore is likeliest to flatten, and since 24
    // September a row whose seed is a marker, which the replay has to stand in
    // for.
    $store->takeBack($sown[3]);
    $store->takeBack($sown[11] ?? $sown[0]);

    // And one offer of each kind, because those are copied too.
    $offers = $store->offers();
    foreach ([0 => null, 1 => true, 2 => false] as $i => $answer) {
        $seed = hash('sha256', "rehearsal offer $i");
        $to = substr(hash('sha256', "to $i"), 0, 32);
        $from = substr(hash('sha256', "from $i"), 0, 32);
        $offers->offer($seed, $to, $from, hash('sha256', "pa $i"), hash('sha256', "pb $i"),
                       hash('sha256', "en $i"), 1.0 + $i, $i % 3, 1_700_000_000 + $i);
        if ($answer !== null) {
            $offers->answer($seed, $to, $answer, 1_700_000_100 + $i);
        }
    }
    printf("  sowed %d arrivals, 2 taken back, 3 offers\n", $arrivals);
}

$copy = $argv[1] ?? null;
$restoredDsn = $argv[2] ?? null;
$replayedDsn = $argv[3] ?? null;
$user = $argv[4] ?? null;
$password = $argv[5] ?? null;

if ($copy === null || $restoredDsn === null || $replayedDsn === null) {
    fwrite(STDERR, "usage: check_restore.php <copy.sql.gz> <restored dsn> <replayed dsn> [user] [password]\n");
    exit(2);
}

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

// MARK: What the copy says it holds

/** The counts `backup.php` wrote into the file when it took the copy. */
function recorded(string $copy): array
{
    $counts = [];
    $handle = gzopen($copy, 'rb');
    while (($line = gzgets($handle)) !== false) {
        if (!str_starts_with($line, '--')) {
            break;
        }
        if (preg_match('/^-- rows (\w+) (\d+)/', $line, $found)) {
            $counts[$found[1]] = (int) $found[2];
        }
    }
    gzclose($handle);
    return $counts;
}

$said = recorded($copy);
check('the copy records what it held', $said !== []);

$restored = new PDO($restoredDsn, $user, $password, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_STRINGIFY_FETCHES => false,
]);

foreach ($said as $table => $expected) {
    $back = (int) $restored->query("SELECT COUNT(*) FROM $table")->fetchColumn();
    check("$table came back whole ($back of $expected)", $back === $expected);
}

// MARK: The walk, replayed

$rows = $restored->query('SELECT * FROM long_walk ORDER BY arrival')->fetchAll();
check('the arrivals are in an order', count($rows) === ($said['long_walk'] ?? 0));

$arrivals = array_map(static fn(array $row): int => (int) $row['arrival'], $rows);
$sorted = $arrivals;
sort($sorted);
check('no arrival number went missing or changed places', $arrivals === $sorted);
check('no two arrivals share a number', count(array_unique($arrivals)) === count($arrivals));

$replayed = WalkStore::open($replayedDsn, $user, $password);
$compared = ['plot', 'side', 'tier', 'slot_index', 'height', 'family', 'nudge_x', 'nudge_z',
             'parent_a', 'parent_b', 'encounter'];

// **A planting taken back is replayed as one.** Its seed is a marker and its
// parents and meeting are gone, so it cannot be planted again as itself. What it
// kept is what the rule reads, so a stand-in with its height and its family is
// placed where it stood, and taking the stand-in back leaves the same row. The
// rows are paired by their order rather than by seed for the same reason: the
// order is the one thing every row still has.
foreach ($rows as $row) {
    $seed = (string) $row['seed'];
    $standIn = TakenBack::isMarker($seed);
    if ($standIn) $seed = hash('sha256', 'stand-in ' . $row['arrival']);
    $replayed->plant(
        $seed,
        $standIn ? $seed : (string) $row['parent_a'],
        $standIn ? $seed : (string) $row['parent_b'],
        $standIn ? $seed : (string) $row['encounter'],
        (float) $row['height'],
        (int) $row['family']
    );
    if ($standIn) $replayed->takeBack($seed);
}

$again = $replayed->connection()->query('SELECT * FROM long_walk ORDER BY arrival')->fetchAll();
check('replaying the copy grows a walk of the same length', count($again) === count($rows));

foreach ($rows as $i => $row) {
    $seed = (string) $row['seed'];
    $short = TakenBack::isMarker($seed) ? 'taken back ' . $row['arrival'] : substr($seed, 0, 8);
    $replay = $again[$i] ?? null;
    if ($replay === null) {
        check("$short is in the replayed walk", false);
        continue;
    }
    if (!TakenBack::isMarker($seed)) {
        check("$short is the arrival replayed in its turn", (string) $replay['seed'] === $seed);
    }
    foreach ($compared as $column) {
        $was = $row[$column];
        $now = $replay[$column];
        $same = is_float($was) || is_float($now)
            ? abs((float) $was - (float) $now) < 1e-12
            : (string) $was === (string) $now;
        check("$short stands where it stood ($column)", $same);
    }
}

// MARK: What is kept beside the walk

$lock = (int) $restored->query('SELECT arrivals FROM long_walk_lock WHERE id = 1')->fetchColumn();
check('the arrival count came back', $lock >= count($rows));

$hidden = (int) $restored->query('SELECT COUNT(*) FROM long_walk WHERE hidden = 1')->fetchColumn();
check('a planting taken back is still in the walk', $hidden <= count($rows));

$offers = $restored->query('SELECT * FROM walk_offers')->fetchAll();
$words = [Offers::OFFERED, Offers::ACCEPTED, Offers::DECLINED, Offers::WITHDRAWN];
foreach ($offers as $offer) {
    $short = substr((string) $offer['seed'], 0, 8);
    // A dump that mangled a column leaves values that are still there and no
    // longer what they were, which a row count cannot see. These are the
    // shapes the service wrote and the ones it will read back.
    check("offer $short kept both addresses", strlen((string) $offer['token_to']) === 32
        && strlen((string) $offer['token_from']) === 32);
    check("offer $short kept its seed", strlen((string) $offer['seed']) === 64);
    check("offer $short kept what was said", in_array((string) $offer['state'], $words, true));
    check("offer $short kept when it was asked", (int) $offer['offered_at'] > 0);
}

// MARK: The word

echo "\n";
if ($failures === []) {
    printf("The walk came back: %d checks, %d arrivals replayed, %d offers.\n",
        $checks, count($rows), count($offers));
    exit(0);
}
printf("The copy does not restore: %d of %d checks failed.\n", count($failures), $checks);
exit(1);
