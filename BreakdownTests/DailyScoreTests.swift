// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The shot of the day's score (App/Daily/DailyScore.swift; plans/25-Nov-2026-shot-of-the-day-plan.md, stage 1
//          item 7): every try's points with the white ball on the mark, the precision steps of half a centimetre, a far
//          miss of the mark keeping only the try points, no make scoring nothing, and no score ever below zero, whatever
//          the distance (huge, infinite, not a number, negative).
// SRP/DRY check: Pass - checks only; the rule is DailyScore's.
@testable import Breakdown
import XCTest

final class DailyScoreTests: XCTestCase {
    func testEveryTryOnTheMark() {
        XCTAssertEqual(DailyScore.score(madeOnTry: 1, distance: 0), 1199)
        XCTAssertEqual(DailyScore.score(madeOnTry: 2, distance: 0), 999)
        XCTAssertEqual(DailyScore.score(madeOnTry: 3, distance: 0), 799)
        XCTAssertEqual(DailyScore.score(madeOnTry: 4, distance: 0), 599)
        XCTAssertEqual(DailyScore.score(madeOnTry: 5, distance: 0), 399)
        XCTAssertEqual(DailyScore.maximum, 1199)
    }

    func testNoMakeScoresNothing() {
        XCTAssertEqual(DailyScore.score(madeOnTry: nil, distance: 0), 0)
        XCTAssertEqual(DailyScore.score(madeOnTry: 0, distance: 0), 0, "there is no try zero")
        XCTAssertEqual(DailyScore.score(madeOnTry: 6, distance: 0), 0, "there are only five tries")
    }

    func testPrecisionCountsWholeHalfCentimetres() {
        XCTAssertEqual(DailyScore.precisionPoints(distance: 0), 199)
        XCTAssertEqual(DailyScore.precisionPoints(distance: 0.0049), 199, "under half a centimetre is still on the mark")
        XCTAssertEqual(DailyScore.precisionPoints(distance: 0.0051), 198)
        XCTAssertEqual(DailyScore.precisionPoints(distance: 0.0123), 197)
        XCTAssertEqual(DailyScore.precisionPoints(distance: 0.5025), 99)
        XCTAssertEqual(DailyScore.score(madeOnTry: 2, distance: 0.0123), 997)
    }

    func testAFarMissOfTheMarkKeepsOnlyTheTryPoints() {
        XCTAssertEqual(DailyScore.precisionPoints(distance: 0.9975), 0, "199 and a half half-centimetres away")
        XCTAssertEqual(DailyScore.precisionPoints(distance: 2.0), 0)
        XCTAssertEqual(DailyScore.score(madeOnTry: 1, distance: 2.0), 1000)
        XCTAssertEqual(DailyScore.score(madeOnTry: 5, distance: 2.0), 200)
    }

    func testNeverBelowZero() {
        for d in [1e9, Double.greatestFiniteMagnitude, .infinity, .nan] {
            XCTAssertEqual(DailyScore.precisionPoints(distance: d), 0, "\(d)")
            XCTAssertEqual(DailyScore.score(madeOnTry: 3, distance: d), 600, "\(d)")
        }
        XCTAssertEqual(DailyScore.precisionPoints(distance: -0.3), 199, "a negative distance is on the mark")
        for t in 1...5 {
            XCTAssertGreaterThanOrEqual(DailyScore.score(madeOnTry: t, distance: 10), 0)
        }
    }
}
