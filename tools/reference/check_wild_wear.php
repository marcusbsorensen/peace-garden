<?php
declare(strict_types=1);

/**
 * Paths that visitors wear in the Wild Fields: a number per ground cell that
 * fades, is capped a day, keeps nothing about anybody, and is off unless a
 * copy turns it on.
 *
 * Run: php tools/reference/check_wild_wear.php
 *      php tools/reference/check_wild_wear.php 'mysql:host=…;dbname=…' user password
 *
 * With no arguments it runs on a throwaway SQLite file; given a DSN, on that
 * database, which must hold no wear yet (it refuses one that does, so it
 * cannot be pointed at a field somebody walked). It drives `WildWear` itself
 * rather than HTTP, as `check_wild_fields.php` does, so it says which step
 * broke — except for the one thing only a request can show: that the routes
 * are not there on a copy that has not turned wear on.
 *
 *   - **A batch**: each cell in it counts once, however often it is in it,
 *     and a batch that is not a list of cells is refused.
 *   - **The cap**: a cell counts at most `CAP` crossings a day, and the next
 *     day it counts again.
 *   - **The fading**: a cell's wear halves in `HALF_LIFE` days, read without
 *     writing; the field is faded once a day however many ask; a cell faded
 *     below `FLOOR` is gone. And the doc's own sentence, in numbers: one
 *     visitor's day shows nothing, a route walked all summer is a path by
 *     autumn, and the most-walked path left in autumn is grass by spring.
 *   - **What a row keeps**: the cell, its wear and today's count, and on
 *     SQLite no hidden row number.
 *   - **The page's grid is the service's**, and the route is limited.
 */

require_once __DIR__ . '/../../Server/.api/WildFields.php';
require_once __DIR__ . '/../../Server/.api/WildWear.php';
require_once __DIR__ . '/../../Server/.api/Limits.php';

$failures = 0;
function check(string $what, bool $held): void
{
    global $failures;
    if (!$held) { $failures++; fwrite(STDERR, "FAILED  $what\n"); }
    else fwrite(STDOUT, "ok      $what\n");
}

$file = null;
if (isset($argv[1])) {
    $db = new PDO($argv[1], $argv[2] ?? null, $argv[3] ?? null, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_STRINGIFY_FETCHES => false,
    ]);
} else {
    $file = sys_get_temp_dir() . '/peacegarden-wear-' . getmypid() . '.sqlite';
    @unlink($file);
    $db = new PDO('sqlite:' . $file, null, null, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_STRINGIFY_FETCHES => false,
    ]);
}
$sqlite = $db->getAttribute(PDO::ATTR_DRIVER_NAME) === 'sqlite';
$wear = new WildWear($db);
if ((int) $db->query('SELECT COUNT(*) FROM wild_wear')->fetchColumn() > 0
    || (int) $db->query('SELECT COUNT(*) FROM wild_wear_day')->fetchColumn() > 0) {
    fwrite(STDERR, "That database already holds wear. This check wants an empty one.\n");
    exit(2);
}
fwrite(STDOUT, 'on ' . ($sqlite ? 'SQLite' : $db->getAttribute(PDO::ATTR_DRIVER_NAME)) . "\n");

// Noon on a day well inside any clock, and the days after it.
const DAY = 86400;
$first = 20_600;
$on = fn (int $day) => $day * DAY + 12 * 3600;
$cell = function (array $field, int $x, int $z): ?float {
    foreach ($field as [$cx, $cz, $w]) if ($cx === $x && $cz === $z) return (float) $w;
    return null;
};
$stored = fn (int $x, int $z) => (function () use ($db, $x, $z) {
    $query = $db->prepare('SELECT wear, today FROM wild_wear WHERE cell_x = ? AND cell_z = ?');
    $query->execute([$x, $z]);
    $row = $query->fetch();
    return $row === false ? null : [(float) $row['wear'], (int) $row['today']];
})();
$daySaid = fn () => (int) $db->query('SELECT day FROM wild_wear_day WHERE id = 1')->fetchColumn();

