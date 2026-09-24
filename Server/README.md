# Serving peacegarden.app

Two jobs. Convince iOS that this app owns this domain, so a seed link opens the
app instead of a web page — and answer everybody else, on `/s`, with the page a
seed lands on.

## What goes where

```
peacegarden.app/
├── index.php                          ← serves every page in .pages/, /plant.wasm, and /api/
├── .pages/                            ← nginx refuses a dot-directory
│   ├── index                          ← the front: a plant, three steps, ten area cards
│   ├── s                              ← the page a seed lands on
│   ├── g                              ← the garden, walked; served at /g and /garden
│   ├── meanings                       ← what the names mean: the lookup table
│   ├── walk                           ← the Long Walk
│   ├── quiet                          ← the Quiet Garden
│   ├── cross                          ← the Crossing
│   ├── orchard                        ← the Orchard
│   ├── knot                           ← the Knot Garden
│   ├── seedbed                        ← the Seedbed
│   ├── frame                          ← the Cold Frame
│   ├── wild                           ← the Wild Fields
│   ├── download                       ← the app
│   ├── privacy                        ← what the site and the app keep
│   ├── t                              ← the test roster
│   ├── PlantWasm.wasm(.gz, .br)       ← built by tools/wasm/build.sh, not committed
│   └── apple-app-site-association     ← no file extension, and none is added
├── .api/                              ← the plot service; see below
│   ├── router.php                     ← every /api/ route
│   ├── Areas.php, Ambassadors.php     ← the ten areas, and the plant that stands for each
│   ├── Seeds.php                      ← whether a seed is the cross of the parents it names
│   ├── LongWalk.php, WalkStore.php    ← the Long Walk's rule, and its table
│   ├── QuietGarden.php, RoomStore.php ← the Quiet Garden's rule, and its table
│   ├── Crossing.php, CrossStore.php   ← the Crossing's rule, and its table
│   ├── Orchard.php, OrchardStore.php  ← the Orchard's rule, and its table
│   ├── KnotGarden.php, KnotStore.php  ← the Knot Garden's rule, and its table
│   ├── Seedbed.php, SeedbedStore.php  ← the Seedbed's rule, and its table
│   ├── ColdFrame.php, ColdFrameStore.php ← the Cold Frame's rule, and its table
│   ├── Offers.php                     ← the asking: offer, pending, answer, withdraw
│   ├── Limits.php                     ← how often one caller may write
│   ├── backup.php                     ← the nightly copy, from cron
│   └── config.example.php             ← copy to config.php, which git ignores
├── .htaccess                          ← for a host that reads one. This is not.
├── languages.json                     ← generated: tools/site/export.py
├── testers.json                       ← generated: one gardener per language
├── passages/<code>.json               ← generated: one bank per language
├── strings/<code>.json                ← the site's own words, per language
├── favicon.ico                        ← generated: tools/icon/make_icon.py
└── assets/
    ├── site.css
    ├── icon.svg, icon-180.png         ← generated, from the same drawing
    ├── stars.bin, places.json         ← generated: tools/sky/pack.py, for sky.js
    └── js/
        ├── frontpage.js               ← the / page: grows the front plant, draws the cards
        ├── page.js                    ← the /s page
        ├── walk.js                    ← the /g page
        ├── meaningspage.js            ← the /meanings page's own opening
        ├── plain.js                   ← /download, /wild and /privacy: words and a chooser
        ├── door.js                    ← the /t page
        ├── walkpage.js, longwalk.js   ← the Long Walk: the page, and the plot drawn
        ├── quietpage.js, quietgarden.js ← the Quiet Garden: the page, and the plot drawn
        ├── crosspage.js, crossing.js  ← the Crossing: the page, and the plot drawn
        ├── orchardpage.js, orchard.js ← the Orchard: the page, and the plot drawn
        ├── knotpage.js, knot.js       ← the Knot Garden: the page, and the plot drawn
        ├── seedbedpage.js, seedbed.js ← the Seedbed: the page, and the plot drawn
        ├── framepage.js, frame.js     ← the Cold Frame: the page, and the plot drawn
        ├── plant.js                   ← grows a plant in the wasm module, draws it in WebGL2
        ├── sky.js                     ← the real sky, a port of SeedCore's Sky
        ├── gates.js                   ← the bar and the minimap; which areas are open
        ├── meanings.js                ← what each area's plants mean: the one table
        ├── link.js                    ← reads the fragment
        ├── languages.js               ← negotiation and the chooser
        ├── strings.js                 ← the catalogue, English written
        ├── testers.js                 ← standing in another language
        ├── garden.js, plots.js        ← the map, and the stand-in for areas not open
        ├── keys.js                    ← the keyboard, and the sheet under ?
        └── passages.js                ← theme, subtheme, and the draw
```

