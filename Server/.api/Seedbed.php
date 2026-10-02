<?php
declare(strict_types=1);

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
 * **A lotus takes two places**, since 25 September 2026: the next two its
 * drill would fill, standing centred across them (`span`). The habit is read
 * for it — a word, exact on every host like the kind, so the placement still
 * needs no tolerance — and only the arriving plant's; a plant already standing
 * says how many places it holds by its span, which is stored with it.
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
     * the Swift's `variants`. Mirrored only, so the drills keep the side of the
     * plot they were laid to. Declared but not yet read.
     */
    public const VARIANTS = ['turns' => 1, 'mirror' => true, 'nudges' => 1];

    /**
     * Six drills of eight, chosen by Marcus from three offers on 23 September.
     * Forty-eight is the Long Walk's number; at this plot it leaves 0.74 m
     * between drills, which is the width of the space a gardener kneels in.
     */
    public const DRILLS = 6;
    public const PLACES = 8;

    /** Across the bed, between one drill and the next. */
    public const DRILL_GAP = 0.74;
    /** Along a drill, between one plant and the next. */
    public const ALONG_GAP = 0.52;

    /**
     * Where a drill's label stands, in `z`: a little beyond the first plant, at
     * the end the drill fills from.
     */
    public const LABEL_AT = -2.15;

    /**
     * Where a plant holding `span` places from `index` stands, in metres from
     * the middle of its plot: [x, z]. The middle of its places, so a lotus
     * stands half a place further from the label than its first.
     *
     * `index` 0 is the place nearest the label, and a drill fills from there
     * outward, so reading a drill from its label is reading it in the order it
     * was sown. The place is counted in halves, as the Swift counts it, so a
     * plant of one place stands where it always did, to the last bit.
     */
    public static function spot(int $drill, int $index, int $span = 1): array
    {
        $at = $index + ($span - 1) / 2;
        return [
            ($drill - (self::DRILLS - 1) / 2) * self::DRILL_GAP,
            ($at - (self::PLACES - 1) / 2) * self::ALONG_GAP,
        ];
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

    /** Every place in one plot, drill by drill and along each. */
    public static function slots(): array
    {
        static $slots = null;
        if ($slots !== null) return $slots;
        $slots = [];
        for ($drill = 0; $drill < self::DRILLS; $drill++) {
            for ($index = 0; $index < self::PLACES; $index++) {
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

    /**
     * How many places in a drill are held. A drill fills from the label without
     * a gap, so this is also the index of its next place — and, in a drill with
     * no lotus in it, how many plants stand there, which is what it counted
     * until a lotus took two.
     */
    public static function sown(array $here, int $drill): int
    {
        $next = 0;
        foreach ($here as $p) {
            if ((int) $p['drill'] === $drill) $next = max($next, (int) $p['index'] + (int) ($p['span'] ?? 1));
        }
        return $next;
    }

    /**
     * Where a plant of this kind goes: [plot, slot].
     *
     * Three steps, oldest plot first: a drill already sown with this kind and
     * not yet full; failing that an unclaimed drill; failing that a new plot,
     * opened at the head of its first drill. **A drill is claimed, never
     * reserved** — a kind that has not arrived holds nothing — which is what
     * keeps a rare kind from pinning a drill open in every plot.
     *
     * **A lotus needs two places side by side.** A drill of its kind with one
     * place left has no room for it, and it goes on as a plant finding the drill
     * full does; the place stays for a plant of one place of that kind.
     *
     * **A drill is claimed by kind and by element**, since 27 September 2026.
     * A kind is an epithet and an epithet says what is most so about a plant
     * rather than what it is — *rubra* is red and a water lily can be red —
     * so two plants of one kind may want different ground. A lily joins a
     * flooded drill of its kind and a dry plant a dry one; neither will take
     * the other's, and a half-flooded drill is not a thing a nursery has.
     */
    public static function place(array $ways, string $kind, string $habit = ''): array
    {
        $plots = max(self::plots($ways), 1);
        $span = self::span($habit);
        $wet = self::wantsWater($habit);
        $byPlot = [];
        for ($plot = 0; $plot < $plots; $plot++) {
            $byPlot[$plot] = array_values(array_filter($ways, fn($p) => (int) $p['plot'] === $plot));
        }

        // A drill of this kind and this element with room in it, oldest plot
        // first.
        for ($plot = 0; $plot < $plots; $plot++) {
            for ($drill = 0; $drill < self::DRILLS; $drill++) {
                if (self::kindOf($byPlot[$plot], $drill) !== $kind) continue;
                if (self::isWater($byPlot[$plot], $drill) !== $wet) continue;
                $next = self::sown($byPlot[$plot], $drill);
                if ($next + $span <= self::PLACES) return [$plot, ['drill' => $drill, 'index' => $next]];
            }
        }

        // Otherwise the first drill nobody has sown, oldest plot first.
        for ($plot = 0; $plot < $plots; $plot++) {
            for ($drill = 0; $drill < self::DRILLS; $drill++) {
                if (self::kindOf($byPlot[$plot], $drill) === null) {
                    return [$plot, ['drill' => $drill, 'index' => 0]];
                }
            }
        }

        return [$plots, ['drill' => 0, 'index' => 0]];
    }

    /**
     * Plants one arrival and returns the planting; the area only grows.
     *
     * The nudge is the only area's whose two directions differ: 0.035 m across
     * the drill and 0.06 m along it. **A drill has to read as a line**, which is
     * the whole of what a seedbed looks like, and a line survives being uneven
     * along its length but not being uneven across it.
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
            'nudgeX' => $jitter(26, 0.035), 'nudgeZ' => $jitter(27, 0.06),
        ];
    }
}
