import SeedCore

/// The Glasshouse: the staging's pots and the border.
extension Glasshouse.Ways: Rule {
    mutating func arrive(_ arrival: Arrival) {
        plant(seed: arrival.seedID, traits: arrival.traits)
    }

    func held(in plot: Int) -> Int { self.plot(plot).count }
    func capacity(of plot: Int) -> Int { Glasshouse.slots.count }
}
