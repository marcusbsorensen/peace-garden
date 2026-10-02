<?php
declare(strict_types=1);

/**
 * The plot service places Coppice arrivals where SeedCore does.
 *
 * `tools/reference/coppice_vectors.json` is what `Coppice.Ways` in SeedCore does
 * with five hundred real crossings, starting from a Coppice that already has its
 * ambassador standing on the first coupe's first stool. This replays the same
 * five hundred through `Server/.api/Coppice.php` and fails if any one of them
 * lands anywhere else, or is drawn anywhere else: since 2 October 2026 each
 * row carries its plot's variant and its spot.
 *
 * **Why the whole five hundred rather than a sample.** The rule has steps that
 * agree with each other for a long while: a fern's stool, then the floor with
 * its cap of one fern a coupe, then a new plot; a star's own row, then the other
 * if it keeps the rows in order. A port that counted a floor's ferns across the
 * whole plot rather than the coupe, or chose a coupe by its stools rather than
 * its floor, would agree until the first time those differ — and that is late,
 * because ferns reach the floor only once every stool is taken.
 *
 * **Compared exactly.** Plot, coupe, place and index are integers, the habit is
 * a word, and the nudge is two bytes of the seed divided by 255. The heights
 * are compared with the floor's cut and with each other on one floor, and the
 * Swift's own vector test checked that none of the five hundred stands close
 * enough to either for a host's rounding to matter.
 *
 *   php tools/reference/check_coppice.php
 */

require_once __DIR__ . '/../../Server/.api/Ambassadors.php';
require_once __DIR__ . '/../../Server/.api/Coppice.php';

$vectors = json_decode(
    file_get_contents(__DIR__ . '/coppice_vectors.json'), true, 512, JSON_THROW_ON_ERROR
);

$failed = [];
$checks = 0;

$standing = Ambassadors::planting('renewal');
if ($standing === null) {
    fwrite(STDERR, "The service has no ambassador for the Coppice.\n");
    exit(1);
}
$ways = [$standing];

foreach ($vectors as $n => $want) {
    $got = Coppice::plant($ways, $want['seed'], $want['height'], $want['family'], $want['habit']);
    $ways[] = $got;
    $checks++;
    $same = $got['plot'] === $want['plot']
        && $got['coupe'] === $want['coupe']
        && $got['place'] === $want['place']
        && $got['index'] === $want['index']
        && $got['nudgeX'] === $want['nudge'][0]
        && $got['nudgeZ'] === $want['nudge'][1];
    if (!$same) {
        $failed[] = sprintf(
            'arrival %d (%s, a %s of %.3f m): SeedCore put it in plot %d coupe %d place %d index %d, '
                . 'the service in plot %d coupe %d place %d index %d',
            $n, substr($want['seed'], 0, 12), $want['habit'], $want['height'],
            $want['plot'], $want['coupe'], $want['place'], $want['index'],
            $got['plot'], $got['coupe'], $got['place'], $got['index']
        );
        if (count($failed) >= 5) break;
        continue;
    }
    // **And where the service says it stands**, since the coupes went round a
    // glade on 2 October 2026: the plot's variant, and the spot the table and
    // the turn give. Both exact, so compared with no tolerance.
    $checks++;
    $variant = Coppice::variant($got['plot']);
    $spot = Coppice::spot($got['plot'], $got['coupe'], $got['place'], $got['index'], $got['nudgeX'], $got['nudgeZ']);
    $wantVariant = [$want['variant'][0], $want['variant'][1] === 1, $want['variant'][2]];
    if ([$variant['turn'], $variant['mirror'], $variant['nudge']] !== $wantVariant || $spot !== $want['spot']) {
        $failed[] = sprintf('arrival %d (%s): SeedCore stands it at %s in variant %s, the service at %s in %s',
            $n, substr($want['seed'], 0, 12), json_encode($want['spot']), json_encode($want['variant']),
            json_encode($spot), json_encode($variant));
        if (count($failed) >= 5) break;
    }
}

// The space the port declares is the table's: as many feature variants as it
// has places for, each with every slot once.
$checks++;
if (Coppice::VARIANTS['nudges'] !== count(CoppiceGladeTable::PLACES)) {
    $failed[] = sprintf('Coppice::VARIANTS says %d feature variants and the table has %d',
        Coppice::VARIANTS['nudges'], count(CoppiceGladeTable::PLACES));
}
foreach (CoppiceGladeTable::PLACES as $nudge => $places) {
    $checks++;
    $tags = array_map(fn($row) => "{$row[2]}:{$row[3]}:{$row[4]}", $places);
    if (count(array_unique($tags)) !== Coppice::COUPES * (Coppice::STOOLS + 2 * Coppice::FLOOR_ROW)) {
        $failed[] = "the Coppice's table variant $nudge does not hold every slot once";
    }
}

