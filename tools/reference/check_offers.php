<?php
declare(strict_types=1);

/**
 * The asking, end to end: nothing reaches the Long Walk until the second
 * gardener says yes.
 *
 * Run: php tools/reference/check_offers.php
 *
 * It drives `Offers` and `WalkStore` over a throwaway SQLite file rather than
 * over HTTP, so it runs anywhere PHP does and says which step broke. The HTTP
 * shell around them is thin and is checked by hand against a local `php -S`;
 * what matters and what can silently rot is the rule below it:
 *
 *   - an offer plants nothing,
 *   - only the token an offer was addressed to can answer it,
 *   - one offer per plant, so a decline is final,
 *   - a withdrawn plant leaves the walk alone and its slot empty,
 *   - and leaves nothing of itself in the database but that slot, the traits
 *     the rule reads and fingerprints — while both phones still hear of it and
 *     nobody can offer it again,
 *   - an offer nobody answers lapses into a withdrawal after thirty days,
 *   - and what the old code kept of a withdrawal is erased on opening.
 */

require_once __DIR__ . '/../../Server/.api/Seeds.php';
require_once __DIR__ . '/../../Server/.api/WalkStore.php';

$failures = 0;
function check(string $what, bool $held): void
{
    global $failures;
    if (!$held) { $failures++; fwrite(STDERR, "FAILED  $what\n"); }
    else fwrite(STDOUT, "ok      $what\n");
}

$file = sys_get_temp_dir() . '/peacegarden-offers-' . getmypid() . '.sqlite';
@unlink($file);
$walk = WalkStore::open('sqlite:' . $file);
$offers = $walk->offers();

/** A real crossing: two parents, a meeting, and the child they actually make. */
function crossing(int $n): array
{
    $a = hash('sha256', "parent a $n");
    $b = hash('sha256', "parent b $n");
    $encounter = hash('sha256', "meeting $n");
    return ['seed' => Seeds::cross($a, $b, $encounter), 'a' => $a, 'b' => $b, 'encounter' => $encounter];
}

function token(string $of): string { return substr(hash('sha256', $of), 0, 32); }

/**
 * Every table in the database, every row, every column, searched for any of
 * these strings. What "no longer stored anywhere" means, checked as literally
 * as a check can: not the columns this file knows about, but whatever the
 * service has made since.
 */
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

/** What `stillHeld` found, said after a check's name when there is anything to say. */
function found(array $held): string
{
    return $held === [] ? '' : ': ' . implode(', ', $held);
}

/** A row of an area's table by its arrival number, which is what outlives its seed. */
function arrival(PDO $db, string $table, int $arrival): ?array
{
    $query = $db->prepare("SELECT * FROM $table WHERE arrival = ?");
    $query->execute([$arrival]);
    $row = $query->fetch(PDO::FETCH_ASSOC);
    return $row === false ? null : $row;
}

function arrivalOf(PDO $db, string $table, string $seed): ?int
{
    $query = $db->prepare("SELECT arrival FROM $table WHERE seed = ?");
    $query->execute([$seed]);
    $found = $query->fetchColumn();
    return $found === false ? null : (int) $found;
}

function offerRow(PDO $db, int $offer): ?array
{
    $query = $db->prepare('SELECT * FROM walk_offers WHERE offer = ?');
    $query->execute([$offer]);
    $row = $query->fetch(PDO::FETCH_ASSOC);
    return $row === false ? null : $row;
}

function offerNumber(PDO $db, string $seed): ?int
{
    $query = $db->prepare('SELECT offer FROM walk_offers WHERE seed = ?');
    $query->execute([$seed]);
    $found = $query->fetchColumn();
    return $found === false ? null : (int) $found;
}

/**
 * A plot's shared plants: what it holds, minus the ambassador standing at the
 * head of plot 0.
 *
 * The walk is never empty and never was — its ambassador (*Zephea pallida*
 * since the re-roll of 28 September 2026, *Halula crassicaulis* before) was placed
 * there before anything else and is not a row in the table. Every count below
 * is about what gardeners put there, which is what these checks are about, so
 * the one plant nobody put there is taken out first. It is the one with no
 * parents, because it has none.
 */
function shared(WalkStore $walk, int $plot = 0): array
{
    return array_values(array_filter($walk->plot($plot), fn ($p) => count($p['parents']) === 2));
}

$now = 1_700_000_000;

// MARK: An offer plants nothing

$one = crossing(1);
$mine = token('one/mine');
$theirs = token('one/theirs');
[$offer, $new] = $offers->offer($one['seed'], $theirs, $mine, $one['a'], $one['b'], $one['encounter'], 1.1, 2, $now);

check('an offer is new the first time', $new === true);
check('an offer starts out waiting', $offer['state'] === Offers::OFFERED);
check('an offer plants nothing', shared($walk) === []);
// And yet there is somewhere to walk: plot 0 opened with the ambassador in it,
// before any of this, and it is there whether or not a gardener has shared
// anything. `check_ambassador.php` is where that is held to the Swift.
check('the walk was never empty', $walk->plots() === 1 && count($walk->plot(0)) === 1);

// MARK: Who can see it, and who cannot

check('the gardener it was sent to finds it', count($offers->touching([$theirs], $now)) === 1);
check('the gardener who sent it sees its state', count($offers->touching([$mine], $now)) === 1);
check('a stranger finds nothing', $offers->touching([token('somebody else')], $now) === []);
check('no tokens asks nothing', $offers->touching([], $now) === []);
check('what comes back carries no seeds but its own',
      array_keys($offers->touching([$theirs], $now)[0]) === ['seed', 'to', 'from', 'state', 'offeredAt', 'answeredAt']);

// MARK: Only the gardener it was addressed to can answer

check('the wrong token cannot answer', $offers->answer($one['seed'], token('wrong'), true, $now) === null);
check('the gardener who sent it cannot answer for the other', $offers->answer($one['seed'], $mine, true, $now) === null);
check('and none of that planted anything', shared($walk) === []);

// MARK: Yes plants it

$answered = $offers->answer($one['seed'], $theirs, true, $now + 60);
check('yes plants it', $answered !== null && $answered['planting'] !== null);
check('it stands in the walk', count(shared($walk)) === 1);
check('the plant in the walk is the one offered', shared($walk)[0]['seed'] === $one['seed']);
check('the offer is settled', $answered['offer']['state'] === Offers::ACCEPTED);
check('and says when', $answered['offer']['answeredAt'] === $now + 60);

$settled = $offers->touching([$theirs], $now)[0];
check('a settled offer keeps the seed and the two tokens',
      $settled['seed'] === $one['seed'] && $settled['to'] === $theirs && $settled['from'] === $mine);

// MARK: One offer per plant, which is what makes a decline final

