import SeedCore

/// The Cold Frame: the frames' ranks and the tank, a lotus taking two places.
extension ColdFrame.Ways: Rule {
    mutating func arrive(_ arrival: Arrival) {
        plant(seed: arrival.seedID, traits: arrival.traits)
    }

    func held(in plot: Int) -> Int { self.plot(plot).map(\.span).reduce(0, +) }
    func capacity(of plot: Int) -> Int { ColdFrame.slots.count }
}
