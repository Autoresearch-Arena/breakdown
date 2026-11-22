// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The twelve real-table checks of Tests/BreakdownCoreTests/RealWorldTests.swift as plain functions, so the
//          "sweep" command (RealWorldSweep.swift) can run them on any set of numbers and count how many bands pass.
//          Each takes the parameters to try (generation two is set by the caller) and returns whether its band held
//          and a one-line note of what it measured. The setups, measurements and bands are the test file's, line for
//          line; the reasoning for every band is written there, not repeated here.
//          KEEP IN STEP: this is a copy. A test target cannot be imported by a tool and the solver's module must not
//          carry test setups, so when a case or band changes in RealWorldTests.swift, change it here in the same commit.
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6, item 26: case 7's slow rebound must be at least
//          two degrees steeper, and case 12, the draw-stun-roll order off a rail, joins; the same changes as the tests.)
// SRP/DRY check: Pass - a deliberate, minimal duplicate of RealWorldTests' setups (stated above); the solver call is
//          PoolSolver directly, since TrickSearch's simulate() takes an aim in degrees and these shots use unit
//          directions. Nothing else here exists elsewhere in BreakProbe.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// One case's result on one set of numbers.
struct RWOutcome: Sendable {
    var passed: Bool
    var note: String
}

/// The eleven cases in the test file's order: number, short name, the check.
let rwCases: [(number: Int, name: String, run: @Sendable (PoolParameters) -> RWOutcome)] = [
    (1, "lag", rwLag), (2, "stop shot", rwStopShot), (3, "draw", rwDraw), (4, "thirty-degree rule", rwThirtyDegrees),
    (5, "throw", rwThrow), (6, "rail energy", rwRailEnergy), (7, "rail angle", rwRailAngle),
    (8, "table lengths", rwLengths), (9, "spin-down", rwSpinDown), (10, "squirt and speed loss", rwSquirt),
    (11, "jump", rwJump), (12, "rail rebound order", rwRailOrder),
]

private func rwLayout(_ balls: [Int: Vec2]) -> [Vec2] {
    var out = [Vec2](repeating: NextShot.offTable, count: 16)
    for (k, v) in balls { out[k] = v }
    return out
}

private func rwSolve(_ q: PoolParameters, _ balls: [Int: Vec2], dir: Vec2 = Vec2(1, 0), speed: Double,
                     up: Double = 0, side: Double = 0, elevation: Double = 0) -> Timeline {
    PoolSolver.simulate(ShotInput(parameters: q, positions: rwLayout(balls),
                                  strike: CueStrike(direction: dir, speed: speed, tipUp: up, tipSide: side,
                                                    elevation: elevation), seed: 1))
}

private func rwDegrees(_ a: Vec2, _ b: Vec2) -> Double {
    acos(max(-1, min(1, a.dot(b) / (a.length * b.length)))) * 180 / Double.pi
}

/// Where the cue ball would rest after its first hit if nothing touched it again (RealWorldTests.travelAfterHit).
private func rwTravelAfterHit(_ tl: Timeline, from: Double, _ q: PoolParameters) -> Double? {
    guard let hit = tl.events.first(where: { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }) else { return nil }
    let after = tl.events.filter { $0.time > hit.time && $0.balls.contains { $0.ball == 0 } }
    guard let end = after.first(where: { $0.kind == .phaseTransition && $0.balls.first?.ball == 0
                                          && ($0.phaseTo == .rolling || $0.phaseTo == .spinning
                                              || $0.phaseTo == .stationary) }),
          !after.contains(where: { $0.time < end.time && $0.kind != .phaseTransition }) else { return nil }
    var travel = end.point.x - from
    if end.phaseTo == .rolling {
        let v = end.balls[0].velocityAfter.x
        travel += (v < 0 ? -1 : 1) * v * v / (2 * q.rollingResistance * q.gravity)
    }
    return travel
}

