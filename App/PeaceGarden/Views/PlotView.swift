import SeedCore
import SwiftUI

/// The garden as a place: a floating square plot in isometric, with the plants
/// standing on it where the arrangement puts them.
///
/// This is the first of the two steps `docs/ARRANGING.md` sets out — the plot
/// and the plants at the right scale. **No terrain and no orbit yet**: the
/// ground is flat and the light is noon held still. Gestures come after this,
/// not with it.
struct PlotView: View {
    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var selected: PlantRecord?

    private var visits: GardenVisits { .shared }

    /// A plant, where it stands, and whether it has anything to say.
    private struct Standing: Identifiable {
        let record: PlantRecord
        let spot: Spot
        let growth: GrowthModel.State
        let announces: Bool

        var id: UUID { record.id }
    }

    var body: some View {
        ZStack {
            Chrome.ground.ignoresSafeArea()

            GeometryReader { proxy in
                let side = model.garden.plotSide
                let world = GardenWorlds.shared.resolve(model.garden.arrangements.first?.world)
                // A hill lifts a plant above the far corner and a ravine hangs
                // the cut below the near one, so the camera has to leave room
                // for the ground as well as for what stands on it.
                let relief = GardenWorlds.shared.relief(world: world, plotSide: side)
                let view = Isometric.fitting(
                    plotSide: side,
                    in: proxy.size,
                    headroom: GardenSprites.tallestExpected + relief.high,
                    soilDepth: GardenGround.rimDepth - relief.low
                )

                ZStack(alignment: .topLeading) {
                    plot(world: world, side: side, in: view, size: proxy.size)

                    // Far to near, and nothing else decides what covers what.
                    ForEach(standing(plotSide: side)) { standing in
                        pool(for: standing, world: world, side: side, in: view)
                        plant(standing, world: world, side: side, in: view)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header
                if model.hybrids.isEmpty { empty }
                Spacer(minLength: 0)
                grounds
            }
            .padding(.horizontal, 26)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: "Close") { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 12)
        }
        .fullScreenCover(item: $selected) { record in
            PlantDetailView(record: record).environment(model)
        }
        .onAppear {
            visits.forget(absentFrom: model.hybrids)
            visits.firstSight(of: model.hybrids, now: model.now)
        }
    }

    // MARK: Where everything stands

    /// The arrangement, with anything moved by hand standing where it was put.
    ///
    /// A template is a pure function of the plants, so this is computed on the
    /// way to the screen and stored nowhere. Only the hand placements are kept,
    /// and they are sparse: a plant grown tomorrow appears where the template
    /// says without anybody having placed it.
    private func standing(plotSide: Double) -> [Standing] {
        let plants = model.hybrids
        let bed = model.garden.arrangements.first
        let laidOut = Arrangement.spots(
            for: plants,
            template: bed?.template ?? .thematic,
            plotSide: plotSide,
            mine: model.identity?.seed
        )

        return plants.compactMap { record -> Standing? in
            guard let spot = bed?.spot(for: record) ?? laidOut[record.id] else { return nil }
            let growth = record.growth(now: model.now)
            return Standing(
                record: record,
                spot: spot,
                growth: growth,
                announces: visits.announces(record, growth: growth)
            )
        }
        .sorted { Isometric.depth($0.spot) < Isometric.depth($1.spot) }
    }

    // MARK: The ground

    /// The ground, drawn once and kept.
    ///
    /// The flat plot underneath is the fallback rather than dead code: if the
    /// world atlas is missing from the bundle the garden is still a place with
    /// an edge, instead of fourteen plants standing in the dark.
    private func plot(world: Int, side: Double, in view: Isometric, size: CGSize) -> some View {
        GardenGroundView(world: world, plotSide: side, view: view, size: size)
            .allowsHitTesting(false)
    }

    /// Where a plant's foot actually is, which on a world is not `y = 0`.
    ///
    /// A square plot **is** a heightmap, so standing a plant on terrain is a
    /// lookup rather than a problem. Drag a plant into the ravine and it goes
    /// down into it.
    private func standsAt(_ spot: Spot, world: Int, side: Double) -> Double {
        GardenWorlds.shared.height(world: world, x: spot.x, z: spot.z, plotSide: side)
    }

    // MARK: The plants

    private func plant(_ standing: Standing, world: Int, side: Double,
                       in view: Isometric) -> some View {
        GardenPlantSprite(
            genome: standing.record.genome,
            growth: standing.growth,
            foot: view.point(standing.spot, y: standsAt(standing.spot, world: world, side: side)),
            pointsPerMetre: view.pointsPerMetre
        ) {
            visits.seen(standing.record, growth: standing.growth)
            selected = standing.record
        }
    }

    /// The light finding a plant that has changed since it was last opened.
    ///
    /// A pool on the ground rather than a mark beside the plant, because the
    /// garden's own vocabulary for *look here* is light — `StageBackdrop` has
    /// done exactly this behind a single plant since August.
    @ViewBuilder
    private func pool(for standing: Standing, world: Int, side: Double,
                      in view: Isometric) -> some View {
        if standing.announces {
            let centre = view.point(standing.spot,
                                    y: standsAt(standing.spot, world: world, side: side))
            let axes = view.ellipse(radius: 0.38)

            Ellipse()
                .fill(
                    RadialGradient(
                        // Set by looking, twice. At 0.26 — which is what it was
                        // when every plant in a first-opened garden announced
                        // itself — the pools were brighter than the plants
                        // standing in them. At 0.15 a single announcing plant in
                        // a garden of fourteen could be missed entirely, which
                        // is the whole job.
                        colors: [Chrome.pinkGold.opacity(0.22), Chrome.pinkGold.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: axes.width
                    )
                )
                .frame(width: axes.width * 2, height: axes.height * 2)
                .position(centre)
                .allowsHitTesting(false)
        }
    }

    // MARK: The words

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Peace garden")
                .chromeHeading(size: 18)
                .foregroundStyle(Chrome.ink)
            Text(model.hybrids.isEmpty
                 ? "Nothing has been crossed yet"
                 : "\(model.hybrids.count) grown from meetings")
                .chromeLabel()
                .foregroundStyle(Chrome.faint)
        }
        .padding(.top, 44)
    }

