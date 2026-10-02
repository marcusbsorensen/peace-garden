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
 * **The habit and the span since 25 September 2026**, when a lotus began to take
 * two places: a word and a count, compared exactly like the rest.
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
    $got = Seedbed::plant($ways, $want['seed'], $want['height'], $want['family'], $want['kind'],
                          $want['habit']);
    $ways[] = $got;
    $checks++;
    // **The plot's variant and where the plant stands**, since the drills came
    // from a table on 2 October 2026: a table's place, a mirror and a nudge,
    // all exact, so compared with no tolerance like the rest.
    $variant = Seedbed::variant($got['plot']);
    $spot = Seedbed::spot($got['plot'], $got['drill'], $got['index'], $got['span'], $got['nudgeX'], $got['nudgeZ']);
    $same = $got['plot'] === $want['plot']
        && $got['drill'] === $want['drill']
        && $got['index'] === $want['index']
        && $got['span'] === $want['span']
        && $got['nudgeX'] === $want['nudge'][0]
        && $got['nudgeZ'] === $want['nudge'][1]
        && [$variant['turn'], $variant['mirror'] ? 1 : 0, $variant['nudge']] === $want['variant']
        && $spot === [(float) $want['spot'][0], (float) $want['spot'][1]];
    if (!$same) {
        $failed[] = sprintf(
            'arrival %d (%s, %s, %s): SeedCore put it in plot %d drill %d place %d holding %d at %.17g, %.17g, '
                . 'the service in plot %d drill %d place %d holding %d at %.17g, %.17g',
            $n, substr($want['seed'], 0, 12), $want['kind'], $want['habit'],
            $want['plot'], $want['drill'], $want['index'], $want['span'], $want['spot'][0], $want['spot'][1],
            $got['plot'], $got['drill'], $got['index'], $got['span'], $spot[0], $spot[1]
        );
        if (count($failed) >= 5) break;
    }
}

$plots = Seedbed::plots($ways);
$claimed = 0;
$full = 0;
$flooded = 0;
$lotuses = 0;

// And the shape of the place the two of them agree on, which is what a visitor
// sees: a kind to a drill, every drill sown in its own order with nothing
// skipped, the dry drills claimed from the head of the bed and the water from
// its foot, no older plot passed over, and every plant inside the bed.
foreach ($ways as $p) {
    $checks++;
    [$atX, $atZ] = Seedbed::spot($p['plot'], $p['drill'], $p['index'], $p['span'], $p['nudgeX'], $p['nudgeZ']);
    // Half the plot, less the half-metre path a gardener kneels in. A seedbed
    // that reached the rim would be a bed nobody could sow.
    $edge = Seedbed::PLOT_SIDE / 2 - 0.5;
    if (abs($atX) >= $edge || abs($atZ) >= $edge) {
        $failed[] = sprintf('%s stands at %.2f, %.2f — outside the bed',
            substr($p['seed'], 0, 12), $atX, $atZ);
    }
    // A lotus holds two places and nothing else more than one.
    $checks++;
    if ($p['span'] !== Seedbed::span($p['habit'])) {
        $failed[] = sprintf('%s is a %s and holds %d places', substr($p['seed'], 0, 12), $p['habit'], $p['span']);
    }
    if ($p['span'] === 2) $lotuses++;
}

