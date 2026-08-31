import SwiftUI

@main
struct PeaceGardenApp: App {
    @State private var model = GardenModel()
    @State private var place = PlaceKeeping()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(place)
                .preferredColorScheme(.dark)
                .statusBarHidden()
                // A seed can arrive from anywhere: a scanned code, a message,
                // an AirDrop, or an App Clip handing over to the full app.
                .onOpenURL { url in
                    model.receive(url: url)
                }
        }
    }
}
