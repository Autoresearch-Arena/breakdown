// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The shot of the day bank and the other tables' numbers as data (0.7.10 bank, plans/25-Nov-2026-shot-of-the-
//          day-plan.md stage 4). The three tables moved into the package (AuthoredTables) agree with the rules tests'
//          hand-built TableSpecs (TableRulesFixtures, written from the app's table files before the move), so the move
//          changed no number. The bank is at least a hundred shots, a whole number of weeks, every place on its day's
//          kind of shot from the first day (a Thursday), no two neighbours of one family (wrap included), every entry
//          with a mark on its table, a playable window, its stroke inside the miscue limit of its own table's ball, a
//          raised cue only at an angle the cue-angle control offers, and a leave ball that is on the table. Whether each
//          answer is still made is BreakProbe "verify" (the upload gate); this file checks what needs no solve.
// SRP/DRY check: Pass - data checks only; the rhythm rule is AuthoredDaily.fits, read, not restated.
import BreakdownAuthored
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import XCTest

final class AuthoredDailyTests: XCTestCase {
    // MARK: The tables moved into the package

    private func assertSame(_ authored: AuthoredTable, _ fixture: TableSpec, file: StaticString = #filePath, line: UInt = #line) {
        let t = authored.parameters.tableSpec
        XCTAssertEqual(t.length, fixture.length, accuracy: 1e-12, "\(authored) length", file: file, line: line)
        XCTAssertEqual(t.width, fixture.width, accuracy: 1e-12, "\(authored) width", file: file, line: line)
        XCTAssertEqual(t.ballRadius, fixture.ballRadius, accuracy: 1e-12, "\(authored) ball", file: file, line: line)
        XCTAssertFalse(t.pocketsEnabled, "\(authored) has no edge pockets", file: file, line: line)
        XCTAssertEqual(t.posts.map(\.center), fixture.posts.map(\.center), "\(authored) posts", file: file, line: line)
        XCTAssertEqual(t.posts.map(\.radius), fixture.posts.map(\.radius), "\(authored) post radii", file: file, line: line)
        XCTAssertEqual(t.pins.count, fixture.pins.count, "\(authored) pins", file: file, line: line)
        for (a, b) in zip(t.pins, fixture.pins) {
            XCTAssertEqual((a.center - b.center).length, 0, accuracy: 1e-12, "\(authored) pin", file: file, line: line)
            XCTAssertEqual(a.radius, b.radius, accuracy: 1e-12, file: file, line: line)
            XCTAssertEqual(a.mass, b.mass, accuracy: 1e-12, file: file, line: line)
        }
        XCTAssertEqual(t.bedHoles.count, fixture.bedHoles.count, "\(authored) holes", file: file, line: line)
        for (a, b) in zip(t.bedHoles, fixture.bedHoles) {
            XCTAssertEqual((a.center - b.center).length, 0, accuracy: 1e-12, "\(authored) hole", file: file, line: line)
            XCTAssertEqual(a.radius, b.radius, accuracy: 1e-12, file: file, line: line)
            XCTAssertEqual(a.captureRadius, b.captureRadius, accuracy: 1e-12, file: file, line: line)
        }
    }

    func testTheOtherTablesKeepTheirNumbers() {
        assertSame(.bumperPool, TableShot.bumperPool)
        assertSame(.fivePin, TableShot.fivePin)
        assertSame(.barBilliards, TableShot.barBilliards)
        // The fixtures write 0.22 where the table adds 0.140 and 0.080: equal to the last bit or two only.
        for (a, b) in [(AuthoredTable.bumperPool, TableShot.bumperPoolStart), (.barBilliards, TableShot.barBilliardsStart)] {
            let start = a.startLayout ?? []
            XCTAssertEqual(start.count, 16, "\(a)")
            for (p, q) in zip(start, b) { XCTAssertEqual((p - q).length, 0, accuracy: 1e-12, "\(a) start") }
        }
        XCTAssertNil(AuthoredTable.standard.startLayout)
        // The pool table changes nothing, so every pool shot hashes exactly as before.
        XCTAssertEqual(AuthoredTable.standard.parameters.tableSpec.length, PoolParameters().tableLength)
        XCTAssertTrue(AuthoredTable.standard.parameters.pocketsEnabled)
    }

    // MARK: The bank

