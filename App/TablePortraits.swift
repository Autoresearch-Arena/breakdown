// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: Pictures of the four tables for the Tables page (0.7.10, plans/25-Nov-2026-front-door-and-table-view-plan.md
//          Stage 1 step 4: "tables are shown, not listed"). Each picture is the real table, built by the real table
//          builder (a TableScene of that table, its start layout on it, still, lit by the same lamp and room picture
//          as the game) and drawn once with RealityKit's offscreen renderer from the game's own warm camera, framed by
//          CameraFraming like the table on screen. The four are drawn one after another the first time the Tables page
//          asks, kept in memory for the rest of the session (a few hundred kilobytes in all), and never drawn again.
//          The page shows the table's symbol until its picture arrives.
//          The steps are the clip renderer's (ClipRenderer.renderVideo, which has run on devices since 0.7.7), cut down
//          to one still: the pictures the table fetches on demand are awaited first, the scene is marked offscreen so
//          it leaves the live game's sound listener and Ride map alone, three warm-up renders let late material swaps
//          land, and the camera's launch pull-back is pinned past its end (SceneClock) so the table is framed exactly.
//          The texture is read back through Core Image as linear light, as the clip renderer found it must be.
//          A table whose picture fails (no GPU, a renderer error) is logged and keeps its symbol; nothing else waits.
//          Read by TableList. Reads TableKind (start layouts, the table files), Rack (the pool table's rack),
//          PoolSolver (a zero-speed shot is a still table), StartupAssets and TableScene.
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 7's leftover note: the picture clips to the kit's
//          small corners (Theme.Corner.tileShape) instead of a bare 12 point radius, and the waiting symbol is the
//          heading role in paper2 instead of a bare title font at a hand-picked opacity.)
// SRP/DRY check: Pass - checked ClipRenderer (the same offscreen route; its writer, overlay and per-frame film loop are
//          not needed for one still, so the few shared steps are repeated here with a pointer back to it rather than
//          bending the clip type into a picture maker), TrickPathThumb (a flat drawing of the pool table only) and
//          TablePlan (the flat plan the maps draw).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import CoreImage
import Foundation
import Metal
import Observation
import RealityKit
import SwiftUI

@MainActor @Observable
final class TablePortraits {
    static let shared = TablePortraits()

    /// The pictures drawn so far, by table. Observed, so each tile shows its picture as soon as it is drawn.
    private(set) var images: [TableKind: CGImage] = [:]
    @ObservationIgnored private var drawing: Task<Void, Never>?

    /// The picture's size in pixels: wide, for a tile about 160 points across at 3x would be 480; 2:1 holds every
    /// table lying across with a little room above and below.
    static let pixelSize = CGSize(width: 480, height: 240)
    /// The canvas the camera frames on, in points (the pixel size at 2x): only its shape and the margins count.
    static let canvas = CGSize(width: 240, height: 120)

    private init() {}

    /// Starts drawing the pictures not drawn yet, one table after another, unless that is already under way.
    func drawIfNeeded() {
        guard drawing == nil, images.count < TableKind.allCases.count else { return }
        drawing = Task { @MainActor [weak self] in
            for kind in TableKind.allCases {
                guard let self, self.images[kind] == nil else { continue }
                do {
                    if let image = try await Self.render(kind) { self.images[kind] = image }
                } catch {
                    NSLog("TablePortraits: the %@ picture was not drawn: %@", kind.rawValue, String(describing: error))
                }
            }
            self?.drawing = nil
        }
    }

    /// A still recording of the table's start: the pool table's rack, or another table's own start layout, struck at
    /// zero speed so nothing moves (the same trick the game uses to put a rack or a table's start on screen).
    private static func stillTimeline(_ kind: TableKind) -> Timeline {
        var input: ShotInput
        if let start = kind.startLayout {
            input = NextShot.shot(from: start, direction: Vec2(1, 0), speed: 0, tipUp: 0, tipSide: 0, seed: 0)
        } else {
            input = Rack.breakShot(parameters: PoolParameters(), seed: 11, aimOffset: 0, speed: 0)
        }
        kind.apply(to: &input.parameters)
        PlaySurface.cloth.apply(to: &input.parameters)
        return PoolSolver.simulate(input)
    }

