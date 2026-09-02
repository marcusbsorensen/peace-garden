# The website

*peacegarden.app.* Scoped 2 September 2026, not started.

**The site is the page a seed lands on.** Every seed link minted so far points at
`https://peacegarden.app/s`, that path answers 403, and somebody who taps one
gets nothing — so the first job is the only urgent one: draw the plant their seed
made, in their browser, seconds after tapping a message, with nothing installed.
Everything else the site could be arrives after that and out of it. **A page
explaining what Peace Garden is** is what `/s` shows when there is no seed in the
link, so it is the same build rather than a second one. **A place a shared plant
lives, so two people can point at it** is phase 2: it needs an identity the app
has deliberately never had, a way to come down again, and a moderation surface,
and it is most of what follows. **A garden you can walk**, with areas and paths
and other people's plots — [BOTANICAL-GARDEN.md](BOTANICAL-GARDEN.md) — is last,
and it is the only one of the four that is not yet agreed to be built at all.

## What is already true

| | |
| --- | --- |
| The domain | `peacegarden.app`, with a certificate that validates. A bare GET answers 403 — the host's default for a directory with nothing in it. |
| The association file | Deployed, served as `application/json` with no redirect, and **already in Apple's CDN**. It claims `/s*` for the app and names `app.peacegarden.Clip` for a clip that does not exist yet. |
| The link format | `PollenLink`, version 1, payload in the fragment, six-byte checksum, base64url fields so a full stop in a name is never a separator. `PollenLink.path` is `/s` and the host is passed in rather than baked in. |
| The renderers | `SeedCore` is authoritative. `tools/reference/` is a second implementation of the derivation, gated by CI. `tools/preview/` is a Python port of the geometry that has drifted twice and is for judging shape. |
| The languages | The app speaks **eight** — English, Dutch, Danish, French, Spanish, Norwegian Bokmål, Swedish, Italian — with seven passage banks and Spanish borrowing English until its own lands. **Twenty-five more are written down** in [LANGUAGES.md](LANGUAGES.md) under *Round two*. A language arrives as an interface first and a bank later, every time, and `QuoteBank.isBorrowed` is the mechanism that says so. |

Two consequences of that AASA entry that shape everything on the web side.

**An iPhone with the app installed never sees the `/s` page.** iOS opens the app
instead. So the page addresses a stranger, always, and never has to branch on
whether the reader already has the app. That is a gift: one voice, one audience,
no "if you already have Peace Garden" paragraph.

**The next edit to the AASA costs a day.** Apple's CDN holds what it has for up
to twenty-four hours, and `docs/HANDOVER.md` records the useful half of that —
the wait bites on the *second* version, not the first. So the association file
gets changed once, when the App Clip target exists, and not before. Adding new
site paths to it in the meantime buys nothing and spends the day.

## What the server can honestly know

The fragment never leaves the browser: it is not in the request line, not in
`Referer`, not in a log. That is the whole reason the payload lives there.

**The request still happens.** The origin sees an IP address, a time, and a user
agent, because that is what serving a file is. So the honest sentence is the one
already written in the association file — *the page they land on learns nothing
about the seed* — and it should stay that shape rather than being inflated into
*learns nothing*. The difference matters here more than it would elsewhere,
because this project's habit is to say the true narrow thing and this is exactly
the place somebody would round it up.

Two things follow, and both are cheap:

- **`/s` is a static file.** No server-side rendering, no analytics, no font CDN,
  no third-party anything. Everything it draws, it draws from the fragment.
- **The origin keeps no request log for that path**, or the shortest one the host
  permits. Worth doing because it is nearly free, and worth not claiming beyond
  what 20i actually allows.

## Two kinds of page, and the difference is everything

The temptation is to treat `/s` and a shared plant page as the same product at
two sizes. They are opposites.

| | `/s#…` — a seed link | `/p/…` — a shared plant |
| --- | --- | --- |
| Where the payload is | In the fragment, on the reader's device | On a server |
| Who can reach it | Whoever holds the link | Whoever holds the link — and the service |
| What is stored | Nothing | A seed, a birthday, a lineage, a name, and possibly a note |
| Who put it there | Nobody; it was computed | A person, who can be asked to take it down |
| What can be indexed | Nothing to index | A first name and a line of prose about a real meeting |
| Moderation surface | None | The subject of half this document |

