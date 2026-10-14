import SeedCore
import SwiftUI

/// What VoiceOver finds in the garden: one element for each plant and each
/// light on the plot, standing over the picture of it.
///
/// **The garden was invisible to VoiceOver** (mass test, 13 October, finding
/// 3): every plant was an unlabelled picture with no action, so a plant's
/// screen could not be opened from the garden at all, and the sky and the
/// ground were more unlabelled pictures in the way. The drawing is now hidden
/// from VoiceOver (`PlotView` hides the sky and the plot) and this layer says
/// what is there instead.
///
/// **A layer of its own, beside the drawing and not in it.** It reads where
/// each plant stands from the same arrangement the plot is drawn from, and is
/// moved by the plot's own zoom, pan and lean, so each element stays over its
/// plant; but nothing here draws, and nothing in the drawing knows it exists.
/// It is equatable on where things stand and what they are doing, so a pan or
/// a pinch — which moves the layer, not what is in it — does not rebuild it.
///
/// - A **plant** says its name, then what it is doing and who it was grown
///   with, in the words its own screen uses. Activating it opens that screen,
///   as a tap on the plant does. A plant somebody has asked to show says so as
///   its hint, in the sentence the asking screen uses.
/// - A **light** says what it is. Activating it opens the small panel a long
///   press opens, whose marks turn it (the figures) and make it smaller or
///   larger; the escape gesture shuts the panel again.
///
/// Carrying a plant or a light is still the long press and drag, which
/// VoiceOver passes through with a double tap held: each element's activation
/// point is low on the plant, where its stem and leaves answer a finger.
///
/// Nothing here mirrors under right to left, as the plot does not.
///
/// **Always there, and a big garden's made a slice a frame** (Marcus, 14
/// October: 28C). Voice Control and Full Keyboard Access read these elements
/// too, and iOS has no way to ask whether either is running, so the layer is
/// built whatever is on. Up to `atOnce` plants it is made with the plot, as
/// the tests read it. Beyond that, made in one go it held the main thread for
/// a third of a second at five hundred plants, so it waits until the garden
/// has filled in — every plant has its pictures — and then makes `perFrame`
/// plants' elements a frame, each slice a view of its own that is not made
/// again when the next one arrives. With VoiceOver or Switch Control running
/// it does not wait for the pictures, which neither needs.
///
/// The elements stand in a fixed order, newest plant first, so that a turn of
/// the plot moves each element rather than making it again in another slice;
/// VoiceOver is given far to near by `reading`.
struct PlotVoiceOver: View, Equatable {
    struct Plant: Equatable {
        let record: PlantRecord
        /// Its name, read off the genome the plot already has, rather than
        /// built from the seed again for every element.
        let name: String
        let stage: GrowthModel.Stage
        let isAsked: Bool
        /// Where its foot is, in the plot's own coordinates.
        let foot: CGPoint
        /// About how tall it stands, in points.
        let height: CGFloat
        let width: CGFloat
        /// Where VoiceOver comes to it: the far plants first, as the plot
        /// is drawn, and the plant in hand last.
        let reading: Double

        static func == (a: Plant, b: Plant) -> Bool {
            a.record.id == b.record.id && a.stage == b.stage && a.isAsked == b.isAsked
                && a.foot == b.foot && a.height == b.height && a.width == b.width
                && a.reading == b.reading
                && a.record.encounter?.peerDisplayName == b.record.encounter?.peerDisplayName
        }
    }

    struct Light: Equatable {
        let id: UUID
        let kind: LampKind
        let foot: CGPoint
        let height: CGFloat
        let width: CGFloat
    }

    let plants: [Plant]
    let lights: [Light]
    /// VoiceOver or Switch Control is running, so a big garden's elements
    /// are made without waiting for its pictures.
    let assistive: Bool
    let open: (PlantRecord) -> Void
    let tend: (UUID) -> Void

    /// Up to this many plants, every element is made at once, with the plot.
    static let atOnce = 100
    /// Beyond that, this many plants' elements a frame: measured on 14
    /// October with `GardenPerfTests.testOpenABigGarden`
    /// (`design/garden-perf-2026-10-14/README.md`, *Not resolved*, 1).
    static let perFrame = 12

