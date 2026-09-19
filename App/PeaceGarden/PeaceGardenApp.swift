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
                // The one request this app makes on its own, and only when the
                // person has left invitations on: whether anything has happened
                // to any of the meetings in this garden. Off, it is not made,
                // and the service is never told this phone exists — see
                // `Sharing.swift`. It is quiet about failing; nobody asked for
                // it, so a phone with no signal simply learns nothing today.
                .task {
                    await model.catchUpOnTheAsking()
                }
        }
    }
}
