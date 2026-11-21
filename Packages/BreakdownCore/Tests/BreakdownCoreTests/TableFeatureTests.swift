// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Checks for the other tables' layout features (posts, pins, bed holes, a table with no edge pockets): a ball
//          driven straight at a post comes back with exactly the post's restitution of its normal speed; a ball through a
//          pin knocks it down once, loses the predicted speed and rolls on; a ball rolling over a bed hole drops in and is
//          recorded as pocket 6 + j; with the pockets off a ball driven into a corner rebounds off both cushions and stays
//          on the table; the features change the parameter hash only when present, and each shot repeats exactly.
// SRP/DRY check: Pass - checked PocketTests and JumpTests (pockets, jaws and the old hashes are covered there); these
//          are the new features only.
import BreakdownLensModel
import BreakdownTimeline
@testable import BreakdownPhysics
import XCTest

final class TableFeatureTests: XCTestCase {
    /// One cue ball plus the fifteen object balls parked off the table, so only the cue ball moves.
    private func lone(_ at: Vec2) -> [Vec2] { [at] + [Vec2](repeating: NextShot.offTable, count: 15) }

    private func shoot(_ p: PoolParameters, from at: Vec2, toward dir: Vec2, speed: Double) -> Timeline {
        PoolSolver.simulate(ShotInput(parameters: p, positions: lone(at), strike: CueStrike(direction: dir, speed: speed), seed: 1))
    }

    func testBallReboundsOffPostByItsRestitution() {
        var p = PoolParameters()
        let W = p.tableWidth
        p.posts = [Post(center: Vec2(1.2, W / 2), radius: 0.02, restitution: 0.7, friction: 0.1)]
        let tl = shoot(p, from: Vec2(0.6, W / 2), toward: Vec2(1, 0), speed: 2.0)
        guard let hit = tl.events.first(where: { $0.kind == .cushion && $0.edge == .post }) else {
            return XCTFail("the ball never met the post")
        }
        XCTAssertEqual(hit.feature, 0)
        let b = hit.balls[0]
        let into = -b.velocityBefore.dot(hit.normal), out = b.velocityAfter.dot(hit.normal)
        XCTAssertGreaterThan(into, 0.5)
        XCTAssertEqual(out, 0.7 * into, accuracy: 1e-9, "normal speed off a post is restitution times the speed into it")
        // Contact exactly one ball radius plus the post radius from the post's centre.
        let centre = tl.state(ball: 0, at: hit.time).position
        XCTAssertEqual((centre - p.posts[0].center).length, p.ballRadius + 0.02, accuracy: 1e-9)
        XCTAssertLessThan(tl.state(ball: 0, at: tl.duration).position.x, 1.2, "the ball should come back off the post")
        XCTAssertEqual(PoolSolver.simulate(ShotInput(parameters: p, positions: lone(Vec2(0.6, W / 2)),
                                                     strike: CueStrike(direction: Vec2(1, 0), speed: 2.0), seed: 1)).contentHash,
                       tl.contentHash)
    }

    func testBallKnocksPinDownOnceAndSlows() {
        var p = PoolParameters()
        let W = p.tableWidth
        p.pins = [Pin(center: Vec2(1.2, W / 2), radius: 0.009, mass: p.ballMass / 10, restitution: 0.8)]
        let tl = shoot(p, from: Vec2(0.6, W / 2), toward: Vec2(1, 0), speed: 2.0)
        let downs = tl.events.filter { $0.kind == .pinDown }
        XCTAssertEqual(downs.count, 1, "a pin goes down once and then plays no further part")
        guard let e = downs.first else { return }
        XCTAssertEqual(e.feature, 0)
        let b = e.balls[0]
        let vin = b.velocityBefore.length, vout = b.velocityAfter.length
        // Head-on: the ball keeps 1 - (1 + e) * m_pin / (m + m_pin) of its speed.
        let keep = 1 - 1.8 * (p.ballMass / 10) / (p.ballMass * 1.1)
        XCTAssertEqual(vout, vin * keep, accuracy: 1e-9)
        XCTAssertLessThan(vout, vin)
        XCTAssertEqual(tl.pinFalls.count, 1)
        XCTAssertEqual(tl.pinFalls.first?.ball, 0)
        XCTAssertEqual(tl.pinDownTime, [e.time])
        XCTAssertFalse(tl.pinIsDown(0, at: e.time - 1e-6))
        XCTAssertTrue(tl.pinIsDown(0, at: e.time))
        XCTAssertGreaterThan(b.velocityAfter.x, 0.5 * b.velocityBefore.x, "the ball carries on through the pin")
    }

