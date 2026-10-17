<?php
declare(strict_types=1);

/**
 * Does SQLite's file locking hold on this host? The test `DESIGN.md` §6.2
 * asks for before the aloft pools (`Server/.api/Aloft.php`) are relied on.
 *
 * Run it with `tools/zonec/locktest.sh`, which picks the PHP and passes the
 * options. Done by hand:
 *
 *     php locktest.php run [--seconds 300] [--cli 64] [--web 64]
 *                          [--scratch DIR] [--serve | --url URL]
 *
 * **What it does.** Reports the PHP modules (`pdo_sqlite` and `sodium` are the
 * two the pools need), free disk and how long an fsync takes. Makes a scratch
 * pool in a directory of its own, outside `public_html` (it refuses a path
 * inside one), shaped as the real pools are: `WITHOUT ROWID`, one blob column,
 * `secure_delete` on, `journal_mode = DELETE`, a 1 second busy timeout. Then
 * `--cli` processes and `--web` concurrent web requests all put, evict and
 * draw on it for `--seconds`, mirroring `Aloft::put` and `Aloft::draw`, but
 * counting what `Aloft` swallows. It reports:
 *
 *   - **busy errors**: operations that gave up on a lock;
 *   - **the longest wait**: the slowest single operation, in milliseconds;
 *   - **`PRAGMA integrity_check`** on the file at the end;
 *   - **rows lost**: every committed put and eviction is counted, so the rows
 *     that should be there equal the rows that are. Fewer is a lost write.
 *
 * and deletes everything it made.
 *
 * **The web half.** The same file answers a web request when served: a request
 * is one slice of the same work, allowed only with the key the run wrote
 * beside the scratch pool. `--serve` serves a copy from `php -S` on this
 * machine (local trials). On a host, put this file where the web server runs
 * PHP, give its address with `--url`, and delete it afterwards: with the
 * scratch directory gone, it does nothing.
 */

const SCRATCH_PREFIX = 'peacegarden-locktest-';
/** Rows the scratch pool holds before a put pushes one out: small, so eviction is constant. */
const CAP = 256;
/** A web request's slice of work, in seconds. */
const SLICE = 15;

// ---- The work, shared by CLI workers and web requests ----------------------

function openPool(string $file): PDO
{
    $db = new PDO('sqlite:' . $file, null, null, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 1,
        PDO::ATTR_STRINGIFY_FETCHES => false,
    ]);
    return $db;
}

function isBusy(Throwable $e): bool
{
    $message = strtolower($e->getMessage());
    return str_contains($message, 'locked') || str_contains($message, 'busy');
}

/**
 * Put, evict and draw until `$seconds` are up. The tallies are of what
 * committed only, so the count at the end can be checked against them.
 */
function work(string $dir, int $seconds): array
{
    $tally = ['puts' => 0, 'draws' => 0, 'busy' => 0, 'other' => 0, 'inserted' => 0, 'removed' => 0, 'longest_ms' => 0.0];
    $end = microtime(true) + $seconds;
    $db = null;
    while (microtime(true) < $end) {
        $started = microtime(true);
        try {
            $db ??= openPool("$dir/pool.sqlite");
            if (random_int(0, 99) < 70) {
                $db->beginTransaction();
                $insert = $db->prepare('INSERT OR IGNORE INTO aloft (row) VALUES (?)');
                $insert->bindValue(1, random_bytes(64), PDO::PARAM_LOB);
                $insert->execute();
                $added = $insert->rowCount();
                $removed = 0;
                $count = (int) $db->query('SELECT count(*) FROM aloft')->fetchColumn();
                if ($count > CAP) {
                    $removed = $db->exec('DELETE FROM aloft WHERE row IN (SELECT row FROM aloft ORDER BY random() LIMIT 1)');
                }
                $db->commit();
                $tally['puts']++;
                $tally['inserted'] += $added;
                $tally['removed'] += $removed;
            } else {
                $select = $db->prepare('SELECT row FROM aloft ORDER BY random() LIMIT 32');
                $select->execute();
                $select->fetchAll(PDO::FETCH_COLUMN);
                $tally['draws']++;
            }
        } catch (Throwable $e) {
            try { if ($db !== null && $db->inTransaction()) $db->rollBack(); } catch (Throwable $ignored) {}
            if (isBusy($e)) {
                $tally['busy']++;
                // The wait that ended in a give-up counts as a wait too.
            } else {
                $tally['other']++;
            }
        }
        $tally['longest_ms'] = max($tally['longest_ms'], (microtime(true) - $started) * 1000);
        // A phone asks now and then; it does not spin. 2-20 ms between requests
        // is still far busier than the real traffic will be.
        usleep(random_int(2000, 20000));
    }
    return $tally;
}

