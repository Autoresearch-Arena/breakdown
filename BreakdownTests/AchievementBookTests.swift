// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: 0.7.7 achievements' live book (App/Achievements/AchievementBook.swift; plans/23-Nov-2026-achievements-plan.md,
//          Tests): the cross-bank answer earns Bank shot and queues its note; a stroke the game played for the player
//          earns nothing; a quiet shot (the first-launch opening) earns without a note; opening the list returns what was
//          new and leaves nothing new; and behind the menu no note shows.
//          Each test keeps its ShowpieceModel in a local for its whole body (the book holds it unowned, so a temporary
//          would be freed at once and the first read would crash), and builds its own book on a throwaway defaults suite
//          with readsProgress false, so no sweep reads this machine's own lessons, trick shots or medals and nothing is
//          written to the app's own save. The model's own `achievements` book is never touched.
// SRP/DRY check: Pass - checks only. Shots are TestShots' solves of the authored answers; the reading is the judge's.
@testable import Breakdown
import BreakdownLensModel
import BreakdownTimeline
import Foundation
import XCTest

@MainActor
final class AchievementBookTests: XCTestCase {
    /// A throwaway defaults suite and its name (to remove it after).
    private func makeSuite() throws -> (defaults: UserDefaults, name: String) {
        let name = "AchievementBookTests-\(UUID().uuidString)"
        return (try XCTUnwrap(UserDefaults(suiteName: name)), name)
    }

    /// The cross-bank answer as the model would read it after finishStrike.
    private func crossBank() throws -> AchievementShotContext {
        let shot = try XCTUnwrap(TrickShots.shot(id: "cross-bank"))
        guard case .layout(let start) = shot.setup else { throw XCTSkip("cross-bank is not a laid-out shot") }
        let tl = TestShots.shot(from: start, shot.solution)
        return AchievementShotContext(timeline: tl, facts: ShotFacts(timeline: tl, start: start, cueBall: 0),
                                      captions: CaptionEngine.make(from: tl, surface: .cloth), table: .standard,
                                      isBreak: false, freePlay: true,
                                      attempt: TestShots.attempt(start: start, timeline: tl, shot.solution))
    }

    func testABankEarnsBankAndQueuesItsNote() throws {
        try XCTSkipUnless(AchievementBook.enabled, "a test launch flag is set")
        let model = ShowpieceModel()
        let suite = try makeSuite()
        defer { suite.defaults.removePersistentDomain(forName: suite.name) }
        let book = AchievementBook(model: model, defaults: suite.defaults, readsProgress: false)
        book.noteShot(try crossBank(), version: model.timelineVersion, quiet: false)
        XCTAssertNotNil(book.earned("bank"))
        XCTAssertNotNil(book.earned("bank")?.shot)
        XCTAssertTrue(book.toasts.contains("bank"))
        XCTAssertNotNil(book.drawings["bank"])
        // Saved: a fresh load of the suite has it.
        XCTAssertNotNil(AchievementRecord.load(from: suite.defaults).earned["bank"])
        // The table and surface were noted.
        XCTAssertEqual(book.record.tablesPlayed, [TableKind.standard.rawValue])
        XCTAssertEqual(book.record.surfacesPlayed, [PlaySurface.cloth.rawValue])
        withExtendedLifetime(model) {}
    }

    func testAStrokeTheGamePlayedEarnsNothing() throws {
        try XCTSkipUnless(AchievementBook.enabled, "a test launch flag is set")
        let model = ShowpieceModel()
        let suite = try makeSuite()
        defer { suite.defaults.removePersistentDomain(forName: suite.name) }
        let book = AchievementBook(model: model, defaults: suite.defaults, readsProgress: false)
        book.strikeStarted(byPerson: false)
        book.noteShot(try crossBank(), version: model.timelineVersion, quiet: false)
        XCTAssertNil(book.earned("bank"))
        XCTAssertEqual(book.toasts, [])
        XCTAssertEqual(book.earnedCount, 0)
        withExtendedLifetime(model) {}
    }

    func testAQuietShotEarnsWithoutANote() throws {
        try XCTSkipUnless(AchievementBook.enabled, "a test launch flag is set")
        let model = ShowpieceModel()
        let suite = try makeSuite()
        defer { suite.defaults.removePersistentDomain(forName: suite.name) }
        let book = AchievementBook(model: model, defaults: suite.defaults, readsProgress: false)
        book.noteShot(try crossBank(), version: model.timelineVersion, quiet: true)
        XCTAssertNotNil(book.earned("bank"))
        XCTAssertEqual(book.toasts, [])
        withExtendedLifetime(model) {}
    }

    func testOpeningTheListReturnsWhatWasNewAndClearsIt() throws {
        try XCTSkipUnless(AchievementBook.enabled, "a test launch flag is set")
        let model = ShowpieceModel()
        let suite = try makeSuite()
        defer { suite.defaults.removePersistentDomain(forName: suite.name) }
        let book = AchievementBook(model: model, defaults: suite.defaults, readsProgress: false)
        book.noteShot(try crossBank(), version: model.timelineVersion, quiet: false)
        XCTAssertGreaterThan(book.newCount, 0)
        let fresh = book.listOpened()
        XCTAssertTrue(fresh.contains("bank"))
        XCTAssertEqual(book.newCount, 0)
        XCTAssertEqual(AchievementRecord.load(from: suite.defaults).earned["bank"]?.seen, true)
        withExtendedLifetime(model) {}
    }

    func testNoNoteShowsBehindTheMenu() throws {
        try XCTSkipUnless(AchievementBook.enabled, "a test launch flag is set")
        try XCTSkipIf(TitleScreen.launchSkipsTitle, "this launch skips the menu")
        let model = ShowpieceModel()
        let suite = try makeSuite()
        defer { suite.defaults.removePersistentDomain(forName: suite.name) }
        let book = AchievementBook(model: model, defaults: suite.defaults, readsProgress: false)
        book.noteShot(try crossBank(), version: model.timelineVersion, quiet: false)
        XCTAssertFalse(book.toasts.isEmpty)
        // A fresh model starts on the menu (or, on a first launch, in the opening): not calm either way.
        book.frame(0.1)
        XCTAssertNil(book.shownToast)
        XCTAssertNil(book.shownReplayEnd)
        withExtendedLifetime(model) {}
    }
}
