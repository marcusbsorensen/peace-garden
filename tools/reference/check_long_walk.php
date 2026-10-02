<?php
declare(strict_types=1);

/**
 * The plot service's placement rule is SeedCore's.
 *
 * Plants the six hundred arrivals in long_walk_vectors.json, in order, with
 * Server/.api/LongWalk.php, and checks each lands in the plot, slot and nudge
 * the Swift gave it — and, since the drifts of 2 October 2026, that its plot
 * is laid the same way round and the plant stands on the same spot, to the
 * last bit. LongWalkVectorTests holds the file to the Swift; this holds the PHP
 * to the file. Run from anywhere:
 *
 *   php tools/reference/check_long_walk.php
 */

require __DIR__ . '/../../Server/.api/LongWalk.php';

$vectors = json_decode(file_get_contents(__DIR__ . '/long_walk_vectors.json'), true, 512, JSON_THROW_ON_ERROR);
$walk = [];
foreach ($vectors as $n => $v) {
    $p = LongWalk::plant($walk, $v['seed'], (float) $v['height'], $v['family']);
    $variant = LongWalk::variant($p['plot']);
    $spot = LongWalk::spot($p['plot'], $p['index'], $p['nudgeX'], $p['nudgeZ']);
    $want = [$v['plot'], $v['side'], $v['tier'], $v['index'], (float) $v['nudge'][0], (float) $v['nudge'][1],
             $v['variant'], (float) $v['spot'][0], (float) $v['spot'][1]];
    $got = [$p['plot'], $p['side'], $p['tier'], $p['index'], $p['nudgeX'], $p['nudgeZ'],
            [$variant['turn'], $variant['mirror'] ? 1 : 0, $variant['nudge']], $spot[0], $spot[1]];
    if ($want !== $got) {
        fwrite(STDERR, sprintf(
            "arrival %d (%s…, height %s, family %d) placed differently\n"
                . "  Swift: plot %d side %d tier %d index %d nudge %.17g, %.17g at %.17g, %.17g\n"
                . "  PHP:   plot %d side %d tier %d index %d nudge %.17g, %.17g at %.17g, %.17g\n",
            $n, substr($v['seed'], 0, 8), $v['height'], $v['family'],
            $want[0], $want[1], $want[2], $want[3], $want[4], $want[5], $want[7], $want[8],
            $got[0], $got[1], $got[2], $got[3], $got[4], $got[5], $got[7], $got[8]
        ));
        exit(1);
    }
    $walk[] = $p;
}

// **And the walk the two agree on is the one Marcus chose**: a lens of one
// colour, no colour in two lenses side by side, nothing in front of something
// shorter. Checked of the PHP's walk, so a port that agreed with a broken Swift
// would still be caught here.
$failed = [];
$slots = LongWalk::slots();
$where = [];
foreach ($slots as $slot) $where[$slot['lens']] = [$slot['side'], $slot['along']];
$byPlot = [];
foreach ($walk as $p) $byPlot[$p['plot']][] = $p;
foreach ($byPlot as $plot => $here) {
    $colour = [];
    foreach ($here as $p) {
        $lens = $slots[$p['index']]['lens'];
        $colour[$lens] ??= $p['family'];
        if ($colour[$lens] !== $p['family']) $failed[] = "plot $plot lens $lens holds two colours";
        foreach ($here as $q) {
            if ($q['side'] !== $p['side'] || $q['tier'] <= $p['tier']) continue;
            if (abs($slots[$q['index']]['z'] - $slots[$p['index']]['z']) > LongWalk::ORDER_REACH) continue;
            if ($q['height'] < $p['height']) $failed[] = "plot $plot: {$p['seed']} stands in front of something shorter";
        }
    }
    foreach ($colour as $a => $family) {
        foreach ($colour as $b => $other) {
            if ($a >= $b || $family !== $other || $where[$a][0] !== $where[$b][0]) continue;
            if (abs($where[$a][1] - $where[$b][1]) === 1) {
                $failed[] = "plot $plot: lenses $a and $b side by side are both colour $family";
            }
        }
    }
}
if ($failed !== []) {
    fwrite(STDERR, "The Long Walk the two agree on is not the one chosen:\n  " . implode("\n  ", array_slice($failed, 0, 5)) . "\n");
    exit(1);
}

printf("The PHP places all %d arrivals where the Swift does, across %d plots, each on the same spot.\n",
       count($vectors), LongWalk::plots($walk));

// **Taking back keeps the place and erases the plant**, and moves nothing that
// arrives after it. `taking_back.php` says how that is checked.
require_once __DIR__ . '/taking_back.php';
takingBack('travel', $vectors);