// MARK: The grid

check('the cells go across the field a whole number of times',
      WildWear::CELLS * WildWear::CELL === WildFields::SIDE);
check('and a tile is a whole number of them', fmod(WildFields::TILE, WildWear::CELL) === 0.0);

// The page counts the same cells (`wear.js`), or what it sends lands somewhere
// else on the field than where the visitor walked.
$page = (string) file_get_contents(__DIR__ . '/../../Server/assets/js/wear.js');
preg_match('/export const CELL = ([0-9.]+);/', $page, $cellJs);
preg_match('/export const CELLS = ([0-9]+);/', $page, $cellsJs);
preg_match('/export const SEEN = ([0-9.]+);/', $page, $seenJs);
check('the page cuts the field into the same cells',
      (float) ($cellJs[1] ?? 0) === WildWear::CELL && (int) ($cellsJs[1] ?? 0) === WildWear::CELLS);
check('and draws from the same least wear when it invents a field',
      (float) ($seenJs[1] ?? 0) === (float) WildWear::SEEN);

// MARK: A batch

check('a batch is a list of cells', WildWear::isBatch([[0, 0], [127, 127]]));
foreach ([
    'nothing' => [],
    'one number' => [5],
    'a cell of three' => [[1, 2, 3]],
    'a cell off the field' => [[128, 0]],
    'a cell before it' => [[0, -1]],
    'a fraction' => [[1.0, 2]],
    'a word' => [['1', 2]],
    'a keyed cell' => [['x' => 1, 'z' => 2]],
    'a keyed batch' => ['a' => [1, 2]],
    'too many' => array_fill(0, WildWear::MOST + 1, [1, 1]),
] as $what => $batch) {
    check("and $what is not", !WildWear::isBatch($batch));
}
check('the most a batch holds is enough for half a minute of brisk walking',
      WildWear::isBatch(array_fill(0, WildWear::MOST, [1, 1])));

$taken = $wear->walked([[3, 4], [5, 6], [3, 4], [3, 4]], $on($first));
check('a batch counts each cell once, however often it is in it', $taken === 2
      && $stored(3, 4) === [1.0, 1] && $stored(5, 6) === [1.0, 1]);
$wear->walked([[3, 4]], $on($first));
check('and the next batch counts it again', $stored(3, 4) === [2.0, 2]);
check('the field reads back as cells and wear, in the order of the cells',
      $wear->field($on($first)) === [[3, 4, 2.0], [5, 6, 1.0]]);
check('the field is told the day it was first walked', $daySaid() === $first);

// MARK: The cap

for ($i = 0; $i < 20; $i++) $wear->walked([[10, 10], [10, 11]], $on($first));
check('a cell counts at most ' . WildWear::CAP . ' crossings a day, however many arrive',
      $stored(10, 10) === [(float) WildWear::CAP, WildWear::CAP]);
check('one visitor panning back and forth all day shows nothing',
      $stored(10, 10)[0] < WildWear::SEEN && WildWear::CAP < WildWear::SEEN);
check('the cap is each cell\'s own', $stored(3, 4) === [2.0, 2]);
for ($i = 0; $i < 20; $i++) $wear->walked([[10, 10]], $on($first + 1));
$f = WildWear::fading(1);
check('the next day it counts again, on top of what is left of yesterday',
      abs($stored(10, 10)[0] - (WildWear::CAP * $f + WildWear::CAP)) < 1e-9
      && $stored(10, 10)[1] === WildWear::CAP);
check('and a cell nobody crossed today has nothing counted towards today', $stored(10, 11)[1] === 0);

// MARK: The fading

check('a day takes the same fraction from every cell', abs(WildWear::fading(1) ** 30 - 0.5) < 1e-12);
$before = $stored(3, 4);
$read = $wear->field($on($first + 1 + WildWear::HALF_LIFE));
check('read a half-life later, a cell shows half its wear',
      abs(($cell($read, 3, 4) ?? 0) - round($before[0] / 2, 2)) < 1e-9);
