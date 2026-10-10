import CoreGraphics
import Foundation

/// **The app's own mark, as numbers, and how it lets go.**
///
/// The drawing is `tools/icon/make_icon.py`'s, ported line for line: a
/// logarithmic coil, a bract that leaves on the tangent the coil ends on, and a
/// taper of the coil's colour running on into the bract. Every dial below is that
/// script's and carries its name. Change the script's dials and this has to
/// follow; `LoadingTests.theMarkAtRestIsTheIconAtRest` holds the two together
/// by pinning where the drawing's own SVG puts the mouth of the bract.
///
/// ## How it unwinds, and why it is not a trim
///
/// `design/Motion.dc.html` is explicit about the gesture: *a tendril opens by its
/// curvature falling away… trimming a fixed spiral reads as a line being drawn
/// on, and is a duller gesture for it.* So nothing here is drawn on. The coil
/// keeps its whole length at every moment, anchored where it meets the bract, and
/// the turning in it is what changes: at `coil == 0` the inner turns carry more
/// curvature than the mark's, concentrated toward the tip the way a fiddlehead
/// keeps it, and as `coil` rises that extra curvature lets go until the line is
/// exactly the mark's.
///
/// **Anchored at the bract's end and not at the tip**, which was the other way
/// round first. Anchoring the tip made the whole figure swing outward, carrying
/// the bract round with it like a flag on a turning wheel. Anchored here, the
/// arm and the bract stay where they will end up and only the inside moves, so
/// the composition holds still and the eye is given one thing to follow.
enum UnwindingMarkGeometry {

    // MARK: - The dials, from `tools/icon/make_icon.py`

    static let stroke = 48.0
    static let turns = 2.0
    static let startRadius = 48.0
    static let growthPerTurn = 2.55
    /// Measured anticlockwise from east, as the script measures it.
    static let endBearing = 45.0
    static let spatheLength = 0.92
    static let spatheTurn = 0.30
    static let spatheWidth = 0.28
    static let taperTo = 0.58
    static let taperPower = 1.7
    static let taperTurnsAt = 0.38
    /// The script's tile and margin, for placing the figure on the same grid its
    /// SVG is on.
    static let tile = 1024.0
    static let margin = 190.0

    /// The extra curvature the furled coil carries toward its tip, as a multiple
    /// of the mark's own there, and how hard that is pushed toward the tip. Chosen
    /// by drawing six candidates side by side (`design/loading-2026-10-10`): lower
    /// values never look furled, and higher ones close the tip into a solid disc,
    /// which reads as something other than a coil.
    static let furledExtra = 2.0
    static let furledTaper = 2.5

    // MARK: - The colours, from the script's own ramp

    /// Forest green, lime and yellow at 140°, 100° and 60°: isoluminant, and
    /// 13.00:1 on `#0D0D1F`. Read off `tools/icon/icon.svg`'s `sweep` gradient.
    static let ramp: [(r: Double, g: Double, b: Double)] = [
        (0x06 / 255, 0xF5 / 255, 0x56 / 255),
        (0x55 / 255, 0xF3 / 255, 0x06 / 255),
        (0xDC / 255, 0xDC / 255, 0x06 / 255),
    ]

    // MARK: - One figure

    /// What is drawn: three runs of points in the script's construction units.
    /// The bract is an outline (out along one edge, back along the other) to be
    /// stroked; the spike is a polygon to be filled.
    struct Figure {
        var coil: [CGPoint]
        var bract: [CGPoint]
        var spike: [CGPoint]
    }

    /// The whole mark at rest, and the pieces it is made from.
    static let rest = Construction()

    /// The figure at a state of opening. Each argument is 0…1 and independent,
    /// because the three open at different moments: the coil first, the bract
    /// after it, the spike last.
    ///
    /// - Parameters:
    ///   - coil: 0 is furled, 1 is the mark's own spiral.
    ///   - bract: how wide the white outline stands against its full width.
    ///   - spike: the same, for the taper of colour inside it.
    static func figure(coil: Double, bract: Double, spike: Double) -> Figure {
        rest.figure(coil: coil, bract: bract, spike: spike)
    }

