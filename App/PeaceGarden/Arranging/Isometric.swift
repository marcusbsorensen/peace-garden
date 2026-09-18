import CoreGraphics
import Foundation
import SeedCore

/// The one projection the garden is drawn in.
///
/// A parallel projection, so there is no perspective divide and one metre is
/// the same number of points everywhere on the plot. Three things follow, and
/// all three are subtractions rather than features — `docs/ARRANGING.md`
/// §*Isometric is a simplification, not only a look*:
///
/// - A plant is the same size wherever it stands, so a sprite is rendered once
///   and placed, never scaled against where it landed.
/// - Nothing leans. Up is up everywhere, so a plant standing on the plot needs
///   no rotation to keep it upright.
/// - Depth order is `x + z`. Not a sort by distance from a camera, and not a
///   depth buffer.
///
/// True isometric, meaning the camera sits along `(1, 1, 1)` and all three axes
/// foreshorten equally. That is what lets `pointsPerMetre` be one number: a
/// metre up the stem and a metre across the ground draw the same length. The
/// mockup's numbers are the same two lines, so a spot placed there lands in the
/// same place here.
struct Isometric: Equatable {
    /// How many points one metre draws as, along any of the three axes.
    var pointsPerMetre: Double

    /// Where the middle of the plot's surface — `(0, 0, 0)` — lands on screen.
    var centre: CGPoint

    /// Quarter-turns of the plot's own axes, as the person has turned it.
    ///
    /// **Ninety-degree steps, because isometric has four natural views** and
    /// stepping between them keeps the ground's own axes aligned to the screen,
    /// which is the property that makes an isometric plot legible at all. It
    /// also answers the ravine, which has a side you cannot see from any one
    /// view.
    ///
    /// The rotation is the same one `GardenSprites` turns a plant and its light
    /// by, and `PlotTests` holds the two to each other: a plant rendered for a
    /// turn has to be the plant you would see standing on a plot at that turn.
    var turn: Int = 0

    private var quarter: Int { ((turn % 4) + 4) % 4 }

    /// The plot's axes as they face the screen at this turn. The same matrix as
    /// a rotation about `+y` by `turn × 90°`.
    func facing(x: Double, z: Double) -> (x: Double, z: Double) {
        switch quarter {
        case 1: return (z, -x)
        case 2: return (-x, -z)
        case 3: return (-z, x)
        default: return (x, z)
        }
    }

    /// And back again.
    func unfacing(x: Double, z: Double) -> (x: Double, z: Double) {
        switch quarter {
        case 1: return (-z, x)
        case 2: return (-x, -z)
        case 3: return (z, -x)
        default: return (x, z)
        }
    }

    /// The ground axes leave the origin thirty degrees either side of the
    /// horizontal, which is what stands the plot's corners at the compass
    /// points of a diamond and keeps its own axes legible.
    static let cosThirty = 0.866_025_403_784_438_6
    static let sinThirty = 0.5

    /// A point in the garden, in metres: `x` and `z` across the ground from the
    /// middle of the plot, `y` up from it.
    ///
    /// Screen `y` grows downward, so height is subtracted and depth is added: a
    /// plant nearer the viewer stands lower on the screen, which is also why
    /// `depth` sorts on the same sum.
    func point(x: Double, y: Double = 0, z: Double) -> CGPoint {
        let (a, b) = facing(x: x, z: z)
        return CGPoint(
            x: centre.x + (a - b) * Self.cosThirty * pointsPerMetre,
            y: centre.y + ((a + b) * Self.sinThirty - y) * pointsPerMetre
        )
    }

    func point(_ spot: Spot, y: Double = 0) -> CGPoint {
        point(x: spot.x, y: y, z: spot.z)
    }

    /// Where on the ground a screen point is, at `y = 0`.
    ///
    /// The forward projection is two lines and this is the same two lines
    /// backward. Over terrain it has to run twice — once at ground zero, once
    /// with that place's own height subtracted — and there is no terrain yet,
    /// so the flat answer is exact rather than nearly right.
    func ground(at point: CGPoint) -> Spot {
        let across = (point.x - centre.x) / (Self.cosThirty * pointsPerMetre)
        let down = (point.y - centre.y) / (Self.sinThirty * pointsPerMetre)
        let (x, z) = unfacing(x: (down + across) / 2, z: (down - across) / 2)
        return Spot(x: x, z: z)
    }

