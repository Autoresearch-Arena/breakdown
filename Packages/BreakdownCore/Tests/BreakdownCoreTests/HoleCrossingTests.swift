// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Checks for generation-two holes (plans/21-Nov-2026-pockets-and-jams-plan.md, part A). A ball over a hole is
//          caught only if it falls a third of its radius before its centre leaves the far side; an edge pocket's back
//          wall catches any ball whose path ends inside the pocket; a ball that skips records a rim-skip event, loses a
//          little speed and carries on; every pocket and rim-skip event records the entry speed and angle. Tests: slow
//          centred balls drop in every pocket and bed hole; a fast off-centre ball skips a bed hole that the same line
//          slow drops into; a break-speed ball straight into a corner drops; a fast ball along the rail past the side
//          pocket skips it and a slow one drops; the skip speed of a centred ball rises with the hole's size and sits
//          exactly where the fall test puts it; and random sweeps (pool table and a bed-hole table) never leave a ball
//          resting over a hole, never produce not-a-number, and repeat exactly.
// SRP/DRY check: Pass - checked PocketTests (generation-1 mouths and rattles, unchanged) and TableFeatureTests (bed holes
//          at generation 1). These are the generation-two hole checks only.
import BreakdownLensModel
import BreakdownTimeline
@testable import BreakdownPhysics
import Foundation
import XCTest

final class HoleCrossingTests: XCTestCase {
    private var p2: PoolParameters {
        var p = PoolParameters()
        p.modelGeneration = PoolParameters.newestGeneration
        return p
    }

    /// Generation two with no edge pockets and one bed hole of capture radius `rc` in the middle of the table.
    private func bedTable(_ rc: Double) -> PoolParameters {
        var p = p2
        p.pocketsEnabled = false
        p.bedHoles = [BedHole(center: Vec2(1.27, 0.635), radius: rc + 0.015, captureRadius: rc)]
        return p
    }

    private func lone(_ at: Vec2) -> [Vec2] { [at] + [Vec2](repeating: NextShot.offTable, count: 15) }

    private func shoot(_ p: PoolParameters, from: Vec2, toward d: Vec2, speed: Double) -> Timeline {
        PoolSolver.simulate(ShotInput(parameters: p, positions: lone(from), strike: CueStrike(direction: d, speed: speed), seed: 1))
    }

    /// The first time the ball met a hole: its pocket or rim-skip event.
    private func firstHole(_ tl: Timeline) -> LensEvent? {
        tl.events.first { $0.kind == .pocket || $0.kind == .rimSkip }
    }

    /// The speed at which a ball crossing a hole of capture radius rc through its centre starts to skip: the chord is
    /// 2 rc, the crossing time 2 rc / v, the fall g t^2 / 2 must reach f R, so v* = 2 rc sqrt(g / (2 f R)).
    private func skipSpeed(_ rc: Double, _ p: PoolParameters) -> Double {
        2 * rc * (p.gravity / (2 * p.pocketCaptureFallFraction * p.ballRadius)).squareRoot()
    }

    // Slow, dead-centre balls drop into all six pockets and into a bed hole, and the events say they came in straight.
    func testSlowCentredBallsDropEverywhere() {
        let p = p2, L = p.tableLength, W = p.tableWidth
        let corners = [Vec2(0, 0), Vec2(L, 0), Vec2(0, W), Vec2(L, W)]
        var drops: [LensEvent] = []
        for (k, c) in corners.enumerated() {
            let inward = Vec2(c.x == 0 ? 1 : -1, c.y == 0 ? 1 : -1).normalized
            let tl = shoot(p, from: c + inward * 0.45, toward: inward * -1, speed: 1.4)
            XCTAssertNotNil(tl.pocketTime[0], "corner \(k) did not take a straight ball")
            XCTAssertEqual(firstHole(tl)?.kind, .pocket)
            XCTAssertEqual(firstHole(tl)?.pocket, k)
            if let e = firstHole(tl) { drops.append(e) }
        }
        for (k, y) in [(4, 0.0), (5, W)] {
            let inward = Vec2(0, y == 0 ? 1 : -1)
            let tl = shoot(p, from: Vec2(L * 0.5, y) + inward * 0.4, toward: inward * -1, speed: 1.2)
            XCTAssertNotNil(tl.pocketTime[0], "side \(k) did not take a straight ball")
            XCTAssertEqual(firstHole(tl)?.kind, .pocket)
            XCTAssertEqual(firstHole(tl)?.pocket, k)
            if let e = firstHole(tl) { drops.append(e) }
        }
        let bed = shoot(bedTable(0.03), from: Vec2(0.87, 0.635), toward: Vec2(1, 0), speed: 0.6)
        XCTAssertEqual(firstHole(bed)?.kind, .pocket)
        XCTAssertEqual(firstHole(bed)?.pocket, 6)
        if let e = firstHole(bed) { drops.append(e) }
        XCTAssertEqual(drops.count, 7)
        for e in drops {
            let entry = e.entry
            XCTAssertNotNil(entry, "every pocket event records how the ball came in")
            XCTAssertGreaterThan(entry?.speed ?? 0, 0)
            XCTAssertEqual(entry?.cosine ?? 0, 1, accuracy: 1e-6, "a dead-centre ball comes in along the centre line")
            XCTAssertEqual(entry?.sine ?? 1, 0, accuracy: 1e-3)
        }
    }

