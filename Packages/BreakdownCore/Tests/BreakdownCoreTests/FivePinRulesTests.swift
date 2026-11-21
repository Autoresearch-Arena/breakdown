// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: One test per rule of the five-pin rule sheet (plans/21-Nov-2026-other-tables-games-plan.md) and a scripted
//          game to the target, on hand-built shots (TableRulesFixtures): each player's own ball, the pin values (white
//          2, red 4, red alone 10), the other player's ball on the red (3), pins knocked by the red, the fouls (a miss,
//          the red first, your own ball on a pin, a ball off the table) giving the shot's points to the other player
//          (never less than 2), turns passing every shot, the target winning, and the next layout moving balls off the
//          pins' spots and back from off the table so all the pins can stand again.
// SRP/DRY check: Pass - FivePinRules only; the shot reading is ShotFactsTests', the shared bookkeeping
//          MatchContractTests'.
import BreakdownLensModel
import BreakdownRules
import BreakdownTimeline
import XCTest

final class FivePinRulesTests: XCTestCase {
    private let rules = FivePinRules()
    private let table = TableShot.fivePin
    private let start = TableShot.fivePinStart

    private func fresh() -> MatchState { rules.initialState(playerNames: ["Ada", "Ben"]) }

    private func shot(_ state: MatchState, from layout: [Vec2]? = nil, ends: [Int: Vec2] = [:],
                      _ happenings: [TableShot.Happening]) -> ShotFacts {
        TableShot.facts(table: table, start: layout ?? start, cueBall: rules.cueBall(for: state.turn, in: state),
                        ends: ends, happenings)
    }

    private func rule(_ happenings: [TableShot.Happening], in state: MatchState? = nil) -> Ruling {
        let s = state ?? fresh()
        return rules.ruling(for: shot(s, happenings), call: nil, in: s)
    }

    func testEachPlayerStrikesTheirOwnBallAtTheOther() {
        let s = fresh()
        XCTAssertEqual(rules.cueBall(for: .first, in: s), 0)
        XCTAssertEqual(rules.cueBall(for: .second, in: s), 1)
        XCTAssertEqual(rules.targetBall(for: .first), 1)
        XCTAssertEqual(rules.targetBall(for: .second), 0)
        XCTAssertEqual(s.ballsLeft, [0, 1, 3])
        XCTAssertTrue(rules.resetsPinsBetweenShots)
        XCTAssertTrue(rules.keepsRunningScore)
        XCTAssertEqual(rules.targetScore, 60)
    }

    func testWhitePinsScoreTwoEach() {
        let r = rule([.contact(0.2, 0, 1), .pin(0.6, ball: 1, pin: 1), .pin(0.65, ball: 1, pin: 3)])
        XCTAssertEqual(r.fouls, [])
        XCTAssertEqual(r.points, [4, 0])
        XCTAssertEqual(r.reasons, [.pointsScored, .pinsReset])
    }

    func testTheRedPinScoresFourWithOthersAndTenAlone() {
        XCTAssertEqual(rule([.contact(0.2, 0, 1), .pin(0.6, ball: 1, pin: 0), .pin(0.62, ball: 1, pin: 2)]).points, [6, 0])
        XCTAssertEqual(rule([.contact(0.2, 0, 1), .pin(0.6, ball: 1, pin: 0)]).points, [10, 0])
        XCTAssertEqual(FivePinRules.pinPoints([0, 1, 2, 3, 4]), 12)
        XCTAssertEqual(FivePinRules.pinPoints([]), 0)
    }

    func testTheOtherPlayersBallHittingTheRedScoresThree() {
        let r = rule([.contact(0.2, 0, 1), .contact(0.7, 1, 3)])
        XCTAssertEqual(r.points, [3, 0])
        // Your own ball touching the red after a good first hit scores nothing in this version.
        XCTAssertEqual(rule([.contact(0.2, 0, 1), .contact(0.7, 0, 3)]).points, [0, 0])
    }

    func testPinsKnockedByTheRedCount() {
        let r = rule([.contact(0.2, 0, 1), .contact(0.5, 1, 3), .pin(0.9, ball: 3, pin: 4)])
        XCTAssertEqual(r.points, [5, 0])
    }

    func testAMissGivesTheOtherPlayerTwo() {
        let r = rule([])
        XCTAssertEqual(r.fouls, [.noBallHit])
        XCTAssertEqual(r.points, [0, 2])
        XCTAssertEqual(r.nextShooter, .second)
        XCTAssertEqual(r.reasons, [.foul, .pointsScored])
    }

    func testHittingTheRedFirstIsAFoulAndItsPointsGoAcross() {
        let r = rule([.contact(0.2, 0, 3), .pin(0.5, ball: 3, pin: 1), .pin(0.55, ball: 3, pin: 2), .contact(0.9, 0, 1)])
        XCTAssertEqual(r.fouls, [.wrongBallFirst])
        XCTAssertEqual(r.points, [0, 4])
    }

    func testYourOwnBallKnockingAPinIsAFoul() {
        let r = rule([.contact(0.2, 0, 1), .pin(0.4, ball: 0, pin: 4), .pin(0.5, ball: 1, pin: 3)])
        XCTAssertEqual(r.fouls, [.ownBallKnockedPins])
        XCTAssertEqual(r.points, [0, 4], "every point the shot made goes to the other player")
    }

