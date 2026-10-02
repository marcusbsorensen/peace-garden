<?php
declare(strict_types=1);

require_once __DIR__ . '/PlotVariant.php';
require_once __DIR__ . '/tables/ColdFramePondTable.php';

/**
 * The Cold Frame's placement rule, ported from SeedCore's
 * `WebGardens/ColdFrame.swift` so the plot service can run it.
 *
 * **A port, and held to the Swift.** The server is PHP and cannot run SeedCore,
 * so this is a second copy of the rule, and a copy drifts unless something
 * checks it: `tools/reference/check_cold_frame.php` plants the arrivals pinned
 * in `tools/reference/cold_frame_vectors.json` and fails CI if this puts any of
 * them anywhere else. Change the Swift first, re-record, then bring this along.
 *
 * **Colour claims a frame and the grown height orders its ranks.** The Knot
 * Garden's claim, asked of a frame instead of a pair, and read off the plants
 * rather than stored, for the same reason: a claim that lives in a column can
 * go stale, be restored wrong, or disagree with what is standing in it. So
 * nothing here reads a claim from anywhere but the plantings it is handed.
 *
 * **The height this rule reads is the grown one.** The Cold Frame draws every
 * plant young, and the height it is drawn at is a matter for the page alone;
 * the service never hears it and nothing here would do anything with it. What
 * the phone sends is the height the plant grows to, as it is for every area, and
 * that is what decides the rank.
 *
 * Kept to the Swift's arithmetic in the Swift's order, and above all to its
 * **loop order in the first step: plot outside, frame in the middle, rank
 * inside**. A port that tried every frame's own rank before any frame's other
 * rank agrees about every plant that finds room in its own rank, which is most
 * of them, and over the recorded five hundred first diverges at arrival 198,
 * when a frame's own rank is full or out of order while a later frame of the
 * same colour has room.
 *
 * **A lotus takes two places**, since 25 September 2026: the next two its rank
 * would fill, standing centred across them (`span`). The habit is read for it,
 * and only the arriving plant's; a plant already standing says how many places
 * it holds by its span, which is stored with it.
 *
 * **A water lily is in the tank**, since 27 September 2026, and nothing else
 * is. The tank is frame 4, a fifth frame appended rather than a new kind of
 * thing, so a slot stays one set of numbers in the table and on the wire and
 * every planting already filed reads back as it did. Its rows come out of the
 * index; it has no ranks, so every place in it is rank 0. The
 * two-place rule is therefore unreachable under glass now — it stays here
 * because rows written before today hold lilies in frames 0-3 with a span of
 * two, and those must keep reading back until the replant moves them.
 *
 * **Two frames and a bigger tank since 29 September 2026** (Marcus): the
 * front row's two frames are retired and the tank took their ground, thirty-
 * nine places in six staggered rows, so the water and the frames fill in step.
 * Frames 2 and 3 still read back, and are never placed in.
 *
 * **A pond planted as a pond since 2 October 2026** (Marcus; `ColdFrame.swift`
 * says the rest). Frame 4 is the pond now, its thirty-nine places from
 * `tables/ColdFramePondTable.php`: fifteen at the margin in five clumps of
 * three, where a reed is offered a place first, and twenty-four in the open
 * water from the deepest point out, where a lily is. Each falls back to the
 * other's water (`waterOrder`). The plots are mirrored by their numbers
 * (`PlotVariant.php`), and `spotOn` is where a planting stands on its plot.
 *
 * A planting here is an array: seed (hex), plot, frame (0-1, 2-3 retired, or
 * 4 for the pond), rank (0 front, 1 back), index (0-5 in a frame, the west one
 * of a lotus's two; 0-38 in the pond), span (1, or 2 for a lotus under glass),
 * height, family, habit, nudgeX, nudgeZ. A planting with no span holds one
 * place, which is what every planting made before the lotus rule holds.
 */
final class ColdFrame
{
    /** The same square every area uses. */
    public const PLOT_SIDE = 5.2;