Almost everything is a file. No build step, no framework, no npm, and one PHP
script, `index.php`, which serves every page in `.pages/` with the type it is,
hands `/api/` to the plot service, sends the plant renderer compressed, and
stamps each page's scripts and stylesheet with the build they are, so a
returning browser cannot run yesterday's copy of one. Deploy with:

    tools/deploy.sh

That uploads this directory and then reads the headers back, which is the half
that matters — see **Deploying** below.

**`s` has no file extension on purpose.** It is the path every seed link
already points at and the path the association file claims, so it cannot grow a
`.html`.

**peacegarden.app does not read `.htaccess`.** This was the design's one
assumption and it is wrong on this host. The 20i vhost is nginx talking
straight to PHP-FPM: there is no Apache in the chain, and no `.htaccess`
anywhere under the document root is ever consulted. Checked on 4 September 2026
by putting a `RewriteRule` to a known-good path and a `Header always set` in
one, at the document root and one directory down, and watching neither happen.

The symptom is the one this file already warned about in another form: `/s`,
`/g`, `/t` and the association file all arrived as `application/octet-stream`,
so a browser saved the page instead of drawing it. Every request was a 200 and
every log line was clean.

**So `index.php` serves them**, and every page added since, because the same
nginx vhost offers exactly that and nothing else:

    location / { try_files $uri $uri/ @dispatch; }
    location @dispatch { if (-f $document_root/index.php) { rewrite ^ /index.php last; } }

A path with no file behind it reaches `index.php` with `REQUEST_URI` intact.
Which is why the pages live in `.pages/` rather than at the paths they are
served at: a file at `/s` wins at `try_files` and is served as a download
again, and `index.php` never sees the request. The leading dot is not
decoration — nginx's own `location ~ /\.(?!well-known(?:/|$)) { deny all; }`
makes the directory unreachable from outside, so each page has one address
rather than two.

**Every page added here has to be added to `ROUTES` in `index.php`** — and to
`PAGES` in `tools/site/serve.py`, which is the same rows in Python. `g` was
missing from the old list once and arrived as a download; nothing said so.
Serve the directory locally the way the host serves it before believing a page
works:

    python3 tools/site/serve.py

That is the reason it exists rather than `python3 -m http.server`, which types
a file by its extension and so cannot draw a single page here.

**The cost is that every page now needs PHP.** Static files did not. It is the
trade the host leaves available: `/s` is in every link already minted and
cannot grow an extension, so either something sets the header or the header is
wrong. If PHP is ever unavailable, the association file — and only that one —
can go back to `.well-known/` as a static file and be served with the wrong
type; Apple's CDN parsed it happily for the four days it was, reporting
`Apple-Origin-Format: json` while the origin said `application/octet-stream`.
That is Apple being lenient about a rule Apple documents, and it is a fallback
rather than a plan.

**Getting `.htaccess` honoured instead** would mean 20i moving this site off
its nginx-only config, which is a support request rather than anything in this
repository. It would make `.htaccess` here do the routing — it is written to
send paths to `index.php` rather than serve them itself, so one mechanism would
still serve them and the two hosts could not disagree about what `/s` is. It
names only the first four paths, though, `/s`, `/g`, `/t` and the association
file, and every page since would need adding to it before that day.

**`/t` is the test roster** — forty-three gardeners, one per language, for
looking at the site from where a reader of it stands. There are no accounts
behind it: `assets/js/testers.js` opens with what a tester is and why a static
site has nobody to log in. It is `noindex, nofollow`, it guards nothing, and it
can ship or be left out of an upload without anything else noticing.

