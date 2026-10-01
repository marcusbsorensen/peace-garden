<?php
declare(strict_types=1);

require_once __DIR__ . '/Ambassadors.php';
require_once __DIR__ . '/Areas.php';
require_once __DIR__ . '/LongWalk.php';
require_once __DIR__ . '/RoomStore.php';
require_once __DIR__ . '/CrossStore.php';
require_once __DIR__ . '/OrchardStore.php';
require_once __DIR__ . '/KnotStore.php';
require_once __DIR__ . '/SeedbedStore.php';
require_once __DIR__ . '/ColdFrameStore.php';
require_once __DIR__ . '/GlasshouseStore.php';
require_once __DIR__ . '/CoppiceStore.php';
require_once __DIR__ . '/HomeGroundStore.php';
require_once __DIR__ . '/WildStore.php';
require_once __DIR__ . '/Offers.php';
require_once __DIR__ . '/TakenBack.php';

/**
 * The Long Walk, stored: every planting in the order it arrived, never changed.
 *
 * **Append-only.** There is an insert and nothing else; a plant's place is
 * decided once, by `LongWalk::plant`, and kept. Arrivals are placed one at a
 * time under a lock, because two placed at once could both take the same slot.
 *
 * **What a planting keeps:** the child seed, both parents' seeds and the
 * meeting's ID (a hybrid cannot be grown from less; WEBSITE.md, amended 18
 * September), its slot, the height and colour family the rule placed it by,
 * and its nudge. No account, no address, no time: the order of the rows is the
 * order of arrival, and nothing else about the arrival is written down.
 *
 * **Until it is taken back.** Then the row keeps its place and the two traits
 * the rule reads, and its seed, parents, meeting and nudge are written over
 * (`TakenBack.php`). It stays, hidden, because the rule placed everything after
 * it by it.
 *
 * **The ambassador is not in it.** *Halula crassicaulis* stands at the head of
 * plot 0 and has done since before the walk had a row in it, but nobody offered
 * it and nobody can take it back, so it is not in the table of plants people
 * offered. `Ambassadors::planting('travel')` derives its slot from the pinned
 * seed, and this class puts it in front of the rule when placing and in front
 * of a plot when serving one. Nothing about it is stored, so there is no row
 * for `takeBack` to reach and none for a backup to carry.
 *
 * PDO, so it runs on SQLite locally and on the 20i database once there is one.
 * Every statement with a value in it is prepared; the fixed ones run as they are.
 */
final class WalkStore
{
    /**
     * What a planting taken back has written over, beyond what every area
     * writes over. Nothing: the walk's rule reads the height (a border is
     * graded by it) and the family (a drift is made of it), and it reads them
     * of every plant in a plot, so both stay.
     */
    private const TAKEN_BACK = [];

    private function __construct(private PDO $db) {}

