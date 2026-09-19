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
 *   - a withdrawn plant leaves the walk alone and its slot empty.
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

$now = 1_700_000_000;

// MARK: An offer plants nothing

$one = crossing(1);
$mine = token('one/mine');
$theirs = token('one/theirs');
[$offer, $new] = $offers->offer($one['seed'], $theirs, $mine, $one['a'], $one['b'], $one['encounter'], 1.1, 2, $now);

check('an offer is new the first time', $new === true);
check('an offer starts out waiting', $offer['state'] === Offers::OFFERED);
check('an offer plants nothing', $walk->plots() === 0);

// MARK: Who can see it, and who cannot

check('the gardener it was sent to finds it', count($offers->touching([$theirs])) === 1);
check('the gardener who sent it sees its state', count($offers->touching([$mine])) === 1);
check('a stranger finds nothing', $offers->touching([token('somebody else')]) === []);
check('no tokens asks nothing', $offers->touching([]) === []);
check('what comes back carries no seeds but its own',
      array_keys($offers->touching([$theirs])[0]) === ['seed', 'to', 'from', 'state', 'offeredAt', 'answeredAt']);

// MARK: Only the gardener it was addressed to can answer

check('the wrong token cannot answer', $offers->answer($one['seed'], token('wrong'), true, $now) === null);
check('the gardener who sent it cannot answer for the other', $offers->answer($one['seed'], $mine, true, $now) === null);
check('and none of that planted anything', $walk->plots() === 0);

// MARK: Yes plants it

$answered = $offers->answer($one['seed'], $theirs, true, $now + 60);
check('yes plants it', $answered !== null && $answered['planting'] !== null);
check('it stands in the walk', count($walk->plot(0)) === 1);
check('the plant in the walk is the one offered', $walk->plot(0)[0]['seed'] === $one['seed']);
check('the offer is settled', $answered['offer']['state'] === Offers::ACCEPTED);
check('and says when', $answered['offer']['answeredAt'] === $now + 60);

$settled = $offers->touching([$theirs])[0];
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

check('no plants nothing', $no['planting'] === null && count($walk->plot(0)) === 1);
check('no is recorded', $no['offer']['state'] === Offers::DECLINED);
[$third, $thirdNew] = $offers->offer($two['seed'], $theirs2, $mine2, $two['a'], $two['b'], $two['encounter'], 0.6, 4, $now);
check('a declined plant cannot be offered again', $thirdNew === false && $third['state'] === Offers::DECLINED);
check('answering a settled offer changes nothing',
      $offers->answer($two['seed'], $theirs2, true, $now)['planting'] === null);
check('and it is still not in the walk', count($walk->plot(0)) === 1);

// MARK: Taking it back

$three = crossing(3);
$mine3 = token('three/mine');
$theirs3 = token('three/theirs');
$offers->offer($three['seed'], $theirs3, $mine3, $three['a'], $three['b'], $three['encounter'], 1.6, 1, $now);
$offers->answer($three['seed'], $theirs3, true, $now);
check('two plants stand in the walk', count($walk->plot(0)) === 2);
$stoodAt = null;
foreach ($walk->plot(0) as $p) if ($p['seed'] === $three['seed']) $stoodAt = $p['spot'];

$taken = $offers->withdraw($three['seed'], $mine3, $now + 120);
check('the gardener who shared it can take it back', $taken !== null && $taken['state'] === Offers::WITHDRAWN);
check('it is no longer drawn', count($walk->plot(0)) === 1);
check('and the one beside it is untouched', $walk->plot(0)[0]['seed'] === $one['seed']);

// The slot it had is not handed to the next arrival: the walk is append-only
// and the rule still sees it, so a border keeps the gap.
$four = crossing(4);
[$planted] = $walk->plant($four['seed'], $four['a'], $four['b'], $four['encounter'], 1.6, 1);
check('a withdrawn plant keeps its slot', $stoodAt !== null && $planted['spot'] !== $stoodAt);
$standing = array_map(fn ($p) => $p['spot'], $walk->plot(0));
check('nothing is planted on top of it', count($standing) === count(array_unique(array_map('json_encode', $standing))));

$stranger = $offers->withdraw($one['seed'], token('nobody'), $now);
check('a stranger cannot take back somebody else\'s plant', $stranger === null);
check('an offer that does not exist cannot be withdrawn',
      $offers->withdraw(hash('sha256', 'never offered'), $mine, $now) === null);

@unlink($file);

if ($failures > 0) {
    fwrite(STDERR, "\n$failures checks failed.\n");
    exit(1);
}
fwrite(STDOUT, "\nThe asking holds: nothing reaches the walk unasked.\n");
