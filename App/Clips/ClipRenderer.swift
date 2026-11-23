// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Draws a Lens clip's pictures (0.7.7, plans/23-Nov-2026-clips-plan.md, Step 6). The film is made from the
//          recorded shot, frame by frame, not by recording the screen, so the same shot always makes the same film at
//          full quality whatever else is on screen, on iPhone, iPad and Mac alike.
//          How: a second TableScene is built from the clip's own recording (an entity has one parent, so the live
//          table cannot be lent out), marked offscreen so it leaves the live game's shared state alone, and handed to
//          RealityKit's offscreen renderer (RealityRenderer) with the scene's own perspective camera. For each frame of
//          the script: the scene is placed for that frame's clock and melt with its wall-clock eases pinned to the
//          clip's own clock (SceneClock.pinned, frame / 30), the camera is framed on the clip's canvas (ClipShape), the
//          renderer draws into one Metal texture, Core Image flips it upright, ClipOverlay lays the words, ring and end
//          card over it, and the result is rendered on the GPU straight into a pixel buffer from the video writer's
//          pool and appended (ClipVideoWriter). Each frame awaits the GPU and the writer, so the main actor is free
//          between frames and the game keeps playing while the clip is made.
//          Returns the camera's right-hand direction on every frame, which ClipSound needs to pan each contact.
//          Never touches the live model, the live scene, SoundStage's stored listener or RideLive.
//          Known risks the coordinator's first run shows (see the plan): the texture's colour format (.bgra8Unorm_srgb;
//          if the picture is refused or dark, use .rgba16Float with extended linear sRGB), the vertical flip (if the
//          self-test clip is upside down, drop it), and the floor's lighting (dark on the first run: renderer.lighting's
//          resource is now the same StartupAssets environment).
// SRP/DRY check: Pass - reuses TableScene whole (table, Lens, camera, moment framing) and StartupAssets' pictures;
//          the only new drawing is ClipOverlay's.
import CoreGraphics
import CoreImage
import CoreVideo
import Foundation
import Metal
import RealityKit
import simd

enum ClipRenderError: Error {
    case noGPU
    case noTexture
    case badFrame
}

@MainActor
final class ClipRenderer {
    let source: ClipSource
    let shape: ClipShape
    let script: ClipScript
    private let sRGB = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    private let linearSRGB = CGColorSpace(name: CGColorSpace.linearSRGB) ?? CGColorSpaceCreateDeviceRGB()

    init(source: ClipSource, shape: ClipShape, script: ClipScript) {
        self.source = source
        self.shape = shape
        self.script = script
    }

