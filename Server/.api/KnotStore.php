<?php
declare(strict_types=1);

require_once __DIR__ . '/Ambassadors.php';
require_once __DIR__ . '/TakenBack.php';
require_once __DIR__ . '/KnotGarden.php';

/**
 * The Knot Garden, stored: every planting in the order it arrived, never
 * changed.
 *
 * **A table of its own**, for the reason `RoomStore` gives and which five areas
 * now put beyond argument: every column after `encounter` means something
 * different again. The walk's row names a side of a path and a tier of a
 * border, the room's a corner and a place in a group of three, the crossing's a
 * quarter and a place in a bed of six, the orchard's a tree and a place in the
 * ring under it, and this one names a *compartment of a knot* and a place in
 * the block of four filling it.
 *
 * **Nothing here records which colour claimed which pair.** The rule reads that
 * off the plants standing in the pair, so it is a fact about the planting and
 * not a second fact beside it. A `claimed_family` column would be the same
 * thing written twice, and the copy is the one that can be wrong after a
 * restore.
 *
 * Everything else is `WalkStore`'s, deliberately: the same append-only insert,
 * the same lock row, the same taking back that keeps a place and erases the
 * plant, and the same ambassador handed to the rule ahead of the stored
 * arrivals.
 */
final class KnotStore
{
    /**
     * What a planting taken back has written over, beyond the seed, the parents,
     * the meeting and the nudge that every area writes over (`TakenBack.php`).
     * Nothing: the knot's rule reads the family of the first plant in each pair,
     * which is the pair's claim, and the height of every plant in a
     * compartment, which grades it. Both stay.
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
        $this->run("CREATE TABLE IF NOT EXISTS knot_garden (
            arrival $id,
            seed CHAR(64) NOT NULL UNIQUE,
            parent_a CHAR(64) NOT NULL,
            parent_b CHAR(64) NOT NULL,
            encounter CHAR(64) NOT NULL,
            plot INTEGER NOT NULL,
            compartment INTEGER NOT NULL,
            slot_index INTEGER NOT NULL,
            height DOUBLE PRECISION NOT NULL,
            family INTEGER NOT NULL,
            nudge_x DOUBLE PRECISION NOT NULL,
            nudge_z DOUBLE PRECISION NOT NULL,
            hidden INTEGER NOT NULL DEFAULT 0
        )");
        $this->run('CREATE INDEX IF NOT EXISTS knot_garden_plot ON knot_garden (plot)');
        $this->run('CREATE TABLE IF NOT EXISTS knot_garden_lock (id INTEGER PRIMARY KEY, arrivals INTEGER NOT NULL)');
        $this->run('INSERT INTO knot_garden_lock (id, arrivals) SELECT 1, 0 WHERE NOT EXISTS (SELECT 1 FROM knot_garden_lock)');
        // Added on 24 September, when taking back began to delete: a row hidden
        // before then still holds the seed, the parents and the meeting, and
        // this erases it. Every request, and nothing to do once it has run.
        $this->run('CREATE INDEX IF NOT EXISTS knot_garden_hidden ON knot_garden (hidden)');
        TakenBack::sweep($this->db, 'knot_garden', self::TAKEN_BACK);
    }

    /**
     * Places one arrival by the rule and keeps it. Returns [the planting,
     * whether it is new]: a seed that has arrived before gets the place it
     * already has, because a plant has one place.
     *
     * `$kind` is the Seedbed's trait and nothing here reads it; it is in the
     * signature so `WalkStore::plantInto` can call every area's `plant` alike.
     */
    public function plant(string $seed, string $parentA, string $parentB, string $encounter,
                          float $height, int $family, string $kind = ''): array
    {
        if (Ambassadors::isOne($seed)) {
            throw new LogicException('an ambassador cannot be planted: it is already standing');
        }

        $this->db->beginTransaction();
        try {
            $this->run('UPDATE knot_garden_lock SET arrivals = arrivals + 1 WHERE id = 1');
            $existing = $this->db->prepare('SELECT * FROM knot_garden WHERE seed = ?');
            $existing->execute([$seed]);
            if ($row = $existing->fetch()) {
                $this->db->rollBack();
                return [self::planting($row), false];
            }
            $all = $this->db->prepare('SELECT * FROM knot_garden ORDER BY arrival');
            $all->execute();
            // The ambassador first, then the arrivals: it stands in the north
            // compartment of plot 0 whether or not anything else is here, and
            // **it is what claimed that pair for its colour**. A reading that
            // left it out would hand the first pair to whoever arrived next.
            $ways = array_merge(
                [Ambassadors::planting('pattern')],
                array_map([self::class, 'forRule'], $all->fetchAll())
            );
            $p = KnotGarden::plant($ways, $seed, $height, $family);
            $insert = $this->db->prepare('INSERT INTO knot_garden
                (seed, parent_a, parent_b, encounter, plot, compartment, slot_index, height, family, nudge_x, nudge_z)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $insert->execute([$seed, $parentA, $parentB, $encounter, $p['plot'], $p['compartment'],
                              $p['index'], $height, $family, $p['nudgeX'], $p['nudgeZ']]);
            $this->db->commit();
            return [self::planting(['seed' => $seed, 'parent_a' => $parentA, 'parent_b' => $parentB,
                'encounter' => $encounter, 'plot' => $p['plot'], 'compartment' => $p['compartment'],
                'slot_index' => $p['index'], 'nudge_x' => $p['nudgeX'], 'nudge_z' => $p['nudgeZ']]), true];
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /**
     * A plot's plantings, in the order they arrived. Hidden ones are not in it.
     *
     * Plot 0 opens with the ambassador in the north compartment, which is not a
     * row. It carries no parents and no meeting, because it was minted rather
     * than crossed, and an empty `parents` is how the wire says so.
     */
    public function plot(int $plot): array
    {
        $query = $this->db->prepare('SELECT * FROM knot_garden WHERE plot = ? AND hidden = 0 ORDER BY arrival');
        $query->execute([$plot]);
        $plantings = array_map([self::class, 'planting'], $query->fetchAll());
        if ($plot !== 0) return $plantings;
        $standing = Ambassadors::planting('pattern');
        [$x, $z] = KnotGarden::spot($standing['compartment'], $standing['index']);
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
     * its place and what the rule reads. The area keeps the gap.
     */
    public function takeBack(string $seed): void
    {
        TakenBack::lift($this->db, 'knot_garden', self::TAKEN_BACK, $seed);
    }

    /**
     * Plots opened. Never fewer than one: the Knot Garden opened with its
     * ambassador in plot 0.
     */
    public function plots(): int
    {
        $query = $this->db->prepare('SELECT COALESCE(MAX(plot) + 1, 0) FROM knot_garden');
        $query->execute();
        return max(1, (int) $query->fetchColumn());
    }

    /** What the page needs to grow a planting and stand it in its place. */
    private static function planting(array $row): array
    {
        [$x, $z] = KnotGarden::spot((int) $row['compartment'], (int) $row['slot_index']);
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
            'compartment' => (int) $row['compartment'], 'index' => (int) $row['slot_index'],
            'height' => (float) $row['height'], 'family' => (int) $row['family'],
        ];
    }
}
