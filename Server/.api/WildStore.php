<?php
declare(strict_types=1);

require_once __DIR__ . '/WildFields.php';
require_once __DIR__ . '/Keyed.php';

/**
 * The Wild Fields, stored: every plant somebody let go, and nothing about the
 * letting go.
 *
 * **What a row keeps:** the plant's seed and its two parents' seeds, which is
 * what a browser needs to grow a hybrid (`docs/WEBSITE.md`, amended 18
 * September), and the tile it stands in, which is its seed read twice
 * (`WildFields::tile`) and is a column only so a page's question — *what stands
 * in this square* — is an index lookup rather than a pass over the field.
 *
 * **What it does not keep, on purpose** (`docs/PHASES.md`: *no name, no sender
 * and no date*): no time, no address, no token, no meeting, no order of
 * arrival. The table has no counter column for that last reason, and on SQLite
 * it is `WITHOUT ROWID`, because SQLite's hidden row number counts up as rows
 * arrive and would be an order of arrival written down by the database rather
 * than by us. On MariaDB the rows are kept in the order of their seeds, which
 * is the order of nothing.
 *
 * **Nothing here is placed against anything else.** Every other area's store
 * takes a lock and reads every arrival before it to place the next one. A
 * released plant's place is its seed's, so there is no lock, no rule run over
 * the field, and two plants released at the same moment cannot collide in any
 * way that matters: if they share a place they stand there together, which
 * the design asks for.
 *
 * **Release is once per plant.** The seed is the key, so a second release of
 * the same plant — a retry after a lost answer, or the other gardener letting
 * go of their own copy — is handed the planting that is already there.
 *
 * **`hidden` is for moderation, and nothing sets it yet.** A field nobody
 * curates still needs a way to take down a plant that should not be standing,
 * and adding the column later would be a migration on a live table. A hidden
 * row stays — it keeps the plant from being released again — and is not drawn.
 *
 * **Who stands beside it, since 1 October 2026** (`wild_names`, Marcus's
 * decision that day). Releasing stays one gardener's act, and the plant still
 * goes into the field at once; but each of the two whose seeds made it may
 * choose to show three things beside it — their gardener name, where they
 * met, and the month they met — and nothing else, no free text. The one who
 * released it chooses as they let go; the other is told on their next
 * `pending` and answers when they like; either changes their answer whenever
 * they like, withdrawing included, without the other.
 *
 *   - **A name is its owner's alone to show.** It is kept in the clear from
 *     the moment its owner chooses it, because it is shown from that moment.
 *   - **The place and the month belong to the meeting both had**, so each is
 *     shown only once both have chosen it — and only if both phones hold the
 *     same account of it. Each phone sends its own words for the place and its
 *     own month, and until both have, what is kept of each is a keyed
 *     fingerprint (`Keyed.php`), which can confirm the other's words are the
 *     same and cannot give them back. When the second agrees and the two
 *     fingerprints match, the words are kept in the clear, because they are
 *     shown. Two phones that remember the place differently show no place: a
 *     place one of them never wrote is not one either agreed to.
 *   - **Only the two token holders answer, each for themselves.** The two
 *     tokens the meeting left are kept as keyed fingerprints, never in the
 *     clear, as a withdrawn offer keeps them. The releaser's phone sends both:
 *     its own, and the one the other phone minted, which is where the other
 *     gardener is reached.
 *   - **Nothing in the row says when or in what order**: no time, no counter,
 *     `WITHOUT ROWID` on SQLite for the reason the field's table is. The two
 *     names are served in alphabetical order, so the page does not say which
 *     of the two let it go.
 */
final class WildStore
{
    public function __construct(private PDO $db)
    {
        $this->migrate();
    }

    private function run(string $sql): void
    {
        $this->db->prepare($sql)->execute();
    }

