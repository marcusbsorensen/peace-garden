import SwiftUI
import SeedCore

/// What this person's seed actually is, and what leaves the phone.
///
/// People are being asked to carry an identifier around and hand it to
/// strangers; they are owed a plain account of what it is.
struct SeedView: View {
    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var editingName = false
    @State private var draftName = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let identity = model.identity {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header(identity: identity)
                        Hairline()
                        traits(identity: identity)
                    }
                    .padding(.horizontal, 30)
                    // Clear of Close, which sits in its own band across the top
                    // rather than in the scroll.
                    .padding(.top, 68)
                    .padding(.bottom, 34)
                    .frame(maxWidth: Chrome.readableWidth)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: "Close") { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func header(identity: Identity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(identity.genome.name.full)
                .plantName(size: 28)
                .foregroundStyle(Chrome.ink)

            Text(identity.genome.form.archetype.label)
                .chromeLabel()
                .foregroundStyle(Chrome.faint)

            if editingName {
                // The field's own label is the one VoiceOver reads, and it was
                // an empty string — which extraction dutifully turned into an
                // empty entry in the catalogue for somebody to translate. It
                // says what the field is for instead, and stays out of the way
                // because the prompt is what is drawn.
                TextField("Your name", text: $draftName, prompt: Text("Gardener"))
                    .labelsHidden()
                    .font(.system(size: 17, weight: .light, design: .serif))
                    .foregroundStyle(Chrome.ink)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit {
                        model.rename(to: draftName)
                        editingName = false
                    }
            } else {
                Button {
                    draftName = identity.displayName
                    editingName = true
                } label: {
                    // The worst offender of the lot before it got an edge: a
                    // sentence in the middle of a paragraph that happened to be
                    // the only way to change your name.
                    Text("Seen as \(model.shownName)")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Chrome.muted)
                        .pressable()
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func traits(identity: Identity) -> some View {
        let genome = identity.genome
        VStack(alignment: .leading, spacing: 14) {
            // The seed itself and the leaf count are numbers, so they are
            // handed over as drawn rather than looked up. Everything else on
            // the right of this list is a phrase somebody wrote.
            row(AnyShape(SeedGlyph()), "Seed", value: Text(verbatim: identity.seed.short))
            row(AnyShape(ClockGlyph()), "Created",
                value: Text(verbatim: identity.birth.formatted(date: .abbreviated, time: .shortened)))
            row(AnyShape(PetalGlyph()), "Petals", value: genome.bloom.present
                ? Text("\(genome.bloom.petalCount) across \(genome.bloom.layers)")
                : Text("None"))
            row(AnyShape(LeafGlyph()), "Leaves", value: Text(verbatim: "\(genome.leafCount)"))
            // The mark answers this row rather than repeating its label: a sun
            // for a plant that opens by day, a crescent for one that does not.
            // The only row here whose glyph carries the value.
            row(genome.tempo.opensByDay ? AnyShape(SunGlyph()) : AnyShape(MoonGlyph()),
                "Opens", value: Text(genome.tempo.opensByDay ? "By day" : "By night"))
            row(AnyShape(BloomGlyph()), "First bloom",
                value: Text("When \(Int(genome.tempo.daysToBloom.rounded())) days old"))
        }
    }

    /// A mark, a label, and a value.
    ///
    /// The marks are here because this is the one screen in the app that is a
    /// list of facts, and a list of facts is read by shape before it is read by
    /// word. They are also the half of each row that survives a language this
    /// app has not been translated into yet.
    ///
    /// The value arrives as a `Text` rather than a `String`, because half these
    /// values are phrases to be looked up and half are numbers to be drawn as
    /// they are, and the caller is the only place that knows which.
    private func row(_ glyph: AnyShape, _ label: LocalizedStringKey, value: Text) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            glyph
                .stroke(Chrome.faint, style: Chrome.monoline)
                .frame(width: 15, height: 15)
                // Uppercase text carries descender room it never uses, so its
                // box sits below the letters. A point up puts the mark on the
                // cap height rather than on the line.
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1 }
            Text(label)
                .chromeLabel()
                .foregroundStyle(Chrome.faint)
            Spacer()
            value
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Chrome.ink)
        }
    }
}
