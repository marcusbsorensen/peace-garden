<?php
declare(strict_types=1);

/**
 * The plot service places Cold Frame arrivals where SeedCore does.
 *
 * `tools/reference/cold_frame_vectors.json` is what `ColdFrame.Ways` in
 * SeedCore does with five hundred real crossings, starting from a Cold Frame
 * that already has its ambassador, a lily, in the water. This replays the same five hundred through `Server/.api/ColdFrame.php`
 * and fails if any one of them lands anywhere else.
 *
 * **Why the whole five hundred rather than a sample.** The rule has two
 * fallbacks that agree with the plain answer for a long while: a plant whose
 * own rank is full, or would stand out of order, goes to the other rank of the
 * same frame; and a colour whose frames are all full or out of order claims a
 * fresh frame in the oldest plot that has one. A port that never tried the
 * other rank diverges forty arrivals in; one that tried every frame's own rank
 * before any frame's other rank agrees for the first two hundred and diverges
 * in plot 4. Both were tried against this file before it was committed.
 *
 * **Compared exactly.** Plot, frame, rank and place are integers and the nudge
 * is two bytes of the seed divided by 255, so all of it is exact on every host.
 * The heights are compared with the cut and with each other, which is where a
 * host could round differently; the Swift's own vector test checked none of the
 * five hundred stands close enough to 0.85 m, or to another plant in its frame,
 * for that to matter.
 *
 * **The habit and the span since 25 September 2026**, when a lotus began to take
 * two places. Both exact, and compared exactly: a port that gave a lotus one
 * place, or gave its second to the next plant, is caught at the first lotus
 * that is not last in its rank.
 *
 * **The tank since 27 September 2026.** Frame 4 is water and is checked as
 * water: a place in it is measured against the tank's own rectangle, it has no
 * ranks to be on the wrong side of, and every plant in it holds one place. The
 * two rules that make the water worth having are here rather than in the
 * geometry — **everything that wants water is in it and nothing else is**, and
 * **a plot's tank is full before the next plot's is used** — because a port
 * that let a lily fall back to a frame, or that opened a pond per lily, would
 * place every one of the five hundred somewhere plausible and be wrong.
 *
 * **Two frames and a bigger tank since 29 September 2026** (Marcus): nothing is
 * placed in the retired front row, frames 2 and 3, and the water and the glass
 * are asked to fill in step — a plot opened by the water with nothing under its
 * glass, while an older plot's frames hold everything dry, is the fault the
 * bigger tank was for, so the plots with anything under glass are counted.
 *
 * **A pond since 2 October 2026**, with the tank's thirty-nine places: every
 * place in the water is inside the pond's outline, a reed takes the open water
 * only once the margin is full and a lily the margin only once the open water
 * is, and every plant's variant and spot, mirrored for its plot, are the
 * Swift's to the bit.
 *
 *   php tools/reference/check_cold_frame.php
 */

require_once __DIR__ . '/../../Server/.api/Ambassadors.php';
require_once __DIR__ . '/../../Server/.api/ColdFrame.php';

$vectors = json_decode(
    file_get_contents(__DIR__ . '/cold_frame_vectors.json'), true, 512, JSON_THROW_ON_ERROR
);

$failed = [];
$checks = 0;

// The Cold Frame as it opened: the ambassador and nothing else, which is what
// the Swift placed these five hundred around — and which has already claimed
// the first frame for its own colour.
$standing = Ambassadors::planting('waiting');
if ($standing === null) {
    fwrite(STDERR, "The service has no ambassador for the Cold Frame.\n");
    exit(1);
}
$ways = [$standing];

