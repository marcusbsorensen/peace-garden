# Population test, 13 October 2026

Five thousand simulated gardeners lived in a local copy of the plot service for
155 simulated days: they met, crossed plants with SeedCore, offered them to the
areas, answered, withdrew, released to the Wild Fields, named what stood beside
them, and were curated. Then the service was attacked, raced and loaded.
Nothing here touched peacegarden.app.

**Short version.** Every plant the service accepted was the true cross of its
parents at a meeting that happened, and every invariant held at every check.
Three things break under concurrency, and one thing caps capacity:

1. A "yes" sent twice at once takes the new planting back while the offer
   still says accepted (15 to 30 of 30 trials).
2. Two phones writing for the first time in the same moment can deadlock the
   rate-limit table and get a 500 (0.8 % of all requests in the population).
3. An offer and a release of the same plant at the same moment leave it
   standing in the Wild Fields and in an area (9 of 40 trials).
4. Every request runs the whole schema migration, 84 statements including ten
   ALTER TABLEs that always fail. Under load most database threads wait on
   metadata locks; without the migrations the same copy served 2.9 to 5 times
   the requests.

## What ran

| | |
| --- | --- |
| Gardeners | 5,000 in 50 towns (80 % of meetings within a town, so lineages run deep) |
| Meetings | 29,901 over 120 days, each SeedCore's own exchange: two seeds, two nonces, encounter ID, child, traits from the grown genome, area from its name, two contact tokens |
| Simulated time | 155 days (35 with no meetings, so every open offer lapses) |
| Requests | 59,601 in 17 minutes, 32 at a time |
| What they did | 8,995 offers; 6,505 answers, leaving 4,459 accepted and 1,372 declined; 410 withdrawals; 3,910 releases, and 1,005 second releases answered 200; 1,019 answers about names; 36,564 `pending` polls; 268 plants hidden with `curate.php hide`; sweep.php once a day |
| Afterwards | 98 adversarial cases, 7 races (210 trials), a character-set probe, a growth probe (to 3,000 plants in one area and 10,000 in the field), load at 10, 50 and 200 clients, and the same load on a copy with the migrations taken out |

**The stack** (`tools/masstest/population/stack.sh`): MariaDB 10.11 (the
version `tools/backup.sh` restores into) on 127.0.0.1:3407, nginx 1.27 with the
two location rules Server/README.md quotes from the 20i vhost, and PHP-FPM 8.3
with a static pool of 16 workers, all in Docker (OrbStack) on one network. The
gitignored `Server/.api/config.php` points at the container.

**Time.** The service reads `time()` and has no clock seam, so a simulated day
passes by editing the local database: every offer's times move 86,400 s into
the past and `rate_limits` is emptied, as a day ends every window. The
service's own code then lapses offers on day 30.

**Addresses.** Each gardener's phone has its own address, sent as `X-Sim-Addr`,
which the local nginx hands PHP as `REMOTE_ADDR`. That header exists only in
this test's nginx config. On festival days (45 and 90) one town's gardeners
share a venue address.

**Checks.** `check.php` checks every invariant against the database and the
HTTP answers together, between requests, on days 30, 60, 90, 120 and 154, after
the adversary and after the load. `popgen verify` (Swift, SeedCore by path)
re-derives every planting's cross and finds its meeting in the plans.

### Caveats

- **Not the host.** A Mac with 16 cores, the load generator on the same
  machine. 20i's PHP version, worker count, MariaDB settings, disk and network
  are not recorded in this repository, so absolute numbers are this machine's.
  The shapes (what grows, what queues, what fails) carry over.
- **Disk.** The population and the load ran on a database in memory (tmpfs),
  where fsync is free. The same database on a Docker volume (fsync through to
  macOS) was probed one request at a time; its load run was cut short when the
  Docker daemon stopped mid-run (the Mac's disk fell to 3 GB free from
  elsewhere). The two bracket a real host.
- **Topology.** The population run, the first races and the first load ran with
  PHP-FPM on macOS (Homebrew PHP 8.5), every database round trip crossing the
  Docker VM's port forwarding; requests were three times slower than with PHP
  in Docker, and races had wider windows. Both are reported where they differ.
- **Ports.** At over 470 new database connections a second the PHP container
  ran out of ephemeral ports (the service opens a connection per request). Only
  the no-migration experiment reached that; it was rerun with a wider port
  range.
- **The driver retries a 500 once**, after 150 to 450 ms, as a person tapping
  again would. The first answers are all counted.
- The plan's RNG seeds are 20261013 (population), 777, 999, 4242, 4343 and
  6161 (pools for the adversary, races and load); the driver's dice are seeded
  too, so a run is reproducible but for which request finishes first.

## Findings, most severe first

### 1. A "yes" sent twice at once takes the planting back, and the offer still says accepted

