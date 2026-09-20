<?php
declare(strict_types=1);

/**
 * The service's ten areas are SeedCore's ten areas.
 *
 * `tools/reference/area_vectors.json` is what `Area` in SeedCore says — the
 * areas, their order, which are open, and what each open one's plantings are
 * called. This fails if `Server/.api/Areas.php` says anything else.
 *
 * **Why the order is checked too.** `GET /api/garden` answers the list in this
 * order and a reader that takes the fifth entry to mean travel would be reading
 * a different area the day two lists disagree. The order is the app's
 * `Quotes.Theme` declaration order, which is neither alphabetical nor the map's
 * layout, so nothing about it can be rederived by guessing.
 *
 *   php tools/reference/check_areas.php
 */

require_once __DIR__ . '/../../Server/.api/Areas.php';

$vectors = json_decode(
    file_get_contents(__DIR__ . '/area_vectors.json'), true, 512, JSON_THROW_ON_ERROR
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

is_same('the number of areas', count($vectors), count(Areas::ALL));

foreach ($vectors as $n => $row) {
    $area = $row['area'];
    is_same("area $n", $area, Areas::ALL[$n] ?? null);
    is_same("$area is open", $row['open'], Areas::isOpen($area));
    is_same("$area's table", $row['table'], Areas::table($area));
}

// The list the service answers with, whole: every area named once, in order,
// with its standing — which is the shape a phone reads and is therefore worth
// checking as a shape rather than only field by field.
$answered = array_map(
    static fn(array $a): array => ['area' => $a['area'], 'open' => $a['open']],
    Areas::all()
);
$expected = array_map(
    static fn(array $r): array => ['area' => $r['area'], 'open' => $r['open']],
    $vectors
);
is_same('what GET /api/garden answers', $expected, $answered);

// An area that is not one of the ten is not an area, whatever it is spelled
// like. The refusal matters more than the acceptance: it is what stops a
// caller filing a plant under a name the garden has never heard of.
foreach (['orangery', 'Travel', 'travel ', '', 'long_walk'] as $notAnArea) {
    $checks++;
    if (Areas::exists($notAnArea)) {
        $failed[] = sprintf('%s is not one of the ten and the service took it',
            json_encode($notAnArea));
    }
}

// And an area that exists but is shut is not open. Said separately because the
// two questions have different answers for nine of the ten, and a port that
// confused them would open the whole garden.
foreach (Areas::ALL as $area) {
    $checks++;
    if (!Areas::exists($area)) {
        $failed[] = "$area is in the list and does not exist";
    }
}

if ($failed !== []) {
    fwrite(STDERR, "The service and SeedCore disagree about the garden:\n");
    foreach ($failed as $line) {
        fwrite(STDERR, "  $line\n");
    }
    fwrite(STDERR, "\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test\n"
                 . "--filter AreaVectorTests, or fix Server/.api/Areas.php to match it.\n");
    exit(1);
}

printf("The garden is ten areas, %s open, and the service agrees: %d checks.\n",
    implode(' and ', Areas::OPEN), $checks);
