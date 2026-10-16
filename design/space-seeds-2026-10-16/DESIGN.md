# Zone C: space seeds through Peace Garden

16 October 2026. **A design, not a build.** This branch changes no app, server or site code. It is written for Marcus, and for the Autonaut session, which owns Autonaut's side and has answered the coordination questions (folded in below).

Sources read: the Hub's `~/Projects/interfulgent-hub/docs/suite-crossovers.md` (decisions 116A, 117 and Zone C), Autonaut's `~/Projects/autonaut/docs/BRIEF.md` §7, and this repo's plot service (`Server/.api/`), app (`App/PeaceGarden/`) and docs.

## The recommendation in short

1. **Zone C rides inside the one request every Peace Garden phone already makes when it opens**, `POST /api/walk/pending`. Every phone adds one fixed-size slot to it and gets one fixed-size bundle of seeds back, whether or not Autonaut is installed. Every Peace Garden user becomes the crowd a space seed hides in.
2. **The server never learns that space seeds exist.** It stores every slot it receives, padding included, in a pool that keeps no time, address or order, and hands out random bundles. Only Peace Garden on the phone can tell a space seed from padding, by a mark it computes itself.
3. **Finding happens on the phone and sends nothing back.** No request, row or log line records who found a seed.
4. **Autonaut and Peace Garden meet only in a folder in the suite App Group.** Autonaut drops in 16 random bytes when the person chooses "Send as a seed"; Peace Garden drops in the seeds it has found for them. Nothing in the folder carries a date or anything about what the person did.
5. **Peace Garden has no server seed exchange to hide in yet.** The Winds is designed but unbuilt. So the launch request has to go from every phone, with or without meetings, and The Winds should later use the same slot.

---

## 1. What "Zone C" is

**Zone C is the code name for the space-garden area in Peace Garden and the space-seed exchange that feeds it.** Marcus dictated "Peace Garden Zone C traffic"; it began as a dictation slip and he adopted it on 16 October. It is written down in three places and appears in no code:

- `~/Projects/interfulgent-hub/docs/suite-crossovers.md:80` — the definition.
- `~/Projects/autonaut/docs/BRIEF.md:222` — the decision that space seeds travel through Peace Garden, with the origin of the name.
- `~/Projects/autonaut/docs/HANDOVER-2026-10-15.md:72` — the Autonaut session's note.

In this repo the only mention is `.claude/HANDOVER.md:22`, which said to ask Marcus what it meant. That question is answered and does not need asking.

---

## 2. What Peace Garden has today

### 2.1 The three kinds of meeting

| | How it travels | Server? | Built |
|---|---|---|---|
| **The tap** | Multipeer between two phones after both feel the knock (`docs/EXCHANGE-PROTOCOL.md`) | None | Yes |
| **The link** | `PollenLink`: the seed in a URL fragment, by QR, AirDrop or message (`docs/SEEDS-ON-THE-WIND.md`) | None; the fragment never reaches a server | Yes |
| **The Winds** | A seed cast to a server queue to meet a stranger's (`docs/PHASES.md:205–318`) | A queue | **No** |

**The finding that shapes this design: there is no ordinary server seed exchange for a space seed to hide in.** The decision of 16 October assumed Peace Garden's own seed traffic already crosses the server. It does not: the tap and the link never touch it, and The Winds is a design.

### 2.2 What the app sends to the server

All of it is in `App/PeaceGarden/WebGarden/PlotService.swift`, through one ephemeral `URLSession` with no cookies and no cache (lines 305–316) and the system's default User-Agent, which names the app and its build number.

| Request | When | Body | Answer |
|---|---|---|---|
| `POST /api/walk/pending` | **Unprompted**, once each time the app starts (`PeaceGardenApp.swift:36–44`), only while *Alert me when a joint seed is shared* is on (on by default, `Sharing.swift:26`) and **only if the garden holds at least one meeting token** (`GardenModel.swift:559–566`) | `{"tokens":[…]}`, up to 128 tokens of 32 hex characters: 13 bytes empty, about 35 bytes more per token | `{"offers":[…],"wild":[…]}`, 23 bytes when nothing is waiting |
| `GET /api/garden` | Prompted: the screen that asks which areas are open | None | The ten areas |
| `POST /api/walk/offer`, `answer`, `withdraw` | Prompted, one gardener's choice | A seed, tokens, a plant's traits | One offer |
| `POST /api/wild/release`, `wild/answer` | Prompted, Release held three seconds | A seed, parents, meeting, tokens, what is shown | One planting |