    /**
     * How this area's plots vary, from each plot's number (`PlotVariant.php`):
     * the Swift's `variants`. Mirrored only, so the frames stay at the back
     * under their high side.
     */
    public const VARIANTS = ['turns' => 1, 'mirror' => true, 'nudges' => 1];

    /**
     * Two ranks of six in each frame. Four frames of twelve was Marcus's
     * choice on 23 September; two, since 29 September 2026.
     */
    public const PLACES = 6;

    /**
     * A frame's outside, in metres: along the ranks, and from back to front.
     * Not read by the rule; here so the check can hold every plant inside the
     * frame it was placed in.
     */
    public const FRAME_LENGTH = 2.0;
    public const FRAME_DEPTH = 1.1;

    /**
     * Where the middles of the frames stand: either side of the plot in `x`,
     * and along the back of the yard in `z`. `FRAME_Z` was pushed out from 0.9
     * on 27 September 2026 to make room for the water, and to 1.65 on 29
     * September when the tank grew.
     */
    public const FRAME_X = 1.2;
    public const FRAME_Z = 1.65;

    /**
     * **The pond across the yard in front of the frames** (2 October 2026),
     * where the tank was: thirty-nine places, as Marcus chose for the tank on
     * 29 September, from the table. Half a metre between lilies.
     */
    public const POND_PLACES = 39;
    public const POND_GAP = 0.50;

    /**
     * The archetypes that want water. Read from the habit, which is a word.
     * `Archetype.wantsWater` in the Swift, said again here.
     *
     * **The reed since 28 September 2026**, which stands in the shallows as a
     * lily lies on the water. So a reed goes in the water and holds one place
     * there, as a lily does, and `Syr` — the reed's many-merous root — being
     * this area's makes the water the larger part of what arrives.
     */
    public const WANTS_WATER = ['lotus', 'reed'];

    /** Along a rank, between one place and the next, and how far either rank stands from the middle of its frame. */
    public const ALONG_GAP = 0.31;
    public const RANK_FROM = 0.24;

    /**
     * The four frames, in the order a plot opened them: the back row from west
     * to east, then the front row. The back row is `z−`. **Only the back row
     * is opened since 29 September 2026**; the front row's numbers are kept so
     * a planting filed in one reads back until the replant.
     */
    public const BACK_WEST = 0;
    public const BACK_EAST = 1;
    public const FRONT_WEST = 2;
    public const FRONT_EAST = 3;
    /** **The dry frames in use**, which is what every loop over "the frames" means. */
    public const FRAMES = [0, 1];
    /** The pond is a fifth frame and not a frame: the tank's number, kept. */
    public const POND = 4;

    /** The kinds of water a place in the pond is, as the table tags them. */
    public const MARGIN = 0;
    public const OPEN = 1;

    /** Whether plants that want dry compost are set in this frame. */
    public static function isDry(int $frame): bool
    {
        return $frame !== self::POND;
    }

    /** Whether this habit belongs in the water. */
    public static function wantsWater(string $habit): bool
    {
        return in_array($habit, self::WANTS_WATER, true);
    }

    /** How many places a frame holds: two ranks of six, or thirty-nine in the water. */
    public static function places(int $frame): int
    {
        return $frame === self::POND ? self::POND_PLACES : self::PLACES;
    }

    /**
     * **The order a plant that wants water is offered the pond's places**:
     * a reed the margin, clump by clump, then the open water from its outer
     * edge in; a lily the open water from the deepest point out, then the
     * margin. The Swift's `waterOrder(for:)`.
     */
    public static function waterOrder(string $habit): array
    {
        static $orders = null;
        if ($orders === null) {
            $margin = [];
            $open = [];
            foreach (ColdFramePondTable::PLACES[0] as $index => $place) {
                if ($place[2] === self::MARGIN) $margin[] = $index;
                else $open[] = $index;
            }
            $orders = ['reed' => array_merge($margin, array_reverse($open)), 'lily' => array_merge($open, $margin)];
        }
        return $habit === 'reed' ? $orders['reed'] : $orders['lily'];
    }

