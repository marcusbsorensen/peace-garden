import SeedCore

/// The Coppice: three coupes of eleven.
extension Coppice.Ways: Rule {
    mutating func arrive(_ arrival: Arrival) {
        plant(seed: arrival.seedID, traits: arrival.traits)
    }

    func held(in plot: Int) -> Int { self.plot(plot).count }
    func capacity(of plot: Int) -> Int { Coppice.slots.count }
}
