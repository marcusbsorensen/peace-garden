<?php
declare(strict_types=1);

/**
 * The Wild Fields' rule: where a released plant stands, read off its seed.
 *
 * A port of SeedCore's `WildFields`, held to it by
 * `tools/reference/check_wild_fields.php` over three hundred and four seeds.
 * It is the whole of the rule, because the wild has no template: no order of
 * arrival, no neighbours, nothing stored that the seed does not already say.
 *
 * **One field with no edge.** A square `SIDE` metres across whose far edges
 * meet its near ones, so a reader who walks off one side walks on in from the
 * other. A page reads it in `TILE`-metre squares, which is what lets a field
 * with no end be fetched a piece at a time.
 *
 * **Exact on every host.** A place is two bytes of the seed in the middle of
 * its step, a whole number of 1/1024ths of a metre, so the double PHP makes is
 * the double Swift makes and the vectors are compared with no tolerance.
 */
final class WildFields
{
    /// How far the field runs before it comes round again, in metres. It can
    /// never change: every place is a fraction of it.
    public const SIDE = 64.0;

    /// The square a page asks for at a time, in metres.
    public const TILE = 8.0;

    /// Tiles along each side.
    public const TILES = 8;

    /** Where a released plant stands: [across, along], each in 0 ≤ v < SIDE. */
    public static function spot(string $seedHex): array
    {
        $across = hexdec(substr($seedHex, 0, 4));
        $along = hexdec(substr($seedHex, 4, 4));
        return [($across + 0.5) / 65536 * self::SIDE, ($along + 0.5) / 65536 * self::SIDE];
    }

    /** Which tile it stands in: [across, along], each 0 to TILES − 1. */
    public static function tile(string $seedHex): array
    {
        [$x, $z] = self::spot($seedHex);
        return [(int) floor($x / self::TILE), (int) floor($z / self::TILE)];
    }
}
