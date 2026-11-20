// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// PURPOSE: Checks for cue elevation, masse and jump shots. A level strike must record bit for bit what it recorded
//          before the jump model existed (content hashes taken from main before the change). A steep centre strike
//          jumps, lands where the closed form says (slate bounce with friction, then a parabola) and settles after a
//          few shrinking bounces. A jump clears a blocking ball when steep and fast enough and hits it when too low.
//          A masse with a left offset curves left and a right offset curves right (the real behaviour). A ball flying
//          high over a cushion leaves the table as a pocket-like outcome. A seeded sweep with raised cues ends with no
//          NaN, nothing in the air or inside rubber, nothing off the table unless pocketed or flown off, and repeats
//          exactly. Also prints the jump and curve ranges the trick-shot author uses.
// SRP/DRY check: Pass - checked PhysicsTests and PocketTests (flat-table and pocket checks, left as they are); these
//          are the airborne and raised-cue checks only.
import BreakdownLensModel
import BreakdownTimeline
@testable import BreakdownPhysics
import XCTest

final class JumpTests: XCTestCase {
    let p = PoolParameters()

    /// The cue ball and the listed object balls; everything else parked off the table.
    private func layout(_ cue: Vec2, _ others: [Vec2] = []) -> [Vec2] {
        var pos = [Vec2](repeating: NextShot.offTable, count: 16)
        pos[0] = cue
        for (i, o) in others.enumerated() { pos[i + 1] = o }
        return pos
    }

    private func shoot(_ cue: Vec2, _ others: [Vec2] = [], dir: Vec2 = Vec2(1, 0), speed: Double, elevation: Double,
                       tipUp: Double = 0, tipSide: Double = 0) -> Timeline {
        PoolSolver.simulate(ShotInput(parameters: p, positions: layout(cue, others),
                                      strike: CueStrike(direction: dir, speed: speed, tipUp: tipUp, tipSide: tipSide,
                                                        elevation: elevation), seed: 1))
    }

    private func flights(_ tl: Timeline, _ mark: FlightMark, ball: Int = 0) -> [LensEvent] {
        tl.events.filter { $0.flight == mark && $0.balls.first?.ball == ball }
    }

    // A level strike records exactly what it recorded before the jump model: same content hash, bit for bit. The
    // hashes were printed by the unchanged solver on main (20-Nov-2026) for these five shots.
    func testLevelStrikesAreBitForBitUnchanged() {
        let shots: [(ShotInput, UInt64)] = [
            (Rack.showpieceBreak(), 8_237_982_394_174_342_167),
            (Rack.breakShot(seed: 5, aimOffset: 0.01, speed: 10, tipUp: 0.008, tipSide: -0.007), 1_300_594_982_491_109_292),
            (ShotInput(positions: layout(Vec2(0.5, 0.6), [Vec2(1.2, 0.7), Vec2(1.6, 0.3)]),
                       strike: CueStrike(direction: Vec2(1, 0.14), speed: 4.0, tipUp: -0.01, tipSide: 0.006), seed: 9),
             10_734_446_667_115_689_931),
            (ShotInput(positions: layout(Vec2(0.3, 0.3), [Vec2(0.9, 0.9)]),
                       strike: CueStrike(direction: Vec2(0.6, 0.8), speed: 6.5, tipUp: 0.012, tipSide: -0.012), seed: 4),
             2_472_483_834_086_878_112),
            (ShotInput(positions: layout(Vec2(2.0, 1.0)),
                       strike: CueStrike(direction: Vec2(-0.3, -1), speed: 2.2, tipUp: 0, tipSide: 0.01), seed: 2),
             16_134_323_682_271_741_191),
        ]
        for (k, (input, expected)) in shots.enumerated() {
            let tl = PoolSolver.simulate(input)
            XCTAssertEqual(tl.contentHash, expected, "level shot \(k) changed")
            XCTAssertFalse(tl.segments.joined().contains { $0.phase == .airborne }, "level shot \(k) left the cloth")
        }
        XCTAssertEqual(PoolParameters().hash, PoolSolver.simulate(Rack.showpieceBreak()).parameterHash)
    }

