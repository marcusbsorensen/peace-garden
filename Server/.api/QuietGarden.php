<?php
declare(strict_types=1);

require_once __DIR__ . '/LongWalk.php';
require_once __DIR__ . '/PlotVariant.php';
require_once __DIR__ . '/tables/QuietRoomTable.php';

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
 * disagree about which group to look at first would file plants differently
 * without either being wrong about a single number.
 *
 * **An asymmetric room, since 2 October 2026** (Marcus; `QuietGarden.swift`
 * says the rest): the specimen by the bench, a group of five across the water,
 * a group of three along a side, and one plant alone, the echo, that repeats
 * the five's colour. The places come from `tables/QuietRoomTable.php`, made
 * offline, and each room is turned and mirrored by its number
 * (`PlotVariant.php`); `spotOn` is where a planting stands on its plot.
 *
 * A planting here is an array: seed (hex), plot, corner (0 the bench, 1 the
 * five, 2 the three, 3 the echo, 4 the pool), index (the place in its group,
 * in its fill order), height, family, nudgeX, nudgeZ.
 */
final class QuietGarden
{
    public const PLOT_SIDE = 5.2;

    /**
     * How this area's plots vary, from each plot's number (`PlotVariant.php`):
     * the Swift's `variants`. Turned and mirrored eight ways, as `quiet-a-
     * rooms.png` turns the rooms.
     */
    public const VARIANTS = ['turns' => 4, 'mirror' => true, 'nudges' => 1];
    public const HEDGE_FROM = 2.3;
    public const AT_THE_HEDGE = 1.95;
    /**
     * The cut between back and arm: 1.04 since 2 October 2026, the 67th
     * centile of this area's own plants, so the five's two backs fill (1.08
     * from 29 September). The Swift's `backFrom`.
     */
    public const BACK_FROM = 1.04;
    /** Where the bench stands in the table's frame, on its corner's diagonal. */
    public const BENCH_SPOT = [-1.72, -1.72];

    /** The bench's corner, which holds one plant and no group. */
    public const BENCH = 0;
    /** The group of five across the water, the group of three, and the echo. */
    public const FIVE = 1;
    public const THREE = 2;
    public const ECHO = 3;

    /**
     * The pool, which is a fifth place and not a group (27 September 2026).
     *
     * It rides in the same numbering so a slot stays one pair of numbers in
     * the table and on the wire. The live garden never sends this area a lily,
     * so it stays empty.
     */
    public const POOL = 4;

    /** How many places each group has: the specimen, the five, the three, the echo, the pool. */
    public const SIZES = [1, 5, 3, 1, 2];

    /** The groups a dry plant may join, in the order they are asked. */
    public const GROUPS = [self::FIVE, self::THREE, self::ECHO];

    /** Whether plants that want dry ground stand here. */
    public static function isDry(int $corner): bool
    {
        return $corner !== self::POOL;
    }

    /** Whether it is a group a colour claims: the five and the three. */
    public static function isGroup(int $corner): bool
    {
        return $corner === self::FIVE || $corner === self::THREE;
    }

    /**
     * Whether a habit wants standing water. `Archetype::wantsWater` in the
     * Swift; one list, said twice, because the service and the app place the
     * same plant and must not disagree about where it goes.
     *
     * **The lotus and, since 28 September 2026, the reed**, which stands in a
     * pool's shallows as a lily lies on it. A reed takes one of the pool's two
     * places, as a lily does.
     */
    public const WANTS_WATER = ['lotus', 'reed'];

    public const ARM = 0;
    public const BACK = 1;

