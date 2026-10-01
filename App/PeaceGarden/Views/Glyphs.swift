import SwiftUI

// The marks for the seed's traits, and for meeting.
//
// The same hand as `CogShape` and the rest in `Chrome.swift` — monoline, round
// free ends, even weight, per BRAND.md §3.2. They live in their own file only
// because there are now enough of them that they were burying the colours and
// the type in there.

/// Two stems crossing twice: a meeting.
///
/// Deliberately not two phones. A rectangle is the one shape this app has none
/// of, and the tap has always been a gesture rather than a device — what the
/// screen is about is two people, not two handsets.
///
/// **Twice is what makes it a meeting rather than a junction.** One crossing is
/// an X, and an X is read as a letter before it is read as anything that grew.
/// Two is two things that took root near one another, leant through, and came
/// back — which costs no more ink and is the whole difference. Four drawings
/// were needed to find that, and each failure is worth naming because each one
/// looked correct while it was being drawn:
///
/// - **Mirrored, with the tips curling inward**, the two crooks close a heart
///   across the top. On the one screen in this app that is about two people
///   meeting, that is the worst available reading.
/// - **Two equal arcs bowing apart** make a vesica and read as a fish.
/// - **One straight stem beside one bowed stem** is a walking figure.
/// - **Arching over into a hanging leaf** is a wilt. The eye takes the
///   direction of a tip before it takes anything else, so a tip that points
///   down says the plant is failing however healthy the rest of it looks.
///
/// So: unequal, both bowing toward one another, crossing twice, and both ending
/// in a coil that winds *inward* — a stem still going rather than one giving
/// up. The lens between the crossings is given room deliberately; drawn tight,
/// the two strokes read at fifteen points as one thick line with a nick in it.
struct MeetGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let box = markBox(rect, 0.88).insetBy(dx: 0.9, dy: 0.9)
        func at(_ u: CGFloat, _ v: CGFloat) -> CGPoint {
            CGPoint(x: box.minX + box.width * u, y: box.minY + box.height * v)
        }
        let w = box.width, h = box.height

        /// A logarithmic coil, wound from its open end inward — the same curve
        /// the app mark and `SproutingRule`'s finials are drawn with. An even
        /// gain reads as wound rather than as growing.
        func coil(_ centre: CGPoint, _ radius: CGFloat,
                  gain: Double, from start: Double, sweep: Double) -> [CGPoint] {
            (0...20).reversed().map { step in
                let along = Double(step) / 20
                let r = (radius / CGFloat(gain)) * CGFloat(pow(gain, along))
                let bearing = start + sweep * along
                return CGPoint(x: centre.x + r * CGFloat(cos(bearing)),
                               y: centre.y + r * CGFloat(sin(bearing)))
            }
        }

        var path = Path()

        // The taller: from left of centre, bowing right through both crossings,
        // and curling in at the top.
        let left = coil(at(0.315, 0.150), w * 0.105, gain: 3.4, from: 1.15, sweep: 3.5)
        path.move(to: at(0.24, 1.00))
        path.addCurve(to: at(0.50, 0.20), control1: at(0.72, 0.78), control2: at(0.74, 0.40))
        path.addCurve(to: left[0],
                      control1: at(0.44, 0.14),
                      control2: CGPoint(x: left[0].x + w * 0.03, y: left[0].y + h * 0.03))
        for point in left.dropFirst() { path.addLine(to: point) }

        // The shorter, bowing the other way and coiling wider.
        let right = coil(at(0.640, 0.150), w * 0.125, gain: 3.6, from: 2.1, sweep: 3.6)
        path.move(to: at(0.76, 1.00))
        path.addCurve(to: at(0.56, 0.24), control1: at(0.28, 0.78), control2: at(0.26, 0.42))
        for point in right { path.addLine(to: point) }

        return path
    }
}

/// A clock, for when a seed was created.
struct ClockGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 0.6
        var path = Path()
        path.addEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius,
                                   width: radius * 2, height: radius * 2))
        // Not twelve o'clock: two hands on one bearing are one hand, and a
        // clock reading noon appears to have none at all.
        path.move(to: centre)
        path.addLine(to: CGPoint(x: centre.x, y: centre.y - radius * 0.55))
        path.move(to: centre)
        path.addLine(to: CGPoint(x: centre.x + radius * 0.45, y: centre.y + radius * 0.28))
        return path
    }
}

