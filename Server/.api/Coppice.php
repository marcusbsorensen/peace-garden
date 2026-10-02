<?php
declare(strict_types=1);

require_once __DIR__ . '/PlotVariant.php';
require_once __DIR__ . '/tables/CoppiceGladeTable.php';

/**
 * The Coppice's placement rule, ported from SeedCore's
 * `WebGardens/Coppice.swift` so the plot service can run it.
 *
 * **A port, and held to the Swift.** `tools/reference/check_coppice.php` plants
 * the arrivals pinned in `tools/reference/coppice_vectors.json` and fails CI if
 * this puts any of them anywhere else. Change the Swift first, re-record, then
 * bring this along.
 *
 * **Habit picks the place; then the Crossing's loops.** Every plant in the
 * Coppice is a fern or a star. A fern takes a free stool in the oldest plot with
 * one, in the coupe holding fewest ferns on stools; failing that, the floor, one
 * fern to a coupe's floor; failing that, a new plot's middle stool. A star takes
 * its own row of the floor — the back from 1.00 m up — oldest plot first, in the
 * coupe with fewest on its floor; then the other row, if nothing would stand out
 * of order; then a new plot. **Rows outside, plots inside**, and the emptiest
 * coupe within a plot.
 *
 * **The first rule here that reads a habit**, which is a word and exact on
 * every host. The one height it weighs is on a coupe's floor, where the Cold
 * Frame's `inOrder` keeps the front row no taller than the back.
 *
 * **And the first area that knows its date.** A coupe's stage is arithmetic on
 * its place in the wood and the year (`stage`), and the year is the service's to
 * say (`yearOn`), so two visitors either side of midnight see one wood. Nothing
 * the rule decides depends on it.
 *
 * A planting here is an array: seed (hex), plot, coupe, place (0 a stool, 1 the
 * back row, 2 the front), index, height, family, habit, nudgeX, nudgeZ.
 *
 * **Where a place stands is the table's** since 2 October 2026, when the
 * coupes went round a glade (`CoppiceGladeTable`, made by
 * `tools/layouts/generate.py`): three rides meeting at the glade, a stand of
 * stools in each coupe, the stars in clumps by the rides, and each plot turned,
 * mirrored and given one of three glades by its number (`PlotVariant`). The
 * rule never reads a place, so none of that touches where a plant goes, only
 * where it is drawn — and `spot` is what the service sends.
 */
final class Coppice
{
    /** The same square every area uses. */
    public const PLOT_SIDE = 5.2;

    /**
     * How this area's plots vary, from each plot's number (`PlotVariant.php`):
     * the Swift's `variants`. Turned four ways, mirrored, and one of the wood's
     * three feature variants (`CoppiceGladeTable::PLACES`, one each).
     */
    public const VARIANTS = ['turns' => 4, 'mirror' => true, 'nudges' => 3];

    /** Three coupes of eleven: five stools, and a back row and a front row of three. */
    public const COUPES = 3;
    public const STOOLS = 5;
    public const FLOOR_ROW = 3;

    /** How far a plant stands off its place, either way, from the seed. */
    public const NUDGE = 0.06;

    /**
     * A row fills from its middle outward: the indices a row's places are
     * numbered by, in the order they fill. The table gives the stool numbered
     * `STOOL_ORDER[k]` the k-th place out from the middle of its coupe's stand,
     * and a floor place numbered `FLOOR_ORDER[k]` the k-th of its row to fill.
     */
    public const STOOL_ORDER = [2, 1, 3, 0, 4];
    public const FLOOR_ORDER = [1, 0, 2];

    /** The three places a plant can stand in a coupe. */
    public const STOOL = 0;
    public const BACK = 1;
    public const FRONT = 2;

    /** The median of the area's own stars, measured as the Cold Frame's cut was: 0.99 since 29 September 2026. */
    public const BACK_FROM = 0.99;

    /** The three stages of a coupe's rotation. */
    public const CUT = 0;
    public const REGROWING = 1;
    public const GROWN = 2;

    /** Year 0 runs from 21 December 2025 to 21 December 2026. */
    public const OPENED_IN = 2026;

    public static function row(float $height): int
    {
        return $height < self::BACK_FROM ? self::FRONT : self::BACK;
    }

    /** The one question asked of a habit. An empty habit is not a fern. */
    public static function isFern(string $habit): bool
    {
        return $habit === 'fern';
    }

    /** The variant plot `$plot` is laid in: the Swift's `Coppice.variant(ofPlot:)`. */
    public static function variant(int $plot): array
    {
        return PlotVariant::of($plot, 'renewal', self::VARIANTS);
    }

    /**
     * Where a place stands in the table's frame for feature variant `$nudge`,
     * before the plot is turned: [x, z]. Found by its tags, which every feature
     * variant lists in one order.
     */
    public static function tablePlace(int $nudge, int $coupe, int $place, int $index): array
    {
        static $at = null;
        if ($at === null) {
            $at = [];
            foreach (CoppiceGladeTable::PLACES[0] as $i => [, , $c, $p, $n]) $at["$c:$p:$n"] = $i;
        }
        if (!isset($at["$coupe:$place:$index"])) {
            throw new LogicException("the Coppice has no place $coupe:$place:$index");
        }
        $row = CoppiceGladeTable::PLACES[$nudge][$at["$coupe:$place:$index"]];
        return [$row[0], $row[1]];
    }

