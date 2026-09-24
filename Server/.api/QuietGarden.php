<?php
declare(strict_types=1);

require_once __DIR__ . '/LongWalk.php';

/**
 * The Quiet Garden's placement rule, ported from SeedCore's
 * `WebGardens/QuietGarden.swift` so the plot service can run it.
 *
 * **A port, and held to the Swift.** The server is PHP and cannot run SeedCore,
 * so this is a second copy of the rule, and a copy drifts unless something
 * checks it: `tools/reference/check_quiet_garden.php` plants the arrivals pinned
 * in `tools/reference/quiet_garden_vectors.json` and fails CI if this puts any
 * of them anywhere the Swift did not. Change the Swift first, re-record, then
 * bring this along.
 *
 * Kept to the Swift's arithmetic in the Swift's order, and — more than in the
 * walk's port — to the Swift's **iteration** order, because this rule returns
 * the first slot it finds rather than the best-scoring one. Two passes that
 * disagree about which corner to look at first would file plants differently
 * without either being wrong about a single number.
 *
 * A planting here is an array: seed (hex), plot, corner (0 bench, 1–3 the
 * groups), index (0 the back of a group, 1 and 2 its arms), height, family,
 * nudgeX, nudgeZ.
 */
final class QuietGarden
{
    public const PLOT_SIDE = 5.2;
    public const HEDGE_FROM = 2.3;
    public const AT_THE_HEDGE = 1.95;
    public const ALONG_THE_HEDGE = 1.10;
    public const BESIDE_THE_BENCH = 0.95;
    public const BACK_FROM = 1.09;

    /** The bench's corner, which holds one plant and no group. */
    public const BENCH = 0;

    /** Which way each corner lies from the middle of the room: [x, z]. */
    public const LIE = [[-1, -1], [1, -1], [1, 1], [-1, 1]];

    public const ARM = 0;
    public const BACK = 1;

    /** Where a plant of this height stands in a group of three. */
    public static function stand(float $height): int
    {
        return $height < self::BACK_FROM ? self::ARM : self::BACK;
    }

    /** The colour families a group will take besides its own. */
    public static function near(int $family): array
    {
        $arcs = LongWalk::PALE_FAMILY;
        if ($family === $arcs) return range(0, $arcs - 1);
        return [($family + $arcs - 1) % $arcs, ($family + 1) % $arcs, $arcs];
    }

    /** Every slot in one plot, in the order a tie is broken: the bench first. */
    public static function slots(): array
    {
        static $slots = null;
        if ($slots !== null) return $slots;
        $slots = [];
        foreach ([0, 1, 2, 3] as $corner) {
            $count = $corner === self::BENCH ? 1 : 3;
            for ($index = 0; $index < $count; $index++) {
                $slots[] = ['corner' => $corner, 'index' => $index];
            }
        }
        return $slots;
    }

    /** Whether a slot is the back of its group. The specimen stands alone. */
    public static function standOf(int $corner, int $index): int
    {
        return $corner !== self::BENCH && $index === 0 ? self::BACK : self::ARM;
    }

    /** Where a slot is, in metres from the middle of its plot: [x, z]. */
    public static function spot(int $corner, int $index): array
    {
        [$lx, $lz] = self::LIE[$corner];
        if ($corner === self::BENCH) {
            return [$lx * self::AT_THE_HEDGE, $lz * self::BESIDE_THE_BENCH];
        }
        return match ($index) {
            0 => [$lx * self::AT_THE_HEDGE, $lz * self::AT_THE_HEDGE],
            1 => [$lx * self::AT_THE_HEDGE, $lz * self::ALONG_THE_HEDGE],
            default => [$lx * self::ALONG_THE_HEDGE, $lz * self::AT_THE_HEDGE],
        };
    }

    /** Plots opened so far. */
    public static function plots(array $room): int
    {
        $max = -1;
        foreach ($room as $p) $max = max($max, $p['plot']);
        return $max + 1;
    }

    /**
     * Where the next plant with these traits goes: [plot, slot].
     *
     * A plot's first plant stands by the bench, always, because a new plot is
     * opened by taking its specimen slot. After that: a group of its own
     * colour, a corner nobody has planted, a group of a colour near its own, or
     * a new plot.
     */
    public static function place(array $room, float $height, int $family): array
    {
        $plots = self::plots($room);
        foreach (['own', 'fresh', 'near'] as $kinship) {
            for ($plot = 0; $plot < $plots; $plot++) {
                $slot = self::slotIn($room, $plot, $height, $family, $kinship);
                if ($slot !== null) return [$plot, $slot];
            }
        }
        return [$plots, ['corner' => self::BENCH, 'index' => 0]];
    }

    /** Plants one arrival and returns the planting; the room only grows. */
    public static function plant(array $room, string $seedHex, float $height, int $family): array
    {
        [$plot, $slot] = self::place($room, $height, $family);
        $bytes = array_values(unpack('C*', hex2bin($seedHex)));
        $jitter = fn(int $i, float $reach) => isset($bytes[$i]) ? ($bytes[$i] / 255 - 0.5) * 2 * $reach : 0.0;
        return [
            'seed' => $seedHex, 'plot' => $plot,
            'corner' => $slot['corner'], 'index' => $slot['index'],
            'height' => $height, 'family' => $family,
            'nudgeX' => $jitter(22, 0.13), 'nudgeZ' => $jitter(23, 0.13),
        ];
    }

    // MARK: - The rule's parts

    private static function slotIn(array $room, int $plot, float $height, int $family,
                                   string $kinship): ?array
    {
        $here = array_values(array_filter($room, fn($p) => $p['plot'] === $plot));
        $taken = [];
        foreach ($here as $p) $taken[$p['corner'] . ':' . $p['index']] = true;

        // Its own stand first, then the other one — a back plant that finds the
        // back taken may still stand in an arm, as long as nothing ends up in
        // front of something shorter.
        $own = self::stand($height);
        $stands = $own === self::BACK ? [self::BACK, self::ARM] : [self::ARM, self::BACK];

        foreach ($stands as $wanted) {
            foreach ([1, 2, 3] as $corner) {
                $group = array_values(array_filter($here, fn($p) => $p['corner'] === $corner));
                $founder = $group[0] ?? null;
                if ($kinship === 'own') {
                    if ($founder === null || $founder['family'] !== $family) continue;
                } elseif ($kinship === 'fresh') {
                    if ($founder !== null) continue;
                } else {
                    if ($founder === null) continue;
                    if (!in_array($family, self::near($founder['family']), true)) continue;
                }
                foreach (self::slots() as $slot) {
                    if ($slot['corner'] !== $corner) continue;
                    if (self::standOf($slot['corner'], $slot['index']) !== $wanted) continue;
                    if (isset($taken[$slot['corner'] . ':' . $slot['index']])) continue;
                    if (!self::inOrder($group, $height, $slot['index'])) continue;
                    return $slot;
                }
            }
        }
        return null;
    }

    /**
     * Whether a plant this tall can stand in this slot: the back of a group is
     * at least as tall as either of its arms. The Long Walk's rule at the scale
     * of a group of three.
     */
    private static function inOrder(array $group, float $height, int $index): bool
    {
        foreach ($group as $other) {
            if ($index === 0 && $other['height'] > $height) return false;
            if ($index !== 0 && $other['index'] === 0 && $other['height'] < $height) return false;
        }
        return true;
    }
}
