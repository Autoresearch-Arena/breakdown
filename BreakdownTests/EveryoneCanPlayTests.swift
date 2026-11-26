// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: Checks for the words Everyone can play adds (plans/25-Nov-2026-everyone-can-play-plan.md): the strike
//          panel's tiles speak their figure with the unit in words, the live figure alone before a shot, the delivered
//          figure alone when the stroke did not change it, and planned then delivered when it did (Part D3); the shot
//          of the day's spoken result is the result card's own lines, the distance only for a make (Part D2).
//          Runs in the app's test host, in whatever language it runs; each expectation is built from the same
//          localized pieces the code uses, so the checks hold in every language.
// SRP/DRY check: Pass - checks only; the figures come from StrikeFigures.make (as StrikeFiguresTests builds them) and
//          the day from DailyRecord.Day's own initialiser.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import XCTest

@MainActor
final class EveryoneCanPlayTests: XCTestCase {
    private let p = PoolParameters()

    private func figures(speed: Double) -> StrikeFigures {
        StrikeFigures.make(strike: CueStrike(direction: Vec2(1, 0), speed: speed, tipUp: 0, tipSide: 0, elevation: 0),
                           swing: CueProfile.swing(forPower: speed), parameters: p)
    }

    // MARK: The strike panel, spoken

    func testLiveTileSpeaksItsFigureInWords() {
        let f = figures(speed: 3)
        XCTAssertEqual(StrikeSpoken.tile(.leaves, .live(f), differs: false), StrikeSpoken.speed(f.leaves))
        XCTAssertEqual(StrikeSpoken.tile(.force, .live(f), differs: false), StrikeSpoken.force(f.force))
    }

    func testPlayedTileThatDidNotChangeSpeaksTheDeliveredFigureOnly() {
        let f = figures(speed: 3)
        let c = StrikeComparison(planned: f, delivered: f)
        XCTAssertEqual(StrikeSpoken.tile(.push, .played(c), differs: c.differs(.push)), StrikeSpoken.push(f.push))
    }

    func testPlayedTileThatChangedSpeaksPlannedThenDelivered() {
        let planned = figures(speed: 3), delivered = figures(speed: 2.5)
        let c = StrikeComparison(planned: planned, delivered: delivered)
        XCTAssertTrue(c.differs(.leaves))
        XCTAssertEqual(StrikeSpoken.tile(.leaves, .played(c), differs: true),
                       StrikeSpoken.plannedThenDelivered(planned: StrikeSpoken.speed(planned.leaves),
                                                         delivered: StrikeSpoken.speed(delivered.leaves)))
    }

    func testACutWithNoBallInLineSaysSo() {
        let f = figures(speed: 3)
        XCTAssertNil(f.cut)
        XCTAssertEqual(StrikeSpoken.value(.cut, of: f), StrikeSpoken.noCut)
    }

    // MARK: The shot of the day's result, spoken

    func testAMadeDaySaysTheTryTheDistanceTheScoreAndTheStreak() {
        let day = DailyRecord.Day(day: 3, shotID: "x", tries: 2, madeOnTry: 2, distance: 0.045, score: 1103)
        let spoken = DailyWords.resultSpoken(day, streak: 4)
        XCTAssertTrue(spoken.hasPrefix(DailyWords.resultTitle(day)))
        XCTAssertTrue(spoken.contains(DailyWords.fromMark(0.045)))
        XCTAssertTrue(spoken.contains(DailyWords.scoreSpoken(1103)))
        XCTAssertTrue(spoken.contains(DailyWords.streakSpoken(4)))
    }

    func testAMissedDayHasNoDistance() {
        let day = DailyRecord.Day(day: 3, shotID: "x", tries: DailyRecord.maxTries, distance: 0.2, score: 0)
        let spoken = DailyWords.resultSpoken(day, streak: 0)
        XCTAssertFalse(spoken.contains(DailyWords.fromMark(0.2)))
        XCTAssertTrue(spoken.contains(DailyWords.scoreSpoken(0)))
    }
}