`/s` is a computation dressed as a URL. `/p` is a publication. Everything hard
about phase 2 lives in the second column, and none of it needs solving to ship
the first.

## Languages

The app speaks eight and has twenty-five more written down. **The site has to
stay in step with it**, and that is a constraint on the design rather than a
later pass, because the first decision it forces is permanent from the moment
anybody shares a link.

### The language is not in the URL

**Settled here, because it cannot be settled later.** Not `/nl/s#…`, not
`nl.peacegarden.app`. The page reads `navigator.languages`, and a chooser on the
page overrides it and remembers the choice in that browser.

The argument that decides it has nothing to do with plumbing. **A link is minted
by one person and read by another, and those two people are the whole subject of
this app.** Marcus's phone would mint `/da/s#…`; the person it lands on reads
Dutch. A language in the URL is the sender's language imposed on the receiver, at
exactly the moment the app is meeting somebody new. The same holds for a shared
plant page, which is read by whoever the sharer sent it to and by strangers after
that.

Three things fall out of it, and all three are worth having:

- **The association file stays as it is.** `"/": "/s*"` matches `/s`, and would
  not match `/nl/s`. Widening it to `/*/s*` would cost the day of CDN cache and
  would then need the App Clip Experience prefix to be widened to match — or
  registered once per language, which is thirty-three experiences for one seed.
- **One App Clip prefix**, forever.
- **A deliberate override stays possible.** `?l=nl` overrides negotiation, is
  never minted by the app, and is present only when a person chose it — *read
  this one in Dutch*. A query does not disturb the AASA path match the way a path
  segment does, which is the technical half of why the override is a query and the
  default is neither.

**What it costs**, said plainly: client-side negotiation means no indexable page
per language. That is a price worth paying while plant pages are `noindex` and
the landing page is a paragraph and a plant. It becomes a live question the day
anything on the site is meant to be found in a search engine, and it is a
question about the marketing page rather than about seeds.

### Most of a plant page is already in every language

This is a real piece of luck and it is worth designing toward rather than
discovering, in the same way LANGUAGES.md found that turning the plant's name off
leaves a screen already in every language.

| Already language-neutral | Needs a word |
| --- | --- |
| The plant. Its whole appearance is derived and there is no text in it | *Shared by*, and *and* between two names |
| **Its name** — a synthesised Latinate binomial. *Zephanis stellula* reads the same in Amsterdam as in Margate, and it is the international convention for plants | The age, which is a number and a unit |
| Every mark, drawn in `Glyphs.swift` and `Chrome.swift`, which says its thing without a word | The report link |
| The date, which formats from the reader's locale | The line offering the app |
| The named place, which is the sharer's own words and is not translated | The passage's borrowed-language line, below |

So **the site's own string catalogue should be in the low tens, not the low
hundreds** — a target rather than an observation, and it should be defended when
somebody wants to add a paragraph. Thirty strings across thirty-three languages
is a commission that can ride alongside one round-two wave. Three hundred is a
second localisation project, and it would be the reason the site fell behind.

### The passage: one page, two readers

The app's rule is that two people on different banks deliberately see different
lines. A bank is a commission rather than a translation — sixty of the English
passages are etymologies of English words, which are facts about English and
false in Dutch — so **what a pair holds in common is the character of the passage
and not its words**. `QuoteBanks.swift` carries the argument.

**A page follows the same rule: the passage is drawn in the reader's language.**
The theme and the subtheme are what two phones already agree on across a language
boundary, they are language-neutral, and they need no field of their own: the
theme falls out of the lineage and the subtheme out of the plant's own genus
ending, both of which the page already carries. The reader's own bank supplies the
line.

- It extends the app's decision to the web rather than contradicting it there.
- The sharer's language is never published, because it never needs to be.
- A passage on a page shared across a language boundary is never in a language
  its reader cannot read — which is what showing the sharer's line would produce
  routinely, on the one kind of page that exists to be sent to somebody else.