/// One petal: broad, and notched at the crown.
///
/// **The notch is the whole mark.** Without it this was a rounded teardrop —
/// which is precisely what `SeedGlyph` is, and the two sat four rows apart in
/// the same list looking like the same thing. A seed is pointed at the bottom
/// and closed at the top; a petal is wide, notched, and pinched where it joins.
/// Many real petals are notched, so it costs nothing in truth to say so.
struct PetalGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let body = rect.insetBy(dx: 0.6, dy: 0.6)
        let base = CGPoint(x: body.midX, y: body.maxY)
        // A dip rather than a cleft. Cut to a fifth of the height it read as a
        // heart, which is a worse thing to have in a list of plant traits than
        // the teardrop it was drawn to escape.
        let notch = CGPoint(x: body.midX, y: body.minY + body.height * 0.09)
        let shoulder = body.minY + body.height * 0.02

        var path = Path()
        path.move(to: base)
        path.addCurve(to: CGPoint(x: body.minX + body.width * 0.18, y: shoulder),
                      control1: CGPoint(x: body.minX, y: body.midY + body.height * 0.30),
                      control2: CGPoint(x: body.minX, y: shoulder))
        path.addQuadCurve(to: notch, control: CGPoint(x: body.midX - body.width * 0.18, y: body.minY))
        path.addQuadCurve(to: CGPoint(x: body.maxX - body.width * 0.18, y: shoulder),
                          control: CGPoint(x: body.midX + body.width * 0.18, y: body.minY))
        path.addCurve(to: base,
                      control1: CGPoint(x: body.maxX, y: shoulder),
                      control2: CGPoint(x: body.maxX, y: body.midY + body.height * 0.30))
        path.closeSubpath()
        return path
    }
}

/// A leaf: a blade with a midrib inside it, and no stalk.
///
/// **The stalk had to go.** A rib carried on past the foot of the blade is
/// botanically right and visually a line struck through an almond, which is
/// what the mark read as at fourteen points — a leaf crossed out. Ending the
/// rib where the blade does costs a true detail and buys the whole glyph.
struct LeafGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let body = rect.insetBy(dx: 0.6, dy: 0.6)
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: body.minX + body.width * x, y: body.minY + body.height * y)
        }
        let foot = at(0.0, 1.0)
        let tip = at(1.0, 0.0)

        var path = Path()
        path.move(to: foot)
        path.addQuadCurve(to: tip, control: at(0.06, 0.24))
        path.addQuadCurve(to: foot, control: at(0.76, 0.94))
        path.move(to: foot)
        path.addLine(to: tip)
        return path
    }
}