**There is one drawing.** `tools/icon/make_icon.py` writes `assets/icon.svg`,
`assets/icon-180.png` and `favicon.ico` from the same dials, and every page
points the `<img>` in its bar at that same `icon.svg`. Change the dials and
re-run the generator; hand-edit none of them.

There used to be a second file, `assets/mark.svg`, described here as a copy of
the canonical drawing and kept in step by hand. It was not: the icon was
inverted on 4 September and the copy was not remade, so for two days every page
carried the old mark in its header and the new one in its tab, on screen
together, and nothing said so. Deleting the copy is what actually closes that —
a deploy step that re-copies it would only have made the drift shorter.

**This README is not uploaded.** `tools/deploy.sh` excludes it and deletes it
if an earlier upload left one there, which one had. It is addressed to whoever
is deploying rather than to a reader of the site.

**Two deploy steps that are settings rather than files:**

- **Request logging on `/s`.** docs/WEBSITE.md asks for none, or the shortest
  the host permits. That is a 20i control-panel setting. Nothing on the page
  claims more than what is actually switched off, and nothing should. Note that
  `/s` is now a PHP request rather than a static one, so it appears in whatever
  the host logs for PHP as well.
- **The root.** `peacegarden.app/` answered 403 until 16 September, and
  `index.php` returned that 403 deliberately: with an index in place the root
  would otherwise have become whatever the script did next, and what the root
  should do was an open question in docs/WEBSITE.md. *Superseded 16 September*:
  an App Store listing needs a support URL a reviewer can open, so `/` is a
  page, `.pages/index`. Since 24 September it is the front — a plant on a
  stage, three steps, ten area cards — drawn by `assets/js/frontpage.js`.

## What the next page reuses

`/p/…`, the shared plant page, is phase 2 and is not here. What is here is the
half of it that has nothing to do with a service, and it is deliberately in
modules of its own rather than inside the `/s` page:

| | |
| --- | --- |
| `languages.js` | negotiation, the chooser, the written-case list |
| `strings.js` | the catalogue and the silent English fallback |
| `passages.js` | theme and subtheme off a name, and the draw |

A plant page reads the same manifest and picks its passage the same way. What
it adds is a plot service — **same-origin on 20i, decided 2 September**, so a
plant page fetches `/api/…` on this host rather than reaching another domain.
That is worth writing down where somebody will look for it: it means the page
has no cross-origin story to design, and it means a request to the service is a
request to the same log as everything else. The fragment property that `/s`
depends on is a property of `/s` alone, because `/p` publishes its payload on
purpose.

## Checking the page

```sh
tools/deploy.sh --check
```

That reads the headers on every path that has ever been served with the wrong
one, and on a sample of the ones nginx types from its own `mime.types`. Wanted
on `/s`: `HTTP/2 200` and `content-type: text/html`. `application/octet-stream`
means a file is sitting at that path and nginx is serving it before
`index.php`, so the page will download rather than draw.

Two of the rows are 404s on purpose, and a 200 on either is the failure:
`/strings/en.json`, because English is written into `strings.js` and
`loadStrings` reads the status; and `/README.md`, because this file belongs to
whoever deploys.

The fragment is the payload and never reaches the server, so a seed can only be
tested in a browser. Any link the app mints will do; `assets/js/link.js` also
carries `PINNED`, the same fragment `PollenLinkTests` and `tools/reference/`
both agree on, which is a valid offer from *Marcus* of *Aurelia nocturna*.

## Already filled in

The Team ID (`R94VDZ56RY`) and bundle identifier (`app.peacegarden`) are in the
file. If either changes in `project.yml`, it changes here too — they have to
agree or iOS silently declines to associate the domain.

The `appclips` entry names the clip's bundle ID, which by convention is the
app's with `.Clip` appended. It is harmless to serve before the App Clip target
exists — iOS simply finds nothing to invoke.

## The rules iOS actually enforces

These are the ones that quietly break associated domains:

- **No file extension.** `apple-app-site-association`, not `.json`.
- **Served as `application/json`.** Some hosts guess `text/plain` for an
  extensionless file and iOS rejects it.
