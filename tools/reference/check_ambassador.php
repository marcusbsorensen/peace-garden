<?php
declare(strict_types=1);

/**
 * The service's ambassadors are SeedCore's ambassadors, and the one standing in
 * the Long Walk stands where the Swift put it.
 *
 * `tools/reference/ambassador_vectors.json` is what `Ambassadors` in SeedCore
 * says: the ten pinned seeds, in the areas' declared order, each with the two
 * facts a placement rule needs about the grown plant — its height and its
 * flower's colour family. The service cannot grow a plant to find those out, so
 * it holds them as constants, and constants drift. This fails if
 * `Server/.api/Ambassadors.php` says anything else.
 *
 * **The placement is derived on both sides, not pinned on either.** The Swift
 * plants the travel ambassador into an empty walk and records where it landed;
 * this plants it into an empty walk with the PHP port of the same rule and
 * checks it lands in the same slot with the same nudge. A slot that is pinned
 * twice is two answers; a slot that is derived twice is one rule, checked.
 *
 * **And it checks that the walk fills around it.** The service hands the
 * ambassador to the rule ahead of every stored arrival, so it is standing there
 * when anything else is placed. If it were ever handed over afterwards, or left
 * out, the border would be graded against a plant that is drawn and not there.
 *
 *   php tools/reference/check_ambassador.php
 */

require_once __DIR__ . '/../../Server/.api/Ambassadors.php';
require_once __DIR__ . '/../../Server/.api/QuietGarden.php';
require_once __DIR__ . '/../../Server/.api/ColdFrame.php';
require_once __DIR__ . '/../../Server/.api/Glasshouse.php';

$vectors = json_decode(
    file_get_contents(__DIR__ . '/ambassador_vectors.json'), true, 512, JSON_THROW_ON_ERROR
);

$checks = 0;
$failed = [];

function is_same(string $what, mixed $swift, mixed $php): void
{
    global $checks, $failed;
    $checks++;
    if ($swift !== $php) {
        $failed[] = sprintf('%s: SeedCore says %s, the service says %s',
            $what, json_encode($swift), json_encode($php));
    }
}

is_same('the day they were sown', $vectors['sown'], Ambassadors::SOWN);
is_same('how many there are', count($vectors['ambassadors']), count(Ambassadors::ALL));

// The order matters as much as the contents: `Areas::ALL` is read by index in
// `GET /api/garden`, and an ambassador table in a different order would file
// the Orchard's plant under the Glasshouse without a single value being wrong.
$order = array_keys(Ambassadors::ALL);
foreach ($vectors['ambassadors'] as $n => $row) {
    $area = $row['area'];
    is_same("ambassador $n is the $area one", $area, $order[$n] ?? null);
    $php = Ambassadors::ALL[$area] ?? null;
    is_same("$area's seed", $row['seed'], $php['seed'] ?? null);
    // Exact doubles, not a tolerance. The height decides a tier, and a tier cut
    // at 0.93 m has a plant either side of it: a value near enough for a report
    // is not near enough to place a plant. Both sides parse the same decimal
    // into the same double, so they are either equal or one of them moved.
    is_same("$area's height", $row['height'], $php['height'] ?? null);
    is_same("$area's colour family", $row['family'], $php['family'] ?? null);
    // The hue, where the service pins one — only the Glasshouse's ambassador,
    // because only the Glasshouse reads it. Exact, for the height's reason and
    // one more: a hue is exact on every host, so there is no excuse for it
    // not to be.
    if (isset($php['hue'])) is_same("$area's hue", $row['hue'], $php['hue']);
    // The habit, where the service pins one — only the Coppice's, because
    // only the Coppice reads it. A word, and exact on every host.
    if (isset($php['habit'])) is_same("$area's habit", $row['habit'], $php['habit']);
}

// MARK: The two that are standing in a garden

$pinned = $vectors['longWalk'];
$standing = Ambassadors::planting('travel');

is_same('the Long Walk ambassador\'s seed', $pinned['seed'], $standing['seed']);
is_same('its plot', $pinned['plot'], $standing['plot']);
is_same('its side of the path', $pinned['side'], $standing['side']);
is_same('its tier', $pinned['tier'], $standing['tier']);
is_same('its slot down the walk', $pinned['index'], $standing['index']);
is_same('its nudge', $pinned['nudge'], [$standing['nudgeX'], $standing['nudgeZ']]);

// The second one, whose planting is a different shape because its area is.
$room = $vectors['quietGarden'];
$sitting = Ambassadors::planting('peace');

is_same('the Quiet Garden ambassador\'s seed', $room['seed'], $sitting['seed']);
is_same('its plot', $room['plot'], $sitting['plot']);
is_same('its corner', $room['corner'], $sitting['corner']);
is_same('its place in that corner', $room['index'], $sitting['index']);
is_same('its nudge', $room['nudge'], [$sitting['nudgeX'], $sitting['nudgeZ']]);

// It is beside the bench, which is what a plot's first plant always is — and
// the reason this area could take a 0.75 m ambassador at all. A specimen slot
// at the back of a group would have wanted a plant half as tall again.
is_same('it is the plant beside the bench', QuietGarden::BENCH, $sitting['corner']);