/// A plant let go: the head opened, and its seeds lifting away on the wind.
///
/// **Drawn because there was no mark for letting go.** Release to the Wild
/// Fields had been borrowing `GardenGlyph`, which says *garden* — the opposite
/// of where a released plant is going — and then `LeafGlyph`, which says
/// *leaf*. Neither says release, and a mark whose word has to explain it is a
/// mark doing nothing.
///
/// Three things, and the order they are read in is the sentence: a stem bowing
/// under the wind, the cup at its head left open and empty, and three seeds
/// rising away from it on the diagonal. The stem stays — a released plant is
/// not destroyed, it is somewhere else — and what has gone has gone upward and
/// to the right, which is the direction every departure is drawn in.
///
/// The three seeds shrink as they go, which is the only depth a monoline has.
struct ReleaseGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let body = rect.insetBy(dx: 0.8, dy: 0.8)
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: body.minX + body.width * x, y: body.minY + body.height * y)
        }

        var path = Path()

        // **Leaning, because a seed that is upright has landed.** Drawn
        // square to the frame it was a dandelion at rest with some weather
        // underneath it; tipped into the way the wind is going, and with its
        // stalk trailing behind rather than hanging, it is one thing being
        // carried. The whole head turns about its own hub, so the canopy keeps
        // its shape and only its attitude changes.
        let lean = 15.0 * .pi / 180
        let hub = at(0.50, 0.34)
        func turned(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: hub.x + (x * cos(lean) - y * sin(lean)) * body.width,
                    y: hub.y + (x * sin(lean) + y * cos(lean)) * body.height)
        }

        // **The hairs sit on a flattened dome, not on a circle.** Spread evenly
        // around the hub they made a five-pointed asterisk, and the stalk
        // leaving the same hub read as a sixth ray. Their tips are on an
        // ellipse half again as wide as it is tall, so the silhouette is a
        // canopy — which is the whole of what tells a parachute from a star.
        //
        // Five is the count. The mark this replaced learnt that twenty-eight
        // points of circle will not hold a stem, a cup and three seeds; five
        // hairs get away with it only because they all leave one point, which
        // the eye takes as one object however many strokes it took.
        for (x, y) in [(-0.31, -0.12), (-0.19, -0.23), (0.0, -0.28),
                       (0.19, -0.23), (0.31, -0.12)] {
            let tip = turned(x, y)
            path.move(to: hub)
            // Bowed outward, away from the hair in the middle, so the canopy
            // opens rather than splaying.
            path.addQuadCurve(
                to: tip,
                control: CGPoint(x: (hub.x + tip.x) / 2 + (tip.x - hub.x) * 0.22,
                                 y: (hub.y + tip.y) / 2 + (tip.y - hub.y) * 0.10)
            )
        }

        // The stalk, trailing out of the canopy, with nothing on its end but
        // the line's own round cap — which at this weight is the seed, and is
        // one mark rather than two.
        path.move(to: hub)
        path.addQuadCurve(to: turned(0, 0.26), control: turned(0.04, 0.13))

        // **Two waves of wind, deliberately unmatched.** Drawn the same length
        // at the same phase one above the other they were an ≈, which is a
        // sign somebody has already read before they read a picture. One runs
        // under the seed and off the right-hand side, the other starts at the
        // left and stops short — two gusts rather than a symbol.
        path.move(to: at(0.32, 0.75))
        path.addQuadCurve(to: at(0.64, 0.70), control: at(0.47, 0.66))
        path.addQuadCurve(to: at(0.98, 0.76), control: at(0.83, 0.81))

        path.move(to: at(0.03, 0.95))
        path.addQuadCurve(to: at(0.38, 0.89), control: at(0.19, 0.84))
        path.addQuadCurve(to: at(0.74, 0.95), control: at(0.58, 1.00))

        return path
    }
}

/// The sun, for a plant that opens by day.
struct SunGlyph: Shape {
    var rays: Int = 8

    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let half = min(rect.width, rect.height) / 2
        // The opposite proportion to `CogShape`: a small disc with long rays is
        // the brightness glyph, which is exactly what is wanted here — and is
        // precisely why the cog had to avoid it.
        let disc = half * 0.42
        let inner = half * 0.64
        let outer = half * 0.96
        var path = Path()
        path.addEllipse(in: CGRect(x: centre.x - disc, y: centre.y - disc,
                                   width: disc * 2, height: disc * 2))
        for index in 0..<rays {
            let bearing = Double(index) * 2 * .pi / Double(rays) - .pi / 2
            path.move(to: CGPoint(x: centre.x + inner * cos(bearing), y: centre.y + inner * sin(bearing)))
            path.addLine(to: CGPoint(x: centre.x + outer * cos(bearing), y: centre.y + outer * sin(bearing)))
        }
        return path
    }
}

/// A crescent, for a plant that opens by night.
///
/// Cut from two circles rather than drawn as one closed curve: the bitten edge
/// is what makes a crescent read as a moon instead of as a comma.
struct MoonGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 0.6
        let full = Path {
            $0.addEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius,
                                     width: radius * 2, height: radius * 2))
        }
        let bite = Path {
            $0.addEllipse(in: CGRect(x: centre.x - radius * 0.46, y: centre.y - radius * 1.04,
                                     width: radius * 2, height: radius * 2))
        }
        return full.subtracting(bite)
    }
}

