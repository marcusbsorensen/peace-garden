<?php
declare(strict_types=1);

/**
 * The migration, run by hand: every table, column, character set and data
 * migration the code expects, whatever the database's version says
 * (14 October 2026).
 *
 *   php ~/public_html/.api/migrate.php
 *
 * **When.** The first request after a deploy migrates by itself when the code's
 * schema version is newer than the database's (`Schema.php`), so this is never
 * needed for the service to work. It is for three moments:
 *
 *   - **Straight after a deploy that raised the version**, so the migration
 *     runs here, where its output can be read, rather than inside whichever
 *     visitor's request came first.
 *   - **After restoring a copy taken before 14 October 2026**, which has no
 *     line telling the next request to migrate (`backup.php`): this erases what
 *     the older copy brought back and claims every plant's place afresh.
 *   - **To see where a database stands**: it says the version before and
 *     after, the tables it converted to utf8mb4, and what the data migrations
 *     found, in counts.
 *
 * Read the way `backup.php` and `sweep.php` are: `config.php` names the
 * database, and `PG_WALK_DSN` points it elsewhere for the reference checks and
 * the mass test. Safe beside the service and beside itself: every step is
 * idempotent, and on MariaDB it holds the same lock a request migrating holds.
 */

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/backup.php';   // `configuration()`, and nothing is taken
require_once __DIR__ . '/Schema.php';

try {
    $config = configuration();
    $db = new PDO($config['dsn'], $config['user'] ?? null, $config['password'] ?? null, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_STRINGIFY_FETCHES => false,
    ]);
    $before = Schema::stored($db);
    $found = Schema::upgrade($db, force: true);
    $after = Schema::stored($db);
} catch (Throwable $trouble) {
    fwrite(STDERR, gmdate('Y-m-d H:i:s') . '  no migration: ' . $trouble->getMessage() . "\n");
    exit(1);
}

printf("%s  schema version %d, now %d (the code's is %d)\n", gmdate('Y-m-d H:i:s'), $before, $after, Schema::VERSION);
$converted = $found['converted'] ?? [];
printf("  converted to utf8mb4: %s\n", $converted === [] ? 'nothing' : implode(', ', $converted));
printf("  offers erased that were withdrawn or declined in the clear: %d\n", $found['erased'] ?? 0);
printf("  places claimed: %d; claims let go: %d; plants standing in two places: %d\n",
    $found['claimed'] ?? 0, $found['let go'] ?? 0, $found['in two places'] ?? 0);
exit(0);
