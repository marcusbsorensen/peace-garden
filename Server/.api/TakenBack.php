<?php
declare(strict_types=1);

/**
 * What is left of a planting once it has been taken back: its place, and
 * nothing that says whose it was.
 *
 * **Taking back deletes.** Until 24 September a planting taken back was hidden
 * and otherwise kept whole — seed, both parents, the meeting — so a gardener
 * who withdrew their consent left everything they had consented to publish in
 * the live database for good. Now the row keeps only its place and the facts
 * about the plant that the area's rule reads, and the rest is written over.
 *
 * **Why a row is left at all.** Every area is append-only and every rule places
 * an arrival against everything that arrived before it: which slots are taken,
 * which colour or kind claimed a pair, a frame or a drill, how tall the plants
 * already in a bed are, and — through the arrival number — which of them came
 * first. Delete a row and the rule sees a different garden, so the next plant
 * lands somewhere the recorded rule would not have put it and every plant after
 * that follows it. What stays is exactly what the rule reads, per store:
 *
 *   long_walk     plot, side, tier, slot, height, family
 *   quiet_garden  plot, corner, slot, height, family
 *   crossing      plot, quarter, slot, height            (family is not read)
 *   orchard       plot, guild, slot, height              (family is not read)
 *   knot_garden   plot, compartment, slot, height, family
 *   seedbed       plot, drill, slot, kind                (height, family not read)
 *   cold_frame    plot, frame, rank, slot, height, family
 *   glasshouse    plot, bed, slot, row                   (height, family, hue not read)
 *   coppice       plot, coupe, place, slot, height, habit (family is not read)
 *   home_ground   plot, bed, crop, slot                  (height, family, habit not read)
 *
 * with the arrival number, which is the order. Each store names its own list in
 * a `TAKEN_BACK` constant, as the columns it blanks. What goes, everywhere: the
 * seed, both parents' seeds, the meeting, and the nudge, which is two bytes of
 * the seed scaled and so a piece of it.
 *
 * **The seed column keeps a marker, not a seed.** It is `NOT NULL UNIQUE` and a
 * live table cannot be altered on both databases alike, so it holds
 * `withdrawn:` and the arrival number, padded to the column's width. That is
 * unique because the arrival number is, it names nothing, and it can never be
 * taken for a seed: a seed is lowercase hex and every route refuses anything
 * else. The parents and the meeting are the empty string for the same reason
 * (`NOT NULL`).
 *
 * **The migration is the same code, run on every request.** A row hidden before
 * this existed still holds its seed, so each store's schema setup erases every
 * hidden row whose seed is not yet a marker. On a table where that is already
 * done it finds nothing, through an index on `hidden`, which is what makes it
 * safe to leave running — and it also puts right a row hidden by anything that
 * forgot to erase it, including an older copy restored from a backup.
 */
final class TakenBack
{
    public const MARK = 'withdrawn:';

    /**
     * What stands in the seed column of a planting taken back: 64 characters,
     * the column's width, made from the arrival number alone.
     */
    public static function marker(int $arrival): string
    {
        return sprintf('%s%054d', self::MARK, $arrival);
    }

    public static function isMarker(string $seed): bool
    {
        return str_starts_with($seed, self::MARK);
    }

    /**
     * Hides one planting and erases everything of it the rule does not read.
     * A seed with no row is nothing to do, which is what a second withdrawal of
     * the same plant finds.
     *
     * `$blank` is the store's own columns to write over, beyond the ones every
     * area writes over: column => the value it becomes.
     */
    public static function lift(PDO $db, string $table, array $blank, string $seed): void
    {
        $find = $db->prepare("SELECT arrival FROM $table WHERE seed = ?");
        $find->execute([$seed]);
        $arrival = $find->fetchColumn();
        if ($arrival === false) return;
        self::erase($db, $table, $blank, (int) $arrival);
    }

    /**
     * The migration: every hidden row that still carries a seed, erased.
     * Idempotent, and cheap once it has run: the index on `hidden` hands it the
     * rows taken back, and each of those is already a marker.
     */
    public static function sweep(PDO $db, string $table, array $blank): void
    {
        $left = $db->prepare("SELECT arrival FROM $table WHERE hidden = 1 AND seed NOT LIKE ?");
        $left->execute([self::MARK . '%']);
        foreach ($left->fetchAll(PDO::FETCH_COLUMN) as $arrival) {
            self::erase($db, $table, $blank, (int) $arrival);
        }
    }

    private static function erase(PDO $db, string $table, array $blank, int $arrival): void
    {
        $blank = ['parent_a' => '', 'parent_b' => '', 'encounter' => '',
                  'nudge_x' => 0.0, 'nudge_z' => 0.0] + $blank;
        $sets = implode(', ', array_map(fn (string $column) => "$column = ?", array_keys($blank)));
        $update = $db->prepare("UPDATE $table SET hidden = 1, seed = ?, $sets WHERE arrival = ?");
        $update->execute([self::marker($arrival), ...array_values($blank), $arrival]);
    }
}
