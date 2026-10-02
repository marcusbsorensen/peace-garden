<?php
declare(strict_types=1);

/**
 * A copy of the walk, taken off the database and kept beside it.
 *
 * **What is worth copying.** The walk is append-only and every plant's place is
 * a function of the order arrivals came in. Lose a row and every plant after it
 * stands somewhere else; lose the order and they all do. Nothing in the walk
 * can be worked out again from anything else, because the thing that made it
 * was two people meeting once.
 *
 *   long_walk        the walk itself
 *   long_walk_lock   the arrival count the placing rule counts from
 *   quiet_garden     the second area, and its own lock
 *   crossing         the third area, and its own lock
 *   orchard          the fourth area, and its own lock
 *   knot_garden      the fifth area, and its own lock
 *   seedbed          the sixth area, and its own lock
 *   cold_frame       the seventh area, and its own lock
 *   glasshouse       the eighth area, and its own lock
 *   coppice          the ninth area, and its own lock
 *   home_ground      the tenth area, and its own lock
 *   wild_fields      every plant released to the Wild Fields. It has no lock
 *                    and no order to lose — a released plant stands where its
 *                    seed says — but a lost row is a plant somebody let go of
 *                    that is nowhere at all, which is the one thing release
 *                    was built not to do
 *   wild_names       who stands beside a released plant, by their own choice:
 *                    the names shown, the place and month both chose, and the
 *                    fingerprints that let each of the two answer. Lost, a
 *                    name somebody chose to show is gone and the two can no
 *                    longer withdraw what is left (since 1 October 2026)
 *   wild_wear        the paths visitors have worn in the Wild Fields: a number
 *                    per ground cell. Lost, every path is grass at once, which
 *                    took months of walking to make (since 2 October 2026;
 *                    empty wherever wear is off)
 *   wild_wear_day    the day the field's wear was last faded to, without which
 *                    a restored field would not know how much to fade
 *   walk_offers      consent in flight: who has asked whom, and what was said
 *   offer_key        the key a withdrawn offer's fingerprints are made under,
 *                    without which a restored table could no longer refuse a
 *                    withdrawn plant offered again (`Offers.php`)
 *
 * **What is left out, on purpose.** `rate_limits` and `rate_salt` are this
 * hour's arithmetic about callers, not anything anybody made. Restoring them
 * would hand back allowance that had been spent and re-key every bucket to an
 * older salt; leaving them out lets the service build them fresh, which is what
 * it does on any empty database. It also means no copy ever holds a scrambled
 * address.
 *
 * **A copy holds what the database held that night.** A plant taken back is
 * erased from the live tables at once and is in no copy taken after that, but
 * the copies already taken keep it until they go: thirty days, here and on the
 * Mac, where `tools/backup.sh` prunes what it pulls to the same length.
 * Server/README.md says so where restoring is described.
 *
 * **Run it from cron, on the server.** `tools/backup.sh --install-cron` puts it
 * there; `tools/backup.sh` pulls what it has written down to the Mac, which is
 * the copy that survives losing the account. A copy on the same disk as the
 * database it came from is a second copy of one thing, not a backup.
 *
 * **Restoring** is in Server/README.md, and `tools/backup.sh --restore-test`
 * proves the newest copy restores rather than assuming it.
 */

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

/** The tables the walk is made of, dumped in this order so a restore can replay it. */
// An area that opens is a table to add here. Nothing derives this list from
// `Areas::TABLES`, and it should not: a copy of the garden is the one place
// where being told explicitly what to keep is worth the repetition, and a lock
// table has no area to be derived from anyway.
const KEPT = ['long_walk', 'long_walk_lock', 'quiet_garden', 'quiet_garden_lock',
              'crossing', 'crossing_lock',
              'orchard', 'orchard_lock',
              'knot_garden', 'knot_garden_lock',
              'seedbed', 'seedbed_lock',
              'cold_frame', 'cold_frame_lock',
              'glasshouse', 'glasshouse_lock',
              'coppice', 'coppice_lock',
              'home_ground', 'home_ground_lock', 'wild_fields', 'wild_names', 'wild_wear', 'wild_wear_day',
              'walk_offers', 'offer_key'];

/** How many copies stay on the server, at most. */
const KEEP = 30;

