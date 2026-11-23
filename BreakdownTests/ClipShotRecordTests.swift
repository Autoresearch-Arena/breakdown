// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Checks for the shot settings a Lens clip carries (App/Clips/ClipShotRecord.swift, 0.7.7): the record survives
//          encoding and decoding unchanged, and solving it again moves exactly as the shot did (same motionHash), for
//          an ordinary shot (the straight pot, default solver version) and for the player's break (built with version
//          1, which the record keeps).
// SRP/DRY check: Pass - checks only; attempts are built the way the model records them.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import XCTest

final class ClipShotRecordTests: XCTestCase {
    /// An attempt as the model keeps one, from a built input and its solved recording.
    static func attempt(_ input: ShotInput, timeline: Timeline, isBreak: Bool) -> ShotAttempt {
        let d = input.strike.direction
        return ShotAttempt(isBreak: isBreak, breakSeed: isBreak ? input.seed : 0, start: input.positions,
                           timeline: timeline, aim: atan2(d.y, d.x) * 180 / Double.pi, power: input.strike.speed,
                           powerRange: PlayerShotSpeed.ordinary, tipUp: input.strike.tipUp,
                           tipSide: input.strike.tipSide, elevation: input.strike.elevation, seed: input.seed,
                           input: input, surface: .cloth, table: .standard,
                           generation: input.parameters.modelGeneration)
    }

    func testTheRecordEncodesAndDecodesUnchanged() throws {
        let a = Self.attempt(RideDemo.straightPot(), timeline: TestShots.straightPot(), isBreak: false)
        let record = ClipShotRecord(attempt: a)
        let data = try JSONEncoder().encode(record)
        XCTAssertEqual(try JSONDecoder().decode(ClipShotRecord.self, from: data), record)
    }

    func testTheStraightPotSolvesToTheSameMotion() throws {
        let a = Self.attempt(RideDemo.straightPot(), timeline: TestShots.straightPot(), isBreak: false)
        let record = ClipShotRecord(attempt: a)
        let solved = try XCTUnwrap(record.solve())
        XCTAssertEqual(a.resolved(on: solved, surface: a.surface).motionHash, a.motionHash)
    }

    func testTheBreakKeepsVersionOneAndSolvesToTheSameMotion() throws {
        let a = Self.attempt(TestShots.breakInput(), timeline: TestShots.breakShot(), isBreak: true)
        let record = ClipShotRecord(attempt: a)
        XCTAssertEqual(record.parametersVersion, 1)
        let solved = try XCTUnwrap(record.solve())
        XCTAssertEqual(a.resolved(on: solved, surface: a.surface).motionHash, a.motionHash)
    }
}
