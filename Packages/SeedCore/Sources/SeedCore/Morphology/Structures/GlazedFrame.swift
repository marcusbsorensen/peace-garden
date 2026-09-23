#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// A cold frame: a low box of boards, higher at the back, with two glazed
/// lights over it propped open at the front. One of `Organic`'s structures;
/// the noise it wanders with is in `Organic`, and the boards are the bench's.
///
/// **In three pieces, because it is three materials.** The box and the lights'
/// bars are timber, and the page lights them as the bench is lit; the glass is
/// drawn last and seen through, which no other structure in the garden asks
/// of the page. A single mesh could not be drawn both ways.
///
/// All three stand on `y = 0`, centred on the origin, the frame's length along
/// `x` and its back toward `z−` — the way `ColdFrame.Frame` stands every frame
/// in the plot, so the rank that will grow tallest is under the high side.
///
/// **Unnamed**, as every structure is. A named structure is forty-two
/// translations.
extension Organic {

    /// How thick a frame's boards are, and a light's bars.
    static let frameBoard = 0.045
    static let lightBar = 0.04
    static let lightBarDeep = 0.035

    /// Where the underside of a propped light is, `z` metres from the middle
    /// of a frame `depth` deep: resting on the back wall and lifted at the
    /// front by `propped`. The same line `ColdFrame.glass(atDepth:)` measures
    /// the plants against.
    static func lightUnderside(atDepth z: Double, depth: Double,
                               back: Double, front: Double, propped: Double) -> Double {
        let t = min(1, max(0, (z + depth / 2) / depth))
        return back + (front + propped - back) * t
    }

    /// The box: four boards on edge, the back one `back` high and the front
    /// one `front`, and the two ends cut to the slope between them.
    ///
    /// **Boards, not a moulded tray.** A frame is knocked together out of
    /// planks, and the bench's plank — a twentieth of a hedge's wander, so an
    /// edge is soft rather than wavy — is what makes a thing read as made
    /// rather than grown. The ends are the same plank stood on its edge and cut
    /// down to the slope, so the box has no ruled line along its top either.
    public static func coldFrame(length: Double = ColdFrame.frameLength, depth: Double = ColdFrame.frameDepth,
                                 back: Double = ColdFrame.backWall, front: Double = ColdFrame.frontWall,
                                 seed: UInt64) -> StructureMesh {
        var mesh = StructureMesh()
        let board = frameBoard

        // Back and front, each a plank turned to run along `x`.
        for (i, (height, z)) in [(back, -depth / 2 + board / 2),
                                 (front, depth / 2 - board / 2)].enumerated() {
            append(plank(length: length, width: board, thickness: height, lift: 0,
                         seed: mix64(seed &+ UInt64(i) &+ 1)),
                   to: &mesh, turned: true, at: SIMD3<Float>(0, 0, Float(z)))
        }

        // The two ends, running along `z` between the back and the front, and
        // cut to the slope: drawn a metre tall and brought down to the line
        // between the two walls' tops, which keeps the plank's own wander.
        for (i, side) in [-1.0, 1.0].enumerated() {
            var end = plank(length: depth - 2 * board, width: board, thickness: 1, lift: 0,
                            seed: mix64(seed &+ UInt64(i) &+ 5))
            for v in end.positions.indices {
                let z = Double(end.positions[v].z)
                let t = (z + depth / 2) / depth
                end.positions[v].y *= Float(back + (front - back) * t)
            }
            append(end, to: &mesh, turned: false,
                   at: SIMD3<Float>(Float(side * (length / 2 - board / 2)), 0, 0))
        }
        mesh.computeNormals()
        return mesh
    }

