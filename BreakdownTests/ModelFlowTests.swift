// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: Checks for the 0.7.5 model-flow fixes in ShowpieceModel (plans/22-Nov-2026-v075-whatif-and-gaps-plan.md,
//          stream model-flow, and the coordinator's addition M-A), run against the real model and real solves:
//          Practice and Watch the intro go back to the pool table after another table was played; the three mode
//          lists open one at a time and every route into play closes them; the computer's level survives a new model
//          (it is stored on the device); the Tables list's tick (tableOnScreen) is the free-play table and nothing
//          while a trick shot, the stroke drill or a match is up; Continue on a paused held moment plays on; Auto
//          clears a chosen speed; the stroke, play, speed and Try again do nothing while the menu is open; opening the
//          menu ends a guided Lens replay; Ride held off for a guided replay comes back when it ends or a plain replay
//          starts.
//          Each test saves and restores the device settings it touches (the opening seen, the chosen table, the
//          computer's level, free play's rack), so running the tests leaves the simulator's app as it found it. The
//          opening is marked seen before each model is made, so no first-launch hand-over is running underneath.
// SRP/DRY check: Pass - checks only. Every action goes through the model's own methods; shots are the model's own
//          solves (the -jumpDemo shot, a trick shot's layout, the racks), nothing is built here.
@testable import Breakdown
import BreakdownRules
import Foundation
import XCTest

@MainActor
final class ModelFlowTests: XCTestCase {
    /// Device settings these tests write; what they held before is kept by prepareDevice and put back by
    /// restoreDevice. (Called from each test with a defer rather than through setUp and tearDown overrides, which
    /// would need to match XCTestCase's own actor isolation under Swift 6.)
    private static let touchedKeys = [GameSettings.seenOpeningKey, TableKind.storageKey, GameSettings.computerLevelKey,
                                      GameSettings.freePlayRackKey]
    private var savedDefaults: [String: Any] = [:]

    /// Keep the touched settings, then set a later launch (no first-launch hand-over under the test) with free play's
    /// default rack, the fifteen-ball triangle, so Practice lays out a rack to break.
    private func prepareDevice() {
        savedDefaults = [:]
        for key in Self.touchedKeys {
            if let value = UserDefaults.standard.object(forKey: key) { savedDefaults[key] = value }
        }
        UserDefaults.standard.set(true, forKey: GameSettings.seenOpeningKey)
        UserDefaults.standard.removeObject(forKey: GameSettings.freePlayRackKey)
    }

