<?php
declare(strict_types=1);

require_once __DIR__ . '/WalkStore.php';

/**
 * The asking: one gardener offers a plant to the Long Walk, and the other says
 * yes or no.
 *
 * **Why there is an asking at all.** A plant made at a meeting is grown from
 * its child seed, both parents' seeds and the meeting's ID, so showing it on
 * the web publishes the other gardener's seed as well (WEBSITE.md, amended 18
 * September). It is not one person's to publish.
 *
 * **What stands in for an account.** Each phone mints sixteen random bytes in
 * its card at the meeting and receives the other's, so a crossing leaves a pair
 * of tokens held by exactly those two phones. An offer is addressed to the
 * token its recipient minted; only that phone can answer it. The service ends
 * up holding a bag of offers keyed by opaque bytes and no directory of people
 * at all — it never learns a name, an address or that two offers concern the
 * same pair of gardeners.
 *
 * **What a token does not prove.** It carries consent, not authenticity: the
 * service cannot tell two tokens minted at a real meeting from two minted by
 * one person on one machine, so it cannot tell a real pair of gardeners from
 * somebody planting their own invented crossings. What it does guarantee is
 * that nobody can plant *somebody else's* plant, or answer for them, because
 * the address is a secret only those two phones hold. Spam is an abuse-control
 * problem and belongs in front of the service, not in this file.
 *
 * **One offer per plant**, which is what makes a decline final: there is one
 * invitation, and declining it is the block (WEBSITE.md, *Deliberately not
 * settings*).
 */
final class Offers
{
    public const OFFERED = 'offered';
    public const ACCEPTED = 'accepted';
    public const DECLINED = 'declined';
    public const WITHDRAWN = 'withdrawn';

