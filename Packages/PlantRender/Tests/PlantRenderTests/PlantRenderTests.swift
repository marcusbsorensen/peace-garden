import SceneKit
import SeedCore
import SwiftUI
import UIKit
import XCTest
@_spi(PeaceGarden) import PlantRender

/// What a second app relies on: a known seed makes the node it should, the
/// scene and camera are the ones Peace Garden lights its plants with, and a
/// thumbnail comes back as a picture of something.
///
/// The numbers are Peace Garden's own plants. If one of these moves, the plant
/// has changed on screen — in the app and in every app that links this — and
/// that is a decision, not a side effect.
@MainActor
final class PlantRenderTests: XCTestCase {

    private func genome(_ tag: String) -> Genome {
        Genome(seed: SeedMint.mint(fromEntropy: Data("plantrender-\(tag)".utf8)))
    }

    // MARK: - The node

    func testANodeHasOneChildForEveryPartThatDrawsAnything() throws {
        let genome = genome("node")
        let growth = PlantSceneBuilder.bloomPreview(for: genome)
        let mesh = PlantBuilder(genome: genome).mesh(growth: growth)
        let node = PlantSceneBuilder.node(for: mesh, palette: genome.palette)

        let drawn = mesh.parts.filter { !$0.indices.isEmpty }
        XCTAssertFalse(drawn.isEmpty, "a grown plant draws something")
        XCTAssertEqual(node.childNodes.count, drawn.count)
        XCTAssertEqual(node.childNodes.map(\.name), drawn.map { $0.role.rawValue })
        for child in node.childNodes {
            XCTAssertNotNil(child.geometry)
            XCTAssertNotNil(child.geometry?.firstMaterial?.diffuse.contents)
        }
    }

    func testTheNodeIsAsBigAsTheMeshItWasMadeFrom() throws {
        let genome = genome("bounds")
        let growth = PlantSceneBuilder.bloomPreview(for: genome)
        let mesh = PlantBuilder(genome: genome).mesh(growth: growth)
        let node = PlantSceneBuilder.node(for: mesh, palette: genome.palette)

        let box = node.boundingBox
        let accuracy: Float = 1e-3
        XCTAssertEqual(Float(box.min.x), mesh.minBounds.x, accuracy: accuracy)
        XCTAssertEqual(Float(box.min.y), mesh.minBounds.y, accuracy: accuracy)
        XCTAssertEqual(Float(box.min.z), mesh.minBounds.z, accuracy: accuracy)
        XCTAssertEqual(Float(box.max.x), mesh.maxBounds.x, accuracy: accuracy)
        XCTAssertEqual(Float(box.max.y), mesh.maxBounds.y, accuracy: accuracy)
        XCTAssertEqual(Float(box.max.z), mesh.maxBounds.z, accuracy: accuracy)
        // A plant stands on its own origin and grows up from it.
        XCTAssertGreaterThan(box.max.y - box.min.y, 0.01)
    }

    func testTheSameSeedMakesTheSameNodeTwice() throws {
        let genome = genome("again")
        let growth = PlantSceneBuilder.bloomPreview(for: genome)
        func make() -> SCNNode {
            PlantSceneBuilder.node(
                for: PlantBuilder(genome: genome).mesh(growth: growth), palette: genome.palette
            )
        }
        let first = make(), second = make()
        XCTAssertEqual(first.childNodes.count, second.childNodes.count)
        XCTAssertEqual(first.boundingBox.max.y, second.boundingBox.max.y)
        XCTAssertEqual(first.boundingBox.min.x, second.boundingBox.min.x)
    }

    func testAPartMakesGeometryWithoutAPlantsMaterial() throws {
        let genome = genome("part")
        let mesh = PlantBuilder(genome: genome).mesh(growth: PlantSceneBuilder.bloomPreview(for: genome))
        let part = try XCTUnwrap(mesh.parts.first { !$0.indices.isEmpty })
        let geometry = PlantSceneBuilder.geometry(for: part)
        XCTAssertEqual(geometry.sources(for: .vertex).first?.vectorCount, part.positions.count)
        XCTAssertEqual(geometry.elementCount, 1)
        // The material is a separate call, and bakes the three textures.
        let material = PlantSceneBuilder.material(for: part.role, palette: genome.palette)
        XCTAssertEqual(material.lightingModel, .physicallyBased)
        XCTAssertNotNil(material.normal.contents)
    }

    // MARK: - The room

