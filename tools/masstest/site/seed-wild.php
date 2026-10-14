<?php
// Stands plants in a LOCAL copy's Wild Fields through WildStore, as
// Server/README.md says a field for looking at is sown. Called by seed.mjs
// with a JSON file of [{seed, parents, shown?: {a, b}}].
//
// It opens the store named by Server/.api/config.php and refuses to run if
// that names anything but a loopback database.
declare(strict_types=1);

if (PHP_SAPI !== 'cli') exit(1);
$api = __DIR__ . '/../../../Server/.api';
require_once $api . '/settings.php';
require_once $api . '/Areas.php';
require_once $api . '/Seeds.php';
require_once $api . '/WalkStore.php';

$settings = settings();
if (!preg_match('#host=(127\.0\.0\.1|localhost)[;:]|^sqlite:#', $settings['dsn'])) {
    fwrite(STDERR, "seed-wild.php sows only a local database.\n");
    exit(2);
}
$plants = json_decode((string) file_get_contents($argv[1]), true);
$wild = WalkStore::open($settings['dsn'], $settings['user'], $settings['password'])->wild();

$stood = 0;
$named = 0;
foreach ($plants as $plant) {
    [$parentA, $parentB] = $plant['parents'];
    [, $new] = $wild->release($plant['seed'], $parentA, $parentB);
    if ($new) $stood++;
    if (isset($plant['shown'])) {
        $mine = bin2hex(random_bytes(16));
        $theirs = bin2hex(random_bytes(16));
        $wild->beside($plant['seed'], $mine, $theirs, $plant['shown']['a']);
        $wild->answer($plant['seed'], $theirs, $plant['shown']['b']);
        $named++;
    }
}
echo "Stood {$stood} plants in the Wild Fields, {$named} with names beside them.\n";