    /** The two ranks of a frame. The back rank is `z−` of the frame's middle, under the higher glass. */
    public const FRONT = 0;
    public const BACK = 1;
    public const RANKS = [0, 1];

    /**
     * **The median of the area's own plants**, measured over the five hundred
     * arrivals whose names put them here rather than over the whole garden, so
     * that two ranks of six divide them in half. A cut borrowed from another
     * area would not: the Orchard's 0.58 puts 12% of them at the back. 0.38 since
     * the plants' shapes changed on 24 September 2026; it was 0.85.
     *
     * **0.50 since the tank was sunk on 27 September 2026.** The cut divides
     * the plants that stand in the frames, and that is no longer every
     * arrival: the 274 lilies in every 501 were pulling the median down by
     * 0.12 m, and left at 0.38 the cut put 81% of the frames' plants at the
     * back with the front ranks standing empty. 0.50 is the dry median.
     * **0.49 since 29 September 2026**, the dry median measured again after
     * the re-roll: 0.486 m.
     */
    public const BACK_FROM = 0.49;

    /** Which rank a plant of this grown height belongs in. */
    public static function rank(float $height): int
    {
        return $height < self::BACK_FROM ? self::FRONT : self::BACK;
    }

    /**
     * How many places along a rank a plant takes: **two for a lotus, one for
     * everything else**, Marcus's choice on 25 September 2026. A lotus's pads
     * reach as far from its stem as the next place, and standing across two
     * it has 0.46 m either side. The habit is a word, the same on the phone and
     * here, so nothing about this can round differently; the empty habit, a
     * plant whose phone never sent one, takes one place.
     */
    public static function span(string $habit): int
    {
        return $habit === 'lotus' ? 2 : 1;
    }

    /**
     * The first place along a rank that nothing holds: the place after the
     * furthest one held, since a rank fills from its west end without a gap.
     * `$rank` is the plantings standing in it.
     */
    public static function next(array $rank): int
    {
        $next = 0;
        foreach ($rank as $p) $next = max($next, (int) $p['index'] + (int) ($p['span'] ?? 1));
        return $next;
    }

    /**
     * The middle of a frame, from the middle of the plot: [x, z]. The pond's
     * places are the table's own, from the plot's middle, so its middle is the
     * plot's. A retired front frame keeps the place the formula gives it.
     */
    public static function centre(int $frame): array
    {
        if ($frame === self::POND) return [0.0, 0.0];
        return [
            $frame % 2 === 0 ? -self::FRAME_X : self::FRAME_X,
            $frame < 2 ? -self::FRAME_Z : self::FRAME_Z,
        ];
    }

    /**
     * Where a place lies within its frame, from the frame's own middle: [x, z].
     * The pond has no ranks, and its places are the table's; a pond index past
     * the table's end is a row written in an older scheme, and stands on the
     * pond's last place until the replant.
     */
    public static function at(int $frame, int $rank, int $index): array
    {
        if ($frame === self::POND) {
            $place = ColdFramePondTable::PLACES[0][min($index, self::POND_PLACES - 1)];
            return [$place[0], $place[1]];
        }
        return [
            ($index - (self::PLACES - 1) / 2) * self::ALONG_GAP,
            $rank === self::BACK ? -self::RANK_FROM : self::RANK_FROM,
        ];
    }

    /**
     * Where a plant holding `span` places from `index` stands, in metres from
     * the middle of the plot **as the table draws it**: [x, z]. The middle of
     * its places, so a lotus under glass stands half a place east of its
     * first.
     *
     * `index` 0 is the west end of the rank, and a rank fills from there, the
     * way trays are set into a frame from the end a gardener reaches in at.
     * Worked out as the Swift's `Planting.spot` is, the first and last places
     * averaged, so a plant of one place stands where its place is to the bit.
     */
    public static function spot(int $frame, int $rank, int $index, int $span = 1): array
    {
        [$x, $z] = self::centre($frame);
        [$ax, $az] = self::at($frame, $rank, $index);
        [$bx, $bz] = self::at($frame, $rank, $index + $span - 1);
        return [$x + ($ax + $bx) / 2, $z + ($az + $bz) / 2];
    }