foreach ($vectors as $n => $want) {
    $got = ColdFrame::plant($ways, $want['seed'], $want['height'], $want['family'], $want['habit']);
    $ways[] = $got;
    $checks++;
    $variant = ColdFrame::variant($got['plot']);
    $spot = ColdFrame::spotOn($got['plot'], $got['frame'], $got['rank'], $got['index'], $got['span'],
                              $got['nudgeX'], $got['nudgeZ']);
    $same = $got['plot'] === $want['plot']
        && $got['frame'] === $want['frame']
        && $got['rank'] === $want['rank']
        && $got['index'] === $want['index']
        && $got['span'] === $want['span']
        && $got['nudgeX'] === $want['nudge'][0]
        && $got['nudgeZ'] === $want['nudge'][1]
        && [$variant['turn'], $variant['mirror'] ? 1 : 0, $variant['nudge']] === $want['variant']
        && $spot[0] === (float) $want['spot'][0] && $spot[1] === (float) $want['spot'][1];
    if (!$same) {
        $failed[] = sprintf(
            'arrival %d (%s, %.3f m, colour %d, %s): SeedCore put it in plot %d frame %d rank %d place %d '
                . 'holding %d, the service in plot %d frame %d rank %d place %d holding %d',
            $n, substr($want['seed'], 0, 12), $want['height'], $want['family'], $want['habit'],
            $want['plot'], $want['frame'], $want['rank'], $want['index'], $want['span'],
            $got['plot'], $got['frame'], $got['rank'], $got['index'], $got['span']
        );
        if (count($failed) >= 5) break;
    }
}

$plots = ColdFrame::plots($ways);
$claimed = 0;
$full = 0;
$ownRank = 0;
$lotuses = 0;
$ponds = [];
$glazed = 0;
// The pond's outline, as the table draws it, and whether a point is in it.
$pond = ColdFramePondTable::CURVES['pond'][0][1];
$inPond = function (float $x, float $z) use ($pond): bool {
    $hit = false;
    for ($i = 0, $j = count($pond) - 1; $i < count($pond); $j = $i++) {
        [$ax, $az] = $pond[$i];
        [$bx, $bz] = $pond[$j];
        if (($az > $z) !== ($bz > $z) && $x < ($bx - $ax) * ($z - $az) / ($bz - $az) + $ax) $hit = !$hit;
    }
    return $hit;
};

// And the shape of the place the two of them agree on, which is what a visitor
// sees: every plant inside its own frame, a colour to a frame, each rank filled
// from its west end, nothing in a front rank taller than anything behind it,
// and no older plot passed over.
$dry = 0;
$inWater = 0;

foreach ($ways as $p) {
    $wet = !ColdFrame::isDry($p['frame']);
    $checks++;
    [$cx, $cz] = ColdFrame::centre($p['frame']);
    [$x, $z] = ColdFrame::spot($p['frame'], $p['rank'], $p['index'], $p['span']);
    $atX = $x + $p['nudgeX'];
    $atZ = $z + $p['nudgeZ'];
    $outside = $wet
        ? !$inPond($atX, $atZ)
        : abs($atX - $cx) >= ColdFrame::FRAME_LENGTH / 2 || abs($atZ - $cz) >= ColdFrame::FRAME_DEPTH / 2;
    if ($outside) {
        $failed[] = sprintf('%s stands at %.2f, %.2f — outside frame %d',
            substr($p['seed'], 0, 12), $atX, $atZ, $p['frame']);
    }
    // **Everything that wants water is in the pond and nothing else is.** The
    // habit is a word, the same on the phone and here, so this cannot round.
    $checks++;
    if ($wet !== ColdFrame::wantsWater($p['habit'])) {
        $failed[] = sprintf('%s is a %s and is in frame %d',
            substr($p['seed'], 0, 12), $p['habit'] === '' ? 'plant with no habit' : $p['habit'], $p['frame']);
    }
    // Nothing is placed in the retired front row.
    $checks++;
    if (!$wet && !in_array($p['frame'], ColdFrame::FRAMES, true)) {
        $failed[] = sprintf('%s is in retired frame %d', substr($p['seed'], 0, 12), $p['frame']);
    }
    if ($wet) {
        $inWater++;
        // The pond has no ranks, so nothing is ever filed in its back one.
        $checks++;
        if ($p['rank'] !== ColdFrame::FRONT) {
            $failed[] = sprintf('%s is in the pond in rank %d', substr($p['seed'], 0, 12), $p['rank']);
        }
    } else {
        $dry++;
        // The back rank is the one further from the eye, in every frame. Said
        // here because it is the whole of why the tallest stand under the
        // higher glass.
        $checks++;
        if (($p['rank'] === ColdFrame::BACK) !== ($z < $cz)) {
            $failed[] = sprintf('%s is in rank %d and stands on the wrong side of frame %d',
                substr($p['seed'], 0, 12), $p['rank'], $p['frame']);
        }
        if ($p['rank'] === ColdFrame::rank($p['height'])) $ownRank++;
    }
    // A lotus under glass holds two places and nothing else holds more than
    // one; a lily in the pond holds one, because the pond's places were
    // measured for its pads.
    $checks++;
    $want = $wet ? 1 : ColdFrame::span($p['habit']);
    if ($p['span'] !== $want) {
        $failed[] = sprintf('%s is a %s in frame %d and holds %d places, not %d',
            substr($p['seed'], 0, 12), $p['habit'], $p['frame'], $p['span'], $want);
    }
    if ($p['span'] === 2) $lotuses++;
}

