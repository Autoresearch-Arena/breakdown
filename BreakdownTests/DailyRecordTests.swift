// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The shot of the day's record (App/Daily/DailyRecord.swift; plans/25-Nov-2026-shot-of-the-day-plan.md, stage 1
//          item 7): the streak grows with each made day, stays alive while today is still open, breaks on a day not
//          played and on five misses; a day takes five tries and no more; a make keeps its try, distance and score; the
//          best streak outlives a broken one; the first-try make is seen; the board's sent flag is kept; and a record
//          survives a save and a load (and a stored record missing fields still loads) through a throwaway defaults
//          suite.
// SRP/DRY check: Pass - checks only; the score is DailyScore's (checked in DailyScoreTests), read here, not restated.
@testable import Breakdown
import Foundation
import XCTest

final class DailyRecordTests: XCTestCase {
    /// A throwaway defaults suite, removed when the test ends.
    private func withSuite(_ body: (UserDefaults) throws -> Void) rethrows {
        let name = "DailyRecordTests-\(UUID().uuidString)"
        guard let suite = UserDefaults(suiteName: name) else { return XCTFail("no defaults suite") }
        defer { suite.removePersistentDomain(forName: name) }
        try body(suite)
    }

    /// Make day `d` on its first try, on the mark.
    private func make(_ r: inout DailyRecord, _ d: Int) {
        r.noteTry(day: d, shotID: "shot-\(d)", made: true, distance: 0)
    }

    /// Miss day `d` five times.
    private func lose(_ r: inout DailyRecord, _ d: Int) {
        for _ in 1...DailyRecord.maxTries { r.noteTry(day: d, shotID: "shot-\(d)", made: false, distance: nil) }
    }

    func testTheStreakGrows() {
        var r = DailyRecord()
        XCTAssertEqual(r.streak(asOf: 0), 0)
        make(&r, 0)
        XCTAssertEqual(r.streak(asOf: 0), 1)
        make(&r, 1)
        make(&r, 2)
        XCTAssertEqual(r.streak(asOf: 2), 3)
        XCTAssertEqual(r.bestStreak, 3)
    }

    func testTheStreakStaysAliveWhileTodayIsOpen() {
        var r = DailyRecord()
        make(&r, 4)
        make(&r, 5)
        XCTAssertEqual(r.streak(asOf: 6), 2, "today not played yet: yesterday's streak stands")
        r.noteTry(day: 6, shotID: "shot-6", made: false, distance: nil)
        XCTAssertEqual(r.streak(asOf: 6), 2, "one miss today, four tries left: the streak stands")
        r.noteTry(day: 6, shotID: "shot-6", made: true, distance: 0.01)
        XCTAssertEqual(r.streak(asOf: 6), 3)
    }

    func testTheStreakBreaksOnAMissedDay() {
        var r = DailyRecord()
        make(&r, 0)
        make(&r, 1)
        // Day 2 never played.
        XCTAssertEqual(r.streak(asOf: 3), 0, "yesterday was missed")
        make(&r, 3)
        XCTAssertEqual(r.streak(asOf: 3), 1, "a new streak starts")
        XCTAssertEqual(r.bestStreak, 2, "the best streak is kept")
    }

    func testTheStreakBreaksOnFiveMisses() {
        var r = DailyRecord()
        make(&r, 0)
        make(&r, 1)
        lose(&r, 2)
        XCTAssertEqual(r.streak(asOf: 2), 0, "five misses today end it")
        XCTAssertEqual(r.streak(asOf: 3), 0, "and it stays ended the next day")
        XCTAssertEqual(r.day(2)?.finished, true)
        XCTAssertEqual(r.day(2)?.made, false)
        XCTAssertEqual(r.day(2)?.score, 0)
    }

    func testFiveTriesAndNoMore() {
        var r = DailyRecord()
        for i in 1...DailyRecord.maxTries {
            let d = r.noteTry(day: 0, shotID: "a", made: false, distance: nil)
            XCTAssertEqual(d?.tries, i)
        }
        XCTAssertNil(r.noteTry(day: 0, shotID: "a", made: true, distance: 0), "a sixth try is refused")
        XCTAssertEqual(r.day(0)?.tries, DailyRecord.maxTries)
        XCTAssertEqual(r.day(0)?.made, false, "the refused try did not make it")
    }

    func testAMakeKeepsItsTryDistanceAndScore() {
        var r = DailyRecord()
        r.noteTry(day: 7, shotID: "stop-dead", made: false, distance: nil)
        let d = r.noteTry(day: 7, shotID: "stop-dead", made: true, distance: 0.0123)
        XCTAssertEqual(d?.madeOnTry, 2)
        XCTAssertEqual(d?.distance, 0.0123)
        XCTAssertEqual(d?.score, DailyScore.score(madeOnTry: 2, distance: 0.0123))
        XCTAssertEqual(d?.shotID, "stop-dead")
        XCTAssertNil(r.noteTry(day: 7, shotID: "stop-dead", made: true, distance: 0), "a made day takes no more tries")
        XCTAssertFalse(r.hasFirstTryMake)
        make(&r, 8)
        XCTAssertTrue(r.hasFirstTryMake)
    }

    func testAMakeWithNoMarkScoresTheTryPointsOnly() {
        var r = DailyRecord()
        let d = r.noteTry(day: 0, shotID: "a", made: true, distance: nil)
        XCTAssertEqual(d?.score, DailyScore.tryPoints(madeOnTry: 1))
    }

    func testTheSentFlag() {
        var r = DailyRecord()
        make(&r, 0)
        XCTAssertEqual(r.day(0)?.sent, false)
        XCTAssertTrue(r.markSent(day: 0))
        XCTAssertEqual(r.day(0)?.sent, true)
        XCTAssertFalse(r.markSent(day: 1), "no such day")
    }

    func testARecordSurvivesASaveAndALoad() {
        withSuite { defaults in
            var r = DailyRecord()
            make(&r, 0)
            make(&r, 1)
            lose(&r, 2)
            r.noteTry(day: 3, shotID: "shot-3", made: false, distance: nil)
            r.markSent(day: 1)
            r.save(to: defaults)
            let back = DailyRecord.load(from: defaults)
            XCTAssertEqual(back, r)
            XCTAssertEqual(back.streak(asOf: 3), 0)
            XCTAssertEqual(back.bestStreak, 2)
        }
    }

    func testARecordMissingFieldsStillLoads() throws {
        try withSuite { defaults in
            // Only one day, with only its number and tries: the rest read as their plain defaults.
            let json = #"{"days": [{"day": 4, "tries": 2}]}"#
            defaults.set(try XCTUnwrap(json.data(using: .utf8)), forKey: DailyRecord.storageKey)
            let r = DailyRecord.load(from: defaults)
            XCTAssertEqual(r.day(4)?.tries, 2)
            XCTAssertNil(r.day(4)?.madeOnTry)
            XCTAssertEqual(r.day(4)?.sent, false)
            XCTAssertEqual(r.bestStreak, 0)
            // Nothing stored at all: an empty record.
            defaults.removeObject(forKey: DailyRecord.storageKey)
            XCTAssertEqual(DailyRecord.load(from: defaults), DailyRecord())
        }
    }
}
