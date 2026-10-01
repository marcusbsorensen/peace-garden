import SwiftUI
import SeedCore

/// One kept plant, and the meeting it came from.
struct PlantDetailView: View {
    let record: PlantRecord

    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var detailsVisible = false
    @State private var editing = false
    /// 0 while the plant is here, 1 once the light has left the screen. The
    /// record is removed when it reaches 1 rather than when the hold ends, so
    /// what is on screen is the truth about the garden throughout.
    @State private var flight: Double = 0
    @State private var releasing = false
    /// Between the end of the hold and the service's answer. The plant stays
    /// exactly where it is until the Wild Fields say they have it.
    @State private var sending = false
    /// Said in the sentence's place when the Wild Fields could not take the
    /// plant, so the plant still on the screen is explained by the screen.
    @State private var releaseTrouble: LocalizedStringResource?
    /// The shared garden's one screen, for asking or for answering.
    @State private var showing = false
    /// Which mark in the row along the foot has its word unrolled. One at a
    /// time: the row is one width wide.
    @State private var expandedMark: String?
    /// The assisted path only, the same as the three rows in Settings:
    /// `HoldToConfirm` asks for this when a sustained press is not available.
    @State private var confirming = false
    /// Which plant the chevrons have walked to, if any. `nil` is the one this
    /// screen was opened on.
    @State private var stepped: PlantRecord.ID?

    var body: some View {
        ZStack {
            StageBackdrop(
                palette: live.genome.palette,
                presence: live.growth(now: model.now).heightScale
            )
                .ignoresSafeArea()

            PlantSceneView(
                genome: live.genome,
                growth: live.growth(now: model.now),
                onTap: { withAnimation(Chrome.fadeIn) { detailsVisible.toggle() } }
            )
            .ignoresSafeArea()
            // The plant gathers to the point the light leaves from, rather
            // than fading where it stands. The anchor is its base, so it
            // collapses onto its own root and not onto the middle of itself.
            .scaleEffect(releasing ? 0.02 : 1, anchor: UnitPoint(x: 0.5, y: 0.78))
            .opacity(releasing ? 0 : 1)
            .animation(.easeIn(duration: 0.45), value: releasing)

            // The plant steps back while there is something to read.
            //
            // **Why a veil and not a move.** Everywhere else in this app the
            // thing in the way is moved — the sun and the moon keep off the
            // words rather than being dimmed behind them. That works because a
            // body in the sky has somewhere else to be. A plant is the subject
            // of this screen, it is framed by `PlantSceneBuilder.framing` for
            // reasons the mushroom taught us, and a tall thin one fills the
            // glass from top to bottom whatever the camera does: there is
            // nowhere to put it. So the plant stays exactly where it is and the
            // light comes off it for as long as the words are up.
            //
            // **It has no edge**, which is the rule: a gradient is not a line,
            // and a panel behind the text would have drawn four. It is darkest
            // at the two ends, where the words are, and thinnest across the
            // middle third, which is the part of a plant worth looking at.
            StageVeil()
                .ignoresSafeArea()
                .opacity(detailsVisible && !releasing ? 1 : 0)
                .allowsHitTesting(false)
                .animation(Chrome.fadeIn, value: detailsVisible)
                .animation(.easeOut(duration: 0.3), value: releasing)

            details
                .opacity(detailsVisible && !releasing ? 1 : 0)
                .allowsHitTesting(detailsVisible && !releasing)
                .animation(Chrome.fadeIn, value: detailsVisible)
                .animation(.easeOut(duration: 0.3), value: releasing)
        }
        .overlay {
            if releasing {
                ReleaseFlight(progress: flight, tint: lightColour)
            }
        }
        .overlay(alignment: .topTrailing) {
            CloseButton { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 12)
                .opacity(releasing ? 0 : 1)
                .allowsHitTesting(!releasing)
                .animation(.easeOut(duration: 0.3), value: releasing)
        }
        // **Through the ones still waiting, without going back for each.**
        // Three invitations used to be three trips out to the garden and back
        // in again, and the garden is where you have just come from. They
        // appear only while this plant is one of the ones waiting and there is
        // more than one, because a chevron with nowhere to go is a control that
        // lies.
        .overlay(alignment: .leading) { chevron(towardsTrailing: false) }
        .overlay(alignment: .trailing) { chevron(towardsTrailing: true) }
        // An alert rather than a confirmation dialog, for the reason
        // SettingsView gives: a dialog on a sheet with a black presentation
        // background drew its destructive button and dropped the cancel, which
        // leaves an irreversible action with no visible way out of it.
        .alert(
            "Release to the Wild Fields?",
            isPresented: $confirming
        ) {
            Button("Leave it", role: .cancel) {}
            Button("Release it", role: .destructive) { release() }
        } message: {
            Text("It leaves your garden for the Wild Fields. The person you grew it with keeps theirs, and every other plant here stays where it is.")
        }
        .sheet(isPresented: $showing) {
            ShowInGardenView(record: live)
                .presentationBackground(Chrome.ground)
        }
        .sheet(isPresented: $editing) {
            EncounterEditView(record: record) { name, place, keepsCoordinate in
                model.updateEncounter(
                    of: record,
                    peerDisplayName: name,
                    place: .some(place),
                    keepsCoordinate: keepsCoordinate
                )
            }
            .presentationBackground(Chrome.ground)
        }
    }

