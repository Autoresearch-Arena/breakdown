// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: One test per nine-ball rule (BreakdownRules/NineBallRules.swift, plans/21-Nov-2026-rules-games-plan.md
//          package 4), each on a hand-built shot (RulesShotScript.swift): no calls, the break (legal, illegal, a
//          scratch), the lowest ball first, any legal pot keeps the turn, the 9 legally pocketed wins (on the break and
//          in a combination), the 9 on a foul is spotted, ball in hand anywhere after a foul, the warning after two
//          fouls in a row and the loss on the third, a legal shot clearing the run, and a scripted full game.
// SRP/DRY check: Pass - new; EightBallRulesTests covers eight-ball, MatchContractTests the shared bookkeeping.
import BreakdownLensModel
import BreakdownRules
import BreakdownTimeline
import XCTest

final class NineBallRulesTests: XCTestCase {
    private let rules = NineBallRules()
    /// Balls 1 to 9 on the table, 10 to 15 parked, as the diamond leaves them.
    private let nine = onlyStanding(Array(1...9))

    private func fresh() -> MatchState { rules.initialState(playerNames: ["Ada", "Ben"]) }

    /// After the break, Ada to shoot, with these balls left.
    private func playing(_ balls: [Int] = Array(1...9)) -> MatchState {
        var s = fresh()
        s.isBreak = false
        s.ballInHand = .none
        s.ballsLeft = balls
        return s
    }

    func testNoCallsAndTheDiamond() {
        XCTAssertEqual(rules.kind, .nineBall)
        XCTAssertEqual(rules.rack, .nineBallDiamond)
        XCTAssertFalse(rules.usesCalls)
        XCTAssertFalse(rules.mayCall(1, in: playing()))
        XCTAssertEqual(fresh().ballsLeft, Array(1...9))
        XCTAssertEqual(fresh().ballInHand, .behindHeadLine)
        XCTAssertEqual(rules.lowestBall(in: playing([4, 6, 9])), 4)
    }

    // MARK: The break

    func testALegalBreakWithAPotKeepsTheTurn() {
        let (r, s) = playShot(rules, ShotScript(start: nine, firstHit: 1, pocketed: [(5, 2)]), in: fresh())
        XCTAssertEqual(r.reasons, [.breakLegal, .legalPot])
        XCTAssertEqual(s.turn, .first)
        XCTAssertFalse(s.isBreak)
        XCTAssertEqual(s.ballsLeft, [1, 2, 3, 4, 6, 7, 8, 9])
    }

    func testABreakWithFourBallsToARailPassesTheTurn() {
        let (r, s) = playShot(rules, ShotScript(start: nine, firstHit: 1, toRail: [2, 3, 6, 7]), in: fresh())
        XCTAssertEqual(r.reasons, [.breakLegal, .noLegalPot])
        XCTAssertTrue(r.fouls.isEmpty)
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(s.ballInHand, BallInHand.none)
    }

    func testAnIllegalBreakIsAFoul() {
        let (r, s) = playShot(rules, ShotScript(start: nine, firstHit: 1, toRail: [2, 3]), in: fresh())
        XCTAssertEqual(r.fouls, [.noRailAfterContact])
        XCTAssertEqual(r.reasons, [.breakIllegal, .foul])
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(s.ballInHand, .anywhere)
        XCTAssertEqual(s.consecutiveFouls, [1, 0])
    }

    func testTheBreakMustHitTheOneFirst() {
        let (r, _) = playShot(rules, ShotScript(start: nine, firstHit: 2, pocketed: [(4, 0)]), in: fresh())
        XCTAssertEqual(r.fouls, [.wrongBallFirst])
        XCTAssertEqual(r.reasons, [.breakLegal, .foul])
    }

    func testAScratchOnTheBreakGivesBallInHandAnywhere() {
        let (r, s) = playShot(rules, ShotScript(start: nine, firstHit: 1, pocketed: [(3, 1), (0, 4)]), in: fresh())
        XCTAssertEqual(r.fouls, [.scratch])
        XCTAssertEqual(r.reasons, [.breakLegal, .scratchOnBreak, .foul])
        XCTAssertEqual(s.ballInHand, .anywhere)
        XCTAssertEqual(s.turn, .second)
    }

