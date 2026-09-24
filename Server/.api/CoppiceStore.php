<?php
declare(strict_types=1);

require_once __DIR__ . '/Ambassadors.php';
require_once __DIR__ . '/TakenBack.php';
require_once __DIR__ . '/Coppice.php';

/**
 * The Coppice, stored: every planting in the order it arrived, never changed.
 *
 * **A table of its own**, for the reason `RoomStore` gives: every column after
 * `encounter` means something different again. This one names a *coupe*, the
 * *place* in it — a stool, the back row of the floor or the front — and where
 * along that row.
 *
 * **`habit` is a column here and nowhere else.** It is the one trait this
 * area's rule reads that no other does: of the plant arriving, to say whether it
 * stands on a stool, and of the plants already standing, to keep the floor to
 * one fern a coupe. So a planting taken back keeps it (`TAKEN_BACK`). The empty
 * string is a habit never sent, which the rule reads as a star's.
 *
 * **Nothing here records a coupe's stage.** It is arithmetic on the plot, the
 * coupe and the year (`Coppice::stage`), and the year is today's. What is stored
 * is where a plant stands, which never changes; how it is drawn this winter is
 * worked out when the plot is served.
 *
 * Everything else is `WalkStore`'s, deliberately: the same append-only insert,
 * the same lock row, the same taking back that keeps a place and erases the
 * plant, and the same ambassador handed to the rule ahead of the stored
 * arrivals.
 */
final class CoppiceStore
{
    /**
     * What a planting taken back has written over, beyond the seed, the parents,
     * the meeting and the nudge that every area writes over (`TakenBack.php`).
     * The family, which the Coppice's rule never reads: its stars' colours are
     * mixed as they arrive. The height stays, because a coupe's floor is kept
     * in order by it; the habit stays, because a floor holds one fern at most;
     * and the coupe, the place and the index stay, because those are the counts.
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
        $this->run("CREATE TABLE IF NOT EXISTS coppice (
            arrival $id,
            seed CHAR(64) NOT NULL UNIQUE,
            parent_a CHAR(64) NOT NULL,
            parent_b CHAR(64) NOT NULL,
            encounter CHAR(64) NOT NULL,
            plot INTEGER NOT NULL,
            coupe INTEGER NOT NULL,
            place INTEGER NOT NULL,
            slot_index INTEGER NOT NULL,
            height DOUBLE PRECISION NOT NULL,
            family INTEGER NOT NULL,
            habit VARCHAR(16) NOT NULL DEFAULT '',
            nudge_x DOUBLE PRECISION NOT NULL,
            nudge_z DOUBLE PRECISION NOT NULL,
            hidden INTEGER NOT NULL DEFAULT 0
        )");
        $this->run('CREATE INDEX IF NOT EXISTS coppice_plot ON coppice (plot)');
        $this->run('CREATE TABLE IF NOT EXISTS coppice_lock (id INTEGER PRIMARY KEY, arrivals INTEGER NOT NULL)');
        $this->run('INSERT INTO coppice_lock (id, arrivals) SELECT 1, 0 WHERE NOT EXISTS (SELECT 1 FROM coppice_lock)');
        $this->run('CREATE INDEX IF NOT EXISTS coppice_hidden ON coppice (hidden)');
        TakenBack::sweep($this->db, 'coppice', self::TAKEN_BACK);
    }

    /**
     * Places one arrival by the rule and keeps it. Returns [the planting,
     * whether it is new]: a seed that has arrived before gets the place it
     * already has, because a plant has one place.
     *
     * `$kind` and `$hue` are the Seedbed's and the Glasshouse's, and nothing
     * here reads them; they are in the signature so `WalkStore::plantInto` can
     * call every area's `plant` alike. `$habit` is this area's, and the empty
     * string means it was never sent.
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
            $this->run('UPDATE coppice_lock SET arrivals = arrivals + 1 WHERE id = 1');
            $existing = $this->db->prepare('SELECT * FROM coppice WHERE seed = ?');
            $existing->execute([$seed]);
            if ($row = $existing->fetch()) {
                $this->db->rollBack();
                return [self::planting($row, Coppice::yearOn(time())), false];
            }
            $all = $this->db->prepare('SELECT * FROM coppice ORDER BY arrival');
            $all->execute();
            // The ambassador first, then the arrivals: it stands in the front
            // row of the first coupe whether or not anything else is here, and
            // the floor is kept in order around it.
            $ways = array_merge(
                [Ambassadors::planting('renewal')],
                array_map([self::class, 'forRule'], $all->fetchAll())
            );
            $p = Coppice::plant($ways, $seed, $height, $family, $habit);
            $insert = $this->db->prepare('INSERT INTO coppice
                (seed, parent_a, parent_b, encounter, plot, coupe, place, slot_index, height, family, habit, nudge_x, nudge_z)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $insert->execute([$seed, $parentA, $parentB, $encounter, $p['plot'], $p['coupe'], $p['place'],
                              $p['index'], $height, $family, $habit, $p['nudgeX'], $p['nudgeZ']]);
            $this->db->commit();
            return [self::planting(['seed' => $seed, 'parent_a' => $parentA, 'parent_b' => $parentB,
                'encounter' => $encounter, 'plot' => $p['plot'], 'coupe' => $p['coupe'],
                'place' => $p['place'], 'slot_index' => $p['index'],
                'nudge_x' => $p['nudgeX'], 'nudge_z' => $p['nudgeZ']], Coppice::yearOn(time())), true];
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /**
     * A plot's plantings, in the order they arrived, drawn as they stand in
     * `$year`. Hidden ones are not in it.
     *
     * Plot 0 opens with the ambassador, a star in the front row of the first
     * coupe. It carries no parents and no meeting, because it was minted rather
     * than crossed, and an empty `parents` is how the wire says so.
     */
    public function plot(int $plot, int $year): array
    {
        $query = $this->db->prepare('SELECT * FROM coppice WHERE plot = ? AND hidden = 0 ORDER BY arrival');
        $query->execute([$plot]);
        $plantings = array_map(fn(array $row) => self::planting($row, $year), $query->fetchAll());
        if ($plot !== 0) return $plantings;
        $standing = Ambassadors::planting('renewal');
        [$x, $z] = Coppice::spot($standing['coupe'], $standing['place'], $standing['index']);
        array_unshift($plantings, [
            'seed' => $standing['seed'],
            'parents' => [],
            'encounter' => null,
            'plot' => 0,
            'spot' => [$x + $standing['nudgeX'], $z + $standing['nudgeZ']],
            'stage' => null,
        ]);
        return $plantings;
    }

