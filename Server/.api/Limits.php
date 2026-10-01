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
 * **It keeps a scrambled address and a count, for up to an hour.** What is
 * stored is an HMAC-SHA256 of the route and the caller's address, truncated,
 * with the time its window started and how many writes it has seen. The key is
 * a salt minted once per install, so two installs produce different buckets
 * for the same caller — but it is kept in `rate_salt`, in this same database,
 * and there are only four billion IPv4 addresses. So anybody holding the
 * database can try every one and turn a bucket back into the address it came
 * from. What protects an address is not the scrambling but the deleting: every
 * request that touches this table first deletes every row whose window has
 * ended (`sweep`), so a bucket is gone at the first limited request after its
 * window.
 * `backup.php` leaves both tables out of every copy, so no backup holds one.
 * The site keeps no analytics and this is not the beginning of some: nothing
 * here is read except to answer *has this caller written too much lately*.
 *
 * **Why an hour holds.** A window is fifty-five minutes (`WINDOW`), and a row
 * goes at the next limited request after its window ends or at the next run of
 * `sweep.php`, which cron starts every five minutes (`SWEPT_EVERY`) for the
 * quiet spells when no request comes. So no bucket is older than fifty-five
 * minutes plus five: the hour the privacy page promises, which is why the
 * window is not an hour itself. Until 24 September it was, swept on a draw,
 * and a bucket could outlive its hour by as long as the service stayed quiet.
 *
 * **What it cannot do.** An address is not a person and a caller with many
 * addresses is not slowed by this at all. It is proportionate cover against one
 * machine filling the walk, and no more. `Offers.php` says what a token does
 * and does not prove.
 */
final class Limits
{
    /// How long a window lasts: fifty-five minutes, so that with the five
    /// minutes a sweep can take to come round a scrambled address is gone
    /// within the hour. See the note above.
    public const WINDOW = 3300;

    /// How often cron runs `sweep.php`, in seconds. It is the line in
    /// Server/README.md and `tools/backup.sh --install-cron` that makes it so;
    /// this is what the arithmetic above assumes of them.
    public const SWEPT_EVERY = 300;

    /// How many writes an address gets in a window.
    ///
    /// **The hourly allowances, scaled to fifty-five minutes** when the window
    /// shrank on 24 September — 20, 60, 30 and 240 an hour — and rounded to the
    /// nearest write, so a person using the app meets the limit no sooner than
    /// before and a script is held back as much.
    ///
    /// `pending` is the generous one: a phone asks it every time the app opens,
    /// and asking is the whole of what the *Alert me* switch turns off — a
    /// person who leaves it on should never meet a limit by using the app.
    /// `offer` is the tight one: it is the route that makes a row, and a person
    /// sharing twenty plants in an hour is not a person sharing plants.
    public const ROUTES = [
        '/api/walk/offer' => [18, self::WINDOW],
        '/api/walk/answer' => [55, self::WINDOW],
        '/api/walk/withdraw' => [28, self::WINDOW],
        '/api/walk/pending' => [220, self::WINDOW],
        // **Release is the tightest**, at the hourly 10 scaled to the window,
        // because it is the one write nobody else has to agree to and the one
        // nobody can take back: an offer waits for a second gardener, and a
        // released plant stands in the Wild Fields for good. A person lets go
        // of a plant now and then; ten in an hour is clearing a garden, and
        // nine is room for that and little else.
        '/api/wild/release' => [9, self::WINDOW],
        // **What stands beside a released plant**, since 1 October 2026: as
        // generous as answering an offer, at the hourly 60, because it is the
        // same kind of act — one gardener answering for themselves about a
        // plant that already exists — and a person changing their mind a few
        // times should never meet a limit.
        '/api/wild/answer' => [55, self::WINDOW],
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

        $this->sweep($now);
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
     * Drops every window that has ended, on every request that touches the
     * table.
     *
     * Every time rather than one request in fifty, as it was until 24
     * September: a draw let a bucket outlive its window by as many requests as
     * the dice took, and the privacy page says an hour. It is one DELETE
     * through the index on `started_at`, which on a quiet table finds nothing.
     * Measured against the longest window, which is also every window.
     *
     * Public because `sweep.php` runs it every five minutes from cron as well,
     * for the quiet spells when no request comes to do it. One DELETE is atomic on
     * both databases, so the two running at once is two deletes of the same
     * rows and nothing worse. Returns how many went.
     */
    public function sweep(int $now): int
    {
        $ended = $now - max(array_column(self::ROUTES, 1));
        $drop = $this->db->prepare('DELETE FROM rate_limits WHERE started_at <= ?');
        $drop->execute([$ended]);
        return $drop->rowCount();
    }
}
