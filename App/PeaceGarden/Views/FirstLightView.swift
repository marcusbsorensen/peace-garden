import SwiftUI

/// First launch: a seed is minted, and nothing is asked for.
///
/// The screen arrives a line at a time rather than all at once. The app is
/// about something unfolding slowly enough to watch, and a screen that appears
/// whole quietly says the opposite before a word of it has been read.
struct FirstLightView: View {
    @Environment(GardenModel.self) private var model

    private static let imprints = [
        "The imprints swirling together:",
        "the coordinates of this moment,",
        "in this specific digital space,",
        "and mutations of the random.",
    ]

    /// When each line arrives: once the line before it has had time to be read.
    private static let beats: [Double] = {
        var running = 1.9
        return imprints.map { line in
            defer { running += readingBeat(line) }
            return running
        }
    }()

    /// The point at which the description has finished arriving.
    private static var settled: Double { (beats.last ?? 0) + readingBeat(imprints.last ?? "") + 0.8 }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 26) {
                BreathingDot(diameter: 10)
                    .padding(.bottom, 8)

                Unfolding(after: 0.5) {
                    Text("A unique seed for you is taking form.")
                        .chromeHeading()
                        .foregroundStyle(Chrome.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }

                VStack(spacing: 7) {
                    ForEach(Array(Self.imprints.enumerated()), id: \.offset) { index, line in
                        Unfolding(after: Self.beats[index]) {
                            Text(line)
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(Chrome.muted)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: Chrome.readableWidth)

            // The rule closes the description off, and waits for it to finish.
            // There is nothing to fill in here: this screen has one thing to
            // say and one thing to press, and a field in the middle of it turns
            // it into a form. The name is asked for at the first meeting, where
            // there is at last somebody for it to be for.
            Unfolding(after: Self.settled) {
                SproutingRule()
                    .padding(.horizontal, 60)
                    .frame(maxWidth: Chrome.readableWidth)
            }
            .padding(.top, 78)

            // The button belongs to the rule, not to the bottom of the screen.
            // Pinned down there it left a third of a screen of nothing in the
            // middle of a composition that is otherwise one column, and the
            // reader had to cross it to answer a sentence they had just read.
            // The whole group sits between two spacers instead, so the empty
            // space is above and below it rather than through it.
            Unfolding(after: Self.settled + 0.7) {
                QuietButton(title: "Plant it now", isProminent: true, action: plant)
            }
            .padding(.top, 34)

            Spacer()
        }
        .background(UnfurlingBackdrop(.single))
    }

    private func plant() {
        model.mintIdentity()
    }
}