check('and reading wrote nothing', $stored(3, 4) === $before && $daySaid() === $first + 1);

$grassed = $wear->settle($on($first + 1 + WildWear::HALF_LIFE));
check('settled a half-life later, every cell holds half', abs($stored(3, 4)[0] - $before[0] / 2) < 1e-9
      && abs($stored(10, 10)[0] - (WildWear::CAP * $f + WildWear::CAP) / 2) < 1e-9);
check('the cell crossed once is gone, faded to half a crossing and below',
      $stored(5, 6) === null && $grassed >= 1);
$again = $stored(10, 10);
check('settled again the same day, nothing fades twice',
      $wear->settle($on($first + 1 + WildWear::HALF_LIFE) + 3600) === 0 && $stored(10, 10) === $again);
check('the field\'s one date is the day it was last faded to', $daySaid() === $first + 1 + WildWear::HALF_LIFE);
$wear->walked([[3, 4]], $on($first + 1 + WildWear::HALF_LIFE));
check('a batch the same day adds to the faded wear', abs($stored(3, 4)[0] - ($before[0] / 2 + 1)) < 1e-9);

// A field nobody has walked for a long time. Reading shows nothing faded
// past the floor; the next batch, or the sweep, lets those cells go.
$far = $first + 1 + WildWear::HALF_LIFE + 400;
check('after a long quiet, reading shows only what is still worn', $wear->field($on($far)) === []);
$wear->settle($on($far));
check('and the first settle after it lets every faded cell go',
      (int) $db->query('SELECT COUNT(*) FROM wild_wear')->fetchColumn() === 0);

// MARK: A summer, an autumn and a spring

// The doc's own sentence: *a route walked all summer is a clear path by
// autumn, and one abandoned in autumn is grass again by spring.* Walked once
// a day from June to September, a cell is several times what the page draws
// at all; walked as much as the cap allows from June to September and then
// left, it has faded below it by the spring equinox. Each day is one batch
// per crossing, through the same `walked` a page reaches.
$june = $far + 10;
for ($d = 0; $d < 122; $d++) {
    $wear->walked([[40, 40]], $on($june + $d));                     // one visitor a day
    for ($k = 0; $k < WildWear::CAP + 2; $k++) {
        $wear->walked([[41, 40]], $on($june + $d));                 // more than the cap allows
    }
}
$autumn = $wear->field($on($june + 122));
check(sprintf('a route crossed once a day all summer is a clear path by autumn (%.1f crossings, %d drawn)',
              $cell($autumn, 40, 40) ?? 0, WildWear::SEEN),
      ($cell($autumn, 40, 40) ?? 0) > 4 * WildWear::SEEN);
$most = $cell($autumn, 41, 40) ?? 0;
check(sprintf('the most a cell can hold is the cap over a day\'s fading (%.1f)', $most),
      $most <= WildWear::CAP / (1 - WildWear::fading(1)) + 1e-9 && $most > 200);
$spring = $wear->field($on($june + 122 + 171));
check(sprintf('the most-walked path, left at the end of September, is grass by the spring equinox (%.1f)',
              $cell($spring, 41, 40) ?? 0),
      ($cell($spring, 41, 40) ?? 0) < WildWear::SEEN);

// MARK: What a row keeps

if ($sqlite) {
    $columns = array_column($db->query('PRAGMA table_info(wild_wear)')->fetchAll(), 'name');
    $dayColumns = array_column($db->query('PRAGMA table_info(wild_wear_day)')->fetchAll(), 'name');
} else {
    $columns = array_column($db->query('SHOW COLUMNS FROM wild_wear')->fetchAll(), 'Field');
    $dayColumns = array_column($db->query('SHOW COLUMNS FROM wild_wear_day')->fetchAll(), 'Field');
}
check('a row is a cell, its wear and today\'s count, and nothing else: ' . implode(', ', $columns),
      $columns === ['cell_x', 'cell_z', 'wear', 'today']);
