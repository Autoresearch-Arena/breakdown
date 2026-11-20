// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// PURPOSE: Checks for the pocket mouths (parameters version 2): slow balls rolled straight into every pocket drop;
//          a ball that clips a knuckle rebounds off it instead of being swallowed; firm shots just off the pocket's
//          centre line rattle between the jaws; and a randomized sweep of thousands of seeded shots ends with no
//          impossible state (no NaN, no ball resting inside rubber or off the table unless pocketed, no cushion hit that
//          adds energy) and repeats exactly.
// SRP/DRY check: Pass - checked PhysicsTests (break-level checks, kept as they are); these are pocket-level only.
import BreakdownLensModel
import BreakdownTimeline
@testable import BreakdownPhysics
import XCTest

final class PocketTests: XCTestCase {
    let p = PoolParameters()

    /// One cue ball plus the fifteen object balls parked off the table, so only the cue ball moves.
    private func lone(_ at: Vec2) -> [Vec2] { [at] + [Vec2](repeating: NextShot.offTable, count: 15) }

    private func shoot(from at: Vec2, toward dir: Vec2, speed: Double, positions: [Vec2]? = nil) -> Timeline {
        PoolSolver.simulate(ShotInput(parameters: p, positions: positions ?? lone(at),
                                      strike: CueStrike(direction: dir, speed: speed), seed: 1))
    }

    private func mouthEvents(_ tl: Timeline, ball: Int = 0) -> [LensEvent] {
        tl.events.filter { $0.kind == .cushion && $0.edge != .rail && $0.balls.contains { $0.ball == ball } }
    }

    // Slow, dead-centre balls drop into all six pockets.
    func testSlowStraightBallsDropInEveryPocket() {
        let L = p.tableLength, W = p.tableWidth
        let corners = [Vec2(0, 0), Vec2(L, 0), Vec2(0, W), Vec2(L, W)]
        for (k, c) in corners.enumerated() {
            let inward = Vec2(c.x == 0 ? 1 : -1, c.y == 0 ? 1 : -1).normalized
            let tl = shoot(from: c + inward * 0.45, toward: inward * -1, speed: 1.4)
            XCTAssertNotNil(tl.pocketTime[0], "corner \(k) did not take a straight ball")
            XCTAssertEqual(tl.events.last { $0.kind == .pocket }?.pocket, k)
        }
        for (k, y) in [(4, 0.0), (5, W)] {
            let inward = Vec2(0, y == 0 ? 1 : -1)
            let tl = shoot(from: Vec2(L * 0.5, y) + inward * 0.4, toward: inward * -1, speed: 1.2)
            XCTAssertNotNil(tl.pocketTime[0], "side \(k) did not take a straight ball")
            XCTAssertEqual(tl.events.last { $0.kind == .pocket }?.pocket, k)
        }
    }

    // A slow ball whose path passes half a radius from a corner knuckle hits the knuckle and stays out.
    func testKnuckleClipRebounds() {
        let a = p.cornerKnuckleOffset
        let knuckle = Vec2(a, 0)
        let d = Vec2(-1, -1).normalized                 // straight down the corner pocket's line
        let towardLine = Vec2(-1, 1).normalized         // from this knuckle toward the pocket's centre line
        let start = knuckle + towardLine * (p.ballRadius * 0.5) - d * 0.5
        let tl = shoot(from: start, toward: d, speed: 0.9)
        let first = mouthEvents(tl).first
        XCTAssertEqual(first?.edge, .knuckle, "the first mouth contact should be the knuckle")
        XCTAssertNil(tl.pocketTime[0], "a ball that clips the knuckle should not be swallowed")
    }

    // Firm shots just off the centre line rattle: at least one offset gives two or more jaw or knuckle contacts.
    func testOffCentreShotsRattle() {
        let d = Vec2(-1, -1).normalized
        let side = Vec2(-1, 1).normalized
        var rattles = 0, dropsAfterRattle = 0
        for i in 0...40 {
            let offset = 0.001 * Double(i)
            let start = Vec2(0.45, 0.45) + side * offset
            let tl = shoot(from: start, toward: d, speed: 3.5)
            if mouthEvents(tl).count >= 2 {
                rattles += 1
                if tl.pocketTime[0] != nil { dropsAfterRattle += 1 }
            }
        }
        XCTAssertGreaterThan(rattles, 0, "no offset produced a rattle")
        print("POCKET rattles: \(rattles) of 41 offsets, \(dropsAfterRattle) of them dropped")
    }