function addTallies(array $a, array $b): array
{
    foreach ($b as $key => $value) {
        $a[$key] = $key === 'longest_ms' ? max($a[$key] ?? 0, $value) : ($a[$key] ?? 0) + $value;
    }
    return $a;
}

// ---- A web request: one slice, with the key -------------------------------

if (PHP_SAPI !== 'cli') {
    header('Content-Type: application/json');
    header('Cache-Control: no-store');
    $dir = realpath((string) ($_GET['dir'] ?? ''));
    $key = (string) ($_GET['key'] ?? '');
    $expected = $dir !== false && str_starts_with(basename($dir), SCRATCH_PREFIX) && is_file("$dir/key")
        ? trim((string) file_get_contents("$dir/key")) : '';
    if ($expected === '' || !hash_equals($expected, $key) || !is_file("$dir/pool.sqlite")) {
        http_response_code(404);
        exit('{}');
    }
    $seconds = max(1, min(SLICE, (int) ($_GET['seconds'] ?? SLICE)));
    set_time_limit($seconds + 30);
    exit(json_encode(work($dir, $seconds)));
}

// ---- The command line ------------------------------------------------------

function say(string $line = ''): void { fwrite(STDOUT, $line . "\n"); }

function removeTree(string $dir): void
{
    if (!is_dir($dir) || is_link($dir)) return;
    foreach (scandir($dir) as $name) {
        if ($name === '.' || $name === '..') continue;
        $path = "$dir/$name";
        is_dir($path) && !is_link($path) ? removeTree($path) : @unlink($path);
    }
    @rmdir($dir);
}

/** What `php -m` would show for the two modules the pools need, and the rest of the setting. */
function reportHost(string $dir): void
{
    say('PHP ' . PHP_VERSION . ' (' . PHP_SAPI . '), ' . PHP_OS);
    foreach (['pdo_sqlite', 'sodium'] as $module) {
        say(sprintf('  module %-10s %s', $module, extension_loaded($module) ? 'present' : 'MISSING'));
    }
    if (extension_loaded('pdo_sqlite')) {
        say('  SQLite ' . (new PDO('sqlite::memory:'))->query('select sqlite_version()')->fetchColumn());
    }
    $free = @disk_free_space($dir);
    say('Free disk at the scratch directory: ' . ($free === false ? 'unknown' : sprintf('%.1f MB', $free / 1048576)));
    $type = @shell_exec('stat -f -c %T ' . escapeshellarg($dir) . ' 2>/dev/null');
    if (is_string($type) && trim($type) !== '') say('Filesystem type: ' . trim($type));

    $file = "$dir/fsync-probe";
    $times = [];
    for ($i = 0; $i < 20; $i++) {
        $handle = fopen($file, 'wb');
        fwrite($handle, random_bytes(4096));
        $started = microtime(true);
        fflush($handle);
        function_exists('fsync') ? fsync($handle) : null;
        $times[] = (microtime(true) - $started) * 1000;
        fclose($handle);
    }
    @unlink($file);
    sort($times);
    say(sprintf('fsync of 4 KB: median %.2f ms, slowest %.2f ms (20 tries)', $times[10], $times[19]));
}

