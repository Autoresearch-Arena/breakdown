// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The shot of the day's mode (App/Daily/DailyMode.swift; plans/25-Nov-2026-shot-of-the-day-plan.md, stage 2
//          item 8), against the real model: today's shot goes on the table as a trick shot with its own id, on its own
//          surface, from a plain stroke at its own cue angle; five tries, then Your turn and Try again do nothing;
//          the answer is refused before the day is finished and plays after; a make writes the record (its try, its
//          distance from the mark and its score, a streak of one) and is reported once to the result sink; a second
//          visit the same day, even from a new mode reading the same record, shows the result and takes no more tries;
//          the shot leaving the table gives the player's own surface back; ordinary trick shots are untouched by the
//          gate.
//          Tries are counted through DailyMode.noteTry, the very call the gate makes for each attempt TrickShotJudge has
//          judged (the judging itself is TrickShotJudgeTests' and DailyBankTests'), so no stroke has to be played out.
//          Each test uses a throwaway defaults suite for the record and puts back the device's own surface and opening
//          flag, which the model's surface change and a new model write.
// SRP/DRY check: Pass - checks only; every action goes through DailyMode and TrickShotMode's own methods.
@testable import Breakdown
import BreakdownAuthored
import BreakdownLensModel
import Foundation
import XCTest

@MainActor
final class DailyModeTests: XCTestCase {
    /// A sink that keeps what it is told.
    @MainActor
    private final class Sink: DailyResultSink {
        var results: [DailyResult] = []
        func dailyFinished(_ result: DailyResult) { results.append(result) }
    }

