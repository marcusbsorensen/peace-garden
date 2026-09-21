<?php
declare(strict_types=1);

/**
 * The plot service places Orchard arrivals where SeedCore does.
 *
 * `tools/reference/orchard_vectors.json` is what `Orchard.Ways` in SeedCore does
 * with five hundred real crossings, starting from an Orchard that already has
 * its ambassador standing under the middle tree. This replays the same five
 * hundred through `Server/.api/Orchard.php` and fails if any one of them lands
 * anywhere else.
 *
 * **Why the whole five hundred rather than a sample.** This rule's answer is
 * decided by the order two loops are nested in: guild outside, rank inside. A
 * port with them the other way round — which is the Crossing's nesting, sitting
 * in the next file along — agrees about the first four plants of every plot,
 * about every plot's total, and about most placements after that. It diverges
 * only where a guild has to take a plant whose height it did not ask for, and
 * the only way to see that is to run it until the guilds are full.
 *
 *   php tools/reference/check_orchard.php
 */

require_once __DIR__ . '/../../Server/.api/Ambassadors.php';
require_once __DIR__ . '/../../Server/.api/Orchard.php';

$vectors = json_decode(
    file_get_contents(__DIR__ . '/orchard_vectors.json'), true, 512, JSON_THROW_ON_ERROR
);

$failed = [];
$checks = 0;

// The Orchard as it opened: the ambassador and nothing else, which is what the
// Swift placed these five hundred around.
$standing = Ambassadors::planting('kinship');
if ($standing === null) {
    fwrite(STDERR, "The service has no ambassador for the Orchard.\n");
    exit(1);
}
$ways = [$standing];

foreach ($vectors as $n => $want) {
    $got = Orchard::plant($ways, $want['seed'], $want['height'], $want['family']);
    $ways[] = $got;
    $checks++;
    $same = $got['plot'] === $want['plot']
        && $got['guild'] === $want['guild']
        && $got['index'] === $want['index']
        && $got['nudgeX'] === $want['nudge'][0]
        && $got['nudgeZ'] === $want['nudge'][1];
    if (!$same) {
        $failed[] = sprintf(
            'arrival %d (%s, %.3f m, colour %d): SeedCore put it in plot %d guild %d place %d, '
                . 'the service in plot %d guild %d place %d',
            $n, substr($want['seed'], 0, 12), $want['height'], $want['family'],
            $want['plot'], $want['guild'], $want['index'],
            $got['plot'], $got['guild'], $got['index']
        );
        if (count($failed) >= 5) break;
    }
}

// And the shape of the place the two of them agree on, which is what a visitor
// sees: plots full at the old end, guilds finished before the next is begun,
// nothing standing in a trunk, and nothing in front of something shorter.
$plots = Orchard::plots($ways);
$holdings = array_fill(0, $plots, 0);
foreach ($ways as $p) $holdings[$p['plot']]++;
$full = count(array_filter($holdings, fn($n) => $n === count(Orchard::slots())));

$checks++;
if ($full < $plots - 2) {
    $failed[] = sprintf('only %d of %d plots are full: %s', $full, $plots, implode(' ', $holdings));
}

foreach ($ways as $p) {
    $checks++;
    [$x, $z] = Orchard::spot($p['guild'], $p['index']);
    $atX = $x + $p['nudgeX'];
    $atZ = $z + $p['nudgeZ'];
    if (max(abs($atX), abs($atZ)) >= Orchard::PLOT_SIDE / 2) {
        $failed[] = sprintf('%s stands at %.2f, %.2f — off the plot',
            substr($p['seed'], 0, 12), $atX, $atZ);
    }
    // Nothing may stand where a trunk is. The five trees are structures and a
    // plant sharing a place with one is two things in one spot.
    foreach ([0, 1, 2, 3, 4] as $guild) {
        [$tx, $tz] = Orchard::trunk($guild);
        if (sqrt(($atX - $tx) ** 2 + ($atZ - $tz) ** 2) <= 0.3) {
            $failed[] = sprintf('%s stands at %.2f, %.2f — in the trunk of tree %d',
                substr($p['seed'], 0, 12), $atX, $atZ, $guild);
        }
    }
}

