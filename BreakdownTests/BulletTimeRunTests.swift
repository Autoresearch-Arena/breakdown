// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Bullet time's run, rationing, camera and drawing (plans/23-Nov-2026-bullet-time-plan.md, version 0.7.7):
//          BulletTimeBudget's rules (rare kinds always, one big cut per rack after a gap, a hard break only when it is
//          the session's hardest by a margin and never on the first free-play break, the computer's shots rare kinds
//          only); BulletTime's beat driven frame by frame with a hand-made moment (the cap and the rate curve, one
//          freeze per play-through, the hold counted only while playing, every way it ends early, uneven frames not
//          read as a jump, a clock that arrives past the contact never freezing, the cue's life); BulletTimeCamera's
//          pure pieces (the weights, the orbit's distance, height, turn and clearances, Reduce Motion leaving the shot
//          alone); and LensLayer's second owner of the contact drawing (outside the Lens root, shown with the Lens off,
//          the clock fingerprint untouched).
// SRP/DRY check: Pass - checks only. Recordings come from TestShots; the LensLayer set-up is SelfCheckTests'
//          testLensScrubIsExact's; the rules are the app's, not restated.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import CoreGraphics
import RealityKit
import XCTest

/// Records the freeze's effects in place of the haptic and the announcement.
@MainActor
private final class EffectsRecorder {
    var calls: [BulletMoment] = []
}

@MainActor
final class BulletTimeRunTests: XCTestCase {
    private let dt = 1.0 / 120.0

    private func moment(_ kind: BulletKind, time: Double = 0.5, speed: Double = 2) -> BulletMoment {
        BulletMoment(kind: kind, event: 0, time: time, striker: 0, object: 1, incomingSpeed: speed)
    }

    // MARK: Budget

    func testRareKindsFreezeEveryTime() {
        var b = BulletTimeBudget()
        for kind in [BulletKind.jumpHit, .curveHit, .kiss, .kiss, .jumpHit] {
            b.noteShot()
            XCTAssertTrue(b.shouldPlay(moment(kind), computerShot: false, freePlay: true, freePlayBreaks: 3), "\(kind)")
        }
    }

    func testABigCutOncePerRackAfterTheGap() {
        var b = BulletTimeBudget()
        b.noteShot()
        XCTAssertTrue(b.shouldPlay(moment(.bigCut), computerShot: false, freePlay: true, freePlayBreaks: 3))
        // The same rack: never again, however long after.
        for _ in 0..<6 { b.noteShot() }
        XCTAssertFalse(b.shouldPlay(moment(.bigCut), computerShot: false, freePlay: true, freePlayBreaks: 3))
        // A new rack, right after a freeze of another kind: refused inside the gap, allowed once it has passed.
        b.startRack()
        b.noteShot()
        XCTAssertTrue(b.shouldPlay(moment(.kiss), computerShot: false, freePlay: true, freePlayBreaks: 3))
        for gap in 1..<BulletTimeBudget.cutGap {
            b.noteShot()
            XCTAssertFalse(b.shouldPlay(moment(.bigCut), computerShot: false, freePlay: true, freePlayBreaks: 3),
                           "a big cut \(gap) shots after the last freeze")
        }
        b.noteShot()
        XCTAssertTrue(b.shouldPlay(moment(.bigCut), computerShot: false, freePlay: true, freePlayBreaks: 3))
    }

