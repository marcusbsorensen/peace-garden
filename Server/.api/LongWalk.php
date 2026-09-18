<?php
declare(strict_types=1);

/**
 * The Long Walk's placement rule, ported from SeedCore's
 * `WebGardens/LongWalk.swift` so the plot service can run it.
 *
 * **A port, and held to the Swift.** The server is PHP and cannot run SeedCore,
 * so this is a second copy of the rule, and a copy drifts unless something
 * checks it: `tools/reference/check_long_walk.php` plants the six hundred
 * arrivals pinned in `tools/reference/long_walk_vectors.json` and fails CI if
 * this puts any of them anywhere the Swift did not. Change the Swift first,
 * re-record, then bring this along.
 *
 * Kept to the Swift's arithmetic in the Swift's order, so every spot and every
 * comparison is the same double: a slot's place is compared with `<=` against
 * a reach, and a last-bit difference there would move a plant.
 *
 * A planting here is an array: seed (hex), plot, side (-1 or 1), tier (0 edge,
 * 1 middle, 2 back), index, height, family, nudgeX, nudgeZ.
 */
final class LongWalk
{
    public const PLANTED_LENGTH = 4.8;
    public const ORDER_REACH = 1.3;
    public const DRIFT_REACH = 0.85;
    public const DRIFT_DEPTH = 0.3;
    public const ROW_OFFSET = 0.13;
    public const DEPTH = [0.95, 1.45, 1.95];
    public const PER_ROW = [5, 4, 3];

    public static function tier(float $height): int
    {
        if ($height < 0.93) return 0;
        if ($height < 1.28) return 1;
        return 2;
    }

    /** Where a slot is, in metres from the middle of its plot: [x, z]. */
    public static function spot(int $side, int $tier, int $index): array
    {
        $spacing = self::PLANTED_LENGTH / self::PER_ROW[$tier];
        $row = $index % 2;
        $along = intdiv($index, 2);
        $depth = self::DEPTH[$tier] + ($row === 0 ? -self::ROW_OFFSET : self::ROW_OFFSET);
        return [
            $side * $depth,
            -self::PLANTED_LENGTH / 2 + ($along + 0.25 + 0.5 * $row) * $spacing,
        ];
    }

    /** Every slot in one plot, in tie-breaking order: down the walk, then left first. */
    public static function slots(): array
    {
        static $slots = null;
        if ($slots !== null) return $slots;
        $slots = [];
        foreach ([0, 1, 2] as $tier) {
            for ($index = 0; $index < 2 * self::PER_ROW[$tier]; $index++) {
                foreach ([-1, 1] as $side) {
                    [$x, $z] = self::spot($side, $tier, $index);
                    $slots[] = ['side' => $side, 'tier' => $tier, 'index' => $index, 'x' => $x, 'z' => $z];
                }
            }
        }
        // Stable, as the Swift's is, so equal places keep the order they were made in.
        usort($slots, fn($a, $b) => $a['z'] <=> $b['z'] ?: $a['side'] <=> $b['side']);
        return $slots;
    }

    /** Plots opened so far. */
    public static function plots(array $walk): int
    {
        $max = -1;
        foreach ($walk as $p) $max = max($max, $p['plot']);
        return $max + 1;
    }

    /**
     * Where the next plant with these traits goes: [plot, slot]. Its own tier
     * in the oldest plot with room, else the tier beside it, else a new plot.
     */
    public static function place(array $walk, float $height, int $family): array
    {
        $own = self::tier($height);
        $beside = array_values(array_filter([0, 1, 2], fn($t) => abs($t - $own) === 1));
        $plots = self::plots($walk);

        foreach ([[$own], $beside] as $tiers) {
            for ($plot = 0; $plot < $plots; $plot++) {
                $here = self::inPlot($walk, $plot);
                $taken = [];
                foreach ($here as $p) $taken[self::key($p)] = true;
                $open = [];
                foreach (self::slots() as $slot) {
                    if (in_array($slot['tier'], $tiers, true) && !isset($taken[self::key($slot)])
                        && self::inOrder($here, $height, $slot)) {
                        $open[] = $slot;
                    }
                }
                $best = self::best($open, $here, $family);
                if ($best !== null) return [$plot, $best];
            }
        }
        $open = array_values(array_filter(self::slots(), fn($s) => $s['tier'] === $own));
        return [$plots, self::best($open, [], $family) ?? $open[0]];
    }

