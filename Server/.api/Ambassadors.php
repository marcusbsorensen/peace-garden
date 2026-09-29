<?php
declare(strict_types=1);

require_once __DIR__ . '/Areas.php';
require_once __DIR__ . '/LongWalk.php';
require_once __DIR__ . '/QuietGarden.php';
require_once __DIR__ . '/Crossing.php';
require_once __DIR__ . '/Orchard.php';
require_once __DIR__ . '/KnotGarden.php';
require_once __DIR__ . '/Seedbed.php';
require_once __DIR__ . '/ColdFrame.php';
require_once __DIR__ . '/Glasshouse.php';
require_once __DIR__ . '/Coppice.php';
require_once __DIR__ . '/HomeGround.php';

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
     * plant that a placement rule needs. All ten, and all ten open.
     */
    public const ALL = [
        // The Seedbed reads a third fact, and only the Seedbed does: a plant's
        // epithet, which is what claims a drill. It is pinned here beside the
        // other two for the same reason they are — the service cannot grow the
        // plant to read the name off it.
        //
        // Since 25 September the Seedbed and the Cold Frame read the habit as
        // well, and ask one thing of it: whether a plant wants water, and
        // whether it is a lotus, which takes two places. The Seedbed's is a
        // spire, dry, and takes one; the Cold Frame's is a lotus, so it opens
        // the tank, where every place is one.
        //
        // **Six of the ten are new since 28 September 2026**, when fourteen
        // families re-dealt every plant's name and the same search found these
        // (`Ambassadors.seeds` in the Swift says which, and why). The Seedbed's,
        // the Cold Frame's and the Home Ground's are the plants they were — the
        // Seedbed's spire 0.09 m shorter, since spires flower from below — and
        // the Orchard's seed grows a vine where it grew a thistle.
        'beginnings' => ['seed' => '526ffb12041c8641eead7cb97614517436806c5748c3f581754dd102738719ae',
                         'height' => 1.004594326019287, 'family' => 4,
                         'kind' => 'angustifolia', 'habit' => 'spire'],  // Verora angustifolia
        'waiting' => ['seed' => '8c0992d3e4221b40489b83d05c0ec3131fc8c771365970ffbb1354a93431ff3f',
                      'height' => 0.30920299887657166, 'family' => 4,
                      'habit' => 'lotus'],  // Nyxisora crassicaulis
        // The Coppice reads a fifth, and only the Coppice does: the plant's
        // habit, its archetype's name, which says whether it stands on a stool.
        // This one is a fern, so it takes the first coupe's middle stool.
        'renewal' => ['seed' => '751caa28cd3debc0889cf2e3753bb08227f73c28344bcbdb152676e4e6ba5ad3',
                      'height' => 0.5046804547309875, 'family' => 6,
                      'habit' => 'fern'],  // Drosula vulgaris
        // The Glasshouse reads a fourth, and only the Glasshouse does: the
        // flower's hue, as a turn of the circle, which is what stands a pot at
        // its place in the staging's spectrum. Pinned for the same reason —
        // though this one, at 1.45 m, is over the border's cut and is planted
        // in the soil, where the hue is not asked.
        'light' => ['seed' => 'cb56d4faf696980777ee2fa626c4d21a8c6313e77360a7c51af1050de37546af',
                    'height' => 1.4487090110778809, 'family' => 4,
                    'hue' => 0.8310607398530679],  // Elora elata
        'pattern' => ['seed' => '2db9895507d76284f916bfb86161bf11979ad6b908317fced3453dff915613cf',
                      'height' => 1.2213140726089478, 'family' => 4],  // Quinyria obscura
        // The Home Ground reads the habit too, and to other ends: it names the
        // crop, and the crop claims a bed. This one is an umbel over the
        // umbel's cut, so it opens the west bed at its north end.
        'ground' => ['seed' => '540d870092386fc9a3e5611499390c1de91fbadddf276bc6ef6eec73dc30326d',
                     'height' => 1.1002660989761353, 'family' => 6,
                     'habit' => 'umbel'],  // Fenunora patentifolia
        'travel' => ['seed' => '53b234ab46f50e06243314d3d6159c67d0b26b2c0bc44a5fcd4b83ad28c4bc41',
                     'height' => 0.5241280794143677, 'family' => 0],  // Zephea pallida
        'meeting' => ['seed' => '4e8ae3205804ca5b4da57110894e26ad8a9f28c97d33de28358f9fb2410cf80a',
                      'height' => 1.1962966918945312, 'family' => 4],  // Ithula obscura
        'kinship' => ['seed' => 'ec0850ec7cd6824077a0c51e3c4c8cc670b321bdf66b8eb8f338fff81deb6bf3',
                      'height' => 1.9295012950897217, 'family' => 0],  // Vininora contorta
        'peace' => ['seed' => '75121838c745b4c11d8c34bdf4492890833a1a8ca768942ef26cbbbba7a74b7b',
                    'height' => 1.0573713779449463, 'family' => 4],  // Bela caerulea
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
     * A name that is not an area gets nothing. Until the Home Ground opened,
     * on 24 September, a shut area got nothing too, because a placement
     * invented for one would have been a promise about a layout nobody had
     * designed; all ten have a rule now.
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
            'beginnings' => Seedbed::plant([], $one['seed'], $one['height'], $one['family'], $one['kind'],
                                           $one['habit']),
            'waiting' => ColdFrame::plant([], $one['seed'], $one['height'], $one['family'], $one['habit']),
            'light' => Glasshouse::plant([], $one['seed'], $one['height'], $one['family'], $one['hue']),
            'renewal' => Coppice::plant([], $one['seed'], $one['height'], $one['family'], $one['habit']),
            'ground' => HomeGround::plant([], $one['seed'], $one['height'], $one['family'], $one['habit']),
            default => null,
        };
    }
}
