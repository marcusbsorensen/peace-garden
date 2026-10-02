<?php
declare(strict_types=1);

require_once __DIR__ . '/LongWalk.php';
require_once __DIR__ . '/PlotVariant.php';
require_once __DIR__ . '/tables/GlasshouseWheelTable.php';

/**
 * The Glasshouse's placement rule, ported from SeedCore's
 * `WebGardens/Glasshouse.swift` so the plot service can run it.
 *
 * **A port, and held to the Swift.** The server is PHP and cannot run SeedCore,
 * so this is a second copy of the rule, and a copy drifts unless something
 * checks it: `tools/reference/check_glasshouse.php` plants the arrivals pinned
 * in `tools/reference/glasshouse_vectors.json` and fails CI if this puts any of
 * them anywhere else. Change the Swift first, re-record, then bring this along.
 *
 * **Height picks the bed; then the staging sorts by hue and the border by
 * arrival.** A plant of 1.16 m or more stands in the round soil bed in the
 * middle of the house, in the bed's next place (its middle first, then
 * farthest-first). Anything shorter goes in a pot on the ring of staging,
 * which is a colour wheel: twelve bands, each standing for a twelfth of the
 * area's hued plants, blue-green just past the door and yellow just before it.
 * A pot looks for its own band in every open plot, oldest first; then one band
 * off, the side its hue leans to first, never across the door; then opens a
 * new plot. A pale plant, or one whose hue was never sent, takes the first free
 * pot in the table's offer order: the pot opposite the door, then
 * farthest-first.
 *
 * **Where each place stands is a table made offline** (`GlasshouseWheelTable`,
 * from `tools/layouts/tables/glasshouse_wheel.py`), the colour wheel Marcus
 * chose on 2 October 2026: the same literals SeedCore reads, so a spot here is
 * the same double as there.
 *
 * **The first rule here that reads a hue**, and the first number this service
 * compares that no host can round differently. A hue is the seed's bytes
 * through `+ − × ÷` on the phone, it arrives as that exact double, and
 * `along` below is one subtraction and at most one addition in the Swift's
 * order — so a plant cannot stand one side of a band edge in SeedCore and the
 * other side here. That is why the edges have no tolerance, and why the check
 * compares every placement exactly.
 *
 * Kept to the Swift's arithmetic in the Swift's order, and to its loop order:
 * **bands outside, plots inside** on the staging — a pot tries its own band in
 * every plot before it tries a neighbour in any.
 *
 * A planting here is an array: seed (hex), plot, bed (0 staging, 1 border),
 * index, row, height, family, hue (a turn, or null), nudgeX, nudgeZ.
 */
final class Glasshouse
{
    /** The same square every area uses. */
    public const PLOT_SIDE = 5.2;

    /**
     * How this area's plots vary, from each plot's number (`PlotVariant.php`):
     * the Swift's `variants`. Fixed: a colour wheel has one way round. Read by
     * `standing`, which lays every plot as the plan is drawn.
     */
    public const VARIANTS = ['turns' => 1, 'mirror' => false, 'nudges' => 1];

    /**
     * Twelve bands round the staging with two pots in each, and a border of
     * eight: thirty-two a plot, Marcus's choice on 23 September.
     */
    public const POSITIONS = 12;
    public const ROWS = 2;
    public const BORDER_PLACES = 8;

    /**
     * The house, in metres: its wall's radius (which wanders outward from this
     * by up to 4 cm, never in), its eaves and its crown. Not read by the rule;
     * here so the check can hold every place inside it and under it.
     */
    public const HOUSE_RADIUS = 2.2;
    public const EAVES = 2.2;
    public const CROWN = 3.5;

    /** Where the door is, as a turn from `x+` toward `z+`: a quarter, `z+`. */
    public const DOOR_TURN = 0.25;

    /** The ring of staging: its middle's radius, its depth and its top; the soil in a pot. */
    public const STAGING_RADIUS = 1.80;
    public const STAGING_DEPTH = 0.40;
    public const STAGING_TOP = 0.70;
    public const POT_SOIL = 0.13;
    public const POT_GAP = 0.43;

    /** The round bed in the middle. */
    public const BED_RADIUS = 0.85;

    /** The two beds. */
    public const STAGING = 0;
    public const BORDER = 1;

