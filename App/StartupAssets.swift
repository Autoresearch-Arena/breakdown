// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (playing beds for the Surface menu: each surface's picture is drawn
//          only when it is chosen, in the background, and kept; the surface saved from last time is started with the
//          launch pictures so a table that opens on ice does not wait for it).
// Edited: Claude Opus 5.5 High, 21-November-2026 (look plan: two pictures that the first frame does not need, the
//          cloth's close-up normal map and the sixteen high-contrast "compact" ball pictures, are drawn on a second
//          background pass that starts only after the launch pictures are finished, so they add nothing to launch time;
//          the table asks for them with async calls and puts them on when they arrive).
// PURPOSE: Makes every generated picture the table needs (cloth, wood, floor, pocket wall, sixteen ball faces, the
//          Lens grid, and the lamp-and-room reflection) on background threads, all at once, starting the moment the app
//          launches, so the main thread no longer spends a second or two in a debug build drawing pixels before the
//          first frame. Pictures are plain CGImages (safe to hand between threads); turning one into a RealityKit
//          texture is a small step the main thread does when the table is assembled. If the table asks for a picture
//          that is not finished it waits for it (never draws it a second time), and if it asks for a picture made
//          for different table sizes it draws that one on the spot, so the result is always correct, only sometimes
//          slower. Also holds the StartupGate that tells the screen when the scene has been built, and the -logStartup
//          stopwatch used to measure all this.
//          Reads: PoolParameters (the default table, to know the sizes), the Lens contrast setting (once, on the main
//          thread). Called by: BreakdownApp (prewarm), TableBuilder (cloth, wood, floor, wall, balls, reflection),
//          BallTextures.gridTexture (the grid).
// SRP/DRY check: Pass - owns when and where the pictures are made; WHAT they look like stays in SurfaceTextures and
//          BallTextures, and where they are placed stays in TableBuilder. Checked those three; nothing duplicated.
import BreakdownPhysics
import CoreGraphics
import Foundation
import Observation
import RealityKit

/// Start-up stopwatch for the launch argument -logStartup: prints milliseconds since the process began, so the cost of
/// building the scene can be compared between builds. Silent without the flag. Safe to call from any thread.
enum StartupLog {
    static let enabled = ProcessInfo.processInfo.arguments.contains("-logStartup")
    private static let processStart: Date? = {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0 else { return nil }
        let t = info.kp_proc.p_un.__p_starttime
        return Date(timeIntervalSince1970: TimeInterval(t.tv_sec) + TimeInterval(t.tv_usec) / 1_000_000)
    }()
    static func mark(_ what: String) {
        guard enabled else { return }
        let ms = processStart.map { Int(Date().timeIntervalSince($0) * 1000) } ?? -1
        NSLog("STARTUP %@ at +%dms since process start", what, ms)
    }
}

/// Tells the window when the 3D scene has been built, so the dark cover over it can fade away.
@MainActor @Observable
final class StartupGate {
    static let shared = StartupGate()
    private(set) var sceneBuilt = false
    func sceneIsBuilt() { if !sceneBuilt { sceneBuilt = true; StartupLog.mark("scene built") } }
}

/// The background picture factory. One shared instance; `prewarm()` is idempotent.
final class StartupAssets: @unchecked Sendable {
    static let shared = StartupAssets()

    /// What a grid picture was drawn for; a request is served from the cache only when all of it matches.
    private struct GridKey { let length: Double, width: Double, radii: [Double], boost: Double }

    // Everything below is written by background jobs and read by the main thread, always under `lock`.
    private let lock = NSLock()
    private let done = DispatchGroup()
    private var started = false
    private var cloth: CGImage?, wood: CGImage?, wall: CGImage?
    private var floor: (half: SIMD2<Float>, image: CGImage?)?
    private var balls = [CGImage?](repeating: nil, count: 16)
    private var grid: (key: GridKey, image: CGImage?)?
    /// Playing-bed pictures for surfaces other than cloth, kept once drawn (the cloth is `cloth` above).
    private var beds: [PlaySurface: CGImage] = [:]
    private var environmentTask: Task<EnvironmentResource?, Never>?
    /// The second pass (see the header): finished when `later` is left. Written under `lock` like everything else.
    private let later = DispatchGroup()
    private var clothDetail: CGImage?
    private var compactBalls = [CGImage?](repeating: nil, count: 16)