$plots = Coppice::plots($ways);
$stools = 0;
$floorFerns = 0;

// And the shape of the wood the two of them agree on, which is what a visitor
// sees: no star on a stool, no floor with two ferns, no front row taller than
// its back, and every row filled from its middle outward.
foreach ($ways as $p) {
    if ($p['place'] === Coppice::STOOL) {
        $stools++;
        $checks++;
        if (!Coppice::isFern($p['habit'])) {
            $failed[] = sprintf('%s is a %s on a stool', substr($p['seed'], 0, 12), $p['habit']);
        }
    } elseif (Coppice::isFern($p['habit'])) {
        $floorFerns++;
    }
}

for ($plot = 0; $plot < $plots; $plot++) {
    for ($coupe = 0; $coupe < Coppice::COUPES; $coupe++) {
        $here = array_values(array_filter($ways, fn($p) => $p['plot'] === $plot && $p['coupe'] === $coupe));
        $at = fn(int $place) => array_values(array_filter($here, fn($p) => $p['place'] === $place));

        $checks++;
        $ferns = array_filter($here, fn($p) => $p['place'] !== Coppice::STOOL && Coppice::isFern($p['habit']));
        if (count($ferns) > 1) {
            $failed[] = sprintf('plot %d coupe %d has %d ferns on its floor', $plot, $coupe, count($ferns));
        }

        $checks++;
        $back = array_map(fn($p) => $p['height'], $at(Coppice::BACK));
        $front = array_map(fn($p) => $p['height'], $at(Coppice::FRONT));
        if ($back !== [] && $front !== [] && max($front) > min($back)) {
            $failed[] = sprintf('plot %d coupe %d stands out of order', $plot, $coupe);
        }

        foreach ([Coppice::STOOL => Coppice::STOOL_ORDER, Coppice::BACK => Coppice::FLOOR_ORDER,
                  Coppice::FRONT => Coppice::FLOOR_ORDER] as $place => $order) {
            $checks++;
            $taken = array_map(fn($p) => $p['index'], $at($place));
            sort($taken);
            $want = array_slice($order, 0, count($taken));
            sort($want);
            if ($taken !== $want) {
                $failed[] = sprintf('plot %d coupe %d place %d holds %s, not from the middle',
                    $plot, $coupe, $place, implode(' ', $taken));
            }
        }
    }
}

// The rotation: a coupe's stage is the Swift's arithmetic, year on year, and
// the year turns on 21 December UTC.
foreach ([[0, 0, 0, Coppice::CUT], [0, 1, 0, Coppice::GROWN], [0, 2, 0, Coppice::REGROWING],
          [1, 0, 0, Coppice::CUT], [0, 1, 1, Coppice::CUT], [0, 0, 1, Coppice::REGROWING],
          [3, 2, -4, Coppice::CUT], [3, 2, -3, Coppice::REGROWING]] as [$plot, $coupe, $year, $stage]) {
    $checks++;
    if (Coppice::stage($plot, $coupe, $year) !== $stage) {
        $failed[] = sprintf('plot %d coupe %d in year %d is at stage %d, not %d',
            $plot, $coupe, $year, Coppice::stage($plot, $coupe, $year), $stage);
    }
}
foreach ([['2026-09-24 12:00', 0], ['2026-12-20 23:59', 0], ['2026-12-21 00:00', 1],
          ['2027-01-01 00:00', 1], ['2027-12-21 00:00', 2]] as [$when, $year]) {
    $checks++;
    $at = (new DateTimeImmutable($when, new DateTimeZone('UTC')))->getTimestamp();
    if (Coppice::yearOn($at) !== $year) {
        $failed[] = sprintf('%s UTC is year %d, not %d', $when, Coppice::yearOn($at), $year);
    }
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about the Coppice:\n");
    foreach ($failed as $line) fwrite(STDERR, "  $line\n");
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter CoppiceVectorTests, or fix Server/.api/Coppice.php to match it.\n");
    exit(1);
}

printf("The PHP places all %d arrivals where the Swift does, across %d plots, "
     . "%d ferns on stools and %d on the floor: %d checks.\n",
    count($vectors), $plots, $stools, $floorFerns, $checks);

// **Taking back keeps the place and erases the plant**, and moves nothing that
// arrives after it. `taking_back.php` says how that is checked.
require_once __DIR__ . '/taking_back.php';
takingBack('renewal', $vectors);