/// The sun and the moon together, for a garden that follows the hour.
///
/// A small sun up and to the leading side, partly behind a crescent whose lit
/// limb faces it. The sun is drawn *around* the moon's disc rather than under
/// it — the monoline has no fills to hide a line behind, so the overlap is a
/// gap in the sun's stroke where the moon stands in front of it.
struct SunAndMoonGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let box = markBox(rect, 1)
        func at(_ u: CGFloat, _ v: CGFloat) -> CGPoint {
            CGPoint(x: box.minX + box.width * u, y: box.minY + box.height * v)
        }
        let side = box.width
        let moonCentre = at(0.66, 0.66)
        let moonRadius = side * 0.32
        // Clear air around the moon, so the sun's broken stroke reads as
        // passing behind rather than as touching it.
        let keepOff = moonRadius + side * 0.08

        let sunCentre = at(0.32, 0.32)
        let disc = side * 0.16
        let inner = side * 0.245
        let outer = side * 0.335

        var path = Path()

        /// A polyline, lifted wherever it passes behind the moon.
        func draw(_ points: [CGPoint]) {
            var drawing = false
            for point in points {
                let clear = hypot(point.x - moonCentre.x, point.y - moonCentre.y) > keepOff
                if clear {
                    if drawing { path.addLine(to: point) } else { path.move(to: point) }
                }
                drawing = clear
            }
        }

        draw((0...72).map { step in
            let angle = Double(step) / 72 * 2 * .pi
            return CGPoint(x: sunCentre.x + disc * cos(angle), y: sunCentre.y + disc * sin(angle))
        })
        for index in 0..<8 {
            let bearing = Double(index) * .pi / 4 - .pi / 2
            draw((0...8).map { step in
                let r = inner + (outer - inner) * CGFloat(step) / 8
                return CGPoint(x: sunCentre.x + r * cos(bearing), y: sunCentre.y + r * sin(bearing))
            })
        }

        let moonBox = CGRect(x: moonCentre.x - moonRadius - 0.6, y: moonCentre.y - moonRadius - 0.6,
                             width: (moonRadius + 0.6) * 2, height: (moonRadius + 0.6) * 2)
        path.addPath(MoonGlyph().path(in: moonBox))
        return path
    }
}

/// A bloom: the closed silhouette of a flower on a stem.
///
/// Three drawings before this one, and the two failures are the same failure
/// twice. **Strokes rising from a point make a letter.** Three of them upright
/// is a capital Y; splaying the outer two turns it into a psi. Neither is a
/// flower, and at fourteen points a reader sees the letter first every time.
///
/// A closed outline cannot be read as type, so this is one: a goblet flaring
/// from the stem to two rim points, with the top dipping between them the way
/// a cup of petals does. It is the same reasoning that took the seam off
/// `SeedGlyph` — let the silhouette carry it, and nothing has to be added.
struct BloomGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let body = rect.insetBy(dx: 0.6, dy: 0.6)
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: body.minX + body.width * x, y: body.minY + body.height * y)
        }
        let throat = at(0.5, 0.74)

        var path = Path()
        path.move(to: at(0.5, 1.0))
        path.addLine(to: throat)

        path.move(to: throat)
        // Up and out to the left rim, dipping across the top, down to the right.
        path.addCurve(to: at(0.04, 0.10),
                      control1: at(0.16, 0.66),
                      control2: at(0.00, 0.40))
        path.addQuadCurve(to: at(0.96, 0.10), control: at(0.5, 0.34))
        path.addCurve(to: throat,
                      control1: at(1.00, 0.40),
                      control2: at(0.84, 0.66))
        path.closeSubpath()
        return path
    }
}

