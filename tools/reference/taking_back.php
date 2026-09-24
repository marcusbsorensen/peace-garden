<?php
declare(strict_types=1);

/**
 * Taking back, held to the rule: every area's check ends here.
 *
 * **What it proves.** A planting taken back is erased — its seed, parents,
 * meeting and nudge leave the database — and every plant that arrives after it
 * stands exactly where it would have stood had nobody taken anything back. The
 * second half is the one that can fail quietly. The rules read the plants
 * already standing, hidden ones included, and a placeholder that kept too
 * little (a blanked height, a blanked colour claim, a blanked kind) would move
 * the next plant, and every plant after it, without a single number looking
 * wrong on its own.
 *
 * **How.** The area's first arrivals from its vector file are sown twice, into
 * two throwaway databases through the area's real store. Into one, nothing is
 * taken back. Into the other, plantings are taken back as the sowing goes — some
 * at once, some several arrivals later — and a few are hidden the way the code
 * before 24 September hid them and then erased by the migration, as a deploy
 * would. Then every row is compared: the place of every planting must be the
 * same in both, a planting not taken back must be the same in every column,
 * and one taken back must keep exactly what the rule reads and nothing else.
 *
 *   takingBack('peace', $vectors);   // from the end of check_quiet_garden.php
 */

require_once __DIR__ . '/../../Server/.api/WalkStore.php';

/** Per area: the store, its table, the columns that are its place, and what a placeholder keeps besides. */
const TAKING_BACK = [
    'travel' => ['long_walk', ['plot', 'side', 'tier', 'slot_index'], ['height', 'family'], []],
    'peace' => ['quiet_garden', ['plot', 'corner', 'slot_index'], ['height', 'family'], []],
    'meeting' => ['crossing', ['plot', 'quarter', 'slot_index'], ['height'], ['family' => 0]],
    'kinship' => ['orchard', ['plot', 'guild', 'slot_index'], ['height'], ['family' => 0]],
    'pattern' => ['knot_garden', ['plot', 'compartment', 'slot_index'], ['height', 'family'], []],
    'beginnings' => ['seedbed', ['plot', 'drill', 'slot_index'], ['kind'], ['height' => 0.0, 'family' => 0]],
    'waiting' => ['cold_frame', ['plot', 'frame', 'slot_rank', 'slot_index'], ['height', 'family'], []],
    'light' => ['glasshouse', ['plot', 'bed', 'slot_index', 'slot_row'], [],
                ['height' => 0.0, 'family' => 0, 'hue' => null]],
    'renewal' => ['coppice', ['plot', 'coupe', 'place', 'slot_index'], ['height', 'habit'], ['family' => 0]],
    'ground' => ['home_ground', ['plot', 'bed', 'crop', 'slot_index'], [],
                 ['height' => 0.0, 'family' => 0, 'habit' => '']],
];

/**
 * The area's store over a database file, opened fresh — which is what runs its
 * migration. Built directly rather than through `WalkStore`, whose accessors
 * for the other areas hold one store per process.
 */
function takingBackStore(string $area, string $file): object
{
    if ($area === 'travel') return WalkStore::open('sqlite:' . $file);
    $db = new PDO('sqlite:' . $file, null, null, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_STRINGIFY_FETCHES => false,
    ]);
    return match ($area) {
        'peace' => new RoomStore($db),
        'meeting' => new CrossStore($db),
        'kinship' => new OrchardStore($db),
        'pattern' => new KnotStore($db),
        'beginnings' => new SeedbedStore($db),
        'waiting' => new ColdFrameStore($db),
        'light' => new GlasshouseStore($db),
        'renewal' => new CoppiceStore($db),
        'ground' => new HomeGroundStore($db),
    };
}

