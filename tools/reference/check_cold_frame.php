<?php
declare(strict_types=1);

/**
 * The plot service places Cold Frame arrivals where SeedCore does.
 *
 * `tools/reference/cold_frame_vectors.json` is what `ColdFrame.Ways` in
 * SeedCore does with five hundred real crossings, starting from a Cold Frame
 * that already has its ambassador standing in the front rank of the first
 * frame. This replays the same five hundred through `Server/.api/ColdFrame.php`
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
    $same = $got['plot'] === $want['plot']
        && $got['frame'] === $want['frame']
        && $got['rank'] === $want['rank']
        && $got['index'] === $want['index']
        && $got['span'] === $want['span']
        && $got['nudgeX'] === $want['nudge'][0]
        && $got['nudgeZ'] === $want['nudge'][1];
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

// And the shape of the place the two of them agree on, which is what a visitor
// sees: every plant inside its own frame, a colour to a frame, each rank filled
// from its west end, nothing in a front rank taller than anything behind it,
// and no older plot passed over.
foreach ($ways as $p) {
    $checks++;
    [$cx, $cz] = ColdFrame::centre($p['frame']);
    [$x, $z] = ColdFrame::spot($p['frame'], $p['rank'], $p['index'], $p['span']);
    $atX = $x + $p['nudgeX'];
    $atZ = $z + $p['nudgeZ'];
    if (abs($atX - $cx) >= ColdFrame::FRAME_LENGTH / 2 || abs($atZ - $cz) >= ColdFrame::FRAME_DEPTH / 2) {
        $failed[] = sprintf('%s stands at %.2f, %.2f — outside frame %d',
            substr($p['seed'], 0, 12), $atX, $atZ, $p['frame']);
    }
    // The back rank is the one further from the eye, in every frame. Said here
    // because it is the whole of why the tallest stand under the higher glass.
    $checks++;
    if (($p['rank'] === ColdFrame::BACK) !== ($z < $cz)) {
        $failed[] = sprintf('%s is in rank %d and stands on the wrong side of frame %d',
            substr($p['seed'], 0, 12), $p['rank'], $p['frame']);
    }
    if ($p['rank'] === ColdFrame::rank($p['height'])) $ownRank++;
    // A lotus holds two places and nothing else holds more than one: the span
    // is the habit's, and read off nothing else.
    $checks++;
    if ($p['span'] !== ColdFrame::span($p['habit'])) {
        $failed[] = sprintf('%s is a %s and holds %d places', substr($p['seed'], 0, 12), $p['habit'], $p['span']);
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

        // One colour to a frame, which is what makes four frames read as four.
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

    // **An unclaimed frame is never passed over.** A plant that cannot join a
    // frame of its own colour claims a fresh one in the oldest plot that has
    // one, so an older plot holding an unclaimed frame while a newer plot holds
    // anything at all is the rule having skipped a place it should have taken.
    if ($plot < $plots - 1) {
        $unclaimed = array_values(array_filter(ColdFrame::FRAMES,
            fn($frame) => ColdFrame::familyOf($here, $frame) === null));
        $checks++;
        if ($unclaimed !== []) {
            $failed[] = sprintf('plot %d left frame %s unclaimed although plot %d was opened',
                $plot, implode(' ', $unclaimed), $plot + 1);
        }
    }

    // A plot opens in its first frame, the back row's west one, which is what
    // makes the ambassador the oldest plant of plot 0 without anything
    // reserving a place for it.
    $checks++;
    if (($here[0]['frame'] ?? -1) !== ColdFrame::BACK_WEST) {
        $failed[] = "plot $plot did not open in its first frame";
    }
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about the Cold Frame:\n");
    foreach ($failed as $line) fwrite(STDERR, "  $line\n");
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter ColdFrameVectorTests, or fix Server/.api/ColdFrame.php to match it.\n");
    exit(1);
}

printf("The PHP places all %d arrivals where the Swift does, across %d plots, "
     . "%d frames claimed and %d of them full, %d of %d plants in their own rank, "
     . "%d lotuses across two places: %d checks.\n",
    count($vectors), $plots, $claimed, $full, $ownRank, count($ways), $lotuses, $checks);

// **Taking back keeps the place and erases the plant**, and moves nothing that
// arrives after it. `taking_back.php` says how that is checked.
require_once __DIR__ . '/taking_back.php';
takingBack('waiting', $vectors);
