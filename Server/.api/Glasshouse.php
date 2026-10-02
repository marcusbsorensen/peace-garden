<?php
declare(strict_types=1);

require_once __DIR__ . '/LongWalk.php';

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
 * arrival.** A plant of 1.14 m or more stands in the soil border along the back,
 * in the next place from the door. Anything shorter goes in a pot on the
 * staging, which is a spectrum: twelve positions, each standing for a twelfth of
 * the area's hued plants, blue-green at the door and yellow at the far end. A
 * pot looks for its own band in every open plot, oldest first; then one band
 * off, the side its hue leans to first; then opens a new plot. A pale plant, or
 * one whose hue was never sent, takes the first free pot from the door.
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
     * the Swift's `variants`. Fixed: a colour wheel has one way round. Declared
     * but not yet read.
     */
    public const VARIANTS = ['turns' => 1, 'mirror' => false, 'nudges' => 1];

    /**
     * Twelve positions along the staging with two pots at each, and a border of
     * eight: thirty-two a plot, Marcus's choice on 23 September.
     */
    public const POSITIONS = 12;
    public const ROWS = 2;
    public const BORDER_PLACES = 8;

    /**
     * The house, in metres. Not read by the rule; here so the check can hold
     * every place inside it.
     */
    public const HOUSE_LENGTH = 4.4;
    public const HOUSE_WIDTH = 3.4;

    /** The staging's middle, how far each row of pots stands from it, and the gap along it. */
    public const STAGING_Z = 1.0;
    public const ROW_FROM = 0.15;
    public const ALONG_GAP = 0.33;
    public const STAGING_TOP = 0.70;
    public const POT_SOIL = 0.13;

    /** The border along the back, and the gap between its places. */
    public const BORDER_Z = -1.15;
    public const BORDER_GAP = 0.50;

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

    /** The band a hue belongs to, 0 at the door to 11: how many edges it lies at or past. */
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
     * Where a place is, in metres from the middle of its plot: [x, z]. Index 0
     * is at the door, the house's `x−` end, in both beds.
     */
    public static function spot(int $bed, int $index, int $row): array
    {
        if ($bed === self::BORDER) {
            return [($index - (self::BORDER_PLACES - 1) / 2) * self::BORDER_GAP, self::BORDER_Z];
        }
        return [
            ($index - (self::POSITIONS - 1) / 2) * self::ALONG_GAP,
            self::STAGING_Z + ($row === 0 ? self::ROW_FROM : -self::ROW_FROM),
        ];
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
     * The border: the next place from the door in the oldest plot with one, or
     * a new plot. The staging: its own band in every open plot, oldest first;
     * then one band off, never across the cut; then a new plot at its own band.
     * A plant with no place on the spectrum takes the first free pot from the
     * door, oldest plot first.
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

        // The next free pot at this position in this plot, or null. A position
        // fills its glass row first, so the row is how many stand there already.
        $free = function (int $position, int $plot) use ($byPlot): ?array {
            $taken = count(array_filter($byPlot[$plot],
                fn($p) => (int) $p['bed'] === self::STAGING && (int) $p['index'] === $position));
            return $taken < self::ROWS ? ['bed' => self::STAGING, 'index' => $position, 'row' => $taken] : null;
        };

        if (self::isUnplaced($family, $hue)) {
            for ($plot = 0; $plot < $opened; $plot++) {
                for ($position = 0; $position < self::POSITIONS; $position++) {
                    if ($slot = $free($position, $plot)) return [$plot, $slot];
                }
            }
            return [$opened, ['bed' => self::STAGING, 'index' => 0, 'row' => 0]];
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
