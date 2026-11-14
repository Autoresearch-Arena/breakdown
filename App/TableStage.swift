// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: Hosts the 3D table inside SwiftUI. Builds the TableScene once, runs the per-frame step (advance the
//          model's clock, place everything for that time, aim the camera, and project the caption's ball to the
//          screen for the leader ring), and reloads the Lens when a new shot is recorded. Anything that changes
//          while the scene runs (the room left for the controls, whether the aim line shows, the view's size) is
//          passed through SceneBridge, a plain reference object, because the per-frame closure is created once and
//          would otherwise keep reading stale copies. Does not draw the table: TableScene and its files do that.
// SRP/DRY check: Pass - split out of ShowpieceView; the scene hand-off code is unchanged from before the glow-up,
//          only the inputs now come from the bridge instead of the view's own state.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import RealityKit
import SwiftUI

/// Values the per-frame closure needs that change after the scene is built.
@MainActor
final class SceneBridge {
    var table: TableScene?
    /// Show the guide line from the cue ball while the shot panel is open.
    var showAim = false
    /// Fraction of the view's height covered by the controls (and panel) at the bottom, for the camera.
    var bottomInset = 0.2
    /// The size of the 3D view itself, which the camera frames the table to.
    var viewSize = CGSize(width: 800, height: 600)
    /// Where the 3D view's top-left corner sits in StageSpace (negative when it extends under the safe areas).
    var viewOrigin = CGPoint.zero
}

struct TableStage: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    let leader: LeaderState
    let showAim: Bool
    let bottomInset: Double

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
                    table.updateCamera(melt: model.melt, viewSize: bridge.viewSize, bottomInset: bridge.bottomInset)
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
        .onChange(of: showAim, initial: true) { _, new in bridge.showAim = new }
        .onChange(of: bottomInset, initial: true) { _, new in bridge.bottomInset = new }
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
