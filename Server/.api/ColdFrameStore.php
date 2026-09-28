<?php
declare(strict_types=1);

require_once __DIR__ . '/Ambassadors.php';
require_once __DIR__ . '/TakenBack.php';
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
 * **`slot_span` is how many places a planting holds**, since 25 September 2026,
 * when a lotus began to take two (`ColdFrame::span`). It is part of the place,
 * like the rank: the index alone does not say where a lotus stands, and the
 * next plant along its rank is placed after both its places. Stored rather than
 * read again off the habit, because a planting made before the rule holds one
 * place whatever it is, and the column's default of 1 says so for every row
 * that was there when it was added. **`habit` is stored beside it** because a
 * replant regrows every plant and the rehearsal plants them again through this
 * store, which needs the habit to give the same span; the rule itself reads
 * only the arriving plant's.
 *
 * Everything else is `WalkStore`'s, deliberately: the same append-only insert,
 * the same lock row, the same taking back that keeps a place and erases the
 * plant, and the same ambassador handed to the rule ahead of the stored
 * arrivals.
 */
final class ColdFrameStore
{
    /**
     * What a planting taken back has written over, beyond the seed, the parents,
     * the meeting and the nudge that every area writes over (`TakenBack.php`):
     * its habit. The frame's rule reads the family of the first plant in each
     * frame, which is the frame's claim, and the height of every plant in it,
     * which orders its two ranks. Both stay, with the rank, which is a column
     * here because the slot alone does not say it, and the span, which is how
     * many places it keeps. The habit is read only of a plant arriving.
     */
    private const TAKEN_BACK = ['habit' => ''];

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
            slot_span INTEGER NOT NULL DEFAULT 1,
            height DOUBLE PRECISION NOT NULL,
            family INTEGER NOT NULL,
            habit VARCHAR(16) NOT NULL DEFAULT '',
            nudge_x DOUBLE PRECISION NOT NULL,
            nudge_z DOUBLE PRECISION NOT NULL,
            hidden INTEGER NOT NULL DEFAULT 0
        )");
        $this->run('CREATE INDEX IF NOT EXISTS cold_frame_plot ON cold_frame (plot)');
        $this->run('CREATE TABLE IF NOT EXISTS cold_frame_lock (id INTEGER PRIMARY KEY, arrivals INTEGER NOT NULL)');
        $this->run('INSERT INTO cold_frame_lock (id, arrivals) SELECT 1, 0 WHERE NOT EXISTS (SELECT 1 FROM cold_frame_lock)');
        // Added on 24 September, when taking back began to delete: a row hidden
        // before then still holds the seed, the parents and the meeting, and
        // this erases it. Every request, and nothing to do once it has run.
        $this->run('CREATE INDEX IF NOT EXISTS cold_frame_hidden ON cold_frame (hidden)');
        // Added on 25 September, when a lotus began to take two places. ALTERs
        // that may already have run, as `Offers` adds its columns, and plain
        // `ADD COLUMN` because MySQL has no `IF NOT EXISTS` for one: on a table
        // that has them they fail, and that is the answer. Every row already
        // there holds one place, which is what the old rule gave it, and has no
        // habit, which nothing reads of a plant already standing.
        foreach (["slot_span INTEGER NOT NULL DEFAULT 1", "habit VARCHAR(16) NOT NULL DEFAULT ''"] as $column) {
            try {
                $this->run("ALTER TABLE cold_frame ADD COLUMN $column");
            } catch (Throwable) {
                // Already there.
            }
        }
        TakenBack::sweep($this->db, 'cold_frame', self::TAKEN_BACK);
    }

    /**
     * Places one arrival by the rule and keeps it. Returns [the planting,
     * whether it is new]: a seed that has arrived before gets the place it
     * already has, because a plant has one place.
     *
     * `$kind` and `$hue` are the Seedbed's and the Glasshouse's, and nothing
     * here reads them; they are in the signature so `WalkStore::plantInto` can
     * call every area's `plant` alike. `$habit` says whether the plant is a
     * lotus, which takes two places; the empty string, a habit never sent, takes
     * one.
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
            $this->run('UPDATE cold_frame_lock SET arrivals = arrivals + 1 WHERE id = 1');
            $existing = $this->db->prepare('SELECT * FROM cold_frame WHERE seed = ?');
            $existing->execute([$seed]);
            if ($row = $existing->fetch()) {
                $this->db->rollBack();
                return [self::planting($row), false];
            }
            $all = $this->db->prepare('SELECT * FROM cold_frame ORDER BY arrival');
            $all->execute();
            // The ambassador first, then the arrivals: it stands at the west
            // end of the tank's first row whether or not anything else is here,
            // **and it holds that place**. A reading that left it out would hand
            // the place to the next plant that wants water, and two would be
            // drawn floating in one. (Until the tank was sunk on 27 September it
            // stood in the first frame and claimed it for its colour.)
            $ways = array_merge(
                [Ambassadors::planting('waiting')],
                array_map([self::class, 'forRule'], $all->fetchAll())
            );
            $p = ColdFrame::plant($ways, $seed, $height, $family, $habit);
            $insert = $this->db->prepare('INSERT INTO cold_frame
                (seed, parent_a, parent_b, encounter, plot, frame, slot_rank, slot_index, slot_span,
                 height, family, habit, nudge_x, nudge_z)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $insert->execute([$seed, $parentA, $parentB, $encounter, $p['plot'], $p['frame'], $p['rank'],
                              $p['index'], $p['span'], $height, $family, $habit, $p['nudgeX'], $p['nudgeZ']]);
            $this->db->commit();
            return [self::planting(['seed' => $seed, 'parent_a' => $parentA, 'parent_b' => $parentB,
                'encounter' => $encounter, 'plot' => $p['plot'], 'frame' => $p['frame'],
                'slot_rank' => $p['rank'], 'slot_index' => $p['index'], 'slot_span' => $p['span'],
                'nudge_x' => $p['nudgeX'], 'nudge_z' => $p['nudgeZ']]), true];
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /**
     * A plot's plantings, in the order they arrived. Hidden ones are not in it.
     *
     * Plot 0 opens with the ambassador at the west end of the tank's first
     * row, one place, since it is a lotus and a lotus is in the water — which
     * is not a row. It carries no parents and no meeting,
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
        [$x, $z] = ColdFrame::spot($standing['frame'], $standing['rank'], $standing['index'], $standing['span']);
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
        TakenBack::lift($this->db, 'cold_frame', self::TAKEN_BACK, $seed);
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
     * already in the spot, and so is a lotus's standing across two places — the
     * spot is their middle — and the young height it is drawn at is the page's
     * to work out, so none of them is on the wire.
     */
    private static function planting(array $row): array
    {
        [$x, $z] = ColdFrame::spot((int) $row['frame'], (int) $row['slot_rank'], (int) $row['slot_index'],
                                   (int) ($row['slot_span'] ?? 1));
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
            'index' => (int) $row['slot_index'], 'span' => (int) $row['slot_span'],
            'height' => (float) $row['height'], 'family' => (int) $row['family'],
            'habit' => (string) $row['habit'],
        ];
    }
}
