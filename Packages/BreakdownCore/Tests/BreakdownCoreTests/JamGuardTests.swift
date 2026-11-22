// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Checks for the jam guard (plans/21-Nov-2026-pockets-and-jams-plan.md, part B; spec 3.5 "Zeno guards"),
//          which runs at every physics generation. Spec 21: balls resting in contact with each other or with a rail
//          make no events until something reaches them. Known jams finish quickly: the frozen pair the throw shot's
//          author found (a cue ball following its object ball into a ball frozen a micrometre away, which used to
//          re-collide tens of thousands of times) and the band of jump speeds on the point-blank puzzle that wedged the
//          cue ball against the 8; each must finish in under two thousand events, end at rest with nothing overlapping
//          or in rubber, and never gain energy, with any settled-in-contact event removing energy only. And the guard
//          must leave a normal shot alone: breaks record no settling (JumpTests' pinned hashes prove them unchanged).
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: the untouched-shots check names its
//          generation: the bit-for-bit breaks on generation one, the new showpiece break on the default.)
// SRP/DRY check: Pass - checked PhysicsTests (event budget), JumpTests (the bit-for-bit pins, unchanged) and BreakProbe's
//          "timing" command (the source of the frozen-pair layout). These are the jam guard's own checks.
import BreakdownLensModel
import BreakdownTimeline
@testable import BreakdownPhysics
import Foundation
import XCTest

final class JamGuardTests: XCTestCase {
    private func generations() -> [PoolParameters] {
        var p2 = PoolParameters()
        p2.modelGeneration = PoolParameters.newestGeneration
        return [PoolParameters(), p2]
    }

    private func unit(_ deg: Double) -> Vec2 { Vec2(cos(deg * Double.pi / 180), sin(deg * Double.pi / 180)) }

    /// Rotate a vector by degrees (counter-clockwise).
    private func rotate(_ v: Vec2, _ deg: Double) -> Vec2 {
        let a = deg * Double.pi / 180
        return Vec2(cos(a) * v.x - sin(a) * v.y, sin(a) * v.x + cos(a) * v.y)
    }

    /// The checks every jam must pass: finished well inside the budget, at rest, nothing overlapping or in rubber,
    /// no event that gains energy, and every settling removes energy.
    private func assertSettled(_ input: ShotInput, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let (tl, report) = PoolSolver.simulateWithReport(input)
        let p = input.parameters
        let r = p.ballRadius
        XCTAssertLessThan(report.events, 2_000, "\(label): \(report.events) events", file: file, line: line)
        XCTAssertFalse(report.hitEventLimit, "\(label) hit the event limit", file: file, line: line)
        for e in tl.events where e.kind != .cueStrike {
            let before = e.balls.reduce(0.0) { $0 + $1.energyBefore }
            let after = e.balls.reduce(0.0) { $0 + $1.energyAfter }
            XCTAssertLessThanOrEqual(after, before * (1 + 1e-9) + 1e-12, "\(label): energy rose at \(e.kind) t=\(e.time)",
                                     file: file, line: line)
            if e.kind == .settledInContact {
                XCTAssertGreaterThanOrEqual(e.energyRemoved ?? -1, 0, file: file, line: line)
                XCTAssertEqual(e.energyRemoved ?? 0, before - after, accuracy: 1e-12, file: file, line: line)
                XCTAssertFalse(e.balls.isEmpty, file: file, line: line)
            }
        }
        var rest: [Vec2] = []
        for b in 0..<tl.ballCount where NextShot.isOnTable(input.positions[b]) {
            let s = tl.state(ball: b, at: tl.duration + 1)
            if s.pocketed { continue }
            XCTAssertEqual(s.velocity.length, 0, "\(label): ball \(b) still moving", file: file, line: line)
            for j in p.jaws {
                XCTAssertGreaterThanOrEqual((s.position - j.start).length, p.railContactDistance * (1 - 1e-6),
                                            "\(label): ball \(b) inside a knuckle", file: file, line: line)
            }
            rest.append(s.position)
        }
        for i in 0..<rest.count { for j in (i + 1)..<rest.count {
            XCTAssertGreaterThan((rest[i] - rest[j]).length, 2 * r * (1 - 1e-9), "\(label): overlap at rest", file: file, line: line)
        } }
        print("JAM \(label): \(report.events) events, \(report.jamsSettled) settled, \(tl.events.count) recorded")
    }

    // Spec 21: a pair of balls touching, and a ball touching a rail, all at rest; another ball is struck away from
    // them. No event may involve the resting balls, at either generation.
    func testRestingContactsStayQuiet() {
        for p in generations() {
            let r = p.ballRadius
            var pos = [Vec2](repeating: NextShot.offTable, count: 16)
            pos[0] = Vec2(2.0, 0.9)
            pos[1] = Vec2(0.7, 0.6)
            pos[2] = Vec2(0.7 + 2 * r, 0.6)                       // frozen to ball 1, exactly touching
            pos[3] = Vec2(0.9, p.railContactDistance)              // frozen to the bottom rail
            let tl = PoolSolver.simulate(ShotInput(parameters: p, positions: pos,
                                                   strike: CueStrike(direction: Vec2(0, 1), speed: 0.3), seed: 1))
            for e in tl.events {
                XCTAssertFalse(e.balls.contains { [1, 2, 3].contains($0.ball) }, "generation \(p.modelGeneration): \(e.kind) touched a resting ball")
            }
            for b in 1...3 { XCTAssertEqual(tl.state(ball: b, at: tl.duration + 1).position, pos[b]) }
        }
    }

