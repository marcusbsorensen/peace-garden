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
    $got = QuietGarden::plant($room, $want['seed'], $want['height'], $want['family']);
    $room[] = $got;
    $checks++;
    $same = $got['plot'] === $want['plot']
        && $got['corner'] === $want['corner']
        && $got['index'] === $want['index']
        && $got['nudgeX'] === $want['nudge'][0]
        && $got['nudgeZ'] === $want['nudge'][1];
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
$full = count(array_filter($holdings, fn($n) => $n === count(QuietGarden::slots())));

$checks++;
if ($full < $plots - 3) {
    $failed[] = sprintf('only %d of %d plots are full: %s', $full, $plots, implode(' ', $holdings));
}

foreach ($room as $p) {
    $checks++;
    [$x, $z] = QuietGarden::spot($p['corner'], $p['index']);
    $out = max(abs($x + $p['nudgeX']), abs($z + $p['nudgeZ']));
    if ($out <= 1.5 || $out >= QuietGarden::HEDGE_FROM) {
        $failed[] = sprintf('%s stands at %.2f, %.2f — on the lawn or in the hedge',
            substr($p['seed'], 0, 12), $x + $p['nudgeX'], $z + $p['nudgeZ']);
    }
}

for ($plot = 0; $plot < $plots; $plot++) {
    foreach ([1, 2, 3] as $corner) {
        $group = array_values(array_filter(
            $room, fn($p) => $p['plot'] === $plot && $p['corner'] === $corner));
        if ($group === []) continue;
        $founder = $group[0];
        $allowed = array_merge([$founder['family']], QuietGarden::near($founder['family']));
        $back = null;
        foreach ($group as $p) {
            $checks++;
            if (!in_array($p['family'], $allowed, true)) {
                $failed[] = sprintf('plot %d corner %d: a colour %d in a colour %d group',
                    $plot, $corner, $p['family'], $founder['family']);
            }
            if ($p['index'] === 0) $back = $p;
        }
        if ($back === null) continue;
        foreach ($group as $p) {
            if ($p['index'] === 0) continue;
            $checks++;
            if ($p['height'] > $back['height']) {
                $failed[] = sprintf('plot %d corner %d: a %.2f m arm in front of a %.2f m back',
                    $plot, $corner, $p['height'], $back['height']);
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
