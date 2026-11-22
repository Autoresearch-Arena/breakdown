// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: Checks for the what-if replay's package parts (plans/22-Nov-2026-v075-whatif-and-gaps-plan.md, stream
//          whatif, tests): TimelineFork (where two futures of one shot part) and ShotNudge / WhatIfInput (the one change
//          to a delivered shot). Real solves where the physics decides the answer (a straight pot, a cut at two
//          speeds, an aim nudge that misses), hand-built recordings where only the reading is tested (phase changes
//          only, two rack hits listed in swapped order, a pocket against a jaw), so each expected answer can be read
//          straight off the test.
// SRP/DRY check: Pass - checked ShotFactsTests (hand-built recordings of one shot, read by ShotFacts) and PhysicsTests
//          (solves); these compare two recordings and check the nudge, which nothing else tests.
import BreakdownLensModel
import BreakdownTimeline
import Foundation
@testable import BreakdownPhysics
import XCTest

final class TimelineForkTests: XCTestCase {
    private let p = PoolParameters()
    private var r: Double { p.ballRadius }

    // MARK: Real shots

    /// The corner pocket at the foot end, far long cushion (largest x and y), and the unit line from the table's middle
    /// toward it: a straight pot along that line drops the object ball in that pocket.
    private var pocketLine: (pocket: Vec2, dir: Vec2) {
        let spec = p.tableSpec
        let pocket = spec.pockets.max { ($0.x + $0.y) < ($1.x + $1.y) }!
        let dir = (pocket - Vec2(spec.length / 2, spec.width / 2)).normalized
        return (pocket, dir)
    }

    /// Cue ball, then the object ball 0.5 m along the line, then 0.6 m on to the pocket; every other ball off the table.
    private func potLayout() -> [Vec2] {
        let (pocket, dir) = pocketLine
        var layout = [Vec2](repeating: NextShot.offTable, count: 16)
        layout[1] = pocket - dir * 0.6
        layout[0] = layout[1] - dir * 0.5
        return layout
    }

    /// A shot from `layout` along `direction` at `speed`, seed 7.
    private func input(_ layout: [Vec2], _ direction: Vec2, speed: Double = 2.5) -> ShotInput {
        NextShot.shot(from: layout, direction: direction, speed: speed, tipUp: 0, tipSide: 0, seed: 7)
    }

    /// (cos a, sin a) for a turn of `degrees`: the trig the app does before handing the turn to the nudge.
    private func turn(_ degrees: Double) -> Vec2 {
        let a = degrees * Double.pi / 180
        return Vec2(cos(a), sin(a))
    }

    func testIdenticalTimelinesGiveNoFork() {
        let layout = potLayout()
        let shot = input(layout, pocketLine.dir)
        let a = PoolSolver.simulate(shot), b = PoolSolver.simulate(shot)
        let fork = TimelineFork.find(real: a, alternate: b, start: layout, cueBall: 0, ballRadius: r)
        XCTAssertTrue(fork.identical)
        XCTAssertNil(fork.story)
        XCTAssertNil(fork.parting)
        XCTAssertNil(fork.marker)
        XCTAssertEqual(fork.changedBalls, [])
        XCTAssertEqual(fork.finishGap, 0, accuracy: 1e-12)
    }

    func testAnAimNudgeThatMissesForksAtTheContact() {
        let layout = potLayout()
        let shot = input(layout, pocketLine.dir)
        let real = PoolSolver.simulate(shot)
        // Precondition: the straight pot drops the object ball.
        XCTAssertNotNil(real.pocketTime[1], "the straight pot should drop the 1")
        // Ten degrees at half a metre carries the cue ball well clear of the object ball (a miss needs about 6.5).
        let alt = PoolSolver.simulate(WhatIfInput.alternate(of: shot, ShotNudge(turn: turn(10)), ballRadius: r))
        let fork = TimelineFork.find(real: real, alternate: alt, start: layout, cueBall: 0, ballRadius: r)
        let realContact = ShotFacts(timeline: real, start: layout).firstContactTime
        XCTAssertNotNil(realContact)
        XCTAssertNil(ShotFacts(timeline: alt, start: layout).firstContactTime, "the nudged shot should miss")
        guard let story = fork.story, let t = realContact else { return XCTFail("expected a story fork") }
        XCTAssertEqual(story.time, t, accuracy: 1e-9, "the fork is the real shot's first contact")
        XCTAssertEqual(story.realEvent?.kind, .ballBall)
        XCTAssertEqual(story.ball, 1)
        XCTAssertNil(fork.departure, "no shared first contact")
        XCTAssertTrue(fork.changedBalls.contains(1))
        XCTAssertEqual(fork.marker?.time ?? -1, t, accuracy: 1e-9)
    }