// It stands in its own tier. Said separately because it is the reason there is
// no specimen slot: only one of the ten ambassadors is tall enough for the back
// of a border, so a specimen fixed at the back would stand a short plant behind
// taller ones and break the rule the walk is built on.
is_same('its tier is the tier its height belongs to',
        LongWalk::tier($vectors['ambassadors'][6]['height']), $standing['tier']);

// The Cold Frame's, which opens its area as every other ambassador does: in the
// first place of the first frame of plot 0, and in the rank its grown height
// belongs to. *Nyxisora crassicaulis* grows to 0.68 m, under the 0.85 m cut, so
// the front rank — and the frame it stands in is claimed for its colour before
// anybody has shared anything.
$waiting = Ambassadors::planting('waiting');
is_same('the Cold Frame ambassador\'s plot', 0, $waiting['plot'] ?? null);
is_same('its frame', ColdFrame::BACK_WEST, $waiting['frame'] ?? null);
is_same('its rank is the rank its height belongs to',
        ColdFrame::rank($vectors['ambassadors'][1]['height']), $waiting['rank'] ?? null);
is_same('its place along that rank', 0, $waiting['index'] ?? null);

// The Glasshouse's, which opens the staging at its own place in the spectrum:
// *Aurea pallida* grows to 0.68 m, under the border's 1.30 m, so it is potted,
// and its orange stands it in the tenth band, three from the far end — the
// first pot on the staging, in the row by the glass.
$light = Ambassadors::planting('light');
is_same('the Glasshouse ambassador\'s plot', 0, $light['plot'] ?? null);
is_same('its bed', Glasshouse::STAGING, $light['bed'] ?? null);
is_same('its place is its own band',
        Glasshouse::band($vectors['ambassadors'][3]['hue']), $light['index'] ?? null);
is_same('its row', 0, $light['row'] ?? null);

// The Coppice's, which opens the first coupe's floor: *Rosea caerulea* is a
// star, so it stands in the light and is never cut, and at 1.00 m it stands in
// the front row, in the middle place, which is where a row starts.
$renewal = Ambassadors::planting('renewal');
is_same('the Coppice ambassador\'s plot', 0, $renewal['plot'] ?? null);
is_same('its coupe', 0, $renewal['coupe'] ?? null);
is_same('its place is the row its height asks for',
        Coppice::row($vectors['ambassadors'][2]['height']), $renewal['place'] ?? null);
is_same('the middle of that row', Coppice::FLOOR_ORDER[0], $renewal['index'] ?? null);

// The two that are not open have no placement, because their areas have no
// rule. A placement invented for one of them would be a promise about a layout
// nobody has designed.
foreach (Areas::ALL as $area) {
    if (Areas::isOpen($area)) continue;
    $checks++;
    if (Ambassadors::planting($area) !== null) {
        $failed[] = "$area has no rule and the service placed its ambassador anyway";
    }
}

// And every area that *is* open has its ambassador standing in it. The day a
// third opens, this is what says its plant was never put in.
foreach (Areas::OPEN as $area) {
    $checks++;
    if (Ambassadors::planting($area) === null) {
        $failed[] = "$area is open and its ambassador is not standing in it";
    }
}

// MARK: The walk fills around it

$walk = [$standing];
$arrivals = json_decode(
    file_get_contents(__DIR__ . '/long_walk_vectors.json'), true, 512, JSON_THROW_ON_ERROR
);
foreach (array_slice($arrivals, 0, 200) as $arrival) {
    $placed = LongWalk::plant($walk, $arrival['seed'], $arrival['height'], $arrival['family']);
    $checks++;
    if ($placed['plot'] === $standing['plot'] && $placed['side'] === $standing['side']
        && $placed['tier'] === $standing['tier'] && $placed['index'] === $standing['index']) {
        $failed[] = sprintf('%s was planted on top of the ambassador', $arrival['seed']);
    }
    $walk[] = $placed;
}

$checks++;
if ($walk[0] !== $standing) {
    $failed[] = 'the ambassador moved while the walk filled';
}

// MARK: Nobody can plant one

foreach ($vectors['ambassadors'] as $row) {
    $checks++;
    if (!Ambassadors::isOne($row['seed'])) {
        $failed[] = sprintf('%s is an ambassador and the service does not know it', $row['area']);
    }
}
foreach ([$arrivals[0]['seed'], str_repeat('0', 64), ''] as $notOne) {
    $checks++;
    if (Ambassadors::isOne($notOne)) {
        $failed[] = sprintf('%s is not an ambassador and the service says it is', json_encode($notOne));
    }
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about the ambassadors:\n");
    foreach ($failed as $line) {
        fwrite(STDERR, "  $line\n");
    }
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter AmbassadorTests, or fix Server/.api/Ambassadors.php to match it.\n");
    exit(1);
}

printf("Ten ambassadors — %s at the head of the walk, %s at the crossing, "
     . "%s under the middle tree, %s beside the bench, %s in the knot, "
     . "%s in the first frame, %s on the staging — and the service agrees: %d checks.\n",
    $vectors['ambassadors'][6]['name'], $vectors['ambassadors'][7]['name'],
    $vectors['ambassadors'][8]['name'], $vectors['ambassadors'][9]['name'],
    $vectors['ambassadors'][4]['name'], $vectors['ambassadors'][1]['name'],
    $vectors['ambassadors'][3]['name'], $checks);