    func testAHardBreakMustBeatTheHardest() {
        var b = BulletTimeBudget()
        b.noteShot()
        // The session's first free-play break never freezes.
        XCTAssertFalse(b.shouldPlay(moment(.hardBreak, speed: 14), computerShot: false, freePlay: true, freePlayBreaks: 1))
        b.noteShot()
        XCTAssertTrue(b.shouldPlay(moment(.hardBreak, speed: 14), computerShot: false, freePlay: true, freePlayBreaks: 2))
        b.noteShot()
        XCTAssertFalse(b.shouldPlay(moment(.hardBreak, speed: 14.2), computerShot: false, freePlay: true,
                                    freePlayBreaks: 3), "not 0.3 m/s harder than the hardest frozen break")
        b.noteShot()
        XCTAssertTrue(b.shouldPlay(moment(.hardBreak, speed: 14.4), computerShot: false, freePlay: true, freePlayBreaks: 4))
        // Outside free play the first-break rule does not apply (a match's own breaks).
        var m = BulletTimeBudget()
        m.noteShot()
        XCTAssertTrue(m.shouldPlay(moment(.hardBreak, speed: 14), computerShot: false, freePlay: false, freePlayBreaks: 0))
    }

    func testTheComputersShotsFreezeOnlyForRareKinds() {
        var b = BulletTimeBudget()
        b.noteShot()
        XCTAssertFalse(b.shouldPlay(moment(.hardBreak, speed: 15), computerShot: true, freePlay: false, freePlayBreaks: 0))
        b.noteShot()
        XCTAssertFalse(b.shouldPlay(moment(.bigCut), computerShot: true, freePlay: false, freePlayBreaks: 0))
        b.noteShot()
        XCTAssertTrue(b.shouldPlay(moment(.kiss), computerShot: true, freePlay: false, freePlayBreaks: 0))
    }

    // MARK: The run

    /// A run armed on a kiss at clock 0.5 for version 1, with its effects recorded.
    private func armed() -> (run: BulletTime, effects: EffectsRecorder, moment: BulletMoment) {
        let run = BulletTime()
        let rec = EffectsRecorder()
        run.effects = { rec.calls.append($0) }
        let m = moment(.kiss)
        run.arm(moment: m, version: 1)
        return (run, rec, m)
    }

    @discardableResult
    private func frame(_ run: BulletTime, clock: Double, playing: Bool = true, dt: Double? = nil, version: Int = 1,
                       allowed: Bool = true) -> Bool {
        run.frame(dt ?? self.dt, clock: clock, playing: playing, rate: 1, version: version, allowed: allowed)
    }

    /// The freeze's length on this machine (Reduce Motion is read when it begins).
    private var holdLength: Double { BulletTime.holdLength(reduceMotion: TableCamera.reduceMotion) }

    /// Runs the hold to its end at the contact, playing; returns the real seconds it held.
    @discardableResult
    private func holdThrough(_ run: BulletTime, clock: Double = 0.5) -> Double {
        var held = 0.0
        var calls = 0
        while calls < 100_000 {
            calls += 1
            held += dt
            if !frame(run, clock: clock) { break }
        }
        return held
    }

    func testTheCapAndTheRateCurve() {
        let (run, _, m) = armed()
        XCTAssertEqual(run.cap(clock: 0.2, version: 1), m.time)
        XCTAssertEqual(run.cap(clock: 0.2, version: 2), .infinity, "another recording is never capped")
        XCTAssertEqual(run.rateFactor(at: 0.0), 1, accuracy: 1e-12)
        XCTAssertEqual(run.rateFactor(at: m.time), BulletTime.slowest, accuracy: 1e-12)
        XCTAssertLessThan(run.rateFactor(at: m.time - 0.06), 1)
        XCTAssertTrue(frame(run, clock: m.time), "the freeze did not begin on the contact")
        holdThrough(run)
        XCTAssertEqual(run.cap(clock: m.time, version: 1), .infinity, "capped while letting go")
        XCTAssertEqual(run.rateFactor(at: m.time + BulletTime.releaseClock), 1, accuracy: 1e-12)
        XCTAssertLessThan(run.rateFactor(at: m.time + 0.05), 1)
        // Past the contact while armed: no cap.
        let (later, _, _) = armed()
        XCTAssertEqual(later.cap(clock: 0.6, version: 1), .infinity)
    }

