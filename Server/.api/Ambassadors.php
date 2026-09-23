<?php
declare(strict_types=1);

require_once __DIR__ . '/Areas.php';
require_once __DIR__ . '/LongWalk.php';
require_once __DIR__ . '/QuietGarden.php';
require_once __DIR__ . '/Crossing.php';
require_once __DIR__ . '/Orchard.php';
require_once __DIR__ . '/KnotGarden.php';
require_once __DIR__ . '/Seedbed.php';

/**
 * The ten plants that stand for the ten areas, as the plot service knows them.
 *
 * A port of `SeedCore`'s `Ambassadors` (`WebGardens/Ambassadors.swift`), which
 * is where the reasoning lives, and held to it by
 * `tools/reference/check_ambassador.php`.
 *
 * **Why the service holds any of this.** An ambassador is a real plant grown
 * from a real seed, and only a grown plant can say how tall it is and what
 * colour it flowers. The service is PHP: it cannot grow one. So the two numbers
 * the placement rule needs are pinned here beside the seed, recorded from the
 * Swift into `tools/reference/ambassador_vectors.json`, and the check script
 * fails CI if this file says anything else.
 *
 * **The placement itself is derived, not pinned.** Given the seed, the height
 * and the family, `LongWalk::plant` into an empty walk gives the slot and the
 * nudge, and gives the same ones every time. Pinning the slot as well would be
 * a second copy of an answer the port already has, and a second copy is a thing
 * that can disagree.
 *
 * **Nothing here is a row.** An ambassador is not a shared plant: nobody
 * offered it, nobody can answer for it, and nobody can take it back. So it is
 * not in the table of plants people offered. `WalkStore` hands it to the rule
 * ahead of the stored arrivals and serves it with the plot, and there is no
 * row anywhere for a withdrawal or a report to reach.
 */
final class Ambassadors
{
    /**
     * Each area's plant: the pinned seed, and the two facts about the grown
     * plant that a placement rule needs. All ten, though nine of the areas are
     * shut, for the same reason SeedCore pins all ten — the area that opens
     * next should not have to go looking for its plant.
     */
    public const ALL = [
        // The Seedbed reads a third fact, and only the Seedbed does: a plant's
        // epithet, which is what claims a drill. It is pinned here beside the
        // other two for the same reason they are — the service cannot grow the
        // plant to read the name off it.
        'beginnings' => ['seed' => '526ffb12041c8641eead7cb97614517436806c5748c3f581754dd102738719ae',
                         'height' => 1.095889687538147, 'family' => 4,
                         'kind' => 'angustifolia'],  // Verora angustifolia
        'waiting' => ['seed' => '8c0992d3e4221b40489b83d05c0ec3131fc8c771365970ffbb1354a93431ff3f',
                      'height' => 0.6767851710319519, 'family' => 4],  // Nyxisora crassicaulis
        'renewal' => ['seed' => 'c295b64b290a2e9b3c6ece6c70dafb1816205f60f42a0663e47bfb738b30d292',
                      'height' => 0.9952253103256226, 'family' => 3],  // Rosea caerulea
        'light' => ['seed' => '53b234ab46f50e06243314d3d6159c67d0b26b2c0bc44a5fcd4b83ad28c4bc41',
                    'height' => 0.6757330298423767, 'family' => 0],  // Aurea pallida
        'pattern' => ['seed' => '75121838c745b4c11d8c34bdf4492890833a1a8ca768942ef26cbbbba7a74b7b',
                      'height' => 1.006360411643982, 'family' => 4],  // Quina caerulea
        'ground' => ['seed' => '540d870092386fc9a3e5611499390c1de91fbadddf276bc6ef6eec73dc30326d',
                     'height' => 1.1019959449768066, 'family' => 6],  // Fenunora patentifolia
        'travel' => ['seed' => 'be9dd17805ea1ebab2c56695b13158adb8d985f165564c10804961b543c12d3c',
                     'height' => 1.0231088399887085, 'family' => 3],  // Halula crassicaulis
        'meeting' => ['seed' => '9bca751433cf86be586c46b3b6582a504fb4df133036321ce000f066e13d7284',
                      'height' => 0.6093385815620422, 'family' => 5],  // Melyrina latifolia
        'kinship' => ['seed' => 'ec0850ec7cd6824077a0c51e3c4c8cc670b321bdf66b8eb8f338fff81deb6bf3',
                      'height' => 1.3274011611938477, 'family' => 0],  // Cyninora contorta
        'peace' => ['seed' => '2d1894df5b3f19d3d1c4a12cae8e8d7334a07f942ba60903d37846a190faa4eb',
                    'height' => 0.7478628754615784, 'family' => 1],  // Olyne paniculata
    ];

    /** The day all ten were sown, a month before the garden opened. */
    public const SOWN = 1787184000;

    public static function seed(string $area): string
    {
        return self::ALL[$area]['seed'] ?? '';
    }

    /**
     * Whether this seed is one of the ten.
     *
     * Asked of every arrival. A seed with no parents cannot be crossed into
     * existence, so an offer carrying one could only be somebody trying it on —
     * but the service takes parentage on trust, so trying it on is exactly what
     * it cannot rule out. Refusing the ten by name is one comparison, and it is
     * what makes *nobody put an ambassador there and nobody can take it away*
     * true rather than merely unlikely.
     */
    public static function isOne(string $seed): bool
    {
        foreach (self::ALL as $one) {
            if (hash_equals($one['seed'], $seed)) return true;
        }
        return false;
    }

    /**
     * Where an area's ambassador stands, by that area's own rule.
     *
     * **The answer's shape is the area's, not a shared one.** A Long Walk
     * planting names a side of a path and a tier of a border; a Quiet Garden
     * planting names a corner of a room and a place in a group of three. That
     * is the same reason each area has a table of its own rather than a shared
     * one with an area column, and it is why this returns the area's own array
     * rather than something flattened to fit both.
     *
     * The areas with no rule get nothing, because a placement invented for one
     * of them would be a promise about a layout nobody has designed.
     */
    public static function planting(string $area): ?array
    {
        static $placed = [];
        if (array_key_exists($area, $placed)) return $placed[$area];
        $one = self::ALL[$area] ?? null;
        if ($one === null) return $placed[$area] = null;
        return $placed[$area] = match ($area) {
            'travel' => LongWalk::plant([], $one['seed'], $one['height'], $one['family']),
            'meeting' => Crossing::plant([], $one['seed'], $one['height'], $one['family']),
            'peace' => QuietGarden::plant([], $one['seed'], $one['height'], $one['family']),
            'kinship' => Orchard::plant([], $one['seed'], $one['height'], $one['family']),
            'pattern' => KnotGarden::plant([], $one['seed'], $one['height'], $one['family']),
            'beginnings' => Seedbed::plant([], $one['seed'], $one['height'], $one['family'], $one['kind']),
            default => null,
        };
    }
}