check('the field\'s one date is one number: ' . implode(', ', $dayColumns), $dayColumns === ['id', 'day']
      && (int) $db->query('SELECT COUNT(*) FROM wild_wear_day')->fetchColumn() === 1);
if ($sqlite) {
    $rowid = true;
    try {
        $db->query('SELECT rowid FROM wild_wear')->fetchAll();
    } catch (PDOException) {
        $rowid = false;
    }
    check('and SQLite keeps no hidden row number that would count arrivals', $rowid === false);
    $tables = $db->query("SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name")
                 ->fetchAll(PDO::FETCH_COLUMN);
    check('walking made no table but the two: ' . implode(', ', $tables),
          $tables === ['wild_wear', 'wild_wear_day']);
}

// MARK: The route

check('the batch route is limited as every write is', isset(Limits::ROUTES['/api/wild/wear']));

// **Off unless turned on.** A copy with no `config.php` saying `'wear' =>
// true` — CI, and the live site, whose `config.php` is written on the server
// — has no wear routes at all: both answer 404 before the rate limit or the
// database is touched. Asked of the local site the way a browser would, on a
// port of its own. A copy whose own `config.php` turns wear on skips this.
$config = __DIR__ . '/../../Server/.api/config.php';
$turnedOn = is_file($config) && ((require $config)['wear'] ?? false) === true;
if ($turnedOn) {
    fwrite(STDOUT, "skip    this copy's config.php turns wear on, so its routes are there\n");
} else {
    $root = dirname(__DIR__, 2);
    $port = 18800 + getmypid() % 900;
    $server = proc_open(['php', '-S', "127.0.0.1:$port", '-t', "$root/Server", "$root/tools/wasm/dev-router.php"],
                        [1 => ['file', '/dev/null', 'w'], 2 => ['file', '/dev/null', 'w']], $pipes);
    $ask = function (string $method, string $body = '') use ($port): ?int {
        $context = stream_context_create(['http' => [
            'method' => $method, 'ignore_errors' => true, 'timeout' => 3,
            'header' => "Content-Type: application/json\r\n", 'content' => $body,
        ]]);
        $stream = @fopen("http://127.0.0.1:$port/api/wild/wear", 'r', false, $context);
        if ($stream === false) return null;
        $status = stream_get_meta_data($stream)['wrapper_data'][0] ?? '';
        fclose($stream);
        return preg_match('#\s(\d{3})\s#', $status, $m) ? (int) $m[1] : null;
    };
    $read = null;
    for ($i = 0; $i < 40 && $read === null; $i++) {
        usleep(100_000);
        $read = $ask('GET');
    }
    $sent = $ask('POST', '{"cells":[[1,2]]}');
    // And the privacy page leaves out its paragraph on wear (2 October 2026),
    // marks and all, so a site with wear off never describes it.
    $privacy = (string) @file_get_contents("http://127.0.0.1:$port/privacy");
    proc_terminate($server);
    proc_close($server);
    check("where wear is not turned on, the field's wear cannot be read ($read)", $read === 404);
    check("nor a batch sent ($sent)", $sent === 404);
    check('and the privacy page does not describe it',
          str_contains($privacy, 'data-s="privacy8"') && !str_contains($privacy, 'privacy9')
          && !str_contains($privacy, '<!--wear-->'));
    $page = (string) file_get_contents(__DIR__ . '/../../Server/.pages/privacy');
    check('though its paragraph is there for a site that has wear on',
          str_contains($page, '<!--wear--><p class="body" data-s="privacy9"></p><!--/wear-->'));
}

unset($wear, $db);
if ($file !== null) @unlink($file);

fwrite(STDOUT, $failures === 0 ? "\nThe paths hold.\n" : "\n$failures failed.\n");
exit($failures === 0 ? 0 : 1);