    func testTheFreezeBeginsOnceAndHoldsWhilePlaying() {
        let (run, rec, m) = armed()
        XCTAssertFalse(frame(run, clock: 0.45))
        XCTAssertNil(run.shown)
        XCTAssertTrue(frame(run, clock: m.time))
        XCTAssertEqual(rec.calls, [m], "the effects did not run exactly once")
        XCTAssertEqual(run.shown, m)
        XCTAssertNotNil(run.statusWords)
        // Paused: the counter does not run, and the clock stays held.
        for _ in 0..<500 { XCTAssertTrue(frame(run, clock: m.time, playing: false)) }
        // Playing again: it holds for the hold length of summed dt, then lets go.
        let held = holdThrough(run)
        XCTAssertGreaterThanOrEqual(held, holdLength - 1e-9, "let go after \(held) s")
        XCTAssertLessThan(held, holdLength + dt + 1e-9, "held for \(held) s")
        XCTAssertNil(run.shown)
        XCTAssertNil(run.statusWords)
        XCTAssertEqual(rec.calls.count, 1)
    }

    func testEveryWayItEndsEarly() {
        // Backwards.
        do {
            let (run, rec, m) = armed()
            frame(run, clock: m.time)
            XCTAssertFalse(frame(run, clock: 0.3))
            XCTAssertNil(run.shown); XCTAssertNil(run.cue)
            // A second play through the same clock never freezes again.
            for c in stride(from: 0.30, through: 0.6, by: 0.005) { XCTAssertFalse(frame(run, clock: c)) }
            XCTAssertEqual(rec.calls.count, 1)
        }
        // Forwards past the allowance, while armed.
        do {
            let (run, rec, m) = armed()
            frame(run, clock: 0.0)
            let past = max(1, 1.0) * 1.5 / 20 + 1e-4
            XCTAssertFalse(frame(run, clock: past + 0.01))
            XCTAssertFalse(frame(run, clock: m.time))
            XCTAssertEqual(rec.calls.count, 0, "a jump forward still froze")
            XCTAssertEqual(run.phase, .done)
        }
        // Another recording.
        do {
            let (run, _, m) = armed()
            frame(run, clock: m.time)
            XCTAssertFalse(frame(run, clock: m.time, version: 2))
            XCTAssertNil(run.shown); XCTAssertNil(run.cue)
        }
        // The gate closing (the Lens asked for, Ride, the option...).
        do {
            let (run, _, m) = armed()
            frame(run, clock: m.time)
            XCTAssertFalse(frame(run, clock: m.time, allowed: false))
            XCTAssertNil(run.shown); XCTAssertNil(run.cue)
        }
        // cancel() (a scrub).
        do {
            let (run, _, m) = armed()
            frame(run, clock: m.time)
            run.cancel()
            XCTAssertFalse(frame(run, clock: m.time))
            XCTAssertNil(run.shown); XCTAssertNil(run.cue)
        }
    }

    func testUnevenFramesAreNotAJump() {
        let (run, rec, m) = armed()
        frame(run, clock: 0.30)
        // One clamped long frame's step (a twentieth of a second of clock), then a short frame.
        XCTAssertFalse(frame(run, clock: 0.35, dt: 1.0 / 20.0))
        XCTAssertFalse(frame(run, clock: 0.36, dt: dt))
        XCTAssertEqual(run.phase, .armed)
        XCTAssertEqual(run.cap(clock: 0.36, version: 1), m.time)
        for c in [0.40, 0.45] { frame(run, clock: c) }
        XCTAssertTrue(frame(run, clock: m.time))
        XCTAssertEqual(rec.calls.count, 1)
    }

    func testAClockThatArrivesPastTheContactNeverFreezes() {
        let (run, rec, _) = armed()
        frame(run, clock: 0.45)
        // 0.07 of clock: inside the 0.0751 allowance at rate 1, so not a jump, but past the contact.
        XCTAssertFalse(frame(run, clock: 0.52))
        XCTAssertEqual(rec.calls.count, 0)
        XCTAssertEqual(run.phase, .done)
        XCTAssertNil(run.cue)
    }

