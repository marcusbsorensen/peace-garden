<?php
declare(strict_types=1);

require_once __DIR__ . '/Ambassadors.php';
require_once __DIR__ . '/ColdFrame.php';

/**
 * The Cold Frame, stored: every planting in the order it arrived, never
 * changed.
 *
 * **A table of its own**, for the reason `RoomStore` gives and which seven
 * areas now put beyond argument: every column after `encounter` means
 * something different again. The walk's row names a side of a path and a tier
 * of a border, the room's a corner and a place in a group of three, the
 * crossing's a quarter and a place in a bed of six, the orchard's a tree and a
 * place in the ring under it, the knot's a compartment and a place in the block
 * of four filling it, the seedbed's a drill and how far along it, and this one
 * names a *frame*, which of its two ranks, and how far along that rank.
 *
 * **The rank is a column, where the Knot Garden's is not.** A knot's rank is a
 * function of the place (`KnotGarden::rankOf`), so storing it would be storing
 * the index twice. A frame's two ranks each run 0 to 5, so the index alone does
 * not say which rank a plant is in, and neither does its height: a plant is
 * put in the other rank when its own is full. It is `slot_rank` rather than
 * `rank` for the reason `slot_index` is not `index` — RANK is a reserved word
 * in MySQL 8 — and a column name that works on one database and not another is
 * a restore that fails on the day it is needed.
 *
 * **Nothing here records which colour claimed which frame.** The rule reads
 * that off the plants standing in the frame (`ColdFrame::familyOf`), so it is a
 * fact about the planting and not a second fact beside it. A `claimed_family`
 * column would be the same thing written twice, and the copy is the one that
 * can be wrong after a restore.
 *
 * **Nor the height the plant is drawn at.** Every plant here is drawn young,
 * and that is the page's business: the rule is decided by the grown height,
 * which is what is stored, as every area stores it.
 *
 * Everything else is `WalkStore`'s, deliberately: the same append-only insert,
 * the same lock row, the same hiding rather than deleting, and the same
 * ambassador handed to the rule ahead of the stored arrivals.
 */
final class ColdFrameStore
{
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
        $this->run("CREATE TABLE IF NOT EXISTS cold_frame (
            arrival $id,
            seed CHAR(64) NOT NULL UNIQUE,
            parent_a CHAR(64) NOT NULL,
            parent_b CHAR(64) NOT NULL,
            encounter CHAR(64) NOT NULL,
            plot INTEGER NOT NULL,
            frame INTEGER NOT NULL,
            slot_rank INTEGER NOT NULL,
            slot_index INTEGER NOT NULL,
            height DOUBLE PRECISION NOT NULL,
            family INTEGER NOT NULL,
            nudge_x DOUBLE PRECISION NOT NULL,
            nudge_z DOUBLE PRECISION NOT NULL,
            hidden INTEGER NOT NULL DEFAULT 0
        )");
        $this->run('CREATE INDEX IF NOT EXISTS cold_frame_plot ON cold_frame (plot)');
        $this->run('CREATE TABLE IF NOT EXISTS cold_frame_lock (id INTEGER PRIMARY KEY, arrivals INTEGER NOT NULL)');
        $this->run('INSERT INTO cold_frame_lock (id, arrivals) SELECT 1, 0 WHERE NOT EXISTS (SELECT 1 FROM cold_frame_lock)');
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
            $this->run('UPDATE cold_frame_lock SET arrivals = arrivals + 1 WHERE id = 1');
            $existing = $this->db->prepare('SELECT * FROM cold_frame WHERE seed = ?');
            $existing->execute([$seed]);
            if ($row = $existing->fetch()) {
                $this->db->rollBack();
                return [self::planting($row), false];
            }
            $all = $this->db->prepare('SELECT * FROM cold_frame ORDER BY arrival');
            $all->execute();
            // The ambassador first, then the arrivals: it stands in the front
            // rank of the first frame whether or not anything else is here, and
            // **it is what claimed that frame for its colour**. A reading that
            // left it out would hand the first frame to whoever arrived next,
            // and every plant of the ambassador's colour would then stand in a
            // frame of their own beside it.
            $ways = array_merge(
                [Ambassadors::planting('waiting')],
                array_map([self::class, 'forRule'], $all->fetchAll())
            );
            $p = ColdFrame::plant($ways, $seed, $height, $family);
            $insert = $this->db->prepare('INSERT INTO cold_frame
                (seed, parent_a, parent_b, encounter, plot, frame, slot_rank, slot_index, height, family, nudge_x, nudge_z)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $insert->execute([$seed, $parentA, $parentB, $encounter, $p['plot'], $p['frame'], $p['rank'],
                              $p['index'], $height, $family, $p['nudgeX'], $p['nudgeZ']]);
            $this->db->commit();
            return [self::planting(['seed' => $seed, 'parent_a' => $parentA, 'parent_b' => $parentB,
                'encounter' => $encounter, 'plot' => $p['plot'], 'frame' => $p['frame'],
                'slot_rank' => $p['rank'], 'slot_index' => $p['index'],
                'nudge_x' => $p['nudgeX'], 'nudge_z' => $p['nudgeZ']]), true];
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /**
     * A plot's plantings, in the order they arrived. Hidden ones are not in it.
     *
     * Plot 0 opens with the ambassador at the west end of the first frame's
     * front rank, which is not a row. It carries no parents and no meeting,
     * because it was minted rather than crossed, and an empty `parents` is how
     * the wire says so.
     */
    public function plot(int $plot): array
    {
        $query = $this->db->prepare('SELECT * FROM cold_frame WHERE plot = ? AND hidden = 0 ORDER BY arrival');
        $query->execute([$plot]);
        $plantings = array_map([self::class, 'planting'], $query->fetchAll());
        if ($plot !== 0) return $plantings;
        $standing = Ambassadors::planting('waiting');
        [$x, $z] = ColdFrame::spot($standing['frame'], $standing['rank'], $standing['index']);
        array_unshift($plantings, [
            'seed' => $standing['seed'],
            'parents' => [],
            'encounter' => null,
            'plot' => 0,
            'spot' => [$x + $standing['nudgeX'], $z + $standing['nudgeZ']],
        ]);
        return $plantings;
    }

    /** Takes a planting out of the drawing without taking it out of the area. */
    public function hide(string $seed): void
    {
        $update = $this->db->prepare('UPDATE cold_frame SET hidden = 1 WHERE seed = ?');
        $update->execute([$seed]);
    }

    /**
     * Plots opened. Never fewer than one: the Cold Frame opened with its
     * ambassador in plot 0.
     */
    public function plots(): int
    {
        $query = $this->db->prepare('SELECT COALESCE(MAX(plot) + 1, 0) FROM cold_frame');
        $query->execute();
        return max(1, (int) $query->fetchColumn());
    }

    /**
     * What the page needs to grow a planting and stand it in its place: the
     * same five fields every area sends. Which frame and rank a plant is in is
     * already in the spot, and the young height it is drawn at is the page's to
     * work out, so neither is on the wire.
     */
    private static function planting(array $row): array
    {
        [$x, $z] = ColdFrame::spot((int) $row['frame'], (int) $row['slot_rank'], (int) $row['slot_index']);
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
            'frame' => (int) $row['frame'], 'rank' => (int) $row['slot_rank'],
            'index' => (int) $row['slot_index'],
            'height' => (float) $row['height'], 'family' => (int) $row['family'],
        ];
    }
}
