# Site mass test, 13–14 October 2026

Every page of peacegarden.app in all 43 languages, at phone, tablet and laptop
widths, light and dark, against a local copy; then a gentle read-only look at
the live site. The crawler is in `tools/masstest/site/` (its README says how to
run it locally and against the live site). No file in `Server/` was changed.

**In one line:** the site is sound where it counts (no script errors, failed
requests, wasm or WebGL failures, clipped text or sideways scroll on any of
3,411 local and 280 live page loads), and the faults are four: a returning
reader downloads the 3 MB plant module again on every area page (live only), the
front page jumps 450 px when the plant arrives on a phone, a third of the
site's words are in no language yet, and some text is below AA contrast.

## What ran

| Run | What | Count | Time |
| --- | --- | ---: | ---: |
| Local crawl | 20 pages (every route in `Server/index.php`, plus `/s` with the pinned offer) × 43 languages × 375 and 1280 px, dark; light on the 9 pages that follow the reader, and on the 11 always-dark area pages for 8 languages | 2,670 | 52 min (8 at once) |
| | Area pages opened on a plant (`?plot=1#p=…`), every language at 375, 8 at 1280 | 561 | |
| | Tablet, 768 px, 6 languages, every page | 120 | |
| | Reduced motion against full motion, en and ar, 375 | 60 | |
| | Read again: pages that met the local database away, or read before they settled | 510 + 510 | 12 + 17 min |
| Mid-width sweep | 6 lighter pages × 43 languages × 600, 768, 820, 1024 px (to chase finding 4) | 1,032 | 8 min |
| Interactions | chooser on every page; negotiation from 10 browser languages; a phone toolbar's resize on 11 area pages; landscape 812 × 375 × 3 languages × 20 pages; the `?` keyboard sheet; the `/meanings#` and `/garden#` fragments; stillness after 10 s under reduced motion | 165 | 16 min |
| Perf | every page cold and warm at 375, Slow 4G (150 ms, 1.6 Mbit/s), CPU ×4 | 20 (+6) | 7 min |
| Checks | `deploy.sh --check`'s 45 rows plus 29 it lacks, the association file, 175 public files hashed, 36 internal links | 74 rows | 2 min |
| **Live** | through a GET-only proxy: 20 pages × en, da, ar, de, ja, fi, uk × 375 and 1280, dark; the same checks; perf | 280 pages, 346 requests to the host | 17 min |

