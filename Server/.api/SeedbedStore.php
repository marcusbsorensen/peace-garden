<?php
declare(strict_types=1);

require_once __DIR__ . '/Ambassadors.php';
require_once __DIR__ . '/TakenBack.php';
require_once __DIR__ . '/Seedbed.php';

/**
 * The Seedbed, stored: every planting in the order it arrived, never changed.
 *
 * **A table of its own**, for the reason `RoomStore` gives and which six areas
 * now put beyond argument: every column after `encounter` means something
 * different again. The walk's row names a side of a path and a tier of a border,
 * the room's a corner and a place in a group of three, the crossing's a quarter
 * and a place in a bed of six, the orchard's a tree and a place in the ring
 * under it, the knot's a compartment and a place in the block of four filling
 * it, and this one names a *drill* and how far along it a plant stands.
 *
 * **`kind` is a column here and nowhere else.** It is the plant's epithet, and
 * it is the one trait this area's rule reads — a drill is claimed by the kind of
 * the first plant sown in it. It is stored because the service cannot grow the
 * plant to read it again: the phone sends it with the arrival, exactly as the
 * height and the colour family are sent. `DEFAULT ''` because a planting made
 * before the column existed has no epithet to give, and an empty kind is a kind
 * like any other — unnamed plants join the drill of unnamed plants.
 *
 * **Nothing here records which kind claimed which drill.** The rule reads that
 * off the plants standing in the drill (`Seedbed::kindOf`), so it is a fact
 * about the planting and not a second fact beside it. A `claimed_kind` column
 * would be the same thing written twice, and the copy is the one that can be
 * wrong after a restore.
 *
 * Everything else is `WalkStore`'s, deliberately: the same append-only insert,
 * the same lock row, the same taking back that keeps a place and erases the
 * plant, and the same ambassador handed to the rule ahead of the stored
 * arrivals.
 */