/**
 * And for how long, at most: thirty days, on the server and on the Mac alike
 * (`KEEP_DAYS` in tools/backup.sh). One copy a day makes the two limits the
 * same thing, but a count alone is not a length of time — a week of cron not
 * running leaves thirty copies spanning thirty-seven days — and the privacy
 * page says thirty days. The newest copy is kept whatever its age.
 */
const KEEP_DAYS = 30;

/** The marker mysqldump writes last. Its absence is a dump cut short. */
const COMPLETED = '-- Dump completed';

// Run directly, this takes a copy. Required from elsewhere, it is a set of
// functions and takes none, which is how `tools/reference/check_backup.php`
// gets at the reading-back and the pruning without a database to dump.
if (realpath((string) ($argv[0] ?? '')) === __FILE__) {
    exit(main($argv));
}

function main(array $argv): int
{
    $config = configuration();

    // Two ways of saying what this script knows, for the rehearsal in
    // tools/backup.sh: it takes its copy with the database's own dumper inside
    // a container, where this script cannot reach, and asks here rather than
    // keeping a second list of tables and a second idea of the preamble.
    if (($argv[1] ?? '') === '--tables') {
        echo implode(' ', KEPT) . "\n";
        return 0;
    }
    if (($argv[1] ?? '') === '--preamble') {
        echo preamble(rowCounts($config));
        return 0;
    }

    // **The tables a deploy added are made before they are copied.** The
    // service makes its tables on the first request after a deploy
    // (`WalkStore::open`), and mysqldump refuses a list naming a table that
    // is not there — so a deploy that added one to KEPT, with no request
    // before 03:17, would cost that night's copy. Opening the store here runs
    // the same migrations a request would, so the order a deploy happens in
    // cannot break the copy. A store that will not open is left for the dump
    // to report, which it will.
    try {
        require_once __DIR__ . '/WalkStore.php';
        WalkStore::open($config['dsn'], $config['user'] ?? null, $config['password'] ?? null);
    } catch (Throwable) {
        // Said by the dump below, in its own words.
    }

    $into = $argv[1] ?? (home() . '/backups');
    if (!is_dir($into) && !mkdir($into, 0700, true)) {
        return fail("cannot make $into");
    }

    $path = sprintf('%s/walk-%s.sql.gz', $into, gmdate('Y-m-d\THis\Z'));

    try {
        $counts = rowCounts($config);
        if (str_starts_with($config['dsn'], 'sqlite:')) {
            copyTheFile($config['dsn'], $path, $counts);
        } else {
            dumpTheDatabase($config, $path, $counts);
        }
        readItBack($path, $counts);
    } catch (Throwable $trouble) {
        @unlink($path);
        return fail($trouble->getMessage());
    }

    $dropped = prune($into);
    printf(
        "%s  %s  %s bytes  %s%s\n",
        gmdate('Y-m-d H:i:s'),
        basename($path),
        number_format(filesize($path)),
        collect($counts),
        $dropped ? "  (dropped $dropped older)" : ''
    );
    return 0;
}

// MARK: Taking the copy

/**
 * Streams mysqldump straight into the gzip, so a walk larger than this machine's
 * memory is still a file rather than a fatal error.
 *
 * `--single-transaction` takes the snapshot inside a transaction instead of
 * locking, which is both consistent and the only thing that works here: shared
 * hosting gives the database user no LOCK TABLES and no PROCESS, so
 * `--skip-lock-tables` and `--no-tablespaces` are what keep mysqldump from
 * asking for either.
 *
 * Every value that reaches the command line goes through escapeshellarg, and
 * the one value that must not appear there at all — the password — is written
 * to a file only this account can read.
 */
function dumpTheDatabase(array $config, string $path, array $counts): void
{
    $where = dsnParts($config['dsn']);

    // `ps` shows a command line to everybody on the machine, so the password
    // goes in an option file instead and is removed as soon as it has been used.
    $defaults = tempnam(sys_get_temp_dir(), 'pgdump');
    if ($defaults === false) {
        throw new RuntimeException('cannot write the credentials file');
    }
    chmod($defaults, 0600);
    file_put_contents($defaults, optionFile($config, $where));

    $command = sprintf(
        'mysqldump --defaults-file=%s --single-transaction --skip-lock-tables'
        . ' --no-tablespaces --no-create-db --hex-blob --default-character-set=utf8mb4'
        . ' %s %s 2>&1',
        escapeshellarg($defaults),
        escapeshellarg($where['dbname']),
        implode(' ', array_map('escapeshellarg', KEPT))
    );

    try {
        stream($command, $path, $counts);
    } finally {
        unlink($defaults);
    }
}

