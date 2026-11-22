// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: One test per eight-ball rule (BreakdownRules/EightBallRules.swift, plans/21-Nov-2026-rules-games-plan.md
//          package 3), each on a hand-built shot (RulesShotScript.swift): the break (legal by a pot, legal by four
//          rails, illegal with the accept-or-re-rack choice and both answers, a scratch, the 8 on the break and its
//          two answers, the 8 on a fouled break), the open table and groups settled by the first called ball legally
//          pocketed, the call and keeping the turn, every foul, a safety, a tie for the first contact, which balls may
//          be called, the win, every loss on the 8 and the order of that table, a scripted full game, and the
//          suggested call.
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 rules-lens: ball in hand behind the head line. A first hit on
//          a ball that started behind the line, with the cue ball never crossing it, is .cueBallBehindHeadLine; a ball
//          on the line counts as behind; crossing first is legal; a tie with a ball beyond the line goes to the shooter;
//          ball in hand anywhere is unaffected; the rules' head line is the placement check's line (NextShot.headLineX).
//          These shots move the cue ball, so they are built here rather than with ShotScript, whose cue ball stands
//          still.)
// SRP/DRY check: Pass - new; MatchContractTests covers the bookkeeping shared by every game, these cover eight-ball's
//          own rules on top of it.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import XCTest

final class EightBallRulesTests: XCTestCase {
    private let rules = EightBallRules()

    /// A fresh game, Ada to break.
    private func fresh() -> MatchState { rules.initialState(playerNames: ["Ada", "Ben"]) }

    /// After the break: the table open, Ada to shoot, every ball still up unless listed.
    private func openTable(ballsLeft: [Int] = Array(1...15)) -> MatchState {
        var s = fresh()
        s.isBreak = false
        s.ballInHand = .none
        s.ballsLeft = ballsLeft
        return s
    }

    /// Groups settled: Ada solids, Ben stripes, Ada to shoot.
    private func grouped(ballsLeft: [Int] = Array(1...15)) -> MatchState {
        var s = openTable(ballsLeft: ballsLeft)
        s.groups = [.solids, .stripes]
        return s
    }

    // MARK: The break

    func testBreakerPlacesTheCueBallBehindTheHeadLineAndCallsAreUsed() {
        XCTAssertEqual(rules.kind, .eightBall)
        XCTAssertEqual(rules.rack, .fifteenBallTriangle)
        XCTAssertTrue(rules.usesCalls)
        XCTAssertEqual(fresh().ballInHand, .behindHeadLine)
        XCTAssertTrue(fresh().isBreak)
    }