    // A steep centre strike: the slate bounce (restitution and capped cloth friction) gives a closed-form take-off,
    // the parabola gives the landing spot, and the ball settles after a few shrinking bounces.
    func testSteepCentreStrikeJumpsAndLandsWhereTheClosedFormSays() {
        let start = Vec2(0.6, 0.635), V = 4.0, e = 0.6
        let tl = shoot(start, speed: V, elevation: e)
        let c = (1 - e * e).squareRoot()
        let down = V * e
        let jn = (1 + p.slateRestitution) * down                  // per unit mass
        let slip = V * c                                          // centre hit: no spin, the contact slips at v
        let f = min(p.slateFriction * jn, 2 * slip / 7)
        let vh = V * c - f
        let vz = p.slateRestitution * down
        let flight = 2 * vz / p.gravity
        let takeOff = flights(tl, .takeOff)
        XCTAssertEqual(takeOff.count, 1)
        XCTAssertEqual(takeOff.first?.time, 0)
        XCTAssertEqual(takeOff.first?.verticalSpeedUp ?? 0, vz, accuracy: 1e-12)
        let landings = flights(tl, .landing)
        XCTAssertGreaterThanOrEqual(landings.count, 2, "expected a few bounces")
        XCTAssertLessThanOrEqual(landings.count, 8, "bounces should die out quickly")
        let first = landings[0]
        XCTAssertEqual(first.time, flight, accuracy: 1e-12)
        XCTAssertEqual(first.point.x, start.x + vh * flight, accuracy: 1e-9)
        XCTAssertEqual(first.point.y, start.y, accuracy: 1e-12)
        XCTAssertEqual(first.verticalSpeedDown, vz, accuracy: 1e-9)
        // Peak height of the first hop, sampled at the top of the parabola.
        XCTAssertEqual(tl.state(ball: 0, at: flight / 2).height, vz * vz / (2 * p.gravity), accuracy: 1e-12)
        // Each bounce rises by the restitution times the speed it came down with, until the cloth absorbs it.
        for k in 1..<landings.count {
            XCTAssertEqual(landings[k].verticalSpeedDown, landings[k - 1].verticalSpeedUp, accuracy: 1e-9)
            XCTAssertLessThan(landings[k].verticalSpeedDown, landings[k - 1].verticalSpeedDown)
        }
        XCTAssertNotEqual(landings.last?.phaseTo, .airborne, "the last landing should stay down")
        // Position and height are continuous across every segment boundary (impacts change velocity, not place).
        let segs = tl.segments[0]
        for k in 1..<segs.count {
            let prev = segs[k - 1].kinematics(at: segs[k].t0)
            XCTAssertEqual((prev.position - segs[k].position0).length, 0, accuracy: 1e-9, "segment \(k)")
            XCTAssertEqual(prev.height, segs[k].height0, accuracy: 1e-9, "segment \(k) height")
        }
        XCTAssertLessThan(tl.duration, PoolSolver.maxTime)
        let end = tl.state(ball: 0, at: tl.duration + 1)
        XCTAssertEqual(end.height, 0)
        XCTAssertEqual(end.velocity.length, 0)
        XCTAssertTrue(end.pocketed || (end.position.x > 0 && end.position.x < p.tableLength))
        print(String(format: "JUMP closed form: launch %.2f m/s at sine %.2f -> take-off %.3f m/s up, %.3f m/s along, " +
                     "first landing %.3f m out after %.3f s, peak %.1f mm, %d landings",
                     V, e, vz, vh, vh * flight, flight, 1000 * vz * vz / (2 * p.gravity), landings.count))
    }

    // A jump clears a ball sitting in its path when steep and fast enough, and hits it when too low.
    func testJumpClearsABlockerOnlyWhenHighEnough() {
        let start = Vec2(0.6, 0.635), blocker = Vec2(0.9, 0.635)
        let high = shoot(start, [blocker], speed: 4.0, elevation: 0.6)
        let land = flights(high, .landing)[0]
        XCTAssertGreaterThan(land.point.x, blocker.x + 2 * p.ballRadius, "the jump should land past the blocker")
        let early = high.events.first { $0.kind == .ballBall && $0.time < land.time }
        XCTAssertNil(early, "the steep jump touched the blocker in the air")
        // Too low: a slight hop still meets the blocker (the 3D contact while airborne, or on the cloth).
        let low = shoot(start, [blocker], speed: 3.0, elevation: 0.15)
        XCTAssertFalse(flights(low, .takeOff).isEmpty, "the low strike should still hop a little")
        let hit = low.events.first { $0.kind == .ballBall }
        XCTAssertNotNil(hit, "the low jump should hit the blocker")
        XCTAssertLessThan(hit?.point.x ?? 9, blocker.x)
        // Level: plainly hits it.
        XCTAssertNotNil(shoot(start, [blocker], speed: 3.0, elevation: 0).events.first { $0.kind == .ballBall })
        // A jump that comes down onto the blocker from above: a 3D contact, and nothing ends overlapping.
        let onto = shoot(start, [Vec2(1.2, 0.635)], speed: 4.0, elevation: 0.6)
        XCTAssertNotNil(onto.events.first { $0.kind == .ballBall }, "expected the landing hop to meet the second ball")
        let a = onto.state(ball: 0, at: onto.duration + 1), b = onto.state(ball: 1, at: onto.duration + 1)
        if !a.pocketed && !b.pocketed { XCTAssertGreaterThan((a.position - b.position).length, 2 * p.ballRadius * (1 - 1e-9)) }
    }

