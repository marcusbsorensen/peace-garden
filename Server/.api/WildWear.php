<?php
declare(strict_types=1);

/**
 * Paths that visitors wear in the Wild Fields: a number per ground cell, and
 * nothing else (`docs/WEB-GARDENS.md` §*Paths that visitors wear*, proposed by
 * Marcus and accepted on 18 September 2026 on exactly those terms). Built on
 * 2 October 2026 for `/dev` only: the routes answer only where `config.php`
 * says `'wear' => true`, which the live site's does not (`router.php`).
 *
 * **What it is.** The field is cut into cells `CELL` metres square, `CELLS`
 * to a side, so the cells come round with the field (`WildFields::SIDE`).
 * While a visitor walks — drags the field, or presses one of the pad's four
 * directions — the page notes which cells the middle of the window crosses
 * and sends them, now and then, as an unordered batch (`wear.js`). Each cell
 * in a batch adds one crossing to that cell's wear.
 *
 * **It fades.** Every cell loses the same fraction a day, so that its wear
 * halves in `HALF_LIFE` days: a route walked all summer is a clear path by
 * autumn, and one left in autumn is grass again by spring. A cell whose wear
 * has faded below `FLOOR` is grass, and its row goes.
 *
 * **It is capped.** A cell counts at most `CAP` crossings a day, however many
 * arrive, so one visitor panning back and forth, or a script, cannot carve a
 * road in a day. What the cap cannot do, and nothing can without knowing who
 * is walking: somebody who comes back every day and walks the same line is a
 * crowd as far as the field can tell, as they would be in a real one.
 *
 * **What a row keeps, and nothing more:** the cell, its wear, and how many
 * crossings it has counted today towards the cap. No time of any visit, no
 * row per visitor or per batch, no address, no order of arrival — on SQLite
 * the table is `WITHOUT ROWID`, as `wild_fields` is, because SQLite's hidden
 * row number counts up as rows arrive and would be an order of arrival
 * written down by the database rather than by us. A cell's row is made the
 * first time it is crossed and never says when that was.
 *
 * **One date for the whole field, not one per cell.** `wild_wear_day` holds
 * the day the field's wear was last faded to: the first batch of a new day
 * (or the five-minute sweep) fades every cell by the days since, empties every
 * cell's count for the cap, and lets the faded cells go. So no cell carries a
 * date of its own, and the one date there is says when the field was last
 * tended, not when anybody walked. A read fades what it answers by the days
 * since without writing anything.
 *
 * **Nothing here sees who sent a batch.** This class is handed cells and a
 * clock. The address meets only the rate limit, in front of the route, as it
 * does for every other write (`Limits.php`: a salted digest and a count, for
 * under an hour).
 */
final class WildWear
{
    /// How wide a cell is, in metres: about a path's width, so a line of them
    /// is a path once it is softened, and a whole number of them goes across
    /// the field so the cells come round with it.
    public const CELL = 0.5;

    /// Cells along each side of the field: `WildFields::SIDE` / `CELL`.
    public const CELLS = 128;

    /// The days in which a cell's wear halves: about a month.
    public const HALF_LIFE = 30;

    /// Crossings a cell counts in one day, at most. With a month's half-life
    /// this also bounds what any cell can ever hold: `CAP` over a day's
    /// fading, about 260 crossings, which the page draws as the most trodden.
    public const CAP = 6;

    /// Wear below which a cell is grass again, and its row goes: half of one
    /// crossing, so a lone crossing nobody repeats is forgotten in a month.
    public const FLOOR = 0.5;

    /// The least wear the page draws at all, in crossings. Above `CAP`, so
    /// that the most one visitor can add to a cell in a day shows nothing: a
    /// path is many people, or it is nothing. Sent to the page with the
    /// field's size (`GET /api/wild`), so there is one number for it.
    public const SEEN = 8;

    /// Cells in one batch, at most. A page sends twice a minute at the most,
    /// and half a minute of brisk walking crosses fewer than this.
    public const MOST = 256;