**What happens.** Both requests read the offer as `offered`. The first plants
it; the second finds the planting already there and is handed it. Both then try
to mark the offer accepted; whichever loses that update takes the planting back
(`Offers.php:321-327`), because it reads its own failure as a lapse or a
withdrawal. The offer ends `accepted`, both phones are told so by `pending`,
and the plant is not in its area: its row is a `withdrawn:` marker holding a
slot for ever. It cannot be offered again (one offer per plant), and the
gardeners have no way to know.

**Repro.** Offer a true cross, then send `POST /api/walk/answer {seed, to, yes:
true}` twice concurrently with the same body (a phone retrying after a slow
answer, or a double tap). `node races.mjs POOL OUT` race R2.

**Evidence** (`results/races.json`, `results/races-hostfpm.json`):

| | two yeses | three yeses |
| --- | --- | --- |
| PHP in Docker | planting gone in 15 of 30 | 10 of 30 |
| PHP on macOS (slower round trips) | 29 of 30 | 30 of 30 |

Every answer was a 200. The population never double-submitted, so it never hit
this; `check.php`'s "an accepted offer has no planting standing in its area"
is the query that finds it.

**Fixes.**
- **A (recommended).** When `accept()` loses, read the offer again and take the
  planting back only if it is no longer accepted:
  `if (!$this->accept($seed, $now) && ($this->find($seed, $now)['state'] ?? '') !== self::ACCEPTED)`.
  Two lines; every other behaviour stays.
- B. Claim the offer before planting (`UPDATE … SET state = 'planting' WHERE
  seed = ? AND state = 'offered'`); only the claimant plants. Stronger, but a
  new state that `pending` and the app would see.
- C. Run `answer` in one transaction holding `SELECT … FOR UPDATE` on the offer
  row (and `BEGIN IMMEDIATE` on SQLite).

Worth running on the live database, read-only, before and after: for each area
table, `SELECT o.seed FROM walk_offers o WHERE o.state = 'accepted' AND o.area =
'<area>' AND NOT EXISTS (SELECT 1 FROM <table> t WHERE t.seed = o.seed AND
t.hidden = 0)`.

### 2. First-time writers at the same moment deadlock the rate-limit table: 500

**What happens.** `Limits::wait` reads the bucket, then for a new one runs
`UPDATE … WHERE bucket = ?` (no row) and `INSERT` (`Limits.php:128-147`). Under
MariaDB's default REPEATABLE READ the UPDATE of a missing row takes a gap lock;
two new buckets landing in the same gap each wait for the other's insert, and
InnoDB kills one: `SQLSTATE[40001] … 1213 Deadlock found`. Two requests from
one address for a bucket that does not exist yet both insert, and one gets
`1062 Duplicate entry`. Either way the phone sees "could not answer" on an
offer, answer, withdrawal, release, name answer or `pending`. Nothing has been
written when it fails, so a retry is safe, but the app does not retry.

**Repro.** Empty `rate_limits`, then send `POST /api/walk/pending {tokens: []}`
from 40 different addresses at once. `races.mjs` R7 (and R1).

**Evidence.**
- Population: 478 of 59,601 first attempts answered 500 (0.80 %): offers
  1.5 %, releases 1.4 %, answers 1.0 %, withdrawals 3.4 %, `pending` 0.5 %. All
  were deadlocks or the duplicate key (`results/php-errors-summary.txt`).
- R7, 40 new callers at once: 0.5 % failed with PHP in Docker, 3.3 % on macOS.
- R1, the same release sent 20 times at once: in one trial 19 of the 20
  answered 500 (PHP in Docker); exactly one row every time.
- The deadlock, from `SHOW ENGINE INNODB STATUS`: two `INSERT INTO rate_limits`
  transactions, each "lock_mode X locks gap before rec insert intention
  waiting" on the same delete-marked record — the sweep's DELETE leaves those
  behind on every request.

**Fixes.**
- **A (recommended).** Retry the transaction in `wait()` up to three times on
  SQLSTATE 40001 and on a duplicate key (23000). It writes nothing else, so a
  retry is always safe; the same ten lines on both databases.
- B. One upsert per driver: `INSERT … ON DUPLICATE KEY UPDATE` on MariaDB,
  `INSERT … ON CONFLICT DO UPDATE` on SQLite. No UPDATE of a missing row, so
  no gap lock.
- C. `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED` in
  `WalkStore::open` for MySQL. No gap locks for this pattern, but it changes
  isolation for every query.

### 3. Every request runs the whole migration; under load requests queue on metadata locks

