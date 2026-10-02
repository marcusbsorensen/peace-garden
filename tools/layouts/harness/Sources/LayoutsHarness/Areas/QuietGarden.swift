import SeedCore

/// The Quiet Garden: the places on dry ground. The pool's are left out, because the live
/// garden never sends this area a lily (`Areas.genusHeads`), so no plant of its own can
/// take one.
extension QuietGarden.Room: Rule {
    mutating func arrive(_ arrival: Arrival) {
        plant(seed: arrival.seedID, traits: arrival.traits)
    }

    func held(in plot: Int) -> Int { self.plot(plot).filter { $0.slot.corner.isDry }.count }
    func capacity(of plot: Int) -> Int { QuietGarden.slots.filter { $0.corner.isDry }.count }

    /// Anything in the pool, and which of the room's groups the settled plots' empty
    /// places are in.
    func note(settled: Range<Int>) -> String? {
        let wet = settled.map { self.plot($0).filter { !$0.slot.corner.isDry }.count }.reduce(0, +)
        var empty: [String: Int] = [:]
        for plot in settled {
            let taken = Set(self.plot(plot).map(\.slot))
            for slot in QuietGarden.slots where slot.corner.isDry && !taken.contains(slot) {
                empty["\(slot.corner) \(slot.stand)", default: 0] += 1
            }
        }
        var parts = empty.sorted { $0.key < $1.key }.map { "\($0.value) \($0.key)" }
        if wet > 0 { parts.append("\(wet) in the pool") }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