**What it costs, and it should be on the page rather than discovered:** a page is
not the same page twice. Somebody who opens their own page on a friend's laptop
set to another language reads a different line. The provenance line under the
passage is where that is said, in one clause, and it is the same place the
borrowed-language line goes.

**Mechanically**, the banks are per-language files fetched at page load — one
bank of three hundred-odd passages is tens of kilobytes; thirty-three of them is
megabytes, so the page fetches the one it needs. That fetch tells the origin
roughly what language the reader has, which is worth recording here rather than
letting somebody find it: **the fragment still never arrives, and the bank
request is one more thing the request itself reveals.**

### When the site is behind the app

It will be, for most of its life, and there are two different ways to be behind
with two different answers. This is the app's own rule restated for a site.

| Behind on | Answer |
| --- | --- |
| **The site's own thirty strings** | Fall back to English silently. A label is short, and a fallback in a label is not the conspicuous case. |
| **A passage bank** | Fall back to English **and say so under the passage**, which is `isBorrowed` on the web. The passage is the one moment the site speaks at length, so it is the one place a borrowed language has to be named. |

A language with an interface and no bank is the normal state, not the exception:
every one of the twenty-five arrives that way, because an interface is a fortnight
and a bank is a commission.

### What keeps the two lists from agreeing only by memory

**Generate both, and let CI fail when they disagree.** The repository already has
the precedent that worked: `tools/reference/` is a second implementation of the
derivation, and CI runs it so the two cannot drift apart without somebody being
told.

- **The banks are a build product.** `Quotes+Dutch.swift` is the source and
  `/passages/nl.json` is generated from it. Commissioning a bank twice would
  produce two different Dutch banks, which is the passage version of exactly the
  drift the renderer section is about. **This is the whole answer to "the site has
  fewer languages than the app": generated banks mean it never has fewer.** What
  it can be behind on is thirty strings, which is a much smaller sentence.
- **A manifest, generated.** `Server/languages.json`, written by a tool beside
  `tools/strings/sync.sh`, listing every language code with whether the app has an
  interface for it and whether it has a bank. The site reads the manifest to
  decide what to offer and what to say. CI regenerates it and fails on a diff.
- **Somebody remembering is the option this repository has already rejected
  twice**, in `tools/preview/` and in the string catalogue that turned out to be
  131 strings short. It is not offered here as a third choice.

## What a shared plant page is

### What it shows

- **The plant**, drawn live from its seed and its birthday, at its real age
  today, turning the way it turns on the phone.
- **Its name**, which is derived and therefore not written by anybody — and,
  being a Latinate binomial, needs no translation anywhere.
- **Its age**, derived from the birthday.
- **The gardener who shared it, by their peace-garden username, and nobody
  else** — settled in [PHASES.md](PHASES.md), and the sentence that governs the
  rest of this section: until the second gardener says yes, the page must not
  indicate that a second person exists. No greyed slot, no *and one other*, no
  count. A placeholder is a disclosure.
- **The passage and its provenance**, drawn in the reader's own language from the
  published theme and subtheme — see *Languages* above.
- **The place as it was named**, if the sharer's note carries one.
- **The note**, if the sharer chose to publish it, attributed.
- **Whether the two seeds met by a tap or by a link**, once the wire format
  carries it. [SEEDS-ON-THE-WIND.md](SEEDS-ON-THE-WIND.md) already decided that a
  link is a weaker claim about a meeting than a tap, and this is the page that
  was supposed to be able to say which.

Once the second gardener accepts, the page carries both names and both notes,
attributed, in the sharer's order — settled, and the reasoning is in PHASES.md:
two accounts of one meeting are allowed to disagree, and reconciling them would
be inventing a version neither person wrote.

**The coordinate never goes up.** Not coarsened, not as a map link, not behind a
tap. [PLACE.md](PLACE.md) is unambiguous about why, and the page carries the
place as it was *named* or carries no place at all.

### Who can put a plant there

