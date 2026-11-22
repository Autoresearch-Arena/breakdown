// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: Checks the contact geometry the Lens draws on a held ball-to-ball hit (App/LensContactGeometry.swift,
//          plans/22-Nov-2026-v074-glow-up-plan.md feature G2) and the two zoom pieces the signature close-up uses.
//          Against real solves: the first hit of every authored trick answer (struck ball at rest, both balls on the
//          cloth) gives a geometry whose momentum triangle closes, incoming = striker out + struck ball out, to a
//          thousandth of the incoming speed (equal masses: the solver's impulse is equal and opposite, so this holds
//          with throw and restitution included); the stop-dead answer is not marked square (the cue ball is left almost
//          still). By hand-made events (the solver's balls are slightly inelastic, so a recorded stun cut is square only
//          on thin cuts; the rule itself is tested on exact numbers): outgoing paths exactly square are marked, five
//          degrees off are not, a struck ball already moving is never marked, the striker is found whichever order the
//          event lists the balls in, and an event that is not a two-ball hit has no geometry. Also: the close-up's point
//          for a hit is the contact in the hand zoom's plan coordinates, and TableZoom.closeUp moves the goal off the
//          fitted view by the asked magnification and springBack returns it.
// SRP/DRY check: Pass - checked TrickShotJudgeTests (it judges the same answers; the way a trick is solved, layout or
//          rack, is the same two lines and is repeated here rather than shared, as that file keeps it private) and
//          CaptionEngineTests (captions, not the drawing's geometry). Solving reuses TestShots.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import XCTest

final class LensContactGeometryTests: XCTestCase {
    /// A trick's authored answer solved from its own start, the way TrickShotMode loads it.
    private func solveAnswer(_ shot: TrickShot) -> Timeline {
        let s = shot.solution
        switch shot.setup {
        case .layout(let start):
            return TestShots.shot(from: start, s)
        case .rack(let seed):
            return TestShots.solve(TestShots.breakInput(seed: seed, aimOffset: s.aim, speed: s.power, tipUp: s.tipUp,
                                                        tipSide: s.tipSide))
        }
    }

    /// One ball of a hand-made event with these velocities (no spin, energies left at zero: the geometry reads none).
    private func ball(_ b: Int, before: Vec2, after: Vec2) -> ImpactBall {
        ImpactBall(ball: b, velocityBefore: before, velocityAfter: after, omegaBefore: .zero, omegaAfter: .zero,
                   translationalBefore: 0, rotationalBefore: 0, translationalAfter: 0, rotationalAfter: 0)
    }

    /// A hit of ball 0 at `incoming` on ball 1 at rest along the unit line of centres `n`, with the outgoing velocities
    /// split exactly as a frictionless elastic hit splits them (the struck ball takes the part along n), the striker's
    /// share then turned by `turn` degrees. `strikerFirst` false lists the struck ball first, as the solver may.
    private func hit(incoming: Vec2, n: Vec2, turn: Double = 0, strikerFirst: Bool = true) -> LensEvent {
        let objectOut = n * incoming.dot(n)
        let left = incoming - objectOut
        let a = turn * .pi / 180
        let strikerOut = Vec2(left.x * cos(a) - left.y * sin(a), left.x * sin(a) + left.y * cos(a))
        let striker = ball(0, before: incoming, after: strikerOut)
        let object = ball(1, before: .zero, after: objectOut)
        // The recorded normal points from balls[0] to balls[1].
        return LensEvent(time: 0.5, kind: .ballBall, point: Vec2(1.2, 0.6), normal: strikerFirst ? n : -n,
                         balls: strikerFirst ? [striker, object] : [object, striker])
    }

    // MARK: Real solves

    func testMomentumTriangleClosesOnEveryTrickFirstHit() {
        var checked = 0
        for shot in TrickShots.all where !shot.pending {
            let tl = solveAnswer(shot)
            guard let e = tl.events.first(where: { $0.kind == .ballBall }) else {
                XCTFail("\(shot.id): the answer hits no ball"); continue
            }
            // A hit with a ball in the air bounces off the slate in the same instant, and the slate's grip takes part
            // of the horizontal momentum, so only hits on the cloth must close exactly.
            guard e.height == 0 else { continue }
            guard let g = ContactGeometry.at(e) else { XCTFail("\(shot.id): no geometry for a ball-to-ball hit"); continue }
            XCTAssertFalse(g.objectWasMoving, "\(shot.id): the first ball struck was moving")
            XCTAssertEqual(g.normal.length, 1, accuracy: 1e-9, shot.id)
            XCTAssertGreaterThan(g.incoming.dot(g.normal), 0, "\(shot.id): the line of centres points back at the striker")
            let gap = (g.incoming - (g.strikerOut + g.objectOut)).length
            XCTAssertLessThanOrEqual(gap, 1e-3 * g.incoming.length, "\(shot.id): the momentum triangle is open by \(gap) m/s")
            checked += 1
        }
        XCTAssertGreaterThan(checked, 5, "too few trick answers hit a ball on the cloth to check the triangle")
    }

