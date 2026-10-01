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

// MARK: Who stands beside it

// Marcus's decision of 1 October 2026: the releaser chooses as they let go,
// the other answers when told, either changes their answer at any time. A
// name is its owner's alone; the place and the month stand only once both
// chose the same. Nothing is kept that is not shown, but what lets each of
// the two answer for themselves.
$six = crossing(6);
$a6 = token('six/released');
$b6 = token('six/grown with');
$none = ['name' => null, 'place' => null, 'month' => null];
$wild->release($six['seed'], $six['a'], $six['b']);
$told = $wild->beside($six['seed'], $a6, $b6,
                      ['name' => 'Wren', 'place' => 'On the winds', 'month' => '2026-03']);
check('the releaser is told it released it, and what it chose',
      $told['released'] === true && $told['yours'] === ['name' => true, 'place' => true, 'month' => true]);
check('and that the other has chosen nothing yet',
      $told['theirs'] === ['name' => false, 'place' => false, 'month' => false]);
[$sx, $sz] = WildFields::tile($six['seed']);
$beside = fn () => array_values(array_filter($wild->tile($sx, $sz), fn ($p) => $p['seed'] === $six['seed']))[0];
check('the field shows the releaser\'s name at once, and no place or month',
      $beside()['shown'] === ['names' => ['Wren'], 'place' => null, 'month' => null]);
check('a plant nobody named carries no shown at all',
      !array_key_exists('shown', $wild->find($four['seed'])));
check('the other gardener\'s words are kept nowhere, and the releaser\'s place and month only as fingerprints',
      stillHeld($db, ['the place' => 'On the winds', 'the month' => '2026-03',
                      'a token' => $a6, 'the other token' => $b6]) === []);

// The other phone hears of it on the poll it already makes, with its own token.
$heard = $wild->touching([$b6, token('unrelated')]);
check('the other phone hears of it, told it did not release it',
      count($heard) === 1 && $heard[0]['seed'] === $six['seed'] && $heard[0]['token'] === $b6
      && $heard[0]['released'] === false);
check('and what the releaser chose, as yes and no',
      $heard[0]['theirs'] === ['name' => true, 'place' => true, 'month' => true]);
check('a token that is neither of the two hears nothing', $wild->touching([token('unrelated')]) === []);
check('and cannot answer', $wild->answer($six['seed'], token('unrelated'), ['name' => 'Mallory'] + $none) === null);
check('nor can anybody answer for a plant released without names',
      $wild->answer($four['seed'], token('four/a'), ['name' => 'Mallory'] + $none) === null);

// The other answers: their name, and the month — the same month.
$answered = $wild->answer($six['seed'], $b6, ['name' => 'Ash', 'place' => null, 'month' => '2026-03']);
check('two names stand beside it, in alphabetical order, not in the order of who released it',
      $answered['shown']['names'] === ['Ash', 'Wren'] && $beside()['shown']['names'] === ['Ash', 'Wren']);
check('the month stands once both chose it', $beside()['shown']['month'] === '2026-03');
check('the place does not, while only one has', $beside()['shown']['place'] === null);

// The place, remembered differently on the two phones, is not shown: a place
// one of them never wrote is not one either agreed to.
$wild->answer($six['seed'], $b6, ['name' => 'Ash', 'place' => 'By the canal', 'month' => '2026-03']);
check('two different places show no place', $beside()['shown']['place'] === null);
check('and the different words are kept nowhere', stillHeld($db, ['a place' => 'By the canal']) === []);
$wild->answer($six['seed'], $b6, ['name' => 'Ash', 'place' => 'On the winds', 'month' => '2026-03']);
check('the same place, chosen by both, stands', $beside()['shown']['place'] === 'On the winds');

// Either withdraws, at any time, without the other.
$wild->answer($six['seed'], $a6, ['name' => 'Wren', 'place' => null, 'month' => '2026-03']);
check('the releaser withdrawing the place takes it down for both', $beside()['shown']['place'] === null);
check('and the words go with it', stillHeld($db, ['the place' => 'On the winds']) === []);
$wild->answer($six['seed'], $b6, $none);
check('the other withdrawing everything leaves only the releaser\'s name',
      $beside()['shown'] === ['names' => ['Wren'], 'place' => null, 'month' => null]);
check('and their name is kept nowhere', stillHeld($db, ['the name' => 'Ash']) === []);
$wild->answer($six['seed'], $a6, $none);
check('both anonymous, the plant is a plant again, with no shown at all',
      !array_key_exists('shown', $beside()));
$withdrawn = $wild->touching([$a6]);
check('and the releaser can still change its mind later',
      count($withdrawn) === 1 && $withdrawn[0]['released'] === true
      && $wild->answer($six['seed'], $a6, ['name' => 'Wren'] + $none) !== null);

// The other phone releasing its own copy answers for itself, and a stranger
// releasing the plant again does not get to stand beside it.
$wild->beside($six['seed'], $b6, $a6, ['name' => 'Ash', 'place' => null, 'month' => null]);
check('the other gardener releasing their copy answers as themselves, not as a releaser',
      $beside()['shown']['names'] === ['Ash', 'Wren'] && $wild->touching([$b6])[0]['released'] === false);
check('a stranger releasing it again with tokens of their own stands nobody beside it',
      $wild->beside($six['seed'], token('stranger'), token('stranger 2'), ['name' => 'Mallory'] + $none) === null
      && $beside()['shown']['names'] === ['Ash', 'Wren']);

// What a names row is, and what it is not.
$named = array_column($db->query('PRAGMA table_info(wild_names)')->fetchAll(PDO::FETCH_ASSOC), 'name');
check('a names row is two token fingerprints, what each chose, and what both chose: ' . implode(', ', $named),
      $named === ['seed', 'print_a', 'print_b', 'name_a', 'name_b', 'place_a', 'place_b', 'month_a', 'month_b',
                  'place', 'month']);
$namesRowid = true;
try {
    $db->query('SELECT rowid FROM wild_names')->fetchAll();
} catch (PDOException) {
    $namesRowid = false;
}
check('and SQLite keeps no hidden row number for it either', $namesRowid === false);
check('a hidden plant shows nobody beside it', (function () use ($db, $wild, $six, $sx, $sz) {
    $db->prepare('UPDATE wild_fields SET hidden = 1 WHERE seed = ?')->execute([$six['seed']]);
    $gone = !in_array($six['seed'], array_column($wild->tile($sx, $sz), 'seed'), true);
    $db->prepare('UPDATE wild_fields SET hidden = 0 WHERE seed = ?')->execute([$six['seed']]);
    return $gone;
})());

// MARK: The limit

check('release is limited, and is the tightest write',
      isset(Limits::ROUTES['/api/wild/release'])
      && Limits::ROUTES['/api/wild/release'][0] <= min(array_column(Limits::ROUTES, 0)));
check('answering what stands beside a plant is limited too', isset(Limits::ROUTES['/api/wild/answer']));

unset($walk, $db, $wild, $offers);
@unlink($file);

fwrite(STDOUT, $failures === 0 ? "\nThe Wild Fields hold.\n" : "\n$failures failed.\n");
exit($failures === 0 ? 0 : 1);
