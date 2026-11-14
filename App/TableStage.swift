// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: Hosts the 3D table inside SwiftUI. Builds the TableScene once, runs the per-frame step (advance the
//          model's clock, place everything for that time, aim the camera, and project the caption's ball to the
//          screen for the leader ring), and reloads the Lens when a new shot is recorded. Anything that changes
//          while the scene runs (the free space the screen measured, whether the aim line shows, the view's size) is
//          passed through SceneBridge, a plain reference object, because the per-frame closure is created once and
//          would otherwise keep reading stale copies. Does not draw the table: TableScene and its files do that.
//          Package 4 (0.4.0): the screen now hands over StageChrome, the real laid-out edges of the title row, the caption
//          slot and the control strip plus the safe areas, all in StageSpace; this file turns them into the 3D view's
//          own coordinates (a FramingRequest) every frame, so the camera frames the table in exactly the space that is
//          left, in portrait, landscape, on iPad and on the Mac. Before, a guessed fraction of the height was passed.
// SRP/DRY check: Pass - split out of ShowpieceView; the scene hand-off code is unchanged from before the glow-up,
//          only the inputs now come from the bridge instead of the view's own state.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import RealityKit
import SwiftUI
#if os(iOS)
import UIKit
#endif

/// What the screen measured of itself, in StageSpace (points, origin at the stage's top-left inside the safe area).
/// ShowpieceView fills this from the real laid-out views; the camera never sees a guessed margin.
struct StageChrome: Equatable {
    /// Safe-area insets of the region the 3D view fills (the side column's side has none).
    var safe = FramingInsets()
    /// Bottom edge of the title row.
    var headerBottom: Double?
    /// Bottom edge of the caption slot (phone held upright); nil where captions sit in a side column.
    var captionBottom: Double?
    /// Top edge of the control strip; nil where the controls live in the side column.
    var controlsTop: Double?
}

/// Values the per-frame closure needs that change after the scene is built.
@MainActor
final class SceneBridge {
    var table: TableScene?
    /// Show the guide line from the cue ball while the shot panel is open.
    var showAim = false
    /// The measured title, caption and control edges, for the camera.
    var chrome = StageChrome()
    /// The size of the 3D view itself, which the camera frames the table to.
    var viewSize = CGSize(width: 800, height: 600)
    /// Where the 3D view's top-left corner sits in StageSpace (negative when it extends under the safe areas).
    var viewOrigin = CGPoint.zero

    /// The free-space request for the camera, in the 3D view's own coordinates. Edges not measured yet (the first
    /// frame) fall back to the safe area plus a typical title row, which is replaced as soon as the real one arrives.
    func request() -> FramingRequest {
        let oy = Double(viewOrigin.y)
        let header = chrome.headerBottom.map { $0 - oy } ?? (chrome.safe.top + 40)
        let caption = max(header, chrome.captionBottom.map { $0 - oy } ?? header)
        let q = FramingRequest(size: viewSize, safe: chrome.safe, headerBottom: header, captionBottom: caption,
                               controlsTop: chrome.controlsTop.map { $0 - oy })
        // Test hook: launch with -frameDebug to print the measured request whenever it changes.
        if Self.frameDebug, q != lastLogged { lastLogged = q; NSLog("FRAMING %@ origin=%@", String(describing: q), String(describing: viewOrigin)) }
        return q
    }
    private static let frameDebug = ProcessInfo.processInfo.arguments.contains("-frameDebug")
    private var lastLogged: FramingRequest?
}

struct TableStage: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    let leader: LeaderState
    let showAim: Bool
    let chrome: StageChrome

    var body: some View {
        RealityView { content in
            #if os(iOS)
            content.camera = .virtual
            #endif
            let table = TableScene(timeline: model.timeline)
            content.add(table.root)
            bridge.table = table
            table.load(model.timeline, version: model.timelineVersion)
            // Reflections: lights the glossy parts from a generated lamp picture.
            await table.installEnvironment()
            // A copy of the content that the per-frame closure may keep: it is only used to project points to the screen.
            let projector = content
            table.subscriptions.append(content.subscribe(to: SceneEvents.Update.self) { event in
                MainActor.assumeIsolated {
                    model.advance(event.deltaTime)
                    let aim: AimPreview? = bridge.showAim ? Self.aim(for: model) : nil
                    table.apply(time: model.time, melt: model.melt, rate: model.displayRate, aim: aim)
                    table.updateCamera(melt: model.melt, request: bridge.request())
                    // The camera has just moved, so project after it: the ring must sit on this frame's ball.
                    // Project into the 3D view's own space, then shift by where that view sits on the stage.
                    // (Projecting straight into the named space came back offset by twice the top safe-area inset in
                    // the iOS 27.2 simulator, so the shift is done here, where it can be checked.)
                    leader.refresh(model: model) { world in
                        guard let local = projector.project(point: world, to: .local) else { return nil }
                        return CGPoint(x: local.x + bridge.viewOrigin.x, y: local.y + bridge.viewOrigin.y)
                    }
                }
            })
        } update: { _ in
            if let table = bridge.table, model.timelineVersion >= 0 {
                table.load(model.timeline, version: model.timelineVersion)
            }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: {
            bridge.viewSize = $0.size
            bridge.viewOrigin = $0.origin
        }
        #if os(iOS)
        // Test hook: -forceLandscape turns the app sideways at launch so landscape can be checked on a simulator that
        // has no rotate command here. No effect without the flag.
        .onAppear {
            guard ProcessInfo.processInfo.arguments.contains("-forceLandscape"),
                  let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        }
        #endif
        .onChange(of: showAim, initial: true) { _, new in bridge.showAim = new }
        .onChange(of: chrome, initial: true) { _, new in bridge.chrome = new }
        .ignoresSafeArea()
        // The scene is a picture of the table; VoiceOver users drive it through the controls and captions.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pool table")
        .accessibilityValue(model.lensOn ? "Physics Lens view" : "Table view")
    }

    static func aim(for model: ShowpieceModel) -> AimPreview {
        // After the first shot the guide line follows the aim slider from the cue ball's resting spot.
        if !model.racked, model.layout.count == 16 {
            return AimPreview(from: model.layout[0], direction: model.shotAimDirection, length: 1.4, always: true)
        }
        let positions = Rack.positions(parameters: PoolParameters(), seed: UInt64(10 + model.breakSerial + 1))
        let target = positions[1] + Vec2(0, model.aimOffset)
        let dir = (target - positions[0]).normalized
        return AimPreview(from: positions[0], direction: dir, length: 1.2, always: true)
    }
}
