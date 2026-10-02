import SeedCore

/// The Long Walk: forty-eight places a plot, a plant to a place.
extension LongWalk.Walk: Rule {
    mutating func arrive(_ arrival: Arrival) {
        plant(seed: arrival.seedID, traits: arrival.traits)
    }

    func held(in plot: Int) -> Int { self.plot(plot).count }
    func capacity(of plot: Int) -> Int { LongWalk.slots.count }
}