/** A local SQLite walk, copied the way SQLite copies itself: consistently, from inside. */
function copyTheFile(string $dsn, string $path, array $counts): void
{
    $plain = tempnam(sys_get_temp_dir(), 'pgwalk');
    unlink($plain); // VACUUM INTO writes the file, and refuses one already there.
    $db = new PDO($dsn);
    $db->prepare('VACUUM INTO ' . $db->quote($plain))->execute();
    unset($db);

    $out = gzopen($path, 'wb9');
    gzwrite($out, preamble($counts) . "-- A SQLite file follows, not SQL.\n");
    gzwrite($out, (string) file_get_contents($plain));
    gzwrite($out, "\n" . COMPLETED . "\n");
    gzclose($out);
    unlink($plain);
}

function stream(string $command, string $path, array $counts): void
{
    $out = gzopen($path, 'wb9');
    if ($out === false) {
        throw new RuntimeException("cannot write $path");
    }
    gzwrite($out, preamble($counts));

    $pipe = popen($command, 'r');
    if ($pipe === false) {
        gzclose($out);
        throw new RuntimeException('cannot run mysqldump');
    }
    while (!feof($pipe)) {
        $block = fread($pipe, 65536);
        if ($block === false || $block === '') {
            continue;
        }
        gzwrite($out, $block);
    }
    $status = pclose($pipe);
    gzclose($out);

    if ($status !== 0) {
        throw new RuntimeException("mysqldump stopped with status $status");
    }
}

/**
 * What the database held when the copy was taken, written where a restore can
 * read it. This is what `--restore-test` holds the restored tables to: a dump
 * that loads without complaint and comes back short is the failure worth
 * catching, and nothing else in the file would say so.
 */
function preamble(array $counts): string
{
    $lines = "-- Peace Garden, the Long Walk\n"
        . '-- taken ' . gmdate('c') . "\n";
    foreach ($counts as $table => $count) {
        $lines .= "-- rows $table $count\n";
    }
    return $lines . "--\n";
}

