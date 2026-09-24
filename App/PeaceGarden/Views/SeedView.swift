import SwiftUI
import SeedCore

/// What this person's seed actually is, and what leaves the phone.
///
/// People are being asked to carry an identifier around and hand it to
/// strangers; they are owed a plain account of what it is.
struct SeedView: View {
    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var showingMeaning = false

    var body: some View {
        ZStack {
            Chrome.ground.ignoresSafeArea()

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
                // Presented the way this screen is, so the second sheet reads
                // as a page turned rather than a different kind of thing.
                .sheet(isPresented: $showingMeaning) {
                    NameMeaningView(genome: identity.genome)
                        .presentationDetents([.medium, .large])
                        .presentationBackground(Chrome.ground)
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
            HStack(alignment: .center, spacing: 12) {
                Text(identity.genome.name.full)
                    .plantName(size: 28)
                    .foregroundStyle(Chrome.ink)
                Spacer(minLength: 0)
                meaningButton
            }

            Text(identity.genome.form.archetype.label)
                .chromeLabel()
                .foregroundStyle(Chrome.faint)

        }
    }

    /// The way to what the name means, laid beside the name it explains.
    ///
    /// **A mark with no word**, as the four along the foot of the stage are
    /// until they are touched. Beside a name in italic serif, a word in
    /// capitals would be a second heading; VoiceOver is given the word. It stands in the same hairline ring
    /// `pressable` gives every control, sized to be round — forty-four points,
    /// which is the least a thumb should be asked to find.
    private var meaningButton: some View {
        Button { showingMeaning = true } label: {
            MeaningsGlyph()
                .stroke(Chrome.muted, style: Chrome.monoline)
                .frame(width: 22, height: 22)
                .drawnHand()
                .pressable(horizontal: 11, vertical: 11)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("What the name means",
                                 comment: "The book mark beside a plant's name on the seed screen, read aloud. It opens a page explaining what the plant's name says about it."))
    }

    @ViewBuilder
    private func traits(identity: Identity) -> some View {
        let genome = identity.genome
        VStack(alignment: .leading, spacing: 14) {
            // The seed itself and the leaf count are numbers, so they are
            // handed over as drawn rather than looked up. Everything else on
            // the right of this list is a phrase somebody wrote.
            factRow(AnyShape(SeedGlyph()), "Seed", value: Text(verbatim: identity.seed.short))
            factRow(AnyShape(ClockGlyph()), "Created",
                    value: Text(verbatim: identity.birth.formatted(date: .abbreviated, time: .shortened)))
            factRow(AnyShape(PetalGlyph()), "Petals", value: genome.bloom.present
                ? Text("\(genome.bloom.petalCount) across \(genome.bloom.layers)")
                : Text("None"))
            factRow(AnyShape(LeafGlyph()), "Leaves", value: Text(verbatim: "\(genome.leafCount)"))
            // The mark answers this row rather than repeating its label: a sun
            // for a plant that opens by day, a crescent for one that does not.
            // The only row here whose glyph carries the value.
            factRow(genome.tempo.opensByDay ? AnyShape(SunGlyph()) : AnyShape(MoonGlyph()),
                    "Opens", value: Text(genome.tempo.opensByDay ? "By day" : "By night"))
            factRow(AnyShape(BloomGlyph()), "First bloom",
                    value: Text("When \(Int(genome.tempo.daysToBloom.rounded())) days old"))
        }
    }
}

/// A mark, a label, and a value.
///
/// The marks are here because this is the one screen in the app that is a
/// list of facts, and a list of facts is read by shape before it is read by
/// word. They are also the half of each row that survives a language this app
/// has not been translated into yet.
///
/// The value arrives as a `Text` rather than a `String`, because half these
/// values are phrases to be looked up and half are numbers to be drawn as they
/// are, and the caller is the only place that knows which.
///
/// Out of `SeedView` so the name sheet can say where a plant stands in the same
/// row the seed screen says everything else in.
@MainActor
private func factRow(_ glyph: AnyShape, _ label: LocalizedStringKey, value: Text) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 10) {
        glyph
            .stroke(Chrome.faint, style: Chrome.monoline)
            .frame(width: 15, height: 15)
            // Uppercase text carries descender room it never uses, so its box
            // sits below the letters. A point up puts the mark on the cap
            // height rather than on the line.
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

/// What a plant's name says about it.
///
/// **The account the website gives**, in the block under each area page and
/// the table at `/meanings`, read off the one plant in hand rather than looked
/// up in a table. The head of the genus names a theme, which is the area of the
/// shared garden the plant belongs to; the ending names which of that theme's
/// three parts a meeting draws its passage from.
///
/// **Nothing here works that out again.** The theme is `Quotes.Theme(genusHead:)`,
/// which reads `Area.genusHeads` in SeedCore, and the part is
/// `Quotes.subtheme(of:in:)`, the same call that chooses a meeting's passage.
/// `meanings.js` is held to those tables by its own `selfTest`, so the site and
/// this sheet cannot come to file one plant in two places.
///
/// The epithet is left out. `Epithet.describing` chooses it, but nothing in
/// SeedCore maps the written word back to what it says, and the glosses on
/// `/meanings` are English data in the site's script rather than something the
/// app can read.
struct NameMeaningView: View {
    let genome: Genome
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let name = genome.name
        let theme = Quotes.Theme(genusHead: name.genusHead)
        let part = Quotes.subtheme(of: genome, in: theme)

        ZStack {
            Chrome.ground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    parsed(name)
                    entry(theme, head: name.genusHead)
                    Hairline()
                    parts(of: theme, chosen: part, tail: name.genusTail)
                }
                .padding(.horizontal, 30)
                .padding(.top, 68)
                .padding(.bottom, 34)
                .frame(maxWidth: Chrome.readableWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: "Close") { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 8)
        }
    }

    /// The name, with the two pieces that carry meaning at full strength and
    /// everything else faint.
    ///
    /// A dot after the head, as a dictionary divides a word, because without
    /// one *Nyxora* does not show where *Nyx* stops. The site's worked example
    /// on `/meanings` is set the same way. Read aloud as the name it is, not as
    /// its pieces.
    private func parsed(_ name: PlantName) -> some View {
        let head = name.genusHead, tail = name.genusTail, genus = name.genus
        var written = AttributedString()
        // A drawn name always begins with its head and ends with its ending; a
        // name written by hand may not, and then it is set whole rather than cut
        // somewhere it does not divide.
        if genus.hasPrefix(head), genus.hasSuffix(tail), head.count + tail.count <= genus.count {
            let middle = genus.dropFirst(head.count).dropLast(tail.count)
            written += piece(head, Chrome.ink)
            written += piece("·\(middle)", Chrome.faint)
            written += piece(tail, Chrome.ink)
        } else {
            written += piece(genus, Chrome.ink)
        }
        written += piece(" " + name.epithet, Chrome.faint)

        return Text(written)
            .plantName(size: 24)
            .accessibilityLabel(Text(verbatim: name.full))
    }

    private func piece(_ text: some StringProtocol, _ colour: Color) -> AttributedString {
        var run = AttributedString(String(text))
        run.foregroundColor = colour
        return run
    }

    /// The theme as a dictionary sets a word: the headword, the syllable it
    /// came from standing where an etymology would, and the definition under
    /// it. Then where in the shared garden that puts the plant.
    ///
    /// The headword is in the sans, larger, and not the serif, which this app
    /// keeps for the names of plants — *Waiting* is not what anything is
    /// called. The syllable is in the serif because it is a piece of one.
    private func entry(_ theme: Quotes.Theme, head: String) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(theme.headword)
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Chrome.ink)
                    Spacer(minLength: 0)
                    Text(verbatim: "\(head)-")
                        .plantName(size: 18)
                        .foregroundStyle(Chrome.faint)
                        .accessibilityHidden(true)
                }
                Text(theme.definition)
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(Chrome.ink.opacity(0.84))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            factRow(AnyShape(GardenGlyph()), "Area", value: Text(theme.area.label))
        }
    }

    /// The theme's three parts, in the order the endings choose them, with
    /// this plant's at full strength and its ending beside it.
    ///
    /// **Marked by weight of ink and by the ending, not by a tick.** A tick is
    /// a form being filled in, and nobody chose this; the name did. The ending
    /// set beside the part is the same piece lit in the name above, so the eye
    /// can go from one to the other without being told to.
    private func parts(of theme: Quotes.Theme, chosen: Quotes.Subtheme, tail: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(theme.subthemes, id: \.self) { part in
                let isChosen = part == chosen
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(part.label)
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(isChosen ? Chrome.ink : Chrome.faint)
                    Spacer(minLength: 0)
                    if isChosen {
                        Text(verbatim: "-\(tail)")
                            .plantName(size: 18)
                            .foregroundStyle(Chrome.muted)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(isChosen ? .isSelected : [])
            }
        }
    }
}
