<?php
declare(strict_types=1);

/**
 * The `pending` route's two Zone C slots and bundles, over HTTP.
 *
 * Run: php tools/reference/check_aloft.php
 *
 * It copies `Server/` to a throwaway directory, writes a `config.php` there
 * that aims the walk and the aloft pools at throwaway files, and serves the
 * copy with `php -S`; the real `Server/` and `peacegarden-data` are never
 * touched. Needs `pdo_sqlite` and `sodium`. Stays under the 220 requests an
 * address gets in a window.
 *
 *   - **The answer**: `aloft` is 128 rows of 128 hex and `back` 128 rows of
 *     208, the same with no slots, padding slots and real-looking ones, and
 *     with an empty, a half-full and a full pool.
 *   - **A malformed slot** (uppercase, 127 or 129 characters, an array, null)
 *     is the token 400 and stores nothing.
 *   - **A good slot** is stored once and never returned to its own request.
 *   - **`tokens: []`** with slots is 200; 129 tokens is still 400.
 *   - **The error log** holds no slot bytes.
 *   - **The 8,192-byte body cap** still takes 128 tokens and both slots.
 *   - **A locked pool** changes neither the status nor the lengths.
 */

require_once __DIR__ . '/../../Server/.api/Aloft.php';

$failures = 0;
function check(string $what, bool $held): void
{
    global $failures;
    if (!$held) { $failures++; fwrite(STDERR, "FAILED  $what\n"); }
    else fwrite(STDOUT, "ok      $what\n");
}

function removeTree(string $dir): void
{
    if (!is_dir($dir)) return;
    foreach (scandir($dir) as $name) {
        if ($name === '.' || $name === '..') continue;
        $path = "$dir/$name";
        is_dir($path) && !is_link($path) ? removeTree($path) : unlink($path);
    }
    rmdir($dir);
}

function copyTree(string $from, string $to): void
{
    mkdir($to, 0700, true);
    foreach (scandir($from) as $name) {
        if ($name === '.' || $name === '..' || $name === 'config.php') continue;
        is_dir("$from/$name") ? copyTree("$from/$name", "$to/$name") : copy("$from/$name", "$to/$name");
    }
}

if (!extension_loaded('pdo_sqlite') || !extension_loaded('sodium')) {
    fwrite(STDERR, "needs pdo_sqlite and sodium\n");
    exit(2);
}

$root = sys_get_temp_dir() . '/aloft-http-' . bin2hex(random_bytes(6));
copyTree(__DIR__ . '/../../Server', "$root/site");
mkdir("$root/data", 0700);
$pool = "$root/data/aloft.sqlite";
$errors = "$root/error.log";
file_put_contents("$root/site/.api/config.php", "<?php\nreturn [\n"
    . "  'dsn' => 'sqlite:$root/data/walk.sqlite',\n"
    . "  'aloft' => '$pool',\n];\n");

$port = random_int(20000, 40000);
$server = proc_open(
    [PHP_BINARY, '-d', "error_log=$errors", '-d', 'log_errors=1', '-S', "127.0.0.1:$port",
     '-t', "$root/site", "$root/site/index.php"],
    [0 => ['file', '/dev/null', 'r'], 1 => ['file', '/dev/null', 'w'], 2 => ['file', '/dev/null', 'w']],
    $pipes
);
register_shutdown_function(static function () use ($server, $root): void {
    proc_terminate($server);
    proc_close($server);
    removeTree($root);
});
for ($i = 0; $i < 50; $i++) {
    if (@fsockopen('127.0.0.1', $port)) break;
    usleep(100000);
}