    /** The variant of a plot: mirrored or not, by its number. */
    public static function variant(int $plot): array
    {
        return PlotVariant::of($plot, 'waiting', self::VARIANTS);
    }

    /**
     * **Where a planting stands on its plot**: its place and its nudge, the
     * sum mirrored as the plot is laid. The Swift's `Planting.spot`, to the
     * bit.
     */
    public static function spotOn(int $plot, int $frame, int $rank, int $index, int $span,
                                  float $nudgeX, float $nudgeZ): array
    {
        [$cx, $cz] = self::centre($frame);
        [$ax, $az] = self::at($frame, $rank, $index);
        [$bx, $bz] = self::at($frame, $rank, $index + $span - 1);
        return PlotVariant::apply(self::variant($plot),
                                  $cx + ($ax + $bx) / 2 + $nudgeX, $cz + ($az + $bz) / 2 + $nudgeZ);
    }

    /**
     * Every place in one plot, frame by frame, the front rank before the back,
     * and the pond's thirty-nine after the two frames' twenty-four.
     */
    public static function slots(): array
    {
        static $slots = null;
        if ($slots !== null) return $slots;
        $slots = [];
        foreach (self::FRAMES as $frame) {
            foreach (self::RANKS as $rank) {
                for ($index = 0; $index < self::PLACES; $index++) {
                    $slots[] = ['frame' => $frame, 'rank' => $rank, 'index' => $index];
                }
            }
        }
        for ($index = 0; $index < self::POND_PLACES; $index++) {
            $slots[] = ['frame' => self::POND, 'rank' => self::FRONT, 'index' => $index];
        }
        return $slots;
    }

    /** Plots opened so far. */
    public static function plots(array $ways): int
    {
        $max = -1;
        foreach ($ways as $p) $max = max($max, (int) $p['plot']);
        return $max + 1;
    }

    /**
     * The colour family standing in this frame of this plot, or null if nobody
     * has claimed it. `$here` is one plot's plantings, in the order they
     * arrived, so the first one found is the one that claimed the frame.
     */
    public static function familyOf(array $here, int $frame): ?int
    {
        foreach ($here as $p) {
            if ((int) $p['frame'] === $frame) return (int) $p['family'];
        }
        return null;
    }