**What happens.** `WalkStore::open` (`WalkStore.php:62-98`) builds every
store, and every store's constructor migrates: 84 statements on every request,
including `GET /api/wild/tile/x/z`. Among them ten `ALTER TABLE … ADD COLUMN`
that always fail (the columns exist), about twenty `CREATE … IF NOT EXISTS`,
two data migrations that scan (`Offers.php:196-200`, `TakenBack::sweep`), and
four ALTERs and four CREATE INDEXes on `walk_offers` alone. A write runs the
offers migration twice, because `WalkStore::offers()` makes a new `Offers`
each call (`WalkStore.php:248-251`).

Three costs:

- **Metadata locks.** DDL, even DDL that changes nothing, takes a metadata
  lock that excludes other DDL on the table, so concurrent requests queue
  behind each other on `walk_offers`. Sampled twice a second at 50 clients,
  58 % of database threads (reads) and 77 % (writes) were "Waiting for table
  metadata lock", on `ALTER TABLE walk_offers ADD COLUMN hue/habit/kind/area`
  and `CREATE INDEX IF NOT EXISTS walk_offers_*`. Throughput falls as clients
  rise: reads 401 → 318 → 249 a second at 10 → 50 → 200 clients, writes 259
  → 121.
- **A scan that grows with every offer ever made.** The erasure migration
  `SELECT * FROM walk_offers WHERE state IN ('withdrawn','declined') AND seed
  NOT LIKE 'h%'` is a full table scan (EXPLAIN: `type ALL`, the
  `(state, offered_at)` index unused). 3.8 ms a request at 10,000 offers, 15.3
  ms at 40,000; `GET /api/walk` went from 10.7 to 31.1 ms. At 400,000 offers
  it would be about 150 ms on every request.
- **The disk.** A failing ALTER still does file-system work: its profile shows
  a table definition being created before the duplicate column is refused. In
  memory it costs 0.17 ms; on the Docker volume about 30 ms (no InnoDB fsyncs
  were counted, so the cost is in the file system), and a single
  request spent 303 ms in the database: `GET /api/walk` p50 163 ms, `/api/ground`
  347 ms, against 11 and 12 ms in memory. A 20i disk sits somewhere between.

**The experiment** (`experiment-once.sh`: a copy of `Server/` in `out/` whose
requests skip the DDL and the two erasure scans; `Server/` untouched), same
database, back to back, 15 s per row:

| | as it is: req/s, p50, p99 (ms) | migrations skipped: req/s, p50, p99 |
| --- | --- | --- |
| read, 10 clients | 246, 26, 170 | 714, 9.5, 65 |
| read, 50 | 297, 134, 548 | 1,047, 37, 227 |
| read, 200 | 298, 610, 1,668 | 807, 230, 473 |
| write, 10 | 259, 31, 149 | 1,331, 5.9, 26 |
| write, 50 | 185, 244, 517 | 2,803, 14, 81 (5 s) |

Statements per request fell from 84 to one or two.

**Fixes.**
- **A (recommended).** A schema version: one row read per request, and the
  migrations run only when the code's number is higher than the stored one,
  under `GET_LOCK` so one request runs them. `backup.php`'s open-first keeps
  working because it calls the same function. Cache `offers()` like the other
  stores.
- B. Run migrations from a command in `tools/deploy.sh` (and `backup.php`),
  never from a request.
- C. At least: `ADD COLUMN IF NOT EXISTS` (MariaDB 10.0+) and delete the two
  erasure migrations once the live tables are clean. Removes the errors and
  the scan; leaves the DDL metadata locks.

### 4. On a database whose default is not utf8mb4, a named release fails for good with the plant already standing

**What happens.** No `CREATE TABLE` names a character set, so the tables take
the database's default, whatever the host created it with. The release inserts
the plant (`router.php:634`) and then writes the names row (`router.php:635`,
`WildStore.php:344`) in separate statements. When the name cannot be stored,
the request answers 500 after the plant is in the field; every retry finds it
standing, tries the name again and answers 500 again.

**Repro.** `node charset.mjs POOL OUT`: three databases, a release with a
name in each.

| database default | Anna | مريم | Rose 🌹 | Zoë |
| --- | --- | --- | --- | --- |
| utf8mb4 | 201 | 201 | 201 | 201 |
| utf8mb3 | 201 | 201 | **500, standing, retry 500** | 201 |
| latin1 | 201 | **500, standing, retry 500** | **500, standing, retry 500** | 201 |

Logged as `1366 Incorrect string value '\xF0\x9F\x8C\xB9' for column
wild_names.name_a`. This is conditional: the live database's default is
unknown here.

**Fixes.**
- **A (recommended).** Check the live database read-only: `SELECT
  default_character_set_name FROM information_schema.schemata WHERE schema_name =
  DATABASE();` and `SHOW CREATE TABLE wild_names;`. If either is not utf8mb4,
  `ALTER TABLE … CONVERT TO CHARACTER SET utf8mb4` on the tables with text
  (they are small).
- B. Name `DEFAULT CHARSET=utf8mb4` in every MySQL `CREATE TABLE`.
- C. Write the planting and its names row in one transaction, so a failure
  leaves nothing standing.

