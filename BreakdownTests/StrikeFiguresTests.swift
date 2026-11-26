// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The strike panel's figures (plans/25-Nov-2026-strike-panel-and-controls-plan.md, stage 1, StrikeFigures):
//          a centre hit leaves at the launch speed; an off-centre hit leaves slower; the push is mass times speed; a
//          centre hit has no spin; planned and delivered are equal when the stroke adds no error. Also pins the
//          figures' mirror of the solver's launch against the solver's own recorded strike (speed, push and spin on the
//          cue-strike event), so the panel cannot drift from the physics, and checks the cut, the miscue and the
//          largest-error pick the phone's line uses.
// SRP/DRY check: Pass - checks only; every expected value is read from PoolParameters or the solver's own recording.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import XCTest

final class StrikeFiguresTests: XCTestCase {
    private let p = PoolParameters()

    /// A cue ball in the middle of the table and nothing else on it (unused balls off the table).
    private var lonelyLayout: [Vec2] {
        var layout = Array(repeating: Vec2(-1, -1), count: 16)
        layout[0] = Vec2(p.tableLength * 0.3, p.tableWidth * 0.5)
        return layout
    }

    private func figures(speed: Double, up: Double = 0, side: Double = 0, elevation: Double = 0,
                         direction: Vec2 = Vec2(1, 0)) -> StrikeFigures {
        StrikeFigures.make(strike: CueStrike(direction: direction, speed: speed, tipUp: up, tipSide: side,
                                             elevation: elevation),
                           swing: CueProfile.swing(forPower: speed), parameters: p)
    }

    // MARK: The plan's five

    func testCentreHitLeavesAtTheLaunchSpeed() {
        let f = figures(speed: 3)
        XCTAssertEqual(f.leaves, 3, accuracy: 1e-12)
        XCTAssertEqual(f.centreSpeed, 3)
        XCTAssertFalse(f.miscue)
    }

    func testOffCentreHitLeavesSlower() {
        let centre = figures(speed: 3)
        let off = figures(speed: 3, up: 0.01, side: 0.005)
        XCTAssertLessThan(off.leaves, centre.leaves)
        // The factor beside cueMass in Parameters.swift, worked out here by hand.
        let b2 = 0.01 * 0.01 + 0.005 * 0.005
        let big = p.cueMass + p.ballMass
        XCTAssertEqual(off.leaves, 3 * big / (big + 2.5 * p.cueMass * b2 / (p.ballRadius * p.ballRadius)), accuracy: 1e-12)
    }

    func testPushIsMassTimesSpeed() {
        for f in [figures(speed: 2), figures(speed: 4.5, up: -0.008), figures(speed: 1.2, side: 0.01, elevation: 0.3)] {
            XCTAssertEqual(f.push, p.ballMass * f.leaves, accuracy: 1e-12)
            // The force is that push over the tip's contact time, and it is the only estimate on the panel.
            XCTAssertEqual(f.force, f.push / StrikeFigures.tipContactTime, accuracy: 1e-9)
        }
    }

    func testCentreHitHasNoSpin() {
        let f = figures(speed: 3)
        XCTAssertEqual(f.topSpin, 0)
        XCTAssertEqual(f.sideSpin, 0)
        // All its energy is motion: half m v squared.
        XCTAssertEqual(f.energy, 0.5 * p.ballMass * 9, accuracy: 1e-12)
        XCTAssertEqual(f.turnDegrees, 0, accuracy: 1e-12)
    }

    func testPlannedAndDeliveredAreEqualWithNoStrokeError() {
        let strike = CueStrike(direction: Vec2(0.6, 0.8), speed: 2.5, tipUp: -0.006, tipSide: 0.004, elevation: 0.1)
        var delivered = strike
        StrokeDelivery(aimError: 0, tipSideError: 0, swing: 2, calmTopSwing: 3, fullPower: false, bridge: 0.15,
                       record: nil).apply(to: &delivered, ballRadius: p.ballRadius)
        let swing = CueProfile.swing(forPower: 2.5)
        let comparison = StrikeComparison(
            planned: StrikeFigures.make(strike: strike, swing: swing, parameters: p, layout: lonelyLayout, table: nil),
            delivered: StrikeFigures.make(strike: delivered, swing: swing, parameters: p, layout: lonelyLayout, table: nil))
        XCTAssertEqual(comparison.planned, comparison.delivered)
        XCTAssertFalse(comparison.anyDiffers)
        XCTAssertNil(comparison.largestError)
    }

    // MARK: Against the solver itself

