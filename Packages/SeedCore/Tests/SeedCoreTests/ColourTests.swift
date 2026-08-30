import XCTest
@testable import SeedCore

final class ColourTests: XCTestCase {
    private func genome(_ index: Int) -> Genome {
        Genome(seed: SeedMint.mint(fromEntropy: Data("colour-\(index)".utf8)))
    }

    func testEverySchemeAndToneIsReachable() {
        var schemes = Set<ColourScheme>()
        var tones = Set<FoliageTone>()
        var variegations = Set<Variegation>()
        for index in 0..<800 {
            let palette = genome(index).palette
            schemes.insert(palette.scheme)
            tones.insert(palette.foliageTone)
            variegations.insert(palette.variegation)
        }
        XCTAssertEqual(schemes.count, ColourScheme.allCases.count)
        XCTAssertEqual(tones.count, FoliageTone.allCases.count)
        XCTAssertEqual(variegations.count, Variegation.allCases.count)
    }

    func testMostPlantsAreGreenAndTheRestAreWorthFinding() {
        var greenCount = 0
        var plainCount = 0
        for index in 0..<800 {
            let palette = genome(index).palette
            if palette.foliageTone == .green { greenCount += 1 }
            if palette.variegation == .none { plainCount += 1 }
        }
        // Green is ordinary; burgundy or silver foliage should feel like a find.
        XCTAssertGreaterThan(Double(greenCount) / 800, 0.35)
        XCTAssertLessThan(Double(greenCount) / 800, 0.60)
        XCTAssertGreaterThan(Double(plainCount) / 800, 0.50)
    }

    func testFlowersRarelyWearTheColourOfLeaves() {
        // A flower the same green as the foliage reads as another leaf.
        var greenFlowers = 0
        for index in 0..<800 where (0.26..<0.40).contains(genome(index).palette.petalBase.hue) {
            greenFlowers += 1
        }
        XCTAssertLessThan(Double(greenFlowers) / 800, 0.05, "too many green flowers")
        XCTAssertGreaterThan(greenFlowers, 0, "green flowers should be possible, just rare")
    }

    func testTheHueMapIsMonotoneSoHybridsStayBetweenTheirParents() {
        // Inheritance can land a child's draw between its parents'. If the map
        // from draw to hue folded back on itself, the child's colour could land
        // outside both — which would read as unrelated to either plant.
        var previous = -1.0
        for step in stride(from: 0.0, through: 1.0, by: 0.001) {
            let hue = flowerHue(step, allowGreen: false)
            XCTAssertGreaterThanOrEqual(hue, previous)
            previous = hue
        }
    }

    func testTheRampStaysInsideTheGamutEverywhere() {
        // Every surface of every plant is sampled from this; a value outside
        // 0...1 reaches the screen as a wrong colour rather than an error.
        for index in 0..<200 {
            let palette = genome(index).palette
            for role in MeshRole.allCases {
                for u in stride(from: 0.0, through: 1.0, by: 0.125) {
                    for v in stride(from: 0.0, through: 1.0, by: 0.125) {
                        let colour = PaletteRamp.colour(for: role, u: u, v: v, palette: palette)
                        XCTAssertTrue((0...1).contains(colour.hue), "hue \(colour.hue)")
                        XCTAssertTrue((0...1).contains(colour.saturation), "sat \(colour.saturation)")
                        XCTAssertTrue((0...1).contains(colour.brightness), "bri \(colour.brightness)")
                    }
                }
            }
        }
    }

    func testMarkingsActuallyChangeTheSurface() {
        // A picotee that does not paint the rim, or veins that do not show, are
        // traits in name only.
        guard let veined = (0..<300).lazy.map(genome).first(where: { $0.palette.veining > 0.4 }) else {
            return XCTFail("no strongly veined genome in the sample")
        }
        let onVein = PaletteRamp.colour(for: .petal, u: 0.1, v: 0.6, palette: veined.palette)
        let betweenVeins = PaletteRamp.colour(for: .petal, u: 0.2, v: 0.6, palette: veined.palette)
        XCTAssertNotEqual(onVein, betweenVeins)

        guard let rimmed = (0..<300).lazy.map(genome).first(where: { $0.palette.picotee != nil }) else {
            return XCTFail("no picotee genome in the sample")
        }
        let atRim = PaletteRamp.colour(for: .petal, u: 0.01, v: 0.5, palette: rimmed.palette)
        let atMiddle = PaletteRamp.colour(for: .petal, u: 0.5, v: 0.5, palette: rimmed.palette)
        XCTAssertNotEqual(atRim, atMiddle)
    }

    func testSpecklesAreStableForAPlantAndDifferentBetweenPlants() {
        let first = genome(1).palette
        let second = genome(2).palette
        XCTAssertEqual(
            speckle(u: 0.3, v: 0.4, seed: first.speckleSeed, frequency: 4.5),
            speckle(u: 0.3, v: 0.4, seed: first.speckleSeed, frequency: 4.5)
        )
        XCTAssertNotEqual(
            speckle(u: 0.3, v: 0.4, seed: first.speckleSeed, frequency: 4.5),
            speckle(u: 0.3, v: 0.4, seed: second.speckleSeed, frequency: 4.5)
        )
    }
}
