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

            if let identity = model.identity {
                if model.isArriving {
                    // The seed coming up out of its husk. It runs once, on the
                    // day the seed is sown, and then this branch is dead for
                    // the life of the app on this phone.
                    GerminationView(identity: identity) { model.arrivalWatched() }
                        .transition(.opacity)
                } else {
                    PlantStageView()
                        .transition(.opacity)
                }
            } else {
                FirstLightView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.9), value: model.hasIdentity)
        // Slower than the crossfade into the app, because what is on both sides
        // of it is the same plant at the same size: a quick cut would read as a
        // jump rather than as the performance ending.
        .animation(.easeInOut(duration: 1.3), value: model.isArriving)
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
            Text("A seed is waiting for you. Create your own first.")
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
