import SwiftUI

// The marks for the seed's traits, and for meeting.
//
// The same hand as `CogShape` and the rest in `Chrome.swift` — monoline, round
// free ends, even weight, per BRAND.md §3.2. They live in their own file only
// because there are now enough of them that they were burying the colours and
// the type in there.

/// Two things overlapping: a meeting.
///
/// Deliberately not two phones. A rectangle is the one shape this app has none
/// of, and the tap has always been a gesture rather than a device — what the
/// screen is about is two people, not two handsets. Two circles that overlap
/// say that at fifteen points and say nothing else.
struct MeetGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2 - 0.6
        // Overlapping by rather more than a third of a radius. Touching exactly
        // reads as a figure of eight; much further apart and they are two
        // separate marks that happen to be near each other.
        let offset = radius * 0.62
        var path = Path()
        for direction in [-1.0, 1.0] {
            let centre = CGPoint(x: rect.midX + offset * direction, y: rect.midY)
            path.addEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius,
                                       width: radius * 2, height: radius * 2))
        }
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
