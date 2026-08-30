import SwiftUI
import SeedCore

struct RootView: View {
    @Environment(GardenModel.self) private var model

    /// Only a fully grown arrival takes over the screen. A seed that turned up
    /// before this person had one of their own waits quietly instead.
    private var incomingBinding: Binding<Bool> {
        Binding(
            get: { if case .arrived = model.incoming { return true }; return false },
            set: { presenting in if !presenting { model.clearIncoming() } }
        )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if model.hasIdentity {
                PlantStageView()
                    .transition(.opacity)
            } else {
                FirstLightView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.9), value: model.hasIdentity)
        .fullScreenCover(isPresented: incomingBinding) {
            if case let .arrived(outcome, reply) = model.incoming {
                IncomingSeedView(outcome: outcome, reply: reply)
                    .environment(model)
            }
        }
        .overlay(alignment: .bottom) {
            incomingNotice
        }
        .overlay(alignment: .top) {
            if let loadError = model.loadError {
                Text(loadError)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Chrome.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
            }
        }
    }

    @ViewBuilder
    private var incomingNotice: some View {
        switch model.incoming {
        case .waitingForIdentity:
            Text("A seed is waiting for you. Draw your own first.")
                .chromeLabel()
                .foregroundStyle(Chrome.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
        case .failed(let message):
            Text(message)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Chrome.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                .onTapGesture { model.clearIncoming() }
        case .none, .arrived:
            EmptyView()
        }
    }
}
