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

                    QuietButton(title: "Tell it differently") { editing = true }
                        .padding(.top, 4)
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: Chrome.readableWidth)
                .padding(.bottom, 18)
            }

            // The same control as the three rows in Settings, for the same
            // reason: this is irreversible, and a hold is a decision where a
            // tap is an accident. `HoldToConfirm` also carries the assisted
            // path — a three-second press is a motor task, and for somebody who
            // cannot make one the row becomes a button and the alert below
            // comes back.
            HoldToConfirm(
                title: "Release to the Wild Fields",
                // Worded for what survives, the way the three in Settings are.
                // No name in it: a name would make this a format string for the
                // sake of a fact the sentence does not need, and the person is
                // already named twice on the screen above it.
                consequence: "It leaves your garden for the Wild Fields. The person you grew it with keeps theirs, and every other plant here stays where it is.",
                glyph: AnyShape(GardenGlyph()),
                tint: Chrome.ochre,
                filledForeground: Chrome.nearBlack,
                action: { release() },
                askInstead: { confirming = true }
            )
            // The row's fill is a `Rectangle`, which takes whatever height it
            // is offered. In Settings it is offered its own, inside a scrolling
            // column; here it sits under a `Spacer` on a full-screen stage and
            // was handed half the screen, drawing a capsule the height of the
            // plant. This asks it for its ideal height and leaves the width to
            // the layout.
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: Chrome.readableWidth)
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
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
