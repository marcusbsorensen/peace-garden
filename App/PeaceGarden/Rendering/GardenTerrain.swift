import CoreGraphics
import SeedCore
import simd
import SwiftUI
import UIKit

/// The plot drawn as a piece of ground: a mesh of quads standing at the world's
/// own heights, lit where it is drawn, cut to the plot's wandering outline, with
/// the slab's side hanging under the stretch of rim that faces the viewer.
///
/// **Drawn once, kept, and drawn somewhere other than the main actor.** Sixteen
/// thousand quads is about half a second, which as a step inside `body` is half
/// a second of frozen phone every time the garden is opened. An actor holds the
/// drawing and the cache, the screen appears immediately, and the ground arrives
/// a beat later.
///
/// The light moves: the ground is drawn under the hour's own sun or moon
/// (`GardenGround.Light.at(hour:)`), and the light is part of the cache's key,
/// so each hour drawn is kept beside the others.
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
        //
        // **At the atlas's own resolution the grid is also the crumb.** Every
        // corner inside the rim is moved by up to a third of a cell and lifted
        // or sunk by what its ground is, so the lattice never reads as a
        // lattice: the website's Knot Garden found that a regular grid of cells
        // draws a tiled floor however hard its tones vary, and that it was the
        // grid's regularity that had to go, not its size. The row of little
        // worlds is too coarse to carry a crumb and is drawn plain.
        let crumbed = mesh == GardenWorlds.cells
        let outline = PlotOutline.of(plotSide: plotSide)
        func atlas(_ n: Int) -> Int { min(GardenWorlds.cells - 1, n * (GardenWorlds.cells - 1) / mesh) }
        var grid = [SIMD3<Double>]()
        grid.reserveCapacity((mesh + 1) * (mesh + 1))
        for j in 0...mesh {
            for i in 0...mesh {
                var x = -half + Double(i) * step
                var z = -half + Double(j) * step
                let edge = i == 0 || j == 0 || i == mesh || j == mesh
                var lift = 0.0
                if crumbed && !edge {
                    // **Less on a steep face.** A corner moved sideways on a
                    // wall is a corner moved up or down it, and a box hedge
                    // or a bed's side came out as a row of teeth. On the flat
                    // the full third; on a wall almost none.
                    let across = (worlds.height(world: world, x: x + step, z: z, plotSide: plotSide)
                        - worlds.height(world: world, x: x - step, z: z, plotSide: plotSide)) / (2 * step)
                    let down = (worlds.height(world: world, x: x, z: z + step, plotSide: plotSide)
                        - worlds.height(world: world, x: x, z: z - step, plotSide: plotSide)) / (2 * step)
                    let steep = (across * across + down * down) / 0.25
                    // And none on the row inside the rim, where the outline
                    // has already squeezed the cells and a moved corner pokes
                    // out past the edge as a fringe.
                    let besideRim = i == 1 || j == 1 || i == mesh - 1 || j == mesh - 1
                    let shift = besideRim ? 0 : step * 0.34 / (1 + steep)
                    x += shift * (GardenGround.grain(i, j, 11) * 2 - 1)
                    z += shift * (GardenGround.grain(i, j, 12) * 2 - 1)
                    // Clods come in twos: half the lift is shared with the
                    // corners round about, so a lump is bigger than a corner.
                    let rough = worlds.kind(world: world, i: atlas(i), j: atlas(j)).crumb.rough
                    let shared = GardenGround.grain(i / 2, j / 2, 13) - 0.5
                    let own = GardenGround.grain(i, j, 14) - 0.5
                    lift = rough * (shared * 1.2 + own * 0.8)
                }
                let at = outline.warp(x: x, z: z)
                grid.append(SIMD3(at.x, worlds.height(world: world, x: at.x, z: at.z, plotSide: plotSide) + lift, at.z))
            }
        }
        func corner(_ i: Int, _ j: Int) -> SIMD3<Double> { grid[j * (mesh + 1) + i] }
        // Where each corner lands on screen, once: four quads share it.
        let screen = grid.map { view.point(x: $0.x, y: $0.y, z: $0.z) }
        func spot(_ i: Int, _ j: Int) -> CGPoint { screen[j * (mesh + 1) + i] }

        // Off at the fitted size, where an edge is a pixel and antialiasing it
        // is what opens the seams. On for a close drawing, where the skyline
        // otherwise came out as a staircase; the stroke in `fill` still closes
        // the seams.
        context.setShouldAntialias(region != nil)
        context.setLineJoin(.miter)

        // The side first: it hangs behind the surface, and the surface is what
        // closes the top of it.
        drawSide(rim: rim(of: grid, detail: mesh), view: view, light: light, within: reach, into: context)

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

        // Bevelled, not mitred: a face squeezed thin by the rim has a corner
        // sharp enough that a mitre runs out past the edge as a spike, and a row
        // of them drew the far rim as a fringe of hair.
        context.setLineWidth(0.7)
        context.setLineJoin(.bevel)
        for diagonal in 0...(2 * last) {
            for u in max(0, diagonal - last)...min(last, diagonal) {
                let (i, j) = cell(u, diagonal - u)
                let p00 = corner(i, j), p10 = corner(i + 1, j)
                let p01 = corner(i, j + 1), p11 = corner(i + 1, j + 1)
                if let reach, !reach.contains(spot(i, j)) { continue }

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

                // Two faces to a cell, split on a diagonal the cell chooses for
                // itself, each lit by its own normal and toned by its own crumb.
                let crumb = crumbed ? worlds.kind(world: world, i: atlas(i), j: atlas(j)).crumb : nil
                let drift = crumbed ? 1 + GardenGround.drift(x: middleX, z: middleZ) : 1
                let turned = crumbed && GardenGround.grain(i, j, 15) < 0.5
                func face(_ a: (Int, Int), _ b: (Int, Int), _ c: (Int, Int), salt: Int) {
                    let pa = corner(a.0, a.1), pb = corner(b.0, b.1), pc = corner(c.0, c.1)
                    var tone = drift
                    var faceNormal = normal
                    if let crumb {
                        var own = simd_cross(pb - pa, pc - pa)
                        if own.y < 0 { own = -own }
                        if simd_length(own) > 1e-12 { faceNormal = simd_normalize(own) }
                        let grain: Double
                        if crumb.perCorner {
                            // Averaging three corners narrows the spread, so it
                            // is widened back to match the per-face kinds.
                            let corners = GardenGround.grain(a.0, a.1, 18) + GardenGround.grain(b.0, b.1, 18)
                                + GardenGround.grain(c.0, c.1, 18)
                            grain = 0.5 + (corners / 3 - 0.5) * 1.7
                        } else {
                            grain = GardenGround.grain(i, j, salt)
                        }
                        tone *= 1 + crumb.spread * (grain - 0.5)
                    }
                    let lit = GardenGround.shaded(base: base * tone, normal: faceNormal,
                                                  shadow: shadow, light: light)
                    context.setFillColor(red: lit.x, green: lit.y, blue: lit.z, alpha: 1)
                    context.setStrokeColor(red: lit.x, green: lit.y, blue: lit.z, alpha: 1)
                    context.move(to: spot(a.0, a.1))
                    context.addLine(to: spot(b.0, b.1))
                    context.addLine(to: spot(c.0, c.1))
                    context.closePath()
                    context.drawPath(using: .fillStroke)
                }
                if turned {
                    face((i, j), (i + 1, j), (i + 1, j + 1), salt: 16)
                    face((i, j), (i + 1, j + 1), (i, j + 1), salt: 17)
                } else {
                    face((i, j), (i + 1, j), (i, j + 1), salt: 16)
                    face((i + 1, j), (i + 1, j + 1), (i, j + 1), salt: 17)
                }
            }
        }
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

    /// The grid's outer row, all the way round, anticlockwise from above: the
    /// `+x` edge from `z-` to `z+` first, the way `Organic.outline` runs.
    private static func rim(of grid: [SIMD3<Double>], detail mesh: Int) -> [SIMD3<Double>] {
        let row = mesh + 1
        var walk: [(i: Int, j: Int)] = []
        for j in 0..<mesh { walk.append((mesh, j)) }
        for i in stride(from: mesh, to: 0, by: -1) { walk.append((i, mesh)) }
        for j in stride(from: mesh, to: 0, by: -1) { walk.append((0, j)) }
        for i in 0..<mesh { walk.append((i, 0)) }
        return walk.map { grid[$0.j * row + $0.i] }
    }

    /// The slab's side, hung from the ground's own last row: `GardenGround.side`
    /// works out the pieces, and this fills them.
    ///
    /// **Filled and stroked in the same colour.** Two pieces sharing an edge do
    /// not share a pixel: fills alone leave a mesh of hairlines the width of the
    /// ground, which reads as a wire frame rather than as earth. The stroke
    /// closes them for the price of one more path, and it is bevelled because a
    /// piece seen edge-on at the diamond's side corners is a sliver, and a mitre
    /// on a sliver is a spike.
    private static func drawSide(
        rim: [SIMD3<Double>],
        view: Isometric,
        light: GardenGround.Light,
        within: CGRect?,
        into context: CGContext
    ) {
        context.saveGState()
        defer { context.restoreGState() }
        context.setLineWidth(0.7)
        context.setLineJoin(.bevel)
        for piece in GardenGround.side(rim: rim, view: view, light: light, within: within) {
            let colour = piece.colour
            context.setFillColor(red: colour.x, green: colour.y, blue: colour.z, alpha: 1)
            context.setStrokeColor(red: colour.x, green: colour.y, blue: colour.z, alpha: 1)
            context.addLines(between: piece.points)
            context.closePath()
            context.drawPath(using: .fillStroke)
        }
    }
}