    func testTheBankIsAHundredShotsInWholeWeeks() {
        let bank = AuthoredDaily.all
        XCTAssertGreaterThanOrEqual(bank.count, 100)
        XCTAssertEqual(bank.count % 7, 0, "a whole number of weeks, so the rhythm holds when the list wraps")
        XCTAssertEqual(Set(bank.map(\.id)).count, bank.count, "duplicate ids")
    }

    func testTheFirstDayIsAThursday() {
        // 26 November 2026 at midnight UTC, the app's DailyBank.startDate: 1_795_651_200 s since 1970.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let weekday = calendar.component(.weekday, from: Date(timeIntervalSince1970: 1_795_651_200))
        XCTAssertEqual(weekday, 5, "Sunday is 1, so Thursday is 5")
        XCTAssertEqual(AuthoredDaily.firstWeekday, .thursday)
        XCTAssertEqual(AuthoredDaily.weekday(ofIndex: 0), .thursday)
        XCTAssertEqual(AuthoredDaily.weekday(ofIndex: 4), .monday)
        XCTAssertEqual(AuthoredDaily.weekday(ofIndex: 10), .sunday)
    }

    func testEveryDayHoldsItsRhythm() {
        let bank = AuthoredDaily.all
        for (i, e) in bank.enumerated() {
            let day = AuthoredDaily.weekday(ofIndex: i)
            XCTAssertTrue(AuthoredDaily.fits(e, on: day), "\(e.id) on day \(i + 1), a \(day)")
            let next = bank[(i + 1) % bank.count]
            XCTAssertNotEqual(e.family, next.family, "\(e.id) and \(next.id) are neighbours of one family")
        }
        // Monday easy: every Monday shot is rated easy.
        for (i, e) in bank.enumerated() where AuthoredDaily.weekday(ofIndex: i) == .monday {
            XCTAssertEqual(e.difficulty, 1, "\(e.id): Monday is the easy day")
        }
    }

    func testEveryEntryIsPlayable() {
        let offered = [0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80].map { AuthoredLessons.sine(forAngle: $0) }
        for e in AuthoredDaily.all {
            let p = e.table.parameters
            XCTAssertNotNil(e.mark, "\(e.id): no mark")
            if let m = e.mark {
                XCTAssertTrue(m.x >= 0 && m.x <= p.tableLength && m.y >= 0 && m.y <= p.tableWidth, "\(e.id): mark off the bed")
            }
            XCTAssertGreaterThan(e.window.aim, 0, e.id)
            XCTAssertGreaterThan(e.window.power, 0, e.id)
            XCTAssertGreaterThan(e.window.tipUp, 0, e.id)
            XCTAssertTrue((1...3).contains(e.difficulty), e.id)
            XCTAssertEqual(e.layout.count, 16, e.id)
            XCTAssertTrue(NextShot.isOnTable(e.layout[0]), "\(e.id): no cue ball")
            XCTAssertFalse(e.goal.drops.isEmpty && e.goal.secondHit == nil, "\(e.id): a goal with nothing to make")
            let tip = (e.answer.tipUp * e.answer.tipUp + e.answer.tipSide * e.answer.tipSide).squareRoot()
            XCTAssertLessThanOrEqual(tip, p.miscueOffsetLimit + 1e-12, "\(e.id): the tip is past the miscue limit")
            if e.source == .authored {
                XCTAssertTrue(offered.contains { abs($0 - e.answer.elevation) < 1e-12 }, "\(e.id): a cue angle the control does not offer")
            }
            if let l = e.leave {
                XCTAssertTrue(NextShot.isOnTable(e.layout[l]), "\(e.id): the leave ball is not on the table")
                XCTAssertFalse(e.goal.drops.contains { $0.ball == l }, "\(e.id): the leave ball is a goal ball")
            }
            for d in e.goal.drops {
                XCTAssertTrue(NextShot.isOnTable(e.layout[d.ball]), "\(e.id): goal ball \(d.ball) is not on the table")
                if let k = d.pocket {
                    let holes = (p.pocketsEnabled ? 6 : 0) + p.bedHoles.count
                    XCTAssertTrue(p.pocketsEnabled ? k < holes : (k >= 6 && k < 6 + p.bedHoles.count),
                                  "\(e.id): pocket \(k) is not on its table")
                }
            }
        }
    }
}