[$again, $wasNew] = $offers->offer($one['seed'], $theirs, $mine, $one['a'], $one['b'], $one['encounter'], 1.1, 2, $now);
check('a plant cannot be offered twice', $wasNew === false && $again['state'] === Offers::ACCEPTED);

$two = crossing(2);
$mine2 = token('two/mine');
$theirs2 = token('two/theirs');
$offers->offer($two['seed'], $theirs2, $mine2, $two['a'], $two['b'], $two['encounter'], 0.6, 4, $now);
$no = $offers->answer($two['seed'], $theirs2, false, $now);

check('no plants nothing', $no['planting'] === null && count(shared($walk)) === 1);
check('no is recorded', $no['offer']['state'] === Offers::DECLINED);
[$third, $thirdNew] = $offers->offer($two['seed'], $theirs2, $mine2, $two['a'], $two['b'], $two['encounter'], 0.6, 4, $now);
check('a declined plant cannot be offered again', $thirdNew === false && $third['state'] === Offers::DECLINED);
check('answering a settled offer changes nothing',
      $offers->answer($two['seed'], $theirs2, true, $now)['planting'] === null);
check('and it is still not in the walk', count(shared($walk)) === 1);

// **A decline is erased as a withdrawal is**, and is still final. Nothing of it
// was ever public, but it used to keep the seed and both tokens for good. Now
// the fingerprints and the word are all that is left, and they are enough to
// refuse the plant again and to tell both phones.
$two['mine'] = $mine2;
$two['theirs'] = $theirs2;
check('nothing of a declined plant is left in the database' . found(stillHeld($walk->connection(), $two)),
      stillHeld($walk->connection(), $two) === []);
$declinedRows = $walk->connection()->query("SELECT * FROM walk_offers WHERE state = 'declined'")->fetchAll();
check('the decline keeps fingerprints, the word and its times', count($declinedRows) === 1
      && $declinedRows[0]['seed'][0] === 'h' && $declinedRows[0]['token_to'][0] === 'h'
      && $declinedRows[0]['parent_a'] === null && $declinedRows[0]['area'] === '');
check('the phone that offered it hears no, by its token', ($offers->touching([$mine2], $now + 5)[0] ?? null) === [
    'seed' => '', 'to' => '', 'from' => $mine2, 'state' => Offers::DECLINED,
    'offeredAt' => $now, 'answeredAt' => $now,
]);
[$strangers, ] = $offers->offer($two['seed'], token('two/stranger a'), token('two/stranger b'),
                                $two['a'], $two['b'], $two['encounter'], 0.6, 4, $now);
check('strangers offering a declined plant are refused', $strangers === null);
$withdrawnDecline = $offers->withdraw($two['seed'], $mine2, $now + 9);
check('withdrawing a declined offer leaves it declined', $withdrawnDecline !== null
      && $withdrawnDecline['state'] === Offers::DECLINED && $withdrawnDecline['answeredAt'] === $now
      && $withdrawnDecline['seed'] === $two['seed'] && $withdrawnDecline['from'] === $mine2);
check('and the one it was sent to still cannot say yes',
      ($offers->answer($two['seed'], $theirs2, true, $now + 10)['offer']['state'] ?? null) === Offers::DECLINED
      && count(shared($walk)) === 1);

// MARK: Taking it back

$three = crossing(3);
$mine3 = token('three/mine');
$theirs3 = token('three/theirs');
$offers->offer($three['seed'], $theirs3, $mine3, $three['a'], $three['b'], $three['encounter'], 1.6, 1, $now);
$offers->answer($three['seed'], $theirs3, true, $now);
check('two plants stand in the walk', count(shared($walk)) === 2);
$stoodAt = null;
foreach (shared($walk) as $p) if ($p['seed'] === $three['seed']) $stoodAt = $p['spot'];
$db = $walk->connection();
$threeArrival = arrivalOf($db, 'long_walk', $three['seed']);
$threeOffer = offerNumber($db, $three['seed']);
$before = arrival($db, 'long_walk', (int) $threeArrival);

$taken = $offers->withdraw($three['seed'], $mine3, $now + 120);
check('the gardener who shared it can take it back', $taken !== null && $taken['state'] === Offers::WITHDRAWN);
check('and is told so about the plant it named', $taken !== null && $taken['seed'] === $three['seed']
      && $taken['from'] === $mine3 && $taken['answeredAt'] === $now + 120);
check('it is no longer drawn', count(shared($walk)) === 1);
check('and the one beside it is untouched', shared($walk)[0]['seed'] === $one['seed']);

// MARK: Taking it back deletes

// The seed, both parents, the meeting and both tokens, searched for in every
// column of every table. None of them may be anywhere.
$three['mine'] = $mine3;
$three['theirs'] = $theirs3;
check('nothing of a withdrawn plant is left in the database' . found(stillHeld($db, $three)),
      stillHeld($db, $three) === []);

// What is left in the walk is its place and the two traits the rule reads.
$after = arrival($db, 'long_walk', (int) $threeArrival);
check('the walk keeps the row, hidden, under the same arrival', $after !== null && (int) $after['hidden'] === 1);
check('its seed is a marker that is not a seed', $after !== null
      && $after['seed'] === TakenBack::marker((int) $threeArrival) && !Seeds::isHex32($after['seed']));
check('its parents and meeting are gone', $after !== null
      && $after['parent_a'] === '' && $after['parent_b'] === '' && $after['encounter'] === '');
check('and its nudge, which was a piece of its seed', $after !== null
      && (float) $after['nudge_x'] === 0.0 && (float) $after['nudge_z'] === 0.0);
check('it keeps its place and what the rule reads', $after !== null && $before !== null
      && array_intersect_key($after, array_flip(['plot', 'side', 'tier', 'slot_index', 'height', 'family']))
         == array_intersect_key($before, array_flip(['plot', 'side', 'tier', 'slot_index', 'height', 'family'])));

// And what is left of the offer is fingerprints, the word and the times.
$print = offerRow($db, (int) $threeOffer);
check('the offer keeps a fingerprint of its seed, not the seed', $print !== null
      && strlen($print['seed']) === 64 && $print['seed'][0] === 'h');
check('and fingerprints of its tokens', $print !== null
      && strlen($print['token_to']) === 32 && $print['token_to'][0] === 'h'
      && strlen($print['token_from']) === 32 && $print['token_from'][0] === 'h');
check('and no plant, and no area', $print !== null && $print['parent_a'] === null && $print['encounter'] === null
      && $print['height'] === null && $print['kind'] === '' && $print['area'] === '');

// **The other phone still hears.** It asks with its own token and is told the
// offer was withdrawn, with that token and no seed — the service has none to
// give — and finds its plant by the token.
$heard = $offers->touching([$theirs3], $now + 180);
check('the other phone still finds it by its token', count($heard) === 1);
check('told in its own words: its token, no seed, withdrawn', ($heard[0] ?? null) === [
    'seed' => '', 'to' => $theirs3, 'from' => '', 'state' => Offers::WITHDRAWN,
    'offeredAt' => $now, 'answeredAt' => $now + 120,
]);
check('and a stranger still finds nothing', $offers->touching([token('somebody else')], $now + 180) === []);

