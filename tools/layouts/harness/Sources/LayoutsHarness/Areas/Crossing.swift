import SeedCore

/// The Crossing: four quarters of six.
extension Crossing.Ways: Rule {
    mutating func arrive(_ arrival: Arrival) {
        plant(seed: arrival.seedID, traits: arrival.traits)
    }

    func held(in plot: Int) -> Int { self.plot(plot).count }
    func capacity(of plot: Int) -> Int { Crossing.slots.count }
}