    func testAnAimNudgeTurnsTheObjectBallTheOtherWay() {
        let layout = potLayout()
        let shot = input(layout, pocketLine.dir)
        let real = PoolSolver.simulate(shot)
        // Half a degree to the shooter's left: the cue ball takes the object ball on its right side, so the object
        // ball leaves turned clockwise (to the right) and the cue ball comes off to the left.
        let alt = PoolSolver.simulate(WhatIfInput.alternate(of: shot, ShotNudge(turn: turn(0.5)), ballRadius: r))
        let fork = TimelineFork.find(real: real, alternate: alt, start: layout, cueBall: 0, ballRadius: r)
        guard let d = fork.departure else { return XCTFail("both futures hit the 1 first") }
        XCTAssertEqual(d.objectBall, 1)
        XCTAssertEqual(d.strikingBall, 0)
        XCTAssertLessThan(d.objectTurn, -0.1, "the object ball should leave to the right")
        XCTAssertGreaterThan(d.strikerSpreadChange, 0.1, "the cue ball should come off wider than a straight hit")
        XCTAssertNotNil(fork.firstContactGap)
    }

    func testAPowerChangePartsOnlyAfterTheContact() {
        // A cut: the cue ball's curve after the hit depends on its speed, while before the hit both run the same line.
        let (pocket, dir) = pocketLine
        var layout = [Vec2](repeating: NextShot.offTable, count: 16)
        layout[1] = pocket - dir * 0.6
        let ghost = layout[1] - dir * (2 * r)
        let approach = (dir + dir.perp * 0.6).normalized
        layout[0] = ghost - approach * 0.5
        let shot = input(layout, (ghost - layout[0]).normalized, speed: 2.0)
        let real = PoolSolver.simulate(shot)
        let alt = PoolSolver.simulate(WhatIfInput.alternate(of: shot, ShotNudge(speedScale: 1.5), ballRadius: r))
        let fork = TimelineFork.find(real: real, alternate: alt, start: layout, cueBall: 0, ballRadius: r)
        guard let parting = fork.parting else { return XCTFail("the faster cut should part from the slower one") }
        guard let contact = ShotFacts(timeline: alt, start: layout).firstContactTime else { return XCTFail("no contact") }
        XCTAssertGreaterThanOrEqual(parting.time, contact - 1e-9, "the lines are the same before the contact")
        // The gap at the parting point is the parting gap.
        XCTAssertEqual((parting.point - parting.realPoint).length, 0.005, accuracy: 1e-4)
        XCTAssertGreaterThan(parting.alternateHeading.length, 0.99)
    }

    // MARK: Hand-built recordings

    private func still(_ q: Vec2) -> BallSegment {
        BallSegment(t0: 0, t1: .infinity, phase: .stationary, position0: q, velocity0: .zero, acceleration: .zero,
                    omega0: .zero, alphaXY: .zero, spinDecay: 9, radius: r, orientation0: .identity)
    }

    private func ball(_ b: Int) -> ImpactBall {
        ImpactBall(ball: b, velocityBefore: Vec2(1, 0), velocityAfter: Vec2(0.5, 0), omegaBefore: .zero,
                   omegaAfter: .zero, translationalBefore: 0.085, rotationalBefore: 0, translationalAfter: 0.02,
                   rotationalAfter: 0)
    }

    private func contact(_ t: Double, _ a: Int, _ b: Int) -> LensEvent {
        LensEvent(time: t, kind: .ballBall, point: Vec2(1, 0.6), normal: Vec2(1, 0), balls: [ball(a), ball(b)])
    }

    private func phase(_ t: Double, _ b: Int) -> LensEvent {
        LensEvent(time: t, kind: .phaseTransition, point: .zero, normal: .zero, balls: [ball(b)], phaseFrom: .sliding,
                  phaseTo: .rolling)
    }

    private let start = [Vec2(0.6, 0.6), Vec2(1.5, 0.6), Vec2(1.7, 0.3)]

    /// Every ball standing still at its start (the reading of the story never needs motion).
    private func recording(_ events: [LensEvent], pocketTime: [Double?] = [nil, nil, nil]) -> Timeline {
        let sorted = events.sorted { $0.time < $1.time }
        return Timeline(table: p.tableSpec, seed: 1, parameterHash: 1, segments: start.map { [still($0)] },
                        events: sorted, pocketTime: pocketTime, duration: (sorted.last?.time ?? 0) + 1)
    }

    func testPhaseChangesAloneAreNoStoryFork() {
        let real = recording([contact(0.4, 0, 1), phase(0.6, 0), phase(0.7, 1)])
        let alt = recording([phase(0.3, 0), contact(0.4, 0, 1), phase(0.9, 1)])
        let fork = TimelineFork.find(real: real, alternate: alt, start: start, cueBall: 0, ballRadius: r)
        XCTAssertFalse(fork.identical)
        XCTAssertNil(fork.story)
    }

    func testTwoRackHitsInSwappedOrderAreNoFork() {
        let real = recording([contact(0.5, 0, 1), contact(0.500004, 0, 2)])
        let alt = recording([contact(0.5, 0, 2), contact(0.500004, 0, 1)])
        let fork = TimelineFork.find(real: real, alternate: alt, start: start, cueBall: 0, ballRadius: r)
        XCTAssertNil(fork.story)
    }

