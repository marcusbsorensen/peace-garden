import CoreGraphics
import SeedCore
import simd
import SwiftUI

/// The plot itself: a clod of ground hanging in space, with the soil's own
/// depth showing at the cut.
///
/// A plane that merely stops leaves *what is off the side* unanswered; a plot
/// with a cut answers it by showing the answer. `docs/ARRANGING.md` §*The garden
/// is a floating square plot*.
///
/// The materials and the light live here; `GardenTerrain` does the drawing and
/// `GardenWorlds` holds the eight grounds. The flat plot below is what is drawn
/// if the world atlas is ever missing from the bundle, so that a garden without
/// it is still a place with an edge.
enum GardenGround {
    // MARK: The cut

    /// How deep the soil is under a place on the plot, in metres.
    ///
    /// The mockup's taper: a floor at the rim everywhere, and a bulge of up to
    /// 1.70 m more toward the middle, measured on the Chebyshev radius so it
    /// follows the square rather than a circle inside it.
    ///
    /// **The floor is the whole point.** The only part of a floating plot's
    /// underside anybody ever sees is the part near the near edges, so a plot
    /// whose soil thins to a line at the rim reads as a tile rather than as a
    /// piece of ground with a root under it. That is why the rim is the one
    /// place the depth is not allowed to be economised.
    static func cutDepth(x: Double, z: Double, plotSide: Double) -> Double {
        let half = plotSide / 2
        guard half > 0 else { return rimDepth }
        let radius = min(1, max(abs(x), abs(z)) / half)
        let bulge = pow(max(0, 1 - pow(radius, 1.7)), 0.85)
        return rimDepth + 1.70 * bulge
    }

    /// What `cutDepth` comes to at the rim.
    ///
    /// **The rim is the only depth that is ever seen.** Looking down at
    /// thirty-five degrees, the plot's own surface hides everything under it, so
    /// the bulge below the middle is never drawn and this number is the whole of
    /// what *thick* means. It started at the mockup's 0.40 m, which read as a
    /// tile with a lip; at 0.95 it reads as a piece of ground with a root under
    /// it, which is the thing the cut is there to say.
    static let rimDepth = 0.95

    // MARK: The light

    /// One light, and the ambient it is set against.
    ///
    /// Hemispheric rather than a studio: sky from above, bounce from the ground
    /// below, so a shadowed face is lit by the sky rather than by nothing.
    /// `StageBackdrop` is a hard key and a near-black ambient on purpose, which
    /// is right for a plant photographed for a box and exactly wrong outdoors.
    ///
    /// `GardenLight` is where one of these comes from: the sun and the moon
    /// going round, read by the ground, the plants, the shadows and the sky
    /// alike. Nothing here knows what hour it is.
    struct Light: Equatable, Sendable {
        var direction: SIMD3<Double>
        var colour: SIMD3<Double>
        var strength: Double
        var sky: SIMD3<Double>
        var bounce: SIMD3<Double>
        /// How high the body in the sky is, `0` at the horizon and `1` at its
        /// own peak. The sky, the stars and the softness of a shadow are all
        /// read off this rather than off the hour, so they agree with the light
        /// rather than merely with the clock.
        var up: Double = 1
        /// Which body is up. Exactly one of them ever is.
        var isDay: Bool = true
        /// Light from far above that is there at every hour: the Milky Way.
        ///
        /// See `GardenLight.galaxy`. Zero at noon, because the sky outshines it.
        var galaxy = SIMD3<Double>(repeating: 0)

        /// The sun at its highest, spelled out.
        ///
        /// It is `at(hour: 12)`, and `PlotTests` holds the two to each other. It
        /// is written out rather than computed because it is a default argument
        /// in this file while the orbit is an extension in another, and the
        /// compiler will not reach across for it in that position.
        static let noon = Light(
            direction: SIMD3(-0.331_965_483_940_478_6,
                             0.882_947_592_858_926_9,
                             0.331_965_483_940_478_6),
            colour: SIMD3(1.00, 0.96, 0.88),
            strength: 0.76,
            sky: SIMD3(0.40, 0.48, 0.60),
            bounce: SIMD3(0.27, 0.25, 0.20),
            up: 1,
            isDay: true
        )
    }

    /// A surface's colour under the light.
    ///
    /// `shadow` is 1 in the open and 0 in shade; the `0.18 +` keeps a shadowed
    /// face lit by the sky rather than black. Softened Lambert, because a leaf
    /// and a bank of soil both scatter more at a grazing angle than a perfect
    /// diffuser would.
    static func shade(
        base: SIMD3<Double>,
        normal: SIMD3<Double>,
        shadow: Double = 1,
        light: Light = .noon
    ) -> Color {
        let lit = shaded(base: base, normal: normal, shadow: shadow, light: light)
        return Color(red: lit.x, green: lit.y, blue: lit.z)
    }

