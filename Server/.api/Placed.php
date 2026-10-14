<?php
declare(strict_types=1);

require_once __DIR__ . '/Areas.php';
require_once __DIR__ . '/Schema.php';

/**
 * One public place per plant, held by the database rather than by luck
 * (14 October 2026).
 *
 * **Why.** A plant stands in one public place: an area, or the Wild Fields.
 * The release checked the asking before the offer's row existed and the offer
 * checked the field before the release's row existed, so an offer and a
 * release of the same plant at the same moment both went through, and a later
 * "yes" planted a plant that was already standing in the field
 * (design/mass-test-2026-10-13/population/README.md, finding 5: 9 of 40
 * trials). Eleven tables, eleven locks, and no one of them could see the
 * others.
 *
 * **What holds it now.** `placed` has one row per plant standing anywhere
 * public: its seed, the key, and the table it stands in. Every arrival in an
 * area and every release writes that row in the same transaction as the
 * planting itself, so whichever commits first holds the plant and the other
 * finds the key taken and backs out — the area's arrival planting nothing,
 * the release clearing the way again as it would have a moment later. Two
 * arrivals of the same plant in the same place are the same arrival and both
 * go on (the area's own lock, or the field's key, then settles which one
 * wrote it).
 *
 * **Taking back lets go.** A planting taken back keeps its place in its area
 * but not its seed (`TakenBack.php`), and its row here goes in the same
 * transaction, so the plant can be released afterwards. A plant the curator
 * hides in the Wild Fields keeps its row, as it keeps its seed: it is still
 * not to be shown anywhere else.
 *
 * **Nothing new is kept.** The seed is the plant's own, already public where it
 * stands, and gone from here when it is gone from there. No order either: on
 * SQLite the table is `WITHOUT ROWID`, as the field's is, and on MariaDB its
 * rows are kept in the order of their seeds, so it does not write down which
 * plant was released first. `placed` is not in the nightly copy: it is made
 * again from the tables that are (`reconcile`, run by every migration).
 */
final class Placed
{
    /// The Wild Fields' table, which is a public place without being an area.
    public const WILD = 'wild_fields';

    public static function migrate(PDO $db): void
    {
        $db->prepare('CREATE TABLE IF NOT EXISTS placed (
            seed CHAR(64) NOT NULL PRIMARY KEY,
            place VARCHAR(16) NOT NULL
        )' . Schema::options($db, ' WITHOUT ROWID'))->execute();
    }

    /** Every table a plant can stand in for anybody to see. */
    public static function places(): array
    {
        return [...array_values(Areas::TABLES), self::WILD];
    }

    /**
     * Claims `$seed` for `$place`, inside the caller's transaction. True if
     * it is now this place's — newly, or already — and false if another place
     * holds it.
     *
     * On MariaDB a claim another transaction has written and not committed
     * makes this wait for it, and the existing row is then read with a
     * locking read, which sees the latest committed version rather than this
     * transaction's older snapshot. SQLite has one writer at a time, so there
     * is nothing to wait for.
     */
    public static function claim(PDO $db, string $seed, string $place): bool
    {
        for ($tries = 0; $tries < 3; $tries++) {
            try {
                $db->prepare('INSERT INTO placed (seed, place) VALUES (?, ?)')->execute([$seed, $place]);
                return true;
            } catch (PDOException $clash) {
                if (($clash->errorInfo[0] ?? '') !== '23000') throw $clash;
            }
            $held = self::holder($db, $seed);
            // Let go in the moment between the two statements: claim again.
            if ($held === null) continue;
            if ($held === $place) return true;
            if (self::stands($db, $held, $seed)) return false;
            // **A claim nothing stands behind** — left by code that did not
            // keep `placed` (a rollback to before 14 October 2026), or by a
            // restore not yet migrated — is taken over rather than obeyed,
            // so it can never refuse a plant for good. Only if it is still
            // the claim just read; if not, look again.
            $take = $db->prepare('UPDATE placed SET place = ? WHERE seed = ? AND place = ?');
            $take->execute([$place, $seed, $held]);
            if ($take->rowCount() === 1) return true;
        }
        return false;
    }

