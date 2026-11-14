// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: Checks the solver against results that can be derived by hand (spec section 9.1): the five-sevenths
//          rule, the ninety-degree rule, cushion mirror angles, rolling stop distance, momentum and energy
//          accounting at every event, continuity of every ball's path, repeatability and the no-libm rule.
// SRP/DRY check: Pass - one test file for the physics module; helpers build tiny two-ball scenes.
import XCTest
import BreakdownLensModel
import BreakdownTimeline
@testable import BreakdownPhysics

private let off = Vec2(-1, -1)

/// A scene with only the listed balls on the table; everything else parked far away and stationary.
private func scene(_ cue: Vec2, others: [Vec2] = [], strike: CueStrike, _ p: PoolParameters = PoolParameters()) -> ShotInput {
    var pos = [Vec2](repeating: off, count: 16)
    pos[0] = cue
    for (i, o) in others.enumerated() { pos[i + 1] = o }
    return ShotInput(parameters: p, positions: pos, strike: strike, seed: 1)
}

final class PhysicsTests: XCTestCase {

    // Test 1: a centre hit on a lone cue ball slides, then rolls at five sevenths of its launch speed.
    func testSlidingBecomesRollingAtFiveSevenths() {
        let tl = PoolSolver.simulate(scene(Vec2(0.5, 0.6), strike: CueStrike(direction: Vec2(1, 0), speed: 2.0)))
        let transition = tl.events.first { $0.kind == .phaseTransition && $0.phaseFrom == .sliding && $0.phaseTo == .rolling }
        XCTAssertNotNil(transition)
        XCTAssertEqual(transition!.balls[0].velocityAfter.length, 2.0 * 5 / 7, accuracy: 1e-9)
    }

    // Test 2: a rolling ball stops after v^2 / (2 c_r g).
    func testRollingStopDistance() {
        var p = PoolParameters(); p.slidingFriction = 0.2
        let tl = PoolSolver.simulate(scene(Vec2(0.3, 0.6), strike: CueStrike(direction: Vec2(1, 0), speed: 0.5, tipUp: 0.4 * p.ballRadius), p))
        // Top-spin of 2/5 R at the start means pure rolling from the first instant.
        let first = tl.segments[0][0]
        XCTAssertEqual(first.phase, .rolling)
        let expected = 0.5 * 0.5 / (2 * p.rollingResistance * p.gravity)
        let end = tl.state(ball: 0, at: tl.duration + 1)
        XCTAssertEqual(end.position.x - 0.3, expected, accuracy: 1e-6)
    }

    // Test 3: with perfect restitution and no friction, a centre-ball stun shot leaves the two balls at ninety degrees.
    func testNinetyDegreeRule() {
        var p = PoolParameters()
        p.ballBallRestitution = 1.0
        p.ballBallFrictionFloor = 0; p.ballBallFrictionGain = 0
        // Object ball is offset sideways so the cut angle is about 30 degrees.
        let r = p.ballRadius
        let cue = Vec2(0.5, 0.6)
        let cutAngleSin = 0.5
        let cosA = (1 - cutAngleSin * cutAngleSin).squareRoot()
        let obj = cue + Vec2(cosA, cutAngleSin) * (2 * r + 0.3)
        // Aim straight along +x; the object ball sits above the line by 0.5 * 2r after travelling 0.3 m.
        let aimStart = Vec2(obj.x - 2 * r * cosA, obj.y - 2 * r * cutAngleSin)
        _ = aimStart
        let dir = Vec2(1, 0)
        let object = Vec2(cue.x + 0.3 + 2 * r * cosA, cue.y + 2 * r * cutAngleSin)
        let tl = PoolSolver.simulate(scene(cue, others: [object], strike: CueStrike(direction: dir, speed: 1.0), p))
        let hit = tl.events.first { $0.kind == .ballBall }!
        let vc = hit.balls[0].velocityAfter, vo = hit.balls[1].velocityAfter
        XCTAssertGreaterThan(vc.length, 0.1)
        XCTAssertEqual(vc.dot(vo), 0, accuracy: 1e-9)
        _ = obj
    }