    func testTheNineOnTheBreakWins() {
        let (r, s) = playShot(rules, ShotScript(start: nine, firstHit: 1, pocketed: [(9, 3)]), in: fresh())
        XCTAssertEqual(r.result, MatchResult(winner: .first, reason: .nineBallPocketed))
        XCTAssertEqual(r.reasons, [.breakLegal, .legalPot, .gameOver])
        XCTAssertTrue(s.isOver)
    }

    // MARK: Ordinary shots

    func testTheLowestBallMustBeHitFirst() {
        let (r, s) = playShot(rules, ShotScript(start: onlyStanding([3, 5, 9]), firstHit: 5, pocketed: [(5, 1)]),
                          in: playing([3, 5, 9]))
        XCTAssertEqual(r.fouls, [.wrongBallFirst])
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(s.ballInHand, .anywhere)
        XCTAssertEqual(s.ballsLeft, [3, 9], "a ball pocketed on a foul stays down")
    }

    func testATieForTheFirstContactCountsTheLowestBall() {
        let (r, _) = playShot(rules, ShotScript(start: onlyStanding([3, 5, 9]), firstHit: 5, tieWith: 3, toRail: [3]),
                          in: playing([3, 5, 9]))
        XCTAssertTrue(r.fouls.isEmpty)
    }

    func testAnyLegallyPocketedBallKeepsTheTurn() {
        let (r, s) = playShot(rules, ShotScript(start: onlyStanding([3, 5, 9]), firstHit: 3, pocketed: [(5, 4)]),
                          in: playing([3, 5, 9]))
        XCTAssertEqual(r.reasons, [.legalPot])
        XCTAssertEqual(s.turn, .first)
        XCTAssertEqual(s.ballsLeft, [3, 9])
    }

    func testNothingDroppingPassesTheTurn() {
        let (r, s) = playShot(rules, ShotScript(start: onlyStanding([3, 9]), firstHit: 3, toRail: [3]), in: playing([3, 9]))
        XCTAssertEqual(r.reasons, [.noLegalPot])
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(s.ballInHand, BallInHand.none)
    }

    func testNoRailAfterContactAndNoBallHitAreFouls() {
        let (noRail, _) = playShot(rules, ShotScript(start: onlyStanding([3, 9]), firstHit: 3), in: playing([3, 9]))
        XCTAssertEqual(noRail.fouls, [.noRailAfterContact])
        let (miss, _) = playShot(rules, ShotScript(start: onlyStanding([3, 9]), toRail: [0]), in: playing([3, 9]))
        XCTAssertEqual(miss.fouls, [.noBallHit])
        let (off, s) = playShot(rules, ShotScript(start: onlyStanding([3, 6, 9]), firstHit: 3, toRail: [3], offTable: [6]),
                            in: playing([3, 6, 9]))
        XCTAssertEqual(off.fouls, [.objectBallOffTable])
        XCTAssertEqual(s.ballsLeft, [3, 9])
    }

    func testTheNineInACombinationWins() {
        let (r, _) = playShot(rules, ShotScript(start: onlyStanding([3, 9]), firstHit: 3, pocketed: [(9, 1)]),
                          in: playing([3, 9]))
        XCTAssertEqual(r.result, MatchResult(winner: .first, reason: .nineBallPocketed))
    }

    func testTheNineOnAFoulIsSpotted() {
        let (r, s) = playShot(rules, ShotScript(start: onlyStanding([3, 9]), firstHit: 3, pocketed: [(9, 1), (0, 0)]),
                          in: playing([3, 9]))
        XCTAssertNil(r.result)
        XCTAssertEqual(r.fouls, [.scratch])
        XCTAssertEqual(r.reasons, [.foul, .ballSpotted])
        XCTAssertEqual(r.ballsToSpot, [9])
        XCTAssertEqual(s.ballsLeft, [3, 9], "the 9 is back on the table")
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(s.ballInHand, .anywhere)

        // Off the table on a foul: spotted too.
        let (off, offState) = playShot(rules, ShotScript(start: onlyStanding([3, 9]), firstHit: 3, offTable: [9]),
                                   in: playing([3, 9]))
        XCTAssertEqual(off.ballsToSpot, [9])
        XCTAssertEqual(offState.ballsLeft, [3, 9])
    }