    /// Builds the table offscreen and draws it once. Nil when the texture cannot be read back as a picture.
    private static func render(_ kind: TableKind) async throws -> CGImage? {
        // 1. The pictures the table fetches on demand (as ClipRenderer step 1), so the picture has no bare bed.
        _ = await StartupAssets.shared.environment()
        _ = await StartupAssets.shared.bedImage(for: .cloth)
        _ = await StartupAssets.shared.clothDetailNormal()
        _ = await StartupAssets.shared.compactBallImages()

        // 2. The table, offscreen: it never touches the live game's listener, Ride map or self-tests.
        let timeline = stillTimeline(kind)
        let scene = TableScene(timeline: timeline, surface: .cloth, table: kind)
        scene.isOffscreen = true
        scene.load(timeline, version: 1, kind: kind, cueBall: 0)
        await scene.installEnvironment()

        // 3. The offscreen renderer, through the scene's own camera, on the room's ground colour, lit by the same
        //    environment picture as the live view (an offscreen renderer starts with none and draws far too dark).
        let renderer = try RealityRenderer()
        renderer.entities.replaceAll([scene.root])
        defer { renderer.entities.removeAll() }
        renderer.activeCamera = scene.cameraEntity
        if let environment = await StartupAssets.shared.environment() {
            renderer.lighting.resource = environment
        }
        var settings = renderer.cameraSettings
        settings.colorBackground = .color(CGColor(srgbRed: 0.02, green: 0.03, blue: 0.05, alpha: 1))
        settings.antialiasing = .multisample4X
        renderer.cameraSettings = settings

        // 4. One colour texture of the picture's size.
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        let width = Int(pixelSize.width), height = Int(pixelSize.height)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: width,
                                                                  height: height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: texture))

        // 5. Place the still table and draw it: three warm-up renders thrown away (late material swaps land), then the
        //    one kept. The scene clock is pinned so the camera's launch pull-back has finished (it eases over
        //    CameraFraming.introSeconds from the first update), so the table is framed exactly, as in the game.
        let request = FramingRequest(size: canvas, safe: FramingInsets(), headerBottom: 0, controlsTop: nil)
        for pass in 0..<4 {
            SceneClock.pinned(at: Double(pass) * 2) {
                scene.apply(time: 0, melt: 0, rate: 0, aim: nil, cueAim: nil, stroke: nil, ride: false)
                scene.updateCamera(melt: 0, request: request, ride: false)
            }
            try await draw(renderer, output)
            // Let the bed's picture, dressed by a task when the scene was built, land before the kept render.
            await Task.yield()
        }

        // 6. Read back: an _srgb texture hands back linear light, so Core Image is told so; a Metal texture's first row
        //    is the top of the picture and Core Image counts from the bottom, so it is flipped (both as ClipRenderer).
        let linear = CGColorSpace(name: CGColorSpace.linearSRGB) ?? CGColorSpaceCreateDeviceRGB()
        let sRGB = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        guard let raw = CIImage(mtlTexture: texture, options: [.colorSpace: linear]) else { return nil }
        let upright = raw.transformed(by: CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -CGFloat(height)))
        let context = CIContext(mtlDevice: device, options: [.workingColorSpace: sRGB])
        return context.createCGImage(upright, from: CGRect(x: 0, y: 0, width: width, height: height), format: .RGBA8,
                                     colorSpace: sRGB)
    }

    /// One render into the texture, awaited until the GPU has finished (ClipRenderer.draw).
    private static func draw(_ renderer: RealityRenderer, _ output: RealityRenderer.CameraOutput) async throws {
        try await withCheckedThrowingContinuation { (done: CheckedContinuation<Void, Error>) in
            do {
                try renderer.updateAndRender(deltaTime: 1.0 / 30, cameraOutput: output, onComplete: { _ in done.resume() })
            } catch {
                done.resume(throwing: error)
            }
        }
    }
}

/// One table's picture on the Tables page, or its symbol on the cloth's colour while the picture is being drawn.
struct TablePortrait: View {
    let kind: TableKind
    @Environment(\.palette) private var palette

    var body: some View {
        let portraits = TablePortraits.shared
        ZStack {
            if let image = portraits.images[kind] {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                TablePlan.bed
                Image(systemName: kind.symbol)
                    .font(Theme.heading)
                    .foregroundStyle(palette.paper2)
            }
        }
        .aspectRatio(TablePortraits.pixelSize.width / TablePortraits.pixelSize.height, contentMode: .fit)
        // The kit's small corners, the same shape the Tables cards and the table page clip it to.
        .clipShape(Theme.Corner.tileShape)
        .onAppear { portraits.drawIfNeeded() }
        .accessibilityHidden(true)
    }
}
