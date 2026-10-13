<?php
// The local copy's Server/.api/config.php, written by stack.sh and never
// committed (Server/.api/.gitignore). It points the service at the test's
// MariaDB container on loopback.
//
// One harness seam: `X-Sim-Db` picks which test database a request uses, so a
// race or a charset check can run on a fresh database beside the population
// without touching it. Only names starting `pgmt_` are taken; anything else is
// the main one.
$db = $_SERVER['HTTP_X_SIM_DB'] ?? getenv('PGMT_DB') ?: 'pgmt_main';
if (!preg_match('/\Apgmt_[a-z0-9_]{1,40}\z/', $db)) $db = 'pgmt_main';
return [
    'dsn' => 'mysql:host=127.0.0.1;port=__DB_PORT__;dbname=' . $db . ';charset=utf8mb4',
    'user' => 'pgmt',
    'password' => 'pgmt-local-only',
    'open_for_planting' => false,
];
