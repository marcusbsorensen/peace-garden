import CoreGraphics
import simd
import UIKit

/// The eight grounds a bed can stand on, as height and colour per cell.
///
/// **A world ships as what it is, not as a picture of itself.** Eight worlds
/// times every hour of the day is a combinatorial blow-up, and snapping to the
/// nearest of eight renders makes the sun jump — so the light is applied where
/// the ground is drawn rather than baked into it. All eight come to 276 KB that
/// way, which is less than one pre-rendered tile would be, because a rendered
/// tile is mostly shading and shading is exactly what is being thrown away.
///
/// Two textures, 128 wide by 128 × 8 tall, one 128-square block per world:
/// height packed 16-bit big-endian into the red and green bytes, and albedo as
/// plain RGB. Both come from the mockup, so a world drawn here is the world that
/// was looked at there.
/// Immutable once loaded, and read from whichever thread is drawing — a terrain
/// is sixteen thousand quads and must not be built on the main actor.
final class GardenWorlds: Sendable {
    static let shared = GardenWorlds()

    /// Cells across one world.
    static let cells = 128
    /// The plot the worlds were drawn for. Relief is scaled with the plot, so a
    /// garden that has grown past this keeps the same hills rather than the same
    /// gradients.
    static let drawnForSide = 5.2
    /// What the two height bytes span, in metres.
    static let heightFloor = -2.0
    static let heightCeiling = 2.0

    /// How many grounds there are to choose from.
    let count: Int

    /// Height in metres, `count * cells * cells`, world-major.
    private let heights: [Float]
    /// Albedo, three bytes a cell, laid out the same way.
    private let albedo: [UInt8]

    private init() {
        let height = Self.pixels(named: "worlds-height")
        let colour = Self.pixels(named: "worlds-albedo")

        guard let height, let colour,
              height.width == Self.cells, colour.width == Self.cells,
              height.height % Self.cells == 0,
              height.height == colour.height else {
            count = 0
            heights = []
            albedo = []
            return
        }

        let worlds = height.height / Self.cells
        count = worlds

        var metres = [Float](repeating: 0, count: worlds * Self.cells * Self.cells)
        var colours = [UInt8](repeating: 0, count: worlds * Self.cells * Self.cells * 3)
        let span = Self.heightCeiling - Self.heightFloor

        for index in 0..<(worlds * Self.cells * Self.cells) {
            let source = index * 4
            let packed = (Int(height.bytes[source]) << 8) | Int(height.bytes[source + 1])
            metres[index] = Float(Self.heightFloor + Double(packed) / 65_535 * span)
            colours[index * 3] = colour.bytes[source]
            colours[index * 3 + 1] = colour.bytes[source + 1]
            colours[index * 3 + 2] = colour.bytes[source + 2]
        }

        heights = metres
        albedo = colours
    }