/// An open book, for what a plant's name means.
///
/// **Transcribed, not drawn here.** The website opens `/meanings` with the same
/// mark, and it is written as one SVG path on a twenty-unit grid so that both
/// can carry it exactly:
///
///     M10 5.2C8.2 3.9 5.4 3.5 2.75 3.9V15.4C5.4 15 8.2 15.4 10 16.7
///     C11.8 15.4 14.6 15 17.25 15.4V3.9C14.6 3.5 11.8 3.9 10 5.2ZM10 5.2V16.7
///
/// Redrawing it on this side would be two marks that agree until somebody
/// improves one, so a change starts from that path and comes here second.
///
/// The grid already carries its own margin — the pages stop at 2.75 and 17.25 —
/// so it takes the whole of `markBox` rather than a share of it, and nothing
/// is inset for the stroke. The top and bottom edges of both pages dip where
/// they reach the spine, which is what makes this a book lying open rather
/// than two panes of glass side by side.
struct MeaningsGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let box = markBox(rect, 1)
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: box.minX + box.width * x / 20, y: box.minY + box.height * y / 20)
        }

        var path = Path()
        // The left page, from the head of the spine out to its corner and
        // down, then back along the foot to the spine.
        path.move(to: at(10, 5.2))
        path.addCurve(to: at(2.75, 3.9), control1: at(8.2, 3.9), control2: at(5.4, 3.5))
        path.addLine(to: at(2.75, 15.4))
        path.addCurve(to: at(10, 16.7), control1: at(5.4, 15), control2: at(8.2, 15.4))
        // The right page, the left one mirrored, and closed at the spine.
        path.addCurve(to: at(17.25, 15.4), control1: at(11.8, 15.4), control2: at(14.6, 15))
        path.addLine(to: at(17.25, 3.9))
        path.addCurve(to: at(10, 5.2), control1: at(14.6, 3.5), control2: at(11.8, 3.9))
        path.closeSubpath()
        // The spine.
        path.move(to: at(10, 5.2))
        path.addLine(to: at(10, 16.7))
        return path
    }
}

/// On to the next one waiting, and back to the last.
///
/// **Bowed, not folded.** Two straight strokes meeting at a point is the
/// system chevron, and it is the one mark in this app that would have come
/// from somewhere else. A stroke that bends instead of breaking is the same
/// hand as every other glyph here, and at the size this is drawn the
/// difference is felt rather than seen: it stops being a symbol borrowed from
/// a settings list and becomes a thing in this garden pointing the way.
///
/// It points to where the next plant is, so it has no head and no tail — an
/// arrow would say *go somewhere else* and this only says *there is another*.
struct ChevronGlyph: Shape {
    /// Which way it points. Leading is back down the queue.
    var towardsTrailing = true

    func path(in rect: CGRect) -> Path {
        let body = rect.insetBy(dx: 0.8, dy: 0.8)
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            let across = towardsTrailing ? x : 1 - x
            return CGPoint(x: body.minX + body.width * across, y: body.minY + body.height * y)
        }

        // Two curves meeting at the point rather than one bow through it. One
        // quadratic across the whole height is an arc, and an arc at this size
        // is a bracket — which is what the first drawing turned out to be. Two
        // is a stroke that comes in nearly straight, bends where the fold would
        // have been, and goes out nearly straight again.
        var path = Path()
        path.move(to: at(0.12, 0.06))
        path.addQuadCurve(to: at(0.94, 0.50), control: at(0.74, 0.28))
        path.addQuadCurve(to: at(0.12, 0.94), control: at(0.74, 0.72))
        return path
    }
}

// MARK: - The garden's tray

/// The tray at the foot of the garden: a plus while it is shut, a minus while
/// it is open.
///
/// **One mark that loses a stroke**, rather than two marks swapped, so opening
/// the tray is seen as the same control changing its mind — the upright draws
/// itself in to nothing and the bar is left. Each stroke bows very slightly, the
/// way `ChevronGlyph` does, so it is the hand of this garden and not the plus
/// on a calculator.
struct TrayGlyph: Shape {
    /// `0` is shut — a plus — and `1` is open, a minus.
    var openness: Double

    var animatableData: Double {
        get { openness }
        set { openness = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let box = markBox(rect, 0.82)
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: box.minX + box.width * x, y: box.minY + box.height * y)
        }
        var path = Path()
        path.move(to: at(0.04, 0.50))
        path.addQuadCurve(to: at(0.96, 0.50), control: at(0.50, 0.46))

        let reach = 0.46 * (1 - openness)
        if reach > 0.01 {
            path.move(to: at(0.50, 0.50 - reach))
            path.addQuadCurve(to: at(0.50, 0.50 + reach), control: at(0.54, 0.50))
        }
        return path
    }
}

/// There is more of this row, this way.
///
/// **Marcus's double chevron**, 1 October: a row of grounds that ran off the
/// edge of the screen did not say there were more. Two of `ChevronGlyph`'s
/// bowed chevrons side by side, so it reads as a direction of travel rather
/// than as a single mark that could be a button.
struct DoubleChevronGlyph: Shape {
    var towardsTrailing = true

