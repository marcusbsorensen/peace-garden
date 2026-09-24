# tools/replant

The replant: when the plants' new shapes go live, every planting in the web
garden is grown again with its new shape and every area's arrivals are placed
again, in the order they came, by the area's own rule. Decided 24 September
2026: *places may change once*.

## Why it takes two halves

A planting's place is decided by heights, and a height is a grown plant's. The
service is PHP and cannot grow a plant; it stores the height the phone sent.
So the growing is done on the Mac, from a copy of the live database, and the
placing is done on the server, where the database is.

| | runs on | does |
|---|---|---|
| `replant plan <copy>` (this package, against SeedCore) | the Mac | reads a copy (`tools/backup.sh`'s `walk-*.sql.gz`, a mysqldump or a SQLite copy), grows every stored seed again from its seed, parents and meeting, recomputes height, family, kind, hue and habit, replays every area through SeedCore's own rule, and writes `plan.json` |
| `Server/.api/replant.php <plan>` | the server | checks the plan against its own digest and the database against the copy, places every planting again with the area's **PHP** rule, refuses if a single place differs from SeedCore's, and writes it all in one transaction |

The two rules are held to each other the way the vector files hold them, but
on the live garden's own plants: the PHP writes nothing unless its replay is
SeedCore's, planting for planting.

## What happens to each kind of row

- **A planting standing:** keeps its arrival number and its seed, parents and
  meeting. Its height, family, kind, hue and habit are the genome's as grown
  now (a planting from a phone that never sent a hue or a habit gets them), and
  its plot, slot and nudge are the rule's, replayed in arrival order after the
  area's ambassador, exactly as the store places an arrival.
- **A planting taken back:** its row is **deleted**. It has no seed, so it
  cannot be regrown. It was kept, with its place and the traits the rule reads,
  only so that nothing placed after it would move (`TakenBack.php`); on the one
  day everything moves, that reason is gone. Kept as a stand-in it would steer
  the plants round it by a height measured on a shape that no longer grows, and
  the gardener asked for it to be gone: this is the day it can be gone
  entirely. The arrival numbers of the rest are kept, so the order holds and
  the numbering simply has gaps. (Considered and rejected: replaying it as a
  placeholder with its stored traits — old-shape heights among new ones, an
  invisible plant ordering visible ones — or pinning it to its old slot, which
  would pin a hole into a plot whose every neighbour has moved.)
- **An offer waiting for its answer:** grown again, and its height, family,
  kind, hue and habit rewritten, so that when it is accepted it is planted by
  the new shape. The plan names it by the SHA-256 of its seed, never the seed:
  an offer not yet accepted is on no page.
- **Anything else:** answered and withdrawn offers, the lock rows, the offer
  key — untouched.

## What makes it safe to run

- **It refuses a plan whose digest does not match its contents** (edited, or
  cut short), and a height whose bits do not match the bits written beside it.
- **It refuses a database that is not the copy's**: every area table must hold
  the same arrival numbers with the same seeds, and the same offers must be
  waiting. Anything that arrived, was taken back, or was offered or answered
  since the copy was taken means a fresh copy and a fresh plan. A table the
  copy did not have (an area opened since) must still be empty.
- **It runs once.** `replant_log` records every plan run; the same plan is
  refused ever after, including after a restore.
- **One transaction**, after taking every area's lock row, so no arrival is
  placed against a half-replanted garden and any failure leaves it as it was.
  Before it commits it reads everything back and compares it with the plan.
- `--dry-run` does all of that and rolls back. `--verify` only reads, and says
  whether the garden is what the plan leaves.

## Rehearsal

`rehearse.sh` sows a garden with the code that is live — its rules, its cuts,
its SeedCore's heights, taken out of git — takes a copy with the live
`backup.php`, plans it with this checkout and replants it with this checkout's
`replant.php`: dry run, verify (no), run, verify (yes), run again (refused), run
on another garden (refused), then an independent replay of the result through
this checkout's stores (`Rehearsal/replay.php`), then one new arrival.

```sh
sh tools/replant/rehearse.sh <live commit>             # SQLite
sh tools/replant/rehearse.sh --mariadb <live commit>   # MariaDB 10.11 in Docker, a mysqldump copy
sh tools/replant/rehearse.sh --copy <walk-….sql.gz>    # a real copy, loaded into Docker
```

`<live commit>` defaults to `main`, which is right only until the shapes are
merged; after that, pass the commit that is deployed. Docker (OrbStack) is
needed for the last two. On 24 September 2026 all three passed: 360 arrivals
from main's SeedCore (40 an area, every seventh taken back, three offers, one
accepted) replanted on SQLite and on MariaDB, and the newest copy on this Mac
(`walk-2026-09-24T122727Z.sql.gz`, which holds no plantings yet and one
declined offer) replanted in MariaDB.

