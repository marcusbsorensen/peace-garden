<?php
declare(strict_types=1);

/**
 * The replant: every area's plantings placed again, in the order they arrived,
 * by the plants' new shapes.
 *
 *   php replant.php <plan.json> --dry-run   check everything, write nothing, say what would change
 *   php replant.php <plan.json>             the same, then write it
 *   php replant.php <plan.json> --verify    say whether the garden is what the plan left
 *
 * **Why there is a plan at all.** A planting's place is decided by the heights
 * of the plants, and a height is a grown plant's, which only SeedCore can grow.
 * The server cannot, so the heights are grown on the Mac from a copy of this
 * database (`tools/replant`), written into a plan with the place each area's
 * rule gives every planting, and carried here. This then does the placing
 * again itself, with the area's own PHP rule, and **refuses to write a table
 * whose places come out any differently from the plan's**: the port and
 * SeedCore have to agree about every planting, as the vector files make them
 * agree about five hundred.
 *
 * **What it refuses, and why each is a refusal rather than a warning:**
 * - a plan whose digest does not match its contents: edited, or cut short;
 * - a plan already run here (`replant_log`): so running it twice, or running
 *   it again after a restore, does nothing;
 * - a table that is not the table the copy was taken of — a planting since,
 *   or an offer made, answered or withdrawn since. The plan's heights are for
 *   the plants the copy held, and a plant it never saw would be placed with
 *   no height at all. Take a fresh copy, make a fresh plan.
 *
 * **One transaction**, with every area's lock row held first, so no arrival is
 * placed against a garden half replanted, and a failure anywhere leaves the
 * garden as it was. Everything is checked again inside it before it commits.
 *
 * **What happens to a planting taken back.** Its row is deleted. It kept its
 * place and the traits the rule reads only so that nothing placed after it
 * would move (`TakenBack.php`); on the one day every planting moves anyway,
 * that reason is gone, and the traits it kept were measured on a plant that no
 * longer grows that shape, so as a stand-in it would steer the plants around
 * it by the height of something that no longer exists. The gardener asked for
 * the plant to be gone, and this is the day it can be gone entirely. The
 * arrival numbers of the rest are kept, so the order is the order it was.
 *
 * Run it from a shell on the server, after `tools/backup.sh` and after the
 * deploy that carries the new shapes; tools/replant/README.md is the runbook.
 */

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/WalkStore.php';
require_once __DIR__ . '/backup.php';   // configuration(), and nothing it runs

const FORMAT = 'peace-garden-replant/1';

/**
 * Every area's table: its area, its rule, and the rule's slot fields against
 * the columns they are stored in. `extra` is the one trait beyond height and
 * family the rule is handed, where it is handed one.
 *
 * `derived` is a part of the place that is a word rather than a number, and so
 * not in the plan's places: the Home Ground's crop, which the rule reads off
 * the habit and nothing else (`HomeGround::crop`). The plan carries the habit,
 * so it carries the crop; it is written from the PHP rule's answer and checked
 * against the habit.
 */
const AREAS = [
    'long_walk' => ['area' => 'travel', 'rule' => 'LongWalk', 'extra' => null,
                    'slot' => ['side' => 'side', 'tier' => 'tier', 'index' => 'slot_index']],
    'quiet_garden' => ['area' => 'peace', 'rule' => 'QuietGarden', 'extra' => null,
                       'slot' => ['corner' => 'corner', 'index' => 'slot_index']],
    'crossing' => ['area' => 'meeting', 'rule' => 'Crossing', 'extra' => null,
                   'slot' => ['quarter' => 'quarter', 'index' => 'slot_index']],
    'orchard' => ['area' => 'kinship', 'rule' => 'Orchard', 'extra' => null,
                  'slot' => ['guild' => 'guild', 'index' => 'slot_index']],
    'knot_garden' => ['area' => 'pattern', 'rule' => 'KnotGarden', 'extra' => null,
                      'slot' => ['compartment' => 'compartment', 'index' => 'slot_index']],
    'seedbed' => ['area' => 'beginnings', 'rule' => 'Seedbed', 'extra' => 'kind',
                  'slot' => ['drill' => 'drill', 'index' => 'slot_index']],
    'cold_frame' => ['area' => 'waiting', 'rule' => 'ColdFrame', 'extra' => null,
                     'slot' => ['frame' => 'frame', 'rank' => 'slot_rank', 'index' => 'slot_index']],
    'glasshouse' => ['area' => 'light', 'rule' => 'Glasshouse', 'extra' => 'hue',
                     'slot' => ['bed' => 'bed', 'index' => 'slot_index', 'row' => 'slot_row']],
    'coppice' => ['area' => 'renewal', 'rule' => 'Coppice', 'extra' => 'habit',
                  'slot' => ['coupe' => 'coupe', 'place' => 'place', 'index' => 'slot_index']],
    'home_ground' => ['area' => 'ground', 'rule' => 'HomeGround', 'extra' => 'habit',
                      'slot' => ['bed' => 'bed', 'index' => 'slot_index'], 'derived' => ['crop' => 'crop']],
];

