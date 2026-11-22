// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The physics against the real world (plans/21-Nov-2026-physics-proof-plan.md package 3): eleven behaviours
//          anyone can check on a real pool table, each with a pass band and what it constrains. They play on physics
//          generation two (PoolParameters.modelGeneration = 2, set explicitly), the physics the rails, cue-strike and
//          pockets plans build and the proof plan's package 4 tunes and then makes the default. Every shot is solved
//          with the public solver and measured from its recording only.
//          Where the band comes from is written above each case: worked out from physics stated in the spec, or the
//          kind of observation a player makes at a table (no measured figure is quoted that this repo cannot back).
//          Since the proof plan's package 4 tuned the numbers and made generation two the default (21-Nov-2026), every
//          case passes on the default physics and none is marked as an expected failure any more. The same
//          setups run inside BreakProbe's "sweep" command (Sources/BreakProbe/RealWorldCases.swift, a copy kept in
//          step by hand because a test target cannot be imported by a tool), which tries the guessed numbers on a
//          grid and reports which combination passes the most bands.
// Edited: Claude Opus 5.5 High, 21-November-2026 (package 4: the expected-failure wrappers removed; all eleven pass.)
// SRP/DRY check: Pass - checked PhysicsTests, PocketTests, JumpTests and SpecItemTests: those check the solver
//          against its own equations; these check it against the table. The thirty-degree rule appears in both
//          SpecItemTests (item 2, on oracle numbers) and here (case 4, on the real numbers), on purpose.
import BreakdownLensModel
import BreakdownTimeline
@testable import BreakdownPhysics
import Foundation
import XCTest

final class RealWorldTests: XCTestCase {
    /// Default numbers on physics generation two.
    private var p: PoolParameters {
        var q = PoolParameters()
        q.modelGeneration = 2
        return q
    }

    private func layout(_ balls: [Int: Vec2]) -> [Vec2] {
        var out = [Vec2](repeating: NextShot.offTable, count: 16)
        for (k, v) in balls { out[k] = v }
        return out
    }

    private func solve(_ q: PoolParameters, _ balls: [Int: Vec2], dir: Vec2 = Vec2(1, 0), speed: Double,
                       up: Double = 0, side: Double = 0, elevation: Double = 0) -> Timeline {
        PoolSolver.simulate(ShotInput(parameters: q, positions: layout(balls),
                                      strike: CueStrike(direction: dir, speed: speed, tipUp: up, tipSide: side,
                                                        elevation: elevation), seed: 1))
    }

    private func degrees(_ a: Vec2, _ b: Vec2) -> Double {
        acos(max(-1, min(1, a.dot(b) / (a.length * b.length)))) * 180 / Double.pi
    }

