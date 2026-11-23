// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Checks for the package parts of "Same shot, every surface" (0.7.7, plans/23-Nov-2026-every-world-plan.md,
//          Tests): BallTravel (how far a ball went and how much of that it skidded, on hand-built recordings whose
//          answers can be worked out on paper: a straight roll at constant deceleration is v squared over two a, a
//          slide then a roll adds the two lengths, a pocketed ball stops counting at its pocket, a ball that never moved
//          or is not in the recording gives zeros), WorldOutcome (drops read as ball numbers; the struck ball's drop is
//          a pocket, not a flight off the table), WorldContrast.key (each case on a pair built for it, and alike for
//          identical outcomes) and WorldContrast.headline (the earliest rank, then the strongest, then the lowest
//          index; nil when nothing solved). One real solve of a straight pot on cloth and on ice checks the readings
//          hold together on a recording the solver made.
// SRP/DRY check: Pass - checked ShotFactsTests (hand-built recordings read by ShotFacts; the builders here follow
//          them) and TimelineForkTests (two recordings of one stroke compared); nothing else tests BallTravel or
//          WorldContrast.
import BreakdownAuthored
import BreakdownLensModel
import BreakdownTimeline
import Foundation
@testable import BreakdownPhysics
import XCTest

final class WorldContrastTests: XCTestCase {
    private let r = 0.028575

    // MARK: Building recordings by hand

    private func segment(_ phase: MotionPhase, from t0: Double, to t1: Double, at p: Vec2, velocity: Vec2 = .zero,
                         acceleration: Vec2 = .zero) -> BallSegment {
        BallSegment(t0: t0, t1: t1, phase: phase, position0: p, velocity0: velocity, acceleration: acceleration,
                    omega0: .zero, alphaXY: .zero, spinDecay: 9, radius: r, orientation0: .identity)
    }

    private func still(_ p: Vec2, from t0: Double = 0) -> BallSegment {
        segment(.stationary, from: t0, to: .infinity, at: p)
    }

    private func ball(_ b: Int) -> ImpactBall {
        ImpactBall(ball: b, velocityBefore: Vec2(1, 0), velocityAfter: Vec2(0.5, 0), omegaBefore: .zero,
                   omegaAfter: .zero, translationalBefore: 0.085, rotationalBefore: 0, translationalAfter: 0.02,
                   rotationalAfter: 0)
    }

    private func contact(_ t: Double, _ a: Int, _ b: Int) -> LensEvent {
        LensEvent(time: t, kind: .ballBall, point: .zero, normal: Vec2(1, 0), balls: [ball(a), ball(b)])
    }

    private func drop(_ t: Double, _ b: Int, pocket k: Int) -> LensEvent {
        LensEvent(time: t, kind: .pocket, point: .zero, normal: Vec2(1, 0), balls: [ball(b)], pocket: k)
    }

    private func flewOff(_ t: Double, _ b: Int) -> LensEvent {
        LensEvent(time: t, kind: .phaseTransition, point: .zero, normal: Vec2(0, -1), balls: [ball(b)],
                  phaseFrom: .airborne, phaseTo: .stationary, flight: .offTable)
    }

    private func cushion(_ t: Double, _ b: Int) -> LensEvent {
        LensEvent(time: t, kind: .cushion, point: .zero, normal: Vec2(0, 1), balls: [ball(b)], edge: .rail)
    }

    private func recording(_ segments: [[BallSegment]], _ events: [LensEvent] = [], pocketTime: [Int: Double] = [:],
                           duration: Double) -> Timeline {
        let spec = TableSpec(length: 2.54, width: 1.27, ballRadius: r, pockets: [], pocketCaptureRadius: [])
        return Timeline(table: spec, seed: 1, parameterHash: 1, segments: segments,
                        events: events.sorted { $0.time < $1.time },
                        pocketTime: (0..<segments.count).map { pocketTime[$0] }, duration: duration)
    }

    // MARK: BallTravel

