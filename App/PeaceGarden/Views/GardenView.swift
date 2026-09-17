import SwiftUI

/// The garden: your own plant, and everything that has grown out of a meeting.
///
/// In this phase the garden is the one on this phone. The shared peace garden —
/// other people's plots, guest books — is the next phase; see docs/PHASES.md.
///
/// The screen itself is `PlotView`: a floating square plot in isometric that the
/// person arranges their own plants on. `GardenGridView` is the tile grid it
/// replaced, kept behind the developer switch while the plot is being judged on
/// real gardens. This view exists so that the swap is one line rather than a
/// change at every place the garden is opened from.
struct GardenView: View {
    var body: some View {
        #if DEBUG
        if Developer.shared.showsTileGrid {
            GardenGridView()
        } else {
            PlotView()
        }
        #else
        PlotView()
        #endif
    }
}
