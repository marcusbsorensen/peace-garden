<?php
declare(strict_types=1);

/**
 * The Wild Fields: a released plant stands where SeedCore says, keeps nothing
 * about who let it go, and stands in one public place.
 *
 * Run: php tools/reference/check_wild_fields.php
 *
 * Three things, each of which could rot without anything else noticing:
 *
 *   - **The place is SeedCore's.** `wild_fields_vectors.json` is what
 *     `WildFields.spot` makes of three hundred and four seeds, the four
 *     corners of the byte space among them; `Server/.api/WildFields.php` has to
 *     make exactly the same of each, with no tolerance, because every place is
 *     a whole number of 1/1024ths of a metre.
 *   - **The field keeps the plant and nothing else.** No time, no meeting, no
 *     token, no order of arrival — the last checked on SQLite, whose hidden row
 *     number would otherwise count arrivals for us.
 *   - **Release and the asking agree.** A plant the asking has never held goes
 *     without a token; one it has held goes only on one of its two tokens, and
 *     is taken out of its area as it goes; and a released plant cannot then be
 *     offered to any area.
 *
 * It drives the classes over a throwaway SQLite file rather than HTTP, as
 * `check_offers.php` does, so it says which step broke.
 */

require_once __DIR__ . '/../../Server/.api/Seeds.php';
require_once __DIR__ . '/../../Server/.api/Limits.php';
require_once __DIR__ . '/../../Server/.api/WalkStore.php';
require_once __DIR__ . '/../../Server/.api/WildFields.php';

$failures = 0;
function check(string $what, bool $held): void
{
    global $failures;
    if (!$held) { $failures++; fwrite(STDERR, "FAILED  $what\n"); }
    else fwrite(STDOUT, "ok      $what\n");
}

// MARK: The place is SeedCore's

$vectors = json_decode(file_get_contents(__DIR__ . '/wild_fields_vectors.json'), true, 512, JSON_THROW_ON_ERROR);
$wrong = [];
foreach ($vectors as $want) {
    $spot = WildFields::spot($want['seed']);
    $tile = WildFields::tile($want['seed']);
    if ($spot !== [(float) $want['spot'][0], (float) $want['spot'][1]] || $tile !== $want['tile']) {
        $wrong[] = sprintf('%s: SeedCore %s / %s, the service %s / %s', substr($want['seed'], 0, 12),
                           json_encode($want['spot']), json_encode($want['tile']),
                           json_encode($spot), json_encode($tile));
    }
}
check(sprintf('the service places all %d recorded seeds where SeedCore does%s', count($vectors),
              $wrong === [] ? '' : ': ' . implode('; ', array_slice($wrong, 0, 3))), $wrong === []);
check('the vectors reach every corner of the field',
      in_array([0, 0], array_column($vectors, 'tile'), true)
      && in_array([7, 7], array_column($vectors, 'tile'), true));
check('the field is eight tiles of eight metres each way',
      WildFields::TILES * WildFields::TILE === WildFields::SIDE && WildFields::TILES === 8);

// MARK: A field with something in it

$file = sys_get_temp_dir() . '/peacegarden-wild-' . getmypid() . '.sqlite';
@unlink($file);
$walk = WalkStore::open('sqlite:' . $file);
$db = $walk->connection();
$wild = $walk->wild();
$offers = $walk->offers();
$now = 1_700_000_000;

function crossing(int $n): array
{
    $a = hash('sha256', "wild parent a $n");
    $b = hash('sha256', "wild parent b $n");
    $encounter = hash('sha256', "wild meeting $n");
    return ['seed' => Seeds::cross($a, $b, $encounter), 'a' => $a, 'b' => $b, 'encounter' => $encounter];
}

function token(string $of): string { return substr(hash('sha256', $of), 0, 32); }

/** Every value of every row of every table, searched for these strings. As `check_offers.php`. */
function stillHeld(PDO $db, array $needles): array
{
    $found = [];
    $tables = $db->query("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'")
                 ->fetchAll(PDO::FETCH_COLUMN);
    foreach ($tables as $table) {
        foreach ($db->query("SELECT * FROM $table")->fetchAll(PDO::FETCH_ASSOC) as $row) {
            foreach ($row as $column => $value) {
                foreach ($needles as $what => $needle) {
                    if (is_string($value) && str_contains($value, $needle)) $found[] = "$what in $table.$column";
                }
            }
        }
    }
    return $found;
}

// MARK: Releasing

$one = crossing(1);
check('a plant the asking has never held may go, with no token', $offers->letGo($one['seed'], null, $now));
[$planting, $new] = $wild->release($one['seed'], $one['a'], $one['b']);
check('a release is new the first time', $new === true);
check('and stands where its seed says', $planting['spot'] === WildFields::spot($one['seed']));
check('and carries what a browser grows a hybrid from', $planting['seed'] === $one['seed']
      && $planting['parents'] === [$one['a'], $one['b']]);
check('and nothing else', array_keys($planting) === ['seed', 'parents', 'spot']);

[$again, $twice] = $wild->release($one['seed'], $one['a'], $one['b']);
check('releasing it twice is the first release', $twice === false && $again === $planting);
check('and the field holds it once',
      (int) $db->query('SELECT COUNT(*) FROM wild_fields')->fetchColumn() === 1);

[$tx, $tz] = WildFields::tile($one['seed']);
check('its tile has it', array_column($wild->tile($tx, $tz), 'seed') === [$one['seed']]);
check('the tile beside it does not', $wild->tile(($tx + 1) % 8, $tz) === []);
check('the field says one plant stands in that tile', $wild->standing() === [[$tx, $tz, 1]]);

// MARK: What the field keeps