    func testLegalBreakWithAPotKeepsTheTurnAndLeavesTheTableOpen() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 1, pocketed: [(4, 1)]), in: fresh())
        XCTAssertEqual(r.reasons, [.breakLegal, .legalPot, .tableOpen])
        XCTAssertEqual(r.nextShooter, .first)
        XCTAssertTrue(r.fouls.isEmpty)
        XCTAssertNil(r.assignedGroup, "a ball on the break does not settle the groups")
        XCTAssertTrue(s.tableOpen)
        XCTAssertFalse(s.isBreak)
        XCTAssertFalse(s.ballsLeft.contains(4))
        XCTAssertEqual(s.ballInHand, BallInHand.none)
    }

    func testLegalBreakByFourBallsToARailPassesTheTurn() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 1, toRail: [2, 5, 9, 12]), in: fresh())
        XCTAssertEqual(r.reasons, [.breakLegal, .noLegalPot, .tableOpen])
        XCTAssertNil(r.choice)
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(s.ballInHand, BallInHand.none)
    }

    func testTheCueBallReachingARailDoesNotCountTowardTheFour() {
        let (r, _) = playShot(rules, ShotScript(firstHit: 1, toRail: [0, 2, 5, 9]), in: fresh())
        XCTAssertEqual(r.reasons.first, .breakIllegal)
    }

    func testIllegalBreakOffersTheOtherPlayerTheTableOrARerack() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 1, toRail: [2, 5, 9]), in: fresh())
        XCTAssertEqual(r.reasons, [.breakIllegal, .tableOpen])
        XCTAssertEqual(r.choice, PendingChoice(choice: .acceptTableOrRerack, chooser: .second))
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(s.pendingChoice?.chooser, .second)

        // Accept: Ben shoots the table as it lies.
        let accept = rules.ruling(answering: .acceptTable, in: s)
        XCTAssertEqual(accept.nextShooter, .second)
        let accepted = rules.applying(accept, facts: nil, to: s)
        XCTAssertNil(accepted.pendingChoice)
        XCTAssertFalse(accepted.isBreak)
        XCTAssertEqual(accepted.shotCount, s.shotCount, "answering is not a shot")

        // Re-rack: a fresh rack that Ben breaks from behind the head line.
        let rerack = rules.ruling(answering: .rerack, in: s)
        let reracked = rules.applying(rerack, facts: nil, to: s)
        XCTAssertTrue(rerack.rerack)
        XCTAssertTrue(reracked.isBreak)
        XCTAssertEqual(reracked.turn, .second)
        XCTAssertEqual(reracked.ballInHand, .behindHeadLine)
        XCTAssertEqual(reracked.ballsLeft, Array(1...15))

        // An answer the choice does not offer changes nothing and keeps the choice waiting.
        let wrong = rules.ruling(answering: .spotEight, in: s)
        XCTAssertEqual(rules.applying(wrong, facts: nil, to: s).pendingChoice, s.pendingChoice)
    }

    func testScratchOnTheBreakGivesBallInHandBehindTheHeadLine() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 1, pocketed: [(0, 4), (3, 1)]), in: fresh())
        XCTAssertEqual(r.fouls, [.scratch])
        XCTAssertEqual(r.reasons, [.breakLegal, .foul, .scratchOnBreak, .tableOpen])
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(s.ballInHand, .behindHeadLine)
        XCTAssertNil(s.pendingChoice)
    }

    func testEightOnTheBreakIsSpottedOrReracked() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 1, pocketed: [(8, 3)]), in: fresh())
        XCTAssertNil(r.result, "the 8 on the break neither wins nor loses")
        XCTAssertEqual(r.reasons, [.eightOnBreak, .tableOpen])
        XCTAssertEqual(r.choice, PendingChoice(choice: .spotEightOrRerack, chooser: .first))
        XCTAssertFalse(s.ballsLeft.contains(8))

        let spot = rules.ruling(answering: .spotEight, in: s)
        XCTAssertEqual(spot.ballsToSpot, [8])
        let spotted = rules.applying(spot, facts: nil, to: s)
        XCTAssertTrue(spotted.ballsLeft.contains(8))
        XCTAssertEqual(spotted.turn, .first, "the breaker keeps shooting")
        XCTAssertNil(spotted.pendingChoice)

        let rerack = rules.applying(rules.ruling(answering: .rerack, in: s), facts: nil, to: s)
        XCTAssertTrue(rerack.isBreak)
        XCTAssertEqual(rerack.turn, .first)
        XCTAssertEqual(rerack.ballsLeft, Array(1...15))
    }

    func testEightOnAFouledBreakIsTheOtherPlayersChoice() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 1, pocketed: [(8, 3), (0, 5)]), in: fresh())
        XCTAssertNil(r.result)
        XCTAssertEqual(r.fouls, [.scratch])
        XCTAssertEqual(r.choice, PendingChoice(choice: .spotEightOrRerack, chooser: .second))
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(s.ballInHand, .behindHeadLine)
        let spotted = rules.applying(rules.ruling(answering: .spotEight, in: s), facts: nil, to: s)
        XCTAssertEqual(spotted.turn, .second)
        XCTAssertEqual(spotted.ballInHand, .behindHeadLine)
        XCTAssertTrue(spotted.ballsLeft.contains(8))
    }

    // MARK: Groups and the call

    func testGroupsAreSettledByTheFirstCalledBallLegallyPocketed() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 3, pocketed: [(3, 1)]), call: .ball(3, pocket: .footRight),
                          in: openTable())
        XCTAssertEqual(r.reasons, [.legalPot, .groupsAssigned])
        XCTAssertEqual(r.assignedGroup, .solids)
        XCTAssertEqual(s.groups, [.solids, .stripes])
        XCTAssertEqual(s.turn, .first)
    }

    func testAnUncalledBallOnTheOpenTableSettlesNothing() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 3, pocketed: [(11, 2)]), call: .ball(3, pocket: .footRight),
                          in: openTable())
        XCTAssertEqual(r.reasons, [.calledBallMissed, .tableOpen])
        XCTAssertNil(r.assignedGroup)
        XCTAssertTrue(s.tableOpen)
        XCTAssertEqual(s.turn, .second)
        XCTAssertFalse(s.ballsLeft.contains(11), "a ball that drops stays down")
    }

    func testKeepShootingWhileTheCalledBallDropsInTheCalledPocket() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 2, pocketed: [(2, 5), (12, 1)]), call: .ball(2, pocket: .leftSide),
                          in: grouped())
        XCTAssertEqual(r.reasons, [.legalPot])
        XCTAssertEqual(s.turn, .first)
        XCTAssertFalse(s.ballsLeft.contains(12), "the other player's ball that dropped stays down")
    }

    func testTheCalledBallInAnotherPocketPassesTheTurn() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 2, pocketed: [(2, 4)]), call: .ball(2, pocket: .leftSide),
                          in: grouped())
        XCTAssertEqual(r.reasons, [.calledBallMissed])
        XCTAssertTrue(r.fouls.isEmpty)
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(s.ballInHand, BallInHand.none)
    }

    func testNothingDroppingPassesTheTurn() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 2, toRail: [2]), call: .ball(2, pocket: .leftSide), in: grouped())
        XCTAssertEqual(r.reasons, [.noLegalPot])
        XCTAssertEqual(s.turn, .second)
    }

    func testASafetyPassesTheTurnEvenIfOwnBallDrops() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 2, pocketed: [(2, 0)]), call: .safety, in: grouped())
        XCTAssertEqual(r.reasons, [.calledBallMissed])
        XCTAssertTrue(r.fouls.isEmpty)
        XCTAssertEqual(s.turn, .second)
        XCTAssertFalse(s.ballsLeft.contains(2))
    }

    func testWhichBallsMayBeCalled() {
        XCTAssertFalse(rules.mayCall(3, in: fresh()), "no call on the break")
        let open = openTable()
        XCTAssertTrue(rules.mayCall(3, in: open))
        XCTAssertTrue(rules.mayCall(12, in: open))
        XCTAssertFalse(rules.mayCall(8, in: open), "never the 8 on an open table")
        let g = grouped(ballsLeft: [3, 8, 12])
        XCTAssertTrue(rules.mayCall(3, in: g))
        XCTAssertFalse(rules.mayCall(12, in: g))
        XCTAssertFalse(rules.mayCall(8, in: g))
        XCTAssertFalse(rules.mayCall(5, in: g), "a ball no longer on the table")
        let onEight = grouped(ballsLeft: [8, 12])
        XCTAssertTrue(rules.mayCall(8, in: onEight))
        XCTAssertFalse(rules.mayCall(12, in: onEight))
        XCTAssertTrue(rules.isOnTheEight(onEight))
    }

    // MARK: Fouls

    func testHittingTheOtherGroupFirstIsAFoulWithBallInHandAnywhere() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 12, pocketed: [(2, 0)]), call: .ball(2, pocket: .headRight),
                          in: grouped())
        XCTAssertEqual(r.fouls, [.wrongBallFirst])
        XCTAssertEqual(r.reasons, [.foul])
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(s.ballInHand, .anywhere)
        XCTAssertFalse(s.ballsLeft.contains(2), "a ball pocketed on a foul stays down")
        XCTAssertEqual(s.foulHistory.last?.fouls, [.wrongBallFirst])
    }

    func testTheEightFirstOnAnOpenTableIsAFoul() {
        let (r, _) = playShot(rules, ShotScript(firstHit: 8, toRail: [8]), call: .ball(3, pocket: .footLeft),
                          in: openTable())
        XCTAssertEqual(r.fouls, [.wrongBallFirst])
        XCTAssertEqual(r.reasons, [.foul, .tableOpen])
    }

    func testNoRailAfterContactIsAFoul() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 2), call: .ball(2, pocket: .footLeft), in: grouped())
        XCTAssertEqual(r.fouls, [.noRailAfterContact])
        XCTAssertEqual(s.ballInHand, .anywhere)
    }

    func testHittingNothingIsAFoul() {
        let (r, _) = playShot(rules, ShotScript(toRail: [0]), call: .ball(2, pocket: .footLeft), in: grouped())
        XCTAssertEqual(r.fouls, [.noBallHit])
    }

    func testAScratchIsAFoul() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 2, pocketed: [(2, 3), (0, 1)]), call: .ball(2, pocket: .footLeft),
                          in: grouped())
        XCTAssertEqual(r.fouls, [.scratch])
        XCTAssertEqual(s.turn, .second)
        XCTAssertEqual(s.ballInHand, .anywhere)
    }

    func testAnObjectBallOffTheTableIsAFoul() {
        let (r, s) = playShot(rules, ShotScript(firstHit: 2, toRail: [2], offTable: [5]), call: .ball(2, pocket: .footLeft),
                          in: grouped())
        XCTAssertEqual(r.fouls, [.objectBallOffTable])
        XCTAssertFalse(s.ballsLeft.contains(5))
    }

    func testATieForTheFirstContactCountsTheLegalBall() {
        let (r, _) = playShot(rules, ShotScript(firstHit: 12, tieWith: 2, toRail: [2]), call: .ball(2, pocket: .footLeft),
                          in: grouped())
        XCTAssertTrue(r.fouls.isEmpty, "a stripe and a solid at the same instant: the solid counts")
    }

    // MARK: The win and every loss on the 8

    func testTheEightInTheCalledPocketAfterTheGroupWins() {
        let (r, s) = playShot(rules, ShotScript(start: onlyStanding([8, 12]), firstHit: 8, pocketed: [(8, 3)]),
                          call: .ball(8, pocket: .footLeft), in: grouped(ballsLeft: [8, 12]))
        XCTAssertEqual(r.result, MatchResult(winner: .first, reason: .eightBallPocketed))
        XCTAssertEqual(r.reasons, [.legalPot, .gameOver])
        XCTAssertTrue(s.isOver)
    }

    func testEveryLossOnTheEight() {
        struct Case { let name: String; let shot: ShotScript; let call: EightBallCall; let state: MatchState
                      let loss: MatchEndReason }
        let onEight = grouped(ballsLeft: [8, 12])
        let early = grouped(ballsLeft: [2, 8, 12])
        let cases = [
            Case(name: "off the table", shot: ShotScript(start: onlyStanding([8, 12]), firstHit: 8, offTable: [8]),
                 call: .ball(8, pocket: .footLeft), state: onEight, loss: .eightOffTable),
            Case(name: "on a foul", shot: ShotScript(start: onlyStanding([8, 12]), firstHit: 8, pocketed: [(8, 3), (0, 2)]),
                 call: .ball(8, pocket: .footLeft), state: onEight, loss: .eightOnFoul),
            Case(name: "early", shot: ShotScript(start: onlyStanding([2, 8, 12]), firstHit: 2, pocketed: [(2, 1), (8, 3)]),
                 call: .ball(2, pocket: .footRight), state: early, loss: .eightEarly),
            Case(name: "early on the open table", shot: ShotScript(firstHit: 3, pocketed: [(8, 3)]),
                 call: .ball(3, pocket: .footRight), state: openTable(), loss: .eightEarly),
            Case(name: "wrong pocket", shot: ShotScript(start: onlyStanding([8, 12]), firstHit: 8, pocketed: [(8, 1)]),
                 call: .ball(8, pocket: .footLeft), state: onEight, loss: .eightWrongPocket),
            Case(name: "a safety that drops the 8", shot: ShotScript(start: onlyStanding([8, 12]), firstHit: 8,
                                                                     pocketed: [(8, 1)]),
                 call: .safety, state: onEight, loss: .eightWrongPocket),
        ]
        for c in cases {
            let (r, s) = playShot(rules, c.shot, call: c.call, in: c.state)
            XCTAssertEqual(r.result, MatchResult(winner: .second, reason: c.loss), c.name)
            XCTAssertEqual(r.reasons.last, .gameOver, c.name)
            XCTAssertTrue(s.isOver, c.name)
        }
        // Every EightBallLoss has a row in the table, in the judge's order.
        XCTAssertEqual(EightBallLoss.allCases.map { MatchEndReason($0) },
                       [.eightOnFoul, .eightEarly, .eightWrongPocket, .eightOffTable])
    }

    func testTheLossTableOrder() {
        // Off the table beats a foul (an 8 off the table is itself a foul); a foul beats too early; too early beats
        // the wrong pocket.
        let (offAndFoul, _) = playShot(rules, ShotScript(start: onlyStanding([8, 12]), firstHit: 12, offTable: [8]),
                                   call: .ball(8, pocket: .footLeft), in: grouped(ballsLeft: [8, 12]))
        XCTAssertEqual(offAndFoul.result?.reason, .eightOffTable)
        let (foulAndEarly, _) = playShot(rules, ShotScript(start: onlyStanding([2, 8]), firstHit: 2, pocketed: [(8, 1), (0, 2)]),
                                     call: .ball(2, pocket: .footLeft), in: grouped(ballsLeft: [2, 8]))
        XCTAssertEqual(foulAndEarly.result?.reason, .eightOnFoul)
        let (earlyAndWrong, _) = playShot(rules, ShotScript(start: onlyStanding([2, 8]), firstHit: 2, pocketed: [(8, 1)]),
                                      call: .ball(8, pocket: .footLeft), in: grouped(ballsLeft: [2, 8]))
        XCTAssertEqual(earlyAndWrong.result?.reason, .eightEarly)
    }

    // MARK: A whole game

    func testAScriptedFullGame() {
        var s = fresh()
        var step: (ruling: Ruling, state: MatchState)

        // 1. Ada breaks and pockets the 5: still her turn, table open.
        step = playShot(rules, ShotScript(firstHit: 1, pocketed: [(5, 1)]), in: s); s = step.state
        XCTAssertEqual(s.turn, .first)
        // 2. Ada calls the 10 in the foot-left corner and makes it: stripes are hers.
        step = playShot(rules, ShotScript(firstHit: 10, pocketed: [(10, 3)]), call: .ball(10, pocket: .footLeft), in: s)
        s = step.state
        XCTAssertEqual(s.group(of: .first), .stripes)
        XCTAssertEqual(s.group(of: .second), .solids)
        // 3. Ada misses: Ben's turn.
        step = playShot(rules, ShotScript(firstHit: 11, toRail: [11]), call: .ball(11, pocket: .footRight), in: s)
        s = step.state
        XCTAssertEqual(s.turn, .second)
        // 4. Ben hits a stripe first: foul, Ada has ball in hand.
        step = playShot(rules, ShotScript(firstHit: 9, toRail: [9]), call: .ball(1, pocket: .headLeft), in: s)
        s = step.state
        XCTAssertEqual(s.turn, .first)
        XCTAssertEqual(s.ballInHand, .anywhere)
        // 5. Ada clears the rest of her stripes in one shot, as called with the last of them.
        step = playShot(rules, ShotScript(start: onlyStanding(s.ballsLeft), firstHit: 9,
                                      pocketed: [(9, 0), (11, 1), (12, 2), (13, 4), (14, 5), (15, 3)]),
                    call: .ball(15, pocket: .footLeft), in: s)
        s = step.state
        XCTAssertEqual(s.turn, .first)
        XCTAssertEqual(s.ballsRemaining(for: .first), [])
        XCTAssertTrue(rules.isOnTheEight(s))
        // 6. Ada calls the 8 in the foot-left corner and makes it: she wins.
        step = playShot(rules, ShotScript(start: onlyStanding(s.ballsLeft), firstHit: 8, pocketed: [(8, 3)]),
                    call: .ball(8, pocket: .footLeft), in: s)
        s = step.state
        XCTAssertEqual(s.result, MatchResult(winner: .first, reason: .eightBallPocketed))
        XCTAssertEqual(s.shotCount, 6)
        XCTAssertEqual(s.foulHistory, [FoulRecord(shot: 4, player: .second, fouls: [.wrongBallFirst])])
    }

    // MARK: The suggested call

    func testTheSuggestedCallIsTheBallOnTheLineAndThePocketOnItsPath() {
        let p = Vec2(2.54, 1.27)   // the foot-left corner
        var positions = [Vec2](repeating: ShotFacts.offTable, count: 16)
        positions[0] = Vec2(1.0, 0.5)
        // The 11 sits on the straight line from the cue ball to the foot-left corner.
        let dir = (p - positions[0]).normalized
        positions[11] = positions[0] + dir * 0.6
        positions[3] = Vec2(0.5, 0.2)
        let pockets = [Vec2(0, 0), Vec2(2.54, 0), Vec2(0, 1.27), Vec2(2.54, 1.27), Vec2(1.27, 0), Vec2(1.27, 1.27)]
        let open = openTable(ballsLeft: [3, 11])
        XCTAssertEqual(rules.suggestedCall(positions: positions, aim: dir, pockets: pockets,
                                           ballRadius: ShotScript.radius, in: open),
                       .ball(11, pocket: .footLeft))
        // Aimed somewhere near the 3 but not on it: the 3 is suggested, with the pocket nearest its line.
        let toward3 = (positions[3] - positions[0]).normalized + Vec2(0, 0.2)
        XCTAssertEqual(rules.suggestedCall(positions: positions, aim: toward3, pockets: pockets,
                                           ballRadius: ShotScript.radius, in: open)?.ball, 3)
        // Nothing to call on the break.
        XCTAssertNil(rules.suggestedCall(positions: positions, aim: dir, pockets: pockets,
                                         ballRadius: ShotScript.radius, in: fresh()))
    }
    // MARK: Ball in hand behind the head line (0.7.5)

    /// A shot from ball in hand behind the head line on ShotScript's 2.54 m table (head line at 0.635 m): the cue ball
    /// starts at `cue`, rolls straight to `via` when given (taking 0.1 s) and then to where it touches `target` (at
    /// 0.2 s), and the target, standing at `at`, drops in the foot-left corner, so the shot is legal on every other
    /// count and only the head-line rule can foul it. `tie` adds a second ball touched 5 microseconds later.
    private func fromTheKitchen(cue: Vec2, via: Vec2? = nil, target: Int = 3, at: Vec2,
                                tie: (ball: Int, at: Vec2)? = nil) -> ShotFacts {
        let r = ShotScript.radius
        var start = [Vec2](repeating: ShotFacts.offTable, count: 16)
        start[0] = cue
        start[target] = at
        if let t = tie { start[t.ball] = t.at }
        // Where the cue ball's centre is when it touches the target: two radii back from the target along its run in.
        let from = via ?? cue
        let touch = at - (at - from).normalized * (2 * r)
        func moving(_ p: Vec2, to q: Vec2, from t0: Double, to t1: Double) -> BallSegment {
            BallSegment(t0: t0, t1: t1, phase: .rolling, position0: p, velocity0: (q - p) * (1 / (t1 - t0)),
                        acceleration: .zero, omega0: .zero, alphaXY: .zero, spinDecay: 9, radius: r,
                        orientation0: .identity)
        }
        func still(_ p: Vec2, from t0: Double = 0) -> BallSegment {
            BallSegment(t0: t0, t1: .infinity, phase: .stationary, position0: p, velocity0: .zero, acceleration: .zero,
                        omega0: .zero, alphaXY: .zero, spinDecay: 9, radius: r, orientation0: .identity)
        }
        var segments = start.map { [still($0)] }
        if let via {
            segments[0] = [moving(cue, to: via, from: 0, to: 0.1), moving(via, to: touch, from: 0.1, to: 0.2),
                           still(touch, from: 0.2)]
        } else {
            segments[0] = [moving(cue, to: touch, from: 0, to: 0.2), still(touch, from: 0.2)]
        }
        func impact(_ b: Int) -> ImpactBall {
            ImpactBall(ball: b, velocityBefore: Vec2(1, 0), velocityAfter: Vec2(0.5, 0), omegaBefore: .zero,
                       omegaAfter: .zero, translationalBefore: 0.085, rotationalBefore: 0, translationalAfter: 0.02,
                       rotationalAfter: 0)
        }
        var events = [LensEvent(time: 0.2, kind: .ballBall, point: .zero, normal: Vec2(1, 0),
                                balls: [impact(0), impact(target)]),
                      LensEvent(time: 0.6, kind: .pocket, point: at, normal: Vec2(1, 0), balls: [impact(target)],
                                pocket: EightBallPocket.footLeft.rawValue)]
        if let t = tie {
            events.append(LensEvent(time: 0.2 + 5e-6, kind: .ballBall, point: .zero, normal: Vec2(1, 0),
                                    balls: [impact(0), impact(t.ball)]))
        }
        events.sort { $0.time < $1.time }
        var pocketTime = [Double?](repeating: nil, count: 16)
        pocketTime[target] = 0.6
        let spec = TableSpec(length: 2.54, width: 1.27, ballRadius: r, pockets: [], pocketCaptureRadius: [])
        let tl = Timeline(table: spec, seed: 1, parameterHash: 1, segments: segments, events: events,
                          pocketTime: pocketTime, duration: 1.1)
        return ShotFacts(timeline: tl, start: start, cueBall: 0)
    }

    /// The open table after a scratch on the break: Ada to shoot with ball in hand behind the head line.
    private func kitchen(_ hand: BallInHand = .behindHeadLine) -> MatchState {
        var s = openTable(ballsLeft: [3, 8, 10, 12])
        s.ballInHand = hand
        return s
    }

    func testTheRulesHeadLineIsThePlacementChecksLine() {
        let p = PoolParameters()
        XCTAssertEqual(EightBallRules.headLineX(tableLength: p.tableLength), NextShot.headLineX(parameters: p))
    }

    func testFromBehindTheLineABallBehindItCannotBeHitFirstWithoutCrossing() {
        // The 3 sits behind the line (x 0.5 < 0.635); the cue ball goes straight at it and never crosses.
        let f = fromTheKitchen(cue: Vec2(0.25, 0.6), at: Vec2(0.5, 0.4))
        let r = rules.ruling(for: f, call: .ball(3, pocket: .footLeft), in: kitchen())
        XCTAssertEqual(r.fouls, [.cueBallBehindHeadLine])
        XCTAssertEqual(r.nextShooter, .second)
        XCTAssertEqual(r.ballInHand, .anywhere, "the foul gives the other player ball in hand anywhere")
        // A ball whose centre is on the line is behind it, as in the placement check.
        let onLine = fromTheKitchen(cue: Vec2(0.25, 0.6), at: Vec2(0.635, 0.4))
        XCTAssertEqual(rules.ruling(for: onLine, call: .ball(3, pocket: .footLeft), in: kitchen()).fouls,
                       [.cueBallBehindHeadLine])
    }

    func testCrossingTheLineFirstIsLegal() {
        // Off the foot end and back: the cue ball passes x 1.2 before it comes back to the 3.
        let f = fromTheKitchen(cue: Vec2(0.25, 0.6), via: Vec2(1.2, 0.9), at: Vec2(0.5, 0.4))
        XCTAssertGreaterThan(f.cueBallFarthestBeforeContact ?? 0, EightBallRules.headLineX(tableLength: 2.54))
        let r = rules.ruling(for: f, call: .ball(3, pocket: .footLeft), in: kitchen())
        XCTAssertEqual(r.fouls, [])
        XCTAssertEqual(r.reasons, [.legalPot, .groupsAssigned])
        // A ball beyond the line hit straight is legal too (the cue ball crosses on its way there).
        let beyond = fromTheKitchen(cue: Vec2(0.25, 0.6), at: Vec2(1.0, 0.5))
        XCTAssertEqual(rules.ruling(for: beyond, call: .ball(3, pocket: .footLeft), in: kitchen()).fouls, [])
    }

    func testATieWithABallBeyondTheLineGoesToTheShooter() {
        // The 3 (behind) and the 10 (beyond, touched within sameInstant): the shooter gets the benefit of the doubt.
        let f = fromTheKitchen(cue: Vec2(0.25, 0.6), at: Vec2(0.5, 0.4), tie: (10, Vec2(0.7, 0.42)))
        XCTAssertEqual(f.firstContactBalls, [3, 10])
        XCTAssertFalse(rules.ruling(for: f, call: .ball(3, pocket: .footLeft), in: kitchen()).fouls
                        .contains(.cueBallBehindHeadLine))
    }

    func testBallInHandAnywhereIsUnaffected() {
        let f = fromTheKitchen(cue: Vec2(0.25, 0.6), at: Vec2(0.5, 0.4))
        XCTAssertEqual(rules.ruling(for: f, call: .ball(3, pocket: .footLeft), in: kitchen(.anywhere)).fouls, [])
        XCTAssertEqual(rules.ruling(for: f, call: .ball(3, pocket: .footLeft), in: kitchen(.none)).fouls, [])
    }
}
