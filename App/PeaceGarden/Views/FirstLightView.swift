import SwiftUI

/// First launch: a seed is minted, and the person chooses the name others will
/// see when they meet.
///
/// The screen arrives a line at a time rather than all at once. The app is
/// about something unfolding slowly enough to watch, and a screen that appears
/// whole quietly says the opposite before a word of it has been read.
struct FirstLightView: View {
    @Environment(GardenModel.self) private var model
    @State private var name: String = ""
    @FocusState private var nameFocused: Bool

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

            // The name and the button wait for the description to finish. Asking
            // for something while the explanation is still arriving is what turns
            // a first screen into a form.
            Unfolding(after: Self.settled) {
                VStack(spacing: 16) {
                    Text("What people see when you meet")
                        .chromeLabel()
                        .foregroundStyle(Chrome.faint)

                    TextField("", text: $name, prompt: Text("Gardener").foregroundStyle(Chrome.faint))
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(Chrome.ink)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .onSubmit(plant)
                        .padding(.horizontal, 40)

                    SproutingRule()
                        .padding(.horizontal, 60)
                }
                .frame(maxWidth: Chrome.readableWidth)
            }
            .padding(.top, 78)

            Spacer()

            Unfolding(after: Self.settled + 0.7) {
                QuietButton(title: "Plant it now", isProminent: true, action: plant)
            }
            .padding(.bottom, 48)
        }
        .background(UnfurlingBackdrop(.single))
    }

    private func plant() {
        nameFocused = false
        model.mintIdentity(displayName: name)
    }
}
