<?php
declare(strict_types=1);

/**
 * How often one caller may write.
 *
 * **Why it is here and not in front.** The service runs on 20i's nginx talking
 * to PHP-FPM, and nothing in that vhost is ours to configure — the same fact
 * that put `index.php` in the tree. So the limit is in PHP, which means it runs
 * after the request has been accepted and is a cap on what gets *written*
 * rather than on what arrives. That is the half that matters here: the Long
 * Walk is append-only, so a planting is expensive to undo, and a bag of offers
 * that nobody can answer is a bag that grows for ever.
 *
 * **It keeps a counter, not an address.** What is stored is a salted SHA-256 of
 * the caller's address, truncated, with the window it belongs to — and the row
 * is deleted once the window has passed. The salt is random per install and
 * lives in the database, so the table cannot be read back into addresses by
 * anybody holding it, and two installs of this service produce different
 * buckets for the same caller. The site keeps no analytics and this is not the
 * beginning of some: nothing here is read except to answer *has this caller
 * written too much in the last hour*.
 *
 * **What it cannot do.** An address is not a person and a caller with many
 * addresses is not slowed by this at all. It is proportionate cover against one
 * machine filling the walk, and no more. `Offers.php` says what a token does
 * and does not prove.
 */
final class Limits
{
    /// How many writes an address gets, and over how long.
    ///
    /// `pending` is the generous one: a phone asks it every time the app opens,
    /// and asking is the whole of what the *Alert me* switch turns off — a
    /// person who leaves it on should never meet a limit by using the app.
    /// `offer` is the tight one: it is the route that makes a row, and a person
    /// sharing twenty plants in an hour is not a person sharing plants.
    public const ROUTES = [
        '/api/walk/offer' => [20, 3600],
        '/api/walk/answer' => [60, 3600],
        '/api/walk/withdraw' => [30, 3600],
        '/api/walk/pending' => [240, 3600],
    ];

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
        $this->run('CREATE TABLE IF NOT EXISTS rate_limits (
            bucket CHAR(32) NOT NULL PRIMARY KEY,
            started_at BIGINT NOT NULL,
            hits INTEGER NOT NULL
        )');
        $this->run('CREATE INDEX IF NOT EXISTS rate_limits_started ON rate_limits (started_at)');
        $this->run('CREATE TABLE IF NOT EXISTS rate_salt (id INTEGER PRIMARY KEY, salt CHAR(64) NOT NULL)');
    }

    /**
     * Whether this caller may write to this route, counting the attempt.
     *
     * Returns the seconds to wait when it may not, and null when it may.
     */
    public function wait(string $route, string $caller, int $now): ?int
    {
        [$allowed, $window] = self::ROUTES[$route] ?? [null, null];
        if ($allowed === null) return null;

        $bucket = substr(hash_hmac('sha256', $route . "\0" . $caller, $this->salt()), 0, 32);

        $this->db->beginTransaction();
        try {
            $query = $this->db->prepare('SELECT started_at, hits FROM rate_limits WHERE bucket = ?');
            $query->execute([$bucket]);
            $row = $query->fetch();

            // A window that has run out is the same as no window at all, so a
            // quiet hour clears the count rather than leaving somebody shut out
            // by something they did yesterday.
            if ($row === false || $now - (int) $row['started_at'] >= $window) {
                // Update then insert, rather than an upsert: `ON CONFLICT` is
                // SQLite's spelling and `ON DUPLICATE KEY` is MySQL's, and this
                // service runs on both.
                $start = $this->db->prepare('UPDATE rate_limits SET started_at = ?, hits = 1 WHERE bucket = ?');
                $start->execute([$now, $bucket]);
                if ($start->rowCount() === 0 && $row === false) {
                    $fresh = $this->db->prepare('INSERT INTO rate_limits (bucket, started_at, hits) VALUES (?, ?, 1)');
                    $fresh->execute([$bucket, $now]);
                }
                $this->db->commit();
                $this->sweep($now);
                return null;
            }

            if ((int) $row['hits'] >= $allowed) {
                $this->db->commit();
                return max(1, $window - ($now - (int) $row['started_at']));
            }

            $count = $this->db->prepare('UPDATE rate_limits SET hits = hits + 1 WHERE bucket = ?');
            $count->execute([$bucket]);
            $this->db->commit();
            return null;
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /**
     * Who is asking, as far as a service can tell.
     *
     * `REMOTE_ADDR` and nothing else. A forwarded header is written by whoever
     * is upstream, and where that is not known to be a proxy of ours it is
     * written by the caller — so trusting one would hand every caller a fresh
     * identity per request, which is the opposite of a rate limit.
     */
    public static function caller(array $server): string
    {
        return (string) ($server['REMOTE_ADDR'] ?? '');
    }

    /**
     * The salt, minted once and kept in the database.
     *
     * Not in the repository and not in `config.php`: it is not a setting
     * anybody should choose, and a salt in a file is a salt in a backup of a
     * file. Random per install, so the same caller buckets differently on the
     * live service and on a local copy.
     */
    private function salt(): string
    {
        $query = $this->db->prepare('SELECT salt FROM rate_salt WHERE id = 1');
        $query->execute();
        if ($salt = $query->fetchColumn()) return (string) $salt;

        $fresh = bin2hex(random_bytes(32));
        try {
            $insert = $this->db->prepare('INSERT INTO rate_salt (id, salt) VALUES (1, ?)');
            $insert->execute([$fresh]);
        } catch (PDOException) {
            // Another request minted it a moment ago. Its value is the one
            // that counts, and the read below is what returns it.
        }

        // Read it back rather than returning what was written: two requests
        // arriving together would otherwise salt with two different values and
        // count the same caller in two buckets.
        $query->execute();
        return (string) $query->fetchColumn();
    }

    /**
     * Drops windows that have run out.
     *
     * One request in fifty, because this is housekeeping and not an answer
     * anybody is waiting for. The longest window is an hour, so a row is never
     * far past its use.
     */
    private function sweep(int $now): void
    {
        if (random_int(1, 50) !== 1) return;
        $oldest = $now - max(array_column(self::ROUTES, 1));
        $drop = $this->db->prepare('DELETE FROM rate_limits WHERE started_at < ?');
        $drop->execute([$oldest]);
    }
}
