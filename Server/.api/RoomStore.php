<?php
declare(strict_types=1);

require_once __DIR__ . '/Ambassadors.php';
require_once __DIR__ . '/TakenBack.php';
require_once __DIR__ . '/QuietGarden.php';

/**
 * The Quiet Garden, stored: every planting in the order it arrived, never
 * changed.
 *
 * **A table of its own, beside the walk's rather than inside it.** Every column
 * after `encounter` means something different here: the walk's row names a side
 * of a path and a tier of a border, and this one names a group in a room and a
 * place in that group. One table with an `area` column would be a table
 * whose rows only mean anything once you know which area they are — which is
 * ten tables pretending to be one (`docs/WEB-GARDENS.md`). It also keeps the
 * walk's own table, which is live and append-only, out of this entirely.
 *
 * Everything else is `WalkStore`'s, deliberately: the same append-only insert,
 * the same lock row, the same taking back that keeps a place and erases the
 * plant, and the same ambassador handed to the rule ahead of the stored
 * arrivals. Two areas with two different answers to *what happens when a
 * gardener takes a plant back* would be two gardens.
 */
final class RoomStore
{
    /**
     * What a planting taken back has written over, beyond the seed, the parents,
     * the meeting and the nudge that every area writes over (`TakenBack.php`).
     * Nothing: the room's rule reads the height of every plant in a group (the
     * back stands at least as tall as its arms) and the family of the plant that
     * founded each group, so both stay.
     */
    private const TAKEN_BACK = [];

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
        $this->run("CREATE TABLE IF NOT EXISTS quiet_garden (
            arrival $id,
            seed CHAR(64) NOT NULL UNIQUE,
            parent_a CHAR(64) NOT NULL,
            parent_b CHAR(64) NOT NULL,
            encounter CHAR(64) NOT NULL,
            plot INTEGER NOT NULL,
            corner INTEGER NOT NULL,
            slot_index INTEGER NOT NULL,
            height DOUBLE PRECISION NOT NULL,
            family INTEGER NOT NULL,
            habit VARCHAR(16) NOT NULL DEFAULT '',
            nudge_x DOUBLE PRECISION NOT NULL,
            nudge_z DOUBLE PRECISION NOT NULL,
            hidden INTEGER NOT NULL DEFAULT 0
        )");
        $this->run('CREATE INDEX IF NOT EXISTS quiet_garden_plot ON quiet_garden (plot)');
        $this->run('CREATE TABLE IF NOT EXISTS quiet_garden_lock (id INTEGER PRIMARY KEY, arrivals INTEGER NOT NULL)');
        $this->run('INSERT INTO quiet_garden_lock (id, arrivals) SELECT 1, 0 WHERE NOT EXISTS (SELECT 1 FROM quiet_garden_lock)');
        // Added on 24 September, when taking back began to delete: a row hidden
        // before then still holds the seed, the parents and the meeting, and
        // this erases it. Every request, and nothing to do once it has run.
        $this->run('CREATE INDEX IF NOT EXISTS quiet_garden_hidden ON quiet_garden (hidden)');
        // Added on 27 September, when the pool was dug and the room began to
        // ask what a plant is: an ALTER that may already have run, as the
        // Seedbed's and the Cold Frame's are. Every row already there holds a
        // dry slot, and the empty habit those rows get is what a plant that
        // wants no water has.
        try {
            $this->run("ALTER TABLE quiet_garden ADD COLUMN habit VARCHAR(16) NOT NULL DEFAULT ''");
        } catch (Throwable) {
            // Already there.
        }
        TakenBack::sweep($this->db, 'quiet_garden', self::TAKEN_BACK);
    }

    /**
     * Places one arrival by the rule and keeps it. Returns [the planting,
     * whether it is new]: a seed that has arrived before gets the place it
     * already has, because a plant has one place.
     *
     * `$kind` is the Seedbed's trait and `$hue` the Glasshouse's; nothing here
     * reads either, and they are in the signature so `WalkStore::plantInto`
     * can call every area's `plant` alike.
     * `$habit` says whether the plant wants standing water, and a plant that
     * does goes in the pool: `QuietGarden::WANTS_WATER` is the list. A habit
     * never sent wants none, and is planted in soil where most plants live.
     */
    public function plant(string $seed, string $parentA, string $parentB, string $encounter,
                          float $height, int $family, string $kind = '',
                          ?float $hue = null, string $habit = ''): array
    {
        if (Ambassadors::isOne($seed)) {
            throw new LogicException('an ambassador cannot be planted: it is already standing');
        }

        $this->db->beginTransaction();
        try {
            $this->run('UPDATE quiet_garden_lock SET arrivals = arrivals + 1 WHERE id = 1');
            $existing = $this->db->prepare('SELECT * FROM quiet_garden WHERE seed = ?');
            $existing->execute([$seed]);
            if ($row = $existing->fetch()) {
                $this->db->rollBack();
                return [self::planting($row), false];
            }
            $all = $this->db->prepare('SELECT * FROM quiet_garden ORDER BY arrival');
            $all->execute();
            // The ambassador first, then the arrivals: it is beside the bench in
            // plot 0 whether or not anything else is here, and a group graded
            // against a room that is missing its oldest plant is graded against
            // a room that is not there.
            $room = array_merge(
                [Ambassadors::planting('peace')],
                array_map([self::class, 'forRule'], $all->fetchAll())
            );
            $p = QuietGarden::plant($room, $seed, $height, $family, $habit);
            $insert = $this->db->prepare('INSERT INTO quiet_garden
                (seed, parent_a, parent_b, encounter, plot, corner, slot_index, height, family, habit, nudge_x, nudge_z)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $insert->execute([$seed, $parentA, $parentB, $encounter, $p['plot'], $p['corner'],
                              $p['index'], $height, $family, $habit, $p['nudgeX'], $p['nudgeZ']]);
            $this->db->commit();
            return [self::planting(['seed' => $seed, 'parent_a' => $parentA, 'parent_b' => $parentB,
                'encounter' => $encounter, 'plot' => $p['plot'], 'corner' => $p['corner'],
                'slot_index' => $p['index'], 'nudge_x' => $p['nudgeX'], 'nudge_z' => $p['nudgeZ']]), true];
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /**
     * A plot's plantings, in the order they arrived. Hidden ones are not in it.
     *
     * Plot 0 opens with the ambassador beside its bench, which is not a row. It
     * carries no parents and no meeting, because it was minted rather than
     * crossed, and an empty `parents` is how the wire says so.
     */
    public function plot(int $plot): array
    {
        $query = $this->db->prepare('SELECT * FROM quiet_garden WHERE plot = ? AND hidden = 0 ORDER BY arrival');
        $query->execute([$plot]);
        $plantings = array_map([self::class, 'planting'], $query->fetchAll());
        if ($plot !== 0) return $plantings;
        $standing = Ambassadors::planting('peace');
        array_unshift($plantings, [
            'seed' => $standing['seed'],
            'parents' => [],
            'encounter' => null,
            'plot' => 0,
            'spot' => QuietGarden::spotOn(0, $standing['corner'], $standing['index'],
                                          $standing['nudgeX'], $standing['nudgeZ']),
        ]);
        return $plantings;
    }

    /**
     * Takes a planting back: out of the drawing, and out of the database but for
     * its place and what the rule reads. The room keeps the gap.
     */
    public function takeBack(string $seed): void
    {
        TakenBack::lift($this->db, 'quiet_garden', self::TAKEN_BACK, $seed);
    }

    /**
     * Plots opened. Never fewer than one: the room opened with its ambassador
     * beside the bench in plot 0.
     */
    public function plots(): int
    {
        $query = $this->db->prepare('SELECT COALESCE(MAX(plot) + 1, 0) FROM quiet_garden');
        $query->execute();
        return max(1, (int) $query->fetchColumn());
    }

    /** What the page needs to grow a planting and stand it in its place. */
    private static function planting(array $row): array
    {
        // Where it stands in its room, turned as the room is laid (2 October
        // 2026).
        return [
            'seed' => $row['seed'],
            'parents' => [$row['parent_a'], $row['parent_b']],
            'encounter' => $row['encounter'],
            'plot' => (int) $row['plot'],
            'spot' => QuietGarden::spotOn((int) $row['plot'], (int) $row['corner'], (int) $row['slot_index'],
                                          (float) $row['nudge_x'], (float) $row['nudge_z']),
        ];
    }

    private static function forRule(array $row): array
    {
        return [
            'seed' => $row['seed'], 'plot' => (int) $row['plot'], 'corner' => (int) $row['corner'],
            'index' => (int) $row['slot_index'],
            'height' => (float) $row['height'], 'family' => (int) $row['family'],
        ];
    }
}