if (realpath((string) ($argv[0] ?? '')) === __FILE__) {
    exit(replant($argv));
}

function replant(array $argv): int
{
    $path = $argv[1] ?? '';
    $mode = $argv[2] ?? 'write';
    if ($path === '' || !in_array($mode, ['write', '--dry-run', '--verify'], true)) {
        fwrite(STDERR, "usage: php replant.php <plan.json> [--dry-run|--verify]\n");
        return 2;
    }
    try {
        $plan = readPlan($path);
        $config = configuration();
        $store = WalkStore::open($config['dsn'], $config['user'] ?? null, $config['password'] ?? null);
        $db = $store->connection();
        $db->prepare('CREATE TABLE IF NOT EXISTS replant_log (
            plan CHAR(64) NOT NULL PRIMARY KEY,
            replanted_at BIGINT NOT NULL,
            summary TEXT NOT NULL
        )')->execute();

        if ($mode === '--verify') {
            $wrong = verify($db, $plan);
            if ($wrong === []) {
                printf("The garden is what plan %s left: %s.\n", substr($plan['id'], 0, 12), counted($plan));
                return 0;
            }
            foreach (array_slice($wrong, 0, 20) as $line) echo "  $line\n";
            printf("The garden is not what plan %s left: %d differences.\n", substr($plan['id'], 0, 12), count($wrong));
            return 1;
        }

        $done = $db->prepare('SELECT replanted_at FROM replant_log WHERE plan = ?');
        $done->execute([$plan['id']]);
        if (($at = $done->fetchColumn()) !== false) {
            throw new RuntimeException(sprintf('plan %s was run here at %s; it runs once',
                substr($plan['id'], 0, 12), gmdate('Y-m-d H:i:s', (int) $at)));
        }

        $db->beginTransaction();
        try {
            // Every lock row first, in one order, as each area's own arrival
            // takes its own: nothing is placed while this runs.
            foreach (array_keys(AREAS) as $table) {
                $db->prepare("UPDATE {$table}_lock SET arrivals = arrivals WHERE id = 1")->execute();
            }
            matches($db, $plan);
            $said = write($db, $plan);
            $wrong = verify($db, $plan);
            if ($wrong !== []) {
                throw new RuntimeException("the garden written is not the plan's:\n  " . implode("\n  ", array_slice($wrong, 0, 20)));
            }
            $db->prepare('INSERT INTO replant_log (plan, replanted_at, summary) VALUES (?, ?, ?)')
               ->execute([$plan['id'], time(), implode('; ', $said)]);
            if ($mode === '--dry-run') {
                $db->rollBack();
                echo "Nothing written. Plan " . substr($plan['id'], 0, 12) . " would:\n";
            } else {
                $db->commit();
                echo "Replanted, plan " . substr($plan['id'], 0, 12) . ":\n";
            }
            foreach ($said as $line) echo "  $line\n";
            return 0;
        } catch (Throwable $trouble) {
            if ($db->inTransaction()) $db->rollBack();
            throw $trouble;
        }
    } catch (Throwable $trouble) {
        fwrite(STDERR, "replant: nothing written: " . $trouble->getMessage() . "\n");
        return 1;
    }
}

// MARK: The plan

/** The plan, read and checked against its own digest. */
function readPlan(string $path): array
{
    $plan = json_decode((string) file_get_contents($path), true, 64, JSON_THROW_ON_ERROR);
    if (($plan['format'] ?? '') !== FORMAT) {
        throw new RuntimeException("not a replant plan of this format ($path)");
    }
    foreach ($plan['tables'] as $table) {
        if (!isset(AREAS[$table['table']])) throw new RuntimeException("the plan names a table this does not know: {$table['table']}");
        foreach ($table['plantings'] as $p) {
            if (bits((float) $p['height']) !== $p['heightBits']) {
                throw new RuntimeException("{$table['table']} {$p['arrival']}: the height is not the height the plan was made with");
            }
        }
    }
    if (identity($plan) !== $plan['id']) {
        throw new RuntimeException('the plan does not match its own digest: edited, or cut short');
    }
    return $plan;
}

