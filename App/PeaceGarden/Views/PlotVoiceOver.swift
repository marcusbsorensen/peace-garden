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
struct PlotVoiceOver: View, Equatable {
    struct Plant: Equatable {
        let record: PlantRecord
        let stage: GrowthModel.Stage
        let isAsked: Bool
        /// Where its foot is, in the plot's own coordinates.
        let foot: CGPoint
        /// About how tall it stands, in points.
        let height: CGFloat
        let width: CGFloat

        static func == (a: Plant, b: Plant) -> Bool {
            a.record.id == b.record.id && a.stage == b.stage && a.isAsked == b.isAsked
                && a.foot == b.foot && a.height == b.height && a.width == b.width
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
    let open: (PlantRecord) -> Void
    let tend: (UUID) -> Void

    nonisolated static func == (a: PlotVoiceOver, b: PlotVoiceOver) -> Bool {
        a.plants == b.plants && a.lights == b.lights
    }

    var body: some View {
        // Each element placed by its own `position`: see `PlotStack`.
        PlotStack {
            ForEach(plants, id: \.record.id) { plant in
                box(width: plant.width, height: plant.height)
                    .accessibilityLabel(Text(verbatim: plant.record.genome.name.full))
                    .accessibilityValue(value(of: plant))
                    .accessibilityHint(plant.isAsked ? Text(OtherGardener(plant.record).wouldLikeItShown) : Text(verbatim: ""))
                    .accessibilityAction { open(plant.record) }
                    .position(x: plant.foot.x, y: plant.foot.y - plant.height / 2)
            }
            ForEach(lights, id: \.id) { light in
                box(width: light.width, height: light.height)
                    .accessibilityLabel(Text(light.kind.label))
                    .accessibilityAction { tend(light.id) }
                    .position(x: light.foot.x, y: light.foot.y - light.height / 2)
            }
        }
        .accessibilityElement(children: .contain)
        // Elements only: every touch goes on to the plants beneath.
        .allowsHitTesting(false)
    }

    /// What a plant is doing, and who it was grown with — the caption under
    /// it and the line on its own screen, read as one.
    private func value(of plant: Plant) -> Text {
        let stage = Text(plant.stage.label)
        guard let name = OtherGardener(plant.record).name else { return stage }
        return stage + Text(verbatim: ", ") + Text("with \(name)")
    }

    /// An empty box the size of a thing on the plot, with its activation
    /// point a quarter of the way up, among the stem and leaves. Stood on the
    /// thing's foot by its caller, after everything it says, so the element
    /// is the box and not the whole plot that `position` takes up.
    private func box(width: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(.clear)
            .frame(width: width, height: height)
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityActivationPoint(UnitPoint(x: 0.5, y: 0.75))
    }
}
