<?php
declare(strict_types=1);

require_once __DIR__ . '/PlotVariant.php';
require_once __DIR__ . '/tables/SeedbedDrillsTable.php';

/**
 * The Seedbed's placement rule, ported from SeedCore's `WebGardens/Seedbed.swift`
 * so the plot service can run it.
 *
 * **A port, and held to the Swift.** The server is PHP and cannot run SeedCore,
 * so this is a second copy of the rule, and a copy drifts unless something
 * checks it: `tools/reference/check_seedbed.php` plants the arrivals pinned in
 * `tools/reference/seedbed_vectors.json` and fails CI if this puts any of them
 * anywhere else. Change the Swift first, re-record, then bring this along.
 *
 * **The first rule in the garden that groups by sameness.** The five areas
 * before it all sort by difference — the Long Walk grades a border by height,
 * the Quiet Garden reads a group of three, the Crossing ranks a quarter, the
 * Orchard stands its tallest in the middle, the Knot Garden claims a pair by
 * colour and then grades by height. Every one of them asks *how does this plant
 * differ from that one*. A seedbed asks the opposite question, which is the
 * question a nursery row is for: *what is this the same as?*
 *
 * **A kind is the epithet, not the whole name.** Across five hundred crossings
 * 490 binomials are unique and the genus is nearly as rare — the commonest
 * stands five times — so a drill claimed by either would hold one plant and wait
 * forever. The epithet repeats: 46 of them over those five hundred, *rubra*
 * thirty times. It is also the truer reading, because an epithet is chosen to
 * say the one thing that is most so about a plant, where a genus is inherited. A
 * drill of *contorta* is a drill of plants that are actually alike.
 *
 * **Neither a height nor a colour is read here, and this is the first area where
 * neither decides anything.** A drill comes from the kind and a place in it from
 * the order of arrival, so nothing in this file compares a number that a host's
 * arithmetic could round differently — which is why the check can compare every
 * placement exactly rather than near a cut. Both are carried through `plant`
 * because they are stored with a planting and drawn, not because anything here
 * asks them a question.
 *
 * **A lotus takes two places**, since 25 September 2026: a pair of its drill,
 * standing centred across them (`span`). The habit is read for it — a word,
 * exact on every host like the kind, so the placement still needs no
 * tolerance — and only the arriving plant's; a plant already standing says how
 * many places it holds by its span, which is stored with it.
 *
 * **Drills on the contour, since 2 October 2026**: six arcs from a table made
 * offline (`tables/SeedbedDrillsTable.php`), a dry kind claiming the highest
 * drill nobody has sown and a water kind the lowest, each drill sown from its
 * middle, and every other plot mirrored (`VARIANTS`). The Swift says why.
 *
 * A planting here is an array: seed (hex), plot, drill (0-5), index (0-7, the
 * one nearer the label of a lotus's two), span (1, or 2 for a lotus), height,
 * family, kind, habit, nudgeX, nudgeZ. A planting with no span holds one place,
 * which is what every planting made before the lotus rule holds.
 */
final class Seedbed
{
    /**
     * The same square as every other area, so the map, the camera and the ground
     * are one piece of work rather than six.
     */
    public const PLOT_SIDE = 5.2;

    /**
     * How this area's plots vary, from each plot's number (`PlotVariant.php`):
     * the Swift's `variants`. Mirrored only, so a plot is laid as drawn or
     * mirrored across the bed, alternately: the water stays on the low side and
     * the labels change ends.
     */
    public const VARIANTS = ['turns' => 1, 'mirror' => true, 'nudges' => 1];

    /**
     * Six drills of eight, chosen by Marcus from three offers on 23 September.
     * Forty-eight is the Long Walk's number; at this plot it left 0.74 m
     * between drills, which is the width of the space a gardener kneels in,
     * until the drills curved more on 2 October 2026: 0.60 m since, from the
     * table (`SeedbedDrillsTable`).
     */
    public const DRILLS = 6;
    public const PLACES = 8;

    /** The area's name, which its plots' variants are dealt from. */
    public const AREA = 'beginnings';