- **HTTPS, valid certificate, no redirects.** Not even http → https. The file
  must be at the final URL directly.
- **No authentication.** Not behind a login, a maintenance page, or a
  "coming soon" splash.
- **Apple's CDN caches it.** A change can take up to 24 hours to reach devices,
  so get it right before testing rather than iterating against it.

## Deploying

```sh
tools/deploy.sh              # upload, then check
tools/deploy.sh --dry-run    # say what would change, touch nothing
tools/deploy.sh --check      # check what is live, upload nothing
```

That uploads this directory and then reads back the status and content type of
every path, plus whether the Team ID in the association file still matches
`project.yml`.

It uploads with `--delete`, because the failure that prevents is invisible: a
file left at `/s` by an older upload wins at nginx's `try_files` and is served
as a download, and `index.php` is never reached. `.well-known/` is the one
directory left alone — certificate renewal writes an ACME challenge there, and
nothing of ours lives in it any more.

It needs the `peacegarden` host in `~/.ssh/config`, which is written, and its
key registered in **My20i → peacegarden.app → Security → SSH Access**. Paste
the contents of `~/.ssh/peacegarden_app.pub` there under a handle such as
`peacegarden-deploy`.

The two failure modes read very differently, and it is worth knowing which is
which before diagnosing the wrong one:

| What ssh says | What it means |
| --- | --- |
| `Permission denied (publickey)` | The key is not registered yet. The host and the SSH user are fine. |
| Connection reset at the handshake | The **IP allowlist** on that same page. It gates SSH before authentication, so it reads like a network fault rather than a permissions one. |

Failing all of that, upload by hand to the document root of `peacegarden.app` —
the directory serving the site, usually `public_html`. `.pages` starts with a
dot, so 20i's file manager may hide it. Turn on "show hidden files", or use
SFTP.

## Checking it

```sh
curl -sSI https://peacegarden.app/.well-known/apple-app-site-association
```

Wanted: `HTTP/2 200` and `content-type: application/json`. A `301`, a `404`, or
`text/html` all mean it will not work.

```sh
curl -sS https://peacegarden.app/.well-known/apple-app-site-association | python3 -m json.tool
```

Should print the JSON with your real Team ID in it.

Apple's own validator — replace the domain:

```
https://app-site-association.cdn-apple.com/a/v1/peacegarden.app
```

That is what devices actually fetch. If it returns nothing, no amount of
correctness on your server matters yet; wait for the cache and try again.

## Testing on a device

With the app installed and the entitlement in place, send yourself a seed link
and tap it. It should open the app. If it opens Safari instead:

1. Check the validator URL above returns your file.
2. Check the Team ID matches the one the app was signed with.
3. Delete and reinstall — associated domains are fetched at install time.
4. On a development build, `applinks:peacegarden.app?mode=developer` in the
   entitlement makes iOS bypass its CDN and fetch from your server directly.

## The plot service (`/api/`)

`index.php` hands every path under `/api/` to `.api/router.php`. The dot keeps
the service's own files unreachable, as it does `.pages/`.

- `GET /api/walk` — plots opened, never fewer than one. `GET /api/walk/plot/{n}`
  — a plot's plantings: seed, both parents, the meeting, and the spot to stand
  it on.
- `GET /api/garden` — the ten areas and which are open. **The app asks this on
  the screen that puts the question**, since 21 September; before that it read
  a list compiled into itself and learned that an area had opened when it was
  next updated. It carries nothing either way: no token, no body, no limit.
- **The Quiet Garden**, `.api/QuietGarden.php` and `.api/RoomStore.php`: a
  `quiet_garden` table of its own beside the walk's, because the two share no
  column after `encounter` — a walk row names a side of a path and a tier of a
  border, a room row names a corner and a place in a group of three. `GET
  /api/quiet` and `GET /api/quiet/plot/{n}` read it, and `/quiet` draws it.
  Checked by `tools/reference/check_quiet_garden.php`, in CI.