    private func locked<T>(_ body: () -> T) -> T { lock.lock(); defer { lock.unlock() }; return body() }

    /// Start making every picture on background threads. Call once, early, on the main thread.
    @MainActor func prewarm() {
        let first: Bool = locked { let f = !started; started = true; return f }
        if !first { return }
        StartupLog.mark("prewarm begin")
        let spec = PoolParameters().tableSpec
        let half = TableBuilder.floorHalfExtent(length: Float(spec.length), width: Float(spec.width))
        // The Lens contrast setting is read on the main thread (it asks UIKit), then handed to the grid job.
        let boost = LensTextures.increaseContrast ? 2.2 : 1.0
        let pockets = zip(spec.pockets, spec.pocketCaptureRadius).map { (x: $0.0.x, y: $0.0.y, radius: $0.1) }
        let gridKey = GridKey(length: spec.length, width: spec.width, radii: pockets.flatMap { [$0.x, $0.y, $0.radius] }, boost: boost)
        let length = spec.length, width = spec.width

        // The reflection picture is its own task: it is drawn, then turned into an environment resource.
        let envTask = Task.detached(priority: .userInitiated) { () -> EnvironmentResource? in
            guard let image = TableBuilder.lampEnvironmentImage() else { return nil }
            return try? await EnvironmentResource(equirectangular: image)
        }
        locked { environmentTask = envTask }

        // Every other picture is an independent job, started together so they spread over the cores.
        var jobs: [@Sendable () -> Void] = [
            { let v = SurfaceTextures.clothImage(); self.locked { self.cloth = v } },
            { let v = SurfaceTextures.woodImage(); self.locked { self.wood = v } },
            { let v = SurfaceTextures.roomFloorImage(tableHalf: half); self.locked { self.floor = (half, v) } },
            { let v = SurfaceTextures.pocketWallImage(); self.locked { self.wall = v } },
            { let v = BallTextures.gridImage(length: length, width: width, pockets: pockets, boost: boost); self.locked { self.grid = (gridKey, v) } },
        ]
        for n in 0..<16 { jobs.append { let v = BallTextures.ballImage(number: n); self.locked { self.balls[n] = v } } }
        // Only the surface the table will open on is drawn now; the others wait until someone picks them.
        let surface = PlaySurface.stored
        if surface != .cloth {
            jobs.append { if let v = surface.makeBedImage() { self.locked { self.beds[surface] = v } } }
        }
        let all = jobs

        done.enter()
        later.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.concurrentPerform(iterations: all.count) { all[$0]() }
            StartupLog.mark("prewarm pictures finished")
            self.done.leave()
            // The second pass, at a lower priority, once the launch pictures are in: nothing waits on it to start.
            DispatchQueue.global(qos: .utility).async {
                var second: [@Sendable () -> Void] = [
                    { let v = SurfaceTextures.clothDetailNormalImage(); self.locked { self.clothDetail = v } },
                ]
                for n in 0..<16 { second.append { let v = BallTextures.ballImage(number: n, compact: true); self.locked { self.compactBalls[n] = v } } }
                let jobs = second
                DispatchQueue.concurrentPerform(iterations: jobs.count) { jobs[$0]() }
                StartupLog.mark("second-pass pictures finished")
                self.later.leave()
            }
        }
    }

    /// Waits (without blocking the main thread) until the second pass is finished.
    @MainActor private func laterReady() async {
        prewarm()
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            later.notify(queue: .main) { c.resume() }
        }
    }

    /// The cloth's close-up normal map (SurfaceTextures.clothDetailNormalImage), once the second pass has drawn it.
    @MainActor func clothDetailNormal() async -> CGImage? {
        await laterReady()
        return locked { clothDetail }
    }

    /// The same picture, only if it is already drawn (nil otherwise); for building a material without waiting.
    @MainActor func clothDetailNormalIfReady() -> CGImage? { locked { clothDetail } }

    /// The sixteen high-contrast ball pictures for balls that are small on screen, once the second pass has drawn them.
    @MainActor func compactBallImages() async -> [CGImage?] {
        await laterReady()
        return locked { compactBalls }
    }

    /// Blocks until the background jobs are finished (instant when they already are). If `prewarm()` was never called,
    /// the jobs are started now, so a caller always gets a picture.
    @MainActor private func ready() {
        prewarm()
        done.wait()
    }

    // MARK: Pictures, as the table asks for them

    @MainActor func clothImage() -> CGImage? { ready(); return locked { cloth } }
    @MainActor func woodImage() -> CGImage? { ready(); return locked { wood } }
    @MainActor func pocketWallImage() -> CGImage? { ready(); return locked { wall } }
    @MainActor func ballImage(number n: Int) -> CGImage? { ready(); return locked { balls[n] } }

    /// The playing bed's picture for a surface, now, for building the table. Normally already made (the saved surface
    /// is drawn with the launch pictures); if not, it is drawn on the spot and kept.
    @MainActor func bedImageNow(for surface: PlaySurface) -> CGImage? {
        if surface == .cloth { return clothImage() }
        ready()
        if let image = locked({ beds[surface] }) { return image }
        // Drawn outside the lock (the lock is not re-entrant and drawing takes a while), then stored.
        let image = surface.makeBedImage()
        if let image { locked { beds[surface] = image } }
        return image
    }

    /// The playing bed's picture for a surface just picked from the menu: drawn on a background thread if it has not
    /// been made yet, so the screen keeps moving while it is drawn. Two quick picks of the same new surface may draw it
    /// twice; the second simply replaces the first, which is harmless.
    @MainActor func bedImage(for surface: PlaySurface) async -> CGImage? {
        if surface == .cloth { return clothImage() }
        if let image = locked({ beds[surface] }) { return image }
        // The background job stores the picture itself and hands nothing back across threads.
        await Task.detached(priority: .userInitiated) {
            if let v = surface.makeBedImage() { self.locked { self.beds[surface] = v } }
        }.value
        return locked { beds[surface] }
    }

    /// The floor picture is shaped by the table's outer size; a table of another size gets a fresh one.
    @MainActor func roomFloorImage(tableHalf: SIMD2<Float>) -> CGImage? {
        ready()
        if let f = locked({ floor }), f.half == tableHalf { return f.image }
        return SurfaceTextures.roomFloorImage(tableHalf: tableHalf)
    }

    /// The Lens grid, from the cache when it was drawn for the same table and contrast setting, else drawn now.
    @MainActor func gridImage(length: Double, width: Double, pockets: [(x: Double, y: Double, radius: Double)], boost: Double) -> CGImage? {
        ready()
        let radii = pockets.flatMap { [$0.x, $0.y, $0.radius] }
        // The caller's lengths went through Float on the way, so compare with a tolerance far below a pixel.
        if let g = locked({ grid }), g.key.boost == boost, abs(g.key.length - length) < 1e-4, abs(g.key.width - width) < 1e-4,
           g.key.radii.count == radii.count, zip(g.key.radii, radii).allSatisfy({ abs($0 - $1) < 1e-4 }) {
            return g.image
        }
        return BallTextures.gridImage(length: length, width: width, pockets: pockets, boost: boost)
    }

    /// The finished reflection environment, or nil if it could not be made (the scene then keeps its plain lights).
    @MainActor func environment() async -> EnvironmentResource? {
        prewarm()
        guard let task = locked({ environmentTask }) else { return nil }
        return await task.value
    }

    /// Turns a finished picture into a RealityKit texture with mipmaps (so distant balls and cloth do not shimmer).
    /// `semantic` is .color for pictures and .normal for a normal map (read as directions, not colours).
    @MainActor static func texture(_ image: CGImage?, semantic: TextureResource.Semantic = .color) -> TextureResource? {
        guard let image else { return nil }
        return try? TextureResource(image: image, options: .init(semantic: semantic, mipmapsMode: .allocateAndGenerateAll))
    }
}
