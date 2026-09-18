<?php
declare(strict_types=1);

/**
 * The plot service's placement rule is SeedCore's.
 *
 * Plants the six hundred arrivals in long_walk_vectors.json, in order, with
 * Server/.api/LongWalk.php, and checks each lands in the plot, slot and nudge
 * the Swift gave it. LongWalkVectorTests holds the file to the Swift; this
 * holds the PHP to the file. Run from anywhere:
 *
 *   php tools/reference/check_long_walk.php
 */

require __DIR__ . '/../../Server/.api/LongWalk.php';

$vectors = json_decode(file_get_contents(__DIR__ . '/long_walk_vectors.json'), true, 512, JSON_THROW_ON_ERROR);
$walk = [];
foreach ($vectors as $n => $v) {
    $p = LongWalk::plant($walk, $v['seed'], (float) $v['height'], $v['family']);
    $want = [$v['plot'], $v['side'], $v['tier'], $v['index'], (float) $v['nudge'][0], (float) $v['nudge'][1]];
    $got = [$p['plot'], $p['side'], $p['tier'], $p['index'], $p['nudgeX'], $p['nudgeZ']];
    if ($want !== $got) {
        fwrite(STDERR, sprintf(
            "arrival %d (%s…, height %s, family %d) placed differently\n  Swift: plot %d side %d tier %d index %d nudge %.17g, %.17g\n  PHP:   plot %d side %d tier %d index %d nudge %.17g, %.17g\n",
            $n, substr($v['seed'], 0, 8), $v['height'], $v['family'], ...$want, ...$got
        ));
        exit(1);
    }
    $walk[] = $p;
}
printf("The PHP places all %d arrivals where the Swift does, across %d plots.\n", count($vectors), LongWalk::plots($walk));
