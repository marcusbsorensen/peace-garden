import SwiftUI
import SeedCore

/// The three things a gardener may show beside a plant in the Wild Fields,
/// as three small switches in a row: their name, where they met, when they
/// met. Off until chosen — anonymous is where every choice starts.
///
/// **Words, not glyphs**, though this app prefers a glyph. A mark for *my
/// name* and one for *the month we met* would each need a word to be read,
/// and these are read once, at the moment somebody decides what of theirs
/// goes on the open web; that is the moment for words.
///
/// Used twice: in the release itself, on the plant's screen, before the hold
/// (`PlantDetailView`), and on the screen that tells the other gardener and
/// lets either change their mind (`WildBesideView`).
struct WildChoiceChips: View {
    @Binding var choice: WildChoice
    /// Each false where this phone has nothing to show for it: no gardener
    /// name set, or no place kept for the meeting.
    var hasName: Bool = true
    var hasPlace: Bool = true

    var body: some View {
        // Wraps rather than shrinking, because three words in German do not
        // fit one line of a phone at the size a switch has to be read at.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { chips }
            VStack(spacing: 8) { chips }
        }
    }

    @ViewBuilder
    private var chips: some View {
        chip("Your name", on: $choice.name, enabled: hasName)
        chip("Where you met", on: $choice.place, enabled: hasPlace)
        chip("When you met", on: $choice.month, enabled: true)
    }

    private func chip(_ title: LocalizedStringKey, on: Binding<Bool>, enabled: Bool) -> some View {
        Button {
            withAnimation(Chrome.fadeIn) { on.wrappedValue.toggle() }
        } label: {
            HStack(spacing: 6) {
                // A dot, filled once chosen: the one mark that says *on*
                // without a tick, which reads as a form.
                Circle()
                    .strokeBorder(on.wrappedValue ? Chrome.ochre : Chrome.faint, lineWidth: 1)
                    .background(Circle().fill(on.wrappedValue ? Chrome.ochre : .clear))
                    .frame(width: 7, height: 7)
                Text(title)
                    .chromeLabel(size: 10)
                    .foregroundStyle(on.wrappedValue ? Chrome.ink : Chrome.muted)
                    .lineLimit(1)
                    .fixedSize()
            }
            .pressable(isProminent: on.wrappedValue, horizontal: 12, vertical: 8)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
        .accessibilityAddTraits(on.wrappedValue ? .isSelected : [])
    }
}

/// What stands beside a released plant, and the three choices about it.
///
/// **A moment of contact first** (Marcus, 1 October 2026: *the release is
/// another moment of contact for the gardeners whose seeds germinated the
/// plant*). When the other gardener lets a plant go, this phone is told on
/// its next poll, and this screen is put in front of this person once: the
/// plant you grew with them has gone into the Wild Fields, here it is, and
/// here is what you may show beside it. Left as it is, they are anonymous.
///
/// **And the one place either of them changes their mind**, at any time: the
/// other gardener from the plant's own screen, the one who released it from
/// Settings, where the plants they let go are kept for this.
///
/// Laid out as `ShowInGardenView` is, the plant standing behind the words
/// through the reading veil, because that is the other screen where a plant of
/// two people's is put on the open web.
struct WildBesideView: View {
    let plant: WildPlant

    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var choice: WildChoice = .none
    @State private var working = false
    @State private var trouble: LocalizedStringResource?

    private var peer: String { plant.peerDisplayName }

    /// What is shown now, as the service last said: the latest notice the
    /// model holds for this plant, rather than the copy this screen opened on.
    private var notice: WildNotice? {
        model.wildPlants.first { $0.id == plant.id }?.notice ?? plant.notice
    }

    private var name: String { model.identity?.displayName ?? "" }

