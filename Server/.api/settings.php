<?php
declare(strict_types=1);

/**
 * What this copy of the site is set to: `config.php` over the defaults.
 *
 * Its own file since 2 October 2026, when the pages began to ask one of these
 * questions too. `router.php` reads it for every request to the plot service,
 * and `index.php` reads it for a page that says something only where a switch
 * is on — the privacy page's paragraph on paths that visitors wear, which is
 * there only where wear is (`WildWear::on`). One reading of `config.php`, so
 * the routes and the page that describes them cannot disagree.
 *
 * `config.php` is git-ignored, and the deploy leaves the server's alone: it
 * is written on the server, and holds the database's credentials.
 */
function settings(): array
{
    $file = __DIR__ . '/config.php';
    $given = is_file($file) ? require $file : [];
    return $given + [
        // Outside public_html, beside it, so the file is never a URL.
        'dsn' => 'sqlite:' . dirname(__DIR__, 2) . '/peacegarden-data/walk.sqlite',
        'user' => null,
        'password' => null,
        'open_for_planting' => false,
        // Paths that visitors wear in the Wild Fields (`WildWear.php`). Off.
        'wear' => false,
    ];
}