**Not whoever holds the seed.** This is the load-bearing point and it is easy to
get backwards. A seed is public by design — handed to strangers, printed on
cards, posted as a QR code — and a *reply* link carries enough for a third party
to compute the same child seed. So possession of a seed proves nothing about
whose plant it is, and an endpoint that accepted *here is a seed, publish it*
would let anybody who ever received a link publish a page in a stranger's name.

A plant is published by **a plot**, and a plot is proved by a key, and the name
on the page is the plot's name rather than a name asserted in the payload. That
is the whole of what identity is for here; see the next section.

### The name is read at page load, not baked into the entry

The app's promise is that *your username will only show publicly if you approve*.
If a page stores the name that was current when it was published, then changing
your name in Settings leaves old pages saying the old one, and removing your name
means finding every page it is on. Render the name from the plot record at read
time and both problems go: one edit changes every page you are on, and taking
your name off a page is one row in one table.

This creates two names, and confusing them will cost somebody an afternoon:

| | Where it lives | When it is fixed |
| --- | --- | --- |
| The name told at a meeting | `EncounterNote.peerDisplayName`, on the phone | At the meeting, forever. PLACE.md's *told, not inherited*, and it is right that it never updates. |
| The name on a plot | The plot record, on the service | Live. Whatever Settings says today. |

### How it comes down

Four ways, and each has to work without the other person agreeing.

1. **The sharer un-shares.** The page goes, and the second gardener's name goes
   with it, because it was never a page of their own.
2. **The second gardener removes their name**, at any time, without asking and
   without the sharer being involved. The page stays, with one name on it.
3. **A report.** One form, no account, takes a URL and a reason. On every page.
4. **The operator suspends a plot**, which hides every plant in it at once.

**A removed page answers 404 rather than a tombstone.** *This plant has been
removed* is a disclosure that something was there, addressed to whoever the
sharer was trying to get away from.

### Unlisted, which is a real property and is not secrecy

**Build the shared plant page as a capability URL first**: `/p/` plus twenty-odd
random characters, `noindex`, listed nowhere, reachable only by being sent to
somebody. That delivers the whole of *a place a shared plant lives so two people
can point at it*, including the invitation, the co-signature, both notes and
every withdrawal above, and it carries none of the garden's surface.

Say what unlisted buys, precisely, because it is worth having and it is not
privacy: **a page pasted into a group chat is public.** What unlisted means is
that the pages do not accumulate into a directory of people and meetings, that a
person's first name plus a line about an evening does not become a search result
for their name, and that nobody can walk from one page to a stranger's.

**A walkable garden converts every one of those pages from unlisted to listed.**
That is a change to what somebody consented to, not a deployment, so it is asked
again rather than shipped. Which is the strongest argument available for building
the unlisted page first: it lets every interesting decision in phase 2 be built,
used and corrected before the question of whether there is a public garden at all
has to be answered.

## Identity, and no more than that

What it actually has to do:

- Prove a plot is yours across a reinstall.
- Let A name B as somebody the service can reach, without A learning anything
  about B that A did not already have.
- Let B check that an invitation is about a plant B really helped make.
- Let either of them withdraw without the other.

**Recommendation: Sign in with Apple for the plot, and a per-meeting contact
token for the invitation.**

**Why not a device-held key alone.** The first thing on the list is surviving a
reinstall, and a device key does not survive a lost phone. A lost key leaves a
plot standing on the open web with somebody's name on it and nobody able to take
it down, which is the exact failure the whole moderation section exists to
prevent. Sign in with Apple gives a stable subject identifier per app, hands over
no email unless asked and relays it when it is, and is the least the App Store
will be happy with beside any other sign-in the app might grow later.

**Why not the seed.** Settled in PHASES.md and restated because it is the mistake
somebody will make while trying to avoid accounts: the seed is handed to
strangers on purpose.

**The contact token, which is per meeting rather than per person.** One more
field in `ExchangePayload` and `PollenCard`: sixteen random bytes minted for that
crossing, kept by both phones alongside the plant. It is enough, because an
invitation is always about one specific plant. A token that were stable per
person would let two people who had each met me discover they had met the same
person, and would create the first thing in this app that identifies somebody
across meetings — which is precisely what the design has avoided everywhere else.

