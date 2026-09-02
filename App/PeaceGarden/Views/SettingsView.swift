import SwiftUI
import SeedCore

/// The standing choices, and the three ways to start again.
///
/// Everything here is a preference rather than a fact about a plant. The seed,
/// the lineage and the birthday are not reachable from this screen and are not
/// meant to be: they are what a plant *is*, and the only thing anybody can do
/// to a seed is draw a different one.
///
/// **The screen says what each control does, and earns a line underneath only
/// where something would otherwise surprise somebody.** It carried a paragraph
/// under every control once — around three hundred words for five decisions,
/// each of them repeating what the confirmation alert then said again. Three of
/// the five sections need no line at all, and the three that take something
/// away say their piece at the moment somebody is deciding rather than while
/// they are reading.
struct SettingsView: View {
    @Environment(GardenModel.self) private var model
    @Environment(PlaceKeeping.self) private var place
    /// Closing is the caller's to do, because this screen is not presented:
    /// it is a layer `PlantStageView` slides down over the stage, so there is
    /// no sheet for `dismiss` to reach.
    let close: () -> Void

    @State private var draftName = ""
    @FocusState private var editingName: Bool
    @State private var confirming: Reset?
    @AppStorage(Places.preferredKey) private var preferredPlace = ""
    @AppStorage(Sharing.invitationsKey) private var wantsInvitations = Sharing.invitationsDefault
    @AppStorage(Chrome.namesPlantKey) private var namesPlant = true

    /// The two irreversible ones, and the one that only forgets plants.
    private enum Reset: String, Identifiable {
        case seed
        case plants
        case everything

        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Text("Settings")
                        .chromeHeading()
                        .foregroundStyle(Chrome.ink)

