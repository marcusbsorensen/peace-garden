import SeedCore
import SwiftUI

/// The garden as a place: a floating square plot in isometric, standing on a
/// chosen ground, lit by the sun and moon going round it, with the plants
/// standing where the arrangement puts them — or where somebody has put them.
///
/// **Four gestures, and one conflict between them.** Pinch zooms, two fingers
/// turn the plot a quarter at a time, one finger pans — and one finger is also
/// what moves a plant. So a plant is lifted by a long press before it can be
/// dragged, with a tap of feedback to say it is in hand. Every plant here is a
/// meeting with somebody, and nudging one by accident while trying to look at it
/// is a worse failure than waiting a third of a second to pick it up.
/// `docs/ARRANGING.md` §*One finger cannot do two things*.
struct PlotView: View {
    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var selected: PlantRecord?

    @AppStorage(Chrome.daylightKey) private var daylightRaw = GardenDaylight.byTheClock.rawValue

    // MARK: Looking at it

    /// Quarter-turns of the plot. Stepped rather than free, because isometric
    /// has four natural views and between them the ground's own axes stop being
    /// aligned to the screen, which is what makes it legible.
    @State private var turn = 0
    /// How far the plot is turned while two fingers are still on it. Shown as a
    /// slight lean so the gesture is felt, then snapped to a quarter on release.
    @State private var turning: Angle = .zero

    @State private var zoom: CGFloat = 1
    @GestureState private var pinching: CGFloat = 1
    @State private var pan: CGSize = .zero
    @GestureState private var panning: CGSize = .zero

    // MARK: Moving a plant

    /// A plant in hand: which one, and where its foot is being held, in the
    /// plot's own unzoomed coordinates.
    private struct Held: Equatable {
        let id: UUID
        var foot: CGPoint
    }
    @State private var held: Held?

    /// A light in hand, the same way.
    @State private var heldLamp: Held?
    /// Counted rather than flagged, so every lift is its own tap of feedback.
    @State private var lifts = 0

    private var visits: GardenVisits { .shared }

    /// A plant, where it stands, and whether it has anything to say.
    private struct Standing: Identifiable {
        let record: PlantRecord
        let spot: Spot
        let growth: GrowthModel.State
        let announces: Bool

        var id: UUID { record.id }
    }

