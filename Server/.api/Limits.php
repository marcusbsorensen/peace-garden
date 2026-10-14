<?php
declare(strict_types=1);

require_once __DIR__ . '/Schema.php';
require_once __DIR__ . '/Transient.php';

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
 * **Two counts, since 14 October 2026: one per gardener, one per address.**
 * Until then there was only the address, and an address is not a person.
 * Meetings happen where people are together, which is where they share a
 * network: on a festival's Wi-Fi in the population test a hundred gardeners
 * opening the app three times had a quarter of their requests refused, and a
 * workshop of ten people each releasing one plant over one router would have
 * run out of releases. Mobile carriers put many phones behind one IPv4
 * address too. The other way round, a phone on IPv6 holds a whole /64, and
 * every address in it counted apart, so one phone had no limit at all
 * (design/mass-test-2026-10-13/population/README.md, finding 6). So:
 *
 *   - **Per gardener** (`ROUTES`): the allowance a person had before, counted
 *     by the meeting token the request carries — `from` for an offer, `to` for
 *     an answer, `token` for a withdrawal, a release or a name, the whole bag
 *     of tokens for `pending` — or by the seed, for a release sent without a
 *     token. Checked after the body is read.
 *   - **Per address** (`CEILINGS`): `CROWD` times that, shared by everybody
 *     behind one address. An IPv4 address is one address; an IPv6 address
 *     counts as its /64 (`caller`). Checked before the body is read, so a
 *     malformed request spends it too.
 *
 * **What each still stops.** A token is sixteen bytes the phone mints, so a
 * script can mint a fresh one for every request and the per-gardener count
 * does not slow it at all: what caps a script is the address. One machine on
 * one IPv4 address, or one IPv6 /64 (which is what a phone or a home line
 * holds), writes at most 90 offers, 45 releases, 140 withdrawals and 275
 * answers or names in fifty-five minutes, and asks `pending` at most 1,100
 * times — where an IPv6 caller had no cap before. What the per-gardener count
 * stops is one phone gone wrong — a retry loop, a stuck button — taking the
 * whole of its crowd's allowance: it gets one person's share, as it always
 * had. The cost is plain: a script on one IPv4 address gets five times what it
 * got, 45 invented plants an hour in the Wild Fields rather than 9; the
 * curator can take them down (`curate.php`), and `CROWD` is the one number to
 * turn if that is too many.
 *
 * **It keeps a scrambled key and a count, for up to an hour.** What is stored
 * is an HMAC-SHA256 of which count it is, the route, and the address or the
 * token, truncated, with the time its window started and how many writes it
 * has seen. The key is a salt minted once per install, so two installs produce
 * different buckets for the same caller — but it is kept in `rate_salt`, in
 * this same database, and there are only four billion IPv4 addresses. So
 * anybody holding the database can try every one and turn a bucket back into
 * the address it came from. (A token is sixteen random bytes and cannot be
 * tried for.) What protects an address is not the scrambling but the
 * deleting: every request that touches this table first deletes every row
 * whose window has ended (`sweep`), so a bucket is gone at the first limited
 * request after its window.
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
 * **What it cannot do.** A caller with many addresses is not slowed by this at
 * all. It is proportionate cover against one machine filling the walk, and no
 * more. `Offers.php` says what a token does and does not prove.
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

    /// The two counts, and the word each is bucketed under.
    public const BY_GARDENER = 'gardener';
    public const BY_ADDRESS = 'address';

    /// How many writes one gardener gets in a window, counted by the meeting
    /// token the request carries.
    ///
    /// **The hourly allowances, scaled to fifty-five minutes** when the window
    /// shrank on 24 September — 20, 60, 30 and 240 an hour — and rounded to the
    /// nearest write, so a person using the app meets the limit no sooner than
    /// before and a script is held back as much. Until 14 October 2026 these
    /// were per address; they are the same numbers, per person.
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
        // **The cells a visitor crossed in the Wild Fields**, since 2 October
        // 2026 and only where wear is turned on (`WildWear.php`): at the
        // hourly 120 scaled to the window, because a page walking without a
        // pause sends a batch every half a minute and no more. A browser
        // carries no token, so this one is counted by address alone, at this
        // number (`CEILINGS`).
        '/api/wild/wear' => [110, self::WINDOW],
    ];

    /// How many gardeners' allowances one address holds. Five: a venue's
    /// Wi-Fi with a few hundred people opening the app, or a workshop of
    /// forty-five each releasing a plant, in one window; and no more than
    /// five times what one machine could write before.
    public const CROWD = 5;

    /// How many writes one address gets in a window, everybody behind it
    /// together: `CROWD` times a gardener's, but for wear, which a browser
    /// sends without a token and so was always counted by address.
    public const CEILINGS = [
        '/api/walk/offer' => [90, self::WINDOW],
        '/api/walk/answer' => [275, self::WINDOW],
        '/api/walk/withdraw' => [140, self::WINDOW],
        '/api/walk/pending' => [1100, self::WINDOW],
        '/api/wild/release' => [45, self::WINDOW],
        '/api/wild/answer' => [275, self::WINDOW],
        '/api/wild/wear' => [110, self::WINDOW],
    ];

    private ?string $salt = null;

    public function __construct(private PDO $db)
    {
        Schema::ensure($db);
    }

    /**
     * The tables, made or brought up to date. Run by `Schema` when the
     * database is older than the code (14 October 2026), never per request.
     */
    public static function migrate(PDO $db): void
    {
        $run = static fn (string $sql): bool => $db->prepare($sql)->execute();
        $run('CREATE TABLE IF NOT EXISTS rate_limits (
            bucket CHAR(32) NOT NULL PRIMARY KEY,
            started_at BIGINT NOT NULL,
            hits INTEGER NOT NULL
        )' . Schema::options($db));
        $run('CREATE INDEX IF NOT EXISTS rate_limits_started ON rate_limits (started_at)');
        $run('CREATE TABLE IF NOT EXISTS rate_salt (id INTEGER PRIMARY KEY, salt CHAR(64) NOT NULL)' . Schema::options($db));
    }

    /**
     * Whether `$caller` may write to this route, counting the attempt.
     * `$caller` is a gardener's token (or a release's seed) with
     * `BY_GARDENER`, and `caller()`'s address with `BY_ADDRESS`.
     *
     * Returns the seconds to wait when it may not, and null when it may.
     *
     * **One statement counts, and it is safe to run twice at once** (14
     * October 2026). Until then a new bucket was a SELECT, an UPDATE of no
     * row and an INSERT; under MariaDB's REPEATABLE READ the UPDATE of a
     * missing row takes a gap lock, and two first writes landing in the same
     * gap deadlocked, or both inserted and one hit the duplicate key — a 500
     * either way. Now one upsert opens, resets or counts the window, whichever
     * it needs, and the row is read back inside the same transaction. The
     * limit's own statements run at READ COMMITTED on MariaDB, which takes no
     * gap locks, and a deadlock or a duplicate that still happens is tried
     * again (`Transient`): nothing else is written, so a retry is always safe.
     */
    public function wait(string $route, string $caller, int $now, string $counted = self::BY_GARDENER): ?int
    {
        $limits = $counted === self::BY_ADDRESS ? self::CEILINGS : self::ROUTES;
        [$allowed, $window] = $limits[$route] ?? [null, null];
        if ($allowed === null) return null;

        $bucket = substr(hash_hmac('sha256', $counted . "\0" . $route . "\0" . $caller, $this->salt()), 0, 32);
        $row = Transient::retry(function () use ($bucket, $allowed, $window, $now): array {
            $this->sweep($now);
            return $this->count($bucket, $allowed, $window, $now);
        }, duplicates: true);

        // Over the allowance: the attempt is refused, and the window's start,
        // which the refusal did not move, says how long until it is over.
        if ((int) $row['hits'] > $allowed) {
            return max(1, $window - ($now - (int) $row['started_at']));
        }
        return null;
    }

    /**
     * Opens, resets or counts one bucket, and reads it back. A window that
     * has run out is the same as no window at all, so a quiet hour clears the
     * count rather than leaving somebody shut out by something they did
     * yesterday. The count stops one past the allowance, so a caller refused a
     * thousand times holds the same row as one refused once.
     */
    private function count(string $bucket, int $allowed, int $window, int $now): array
    {
        $mysql = Schema::isMysql($this->db);
        if ($mysql) $this->db->prepare('SET TRANSACTION ISOLATION LEVEL READ COMMITTED')->execute();
        $this->db->beginTransaction();
        try {
            $upsert = $this->db->prepare($mysql
                // `hits` first: MariaDB assigns left to right, and the window's
                // test has to read the old start.
                ? 'INSERT INTO rate_limits (bucket, started_at, hits) VALUES (?, ?, 1)
                    ON DUPLICATE KEY UPDATE
                        hits = IF(? - started_at >= ?, 1, LEAST(hits + 1, ?)),
                        started_at = IF(? - started_at >= ?, ?, started_at)'
                // SQLite reads every right-hand side from the row as it was.
                : 'INSERT INTO rate_limits (bucket, started_at, hits) VALUES (?, ?, 1)
                    ON CONFLICT (bucket) DO UPDATE SET
                        hits = CASE WHEN ? - started_at >= ? THEN 1 ELSE MIN(hits + 1, ?) END,
                        started_at = CASE WHEN ? - started_at >= ? THEN ? ELSE started_at END');
            // Every number bound as a number: bound as text, SQLite compares
            // `3300 >= '3300'` as false, and MariaDB may compare a LEAST of a
            // number and a string as strings.
            $upsert->bindValue(1, $bucket);
            foreach ([$now, $now, $window, $allowed + 1, $now, $window, $now] as $i => $number) {
                $upsert->bindValue($i + 2, $number, PDO::PARAM_INT);
            }
            $upsert->execute();
            $query = $this->db->prepare('SELECT started_at, hits FROM rate_limits WHERE bucket = ?');
            $query->execute([$bucket]);
            $row = $query->fetch(PDO::FETCH_ASSOC);
            $this->db->commit();
            return $row === false ? ['started_at' => $now, 'hits' => 1] : $row;
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /**
     * Who is asking, as far as a service can tell: `REMOTE_ADDR`, and for an
     * IPv6 address its /64.
     *
     * `REMOTE_ADDR` and nothing else. A forwarded header is written by whoever
     * is upstream, and where that is not known to be a proxy of ours it is
     * written by the caller — so trusting one would hand every caller a fresh
     * identity per request, which is the opposite of a rate limit.
     *
     * **An IPv6 address is counted as its /64** (14 October 2026), the low
     * sixty-four bits zeroed: a phone or a home line is given a whole /64 and
     * can use any address in it, so counting each apart gave one phone 2^64
     * allowances. An IPv4 address written as IPv6 (`::ffff:192.0.2.1`) is the
     * IPv4 address. Anything that is not an address is counted as it is.
     */
    public static function caller(array $server): string
    {
        $address = (string) ($server['REMOTE_ADDR'] ?? '');
        $packed = @inet_pton($address);
        if ($packed === false || strlen($packed) !== 16) return $address;
        if (str_starts_with($packed, str_repeat("\0", 10) . "\xff\xff")) {
            return (string) inet_ntop(substr($packed, 12));
        }
        return inet_ntop(substr($packed, 0, 8) . str_repeat("\0", 8)) . '/64';
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
        if ($this->salt !== null) return $this->salt;
        $query = $this->db->prepare('SELECT salt FROM rate_salt WHERE id = 1');
        $query->execute();
        if ($salt = $query->fetchColumn()) return $this->salt = (string) $salt;

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
        return $this->salt = (string) $query->fetchColumn();
    }

    /**
     * Drops every window that has ended, on every request that touches the
     * table.
     *
     * Every time rather than one request in fifty, as it was until 24
     * September: a draw let a bucket outlive its window by as many requests as
     * the dice took, and the privacy page says an hour. It is one DELETE
     * through the index on `started_at`, which on a quiet table finds nothing.
     * Measured against the longest window, which is also every window. On
     * MariaDB at READ COMMITTED, so the range it reads is not gap-locked
     * against the windows other requests are opening at that moment.
     *
     * Public because `sweep.php` runs it every five minutes from cron as well,
     * for the quiet spells when no request comes to do it. One DELETE is atomic on
     * both databases, so the two running at once is two deletes of the same
     * rows and nothing worse. Returns how many went.
     */
    public function sweep(int $now): int
    {
        $ended = $now - max(array_column([...self::ROUTES, ...self::CEILINGS], 1));
        if (Schema::isMysql($this->db)) {
            $this->db->prepare('SET TRANSACTION ISOLATION LEVEL READ COMMITTED')->execute();
        }
        $drop = $this->db->prepare('DELETE FROM rate_limits WHERE started_at <= ?');
        $drop->execute([$ended]);
        return $drop->rowCount();
    }
}