// **And it still cannot come back.** The seed, parents and meeting were public
// while it stood; anybody who read them has everything an offer needs except
// the tokens. The fingerprint is what refuses them.
[$again3, $againNew] = $offers->offer($three['seed'], token('replant/a'), token('replant/b'),
                                      $three['a'], $three['b'], $three['encounter'], 1.6, 1, $now + 200);
check('a withdrawn plant offered again by strangers is refused', $again3 === null && $againNew === false);
[$again3, $againNew] = $offers->offer($three['seed'], $theirs3, $mine3,
                                      $three['a'], $three['b'], $three['encounter'], 1.6, 1, $now + 200);
check('offered again by the two who met, it is still withdrawn', $again3 !== null && $againNew === false
      && $again3['state'] === Offers::WITHDRAWN && $again3['seed'] === $three['seed']
      && $again3['to'] === $theirs3 && $again3['from'] === $mine3);
check('and that brought nothing back', stillHeld($db, $three) === [] && count(shared($walk)) === 1);
$late = $offers->answer($three['seed'], $theirs3, true, $now + 240);
check('a yes that arrives after the withdrawal plants nothing', $late !== null && $late['planting'] === null
      && $late['offer']['state'] === Offers::WITHDRAWN && count(shared($walk)) === 1);
check('the wrong token still cannot answer it', $offers->answer($three['seed'], token('wrong'), true, $now) === null);
$twice = $offers->withdraw($three['seed'], $theirs3, $now + 300);
check('withdrawing twice is the first withdrawal', $twice !== null && $twice['state'] === Offers::WITHDRAWN
      && $twice['answeredAt'] === $now + 120 && $twice['to'] === $theirs3);
check('and still leaves nothing behind', stillHeld($db, $three) === []);

// The slot it had is not handed to the next arrival: the walk is append-only
// and the rule still sees it, so a border keeps the gap.
$four = crossing(4);
[$planted] = $walk->plant($four['seed'], $four['a'], $four['b'], $four['encounter'], 1.6, 1);
check('a withdrawn plant keeps its slot', $stoodAt !== null && $planted['spot'] !== $stoodAt);
$standing = array_map(fn ($p) => $p['spot'], $walk->plot(0));  // the ambassador included: nothing may stand on it either
check('nothing is planted on top of it', count($standing) === count(array_unique(array_map('json_encode', $standing))));

// MARK: The second area

// **An offer carries the area its plant belongs to**, and is planted there. A
// Quiet Garden plant answered yes must not turn up in the Long Walk, and the
// two counts either side of this are what would catch it.
$five = crossing(5);
$mine5 = token('five/mine');
$theirs5 = token('five/theirs');
$walkHeld = count(shared($walk));
$offers->offer($five['seed'], $theirs5, $mine5, $five['a'], $five['b'], $five['encounter'],
               0.9, 2, $now, 'peace');
$planted = $offers->answer($five['seed'], $theirs5, true, $now);
check('a Quiet Garden plant is planted', $planted['planting'] !== null);
check('and not in the walk', count(shared($walk)) === $walkHeld);
$room = array_values(array_filter($walk->room()->plot(0), fn ($p) => count($p['parents']) === 2));
check('it is in the room', count($room) === 1 && $room[0]['seed'] === $five['seed']);
check('beside the ambassador, which is still there', count($walk->room()->plot(0)) === 2);

// And taking it back reaches the right area's table.
$offers->withdraw($five['seed'], $mine5, $now + 60);
check('taking it back empties the room again',
      count(array_filter($walk->room()->plot(0), fn ($p) => count($p['parents']) === 2)) === 0);
check('and the ambassador is untouched', count($walk->room()->plot(0)) === 1);
check('and nothing of it is left in the room or the asking',
      stillHeld($walk->connection(), $five + ['mine' => $mine5, 'theirs' => $theirs5]) === []);

// MARK: The sixth area, and the kind an offer has to carry

// **The Seedbed claims a drill by the plant's kind**, and the plant is planted
// when the *other* gardener answers — days later, on a service that cannot grow
// it again to read its name. So the kind travels with the offer or it is lost,
// and losing it is invisible: every plant would simply be sown in the drill of
// unnamed plants and the rule would go on agreeing with itself.
function sownAs(WalkStore $walk, string $seed): ?array
{
    $query = $walk->connection()->prepare('SELECT kind, drill, slot_index FROM seedbed WHERE seed = ?');
    $query->execute([$seed]);
    $row = $query->fetch();
    return $row === false ? null : $row;
}

$six = crossing(6);
$mine6 = token('six/mine');
$theirs6 = token('six/theirs');
$offers->offer($six['seed'], $theirs6, $mine6, $six['a'], $six['b'], $six['encounter'],
               1.0, 2, $now, 'beginnings', 'contorta');
check('a Seedbed plant is planted', $offers->answer($six['seed'], $theirs6, true, $now)['planting'] !== null);
$sown = sownAs($walk, $six['seed']);
check('the kind survived the asking', $sown !== null && $sown['kind'] === 'contorta');
// Drill 0 belongs to the ambassador, *Verora angustifolia*, so a plant whose
// kind was dropped would be sown in the first drill nobody has claimed and look
// exactly like this one. What tells them apart is the kind in the row above and
// the plant that follows it below.
// Since 2 October 2026 a drill is sown from its middle: the first place of
// the drill's own order, not the place by its label.
check('it claimed a drill of its own', $sown !== null && (int) $sown['drill'] === 1
      && (int) $sown['slot_index'] === Seedbed::dryOrder(1)[0]);

$seven = crossing(7);
$mine7 = token('seven/mine');
$theirs7 = token('seven/theirs');
$offers->offer($seven['seed'], $theirs7, $mine7, $seven['a'], $seven['b'], $seven['encounter'],
               1.7, 5, $now, 'beginnings', 'contorta');
$offers->answer($seven['seed'], $theirs7, true, $now);
$beside = sownAs($walk, $seven['seed']);
// A different height and a different colour, and it still joins the first one:
// this area reads neither, and a kind that had been dropped would have opened a
// third drill instead.
check('a second plant of that kind joins the same drill',
      $beside !== null && (int) $beside['drill'] === 1 && (int) $beside['slot_index'] === Seedbed::dryOrder(1)[1]);

// And an offer made without a kind — which is every offer made before the
// column existed — still plants, in the drill of unnamed plants.
$eight = crossing(8);
$mine8 = token('eight/mine');
$theirs8 = token('eight/theirs');
$offers->offer($eight['seed'], $theirs8, $mine8, $eight['a'], $eight['b'], $eight['encounter'],
               0.7, 1, $now, 'beginnings');