    private function migrate(): void
    {
        $sqlite = $this->db->getAttribute(PDO::ATTR_DRIVER_NAME) === 'sqlite';
        $order = $sqlite ? ' WITHOUT ROWID' : '';
        $this->run("CREATE TABLE IF NOT EXISTS wild_fields (
            seed CHAR(64) NOT NULL PRIMARY KEY,
            parent_a CHAR(64) NOT NULL,
            parent_b CHAR(64) NOT NULL,
            tile_x INTEGER NOT NULL,
            tile_z INTEGER NOT NULL,
            hidden INTEGER NOT NULL DEFAULT 0
        )$order");
        $this->run('CREATE INDEX IF NOT EXISTS wild_fields_tile ON wild_fields (tile_x, tile_z)');
        // Since 1 October 2026: who stands beside a released plant, by their
        // own choice. `a` is the side of the gardener who released it and `b`
        // the other's. `print_*` are the fingerprints of the two tokens the
        // meeting left; `name_*` a name shown; `place_*` and `month_*` the
        // fingerprints of the place and the month each has chosen, null where
        // they have not; `place` and `month` what is shown, once both chose the
        // same. A row is made only when a plant is released with both tokens,
        // and the field's own table is untouched by it.
        $this->run("CREATE TABLE IF NOT EXISTS wild_names (
            seed CHAR(64) NOT NULL PRIMARY KEY,
            print_a CHAR(33) NOT NULL,
            print_b CHAR(33) NOT NULL,
            name_a VARCHAR(48) NULL,
            name_b VARCHAR(48) NULL,
            place_a CHAR(33) NULL,
            place_b CHAR(33) NULL,
            month_a CHAR(33) NULL,
            month_b CHAR(33) NULL,
            place VARCHAR(64) NULL,
            month CHAR(7) NULL
        )$order");
        $this->run('CREATE INDEX IF NOT EXISTS wild_names_a ON wild_names (print_a)');
        $this->run('CREATE INDEX IF NOT EXISTS wild_names_b ON wild_names (print_b)');
    }

