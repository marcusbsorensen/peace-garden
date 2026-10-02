<?php
declare(strict_types=1);

require_once __DIR__ . '/Ambassadors.php';
require_once __DIR__ . '/TakenBack.php';
require_once __DIR__ . '/Glasshouse.php';

/**
 * The Glasshouse, stored: every planting in the order it arrived, never
 * changed.
 *
 * **A table of its own**, for the reason `RoomStore` gives and eight areas now
 * put beyond argument: every column after `encounter` means something different
 * again. This one names a *bed* — the staging or the border — a place along it,
 * and on the staging which of the two pots at that place.
 *
 * **The row is a column, as the Cold Frame's rank is.** Two pots stand at each
 * position of the staging, and neither the position nor the plant's hue says
 * which of them a plant is in: that is the order they arrived in. It is
 * `slot_row` rather than `row` because ROW is a reserved word in MySQL 8, for
 * the reason `slot_index` is not `index` and `slot_rank` is not `rank`.
 *
 * **`hue` is a column here and nowhere else.** It is the one trait this area's
 * rule reads that no other does — of the plant arriving, to choose its band.
 * The rule asks the plants already standing only where they stand, which is
 * why a planting taken back can let its hue go (`TAKEN_BACK`); it is stored for
 * what every area stores, a record of the planting while it stands. Nullable,
 * because a plant whose phone never sent a hue has none — and the rule reads
 * null as it reads a pale flower, so that plant takes any free pot rather than
 * being refused.
 *
 * **Nothing here records which band a position stands for.** That is the
 * rule's, a list of eleven edges fixed in `Glasshouse`; a pot one band off
 * stands at a position that is not its own band, which is a fact about where it
 * stands and not a claim on the place.
 *
 * Everything else is `WalkStore`'s, deliberately: the same append-only insert,
 * the same lock row, the same taking back that keeps a place and erases the
 * plant, and the same ambassador handed to the rule ahead of the stored
 * arrivals.
 */
final class GlasshouseStore
{
    /**
     * What a planting taken back has written over, beyond the seed, the parents,
     * the meeting and the nudge that every area writes over (`TakenBack.php`).
     * The height, the family and the hue, none of which the Glasshouse's rule
     * reads of a plant already standing: it asks only how many stand in the
     * border of a plot, and how many pots at a position of the staging are
     * taken. The plant's own hue and height choose its place, and are the
     * arriving plant's, not the standing ones'. The bed, the position and the
     * glass row stay, because those are the counts.
     */
    private const TAKEN_BACK = ['height' => 0.0, 'family' => 0, 'hue' => null];

    public function __construct(private PDO $db)
    {
        $this->migrate();
    }

    private function run(string $sql): void
    {
        $this->db->prepare($sql)->execute();
    }

    private function migrate(): void
    {
        $sqlite = $this->db->getAttribute(PDO::ATTR_DRIVER_NAME) === 'sqlite';
        $id = $sqlite ? 'INTEGER PRIMARY KEY AUTOINCREMENT' : 'BIGINT PRIMARY KEY AUTO_INCREMENT';
        $this->run("CREATE TABLE IF NOT EXISTS glasshouse (
            arrival $id,
            seed CHAR(64) NOT NULL UNIQUE,
            parent_a CHAR(64) NOT NULL,
            parent_b CHAR(64) NOT NULL,
            encounter CHAR(64) NOT NULL,
            plot INTEGER NOT NULL,
            bed INTEGER NOT NULL,
            slot_index INTEGER NOT NULL,
            slot_row INTEGER NOT NULL,
            height DOUBLE PRECISION NOT NULL,
            family INTEGER NOT NULL,
            hue DOUBLE PRECISION NULL,
            nudge_x DOUBLE PRECISION NOT NULL,
            nudge_z DOUBLE PRECISION NOT NULL,
            hidden INTEGER NOT NULL DEFAULT 0
        )");
        $this->run('CREATE INDEX IF NOT EXISTS glasshouse_plot ON glasshouse (plot)');
        $this->run('CREATE TABLE IF NOT EXISTS glasshouse_lock (id INTEGER PRIMARY KEY, arrivals INTEGER NOT NULL)');
        $this->run('INSERT INTO glasshouse_lock (id, arrivals) SELECT 1, 0 WHERE NOT EXISTS (SELECT 1 FROM glasshouse_lock)');
        // Added on 24 September, when taking back began to delete: a row hidden
        // before then still holds the seed, the parents and the meeting, and
        // this erases it. Every request, and nothing to do once it has run.
        $this->run('CREATE INDEX IF NOT EXISTS glasshouse_hidden ON glasshouse (hidden)');
        TakenBack::sweep($this->db, 'glasshouse', self::TAKEN_BACK);
    }

