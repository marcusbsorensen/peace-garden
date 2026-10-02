<?php
declare(strict_types=1);

/**
 * The curator's tool: a plant taken down is gone from every public read, still
 * holds its seed against a second release, and comes back exactly as it was.
 *
 * Run: php tools/reference/check_curate.php
 *
 * It runs `Server/.api/curate.php` the way a curator does over ssh — as its own
 * process, pointed at a throwaway SQLite file by `PG_WALK_DSN` — and reads the
 * field back the way a page does, over HTTP, from PHP's own server standing in
 * front of a copy of the service pointed at the same file:
 *
 *   - `hide` takes one plant down by its seed or a beginning only it has, says
 *     which, and changes the one flag and nothing else; `unhide` puts it back
 *     exactly; `show` and `list` change nothing,
 *   - a prefix two plants share, one too short, or one nobody has, changes
 *     nothing,
 *   - hidden, it is in no count at `/api/wild` and no tile, names included,
 *   - it cannot be released again or offered to an area, and the nightly copy
 *     still counts it,
 *   - and the tool will not run as a web page, even on a host that would run it.
 */

require_once __DIR__ . '/../../Server/.api/Seeds.php';
require_once __DIR__ . '/../../Server/.api/WalkStore.php';
require_once __DIR__ . '/../../Server/.api/WildFields.php';

$failures = 0;
function check(string $what, bool $held): void
{
    global $failures;
    if (!$held) { $failures++; fwrite(STDERR, "FAILED  $what\n"); }
    else fwrite(STDOUT, "ok      $what\n");
}

$api = dirname(__DIR__, 2) . '/Server/.api';
$scratch = sys_get_temp_dir() . '/peacegarden-curate-' . getmypid();
@mkdir($scratch, 0700, true);
$file = "$scratch/walk.sqlite";
@unlink($file);
$dsn = 'sqlite:' . $file;

