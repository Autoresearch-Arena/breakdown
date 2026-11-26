// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The shot of the day's handover to the boards (App/GameCenter/DailyBoardLink.swift; 0.7.10 wave 2 wiring,
//          plans/25-Nov-2026-shot-of-the-day-plan.md stage 3 item 6): a day recorded as unsent is handed over once,
//          only while it is still that day, and dropped (marked sent, nothing posted) once its day has passed; a live
//          make is handed over as it finishes and never again at the next launch; five misses post nothing; with the
//          board hidden nothing is handed over or marked. Against the real DailyMode and DailyRecord, with a stand-in
//          for GameCenter that keeps what it is given, and a throwaway defaults suite for the record. The pure rule
//          (DailyHandover.plan) is checked on its own too.
// SRP/DRY check: Pass - checks only. GameCenterQueueTests covers the queue's own send-once and drop rules; this file
//          covers the record's side of the same promise.
@testable import Breakdown
import BreakdownLensModel
import Foundation
import XCTest

@MainActor
final class DailyBoardLinkTests: XCTestCase {
    /// Keeps what it is asked to post.
    @MainActor
    private final class Poster: DailyBoardPoster {
        var boardAllowed = true
        var daily: [(score: Int, day: Int)] = []
        var streaks: [Int] = []
        var boardsOpened = 0
        func postDaily(score: Int, playedAt: Date) { daily.append((score, DailyBank.day(at: playedAt))) }
        func postStreak(_ days: Int) { streaks.append(days) }
        func showBoard() { boardsOpened += 1 }
    }

    /// A throwaway defaults suite, with the opening marked seen and the device's own surface kept and put back (a new
    /// model and the mode's begin write both).
    private func withDevice(_ body: (UserDefaults) throws -> Void) rethrows {
        let keys = [PlaySurface.storageKey, GameSettings.seenOpeningKey]
        var saved: [String: Any] = [:]
        for key in keys { if let v = UserDefaults.standard.object(forKey: key) { saved[key] = v } }
        defer {
            for key in keys {
                if let v = saved[key] { UserDefaults.standard.set(v, forKey: key) }
                else { UserDefaults.standard.removeObject(forKey: key) }
            }
        }
        UserDefaults.standard.set(true, forKey: GameSettings.seenOpeningKey)
        let name = "DailyBoardLinkTests-\(UUID().uuidString)"
        guard let suite = UserDefaults(suiteName: name) else { return XCTFail("no defaults suite") }
        defer { suite.removePersistentDomain(forName: name) }
        try body(suite)
    }

    /// A moment in the middle of day `day` (UTC). Static and nonisolated, so a clock closure can call it.
    nonisolated private static func noon(ofDay day: Int) -> Date {
        DailyBank.startDate.addingTimeInterval(Double(day) * DailyBank.secondsPerDay + 12 * 3600)
    }

    /// Save a record with day `day` made on its second try, unsent, into `defaults`.
    private func saveUnsentMake(day: Int, in defaults: UserDefaults) -> DailyRecord.Day? {
        var record = DailyRecord()
        record.noteTry(day: day, shotID: "test-shot", made: false, distance: nil)
        let made = record.noteTry(day: day, shotID: "test-shot", made: true, distance: 0.02)
        record.save(to: defaults)
        return made
    }

