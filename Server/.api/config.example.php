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

    // Paths that visitors wear in the Wild Fields (`WildWear.php`). On at the
    // live site, where the privacy page says what it sends and keeps (privacy9,
    // in 41 languages); a local copy turns it on here (Marcus, 14 October: 18A).
    // 'wear' => true,
];