    /// The same answer as components, for the thousands of quads a terrain is
    /// made of — a `Color` per cell would be four thousand boxed values a frame.
    static func shaded(
        base: SIMD3<Double>,
        normal: SIMD3<Double>,
        shadow: Double = 1,
        light: Light = .noon
    ) -> SIMD3<Double> {
        let hemi = 0.5 + 0.5 * normal.y
        let key = max(0, simd_dot(normal, light.direction))
        let lit = pow(key, 0.9) * light.strength * (0.18 + 0.82 * shadow)

        // The galaxy is straight overhead, so it falls on what faces up and
        // hardly at all on a bank that faces sideways — the same hemispheric rule
        // as the sky, weighted harder toward the top.
        let overhead = hemi * hemi

        var out = SIMD3<Double>()
        for channel in 0..<3 {
            let ambient = light.sky[channel] * hemi + light.bounce[channel] * (1 - hemi)
                + light.galaxy[channel] * overhead
            out[channel] = min(1, max(0, base[channel] * (ambient + light.colour[channel] * lit)))
        }
        return ceilinged(out)
    }

    // MARK: What the ground is made of

    /// What the slab's side is made of, top to bottom.
    ///
    /// A cut is not one colour. The dark humus is a hand's depth and no more,
    /// the earth under it holds most of the depth, and rock comes up from the
    /// bottom — which is why a road cutting reads as ground rather than as a
    /// painted edge. The website's slabs hang the same three from the same
    /// numbers (`COLOUR` in `longwalk.js`), so a plot is one object in both.
    ///
    /// **Lighter than the ground they sit under, on purpose.** A cut face is
    /// vertical, so it is lit by the sky and by little of the sun, and materials
    /// chosen to look right in the hand came out as a black band under the plot.
    /// These are chosen for how they read once the hemispheric ambient has had
    /// them, which is the only way they are ever seen.
    static let humus = SIMD3<Double>(0.205, 0.158, 0.116)
    static let earth = SIMD3<Double>(0.375, 0.300, 0.232)
    static let bedrock = SIMD3<Double>(0.340, 0.330, 0.318)
    static let stone = SIMD3<Double>(0.455, 0.437, 0.415)

    /// The rock the slab's lower part is made of: the bedrock, with some of the
    /// stone in it.
    ///
    /// **Lighter than the earth above it, which bedrock alone is not.** The
    /// side curves under toward its lower edge and the sky reaches less of it,
    /// so a rock no lighter than the earth came out the same dark brown as the
    /// earth, and the strata were gone. The cells used to carry the difference
    /// by scattering stone-coloured ones through it; a band has to carry it
    /// itself.
    static let rock = bedrock + (stone - bedrock) * 0.45

    /// How much lighter the side is drawn than its materials, all of it alike.
    ///
    /// **Measured, not chosen** (2 October 2026). The side used to be lit at
    /// half the sun and nudged up and down cell by cell, and stone-coloured
    /// cells were a fifth of its lower half; lit as planes by the whole of the
    /// light, the same materials came out a quarter darker on average at ten in
    /// the morning, and by night nearly black. At this the side turned away
    /// from the sun is as bright as the bank was (an average of 44.5 against
    /// 46.2 out of 255 at ten, both faces in shade; 19.4 against 19.2 at
    /// midnight), and the side turned toward it is brighter than that — 50.2
    /// against 43.7 at five, with the low sun on one face — which is the point.
    static let sideLift = 1.45

    /// The colour of the side `down` metres below the ground's edge, before the
    /// light.
    ///
    /// `humusTo` is where the humus gives way to earth and `rockFrom` where the
    /// earth gives way to rock, both in metres down at this place on the rim,
    /// and `bottom` is how far down the lower edge is. **The bands are drawn
    /// with their edges where these say**, so a boundary is a line that wanders
    /// along the side with the rest of the slab rather than a step between
    /// rows; what this adds is the grading inside a band — the humus warming
    /// into the earth under it, the earth greying where the rock comes up — so
    /// a boundary is soft on one side and still reads as a boundary.
    static func sideColour(down: Double, humusTo: Double, rockFrom: Double, bottom: Double)
        -> SIMD3<Double> {
        func mix(_ a: SIMD3<Double>, _ b: SIMD3<Double>, _ t: Double) -> SIMD3<Double> {
            a + (b - a) * min(max(t, 0), 1)
        }
        let base: SIMD3<Double>
        if down < humusTo {
            let f = down / max(humusTo, 1e-6)
            base = mix(humus * 0.94, mix(humus, earth, 0.3), (f - 0.45) / 0.55)
        } else if down < rockFrom {
            let f = (down - humusTo) / max(rockFrom - humusTo, 1e-6)
            base = f < 0.2
                ? mix(mix(earth, humus, 0.16), earth, f / 0.2)
                : mix(earth, mix(earth, rock, 0.25), (f - 0.75) / 0.25)
        } else {
            let f = (down - rockFrom) / max(bottom - rockFrom, 1e-6)
            base = mix(mix(earth, rock, 0.6), rock, f / 0.3)
        }
        return base * sideLift
    }