    /// Runs a test with a throwaway defaults suite, the opening marked seen and the device's own surface kept and put
    /// back afterwards.
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
        let name = "DailyModeTests-\(UUID().uuidString)"
        guard let suite = UserDefaults(suiteName: name) else { return XCTFail("no defaults suite") }
        defer { suite.removePersistentDomain(forName: name) }
        try body(suite)
    }

    /// A moment in the middle of day `day` (UTC). Static and nonisolated, so a clock closure can call it.
    nonisolated private static func noon(ofDay day: Int) -> Date {
        DailyBank.startDate.addingTimeInterval(Double(day) * DailyBank.secondsPerDay + 12 * 3600)
    }

    /// The first day whose shot is `id`.
    private func day(of id: String) -> Int? { AuthoredDaily.all.firstIndex { $0.id == id } }

    func testTodaysShotGoesOnTheTableAsATrickShot() throws {
        try withDevice { defaults in
            let model = ShowpieceModel()
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 3) })
            mode.begin()
            let shot = try XCTUnwrap(mode.shot)
            XCTAssertEqual(shot.day, 3)
            XCTAssertEqual(shot.entry.id, AuthoredDaily.all[3].id)
            XCTAssertEqual(model.trickMode.current?.id, shot.trick.id)
            XCTAssertTrue(DailyMode.showing(model))
            XCTAssertEqual(model.trickMode.phase, .ready)
            XCTAssertEqual(model.surface, shot.surface, "the shot's own surface is on")
            XCTAssertNotNil(mode.mark, "the mark was found")
            XCTAssertEqual(mode.triesUsed, 0)
            model.trickMode.end()
            XCTAssertFalse(DailyMode.showing(model))
        }
    }

    func testTheShotStartsAtItsOwnCueAngle() throws {
        try withDevice { defaults in
            let d = try XCTUnwrap(day(of: "jump-over"), "the jump is in the bank")
            let model = ShowpieceModel()
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: d) })
            mode.begin()
            let want = try XCTUnwrap(mode.shot?.trick.solution.elevation, "the jump raises the cue")
            XCTAssertEqual(model.shotElevation, want, accuracy: 1e-12)
            XCTAssertNotEqual(model.shotPower, mode.shot?.trick.solution.power, "never the answer's power")
            model.trickMode.end()
        }
    }

    func testFiveTriesThenStop() throws {
        try withDevice { defaults in
            let model = ShowpieceModel()
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 0) })
            mode.begin()
            let trick = try XCTUnwrap(mode.shot?.trick)
            for i in 1...DailyRecord.maxTries {
                XCTAssertTrue(mode.mayTry(trick), "try \(i) is allowed")
                mode.noteTry(made: false, rest: nil)
                XCTAssertEqual(mode.triesUsed, i)
            }
            XCTAssertTrue(mode.finished)
            XCTAssertFalse(mode.mayTry(trick))
            mode.noteTry(made: true, rest: mode.mark)
            XCTAssertEqual(mode.triesUsed, DailyRecord.maxTries, "a sixth try is not counted")
            XCTAssertEqual(mode.current?.made, false)
            model.trickMode.yourTurn()
            XCTAssertNotEqual(model.trickMode.phase, .aiming, "Your turn is refused after five tries")
            model.trickMode.tryAgain()
            XCTAssertNotEqual(model.trickMode.phase, .aiming, "Try again is refused after five tries")
            model.trickMode.end()
        }
    }

    func testTheAnswerIsRefusedUntilTheDayIsFinished() throws {
        try withDevice { defaults in
            let model = ShowpieceModel()
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 1) })
            mode.begin()
            let trick = try XCTUnwrap(mode.shot?.trick)
            XCTAssertFalse(mode.mayWatch(trick))
            model.trickMode.watch()
            XCTAssertEqual(model.trickMode.phase, .ready, "Watch it did nothing before the day is finished")
            mode.noteTry(made: false, rest: nil)
            XCTAssertFalse(mode.mayWatch(trick), "one miss does not finish the day")
            for _ in 2...DailyRecord.maxTries { mode.noteTry(made: false, rest: nil) }
            XCTAssertTrue(mode.mayWatch(trick), "after five misses the answer can be watched")
            model.trickMode.watch()
            XCTAssertEqual(model.trickMode.phase, .watching, "Watch it plays the answer once the day is finished")
            model.trickMode.end()
        }
    }

    func testAMakeWritesTheRecordAndIsReportedOnce() throws {
        try withDevice { defaults in
            let model = ShowpieceModel()
            let sink = Sink()
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 2) })
            mode.resultSink = sink
            mode.begin()
            let mark = try XCTUnwrap(mode.mark)
            let shot = try XCTUnwrap(mode.shot)
            mode.noteTry(made: false, rest: nil)
            XCTAssertTrue(sink.results.isEmpty, "a miss with tries left finishes nothing")
            // The second try makes it, the white ball 1.2 cm from the mark.
            mode.noteTry(made: true, rest: mark + Vec2(0.012, 0))
            let day = try XCTUnwrap(DailyRecord.load(from: defaults).day(2), "the record was saved")
            XCTAssertEqual(day.madeOnTry, 2)
            XCTAssertEqual(day.shotID, shot.entry.id)
            XCTAssertEqual(try XCTUnwrap(day.distance), 0.012, accuracy: 1e-9)
            XCTAssertEqual(day.score, DailyScore.score(madeOnTry: 2, distance: 0.012))
            XCTAssertEqual(mode.streak(asOf: 2), 1)
            XCTAssertEqual(sink.results.count, 1)
            XCTAssertEqual(sink.results.first?.score, day.score)
            XCTAssertEqual(sink.results.first?.streak, 1)
            mode.noteTry(made: true, rest: mark)
            XCTAssertEqual(sink.results.count, 1, "a finished day is reported once")
            XCTAssertTrue(model.trickMode.doneIDs.isEmpty || !model.trickMode.doneIDs.contains(shot.trick.id),
                          "a daily make never joins the trick shots' own progress")
            model.trickMode.end()
        }
    }

    func testASecondVisitTheSameDayShowsTheResult() throws {
        try withDevice { defaults in
            let model = ShowpieceModel()
            let first = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 5) })
            first.begin()
            first.noteTry(made: false, rest: nil)
            first.noteTry(made: true, rest: first.mark)
            model.trickMode.end()

            // A later launch the same day: a new mode reading the same record.
            let again = DailyMode(model: model, defaults: defaults, clock: {
                DailyBank.startDate.addingTimeInterval(5 * DailyBank.secondsPerDay + 23 * 3600)
            })
            again.begin()
            let trick = try XCTUnwrap(again.shot?.trick)
            XCTAssertTrue(again.finished, "the day's result is shown")
            XCTAssertEqual(again.current?.madeOnTry, 2)
            XCTAssertFalse(again.mayTry(trick), "no more tries the same day")
            XCTAssertTrue(again.mayWatch(trick))
            model.trickMode.yourTurn()
            XCTAssertEqual(again.triesUsed, 2, "nothing more was counted")
            model.trickMode.end()

            // The next day is a new shot with five tries.
            let tomorrow = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 6) })
            tomorrow.begin()
            XCTAssertFalse(tomorrow.finished)
            XCTAssertEqual(tomorrow.triesUsed, 0)
            XCTAssertEqual(tomorrow.streak(asOf: 6), 1, "yesterday's make carries the streak into today")
            model.trickMode.end()
        }
    }

    func testLeavingGivesThePlayersSurfaceBack() throws {
        try withDevice { defaults in
            // A day on dive-bar felt, entered from the Moon.
            let d = try XCTUnwrap(AuthoredDaily.all.firstIndex { $0.surface == .diveBar }, "a dive-bar day")
            let model = ShowpieceModel()
            model.setSurface(.moon)
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: d) })
            mode.begin()
            XCTAssertEqual(model.surface, .diveBar)
            mode.begin()
            XCTAssertEqual(model.surface, .diveBar, "opening it again keeps the shot's surface")
            model.trickMode.end()
            XCTAssertEqual(model.surface, .moon, "the player's own surface is back")
        }
    }

    func testOrdinaryTrickShotsAreUntouched() throws {
        try withDevice { defaults in
            let model = ShowpieceModel()
            let mode = DailyMode(model: model, defaults: defaults, clock: { Self.noon(ofDay: 0) })
            mode.begin()
            let trick = try XCTUnwrap(TrickShots.all.first { !$0.pending && !$0.isBreak })
            // Another trick shot from the list: the gate stays but answers as for any trick shot.
            model.trickMode.begin(trick)
            XCTAssertFalse(DailyMode.showing(model))
            XCTAssertTrue(mode.mayWatch(trick))
            XCTAssertTrue(mode.mayTry(trick))
            XCTAssertTrue(mode.keepsProgress(trick))
            XCTAssertNil(mode.startSettings(for: trick))
            model.trickMode.watch()
            XCTAssertEqual(model.trickMode.phase, .watching, "Watch it plays at once for a trick shot")
            model.trickMode.end()
        }
    }
}