@Sendable func rwLag(_ q: PoolParameters) -> RWOutcome {
    let r = q.ballRadius
    let start = Vec2(r + 0.02, q.tableWidth / 2)
    let target = q.tableLength - r - 0.02
    func lag(_ v: Double) -> (x: Double, time: Double, railed: Bool) {
        let tl = rwSolve(q, [0: start], speed: v)
        return (tl.state(ball: 0, at: tl.duration + 1).position.x, tl.duration, tl.events.contains { $0.kind == .cushion })
    }
    var lo = 0.2, hi = 3.0
    for _ in 0..<40 {
        let mid = (lo + hi) / 2
        let s = lag(mid)
        if s.railed || s.x > target { hi = mid } else { lo = mid }
    }
    let best = lag(lo)
    let ok = !best.railed && abs(best.x - target) <= 0.01 && best.time >= 5.5 && best.time <= 10.5
    return RWOutcome(passed: ok, note: String(format: "lag of one length takes %.2f s (5.5 to 10.5)", best.time))
}

@Sendable func rwStopShot(_ q: PoolParameters) -> RWOutcome {
    let r = q.ballRadius, W = q.tableWidth
    let object = Vec2(1.5, W / 2), cue = Vec2(1.5 - q.tableLength / 8, W / 2)
    let contact = object.x - 2 * r
    let firm = rwTravelAfterHit(rwSolve(q, [0: cue, 1: object], speed: 4.0), from: contact, q) ?? 9
    let soft = rwTravelAfterHit(rwSolve(q, [0: cue, 1: object], speed: 1.0), from: contact, q) ?? -9
    return RWOutcome(passed: abs(firm) <= 0.08 && soft >= 0.10,
                     note: String(format: "firm ends %+.3f m (within 0.08), soft %+.3f m (0.10 on)", firm, soft))
}

@Sendable func rwDraw(_ q: PoolParameters) -> RWOutcome {
    let r = q.ballRadius, W = q.tableWidth
    let object = Vec2(1.5, W / 2), cue = Vec2(1.5 - q.tableLength / 8, W / 2)
    let back = -(rwTravelAfterHit(rwSolve(q, [0: cue, 1: object], speed: 3.0, up: -0.4 * r), from: object.x - 2 * r, q) ?? 9)
    return RWOutcome(passed: back >= 0.6 && back <= 1.9, note: String(format: "draws back %.2f m (0.6 to 1.9)", back))
}

@Sendable func rwThirtyDegrees(_ q: PoolParameters) -> RWOutcome {
    let r = q.ballRadius
    let cue = Vec2(0.5, 0.6)
    var turns: [Double] = []
    for cut in Swift.stride(from: 20.0, through: 45.0, by: 5.0) {
        let phi = cut * Double.pi / 180
        let object = Vec2(cue.x + 0.3 + 2 * r * cos(phi), cue.y + 2 * r * sin(phi))
        let tl = rwSolve(q, [0: cue, 1: object], speed: 1.5, up: 0.4 * r)
        guard let hit = tl.events.first(where: { $0.kind == .ballBall }),
              let mine = hit.balls.first(where: { $0.ball == 0 }),
              let rolls = tl.events.first(where: { $0.time > hit.time && $0.kind == .phaseTransition
                                                    && $0.balls.first?.ball == 0 && $0.phaseTo == .rolling })
        else { return RWOutcome(passed: false, note: "cut \(cut): no hit or never rolled again") }
        turns.append(rwDegrees(rolls.balls[0].velocityAfter, mine.velocityBefore))
    }
    let ok = turns.allSatisfy { $0 >= 25 && $0 <= 40 }
    return RWOutcome(passed: ok, note: "turns " + turns.map { String(format: "%.1f", $0) }.joined(separator: " ")
                     + " deg over cuts 20 to 45 (25 to 40)")
}

@Sendable func rwThrow(_ q: PoolParameters) -> RWOutcome {
    let r = q.ballRadius
    let cue = Vec2(0.5, 0.6)
    let phi = 30 * Double.pi / 180
    let object = Vec2(cue.x + 0.3 + 2 * r * cos(phi), cue.y + 2 * r * sin(phi))
    func throwAngle(_ speed: Double, side: Double) -> Double? {
        let tl = rwSolve(q, [0: cue, 1: object], speed: speed, side: side)
        guard let hit = tl.events.first(where: { $0.kind == .ballBall }),
              let it = hit.balls.first(where: { $0.ball == 1 }) else { return nil }
        return rwDegrees(it.velocityAfter, hit.balls.first?.ball == 0 ? hit.normal : hit.normal * -1)
    }
    let soft = throwAngle(0.8, side: 0) ?? 0, hard = throwAngle(4.0, side: 0) ?? 0
    var cancelled = 90.0
    for k in -18...18 { if let t = throwAngle(0.8, side: Double(k) * 0.025 * r) { cancelled = min(cancelled, t) } }
    let ok = soft >= 2 && soft <= 7 && hard < soft && cancelled < 1
    return RWOutcome(passed: ok, note: String(format: "soft %.2f deg (2 to 7), hard %.2f, least with side %.2f (under 1)",
                                              soft, hard, cancelled))
}