$offers->answer($eight['seed'], $theirs8, true, $now);
$unnamed = sownAs($walk, $eight['seed']);
check('an offer with no kind still plants', $unnamed !== null && $unnamed['kind'] === '');
check('and stands in a drill of its own', $unnamed !== null && (int) $unnamed['drill'] === 2);

// The kind is the plant's, not the planting's address, so it goes when the offer
// is settled — with the parents, the height and the family, and for the reason
// they go: an accepted plant is in the bed and does not need to be here twice.
$left = $walk->connection()->prepare('SELECT kind, height, area FROM walk_offers WHERE seed = ?');
$left->execute([$six['seed']]);
$after = $left->fetch();
check('an answered offer keeps no kind', $after !== false && $after['kind'] === ''
      && $after['height'] === null);
check('but still says which area to look in', $after !== false && $after['area'] === 'beginnings');

// MARK: The seventh area

// **The Cold Frame is reached the way every area is**: through `plantInto`,
// whose fallback is the Long Walk. So an area missing from that `match` is not
// refused — its plants are filed in the walk, graded against a border they do
// not belong to, and nothing says so. The two counts either side of the answer
// are what would catch it.
function framedAs(WalkStore $walk, string $seed): ?array
{
    $query = $walk->connection()->prepare(
        'SELECT frame, slot_rank, slot_index, hidden FROM cold_frame WHERE seed = ?');
    $query->execute([$seed]);
    $row = $query->fetch();
    return $row === false ? null : $row;
}

$nine = crossing(9);
$mine9 = token('nine/mine');
$theirs9 = token('nine/theirs');
$walkHeld = count(shared($walk));
$offers->offer($nine['seed'], $theirs9, $mine9, $nine['a'], $nine['b'], $nine['encounter'],
               1.1, 2, $now, 'waiting');
check('a Cold Frame plant is planted',
      $offers->answer($nine['seed'], $theirs9, true, $now)['planting'] !== null);
check('and not in the walk', count(shared($walk)) === $walkHeld);
$framed = framedAs($walk, $nine['seed']);
// The ambassador, *Nyxisora crassicaulis*, is a lotus and has stood in the tank
// since it was sunk on 27 September, so no frame is claimed before this plant
// arrives: it claims the first for its colour, and at 1.1 m it opens it in the
// back rank — the answer only the Cold Frame's rule gives, where a plant
// misfiled anywhere else has no row here at all. (Until the tank, the first
// frame was the ambassador's and this plant opened the second; this check said
// so until 28 September 2026.)
check('it is in the Cold Frame, in a frame of its own colour',
      $framed !== null && (int) $framed['frame'] === ColdFrame::BACK_WEST
      && (int) $framed['slot_rank'] === ColdFrame::BACK && (int) $framed['slot_index'] === 0);
check('beside the ambassador, which is still there', count($walk->coldFrame()->plot(0)) === 2);

// And taking it back reaches the Cold Frame's table, not the walk's: the row
// stays and keeps its place, and is not drawn. It is found by its arrival
// number afterwards, because its seed is no longer there to find it by.
$nineArrival = arrivalOf($db, 'cold_frame', $nine['seed']);
$offers->withdraw($nine['seed'], $mine9, $now + 60);
$lifted = arrival($db, 'cold_frame', (int) $nineArrival);
check('taking it back hides it in the Cold Frame', $lifted !== null && (int) $lifted['hidden'] === 1);
check('where it keeps its frame, its rank and its place', $lifted !== null
      && (int) $lifted['frame'] === ColdFrame::BACK_WEST
      && (int) $lifted['slot_rank'] === ColdFrame::BACK && (int) $lifted['slot_index'] === 0);
check('and the family that claimed the frame, and its height', $lifted !== null
      && (int) $lifted['family'] === 2 && (float) $lifted['height'] === 1.1);
check('and nothing else of it', framedAs($walk, $nine['seed']) === null
      && stillHeld($db, $nine + ['mine' => $mine9, 'theirs' => $theirs9]) === []);
check('and the frame is back to its ambassador alone', count($walk->coldFrame()->plot(0)) === 1);

// MARK: The eighth area, and the hue an offer has to carry

// **The Glasshouse stands a pot at its place in a spectrum, and the place is
// read off the plant's hue** — which, like the Seedbed's kind, has to travel
// with the offer, because the plant is planted when the other gardener answers
// and nothing then can grow it to see its colour. Losing it would be invisible
// twice over: the plant would land in `plantInto`'s fallback, the walk, if the
// area were missing there; and if the hue alone were dropped it would take the
// first free pot from the door, which is a place the rule also gives.
function pottedAs(WalkStore $walk, string $seed): ?array
{
    $query = $walk->connection()->prepare(
        'SELECT bed, slot_index, slot_row, hue, hidden FROM glasshouse WHERE seed = ?');
    $query->execute([$seed]);
    $row = $query->fetch();
    return $row === false ? null : $row;
}

$ten = crossing(10);
$mine10 = token('ten/mine');
$theirs10 = token('ten/theirs');
$walkHeld = count(shared($walk));
// Violet, 280°: the sixth band, well away from the door, so a hue that had
// been dropped — which would put it in the first free pot from the door —
// cannot land in the same place by chance.
$violet = 280.0 / 360.0;
$offers->offer($ten['seed'], $theirs10, $mine10, $ten['a'], $ten['b'], $ten['encounter'],
               0.9, 4, $now, 'light', '', $violet);
check('a Glasshouse plant is planted',
      $offers->answer($ten['seed'], $theirs10, true, $now)['planting'] !== null);
check('and not in the walk', count(shared($walk)) === $walkHeld);
$potted = pottedAs($walk, $ten['seed']);
// To the bit, which is what `GlasshouseStore::exactly` is for: bound as a
// plain float, PDO writes fourteen digits and 280° comes back a different
// double — near enough for a height, not for a number compared with a band
// edge exactly.
check('the hue survived the asking, to the bit', $potted !== null && (float) $potted['hue'] === $violet);
check('it is potted on the staging at its own band', $potted !== null
      && (int) $potted['bed'] === Glasshouse::STAGING
      && (int) $potted['slot_index'] === Glasshouse::band($violet) && (int) $potted['slot_row'] === 0);
check('beside the ambassador, which is still there', count($walk->glasshouse()->plot(0)) === 2);
$served = $walk->glasshouse()->plot(0)[1] ?? [];
check('and the page is told how far off the floor it stands',
      ($served['lift'] ?? null) === Glasshouse::STAGING_TOP + Glasshouse::POT_SOIL);

