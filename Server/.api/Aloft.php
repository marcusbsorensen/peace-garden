<?php
declare(strict_types=1);

/**
 * The two pools that space seeds travel through: `aloft` for 64-byte rows (a
 * space seed and its key, or padding) and `back` for 104-byte rows (a sealed
 * return, or padding). The reasoning is in
 * `design/space-seeds-2026-10-16/DESIGN.md` §4.4; this is the part that keeps
 * to it.
 *
 * **One file of its own**, `../peacegarden-data/aloft.sqlite`, not the MySQL
 * database: a database server can keep a timed log of every write, and a
 * SQLite file in our own space keeps none. The directory is 0700 and the file
 * 0600, made the first time they are asked for, as `store()` makes the walk's.
 *
 * **One column in each table, the bytes.** No time, address, token, counter or
 * order of arrival; `WITHOUT ROWID` because SQLite's hidden row number counts
 * up as rows arrive, which would write the order down for us. `secure_delete`
 * overwrites what is removed, and `journal_mode = DELETE` leaves no log behind.
 *
 * **A cap on each**, `P` and `Q` rows. A row put in over the cap pushes out
 * one row chosen at random, so a row's age is written nowhere. A draw is
 * `ORDER BY random() LIMIT n`, a scan of at most `P` rows: probes into the key
 * are uneven (a row's chance follows the gap before it), a scan is not.
 *
 * **It never fails a request.** A pool that is locked for longer than a second,
 * or cannot be opened, answers a draw with padding and drops a put; nothing
 * here throws to the caller.
 */
final class Aloft
{
    /** Rows a pool holds: aloft, back. */
    public const P = 2048;
    public const Q = 2048;
    /** Rows a request draws from each: aloft, back. */
    public const B = 128;
    public const R = 128;
    /** Bytes in a row: aloft, back. */
    public const ALOFT_ROW = 64;
    public const BACK_ROW = 104;

    private ?PDO $db = null;
    private bool $tried = false;

    private function __construct(
        private string $file,
        private int $aloftCap,
        private int $backCap,
    ) {
    }

    /** The pools at `$file`, made on first use. The caps are for tests. */
    public static function open(string $file, int $aloftCap = self::P, int $backCap = self::Q): self
    {
        return new self($file, $aloftCap, $backCap);
    }

    /** Add a 64-byte row to `aloft`. False when it was dropped. */
    public function putAloft(string $row): bool
    {
        return $this->put('aloft', self::ALOFT_ROW, $this->aloftCap, $row);
    }

    /** Add a 104-byte row to `back`. False when it was dropped. */
    public function putBack(string $row): bool
    {
        return $this->put('back', self::BACK_ROW, $this->backCap, $row);
    }

    /** Exactly `$n` distinct 64-byte rows, padded where the pool holds fewer. */
    public function drawAloft(int $n = self::B): array
    {
        return $this->draw('aloft', self::ALOFT_ROW, $n);
    }

    /** Exactly `$n` distinct 104-byte rows, padded where the pool holds fewer. */
    public function drawBack(int $n = self::R): array
    {
        return $this->draw('back', self::BACK_ROW, $n);
    }

    /** A row that is not a seed: 32 random bytes, then a public key nobody holds. */
    public static function paddingAloft(): string
    {
        return random_bytes(32) . sodium_crypto_scalarmult_base(random_bytes(32));
    }

    /** A row that is not a return: random bytes, as a sealed one looks. */
    public static function paddingBack(): string
    {
        return random_bytes(self::BACK_ROW);
    }

    private function put(string $table, int $length, int $cap, string $row): bool
    {
        if (strlen($row) !== $length) return false;
        try {
            $db = $this->connection();
            if ($db === null) return false;
            $db->beginTransaction();
            $insert = $db->prepare("INSERT OR IGNORE INTO $table (row) VALUES (?)");
            $insert->bindValue(1, $row, PDO::PARAM_LOB);
            $insert->execute();
            $count = (int) $db->query("SELECT count(*) FROM $table")->fetchColumn();
            if ($count > $cap) {
                $db->exec("DELETE FROM $table WHERE row IN (SELECT row FROM $table ORDER BY random() LIMIT 1)");
            }
            $db->commit();
            return true;
        } catch (Throwable $e) {
            $this->rollBack();
            return false;
        }
    }

    private function draw(string $table, int $length, int $n): array
    {
        $rows = [];
        try {
            $db = $this->connection();
            if ($db !== null) {
                $select = $db->prepare("SELECT row FROM $table ORDER BY random() LIMIT ?");
                $select->bindValue(1, $n, PDO::PARAM_INT);
                $select->execute();
                foreach ($select->fetchAll(PDO::FETCH_COLUMN) as $row) {
                    if (is_resource($row)) $row = stream_get_contents($row);
                    if (is_string($row) && strlen($row) === $length) $rows[$row] = true;
                }
            }
        } catch (Throwable $e) {
            $rows = [];
        }
        // Padding is random, so a repeat is not to be expected; the key keeps it distinct if it is.
        while (count($rows) < $n) {
            $rows[$length === self::ALOFT_ROW ? self::paddingAloft() : self::paddingBack()] = true;
        }
        return array_map('strval', array_keys($rows));
    }

    /** The open file, or null where it cannot be opened (tried once a request). */
    private function connection(): ?PDO
    {
        if ($this->tried) return $this->db;
        $this->tried = true;
        try {
            $directory = dirname($this->file);
            if (!is_dir($directory)) mkdir($directory, 0700, true);
            $fresh = !file_exists($this->file);
            if ($fresh) {
                $old = umask(0077);
                touch($this->file);
                umask($old);
                chmod($this->file, 0600);
            }
            $db = new PDO('sqlite:' . $this->file, null, null, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_TIMEOUT => 1,
                PDO::ATTR_STRINGIFY_FETCHES => false,
            ]);
            $db->exec('PRAGMA secure_delete = ON');
            $db->exec('PRAGMA journal_mode = DELETE');
            $db->exec('CREATE TABLE IF NOT EXISTS aloft (row BLOB PRIMARY KEY) WITHOUT ROWID');
            $db->exec('CREATE TABLE IF NOT EXISTS back (row BLOB PRIMARY KEY) WITHOUT ROWID');
            return $this->db = $db;
        } catch (Throwable $e) {
            return $this->db = null;
        }
    }

    private function rollBack(): void
    {
        try {
            if ($this->db !== null && $this->db->inTransaction()) $this->db->rollBack();
        } catch (Throwable $e) {
        }
    }
}