### 5. An offer and a release of the same plant at the same moment: it stands in two public places

**What happens.** The release checks the asking (`letGo`, `router.php:628`)
before the offer's row exists, and the offer checks the field
(`Offers.php:232`) before the release's row exists; both succeed. A later
"yes" plants it, because `answer` does not look at the field
(`Offers.php:300-320`). The plant then stands in the Wild Fields and in an
area with its meeting published — what `walk/offer`'s 410 exists to prevent.

**Repro.** Gardener A offers while gardener B releases (with B's token), at the
same moment; then the offer's recipient answers yes. `races.mjs` R4.

**Evidence.** 9 of 40 trials with PHP in Docker, 33 of 40 on macOS. The
population never raced the two and stayed clean.

**Fixes.**
- **A (recommended).** In `answer`, before planting, erase the offer as
  withdrawn if `$this->walk->wild()->holds($seed)`. One check; whatever the
  interleaving, nothing is planted for a released plant.
- B. A `placed` table keyed by seed, written by both release and plant in
  their transactions, so the second to arrive backs out.

### 6. The rate limit counts addresses, and real crowds and IPv6 are not one address each

**What happens.** `Limits::caller` is the whole `REMOTE_ADDR`
(`Limits.php:174-177`).
- **A crowd on one Wi-Fi.** On each festival day about a hundred gardeners on
  the venue's Wi-Fi opened the app three times: 141 of their 588 requests
  (24 %) were answered 429, all `pending` (220 per address per 55 minutes).
  Offers (18) and releases (9) would run out sooner: a workshop where ten
  people each release one plant over the same router exceeds the release
  allowance. Meetings happen where people are together, which is where they
  share a network, and mobile carriers put many phones behind one IPv4
  address.
- **IPv6.** A phone holds a /64. Twenty releases from twenty addresses in one
  /64 were all accepted (`results/adversary.json`). Combined with the
  service taking any self-consistent lineage (by design: a token carries
  consent, not authenticity), there is no brake on inventing plants over IPv6
  — if the host serves IPv6.

**Fixes.**
- **A (recommended).** Bucket IPv6 by /64 in `Limits::caller` (zero the low 64
  bits; one line), and raise `pending` — it writes nothing and is limited only
  because phones call it unprompted.
- B. Count writes per address and per meeting token together, so a crowd's
  phones do not share one allowance while one phone is still capped.
- C. Keep as is, and have the app say "busy, try in a while" on 429 rather
  than an error.

### 7. What grows with the garden

None of these is a problem at this population; each is linear and unbounded.

- **A Wild Fields tile has no limit.** About 370 to 490 bytes a planting
  (`results/scale.json`): 58 KB per tile at 10,000 released, 188 KB at 34,620
  (after the load test). At a million released it would be about 5.8 MB per
  tile, and the page fetches several.
- **`GET /api/wild` reads the whole field** (EXPLAIN: full index scan plus row
  lookups for `hidden`): p50 6.9 ms at 1,000 released and 20 ms at 10,000; at
  34,620 its query alone took 34 ms.
- **Every arrival in an area reads the whole area under the area's lock**
  (`SELECT * … ORDER BY arrival`, e.g. `GlasshouseStore.php:113-124`): rows read
  per arrival equalled the area's size at every step; the scan took 0.9 ms at
  250 plantings and 8 ms at 3,000, a "yes" 9 then 17.6 ms. Arrivals in one area
  are serialised, so at about 100,000 plantings an area would take a few a
  second. Fifty yeses at once into the Glasshouse placed cleanly in 307 ms.
- **Lapsing is done by whichever request comes first.** With 30,701 offers
  due at once, sweep.php lapsed 1,544 while one concurrent `pending` lapsed
  the other 29,157 itself and took 3.0 s; the next took 34 ms. `offer` and
  `pending` lapse every offer that is due (`Offers.php:225, 281, 468-477`).

**Fixes.**
- **A (recommended), tiles:** cap a tile at, say, 200 plantings in seed order
  (seeds are random, so the first 200 are a fair sample) and send the count;
  for the field, keep a per-tile count or index `(hidden, tile_x, tile_z)`;
  cap `lapse()` per request (say 200) and leave the rest to the sweep.
- B. Finer tiles where the field is dense, or cached tile JSON invalidated on
  release and hide.
- C. Leave the area scan until an area passes ~10,000; then read only the
  plots the rule can still place into, if the rule allows.

### 8. A plant crossed with itself is accepted

Both parents the same seed, crossed by the caller: released with 201. The app
never makes one (the exchange aborts on "same seed"), so it is always made by
hand. **A (recommended):** refuse `parents[0] === parents[1]` with 422 in
`checkedPlant` and the release route. B: leave it, as one more invented
lineage.

### Smaller things noticed

- The app strips formatting characters before sending a name
  (`WildShowing.choosing`), which removes the zero-width joiner in emoji such
  as 🧑‍🌾 and the zero-width non-joiner Persian spelling needs; the service
  refuses them sent raw (400). Names display slightly wrong in those scripts.
- PHP's `trim` removes ASCII spaces only, so a name sent with no-break spaces
  round it keeps them (the app trims them first).

## What held

At every check (days 30, 60, 90, 120, 154, after the adversary, after the load):
no violation (`results/invariants-day-154.json`, `results/invariants.json`).

- **Every accepted plant is the true cross of its parents at its meeting**:
  8,369 plantings at day 154 and 39,347 after the load, each re-derived by
  SeedCore and found among meetings that happened. Plantings taken back keep
  no lineage (428 markers).
- **Nothing forged was accepted**: a wrong seed, a wrong meeting, a swapped
  parent, upper-case hex, three parents — 422 or 400 every time.
- **No duplicates**: one row per released seed under 20 identical releases at
  once; no seed in two areas, or in an area and the field.
- **Hidden stays hidden**: 268 hidden in the population; every re-release and
  every offer of one answered 410; none in any tile or count; `unhide`
  restores it; `pending` still tells its gardeners, as the README says.
- **Tiles and counts agree with the database** in all 64 tiles; every plant
  stands inside its tile, where SeedCore puts it; names in alphabetical order.
- **Offers lapse at exactly thirty days and are erased**: 2,495 lapsed, each
  with `answered_at − offered_at = 2,592,000`, none waiting past thirty days,
  every settled offer reduced to fingerprints.
- **The areas stay valid and small**: `/api/<area>` 11 to 12 bytes; the largest
  plot 22.8 KB (Home Ground, 64 plantings); no two plantings share a place or
  stand within 21 cm; none farther than 3.0 m from its plot's origin; lotus spans
  never overlap.
- **Tokens do their job**: a replayed offer or yes changes nothing; invented,
  swapped or stolen tokens get 409, 404 or 403; a published plant cannot be
  released, re-offered or withdrawn by a stranger.
- **Bad input never reaches a 500**: malformed, empty, nested 600 deep,
  invalid UTF-8, lone surrogates, 9 KB (cut at 8 KB), 900 KB, type-confused
  fields — 400; over 1 MB, nginx's 413. SQL-shaped, HTML and right-to-left
  names are stored and served exactly.
- **The limit counts as designed**: nine releases, then 429 with
  `Retry-After`; malformed requests count too.

## Load

PHP-FPM in Docker, 16 workers, the database in memory and populated (23 to 30
MB, 10,000 to 16,000 offers, 4,000 to 10,000 released). Closed-loop clients,
20 s per row. Reads: half tiles, a tenth `/api/wild`, the rest area counts
and plots. Writes: half releases, half offers, each from its own address.

| kind | clients | req/s | p50 ms | p95 ms | p99 ms | errors |
| --- | --- | --- | --- | --- | --- | --- |
| read | 10 | 401 | 21 | 48 | 80 | 0 |
| read | 50 | 318 | 132 | 301 | 353 | 0 |
| read | 200 | 249 | 601 | 2,575 | 3,111 | 0 |
| write | 10 | 259 | 32 | 75 | 103 | 0 |
| write | 50 | 121 | 414 | 714 | 847 | 0 |
| write | 200 | 126 | 1,461 | 1,857 | 1,893 | 0 (7 s, pool ran out) |

With PHP-FPM on macOS the same mix managed 58, 64 and 82 reads a second
(p99 22.7 s at 200 clients) and 28 to 70 writes, with 0.1 to 0.2 % 500s from
finding 2 (`results/load-hostfpm.json`). One request at a time on the Docker
volume: 163 to 347 ms p50 per read (`results/probe-volume.json`).

**Slowest statements** (performance_schema, `results/load-*.json`):

| statement | per call | why |
| --- | --- | --- |
| `SELECT * FROM walk_offers WHERE state IN (…) AND seed NOT LIKE ?` | 3.8 ms at 10k offers, 15.3 ms at 40k | full scan, every request (twice on writes) |
| `SELECT tile_x, tile_z, COUNT(*) … FROM wild_fields WHERE hidden = 0 GROUP BY …` | 4 ms at 4k, 34 ms at 35k | full index scan with row lookups |
| `SELECT * FROM <area> ORDER BY arrival` | 0.9 ms at 250, 8 ms at 3k | every arrival, under the area's lock |
| `ALTER TABLE … ADD COLUMN` (×10, all failing) | 0.17 ms in memory, ~30 ms on the volume | every request, plus the metadata lock |

Database size: 17.8 MB at the end of the population (largest table
`walk_offers`, 9.9 MB for 8,952 rows: four indexes over 64-character keys),
67 MB after the load tests.

### Where it would break first on shared hosting

1. **The metadata-lock queue on `walk_offers`** (finding 3). It is there on an
   idle server and gets worse with every concurrent request; throughput falls
   as clients rise rather than levelling off.
2. **A slow disk under DDL.** If 20i's disk makes a failing ALTER cost tens
   of milliseconds, every request costs a third of a second in the database
   and a 16-worker pool tops out near 50 requests a second.
3. **Round trips.** 84 statements on a fresh connection per request: at 0.3 to
   0.5 ms to a database server, 25 to 40 ms before any work.
4. **The `walk_offers` scan**, which grows with every offer ever made.
5. **The PHP worker pool**: past 16 concurrent requests everything queues
   (p99 in seconds at 200 clients). A shared plan may give fewer workers.

## Rerunning it

```sh
cd tools/masstest/population
swift build -c release                                   # popgen, SeedCore by path
PGMT_STORAGE=tmpfs ./stack.sh up                         # needs the pg-mt-pop-php:8.3 image:
#   docker build -t pg-mt-pop-php:8.3 -f conf/php.Dockerfile conf
.build/release/popgen plan 5000 120 250 20261013 out/plan.jsonl
.build/release/popgen plan 3000 5 3000 777 out/pool.jsonl
node driver.mjs out/plan.jsonl out/run --width 32 --check-days 30,60,90,120,154
node adversary.mjs out/pool.jsonl out/run --from 0
./stack.sh db race && node races.mjs out/pool.jsonl out/run --from 300
node charset.mjs out/pool.jsonl out/run --from 1200
node scale.mjs out/plan.jsonl out/run
node load.mjs out/pool.jsonl out/run --from 2000 --tag tmpfs
php check.php out/run && .build/release/popgen verify out/plan.jsonl out/run/dump.json out/pool.jsonl
./experiment-once.sh && PGMT_STORAGE=tmpfs PGMT_SERVER_DIR=$PWD/out/server-once ./stack.sh web
./migrations.sh out/migrations 97fd259                   # the schema version: fresh, upgraded, latin1, a rollback
./stack.sh down                                          # containers, network, volume, config.php
```

| file | what it is |
| --- | --- |
| `stack.sh`, `conf/` | the local stack, and the config it writes |
| `Sources/popgen/main.swift` | the plan (SeedCore's exchange for every meeting) and the verifier |
| `driver.mjs` | the population over HTTP, with the clock and the curator |
| `check.php` | the invariants, database and HTTP together |
| `adversary.mjs`, `races.mjs`, `charset.mjs` | the attacks, the races, the character sets |
| `scale.mjs`, `load.mjs`, `probe.mjs` | growth, load, one request alone |
| `experiment-once.sh` | the copy without migrations, for finding 3 |
| `migrations.sh`, `migrations.php` | the schema version on MariaDB, fresh and upgraded (14 October) |
| `results/` | the outputs quoted above |
| `results-after/` | the outputs quoted below, after the fixes |

## After the fixes, 14 October

Marcus chose 7A: fix 1, 2, 3, 5, 6 and 8, take option B for 4, and leave 7.
Branch `claude/server-fixes-2026-10-14`; the code before is 97fd259, the
code this report measured. Then everything above ran again against the
fixed server, on the same stack (PHP-FPM 8.3 in Docker, 16 workers,
MariaDB 10.11 in memory), with the same plans and seeds.

**Short version.** No request answered 500 — not in the population, the
adversary, the races or the load, where the population had 478 before. A
double yes never takes the planting back (0 of 60, from 25 of 60), and an
offer and a release at once never leave a plant in two places (0 of 40, from
9). A request reads one row of schema instead of running eighty-four
statements; no database thread waited on a metadata lock; reads went from 160
to 320 a second to 1,400 to 1,800, and writes from 210 to 310 to 1,400 to
2,200, on the same database the same day.
Every invariant held at every check, and every planting re-derived by SeedCore.

### What changed

| finding | the fix | where |
| --- | --- | --- |
| 1. a double yes takes the planting back | When `accept()` loses, the offer is read again; the planting is taken back only if it is no longer accepted. Lapsed, withdrawn and declined never return to accepted, so the second read cannot be overtaken | `Offers::answer` |
| 2. deadlocks and duplicate keys on `rate_limits` | One upsert opens, resets or counts a window, inside a transaction at READ COMMITTED (no gap locks), read back in the same transaction; a deadlock or a duplicate key is tried again, four tries with jitter. Arrivals and releases retry deadlocks the same way | `Limits::wait`, `Limits::count`, `Transient.php` |
| 3. the migration on every request | `schema_version`: a request reads one row and migrates only when `Schema::VERSION` is higher, under `GET_LOCK`. Columns are added only where `information_schema` says they are missing; the `walk_offers` erasure scan and the `TakenBack` sweeps run with the migration. `offers()` is cached, and the store caches are per instance. `migrate.php` runs it by hand; every MariaDB copy drops `schema_version` first, so a restore is migrated again | `Schema.php`, each store's static `migrate`, `WalkStore::on`, `backup.php`, `migrate.php` |
| 4, option B | Every `CREATE TABLE` names `utf8mb4` and `utf8mb4_unicode_ci`; the migration converts any table of ours whose collation differs, after one read of `information_schema` | `Schema::options`, `Schema::utf8mb4` |
| 5. one plant in two public places | `placed`, keyed by seed: every arrival and every release claims the plant in its own transaction. A yes that finds the field holds it plants nothing and the offer is withdrawn; a release that finds an area holds it clears the way again, once, as it would have a moment later. Taking back lets go in the same transaction. A claim nothing stands behind (left by a rollback) is taken over | `Placed.php`, each area's `plant`, `WildStore::release`, `TakenBack::lift`, the release route |
| 6. the limit counts addresses | Two counts: per gardener (the meeting token; the whole bag for `pending`; the seed for a release without one) at the old allowances, and per address at `CROWD` = 5 times that. IPv6 counted by /64 | `Limits.php`, the routes |
| 8. a plant crossed with itself | 422 | `refuseSelfCross` in `router.php` |

**The limits, and what each still stops.** Per gardener, in fifty-five
minutes: 18 offers, 55 answers, 28 withdrawals, 220 askings, 9 releases, 55
name answers — what one address had. Per address: 90, 275, 140, 1,100, 45 and
275; wear stays 110 by address, as a browser carries no token. A token is
minted by the phone, so a script mints one per request and the gardener's
count never slows it: the address is what caps a script, now 45 invented
plants an hour in the Wild Fields from one IPv4 address or one /64 — five
times the 9 before, where IPv6 had no cap at all. The gardener's count stops
one phone gone wrong from spending its crowd's allowance. `CROWD` is the one
number to turn.

### The schema on MariaDB, fresh and upgraded

`migrations.sh` (`results-after/migrations/`) had 97fd259 serve two
databases, then the fixed code open them on its first request, as a deploy
would:

| database | built by | the fixed code's first request | the next | what was checked |
| --- | --- | --- | --- | --- |
| `pgmt_fresh` | nothing | 130 ms, every table made | 4.3 ms | the reference schema for the others |
| `pgmt_upgrade` (utf8mb4, MariaDB's default collation) | 97fd259: 800 gardeners for 66 simulated days (4,043 requests), then a withdrawn and a declined offer in the clear and a planting hidden with its seed and its offer, as the code before 24 September left them | 28 ms: tables converted, the four legacy rows erased (three offers, one planting), 502 places claimed | 4.8 ms | schema identical to the fresh one, table for table; the only rows changed were those four; `check.php` clean; `popgen verify` 502 of 502 true crosses |
| `pgmt_uplatin` (created latin1) | 97fd259: Anna and Zoë 201, Rose 🌹 and مريم **500** (finding 4) | 30 ms, every table converted | 3.4 ms | Anna and Zoë read back exactly; Rose 🌹 now 201; an offer waiting across the deploy answered yes and planted |
| the same, rolled back | 97fd259 again withdraws an accepted planting, leaving its claim in `placed` | — | — | the fixed code releases it over the stale claim: 201 |

The SQLite path is held in CI: `check_offers.php` upgrades a database built
in the tables' first shapes, and counts the statements a request sends to a
database at the code's version — one.

### The population again

The same plan (seed 20261013: 5,000 gardeners, 29,901 meetings, 155 days).
The driver's dice made the same choices, so the outcomes are identical —
8,995 offers; 4,459 accepted, 1,372 declined; 3,910 releases and 1,005 second
releases answered 200; 268 hidden; 2,495 offers lapsed at exactly thirty days
— and only the failures differ.

| | 13 October | 14 October |
| --- | --- | --- |
| requests | 59,601, of which 478 a retry of a 500 | 59,123, none retried |
| first attempts answered 500 | 478 (0.80 %), all deadlocks or the duplicate key | 0 |
| festival requests refused 429 | 141 of 588 (24 %) | 0 of 588 |
| invariants on days 30, 60, 90, 120, 154 | no violation | no violation |

The run took 150 s against 17 minutes, but the first ran PHP on macOS, so the
times are not comparable (see *Caveats*).

**Adversary**: 102 cases (the rate-limit block rewritten for two counts), all
as wanted: a plant crossed with itself 422; one address, 45 releases then
429; one token from eleven addresses, 9 then 429; forty gardeners on one
router, all 201; a hundred phones on one Wi-Fi asking `pending` three times,
none refused; one /64, 45 then 429, and ten /64s are ten callers; 45
malformed releases spend the address's allowance.

**Character sets**: on databases created utf8mb4, utf8mb3 and latin1, every
name — Anna, مريم, Rose 🌹, Zoë — answered 201, its retry 200, and was stored
exactly; every table is `utf8mb4_unicode_ci` whatever the database's default.

### The races again (PHP in Docker, both days)

| race | 13 October | 14 October |
| --- | --- | --- |
| R1, one release twenty times at once | one row; in one trial 19 of 20 answered 500 | one row every time; none failed; 1 created, 8 told, 11 refused 429 by the gardener's count (one token) |
| R2, two yeses at once | planting gone in 15 of 30 | 0 of 30 (both answers said planted in 19) |
| R2, three yeses | 10 of 30 | 0 of 30 |
| R3, a yes and a withdrawal at once | withdrawn and absent 27, accepted and standing 3 | 28 and 2: consistent either way, as before |
| R4, an offer and a release at once, then yes | in both places in 9 of 40 | 0 of 40: 31 offers taken and then withdrawn by the yes, 9 refused 410 |
| R5, fifty yeses into the Glasshouse | 307 ms, no clash | 89 ms, no clash |
| R6, both choose the place at once | shown 30 of 30 | 30 of 30 |
| R7, forty new callers at once | 0.5 % answered 500 | 0 % |

### Load, before and after

The populated database after the races (18.6 MB). 97fd259 first, then the
fixed code, the same day; reads 20 s a row, writes 6 s a row (the write pool
holds 58,420 true crosses, and the fixed code writes them fast). Errors 0 and
InnoDB deadlocks 0 in every row; *waits* is the share of database threads
sampled "Waiting for table metadata lock".

| kind | clients | 13 Oct report: req/s, p50/p95/p99 ms | 97fd259 today: req/s, p50/p95/p99, waits | fixed: req/s, p50/p95/p99, waits |
| --- | --- | --- | --- | --- |
| read | 10 | 401, 21/48/80 | 241, 26/118/218, 24 % | **1,654**, 4.1/16/25, 0 % |
| read | 50 | 318, 132/301/353 | 160, 234/757/1,269, 62 % | **1,422**, 25/88/223, 0 % |
| read | 200 | 249, 601/2,575/3,111 | 322, 541/1,101/1,447, 55 % | **1,823**, 90/211/320, 0 % |
| write | 10 | 259, 32/75/103 | 309, 29/60/89, 19 % | **1,396**, 5.4/15/32, 0 % |
| write | 50 | 121, 414/714/847 | 211, 221/367/454, 67 % | **2,216**, 16/40/115, 0 % |
| write | 200 | 126, 1,461/1,857/1,893 | 211, 909/1,333/1,425, 66 % | **2,054**, 55/237/382, 0 % |

Throughput now rises with clients and levels off at the worker pool, where
before it fell. The costliest statements before were the `walk_offers`
erasure scan (11.8 ms a request at 50 readers) and the DDL; after, the schema
costs one `SELECT version` (0.25 ms), and the costliest is `GET /api/wild`'s
count over the field (21 ms at 25,000 released), which is finding 7, left as
it is. A tile reached 143 KB at that size.

### Invariants

No violation at any check: days 30, 60, 90, 120 and 154; after the adversary,
the races and the character sets; and after the load
(`results-after/invariants-*.json`, `stats.json`). `popgen verify`: 8,528
plantings after the adversary and 30,119 after the load, every one the true
cross of its parents at a meeting that happened (`verify.txt`), and 428
taken-back markers, as before. The old code's load wrote 2,354 releases with
no claim in `placed`; `migrate.php` then claimed exactly those, and found no
plant in two places.

### At deploy

- Nothing has to run by hand: the first request after the upload migrates,
  in about 30 ms on a database the size of the test's upgrade. To see it
  happen instead, `ssh peacegarden 'php ~/public_html/.api/migrate.php'`
  prints the version, the tables converted and what was claimed and erased.
- After restoring a copy taken before this deploy, run `migrate.php` once
  (Server/README.md, *Restoring*); copies taken after it migrate by
  themselves.
- The live database's character set is still Marcus's to check (finding 4,
  option A). The migration converts any table of ours not in
  `utf8mb4_unicode_ci`, so a live database left latin1 is put right on the
  first request, and `migrate.php` says which tables it converted.
- Worth running read-only on the live database first: finding 1's query, and
  for finding 5, any seed both in `wild_fields` and an area table. The
  migration claims the first place it finds for such a plant and counts it
  under *plants standing in two places*.

### Noticed, not changed

- R3 still lets a withdrawal lose to a yes arriving at the same moment: the
  withdrawing phone is told "accepted" and the plant stands, consistently.
  It can withdraw again.
- R1's twenty identical releases meet the gardener's count after nine; a real
  retry is one or two.
- Finding 7 is now the first thing that grows: `GET /api/wild` and the tiles.