    public static function open(string $dsn, ?string $user = null, ?string $password = null): self
    {
        $db = new PDO($dsn, $user, $password, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_STRINGIFY_FETCHES => false,
        ]);
        $store = new self($db);
        $store->migrate();
        // The other areas' tables too, rather than when somebody first asks
        // for them. They cost one `CREATE TABLE IF NOT EXISTS` a request, and a
        // table that does not exist until the first visitor is a table the
        // nightly copy does not know to keep.
        $store->room();
        $store->cross();
        $store->orchard();
        $store->knot();
        $store->seedbed();
        $store->coldFrame();
        $store->glasshouse();
        $store->coppice();
        $store->homeGround();
        // And the Wild Fields', which is not an area and has no rule to run,
        // for the same reason: it is in the nightly copy's list.
        $store->wild();
        // And the asking's, for the same reason and one more: `offer_key` is
        // in the nightly copy's list, and mysqldump refuses a list naming a
        // table that is not there. Its migration is also the one that erases
        // what an offer withdrawn or declined before 24 September still held,
        // and this is what makes that happen on the first request after a
        // deploy, whatever that request is for.
        $store->offers();
        return $store;
    }

    private function run(string $sql): void
    {
        $this->db->prepare($sql)->execute();
    }

    private function migrate(): void
    {
        $sqlite = $this->db->getAttribute(PDO::ATTR_DRIVER_NAME) === 'sqlite';
        $id = $sqlite ? 'INTEGER PRIMARY KEY AUTOINCREMENT' : 'BIGINT PRIMARY KEY AUTO_INCREMENT';
        // DOUBLE, because the rule compares heights and a stored height must
        // come back the same double it went in as.
        $this->run("CREATE TABLE IF NOT EXISTS long_walk (
            arrival $id,
            seed CHAR(64) NOT NULL UNIQUE,
            parent_a CHAR(64) NOT NULL,
            parent_b CHAR(64) NOT NULL,
            encounter CHAR(64) NOT NULL,
            plot INTEGER NOT NULL,
            side INTEGER NOT NULL,
            tier INTEGER NOT NULL,
            slot_index INTEGER NOT NULL,
            height DOUBLE PRECISION NOT NULL,
            family INTEGER NOT NULL,
            nudge_x DOUBLE PRECISION NOT NULL,
            nudge_z DOUBLE PRECISION NOT NULL
        )");
        $this->run('CREATE INDEX IF NOT EXISTS long_walk_plot ON long_walk (plot)');
        // Added after the table was live, so it is an ALTER that may already
        // have run. A planting taken back is hidden rather than deleted: the
        // walk is append-only and nothing in it moves, so the row stays, keeps
        // its slot, and simply is not drawn. The border is left with a gap,
        // which is what lifting a plant out of one leaves.
        try {
            $this->run('ALTER TABLE long_walk ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0');
        } catch (Throwable) {
            // Already there.
        }
        // Added on 24 September, when taking back began to delete: the rows
        // hidden before then still hold the seed, the parents and the meeting,
        // and this erases them. It runs every request and finds nothing once
        // it has run once; the index is what keeps that finding cheap.
        $this->run('CREATE INDEX IF NOT EXISTS long_walk_hidden ON long_walk (hidden)');
        TakenBack::sweep($this->db, 'long_walk', self::TAKEN_BACK);
        // One row, written first in every arrival's transaction: the write lock
        // that keeps two arrivals from being placed against the same walk.
        $this->run('CREATE TABLE IF NOT EXISTS long_walk_lock (id INTEGER PRIMARY KEY, arrivals INTEGER NOT NULL)');
        $this->run('INSERT INTO long_walk_lock (id, arrivals) SELECT 1, 0 WHERE NOT EXISTS (SELECT 1 FROM long_walk_lock)');
    }

    /**
     * Places one arrival by the rule and keeps it. Returns [the planting, whether
     * it is new]: a seed that has arrived before gets the place it already has,
     * because a plant has one place.
     *
     * `$kind` is the Seedbed's trait and nothing here reads it; it is in the
     * signature so `plantInto` can call every area's `plant` alike.
     */
    public function plant(string $seed, string $parentA, string $parentB, string $encounter,
                          float $height, int $family, string $kind = ''): array
    {
        // **Never an ambassador.** Unreachable from any route today: the offer
        // and plant routes both check that the seed is the cross of its two
        // parents at their meeting, and an ambassador is minted rather than
        // crossed, so no caller can produce parents that hash to one. This is
        // what keeps it unreachable the day somebody adds a route that plants a
        // minted seed. It is a bug and not a refusal, so it is thrown.
        if (Ambassadors::isOne($seed)) {
            throw new LogicException('an ambassador cannot be planted: it is already standing');
        }

        $this->db->beginTransaction();
        try {
            $this->run('UPDATE long_walk_lock SET arrivals = arrivals + 1 WHERE id = 1');
            $existing = $this->db->prepare('SELECT * FROM long_walk WHERE seed = ?');
            $existing->execute([$seed]);
            if ($row = $existing->fetch()) {
                $this->db->rollBack();
                return [self::planting($row), false];
            }
            $all = $this->db->prepare('SELECT * FROM long_walk ORDER BY arrival');
            $all->execute();
            // **The ambassador first, then the arrivals.** It is standing in
            // plot 0 whether or not anything else is, so the rule has to see it:
            // a plant graded against a border that is missing its oldest plant
            // is graded against a border that is not there. It is prepended
            // rather than stored, because its slot is a pure function of its
            // pinned seed and comes back the same every time it is asked for.
            $walk = array_merge(
                [Ambassadors::planting('travel')],
                array_map([self::class, 'forRule'], $all->fetchAll())
            );
            $p = LongWalk::plant($walk, $seed, $height, $family);
            $insert = $this->db->prepare('INSERT INTO long_walk
                (seed, parent_a, parent_b, encounter, plot, side, tier, slot_index, height, family, nudge_x, nudge_z)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $insert->execute([$seed, $parentA, $parentB, $encounter, $p['plot'], $p['side'], $p['tier'],
                              $p['index'], $height, $family, $p['nudgeX'], $p['nudgeZ']]);
            $this->db->commit();
            return [self::planting(['seed' => $seed, 'parent_a' => $parentA, 'parent_b' => $parentB,
                'encounter' => $encounter, 'plot' => $p['plot'], 'side' => $p['side'], 'tier' => $p['tier'],
                'slot_index' => $p['index'], 'nudge_x' => $p['nudgeX'], 'nudge_z' => $p['nudgeZ']]), true];
        } catch (Throwable $error) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $error;
        }
    }

    /**
     * A plot's plantings, in the order they arrived. Hidden ones are not in it.
     *
     * Plot 0 opens with the ambassador, which arrived before all of them and is
     * not a row. It carries no parents and no meeting, because it has neither:
     * a reader grows it from its seed alone rather than from a lineage, and an
     * empty `parents` is how it says so without a new field on the wire.
     */
    public function plot(int $plot): array
    {
        $query = $this->db->prepare('SELECT * FROM long_walk WHERE plot = ? AND hidden = 0 ORDER BY arrival');
        $query->execute([$plot]);
        $plantings = array_map([self::class, 'planting'], $query->fetchAll());
        $standing = $plot === 0 ? Ambassadors::planting('travel') : null;
        if ($standing === null) return $plantings;
        [$x, $z] = LongWalk::spot($standing['side'], $standing['tier'], $standing['index']);
        array_unshift($plantings, [
            'seed' => $standing['seed'],
            'parents' => [],
            'encounter' => null,
            'plot' => 0,
            'spot' => [$x + $standing['nudgeX'], $z + $standing['nudgeZ']],
        ]);
        return $plantings;
    }

    /**
     * Takes a planting back: out of the drawing, and its seed, parents, meeting
     * and nudge out of the database.
     *
     * The row stays and keeps its slot, its height and its family, so nothing
     * already placed moves and nothing new is placed where it stood. `plant`
     * still reads it, which is the point: the rule saw it when it placed
     * everything around it, and a rule that stopped seeing it would be a
     * different rule. `TakenBack.php` says what is kept and why.
     */
    public function takeBack(string $seed): void
    {
        TakenBack::lift($this->db, 'long_walk', self::TAKEN_BACK, $seed);
    }

    /** The asking that decides what ever reaches the walk. */
    public function offers(): Offers
    {
        return new Offers($this->db, $this);
    }

    /// The same connection, for the parts of the service that keep their own
    /// tables beside the walk rather than in it.
    public function connection(): PDO { return $this->db; }

    /**
     * The Quiet Garden, on the same connection.
     *
     * **This class has outgrown its name**, which is a thing worth saying
     * rather than quietly fixing: it opened the database for a service that was
     * only the Long Walk, and now it holds the connection for a garden with
     * all ten areas in it. Renaming it means touching every
     * caller and the reference checks in one go, which is a commit of its own
     * and not this one. `Offers` and `Limits` already reach through it the same
     * way.
     */
    public function room(): RoomStore
    {
        static $room = null;
        return $room ??= new RoomStore($this->db);
    }

    /** The Crossing, on the same connection. */
    public function cross(): CrossStore
    {
        static $cross = null;
        return $cross ??= new CrossStore($this->db);
    }

    /** The Orchard, on the same connection. */
    public function orchard(): OrchardStore
    {
        static $orchard = null;
        return $orchard ??= new OrchardStore($this->db);
    }

    /** The Knot Garden, on the same connection. */
    public function knot(): KnotStore
    {
        static $knot = null;
        return $knot ??= new KnotStore($this->db);
    }

    /** The Seedbed, on the same connection. */
    public function seedbed(): SeedbedStore
    {
        static $seedbed = null;
        return $seedbed ??= new SeedbedStore($this->db);
    }

    /** The Cold Frame, on the same connection. */
    public function coldFrame(): ColdFrameStore
    {
        static $coldFrame = null;
        return $coldFrame ??= new ColdFrameStore($this->db);
    }

    /** The Glasshouse, on the same connection. */
    public function glasshouse(): GlasshouseStore
    {
        static $glasshouse = null;
        return $glasshouse ??= new GlasshouseStore($this->db);
    }

    /** The Coppice, on the same connection. */
    public function coppice(): CoppiceStore
    {
        static $coppice = null;
        return $coppice ??= new CoppiceStore($this->db);
    }

    /** The Home Ground, on the same connection. */
    public function homeGround(): HomeGroundStore
    {
        static $homeGround = null;
        return $homeGround ??= new HomeGroundStore($this->db);
    }

    /**
     * The Wild Fields, on the same connection. Not an area: nothing in it is
     * placed by a rule against anything else, so it has no `plant` and is not
     * in `plantInto`. A plant reaches it by being released (`router.php`).
     */
    public function wild(): WildStore
    {
        static $wild = null;
        return $wild ??= new WildStore($this->db);
    }

    /**
     * Plants one arrival into whichever area it belongs to.
     *
     * The one place that knows an area's name maps to a table. Everything above
     * it — the asking, the routes — carries the area as a word and never a
     * table, so an area that opens is a case here rather than a change
     * everywhere.
     *
     * **`$kind` is the Seedbed's alone.** It is a plant's epithet, and the sixth
     * area is the only one whose rule reads it: a drill is claimed by the kind
     * of the first plant sown in it. Every area's `plant` takes it so that this
     * can hand the same arguments to any of them; the other six ignore it, as
     * they ignore nothing else they are given. Absent means the empty kind,
     * which is what a plant offered before the epithet went on the wire has.
     *
     * **`$hue` is the Glasshouse's alone**, and handed to it alone: the flower's
     * hue as a turn of the circle, which stands a pot at its place in the
     * staging's spectrum. Null means it was never sent — a plant offered before
     * 24 September — and the Glasshouse reads that as it reads a pale flower.
     *
     * **`$habit` is the Coppice's, the Home Ground's, the Seedbed's and the Cold
     * Frame's**, and handed to those four alone: the plant's archetype, which
     * says whether it stands on a stool, which crop it is, and — since 25
     * September — whether it is a lotus, which takes two places in a drill or a
     * rank. Empty means it was never sent; the Coppice reads that as a star, in
     * the light and never cut, the Home Ground sows it as an umbel, and the
     * other two give it one place.
     *
     * **An area missing from this `match` is not refused: it falls to the Long
     * Walk and says nothing.** So each area that opens is a case here the day it
     * opens, and `check_offers.php` has a block for it that would catch the
     * plant turning up in the walk instead.
     */
    public function plantInto(string $area, string $seed, string $parentA, string $parentB,
                              string $encounter, float $height, int $family, string $kind = '',
                              ?float $hue = null, string $habit = ''): array
    {
        return match ($area) {
            'peace' => $this->room()->plant($seed, $parentA, $parentB, $encounter, $height, $family,
                                            $kind, $hue, $habit),
            'meeting' => $this->cross()->plant($seed, $parentA, $parentB, $encounter, $height, $family, $kind),
            'kinship' => $this->orchard()->plant($seed, $parentA, $parentB, $encounter, $height, $family, $kind),
            'pattern' => $this->knot()->plant($seed, $parentA, $parentB, $encounter, $height, $family, $kind),
            'beginnings' => $this->seedbed()->plant($seed, $parentA, $parentB, $encounter, $height, $family,
                                                    $kind, $hue, $habit),
            'waiting' => $this->coldFrame()->plant($seed, $parentA, $parentB, $encounter, $height, $family,
                                                   $kind, $hue, $habit),
            'light' => $this->glasshouse()->plant($seed, $parentA, $parentB, $encounter, $height, $family,
                                                  $kind, $hue),
            'renewal' => $this->coppice()->plant($seed, $parentA, $parentB, $encounter, $height, $family,
                                                 $kind, $hue, $habit),
            'ground' => $this->homeGround()->plant($seed, $parentA, $parentB, $encounter, $height, $family,
                                                   $kind, $hue, $habit),
            default => $this->plant($seed, $parentA, $parentB, $encounter, $height, $family, $kind),
        };
    }

    /** Takes a planting back, in whichever area holds it. */
    public function takeBackIn(string $area, string $seed): void
    {
        if ($area === 'peace') { $this->room()->takeBack($seed); return; }
        if ($area === 'meeting') { $this->cross()->takeBack($seed); return; }
        if ($area === 'kinship') { $this->orchard()->takeBack($seed); return; }
        if ($area === 'pattern') { $this->knot()->takeBack($seed); return; }
        if ($area === 'beginnings') { $this->seedbed()->takeBack($seed); return; }
        if ($area === 'waiting') { $this->coldFrame()->takeBack($seed); return; }
        if ($area === 'light') { $this->glasshouse()->takeBack($seed); return; }
        if ($area === 'renewal') { $this->coppice()->takeBack($seed); return; }
        if ($area === 'ground') { $this->homeGround()->takeBack($seed); return; }
        $this->takeBack($seed);
    }

    /**
     * Plots opened. Never fewer than one: the walk opened with its ambassador
     * in plot 0, so there has been somewhere to walk since before anybody
     * shared anything.
     */
    public function plots(): int
    {
        $query = $this->db->prepare('SELECT COALESCE(MAX(plot) + 1, 0) FROM long_walk');
        $query->execute();
        return max(1, (int) $query->fetchColumn());
    }

    /** What the page needs to grow a planting and stand it in its place. */
    private static function planting(array $row): array
    {
        [$x, $z] = LongWalk::spot((int) $row['side'], (int) $row['tier'], (int) $row['slot_index']);
        return [
            'seed' => $row['seed'],
            'parents' => [$row['parent_a'], $row['parent_b']],
            'encounter' => $row['encounter'],
            'plot' => (int) $row['plot'],
            'spot' => [$x + (float) $row['nudge_x'], $z + (float) $row['nudge_z']],
        ];
    }

    private static function forRule(array $row): array
    {
        return [
            'seed' => $row['seed'], 'plot' => (int) $row['plot'], 'side' => (int) $row['side'],
            'tier' => (int) $row['tier'], 'index' => (int) $row['slot_index'],
            'height' => (float) $row['height'], 'family' => (int) $row['family'],
        ];
    }
}