## The runbook for the live run

**Ask Marcus first.** Every step from 2 on changes the live service.

**When.** The phones send the height with every offer, and a phone on a build
older than the shapes sends the old one. Until the app build with the new
shapes is what people have, an offer made after the replant is planted by its
old height. So run it as that build ships. If it has to run earlier, run it
again (a fresh copy, a fresh plan) once the build is out: a second plan has a
new digest, and it grows every planting again, so those arrivals come into
line.

0. **On the Mac, in the merged checkout** — every check green, and the
   rehearsals passing against the commit that is live now:

   ```sh
   swift test --package-path Packages/SeedCore
   for f in tools/reference/check_*.php; do [ "$f" = tools/reference/check_restore.php ] || php "$f" || break; done
   sh tools/replant/rehearse.sh <live commit>
   sh tools/replant/rehearse.sh --mariadb <live commit>
   sh tools/wasm/build.sh            # the module is built, not committed
   ```

1. **Back up**, and prove the copy restores:

   ```sh
   sh tools/backup.sh
   sh tools/backup.sh --restore-test
   ```

2. **Plan** from that copy, and read what it says — every area's count, what
   moves, and any `note:` line (a planting whose name puts it in another area is
   left where it is, and said so):

   ```sh
   COPY=$(ls -1 "$HOME/Library/Application Support/Peace Garden backups"/walk-*.sql.gz | tail -1)
   swift run -c release --package-path tools/replant replant plan "$COPY" --out /tmp/replant-plan.json
   ```

3. **Deploy** the new shapes: rules, cuts, ambassadors, the WebAssembly module,
   and `replant.php`.

   ```sh
   sh tools/deploy.sh
   ```

   From here until step 5, a new arrival is placed by the new rules among
   old-shape heights. The replant refuses to run over it (step 4 says so), so
   keep the gap short, and if it happens go back to step 1.

4. **Carry the plan over and rehearse it there:**

   ```sh
   scp /tmp/replant-plan.json peacegarden:replant-plan.json
   ssh peacegarden 'php ~/public_html/.api/replant.php ~/replant-plan.json --dry-run'
   ```

   A refusal names what differs. *Not what the copy held* means something
   arrived, was taken back, offered or answered since the copy: back to step 1.

5. **Replant:**

   ```sh
   ssh peacegarden 'php ~/public_html/.api/replant.php ~/replant-plan.json'
   ```

6. **Verify**, then look:

   ```sh
   ssh peacegarden 'php ~/public_html/.api/replant.php ~/replant-plan.json --verify'
   ```

   Open every area's page in a fresh browser profile (an old one keeps the old
   JavaScript): `/walk`, `/quiet`, `/cross`, `/orchard`, `/knot`, the Seedbed,
   `/frame`, `/glasshouse`, `/coppice`, `/ground`.

7. **Back up again**, so the newest copy is the replanted garden:

   ```sh
   sh tools/backup.sh
   ```

8. **Delete the plan**, on both sides. It holds every planting's seed and each
   waiting offer's digest, as a copy does:

   ```sh
   ssh peacegarden 'rm ~/replant-plan.json'
   rm /tmp/replant-plan.json
   ```

**If it has to be undone:** restore the copy from step 1 as `Server/README.md`
§*Restoring* describes and deploy the previous commit. `replant_log` is not in
the copies, so it survives the restore and the same plan stays refused; a
replant after that is a fresh copy and a fresh plan.
