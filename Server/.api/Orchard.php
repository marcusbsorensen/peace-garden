<?php
declare(strict_types=1);

require_once __DIR__ . '/LongWalk.php';
require_once __DIR__ . '/PlotVariant.php';
require_once __DIR__ . '/tables/OrchardMeadowTable.php';

/**
 * The Orchard's placement rule, ported from SeedCore's
 * `WebGardens/Orchard.swift` so the plot service can run it.
 *
 * **A port, and held to the Swift.** The server is PHP and cannot run SeedCore,
 * so this is a second copy of the rule, and a copy drifts unless something
 * checks it: `tools/reference/check_orchard.php` plants the arrivals pinned in
 * `tools/reference/orchard_vectors.json` and fails CI if this puts any of them
 * anywhere the Swift did not. Change the Swift first, re-record, then bring this
 * along.
 *
 * Kept to the Swift's arithmetic in the Swift's order, and above all to its
 * **loop order**: guild outside, rank inside. That nesting *is* the rule — the
 * Crossing's port has the same two loops the other way round, because its
 * business is keeping four beds level and this one's is finishing one guild
 * before starting the next. A port that scored every place and took the best
 * would agree about most plants and disagree about the ones that matter.
 *
 * A planting here is an array: seed (hex), plot, guild (0-4), index (0-3),
 * height, family, nudgeX, nudgeZ.
 *
 * **Where a place stands is the table's** since 2 October 2026, when the
 * Orchard became a meadow orchard (`OrchardMeadowTable`, made by
 * `tools/layouts/generate.py`): crescents turned toward the middle tree, the
 * middle tree's ring of four, and each plot turned, mirrored and nudged by its
 * number (`PlotVariant`). The rule never reads a place, so none of that touches
 * where a plant goes, only where it is drawn — and `spot` is what the service
 * sends.
 */
final class Orchard
{
    public const PLOT_SIDE = 5.2;

    /**
     * How this area's plots vary, from each plot's number (`PlotVariant.php`):
     * the Swift's `variants`. Turned four ways, mirrored, and one of the
     * meadow's three feature variants (`OrchardMeadowTable::PLACES`, one each).
     */
    public const VARIANTS = ['turns' => 4, 'mirror' => true, 'nudges' => 3];
    /** The table's numbers, for reading: the outer trunks before their nudge, a crescent's radius, the middle ring's. */
    public const TREE_FROM = 1.74;
    public const GUILD_RADIUS = 0.90;
    public const MIDDLE_RADIUS = 0.75;

    /** The cuts, measured at the 25th and 75th centiles of grown heights: 0.48 and 1.18 since 29 September 2026. */
    public const FLANK_FROM = 0.48;
    public const CROWN_FROM = 1.18;

    public const MIDDLE = 0;

    public const UNDERSTOREY = 0;
    public const FLANK = 1;
    public const CROWN = 2;

    /** Where in an outer guild a plant of this height belongs. */
    public static function rank(float $height): int
    {
        if ($height < self::FLANK_FROM) return self::UNDERSTOREY;
        return $height < self::CROWN_FROM ? self::FLANK : self::CROWN;
    }

    /**
     * Which rank a place is, or null for the four under the middle tree, which
     * are all the same distance from the plot's centre and so have no order
     * among themselves and take any plant at all.
     */
    public static function rankOf(int $guild, int $index): ?int
    {
        if ($guild === self::MIDDLE) return null;
        if ($index === 0) return self::UNDERSTOREY;
        return $index < 3 ? self::FLANK : self::CROWN;
    }

    /** Whether a plant of this rank may take this place. */
    public static function accepts(int $guild, int $index, int $rank): bool
    {
        $own = self::rankOf($guild, $index);
        return $own === null || $own === $rank;
    }

    /** Every place in one plot, guild by guild and outward within each. */
    public static function slots(): array
    {
        static $slots = null;
        if ($slots !== null) return $slots;
        $slots = [];
        foreach ([0, 1, 2, 3, 4] as $guild) {
            for ($index = 0; $index < 4; $index++) {
                $slots[] = ['guild' => $guild, 'index' => $index];
            }
        }
        return $slots;
    }

    /** The variant plot `$plot` is laid in: the Swift's `Orchard.variant(ofPlot:)`. */
    public static function variant(int $plot): array
    {
        return PlotVariant::of($plot, 'kinship', self::VARIANTS);
    }

    /**
     * Where a place stands in the table's frame for feature variant `$nudge`,
     * before the plot is turned: [x, z]. The table lists the places guild by
     * guild and index by index, as `slots()` does, and says so in its tags.
     */
    public static function tablePlace(int $nudge, int $guild, int $index): array
    {
        $row = OrchardMeadowTable::PLACES[$nudge][$guild * 4 + $index];
        if ($row[2] !== $guild || $row[3] !== $index) {
            throw new LogicException("the Orchard's table has {$row[2]}/{$row[3]} where $guild/$index belongs");
        }
        return [$row[0], $row[1]];
    }

