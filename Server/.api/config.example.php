<?php
// Copy to config.php (which git ignores) to change where the plot service
// keeps the walk, or to open planting on a local copy. Every key is optional.
return [
    // The 20i database, once it exists:
    // 'dsn' => 'mysql:host=…;dbname=…;charset=utf8mb4',
    // 'user' => '…',
    // 'password' => '…',

    // Local only. Planting stays closed on the live site until sign-in and
    // both gardeners' consent exist.
    // 'open_for_planting' => true,

    // Local only, since 2 October 2026: paths that visitors wear in the Wild
    // Fields (`WildWear.php`). It stays off on the live site until the privacy
    // page says what it sends and keeps, in every language.
    // 'wear' => true,
];