    /**
     * Whether `$seed` stands in `$table` for anybody to see: in an area, a row
     * not taken back; in the field, any row, hidden too, because a hidden plant
     * still holds its seed. A locking read on MariaDB, for the reason `claim`'s
     * is: a claim and its planting are committed together, so the planting of
     * a claim just read is committed too, and only a locking read is sure to
     * see it from inside an older snapshot.
     */
    private static function stands(PDO $db, string $table, string $seed): bool
    {
        if (!in_array($table, self::places(), true)) return false;
        $standing = $table === self::WILD ? '' : ' AND hidden = 0';
        $query = $db->prepare("SELECT 1 FROM $table WHERE seed = ?$standing"
                              . (Schema::isMysql($db) ? ' LOCK IN SHARE MODE' : ''));
        $query->execute([$seed]);
        return $query->fetchColumn() !== false;
    }

    /** Lets go of `$seed`, if `$place` holds it. */
    public static function letGo(PDO $db, string $seed, string $place): void
    {
        $db->prepare('DELETE FROM placed WHERE seed = ? AND place = ?')->execute([$seed, $place]);
    }

    /** Which table holds `$seed`, or null. */
    public static function holder(PDO $db, string $seed): ?string
    {
        $query = $db->prepare('SELECT place FROM placed WHERE seed = ?'
                              . (Schema::isMysql($db) ? ' LOCK IN SHARE MODE' : ''));
        $query->execute([$seed]);
        $held = $query->fetchColumn();
        return $held === false ? null : (string) $held;
    }

    /**
     * Makes `placed` say what the tables say: a claim for every plant
     * standing in an area or released to the field, and none for anything
     * else. Run by every migration — on a database from before `placed`
     * existed it makes every claim, and after a restore it puts right what
     * the restored tables changed. Returns counts, for `migrate.php`.
     *
     * A plant already standing in two places — which the race this table
     * closes could leave behind — keeps the first claim in `places()`'s
     * order, and is counted under `in two places` for the curator to look at.
     */
    public static function reconcile(PDO $db): array
    {
        $tables = self::places();
        $let = 0;
        $claimed = 0;
        $twice = 0;
        foreach ($tables as $table) {
            $standing = $table === self::WILD ? '1 = 1' : 't.hidden = 0';
            $stale = $db->prepare("DELETE FROM placed WHERE place = ? AND seed NOT IN
                (SELECT t.seed FROM $table t WHERE $standing)");
            $stale->execute([$table]);
            $let += $stale->rowCount();
        }
        $marks = implode(',', array_fill(0, count($tables), '?'));
        $junk = $db->prepare("DELETE FROM placed WHERE place NOT IN ($marks)");
        $junk->execute($tables);
        $let += $junk->rowCount();
        foreach ($tables as $table) {
            $standing = $table === self::WILD ? '1 = 1' : 't.hidden = 0';
            $missing = $db->prepare("INSERT INTO placed (seed, place)
                SELECT t.seed, ? FROM $table t LEFT JOIN placed p ON p.seed = t.seed
                WHERE p.seed IS NULL AND $standing");
            $missing->execute([$table]);
            $claimed += $missing->rowCount();
        }
        foreach ($tables as $table) {
            $standing = $table === self::WILD ? '1 = 1' : 't.hidden = 0';
            $elsewhere = $db->prepare("SELECT COUNT(*) FROM $table t JOIN placed p ON p.seed = t.seed
                WHERE p.place <> ? AND $standing");
            $elsewhere->execute([$table]);
            $twice += (int) $elsewhere->fetchColumn();
        }
        return ['let go' => $let, 'claimed' => $claimed, 'in two places' => $twice];
    }
}