- **An offer carries the area its plant is for**, and is planted there when it
  is answered. The routes are still spelled `/api/walk/…` because an installed
  app calls them and cannot be asked to learn a new address; what is the travel
  area's alone is `GET /api/walk` and `GET /api/walk/plot/{n}`.
- **The ambassador is in plot 0 and is not a row**, `.api/Ambassadors.php`.
  *Halula crassicaulis* was placed by the rule into an empty walk before
  anything was shared, and its slot and nudge are pure functions of its pinned
  seed, so the service re-derives the placement rather than storing it. It is
  handed to the rule ahead of the stored arrivals — every shared plant is graded
  against it — and served at the head of plot 0 with an **empty `parents` and no
  meeting**, because it was minted and has neither; a reader grows it from its
  seed alone. Nothing to hide, nothing to withdraw, nothing for a backup to
  carry, and `WalkStore::plant` refuses an ambassador's seed outright. Checked
  by `tools/reference/check_ambassador.php`, in CI. The Quiet Garden's, *Olyne
  paniculata*, stands beside its bench the same way.
- **The asking**, `.api/Offers.php`, which is how anything gets into the walk:
  - `POST /api/walk/offer` — `{to, from, plant}`. One gardener offers a plant,
    addressed to the sixteen bytes the other minted at their meeting. It plants
    nothing.
  - `POST /api/walk/pending` — `{tokens: […]}`, at most 128. Everything touching
    those tokens either way round: offers made to this phone, and the state of
    offers made from it. This is the request the app's *Alert me when a joint
    seed is shared* switch turns **off entirely**.
  - `POST /api/walk/answer` — `{seed, to, yes}`. Only the token an offer was
    addressed to can answer it. Yes plants it by the rule; no is final, because
    there is one offer per plant.
  - `POST /api/walk/withdraw` — `{seed, token}`. Either gardener, at any time.
    **Taking back deletes** (since 24 September): the seed, both parents, the
    meeting and the traits leave the live database. An accepted planting keeps
    only its place, hidden — the area is append-only and the next arrival is
    placed against what is already standing, so the slot stays taken, the
    border keeps the gap, and the row keeps exactly what its area's rule reads
    (`.api/TakenBack.php` lists it per area). The offer keeps keyed
    fingerprints of the seed and the two tokens, the word `withdrawn` and its
    two times: enough to refuse the plant if anybody offers it again — its
    seed, parents and meeting were public while it stood — and to tell both
    phones, which ask by token. The key is `offer_key`, which the nightly copy
    carries with `walk_offers`. **A declined offer is erased the same way**
    and keeps the word `declined`, which still refuses a second offer. Rows
    withdrawn or declined before this are erased by a migration that runs on
    every request and finds nothing once it has run.
  - **An offer nobody answers lapses after thirty days**: it becomes a
    withdrawal, answered at the moment it lapsed, and is erased the same way.
    Checked whenever the offer is looked up, swept on every `offer` and
    `pending` request, and swept every five minutes by `.api/sweep.php`
    (below).
  - A token carries **consent, not authenticity**. The service cannot tell two
    tokens minted at a real meeting from two minted by one person, so it cannot
    tell a real pair of gardeners from somebody planting invented crossings.
    What it does prevent is anybody planting *somebody else's* plant or
    answering for them. Rate limiting belongs in front of the service.
  - Checked by `tools/reference/check_offers.php`, in CI.
- **How often one caller may write**, `.api/Limits.php`: 18 offers, 55 answers,
  28 withdrawals and 220 askings per address in a window of fifty-five minutes
  — the hourly 20, 60, 30 and 240 scaled to it — answered `429` with a
  `Retry-After` when the allowance is gone. It is in PHP because the vhost is
  not ours to configure, so it caps what is *written* rather than what arrives
  — which is the half that matters on an append-only walk. What is stored is a
  salted digest of the address and a count. The salt is random per install and
  lives in the same database, so anybody holding the database could try every
  IPv4 address against a digest; what protects an address is that its row is
  deleted once its window is over — at the first limited request after it, or
  at the next sweep, whichever comes first — and that no backup copies the
  table. **The window is fifty-five minutes and the sweep comes every five**, so
  no scrambled address is kept longer than an hour, which is what the privacy
  page says. Checked by `tools/reference/check_limits.php`, in CI, down to a
  two-hour quiet spell swept only by cron.