    /// Put every touched setting back as it was before prepareDevice.
    private func restoreDevice() {
        for key in Self.touchedKeys {
            if let value = savedDefaults[key] {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    /// A trick shot that is played from a layout (not a break) and can be played now.
    private var layoutTrick: TrickShot? { TrickShots.all.first { !$0.pending && !$0.isBreak } }

    // MARK: Practice and Watch the intro land on the pool table (item 2)

    func testPracticeAfterAnotherTableRacksThePoolTable() {
        prepareDevice(); defer { restoreDevice() }
        let model = ShowpieceModel()
        model.playTable(.barBilliards)
        XCTAssertEqual(model.physicsTable, .barBilliards, "the set-up did not put bar billiards on")
        model.startGame()
        XCTAssertEqual(model.physicsTable, .standard, "Practice stayed on the last table")
        XCTAssertEqual(model.tableKind, .standard)
        XCTAssertEqual(model.solvedTable, .standard, "the table on screen is not the pool table")
        XCTAssertTrue(model.racked, "Practice did not lay out a rack")
        XCTAssertEqual(UserDefaults.standard.string(forKey: TableKind.storageKey), TableKind.standard.rawValue,
                       "the pool table was not stored as the choice")
    }

    func testWatchTheIntroAfterAnotherTablePlaysThePoolOpening() {
        prepareDevice(); defer { restoreDevice() }
        // A new model starts on the pool table's opening (every launch does), solved on the stored surface: the
        // recording Watch the intro must put back.
        let reference = ShowpieceModel().timeline
        let model = ShowpieceModel()
        model.playTable(.bumperPool)
        XCTAssertEqual(model.solvedTable, .bumperPool, "the set-up did not put bumper pool on")
        model.watchBreak()
        XCTAssertEqual(model.solvedTable, .standard, "Watch the intro was solved on another table")
        XCTAssertEqual(model.physicsTable, .standard)
        XCTAssertEqual(model.timeline.ballCount, reference.ballCount)
        XCTAssertEqual(model.timeline.duration, reference.duration, accuracy: 1e-9,
                       "Watch the intro did not play the pool table's opening shot")
        XCTAssertEqual(model.stage, .normalBreak)
    }

    // MARK: Lists (item 3)

    private func openEveryList(_ model: ShowpieceModel) {
        model.trickMode.listOpen = true
        model.lessonMode.listOpen = true
        model.eightBallMode.listOpen = true
    }

    private func assertNoListOpen(_ model: ShowpieceModel, after route: String, line: UInt = #line) {
        XCTAssertFalse(model.trickMode.listOpen, "\(route) left the trick list open", line: line)
        XCTAssertFalse(model.lessonMode.listOpen, "\(route) left the lesson list open", line: line)
        XCTAssertFalse(model.eightBallMode.listOpen, "\(route) left the eight-ball list open", line: line)
    }

    func testShowListOpensOnlyThatList() {
        prepareDevice(); defer { restoreDevice() }
        let model = ShowpieceModel()
        model.lessonMode.listOpen = true
        model.showList(.tricks)
        XCTAssertTrue(model.trickMode.listOpen)
        XCTAssertFalse(model.lessonMode.listOpen, "the lesson list stayed open under the trick list")
        XCTAssertFalse(model.eightBallMode.listOpen)
        model.showList(.eightBall)
        XCTAssertFalse(model.trickMode.listOpen)
        XCTAssertTrue(model.eightBallMode.listOpen)
        model.closeAllLists()
        assertNoListOpen(model, after: "closeAllLists")
    }

    func testEveryRouteIntoPlayClosesTheLists() {
        prepareDevice(); defer { restoreDevice() }
        let model = ShowpieceModel()
        openEveryList(model)
        model.startGame()
        assertNoListOpen(model, after: "Practice")
        openEveryList(model)
        model.watchBreak()
        assertNoListOpen(model, after: "Watch the intro")
        openEveryList(model)
        // With or without a save on this device: a Continue that loads closes them, and one that fails does too.
        model.continueSavedMatch()
        assertNoListOpen(model, after: "Continue match")
        openEveryList(model)
        model.enterStrokeDrill()
        assertNoListOpen(model, after: "the stroke drill")
    }

    // MARK: The computer's level (item 5)

    func testComputerLevelIsRememberedByANewModel() {
        prepareDevice(); defer { restoreDevice() }
        let model = ShowpieceModel()
        model.computerLevel = .hard
        XCTAssertEqual(UserDefaults.standard.string(forKey: GameSettings.computerLevelKey), "hard")
        XCTAssertEqual(ShowpieceModel().computerLevel, .hard, "a new model forgot the computer's level")
        model.computerLevel = .easy
        XCTAssertEqual(ShowpieceModel().computerLevel, .easy)
        // A stored value that is not a level reads as Medium.
        UserDefaults.standard.set("grandmaster", forKey: GameSettings.computerLevelKey)
        XCTAssertEqual(ShowpieceModel().computerLevel, .medium)
    }

    // MARK: The table on screen (item 6)

    func testTableOnScreenIsTheFreePlayTableOnly() throws {
        prepareDevice(); defer { restoreDevice() }
        let model = ShowpieceModel()
        model.startGame()
        XCTAssertEqual(model.tableOnScreen, .standard)
        model.playTable(.fivePin)
        XCTAssertEqual(model.tableOnScreen, .fivePin)

        let trick = try XCTUnwrap(layoutTrick, "no playable trick shot")
        model.trickMode.begin(trick)
        XCTAssertNil(model.tableOnScreen, "a trick shot is up, so no table is the player's")
        model.trickMode.end()

        model.strokeDrill.begin()
        XCTAssertNil(model.tableOnScreen, "the stroke drill is up, so no table is the player's")

        model.startMatch(.barBilliards, players: 1)
        XCTAssertNotNil(model.match)
        XCTAssertNil(model.tableOnScreen, "a match is up, so no table is the player's")
        // The match saved itself when it started; ending it removes that save again.
        model.endMatch()
        XCTAssertEqual(model.tableOnScreen, .fivePin, "after the match free play's own table is back")
    }

    // MARK: Continue, Auto and the menu (items 7 and 9, M-A)

    func testContinueOnAPausedHeldMomentPlaysOn() {
        prepareDevice(); defer { restoreDevice() }
        let model = ShowpieceModel()
        model.playJumpDemo()
        model.replay(withLens: true)
        XCTAssertTrue(model.guided, "the jump shot's Lens replay is not guided, so it has no moments to hold")
        // Not holding yet: Continue jumps to the first moment and holds there.
        model.nextBeat()
        XCTAssertTrue(model.holding, "Continue did not stop on the first explained moment")
        model.playing = false
        model.nextBeat()
        XCTAssertFalse(model.holding)
        XCTAssertTrue(model.playing, "Continue on a paused held moment left the replay stopped")
    }

    func testAutoClearsAChosenSpeed() {
        prepareDevice(); defer { restoreDevice() }
        let model = ShowpieceModel()
        model.playJumpDemo()
        model.setRate(0.5)
        XCTAssertEqual(model.chosenRate, 0.5)
        model.playing = false
        model.setAutoRate()
        XCTAssertNil(model.chosenRate, "Auto kept the fixed speed")
        XCTAssertTrue(model.playing, "Auto did not play a paused replay")
    }

    func testNothingMovesBehindTheMenu() throws {
        prepareDevice(); defer { restoreDevice() }
        let model = ShowpieceModel()
        model.startGame()
        model.openMenu()
        XCTAssertTrue(model.menuOpen)

        // The stroke: nothing struck, and no refusal recorded for a card to pulse behind the menu.
        XCTAssertNotEqual(model.fireStroke(), .breakStruck)
        XCTAssertNil(model.lastRefusal, "a refusal was recorded behind the menu")
        XCTAssertTrue(model.racked, "the rack was broken behind the menu")
        XCTAssertFalse(model.isSolving)

        // Play and the speed.
        let playing = model.playing
        model.togglePlay()
        XCTAssertEqual(model.playing, playing, "Play or Pause acted behind the menu")
        let rate = model.chosenRate
        model.setRate(2)
        XCTAssertEqual(model.chosenRate, rate, "the speed changed behind the menu")

        // Try again: a trick shot's layout is solved directly, so a played attempt is on screen at once.
        let trick = try XCTUnwrap(layoutTrick, "no playable trick shot")
        model.trickMode.begin(trick)
        XCTAssertFalse(model.menuOpen)
        model.shootNow()
        XCTAssertNotNil(model.currentAttempt, "the trick shot's stroke left no attempt")
        model.scrub(to: model.duration)
        XCTAssertTrue(model.canTryAgain)
        model.openMenu()
        model.tryAgain()
        XCTAssertNotNil(model.currentAttempt, "Try again reset the table behind the menu")
        XCTAssertNil(model.ghost, "Try again armed a retry behind the menu")
        // With the menu closed the same call works, so the check above tested the menu and nothing else.
        model.closeMenu()
        model.tryAgain()
        XCTAssertNotNil(model.ghost, "Try again did nothing with the menu closed")
        model.trickMode.end()
    }

    func testOpeningTheMenuEndsAGuidedLensReplay() {
        prepareDevice(); defer { restoreDevice() }
        let model = ShowpieceModel()
        model.playJumpDemo()
        model.replay(withLens: true)
        XCTAssertTrue(model.guided)
        model.openMenu()
        XCTAssertFalse(model.guided, "the guided Lens replay was still on behind the menu")
        XCTAssertFalse(model.lensOn, "the Lens was left drawn behind the menu")
        model.closeMenu()
        XCTAssertFalse(model.lensOn, "Continue came back to the Lens")
    }

    // MARK: Ride around guided replays (item 8)

    func testRideHeldForAGuidedReplayComesBack() {
        prepareDevice(); defer { restoreDevice() }
        let model = ShowpieceModel()
        model.playJumpDemo()
        model.setRide(true)
        model.holdRideForGuidedReplay()
        XCTAssertFalse(model.rideOn, "Ride was not switched off for the guided replay")
        model.replay(withLens: true)
        XCTAssertFalse(model.rideOn, "a Lens replay gave Ride back at its start")
        // Played to its end: the next frame gives Ride back.
        model.scrub(to: model.duration)
        model.advance(1.0 / 60.0)
        XCTAssertTrue(model.rideOn, "Ride did not come back when the guided replay ended")

        // Left for a plain replay: Ride comes back at once.
        model.holdRideForGuidedReplay()
        model.replay(withLens: true)
        model.replay(withLens: false)
        XCTAssertTrue(model.rideOn, "Ride did not come back for a plain replay")

        // Ride the player turned off themselves is not brought back.
        model.holdRideForGuidedReplay()
        model.setRide(false)
        model.scrub(to: model.duration)
        model.advance(1.0 / 60.0)
        XCTAssertFalse(model.rideOn, "Ride came back after the player turned it off")
    }
}