for ($plot = 0; $plot < $plots; $plot++) {
    $here = array_values(array_filter($ways, fn($p) => $p['plot'] === $plot));
    foreach (ColdFrame::FRAMES as $frame) {
        $block = array_values(array_filter($here, fn($p) => $p['frame'] === $frame));
        if ($block === []) continue;
        $claimed++;
        if (array_sum(array_map(fn($p) => $p['span'], $block)) === 2 * ColdFrame::PLACES) $full++;

        // One colour to a frame, which is what makes two frames read as two.
        $checks++;
        $families = array_values(array_unique(array_map(fn($p) => (int) $p['family'], $block)));
        if (count($families) > 1) {
            $failed[] = sprintf('plot %d frame %d holds colours %s',
                $plot, $frame, implode(' ', $families));
        }

        foreach (ColdFrame::RANKS as $rank) {
            // Each rank fills from its west end: 0, 1, 2 and so on with nothing
            // missing and nothing held twice, a lotus's two places among them —
            // so the place after a lotus is never given to the plant after it.
            $checks++;
            $taken = [];
            foreach ($block as $p) {
                if ($p['rank'] !== $rank) continue;
                for ($i = 0; $i < $p['span']; $i++) $taken[] = (int) $p['index'] + $i;
            }
            sort($taken);
            if ($taken !== [] && $taken !== range(0, count($taken) - 1)) {
                $failed[] = sprintf('plot %d frame %d rank %d is filled %s',
                    $plot, $frame, $rank, implode(' ', $taken));
            }
        }

        // Nothing in the front rank taller than anything in the back. Asked of
        // the finished frame rather than of each arrival, so it catches a later
        // plant that the rule let in behind an earlier one it should not have.
        $front = array_filter($block, fn($p) => $p['rank'] === ColdFrame::FRONT);
        $back = array_filter($block, fn($p) => $p['rank'] === ColdFrame::BACK);
        foreach ($front as $low) {
            foreach ($back as $high) {
                $checks++;
                if ($low['height'] > $high['height']) {
                    $failed[] = sprintf('plot %d frame %d: a %.2f m plant in front of a %.2f m one',
                        $plot, $frame, $low['height'], $high['height']);
                }
            }
        }
    }

    // **A reed takes the margin and a lily the open water**, each the other's
    // only once its own is full, and no place in the pond is held twice.
    $water = array_values(array_filter($here, fn($p) => !ColdFrame::isDry($p['frame'])));
    $checks++;
    $taken = array_map(fn($p) => (int) $p['index'], $water);
    if (count(array_unique($taken)) !== count($taken)) {
        $failed[] = sprintf('plot %d\'s pond holds a place twice: %s', $plot, implode(' ', $taken));
    }
    $kind = fn(int $index) => ColdFramePondTable::PLACES[0][$index][2];
    $held = fn(int $kindOf) => count(array_filter($taken, fn($i) => $kind($i) === $kindOf));
    $places = fn(int $kindOf) => count(array_filter(ColdFramePondTable::PLACES[0], fn($q) => $q[2] === $kindOf));
    foreach ($water as $p) {
        $mine = $p['habit'] === 'reed' ? ColdFrame::MARGIN : ColdFrame::OPEN;
        if ($kind((int) $p['index']) === $mine) continue;
        $checks++;
        // Asked of the plot as it ended: its own water has to be full now.
        if ($held($mine) < $places($mine)) {
            $failed[] = sprintf('plot %d: a %s is out of its own water while there is room in it',
                $plot, $p['habit']);
        }
    }
    $ponds[$plot] = count($water);
    if (count($water) < count($here)) $glazed++;

    // **An unclaimed frame is never passed over.** A plant that cannot join a
    // frame of its own colour claims a fresh one in the oldest plot that has
    // one, so an older plot holding an unclaimed frame while a newer plot holds
    // a plant under glass is the rule having skipped a place it should have
    // taken. Since 27 September a plot can also be opened by a lily finding
    // every pond full, which claims no frame at all — so the newer plot has to
    // hold something dry for this to mean anything.
    if ($plot < $plots - 1) {
        $laterDry = array_filter($ways,
            fn($p) => (int) $p['plot'] > $plot && ColdFrame::isDry($p['frame']));
        $unclaimed = array_values(array_filter(ColdFrame::FRAMES,
            fn($frame) => ColdFrame::familyOf($here, $frame) === null));
        $checks++;
        if ($unclaimed !== [] && $laterDry !== []) {
            $failed[] = sprintf('plot %d left frame %s unclaimed although a later plot was planted under glass',
                $plot, implode(' ', $unclaimed));
        }
    }

    // A plot's frames open in the first of them, the back row's west one. Said
    // of the first plant under glass rather than the first plant, because a
    // plot now usually opens with a lily in the water and claims no frame
    // until something dry arrives.
    $checks++;
    $firstDry = array_values(array_filter($here, fn($p) => ColdFrame::isDry($p['frame'])));
    if ($firstDry !== [] && $firstDry[0]['frame'] !== ColdFrame::BACK_WEST) {
        $failed[] = "plot $plot did not open its frames in the first one";
    }
}