    func testAPauseDuringTheLetGoEndsIt() {
        let (run, _, m) = armed()
        frame(run, clock: m.time)
        holdThrough(run)
        XCTAssertNotNil(run.cue, "no cue while letting go")
        var waited = 0.0
        while run.cue != nil && waited < 10 {
            frame(run, clock: m.time, playing: false)
            waited += dt
        }
        XCTAssertNil(run.cue)
        XCTAssertGreaterThanOrEqual(waited, BulletTime.cameraBackSeconds - dt)
        XCTAssertLessThan(waited, BulletTime.cameraBackSeconds + 2 * dt)
    }

    func testTheCuesLife() {
        let (run, _, m) = armed()
        frame(run, clock: 0.45)
        XCTAssertNil(run.cue, "a cue before the freeze")
        frame(run, clock: m.time)
        var lastHold = -1.0
        while let cue = run.cue, cue.release == 0, frame(run, clock: m.time) {
            XCTAssertGreaterThanOrEqual(cue.hold, lastHold)
            XCTAssertLessThanOrEqual(cue.hold, 1)
            lastHold = cue.hold
        }
        // Letting go: hold 1, release climbing to 1 while the clock plays on at a playback pace.
        var clock = m.time
        var lastRelease = -1.0
        var frames = 0
        while let cue = run.cue, frames < 10_000 {
            XCTAssertEqual(cue.hold, 1)
            XCTAssertGreaterThanOrEqual(cue.release, lastRelease)
            XCTAssertLessThanOrEqual(cue.release, 1)
            lastRelease = cue.release
            clock += dt * 0.5
            frame(run, clock: clock)
            frames += 1
        }
        XCTAssertNil(run.cue)
        XCTAssertEqual(lastRelease, 1, accuracy: 0.05)
        XCTAssertEqual(run.phase, .done)
    }

    func testGlassOnlyOnTheTwoTouchingBalls() {
        let cue = BulletCue(moment: moment(.kiss), hold: 1, release: 0, reduceMotion: false)
        XCTAssertEqual(cue.glass(for: 0), 0.6, accuracy: 1e-6)
        XCTAssertEqual(cue.glass(for: 1), 0.6, accuracy: 1e-6)
        XCTAssertEqual(cue.glass(for: 2), 0)
        XCTAssertEqual(BulletCue(moment: moment(.kiss), hold: 1, release: 1, reduceMotion: false).glass(for: 0), 0)
        XCTAssertTrue(cue.drawing)
        XCTAssertFalse(BulletCue(moment: moment(.kiss), hold: 1, release: 0.6, reduceMotion: false).drawing)
    }

    // MARK: Camera

    func testTheWeights() {
        XCTAssertEqual(BulletTimeCamera.weights(hold: 0, release: 0).blend, 0)
        for h in stride(from: 0.2, through: 1.0, by: 0.05) {
            XCTAssertEqual(BulletTimeCamera.weights(hold: h, release: 0).blend, 1, accuracy: 1e-12, "hold \(h)")
        }
        XCTAssertEqual(BulletTimeCamera.weights(hold: 1, release: 1).blend, 0)
        for h in stride(from: 0.0, through: 0.2, by: 0.05) {
            XCTAssertEqual(BulletTimeCamera.weights(hold: h, release: 0).swing, 0, accuracy: 1e-12, "hold \(h)")
        }
        for h in stride(from: 0.8, through: 1.0, by: 0.05) {
            XCTAssertEqual(BulletTimeCamera.weights(hold: h, release: 0).swing, 1, accuracy: 1e-9, "hold \(h)")
        }
    }

    /// `v` turned counter-clockwise by `degrees`.
    private func turned(_ v: Vec2, _ degrees: Double) -> Vec2 {
        let a = degrees * Double.pi / 180
        return Vec2(v.x * cos(a) - v.y * sin(a), v.x * sin(a) + v.y * cos(a))
    }

