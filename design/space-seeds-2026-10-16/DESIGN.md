# Zone C: space seeds through Peace Garden

16 October 2026. **A design, not a build.** This branch changes no app, server or site code. It is written for Marcus, and for the Autonaut session, which owns Autonaut's side and has answered the coordination questions (folded in below).

**Revised the same day to Marcus's decisions (§7).** A found seed now grows a cross with the finder's own seed, as a knock does; the sender is told, through a return that rides in the finder's later launch requests, and grows the same plant in Zone C; and Zone C is backed up with the rest of the garden. Nothing changes for Autonaut or in the Hub's App Group rules (§6.4, §6.5).

Sources read: the Hub's `~/Projects/interfulgent-hub/docs/suite-crossovers.md` (decisions 116A, 117 and Zone C), Autonaut's `~/Projects/autonaut/docs/BRIEF.md` §7, and this repo's plot service (`Server/.api/`), app (`App/PeaceGarden/`) and docs. For the cross: `Packages/SeedCore/Sources/SeedCore/Genome/Pollination.swift`, `Exchange/ExchangePayload.swift`, `Exchange/PollenLink.swift`, `Persistence/GardenModels.swift`, `App/PeaceGarden/Exchange/PollenExchangeService.swift` and `docs/EXCHANGE-PROTOCOL.md`.

## The recommendation in short