That choice gives the service a pleasing shape. A share posts *an invitation
against token X*. B's phone, next time it opens, asks *is there anything for any
of these tokens*, presenting the ones from its own garden. The service therefore
holds a bag of pending invitations keyed by opaque bytes and **never needs a
directory of people at all**. A learns nothing about B; B learns only about a
plant that is already half theirs.

**What it costs.** PHASES.md says *B can block A*, and a per-meeting token cannot
express that: there is no A to block. What it can express is *one invitation per
plant* — already the rule — and *declining is final for that plant*. Between
them, those two deliver what the block was for without minting a per-person
identifier. **This is a departure from PHASES.md's wording and should be
confirmed rather than assumed**; the alternative is a second, per-person token,
and it should be added for that reason or not at all.

**Delivery stays as PHASES.md decided it**: B finds out next time they open the
app. No push, no device token, no notification permission. The label already in
Settings says *alert me*, and an alert when you open the app is an alert.

## Moderation

### What the surface actually is

| Surface | Who writes it | Volume |
| --- | --- | --- |
| A published encounter note | One of the two gardeners, about their own meeting | One per plant per gardener |
| A gardener username | The person it names | One per plot |
| A guest book entry | Anybody at all, to a person named by first name | Unbounded |
| A plant's name | Nobody — derived from the seed | Not a surface |

Plant names deserve their line: they are synthesised from twenty-four genus heads
and ten endings, so there is no message anybody can write in one.

### There is no guest book

**Recommended, plainly.** It is the highest-risk surface in the product and the
lowest-value one.

- It is a comment box on the open internet, addressed to a person by their first
  name, attached to a record of a real meeting between two real people. Every
  bad thing a comment box does, it would do here with unusually good targeting.
- It costs reporting, blocking, a queue, a retention policy, an abuse channel and
  somebody at the end of it — and the somebody is one person with no rota. It
  also makes this a user-to-user service in the sense the UK's Online Safety Act
  uses, and those duties do not scale down to a one-person project. **That is
  worth an hour of a lawyer's time before anything is built, and the cheapest way
  to not need the hour is to not build the guest book.**
- The app's social object is two people who met. A stranger leaving a line on it
  is a different app wearing this one's clothes.
- And there is already a way to say something to somebody here. Meet them.

So phase 2 publishes two kinds of text, both of which have exactly one author
each, and both of whose authors are named on the page.

### What is still needed, with no guest book at all

None of it is optional, and all of it is small because the volume is bounded by
the number of plants rather than by the number of strangers.

- **A report link on every page.** No account, no sign-in: a URL and a reason.
- **Deletion by the author, immediately**, with no request and no negotiation.
- **Suspension of a plot**, which takes every page in it down at once.
- **A reported username can be reset to `Gardener`**, which is the fallback the
  app already has.
- **Account deletion in the app.** Apple requires it of anything that creates
  accounts, so the day the plot exists it stops being a courtesy.
- **Nothing publishes prose on a yes given to a different question.** PHASES.md
  settled this for B's invitation; see *What this asks of the app*, where it turns
  out A needs the same screen.

## The App Clip

The clip does one thing the web page cannot, and it is not rendering. **A plant
grown in the clip is kept** — it carries into the full app through a shared app
group — where a plant drawn on a web page is a picture until somebody installs
something. The clip is the difference between seeing a plant and having one.

How it meets the site:

- **The clip needs the app on the App Store**, which the page does not. So the
  page is first, and the clip slots in ahead of it later for phones that offer
  it. That ordering is already in SEEDS-ON-THE-WIND.md and this document does not
  change it.
- **The page is part of the clip's plumbing rather than an alternative to it.**
  The Safari route to a clip card is a smart-app-banner meta tag on the page at
  the invocation URL, so `/s` carries that tag once the clip exists.
- **The AASA already names the clip** and is harmless to serve before the target
  exists. Nothing about the file changes for the clip; what changes is the App
  Clip Experience registered in App Store Connect against the `/s` prefix.