    /**
     * Where each place stands in the table, before its plot is mirrored:
     * `[drill][index] => [x, z]`.
     */
    public static function at(int $drill, int $index): array
    {
        static $at = null;
        if ($at === null) {
            $at = [];
            foreach (SeedbedDrillsTable::PLACES[0] as [$x, $z, $d, $i]) $at[$d][$i] = [$x, $z];
        }
        return $at[$drill][$index];
    }

    /**
     * **The order a dry drill is sown in**: each drill's places as the table
     * lists them, the one nearest its middle first and then farthest-first.
     */
    public static function dryOrder(int $drill): array
    {
        static $order = null;
        if ($order === null) {
            $order = array_fill(0, self::DRILLS, []);
            foreach (SeedbedDrillsTable::PLACES[0] as [, , $d, $i]) $order[$d][] = $i;
        }
        return $order[$drill];
    }

    /**
     * **The order a flooded drill is sown in**: by the table's `pair` rank, and
     * within a pair the place nearer the label first. A lily takes a whole
     * pair and a reed the first free place.
     */
    public static function wetOrder(int $drill): array
    {
        static $order = null;
        if ($order === null) {
            $byDrill = array_fill(0, self::DRILLS, []);
            foreach (SeedbedDrillsTable::PLACES[0] as [, , $d, $i, $pair]) $byDrill[$d][] = [$pair, $i];
            $order = [];
            foreach ($byDrill as $d => $places) {
                usort($places, fn($a, $b) => $a[0] <=> $b[0] ?: $a[1] <=> $b[1]);
                $order[$d] = array_map(fn($p) => $p[1], $places);
            }
        }
        return $order[$drill];
    }

    /** Which drills a plant claims first: a dry plant the highest, a water plant the lowest. */
    public static function claimOrder(bool $wet): array
    {
        $drills = range(0, self::DRILLS - 1);
        return $wet ? array_reverse($drills) : $drills;
    }

    /** The variant a plot is laid with: plain, then mirrored, alternately. */
    public static function variant(int $plot): array
    {
        return PlotVariant::of($plot, self::AREA, self::VARIANTS);
    }

    /**
     * Where a plant holding `span` places from `index` of `drill` stands in
     * plot `plot`, with its nudge, in metres from the middle of its plot:
     * [x, z]. The middle of its places, so a lotus stands half a place further
     * from the label than its first; then nudged along and across its drill
     * where it stands (`along`), then mirrored as its plot is, in the Swift's
     * order, so every spot is the same double.
     */
    public static function spot(int $plot, int $drill, int $index, int $span = 1,
                                float $nudgeX = 0.0, float $nudgeZ = 0.0): array
    {
        [$x, $z] = self::at($drill, $index);
        if ($span === 2 && $index + 1 < self::PLACES) {
            [$bx, $bz] = self::at($drill, $index + 1);
            $x = ($x + $bx) / 2;
            $z = ($z + $bz) / 2;
        }
        [$ax, $az] = self::along($drill, $index, $span);
        $x = $x + ($nudgeX * $ax - $nudgeZ * $az);
        $z = $z + ($nudgeX * $az + $nudgeZ * $ax);
        return PlotVariant::apply(self::variant($plot), $x, $z);
    }

    /**
     * **Which way a drill runs at a place**, away from its label, as a unit
     * [x, z] in the table: from the place before to the place after (a drill's
     * end to its neighbour), or across a lotus's two places. The Swift's
     * `Seedbed.along`: a plant's nudge is laid along and across this, so a drill
     * that curves stays even across its width all the way round. Only a
     * difference, a square root and a division, so the same double on every host.
     */
    public static function along(int $drill, int $index, int $span): array
    {
        $from = $span === 2 ? $index : max(0, $index - 1);
        $to = min(self::PLACES - 1, $index + 1);
        [$ax, $az] = self::at($drill, $from);
        [$bx, $bz] = self::at($drill, $to);
        $dx = $bx - $ax;
        $dz = $bz - $az;
        $length = sqrt($dx * $dx + $dz * $dz);
        return [$dx / $length, $dz / $length];
    }

