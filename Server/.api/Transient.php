<?php
declare(strict_types=1);

/**
 * A database refusal that goes away if asked again, and asking again
 * (14 October 2026).
 *
 * **Why.** MariaDB settles two transactions that wait on each other by
 * killing one of them — `SQLSTATE 40001`, error 1213, *Deadlock found* — and
 * says so expecting the caller to run it again: the transaction was rolled
 * back whole, so nothing it wrote is left. Until today the service answered
 * those with a 500, and two phones writing for the first time in the same
 * moment met them on the rate-limit table (0.8 % of every request in the
 * population test, design/mass-test-2026-10-13/population/README.md, finding
 * 2). SQLite's equivalent is a busy database.
 *
 * **What is retried, and only that.** A deadlock, and on SQLite a database
 * busy or locked; with `$duplicates`, also a duplicate key, for the one place
 * where two first writes of the same key racing is the expected case and the
 * second should simply count again. Anything else is a real answer and is
 * thrown at once.
 *
 * **Bounded, with jitter.** Four tries in all. Before each retry it sleeps a
 * few milliseconds, more each time and never the same for two requests, so two
 * that collided once do not collide again in step.
 */
final class Transient
{
    public const TRIES = 4;

    /**
     * Runs `$work` until it returns, retrying a transient refusal up to
     * `TRIES` times in all. `$work` must leave nothing behind when it throws:
     * a transaction rolled back, or a single statement.
     */
    public static function retry(callable $work, bool $duplicates = false): mixed
    {
        for ($try = 1; ; $try++) {
            try {
                return $work();
            } catch (PDOException $refusal) {
                if ($try >= self::TRIES || !self::is($refusal, $duplicates)) throw $refusal;
                usleep(random_int(2_000, 12_000) * $try);
            }
        }
    }

    /** Whether asking again could get a different answer. */
    public static function is(PDOException $refusal, bool $duplicates = false): bool
    {
        $state = (string) ($refusal->errorInfo[0] ?? $refusal->getCode());
        $code = (int) ($refusal->errorInfo[1] ?? 0);
        if ($state === '40001' || $code === 1213) return true;                       // deadlock
        if ($duplicates && ($state === '23000' && ($code === 1062 || $code === 19))) return true;   // duplicate key
        // SQLite: SQLITE_BUSY (5) and SQLITE_LOCKED (6), reported as HY000.
        if ($state === 'HY000' && ($code === 5 || $code === 6)) return true;
        return false;
    }
}