    /**
     * **The tallest quarter of this area's own plants**: their 75th centile,
     * 1.139 m, set at 1.14. It was the Orchard's crown, 1.30, borrowed, until
     * the plants' shapes changed on 24 September 2026 and the two numbers
     * parted. `Glasshouse.borderFrom` in the Swift; the check holds it to the
     * vector file. **1.16 since 29 September 2026**, measured again after the
     * re-roll: 1.160 m.
     */
    public const BORDER_FROM = 1.16;

    /** Where the circle is cut, as a turn: 114°, in the green no flower here is. */
    public const CUT = 114.0 / 360.0;

    /**
     * The eleven edges between twelve bands of equal share, as turns past the
     * cut. Measured on 2,864 hued plants of this area's own; see the Swift for
     * the sample and why the five hundred in the vector file are not it.
     */
    public const BAND_EDGES = [0.146, 0.213, 0.283, 0.350, 0.422, 0.492, 0.560, 0.643, 0.727, 0.795, 0.877];

    public static function bed(float $height): int
    {
        return $height < self::BORDER_FROM ? self::STAGING : self::BORDER;
    }

    /** How far past the cut a hue lies, going round: 0 at the cut, just under 1 at its far side. */
    public static function along(float $hue): float
    {
        return $hue >= self::CUT ? $hue - self::CUT : $hue - self::CUT + 1;
    }

    /** The band a hue belongs to, 0 just past the door to 11 just before it: how many edges it lies at or past. */
    public static function band(float $hue): int
    {
        $u = self::along($hue);
        $count = 0;
        foreach (self::BAND_EDGES as $edge) {
            if ($u >= $edge) $count++;
        }
        return $count;
    }

    /** Whether a hue lies in the upper half of its band, nearer the band after it. */
    public static function leansOn(float $hue): bool
    {
        $u = self::along($hue);
        $b = self::band($hue);
        $low = $b === 0 ? 0.0 : self::BAND_EDGES[$b - 1];
        $high = $b === count(self::BAND_EDGES) ? 1.0 : self::BAND_EDGES[$b];
        return $u - $low >= $high - $u;
    }

    /** A pale flower, or one whose hue was never sent: it takes any free pot. */
    public static function isUnplaced(int $family, ?float $hue): bool
    {
        return $family === LongWalk::PALE_FAMILY || $hue === null;
    }

    /**
     * Where a place is, in metres from the middle of its plot, as the table
     * has it: [x, z]. On the staging `index` is the band and `row` which of its
     * two pots; in the border `index` is the place's turn in the bed's order.
     */
    public static function spot(int $bed, int $index, int $row): array
    {
        $at = self::places()[$bed][$index][$bed === self::STAGING ? $row : 0] ?? null;
        if ($at === null) {
            throw new InvalidArgumentException("The Glasshouse has no place $bed/$index/$row.");
        }
        return $at;
    }

    /**
     * **Where a planting stands**: its place and its nudge, as the plot's
     * variant lays them — which here is always the plan as drawn. The Swift's
     * `Planting.spot`, in its order: the nudge added in the table's frame,
     * then the sum turned.
     */
    public static function standing(int $plot, int $bed, int $index, int $row, float $nudgeX, float $nudgeZ): array
    {
        [$x, $z] = self::spot($bed, $index, $row);
        return PlotVariant::apply(PlotVariant::of($plot, 'light', self::VARIANTS), $x + $nudgeX, $z + $nudgeZ);
    }

    /**
     * **The order a pot with no place on the spectrum is offered the staging
     * in**, as [index, row] pairs: the table's own order, the pot opposite the
     * door first, then farthest-first.
     */
    public static function paleOrder(): array
    {
        static $order = null;
        if ($order === null) {
            $order = [];
            foreach (GlasshouseWheelTable::PLACES[0] as [$x, $z, $bed, $index, $row]) {
                if ($bed === self::STAGING) $order[] = [$index, $row];
            }
        }
        return $order;
    }

    /** The table's places by bed, index and row: [bed][index][row] => [x, z]. */
    private static function places(): array
    {
        static $places = null;
        if ($places === null) {
            $places = [];
            foreach (GlasshouseWheelTable::PLACES[0] as [$x, $z, $bed, $index, $row]) {
                $places[$bed][$index][$row] = [$x, $z];
            }
        }
        return $places;
    }

    /** How far off the floor a plant in this bed stands: the soil in its pot, or none. */
    public static function lift(int $bed): float
    {
        return $bed === self::STAGING ? self::STAGING_TOP + self::POT_SOIL : 0.0;
    }