function option(array $argv, string $name, string $default): string
{
    $at = array_search("--$name", $argv, true);
    return $at !== false && isset($argv[$at + 1]) ? $argv[$at + 1] : $default;
}

function run(array $argv): int
{
    if (!extension_loaded('pdo_sqlite')) {
        fwrite(STDERR, "pdo_sqlite is missing: nothing to test.\n");
        return 2;
    }
    $seconds = max(1, (int) option($argv, 'seconds', '300'));
    $cli = max(0, (int) option($argv, 'cli', '64'));
    $web = max(0, (int) option($argv, 'web', '64'));
    $serve = in_array('--serve', $argv, true);
    $url = option($argv, 'url', '');
    if ($web > 0 && !$serve && $url === '') {
        fwrite(STDERR, "The web half needs --serve (a local php -S) or --url ADDRESS-OF-THIS-FILE, or --web 0.\n");
        return 2;
    }

    $parent = rtrim(option($argv, 'scratch', dirname(getcwd())), '/');
    if (str_contains($parent . '/', '/public_html/')) {
        fwrite(STDERR, "The scratch directory must be outside public_html.\n");
        return 2;
    }
    if (!is_dir($parent)) {
        fwrite(STDERR, "No such scratch parent directory.\n");
        return 2;
    }
    $dir = $parent . '/' . SCRATCH_PREFIX . bin2hex(random_bytes(6));
    $key = bin2hex(random_bytes(16));
    $server = null;
    $webRoot = null;
    $result = 1;

    try {
        mkdir($dir, 0700);
        file_put_contents("$dir/key", $key);
        chmod("$dir/key", 0600);
        say("locktest: $seconds s, $cli CLI processes, $web concurrent web requests");
        say("Scratch directory: " . basename($dir) . ' (made now, deleted at the end)');
        reportHost($dir);

        $db = openPool("$dir/pool.sqlite");
        $db->exec('PRAGMA secure_delete = ON');
        $db->exec('PRAGMA journal_mode = DELETE');
        $db->exec('CREATE TABLE aloft (row BLOB PRIMARY KEY) WITHOUT ROWID');
        $db = null;

        if ($serve && $web > 0) {
            $webRoot = $dir . '/web';
            mkdir($webRoot, 0700);
            copy(__FILE__, "$webRoot/locktest.php");
            $port = random_int(20000, 40000);
            $server = proc_open(
                [PHP_BINARY, '-S', "127.0.0.1:$port", '-t', $webRoot],
                [0 => ['file', '/dev/null', 'r'], 1 => ['file', '/dev/null', 'w'], 2 => ['file', '/dev/null', 'w']],
                $pipes,
                null,
                ['PHP_CLI_SERVER_WORKERS' => (string) max(2, $web)] + getenv()
            );
            $url = "http://127.0.0.1:$port/locktest.php";
            for ($i = 0; $i < 50 && !@fsockopen('127.0.0.1', $port); $i++) usleep(100000);
        }

        $total = ['puts' => 0, 'draws' => 0, 'busy' => 0, 'other' => 0, 'inserted' => 0, 'removed' => 0, 'longest_ms' => 0.0];
        $workers = [];
        for ($i = 0; $i < $cli; $i++) {
            $workers[] = proc_open(
                [PHP_BINARY, __FILE__, 'worker', $dir, (string) $seconds],
                [0 => ['file', '/dev/null', 'r'], 1 => ['pipe', 'w'], 2 => ['file', '/dev/null', 'w']],
                $pipes[$i]
            );
        }

        $webFailures = 0;
        $webWhy = [];
        $webSlices = 0;
        $deadline = microtime(true) + $seconds;
        if ($web > 0) {
            $multi = curl_multi_init();
            $handles = [];
            $start = static function () use (&$handles, $multi, $url, $dir, $key, $deadline): void {
                $left = (int) ceil($deadline - microtime(true));
                if ($left < 1) return;
                $curl = curl_init($url . '?' . http_build_query(['dir' => $dir, 'key' => $key, 'seconds' => min(SLICE, $left)]));
                curl_setopt_array($curl, [CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => SLICE + 60]);
                curl_multi_add_handle($multi, $curl);
                $handles[(int) $curl] = $curl;
            };
            for ($i = 0; $i < $web; $i++) $start();
            while ($handles !== []) {
                curl_multi_exec($multi, $running);
                curl_multi_select($multi, 0.2);
                while ($done = curl_multi_info_read($multi)) {
                    $curl = $done['handle'];
                    $body = (string) curl_multi_getcontent($curl);
                    $decoded = json_decode($body, true);
                    $webSlices++;
                    if (curl_getinfo($curl, CURLINFO_RESPONSE_CODE) === 200 && is_array($decoded)) {
                        $total = addTallies($total, $decoded);
                    } else {
                        $webFailures++;
                        $webWhy[] = curl_getinfo($curl, CURLINFO_RESPONSE_CODE) . ' ' . curl_error($curl);
                    }
                    curl_multi_remove_handle($multi, $curl);
                    unset($handles[(int) $curl]);
                    curl_close($curl);
                    $start();
                }
            }
            curl_multi_close($multi);
        }

        $cliFailures = 0;
        foreach ($workers as $i => $process) {
            $out = stream_get_contents($pipes[$i][1]);
            fclose($pipes[$i][1]);
            proc_close($process);
            $decoded = json_decode((string) $out, true);
            is_array($decoded) ? $total = addTallies($total, $decoded) : $cliFailures++;
        }

        $db = openPool("$dir/pool.sqlite");
        $integrity = (string) $db->query('PRAGMA integrity_check')->fetchColumn();
        $present = (int) $db->query('SELECT count(*) FROM aloft')->fetchColumn();
        $db = null;
        $expected = $total['inserted'] - $total['removed'];
        $lost = $expected - $present;

        say();
        say("Operations: {$total['puts']} puts, {$total['draws']} draws ($webSlices web requests, $web at a time)");
        say("Busy errors (gave up on a lock after 1 s): {$total['busy']}");
        say("Other errors: {$total['other']}");
        say(sprintf('Longest wait: %.0f ms', $total['longest_ms']));
        say("integrity_check: $integrity");
        say("Rows that should be there: $expected; there: $present; lost: " . ($lost > 0 ? $lost : 0)
            . ($lost < 0 ? ' (and ' . -$lost . ' more than were counted)' : ''));
        if ($webFailures > 0) say("Web requests that failed or answered wrongly: $webFailures (" . implode('; ', array_slice(array_unique($webWhy), 0, 3)) . ')');
        if ($cliFailures > 0) say("CLI processes that reported nothing: $cliFailures");

        $held = $integrity === 'ok' && $lost === 0 && $total['other'] === 0 && $webFailures === 0 && $cliFailures === 0
            && $total['puts'] > 0;
        say($held ? 'RESULT: locking held.' : 'RESULT: locking did NOT hold cleanly: read the lines above.');
        if ($total['busy'] > 0 && $held) say('Busy errors are the pool giving up politely (a draw pads, a put drops); they are not corruption.');
        $result = $held ? 0 : 1;
    } finally {
        if ($server !== null) { proc_terminate($server); proc_close($server); }
        removeTree($dir);
        say(is_dir($dir) ? "NOT deleted: $dir" : 'Deleted everything this run made.');
    }
    return $result;
}

function worker(array $argv): int
{
    echo json_encode(work($argv[2], (int) $argv[3]));
    return 0;
}

exit(match ($argv[1] ?? '') {
    'run' => run($argv),
    'worker' => worker($argv),
    default => (function (): int { fwrite(STDERR, "Use tools/zonec/locktest.sh\n"); return 2; })(),
});