// **A plot's water is full before the next plot's is used**, which is what
// keeps the area from being a row of half-empty ponds: a lily or a reed takes
// a free place in the oldest pond, so at most one pond is part full and every
// pond after it is empty.
$short = null;
foreach ($ponds as $plot => $count) {
    $checks++;
    if ($short !== null && $count !== 0) {
        $failed[] = sprintf('plot %d\'s pond was used although plot %d\'s holds only %d',
            $plot, $short, $ponds[$short]);
    }
    if ($short === null && $count < ColdFrame::POND_PLACES) $short = $plot;
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about the Cold Frame:\n");
    foreach ($failed as $line) fwrite(STDERR, "  $line\n");
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter ColdFrameVectorTests, or fix Server/.api/ColdFrame.php to match it.\n");
    exit(1);
}

printf("The PHP places all %d arrivals where the Swift does, across %d plots, %d with plants under glass, "
     . "%d frames claimed and %d of them full, %d of %d plants under glass in their own rank, "
     . "%d in the water, %d lotuses across two places: %d checks.\n",
    count($vectors), $plots, $glazed, $claimed, $full, $ownRank, $dry, $inWater, $lotuses, $checks);

// **Taking back keeps the place and erases the plant**, and moves nothing that
// arrives after it. `taking_back.php` says how that is checked.
require_once __DIR__ . '/taking_back.php';
takingBack('waiting', $vectors);
