<?php
declare(strict_types=1);

/**
 * The plot service turns, mirrors and varies a plot as SeedCore does.
 *
 * `tools/reference/plot_variant_vectors.json` is what `PlotVariant` in SeedCore
 * deals to three hundred plots of every space an area could declare, each under
 * a different area's salt, and where it draws a handful of places under every
 * turn and mirror. This deals and draws the same through
 * `Server/.api/PlotVariant.php` and fails if any one differs.
 *
 * **Why every space and not the ten the areas declare.** Each area settles its
 * own space in its own file as its layout is built; an area whose rule or
 * drawing reads its variant pins its own plots in its own vector file. What is
 * shared is the function, and the one place a port goes wrong is the
 * thirty-two-bit arithmetic, which this reaches in every space.
 *
 * And the decision itself, which the Swift's `PlotVariantTests` holds on its
 * side: the Knot Garden and the Glasshouse are laid one way, and the other
 * eight vary.
 *
 *   php tools/reference/check_plot_variant.php
 */

require_once __DIR__ . '/../../Server/.api/PlotVariant.php';
foreach (['LongWalk', 'QuietGarden', 'Crossing', 'Orchard', 'KnotGarden', 'Seedbed', 'ColdFrame',
          'Glasshouse', 'Coppice', 'HomeGround'] as $class) {
    require_once __DIR__ . "/../../Server/.api/$class.php";
}

$vectors = json_decode(
    file_get_contents(__DIR__ . '/plot_variant_vectors.json'), true, 512, JSON_THROW_ON_ERROR
);

$failed = [];
$checks = 0;

foreach ($vectors['salts'] as $area => $salt) {
    $checks++;
    if (PlotVariant::salt($area) !== $salt) {
        $failed[] = sprintf('%s salts to %d here and %d in SeedCore', $area, PlotVariant::salt($area), $salt);
    }
}

foreach ($vectors['dealt'] as $row) {
    $space = ['turns' => $row['turns'], 'mirror' => $row['mirror'], 'nudges' => $row['nudges']];
    foreach ($row['plots'] as $plot => [$turn, $mirror, $nudge]) {
        $checks++;
        $got = PlotVariant::of($plot, $row['area'], $space);
        if ($got !== ['turn' => $turn, 'mirror' => $mirror === 1, 'nudge' => $nudge]) {
            $failed[] = sprintf('plot %d of %s in a space of %d turns, %s, %d nudges: SeedCore deals [%d %d %d], '
                . 'the service [%d %d %d]', $plot, $row['area'], $row['turns'], $row['mirror'] ? 'mirrored' : 'unmirrored',
                $row['nudges'], $turn, $mirror, $nudge, $got['turn'], $got['mirror'] ? 1 : 0, $got['nudge']);
            if (count($failed) >= 8) break 2;
        }
    }
}

foreach ($vectors['spots'] as $row) {
    $checks++;
    $variant = ['turn' => $row['turn'], 'mirror' => $row['mirror'], 'nudge' => 0];
    $got = PlotVariant::apply($variant, (float) $row['from'][0], (float) $row['from'][1]);
    if ($got[0] !== (float) $row['to'][0] || $got[1] !== (float) $row['to'][1]) {
        $failed[] = sprintf('turn %d, %s, takes [%s, %s] to [%s, %s] in SeedCore and [%s, %s] here',
            $row['turn'], $row['mirror'] ? 'mirrored' : 'unmirrored', $row['from'][0], $row['from'][1],
            $row['to'][0], $row['to'][1], $got[0], $got[1]);
    }
    $checks++;
    $back = PlotVariant::undo($variant, $got[0], $got[1]);
    if ($back[0] !== (float) $row['from'][0] || $back[1] !== (float) $row['from'][1]) {
        $failed[] = sprintf('turn %d, %s, does not undo to [%s, %s]', $row['turn'],
            $row['mirror'] ? 'mirrored' : 'unmirrored', $row['from'][0], $row['from'][1]);
    }
}

// The decision of 2 October 2026: all but the Knot Garden and the Glasshouse
// vary, and plot 0 of every area is the plan as drawn.
foreach (['travel' => LongWalk::VARIANTS, 'peace' => QuietGarden::VARIANTS, 'meeting' => Crossing::VARIANTS,
          'kinship' => Orchard::VARIANTS, 'pattern' => KnotGarden::VARIANTS, 'beginnings' => Seedbed::VARIANTS,
          'waiting' => ColdFrame::VARIANTS, 'light' => Glasshouse::VARIANTS, 'renewal' => Coppice::VARIANTS,
          'ground' => HomeGround::VARIANTS] as $area => $space) {
    $checks++;
    $fixed = $area === 'pattern' || $area === 'light';
    if ((PlotVariant::count($space) === 1) !== $fixed) {
        $failed[] = sprintf('%s %s, and should %s', $area, $fixed ? 'varies' : 'is laid one way',
            $fixed ? 'be laid one way' : 'vary');
    }
    $checks++;
    if (PlotVariant::of(0, $area, $space) !== PlotVariant::PLAIN) {
        $failed[] = sprintf('plot 0 of %s is not the plan as drawn', $area);
    }
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about how a plot varies:\n");
    foreach ($failed as $line) fwrite(STDERR, "  $line\n");
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter PlotVariantVectorTests, or fix Server/.api/PlotVariant.php to match it.\n");
    exit(1);
}

printf("The PHP deals %d spaces of %d plots and draws %d places as the Swift does: %d checks.\n",
    count($vectors['dealt']), count($vectors['dealt'][0]['plots']), count($vectors['spots']), $checks);
