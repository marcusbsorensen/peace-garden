<?php
declare(strict_types=1);

/**
 * The rehearsal's second opinion: a replanted garden is the garden this
 * checkout's service would have grown had every plant arrived with its new
 * shape in the first place.
 *
 *   php tools/replant/Rehearsal/replay.php <replanted dsn> <empty dsn> [user] [password]
 *
 * `replant.php` places every planting with the areas' bare rules and holds
 * them to SeedCore's places. This goes the other way round, through the
 * stores, the path an arrival takes on the live service: every planting in the
 * replanted garden is planted again, in arrival order, into an empty database
 * by `WalkStore::plantInto`, with the traits the replant wrote. Every place and
 * every nudge has to come back the same. Nothing here reads the plan.
 */

require_once __DIR__ . '/../../../Server/.api/WalkStore.php';
require_once __DIR__ . '/../../../Server/.api/replant.php';

// The replanted garden is read with a bare connection, and only the fresh one
// is opened as a store: `WalkStore` keeps each area's store in a static, one
// for the process, so a second `WalkStore::open` would hand back the first's.
$replanted = new PDO($argv[1] ?? '', $argv[3] ?? null, $argv[4] ?? null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$fresh = WalkStore::open($argv[2] ?? '', $argv[3] ?? null, $argv[4] ?? null);

$checks = 0;
$wrong = 0;
foreach (AREAS as $table => $spec) {
    $rows = $replanted->query("SELECT * FROM $table ORDER BY arrival")->fetchAll(PDO::FETCH_ASSOC);
    foreach ($rows as $row) {
        $fresh->plantInto($spec['area'], (string) $row['seed'], (string) $row['parent_a'],
            (string) $row['parent_b'], (string) $row['encounter'], (float) $row['height'], (int) $row['family'],
            (string) ($row['kind'] ?? ''), isset($row['hue']) ? (float) $row['hue'] : null,
            (string) ($row['habit'] ?? ''));
    }
    $again = $fresh->connection()->query("SELECT * FROM $table ORDER BY arrival")->fetchAll(PDO::FETCH_ASSOC);
    foreach ($rows as $i => $row) {
        $other = $again[$i] ?? null;
        $columns = array_merge(['seed', 'plot'], array_values($spec['slot']));
        foreach ($columns as $column) {
            $checks++;
            if ($other === null || (string) $other[$column] !== (string) $row[$column]) {
                $wrong++;
                printf("  %s arrival %d: %s is %s replanted and %s grown fresh\n", $table, $row['arrival'], $column,
                    $row[$column], $other[$column] ?? 'missing');
            }
        }
        foreach (['nudge_x', 'nudge_z', 'height'] as $column) {
            $checks++;
            if ($other === null || !near((float) $other[$column], (float) $row[$column])) {
                $wrong++;
                printf("  %s arrival %d: %s differs\n", $table, $row['arrival'], $column);
            }
        }
    }
}
if ($wrong === 0) {
    printf("Grown fresh through the stores, the garden comes out as replanted: %d checks.\n", $checks);
    exit(0);
}
printf("The replanted garden is not what the stores grow: %d of %d checks.\n", $wrong, $checks);
exit(1);
