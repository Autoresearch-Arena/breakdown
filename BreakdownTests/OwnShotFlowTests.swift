// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Make it again (0.7.7, plans/23-Nov-2026-make-it-again-plan.md, tests 11 and 12): a saved shot played through
//          the real model and trick-shot mode. A saved bumper-pool shot is set up, solved and recorded on bumper pool
//          (hook M1) and the player's table comes back when the mode ends; Watch it on a saved shot strikes the saved
//          stroke bit for bit (hook T2, OwnShotProof.arm through the model's kept strike), so its recording's motion
//          is the saved one.
//          The device settings these tests write (the opening seen, the table, the surface) are kept and put back, as
//          ModelFlowTests does (its helpers are private, so the pattern is copied), and the app's shelf is swapped for a
//          memory shelf for the length of each test, so the player's own saved shots are never touched.
// SRP/DRY check: Pass - checked ModelFlowTests (same device pattern, copied because its helpers are private) and
//          OwnShotTests (the shot builders are repeated here in their short form, since a test class's private helpers
//          are not shared).
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import XCTest

@MainActor
final class OwnShotFlowTests: XCTestCase {
    /// Device settings these tests write; what they held before is put back after each test.
    private static let touchedKeys = [GameSettings.seenOpeningKey, TableKind.storageKey, PlaySurface.storageKey]

    /// Runs `body` with the opening marked as seen and a memory shelf as the app's shelf, then puts back the settings
    /// and the app's own shelf.
    private func withDevice(_ body: () throws -> Void) rethrows {
        var saved: [String: Any] = [:]
        for key in Self.touchedKeys {
            if let value = UserDefaults.standard.object(forKey: key) { saved[key] = value }
        }
        let shelf = OwnShotShelf.shared
        OwnShotShelf.shared = OwnShotShelf(fileURL: nil)
        UserDefaults.standard.set(true, forKey: GameSettings.seenOpeningKey)
        defer {
            OwnShotShelf.shared = shelf
            for key in Self.touchedKeys {
                if let value = saved[key] {
                    UserDefaults.standard.set(value, forKey: key)
                } else {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        }
        try body()
    }

    /// The straight pot struck in free play on the cloth, saved (OwnShotTests test 1's shot).
    private func straightPotShot() throws -> OwnShot {
        let input = RideDemo.straightPot()
        let g = PoolParameters().modelGeneration
        let tl = PoolSolver.simulate(ShowpieceModel.solverCopy(input, table: .standard, surface: .cloth, generation: g))
        let s = input.strike
        let a = ShotAttempt(isBreak: false, breakSeed: 0, start: input.positions, timeline: tl,
                            aim: atan2(s.direction.y, s.direction.x) * 180 / Double.pi, power: s.speed,
                            powerRange: PlayerShotSpeed.ordinary, tipUp: s.tipUp, tipSide: s.tipSide,
                            elevation: s.elevation, seed: input.seed, input: input, surface: .cloth, table: .standard,
                            generation: g)
        return try XCTUnwrap(OwnShot.make(from: a, kind: nil, number: 1))
    }

    /// A shot on bumper pool from the table's own opening shot (its goal need not hold here).
    private func bumperPoolShot() -> OwnShot {
        let input = TableKind.bumperPool.openingShot
        let s = input.strike
        return OwnShot(id: OwnShot.idPrefix + "bumper-flow", name: "Bumper", saved: Date(timeIntervalSince1970: 0),
                       tableRaw: "bumperPool", surfaceRaw: "cloth", generation: PoolParameters().modelGeneration,
                       start: input.positions,
                       strike: OwnStrike(directionX: s.direction.x, directionY: s.direction.y, speed: s.speed,
                                         tipUp: s.tipUp, tipSide: s.tipSide, elevation: s.elevation, seed: input.seed),
                       drops: [OwnDrop(ball: 1, pocket: 6)], firstHit: 1, bank: nil, kindRaw: nil,
                       motionHash: "0", window: nil, made: false)
    }

    // MARK: 11. A saved bumper-pool shot is solved on bumper pool

    func testPlayingASavedBumperPoolShotSolvesOnBumperPool() throws {
        try withDevice {
            let model = ShowpieceModel()
            let own = bumperPoolShot()
            XCTAssertTrue(OwnShotShelf.shared.add(own))
            OwnShotShelf.shared.play(own, model: model)
            XCTAssertEqual(model.trickMode.current?.id, own.id)
            XCTAssertEqual(model.physicsTable, .bumperPool, "the saved shot is not on its own table")
            XCTAssertEqual(model.solvedTable, .bumperPool, "the start was not laid out on bumper pool")
            XCTAssertEqual(model.layout, own.start)
            model.trickMode.watch()
            let attempt = try XCTUnwrap(model.currentAttempt, "Watch it struck nothing")
            XCTAssertEqual(attempt.table, .bumperPool, "Watch it was solved on another table")
            model.trickMode.end()
            XCTAssertEqual(model.physicsTable, model.tableKind, "the player's own table did not come back")
        }
    }

    // MARK: 12. Watch it strikes the saved stroke exactly

    func testWatchItStrikesTheSavedStrokeExactly() throws {
        try withDevice {
            let model = ShowpieceModel()
            let own = try straightPotShot()
            XCTAssertTrue(OwnShotShelf.shared.add(own))
            OwnShotShelf.shared.play(own, model: model)
            XCTAssertEqual(model.surface, .cloth)
            model.trickMode.watch()
            let attempt = try XCTUnwrap(model.currentAttempt, "Watch it struck nothing")
            // The input's seed, not the attempt's: that one is shootNow's serial seed.
            XCTAssertEqual(attempt.input.seed, own.strike.seed)
            XCTAssertEqual(String(attempt.motionHash, radix: 16), own.motionHash,
                           "Watch it did not play the saved stroke bit for bit")
            XCTAssertEqual(attempt.table, .standard)
        }
    }
}