    /**
     * How many places along a drill a plant takes: **two for a lotus, one for
     * everything else**, Marcus's choice on 25 September 2026. A lotus's pads
     * reach as far from its stem as the next place along a drill, and further;
     * standing across two it has 0.78 m to the next stem. The empty habit, a
     * plant whose phone never sent one, takes one place.
     */
    public static function span(string $habit): int
    {
        return $habit === 'lotus' ? 2 : 1;
    }

    /** Every place in one plot, drill by drill, each in the order a dry drill is sown. */
    public static function slots(): array
    {
        static $slots = null;
        if ($slots !== null) return $slots;
        $slots = [];
        for ($drill = 0; $drill < self::DRILLS; $drill++) {
            foreach (self::dryOrder($drill) as $index) {
                $slots[] = ['drill' => $drill, 'index' => $index];
            }
        }
        return $slots;
    }

    /** Plots opened so far. */
    public static function plots(array $ways): int
    {
        $max = -1;
        foreach ($ways as $p) $max = max($max, (int) $p['plot']);
        return $max + 1;
    }

    /**
     * The kind sown in this drill of this plot, or null if nobody has claimed
     * it. `$here` is one plot's plantings.
     *
     * **Read off the plants rather than stored**, as the Knot Garden's colour
     * claim is: a claim that lives in a column can go stale, be restored wrong,
     * or disagree with the plants standing in it. This one cannot, because it
     * *is* the plants — which is why `SeedbedStore` has no claimed-kind column.
     */
    public static function kindOf(array $here, int $drill): ?string
    {
        foreach ($here as $p) {
            if ((int) $p['drill'] === $drill) return (string) $p['kind'];
        }
        return null;
    }

    /**
     * The archetypes that want water. Read from the habit, which is a word.
     * `Archetype.wantsWater` in the Swift, said again here.
     *
     * **The reed since 28 September 2026**, which stands in the shallows as a
     * lily lies on the water, so a reed floods its drill as a lily does. It
     * takes one place in it; only a lotus takes two (`span`).
     */
    public const WANTS_WATER = ['lotus', 'reed'];

    /** Whether this habit belongs in water. */
    public static function wantsWater(string $habit): bool
    {
        return in_array($habit, self::WANTS_WATER, true);
    }

    /**
     * **Whether this drill is under water**, or null if nobody has claimed
     * it. A drill sown with water lilies is flooded, which is what a nursery
     * does: the aquatics stand in their own rows beside the rows of fine
     * tilth. Read off the first plant in the drill, as the kind is, and from
     * its habit, which is stored with it — so a row written before the water
     * says which element its drill is as plainly as a new one.
     */
    public static function isWater(array $here, int $drill): ?bool
    {
        foreach ($here as $p) {
            if ((int) $p['drill'] === $drill) return self::wantsWater((string) ($p['habit'] ?? ''));
        }
        return null;
    }

    /** How many places in a drill are held, a lotus's two counted as two. */
    public static function sown(array $here, int $drill): int
    {
        $held = 0;
        foreach ($here as $p) {
            if ((int) $p['drill'] === $drill) $held += (int) ($p['span'] ?? 1);
        }
        return $held;
    }

    /** Which places of a drill are held: index => true. */
    private static function held(array $here, int $drill): array
    {
        $held = [];
        foreach ($here as $p) {
            if ((int) $p['drill'] !== $drill) continue;
            for ($i = 0; $i < (int) ($p['span'] ?? 1); $i++) $held[(int) $p['index'] + $i] = true;
        }
        return $held;
    }

    /**
     * The first place in this drill a plant of this span and element can take,
     * in the order the drill is sown, or null if it has none. **A lotus takes a
     * whole pair**, the next free one in the flooded order.
     */
    public static function free(int $drill, array $held, int $span, bool $wet): ?int
    {
        foreach ($wet ? self::wetOrder($drill) : self::dryOrder($drill) as $index) {
            if (isset($held[$index])) continue;
            if ($span === 1) return $index;
            if ($index % 2 === 0 && $index + 1 < self::PLACES && !isset($held[$index + 1])) return $index;
        }
        return null;
    }

