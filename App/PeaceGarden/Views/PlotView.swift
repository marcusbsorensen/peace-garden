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
    /// The plant somebody else has asked about, while it is being answered.
    @State private var answering: PlantRecord?
    /// Which outstanding invitation the notice at the foot opens next.
    ///
    /// It steps rather than always opening the first, so a garden with three
    /// waiting in it can be walked through from the notice alone. The plant
    /// screen has its own way through them — see `PlantDetailView`'s chevrons —
    /// and this is for somebody who has not got there yet.
    @State private var askedStep = 0

    @AppStorage(Chrome.daylightKey) private var daylightRaw = GardenDaylight.byTheClock.rawValue

    // MARK: Looking at it

    /// Quarter-turns of the plot. Stepped rather than free, because isometric
    /// has four natural views and between them the ground's own axes stop being
    /// aligned to the screen, which is what makes it legible.
    ///
    /// Kept between visits, so a favourite side is the side the garden opens
    /// on: `Chrome.plotTurnKey` says why on the phone and not on the bed.
    @AppStorage(Chrome.plotTurnKey) private var turn = 0
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
    /// Whether the light in hand has gone anywhere yet. One lifted and let go
    /// where it was is being asked about rather than moved, and opens its panel.
    @State private var lampTravelled = false
    /// The light whose panel is open.
    @State private var tending: UUID?
    /// Counted rather than flagged, so every lift is its own tap of feedback.
    @State private var lifts = 0

    /// Which way, and how fast, the plot is being panned under something held
    /// near the edge of the screen, in points a second.
    @State private var edgePush: CGSize = .zero
    @State private var edgeTask: Task<Void, Never>?
    /// The size the plot is shown at, for the arithmetic that has to happen
    /// outside the `GeometryReader`: where a finger is on the glass, and how
    /// far the plot can pan.
    @State private var screen: CGSize = .zero

    // MARK: The tray

    /// Whether the tray at the foot is open. Shut every time the garden opens.
    @State private var trayOpen = false
    /// Where the foot of the screen begins — the asking line, the tray and its
    /// plus — so the plot is framed in the sky above it.
    @State private var footFrame: CGRect = .null

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

    /// The plot's side: the garden's own, unless a developer has fixed it to
    /// look at a web plot.
    /// Whether the plot is being looked at as a Long Walk plot, path and hedges
    /// and all. Developer-only until the web gardens have a plot of their own.
    private var isLongWalk: Bool {
        #if DEBUG
        return Developer.shared.previewArea == "longWalk"
        #else
        return false
        #endif
    }

    private var plotSide: Double {
        #if DEBUG
        if let fixed = Developer.shared.fixedPlotSide { return fixed }
        #endif
        return model.garden.plotSide
    }

    /// Where the heading and Close are on the screen, so the sun and moon keep off them.
    @State private var headingFrame: CGRect = .null
    /// The asking line's place on screen, so the stars keep off it too.
    @State private var askingFrame: CGRect = .null
    @State private var closeFrame: CGRect = .null

    var body: some View {
        ZStack {
            Chrome.ground.ignoresSafeArea()

            GeometryReader { proxy in
                let light = GardenGround.Light.at(hour: hour)
                let side = plotSide
                let world = GardenWorlds.shared.resolve(model.garden.arrangements.first?.world)
                // A hill lifts a plant above the far corner and a ravine hangs
                // the cut below the near one, so the camera has to leave room
                // for the ground as well as for what stands on it.
                let relief = GardenWorlds.shared.relief(world: world, plotSide: side)
                let glass = proxy.frame(in: .global)
                let area = framing(in: proxy.size, glass: glass)
                var view = Isometric.fitting(
                    plotSide: side,
                    in: proxy.size,
                    area: area,
                    headroom: GardenSprites.tallestExpected + relief.high,
                    soilDepth: GardenGround.rimDepth - relief.low
                )
                let _ = (view.turn = turn)
                // How far the frame has moved the plot from the middle of the
                // screen, which is where its ground is drawn: see
                // `GardenGroundView.shift`.
                let shift = CGSize(width: (area?.midX ?? proxy.size.width / 2) - proxy.size.width / 2,
                                   height: (area?.midY ?? proxy.size.height / 2) - proxy.size.height / 2)

                let lamps = model.garden.arrangements.first?.allLamps ?? []
                let glow = GardenLamps.glow(in: light)

                ZStack(alignment: .topLeading) {
                    GardenSky(light: light, date: model.now, view: view,
                              keepClear: [headingFrame, closeFrame, askingFrame])

                    ZStack(alignment: .topLeading) {
                        plot(world: world, side: side, in: view, shift: shift,
                             size: proxy.size, light: light)

                        if isLongWalk {
                            MownPath(view: view, light: light, plotSide: side) { spot in
                                standsAt(spot, world: world, side: side)
                            }
                            HedgeShadow(view: view, light: light, plotSide: side,
                                        hedges: hedgeLines(plotSide: side, world: world, in: view)) { spot in
                                standsAt(spot, world: world, side: side)
                            }
                        }

                        // The lights' pools, under everything that stands, so
                        // a plant stands *in* the light rather than behind it.
                        ForEach(lamps) { lamp in
                            lampPool(lamp, world: world, side: side, in: view, glow: glow)
                        }

                        // Far to near, and nothing else decides what covers
                        // what — except something in hand, which is above
                        // everything until it is put down.
                        ForEach(things(plotSide: side, world: world, lamps: lamps, in: view)) { thing in
                            switch thing {
                            case .plant(let standing):
                                pool(for: standing, world: world, side: side, in: view)
                                waiting(for: standing, world: world, side: side, in: view)
                                plant(standing, world: world, side: side, in: view,
                                      light: light, lamps: lamps, glow: glow)
                            case .lamp(let lamp):
                                self.lamp(lamp, world: world, side: side, in: view, glow: glow)
                            case .hedge(let piece):
                                hedge(piece, world: world, side: side, in: view)
                            }
                        }
                    }
                    .coordinateSpace(name: "plot")
                    .scaleEffect(zoom * pinching)
                    .offset(x: pan.width + panning.width, y: pan.height + panning.height)
                    .rotationEffect(turning)

                    // Over the plot and under the words, because a thread joins
                    // one to the other and has to be in both their spaces.
                    threads(world: world, side: side, in: view,
                            screen: proxy.size, glass: glass)

                    panel(lamps: lamps, world: world, side: side, in: view, screen: proxy.size)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .onAppear { screen = proxy.size }
                .onChange(of: proxy.size) { _, size in screen = size }
                .contentShape(Rectangle())
                .gesture(looking(in: proxy.size))
                .simultaneousGesture(panGesture(in: proxy.size))
            }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header
                    // Measured on the screen, which is the sky's space too: the
                    // sky ignores the safe area and fills the glass from its corner.
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { headingFrame = $0 }
                if model.hybrids.isEmpty { empty }
                Spacer(minLength: 0)
                foot
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                        // The first measurement places the plot; every one
                        // after it moves the plot, and is seen to.
                        if footFrame.isNull {
                            footFrame = frame
                        } else {
                            withAnimation(.smooth(duration: 0.4)) { footFrame = frame }
                        }
                    }
            }
            .padding(.horizontal, 26)
            .frame(maxWidth: .infinity, alignment: .leading)
            .allowsHitTesting(true)
        }
        .overlay(alignment: .topTrailing) {
            CloseButton { dismiss() }
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { closeFrame = $0 }
                .padding(.trailing, 12)
                .padding(.top, 12)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: lifts)
        .sensoryFeedback(.selection, trigger: turn)
        .sheet(item: $answering) { record in
            ShowInGardenView(record: record)
                .environment(model)
                .presentationBackground(Chrome.ground)
        }
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
                if degrees > 28 { turnPlot(by: -1) } else if degrees < -28 { turnPlot(by: 1) }
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

    /// Where the plot is framed: the sky between the heading and whatever stands
    /// at the foot of the screen, in the plot's own space.
    ///
    /// **Above the tray, not behind it** (Marcus, 1 October). The figures to
    /// put out and the grounds to stand on are below the plot, which is where
    /// they belong — the things that go on the garden above the earth it
    /// stands in. So the plot rises when the tray opens and comes back down
    /// when it shuts. Until both ends have been measured, the whole screen.
    ///
    /// **From the top of the heading, not the foot of it.** The fit keeps
    /// room above the plot for the tallest plant a garden could grow, and in
    /// nearly every garden that room is sky. Measured from under the heading,
    /// the plot sat low with a band of empty sky over it; the heading stands
    /// at the leading edge and the plot's far corner is in the middle, so the
    /// tallest plant there still clears the words.
    private func framing(in size: CGSize, glass: CGRect) -> CGRect? {
        guard !headingFrame.isNull, !footFrame.isNull else { return nil }
        let top = headingFrame.minY - glass.minY
        let bottom = footFrame.minY - glass.minY
        guard bottom - top > 160 else { return nil }
        return CGRect(x: 0, y: top, width: size.width, height: bottom - top)
    }

    /// A quarter-turn, from two fingers or from the tray: one step, one tap of
    /// feedback. Positive is anticlockwise as seen.
    private func turnPlot(by quarters: Int) {
        tending = nil
        turn = ((turn + quarters) % 4 + 4) % 4
    }

    private var viewIsMoved: Bool {
        turn != 0 || zoom > 1.001 || pan != .zero
    }

    /// The plot as it first opened: from its first side, all of it on screen.
    private func resetView() {
        tending = nil
        turn = 0
        withAnimation(.easeInOut(duration: 0.35)) {
            zoom = 1
            pan = .zero
        }
    }

    // MARK: Zoom, for what it is for

    /// How far in a double tap comes. Close enough to show a plant off, with
    /// its neighbours still round it.
    private static let comingIn: CGFloat = 2.4

    /// Come in on a point of the plot, or back out if already in.
    ///
    /// For showing a plant to somebody in its setting: `ARRANGING.md` §*What
    /// zoom is for*. A plant alone, large, is its sheet's job, so this stops
    /// well short of the cap.
    private func comeIn(on point: CGPoint) {
        withAnimation(.easeInOut(duration: 0.35)) {
            guard zoom <= 1.001 else {
                zoom = 1
                pan = .zero
                return
            }
            zoom = Self.comingIn
            // `scaleEffect` scales about the middle, so a point lands at
            // `middle + (point - middle) * zoom + pan`; the pan that puts it in
            // the middle is the rest of that, turned round.
            let middle = CGPoint(x: screen.width / 2, y: screen.height / 2)
            pan = clamped(CGSize(width: -(point.x - middle.x) * zoom,
                                 height: -(point.y - middle.y) * zoom), in: screen)
        }
    }

    /// Something in hand near the edge of the screen pans the plot under it,
    /// so a plant can be carried anywhere on a plot zoomed past the screen.
    ///
    /// Harder the nearer the edge. It keeps going while the finger is still,
    /// because a finger held at the edge is somebody waiting to be taken there.
    private func nudge(finger: CGPoint) {
        guard zoom > 1.001, screen.width > 0 else {
            edgePush = .zero
            return
        }
        let middle = CGPoint(x: screen.width / 2, y: screen.height / 2)
        let on = CGPoint(x: middle.x + (finger.x - middle.x) * zoom + pan.width,
                         y: middle.y + (finger.y - middle.y) * zoom + pan.height)

        let margin: CGFloat = 56, fastest: CGFloat = 420
        func push(_ at: CGFloat, _ length: CGFloat) -> CGFloat {
            if at < margin { return -min(1, (margin - at) / margin) * fastest }
            if at > length - margin { return min(1, (at - (length - margin)) / margin) * fastest }
            return 0
        }
        edgePush = CGSize(width: push(on.x, screen.width), height: push(on.y, screen.height))

        guard edgePush != .zero, edgeTask == nil else { return }
        edgeTask = Task { @MainActor in
            defer { edgeTask = nil }
            let tick = 1.0 / 60
            while !Task.isCancelled, edgePush != .zero, held != nil || heldLamp != nil {
                try? await Task.sleep(for: .seconds(tick))
                let before = pan
                pan = clamped(CGSize(width: pan.width - edgePush.width * tick,
                                     height: pan.height - edgePush.height * tick), in: screen)
                // The finger has not moved on the glass, so the plot under it
                // has: what is held moves with the finger, against the pan.
                let shift = CGSize(width: -(pan.width - before.width) / zoom,
                                   height: -(pan.height - before.height) / zoom)
                if shift == .zero { continue }
                held?.foot.x += shift.width
                held?.foot.y += shift.height
                heldLamp?.foot.x += shift.width
                heldLamp?.foot.y += shift.height
            }
        }
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

        // A hand placement made before the rim wandered may be past it; it is
        // shown on the ground, and kept as it was until it is moved again.
        let outline = PlotOutline.of(plotSide: plotSide)
        return plants.compactMap { record -> Standing? in
            guard let spot = bed?.spot(for: record).map({ outline.keepOn($0) }) ?? laidOut[record.id]
            else { return nil }
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
        case hedge(Hedge)

        var id: UUID {
            switch self {
            case .plant(let standing): return standing.id
            case .lamp(let lamp): return lamp.id
            case .hedge(let piece): return piece.id
            }
        }

        var spot: Spot {
            switch self {
            case .plant(let standing): return standing.spot
            case .lamp(let lamp): return lamp.spot
            case .hedge(let piece): return piece.spot
            }
        }
    }

    /// One piece of a Long Walk hedge.
    private struct Hedge {
        let id: UUID
        let spot: Spot
        let line: HedgeLine
        let index: Int
    }

    /// The Long Walk's two hedges: tall behind the far border and low in front
    /// of the near one, which is decided by the view and so swaps as the plot
    /// turns. Each is one mesh, built once for its side and height.
    private func hedgeLines(plotSide: Double, world: Int, in view: Isometric) -> [HedgeLine] {
        guard isLongWalk else { return [] }
        let out = LongWalk.hedgeFrom + GardenStructures.thickness / 2
        let farSide = view.depth(Spot(x: out, z: 0)) < view.depth(Spot(x: -out, z: 0)) ? 1 : -1
        return [-1, 1].map { side in
            GardenStructures.shared.line(side: side,
                                         height: side == farSide ? GardenStructures.tall : GardenStructures.low,
                                         plotSide: plotSide, world: world)
        }
    }

    /// The hedges in the pieces they are drawn in, each sorted among the plants
    /// by its own depth. **The top is the hedge's own**: an undulating line set
    /// by its seed and carried over the ground's rises, rather than one level
    /// cut, because a level line is a ruled one.
    private func hedges(plotSide: Double, world: Int, in view: Isometric) -> [Hedge] {
        hedgeLines(plotSide: plotSide, world: world, in: view).flatMap { line in
            line.pieces.map { piece in
                Hedge(id: UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d",
                                                  (line.side > 0 ? 1_000 : 0) + piece.index))!,
                      spot: piece.spot, line: line, index: piece.index)
            }
        }
    }

    private func hedge(_ piece: Hedge, world: Int, side: Double, in view: Isometric) -> some View {
        let foot = view.point(piece.spot, y: piece.line.pieces[piece.index].ground)
        let size = GardenStructures.figure(height: piece.line.height).metres * view.pointsPerMetre
        return HedgePiece(line: piece.line, index: piece.index, pointsPerMetre: view.pointsPerMetre,
                          hour: hour, turn: turn)
            .allowsHitTesting(false)
            .position(x: foot.x, y: foot.y - size / 2)
    }

    private func things(plotSide: Double, world: Int, lamps: [Lamp], in view: Isometric) -> [Thing] {
        let inHand: Set<UUID> = Set([held?.id, heldLamp?.id].compactMap { $0 })
        let all = standing(plotSide: plotSide, in: view).map(Thing.plant)
            + lamps.filter { $0.known != nil }.map(Thing.lamp)
            + hedges(plotSide: plotSide, world: world, in: view).map(Thing.hedge)

        return all.sorted { a, b in
            if inHand.contains(a.id) { return false }
            if inHand.contains(b.id) { return true }
            return view.depth(a.spot) < view.depth(b.spot)
        }
    }

    // MARK: The ground

    /// The ground, drawn once and kept.
    private func plot(world: Int, side: Double, in view: Isometric, shift: CGSize, size: CGSize,
                      light: GardenGround.Light) -> some View {
        var drawn = view
        drawn.centre = CGPoint(x: view.centre.x - shift.width, y: view.centre.y - shift.height)
        return GardenGroundView(world: world, plotSide: side, view: drawn, shift: shift,
                                size: size, light: light, zoom: zoom, pan: pan)
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
            isLeaving: inHand && Isometric.isOff(view.ground(at: held?.foot ?? resting),
                                                 plotSide: side),
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
            onDoubleTap: {
                comeIn(on: CGPoint(x: resting.x, y: resting.y - 0.45 * view.pointsPerMetre))
            },
            onMove: { travel, finger in
                held?.foot = CGPoint(x: resting.x + travel.width, y: resting.y + travel.height)
                if let finger { nudge(finger: finger) }
            },
            onDrop: { travel in
                edgePush = .zero
                // Where it is held, not where the last drag said: the plot may
                // have panned under a finger that has not moved since.
                let foot = held?.foot
                    ?? CGPoint(x: resting.x + travel.width, y: resting.y + travel.height)
                put(standing.record, at: foot, world: world, side: side, in: view)
            }
        )
    }

    /// Where a dropped plant lands, and keeping it on the plot.
    ///
    /// Drawn in inside the rim rather than refused, because a plant dropped just
    /// over the edge was meant to be at the edge. The rim is the wandering one
    /// that is drawn, so a plant is never left standing on the air beside it. The finger is where the *foot*
    /// is, so the ground has to be found with that place's own height put back —
    /// the inverse runs twice, and on the steepest wall of the ravine twice is
    /// enough.
    private func put(_ plant: PlantRecord, at foot: CGPoint, world: Int, side: Double,
                     in view: Isometric) {
        // Carried off the plot, it goes home: the hand placement is forgotten
        // and the plant walks back to where its arrangement puts it.
        if Isometric.isOff(view.ground(at: foot), plotSide: side) {
            withAnimation(.spring(duration: 0.45)) {
                model.putBack(plant)
                held = nil
            }
            return
        }

        let relief = GardenWorlds.shared.relief(world: world, plotSide: side)
        let found = view.ground(at: foot, height: { spot in
            standsAt(spot, world: world, side: side)
        }, between: relief.low, and: relief.high)
        let spot = PlotOutline.of(plotSide: side).keepOn(found)

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
            // A larger light throws a larger pool: the pool is the light, as
            // far as the ground can tell.
            let axes = view.ellipse(radius: GardenLamps.reach(of: kind) * 0.72 * lamp.drawnScale)

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
            // Its size is a size in the garden, so it is drawn at more or fewer
            // points to the metre and everything about it — the frame, the part
            // that answers a finger — follows.
            let metre = view.pointsPerMetre * lamp.drawnScale
            let resting = view.point(lamp.spot, y: standsAt(lamp.spot, world: world, side: side))
            let inHand = heldLamp?.id == lamp.id
            let lifted = inHand || tending == lamp.id
            let foot = inHand ? (heldLamp?.foot ?? resting) : resting

            LampFigure(kind: kind, glow: glow, pointsPerMetre: metre, seed: Self.seed(of: lamp),
                       hour: hour, turn: turn)
                .allowsHitTesting(false)
                // Only the light itself answers a finger, not the whole metre of
                // air its frame takes up, or a lantern would steal every touch
                // meant for the plant behind it.
                .overlay(alignment: .bottom) {
                    Color.clear
                        .frame(width: GardenLamps.grip(of: kind).width * metre,
                               height: GardenLamps.grip(of: kind).height * metre)
                        .contentShape(Rectangle())
                        .gesture(carrying(lamp, from: resting, world: world, side: side, in: view))
                }
                .scaleEffect(lifted ? 1.06 : 1, anchor: .bottom)
                .offset(y: lifted ? -8 : 0)
                .opacity(inHand && Isometric.isOff(view.ground(at: foot), plotSide: side) ? 0.4 : 1)
                .position(x: foot.x, y: foot.y - 0.6 * metre)
        }
    }

    /// The seed a light is drawn from, with its facing in the low three bits.
    ///
    /// **A figure has always faced by its seed** — `GardenCreatures.facing` is
    /// the seed's remainder by eight — so turning one is a matter of handing it
    /// a seed that ends in the facing chosen. The rest of the seed is the
    /// light's own, so a drift of fireflies keeps its drift. A light nobody has
    /// turned gets back exactly the seed it always had.
    static func seed(of lamp: Lamp) -> Int {
        let dealt = Int(lamp.id.uuid.0) << 8 | Int(lamp.id.uuid.1)
        return dealt & ~7 | lamp.drawnFacing
    }

    private func carrying(_ lamp: Lamp, from resting: CGPoint, world: Int, side: Double,
                          in view: Isometric) -> some Gesture {
        LongPressGesture(minimumDuration: 0.33)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("plot")))
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                let travel = drag?.translation ?? .zero
                if heldLamp?.id != lamp.id {
                    lifts += 1
                    lampTravelled = false
                    tending = nil
                }
                // Further than a finger wanders while it is held still.
                if hypot(travel.width, travel.height) > 6 { lampTravelled = true }
                heldLamp = Held(id: lamp.id, foot: CGPoint(x: resting.x + travel.width,
                                                           y: resting.y + travel.height))
                if let finger = drag?.location { nudge(finger: finger) }
            }
            .onEnded { value in
                edgePush = .zero
                guard case .second(true, let drag) = value else {
                    heldLamp = nil
                    return
                }
                // Lifted and let go where it was: not a move, a question.
                guard lampTravelled else {
                    withAnimation(.spring(duration: 0.25)) {
                        heldLamp = nil
                        tending = lamp.id
                    }
                    return
                }
                let travel = drag?.translation ?? .zero
                let foot = heldLamp?.foot
                    ?? CGPoint(x: resting.x + travel.width, y: resting.y + travel.height)
                let found = view.ground(at: foot)

                withAnimation(.spring(duration: 0.3)) {
                    if Isometric.isOff(found, plotSide: side) {
                        model.removeLamp(lamp.id)
                    } else {
                        let relief = GardenWorlds.shared.relief(world: world, plotSide: side)
                        let landed = view.ground(at: foot, height: { spot in
                            standsAt(spot, world: world, side: side)
                        }, between: relief.low, and: relief.high)
                        model.moveLamp(lamp.id, to: PlotOutline.of(plotSide: side).keepOn(landed))
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

    // MARK: The ones somebody is waiting on

    /// A ring of light round a plant the other gardener has asked about.
    ///
    /// **The garden says which one.** The notice at the foot of the screen used
    /// to be the only thing that knew, so it told you something was waiting and
    /// left you to find it among fourteen plants. The plant is standing right
    /// there; the ring is the pointing.
    ///
    /// A ring rather than a pool, because `pool` — a filled glow in the same
    /// gold — already means *this one has grown since you last looked*, and two
    /// different things saying themselves the same way is one thing said twice.
    /// Stroked, so a plant stands inside it rather than on top of it.
    @ViewBuilder
    private func waiting(for standing: Standing, world: Int, side: Double,
                         in view: Isometric) -> some View {
        if standing.record.standingOrHere.state == .invited, held?.id != standing.id {
            let centre = view.point(standing.spot,
                                    y: standsAt(standing.spot, world: world, side: side))
            // Wide enough to be a ring round the stem and no wider. At 0.46 it
            // was bigger than the plant standing in it, which reads as a mark
            // on the ground that a plant happens to be near.
            let axes = view.ellipse(radius: 0.30)

            Ellipse()
                .stroke(Chrome.pinkGold.opacity(0.45), style: Chrome.monoline)
                .frame(width: axes.width * 2, height: axes.height * 2)
                .contentShape(Ellipse())
                .onTapGesture {
                    visits.seen(standing.record, growth: standing.growth)
                    selected = standing.record
                }
                .position(centre)
        }
    }

    /// The threads: one from each waiting plant down to the question at the foot.
    ///
    /// **Why they are drawn at all.** A notice that says somebody is waiting,
    /// and a plant standing in a garden, are two facts about one thing with
    /// nothing between them. The thread is the between.
    ///
    /// **Why they are straight, when nothing else here is.** The rule about
    /// this garden — no ruled lines, the soil and the hedges and the paths and
    /// the shadows all irregular — is a rule about the *scene*. A thread that
    /// wandered was tried first and it was a scene object: a soft gold curve
    /// coming out of the ground beside a stem, which on the plot read as a
    /// second stem and below the plot as a root. Drawn dead straight, thin and
    /// dotted, it stops pretending to have grown there and becomes what it is
    /// — the interface pointing at something (Marcus, 20 September).
    ///
    /// It falls **vertically**, so nothing about it has to be read: it is
    /// under its own plant, and it ends where the question is.
    ///
    /// The plot's zoom and pan are render transforms and do not move layout, so
    /// a plant's place on the glass is worked out here with the same arithmetic
    /// `nudge(finger:)` uses rather than read back from SwiftUI.
    @ViewBuilder
    private func threads(world: Int, side: Double, in view: Isometric,
                         screen size: CGSize, glass: CGRect) -> some View {
        let waiting = model.invited
        if !waiting.isEmpty, !askingFrame.isNull, size.width > 0 {
            let top = askingFrame.minY - glass.minY - 6
            let standings = standing(plotSide: side, in: view)
            let heads = waiting.compactMap { record -> CGPoint? in
                guard let spot = standings.first(where: { $0.record.id == record.id })?.spot
                else { return nil }
                let at = view.point(spot, y: standsAt(spot, world: world, side: side))
                return onTheGlass(at, in: size)
            }

            Canvas { context, _ in
                for head in heads where head.y < top {
                    var path = Path()
                    path.move(to: head)
                    path.addLine(to: CGPoint(x: head.x, y: top))
                    // Dots rather than dashes, and under a point wide. A dash
                    // has a direction and a length and starts looking like a
                    // measurement; a dotted line is only a line of sight. It
                    // crosses the lit face of the plot and then the night
                    // below it, and at this weight it holds on both without
                    // being the brightest thing on either.
                    context.stroke(
                        path,
                        with: .color(Chrome.pinkGold.opacity(0.5)),
                        style: StrokeStyle(lineWidth: 0.75, lineCap: .round, dash: [0.75, 6])
                    )
                }
            }
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)
        }
    }

    /// A point in the plot's own coordinates, where it actually lands on the
    /// glass once the plot has been zoomed and panned.
    private func onTheGlass(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let scale = zoom * pinching
        let middle = CGPoint(x: size.width / 2, y: size.height / 2)
        return CGPoint(
            x: middle.x + (point.x - middle.x) * scale + pan.width + panning.width,
            y: middle.y + (point.y - middle.y) * scale + pan.height + panning.height
        )
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

    /// Somebody is waiting on an answer about one of these plants.
    ///
    /// **It has to be findable**, or it is an invitation nobody ever sees: the
    /// answer decides whether a plant of this person's stands on the open web,
    /// and it arrives while they are doing something else. It says nothing
    /// about who or which — the plant itself is where that is read.
    ///
    /// **Down here rather than under the heading** (Marcus, 19 September):
    /// between the title and the garden there is sky, and sky holds the sun,
    /// the moon and the stars and nothing else. Above the row of figures the
    /// ground has already come up behind it, so a line of words there sits on
    /// something dark rather than across a field of stars.
    ///
    /// **No count and no numeral.** One string rather than a plural entry in
    /// forty-two languages, and `tools/strings/app_check.py` would refuse a
    /// numeral here anyway.
    @ViewBuilder
    private var asking: some View {
        let waiting = model.invited
        if !waiting.isEmpty {
            Button { openTheNextAsked(of: waiting) } label: {
                Text(asked(by: waiting))
                    .chromeLabel()
                    .foregroundStyle(Chrome.pinkGold)
                    .multilineTextAlignment(.center)
                    // **No outline**, though it is a button and `pressable`
                    // is what this app puts round one. A capsule the width of
                    // the screen, hard-edged, sitting above a row of glowing
                    // figures was the loudest object on a screen made of soft
                    // light, and it read as the thing to press on a screen
                    // whose whole argument is that the plant is. What says it
                    // can be pressed now is what it is made of: the one pink
                    // gold on the screen, the same gold as the rings, with
                    // three threads coming down to land on it.
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { askingFrame = $0 }
            .padding(.bottom, 10)
        }
    }

    /// Who has asked, and what they asked for.
    ///
    /// **It said *somebody* while the app knew the name.** The people in this
    /// garden are the whole subject of it — every plant here came from meeting
    /// one of them — and anonymising them turned a person's question into a
    /// notification from a service. It also said *asked about a plant*, which
    /// could be a question, a message or a query; what was actually asked is
    /// for the plant to be shown where anyone can come across it.
    ///
    /// **Two keys rather than a plural rule.** The count decides which sentence
    /// is looked up, so neither carries a numeral — which `tools/strings/app_check.py`
    /// would refuse — and both are a whole sentence for a translator to move
    /// around. `ListFormatter` puts the names in the reader's own language,
    /// with that language's own word for *and*.
    private func asked(by waiting: [PlantRecord]) -> LocalizedStringKey {
        let who = ListFormatter.localizedString(byJoining: Self.gardenersAsking(waiting))
        // One *plant*, not one person: two plants from the same meeting are two
        // questions, and the sentence has to agree with the plants.
        return waiting.count == 1
            ? "\(who) has asked to show a plant you grew together"
            : "\(who) have asked to show plants you grew together"
    }

    /// Who is asking, each of them once, in the order their plants arrived.
    ///
    /// Once, because two plants from one meeting are two questions and one
    /// person, and a notice that said *Cai and Cai* would be counting plants
    /// while appearing to count people.
    static func gardenersAsking(_ waiting: [PlantRecord]) -> [String] {
        var names: [String] = []
        for record in waiting {
            let name = record.encounter?.peerDisplayName ?? String(localized: "the other gardener")
            if !names.contains(name) { names.append(name) }
        }
        return names
    }

    /// Opens the next one waiting, and the one after that next time.
    ///
    /// It goes to the plant rather than straight to the question, because the
    /// plant is what is being asked about and answering without looking at it
    /// is the thing this whole screen exists to avoid. The answer is one mark
    /// away from there, and the chevrons carry on through the rest.
    private func openTheNextAsked(of waiting: [PlantRecord]) {
        guard !waiting.isEmpty else { return }
        let next = waiting[askedStep % waiting.count]
        askedStep += 1
        visits.seen(next, growth: next.growth(now: model.now))
        selected = next
    }

    /// How much bigger a figure is drawn in the row than on the plot. A lantern
    /// fills its button at forty points a metre; a snail at that scale is eight
    /// points of nothing.
    private func trayScale(of kind: LampKind) -> Double {
        switch kind {
        case .lantern, .paperLamp, .fireflies: return 1
        case .hare: return 1.5
        case .fox: return 1.25
        case .moth: return 1.6
        case .snail: return 2.1
        }
    }

    /// How far a figure is raised in the row, so the part of it drawn below its
    /// foot is inside the button rather than clipped off.
    private func trayLift(of kind: LampKind) -> Double {
        guard let figure = GardenCreatures.figure(of: kind) else { return 0 }
        return 0.6 * figure.lift * figure.metres * 40 * trayScale(of: kind)
    }

    /// The foot of the screen: the asking line, the tray when it is open, and
    /// the plus that opens it.
    private var foot: some View {
        VStack(alignment: .leading, spacing: 0) {
            asking
            if trayOpen {
                tray
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            TrayToggle(isOpen: trayOpen) {
                tending = nil
                withAnimation(.smooth(duration: 0.4)) { trayOpen.toggle() }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 12)
        }
    }

    /// What the tray holds, in the order Marcus asked for on 1 October: **the
    /// things that go on the garden above the ground they go on**, which is the
    /// order they stand in on the plot as well. Then how the plot is seen.
    private var tray: some View {
        VStack(alignment: .leading, spacing: 8) {
            figures
            grounds
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    seeing
                    Spacer(minLength: 12)
                    daylight
                }
                VStack(alignment: .leading, spacing: 8) {
                    seeing
                    daylight
                }
            }
        }
    }

    /// The lights to put out, unnamed like the worlds: each is drawn as itself
    /// and added where it can be seen, then carried to where it is wanted.
    private var figures: some View {
        ContinuingRow {
            HStack(spacing: 10) {
                ForEach(LampKind.allCases, id: \.self) { kind in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            model.addLamp(kind, at: freshSpot(side: plotSide))
                        }
                    } label: {
                        // The figures a little below full glow: at full they
                        // are a white shape with no form in it.
                        LampFigure(kind: kind, glow: GardenCreatures.isCreature(kind) ? 0.7 : 1,
                                   pointsPerMetre: 40 * trayScale(of: kind),
                                   // The fox side-on: facing out of the row it
                                   // is a ball with a face.
                                   seed: kind == .fox ? 1 : 7)
                            .offset(y: -trayLift(of: kind))
                            .frame(width: 40, height: 48, alignment: .bottom)
                            .clipped()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
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

            ContinuingRow {
                HStack(spacing: 10) {
                    ForEach(0..<GardenWorlds.shared.count, id: \.self) { world in
                        Button {
                            model.choose(world: world)
                        } label: {
                            GroundMark(world: world,
                                       plotSide: plotSide,
                                       isChosen: world == chosen)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    /// Turning the plot and putting the view back, for anybody who has not
    /// found the two-finger turn — or who has, and has lost their way.
    ///
    /// Stepped exactly as the gesture is, a quarter at a time, for the reason
    /// `turn` gives.
    private var seeing: some View {
        HStack(spacing: 8) {
            TrayMark(glyph: TurnGlyph(clockwise: false, aroundPlot: true), says: "rotate.left") {
                turnPlot(by: 1)
            }
            TrayMark(glyph: TurnGlyph(clockwise: true, aroundPlot: true), says: "rotate.right") {
                turnPlot(by: -1)
            }
            TrayMark(glyph: FramedPlotGlyph(), says: "arrow.counterclockwise",
                     isEnabled: viewIsMoved) {
                resetView()
            }
        }
    }

    /// Day, the clock, or night: Settings' own control, on the same setting.
    private var daylight: some View {
        LightToggle(selection: GardenDaylight(rawValue: daylightRaw) ?? .byTheClock) {
            daylightRaw = $0.rawValue
        }
    }

    // MARK: A light's panel

    /// The small panel over a light somebody has held and let go, and the
    /// glass round it that shuts it when anything else is touched.
    ///
    /// Placed over the light where it stands on the glass — zoom, pan and all —
    /// and kept on the screen, below the light rather than above it if above
    /// would be under the heading.
    @ViewBuilder
    private func panel(lamps: [Lamp], world: Int, side: Double, in view: Isometric,
                       screen size: CGSize) -> some View {
        if let id = tending, let lamp = lamps.first(where: { $0.id == id }), let kind = lamp.known {
            let metre = view.pointsPerMetre * lamp.drawnScale
            let footAt = view.point(lamp.spot, y: standsAt(lamp.spot, world: world, side: side))
            let top = onTheGlass(CGPoint(x: footAt.x,
                                         y: footAt.y - GardenLamps.grip(of: kind).height * metre - 8),
                                 in: size)
            let bottom = onTheGlass(footAt, in: size)
            let above = top.y - 30
            let roomAbove = headingFrame.isNull ? 120 : headingFrame.maxY + 30

            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) { tending = nil }
                    }

                LampPanel(lamp: lamp) { edit in
                    withAnimation(.spring(duration: 0.3)) { model.changeLamp(lamp.id, edit) }
                }
                .fixedSize()
                .position(x: min(max(top.x, 130), size.width - 130),
                          y: above > roomAbove ? above : bottom.y + 34)
                .transition(.opacity)
            }
            .frame(width: size.width, height: size.height)
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
    /// Held off the edge of the plot, where letting go sends it home. Faded, so
    /// the plant says what letting go will do before it is done.
    let isLeaving: Bool
    /// How much the lights nearby lift this plant, and in what colour.
    let lamplight: (amount: Double, colour: SIMD3<Double>)
    let glow: Double
    let onTap: () -> Void
    let onLift: () -> Void
    let onDoubleTap: () -> Void
    /// How far it has travelled, and where the finger is, both in the plot's
    /// own unzoomed coordinates.
    let onMove: (CGSize, CGPoint?) -> Void
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
                .opacity(isLeaving ? 0.45 : 1)
                .animation(.easeOut(duration: 0.15), value: isLeaving)
                // **The gestures go on the plant and not on its frame.**
                // `position` makes a view take all the space it is offered, so a
                // gesture attached after it answered anywhere on screen; and a
                // frame is mostly air, so a gesture on the whole frame let a
                // plant take every touch meant for whatever stood behind it.
                .contentShape(sprite.leaves(in: size))
                // The double tap first, so a single tap waits a moment to be
                // sure it is one; that moment is the price of coming in.
                .onTapGesture(count: 2, perform: onDoubleTap)
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
                onMove(drag?.translation ?? .zero, drag?.location)
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
    /// The view the ground is drawn in: the plot as it would stand framed in
    /// the whole screen.
    let view: Isometric
    /// How far the plot actually stands from there, now that it is framed above
    /// the tray. The drawing is moved by this rather than drawn again.
    ///
    /// **Moved, because a move can be seen happening.** Opening the tray lifts
    /// the plot, and the plants rise with it on their own `position`s; a ground
    /// drawn again where it had arrived would jump while they glided. It is
    /// also what the terrain's cache expects — a drawing is keyed by its scale
    /// and size and not by where its middle is, so a plot drawn at two places
    /// on one screen would be handed the first.
    let shift: CGSize
    let size: CGSize
    let light: GardenGround.Light
    /// The zoom and pan once they have settled — not while fingers are down.
    let zoom: CGFloat
    let pan: CGSize

    @State private var ground: UIImage?
    /// The part of the ground on screen, drawn again at the zoom it is seen at.
    @State private var close: (image: UIImage, region: CGRect)?

    /// What is on screen, in the plot's own unzoomed coordinates, a little
    /// wider so a short pan does not uncover the stretched drawing beneath,
    /// and rounded so a pan of a point does not draw it all again.
    ///
    /// **Why this is here at all.** The ground is drawn once, at the size of
    /// the screen, and zooming stretched it: at 3x each quad was a blurred
    /// patch, and zoom is partly for showing a plant off in its setting
    /// (`ARRANGING.md` §*What zoom is for*). The quads themselves are the grain
    /// and stay; what is fixed is the drawing being enlarged. Only what is on
    /// screen is drawn, because the whole plot at three times the screen's
    /// resolution is over a hundred megabytes.
    private var seen: CGRect? {
        guard zoom > 1.3 else { return nil }
        let middle = CGPoint(x: size.width / 2, y: size.height / 2)
        let width = size.width / zoom * 1.2, height = size.height / zoom * 1.2
        // In the drawing's own space, which stands `shift` back from the plot's.
        let x = middle.x - pan.width / zoom - width / 2 - shift.width
        let y = middle.y - pan.height / zoom - height / 2 - shift.height
        let grain: CGFloat = 16
        return CGRect(x: (x / grain).rounded(.down) * grain, y: (y / grain).rounded(.down) * grain,
                      width: (width / grain).rounded(.up) * grain,
                      height: (height / grain).rounded(.up) * grain)
    }

    private var sharpness: CGFloat { min(3, (zoom * 2).rounded(.up) / 2) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            base
            if let close {
                Image(uiImage: close.image)
                    .resizable()
                    .frame(width: close.region.width, height: close.region.height)
                    .offset(x: close.region.minX, y: close.region.minY)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .offset(shift)
        .task(id: "\(baseKey)-\(seen.map { "\($0)" } ?? "far")-\(sharpness)") {
            guard let region = seen else {
                close = nil
                return
            }
            // A beat first, so a pan under a carried plant is not redrawn at
            // every step of it.
            try? await Task.sleep(for: .milliseconds(250))
            if Task.isCancelled { return }
            if let image = await GardenTerrain.shared.image(
                world: world, plotSide: plotSide, view: view, size: size, light: light,
                region: region, sharpness: sharpness
            ), !Task.isCancelled {
                close = (image, region)
            }
        }
    }

    /// The turn is in it, and the scale: the plot turned from the tray, or
    /// framed smaller above it on a wide screen, is a different drawing.
    private var baseKey: String {
        "\(world)-\(Int(plotSide * 100))-\(Int(size.width))x\(Int(size.height))"
            + "-t\(((view.turn % 4) + 4) % 4)-\(Int(view.pointsPerMetre * 10))"
            + "-\(Int(light.strength * 1000))-\(Int(light.direction.x * 100))"
    }

    private var base: some View {
        Group {
            if let ground {
                Image(uiImage: ground)
                    .resizable()
                    .frame(width: size.width, height: size.height)
            } else if !GardenWorlds.shared.isLoaded {
                Canvas { context, _ in
                    for (path, colour) in GardenGround.nearFaces(plotSide: plotSide, in: view) {
                        context.fill(path, with: .color(colour))
                        context.stroke(path, with: .color(colour), lineWidth: 0.7)
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
        .task(id: baseKey) {
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
