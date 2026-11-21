// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The Behind the 8-Ball judge (App/EightBall/EightBallJudge.swift) as unit tests. The judge already carries its
//          own checks, run until now only by the -eightJudgeCheck launch flag and read off the console: selfCheck()
//          (fouls, loss of game, made as called, double hit, cue and bridge touches, scoops, safeties, the scoring
//          arithmetic, the difficulty bands and the real-table card, each on a small hand-made table) and
//          checkAuthoredEscapes() (every authored escape of every situation, solved on its own cloth and judged: made as
//          called or a legal safety, no foul). Both return one line per check starting "PASS" or "FAIL"; these tests call
//          the same functions and fail on any FAIL line, naming it.
//          Runtime: checkAuthoredEscapes judges every escape with its full window sweep, many solves each, so it is the
//          slowest test in the target (tens of seconds in a Debug build, more on a slow machine).
// SRP/DRY check: Pass - no judging logic here; the checks live in the judge and are only asserted on.
@testable import Breakdown
import XCTest

final class EightBallJudgeTests: XCTestCase {
    private func assertAllPass(_ lines: [String], _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(lines.isEmpty, "\(what) ran no checks", file: file, line: line)
        // "TIME ..." lines report how long a judgement took; they are information, not checks.
        let checks = lines.filter { $0.hasPrefix("PASS ") || $0.hasPrefix("FAIL ") }
        XCTAssertFalse(checks.isEmpty, "\(what) reported no PASS or FAIL lines", file: file, line: line)
        for failed in checks where failed.hasPrefix("FAIL ") {
            XCTFail("\(what): \(failed)", file: file, line: line)
        }
    }

    func testJudgeSelfChecks() {
        assertAllPass(EightBallJudge.selfCheck(), "EightBallJudge.selfCheck")
    }

    func testEveryAuthoredEscapeIsMadeOrASafety() {
        XCTAssertFalse(EightBallSituations.all.isEmpty)
        let lines = EightBallJudge.checkAuthoredEscapes()
        XCTAssertEqual(lines.count, EightBallSituations.all.reduce(0) { $0 + $1.escapes.count },
                       "one line per authored escape")
        assertAllPass(lines, "EightBallJudge.checkAuthoredEscapes")
    }
}