    // A ball crossing a bed hole off its centre: fast, it skips (a rim-skip event with its entry, a little speed lost,
    // and it carries on); the same line slow, it drops.
    func testFastOffCentreBallSkipsABedHoleAndSlowDrops() {
        let p = bedTable(0.03)
        let start = Vec2(0.87, 0.635 + 0.018)                   // 0.6 of the capture radius off the centre line
        let fast = shoot(p, from: start, toward: Vec2(1, 0), speed: 4.0)
        let skip = firstHole(fast)
        XCTAssertEqual(skip?.kind, .rimSkip)
        XCTAssertEqual(skip?.pocket, 6)
        XCTAssertNotNil(skip?.entry)
        if let b = skip?.balls.first {
            XCTAssertEqual(b.velocityAfter.length, b.velocityBefore.length * (1 - p.rimSkipSpeedLoss), accuracy: 1e-9)
            // It left the hole's circle: the event is at the far rim.
            XCTAssertEqual((skip!.point - p.bedHoles[0].center).length, p.bedHoles[0].captureRadius, accuracy: 1e-6)
        }
        let slow = shoot(p, from: start, toward: Vec2(1, 0), speed: 0.6)
        XCTAssertEqual(firstHole(slow)?.kind, .pocket)
        XCTAssertNotNil(slow.pocketTime[0])
    }

    // A break-speed ball straight down the diagonal into a corner meets the pocket's back and drops.
    func testBreakSpeedBallIntoACornerDrops() {
        let p = p2
        let inward = Vec2(1, 1).normalized
        let tl = shoot(p, from: inward * 0.45, toward: inward * -1, speed: 10)
        XCTAssertEqual(firstHole(tl)?.kind, .pocket)
        XCTAssertEqual(firstHole(tl)?.pocket, 0)
        XCTAssertGreaterThan(firstHole(tl)?.entry?.speed ?? 0, 8)
    }

    // A ball running along the long rail, two millimetres off it, passes over the mouth of the side pocket: fast, its path
    // leaves the hole on the table side before it can fall, so it skips; slow, it drops.
    func testAlongTheRailPastTheSidePocket() {
        let p = p2
        let start = Vec2(p.tableLength * 0.5 - 0.4, p.railContactDistance + 0.002)
        let fast = shoot(p, from: start, toward: Vec2(1, 0), speed: 5)
        XCTAssertEqual(firstHole(fast)?.kind, .rimSkip, "a fast ball along the rail should skip the side pocket")
        XCTAssertEqual(firstHole(fast)?.pocket, 4)
        let slow = shoot(p, from: start, toward: Vec2(1, 0), speed: 1)
        XCTAssertEqual(firstHole(slow)?.kind, .pocket, "a slow ball along the rail should drop into the side pocket")
        XCTAssertEqual(firstHole(slow)?.pocket, 4)
        // Generation one swallows both (the old rule), which is the change.
        var p1 = PoolParameters()
        p1.modelGeneration = 1
        XCTAssertEqual(firstHole(shoot(p1, from: Vec2(start.x, p1.ballRadius + 0.002), toward: Vec2(1, 0), speed: 5))?.kind, .pocket)
    }

    // A centred ball's skip speed rises with the hole's size, and the switch sits where the fall test says.
    func testSkipSpeedRisesWithHoleSize() {
        var thresholds: [Double] = []
        for rc in [0.02, 0.035] {
            let p = bedTable(rc)
            var lo = 1.0, hi = 8.0                               // 1 m/s reaches the hole well under either skip speed
            XCTAssertEqual(firstHole(shoot(p, from: Vec2(0.87, 0.635), toward: Vec2(1, 0), speed: lo))?.kind, .pocket)
            XCTAssertEqual(firstHole(shoot(p, from: Vec2(0.87, 0.635), toward: Vec2(1, 0), speed: hi))?.kind, .rimSkip)
            for _ in 0..<30 {
                let mid = (lo + hi) * 0.5
                if firstHole(shoot(p, from: Vec2(0.87, 0.635), toward: Vec2(1, 0), speed: mid))?.kind == .pocket { lo = mid } else { hi = mid }
            }
            let vStar = skipSpeed(rc, p)
            let dropped = firstHole(shoot(p, from: Vec2(0.87, 0.635), toward: Vec2(1, 0), speed: lo))
            let skipped = firstHole(shoot(p, from: Vec2(0.87, 0.635), toward: Vec2(1, 0), speed: hi))
            XCTAssertLessThanOrEqual(dropped?.entry?.speed ?? 99, vStar * (1 + 1e-6))
            XCTAssertGreaterThanOrEqual(skipped?.entry?.speed ?? 0, vStar * (1 - 1e-6))
            print(String(format: "HOLE capture radius %.3f m: skips above %.3f m/s at the hole (launch %.3f m/s)", rc, vStar, hi))
            thresholds.append(hi)
        }
        XCTAssertGreaterThan(thresholds[1], thresholds[0])
    }