    func testAPocketAgainstAJawForksAtThePocket() {
        let drop = LensEvent(time: 1.0, kind: .pocket, point: Vec2(2.54, 1.27), normal: Vec2(1, 0), balls: [ball(1)],
                             pocket: 3)
        let jaw = LensEvent(time: 0.99, kind: .cushion, point: Vec2(2.5, 1.25), normal: Vec2(1, 0), balls: [ball(1)],
                            pocket: 3, edge: .jaw)
        let real = recording([contact(0.4, 0, 1), drop], pocketTime: [nil, 1.0, nil])
        let alt = recording([contact(0.4, 0, 1), jaw])
        let fork = TimelineFork.find(real: real, alternate: alt, start: start, cueBall: 0, ballRadius: r)
        guard let story = fork.story else { return XCTFail("a drop against a jaw is a different story") }
        XCTAssertEqual(story.ball, 1)
        XCTAssertEqual(story.realEvent?.kind, .pocket)
        XCTAssertEqual(story.alternateEvent?.kind, .cushion)
        XCTAssertEqual(story.alternateEvent?.edge, .jaw)
        XCTAssertEqual(story.time, 0.99, accuracy: 1e-12)
        XCTAssertEqual(fork.changedBalls.first, 1)
    }

    // MARK: ShotNudge

    func testAZeroNudgeReturnsTheInputUnchanged() {
        let layout = potLayout()
        var shot = NextShot.shot(from: layout, direction: turn(23.7), speed: 3.1, tipUp: -0.008, tipSide: 0.004,
                                 seed: 99, elevation: 0.2)
        shot.parameters.modelGeneration = 2
        let same = WhatIfInput.alternate(of: shot, ShotNudge(), ballRadius: r)
        XCTAssertEqual(same.parameters.hash, shot.parameters.hash)
        XCTAssertEqual(same.positions, shot.positions)
        XCTAssertEqual(same.seed, shot.seed)
        XCTAssertEqual(same.strike.direction, shot.strike.direction)
        XCTAssertEqual(same.strike.speed.bitPattern, shot.strike.speed.bitPattern)
        XCTAssertEqual(same.strike.tipUp.bitPattern, shot.strike.tipUp.bitPattern)
        XCTAssertEqual(same.strike.tipSide.bitPattern, shot.strike.tipSide.bitPattern)
        XCTAssertEqual(same.strike.elevation.bitPattern, shot.strike.elevation.bitPattern)
        XCTAssertEqual(same.strike.ballIndex, shot.strike.ballIndex)
        XCTAssertEqual(PoolSolver.simulate(same).contentHash, PoolSolver.simulate(shot).contentHash)
    }

    func testATurnAndItsReverseGiveTheDirectionBack() {
        let shot = input(potLayout(), turn(31.3))
        let there = WhatIfInput.alternate(of: shot, ShotNudge(turn: turn(0.25)), ballRadius: r)
        let back = WhatIfInput.alternate(of: there, ShotNudge(turn: turn(-0.25)), ballRadius: r)
        XCTAssertEqual(back.strike.direction.x, shot.strike.direction.x, accuracy: 1e-15)
        XCTAssertEqual(back.strike.direction.y, shot.strike.direction.y, accuracy: 1e-15)
        // The turn really turned it: a quarter degree, anticlockwise.
        let cross = shot.strike.direction.x * there.strike.direction.y - shot.strike.direction.y * there.strike.direction.x
        XCTAssertEqual(asin(cross) * 180 / Double.pi, 0.25, accuracy: 1e-9)
    }

    func testTheSideOffsetClampsAtNineTenthsOfTheRadius() {
        let shot = NextShot.shot(from: potLayout(), direction: Vec2(1, 0), speed: 2, tipUp: 0, tipSide: 0.02, seed: 1)
        let right = WhatIfInput.alternate(of: shot, ShotNudge(tipSide: 0.05), ballRadius: r)
        XCTAssertEqual(right.strike.tipSide, 0.9 * r, accuracy: 1e-15)
        let left = WhatIfInput.alternate(of: shot, ShotNudge(tipSide: -0.2), ballRadius: r)
        XCTAssertEqual(left.strike.tipSide, -0.9 * r, accuracy: 1e-15)
        let inside = WhatIfInput.alternate(of: shot, ShotNudge(tipSide: -0.0025), ballRadius: r)
        XCTAssertEqual(inside.strike.tipSide, 0.0175, accuracy: 1e-15)
        // Speed and elevation parts.
        let faster = WhatIfInput.alternate(of: shot, ShotNudge(speedScale: 1.1, elevation: 2), ballRadius: r)
        XCTAssertEqual(faster.strike.speed, 2.2, accuracy: 1e-12)
        XCTAssertEqual(faster.strike.elevation, WhatIfInput.maxElevation)
    }
}
