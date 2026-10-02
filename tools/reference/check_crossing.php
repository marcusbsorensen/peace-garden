<?php
declare(strict_types=1);

/**
 * The plot service places Crossing arrivals where SeedCore does.
 *
 * `tools/reference/crossing_vectors.json` is what `Crossing.Ways` in SeedCore
 * does with five hundred real crossings, starting from a Crossing that already
 * has its ambassador standing on the first quarter's diagonal. This replays the
 * same five hundred through `Server/.api/Crossing.php` and fails if any one of
 * them lands anywhere else.
 *
 * **Why the whole five hundred rather than a sample.** This rule picks the
 * emptiest quarter it finds rather than the best-scoring one, and keeps a tie on
 * the lowest-numbered quarter by testing `<` and not `<=`. A port that agreed
 * about every number and broke a tie the other way would place the first few
 * dozen plants identically and then diverge for ever. The only way to see that
 * is to run it until the plots are full.
 *
 *   php tools/reference/check_crossing.php
 */

require_once __DIR__ . '/../../Server/.api/Ambassadors.php';
require_once __DIR__ . '/../../Server/.api/Crossing.php';

$vectors = json_decode(
    file_get_contents(__DIR__ . '/crossing_vectors.json'), true, 512, JSON_THROW_ON_ERROR
);

$failed = [];
$checks = 0;

// The Crossing as it opened: the ambassador and nothing else, which is what the
// Swift placed these five hundred around.
$standing = Ambassadors::planting('meeting');
if ($standing === null) {
    fwrite(STDERR, "The service has no ambassador for the Crossing.\n");
    exit(1);
}
$ways = [$standing];

foreach ($vectors as $n => $want) {
    $got = Crossing::plant($ways, $want['seed'], $want['height'], $want['family']);
    $ways[] = $got;
    $checks++;
    // **And where it stands on its plot**, since the four ways began turning
    // in on 2 October 2026: the variant the plot's number deals it, and its
    // place and nudge turned by it. Exact, as the slot is.
    $variant = Crossing::variant($got['plot']);
    $spot = Crossing::spotOn($got['plot'], $got['quarter'], $got['index'], $got['nudgeX'], $got['nudgeZ']);
    $same = $got['plot'] === $want['plot']
        && $got['quarter'] === $want['quarter']
        && $got['index'] === $want['index']
        && $got['nudgeX'] === $want['nudge'][0]
        && $got['nudgeZ'] === $want['nudge'][1]
        && [$variant['turn'], $variant['mirror'] ? 1 : 0, $variant['nudge']] === $want['variant']
        && $spot[0] === (float) $want['spot'][0] && $spot[1] === (float) $want['spot'][1];
    if (!$same) {
        $failed[] = sprintf(
            'arrival %d (%s, %.3f m, colour %d): SeedCore put it in plot %d quarter %d slot %d, '
                . 'the service in plot %d quarter %d slot %d',
            $n, substr($want['seed'], 0, 12), $want['height'], $want['family'],
            $want['plot'], $want['quarter'], $want['index'],
            $got['plot'], $got['quarter'], $got['index']
        );
        if (count($failed) >= 5) break;
    }
}

// And the shape of the place the two of them agree on, which is what a visitor
// sees: every plot but the growing end full, the four quarters level, nothing
// standing on a path or on the paving, and nothing in front of something
// shorter than itself.
$plots = Crossing::plots($ways);
$holdings = array_fill(0, $plots, 0);
foreach ($ways as $p) $holdings[$p['plot']]++;
$full = count(array_filter($holdings, fn($n) => $n === count(Crossing::slots())));

$checks++;
if ($full < $plots - 2) {
    $failed[] = sprintf('only %d of %d plots are full: %s', $full, $plots, implode(' ', $holdings));
}