    /// A fixed number for a place, so a bank of earth is the same bank every
    /// time it is drawn. The usual integer hash: cheap, and it does not matter
    /// that it is not a good one.
    static func grain(_ a: Int, _ b: Int, _ salt: Int = 0) -> Double {
        var h = UInt64(bitPattern: Int64(a &* 73_856_093 ^ b &* 19_349_663 ^ salt &* 83_492_791))
        h ^= h >> 33
        h = h &* 0xff51_afd7_ed55_8ccd
        h ^= h >> 29
        return Double(h % 100_000) / 100_000
    }

    /// A slow wander round a closed loop, about `-1...1`, that meets itself
    /// with no seam.
    ///
    /// A whole number of knots round the loop, so the last stretch runs into
    /// the first, eased through with a Catmull-Rom curve rather than a
    /// smoothstep: a smoothstep is flat at every knot, and a lower edge made of
    /// it undulates in a row of little plateaus.
    static func roundTheLoop(_ along: Double, perimeter: Double, wavelength: Double, salt: Int) -> Double {
        let knots = max(3, Int((perimeter / wavelength).rounded()))
        let t = along / perimeter * Double(knots)
        let i = Int(t.rounded(.down))
        let f = t - Double(i)
        func knot(_ n: Int) -> Double { grain(((n % knots) + knots) % knots, salt, 61) * 2 - 1 }
        let p0 = knot(i - 1), p1 = knot(i), p2 = knot(i + 1), p3 = knot(i + 2)
        let f2 = f * f, f3 = f2 * f
        return 0.5 * (2 * p1 + (p2 - p0) * f + (2 * p0 - 5 * p1 + 4 * p2 - p3) * f2
            + (3 * p1 - p0 - 3 * p2 + p3) * f3)
    }

    // MARK: The crumb

    /// What a cell of a world is, which decides how its crumb is drawn. Written
    /// into the atlas by `tools/worlds/worlds.py`; the order is that file's.
    enum Kind: UInt8, Sendable {
        case grass, earth, gravel, rock, scree, snow, water, box, tarmac, sand

        /// **The website's crumb, by surface.** Its ground got its detail from a
        /// five-centimetre lattice with a tone to a crumb, and the spread of that
        /// tone is what says what the ground is: narrow on a trodden path, wide
        /// on dug earth, widest on stones. `docs/ARRANGING.md` §*The crumb*.
        var crumb: Crumb {
            switch self {
            case .grass: Crumb(spread: 0.20, perCorner: true, rough: 0.004)
            case .earth: Crumb(spread: 0.34, perCorner: false, rough: 0.011)
            case .gravel: Crumb(spread: 0.32, perCorner: false, rough: 0.004)
            case .rock: Crumb(spread: 0.22, perCorner: false, rough: 0.010)
            case .scree: Crumb(spread: 0.36, perCorner: false, rough: 0.008)
            case .snow: Crumb(spread: 0.07, perCorner: true, rough: 0.003)
            case .water: Crumb(spread: 0.04, perCorner: true, rough: 0)
            case .box: Crumb(spread: 0.24, perCorner: false, rough: 0.008)
            case .tarmac: Crumb(spread: 0.08, perCorner: false, rough: 0.001)
            case .sand: Crumb(spread: 0.14, perCorner: true, rough: 0.003)
            }
        }
    }

    /// How one kind of ground is broken up.
    ///
    /// `spread` is how far a crumb's tone may sit from its neighbours', as a
    /// fraction of its colour. `perCorner` tones a surface on its corners and
    /// averages them across each face, so no face edge shows — grass and snow
    /// are surfaces. Without it each face takes its own tone, because gravel,
    /// earth and stone are heaps of separate things, and the website found the
    /// smooth version drew wet sand. `rough` is how far, in metres, a corner of
    /// the lattice is lifted or sunk, which is what lets the light find a clod.
    struct Crumb: Sendable {
        let spread: Double
        let perCorner: Bool
        let rough: Double
    }

