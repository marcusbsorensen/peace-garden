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
        CGPoint(
            x: centre.x + (x - z) * Self.cosThirty * pointsPerMetre,
            y: centre.y + ((x + z) * Self.sinThirty - y) * pointsPerMetre
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
        return Spot(x: (down + across) / 2, z: (down - across) / 2)
    }

    /// Far to near. Everything on the plot is drawn in this order and nothing
    /// else decides what covers what.
    static func depth(_ spot: Spot) -> Double { spot.x + spot.z }

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
