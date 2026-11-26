// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 bank: each answer is solved on its own table and must stop
//          on its written mark; a found shot says its goal in words.)
// PURPOSE: The shot of the day's bank and day numbers (App/Daily/DailyBank.swift, DailyShot.swift and the package's
//          AuthoredDaily; plans/25-Nov-2026-shot-of-the-day-plan.md, stage 1 item 7): the start is midnight UTC on 26
//          November 2026; day numbers change exactly at midnight UTC and count back before the start; the entry for a
//          day wraps round at the end of the list, both ways; the bank holds together (ids unique, no two neighbours of
//          one family, the last and the first included, every window wide enough to divide by); a trick-shot entry
//          carries the trick's own numbers; an escape entry's goal is its call; every entry builds a playable TrickShot
//          whose answer makes its own goal in the app's solve on its own surface (TrickShotJudge, as the app judges a
//          try), and whose mark can be found.
// SRP/DRY check: Pass - checks only. Solving and attempts are TestShots' (EightBallJudge.solve, the model's attempt
//          shape); the goal test is TrickShotJudge's.
@testable import Breakdown
import BreakdownAuthored
import BreakdownLensModel
import BreakdownPhysics
import Foundation
import XCTest

final class DailyBankTests: XCTestCase {
    private let day = DailyBank.secondsPerDay

    // MARK: Day numbers

