<?php
declare(strict_types=1);

/**
 * The population test's invariants, checked against the local database and
 * the local service together.
 *
 *   php check.php OUT_DIR [db-suffix]
 *
 * Writes OUT_DIR/dump.json (every planting, for `popgen verify`, which checks
 * each one against SeedCore and the plan) and OUT_DIR/invariants.json, and
 * exits 1 if anything is wrong. Reads OUT_DIR/forged.json (seeds that must
 * never be accepted) and OUT_DIR/extra_genuine.json (true crosses grown
 * outside the plan, by the adversary and the load test) when they are there.
 *
 * Local only: the base must be loopback, as in lib.mjs.
 */

$out = $argv[1] ?? exit("usage: php check.php OUT_DIR [db]\n");
$db = 'pgmt_' . ($argv[2] ?? 'main');
$base = getenv('PGMT_BASE') ?: 'http://127.0.0.1:8811';
if (!in_array(parse_url($base, PHP_URL_HOST), ['127.0.0.1', 'localhost'], true)) exit("refusing: not local\n");

$pdo = new PDO("mysql:host=127.0.0.1;port=3407;dbname=$db;charset=utf8mb4", 'root', 'root-local-only', [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);
$rows = fn (string $sql, array $args = []) => (function () use ($pdo, $sql, $args) {
    $q = $pdo->prepare($sql);
    $q->execute($args);
    return $q->fetchAll();
})();

$violations = [];
$facts = [];
function violation(string $what, mixed $detail = null): void
{
    global $violations;
    $violations[$what] ??= ['count' => 0, 'examples' => []];
    $violations[$what]['count']++;
    if (count($violations[$what]['examples']) < 5) $violations[$what]['examples'][] = $detail;
}

function api(string $path): array
{
    global $base, $db;
    $context = stream_context_create(['http' => ['header' => "X-Sim-Db: $db\r\n", 'ignore_errors' => true,
                                                 'timeout' => 120]]);
    $t = microtime(true);
    $body = file_get_contents($base . $path, false, $context);
    $ms = (microtime(true) - $t) * 1000;
    preg_match('#\s(\d{3})\s#', $http_response_header[0] ?? '', $m);
    $json = json_decode((string) $body, true);
    return ['status' => (int) ($m[1] ?? 0), 'json' => $json, 'bytes' => strlen((string) $body), 'ms' => $ms,
            'valid' => json_last_error() === JSON_ERROR_NONE];
}

$AREAS = [
    'travel' => ['long_walk', 'walk', ['plot', 'side', 'tier', 'slot_index']],
    'peace' => ['quiet_garden', 'quiet', ['plot', 'corner', 'slot_index']],
    'meeting' => ['crossing', 'cross', ['plot', 'quarter', 'slot_index']],
    'kinship' => ['orchard', 'orchard', ['plot', 'guild', 'slot_index']],
    'pattern' => ['knot_garden', 'knot', ['plot', 'compartment', 'slot_index']],
    'beginnings' => ['seedbed', 'seedbed', ['plot', 'drill', 'slot_index']],
    'waiting' => ['cold_frame', 'frame', ['plot', 'frame', 'slot_rank', 'slot_index']],
    'light' => ['glasshouse', 'glasshouse', ['plot', 'bed', 'slot_row', 'slot_index']],
    'renewal' => ['coppice', 'coppice', ['plot', 'coupe', 'place', 'slot_index']],
    'ground' => ['home_ground', 'ground', ['plot', 'bed', 'crop', 'slot_index']],
];
$isMarker = fn (string $seed) => str_starts_with($seed, 'withdrawn:');
$now = time();

// MARK: - 1. The dump, for SeedCore to check every planting

$dump = ['areas' => [], 'wild' => [], 'extra_genuine' => []];
$standingIn = [];   // seed => area, for plantings that are shown
$everIn = [];       // seed => [areas], any row that still names it
foreach ($AREAS as $area => [$table]) {
    $all = $rows("SELECT * FROM $table ORDER BY arrival");
    $dump['areas'][$table] = array_map(fn ($r) => ['seed' => $r['seed'], 'parent_a' => $r['parent_a'],
        'parent_b' => $r['parent_b'], 'encounter' => $r['encounter'], 'hidden' => (int) $r['hidden'],
        'plot' => (int) $r['plot']], $all);
    foreach ($all as $r) {
        if ($isMarker($r['seed'])) {
            if ((int) $r['hidden'] !== 1 || $r['parent_a'] !== '' || $r['encounter'] !== '') {
                violation('a planting taken back still carries its lineage', [$table, $r['arrival']]);
            }
            continue;
        }
        if ((int) $r['hidden'] !== 0) violation('a hidden planting still carries its seed', [$table, $r['seed']]);
        $everIn[$r['seed']][] = $area;
        $standingIn[$r['seed']] = $area;
    }
    $facts['rows'][$table] = count($all);
}
$wild = $rows('SELECT seed, parent_a, parent_b, tile_x, tile_z, hidden FROM wild_fields ORDER BY seed');
$dump['wild'] = array_map(fn ($r) => ['seed' => $r['seed'], 'parent_a' => $r['parent_a'], 'parent_b' => $r['parent_b'],
    'tile_x' => (int) $r['tile_x'], 'tile_z' => (int) $r['tile_z'], 'hidden' => (int) $r['hidden']], $wild);
$facts['rows']['wild_fields'] = count($wild);
$facts['rows']['wild_hidden'] = count(array_filter($wild, fn ($r) => (int) $r['hidden'] !== 0));
$facts['rows']['wild_names'] = (int) $rows('SELECT COUNT(*) AS n FROM wild_names')[0]['n'];
foreach (glob("$out/extra_genuine*.json") as $file) {
    $dump['extra_genuine'] = array_merge($dump['extra_genuine'], json_decode(file_get_contents($file), true));
}
file_put_contents("$out/dump.json", json_encode($dump));

// MARK: - 2. Nothing forged

$forged = [];
foreach (glob("$out/forged*.json") as $file) $forged = array_merge($forged, json_decode(file_get_contents($file), true));
$wildSeeds = array_flip(array_column($wild, 'seed'));
$offers = $rows('SELECT * FROM walk_offers');
$offerSeeds = array_flip(array_column($offers, 'seed'));
foreach ($forged as $seed) {
    if (isset($everIn[$seed]) || isset($wildSeeds[$seed]) || isset($offerSeeds[$seed])) violation('a forged seed was accepted', $seed);
}
$facts['forged_tried'] = count($forged);

// MARK: - 3. One public place per plant

foreach ($everIn as $seed => $areas) {
    if (count($areas) > 1) violation('a plant stands in two areas', [$seed, $areas]);
    if (isset($wildSeeds[$seed])) violation('a plant stands in an area and in the Wild Fields', [$seed, $areas]);
}

// MARK: - 4 and 5. The Wild Fields: counts, tiles, hidden

$expected = [];
$hidden = [];
foreach ($wild as $r) {
    if ((int) $r['hidden'] !== 0) { $hidden[$r['seed']] = true; continue; }
    $expected[$r['tile_x']][$r['tile_z']][$r['seed']] = true;
}
$field = api('/api/wild');
if ($field['status'] !== 200 || !$field['valid']) violation('/api/wild did not answer', $field['status']);
$counted = [];
foreach ($field['json']['standing'] ?? [] as [$x, $z, $n]) $counted["$x,$z"] = $n;
$tileBytes = [];
$tileMs = [];
$shownSeen = 0;
for ($x = 0; $x < 8; $x++) {
    for ($z = 0; $z < 8; $z++) {
        $want = $expected[$x][$z] ?? [];
        if (($counted["$x,$z"] ?? 0) !== count($want)) {
            violation('/api/wild counts disagree with the database', ["$x,$z", $counted["$x,$z"] ?? 0, count($want)]);
        }
        $tile = api("/api/wild/tile/$x/$z");
        $tileBytes[] = $tile['bytes'];
        $tileMs[] = $tile['ms'];
        if ($tile['status'] !== 200 || !$tile['valid']) { violation('a tile did not answer', ["$x,$z", $tile['status']]); continue; }
        $got = [];
        foreach ($tile['json']['plantings'] as $p) {
            $got[$p['seed']] = true;
            if (isset($hidden[$p['seed']])) violation('a hidden plant is served in a tile', $p['seed']);
            [$sx, $sz] = $p['spot'];
            if (!is_numeric($sx) || $sx < $x * 8 || $sx >= $x * 8 + 8 || $sz < $z * 8 || $sz >= $z * 8 + 8) {
                violation('a wild plant stands outside its tile', [$p['seed'], $p['spot'], "$x,$z"]);
            }
            if (isset($p['shown'])) {
                $shownSeen++;
                $names = $p['shown']['names'];
                $sorted = $names;
                sort($sorted, SORT_STRING);
                if ($names !== $sorted) violation('names beside a plant are not in alphabetical order', $p['seed']);
            }
        }
        if (array_keys($got) != array_keys($want) && count(array_diff_key($got, $want)) + count(array_diff_key($want, $got)) > 0) {
            violation('a tile disagrees with the database', ["$x,$z", count($got), count($want)]);
        }
    }
}
sort($tileBytes);
sort($tileMs);
$facts['wild'] = ['standing' => array_sum($counted), 'hidden' => count($hidden), 'tiles_with_plants' => count($counted),
                  'tile_bytes_max' => end($tileBytes), 'tile_bytes_median' => $tileBytes[32],
                  'tile_ms_median' => round($tileMs[32], 1), 'tile_ms_max' => round(end($tileMs), 1),
                  'plantings_with_shown' => $shownSeen, 'wild_json_bytes' => $field['bytes']];

// MARK: - 6. The asking: lapsed at thirty days, erased when settled

$byState = [];
foreach ($offers as $o) {
    $byState[$o['state']] = ($byState[$o['state']] ?? 0) + 1;
    $erased = str_starts_with($o['seed'], 'h');
    switch ($o['state']) {
        case 'offered':
            if ((int) $o['offered_at'] + 30 * 86400 <= $now) violation('an offer is still waiting after thirty days', $o['offer']);
            if ($erased || $o['parent_a'] === null) violation('a waiting offer lost its plant', $o['offer']);
            break;
        case 'withdrawn':
        case 'declined':
            if (!$erased || !str_starts_with($o['token_to'], 'h') || !str_starts_with($o['token_from'], 'h')
                || $o['parent_a'] !== null || $o['encounter'] !== null || $o['height'] !== null || $o['area'] !== '') {
                violation("a $o[state] offer was not erased", $o['offer']);
            }
            if ($o['answered_at'] === null) violation("a $o[state] offer has no time it was settled", $o['offer']);
            break;
        case 'accepted':
            if ($erased || $o['parent_a'] !== null || $o['encounter'] !== null) violation('an accepted offer kept its plant', $o['offer']);
            if (($standingIn[$o['seed']] ?? null) !== $o['area']) {
                violation('an accepted offer has no planting standing in its area', [$o['seed'], $o['area'], $standingIn[$o['seed']] ?? null]);
            }
            break;
        default:
            violation('an offer in a state nobody knows', $o['state']);
    }
}
$acceptedSeeds = [];
foreach ($offers as $o) if ($o['state'] === 'accepted') $acceptedSeeds[$o['seed']] = $o['area'];
foreach ($standingIn as $seed => $area) {
    if (($acceptedSeeds[$seed] ?? null) !== $area) violation('a planting stands with no accepted offer for it', [$seed, $area]);
}
$lapsed = (int) $rows("SELECT COUNT(*) AS n FROM walk_offers WHERE state = 'withdrawn' AND answered_at - offered_at = 2592000")[0]['n'];
$facts['offers'] = $byState + ['lapsed_at_exactly_30_days' => $lapsed];

// MARK: - 7. The areas: valid, bounded, nothing on top of anything

foreach ($AREAS as $area => [$table, $route, $slot]) {
    $columns = implode(', ', $slot);
    foreach ($rows("SELECT $columns, COUNT(*) AS n FROM $table GROUP BY $columns HAVING COUNT(*) > 1") as $clash) {
        violation('two plantings share one place', [$table, $clash]);
    }
    if (in_array($table, ['seedbed', 'cold_frame'], true)) {
        $line = $table === 'seedbed' ? 'plot, drill' : 'plot, frame, slot_rank';
        $taken = [];
        foreach ($rows("SELECT seed, $line, slot_index, slot_span FROM $table") as $r) {
            $key = $table === 'seedbed' ? "$r[plot]/$r[drill]" : "$r[plot]/$r[frame]/$r[slot_rank]";
            for ($i = 0; $i < (int) $r['slot_span']; $i++) {
                $cell = $key . '/' . ((int) $r['slot_index'] + $i);
                if (isset($taken[$cell])) violation('a lotus overlaps another planting', [$table, $cell]);
                $taken[$cell] = true;
            }
        }
    }
    $head = api("/api/$route");
    if ($head['status'] !== 200 || !$head['valid'] || !is_int($head['json']['plots'] ?? null)) {
        violation('an area\'s count did not answer', [$route, $head['status']]);
        continue;
    }
    $plots = $head['json']['plots'];
    $max = (int) ($rows("SELECT COALESCE(MAX(plot) + 1, 0) AS n FROM $table")[0]['n']);
    if ($plots !== max(1, $max)) violation('an area\'s plot count disagrees with the database', [$route, $plots, $max]);
    $bytes = [];
    $ms = [];
    $closest = INF;
    $counts = [];
    $reach = [];
    for ($plot = 0; $plot < $plots; $plot++) {
        $page = api("/api/$route/plot/$plot");
        $bytes[] = $page['bytes'];
        $ms[] = $page['ms'];
        if ($page['status'] !== 200 || !$page['valid']) { violation('a plot did not answer', [$route, $plot, $page['status']]); continue; }
        $want = array_column($rows("SELECT seed FROM $table WHERE plot = ? AND hidden = 0", [$plot]), 'seed');
        $got = [];
        $spots = [];
        foreach ($page['json']['plantings'] as $p) {
            [$sx, $sz] = $p['spot'];
            if (!is_float($sx) && !is_int($sx) || !is_finite((float) $sx) || !is_finite((float) $sz)) {
                violation('a planting has no finite spot', [$route, $p['seed']]);
                continue;
            }
            $spots[] = [(float) $sx, (float) $sz, $p['seed']];
            $reach[] = hypot((float) $sx, (float) $sz);
            if (($p['parents'] ?? []) !== []) $got[] = $p['seed'];   // an ambassador has none, and is not a row
        }
        sort($want);
        sort($got);
        if ($want !== $got) violation('a plot disagrees with the database', [$route, $plot, count($got), count($want)]);
        $counts[] = count($spots);
        for ($i = 0; $i < count($spots); $i++) {
            for ($j = $i + 1; $j < count($spots); $j++) {
                $d = hypot($spots[$i][0] - $spots[$j][0], $spots[$i][1] - $spots[$j][1]);
                $closest = min($closest, $d);
                if ($d < 0.05) violation('two plantings stand within 5 cm of each other', [$route, $plot, $spots[$i][2], $spots[$j][2], round($d, 4)]);
            }
        }
    }
    sort($bytes);
    sort($ms);
    sort($reach);
    $facts['areas'][$area] = [
        'rows' => $facts['rows'][$table], 'plots' => $plots, 'plot_bytes_max' => end($bytes) ?: 0,
        'plot_ms_median' => $ms ? round($ms[intdiv(count($ms), 2)], 1) : null, 'plot_ms_max' => $ms ? round(end($ms), 1) : null,
        'plantings_per_plot_max' => $counts ? max($counts) : 0, 'closest_pair_m' => is_finite($closest) ? round($closest, 3) : null,
        'reach_m_max' => $reach ? round(end($reach), 2) : null, 'count_json_bytes' => $head['bytes'],
    ];
}

// MARK: - Sizes

$facts['database_bytes'] = (int) $rows('SELECT SUM(data_length + index_length) AS n FROM information_schema.tables WHERE table_schema = ?', [$db])[0]['n'];
$facts['tables'] = $rows('SELECT table_name, table_rows, data_length + index_length AS bytes FROM information_schema.tables
                          WHERE table_schema = ? ORDER BY bytes DESC LIMIT 8', [$db]);

$report = ['db' => $db, 'checked_at' => gmdate('c'), 'violations' => $violations, 'facts' => $facts];
file_put_contents("$out/invariants.json", json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
echo json_encode(['violations' => array_map(fn ($v) => $v['count'], $violations), 'wild' => $facts['wild'],
                  'offers' => $facts['offers']], JSON_UNESCAPED_SLASHES), "\n";
exit($violations === [] ? 0 : 1);