    // Masse: with a raised cue, a left offset curves the ball to the left of the aim line and a right offset to the
    // right, mirror images of each other; the same offsets with a level cue run straight.
    func testMasseCurvesTowardTheSideOfTheOffset() {
        let start = Vec2(0.6, 0.635)
        for (e, V) in [(0.5, 0.5), (0.8, 0.3), (0.95, 0.25)] {
            let left = shoot(start, speed: V, elevation: e, tipSide: -0.6 * p.ballRadius)
            let right = shoot(start, speed: V, elevation: e, tipSide: 0.6 * p.ballRadius)
            let l = left.state(ball: 0, at: left.duration + 1).position
            let r = right.state(ball: 0, at: right.duration + 1).position
            XCTAssertTrue(flights(left, .takeOff).isEmpty, "this masse should stay on the cloth")
            // Aim is +x, so left of the aim line is +y.
            XCTAssertGreaterThan(l.y - start.y, 0.01, "left masse at sine \(e) did not curve left")
            XCTAssertLessThan(r.y - start.y, -0.01, "right masse at sine \(e) did not curve right")
            XCTAssertEqual(l.y - start.y, -(r.y - start.y), accuracy: 1e-9)
            print(String(format: "MASSE sine %.2f speed %.2f: ends %.0f mm along, %.0f mm to the side",
                         e, V, 1000 * (l.x - start.x), 1000 * (l.y - start.y)))
        }
        let level = shoot(start, speed: 0.5, elevation: 0, tipSide: -0.6 * p.ballRadius)
        XCTAssertEqual(level.state(ball: 0, at: level.duration + 1).position.y, start.y, accuracy: 1e-12)
    }

    // A ball flying high over a cushion leaves the table: a pocket-like outcome, never a crash, and the next layout
    // brings the cue ball back on the head spot.
    func testHighBallFliesOffTheTable() {
        let tl = shoot(Vec2(2.3, 0.635), speed: 6.0, elevation: 0.7)
        XCTAssertTrue(tl.flewOffTable(0))
        XCTAssertNotNil(tl.pocketTime[0])
        let off = flights(tl, .offTable)
        XCTAssertEqual(off.count, 1)
        XCTAssertGreaterThanOrEqual(off[0].height, p.cushionNoseHeight)
        XCTAssertTrue(tl.state(ball: 0, at: tl.duration + 1).pocketed)
        let next = NextShot.layout(after: tl, parameters: p)
        XCTAssertTrue(NextShot.isOnTable(next[0]))
        // The same strike from the middle of the table lands on it instead.
        XCTAssertFalse(shoot(Vec2(0.4, 0.635), speed: 6.0, elevation: 0.7).flewOffTable(0))
    }

    // A raised strike repeats exactly, and its hash differs from the level one.
    func testRaisedStrikeRepeats() {
        let a = shoot(Vec2(0.6, 0.6), [Vec2(1.0, 0.62)], speed: 5, elevation: 0.5, tipUp: 0.004, tipSide: -0.006)
        let b = shoot(Vec2(0.6, 0.6), [Vec2(1.0, 0.62)], speed: 5, elevation: 0.5, tipUp: 0.004, tipSide: -0.006)
        let c = shoot(Vec2(0.6, 0.6), [Vec2(1.0, 0.62)], speed: 5, elevation: 0, tipUp: 0.004, tipSide: -0.006)
        XCTAssertEqual(a.contentHash, b.contentHash)
        XCTAssertNotEqual(a.contentHash, c.contentHash)
    }

