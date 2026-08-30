# Peace Garden

An iPhone app in which a plant is grown from a seed drawn once, on one phone,
for one person — and where two people who meet in person can cross their seeds
by touching their phones together, growing a plant that neither could have grown
alone.

The plant is the only thing on screen. Black background, full-colour 3-D plant
you can turn with a finger, and controls that appear when you tap and see
themselves out again.

**This is phase 1: the seed, and the meeting.** The shared peace garden with
other people's plots and guest books is phase 2, sketched in
[docs/PHASES.md](docs/PHASES.md).

## What works

- **A seed of your own.** Minted once from 32 random bytes plus what the phone
  can see of the moment — model, locale, timezone, uptime, the instant itself —
  hashed into 32 bytes that never change and never leave the phone unless you
  meet someone.
- **A plant derived entirely from that seed.** Twelve archetypes (spire, umbel,
  fern, orchid, lotus, thistle, vine, bell, star, poppy, succulent, plume),
  around sixty inherited traits, procedural geometry, a colour palette, and a
  binomial name.
- **Real-time growth.** Germinating, seedling, growing, in bud, in bloom,
  mature, over days — plus a day/night rhythm, so a flower that opens by day is
  closed at two in the morning.
- **Meeting someone.** Both open Meet, tap the tops of the phones together, and
  both phones independently derive the same hybrid and prove it to each other
  before either one shows it.
- **Keeping it.** The hybrid, with the date and time if you want them, a place,
  and a line about the meeting. Then it grows, from the moment you met.

## Where the tap really happens

An iPhone app cannot open an NFC link to another iPhone — Core NFC reads tags,
and the tap-to-share gestures in iOS are system features with no API. So the tap
is treated as **a gesture, not a transport**: both accelerometers feel the
knock, and the seeds cross over Multipeer Connectivity, which is already
connected by then. Nothing proceeds until both phones have felt it within three
seconds of each other.

The full reasoning, the handshake and the derivation are in
[docs/EXCHANGE-PROTOCOL.md](docs/EXCHANGE-PROTOCOL.md).

## Building it

```sh
brew install xcodegen
git clone git@github.com:marcusbsorensen/peace-garden.git
cd peace-garden
xcodegen generate
open PeaceGarden.xcodeproj
```

Set your team under Signing & Capabilities, then run. `.xcodeproj` is generated
rather than checked in — it is the worst file in an iOS repository to merge.

**You need two physical iPhones.** The Simulator has no accelerometer to feel
the tap and no radio for Multipeer, so the exchange can only be exercised on
hardware. Everything else — minting, growth, rendering, the garden — runs in the
Simulator.

Requires iOS 17 (SwiftUI `@Observable`), Xcode 15 or later.

### Running the tests

```sh
cd Packages/SeedCore
swift test
```

or open the package in Xcode and test the `SeedCore` scheme. The tests cover the
parts that are expensive to get wrong: the derivation vectors, commutativity of
the cross, trait ranges across hundreds of genomes, growth monotonicity, and
120 genomes × 7 ages of generated geometry checked for non-finite vertices and
out-of-range indices.

```sh
python3 tools/reference/derivation_reference.py
```

prints the same vectors from an independent implementation of the spec in
another language. If the Swift tests and this file ever disagree, one of them
has drifted.

### Seeing plants without a Mac

`tools/preview/` is a Python port of the genome, the growth model and the
geometry, with a rough renderer, so the plants can be looked at before there is
a device to look at them on:

```sh
cd tools/preview
pip install numpy pillow
python3 preview.py --seeds 12 --out sheet.png        # twelve plants in bloom
python3 preview.py --seed hello --stages --out row.png   # one plant over its life
python3 preview.py --cross ada marcus --out cross.png    # two parents and their child
```

It is a sketch, not a second source of truth — `SeedCore` is authoritative, and
the port will drift the moment the Swift changes. It earns its place by being
runnable anywhere.

Eight plants in bloom:

![Eight plants](docs/images/plants.png)

One plant from seed husk to open flower:

![Growth stages](docs/images/growth.png)

Two parents, and the plant their meeting made — the child takes its form and
pale blue from one, its depth of colour and broader leaves from the other, and
its name from both:

![A cross](docs/images/cross.png)

### Status, honestly

This was written on Linux, where there is no Swift toolchain and no Xcode, so
**none of the Swift has been compiled or run.** Expect to fix build errors on
first open.

What has actually been executed, rather than believed:

- **The derivation.** `tools/reference/derivation_reference.py` implements the
  spec independently and was run; its outputs are pinned into the Swift tests.
  Commutativity, distinctness across 256 meetings between the same pair, and the
  36/36/22/6 inheritance mix are all measured, not assumed.
- **The geometry.** The Python port above was run over 120 genomes at seven ages
  each and checked for the same properties the Swift tests assert: no non-finite
  vertices, unit-length normals, in-range indices, and a triangle count that
  stays inside budget (the worst case is 42k against a 120k ceiling). Rendering
  those found three real defects, all since fixed: flowers were specks against
  the foliage, seedlings had full-thickness stems and full-size leaves, and the
  seed husk vanished in a single frame instead of shrinking away.

What has *not* been seen is the SceneKit rendering — the lighting rig, the
materials, the bloom. The one thing to check first there: if a petal's tip
colour appears at its base, flip the row order in
`GradientTexture.image(for:palette:)`, where the comment says so.

## Layout

```
.
├── Packages/SeedCore/          Pure Swift. Plants, not pixels.
│   ├── Sources/SeedCore/
│   │   ├── Determinism/        Hashing, seeds, deterministic noise
│   │   ├── Genome/             Minting, traits, archetypes, names, crossing
│   │   ├── Growth/             Time to appearance
│   │   ├── Morphology/         Skeleton, surfaces, mesh, colour
│   │   ├── Exchange/           Wire format
│   │   └── Persistence/        The garden file
│   └── Tests/SeedCoreTests/
├── App/PeaceGarden/            SwiftUI + SceneKit
│   ├── Rendering/              Mesh to SceneKit, lighting, thumbnails
│   ├── Exchange/               Multipeer, touch detection, state machine
│   └── Views/
├── docs/
│   ├── ARCHITECTURE.md         Why a plant is a seed plus a birthday
│   ├── EXCHANGE-PROTOCOL.md    The handshake, and why not NFC
│   ├── PHASES.md               What phase 2 has to answer
│   └── images/                 Previews rendered by tools/preview
├── tools/
│   ├── reference/              Executable spec for the derivation
│   └── preview/                Python port + renderer, to see plants anywhere
└── project.yml                 XcodeGen
```

## The one idea

A plant is a seed plus a birthday. Everything else — shape, colour, name, pace,
geometry — is derived. Nothing about a plant's appearance is stored, sent or
synced, which is why two phones can agree on a hybrid without a server, why a
garden of a hundred plants is a few kilobytes, and why a saved plant can never
drift from the plant it draws.

It also means the derivation can never casually change. Hence the versioned
domain tags, the traits drawn by name rather than by position, and the reference
implementation. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