    /// A slow wander under the crumb, a few per cent either way over most of a
    /// metre, so a lawn is damper in one corner than another rather than one
    /// colour sprinkled evenly. The website's drift, for the same reason.
    static func drift(x: Double, z: Double) -> Double {
        let scale = 0.7
        let u = x / scale + 100, v = z / scale + 100
        let i = Int(u.rounded(.down)), j = Int(v.rounded(.down))
        let fu = u - Double(i), fv = v - Double(j)
        let su = fu * fu * (3 - 2 * fu), sv = fv * fv * (3 - 2 * fv)
        let a = grain(i, j, 31), b = grain(i + 1, j, 31)
        let c = grain(i, j + 1, 31), d = grain(i + 1, j + 1, 31)
        let mixed = (a * (1 - su) + b * su) * (1 - sv) + (c * (1 - su) + d * su) * sv
        return (mixed - 0.5) * 0.10
    }

    /// The flat plot's surface: a plain turf, deliberately duller than any world
    /// will be. It is a stand-in for a chosen ground and should look like one.
    static let turf = SIMD3<Double>(0.235, 0.265, 0.190)

    /// Every colour the ground puts on screen passes through here.
    ///
    /// `Chrome`'s rule is that the plant is the only saturated thing on screen,
    /// and a lawn in full chroma takes that away. Enforcing it in one function
    /// rather than trusting each material means a material written too bright
    /// later cannot quietly break the rule.
    ///
    /// **The ceiling is 0.28 and it is a decision, not a measurement.** The
    /// generator that held the original number was never committed; 0.28 sits
    /// just under `StageBackdrop.saturation`, which is the most saturated thing
    /// the app already puts behind a plant.
    static let saturationCeiling = 0.28

    static func underCeiling(_ rgb: SIMD3<Double>) -> Color {
        let held = ceilinged(rgb)
        return Color(red: held.x, green: held.y, blue: held.z)
    }

    static func ceilinged(_ rgb: SIMD3<Double>) -> SIMD3<Double> {
        let high = max(rgb.x, max(rgb.y, rgb.z))
        let low = min(rgb.x, min(rgb.y, rgb.z))
        guard high > 0 else { return SIMD3(repeating: 0) }

        let saturation = (high - low) / high
        guard saturation > saturationCeiling else { return rgb }

        // Pulled toward its own grey rather than desaturated to it, so the
        // material keeps its hue and loses only what it was not allowed.
        let keep = saturationCeiling / saturation
        let grey = high * (1 - keep)
        return rgb * keep + SIMD3(repeating: grey)
    }

    // MARK: The shapes

    /// The plot's surface: the ground's outline, flat.
    static func topFace(plotSide: Double, in view: Isometric) -> Path {
        PlotOutline.of(plotSide: plotSide).path(in: view)
    }

    /// The side of the flat plot, for when there is no world to stand it on:
    /// the same slab the worlds hang, from the plot's outline at ground level,
    /// at noon.
    ///
    /// Fill each with a stroke of its own colour, or the joins show as hairlines.
    static func nearFaces(plotSide: Double, in view: Isometric) -> [(Path, Color)] {
        let rim = PlotOutline.of(plotSide: plotSide).points.map { SIMD3($0.x, 0, $0.z) }
        return side(rim: rim, view: view, light: .noon).map { piece in
            var path = Path()
            path.addLines(piece.points)
            path.closeSubpath()
            return (path, Color(red: piece.colour.x, green: piece.colour.y, blue: piece.colour.z))
        }
    }

    // MARK: The slab's side

    /// One piece of the slab's side as it lands on screen, already lit.
    struct SidePiece {
        let points: [CGPoint]
        let colour: SIMD3<Double>
    }

    /// How far in the side has come by the lower edge, in metres.
    ///
    /// **A clod, not a box** (Marcus, 2 October 2026: *a solid slab of earth
    /// with organic contours that is floating, not melting away*). The side
    /// leans in a little under the rim and more toward the lower edge, which
    /// is the taper `ARRANGING.md` promised on 17 September and nothing drew.
    /// Twenty centimetres is enough for the two side corners of the diamond to
    /// show the slab drawing in against the sky; much more and the near side,
    /// seen from above, gives back the depth the rim was made deep to show.
    static let taper = 0.20