@Sendable func rwRailEnergy(_ q: PoolParameters) -> RWOutcome {
    let r = q.ballRadius
    func share(_ speed: Double) -> Double {
        let tl = rwSolve(q, [0: Vec2(q.tableLength - 0.6, q.tableWidth / 2)], speed: speed, up: 0.4 * r)
        guard let hit = tl.events.first(where: { $0.kind == .cushion }) else { return .nan }
        return hit.balls[0].energyAfter / hit.balls[0].energyBefore
    }
    let medium = share(2), hard = share(6)
    return RWOutcome(passed: medium >= 0.35 && medium <= 0.5 && hard <= 0.9 * medium,
                     note: String(format: "keeps %.3f at medium (0.35 to 0.5), %.3f hard (at most 0.9 of medium)", medium, hard))
}

@Sendable func rwRailAngle(_ q: PoolParameters) -> RWOutcome {
    let r = q.ballRadius
    func exitAngle(_ speed: Double) -> Double {
        let tl = rwSolve(q, [0: Vec2(0.6, 0.45)], dir: Vec2(1, -1), speed: speed, up: 0.4 * r)
        guard let hit = tl.events.first(where: { $0.kind == .cushion }) else { return .nan }
        let v = hit.balls[0].velocityAfter
        return atan2(abs(v.y), abs(v.x)) * 180 / Double.pi
    }
    let slow = exitAngle(1), fast = exitAngle(5)
    return RWOutcome(passed: slow >= 47 && fast < 45,
                     note: String(format: "off the rail at %.1f deg slow (at least 47), %.1f fast (under 45)", slow, fast))
}

/// Case 12 (bug plan after 0.6.6, item 26): straight into a rail from just in front of it, a drawn ball comes back
/// farthest, a stun ball next and a naturally rolling ball the shortest, each clearly farther than the next.
@Sendable func rwRailOrder(_ q: PoolParameters) -> RWOutcome {
    var notes: [String] = []
    var ok = true
    for pace in [0.5, 1.0] {
        let r = rwRailRebounds(q, pace: pace)
        let clear = r.draw >= 1.15 * r.stun && r.stun >= 1.15 * r.roll
        ok = ok && clear
        notes.append(String(format: "%.1f m/s: draw %.3f, stun %.3f, roll %.3f m", pace, r.draw, r.stun, r.roll))
    }
    return RWOutcome(passed: ok, note: notes.joined(separator: "; ") + " (each at least 1.15 times the next)")
}

/// How far a drawn, a stunned and a naturally rolling ball come back off a rail, struck straight at it from 5 mm away
/// at `pace` (the off-centre strokes at the stroke whose slower launch matches the stun's), measured where each would
/// stop if nothing touched it again (the rolling law after its slide off the rail ends).
func rwRailRebounds(_ q: PoolParameters, pace: Double) -> (draw: Double, stun: Double, roll: Double) {
    let r = q.ballRadius
    let start = Vec2(0.8, q.railContactDistance + 0.005)
    let big = q.cueMass + q.ballMass
    // 0.4 R off centre gives exactly the natural roll's spin, 5/2 * v * 0.4 R / R^2 = v / R, at the launch speed.
    let factor = q.usesGenerationTwo ? big / (big + 2.5 * q.cueMass * 0.16) : 1
    func rebound(_ tipUp: Double, _ speed: Double) -> Double {
        let tl = rwSolve(q, [0: start], dir: Vec2(0, -1), speed: speed, up: tipUp)
        guard let rail = tl.events.first(where: { $0.kind == .cushion }) else { return .nan }
        let after = tl.events.filter { $0.time > rail.time && $0.balls.first?.ball == 0 }
        guard let end = after.first(where: { $0.kind == .phaseTransition && $0.phaseFrom == .sliding }) else {
            return tl.state(ball: 0, at: tl.duration + 1).position.y - start.y
        }
        var travel = end.point.y - q.railContactDistance
        if end.phaseTo == .rolling {
            let v = end.balls[0].velocityAfter.y
            travel += (v < 0 ? -1 : 1) * v * v / (2 * q.rollingResistance * q.gravity)
        }
        return travel
    }
    return (rebound(-0.4 * r, pace / factor), rebound(0, pace), rebound(0.4 * r, pace / factor))
}

