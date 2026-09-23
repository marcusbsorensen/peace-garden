<?php
declare(strict_types=1);

/**
 * The plot service places Seedbed arrivals where SeedCore does.
 *
 * `tools/reference/seedbed_vectors.json` is what `Seedbed.Ways` in SeedCore does
 * with five hundred real crossings, starting from a Seedbed that already has its
 * ambassador at the head of the first drill. This replays the same five hundred
 * through `Server/.api/Seedbed.php` and fails if any one of them lands anywhere
 * else.
 *
 * **Why the whole five hundred rather than a sample.** This is the first rule
 * that groups by sameness rather than sorting by difference, and the question it
 * asks — which drill is this kind's — has two answers that agree for a long
 * while. A port that claimed drills in a different order, or that let a kind
 * claim a second drill in a plot where its first is already full, places the
 * whole of plot 0 exactly as the Swift does and diverges only when a common kind
 * first fills eight places, which is a long way in.
 *
 * **Compared exactly, with no tolerance anywhere.** The other areas' checks
 * allow for a height landing either side of a cut on a different host; this one
 * has no cuts. A drill comes from a string and a place from a count, and the
 * nudge is two bytes of the seed divided by 255 — all of it exact on every host,
 * so anything that differs is a port that differs.
 *
 *   php tools/reference/check_seedbed.php
 */

require_once __DIR__ . '/../../Server/.api/Ambassadors.php';
require_once __DIR__ . '/../../Server/.api/Seedbed.php';

$vectors = json_decode(
    file_get_contents(__DIR__ . '/seedbed_vectors.json'), true, 512, JSON_THROW_ON_ERROR
);

$failed = [];
$checks = 0;

// The Seedbed as it opened: the ambassador and nothing else, which is what the
// Swift placed these five hundred around — and which has already claimed the
// first drill for its own kind.
$standing = Ambassadors::planting('beginnings');
if ($standing === null) {
    fwrite(STDERR, "The service has no ambassador for the Seedbed.\n");
    exit(1);
}
$ways = [$standing];

foreach ($vectors as $n => $want) {
    $got = Seedbed::plant($ways, $want['seed'], $want['height'], $want['family'], $want['kind']);
    $ways[] = $got;
    $checks++;
    $same = $got['plot'] === $want['plot']
        && $got['drill'] === $want['drill']
        && $got['index'] === $want['index']
        && $got['nudgeX'] === $want['nudge'][0]
        && $got['nudgeZ'] === $want['nudge'][1];
    if (!$same) {
        $failed[] = sprintf(
            'arrival %d (%s, %s): SeedCore put it in plot %d drill %d place %d, '
                . 'the service in plot %d drill %d place %d',
            $n, substr($want['seed'], 0, 12), $want['kind'],
            $want['plot'], $want['drill'], $want['index'],
            $got['plot'], $got['drill'], $got['index']
        );
        if (count($failed) >= 5) break;
    }
}

$plots = Seedbed::plots($ways);
$claimed = 0;
$full = 0;

// And the shape of the place the two of them agree on, which is what a visitor
// sees: a kind to a drill, every drill sown from its label with no gap, no older
// plot passed over, and every plant inside the bed.
foreach ($ways as $p) {
    $checks++;
    [$x, $z] = Seedbed::spot($p['drill'], $p['index']);
    $atX = $x + $p['nudgeX'];
    $atZ = $z + $p['nudgeZ'];
    // Half the plot, less the half-metre path a gardener kneels in. A seedbed
    // that reached the rim would be a bed nobody could sow.
    $edge = Seedbed::PLOT_SIDE / 2 - 0.5;
    if (abs($atX) >= $edge || abs($atZ) >= $edge) {
        $failed[] = sprintf('%s stands at %.2f, %.2f — outside the bed',
            substr($p['seed'], 0, 12), $atX, $atZ);
    }
}

for ($plot = 0; $plot < $plots; $plot++) {
    $here = array_values(array_filter($ways, fn($p) => $p['plot'] === $plot));
    for ($drill = 0; $drill < Seedbed::DRILLS; $drill++) {
        $block = array_values(array_filter($here, fn($p) => $p['drill'] === $drill));
        if ($block === []) continue;
        $claimed++;
        if (count($block) === Seedbed::PLACES) $full++;

        // One kind to a drill, which is the whole of what a seedbed is for.
        $checks++;
        $kinds = array_values(array_unique(array_map(fn($p) => (string) $p['kind'], $block)));
        if (count($kinds) > 1) {
            $failed[] = sprintf('plot %d drill %d holds %s', $plot, $drill, implode(' ', $kinds));
        }

        // And it fills from the label outward: 0, 1, 2 and so on with nothing
        // missing. A gap would be a place nobody can explain — the drill was
        // sown in the order it was sown, and reading it from the label is
        // reading that order.
        $checks++;
        $taken = array_map(fn($p) => (int) $p['index'], $block);
        sort($taken);
        if ($taken !== range(0, count($taken) - 1)) {
            $failed[] = sprintf('plot %d drill %d is sown %s', $plot, $drill, implode(' ', $taken));
        }
    }

    // **An unclaimed drill is never passed over.** A plant that cannot join a
    // drill of its own kind claims a fresh one in the oldest plot that has one,
    // so an older plot holding an unclaimed drill while a newer plot holds
    // anything at all is the rule having skipped a place it should have taken.
    if ($plot < $plots - 1) {
        $unsown = [];
        for ($drill = 0; $drill < Seedbed::DRILLS; $drill++) {
            if (Seedbed::kindOf($here, $drill) === null) $unsown[] = $drill;
        }
        $checks++;
        if ($unsown !== []) {
            $failed[] = sprintf('plot %d left drill %s unclaimed although plot %d was opened',
                $plot, implode(' ', $unsown), $plot + 1);
        }
    }
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about the Seedbed:\n");
    foreach ($failed as $line) fwrite(STDERR, "  $line\n");
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter SeedbedVectorTests, or fix Server/.api/Seedbed.php to match it.\n");
    exit(1);
}

printf("The PHP sows all %d arrivals where the Swift does, across %d plots, "
     . "%d drills claimed and %d of them full: %d checks.\n",
    count($vectors), $plots, $claimed, $full, $checks);