    /// The mark's ink bounds at rest, in construction units, with half a stroke
    /// added: exact rather than conservative for round caps and joins.
    static var inkBounds: CGRect { rest.inkBounds }

    // MARK: - The construction

    struct Construction {
        /// 513 points, inner tip first, outer end (the bract's mouth) last.
        let coil: [CGPoint]
        let spine: [CGPoint]
        let spineNormals: [CGPoint]
        let spineLength: Double
        let spikeCount: Int
        let spikeNormals: [CGPoint]

        // The coil as turning, which is what relaxes.
        private let segmentLengths: [Double]
        private let headings: [Double]
        private let turning: [Double]
        private let tipness: [Double]

        init() {
            // The coil. Solve the phase so the outer end lands on `endBearing`.
            let sweep = UnwindingMarkGeometry.turns * 2 * .pi
            let phase = UnwindingMarkGeometry.endBearing * .pi / 180 - sweep
            let samples = 512
            var line: [CGPoint] = []
            line.reserveCapacity(samples + 1)
            for index in 0...samples {
                let theta = sweep * Double(index) / Double(samples)
                let radius = UnwindingMarkGeometry.startRadius
                    * pow(UnwindingMarkGeometry.growthPerTurn, theta / (2 * .pi))
                let angle = theta + phase
                // Screen space: y grows downward, so the sine is negated.
                line.append(CGPoint(x: radius * cos(angle), y: -radius * sin(angle)))
            }
            coil = line

            // The bract's spine leaves on the tangent the coil actually ends on,
            // taken from the drawn points rather than differentiated by hand.
            let tail = CGPoint(x: line[samples].x - line[samples - 1].x,
                               y: line[samples].y - line[samples - 1].y)
            let tailLength = hypot(tail.x, tail.y)
            let heading = CGPoint(x: tail.x / tailLength, y: tail.y / tailLength)
            let bractLength = UnwindingMarkGeometry.spatheLength
                * UnwindingMarkGeometry.startRadius
                * pow(UnwindingMarkGeometry.growthPerTurn, UnwindingMarkGeometry.turns)
            let steps = 160
            var blade: [CGPoint] = [line[samples]]
            for index in 1...steps {
                // The turn accumulates along the blade, so the bend is gentle at
                // the base and the tip is the part that has swung.
                let angle = UnwindingMarkGeometry.spatheTurn * Double(index) / Double(steps)
                let direction = CGPoint(
                    x: heading.x * cos(angle) - heading.y * sin(angle),
                    y: heading.x * sin(angle) + heading.y * cos(angle))
                let previous = blade[index - 1]
                blade.append(CGPoint(x: previous.x + direction.x * bractLength / Double(steps),
                                     y: previous.y + direction.y * bractLength / Double(steps)))
            }
            spine = blade
            spineNormals = Self.normals(of: blade)
            spineLength = Self.length(of: blade)

            // The taper keeps the spine up to `taperTo` of the way along.
            var kept = 0
            for index in 0..<blade.count where Double(index) / Double(steps)
                <= UnwindingMarkGeometry.taperTo { kept = index + 1 }
            spikeCount = kept
            spikeNormals = Self.normals(of: Array(blade[0..<kept]))

            // The coil as turning: lengths, headings and curvature per segment.
            var lengths: [Double] = []
            var raw: [Double] = []
            for index in 0..<samples {
                let dx = line[index + 1].x - line[index].x
                let dy = line[index + 1].y - line[index].y
                lengths.append(hypot(dx, dy))
                raw.append(atan2(dy, dx))
            }
            var unwrapped = raw
            for index in 1..<unwrapped.count {
                while unwrapped[index] - unwrapped[index - 1] > .pi { unwrapped[index] -= 2 * .pi }
                while unwrapped[index] - unwrapped[index - 1] < -.pi { unwrapped[index] += 2 * .pi }
            }
            segmentLengths = lengths
            headings = unwrapped
            var change: [Double] = [0]
            for index in 1..<unwrapped.count { change.append(unwrapped[index] - unwrapped[index - 1]) }
            turning = change
            // 1 at the tip, 0 at the mouth: where the extra curvature lives.
            tipness = (0..<samples).map { 1 - Double($0) / Double(samples) }
        }

