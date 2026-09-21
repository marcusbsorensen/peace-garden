<?php
declare(strict_types=1);

require_once __DIR__ . '/Ambassadors.php';
require_once __DIR__ . '/Areas.php';
require_once __DIR__ . '/LongWalk.php';
require_once __DIR__ . '/RoomStore.php';
require_once __DIR__ . '/Offers.php';

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
 * **The ambassador is not in it.** *Halula crassicaulis* stands at the head of
 * plot 0 and has done since before the walk had a row in it, but nobody offered
 * it and nobody can take it back, so it is not in the table of plants people
 * offered. `Ambassadors::planting('travel')` derives its slot from the pinned
 * seed, and this class puts it in front of the rule when placing and in front
 * of a plot when serving one. Nothing about it is stored, so there is no row
 * for `hide` to reach and none for a backup to carry.
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
        // The Quiet Garden's tables too, rather than when somebody first asks
        // for it. They cost one `CREATE TABLE IF NOT EXISTS` a request, and a
        // table that does not exist until the first visitor is a table the
        // nightly copy does not know to keep.
        $store->room();
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
        // Added after the table was live, so it is an ALTER that may already
        // have run. A planting taken back is hidden rather than deleted: the
        // walk is append-only and nothing in it moves, so the row stays, keeps
        // its slot, and simply is not drawn. The border is left with a gap,
        // which is what lifting a plant out of one leaves.
        try {
            $this->run('ALTER TABLE long_walk ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0');
        } catch (Throwable) {
            // Already there.
        }
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
        // **Never an ambassador.** Unreachable from any route today: the offer
        // and plant routes both check that the seed is the cross of its two
        // parents at their meeting, and an ambassador is minted rather than
        // crossed, so no caller can produce parents that hash to one. This is
        // what keeps it unreachable the day somebody adds a route that plants a
        // minted seed. It is a bug and not a refusal, so it is thrown.
        if (Ambassadors::isOne($seed)) {
            throw new LogicException('an ambassador cannot be planted: it is already standing');
        }

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
            // **The ambassador first, then the arrivals.** It is standing in
            // plot 0 whether or not anything else is, so the rule has to see it:
            // a plant graded against a border that is missing its oldest plant
            // is graded against a border that is not there. It is prepended
            // rather than stored, because its slot is a pure function of its
            // pinned seed and comes back the same every time it is asked for.
            $walk = array_merge(
                [Ambassadors::planting('travel')],
                array_map([self::class, 'forRule'], $all->fetchAll())
            );
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

    /**
     * A plot's plantings, in the order they arrived. Hidden ones are not in it.
     *
     * Plot 0 opens with the ambassador, which arrived before all of them and is
     * not a row. It carries no parents and no meeting, because it has neither:
     * a reader grows it from its seed alone rather than from a lineage, and an
     * empty `parents` is how it says so without a new field on the wire.
     */
    public function plot(int $plot): array
    {
        $query = $this->db->prepare('SELECT * FROM long_walk WHERE plot = ? AND hidden = 0 ORDER BY arrival');
        $query->execute([$plot]);
        $plantings = array_map([self::class, 'planting'], $query->fetchAll());
        $standing = $plot === 0 ? Ambassadors::planting('travel') : null;
        if ($standing === null) return $plantings;
        [$x, $z] = LongWalk::spot($standing['side'], $standing['tier'], $standing['index']);
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
     * Takes a planting out of the drawing without taking it out of the walk.
     *
     * The row stays and keeps its slot, so nothing already placed moves and
     * nothing new is placed where it stood. `plant` still reads it, which is
     * the point: the rule saw it when it placed everything around it, and a
     * rule that stopped seeing it would be a different rule.
     */
    public function hide(string $seed): void
    {
        $update = $this->db->prepare('UPDATE long_walk SET hidden = 1 WHERE seed = ?');
        $update->execute([$seed]);
    }

    /** The asking that decides what ever reaches the walk. */
    public function offers(): Offers
    {
        return new Offers($this->db, $this);
    }

    /// The same connection, for the parts of the service that keep their own
    /// tables beside the walk rather than in it.
    public function connection(): PDO { return $this->db; }

    /**
     * The Quiet Garden, on the same connection.
     *
     * **This class has outgrown its name**, which is a thing worth saying
     * rather than quietly fixing: it opened the database for a service that was
     * only the Long Walk, and now it holds the connection for a garden with two
     * areas in it and eight to come. Renaming it means touching every caller and
     * the reference checks in one go, which is a commit of its own and not this
     * one. `Offers` and `Limits` already reach through it the same way.
     */
    public function room(): RoomStore
    {
        static $room = null;
        return $room ??= new RoomStore($this->db);
    }

    /**
     * Plants one arrival into whichever area it belongs to.
     *
     * The one place that knows an area's name maps to a table. Everything above
     * it — the asking, the routes — carries the area as a word and never a
     * table, so an area that opens is a case here rather than a change
     * everywhere.
     */
    public function plantInto(string $area, string $seed, string $parentA, string $parentB,
                              string $encounter, float $height, int $family): array
    {
        return match ($area) {
            'peace' => $this->room()->plant($seed, $parentA, $parentB, $encounter, $height, $family),
            default => $this->plant($seed, $parentA, $parentB, $encounter, $height, $family),
        };
    }

    /** Takes a planting out of the drawing, in whichever area holds it. */
    public function hideIn(string $area, string $seed): void
    {
        if ($area === 'peace') { $this->room()->hide($seed); return; }
        $this->hide($seed);
    }

    /**
     * Plots opened. Never fewer than one: the walk opened with its ambassador
     * in plot 0, so there has been somewhere to walk since before anybody
     * shared anything.
     */
    public function plots(): int
    {
        $query = $this->db->prepare('SELECT COALESCE(MAX(plot) + 1, 0) FROM long_walk');
        $query->execute();
        return max(1, (int) $query->fetchColumn());
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