function takingBackRows(string $file, string $table): array
{
    $db = new PDO('sqlite:' . $file, null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    return $db->query("SELECT * FROM $table ORDER BY arrival")->fetchAll(PDO::FETCH_ASSOC);
}

function takingBack(string $area, array $vectors, int $count = 200): void
{
    [$table, $place, $kept, $blanked] = TAKING_BACK[$area];
    $arrivals = [];
    foreach (array_slice($vectors, 0, $count) as $n => $v) {
        $arrivals[] = [
            'seed' => $v['seed'],
            'a' => hash('sha256', "taking back, parent a $n"),
            'b' => hash('sha256', "taking back, parent b $n"),
            'encounter' => hash('sha256', "taking back, meeting $n"),
            'height' => (float) $v['height'], 'family' => (int) $v['family'], 'kind' => (string) ($v['kind'] ?? ''),
            'hue' => isset($v['hue']) ? (float) $v['hue'] : null,
            'habit' => (string) ($v['habit'] ?? ''),
        ];
    }

    $scratch = sys_get_temp_dir() . "/peacegarden-taking-back-$area-" . getmypid();
    $kept_file = "$scratch-kept.sqlite";
    $taken_file = "$scratch-taken.sqlite";
    @unlink($kept_file);
    @unlink($taken_file);

    $whole = takingBackStore($area, $kept_file);
    $lifted = takingBackStore($area, $taken_file);
    $taken = [];
    foreach ($arrivals as $n => $a) {
        // The hue is the Glasshouse's alone and the habit the Coppice's and the
        // Home Ground's; every other area's `plant` takes fewer arguments and PHP
        // lets the rest pass by unread.
        $whole->plant($a['seed'], $a['a'], $a['b'], $a['encounter'], $a['height'], $a['family'], $a['kind'],
                      $a['hue'], $a['habit']);
        $lifted->plant($a['seed'], $a['a'], $a['b'], $a['encounter'], $a['height'], $a['family'], $a['kind'],
                       $a['hue'], $a['habit']);

        // Taken back at once, now and then; taken back a few arrivals later,
        // now and then; and, less often, hidden the old way and erased by the
        // migration that runs when the store is next opened.
        if ($n % 7 === 3 && !isset($taken[$n])) {
            $lifted->takeBack($a['seed']);
            $taken[$n] = true;
        }
        if ($n % 9 === 5 && $n >= 4 && !isset($taken[$n - 4])) {
            $lifted->takeBack($arrivals[$n - 4]['seed']);
            $taken[$n - 4] = true;
        }
        if ($n % 23 === 11 && !isset($taken[$n - 1])) {
            $old = new PDO('sqlite:' . $taken_file);
            $old->prepare("UPDATE $table SET hidden = 1 WHERE seed = ?")->execute([$arrivals[$n - 1]['seed']]);
            unset($old);
            $taken[$n - 1] = true;
            $lifted = takingBackStore($area, $taken_file);
        }
    }
    unset($whole, $lifted);

    $wholeRows = takingBackRows($kept_file, $table);
    $liftedRows = takingBackRows($taken_file, $table);
    $failed = [];
    if (count($wholeRows) !== count($arrivals) || count($liftedRows) !== count($arrivals)) {
        $failed[] = sprintf('%d arrivals sown, %d and %d rows kept', count($arrivals), count($wholeRows), count($liftedRows));
    }

    foreach ($wholeRows as $i => $row) {
        $other = $liftedRows[$i] ?? null;
        if ($other === null) break;
        $label = sprintf('arrival %d (%s…)', $i, substr($arrivals[$i]['seed'], 0, 8));
        foreach ($place as $column) {
            if ($other[$column] !== $row[$column]) {
                $failed[] = "$label stands at $column {$other[$column]}, not {$row[$column]}";
            }
        }
        if (!isset($taken[$i])) {
            if ($other !== $row) $failed[] = "$label was not taken back and still changed";
            continue;
        }
        $expected = TakenBack::marker((int) $row['arrival']);
        if ($other['seed'] !== $expected) $failed[] = "$label kept seed {$other['seed']}";
        if ((int) $other['hidden'] !== 1) $failed[] = "$label is not hidden";
        foreach (['parent_a', 'parent_b', 'encounter'] as $column) {
            if ($other[$column] !== '') $failed[] = "$label kept its $column";
        }
        foreach (['nudge_x', 'nudge_z'] as $column) {
            if ((float) $other[$column] !== 0.0) $failed[] = "$label kept its $column";
        }
        foreach ($kept as $column) {
            if ($other[$column] !== $row[$column]) $failed[] = "$label lost its $column, which the rule reads";
        }
        foreach ($blanked as $column => $value) {
            $same = $value === null ? $other[$column] === null : $other[$column] == $value;
            if (!$same) $failed[] = "$label kept its $column, which the rule does not read";
        }
    }

    // And literally: none of the seeds, parents or meetings taken back is in
    // any column of any table of the database they were taken back from.
    $db = new PDO('sqlite:' . $taken_file, null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    $gone = [];
    foreach (array_keys($taken) as $n) {
        foreach (['seed', 'a', 'b', 'encounter'] as $field) $gone[] = $arrivals[$n][$field];
    }
    foreach ($db->query("SELECT name FROM sqlite_master WHERE type = 'table'")->fetchAll(PDO::FETCH_COLUMN) as $t) {
        foreach ($db->query("SELECT * FROM $t")->fetchAll(PDO::FETCH_ASSOC) as $row) {
            foreach ($row as $column => $value) {
                if (is_string($value) && in_array($value, $gone, true)) {
                    $failed[] = "something taken back is still in $t.$column";
                }
            }
        }
    }
    unset($db);
    @unlink($kept_file);
    @unlink($taken_file);

    if ($failed !== []) {
        fwrite(STDERR, sprintf("\nTaking back in %s moved or kept what it should not (%d):\n", $table, count($failed)));
        foreach (array_slice($failed, 0, 20) as $line) fwrite(STDERR, "  $line\n");
        exit(1);
    }
    printf("Taking back %d of %d plantings erases them, and every later arrival stands where it would have.\n",
        count($taken), count($arrivals));
}