// The paths as each plot lays them: the table's centre lines, turned.
$halfWidth = function (float $r): float {
    $t = min(1.0, max(0.0, ($r - Crossing::ROUNDEL_RADIUS) / (Crossing::PLOT_SIDE / 2 - Crossing::ROUNDEL_RADIUS)));
    return Crossing::PATH_HALF_WIDTH_AT_ROUND
        + (Crossing::PATH_HALF_WIDTH - Crossing::PATH_HALF_WIDTH_AT_ROUND) * $t * $t * (3 - 2 * $t);
};
foreach ($ways as $p) {
    $checks++;
    [$atX, $atZ] = Crossing::spotOn($p['plot'], $p['quarter'], $p['index'], $p['nudgeX'], $p['nudgeZ']);
    if (max(abs($atX), abs($atZ)) >= Crossing::PLOT_SIDE / 2 - 0.3) {
        $failed[] = sprintf('%s stands at %.2f, %.2f — at the edge of its plot',
            substr($p['seed'], 0, 12), $atX, $atZ);
    }
    $variant = Crossing::variant($p['plot']);
    $room = INF;
    foreach ([0, 1, 2, 3] as $q) {
        [, $points] = CrossingWaysTable::CURVES["way$q"][0];
        foreach ($points as [$wx, $wz]) {
            [$wx, $wz] = PlotVariant::apply($variant, $wx, $wz);
            $room = min($room, sqrt(($atX - $wx) ** 2 + ($atZ - $wz) ** 2) - $halfWidth(sqrt($wx * $wx + $wz * $wz)));
        }
    }
    if ($room <= 0.05) {
        $failed[] = sprintf('%s stands at %.2f, %.2f — on a path',
            substr($p['seed'], 0, 12), $atX, $atZ);
    }
    if (sqrt($atX * $atX + $atZ * $atZ) <= Crossing::ROUNDEL_RADIUS) {
        $failed[] = sprintf('%s stands at %.2f, %.2f — on the paving',
            substr($p['seed'], 0, 12), $atX, $atZ);
    }
}

for ($plot = 0; $plot < $plots; $plot++) {
    $here = array_values(array_filter($ways, fn($p) => $p['plot'] === $plot));
    $counts = [];
    foreach ([0, 1, 2, 3] as $quarter) {
        $bed = array_values(array_filter($here, fn($p) => $p['quarter'] === $quarter));
        $counts[] = count($bed);
        foreach ($bed as $one) {
            foreach ($bed as $other) {
                if (Crossing::rankOf($one['index']) >= Crossing::rankOf($other['index'])) continue;
                $checks++;
                if ($one['height'] > $other['height']) {
                    $failed[] = sprintf('plot %d quarter %d: a %.2f m plant in front of a %.2f m one',
                        $plot, $quarter, $one['height'], $other['height']);
                }
            }
        }
    }
    // The rule the area is for: an arrival goes where there is least, so no
    // quarter runs away from the others.
    $checks++;
    if (max($counts) - min($counts) > 2) {
        $failed[] = sprintf('plot %d quarters hold %s, which is not four ways equally used',
            $plot, implode(' ', $counts));
    }
    // A plot opens in its first quarter, which is what makes the
    // ambassador the oldest plant of plot 0 without anything reserving a slot.
    $checks++;
    if (($here[0]['quarter'] ?? -1) !== 0) {
        $failed[] = "plot $plot did not open in its first quarter";
    }
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about the Crossing:\n");
    foreach ($failed as $line) fwrite(STDERR, "  $line\n");
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter CrossingVectorTests, or fix Server/.api/Crossing.php to match it.\n");
    exit(1);
}

printf("The PHP places all %d arrivals where the Swift does, across %d plots, %d of them full: %d checks.\n",
    count($vectors), $plots, $full, $checks);

// **Taking back keeps the place and erases the plant**, and moves nothing that
// arrives after it. `taking_back.php` says how that is checked.
require_once __DIR__ . '/taking_back.php';
takingBack('meeting', $vectors);