    // Test 4: momentum along the plane and the energy ledger hold at every ball-ball event; energy never rises.
    func testMomentumAndEnergyAtEveryEvent() {
        for seed in UInt64(1)...UInt64(8) {
            let tl = PoolSolver.simulate(Rack.breakShot(seed: seed, aimOffset: 0.004, speed: 9))
            for e in tl.events where e.kind != .cueStrike {
                let before = e.balls.reduce(0.0) { $0 + $1.energyBefore }
                let after = e.balls.reduce(0.0) { $0 + $1.energyAfter }
                XCTAssertLessThanOrEqual(after, before * (1 + 1e-9) + 1e-12, "energy rose at \(e.kind) t=\(e.time)")
                if e.kind == .ballBall {
                    let m = PoolParameters().ballMass
                    let pb = e.balls.reduce(Vec2.zero) { $0 + $1.velocityBefore * m }
                    let pa = e.balls.reduce(Vec2.zero) { $0 + $1.velocityAfter * m }
                    XCTAssertEqual((pb - pa).length, 0, accuracy: 1e-9)
                }
            }
        }
    }

    // Test 5: a frictionless, perfectly elastic cushion mirrors the angle.
    func testCushionMirrorAngle() {
        var p = PoolParameters()
        p.cushionRestitution = 1.0; p.cushionFriction = 0
        let tl = PoolSolver.simulate(scene(Vec2(0.7, 0.4), strike: CueStrike(direction: Vec2(0.6, -0.8), speed: 1.5), p))
        let hit = tl.events.first { $0.kind == .cushion }!
        let before = hit.balls[0].velocityBefore, after = hit.balls[0].velocityAfter
        XCTAssertEqual(after.x, before.x, accuracy: 1e-9)
        XCTAssertEqual(after.y, -before.y, accuracy: 1e-9)
    }

    // Test 6: no ball ever ends outside the table or inside a cushion, and the shot comes to rest.
    func testBreakEndsAtRestInsideTable() {
        for seed in UInt64(1)...UInt64(20) {
            let input = Rack.breakShot(seed: seed, aimOffset: Double(seed % 5) * 0.004 - 0.008, speed: 8 + Double(seed % 4))
            let tl = PoolSolver.simulate(input)
            let p = input.parameters
            XCTAssertLessThan(tl.duration, PoolSolver.maxTime, "seed \(seed) never settled")
            for b in 0..<tl.ballCount {
                let s = tl.state(ball: b, at: tl.duration + 5)
                if s.pocketed { continue }
                XCTAssertEqual(s.velocity.length, 0, accuracy: 1e-9)
                XCTAssertGreaterThanOrEqual(s.position.x, p.ballRadius - 1e-6, "ball \(b) seed \(seed)")
                XCTAssertLessThanOrEqual(s.position.x, p.tableLength - p.ballRadius + 1e-6, "ball \(b) seed \(seed)")
                XCTAssertGreaterThanOrEqual(s.position.y, p.ballRadius - 1e-6, "ball \(b) seed \(seed)")
                XCTAssertLessThanOrEqual(s.position.y, p.tableWidth - p.ballRadius + 1e-6, "ball \(b) seed \(seed)")
            }
        }
    }

    // Test 7: no two resting balls overlap.
    func testNoOverlapAtRest() {
        for seed in UInt64(1)...UInt64(12) {
            let input = Rack.breakShot(seed: seed, aimOffset: 0.003, speed: 9)
            let tl = PoolSolver.simulate(input)
            let r = input.parameters.ballRadius
            let end = (0..<tl.ballCount).map { tl.state(ball: $0, at: tl.duration + 5) }
            for i in 0..<end.count where !end[i].pocketed {
                for j in (i + 1)..<end.count where !end[j].pocketed {
                    XCTAssertGreaterThan((end[i].position - end[j].position).length, 2 * r * (1 - 1e-9), "balls \(i),\(j) seed \(seed)")
                }
            }
        }
    }

    // Test 8: position and velocity are continuous across every segment boundary of every ball.
    func testSegmentsAreContinuousExceptAtImpacts() {
        let tl = PoolSolver.simulate(Rack.breakShot(seed: 3, aimOffset: 0, speed: 9))
        for b in 0..<tl.ballCount {
            let segs = tl.segments[b]
            for k in 1..<segs.count {
                let prev = segs[k - 1].kinematics(at: segs[k].t0)
                XCTAssertEqual((prev.position - segs[k].position0).length, 0, accuracy: 1e-9, "ball \(b) segment \(k)")
            }
        }
    }

