import SwiftUI

@main
struct PeaceGardenApp: App {
    @State private var model = GardenModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(.dark)
                .statusBarHidden()
        }
    }
}