    // Random shots on generation two, on the pool table and on a table with three bed holes: nothing rests over a hole,
    // nothing is not-a-number, every hole event records its entry, nothing overlaps at rest, and the shots repeat.
    func testRandomSweepLeavesNothingOverAHole() {
        var rng = HoleRandom(state: 20_261_121)
        var bedHoles = p2
        bedHoles.pocketsEnabled = false
        bedHoles.bedHoles = [BedHole(center: Vec2(0.6, 0.4), radius: 0.045, captureRadius: 0.03),
                             BedHole(center: Vec2(1.27, 0.8), radius: 0.045, captureRadius: 0.03),
                             BedHole(center: Vec2(1.9, 0.5), radius: 0.04, captureRadius: 0.025)]
        var skips = 0, drops = 0
        for shot in 0..<2000 {
            let p = shot % 4 == 3 ? bedHoles : p2
            let r = p.ballRadius, L = p.tableLength, W = p.tableWidth
            let holes = (p.pocketsEnabled ? Array(p.pocketCenters.prefix(6)) : []) + p.bedHoles.map(\.center)
            let radii = (p.pocketsEnabled ? Array(p.pocketCaptureRadii.prefix(6)) : []) + p.bedHoles.map(\.captureRadius)
            var pos = [Vec2](repeating: NextShot.offTable, count: 16)
            var placed = 0
            while placed < 6 {
                let c = Vec2(r + 0.002 + rng.next() * (L - 2 * r - 0.004), r + 0.002 + rng.next() * (W - 2 * r - 0.004))
                let clearOfHoles = zip(holes, radii).allSatisfy { ($0.0 - c).length > $0.1 + 0.001 }
                if clearOfHoles && pos.prefix(placed).allSatisfy({ ($0 - c).length > 2 * r + 0.001 }) { pos[placed] = c; placed += 1 }
            }
            let dir = Vec2(rng.next() - 0.5, rng.next() - 0.5)
            guard dir.length > 0.05 else { continue }
            let input = ShotInput(parameters: p, positions: pos,
                                  strike: CueStrike(direction: dir, speed: 0.5 + rng.next() * 7.5,
                                                    tipUp: (rng.next() - 0.5) * 0.026, tipSide: (rng.next() - 0.5) * 0.026),
                                  seed: UInt64(shot))
            let tl = PoolSolver.simulate(input)
            XCTAssertLessThan(tl.duration, PoolSolver.maxTime, "shot \(shot) never settled")
            for e in tl.events where e.kind == .pocket || e.kind == .rimSkip {
                XCTAssertNotNil(e.entry, "shot \(shot): a hole event without its entry")
                if e.kind == .rimSkip { skips += 1 } else { drops += 1 }
            }
            for e in tl.events where e.kind == .cushion || e.kind == .rimSkip || e.kind == .settledInContact {
                for b in e.balls {
                    XCTAssertLessThanOrEqual(b.energyAfter, b.energyBefore * (1 + 1e-9) + 1e-12, "shot \(shot) \(e.kind) gained energy")
                }
            }
            var rest: [Vec2] = []
            for b in 0..<6 {
                let s = tl.state(ball: b, at: tl.duration + 1)
                XCTAssertFalse(s.position.x.isNaN || s.position.y.isNaN, "shot \(shot) ball \(b) NaN")
                if s.pocketed { continue }
                XCTAssertEqual(s.velocity.length, 0, "shot \(shot) ball \(b) still moving")
                for (h, rc) in zip(holes, radii) {
                    XCTAssertGreaterThan((s.position - h).length, rc, "shot \(shot) ball \(b) rests over a hole")
                }
                rest.append(s.position)
            }
            for i in 0..<rest.count { for j in (i + 1)..<rest.count {
                XCTAssertGreaterThan((rest[i] - rest[j]).length, 2 * r * (1 - 1e-9), "shot \(shot) overlap at rest")
            } }
            if shot % 20 == 0 {
                XCTAssertEqual(tl.contentHash, PoolSolver.simulate(input).contentHash, "shot \(shot) did not repeat")
            }
        }
        XCTAssertGreaterThan(drops, 0)
        print("HOLE sweep: \(drops) drops, \(skips) rim skips")
    }
}

/// A tiny seeded generator, so the sweep is the same on every machine and every run.
private struct HoleRandom {
    var state: UInt64
    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(1 << 53)
    }
}
