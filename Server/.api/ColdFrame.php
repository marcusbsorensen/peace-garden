<?php
declare(strict_types=1);

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
 * A planting here is an array: seed (hex), plot, frame (0-3), rank (0 front,
 * 1 back), index (0-5, the west one of a lotus's two), span (1, or 2 for a
 * lotus), height, family, habit, nudgeX, nudgeZ. A planting with no span holds
 * one place, which is what every planting made before the lotus rule holds.
 */
final class ColdFrame
{
    /** The same square every area uses. */
    public const PLOT_SIDE = 5.2;

    /**
     * Four frames of twelve, two ranks of six in each: forty-eight a plot,
     * Marcus's choice on 23 September.
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
     * Where the middles of the four frames stand: either side of the plot in
     * `x`, and two rows in `z` with a path between them.
     */
    public const FRAME_X = 1.2;
    public const FRAME_Z = 0.9;

    /** Along a rank, between one place and the next, and how far either rank stands from the middle of its frame. */
    public const ALONG_GAP = 0.31;
    public const RANK_FROM = 0.24;

    /**
     * The four frames, in the order a plot opens them: the back row from west
     * to east, then the front row. The back row is `z−`.
     */
    public const BACK_WEST = 0;
    public const BACK_EAST = 1;
    public const FRONT_WEST = 2;
    public const FRONT_EAST = 3;
    public const FRAMES = [0, 1, 2, 3];

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
     */
    public const BACK_FROM = 0.38;

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

    /** The middle of a frame, from the middle of the plot: [x, z]. */
    public static function centre(int $frame): array
    {
        return [
            $frame % 2 === 0 ? -self::FRAME_X : self::FRAME_X,
            $frame < 2 ? -self::FRAME_Z : self::FRAME_Z,
        ];
    }

    /**
     * Where a plant holding `span` places from `index` stands, in metres from
     * the middle of its plot: [x, z]. The middle of its places, so a lotus
     * stands half a place east of its first.
     *
     * `index` 0 is the west end of the rank, and a rank fills from there, the
     * way trays are set into a frame from the end a gardener reaches in at.
     * The place is counted in halves, as the Swift counts it, so a plant of
     * one place stands where it always did, to the last bit.
     */
    public static function spot(int $frame, int $rank, int $index, int $span = 1): array
    {
        [$x, $z] = self::centre($frame);
        $at = $index + ($span - 1) / 2;
        return [
            $x + ($at - (self::PLACES - 1) / 2) * self::ALONG_GAP,
            $z + ($rank === self::BACK ? -self::RANK_FROM : self::RANK_FROM),
        ];
    }

    /** Every place in one plot, frame by frame, the front rank before the back. */
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
     */
    public static function place(array $ways, float $height, int $family, string $habit = ''): array
    {
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
            'span' => self::span($habit),
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