Per page: console errors and warnings, page exceptions, unhandled rejections,
failed and 4xx/5xx requests, every WebAssembly compile and instantiation and
how it ended, every WebGL context, horizontal overflow (`scrollWidth >
clientWidth`), text clipped by an ancestor, spilling out of its own box,
overlapping other text or past the screen edge, English left on a translated
page (the catalogue's own `lang="en"` marking, and text identical to the
English page's), raw keys and unfilled `{placeholders}`, links and fragments,
images without alt, controls without a name, right-to-left runs, axe-core 4.14
(WCAG 2.2 A/AA and best practice) on every page, LCP and CLS.

### The set-up

- **Server:** PHP 8.5's own server on 127.0.0.1:8822 with
  `tools/masstest/site/router.php`, which serves `Server/` the way the live
  nginx vhost does (dot paths 403, files typed from nginx's `mime.types` and
  gzipped, `README.md` absent as the deploy leaves it, everything else to
  `index.php`). The router's results match the live host row for row on all
  74 checked paths.
- **Plot service:** MariaDB 10.11 in Docker on 3408 (`pg-mt-site-db`), the
  schema made by the service's own migrations as `backup.sh --rehearse` relies
  on, sown by `seed.mjs` with 350 real crossings (35 an area, each sent to the
  area its genus names, its epithet as its kind) and 200 Wild Fields plants, 67
  with names, places and months beside them in seven scripts.
- **Browser:** Google Chrome 156, headless, with `playwright-core` 1.64. The
  Playwright Chromium in the cache (`chromium-1217`) was an empty shell of 448 KB
  with no framework, so it could not run. WebGL2 ran on the GPU (ANGLE Metal).

### Caveats

- **Chrome, not Safari.** Every iPhone and iPad browser is WebKit. Layout and
  wasm agree closely; WebGL, font metrics and the URL bar do not always. A
  WebKit pass is the next thing worth running.
- **The machine was shared and at times overloaded** (load average up to
  1,000, other agents building and simulating). Timings in the crawl are not
  measurements, and 392 "network never quiet within 8 s" readings are that.
  The perf runs were made with nothing else of mine running, but not on an
  idle machine; bytes and CLS are reliable, milliseconds approximate.
- **Docker went down for 14 minutes** (another agent filled the disk) during the
  crawl. The 508 area pages read in that window, and two read before they
  settled, were read again; none of what follows comes from that window. One
  `ERR_EMPTY_RESPONSE` on `/api/ground/plot/0` in the second reading is PHP's
  own server dropping a request under load, not the site.
- **My own init script broke on 510 pages of the first re-reading** (it watched
  the document element before there was one). They were read a third time; the
  numbers below are from that reading.
- Light was sampled on the always-dark area pages (they wear `body.night`
  whatever the reader's system says); in the sample the two schemes differed
  only where one of the two readings caught the page still loading. Device pixel ratio was 1 throughout.
- The **live** crawl went through a local proxy that fetched each address once,
  so its "warm" perf figures are not the host's; finding L1 was measured
  directly instead, with three single conditional GETs.

## Summary

Local, 3,411 page loads (last reading of each), 20 routes, 43 languages:

| Check | Pages with it | Distinct causes | Notes |
| --- | ---: | ---: | --- |
| JS exceptions, unhandled rejections | 0 | 0 | |
| Console errors / warnings | 1 / 1 | 1 | local server dropped a request; environment |
| Failed requests, HTTP 4xx/5xx | 1 / 0 | 1 | the same request |
| WebAssembly or WebGL failures | 0 | 0 | the module instantiated on all 1,963 pages that load it |
| Horizontal overflow | 2 (+8 in the sweep) | 1 | finding 4 |
| Text clipped, overlapping, past the edge | 0 / 0 / 2 | 1 | the same /g map at 768 px |
| Text spilling its box | 86 | 1 | front tagline's descenders, 4 px: not a fault |
| English on a translated page | 2,535 | 96 | finding 2; 30,219 element readings |
| Raw keys, `{placeholders}`, empty strings | 0 | 0 | |
| Images without alt, broken images | 0 | 0 | |
| Controls without an accessible name | 0 | 0 | |
| Broken internal links or fragments | 0 | 0 | 36 links; fragments checked in the browser |
| axe serious (all colour contrast) | 383 | 7 selectors | finding 3 |
| axe moderate (`page-has-heading-one`, /g) | 362 | 1 | finding 7 |
| axe minor (`aria-allowed-role`, `nav#keys`) | 1,342 | 1 | finding 7 |
| Right to left (ar, he) wrong | 0 | 0 | `dir="rtl"`, bar mirrored, no misdirected runs |
| Moves under reduced motion (after growing) | 0 | 0 | /wild repaints 60×/s: finding 5 |

Live, 280 page loads: the same results for the same pages and languages, with
no request refused by the proxy (nothing tried to write) and none to another
origin. Every one of the 74 header rows is as wanted, the association file
parses with appID `R94VDZ56RY.app.peacegarden` (matching `project.yml`), and all
175 public files and 19 pages are byte-identical to `main` except `/privacy`
(finding L2). The plant module is the same build on both (stamp
`6acae18f-81fc30`). `git diff --stat 3686d5d main -- Server` is empty and the
last change under `Server/` is `ca19eae` (12 October, 00:01), before the deploy
of 12 October that `.claude/HANDOVER.md` records, so the live site is current.

Perf at 375 px, Slow 4G, CPU ×4, cold (KB on the wire; "module" is when the
plant module had instantiated):

| Page | Local KB | Req | LCP s | CLS | Module | Live KB | LCP s | CLS | Module |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| front | 2,306 | 15 | 1.1 | **0.578** | 12.1 s | 3,086 | 1.1 | **0.323** | 15.8 s |
| walk (and the other 9 areas, ±1%) | 2,501 | 34 | 1.6 | 0.050 | 12.5 s | 3,276 | 1.6 | 0.056 | 16.4 s |
| wild | 2,544 | 47 | 1.2 | 0.023 | 13.0 s | 3,338 | 1.2 | 0.024 | 16.8 s |
| meanings | 101 | 13 | 1.0 | 0.161 | | 98 | 1.0 | 0.161 | |
| g, garden | 101 | 14 | 0.9 | 0.062 | | 96 | 0.9 | 0.062 | |
| s, s with a seed | 83, 105 | 12, 13 | 1.1 | 0 | | 80, 102 | 1.0 | 0 | |
| download, privacy, t | 65, 66, 44 | 8, 8, 6 | 0.9, 0.9, 0.5 | 0 | | 62, 63, 40 | 0.9 | 0 | |

German on the front: CLS 0.845. Live is 0.8 MB heavier on every page that
grows a plant because the host's CDN turns brotli into gzip (2.2 → 3.0 MB),
which `Server/index.php` already documents. LCP ignores a WebGL canvas, so on
the area pages it is a paragraph, not the plot; the plot can draw only once the
module has arrived (the "Module" column).

## Findings, most severe first

### L1. A returning reader downloads the 3 MB plant module again on every page that grows a plant (live)

**What happens.** `/plant.wasm` is sent `Cache-Control: public, no-cache` with
an ETag, on the reasoning (`Server/index.php:196-213`, `Server/README.md:532`)
that a return visit costs "one small conditional request rather than eight
megabytes". On the live host the conditional request is answered `200` with
the whole 3,050,828 bytes, so every visit to the front or any of the eleven
area pages, and every move between areas, downloads the module again: on Slow
4G that is about 16 s before the plot can draw, every time, and 3 MB of a
reader's data allowance per page. Pages and the stylesheet do revalidate
(`304`, checked on `/s` and `/assets/site.css`).

**Where.** Live only: `/`, `/wild`, `/walk`, `/quiet`, `/cross`, `/orchard`,
`/knot`, `/seedbed`, `/frame`, `/glasshouse`, `/coppice`, `/ground`, every
language and width. The local copy answers `304` (warm reload 1–13 KB).

**Repro.**
```
GET https://peacegarden.app/plant.wasm?v=6acae18f-81fc30
If-None-Match: "6acae18f-2e8d4c"
```
**Evidence** (13 October, 23:41 UTC; the request above, then again with a
browser's `Accept-Encoding`): `200`, 3,050,828 bytes, `etag: "6acae18f-2e8d4c"` (the
same tag that was sent), `x-powered-by: PHP/8.3.35`, `x-origin-cache-status:
MISS`, `x-cdn-cache-status: MISS`. The same request shape for `/s` and
`/assets/site.css` answered `304`. So the request reaches PHP and the
comparison at `index.php:186` does not see the tag: most likely 20i's CDN drops
`If-None-Match` on a miss for this response (it already rewrites
`Accept-Encoding` on the way through, `index.php:148-155`).

**Fixes.**
- **A (recommended).** Make the stamped address immutable: the pages already
  ask for `/plant.wasm?v=<mtime-size>` (`index.php:273-279`), so when `v`
  equals the current stamp send `Cache-Control: public, max-age=31536000,
  immutable` and no revalidation is ever needed; keep `no-cache` for the bare
  `/plant.wasm`. It works whatever the CDN does with conditional requests.
- B. Find where `If-None-Match` is lost (log it at the top of the wasm branch
  for a day, or ask 20i), and keep the current header.
- C. Leave it, and say in `Server/README.md` that the module is downloaded on
  every visit.

### 1. The front page jumps 450 px on a phone when the plant arrives

**What happens.** At phone width the front's plant stage is placed above the
words (`order: -1`, `Server/assets/site.css:2895-2897`) but stays `hidden`
(`Server/.pages/index:101`) until the module has downloaded and grown the plant
(`Server/assets/js/frontpage.js:42`). On Slow 4G that is 12 s locally and
about 16 s live, by which time the reader is reading the heading; the heading,
the lead and the buttons then drop 446 px. A first, smaller shift at about 1 s
is the page writing its words into empty elements.

**Where.** `/`, every language, below 760 px. CLS 0.578 (en) and 0.845 (de)
locally, 0.323 (en) live; anything above 0.25 is "poor". Wider screens put the
stage beside the words and do not jump.

**Evidence.** `01-front-layout-shift.jpg` (4 s and 16 s). Layout-shift sources:
`div.front-hero__words 19,200 338x263 -> 19,646 338x166` at 12.2 s (0.323), and
`section.front-steps 19,363 -> 19,544` at 1.1 s (0.255).

**Repro.** Chrome, 375 × 812, DevTools → Network "Slow 4G", CPU 4× slowdown,
open `/`.

**Fixes.**
- **A (recommended).** Lay the stage out from the first paint: drop `hidden`
  from `#plant-stage`, keep its `aspect-ratio: 4 / 5` box (with the soft pool
  it already draws) and hide only the canvas until the plant is drawn; if the
  module fails, collapse it then (rare, and no worse than today).
- B. On phones, put the stage after the words (remove `order: -1`), so the
  plant arrives below what is being read.
- C. Leave it.

### 2. A third of the site's words are in no language yet, and the privacy page's newest paragraph is English in 41

**What happens.** 44 of the 146 keys in `strings.js` have no translation in any
of the 42 catalogues, so they read in English on every translated page
(silently, by design: `catalogue()` in `strings.js:719`). Where they show:

- every area page: the about paragraph (`walkAbout`, `quietAbout`,
  `crossAbout`, `orchardAbout`, `knotAbout`, `seedbedAbout`, `frameAbout`,
  `glasshouseAbout`, `coppiceAbout`, `groundAbout`), "Growing the plants…"
  (`walkGrowing`), and the move pad's names and the `?` keyboard sheet's rows
  (`moveUp/Down/Left/Right`, `zoomIn/Out`, `moveHome`, `walkTurnAnti/Clock`,
  `plantKey`);
- the plant panel on every area page: **"Close"** and **"Send as a postcard"**
  (`plantClose`, `plantPostcard`, with `plantPostcardText`, `plantCopied`,
  `plantCopyThis`, `plantAmbassador`);
- `/download` (`downloadBody`), `/g` (`gardenBody`), and the failure lines
  (`walkEmpty`, `walkAway`, `quietAway` … `groundAway`, `goOn`, `walkTitle`,
  `walkThisArea`, `walkBody`).

Besides those: **`privacy10`** (the launch-moment update check, deployed 12
October) is only in Danish, so the privacy notice is English in that
paragraph for 41 languages; **Greenlandic** has 13 of 146 strings, so `/?l=kl`
is almost all English; and some English is written outside the catalogue: the
dictionary's roots, endings and examples on `/meanings` (`meanings.js`,
marked `lang="en"`), the English names of each area page's root glyphs
(`#gathers .gathers__heads`), the `/g` notice (`#invented`, in the markup), the
`/g` pad's `aria-label`s "Up", "Left", "Right", "Down"
(`Server/.pages/g:151-154`), and the download page's version line "1.0 (1) ·
iPhone and iPad · iOS 17 and later" (`Server/.pages/download`).

**Where.** 19 routes, 42 languages, both widths, both schemes. Right-to-left
pages handle it correctly: each English run carries `lang="en" dir="ltr"`, so
nothing is scrambled.

**Evidence.** `04-english-on-translated-pages.jpg`; the analysis counts
2,535 translated pages with English on them, 96 causes. The catalogue table is below.

**Fixes.**
- **A (recommended).** Put the 44 keys and `privacy10` into the next
  translation round, in this order: `privacy10` (it is the privacy notice),
  the plant panel's six, the pad and sheet's ten, the ten about paragraphs,
  then the rest; and decide Greenlandic separately (finish it, or take it out
  of `languages.json` until it is finished).
- B. Before then, follow the glyphs-over-words rule where it fits: the panel's
  "Close" as ✕ and "Send as a postcard" as the postcard glyph, with the words
  kept as their accessible names; the pad already has glyphs.
- C. Leave it as the documented silent fallback.

### 3. Some text is below WCAG AA contrast

**What happens.** (a) The front's area cards set white names (11 px) and 86%
white meanings (13 px) on the area's ground colour. On the two light grounds,
Waiting and Pattern (`#968b78`, `Server/assets/js/gates.js:84,115`), that is
3.35:1 and 2.92:1; on Kinship (`#66704a`, `gates.js:108`) the meaning is
4.40:1. AA for this size is 4.5:1. (b) In light mode the faint grey,
`--faint: rgba(18,18,18,0.52)` (`Server/assets/site.css:70`), comes to
`#7f7f7f` on `#f6f6f6`, 3.71:1: the seed page's passage source, the
`/meanings` labels and roots, the foot's privacy link on `/g`, the app note on
`/s`. The comment above it gives the dark figures only.

**Where.** (a) `/`, every language, width and scheme (the cards do not follow
the scheme). (b) `/s` with a seed, `/meanings`, `/g`, `/garden`, light scheme.

**Evidence.** `02-contrast.jpg`; axe `color-contrast`, e.g. `{"fg":"#f0efec",
"bg":"#968b78","ratio":2.91,"need":"4.5:1","size":"13px"}`.

**Fixes.**
- **A (recommended).** (a) Give the card text on those grounds ink instead of
  white (`#121212` on `#968b78` is 5.59:1), or darken the two light grounds
  for the cards only to about `#70685a` (4.58:1 with the 86% white); nudge
  Kinship to `#646e49`. (b) `--faint` in light mode to `rgba(18,18,18,0.6)`
  (`#6d6d6d`, 4.79:1).
- B. Make the card meaning full white and 14 px (still 3.35:1 on `#968b78`, so
  (a) is needed for those two cards either way).
- C. Leave it.

### 4. The garden map runs off a tablet screen in long-word languages

**What happens.** Above 46rem the map is `grid-template-columns: repeat(5,
1fr)` with no overflow handling (`Server/assets/site.css:636-643`); below it,
the map becomes its own scrolling strip (`site.css:660-676`). A `1fr` column
will not shrink below its longest word, so a long area name widens its column
and the grid outgrows the page: the right-hand column (The Long Walk, The
Crossing) is cut off or pannable.

**Where.** `/g` and `/garden`: at 768 px Finnish (841 px wide), Swedish (816),
Icelandic (801), Norwegian (777), Macedonian (776); at 820 px Finnish (868),
Swedish (842), Icelandic (826). Fine at 600 and 1024 px and in the other 38
languages.

**Evidence.** `03-garden-map-overflow.jpg`; `scrollWidth 841 > clientWidth
768` with `span.garden-cell__name "Puukujanne"` at x 721–828.

**Repro.** `/garden?l=fi` at 768 × 1024.

**Fixes.**
- **A (recommended).** `repeat(5, minmax(0, 1fr))` on `.garden-grid`, and
  `overflow-wrap: anywhere; hyphens: auto` on `.garden-cell__name`
  (`site.css:705`), so a long name breaks inside its cell.
- B. Raise the scrolling-strip breakpoint from 46rem to about 64rem, so
  tablets get the strip phones already have.
- C. Both.

### L2. Paths that visitors wear are switched on at the live site, which the docs say is off

**What happens.** Live `GET /api/wild` carries `"wear":{"cell":0.5,"cells":128,
"most":256,"seen":8}`, so `/wild` loads `wear.js` and a reader who drags the
field sends the cells crossed (`POST /api/wild/wear`); and live `/privacy`
includes `privacy9`, the paragraph that describes it. That is exactly what the
code does when the server's `config.php` says `'wear' => true`. But
`Server/README.md:490-503`, `docs/WEB-GARDENS.md:20-23` and `:3147-3153`, and
`config.example.php` all say the server's does not, and the local copy (with no
`wear` key) leaves the paragraph out; that paragraph is the one byte difference
between live and `main`. The privacy page does say what is sent, in 41
languages (Greenlandic falls back to English).

