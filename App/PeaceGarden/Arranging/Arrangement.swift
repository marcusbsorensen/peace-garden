import Foundation
import SeedCore

/// Where each template puts the plants nobody has moved by hand.
///
/// A template is a **pure function** from the garden to a spot per plant:
/// deterministic, stored nowhere, one function each. A template that needed
/// state would be a bed. See `docs/ARRANGING.md`.
///
/// These live in the app rather than in `SeedCore` because Thematic reads
/// `Quotes.Theme`, which is the app's. Splitting five functions across two
/// modules to keep three of them in the core would be worse than keeping them
/// together.
enum Arrangement {

    // MARK: - Where the wobble comes from

    /// A plant's own scatter, drawn from its **seed** and never from its index.
    ///
    /// The mockup used the index, which is wrong in a way that only shows up
    /// later: the sixth plant's position depends on there being five before it,
    /// so meeting somebody new reshuffles a garden the person had grown used to.
    /// The site settled this already — a plant's cell comes from two slices of
    /// its own seed hex, because the seed is a digest and there is nothing to
    /// gain by hashing it again. Same rule here.
    ///
    /// `salt` picks a different pair of bytes, so one plant can have several
    /// independent wobbles without any of them moving.
    private static func scatter(_ record: PlantRecord, salt: Int) -> (Double, Double) {
        let bytes = Array(record.seed.bytes)
        guard bytes.count >= 32 else { return (0.5, 0.5) }
        let a = bytes[(salt * 2) % bytes.count]
        let b = bytes[(salt * 2 + 1) % bytes.count]
        return (Double(a) / 255.0, Double(b) / 255.0)
    }

    // MARK: - The map

    /// The site's plan of the garden, five across and two down.
    ///
    /// Baked rather than recomputed, for the reason `docs/WEBSITE.md` gives:
    /// the ten themes' four-dimensional positions projected onto their first two
    /// principal components carry 85% of the variance, and **the map must not
    /// move**. A garden whose areas rearrange when somebody tunes a theme is a
    /// garden nobody can learn. Retuning a position is now a change to this
    /// table, and has to be made as one.
    ///
    /// Walking right goes from the still and long-span toward the moving and
    /// momentary; walking down goes from the solitary toward the shared.
    static let areas: [Quotes.Theme: (column: Int, row: Int)] = [
        .waiting: (0, 0), .ground: (1, 0), .beginnings: (2, 0),
        .renewal: (3, 0), .travel: (4, 0),
        .peace: (0, 1), .kinship: (1, 1), .pattern: (2, 1),
        .light: (3, 1), .meeting: (4, 1),
    ]

    static let columns = 5
    static let rows = 2

    /// The area a plant belongs to: the sense of the syllable **its own genus
    /// begins with**.
    ///
    /// Deliberately not `Quotes.theme(of:)`, which builds the genome
    /// `.minted`. That is right where it is used — a passage is a thing said at
    /// a meeting rather than a property of the plant it made — and wrong here,
    /// because a hybrid's traits are drawn from its parents, so the same child
    /// seed minted is a different plant with a different name.
    ///
    /// It is not a near miss. Over the fourteen crossings drawn for the mockup
    /// **all fourteen** genus heads differed: `Fenolis longifolia` minted is
    /// `Calisis vivida`, `Nyxellula rubra` is `Ithula venosa`. Every answer is a
    /// real theme, so the garden would have filed every plant under an area that
    /// has nothing to do with its name, and looked perfectly sensible doing it.
    ///
    /// `ArrangementTests` holds it to the plant's own name.
    static func theme(of plant: PlantRecord) -> Quotes.Theme {
        Quotes.Theme(genusHead: plant.genome.name.genusHead)
    }

    // MARK: - The templates

    /// Every plant's spot under one template, in metres from the plot's middle.
    static func spots(
        for plants: [PlantRecord],
        template: Template,
        plotSide: Double,
        mine: SeedID?
    ) -> [UUID: Spot] {
        // The plants are laid out inside a margin, so nothing the template
        // places ever sits on the cut edge.
        let usable = plotSide * 0.88
        switch template {
        case .thematic:   return thematic(plants, usable)
        case .nightAndDay: return nightAndDay(plants, usable)
        case .colours:    return colours(plants, usable)
        case .meetings:   return meetings(plants, usable)
        case .kinship:    return kinship(plants, usable, mine: mine)
        }
    }

    private static func thematic(_ plants: [PlantRecord], _ side: Double) -> [UUID: Spot] {
        var out: [UUID: Spot] = [:]
        let cellWidth = side / Double(columns)
        let cellDepth = side / Double(rows)
        for plant in plants {
            let cell = areas[theme(of: plant)] ?? (column: 2, row: 0)
            let (jx, jz) = scatter(plant, salt: 1)
            out[plant.id] = Spot(
                x: -side / 2 + (Double(cell.column) + 0.18 + 0.64 * jx) * cellWidth,
                z: -side / 2 + (Double(cell.row) + 0.20 + 0.60 * jz) * cellDepth
            )
        }
        return out
    }

