// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The app's launch-flag self-checks as unit tests that launch nothing. Each test calls the same check the flag
//          runs and asserts on its result instead of reading the console:
//          - Lens scrub (-lensSelfTest): LensScrubCheck.run on a Lens layer built for a solved shot, exactly as
//            TableScene builds its own (buildStatic, then rebuild). No visit may differ, the pictures must change with
//            the clock, the trail fade must only dim.
//          - Ride (-rideSelfTest): ShotCamera.selfTest after loading a solved shot, at the phone size the flag uses and
//            at a sideways and a tablet size. Scrub-exact, no snap turn, the eye never below two ball radii, never up.
//          - Retry (-retryDemo): the same shot from the same start with the same settings must record the same motion
//            (ShotAttempt.motionHash), ShowpieceModel.sameSettings must agree, and ShotComparison must say "Same shot,
//            same result"; a change of spin must change the motion and the comparison. For a shot and for the break.
//          - Aim script (-aimScript): the script logs which ball the aim guide says the cue ball will hit, and where the
//            cue ball ends up after a scratch. Its drags need a screen, so the test checks what those logs check: the
//            guide (AimGeometry.firstContact) names the ball the solver really hits first, for every visible ball after
//            a break and both cut directions; and a cue ball sent into a pocket is put back on the table for the next
//            shot (NextShot.layout(after:)).
// SRP/DRY check: Pass - no check logic is repeated here: LensScrubCheck, ShotCamera.selfTest, ShotAttempt.motionHash,
//          ShowpieceModel.sameSettings, ShotComparison.describe and AimGeometry.firstContact are the app's own.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import CoreGraphics
import XCTest

final class SelfCheckTests: XCTestCase {
    // MARK: Lens scrub

    @MainActor
    func testLensScrubIsExact() {
        for (name, tl) in [("break", TestShots.breakShot()), ("straight pot", TestShots.straightPot())] {
            let frame = TableFrame(tl.table)
            let lens = LensLayer()
            lens.buildStatic(ballCount: tl.ballCount, frame: frame, table: tl.table)
            lens.rebuild(timeline: tl, frame: frame)
            let r = LensScrubCheck.run(lens: lens, timeline: tl, frame: frame)
            XCTAssertEqual(r.mismatches, 0, "\(name): a revisited time looked different")
            XCTAssertTrue(r.fadeMonotone, "\(name): a trail got brighter as it aged")
            XCTAssertGreaterThan(r.distinctStates, 4, "\(name): the Lens barely changed with the clock")
            XCTAssertTrue(r.passed, name)
        }
    }

    // MARK: Ride

    @MainActor
    func testRideIsScrubExactAndSmooth() {
        // 402 x 874 is the size -rideSelfTest checks (TableScene); the other two are a phone sideways and a tablet.
        let sizes = [CGSize(width: 402, height: 874), CGSize(width: 874, height: 402), CGSize(width: 1032, height: 1376)]
        for (name, tl) in [("break", TestShots.breakShot()), ("straight pot", TestShots.straightPot())] {
            let camera = ShotCamera()
            camera.load(tl, frame: TableFrame(tl.table))
            XCTAssertTrue(camera.plan.rideable, "\(name): nothing to ride")
            for size in sizes {
                guard let r = camera.selfTest(size: size) else { return XCTFail("\(name): the check did not run") }
                let label = "\(name) at \(size)"
                XCTAssertEqual(r.mismatches, 0, "\(label): the same clock gave a different camera")
                XCTAssertFalse(r.upward, "\(label): the camera looked up")
                XCTAssertLessThan(r.maxTurnPerStep, 4, "\(label): a snap turn at \(r.maxTurnAt) s")
                XCTAssertGreaterThan(r.minEye, 2 * Float(tl.table.ballRadius), "\(label): the eye went into the balls")
                XCTAssertTrue(r.passed, label)
            }
        }
    }

    @MainActor
    func testRideOnAStillTableHasNothingToRideAndPasses() {
        // A re-rack records a still table (a zero-speed strike): the check must say so and pass, not fail.
        let still = TestShots.solve(TestShots.breakInput(speed: 0))
        let camera = ShotCamera()
        camera.load(still, frame: TableFrame(still.table))
        let r = camera.selfTest(size: CGSize(width: 402, height: 874))
        XCTAssertEqual(r?.rideable, false)
        XCTAssertEqual(r?.passed, true)
    }

    // MARK: Retry