    func testAnUnsentDayIsPostedOnceWhileItIsStillThatDay() throws {
        try withDevice { defaults in
            let made = try XCTUnwrap(saveUnsentMake(day: 4, in: defaults))
            XCTAssertFalse(made.sent)
            let model = ShowpieceModel()
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 4) })
            let poster = Poster()
            let link = DailyBoardLink(mode: mode, poster: poster)
            link.handOverUnsent()
            XCTAssertEqual(poster.daily.map { $0.score }, [made.score], "the day's score went to the daily board")
            XCTAssertEqual(poster.daily.first?.day, 4, "filed under its own day")
            XCTAssertEqual(poster.streaks, [1], "and the streak to the streak board")
            XCTAssertEqual(mode.result(forDay: 4)?.sent, true)
            XCTAssertEqual(DailyRecord.load(from: defaults).day(4)?.sent, true, "the mark is saved")
            // A second launch the same day: nothing is posted again.
            link.handOverUnsent()
            let again = DailyBoardLink(mode: DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 4) }),
                                       poster: poster)
            again.handOverUnsent()
            XCTAssertEqual(poster.daily.count, 1, "posted once")
            XCTAssertEqual(poster.streaks.count, 1, "posted once")
        }
    }

    func testAnUnsentDayIsDroppedAfterItsDay() throws {
        try withDevice { defaults in
            _ = try XCTUnwrap(saveUnsentMake(day: 4, in: defaults))
            let model = ShowpieceModel()
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 5) })
            let poster = Poster()
            DailyBoardLink(mode: mode, poster: poster).handOverUnsent()
            XCTAssertTrue(poster.daily.isEmpty, "yesterday's board has closed")
            XCTAssertTrue(poster.streaks.isEmpty)
            XCTAssertEqual(DailyRecord.load(from: defaults).day(4)?.sent, true, "dropped: never looked at again")
        }
    }

    func testAHiddenBoardTakesNothingAndMarksNothing() throws {
        try withDevice { defaults in
            _ = try XCTUnwrap(saveUnsentMake(day: 4, in: defaults))
            let model = ShowpieceModel()
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 4) })
            let poster = Poster()
            poster.boardAllowed = false
            let link = DailyBoardLink(mode: mode, poster: poster)
            link.handOverUnsent()
            XCTAssertTrue(poster.daily.isEmpty)
            XCTAssertEqual(mode.result(forDay: 4)?.sent, false, "kept for a later launch the same day")
            // Shown again the same day: handed over then.
            poster.boardAllowed = true
            link.handOverUnsent()
            XCTAssertEqual(poster.daily.count, 1)
        }
    }

    func testALiveMakeIsHandedOverOnceAndNotAgainAtLaunch() throws {
        try withDevice { defaults in
            let model = ShowpieceModel()
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 2) })
            let poster = Poster()
            let link = DailyBoardLink(mode: mode, poster: poster)
            mode.resultSink = link
            mode.begin()
            let mark = try XCTUnwrap(mode.mark)
            mode.noteTry(made: true, rest: mark + Vec2(0.01, 0))
            let day = try XCTUnwrap(mode.result(forDay: 2))
            XCTAssertEqual(poster.daily.map { $0.score }, [day.score])
            XCTAssertEqual(poster.streaks, [1])
            XCTAssertTrue(day.sent, "marked sent as it was handed over")
            link.handOverUnsent()
            XCTAssertEqual(poster.daily.count, 1, "the launch handover skips a day already sent")
            model.trickMode.end()
        }
    }

    func testFiveMissesPostNothing() throws {
        try withDevice { defaults in
            let model = ShowpieceModel()
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 2) })
            let poster = Poster()
            let link = DailyBoardLink(mode: mode, poster: poster)
            mode.resultSink = link
            mode.begin()
            for _ in 1...DailyRecord.maxTries { mode.noteTry(made: false, rest: nil) }
            XCTAssertTrue(poster.daily.isEmpty)
            XCTAssertTrue(poster.streaks.isEmpty)
            XCTAssertEqual(mode.result(forDay: 2)?.sent, true, "dealt with")
            model.trickMode.end()
        }
    }

    func testConnectGivesTheResultCardItsBoard() throws {
        try withDevice { defaults in
            let model = ShowpieceModel()
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 2) })
            let poster = Poster()
            let link = DailyBoardLink.connect(mode, poster: poster)
            XCTAssertTrue(mode.resultSink === link)
            let open = try XCTUnwrap(mode.openBoard, "the Board button shows")
            open()
            XCTAssertEqual(poster.boardsOpened, 1)
        }
    }

    func testTheRuleOnItsOwn() {
        var made = DailyRecord.Day(day: 7, shotID: "s", tries: 1, madeOnTry: 1, distance: 0, score: 900)
        XCTAssertEqual(DailyHandover.plan(for: made, streak: 3, today: 7),
                       DailyHandover.Plan(score: 900, streak: 3, markSent: true))
        XCTAssertEqual(DailyHandover.plan(for: made, streak: 3, today: 8),
                       DailyHandover.Plan(score: nil, streak: nil, markSent: true), "dropped after its day")
        XCTAssertEqual(DailyHandover.plan(for: made, streak: 3, today: 6), .nothing, "a clock set back: left alone")
        made.sent = true
        XCTAssertEqual(DailyHandover.plan(for: made, streak: 3, today: 7), .nothing, "already sent")
        let open = DailyRecord.Day(day: 7, shotID: "s", tries: 2)
        XCTAssertEqual(DailyHandover.plan(for: open, streak: 0, today: 7), .nothing, "still being played")
        let missed = DailyRecord.Day(day: 7, shotID: "s", tries: DailyRecord.maxTries)
        XCTAssertEqual(DailyHandover.plan(for: missed, streak: 0, today: 7),
                       DailyHandover.Plan(score: nil, streak: nil, markSent: true))
    }
}