    func testTheSceneIsLitByThreeDirectionsAndAnAmbient() throws {
        let scene = PlantSceneBuilder.makeScene(palette: genome("scene").palette)
        let lights = scene.rootNode.childNodes.compactMap(\.light)
        XCTAssertEqual(lights.filter { $0.type == .directional }.count, 3)
        XCTAssertEqual(lights.filter { $0.type == .ambient }.count, 1)
    }

    func testTheCameraIsPinnedToAVerticalFieldOfView() throws {
        let camera = try XCTUnwrap(PlantSceneBuilder.makeCameraNode().camera)
        XCTAssertEqual(camera.fieldOfView, 36)
        XCTAssertEqual(camera.projectionDirection, .vertical)
        XCTAssertEqual(PlantSceneBuilder.verticalHalfAngle, Float(18 * Double.pi / 180), accuracy: 1e-6)
    }

    func testFramingStandsFurtherBackFromABiggerPlant() throws {
        let small = PlantSceneBuilder.framing(min: SIMD3(-0.1, 0, -0.1), max: SIMD3(0.1, 0.3, 0.1), aspect: 1)
        let tall = PlantSceneBuilder.framing(min: SIMD3(-0.1, 0, -0.1), max: SIMD3(0.1, 0.9, 0.1), aspect: 1)
        XCTAssertGreaterThan(tall.distance, small.distance)
        XCTAssertEqual(Float(small.target.y), 0.15, accuracy: 1e-6, "aimed at the middle of the box")
    }

    // MARK: - The thumbnail

    func testAThumbnailIsAPictureOfAPlantOnNothing() throws {
        let genome = genome("thumbnail")
        let growth = PlantSceneBuilder.bloomPreview(for: genome)
        let image = try XCTUnwrap(ThumbnailRenderer.shared.image(genome: genome, growth: growth, size: 120))
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)

        let (clear, drawn) = try Self.alphaCounts(of: image)
        XCTAssertGreaterThan(drawn, 200, "the plant is in the picture")
        XCTAssertGreaterThan(clear, 200, "and the rest of it is left clear for the backdrop")
    }

    func testAThumbnailIsKeptForTheNextAsk() throws {
        let genome = genome("cache")
        let growth = PlantSceneBuilder.bloomPreview(for: genome)
        let first = ThumbnailRenderer.shared.image(genome: genome, growth: growth, size: 90)
        let second = ThumbnailRenderer.shared.image(genome: genome, growth: growth, size: 90)
        XCTAssertNotNil(first)
        XCTAssertTrue(first === second)
    }

    func testAYoungPlantAndAGrownOneAreDifferentPictures() throws {
        let genome = genome("ages")
        let grown = PlantSceneBuilder.bloomPreview(for: genome)
        let young = GrowthModel(genome: genome).state(
            birth: Date(timeIntervalSinceNow: -3600), now: Date()
        )
        let a = try XCTUnwrap(ThumbnailRenderer.shared.image(genome: genome, growth: young, size: 100))
        let b = try XCTUnwrap(ThumbnailRenderer.shared.image(genome: genome, growth: grown, size: 100))
        XCTAssertNotEqual(a.pngData(), b.pngData())
    }

    // MARK: - The view

    func testTheViewHostsASceneWithThePlantInIt() throws {
        let genome = genome("view")
        let growth = PlantSceneBuilder.bloomPreview(for: genome)
        let host = UIHostingController(rootView: PlantSceneView(genome: genome, growth: growth, isInteractive: false))
        // SwiftUI makes a representable's view once it is on screen, so the
        // controller is given a window to be in.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        func scnView(in view: UIView) -> SCNView? {
            if let found = view as? SCNView { return found }
            for sub in view.subviews { if let found = scnView(in: sub) { return found } }
            return nil
        }
        let scene = try XCTUnwrap(scnView(in: host.view)?.scene)
        // The turntable is the node the plant hangs from; the camera rig and
        // four lights stand beside it.
        XCTAssertGreaterThanOrEqual(scene.rootNode.childNodes.count, 6)
        XCTAssertEqual(scene.rootNode.childNodes.compactMap(\.light).count, 4)
    }

    // MARK: - Helpers

    /// How many pixels of `image` are fully clear, and how many are not.
    static func alphaCounts(of image: UIImage) throws -> (clear: Int, drawn: Int) {
        let cg = try XCTUnwrap(image.cgImage)
        let width = cg.width, height = cg.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let space = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        try pixels.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: space, bitmapInfo: info
            ))
            context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        var clear = 0, drawn = 0
        for index in stride(from: 3, to: pixels.count, by: 4) {
            if pixels[index] == 0 { clear += 1 } else { drawn += 1 }
        }
        return (clear, drawn)
    }
}
