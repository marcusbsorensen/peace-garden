<?php
declare(strict_types=1);

require_once __DIR__ . '/LongWalk.php';
require_once __DIR__ . '/Orchard.php';

/**
 * The Knot Garden's placement rule, ported from SeedCore's
 * `WebGardens/KnotGarden.swift` so the plot service can run it.
 *
 * **A port, and held to the Swift.** The server is PHP and cannot run SeedCore,
 * so this is a second copy of the rule, and a copy drifts unless something
 * checks it: `tools/reference/check_knot.php` plants the arrivals pinned in
 * `tools/reference/knot_garden_vectors.json` and fails CI if this puts any of
 * them anywhere else. Change the Swift first, re-record, then bring this along.
 *
 * **The first rule here that reads a plant's colour.** Four areas grade by
 * height alone; this one asks the colour first — which pair of opposite
 * compartments a plant belongs to — and the height second, for the place within
 * it. A port that got only the height right would agree about plot 0 entirely
 * and diverge in the middle of the garden, when a colour first runs out of room
 * in the plot it started in.
 *
 * Kept to the Swift's arithmetic in the Swift's order, and above all to its
 * **loop order in the first step: plot outside, rank inside**. That is the
 * Orchard's nesting rather than the Crossing's, because what this area is for
 * is that a compartment reads as one colour.
 *
 * A planting here is an array: seed (hex), plot, compartment (0-7), index
 * (0-3), height, family, nudgeX, nudgeZ.
 */
final class KnotGarden
{
    public const PLOT_SIDE = 5.2;
    public const BAND_HALF_THICKNESS = 0.09;
    public const BAND_HEIGHT = 0.17;
    public const BAND_FROM = 0.76;
    public const EDGING_FROM = 2.20;

    /**
     * The Orchard's cuts, named as the Orchard's rather than written out again.
     * A compartment of four graded outward is the same 1:2:1 a guild is, so it
     * divides the same population of grown heights the same way — and a second
     * copy of 0.58 and 1.20 would be a number that could drift from the one it
     * is a copy of.
     */
    public const SIDE_FROM = Orchard::FLANK_FROM;
    public const POINT_FROM = Orchard::CROWN_FROM;

    public const HEART = 0;
    public const SIDE = 1;
    public const POINT = 2;

    /** The eight compartments: four at the sides of the plot, then four at its corners. */
    public const NORTH = 0;
    public const COMPARTMENTS = [0, 1, 2, 3, 4, 5, 6, 7];
    public const PAIRS = [0, 1, 2, 3];

    /**
     * The four places in the north compartment, 1.37 m across and 1.29 m deep
     * between the knot's two runs and the edging. Written out rather than
     * computed from an angle, for the reason `Organic::quarter` exists.
     */
    public const SIDE_PLACES = [
        [0.0, 1.16],      // 0  nearest the knot's middle
        [-0.43, 1.53],    // 1  beside it
        [0.43, 1.53],     // 2  beside it, the same distance out as 1
        [0.0, 1.89],      // 3  at the edging
    ];

    /** The four places in the north-east compartment, a 1.29 m square. */
    public const CORNER_PLACES = [
        [1.09, 1.09],
        [1.03, 1.72],
        [1.72, 1.03],
        [1.80, 1.80],
    ];

    /** Whether a compartment sits at a corner of the plot rather than at a side. */
    public static function atCorner(int $compartment): bool
    {
        return $compartment >= 4;
    }

    /** The compartment opposite this one, which holds the same colour. */
    public static function mirror(int $compartment): int
    {
        return $compartment ^ 2;
    }

    /** Which of the four mirror pairs a compartment belongs to. */
    public static function pairOf(int $compartment): int
    {
        return $compartment % 2 + (self::atCorner($compartment) ? 2 : 0);
    }

    /** The two compartments of a pair, the one it is named for first. */
    public static function compartmentsOf(int $pair): array
    {
        $first = $pair < 2 ? $pair : $pair + 2;
        return [$first, self::mirror($first)];
    }

    /** Where in a compartment a plant of this height belongs. */
    public static function rank(float $height): int
    {
        if ($height < self::SIDE_FROM) return self::HEART;
        return $height < self::POINT_FROM ? self::SIDE : self::POINT;
    }

    /** Which rank a place is. */
    public static function rankOf(int $index): int
    {
        if ($index === 0) return self::HEART;
        return $index < 3 ? self::SIDE : self::POINT;
    }

    /** Every place in one plot, compartment by compartment and outward within each. */
    public static function slots(): array
    {
        static $slots = null;
        if ($slots !== null) return $slots;
        $slots = [];
        foreach (self::COMPARTMENTS as $compartment) {
            for ($index = 0; $index < 4; $index++) {
                $slots[] = ['compartment' => $compartment, 'index' => $index];
            }
        }
        return $slots;
    }

    /**
     * Where a place is, in metres from the middle of its plot: [x, z].
     *
     * Every compartment is one of the two canonical sets of four turned by a
     * whole number of quarters, and a quarter turn here is a sign swap — no
     * host's trigonometry is involved, so every host holds the same number.
     */
    public static function spot(int $compartment, int $index): array
    {
        [$x, $z] = self::atCorner($compartment)
            ? self::CORNER_PLACES[$index]
            : self::SIDE_PLACES[$index];
        return match ($compartment % 4) {
            1 => [$z, -$x],
            2 => [-$x, -$z],
            3 => [-$z, $x],
            default => [$x, $z],
        };
    }