    /// **Read without a colour space, never redrawn into one.**
    ///
    /// The height is a sixteen-bit number hidden in two colour channels, and
    /// every step of ordinary image handling — a colour-managed decode, a draw
    /// into device RGB — is entitled to change a colour by a value or two while
    /// keeping it the same colour. A value or two here is a centimetre of hill
    /// in the wrong place, which nothing would ever look wrong enough to catch.
    /// `PlotTests` holds each world's relief against what the exporter measured.
    private static func pixels(named name: String) -> (bytes: [UInt8], width: Int, height: Int)? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }

        let width = image.width, height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &bytes,
            width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (bytes, width, height)
    }

    var isLoaded: Bool { count > 0 }

    /// A world's index, brought inside the range whatever is asked for. A bed
    /// carrying a world this build has never heard of falls to the first one
    /// rather than to nothing.
    func resolve(_ world: Int?) -> Int {
        guard count > 0 else { return 0 }
        guard let world, world >= 0, world < count else { return 0 }
        return world
    }

    // MARK: Reading the ground

    /// The height of the ground at a place on the plot, in metres.
    ///
    /// Bilinear, because a plant dragged across the plot has to rise and fall
    /// smoothly rather than in steps of four centimetres. The relief is scaled
    /// with the plot: a garden of fifty meetings gets a bigger hill rather than
    /// the same hill with more ground around it.
    func height(world: Int, x: Double, z: Double, plotSide: Double) -> Double {
        guard isLoaded else { return 0 }
        let scale = plotSide / Self.drawnForSide
        let (i, j, fi, fj) = place(x: x, z: z, plotSide: plotSide)
        let base = world * Self.cells * Self.cells

        func at(_ a: Int, _ b: Int) -> Double {
            Double(heights[base + b * Self.cells + a])
        }

        let top = at(i, j) * (1 - fi) + at(i + 1, j) * fi
        let bottom = at(i, j + 1) * (1 - fi) + at(i + 1, j + 1) * fi
        return (top * (1 - fj) + bottom * fj) * scale
    }

    /// What the ground is made of over the patch a quad covers, before any light
    /// falls on it.
    ///
    /// **Averaged over the patch, not read at its middle.** A world's colour is
    /// stippled — the ravine's strata and the scree are drawn as single dark
    /// cells among lighter ones, which is what gives them their grain. Reading
    /// one cell per quad picks a dot or a gap, and at a mesh coarser than the
    /// atlas that came out as a lattice of black diamonds down the gorge, which
    /// looked like holes in the ground rather than like a sampling fault. Where
    /// the mesh matches the atlas the patch is one cell and this costs nothing.
    func colour(world: Int, x: Double, z: Double, plotSide: Double,
                covering: Double = 0) -> SIMD3<Double> {
        guard isLoaded else { return GardenGround.turf }
        let (i, j, _, _) = place(x: x, z: z, plotSide: plotSide)
        let base = world * Self.cells * Self.cells

        let reach = max(0, Int((covering / plotSide * Double(Self.cells) / 2).rounded(.down)))
        guard reach > 0 else {
            let at = (base + j * Self.cells + i) * 3
            return SIMD3(Double(albedo[at]) / 255,
                         Double(albedo[at + 1]) / 255,
                         Double(albedo[at + 2]) / 255)
        }

        var sum = SIMD3<Double>()
        var taken = 0.0
        for dj in -reach...reach {
            let row = min(max(j + dj, 0), Self.cells - 1)
            for di in -reach...reach {
                let column = min(max(i + di, 0), Self.cells - 1)
                let at = (base + row * Self.cells + column) * 3
                sum += SIMD3(Double(albedo[at]), Double(albedo[at + 1]), Double(albedo[at + 2]))
                taken += 1
            }
        }
        return sum / (taken * 255)
    }

    /// The deepest and highest this world goes on a plot of this size — what the
    /// camera has to leave room for above the far corner and below the near one.
    func relief(world: Int, plotSide: Double) -> (low: Double, high: Double) {
        guard isLoaded else { return (0, 0) }
        let scale = plotSide / Self.drawnForSide
        let base = world * Self.cells * Self.cells
        var low = Float.greatestFiniteMagnitude, high = -Float.greatestFiniteMagnitude
        for index in base..<(base + Self.cells * Self.cells) {
            low = min(low, heights[index])
            high = max(high, heights[index])
        }
        return (Double(low) * scale, Double(high) * scale)
    }

    /// A place on the plot as a cell and the fraction into it, clamped so the
    /// rim itself is a valid place to stand.
    private func place(x: Double, z: Double, plotSide: Double)
        -> (i: Int, j: Int, fi: Double, fj: Double) {
        let half = plotSide / 2
        let last = Double(Self.cells - 1)
        let u = min(max((x + half) / plotSide, 0), 1) * last
        let v = min(max((z + half) / plotSide, 0), 1) * last
        let i = min(Int(u), Self.cells - 2)
        let j = min(Int(v), Self.cells - 2)
        return (i, j, u - Double(i), v - Double(j))
    }
}