- **Everybody the clip does not reach still lands on the page**: Android,
  desktop, an iPhone that dismissed the card, an iPhone whose owner opened the
  link in a browser they installed themselves.
- **One thing to verify rather than assume: whether the fragment survives every
  invocation route.** Experience matching is on the URL prefix, and a fragment
  plays no part in it — but the clip has to *receive* the fragment to have a seed
  at all. It is expected to arrive in the invocation URL for a tapped link; it is
  worth proving on a device for an App Clip Code and an NFC tag before either is
  designed around. If a route drops it, that route needs the payload somewhere
  else, and the whole *no server sees the seed* property would have to be argued
  again for that route alone.

## What renders the plant

Four routes, and the project has already ruled on the principle that decides
between them.

| | Cost |
| --- | --- |
| **A third hand-maintained port**, in JavaScript | The thing HANDOVER.md forbids by name. `tools/preview/` has drifted twice, and a plant in the garden that does not match the plant on the phone is the one failure this project cannot survive. |
| **A JavaScript port with a CI gate** — the `tools/reference/` treatment: render the same seeds through both, fail on disagreement | Honest, and proven: CI already runs a second implementation of the derivation. It is real work to write and real work to keep. |
| **`SeedCore` compiled to WebAssembly** | One implementation, so drift is impossible by construction rather than by vigilance. Unknown bundle size. |
| **Rendered images made somewhere** | Ruled out on principle: it would be the first stored appearance in the project's history, on the one surface where a mismatch is most visible. ARCHITECTURE.md's one idea is that nothing about a plant's appearance is stored, sent or synced. |

**Recommendation: WebAssembly, with the CI-gated port as the fallback if the
bundle proves too heavy.**

The argument is that most of the work is done. `SeedCore` has no dependency on
SwiftUI, SceneKit or UIKit; it already builds and passes its tests on Linux
against swift-crypto and a `simd` compatibility layer, and HANDOVER.md notes that
the two platforms agreeing is what proves that layer equivalent rather than
merely plausible. A wasm target is the third host for a package that has already
been made portable twice.

It also lands on the right layering. `PlantBuilder` emits positions, normals, UVs
and indices grouped by material role — which is exactly what a WebGL renderer
wants. So the wasm module gives the browser the same buffers `PlantSceneBuilder`
gets, and the JavaScript is a renderer and nothing else: the web analogue of the
one file ARCHITECTURE.md says SceneKit is confined to.

**The honest risk is size.** A SwiftWasm module carries a runtime, and a seed link
is often opened on a phone on mobile data by somebody who has never heard of this
app. Measure it before committing. If it is too heavy, the fallback is the
CI-gated JavaScript port, and the gate is not negotiable — a third hand-maintained
copy of the geometry with nothing checking it is the one option that is off the
table however convenient it looks.

A split is available if wasm is heavy and the gate is expensive: the derivation is
small, stable and already has pinned vectors, so a JavaScript derivation is cheap
to gate; the geometry is large and is what has actually drifted. Take that only if
the measurements ask for it.

## The look of it

Short, because [BRAND.md](BRAND.md) and the app already decide it.

- **The stage, not a web page.** Black ground, the plant standing in a soft radial
  pool of light tinted a few percent toward its own colour, drawn in screen space
  behind a transparent canvas for the reason ARCHITECTURE.md gives.
- **Colour belongs to the plants.** Chrome is white at four opacities, as in the
  app. The icon's yellow-lime-green sweep is the mark's and stays on the mark.
- **Every drawn thing is monoline** — even weight, round free ends, no filled
  shapes, per BRAND.md §3.2, the rule the app icon and every chrome glyph are
  drawn to. That governs the report link's mark, the share mark, and — if a map is
  ever drawn — its paths.
- **Type and voice follow [TYPE.md](TYPE.md) and the app**: the serif for names
  and passages, wide-tracked small caps for labels, and no sentence that says what
  a thing is not.