    /** The first place of a rank, used to open a compartment nobody has planted. */
    public static function firstSlot(int $rank, int $compartment): array
    {
        return ['compartment' => $compartment,
                'index' => $rank === self::HEART ? 0 : ($rank === self::SIDE ? 1 : 3)];
    }

    /** Plots opened so far. */
    public static function plots(array $ways): int
    {
        $max = -1;
        foreach ($ways as $p) $max = max($max, $p['plot']);
        return $max + 1;
    }

    /** The ranks to try, in order: a plant's own, then the one or two beside it. */
    public static function ranksBeside(int $rank): array
    {
        return match ($rank) {
            self::HEART => [self::HEART, self::SIDE],
            self::SIDE => [self::SIDE, self::HEART, self::POINT],
            default => [self::POINT, self::SIDE],
        };
    }

    /**
     * The colour family standing in this pair of this plot, or null if nobody
     * has claimed it. Read off the plants rather than stored, so a claim cannot
     * go stale or be restored wrong.
     */
    public static function familyOf(array $here, int $pair): ?int
    {
        foreach ($here as $p) {
            if (self::pairOf($p['compartment']) === $pair) return (int) $p['family'];
        }
        return null;
    }

    /**
     * Where the next plant with these traits goes: [plot, slot].
     *
     * A pair already holding this colour, in the oldest plot that has one with
     * room; then a pair nobody has claimed, in the oldest plot that has one;
     * then a new plot, opened in the north compartment.
     */
    public static function place(array $ways, float $height, int $family): array
    {
        $plots = self::plots($ways);
        $own = self::rank($height);
        $byPlot = [];
        for ($plot = 0; $plot < $plots; $plot++) {
            $byPlot[$plot] = array_values(array_filter($ways, fn($p) => $p['plot'] === $plot));
        }

        for ($plot = 0; $plot < $plots; $plot++) {
            foreach (self::PAIRS as $pair) {
                if (self::familyOf($byPlot[$plot], $pair) !== $family) continue;
                foreach (self::ranksBeside($own) as $rank) {
                    $slot = self::slotIn($byPlot[$plot], $pair, $height, $rank);
                    if ($slot !== null) return [$plot, $slot];
                }
            }
        }
        for ($plot = 0; $plot < $plots; $plot++) {
            foreach (self::PAIRS as $pair) {
                if (self::familyOf($byPlot[$plot], $pair) !== null) continue;
                return [$plot, self::firstSlot($own, self::compartmentsOf($pair)[0])];
            }
        }
        return [$plots, self::firstSlot($own, self::NORTH)];
    }

    /** Plants one arrival and returns the planting; the area only grows. */
    public static function plant(array $ways, string $seedHex, float $height, int $family): array
    {
        [$plot, $slot] = self::place($ways, $height, $family);
        $bytes = array_values(unpack('C*', hex2bin($seedHex)));
        $jitter = fn(int $i, float $reach) => isset($bytes[$i]) ? ($bytes[$i] / 255 - 0.5) * 2 * $reach : 0.0;
        return [
            'seed' => $seedHex, 'plot' => $plot,
            'compartment' => $slot['compartment'], 'index' => $slot['index'],
            'height' => $height, 'family' => $family,
            'nudgeX' => $jitter(26, 0.09), 'nudgeZ' => $jitter(27, 0.09),
        ];
    }

    // MARK: - The rule's parts

    /**
     * A free place of this rank in this pair that this plant may stand in: the
     * emptier of the pair's two compartments, ties to the one the pair is named
     * for. The Crossing's *wherever there is least*, asked of two compartments
     * instead of four quarters, which is what makes a pair fill as a mirror.
     */
    private static function slotIn(array $here, int $pair, float $height, int $rank): ?array
    {
        $taken = [];
        foreach ($here as $p) $taken[$p['compartment'] . ':' . $p['index']] = true;
        $best = null;
        $fewest = PHP_INT_MAX;
        foreach (self::compartmentsOf($pair) as $compartment) {
            $block = array_values(array_filter($here, fn($p) => $p['compartment'] === $compartment));
            if (count($block) >= $fewest) continue;
            foreach (self::slots() as $slot) {
                if ($slot['compartment'] !== $compartment) continue;
                if (self::rankOf($slot['index']) !== $rank) continue;
                if (isset($taken[$compartment . ':' . $slot['index']])) continue;
                if (!self::inOrder($block, $height, $slot['index'])) continue;
                $best = $slot;
                $fewest = count($block);
                break;
            }
        }
        return $best;
    }

    /**
     * `inOrder` for `tools/reference/check_knot.php`, which has to ask the rule
     * whether a plant *could* have stood somewhere it did not. Public rather
     * than duplicated: a second copy of this comparison in the check would be a
     * check that agrees with itself.
     */
    public static function inOrderForCheck(array $block, float $height, int $index): bool
    {
        return self::inOrder($block, $height, $index);
    }

    /**
     * Whether a plant this tall can stand in this place: reading outward from
     * the middle of the plot, nothing stands in front of something shorter than
     * itself. Ranks are compared, not distances, so the two plants at index 1
     * and 2 are free of each other.
     */
    private static function inOrder(array $block, float $height, int $index): bool
    {
        $mine = self::rankOf($index);
        foreach ($block as $other) {
            $theirs = self::rankOf($other['index']);
            if ($mine < $theirs && $height > $other['height']) return false;
            if ($mine > $theirs && $height < $other['height']) return false;
        }
        return true;
    }
}