final class SeedbedStore
{
    /**
     * What a planting taken back has written over, beyond the seed, the parents,
     * the meeting and the nudge that every area writes over (`TakenBack.php`).
     * The height and the family, which the Seedbed's rule never reads. The kind
     * stays: the first plant sown in a drill is what claimed it, and a drill
     * whose claim had been blanked would be handed to the next kind to arrive.
     * The slot stays too, though the rule counts a drill rather than reading
     * it, because it is where the gap is.
     */
    private const TAKEN_BACK = ['height' => 0.0, 'family' => 0];

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
        $this->run("CREATE TABLE IF NOT EXISTS seedbed (
            arrival $id,
            seed CHAR(64) NOT NULL UNIQUE,
            parent_a CHAR(64) NOT NULL,
            parent_b CHAR(64) NOT NULL,
            encounter CHAR(64) NOT NULL,
            plot INTEGER NOT NULL,
            drill INTEGER NOT NULL,
            slot_index INTEGER NOT NULL,
            height DOUBLE PRECISION NOT NULL,
            family INTEGER NOT NULL,
            kind VARCHAR(64) NOT NULL DEFAULT '',
            nudge_x DOUBLE PRECISION NOT NULL,
            nudge_z DOUBLE PRECISION NOT NULL,
            hidden INTEGER NOT NULL DEFAULT 0
        )");
        $this->run('CREATE INDEX IF NOT EXISTS seedbed_plot ON seedbed (plot)');
        $this->run('CREATE TABLE IF NOT EXISTS seedbed_lock (id INTEGER PRIMARY KEY, arrivals INTEGER NOT NULL)');
        $this->run('INSERT INTO seedbed_lock (id, arrivals) SELECT 1, 0 WHERE NOT EXISTS (SELECT 1 FROM seedbed_lock)');
        // Added on 24 September, when taking back began to delete: a row hidden
        // before then still holds the seed, the parents and the meeting, and
        // this erases it. Every request, and nothing to do once it has run.
        $this->run('CREATE INDEX IF NOT EXISTS seedbed_hidden ON seedbed (hidden)');
        TakenBack::sweep($this->db, 'seedbed', self::TAKEN_BACK);
    }

    /**
     * Places one arrival by the rule and keeps it. Returns [the planting,
     * whether it is new]: a seed that has arrived before gets the place it
     * already has, because a plant has one place.
     */
    public function plant(string $seed, string $parentA, string $parentB, string $encounter,
                          float $height, int $family, string $kind = ''): array
    {
        if (Ambassadors::isOne($seed)) {
            throw new LogicException('an ambassador cannot be planted: it is already standing');
        }

        $this->db->beginTransaction();
        try {
            $this->run('UPDATE seedbed_lock SET arrivals = arrivals + 1 WHERE id = 1');
            $existing = $this->db->prepare('SELECT * FROM seedbed WHERE seed = ?');
            $existing->execute([$seed]);
            if ($row = $existing->fetch()) {
                $this->db->rollBack();
                return [self::planting($row), false];
            }
            $all = $this->db->prepare('SELECT * FROM seedbed ORDER BY arrival');
            $all->execute();
            // The ambassador first, then the arrivals: it stands at the head of
            // the first drill whether or not anything else is here, and **it is
            // what claimed that drill for its kind**. A reading that left it out
            // would hand drill 0 to whoever arrived next, and every plant of the
            // ambassador's kind would then be sown somewhere else.
            $ways = array_merge(
                [Ambassadors::planting('beginnings')],
                array_map([self::class, 'forRule'], $all->fetchAll())
            );
            $p = Seedbed::plant($ways, $seed, $height, $family, $kind);
            $insert = $this->db->prepare('INSERT INTO seedbed
                (seed, parent_a, parent_b, encounter, plot, drill, slot_index, height, family, kind, nudge_x, nudge_z)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $insert->execute([$seed, $parentA, $parentB, $encounter, $p['plot'], $p['drill'],
                              $p['index'], $height, $family, $kind, $p['nudgeX'], $p['nudgeZ']]);
            $this->db->commit();
            return [self::planting(['seed' => $seed, 'parent_a' => $parentA, 'parent_b' => $parentB,
                'encounter' => $encounter, 'plot' => $p['plot'], 'drill' => $p['drill'],
                'slot_index' => $p['index'], 'kind' => $kind,
                'nudge_x' => $p['nudgeX'], 'nudge_z' => $p['nudgeZ']]), true];
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /**
     * A plot's plantings, in the order they arrived. Hidden ones are not in it.
     *
     * Plot 0 opens with the ambassador at the head of drill 0, which is not a
     * row. It carries no parents and no meeting, because it was minted rather
     * than crossed, and an empty `parents` is how the wire says so.
     */
    public function plot(int $plot): array
    {
        $query = $this->db->prepare('SELECT * FROM seedbed WHERE plot = ? AND hidden = 0 ORDER BY arrival');
        $query->execute([$plot]);
        $plantings = array_map([self::class, 'planting'], $query->fetchAll());
        if ($plot !== 0) return $plantings;
        $standing = Ambassadors::planting('beginnings');
        [$x, $z] = Seedbed::spot($standing['drill'], $standing['index']);
        array_unshift($plantings, [
            'seed' => $standing['seed'],
            'parents' => [],
            'encounter' => null,
            'plot' => 0,
            'drill' => $standing['drill'],
            'kind' => $standing['kind'],
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
        TakenBack::lift($this->db, 'seedbed', self::TAKEN_BACK, $seed);
    }

    /**
     * Plots opened. Never fewer than one: the Seedbed opened with its ambassador
     * in plot 0.
     */
    public function plots(): int
    {
        $query = $this->db->prepare('SELECT COALESCE(MAX(plot) + 1, 0) FROM seedbed');
        $query->execute();
        return max(1, (int) $query->fetchColumn());
    }

    /**
     * What the page needs to grow a planting, stand it in its place, and name
     * the drill it stands in. The kind is on the wire because the page cannot
     * recover it: an epithet is read off a grown plant, and the page grows a
     * plant to draw it, not to name it. Nothing on the label says it either.
     */
    private static function planting(array $row): array
    {
        [$x, $z] = Seedbed::spot((int) $row['drill'], (int) $row['slot_index']);
        return [
            'seed' => $row['seed'],
            'parents' => [$row['parent_a'], $row['parent_b']],
            'encounter' => $row['encounter'],
            'plot' => (int) $row['plot'],
            'drill' => (int) $row['drill'],
            'kind' => (string) $row['kind'],
            'spot' => [$x + (float) $row['nudge_x'], $z + (float) $row['nudge_z']],
        ];
    }

    private static function forRule(array $row): array
    {
        return [
            'seed' => $row['seed'], 'plot' => (int) $row['plot'],
            'drill' => (int) $row['drill'], 'index' => (int) $row['slot_index'],
            'height' => (float) $row['height'], 'family' => (int) $row['family'],
            'kind' => (string) $row['kind'],
        ];
    }
}
