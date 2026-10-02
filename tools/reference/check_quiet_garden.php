<?php
declare(strict_types=1);

/**
 * The plot service places Quiet Garden arrivals where SeedCore does.
 *
 * `tools/reference/quiet_garden_vectors.json` is what `QuietGarden.Room` in
 * SeedCore does with five hundred real crossings, starting from a room that
 * already has its ambassador standing beside the bench. This replays the same
 * five hundred through `Server/.api/QuietGarden.php` and fails if any one of
 * them lands anywhere else.
 *
 * **Why the whole five hundred rather than a sample.** This rule returns the
 * first slot it finds rather than the best-scoring one, so a port that agreed
 * about every number and disagreed about which corner to look at first would
 * place the first few dozen plants identically and then diverge for ever. The
 * only way to see that is to run it until the plots are full.
 *
 *   php tools/reference/check_quiet_garden.php
 */

require_once __DIR__ . '/../../Server/.api/Ambassadors.php';
require_once __DIR__ . '/../../Server/.api/QuietGarden.php';

$vectors = json_decode(
    file_get_contents(__DIR__ . '/quiet_garden_vectors.json'), true, 512, JSON_THROW_ON_ERROR
);

$failed = [];
$checks = 0;

// The room as it opened: the ambassador and nothing else, which is what the
// Swift placed these five hundred around.
$standing = Ambassadors::planting('peace');
if ($standing === null) {
    fwrite(STDERR, "The service has no ambassador for the Quiet Garden.\n");
    exit(1);
}
$room = [$standing];

foreach ($vectors as $n => $want) {
    // The habit goes with them since 27 September: the pool is the one slot
    // this room chooses by what a plant is, so a vector without it would
    // check every rule but the one most likely to drift.
    $got = QuietGarden::plant($room, $want['seed'], $want['height'], $want['family'],
                              $want['habit'] ?? '');
    $room[] = $got;
    $checks++;
    // **And where it stands in its room**, since the room was made
    // asymmetric on 2 October 2026: the variant the plot's number deals it,
    // and its place and nudge turned by it. Exact, as the slot is.
    $variant = QuietGarden::variant($got['plot']);
    $spot = QuietGarden::spotOn($got['plot'], $got['corner'], $got['index'], $got['nudgeX'], $got['nudgeZ']);
    $same = $got['plot'] === $want['plot']
        && $got['corner'] === $want['corner']
        && $got['index'] === $want['index']
        && $got['nudgeX'] === $want['nudge'][0]
        && $got['nudgeZ'] === $want['nudge'][1]
        && [$variant['turn'], $variant['mirror'] ? 1 : 0, $variant['nudge']] === $want['variant']
        && $spot[0] === (float) $want['spot'][0] && $spot[1] === (float) $want['spot'][1];
    if (!$same) {
        $failed[] = sprintf(
            'arrival %d (%s, %.3f m, colour %d): SeedCore put it in plot %d corner %d slot %d, '
                . 'the service in plot %d corner %d slot %d',
            $n, substr($want['seed'], 0, 12), $want['height'], $want['family'],
            $want['plot'], $want['corner'], $want['index'],
            $got['plot'], $got['corner'], $got['index']
        );
        if (count($failed) >= 5) break;
    }
}

// And the shape of the room the two of them agree on, which is the thing a
// visitor sees: every plot but the growing end full, nothing on the lawn, and
// no group holding a colour from the far side of the circle.
$plots = QuietGarden::plots($room);
$holdings = array_fill(0, $plots, 0);
foreach ($room as $p) $holdings[$p['plot']]++;
// Full means its ground is full. A pool fills only when a lily arrives, and
// lilies are one arrival in twelve (a lily or a reed since 28 September 2026,
// two in fourteen), so a plot counted with its water in would
// almost never be full and this would be measuring the draw rather than the
// rule. `QuietGardenTests` splits it the same way.
$dry = count(array_filter(QuietGarden::slots(), fn($s) => QuietGarden::isDry($s['corner'])));
$holdings = array_map(
    fn($plot) => count(array_filter(
        $room,
        fn($p) => $p['plot'] === $plot && QuietGarden::isDry($p['corner'])
    )),
    range(0, $plots - 1)
);
$full = count(array_filter($holdings, fn($n) => $n === $dry));

$checks++;
if ($full < $plots - 3) {
    $failed[] = sprintf('only %d of %d plots are full: %s', $full, $plots, implode(' ', $holdings));
}

