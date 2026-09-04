import SwiftUI
import SeedCore

/// The moment a new plant is shown for the first time.
///
/// Used both by a face-to-face exchange and by a seed that arrived as a link,
/// because from here on they are the same thing: a plant that came from meeting
/// someone, waiting to be kept.
struct PlantRevealView: View {
    @Environment(GardenModel.self) private var model
    let outcome: ExchangeOutcome
    /// Already looked up by whoever passes it, because it is built out of two
    /// names — see `IncomingSeedView`.
    var subtitle: String?
    let onKeep: () -> Void

    /// The third and last thing the app explains itself with. Someone holding
    /// no crossed plants has never seen this happen, so this is the moment it
    /// is worth saying what just happened; after that the screen is the quieter
    /// one, because by then they know.
    private var isFirstMeeting: Bool { model.hybrids.isEmpty }

    var body: some View {
        let genome = outcome.result.genome
        // Shown as it will be in bloom. A plant born a second ago is a speck,
        // and the point of this moment is to see what the two of you made.
        let preview = PlantSceneBuilder.bloomPreview(for: genome)

        VStack(spacing: 0) {
            PlantSceneView(genome: genome, growth: preview, autoRotates: true)
                .background(StageBackdrop(palette: genome.palette))
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 10) {
                // Only the explanation retires. Someone meeting their fifth
                // person knows what a crossing is and does not need telling
                // again; the plant they just made still wants naming.
                if isFirstMeeting {
                    Text("Your plants have created a brand new seed.")
                        .chromeHeading(size: 16)
                        .foregroundStyle(Chrome.ink)
                        .padding(.bottom, 4)
                } else {
                    Text(genome.name.full)
                        .plantName(size: 24)
                        .foregroundStyle(Chrome.ink)
                    Group {
                        if let subtitle {
                            Text(verbatim: subtitle)
                        } else {
                            Text("Your plant and \(outcome.peerPlantName), together")
                        }
                    }
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Chrome.muted)
                        .padding(.bottom, 4)
                }

                // The theme is the pair's and holds; the line inside it is this
                // meeting's. So two people keep the same character between them
                // and never get the same words twice.
                // The passage is drawn as it stands, from whichever bank this
                // phone reads. A bank is written in its own language rather
                // than translated from the English one — see `QuoteBank` for
                // what two people on different banks still hold in common, and
                // docs/LANGUAGES.md for why it had to be that way.
                let passage = Quotes.passage(for: outcome.result)
                Text(verbatim: passage.text)
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(Chrome.ink.opacity(0.84))
                    .lineSpacing(6)
                Group {
                    if QuoteBank.isBorrowed {
                        // This screen is the one moment the app speaks at
                        // length, so it is where a borrowed language is most
                        // conspicuous. Saying which one it is in is what makes
                        // showing it defensible rather than careless.
                        Text("\(passage.source) · in English")
                    } else {
                        Text(verbatim: passage.source)
                    }
                }
                .chromeLabel()
                // **The label voice follows the words, not the interface.**
                //
                // `chromeLabel` uppercases and tracks according to the
                // environment's locale, which is the *app's* resolved language —
                // and a bank exists for languages the interface does not. A
                // Japanese phone gets English chrome and a Japanese bank, so the
                // environment says `en`, and this line was letter-spacing a Han
                // source: 建 築 rather than 建築. On Arabic it would have severed
                // the joins, which is the thing `Chrome.neverTracked` was added
                // to prevent.
                //
                // Handing it the bank's own locale makes both rules read the
                // language they are actually about — the same correction the web
                // makes by setting `dir` on the passage rather than on the page.
                // Where the bank is borrowed the source really is English, and
                // `QuoteBank.current` is `.english`, so this says `en` and is
                // right for the same reason.
                .environment(\.locale, Locale(identifier: QuoteBank.current.rawValue))
                .foregroundStyle(Chrome.faint)
                .padding(.bottom, 6)

                Text("It will open like this in \(Int(genome.tempo.daysToBloom.rounded())) days")
                    .chromeLabel()
                    .foregroundStyle(Chrome.faint)
                    .padding(.top, 2)

                QuietButton(
                    title: isFirstMeeting ? "Plant in peace garden" : "Keep this plant",
                    isProminent: true,
                    action: onKeep
                )
                .padding(.top, 10)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
            .frame(maxWidth: Chrome.readableWidth)
            .frame(maxWidth: .infinity)
        }
    }

}