    /**
     * Each of a plot's three coupes' stage in `$year`, coupe 0 first: 0 cut
     * this winter, 1 regrowing, 2 grown. Sent with the plot so the page can
     * show which band is open even where no fern stands on a stool yet.
     */
    public static function stages(int $plot, int $year): array
    {
        return array_map(fn(int $coupe) => Coppice::stage($plot, $coupe, $year), range(0, Coppice::COUPES - 1));
    }

    /**
     * Takes a planting back: out of the drawing, and out of the database but for
     * its place and what the rule reads. The area keeps the gap.
     */
    public function takeBack(string $seed): void
    {
        TakenBack::lift($this->db, 'coppice', self::TAKEN_BACK, $seed);
    }

    /**
     * Plots opened. Never fewer than one: the Coppice opened with its
     * ambassador in plot 0.
     */
    public function plots(): int
    {
        $query = $this->db->prepare('SELECT COALESCE(MAX(plot) + 1, 0) FROM coppice');
        $query->execute();
        return max(1, (int) $query->fetchColumn());
    }

    /**
     * What the page needs to grow a planting and stand it in its place: the
     * five fields every area sends, and **one more, `stage`** — for a fern on a
     * stool, where its coupe stands in the rotation this year, which is how
     * young to draw it and how weathered to draw the cut face under it; for any
     * other plant, null, which is *drawn at its best*. A stage and not a
     * stool's place, because the page draws a stool under every planting with
     * one.
     */
    private static function planting(array $row, int $year): array
    {
        $plot = (int) $row['plot'];
        $coupe = (int) $row['coupe'];
        $place = (int) $row['place'];
        [$x, $z] = Coppice::spot($coupe, $place, (int) $row['slot_index']);
        return [
            'seed' => $row['seed'],
            'parents' => [$row['parent_a'], $row['parent_b']],
            'encounter' => $row['encounter'],
            'plot' => $plot,
            'spot' => [$x + (float) $row['nudge_x'], $z + (float) $row['nudge_z']],
            'stage' => $place === Coppice::STOOL ? Coppice::stage($plot, $coupe, $year) : null,
        ];
    }

    private static function forRule(array $row): array
    {
        return [
            'seed' => $row['seed'], 'plot' => (int) $row['plot'],
            'coupe' => (int) $row['coupe'], 'place' => (int) $row['place'],
            'index' => (int) $row['slot_index'],
            'height' => (float) $row['height'], 'family' => (int) $row['family'],
            'habit' => (string) $row['habit'],
        ];
    }
}
