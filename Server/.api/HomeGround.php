<?php
declare(strict_types=1);

require_once __DIR__ . '/PlotVariant.php';
require_once __DIR__ . '/tables/HomeGroundCerTable.php';
require_once __DIR__ . '/tables/HomeGroundFenTable.php';
require_once __DIR__ . '/tables/HomeGroundPellTable.php';

/**
 * The Home Ground's placement rule, ported from SeedCore's
 * `WebGardens/HomeGround.swift` so the plot service can run it.
 *
 * **A port, and held to the Swift.** `tools/reference/check_home_ground.php`
 * plants the arrivals pinned in `tools/reference/home_ground_vectors.json` and
 * fails CI if this puts any of them anywhere else. Change the Swift first,
 * re-record, then bring this along.
 *
 * **The crop decides the bed, the height decides the end.** The crop is the
 * genus root — `Cer`, `Fen` or `Pell` — and it is read off the habit, which
 * names it exactly in this area: a spire is a `Cer`, an umbel a `Fen`, a
 * succulent a `Pell`, and a habit never sent is sown as an umbel. A plant takes
 * a bed already sown with its crop and not full, oldest plot first, beds west to
 * east; then the first bed nobody has sown, which takes its crop's spacing from
 * then on; then a new plot's west bed. Within the bed a plant at least as tall
 * as its crop's cut takes the first free place from the north end, and a
 * shorter one the first free place from the south.
 *
 * **A height is compared only with a cut, never with another plant**, and a
 * habit is a word, exact on every host. Nothing about a plant already standing
 * is read but where it stands and the crop of its bed.
 *
 * **Lazy beds since 2 October 2026**: the beds sway together in a lazy S with
 * the rows square to it, and a plot is mirrored or not by its number, so the
 * sway alternates. Where each place stands is a crop's table made offline
 * (`tables/HomeGround{Cer,Fen,Pell}Table.php`, from
 * `tools/layouts/tables/home_ground_*.py`). The rule did not change, so every
 * slot is the slot it was.
 *
 * A planting here is an array: seed (hex), plot, bed, crop, index, height,
 * family, habit, nudgeX, nudgeZ.
 */
final class HomeGround
{
    /** The same square every area uses. */
    public const PLOT_SIDE = 5.2;

    /**
     * How this area's plots vary, from each plot's number (`PlotVariant.php`):
     * the Swift's `variants`. Mirrored only, so north stays north, and a space
     * of two alternates plot by plot: the beds sway one way and then the other.
     */
    public const VARIANTS = ['turns' => 1, 'mirror' => true, 'nudges' => 1];

    /** Three beds, 1.2 m wide, swaying about these lines across the plot; north is `z−`. */
    public const BEDS = 3;
    public const BED_X = [-1.65, 0.0, 1.65];

    /** How far a plant stands off its place, from the seed: along the row, and down the bed. */
    public const NUDGE_ACROSS = 0.05;
    public const NUDGE_DOWN = 0.025;

    /**
     * Each crop's spacing and cut: plants across a row, the gap between them,
     * rows down the bed, the gap between those, and the height from which a
     * plant takes the north end. The umbel's cut is 0.930, moved off the
     * measured 0.932 where an arrival stood 0.009 mm from it. The spire's and
     * the rosette's were measured again on 29 September 2026, after the
     * re-roll: 1.261 (was 1.346) and 0.266 (was 0.275).
     */
    public const CROPS = [
        'Cer' => ['across' => 3, 'gap' => 0.40, 'rows' => 9, 'rowGap' => 0.45, 'cut' => 1.261],
        'Fen' => ['across' => 2, 'gap' => 0.60, 'rows' => 7, 'rowGap' => 0.60, 'cut' => 0.930],
        'Pell' => ['across' => 3, 'gap' => 0.38, 'rows' => 10, 'rowGap' => 0.40, 'cut' => 0.266],
    ];

    /** The crop a habit names. An empty or unknown habit is sown as an umbel. */
    public static function crop(string $habit): string
    {
        return match ($habit) {
            'spire' => 'Cer',
            'succulent' => 'Pell',
            default => 'Fen',
        };
    }

    public static function capacity(string $crop): int
    {
        return self::CROPS[$crop]['across'] * self::CROPS[$crop]['rows'];
    }

    /** Whether a plant this tall takes the north end of its crop's bed. */
    public static function north(string $crop, float $height): bool
    {
        return $height >= self::CROPS[$crop]['cut'];
    }

