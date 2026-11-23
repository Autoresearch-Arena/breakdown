// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: 0.7.7 achievements' save and kept shot (App/Achievements/AchievementRecord.swift and AchievementShot.swift;
//          plans/23-Nov-2026-achievements-plan.md, Tests): a record survives a save and a load through a throwaway
//          UserDefaults suite; a stored record missing fields still loads; earning twice keeps the first date and shot;
//          a kept shot from a real attempt solves back to the very same motion (and says it does not when its physics
//          generation is changed); and a stored unit direction comes back bit for bit through input(), despite
//          CueStrike's normalising init.
// SRP/DRY check: Pass - checks only. The attempt is TestShots.attempt (the model's own recording shape); the solve is
//          the kept shot's own, through ShowpieceModel.solverCopy.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import XCTest

final class AchievementRecordTests: XCTestCase {
    /// A throwaway defaults suite, removed when the test ends.
    private func withSuite(_ body: (UserDefaults) throws -> Void) rethrows {
        let name = "AchievementRecordTests-\(UUID().uuidString)"
        guard let suite = UserDefaults(suiteName: name) else { return XCTFail("no defaults suite") }
        defer { suite.removePersistentDomain(forName: name) }
        try body(suite)
    }

    /// The stop-dead trick answer as a recorded attempt.
    private func stopDeadAttempt() -> ShotAttempt? {
        guard let shot = TrickShots.shot(id: "stop-dead"), case .layout(let start) = shot.setup else { return nil }
        let tl = TestShots.shot(from: start, shot.solution)
        return TestShots.attempt(start: start, timeline: tl, shot.solution)
    }

    func testARecordSurvivesASaveAndALoad() {
        withSuite { defaults in
            var r = AchievementRecord()
            let shot = stopDeadAttempt().flatMap { AchievementShot(attempt: $0, signature: [1, 2]) }
            XCTAssertNotNil(shot)
            r.earn("dead-stop", on: Date(timeIntervalSinceReferenceDate: 800_000_000), shot: shot, seen: false)
            r.earn(Achievements.everyTable, on: Date(timeIntervalSinceReferenceDate: 800_000_100), shot: nil, seen: true)
            r.notePlayed(table: TableKind.standard.rawValue, surface: PlaySurface.moon.rawValue)
            r.seeded = true
            r.save(to: defaults)
            XCTAssertEqual(AchievementRecord.load(from: defaults), r)
        }
    }

    func testARecordMissingFieldsStillLoads() throws {
        try withSuite { defaults in
            // Only "earned", and an entry whose shot is not a shot at all: the date is kept, the shot dropped.
            let json = #"{"earned": {"bank": {"date": 800000000, "shot": {"nonsense": true}, "seen": false}}}"#
            defaults.set(try XCTUnwrap(json.data(using: .utf8)), forKey: AchievementRecord.storageKey)
            let r = AchievementRecord.load(from: defaults)
            XCTAssertEqual(r.earned["bank"]?.date, Date(timeIntervalSinceReferenceDate: 800_000_000))
            XCTAssertNil(r.earned["bank"]?.shot)
            XCTAssertEqual(r.earned["bank"]?.seen, false)
            XCTAssertEqual(r.tablesPlayed, [])
            XCTAssertFalse(r.seeded)
        }
    }

    func testEarningTwiceKeepsTheFirst() {
        var r = AchievementRecord()
        let first = Date(timeIntervalSinceReferenceDate: 1)
        let shot = stopDeadAttempt().flatMap { AchievementShot(attempt: $0, signature: []) }
        XCTAssertTrue(r.earn("bank", on: first, shot: shot, seen: false))
        XCTAssertFalse(r.earn("bank", on: Date(timeIntervalSinceReferenceDate: 2), shot: nil, seen: true))
        XCTAssertEqual(r.earned["bank"]?.date, first)
        XCTAssertEqual(r.earned["bank"]?.shot, shot)
        XCTAssertEqual(r.earned["bank"]?.seen, false)
    }

    func testAKeptShotSolvesBackToTheSameMotion() throws {
        let attempt = try XCTUnwrap(stopDeadAttempt())
        var shot = try XCTUnwrap(AchievementShot(attempt: attempt, signature: []))
        let again = try XCTUnwrap(shot.solve())
        XCTAssertTrue(again.sameAsEarned)
        XCTAssertEqual(again.attempt.motionHash, attempt.motionHash)
        // Through a save and a load too (every number survives the JSON).
        let decoded = try JSONDecoder().decode(AchievementShot.self, from: JSONEncoder().encode(shot))
        XCTAssertEqual(decoded, shot)
        XCTAssertEqual(try XCTUnwrap(decoded.solve()).sameAsEarned, true)
        // Another physics generation is another recording.
        shot.generation = shot.generation == 1 ? 2 : 1
        XCTAssertEqual(try XCTUnwrap(shot.solve()).sameAsEarned, false)
    }

    func testAStoredUnitDirectionComesBackExactly() throws {
        let attempt = try XCTUnwrap(stopDeadAttempt())
        let shot = try XCTUnwrap(AchievementShot(attempt: attempt, signature: []))
        XCTAssertEqual(shot.input().strike.direction, shot.direction)
        XCTAssertEqual(shot.input().strike.direction, attempt.input.strike.direction)
        // An unknown table or surface does not solve.
        var unknown = shot
        unknown.surface = "no-such-surface"
        XCTAssertNil(unknown.solvedTimeline())
    }
}
