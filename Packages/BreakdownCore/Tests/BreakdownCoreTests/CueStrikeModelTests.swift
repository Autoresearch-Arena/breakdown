// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Checks for the generation-two cue strike (plans/21-Nov-2026-cue-strike-plan.md; spec 3.3 and test 12 of
//          section 9.1). Spec 12: follow, draw, left and right spin the right way, a centre hit gives no spin, the launch
//          speed matches the strike formula at five offsets, and the miscue limit sits where the formula says at three
//          elevations. Deflection: none at centre or from top and bottom alone, away from the struck side, growing with
//          offset, two to three degrees at half the radius. Miscue: the same seed gives the same miscue, different seeds
//          differ, the speed is cut. The strike hits CueStrike.ballIndex at both generations, generation one strikes as
//          it always did, and the aim guide's launch direction is the direction the solver really launches.
// SRP/DRY check: Pass - checked PhysicsSwitchTests (the starting values' reasons) and JumpTests (raised strikes on
//          generation 1). These are the generation-two strike checks; the proof stream may write spec 12 as an expected
//          failure, and this file holds the real test (the coordinator keeps one copy).
import BreakdownLensModel
import BreakdownTimeline
@testable import BreakdownPhysics
import Foundation
import XCTest

final class CueStrikeModelTests: XCTestCase {
    private var p2: PoolParameters {
        var p = PoolParameters()
        p.modelGeneration = PoolParameters.newestGeneration
        return p
    }

    private func lone(_ at: Vec2 = Vec2(0.6, 0.635)) -> [Vec2] { [at] + [Vec2](repeating: NextShot.offTable, count: 15) }

    /// The cue-strike event of a lone ball struck along +x.
    private func strike(_ s: CueStrike, _ p: PoolParameters, seed: UInt64 = 1) -> LensEvent {
        let tl = PoolSolver.simulate(ShotInput(parameters: p, positions: lone(), strike: s, seed: seed))
        return tl.events.first { $0.kind == .cueStrike }!
    }

    /// The strike formula divided by its centre value: (M + m) / (M + m + 5/2 M b^2 / R^2).
    private func factor(_ b2: Double, _ p: PoolParameters) -> Double {
        let big = p.cueMass + p.ballMass
        return big / (big + 2.5 * p.cueMass * b2 / (p.ballRadius * p.ballRadius))
    }

    // Spec 12, spin directions. Aim +x. Follow spins forward (omega.y > 0: the rolling direction for +x travel), draw
    // backward; a hit right of centre spins counter-clockwise seen from above (omega.z > 0: the torque r x J of a forward
    // push on the ball's right side points up), left clockwise; a centre hit gives no spin at all.
    func testSpinDirections() {
        let p = p2, R = p.ballRadius, V = 2.0
        XCTAssertGreaterThan(strike(CueStrike(direction: Vec2(1, 0), speed: V, tipUp: 0.3 * R), p).balls[0].omegaAfter.y, 0)
        XCTAssertLessThan(strike(CueStrike(direction: Vec2(1, 0), speed: V, tipUp: -0.3 * R), p).balls[0].omegaAfter.y, 0)
        XCTAssertGreaterThan(strike(CueStrike(direction: Vec2(1, 0), speed: V, tipSide: 0.3 * R), p).balls[0].omegaAfter.z, 0)
        XCTAssertLessThan(strike(CueStrike(direction: Vec2(1, 0), speed: V, tipSide: -0.3 * R), p).balls[0].omegaAfter.z, 0)
        let centre = strike(CueStrike(direction: Vec2(1, 0), speed: V), p)
        XCTAssertEqual(centre.balls[0].omegaAfter, .zero)
        XCTAssertEqual(centre.miscue, false)
        XCTAssertEqual(centre.deflectionSine, 0)
    }

    // Spec 12, launch speed: the strike formula at five offsets (centre, small, a quarter, 0.4 and half the radius,
    // mixing height and side), to 1e-12 relative.
    func testLaunchSpeedMatchesTheStrikeFormula() {
        let p = p2, R = p.ballRadius, V = 3.0
        let offsets: [(Double, Double)] = [(0, 0), (0.1 * R, 0), (0, -0.25 * R), (0.24 * R, 0.32 * R), (-0.3 * R, -0.4 * R)]
        for (up, side) in offsets {
            let e = strike(CueStrike(direction: Vec2(1, 0), speed: V, tipUp: up, tipSide: side), p)
            let expected = V * factor(up * up + side * side, p)
            XCTAssertEqual(e.balls[0].velocityAfter.length, expected, accuracy: 1e-12 * V, "offset (\(up), \(side))")
            XCTAssertEqual(e.normalImpulse, p.ballMass * expected, accuracy: 1e-12)
            XCTAssertEqual(e.miscue, false)
            // The spin is the old formula at the reduced speed: |omega| = 5/2 * v * b / R^2.
            let b = (up * up + side * side).squareRoot()
            XCTAssertEqual(e.balls[0].omegaAfter.length, 2.5 * expected * b / (R * R), accuracy: 1e-9)
        }
    }

