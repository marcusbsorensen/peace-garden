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

    func note(settled: Range<Int>) -> String? {
        let wet = settled.map { self.plot($0).filter { !$0.slot.corner.isDry }.count }.reduce(0, +)
        return wet > 0 ? "\(wet) in the pool" : nil
    }
}
