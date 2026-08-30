import Foundation
#if canImport(simd)
import simd
#endif

/// Accumulates geometry, one material role at a time.
///
/// Every surface in the plant — the stem tube, a leaf blade, a petal, the
/// flower's centre — is a parametric grid, so they all go through
/// `addSurface`. Normals are derived from neighbouring grid points rather than
/// worked out analytically per surface: one place to get right instead of five,
/// and it stays correct when a surface's maths changes.
public struct MeshBuilder {
    private var parts: [MeshRole: PlantMesh.Part] = [:]
    private var minBounds = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
    private var maxBounds = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)

    public init() {}

    /// Adds a `rows` x `columns` grid of vertices.
    ///
    /// - Parameters:
    ///   - point: evaluated at `(u, v)`, both in `0...1`. `u` runs across the
    ///     columns, `v` along the rows.
    ///   - flipWinding: reverses triangle order for surfaces built inside-out.
    public mutating func addSurface(
        role: MeshRole,
        rows: Int,
        columns: Int,
        flipWinding: Bool = false,
        point: (Float, Float) -> SIMD3<Float>
    ) {
        guard rows >= 2, columns >= 2 else { return }

        var grid = [SIMD3<Float>]()
        grid.reserveCapacity(rows * columns)
        for row in 0..<rows {
            let v = Float(row) / Float(rows - 1)
            for column in 0..<columns {
                let u = Float(column) / Float(columns - 1)
                grid.append(point(u, v))
            }
        }

        var positions = [SIMD3<Float>]()
        var normals = [SIMD3<Float>]()
        var uvs = [SIMD2<Float>]()
        positions.reserveCapacity(grid.count)
        normals.reserveCapacity(grid.count)
        uvs.reserveCapacity(grid.count)

        func vertex(_ row: Int, _ column: Int) -> SIMD3<Float> {
            grid[row * columns + column]
        }

        for row in 0..<rows {
            for column in 0..<columns {
                let position = vertex(row, column)
                let acrossA = vertex(row, min(columns - 1, column + 1))
                let acrossB = vertex(row, max(0, column - 1))
                let alongA = vertex(min(rows - 1, row + 1), column)
                let alongB = vertex(max(0, row - 1), column)
                let across = acrossA - acrossB
                let along = alongA - alongB
                var normal = cross(along, across)
                let lengthSquared = simd_length_squared(normal)
                // Poles and pinched tips collapse to zero area; borrow the
                // neighbouring row's normal rather than emitting NaN.
                if lengthSquared < 1e-12 {
                    let fallbackRow = row == 0 ? min(rows - 1, 1) : max(0, row - 1)
                    let a = vertex(fallbackRow, min(columns - 1, column + 1)) - vertex(fallbackRow, max(0, column - 1))
                    let b = vertex(min(rows - 1, fallbackRow + 1), column) - vertex(max(0, fallbackRow - 1), column)
                    normal = cross(b, a)
                    if simd_length_squared(normal) < 1e-12 {
                        normal = SIMD3<Float>(0, 1, 0)
                    }
                }
                positions.append(position)
                normals.append(simd_normalize(normal))
                uvs.append(SIMD2<Float>(Float(column) / Float(columns - 1), Float(row) / Float(rows - 1)))
            }
        }

        var indices = [UInt32]()
        indices.reserveCapacity((rows - 1) * (columns - 1) * 6)
        for row in 0..<(rows - 1) {
            for column in 0..<(columns - 1) {
                let topLeft = UInt32(row * columns + column)
                let topRight = topLeft + 1
                let bottomLeft = UInt32((row + 1) * columns + column)
                let bottomRight = bottomLeft + 1
                if flipWinding {
                    indices.append(contentsOf: [topLeft, topRight, bottomLeft])
                    indices.append(contentsOf: [topRight, bottomRight, bottomLeft])
                } else {
                    indices.append(contentsOf: [topLeft, bottomLeft, topRight])
                    indices.append(contentsOf: [topRight, bottomLeft, bottomRight])
                }
            }
        }

        append(role: role, positions: positions, normals: normals, uvs: uvs, indices: indices)
    }

    /// A tapered tube swept along a path. Used for stems, stalks and filaments.
    public mutating func addTube(
        role: MeshRole,
        path: [PathSample],
        sides: Int
    ) {
        guard path.count >= 2, sides >= 3 else { return }
        let columns = sides + 1  // last column repeats the first, for clean UVs
        addSurface(role: role, rows: path.count, columns: columns) { u, v in
            let position = v * Float(path.count - 1)
            let index = min(path.count - 1, Int(position.rounded()))
            let sample = path[index]
            let angle = u * 2 * .pi
            let offset = sample.normal * cos(angle) + sample.binormal * sin(angle)
            return sample.position + offset * sample.radius
        }
    }

    /// A hemisphere-ish dome, flattened by `flatten` (1 = full hemisphere).
    public mutating func addDome(
        role: MeshRole,
        centre: SIMD3<Float>,
        axis: SIMD3<Float>,
        side: SIMD3<Float>,
        radius: Float,
        flatten: Float = 0.65,
        rows: Int = 10,
        columns: Int = 16
    ) {
        guard radius > 0 else { return }
        let up = simd_normalize(axis)
        let right = simd_normalize(side - up * dot(side, up))
        let forward = cross(up, right)
        addSurface(role: role, rows: rows, columns: columns + 1) { u, v in
            let polar = v * (.pi / 2)
            let azimuth = u * 2 * .pi
            let ring = sin(polar) * radius
            let rise = cos(polar) * radius * flatten
            return centre
                + right * (ring * cos(azimuth))
                + forward * (ring * sin(azimuth))
                + up * rise
        }
    }

    public mutating func append(
        role: MeshRole,
        positions: [SIMD3<Float>],
        normals: [SIMD3<Float>],
        uvs: [SIMD2<Float>],
        indices: [UInt32]
    ) {
        guard !positions.isEmpty, !indices.isEmpty else { return }
        var part = parts[role] ?? PlantMesh.Part(role: role, positions: [], normals: [], uvs: [], indices: [])
        let offset = UInt32(part.positions.count)
        part.positions.append(contentsOf: positions)
        part.normals.append(contentsOf: normals)
        part.uvs.append(contentsOf: uvs)
        part.indices.append(contentsOf: indices.map { $0 + offset })
        parts[role] = part

        for position in positions {
            minBounds = simd_min(minBounds, position)
            maxBounds = simd_max(maxBounds, position)
        }
    }

    public func build() -> PlantMesh {
        let ordered = MeshRole.allCases.compactMap { parts[$0] }
        let hasGeometry = !ordered.isEmpty
        return PlantMesh(
            parts: ordered,
            minBounds: hasGeometry ? minBounds : .zero,
            maxBounds: hasGeometry ? maxBounds : .zero
        )
    }
}
