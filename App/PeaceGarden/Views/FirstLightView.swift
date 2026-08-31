import SwiftUI

/// First launch: a seed is minted, and the person chooses the name others will
/// see when they meet.
///
/// The seed is drawn once and kept for good, so this screen says as much
/// plainly rather than letting someone discover it later.
struct FirstLightView: View {
    @Environment(GardenModel.self) private var model
    @State private var name: String = ""
    @State private var revealed = false
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 26) {
                BreathingDot(diameter: 10)
                    .padding(.bottom, 8)

                Text("A unique seed for you is taking form.")
                    .chromeHeading()
                    .foregroundStyle(Chrome.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                // The breaks are the cadence, and are set rather than left
                // to the wrap: the three imprints are a list, and a list
                // that reflows stops reading as one.
                Text("The imprints swirling together:\nthe coordinates of this moment,\nin this specific digital space,\nand mutations of the random.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Chrome.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(7)
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: Chrome.readableWidth)
            .opacity(revealed ? 1 : 0)

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
            .padding(.top, 78)
            .opacity(revealed ? 1 : 0)

            Spacer()

            QuietButton(title: "Plant it now", isProminent: true, action: plant)
                .padding(.bottom, 48)
                .opacity(revealed ? 1 : 0)
        }
        .animation(.easeInOut(duration: 1.4), value: revealed)
        .onAppear { revealed = true }
    }

    private func plant() {
        nameFocused = false
        model.mintIdentity(displayName: name)
    }
}
