// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: One test per rule of the bar-billiards rule sheet (plans/21-Nov-2026-other-tables-games-plan.md) and a
//          scripted two-player game against a short clock, on hand-built shots (TableRulesFixtures): hole values and the
//          red's double, a break that goes on while balls drop, a miss, the white and black pegs, balls coming back to
//          the tray and the red to its spot, the next white set on the D, all whites coming back when none is left to
//          play, the bar dropping when time is up, the game ending when no white is left, one player, and the clock.
//          The clock is injected: the tests set MatchState.clockRemaining or call ticking(_:by:), so nothing waits.
// SRP/DRY check: Pass - BarBilliardsRules only; the shot reading is ShotFactsTests', the shared bookkeeping
//          MatchContractTests'.
import BreakdownLensModel
import BreakdownRules
import BreakdownTimeline
import XCTest

final class BarBilliardsRulesTests: XCTestCase {
    private let rules = BarBilliardsRules()
    private let table = TableShot.barBilliards
    private let start = TableShot.barBilliardsStart
    private let d = TableShot.dSpot
    private let redSpot = TableShot.redSpot

    private func fresh(_ names: [String] = ["Ada", "Ben"]) -> MatchState { rules.initialState(playerNames: names) }

    private func shot(_ state: MatchState, from layout: [Vec2]? = nil, ends: [Int: Vec2] = [:],
                      _ happenings: [TableShot.Happening]) -> ShotFacts {
        TableShot.facts(table: table, start: layout ?? start, cueBall: rules.cueBall(for: state.turn, in: state),
                        ends: ends, happenings)
    }

    private func next(_ f: ShotFacts, _ s: MatchState) -> [Vec2] {
        rules.nextLayout(after: f, in: s, table: table, dSpot: d, redSpot: redSpot)
    }

    func testTheGameStartsWithEveryBallTheClockAndAnEmptyBreak() {
        let s = fresh()
        XCTAssertEqual(s.ballsLeft, Array(0...7))
        XCTAssertEqual(s.clockRemaining, BarBilliardsRules.standardClock)
        XCTAssertEqual(s.breakPoints, 0)
        XCTAssertEqual(rules.playerCount, 1...2)
        XCTAssertEqual(rules.turnClock, 900)
        XCTAssertTrue(rules.keepsRunningScore)
        XCTAssertEqual(rules.cueBall(for: .first, in: s), 0)
        XCTAssertEqual(BarBilliardsRules.holeValues, [200, 100, 50, 50, 30, 20, 10, 20, 30])
        XCTAssertEqual(BarBilliardsRules(clockLength: 60).initialState(playerNames: ["Ada"]).clockRemaining, 60)
    }

