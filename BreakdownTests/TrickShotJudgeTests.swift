// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The trick-shot judge (App/TrickShotJudge.swift) against real solves. Every trick in the library, played with
//          its authored answer on the standard cloth, must be judged made with its own praise line; played far too
//          softly it must be judged a miss, and on a shot judged by its pockets the one line of advice must name the
//          power ("Not enough pace") because power is then by far the setting furthest outside its window. A physics
//          change that breaks an authored answer, or a judge change that misreads one, fails here before an upload.
// SRP/DRY check: Pass - checked the package's BreakProbe trick authoring (it searches for answers; this checks the
//          app's judge on them) and TrickShotMode (the flow; this calls the judge directly with what the mode passes).
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import XCTest

final class TrickShotJudgeTests: XCTestCase {
    /// Solve a trick with the given settings from its own start, the way TrickShotMode loads it (the authored layout,
    /// or the authored rack broken from its own seed), and make the attempt the model would record.
    private func play(_ shot: TrickShot, _ s: TrickSettings) -> ShotAttempt {
        switch shot.setup {
        case .layout(let start):
            return TestShots.attempt(start: start, timeline: TestShots.shot(from: start, s), s)
        case .rack(let seed):
            let input = TestShots.breakInput(seed: seed, aimOffset: s.aim, speed: s.power, tipUp: s.tipUp,
                                             tipSide: s.tipSide)
            return TestShots.attempt(start: input.positions, timeline: TestShots.solve(input), s, isBreak: true,
                                     breakSeed: seed)
        }
    }

    func testEveryAuthoredAnswerIsMade() {
        XCTAssertFalse(TrickShots.all.isEmpty)
        for shot in TrickShots.all where !shot.pending {
            let attempt = play(shot, shot.solution)
            let verdict = TrickShotJudge.verdict(for: shot, attempt: attempt)
            XCTAssertNil(TrickShotJudge.failure(shot.goal, attempt), "\(shot.id): the authored answer no longer works")
            XCTAssertTrue(verdict.made, "\(shot.id): judged a miss (\(verdict.line))")
            XCTAssertEqual(verdict.line, shot.praise, shot.id)
        }
    }

    func testAFarTooSoftStrokeIsAMissWithAdvice() {
        for shot in TrickShots.all where !shot.pending {
            var soft = shot.solution
            // A fifth of the authored speed: several power windows outside every measured one (the widest power
            // half-width in the library is well under half the answer's speed), so no goal can still be met.
            soft.power *= 0.2
            let verdict = TrickShotJudge.verdict(for: shot, attempt: play(shot, soft))
            XCTAssertFalse(verdict.made, "\(shot.id): a fifth of the speed still made it")
            XCTAssertFalse(verdict.line.isEmpty, shot.id)
            XCTAssertNotEqual(verdict.line, shot.praise, shot.id)
            // With aim and tip exactly on the answer, power is the only setting off, so the advice must name it,
            // except on the stop-dead shot, whose advice reads the cue ball's finish instead (TrickShotJudge.advice).
            if shot.goal.cueZone == nil {
                let pace = String(localized: "Not enough pace. Pull back further to hit it harder.")
                XCTAssertTrue(verdict.line == pace
                              || verdict.line == String(localized: "The cue ball went in too. \(pace)"),
                              "\(shot.id): advice was \"\(verdict.line)\"")
            }
        }
    }

    func testPocketOfReadsTheRecordedDrop() {
        let tl = TestShots.straightPot()
        // The Ride demo pots ball 1 in the corner furthest from the head spot (RideDemo.straightPot).
        let p = PoolParameters()
        let far = p.pocketCenters.indices.max { (p.pocketCenters[$0].x + p.pocketCenters[$0].y)
                                                < (p.pocketCenters[$1].x + p.pocketCenters[$1].y) }
        XCTAssertNotNil(tl.pocketTime[1], "the straight pot no longer drops ball 1")
        XCTAssertEqual(TrickShotJudge.pocket(of: 1, in: tl), far)
        XCTAssertNil(TrickShotJudge.pocket(of: 0, in: tl), "the cue ball must stay up on the straight pot")
    }
}
