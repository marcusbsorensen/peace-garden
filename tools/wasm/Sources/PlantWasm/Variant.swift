#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// Which way round a plot is laid, for the page, from SeedCore's own
// `PlotVariant` and the space the area declares — so the page keeps no copy of
// any area's space.
//
//   pg_plot_variant(text, length, plot)
//       the variant of plot `plot` of the area named by `text` (`travel`,
//       `renewal`: `Area`'s raw value), packed as turn + 4 × mirror + 8 ×
//       nudge, or −1 for a name that is no area. `variantFromModule` in
//       `variant.js` unpacks it.

@_expose(wasm, "pg_plot_variant")
@_cdecl("pg_plot_variant")
public func pgPlotVariant(_ text: UnsafePointer<UInt8>, _ length: Int32, _ plot: Int32) -> Int32 {
    let name = String(decoding: UnsafeBufferPointer(start: text, count: Int(length)), as: UTF8.self)
    guard let area = Area(rawValue: name) else { return -1 }
    let v = PlotVariant.of(plot: Int(plot), area: area)
    return Int32(v.turn + (v.mirror ? 4 : 0) + 8 * v.nudge)
}