    /// The grounds, picked the way you pick a plant.
    ///
    /// **Nothing here is named.** A named world is forty-two translations, and
    /// `docs/WEBSITE.md` has already recorded the ten area names becoming 420
    /// commissions at a multiplier that is now forty-two. Unnamed, the fiftieth
    /// world costs a render.
    @ViewBuilder
    private var grounds: some View {
        if GardenWorlds.shared.isLoaded {
            let chosen = GardenWorlds.shared.resolve(model.garden.arrangements.first?.world)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<GardenWorlds.shared.count, id: \.self) { world in
                        Button {
                            model.choose(world: world)
                        } label: {
                            GroundMark(world: world,
                                       plotSide: model.garden.plotSide,
                                       isChosen: world == chosen)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
            }
            .padding(.bottom, 26)
        }
    }

    private var empty: some View {
        Text("Every plant here came from meeting someone. Open Meet with another person and touch the tops of your phones together.")
            .font(.system(size: 14, weight: .light))
            .foregroundStyle(Chrome.muted)
            .lineSpacing(5)
            .frame(maxWidth: Chrome.readableWidth, alignment: .leading)
            .padding(.top, 20)
    }
}

/// One plant's still, rendered off-screen and held while it is on screen.
///
/// Its own view rather than a call in `PlotView` so that each plant renders in
/// its own task: fourteen snapshots taken in one pass would be fourteen scenes
/// built before anything appeared.
private struct GardenPlantSprite: View {
    let genome: Genome
    let growth: GrowthModel.State
    let foot: CGPoint
    let pointsPerMetre: Double
    let onTap: () -> Void

    @State private var sprite: GardenSprites.Sprite?

    var body: some View {
        Group {
            if let sprite {
                let size = GardenSprites.drawnSize(
                    metres: sprite.metres,
                    pointsPerMetre: pointsPerMetre
                )
                Image(uiImage: sprite.image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: size.width, height: size.height)
                    // **The gesture goes on the picture and not outside it.**
                    // `position` makes a view take all the space it is offered,
                    // so a tap attached after it answers anywhere on screen and
                    // the last plant drawn quietly swallows every tap in the
                    // garden — including the ones meant for the plants under it.
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onTap)
                    // A sprite is anchored at the bottom centre of its frame,
                    // which is where the plant's foot was rendered, so the
                    // position is the foot raised by half the frame.
                    .position(x: foot.x, y: foot.y - size.height / 2)
                    .transition(.opacity)
            } else {
                Color.clear
            }
        }
        .task(id: GardenSprites.key(genome: genome, growth: growth)) {
            sprite = GardenSprites.shared.sprite(genome: genome, growth: growth)
        }
    }
}

/// The ground under the garden.
///
/// Its own view so the drawing can happen off the main actor and arrive when it
/// is ready. The flat plot underneath is the fallback rather than dead code: if
/// the world atlas is missing from the bundle the garden is still a place with
/// an edge, instead of fourteen plants standing in the dark.
private struct GardenGroundView: View {
    let world: Int
    let plotSide: Double
    let view: Isometric
    let size: CGSize

    @State private var ground: UIImage?

    var body: some View {
        Group {
            if let ground {
                Image(uiImage: ground)
                    .resizable()
                    .frame(width: size.width, height: size.height)
            } else if !GardenWorlds.shared.isLoaded {
                Canvas { context, _ in
                    for (path, colour) in GardenGround.nearFaces(plotSide: plotSide, in: view) {
                        context.fill(path, with: .color(colour))
                    }
                    context.fill(
                        GardenGround.topFace(plotSide: plotSide, in: view),
                        with: .color(GardenGround.shade(base: GardenGround.turf,
                                                        normal: SIMD3(0, 1, 0)))
                    )
                }
            } else {
                Color.clear
            }
        }
        .task(id: "\(world)-\(Int(plotSide * 100))-\(Int(size.width))x\(Int(size.height))") {
            ground = await GardenTerrain.shared.image(
                world: world, plotSide: plotSide, view: view, size: size
            )
        }
    }
}

/// One ground in the row, drawn as itself rather than described.
private struct GroundMark: View {
    let world: Int
    let plotSide: Double
    let isChosen: Bool

    private static let size = CGSize(width: 64, height: 46)

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: Self.size.width, height: Self.size.height)
            } else {
                Color.clear.frame(width: Self.size.width, height: Self.size.height)
            }
        }
        // The chosen one is brighter and the rest stand back, rather than a tick
        // or a ring — a border round a landscape is a stamp on a picture.
        .opacity(isChosen ? 1 : 0.42)
        .task {
            let view = Isometric.fitting(
                plotSide: plotSide,
                in: Self.size,
                headroom: 0,
                soilDepth: GardenGround.rimDepth,
                margin: 2
            )
            // Coarser than the plot, and eight of them at once: a mark sixty
            // points wide has no grain to show, so the colour is averaged over
            // each quad rather than the stipple being sampled at one point.
            image = await GardenTerrain.shared.image(world: world, plotSide: plotSide,
                                                     view: view, size: Self.size, detail: 26)
        }
    }
}
