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
    /// The shared garden's one screen, for asking or for answering.
    @State private var showing = false
    /// Which mark in the row along the foot has its word unrolled. One at a
    /// time: the row is one width wide.
    @State private var expandedMark: String?
    /// The assisted path only, the same as the three rows in Settings:
    /// `HoldToConfirm` asks for this when a sustained press is not available.
    @State private var confirming = false

    var body: some View {
        ZStack {
            StageBackdrop(
                palette: record.genome.palette,
                presence: record.growth(now: model.now).heightScale
            )
                .ignoresSafeArea()

            PlantSceneView(
                genome: record.genome,
                growth: record.growth(now: model.now),
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
            QuietButton(title: "Close") { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 12)
                .opacity(releasing ? 0 : 1)
                .allowsHitTesting(!releasing)
                .animation(.easeOut(duration: 0.3), value: releasing)
        }
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
            VStack(spacing: 8) {
                Text(record.genome.name.full)
                    .plantName()
                    .foregroundStyle(Chrome.ink)
                Text(verbatim: record.growth(now: model.now).caption())
                    .chromeLabel()
                    .foregroundStyle(Chrome.faint)
            }
            .padding(.top, 64)

            Spacer()

            if let encounter = record.encounter {
                VStack(spacing: 12) {
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

                    standing
                        .padding(.top, 2)
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: Chrome.readableWidth)
                .padding(.bottom, 22)
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
    private var live: PlantRecord {
        model.garden.plants.first { $0.id == record.id } ?? record
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
            standingLine("In the peace garden")
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
    private var releaseMark: some View {
        HoldToConfirm(
            title: "Release",
            // Worded for what survives, the way the three in Settings are. No
            // name in it: a name would make this a format string for the sake
            // of a fact the sentence does not need, and the person is already
            // named on the screen above it.
            consequence: "It leaves your garden for the Wild Fields. The person you grew it with keeps theirs, and every other plant here stays where it is.",
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
        // asked for; unrolled, the hold is the only thing that fires.
        .allowsHitTesting(expandedMark == "release")
        .overlay {
            if expandedMark != "release" {
                Color.clear
                    .contentShape(Capsule())
                    .onTapGesture { expandedMark = "release" }
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
        let tip = record.genome.palette.petalTip
        return Color(hue: tip.hue, saturation: 0.18, brightness: 1)
    }

    /// Sends the plant off, and removes it when it has gone.
    ///
    /// The order matters. Deleting first and animating afterwards would be an
    /// animation of a plant that no longer exists — and `dismiss()` on a
    /// record the garden has already dropped is the shape of a crash. So the
    /// record stands until the light is off the screen.
    ///
    /// Reduce Motion gets the same two facts in a quarter of a second: the
    /// plant goes, and the screen closes. The objection is to being held
    /// through choreography, not to knowing what happened.
    private func release() {
        guard !releasing else { return }
        releasing = true

        let flightTime: Double = reduceMotion ? 0.25 : 1.7
        withAnimation(.easeOut(duration: flightTime)) { flight = 1 }

        Task {
            try? await Task.sleep(for: .seconds(flightTime + 0.15))
            model.delete(record)
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
    var body: some View {
        LinearGradient(
            stops: [
                // The name and the age.
                .init(color: Chrome.ground.opacity(0.90), location: 0),
                .init(color: Chrome.ground.opacity(0.80), location: 0.11),
                .init(color: Chrome.ground.opacity(0.40), location: 0.22),
                // The window: a third of the screen with almost nothing on it,
                // and the part of a plant worth looking at.
                .init(color: Chrome.ground.opacity(0.22), location: 0.28),
                .init(color: Chrome.ground.opacity(0.22), location: 0.46),
                // Down to the meeting and what can be done about it. Nearly
                // solid, because the words here are small and grey and a plant
                // read through them is a plant nobody chose to look at: the tap
                // that put these words up takes them down again.
                .init(color: Chrome.ground.opacity(0.72), location: 0.60),
                .init(color: Chrome.ground.opacity(0.95), location: 0.72),
                .init(color: Chrome.ground.opacity(0.97), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