    /// How deep the side really is at the rim: `rimDepth` and half the taper.
    ///
    /// **So that the near side still shows `rimDepth`.** Seen from above, a
    /// side drawn in at its foot is a side whose foot has moved up the screen —
    /// by half of `taper` on the two near sides — and at 0.95 m the slab read
    /// a fifth thinner than the bank it replaced (94 points of side against
    /// 119, at three times the garden's size). A tenth of a metre more puts
    /// back exactly what the taper takes, so the near side shows the 0.95 m
    /// `rimDepth` promises and the camera leaves room for. The website's plots
    /// hang this same slab, at the same depth (`Server/assets/js/slab.js`,
    /// since 2 October 2026).
    static let sideDepth = rimDepth + taper / 2

    /// How small a stone in the side may come out on screen, in points, and
    /// still be drawn.
    ///
    /// **Stones only when zoomed in** (Marcus, 2 October 2026, for the app and
    /// the website alike). At three points the stones of the whole plot were a
    /// sprinkle of flecks along the side; a stone is for a close look. So none
    /// is drawn on the whole plot (`side`, which draws them only into a close
    /// drawing) and, close up, none under eight points as it is seen — the
    /// website's rule too (`STONES` in `slab.js`).
    static let smallestStone = 8.0

    /// The slab's side, from the rim down to its lower edge, as pieces to fill
    /// far to near.
    ///
    /// `rim` is the ground's own last row, anticlockwise from above with the
    /// `+x` edge first, at the ground's own heights — so the side's top is the
    /// line the surface ends on, and the surface drawn after it closes it.
    ///
    /// **One mass, lit as one.** Everything that read as melting in the first
    /// cut was noise at the scale of a cell: a ragged floor a column at a time,
    /// a normal jittered cell by cell, bands in a grid that ignored the form.
    /// What is here instead:
    ///
    /// - **The side faces the way the rim does**, smoothed over a stride either
    ///   side so the outline's small wobbles do not stripe it, and a little
    ///   downward as it leans in toward the lower edge. Lit by that and nothing
    ///   else, a stretch turned to the sun or the moon is bright as a whole and
    ///   one turned away is dark as a whole, which is what makes it a solid
    ///   thing.
    /// - **The lower edge is one line round the slab**: the outline drawn in by
    ///   `taper`, undulating gently at the scale of a pace and a half, slower
    ///   than the rim's own wander — and never a column at a time.
    /// - **The strata are bands that follow the slab**: humus a hand deep under
    ///   the surface, rock coming up from the lower edge, each boundary a slow
    ///   wander along the side, and a few stones sitting in the rock.
    ///
    /// Only what faces the viewer is drawn, because depth runs on `x + z` and the
    /// rest is behind the plot's own surface; and with `within`, only the stretch
    /// of it that reaches into that part of the screen, which is what a close
    /// drawing of a corner of the plot asks for. `magnification` is how many
    /// times larger than `view` that close drawing is drawn to be seen — its
    /// sharpness — which is what says how big a stone comes out (`stones`).
    static func side(rim: [SIMD3<Double>], view: Isometric, light: Light,
                     within: CGRect? = nil, magnification: Double = 1) -> [SidePiece] {
        let count = rim.count
        guard count > 8 else { return [] }

        // Round the rim in metres, and the whole way round.
        var along = [Double](repeating: 0, count: count)
        for v in 1..<count {
            along[v] = along[v - 1] + hypot(rim[v].x - rim[v - 1].x, rim[v].z - rim[v - 1].z)
        }
        let perimeter = along[count - 1] + hypot(rim[0].x - rim[count - 1].x, rim[0].z - rim[count - 1].z)
        guard perimeter > 0 else { return [] }

        // Outward, as the direction of travel turned a quarter clockwise, over
        // eighteen centimetres either side: wide enough that the outline's
        // finest wander does not light the side in stripes, narrow enough that
        // a bay in the rim still turns its own way to the light.
        let span = max(1, Int((0.18 / (perimeter / Double(count))).rounded()))
        let outward: [SIMD2<Double>] = (0..<count).map { v in
            let a = rim[(v - span + count) % count], b = rim[(v + span) % count]
            let travel = SIMD2(b.x - a.x, b.z - a.z)
            let length = simd_length(travel)
            return length > 1e-9 ? SIMD2(travel.y, -travel.x) / length : SIMD2(1, 0)
        }

        // How the side hangs at each place on the rim, in metres down from the
        // ground's edge. The lower edge undulates by about a tenth of the depth
        // over a pace and a half, with a finer wander a third as large. Where
        // the ground dips at the rim — the ravine's mouth — the lower edge
        // sags under it to keep half a metre of side, eased in over a quarter
        // of a metre so the sag is a curve and not a corner. Each boundary
        // wanders on its own.
        struct Hang { let top: Double; let deep: Double; let humus: Double; let rock: Double; let tone: Double }
        let hang: [Hang] = (0..<count).map { v in
            let s = along[v]
            func wander(_ wavelength: Double, _ salt: Int) -> Double {
                roundTheLoop(s, perimeter: perimeter, wavelength: wavelength, salt: salt)
            }
            let top = rim[v].y
            let floor = -sideDepth * (1 + 0.09 * wander(1.7, 1) + 0.03 * wander(0.6, 2))
            let under = top - 0.5, ease = 0.25
            let h = min(max(0.5 + 0.5 * (under - floor) / ease, 0), 1)
            let deep = top - (under + (floor - under) * h - ease * h * (1 - h))
            let humus = min(deep * 0.3, 0.15 + 0.03 * wander(0.9, 3))
            let rock = min(max(deep * 0.58 + 0.07 * wander(1.3, 4), humus + 0.12), deep - 0.12)
            return Hang(top: top, deep: deep, humus: humus, rock: rock, tone: 1 + 0.045 * wander(0.8, 5))
        }

        // Where a place on the side lands: `down` metres under the rim at `v`,
        // drawn in toward the middle by the taper, a little under the rim and
        // more toward the lower edge — steady enough that the side meets its
        // lower edge at an angle, which is what makes the edge a firm one
        // rather than a cushion's.
        func inset(_ f: Double) -> Double { taper * (0.55 * f + 0.45 * f * f) }
        func lean(_ f: Double, deep: Double) -> Double { taper / deep * (0.55 + 0.9 * f) }
        func world(_ v: Int, _ down: Double) -> SIMD3<Double> {
            let top = rim[v], h = hang[v]
            let f = min(max(down / h.deep, 0), 1)
            let radius = hypot(top.x, top.z)
            let k = radius > 1e-9 ? max(0, 1 - inset(f) / radius) : 1
            return SIMD3(top.x * k, h.top - f * h.deep, top.z * k)
        }
        func point(_ v: Int, _ down: Double) -> CGPoint {
            let p = world(v, down)
            return view.point(x: p.x, y: p.y, z: p.z)
        }

        // Rows: the bands' own edges, and a row every three points or so between
        // them, so that neither the side's turn nor the grading inside a band
        // comes out as stripes — but no more than about two dozen down the
        // whole side, which is already finer than either changes, and is what
        // keeps a drawing three times closer from costing three times as much.
        // A slab a few points tall gets a row a band.
        let rowHeight = max(3, view.pointsPerMetre * sideDepth / 24)
        func rowsFor(_ metres: Double, least: Int) -> Int {
            max(least, Int((metres * view.pointsPerMetre / rowHeight).rounded(.up)))
        }
        let rows = (humus: rowsFor(0.15, least: 1), earth: rowsFor(0.46, least: 1),
                    rock: rowsFor(0.44, least: 2))
        func levels(_ h: Hang) -> [Double] {
            var out: [Double] = []
            for r in 0..<rows.humus { out.append(h.humus * Double(r) / Double(rows.humus)) }
            for r in 0..<rows.earth { out.append(h.humus + (h.rock - h.humus) * Double(r) / Double(rows.earth)) }
            for r in 0...rows.rock { out.append(h.rock + (h.deep - h.rock) * Double(r) / Double(rows.rock)) }
            return out
        }
        let level = hang.map(levels)

        // The light a stretch of side gets, from the way it faces at a depth.
        func normal(_ v: Int, _ w: Int, down f: Double) -> SIMD3<Double> {
            let out = simd_normalize(outward[v] + outward[w])
            let middle = SIMD2(rim[v].x + rim[w].x, rim[v].z + rim[w].z)
            let inward = simd_length(middle) > 1e-9 ? max(0, simd_dot(simd_normalize(middle), out)) : 0
            let deep = (hang[v].deep + hang[w].deep) / 2
            return simd_normalize(SIMD3(out.x, -lean(f, deep: deep) * inward, out.y))
        }

        // A column a step of the rim, in the rim's own order. A step turned a
        // little away is kept: near the diamond's side corners it is what
        // closes the silhouette, and anything it covers wrongly is painted over
        // by the nearer step after it.
        var columns: [(v: Int, depth: Double)] = []
        for v in 0..<count {
            let w = (v + 1) % count
            let out = outward[v] + outward[w]
            let (a, b) = view.facing(x: out.x, z: out.y)
            guard a + b > -0.1 * simd_length(out) else { continue }
            if let within {
                let top = point(v, 0), bottom = point(v, hang[v].deep)
                let reach = CGRect(x: min(top.x, bottom.x), y: min(top.y, bottom.y),
                                   width: abs(top.x - bottom.x), height: abs(top.y - bottom.y))
                guard reach.insetBy(dx: -4, dy: -4).intersects(within) else { continue }
            }
            columns.append((v, view.depth(Spot(x: (rim[v].x + rim[w].x) / 2, z: (rim[v].z + rim[w].z) / 2))))
        }

        // Faint layers inside each band, as sediment lies: a slow wander along
        // the side and a short one down it, so a band has streaks in it that
        // thicken and thin. Worked out from where on the side a place is, in
        // metres, and not from the rows, so the close drawing and the far one
        // show the same streaks; and eased into itself over the last metre of
        // the loop, so there is no seam where the rim starts.
        func streaks(_ s: Double, _ down: Double) -> Double {
            func at(_ s: Double) -> Double {
                (Organic.noise(s / 1.2, down / 0.08, seed: 0x51DE)
                    + 0.5 * Organic.noise(s / 0.45, down / 0.035, seed: 0x51DF)) / 1.5
            }
            guard s > perimeter - 1 else { return at(s) }
            let t = s - (perimeter - 1)
            return at(s) + (at(s - perimeter) - at(s)) * t * t * (3 - 2 * t)
        }

        // Every column's colour in every row.
        let bands = level.first.map { $0.count - 1 } ?? 0
        let colours: [[SIMD3<Double>]] = columns.map { column in
            let v = column.v, w = (v + 1) % count
            let tone = (hang[v].tone + hang[w].tone) / 2
            let humusTo = (hang[v].humus + hang[w].humus) / 2
            let rockFrom = (hang[v].rock + hang[w].rock) / 2
            let deep = (hang[v].deep + hang[w].deep) / 2
            let s = (along[v] + (w == 0 ? perimeter : along[w])) / 2
            return (0..<bands).map { r in
                let middle = (level[v][r] + level[v][r + 1] + level[w][r] + level[w][r + 1]) / 4
                let layered = 1 + (middle < humusTo ? 0.025 : 0.05) * streaks(s, middle)
                let base = sideColour(down: middle, humusTo: humusTo, rockFrom: rockFrom, bottom: deep)
                    * tone * layered
                return shaded(base: base, normal: normal(v, w, down: middle / deep), light: light)
            }
        }

        // **A run of columns the screen cannot tell apart is drawn as one.**
        // Lit as planes, neighbouring steps of the rim come out within a shade
        // of each other along most of the side, and four thousand quads a
        // drawing was most of what the side cost. So in each row, steps that
        // follow one another round the rim and stay within one 8-bit level of
        // where the run began are one piece, coloured as their mean: the same
        // picture to the eye, in about a fifth of the pieces.
        // Runs are painted far to near by their middles; a run is short, and
        // where two overlap — a bay in the rim, a corner of the diamond — the
        // light is turning fast enough that it is a column or two long.
        let close = 1.0 / 255
        var screen = [[CGPoint]?](repeating: nil, count: count)
        func spot(_ v: Int, _ r: Int) -> CGPoint {
            if let held = screen[v] { return held[r] }
            let row = level[v].map { point(v, $0) }
            screen[v] = row
            return row[r]
        }
        var runs: [(depth: Double, piece: SidePiece)] = []
        runs.reserveCapacity(columns.count * bands / 3 + 64)
        for r in 0..<bands {
            var first = 0
            while first < columns.count {
                var last = first, sum = colours[first][r], depth = columns[first].depth
                while last + 1 < columns.count, columns[last + 1].v == columns[last].v + 1,
                      simd_reduce_max(simd_abs(colours[last + 1][r] - colours[first][r])) < close {
                    last += 1
                    sum += colours[last][r]
                    depth += columns[last].depth
                }
                let steps = columns[first].v...(columns[last].v + 1)
                var points = steps.map { spot($0 % count, r) }
                points += steps.reversed().map { spot($0 % count, r + 1) }
                let n = Double(last - first + 1)
                runs.append((depth / n, SidePiece(points: points, colour: sum / n)))
                first = last + 1
            }
        }
        runs.sort { $0.depth < $1.depth }
        var pieces = runs.map(\.piece)

        // **Stones only when zoomed in** (Marcus, 2 October 2026): a close
        // drawing is the only drawing made once the plot is zoomed into, so the
        // whole plot has none and a corner seen close has them.
        if within != nil {
            pieces += stones(rim: rim, along: along, perimeter: perimeter, outward: outward, hang: hang.map {
                (deep: $0.deep, humus: $0.humus, rock: $0.rock)
            }, view: view, magnification: magnification, light: light, world: world, normal: normal)
        }
        return pieces
    }