    /**
     * Where a planting stands on its plot: its place in the table's frame, its
     * nudge added there, and the sum turned for the plot — the Swift's
     * `Planting.spot`, exact on every host. With no nudge, where the place is.
     */
    public static function spot(int $plot, int $guild, int $index, float $nudgeX = 0.0, float $nudgeZ = 0.0): array
    {
        $variant = self::variant($plot);
        [$x, $z] = self::tablePlace($variant['nudge'], $guild, $index);
        return PlotVariant::apply($variant, $x + $nudgeX, $z + $nudgeZ);
    }

    /** Where a guild's trunk stands on plot `$plot`, in metres from the middle of the plot. */
    public static function trunk(int $plot, int $guild): array
    {
        $variant = self::variant($plot);
        [, $points] = OrchardMeadowTable::CURVES['trunks'][$variant['nudge']];
        [$x, $z] = $points[$guild];
        return PlotVariant::apply($variant, $x, $z);
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
            self::UNDERSTOREY => [self::UNDERSTOREY, self::FLANK],
            self::FLANK => [self::FLANK, self::UNDERSTOREY, self::CROWN],
            default => [self::CROWN, self::FLANK],
        };
    }

    /**
     * Where the next plant with these traits goes: [plot, slot].
     *
     * The earliest guild of the oldest plot with a place free, taking the
     * plant's own rank there if it can and a rank beside its own otherwise;
     * then the next guild; then a new plot, opened under its middle tree.
     *
     * **Note the nesting.** Plot, then guild, then rank — the guild loop sits
     * outside the rank loop, which is what makes this *finish a guild* rather
     * than *find the right rank*.
     */
    public static function place(array $ways, float $height, int $family): array
    {
        $plots = self::plots($ways);
        $own = self::rank($height);
        for ($plot = 0; $plot < $plots; $plot++) {
            foreach ([0, 1, 2, 3, 4] as $guild) {
                foreach (self::ranksBeside($own) as $rank) {
                    $slot = self::slotIn($ways, $plot, $guild, $height, $rank);
                    if ($slot !== null) return [$plot, $slot];
                }
            }
        }
        return [$plots, ['guild' => self::MIDDLE, 'index' => 0]];
    }

    /** Plants one arrival and returns the planting; the area only grows. */
    public static function plant(array $ways, string $seedHex, float $height, int $family): array
    {
        [$plot, $slot] = self::place($ways, $height, $family);
        $bytes = array_values(unpack('C*', hex2bin($seedHex)));
        $jitter = fn(int $i, float $reach) => isset($bytes[$i]) ? ($bytes[$i] / 255 - 0.5) * 2 * $reach : 0.0;
        return [
            'seed' => $seedHex, 'plot' => $plot,
            'guild' => $slot['guild'], 'index' => $slot['index'],
            'height' => $height, 'family' => $family,
            'nudgeX' => $jitter(24, 0.13), 'nudgeZ' => $jitter(25, 0.13),
        ];
    }

    // MARK: - The rule's parts

    /**
     * A free place under this guild's tree that a plant of this rank and this
     * height may stand in. The first one found, in the order `slots()` lists
     * them, which is what the Swift's `first { ... }` does.
     */
    private static function slotIn(array $ways, int $plot, int $guild, float $height, int $rank): ?array
    {
        $here = array_values(array_filter($ways, fn($p) => $p['plot'] === $plot));
        $taken = [];
        foreach ($here as $p) $taken[$p['guild'] . ':' . $p['index']] = true;
        $under = array_values(array_filter($here, fn($p) => $p['guild'] === $guild));

        foreach (self::slots() as $slot) {
            if ($slot['guild'] !== $guild) continue;
            if (!self::accepts($slot['guild'], $slot['index'], $rank)) continue;
            if (isset($taken[$slot['guild'] . ':' . $slot['index']])) continue;
            if (!self::inOrder($under, $height, $slot['guild'], $slot['index'])) continue;
            return $slot;
        }
        return null;
    }

    /**
     * Whether a plant this tall can stand in this place: reading outward from
     * the middle of the plot, nothing stands in front of something shorter than
     * itself. Ranks are compared, not distances, so the two plants flanking a
     * trunk are free of each other — and a place with no rank, which is every
     * place under the middle tree, is free of everything.
     */
    /**
     * `inOrder` for `tools/reference/check_orchard.php`, which has to ask the
     * rule whether a plant *could* have stood somewhere it did not. Public
     * rather than duplicated: a second copy of this comparison in the check
     * would be a check that agrees with itself.
     */
    public static function inOrderForCheck(array $under, float $height, int $guild, int $index): bool
    {
        return self::inOrder($under, $height, $guild, $index);
    }

    private static function inOrder(array $under, float $height, int $guild, int $index): bool
    {
        $mine = self::rankOf($guild, $index);
        if ($mine === null) return true;
        foreach ($under as $other) {
            $theirs = self::rankOf($other['guild'], $other['index']);
            if ($theirs === null) continue;
            if ($mine < $theirs && $height > $other['height']) return false;
            if ($mine > $theirs && $height < $other['height']) return false;
        }
        return true;
    }
}
