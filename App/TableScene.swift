// Author: Claude Sonnet 5.5 High
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
//          Package 2 (13-Nov-2026) added: the Lens legend hangs off the camera's HUD anchor; test launch flags
//          -lensDebugTime <seconds> and -lensDebugMelt <0..1> pin the clock and melt for screenshots, and
//          -lensSelfTest runs the scrub-exactness check and prints the result.
//          Package 4 (13-Nov-2026): the camera now takes the measured free space (a FramingRequest) and the clock, so it can
//          frame between the title, caption slot and controls and push in on the break; nothing else here changed.
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
    private var tourFrame = 0
    /// The clock the last apply() used (after any test pinning), so the camera pushes in on exactly the frame drawn.
    private var lastClock = 0.0
    var subscriptions: [EventSubscription] = []

    init(timeline: Timeline) {
        self.timeline = timeline
        frame = TableFrame(timeline.table)
        tableGroup = TableBuilder.makeTable(frame: frame, pockets: timeline.table.pockets)
        // Child order matches the old single-file scene: table, Lens, camera, then balls and lights.
        root.addChild(tableGroup)
        root.addChild(lens.root)
        root.addChild(camera.rig)
        lens.buildStatic(ballCount: timeline.ballCount, frame: frame, table: timeline.table)
        camera.hud.addChild(lens.legend)
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
        if Self.launchFlag("-lensSelfTest") { runSelfTest() }
    }

    // MARK: Per frame

    func apply(time rawT: Double, melt rawMelt: Double, rate: Double, aim: AimPreview?) {
        // Test hooks (launch flags): pin the clock and/or the melt so a screenshot shows one exact frame.
        var t = Self.launchValue("-lensDebugTime") ?? rawT
        // -lensDebugTour a,b,c: before settling on the pinned time, visit these clock times, one per frame, forward
        // then back, so a screenshot afterwards can be compared with one taken with no tour (scrub exactness).
        if let tour = Self.launchList("-lensDebugTour"), tourFrame < tour.count { t = tour[tourFrame]; tourFrame += 1 }
        lastClock = t
        let melt = Self.launchValue("-lensDebugMelt") ?? rawMelt
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

        lens.apply(time: t, melt: melt, aim: aim, timeline: timeline, frame: frame, ballVisible: visibility)
    }

    /// Frames the whole table in the measured free space, swings from a low three-quarter view to straight down as the
    /// Lens melts in, and pushes in on the break (see TableCamera).
    func updateCamera(melt: Double, request: FramingRequest) {
        camera.update(melt: Self.launchValue("-lensDebugMelt") ?? melt, clock: lastClock, duration: timeline.duration,
                      request: request, frame: frame)
    }

    // MARK: Test hooks

    private static func launchFlag(_ name: String) -> Bool { ProcessInfo.processInfo.arguments.contains(name) }

    private static func launchList(_ name: String) -> [Double]? {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: name), i + 1 < a.count else { return nil }
        return a[i + 1].split(separator: ",").compactMap { Double($0) }
    }

    private static func launchValue(_ name: String) -> Double? {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: name), i + 1 < a.count else { return nil }
        return Double(a[i + 1])
    }

    /// Scrub-exactness check. Drives the Lens to a list of clock times, records its fingerprint at each, then
    /// visits the same times again going backwards, then in a shuffled order, and compares. Also checks that the
    /// trail fade only ever dims with age. Results go to the console (visible with simctl launch --console).
    private func runSelfTest() {
        let d = timeline.duration
        let times = [0.0, 0.05, 0.3, 0.9, 1.7, 2.6, d * 0.5, d * 0.8, d].map { min($0, d) }
        let visible = [Bool](repeating: true, count: timeline.ballCount)
        func print(at t: Double) -> UInt64 {
            lens.apply(time: t, melt: 1, aim: nil, timeline: timeline, frame: frame, ballVisible: visible)
            return lens.fingerprint()
        }
        var first: [Double: UInt64] = [:]
        for t in times { first[t] = print(at: t) }                     // forward
        var mismatches = 0
        for t in times.reversed() where print(at: t) != first[t] { mismatches += 1 }   // backward
        for t in [times[5], times[1], times[8], times[0], times[6], times[3], times[2], times[7], times[4]] {
            _ = print(at: d * 0.37)                                    // jump somewhere unrelated first
            if print(at: t) != first[t] { mismatches += 1 }            // then back to a known time
        }
        // Different times should look different (guards against a fingerprint that ignores the clock).
        let distinct = Set(first.values).count
        var monotone = true
        var prev = 2.0
        for i in 0...400 { let b = LensLayer.trailBrightness(age: Double(i) * 0.01); if b > prev + 1e-12 { monotone = false }; prev = b }
        NSLog("LENS-SELFTEST scrub mismatches=%d distinctStates=%d/%d fadeMonotone=%@ floor=%.2f bloom=%@ -> %@",
              mismatches, distinct, times.count, monotone ? "yes" : "NO", LensLayer.trailBrightness(age: 99),
              lens.bloomActive ? "on" : "off", (mismatches == 0 && monotone && distinct > 4) ? "PASS" : "FAIL")
    }
}
