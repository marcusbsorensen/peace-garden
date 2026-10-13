# The site mass test

A crawler for peacegarden.app: every page, in every language, at a phone's, a
tablet's and a laptop's width, light and dark, against a local copy, and a
read-only look at the live site through a window that cannot write. Written
for the mass test of 13 October 2026; its findings are in
`design/mass-test-2026-10-13/site/README.md`.

Nothing here is part of the site and nothing here is uploaded.

| File | What it does |
| --- | --- |
| `router.php` | Serves `Server/` with PHP's own server the way the live nginx vhost does: dot paths 403, files typed from nginx's `mime.types` and gzipped, `README.md` left out as the deploy leaves it out, everything else to `index.php`. |
| `seed.mjs`, `seed-wild.php`, `engine.mjs` | Sow a **local** plot service: real crossings from the plant module, each sent to the area its genus names, and a Wild Fields of 200 with names beside a third. Refuse anything not on loopback. |
| `crawl.mjs` | The crawl. One line of results per page in `<out>/results.jsonl`; resumable; `--redo` reads again any page read before it settled. |
| `lib/inpage.mjs` | What is asked of each page: overflow, clipped/spilling/overlapping text, English fallbacks, raw keys, links, images, unnamed controls, right-to-left runs, wasm and WebGL outcomes, LCP and CLS. |
| `checks.mjs` | `tools/deploy.sh --check`'s rows and the ones it lacks, the association file, every public file hashed (for comparing two copies), and the internal links a crawl found. |
| `interact.mjs` | The chooser, negotiation from the browser's languages, a phone toolbar's resize, a phone held sideways, the keyboard sheet. |
| `perf.mjs` | Weight, LCP and CLS per page at 375 px on Slow 4G with the CPU slowed 4×, cold and warm. |
| `proxy.mjs` | The read-only window onto the live site: GET only, a read allowlist, one request every 500 ms, each address fetched once, a User-Agent naming the check. |
| `analyse.mjs` | Groups every fault by cause, with routes, languages, widths, an example URL and crops. |
| `sheet.mjs` | Lays crops out as captioned contact sheets. |

## Setting up

The two npm modules are not committed. Install them anywhere outside git:

```sh
npm i --prefix "$SCRATCH" playwright-core@1.64.0 axe-core@4.14.0
export PG_MASSTEST_MODULES="$SCRATCH/node_modules"
```

(or `npm i` them in this folder; its `.gitignore` keeps `node_modules/` out).
The browser is Playwright's Chromium if a whole one is in
`~/Library/Caches/ms-playwright`, otherwise the installed Google Chrome, or
whatever `PG_CHROME` names. On 13 October the cached `chromium-1217` was an
empty shell (448 KB, no framework), so the run used Google Chrome 156,
headless, with its own throwaway profile; `playwright-core@1.64.0` is the one
that speaks to Chrome 156.

## Running it locally

```sh
# A database for the plot service (MariaDB 10.11, as backup.sh rehearses on).
docker run -d --name pg-mt-site-db -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=yes \
  -e MARIADB_DATABASE=peacegarden -p 127.0.0.1:3408:3306 mariadb:10.11

# Server/.api/config.php (git ignores it; never commit it):
#   return ['dsn' => 'mysql:host=127.0.0.1;port=3408;dbname=peacegarden;charset=utf8mb4',
#           'user' => 'root', 'password' => '', 'open_for_planting' => (getenv('PG_MT_OPEN') === '1')];

# The built plant module, which git ignores, copied from a checkout that has run tools/wasm/build.sh:
cp ../peace-garden/Server/.pages/PlantWasm.wasm* Server/.pages/

# Serve, open for planting, sow, then serve again closed, as the live host is.
PG_MT_OPEN=1 PHP_CLI_SERVER_WORKERS=8 php -S 127.0.0.1:8822 -t Server tools/masstest/site/router.php &
node tools/masstest/site/seed.mjs http://127.0.0.1:8822 35 200
kill %1; PHP_CLI_SERVER_WORKERS=8 php -S 127.0.0.1:8822 -t Server tools/masstest/site/router.php &

OUT=$SCRATCH/local
node tools/masstest/site/crawl.mjs --base http://127.0.0.1:8822 --out $OUT --concurrency 8
node tools/masstest/site/crawl.mjs --base http://127.0.0.1:8822 --out $OUT --redo --concurrency 2 --settle 3000
node tools/masstest/site/checks.mjs --base http://127.0.0.1:8822 --name local --out $OUT --links $OUT/results.jsonl
node tools/masstest/site/interact.mjs --base http://127.0.0.1:8822 --out $OUT
node tools/masstest/site/perf.mjs --base http://127.0.0.1:8822 --out $OUT --langs en,de
node tools/masstest/site/analyse.mjs --out $OUT --name local
```

The whole local crawl is about 3,400 page loads and took about two hours at
eight pages at once. `--pages`, `--langs`, `--widths`, `--schemes` and
`--variants` cut it down; every option is listed at the head of `crawl.mjs`.

## Running it against the live site, read-only

Only through the proxy, which is the thing that guarantees it cannot write
and cannot hurry the host:

```sh
node tools/masstest/site/proxy.mjs --port 8830 --log $SCRATCH/live/proxy.log &
LIVE=http://127.0.0.1:8830
node tools/masstest/site/checks.mjs --base $LIVE --name live --out $SCRATCH/live
node tools/masstest/site/crawl.mjs --base $LIVE --out $SCRATCH/live --live \
  --langs en,da,ar,de,ja,pl,fi --variants plain --schemes dark --concurrency 2
node tools/masstest/site/perf.mjs --base $LIVE --out $SCRATCH/live --langs en
node tools/masstest/site/analyse.mjs --out $SCRATCH/live --name live
```

What the proxy allows is in its head comment: the pages, the static files,
three known misses the deploy check reads, and the plot service's GET routes
for counts, plots and tiles. Every other method is answered 405 locally, and
so is any other `/api/` path. `--live` on the crawler also refuses, in the
browser, every request that is not a GET to the proxy, and records it.
`proxy.log` lists every request that reached the live host.