    func testAStraightRollAtConstantDecelerationIsVSquaredOverTwoA() {
        // 2 m/s, slowing at 0.5 m/s squared: it stops after 4 s, 2 * 2 / (2 * 0.5) = 4 m on.
        let start = Vec2(0.3, 0.6)
        let tl = recording([[segment(.rolling, from: 0, to: 4, at: start, velocity: Vec2(2, 0),
                                     acceleration: Vec2(-0.5, 0)),
                             still(Vec2(4.3, 0.6), from: 4)]], duration: 4)
        let travel = BallTravel(timeline: tl, ball: 0)
        XCTAssertEqual(travel.distance, 4, accuracy: 1e-6)
        XCTAssertEqual(travel.skidding, 0, accuracy: 1e-12)
        XCTAssertEqual(travel.skidShare, 0, accuracy: 1e-12)
        XCTAssertEqual(travel.stopTime, 4, accuracy: 1e-12)
        XCTAssertEqual(travel.cushions, 0)
    }

    func testASlideThenARollCountsTheSlideAsSkidding() {
        // Sliding 0.2 s from 3 m/s at 5 m/s squared: 3 * 0.2 - 2.5 * 0.04 = 0.5 m, leaving it at 2 m/s. Then rolling
        // from 2 m/s at 0.5 m/s squared: 4 m more. Diagonal, so both axes of the speed are used.
        let d = Vec2(0.6, 0.8)
        let start = Vec2(0.3, 0.3)
        let slideEnd = start + d * 0.5
        let tl = recording([[segment(.sliding, from: 0, to: 0.2, at: start, velocity: d * 3, acceleration: d * -5),
                             segment(.rolling, from: 0.2, to: 4.2, at: slideEnd, velocity: d * 2,
                                     acceleration: d * -0.5),
                             still(slideEnd + d * 4, from: 4.2)]],
                           [cushion(1.0, 0), cushion(2.0, 0)], duration: 4.2)
        let travel = BallTravel(timeline: tl, ball: 0)
        XCTAssertEqual(travel.distance, 4.5, accuracy: 1e-6)
        XCTAssertEqual(travel.skidding, 0.5, accuracy: 1e-6)
        XCTAssertGreaterThan(travel.skidShare, 0)
        XCTAssertLessThan(travel.skidShare, 1)
        XCTAssertEqual(travel.skidShare, 0.5 / 4.5, accuracy: 1e-6)
        XCTAssertEqual(travel.stopTime, 4.2, accuracy: 1e-12)
        XCTAssertEqual(travel.cushions, 2)
    }

    func testAPocketedBallStopsCountingAtItsPocket() {
        // The same roll as above, taken by a pocket after 1 s: 2 * 1 - 0.25 * 1 = 1.75 m. The cushion after the
        // pocket time is not counted.
        let tl = recording([[segment(.rolling, from: 0, to: 4, at: Vec2(0.3, 0.6), velocity: Vec2(2, 0),
                                     acceleration: Vec2(-0.5, 0)),
                             still(Vec2(4.3, 0.6), from: 4)]],
                           [drop(1.0, 0, pocket: 5), cushion(0.5, 0), cushion(1.5, 0)], pocketTime: [0: 1.0],
                           duration: 4)
        let travel = BallTravel(timeline: tl, ball: 0)
        XCTAssertEqual(travel.distance, 1.75, accuracy: 1e-6)
        XCTAssertEqual(travel.stopTime, 1.0, accuracy: 1e-12)
        XCTAssertEqual(travel.cushions, 1)
    }

    func testABallThatNeverMovedOrIsNotInTheRecordingGivesZeros() {
        let tl = recording([[still(Vec2(0.3, 0.6))], [still(Vec2(1.0, 0.6))]], duration: 2)
        for b in [1, 5, -1] {
            let travel = BallTravel(timeline: tl, ball: b)
            XCTAssertEqual(travel, BallTravel(distance: 0, skidding: 0, airborne: 0, stopTime: 0, cushions: 0),
                           "ball \(b)")
            XCTAssertEqual(travel.skidShare, 0)
        }
    }

    // MARK: WorldOutcome