- **Uppercasing is per language, as it is in the app.** `Chrome.letterCase(in:)`
  keeps the written case for `tr`, `az`, `el` and `ga`, and the site's small-caps
  labels need the same list rather than a blanket `text-transform: uppercase`.
  None of the eight shipping languages is on it; several of the twenty-five are.
- **Nothing assumes left to right.** No round-two language is right to left, so
  this costs nothing now: use logical properties rather than `left` and `right`,
  and it stays true when the other-alphabets round arrives. LANGUAGES.md's
  right-to-left pass found the app already sound, and it is cheaper to keep that
  than to earn it twice.
- **It is quiet.** No cookie banner, because there are no cookies. No analytics,
  because there is nothing worth knowing that is worth asking for.

## What this asks of the app

Settings are being designed now, so this is what phase 2 needs from that screen
and from the wire format, stated as switches rather than as intentions.

### The most urgent item is not a setting

**Two fields in `ExchangePayload` and `PollenCard`, decided now**, because
neither can be added to meetings that have already happened:

| Field | What it is | Why now |
| --- | --- | --- |
| **Contact token** | 16 random bytes for this crossing, kept by both phones with the plant | It is the only way A can tell B that a plant they made together has been shared. A meeting made without one can never carry an invitation. |
| **Provenance** | Whether the seeds met by a tap or by a link | SEEDS-ON-THE-WIND.md §5 already asks for it. A page that cannot say which is a page that quietly treats a forwarded link as a meeting. |

**Adding the token makes a sentence on screen untrue**, and it is the same
sentence PLACE.md caught once already:

> When you meet someone, your phones exchange your seed, your name, and a random
> number for that meeting. That is everything that crosses between you…

It has to be rewritten in the same commit that adds the field, and rewritten to
say what the token is *for* rather than that it exists — something with the shape
of *and a token that lets one of you tell the other if the plant is ever shared*.

### Existing switches whose meaning changes

| Control | Key | Today | From phase 2 |
| --- | --- | --- | --- |
| **Alert me when a joint seed is shared** | `sharing.invitations.v1`, on by default | Stores a bool that nothing reads | **On:** when you open the app, it asks the service whether a plant of yours has been shared, presenting the contact tokens in your garden. **Off:** the app makes no such request, so the service is never told this phone exists. |
| **Gardener username** | `GardenModel.identity.displayName` | What the other phone is told at a meeting — a claim, decoration, never matched on | Also the name printed on any plant you share, read live at page load. |
| **Use geographical coordinates** | `PlaceKeeping` | A coordinate written to the local note | Behaviour unchanged, and that is the decision. The paragraph beside it gains one clause: a shared plant carries the place as it was named. |

Two notes on those.

**Off must mean no request.** If *off* only suppressed a banner while the app
still asked, the switch would be a lie of the specific kind this project has been
careful about elsewhere. Off is the reason the service can honestly be told
nothing.

**The username's line underneath now says the wrong thing.** *Plants grown under
this name will keep it* describes the frozen name on a local encounter note,
which stays true — but beside a field that also feeds a public page it reads as a
promise that a published name cannot be changed, which is the opposite of the
design. It becomes something like *This is the name shown on any plant you
share*, and the local behaviour is left to the note screens that own it.

### New

| Control | Where | What it stores | Off / absent means |
| --- | --- | --- | --- |
| **Peace garden** — a section showing who you are signed in as, and a way to sign out | Settings, appearing only once you have shared something | The Apple subject identifier for the plot | Somebody who never shares never sees an account, and there is nothing signed in to sign out of |
| **Delete my peace garden account** | A fourth row under *Starting again*, held rather than tapped, crimson | — | Your plot, its pages and your name on other people's pages all go. **Your local garden stays**, which is the sentence that has to be on screen, because every other row on that screen takes something local away |
| **Show in the peace garden** | On the plant, in Garden — **not** in Settings | Per plant | A plant is on the web because you put it there, one at a time. It is not a preference, and a standing switch that published future plants automatically would be a consent given once for things that do not exist yet |