// A plant tall enough for the border goes there, whatever its colour — in the
// next place from the door, since the ambassador, *Elora elata*, has held the
// first since the re-roll of 28 September 2026.
$eleven = crossing(11);
$mine11 = token('eleven/mine');
$theirs11 = token('eleven/theirs');
$offers->offer($eleven['seed'], $theirs11, $mine11, $eleven['a'], $eleven['b'], $eleven['encounter'],
               1.6, 4, $now, 'light', '', $violet);
$offers->answer($eleven['seed'], $theirs11, true, $now);
$tall = pottedAs($walk, $eleven['seed']);
check('a tall one goes in the border, next from the door after the ambassador', $tall !== null
      && (int) $tall['bed'] === Glasshouse::BORDER && (int) $tall['slot_index'] === 1);

// And an offer made without a hue — every offer made before the column
// existed — still plants: in the first free pot from the door.
$twelve = crossing(12);
$mine12 = token('twelve/mine');
$theirs12 = token('twelve/theirs');
$offers->offer($twelve['seed'], $theirs12, $mine12, $twelve['a'], $twelve['b'], $twelve['encounter'],
               0.9, 4, $now, 'light');
$offers->answer($twelve['seed'], $theirs12, true, $now);
$unhued = pottedAs($walk, $twelve['seed']);
check('an offer with no hue still plants', $unhued !== null && $unhued['hue'] === null);
check('in the first free pot from the door', $unhued !== null
      && (int) $unhued['bed'] === Glasshouse::STAGING && (int) $unhued['slot_index'] === 0);

// The hue goes when the offer is settled, with the rest of the plant.
$settled = $walk->connection()->prepare('SELECT hue, area FROM walk_offers WHERE seed = ?');
$settled->execute([$ten['seed']]);
$after = $settled->fetch();
check('an answered offer keeps no hue', $after !== false && $after['hue'] === null);
check('but still says which area to look in', $after !== false && $after['area'] === 'light');

// Taking it back reaches the Glasshouse's table, and leaves the pot empty. It
// is found by its arrival number afterwards, because its seed is gone.
$tenArrival = arrivalOf($db, 'glasshouse', $ten['seed']);
$offers->withdraw($ten['seed'], $mine10, $now + 60);
$lifted = arrival($db, 'glasshouse', (int) $tenArrival);
check('taking it back hides it in the Glasshouse', $lifted !== null && (int) $lifted['hidden'] === 1);
check('where it keeps its bed, its position and its row', $lifted !== null
      && (int) $lifted['bed'] === Glasshouse::STAGING
      && (int) $lifted['slot_index'] === Glasshouse::band($violet) && (int) $lifted['slot_row'] === 0);
check('and not its hue, which no rule reads of a plant standing', $lifted !== null && $lifted['hue'] === null
      && (float) $lifted['height'] === 0.0);
$tenOffer = $db->query("SELECT hue FROM walk_offers WHERE state = 'withdrawn' AND hue IS NOT NULL")->fetchAll();
check('and the offer keeps no hue either', $tenOffer === []);
check('and nothing else of it', pottedAs($walk, $ten['seed']) === null
      && stillHeld($db, $ten + ['mine' => $mine10, 'theirs' => $theirs10]) === []);

// MARK: The ninth area, and the habit an offer has to carry

// **The Coppice stands a fern on a stool and a star in the light, and which is
// read off the plant's habit** — which travels with the offer for the hue's
// reason. Dropped, it would be invisible: a fern read as a star stands on the
// floor, which is a place the rule also gives.
function stoodAs(WalkStore $walk, string $seed): ?array
{
    $query = $walk->connection()->prepare(
        'SELECT coupe, place, slot_index, habit, height, hidden FROM coppice WHERE seed = ?');
    $query->execute([$seed]);
    $row = $query->fetch();
    return $row === false ? null : $row;
}

$thirteen = crossing(13);
$mine13 = token('thirteen/mine');
$theirs13 = token('thirteen/theirs');
$walkHeld = count(shared($walk));
$offers->offer($thirteen['seed'], $theirs13, $mine13, $thirteen['a'], $thirteen['b'], $thirteen['encounter'],
               0.7, 5, $now, 'renewal', '', null, 'fern');
check('a Coppice plant is planted',
      $offers->answer($thirteen['seed'], $theirs13, true, $now)['planting'] !== null);
check('and not in the walk', count(shared($walk)) === $walkHeld);
$stool = stoodAs($walk, $thirteen['seed']);
// A fern: the second coupe's middle stool, the first coupe's being the
// ambassador's — *Drosula vulgaris*, a fern itself since the re-roll of 28
// September 2026 — and a fern taking a stool in the coupe with fewest. Read as
// a star, a plant of 0.7 m would have gone to the front row of the first
// coupe, whose floor is empty — so a habit dropped on the way cannot land here
// by chance.
check('the habit survived the asking', $stool !== null && $stool['habit'] === 'fern');
check('it stands on the second coupe\'s middle stool', $stool !== null
      && (int) $stool['coupe'] === 1 && (int) $stool['place'] === Coppice::STOOL
      && (int) $stool['slot_index'] === Coppice::STOOL_ORDER[0]);
check('beside the ambassador, which is still there', count($walk->coppice()->plot(0, 0)) === 2);
// Coupe 1 of plot 0 stands grown in year 0 and is cut in year 1.
$served = $walk->coppice()->plot(0, 0)[1] ?? [];
check('and the page is told its coupe is grown this year',
      array_key_exists('stage', $served) && $served['stage'] === Coppice::GROWN);
check('and a year on, cut', ($walk->coppice()->plot(0, 1)[1]['stage'] ?? null) === Coppice::CUT);
// The ambassador is on a stool too, and is told its coupe's stage as any fern
// on a stool is: coupe 0 is the one cut in year 0.
check('and so is the ambassador, cut this year with the first coupe',
      array_key_exists('stage', $walk->coppice()->plot(0, 0)[0])
      && $walk->coppice()->plot(0, 0)[0]['stage'] === Coppice::CUT);

// An offer made without a habit — every offer made before the column existed
// — still plants: as a star, on the floor.
$fourteen = crossing(14);
$mine14 = token('fourteen/mine');
$theirs14 = token('fourteen/theirs');
$offers->offer($fourteen['seed'], $theirs14, $mine14, $fourteen['a'], $fourteen['b'], $fourteen['encounter'],
               0.7, 5, $now, 'renewal');
$offers->answer($fourteen['seed'], $theirs14, true, $now);
$unsent = stoodAs($walk, $fourteen['seed']);
check('an offer with no habit still plants', $unsent !== null && $unsent['habit'] === '');
check('in the light, as a star', $unsent !== null && (int) $unsent['place'] === Coppice::FRONT
      && (int) $unsent['coupe'] === 0);
$asStar = array_values(array_filter($walk->coppice()->plot(0, 0), fn($p) => $p['seed'] === $fourteen['seed']));
check('and a star is drawn at its best, whatever the year',
      $asStar !== [] && array_key_exists('stage', $asStar[0]) && $asStar[0]['stage'] === null);