    /// How many plants of a big garden have their elements so far.
    @State private var said = 0

    /// How far a big garden's layer has got: what the test that measures it
    /// waits on, as the mass test waits on `GardenSprites.outstanding`.
    static private(set) var progress = (said: 0, of: 0)

    nonisolated static func == (a: PlotVoiceOver, b: PlotVoiceOver) -> Bool {
        a.plants == b.plants && a.lights == b.lights && a.assistive == b.assistive
    }

    var body: some View {
        let count = plants.count <= Self.atOnce ? plants.count : min(said, plants.count)
        // Each element placed by its own `position`: see `PlotStack`.
        PlotStack {
            ForEach(Array(stride(from: 0, to: count, by: Self.perFrame)), id: \.self) { start in
                Slice(plants: plants[start..<min(count, start + Self.perFrame)], open: open)
                    .equatable()
            }
            ForEach(lights, id: \.id) { light in
                Self.box(width: light.width, height: light.height)
                    .accessibilityLabel(Text(light.kind.label))
                    .accessibilityAction { tend(light.id) }
                    .position(x: light.foot.x, y: light.foot.y - light.height / 2)
            }
        }
        .accessibilityElement(children: .contain)
        // Elements only: every touch goes on to the plants beneath.
        .allowsHitTesting(false)
        .task(id: Wanted(plants: plants.count, assistive: assistive)) { await sayTheRest() }
    }

    private struct Wanted: Equatable {
        let plants: Int
        let assistive: Bool
    }

    /// A big garden's elements, `perFrame` plants a frame, once its pictures
    /// are all in.
    private func sayTheRest() async {
        let total = plants.count
        guard total > Self.atOnce, said < total else { return }
        if !assistive {
            // Filled in: nothing waited for, twice a beat apart, since a plant
            // asks for its pictures a moment after it first stands on the plot.
            var quiet = 0
            while quiet < 2 {
                try? await Task.sleep(for: .milliseconds(250))
                if Task.isCancelled { return }
                quiet = GardenSprites.shared.outstanding == 0 ? quiet + 1 : 0
            }
        }
        while said < total {
            said = min(total, said + Self.perFrame)
            Self.progress = (said, total)
            // A frame, so each slice is drawn before the next is made.
            try? await Task.sleep(for: .milliseconds(16))
            if Task.isCancelled { return }
        }
    }

    /// One slice of the plants' elements: a view of its own, compared on
    /// what it holds, so the slices already made are left alone when the
    /// next one arrives.
    private struct Slice: View, Equatable {
        let plants: ArraySlice<Plant>
        let open: (PlantRecord) -> Void

        nonisolated static func == (a: Slice, b: Slice) -> Bool {
            a.plants == b.plants
        }

        var body: some View {
            PlotStack {
                ForEach(plants, id: \.record.id) { plant in
                    PlotVoiceOver.box(width: plant.width, height: plant.height)
                        .accessibilityLabel(Text(verbatim: plant.name))
                        .accessibilityValue(value(of: plant))
                        .accessibilityHint(plant.isAsked ? Text(OtherGardener(plant.record).wouldLikeItShown) : Text(verbatim: ""))
                        .accessibilityAction { open(plant.record) }
                        .accessibilitySortPriority(plant.reading)
                        .position(x: plant.foot.x, y: plant.foot.y - plant.height / 2)
                }
            }
        }

        /// What a plant is doing, and who it was grown with — the caption
        /// under it and the line on its own screen, read as one.
        private func value(of plant: Plant) -> Text {
            let stage = Text(plant.stage.label)
            guard let name = OtherGardener(plant.record).name else { return stage }
            return stage + Text(verbatim: ", ") + Text("with \(name)")
        }
    }

    /// An empty box the size of a thing on the plot, with its activation
    /// point a quarter of the way up, among the stem and leaves. Stood on the
    /// thing's foot by its caller, after everything it says, so the element
    /// is the box and not the whole plot that `position` takes up.
    /// `Color.clear`, which draws nothing, rather than a shape filled with
    /// nothing.
    fileprivate static func box(width: CGFloat, height: CGFloat) -> some View {
        Color.clear
            .frame(width: width, height: height)
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityActivationPoint(UnitPoint(x: 0.5, y: 0.75))
    }
}