    /// **A few stones sitting in the rock**, and the odd one up in the earth.
    ///
    /// A little under one chance in two every half metre of rim, each a lump
    /// wider than it is tall with nine corners at uneven distances, so no two
    /// are the same and none is an egg. Each is drawn as the shadow it sits in,
    /// showing only under it, its body, and an upper face lit as turned a
    /// little toward the sky. **Close in tone to the rock round it**: smooth
    /// round stones a shade lighter than the rock read as a row of rivets.
    /// Only where the side faces the viewer squarely, so none is ever cut by
    /// the silhouette, and none smaller on screen than `smallestStone`.
    private static func stones(
        rim: [SIMD3<Double>],
        along: [Double],
        perimeter: Double,
        outward: [SIMD2<Double>],
        hang: [(deep: Double, humus: Double, rock: Double)],
        view: Isometric,
        magnification: Double,
        light: Light,
        world: (Int, Double) -> SIMD3<Double>,
        normal: (Int, Int, Double) -> SIMD3<Double>
    ) -> [SidePiece] {
        let count = rim.count
        let slot = 0.5
        var pieces: [SidePiece] = []

        // The place `s` metres round the rim and `down` under it, between the
        // two steps either side of it.
        func place(_ s: Double, _ down: Double) -> CGPoint {
            let wrapped = (s.truncatingRemainder(dividingBy: perimeter) + perimeter)
                .truncatingRemainder(dividingBy: perimeter)
            var low = 0, high = count - 1
            while low < high {
                let mid = (low + high + 1) / 2
                if along[mid] <= wrapped { low = mid } else { high = mid - 1 }
            }
            let v = low, w = (low + 1) % count
            let span = (w == 0 ? perimeter : along[w]) - along[v]
            let t = span > 1e-9 ? (wrapped - along[v]) / span : 0
            let p = world(v, down) + (world(w, down) - world(v, down)) * t
            return view.point(x: p.x, y: p.y, z: p.z)
        }

        for k in 0..<Int(perimeter / slot) {
            guard grain(k, 7, 51) < 0.45 else { continue }
            let s = (Double(k) + 0.2 + 0.6 * grain(k, 7, 52)) * slot
            guard let v = along.lastIndex(where: { $0 <= s }) else { continue }
            let w = (v + 1) % count

            let (a, b) = view.facing(x: outward[v].x, z: outward[v].y)
            guard (a + b) / 2.0.squareRoot() > 0.45 else { continue }

            let h = hang[v]
            let inRock = grain(k, 7, 53) < 0.75
            let width = inRock ? 0.06 + 0.07 * grain(k, 7, 55) : 0.04 + 0.03 * grain(k, 7, 55)
            let tall = width * (0.55 + 0.25 * grain(k, 7, 56))
            guard width * view.pointsPerMetre * magnification >= smallestStone else { continue }
            let centre = inRock
                ? h.rock + (h.deep - h.rock) * (0.25 + 0.45 * grain(k, 7, 54))
                : h.humus + (h.rock - h.humus) * (0.35 + 0.4 * grain(k, 7, 54))
            guard centre - tall > h.humus + 0.02, centre + tall < h.deep - 0.05 else { continue }

            func outline(scale: Double, lift: Double) -> [CGPoint] {
                (0..<9).map { i in
                    let angle = (Double(i) + 0.5 * (grain(k, i, 57) - 0.5)) / 9 * 2 * .pi
                    let r = scale * (0.74 + 0.36 * grain(k, i, 58))
                    return place(s + width * r * cos(angle), centre - lift * tall + tall * r * sin(angle))
                }
            }

            let f = centre / h.deep
            let wall = normal(v, w, f)
            let around = sideColour(down: centre, humusTo: h.humus, rockFrom: h.rock, bottom: h.deep)
            let colour = (rock + (stone - rock) * 0.2) * sideLift * (0.96 + 0.08 * grain(k, 7, 59))
            let up = simd_normalize(wall + SIMD3(0, 0.22, 0))
            pieces.append(SidePiece(points: outline(scale: 1.03, lift: -0.3),
                                    colour: shaded(base: around * 0.78, normal: wall, light: light)))
            pieces.append(SidePiece(points: outline(scale: 1, lift: 0),
                                    colour: shaded(base: colour, normal: wall, light: light)))
            pieces.append(SidePiece(points: outline(scale: 0.62, lift: 0.32),
                                    colour: shaded(base: colour, normal: up, light: light)))
        }
        return pieces
    }
}