    // MARK: Three fouls

    func testAWarningAfterTwoFoulsAndALossOnTheThird() {
        let foul = ShotScript(start: onlyStanding([3, 9]), firstHit: 9, toRail: [9])   // the 9 first: wrong ball
        let pass = ShotScript(start: onlyStanding([3, 9]), firstHit: 3, toRail: [3])   // legal, nothing drops

        var s = playing([3, 9])
        var step = playShot(rules, foul, in: s); s = step.state                         // Ada, foul one
        XCTAssertFalse(step.ruling.reasons.contains(.foulWarning))
        step = playShot(rules, pass, in: s); s = step.state                             // Ben, legal
        step = playShot(rules, foul, in: s); s = step.state                             // Ada, foul two
        XCTAssertEqual(step.ruling.reasons, [.foul, .foulWarning])
        XCTAssertEqual(s.consecutiveFouls, [2, 0])
        step = playShot(rules, pass, in: s); s = step.state                             // Ben, legal
        step = playShot(rules, foul, in: s); s = step.state                             // Ada, foul three
        XCTAssertEqual(step.ruling.result, MatchResult(winner: .second, reason: .threeConsecutiveFouls))
        XCTAssertEqual(step.ruling.reasons, [.foul, .gameOver])
        XCTAssertTrue(s.isOver)
    }

    func testALegalShotClearsTheRunOfFouls() {
        let foul = ShotScript(start: onlyStanding([3, 9]), firstHit: 9, toRail: [9])
        let pot = ShotScript(start: onlyStanding([3, 4, 9]), firstHit: 3, pocketed: [(4, 1)])
        var s = playing([3, 4, 9])
        s.consecutiveFouls = [2, 0]
        let step = playShot(rules, pot, in: s)
        XCTAssertEqual(step.ruling.reasons, [.legalPot])
        XCTAssertEqual(step.state.consecutiveFouls, [0, 0])
        // A foul now is the first of a new run again: no warning.
        let again = playShot(rules, foul, in: playing([3, 9]))
        XCTAssertEqual(again.ruling.reasons, [.foul])
    }

    // MARK: A whole game

    func testAScriptedFullGame() {
        var s = fresh()
        var step: (ruling: Ruling, state: MatchState)
        // 1. Ada breaks and pockets the 2 and the 7.
        step = playShot(rules, ShotScript(start: nine, firstHit: 1, pocketed: [(2, 1), (7, 3)]), in: s); s = step.state
        XCTAssertEqual(s.ballsLeft, [1, 3, 4, 5, 6, 8, 9])
        XCTAssertEqual(s.turn, .first)
        // 2. Ada hits the 1 but nothing drops: Ben.
        step = playShot(rules, ShotScript(start: onlyStanding(s.ballsLeft), firstHit: 1, toRail: [1]), in: s); s = step.state
        XCTAssertEqual(s.turn, .second)
        // 3. Ben pockets the 1 and the 3 off it.
        step = playShot(rules, ShotScript(start: onlyStanding(s.ballsLeft), firstHit: 1, pocketed: [(1, 0), (3, 2)]), in: s)
        s = step.state
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(rules.lowestBall(in: s), 4)
        // 4. Ben scratches: Ada has ball in hand.
        step = playShot(rules, ShotScript(start: onlyStanding(s.ballsLeft), firstHit: 4, pocketed: [(0, 5)]), in: s)
        s = step.state
        XCTAssertEqual(s.turn, .first)
        XCTAssertEqual(s.ballInHand, .anywhere)
        // 5. Ada plays the 4 into the 9 and the 9 drops: she wins.
        step = playShot(rules, ShotScript(start: onlyStanding(s.ballsLeft), firstHit: 4, pocketed: [(9, 3)]), in: s)
        s = step.state
        XCTAssertEqual(s.result, MatchResult(winner: .first, reason: .nineBallPocketed))
        XCTAssertEqual(s.shotCount, 5)
        XCTAssertEqual(s.foulHistory, [FoulRecord(shot: 4, player: .second, fouls: [.scratch])])
    }
}
