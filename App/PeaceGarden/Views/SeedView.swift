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

            Text(identity.genome.form.archetype.displayName)
                .chromeLabel()
                .foregroundStyle(Chrome.faint)

            if editingName {
                TextField("", text: $draftName)
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
            row(AnyShape(SeedGlyph()), "Seed", identity.seed.short)
            row(AnyShape(ClockGlyph()), "Created",
                identity.birth.formatted(date: .abbreviated, time: .shortened))
            row(AnyShape(PetalGlyph()), "Petals",
                genome.bloom.present ? "\(genome.bloom.petalCount) across \(genome.bloom.layers)" : "None")
            row(AnyShape(LeafGlyph()), "Leaves", "\(genome.leafCount)")
            // The mark answers this row rather than repeating its label: a sun
            // for a plant that opens by day, a crescent for one that does not.
            // The only row here whose glyph carries the value.
            row(genome.tempo.opensByDay ? AnyShape(SunGlyph()) : AnyShape(MoonGlyph()),
                "Opens", genome.tempo.opensByDay ? "By day" : "By night")
            row(AnyShape(BloomGlyph()), "First bloom",
                "When \(Int(genome.tempo.daysToBloom.rounded())) days old")
        }
    }

    /// A mark, a label, and a value.
    ///
    /// The marks are here because this is the one screen in the app that is a
    /// list of facts, and a list of facts is read by shape before it is read by
    /// word. They are also the half of each row that survives a language this
    /// app has not been translated into yet.
    private func row(_ glyph: AnyShape, _ label: String, _ value: String) -> some View {
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
            Text(value)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Chrome.ink)
        }
    }
}