    /// Where the cue ball would come to rest after its first hit on another ball, measured along +x from `from`, if
    /// nothing touched it again. Read off the recording at the moment its slide after the hit ends: if it is rolling
    /// then, it rolls on in a straight line and stops after v^2 / (2 c_r g) (the solver's rolling law, checked in
    /// PhysicsTests.testRollingStopDistance). Used for the stop and draw shots, whose object ball comes back off the
    /// far rail and could meet the cue ball before it stops. Nil when the cue ball hit nothing, or something else
    /// touched it before its slide ended.
    private func travelAfterHit(_ tl: Timeline, from: Double, _ q: PoolParameters) -> Double? {
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

    // MARK: 1. Roll distance

    // A lag: a centre-ball stroke from the head rail just hard enough to die at the far rail, one table length. On a
    // real table such a lag takes roughly six to ten seconds from the stroke to rest, which any player can time with a
    // stopwatch. The band comes from the rolling resistance range the spec gives for pool cloth (3.4: 0.005 to 0.015):
    // a ball rolling a distance D at constant drag c_r g takes T = sqrt(2 D / (c_r g)), which for D = 2.54 m is 10.2 s
    // at 0.005 and 5.8 s at 0.015. Band 5.5 to 10.5 s (a little room for the short slide at the start). Constrains
    // rolling drag.
    func testCase01LagDiesAtTheFarRailAfterOneLength() {
        let q = p, r = q.ballRadius
        let start = Vec2(r + 0.02, q.tableWidth / 2)
        let target = q.tableLength - r - 0.02
        func lag(_ v: Double) -> (x: Double, time: Double, railed: Bool) {
            let tl = solve(q, [0: start], speed: v)
            return (tl.state(ball: 0, at: tl.duration + 1).position.x, tl.duration, tl.events.contains { $0.kind == .cushion })
        }
        // The strongest stroke that stops short of the far rail, by bisection on speed.
        var lo = 0.2, hi = 3.0
        for _ in 0..<40 {
            let mid = (lo + hi) / 2
            let s = lag(mid)
            if s.railed || s.x > target { hi = mid } else { lo = mid }
        }
        let best = lag(lo)
        print(String(format: "REAL 1 lag: %.3f m/s stops %.3f m short of the far rail after %.2f s", lo,
                     q.tableLength - r - best.x, best.time))
        XCTAssertFalse(best.railed)
        XCTAssertEqual(best.x, target, accuracy: 0.01, "the bisection did not find the lag")
        XCTAssertGreaterThanOrEqual(best.time, 5.5)
        XCTAssertLessThanOrEqual(best.time, 10.5)
    }

    // MARK: 2. Stop shot

    // Straight on from one diamond (a quarter of the table's width, 0.3175 m centre to centre): a firm centre-ball hit
    // stops the cue ball dead, a soft one rolls through after the object ball. "Dead" to a player's eye: it finishes
    // within a quarter of a diamond (8 cm) of where it struck. "Rolls through": it carries on at least 10 cm. Why:
    // a centre-ball hit starts with no spin and the cloth builds topspin while it slides; firm, it arrives still
    // mostly sliding and stops; soft, it has turned into a roll and follows. Constrains cloth grip (sliding friction),
    // which sets how quickly a slide turns into a roll.
    // Passes on the default physics since the proof plan's package 4 tuned it (21-Nov-2026).
    func testCase02StopShotStopsDeadAndASoftOneRollsThrough() {
        let q = p, r = q.ballRadius, W = q.tableWidth
        let object = Vec2(1.5, W / 2), cue = Vec2(1.5 - q.tableLength / 8, W / 2)
        let contact = object.x - 2 * r
        let firm = travelAfterHit(solve(q, [0: cue, 1: object], speed: 4.0), from: contact, q)
        let soft = travelAfterHit(solve(q, [0: cue, 1: object], speed: 1.0), from: contact, q)
        print(String(format: "REAL 2 stop shot: firm finishes %+.3f m from the contact spot, soft %+.3f m",
                     firm ?? .nan, soft ?? .nan))
        XCTAssertLessThanOrEqual(abs(firm ?? 9), 0.08)
        XCTAssertGreaterThanOrEqual(soft ?? -9, 0.10)
    }

    // MARK: 3. Draw distance

    // Straight on from one diamond, a firm stroke (3 m/s) well below centre (two fifths of the radius, inside the
    // miscue limit): the cue ball comes back roughly a table width (1.27 m), clearly not a table length (2.54 m).
    // Band 0.6 to 1.9 m back. Constrains cloth grip (how much backspin survives the trip) and the cue strike (how
    // much speed and spin an off-centre hit really gives).
    // Passes on the default physics since the proof plan's package 4 tuned it (21-Nov-2026).
    func testCase03DrawComesBackAboutATableWidth() {
        let q = p, r = q.ballRadius, W = q.tableWidth
        let object = Vec2(1.5, W / 2), cue = Vec2(1.5 - q.tableLength / 8, W / 2)
        let travel = travelAfterHit(solve(q, [0: cue, 1: object], speed: 3.0, up: -0.4 * r), from: object.x - 2 * r, q)
        let back = -(travel ?? 9)
        print(String(format: "REAL 3 draw: comes back %.2f m", back))
        XCTAssertGreaterThanOrEqual(back, 0.6)
        XCTAssertLessThanOrEqual(back, 1.9)
    }

    // MARK: 4. The thirty-degree rule

    // A rolling cue ball that cuts an object ball anywhere from a three-quarter-ball hit to a thin hit ends up
    // travelling about thirty degrees off its old line, measured once it rolls again: the rule players use to see
    // where the cue ball goes. Spec 9.1 item 2 gives the band, 25 to 40 degrees; here on the real numbers (restitution
    // 0.95 and ball-ball friction), over cut angles of 20 to 45 degrees. Constrains ball-to-ball grip and restitution.
    func testCase04ThirtyDegreeRule() {
        let q = p, r = q.ballRadius
        let cue = Vec2(0.5, 0.6)
        for cut in Swift.stride(from: 20.0, through: 45.0, by: 5.0) {
            let phi = cut * Double.pi / 180
            let object = Vec2(cue.x + 0.3 + 2 * r * cos(phi), cue.y + 2 * r * sin(phi))
            let tl = solve(q, [0: cue, 1: object], speed: 1.5, up: 0.4 * r)
            guard let hit = tl.events.first(where: { $0.kind == .ballBall }),
                  let mine = hit.balls.first(where: { $0.ball == 0 }),
                  let rolls = tl.events.first(where: { $0.time > hit.time && $0.kind == .phaseTransition
                                                        && $0.balls.first?.ball == 0 && $0.phaseTo == .rolling }) else {
                XCTFail("cut \(cut): no hit, or the cue ball never rolled again"); continue
            }
            let turn = degrees(rolls.balls[0].velocityAfter, mine.velocityBefore)
            print(String(format: "REAL 4 thirty-degree rule: cut %.0f deg, cue ball turns %.1f deg", cut, turn))
            XCTAssertGreaterThanOrEqual(turn, 25, "cut \(cut)")
            XCTAssertLessThanOrEqual(turn, 40, "cut \(cut)")
        }
    }

    // MARK: 5. Throw

    // A half-ball cut (thirty degrees) played softly: friction between the balls drags the object ball a few degrees
    // off the line of centres. Hit hard, the balls part before friction can do as much, so it is thrown less. With
    // the right side spin the cue ball's surface rolls across the object ball instead of rubbing it, and the throw
    // disappears. Players see all three when they cut a ball close to a rail. Bands: soft (0.8 m/s) thrown 2 to 7
    // degrees, from the ball-ball friction formula of spec 3.3: the friction impulse is at most mu J_n, about
    // (0.08 to 0.09) of the normal impulse at that slip, so the throw is about atan(0.085) = 4.9 degrees; hard
    // (4 m/s) thrown less than soft; some side spin between minus and plus nine tenths of half the radius leaves less
    // than one degree. Constrains ball-to-ball grip.
    func testCase05ThrowIsSmallerWhenHardAndSideSpinCancelsIt() {
        let q = p, r = q.ballRadius
        let cue = Vec2(0.5, 0.6)
        let phi = 30 * Double.pi / 180
        let object = Vec2(cue.x + 0.3 + 2 * r * cos(phi), cue.y + 2 * r * sin(phi))
        func throwAngle(_ speed: Double, side: Double) -> Double? {
            let tl = solve(q, [0: cue, 1: object], speed: speed, side: side)
            guard let hit = tl.events.first(where: { $0.kind == .ballBall }),
                  let it = hit.balls.first(where: { $0.ball == 1 }) else { return nil }
            return degrees(it.velocityAfter, hit.balls.first?.ball == 0 ? hit.normal : hit.normal * -1)
        }
        let soft = throwAngle(0.8, side: 0) ?? 0, hard = throwAngle(4.0, side: 0) ?? 0
        var cancelled = 90.0
        for k in -18...18 {
            if let t = throwAngle(0.8, side: Double(k) * 0.025 * r) { cancelled = min(cancelled, t) }
        }
        print(String(format: "REAL 5 throw: soft %.2f deg, hard %.2f deg, least with side spin %.2f deg", soft, hard, cancelled))
        XCTAssertGreaterThanOrEqual(soft, 2)
        XCTAssertLessThanOrEqual(soft, 7)
        XCTAssertLessThan(hard, soft)
        XCTAssertLessThan(cancelled, 1)
    }

    // MARK: 6. Rail speed loss

    // A ball rolled straight into a rail keeps a little under half of its energy at medium pace (2 m/s), and a
    // smaller share when it is hit hard (6 m/s): rubber is livelier when struck gently, which is why a hard bank
    // comes up short. Measured as the share of the ball's kinetic and spin energy that it still has just after the
    // rail. Bands: 0.35 to 0.5 at medium pace; at hard pace at most nine tenths of the medium share. Constrains rail
    // bounce (restitution and how it falls with speed).
    // Passes on the default physics since the proof plan's package 4 tuned it (21-Nov-2026).
    func testCase06RailKeepsLessThanHalfTheEnergyAndLessWhenHard() {
        let q = p, r = q.ballRadius
        func share(_ speed: Double) -> Double {
            let tl = solve(q, [0: Vec2(q.tableLength - 0.6, q.tableWidth / 2)], speed: speed, up: 0.4 * r)
            guard let hit = tl.events.first(where: { $0.kind == .cushion }) else { return .nan }
            return hit.balls[0].energyAfter / hit.balls[0].energyBefore
        }
        let medium = share(2), hard = share(6)
        print(String(format: "REAL 6 rail energy kept: medium %.3f, hard %.3f", medium, hard))
        XCTAssertGreaterThanOrEqual(medium, 0.35)
        XCTAssertLessThanOrEqual(medium, 0.5)
        XCTAssertLessThanOrEqual(hard, 0.9 * medium)
    }

    // MARK: 7. Rail angle

    // A naturally rolling ball sent into a rail at forty-five degrees comes off steeper (further from the rail, a
    // shorter rebound) when it is slow, and flatter (a longer rebound) when it is fast. The rail's grip takes speed
    // along the rail, which steepens the rebound; at high pace the rail also loses more of the speed into it, which
    // flattens it. Measured as the angle between the ball's path and the rail just after it leaves the rail. Bands:
    // slow (1 m/s) above 45 degrees; fast (5 m/s) below 45 degrees. Constrains rail grip and rail bounce together.
    // Passes on the default physics since the proof plan's package 4 tuned it (21-Nov-2026).
    func testCase07RailAngleSteeperWhenSlowLongerWhenFast() {
        let q = p, r = q.ballRadius
        func exitAngle(_ speed: Double) -> Double {
            let tl = solve(q, [0: Vec2(0.6, 0.45)], dir: Vec2(1, -1), speed: speed, up: 0.4 * r)
            guard let hit = tl.events.first(where: { $0.kind == .cushion }) else { return .nan }
            let v = hit.balls[0].velocityAfter
            return atan2(abs(v.y), abs(v.x)) * 180 / Double.pi
        }
        let slow = exitAngle(1), fast = exitAngle(5)
        print(String(format: "REAL 7 rail angle off the rail: slow %.1f deg, fast %.1f deg", slow, fast))
        XCTAssertGreaterThan(slow, 45)
        XCTAssertLessThan(fast, 45)
    }

    // MARK: 8. Lengths of the table

    // A ball struck at break pace (10 m/s, the middle of the spec's 8 to 13 m/s break range) straight up and down the
    // table with nothing in its way travels about four to five table lengths before it stops: a familiar sight when a
    // player hits a lone ball hard. Measured as the length of its whole path. Band 3.5 to 5.5 lengths. Constrains
    // rail bounce at high pace (most of the energy goes at the rails) and rolling drag.
    // Passes on the default physics since the proof plan's package 4 tuned it (21-Nov-2026).
    func testCase08HardBallTravelsFourToFiveLengths() {
        let q = p, r = q.ballRadius
        let tl = solve(q, [0: Vec2(r + 0.03, q.tableWidth / 2)], speed: 10)
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
        print(String(format: "REAL 8 a hard ball travels %.2f table lengths", lengths))
        XCTAssertGreaterThanOrEqual(lengths, 3.5)
        XCTAssertLessThanOrEqual(lengths, 5.5)
    }

    // MARK: 9. Spin-down

    // A ball spinning like a top at a brisk rate (at least 20 radians a second, about three turns a second) stops
    // spinning within a handful of seconds, not in a blink and not for half a minute: watch a ball struck with
    // heavy side, or one spun by hand on the cloth. Band 1.5 to 8 seconds. In the model the vertical spin falls at
    // the same constant rate whatever the ball is doing on the cloth (spec 3.1), so a ball struck slowly with side
    // shows the same spin-down as one spinning in place, and it is easier to set up. Constrains spin decay.
    func testCase09BriskSpinDiesInAHandfulOfSeconds() {
        let q = p, r = q.ballRadius
        let tl = solve(q, [0: Vec2(0.15, q.tableWidth / 2)], speed: 0.8, side: 0.45 * r)
        let w0 = abs(tl.segments[0][0].omega0.z)
        XCTAssertGreaterThanOrEqual(w0, 20, "the stroke should start a brisk spin")
        var lo = 0.0, hi = 60.0
        for _ in 0..<60 {
            let mid = (lo + hi) / 2
            if tl.state(ball: 0, at: mid).omega.z != 0 { lo = mid } else { hi = mid }
        }
        XCTAssertFalse(tl.events.contains { $0.kind == .cushion && $0.time < hi }, "the ball met a rail while spinning")
        print(String(format: "REAL 9 spin of %.1f rad/s dies after %.2f s", w0, hi))
        XCTAssertGreaterThanOrEqual(hi, 1.5)
        XCTAssertLessThanOrEqual(hi, 8)
    }

    // MARK: 10. Squirt and speed lost to an off-centre hit

    // Side spin pushes the cue ball off the line of the cue, away from the side struck (right-hand side sends it a
    // little left), by about two to three degrees at half the radius on a standard shaft (one to two on the stiffer
    // low-deflection kind): spec 3.3's figures, which players learn as "aim off a little with side". Band 1 to 3.5
    // degrees, to the left for right side. And an off-centre hit gives the ball less speed than a centre hit with the
    // same stroke, because part of the push goes into spin: at half the radius the strike formula of spec 3.3,
    // (M + m) / (M + m + 5/2 M x^2), gives 0.68 for cues of 0.5 to 0.6 kg. Band 0.6 to 0.8 of the centre-hit speed.
    // Passes on the default physics since the proof plan's package 4 tuned it (21-Nov-2026).
    func testCase10SideSpinSquirtsAndOffCentreHitsAreSlower() {
        let q = p, r = q.ballRadius
        let start = [0: Vec2(0.5, q.tableWidth / 2)]
        let right = solve(q, start, speed: 2, side: 0.5 * r).segments[0][0].velocity0
        let turn = atan2(right.y, right.x) * 180 / Double.pi
        let centre = solve(q, start, speed: 2).segments[0][0].velocity0.length
        let high = solve(q, start, speed: 2, up: 0.5 * r).segments[0][0].velocity0.length
        print(String(format: "REAL 10 squirt %.2f deg (positive is left), off-centre speed share %.3f", turn, high / centre))
        XCTAssertGreaterThanOrEqual(turn, 1)
        XCTAssertLessThanOrEqual(turn, 3.5)
        XCTAssertGreaterThanOrEqual(high / centre, 0.6)
        XCTAssertLessThanOrEqual(high / centre, 0.8)
    }

    // MARK: 11. Jump height

    // A steep, hard, centre-ball stroke (cue raised to sine 0.75, about 49 degrees, at 6 m/s) jumps a ball sitting one
    // ball-width in front of the cue ball; the same stroke with the cue only slightly raised (sine 0.15) runs into it.
    // Players learn this as "jump cue up steep, hit down hard". Worked out from the slate bounce (restitution 0.5): the
    // steep stroke leaves the cloth at 2.25 m/s upward and about 2.8 m/s forward and is 6 to 7 cm up as it passes over
    // the ball in the way (it needs 5.7 cm); the shallow one rises at most a centimetre. Constrains the slate's bounce.
    func testCase11SteepJumpClearsABallAShallowOneDoesNot() {
        let q = p, r = q.ballRadius, W = q.tableWidth
        let cue = Vec2(0.6, W / 2), blocker = Vec2(0.6 + 4 * r, W / 2)
        func touches(_ tl: Timeline) -> LensEvent? {
            tl.events.first { $0.kind == .ballBall && Set($0.balls.map(\.ball)) == [0, 1] }
        }
        let steep = solve(q, [0: cue, 1: blocker], speed: 6, elevation: 0.75)
        let over = steep.events.first { $0.flight == .landing && $0.balls.first?.ball == 0 && $0.point.x > blocker.x + 2 * r }
        XCTAssertNotNil(over, "the steep stroke should land beyond the blocker")
        XCTAssertGreaterThan(touches(steep)?.time ?? .infinity, over?.time ?? 0, "the steep stroke hit the blocker on the way")
        let shallow = solve(q, [0: cue, 1: blocker], speed: 6, elevation: 0.15)
        let hit = touches(shallow)
        XCTAssertNotNil(hit, "the shallow stroke should run into the blocker")
        XCTAssertLessThan(hit?.point.x ?? 9, blocker.x)
        print("REAL 11 jump: steep clears the blocker \(over != nil), shallow hits it \(hit != nil)")
    }
}