    // Spec 12, the miscue limit: offset / R = mu / sqrt(1 + mu^2), at three elevations. Just inside it the tip grips,
    // just outside it slips, whichever way the offset points.
    func testMiscueLimitSitsWhereTheFormulaSays() {
        let p = p2, R = p.ballRadius
        let limit = R * p.tipGrip / (1 + p.tipGrip * p.tipGrip).squareRoot()
        XCTAssertEqual(p.miscueOffsetLimit, limit, accuracy: 1e-15)
        for elevation in [0.0, 0.3, 0.6] {
            for (ux, sx) in [(1.0, 0.0), (0.0, 1.0), (-0.6, 0.8)] {
                let inside = strike(CueStrike(direction: Vec2(1, 0), speed: 2, tipUp: ux * limit * 0.999,
                                              tipSide: sx * limit * 0.999, elevation: elevation), p)
                let outside = strike(CueStrike(direction: Vec2(1, 0), speed: 2, tipUp: ux * limit * 1.001,
                                               tipSide: sx * limit * 1.001, elevation: elevation), p)
                XCTAssertEqual(inside.miscue, false, "elevation \(elevation), direction (\(ux), \(sx))")
                XCTAssertEqual(outside.miscue, true, "elevation \(elevation), direction (\(ux), \(sx))")
            }
        }
    }

    // Deflection ("squirt"): none at centre, none from height alone, away from the struck side, growing with the side
    // offset up to the limit, and two to three degrees at half the radius.
    func testSideSpinDeflection() {
        let p = p2, R = p.ballRadius
        XCTAssertEqual(strike(CueStrike(direction: Vec2(1, 0), speed: 2, tipUp: 0.45 * R), p).deflectionSine, 0)
        XCTAssertEqual(strike(CueStrike(direction: Vec2(1, 0), speed: 2, tipUp: -0.45 * R), p).deflectionSine, 0)
        var last = 0.0
        for x in [0.1, 0.2, 0.3, 0.4, 0.5] {
            let right = strike(CueStrike(direction: Vec2(1, 0), speed: 2, tipSide: x * R), p)
            let left = strike(CueStrike(direction: Vec2(1, 0), speed: 2, tipSide: -x * R), p)
            let sine = right.deflectionSine ?? 0
            // Struck on the right, the ball goes left of the aim (+y, counter-clockwise), and the event's velocity agrees.
            XCTAssertGreaterThan(sine, last)
            XCTAssertGreaterThan(right.balls[0].velocityAfter.y, 0)
            XCTAssertEqual(left.deflectionSine ?? 0, -sine, accuracy: 1e-15)
            XCTAssertLessThan(left.balls[0].velocityAfter.y, 0)
            let v = right.balls[0].velocityAfter
            XCTAssertEqual(v.y / v.length, sine, accuracy: 1e-12)
            last = sine
        }
        let degrees = asin(last) * 180 / Double.pi
        print(String(format: "CUE deflection at half the radius: %.3f degrees", degrees))
        XCTAssertGreaterThanOrEqual(degrees, 2)
        XCTAssertLessThanOrEqual(degrees, 3)
    }

    // Miscue: repeatable from the seed, different for different seeds, slower, and its turn within the stated range.
    func testMiscueIsSeededAndSlow() {
        let p = p2, R = p.ballRadius
        let s = CueStrike(direction: Vec2(1, 0), speed: 4, tipUp: 0.1 * R, tipSide: 0.65 * R)
        let a = strike(s, p, seed: 11), b = strike(s, p, seed: 11)
        XCTAssertEqual(a.miscue, true)
        XCTAssertEqual(a.deflectionSine, b.deflectionSine)
        XCTAssertEqual(a.balls[0].velocityAfter, b.balls[0].velocityAfter)
        let sines = Set((1...12).map { strike(s, p, seed: UInt64($0)).deflectionSine ?? 0 })
        XCTAssertGreaterThan(sines.count, 6, "different seeds should give different miscues")
        let maxSine = p.miscueMaxDeflection / (1 + p.miscueMaxDeflection * p.miscueMaxDeflection).squareRoot()
        for sine in sines { XCTAssertLessThanOrEqual(abs(sine), maxSine + 1e-15) }
        XCTAssertEqual(a.balls[0].velocityAfter.length, 4 * p.miscueSpeedFraction, accuracy: 1e-12)
        // Less spin than a good hit at the limit with the full stroke would give.
        let limit = p.miscueOffsetLimit
        XCTAssertLessThan(a.balls[0].omegaAfter.length, 2.5 * 4 * limit / (R * R))
        // The whole recording repeats from the same seed.
        let input = ShotInput(parameters: p, positions: lone(), strike: s, seed: 11)
        XCTAssertEqual(PoolSolver.simulate(input).contentHash, PoolSolver.simulate(input).contentHash)
    }