- **The sweep**, `.api/sweep.php`: a command, not a page, run from cron every
  five minutes.
  It drops every rate-limit window that has ended and lapses every offer that
  has waited thirty days, for the hours when no request comes to do either. It
  is safe beside the service and beside itself — a second run, or four at once,
  or a request lapsing the same offer, changes nothing further — and says one
  line in its log when it removed something, in counts only. Checked by
  `tools/reference/check_sweep.php`, in CI. Its cron line is under *Keeping
  the walk*.
- `POST /api/walk/plant` — **answers 403**: it is the one route that plants with
  nobody asked, and it exists for the reference check. A local copy opens it in
  `.api/config.php` (copy `config.example.php`; git ignores it and `deploy.sh`
  leaves the server's alone).
- The rule is `.api/LongWalk.php`, a port of SeedCore's, checked in CI by
  `tools/reference/check_long_walk.php`. The service refuses a seed that is not
  the cross of the parents it names.
- Storage defaults to SQLite **beside** `public_html` (`../peacegarden-data/`),
  never inside it. The 20i database goes in `config.php` once it exists.

Locally, with the browser pages beside it:
`php -S localhost:8803 -t Server tools/wasm/dev-router.php` — which serves
the whole site with the plot service behind it, same-origin the way the live
host is — then
`node tools/wasm/send-arrivals.mjs http://localhost:8803 120` to stand in for
phones — add `peace` as a third argument to send them to the Quiet Garden —
and open `/walk` or `/quiet`. The workbenches are `/dev/walk` and `/dev/quiet`,
which invent a garden rather than reading the service.

**`/plant.wasm` is revalidated, not cached for a day.** It used to be
`max-age=86400, must-revalidate`, on the reasoning that a module changes
rarely. The flaw is that a new build is not a new URL — the path never changes
— so a browser that fetched it yesterday ran yesterday's Swift today. The day
the Quiet Garden opened, a browser that had visited `/walk` the day before was
told `/quiet` could not be reached. It is `no-cache` now, which with the ETag
is one small conditional request rather than eight megabytes. A development
copy says `no-store`, because there it is rebuilt every few minutes, and the
two workbench pages ask for a fresh address each load as well, for copies a
browser stored before any of this.

**Against the app**, which is the only way to watch the asking end to end:
launch the simulator with `-pgPlots http://localhost:8803` and the app talks to
the local service instead of the live one. Debug builds only —
`PlotService.origin` is a constant, because an address the app would take from
anywhere is a way to send somebody's meetings somewhere else.

**Checked on the first deploy, 18 September:** `/.api/router.php`,
`/.api/config.php` and the rest answer 403 from nginx's dot rule, so PHP-FPM
never runs a service file directly. The service runs on the 20i MySQL database
named in the server's `config.php`.

## Keeping the walk

The Long Walk is append-only and every plant's place is worked out from what
arrived before it. Lose a row and everything after it stands somewhere else;
lose the order and they all do. None of it can be derived from anything else,
because the thing that made it was two people meeting once.

`.api/backup.php` takes the copy, from cron at 03:17 server time:

```
17 3 * * * /usr/bin/php $HOME/public_html/.api/backup.php >> $HOME/backups/backup.log 2>&1
```

It copies every area's table and its lock, `walk_offers` and `offer_key`
(`KEPT` in `backup.php` is the list), and leaves `rate_limits` and `rate_salt`
out on purpose — those are this hour's arithmetic about callers, and restoring
them would hand back spent allowance and re-key every bucket. It reads each
copy back before filing it, because a dump cut short is a valid gzip of a
valid beginning and restores most of the walk in silence. At most thirty stay
on the server, and none older than thirty days but the newest.

`.api/sweep.php` is the clean-up, every five minutes. The line, as it goes in
the server's crontab — in the 20i control panel, under *Scheduled Tasks* (cron
jobs), the schedule is every five minutes and the command is everything after
the five time fields:

```
*/5 * * * * /usr/bin/php $HOME/public_html/.api/sweep.php >> $HOME/backups/sweep.log 2>&1
```

