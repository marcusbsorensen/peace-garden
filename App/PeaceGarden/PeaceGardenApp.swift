import SwiftUI

@main
struct PeaceGardenApp: App {
    @State private var model = GardenModel()
    @State private var place = PlaceKeeping()
    /// Which way up the app is drawn. See `StageAppearance`.
    ///
    /// **Here rather than in `RootView`, and nowhere else.** It was `.dark` on
    /// this view and `Dark` again in `UIUserInterfaceStyle`, and between them
    /// they made the choice unreachable: the plist forces the style below
    /// anything SwiftUI can say, and this modifier would have won over a root
    /// that disagreed with it. The plist is `Automatic` now and this is the one
    /// place that decides.
    @AppStorage(Chrome.appearanceKey) private var appearanceRaw = StageAppearance.dark.rawValue
    private var appearance: StageAppearance {
        StageAppearance(rawValue: appearanceRaw) ?? .dark
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(place)
                .preferredColorScheme(appearance.colorScheme)
                .statusBarHidden()
                // A seed can arrive from anywhere: a scanned code, a message,
                // an AirDrop, or an App Clip handing over to the full app.
                .onOpenURL { url in
                    model.receive(url: url)
                }
        }
    }
}
