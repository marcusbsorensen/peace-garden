<?php
declare(strict_types=1);

/**
 * The curator's tool: taking a released plant down from the Wild Fields, by
 * hand, and standing it again.
 *
 *   php ~/public_html/.api/curate.php hide <seed, or a prefix only it has>
 *   php ~/public_html/.api/curate.php unhide <seed, or a prefix only it has>
 *   php ~/public_html/.api/curate.php show <seed, or any prefix>
 *   php ~/public_html/.api/curate.php list          the plants taken down
 *
 * **Why it exists.** Anybody can release a plant: a token carries consent, not
 * authenticity, and the rate limit is all that stands in front of the field
 * (docs/WEB-GARDENS.md, *The Wild Fields*, *Abuse*). A plant that should not
 * stand — a name beside it that is somebody else's, a field sown with
 * invented crossings — needs somebody to be able to take it down.
 *
 * **What hiding does is set `hidden` on its row, and nothing else.** No public
 * read serves a hidden plant (`WildStore`): not the counts at `/api/wild`, not
 * its tile, and so not the names beside it, which are only ever read through
 * the plant. The row stays, so the same seed cannot be released again
 * (`/api/wild/release` answers `410`) or offered to an area (`410` too), and
 * the nightly copy carries it with the flag set. **Nothing is ever deleted**,
 * so `unhide` puts back exactly what was there.
 *
 * **And nothing is written about the hiding**: no reason, no time, not who.
 * The field keeps no time and no name for anything (`docs/PHASES.md`), and a
 * curator's note would be the one dated record in it.
 *
 * **A prefix names one plant or none.** Seeds are long and a curator reads one
 * off a page; `hide` and `unhide` take any unambiguous beginning of one, at
 * least six characters, and refuse a prefix two plants share, listing both.
 * `show` lists every match and changes nothing.
 *
 * **Run on the server, over ssh**, read the way `backup.php` and `sweep.php`
 * are: `config.php` names the database, and `PG_WALK_DSN` points it elsewhere
 * for the reference check (`tools/reference/check_curate.php`). It refuses to
 * run under anything but the command line, and is not reachable over HTTP in
 * the first place: nginx denies every dot-directory, and the router serves only
 * the `/api/` routes it names, none of which is this.
 */

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/backup.php';   // `configuration()`, and nothing is taken
require_once __DIR__ . '/WalkStore.php';

/** The shortest beginning of a seed `hide` and `unhide` will act on. */
const SHORTEST = 6;

exit(curate($argv));

function curate(array $argv): int
{
    $verb = $argv[1] ?? '';
    $given = strtolower(trim((string) ($argv[2] ?? '')));
    $usage = "usage: curate.php hide|unhide|show <seed or prefix>\n       curate.php list\n";

    if ($verb === 'list' && count($argv) === 2) {
        $hidden = wild()->hiddenOnes();
        if ($hidden === []) {
            echo "Nothing is hidden.\n";
            return 0;
        }
        foreach ($hidden as $plant) echo describe($plant);
        printf("%d hidden.\n", count($hidden));
        return 0;
    }
    if (!in_array($verb, ['hide', 'unhide', 'show'], true) || count($argv) !== 3) {
        fwrite(STDERR, $usage);
        return 2;
    }
    if (!preg_match('/\A[0-9a-f]{1,64}\z/', $given)) {
        fwrite(STDERR, "A seed is hex: 0-9 and a-f, at most 64 of them.\n");
        return 2;
    }

    $wild = wild();
    $matches = $wild->matching($given);
    if ($verb === 'show') {
        if ($matches === []) {
            fwrite(STDERR, "No plant in the Wild Fields begins $given.\n");
            return 1;
        }
        foreach ($matches as $plant) echo describe($plant);
        return 0;
    }

    if (strlen($given) < SHORTEST) {
        fwrite(STDERR, sprintf("%s takes at least %d characters of the seed.\n", $verb, SHORTEST));
        return 2;
    }
    if ($matches === []) {
        fwrite(STDERR, "No plant in the Wild Fields begins $given.\n");
        return 1;
    }
    if (count($matches) > 1) {
        fwrite(STDERR, sprintf("%d plants begin %s, so none was changed:\n", count($matches), $given));
        foreach ($matches as $plant) fwrite(STDERR, describe($plant));
        return 1;
    }

    $plant = $matches[0];
    $hide = $verb === 'hide';
    if (!$wild->setHidden($plant['seed'], $hide)) {
        echo ($hide ? 'Already hidden' : 'Not hidden') . ", so nothing changed:\n" . describe($plant);
        return 0;
    }
    $plant['hidden'] = $hide;
    echo ($hide ? 'Hidden' : 'Standing again') . ":\n" . describe($plant);
    return 0;
}

function wild(): WildStore
{
    $config = configuration();
    try {
        return WalkStore::open($config['dsn'], $config['user'] ?? null, $config['password'] ?? null)->wild();
    } catch (Throwable $trouble) {
        fwrite(STDERR, 'The database would not open: ' . $trouble->getMessage() . "\n");
        exit(1);
    }
}

/** One plant, as the curator reads it: enough to know it is the right one. */
function describe(array $plant): string
{
    $lines = sprintf("  %s  %s\n", $plant['seed'], $plant['hidden'] ? 'hidden' : 'standing')
        . sprintf("    tile %d,%d   parents %s  %s\n", $plant['tile'][0], $plant['tile'][1],
                  $plant['parents'][0], $plant['parents'][1]);
    $shown = $plant['shown'];
    if ($shown['names'] !== []) $lines .= '    names  ' . implode(', ', $shown['names']) . "\n";
    if ($shown['place'] !== null) $lines .= '    place  ' . $shown['place'] . "\n";
    if ($shown['month'] !== null) $lines .= '    month  ' . $shown['month'] . "\n";
    return $lines;
}