    /** Where a plant of this height stands in a group. */
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
        foreach (self::SIZES as $corner => $count) {
            for ($index = 0; $index < $count; $index++) {
                $slots[] = ['corner' => $corner, 'index' => $index];
            }
        }
        return $slots;
    }

    /**
     * Where a slot's place is in the table. A planting filed before 2 October
     * 2026 can hold an index its group no longer has (an arm of what was the
     * fourth corner's three, now the echo), and reads as standing on the
     * group's last place until the replant places it again.
     */
    public static function row(int $corner, int $index): int
    {
        $first = 0;
        for ($c = 0; $c < $corner; $c++) $first += self::SIZES[$c];
        return $first + min($index, self::SIZES[$corner] - 1);
    }

    /** Whether a slot is the back of its group, as the table says. */
    public static function standOf(int $corner, int $index): int
    {
        return QuietRoomTable::PLACES[0][self::row($corner, $index)][3] === 1 ? self::BACK : self::ARM;
    }

    /**
     * Where a slot is, in metres from the middle of the plot **as the table
     * draws it**, before the room is turned: [x, z].
     */
    public static function spot(int $corner, int $index): array
    {
        $place = QuietRoomTable::PLACES[0][self::row($corner, $index)];
        return [$place[0], $place[1]];
    }

    /** The variant of a plot: which way round its room is laid. */
    public static function variant(int $plot): array
    {
        return PlotVariant::of($plot, 'peace', self::VARIANTS);
    }

    /**
     * **Where a planting stands on its plot**: its place and its nudge, the
     * sum turned and mirrored as the room is laid. The Swift's
     * `Planting.spot`, to the bit.
     */
    public static function spotOn(int $plot, int $corner, int $index, float $nudgeX, float $nudgeZ): array
    {
        [$x, $z] = self::spot($corner, $index);
        return PlotVariant::apply(self::variant($plot), $x + $nudgeX, $z + $nudgeZ);
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
     * colour (the five, the three, then the echo, which shows the five's), a
     * group nobody has planted (the five, then the three), a group of a colour
     * near its own, or a new plot.
     */
    public static function place(array $room, float $height, int $family,
                                 string $habit = ''): array
    {
        $plots = self::plots($room);
        // A plant that wants water goes in water. The colour rules below are
        // about groups and a lily is not in a group — it is in the pool, and
        // the pool is the only place in this room it can stand. So it is asked
        // first and separately: the first plot with a free place in its water,
        // or a new plot if every pool is full.
        if (in_array($habit, self::WANTS_WATER, true)) {
            for ($plot = 0; $plot < $plots; $plot++) {
                $taken = [];
                foreach ($room as $p) {
                    if ($p['plot'] === $plot) $taken[$p['corner'] . ':' . $p['index']] = true;
                }
                foreach (self::slots() as $slot) {
                    if ($slot['corner'] !== self::POOL) continue;
                    if (!isset($taken[$slot['corner'] . ':' . $slot['index']])) {
                        return [$plot, $slot];
                    }
                }
            }
            return [$plots, ['corner' => self::POOL, 'index' => 0]];
        }
        foreach (['own', 'fresh', 'near'] as $kinship) {
            for ($plot = 0; $plot < $plots; $plot++) {
                $slot = self::slotIn($room, $plot, $height, $family, $kinship);
                if ($slot !== null) return [$plot, $slot];
            }
        }
        return [$plots, ['corner' => self::BENCH, 'index' => 0]];
    }

    /** Plants one arrival and returns the planting; the room only grows. */
    public static function plant(array $room, string $seedHex, float $height, int $family,
                                 string $habit = ''): array
    {
        [$plot, $slot] = self::place($room, $height, $family, $habit);
        $bytes = array_values(unpack('C*', hex2bin($seedHex)));
        $jitter = fn(int $i, float $reach) => isset($bytes[$i]) ? ($bytes[$i] / 255 - 0.5) * 2 * $reach : 0.0;
        // A lily takes no nudge: the water is small enough that where two of
        // them float is a decision and not a chance, and 0.13 m either way
        // would put their pads over each other more often than not.
        $reach = self::isDry($slot['corner']) ? 0.13 : 0.0;
        return [
            'seed' => $seedHex, 'plot' => $plot,
            'corner' => $slot['corner'], 'index' => $slot['index'],
            'height' => $height, 'family' => $family, 'habit' => $habit,
            'nudgeX' => $jitter(22, $reach), 'nudgeZ' => $jitter(23, $reach),
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
        // The echo shows the five's colour: the five's first plant claims both.
        $five = null;
        foreach ($here as $p) {
            if ($p['corner'] === self::FIVE) { $five = $p['family']; break; }
        }

        foreach ($stands as $wanted) {
            foreach (self::GROUPS as $corner) {
                $group = array_values(array_filter($here, fn($p) => $p['corner'] === $corner));
                $claim = $corner === self::ECHO ? $five : ($group[0]['family'] ?? null);
                if ($kinship === 'own') {
                    if ($claim !== $family) continue;
                } elseif ($kinship === 'fresh') {
                    if (!self::isGroup($corner) || $group !== []) continue;
                } else {
                    if ($claim === null || !in_array($family, self::near($claim), true)) continue;
                }
                foreach (self::slots() as $slot) {
                    if ($slot['corner'] !== $corner) continue;
                    if (self::standOf($slot['corner'], $slot['index']) !== $wanted) continue;
                    if (isset($taken[$slot['corner'] . ':' . $slot['index']])) continue;
                    if (!self::inOrder($group, $height, $slot['corner'], $slot['index'])) continue;
                    return $slot;
                }
            }
        }
        return null;
    }

    /**
     * Whether a plant this tall can stand in this slot: nothing at the back of
     * a group is shorter than anything in its arms. The Long Walk's rule at the
     * scale of a group; two at the back of the five are free of each other, and
     * so are its arms.
     */
    private static function inOrder(array $group, float $height, int $corner, int $index): bool
    {
        $mine = self::standOf($corner, $index);
        foreach ($group as $other) {
            $theirs = self::standOf($other['corner'], $other['index']);
            if ($mine === self::BACK && $theirs === self::ARM && $other['height'] > $height) return false;
            if ($mine === self::ARM && $theirs === self::BACK && $other['height'] < $height) return false;
        }
        return true;
    }
}