/** tools/replant's `Planner.identity`, line for line. */
function identity(array $plan): string
{
    $lines = FORMAT . "\n" . $plan['copy']['sha256'] . "\n";
    foreach ($plan['tables'] as $t) {
        $b = $t['before'];
        $lines .= "{$t['table']} before {$b['rows']} {$b['last']} {$b['sha256']}\n";
        foreach ($t['plantings'] as $p) {
            $hue = $p['hue'] === null ? '-' : bits((float) $p['hue']);
            $lines .= "{$t['table']} {$p['arrival']} {$p['seed']} {$p['heightBits']} {$p['family']} {$p['kind']} $hue {$p['habit']}";
            $keys = array_keys($p['place']);
            sort($keys, SORT_STRING);
            foreach ($keys as $key) $lines .= " $key=" . bits((float) $p['place'][$key]);
            $lines .= "\n";
        }
        foreach ($t['takenBack'] as $arrival) $lines .= "{$t['table']} $arrival taken back\n";
    }
    $b = $plan['offers']['before'];
    $lines .= "walk_offers before {$b['rows']} {$b['last']} {$b['sha256']}\n";
    foreach ($plan['offers']['pending'] as $o) {
        $hue = $o['hue'] === null ? '-' : bits((float) $o['hue']);
        $lines .= "walk_offers {$o['offer']} {$o['seedSha256']} {$o['heightBits']} {$o['family']} {$o['kind']} $hue {$o['habit']}\n";
    }
    return hash('sha256', $lines);
}

/** A double's bits, as the Swift writes them: sixteen hex digits, high byte first. */
function bits(float $value): string
{
    return bin2hex(pack('E', $value));
}

// MARK: The garden the plan was made from

/**
 * Every table is the table the copy was taken of: the same arrivals with the
 * same seeds, and the same offers waiting. A table the plan does not name
 * held nothing then, and must hold nothing now.
 */
function matches(PDO $db, array $plan): void
{
    $named = [];
    foreach ($plan['tables'] as $t) $named[$t['table']] = $t['before'];
    foreach (array_keys(AREAS) as $table) {
        $rows = $db->query("SELECT arrival, seed FROM $table ORDER BY arrival")->fetchAll(PDO::FETCH_ASSOC);
        $now = fingerprint($rows, 'arrival', false);
        $then = $named[$table] ?? ['rows' => 0, 'last' => 0, 'sha256' => hash('sha256', '')];
        if ($now !== [(int) $then['rows'], (int) $then['last'], $then['sha256']]) {
            throw new RuntimeException(sprintf('%s is not what the copy held (%d rows, last %d; the copy had %d, last %d). '
                . 'Something arrived or was taken back since. Take a fresh copy and make a fresh plan.',
                $table, $now[0], $now[1], $then['rows'], $then['last']));
        }
    }
    $waiting = $db->prepare('SELECT offer, seed FROM walk_offers WHERE state = ? ORDER BY offer');
    $waiting->execute([Offers::OFFERED]);
    $now = fingerprint($waiting->fetchAll(PDO::FETCH_ASSOC), 'offer', true);
    $then = $plan['offers']['before'];
    if ($now !== [(int) $then['rows'], (int) $then['last'], $then['sha256']]) {
        throw new RuntimeException(sprintf('the offers waiting are not the ones the copy held (%d now, %d then). '
            . 'Take a fresh copy and make a fresh plan.', $now[0], (int) $then['rows']));
    }
}

/** tools/replant's `Planner.fingerprint`. */
function fingerprint(array $rows, string $key, bool $digestSeed): array
{
    $lines = '';
    $last = 0;
    foreach ($rows as $row) {
        $number = (int) $row[$key];
        $last = max($last, $number);
        $seed = (string) $row['seed'];
        $lines .= $number . ' ' . ($digestSeed ? hash('sha256', $seed) : $seed) . "\n";
    }
    return [count($rows), $last, hash('sha256', $lines)];
}

// MARK: Replanting

/**
 * Places every planting again with its area's own rule, in arrival order, after
 * the ambassador as the store places them; refuses on the first place that is
 * not the plan's; writes each row's new place and traits; deletes the rows
 * taken back; grows the waiting offers' traits. Returns what it did, a line an
 * area.
 */