    func testTheStartIsMidnightUTCOnTheTwentySixthOfNovember() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        let c = utc.dateComponents([.year, .month, .day, .hour, .minute, .second], from: DailyBank.startDate)
        XCTAssertEqual([c.year, c.month, c.day, c.hour, c.minute, c.second], [2026, 11, 26, 0, 0, 0])
    }

    func testTheDayChangesAtMidnightUTC() {
        let start = DailyBank.startDate
        XCTAssertEqual(DailyBank.day(at: start), 0)
        XCTAssertEqual(DailyBank.day(at: start.addingTimeInterval(day - 1)), 0, "one second before midnight")
        XCTAssertEqual(DailyBank.day(at: start.addingTimeInterval(day)), 1, "midnight")
        XCTAssertEqual(DailyBank.day(at: start.addingTimeInterval(day + 1)), 1)
        XCTAssertEqual(DailyBank.day(at: start.addingTimeInterval(40 * day + 12 * 3600)), 40)
        XCTAssertEqual(DailyBank.day(at: start.addingTimeInterval(-1)), -1, "the second before the start")
        XCTAssertEqual(DailyBank.day(at: start.addingTimeInterval(-day)), -1)
        XCTAssertEqual(DailyBank.day(at: start.addingTimeInterval(-day - 1)), -2)
    }

    func testTheDayIsTheSameInEveryTimeZone() {
        // Midnight in Tokyo on the 28th is 15:00 UTC on the 27th: still day 1 for everyone.
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .gmt
        let moment = tokyo.date(from: DateComponents(year: 2026, month: 11, day: 28, hour: 0, minute: 0))
        XCTAssertEqual(moment.map { DailyBank.day(at: $0) }, 1)
    }

    func testTheEntryWrapsRoundTheList() {
        let bank = AuthoredDaily.all
        let n = bank.count
        XCTAssertGreaterThan(n, 0)
        XCTAssertEqual(DailyBank.entry(forDay: 0).id, bank[0].id)
        XCTAssertEqual(DailyBank.entry(forDay: n - 1).id, bank[n - 1].id, "the last day of the list")
        XCTAssertEqual(DailyBank.entry(forDay: n).id, bank[0].id, "the day after the last starts again")
        XCTAssertEqual(DailyBank.entry(forDay: n + 1).id, bank[1].id)
        XCTAssertEqual(DailyBank.entry(forDay: 3 * n + 2).id, bank[2].id)
        XCTAssertEqual(DailyBank.entry(forDay: -1).id, bank[n - 1].id, "a day before the start wraps backwards")
        XCTAssertEqual(DailyBank.entry(forDay: -n).id, bank[0].id)
    }

    // MARK: The bank

    func testTheBankHoldsTogether() {
        let bank = AuthoredDaily.all
        XCTAssertEqual(Set(bank.map(\.id)).count, bank.count, "duplicate daily ids")
        for (i, e) in bank.enumerated() {
            let next = bank[(i + 1) % bank.count]
            XCTAssertNotEqual(e.family, next.family, "\(e.id) and \(next.id) are neighbours of one family")
            XCTAssertGreaterThan(e.window.aim, 0, e.id)
            XCTAssertGreaterThan(e.window.power, 0, e.id)
            XCTAssertGreaterThan(e.window.tipUp, 0, e.id)
            XCTAssertTrue((1...3).contains(e.difficulty), e.id)
            XCTAssertEqual(e.layout.count, 16, e.id)
            XCTAssertTrue(NextShot.isOnTable(e.layout[0]), "\(e.id): no cue ball")
            XCTAssertFalse(e.goal.drops.isEmpty && e.goal.secondHit == nil, "\(e.id): a goal with nothing to make")
        }
    }

    func testATrickEntryCarriesTheTricksOwnNumbers() throws {
        for e in AuthoredDaily.all {
            guard case .trick(let id) = e.source else { continue }
            let t = try XCTUnwrap(AuthoredTricks.trick(id: id), id)
            XCTAssertEqual(e.layout, t.layout, id)
            XCTAssertEqual(e.answer, t.solution, id)
            XCTAssertEqual(e.goal, t.goal, id)
            XCTAssertEqual(e.window, t.window, id)
            XCTAssertEqual(e.surface, .cloth, id)
            XCTAssertEqual(e.strongSide != nil, AuthoredTricks.strongSideIDs.contains(id), id)
        }
    }

    func testAnEscapeEntrysGoalIsItsCall() throws {
        for e in AuthoredDaily.all {
            guard case .escape(let situationID, let escapeID) = e.source else { continue }
            let s = try XCTUnwrap(AuthoredEscapes.situation(id: situationID), situationID)
            let escape = try XCTUnwrap(s.escape(escapeID), e.id)
            XCTAssertEqual(e.layout, s.layout, e.id)
            XCTAssertEqual(e.answer, escape.strike, e.id)
            XCTAssertEqual(e.surface, s.surface, e.id)
            XCTAssertEqual(e.goal.drops.first?.ball, escape.call.ball, e.id)
            XCTAssertEqual(e.goal.drops.first?.pocket, escape.call.pocket?.rawValue, e.id)
        }
    }

    // MARK: The shots as the app plays them

    func testEveryDailyShotIsAPlayableTrickShot() {
        for (i, e) in AuthoredDaily.all.enumerated() {
            let shot = DailyShot(day: i, entry: e)
            XCTAssertTrue(DailyShot.isDailyID(shot.trick.id), e.id)
            XCTAssertNil(TrickShots.shot(id: shot.trick.id), "\(e.id): a daily id must never be a trick shot's")
            XCTAssertFalse(shot.trick.pending, e.id)
            XCTAssertFalse(shot.trick.goalLine.isEmpty, e.id)
            XCTAssertEqual(shot.trick.title, DailyShot.title, "\(e.id): the card must not name the trick before the day ends")
            XCTAssertNil(shot.trick.cueAngles, "\(e.id): the daily shot sets its own cue angle")
            XCTAssertEqual(shot.trick.goal.side, e.strongSide, e.id)
            if case .trick(let id) = e.source {
                XCTAssertEqual(DailyShot.sourceTrickID(shot.trick.id), id, "the replay's held moments")
            }
        }
        XCTAssertFalse(DailyShot.isDailyID("stop-dead"))
        XCTAssertFalse(DailyShot.isDailyID(nil))
        XCTAssertEqual(DailyShot.sourceTrickID("stop-dead"), "stop-dead", "any other id is unchanged")
    }

    /// The answer of every entry makes its own goal, solved as the app solves it on the entry's table and surface and
    /// judged as the app judges a try; and it stops on its mark (0.7.10 bank: every entry writes its mark, the answer's
    /// own resting place to the tenth of a millimetre, Stop Dead's its circle's centre).
    func testEveryAnswerMakesItsGoalAndHasAMark() throws {
        for e in AuthoredDaily.all {
            let shot = DailyShot(day: 0, entry: e)
            guard case .layout(let start) = shot.trick.setup else { return XCTFail("\(e.id) is not laid out") }
            XCTAssertEqual(shot.trick.table, TableKind(e.table), "\(e.id): the shot starts on its own table")
            let tl = DailyShot.answerTimeline(of: e)
            let attempt = TestShots.attempt(start: start, timeline: tl, shot.trick.solution, on: shot.surface,
                                            table: shot.table)
            XCTAssertNil(TrickShotJudge.failure(shot.trick.goal, attempt), "\(e.id): the answer misses its own goal")
            XCTAssertTrue(TrickShotJudge.verdict(for: shot.trick, attempt: attempt).made, e.id)
            let mark = try XCTUnwrap(shot.findMark(), "\(e.id): no mark")
            XCTAssertLessThan((attempt.cueRest - mark).length, 0.01, "\(e.id): the answer stops on its mark")
        }
    }

    /// 0.7.10 bank: every shot BreakProbe daily found says its goal in words, with the ball it leaves the cue ball on.
    func testAnAuthoredShotSaysItsGoal() {
        for e in AuthoredDaily.all where e.source == .authored {
            let shot = DailyShot(day: 0, entry: e)
            XCTAssertFalse(shot.trick.goalLine.isEmpty, e.id)
            XCTAssertNotEqual(shot.trick.goalLine, String(localized: "Make the shot."), "\(e.id): a goal with no words")
            XCTAssertFalse(shot.trick.idea.isEmpty, e.id)
        }
    }
}