@Sendable func rwLengths(_ q: PoolParameters) -> RWOutcome {
    let r = q.ballRadius
    let tl = rwSolve(q, [0: Vec2(r + 0.03, q.tableWidth / 2)], speed: 10)
    var path = 0.0
    for s in tl.segments[0] {
        let end = min(s.t1, tl.duration)
        guard end > s.t0 else { continue }
        var last = s.kinematics(at: s.t0).position
        for k in 1...200 {
            let here = s.kinematics(at: s.t0 + (end - s.t0) * Double(k) / 200).position
            path += (here - last).length
            last = here
        }
    }
    let lengths = path / q.tableLength
    return RWOutcome(passed: lengths >= 3.5 && lengths <= 5.5,
                     note: String(format: "a hard ball travels %.2f lengths (3.5 to 5.5)", lengths))
}

@Sendable func rwSpinDown(_ q: PoolParameters) -> RWOutcome {
    let r = q.ballRadius
    let tl = rwSolve(q, [0: Vec2(0.15, q.tableWidth / 2)], speed: 0.8, side: 0.45 * r)
    let w0 = abs(tl.segments[0][0].omega0.z)
    var lo = 0.0, hi = 60.0
    for _ in 0..<60 {
        let mid = (lo + hi) / 2
        if tl.state(ball: 0, at: mid).omega.z != 0 { lo = mid } else { hi = mid }
    }
    let railed = tl.events.contains { $0.kind == .cushion && $0.time < hi }
    return RWOutcome(passed: w0 >= 20 && !railed && hi >= 1.5 && hi <= 8,
                     note: String(format: "%.1f rad/s dies after %.2f s (1.5 to 8)", w0, hi))
}

@Sendable func rwSquirt(_ q: PoolParameters) -> RWOutcome {
    let r = q.ballRadius
    let start = [0: Vec2(0.5, q.tableWidth / 2)]
    let right = rwSolve(q, start, speed: 2, side: 0.5 * r).segments[0][0].velocity0
    let turn = atan2(right.y, right.x) * 180 / Double.pi
    let centre = rwSolve(q, start, speed: 2).segments[0][0].velocity0.length
    let high = rwSolve(q, start, speed: 2, up: 0.5 * r).segments[0][0].velocity0.length
    let share = high / centre
    return RWOutcome(passed: turn >= 1 && turn <= 3.5 && share >= 0.6 && share <= 0.8,
                     note: String(format: "squirt %.2f deg (1 to 3.5), off-centre speed share %.3f (0.6 to 0.8)", turn, share))
}

@Sendable func rwJump(_ q: PoolParameters) -> RWOutcome {
    let r = q.ballRadius, W = q.tableWidth
    let cue = Vec2(0.6, W / 2), blocker = Vec2(0.6 + 4 * r, W / 2)
    func touches(_ tl: Timeline) -> LensEvent? {
        tl.events.first { $0.kind == .ballBall && Set($0.balls.map(\.ball)) == [0, 1] }
    }
    let steep = rwSolve(q, [0: cue, 1: blocker], speed: 6, elevation: 0.75)
    let over = steep.events.first { $0.flight == .landing && $0.balls.first?.ball == 0 && $0.point.x > blocker.x + 2 * r }
    let clean = over != nil && (touches(steep)?.time ?? .infinity) > (over?.time ?? 0)
    let shallow = rwSolve(q, [0: cue, 1: blocker], speed: 6, elevation: 0.15)
    let blocked = (touches(shallow)?.point.x ?? 9) < blocker.x
    return RWOutcome(passed: clean && blocked, note: "steep clears \(clean), shallow blocked \(blocked)")
}