    /**
     * Places one arrival by the rule and keeps it. Returns [the planting,
     * whether it is new]: a seed that has arrived before gets the place it
     * already has, because a plant has one place.
     *
     * `$kind` is the Seedbed's trait and nothing here reads it; it is in the
     * signature so `WalkStore::plantInto` can call every area's `plant` alike.
     * `$hue` is this area's, and null means it was never sent.
     */
    public function plant(string $seed, string $parentA, string $parentB, string $encounter,
                          float $height, int $family, string $kind = '', ?float $hue = null): array
    {
        if (Ambassadors::isOne($seed)) {
            throw new LogicException('an ambassador cannot be planted: it is already standing');
        }

        $this->db->beginTransaction();
        try {
            $this->run('UPDATE glasshouse_lock SET arrivals = arrivals + 1 WHERE id = 1');
            $existing = $this->db->prepare('SELECT * FROM glasshouse WHERE seed = ?');
            $existing->execute([$seed]);
            if ($row = $existing->fetch()) {
                $this->db->rollBack();
                return [self::planting($row), false];
            }
            $all = $this->db->prepare('SELECT * FROM glasshouse ORDER BY arrival');
            $all->execute();
            // The ambassador first, then the arrivals: it stands whether or not
            // anything else is here, **and it holds a place**. A reading that
            // left it out would hand that place to the next plant, and two
            // plants would be drawn standing in one. (Since 28 September 2026
            // the place is the border's first — the middle of the round bed
            // since 2 October; it was a pot at the ambassador's own band of the
            // staging.)
            $ways = array_merge(
                [Ambassadors::planting('light')],
                array_map([self::class, 'forRule'], $all->fetchAll())
            );
            $p = Glasshouse::plant($ways, $seed, $height, $family, $hue);
            $insert = $this->db->prepare('INSERT INTO glasshouse
                (seed, parent_a, parent_b, encounter, plot, bed, slot_index, slot_row, height, family, hue, nudge_x, nudge_z)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $insert->execute([$seed, $parentA, $parentB, $encounter, $p['plot'], $p['bed'], $p['index'],
                              $p['row'], $height, $family, self::exactly($hue), $p['nudgeX'], $p['nudgeZ']]);
            $this->db->commit();
            return [self::planting(['seed' => $seed, 'parent_a' => $parentA, 'parent_b' => $parentB,
                'encounter' => $encounter, 'plot' => $p['plot'], 'bed' => $p['bed'],
                'slot_index' => $p['index'], 'slot_row' => $p['row'],
                'nudge_x' => $p['nudgeX'], 'nudge_z' => $p['nudgeZ']]), true];
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /**
     * A plot's plantings, in the order they arrived. Hidden ones are not in it.
     *
     * Plot 0 opens with the ambassador, which is not a row, in the bed its
     * height gives it — since the re-roll of 28 September 2026 the border's
     * first place (the middle of the round bed since 2 October), where it was
     * a pot at its own band of the staging — and lifted as that bed lifts it. It carries no parents and no meeting, because it was
     * minted rather than crossed, and an empty `parents` is how the wire says
     * so.
     */
    public function plot(int $plot): array
    {
        $query = $this->db->prepare('SELECT * FROM glasshouse WHERE plot = ? AND hidden = 0 ORDER BY arrival');
        $query->execute([$plot]);
        $plantings = array_map([self::class, 'planting'], $query->fetchAll());
        if ($plot !== 0) return $plantings;
        $standing = Ambassadors::planting('light');
        array_unshift($plantings, [
            'seed' => $standing['seed'],
            'parents' => [],
            'encounter' => null,
            'plot' => 0,
            'spot' => Glasshouse::standing(0, $standing['bed'], $standing['index'], $standing['row'],
                                           $standing['nudgeX'], $standing['nudgeZ']),
            'lift' => Glasshouse::lift($standing['bed']),
        ]);
        return $plantings;
    }

    /**
     * Takes a planting back: out of the drawing, and out of the database but for
     * its place and what the rule reads. The area keeps the gap.
     */
    public function takeBack(string $seed): void
    {
        TakenBack::lift($this->db, 'glasshouse', self::TAKEN_BACK, $seed);
    }

    /**
     * Plots opened. Never fewer than one: the Glasshouse opened with its
     * ambassador in plot 0.
     */
    public function plots(): int
    {
        $query = $this->db->prepare('SELECT COALESCE(MAX(plot) + 1, 0) FROM glasshouse');
        $query->execute();
        return max(1, (int) $query->fetchColumn());
    }

    /**
     * What the page needs to grow a planting and stand it in its place: the
     * five fields every area sends, and **one more, `lift`** — how far off the
     * floor the plant stands, which is the soil in its pot on the staging and
     * nothing in the border. The first area whose plants do not all stand on
     * the ground, and the page cannot tell a pot from the border by its spot
     * without keeping a second copy of where the staging is. It draws a pot
     * under every planting with a lift.
     */
    private static function planting(array $row): array
    {
        $bed = (int) $row['bed'];
        return [
            'seed' => $row['seed'],
            'parents' => [$row['parent_a'], $row['parent_b']],
            'encounter' => $row['encounter'],
            'plot' => (int) $row['plot'],
            'spot' => Glasshouse::standing((int) $row['plot'], $bed, (int) $row['slot_index'], (int) $row['slot_row'],
                                           (float) $row['nudge_x'], (float) $row['nudge_z']),
            'lift' => Glasshouse::lift($bed),
        ];
    }

    /**
     * **A double as the text that parses back to exactly it**, for binding.
     *
     * PDO binds every value as a string, and it turns a float into one with
     * PHP's `precision` setting — fourteen significant digits — so a hue of
     * 0.7777777777777778 goes into the column as 0.77777777777778 and comes
     * back a different double. Every height in every area is stored that way,
     * and is harmless there: the nearest a height comes to anything a rule
     * compares it with is a tenth of a millimetre. A hue is compared with band
     * edges exactly, and was sent exactly, so it is kept exactly: `json_encode`
     * writes the shortest text that reads back as the same double, and SQLite
     * and MySQL both read it back so. `check_offers.php` holds a hue to the bit
     * through the asking and the planting.
     */
    public static function exactly(?float $value): ?string
    {
        return $value === null ? null : json_encode($value, JSON_PRESERVE_ZERO_FRACTION);
    }

    private static function forRule(array $row): array
    {
        return [
            'seed' => $row['seed'], 'plot' => (int) $row['plot'],
            'bed' => (int) $row['bed'], 'index' => (int) $row['slot_index'],
            'row' => (int) $row['slot_row'],
            'height' => (float) $row['height'], 'family' => (int) $row['family'],
            'hue' => $row['hue'] === null ? null : (float) $row['hue'],
        ];
    }
}
