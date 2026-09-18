import CoreGraphics
import simd
import SwiftUI
import UIKit

/// The plot drawn as a piece of ground: a mesh of quads standing at the world's
/// own heights, lit where it is drawn, with the cut hanging under the two near
/// edges.
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
        light: GardenGround.Light = .noon
    ) -> UIImage? {
        let worlds = GardenWorlds.shared
        guard worlds.isLoaded, size.width > 1, size.height > 1 else { return nil }

        // The light is part of what a drawing is, so it is part of the key. Six
        // minutes of clock is finer than the eye can tell on a hillside and
        // coarse enough that a garden looked at for a while is drawn once.
        let key = "\(world)-\(Int(size.width))x\(Int(size.height))"
            + "-\(Int(plotSide * 100))-\(Int(view.pointsPerMetre * 10))-\(detail)"
            + "-\(Int(light.strength * 1000))-\(Int(light.direction.x * 100))"
            + "-\(Int(light.direction.z * 100))"
        if let held = cache[key] { return held }

        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            Self.draw(world: world, plotSide: plotSide, view: view, detail: max(4, detail),
                      light: light, into: context.cgContext)
        }

        // A handful is enough: one for the plot and eight small ones for the row
        // of worlds to choose from.
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
        into context: CGContext
    ) {
        let worlds = GardenWorlds.shared
        let half = plotSide / 2
        let step = plotSide / Double(mesh)

        var grid = [SIMD3<Double>]()
        grid.reserveCapacity((mesh + 1) * (mesh + 1))
        for j in 0...mesh {
            let z = -half + Double(j) * step
            for i in 0...mesh {
                let x = -half + Double(i) * step
                grid.append(SIMD3(x, worlds.height(world: world, x: x, z: z, plotSide: plotSide), z))
            }
        }
        func corner(_ i: Int, _ j: Int) -> SIMD3<Double> { grid[j * (mesh + 1) + i] }

        context.setShouldAntialias(false)
        context.setLineJoin(.miter)

        // The cut first: it hangs behind the surface, and the surface is what
        // closes the top of it.
        for (path, colour) in cutFaces(world: world, plotSide: plotSide, view: view,
                                       detail: mesh, light: light) {
            fill(path, colour, in: context)
        }

        // Far to near along the anti-diagonals, which is `x + z` ascending and
        // the same order the plants are drawn in.
        for diagonal in 0...(2 * (mesh - 1)) {
            for i in max(0, diagonal - (mesh - 1))...min(mesh - 1, diagonal) {
                let j = diagonal - i
                let p00 = corner(i, j), p10 = corner(i + 1, j)
                let p01 = corner(i, j + 1), p11 = corner(i + 1, j + 1)

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
        let half = plotSide / 2

        var x = place.x, z = place.z, y = place.y + max(0.012, step)
        for _ in 0..<46 {
            x += travel.x; z += travel.y; y += climb
            if abs(x) > half || abs(z) > half { return false }
            if worlds.height(world: world, x: x, z: z, plotSide: plotSide) > y { return true }
        }
        return false
    }

    /// The two faces of the cut that face the viewer, each following the terrain
    /// along its own rim.
    private static func cutFaces(
        world: Int,
        plotSide: Double,
        view: Isometric,
        detail mesh: Int,
        light: GardenGround.Light
    ) -> [(Path, SIMD3<Double>)] {
        let worlds = GardenWorlds.shared
        let half = plotSide / 2

        let faces: [(normal: SIMD3<Double>, along: (Double) -> (x: Double, z: Double))] = [
            (SIMD3(0, 0, 1), { t in (x: -half + t * plotSide, z: half) }),
            (SIMD3(1, 0, 0), { t in (x: half, z: half - t * plotSide) })
        ]

        return faces.map { face in
            var path = Path()
            for step in 0...mesh {
                let at = face.along(Double(step) / Double(mesh))
                let y = worlds.height(world: world, x: at.x, z: at.z, plotSide: plotSide)
                let point = view.point(x: at.x, y: y, z: at.z)
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            for step in stride(from: mesh, through: 0, by: -1) {
                let at = face.along(Double(step) / Double(mesh))
                let depth = GardenGround.cutDepth(x: at.x, z: at.z, plotSide: plotSide)
                path.addLine(to: view.point(x: at.x, y: -depth, z: at.z))
            }
            path.closeSubpath()

            return (path, GardenGround.shaded(
                base: GardenGround.soil, normal: face.normal, shadow: 0.55, light: light
            ))
        }
    }
}