    /** Plants one arrival and returns the planting; the walk only grows. */
    public static function plant(array $walk, string $seedHex, float $height, int $family): array
    {
        [$plot, $slot] = self::place($walk, $height, $family);
        $bytes = array_values(unpack('C*', hex2bin($seedHex)));
        $jitter = fn(int $i, float $reach) => isset($bytes[$i]) ? ($bytes[$i] / 255 - 0.5) * 2 * $reach : 0.0;
        return [
            'seed' => $seedHex, 'plot' => $plot,
            'side' => $slot['side'], 'tier' => $slot['tier'], 'index' => $slot['index'],
            'height' => $height, 'family' => $family,
            'nudgeX' => $jitter(20, 0.1), 'nudgeZ' => $jitter(21, 0.14),
        ];
    }

    // MARK: - The rule's parts

    private static function inOrder(array $here, float $height, array $slot): bool
    {
        foreach ($here as $other) {
            if ($other['side'] !== $slot['side']) continue;
            [, $oz] = self::spot($other['side'], $other['tier'], $other['index']);
            if (abs($oz - $slot['z']) > self::ORDER_REACH) continue;
            if ($other['tier'] > $slot['tier'] && $other['height'] < $height) return false;
            if ($other['tier'] < $slot['tier'] && $other['height'] > $height) return false;
        }
        return true;
    }

    /** The best open slot for this colour, or null if every one would overfill a drift. */
    private static function best(array $open, array $here, int $family): ?array
    {
        $bestSlot = null;
        $bestScore = PHP_INT_MIN;
        foreach ($open as $slot) {
            $kin = [];
            foreach ($here as $p) {
                if ($p['side'] !== $slot['side'] || $p['family'] !== $family) continue;
                [$px, $pz] = self::spot($p['side'], $p['tier'], $p['index']);
                if (abs($pz - $slot['z']) <= self::DRIFT_REACH && abs($px - $slot['x']) <= self::DRIFT_DEPTH) {
                    $kin[] = $p;
                }
            }
            if ($kin === []) {
                $score = 0;
            } else {
                $joined = [];
                foreach ($kin as $neighbour) $joined += self::drift($neighbour, $here);
                if (count($joined) >= 5) continue;
                $score = 10 + count($joined);
            }
            if ($score > $bestScore) {
                $bestScore = $score;
                $bestSlot = $slot;
            }
        }
        return $bestSlot;
    }

    /** The slots, keyed, of every plant of one colour joined to this one. */
    private static function drift(array $start, array $here): array
    {
        $seen = [self::key($start) => true];
        $frontier = [$start];
        while ($frontier !== []) {
            $next = array_pop($frontier);
            [$nx, $nz] = self::spot($next['side'], $next['tier'], $next['index']);
            foreach ($here as $other) {
                if (isset($seen[self::key($other)]) || $other['family'] !== $start['family']
                    || $other['side'] !== $next['side']) continue;
                [$ox, $oz] = self::spot($other['side'], $other['tier'], $other['index']);
                if (abs($oz - $nz) <= self::DRIFT_REACH && abs($ox - $nx) <= self::DRIFT_DEPTH) {
                    $seen[self::key($other)] = true;
                    $frontier[] = $other;
                }
            }
        }
        return $seen;
    }

    private static function inPlot(array $walk, int $plot): array
    {
        return array_values(array_filter($walk, fn($p) => $p['plot'] === $plot));
    }

    private static function key(array $slot): string
    {
        return $slot['side'] . ':' . $slot['tier'] . ':' . $slot['index'];
    }
}
