import SwiftUI

/// Now and again, a few birds crossing very high.
///
/// **A moment, not a screensaver.** Each quarter of an hour has about one
/// chance in four of a crossing, and a crossing lasts half a minute. Somebody
/// who opens the garden for a minute a day sees birds a few times a month,
/// which is about how often anybody looks up at the right moment outside.
/// Between crossings nothing here draws at all.
///
/// **The season's birds.** Swifts in summer, in a loose screaming party; a
/// skein of geese in autumn and again on their way back in late winter; at
/// other times a small loose flock. The months are turned round for a garden
/// in the southern hemisphere, whose latitude comes from the time zone's city
/// as the stars' does.
///
/// **Dealt from the clock, like the clouds.** Everyone in a time zone gets the
/// same crossings at the same minutes.
enum SkyLife {

    enum Kind: String, Sendable {
        case swifts, geese, flock
    }

    struct Flight: Sendable {
        var kind: Kind
        var start: Date
        var duration: TimeInterval
        var count: Int
        var seed: Int
        var fromLeft: Bool
        /// Where it enters and leaves, and how far its path bows, as fractions
        /// of the screen's height.
        var enter: Double
        var leave: Double
        var bow: Double
    }

    /// How the day is cut up for dealing crossings.
    static let slot: TimeInterval = 15 * 60
    /// The chance of a crossing in any one slot.
    static let chance = 0.26

    static func kind(on date: Date, latitude: Double) -> Kind {
        let calendar = Calendar.current
        var month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        if latitude < 0 { month = (month + 5) % 12 + 1 }
        switch (month, day) {
        case (5...7, _), (8, ...15): return .swifts
        case (9, 15...), (10...11, _), (2, 15...), (3, _): return .geese
        default: return .flock
        }
    }

    /// The crossing dealt to the slot this date falls in, if there is one.
    static func flight(inSlotOf date: Date, latitude: Double) -> Flight? {
        let local = date.timeIntervalSince1970 + Double(TimeZone.current.secondsFromGMT(for: date))
        let index = Int(floor(local / slot))
        var dice = SkyDice(index, 0xB1D5)
        guard dice.next() < chance else { return nil }

        let kind = kind(on: date, latitude: latitude)
        let duration: TimeInterval
        let count: Int
        switch kind {
        case .swifts:
            duration = 24 + 10 * dice.next()
            count = 3 + Int(dice.next() * 3.99)
        case .geese:
            duration = 40 + 14 * dice.next()
            count = 7 + Int(dice.next() * 7.99)
        case .flock:
            duration = 30 + 10 * dice.next()
            count = 5 + Int(dice.next() * 4.99)
        }
        let slotStart = Double(index) * slot - Double(TimeZone.current.secondsFromGMT(for: date))
        let start = slotStart + dice.next() * (slot - duration - 1)
        return Flight(
            kind: kind,
            start: Date(timeIntervalSince1970: start),
            duration: duration,
            count: count,
            seed: index,
            fromLeft: dice.next() < 0.5,
            enter: 0.23 + 0.15 * dice.next(),
            leave: 0.23 + 0.15 * dice.next(),
            bow: (dice.next() - 0.5) * 0.10
        )
    }

    /// The crossing in the sky at this moment, if any.
    static func flight(at date: Date, latitude: Double) -> Flight? {
        guard let flight = flight(inSlotOf: date, latitude: latitude) else { return nil }
        let into = date.timeIntervalSince(flight.start)
        return into >= 0 && into <= flight.duration ? flight : nil
    }

    /// When the next crossing sets out, looking a few slots ahead.
    static func nextStart(after date: Date, latitude: Double) -> Date? {
        for ahead in 0..<8 {
            let probe = date.addingTimeInterval(Double(ahead) * slot)
            if let flight = flight(inSlotOf: probe, latitude: latitude), flight.start > date {
                return flight.start
            }
        }
        return nil
    }

    // MARK: Drawing

