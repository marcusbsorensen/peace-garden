<?php
declare(strict_types=1);

require_once __DIR__ . '/WildFields.php';

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
            'SELECT seed, parent_a, parent_b FROM wild_fields WHERE tile_x = ? AND tile_z = ? AND hidden = 0 ORDER BY seed'
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
        $query = $this->db->prepare('SELECT * FROM wild_fields WHERE seed = ?');
        $query->execute([$seed]);
        $row = $query->fetch();
        return $row === false ? null : $row;
    }

    /**
     * What a page needs to grow a planting and stand it in its place: the seed,
     * both parents, and the spot, in metres from the field's corner. No plot,
     * because the field has none.
     */
    private static function planting(array $row): array
    {
        return [
            'seed' => $row['seed'],
            'parents' => [$row['parent_a'], $row['parent_b']],
            'spot' => WildFields::spot($row['seed']),
        ];
    }
}