    // Seeded random shots with raised cues among them: nothing impossible, and exact repeats.
    func testRandomSweepWithRaisedCuesStaysPhysical() {
        var rng = SweepRandom(seed: 20_261_121)
        let L = p.tableLength, W = p.tableWidth, r = p.ballRadius
        var jumps = 0, offTable = 0, airContacts = 0, checked = 0
        for shot in 0..<1500 {
            var pos = [Vec2](repeating: NextShot.offTable, count: 16)
            var placed = 0
            while placed < 6 {
                let c = Vec2(r + 0.002 + rng.next() * (L - 2 * r - 0.004), r + 0.002 + rng.next() * (W - 2 * r - 0.004))
                if pos.prefix(placed).allSatisfy({ ($0 - c).length > 2 * r + 0.001 }) { pos[placed] = c; placed += 1 }
            }
            let dir = Vec2(rng.next() - 0.5, rng.next() - 0.5)
            guard dir.length > 0.05 else { continue }
            // Two shots in three have a raised cue, anywhere from barely raised to nearly vertical.
            let elevation = shot % 3 == 0 ? 0 : rng.next() * 0.95
            let input = ShotInput(parameters: p, positions: pos,
                                  strike: CueStrike(direction: dir, speed: 0.3 + rng.next() * 7.7,
                                                    tipUp: (rng.next() - 0.5) * 0.03, tipSide: (rng.next() - 0.5) * 0.03,
                                                    elevation: elevation),
                                  seed: UInt64(shot))
            let tl = PoolSolver.simulate(input)
            XCTAssertLessThan(tl.duration, PoolSolver.maxTime, "shot \(shot) never settled")
            if tl.events.contains(where: { $0.flight == .takeOff }) { jumps += 1 }
            airContacts += tl.events.filter { $0.kind == .ballBall && $0.height > 0 }.count
            for e in tl.events where e.kind == .cushion || e.flight == .landing {
                for b in e.balls {
                    XCTAssertLessThanOrEqual(b.energyAfter, b.energyBefore * (1 + 1e-9) + 1e-12, "shot \(shot) \(e.kind) gained energy")
                }
            }
            var rest: [Int: Vec2] = [:]
            for b in 0..<6 {
                // Every path, in the air or on the cloth, is continuous in place and height across its segments.
                let segs = tl.segments[b]
                for k in 1..<segs.count {
                    let prev = segs[k - 1].kinematics(at: segs[k].t0)
                    XCTAssertEqual((prev.position - segs[k].position0).length, 0, accuracy: 1e-9, "shot \(shot) ball \(b) segment \(k)")
                    XCTAssertEqual(prev.height, segs[k].height0, accuracy: 1e-9, "shot \(shot) ball \(b) segment \(k) height")
                    XCTAssertGreaterThanOrEqual(segs[k].height0, 0, "shot \(shot) ball \(b) below the cloth")
                }
                let s = tl.state(ball: b, at: tl.duration + 1)
                XCTAssertFalse(s.position.x.isNaN || s.position.y.isNaN || s.height.isNaN, "shot \(shot) ball \(b) NaN")
                if s.pocketed {
                    if tl.flewOffTable(b) { offTable += 1 }
                    continue
                }
                XCTAssertEqual(s.height, 0, "shot \(shot) ball \(b) still in the air")
                XCTAssertEqual(s.velocity.length, 0, "shot \(shot) ball \(b) still moving")
                for j in p.jaws { XCTAssertGreaterThanOrEqual((s.position - j.start).length, r * (1 - 1e-6), "shot \(shot) ball \(b) inside a knuckle") }
                let inside = s.position.x >= r - 1e-6 && s.position.x <= L - r + 1e-6 && s.position.y >= r - 1e-6 && s.position.y <= W - r + 1e-6
                if !inside {
                    // Off the rectangle is only allowed hanging in a pocket mouth.
                    let near = p.pocketCenters.map { (s.position - $0).length }.min()!
                    XCTAssertLessThan(near, 0.13, "shot \(shot) ball \(b) off the table at \(s.position)")
                }
                rest[b] = s.position
            }
            for (i, a) in rest { for (j, b) in rest where j > i {
                XCTAssertGreaterThan((a - b).length, 2 * r * (1 - 1e-9), "shot \(shot) balls \(i),\(j) overlap at rest")
            } }
            if shot % 15 == 0 {
                XCTAssertEqual(tl.contentHash, PoolSolver.simulate(input).contentHash, "shot \(shot) did not repeat")
            }
            checked += 1
        }
        XCTAssertGreaterThan(jumps, 100, "the sweep hardly jumped")
        print("JUMP sweep: \(checked) shots, \(jumps) with a take-off, \(airContacts) contacts in the air, \(offTable) balls flew off")
    }

    // Not a pass/fail check: prints which raised strikes leave the cloth and how high and far they go, and how far a
    // masse bends, so the trick-shot author can pick numbers. Run with: swift test --filter JumpTests/testPrintRanges
    func testPrintRanges() {
        let start = Vec2(0.6, 0.635)
        for e in [0.1, 0.2, 0.3, 0.5, 0.7, 0.9] {
            var row = String(format: "JUMP range sine %.1f:", e)
            for V in [1.0, 2.0, 3.0, 4.0, 6.0, 8.0] {
                let tl = shoot(start, speed: V, elevation: e)
                if let up = flights(tl, .takeOff).first?.verticalSpeedUp, let land = flights(tl, .landing).first {
                    row += String(format: "  v%.0f peak %3.0fmm land %4.0fmm", V, 1000 * up * up / (2 * p.gravity),
                                  1000 * (land.point.x - start.x))
                } else if tl.flewOffTable(0) {
                    row += String(format: "  v%.0f flies off table    ", V)
                } else {
                    row += String(format: "  v%.0f stays down        ", V)
                }
            }
            print(row)
        }
    }
}

/// A tiny seeded generator, so the sweep is the same on every machine and every run.
private struct SweepRandom {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(1 << 53)
    }
}