1. **Zone C rides inside the one request every Peace Garden phone already makes when it opens**, `POST /api/walk/pending`. Every phone adds two fixed-size slots to it, one for a seed going up and one for a return coming back, and gets two fixed-size bundles back, whether or not Autonaut is installed. Every Peace Garden user becomes the crowd a space seed and its return hide in.
2. **The server never learns that space seeds or returns exist.** It stores every slot it receives, padding included, in pools that keep no time, address or order, and hands out random bundles. Only Peace Garden on the phone can tell a space seed from padding, by a mark it computes itself, and only the sender's phone can tell its return from padding, with a key that stays on that phone.
3. **A find grows a cross, as a knock does.** The finder's phone crosses the found seed with the finder's own seed in Zone C, through the same derivation two phones use when they knock, and draws the plant as space flora.
4. **The sender is told, and grows the same plant.** The finder's next launch requests carry a return, sealed so that only the sender's phone can open it. It holds the finder's half of the cross, and the sender's Zone C grows the identical plant. No request, row or log line says who found a seed, or that a return is anything but padding.
5. **Autonaut and Peace Garden meet only in a folder in the suite App Group.** Autonaut drops in 16 random bytes when the person chooses "Send as a seed"; Peace Garden drops in the seeds it has found for them. Nothing in the folder carries a date or anything about what the person did.
6. **Peace Garden has no server seed exchange to hide in yet.** The Winds is designed but unbuilt. So the launch request has to go from every phone, with or without meetings, and The Winds should later use the same slot.

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
- **The Wild Fields** already show how to keep a row with no order of arrival: no time column, the seed as the key, `WITHOUT ROWID` on SQLite (`WildStore.php:20–26`). They also publish both parents of every planting to the page that draws it (`WildStore.php:278–294`), which matters for §5.2.
- **The nightly copy** (`backup.php:77`) keeps a named list of tables for 30 days. A table not on the list is in no copy.
- **20i**, the host, keeps the full internet address and browser details of every request in its access and error logs for 12 weeks, and in its CDN logs for 7 days, and cannot shorten either (ticket #497653007; recorded in the Hub's `privacy-arc-dashlit-notes.md:68`). Peace Garden's own privacy page already says the host keeps its usual request logs (`privacy5`). Whether those logs record request and response sizes is not known, so this design assumes they do.

### 2.4 App Group

Peace Garden has none. Its entitlements file holds the associated domains only. It is on team R94VDZ56RY as `app.peacegarden` (`project.yml:55, 76`), the same team as the suite-wide App Group decided in 116A.

### 2.5 Backups

Peace Garden keeps the garden in `Application Support/PeaceGarden/garden.json` (`GardenStore.swift:66–76`) and excludes nothing from backups, so the garden is in every iCloud and computer backup of the phone. Each hybrid's record holds both parents' seeds, so a backup already shows whose seeds a person has crossed with.

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
| `Seeds/v1/in/<random>` | `{"v":1,"seed":"<64 hex>"}` — the 32-byte space seed Peace Garden found, as itself. Zone C grows the cross (§5.2); Autonaut draws the found seed |

- **File names are random**, never a count or a time.
- **Every file's dates are set to a fixed value straight after writing** (1 January 2001), the presence markers included (Autonaut's condition on A6; suite-wide by the Hub's rule). A presence marker is written only when it is missing, never on every launch (Hub). A file system records when a file was made, and a date in this folder would say when someone was in Autonaut's Create, which can be when they were in crisis.
- **The folder is left out of device backups** (`isExcludedFromBackup`; the Hub's suite rule and Autonaut's A5). Zone C's own store is a different thing: it lives in Peace Garden's own container and is backed up with the garden (9B, §4.5).
- **Each reader takes what it reads.** Peace Garden deletes an `out` file once the server has answered the request that carried it, and keeps `r` in its own record of the sent seed (§5.3); Autonaut moves an `in` file into its own storage and deletes it from the group. The folder holds only seeds in flight, never a history.
- **A find and a return add nothing here.** Peace Garden writes the found seed to `in/` exactly as before, and writes nothing to the group when a return arrives.

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
  - **At most three seeds wait in `Seeds/v1/out/`.** If Peace Garden has been deleted, nothing takes them. Autonaut then hides "Send as a seed" until one leaves (A2).

### 3.5 How Peace Garden knows a seed is genuine, without a server

Two separate questions.

**Did it come from Autonaut?** On iPhone and iPad, iOS opens an App Group container only to apps signed by the team that owns it (R94VDZ56RY) with that group in their entitlements. So everything in the folder was written by one of Marcus's own apps; nothing from another developer can reach it. Inside the suite, `Seeds/v1/out/` has one writer by agreement, and Peace Garden holds every file to the exact format: version 1, exactly the keys shown, exactly 32 lowercase hex characters. Anything else is deleted unread. A bug in another suite app can at worst add a contentless seed.

**Is a seed from the server a space seed?** Peace Garden turns the 16 bytes `r` into a 32-byte seed by adding a mark:

```
mark = first 16 bytes of HMAC-SHA256(key: K, "peacegarden.zonec.mark.v1" ‖ r)
space seed = r ‖ mark
```

`K` is a 32-byte constant compiled into Peace Garden. A seed whose second half is its first half's mark is a space seed; the chance that random bytes pass is 1 in 2¹²⁸. **What `K` protects is the server's blindness, not forgery.** Anyone who takes the app apart can read `K`; a copy of the server's pool without the app shows only random bytes. Someone holding `K` could cast counterfeit space seeds. They carry nothing, one launch casts at most one, and the existing rate limits hold the rest, so the worst they can do is add space plants.

**How a space seed is drawn** comes from `r` alone, through a new, versioned derivation in SeedCore (`peacegarden.space.v1`, traits drawn by name, pinned test vectors), so Autonaut can draw a found seed as itself from the same 16 bytes without holding `K` (A3). In Zone C a found seed grows a cross instead (§5.2). The same derivation draws it, reading each parent by its first 16 bytes, which for a space seed is `r`.

**On a Mac** the guarantee is weaker: other programs can reach group containers, subject to macOS asking the person. Peace Garden has no Mac app, so nothing crosses there until it does.

### 3.6 Uninstalling, and a new phone

| What happens | Result |
|---|---|
| Autonaut is deleted | Zone C stays, with everything grown there. Nothing new is cast. Finding stops once three seeds wait unread. Returns for seeds already sent still arrive while their records last (§5.3). What Autonaut held goes with it. |
| Peace Garden is deleted | Zone C goes with Peace Garden's own storage: its plants, its own seed and its records. Returns for its sent seeds are never opened; their finders keep their plants. Autonaut's space garden keeps what it already took in. Seeds waiting in `out` stay unsent. |
| Autonaut is deleted, then reinstalled | It writes `Presence/v1/autonaut`, takes up to three waiting seeds, and carries on. |
| A new phone is restored from a backup | Zone C comes back with the garden: its plants, its own seed and its records (9B), so returns can still arrive. The App Group folder starts empty, since its files are left out of backups. Autonaut's own data stays out of backups (A5), so its space garden starts empty. |
| Every suite app is deleted | iOS deletes the container. |

What lingers in the container when both apps are gone but another suite app remains: two presence files and at most six 16- or 32-byte values. The presence file still says Autonaut was once installed. **So no other suite app may ever read `Seeds/v1/`**, a rule for the Hub's record (question H1).

### 3.7 What the App Group must never hold

- Anything about what the person did in Autonaut: creations, materials, kernels, activities, skins, settings, counts, states.
- Any date or time, including the files' own.
- Any history. Seeds pass through and are taken.
- Any identifier of the person or the device, and any of Peace Garden's meeting tokens.
- The mark key `K`.
- Anything of Zone C's own store: its own seed, the records and keys of seeds sent, returns, plants. These stay in Peace Garden's container.
- Seeds from any other app. FreqShift in particular never writes to the group (Hub, question 3).

---

## 4. The exchange inside Peace Garden's own traffic

### 4.1 Where it rides

The launch request, `POST /api/walk/pending`, already goes from every Peace Garden phone whose garden holds a meeting, each time the app starts, by the person's own timing, and the privacy page already describes it (`privacy7`: the app asks each time it starts). Zone C adds two fields each way: `aloft` carries seeds up, named to keep it clear of The Winds, the sky renderer and Autonaut's "Let it drift"; `back` carries returns.

**Two changes make every Peace Garden phone send the same request, Autonaut or not:**

1. **The request goes even when the garden has no meeting tokens.** Today a phone with no meetings sends nothing (`GardenModel.swift:565`). If that stayed, an Autonaut user with no meetings would be one of the few phones sending an empty bag. The server already accepts an empty bag and counts it by address (`router.php:515–523`).
2. **Every request carries `aloft` and `back`, and every answer carries a bundle of each.** The fields are always there, always the same length, and the server treats every value the same.

The one switch governs it all (2A): relabelled, for example "Ask the garden for news when it opens"; off means no request, so nothing is cast, found or returned.

**What this costs Peace Garden itself.** Today a phone with no meetings to ask about never contacts the server when it starts, so 20i's logs list only people who have met someone. After the first change, every phone with the switch on contacts it at each start, and 20i's logs list each of those addresses as a Peace Garden user for 12 weeks. Using Peace Garden is not health data, and the privacy page already describes a request at every start; it is still a wider footprint than today, and the reason the crowd is big enough to hide in. Each start also sends about 360 bytes more and downloads about 43 KB of mostly random bytes.

### 4.2 The frame

**Request.** Two slots, each always present and always the same length:

- `"aloft": "<128 hex>"`, exactly 64 bytes: a space seed waiting in `Seeds/v1/out/` followed by its seed key (§5.3), or padding: 32 fresh random bytes followed by the public half of a key pair drawn and thrown away. At most one seed per launch, and only in the first request if a large garden sends several.
- `"back": "<208 hex>"`, exactly 104 bytes: a return this phone owes for a find (§5.3), or padding: the public half of a key pair drawn and thrown away, followed by 72 fresh random bytes. At most one return per launch, likewise only in the first request.

Padding carries a real public key because a public key has a shape plain random bytes lack (an X25519 key lies on the curve and has its top bit clear). Padding made from a real key has the same shape as the real thing.

The server cannot tell any of these apart. It has no `K` and no private key, and every slot is the same length.

**Answer.** `"aloft": "<B × 128 hex>"`, exactly `B` rows drawn at random from the seed pool, and `"back": "<R × 208 hex>"`, exactly `R` rows drawn at random from the return pool, each topped up with padding of the same shape while its pool holds fewer. **`B` = `R` = 128 to start**: about 43 KB per launch. `B` and `R` are the same for every answer at any moment; changing one changes it for everyone at once.

**Rules the server code keeps:**
- A slot that is not exactly its length in lowercase hex is refused 400, as a malformed token is. A well-formed value never changes the status, the length or the time of the answer.
- Every well-formed slot is stored, `INSERT OR IGNORE`, after the bundles are drawn, so a phone never gets its own slots straight back.
- No code path reads a value beyond storing it.
- Older app builds that send neither field still get both bundles, so every answer is the same length.

### 4.3 Matching the ordinary traffic, axis by axis

| Axis | Today | With Zone C | Why a space seed or a return cannot be singled out |
|---|---|---|---|
| Endpoint | `POST /api/walk/pending` | The same | No new route; Autonaut never connects |
| Who sends it | Phones with the switch on **and** at least one meeting | Every phone with the switch on | The crowd is every Peace Garden user |
| When | Each time the app starts | The same (3A) | A waiting seed or return leaves with the next request the phone makes anyway; nothing in the folder, and no return, ever starts a request |
| How often | Once per start, more for gardens over 128 meetings | The same | At most one seed and one return per start, for every phone |
| Request size | 13 bytes + about 35 per token | + about 360 bytes for every phone | The slots are always 64 and 104 bytes |
| Answer size | 23 bytes + offers and released plants | + about 43 KB for every phone | The bundles are always `B` and `R` rows; what varies is the offers and released plants, which have nothing to do with Autonaut |
| Status | 200, or 400 / 429 | The same | `aloft` and `back` cannot cause a refusal except when malformed |
| Headers | System default User-Agent with app name and build | The same | No Autonaut build, header or flag |
| Server log lines | Refusals only: status and route | The same | Nothing about either slot is ever logged |
| Database writes | One rate-limit upsert | + one insert into each pool, and once they are full one random removal from each, for every request | The same writes whatever the slots hold |
| Stored rows | — | One row in each pool per request (§4.4) | Kind-blind and cast-blind |

### 4.4 What the server stores, and whether it can tell

**The pools live in their own SQLite file beside `public_html`** (`../peacegarden-data/aloft.sqlite`), not in 20i's MySQL database (8A).

```
aloft(row BLOB PRIMARY KEY) WITHOUT ROWID    -- 64 bytes: a space seed and its key, or padding
back(row BLOB PRIMARY KEY) WITHOUT ROWID     -- 104 bytes: a sealed return, or padding
PRAGMA secure_delete = ON; journal_mode = DELETE
```

- **One column in each: the bytes.** No time, no address, no token, no counter, no order of arrival. The key begins with random bytes, so the rows sit in the order of nothing, as the Wild Fields' do.
- **Two tables because the slots are two sizes.** Every request fills both, so the table a row sits in says only which slot it came from.
- **A cap on each, `P` and `Q` rows (2,048 each to start, about 128 KB and 208 KB).** Once full, each insert pushes out one row chosen at random. A row's age is written nowhere. A seed stays for about `P` requests and is offered to about `B` phones on average, however busy the garden is: at a thousand launches a day it waits about two days, at a hundred thousand about half an hour. A return likewise stays for about `Q` requests and is offered to about `R` phones. Until a pool first fills, early rows are offered more often.
- **Bundles are drawn by random probes into the key**, each one index lookup.
- **Not in the nightly copy.** Neither table is added to `backup.php`'s list; a restore starts both pools empty, and an unfound seed or an unread return is lost.
- **Why a separate SQLite file.** A database server can keep its own log of every write with a time (MySQL's binary log), and on shared hosting that log is 20i's, not ours. Matched against the 12-week access logs, a timed write would tie each pool row to an address, and anyone holding `K` could then pick out the space seeds. A SQLite file in our own space keeps no log of writes, and `secure_delete` overwrites what is removed.

**Can the server ever tell a space seed from an ordinary one, or a return from padding?** No. It holds no `K` and no private key, runs no code that knows kinds exist, and stores padding exactly as it stores casts and returns, so it cannot tell whether a request carried anything at all. **Someone who reads `K` out of the app** and holds a copy of the pool can count the space seeds in it, and learns nothing about who sent any of them. They still cannot tell a return from padding, or which seed a return answers: opening one takes the private key that stays on the sender's phone.

### 4.5 Who could learn that a given address or person uses Autonaut

| Who | What they hold | What the design does | What is left |
|---|---|---|---|
| **20i's access and error logs** (12 weeks) | Address, time, route, status, sizes, User-Agent | Every Peace Garden phone sends the same route at its own launches, with the same two fixed slots and the same two fixed bundles; neither slot causes a refusal or a log line | They show who uses Peace Garden, and more phones than today (§4.1) |
| **20i's CDN logs** (7 days) | The same | The same | The same |
| **The pool file**, in a breach, a subpoena or Marcus's own hands | Random-looking 64- and 104-byte values | No time, address, token, counter or order; padding is stored too; a return, which holds a finder's own seed in Zone C, opens only with a key that stays on its sender's phone | With `K` from the app: how many space seeds wait. Nobody's name or address, and nothing about returns |
| **20i's snapshots of the web space** | The pools at each snapshot | Every request adds one row to each pool, padding or not | Rows new since the last snapshot match the addresses that opened Peace Garden in that interval. With `K`, a space seed narrows to that crowd, which is every Peace Garden user who opened the app between two snapshots. Returns stay unreadable. **Ask 20i how often it snapshots** (8A) |
| **20i's MySQL logs** | — | The pools are not in MySQL | Nothing |
| **The plot service's own log** | Refusals: status and route | Unchanged | Nothing new |
| **The server itself, if changed to log** (a breach that alters code, or a compelled change) | Every request as it arrives, address included | Watching alone, it still cannot tell a return from padding, or which seed a return answers, so finders stay hidden from it. Nothing in the design can stop it reading the seed slot beside the address | **The one real limit, now in two parts.** With `K`, it can tell which addresses send space seeds. And if it is changed to act as well as watch, it can hand out space seeds with its own key in place of the sender's, open the returns that come back, and so learn which addresses found them, and their own seeds in Zone C. Only a relay between phone and server, such as Oblivious HTTP or iCloud Private Relay, closes both. Worth a line in the DPIA |
| **A network observer** (Wi-Fi owner, employer, carrier) | Encrypted traffic to peacegarden.app: times and sizes | The same sizes and times as every Peace Garden phone | That this device uses Peace Garden |
| **Another Peace Garden user without Autonaut** | Their own bundles | Their app skips space seeds and opens no returns; its `back` slot is always padding; no Zone C door; the tap and the link carry none | Nothing |
| **The finder** | The space seed and its key: random bytes | No name, no time, no place travels with it | That someone, somewhere, has Autonaut, which is the point |
| **The sender, when a return arrives** | The finder's own seed in Zone C and a nonce: random bytes | That seed appears nowhere outside Zone C: not in the ordinary garden, a knock, a link or the Wild Fields (§5.2) | That someone found the seed. If one finder finds two of the sender's seeds, the same own seed comes back twice, so the sender can tell one stranger found both |
| **Anyone who sees both holders' share pictures** | Two pictures of one plant | A share picture carries the plant and nothing about it (`PlantPicture.swift:8–12`), and is made only when the person asks (10B) | The sender and the finder hold the same plant. If both post a picture of it, anyone who sees both can tell that the two share a space plant: both use Autonaut, and one found the other's seed. Space flora's look alone says "Autonaut" to anyone who knows it. Each person's own choice |
| **Someone with the phone in hand** | Peace Garden's screens | Zone C has its own door and no glimpse from the ordinary garden (10B); a sent seed appears there only once a return arrives | They can open the door, as they can open Autonaut, and see the finds of the person's own seeds |
| **Other suite apps on the phone** | Read access to the group | They never read `Seeds/v1/` (Hub rule) | Only an app that breaks the rule |
| **Apple, through iCloud Backup** | Device backups, readable by Apple unless Advanced Data Protection is on | Zone C's store and plants are backed up with the rest of the garden (9B). The App Group folder is left out (Hub rule; A5), and so is Autonaut's own data (A5) | **Accepted by Marcus (9B):** without Advanced Data Protection, Apple can read that the person has space flora, and therefore uses Autonaut. It can also read Zone C's own seed, the live records and their keys, and each Zone C plant's parents; with two people's backups it can tell that they share a Zone C plant, since the finder's own seed in Zone C is a parent of the sender's copy. Apple can already read who met whom from the garden's own records (§2.5). With Advanced Data Protection on, none of it is readable to Apple |
| **A flood of fake seeds or returns** | — | Contentless, one of each per launch, rate-limited, evicted at random; at most three plants grow from one sent seed (§5.3) | Fewer finds for a while. Someone holding `K` can seal a return to a space seed's key, so that its sender grows a plant with a stranger's chosen parent |

**Behaviour that cannot be hidden:**
- Someone with Autonaut may open Peace Garden more often to look in Zone C, or to see whether a seed they sent was found. Many people open it often for many reasons; it is a weak signal and the design does not try to mask it.
- Someone who had the switch off and turns it on to use Zone C starts sending the launch request from that day. People turn switches on for many reasons too, and the switch is on by default, so most phones already send it.

---

## 5. How one Autonaut user finds another's space seed

### 5.1 The way it works

1. **Ana finishes something in Create and chooses "Send as a seed".** Autonaut draws 16 random bytes into `Seeds/v1/out/` and shows the seed going out in its own way. It promises nothing about being found.
2. **The next time Ana opens Peace Garden**, for any reason, the launch request it makes anyway carries her seed and a fresh seed key in the `aloft` slot instead of padding. When the server answers, Peace Garden deletes the file and keeps a small record: `r` and the key's private half.
3. **Somewhere else, Ben opens Peace Garden.** His bundle of 128 seeds may hold Ana's. His Peace Garden sees Autonaut is present, checks each seed's mark, skips any it holds a record for (its own), and takes at most one a day (5A). It crosses Ana's seed with Ben's own seed in Zone C, as two phones cross at a knock, and plants the cross in Zone C, drawn as space flora (§5.2). It drops Ana's seed, as itself, into `Seeds/v1/in/`.
4. **When Ben next opens Autonaut**, it takes the seed into its space garden and draws it as itself, as agreed (A3, A4).
5. **Ben's next eight launch requests each carry a return** in the `back` slot: his half of the cross, sealed to Ana's seed key, sealed afresh each time so no two copies look alike (§5.3).
6. **Each time Ana opens Peace Garden**, her phone tries its records' keys on the 128 returns in the answer. If one of Ben's copies is there, it opens, and Ana's Zone C grows the same plant Ben has, marked as grown because her seed was found. A return that never reaches her leaves no trace.
7. **Neither learns anything of the other beyond the plant they now share**: no name, time or place travels. The seed was offered to about 128 phones; most belonged to people without Autonaut, whose apps passed over it without a trace. It may be found by nobody, by one person or by a few (4A), and each finder's return grows its own plant on Ana's phone.

How often finds happen depends on how many people use Autonaut. As a rough guide: if 2 in 100 Peace Garden users have Autonaut, each sends a seed a week and opens Peace Garden twice a day, about one bundle in six holds a space seed, and each space seed reaches two or three people with Autonaut. How often Ana hears of a find is in §5.3.

### 5.2 The cross

**At a knock, as built.** Each phone contributes its owner's own seed, `Identity.seed`, "minted once on first launch and kept for good" (`GardenModels.swift:8–10`), handed over in the `hello` card (`PollenExchangeService.swift:129–142`), and 16 fresh random bytes, its nonce. Both phones then compute, with `Pollination` (`Pollination.swift:19–71`; `docs/EXCHANGE-PROTOCOL.md`, "The derivation"):

```
encounterID = H("peacegarden.encounter.v1", min(seedA,seedB), max(seedA,seedB),
                                            min(nonceA,nonceB), max(nonceA,nonceB))
childSeed   = H("peacegarden.cross.v1",     min(seedA,seedB), max(seedA,seedB), encounterID)
checksum    = H("peacegarden.checksum.v1",  childSeed)[0..8]
```

They swap checksums and keep the plant only if they agree. The plant's traits are drawn by `Genome.hybrid` from the child seed and the two parents, each trait by name (36% the first parent, 36% the second, 22% a blend, 6% something new), and its lineage is `.crossed(parentA, parentB, encounterID)` with the parents sorted (`CrossPollinationResult`, `ExchangePayload.swift:234–254`). Sorting is what lets both phones reach the same plant without knowing who went first. A seed link does the same across time: the reply carries the receiver's seed, nonce and checksum, and the sender grows the plant only if the checksum agrees (`PollenLink.swift:40–51, 207–222`).

**In Zone C, the same three functions, the same sorting and the same checksum**, with these inputs:

| | At a knock | In Zone C |
|---|---|---|
| One parent | Phone A's own seed | The found space seed, `r ‖ mark` |
| Its nonce | 16 fresh bytes from phone A | `r`, the 16 bytes Autonaut drew fresh for this seed |
| The other parent | Phone B's own seed | **The finder's own seed in Zone C** |
| Its nonce | 16 fresh bytes from phone B | 16 fresh bytes the finder's phone draws at the find |
| The checksum | Swapped in `confirm` | Carried to the sender inside the return |
| Drawn by | `Genome.hybrid` | Space flora's hybrid draw: the same inheritance rule over space-flora traits (`peacegarden.space.v1`) |

In code, the finder's phone computes `CrossPollinationResult(localSeed: own, remoteSeed: found, localNonce: n, remoteNonce: r)` and the sender's computes `CrossPollinationResult(localSeed: found, remoteSeed: own, localNonce: r, remoteNonce: n)`. Sorting makes them the same `childSeed`, `encounterID` and `checksum`. Only the drawing differs: Zone C keeps its plants in its own store and record type and draws them as space flora, so no path in the ordinary garden (offer, release, link) can reach one.

**Which of the finder's seeds: their own seed in Zone C** (Zone C's own seed, for short). 32 bytes from the system's random source, minted once when Zone C first opens, kept in Zone C's store for good and backed up with it (9B), so it moves to a new phone as the person's own seed does. It plays the part the person's own seed plays at a knock: one per person, the same at every cross, a parent of every plant their finds make, while the two nonces make each cross different. It leaves the phone only sealed inside a return, which one sender alone can open. Whether Zone C also shows it as the person's own space plant, as the garden shows their own plant, is for the drawing stage.

**Why not the person's own seed itself.** A person's own seed is a parent of every plant their meetings make (`WildFields.swift:135–138`): everyone they have met holds it in their garden, and the Wild Fields publish both parents of every planting (`WildStore.php:278–294`). A return carrying it would let a sender who has ever met the finder, or who looks through the Wild Fields, recognise who found the seed, and learn that they use Autonaut. The finder's own seed in Zone C does the same work, and nobody outside Zone C knows it. Question 14 puts this to Marcus.

**Why the sender's half is the space seed itself.** It is the thing that travelled, and it is fresh for every seed sent, so nothing in the pool links two of Ana's seeds. Her own seed in the ordinary garden plays no part, and her own seed in Zone C travels only when she is the finder, sealed in a return.

### 5.3 The return

**The seed key.** When Peace Garden takes a seed from `out/` to carry it, it draws a key pair for that seed alone (X25519, CryptoKit) and sends the public half in the `aloft` slot beside the space seed. The private half is the per-seed secret that lets this phone, and only this phone, recognise and open the seed's returns. It is drawn, not derived from `r`, because `r` travels in the clear inside the space seed: anything computed from `r` alone is known to everyone who holds the pool. And it is drawn fresh for each seed rather than derived from one lasting secret, so once a record ends, nothing on the phone or in a backup can pick out which pool rows were this phone's.

**The record.** For each seed it carries aloft, Peace Garden keeps in Zone C's store:
- `r` (16 bytes), from which it rebuilds the space seed with `K`;
- the seed key's private half (32 bytes);
- how many of its own launch requests the record has left, 60 to start;
- how many plants have grown from it, at most three.

It holds no date and nothing else from Autonaut. Zone C shows no list of seeds waiting: a sent seed appears there only when a return arrives (13A), so no record waits for an answer where the person can see it, as A4 asks of Autonaut. **At most eight records are kept**; a ninth pushes out the oldest. **A record ends after 60 of the phone's own launch requests**, about a month at two starts a day, **or once three plants have grown from it.** Peace Garden counts its launches, not days, so a record says nothing about when the seed was sent. The records also do the job of the earlier "last eight casts" list: a phone never finds a seed it holds a record for.

Why 60: a seed stays in the pool for about 2,048 starts across the garden; its finders send their returns in their next eight starts; each return then stays about 2,048 starts more. At a thousand starts a day that is about a week, well inside a month.

**Sealing a return.** At a find, the finder's phone seals 56 bytes, `own seed (32) ‖ nonce n (16) ‖ checksum (8)`, to the sender's seed key with HPKE (RFC 9180, base mode: X25519, HKDF-SHA256, ChaCha20-Poly1305; CryptoKit's `HPKE`, available from iOS 17, which is Peace Garden's floor). The context string is `"peacegarden.zonec.back.v1" ‖ space seed`, so a return opens only for the seed it answers. The result is 104 bytes: a fresh public key of 32 bytes and 72 bytes of ciphertext, the same shape as padding. It goes in the `back` slot of the finder's next eight launch requests, sealed afresh for each, so no two copies look alike. If a second find's return is waiting, the two take turns. **While three finds' returns are still going out, Peace Garden plants no new find**, and the seed drifts on for someone else; with one find a day at most (5A), this binds only someone who opens Peace Garden rarely.

**Opening a return.** At each answer, the sender's phone tries each live record's key on each of the `R` returns: at most 8 × 128 = 1,024 key agreements, a few tens of milliseconds, off the main thread. A return opens only with the right key and the right space seed. Then Peace Garden:
1. rebuilds the cross from the space seed, `r`, the finder's own seed and the finder's nonce (§5.2);
2. compares the checksum with the one in the return, and grows nothing if they differ, as a link's reply does, since a difference means the two phones are on different versions;
3. passes over a copy whose plant Zone C already holds;
4. otherwise grows the plant in Zone C, with the same seed, lineage and drawing as the finder's, marked as grown because the person's seed was found.

It writes nothing to the App Group, and Autonaut's side is unchanged (A4). Each phone's plant is born when it grows there, since no time travels, so the two are the same plant a few days apart in age.

**Several finders (4A).** Each finder crosses the seed with their own seed and their own nonce, so each grows a different plant and sends their own return. The sender grows each that arrives, up to three from one seed, and each is the twin of one finder's plant. Further copies of a return already grown are passed over; once three plants have grown, the record ends.

**How often a return arrives.** Returns are offered the way seeds are: each copy to about `R` = 128 phones chosen at random. Only one phone can open it, so it arrives only if the sender opens Peace Garden while a copy is in the pool and draws it. The expected number of times the sender is offered one find's return is about 8 copies × 128 × (the sender's starts a day ÷ all starts a day). If the sender opens Peace Garden twice a day:

| Starts a day, across the garden | Returns that reach their sender |
|---|---|
| 1,000 | about 9 in 10 |
| 10,000 | about 1 in 5 |
| 100,000 | about 1 in 50 |

The sender hears of a find only when a return arrives; as Peace Garden grows, more finds go untold. The copies and `R` can rise later, for everyone at once. Sure delivery at any size, inside a bounded download, needs a different shape (question 15).

### 5.4 The other routes, and why not

| Route | Why it is not used |
|---|---|
| **The tap** (in person) | It would tell the person standing there that this phone has Autonaut. That is a disclosure to someone who may know them, and it is theirs to make in words, not the app's to make for them |
| **A seed link, QR or code** | The same, and a link can be forwarded to anyone |
| **The Wild Fields** | Public, drawn on the website, and every planting there is a released hybrid checked against its parents; a release is a person's deliberate act and would change how often a phone releases |
| **Between one person's own devices** (116A's seed QR or pouch) | A space-seed code on a screen marks its holder as an Autonaut user. Not offered for space seeds; each device finds its own |
| **A mailbox for returns** | A phone that asks the server for the replies to its own seed tells it which seeds it sent, and a finder that posts to a named mailbox tells it who found what. The pooled `back` slot says neither |

### 5.5 What someone without Autonaut sees

