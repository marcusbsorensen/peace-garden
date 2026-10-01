<?php
declare(strict_types=1);

/**
 * The service's one key for fingerprints, and the fingerprints made under it.
 *
 * **One key, two users.** `Offers.php` minted it on 24 September for the
 * fingerprints a withdrawn offer keeps of its seed and tokens; since 1 October
 * 2026 the Wild Fields' names (`WildStore.php`) make theirs under it too,
 * rather than under a second key that a backup could carry without the first.
 * It is one row in `offer_key`, minted on first use and kept in the nightly
 * copy, because a restored table of fingerprints is no use without it.
 *
 * **What a fingerprint does.** HMAC-SHA256 under that key, so it hides nothing
 * from somebody holding the whole database; what it does is keep the values
 * themselves out of it. A token is sixteen random bytes, so its fingerprint can
 * confirm a token somebody already holds and cannot give one back.
 */
final class Keyed
{
    /// What starts every fingerprint. Seeds and tokens are lowercase hex,
    /// which has no `h`, so a fingerprint is never taken for either.
    public const MARK = 'h';

    /** The key, minted once and kept in `offer_key`. */
    public static function key(PDO $db): string
    {
        $db->prepare('CREATE TABLE IF NOT EXISTS offer_key (id INTEGER PRIMARY KEY, hmac_key CHAR(64) NOT NULL)')
           ->execute();
        $query = $db->prepare('SELECT hmac_key FROM offer_key WHERE id = 1');
        $query->execute();
        if ($key = $query->fetchColumn()) return (string) $key;

        try {
            $insert = $db->prepare('INSERT INTO offer_key (id, hmac_key) VALUES (1, ?)');
            $insert->execute([bin2hex(random_bytes(32))]);
        } catch (PDOException) {
            // Another request minted it a moment ago; the read below returns it.
        }
        $query->execute();
        return (string) $query->fetchColumn();
    }

    /**
     * A fingerprint of `$value` in `$domain`, `MARK` and `$length` hex
     * characters. The domain keeps a value fingerprinted for one purpose from
     * matching the same value fingerprinted for another.
     */
    public static function print(string $key, string $domain, string $value, int $length = 32): string
    {
        return self::MARK . substr(hash_hmac('sha256', $domain . "\0" . $value, $key), 0, $length);
    }
}