    /// Midnight at one edge, noon at the other.
    ///
    /// It reads `Genome.Tempo.opensByDay` — the **trait** — and never the genus
    /// head. Nyx and Umbr mean the passage theme `waiting`, which is a mood
    /// rather than a behaviour, and a *Nyxia* may open at noon. Sorting by the
    /// name would put that plant at the midnight end and look almost right,
    /// which is the worst way to be wrong.
    private static func nightAndDay(_ plants: [PlantRecord], _ side: Double) -> [UUID: Spot] {
        var out: [UUID: Spot] = [:]
        for plant in plants {
            let byDay = plant.genome.tempo.opensByDay
            let (jx, jz) = scatter(plant, salt: 2)
            // Two bands with room between them, each spread by the plant's own
            // wobble rather than by its place in a list.
            let centre = byDay ? 0.30 : -0.30
            out[plant.id] = Spot(
                x: side * (centre + (jx - 0.5) * 0.26),
                z: side * ((jz - 0.5) * 0.82)
            )
        }
        return out
    }

    /// Hue straight onto the long axis, in drifts.
    ///
    /// **Not a sort.** Sorting and then laying the result out in order makes a
    /// plant's place depend on how many plants are bluer than it, so one new
    /// meeting moves everything after it. Hue is already a number between nought
    /// and one; using it directly is both simpler and stable.
    ///
    /// It will look more like Kinship than it sounds: palette is inherited, so
    /// plants grown with one person already share a hue.
    private static func colours(_ plants: [PlantRecord], _ side: Double) -> [UUID: Spot] {
        var out: [UUID: Spot] = [:]
        for plant in plants {
            let hue = plant.genome.palette.petalBase.hue
            let (_, jz) = scatter(plant, salt: 3)
            let (jitterX, _) = scatter(plant, salt: 4)
            out[plant.id] = Spot(
                x: side * ((hue - 0.5) * 0.88 + (jitterX - 0.5) * 0.08),
                z: side * ((jz - 0.5) * 0.84)
            )
        }
        return out
    }

    /// A walk through the meetings in the order they happened.
    ///
    /// The one template where an order is the point, so an index is honest here.
    /// It is stable in the way that matters: a new plant is the newest, so it
    /// goes on the end and moves nothing.
    private static func meetings(_ plants: [PlantRecord], _ side: Double) -> [UUID: Spot] {
        let ordered = plants.sorted { $0.birth < $1.birth }
        var out: [UUID: Spot] = [:]
        guard !ordered.isEmpty else { return out }
        for (index, plant) in ordered.enumerated() {
            let t = (Double(index) + 0.5) / Double(ordered.count)
            let (_, jz) = scatter(plant, salt: 5)
            out[plant.id] = Spot(
                x: side * (t - 0.5) * 0.9,
                z: side * ((t - 0.5) * 0.5 + (jz - 0.5) * 0.30)
            )
        }
        return out
    }

    /// Plants sharing a parent stand together.
    ///
    /// It groups on whichever parent is **not** your own seed, so a group is one
    /// person. Not `Pollination.pairID`, which hashes the pair into a theme and
    /// cannot be asked which parent it came from.
    ///
    /// The group's place on the plot comes from that peer's seed, so it does not
    /// move when somebody new is met, and somebody who introduces themselves
    /// differently next time still lands in the same group — the name is told
    /// and the parent seed is not.
    private static func kinship(_ plants: [PlantRecord], _ side: Double, mine: SeedID?) -> [UUID: Spot] {
        var out: [UUID: Spot] = [:]
        var groups: [SeedID: [PlantRecord]] = [:]
        var solitary: [PlantRecord] = []

        for plant in plants {
            guard let (a, b) = plant.lineage.parents else {
                solitary.append(plant)
                continue
            }
            let peer = (a == mine) ? b : ((b == mine) ? a : a)
            groups[peer, default: []].append(plant)
        }

        for (peer, members) in groups {
            let bytes = Array(peer.bytes)
            let cx = (Double(bytes.first ?? 0) / 255.0 - 0.5) * 0.74
            let cz = (Double(bytes.dropFirst().first ?? 0) / 255.0 - 0.5) * 0.74

            // **A member's place in its group comes from its own seed, and the
            // group's radius is fixed.** The first version put each plant at an
            // angle of `index / members.count` inside a radius that grew with
            // the count, so meeting the same person again spun everyone you had
            // already grown with them. `ArrangementTests` caught it; nothing
            // else would have, because the picture is perfectly reasonable —
            // it is just a different one every time.
            //
            // A fixed radius means a group of ten is denser than a group of
            // two, which says something true: somebody you have met ten times
            // is a thicket. Two plants may land close enough to overlap, and
            // that is allowed for the reason `docs/WEBSITE.md` gives about the
            // site's shared cells — more than one plant standing together is a
            // thing a garden does.
            for plant in members {
                let (jAngle, jRadius) = scatter(plant, salt: 6)
                let angle = jAngle * 2 * .pi
                let radius = 0.055 + 0.075 * jRadius.squareRoot()
                out[plant.id] = Spot(
                    x: side * (cx + cos(angle) * radius),
                    z: side * (cz + sin(angle) * radius)
                )
            }
        }

        for plant in solitary {
            let (jx, jz) = scatter(plant, salt: 7)
            out[plant.id] = Spot(x: side * (jx - 0.5) * 0.9, z: side * (jz - 0.5) * 0.9)
        }
        return out
    }
}
