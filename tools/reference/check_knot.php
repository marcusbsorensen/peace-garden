<?php
declare(strict_types=1);

/**
 * The plot service places Knot Garden arrivals where SeedCore does.
 *
 * `tools/reference/knot_garden_vectors.json` is what `KnotGarden.Ways` in
 * SeedCore does with five hundred real crossings, starting from a Knot Garden
 * that already has its ambassador standing in the north compartment. This
 * replays the same five hundred through `Server/.api/KnotGarden.php` and fails
 * if any one of them lands anywhere else.
 *
 * **Why the whole five hundred rather than a sample.** This is the first rule
 * whose answer turns on a plant's colour rather than only its height. A port
 * that read the colour but claimed pairs in a different order — or that took
 * the fuller of a pair's two compartments — would agree about the whole of plot
 * 0, about most placements after that, and about every plot's total. It
 * diverges when a colour first runs out of room in the plot it started in,
 * which is a long way in.
 *
 *   php tools/reference/check_knot.php
 */

require_once __DIR__ . '/../../Server/.api/Ambassadors.php';
require_once __DIR__ . '/../../Server/.api/KnotGarden.php';

$vectors = json_decode(
    file_get_contents(__DIR__ . '/knot_garden_vectors.json'), true, 512, JSON_THROW_ON_ERROR
);

$failed = [];
$checks = 0;

// The Knot Garden as it opened: the ambassador and nothing else, which is what
// the Swift placed these five hundred around — and which has already claimed
// the first pair for its own colour.
$standing = Ambassadors::planting('pattern');
if ($standing === null) {
    fwrite(STDERR, "The service has no ambassador for the Knot Garden.\n");
    exit(1);
}
$ways = [$standing];

foreach ($vectors as $n => $want) {
    $got = KnotGarden::plant($ways, $want['seed'], $want['height'], $want['family']);
    $ways[] = $got;
    $checks++;
    $same = $got['plot'] === $want['plot']
        && $got['compartment'] === $want['compartment']
        && $got['index'] === $want['index']
        && $got['nudgeX'] === $want['nudge'][0]
        && $got['nudgeZ'] === $want['nudge'][1];
    if (!$same) {
        $failed[] = sprintf(
            'arrival %d (%s, %.3f m, colour %d): SeedCore put it in plot %d compartment %d place %d, '
                . 'the service in plot %d compartment %d place %d',
            $n, substr($want['seed'], 0, 12), $want['height'], $want['family'],
            $want['plot'], $want['compartment'], $want['index'],
            $got['plot'], $got['compartment'], $got['index']
        );
        if (count($failed) >= 5) break;
    }
}

$plots = KnotGarden::plots($ways);
$holdings = array_fill(0, $plots, 0);
foreach ($ways as $p) $holdings[$p['plot']]++;
$full = count(array_filter($holdings, fn($n) => $n === count(KnotGarden::slots())));

// And the shape of the place the two of them agree on, which is what a visitor
// sees: every plant inside its own compartment, a colour to a pair, the two
// compartments of a pair level with each other, and nothing standing in front
// of something shorter.
foreach ($ways as $p) {
    $checks++;
    [$x, $z] = KnotGarden::spot($p['compartment'], $p['index']);
    $atX = $x + $p['nudgeX'];
    $atZ = $z + $p['nudgeZ'];
    $inner = KnotGarden::BAND_FROM + KnotGarden::BAND_HALF_THICKNESS;
    $between = KnotGarden::BAND_FROM - KnotGarden::BAND_HALF_THICKNESS;
    $outer = KnotGarden::EDGING_FROM - KnotGarden::BAND_HALF_THICKNESS;
    $near = min(abs($atX), abs($atZ));
    $far = max(abs($atX), abs($atZ));
    $inside = KnotGarden::atCorner($p['compartment'])
        ? ($near > $inner && $far < $outer)
        : ($near < $between && $far > $inner && $far < $outer);
    if (!$inside) {
        $failed[] = sprintf('%s stands at %.2f, %.2f — outside compartment %d',
            substr($p['seed'], 0, 12), $atX, $atZ, $p['compartment']);
    }
}

for ($plot = 0; $plot < $plots; $plot++) {
    $here = array_values(array_filter($ways, fn($p) => $p['plot'] === $plot));
    foreach (KnotGarden::PAIRS as $pair) {
        $block = array_values(array_filter($here, fn($p) => KnotGarden::pairOf($p['compartment']) === $pair));
        $checks++;
        $families = array_values(array_unique(array_map(fn($p) => (int) $p['family'], $block)));
        if (count($families) > 1) {
            $failed[] = sprintf('plot %d pair %d holds colours %s',
                $plot, $pair, implode(' ', $families));
        }
        // Two compartments of a pair level with each other, unless the emptier
        // one had nothing of the right rank to offer. *Not* an assertion that
        // they never differ by more than one: a compartment whose remaining
        // places are the wrong rank is passed over however empty it is, and at
        // five hundred exactly one pair of sixty-six ends uneven.
        [$first, $second] = KnotGarden::compartmentsOf($pair);
        $counts = [];
        foreach ([$first, $second] as $compartment) {
            $counts[$compartment] = count(array_values(array_filter(
                $block, fn($p) => $p['compartment'] === $compartment)));
        }
        $checks++;
        if (abs($counts[$first] - $counts[$second]) > 2) {
            $failed[] = sprintf('plot %d pair %d holds %d and %d',
                $plot, $pair, $counts[$first], $counts[$second]);
        }
    }

    foreach (KnotGarden::COMPARTMENTS as $compartment) {
        $block = array_values(array_filter($here, fn($p) => $p['compartment'] === $compartment));
        foreach ($block as $one) {
            foreach ($block as $other) {
                $mine = KnotGarden::rankOf($one['index']);
                $theirs = KnotGarden::rankOf($other['index']);
                if ($mine >= $theirs) continue;
                $checks++;
                if ($one['height'] > $other['height']) {
                    $failed[] = sprintf('plot %d compartment %d: a %.2f m plant in front of a %.2f m one',
                        $plot, $compartment, $one['height'], $other['height']);
                }
            }
        }
    }

    // **An unclaimed pair is never passed over.** A plant that cannot join a
    // pair of its own colour claims a fresh one in the oldest plot that has
    // one, so an older plot holding an unclaimed pair while a newer plot holds
    // anything at all is the rule having skipped a place it should have taken.
    if ($plot < $plots - 1) {
        $unclaimed = array_values(array_filter(KnotGarden::PAIRS,
            fn($pair) => KnotGarden::familyOf($here, $pair) === null));
        $checks++;
        if ($unclaimed !== []) {
            $failed[] = sprintf('plot %d left pair %s unclaimed although plot %d was opened',
                $plot, implode(' ', $unclaimed), $plot + 1);
        }
    }

    // A plot opens in its north compartment, which is what makes the
    // ambassador the oldest plant of plot 0 without anything reserving a place.
    $checks++;
    if (($here[0]['compartment'] ?? -1) !== KnotGarden::NORTH) {
        $failed[] = "plot $plot did not open in its north compartment";
    }
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about the Knot Garden:\n");
    foreach ($failed as $line) fwrite(STDERR, "  $line\n");
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter KnotGardenVectorTests, or fix Server/.api/KnotGarden.php to match it.\n");
    exit(1);
}

printf("The PHP places all %d arrivals where the Swift does, across %d plots, %d of them full: %d checks.\n",
    count($vectors), $plots, $full, $checks);