/** [status, decoded body, raw] for a POST of `$json` (a string, to send it as is). */
function post(int $port, array|string $json): array
{
    $body = is_string($json) ? $json : json_encode($json);
    $curl = curl_init("http://127.0.0.1:$port/api/walk/pending");
    curl_setopt_array($curl, [CURLOPT_POST => true, CURLOPT_POSTFIELDS => $body, CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'], CURLOPT_TIMEOUT => 20]);
    $raw = (string) curl_exec($curl);
    $status = (int) curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
    curl_close($curl);
    return [$status, json_decode($raw, true), $raw];
}

function token(int $n): string { return substr(hash('sha256', "t$n"), 0, 32); }
function slot(int $bytes): string { return bin2hex(random_bytes($bytes)); }

/** Both bundles at their fixed shape. */
function shaped(?array $body): bool
{
    if (!is_array($body) || !isset($body['aloft'], $body['back'], $body['offers'], $body['wild'])) return false;
    foreach ([['aloft', 128], ['back', 208]] as [$key, $length]) {
        if (count($body[$key]) !== 128) return false;
        foreach ($body[$key] as $row) {
            if (!is_string($row) || strlen($row) !== $length || preg_match('/\A[0-9a-f]+\z/', $row) !== 1) return false;
        }
        if (count(array_unique($body[$key])) !== 128) return false;
    }
    return true;
}

function counts(string $pool): array
{
    if (!file_exists($pool)) return [0, 0];
    $db = new PDO('sqlite:' . $pool);
    return [(int) $db->query('SELECT count(*) FROM aloft')->fetchColumn(),
            (int) $db->query('SELECT count(*) FROM back')->fetchColumn()];
}

$tokens = [token(1), token(2)];

// ---- The answer, whatever the pools and the slots hold ----------------------
[$s, $b] = post($port, ['tokens' => $tokens]);
check('no slots (builds 1-10): 200 with both bundles', $s === 200 && shaped($b));
check('no slots store nothing', counts($pool) === [0, 0]);

[$s, $b] = post($port, ['tokens' => $tokens, 'aloft' => slot(64), 'back' => slot(104)]);
check('real-looking slots into an empty pool: 200 with both bundles', $s === 200 && shaped($b));
$padding = Aloft::paddingAloft();
[$s, $b2] = post($port, ['tokens' => $tokens, 'aloft' => bin2hex($padding), 'back' => bin2hex(Aloft::paddingBack())]);
check('padding-shaped slots: 200 with both bundles', $s === 200 && shaped($b2));
check('an empty pool answers the same length as a stocked one', strlen(json_encode($b['aloft'])) === strlen(json_encode($b2['aloft'])));

$pools = Aloft::open($pool);
for ($i = 0; $i < 1000; $i++) { $pools->putAloft(Aloft::paddingAloft()); $pools->putBack(Aloft::paddingBack()); }
[$s, $half] = post($port, ['tokens' => $tokens]);
check('a half-full pool: 200 with both bundles', $s === 200 && shaped($half));
for ($i = 0; $i < 1300; $i++) { $pools->putAloft(Aloft::paddingAloft()); $pools->putBack(Aloft::paddingBack()); }
[$s, $full] = post($port, ['tokens' => $tokens, 'aloft' => slot(64), 'back' => slot(104)]);
check('a full pool: 200 with both bundles', $s === 200 && shaped($full));
check('a full pool stays at its cap after a put', counts($pool) === [Aloft::P, Aloft::Q]);
check('the whole answer is as long (offers and wild empty) at every fill',
    strlen(json_encode($b)) === strlen(json_encode($half)) && strlen(json_encode($half)) === strlen(json_encode($full)));
[$s, $b0] = post($port, ['tokens' => []]);
check('no tokens and no slots still answers both bundles', $s === 200 && shaped($b0));

// ---- Malformed slots --------------------------------------------------------
[$before] = [counts($pool)];
$errorsBefore = file_exists($errors) ? filesize($errors) : 0;
$bad = [
    'aloft uppercase' => ['aloft' => strtoupper('ab' . slot(63))],
    'aloft 127 characters' => ['aloft' => substr(slot(64), 1)],
    'aloft 129 characters' => ['aloft' => slot(64) . 'a'],
    'aloft an array' => ['aloft' => [slot(64)]],
    'aloft null' => ['aloft' => null],
    'aloft not hex' => ['aloft' => str_repeat('g', 128)],
    'back uppercase' => ['back' => strtoupper('ab' . slot(103))],
    'back 207 characters' => ['back' => substr(slot(104), 1)],
    'back 209 characters' => ['back' => slot(104) . 'a'],
    'back an array' => ['back' => [slot(104)]],
    'back null' => ['back' => null],
    'a good aloft beside a bad back' => ['aloft' => slot(64), 'back' => slot(104) . 'a'],
];
$sent = [];
foreach ($bad as $what => $slots) {
    foreach ($slots as $value) if (is_string($value)) $sent[] = $value;
    [$s, $b] = post($port, ['tokens' => $tokens] + $slots);
    check("malformed slot ($what) is 400", $s === 400 && !isset($b['aloft']));
}
[$s] = post($port, ['tokens' => [strtoupper(token(3))]]);
check('and a malformed token is the same 400', $s === 400);
check('malformed slots store nothing', counts($pool) === $before);

// ---- A good slot ------------------------------------------------------------
unlink($pool);
$mine = slot(64);
$return = slot(104);
[$s, $b] = post($port, ['tokens' => $tokens, 'aloft' => $mine, 'back' => $return]);
check('a well-formed slot is stored', $s === 200 && counts($pool) === [1, 1]);
check('and never returned to its own request', !in_array($mine, $b['aloft'], true) && !in_array($return, $b['back'], true));
[$s, $b] = post($port, ['tokens' => $tokens, 'aloft' => $mine, 'back' => $return]);
check('sent again, it is returned to the second request and still stored once',
    $s === 200 && in_array($mine, $b['aloft'], true) && in_array($return, $b['back'], true) && counts($pool) === [1, 1]);
$sent[] = $mine;
$sent[] = $return;

// ---- The bag ----------------------------------------------------------------
[$s, $b] = post($port, ['tokens' => [], 'aloft' => slot(64), 'back' => slot(104)]);
check('tokens: [] with slots is 200 and stores them', $s === 200 && shaped($b) && counts($pool) === [2, 2]);
[$s] = post($port, ['tokens' => array_map('token', range(1, 129))]);
check('129 tokens is still 400', $s === 400);
[$s, $b] = post($port, ['tokens' => array_map('token', range(1, 128)), 'aloft' => slot(64), 'back' => slot(104)]);
check('128 tokens with both slots is 200', $s === 200 && shaped($b));

// ---- The body cap -----------------------------------------------------------
$tokens128 = array_map('token', range(1000, 1127));
$large = json_encode(['tokens' => $tokens128, 'aloft' => slot(64), 'back' => slot(104)]);
$withBefore = counts($pool);
[$s, $b] = post($port, $large);
check('the 8,192-byte cap takes 128 tokens and both slots (' . strlen($large) . ' bytes)',
    strlen($large) < 8192 && $s === 200 && shaped($b));
check('and both slots were stored', counts($pool) === [$withBefore[0] + 1, $withBefore[1] + 1]);
[$s] = post($port, str_repeat(' ', 8200) . json_encode(['tokens' => []]));
check('a body past the cap is still refused', $s === 400);

// ---- A locked pool ----------------------------------------------------------
$lock = new PDO('sqlite:' . $pool, null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$lock->exec('BEGIN EXCLUSIVE');
$started = microtime(true);
[$s, $b] = post($port, ['tokens' => $tokens, 'aloft' => slot(64), 'back' => slot(104)]);
$waited = microtime(true) - $started;
check('a locked pool: 200, both bundles at their lengths', $s === 200 && shaped($b));
check('and the wait is about a second, not more', $waited < 5);
$lock->exec('ROLLBACK');
$lock = null;
[$s, $b] = post($port, ['tokens' => $tokens]);
check('the pool answers again once unlocked', $s === 200 && shaped($b));

// ---- The error log ----------------------------------------------------------
$log = file_exists($errors) ? (string) file_get_contents($errors) : '';
$leak = false;
foreach ($sent as $bytes) if (stripos($log, $bytes) !== false || stripos($log, substr($bytes, 0, 24)) !== false) $leak = true;
check('the error log holds no slot bytes', !$leak);
check('and does hold the refusals (status and route)', str_contains($log, 'plot service: 400 on /api/walk/pending'));

echo $failures === 0 ? "\nAll checks held.\n" : "\n$failures failed.\n";
exit($failures === 0 ? 0 : 1);
