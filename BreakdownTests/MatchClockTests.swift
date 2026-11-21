// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The bar-billiards game clock's rule (MatchClock in App/Match/TableGames.swift): it counts real seconds while
//          the table is live and stops for everything that is not play - a replay of a shot already seen, the Physics
//          Lens, a shot being solved, the ruling and hand-over cards, a finished game - and the clock arithmetic (one
//          long frame never counts for more than a quarter second, the clock never goes below zero, the shown second
//          counts up). Also the single-player best score kept on the device (BarBilliardsBest), on a throwaway
//          UserDefaults suite so the real one is never touched. Everything is a pure value, so nothing here waits.
// SRP/DRY check: Pass - checks only; limits are read from MatchClock's own constants, not retyped.
@testable import Breakdown
import XCTest

final class MatchClockTests: XCTestCase {
    /// A live moment in which the clock runs: aiming at a table at rest, nothing else going on.
    private func live(_ phase: MatchMode.Phase = .aiming) -> MatchClock.Moment {
        MatchClock.Moment(hasClock: true, isOver: false, phase: phase, lensOn: false, isSolving: false,
                          tableAtRest: true, playingNewGround: true)
    }

    func testRunsWhileAimingAtATableAtRest() {
        XCTAssertTrue(MatchClock.runs(live()))
    }

    func testStopsWhileTheLastShotIsReplayedDuringAiming() {
        var m = live()
        m.tableAtRest = false
        XCTAssertFalse(MatchClock.runs(m), "scrubbing or replaying the last shot is not playing time")
    }

    func testStopsWhileTheLensIsUp() {
        var m = live()
        m.lensOn = true
        XCTAssertFalse(MatchClock.runs(m))
        m.phase = .shooting
        XCTAssertFalse(MatchClock.runs(m), "the Lens stops it during a shot too")
    }

    func testStopsWhileSolving() {
        var m = live(.shooting)
        m.isSolving = true
        XCTAssertFalse(MatchClock.runs(m))
    }

    func testRunsOnlyOnAShotsFirstShowing() {
        var m = live(.shooting)
        XCTAssertTrue(MatchClock.runs(m), "the shot playing for the first time counts")
        m.playingNewGround = false
        XCTAssertFalse(MatchClock.runs(m), "watching it again after a rewind does not")
    }

    func testStopsForCardsAndAtTheEnd() {
        for phase in [MatchMode.Phase.ruling, .handOver, .over] {
            XCTAssertFalse(MatchClock.runs(live(phase)), "\(phase) is not playing time")
        }
        var over = live()
        over.isOver = true
        XCTAssertFalse(MatchClock.runs(over))
    }

    func testGamesWithoutAClockNeverRun() {
        var m = live()
        m.hasClock = false
        XCTAssertFalse(MatchClock.runs(m))
    }

    func testOneFrameCountsAtMostTheLongestFrame() {
        XCTAssertEqual(MatchClock.seconds(forFrame: 1.0 / 60), 1.0 / 60, accuracy: 1e-12)
        XCTAssertEqual(MatchClock.seconds(forFrame: 30), MatchClock.longestFrame,
                       "a long gap is the app held up or in the background, not time at the table")
        XCTAssertEqual(MatchClock.seconds(forFrame: -1), 0)
    }

    func testTheClockNeverGoesBelowZero() {
        XCTAssertEqual(MatchClock.ticked(10, by: 2.5), 7.5, accuracy: 1e-12)
        XCTAssertEqual(MatchClock.ticked(0.1, by: 0.25), 0)
        XCTAssertEqual(MatchClock.ticked(5, by: -1), 5, "a negative frame never adds time")
    }

    func testTheShownSecondCountsUp() {
        XCTAssertEqual(MatchClock.shownSeconds(900), 900)
        XCTAssertEqual(MatchClock.shownSeconds(899.2), 900, "15:00 until a whole second has gone")
        XCTAssertEqual(MatchClock.shownSeconds(0.01), 1, "0:00 only when time is really up")
        XCTAssertEqual(MatchClock.shownSeconds(0), 0)
        XCTAssertEqual(MatchClock.shownSeconds(-3), 0)
    }

    /// A whole minute of frames at sixty a second, some of them during a replay and the Lens: only the live ones count.
    func testAMinuteWithPausesCountsOnlyTheLiveFrames() {
        var clock = 600.0
        let frame = 1.0 / 60
        for k in 0..<3600 {
            var m = live()
            // The second quarter of the minute is a replay, the third the Lens.
            if (900..<1800).contains(k) { m.tableAtRest = false }
            if (1800..<2700).contains(k) { m.lensOn = true }
            if MatchClock.runs(m) { clock = MatchClock.ticked(clock, by: MatchClock.seconds(forFrame: frame)) }
        }
        XCTAssertEqual(clock, 600 - 30, accuracy: 1e-6, "two quarters of a minute live, two paused")
    }

    // MARK: The best score

    private func freshDefaults() -> UserDefaults {
        let name = "MatchClockTests-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    func testTheBestScoreIsKeptAndOnlyBeatenByMore() {
        let d = freshDefaults()
        XCTAssertNil(BarBilliardsBest.best(in: d))
        XCTAssertEqual(BarBilliardsBest.record(4_000, in: d), .first(score: 4_000))
        XCTAssertEqual(BarBilliardsBest.best(in: d), 4_000)
        XCTAssertEqual(BarBilliardsBest.record(3_500, in: d), .notBest(score: 3_500, best: 4_000))
        XCTAssertEqual(BarBilliardsBest.record(4_000, in: d), .notBest(score: 4_000, best: 4_000), "a tie is not a new best")
        XCTAssertEqual(BarBilliardsBest.record(5_200, in: d), .newBest(score: 5_200, previous: 4_000))
        XCTAssertEqual(BarBilliardsBest.best(in: d), 5_200)
    }

    func testAZeroScoreIsStillAFirstBest() {
        let d = freshDefaults()
        XCTAssertEqual(BarBilliardsBest.record(0, in: d), .first(score: 0), "a black peg can end a game on nothing")
        XCTAssertEqual(BarBilliardsBest.best(in: d), 0)
    }
}