    /**
     * Where the next plant with these traits goes: [plot, slot].
     *
     * **Colour picks the frame, the grown height picks the rank.** A frame
     * already holding this colour, oldest plot first — its own rank if there is
     * room and nothing would stand out of order, otherwise the other rank on the
     * same terms; then a frame nobody has claimed, oldest plot first, in its own
     * rank; then a new plot, opened in the first frame.
     *
     * Plot outside, rank inside, as the Knot Garden and the Orchard have it: a
     * frame reading as one colour matters more than a plant getting the rank its
     * height asks for.
     *
     * **A lotus asks each rank for two places side by side.** A rank with one
     * place left has no room for it, and it goes on as a plant finding a full
     * rank does; the place stays for a plant of one.
     *
     * **What wants water is asked first and asked only of the water.** The
     * frames are sorted by colour and by height and a lily is sorted by
     * neither, so there is no frame for it to fall back to: a full pond opens
     * a new plot. That is what keeps a plot's water full before the next
     * plot's is used.
     */
    public static function place(array $ways, float $height, int $family, string $habit = ''): array
    {
        if (self::wantsWater($habit)) {
            $order = self::waterOrder($habit);
            $opened = self::plots($ways);
            for ($plot = 0; $plot < $opened; $plot++) {
                $taken = [];
                foreach ($ways as $p) {
                    if ((int) $p['plot'] !== $plot || (int) $p['frame'] !== self::POND) continue;
                    $from = (int) $p['index'];
                    for ($n = 0; $n < (int) ($p['span'] ?? 1); $n++) $taken[$from + $n] = true;
                }
                foreach ($order as $index) {
                    if (!isset($taken[$index])) {
                        return [$plot, ['frame' => self::POND, 'rank' => self::FRONT, 'index' => $index]];
                    }
                }
            }
            return [$opened, ['frame' => self::POND, 'rank' => self::FRONT, 'index' => $order[0]]];
        }
        $own = self::rank($height);
        $span = self::span($habit);
        $other = $own === self::BACK ? self::FRONT : self::BACK;
        $opened = self::plots($ways);
        $byPlot = [];
        for ($plot = 0; $plot < $opened; $plot++) {
            $byPlot[$plot] = array_values(array_filter($ways, fn($p) => (int) $p['plot'] === $plot));
        }

        for ($plot = 0; $plot < $opened; $plot++) {
            foreach (self::FRAMES as $frame) {
                $here = array_values(array_filter($byPlot[$plot], fn($p) => (int) $p['frame'] === $frame));
                // The first plant in the frame is the claim. An empty frame has
                // none, and `null !== $family` passes it by here, as the Swift's
                // `here.first?.traits.family == traits.family` does.
                if (($here === [] ? null : (int) $here[0]['family']) !== $family) continue;
                foreach ([$own, $other] as $rank) {
                    $next = self::next(array_filter($here, fn($p) => (int) $p['rank'] === $rank));
                    if ($next + $span <= self::PLACES && self::inOrder($height, $rank, $here)) {
                        return [$plot, ['frame' => $frame, 'rank' => $rank, 'index' => $next]];
                    }
                }
            }
        }
        for ($plot = 0; $plot < $opened; $plot++) {
            foreach (self::FRAMES as $frame) {
                if (self::familyOf($byPlot[$plot], $frame) === null) {
                    return [$plot, ['frame' => $frame, 'rank' => $own, 'index' => 0]];
                }
            }
        }
        return [$opened, ['frame' => self::BACK_WEST, 'rank' => $own, 'index' => 0]];
    }

    /**
     * Plants one arrival and returns the planting; the area only grows.
     *
     * The nudge is 0.03 m either way, the tightest in the garden after the
     * Seedbed's across a drill: places along a rank are 0.31 m apart and a rank
     * is meant to read as one.
     */
    public static function plant(array $ways, string $seedHex, float $height, int $family,
                                 string $habit = ''): array
    {
        [$plot, $slot] = self::place($ways, $height, $family, $habit);
        $bytes = array_values(unpack('C*', hex2bin($seedHex)));
        $jitter = fn(int $i, float $reach) => isset($bytes[$i]) ? ($bytes[$i] / 255 - 0.5) * 2 * $reach : 0.0;
        return [
            'seed' => $seedHex, 'plot' => $plot,
            'frame' => $slot['frame'], 'rank' => $slot['rank'], 'index' => $slot['index'],
            // **A lily in the pond holds one place**, as it did in the tank.
            // The two it holds under glass are 0.31 m apart and a lotus's
            // pads need more than one of them; the pond's open water is half
            // a metre between places, measured for a lily. The span is a fact
            // about the place as much as about the plant.
            'span' => self::isDry($slot['frame']) ? self::span($habit) : 1,
            'height' => $height, 'family' => $family, 'habit' => $habit,
            'nudgeX' => $jitter(26, 0.03), 'nudgeZ' => $jitter(27, 0.03),
        ];
    }

    /**
     * Whether a plant this tall can stand in this rank of a frame: nothing in
     * the front rank taller than anything in the back.
     *
     * The Long Walk's rule about a border, asked of a frame. Places along one
     * rank are free of each other, because the ranks are what is graded and a
     * rank is one row. Public so `check_cold_frame.php` can ask it rather than
     * keep a second copy of the comparison that would agree with itself.
     */
    public static function inOrder(float $height, int $rank, array $frame): bool
    {
        foreach ($frame as $other) {
            if ((int) $other['rank'] === $rank) continue;
            if ($rank === self::BACK && $height < $other['height']) return false;
            if ($rank === self::FRONT && $height > $other['height']) return false;
        }
        return true;
    }
}
