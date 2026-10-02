#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// **A table of places made offline**: where an area's places stand on a
/// plot, already in the order they are offered, written into SeedCore as
/// numbers by `tools/layouts/generate.py`.
///
/// Marcus approved three moves for every area on 2 October 2026
/// (`design/garden-layouts-2026-10-02/RESEARCH.md` §*Three moves for every
/// area*), and this is the third: positions come from blue noise inside an
/// organic outline, from a sunflower and from arcs, all worked out once, by a
/// generator, and kept as literals. **With no `sin` or `pow` at run time,
/// every host agrees to the bit** — the phone, the plot service's PHP port and
/// the browser — whatever curves made the table. The libm divergence of 22
/// September 2026 (`VectorFile.swift` in the tests) is why that matters.
///
/// **And the order is the first move**: a table's places are listed in fill
/// order — its focal place first, then farthest-first, or a sunflower from
/// its middle — so a rule that takes the first free place in table order
/// leaves every count looking finished. Nothing about the order is computed
/// here either.
///
/// Each table is one generated file in `WebGardens/Tables/`, one class in
/// `Server/.api/tables/`, and where the drawing needs it one module in
/// `Server/assets/js/tables/`, all from one spec in `tools/layouts/tables/`.
/// `generate.py --check` fails CI if any of them is not what its spec makes.
public struct PlaceTable: Sendable {

    /// One place: where it stands, in metres from the middle of the plot as
    /// the table draws it (before the plot's turn), and its tags, in the order
    /// of the table's `fields`.
    public struct Place: Equatable, Sendable {
        public let x: Double
        public let z: Double
        public let tags: [Int]

        public init(x: Double, z: Double, tags: [Int]) {
            self.x = x
            self.z = z
            self.tags = tags
        }

        public var spot: Spot { Spot(x: x, z: z) }
    }

    /// A curve the drawing needs — an outline, a ride's line — in the table's
    /// frame, as the generator made it.
    public struct Curve: Sendable {
        public let closed: Bool
        public let points: [Spot]

        public init(closed: Bool, points: [Spot]) {
            self.closed = closed
            self.points = points
        }
    }

    /// The spec's name: `example`, `coppice_glade`.
    public let name: String
    /// What each tag of a place is, in order: `["coupe", "kind"]`.
    public let fields: [String]
    /// **The places of each feature variant**, `[nudge][fill order]`. One
    /// variant for a table that does not change with the plot.
    public let variants: [[Place]]
    /// Each named curve, one per feature variant.
    public let curves: [String: [Curve]]

    public init(name: String, fields: [String], variants: [[Place]], curves: [String: [Curve]]) {
        self.name = name
        self.fields = fields
        self.variants = variants
        self.curves = curves
    }

    /// How many feature variants the table has.
    public var nudges: Int { variants.count }

    /// **The places of a feature variant, in fill order.** A table of one
    /// variant answers it for every nudge, so a table that does not change
    /// with the plot sits in an area whose others do.
    public func places(nudge: Int) -> [Place] {
        variants[which(nudge)]
    }

    /// A place's tag by its field's name.
    public func tag(_ field: String, of place: Place) -> Int {
        guard let at = fields.firstIndex(of: field) else {
            preconditionFailure("\(name) has no field \(field); it has \(fields)")
        }
        return place.tags[at]
    }

    /// **Where the `index`-th place of a plot stands**: its feature variant's
    /// place, turned and mirrored as the plot is. Exact on every host.
    public func spot(_ index: Int, on variant: PlotVariant) -> Spot {
        variant.apply(places(nudge: variant.nudge)[index].spot)
    }

    /// A named curve as a plot with this variant draws it.
    public func curve(_ name: String, on variant: PlotVariant) -> Curve {
        guard let all = curves[name] else {
            preconditionFailure("\(self.name) has no curve \(name)")
        }
        let one = all[which(variant.nudge)]
        return Curve(closed: one.closed, points: one.points.map(variant.apply))
    }

    private func which(_ nudge: Int) -> Int {
        if variants.count == 1 { return 0 }
        precondition((0..<variants.count).contains(nudge),
                     "\(name) has \(variants.count) feature variants, not \(nudge + 1)")
        return nudge
    }
}