**Nothing.** Their Peace Garden receives the same bundles and passes over space seeds and returns; its `back` slot always carries padding; it has no Zone C door, no hint and no count. The tap and the link with an Autonaut user are the ordinary ones. The website never shows Zone C.

---

## 6. What would have to change

### 6.1 Peace Garden app

- Add the suite App Group to the entitlements; read and write `Seeds/v1/` with `NSFileCoordinator`, fixed file dates, backup exclusion, strict format checks.
- Write `Presence/v1/peacegarden` when it is missing (empty, fixed dates). Keep `Seeds/v1/exchange` (empty, fixed dates) while the launch request's switch is on, and delete it when the switch goes off.
- Send `pending` on each launch while the switch is on, **with or without meeting tokens**. Relabel the switch to cover both (2A), for example "Ask the garden for news when it opens".
- Put `aloft` in every `pending` request: the oldest waiting `out` seed, marked, with a fresh seed key, or padding of the same shape. After a 2xx answer, write the seed's record, then delete the `out` file.
- Put `back` in every `pending` request: the next copy of a return this phone owes, sealed afresh, or padding of the same shape.
- Read both bundles in every answer:
  - Seeds: check marks with `K`; skip seeds it holds a record for; find at most one a day, only while Autonaut is present, fewer than three seeds wait in `Seeds/v1/in/` and fewer than three returns are going out; cross it with Zone C's own seed (§5.2) and plant it; write the found seed to `Seeds/v1/in/`; queue its return for the next eight launches.
  - Returns: try each live record's key; when one opens and its checksum agrees, grow the same cross in Zone C.
