// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: One test per rule of the bumper-pool rule sheet (plans/21-Nov-2026-other-tables-games-plan.md) and a
//          scripted game from the first shot to the result, on hand-built shots (TableRulesFixtures): who strikes which
//          ball, sinking your own shoots again, an empty shot passes, an opponent's ball in their cup counts for them,
//          the wrong cup and a ball off the table are fouls that put the ball back (on its start spot or the nearest
//          free place), a foul outweighs a sink, and all five down wins whoever sank the last.
// SRP/DRY check: Pass - BumperPoolRules only; the shot reading is ShotFactsTests', the shared bookkeeping
//          MatchContractTests'.
import BreakdownLensModel
import BreakdownRules
import BreakdownTimeline
import XCTest

final class BumperPoolRulesTests: XCTestCase {
    private let rules = BumperPoolRules()
    private let table = TableShot.bumperPool
    private let start = TableShot.bumperPoolStart

    private func fresh() -> MatchState { rules.initialState(playerNames: ["Ada", "Ben"]) }

    /// The facts of a shot by whoever's turn it is in `state`, from `layout`.
    private func shot(_ state: MatchState, from layout: [Vec2]? = nil, ends: [Int: Vec2] = [:],
                      _ happenings: [TableShot.Happening]) -> ShotFacts {
        TableShot.facts(table: table, start: layout ?? start, cueBall: rules.cueBall(for: state.turn, in: state),
                        ends: ends, happenings)
    }

    /// Only the listed balls on the table.
    private func layout(_ placed: [Int: Vec2]) -> [Vec2] {
        var l = TableShot.empty()
        for (b, p) in placed { l[b] = p }
        return l
    }

    func testTheGameStartsWithAllTenBallsAndNoCalls() {
        let s = fresh()
        XCTAssertEqual(s.kind, .bumperPool)
        XCTAssertEqual(s.ballsLeft, [0, 1, 2, 3, 4, 9, 10, 11, 12, 13])
        XCTAssertEqual(rules.ballsLeft(for: .first, in: s), [0, 1, 2, 3, 4])
        XCTAssertEqual(rules.ballsLeft(for: .second, in: s), [9, 10, 11, 12, 13])
        XCTAssertFalse(rules.mayCall(0, in: s))
        XCTAssertFalse(rules.usesCalls)
        XCTAssertEqual(rules.playerCount, 2...2)
        XCTAssertEqual(BumperPoolRules.targetHole, [1, 0])
    }

    func testEachPlayerStrikesTheirMarkedBallFirstThenTheRestInOrder() {
        var s = fresh()
        XCTAssertEqual(rules.cueBall(for: .first, in: s), 0)
        XCTAssertEqual(rules.cueBall(for: .second, in: s), 9)
        s.ballsLeft = [2, 4, 9, 10, 11, 12, 13]
        XCTAssertEqual(rules.cueBall(for: .first, in: s), 2, "marked ball gone: the lowest number left")
        s.ballsLeft = [0, 3, 12]
        XCTAssertEqual(rules.cueBall(for: .first, in: s), 0, "the marked ball first while it is on the table")
        XCTAssertEqual(rules.cueBall(for: .second, in: s), 12)
    }

    func testSinkingYourOwnBallInYourCupShootsAgain() {
        let s = fresh()
        let f = shot(s, [.contact(0.2, 0, 1), .hole(0.9, ball: 1, hole: 1)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.nextShooter, .first)
        XCTAssertEqual(r.fouls, [])
        XCTAssertEqual(r.reasons, [.legalPot])
        let after = rules.applying(r, facts: f, to: s)
        XCTAssertFalse(after.ballsLeft.contains(1))
        XCTAssertEqual(rules.ballsLeft(for: .first, in: after), [0, 2, 3, 4])
    }

    func testAShotThatSinksNothingPassesTheTurn() {
        let s = fresh()
        let f = shot(s, ends: [0: Vec2(0.5, 0.3)], [])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.nextShooter, .second)
        XCTAssertEqual(r.reasons, [.noLegalPot])
        XCTAssertNil(r.result)
    }