$settled = $walk->connection()->prepare('SELECT habit, area FROM walk_offers WHERE seed = ?');
$settled->execute([$thirteen['seed']]);
$after = $settled->fetch();
check('an answered offer keeps no habit', $after !== false && $after['habit'] === '');
check('but still says which area to look in', $after !== false && $after['area'] === 'renewal');

// Taking it back keeps its place and its habit, which the rule reads of a plant
// standing: a floor holds one fern at most.
$thirteenArrival = arrivalOf($db, 'coppice', $thirteen['seed']);
$offers->withdraw($thirteen['seed'], $mine13, $now + 60);
$lifted = arrival($db, 'coppice', (int) $thirteenArrival);
check('taking it back hides it in the Coppice', $lifted !== null && (int) $lifted['hidden'] === 1);
check('where it keeps its coupe, its place and its habit', $lifted !== null
      && (int) $lifted['coupe'] === 1 && (int) $lifted['place'] === Coppice::STOOL
      && $lifted['habit'] === 'fern' && (float) $lifted['height'] === 0.7 && (int) $lifted['family'] === 0);
check('and nothing else of it', stoodAs($walk, $thirteen['seed']) === null
      && stillHeld($db, $thirteen + ['mine' => $mine13, 'theirs' => $theirs13]) === []);

// MARK: The tenth area, and the habit read as a crop

// **The Home Ground reads the same habit to other ends: it names the crop, and
// the crop claims a bed.** Dropped on the way, a spire would be sown as an
// umbel — which is a place the rule also gives, so nothing would look wrong.
function bedded(WalkStore $walk, string $seed): ?array
{
    $query = $walk->connection()->prepare(
        'SELECT bed, crop, slot_index, habit, height, family, hidden FROM home_ground WHERE seed = ?');
    $query->execute([$seed]);
    $row = $query->fetch();
    return $row === false ? null : $row;
}

$fifteen = crossing(15);
$mine15 = token('fifteen/mine');
$theirs15 = token('fifteen/theirs');
$walkHeld = count(shared($walk));
$offers->offer($fifteen['seed'], $theirs15, $mine15, $fifteen['a'], $fifteen['b'], $fifteen['encounter'],
               1.5, 2, $now, 'ground', '', null, 'spire');
check('a Home Ground plant is planted',
      $offers->answer($fifteen['seed'], $theirs15, true, $now)['planting'] !== null);
check('and not in the walk', count(shared($walk)) === $walkHeld);
$spire = bedded($walk, $fifteen['seed']);
// A spire over its crop's cut: the north end of the middle bed, the west bed
// being the ambassador's umbels. Read as an umbel it would have gone to the
// west bed beside the ambassador, so a habit dropped on the way cannot land
// here by chance.
check('the habit survived the asking', $spire !== null && $spire['habit'] === 'spire');
check('it opens the middle bed for spires, at its north end', $spire !== null
      && (int) $spire['bed'] === 1 && $spire['crop'] === 'Cer' && (int) $spire['slot_index'] === 0);
check('beside the ambassador, which is still there', count($walk->homeGround()->plot(0)) === 2);

// An offer made without a habit still plants: as an umbel, beside the
// ambassador. Short, so from the south end of the west bed.
$sixteen = crossing(16);
$mine16 = token('sixteen/mine');
$theirs16 = token('sixteen/theirs');
$offers->offer($sixteen['seed'], $theirs16, $mine16, $sixteen['a'], $sixteen['b'], $sixteen['encounter'],
               0.6, 3, $now, 'ground');
$offers->answer($sixteen['seed'], $theirs16, true, $now);
$unsent = bedded($walk, $sixteen['seed']);
check('an offer with no habit still plants', $unsent !== null && $unsent['habit'] === '');
check('as an umbel, at the south end of the west bed', $unsent !== null && (int) $unsent['bed'] === 0
      && $unsent['crop'] === 'Fen' && (int) $unsent['slot_index'] === HomeGround::capacity('Fen') - 1);

$settled = $walk->connection()->prepare('SELECT habit, area FROM walk_offers WHERE seed = ?');
$settled->execute([$fifteen['seed']]);
$after = $settled->fetch();
check('an answered offer keeps no habit', $after !== false && $after['habit'] === '');
check('but still says which area to look in', $after !== false && $after['area'] === 'ground');

// Taking it back keeps its place and its bed's crop, and nothing of the plant:
// no rule reads the height, family or habit of a plant already standing.
$fifteenArrival = arrivalOf($db, 'home_ground', $fifteen['seed']);
$offers->withdraw($fifteen['seed'], $mine15, $now + 60);
$lifted = arrival($db, 'home_ground', (int) $fifteenArrival);
check('taking it back hides it in the Home Ground', $lifted !== null && (int) $lifted['hidden'] === 1);
check('where it keeps its bed, its crop and its place', $lifted !== null
      && (int) $lifted['bed'] === 1 && $lifted['crop'] === 'Cer' && (int) $lifted['slot_index'] === 0);
check('and not its height, family or habit', $lifted !== null && (float) $lifted['height'] === 0.0
      && (int) $lifted['family'] === 0 && $lifted['habit'] === '');
check('and nothing else of it', bedded($walk, $fifteen['seed']) === null
      && stillHeld($db, $fifteen + ['mine' => $mine15, 'theirs' => $theirs15]) === []);

// MARK: The lotus, and the places it takes

// **Since 25 September a lotus takes two places in the Cold Frame and the
// Seedbed**, read off the habit the offer carries. Dropped on the way, a lotus
// would be given one place and the next plant would stand in its pads — a place
// the rule also gives, so the span in the row and the plant after it are what
// tell them apart.
//
// **Since 27 September the habit decides the element as well.** A plant that
// wants water goes in the Cold Frame's tank, one place to a plant, and floods a
// drill of its own in the Seedbed, where a lotus still takes two. Dropped on
// the way, a lotus would be put under glass, or sown in a dry drill of its kind.
// This section said the 25 September story until 28 September 2026.
function held(PDO $db, string $table, string $seed): ?array
{
    $query = $db->prepare("SELECT slot_index, slot_span, habit, hidden FROM $table WHERE seed = ?");
    $query->execute([$seed]);
    $row = $query->fetch();
    return $row === false ? null : $row;
}

// The Cold Frame's tank holds its ambassador, a lotus, in its first place. A
// young lotus joins it in the next, holding one place as everything in the
// water does; a plant of the same colour that is not a lotus goes under glass,
// in the frame no plant of its colour has claimed yet.
$seventeen = crossing(17);
$mine17 = token('seventeen/mine');
$theirs17 = token('seventeen/theirs');
$offers->offer($seventeen['seed'], $theirs17, $mine17, $seventeen['a'], $seventeen['b'], $seventeen['encounter'],
               0.30, 4, $now, 'waiting', '', null, 'lotus');