- Zone C's own seed: minted once when Zone C first opens, kept for good.
- Sent-seed records: at most eight; each ends after 60 of the phone's launch requests or three plants; no dates.
- Zone C: its own door, like the Wild Fields; no glimpse from the ordinary garden; space flora from a new SeedCore derivation with pinned vectors and a reference implementation, including the hybrid draw for crosses; a sender's plant marked as grown because their seed was found.
- Zone C plants stay on the phone: no offer, release, tap or link; a share picture, as for any plant, when the person asks (10B). They live in Zone C's own store and record type, so no ordinary path can reach one.
- Zone C's storage in its own file beside `garden.json`, backed up with it (9B). The App Group folder stays out of backups.
- The switch's label and the About sheet's privacy text, in all seven languages, including that Zone C is in the phone's backup with the rest of the garden.
- Tests: request and answer lengths equal with and without a seed or a return; padding and real slots of the same shape, each carrying a real public key; no request ever started by a change in the group or by a return waiting; nothing in `Seeds/v1/` with a real date; the Zone C cross reaching the same child seed and checksum on both sides, and matching `CrossPollinationResult`; a return opening only with its own key and seed; the record limits; space-flora vectors, shared with Autonaut for the single-seed draw, and in `tools/reference/derivation_reference.py`.