    /**
     * Where a plant of this kind goes: [plot, slot].
     *
     * Three steps, oldest plot first: a drill already sown with this kind and
     * not yet full; failing that an unclaimed drill; failing that a new plot.
     * **A drill is claimed, never reserved** — a kind that has not arrived holds
     * nothing — which is what keeps a rare kind from pinning a drill open in
     * every plot.
     *
     * **A lotus needs a whole pair.** A drill of its kind whose free places are
     * not two of one pair has no room for it, and it goes on as a plant finding
     * the drill full does; the place stays for a plant of one place of that kind.
     *
     * **A drill is claimed by kind and by element**, since 27 September 2026.
     * A kind is an epithet and an epithet says what is most so about a plant
     * rather than what it is — *rubra* is red and a water lily can be red —
     * so two plants of one kind may want different ground. A lily joins a
     * flooded drill of its kind and a dry plant a dry one; neither will take
     * the other's, and a half-flooded drill is not a thing a nursery has.
     *
     * **And from its own side of the bed**, since 2 October 2026: a dry plant
     * claims the highest unclaimed drill and a water plant the lowest, and takes
     * the first place its drill is sown in.
     */
    public static function place(array $ways, string $kind, string $habit = ''): array
    {
        $plots = max(self::plots($ways), 1);
        $span = self::span($habit);
        $wet = self::wantsWater($habit);
        $order = self::claimOrder($wet);
        $byPlot = array_fill(0, $plots, []);
        foreach ($ways as $p) {
            if ((int) $p['plot'] < $plots) $byPlot[(int) $p['plot']][] = $p;
        }

        // A drill of this kind and this element with room in it, oldest plot
        // first.
        for ($plot = 0; $plot < $plots; $plot++) {
            foreach ($order as $drill) {
                if (self::kindOf($byPlot[$plot], $drill) !== $kind) continue;
                if (self::isWater($byPlot[$plot], $drill) !== $wet) continue;
                $index = self::free($drill, self::held($byPlot[$plot], $drill), $span, $wet);
                if ($index !== null) return [$plot, ['drill' => $drill, 'index' => $index]];
            }
        }

        // Otherwise the first drill nobody has sown on its own side of the bed,
        // oldest plot first.
        for ($plot = 0; $plot < $plots; $plot++) {
            foreach ($order as $drill) {
                if (self::kindOf($byPlot[$plot], $drill) === null) {
                    return [$plot, ['drill' => $drill, 'index' => self::free($drill, [], $span, $wet)]];
                }
            }
        }

        return [$plots, ['drill' => $order[0], 'index' => self::free($order[0], [], $span, $wet)]];
    }

    /**
     * Plants one arrival and returns the planting; the area only grows.
     *
     * The nudge is the only area's whose two directions differ: 0.06 m along
     * the drill and 0.035 m across it, `nudgeX` and `nudgeZ`, laid along the
     * drill where the plant stands (`spot`). **A
     * drill has to read as a line**, which is the whole of what a seedbed looks
     * like, and a line survives being uneven along its length but not being
     * uneven across it.
     */
    public static function plant(array $ways, string $seedHex, float $height,
                                 int $family, string $kind, string $habit = ''): array
    {
        [$plot, $slot] = self::place($ways, $kind, $habit);
        $bytes = array_values(unpack('C*', hex2bin($seedHex)));
        $jitter = fn(int $i, float $reach) => isset($bytes[$i]) ? ($bytes[$i] / 255 - 0.5) * 2 * $reach : 0.0;
        return [
            'seed' => $seedHex, 'plot' => $plot,
            'drill' => $slot['drill'], 'index' => $slot['index'], 'span' => self::span($habit),
            'height' => $height, 'family' => $family, 'kind' => $kind, 'habit' => $habit,
            'nudgeX' => $jitter(26, 0.06), 'nudgeZ' => $jitter(27, 0.035),
        ];
    }
}
