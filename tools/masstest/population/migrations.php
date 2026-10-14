<?php
declare(strict_types=1);

/**
 * The schema version on MariaDB (14 October 2026): a fresh database, and a
 * database the code before the version built and then the new code upgraded.
 * Run by migrations.sh, which serves the old code and then the new; see the
 * population report, *After the fixes, 14 October*.
 *
 *   php migrations.php snapshot DB FILE        every table's schema and rows, as JSON
 *   php migrations.php first DB FILE           two requests, timed: the one that migrates, and the next
 *   php migrations.php latin1-setup DB         names the old code could and could not keep, over HTTP
 *   php migrations.php latin1-verify DB FILE   after the upgrade: what came back, and an emoji now
 *   php migrations.php legacy DB               rows as the code before 24 September left them
 *   php migrations.php compare BEFORE AFTER FRESH FILE
 *
 * Local only, as lib.mjs: the base must be loopback.
 */

require_once __DIR__ . '/../../../Server/.api/Seeds.php';

$base = getenv('PGMT_BASE') ?: 'http://127.0.0.1:8811';
if (!in_array(parse_url($base, PHP_URL_HOST), ['127.0.0.1', 'localhost'], true)) exit("refusing: not local\n");

function pdo(string $db): PDO
{
    return new PDO("mysql:host=127.0.0.1;port=3407;dbname=pgmt_$db;charset=utf8mb4", 'root', 'root-local-only', [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
}

function http(string $method, string $path, string $db, ?array $body = null, string $addr = '198.18.200.1'): array
{
    global $base;
    $headers = "X-Sim-Db: pgmt_$db\r\nX-Sim-Addr: $addr\r\n";
    $options = ['method' => $method, 'header' => $headers, 'ignore_errors' => true, 'timeout' => 120];
    if ($body !== null) {
        $options['header'] .= "Content-Type: application/json\r\n";
        $options['content'] = json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }
    $t = microtime(true);
    $text = file_get_contents($base . $path, false, stream_context_create(['http' => $options]));
    $ms = (microtime(true) - $t) * 1000;
    preg_match('#\s(\d{3})\s#', $http_response_header[0] ?? '', $m);
    return ['status' => (int) ($m[1] ?? 0), 'json' => json_decode((string) $text, true), 'ms' => round($ms, 1)];
}

/** A true cross, made the way SeedCore makes one, from a label. */
function crossOf(string $label): array
{
    $a = hash('sha256', "migrations $label a");
    $b = hash('sha256', "migrations $label b");
    $e = hash('sha256', "migrations $label meeting");
    return ['seed' => Seeds::cross($a, $b, $e), 'parents' => [$a, $b], 'encounter' => $e,
            'tokenA' => substr(hash('sha256', "migrations $label token a"), 0, 32),
            'tokenB' => substr(hash('sha256', "migrations $label token b"), 0, 32)];
}

function snapshot(string $db): array
{
    $pdo = pdo($db);
    $tables = $pdo->query('SELECT TABLE_NAME, TABLE_COLLATION FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() ORDER BY TABLE_NAME')->fetchAll(PDO::FETCH_KEY_PAIR);
    $out = [];
    foreach ($tables as $table => $collation) {
        $create = $pdo->query("SHOW CREATE TABLE `$table`")->fetch()['Create Table'];
        $create = preg_replace('/ AUTO_INCREMENT=\d+/', '', $create);
        $columns = $pdo->query("SELECT COLUMN_NAME, COLLATION_NAME FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '$table' AND COLLATION_NAME IS NOT NULL")
            ->fetchAll(PDO::FETCH_KEY_PAIR);
        $rows = $pdo->query("SELECT * FROM `$table`")->fetchAll();
        // In a stable order whatever the table's key is.
        usort($rows, fn ($x, $y) => strcmp(json_encode($x), json_encode($y)));
        $out[$table] = ['collation' => $collation, 'columns' => $columns, 'create' => $create, 'rows' => $rows];
    }
    return $out;
}

/** The column definitions of a CREATE TABLE, without the order MariaDB happens to list them in. */
function shape(string $create): array
{
    $lines = array_map('trim', explode("\n", $create));
    $lines = array_filter($lines, fn ($l) => $l !== '' && !str_starts_with($l, 'CREATE TABLE') && !str_starts_with($l, ')'));
    $lines = array_map(fn ($l) => rtrim($l, ','), $lines);
    sort($lines);
    $tail = '';
    foreach (explode("\n", $create) as $l) if (str_starts_with(trim($l), ')')) $tail = trim($l);
    return ['columns' => array_values($lines), 'table' => $tail];
}

$verb = $argv[1] ?? '';

if ($verb === 'snapshot') {
    file_put_contents($argv[3], json_encode(snapshot($argv[2]), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
    exit(0);
}

if ($verb === 'first') {
    $db = $argv[2];
    $before = (int) (pdo($db)->query("SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'schema_version'")->fetchColumn());
    $one = http('GET', '/api/walk', $db);
    $two = http('GET', '/api/walk', $db);
    $three = http('GET', '/api/wild', $db);
    $version = (int) pdo($db)->query('SELECT version FROM schema_version WHERE id = 1')->fetchColumn();
    $result = ['had schema_version before' => $before === 1, 'first request' => [$one['status'], $one['ms']],
               'second request' => [$two['status'], $two['ms']], 'GET /api/wild after' => [$three['status'], $three['ms']],
               'version' => $version];
    file_put_contents($argv[3], json_encode($result, JSON_PRETTY_PRINT));
    echo json_encode($result), "\n";
    exit($one['status'] === 200 && $two['status'] === 200 && $version >= 1 ? 0 : 1);
}

if ($verb === 'latin1-setup') {
    $db = $argv[2];
    $said = [];
    foreach (['Anna', 'Zoë', 'Rose 🌹', 'مريم'] as $i => $name) {
        $m = crossOf("latin1 $i");
        $r = http('POST', '/api/wild/release', $db, ['seed' => $m['seed'], 'parents' => $m['parents'],
            'encounter' => $m['encounter'], 'token' => $m['tokenA'], 'theirs' => $m['tokenB'], 'shown' => ['name' => $name]],
            "198.18.201.$i");
        $said[$name] = $r['status'];
    }
    // And an offer waiting across the deploy, and one accepted.
    foreach (['waiting', 'accepted'] as $i => $what) {
        $m = crossOf("latin1 offer $what");
        $plant = ['seed' => $m['seed'], 'parents' => $m['parents'], 'encounter' => $m['encounter'], 'height' => 1.1,
                  'family' => 2, 'area' => 'travel', 'kind' => 'pallida', 'habit' => 'star'];
        $said["offer $what"] = http('POST', '/api/walk/offer', $db, ['to' => $m['tokenB'], 'from' => $m['tokenA'], 'plant' => $plant],
                                    "198.18.202.$i")['status'];
        if ($what === 'accepted') {
            $said['yes'] = http('POST', '/api/walk/answer', $db, ['seed' => $m['seed'], 'to' => $m['tokenB'], 'yes' => true],
                                "198.18.203.$i")['status'];
        }
    }
    echo json_encode($said, JSON_UNESCAPED_UNICODE), "\n";
    exit(0);
}

if ($verb === 'latin1-verify') {
    $db = $argv[2];
    $result = [];
    foreach (['Anna', 'Zoë'] as $i => $name) {
        $m = crossOf("latin1 $i");
        $r = http('POST', '/api/wild/release', $db, ['seed' => $m['seed'], 'parents' => $m['parents'], 'encounter' => $m['encounter']],
                  "198.18.204.$i");
        $result["kept: $name"] = ($r['json']['planting']['shown']['names'] ?? []) === [$name] ? 'exactly' : json_encode($r['json']);
    }
    $m = crossOf('latin1 after');
    $r = http('POST', '/api/wild/release', $db, ['seed' => $m['seed'], 'parents' => $m['parents'], 'encounter' => $m['encounter'],
        'token' => $m['tokenA'], 'theirs' => $m['tokenB'], 'shown' => ['name' => 'Rose 🌹']], '198.18.205.1');
    $result['a new name with an emoji'] = $r['status'] . ' ' . json_encode($r['json']['planting']['shown']['names'] ?? null, JSON_UNESCAPED_UNICODE);
    $m = crossOf('latin1 offer waiting');
    $r = http('POST', '/api/walk/answer', $db, ['seed' => $m['seed'], 'to' => $m['tokenB'], 'yes' => true], '198.18.205.2');
    $result['the offer waiting across the deploy, answered yes'] = $r['status'] . ' ' . ($r['json']['offer']['state'] ?? '?')
        . ($r['json']['planting'] ? ', planted' : ', nothing planted');
    $result['collations'] = pdo($db)->query("SELECT DISTINCT TABLE_COLLATION FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()")->fetchAll(PDO::FETCH_COLUMN);
    $result['column collations'] = pdo($db)->query("SELECT DISTINCT COLLATION_NAME FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND COLLATION_NAME IS NOT NULL")->fetchAll(PDO::FETCH_COLUMN);
    file_put_contents($argv[3], json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    echo json_encode($result, JSON_UNESCAPED_UNICODE), "\n";
    exit(0);
}

if ($verb === 'rollback-setup') {
    // Served by the old code again, after the upgrade: it takes a planting
    // back without letting go of its claim in `placed`, which it knows
    // nothing about.
    $m = crossOf('latin1 offer accepted');
    $r = http('POST', '/api/walk/withdraw', $argv[2], ['seed' => $m['seed'], 'token' => $m['tokenA']], '198.18.206.1');
    $held = pdo($argv[2])->prepare('SELECT place FROM placed WHERE seed = ?');
    $held->execute([$m['seed']]);
    echo json_encode(['withdrawn by the old code' => $r['status'] . ' ' . ($r['json']['offer']['state'] ?? '?'),
                      'claim left behind' => $held->fetchColumn()]), "\n";
    exit(0);
}

if ($verb === 'rollback-verify') {
    // The new code again: the plant is released by one of its two, over the
    // stale claim.
    $m = crossOf('latin1 offer accepted');
    $r = http('POST', '/api/wild/release', $argv[2], ['seed' => $m['seed'], 'parents' => $m['parents'],
        'encounter' => $m['encounter'], 'token' => $m['tokenA']], '198.18.206.2');
    $held = pdo($argv[2])->prepare('SELECT place FROM placed WHERE seed = ?');
    $held->execute([$m['seed']]);
    $result = ['released over the stale claim' => $r['status'], 'claim now' => $held->fetchColumn()];
    file_put_contents($argv[3], json_encode($result, JSON_PRETTY_PRINT));
    echo json_encode($result), "\n";
    exit($r['status'] === 201 ? 0 : 1);
}

if ($verb === 'legacy') {
    // What the code before 24 September left: a withdrawn offer and a declined
    // one keeping their seeds and tokens, and a planting hidden with its seed,
    // parents and meeting. Written after the old code's last request, which
    // would otherwise have erased them itself.
    $pdo = pdo($argv[2]);
    $w = crossOf('legacy withdrawn');
    $d = crossOf('legacy declined');
    $pdo->prepare("INSERT INTO walk_offers (seed, token_to, token_from, state, offered_at, answered_at, area)
        VALUES (?, ?, ?, 'withdrawn', 1790000000, 1790000050, 'travel'), (?, ?, ?, 'declined', 1790000000, 1790000070, 'meeting')")
        ->execute([$w['seed'], $w['tokenB'], $w['tokenA'], $d['seed'], $d['tokenB'], $d['tokenA']]);
    // A withdrawal then hid the planting and set its offer withdrawn, keeping
    // the seed and both tokens in the offer and everything in the planting.
    $hidden = $pdo->query("SELECT c.arrival, c.seed FROM crossing c JOIN walk_offers o ON o.seed = c.seed
        WHERE c.hidden = 0 AND o.state = 'accepted' ORDER BY c.arrival LIMIT 1")->fetch();
    if ($hidden) {
        $pdo->prepare('UPDATE crossing SET hidden = 1 WHERE arrival = ?')->execute([$hidden['arrival']]);
        $pdo->prepare("UPDATE walk_offers SET state = 'withdrawn', answered_at = answered_at + 60 WHERE seed = ?")
            ->execute([$hidden['seed']]);
    }
    echo json_encode(['legacy offers' => 2, 'hidden with its seed' => $hidden['seed'] ?? null]), "\n";
    exit(0);
}

if ($verb === 'compare') {
    [, , $beforeFile, $afterFile, $freshFile, $outFile] = $argv;
    $before = json_decode(file_get_contents($beforeFile), true);
    $after = json_decode(file_get_contents($afterFile), true);
    $fresh = json_decode(file_get_contents($freshFile), true);
    $report = ['tables only after' => array_values(array_diff(array_keys($after), array_keys($before))),
               'tables lost' => array_values(array_diff(array_keys($before), array_keys($after)))];
    // Rows: the same, but for what the migration is for.
    $changed = [];
    foreach ($before as $table => $was) {
        if (!isset($after[$table])) continue;
        $old = array_map('json_encode', $was['rows']);
        $new = array_map('json_encode', $after[$table]['rows']);
        $gone = array_values(array_diff($old, $new));
        $came = array_values(array_diff($new, $old));
        if ($gone || $came) $changed[$table] = ['rows before' => count($old), 'rows after' => count($new),
                                                'changed or gone' => count($gone), 'new or changed' => count($came),
                                                'examples' => array_slice(array_map(fn ($r) => json_decode($r, true), $came), 0, 3)];
    }
    $report['rows changed by the upgrade'] = $changed;
    $report['placed rows after'] = count($after['placed']['rows'] ?? []);
    $report['schema_version after'] = $after['schema_version']['rows'][0]['version'] ?? null;
    // Schema: the upgraded database against a fresh one, column by column.
    $differs = [];
    foreach ($fresh as $table => $made) {
        if (!isset($after[$table])) { $differs[$table] = 'missing after the upgrade'; continue; }
        $a = shape($after[$table]['create']);
        $f = shape($made['create']);
        if ($a !== $f) $differs[$table] = ['upgraded' => array_values(array_diff($a['columns'], $f['columns'])) ?: $a['table'],
                                           'fresh' => array_values(array_diff($f['columns'], $a['columns'])) ?: $f['table']];
        if ($after[$table]['collation'] !== $made['collation']) $differs["$table collation"] = [$after[$table]['collation'], $made['collation']];
    }
    $report['upgraded schema differs from fresh'] = $differs;
    $report['collations after'] = array_values(array_unique(array_column($after, 'collation')));
    $report['collations fresh'] = array_values(array_unique(array_column($fresh, 'collation')));
    file_put_contents($outFile, json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
    echo json_encode(['tables only after' => $report['tables only after'], 'tables lost' => $report['tables lost'],
                      'tables with changed rows' => array_keys($changed), 'schema differs' => array_keys($differs),
                      'placed' => $report['placed rows after'], 'version' => $report['schema_version after'],
                      'collations' => $report['collations after']]), "\n";
    exit($report['tables lost'] === [] && $differs === [] ? 0 : 1);
}

fwrite(STDERR, "usage: see the head of this file\n");
exit(2);