### 6.2 Server

- `pending` takes an optional `aloft` (128 lowercase hex) and an optional `back` (208 lowercase hex), stores each after drawing the bundles, and always answers with `B` seed rows and `R` return rows.
- The two pools in their own SQLite file, as §4.4: one column each, `WITHOUT ROWID`, `secure_delete`, caps with random removal, random-probe draws.
- Padding for the top-ups made with PHP's `sodium` (a key pair drawn and thrown away for each row), used only until each pool first fills.
- Left out of `backup.php` and of `Schema.php`'s MySQL migration.
- `sweep.php`: nothing to sweep beyond holding the caps.
- `tools/reference/check_aloft.php` in CI: the answer is the same length whatever the pools and the slots hold; every well-formed slot is stored; each table has one column; the file is in no copy.
- `tools/deploy.sh --check`: `pending` answers with two bundles of the right lengths.
- Before relying on SQLite at 20i: check its file locking holds on their storage under many launches at once. The population test in `design/mass-test-2026-10-13/` can stand in for the phones.

### 6.3 Site

- `privacy7` rewritten: the app asks each time it starts, whether or not it has meetings, and sends one random-looking seed and one random-looking reply, and receives a handful of each.
- A new paragraph on the pools: what they keep (random-looking values of 64 and 104 bytes, with no time, address or order), for how long (until they are full and the values are pushed out), that they are in no backup, and that a reply opens only on the phone that sent its seed. It can name Autonaut plainly: the page says what happens, not who uses it.
- Commissioned in all 40 offered languages, as the Wild Fields' paragraphs were.
- A DPIA row (Hub, decision 117), with the residual risks in §4.5.
- No Zone C on the web.

