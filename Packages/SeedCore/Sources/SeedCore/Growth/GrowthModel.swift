import Foundation

/// Turns "how long has this plant been alive" into "what does it look like".
///
/// Growth is a pure function of the genome and elapsed time, so a plant looks
/// the same on any device that knows its seed and birth date, and there is
/// nothing to sync. The timeline runs in real days on purpose — the plant is
/// something to come back to, not something to scrub through.
public struct GrowthModel {
    public enum Stage: String, CaseIterable, Codable, Sendable {
        case germinating
        case seedling
        case growing
        case budding
        case blooming
        case mature

        public var displayName: String {
            switch self {
            case .germinating: return "Germinating"
            case .seedling: return "Seedling"
            case .growing: return "Growing"
            case .budding: return "In bud"
            case .blooming: return "In bloom"
            case .mature: return "Mature"
            }
        }
    }

    public struct State: Equatable, Sendable {
        public var stage: Stage
        /// Progress through the current stage, `0...1`.
        public var stageProgress: Double
        /// Progress across the whole timeline to full bloom, `0...1`.
        public var overall: Double
        /// Fraction of final height reached.
        public var heightScale: Double
        /// How many of the leaves have opened, `0...1`.
        public var leafUnfurl: Double
        /// Bud swelling ahead of the bloom, `0...1`.
        public var budSwell: Double
        /// Petal opening, `0...1`. Damped at night for plants that close.
        public var bloomOpen: Double
        public var age: TimeInterval
        /// Time until the next stage begins, or `nil` once mature.
        public var timeToNextStage: TimeInterval?
    }

    public let genome: Genome

    public init(genome: Genome) {
        self.genome = genome
    }

    private static let hour: TimeInterval = 3600
    private static let day: TimeInterval = 86_400

    /// Stage boundaries measured in seconds from the plant's birth.
    private var boundaries: [(stage: Stage, end: TimeInterval)] {
        let tempo = genome.tempo
        let germination = tempo.germinationHours * Self.hour
        let seedling = germination + tempo.seedlingDays * Self.day
        let growing = seedling + tempo.vegetativeDays * Self.day
        let budding = growing + tempo.buddingDays * Self.day
        let blooming = budding + tempo.bloomDays * Self.day
        return [
            (.germinating, germination),
            (.seedling, seedling),
            (.growing, growing),
            (.budding, budding),
            (.blooming, blooming)
        ]
    }

    public func state(birth: Date, now: Date = Date(), calendar: Calendar = .current) -> State {
        let age = max(0, now.timeIntervalSince(birth))
        let marks = boundaries
        let fullBloomAt = marks[3].end

        var stage: Stage = .mature
        var stageStart: TimeInterval = marks[4].end
        var stageEnd: TimeInterval?
        var previousEnd: TimeInterval = 0
        for mark in marks {
            if age < mark.end {
                stage = mark.stage
                stageStart = previousEnd
                stageEnd = mark.end
                break
            }
            previousEnd = mark.end
        }

        let stageProgress: Double
        if let stageEnd, stageEnd > stageStart {
            stageProgress = ((age - stageStart) / (stageEnd - stageStart)).clamped(to: 0...1)
        } else {
            stageProgress = 1
        }

        let overall = (age / fullBloomAt).clamped(to: 0...1)

        // Height runs ahead of the bloom and eases off as the plant tops out.
        //
        // The floor is what a seed looks like the moment it is sown, and it is
        // deliberately not a hair above zero: the ramp below is measured in
        // days, so across the germination *hours* it barely moves, and whatever
        // the floor is, that is the plant its owner meets first. At 0.02 that
        // was a two-centimetre stub. A sprout wants to be taller than the husk
        // it came out of.
        let heightSpan = marks[2].end
        let height = Self.easeOut((age / heightSpan).clamped(to: 0...1))

        // Leaves open from the base upward, starting just after the sprout.
        let leafStart = marks[0].end
        let leafSpan = max(1, marks[2].end - leafStart)
        let leafUnfurl = Self.easeOut(((age - leafStart) / leafSpan).clamped(to: 0...1))

        let budStart = marks[2].end
        let budSpan = max(1, marks[3].end - budStart)
        let budSwell = ((age - budStart) / budSpan).clamped(to: 0...1)

        let bloomStart = marks[3].end
        let bloomSpan = max(1, genome.tempo.bloomDays * Self.day * 0.35)
        var bloomOpen = Self.easeInOut(((age - bloomStart) / bloomSpan).clamped(to: 0...1))
        if genome.bloom.present == false {
            bloomOpen = 0
        }
        bloomOpen *= Self.diurnalFactor(genome: genome, now: now, calendar: calendar)

        let timeToNextStage: TimeInterval? = stageEnd.map { $0 - age }

        return State(
            stage: stage,
            stageProgress: stageProgress,
            overall: overall,
            heightScale: max(0.055, height),
            leafUnfurl: leafUnfurl,
            budSwell: budSwell,
            bloomOpen: bloomOpen,
            age: age,
            timeToNextStage: timeToNextStage
        )
    }

    /// Plants that open by day close to about a third overnight, and the
    /// night-blooming ones do the reverse. It is a small thing that makes the
    /// plant feel like it is living alongside you.
    static func diurnalFactor(genome: Genome, now: Date, calendar: Calendar) -> Double {
        let hour = Double(calendar.component(.hour, from: now))
            + Double(calendar.component(.minute, from: now)) / 60.0
        // Peaks at 13:00 for day plants, 01:00 for night plants.
        let peak = genome.tempo.opensByDay ? 13.0 : 1.0
        var delta = abs(hour - peak)
        if delta > 12 { delta = 24 - delta }
        let closeness = 1.0 - (delta / 12.0)
        return 0.34 + 0.66 * Self.easeInOut(closeness)
    }

    static func easeOut(_ t: Double) -> Double {
        1 - pow(1 - t.clamped(to: 0...1), 2.4)
    }

    static func easeInOut(_ t: Double) -> Double {
        let x = t.clamped(to: 0...1)
        return x * x * (3 - 2 * x)
    }
}

// `DateComponentsFormatter` does not exist in swift-corelibs-foundation, so the
// interval a growth caption ends on is Apple-only. Nothing off-platform needs
// it: it is for the overlay, and the overlay only runs on a device.
//
// **The caption itself has moved to the app**, as `GrowthModel.State.caption()`
// in `Views/Localised.swift`. It used to be assembled here, out of
// `stage.displayName.lowercased()` and this formatter, and it could not stay:
// the stage name is a word somebody reads, so it belongs in the app's string
// catalogue, and lowercasing an English identifier is not how any other
// language forms the same caption. `displayName` above is what it always was —
// an identifier, for a log and for the developer panel.
#if canImport(Darwin)
public extension DateComponentsFormatter {
    static let growthDefault: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .full
        return formatter
    }()
}
#endif
