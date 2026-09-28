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
    // The habit, where the service pins one — the Coppice's, the Home Ground's,
    // the Seedbed's and the Cold Frame's, because only those four read it. A
    // word, and exact on every host.
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
// at the back of a group would have wanted a plant half as tall again. (Since
// the re-roll of 28 September 2026 it is *Bela caerulea*, 1.06 m, and stands
// beside the bench for the same reason.)
is_same('it is the plant beside the bench', QuietGarden::BENCH, $sitting['corner']);

// It stands in its own tier. Said separately because it is the reason there is
// no specimen slot: three of the ten ambassadors are tall enough for the back
// of a border (one, until 28 September 2026), so a specimen fixed at the back
// would stand a short plant behind taller ones in seven areas of ten and break
// the rule the walk is built on. *Zephea pallida*, 0.52 m, is an edge plant.
is_same('its tier is the tier its height belongs to',
        LongWalk::tier($vectors['ambassadors'][6]['height']), $standing['tier']);

// The Cold Frame's, which opens its area as every other ambassador does: in the
// first place of plot 0 that its rule gives it. *Nyxisora crassicaulis* is a
// lotus, and since the tank was sunk on 27 September a plant that wants water
// goes in the tank and nowhere else, holding one place there: so it opens the
// tank, at the west end of its first row. (Until then it held the first two
// places of the first frame's front rank, and this check said so until 28
// September 2026.)
$waiting = Ambassadors::planting('waiting');
is_same('the Cold Frame ambassador\'s plot', 0, $waiting['plot'] ?? null);
is_same('its frame is the tank', ColdFrame::TANK, $waiting['frame'] ?? null);
is_same('its place along the tank\'s first row', 0, $waiting['index'] ?? null);
is_same('it is a lotus', 'lotus', $vectors['ambassadors'][1]['habit']);
is_same('so it wants water', true, ColdFrame::wantsWater($vectors['ambassadors'][1]['habit']));
is_same('and holds one place in it', 1, $waiting['span'] ?? null);

// The Glasshouse's, which opens the border: *Elora elata*, since 28 September
// 2026, grows to 1.45 m, over the border's 1.14 m, so it is planted in the
// soil rather than potted, in the border's first place from the door, and the
// staging opens empty. (*Aurea pallida*, 0.74 m, opened the staging at its own
// band.)
$light = Ambassadors::planting('light');
is_same('the Glasshouse ambassador\'s plot', 0, $light['plot'] ?? null);
is_same('its bed is the bed its height belongs to',
        Glasshouse::bed($vectors['ambassadors'][3]['height']), $light['bed'] ?? null);
is_same('which is the border', Glasshouse::BORDER, $light['bed'] ?? null);
is_same('its place is first from the door', 0, $light['index'] ?? null);
is_same('its row', 0, $light['row'] ?? null);

// The Coppice's, which opens the first coupe: *Drosula vulgaris*, since 28
// September 2026, is a fern, so it takes a stool — the first coupe's middle
// one, which is where a fern opens a plot — and it is cut with its coupe.
// (*Rosea caerulea* was a star, in the front row's middle place, never cut.)
$renewal = Ambassadors::planting('renewal');
is_same('the Coppice ambassador\'s plot', 0, $renewal['plot'] ?? null);
is_same('its coupe', 0, $renewal['coupe'] ?? null);
is_same('it is a fern', true, Coppice::isFern($vectors['ambassadors'][2]['habit']));
is_same('so its place is a stool', Coppice::STOOL, $renewal['place'] ?? null);
is_same('the middle stool', Coppice::STOOL_ORDER[0], $renewal['index'] ?? null);

// The Home Ground's, which opens the west bed for umbels: *Fenunora
// patentifolia* is 1.100 m, over the umbel's cut, so it takes the first place
// from the north end — the north-west corner of plot 0, the head of the garden.
$ground = Ambassadors::planting('ground');
$groundRow = array_values(array_filter($vectors['ambassadors'], fn($r) => $r['area'] === 'ground'))[0];
is_same('the Home Ground ambassador\'s plot', 0, $ground['plot'] ?? null);
is_same('its bed', 0, $ground['bed'] ?? null);
is_same('its crop is the one its habit names', HomeGround::crop($groundRow['habit']), $ground['crop'] ?? null);
is_same('and its genus root', $groundRow['genusHead'], $ground['crop'] ?? null);
is_same('the north end, for its height', 0, $ground['index'] ?? null);

// An area that is not open has no placement, because it has no rule. A
// placement invented for one would be a promise about a layout nobody has
// designed. None is shut since the Home Ground opened; this stays for the day
// one is.
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
     . "%s in the tank, %s in the border — and the service agrees: %d checks.\n",
    $vectors['ambassadors'][6]['name'], $vectors['ambassadors'][7]['name'],
    $vectors['ambassadors'][8]['name'], $vectors['ambassadors'][9]['name'],
    $vectors['ambassadors'][4]['name'], $vectors['ambassadors'][1]['name'],
    $vectors['ambassadors'][3]['name'], $checks);