### 6.4 Autonaut

**Nothing changes.** The list agreed with the Autonaut session stands:

- Join the suite App Group. Still no network code.
- Write `Presence/v1/autonaut` when it is missing (empty, fixed dates).
- On "Send as a seed": draw 16 random bytes, write one `out` file atomically, set its dates to the fixed value. Nothing else.
- On opening: take every `in` file into its own storage and delete it from the group.
- Show "Send as a seed" and the space garden only while `Presence/v1/peacegarden` and `Seeds/v1/exchange` both exist.
- Draw a found seed's kind from `r` with the same pinned derivation as Peace Garden (shared test vectors). SeedCore gains a hybrid draw for Zone C's crosses that Autonaut does not use.
- Never write anything else into the group, and never read Peace Garden's files beyond `Presence/v1/peacegarden`, `Seeds/v1/exchange` and `Seeds/v1/in/`.

Two consequences to know, neither of them a change: Autonaut's space garden draws a found seed as itself, while Peace Garden's Zone C grows the cross; and a sender's Autonaut never learns that a seed was found, since the sender sees that in Peace Garden (13A). If Marcus later wants Autonaut to show the cross, that is a change to Autonaut's side and goes to the Autonaut session.

### 6.5 The Hub record

**Nothing changes in the App Group rules.**

- Settled (H1, 16 October): the group is `group.com.interfulgent.suite`; folders `Presence/v1/`, `Seeds/v1/`, `Inbox/v1/<app-id>/`, `Outbox/v1/<app-id>/`.
- Accepted by the Hub (16 October): `Seeds/v1/out/` written by Autonaut and read by Peace Garden; `Seeds/v1/in/` and `Seeds/v1/exchange` written by Peace Garden and read by Autonaut; no other app touches `Seeds/v1/`. Fixed file dates (1 January 2001) on every file in the group after each write, suite-wide; a presence marker is written only when it is missing.
- The transit files stay out of backups, as the Hub's suite rule says. Zone C's backed-up store (9B) is in Peace Garden's own container, outside the group, so the rule holds as written.
- The DPIA row gains the new residual risks in §4.5: Apple's view of Zone C in backups without Advanced Data Protection (9B), two share pictures of one plant (10B), and a server altered to swap seed keys.