/** One run of the tool, as a curator types it: [exit status, what it said, what it complained of]. */
function curate(string ...$args): array
{
    global $api, $dsn;
    $process = proc_open(['php', "$api/curate.php", ...$args], [1 => ['pipe', 'w'], 2 => ['pipe', 'w']], $pipes,
                         null, ['PG_WALK_DSN' => $dsn, 'PATH' => getenv('PATH')]);
    $out = stream_get_contents($pipes[1]);
    $err = stream_get_contents($pipes[2]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    return [proc_close($process), $out, $err];
}

/** Every row of both of the field's tables, in order: what "nothing else changed" is checked against. */
function field(PDO $db): array
{
    return [$db->query('SELECT * FROM wild_fields ORDER BY seed')->fetchAll(PDO::FETCH_ASSOC),
            $db->query('SELECT * FROM wild_names ORDER BY seed')->fetchAll(PDO::FETCH_ASSOC)];
}

function token(string $of): string { return substr(hash('sha256', $of), 0, 32); }

// MARK: A field with something in it

$walk = WalkStore::open($dsn);
$db = $walk->connection();
$wild = $walk->wild();
$none = ['name' => null, 'place' => null, 'month' => null];

// The one taken down: a real cross, so it can be released again over HTTP,
// with a name and a meeting both chose standing beside it.
$a = hash('sha256', 'curate parent a');
$b = hash('sha256', 'curate parent b');
$meeting = hash('sha256', 'curate meeting');
$seed = Seeds::cross($a, $b, $meeting);
$wild->release($seed, $a, $b);
$wild->beside($seed, token('curate one'), token('curate two'), ['name' => 'Wren', 'place' => 'Lisbon', 'month' => '2026-09']);
$wild->answer($seed, token('curate two'), ['name' => 'Ash', 'place' => 'Lisbon', 'month' => '2026-09']);
[$tx, $tz] = WildFields::tile($seed);

// Two that share their first ten characters, for a prefix that names neither.
$twinA = 'abcdef0123' . substr(hash('sha256', 'twin a'), 10);
$twinB = 'abcdef0123' . substr(hash('sha256', 'twin b'), 10);
$wild->release($twinA, $a, $b);
$wild->release($twinB, $a, $b);
check('the field is sown with three plants, one with names beside it',
      count($wild->matching('')) === 3 && ($wild->find($seed)['shown']['names'] ?? []) === ['Ash', 'Wren']);

$before = field($db);
$prefix = substr($seed, 0, 12);

// MARK: The service, as a page reads it

// A copy of the service, so its `config.php` can point at the scratch file
// without touching the checkout's. The files are the checkout's own.
$site = "$scratch/site";
@mkdir("$site/.api", 0700, true);
copy(dirname($api) . '/index.php', "$site/index.php");
foreach (glob("$api/*.php") as $php) {
    if (basename($php) !== 'config.php') copy($php, "$site/.api/" . basename($php));
}
file_put_contents("$site/.api/config.php", '<?php return ' . var_export(['dsn' => $dsn], true) . ';');

$listen = stream_socket_server('tcp://127.0.0.1:0');
$port = (int) substr(strrchr(stream_socket_get_name($listen, false), ':'), 1);
fclose($listen);
// No router script: PHP's server runs any `.php` file at its own path, which
// is the host this check wants — one that would run `/.api/curate.php` if
// asked — and hands everything else to `index.php`, as nginx does.
$server = proc_open(['php', '-S', "127.0.0.1:$port", '-t', $site], [1 => ['file', '/dev/null', 'w'],
                    2 => ['file', '/dev/null', 'w']], $serverPipes);
register_shutdown_function(function () use ($server, $scratch) {
    proc_terminate($server);
    proc_close($server);
    exec('rm -rf ' . escapeshellarg($scratch));
});
for ($i = 0; $i < 100 && !@fsockopen('127.0.0.1', $port); $i++) usleep(50_000);

/** [status, decoded body] for one request to the copy. */
function http(string $method, string $path, ?array $body = null): array
{
    global $port;
    $context = stream_context_create(['http' => [
        'method' => $method, 'ignore_errors' => true,
        'header' => "Content-Type: application/json\r\n",
        'content' => $body === null ? '' : json_encode($body),
    ]]);
    $text = @file_get_contents("http://127.0.0.1:$port$path", false, $context);
    $status = (int) (explode(' ', $http_response_header[0] ?? 'HTTP/1.1 0')[1] ?? 0);
    return [$status, json_decode((string) $text, true), (string) $text];
}

function counted(): int
{
    [, $wild] = http('GET', '/api/wild');
    return array_sum(array_column($wild['standing'] ?? [], 2));
}

function inTile(string $seed): bool
{
    global $tx, $tz;
    [, $tile, $text] = http('GET', "/api/wild/tile/$tx/$tz");
    return in_array($seed, array_column($tile['plantings'] ?? [], 'seed'), true);
}

check('before: the service counts all three, and its tile serves it with its names',
      counted() === 3 && inTile($seed));

// MARK: Hiding

[$status, $out, $err] = curate('hide', $prefix);
check('hide by a prefix only it has succeeds', $status === 0 && $err === '');
check('and says what it hid: the whole seed, its tile, its parents, its names',
      str_contains($out, 'Hidden') && str_contains($out, $seed) && str_contains($out, "tile $tx,$tz")
      && str_contains($out, $a) && str_contains($out, 'Ash, Wren') && str_contains($out, 'Lisbon'));
check('the plant is hidden', $wild->isHidden($seed));

$after = field($db);
$flagged = $before;
foreach ($flagged[0] as &$row) if ($row['seed'] === $seed) $row['hidden'] = 1;
unset($row);
check('and the flag is the only thing that changed: no row gone, none added, no note, no time',
      $after === $flagged);
check('the field has no column for a reason, a time or a curator',
      array_column($db->query('PRAGMA table_info(wild_fields)')->fetchAll(PDO::FETCH_ASSOC), 'name')
      === ['seed', 'parent_a', 'parent_b', 'tile_x', 'tile_z', 'hidden']);

check('hidden, it is in no count at /api/wild', counted() === 2);
check('nor in its tile at /api/wild/tile, and so neither are its names', !inTile($seed)
      && !str_contains(http('GET', "/api/wild/tile/$tx/$tz")[2], 'Wren'));
check('the store serves it to nothing that reads the field', $wild->find($seed) === null
      && !in_array($seed, array_column($wild->tile($tx, $tz), 'seed'), true));

[$status, $body] = http('POST', '/api/wild/release', ['seed' => $seed, 'parents' => [$a, $b], 'encounter' => $meeting]);
check("a second release of it is refused, 410, and not answered with the planting ($status)",
      $status === 410 && !isset($body['planting']));
[$status, $body] = http('POST', '/api/wild/release', ['seed' => $seed, 'parents' => [$a, $b], 'encounter' => $meeting,
                        'token' => token('curate one'), 'theirs' => token('curate two'), 'shown' => ['name' => 'Wren']]);
check('even by one of the two who grew it, with names', $status === 410 && !isset($body['beside']));
check('and the refusals stood nothing up and changed nothing', field($db) === $flagged && counted() === 2);
check('nor can it be offered to an area', $walk->offers()->offer($seed, token('o to'), token('o from'), $a, $b,
      $meeting, 1.0, 1, time()) === [false, false]);

$copy = [];
exec('PG_WALK_DSN=' . escapeshellarg($dsn) . ' php ' . escapeshellarg("$api/backup.php") . ' --preamble', $copy);
check('the nightly copy still counts it', in_array('-- rows wild_fields 3', $copy, true)
      && in_array('wild_fields', explode(' ', (string) shell_exec('php ' . escapeshellarg("$api/backup.php") . ' --tables')), true));

[$status, $out] = curate('hide', $seed);
check('hiding it again says so and changes nothing', $status === 0 && str_contains($out, 'Already hidden')
      && field($db) === $flagged);

// MARK: Looking

[$status, $out] = curate('show', $prefix);
check('show finds it, says it is hidden, and changes nothing', $status === 0 && str_contains($out, "$seed  hidden")
      && field($db) === $flagged);
[$status, $out] = curate('show', 'abcdef');
check('show lists every plant a prefix matches', $status === 0 && str_contains($out, $twinA)
      && str_contains($out, $twinB) && substr_count($out, 'standing') === 2);
[$status, $out] = curate('list');
check('list names the hidden plant and only it', $status === 0 && str_contains($out, $seed)
      && !str_contains($out, $twinA) && str_contains($out, '1 hidden'));

// MARK: Prefixes

[$status, $out, $err] = curate('hide', 'abcdef0123');
check('a prefix two plants share is refused, both listed, neither hidden', $status === 1
      && str_contains($err, $twinA) && str_contains($err, $twinB) && str_contains($err, 'none was changed')
      && field($db) === $flagged);
[$status, , $err] = curate('hide', 'abcde');
check('a prefix shorter than six is refused', $status === 2 && field($db) === $flagged);
[$status, , $err] = curate('hide', '000000');
check('a prefix nobody has is said so, and changes nothing', $status === 1 && str_contains($err, 'No plant')
      && field($db) === $flagged);
[$status] = curate('hide', 'zzzzzz');
check('a seed that is not hex is refused', $status === 2);
[$status] = curate('hide', $prefix, 'extra');
check('so is a stray word', $status === 2);
[$status] = curate('delete', $prefix);
check('and there is no verb that deletes', $status === 2 && field($db) === $flagged);
[$status] = curate('hide', strtoupper($prefix));
check('a seed copied in capitals is the same seed', $status === 0 && field($db) === $flagged);

// MARK: Standing again

[$status, $out] = curate('unhide', $prefix);
check('unhide stands it again and says so', $status === 0 && str_contains($out, 'Standing again')
      && str_contains($out, $seed));
check('exactly as it was, names and all', field($db) === $before);
check('counted and served again', counted() === 3 && inTile($seed)
      && str_contains(http('GET', "/api/wild/tile/$tx/$tz")[2], 'Wren'));
[$status, $body] = http('POST', '/api/wild/release', ['seed' => $seed, 'parents' => [$a, $b], 'encounter' => $meeting]);
check('and a release of it is answered with the planting again', $status === 200
      && ($body['planting']['seed'] ?? null) === $seed);
[$status, $out] = curate('unhide', $seed);
check('unhiding a plant that stands says so and changes nothing', $status === 0
      && str_contains($out, 'Not hidden') && field($db) === $before);
[$status, $out] = curate('list');
check('and list is empty', $status === 0 && str_contains($out, 'Nothing is hidden'));

// MARK: Only from the command line

$heard = http('GET', '/.api/curate.php');
$heard2 = http('GET', '/.api/curate.php?hide=' . $prefix);
check("run as a web page, on a host that would run it, it answers 404 and does nothing ({$heard[0]})",
      $heard[0] === 404 && $heard[2] === '' && $heard2[0] === 404 && field($db) === $before);
check('and the service has no route to it', http('GET', '/api/curate')[0] === 404
      && http('POST', '/api/curate', ['hide' => $seed])[0] === 404 && field($db) === $before);
check('the tool refuses any SAPI but the command line before it reads a thing',
      (bool) preg_match("/\A<\?php\s+declare\(strict_types=1\);\s+\/\*\*.*?\*\/\s+if \(PHP_SAPI !== 'cli'\) \{/s",
                        (string) file_get_contents("$api/curate.php")));

unset($walk, $db, $wild);

fwrite(STDOUT, $failures === 0 ? "\nThe curator's tool holds.\n" : "\n$failures failed.\n");
exit($failures === 0 ? 0 : 1);
