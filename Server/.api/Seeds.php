<?php
declare(strict_types=1);

/**
 * The one piece of SeedCore's derivation the plot service needs: whether a
 * child seed is the cross of two parents at one meeting.
 *
 * It is what stops a made-up seed being planted in the walk: a planting names
 * its parents and the meeting, and the service checks the child is what they
 * make. `Seeds::cross` is SeedCore's `Pollination.cross` over `seedDigest`, and
 * `tools/reference/check_long_walk.php` holds it to DerivationVectorTests'
 * pinned child.
 */
final class Seeds
{
    public const CROSS = 'peacegarden.cross.v1';

    /** 64 lowercase hex characters: a seed, or a meeting's ID. */
    public static function isHex32(mixed $value): bool
    {
        return is_string($value) && preg_match('/\A[0-9a-f]{64}\z/', $value) === 1;
    }

    /** 32 lowercase hex characters: one of the sixteen-byte tokens a meeting leaves. */
    public static function isHex16(mixed $value): bool
    {
        return is_string($value) && preg_match('/\A[0-9a-f]{32}\z/', $value) === 1;
    }

    /** SHA-256 over the domain, a zero byte, then each part with a big-endian length. */
    public static function digest(string $domain, string ...$parts): string
    {
        $message = $domain . "\0";
        foreach ($parts as $part) $message .= pack('N', strlen($part)) . $part;
        return hash('sha256', $message, true);
    }

    /** The child of two parents at one meeting, as hex. The parents' order does not matter. */
    public static function cross(string $parentAHex, string $parentBHex, string $encounterHex): string
    {
        $a = hex2bin($parentAHex);
        $b = hex2bin($parentBHex);
        [$low, $high] = strcmp($a, $b) < 0 ? [$a, $b] : [$b, $a];
        return bin2hex(self::digest(self::CROSS, $low, $high, hex2bin($encounterHex)));
    }
}
