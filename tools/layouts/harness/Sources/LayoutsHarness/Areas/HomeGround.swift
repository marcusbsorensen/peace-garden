import SeedCore

/// The Home Ground: each bed holds what its crop is sown at (27 spires, 14 umbels, 30
/// rosettes), so a plot's places are its claimed beds'. A bed nobody has claimed has no
/// spacing yet and counts for nothing; the note says how many settled beds that is.
extension HomeGround.Ways: Rule {
    mutating func arrive(_ arrival: Arrival) {
        plant(seed: arrival.seedID, traits: arrival.traits)
    }

    func held(in plot: Int) -> Int { self.plot(plot).count }
    func capacity(of plot: Int) -> Int {
        (0..<HomeGround.beds).compactMap { crop(of: $0, in: plot)?.capacity }.reduce(0, +)
    }

    func note(settled: Range<Int>) -> String? {
        let open = settled.map { plot in (0..<HomeGround.beds).filter { crop(of: $0, in: plot) == nil }.count }
            .reduce(0, +)
        return open > 0 ? "\(open) settled \(open == 1 ? "bed" : "beds") unsown" : nil
    }
}