    var body: some View {
        ZStack {
            StageBackdrop(
                palette: plant.genome.palette,
                presence: GrowthModel(genome: plant.genome).state(birth: plant.birth, now: model.now).heightScale
            )
            .ignoresSafeArea()

            PlantSceneView(genome: plant.genome,
                           growth: GrowthModel(genome: plant.genome).state(birth: plant.birth, now: model.now))
                .ignoresSafeArea()

            StageVeil(cut: .reading)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            content
        }
        .onAppear {
            choice = plant.choice
            model.heard(plant)
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 22) {
                    Text(plant.genome.name.full)
                        .plantName()
                        .foregroundStyle(Chrome.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 6)

                    if plant.releasedHere {
                        headline("You let this plant go into the Wild Fields. \(peer) keeps theirs.")
                    } else {
                        headline("\(peer) has let the plant you grew together go into the Wild Fields. Yours stays here.")
                    }

                    VStack(spacing: 16) {
                        fact("Anyone walking the field can come across it.")
                        fact("Beside it stands only what each of you chooses. Left as it is, you stay anonymous.")
                    }
                    .padding(.horizontal, 40)
                    .frame(maxWidth: Chrome.readableWidth)

                    VStack(spacing: 12) {
                        WildChoiceChips(choice: $choice, hasName: !name.isEmpty, hasPlace: plant.place != nil)
                        Text("Your name is yours to show. Where and when you met are shown only once you both choose them.")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Chrome.faint)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        preview
                    }
                    .frame(maxWidth: Chrome.readableWidth)

                    if let trouble {
                        Text(trouble)
                            .chromeLabel()
                            .foregroundStyle(Chrome.ochre)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 28)
            }
            .closingBar { dismiss() }

            VStack(spacing: 6) {
                QuietButton(title: "Done", isProminent: true) { done() }
                Link(destination: plant.address(on: model.plots.origin)) {
                    Text("See it in the Wild Fields")
                        .chromeLabel()
                        .foregroundStyle(Chrome.muted)
                        .pressable()
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: Chrome.readableWidth)
            .padding(.bottom, 34)
            .opacity(working ? 0.4 : 1)
            .allowsHitTesting(!working)
            .animation(Chrome.fadeIn, value: working)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// What would stand beside it once this choice is sent, in the words that
    /// would go: this person's name as it is now, the other's where the field
    /// already shows it, and the place and the month only where the other has
    /// chosen them too — this phone's own words for them, which stand only if
    /// the other phone's are the same.
    private var previewWords: [String] {
        let shown = model.showing(choice, for: plant)
        let theirChoice = notice?.theirs ?? .none
        var others = notice?.shown.names ?? []
        if notice?.yours.name == true, let mine = others.firstIndex(of: name) { others.remove(at: mine) }
        let names = (others + (shown.name.map { [$0] } ?? [])).sorted()
        let place = theirChoice.place ? shown.place : nil
        let month = theirChoice.month ? shown.month.flatMap(Self.monthWords) : nil
        return [names.isEmpty ? nil : names.joined(separator: ", "), place, month].compactMap { $0 }
    }

    @ViewBuilder
    private var preview: some View {
        let words = previewWords
        if !words.isEmpty {
            Text("Beside it: \(words.joined(separator: " · "))")
                .font(.system(size: 13, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Chrome.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        if let notice, notice.yours.place, notice.theirs.place, notice.shown.place == nil {
            // Both said yes and the two phones keep the place in different
            // words, so neither's is shown: a place one of them never wrote
            // is not one either agreed to.
            Text("Your phones remember the place in different words, so it is not shown.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Chrome.faint)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    /// `YYYY-MM` as this person reads a month.
    static func monthWords(_ month: String) -> String? {
        let parts = month.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2,
              let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: parts[0], month: parts[1]))
        else { return nil }
        return date.formatted(.dateTime.month(.wide).year())
    }

    private func headline(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 19, weight: .light, design: .serif))
            .foregroundStyle(Chrome.ink)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 40)
            .frame(maxWidth: Chrome.readableWidth)
    }

    private func fact(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 14, weight: .light))
            .foregroundStyle(Chrome.muted)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .frame(maxWidth: .infinity)
    }

    /// Sends the choice if it changed, and closes. Unchanged, nothing is sent:
    /// the service already holds exactly this.
    private func done() {
        guard !working else { return }
        guard choice != (notice?.yours ?? .none) else { return dismiss() }
        working = true
        trouble = nil
        Task {
            switch await model.beside(plant, choosing: choice) {
            case .success:
                dismiss()
            case .failure:
                // One sentence for every failure, as release has, and true of
                // each: nothing changed, and it can be asked again.
                trouble = "The Wild Fields could not be reached just now. Nothing has changed; try again in a little while."
                working = false
            }
        }
    }
}