    func testABallOffTheTableIsAFoulAndGoesBackToItsSpot() {
        let s = fresh()
        let f = shot(s, [.contact(0.2, 0, 1), .offTable(0.8, ball: 1)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.fouls, [.objectBallOffTable])
        XCTAssertEqual(r.ballsToSpot, [1])
        XCTAssertEqual(r.points, [0, 2])
        let after = rules.applying(r, facts: f, to: s)
        XCTAssertEqual(after.ballsLeft, [0, 1, 3], "all three balls stay in play")
        let next = FivePinRules.nextLayout(after: f.resting, table: table, spots: TableShot.fivePinSpots)
        XCTAssertEqual(next[1], TableShot.fivePinSpots[1])
        XCTAssertEqual(next[0], start[0], "a ball resting clear of the pins stays put")

        // Your own ball off the table is the scratch.
        let own = shot(s, [.contact(0.2, 0, 1), .offTable(0.8, ball: 0)])
        XCTAssertEqual(rules.ruling(for: own, call: nil, in: s).fouls, [.scratch])
    }

    func testTheTurnPassesAfterEveryShot() {
        var s = fresh()
        let f = shot(s, [.contact(0.2, 0, 1), .pin(0.6, ball: 1, pin: 1)])
        let r = rules.ruling(for: f, call: nil, in: s)
        XCTAssertEqual(r.nextShooter, .second, "even a scoring shot passes the turn")
        s = rules.applying(r, facts: f, to: s)
        XCTAssertEqual(s.scores, [2, 0])
        XCTAssertEqual(rules.cueBall(for: s.turn, in: s), 1)
    }

    func testFirstToTheTargetWins() {
        var s = fresh()
        s.scores = [58, 30]
        s.isBreak = false
        let r = rule([.contact(0.2, 0, 1), .pin(0.6, ball: 1, pin: 2)], in: s)
        XCTAssertEqual(r.result, MatchResult(winner: .first, reason: .targetScoreReached))
        XCTAssertEqual(r.reasons.last, .gameOver)

        // A foul can carry the other player over the line.
        let foul = rule([], in: s)
        XCTAssertNil(foul.result, "30 + 2 is short of 60")
        s.scores = [10, 59]
        XCTAssertEqual(rule([], in: s).result, MatchResult(winner: .second, reason: .targetScoreReached))
        XCTAssertEqual(FivePinRules(targetScore: 20).targetScore, 20)
    }

    func testABallRestingWherePinsStandIsMovedBeforeTheNextShot() {
        var resting = start
        resting[3] = table.pins[1].center + Vec2(0.01, 0)   // the red came to rest on a white pin's spot
        resting[0] = Vec2(1.0, 0.4)                          // the white is well clear
        XCTAssertTrue(TableSpots.blocksAPin(resting[3], table: table))
        let next = FivePinRules.nextLayout(after: resting, table: table, spots: TableShot.fivePinSpots)
        XCTAssertEqual(next[3], TableShot.fivePinSpots[3], "back on the red's spot")
        XCTAssertEqual(next[0], resting[0])
        for b in [0, 1, 3] { XCTAssertFalse(TableSpots.blocksAPin(next[b], table: table)) }
    }

    func testASpotThatIsTakenSendsTheBallToTheNearestFreePlace() {
        var resting = start
        resting[1] = ShotFacts.offTable
        resting[3] = TableShot.fivePinSpots[1]!               // the red sits on the yellow's spot
        let next = FivePinRules.nextLayout(after: resting, table: table, spots: TableShot.fivePinSpots)
        XCTAssertNotEqual(next[1], TableShot.fivePinSpots[1])
        XCTAssertTrue(TableSpots.isFree(next[1], for: 1, among: next, table: table))
        XCTAssertEqual(next[3], resting[3], "the red was not in the way of a pin, so it stays")
    }

    func testAScriptedGame() {
        let short = FivePinRules(targetScore: 20)
        var s = short.initialState(playerNames: ["Ada", "Ben"])
        var layout = start
        func play(_ h: [TableShot.Happening]) -> Ruling {
            let f = TableShot.facts(table: table, start: layout, cueBall: short.cueBall(for: s.turn, in: s), h)
            let r = short.ruling(for: f, call: nil, in: s)
            layout = FivePinRules.nextLayout(after: f.resting, table: table, spots: TableShot.fivePinSpots)
            s = short.applying(r, facts: f, to: s)
            return r
        }
        // Ada: the yellow takes the red pin alone. 10 - 0.
        XCTAssertEqual(play([.contact(0.2, 0, 1), .pin(0.8, ball: 1, pin: 0)]).points, [10, 0])
        // Ben: his yellow misses the white. 10 - 0, Ada gets 2.
        XCTAssertEqual(play([.contact(0.3, 1, 3)]).fouls, [.wrongBallFirst])
        XCTAssertEqual(s.scores, [12, 0])
        // Ada: the yellow runs into the red and two white pins fall. 12 + 3 + 4 = 19.
        XCTAssertEqual(play([.contact(0.2, 0, 1), .contact(0.6, 1, 3), .pin(0.9, ball: 3, pin: 1), .pin(1.0, ball: 3, pin: 2)])
                        .points, [7, 0])
        // Ben: the white he hits knocks a pin, but so does his own yellow. Ada gets 4.
        let foul = play([.contact(0.2, 1, 0), .pin(0.5, ball: 0, pin: 3), .pin(0.6, ball: 1, pin: 4)])
        XCTAssertEqual(foul.fouls, [.ownBallKnockedPins])
        XCTAssertEqual(foul.result, MatchResult(winner: .first, reason: .targetScoreReached))
        XCTAssertEqual(s.scores, [23, 0])
        XCTAssertTrue(s.isOver)
        XCTAssertEqual(s.shotCount, 4)
        XCTAssertEqual(s.foulHistory.map(\.player), [.second, .second])
    }
}