// The pool as each room lays it: the table's outline, turned.
$inside = function (array $p, array $loop): bool {
    $hit = false;
    for ($i = 0, $j = count($loop) - 1; $i < count($loop); $j = $i++) {
        [$ax, $az] = $loop[$i];
        [$bx, $bz] = $loop[$j];
        if (($az > $p[1]) !== ($bz > $p[1]) && $p[0] < ($bx - $ax) * ($p[1] - $az) / ($bz - $az) + $ax) $hit = !$hit;
    }
    return $hit;
};
$distance = function (array $p, array $loop): float {
    $best = INF;
    for ($i = 0, $n = count($loop); $i < $n; $i++) {
        [$ax, $az] = $loop[$i];
        [$bx, $bz] = $loop[($i + 1) % $n];
        $dx = $bx - $ax; $dz = $bz - $az;
        $m = $dx * $dx + $dz * $dz;
        $t = $m == 0 ? 0.0 : max(0.0, min(1.0, (($p[0] - $ax) * $dx + ($p[1] - $az) * $dz) / $m));
        $best = min($best, sqrt(($p[0] - $ax - $dx * $t) ** 2 + ($p[1] - $az - $dz * $t) ** 2));
    }
    return $best;
};
foreach ($room as $p) {
    $checks++;
    $at = QuietGarden::spotOn($p['plot'], $p['corner'], $p['index'], $p['nudgeX'], $p['nudgeZ']);
    $variant = QuietGarden::variant($p['plot']);
    $pool = array_map(fn($q) => PlotVariant::apply($variant, $q[0], $q[1]), QuietRoomTable::CURVES['pool'][0][1]);
    // A lily stands in the water on purpose, and the invariant for it is the
    // same one from the other side: inside its own water.
    if (!QuietGarden::isDry($p['corner'])) {
        if (!$inside($at, $pool)) {
            $failed[] = sprintf('%s stands at %.2f, %.2f — out of the water',
                                substr($p['seed'], 0, 12), $at[0], $at[1]);
        }
        continue;
    }
    $out = max(abs($at[0]), abs($at[1]));
    if ($inside($at, $pool) || $distance($at, $pool) <= 0.45 || $out >= QuietGarden::HEDGE_FROM - 0.15) {
        $failed[] = sprintf('%s stands at %.2f, %.2f — at the water or in the hedge',
            substr($p['seed'], 0, 12), $at[0], $at[1]);
    }
}

for ($plot = 0; $plot < $plots; $plot++) {
    $five = null;
    foreach ([QuietGarden::FIVE, QuietGarden::THREE, QuietGarden::ECHO] as $corner) {
        $group = array_values(array_filter(
            $room, fn($p) => $p['plot'] === $plot && $p['corner'] === $corner));
        if ($group === []) continue;
        // The echo shows the five's colour, or a tone of it; a group, its own
        // founder's.
        $founder = $corner === QuietGarden::ECHO ? $five : $group[0];
        if ($corner === QuietGarden::FIVE) $five = $group[0];
        $checks++;
        if ($founder === null) {
            $failed[] = "plot $plot has an echo of nothing";
            continue;
        }
        $allowed = array_merge([$founder['family']], QuietGarden::near($founder['family']));
        foreach ($group as $p) {
            $checks++;
            if (!in_array($p['family'], $allowed, true)) {
                $failed[] = sprintf('plot %d group %d: a colour %d where %d stands',
                    $plot, $corner, $p['family'], $founder['family']);
            }
        }
        foreach ($group as $back) {
            if (QuietGarden::standOf($corner, $back['index']) !== QuietGarden::BACK) continue;
            foreach ($group as $arm) {
                if (QuietGarden::standOf($corner, $arm['index']) !== QuietGarden::ARM) continue;
                $checks++;
                if ($arm['height'] > $back['height']) {
                    $failed[] = sprintf('plot %d group %d: a %.2f m arm in front of a %.2f m back',
                        $plot, $corner, $arm['height'], $back['height']);
                }
            }
        }
    }
}

// The plant beside the bench is the plot's oldest, which is what makes the
// ambassador the specimen of plot 0 without anything reserving a slot.
for ($plot = 0; $plot < $plots; $plot++) {
    $here = array_values(array_filter($room, fn($p) => $p['plot'] === $plot));
    $checks++;
    if (($here[0]['corner'] ?? -1) !== QuietGarden::BENCH) {
        $failed[] = "plot $plot did not open beside its bench";
    }
    $checks++;
    if (count(array_filter($here, fn($p) => $p['corner'] === QuietGarden::BENCH)) !== 1) {
        $failed[] = "plot $plot has more than one plant beside its bench";
    }
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about the Quiet Garden:\n");
    foreach ($failed as $line) fwrite(STDERR, "  $line\n");
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter QuietGardenVectorTests, or fix Server/.api/QuietGarden.php to match it.\n");
    exit(1);
}

printf("The PHP places all %d arrivals where the Swift does, across %d plots, %d of them full: %d checks.\n",
    count($vectors), $plots, $full, $checks);

// **Taking back keeps the place and erases the plant**, and moves nothing that
// arrives after it. `taking_back.php` says how that is checked.
require_once __DIR__ . '/taking_back.php';
takingBack('peace', $vectors);