    // A raised cue: the same speed factor and miscue rule; the turn is in the table plane only.
    func testRaisedStrikeUsesTheSameLaunch() {
        let p = p2, R = p.ballRadius
        let e = 0.3
        let s = CueStrike(direction: Vec2(1, 0), speed: 2, tipUp: 0.1 * R, tipSide: 0.3 * R, elevation: e)
        let launch = PoolSolver.cueLaunch(s, p, seed: 1)
        XCTAssertEqual(launch.speed, 2 * factor(0.01 * R * R + 0.09 * R * R, p), accuracy: 1e-12)
        XCTAssertFalse(launch.miscue)
        let ev = strike(s, p)
        XCTAssertEqual(ev.normalImpulse, p.ballMass * launch.speed, accuracy: 1e-12)
        XCTAssertEqual(ev.deflectionSine ?? 0, launch.deflectionSine, accuracy: 1e-15)
        XCTAssertEqual(launch.direction.length, 1, accuracy: 1e-15)
        XCTAssertGreaterThan(launch.deflectionSine, 0, "struck on the right, it turns left in the table plane")
    }

    // Generation one strikes exactly as before: full speed, straight along the cue, and no generation-two flags.
    func testGenerationOneStrikeIsUnchanged() {
        let p = PoolParameters(), R = p.ballRadius
        let e = strike(CueStrike(direction: Vec2(1, 0), speed: 3, tipUp: 0.2 * R, tipSide: 0.7 * R), p)
        XCTAssertEqual(e.balls[0].velocityAfter, Vec2(3, 0))
        XCTAssertNil(e.miscue)
        XCTAssertNil(e.deflectionSine)
        XCTAssertEqual(e.normalImpulse, p.ballMass * 3)
    }

    // The strike hits CueStrike.ballIndex at both generations; naming ball 0 is exactly the default.
    func testStrikeHitsTheNamedBall() {
        for p in [PoolParameters(), p2] {
            var pos = lone(Vec2(0.5, 0.4))
            pos[3] = Vec2(1.5, 0.9)
            let named = PoolSolver.simulate(ShotInput(parameters: p, positions: pos,
                                                      strike: CueStrike(direction: Vec2(-1, 0), speed: 0.5, ballIndex: 3), seed: 1))
            let ev = named.events.first { $0.kind == .cueStrike }!
            XCTAssertEqual(ev.balls[0].ball, 3)
            XCTAssertEqual(ev.point, pos[3])
            XCTAssertEqual(named.state(ball: 0, at: named.duration + 1).position, pos[0], "ball 0 was not struck")
            XCTAssertLessThan(named.state(ball: 3, at: named.duration + 1).position.x, pos[3].x)
            let zero = PoolSolver.simulate(ShotInput(parameters: p, positions: pos,
                                                     strike: CueStrike(direction: Vec2(1, 0), speed: 1.5, ballIndex: 0), seed: 1))
            let plain = PoolSolver.simulate(ShotInput(parameters: p, positions: pos,
                                                      strike: CueStrike(direction: Vec2(1, 0), speed: 1.5), seed: 1))
            XCTAssertEqual(zero.contentHash, plain.contentHash)
        }
    }

    // The aim guide's direction is the solver's launch direction: the aim at generation one, the turned direction on
    // generation two (equal to the recorded launch), and the cue's own line for a miscue (its turn is unknowable).
    func testLaunchDirectionForTheAimGuide() {
        let R = PoolParameters().ballRadius
        let s = CueStrike(direction: Vec2(0.6, 0.8), speed: 2, tipSide: 0.4 * R)
        XCTAssertEqual(PoolSolver.launchDirection(for: s, parameters: PoolParameters()), s.direction)
        let guide = PoolSolver.launchDirection(for: s, parameters: p2)
        let tl = PoolSolver.simulate(ShotInput(parameters: p2, positions: lone(), strike: s, seed: 3))
        let v = tl.events.first { $0.kind == .cueStrike }!.balls[0].velocityAfter
        XCTAssertEqual((v.normalized - guide).length, 0, accuracy: 1e-12)
        XCTAssertGreaterThan(s.direction.x * guide.y - s.direction.y * guide.x, 0, "right side turns the ball left")
        let miscue = CueStrike(direction: Vec2(0.6, 0.8), speed: 2, tipSide: 0.7 * R)
        XCTAssertEqual(PoolSolver.launchDirection(for: miscue, parameters: p2), miscue.direction)
    }
}