    /// The hour the garden is being looked at, as a fraction.
    ///
    /// **Night falls by the clock.** A garden that is dark because it is dark
    /// outside is a place; a garden that is dark because somebody pressed a
    /// button is a theme picker. It reads `model.now`, so the developer clock
    /// winds the sun round with everything else.
    private var hour: Double {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: model.now)
        let actual = Double(parts.hour ?? 12) + Double(parts.minute ?? 0) / 60
        return (GardenDaylight(rawValue: daylightRaw) ?? .byTheClock).hour(when: actual)
    }

    var body: some View {
        ZStack {
            Chrome.ground.ignoresSafeArea()

            GeometryReader { proxy in
                let light = GardenGround.Light.at(hour: hour)
                let side = model.garden.plotSide
                let world = GardenWorlds.shared.resolve(model.garden.arrangements.first?.world)
                // A hill lifts a plant above the far corner and a ravine hangs
                // the cut below the near one, so the camera has to leave room
                // for the ground as well as for what stands on it.
                let relief = GardenWorlds.shared.relief(world: world, plotSide: side)
                var view = Isometric.fitting(
                    plotSide: side,
                    in: proxy.size,
                    headroom: GardenSprites.tallestExpected + relief.high,
                    soilDepth: GardenGround.rimDepth - relief.low
                )
                let _ = (view.turn = turn)

                let lamps = model.garden.arrangements.first?.allLamps ?? []
                let glow = GardenLamps.glow(in: light)

                ZStack(alignment: .topLeading) {
                    GardenSky(light: light, date: model.now, view: view)

                    ZStack(alignment: .topLeading) {
                        plot(world: world, side: side, in: view, size: proxy.size, light: light)

                        // The lights' pools, under everything that stands, so
                        // a plant stands *in* the light rather than behind it.
                        ForEach(lamps) { lamp in
                            lampPool(lamp, world: world, side: side, in: view, glow: glow)
                        }

                        // Far to near, and nothing else decides what covers
                        // what — except something in hand, which is above
                        // everything until it is put down.
                        ForEach(things(plotSide: side, lamps: lamps, in: view)) { thing in
                            switch thing {
                            case .plant(let standing):
                                pool(for: standing, world: world, side: side, in: view)
                                plant(standing, world: world, side: side, in: view,
                                      light: light, lamps: lamps, glow: glow)
                            case .lamp(let lamp):
                                self.lamp(lamp, world: world, side: side, in: view, glow: glow)
                            }
                        }
                    }
                    .coordinateSpace(name: "plot")
                    .scaleEffect(zoom * pinching)
                    .offset(x: pan.width + panning.width, y: pan.height + panning.height)
                    .rotationEffect(turning)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .contentShape(Rectangle())
                .gesture(looking(in: proxy.size))
                .simultaneousGesture(panGesture(in: proxy.size))
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
            .allowsHitTesting(true)
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: "Close") { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 12)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: lifts)
        .sensoryFeedback(.selection, trigger: turn)
        .fullScreenCover(item: $selected) { record in
            PlantDetailView(record: record).environment(model)
        }
        .onAppear {
            visits.forget(absentFrom: model.hybrids)
            visits.firstSight(of: model.hybrids, now: model.now)
        }
    }

    // MARK: The gestures

    /// Pinch and turn, together, because two fingers do both at once and people
    /// expect them to.
    private func looking(in size: CGSize) -> some Gesture {
        let pinch = MagnifyGesture()
            .updating($pinching) { value, state, _ in
                state = min(max(value.magnification, 1 / zoom), 3 / zoom)
            }
            .onEnded { value in
                withAnimation(.easeOut(duration: 0.25)) {
                    zoom = min(max(zoom * value.magnification, 1), 3)
                    if zoom <= 1.001 { pan = .zero }
                    pan = clamped(pan, in: size)
                }
            }

        // A lean while the fingers are down, capped so it reads as intent and
        // not as the plot spinning; a quarter-turn once they lift, if the lean
        // went far enough to mean it. Clockwise on the glass turns the plot
        // clockwise as it is seen, which is a negative turn about `+y`.
        let rotate = RotateGesture()
            .onChanged { value in
                let degrees = min(max(value.rotation.degrees, -24), 24)
                turning = .degrees(degrees)
            }
            .onEnded { value in
                let degrees = value.rotation.degrees
                withAnimation(.easeOut(duration: 0.2)) { turning = .zero }
                if degrees > 28 { turn -= 1 } else if degrees < -28 { turn += 1 }
            }

        return pinch.simultaneously(with: rotate)
    }

    /// One finger on the ground moves the view, once there is somewhere to move
    /// it to. At the fitted size the whole plot is already on screen, so there
    /// is nothing to pan and a stray swipe does nothing.
    private func panGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($panning) { value, state, _ in
                guard zoom > 1.001, held == nil else { return }
                state = value.translation
            }
            .onEnded { value in
                guard zoom > 1.001, held == nil else { return }
                pan = clamped(CGSize(width: pan.width + value.translation.width,
                                     height: pan.height + value.translation.height),
                              in: size)
            }
    }

    /// Far enough to reach any corner of the plot at this zoom, and no further.
    private func clamped(_ offset: CGSize, in size: CGSize) -> CGSize {
        let reachX = size.width * (zoom - 1) / 2
        let reachY = size.height * (zoom - 1) / 2
        return CGSize(width: min(max(offset.width, -reachX), reachX),
                      height: min(max(offset.height, -reachY), reachY))
    }

    // MARK: Where everything stands

    /// The arrangement, with anything moved by hand standing where it was put.
    ///
    /// A template is a pure function of the plants, so this is computed on the
    /// way to the screen and stored nowhere. Only the hand placements are kept,
    /// and they are sparse: a plant grown tomorrow appears where the template
    /// says without anybody having placed it.
    private func standing(plotSide: Double, in view: Isometric) -> [Standing] {
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
        .sorted { a, b in
            if a.id == held?.id { return false }
            if b.id == held?.id { return true }
            return view.depth(a.spot) < view.depth(b.spot)
        }
    }

    /// Anything standing on the plot, so plants and lights can be drawn in one
    /// far-to-near order. A lantern behind a plant is behind it.
    private enum Thing: Identifiable {
        case plant(Standing)
        case lamp(Lamp)

        var id: UUID {
            switch self {
            case .plant(let standing): return standing.id
            case .lamp(let lamp): return lamp.id
            }
        }

        var spot: Spot {
            switch self {
            case .plant(let standing): return standing.spot
            case .lamp(let lamp): return lamp.spot
            }
        }
    }

    private func things(plotSide: Double, lamps: [Lamp], in view: Isometric) -> [Thing] {
        let inHand: Set<UUID> = Set([held?.id, heldLamp?.id].compactMap { $0 })
        let all = standing(plotSide: plotSide, in: view).map(Thing.plant)
            + lamps.filter { $0.known != nil }.map(Thing.lamp)

        return all.sorted { a, b in
            if inHand.contains(a.id) { return false }
            if inHand.contains(b.id) { return true }
            return view.depth(a.spot) < view.depth(b.spot)
        }
    }

    // MARK: The ground

    /// The ground, drawn once and kept.
    private func plot(world: Int, side: Double, in view: Isometric, size: CGSize,
                      light: GardenGround.Light) -> some View {
        GardenGroundView(world: world, plotSide: side, view: view, size: size, light: light)
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
                       in view: Isometric, light: GardenGround.Light,
                       lamps: [Lamp], glow: Double) -> some View {
        let resting = view.point(standing.spot,
                                 y: standsAt(standing.spot, world: world, side: side))
        let inHand = held?.id == standing.id

        return GardenPlantSprite(
            genome: standing.record.genome,
            growth: standing.growth,
            foot: inHand ? (held?.foot ?? resting) : resting,
            pointsPerMetre: view.pointsPerMetre,
            light: light,
            hour: hour,
            turn: turn,
            isHeld: inHand,
            lamplight: GardenLamps.lift(at: standing.spot, from: lamps),
            glow: glow,
            onTap: {
                visits.seen(standing.record, growth: standing.growth)
                selected = standing.record
            },
            onLift: {
                held = Held(id: standing.id, foot: resting)
                lifts += 1
            },
            onMove: { travel in
                held?.foot = CGPoint(x: resting.x + travel.width, y: resting.y + travel.height)
            },
            onDrop: { travel in
                let foot = CGPoint(x: resting.x + travel.width, y: resting.y + travel.height)
                put(standing.record, at: foot, world: world, side: side, in: view)
            }
        )
    }

    /// Where a dropped plant lands, and keeping it on the plot.
    ///
    /// Clamped inside the rim rather than refused, because a plant dropped just
    /// over the edge was meant to be at the edge. The finger is where the *foot*
    /// is, so the ground has to be found with that place's own height put back —
    /// the inverse runs twice, and on the steepest wall of the ravine twice is
    /// enough.
    private func put(_ plant: PlantRecord, at foot: CGPoint, world: Int, side: Double,
                     in view: Isometric) {
        let relief = GardenWorlds.shared.relief(world: world, plotSide: side)
        let found = view.ground(at: foot, height: { spot in
            standsAt(spot, world: world, side: side)
        }, between: relief.low, and: relief.high)
        let edge = side / 2 * 0.96
        let spot = Spot(x: min(max(found.x, -edge), edge), z: min(max(found.z, -edge), edge))

        withAnimation(.spring(duration: 0.3)) {
            model.place(plant, at: spot)
            held = nil
        }
    }

    // MARK: The lights

    /// A light's own pool on the ground, following it while it is in hand.
    @ViewBuilder
    private func lampPool(_ lamp: Lamp, world: Int, side: Double, in view: Isometric,
                          glow: Double) -> some View {
        if let kind = lamp.known {
            let colour = GardenLamps.swiftUIColour(GardenLamps.colour(of: kind))
            let resting = view.point(lamp.spot, y: standsAt(lamp.spot, world: world, side: side))
            let centre = heldLamp?.id == lamp.id ? (heldLamp?.foot ?? resting) : resting
            let axes = view.ellipse(radius: GardenLamps.reach(of: kind) * 0.72)

            // **Elliptical, not radial.** A pool lies flat on the ground, so it
            // is drawn as an ellipse; a circular gradient inside a flattened
            // ellipse is cut off at the ellipse's short sides while still bright,
            // and came out as a hard-edged coloured disc on the grass.
            Ellipse()
                .fill(EllipticalGradient(
                    colors: [colour.opacity(0.34 * glow * GardenLamps.pool(of: kind)),
                             colour.opacity(0)],
                    center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5
                ))
                .frame(width: axes.width * 2, height: axes.height * 2)
                .position(centre)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
        }
    }

    /// A light standing on the plot. Lifted and carried the same way a plant is;
    /// carried off the edge of the plot, it is gone.
    @ViewBuilder
    private func lamp(_ lamp: Lamp, world: Int, side: Double, in view: Isometric,
                      glow: Double) -> some View {
        if let kind = lamp.known {
            let metre = view.pointsPerMetre
            let resting = view.point(lamp.spot, y: standsAt(lamp.spot, world: world, side: side))
            let inHand = heldLamp?.id == lamp.id
            let foot = inHand ? (heldLamp?.foot ?? resting) : resting
            let seed = Int(lamp.id.uuid.0) << 8 | Int(lamp.id.uuid.1)

            LampFigure(kind: kind, glow: glow, pointsPerMetre: metre, seed: seed)
                .allowsHitTesting(false)
                // Only the light itself answers a finger, not the whole metre of
                // air its frame takes up, or a lantern would steal every touch
                // meant for the plant behind it.
                .overlay(alignment: .bottom) {
                    Color.clear
                        .frame(width: 0.32 * metre,
                               height: (GardenLamps.height(of: kind) + 0.14) * metre)
                        .contentShape(Rectangle())
                        .gesture(carrying(lamp, from: resting, world: world, side: side, in: view))
                }
                .scaleEffect(inHand ? 1.06 : 1, anchor: .bottom)
                .offset(y: inHand ? -8 : 0)
                .position(x: foot.x, y: foot.y - 0.6 * metre)
        }
    }

    private func carrying(_ lamp: Lamp, from resting: CGPoint, world: Int, side: Double,
                          in view: Isometric) -> some Gesture {
        LongPressGesture(minimumDuration: 0.33)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("plot")))
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                let travel = drag?.translation ?? .zero
                if heldLamp?.id != lamp.id { lifts += 1 }
                heldLamp = Held(id: lamp.id, foot: CGPoint(x: resting.x + travel.width,
                                                           y: resting.y + travel.height))
            }
            .onEnded { value in
                guard case .second(true, let drag) = value else {
                    heldLamp = nil
                    return
                }
                let travel = drag?.translation ?? .zero
                let foot = CGPoint(x: resting.x + travel.width, y: resting.y + travel.height)
                let found = view.ground(at: foot)
                let half = side / 2

                withAnimation(.spring(duration: 0.3)) {
                    if abs(found.x) > half + 0.15 || abs(found.z) > half + 0.15 {
                        model.removeLamp(lamp.id)
                    } else {
                        let relief = GardenWorlds.shared.relief(world: world, plotSide: side)
                        let landed = view.ground(at: foot, height: { spot in
                            standsAt(spot, world: world, side: side)
                        }, between: relief.low, and: relief.high)
                        let edge = half * 0.96
                        model.moveLamp(lamp.id, to: Spot(x: min(max(landed.x, -edge), edge),
                                                         z: min(max(landed.z, -edge), edge)))
                    }
                    heldLamp = nil
                }
            }
    }

    /// Where a new light is put down: near the middle, each one a little round
    /// from the last on a golden-angle spiral, so a second lantern does not land
    /// on top of the first and nothing about it depends on anything but how
    /// many are out already.
    private func freshSpot(side: Double) -> Spot {
        let count = Double(model.garden.arrangements.first?.allLamps.count ?? 0)
        let angle = count * 2.399_963
        let radius = min(0.35 + 0.2 * count.squareRoot(), side / 2 * 0.8)
        return Spot(x: cos(angle) * radius, z: sin(angle) * radius)
    }

    /// The light finding a plant that has changed since it was last opened.
    ///
    /// A pool on the ground rather than a mark beside the plant, because the
    /// garden's own vocabulary for *look here* is light — `StageBackdrop` has
    /// done exactly this behind a single plant since August.
    @ViewBuilder
    private func pool(for standing: Standing, world: Int, side: Double,
                      in view: Isometric) -> some View {
        if standing.announces, held?.id != standing.id {
            let centre = view.point(standing.spot,
                                    y: standsAt(standing.spot, world: world, side: side))
            let axes = view.ellipse(radius: 0.38)

            Ellipse()
                .fill(
                    EllipticalGradient(
                        // Set by looking, twice. At 0.26 — which is what it was
                        // when every plant in a first-opened garden announced
                        // itself — the pools were brighter than the plants
                        // standing in them. At 0.15 a single announcing plant in
                        // a garden of fourteen could be missed entirely, which
                        // is the whole job. Elliptical so it fades to nothing at
                        // every edge, rather than being cut off at the short ones.
                        colors: [Chrome.pinkGold.opacity(0.22), Chrome.pinkGold.opacity(0)],
                        center: .center,
                        startRadiusFraction: 0,
                        endRadiusFraction: 0.5
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
        .allowsHitTesting(false)
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
                    // The lights to put out, first, and unnamed like the worlds:
                    // each is drawn as itself and added where it can be seen,
                    // then carried to where it is wanted.
                    ForEach(LampKind.allCases, id: \.self) { kind in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                model.addLamp(kind, at: freshSpot(side: model.garden.plotSide))
                            }
                        } label: {
                            LampFigure(kind: kind, glow: 1, pointsPerMetre: 40, seed: 7)
                                .frame(width: 40, height: 48)
                                .clipped()
                        }
                        .buttonStyle(.plain)
                    }

                    Hairline()
                        .frame(width: 1, height: 32)
                        .opacity(0.5)

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
            .allowsHitTesting(false)
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
    let light: GardenGround.Light
    let hour: Double
    let turn: Int
    let isHeld: Bool
    /// How much the lights nearby lift this plant, and in what colour.
    let lamplight: (amount: Double, colour: SIMD3<Double>)
    let glow: Double
    let onTap: () -> Void
    let onLift: () -> Void
    let onMove: (CGSize) -> Void
    let onDrop: (CGSize) -> Void

    @State private var before: GardenSprites.Sprite?
    @State private var after: GardenSprites.Sprite?
    @State private var lifting = false

    private var between: (before: Int, after: Int, blend: Double) {
        GardenGround.Light.steps(at: hour)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let sprite = before ?? after {
                let size = GardenSprites.drawnSize(metres: sprite.metres,
                                                   pointsPerMetre: pointsPerMetre)
                shadow(of: sprite, size: size)

                // Two renders crossfaded rather than one snapped to. The plants
                // are meshes nobody wants to rebuild at sixty frames a second,
                // so they are drawn at eight points round the clock; stepping
                // between them without the fade is what makes the sun jump.
                ZStack(alignment: .topLeading) {
                    picture(before, size: size, opacity: 1)
                    picture(after, size: size, opacity: between.blend)

                    // Lit by the lights near it: the plant again, tinted by
                    // their colour and *added*, so it brightens in proportion to
                    // its own colour the way light does — a pale petal comes up
                    // more than a dark leaf — rather than being washed over.
                    if lamplight.amount > 0.01, let lit = before ?? after {
                        Image(uiImage: lit.image)
                            .resizable()
                            .frame(width: size.width, height: size.height)
                            .colorMultiply(GardenLamps.swiftUIColour(lamplight.colour))
                            .blendMode(.plusLighter)
                            .opacity(lamplight.amount * glow * 0.9)
                    }
                }
                .frame(width: size.width, height: size.height)
                // In hand, the plant rises off the ground a little and its
                // shadow stays down, which is what says it has been picked up.
                .scaleEffect(isHeld ? 1.05 : 1, anchor: .bottom)
                .offset(y: isHeld ? -10 : 0)
                // **The gestures go on the plant and not on its frame.**
                // `position` makes a view take all the space it is offered, so a
                // gesture attached after it answered anywhere on screen; and a
                // frame is mostly air, so a gesture on the whole frame let a
                // plant take every touch meant for whatever stood behind it.
                .contentShape(Rectangle().path(in: CGRect(
                    x: sprite.opaque.minX * size.width,
                    y: sprite.opaque.minY * size.height,
                    width: sprite.opaque.width * size.width,
                    height: sprite.opaque.height * size.height
                )))
                .onTapGesture(perform: onTap)
                .gesture(lift)
                .position(x: foot.x, y: foot.y - size.height / 2)
            }
        }
        .task(id: GardenSprites.key(genome: genome, growth: growth,
                                    step: between.before, turn: turn)) {
            before = GardenSprites.shared.sprite(genome: genome, growth: growth,
                                                 step: between.before, turn: turn)
        }
        .task(id: GardenSprites.key(genome: genome, growth: growth,
                                    step: between.after, turn: turn)) {
            after = GardenSprites.shared.sprite(genome: genome, growth: growth,
                                                step: between.after, turn: turn)
        }
    }

    /// Long press to lift, then drag.
    ///
    /// A third of a second, which is long enough that looking at a plant never
    /// picks it up and short enough that picking one up does not feel like
    /// waiting. The drag is measured in the plot's own unzoomed coordinates, so
    /// a plant follows the finger at any zoom.
    private var lift: some Gesture {
        LongPressGesture(minimumDuration: 0.33)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("plot")))
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                if !lifting {
                    lifting = true
                    onLift()
                }
                onMove(drag?.translation ?? .zero)
            }
            .onEnded { value in
                defer { lifting = false }
                guard case .second(true, let drag) = value else { return }
                onDrop(drag?.translation ?? .zero)
            }
    }

    @ViewBuilder
    private func picture(_ sprite: GardenSprites.Sprite?, size: CGSize,
                         opacity: Double) -> some View {
        if let sprite {
            Image(uiImage: sprite.image)
                .resizable()
                .interpolation(.high)
                .frame(width: size.width, height: size.height)
                .opacity(opacity)
        }
    }

    /// The plant's own shadow, laid on the ground.
    ///
    /// **A shear of the picture, not a second drawing.** A point standing `v`
    /// points up the sprite is a point `v / pointsPerMetre` metres up the plant,
    /// and its shadow lands that height over the light's own slope away across
    /// the ground — which the projection turns back into a screen offset. So the
    /// whole shadow is one affine transform of the sprite, blackened.
    ///
    /// The light is in the plot's own axes, so it is turned with the plot before
    /// the shear is worked out: the sun goes round the plot, not the screen.
    ///
    /// It goes flat twice a day. At noon and at midnight the body is at the
    /// azimuth where the shadow runs exactly along the screen's horizontal, and
    /// a shadow with no screen height is a line. That is not a fault — it is
    /// what an isometric view of that moment is — and the blur is what keeps it
    /// from reading as a drawn rule.
    @ViewBuilder
    private func shadow(of sprite: GardenSprites.Sprite, size: CGSize) -> some View {
        let seen = light.turned(quarters: turn).direction
        let rise = max(0.12, seen.y)
        let across = -(seen.x - seen.z) * Isometric.cosThirty / rise
        let down = -(seen.x + seen.z) * Isometric.sinThirty / rise
        let height = size.height

        Image(uiImage: sprite.image)
            .resizable()
            .renderingMode(.template)
            .frame(width: size.width, height: size.height)
            .foregroundStyle(.black)
            .blur(radius: 0.30 + 0.34 * (1 - light.up))
            .opacity(max(0.10, 0.42 * light.strength / 0.76))
            .transformEffect(CGAffineTransform(
                a: 1, b: 0,
                c: -across, d: -down,
                tx: across * height, ty: height * (1 + down)
            ))
            .position(x: foot.x, y: foot.y - height / 2)
            .allowsHitTesting(false)
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
    let light: GardenGround.Light

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
        .task(id: "\(world)-\(Int(plotSide * 100))-\(Int(size.width))x\(Int(size.height))"
              + "-\(Int(light.strength * 1000))-\(Int(light.direction.x * 100))") {
            ground = await GardenTerrain.shared.image(
                world: world, plotSide: plotSide, view: view, size: size, light: light
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