    /// Signed angle from a to b, degrees.
    private func angle(_ a: Vec2, _ b: Vec2) -> Double {
        atan2(a.x * b.y - a.y * b.x, a.dot(b)) * 180 / Double.pi
    }

    func testTheOrbitOnAnOpenTable() {
        let table = TestShots.straightPot().table
        let R = table.ballRadius
        let centre = Vec2(table.length / 2, table.width / 2)
        let b1 = Vec2(0, 1)
        let b0 = turned(b1, -BulletTimeCamera.turnDegrees)
        var lastAngle = 0.0
        for i in 0...100 {
            let s = Double(i) / 100
            let p = BulletTimeCamera.orbitPlan(centre: centre, b0: b0, b1: b1, swing: s, radius: R, table: table)
            XCTAssertEqual((p.eye - centre).length, 13 * R, accuracy: 1e-9, "swing \(s)")
            XCTAssertGreaterThanOrEqual(p.height, 2 * R, "below the ball tops at swing \(s)")
            let a = angle(b0, p.eye - centre)
            XCTAssertGreaterThanOrEqual(a, lastAngle - 1e-9, "the bearing turned back at swing \(s)")
            lastAngle = a
        }
        let start = BulletTimeCamera.orbitPlan(centre: centre, b0: b0, b1: b1, swing: 0, radius: R, table: table)
        let end = BulletTimeCamera.orbitPlan(centre: centre, b0: b0, b1: b1, swing: 1, radius: R, table: table)
        XCTAssertEqual(start.height, 2.2 * R, accuracy: 1e-9)
        XCTAssertEqual(end.height, 7 * R, accuracy: 1e-9)
        XCTAssertEqual(angle(start.eye - centre, end.eye - centre), BulletTimeCamera.turnDegrees, accuracy: 1e-6)
    }

    func testTheOrbitClearsACushion() {
        let table = TestShots.straightPot().table
        let R = table.ballRadius
        // A contact 3 cm from the top cushion, the swing ending out over it.
        let centre = Vec2(table.length / 2, table.width - 0.03)
        let b1 = Vec2(0, 1)
        let b0 = turned(b1, -BulletTimeCamera.turnDegrees)
        var last: Double?
        for i in 0...100 {
            let s = Double(i) / 100
            let p = BulletTimeCamera.orbitPlan(centre: centre, b0: b0, b1: b1, swing: s, radius: R, table: table)
            let outside = max(0, -p.eye.x, p.eye.x - table.length, -p.eye.y, p.eye.y - table.width)
            if outside >= 0.05 {
                XCTAssertGreaterThanOrEqual(p.height, BulletTimeCamera.railClear - 1e-12,
                                            "\(outside) m outside the cloth at \(p.height) m high, swing \(s)")
            }
            if let last {
                XCTAssertLessThan(abs(p.height - last), 0.025, "the eye jumped at swing \(s)")
            }
            last = p.height
        }
    }

    func testTheOrbitRisesOverAPost() {
        var table = TestShots.straightPot().table
        let R = table.ballRadius
        let centre = Vec2(table.length / 2, table.width / 2)
        let b1 = Vec2(0, 1)
        let b0 = turned(b1, -BulletTimeCamera.turnDegrees)
        // A bumper-style post standing on the swing's path, halfway round.
        let halfway = BulletTimeCamera.orbitPlan(centre: centre, b0: b0, b1: b1, swing: 0.5, radius: R, table: table)
        table.posts = [Post(center: halfway.eye, radius: 0.02, height: 0.05)]
        var inside = 0
        for i in 0...200 {
            let s = Double(i) / 200
            let p = BulletTimeCamera.orbitPlan(centre: centre, b0: b0, b1: b1, swing: s, radius: R, table: table)
            guard (p.eye - halfway.eye).length <= 0.02 else { continue }
            inside += 1
            XCTAssertGreaterThanOrEqual(p.height, 0.05 + 2 * R - 1e-12, "inside the post at \(p.height) m, swing \(s)")
        }
        XCTAssertGreaterThan(inside, 0, "the swing never passed through the post")
    }

