<?php
declare(strict_types=1);

require_once __DIR__ . '/LongWalk.php';

/**
 * The Long Walk, stored: every planting in the order it arrived, never changed.
 *
 * **Append-only.** There is an insert and nothing else; a plant's place is
 * decided once, by `LongWalk::plant`, and kept. Arrivals are placed one at a
 * time under a lock, because two placed at once could both take the same slot.
 *
 * **What a planting keeps:** the child seed, both parents' seeds and the
 * meeting's ID (a hybrid cannot be grown from less; WEBSITE.md, amended 18
 * September), its slot, the height and colour family the rule placed it by,
 * and its nudge. No account, no address, no time: the order of the rows is the
 * order of arrival, and nothing else about the arrival is written down.
 *
 * PDO, so it runs on SQLite locally and on the 20i database once there is one.
 * Every statement with a value in it is prepared; the fixed ones run as they are.
 */
final class WalkStore
{
    private function __construct(private PDO $db) {}

    public static function open(string $dsn, ?string $user = null, ?string $password = null): self
    {
        $db = new PDO($dsn, $user, $password, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_STRINGIFY_FETCHES => false,
        ]);
        $store = new self($db);
        $store->migrate();
        return $store;
    }

    private function run(string $sql): void
    {
        $this->db->prepare($sql)->execute();
    }

    private function migrate(): void
    {
        $sqlite = $this->db->getAttribute(PDO::ATTR_DRIVER_NAME) === 'sqlite';
        $id = $sqlite ? 'INTEGER PRIMARY KEY AUTOINCREMENT' : 'BIGINT PRIMARY KEY AUTO_INCREMENT';
        // DOUBLE, because the rule compares heights and a stored height must
        // come back the same double it went in as.
        $this->run("CREATE TABLE IF NOT EXISTS long_walk (
            arrival $id,
            seed CHAR(64) NOT NULL UNIQUE,
            parent_a CHAR(64) NOT NULL,
            parent_b CHAR(64) NOT NULL,
            encounter CHAR(64) NOT NULL,
            plot INTEGER NOT NULL,
            side INTEGER NOT NULL,
            tier INTEGER NOT NULL,
            slot_index INTEGER NOT NULL,
            height DOUBLE PRECISION NOT NULL,
            family INTEGER NOT NULL,
            nudge_x DOUBLE PRECISION NOT NULL,
            nudge_z DOUBLE PRECISION NOT NULL
        )");
        $this->run('CREATE INDEX IF NOT EXISTS long_walk_plot ON long_walk (plot)');
        // One row, written first in every arrival's transaction: the write lock
        // that keeps two arrivals from being placed against the same walk.
        $this->run('CREATE TABLE IF NOT EXISTS long_walk_lock (id INTEGER PRIMARY KEY, arrivals INTEGER NOT NULL)');
        $this->run('INSERT INTO long_walk_lock (id, arrivals) SELECT 1, 0 WHERE NOT EXISTS (SELECT 1 FROM long_walk_lock)');
    }

    /**
     * Places one arrival by the rule and keeps it. Returns [the planting, whether
     * it is new]: a seed that has arrived before gets the place it already has,
     * because a plant has one place.
     */
    public function plant(string $seed, string $parentA, string $parentB, string $encounter,
                          float $height, int $family): array
    {
        $this->db->beginTransaction();
        try {
            $this->run('UPDATE long_walk_lock SET arrivals = arrivals + 1 WHERE id = 1');
            $existing = $this->db->prepare('SELECT * FROM long_walk WHERE seed = ?');
            $existing->execute([$seed]);
            if ($row = $existing->fetch()) {
                $this->db->rollBack();
                return [self::planting($row), false];
            }
            $all = $this->db->prepare('SELECT * FROM long_walk ORDER BY arrival');
            $all->execute();
            $walk = array_map([self::class, 'forRule'], $all->fetchAll());
            $p = LongWalk::plant($walk, $seed, $height, $family);
            $insert = $this->db->prepare('INSERT INTO long_walk
                (seed, parent_a, parent_b, encounter, plot, side, tier, slot_index, height, family, nudge_x, nudge_z)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $insert->execute([$seed, $parentA, $parentB, $encounter, $p['plot'], $p['side'], $p['tier'],
                              $p['index'], $height, $family, $p['nudgeX'], $p['nudgeZ']]);
            $this->db->commit();
            return [self::planting(['seed' => $seed, 'parent_a' => $parentA, 'parent_b' => $parentB,
                'encounter' => $encounter, 'plot' => $p['plot'], 'side' => $p['side'], 'tier' => $p['tier'],
                'slot_index' => $p['index'], 'nudge_x' => $p['nudgeX'], 'nudge_z' => $p['nudgeZ']]), true];
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /** A plot's plantings, in the order they arrived. */
    public function plot(int $plot): array
    {
        $query = $this->db->prepare('SELECT * FROM long_walk WHERE plot = ? ORDER BY arrival');
        $query->execute([$plot]);
        return array_map([self::class, 'planting'], $query->fetchAll());
    }

    public function plots(): int
    {
        $query = $this->db->prepare('SELECT COALESCE(MAX(plot) + 1, 0) FROM long_walk');
        $query->execute();
        return (int) $query->fetchColumn();
    }

    /** What the page needs to grow a planting and stand it in its place. */
    private static function planting(array $row): array
    {
        [$x, $z] = LongWalk::spot((int) $row['side'], (int) $row['tier'], (int) $row['slot_index']);
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
            'seed' => $row['seed'], 'plot' => (int) $row['plot'], 'side' => (int) $row['side'],
            'tier' => (int) $row['tier'], 'index' => (int) $row['slot_index'],
            'height' => (float) $row['height'], 'family' => (int) $row['family'],
        ];
    }
}