    func path(in rect: CGRect) -> Path {
        let width = rect.width * 0.58
        let first = CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height)
        let second = first.offsetBy(dx: rect.width - width, dy: 0)
        var path = ChevronGlyph(towardsTrailing: towardsTrailing).path(in: first)
        path.addPath(ChevronGlyph(towardsTrailing: towardsTrailing).path(in: second))
        return path
    }
}

/// A turn, one way or the other: three quarters of a circle and the head of the
/// way it is going.
///
/// `aroundPlot` puts the plot itself in the middle of it — a small diamond, the
/// shape the plot is seen as — so turning the whole garden and turning one
/// figure in it are two marks rather than one mark in two places.
struct TurnGlyph: Shape {
    var clockwise = true
    var aroundPlot = false

    func path(in rect: CGRect) -> Path {
        let box = markBox(rect, 1)
        let centre = CGPoint(x: box.midX, y: box.midY)
        let radius = box.width * 0.40
        func mirrored(_ point: CGPoint) -> CGPoint {
            clockwise ? point : CGPoint(x: 2 * centre.x - point.x, y: point.y)
        }

        // Screen angles grow clockwise. The gap is at the top: the stroke runs
        // from just right of it, round the bottom, to just left of it, and the
        // head points back across the gap the way it is going.
        let start = Double.pi * 1.70, end = Double.pi * 3.30
        let steps = 32
        var path = Path()
        for step in 0...steps {
            let angle = start + (end - start) * Double(step) / Double(steps)
            let point = mirrored(CGPoint(x: centre.x + radius * cos(angle),
                                         y: centre.y + radius * sin(angle)))
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }

        // The head: two short strokes back from the tip, either side of the
        // way it is travelling.
        let tip = CGPoint(x: centre.x + radius * cos(end), y: centre.y + radius * sin(end))
        let along = CGVector(dx: -sin(end), dy: cos(end))
        let out = CGVector(dx: cos(end), dy: sin(end))
        let back = radius * 0.55, spread = radius * 0.42
        for side in [-1.0, 1.0] {
            path.move(to: mirrored(CGPoint(x: tip.x - along.dx * back + out.dx * spread * side,
                                           y: tip.y - along.dy * back + out.dy * spread * side)))
            path.addLine(to: mirrored(tip))
        }

        if aroundPlot {
            let w = radius * 0.62, h = w * 0.58
            path.move(to: CGPoint(x: centre.x, y: centre.y - h))
            path.addLine(to: CGPoint(x: centre.x + w, y: centre.y))
            path.addLine(to: CGPoint(x: centre.x, y: centre.y + h))
            path.addLine(to: CGPoint(x: centre.x - w, y: centre.y))
            path.closeSubpath()
        }
        return path
    }
}

/// The plot as it was first seen: its diamond, in the middle of four corners
/// that frame it.
///
/// For putting the view back — turn, zoom and pan — after it has been moved.
/// A frame round the thing is what *fit it to the screen* has looked like
/// since viewfinders, and it says nothing about undoing anything else.
struct FramedPlotGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let box = markBox(rect, 0.92)
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: box.minX + box.width * x, y: box.minY + box.height * y)
        }
        var path = Path()
        path.move(to: at(0.50, 0.30))
        path.addLine(to: at(0.80, 0.50))
        path.addLine(to: at(0.50, 0.70))
        path.addLine(to: at(0.20, 0.50))
        path.closeSubpath()

        let arm: CGFloat = 0.20
        let corners: [(CGFloat, CGFloat)] = [(0, 0), (1, 0), (1, 1), (0, 1)]
        for (x, y) in corners {
            let dx: CGFloat = x == 0 ? arm : -arm
            let dy: CGFloat = y == 0 ? arm : -arm
            path.move(to: at(x + dx, y))
            path.addLine(to: at(x, y))
            path.addLine(to: at(x, y + dy))
        }
        return path
    }
}

/// Smaller or larger: a ring, small or large in its frame.
///
/// Two rings side by side are the comparison itself, which is all a size
/// control has to say. Not a plus and a minus, which on this screen already
/// open and shut the tray.
struct SizeGlyph: Shape {
    var larger = true

    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * (larger ? 0.86 : 0.40)
        return Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius,
                                      width: radius * 2, height: radius * 2))
    }
}

