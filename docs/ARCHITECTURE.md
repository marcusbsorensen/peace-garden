# Architecture

## The one idea

**A plant is a seed plus a birthday. Everything else is derived.**

Nothing about a plant's appearance is stored, sent, or synced. Its shape, its
colours, its name, its pace of growth and its geometry are all pure functions of
32 bytes and a date. That single decision is what makes the rest of the app
small:

- Two phones that have never met agree on a hybrid without a server, because
  they both compute it from the same 32 bytes.
- A garden of a hundred plants is a few kilobytes of JSON.
- A saved plant can never disagree with the plant it draws.
- Growing over weeks needs no background work: the plant is drawn from the
  current time whenever it is looked at.

The cost is that the derivation can never casually change. That is why every
domain tag is versioned, why traits are drawn by name rather than by position in
a stream, and why the derivation has an executable reference implementation and
pinned test vectors.

## Layers

```
  App/PeaceGarden          SwiftUI + SceneKit. Knows about screens and pixels.
        |
        |  Genome, GrowthModel.State, PlantMesh
        v
  Packages/SeedCore        Pure Swift. Knows about plants. No UI, no I/O.
```

`SeedCore` has no dependency on SwiftUI, SceneKit or UIKit — it emits plain
vertex buffers, and the only Apple framework it touches is CryptoKit for
SHA-256. That is what lets the geometry be tested without a GPU and the
derivation be tested without a device.

### SeedCore

| Area | What it does |
| --- | --- |
| `Determinism` | Domain-separated SHA-256; `SeedID`; SplitMix64 for cheap in-plant noise |
| `Genome` | Minting, trait derivation, archetypes, naming, cross pollination |
| `Growth` | Elapsed time to stage, height, unfurling, bloom, day/night rhythm |
| `Morphology` | Skeleton, parametric surfaces, mesh assembly, colour ramps |
| `Exchange` | Wire format, seed links, and the cross-pollination result |
| `Persistence` | The garden file |

### App

| Area | What it does |
| --- | --- |
| `GardenModel` | The observable state: identity, kept plants, and a slow clock |
| `Rendering` | `PlantMesh` to SceneKit; the lighting rig; the stage; thumbnails |
| `Exchange` | Multipeer session, the touch detector, the protocol state machine |
| `Views` | Black screens with controls that appear on a tap |

## Why traits are drawn by name

```swift
source.value("stem.height", 0.55...1.25)
```

not

```swift
rng.next()   // whatever comes next in the stream
```

A stream means that inserting one new trait in version 1.1 shifts every trait
after it, and every plant on every phone changes overnight. Drawing by name —
`SHA-256(domain ‖ seed ‖ label)` — means a new trait consumes nothing that
already exists. Old plants keep growing the way their owners remember them.

It also makes inheritance natural: a hybrid's `stem.height` can be looked up in
either parent, because the label is the same everywhere.

The label strings are therefore part of the file format. Renaming
`"stem.height"` is a breaking change to every plant that exists.

## Why geometry is a buffer, not a scene

`PlantBuilder` produces positions, normals, UVs and indices grouped by material
role. It does not produce `SCNNode`s. That keeps the interesting maths testable
in a plain test target — a hundred and twenty genomes at seven ages each,
checked for non-finite vertices and out-of-range indices — and it means the
renderer is one file. SceneKit is used today; moving to RealityKit is a rewrite
of `PlantSceneBuilder.swift` and nothing else.

Every surface in the plant is a parametric grid evaluated through one function,
`MeshBuilder.addSurface`, with normals derived from neighbouring grid points.
A tube, a leaf blade, a petal and a dome are the same code with different
`point(u, v)`. One place to get the winding and the normals right instead of
five.

## Why the backdrop is SwiftUI and not the scene

The pool of light behind the plant is a `RadialGradient` in SwiftUI, painted
behind a transparent `SCNView`, rather than a SceneKit background.

A single image handed to `scene.background.contents` is treated as a spherical
environment map: it would distort, and it would swing around as the plant turns
— exactly what a backdrop must not do. Screen-space is where a photographic
backdrop belongs, it costs nothing to draw, and the falloff can be spelled out
stop by stop, which is what keeps a near-black gradient from banding on an OLED
screen in a dark room.

The scene's ambient fill is tinted to the same colour, so the plant reads as
standing in that light rather than cut out and pasted onto it.

## Why growth is a function of time, not a state machine

There is no "grow" step to run, nothing to catch up on after the app has been
closed for a week, and no way for two devices to disagree about how far along a
plant is. `GrowthModel.state(birth:now:)` takes a date and returns the plant.
Closing the app for a month and reopening it shows a month of growth, because
that is what the function returns.

The day/night rhythm rides on the same idea: it reads the hour out of `now`, so
a flower that closes at night is closed at night without anything having to run.

## Threading

The exchange service and the garden model are `@MainActor`. Multipeer's
callbacks arrive on arbitrary queues, so every delegate method is `nonisolated`,
extracts what it needs into `Sendable` values (a `String` display name, a
`Data`) and hops to the main actor. Nothing else in the app is concurrent:
building a mesh takes a few milliseconds and happens when growth visibly
changes, not per frame.
