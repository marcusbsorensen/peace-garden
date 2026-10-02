<?php
declare(strict_types=1);

require_once __DIR__ . '/Ambassadors.php';
require_once __DIR__ . '/TakenBack.php';
require_once __DIR__ . '/Crossing.php';

/**
 * The Crossing, stored: every planting in the order it arrived, never changed.
 *
 * **A table of its own**, for the reason `RoomStore` gives and which the third
 * area is the proof of: every column after `encounter` means something
 * different again. The walk's row names a side of a path and a tier of a
 * border, the room's a corner and a place in a group of three, and this one a
 * quarter and a place in a bed of six. Three areas, three schemas, no `area`
 * column — which is what `docs/WEB-GARDENS.md` predicted and what two areas
 * could only suggest.
 *
 * Everything else is `WalkStore`'s, deliberately: the same append-only insert,
 * the same lock row, the same taking back that keeps a place and erases the
 * plant, and the same ambassador handed to the rule ahead of the stored
 * arrivals.
 */
final class CrossStore
{
    /**
     * What a planting taken back has written over, beyond the seed, the parents,
     * the meeting and the nudge that every area writes over (`TakenBack.php`).
     * The family, which the Crossing's rule never reads: it ranks a quarter by
     * height alone and fills the emptiest one. The height stays, because a
     * quarter is graded outward by it.
     */
    private const TAKEN_BACK = ['family' => 0];

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
        $this->run("CREATE TABLE IF NOT EXISTS crossing (
            arrival $id,
            seed CHAR(64) NOT NULL UNIQUE,
            parent_a CHAR(64) NOT NULL,
            parent_b CHAR(64) NOT NULL,
            encounter CHAR(64) NOT NULL,
            plot INTEGER NOT NULL,
            quarter INTEGER NOT NULL,
            slot_index INTEGER NOT NULL,
            height DOUBLE PRECISION NOT NULL,
            family INTEGER NOT NULL,
            nudge_x DOUBLE PRECISION NOT NULL,
            nudge_z DOUBLE PRECISION NOT NULL,
            hidden INTEGER NOT NULL DEFAULT 0
        )");
        $this->run('CREATE INDEX IF NOT EXISTS crossing_plot ON crossing (plot)');
        $this->run('CREATE TABLE IF NOT EXISTS crossing_lock (id INTEGER PRIMARY KEY, arrivals INTEGER NOT NULL)');
        $this->run('INSERT INTO crossing_lock (id, arrivals) SELECT 1, 0 WHERE NOT EXISTS (SELECT 1 FROM crossing_lock)');
        // Added on 24 September, when taking back began to delete: a row hidden
        // before then still holds the seed, the parents and the meeting, and
        // this erases it. Every request, and nothing to do once it has run.
        $this->run('CREATE INDEX IF NOT EXISTS crossing_hidden ON crossing (hidden)');
        TakenBack::sweep($this->db, 'crossing', self::TAKEN_BACK);
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
            $this->run('UPDATE crossing_lock SET arrivals = arrivals + 1 WHERE id = 1');
            $existing = $this->db->prepare('SELECT * FROM crossing WHERE seed = ?');
            $existing->execute([$seed]);
            if ($row = $existing->fetch()) {
                $this->db->rollBack();
                return [self::planting($row), false];
            }
            $all = $this->db->prepare('SELECT * FROM crossing ORDER BY arrival');
            $all->execute();
            // The ambassador first, then the arrivals: it stands in the first
            // quarter of plot 0 — in the middle rank's first place since 28
            // September 2026, on the diagonal before — whether or not anything else is here,
            // and the rule counts what is in a quarter to decide where to put
            // the next plant. A count that left it out would be the wrong count.
            $ways = array_merge(
                [Ambassadors::planting('meeting')],
                array_map([self::class, 'forRule'], $all->fetchAll())
            );
            $p = Crossing::plant($ways, $seed, $height, $family);
            $insert = $this->db->prepare('INSERT INTO crossing
                (seed, parent_a, parent_b, encounter, plot, quarter, slot_index, height, family, nudge_x, nudge_z)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $insert->execute([$seed, $parentA, $parentB, $encounter, $p['plot'], $p['quarter'],
                              $p['index'], $height, $family, $p['nudgeX'], $p['nudgeZ']]);
            $this->db->commit();
            return [self::planting(['seed' => $seed, 'parent_a' => $parentA, 'parent_b' => $parentB,
                'encounter' => $encounter, 'plot' => $p['plot'], 'quarter' => $p['quarter'],
                'slot_index' => $p['index'], 'nudge_x' => $p['nudgeX'], 'nudge_z' => $p['nudgeZ']]), true];
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /**
     * A plot's plantings, in the order they arrived. Hidden ones are not in it.
     *
     * Plot 0 opens with the ambassador in the first quarter, in the middle
     * rank's first place since 28 September 2026, which is not a row. It carries no parents and no meeting, because it was minted
     * rather than crossed, and an empty `parents` is how the wire says so.
     */
    public function plot(int $plot): array
    {
        $query = $this->db->prepare('SELECT * FROM crossing WHERE plot = ? AND hidden = 0 ORDER BY arrival');
        $query->execute([$plot]);
        $plantings = array_map([self::class, 'planting'], $query->fetchAll());
        if ($plot !== 0) return $plantings;
        $standing = Ambassadors::planting('meeting');
        array_unshift($plantings, [
            'seed' => $standing['seed'],
            'parents' => [],
            'encounter' => null,
            'plot' => 0,
            'spot' => Crossing::spotOn(0, $standing['quarter'], $standing['index'],
                                       $standing['nudgeX'], $standing['nudgeZ']),
        ]);
        return $plantings;
    }

    /**
     * Takes a planting back: out of the drawing, and out of the database but for
     * its place and what the rule reads. The area keeps the gap.
     */
    public function takeBack(string $seed): void
    {
        TakenBack::lift($this->db, 'crossing', self::TAKEN_BACK, $seed);
    }

    /**
     * Plots opened. Never fewer than one: the Crossing opened with its
     * ambassador in plot 0.
     */
    public function plots(): int
    {
        $query = $this->db->prepare('SELECT COALESCE(MAX(plot) + 1, 0) FROM crossing');
        $query->execute();
        return max(1, (int) $query->fetchColumn());
    }

    /** What the page needs to grow a planting and stand it in its place. */
    private static function planting(array $row): array
    {
        // Where it stands on its plot, turned as the plot is laid (2 October
        // 2026). A row taken back has no nudge left, and stands on its place.
        return [
            'seed' => $row['seed'],
            'parents' => [$row['parent_a'], $row['parent_b']],
            'encounter' => $row['encounter'],
            'plot' => (int) $row['plot'],
            'spot' => Crossing::spotOn((int) $row['plot'], (int) $row['quarter'], (int) $row['slot_index'],
                                       (float) $row['nudge_x'], (float) $row['nudge_z']),
        ];
    }

    private static function forRule(array $row): array
    {
        return [
            'seed' => $row['seed'], 'plot' => (int) $row['plot'], 'quarter' => (int) $row['quarter'],
            'index' => (int) $row['slot_index'],
            'height' => (float) $row['height'], 'family' => (int) $row['family'],
        ];
    }
}
