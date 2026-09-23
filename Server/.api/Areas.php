<?php

/**
 * The ten areas of the shared garden, and which of them a plant can stand in.
 *
 * A port of `SeedCore`'s `Area` (`Packages/SeedCore/Sources/SeedCore/WebGardens/Areas.swift`),
 * which is where the reasoning lives. `tools/reference/check_areas.php` holds
 * the two to each other, because a phone that thinks the Orchard is open and a
 * service that does not is a gardener told their plant was shared when it was
 * refused.
 *
 * **Why the service needs this at all.** Until now it was a Long Walk service:
 * one table, one rule, and a plant went into it whatever theme it belonged to.
 * A garden of ten areas is built one area at a time, so something has to be
 * able to say *that one is not open yet* — and say it to the phone, so the
 * gardener hears it before they promise anything to anybody.
 */
final class Areas
{
    /** In the order `Quotes.Theme` declares them, which is the order SeedCore does. */
    public const ALL = [
        'beginnings', 'waiting', 'renewal', 'light', 'pattern',
        'ground', 'travel', 'meeting', 'kinship', 'peace',
    ];

    /**
     * The areas with a placement rule, which is what open means. An area is not
     * open because it has a name and a layout on paper; it is open when there
     * is a rule that gives an arriving plant a slot and never moves it again.
     */
    public const OPEN = ['beginnings', 'pattern', 'travel', 'meeting', 'kinship', 'peace'];

    /** What this area's plantings are called, or '' for an area with no table yet. */
    public const TABLES = [
        'travel' => 'long_walk',
        'meeting' => 'crossing',
        'peace' => 'quiet_garden',
        'kinship' => 'orchard',
        'pattern' => 'knot_garden',
        'beginnings' => 'seedbed',
    ];

    public static function exists(mixed $area): bool
    {
        return is_string($area) && in_array($area, self::ALL, true);
    }

    public static function isOpen(mixed $area): bool
    {
        return is_string($area) && in_array($area, self::OPEN, true);
    }

    public static function table(string $area): string
    {
        return self::TABLES[$area] ?? '';
    }

    /**
     * What `GET /api/garden` answers: every area, named, and whether a plant
     * can stand in it.
     *
     * **All ten rather than only the open ones.** A phone that received a list
     * of one could not tell an area that is not built from an area that has
     * been taken away, and the difference matters to somebody holding a plant
     * that belongs to it.
     */
    public static function all(): array
    {
        return array_map(
            static fn(string $area): array => ['area' => $area, 'open' => self::isOpen($area)],
            self::ALL
        );
    }
}