    func testAnOpponentsBallInTheirOwnCupCountsForThem() {
        let s = fresh()
        let f = shot(s, [.contact(0.3, 0, 10), .hole(1.0, ball: 10, hole: 0)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.fouls, [])
        XCTAssertEqual(r.nextShooter, .second, "helping the other side does not earn another shot")
        let after = rules.applying(r, facts: f, to: s)
        XCTAssertEqual(rules.ballsLeft(for: .second, in: after), [9, 11, 12, 13])
    }

    func testABallInTheWrongCupIsAFoulAndComesBack() {
        let s = fresh()
        // Ada's ball 2 runs back into her own end's cup (hole 0), the cup Ben's balls go into.
        let f = shot(s, [.contact(0.2, 0, 2), .hole(0.8, ball: 2, hole: 0)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.fouls, [.wrongCup])
        XCTAssertEqual(r.ballsToSpot, [2])
        XCTAssertEqual(r.nextShooter, .second)
        XCTAssertEqual(r.reasons, [.foul, .noLegalPot, .ballSpotted])
        let after = rules.applying(r, facts: f, to: s)
        XCTAssertTrue(after.ballsLeft.contains(2), "the ball is back in play")
        XCTAssertEqual(after.consecutiveFouls, [1, 0])
        // Its start spot is free, so it goes straight back there.
        let next = BumperPoolRules.nextLayout(after: f, ruling: r, start: start, table: table)
        XCTAssertEqual(next[2], start[2])
    }

    func testABallOffTheTableIsAFoulAndComesBack() {
        let s = fresh()
        let f = shot(s, [.contact(0.2, 0, 3), .offTable(0.6, ball: 3), .offTable(0.7, ball: 0)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.fouls, [.scratch, .objectBallOffTable], "the struck ball is the scratch, the other an object ball")
        XCTAssertEqual(r.ballsToSpot, [0, 3])
        XCTAssertEqual(r.nextShooter, .second)
        let next = BumperPoolRules.nextLayout(after: f, ruling: r, start: start, table: table)
        XCTAssertEqual(next[0], start[0])
        XCTAssertEqual(next[3], start[3])
    }

    func testAReturningBallGoesToTheNearestFreePlaceWhenItsSpotIsTaken() {
        let s = fresh()
        // Ball 1 drops in the wrong cup while Ben's ball 9 has come to rest right on ball 1's start spot.
        let f = shot(s, ends: [9: start[1]], [.contact(0.2, 0, 1), .hole(0.8, ball: 1, hole: 0)])
        let r = rules.ruling(for: f, call: nil, in: s)
        let next = BumperPoolRules.nextLayout(after: f, ruling: r, start: start, table: table)
        XCTAssertNotEqual(next[1], start[1])
        XCTAssertTrue(TableSpots.isFree(next[1], for: 1, among: next, table: table))
        XCTAssertGreaterThan(next[1].x, start[1].x, "stepped toward the middle of the table")
    }

    func testAFoulOutweighsSinkingYourOwnBall() {
        let s = fresh()
        let f = shot(s, [.contact(0.2, 0, 1), .hole(0.8, ball: 1, hole: 1), .hole(0.9, ball: 0, hole: 0)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.fouls, [.wrongCup])
        XCTAssertEqual(r.nextShooter, .second)
        let after = rules.applying(r, facts: f, to: s)
        XCTAssertFalse(after.ballsLeft.contains(1), "the good sink still stays down")
        XCTAssertTrue(after.ballsLeft.contains(0), "the wrong-cup ball comes back")
    }

    func testAllFiveDownWins() {
        var s = fresh()
        s.ballsLeft = [4, 9, 12]
        s.isBreak = false
        let f = shot(s, from: layout([4: Vec2(0.9, 0.4), 9: start[9], 12: start[12]]), [.hole(1.0, ball: 4, hole: 1)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.result, MatchResult(winner: .first, reason: .allBallsSunk))
        XCTAssertEqual(r.reasons, [.gameOver])
        XCTAssertTrue(rules.applying(r, facts: f, to: s).isOver)
    }

    func testSinkingTheOpponentsLastBallMakesThemWin() {
        var s = fresh()
        s.ballsLeft = [0, 1, 13]
        let f = shot(s, from: layout([0: start[0], 1: start[1], 13: Vec2(0.4, 0.4)]),
                     [.contact(0.3, 0, 13), .hole(0.9, ball: 13, hole: 0)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.result, MatchResult(winner: .second, reason: .allBallsSunk))
    }

    func testAScriptedGame() {
        var s = fresh()
        var layout = start
        func play(ends: [Int: Vec2] = [:], _ h: [TableShot.Happening]) -> Ruling {
            let f = shot(s, from: layout, ends: ends, h)
            let r = rules.ruling(for: f, call: nil, in: s)
            layout = BumperPoolRules.nextLayout(after: f, ruling: r, start: start, table: table)
            s = rules.applying(r, facts: f, to: s)
            return r
        }
        // Ada banks her marked ball in, then misses.
        XCTAssertEqual(play([.hole(1.2, ball: 0, hole: 1)]).nextShooter, .first)
        XCTAssertEqual(rules.cueBall(for: .first, in: s), 1)
        XCTAssertEqual(play(ends: [1: Vec2(0.7, 0.2)], []).nextShooter, .second)
        // Ben sinks his marked ball and two more, then puts one in the wrong cup.
        XCTAssertEqual(play([.hole(1.0, ball: 9, hole: 0)]).nextShooter, .second)
        XCTAssertEqual(play([.contact(0.2, 10, 11), .hole(0.9, ball: 10, hole: 0), .hole(1.1, ball: 11, hole: 0)]).nextShooter,
                       .second)
        XCTAssertEqual(play([.hole(1.0, ball: 12, hole: 1)]).fouls, [.wrongCup])
        XCTAssertEqual(s.turn, .first)
        XCTAssertEqual(rules.ballsLeft(for: .second, in: s), [12, 13])
        XCTAssertEqual(layout[12], start[12], "back on its own start spot")
        // Ada runs her last four.
        for b in 1...3 { XCTAssertNil(play([.hole(1.0, ball: b, hole: 1)]).result) }
        XCTAssertEqual(play([.hole(1.0, ball: 4, hole: 1)]).reasons, [.gameOver])
        XCTAssertEqual(s.result, MatchResult(winner: .first, reason: .allBallsSunk))
        XCTAssertEqual(s.shotCount, 9)
        XCTAssertEqual(s.foulHistory, [FoulRecord(shot: 5, player: .second, fouls: [.wrongCup])])
    }
}
