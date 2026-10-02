<?php
declare(strict_types=1);

/**
 * The plot service places Glasshouse arrivals where SeedCore does.
 *
 * `tools/reference/glasshouse_vectors.json` is what `Glasshouse.Ways` in
 * SeedCore does with five hundred real crossings, starting from a Glasshouse
 * that already has its ambassador potted on the staging. This replays the same
 * five hundred through `Server/.api/Glasshouse.php` and fails if any one of them
 * lands anywhere else.
 *
 * **Why the whole five hundred rather than a sample.** The staging has three
 * steps that agree with each other for a long while: a pot's own band, then a
 * neighbour, then a new plot. A port that tried each plot's neighbours before
 * the next plot's own band would agree until the first time a band is full in
 * one plot and free in another, and one that tried the lower neighbour first
 * whatever the hue would agree until the first pot whose hue leans the other
 * way finds its own band full. Both were tried against this file before it was
 * committed: the first parts company at arrival 26, the second at arrival 103.
 *
 * **Compared exactly, the hue included.** Plot, bed, place and row are integers
 * and the nudge is two bytes of the seed divided by 255. **And where each one
 * stands**, since the house became round on 2 October 2026: the plot's variant
 * (the plain plan, always, in this area) and the spot, the table's place plus
 * the nudge — literals and one addition, so the same double here as there. The hue is the seed's
 * bytes through `+ − × ÷` and arrives as that double, so where it falls
 * against a band edge is the same here as in the Swift to the last bit. The
 * heights are compared only with the border's cut, and the Swift's own vector
 * test checked none of the five hundred stands close enough to it for a host's
 * rounding to matter.
 *
 *   php tools/reference/check_glasshouse.php
 */

require_once __DIR__ . '/../../Server/.api/Ambassadors.php';
require_once __DIR__ . '/../../Server/.api/Glasshouse.php';

$vectors = json_decode(
    file_get_contents(__DIR__ . '/glasshouse_vectors.json'), true, 512, JSON_THROW_ON_ERROR
);

$failed = [];
$checks = 0;

// The Glasshouse as it opened: the ambassador in the middle of the bed, which
// is what the Swift placed these five hundred around.
$standing = Ambassadors::planting('light');
if ($standing === null) {
    fwrite(STDERR, "The service has no ambassador for the Glasshouse.\n");
    exit(1);
}
$ways = [$standing];

foreach ($vectors as $n => $want) {
    $got = Glasshouse::plant($ways, $want['seed'], $want['height'], $want['family'], (float) $want['hue']);
    $ways[] = $got;
    $checks++;
    $variant = PlotVariant::of($got['plot'], 'light', Glasshouse::VARIANTS);
    $spot = Glasshouse::standing($got['plot'], $got['bed'], $got['index'], $got['row'],
                                 $got['nudgeX'], $got['nudgeZ']);
    $same = $got['plot'] === $want['plot']
        && $got['bed'] === $want['bed']
        && $got['index'] === $want['index']
        && $got['row'] === $want['row']
        && $got['nudgeX'] === $want['nudge'][0]
        && $got['nudgeZ'] === $want['nudge'][1]
        && [$variant['turn'], $variant['mirror'], $variant['nudge']] === $want['variant']
        && $spot === [(float) $want['spot'][0], (float) $want['spot'][1]];
    if (!$same) {
        $failed[] = sprintf(
            'arrival %d (%s, %.3f m, hue %.4f, colour %d): SeedCore put it in plot %d bed %d place %d row %d, '
                . 'the service in plot %d bed %d place %d row %d',
            $n, substr($want['seed'], 0, 12), $want['height'], $want['hue'], $want['family'],
            $want['plot'], $want['bed'], $want['index'], $want['row'],
            $got['plot'], $got['bed'], $got['index'], $got['row']
        );
        if (count($failed) >= 5) break;
    }
}

$plots = Glasshouse::plots($ways);
$pots = 0;
$ownBand = 0;
$hued = 0;

