// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The trick-shot judge (App/TrickShotJudge.swift) against real solves. Every trick in the library, played with
//          its authored answer on the standard cloth, must be judged made with its own praise line; played far too
//          softly it must be judged a miss, and on a shot judged by its pockets the one line of advice must name the
//          power ("Not enough pace") because power is then by far the setting furthest outside its window. A physics
//          change that breaks an authored answer, or a judge change that misreads one, fails here before an upload.
//          0.7.5 (Claude Opus 5.5 High, learn-modes stream): a level cue at the massé, the jump and the carom is told to
//          raise the cue, and one far too steep to lower it (the shared cue-angle check); every raised-cue answer is on
//          an offered angle inside its own run; a kick's aim miss is never called too full or too thin; the draw advice
//          names the millimetres; and Your turn after Watch it keeps the player's raised cue (TrickShotMode).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream: the tests above.)
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
            // A tenth of the authored speed, so no goal can still be met. (A fifth was tried first: Throw It In still
            // dropped its ball at a fifth, which is honest physics, since throw grows as the hit gets softer.)
            soft.power *= 0.1
            let verdict = TrickShotJudge.verdict(for: shot, attempt: play(shot, soft))
            XCTAssertFalse(verdict.made, "\(shot.id): a tenth of the speed still made it")
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

    // MARK: 0.7.5 (learn-modes stream)

    private let raiseLine = String(localized: "Raise the cue more. A level cue cannot do this one.")
    private let lowerLine = String(localized: "The cue is too steep. Lower it a little.")

    private func shot(_ id: String, file: StaticString = #filePath, line: UInt = #line) throws -> TrickShot {
        try XCTUnwrap(TrickShots.shot(id: id), "\(id): no such trick shot", file: file, line: line)
    }

    /// The answer with only the cue angle changed (nil is a level cue).
    private func atAngle(_ shot: TrickShot, _ degrees: Int?) -> TrickVerdict {
        var s = shot.solution
        s.elevation = degrees.map { CueAngleMenu.sine(forAngle: $0) }
        if s.elevation == 0 { s.elevation = nil }
        return TrickShotJudge.verdict(for: shot, attempt: play(shot, s))
    }

    // A level cue with the answer's aim, power and tip misses the massé and the jump (BreakProbe keeps both only if it
    // does), and the advice must be the cue angle, not "So close" or a line about the aim.
    func testALevelCueAtARaisedShotIsToldToRaiseTheCue() throws {
        for id in ["masse-curve", "jump-over", "draw-masse-carom"] {
            let verdict = atAngle(try shot(id), nil)
            XCTAssertFalse(verdict.made, "\(id): a level cue made it")
            XCTAssertEqual(verdict.line, raiseLine, "\(id): advice was \"\(verdict.line)\"")
        }
    }

    // Far steeper than any angle that makes it (BreakProbe verify reports the massé makes it only at 20 degrees and the
    // carom at 5 to 15): told to lower the cue.
    func testATooSteepCueIsToldToLowerIt() throws {
        for (id, degrees) in [("masse-curve", 80), ("draw-masse-carom", 30)] {
            let verdict = atAngle(try shot(id), degrees)
            XCTAssertFalse(verdict.made, "\(id) at \(degrees) degrees made it")
            XCTAssertEqual(verdict.line, lowerLine, "\(id) at \(degrees) degrees: advice was \"\(verdict.line)\"")
        }
    }

    // Every raised-cue answer is struck on an angle the cue-angle menu offers, exactly as the menu writes it, and its
    // own angle lies inside its recorded run, so the answer is never told to raise or lower the cue. On the main actor
    // because the menu's nearestAngle is (CueAngleMenu is a view).
    @MainActor
    func testRaisedCueAnswersAreOnOfferedAngles() {
        for shot in TrickShots.all {
            guard let e = shot.solution.elevation else { XCTAssertNil(shot.cueAngles, shot.id); continue }
            let angle = CueAngleMenu.nearestAngle(toSine: e)
            XCTAssertEqual(CueAngleMenu.sine(forAngle: angle), e, accuracy: 0, "\(shot.id): not an offered angle")
            XCTAssertTrue(shot.cueAngles?.contains(angle) == true, "\(shot.id): its angle is outside its run")
        }
    }

    // "Too full" and "too thin" describe a direct hit along the cue's line; a kick reaches the ball off two cushions,
    // so its aim misses must be told only to aim left or right.
    func testAKickMissIsNeverCalledFullOrThin() throws {
        let kick = try shot("two-rail-kick")
        var forbidden: Set<String> = []
        for thickness in [String(localized: "full"), String(localized: "thin")] {
            for amount in [String(localized: "well"), String(localized: "a touch")] {
                for way in [String(localized: "left"), String(localized: "right")] {
                    let line = String(localized: "You hit it too \(thickness). Aim \(amount) \(way).")
                    forbidden.insert(line)
                    forbidden.insert(String(localized: "The cue ball went in too. \(line)"))
                }
            }
        }
        var misses = 0
        for offset in [-3.0, -2.0, -1.0, -0.6, 0.6, 1.0, 2.0, 3.0] {
            var s = kick.solution
            s.aim += offset
            let verdict = TrickShotJudge.verdict(for: kick, attempt: play(kick, s))
            guard !verdict.made else { continue }
            misses += 1
            XCTAssertFalse(forbidden.contains(verdict.line), "aim \(offset): \"\(verdict.line)\"")
        }
        XCTAssertGreaterThan(misses, 0, "no aim offset missed the kick, so nothing was checked")
    }

    // The draw advice names the gap in millimetres: the long draw struck at centre height is 10.5 mm short of its draw.
    func testTheDrawAdviceNamesTheMillimetres() throws {
        let draw = try shot("bridge-draw")
        var s = draw.solution
        s.tipUp = 0
        let verdict = TrickShotJudge.verdict(for: draw, attempt: play(draw, s))
        XCTAssertFalse(verdict.made)
        let mm = TableWords.millimetres(0 - draw.solution.tipUp)
        let advice = String(localized: "Not enough draw. Strike about \(mm) millimetres lower on the cue ball.")
        XCTAssertTrue(verdict.line == advice || verdict.line == String(localized: "The cue ball went in too. \(advice)"),
                      "advice was \"\(verdict.line)\"")
    }

    // Your turn after Watch it keeps the player's raised cue (it used to come back level): the settings the mode keeps
    // for the player carry the cue angle.
    @MainActor
    func testTrickShotModeKeepsARaisedCueAngle() throws {
        let model = ShowpieceModel()
        let mode = model.trickMode
        mode.begin(try shot("jump-over"))
        defer { mode.end() }
        mode.yourTurn()
        let raised = CueAngleMenu.sine(forAngle: 40)
        model.shotElevation = raised
        mode.watch()
        XCTAssertEqual(model.shotElevation, TrickShots.shot(id: "jump-over")?.solution.elevation ?? -1, accuracy: 1e-12,
                       "Watch it plays the answer's own angle")
        mode.yourTurn()
        XCTAssertEqual(model.shotElevation, raised, accuracy: 1e-12, "Your turn put the cue back to another angle")
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