`pending` is the only request a phone makes on its own, and its timing is the person's: it goes when they open Peace Garden.

### 2.3 What the server and the host keep

- **The plot service** (`Server/.api/router.php`) writes a log line only for a refusal (status 400 or above), and the line is the status and the route, never the body (lines 109–116). Bodies are capped at 8 KB (line 145).
- **Rate limits** (`Limits.php`) keep a salted digest of the address or the token bag and a count, for at most an hour (`Server/README.md:537–578`). `pending` is allowed 220 a window per gardener and 1,100 per address.
- **The Wild Fields** already show how to keep a row with no order of arrival: no time column, the seed as the key, `WITHOUT ROWID` on SQLite (`WildStore.php:20–26`).
- **The nightly copy** (`backup.php:77`) keeps a named list of tables for 30 days. A table not on the list is in no copy.
- **20i**, the host, keeps the full internet address and browser details of every request in its access and error logs for 12 weeks, and in its CDN logs for 7 days, and cannot shorten either (ticket #497653007; recorded in the Hub's `privacy-arc-dashlit-notes.md:68`). Peace Garden's own privacy page already says the host keeps its usual request logs (`privacy5`). Whether those logs record request and response sizes is not known, so this design assumes they do.

### 2.4 App Group

Peace Garden has none. Its entitlements file holds the associated domains only. It is on team R94VDZ56RY as `app.peacegarden` (`project.yml:55, 76`), the same team as the suite-wide App Group decided in 116A.

---

## 3. The App Group hand-off

### 3.1 The group

Both apps add the suite-wide App Group decided in 116A. The Hub fixed its name on 16 October (H1): `group.com.interfulgent.suite` on team R94VDZ56RY, separate from each app's own group. Its folder rules are in the Hub's `docs/suite-crossovers.md`, "The suite App Group"; they are a convention, since an App Group can't enforce per-folder access, so each app's tests check that it writes only its own files. Autonaut declares nothing of its own (Autonaut session, 16 October).

### 3.2 What sits in it

Small files in the Hub's folders: presence markers in `Presence/v1/`, and Zone C's seeds in `Seeds/v1/`. Files rather than a shared `UserDefaults` suite, because each file has one writer and is written whole and atomically, so two apps never edit the same thing at once. Both apps use `NSFileCoordinator`.

```
Presence/v1/autonaut        written by Autonaut when missing (Hub convention)
Presence/v1/peacegarden     written by Peace Garden when missing
Seeds/v1/
  exchange                  written by Peace Garden while its launch request is switched on
  out/<random>              a seed the person has sent; Autonaut writes, Peace Garden takes
  in/<random>               a seed found for the person; Peace Garden writes, Autonaut takes
```

| File | Content, and nothing else |
|---|---|
| `Presence/v1/autonaut`, `Presence/v1/peacegarden` | empty (Hub convention) |
| `Seeds/v1/exchange` | empty; it exists while Peace Garden's launch request is switched on, so Autonaut can hide "Send as a seed" when nothing would carry it |
| `Seeds/v1/out/<random>` | `{"v":1,"r":"<32 hex>"}` — 16 bytes from `SecRandomCopyBytes`, drawn when the person chooses "Send as a seed", written atomically (A1, agreed) |
| `Seeds/v1/in/<random>` | `{"v":1,"seed":"<64 hex>"}` — the 32-byte space seed Peace Garden found |

- **File names are random**, never a count or a time.
- **Every file's dates are set to a fixed value straight after writing** (1 January 2001), the presence markers included (Autonaut's condition on A6; suite-wide by the Hub's rule). A presence marker is written only when it is missing, never on every launch (Hub). A file system records when a file was made, and a date in this folder would say when someone was in Autonaut's Create, which can be when they were in crisis.
- **The folder is left out of device backups** (`isExcludedFromBackup`).
- **Each reader takes what it reads.** Peace Garden deletes an `out` file once the server has answered the request that carried it; Autonaut moves an `in` file into its own storage and deletes it from the group. The folder holds only seeds in flight, never a history.

### 3.3 Who writes what (the Autonaut session's answers)

- Autonaut writes a seed **only** when the person chooses "Send as a seed" on a finished creation in Create. Nothing on first launch, nothing at milestones.
- The seed is contentless: 16 random bytes. The creation, its materials and when it was made stay in Autonaut.
- Traffic runs both ways: Peace Garden writes back the seeds found for the person, and Autonaut shows them in its space garden.
- Autonaut has no network code, and keeps none.

### 3.4 Presence

- **Zone C opens in Peace Garden when `Presence/v1/autonaut` exists.**
- **Autonaut shows "Send as a seed" and its space garden when `Presence/v1/peacegarden` and `Seeds/v1/exchange` both exist.** Presence comes from the group, never a URL-scheme check (Autonaut session).
- **The limit, and how the design lives with it.** The container lasts as long as any suite app that uses the group is installed: UnCubed or Pfish keeps it alive after Autonaut and Peace Garden are both gone. So a presence file says "was installed", never "is installed". Two caps stand in for the missing check:
  - **Peace Garden writes into `Seeds/v1/in/` only while fewer than three files wait there.** Autonaut takes them each time it opens. If Autonaut has been deleted, nobody takes them, and finding stops after three.
  - **At most three seeds wait in `Seeds/v1/out/`.** If Peace Garden has been deleted, nothing takes them. What Autonaut shows once three are waiting is Autonaut's choice (question A2).

### 3.5 How Peace Garden knows a seed is genuine, without a server

Two separate questions.

**Did it come from Autonaut?** On iPhone and iPad, iOS opens an App Group container only to apps signed by the team that owns it (R94VDZ56RY) with that group in their entitlements. So everything in the folder was written by one of Marcus's own apps; nothing from another developer can reach it. Inside the suite, `Seeds/v1/out/` has one writer by agreement, and Peace Garden holds every file to the exact format: version 1, exactly the keys shown, exactly 32 lowercase hex characters. Anything else is deleted unread. A bug in another suite app can at worst add a contentless seed.

**Is a seed from the server a space seed?** Peace Garden turns the 16 bytes `r` into a 32-byte seed by adding a mark:

```
mark = first 16 bytes of HMAC-SHA256(key: K, "peacegarden.zonec.mark.v1" ‖ r)
space seed = r ‖ mark
```

`K` is a 32-byte constant compiled into Peace Garden. A seed whose second half is its first half's mark is a space seed; the chance that random bytes pass is 1 in 2¹²⁸. **What `K` protects is the server's blindness, not forgery.** Anyone who takes the app apart can read `K`; a copy of the server's pool without the app shows only random bytes. Someone holding `K` could cast counterfeit space seeds. They carry nothing, one launch casts at most one, and the existing rate limits hold the rest, so the worst they can do is add space plants.

**Which space plant it grows** comes from `r` alone, through a new, versioned derivation in SeedCore (`peacegarden.space.v1`, traits drawn by name, pinned test vectors), so Autonaut can draw the same kind from the same 16 bytes without holding `K`.

**On a Mac** the guarantee is weaker: other programs can reach group containers, subject to macOS asking the person. Peace Garden has no Mac app, so nothing crosses there until it does.

### 3.6 Uninstalling

| What is deleted | What happens |
|---|---|
| Autonaut | Zone C stays, with everything grown there. Nothing new is cast. Finding stops once three seeds wait unread. What Autonaut held goes with it. |
| Peace Garden | Zone C goes with Peace Garden's own storage. Autonaut's space garden keeps what it already took in. Seeds waiting in `out` stay unsent. |
| Autonaut, then reinstalled | It writes `Presence/v1/autonaut`, takes up to three waiting seeds, and carries on. |
| Every suite app | iOS deletes the container. |

What lingers in the container when both apps are gone but another suite app remains: two presence files and at most six 16- or 32-byte values. The presence file still says Autonaut was once installed. **So no other suite app may ever read `Seeds/v1/`**, a rule for the Hub's record (question H1).

### 3.7 What the App Group must never hold

- Anything about what the person did in Autonaut: creations, materials, kernels, activities, skins, settings, counts, states.
- Any date or time, including the files' own.
- Any history. Seeds pass through and are taken.
- Any identifier of the person or the device, and any of Peace Garden's meeting tokens.
- The mark key `K`.
- Seeds from any other app. FreqShift in particular never writes to the group (Hub, question 3).

---

## 4. The exchange inside Peace Garden's own traffic

### 4.1 Where it rides

The launch request, `POST /api/walk/pending`, already goes from every Peace Garden phone whose garden holds a meeting, each time the app starts, by the person's own timing, and the privacy page already describes it (`privacy7`: the app asks each time it starts). Zone C adds one field each way, named `aloft` here to keep it clear of The Winds, the sky renderer and Autonaut's "Let it drift".

**Two changes make every Peace Garden phone send the same request, Autonaut or not:**

1. **The request goes even when the garden has no meeting tokens.** Today a phone with no meetings sends nothing (`GardenModel.swift:565`). If that stayed, an Autonaut user with no meetings would be one of the few phones sending an empty bag. The server already accepts an empty bag and counts it by address (`router.php:515–523`).
2. **Every request carries `aloft`, and every answer carries a bundle.** The field is always there, always the same length, and the server treats every value the same.

**What this costs Peace Garden itself.** Today a phone with no meetings to ask about never contacts the server when it starts, so 20i's logs list only people who have met someone. After the first change, every phone with the switch on contacts it at each start, and 20i's logs list each of those addresses as a Peace Garden user for 12 weeks. Using Peace Garden is not health data, and the privacy page already describes a request at every start; it is still a wider footprint than today, and the reason the crowd is big enough to hide in. Each start also downloads about 8 KB of mostly random bytes.

### 4.2 The frame

**Request.** `"aloft": "<64 hex>"`, exactly 32 bytes:
- a space seed waiting in `Seeds/v1/out/` (at most one per launch, and only in the first request if a large garden sends several), or
- 32 fresh random bytes, which carry no mark.

The server cannot tell the two apart. It has no `K`, and both are random-looking 32 bytes.

**Answer.** `"aloft": "<B × 64 hex>"`, exactly `B` seeds drawn at random from the pool, topped up with fresh random bytes while the pool holds fewer than `B`. **`B` = 128 to start**: about 8.2 KB per launch. `B` is the same for every answer at any moment; changing it changes it for everyone at once.

**Rules the server code keeps:**
- `aloft` that is not 64 lowercase hex is refused 400, as a malformed token is. A well-formed value never changes the status, the length or the time of the answer.
- Every well-formed value is stored, `INSERT OR IGNORE`, after the bundle is drawn, so a phone never gets its own slot straight back.
- No code path reads the value beyond storing it.
- Older app builds that send no `aloft` still get the bundle, so every answer is the same length.

### 4.3 Matching the ordinary traffic, axis by axis

| Axis | Today | With Zone C | Why a space seed cannot be singled out |
|---|---|---|---|
| Endpoint | `POST /api/walk/pending` | The same | No new route; Autonaut never connects |
| Who sends it | Phones with the switch on **and** at least one meeting | Every phone with the switch on | The crowd is every Peace Garden user |
| When | Each time the app starts | The same (question 3 offers one more moment, for everyone) | A waiting seed leaves with the next request the phone makes anyway; nothing in the folder ever starts a request |
| How often | Once per start, more for gardens over 128 meetings | The same | At most one cast per start, for every phone |
| Request size | 13 bytes + about 35 per token | + 75 bytes for every phone | The slot is always 32 bytes |
| Answer size | 23 bytes + offers and released plants | + about 8.2 KB for every phone | The bundle is always `B` seeds; what varies is the offers and released plants, which have nothing to do with Autonaut |
| Status | 200, or 400 / 429 | The same | `aloft` cannot cause a refusal except when malformed |
| Headers | System default User-Agent with app name and build | The same | No Autonaut build, header or flag |
| Server log lines | Refusals only: status and route | The same | Nothing about `aloft` is ever logged |
| Database writes | One rate-limit upsert | + one insert into the pool, and once it is full one random removal, for every request | The same writes whatever the slot holds |
| Stored rows | — | One row per request in the pool (§4.4) | Kind-blind and cast-blind |

### 4.4 What the server stores, and whether it can tell

**The pool lives in its own SQLite file beside `public_html`** (`../peacegarden-data/aloft.sqlite`), not in 20i's MySQL database.

```
aloft(seed BLOB PRIMARY KEY) WITHOUT ROWID
PRAGMA secure_delete = ON; journal_mode = DELETE
```

- **One column: the 32 bytes.** No time, no address, no token, no counter, no order of arrival. The key is random, so the rows sit in the order of nothing, as the Wild Fields' do.
- **A cap, `P` rows (2,048 to start, about 64 KB).** Once full, each insert pushes out one row chosen at random. A row's age is written nowhere. A seed stays for about `P` requests and is offered to about `B` phones on average, however busy the garden is: at a thousand launches a day it waits about two days, at a hundred thousand about half an hour. Until the pool first fills, early seeds are offered more often.
- **Bundles are drawn by `B` random probes into the key**, each one index lookup.
- **Not in the nightly copy.** It is not added to `backup.php`'s list; a restore starts the pool empty, and an unfound seed is lost.
- **Why a separate SQLite file.** A database server can keep its own log of every write with a time (MySQL's binary log), and on shared hosting that log is 20i's, not ours. Matched against the 12-week access logs, a timed write would tie each pool row to an address, and anyone holding `K` could then pick out the space seeds. A SQLite file in our own space keeps no log of writes, and `secure_delete` overwrites what is removed.

**Can the server ever tell a space seed from an ordinary one?** No. It holds no `K`, runs no code that knows kinds exist, and stores padding exactly as it stores casts, so it cannot tell whether a request cast anything at all. **Someone who reads `K` out of the app** and holds a copy of the pool can count the space seeds in it, and learns nothing about who sent any of them.

### 4.5 Who could learn that a given address or person uses Autonaut

| Who | What they hold | What the design does | What is left |
|---|---|---|---|
| **20i's access and error logs** (12 weeks) | Address, time, route, status, sizes, User-Agent | Every Peace Garden phone sends the same route at its own launches, with the same fixed slot and the same fixed bundle; `aloft` causes no refusal and no log line | They show who uses Peace Garden, and more phones than today (§4.1) |
| **20i's CDN logs** (7 days) | The same | The same | The same |
| **The pool file**, in a breach, a subpoena or Marcus's own hands | Random 32-byte values | No time, address, token, counter or order; padding is stored too | With `K` from the app: how many space seeds wait. Nobody's name or address |
| **20i's snapshots of the web space** | The pool at each snapshot | Every request adds one row, padding or not | Rows new since the last snapshot match the addresses that opened Peace Garden in that interval. With `K`, a space seed narrows to that crowd, which is every Peace Garden user who opened the app between two snapshots. **Ask 20i how often it snapshots** (question 8) |
| **20i's MySQL logs** | — | The pool is not in MySQL | Nothing |
| **The plot service's own log** | Refusals: status and route | Unchanged | Nothing new |
| **The server itself, if changed to log** (a breach that alters code, or a compelled change) | Every request as it arrives, address included | Nothing in the design can stop a server that has been altered from reading the slot beside the address | **The one real limit.** Only a relay between phone and server, such as Oblivious HTTP or iCloud Private Relay, closes it. Worth one line in the DPIA |
| **A network observer** (Wi-Fi owner, employer, carrier) | Encrypted traffic to peacegarden.app: times and sizes | The same sizes and times as every Peace Garden phone | That this device uses Peace Garden |
| **Another Peace Garden user without Autonaut** | Their own bundles | Their app skips space seeds; no Zone C door; the tap and the link carry none | Nothing |
| **Another Autonaut user who finds the seed** | 32 bytes | No name, no time, no place travels with it | That someone, somewhere, has Autonaut, which is the point |
| **Someone with the phone in hand** | Peace Garden's screens | Zone C has its own door and no glimpse from the ordinary garden (question 10) | They can open the door, as they can open Autonaut |
| **Other suite apps on the phone** | Read access to the group | They never read `Seeds/v1/` (Hub rule) | Only an app that breaks the rule |
| **Apple, through iCloud Backup** | Device backups, readable by Apple unless Advanced Data Protection is on | The group folder and Zone C's file are left out of backups (question 9) | Autonaut's own data, which is Autonaut's choice |
| **A flood of fake seeds** | — | Contentless, one per launch, rate-limited, evicted at random | Fewer finds for a while |

**Behaviour that cannot be hidden:**
- Someone with Autonaut may open Peace Garden more often to look in Zone C. Many people open it often for many reasons; it is a weak signal and the design does not try to mask it.
- Someone who had the switch off and turns it on to use Zone C starts sending the launch request from that day. People turn switches on for many reasons too, and the switch is on by default, so most phones already send it.

---

## 5. How one Autonaut user finds another's space seed

### 5.1 The way it works

1. **Ana finishes something in Create and chooses "Send as a seed".** Autonaut draws 16 random bytes into `Seeds/v1/out/` and shows the seed going out in its own way. It promises nothing about being found.
2. **The next time Ana opens Peace Garden**, for any reason, the launch request it makes anyway carries her seed in the `aloft` slot instead of padding. When the server answers, Peace Garden deletes the file.
3. **Somewhere else, Ben opens Peace Garden.** His bundle of 128 seeds may hold Ana's. His Peace Garden sees Autonaut is present, checks each seed's mark, skips any it cast itself (the last eight, kept in Zone C's own file), and plants at most one space seed (question 5) in Zone C, where it grows as itself, in space flora. It also drops the seed into `Seeds/v1/in/`.
4. **When Ben next opens Autonaut**, it takes the seed into its space garden.
5. **Ana is never told, and neither learns anything of the other.** The seed was offered to about 128 phones; most belonged to people without Autonaut, whose apps passed over it without a trace. It may be found by nobody, by one person or by a few (question 4).

How often finds happen depends on how many people use Autonaut. As a rough guide: if 2 in 100 Peace Garden users have Autonaut, each sends a seed a week and opens Peace Garden twice a day, about one bundle in six holds a space seed, and each space seed reaches two or three people with Autonaut.

### 5.2 The other routes, and why not

| Route | Why it is not used |
|---|---|
| **The tap** (in person) | It would tell the person standing there that this phone has Autonaut. That is a disclosure to someone who may know them, and it is theirs to make in words, not the app's to make for them |
| **A seed link, QR or code** | The same, and a link can be forwarded to anyone |
| **The Wild Fields** | Public, drawn on the website, and every planting there is a released hybrid checked against its parents; a release is a person's deliberate act and would change how often a phone releases |
| **Between one person's own devices** (116A's seed QR or pouch) | A space-seed code on a screen marks its holder as an Autonaut user. Not offered for space seeds; each device finds its own |

### 5.3 What someone without Autonaut sees

**Nothing.** Their Peace Garden receives the same bundles and passes over space seeds; it has no Zone C door, no hint and no count. The tap and the link with an Autonaut user are the ordinary ones. The website never shows Zone C.

---

## 6. What would have to change

### 6.1 Peace Garden app

- Add the suite App Group to the entitlements; read and write `Seeds/v1/` with `NSFileCoordinator`, fixed file dates, backup exclusion, strict format checks.
- Write `Presence/v1/peacegarden` when it is missing (empty, fixed dates). Keep `Seeds/v1/exchange` (empty, fixed dates) while the launch request's switch is on, and delete it when the switch goes off.
- Send `pending` on each launch while the switch is on, **with or without meeting tokens**.
- Put `aloft` in every `pending` request: the oldest waiting `out` seed, marked, or 32 random bytes. Delete the `out` file only after a 2xx answer.
- Read the `aloft` bundle in every answer; check marks with `K`; skip its own last eight casts; plant at most one a day in Zone C while Autonaut is present; write it to `Seeds/v1/in/` while fewer than three wait.
- Zone C: its own door, like the Wild Fields; space flora from a new SeedCore derivation with pinned vectors and a reference implementation; no glimpse from the ordinary garden.
- Zone C plants never leave the phone: no offer, release, tap, link or share (question 10).
- Zone C's storage in its own file, left out of backups (question 9).
- The switch's label and the About sheet's privacy text, in all seven languages.
- Tests: request and answer lengths equal with and without a space seed; no request ever started by a change in the group; nothing in `Seeds/v1/` with a real date; space-flora vectors.

### 6.2 Server

- `pending` takes an optional `aloft` (64 lowercase hex), stores it after drawing the bundle, and always answers with a `B`-seed `aloft` bundle.
- The pool in its own SQLite file, as §4.4: one column, `WITHOUT ROWID`, `secure_delete`, cap with random removal, random-probe draws.
- Left out of `backup.php` and of `Schema.php`'s MySQL migration.
- `sweep.php`: nothing to sweep beyond holding the cap.
- `tools/reference/check_aloft.php` in CI: the answer is the same length whatever the pool and the slot hold; every well-formed slot is stored; the table has one column; the file is in no copy.
- `tools/deploy.sh --check`: `pending` answers with a bundle of the right length.
- Before relying on SQLite at 20i: check its file locking holds on their storage under many launches at once. The population test in `design/mass-test-2026-10-13/` can stand in for the phones.

### 6.3 Site

- `privacy7` rewritten: the app asks each time it starts, whether or not it has meetings, and sends one random-looking seed and receives a handful.
- A new paragraph on the pool: what it keeps (32-byte seeds, with no time, address or order), for how long (until it is full and they are pushed out), and that it is in no backup. It can name Autonaut plainly: the page says what happens, not who uses it.
- Commissioned in all 40 offered languages, as the Wild Fields' paragraphs were.
- A DPIA row (Hub, decision 117).
- No Zone C on the web.

### 6.4 Autonaut

- Join the suite App Group. Still no network code.
- Write `Presence/v1/autonaut` when it is missing (empty, fixed dates).
- On "Send as a seed": draw 16 random bytes, write one `out` file atomically, set its dates to the fixed value. Nothing else.
- On opening: take every `in` file into its own storage and delete it from the group.
- Show "Send as a seed" and the space garden only while `Presence/v1/peacegarden` and `Seeds/v1/exchange` both exist.
- Draw a space plant's kind from `r` with the same pinned derivation as Peace Garden (shared test vectors).
- Never write anything else into the group, and never read Peace Garden's files beyond `Presence/v1/peacegarden`, `Seeds/v1/exchange` and `Seeds/v1/in/`.

### 6.5 The Hub record

- Settled (H1, 16 October): the group is `group.com.interfulgent.suite`; folders `Presence/v1/`, `Seeds/v1/`, `Inbox/v1/<app-id>/`, `Outbox/v1/<app-id>/`.
- **One amendment asked of the Hub:** its record has `Seeds/v1/` written by Autonaut and read only by Peace Garden. Zone C runs both ways, so the rule needs to read: `Seeds/v1/out/` written by Autonaut and read by Peace Garden; `Seeds/v1/in/` and `Seeds/v1/exchange` written by Peace Garden and read by Autonaut; no other app touches `Seeds/v1/`.
- Accepted by the Hub (16 October): the two-way `Seeds/v1/` rule above; fixed file dates (1 January 2001) on every file in the group after each write, suite-wide; and a presence marker is written only when it is missing.
- The DPIA row, and the residual risks in §4.5.

---

## 7. Open questions for Marcus

1. **Where Zone C's traffic hides** — A (recommended): inside the launch request every Peace Garden phone makes, sent at every start even with no meetings, so every Peace Garden user is the crowd. B: build The Winds first and hide space seeds only among its users, a smaller crowd until it is popular. C: move the seed route to a host whose logs can be switched off, and keep the matching as a second layer.
2. **The switch that governs it** — A (recommended): one switch for the launch request, relabelled to cover both, for example "Ask the garden for news when it opens"; off means no request and no Zone C exchange. B: keep "Alert me when a joint seed is shared" as it is; Zone C needs it on. C: a second switch for Zone C, which sends the same request.
3. **When the launch request goes, for everyone** — A (recommended): as today, once each time Peace Garden starts. B: also when it comes back to the screen, at most once an hour, so a sent seed leaves sooner.
4. **How many people can find one space seed** — A (recommended): it is offered to about 128 phones and then drifts on; nobody, one person or a few may find it. B: exactly one finder, which needs a "taken" request the server could tie to the finder's address; not recommended. C: it waits a fixed time, such as a week, offered to everyone who opens Peace Garden meanwhile; that needs a date on each row, which the pool otherwise never holds.
5. **How often one person can find one** — A (recommended): at most one a day. B: at most one a week. C: as many as arrive.
6. **Whether the sender is told** — A (recommended): no; a sent seed goes out into the dark, as the Voyager record did. B: an anonymous "found" signal, which needs a write from the finder's phone that the server would see.
7. **What grows from a found seed** — A (recommended): the found seed as it is, in space flora. B: a cross of it with one of the finder's own sent seeds.
8. **Where the pool lives** — A (recommended): its own SQLite file beside `public_html`, in no backup, after asking 20i how often it snapshots the web space. B: 20i's MySQL, if 20i confirms it keeps no binary or query logs for shared databases. C: a different host.
9. **Backups** — A (recommended): Zone C and the group's seed folder are left out of iCloud and computer backups, so Zone C starts again on a new phone. B: backed up with the rest of the garden.
10. **Zone C plants and sharing** — A (recommended): they stay on the phone: no offer, release, tap, link or share picture, and Zone C has its own door with no glimpse from the ordinary garden. B: as A, but a share picture is allowed as the person's own choice.
11. **The Winds, when built** — A (recommended): it uses the same `aloft` slot and pool, with its own mark, so its users join the same crowd. B: its own route, which keeps the two crowds apart.

---

## 8. Questions for the Autonaut session, and its answers (16 October)

- **A1. The `out` file — agreed.** `{"v":1,"r":"<32 hex>"}`, 16 bytes from `SecRandomCopyBytes`, a random file name, fixed file dates, no other fields, written atomically and only when the person taps "Send as a seed".
- **A2. When three seeds are waiting — with Marcus.** Autonaut recommends hiding "Send as a seed" until one of the three leaves: replacing the oldest would quietly discard a seed the person chose to send, and hiding matches the rule that the exchange is absent without Peace Garden.
- **A3. Space flora — agreed.** One pinned derivation in SeedCore with vectors both repos test against. Autonaut's design work proposes the kinds, names and look (brief §7: space flora with an aesthetic of its own); once agreed they are pinned in SeedCore.
- **A4. Sent seeds — with Marcus.** Autonaut recommends found seeds only, as proposed here: sending has its own moment as the seed leaves, and no record waits for an answer.
- **A5. Backups — with Marcus.** Autonaut recommends keeping its own data out of iCloud Backup (brief item 11). The Zone C transit files stay out regardless.
- **A6. Presence — agreed, with fixed file dates**, and (Hub) written only when missing, so the marker records no activity pattern (brief §7: only presence and a seed's kind ever cross). The Hub's layout makes it the empty file `Presence/v1/autonaut`.
- **A7. The Mac — agreed.** No seeds and no "Send as a seed" until Peace Garden or a seed pouch exists there.
- **H1 (with the Hub) — answered.** See §3.1 and §6.5, including the one amendment asked of the Hub.
