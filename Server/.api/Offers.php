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
 *
 * **Taking back deletes** (24 September). A withdrawn offer keeps no seed, no
 * parents, no meeting, no traits and no area, and its planting, if it had one,
 * keeps only its place (`TakenBack.php`). What the row does keep is a keyed
 * fingerprint of the seed and of each token, the word `withdrawn` and the two
 * times, because two things still need it:
 *
 *   - **Refusing a re-offer.** While a plant stood in the garden its seed, its
 *     parents and its meeting were public at `/api/<area>/plot/<n>`, and those
 *     three are everything `checkedPlant` asks of an offer. A service that
 *     forgot the plant entirely would let anybody who had read them offer it
 *     again, addressed to a token of their own, answer yes, and plant it back.
 *     The seed's fingerprint is what `offer` finds instead.
 *   - **Answering the two phones.** The phone that did not withdraw learns it
 *     from `pending`, asked with its own token, and either phone may still
 *     answer or withdraw what it believes is waiting. The token fingerprints
 *     are what those requests are matched against, and the answer carries back
 *     only what the asking phone sent: its own token, and the seed when it
 *     named one (`pending` names none, so a withdrawn row comes back from it
 *     with an empty seed and the phone finds its plant by token).
 *
 * A fingerprint is HMAC-SHA256 under a key minted once per install and kept in
 * `offer_key`, beside this table and in the same backups — a restore that lost
 * the key would lose every refusal with it. So it hides nothing from somebody
 * holding the whole database; what it does is keep the seed and the tokens out
 * of it. A seed is 32 random bytes and a token 16, so a fingerprint can confirm
 * one somebody already holds and cannot give one back.
 *
 * **A declined offer is erased the same way** (24 September, Marcus's call). It
 * was never planted, so nothing of it was ever public, but it kept the seed and
 * both tokens in the clear for good. Now it keeps the same fingerprints and the
 * word `declined`, which is still what refuses a second offer and still what
 * both phones are told.
 *
 * **An offer nobody answers lapses after thirty days**, and is then exactly a
 * withdrawn one: same word, same erasure, answered at the moment it lapsed.
 * Checked when the offer is next looked up, swept on every `offer` and
 * `pending` request, and swept every five minutes by `sweep.php` from cron, so an offer
 * waiting on a phone that never asks still goes.
 */
final class Offers
{
    public const OFFERED = 'offered';
    public const ACCEPTED = 'accepted';
    public const DECLINED = 'declined';
    public const WITHDRAWN = 'withdrawn';

    /// How long an offer waits for its answer: thirty days, in seconds.
    public const LAPSES_AFTER = 30 * 86400;

    /// What starts a fingerprint in the seed and token columns. Seeds and
    /// tokens are lowercase hex, which has no `h`, so a fingerprint is never
    /// taken for either and every route refuses one offered as either.
    private const PRINT = 'h';

    private ?string $key = null;

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
        // subject matter — and once it is withdrawn, not even the seed and the
        // tokens, only their fingerprints (`erase`).
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
        // anything about the plant. It goes when the offer is withdrawn, when
        // there is no longer a planting to look for.
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
        // it belongs with the parents, the height and the family in `accept`
        // and `erase`.
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
        // Added on 24 September, with taking back that deletes. The key the
        // fingerprints are made under, one row, minted on first use; and the
        // index the thirty-day sweep reads, so a sweep that finds nothing costs
        // a lookup rather than a pass over every offer ever made.
        $this->run('CREATE TABLE IF NOT EXISTS offer_key (id INTEGER PRIMARY KEY, hmac_key CHAR(64) NOT NULL)');
        $this->run('CREATE INDEX IF NOT EXISTS walk_offers_waiting ON walk_offers (state, offered_at)');
        // **The migration.** An offer withdrawn or declined before today still
        // holds its seed and both tokens in the clear, and this puts them
        // through the same erasure a withdrawal or a decline does now. It runs
        // on every request and finds nothing once it has run: an erased row's
        // seed starts with the fingerprint's letter. It leaves the times and
        // the word alone, so both phones hear the same thing about the offer
        // as before.
        $plain = $this->db->prepare('SELECT * FROM walk_offers WHERE state IN (?, ?) AND seed NOT LIKE ?');
        $plain->execute([self::WITHDRAWN, self::DECLINED, self::PRINT . '%']);
        foreach ($plain->fetchAll() as $row) {
            $this->erase($row, (string) $row['state'], (int) ($row['answered_at'] ?? $row['offered_at']));
        }
    }

    /**
     * Offers one plant, addressed to the token the other gardener minted.
     *
     * Returns [the offer as the phone should see it, whether it is new]. A
     * second offer of the same plant is not a second invitation: the phone is
     * handed the one that already exists, whatever state it is in — a
     * withdrawn or lapsed one included, which is what keeps it withdrawn.
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
        $this->lapse($now);
        $sent = $this->sent($seed, [$to, $from]);
        if ($existing = $this->find($seed, $now)) {
            // **Only to the two who met.** A second offer of one plant is
            // answered with the first — which is how a retry, or the other
            // phone offering the same child, learns where it stands — but the
            // answer carries both tokens, and either token can withdraw. An
            // accepted plant's seed is public at `/api/<area>/plot/<n>`, so
            // until 24 September anybody could offer a published plant with two
            // invented tokens, be handed the real pair, and take it down. The
            // pair asked with has to be the pair stored, in either order.
            if (!$this->samePair($existing, $to, $from)) return [null, false];
            return [$this->seen($existing, $sent), false];
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
            if ($row = $this->find($seed, $now)) {
                return $this->samePair($row, $to, $from) ? [$this->seen($row, $sent), false] : [null, false];
            }
            throw $clash;
        }
        return [$this->seen($this->find($seed, $now) ?? [], $sent), true];
    }

    /**
     * Everything touching these tokens, in either direction: offers made *to*
     * this phone, and the state of offers made *from* it.
     *
     * One request rather than two, because a phone holds one token per meeting
     * and asks about all of them at once — and because the switch that turns
     * this off (`sharing.invitations.v1`) has to turn off *the request*, not a
     * banner. Off means the service is never told this phone exists.
     *
     * A withdrawn offer is found by its tokens' fingerprints and comes back
     * with the tokens this phone asked with and an empty seed: the service no
     * longer has the seed to give, and the phone knows its own plant by the
     * token it minted for that meeting.
     */
    public function touching(array $tokens, int $now): array
    {
        if ($tokens === []) return [];
        $this->lapse($now);
        $sent = $this->sent(null, $tokens);
        $asked = [...$tokens, ...array_keys($sent)];
        $marks = implode(',', array_fill(0, count($asked), '?'));
        $query = $this->db->prepare(
            "SELECT * FROM walk_offers WHERE token_to IN ($marks) OR token_from IN ($marks) ORDER BY offer"
        );
        $query->execute([...$asked, ...$asked]);
        return array_map(fn (array $row) => $this->seen($row, $sent), $query->fetchAll());
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
        $sent = $this->sent($seed, [$to]);
        $row = $this->find($seed, $now);
        if ($row === null || !$this->holds($row, 'token_to', $to)) return null;
        if ($row['state'] !== self::OFFERED) return ['offer' => $this->seen($row, $sent), 'planting' => null];

        if (!$yes) {
            // Declined, and erased as a withdrawal is: the fingerprints and
            // the word are all a refusal needs.
            $this->erase($row, self::DECLINED, $now);
            return ['offer' => $this->seen($this->find($seed, $now) ?? [], $sent), 'planting' => null];
        }

        [$planting] = $this->walk->plantInto(
            (string) ($row['area'] ?? 'travel'),
            $seed, (string) $row['parent_a'], (string) $row['parent_b'], (string) $row['encounter'],
            (float) $row['height'], (int) $row['family'], (string) ($row['kind'] ?? ''),
            isset($row['hue']) ? (float) $row['hue'] : null
        );
        if (!$this->accept($seed, $now)) {
            // The offer changed under this answer — it lapsed in the hourly
            // sweep, or was withdrawn, in the moment between reading it and
            // planting it. It is not the garden's to keep, so the planting
            // just made is taken back at once.
            $this->walk->takeBackIn((string) ($row['area'] ?? 'travel'), $seed);
            $planting = null;
        }
        return ['offer' => $this->seen($this->find($seed, $now) ?? [], $sent), 'planting' => $planting];
    }

    /**
     * Taken back by whichever gardener holds one of its tokens.
     *
     * **Either of them, at any time, without the other.** An offer still
     * waiting goes. One already accepted is taken back out of its area: the
     * area is append-only and nothing in it ever moves, so the planting keeps
     * its place, hidden, as the gap a plant lifted out of a border leaves — and
     * everything else about it is erased, there and here. A consent that
     * cannot be withdrawn is not worth much, and nor is one whose withdrawal
     * leaves the thing consented to on the server.
     *
     * Withdrawing twice is the first withdrawal, returned again, and
     * withdrawing a declined offer is the decline: it is already as settled,
     * and as erased, as a withdrawal would leave it.
     */
    public function withdraw(string $seed, string $token, int $now): ?array
    {
        $sent = $this->sent($seed, [$token]);
        $row = $this->find($seed, $now);
        if ($row === null) return null;
        if (!$this->holds($row, 'token_to', $token) && !$this->holds($row, 'token_from', $token)) return null;
        if ($row['state'] === self::WITHDRAWN || $row['state'] === self::DECLINED) {
            return $this->seen($row, $sent);
        }

        if ($row['state'] === self::ACCEPTED) {
            $this->walk->takeBackIn((string) ($row['area'] ?? 'travel'), $seed);
        }
        $this->erase($row, self::WITHDRAWN, $now);
        return $this->seen($this->find($seed, $now) ?? [], $sent);
    }

    /**
     * The offer for this seed, in the clear or erased. An offer found still
     * waiting past its thirty days lapses here, before anybody is told about
     * it, so no route can answer or be answered with an offer that has gone.
     */
    private function find(string $seed, int $now): ?array
    {
        $query = $this->db->prepare('SELECT * FROM walk_offers WHERE seed IN (?, ?)');
        $query->execute([$seed, $this->seedPrint($seed)]);
        $row = $query->fetch();
        if ($row === false) return null;
        if ($row['state'] === self::OFFERED && (int) $row['offered_at'] + self::LAPSES_AFTER <= $now) {
            $this->erase($row, self::WITHDRAWN, (int) $row['offered_at'] + self::LAPSES_AFTER);
            $query->execute([$seed, $this->seedPrint($seed)]);
            $row = $query->fetch();
            return $row === false ? null : $row;
        }
        return $row;
    }

    /**
     * Settles an offer as accepted, and drops the plant it carried: it is in
     * its area now and does not need to be here twice. The area stays, as
     * where to look for the planting.
     *
     * Only an offer still waiting, so an answer that loses a race with the
     * sweep or a withdrawal changes nothing. Returns whether it was this call
     * that settled it.
     */
    private function accept(string $seed, int $now): bool
    {
        // `kind` goes back to the empty string rather than to NULL, because the
        // column is NOT NULL — it is the same erasure the nullable fields get.
        $update = $this->db->prepare("UPDATE walk_offers SET state = ?, answered_at = ?,
            parent_a = NULL, parent_b = NULL, encounter = NULL, height = NULL, family = NULL,
            kind = '', hue = NULL
            WHERE seed = ? AND state = ?");
        $update->execute([self::ACCEPTED, $now, $seed, self::OFFERED]);
        return $update->rowCount() === 1;
    }

    /**
     * Settles an offer as withdrawn or declined and erases it: the seed and
     * both tokens become their fingerprints, and the plant's fields — the
     * Glasshouse's hue among them — and its area go. `$row` is the row as it
     * was read, in the clear; `$at` is when it was withdrawn, declined, or
     * lapsed.
     *
     * **Only if the row is still as it was read**, which is what makes this
     * safe beside itself. The hourly sweep, a request's own sweep and a phone
     * withdrawing can all reach one offer at once, and a second erasure of a
     * row already erased would fingerprint the fingerprints and lose the offer
     * for good. Matching on the seed and the state as read turns the loser of
     * that race into an update of nothing.
     */
    private function erase(array $row, string $state, int $at): bool
    {
        if (self::isPrint((string) $row['seed'])) return false;
        $update = $this->db->prepare("UPDATE walk_offers SET state = ?, answered_at = ?,
            seed = ?, token_to = ?, token_from = ?,
            parent_a = NULL, parent_b = NULL, encounter = NULL, height = NULL, family = NULL,
            kind = '', hue = NULL, area = ''
            WHERE offer = ? AND seed = ? AND state = ?");
        $update->execute([$state, $at,
                          $this->seedPrint((string) $row['seed']),
                          $this->tokenPrint((string) $row['token_to']),
                          $this->tokenPrint((string) $row['token_from']),
                          $row['offer'], (string) $row['seed'], (string) $row['state']]);
        return $update->rowCount() === 1;
    }

    /**
     * Every offer that has waited thirty days, lapsed. Read through the index
     * on (state, offered_at), so on a day when nothing lapses it is one lookup
     * that finds nothing. Returns how many lapsed, for `sweep.php` to say.
     */
    public function lapse(int $now): int
    {
        $due = $this->db->prepare('SELECT * FROM walk_offers WHERE state = ? AND offered_at <= ?');
        $due->execute([self::OFFERED, $now - self::LAPSES_AFTER]);
        $lapsed = 0;
        foreach ($due->fetchAll() as $row) {
            if ($this->erase($row, self::WITHDRAWN, (int) $row['offered_at'] + self::LAPSES_AFTER)) $lapsed++;
        }
        return $lapsed;
    }

    // MARK: - Fingerprints

    private function seedPrint(string $seed): string
    {
        return self::PRINT . substr(hash_hmac('sha256', "seed\0" . $seed, $this->key()), 0, 63);
    }

    private function tokenPrint(string $token): string
    {
        return self::PRINT . substr(hash_hmac('sha256', "token\0" . $token, $this->key()), 0, 31);
    }

    private static function isPrint(string $value): bool
    {
        return str_starts_with($value, self::PRINT);
    }

    /**
     * What the asking phone sent, keyed so an erased row can be read back in
     * its terms: each token's fingerprint gives the token, and `seed` gives the
     * seed if the request named one.
     */
    private function sent(?string $seed, array $tokens): array
    {
        $sent = [];
        foreach ($tokens as $token) $sent[$this->tokenPrint((string) $token)] = (string) $token;
        if ($seed !== null) $sent['seed'] = $seed;
        return $sent;
    }

    /** Whether `$token` is the one in this column, in the clear or erased. */
    private function holds(array $row, string $column, string $token): bool
    {
        $stored = (string) $row[$column];
        return hash_equals($stored, self::isPrint($stored) ? $this->tokenPrint($token) : $token);
    }

    /**
     * The key, minted once and kept in the database, as the rate limit's salt
     * is and for the same reasons — except that this one is in the backups,
     * because a restored table of fingerprints is no use without it.
     */
    private function key(): string
    {
        if ($this->key !== null) return $this->key;
        $query = $this->db->prepare('SELECT hmac_key FROM offer_key WHERE id = 1');
        $query->execute();
        if ($key = $query->fetchColumn()) return $this->key = (string) $key;

        try {
            $insert = $this->db->prepare('INSERT INTO offer_key (id, hmac_key) VALUES (1, ?)');
            $insert->execute([bin2hex(random_bytes(32))]);
        } catch (PDOException) {
            // Another request minted it a moment ago; the read below returns it.
        }
        $query->execute();
        return $this->key = (string) $query->fetchColumn();
    }

    // MARK: - What a phone is told

    /// Whether `$to` and `$from` are this offer's two tokens, in either order:
    /// the phone that offered sends them one way round, and the other phone,
    /// offering the same child, sends them the other.
    private function samePair(array $row, string $to, string $from): bool
    {
        return ($this->holds($row, 'token_to', $to) && $this->holds($row, 'token_from', $from))
            || ($this->holds($row, 'token_to', $from) && $this->holds($row, 'token_from', $to));
    }

    /**
     * What a phone is told about an offer.
     *
     * The tokens go back so a phone can tell which of its plants an offer is
     * about without the service being told which plants it holds — it asked
     * with a bag of tokens and gets answers keyed the same way. The plant's
     * parents and traits never go back: the phone that made the offer has them
     * already, and the phone being asked grew the plant itself.
     *
     * **An erased offer is told in the asker's own words.** Its seed and tokens
     * are fingerprints, which mean nothing to a phone, so each is replaced by
     * what the request sent that matches it, and by the empty string where the
     * request sent nothing that does. Never null: the phone reads all three as
     * strings, and a null in one row would lose it the whole answer.
     */
    private function seen(array $row, array $sent = []): array
    {
        $said = fn (?string $value) => $value !== null && self::isPrint($value) ? ($sent[$value] ?? '') : $value;
        $seed = $row['seed'] ?? null;
        return [
            'seed' => $seed !== null && self::isPrint((string) $seed) ? ($sent['seed'] ?? '') : $seed,
            'to' => $said(isset($row['token_to']) ? (string) $row['token_to'] : null),
            'from' => $said(isset($row['token_from']) ? (string) $row['token_from'] : null),
            'state' => $row['state'] ?? null,
            'offeredAt' => isset($row['offered_at']) ? (int) $row['offered_at'] : null,
            'answeredAt' => isset($row['answered_at']) ? (int) $row['answered_at'] : null,
        ];
    }
}