for ($plot = 0; $plot < $plots; $plot++) {
    $here = array_values(array_filter($ways, fn($p) => $p['plot'] === $plot));
    $counts = [];
    foreach ([0, 1, 2, 3, 4] as $guild) {
        $under = array_values(array_filter($here, fn($p) => $p['guild'] === $guild));
        $counts[] = count($under);
        foreach ($under as $one) {
            foreach ($under as $other) {
                $mine = Orchard::rankOf($one['guild'], $one['index']);
                $theirs = Orchard::rankOf($other['guild'], $other['index']);
                if ($mine === null || $theirs === null || $mine >= $theirs) continue;
                $checks++;
                if ($one['height'] > $other['height']) {
                    $failed[] = sprintf('plot %d guild %d: a %.2f m plant in front of a %.2f m one',
                        $plot, $guild, $one['height'], $other['height']);
                }
            }
        }
    }
    // **The rule the area is for**, stated the way the rule actually keeps it.
    //
    // *Not* "a later guild never holds more than an earlier one" — that is
    // false, and asserting it was this check's own first bug. A guild's last
    // place carries the tightest constraint in the plot, so a guild can sit at
    // three while the next fills to four, waiting for a plant tall enough for
    // its crown. Counts of 4 4 4 3 4 are correct behaviour.
    //
    // What is guaranteed is two things. **An occupied guild is never preceded
    // by an empty one**: an empty guild refuses nobody, because `inOrder` has
    // nothing to compare against, so a plant can only reach guild n by being
    // refused places in guilds that already hold something. And **a free place
    // in an earlier guild is one that no plant in a later guild of the same
    // plot could have stood in** — otherwise that plant would have taken it,
    // since `place` reaches the earlier guild first.
    //
    // The second is sound against the final state rather than a replay because
    // `inOrder` only ever gets stricter as a guild fills: if the finished guild
    // would accept a plant, the part-filled guild it passed through would have
    // too.
    $started = -1;
    foreach ($counts as $g => $n) if ($n > 0) $started = $g;
    for ($g = 0; $g <= $started; $g++) {
        $checks++;
        if ($counts[$g] === 0) {
            $failed[] = sprintf('plot %d guilds hold %s — guild %d was skipped',
                $plot, implode(' ', $counts), $g);
        }
    }
    $taken = [];
    foreach ($here as $p) $taken[$p['guild'] . ':' . $p['index']] = true;
    for ($g = 0; $g < $started; $g++) {
        $under = array_values(array_filter($here, fn($p) => $p['guild'] === $g));
        foreach (Orchard::slots() as $slot) {
            if ($slot['guild'] !== $g) continue;
            if (isset($taken[$g . ':' . $slot['index']])) continue;
            foreach ($here as $later) {
                if ($later['guild'] <= $g) continue;
                $rank = Orchard::rankOf($slot['guild'], $slot['index']);
                if ($rank !== null
                    && !in_array($rank, Orchard::ranksBeside(Orchard::rank($later['height'])), true)) {
                    continue;
                }
                $checks++;
                if (Orchard::inOrderForCheck($under, $later['height'], $g, $slot['index'])) {
                    $failed[] = sprintf(
                        'plot %d guild %d place %d is free, but a %.2f m plant went to guild %d '
                            . 'and could have stood there',
                        $plot, $g, $slot['index'], $later['height'], $later['guild']);
                    break 2;
                }
            }
        }
    }
    // A plot opens under its middle tree, which is what makes the ambassador the
    // oldest plant of plot 0 without anything reserving a place for it.
    $checks++;
    if (($here[0]['guild'] ?? -1) !== Orchard::MIDDLE) {
        $failed[] = "plot $plot did not open under its middle tree";
    }
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about the Orchard:\n");
    foreach ($failed as $line) fwrite(STDERR, "  $line\n");
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter OrchardVectorTests, or fix Server/.api/Orchard.php to match it.\n");
    exit(1);
}

printf("The PHP places all %d arrivals where the Swift does, across %d plots, %d of them full: %d checks.\n",
    count($vectors), $plots, $full, $checks);
