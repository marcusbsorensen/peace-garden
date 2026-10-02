import SeedCore

/// The Knot Garden: eight compartments of four.
extension KnotGarden.Ways: Rule {
    mutating func arrive(_ arrival: Arrival) {
        plant(seed: arrival.seedID, traits: arrival.traits)
    }

    func held(in plot: Int) -> Int { self.plot(plot).count }
    func capacity(of plot: Int) -> Int { KnotGarden.slots.count }
}
