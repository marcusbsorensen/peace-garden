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

                Text("A seed is about to be drawn for you")
                    .font(.system(size: 19, weight: .light, design: .serif))
                    .foregroundStyle(Chrome.ink)
                    .multilineTextAlignment(.center)

                Text("It is made from this moment and this phone, and it is yours alone. It cannot be drawn again, and it never leaves the phone until you choose to meet someone.")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Chrome.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: Chrome.readableWidth)
            .opacity(revealed ? 1 : 0)

            Spacer()

            VStack(spacing: 16) {
                Text("What should people see when you meet?")
                    .chromeLabel()
                    .foregroundStyle(Chrome.faint)

                TextField("", text: $name, prompt: Text("Gardener").foregroundStyle(Chrome.faint))
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundStyle(Chrome.ink)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit(plant)
                    .padding(.horizontal, 40)

                Hairline()
                    .padding(.horizontal, 60)
            }
            .frame(maxWidth: Chrome.readableWidth)
            .opacity(revealed ? 1 : 0)

            Spacer()

            QuietButton(title: "Draw my seed", isProminent: true, action: plant)
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