    func testAnOutcomeReadsDropsAsBallNumbersAndThePocketNotAFlight() {
        let start = [Vec2(0.3, 0.6), Vec2(1.5, 0.3), Vec2(1.7, 0.9), Vec2(1.0, 0.6)]
        func moving(_ p: Vec2, to q: Vec2) -> [BallSegment] {
            [segment(.rolling, from: 0, to: 1, at: p, velocity: (q - p) * 2, acceleration: (q - p) * -2), still(q, from: 1)]
        }
        // A pot of the 3: the cue ball hits the 3, the 3 drops.
        var segs = start.map { [still($0)] }
        segs[0] = moving(start[0], to: Vec2(0.9, 0.6))
        segs[3] = moving(start[3], to: Vec2(2.4, 0.6))
        let pot = recording(segs, [contact(0.4, 0, 3), drop(0.9, 3, pocket: 5)], pocketTime: [3: 0.9], duration: 1)
        let outcome = WorldOutcome(timeline: pot, start: start, cueBall: 0)
        XCTAssertEqual(outcome.dropped, [3])
        XCTAssertEqual(outcome.firstContact, 3)
        XCTAssertFalse(outcome.struckPocketed)
        XCTAssertEqual(outcome.struckBall, 0)
        XCTAssertGreaterThan(outcome.travel.distance, 0)

        // The cue ball flying off the table is not a pocket.
        let off = recording(segs, [contact(0.4, 0, 3), flewOff(0.8, 0)], pocketTime: [0: 0.8], duration: 1)
        let flown = WorldOutcome(timeline: off, start: start, cueBall: 0)
        XCTAssertFalse(flown.struckPocketed, "a flight off the table is not a drop into a pocket")
        XCTAssertEqual(flown.dropped, [])

        // The cue ball dropping is.
        let scratch = recording(segs, [contact(0.4, 0, 3), drop(0.8, 0, pocket: 2)], pocketTime: [0: 0.8], duration: 1)
        XCTAssertTrue(WorldOutcome(timeline: scratch, start: start, cueBall: 0).struckPocketed)
    }

    // MARK: WorldContrast.key

    private func outcome(distance: Double = 1.0, skidding: Double = 0.2, stop: Double = 2.0, first: Int? = 1,
                         dropped: [Int] = [], struckPocketed: Bool = false) -> WorldOutcome {
        WorldOutcome(struckBall: 0,
                     travel: BallTravel(distance: distance, skidding: skidding, airborne: 0, stopTime: stop, cushions: 0),
                     firstContact: first, dropped: dropped, struckPocketed: struckPocketed)
    }

    func testEachContrastOnAPairBuiltForIt() {
        let home = outcome()
        XCTAssertEqual(WorldContrast.key(home: home, world: home), .alike)
        XCTAssertEqual(WorldContrast.key(home: home, world: outcome(dropped: [3])), .gainsDrop(ball: 3))
        XCTAssertEqual(WorldContrast.key(home: home, world: outcome(distance: 1.0, skidding: 0.95)),
                       .neverRolls(distance: 1.0))
        // A skid-heavy home shot means "never rolls" is no difference.
        XCTAssertNotEqual(WorldContrast.key(home: outcome(skidding: 0.9), world: outcome(distance: 1.0, skidding: 0.95)),
                          .neverRolls(distance: 1.0))
        XCTAssertEqual(WorldContrast.key(home: home, world: outcome(first: nil)), .neverReaches(ball: 1))
        XCTAssertEqual(WorldContrast.key(home: home, world: outcome(first: 2)), .meetsOther(ball: 2, insteadOf: 1))
        XCTAssertEqual(WorldContrast.key(home: outcome(first: nil), world: outcome(first: 2)), .reaches(ball: 2))
        XCTAssertEqual(WorldContrast.key(home: outcome(dropped: [3]), world: home), .losesDrop(ball: 3))
        XCTAssertEqual(WorldContrast.key(home: home, world: outcome(struckPocketed: true)), .struckDrops)
        XCTAssertEqual(WorldContrast.key(home: outcome(struckPocketed: true), world: home), .struckStaysUp)
        XCTAssertEqual(WorldContrast.key(home: home, world: outcome(distance: 2.5)), .travel(world: 2.5, home: 1.0))
        XCTAssertEqual(WorldContrast.key(home: home, world: outcome(distance: 0.4)), .travel(world: 0.4, home: 1.0))
        // Double but under the visible minimum: not a travel difference.
        XCTAssertEqual(WorldContrast.key(home: outcome(distance: 0.1), world: outcome(distance: 0.25)), .alike)
        XCTAssertEqual(WorldContrast.key(home: home, world: outcome(stop: 5.0)), .lasts(world: 5.0, home: 2.0))
        // The order: a new drop outranks everything else that also changed.
        XCTAssertEqual(WorldContrast.key(home: home, world: outcome(distance: 3, first: 2, dropped: [4])),
                       .gainsDrop(ball: 4))
    }

