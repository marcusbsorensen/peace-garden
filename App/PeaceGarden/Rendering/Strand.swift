import SwiftUI
import SeedCore

/// A thread hanging from a plant down to the question waiting at the foot of
/// the screen.
///
/// **What it is for.** A plant somebody has asked about is standing in the
/// garden and the question about it is at the bottom of the screen, and until
/// now nothing joined the two: the notice knew which plant it meant and the
/// person reading it did not. The strand is the joining, and it is drawn rather
/// than written because the plant is already there to be pointed at.
///
/// **It is not a straight line.** Nothing in this garden is — the soil, the
/// hedges, the paths and the shadows are all irregular, and a ruled line would
/// be the one thing on screen that was made by a machine. So it falls the way a
/// thread falls: mostly downward, with a lean in it, and the lean is taken from
/// the plant's own seed so that it is the same every time the screen is drawn
/// and different for every plant.
enum Strand {

    /// How far the thread may wander from the straight way down, in points.
    ///
    /// Small. The job is to be followed with the eye from one end to the other,
    /// and a thread that wanders far enough to be admired is a thread you lose
    /// halfway. Two or three points is enough to stop it being ruled.
    static let wander: Double = 7

    /// A thread from a plant to the notice, leaning by an amount that is this
    /// seed's own.
    ///
    /// Two curves rather than one, because a single quadratic bends one way for
    /// its whole length and reads as an arc drawn on purpose. Bending one way
    /// and then back is what a hanging thing does.
    static func path(from head: CGPoint, to foot: CGPoint, seed: SeedID) -> Path {
        let lean = self.lean(of: seed)
        let drop = foot.y - head.y
        let middle = CGPoint(x: (head.x + foot.x) / 2 + lean, y: head.y + drop * 0.5)

        var path = Path()
        path.move(to: head)
        path.addQuadCurve(
            to: middle,
            control: CGPoint(x: head.x + lean * 1.6, y: head.y + drop * 0.24)
        )
        path.addQuadCurve(
            to: foot,
            control: CGPoint(x: foot.x - lean * 0.9, y: head.y + drop * 0.78)
        )
        return path
    }

    /// The lean, in points, from the seed's own bytes.
    ///
    /// The same two bytes every time, so a plant's thread hangs the same way on
    /// every redraw — a thread that changed as the screen refreshed would be
    /// the only thing in the garden that flickered. Byte 30 and 31 are used by
    /// nothing else; `LongWalk` takes 20 and 21 for its nudge.
    static func lean(of seed: SeedID) -> Double {
        let bytes = [UInt8](seed.bytes)
        guard bytes.count > 31 else { return 0 }
        let coarse = Double(bytes[30]) / 255 - 0.5
        let fine = Double(bytes[31]) / 255 - 0.5
        return (coarse * 2 + fine * 0.4) * wander
    }
}
