import SeedCore

/// The Orchard: a guild of four under each of five trees.
extension Orchard.Ways: Rule {
    mutating func arrive(_ arrival: Arrival) {
        plant(seed: arrival.seedID, traits: arrival.traits)
    }

    func held(in plot: Int) -> Int { self.plot(plot).count }
    func capacity(of plot: Int) -> Int { Orchard.slots.count }
}