    // MARK: WorldContrast.headline

    func testTheHeadlineIsTheEarliestRankThenTheStrongestThenTheFirst() {
        let home = outcome()
        let far = outcome(distance: 2.5), farther = outcome(distance: 4.0), pot = outcome(dropped: [3])
        // A new drop (rank 1) beats any travel.
        let a = WorldContrast.headline(home: home, worlds: [nil, far, pot, farther])
        XCTAssertEqual(a?.index, 2)
        XCTAssertEqual(a?.contrast, .gainsDrop(ball: 3))
        // Two travels: the larger ratio.
        let b = WorldContrast.headline(home: home, worlds: [far, farther])
        XCTAssertEqual(b?.index, 1)
        XCTAssertEqual(b?.contrast, .travel(world: 4.0, home: 1.0))
        // The same rank and the same strength: the earlier index (the surface listed first) wins the tie.
        let c = WorldContrast.headline(home: home, worlds: [nil, farther, farther])
        XCTAssertEqual(c?.index, 1)
        // All alike: the first solved surface, alike.
        let d = WorldContrast.headline(home: home, worlds: [nil, home, home])
        XCTAssertEqual(d?.index, 1)
        XCTAssertEqual(d?.contrast, .alike)
        // Nothing solved.
        XCTAssertNil(WorldContrast.headline(home: home, worlds: [nil, nil]))
        XCTAssertNil(WorldContrast.headline(home: home, worlds: []))
    }

    // MARK: A real solve

    func testAStraightPotOnClothAndOnIceReadsConsistently() {
        let p = PoolParameters()
        let spec = p.tableSpec
        let pocket = spec.pockets.max { ($0.x + $0.y) < ($1.x + $1.y) }!
        let dir = (pocket - Vec2(spec.length / 2, spec.width / 2)).normalized
        var layout = [Vec2](repeating: NextShot.offTable, count: 16)
        layout[1] = pocket - dir * 0.6
        layout[0] = layout[1] - dir * 0.5
        let cloth = NextShot.shot(from: layout, direction: dir, speed: 2.5, tipUp: 0, tipSide: 0, seed: 7)
        var ice = cloth
        TableSurface.ice.apply(to: &ice.parameters)
        for (name, shot) in [("cloth", cloth), ("ice", ice)] {
            let tl = PoolSolver.simulate(shot)
            let out = WorldOutcome(timeline: tl, start: layout, cueBall: 0)
            let t = out.travel
            XCTAssertGreaterThan(t.distance, 0, name)
            XCTAssertGreaterThanOrEqual(t.skidShare, 0, name)
            XCTAssertLessThanOrEqual(t.skidShare, 1 + 1e-9, name)
            XCTAssertLessThanOrEqual(t.skidding + t.airborne, t.distance + 1e-9, name)
            XCTAssertGreaterThan(t.stopTime, 0, name)
            XCTAssertLessThanOrEqual(t.stopTime, tl.duration + 1e-9, name)
            XCTAssertEqual(out.firstContact, 1, name)
            // A path is never shorter than the straight line from where the ball started to where it ended.
            let end = tl.state(ball: 0, at: tl.duration).position
            XCTAssertGreaterThanOrEqual(t.distance + 1e-6, (end - layout[0]).length, name)
        }
    }
}