    public function __construct(private PDO $db, private WalkStore $walk)
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
        $id = $sqlite ? 'INTEGER PRIMARY KEY AUTOINCREMENT' : 'BIGINT PRIMARY KEY AUTO_INCREMENT';
        // The plant's own fields are kept only while the offer is open. Once it
        // is answered they go: an accepted plant is in the walk and does not
        // need to be here twice, and a declined one should not be anywhere.
        // What stays is the seed, the two tokens and the answer, so both phones
        // can learn what happened without the service keeping the refusal's
        // subject matter.
        $this->run("CREATE TABLE IF NOT EXISTS walk_offers (
            offer $id,
            seed CHAR(64) NOT NULL UNIQUE,
            token_to CHAR(32) NOT NULL,
            token_from CHAR(32) NOT NULL,
            parent_a CHAR(64) NULL,
            parent_b CHAR(64) NULL,
            encounter CHAR(64) NULL,
            height DOUBLE PRECISION NULL,
            family INTEGER NULL,
            state VARCHAR(16) NOT NULL,
            offered_at BIGINT NOT NULL,
            answered_at BIGINT NULL
        )");
        $this->run('CREATE INDEX IF NOT EXISTS walk_offers_to ON walk_offers (token_to)');
        $this->run('CREATE INDEX IF NOT EXISTS walk_offers_from ON walk_offers (token_from)');
        // Added on 21 September, when the garden had a second area to be
        // offered a plant for, so it is an ALTER that may already have run.
        // Every offer made before it was for the Long Walk, which is what the
        // default says, and an offer answered after it is planted where its own
        // area's rule says. The column stays after the answer, unlike the
        // plant's own fields: it is where to look for the planting, not
        // anything about the plant.
        try {
            $this->run("ALTER TABLE walk_offers ADD COLUMN area VARCHAR(16) NOT NULL DEFAULT 'travel'");
        } catch (Throwable) {
            // Already there.
        }
        // Added on 23 September, when the Seedbed opened and a placement needed
        // a third fact about the plant. Another ALTER that may already have run,
        // and the reason it defaults to the empty string rather than being NULL:
        // an offer made before this migration is answered after it, and the
        // empty kind is the one the rule already understands. So an offer in
        // flight across the deploy still plants — into the drill of unnamed
        // plants, which is what a plant whose phone never sent an epithet is.
        //
        // Unlike `area`, this one is dropped when the offer is answered. It is a
        // fact about the plant rather than about where to find the planting, so
        // it belongs with the parents, the height and the family in `settle`.
        try {
            $this->run("ALTER TABLE walk_offers ADD COLUMN kind VARCHAR(64) NOT NULL DEFAULT ''");
        } catch (Throwable) {
            // Already there.
        }
        // Added on 24 September, when the Glasshouse opened and a placement
        // needed a fourth fact: the flower's hue. Another ALTER that may already
        // have run, and **nullable where `kind` is not**, because there is no
        // hue that means *none* the way the empty string is the empty kind. An
        // offer made before the migration and answered after it plants with a
        // null hue, which the Glasshouse reads as it reads a pale flower: any
        // free pot on the staging.
        //
        // Dropped when the offer is answered, as `kind` is: a fact about the
        // plant, not about where to find the planting.
        try {
            $this->run('ALTER TABLE walk_offers ADD COLUMN hue DOUBLE PRECISION NULL');
        } catch (Throwable) {
            // Already there.
        }
    }

    /**
     * Offers one plant, addressed to the token the other gardener minted.
     *
     * Returns [the offer as the phone should see it, whether it is new]. A
     * second offer of the same plant is not a second invitation: the phone is
     * handed the one that already exists, whatever state it is in.
     *
     * `$kind` is the plant's epithet, kept for the same reason its height and
     * its colour family are: the plant is planted when the *other* gardener
     * answers, which may be days later, and nothing at that moment can grow it
     * again to read the name off it. An offer made without one carries the empty
     * kind, which is what an older app sends.
     *
     * `$hue` is kept for the same reason, and null when an older app sent none.
     */
    public function offer(string $seed, string $to, string $from, string $parentA, string $parentB,
                          string $encounter, float $height, int $family, int $now,
                          string $area = 'travel', string $kind = '', ?float $hue = null): array
    {
        if ($existing = $this->find($seed)) {
            // **Only to the two who met.** A second offer of one plant is
            // answered with the first — which is how a retry, or the other
            // phone offering the same child, learns where it stands — but the
            // answer carries both tokens, and either token can withdraw. An
            // accepted plant's seed is public at `/api/<area>/plot/<n>`, so
            // until 24 September anybody could offer a published plant with two
            // invented tokens, be handed the real pair, and take it down. The
            // pair asked with has to be the pair stored, in either order.
            if (!self::samePair($existing, $to, $from)) return [null, false];
            return [self::seen($existing), false];
        }
        $insert = $this->db->prepare('INSERT INTO walk_offers
            (seed, token_to, token_from, parent_a, parent_b, encounter, height, family, state, offered_at, area, kind, hue)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
        try {
            $insert->execute([$seed, $to, $from, $parentA, $parentB, $encounter, $height, $family,
                              self::OFFERED, $now, $area, $kind, GlasshouseStore::exactly($hue)]);
        } catch (PDOException $clash) {
            // Two offers of one plant, racing. The unique seed settles it and
            // the loser is handed the winner, which is the same answer it would
            // have had a moment earlier.
            if ($row = $this->find($seed)) {
                return self::samePair($row, $to, $from) ? [self::seen($row), false] : [null, false];
            }
            throw $clash;
        }
        return [self::seen($this->find($seed) ?? []), true];
    }

    /**
     * Everything touching these tokens, in either direction: offers made *to*
     * this phone, and the state of offers made *from* it.
     *
     * One request rather than two, because a phone holds one token per meeting
     * and asks about all of them at once — and because the switch that turns
     * this off (`sharing.invitations.v1`) has to turn off *the request*, not a
     * banner. Off means the service is never told this phone exists.
     */
    public function touching(array $tokens): array
    {
        if ($tokens === []) return [];
        $marks = implode(',', array_fill(0, count($tokens), '?'));
        $query = $this->db->prepare(
            "SELECT * FROM walk_offers WHERE token_to IN ($marks) OR token_from IN ($marks) ORDER BY offer"
        );
        $query->execute([...$tokens, ...$tokens]);
        return array_map([self::class, 'seen'], $query->fetchAll());
    }

    /**
     * The other gardener's answer. `$to` is the token the offer was addressed
     * to, which only they hold, and is the whole of the proof that it is theirs
     * to answer.
     *
     * Yes plants it by the rule and returns the planting. No is final for this
     * plant: there is one offer per plant and no second one can be made.
     */
    public function answer(string $seed, string $to, bool $yes, int $now): ?array
    {
        $row = $this->find($seed);
        if ($row === null || !hash_equals((string) $row['token_to'], $to)) return null;
        if ($row['state'] !== self::OFFERED) return ['offer' => self::seen($row), 'planting' => null];

        if (!$yes) {
            $this->settle($seed, self::DECLINED, $now);
            return ['offer' => self::seen($this->find($seed) ?? []), 'planting' => null];
        }

        [$planting] = $this->walk->plantInto(
            (string) ($row['area'] ?? 'travel'),
            $seed, (string) $row['parent_a'], (string) $row['parent_b'], (string) $row['encounter'],
            (float) $row['height'], (int) $row['family'], (string) ($row['kind'] ?? ''),
            isset($row['hue']) ? (float) $row['hue'] : null
        );
        $this->settle($seed, self::ACCEPTED, $now);
        return ['offer' => self::seen($this->find($seed) ?? []), 'planting' => $planting];
    }

    /**
     * Taken back by whichever gardener holds one of its tokens.
     *
     * **Either of them, at any time, without the other.** An offer still
     * waiting simply goes. One already accepted leaves its planting in the walk
     * — the walk is append-only and nothing in it ever moves — but the planting
     * is hidden, so the slot stays empty, which is what a plant lifted out of a
     * border leaves behind. A consent that cannot be withdrawn is not worth
     * much, and this is the whole of what withdrawing means here.
     */
    public function withdraw(string $seed, string $token, int $now): ?array
    {
        $row = $this->find($seed);
        if ($row === null) return null;
        if (!hash_equals((string) $row['token_to'], $token)
            && !hash_equals((string) $row['token_from'], $token)) return null;

        if ($row['state'] === self::ACCEPTED) {
            $this->walk->hideIn((string) ($row['area'] ?? 'travel'), $seed);
        }
        $this->settle($seed, self::WITHDRAWN, $now);
        return self::seen($this->find($seed) ?? []);
    }

    private function find(string $seed): ?array
    {
        $query = $this->db->prepare('SELECT * FROM walk_offers WHERE seed = ?');
        $query->execute([$seed]);
        $row = $query->fetch();
        return $row === false ? null : $row;
    }

    /** Settles an offer and drops the plant it carried. */
    private function settle(string $seed, string $state, int $now): void
    {
        // `kind` goes back to the empty string rather than to NULL, because the
        // column is NOT NULL — it is the same erasure the nullable fields get.
        $update = $this->db->prepare("UPDATE walk_offers SET state = ?, answered_at = ?,
            parent_a = NULL, parent_b = NULL, encounter = NULL, height = NULL, family = NULL,
            kind = '', hue = NULL
            WHERE seed = ?");
        $update->execute([$state, $now, $seed]);
    }

    /**
     * What a phone is told about an offer.
     *
     * The tokens go back so a phone can tell which of its plants an offer is
     * about without the service being told which plants it holds — it asked
     * with a bag of tokens and gets answers keyed the same way. The plant's
     * parents and traits never go back: the phone that made the offer has them
     * already, and the phone being asked grew the plant itself.
     */
    /// Whether `$to` and `$from` are this offer's two tokens, in either order:
    /// the phone that offered sends them one way round, and the other phone,
    /// offering the same child, sends them the other.
    private static function samePair(array $row, string $to, string $from): bool
    {
        $stored = [(string) $row['token_to'], (string) $row['token_from']];
        return (hash_equals($stored[0], $to) && hash_equals($stored[1], $from))
            || (hash_equals($stored[0], $from) && hash_equals($stored[1], $to));
    }

    private static function seen(array $row): array
    {
        return [
            'seed' => $row['seed'] ?? null,
            'to' => $row['token_to'] ?? null,
            'from' => $row['token_from'] ?? null,
            'state' => $row['state'] ?? null,
            'offeredAt' => isset($row['offered_at']) ? (int) $row['offered_at'] : null,
            'answeredAt' => isset($row['answered_at']) ? (int) $row['answered_at'] : null,
        ];
    }
}
