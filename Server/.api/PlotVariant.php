<?php
declare(strict_types=1);

/**
 * Which way round a plot is laid: turned, mirrored, and which of its area's
 * feature variants it takes, chosen from the plot's number. Ported from
 * SeedCore's `WebGardens/PlotVariant.swift`, which says why.
 *
 * **A port, and held to the Swift.** `tools/reference/check_plot_variant.php`
 * reads `tools/reference/plot_variant_vectors.json`, which the Swift records,
 * and fails CI if this deals any plot a different variant or draws any place
 * anywhere else.
 *
 * **Thirty-two bits, multiplied in halves.** PHP's integers are sixty-four
 * bits and signed, and a product that overflows them turns into a float, which
 * has lost its low bits by then. `mul32` multiplies by sixteen bits at a time,
 * so no product passes 2^48 and every value stays an integer in [0, 2^32).
 *
 * A space is an array: ['turns' => 1|2|4, 'mirror' => bool, 'nudges' => int],
 * as each area class declares it in `VARIANTS`. A variant is an array:
 * ['turn' => 0..3, 'mirror' => bool, 'nudge' => int].
 */
final class PlotVariant
{
    /** The plot as its area's tables draw it: every area's plot 0. */
    public const PLAIN = ['turn' => 0, 'mirror' => false, 'nudge' => 0];

    /** How many variants a space holds. */
    public static function count(array $space): int
    {
        return $space['turns'] * ($space['mirror'] ? 2 : 1) * $space['nudges'];
    }

    /** The n-th variant of a space: the turn changing fastest, then the mirror, then the feature variant. */
    public static function variant(array $space, int $n): array
    {
        $turns = $space['turns'];
        $mirrors = $space['mirror'] ? 2 : 1;
        return [
            'turn' => ($n % $turns) * intdiv(4, $turns),
            'mirror' => intdiv($n, $turns) % $mirrors === 1,
            'nudge' => intdiv($n, $turns * $mirrors),
        ];
    }

    /** The variant of plot `$plot` of the area named `$area` (`travel`, `renewal`), from its space. */
    public static function of(int $plot, string $area, array $space): array
    {
        return self::dealt($plot, self::salt($area), $space);
    }

    /** The variant of a plot, from its number and a salt: dealt in shuffled blocks, as the Swift's `of(plot:salt:in:)`. */
    public static function dealt(int $plot, int $salt, array $space): array
    {
        $count = self::count($space);
        if ($count <= 1 || $plot <= 0) return self::variant($space, 0);
        if ($count === 2) return self::variant($space, $plot % 2);
        return self::variant($space, self::deck(intdiv($plot, $count), $count, $salt)[$plot % $count]);
    }

    /** A block's shuffle, plot 0 brought to the front of the first, and no block beginning where the last ended. */
    private static function deck(int $block, int $count, int $salt): array
    {
        $deck = self::shuffle($block, $count, $salt);
        if ($block === 0) {
            $plain = array_search(0, $deck, true);
            [$deck[0], $deck[$plain]] = [$deck[$plain], $deck[0]];
        } else {
            $before = $block === 1
                ? self::deck(0, $count, $salt)[$count - 1]
                : self::shuffle($block - 1, $count, $salt)[$count - 1];
            if ($deck[0] === $before) [$deck[0], $deck[1]] = [$deck[1], $deck[0]];
        }
        return $deck;
    }

    /** Fisher and Yates's shuffle of 0..count-1, from the block's number and the salt. */
    private static function shuffle(int $block, int $count, int $salt): array
    {
        $deck = range(0, $count - 1);
        $start = self::mix32(self::mix32($salt) ^ ($block & 0xFFFFFFFF));
        for ($i = $count - 1; $i > 0; $i--) {
            $j = self::mix32($start ^ $i) % ($i + 1);
            [$deck[$i], $deck[$j]] = [$deck[$j], $deck[$i]];
        }
        return $deck;
    }

    /** FNV-1a over an area's name. */
    public static function salt(string $area): int
    {
        $hash = 0x811C9DC5;
        foreach (unpack('C*', $area) ?: [] as $byte) {
            $hash = self::mul32($hash ^ $byte, 0x01000193);
        }
        return $hash;
    }

    /** Chris Wellons's lowbias32, as the Swift's `mix32`. */
    public static function mix32(int $x): int
    {
        $x &= 0xFFFFFFFF;
        $x ^= $x >> 16;
        $x = self::mul32($x, 0x7FEB352D);
        $x ^= $x >> 15;
        $x = self::mul32($x, 0x846CA68B);
        $x ^= $x >> 16;
        return $x;
    }

    /** The low thirty-two bits of a × b, for a and b in [0, 2^32), sixteen bits of b at a time. */
    public static function mul32(int $a, int $b): int
    {
        $low = ($a * ($b & 0xFFFF)) & 0xFFFFFFFF;
        $high = (($a * ($b >> 16)) & 0xFFFF) << 16;
        return ($low + $high) & 0xFFFFFFFF;
    }

    /**
     * Where a place in the area's table stands on this plot: mirrored, then
     * turned, about the plot's middle. A quarter turn takes x+ to z+. Returns
     * [x, z]. `0.0 - $x` rather than `-$x`, so a place on an axis stays +0.
     */
    public static function apply(array $variant, float $x, float $z): array
    {
        if ($variant['mirror']) $x = 0.0 - $x;
        return match ($variant['turn'] & 3) {
            0 => [$x, $z],
            1 => [0.0 - $z, $x],
            2 => [0.0 - $x, 0.0 - $z],
            default => [$z, 0.0 - $x],
        };
    }

    /** The other way: where a point on this plot is in the area's table. */
    public static function undo(array $variant, float $x, float $z): array
    {
        [$x, $z] = self::apply(['turn' => (4 - ($variant['turn'] & 3)) & 3, 'mirror' => false, 'nudge' => 0], $x, $z);
        return $variant['mirror'] ? [0.0 - $x, $z] : [$x, $z];
    }
}