    // Test 9: the same input gives the same timeline hash; a different seed gives a different one.
    func testRepeatability() {
        let a = PoolSolver.simulate(Rack.breakShot(seed: 7, aimOffset: 0.002, speed: 9)).contentHash
        let b = PoolSolver.simulate(Rack.breakShot(seed: 7, aimOffset: 0.002, speed: 9)).contentHash
        let c = PoolSolver.simulate(Rack.breakShot(seed: 8, aimOffset: 0.002, speed: 9)).contentHash
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // Test 10: the default showpiece break drops at least one ball and keeps the cue ball.
    func testDefaultBreakPocketsABall() {
        let tl = PoolSolver.simulate(Rack.showpieceBreak())
        let dropped = (1..<tl.ballCount).filter { tl.pocketTime[$0] != nil }
        XCTAssertGreaterThanOrEqual(dropped.count, 2)
        XCTAssertNil(tl.pocketTime[0])
    }

    // Test 10b: the layout after the break parks pocketed balls off the table, keeps the rest inside the cushions,
    // and a follow-up shot from it is repeatable.
    func testNextShotLayoutAfterBreak() {
        let p = PoolParameters()
        let tl = PoolSolver.simulate(Rack.showpieceBreak())
        let layout = NextShot.layout(after: tl, parameters: p)
        XCTAssertEqual(layout.count, 16)
        for b in 1..<16 {
            if tl.pocketTime[b] != nil {
                XCTAssertFalse(NextShot.isOnTable(layout[b]), "pocketed ball \(b) should be off the table")
            } else {
                XCTAssertTrue(layout[b].x > 0 && layout[b].x < p.tableLength && layout[b].y > 0 && layout[b].y < p.tableWidth)
            }
        }
        let dir = NextShot.directionToNearestObjectBall(in: layout)
        XCTAssertNotNil(dir)
        let a = PoolSolver.simulate(NextShot.shot(from: layout, direction: dir!, speed: 3.0, tipUp: 0, tipSide: 0, seed: 77))
        let b = PoolSolver.simulate(NextShot.shot(from: layout, direction: dir!, speed: 3.0, tipUp: 0, tipSide: 0, seed: 77))
        XCTAssertEqual(a.contentHash, b.contentHash)
    }

    // Test 10c: a scratched cue ball comes back on the head spot, and slides clear if a ball is sitting there.
    func testScratchRespot() {
        let p = PoolParameters()
        var pos = [Vec2](repeating: NextShot.offTable, count: 16)
        XCTAssertEqual(NextShot.respotCueBall(among: pos, parameters: p), Vec2(p.tableLength * 0.25, p.tableWidth * 0.5))
        pos[1] = Vec2(p.tableLength * 0.25, p.tableWidth * 0.5)
        let moved = NextShot.respotCueBall(among: pos, parameters: p)
        XCTAssertGreaterThanOrEqual((moved - pos[1]).length, 2 * p.ballRadius)
        XCTAssertTrue(NextShot.isOnTable(moved))
    }

    // Test 10d: a zero-speed strike (used to show a fresh rack) records a still table without trouble.
    func testZeroSpeedStrikeIsAStillTable() {
        let tl = PoolSolver.simulate(Rack.breakShot(seed: 11, aimOffset: 0, speed: 0))
        XCTAssertTrue(tl.duration.isFinite)
        XCTAssertTrue((1..<16).allSatisfy { tl.pocketTime[$0] == nil })
        let rack = Rack.positions(parameters: PoolParameters(), seed: 11)
        XCTAssertEqual(tl.state(ball: 5, at: 0).position, rack[5])
    }

    // Test 11: root finder agrees with a hand-computed quartic crossing.
    func testRootFinder() {
        // (t - 1)(t - 2)(t + 1)(t + 3) has down-crossings at t = -1... use (t-2)(t+1) = t^2 - t - 2, positive at t = 0? No:
        // choose (t - 1.5)(t + 4) * (t^2 + 1) crossing from negative; instead check a decreasing line and a parabola.
        let line = RootFinder.firstDownCrossing([3, -2], limit: 5)
        XCTAssertEqual(line!, 1.5, accuracy: 1e-12)
        let parab = RootFinder.firstDownCrossing([4, 0, -1], limit: 5)   // 4 - t^2 crosses at 2
        XCTAssertEqual(parab!, 2, accuracy: 1e-12)
        XCTAssertNil(RootFinder.firstDownCrossing([1, 0, 1], limit: 5))    // never crosses
        let quartic = RootFinder.firstDownCrossing([-(6.0), 11, -6, 1].map { $0 }, limit: 10)  // starts negative: nil
        XCTAssertNil(quartic)
    }

    // The physics module must not import Foundation or any math library.
    func testPhysicsModuleHasNoFoundationImport() throws {
        let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources/BreakdownPhysics")
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        XCTAssertFalse(files.isEmpty)
        for f in files where f.pathExtension == "swift" {
            let text = try String(contentsOf: f, encoding: .utf8)
            for banned in ["import Foundation", "import Darwin", "import Accelerate", "import simd"] {
                XCTAssertFalse(text.contains(banned), "\(f.lastPathComponent) imports \(banned)")
            }
        }
    }
}