$columns = array_column($db->query('PRAGMA table_info(wild_fields)')->fetchAll(PDO::FETCH_ASSOC), 'name');
check('a row is the plant, its parents and where it is, and nothing else: ' . implode(', ', $columns),
      $columns === ['seed', 'parent_a', 'parent_b', 'tile_x', 'tile_z', 'hidden']);
$rowid = true;
try {
    $db->query('SELECT rowid FROM wild_fields')->fetchAll();
} catch (PDOException) {
    $rowid = false;
}
check('and SQLite keeps no hidden row number that would count arrivals', $rowid === false);
check('the meeting it was checked against is kept nowhere',
      stillHeld($db, ['the meeting' => $one['encounter']]) === []);

// Two at one place is two plants at one place, both drawn. Seeds that share
// their first four bytes are one pair in four billion, so the collision is
// made rather than found: two seeds that agree that far and no further.
$shared = '0102030405' . str_repeat('a', 59);
$beside = '0102030405' . str_repeat('b', 59);
$wild->release($shared, str_repeat('c', 64), str_repeat('d', 64));
$wild->release($beside, str_repeat('e', 64), str_repeat('f', 64));
[$cx, $cz] = WildFields::tile($shared);
$there = $wild->tile($cx, $cz);
check('two plants whose seeds put them in one place both stand there',
      count($there) === 2 && $there[0]['spot'] === $there[1]['spot']);

// MARK: Release and the asking

// Offered, and still waiting. The meeting's own token takes it out of the
// asking and into the field; no token, or somebody else's, does not.
$two = crossing(2);
$mine = token('two/mine');
$theirs = token('two/theirs');
$offers->offer($two['seed'], $theirs, $mine, $two['a'], $two['b'], $two['encounter'], 1.0, 1, $now);
check('a plant in the asking does not go without a token', $offers->letGo($two['seed'], null, $now) === false);
check('nor on a token that is not one of its two',
      $offers->letGo($two['seed'], token('somebody else'), $now) === false);
check('it goes on either of its own', $offers->letGo($two['seed'], $theirs, $now) === true);
$seen = $offers->touching([$mine], $now);
check('and the offer is withdrawn, which the other phone hears',
      count($seen) === 1 && $seen[0]['state'] === Offers::WITHDRAWN);

// Accepted, and standing in the Long Walk. Released, it is taken back out of
// the walk — a plant stands in one public place.
$three = crossing(3);
$a3 = token('three/a');
$b3 = token('three/b');
$offers->offer($three['seed'], $b3, $a3, $three['a'], $three['b'], $three['encounter'], 1.2, 2, $now);
$offers->answer($three['seed'], $b3, true, $now);
$standingIn = fn () => array_column(array_filter($walk->plot(0), fn ($p) => count($p['parents']) === 2), 'seed');
check('a plant standing in the walk is there before it is released', in_array($three['seed'], $standingIn(), true));
check('its token lets it go', $offers->letGo($three['seed'], $a3, $now) === true);
$wild->release($three['seed'], $three['a'], $three['b']);
check('and it is no longer in the walk', !in_array($three['seed'], $standingIn(), true));
check('but in the field', $wild->find($three['seed']) !== null);

// Once in the field, no area can be offered it — by either gardener, on the
// pair that met.
[$refused, $made] = $offers->offer($three['seed'], $b3, $a3, $three['a'], $three['b'], $three['encounter'],
                                   1.2, 2, $now + 60);
check('a released plant cannot then be offered to an area', $refused === false && $made === false);
$four = crossing(4);
$wild->release($four['seed'], $four['a'], $four['b']);
[$refused] = $offers->offer($four['seed'], token('four/b'), token('four/a'), $four['a'], $four['b'],
                            $four['encounter'], 1.0, 0, $now);
check('nor one released before it was ever offered', $refused === false);

// Withdrawn long ago: its seed, parents and meeting were public while it
// stood, so a stranger who read them cannot stand it in the wild.
$five = crossing(5);
$a5 = token('five/a');
$b5 = token('five/b');
$offers->offer($five['seed'], $b5, $a5, $five['a'], $five['b'], $five['encounter'], 1.0, 0, $now);
$offers->answer($five['seed'], $b5, true, $now);
$offers->withdraw($five['seed'], $b5, $now);
check('a plant taken back out of the garden is not released by a stranger',
      $offers->letGo($five['seed'], null, $now) === false
      && $offers->letGo($five['seed'], token('a stranger'), $now) === false);
check('and is by either gardener', $offers->letGo($five['seed'], $a5, $now) === true);

// MARK: Hidden

$db->prepare('UPDATE wild_fields SET hidden = 1 WHERE seed = ?')->execute([$one['seed']]);
check('a hidden plant is not drawn', $wild->find($one['seed']) === null
      && !in_array($one['seed'], array_column($wild->tile($tx, $tz), 'seed'), true));
check('and is still held, so it is not released again', $wild->holds($one['seed']));
[$back, $fresh] = $wild->release($one['seed'], $one['a'], $one['b']);
check('releasing it again does not bring it back', $fresh === false
      && (int) $db->query("SELECT hidden FROM wild_fields WHERE seed = '{$one['seed']}'")->fetchColumn() === 1);

// MARK: The limit

check('release is limited, and is the tightest write',
      isset(Limits::ROUTES['/api/wild/release'])
      && Limits::ROUTES['/api/wild/release'][0] <= min(array_column(Limits::ROUTES, 0)));

unset($walk, $db, $wild, $offers);
@unlink($file);

fwrite(STDOUT, $failures === 0 ? "\nThe Wild Fields hold.\n" : "\n$failures failed.\n");
exit($failures === 0 ? 0 : 1);