**Where.** Live `/wild`, `/api/wild`, `/privacy`. Not tested further: the
crawl sent no POST.

**Fixes.**
- **A (recommended), if it was turned on deliberately:** say so in
  `Server/README.md` and `docs/WEB-GARDENS.md` with the date, and add a row to
  `deploy.sh --check` that reads `/api/wild` and reports whether `wear` is on,
  so the docs and the host cannot drift again.
- B. If it was not: remove `'wear' => true` from the server's `config.php`.

### 5. The Wild Fields repaint their fireflies 60 times a second under reduced motion

**What happens.** The firefly layer's loop skips frames to hold 30 fps, except
under reduced motion, where the condition lets every frame through
(`Server/assets/js/wildfields.js:1243-1245`: `if (now - last < 33 &&
!still.matches) return;`). With reduced motion the fireflies are frozen
(`time = 0`), so it redraws an identical picture 60 times a second, twice as
often as for a reader who asked for motion. Nothing moves on screen (checked:
0 changed pixels over 3 s), so this is battery and heat on a phone, not motion.

**Where.** `/wild`, every language, reduced motion on.

**Fixes.**
- **A (recommended).** Under reduced motion, paint once, then only when the
  view moves (the stage already redraws on a turn or a drag).
- B. Use the same 33 ms gate in both modes.
- C. Leave it.