    /** Plots opened so far. */
    public static function plots(array $ways): int
    {
        $max = -1;
        foreach ($ways as $p) $max = max($max, (int) $p['plot']);
        return $max + 1;
    }

    /**
     * Where the next plant with these traits goes: [plot, slot].
     *
     * The border: the bed's next place in the oldest plot with one, or a new
     * plot. The staging: its own band in every open plot, oldest first; then
     * one band off, never across the cut; then a new plot at its own band. A
     * plant with no place on the spectrum takes the first free pot in
     * `paleOrder`, oldest plot first, or a new plot at the first of them.
     */
    public static function place(array $ways, float $height, int $family, ?float $hue): array
    {
        $opened = self::plots($ways);
        $byPlot = array_fill(0, max(0, $opened), []);
        foreach ($ways as $p) $byPlot[(int) $p['plot']][] = $p;

        if (self::bed($height) === self::BORDER) {
            for ($plot = 0; $plot < $opened; $plot++) {
                $taken = count(array_filter($byPlot[$plot], fn($p) => (int) $p['bed'] === self::BORDER));
                if ($taken < self::BORDER_PLACES) {
                    return [$plot, ['bed' => self::BORDER, 'index' => $taken, 'row' => 0]];
                }
            }
            return [$opened, ['bed' => self::BORDER, 'index' => 0, 'row' => 0]];
        }

        // The next free pot in this band in this plot, or null. A band fills
        // its row 0 first, so the row is how many stand there already.
        $free = function (int $position, int $plot) use ($byPlot): ?array {
            $taken = count(array_filter($byPlot[$plot],
                fn($p) => (int) $p['bed'] === self::STAGING && (int) $p['index'] === $position));
            return $taken < self::ROWS ? ['bed' => self::STAGING, 'index' => $position, 'row' => $taken] : null;
        };

        if (self::isUnplaced($family, $hue)) {
            for ($plot = 0; $plot < $opened; $plot++) {
                $taken = [];
                foreach ($byPlot[$plot] as $p) {
                    if ((int) $p['bed'] === self::STAGING) $taken[(int) $p['index'] . '/' . (int) $p['row']] = true;
                }
                foreach (self::paleOrder() as [$index, $row]) {
                    if (!isset($taken["$index/$row"])) {
                        return [$plot, ['bed' => self::STAGING, 'index' => $index, 'row' => $row]];
                    }
                }
            }
            [$index, $row] = self::paleOrder()[0];
            return [$opened, ['bed' => self::STAGING, 'index' => $index, 'row' => $row]];
        }

        $own = self::band($hue);
        for ($plot = 0; $plot < $opened; $plot++) {
            if ($slot = $free($own, $plot)) return [$plot, $slot];
        }
        $near = self::leansOn($hue) ? [$own + 1, $own - 1] : [$own - 1, $own + 1];
        $neighbours = array_values(array_filter($near, fn($p) => $p >= 0 && $p < self::POSITIONS));
        for ($plot = 0; $plot < $opened; $plot++) {
            foreach ($neighbours as $position) {
                if ($slot = $free($position, $plot)) return [$plot, $slot];
            }
        }
        return [$opened, ['bed' => self::STAGING, 'index' => $own, 'row' => 0]];
    }

    /**
     * Plants one arrival and returns the planting; the area only grows.
     *
     * The nudge is 0.015 m either way on the staging, where a pot stands in
     * line with its neighbours, and 0.05 m in the border, which is planted by
     * eye.
     */
    public static function plant(array $ways, string $seedHex, float $height, int $family, ?float $hue): array
    {
        [$plot, $slot] = self::place($ways, $height, $family, $hue);
        $bytes = array_values(unpack('C*', hex2bin($seedHex)));
        $reach = $slot['bed'] === self::STAGING ? 0.015 : 0.05;
        $jitter = fn(int $i) => isset($bytes[$i]) ? ($bytes[$i] / 255 - 0.5) * 2 * $reach : 0.0;
        return [
            'seed' => $seedHex, 'plot' => $plot,
            'bed' => $slot['bed'], 'index' => $slot['index'], 'row' => $slot['row'],
            'height' => $height, 'family' => $family, 'hue' => $hue,
            'nudgeX' => $jitter(26), 'nudgeZ' => $jitter(27),
        ];
    }
}