for ($plot = 0; $plot < $plots; $plot++) {
    $here = array_values(array_filter($ways, fn($p) => $p['plot'] === $plot));
    for ($drill = 0; $drill < Seedbed::DRILLS; $drill++) {
        $block = array_values(array_filter($here, fn($p) => $p['drill'] === $drill));
        if ($block === []) continue;
        $claimed++;
        if (Seedbed::sown($block, $drill) === Seedbed::PLACES) $full++;

        // One kind to a drill, which is the whole of what a seedbed is for.
        $checks++;
        $kinds = array_values(array_unique(array_map(fn($p) => (string) $p['kind'], $block)));
        if (count($kinds) > 1) {
            $failed[] = sprintf('plot %d drill %d holds %s', $plot, $drill, implode(' ', $kinds));
        }

        // **And one element: a drill is dry or it is under water.** An
        // epithet says what is most so about a plant rather than what it is,
        // so one kind can arrive as a lily and as a fern; they take a drill
        // each. A half-flooded drill is not a thing a nursery has, and a port
        // that read only the kind would make one at the first shared epithet.
        $checks++;
        $elements = array_values(array_unique(array_map(
            fn($p) => Seedbed::wantsWater((string) ($p['habit'] ?? '')) ? 1 : 0, $block)));
        if (count($elements) > 1) {
            $failed[] = sprintf('plot %d drill %d is half flooded', $plot, $drill);
        }
        $checks++;
        if (Seedbed::isWater($here, $drill) !== ($elements[0] === 1)) {
            $failed[] = sprintf('plot %d drill %d reads as the wrong element', $plot, $drill);
        }
        if ($elements[0] === 1) $flooded++;

        // And it is sown in its own order, since 2 October 2026, with nothing
        // skipped: a dry drill's places are the first of the table's order for
        // it, and a flooded drill's touched pairs the first of its pairs. A gap
        // would be a place nobody can explain. A lotus's two places are both in
        // it, one pair, and a place held twice would be a lotus's second given
        // away.
        $checks++;
        $taken = [];
        foreach ($block as $p) {
            for ($i = 0; $i < $p['span']; $i++) $taken[] = (int) $p['index'] + $i;
            if ($p['span'] === 2 && $p['index'] % 2 !== 0) {
                $failed[] = sprintf('plot %d drill %d: a lotus holds two places of different pairs', $plot, $drill);
            }
        }
        sort($taken);
        if (count($taken) !== count(array_unique($taken))) {
            $failed[] = sprintf('plot %d drill %d holds a place twice: %s', $plot, $drill, implode(' ', $taken));
        }
        if ($elements[0] === 1) {
            $pairs = [];
            foreach (Seedbed::wetOrder($drill) as $index) {
                if (!in_array(intdiv($index, 2), $pairs, true)) $pairs[] = intdiv($index, 2);
            }
            $touched = array_values(array_unique(array_map(fn($i) => intdiv($i, 2), $taken)));
            sort($touched);
            $first = array_slice($pairs, 0, count($touched));
            sort($first);
            if ($touched !== $first) {
                $failed[] = sprintf('flooded plot %d drill %d is sown %s', $plot, $drill, implode(' ', $taken));
            }
        } else {
            $first = array_slice(Seedbed::dryOrder($drill), 0, count($taken));
            sort($first);
            if ($taken !== $first) {
                $failed[] = sprintf('plot %d drill %d is sown %s', $plot, $drill, implode(' ', $taken));
            }
        }
    }

    // **Each drill claimed was the first on its side of the bed**: replayed in
    // the order the plants arrived, a dry plant claimed the highest drill
    // nobody had sown and a lily or a reed the lowest, so the flooded drills
    // lie together at the foot.
    $checks++;
    $unclaimed = range(0, Seedbed::DRILLS - 1);
    foreach ($here as $p) {
        if (!in_array($p['drill'], $unclaimed, true)) continue;
        $want = Seedbed::wantsWater((string) ($p['habit'] ?? '')) ? max($unclaimed) : min($unclaimed);
        if ($p['drill'] !== $want) {
            $failed[] = sprintf('%s claimed drill %d of plot %d where drill %d was first on its side',
                substr($p['seed'], 0, 12), $p['drill'], $plot, $want);
        }
        $unclaimed = array_values(array_diff($unclaimed, [$p['drill']]));
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
     . "%d drills claimed, %d of them flooded, %d of them full, "
     . "%d lotuses across two places: %d checks.\n",
    count($vectors), $plots, $claimed, $flooded, $full, $lotuses, $checks);

// **Taking back keeps the place and erases the plant**, and moves nothing that
// arrives after it. `taking_back.php` says how that is checked.
require_once __DIR__ . '/taking_back.php';
takingBack('beginnings', $vectors);
