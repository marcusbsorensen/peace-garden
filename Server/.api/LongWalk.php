<?php
declare(strict_types=1);

require_once __DIR__ . '/PlotVariant.php';
require_once __DIR__ . '/tables/LongWalkDriftsTable.php';

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
 * comparison is the same double: a place's `z` is compared with `<=` against a
 * reach, and a last-bit difference there would move a plant.
 *
 * **Interlocking drifts, since 2 October 2026**: each border's places stand in
 * six slanting lenses from a table made offline
 * (`tables/LongWalkDriftsTable.php`). A lens is claimed by the colour family of
 * the first plant sown in it and holds only that colour; a warm colour claims
 * lenses from the plot's middle out and a cool one from its ends in; a colour
 * never claims the lens beside one it holds, in its plot or across the join with
 * the next; and plots are turned half round and mirrored by their number
 * (`VARIANTS`). The Swift says why.
 *
 * A planting here is an array: seed (hex), plot, side (-1 or 1), tier (0 edge,
 * 1 middle, 2 back), index (the place's number in the table), height, family,
 * nudgeX, nudgeZ.
 */
final class LongWalk
{
    public const PLANTED_LENGTH = 4.8;

    /**
     * How this area's plots vary, from each plot's number (`PlotVariant.php`):
     * the Swift's `variants`. Half turns and mirrors only, so the path stays
     * where it runs down the walk.
     */
    public const VARIANTS = ['turns' => 2, 'mirror' => true, 'nudges' => 1];
    public const ORDER_REACH = 1.3;
    public const NUDGE = 0.05;
    public const LENSES = 12;

    /** The area's name, which its plots' variants are dealt from. */
    public const AREA = 'travel';

    /// The seventh colour family: the flowers too unsaturated to have a hue at
    /// all. SeedCore's `LongWalk.paleFamily`. It is here rather than in an area
    /// of its own because the six arcs and the pale are a fact about a flower
    /// and every area that groups by colour reads the same seven.
    public const PALE_FAMILY = 6;

    /** The cuts, 0.75 and 1.18 since they were measured again on 29 September 2026. */
    public static function tier(float $height): int
    {
        if ($height < 0.75) return 0;
        if ($height < 1.18) return 1;
        return 2;
    }

    /** The warm colours, families 0, 1 and 5: they claim lenses from the middle of a plot out. */
    public static function isWarm(int $family): bool
    {
        return $family === 0 || $family === 1 || $family === 5;
    }

    /**
     * The order a colour claims lenses in: a warm colour as the table numbers
     * them, middle first; a cool one the same groups of four the other way round.
     */
    public static function claimOrder(bool $warm): array
    {
        return $warm ? range(0, self::LENSES - 1) : [8, 9, 10, 11, 4, 5, 6, 7, 0, 1, 2, 3];
    }

    /**
     * Every place in one plot, in the table's order: [side, tier, index, lens,
     * along, x, z], `x` and `z` in the table, before the plot is turned.
     */
    public static function slots(): array
    {
        static $slots = null;
        if ($slots !== null) return $slots;
        $slots = [];
        foreach (LongWalkDriftsTable::PLACES[0] as $index => [$x, $z, $side, $lens, $tier, $along]) {
            $slots[] = ['side' => $side, 'tier' => $tier, 'index' => $index, 'lens' => $lens,
                        'along' => $along, 'x' => $x, 'z' => $z];
        }
        return $slots;
    }

    /** Each lens's places, in the table's order. */
    private static function placesIn(int $lens): array
    {
        static $in = null;
        if ($in === null) {
            $in = array_fill(0, self::LENSES, []);
            foreach (self::slots() as $slot) $in[$slot['lens']][] = $slot['index'];
        }
        return $in[$lens];
    }

    /** A lens's side and where it comes in its border from the head of the plot. */
    private static function lens(int $lens): array
    {
        $slot = self::slots()[self::placesIn($lens)[0]];
        return [$slot['side'], $slot['along']];
    }

    /** The variant a plot is laid with, from its number. */
    public static function variant(int $plot): array
    {
        return PlotVariant::of($plot, self::AREA, self::VARIANTS);
    }

    /** Where a lens is on the walk as drawn: [side, along], once its plot is turned. */
    private static function onTheWalk(int $lens, int $plot): array
    {
        [$side, $along] = self::lens($lens);
        [$x, $z] = PlotVariant::apply(self::variant($plot), (float) $side, $along - 2.5);
        return [$x < 0 ? -1 : 1, (int) ($z + 2.5)];
    }

    /**
     * Where a planting stands in its plot: its place, nudged, turned as its
     * plot is — in the Swift's order, so it is the same double. [x, z].
     */
    public static function spot(int $plot, int $index, float $nudgeX = 0.0, float $nudgeZ = 0.0): array
    {
        $slot = self::slots()[$index];
        return PlotVariant::apply(self::variant($plot), $slot['x'] + $nudgeX, $slot['z'] + $nudgeZ);
    }

    /** Plots opened so far. */
    public static function plots(array $walk): int
    {
        $max = -1;
        foreach ($walk as $p) $max = max($max, $p['plot']);
        return $max + 1;
    }

    /**
     * Where the next plant with these traits goes: [plot, slot]. In each plot
     * from the oldest: a lens its colour has claimed, in its own tier; a lens
     * nobody has claimed, in its own tier, in its colour's order and never
     * beside a lens of its colour; a lens its colour has claimed, in the tier
     * beside. Then a new plot.
     */
    public static function place(array $walk, float $height, int $family): array
    {
        $own = self::tier($height);
        $beside = array_values(array_filter([0, 1, 2], fn($t) => abs($t - $own) === 1));
        $order = self::claimOrder(self::isWarm($family));
        $plots = self::plots($walk);
        $state = self::read($walk, $plots + 1);

        for ($plot = 0; $plot < $plots; $plot++) {
            foreach ($order as $lens) {
                if ($state[$plot]['claims'][$lens] !== $family) continue;
                $slot = self::open($lens, $state[$plot], [$own], $height);
                if ($slot !== null) return [$plot, $slot];
            }
            foreach ($order as $lens) {
                if ($state[$plot]['claims'][$lens] !== null) continue;
                if (self::besideItsColour($lens, $plot, $family, $state)) continue;
                $slot = self::open($lens, $state[$plot], [$own], $height);
                if ($slot !== null) return [$plot, $slot];
            }
            foreach ($order as $lens) {
                if ($state[$plot]['claims'][$lens] !== $family) continue;
                $slot = self::open($lens, $state[$plot], $beside, $height);
                if ($slot !== null) return [$plot, $slot];
            }
        }
        foreach ($order as $lens) {
            if (self::besideItsColour($lens, $plots, $family, $state)) continue;
            $slot = self::open($lens, $state[$plots], [$own], $height);
            if ($slot !== null) return [$plots, $slot];
        }
        return [$plots, self::open($order[0], $state[$plots], [$own], $height)];
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
            'nudgeX' => $jitter(20, self::NUDGE), 'nudgeZ' => $jitter(21, self::NUDGE),
        ];
    }

    // MARK: - The rule's parts

    /** Each plot up to `count`: which places are taken, what claimed each lens, who stands there. */
    private static function read(array $walk, int $count): array
    {
        $state = array_fill(0, $count, ['taken' => [], 'claims' => array_fill(0, self::LENSES, null), 'here' => []]);
        foreach ($walk as $p) {
            if ($p['plot'] >= $count) continue;
            $lens = self::slots()[$p['index']]['lens'];
            $state[$p['plot']]['taken'][$p['index']] = true;
            if ($state[$p['plot']]['claims'][$lens] === null) $state[$p['plot']]['claims'][$lens] = $p['family'];
            $state[$p['plot']]['here'][] = $p;
        }
        return $state;
    }

    /** The first free place of these tiers in a lens, in the table's order, where the plant stands in order. */
    private static function open(int $lens, array $plot, array $tiers, float $height): ?array
    {
        foreach (self::placesIn($lens) as $index) {
            if (isset($plot['taken'][$index])) continue;
            $slot = self::slots()[$index];
            if (in_array($slot['tier'], $tiers, true) && self::inOrder($plot['here'], $height, $slot)) return $slot;
        }
        return null;
    }

    /** Whether a lens is beside one its colour holds, in its own border or across a join. */
    private static function besideItsColour(int $lens, int $plot, int $family, array $state): bool
    {
        [$side, $along] = self::lens($lens);
        for ($other = 0; $other < self::LENSES; $other++) {
            [$s, $a] = self::lens($other);
            if ($s === $side && abs($a - $along) === 1 && $state[$plot]['claims'][$other] === $family) return true;
        }
        [$drawnSide, $drawnAlong] = self::onTheWalk($lens, $plot);
        foreach ([[$plot - 1, 0, 5], [$plot + 1, 5, 0]] as [$neighbour, $end, $meets]) {
            if ($drawnAlong !== $end || $neighbour < 0 || $neighbour >= count($state)) continue;
            for ($other = 0; $other < self::LENSES; $other++) {
                if ($state[$neighbour]['claims'][$other] !== $family) continue;
                [$s, $a] = self::onTheWalk($other, $neighbour);
                if ($s === $drawnSide && $a === $meets) return true;
            }
        }
        return false;
    }

    private static function inOrder(array $here, float $height, array $slot): bool
    {
        foreach ($here as $other) {
            if ($other['side'] !== $slot['side']) continue;
            $oz = self::slots()[$other['index']]['z'];
            if (abs($oz - $slot['z']) > self::ORDER_REACH) continue;
            if ($other['tier'] > $slot['tier'] && $other['height'] < $height) return false;
            if ($other['tier'] < $slot['tier'] && $other['height'] > $height) return false;
        }
        return true;
    }
}
