<?php
declare(strict_types=1);

require_once __DIR__ . '/Ambassadors.php';
require_once __DIR__ . '/TakenBack.php';
require_once __DIR__ . '/HomeGround.php';

/**
 * The Home Ground, stored: every planting in the order it arrived, never
 * changed.
 *
 * **A table of its own**, for the reason `RoomStore` gives: every column after
 * `encounter` means something different again. This one names a *bed*, the
 * *crop* it is sown with, and the place in it counted from the north end.
 *
 * **`crop` is a column because a bed's claim is read off it.** The rule asks of
 * the plants already standing only where they stand and what their bed is sown
 * with, and the crop is part of the place: the same index is a different spot in
 * a bed of spires and a bed of rosettes. So a planting taken back keeps its
 * crop and its place, and gives up its height, its family and its habit, none of
 * which the rule reads of a plant already standing (`TAKEN_BACK`). The habit is
 * kept while the plant stands, because a replant reads it.
 *
 * Everything else is `WalkStore`'s, deliberately: the same append-only insert,
 * the same lock row, the same taking back that keeps a place and erases the
 * plant, and the same ambassador handed to the rule ahead of the stored
 * arrivals.
 */
final class HomeGroundStore
{
    /**
     * What a planting taken back has written over, beyond the seed, the parents,
     * the meeting and the nudge that every area writes over (`TakenBack.php`):
     * everything about the plant. A height is compared only with a cut, and
     * only the arriving plant's, so no standing plant's height is ever read.
     */
    private const TAKEN_BACK = ['height' => 0.0, 'family' => 0, 'habit' => ''];

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
        $this->run("CREATE TABLE IF NOT EXISTS home_ground (
            arrival $id,
            seed CHAR(64) NOT NULL UNIQUE,
            parent_a CHAR(64) NOT NULL,
            parent_b CHAR(64) NOT NULL,
            encounter CHAR(64) NOT NULL,
            plot INTEGER NOT NULL,
            bed INTEGER NOT NULL,
            crop VARCHAR(8) NOT NULL,
            slot_index INTEGER NOT NULL,
            height DOUBLE PRECISION NOT NULL,
            family INTEGER NOT NULL,
            habit VARCHAR(16) NOT NULL DEFAULT '',
            nudge_x DOUBLE PRECISION NOT NULL,
            nudge_z DOUBLE PRECISION NOT NULL,
            hidden INTEGER NOT NULL DEFAULT 0
        )");
        $this->run('CREATE INDEX IF NOT EXISTS home_ground_plot ON home_ground (plot)');
        $this->run('CREATE TABLE IF NOT EXISTS home_ground_lock (id INTEGER PRIMARY KEY, arrivals INTEGER NOT NULL)');
        $this->run('INSERT INTO home_ground_lock (id, arrivals) SELECT 1, 0 WHERE NOT EXISTS (SELECT 1 FROM home_ground_lock)');
        $this->run('CREATE INDEX IF NOT EXISTS home_ground_hidden ON home_ground (hidden)');
        TakenBack::sweep($this->db, 'home_ground', self::TAKEN_BACK);
    }

    /**
     * Places one arrival by the rule and keeps it. Returns [the planting,
     * whether it is new]: a seed that has arrived before gets the place it
     * already has, because a plant has one place.
     *
     * `$kind` and `$hue` are the Seedbed's and the Glasshouse's, and nothing
     * here reads them; they are in the signature so `WalkStore::plantInto` can
     * call every area's `plant` alike. `$habit` names the crop, and the empty
     * string, a habit never sent, is sown as an umbel.
     */
    public function plant(string $seed, string $parentA, string $parentB, string $encounter,
                          float $height, int $family, string $kind = '', ?float $hue = null,
                          string $habit = ''): array
    {
        if (Ambassadors::isOne($seed)) {
            throw new LogicException('an ambassador cannot be planted: it is already standing');
        }

        $this->db->beginTransaction();
        try {
            $this->run('UPDATE home_ground_lock SET arrivals = arrivals + 1 WHERE id = 1');
            $existing = $this->db->prepare('SELECT * FROM home_ground WHERE seed = ?');
            $existing->execute([$seed]);
            if ($row = $existing->fetch()) {
                $this->db->rollBack();
                return [self::planting($row), false];
            }
            $all = $this->db->prepare('SELECT * FROM home_ground ORDER BY arrival');
            $all->execute();
            // The ambassador first, then the arrivals: it has claimed the west
            // bed of plot 0 for umbels whether or not anything else is here.
            $ways = array_merge(
                [Ambassadors::planting('ground')],
                array_map([self::class, 'forRule'], $all->fetchAll())
            );
            $p = HomeGround::plant($ways, $seed, $height, $family, $habit);
            $insert = $this->db->prepare('INSERT INTO home_ground
                (seed, parent_a, parent_b, encounter, plot, bed, crop, slot_index, height, family, habit, nudge_x, nudge_z)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $insert->execute([$seed, $parentA, $parentB, $encounter, $p['plot'], $p['bed'], $p['crop'],
                              $p['index'], $height, $family, $habit, $p['nudgeX'], $p['nudgeZ']]);
            $this->db->commit();
            return [self::planting(['seed' => $seed, 'parent_a' => $parentA, 'parent_b' => $parentB,
                'encounter' => $encounter, 'plot' => $p['plot'], 'bed' => $p['bed'], 'crop' => $p['crop'],
                'slot_index' => $p['index'], 'nudge_x' => $p['nudgeX'], 'nudge_z' => $p['nudgeZ']]), true];
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /**
     * A plot's plantings, in the order they arrived. Hidden ones are not in it.
     *
     * Plot 0 opens with the ambassador at the north end of the west bed. It
     * carries no parents and no meeting, because it was minted rather than
     * crossed, and an empty `parents` is how the wire says so.
     */
    public function plot(int $plot): array
    {
        $query = $this->db->prepare('SELECT * FROM home_ground WHERE plot = ? AND hidden = 0 ORDER BY arrival');
        $query->execute([$plot]);
        $plantings = array_map([self::class, 'planting'], $query->fetchAll());
        if ($plot !== 0) return $plantings;
        $standing = Ambassadors::planting('ground');
        [$x, $z] = HomeGround::spot($standing['bed'], $standing['crop'], $standing['index']);
        array_unshift($plantings, [
            'seed' => $standing['seed'],
            'parents' => [],
            'encounter' => null,
            'plot' => 0,
            'spot' => [$x + $standing['nudgeX'], $z + $standing['nudgeZ']],
        ]);
        return $plantings;
    }

    /**
     * Takes a planting back: out of the drawing, and out of the database but for
     * its place and its bed's crop. The area keeps the gap.
     */
    public function takeBack(string $seed): void
    {
        TakenBack::lift($this->db, 'home_ground', self::TAKEN_BACK, $seed);
    }

    /**
     * Plots opened. Never fewer than one: the Home Ground opened with its
     * ambassador in plot 0.
     */
    public function plots(): int
    {
        $query = $this->db->prepare('SELECT COALESCE(MAX(plot) + 1, 0) FROM home_ground');
        $query->execute();
        return max(1, (int) $query->fetchColumn());
    }

    /** What the page needs to grow a planting and stand it in its place: the five fields every area sends. */
    private static function planting(array $row): array
    {
        [$x, $z] = HomeGround::spot((int) $row['bed'], (string) $row['crop'], (int) $row['slot_index']);
        return [
            'seed' => $row['seed'],
            'parents' => [$row['parent_a'], $row['parent_b']],
            'encounter' => $row['encounter'],
            'plot' => (int) $row['plot'],
            'spot' => [$x + (float) $row['nudge_x'], $z + (float) $row['nudge_z']],
        ];
    }

    private static function forRule(array $row): array
    {
        return [
            'seed' => $row['seed'], 'plot' => (int) $row['plot'],
            'bed' => (int) $row['bed'], 'crop' => (string) $row['crop'],
            'index' => (int) $row['slot_index'],
            'height' => (float) $row['height'], 'family' => (int) $row['family'],
            'habit' => (string) $row['habit'],
        ];
    }
}