**`Reset everything` needs a line about the plot.** Today it is local, and it says
so. Once a plot exists, a reset that leaves it standing is the orphaned-plot
failure by another route — so either it takes the plot too and says so, or it says
plainly that the plot stays and where to go for it. Either is defensible; silence
is not.

### Deliberately not settings

- **A guest-book switch**, because there is no guest book and there is nothing to
  switch off.
- **A block list.** Declining an invitation is final for that plant and there is
  one invitation per plant, so the decline is the block. A list would need to name
  people, and the app has no stable identity for a person — by choice.
- **Publishing a note.** It belongs in the flow, shown as it will appear, at the
  moment somebody is deciding. Which raises the one gap:

**A publishing their own note deserves the screen B gets.** PHASES.md worked out
that an invitation which publishes prose somebody wrote privately, on a yes given
to a question about their name, is a trick — and then specified the remedy for B
only. It is the same trick on A's side: A wrote that note for themselves too,
before any of this existed. So the share flow shows A their own note as it will
appear, lets them edit it there with the machinery that already exists, and lets
them share with their name and no note at all.

### Two build steps, in the app's repository

Neither is a setting, and both are the reason the site's languages and the app's
stay the same list rather than two lists that agree for a while.

| Tool | Writes | Gated by |
| --- | --- | --- |
| **A bank exporter**, beside `tools/strings/sync.sh` | `/passages/<code>.json` for every bank in `QuoteBank` | CI fails on a diff, so a bank added to the app is a bank the site has |
| **A language manifest** | `Server/languages.json` — every code, whether the app has an interface, whether it has a bank | The same job |

The site adds no language of its own and commissions no bank of its own. If it
ever needs to, that is a decision to take deliberately rather than a file
somebody adds.

### One more, and it is a fact rather than a preference

**A plant that is on the web should look different in Garden from one that is
not.** Whatever the mark is, it is monoline, and tapping it reaches the page.
Somebody who cannot tell at a glance which of their plants are published has been
handed a decision they cannot review.

## Still open

- **Whether the garden is a place you can walk.** Everything above is written so
  that this can be answered late. Answering it *yes* relists every existing page,
  which is a fresh consent rather than a release.
- **One place, or many.** PHASES.md's question, unchanged. One place is the idea
  and one place is where every moderation problem lives.
- **Whether a plant grown alone can be shared.** BOTANICAL-GARDEN.md's third
  question: a theme comes from a pair, so a solitary plant has no area to stand
  in — unless the seed's own theme trait is used instead. It decides what the
  front page is for.
- **Whether a page expires.** The same question as PHASES.md's *does a plant ever
  die*, asked of a URL, where it is also a retention policy.
- **Whether the coordinate is ever publishable.** The answer today is no and
  nothing needs it to be. If it ever is, it is a new consent with its own screen
  and its own withdrawal.
- **The wasm bundle size**, which decides whether the recommended renderer
  survives contact with a phone on mobile data.
- **Whether the fragment reaches an App Clip on every invocation route.**
- **How many languages the site's own thirty strings ship in on the first day.**
  English alone is defensible and honest; eight matches the app; thirty-three
  matches the ambition. It is a commission of a known size, which is unusual for
  a question on this list.
- **Whether the passage line says, every time, that it was drawn for the reader.**
  It has to be said somewhere. Saying it on every page may be one sentence more
  than the page can carry, and the alternative — saying it only where the reader's
  language differs from the sharer's — would mean publishing the sharer's
  language, which is the one thing this design avoids having to do.
- **Whether a per-person block is needed after all**, and therefore whether a
  second, per-person token has to go into the wire format alongside the
  per-meeting one — a decision that also cannot be made retrospectively.
- **Who answers a report.** There is one person and no rota, and that is a fact
  about the service rather than a gap in the spec.
- **Where the plot service runs.** 20i shared hosting serves a static file well;
  a plot service is a database, an API, backups and a restore somebody has
  actually tried. Not decided, and it is the only part of this that has a monthly
  bill.
- **Whether `peacegarden.app` is also the app's marketing page.** The position
  here is that `/s` with no seed in it is already that page, and that a separate
  one earns its place only when there is an App Store listing to point at.
