<?php
declare(strict_types=1);

/**
 * The aloft pools: two tables of bytes, capped, drawn evenly, and forgetful.
 *
 * Run: php tools/reference/check_aloft_store.php
 *
 * It runs on a throwaway directory under the system's temporary one, never on
 * the real `peacegarden-data`, and drives `Aloft` itself rather than HTTP.
 *
 *   - **The shape**: one column and no rowid in each table; the directory is
 *     0700 and the file 0600.
 *   - **The cap**: never over it after 10,000 puts, and a repeated row is
 *     stored once.
 *   - **Eviction is at random**, not first in first out.
 *   - **A draw** is exactly n distinct rows of the right length at any fill.
 *   - **Evenness**: at P = 2,048 each real row is offered within 25% of the
 *     mean over 20,000 draws.
 *   - **Forgetting**: a removed row leaves no bytes in the file.
 *   - **A locked file** answers with padding and drops the insert.
 */

require_once __DIR__ . '/../../Server/.api/Aloft.php';

$failures = 0;
function check(string $what, bool $held): void
{
    global $failures;
    if (!$held) { $failures++; fwrite(STDERR, "FAILED  $what\n"); }
    else fwrite(STDOUT, "ok      $what\n");
}

function tempDirectory(): string
{
    $dir = sys_get_temp_dir() . '/aloft-check-' . bin2hex(random_bytes(6));
    return $dir;
}

function removeTree(string $dir): void
{
    if (!is_dir($dir)) return;
    foreach (scandir($dir) as $name) {
        if ($name === '.' || $name === '..') continue;
        $path = "$dir/$name";
        is_dir($path) ? removeTree($path) : unlink($path);
    }
    rmdir($dir);
}