    /// The crossing as it stands at `date`, if one is under way.
    @MainActor
    static func draw(at date: Date, latitude: Double, in context: inout GraphicsContext, size: CGSize,
                     palette: SkyPalette, up: Double, keepClear: [CGRect]) {
        guard up > 0.06, let flight = flight(at: date, latitude: latitude) else { return }
        let t = date.timeIntervalSince(flight.start)
        let along = t / flight.duration

        // The path: a long, shallow bow across the upper sky, entering and
        // leaving beyond the edges so nobody sees a bird appear.
        let w = size.width, h = size.height
        let a = CGPoint(x: flight.fromLeft ? -0.12 * w : 1.12 * w, y: flight.enter * h)
        let b = CGPoint(x: flight.fromLeft ? 1.12 * w : -0.12 * w, y: flight.leave * h)
        let c = CGPoint(x: w / 2, y: (a.y + b.y) / 2 + flight.bow * h)
        func path(_ u: Double) -> CGPoint {
            let v = 1 - u
            return CGPoint(x: v * v * a.x + 2 * v * u * c.x + u * u * b.x,
                           y: v * v * a.y + 2 * v * u * c.y + u * u * b.y)
        }
        let lead = path(along)
        let ahead = path(min(1, along + 0.01))
        let behind = path(max(0, along - 0.01))
        var heading = CGVector(dx: ahead.x - behind.x, dy: ahead.y - behind.y)
        let length = max(0.001, hypot(heading.dx, heading.dy))
        heading = CGVector(dx: heading.dx / length, dy: heading.dy / length)
        let side = CGVector(dx: -heading.dy, dy: heading.dx)

        // Dark against the sky, but with the sky in it: far things are seen
        // through air.
        let ink = SkyPalette.mix(palette.zenith, SIMD3(0.02, 0.03, 0.06), 0.62)
        var dice = SkyDice(flight.seed, 0xF1)

        for k in 0..<flight.count {
            let spot: CGPoint
            var facing = heading
            switch flight.kind {
            case .geese:
                // A V with one arm longer than the other, every bird keeping
                // station a little loosely.
                let rank = Double((k + 1) / 2)
                let arm: Double = k == 0 ? 0 : (k % 2 == 0 ? 1 : -1)
                let wobble = sin(t * 0.8 + Double(k) * 1.7) * 1.3
                let back = rank * 7.0 + sin(t * 0.6 + Double(k)) * 0.8
                spot = CGPoint(x: lead.x - heading.dx * back + side.dx * (arm * rank * 5.0 + wobble),
                               y: lead.y - heading.dy * back + side.dy * (arm * rank * 5.0 + wobble))
            case .swifts:
                // A loose party, each bird swinging round its own circle as
                // the party goes, which is how swifts hawk across a sky.
                let radius = 10 + 18 * dice.next()
                let speed = (0.7 + 0.8 * dice.next()) * (dice.next() < 0.5 ? -1 : 1)
                let phase = dice.next() * 2 * .pi
                let spread = (dice.next() - 0.5) * 44
                let angle = t * speed + phase
                spot = CGPoint(x: lead.x + heading.dx * spread + cos(angle) * radius,
                               y: lead.y + heading.dy * spread + sin(angle) * radius * 0.6)
                let swing = CGVector(dx: -sin(angle) * radius * speed, dy: cos(angle) * radius * 0.6 * speed)
                let pace = 1.12 * w / flight.duration
                let v = CGVector(dx: heading.dx * pace + swing.dx, dy: heading.dy * pace + swing.dy)
                let span = max(0.001, hypot(v.dx, v.dy))
                facing = CGVector(dx: v.dx / span, dy: v.dy / span)
            case .flock:
                let spreadAlong = (dice.next() - 0.5) * 34
                let spreadSide = (dice.next() - 0.5) * 22
                let drift = sin(t * 0.9 + Double(k) * 2.3) * 2.5
                spot = CGPoint(x: lead.x + heading.dx * spreadAlong + side.dx * (spreadSide + drift),
                               y: lead.y + heading.dy * spreadAlong + side.dy * (spreadSide + drift))
            }

            var keep = 1.0
            for box in keepClear { keep = min(keep, GardenSky.dimming(at: spot, near: box.insetBy(dx: -6, dy: -6))) }
            guard keep > 0.02 else { continue }

            bird(flight.kind, at: spot, facing: facing, time: t, index: k,
                 in: &context, colour: Color(sky: ink, opacity: 0.62 * keep))
        }
    }