    func testStopDeadIsNotMarkedSquare() throws {
        let shot = try XCTUnwrap(TrickShots.shot(id: "stop-dead"))
        let tl = solveAnswer(shot)
        let e = try XCTUnwrap(tl.events.first { $0.kind == .ballBall })
        let g = try XCTUnwrap(ContactGeometry.at(e))
        XCTAssertFalse(g.rightAngle, "a full stop shot leaves the cue ball almost still, nothing to square")
    }

    // MARK: Hand-made hits

    func testSquareOutgoingPathsAreMarked() throws {
        let n = Vec2(cos(50 * Double.pi / 180), sin(50 * Double.pi / 180))
        let g = try XCTUnwrap(ContactGeometry.at(hit(incoming: Vec2(2, 0), n: n)))
        XCTAssertTrue(g.rightAngle)
        XCTAssertEqual(g.striker, 0)
        XCTAssertEqual(g.object, 1)
        XCTAssertEqual((g.normal - n).length, 0, accuracy: 1e-12)
        XCTAssertEqual((g.tangent - n.perp).length, 0, accuracy: 1e-12)
        XCTAssertEqual(g.point, Vec2(1.2, 0.6))
    }

    func testFiveDegreesOffSquareIsNotMarked() throws {
        let n = Vec2(cos(50 * Double.pi / 180), sin(50 * Double.pi / 180))
        let g = try XCTUnwrap(ContactGeometry.at(hit(incoming: Vec2(2, 0), n: n, turn: 5)))
        XCTAssertFalse(g.rightAngle)
    }

    func testStrikerIsFoundWhicheverBallIsListedFirst() throws {
        let n = Vec2(cos(-35 * Double.pi / 180), sin(-35 * Double.pi / 180))
        let g = try XCTUnwrap(ContactGeometry.at(hit(incoming: Vec2(1.5, 0.2), n: n, strikerFirst: false)))
        XCTAssertEqual(g.striker, 0)
        XCTAssertEqual(g.object, 1)
        // The line of centres still runs from the striker into the struck ball.
        XCTAssertEqual((g.normal - n).length, 0, accuracy: 1e-12)
        XCTAssertTrue(g.rightAngle)
    }

    func testStruckBallAlreadyMovingIsNeverMarked() throws {
        let n = Vec2(1, 0)
        let e = LensEvent(time: 0.5, kind: .ballBall, point: Vec2(1, 0.6), normal: n,
                          balls: [ball(0, before: Vec2(2, 0), after: Vec2(0, 0.6)),
                                  ball(1, before: Vec2(0.5, 0), after: Vec2(1.6, 0))])
        let g = try XCTUnwrap(ContactGeometry.at(e))
        XCTAssertTrue(g.objectWasMoving)
        XCTAssertFalse(g.rightAngle)
    }

    func testOnlyTwoBallHitsHaveGeometry() {
        let rail = LensEvent(time: 0.5, kind: .cushion, point: Vec2(0, 0.6), normal: Vec2(1, 0),
                             balls: [ball(0, before: Vec2(-1, 0), after: Vec2(0.8, 0))])
        XCTAssertNil(ContactGeometry.at(rail))
        let lone = LensEvent(time: 0.5, kind: .ballBall, point: Vec2(1, 0.6), normal: Vec2(1, 0),
                             balls: [ball(0, before: Vec2(1, 0), after: Vec2(0, 0))])
        XCTAssertNil(ContactGeometry.at(lone))
        let still = LensEvent(time: 0.5, kind: .ballBall, point: Vec2(1, 0.6), normal: Vec2(1, 0),
                              balls: [ball(0, before: .zero, after: .zero), ball(1, before: .zero, after: .zero)])
        XCTAssertNil(ContactGeometry.at(still), "two balls at rest: nothing struck anything")
    }

    // MARK: The close-up's coordinates and the zoom it moves

    @MainActor
    func testCloseUpPointIsTheContactInZoomCoordinates() throws {
        let e = hit(incoming: Vec2(2, 0), n: Vec2(1, 0))
        let tl = TestShots.recording([e])
        let p = try XCTUnwrap(SignatureCloseUp.moment(of: 0, in: tl))
        let w = TableFrame(tl.table).world(e.point)
        XCTAssertEqual(p.x, w.x, accuracy: 1e-6)
        XCTAssertEqual(p.y, w.z, accuracy: 1e-6)
        XCTAssertNil(SignatureCloseUp.moment(of: 5, in: tl), "an index outside the recording has no moment")
    }

    @MainActor
    func testCloseUpLeavesTheFittedViewAndSpringsBack() {
        let zoom = TableZoom()
        XCTAssertTrue(zoom.atFittedView)
        zoom.closeUp(on: SIMD2<Float>(0.3, -0.2), scale: SignatureCloseUp.magnification)
        XCTAssertFalse(zoom.atFittedView)
        XCTAssertEqual(zoom.goalScale, 1 / SignatureCloseUp.magnification, accuracy: 1e-6)
        XCTAssertEqual(zoom.goalOffset.x, 0.3, accuracy: 1e-6)
        XCTAssertEqual(zoom.goalOffset.y, -0.2, accuracy: 1e-6)
        zoom.springBack()
        XCTAssertTrue(zoom.atFittedView)
    }
}