function pdoOf(string $file): PDO
{
    return new PDO('sqlite:' . $file, null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
}

function blobs(PDO $db, string $table): array
{
    $rows = [];
    foreach ($db->query("SELECT row FROM $table")->fetchAll(PDO::FETCH_COLUMN) as $row) {
        $rows[] = is_resource($row) ? stream_get_contents($row) : $row;
    }
    return $rows;
}

$root = tempDirectory();
register_shutdown_function(static fn () => removeTree($root));
$file = "$root/data/aloft.sqlite";

// The shape, and the modes, on a pool made on first use.
$pools = Aloft::open($file);
check('nothing exists before first use', !file_exists($file) && !is_dir("$root/data"));
check('a first put is stored', $pools->putAloft(random_bytes(64)));
check('the directory is 0700', (fileperms("$root/data") & 0777) === 0700);
check('the file is 0600', (fileperms($file) & 0777) === 0600);

$db = pdoOf($file);
foreach (['aloft', 'back'] as $table) {
    $columns = $db->query("PRAGMA table_info($table)")->fetchAll(PDO::FETCH_ASSOC);
    check("$table has one column, named row", count($columns) === 1 && $columns[0]['name'] === 'row');
    $sql = (string) $db->query("SELECT sql FROM sqlite_master WHERE name = '$table'")->fetchColumn();
    check("$table is WITHOUT ROWID", stripos($sql, 'WITHOUT ROWID') !== false);
    $hidden = true;
    try { $db->query("SELECT rowid FROM $table"); } catch (PDOException $e) { $hidden = false; }
    check("$table has no rowid to read", !$hidden);
}
check('journal mode is DELETE', $db->query('PRAGMA journal_mode')->fetchColumn() === 'delete');
unset($db, $pools);

// A repeated row, and a row of the wrong length.
$once = Aloft::open("$root/once.sqlite");
$row = random_bytes(64);
$once->putAloft($row);
$once->putAloft($row);
$backRow = random_bytes(104);
$once->putBack($backRow);
$once->putBack($backRow);
$db = pdoOf("$root/once.sqlite");
check('a repeated aloft row is stored once', (int) $db->query('SELECT count(*) FROM aloft')->fetchColumn() === 1);
check('a repeated back row is stored once', (int) $db->query('SELECT count(*) FROM back')->fetchColumn() === 1);
check('a row of the wrong length is refused', !$once->putAloft(random_bytes(63)) && !$once->putBack(random_bytes(64)));
unset($db, $once);

// The cap, after 10,000 puts.
$capped = Aloft::open("$root/capped.sqlite");
$over = false;
$db = pdoOf("$root/capped.sqlite");
for ($i = 0; $i < 10000; $i++) {
    $capped->putAloft(random_bytes(64));
    $capped->putBack(random_bytes(104));
    if ($i % 250 === 0 || $i === 9999) {
        foreach (['aloft' => Aloft::P, 'back' => Aloft::Q] as $table => $cap) {
            if ((int) $db->query("SELECT count(*) FROM $table")->fetchColumn() > $cap) $over = true;
        }
    }
}
check('never over the cap after 10,000 puts', !$over);
check('aloft holds exactly P once full', (int) $db->query('SELECT count(*) FROM aloft')->fetchColumn() === Aloft::P);
check('back holds exactly Q once full', (int) $db->query('SELECT count(*) FROM back')->fetchColumn() === Aloft::Q);
unset($db, $capped);

// Eviction is at random, not first in first out: after 64 more puts into a
// full pool of 64, first in first out leaves exactly the last 64.
$small = Aloft::open("$root/small.sqlite", 64, 64);
$first = [];
for ($i = 0; $i < 64; $i++) { $first[] = random_bytes(64); $small->putAloft($first[$i]); }
$later = [];
for ($i = 0; $i < 64; $i++) { $later[] = random_bytes(64); $small->putAloft($later[$i]); }
$held = array_flip(blobs(pdoOf("$root/small.sqlite"), 'aloft'));
$oldKept = count(array_filter($first, static fn ($r) => isset($held[$r])));
$newLost = count(array_filter($later, static fn ($r) => !isset($held[$r])));
check("some of the oldest rows are still there ($oldKept of 64)", $oldKept > 0);
check("some of the newest rows are gone ($newLost of 64)", $newLost > 0);
unset($small);

// A draw is n distinct rows of the right length at any fill.
$draws = true;
$fill = Aloft::open("$root/fill.sqlite");
$have = 0;
foreach ([0, 1, 5, 127, 128, 129, 500, 2048] as $target) {
    while ($have < $target) { $fill->putAloft(random_bytes(64)); $fill->putBack(random_bytes(104)); $have++; }
    foreach ([[$fill->drawAloft(128), 64], [$fill->drawBack(128), 104]] as [$rows, $length]) {
        if (count($rows) !== 128 || count(array_unique($rows)) !== 128) $draws = false;
        foreach ($rows as $r) if (!is_string($r) || strlen($r) !== $length) $draws = false;
    }
    check("draw(128) is 128 distinct rows of the right length at fill $target", $draws);
}
$padding = Aloft::paddingAloft();
check('aloft padding is 64 bytes', strlen($padding) === 64);
check('back padding is 104 bytes', strlen(Aloft::paddingBack()) === 104);

// Evenness: at P = 2,048, 20,000 draws of 128 offer each row 1,250 times on
// average; every row has to fall within 25% of that.
$even = Aloft::open("$root/even.sqlite");
$real = [];
for ($i = 0; $i < Aloft::P; $i++) { $real[$i] = random_bytes(64); $even->putAloft($real[$i]); }
$offered = array_fill_keys($real, 0);
$draws = 20000;
for ($i = 0; $i < $draws; $i++) {
    foreach ($even->drawAloft(128) as $r) if (isset($offered[$r])) $offered[$r]++;
}
$mean = $draws * 128 / Aloft::P;
$lowest = min($offered);
$highest = max($offered);
check(sprintf('every row offered within 25%% of the mean %.0f (lowest %d, highest %d)', $mean, $lowest, $highest),
    $lowest >= $mean * 0.75 && $highest <= $mean * 1.25);
unset($even);

// Forgetting: a row pushed out leaves no bytes in the file.
$forget = Aloft::open("$root/forget.sqlite", 8, 8);
$sent = [];
for ($i = 0; $i < 300; $i++) { $sent[$i] = random_bytes(64); $forget->putAloft($sent[$i]); }
$held = array_flip(blobs(pdoOf("$root/forget.sqlite"), 'aloft'));
$bytes = (string) file_get_contents("$root/forget.sqlite");
$leaks = 0;
$kept = 0;
foreach ($sent as $r) {
    $inFile = str_contains($bytes, $r);
    if (isset($held[$r])) { $kept++; if (!$inFile) $leaks--; }
    elseif ($inFile) $leaks++;
}
check("removed rows leave no bytes in the file ($kept kept, 292 removed)", $leaks === 0 && $kept === 8);
check('no journal is left beside the file', glob("$root/forget.sqlite-*") === []);
unset($forget);

// A locked file answers with padding and drops the insert, inside a few seconds.
$locked = Aloft::open("$root/locked.sqlite");
$locked->putAloft(random_bytes(64));
$holder = pdoOf("$root/locked.sqlite");
$holder->exec('BEGIN EXCLUSIVE');
$busy = Aloft::open("$root/locked.sqlite");
$began = microtime(true);
$threw = false;
try {
    $put = $busy->putAloft(random_bytes(64));
    $rows = $busy->drawAloft(128);
    $back = $busy->drawBack(128);
} catch (Throwable $e) {
    $threw = true;
}
$took = microtime(true) - $began;
check('a locked file throws nothing to the caller', !$threw);
check('a locked file drops the insert', !$threw && $put === false);
check('a locked file still answers 128 distinct rows of padding',
    !$threw && count($rows) === 128 && count(array_unique($rows)) === 128 && count($back) === 128);
check(sprintf('a locked file gives up within a few seconds (%.1f s)', $took), $took < 5);
$holder->exec('ROLLBACK');
unset($holder);

fwrite(STDOUT, $failures === 0 ? "\nAll held.\n" : "\n$failures failed.\n");
exit($failures === 0 ? 0 : 1);