    private const DAY = 86400;

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
        $order = $sqlite ? ' WITHOUT ROWID' : '';
        // DOUBLE, because wear fades by a fraction a day and has to come back
        // the number it went in as.
        $this->run("CREATE TABLE IF NOT EXISTS wild_wear (
            cell_x INTEGER NOT NULL,
            cell_z INTEGER NOT NULL,
            wear DOUBLE PRECISION NOT NULL,
            today INTEGER NOT NULL,
            PRIMARY KEY (cell_x, cell_z)
        )$order");
        // One row: the day the field was last faded to, counted in whole days
        // from 1970 in UTC.
        $this->run('CREATE TABLE IF NOT EXISTS wild_wear_day (
            id INTEGER NOT NULL PRIMARY KEY,
            day INTEGER NOT NULL
        )');
    }

    /** The day `$now` falls in, in whole days since 1970, UTC. */
    public static function day(int $now): int
    {
        return intdiv($now, self::DAY);
    }

    /** What a cell's wear is multiplied by over `$days` days. */
    public static function fading(int $days): float
    {
        return $days <= 0 ? 1.0 : 2 ** (-$days / self::HALF_LIFE);
    }

    /**
     * Whether `$cells` is a batch this field takes: a list of at most `MOST`
     * pairs `[x, z]`, each a whole number from 0 to `CELLS` − 1. The route
     * says so before anything is written.
     */
    public static function isBatch(mixed $cells): bool
    {
        if (!is_array($cells) || !array_is_list($cells) || $cells === [] || count($cells) > self::MOST) return false;
        foreach ($cells as $cell) {
            if (!is_array($cell) || !array_is_list($cell) || count($cell) !== 2) return false;
            foreach ($cell as $v) {
                if (!is_int($v) || $v < 0 || $v >= self::CELLS) return false;
            }
        }
        return true;
    }

    /**
     * One batch of crossed cells, from one page. Each cell counts once
     * however often it is in the batch — a visitor panning back and forth
     * over one cell has crossed it once — and only while it has counted
     * fewer than `CAP` today. Returns how many cells the batch held, once
     * each: the request's own number, and nothing about anybody else's.
     *
     * The caller has checked the batch (`isBatch`).
     */
    public function walked(array $cells, int $now): int
    {
        $this->settle($now);
        $once = [];
        foreach ($cells as [$x, $z]) $once[$z * self::CELLS + $x] = [$x, $z];
        // A cell not yet worn is made on its first crossing; a cell already
        // at today's cap is left as it is. Update first, because nearly every
        // crossing of a path is of a cell that is already there.
        $bump = $this->db->prepare('UPDATE wild_wear SET wear = wear + 1, today = today + 1
            WHERE cell_x = ? AND cell_z = ? AND today < ?');
        $fresh = $this->db->prepare('INSERT INTO wild_wear (cell_x, cell_z, wear, today) VALUES (?, ?, 1, 1)');
        $this->db->beginTransaction();
        try {
            foreach ($once as [$x, $z]) {
                $bump->execute([$x, $z, self::CAP]);
                if ($bump->rowCount() > 0) continue;
                try {
                    $fresh->execute([$x, $z]);
                } catch (PDOException) {
                    // There already, and at today's cap — or made a moment ago
                    // by a batch arriving beside this one, which costs one
                    // crossing and nothing worse.
                }
            }
            $this->db->commit();
        } catch (Throwable $trouble) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $trouble;
        }
        return count($once);
    }

    /**
     * The field's wear as of `$now`: `[[x, z, wear], …]` for every cell worn
     * past `FLOOR`, in the order of the cells, wear in crossings to two
     * places. Faded to today as it is read, and nothing is written.
     */
    public function field(int $now): array
    {
        $since = $this->settledOn();
        $factor = self::fading($since === null ? 0 : self::day($now) - $since);
        $query = $this->db->prepare('SELECT cell_x, cell_z, wear FROM wild_wear ORDER BY cell_z, cell_x');
        $query->execute();
        $field = [];
        foreach ($query->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $wear = (float) $row['wear'] * $factor;
            if ($wear < self::FLOOR) continue;
            $field[] = [(int) $row['cell_x'], (int) $row['cell_z'], round($wear, 2)];
        }
        return $field;
    }

    /**
     * Fades the field to the day `$now` falls in, if it has not been already:
     * every cell's wear by the days since it was last faded, every cell's
     * count for the cap back to nothing, and the cells faded below `FLOOR`
     * gone. Returns how many went.
     *
     * Run by the first batch of a day and by the sweep (`sweep.php`), in its
     * own transaction. **Once, however many run it at once**: the day is moved
     * on only where it still says what was read, and only the request that
     * moved it fades the field, so two at midnight fade it once.
     */
    public function settle(int $now): int
    {
        $today = self::day($now);
        $was = $this->settledOn();
        if ($was === null) {
            // The first time the field is tended. Nothing to fade yet.
            try {
                $this->db->prepare('INSERT INTO wild_wear_day (id, day) VALUES (1, ?)')->execute([$today]);
            } catch (PDOException) {
                // Another request made it a moment ago, with the same day.
            }
            return 0;
        }
        if ($was >= $today) return 0;

        $this->db->beginTransaction();
        try {
            // A write first, so the transaction holds the database for writing
            // from its first statement and two of these cannot each wait on the
            // other.
            $claim = $this->db->prepare('UPDATE wild_wear_day SET day = ? WHERE id = 1 AND day = ?');
            $claim->execute([$today, $was]);
            $gone = 0;
            if ($claim->rowCount() === 1) {
                $this->db->prepare('UPDATE wild_wear SET wear = wear * ?, today = 0')
                    ->execute([self::fading($today - $was)]);
                $drop = $this->db->prepare('DELETE FROM wild_wear WHERE wear < ?');
                $drop->execute([self::FLOOR]);
                $gone = $drop->rowCount();
            }
            $this->db->commit();
            return $gone;
        } catch (Throwable $trouble) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $trouble;
        }
    }

    /** The day the field was last faded to, or null before it ever has been. */
    private function settledOn(): ?int
    {
        $query = $this->db->prepare('SELECT day FROM wild_wear_day WHERE id = 1');
        $query->execute();
        $day = $query->fetchColumn();
        return $day === false ? null : (int) $day;
    }
}