    /// The figures' launch mirror must agree with what the solver records on its cue-strike event: the ball's speed
    /// just after, the push (normalImpulse) and the spin, for a level strike inside the grip.
    func testFiguresMatchTheSolversOwnStrike() {
        let up = 0.009, side = -0.006, speed = 2.8
        let input = NextShot.shot(from: lonelyLayout, direction: Vec2(1, 0), speed: speed, tipUp: up, tipSide: side,
                                  seed: 7, parameters: p)
        let timeline = PoolSolver.simulate(input)
        guard let event = timeline.events.first(where: { $0.kind == .cueStrike }), let ball = event.balls.first else {
            return XCTFail("the solver recorded no strike")
        }
        let f = StrikeFigures.make(strike: input.strike, swing: CueProfile.swing(forPower: speed), parameters: p)
        XCTAssertEqual(f.leaves, ball.velocityAfter.length, accuracy: 1e-9)
        XCTAssertEqual(f.push, event.normalImpulse, accuracy: 1e-9)
        // Aim along +x: the top-spin axis is y (omega.y = k * tipUp) and side spin is about the vertical (omega.z).
        XCTAssertEqual(f.topSpin * 2 * Double.pi, ball.omegaAfter.y, accuracy: 1e-6)
        XCTAssertEqual(f.sideSpin * 2 * Double.pi, ball.omegaAfter.z, accuracy: 1e-6)
    }

    // MARK: Miscue, angle and cut

    func testPastTheGripMiscues() {
        let limit = p.miscueOffsetLimit
        let f = figures(speed: 3, up: limit * 1.1)
        XCTAssertTrue(f.miscue)
        XCTAssertEqual(f.leaves, 3 * p.miscueSpeedFraction, accuracy: 1e-12)
        // The tip shown is where it was aimed, not where it slid to.
        XCTAssertEqual(f.tipUp, limit * 1.1, accuracy: 1e-12)
    }

    func testCueAngleIsInDegrees() {
        XCTAssertEqual(figures(speed: 2, elevation: sin(30 * Double.pi / 180)).cueAngle, 30, accuracy: 1e-9)
        XCTAssertEqual(figures(speed: 2).cueAngle, 0)
    }

    func testFullBallHasNoCutAndNoBallMeansNoCut() {
        var layout = lonelyLayout
        let table = PoolSolver.simulate(NextShot.shot(from: layout, direction: Vec2(1, 0), speed: 0.01, tipUp: 0,
                                                      tipSide: 0, seed: 1, parameters: p)).table
        let strike = CueStrike(direction: Vec2(1, 0), speed: 2)
        XCTAssertNil(StrikeFigures.make(strike: strike, swing: 1, parameters: p, layout: layout, table: table).cut)
        layout[5] = layout[0] + Vec2(0.5, 0)
        let full = StrikeFigures.make(strike: strike, swing: 1, parameters: p, layout: layout, table: table)
        XCTAssertEqual(full.cut ?? -1, 0, accuracy: 1e-6)
        XCTAssertEqual(full.cutBall, 5)
        // Half a ball's width off line (one radius): a thirty-degree cut.
        layout[5] = layout[0] + Vec2(0.5, p.ballRadius)
        let half = StrikeFigures.make(strike: strike, swing: 1, parameters: p, layout: layout, table: table)
        XCTAssertEqual(half.cut ?? -1, 30, accuracy: 1e-6)
    }

    // MARK: The phone's one line

    func testLargestErrorPicksTheBiggerSlip() {
        let swing = 1.5
        let planned = StrikeFigures.make(strike: CueStrike(direction: Vec2(1, 0), speed: 2), swing: swing, parameters: p)
        // A full degree of turn outweighs a millimetre of tip (a half degree counts as much as a millimetre).
        let turned = CueStrike(direction: Vec2(cos(Double.pi / 180), sin(Double.pi / 180)), speed: 2, tipSide: -0.001)
        let a = StrikeComparison(planned: planned,
                                 delivered: StrikeFigures.make(strike: turned, swing: swing, parameters: p))
        guard case .aim(let degrees)? = a.largestError else { return XCTFail("expected the aim") }
        XCTAssertEqual(degrees, 1, accuracy: 1e-9)
        // Three millimetres of tip outweighs a tenth of a degree.
        let slid = CueStrike(direction: Vec2(cos(0.1 * Double.pi / 180), sin(0.1 * Double.pi / 180)), speed: 2,
                             tipSide: 0.003)
        let b = StrikeComparison(planned: planned, delivered: StrikeFigures.make(strike: slid, swing: swing, parameters: p))
        guard case .tip(let metres)? = b.largestError else { return XCTFail("expected the tip") }
        XCTAssertEqual(metres, 0.003, accuracy: 1e-12)
        XCTAssertTrue(b.differs(.tipSide))
        XCTAssertTrue(b.differs(.sideSpin))
        XCTAssertFalse(b.differs(.swing))
    }
}