    private var details: some View {
        VStack {
            // **The name alone over the crown.** The age used to sit under it,
            // which on a tall plant is small grey capitals laid across the
            // flower head — the one part of a spire worth looking at, and the
            // one place on this screen where the veil is deliberately no
            // stronger than it has to be. How old a plant is belongs with what
            // it is, not with what it is called, so it has gone down to the
            // foot with the meeting and the standing. What is left up here is
            // one large word, light on dark, which reads over anything.
            Text(live.genome.name.full)
                .plantName()
                .foregroundStyle(Chrome.ink)
                .padding(.top, 64)

            Spacer()

            VStack(spacing: 12) {
                if let encounter = live.encounter {
                    if let note = encounter.note {
                        // Somebody's own sentence about their own meeting.
                        Text(verbatim: note)
                            .font(.system(size: 16, weight: .light, design: .serif))
                            .italic()
                            .foregroundStyle(Chrome.ink)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                    }

                    VStack(spacing: 4) {
                        Text("with \(encounter.peerDisplayName)")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Chrome.muted)
                        if let place = encounter.place {
                            // Typed, or accepted from what `Places` offered —
                            // either way it was already in this person's
                            // language when it was written down.
                            Text(verbatim: place)
                                .chromeLabel(size: 10)
                                .foregroundStyle(Chrome.faint)
                        }
                        if encounter.showsDateTime {
                            Text(encounter.happenedAt.formatted(date: .long, time: .shortened))
                                .chromeLabel(size: 10)
                                .foregroundStyle(Chrome.faint)
                        }
                        // Numbers rather than a place name, and a tap to let a
                        // map say the name if anybody wants it. See
                        // `CoordinateDisplay`.
                        if let coordinate = encounter.coordinate {
                            if let url = coordinate.mapURL {
                                Link(destination: url) {
                                    Text(verbatim: coordinate.written)
                                        .chromeLabel(size: 10)
                                        .foregroundStyle(Chrome.muted)
                                        .pressable()
                                }
                                .padding(.top, 4)
                            } else {
                                Text(verbatim: coordinate.written)
                                    .chromeLabel(size: 10)
                                    .foregroundStyle(Chrome.faint)
                            }
                        }
                    }
                }

                // **How old it is, and where it stands.** Both are the plant
                // now rather than the meeting it came from, so they are one
                // group of their own under the meeting's — and both survive a
                // plant with no meeting written down, which the block above
                // does not.
                VStack(spacing: 4) {
                    Text(verbatim: live.growth(now: model.now).caption())
                        .chromeLabel(size: 10)
                        .foregroundStyle(Chrome.faint)
                    standing
                }
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: Chrome.readableWidth)
            .padding(.bottom, 22)

            // **Said when the word is asked for, not while it is held.** Under
            // the thumb for the three seconds of the hold, it went before
            // anybody could read it; here it stays for as long as the word is
            // out, and the hold comes after it has been read.
            if expandedMark == "release" {
                Text(sending ? Self.releaseSending : releaseTrouble ?? Self.releaseConsequence)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Chrome.muted)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                    .frame(maxWidth: Chrome.readableWidth)
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }

            marks
                .frame(maxWidth: Chrome.readableWidth)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)

        }
    }

    /// This plant as the garden holds it now.
    ///
    /// **`record` is a copy taken when the screen opened**, and the asking
    /// changes a plant while the screen is up: a plant offered a moment ago
    /// went on saying *Show in the peace garden*, which is a screen telling
    /// somebody their own action did not happen. The garden is observed, so
    /// reading it here is what redraws the row.
    /// **Everything on this screen reads `live`, not `record`.**
    ///
    /// It began as a fix for one thing — a value copy went stale, so an offered
    /// plant went on saying *Show in the peace garden* — and the plant, its
    /// name and its meeting were still read from the copy. That was invisible
    /// until the chevrons arrived and stepped to the next plant: the standing
    /// and the marks changed and the plant on screen did not, which looks like
    /// a screen that has stopped working.
    private var live: PlantRecord {
        let id = stepped ?? record.id
        return model.garden.plants.first { $0.id == id }
            ?? model.garden.plants.first { $0.id == record.id }
            ?? record
    }

    /// The ones still waiting on an answer, in the order the garden holds them.
    private var waiting: [PlantRecord] { model.invited }

    /// One chevron, if there is anywhere for it to go.
    ///
    /// **Sitting in the veil's own window**, the band across the middle where
    /// `StageVeil` lets the plant through and no word stands — so it is clear
    /// of the name above and the row of marks below at every size, and it does
    /// not need a background of its own to be legible.
    @ViewBuilder
    private func chevron(towardsTrailing: Bool) -> some View {
        let others = waiting
        if others.count > 1, others.contains(where: { $0.id == live.id }), !releasing, !sending {
            Button { step(towardsTrailing ? 1 : -1, through: others) } label: {
                ChevronGlyph(towardsTrailing: towardsTrailing)
                    .stroke(Chrome.pinkGold.opacity(0.75), style: Chrome.monoline)
                    .frame(width: 14, height: 26)
                    // Room round it for a finger, without a ring drawn to say
                    // so, and off the very edge of the glass where a thumb
                    // resting on the phone would find it by accident.
                    .padding(18)
                    .padding(.horizontal, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .transition(.opacity)
        }
    }

    /// Walks to the next plant waiting on an answer, and round at the end.
    ///
    /// Round rather than stopping, because the row is short and a chevron that
    /// went dead at one end would be a control that changes its mind.
    private func step(_ by: Int, through others: [PlantRecord]) {
        guard let at = others.firstIndex(where: { $0.id == live.id }) else { return }
        let next = others[(at + by + others.count) % others.count]
        withAnimation(Chrome.fadeIn) {
            detailsVisible = true
            stepped = next.id
        }
    }

    /// Where this plant stands with the shared garden on the web, in a line.
    ///
    /// **A plant that is on the web looks different from one that is not**, and
    /// somebody who cannot tell at a glance has been handed a decision they
    /// cannot review (`docs/WEBSITE.md`). A state is not a thing to press, so
    /// it is said here and the pressing is in the row below.
    @ViewBuilder
    private var standing: some View {
        switch live.standingOrHere.state {
        case .asked:
            standingLine("Waiting on \(live.encounter?.peerDisplayName ?? String(localized: "the other gardener"))")
        case .shown:
            standingLine("In the public website garden")
        // One line for both endings. They are different events — the other
        // gardener said no, or one of the two took it back — but what a person
        // needs off this screen is where the plant is, and a line naming whose
        // decision it was would put somebody else's answer on your screen in
        // their name.
        case .declined, .withdrawn:
            standingLine("In this garden only")
        case .here, .invited, .unknown:
            EmptyView()
        }
    }

    /// Everything that can be done to this plant, as marks.
    ///
    /// **The same row as the foot of the stage**, which is the app's one way of
    /// offering more than one thing at once: a glyph in a circle, its word only
    /// once it has been asked for, and one word at a time because four of them
    /// do not fit in any language. `ChromeMark` is shared with the stage so the
    /// two rows cannot drift apart.
    ///
    /// **Release is a mark too, and still a hold.** It was a Settings row on a
    /// screen that has no Settings rows — a different type, a different colour
    /// and a different alignment from everything beside it. What made it a hold
    /// is that it cannot be undone, and that is true of it whatever it is
    /// wearing, so it wears a mark's clothes and keeps the three seconds.
    @ViewBuilder
    private var marks: some View {
        let plant = live
        HStack(spacing: 10) {
            Spacer(minLength: 0)

            ChromeMark(
                glyph: AnyShape(PencilShape()),
                name: "meeting",
                title: "The meeting",
                expanded: $expandedMark
            ) { editing = true }

            if plant.canBeOffered {
                ChromeMark(
                    glyph: AnyShape(GardenGlyph()),
                    name: "show",
                    title: "Show",
                    expanded: $expandedMark
                ) { showing = true }
            }

            if plant.standingOrHere.state == .invited {
                ChromeMark(
                    glyph: AnyShape(GardenGlyph()),
                    name: "answer",
                    title: "Answer",
                    isProminent: true,
                    expanded: $expandedMark
                ) { showing = true }
            }

            if plant.standingOrHere.isShown {
                ChromeMark(
                    glyph: AnyShape(CycleGlyph()),
                    name: "back",
                    title: "Take it back",
                    expanded: $expandedMark
                ) { takeItBack() }
            }

            releaseMark

            Spacer(minLength: 0)
        }
    }

    /// Letting a plant go, which is the one thing on this screen that cannot be
    /// taken back — so it is held rather than tapped.
    ///
    /// A tap unrolls its word like any other mark; the hold is what fires it.
    /// `HoldToConfirm` also carries the assisted path: a three-second press is
    /// a motor task, and for somebody who cannot make one the mark becomes an
    /// ordinary button and the alert comes back.
    /// One sentence, said above the row when the word is out and carried by
    /// the alert on the assisted path.
    static let releaseConsequence: LocalizedStringResource = "It leaves your garden for the Wild Fields. The person you grew it with keeps theirs, and every other plant here stays where it is."

    /// In the sentence's place while the plant is on its way, which is
    /// usually under a second and is long enough on a slow connection for a
    /// still plant to look like a hold that did nothing.
    static let releaseSending: LocalizedStringResource = "Sending it to the Wild Fields…"

    /// In the sentence's place when it did not arrive. **One sentence for
    /// every failure**, as the asking has (`ShowInGardenView`), and it has to
    /// be true of each: no signal, a service that refused, and a service
    /// saying this phone has released a lot lately. What matters is the
    /// second clause — the plant is still here — because the last time release
    /// failed, it failed silently and the plant was gone.
    static let releaseFailed: LocalizedStringResource = "The Wild Fields could not be reached just now, so this plant is still here. Try again in a little while."

    private var releaseMark: some View {
        HoldToConfirm(
            title: "Release",
            // Worded for what survives, the way the three in Settings are. No
            // name in it: a name would make this a format string for the sake
            // of a fact the sentence does not need, and the person is already
            // named on the screen above it.
            consequence: Self.releaseConsequence,
            // Its own mark, drawn for this: a head let go and its seeds
            // lifting away. It had been borrowing the garden's, which says the
            // opposite of where a released plant goes.
            glyph: AnyShape(ReleaseGlyph()),
            tint: Chrome.ochre,
            filledForeground: Chrome.nearBlack,
            action: { release() },
            askInstead: { confirming = true },
            dress: .mark(showsTitle: expandedMark == "release")
        )
        // Collapsed, a tap unrolls the word rather than starting a hold nobody
        // asked for; unrolled, the hold is the only thing that fires — and not
        // a second time while the first is on its way.
        .allowsHitTesting(expandedMark == "release" && !sending)
        .overlay {
            if expandedMark != "release" {
                Color.clear
                    .contentShape(Capsule())
                    .onTapGesture { withAnimation(Chrome.fadeIn) { expandedMark = "release" } }
            }
        }
        .fixedSize(horizontal: true, vertical: true)
    }

    private func standingLine(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .chromeLabel(size: 10)
            .foregroundStyle(Chrome.faint)
            .padding(.top, 4)
    }

    private func takeItBack() {
        Task { await model.withdraw(live) }
    }

    /// The light the plant leaves as.
    ///
    /// Its own flower's hue, and almost none of its own saturation. A light is
    /// white at its core whatever colour it casts, and a fully saturated dot
    /// reads as a petal that came loose rather than as the plant going.
    private var lightColour: Color {
        let tip = live.genome.palette.petalTip
        return Color(hue: tip.hue, saturation: 0.18, brightness: 1)
    }

    /// Sends the plant to the Wild Fields, and removes it when it has gone.
    ///
    /// **It goes only when the Wild Fields have it.** Until 1 October 2026
    /// this animated and deleted and sent nothing, under a sentence saying the
    /// plant left for the Wild Fields — so a plant let go went nowhere. Now
    /// the hold sends it (`GardenModel.release`) and the plant stands still
    /// until the service answers: on its word the light leaves and the plant
    /// goes; without it the plant stays, and the sentence under the row says
    /// so. Nothing is queued — see `GardenModel.release` for why.
    ///
    /// The order after that is the old one, and still matters. Deleting first
    /// and animating afterwards would be an animation of a plant that no
    /// longer exists — and `dismiss()` on a record the garden has already
    /// dropped is the shape of a crash. So the record stands until the light
    /// is off the screen. If the screen is closed while the plant is on its
    /// way, the task carries on and removes it all the same once it arrives.
    ///
    /// The plant on the screen is `live`, not `record`: the chevrons can have
    /// stepped to another plant since the screen opened, and it is the one in
    /// front of the person that they let go.
    ///
    /// Reduce Motion gets the same two facts in a quarter of a second: the
    /// plant goes, and the screen closes. The objection is to being held
    /// through choreography, not to knowing what happened.
    private func release() {
        guard !releasing, !sending else { return }
        let plant = live
        sending = true
        releaseTrouble = nil

        Task {
            let arrived = await model.release(plant)
            sending = false
            guard case .success = arrived else {
                withAnimation(Chrome.fadeIn) { releaseTrouble = Self.releaseFailed }
                return
            }
            releasing = true
            let flightTime: Double = reduceMotion ? 0.25 : 1.7
            withAnimation(.easeOut(duration: flightTime)) { flight = 1 }
            try? await Task.sleep(for: .seconds(flightTime + 0.15))
            model.delete(plant)
            dismiss()
        }
    }
}

/// The light coming off the stage while there is something to read over it.
///
/// One gradient, darkest at the two ends and thinnest across the middle third.
/// The ends are where the words are — a name and an age at the top, a meeting
/// and what can be done about it at the foot — and the middle is the part of a
/// plant worth looking at, so the veil is shaped like the screen's own use
/// rather than laid on evenly.
///
/// `Chrome.ground` rather than black, so it takes the light out of a dark
/// stage and puts it back into a pale one, and the words above it stay the
/// same words in both.
struct StageVeil: View {
    /// How much of the screen the words take.
    ///
    /// **The veil is cut to the words, not to the plant.** On the detail screen
    /// there is a name at the top, a few grey lines at the foot and a third of
    /// the screen with nothing on it, so the veil opens wide in the middle. The
    /// consent screen is four paragraphs and two buttons: opening it there put
    /// a flower head behind a sentence, which is a plant nobody can look at and
    /// a sentence nobody can read. So it keeps a narrower window, lower down,
    /// where the stem is and no word stands.
    enum Cut { case stage, reading }

    var cut: Cut = .stage

    var body: some View {
        LinearGradient(
            stops: cut == .reading ? Self.reading : Self.stage,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private static let reading: [Gradient.Stop] = [
        .init(color: Chrome.ground.opacity(0.94), location: 0),
        .init(color: Chrome.ground.opacity(0.90), location: 0.30),
        // Through the facts, which run to a little over half way.
        .init(color: Chrome.ground.opacity(0.88), location: 0.56),
        // The window: the stem, between the last fact and the first button.
        .init(color: Chrome.ground.opacity(0.34), location: 0.63),
        .init(color: Chrome.ground.opacity(0.34), location: 0.75),
        .init(color: Chrome.ground.opacity(0.88), location: 0.81),
        .init(color: Chrome.ground.opacity(0.96), location: 1),
    ]

    private static let stage: [Gradient.Stop] = [
        // The name and the age.
        .init(color: Chrome.ground.opacity(0.90), location: 0),
        .init(color: Chrome.ground.opacity(0.80), location: 0.11),
        .init(color: Chrome.ground.opacity(0.40), location: 0.22),
        // The window: a third of the screen with almost nothing on it, and the
        // part of a plant worth looking at.
        .init(color: Chrome.ground.opacity(0.22), location: 0.28),
        .init(color: Chrome.ground.opacity(0.22), location: 0.46),
        // Down to the meeting and what can be done about it. Nearly solid,
        // because the words here are small and grey and a plant read through
        // them is a plant nobody chose to look at: the tap that put these words
        // up takes them down again.
        .init(color: Chrome.ground.opacity(0.72), location: 0.60),
        .init(color: Chrome.ground.opacity(0.95), location: 0.72),
        .init(color: Chrome.ground.opacity(0.97), location: 1),
    ]
}