    /**
     * Where a place is, in metres from the middle of its plot, as the table
     * draws the plot: [x, z]. The crop's table holds every bed's places, bed
     * by bed, each in the slots' order, to the millimetre.
     */
    public static function spot(int $bed, string $crop, int $index): array
    {
        $places = match ($crop) {
            'Cer' => HomeGroundCerTable::PLACES[0],
            'Pell' => HomeGroundPellTable::PLACES[0],
            default => HomeGroundFenTable::PLACES[0],
        };
        $place = $places[$bed * self::capacity($crop) + $index];
        return [$place[0], $place[1]];
    }

    /**
     * Where a planting stands: its place and its nudge added as the table draws
     * the plot, then the sum mirrored if the plot is (`PlotVariant.php`). In
     * that order because the nudge is narrower one way than the other, and it
     * turns with its row.
     */
    public static function spotOf(int $plot, int $bed, string $crop, int $index, float $nudgeX, float $nudgeZ): array
    {
        [$x, $z] = self::spot($bed, $crop, $index);
        return PlotVariant::apply(PlotVariant::of($plot, 'ground', self::VARIANTS), $x + $nudgeX, $z + $nudgeZ);
    }

    /** Plots opened so far. */
    public static function plots(array $ways): int
    {
        $max = -1;
        foreach ($ways as $p) $max = max($max, (int) $p['plot']);
        return $max + 1;
    }

    /**
     * The first free place in a bed counted from one end, or null if the bed
     * is full: 0, 1, 2… from the north; the last place, the one before it…
     * from the south.
     */
    private static function next(array $here, int $bed, string $crop, bool $north): ?int
    {
        $taken = [];
        foreach ($here as $p) {
            if ((int) $p['bed'] === $bed) $taken[(int) $p['index']] = true;
        }
        $capacity = self::capacity($crop);
        if ($north) {
            for ($i = 0; $i < $capacity; $i++) if (!isset($taken[$i])) return $i;
        } else {
            for ($i = $capacity - 1; $i >= 0; $i--) if (!isset($taken[$i])) return $i;
        }
        return null;
    }

    /** Where the next plant with these traits goes: [plot, slot]. */
    public static function place(array $ways, float $height, string $habit): array
    {
        $crop = self::crop($habit);
        $north = self::north($crop, $height);
        $first = $north ? 0 : self::capacity($crop) - 1;
        $opened = self::plots($ways);
        $byPlot = array_fill(0, max(0, $opened), []);
        foreach ($ways as $p) $byPlot[(int) $p['plot']][] = $p;

        // Each bed's crop, read off the first plant sown in it.
        $claims = [];
        for ($plot = 0; $plot < $opened; $plot++) {
            $claims[$plot] = array_fill(0, self::BEDS, null);
            foreach ($byPlot[$plot] as $p) {
                $bed = (int) $p['bed'];
                if ($claims[$plot][$bed] === null) $claims[$plot][$bed] = (string) $p['crop'];
            }
        }

        for ($plot = 0; $plot < $opened; $plot++) {
            for ($bed = 0; $bed < self::BEDS; $bed++) {
                if ($claims[$plot][$bed] !== $crop) continue;
                $index = self::next($byPlot[$plot], $bed, $crop, $north);
                if ($index !== null) return [$plot, ['bed' => $bed, 'crop' => $crop, 'index' => $index]];
            }
        }
        for ($plot = 0; $plot < $opened; $plot++) {
            for ($bed = 0; $bed < self::BEDS; $bed++) {
                if ($claims[$plot][$bed] === null) return [$plot, ['bed' => $bed, 'crop' => $crop, 'index' => $first]];
            }
        }
        return [$opened, ['bed' => 0, 'crop' => $crop, 'index' => $first]];
    }

    /** Plants one arrival and returns the planting; the area only grows. */
    public static function plant(array $ways, string $seedHex, float $height, int $family, string $habit): array
    {
        [$plot, $slot] = self::place($ways, $height, $habit);
        $bytes = array_values(unpack('C*', hex2bin($seedHex)));
        $jitter = fn(int $i, float $reach) => isset($bytes[$i]) ? ($bytes[$i] / 255 - 0.5) * 2 * $reach : 0.0;
        return [
            'seed' => $seedHex, 'plot' => $plot,
            'bed' => $slot['bed'], 'crop' => $slot['crop'], 'index' => $slot['index'],
            'height' => $height, 'family' => $family, 'habit' => $habit,
            'nudgeX' => $jitter(26, self::NUDGE_ACROSS), 'nudgeZ' => $jitter(27, self::NUDGE_DOWN),
        ];
    }
}