    @MainActor
    func testARetryWithTheSameSettingsRecordsTheSameShot() {
        let input = RideDemo.straightPot()
        let s = TrickSettings(aim: atan2(input.strike.direction.y, input.strike.direction.x) * 180 / Double.pi,
                              power: input.strike.speed, tipUp: input.strike.tipUp, tipSide: input.strike.tipSide)
        let first = TestShots.attempt(start: input.positions, timeline: TestShots.shot(from: input.positions, s), s)
        let again = TestShots.attempt(start: input.positions, timeline: TestShots.shot(from: input.positions, s), s)
        XCTAssertTrue(ShowpieceModel.sameSettings(first, again))
        XCTAssertEqual(first.motionHash, again.motionHash, "the same shot played twice moved differently")
        XCTAssertEqual(ShotComparison.describe(RetryComparison.between(first, again), previous: first, current: again),
                       String(localized: "Same shot, same result. The physics is exact, so nothing changes unless you do."))

        // Follow instead of draw: a different shot, and the comparison says what changed.
        var follow = s
        follow.tipUp = -s.tipUp
        let changed = TestShots.attempt(start: input.positions, timeline: TestShots.shot(from: input.positions, follow),
                                        follow)
        XCTAssertFalse(ShowpieceModel.sameSettings(first, changed))
        XCTAssertNotEqual(first.motionHash, changed.motionHash)
        XCTAssertNotEqual(ShotComparison.describe(RetryComparison.between(first, changed), previous: first, current: changed),
                          String(localized: "Same shot, same result. The physics is exact, so nothing changes unless you do."))
    }

    @MainActor
    func testARetriedBreakRecordsTheSameBreak() {
        // Try again on a break re-racks the identical rack (the same seed) and breaks it with the same settings.
        let s = TrickSettings(aim: 0.004, power: 9, tipUp: -0.002, tipSide: 0.001)
        func broken() -> ShotAttempt {
            let input = TestShots.breakInput(seed: 12, aimOffset: s.aim, speed: s.power, tipUp: s.tipUp, tipSide: s.tipSide)
            return TestShots.attempt(start: input.positions, timeline: TestShots.solve(input), s, isBreak: true, breakSeed: 12)
        }
        let first = broken(), again = broken()
        XCTAssertTrue(ShowpieceModel.sameSettings(first, again))
        XCTAssertEqual(first.motionHash, again.motionHash, "the same break played twice moved differently")
    }

    // MARK: Aim script

    func testTheAimGuideNamesTheBallTheSolverHitsFirst() {
        // After a break, the layout the next shot starts from, as the model adopts it.
        let p = TestShots.parameters()
        let layout = NextShot.layout(after: TestShots.breakShot(), parameters: p)
        let cue = layout[0]
        XCTAssertTrue(NextShot.isOnTable(cue))
        var checked = 0
        for b in 1..<layout.count where NextShot.isOnTable(layout[b]) {
            let toBall = layout[b] - cue
            // Only balls the cue ball can see in a straight line, as the script picks them.
            guard AimGeometry.firstContact(layout: layout, from: cue, direction: toBall.normalized,
                                           radius: p.ballRadius)?.ball == b else { continue }
            // The script's thin cut: aim at a point beside the ball, 0.8 of a radius off its centre, either side.
            for side in [-1.0, 1.0] {
                let spot = layout[b] + toBall.normalized.perp * (p.ballRadius * 0.8 * side)
                let dir = (spot - cue).normalized
                guard let guide = AimGeometry.firstContact(layout: layout, from: cue, direction: dir,
                                                           radius: p.ballRadius) else { continue }
                // Centre ball, level cue: the cue ball runs straight until it meets something, as the guide assumes.
                let shot = TestShots.shot(from: layout, TrickSettings(aim: atan2(dir.y, dir.x) * 180 / Double.pi,
                                                                       power: 2, tipUp: 0, tipSide: 0))
                let attempt = TestShots.attempt(start: layout, timeline: shot,
                                                TrickSettings(aim: 0, power: 2, tipUp: 0, tipSide: 0))
                XCTAssertEqual(attempt.firstStruck, guide.ball, "aiming past ball \(b) on side \(side)")
                checked += 1
            }
        }
        XCTAssertGreaterThan(checked, 0, "no visible ball to aim at after the break")
    }

    func testAScratchedCueBallIsPutBackOnTheTable() {
        // The cue ball alone in the middle, sent dead centre into a corner, as the script's "scratch" run does.
        let p = TestShots.parameters()
        var start = [Vec2](repeating: NextShot.offTable, count: 16)
        start[0] = Vec2(p.tableLength * 0.5, p.tableWidth * 0.5)
        let corner = p.pocketCenters[3]
        let dir = (corner - start[0]).normalized
        let tl = TestShots.shot(from: start, TrickSettings(aim: atan2(dir.y, dir.x) * 180 / Double.pi, power: 2.5,
                                                           tipUp: 0, tipSide: 0))
        XCTAssertNotNil(tl.pocketTime[0], "the cue ball did not drop, so this is not a scratch")
        let next = NextShot.layout(after: tl, parameters: p)
        XCTAssertTrue(NextShot.isOnTable(next[0]), "the scratched cue ball was not put back")
    }
}