        // MARK: The figure at a state of opening

        func figure(coil open: Double, bract: Double, spike: Double) -> Figure {
            Figure(
                coil: relaxed(open),
                bract: outline(widthScale: bract),
                spike: taper(widthScale: spike))
        }

        /// The coil with its extra curvature let go by `open`, anchored at the
        /// bract's mouth. At 1 this is `coil` to the last digit.
        private func relaxed(_ open: Double) -> [CGPoint] {
            let held = min(max(open, 0), 1)
            if held >= 1 { return coil }
            let count = segmentLengths.count
            var angles = [Double](repeating: 0, count: count)
            angles[count - 1] = headings[count - 1]
            for index in stride(from: count - 2, through: 0, by: -1) {
                let extra = 1 + UnwindingMarkGeometry.furledExtra * (1 - held)
                    * pow(tipness[index + 1], UnwindingMarkGeometry.furledTaper)
                angles[index] = angles[index + 1] - turning[index + 1] * extra
            }
            var points = [CGPoint](repeating: .zero, count: count + 1)
            points[count] = coil[count]
            for index in stride(from: count - 1, through: 0, by: -1) {
                points[index] = CGPoint(
                    x: points[index + 1].x - cos(angles[index]) * segmentLengths[index],
                    y: points[index + 1].y - sin(angles[index]) * segmentLengths[index])
            }
            return points
        }

        /// The bract: out along one edge and back along the other, so the whole
        /// mark stays one path.
        ///
        /// **It opens as a bud grows and not as a line widens.** Narrowing the
        /// outline alone leaves the spine, and the outline is stroked at the
        /// mark's full weight, so at zero width what is drawn is a white bar the
        /// length of the bract: the first version of this put a stick out of the
        /// coil for half a second. Scaled about its mouth instead, the whole
        /// outline is a small closed shape at the start, and the hollow only
        /// appears when it is big enough to hold one.
        private func outline(widthScale: Double) -> [CGPoint] {
            let scale = min(max(widthScale, 0), 1)
            let mouth = spine[0]
            let last = Double(spine.count - 1)
            var near: [CGPoint] = []
            var far: [CGPoint] = []
            for index in spine.indices {
                let s = Double(index) / last
                let half = Self.spatheHalfWidth(s, length: spineLength)
                near.append(CGPoint(x: spine[index].x + spineNormals[index].x * half,
                                    y: spine[index].y + spineNormals[index].y * half))
                far.append(CGPoint(x: spine[index].x - spineNormals[index].x * half,
                                   y: spine[index].y - spineNormals[index].y * half))
            }
            let full = near + far.reversed()
            if scale >= 1 { return full }
            return full.map {
                CGPoint(x: mouth.x + ($0.x - mouth.x) * scale, y: mouth.y + ($0.y - mouth.y) * scale)
            }
        }

        /// The coil's colour carried into the bract, as an outline to be filled.
        private func taper(widthScale: Double) -> [CGPoint] {
            let scale = min(max(widthScale, 0), 1)
            let last = Double(spine.count - 1)
            var near: [CGPoint] = []
            var far: [CGPoint] = []
            for index in 0..<spikeCount {
                let s = Double(index) / last
                let half = Self.taperHalfWidth(s) * scale
                near.append(CGPoint(x: spine[index].x + spikeNormals[index].x * half,
                                    y: spine[index].y + spikeNormals[index].y * half))
                far.append(CGPoint(x: spine[index].x - spikeNormals[index].x * half,
                                   y: spine[index].y - spikeNormals[index].y * half))
            }
            return near + far.reversed()
        }

        // MARK: Measures

        /// The smallest box containing the ink at rest.
        var inkBounds: CGRect {
            let full = figure(coil: 1, bract: 1, spike: 1)
            let points = full.coil + full.bract + full.spike
            let half = UnwindingMarkGeometry.stroke / 2
            let xs = points.map(\.x)
            let ys = points.map(\.y)
            return CGRect(x: xs.min()! - half, y: ys.min()! - half,
                          width: xs.max()! - xs.min()! + 2 * half,
                          height: ys.max()! - ys.min()! + 2 * half)
        }