    // Thousands of seeded shots from random layouts: nothing impossible, and exact repeats.
    func testRandomSweepStaysPhysical() {
        var rng = Lcg(seed: 20_261_120)
        let L = p.tableLength, W = p.tableWidth, r = p.ballRadius
        let jaws = p.jaws
        var checked = 0, mouthHits = 0
        for shot in 0..<3000 {
            // Five balls at random clear spots; the rest off the table.
            var pos = [Vec2](repeating: NextShot.offTable, count: 16)
            var placed = 0
            while placed < 5 {
                let c = Vec2(r + 0.002 + rng.next() * (L - 2 * r - 0.004), r + 0.002 + rng.next() * (W - 2 * r - 0.004))
                if pos.prefix(placed).allSatisfy({ ($0 - c).length > 2 * r + 0.001 }) { pos[placed] = c; placed += 1 }
            }
            let dir = Vec2(rng.next() - 0.5, rng.next() - 0.5)
            guard dir.length > 0.05 else { continue }
            let input = ShotInput(parameters: p, positions: pos,
                                  strike: CueStrike(direction: dir, speed: 0.5 + rng.next() * 7.5,
                                                    tipUp: (rng.next() - 0.5) * 0.03, tipSide: (rng.next() - 0.5) * 0.03),
                                  seed: UInt64(shot))
            let tl = PoolSolver.simulate(input)
            XCTAssertLessThan(tl.duration, PoolSolver.maxTime, "shot \(shot) never settled")
            mouthHits += tl.events.filter { $0.kind == .cushion && $0.edge != .rail }.count
            for e in tl.events where e.kind == .cushion {
                for b in e.balls { XCTAssertLessThanOrEqual(b.energyAfter, b.energyBefore * (1 + 1e-9) + 1e-12, "shot \(shot) cushion gained energy") }
            }
            for b in 0..<5 {
                let s = tl.state(ball: b, at: tl.duration + 1)
                XCTAssertFalse(s.position.x.isNaN || s.position.y.isNaN, "shot \(shot) ball \(b) NaN")
                if s.pocketed { continue }
                // Never inside a knuckle.
                for j in jaws { XCTAssertGreaterThanOrEqual((s.position - j.start).length, r * (1 - 1e-6), "shot \(shot) ball \(b) inside a knuckle") }
                let inside = s.position.x >= r - 1e-6 && s.position.x <= L - r + 1e-6 && s.position.y >= r - 1e-6 && s.position.y <= W - r + 1e-6
                if !inside {
                    // Off the rectangle is only allowed hanging in a pocket mouth, on the playing side of its jaws.
                    let k = (0..<p.pocketCenters.count).min { (s.position - p.pocketCenters[$0]).length < (s.position - p.pocketCenters[$1]).length }!
                    XCTAssertLessThan((s.position - p.pocketCenters[k]).length, 0.13, "shot \(shot) ball \(b) off the table at \(s.position)")
                    for j in jaws where j.pocket == k {
                        let dir = (j.end - j.start).normalized
                        let partner = jaws.first { $0.pocket == k && $0.start != j.start }!.start
                        var n = dir.perp
                        if n.dot((j.start + partner) * 0.5 - j.start) < 0 { n = n * -1 }
                        // Only beside the face itself; behind the knuckle end the knuckle check above applies.
                        let along = (s.position - j.start).dot(dir)
                        if along < 0 || along > (j.end - j.start).length { continue }
                        XCTAssertGreaterThanOrEqual(n.dot(s.position - j.start), r * (1 - 1e-6), "shot \(shot) ball \(b) inside a jaw")
                    }
                }
            }
            if shot % 15 == 0 {
                XCTAssertEqual(tl.contentHash, PoolSolver.simulate(input).contentHash, "shot \(shot) did not repeat")
            }
            checked += 1
        }
        XCTAssertGreaterThan(mouthHits, 0, "the sweep never touched a jaw or knuckle")
        print("POCKET sweep: \(checked) shots, \(mouthHits) jaw or knuckle contacts")
    }
}

/// A tiny seeded generator, so the sweep is the same on every machine and every run.
private struct Lcg {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(1 << 53)
    }
}