---

## 7. Marcus's decisions (16 October), and the questions still open

1. **Where Zone C's traffic hides — decided A.** Inside the launch request every Peace Garden phone makes, sent at every start even with no meetings, so every Peace Garden user is the crowd.
2. **The switch that governs it — decided A.** One switch for the launch request, relabelled to cover both, for example "Ask the garden for news when it opens"; off means no request and no Zone C exchange.
3. **When the launch request goes, for everyone — decided A.** As today, once each time Peace Garden starts.
4. **How many people can find one space seed — decided A.** It is offered to about 128 phones and then drifts on; nobody, one person or a few may find it.
5. **How often one person can find one — decided A.** At most one a day.
6. **Whether the sender is told — decided B.** The sender is told when their space seed is found, by a return that rides in the finder's later launch requests (§5.3).
7. **What grows from a found seed — decided: a cross with the finder's own seed.** A found seed grows a plant crossed from the found seed and the finder's own seed, "just like when phones in real time and real life are crossed": the same derivation as a knock, drawn as space flora (§5.2). Which seed stands as the finder's own is question 14.
8. **Where the pool lives — decided A.** Its own SQLite file beside `public_html`, in no backup. Still to do: ask 20i how often it snapshots the web space.
9. **Backups — decided B, kept after Marcus was told the consequence.** Zone C's plants and store are backed up with the rest of the garden. **Accepted consequence:** in an iCloud backup without Advanced Data Protection, Apple can read that the person has space flora, and therefore uses Autonaut (§4.5). The App Group's transit files stay out of backups: that is the Hub's suite rule and Autonaut's A5.
10. **Zone C plants and sharing — decided B.** They stay on the phone, with no offer, release, tap or link, and Zone C has its own door with no glimpse from the ordinary garden; the person may make a share picture by their own choice.
11. **The Winds, when built — decided A.** It uses the same `aloft` slot and pool, with its own mark, so its users join the same crowd.
12. **Whether the sender gets the same plant — decided A** (new). Yes. In a real-life cross both phones get the same plant ("you both have it"), so the "found" signal carries the finder's half back, and the sender grows the identical cross (§5.3).
13. **Where the sender sees the find — decided A** (new). In Peace Garden's Zone C, with the new plant. Peace Garden holds the record of a sent seed needed to recognise its return (§5.3). Autonaut stays as decided under A4: its space garden shows found seeds only, and it keeps no record that waits for an answer.

### Open

14. **Which of the finder's seeds is crossed** — A (recommended): the finder's own seed in Zone C, minted once when Zone C first opens and kept for good; it does at every find what the person's own seed does at every knock, and nobody outside Zone C knows it. B: the person's own seed itself, exactly as at a knock; everyone they have met holds it and the Wild Fields publish it, so a sender who knows them could recognise them in a return and learn that they use Autonaut.
15. **How sure the sender is to hear of a find** — A (recommended): as designed, a fixed 43 KB at each start; the sender hears of about 9 in 10 finds at a thousand starts a day across the garden, 1 in 5 at ten thousand and 1 in 50 at a hundred thousand; revisit when starts pass about five thousand a day. B: each answer grows with the garden so that nearly every return arrives: about 400 KB at each start at ten thousand starts a day, and 4 MB at a hundred thousand. C: each phone reads one "home" share of the returns in full, which makes delivery sure in a bounded download; every phone then sends its home number with each seed, and every phone answers each space seed it is offered, finder or not, so finders stay hidden. It needs its own design pass.

---

## 8. Questions for the Autonaut session, and its answers (16 October)

- **A1. The `out` file — agreed.** `{"v":1,"r":"<32 hex>"}`, 16 bytes from `SecRandomCopyBytes`, a random file name, fixed file dates, no other fields, written atomically and only when the person taps "Send as a seed".
- **A2. When three seeds are waiting — decided (Marcus, as recommended).** Autonaut hides "Send as a seed" until one of the three leaves; nothing is replaced or discarded.
- **A3. Space flora — agreed.** One pinned derivation in SeedCore with vectors both repos test against. Autonaut's design work proposes the kinds, names and look (brief §7: space flora with an aesthetic of its own); once agreed they are pinned in SeedCore. Zone C's hybrid draw builds on the same traits and is Peace Garden's alone.
- **A4. Sent seeds — decided (Marcus, as recommended).** Autonaut's space garden shows found seeds only. Sending has its own moment as the seed leaves, and no record waits for an answer. Marcus's 13A keeps this: the sender sees a find in Peace Garden's Zone C, and Autonaut is unchanged.
- **A5. Backups — decided (Marcus, as recommended).** Autonaut's own data stays out of iCloud Backup, on the phone only. The Zone C transit files stay out too. Peace Garden's own Zone C store is backed up (9B); it is outside the group.
- **A6. Presence — agreed, with fixed file dates**, and (Hub) written only when missing, so the marker records no activity pattern (brief §7: only presence and a seed's kind ever cross). The Hub's layout makes it the empty file `Presence/v1/autonaut`.
- **A7. The Mac — agreed.** No seeds and no "Send as a seed" until Peace Garden or a seed pouch exists there.
- **H1 (with the Hub) — answered.** See §3.1 and §6.5.