function rowCounts(array $config): array
{
    $db = new PDO($config['dsn'], $config['user'] ?? null, $config['password'] ?? null, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
    $counts = [];
    foreach (KEPT as $table) {
        try {
            $counts[$table] = (int) $db->query("SELECT COUNT(*) FROM $table")->fetchColumn();
        } catch (Throwable) {
            // A table the service has not created yet is nothing to copy, and
            // is not a reason to take no copy of the others.
            $counts[$table] = 0;
        }
    }
    return $counts;
}

// MARK: Reading it back

/**
 * Opens the file that was just written and reads it to the end.
 *
 * **The failure this is for** is the one that leaves everything looking well: a
 * dump cut short by a dropped connection or a full disk is a valid gzip of a
 * valid prefix of SQL, and it restores most of the walk without a word. Reading
 * for the marker mysqldump writes last, and for a CREATE of every table that
 * had anything in it, is the difference between having a copy and believing you
 * have one.
 */
function readItBack(string $path, array $counts): void
{
    $handle = gzopen($path, 'rb');
    if ($handle === false) {
        throw new RuntimeException('the copy will not open');
    }
    $found = [];
    $ended = false;
    while (($line = gzgets($handle)) !== false) {
        foreach (KEPT as $table) {
            if (str_contains($line, "CREATE TABLE `$table`")) {
                $found[$table] = true;
            }
        }
        if (str_contains($line, 'A SQLite file follows')) {
            $found = array_fill_keys(KEPT, true);
        }
        if (str_starts_with($line, COMPLETED)) {
            $ended = true;
        }
    }
    gzclose($handle);

    if (!$ended) {
        throw new RuntimeException('the copy stops early — it was cut short');
    }
    foreach (KEPT as $table) {
        // A table with no count in the header is one this copy was taken
        // before the service had — reading it as zero rows is the truth about
        // that copy, and is what lets an older copy still verify.
        if (empty($found[$table]) && ($counts[$table] ?? 0) > 0) {
            throw new RuntimeException("$table is not in the copy");
        }
    }
}

// MARK: Keeping a few

/**
 * Leaves the newest KEEP copies, none of them older than KEEP_DAYS but the
 * newest, and removes the rest. Returns how many went.
 *
 * The age is read off the stamp in the name rather than the file's time, which
 * a copy or a restore can change; a name with no stamp is left alone.
 */
function prune(string $into, ?int $now = null): int
{
    $now ??= time();
    $copies = glob("$into/walk-*.sql.gz") ?: [];
    sort($copies); // The stamp sorts as the date does, which is why it is written that way.
    if ($copies === []) {
        return 0;
    }
    $newest = end($copies);
    $going = array_slice($copies, 0, max(0, count($copies) - KEEP));
    foreach ($copies as $copy) {
        $taken = stampOf($copy);
        if ($copy !== $newest && $taken !== null && $taken < $now - KEEP_DAYS * 86400) {
            $going[] = $copy;
        }
    }
    $going = array_unique($going);
    foreach ($going as $old) {
        unlink($old);
    }
    return count($going);
}

/** When a copy was taken, read off its name, or null for a name with no stamp. */
function stampOf(string $path): ?int
{
    if (!preg_match('/^walk-(\d{4})-(\d{2})-(\d{2})T(\d{2})(\d{2})(\d{2})Z\.sql\.gz$/', basename($path), $m)) {
        return null;
    }
    return gmmktime((int) $m[4], (int) $m[5], (int) $m[6], (int) $m[2], (int) $m[3], (int) $m[1]);
}

// MARK: Small things

/**
 * `PG_WALK_DSN` comes first, with `PG_WALK_USER` and `PG_WALK_PASSWORD` beside
 * it, so `check_backup.php` and `backup.sh --rehearse` can point this at a walk
 * of their own making. Nothing sets them in cron, where the server's config.php
 * is the only answer.
 */
function configuration(): array
{
    $config = is_file(__DIR__ . '/config.php') ? require __DIR__ . '/config.php' : [];
    if ($dsn = getenv('PG_WALK_DSN')) {
        $config = [
            'dsn' => $dsn,
            'user' => getenv('PG_WALK_USER') ?: null,
            'password' => getenv('PG_WALK_PASSWORD') ?: null,
        ];
    }
    // The same default the service itself falls back to, in router.php:
    // beside public_html, never inside it.
    $config['dsn'] ??= 'sqlite:' . dirname(__DIR__, 2) . '/peacegarden-data/walk.sqlite';
    return $config;
}

function dsnParts(string $dsn): array
{
    $parts = ['host' => '127.0.0.1', 'port' => '3306', 'dbname' => ''];
    foreach (explode(';', substr($dsn, strpos($dsn, ':') + 1)) as $pair) {
        [$key, $value] = array_pad(explode('=', $pair, 2), 2, '');
        if (isset($parts[$key])) {
            $parts[$key] = $value;
        }
    }
    if ($parts['dbname'] === '') {
        throw new RuntimeException('the configured dsn names no database');
    }
    return $parts;
}

/**
 * MySQL's own option-file format. A value carrying a quote or a newline would
 * break out of it, so one is refused rather than escaped: a password like that
 * means the configuration is wrong, and guessing at it here would hide that.
 */
function optionFile(array $config, array $where): string
{
    $file = "[client]\n";
    foreach ([
        'user' => $config['user'] ?? '',
        'password' => $config['password'] ?? '',
        'host' => $where['host'],
        'port' => $where['port'],
    ] as $key => $value) {
        if (preg_match('/["\r\n]/', (string) $value)) {
            throw new RuntimeException("the configured $key cannot go in an option file");
        }
        $file .= sprintf("%s=\"%s\"\n", $key, $value);
    }
    return $file;
}

function collect(array $counts): string
{
    $said = [];
    foreach ($counts as $table => $count) {
        $said[] = "$table=$count";
    }
    return implode(' ', $said);
}

function home(): string
{
    return getenv('HOME') ?: dirname(__DIR__, 2);
}

function fail(string $said): int
{
    fwrite(STDERR, gmdate('Y-m-d H:i:s') . "  no copy taken: $said\n");
    return 1;
}