$offers->answer($seventeen['seed'], $theirs17, true, $now);
$pads = held($db, 'cold_frame', $seventeen['seed']);
check('a lotus in the Cold Frame goes in the tank, after the ambassador, and holds one place', $pads !== null
      && (int) (framedAs($walk, $seventeen['seed'])['frame'] ?? -1) === ColdFrame::TANK
      && (int) $pads['slot_index'] === 1 && (int) $pads['slot_span'] === 1 && $pads['habit'] === 'lotus');
$eighteen = crossing(18);
$mine18 = token('eighteen/mine');
$theirs18 = token('eighteen/theirs');
$offers->offer($eighteen['seed'], $theirs18, $mine18, $eighteen['a'], $eighteen['b'], $eighteen['encounter'],
               0.30, 4, $now, 'waiting');
$offers->answer($eighteen['seed'], $theirs18, true, $now);
$after = framedAs($walk, $eighteen['seed']);
check('and a plant of its colour that is not a lotus goes under glass', $after !== null
      && (int) $after['frame'] === ColdFrame::BACK_EAST && (int) $after['slot_index'] === 0);
$lotusAt = $walk->coldFrame()->plot(0)[1]['spot'] ?? [0.0, 0.0];
[$tankX, $tankZ] = ColdFrame::spot(ColdFrame::TANK, ColdFrame::FRONT, 1);
check('the page is sent its place in the water', abs($lotusAt[0] - $tankX) <= 0.03 + 1e-9
      && abs($lotusAt[1] - $tankZ) <= 0.03 + 1e-9);

// Taken back, it keeps its place: the next lotus floats after it, not in the
// gap it leaves.
$seventeenArrival = arrivalOf($db, 'cold_frame', $seventeen['seed']);
$offers->withdraw($seventeen['seed'], $mine17, $now + 60);
$lifted = arrival($db, 'cold_frame', (int) $seventeenArrival);
check('a lotus taken back keeps its place and not its habit', $lifted !== null
      && (int) $lifted['hidden'] === 1 && (int) $lifted['frame'] === ColdFrame::TANK
      && (int) $lifted['slot_index'] === 1 && (int) $lifted['slot_span'] === 1 && $lifted['habit'] === '');
$nineteen = crossing(19);
$mine19 = token('nineteen/mine');
$theirs19 = token('nineteen/theirs');
$offers->offer($nineteen['seed'], $theirs19, $mine19, $nineteen['a'], $nineteen['b'], $nineteen['encounter'],
               0.30, 4, $now, 'waiting', '', null, 'lotus');
$offers->answer($nineteen['seed'], $theirs19, true, $now);
$later = held($db, 'cold_frame', $nineteen['seed']);
check('and nothing is given its place', $later !== null && (int) $later['slot_index'] === 2);

// The Seedbed's drill of *contorta* is dry, sown with two plants that sent no
// habit. A lotus of that kind wants water, so it passes the dry drill by,
// floods the lowest drill nobody has claimed, at the foot of the bed, and takes
// the first pair that drill is sown in, whatever its height and colour.
$lotusSeed = hash('sha256', 'check_offers: a lotus in the seedbed');
[$sownLotus] = $walk->plantInto('beginnings', $lotusSeed, hash('sha256', 'la'), hash('sha256', 'lb'),
                                hash('sha256', 'le'), 0.3, 1, 'contorta', null, 'lotus');
$sown = held($db, 'seedbed', $lotusSeed);
$pair = Seedbed::wetOrder(5);
check('a lotus in the Seedbed floods a drill of its kind and holds two places in it', $sown !== null
      && ($sownLotus['drill'] ?? null) === 5 && ($sownLotus['kind'] ?? null) === 'contorta'
      && (int) $sown['slot_index'] === $pair[0] && (int) $sown['slot_span'] === 2 && $sown['habit'] === 'lotus');
[$x0, $z0] = Seedbed::at(5, $pair[0]);
[$x1, $z1] = Seedbed::at(5, $pair[1]);
check('and stands between them', abs($sownLotus['spot'][0] - ($x0 + $x1) / 2) <= 0.06 + 1e-9
      && abs($sownLotus['spot'][1] - ($z0 + $z1) / 2) <= 0.035 + 1e-9);

// A published plant's seed, parents and meeting are public. Offering it again
// with two invented tokens must not hand back the real ones, or the stranger
// could withdraw it with them.
[$probe, $probeNew] = $offers->offer($one['seed'], token('stranger/a'), token('stranger/b'),
                                     $one['a'], $one['b'], $one['encounter'], 1.1, 2, $now);
check('a stranger re-offering a published plant is told nothing', $probe === null && $probeNew === false);
[$other, ] = $offers->offer($one['seed'], $mine, $theirs, $one['a'], $one['b'], $one['encounter'], 1.1, 2, $now);
check('the other phone, offering the same child, still learns where it stands',
      $other !== null && $other['to'] === $theirs && $other['from'] === $mine);

$stranger = $offers->withdraw($one['seed'], token('nobody'), $now);
check('a stranger cannot take back somebody else\'s plant', $stranger === null);
check('an offer that does not exist cannot be withdrawn',
      $offers->withdraw(hash('sha256', 'never offered'), $mine, $now) === null);

// MARK: An offer nobody answers lapses after thirty days

// **Found when it is asked about.** One second short of thirty days it is still
// waiting; at thirty days it is withdrawn, answered at the moment it lapsed,
// and erased exactly as a withdrawal is.
$ten = crossing(30);
$mine10 = token('lapse ten/mine');
$theirs10 = token('lapse ten/theirs');
$offers->offer($ten['seed'], $theirs10, $mine10, $ten['a'], $ten['b'], $ten['encounter'], 1.2, 3, $now);
$lapse = $now + Offers::LAPSES_AFTER;
check('an offer is still waiting a second before thirty days',
      ($offers->touching([$theirs10], $lapse - 1)[0]['state'] ?? null) === Offers::OFFERED);
check('at thirty days it has lapsed into a withdrawal', ($offers->touching([$theirs10], $lapse)[0] ?? null) === [
    'seed' => '', 'to' => $theirs10, 'from' => '', 'state' => Offers::WITHDRAWN,
    'offeredAt' => $now, 'answeredAt' => $lapse,
]);
check('and nothing of it is left', stillHeld($db, $ten + ['mine' => $mine10, 'theirs' => $theirs10]) === []);
check('the phone that offered it hears the same', ($offers->touching([$mine10], $lapse)[0]['from'] ?? null) === $mine10);
[$reoffered, $reNew] = $offers->offer($ten['seed'], $theirs10, $mine10, $ten['a'], $ten['b'], $ten['encounter'],
                                      1.2, 3, $lapse + 5);
check('a lapsed offer cannot be made again', $reoffered !== null && $reNew === false
      && $reoffered['state'] === Offers::WITHDRAWN);