    func testBallRollingOverBedHoleDrops() {
        for pocketsOn in [true, false] {
            var p = PoolParameters()
            let W = p.tableWidth
            p.pocketsEnabled = pocketsOn
            p.bedHoles = [BedHole(center: Vec2(1.8, 0.3), radius: 0.04, captureRadius: 0.02),
                          BedHole(center: Vec2(1.5, W / 2), radius: 0.04, captureRadius: 0.02)]
            let tl = shoot(p, from: Vec2(0.6, W / 2), toward: Vec2(1, 0), speed: 1.5)
            XCTAssertNotNil(tl.pocketTime[0], "the ball should drop into the bed hole (pockets \(pocketsOn))")
            XCTAssertEqual(tl.events.last { $0.kind == .pocket }?.pocket, TableSpec.edgePocketCount + 1)
            XCTAssertEqual(tl.table.holeCenter(pocket: TableSpec.edgePocketCount + 1), Vec2(1.5, W / 2))
            XCTAssertEqual(tl.table.pockets.count, pocketsOn ? 6 : 0)
        }
    }

    func testWithPocketsOffACornerShotRebounds() {
        var p = PoolParameters()
        p.pocketsEnabled = false
        let inward = Vec2(1, 1).normalized
        let tl = shoot(p, from: Vec2(0, 0) + inward * 0.45, toward: inward * -1, speed: 1.4)
        XCTAssertNil(tl.pocketTime[0], "there is no pocket to fall into")
        XCTAssertTrue(tl.table.jaws.isEmpty)
        let rails = tl.events.filter { $0.kind == .cushion && $0.balls.first?.ball == 0 }
        XCTAssertGreaterThanOrEqual(rails.count, 2, "the ball should meet both cushions of the corner")
        XCTAssertTrue(rails.allSatisfy { $0.edge == .rail })
        let end = tl.state(ball: 0, at: tl.duration).position
        let r = p.ballRadius
        XCTAssertTrue(end.x >= r - 1e-9 && end.y >= r - 1e-9 && end.x <= p.tableLength - r + 1e-9 && end.y <= p.tableWidth - r + 1e-9)
        XCTAssertGreaterThan(end.x + end.y, 0.2, "the ball comes back out of the corner")
    }

    func testFeaturesJoinTheHashOnlyWhenPresent() {
        let plain = PoolParameters().hash
        var p = PoolParameters()
        p.posts = []; p.pins = []; p.bedHoles = []; p.pocketsEnabled = true
        XCTAssertEqual(p.hash, plain)
        var q = PoolParameters(); q.pocketsEnabled = false
        var r = PoolParameters(); r.posts = [Post(center: Vec2(1, 0.6), radius: 0.02)]
        var s = PoolParameters(); s.pins = [Pin(center: Vec2(1, 0.6), radius: 0.01)]
        var t = PoolParameters(); t.bedHoles = [BedHole(center: Vec2(1, 0.6), radius: 0.04, captureRadius: 0.02)]
        let hashes = [plain, q.hash, r.hash, s.hash, t.hash]
        XCTAssertEqual(Set(hashes).count, hashes.count)
    }

    // A ball in the air higher than a pin's top passes over it without knocking it down.
    func testJumpingBallClearsALowPin() {
        var p = PoolParameters()
        let W = p.tableWidth
        p.pins = [Pin(center: Vec2(0.9, W / 2), radius: 0.009, height: 0.005)]
        let tl = PoolSolver.simulate(ShotInput(parameters: p, positions: lone(Vec2(0.6, W / 2)),
                                               strike: CueStrike(direction: Vec2(1, 0), speed: 4.0, elevation: 0.6), seed: 3))
        // On the way out (before the ball reaches the far cushion and rolls back on the cloth) the pin must stand.
        let firstRail = tl.events.first { $0.kind == .cushion }?.time ?? tl.duration
        XCTAssertTrue(tl.events.filter { $0.kind == .pinDown && $0.time < firstRail }.isEmpty,
                      "a jump over a low pin should leave it standing")
        XCTAssertTrue(tl.segments[0].contains { $0.phase == .airborne }, "the strike should have jumped")
    }
}