function write(PDO $db, array $plan): array
{
    $said = [];
    foreach ($plan['tables'] as $t) {
        $table = $t['table'];
        $spec = AREAS[$table];
        $rule = $spec['rule'];
        $ways = [Ambassadors::planting($spec['area'])];
        $sets = ['plot = ?'];
        foreach ($spec['slot'] as $column) $sets[] = "$column = ?";
        foreach ($spec['derived'] ?? [] as $column) $sets[] = "$column = ?";
        $sets[] = 'height = ?';
        $sets[] = 'family = ?';
        if ($spec['extra'] !== null) $sets[] = "{$spec['extra']} = ?";
        $sets[] = 'nudge_x = ?';
        $sets[] = 'nudge_z = ?';
        $update = $db->prepare("UPDATE $table SET " . implode(', ', $sets) . ' WHERE arrival = ? AND seed = ?');

        $moved = 0;
        $before = $db->query("SELECT * FROM $table ORDER BY arrival")->fetchAll(PDO::FETCH_ASSOC);
        $was = [];
        foreach ($before as $row) $was[(int) $row['arrival']] = $row;
        foreach ($t['plantings'] as $p) {
            $seed = (string) $p['seed'];
            $height = (float) $p['height'];
            $family = (int) $p['family'];
            $extra = match ($spec['extra']) {
                'kind' => (string) $p['kind'],
                'hue' => $p['hue'] === null ? null : (float) $p['hue'],
                'habit' => (string) $p['habit'],
                default => null,
            };
            $placed = $spec['extra'] === null
                ? $rule::plant($ways, $seed, $height, $family)
                : $rule::plant($ways, $seed, $height, $family, $extra);
            foreach ($p['place'] as $key => $want) {
                if (abs((float) $placed[$key] - (float) $want) > 1e-12) {
                    throw new RuntimeException(sprintf('%s arrival %d: the PHP rule puts it at %s %s where SeedCore puts it at %s. '
                        . 'The port and SeedCore disagree; nothing is written.',
                        $table, $p['arrival'], $key, var_export($placed[$key], true), var_export($want, true)));
                }
            }
            $ways[] = $placed;

            $row = $was[(int) $p['arrival']] ?? null;
            if ($row === null || (string) $row['seed'] !== $seed) {
                throw new RuntimeException("$table arrival {$p['arrival']} is not the planting the plan names");
            }
            if ((int) $row['plot'] !== (int) $placed['plot']) $moved++;
            else foreach ($spec['slot'] as $key => $column) {
                if ((int) $row[$column] !== (int) $placed[$key]) { $moved++; break; }
            }
            foreach ($spec['derived'] ?? [] as $key => $column) {
                if ((string) $row[$column] !== (string) $placed[$key]) { $moved++; break; }
            }

            $values = [(int) $placed['plot']];
            foreach (array_keys($spec['slot']) as $key) $values[] = (int) $placed[$key];
            foreach (array_keys($spec['derived'] ?? []) as $key) $values[] = (string) $placed[$key];
            // Heights and hues bound as the shortest text that reads back as
            // the same double: PDO binds a float at fourteen digits
            // (`GlasshouseStore::exactly`), and a height is compared with a cut.
            $values[] = GlasshouseStore::exactly($height);
            $values[] = $family;
            if ($spec['extra'] === 'hue') $values[] = GlasshouseStore::exactly($extra);
            elseif ($spec['extra'] !== null) $values[] = $extra;
            $values[] = GlasshouseStore::exactly((float) $placed['nudgeX']);
            $values[] = GlasshouseStore::exactly((float) $placed['nudgeZ']);
            $values[] = (int) $p['arrival'];
            $values[] = $seed;
            $update->execute($values);
        }

        $gone = $db->prepare("DELETE FROM $table WHERE arrival = ? AND hidden = 1");
        foreach ($t['takenBack'] as $arrival) {
            $gone->execute([(int) $arrival]);
            if ($gone->rowCount() !== 1) {
                throw new RuntimeException("$table arrival $arrival is not a planting taken back");
            }
        }
        $said[] = sprintf('%s: %d replanted, %d moved, %d taken back removed, plots %d -> %d',
            $table, count($t['plantings']), $moved, count($t['takenBack']),
            (int) $t['plotsBefore'], (int) $t['plotsAfter']);
    }

    $offer = $db->prepare('UPDATE walk_offers SET height = ?, family = ?, kind = ?, hue = ?, habit = ?
                           WHERE offer = ? AND state = ?');
    $find = $db->prepare('SELECT seed FROM walk_offers WHERE offer = ? AND state = ?');
    foreach ($plan['offers']['pending'] as $o) {
        $find->execute([(int) $o['offer'], Offers::OFFERED]);
        if (hash('sha256', (string) $find->fetchColumn()) !== $o['seedSha256']) {
            throw new RuntimeException("offer {$o['offer']} is not the offer the plan names");
        }
        $offer->execute([GlasshouseStore::exactly((float) $o['height']), (int) $o['family'], (string) $o['kind'],
                         $o['hue'] === null ? null : GlasshouseStore::exactly((float) $o['hue']),
                         (string) $o['habit'], (int) $o['offer'], Offers::OFFERED]);
    }
    $said[] = sprintf('walk_offers: %d waiting, grown again', count($plan['offers']['pending']));
    return $said;
}

// MARK: Checking what was written

/**
 * Every difference between the garden and what the plan leaves, as lines; none
 * is the answer wanted. Read back rather than trusted, since an UPDATE that
 * changes nothing reports no rows on MariaDB and so cannot say it matched.
 */
function verify(PDO $db, array $plan): array
{
    $wrong = [];
    $named = [];
    foreach ($plan['tables'] as $t) $named[$t['table']] = $t;
    foreach (AREAS as $table => $spec) {
        $rows = $db->query("SELECT * FROM $table ORDER BY arrival")->fetchAll(PDO::FETCH_ASSOC);
        $t = $named[$table] ?? ['plantings' => [], 'takenBack' => []];
        if (count($rows) !== count($t['plantings'])) {
            $wrong[] = sprintf('%s holds %d rows where the plan leaves %d', $table, count($rows), count($t['plantings']));
            continue;
        }
        foreach ($t['plantings'] as $i => $p) {
            $row = $rows[$i];
            $at = "$table arrival {$p['arrival']}";
            if ((int) $row['arrival'] !== (int) $p['arrival'] || (string) $row['seed'] !== (string) $p['seed']) {
                $wrong[] = "$at is not in its place in the order";
                continue;
            }
            if ((int) $row['hidden'] !== 0) $wrong[] = "$at is hidden";
            if ((int) $row['plot'] !== (int) $p['place']['plot']) $wrong[] = "$at is in plot {$row['plot']}";
            foreach ($spec['slot'] as $key => $column) {
                if ((int) $row[$column] !== (int) $p['place'][$key]) $wrong[] = "$at has $column {$row[$column]}";
            }
            if (!near((float) $row['height'], (float) $p['height'])) $wrong[] = "$at is {$row['height']} m tall";
            if ((int) $row['family'] !== (int) $p['family']) $wrong[] = "$at is family {$row['family']}";
            if ($spec['extra'] === 'kind' && (string) $row['kind'] !== (string) $p['kind']) $wrong[] = "$at is kind {$row['kind']}";
            if ($spec['extra'] === 'habit' && (string) $row['habit'] !== (string) $p['habit']) $wrong[] = "$at is habit {$row['habit']}";
            if (isset($spec['derived']['crop']) && (string) $row['crop'] !== HomeGround::crop((string) $p['habit'])) {
                $wrong[] = "$at is sown with {$row['crop']}";
            }
            if ($spec['extra'] === 'hue' && ($row['hue'] === null) !== ($p['hue'] === null)) $wrong[] = "$at has hue {$row['hue']}";
            if ($spec['extra'] === 'hue' && $row['hue'] !== null && $p['hue'] !== null && !near((float) $row['hue'], (float) $p['hue'])) {
                $wrong[] = "$at has hue {$row['hue']}";
            }
            if (!near((float) $row['nudge_x'], (float) $p['place']['nudgeX'])
                || !near((float) $row['nudge_z'], (float) $p['place']['nudgeZ'])) {
                $wrong[] = "$at is nudged differently";
            }
        }
    }
    $find = $db->prepare('SELECT * FROM walk_offers WHERE offer = ?');
    foreach ($plan['offers']['pending'] as $o) {
        $find->execute([(int) $o['offer']]);
        $row = $find->fetch(PDO::FETCH_ASSOC);
        // An offer answered or withdrawn since is no longer the replant's.
        if ($row === false || $row['state'] !== Offers::OFFERED) continue;
        if (!near((float) $row['height'], (float) $o['height']) || (int) $row['family'] !== (int) $o['family']
            || (string) $row['kind'] !== (string) $o['kind'] || (string) $row['habit'] !== (string) $o['habit']) {
            $wrong[] = "offer {$o['offer']} was not grown again";
        }
    }
    return $wrong;
}

/**
 * The same double, give or take what a database's text protocol does to the
 * last digit: a part in a million million, which is a thousand times finer
 * than the finest thing any rule decides.
 */
function near(float $a, float $b): bool
{
    return abs($a - $b) <= 1e-12 * max(1.0, abs($a), abs($b));
}

function counted(array $plan): string
{
    $plantings = 0;
    foreach ($plan['tables'] as $t) $plantings += count($t['plantings']);
    return sprintf('%d plantings in %d areas, %d offers waiting', $plantings, count($plan['tables']),
        count($plan['offers']['pending']));
}