    /// Where on the ground a finger is, when the ground is not flat.
    ///
    /// **Finding the place needs the height, and the height needs the place.**
    /// A foot standing `h` metres up is drawn `h` metres higher on the screen, so
    /// every height has its own answer: the ground under the finger at height
    /// `h` is the flat answer for a point `h` metres lower down the screen.
    ///
    /// `docs/ARRANGING.md` said the inverse runs twice and that twice is enough.
    /// **Twice is not enough on a mountain, and no number of times is.** Measured
    /// on the alpine world, it dropped a plant eight centimetres from the finger,
    /// and iterating further did not move it — because on a steep peak there are
    /// two places on the ground under one point of the screen, the face you can
    /// see and one behind it, and a fixed-point search is as happy with either.
    ///
    /// So this marches the finger's own sight line in from the viewer's side —
    /// from above the highest the ground goes, downward, which on this screen is
    /// from near to far — and takes the first place it meets the ground. That is
    /// the place you can see, which is the only place a finger can be on.
    func ground(at point: CGPoint, height: (Spot) -> Double,
                between low: Double, and high: Double) -> Spot {
        func under(_ y: Double) -> Spot {
            ground(at: CGPoint(x: point.x, y: point.y + y * pointsPerMetre))
        }

        let top = high + 0.05, bottom = low - 0.05
        let steps = 240
        var previous = top

        for step in 1...steps {
            let y = top - (top - bottom) * Double(step) / Double(steps)
            guard height(under(y)) >= y else {
                previous = y
                continue
            }

            // Somewhere between the last height above the ground and this one
            // below it; a few halvings is finer than any finger.
            var above = previous, below = y
            for _ in 0..<12 {
                let middle = (above + below) / 2
                if height(under(middle)) >= middle { below = middle } else { above = middle }
            }
            return under((above + below) / 2)
        }
        return ground(at: point)
    }

    /// Whether something let go of here has been carried off the plot, rather
    /// than dropped at its edge.
    ///
    /// **Off the edge is how a thing is given up**, and the answer needs no word
    /// on the screen: a light carried off is gone, and a plant carried off goes
    /// home to where its arrangement puts it. A little way over the rim is still
    /// the rim — somebody aiming for the edge overshoots — so only a clear
    /// fifteen centimetres beyond it counts as leaving.
    static func isOff(_ spot: Spot, plotSide: Double) -> Bool {
        let beyond = plotSide / 2 + 0.15
        return abs(spot.x) > beyond || abs(spot.z) > beyond
    }

    /// Far to near. Everything on the plot is drawn in this order and nothing
    /// else decides what covers what. It turns with the plot, because *near* is
    /// a fact about the screen rather than about the ground.
    func depth(_ spot: Spot) -> Double {
        let (a, b) = facing(x: spot.x, z: spot.z)
        return a + b
    }

    /// A circle of `radius` metres lying on the ground, as the ellipse it draws.
    ///
    /// Returned as the two semi-axes in points. The ratio between them is fixed
    /// by the projection — `cos 30 / sin 30`, a little over seven to four — so
    /// anything lying flat on the plot is drawn with this and never with a
    /// guessed squash.
    func ellipse(radius: Double) -> CGSize {
        let diagonal = radius * 2.0.squareRoot() * pointsPerMetre
        return CGSize(width: diagonal * Self.cosThirty, height: diagonal * Self.sinThirty)
    }

    /// The scale that fits a plot of `plotSide` metres into `size`, with room
    /// above it for the tallest plant and below it for the soil's own cut.
    ///
    /// Fitted on both axes and the smaller taken, because a phone is tall and an
    /// iPad in Split View is not, and a plot that overflows sideways loses the
    /// corners that say what shape it is.
    static func fitting(
        plotSide: Double,
        in size: CGSize,
        headroom: Double,
        soilDepth: Double,
        margin: Double = 8
    ) -> Isometric {
        let width = max(size.width - margin * 2, 1)
        let height = max(size.height - margin * 2, 1)

        // The plot draws as a diamond. Corner to corner it spans a whole side's
        // worth of *both* ground axes in each direction, so `x - z` runs over
        // `2 * plotSide` across and `x + z` over `2 * plotSide` down — which is
        // `plotSide` on screen once `sin 30` has halved it.
        //
        // **Taking that vertical span as `plotSide * sin 30` is the fault this
        // arithmetic had**, and it fits on a phone, where the width binds and
        // the height is never asked. It shows up only on a landscape iPad: the
        // far corner's plant is a hundred points off the top of the screen and
        // the cut hangs off the bottom.
        let across = plotSide * 2 * cosThirty
        let down = plotSide + headroom + soilDepth
        let scale = min(width / across, height / down)

        // The plot's middle sits off the centre of the view by half the
        // difference between what stands above it and what hangs below it, so
        // the whole drawing is centred rather than the ground being centred
        // with the plants off the top of the screen.
        let above = plotSide / 2 + headroom
        let below = plotSide / 2 + soilDepth
        let offset = (above - below) / 2 * scale

        return Isometric(
            pointsPerMetre: scale,
            centre: CGPoint(x: size.width / 2, y: size.height / 2 + offset)
        )
    }
}