    /// Draws every frame of the script into a silent video at `url`. `progress` is told 0 to 0.9 as frames are written
    /// (the sound and the final file take the rest). Throws CancellationError when the task is cancelled; the half
    /// written file is then deleted.
    func renderVideo(to url: URL, progress: (Double) -> Void) async throws -> [SIMD3<Float>] {
        // 1. The pictures the table fetches on demand, so no frame shows a bare bed. (The wood, pocket wall and ball
        //    pictures the table reads while it is built are already drawn: a clip is only ever offered after the live
        //    table has been built.)
        _ = await StartupAssets.shared.environment()
        _ = await StartupAssets.shared.bedImage(for: source.surface)
        _ = await StartupAssets.shared.clothDetailNormal()
        _ = await StartupAssets.shared.compactBallImages()
        try Task.checkCancellation()

        // 2. The clip's own table, offscreen.
        let scene = TableScene(timeline: source.timeline, surface: source.surface, table: source.table)
        scene.isOffscreen = true
        scene.load(source.timeline, version: 1, kind: source.table, cueBall: source.striker)
        await scene.installEnvironment()
        try Task.checkCancellation()

        // 3. The offscreen renderer, looking through the scene's own camera on the room's ground colour.
        let renderer = try RealityRenderer()
        renderer.entities.replaceAll([scene.root])
        defer { renderer.entities.removeAll() }
        renderer.activeCamera = scene.cameraEntity
        // The live view lights the whole room from the same environment picture by default; an offscreen renderer
        // starts with none, and the first clips came out much darker than the game (0.7.7 merge check). Give it the
        // same environment, so the film's table matches the screen's.
        if let environment = await StartupAssets.shared.environment() {
            renderer.lighting.resource = environment
        }
        var settings = renderer.cameraSettings
        settings.colorBackground = .color(CGColor(srgbRed: 0.02, green: 0.03, blue: 0.05, alpha: 1))
        settings.antialiasing = .multisample4X
        renderer.cameraSettings = settings

        // 4. One colour texture of the film's size, and Core Image on the same GPU.
        guard let device = MTLCreateSystemDefaultDevice() else { throw ClipRenderError.noGPU }
        let width = Int(shape.pixelSize.width), height = Int(shape.pixelSize.height)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: width,
                                                                  height: height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        guard let texture = device.makeTexture(descriptor: descriptor) else { throw ClipRenderError.noTexture }
        let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: texture))
        let ciContext = CIContext(mtlDevice: device, options: [.workingColorSpace: sRGB])

        // 5. The writer, deleted again unless every frame makes it in.
        let writer = try ClipVideoWriter(url: url, pixelSize: shape.pixelSize)
        try writer.start()
        var finished = false
        defer { if !finished { writer.cancel() } }
        let overlay = ClipOverlay(shape: shape, title: source.title)

        guard let first = script.frames.first else { throw ClipRenderError.badFrame }
        // 6. Three warm-up renders of frame 0, thrown away, so late material swaps land before the first real frame.
        //    Each runs on the clip's clock at 0: the camera's launch pull-back and its eases start their clock at the
        //    first update, so a warm-up off the pin would start them on the device clock.
        for _ in 0..<3 {
            place(scene, first, at: 0)
            try await draw(renderer, output)
        }

        // 7. Every frame.
        var rights: [SIMD3<Float>] = []
        rights.reserveCapacity(script.frames.count)
        let count = script.frames.count
        let film = CGRect(origin: .zero, size: shape.pixelSize)
        for (i, f) in script.frames.enumerated() {
            try Task.checkCancellation()
            place(scene, f, at: Double(i) / ClipScript.fps)
            let camera = scene.tableCamera
            // Screen right across the table, for the sound's pan (TableCamera hands SoundStage the same direction).
            rights.append(simd_cross(camera.forward, SIMD3<Float>(0, 1, 0)))
            try await draw(renderer, output)
            // An _srgb texture hands back linear light when read, so Core Image must be told the values are linear;
            // tagged sRGB, the picture was darkened a second time and the table came out far too dark (0.7.7 check).
            guard let raw = CIImage(mtlTexture: texture, options: [.colorSpace: linearSRGB]) else {
                throw ClipRenderError.badFrame
            }
            // A Metal texture's first row is the top of the picture; Core Image counts from the bottom: flip it.
            let base = raw.transformed(by: CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -CGFloat(height)))
            let composed = overlay.frameImage(base: base, frame: f, script: script, camera: camera,
                                              timeline: source.timeline)
            let buffer = try writer.nextBuffer()
            ciContext.render(composed, to: buffer, bounds: film, colorSpace: sRGB)
            try await writer.append(buffer, frame: i)
            progress(0.9 * Double(i + 1) / Double(count))
            await Task.yield()
        }
        try await writer.finish()
        finished = true
        return rights
    }

    /// Places the clip's scene for one frame, on the clip's clock. The moment framing's share is held at the middle
    /// (the upright phone's explanation blurb may have moved it for the live table) and put back at once.
    private func place(_ scene: TableScene, _ f: ClipFrame, at t: Double) {
        let share = MomentFrame.blurbShare
        MomentFrame.blurbShare = 0.5
        defer { MomentFrame.blurbShare = share }
        SceneClock.pinned(at: t) {
            scene.lensHeldEvent = f.heldEvent
            scene.apply(time: f.clock, melt: f.melt, rate: max(f.rate, 0), aim: nil, cueAim: nil, stroke: source.stroke,
                        ride: false)
            scene.moment = MomentRequest(allowed: f.momentAllowed, plan: script.plan)
            scene.updateCamera(melt: f.melt, request: shape.framingRequest, ride: false)
        }
    }

    /// One render of the scene into the texture, awaited until the GPU has finished. A render that throws at once
    /// resumes with its error (inside the continuation), so nothing waits for an onComplete that never comes.
    private func draw(_ renderer: RealityRenderer, _ output: RealityRenderer.CameraOutput) async throws {
        try await withCheckedThrowingContinuation { (done: CheckedContinuation<Void, Error>) in
            do {
                try renderer.updateAndRender(deltaTime: 1.0 / ClipScript.fps, cameraOutput: output,
                                             onComplete: { _ in done.resume() })
            } catch {
                done.resume(throwing: error)
            }
        }
    }
}
