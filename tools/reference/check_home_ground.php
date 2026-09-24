<?php
declare(strict_types=1);

/**
 * The plot service places Home Ground arrivals where SeedCore does.
 *
 * `tools/reference/home_ground_vectors.json` is what `HomeGround.Ways` in
 * SeedCore does with five hundred real crossings, starting from a Home Ground
 * that already has its ambassador standing at the north end of the west bed.
 * This replays the same five hundred through `Server/.api/HomeGround.php` and
 * fails if any one of them lands anywhere else.
 *
 * **Why the whole five hundred rather than a sample.** The rule's steps agree
 * with each other for a long while: a bed of the plant's crop, then an unsown
 * bed, then a new plot. A port that claimed a bed for the latest plant sown in
 * it rather than the first, or took the first unsown bed across plots before
 * looking for a bed of the crop, would agree until the first plot filled.
 *
 * **Compared exactly.** Plot, bed and index are integers, the crop and the habit
 * are words, and the nudge is two bytes of the seed divided by 255. A height is
 * compared only with its crop's cut, and the Swift's own vector test checked
 * that none of the five hundred stands close enough to one for a host's rounding
 * to matter.
 *
 *   php tools/reference/check_home_ground.php
 */

require_once __DIR__ . '/../../Server/.api/Ambassadors.php';
require_once __DIR__ . '/../../Server/.api/HomeGround.php';

$vectors = json_decode(
    file_get_contents(__DIR__ . '/home_ground_vectors.json'), true, 512, JSON_THROW_ON_ERROR
);

$failed = [];
$checks = 0;

$standing = Ambassadors::planting('ground');
if ($standing === null) {
    fwrite(STDERR, "The service has no ambassador for the Home Ground.\n");
    exit(1);
}
$checks++;
if ([$standing['plot'], $standing['bed'], $standing['crop'], $standing['index']] !== [0, 0, 'Fen', 0]) {
    $failed[] = sprintf('the ambassador stands in plot %d bed %d (%s) place %d, not at the head of the garden',
        $standing['plot'], $standing['bed'], $standing['crop'], $standing['index']);
}
$ways = [$standing];

foreach ($vectors as $n => $want) {
    $got = HomeGround::plant($ways, $want['seed'], $want['height'], $want['family'], $want['habit']);
    $ways[] = $got;
    $checks++;
    $same = $got['plot'] === $want['plot']
        && $got['bed'] === $want['bed']
        && $got['crop'] === $want['crop']
        && $got['index'] === $want['index']
        && $got['nudgeX'] === $want['nudge'][0]
        && $got['nudgeZ'] === $want['nudge'][1];
    if (!$same) {
        $failed[] = sprintf(
            'arrival %d (%s, a %s of %.3f m): SeedCore put it in plot %d bed %d (%s) index %d, '
                . 'the service in plot %d bed %d (%s) index %d',
            $n, substr($want['seed'], 0, 12), $want['habit'], $want['height'],
            $want['plot'], $want['bed'], $want['crop'], $want['index'],
            $got['plot'], $got['bed'], $got['crop'], $got['index']
        );
        if (count($failed) >= 5) break;
    }
}

$plots = HomeGround::plots($ways);
$beds = 0;

// And the shape of the garden the two of them agree on, which is what a visitor
// sees: one crop to a bed, every plant in its own crop's bed, and in every bed
// the north end at least as tall as the south, each end a run from its own end.
for ($plot = 0; $plot < $plots; $plot++) {
    for ($bed = 0; $bed < HomeGround::BEDS; $bed++) {
        $here = array_values(array_filter($ways, fn($p) => $p['plot'] === $plot && $p['bed'] === $bed));
        if ($here === []) continue;
        $beds++;

        $checks++;
        $crops = array_unique(array_map(fn($p) => $p['crop'], $here));
        if (count($crops) !== 1) {
            $failed[] = sprintf('plot %d bed %d holds %s', $plot, $bed, implode(' and ', $crops));
            continue;
        }
        $crop = $crops[0];
        foreach ($here as $p) {
            $checks++;
            if (HomeGround::crop($p['habit']) !== $crop) {
                $failed[] = sprintf('%s, a %s, stands in a bed of %s', substr($p['seed'], 0, 12), $p['habit'], $crop);
            }
        }

        $checks++;
        $north = array_values(array_filter($here, fn($p) => HomeGround::north($crop, $p['height'])));
        $south = array_values(array_filter($here, fn($p) => !HomeGround::north($crop, $p['height'])));
        $tall = array_map(fn($p) => $p['height'], $north);
        $short = array_map(fn($p) => $p['height'], $south);
        if ($tall !== [] && $short !== [] && min($tall) < max($short)) {
            $failed[] = sprintf('plot %d bed %d stands a short plant north of a tall one', $plot, $bed);
        }

        $checks++;
        $capacity = HomeGround::capacity($crop);
        $fromNorth = array_map(fn($p) => $p['index'], $north);
        $fromSouth = array_map(fn($p) => $p['index'], $south);
        sort($fromNorth);
        sort($fromSouth);
        if ($fromNorth !== range(0, count($north) - 1) && $north !== []
            || $south !== [] && $fromSouth !== range($capacity - count($south), $capacity - 1)) {
            $failed[] = sprintf('plot %d bed %d did not fill from its two ends', $plot, $bed);
        }
    }
}

// The spacing: every crop's rows span the same 3.6 m, centred down the bed.
foreach (HomeGround::CROPS as $crop => $s) {
    $checks++;
    [, $zFirst] = HomeGround::spot(1, $crop, 0);
    [, $zLast] = HomeGround::spot(1, $crop, HomeGround::capacity($crop) - 1);
    if (abs($zFirst + 1.8) > 1e-9 || abs($zLast - 1.8) > 1e-9) {
        $failed[] = sprintf('a bed of %s runs from %.3f to %.3f, not -1.8 to 1.8', $crop, $zFirst, $zLast);
    }
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about the Home Ground:\n");
    foreach ($failed as $line) fwrite(STDERR, "  $line\n");
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter HomeGroundVectorTests, or fix Server/.api/HomeGround.php to match it.\n");
    exit(1);
}

printf("The PHP places all %d arrivals where the Swift does, across %d plots and %d beds: %d checks.\n",
    count($vectors), $plots, $beds, $checks);

// **Taking back keeps the place and erases the plant**, and moves nothing that
// arrives after it. `taking_back.php` says how that is checked.
require_once __DIR__ . '/taking_back.php';
takingBack('ground', $vectors);
