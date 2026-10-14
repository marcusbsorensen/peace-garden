<?php
declare(strict_types=1);

require_once __DIR__ . '/WalkStore.php';
require_once __DIR__ . '/Limits.php';
require_once __DIR__ . '/Placed.php';

/**
 * The database's shape, and when it is made: once per version, not once per
 * request (14 October 2026).
 *
 * **Why.** Until today every store made its own tables in its constructor, and
 * `WalkStore::open` built every store, so every request ran the whole
 * migration: eighty-four statements, ten of them `ALTER TABLE … ADD COLUMN`
 * that failed because the column was there, and two scans of tables that grow
 * for ever. DDL takes a metadata lock even when it changes nothing, so under
 * load most of the database's threads were waiting on one another's no-op
 * ALTERs (design/mass-test-2026-10-13/population/README.md, finding 3).
 *
 * **What happens now.** The database keeps the version it was last migrated
 * to, one row in `schema_version`. A request reads that row — one statement —
 * and if it is not lower than `VERSION` the request goes on to its own work.
 * If it is lower, or the table is not there (a database from before today, or
 * an empty one), the whole migration runs: every store's tables and columns,
 * the character set, and the data migrations, then the new version is
 * written. On MariaDB it runs under `GET_LOCK`, so one request migrates and
 * any arriving meanwhile wait for it and then find the work done.
 *
 * **Every step is idempotent**, because a database at version 0 runs all of
 * them: `CREATE … IF NOT EXISTS`, a column added only when
 * `information_schema` (or SQLite's `table_info`) says it is missing, a table
 * converted to utf8mb4 only when its collation says it is not, and the
 * erasures and claims that find nothing to do once done. So running it twice
 * is running it once, and `migrate.php` runs it on demand.
 *
 * **Raising the version.** A change to any store's `migrate` — a table, a
 * column, an index, a data migration that has to run once — raises `VERSION`
 * by one in the same commit, and says so below. Without that, a database
 * already at the old number never sees the change.
 *
 *   1  14 October 2026: the version itself; `placed`, one public place per
 *      plant; every table utf8mb4 with one collation.
 *
 * **After a restore.** A copy restored into the live database replaces the
 * tables but not `schema_version`, so `backup.php` writes a line at the top of
 * every MariaDB copy that drops it: the first request after any restore runs
 * the whole migration again, which erases what an older copy brought back and
 * claims every plant's place afresh (`Placed::reconcile`). For a copy taken
 * before that line existed, `php ~/public_html/.api/migrate.php` does the same
 * by hand (Server/README.md, *Restoring*).
 */
final class Schema
{
    public const VERSION = 1;

    /// The collation every MariaDB table is made with, and converted to. One
    /// collation, because MariaDB refuses to compare two columns whose
    /// collations differ, and `placed` is compared with every planted table.
    public const COLLATION = 'utf8mb4_unicode_ci';

    /** @var WeakMap<PDO, true>|null */
    private static ?WeakMap $checked = null;

    /**
     * Makes sure this connection's database is at `VERSION`. Once per
     * connection: every store asks, and after the first it is a lookup in
     * memory.
     */
    public static function ensure(PDO $db): void
    {
        self::$checked ??= new WeakMap();
        if (isset(self::$checked[$db])) return;
        // Marked before migrating, so a store the migration opens does not
        // start the migration again from its own constructor.
        self::$checked[$db] = true;
        if (self::stored($db) >= self::VERSION) return;
        self::upgrade($db);
    }

    /** The version this database was last migrated to; 0 for none. */
    public static function stored(PDO $db): int
    {
        try {
            $query = $db->prepare('SELECT version FROM schema_version WHERE id = 1');
            $query->execute();
            return (int) $query->fetchColumn();
        } catch (PDOException) {
            // No such table: a database from before 14 October 2026, or one
            // nobody has opened yet.
            return 0;
        }
    }

    /**
     * Runs the migration, under the lock, unless another request finished it
     * while this one waited — or whatever the version says, with `$force`,
     * which is `migrate.php`'s. Returns what the data migrations found, for
     * `migrate.php` to say.
     */
    public static function upgrade(PDO $db, bool $force = false): array
    {
        self::$checked ??= new WeakMap();
        self::$checked[$db] = true;
        $mysql = self::isMysql($db);
        $locked = false;
        if ($mysql) {
            // Lock names are the server's, not the database's, and a shared
            // host's server is shared: the database's own name, hashed to fit
            // the 64 characters a lock name may have, keeps this one ours.
            $lock = $db->prepare("SELECT GET_LOCK(CONCAT('peacegarden.schema.', MD5(DATABASE())), 60)");
            $lock->execute();
            $locked = (int) $lock->fetchColumn() === 1;
            // Not got in a minute: another request is migrating something
            // large. Going ahead is safe — every step is idempotent — and
            // better than refusing the request.
        }
        try {
            if (!$force && self::stored($db) >= self::VERSION) return [];
            $found = self::migrate($db);
            self::record($db);
            return $found;
        } finally {
            if ($locked) {
                $db->prepare("SELECT RELEASE_LOCK(CONCAT('peacegarden.schema.', MD5(DATABASE())))")->execute();
            }
        }
    }