    /**
     * Stands one plant in the field. Returns [the planting, whether it is
     * new]: a plant already released gets the place it already has.
     *
     * The caller has checked that the seed is the cross of the two parents,
     * and has cleared the way with the asking (`Offers::letGo`). Neither is
     * done here, because this class knows nothing about either.
     */
    public function release(string $seed, string $parentA, string $parentB): array
    {
        if ($row = $this->row($seed)) return [self::planting($row), false];
        [$x, $z] = WildFields::tile($seed);
        $insert = $this->db->prepare('INSERT INTO wild_fields (seed, parent_a, parent_b, tile_x, tile_z)
            VALUES (?, ?, ?, ?, ?)');
        try {
            $insert->execute([$seed, $parentA, $parentB, $x, $z]);
        } catch (PDOException $clash) {
            // The same plant released twice at once. The key settles it and the
            // loser is handed the winner, which is what it would have had a
            // moment later.
            if ($row = $this->row($seed)) return [self::planting($row), false];
            throw $clash;
        }
        return [self::planting(['seed' => $seed, 'parent_a' => $parentA, 'parent_b' => $parentB]), true];
    }

    /** Whether this plant has been released, hidden or not. */
    public function holds(string $seed): bool
    {
        return $this->row($seed) !== null;
    }

    /** The planting for this seed, as a page sees it, or null. A hidden one is null. */
    public function find(string $seed): ?array
    {
        $row = $this->row($seed);
        return $row === null || (int) $row['hidden'] !== 0 ? null : self::planting($row);
    }

    /**
     * What stands in one tile, in the order of the seeds — which is no order
     * at all, and is chosen for being one.
     */
    public function tile(int $x, int $z): array
    {
        $query = $this->db->prepare(
            'SELECT f.seed, f.parent_a, f.parent_b, n.name_a, n.name_b, n.place, n.month
             FROM wild_fields f LEFT JOIN wild_names n ON n.seed = f.seed
             WHERE f.tile_x = ? AND f.tile_z = ? AND f.hidden = 0 ORDER BY f.seed'
        );
        $query->execute([$x, $z]);
        return array_map([self::class, 'planting'], $query->fetchAll());
    }

    /**
     * How many plants stand in each tile that has any: `[[x, z, count], …]`.
     *
     * At most sixty-four rows, and what a page opens on: somewhere with a plant
     * in it, rather than a field it would have to search. It is a count and
     * not a map, and nothing draws it as one.
     */
    public function standing(): array
    {
        $query = $this->db->prepare(
            'SELECT tile_x, tile_z, COUNT(*) AS plants FROM wild_fields WHERE hidden = 0
             GROUP BY tile_x, tile_z ORDER BY tile_x, tile_z'
        );
        $query->execute();
        return array_map(fn (array $row) => [(int) $row['tile_x'], (int) $row['tile_z'], (int) $row['plants']],
                         $query->fetchAll());
    }

    private function row(string $seed): ?array
    {
        $query = $this->db->prepare('SELECT f.*, n.name_a, n.name_b, n.place, n.month
            FROM wild_fields f LEFT JOIN wild_names n ON n.seed = f.seed WHERE f.seed = ?');
        $query->execute([$seed]);
        $row = $query->fetch();
        return $row === false ? null : $row;
    }

    /**
     * What a page needs to grow a planting and stand it in its place: the seed,
     * both parents, and the spot, in metres from the field's corner. No plot,
     * because the field has none.
     *
     * **And `shown`, only where somebody chose to show something**: the names
     * in alphabetical order, the place and the month once both chose them. A
     * planting nobody named has no `shown` at all, rather than an empty one,
     * so the plain case is the case the field was built with.
     */
    private static function planting(array $row): array
    {
        $planting = [
            'seed' => $row['seed'],
            'parents' => [$row['parent_a'], $row['parent_b']],
            'spot' => WildFields::spot($row['seed']),
        ];
        $shown = self::shownOf($row);
        if ($shown['names'] !== [] || $shown['place'] !== null || $shown['month'] !== null) {
            $planting['shown'] = $shown;
        }
        return $planting;
    }

    /** What the field shows beside a plant, read off its names row. */
    private static function shownOf(array $row): array
    {
        $names = array_values(array_filter([$row['name_a'] ?? null, $row['name_b'] ?? null],
                                           fn ($name) => $name !== null && $name !== ''));
        sort($names, SORT_STRING);
        return [
            'names' => $names,
            'place' => isset($row['place']) && $row['place'] !== '' ? (string) $row['place'] : null,
            'month' => isset($row['month']) && $row['month'] !== '' ? (string) $row['month'] : null,
        ];
    }

    // MARK: - Who stands beside it

    /**
     * Makes a released plant's names row, with the releaser's choices. Called
     * when the plant first stands: `$token` is the releaser's own token from
     * the meeting and `$theirs` the one the other phone minted.
     *
     * A row already there — the other phone released its copy a moment
     * earlier — is answered for whichever side `$token` is, as `answer` would.
     * Returns what the releaser's phone is told, or null if the row there is
     * not this pair's.
     */
    public function beside(string $seed, string $token, string $theirs, array $shown): ?array
    {
        $key = $this->key();
        try {
            $this->db->prepare('INSERT INTO wild_names (seed, print_a, print_b) VALUES (?, ?, ?)')
                ->execute([$seed, Keyed::print($key, 'wild token', $token),
                           Keyed::print($key, 'wild token', $theirs)]);
        } catch (PDOException) {
            // There already. Answered below for whichever side this is.
        }
        return $this->answer($seed, $token, $shown);
    }

    /**
     * One gardener's answer: what of theirs stands beside the plant. The
     * whole of it each time — `name`, `place` and `month`, each the value to
     * show or null for not — so a change and a withdrawal are one request, and
     * nothing depends on what was said before.
     *
     * Null if the plant has no names row or `$token` is neither of its two:
     * the same answer for both, so the route says nothing about which plants
     * have one.
     */
    public function answer(string $seed, string $token, array $shown): ?array
    {
        $names = $this->names($seed);
        if ($names === null) return null;
        $side = $this->sideOf($names, $token);
        if ($side === null) return null;

        $key = $this->key();
        $place = $shown['place'] ?? null;
        $month = $shown['month'] ?? null;
        $this->db->prepare("UPDATE wild_names SET name_$side = ?, place_$side = ?, month_$side = ? WHERE seed = ?")
            ->execute([
                $shown['name'] ?? null,
                $place === null ? null : Keyed::print($key, 'wild place', $seed . "\0" . $place),
                $month === null ? null : Keyed::print($key, 'wild month', $seed . "\0" . $month),
                $seed,
            ]);
        // **What both chose, in the clear; anything else, nothing.** Worked
        // out after the write and in one statement, so two answers arriving
        // together cannot each miss the other's: whichever runs second sees
        // both fingerprints. Matching fingerprints are matching words, so the
        // words this request carried are the words both chose — and a request
        // that withdrew carries none, and its own fingerprint is null.
        $this->db->prepare('UPDATE wild_names SET
            place = CASE WHEN place_a IS NOT NULL AND place_a = place_b THEN COALESCE(?, place) ELSE NULL END,
            month = CASE WHEN month_a IS NOT NULL AND month_a = month_b THEN COALESCE(?, month) ELSE NULL END
            WHERE seed = ?')->execute([$place, $month, $seed]);
        return $this->seen($this->names($seed) ?? [], $side, $token);
    }

    /**
     * Every names row touching these tokens, as each phone is told it: what
     * it chose, what the other chose, and what the field shows. For `pending`,
     * so a phone hears of a release on the one request it already makes.
     */
    public function touching(array $tokens): array
    {
        if ($tokens === []) return [];
        $key = $this->key();
        $asked = [];
        foreach ($tokens as $token) $asked[Keyed::print($key, 'wild token', (string) $token)] = (string) $token;
        $prints = array_keys($asked);
        $marks = implode(',', array_fill(0, count($prints), '?'));
        $query = $this->db->prepare(
            "SELECT * FROM wild_names WHERE print_a IN ($marks) OR print_b IN ($marks) ORDER BY seed"
        );
        $query->execute([...$prints, ...$prints]);
        $seen = [];
        foreach ($query->fetchAll() as $row) {
            foreach (['a', 'b'] as $side) {
                $token = $asked[(string) $row["print_$side"]] ?? null;
                if ($token !== null) $seen[] = $this->seen($row, $side, $token);
            }
        }
        return $seen;
    }

    /**
     * What one phone is told: the plant, the token it asked with, whether it
     * was the one that released it, its own three choices and the other's,
     * and what the field shows. **The choices are yes or no**, never the words:
     * the phone has its own, and the other's are not shown until both chose.
     */
    private function seen(array $row, string $side, string $token): array
    {
        $other = $side === 'a' ? 'b' : 'a';
        $chose = fn (string $of) => [
            'name' => ($row["name_$of"] ?? null) !== null,
            'place' => ($row["place_$of"] ?? null) !== null,
            'month' => ($row["month_$of"] ?? null) !== null,
        ];
        return [
            'seed' => (string) ($row['seed'] ?? ''),
            'token' => $token,
            'released' => $side === 'a',
            'yours' => $chose($side),
            'theirs' => $chose($other),
            'shown' => self::shownOf($row),
        ];
    }

    private function names(string $seed): ?array
    {
        $query = $this->db->prepare('SELECT * FROM wild_names WHERE seed = ?');
        $query->execute([$seed]);
        $row = $query->fetch();
        return $row === false ? null : $row;
    }

    /** Which side of the row `$token` holds, or null. */
    private function sideOf(array $row, string $token): ?string
    {
        $print = Keyed::print($this->key(), 'wild token', $token);
        if (hash_equals((string) $row['print_a'], $print)) return 'a';
        if (hash_equals((string) $row['print_b'], $print)) return 'b';
        return null;
    }

    private ?string $key = null;

    private function key(): string
    {
        return $this->key ??= Keyed::key($this->db);
    }
}