    // The frozen pair from the throw shot's authoring (BreakProbe "timing"): the 2 and the 8 a micrometre apart, the cue
    // ball driving into the 2 along their line of centres with side spin, so it follows the 2 into the 8 and used to
    // re-collide tens of thousands of times. At every gap and both generations it must now finish quickly and cleanly.
    func testFrozenPairFollowChatterSettles() {
        for p in generations() {
            let r = p.ballRadius
            let corner = Vec2(0, 0)
            let b = corner + Vec2(1, 0.62).normalized * 0.45
            let v = rotate((corner - b).normalized, 5)
            for gap in [1e-6, 1e-5, 1e-4] {
                let a = b - v * (2 * r + gap)
                let c = a - v * 0.5
                var pos = [Vec2](repeating: NextShot.offTable, count: 16)
                pos[0] = c; pos[2] = a; pos[8] = b
                for (side, up) in [(0.012, 0.0), (0.0, 0.008), (0.0, 0.0)] {
                    let input = ShotInput(parameters: p, positions: pos,
                                          strike: CueStrike(direction: (a - c).normalized, speed: 2.5, tipUp: up, tipSide: side),
                                          seed: 1)
                    assertSettled(input, "gen \(p.modelGeneration) frozen pair gap \(gap) side \(side) up \(up)")
                }
            }
        }
    }

    // Point-blank (Behind the 8-Ball, situation 7): the steep jump over the 8 wedged the cue ball against it in a
    // narrow band of speeds. Sweep that band finely, at both generations.
    func testPointBlankJumpBandFinishes() {
        let d = 2.54 / 8                                         // one diamond, as EightBallTable lays it out
        func spot(_ across: Double, _ along: Double) -> Vec2 { Vec2(along * d, (4 - across) * d) }
        var pos = [Vec2](repeating: NextShot.offTable, count: 16)
        pos[0] = spot(1.0, 6.0); pos[8] = spot(1.3, 6.17)
        pos[14] = spot(2.6, 6.9); pos[1] = spot(3.4, 3.1); pos[3] = spot(0.6, 2.2); pos[6] = spot(2.2, 4.9); pos[7] = spot(3.7, 5.8)
        for p in generations() {
            var speed = 2.8
            while speed <= 4.2 + 1e-9 {
                let input = ShotInput(parameters: p, positions: pos,
                                      strike: CueStrike(direction: unit(-61.55), speed: speed, tipUp: -0.0045,
                                                        elevation: 0.85),
                                      seed: 1)
                assertSettled(input, String(format: "gen %ld point-blank jump at %.2f m/s", p.modelGeneration, speed))
                speed += 0.05
            }
        }
    }

    // A storm settles and says so: a cue ball driven at walking pace into a ball frozen against a rail, straight in. The
    // shot either never storms (then it is simply short) or every settling closes the energy ledger.
    func testWedgeAgainstARailSettlesCleanly() {
        for p in generations() {
            let r = p.ballRadius
            var pos = [Vec2](repeating: NextShot.offTable, count: 16)
            pos[1] = Vec2(0.8, p.railContactDistance + 1e-6)
            pos[0] = Vec2(0.8, p.railContactDistance + 2 * r + 0.2)
            for (speed, up) in [(0.5, 0.01), (1.0, 0.012), (2.0, 0.0)] {
                let input = ShotInput(parameters: p, positions: pos,
                                      strike: CueStrike(direction: Vec2(0, -1), speed: speed, tipUp: up), seed: 1)
                assertSettled(input, "gen \(p.modelGeneration) wedge on a rail at \(speed) m/s")
            }
        }
    }

    // The guard leaves normal shots alone: the showpiece break and another break pinned bit for bit in JumpTests (whose
    // content hashes prove they are unchanged; generation one on its old numbers since the flip), and the break the
    // momentum test uses, record no settling, never reach the event limit, and settle well inside two thousand events.
    // On the default generation two the new showpiece break and the momentum test's break are untouched too. (The
    // seed-5 break below does storm on generation two: balls 7 and 8 chatter about six hundred times inside one
    // millisecond a quarter of a second in, and the guard settles them, removing about nine microjoules; that is the
    // guard doing its job, so that break is checked here on generation one only.)
    func testNormalShotsAreUntouched() {
        let old = PoolParameters.generationOne
        let shots: [ShotInput] = [
            Rack.generationOneShowpieceBreak(),
            Rack.breakShot(parameters: old, seed: 5, aimOffset: 0.01, speed: 10, tipUp: 0.008, tipSide: -0.007),
            Rack.breakShot(parameters: old, seed: 3, aimOffset: 0.004, speed: 9),
            Rack.showpieceBreak(),
            Rack.breakShot(seed: 3, aimOffset: 0.004, speed: 9),
        ]
        for (k, input) in shots.enumerated() {
            let (tl, report) = PoolSolver.simulateWithReport(input)
            XCTAssertEqual(report.jamsSettled, 0, "shot \(k) was settled by the jam guard")
            XCTAssertFalse(report.hitEventLimit)
            XCTAssertFalse(tl.events.contains { $0.kind == .settledInContact })
            XCTAssertLessThan(report.events, 2_000)
        }
    }
}
