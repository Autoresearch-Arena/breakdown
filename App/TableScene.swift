// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// PURPOSE: The thin coordinator of the 3D scene. Owns the root entity and the shared state (current timeline and
//          table frame, the ball entities), wires the three jobs together, and runs the per-frame apply(): fade the
//          warm table out and the Lens in with the melt value, place every ball for the playback clock, then hand the
//          Lens layer and the camera what they need. RealityKit physics is not used: every transform comes from the
//          recorded timeline, so scrubbing in either direction is exact.
//          Layout (package 0 of the glow-up plan, 13-Nov-2026; behaviour unchanged from 0.2.2):
//            TableScene.swift   this file: root, shared state, load(), apply(), ball placement. Keep it short.
//            TableBuilder.swift the static warm table, rails, cushions, pockets, balls, lights, reflections.
//            LensLayer.swift    grid, trails, rings, arrows, aim line and their per-frame reveal.
//            TableCamera.swift  camera rig, framing and the melt swing.
//          Edit the file for the job you are doing; do not add Lens or table detail back into this one.
// SRP/DRY check: Pass - coordination only; it reads the model and timeline and never changes them.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import CoreGraphics
import Foundation
import RealityKit
import simd

@MainActor
final class TableScene {
    let root = Entity()
    private let tableGroup: Entity
    private let lens = LensLayer()
    private let camera = TableCamera()
    private var balls: [Entity] = []
    private var bodies: [ModelEntity] = []
    private var markers: [ModelEntity] = []
    private var frame: TableFrame
    private var timeline: Timeline
    private var loadedVersion = -1
    var subscriptions: [EventSubscription] = []

    init(timeline: Timeline) {
        self.timeline = timeline
        frame = TableFrame(timeline.table)
        tableGroup = TableBuilder.makeTable(frame: frame, pockets: timeline.table.pockets)
        // Child order matches the old single-file scene: table, Lens, camera, then balls and lights.
        root.addChild(tableGroup)
        root.addChild(lens.root)
        root.addChild(camera.rig)
        lens.buildStatic(ballCount: timeline.ballCount, frame: frame)
        for n in 0..<timeline.ballCount {
            let parts = TableBuilder.makeBall(number: n, radius: frame.ballRadius, parent: root)
            balls.append(parts.ball); bodies.append(parts.body); markers.append(parts.marker)
        }
        TableBuilder.addLights(to: root)
    }

    /// Light the scene with the generated lamp picture so the glossy parts have something to reflect.
    func installEnvironment() async {
        await TableBuilder.installEnvironment(on: root)
    }

    /// Rebuild the Lens trails and rings for a new recorded shot.
    func load(_ timeline: Timeline, version: Int) {
        guard version != loadedVersion else { return }
        loadedVersion = version
        self.timeline = timeline
        frame = TableFrame(timeline.table)
        lens.rebuild(timeline: timeline, frame: frame)
        for b in 0..<balls.count {
            balls[b].isEnabled = true
        }
    }

    // MARK: Per frame

    func apply(time t: Double, melt: Double, rate: Double, aim: AimPreview?) {
        let R = frame.ballRadius
        let m = Float(melt)
        let tableOpacity = max(0, 1 - Float(melt) * 1.15)
        tableGroup.components.set(OpacityComponent(opacity: tableOpacity))
        tableGroup.isEnabled = tableOpacity > 0.01

        var visibility: [Bool] = []
        for b in 0..<balls.count {
            let s = timeline.state(ball: b, at: t)
            var pos = frame.world(s.position, height: R)
            var scale: Float = 1
            var visible = true
            if s.pocketed, let tp = timeline.pocketTime[b] {
                let k = Float(min(1, (t - tp) / 0.22))
                pos.y -= 0.09 * k
                scale = 1 - 0.7 * k
                visible = (t - tp) < 0.35
            }
            // A ball parked off the table (pocketed in an earlier shot) never shows.
            if !NextShot.isOnTable(timeline.segments[b][0].position0) { visible = false }
            balls[b].isEnabled = visible
            balls[b].position = pos
            balls[b].orientation = frame.orientation(s.orientation)
            balls[b].scale = SIMD3(repeating: scale)
            bodies[b].components.set(OpacityComponent(opacity: 1 - 0.55 * m))
            markers[b].components.set(OpacityComponent(opacity: m))
            visibility.append(visible)
        }

        lens.apply(time: t, melt: melt, rate: rate, aim: aim, timeline: timeline, frame: frame, ballVisible: visibility)
    }

    /// Frames the whole table and swings from a low three-quarter view to straight down as the Lens melts in.
    func updateCamera(melt: Double, viewSize: CGSize, bottomInset: Double) {
        camera.update(melt: melt, viewSize: viewSize, bottomInset: bottomInset, frame: frame)
    }
}
