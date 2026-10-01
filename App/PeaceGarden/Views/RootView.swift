import SwiftUI
import SeedCore

struct RootView: View {

    @Environment(GardenModel.self) private var model

    /// The released plant being told about, if one is. Held here rather than
    /// read off the model, because the screen marks it heard as it opens and a
    /// sheet bound straight to *the first unheard* would change under itself.
    @State private var hearing: WildPlant?

    private func hearNext() {
        guard hearing == nil, model.hasIdentity, !model.isArriving else { return }
        if case .arrived = model.incoming { return }
        hearing = model.wildToHear.first
    }

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
            Chrome.ground.ignoresSafeArea()

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
        // **The other gardener let a plant you grew together go into the Wild
        // Fields** (1 October 2026). Heard on the poll the app already makes,
        // only while *Alert me* is on, and put in front of this person once:
        // the plant, who let it go, and what they may show beside it. One at a
        // time, the next after the last is closed — and not over a seed
        // arriving, which has the screen first.
        .sheet(item: $hearing, onDismiss: { hearNext() }) { plant in
            WildBesideView(plant: plant)
                .environment(model)
                .presentationBackground(Chrome.ground)
        }
        .onChange(of: model.wildToHear.map(\.id)) { hearNext() }
        .onAppear { hearNext() }
        .overlay(alignment: .bottom) {
            incomingNotice
        }
        .overlay(alignment: .top) {
            if let loadError = model.loadError {
                // Looked up where it is made — it ends on the system's own
                // account of what went wrong, which is already in this phone's
                // language. See `GardenModel`.
                Text(verbatim: loadError)
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
            Text(verbatim: message)
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
