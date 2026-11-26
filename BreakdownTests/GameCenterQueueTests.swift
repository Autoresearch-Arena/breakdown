// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The saved list of unsent Game Center scores (App/GameCenter/GameCenterQueue.swift; Shot of the day plan stage
//          3 item 9, plans/25-Nov-2026-shot-of-the-day-plan.md): an unsent score is kept, it is sent once and never
//          again, a failed send waits for the next chance, and a daily score is dropped once its day has passed while a
//          streak waits however long it takes. Also the day number (it turns at midnight Coordinated Universal Time),
//          the list surviving a save and a load, and the permanent Game Center ids. Pure: no GameKit, no sign-in.
// SRP/DRY check: Pass - checks only; the throwaway defaults suite follows AchievementRecordTests.
@testable import Breakdown
import Foundation
import XCTest

final class GameCenterQueueTests: XCTestCase {
    /// A throwaway defaults suite, removed when the test ends.
    private func withSuite(_ body: (UserDefaults) throws -> Void) rethrows {
        let name = "GameCenterQueueTests-\(UUID().uuidString)"
        guard let suite = UserDefaults(suiteName: name) else { return XCTFail("no defaults suite") }
        defer { suite.removePersistentDomain(forName: name) }
        try body(suite)
    }

    private let today = 20_418

    func testUnsentScoreIsKept() {
        var q = GameCenterQueue()
        XCTAssertTrue(q.add(board: .daily, value: 1_120, day: today))
        XCTAssertEqual(q.entries.count, 1)
        // Not sent yet (never begun): still there on the same day, and handed out when a send starts.
        XCTAssertFalse(q.dropExpired(today: today))
        let due = q.begin(today: today)
        XCTAssertEqual(due.map(\.value), [1_120])
        XCTAssertEqual(due.first?.board, .daily)
    }

    func testSentOnce() {
        var q = GameCenterQueue()
        q.add(board: .daily, value: 900, day: today)
        let first = q.begin(today: today)
        XCTAssertEqual(first.count, 1)
        // A second send starting before the first finishes is not handed the same score.
        XCTAssertTrue(q.begin(today: today).isEmpty)
        q.finish(first[0].id, sent: true)
        XCTAssertTrue(q.entries.isEmpty)
        // And after it is sent, nothing is ever handed out again.
        XCTAssertTrue(q.begin(today: today).isEmpty)
    }

    func testFailedSendWaitsForNextChance() {
        var q = GameCenterQueue()
        q.add(board: .daily, value: 700, day: today)
        let first = q.begin(today: today)
        q.finish(first[0].id, sent: false)
        XCTAssertEqual(q.entries.count, 1)
        XCTAssertEqual(q.begin(today: today).map(\.id), [first[0].id])
    }

    func testDailyScoreDroppedWhenItsDayHasPassed() {
        var q = GameCenterQueue()
        q.add(board: .daily, value: 1_000, day: today)
        q.add(board: .streak, value: 4, day: nil)
        // The next day: the daily board it was for has closed, so it goes unsent; the streak stays.
        let due = q.begin(today: today + 1)
        XCTAssertEqual(due.map(\.board), [.streak])
        XCTAssertEqual(q.entries.map(\.board), [.streak])
    }

    func testStreakNeverExpires() {
        var q = GameCenterQueue()
        q.add(board: .streak, value: 3, day: today)
        // A streak is kept without a day, whatever the caller passed.
        XCTAssertNil(q.entries.first?.day)
        XCTAssertFalse(q.dropExpired(today: today + 400))
        XCTAssertEqual(q.entries.count, 1)
    }

    func testSameDayKeepsTheHigherScoreAndBestStreak() {
        var q = GameCenterQueue()
        q.add(board: .daily, value: 600, day: today)
        XCTAssertFalse(q.add(board: .daily, value: 400, day: today))
        XCTAssertTrue(q.add(board: .daily, value: 800, day: today))
        q.add(board: .streak, value: 5, day: nil)
        XCTAssertFalse(q.add(board: .streak, value: 2, day: nil))
        XCTAssertEqual(q.entries.filter { $0.board == .daily }.map(\.value), [800])
        XCTAssertEqual(q.entries.filter { $0.board == .streak }.map(\.value), [5])
        // Another day's score is its own entry.
        q.add(board: .daily, value: 300, day: today + 1)
        XCTAssertEqual(q.entries.filter { $0.board == .daily }.count, 2)
    }

    func testNothingKeptForZero() {
        var q = GameCenterQueue()
        XCTAssertFalse(q.add(board: .daily, value: 0, day: today))
        XCTAssertFalse(q.add(board: .streak, value: 0, day: nil))
        XCTAssertTrue(q.entries.isEmpty)
    }

    func testSurvivesSaveAndLoad() {
        withSuite { defaults in
            var q = GameCenterQueue()
            q.add(board: .daily, value: 1_199, day: today)
            q.add(board: .streak, value: 7, day: nil)
            q.save(to: defaults)
            let loaded = GameCenterQueue.load(from: defaults)
            XCTAssertEqual(loaded, q)
            XCTAssertEqual(loaded.entries.map(\.value), [1_199, 7])
        }
    }

    func testScoreBeingSentWhenTheAppClosesIsSentNextLaunch() {
        withSuite { defaults in
            var q = GameCenterQueue()
            q.add(board: .daily, value: 500, day: today)
            _ = q.begin(today: today)
            q.save(to: defaults)
            // Being sent is not saved: the next launch hands it out again.
            var next = GameCenterQueue.load(from: defaults)
            XCTAssertEqual(next.begin(today: today).map(\.value), [500])
        }
    }

    func testUnreadableSaveLoadsEmpty() {
        withSuite { defaults in
            defaults.set(Data("not json".utf8), forKey: GameCenterQueue.storageKey)
            XCTAssertTrue(GameCenterQueue.load(from: defaults).entries.isEmpty)
        }
    }

    func testDayTurnsAtMidnightUTC() {
        // 2026-11-26 23:59:59 and 2026-11-27 00:00:00, both Coordinated Universal Time.
        let before = Date(timeIntervalSince1970: 1_795_737_599)
        let after = Date(timeIntervalSince1970: 1_795_737_600)
        XCTAssertEqual(GameCenterQueue.utcDay(of: after), GameCenterQueue.utcDay(of: before) + 1)
        XCTAssertEqual(GameCenterQueue.utcDay(of: Date(timeIntervalSince1970: 0)), 0)
        XCTAssertEqual(GameCenterQueue.utcDay(of: Date(timeIntervalSince1970: -1)), -1)
    }

    func testPermanentIDs() {
        XCTAssertEqual(GameCenterBoard.daily.rawValue, "breakdown.daily")
        XCTAssertEqual(GameCenterBoard.streak.rawValue, "breakdown.streak")
        XCTAssertEqual(GameCenterIDs.achievement("bank"), "breakdown.bank")
        XCTAssertEqual(GameCenterIDs.achievement("daily-first-try"), "breakdown.daily_first_try")
        XCTAssertEqual(GameCenterIDs.achievement(Achievements.everyTrick), "breakdown.every_trick")
    }
}
