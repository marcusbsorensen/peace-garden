import SwiftUI
import SeedCore

struct RootView: View {
    @Environment(GardenModel.self) private var model

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
}
