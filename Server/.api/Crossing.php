<?php
declare(strict_types=1);

require_once __DIR__ . '/LongWalk.php';

/**
 * The Crossing's placement rule, ported from SeedCore's
 * `WebGardens/Crossing.swift` so the plot service can run it.
 *
 * **A port, and held to the Swift.** The server is PHP and cannot run SeedCore,
 * so this is a second copy of the rule, and a copy drifts unless something
 * checks it: `tools/reference/check_crossing.php` plants the arrivals pinned in
 * `tools/reference/crossing_vectors.json` and fails CI if this puts any of them
 * anywhere the Swift did not. Change the Swift first, re-record, then bring this
 * along.
 *
 * Kept to the Swift's arithmetic in the Swift's order, and to its **iteration**
 * order, because this rule returns the emptiest quarter it finds rather than the
 * best-scoring one, and `<` rather than `<=` on the count is what keeps a tie on
 * the lowest-numbered quarter.
 *
 * A planting here is an array: seed (hex), plot, quarter (0-3), index (0-5),
 * height, family, nudgeX, nudgeZ.
 */
final class Crossing
{
    public const PLOT_SIDE = 5.2;
    public const PATH_HALF_WIDTH = 0.6;
    public const ROUNDEL_RADIUS = 0.85;

    /** The cuts, measured at the 50th and 83rd centiles of grown heights. */
    public const MIDDLE_FROM = 0.91;
    public const CORNER_FROM = 1.30;

    /** Which way each quarter lies from the middle of the plot: [x, z]. */
    public const LIE = [[1, 1], [-1, 1], [-1, -1], [1, -1]];

    public const PATH = 0;
    public const MIDDLE = 1;
    public const CORNER = 2;

    /**
     * The six places in a quarter, in the quarter where both axes are positive.
     * Three arcs at 1.90, 2.42 and 2.95 m from the middle, written out rather
     * than computed from an angle so that Swift and PHP hold the same number.
     */
    public const CANONICAL = [
        [1.34, 1.34],   // 0  the path rank, on the quarter's own diagonal
        [0.92, 1.66],   // 1  the path rank, along one path edge
        [1.66, 0.92],   // 2  the path rank, along the other
        [1.39, 1.98],   // 3  behind 1
        [1.98, 1.39],   // 4  behind 2
        [2.09, 2.09],   // 5  the corner, behind 0
    ];

    /** Where in a quarter a plant of this height belongs. */
    public static function rank(float $height): int
    {
        if ($height < self::MIDDLE_FROM) return self::PATH;
        return $height < self::CORNER_FROM ? self::MIDDLE : self::CORNER;
    }

    /** Which rank a slot is, read off its index. */
    public static function rankOf(int $index): int
    {
        if ($index < 3) return self::PATH;
        return $index < 5 ? self::MIDDLE : self::CORNER;
    }

    /** Every slot in one plot, quarter by quarter and outward within each. */
    public static function slots(): array
    {
        static $slots = null;
        if ($slots !== null) return $slots;
        $slots = [];
        foreach ([0, 1, 2, 3] as $quarter) {
            for ($index = 0; $index < 6; $index++) {
                $slots[] = ['quarter' => $quarter, 'index' => $index];
            }
        }
        return $slots;
    }

    /** The first slot of a rank, used to open a quarter nobody has planted. */
    public static function firstSlot(int $rank, int $quarter): array
    {
        $index = $rank === self::PATH ? 0 : ($rank === self::MIDDLE ? 3 : 5);
        return ['quarter' => $quarter, 'index' => $index];
    }

    /** Where a slot is, in metres from the middle of its plot: [x, z]. */
    public static function spot(int $quarter, int $index): array
    {
        [$lx, $lz] = self::LIE[$quarter];
        [$x, $z] = self::CANONICAL[$index];
        return [$lx * $x, $lz * $z];
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
            self::PATH => [self::PATH, self::MIDDLE],
            self::MIDDLE => [self::MIDDLE, self::PATH, self::CORNER],
            default => [self::CORNER, self::MIDDLE],
        };
    }

    /**
     * Where the next plant with these traits goes: [plot, slot].
     *
     * A slot of its own rank in the emptiest quarter of the oldest plot that
     * has one; then a slot of the rank beside its own; then a new plot, opened
     * by this plant standing in its own rank in the first quarter.
     */
    public static function place(array $ways, float $height, int $family): array
    {
        $plots = self::plots($ways);
        foreach (self::ranksBeside(self::rank($height)) as $rank) {
            for ($plot = 0; $plot < $plots; $plot++) {
                $slot = self::slotIn($ways, $plot, $height, $rank);
                if ($slot !== null) return [$plot, $slot];
            }
        }
        return [$plots, self::firstSlot(self::rank($height), 0)];
    }

    /** Plants one arrival and returns the planting; the area only grows. */
    public static function plant(array $ways, string $seedHex, float $height, int $family): array
    {
        [$plot, $slot] = self::place($ways, $height, $family);
        $bytes = array_values(unpack('C*', hex2bin($seedHex)));
        $jitter = fn(int $i, float $reach) => isset($bytes[$i]) ? ($bytes[$i] / 255 - 0.5) * 2 * $reach : 0.0;
        return [
            'seed' => $seedHex, 'plot' => $plot,
            'quarter' => $slot['quarter'], 'index' => $slot['index'],
            'height' => $height, 'family' => $family,
            'nudgeX' => $jitter(22, 0.11), 'nudgeZ' => $jitter(23, 0.11),
        ];
    }

    // MARK: - The rule's parts

    /**
     * The emptiest quarter of this plot with a free slot of `$rank` that a plant
     * this tall may stand in. Strictly fewer, so a tie stays with the
     * lowest-numbered quarter, which is what the Swift does.
     */
    private static function slotIn(array $ways, int $plot, float $height, int $rank): ?array
    {
        $here = array_values(array_filter($ways, fn($p) => $p['plot'] === $plot));
        $taken = [];
        foreach ($here as $p) $taken[$p['quarter'] . ':' . $p['index']] = true;

        $best = null;
        $fewest = PHP_INT_MAX;
        foreach ([0, 1, 2, 3] as $quarter) {
            $bed = array_values(array_filter($here, fn($p) => $p['quarter'] === $quarter));
            if (count($bed) >= $fewest) continue;
            foreach (self::slots() as $slot) {
                if ($slot['quarter'] !== $quarter) continue;
                if (self::rankOf($slot['index']) !== $rank) continue;
                if (isset($taken[$slot['quarter'] . ':' . $slot['index']])) continue;
                if (!self::inOrder($bed, $height, $slot['index'])) continue;
                $best = $slot;
                $fewest = count($bed);
                break;
            }
        }
        return $best;
    }

    /**
     * Whether a plant this tall can stand in this slot: reading outward from the
     * crossing, nothing stands in front of something shorter than itself. Ranks
     * are compared, not distances, so the three sharing the path rank's arc are
     * free of each other.
     */
    private static function inOrder(array $bed, float $height, int $index): bool
    {
        $rank = self::rankOf($index);
        foreach ($bed as $other) {
            $otherRank = self::rankOf($other['index']);
            if ($rank < $otherRank && $height > $other['height']) return false;
            if ($rank > $otherRank && $height < $other['height']) return false;
        }
        return true;
    }
}