// And the shape of the place the two of them agree on, which is what a visitor
// sees: every plant inside the round house, the tallest in the bed in the
// middle and the rest in pots on the ring, every pot in its own band or one
// beside it, the bed filled in its order, and no older plot passed over.
foreach ($ways as $p) {
    $checks++;
    [$atX, $atZ] = Glasshouse::standing($p['plot'], $p['bed'], $p['index'], $p['row'], $p['nudgeX'], $p['nudgeZ']);
    $r = sqrt($atX * $atX + $atZ * $atZ);
    $where = $p['bed'] === Glasshouse::STAGING
        ? abs($r - Glasshouse::STAGING_RADIUS) < Glasshouse::STAGING_DEPTH / 2 - 0.1
        : $r < Glasshouse::BED_RADIUS - 0.05;
    if (!$where || $r >= Glasshouse::HOUSE_RADIUS - 0.2) {
        $failed[] = sprintf('%s stands at %.2f, %.2f — off its bed', substr($p['seed'], 0, 12), $atX, $atZ);
    }
    $checks++;
    if ($p['bed'] !== Glasshouse::bed($p['height'])) {
        $failed[] = sprintf('%s is %.2f m and stands in bed %d', substr($p['seed'], 0, 12), $p['height'], $p['bed']);
    }
    if ($p['bed'] !== Glasshouse::STAGING) continue;
    $pots++;
    if (Glasshouse::isUnplaced($p['family'], $p['hue'])) continue;
    $hued++;
    $by = abs($p['index'] - Glasshouse::band($p['hue']));
    if ($by === 0) $ownBand++;
    $checks++;
    if ($by > 1) {
        $failed[] = sprintf('%s stands %d places from its band', substr($p['seed'], 0, 12), $by);
    }
}

for ($plot = 0; $plot < $plots; $plot++) {
    $here = array_values(array_filter($ways, fn($p) => $p['plot'] === $plot));

    // The bed fills in its order: 0, 1, 2 and so on with nothing missing.
    $checks++;
    $border = array_map(fn($p) => $p['index'],
        array_values(array_filter($here, fn($p) => $p['bed'] === Glasshouse::BORDER)));
    sort($border);
    if ($border !== [] && $border !== range(0, count($border) - 1)) {
        $failed[] = sprintf('plot %d\'s border is filled %s', $plot, implode(' ', $border));
    }

    // Each band on the staging fills its row 0 first, and holds no more than
    // two pots.
    for ($position = 0; $position < Glasshouse::POSITIONS; $position++) {
        $checks++;
        $rows = array_map(fn($p) => $p['row'], array_values(array_filter($here,
            fn($p) => $p['bed'] === Glasshouse::STAGING && $p['index'] === $position)));
        sort($rows);
        if ($rows !== [] && $rows !== range(0, count($rows) - 1)) {
            $failed[] = sprintf('plot %d band %d holds rows %s', $plot, $position, implode(' ', $rows));
        }
    }

    // **An older plot's border is never passed over.** A border plant takes the
    // oldest plot with room, so an older plot with a border place free while a
    // newer one has a border plant in it is the rule having skipped a place.
    if ($plot < $plots - 1) {
        $later = array_filter($ways, fn($p) => $p['plot'] > $plot && $p['bed'] === Glasshouse::BORDER);
        $checks++;
        if ($later !== [] && count($border) < Glasshouse::BORDER_PLACES) {
            $failed[] = sprintf('plot %d\'s border has room although a later plot\'s border was planted', $plot);
        }
    }
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about the Glasshouse:\n");
    foreach ($failed as $line) fwrite(STDERR, "  $line\n");
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter GlasshouseVectorTests, or fix Server/.api/Glasshouse.php to match it.\n");
    exit(1);
}

printf("The PHP places all %d arrivals where the Swift does, across %d plots, "
     . "%d in pots and %d in the border, %d of %d hued pots in their own band: %d checks.\n",
    count($vectors), $plots, $pots, count($ways) - $pots, $ownBand, $hued, $checks);

// **Taking back keeps the place and erases the plant**, and moves nothing that
// arrives after it. `taking_back.php` says how that is checked.
require_once __DIR__ . '/taking_back.php';
takingBack('light', $vectors);
