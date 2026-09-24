<?php
declare(strict_types=1);

/**
 * Sows a garden for the replant's rehearsal, with the service as it is live.
 *
 *   php tools/replant/Rehearsal/sow.php <the live code's .api directory> <dsn> <arrivals.jsonl> [user] [password]
 *
 * `rehearse.sh` runs it against a copy of the live code taken out of git, so
 * the garden it makes is the one the live service would have made: planted by
 * the rules and cuts deployed now, with the heights the phones send now. The
 * arrivals are grown by that code's SeedCore (`rehearse.sh` builds a small
 * tool for it) and handed over one JSON object a line.
 *
 * Every open area gets its arrivals in the order the file has them; every
 * seventh planting in each area is then taken back, so every table carries
 * rows whose seed is a marker; and the offers are made, the last of them
 * accepted, so the copy holds offers waiting and one answered.
 */

$api = rtrim($argv[1] ?? '', '/');
$dsn = $argv[2] ?? '';
$file = $argv[3] ?? '';
if ($api === '' || $dsn === '' || $file === '') {
    fwrite(STDERR, "usage: php tools/replant/Rehearsal/sow.php <.api dir> <dsn> <arrivals.jsonl> [user] [password]\n");
    exit(2);
}
require_once "$api/WalkStore.php";

$store = WalkStore::open($dsn, $argv[4] ?? null, $argv[5] ?? null);
$planted = [];
$offers = [];
foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    $a = json_decode($line, true, 8, JSON_THROW_ON_ERROR);
    if ($a['role'] === 'offer') { $offers[] = $a; continue; }
    $store->plantInto($a['area'], $a['seed'], $a['parentA'], $a['parentB'], $a['encounter'],
                      (float) $a['height'], (int) $a['family'], (string) $a['kind'],
                      $a['hue'] === null ? null : (float) $a['hue'], (string) $a['habit']);
    $planted[$a['area']][] = $a['seed'];
}

$taken = 0;
foreach ($planted as $area => $seeds) {
    foreach ($seeds as $i => $seed) {
        if ($i % 7 === 3) { $store->takeBackIn($area, $seed); $taken++; }
    }
}

$asking = $store->offers();
$now = time();
foreach ($offers as $i => $a) {
    $to = substr(hash('sha256', "rehearsal to $i"), 0, 32);
    $from = substr(hash('sha256', "rehearsal from $i"), 0, 32);
    $asking->offer($a['seed'], $to, $from, $a['parentA'], $a['parentB'], $a['encounter'],
                   (float) $a['height'], (int) $a['family'], $now - 60 + $i, $a['area'],
                   (string) $a['kind'], $a['hue'] === null ? null : (float) $a['hue'], (string) $a['habit']);
    if ($i === count($offers) - 1) $asking->answer($a['seed'], $to, true, $now);
}

$count = array_sum(array_map('count', $planted));
printf("sowed %d plantings in %d areas, %d taken back, %d offers (%d waiting, 1 accepted)\n",
    $count, count($planted), $taken, count($offers), max(0, count($offers) - 1));