                    name
                    Hairline()
                    plantScreen
                    Hairline()
                    places
                    Hairline()
                    whereYouMeet
                    Hairline()
                    beingTold
                    Hairline()
                    startingAgain
#if DEBUG
                    Hairline()
                    DeveloperSection(close: close)
                        .environment(model)
#endif
                }
                .padding(.horizontal, 30)
                .padding(.top, 34)
                .padding(.bottom, 60)
                .frame(maxWidth: Chrome.readableWidth)
                .frame(maxWidth: .infinity)
            }
            // The field is on the rule near the top of a scroll view, so the
            // keyboard has never covered it — but a name typed and then
            // scrolled away from should still be kept, which is what losing
            // focus does below.
            .scrollDismissesKeyboard(.interactively)
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: "Close") { close() }
                .padding(.trailing, 12)
                .padding(.top, 8)
        }
        .onAppear { draftName = model.identity?.displayName ?? "" }
        // The alert is the assisted path only: `HoldToConfirm` asks for it when
        // a sustained press is not available. An alert rather than a
        // confirmation dialog, because the dialog rendered its destructive
        // button and dropped the cancel entirely on a sheet with a black
        // presentation background, which leaves an irreversible action with no
        // visible way out of it.
        .alert(
            confirming.map { "\(label($0))?" } ?? "",
            isPresented: confirmingBinding,
            presenting: confirming
        ) { reset in
            Button("Leave it", role: .cancel) {}
            Button(confirmLabel(reset), role: .destructive) { perform(reset) }
        } message: { reset in
            Text(consequence(reset))
        }
    }

    // MARK: - The name

    /// One layout, always.
    ///
    /// It used to swap a `Button` for a `TextField` when editing began, which
    /// put two different layouts in one slot and landed the `SproutingRule` on
    /// top of the field's own baseline. The field is a field from the moment
    /// the screen opens, the rule is its underline throughout, and there is
    /// nothing left to collide.
    private var name: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your Peace Garden username")
                .chromeLabel()
                .foregroundStyle(Chrome.sectionLabel)
                .padding(.bottom, 10)

            // "Gardener" is the prompt rather than the text. It is what the
            // other phone shows until a name is chosen, so it belongs on
            // screen — but writing it into the field would let a stray commit
            // turn the fallback into an actual choice.
            TextField("Gardener", text: $draftName)
                .font(.system(size: 17, weight: .light, design: .serif))
                .foregroundStyle(Chrome.ink)
                // Centred on the rule rather than tucked against its leading
                // end, where a short name looked like it had fallen off.
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($editingName)
                .onSubmit { commitName() }
                // The pencil is laid over the trailing end rather than set
                // beside the field, so the field keeps the full width of the
                // rule and its centre is the rule's centre.
                .padding(.horizontal, 26)
                .overlay(alignment: .trailing) {
                    PencilShape()
                        .stroke(Chrome.faint, style: Chrome.monoline)
                        .frame(width: 14, height: 14)
                }
                // A rule under a value is the oldest signal in print that the
                // value is yours to fill in. Curling down because the tendrils
                // open upward into the line of type otherwise.
                .underlining(curlingDown: true)
                // The pencil is an affordance rather than a button: anywhere on
                // the row the field does not already take focuses the field.
                .contentShape(Rectangle())
                .onTapGesture { editingName = true }

            Text("Plants grown under this name will keep it.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
                .padding(.top, 6)
        }
        // Committed on losing focus as well as on submit, so a name typed and
        // then dismissed is kept rather than silently dropped.
        .onChange(of: editingName) { _, focused in
            if !focused { commitName() }
        }
    }

    /// `rename` keeps an empty name out of the garden on its own, so a field
    /// cleared and left is the same as one never touched.
    private func commitName() {
        model.rename(to: draftName)
    }

    // MARK: - What the stage says

    /// Whether the plant is captioned.
    ///
    /// Off leaves the plant, the light it stands in, and a row of marks — and
    /// not one word on screen. That is worth having for its own sake, and it
    /// is also the only state of this app that is already in every language,
    /// which is why the line underneath says so plainly rather than selling it
    /// as a preference about clutter.
    private var plantScreen: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $namesPlant) {
                Text("Name the plant on screen")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Chrome.ink)
            }
            .tint(Chrome.muted)

            Text("Off, the stage is the plant and the marks along the foot, in no language at all.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
    }

    // MARK: - The place a note arrives holding

    /// A standing answer for the Where field.
    ///
    /// Left alone, each meeting is offered the place its own seed travelled
    /// through — see `Places`. Choosing one here says the same thing every
    /// time instead, which suits somebody who meets people in one place.
    private var places: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Default seed planting location")
                .chromeLabel()
                .foregroundStyle(Chrome.sectionLabel)

            Menu {
                Button("Wherever the seed travelled") { preferredPlace = "" }
                Divider()
                ForEach(Places.all, id: \.self) { option in
                    Button(option) { preferredPlace = option }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(preferredPlace.isEmpty ? "Wherever the seed travelled" : preferredPlace)
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Chrome.ink)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Chrome.faint)
                }
                .pressable()
            }
        }
    }

    // MARK: - Places on the earth

    /// The same switch as the one on the seed screen, writing through the same
    /// owner. It appears twice because it answers two different questions —
    /// "what leaves my phone" over there, and "what is turned on" here — and
    /// `PlaceKeeping` is the single thing either one sets.
    ///
    /// *Log*, not *keep*. Keep can mean hold on to and it can mean keep away,
    /// keep back, keep out, and on a privacy control that second reading points
    /// in exactly the wrong direction. Log says what happens: a coordinate is
    /// written down.
    private var whereYouMeet: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: placeBinding) {
                Text("Log where new seeds are planted")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Chrome.ink)
            }
            .tint(Chrome.muted)

            Text("By default, only you see this.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)

            // Moved here from the seed screen, which was carrying a switch and
            // a paragraph that both belonged with the other standing choices.
            // The paragraph came with the switch rather than being dropped: it
            // is the plainest account this app gives of what leaves the phone,
            // and losing it to a tidy-up would have been the tidy-up costing
            // more than it saved.
            Text("When you meet someone, your phones exchange your seed, your name, and a random number for that meeting. That is everything that crosses between you, and it goes directly from phone to phone. A seed cannot be turned back into anything about you or your phone.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
                .padding(.top, 2)
        }
    }

    private var placeBinding: Binding<Bool> {
        Binding(
            get: { place.isEnabled },
            set: { $0 ? place.enable() : place.disable() }
        )
    }

    // MARK: - Being told about a share

    /// The one thing the shared garden will ever ask of somebody who is not
    /// using it.
    ///
    /// A plant belongs to two people, so one of them putting it in the peace
    /// garden is one of them speaking, and the page carries that person's name
    /// alone. This is the offer to be named alongside them — and the offer is
    /// all it is, because until somebody accepts, the page says nothing about
    /// them at all.
    ///
    /// The switch does nothing today: phase 1 makes no network request, so
    /// there is nothing that could tell this phone a plant was shared. It is
    /// here because it is a decision about what somebody agrees to be told, and
    /// that belongs beside their other decisions rather than arriving with the
    /// feature. See docs/PHASES.md.
    private var beingTold: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $wantsInvitations) {
                Text("Alert me when a joint seed is shared")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Chrome.ink)
            }
            .tint(Chrome.muted)

            Text("Your username will only show publicly if you approve.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
    }

    // MARK: - Starting again

    /// Three rows that are held rather than tapped — see `HoldToConfirm` for
    /// why. Their consequences are gone from the screen and come back under
    /// whichever row is being held, which is the only moment those words were
    /// ever for.
    private var startingAgain: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Starting again")
                .chromeLabel()
                .foregroundStyle(Chrome.sectionLabel)

            row(.seed)

            if !model.hybrids.isEmpty {
                row(.plants)
            }

            row(.everything)
        }
    }

    private func row(_ reset: Reset) -> some View {
        HoldToConfirm(
            title: label(reset),
            consequence: consequence(reset),
            glyph: glyph(reset),
            tint: tint(reset),
            filledForeground: filledForeground(reset),
            action: { perform(reset) },
            askInstead: { confirming = reset }
        )
    }

    // MARK: - What each row is

    private func label(_ reset: Reset) -> String {
        switch reset {
        case .seed: return "Get a new seed"
        case .plants: return "Empty the garden"
        case .everything: return "Reset everything"
        }
    }

    /// Monoline and round-ended, per BRAND.md §3.2 — the same hand as the cog
    /// that opened this screen.
    private func glyph(_ reset: Reset) -> AnyShape {
        switch reset {
        case .seed: return AnyShape(SeedGlyph())
        case .plants: return AnyShape(GardenGlyph())
        case .everything: return AnyShape(CycleGlyph())
        }
    }

    /// The middle one is inferred rather than specified: a row with no colour
    /// sitting between two that have it reads as unfinished rather than as
    /// restraint. Ochre sits between the other two because its consequence
    /// does — your seed and its plant stay, and only what you grew with other
    /// people goes.
    private func tint(_ reset: Reset) -> Color {
        switch reset {
        case .seed: return Chrome.pinkGold
        case .plants: return Chrome.ochre
        case .everything: return Chrome.crimson
        }
    }

    private func filledForeground(_ reset: Reset) -> Color {
        switch reset {
        case .seed, .plants: return Chrome.nearBlack
        case .everything: return Chrome.ink
        }
    }

    // MARK: - Confirming

    private var confirmingBinding: Binding<Bool> {
        Binding(
            get: { confirming != nil },
            set: { if !$0 { confirming = nil } }
        )
    }

    private func confirmLabel(_ reset: Reset) -> String {
        switch reset {
        case .seed: return "Get a new seed"
        case .plants: return "Empty it"
        case .everything: return "Reset everything"
        }
    }

    /// Said under a row while it is held, and in the alert on the assisted
    /// path. Each is worded for what survives rather than for what goes,
    /// because what people need before deciding is what they still have
    /// afterwards — including the reassurance about other people's gardens,
    /// which used to stand at the foot of the screen for everybody and now
    /// arrives inside the two sentences that need it.
    private func consequence(_ reset: Reset) -> String {
        switch reset {
        case .seed:
            return "The plant you have now was created once and this creates another. Your garden keeps every plant you have grown with somebody, and so do they."
        case .plants:
            return "Your own seed and its plant stay. The people you grew those plants with keep theirs."
        case .everything:
            return "Your seed, your plant and your garden all go. The people you have met keep the plants you grew together."
        }
    }

    private func perform(_ reset: Reset) {
        switch reset {
        case .seed: model.resetSeed()
        case .plants: model.forgetPlants()
        case .everything: model.resetEverything()
        }
        confirming = nil
        close()
    }
}