`tools/backup.sh --install-cron` adds it over SSH beside the backup line, and
a second run finds both already there. **Five minutes is part of the privacy
page's arithmetic**: a rate-limit window is fifty-five, so a sweep any less
often lets a scrambled address outlive the hour. Without the line at all, an
address waits for the next limited request however long that is, and an offer
nobody answers for the next `offer` or `pending` request.

**A copy keeps what the database held that night.** A plant taken back, an
offer declined, or one that lapses, is erased from the live tables at once and
is in no copy taken afterwards. The copies taken before keep it until they go,
which is **thirty days on both sides**: the server prunes its own copies by
their date as well as their number, and on the Mac the pulled copies older than
thirty days are deleted after every pull that succeeds and **once a day by a
launchd job**, whether or not anybody pulls. The newest copy is kept on each
side however old it is, so a server whose cron stopped, or a Mac that has not
pulled for two months, still holds one copy — and that copy is older than
thirty days. **Time Machine and iCloud** keep their own history of
`~/Documents/Peace Garden backups`, which neither the job nor anything else
here can prune.

The Mac's job, from the checkout that will stay (it runs *that* `backup.sh`):

```
tools/backup.sh --install-launchd
```

It writes `~/Library/LaunchAgents/app.peacegarden.prune-backups.plist` from
the template in `tools/launchd/`, loads it with `launchctl bootstrap
gui/$(id -u)`, and runs `tools/backup.sh --prune` daily at 09:41 — nothing
else, no SSH and no pull — logging to `prune.log` in the backups folder. A
second install finds it there; a moved checkout or a new `$PG_BACKUPS` is
reloaded. `--uninstall-launchd` unloads and removes it. `launchctl kickstart
gui/$(id -u)/app.peacegarden.prune-backups` runs it once now, and the log says
whether it could reach the folder: `~/Documents` is behind macOS's privacy
controls, and a job the system has not allowed there fails with *Operation not
permitted*. Restoring an older copy brings erased rows back into the live tables,
and the first request afterwards erases them again.

From the Mac:

| | |
|---|---|
| `tools/backup.sh` | take a copy now, then pull every copy down |
| `tools/backup.sh --pull` | pull only, then prune the Mac's copies to thirty days |
| `tools/backup.sh --prune` | prune the Mac's copies to thirty days, pull nothing |
| `tools/backup.sh --install-launchd` | have this Mac run `--prune` daily; `--uninstall-launchd` stops it |
| `tools/backup.sh --install-cron` | put the backup and sweep lines in the server's crontab |
| `tools/backup.sh --restore-test` | load the newest copy and replay the walk out of it |
| `tools/backup.sh --rehearse` | the same, on a walk made for it |

The pulled copies go to `~/Documents/Peace Garden backups` (`$PG_BACKUPS` moves
them), and that is the copy that matters: `~/backups` on the 20i account is the
same disk, the same provider and the same billing relationship as the database
it came from.

### Restoring

```
gunzip -c ~/Documents/Peace\ Garden\ backups/walk-….sql.gz \
  | ssh peacegarden 'mysql --defaults-file=… <database>'
```

There is no one-line script for this on purpose. Restoring is the rare thing
done once under pressure, and a script that did it would also be a script that
could do it by accident. What the tooling does instead is prove beforehand that
the copy *will* restore.

### The test, and why it is a replay

`--restore-test` loads the newest copy into an empty MariaDB of the same version
(in Docker — there is no MySQL on the Mac) and then plants every arrival again,
in order, into a second empty database, by the same rule that placed it the
first time. Every column of every row has to come back the same. A row count
cannot see a lost ordering: each restored row is individually plausible and the
walk is wrong.

`--rehearse` does all of that on a walk it sows itself — two dozen arrivals, two
taken back, three offers — because until two people have met and agreed, the
real walk is empty and a test of it passes by having nothing to get wrong. It
then deletes one arrival from the middle of the restored copy and requires the
check to fail, so the check is known to be a check.

`tools/reference/check_backup.php` is the part that runs in CI: the reading-back,
the pruning, and the refusal to put a password on a command line.