    /// The two lights that close the frame, as their bars: a stile down each
    /// side, a rail at the top and the bottom, and a glazing bar down the
    /// middle of each — and the two blocks the lights are propped on.
    ///
    /// **Propped, because this is how a frame is by day.** A light rests on the
    /// back wall and its front is lifted onto a block, a little at first and
    /// more each day as the plants harden off. The blocks are there to say why
    /// there is a gap under the front of the glass; a lid hovering over a
    /// frame reads as a drawing error, not as air being let in.
    ///
    /// Built flat and then sheared onto the slope rather than turned onto it.
    /// The slope is a few degrees, so the two are indistinguishable, and a
    /// shear keeps every bar standing upright — the way a light's bars stand
    /// when it is set down on a frame.
    public static func frameLights(length: Double = ColdFrame.frameLength, depth: Double = ColdFrame.frameDepth,
                                   back: Double = ColdFrame.backWall, front: Double = ColdFrame.frontWall,
                                   propped: Double = ColdFrame.propped, seed: UInt64) -> StructureMesh {
        var flat = StructureMesh()
        let bar = lightBar, deep = lightBarDeep
        let light = length / 2
        var n: UInt64 = 20
        let next = { () -> UInt64 in n += 1; return mix64(seed &+ n) }

        for l in 0..<2 {
            let x0 = -length / 2 + Double(l) * light
            // Stiles and the glazing bar, down the slope.
            for x in [x0 + bar / 2, x0 + light / 2, x0 + light - bar / 2] {
                append(plank(length: depth, width: bar, thickness: deep, lift: 0, seed: next()),
                       to: &flat, turned: false, at: SIMD3<Float>(Float(x), 0, 0))
            }
            // The top and bottom rails, across it, between the stiles.
            for z in [-depth / 2 + bar / 2, depth / 2 - bar / 2] {
                append(plank(length: light - 2 * bar, width: bar, thickness: deep, lift: 0, seed: next()),
                       to: &flat, turned: true, at: SIMD3<Float>(Float(x0 + light / 2), 0, Float(z)))
            }
        }
        for v in flat.positions.indices {
            let z = Double(flat.positions[v].z)
            flat.positions[v].y += Float(lightUnderside(atDepth: z, depth: depth, back: back,
                                                        front: front, propped: propped))
        }

        // A block under the front of each light, standing on the front wall.
        if propped > 0.005 {
            for l in 0..<2 {
                let x = -length / 2 + (Double(l) + 0.5) * light
                append(plank(length: 0.07, width: 0.09, thickness: propped, lift: front, seed: next()),
                       to: &flat, turned: false,
                       at: SIMD3<Float>(Float(x), 0, Float(depth / 2 - frameBoard / 2)))
            }
        }
        flat.computeNormals()
        return flat
    }

    /// The glass in the two lights: each light glazed in two bays either side
    /// of its glazing bar, each bay in three panes lapped down the slope.
    ///
    /// **Lapped, because that is how a frame light is glazed** — each pane
    /// laid over the top of the one below it so rain runs off rather than in —
    /// and because the laps are what make the glass visible. Seen through, a
    /// clear pane is nothing; the lap is a line where there are two thicknesses
    /// of it, which the page's glass draws as a line of more light.
    ///
    /// **Not quite flat.** Each pane is a small sheet with a ripple a couple of
    /// millimetres deep in it, the way old horticultural glass is, so its
    /// surface turns the light a little across its width and catches it as a
    /// glint rather than as one flat tint.
    public static func frameGlass(length: Double = ColdFrame.frameLength, depth: Double = ColdFrame.frameDepth,
                                  back: Double = ColdFrame.backWall, front: Double = ColdFrame.frontWall,
                                  propped: Double = ColdFrame.propped, seed: UInt64) -> StructureMesh {
        var mesh = StructureMesh()
        let bar = lightBar
        let light = length / 2
        let tuck = 0.01                         // how far a pane runs under a bar
        let panes = 3, lap = 0.025
        let from = -depth / 2 + bar - tuck, to = depth / 2 - bar + tuck
        let paneDepth = (to - from + Double(panes - 1) * lap) / Double(panes)
        let columns = 6, rows = 5

        for l in 0..<2 {
            let x0 = -length / 2 + Double(l) * light
            let bays = [(x0 + bar - tuck, x0 + light / 2 - bar / 2 + tuck),
                        (x0 + light / 2 + bar / 2 - tuck, x0 + light - bar + tuck)]
            for (b, bay) in bays.enumerated() {
                for p in 0..<panes {
                    // The upper pane lies over the lower one, so each pane down
                    // the slope sits a glass's thickness under the one above.
                    let z0 = from + Double(p) * (paneDepth - lap)
                    let over = 0.003 * Double(panes - 1 - p)
                    let paneSeed = mix64(seed &+ UInt64(l * 16 + b * 4 + p) &+ 101)
                    let base = UInt32(mesh.positions.count)
                    for r in 0...rows {
                        let z = z0 + paneDepth * Double(r) / Double(rows)
                        for c in 0...columns {
                            let x = bay.0 + (bay.1 - bay.0) * Double(c) / Double(columns)
                            let ripple = 0.0018 * wobble(x, z, wavelength: 0.22, seed: paneSeed)
                            let y = lightUnderside(atDepth: z, depth: depth, back: back,
                                                   front: front, propped: propped)
                                + lightBarDeep * 0.5 + over + ripple
                            mesh.positions.append(SIMD3<Float>(Float(x), Float(y), Float(z)))
                        }
                    }
                    let stride = UInt32(columns + 1)
                    for r in 0..<UInt32(rows) {
                        for c in 0..<UInt32(columns) {
                            let i = base + r * stride + c, j = i + stride
                            // Wound so the face looks up, toward the sky.
                            mesh.indices.append(contentsOf: [i, j, i + 1, i + 1, j, j + 1])
                        }
                    }
                }
            }
        }
        mesh.computeNormals()
        return mesh
    }
}
