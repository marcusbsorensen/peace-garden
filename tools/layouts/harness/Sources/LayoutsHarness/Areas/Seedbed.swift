import SeedCore

/// The Seedbed: six drills of eight, a lotus taking two places.
extension Seedbed.Ways: Rule {
    mutating func arrive(_ arrival: Arrival) {
        plant(seed: arrival.seedID, traits: arrival.traits)
    }

    func held(in plot: Int) -> Int { self.plot(plot).map(\.span).reduce(0, +) }
    func capacity(of plot: Int) -> Int { Seedbed.slots.count }
}