    func testReduceMotionLeavesTheShotAlone() {
        let tl = TestShots.straightPot()
        let frame = TableFrame(tl.table)
        guard let i = ShotMoments(timeline: tl, captions: []).firstContact(of: 0),
              let g = ContactGeometry.at(tl.events[i]) else { return XCTFail("the straight pot has no first contact") }
        let m = BulletMoment(kind: .bigCut, event: i, time: tl.events[i].time, striker: g.striker, object: g.object,
                             incomingSpeed: g.incoming.length)
        let size = CGSize(width: 402, height: 874)
        let free = FramingRect(left: 0, top: 120, right: 402, bottom: 700)
        let given = CameraShot(position: SIMD3<Float>(1.27, 2.2, 1.6), target: SIMD3<Float>(1.27, 0, 0.6), fov: 40,
                               near: ShotCamera.overheadNear)
        let camera = BulletTimeCamera()
        for hold in [0.0, 0.3, 1.0] {
            for release in [0.0, 0.5, 1.0] {
                let cue = BulletCue(moment: m, hold: hold, release: release, reduceMotion: false)
                camera.set(cue: cue, timeline: tl, frame: frame)
                let out = camera.override(given, free: free, size: size, reduceMotion: true)
                XCTAssertEqual(out.position, given.position, "hold \(hold) release \(release)")
                XCTAssertEqual(out.target, given.target, "hold \(hold) release \(release)")
                XCTAssertEqual(out.fov, given.fov)
                XCTAssertEqual(out.near, given.near)
                XCTAssertFalse(camera.flying)
            }
        }
        // Without Reduce Motion, mid-freeze, the orbit has the view.
        let moving = BulletTimeCamera()
        moving.set(cue: BulletCue(moment: m, hold: 0.5, release: 0, reduceMotion: false), timeline: tl, frame: frame)
        let out = moving.override(given, free: free, size: size, reduceMotion: false)
        XCTAssertTrue(moving.flying)
        XCTAssertNotEqual(out.position, given.position)
    }

    // MARK: The drawing's second owner

    func testTheContactDrawingShowsWithTheLensOff() {
        let tl = TestShots.straightPot()
        let frame = TableFrame(tl.table)
        let lens = LensLayer()
        lens.buildStatic(ballCount: tl.ballCount, frame: frame, table: tl.table)
        lens.rebuild(timeline: tl, frame: frame)
        // heldRoot is not root and does not hang under it.
        XCTAssertFalse(lens.heldRoot === lens.root)
        var parent = lens.heldRoot.parent
        while let p = parent {
            XCTAssertFalse(p === lens.root, "heldRoot hangs under the Lens root")
            parent = p.parent
        }
        guard let i = ShotMoments(timeline: tl, captions: []).firstContact(of: 0) else {
            return XCTFail("the straight pot has no first contact")
        }
        let t = tl.events[i].time
        let visible = [Bool](repeating: true, count: tl.ballCount)
        lens.apply(time: t, melt: 0, aim: nil, timeline: tl, frame: frame, ballVisible: visible)
        XCTAssertFalse(lens.heldRoot.children.contains { $0.isEnabled }, "the drawing shows with nothing owning it")
        let plain = lens.fingerprint()
        lens.bulletEvent = i
        lens.bulletLift = frame.ballRadius
        lens.apply(time: t, melt: 0, aim: nil, timeline: tl, frame: frame, ballVisible: visible)
        XCTAssertTrue(lens.heldRoot.children.contains { $0.isEnabled }, "the frozen hit's drawing did not show")
        XCTAssertEqual(lens.fingerprint(), plain, "the clock fingerprint changed with the drawing")
    }
}
