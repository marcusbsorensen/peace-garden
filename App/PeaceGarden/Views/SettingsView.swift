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
    @AppStorage(Chrome.showsStageKey) private var showsStage = true
    @AppStorage(Chrome.turntableKey) private var turntable = true
    @AppStorage(Chrome.menuStyleKey) private var menuStyleRaw = StageMenuStyle.hidden.rawValue
    @AppStorage(Chrome.appearanceKey) private var appearanceRaw = StageAppearance.dark.rawValue
    @AppStorage(Chrome.plantStyleKey) private var plantStyleRaw = StagePlantStyle.full.rawValue
    @AppStorage(Chrome.plantTintKey) private var plantTint = Chrome.plantTintDefault
    @AppStorage(Chrome.placeModeKey) private var placeModeRaw = PlantingLocationMode.abstract.rawValue
    @AppStorage(Chrome.placeCustomKey) private var customPlace = ""

    private var menuStyle: StageMenuStyle {
        StageMenuStyle(rawValue: menuStyleRaw) ?? .hidden
    }
    private var appearance: StageAppearance {
        StageAppearance(rawValue: appearanceRaw) ?? .dark
    }
    private var plantStyle: StagePlantStyle {
        StagePlantStyle(rawValue: plantStyleRaw) ?? .full
    }
    private var placeMode: PlantingLocationMode {
        PlantingLocationMode(rawValue: placeModeRaw) ?? .abstract
    }

    /// The two irreversible ones, and the one that only forgets plants.
    private enum Reset: String, Identifiable {
        case seed
        case plants
        case everything

        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Chrome.ground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Text("Settings")
                        .chromeHeading()
                        .foregroundStyle(Chrome.ink)

                    // Grouped by the question each answers rather than by the
                    // order they were built in. Four headings, and the one
                    // thing that moved between them is the username: it is not
                    // a display choice, it is what the other phone is told you
                    // are called, so it belongs with the rest of what crosses
                    // between two people.
                    section("Display") { display }
                    Hairline()
                    section("Seed planting location") { plantingLocation }
                    Hairline()
                    section("Joint seeds") { jointSeeds }
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
            // A question of its own per row, rather than a row's label with a
            // question mark stuck on the end. Composing one produced the key
            // `"%@?"`, which is a format a translator cannot do anything with —
            // and in a language that puts its question word first there is
            // nothing for a trailing `?` to be stuck on to.
            confirming.map { Text(alertTitle($0)) } ?? Text(verbatim: ""),
            isPresented: confirmingBinding,
            presenting: confirming
        ) { reset in
            Button("Leave it", role: .cancel) {}
            Button(role: .destructive) { perform(reset) } label: {
                Text(confirmLabel(reset))
            }
        } message: { reset in
            Text(consequence(reset))
        }
    }

    // MARK: - The shape of a section

    /// A heading and the settings under it.
    ///
    /// The screen was a flat list of six things with a rule between each, which
    /// is fine at six and stops being fine the moment there are ten. A heading
    /// says which question the switches under it are answering, and that is
    /// what lets somebody find the one they came for without reading the rest.
    @ViewBuilder
    private func section(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            // The heading voice rather than the label voice. At twelve points
            // in the label voice it was the same object as the labels under it
            // — same case, same tracking, a point of size and a shade of grey
            // between them — and a hierarchy the reader has to measure is not
            // one. Wider tracking is what separates them without shouting.
            Text(title)
                .chromeHeading(size: 13)
                .foregroundStyle(Chrome.ink)
            content()
        }
    }

    /// A switch, and the sentence under it if it needs one.
    ///
    /// Most do not. A line of explanation under a switch whose label already
    /// says what it does is a line somebody has to read to discover it was not
    /// worth reading.
    @ViewBuilder
    private func switchRow(
        _ title: LocalizedStringKey,
        note: LocalizedStringKey? = nil,
        isOn: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: isOn) {
                Text(title)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Chrome.ink)
            }
            .tint(Chrome.muted)

            if let note {
                Text(note)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Chrome.muted)
                    .lineSpacing(4)
            }
        }
    }

    /// A label, and a menu of answers under it.
    @ViewBuilder
    private func chooser(
        _ title: LocalizedStringKey,
        current: Text,
        note: LocalizedStringKey? = nil,
        @ViewBuilder options: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .chromeLabel()
                .foregroundStyle(Chrome.sectionLabel)

            Menu {
                options()
            } label: {
                HStack(spacing: 10) {
                    current
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Chrome.ink)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Chrome.faint)
                }
                .pressable()
            }

            if let note {
                Text(note)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Chrome.muted)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Display

    /// What is on the stage besides the plant.
    ///
    /// Every one of these can be turned off, and with all of them off the stage
    /// is the plant and the light it stands in and nothing else — which is
    /// worth having for its own sake, and is also the only state of this app
    /// that is already in every language.
    private var display: some View {
        VStack(alignment: .leading, spacing: 22) {
            switchRow("Show plant name", isOn: $namesPlant)
            switchRow("Show growth stage", isOn: $showsStage)

            chooser(
                "Menu bar",
                current: Text(menuStyle.label),
                note: "Hidden keeps the plant alone until you touch the screen. Marks and words is one tap to anything."
            ) {
                ForEach(StageMenuStyle.allCases, id: \.self) { style in
                    Button { menuStyleRaw = style.rawValue } label: { Text(style.label) }
                }
            }

            switchRow(
                "Let the plant turn",
                note: "Off, it stays where you leave it and turns only when you drag it.",
                isOn: $turntable
            )

            chooser("How the plant is drawn", current: Text(plantStyle.label)) {
                ForEach(StagePlantStyle.allCases, id: \.self) { style in
                    Button { plantStyleRaw = style.rawValue } label: { Text(style.label) }
                }
            }

            // Only where it is the plant's whole colour. Offering a tint for a
            // plant that is already wearing its own is offering a control that
            // does nothing.
            if plantStyle.isTinted {
                ColorPicker(selection: tintBinding, supportsOpacity: false) {
                    Text("Its colour")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Chrome.ink)
                }
            }

            chooser(
                "Appearance",
                current: Text(appearance.label),
                note: "The garden was black from the first screen, so a plant would be the only colour in front of you. Light gives that up for a phone in sunlight."
            ) {
                ForEach(StageAppearance.allCases, id: \.self) { option in
                    Button { appearanceRaw = option.rawValue } label: { Text(option.label) }
                }
            }
        }
    }

    /// The picker speaks `Color`; the default is six hex digits, because a
    /// colour that has to survive a reinstall has to be something a plist can
    /// hold.
    private var tintBinding: Binding<Color> {
        Binding(
            get: { Color(hex: plantTint) },
            set: { plantTint = $0.hex }
        )
    }

    // MARK: - Seed planting location

    /// Where a seed says it was planted, and in which of the two languages the
    /// app has for saying it.
    ///
    /// These were two settings a screen apart — a menu of figurative places and
    /// a switch that wrote down a coordinate — and they answer the same
    /// question. Only one of them can be the answer, so they are one control
    /// with two states rather than two controls that can disagree.
    private var plantingLocation: some View {
        VStack(alignment: .leading, spacing: 22) {
            chooser("How the place is said", current: Text(placeMode.label)) {
                ForEach(PlantingLocationMode.allCases, id: \.self) { mode in
                    Button { choose(mode) } label: { Text(mode.label) }
                }
            }

            switch placeMode {
            case .abstract:
                // What is *stored* is the English phrase, which is also the
                // catalogue key — so a standing choice made in one language is
                // still the same place after the phone is switched to another.
                // Storing what was on screen would have made the preference
                // stop matching the list the moment the language changed.
                chooser(
                    "Which one",
                    current: Places.stored(preferredPlace).map(Text.init)
                        ?? Text("Wherever the seed travelled"),
                    note: "Shown when a seed is exchanged with another, as the place where the seed is planted."
                ) {
                    Button("Wherever the seed travelled") { preferredPlace = "" }
                    Divider()
                    ForEach(Places.all, id: \.key) { option in
                        Button { preferredPlace = option.key } label: { Text(option) }
                    }
                }

            case .geographic:
                VStack(alignment: .leading, spacing: 8) {
                    if !place.isEnabled {
                        // Choosing the mode is not the same as granting the
                        // permission, and the phone will ask separately. Say so
                        // rather than leaving somebody looking at a setting
                        // that has quietly not taken.
                        Text("Waiting for you to allow location.")
                            .chromeLabel()
                            .foregroundStyle(Chrome.sectionLabel)
                    }
                    Text("A seed planted while this is on carries the coordinates the phone measured, to five decimal places. Nothing is looked up and no place is named — the numbers are the honest record, and a map can say the rest.")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Chrome.muted)
                        .lineSpacing(4)
                }

            case .custom:
                VStack(alignment: .leading, spacing: 0) {
                    Text("What it says")
                        .chromeLabel()
                        .foregroundStyle(Chrome.sectionLabel)
                        .padding(.bottom, 10)

                    TextField("Where you were", text: $customPlace)
                        .font(.system(size: 17, weight: .light, design: .serif))
                        .foregroundStyle(Chrome.ink)
                        .multilineTextAlignment(.center)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .padding(.horizontal, 26)
                        .underlining()

                    Text("Whatever you write goes to the other phone as it stands. It is the one place in this app where a seed carries a sentence somebody chose rather than one the app offered.")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Chrome.muted)
                        .lineSpacing(4)
                        .padding(.top, 6)
                }
            }

            // The plainest account this app gives of what leaves the phone, and
            // it stays whichever of the three is chosen.
            Text("When you meet someone, your phones exchange your seed, your name, and a random number for that meeting. That is everything that crosses between you, and it goes directly from phone to phone. A seed cannot be turned back into anything about you or your phone.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
    }

    /// Choosing the mode is what turns location on and off.
    ///
    /// `PlaceKeeping` is still the single thing that owns the permission — this
    /// only tells it which way the choice went, so there is no state in which
    /// the mode says one thing and the switch says another.
    private func choose(_ mode: PlantingLocationMode) {
        placeModeRaw = mode.rawValue
        if mode == .geographic {
            place.enable()
        } else if place.isEnabled {
            place.disable()
        }
    }

    // MARK: - Joint seeds

    /// What the other phone is told, and what this one is told back.
    ///
    /// The username lives here rather than under Display because it is not
    /// something you look at — it is what somebody else sees when your seeds
    /// cross, which is the same question the switch under it answers.
    private var jointSeeds: some View {
        VStack(alignment: .leading, spacing: 22) {
            username

            switchRow(
                "Alert me when a joint seed is shared",
                note: "Your username will only show publicly if you approve.",
                isOn: $wantsInvitations
            )
        }
    }

    /// One layout, always.
    ///
    /// It used to swap a `Button` for a `TextField` when editing began, which
    /// put two different layouts in one slot and landed the `SproutingRule` on
    /// top of the field's own baseline. The field is a field from the moment
    /// the screen opens, the rule is its underline throughout, and there is
    /// nothing left to collide.
    private var username: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Gardener username")
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
                // value is yours to fill in. The tendrils open upward out of
                // it, which is the way everything else in this app opens.
                .underlining()
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

    private func commitName() {
        model.rename(to: draftName)
    }

    // MARK: - Starting again

    /// Three rows that are held rather than tapped — see `HoldToConfirm` for
    /// why. Their consequences are gone from the screen and come back under
    /// whichever row is being held, which is the only moment those words were
    /// ever for.
    private var startingAgain: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Starting again")
                .chromeHeading(size: 13)
                .foregroundStyle(Chrome.ink)

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

    private func label(_ reset: Reset) -> LocalizedStringResource {
        switch reset {
        case .seed: return "Get a new seed"
        case .plants: return "Empty the garden"
        case .everything: return "Reset everything"
        }
    }

    /// What the alert asks, on the assisted path. One sentence per row rather
    /// than the row's label turned into a question.
    private func alertTitle(_ reset: Reset) -> LocalizedStringResource {
        switch reset {
        case .seed: return "Get a new seed?"
        case .plants: return "Empty the garden?"
        case .everything: return "Reset everything?"
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

    private func confirmLabel(_ reset: Reset) -> LocalizedStringResource {
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
    private func consequence(_ reset: Reset) -> LocalizedStringResource {
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