    /**
     * Every step, in order: the tables, then the character set, then the data.
     * The order matters once: `placed` is compared with every planted table,
     * which MariaDB allows only once they share a collation.
     */
    private static function migrate(PDO $db): array
    {
        // The tables, each store's own, in the order the requests used to
        // make them. Each store's `migrate` also runs its own data migration
        // over its own table: `TakenBack::sweep`, which erases a planting
        // hidden before taking back began to delete.
        WalkStore::migrate($db);
        RoomStore::migrate($db);
        CrossStore::migrate($db);
        OrchardStore::migrate($db);
        KnotStore::migrate($db);
        SeedbedStore::migrate($db);
        ColdFrameStore::migrate($db);
        GlasshouseStore::migrate($db);
        CoppiceStore::migrate($db);
        HomeGroundStore::migrate($db);
        WildStore::migrate($db);
        WildWear::migrate($db);
        Offers::migrate($db);
        Limits::migrate($db);
        Placed::migrate($db);
        $db->prepare('CREATE TABLE IF NOT EXISTS schema_version (id INTEGER PRIMARY KEY, version INTEGER NOT NULL)'
                     . self::options($db))->execute();

        $converted = self::utf8mb4($db);

        // The data, once every table is there and alike: what an offer
        // withdrawn or declined before 24 September still held in the clear,
        // and then one claim per plant standing in a public place.
        $erased = WalkStore::on($db)->offers()->eraseLegacy();
        return ['converted' => $converted, 'erased' => $erased] + Placed::reconcile($db);
    }

    /** Writes `VERSION` as the database's, never lowering a higher one. */
    private static function record(PDO $db): void
    {
        $raise = $db->prepare('UPDATE schema_version SET version = ? WHERE id = 1 AND version < ?');
        $raise->execute([self::VERSION, self::VERSION]);
        if ($raise->rowCount() > 0) return;
        try {
            $db->prepare('INSERT INTO schema_version (id, version) VALUES (1, ?)')->execute([self::VERSION]);
        } catch (PDOException) {
            // There already, at this version or a higher one.
        }
    }

    // MARK: - For the stores' migrations

    public static function isMysql(PDO $db): bool
    {
        return $db->getAttribute(PDO::ATTR_DRIVER_NAME) === 'mysql';
    }

    /**
     * What closes every `CREATE TABLE`: on MariaDB the character set and the
     * collation, named rather than left to whatever the host's default is
     * (finding 4 — a database created latin1 refused a name with an emoji in
     * it after the plant was already standing); on SQLite `$sqlite`, which is
     * `' WITHOUT ROWID'` for the tables that must not count their rows.
     */
    public static function options(PDO $db, string $sqlite = ''): string
    {
        return self::isMysql($db) ? ' DEFAULT CHARSET=utf8mb4 COLLATE=' . self::COLLATION : $sqlite;
    }

    /** Whether `$table` has `$column`. */
    public static function hasColumn(PDO $db, string $table, string $column): bool
    {
        if (self::isMysql($db)) {
            $query = $db->prepare('SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?');
            $query->execute([$table, $column]);
            return (int) $query->fetchColumn() > 0;
        }
        $query = $db->prepare("PRAGMA table_info($table)");
        $query->execute();
        foreach ($query->fetchAll(PDO::FETCH_ASSOC) as $row) {
            if (($row['name'] ?? null) === $column) return true;
        }
        return false;
    }

    /**
     * Adds a column that was added after its table was live, if it is not
     * there yet. Asked first, so the ALTER runs once in the life of a
     * database rather than failing on every request; and still caught, for
     * two processes adding it to an empty SQLite file at once.
     */
    public static function addColumn(PDO $db, string $table, string $definition): void
    {
        $column = strtok($definition, ' ');
        if (self::hasColumn($db, $table, $column)) return;
        try {
            $db->prepare("ALTER TABLE $table ADD COLUMN $definition")->execute();
        } catch (PDOException $error) {
            if (!self::hasColumn($db, $table, $column)) throw $error;
        }
    }

    /**
     * Every table of ours that is not utf8mb4 in `COLLATION`, converted; the
     * rest left alone. One question to `information_schema` first, so a
     * database already right costs a read and nothing else. Returns the
     * tables it converted.
     *
     * The tables are small (the largest, `walk_offers`, was 10 MB for nine
     * thousand offers in the population test), so a conversion is a moment's
     * table copy, once.
     */
    private static function utf8mb4(PDO $db): array
    {
        if (!self::isMysql($db)) return [];
        $ours = self::tables();
        $marks = implode(',', array_fill(0, count($ours), '?'));
        $query = $db->prepare("SELECT TABLE_NAME FROM information_schema.TABLES
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ($marks) AND TABLE_COLLATION <> ?
            UNION
            SELECT TABLE_NAME FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ($marks)
                AND COLLATION_NAME IS NOT NULL AND COLLATION_NAME <> ?");
        $query->execute([...$ours, self::COLLATION, ...$ours, self::COLLATION]);
        $wrong = array_values(array_unique($query->fetchAll(PDO::FETCH_COLUMN)));
        sort($wrong);
        foreach ($wrong as $table) {
            if (!in_array($table, $ours, true)) continue;   // only names from the list above reach the ALTER
            $db->prepare("ALTER TABLE $table CONVERT TO CHARACTER SET utf8mb4 COLLATE " . self::COLLATION)->execute();
        }
        return $wrong;
    }

    /** Every table this service makes, and the replant's log beside them. */
    public static function tables(): array
    {
        return ['long_walk', 'long_walk_lock', 'quiet_garden', 'quiet_garden_lock', 'crossing', 'crossing_lock',
                'orchard', 'orchard_lock', 'knot_garden', 'knot_garden_lock', 'seedbed', 'seedbed_lock',
                'cold_frame', 'cold_frame_lock', 'glasshouse', 'glasshouse_lock', 'coppice', 'coppice_lock',
                'home_ground', 'home_ground_lock', 'wild_fields', 'wild_names', 'wild_wear', 'wild_wear_day',
                'walk_offers', 'offer_key', 'rate_limits', 'rate_salt', 'placed', 'schema_version',
                'replant_log'];
    }
}