// **Found when it is answered.** A yes that arrives after thirty days finds the
// offer gone and plants nothing.
$eleven = crossing(31);
$mine11 = token('lapse eleven/mine');
$theirs11 = token('lapse eleven/theirs');
$offers->offer($eleven['seed'], $theirs11, $mine11, $eleven['a'], $eleven['b'], $eleven['encounter'], 0.8, 0, $now);
$held = count(shared($walk));
$tooLate = $offers->answer($eleven['seed'], $theirs11, true, $lapse + 60);
check('a yes after thirty days plants nothing', $tooLate !== null && $tooLate['planting'] === null
      && $tooLate['offer']['state'] === Offers::WITHDRAWN && $tooLate['offer']['answeredAt'] === $lapse
      && count(shared($walk)) === $held);
check('and leaves nothing of it', stillHeld($db, $eleven + ['mine' => $mine11, 'theirs' => $theirs11]) === []);

// **Swept, when nobody asks.** An offer whose phones never ask again still goes:
// any other offer, or any phone asking about anything, sweeps it.
$twelve = crossing(32);
$mine12 = token('lapse twelve/mine');
$theirs12 = token('lapse twelve/theirs');
$offers->offer($twelve['seed'], $theirs12, $mine12, $twelve['a'], $twelve['b'], $twelve['encounter'], 0.8, 0, $now);
$thirteen = crossing(33);
$offers->offer($thirteen['seed'], token('lapse thirteen/theirs'), token('lapse thirteen/mine'),
               $thirteen['a'], $thirteen['b'], $thirteen['encounter'], 0.8, 0, $lapse + 1);
check('somebody else\'s offer sweeps an offer that has lapsed',
      stillHeld($db, $twelve + ['mine' => $mine12, 'theirs' => $theirs12]) === []);
check('and leaves a fresh one alone', offerNumber($db, $thirteen['seed']) !== null);
$fourteen = crossing(34);
$offers->offer($fourteen['seed'], token('lapse fourteen/theirs'), token('lapse fourteen/mine'),
               $fourteen['a'], $fourteen['b'], $fourteen['encounter'], 0.8, 0, $now + 10);
$offers->touching([token('anyone at all')], $now + 10 + Offers::LAPSES_AFTER);
check('so does any phone asking about anything', offerNumber($db, $fourteen['seed']) === null);

// MARK: What was withdrawn before today

// **The migration.** Until 24 September a withdrawal hid the planting and kept
// everything, so a database carried across the deploy holds withdrawn offers
// with their seeds and tokens and hidden plantings with their seeds, parents and
// meetings. Opening the store is what erases them, and opening it again changes
// nothing further. Written here the way the old code wrote them.
$legacyFile = sys_get_temp_dir() . '/peacegarden-offers-legacy-' . getmypid() . '.sqlite';
@unlink($legacyFile);
$legacy = WalkStore::open('sqlite:' . $legacyFile);
$old = crossing(20);
$oldMine = token('old/mine');
$oldTheirs = token('old/theirs');
$legacy->plant($old['seed'], $old['a'], $old['b'], $old['encounter'], 1.3, 4);
$legacyDb = $legacy->connection();
$legacyDb->prepare('UPDATE long_walk SET hidden = 1 WHERE seed = ?')->execute([$old['seed']]);
$legacyDb->prepare("INSERT INTO walk_offers (seed, token_to, token_from, state, offered_at, answered_at, area)
                    VALUES (?, ?, ?, 'withdrawn', ?, ?, 'travel')")
         ->execute([$old['seed'], $oldTheirs, $oldMine, $now, $now + 50]);
// And a decline, which until the same day kept its seed and tokens too.
$refused = crossing(21);
$refusedMine = token('refused/mine');
$refusedTheirs = token('refused/theirs');
$legacyDb->prepare("INSERT INTO walk_offers (seed, token_to, token_from, state, offered_at, answered_at, area)
                    VALUES (?, ?, ?, 'declined', ?, ?, 'meeting')")
         ->execute([$refused['seed'], $refusedTheirs, $refusedMine, $now, $now + 70]);
$refused += ['mine' => $refusedMine, 'theirs' => $refusedTheirs];
$oldArrival = arrivalOf($legacyDb, 'long_walk', $old['seed']);
$heldBefore = arrival($legacyDb, 'long_walk', (int) $oldArrival);
$old += ['mine' => $oldMine, 'theirs' => $oldTheirs];
check('the legacy rows hold what the old code kept', count(stillHeld($legacyDb, $old)) >= 5);
unset($legacy, $legacyDb);

$reopened = WalkStore::open('sqlite:' . $legacyFile);
$reDb = $reopened->connection();
check('opening the store erases what a withdrawal before today kept' . found(stillHeld($reDb, $old)),
      stillHeld($reDb, $old) === []);
check('and what a decline before today kept' . found(stillHeld($reDb, $refused)),
      stillHeld($reDb, $refused) === []);
check('and the decline is still a decline, to both phones',
      ($reopened->offers()->touching([$refusedMine], $now + 60)[0] ?? null) === [
          'seed' => '', 'to' => '', 'from' => $refusedMine, 'state' => Offers::DECLINED,
          'offeredAt' => $now, 'answeredAt' => $now + 70,
      ]);
$migrated = arrival($reDb, 'long_walk', (int) $oldArrival);
check('and leaves its place where it was', $migrated !== null && $heldBefore !== null
      && $migrated['seed'] === TakenBack::marker((int) $oldArrival)
      && $migrated['plot'] === $heldBefore['plot'] && $migrated['slot_index'] === $heldBefore['slot_index']
      && $migrated['height'] === $heldBefore['height'] && $migrated['family'] === $heldBefore['family']);
check('and both phones still hear that it was withdrawn',
      ($reopened->offers()->touching([$oldTheirs], $now + 60)[0] ?? null) === [
          'seed' => '', 'to' => $oldTheirs, 'from' => '', 'state' => Offers::WITHDRAWN,
          'offeredAt' => $now, 'answeredAt' => $now + 50,
      ]);
$snapshot = static fn (PDO $db) => [
    $db->query('SELECT * FROM long_walk ORDER BY arrival')->fetchAll(PDO::FETCH_ASSOC),
    $db->query('SELECT * FROM walk_offers ORDER BY offer')->fetchAll(PDO::FETCH_ASSOC),
];
$once = $snapshot($reDb);
unset($reopened, $reDb);
$third = WalkStore::open('sqlite:' . $legacyFile);
check('and running it again changes nothing', $snapshot($third->connection()) === $once);
unset($third);
@unlink($legacyFile);

@unlink($file);

if ($failures > 0) {
    fwrite(STDERR, "\n$failures checks failed.\n");
    exit(1);
}
fwrite(STDOUT, "\nThe asking holds: nothing reaches the walk unasked.\n");