        /// The coil and the taper only, which is what the sweep is measured
        /// across: the bract is white and takes no part in it.
        var sweepBounds: CGRect {
            let full = figure(coil: 1, bract: 1, spike: 1)
            let points = full.coil + full.spike
            let half = UnwindingMarkGeometry.stroke / 2
            let xs = points.map(\.x)
            let ys = points.map(\.y)
            return CGRect(x: xs.min()! - half, y: ys.min()! - half,
                          width: xs.max()! - xs.min()! + 2 * half,
                          height: ys.max()! - ys.min()! + 2 * half)
        }

        /// Where the script puts the figure on its 1024 tile: scaled so the
        /// longer side of the ink is `tile − 2 × margin`, and centred. The stroke
        /// the SVG is drawn at is `stroke × scale`.
        var tilePlacement: (scale: Double, offset: CGPoint) {
            let box = inkBounds
            let scale = (UnwindingMarkGeometry.tile - 2 * UnwindingMarkGeometry.margin)
                / max(box.width, box.height)
            // The script centres the *points'* bounds plus half a stroke; the
            // box here is the same thing, so the centre is the same.
            let offsetX = (UnwindingMarkGeometry.tile - box.width * scale) / 2 - box.minX * scale
            let offsetY = (UnwindingMarkGeometry.tile - box.height * scale) / 2 - box.minY * scale
            return (scale, CGPoint(x: offsetX, y: offsetY))
        }

        // MARK: The bract's own profile, from the script

        static func spatheHalfWidth(_ s: Double, length: Double) -> Double {
            let shaped = pow(max(sin(.pi * pow(s, 0.62)), 0), 0.85)
            return shaped * UnwindingMarkGeometry.spatheWidth * length
        }

        static func taperHalfWidth(_ s: Double) -> Double {
            let along = min(max(1 - s / UnwindingMarkGeometry.taperTo, 0), 1)
            return pow(along, UnwindingMarkGeometry.taperPower) * UnwindingMarkGeometry.stroke / 2
        }

        // MARK: Small helpers

        static func length(of points: [CGPoint]) -> Double {
            var total = 0.0
            for index in 1..<points.count {
                total += hypot(points[index].x - points[index - 1].x,
                               points[index].y - points[index - 1].y)
            }
            return total
        }

        /// Unit normals from central differences, one-sided at the ends — what
        /// `numpy.gradient` does, which is what the script does.
        static func normals(of points: [CGPoint]) -> [CGPoint] {
            let last = points.count - 1
            return points.indices.map { index in
                let before = points[max(index - 1, 0)]
                let after = points[min(index + 1, last)]
                let steps = Double(min(index + 1, last) - max(index - 1, 0))
                let tx = (after.x - before.x) / steps
                let ty = (after.y - before.y) / steps
                let size = max(hypot(tx, ty), 1e-9)
                return CGPoint(x: -ty / size, y: tx / size)
            }
        }
    }

    // MARK: - The sweep's colour at a point

    /// The colour the sweep has reached at `point`, for the taper to join it.
    /// Bottom-left to top-right across `box`, even stops: `sweep_at` in the
    /// script.
    static func sweepColour(at point: CGPoint, in box: CGRect) -> (r: Double, g: Double, b: Double) {
        let start = CGPoint(x: box.minX, y: box.maxY)
        let axis = CGPoint(x: box.maxX - box.minX, y: box.minY - box.maxY)
        let along = ((point.x - start.x) * axis.x + (point.y - start.y) * axis.y)
            / (axis.x * axis.x + axis.y * axis.y)
        let t = min(max(along, 0), 1)
        let position = t * Double(ramp.count - 1)
        let lower = Int(min(max(floor(position), 0), Double(ramp.count - 2)))
        let blend = position - Double(lower)
        let a = ramp[lower], b = ramp[lower + 1]
        return (a.r * (1 - blend) + b.r * blend,
                a.g * (1 - blend) + b.g * blend,
                a.b * (1 - blend) + b.b * blend)
    }
}