    func testEachHoleScoresItsValueAndTheRedScoresDouble() {
        let s = fresh()
        // The white hits the red: the red drops in the 100 (200 for the red), the white in the far 10.
        let f = shot(s, [.contact(0.2, 0, 3), .hole(0.8, ball: 3, hole: 1), .hole(1.1, ball: 0, hole: 6)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.points, [210, 0])
        XCTAssertEqual(r.fouls, [])
        XCTAssertEqual(r.nextShooter, .first)
        XCTAssertEqual(r.reasons, [.pointsScored, .legalPot, .ballsReturned, .ballSpotted])
    }

    func testABreakGoesOnWhileBallsDropAndEndsWhenNothingDrops() {
        var s = fresh()
        let first = shot(s, [.contact(0.2, 0, 3), .hole(0.9, ball: 0, hole: 2)])
        let r1 = rules.ruling(for: first, call: nil, in: s)
        XCTAssertEqual(r1.nextShooter, .first)
        var layout = next(first, s)
        s = rules.applying(r1, facts: first, to: s)
        XCTAssertEqual(s.breakPoints, 50)
        XCTAssertEqual(s.scores, [50, 0])

        let second = shot(s, from: layout, ends: [0: Vec2(1.0, 0.3)], [.contact(0.2, 0, 3)])
        let r2 = rules.ruling(for: second, call: nil, in: s)
        XCTAssertEqual(r2.reasons, [.noLegalPot])
        XCTAssertEqual(r2.nextShooter, .second)
        layout = next(second, s)
        s = rules.applying(r2, facts: second, to: s)
        XCTAssertEqual(s.breakPoints, 0, "the next break starts from nothing")
        XCTAssertEqual(s.scores, [50, 0], "points already scored are kept")
        XCTAssertEqual(layout[1], Vec2(1.0, 0.3), "the white left on the table stays there (as a tray white)")
        XCTAssertEqual(layout[0], d)
    }

    func testAMissScoresNothingEndsTheBreakAndTheBallGoesBack() {
        let s = fresh()
        // The white touches nothing but runs straight into the 50.
        let dropped = shot(s, [.hole(0.9, ball: 0, hole: 2)])
        let r = rules.ruling(for: dropped, call: nil, in: s)
        XCTAssertEqual(r.fouls, [.noBallHit])
        XCTAssertEqual(r.points, [0, 0])
        XCTAssertEqual(r.nextShooter, .second)

        // The white touches nothing and stops on the table: it is lifted back to the tray and played again from the D.
        let stopped = shot(s, ends: [0: Vec2(1.0, 0.6)], [])
        let r2 = rules.ruling(for: stopped, call: nil, in: s)
        XCTAssertEqual(r2.reasons, [.foul, .ballsReturned])
        let layout = next(stopped, s)
        XCTAssertEqual(layout[0], d)
        XCTAssertEqual(layout.filter(ShotFacts.isOnTable).count, 2, "the white on the D and the red, nothing else")
    }

    func testAWhitePegDownLosesTheBreak() {
        var s = fresh()
        s.scores = [400, 0]
        s.breakPoints = 150
        let f = shot(s, [.contact(0.2, 0, 3), .pin(0.5, ball: 3, pin: 1), .hole(0.9, ball: 0, hole: 0)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.points, [-150, 0], "the 200 that dropped scores nothing either")
        XCTAssertEqual(r.reasons.first, .whitePegDown)
        XCTAssertEqual(r.nextShooter, .second)
        let after = rules.applying(r, facts: f, to: s)
        XCTAssertEqual(after.scores, [250, 0])
        XCTAssertEqual(after.breakPoints, 0)
    }

    func testTheBlackPegDownLosesTheWholeScore() {
        var s = fresh()
        s.scores = [400, 120]
        s.breakPoints = 150
        let f = shot(s, [.contact(0.2, 0, 3), .pin(0.4, ball: 0, pin: 0), .pin(0.6, ball: 3, pin: 2)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.points, [-400, 0])
        XCTAssertEqual(r.reasons, [.blackPegDown], "the black peg outweighs the white")
        XCTAssertEqual(rules.applying(r, facts: f, to: s).scores, [0, 120])
    }

    func testDroppedBallsComeBackAndTheRedGoesBackOnItsSpot() {
        let s = fresh()
        let f = shot(s, [.contact(0.2, 0, 3), .hole(0.6, ball: 3, hole: 0), .hole(1.0, ball: 0, hole: 3)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.ballsToSpot, [BarBilliardsRules.redBall])
        XCTAssertEqual(rules.ballsReturningToHand(after: f, in: s), BarBilliardsRules.whiteBalls)
        XCTAssertEqual(rules.applying(r, facts: f, to: s).ballsLeft, Array(0...7), "nothing leaves the game")
        let layout = next(f, s)
        XCTAssertEqual(layout[3], redSpot)
        XCTAssertEqual(layout[0], d)
    }

    func testTheNextWhiteIsAlwaysTheOneOnTheD() {
        let s = fresh()
        // The white stops on the table after potting the red: a tray white takes its place there, ball 0 goes on the D.
        let f = shot(s, ends: [0: Vec2(1.0, 0.3)], [.contact(0.2, 0, 3), .hole(0.8, ball: 3, hole: 1)])
        let layout = next(f, s)
        let after = rules.applying(rules.ruling(for: f, call: nil, in: s), facts: f, to: s)
        XCTAssertEqual(rules.cueBall(for: after.turn, in: after), 0)
        XCTAssertEqual(layout[0], d)
        XCTAssertEqual(layout[1], Vec2(1.0, 0.3))
        XCTAssertEqual(layout[3], redSpot)
    }

    func testAllTheWhitesComeBackWhenNoneIsLeftToPlay() {
        let s = fresh()
        var layout = start
        // Six whites already resting on the table, out of the way; ball 0 on the D is the last in the tray.
        for (k, b) in [1, 2, 4, 5, 6, 7].enumerated() { layout[b] = Vec2(0.15 + 0.08 * Double(k), 0.08) }
        let f = shot(s, from: layout, ends: [0: Vec2(1.2, 0.55)], [.contact(0.2, 0, 3)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.reasons, [.noLegalPot, .ballsReturned])
        let nextLayout = next(f, s)
        XCTAssertEqual(nextLayout[0], d)
        for b in [1, 2, 4, 5, 6, 7] { XCTAssertFalse(ShotFacts.isOnTable(nextLayout[b]), "white \(b) is back in the tray") }
        XCTAssertEqual(nextLayout[3], start[3])
    }

    func testWhenTimeIsUpDroppedBallsStayDown() {
        var s = fresh()
        s.clockRemaining = 0
        XCTAssertTrue(rules.barIsDown(in: s))
        let f = shot(s, [.contact(0.2, 0, 3), .hole(0.8, ball: 3, hole: 4)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.points, [60, 0], "the red in the 30 still scores double")
        XCTAssertEqual(r.reasons.first, .timeUp)
        XCTAssertEqual(r.ballsToSpot, [], "the red does not come back")
        let after = rules.applying(r, facts: f, to: s)
        XCTAssertFalse(after.ballsLeft.contains(3))
        XCTAssertNil(after.result, "whites are still left to play")
        XCTAssertFalse(ShotFacts.isOnTable(next(f, s)[3]))
    }

    func testTheGameEndsWhenTheBarIsDownAndNoWhiteIsLeft() {
        var s = fresh()
        s.clockRemaining = 0
        s.scores = [300, 320]
        s.ballsLeft = [0, 3]
        var layout = TableShot.empty()
        layout[0] = d
        layout[3] = Vec2(0.85, 0.4)
        // Ada drops her last white in a 50: 350 against 320.
        let f = shot(s, from: layout, [.contact(0.2, 0, 3), .hole(0.9, ball: 0, hole: 2)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.result, MatchResult(winner: .first, reason: .timeExpired))
        XCTAssertEqual(r.reasons, [.timeUp, .pointsScored, .noLegalPot, .gameOver])
        let after = rules.applying(r, facts: f, to: s)
        XCTAssertEqual(after.scores, [350, 320])
        XCTAssertTrue(after.isOver)

        // The same last white stopping on the table ends it too: nothing is left in the tray.
        let stopped = shot(s, from: layout, ends: [0: Vec2(0.5, 0.2)], [.contact(0.2, 0, 3)])
        XCTAssertEqual(rules.ruling(for: stopped, call: nil, in: s).result, MatchResult(winner: .second, reason: .timeExpired))

        // A level score has no winner.
        s.scores = [320, 320]
        XCTAssertEqual(rules.ruling(for: stopped, call: nil, in: s).result, MatchResult(winner: nil, reason: .timeExpired))
    }

    func testOnePlayerKeepsTheTableAndPlaysForAScore() {
        var s = fresh(["Ada"])
        let f = shot(s, ends: [0: Vec2(1.0, 0.3)], [.contact(0.2, 0, 3)])
        XCTAssertEqual(rules.ruling(for: f, call: nil, in: s).nextShooter, .first)
        s.clockRemaining = 0
        s.ballsLeft = [0, 3]
        s.scores = [880]
        var layout = TableShot.empty()
        layout[0] = d
        layout[3] = redSpot
        let last = shot(s, from: layout, [.contact(0.2, 0, 3), .hole(0.9, ball: 0, hole: 0)])
        let r = rules.ruling(for: last, call: nil, in: s)
        XCTAssertEqual(r.result, MatchResult(winner: nil, reason: .timeExpired))
        XCTAssertEqual(rules.applying(r, facts: last, to: s).scores, [1080])
    }

    func testTheClockCountsDownAndStopsAtZero() {
        let s = fresh()
        XCTAssertEqual(rules.ticking(s, by: 100).clockRemaining, 800)
        XCTAssertEqual(rules.ticking(s, by: 5000).clockRemaining, 0)
        XCTAssertFalse(rules.barIsDown(in: rules.ticking(s, by: 899.5)))
        XCTAssertTrue(rules.barIsDown(in: rules.ticking(s, by: 900)))
        XCTAssertEqual(rules.ticking(s, by: -3), s, "time never runs backwards")
        var over = s
        over.result = MatchResult(winner: .first, reason: .timeExpired)
        XCTAssertEqual(rules.ticking(over, by: 10), over, "a finished game's clock stops")
    }

    func testAScriptedGame() {
        let game = BarBilliardsRules(clockLength: 60)
        var s = game.initialState(playerNames: ["Ada", "Ben"])
        var layout = start
        func play(after seconds: Double, ends: [Int: Vec2] = [:], _ h: [TableShot.Happening]) -> Ruling {
            s = game.ticking(s, by: seconds)
            let f = TableShot.facts(table: table, start: layout, cueBall: game.cueBall(for: s.turn, in: s), ends: ends, h)
            let r = game.ruling(for: f, call: nil, in: s)
            layout = game.nextLayout(after: f, in: s, table: table, dSpot: d, redSpot: redSpot)
            s = game.applying(r, facts: f, to: s)
            return r
        }
        // Ada: the red into the 200 (400), then a white into the 100, then nothing drops.
        XCTAssertEqual(play(after: 5, [.contact(0.2, 0, 3), .hole(0.8, ball: 3, hole: 0)]).points, [400, 0])
        XCTAssertEqual(play(after: 5, [.contact(0.2, 0, 3), .hole(0.9, ball: 0, hole: 1)]).points, [100, 0])
        XCTAssertEqual(s.breakPoints, 500)
        XCTAssertEqual(play(after: 5, ends: [0: Vec2(1.25, 0.6)], [.contact(0.2, 0, 3)]).nextShooter, .second)
        XCTAssertEqual(s.scores, [500, 0])
        // Ben: a 50, then he knocks a white peg and loses it.
        XCTAssertEqual(play(after: 5, [.contact(0.2, 0, 1), .hole(0.9, ball: 1, hole: 3)]).points, [0, 50])
        XCTAssertEqual(play(after: 5, [.contact(0.2, 0, 3), .pin(0.5, ball: 3, pin: 2)]).reasons, [.whitePegDown])
        XCTAssertEqual(s.scores, [500, 0])
        XCTAssertEqual(s.turn, .first)
        // Time runs out while Ada plays: the bar is down and the white she drops stays down.
        let barShot = play(after: 40, [.contact(0.2, 0, 3), .hole(0.9, ball: 0, hole: 8)])
        XCTAssertEqual(barShot.reasons.first, .timeUp)
        XCTAssertEqual(s.clockRemaining, 0)
        XCTAssertEqual(s.scores, [530, 0])
        XCTAssertFalse(s.ballsLeft.contains(0))
        // Play goes on with the whites left until none is left to play.
        var shots = 0
        while !s.isOver && shots < 20 {
            let b = game.cueBall(for: s.turn, in: s)
            _ = play(after: 1, [.contact(0.2, b, 3), .hole(0.9, ball: b, hole: 6)])
            shots += 1
        }
        XCTAssertTrue(s.isOver)
        XCTAssertEqual(s.result?.reason, .timeExpired)
        XCTAssertEqual(s.result?.winner, .first)
        XCTAssertEqual(s.ballsLeft.filter { BarBilliardsRules.whiteBalls.contains($0) }, [])
    }
}