    /**
     * Where a planting stands on its plot: its place in the table's frame, its
     * nudge added there, and the sum turned for the plot — the Swift's
     * `Planting.spot`, exact on every host. With no nudge, where the place is.
     */
    public static function spot(int $plot, int $coupe, int $place, int $index,
                                float $nudgeX = 0.0, float $nudgeZ = 0.0): array
    {
        $variant = self::variant($plot);
        [$x, $z] = self::tablePlace($variant['nudge'], $coupe, $place, $index);
        return PlotVariant::apply($variant, $x + $nudgeX, $z + $nudgeZ);
    }

    /** `(year − (3 × plot + coupe)) mod 3`: 0 cut this winter, 1 regrowing, 2 grown. */
    public static function stage(int $plot, int $coupe, int $year): int
    {
        $n = ($year - (self::COUPES * $plot + $coupe)) % self::COUPES;
        return $n < 0 ? $n + self::COUPES : $n;
    }

    /** How many winter solstices, taken as 21 December UTC, have passed since the Coppice opened. */
    public static function year(int $utcYear, int $month, int $day): int
    {
        return $utcYear - self::OPENED_IN + ($month === 12 && $day >= 21 ? 1 : 0);
    }

    /** The year of the rotation a moment falls in, read in UTC. */
    public static function yearOn(int $time): int
    {
        return self::year((int) gmdate('Y', $time), (int) gmdate('n', $time), (int) gmdate('j', $time));
    }

    /** Plots opened so far. */
    public static function plots(array $ways): int
    {
        $max = -1;
        foreach ($ways as $p) $max = max($max, (int) $p['plot']);
        return $max + 1;
    }

    /** Whether a plant this tall can stand in this row of a coupe's floor. */
    private static function inOrder(float $height, int $row, array $floor): bool
    {
        foreach ($floor as $other) {
            if ((int) $other['place'] === $row) continue;
            if ($row === self::BACK && $height < (float) $other['height']) return false;
            if ($row === self::FRONT && $height > (float) $other['height']) return false;
        }
        return true;
    }

    /**
     * A place on the floor, or null: the plant's own row, then the other, each
     * across every open plot oldest first, and within a plot the coupe with
     * fewest on its floor that has room in the row, keeps the rows in order, and
     * passes `$room`.
     */
    private static function floor(array $byPlot, float $height, callable $room): ?array
    {
        $own = self::row($height);
        foreach ([$own, $own === self::BACK ? self::FRONT : self::BACK] as $row) {
            foreach ($byPlot as $plot => $here) {
                $best = null;
                for ($coupe = 0; $coupe < self::COUPES; $coupe++) {
                    $floor = array_values(array_filter($here,
                        fn($p) => (int) $p['coupe'] === $coupe && (int) $p['place'] !== self::STOOL));
                    $taken = count(array_filter($floor, fn($p) => (int) $p['place'] === $row));
                    if ($taken >= self::FLOOR_ROW || !self::inOrder($height, $row, $floor) || !$room($floor)) continue;
                    if ($best !== null && count($floor) >= $best['onFloor']) continue;
                    $best = ['coupe' => $coupe, 'taken' => $taken, 'onFloor' => count($floor)];
                }
                if ($best !== null) {
                    return [$plot, ['coupe' => $best['coupe'], 'place' => $row,
                                    'index' => self::FLOOR_ORDER[$best['taken']]]];
                }
            }
        }
        return null;
    }

    /** Where the next plant with these traits goes: [plot, slot]. */
    public static function place(array $ways, float $height, string $habit): array
    {
        $opened = self::plots($ways);
        $byPlot = array_fill(0, max(0, $opened), []);
        foreach ($ways as $p) $byPlot[(int) $p['plot']][] = $p;

        if (self::isFern($habit)) {
            for ($plot = 0; $plot < $opened; $plot++) {
                $best = null;
                for ($coupe = 0; $coupe < self::COUPES; $coupe++) {
                    $taken = count(array_filter($byPlot[$plot],
                        fn($p) => (int) $p['coupe'] === $coupe && (int) $p['place'] === self::STOOL));
                    if ($taken < self::STOOLS && ($best === null || $taken < $best['taken'])) {
                        $best = ['coupe' => $coupe, 'taken' => $taken];
                    }
                }
                if ($best !== null) {
                    return [$plot, ['coupe' => $best['coupe'], 'place' => self::STOOL,
                                    'index' => self::STOOL_ORDER[$best['taken']]]];
                }
            }
            $room = fn(array $floor) => count(array_filter($floor, fn($p) => self::isFern((string) $p['habit']))) < 1;
            if ($found = self::floor($byPlot, $height, $room)) return $found;
            return [$opened, ['coupe' => 0, 'place' => self::STOOL, 'index' => self::STOOL_ORDER[0]]];
        }

        if ($found = self::floor($byPlot, $height, fn(array $floor) => true)) return $found;
        return [$opened, ['coupe' => 0, 'place' => self::row($height), 'index' => self::FLOOR_ORDER[0]]];
    }

    /** Plants one arrival and returns the planting; the area only grows. */
    public static function plant(array $ways, string $seedHex, float $height, int $family, string $habit): array
    {
        [$plot, $slot] = self::place($ways, $height, $habit);
        $bytes = array_values(unpack('C*', hex2bin($seedHex)));
        $jitter = fn(int $i) => isset($bytes[$i]) ? ($bytes[$i] / 255 - 0.5) * 2 * self::NUDGE : 0.0;
        return [
            'seed' => $seedHex, 'plot' => $plot,
            'coupe' => $slot['coupe'], 'place' => $slot['place'], 'index' => $slot['index'],
            'height' => $height, 'family' => $family, 'habit' => $habit,
            'nudgeX' => $jitter(26), 'nudgeZ' => $jitter(27),
        ];
    }
}
