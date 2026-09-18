import CoreGraphics
import SeedCore
import simd
import SwiftUI
import UIKit

/// The plot drawn as a piece of ground: a mesh of quads standing at the world's
/// own heights, lit where it is drawn, cut to the plot's wandering outline, with
/// the cut hanging under the stretch of rim that faces the viewer.
///
/// **Drawn once, kept, and drawn somewhere other than the main actor.** Sixteen
/// thousand quads is about half a second, which as a step inside `body` is half
/// a second of frozen phone every time the garden is opened. An actor holds the
/// drawing and the cache, the screen appears immediately, and the ground arrives
/// a beat later.
///
/// The light does not move yet. When the sun and moon go round, this renders at
/// the eight points round the clock the plants are already rendered at, and the
/// same cache holds them.
actor GardenTerrain {
    static let shared = GardenTerrain()

    /// Quads a side, and **it matches the atlas on purpose**.
    ///
    /// A world's colour is stippled — the ravine's strata, the scree — so at a
    /// coarser mesh a quad covers several cells and has to average them, which
    /// keeps the colour right and throws the grain away. One quad per cell keeps
    /// the grain, and the grain is most of what makes a wall of rock read as
    /// rock. The row of little worlds is drawn coarse and averaged, because a
    /// mark sixty points wide has no grain to show.
    static let mesh = GardenWorlds.cells

    private var cache: [String: UIImage] = [:]

    func image(
        world: Int,
        plotSide: Double,
        view: Isometric,
        size: CGSize,
        detail: Int = mesh,
        light: GardenGround.Light = .noon,
        region: CGRect? = nil,
        sharpness: CGFloat = 1
    ) -> UIImage? {
        let worlds = GardenWorlds.shared
        guard worlds.isLoaded, size.width > 1, size.height > 1 else { return nil }

        // The light is part of what a drawing is, so it is part of the key. Six
        // minutes of clock is finer than the eye can tell on a hillside and
        // coarse enough that a garden looked at for a while is drawn once.
        let key = "\(world)-\(Int(size.width))x\(Int(size.height))"
            + "-\(Int(plotSide * 100))-\(Int(view.pointsPerMetre * 10))-\(detail)"
            + "-\(Int(light.strength * 1000))-\(Int(light.direction.x * 100))"
            + "-\(Int(light.direction.z * 100))-t\(((view.turn % 4) + 4) % 4)"
            + (region.map { "-r\(Int($0.minX)),\(Int($0.minY)),\(Int($0.width)),\(Int($0.height))" } ?? "")
            + "-s\(Int(sharpness * 10))"
        if let held = cache[key] { return held }

        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false
        format.scale *= sharpness
        let canvas = region?.size ?? size
        let image = UIGraphicsImageRenderer(size: canvas, format: format).image { context in
            if let region { context.cgContext.translateBy(x: -region.minX, y: -region.minY) }
            Self.draw(world: world, plotSide: plotSide, view: view, detail: max(4, detail),
                      light: light, region: region, into: context.cgContext)
        }

        // A handful is enough: one for the plot and eight small ones for the row
        // of worlds to choose from.
        // A close drawing is the screen's worth of pixels at up to three times
        // the resolution, and the view holds the one it is showing; kept here
        // as well, two dozen of them would be hundreds of megabytes.
        guard region == nil else { return image }
        if cache.count > 24 { cache.removeAll() }
        cache[key] = image
        return image
    }

    /// Thrown away when the plot's size changes, which is the only thing that
    /// invalidates a drawing while the light is held still.
    func forget() { cache.removeAll() }

    // MARK: The drawing

    private static func draw(
        world: Int,
        plotSide: Double,
        view: Isometric,
        detail mesh: Int,
        light: GardenGround.Light,
        region: CGRect? = nil,
        into context: CGContext
    ) {
        let worlds = GardenWorlds.shared
        let half = plotSide / 2
        let step = plotSide / Double(mesh)
        // A quad well outside the region is skipped before its shadow is
        // marched, which is most of what a quad costs.
        let reach = region?.insetBy(dx: -4 * step * view.pointsPerMetre,
                                    dy: -4 * step * view.pointsPerMetre)

        // The grid is laid over the square and its outer part drawn in to the
        // plot's outline, so the grid's own last row is the wandering rim.
        let outline = PlotOutline.of(plotSide: plotSide)
        var grid = [SIMD3<Double>]()
        grid.reserveCapacity((mesh + 1) * (mesh + 1))
        for j in 0...mesh {
            let z = -half + Double(j) * step
            for i in 0...mesh {
                let x = -half + Double(i) * step
                let at = outline.warp(x: x, z: z)
                grid.append(SIMD3(at.x, worlds.height(world: world, x: at.x, z: at.z, plotSide: plotSide), at.z))
            }
        }
        func corner(_ i: Int, _ j: Int) -> SIMD3<Double> { grid[j * (mesh + 1) + i] }

        // Off at the fitted size, where an edge is a pixel and antialiasing it
        // is what opens the seams. On for a close drawing, where the skyline
        // otherwise came out as a staircase; the stroke in `fill` still closes
        // the seams.
        context.setShouldAntialias(region != nil)
        context.setLineJoin(.miter)

        // The cut first: it hangs behind the surface, and the surface is what
        // closes the top of it.
        drawCut(rim: rim(of: grid, detail: mesh), plotSide: plotSide, view: view,
                light: light, into: context)

        // Far to near along the anti-diagonals **of the view**, not of the plot.
        // Near is a fact about the screen: once the plot has been turned, the
        // cell that was at the back is at the front, and painting in the plot's
        // own order would lay the far hillside over the near one. `(u, v)` walk
        // the view's grid; `cell` says which of the plot's cells stands there.
        let last = mesh - 1
        let quarter = ((view.turn % 4) + 4) % 4
        func cell(_ u: Int, _ v: Int) -> (i: Int, j: Int) {
            switch quarter {
            case 1: return (last - v, u)
            case 2: return (last - u, last - v)
            case 3: return (v, last - u)
            default: return (u, v)
            }
        }

        for diagonal in 0...(2 * last) {
            for u in max(0, diagonal - last)...min(last, diagonal) {
                let (i, j) = cell(u, diagonal - u)
                let p00 = corner(i, j), p10 = corner(i + 1, j)
                let p01 = corner(i, j + 1), p11 = corner(i + 1, j + 1)
                if let reach, !reach.contains(view.point(x: p00.x, y: p00.y, z: p00.z)) { continue }

                // **From the quad's own diagonals, not from anything it sits on.**
                // The sphere took the sphere's normal for every face and the
                // terrain got no slope shading at all — a mountain range drawn as
                // a painted ball. True face normals were the whole difference
                // between the first alpine world and the second.
                var normal = simd_cross(p11 - p00, p01 - p10)
                if normal.y < 0 { normal = -normal }
                normal = simd_normalize(normal)

                // **The middle of a quad is not the average of two corners.** It
                // was, and where the ground is steep that point sits off the
                // surface, so the march for shade started underground and the
                // quad shadowed itself. On flat ground the two agree, which is
                // why the meadow looked perfectly correct.
                let middleX = (p00.x + p11.x) / 2, middleZ = (p00.z + p11.z) / 2
                let middle = SIMD3(
                    middleX,
                    worlds.height(world: world, x: middleX, z: middleZ, plotSide: plotSide),
                    middleZ
                )

                let base = worlds.colour(world: world, x: middleX, z: middleZ,
                                         plotSide: plotSide, covering: step)
                // A face already turned away from the light is dark because of
                // where it points, and asking whether anything stands between it
                // and a light it cannot see is both wasted and a way to get acne.
                let facing = simd_dot(normal, light.direction) > 0
                let shadow: Double = facing && shadowed(world: world, at: middle,
                                                        plotSide: plotSide, light: light) ? 0 : 1
                let lit = GardenGround.shaded(base: base, normal: normal,
                                              shadow: shadow, light: light)

                var path = Path()
                path.move(to: view.point(x: p00.x, y: p00.y, z: p00.z))
                path.addLine(to: view.point(x: p10.x, y: p10.y, z: p10.z))
                path.addLine(to: view.point(x: p11.x, y: p11.y, z: p11.z))
                path.addLine(to: view.point(x: p01.x, y: p01.y, z: p01.z))
                path.closeSubpath()
                fill(path, lit, in: context)
            }
        }
    }

    /// Filled **and** stroked in the same colour.
    ///
    /// Two quads sharing an edge do not share a pixel: fills alone leave a mesh
    /// of hairlines the width of the ground, which reads as a wire frame rather
    /// than as a hill. The stroke closes them for the price of one more path.
    private static func fill(_ path: Path, _ colour: SIMD3<Double>, in context: CGContext) {
        let cg = CGColor(red: colour.x, green: colour.y, blue: colour.z, alpha: 1)
        context.setFillColor(cg)
        context.setStrokeColor(cg)
        context.setLineWidth(0.7)
        context.addPath(path.cgPath)
        context.drawPath(using: .fillStroke)
    }

    /// Whether the light reaches a place, by marching toward it over the ground.
    ///
    /// The bias is what keeps a slope from shadowing itself at every step, and
    /// the step count is what keeps a ravine wall from casting to the horizon.
    private static func shadowed(
        world: Int,
        at place: SIMD3<Double>,
        plotSide: Double,
        light: GardenGround.Light
    ) -> Bool {
        let worlds = GardenWorlds.shared
        let along = SIMD2(light.direction.x, light.direction.z)
        let rise = light.direction.y
        guard rise > 0.001, simd_length(along) > 0.001 else { return false }

        let step = plotSide / Double(GardenWorlds.cells)
        let travel = simd_normalize(along) * step
        let climb = rise / simd_length(along) * step
        let outline = PlotOutline.of(plotSide: plotSide)

        var x = place.x, z = place.z, y = place.y + max(0.012, step)
        for _ in 0..<46 {
            x += travel.x; z += travel.y; y += climb
            if !outline.reaches(x: x, z: z) { return false }
            if worlds.height(world: world, x: x, z: z, plotSide: plotSide) > y { return true }
        }
        return false
    }

    /// One place on the rim: where the ground's edge is, and where on the
    /// square it was drawn in from, which is what the cut's depth is read at.
    private struct RimPoint {
        let at: SIMD3<Double>
        let square: (x: Double, z: Double)
    }

    /// The grid's outer row, all the way round, anticlockwise from above: the
    /// `+x` edge from `z-` to `z+` first, the way `Organic.outline` runs.
    private static func rim(of grid: [SIMD3<Double>], detail mesh: Int) -> [RimPoint] {
        let row = mesh + 1
        var walk: [(i: Int, j: Int)] = []
        for j in 0..<mesh { walk.append((mesh, j)) }
        for i in stride(from: mesh, to: 0, by: -1) { walk.append((i, mesh)) }
        for j in stride(from: mesh, to: 0, by: -1) { walk.append((0, j)) }
        for i in 0..<mesh { walk.append((i, 0)) }
        return walk.map { cell in
            let fi = Double(cell.i) / Double(mesh) * 2 - 1
            let fj = Double(cell.j) / Double(mesh) * 2 - 1
            return RimPoint(at: grid[cell.j * row + cell.i], square: (x: fi, z: fj))
        }
    }

    /// The cut: the bank of earth under the stretch of the rim that faces the
    /// viewer, drawn as chunks rather than as flat faces.
    ///
    /// **It hangs from the ground's own last row**, so its top is the same
    /// wandering line the surface ends on, and the surface drawn after it closes
    /// it without a gap. Only the part facing the viewer is drawn: depth runs on
    /// `x + z`, so the far part is behind the plot's own surface. Nor is the
    /// bulge under the middle ever seen — looking down at thirty-five degrees,
    /// the plot's own surface hides everything below it — so **the rim is the
    /// whole of what the cut has to say**, and it is worth spending cells on.
    ///
    /// Each column runs down from the dark humus at the top through the earth to
    /// rock at the bottom, in cells that vary so no two are the same colour. The
    /// floor is jagged by a few centimetres for the same reason — ground that
    /// ends in a ruled line is a tile again.
    private static func drawCut(
        rim: [RimPoint],
        plotSide: Double,
        view: Isometric,
        light: GardenGround.Light,
        into context: CGContext
    ) {
        let half = plotSide / 2
        let count = rim.count
        guard count > 8 else { return }

        // **Chunks have to be chunky.** Drawn a column per quad of the terrain,
        // the variation came out as a comb of pinstripes three pixels wide —
        // texture so fine it reads as a moiré rather than as soil. A bank wants
        // cells you can see the edges of: three quads of the rim to a column,
        // about forty-four to a side, as before the rim wandered.
        let columns = min(count, max(4, Int((Double(count) / 3).rounded(.down))))
        let bands = 11
        func start(_ column: Int) -> Int { column * count / columns }

        // How far under the rim the ground goes: read on the square, where the
        // rim is always the rim, and roughened at each column's edge.
        func floor(_ v: Int, in column: Int) -> Double {
            let point = rim[v % count]
            let depth = GardenGround.cutDepth(x: point.square.x * half, z: point.square.z * half,
                                              plotSide: plotSide)
            let from = start(column), to = start(column + 1)
            let into = to > from ? Double(v - from) / Double(to - from) : 0
            let a = GardenGround.grain(column, -1) - 0.5
            let b = GardenGround.grain((column + 1) % columns, -1) - 0.5
            return -depth * (1 + (a + (b - a) * into) * 0.20)
        }

        struct Column { let index: Int; let normal: SIMD3<Double>; let sideways: SIMD3<Double>; let depth: Double }
        var seen: [Column] = []
        for column in 0..<columns {
            let first = rim[start(column)].at
            let last = rim[start(column + 1) % count].at
            let along = SIMD3(last.x - first.x, 0, last.z - first.z)
            guard simd_length(along) > 1e-9 else { continue }
            let sideways = simd_normalize(along)
            // Outward is the direction of travel turned a quarter clockwise.
            let normal = SIMD3(sideways.z, 0, -sideways.x)
            let (a, b) = view.facing(x: normal.x, z: normal.z)
            guard a + b > 0 else { continue }
            let middle = view.depth(Spot(x: (first.x + last.x) / 2, z: (first.z + last.z) / 2))
            seen.append(Column(index: column, normal: normal, sideways: sideways, depth: middle))
        }
        seen.sort { $0.depth < $1.depth }

        for column in seen {
            let vertices = Array(start(column.index)...start(column.index + 1))
            for band in 0..<bands {
                let near = Double(band) / Double(bands)
                let far = Double(band + 1) / Double(bands)

                func corner(_ v: Int, _ down: Double) -> CGPoint {
                    let top = rim[v % count].at
                    let y = top.y + down * (floor(v, in: column.index) - top.y)
                    return view.point(x: top.x, y: y, z: top.z)
                }

                let grain = GardenGround.grain(column.index, band)
                let colour = GardenGround.cutColour(
                    down: (near + far) / 2,
                    grain: grain,
                    stones: GardenGround.grain(column.index / 2, band / 2, 16)
                )

                // Each cell sits a little differently in the bank, so the
                // light finds some of them and not others. That, rather than
                // the colour, is most of what reads as chunkiness.
                let tilt = (grain - 0.5) * 0.5
                let lean = GardenGround.grain(column.index, band, 8) - 0.5
                let normal = simd_normalize(
                    column.normal + column.sideways * tilt + SIMD3(0, lean * 0.4, 0)
                )

                var path = Path()
                path.move(to: corner(vertices[0], near))
                for v in vertices.dropFirst() { path.addLine(to: corner(v, near)) }
                for v in vertices.reversed() { path.addLine(to: corner(v, far)) }
                path.closeSubpath()

                fill(path, GardenGround.shaded(base: colour, normal: normal,
                                               shadow: 0.55, light: light),
                     in: context)
            }
        }
    }
}