    /// One bird, as seen from below and far off: a few points of silhouette.
    private static func bird(_ kind: Kind, at spot: CGPoint, facing: CGVector, time: Double, index: Int,
                             in context: inout GraphicsContext, colour: Color) {
        let across = CGVector(dx: -facing.dy, dy: facing.dx)
        var shape = Path()
        func p(_ forward: Double, _ out: Double) -> CGPoint {
            CGPoint(x: spot.x + facing.dx * forward + across.dx * out,
                    y: spot.y + facing.dy * forward + across.dy * out)
        }

        switch kind {
        case .swifts:
            // The anchor: two sickle wings swept back from a short body,
            // flickering in bursts and gliding between them.
            let burst = sin(time * 0.9 + Double(index) * 1.3) > 0.2
            let flicker = burst ? 0.80 + 0.20 * sin(time * 44 + Double(index)) : 1
            let span = 3.1 * flicker
            shape.move(to: p(-1.6, -span))
            shape.addQuadCurve(to: p(0.5, 0), control: p(0.2, -span * 0.55))
            shape.addQuadCurve(to: p(-1.6, span), control: p(0.2, span * 0.55))
            shape.move(to: p(1.0, 0))
            shape.addLine(to: p(-0.8, 0))
            context.stroke(shape, with: .color(colour), style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
        case .geese, .flock:
            // The bird everybody draws, because it is what a far bird looks
            // like: two wings and the beat of them, banked with the path.
            let goose = kind == .geese
            let span = goose ? 3.1 : 1.9
            var beat = sin(time * 2 * .pi * (goose ? 1.4 : 4.5) + Double(index) * 0.7)
            if !goose {
                // Small birds bound: a few quick beats, then wings shut.
                let cycle = (time * 1.4 + Double(index) * 0.37).truncatingRemainder(dividingBy: 1)
                if cycle > 0.6 { beat = -0.2 }
            }
            let lift = span * 0.55 * beat
            let bank = max(-0.35, min(0.35, atan(Double(facing.dy / max(0.2, abs(facing.dx))))))
            func q(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: spot.x + x * cos(bank) - y * sin(bank), y: spot.y + x * sin(bank) + y * cos(bank))
            }
            shape.move(to: q(-span, -lift))
            shape.addQuadCurve(to: q(0, 0.35), control: q(-span * 0.45, -lift * 0.2 - span * 0.3))
            shape.addQuadCurve(to: q(span, -lift), control: q(span * 0.45, -lift * 0.2 - span * 0.3))
            context.stroke(shape, with: .color(colour),
                           style: StrokeStyle(lineWidth: goose ? 1.0 : 0.9, lineCap: .round, lineJoin: .round))
        }
    }
}

/// When the moving part of the sky needs drawing again.
///
/// **Nothing is drawn that has not moved.** Clouds drift a fraction of a
/// point a frame, so twelve frames a second is smooth; a bird's wings need
/// thirty; and on a clear day with no bird in the sky the next entry is the
/// moment the next crossing sets out, so the canvas sleeps until then.
struct SkyMotionSchedule: TimelineSchedule {
    /// The developer clock's shift, so the motion runs on the garden's clock.
    let shift: TimeInterval
    let latitude: Double

    func entries(from start: Date, mode: TimelineScheduleMode) -> Entries {
        Entries(coming: start, schedule: self, sparing: mode == .lowFrequency)
    }

    struct Entries: Sequence, IteratorProtocol {
        var coming: Date
        let schedule: SkyMotionSchedule
        let sparing: Bool

        mutating func next() -> Date? {
            let now = coming
            coming = schedule.after(now, sparing: sparing)
            return now
        }
    }

    func after(_ date: Date, sparing: Bool) -> Date {
        if sparing { return date.addingTimeInterval(1) }
        let garden = date.addingTimeInterval(shift)
        if SkyLife.flight(at: garden, latitude: latitude) != nil {
            return date.addingTimeInterval(1.0 / 30)
        }
        if !SkyClouds.day(garden).clouds.isEmpty { return date.addingTimeInterval(1.0 / 12) }
        if let next = SkyLife.nextStart(after: garden, latitude: latitude) {
            return max(date.addingTimeInterval(1.0 / 30), next.addingTimeInterval(-shift))
        }
        return date.addingTimeInterval(60)
    }
}