### 6. Two pieces of copy no longer match the app

- `/download` still names "1.0 (1)", and its comment says no build has been
  uploaded; `project.yml` is at build 8 and builds go to TestFlight. "Not open
  yet." still stands for the public.
- The `/g` notice (`#invented`) says "The plants drawn here stand in for the
  areas not open yet", but all ten areas are open (`Areas::OPEN`), so the map
  draws no stand-ins. It is also English in every language.

**Fixes.** **A (recommended):** drop the version line until there is an App
Store version to name (or name the TestFlight build), and remove or rewrite the
`/g` notice. B: leave until launch.

### 7. Small accessibility notes from axe

- `nav#keys role="group"` on the eleven area pages (`aria-allowed-role`,
  minor): `role="group"` overrides the `nav` landmark. **A:** make it a `div
  role="group"`, or drop the role and keep `nav` with an `aria-label`.
- `/g` has no `h1` (`page-has-heading-one`, moderate): its `h1` is inside the
  hidden area section. **A:** a visually hidden `h1` naming the garden.

### L3. Live headers worth tidying (low)

- No `Strict-Transport-Security`, `Content-Security-Policy` or
  `Referrer-Policy` on any response, and `X-Powered-By: PHP/8.3.35` names the
  PHP version.
- Gzipped static files (`/assets/*`) come without `Vary: Accept-Encoding`
  (the CDN's doing; the module and pages carry it).

**A (recommended):** add HSTS and `Referrer-Policy: no-referrer` from
`index.php` for pages (static files are the vhost's), and ask 20i to drop
`X-Powered-By`; a CSP is worth it only once the inline import map is hashed.
B: leave it; there are no forms, cookies or sign-ins.

### 8. `deploy.sh --check` does not read seven of the pages it deploys (low)

Its list stops at `/glasshouse`, `/coppice` and `/ground` among the areas and
lacks `/quiet`, `/cross`, `/orchard`, `/knot`, `/seedbed`, `/frame` and
`/privacy`, and seven areas' `/api/…` routes. All answered correctly here
(`checks.mjs`'s extra rows). **A:** add them, beside the wear row of L2.

## Checked and found right

- **Chooser:** on all 19 pages that have one, picking Hebrew redraws the page
  in Hebrew, right to left, within 1.5 s and without a reload, remembers it on
  the next page opened without `?l=`, and `?l=da` still outranks it. `/t` has
  no chooser and is English by design.
- **Negotiation** from the browser's languages: da-DK → da, pt-BR → pt, no-NO
  and nb-NO → nb, zh-TW → zh (Simplified; there is no Traditional catalogue),
  sr-Latn-RS → sr (Cyrillic), he-IL → he and right to left, kl-GL → kl, cy-GB →
  cy, sw-KE → English.
- **Right to left:** every Arabic and Hebrew page is `dir="rtl"` with the bar
  mirrored; no left-to-right box holds Arabic or Hebrew, and English runs are
  marked `lang="en" dir="ltr"`.
- **A phone's toolbar** taking 100 px of height does not regrow any area's
  plants; **landscape** (812 × 375) shows no overflow, clipping or overlap on
  any page in en, de or ar.
- **The `?` sheet** opens with focus inside and closes on Escape on the 15
  pages that have one; `/meanings#<area>` lands on that entry and
  `/garden#<area>` opens on that area, for all ten.
- **Reduced motion:** once the plants have grown, nothing moves on any area
  page or the front (two captures 3 s apart, identical), and nothing moves with
  full motion either except the Wild Fields' fireflies.
- **The association file** is `application/json`, valid, with appID
  `R94VDZ56RY.app.peacegarden` and the `/s*` component; the clip entry names
  `R94VDZ56RY.app.peacegarden.Clip`.
- `/strings/en.json` and `/README.md` are 404 and `/.api/curate.php` is 403, on
  both copies.

## The catalogues

146 keys. 101 in every language but Danish (102, with `privacy10`) and
Greenlandic (13). In no language: `gardenBody downloadBody walkTitle
walkThisArea walkBody walkAbout walkGrowing walkEmpty walkAway walkTurnAnti
walkTurnClock moveUp moveDown moveLeft moveRight zoomIn zoomOut moveHome
plantKey plantAmbassador plantPostcard plantPostcardText plantCopied
plantCopyThis plantClose quietAbout quietAway crossAbout crossAway
orchardAbout orchardAway knotAbout knotAway seedbedAbout seedbedAway
frameAbout frameAway glasshouseAbout glasshouseAway coppiceAbout coppiceAway
groundAbout groundAway goOn`.

## How gentle the live check was

346 GETs reached peacegarden.app between 23:20 and 23:31 UTC on 13 October,
one at a time and at least 500 ms apart, about 8.6 MB in all, each with the
User-Agent `PeaceGardenSiteCheck/1.0 (Peace Garden's own read-only site check;
GET only, 2 req/s; +https://peacegarden.app)`; then three single conditional
GETs for L1, made directly. Nothing was posted: the proxy answers anything but
a GET with 405 itself and allows only the pages, static files and the plot
service's read routes, and the crawler's `--live` refuses non-GET requests in
the browser as well. Neither refused anything during the crawl. The four
refusals in the proxy's log are its own self-test before the run.

## After the fixes, 14 October

Marcus chose **17A** (fix every finding, crawl again, add a WebKit pass) and
**18A** (paths that visitors wear stay on, and the docs say so). The fixes are
on `claude/site-fixes-2026-10-14`. Nothing was deployed and the live site was
not contacted: everything below is the local copy, served and sown as in *The
set-up*, with the wear switch on as the live host has it.

**In one line:** every finding is fixed, or made harmless where the host
decides; 4,799 page loads in Chrome and 510 in WebKit found nothing the fixes
left or brought in, and no page breaks its own Content-Security-Policy in
either engine.

### What changed

| Finding | Fix | Where |
| --- | --- | --- |
| L1, module downloaded on every visit | `/plant.wasm?v=<this build>` is `private, max-age=31536000, immutable`, so a returning browser asks for nothing. A stale stamp and the bare address keep `no-cache`. `If-None-Match` is read as a list with weak tags and `*`, `If-Modified-Since` is the fallback, `Last-Modified` is sent, and a 304 carries its cache headers and no `Content-Type`. `private` because whether 20i's CDN keys on the query cannot be seen from here, and one that did not would serve an old module under a new stamp for a year. | `Server/index.php`: the `/plant.wasm` branch, `$fresh`, `$notModified`, `$moduleStamp` |
| L3, headers | Everything PHP answers: `Strict-Transport-Security: max-age=31536000` (this name only), `Referrer-Policy: strict-origin-when-cross-origin`, `X-Content-Type-Options: nosniff`, no `X-Powered-By`. Pages: a `Content-Security-Policy` of the site's own files, the import map by its hash, `wasm-unsafe-eval` for the renderer, and style attributes allowed for WebKit's own `<select>` (below). The static files' headers, `Vary` among them, are nginx's and cannot be set from this repository. | the head of `Server/index.php`; `Server/README.md` §Headers |
| 1, the front jumps on a phone | The stage is laid out from the first paint, its canvas and hint invisible until `data-grown`; a browser with no WebGL2 or WebAssembly loses the stage at once, a module that fails later. The words, empty until the language is settled, stay invisible until `body[data-ready]`. | `Server/.pages/index` (`#plant-stage`), `frontpage.js`, `site.css` §The front |
| 3, contrast | The Cold Frame and Knot Garden cards on `#766d5e` (`LOOK.card`; the map keeps `#968b78`), every card meaning 92% white, light `--faint` 0.6 (`#6d6d6d`, 4.79:1). Dark mode unchanged. | `gates.js`, `frontpage.js`, `site.css` |
| 4, the map off a tablet | `repeat(5, minmax(0, 1fr))`; names hyphenate, and break anywhere as a last resort; from 46rem up the map is `min(36rem, 100vw − 32px)` wide and centred over the page. It only ever fitted by spilling past the 440 px measure, and squeezed into it every name broke into syllables, English included. | `site.css` §The garden |
| 5, fireflies at 60/s | Under reduced motion they are painted once and then only after the field is drawn (`whenDrawn` on the stage), in the same frame; with motion, 30/s as before. | `wildfields.js`: `flyOver`, the stage's `draw` |
| 6, stale copy | `/download` says "iPhone and iPad · iOS 17 and later", marked as English, and names no version; `deploy.sh --check` reads it against `project.yml`. `/g`'s stand-in notice shows only while some area on the map has no page, which is none of them now. | `Server/.pages/download`, `walk.js` |
| 7, axe | The key pad is a `div role="group"`, not a `nav` overridden as one. `/g`'s map section holds a visually hidden `h1` from the catalogue (`gardenTitle`) and is labelled by it; its English `aria-label` is gone. | the eleven area pages, `Server/.pages/g` |
| 8, the deploy check | Rows for `/quiet /cross /orchard /knot /seedbed /frame /privacy` and `/api/walk quiet cross orchard knot seedbed frame wild` (asked with a GET, as the plot service answers nothing else); the headers above; the stamped module immutable and the bare one `no-cache`, with a revalidation reported; wear on; `/download`'s iOS. `PG_BASE=` points it at a local copy, where every row passes. | `tools/deploy.sh` |
| L2, wear | On, as the host has it. `Server/README.md` and `docs/WEB-GARDENS.md` say so now, and the deploy check fails if `/api/wild` stops carrying `wear`. | the two docs, `tools/deploy.sh` |
| 2 (B), the panel's "Close" | The app's X in a 42 px hairline ring. `plantClose` is its accessible name, and the `?` sheet's, marked English while it falls back. No visible word added. | `plantpanel.js`, `site.css` |

**One allowance in the policy, for WebKit.** The WebKit pass found one
`style-src-attr` refusal on every page with the language chooser, at its
`<select>`. A page holding nothing but an empty `<select>` under the same
policy gets it too, and Chrome does not, so it is WebKit drawing its own
control. It changes nothing on screen (the bar is pixel-identical with and
without it), but a console with a refusal on every page hides a real one, so
the policy allows style attributes (`style-src-attr 'unsafe-inline'`).
`<style>` blocks, other hosts' stylesheets and every script stay refused.

### The re-crawl, before and after

Before is the run of 13 October above, after is 14 October: the same set-up
on the same machine, shared and loaded again (load average 150 to 360). Each
count is of the last reading of each page.

| Check | Before (13 Oct) | After (14 Oct) |
| --- | ---: | ---: |
| Page loads | 3,411 + 1,032 in the mid-width sweep | 3,411 + 1,032, and the two map pages again with the final map (356) |
| JS exceptions, unhandled rejections | 0 | 0 |
| Console errors / warnings | 1 / 1 (the local server) | 0 / 0 |
| Failed requests / HTTP 4xx–5xx | 1 / 0 | 0 / 0 |
| WebAssembly or WebGL failures | 0 (1,963 instantiated) | 0 (1,963 instantiated) |
| Content-Security-Policy refusals | no policy | **0**, every route, language, width and scheme |
| Horizontal overflow | 2 (+8 in the sweep) | **0** (+0) |
| Text clipped / overlapping / past the edge | 0 / 0 / 2 | 0 / 0 / **0** |
| axe serious (colour contrast) | 383 pages, 7 selectors | **0** |
| axe moderate (`page-has-heading-one`, /g) | 362 | **0** |
| axe minor (`aria-allowed-role`, `nav#keys`) | 1,342 | **0** |
| Front CLS at 375, Slow 4G, CPU ×4 | en 0.578, de 0.845, fi 0.803, ja 0.802, ar 0.757 | **0.003** in 40 languages, 0 in en, 0.03 in ar and he (the bar turning right to left); none at 0.1 or over |
| Front CLS at 375, the crawl, 43 languages | not tabulated | at most 0.003 |
| `/wild` animation frames a second under reduced motion | 64 (en), 12 (ar) | **0**, fireflies drawn and redrawn when the field moves |
| The module on a return visit (`/walk`, then `/quiet`, `/`, `/walk`) | a conditional request each time: 304 here, 200 and 3 MB live | **no request**: the browser's cache, 0 bytes |
| Interactions: chooser, negotiation, toolbar, landscape, `?` sheet, fragments, stillness | all as wanted | all as wanted: 19 of 19 choosers to Hebrew (`/t` is English by design), 20 of 20 negotiations, 0 of 11 regrown, 0 of 60 landscape faults, 15 of 15 sheets, 10 of 10 fragments, nothing moving on any of 12 pages after 10 s under reduced motion |
| English on a translated page | 2,535 pages, 96 causes | 2,177 pages, 95 causes: the `/g` notice is hidden, and nothing was translated |
| Text spilling its box | 86 (front tagline descenders, not a fault) | 86, the same |

Perf at 375, Slow 4G, CPU ×4, cold, the same five languages (en, de, fi, ja,
ar) on both copies, measured the same morning; KB on the wire, locally, so
brotli:

| Page | Before KB | Before CLS | After KB | After CLS |
| --- | ---: | ---: | ---: | ---: |
| front | 2,306–2,311 | 0.578–0.845 | 2,309–2,314 | 0.003 (ar 0.03) |
| g | 101–105 | 0.062–0.081 | 104–108 | 0.057–0.075 |
| meanings | 101–106 | 0.161–0.213 | 103–108 | 0.161–0.213 |

`/meanings` was not in this round. Its 0.16–0.21 is the dictionary being
written in once the language is settled, the shift the front had, open to
the same remedy.

**Area pages opened on a plant** shift by 0.03–0.05 on average at 375, with
about one reading in ten at 0.1 or over: the panel opens before its passage
has arrived and grows upward when it does. The same 121 readings on the copy
from before the fixes average 0.027, six of them over 0.1, and read side by
side one context at a time the two copies are alike (0.083 before, 0.065
after); the spread is timing. It predates this round and is worth a fix of its
own (keep the passage's room, or open the panel once the bank has arrived).

### WebKit

Playwright's WebKit, build 2370, the engine of every browser on an iPhone or
iPad, headless: every route in en, da, ar, de and ja at 375 and 1280, light and
dark, and every area page opened on a plant. 510 page loads.

| Check | WebKit |
| --- | ---: |
| JS exceptions, the pages' console errors, failed requests, 4xx/5xx | 0 |
| Content-Security-Policy refusals by the pages | **0** (one on every page with a chooser, without the `<select>` allowance) |
| WebAssembly instantiations, WebGL2 contexts | 350 and 350, all succeeded, a drawn canvas on every one |
| Horizontal overflow; clipped, overlapping or off-screen text | 0 |
| axe (contrast, headings, roles, names) | 0 |
| Right to left (ar) | `dir="rtl"` on every page but `/t`, which is English by design |

Two things about the pass rather than the site. axe's own run logs a style
refusal in WebKit, because it adds a `<style>` of its own and the policy
refuses it, as it should; the crawler marks those lines and leaves them out,
and none appears with axe switched off. And WebKit's browser process quit three
times on the loaded machine; the crawler now starts it again, and the pages it
was reading were read again. WebKit reports no layout shifts or largest paints,
so CLS and LCP are Chrome's alone.

### Checking the headers after the deploy

`tools/deploy.sh --check` reads every one of them back. By hand:
`curl -sSI https://peacegarden.app/` shows `strict-transport-security`,
`content-security-policy`, `referrer-policy` and no `x-powered-by`; the front
page's `data-module` address answers `cache-control: private,
max-age=31536000, immutable`; and in a browser, `/walk` then `/quiet` shows
`plant.wasm?v=…` from the disk cache in DevTools' Network panel, with nothing
sent.

### For the translation round

No catalogue string's English changed. `plantClose` ("Close") is now a
button's accessible name rather than its face: it still wants translating, and
is read aloud rather than shown. `gardenTitle` also names `/g`'s hidden `h1`.
The two English lines outside the catalogue keep their words: `/g`'s notice,
hidden while all ten areas are open, and `/download`'s "iPhone and iPad · iOS
17 and later", now marked as English.

### Evidence

`05-after-front-layout.jpg` (the front at 4 s and 18 s, before and after),
`06-after-contrast.jpg` (the cards, the seed page's source line, the
dictionary's labels), `07-after-map-panel-download.jpg` (the map at 768 in
Finnish, the panel's way out, `/download`).
