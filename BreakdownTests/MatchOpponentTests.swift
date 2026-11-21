// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The computer opponent (App/Match/MatchOpponent.swift) and the match record (App/Match/MatchRecord.swift) as
//          unit tests: which balls it may aim at and the candidate shots it lists (straight pots and one-cushion banks
//          of legal balls only, easiest first), the seeded noise (the same seed gives the same stroke, so a saved match
//          replays the same; neighbouring shots differ; each level's spread is the size it says), the safety choice
//          (the legal safety that leaves the smallest window; a hooked cue ball leaves no window at all), one full plan
//          on a hanging ball (it pots it, with the right call, and plans the same way twice), the computer seat
//          surviving a save, and the record's counting.
//          The full plan solves a few hundred budgeted shots, about a second in a Debug build.
// SRP/DRY check: Pass - no opponent logic here; layouts are hand-made, parameters come from TestShots.parameters.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation
import XCTest

final class MatchOpponentTests: XCTestCase {
    // MARK: Helpers

    private let r = PoolParameters().ballRadius

    /// Sixteen positions: the given balls, the cue ball, every other ball off the table.
    private func layout(_ balls: [Int: Vec2], cue: Vec2) -> [Vec2] {
        var l = [Vec2](repeating: NextShot.offTable, count: 16)
        l[0] = cue
        for (b, p) in balls { l[b] = p }
        return l
    }

    /// Eight-ball after the break with these balls left and the computer (seat 2) to shoot.
    private func eightBallState(left: [Int], group: EightBallGroup? = nil) -> MatchState {
        var s = EightBallRules().initialState(playerNames: ["Player 1", "Computer"])
        s.players[1].computer = .medium
        s.isBreak = false
        s.ballsLeft = left.sorted()
        s.turn = .second
        s.ballInHand = .none
        if let g = group { s.groups = [g.other, g] }
        return s
    }

    private func snapshot(_ l: [Vec2], _ s: MatchState, rules: any MatchRules = EightBallRules(),
                          level: ComputerLevel = .medium) -> OpponentSnapshot {
        OpponentSnapshot(layout: l, state: s, rules: rules, parameters: TestShots.parameters(), level: level,
                         racked: false)
    }

    // MARK: Legal balls and candidates

    func testLegalTargetsFollowTheRules() {
        // Open table: every ball but the 8.
        XCTAssertEqual(OpponentPlanner.legalTargets(rules: EightBallRules(), state: eightBallState(left: [1, 8, 9])),
                       [1, 9])
        // Stripes with only the 8 left of theirs: the 8.
        XCTAssertEqual(OpponentPlanner.legalTargets(rules: EightBallRules(),
                                                    state: eightBallState(left: [3, 8], group: .stripes)), [8])
        // Nine-ball: only the lowest ball.
        var nine = NineBallRules().initialState(playerNames: ["A", "B"])
        nine.ballsLeft = [4, 7, 9]
        nine.isBreak = false
        XCTAssertEqual(OpponentPlanner.legalTargets(rules: NineBallRules(), state: nine), [4])
    }

    func testCandidatesAreLegalStraightPotsAndBanksEasiestFirst() {
        let l = layout([1: Vec2(1.6, 0.5), 8: Vec2(1.0, 1.0), 9: Vec2(2.0, 0.9)], cue: Vec2(0.6, 0.635))
        let p = TestShots.parameters()
        let all = OpponentPlanner.candidates(layout: l, cueBall: 0, targets: [1, 9], parameters: p)
        XCTAssertFalse(all.isEmpty)
        XCTAssertTrue(all.allSatisfy { [1, 9].contains($0.ball) }, "only legal balls are aimed at, never the 8")
        XCTAssertTrue(all.allSatisfy { (0..<6).contains($0.pocket) })
        XCTAssertTrue(all.contains { $0.bankRail == nil }, "straight pots are listed")
        XCTAssertTrue(all.contains { $0.bankRail != nil }, "one-cushion banks are listed")
        XCTAssertTrue(all.allSatisfy { $0.estimate > 0 && $0.estimate <= 2 * EightBallJudge.aimLimit })
        XCTAssertTrue(all.allSatisfy { $0.speed >= 0.5 && $0.aimDegrees.isFinite })
        // Clear paths first, then the widest predicted window.
        if let firstBlocked = all.firstIndex(where: { !$0.clear }) {
            XCTAssertTrue(all[firstBlocked...].allSatisfy { !$0.clear })
        }
        let clear = all.filter(\.clear)
        XCTAssertEqual(clear.map(\.estimate), clear.map(\.estimate).sorted(by: >))
        // The shortlist keeps at most the named numbers of straight pots and banks.
        let short = OpponentPlanner.shortlist(all)
        XCTAssertLessThanOrEqual(short.filter { $0.bankRail == nil }.count, OpponentPlanner.straightKeep)
        XCTAssertLessThanOrEqual(short.filter { $0.bankRail != nil }.count, OpponentPlanner.bankKeep)
        XCTAssertEqual(OpponentPlanner.candidates(layout: l, cueBall: 0, targets: [1, 9], parameters: p), all,
                       "the same layout lists the same candidates in the same order")
    }

    func testAStraightInPotPredictsAWiderWindowThanACut() {
        // The same distances; one straight in, one cut at 45 degrees: the cut's window is narrower by cos 45.
        let straight = OpponentPlanner.windowEstimate(cueTravel: 0.6, objectTravel: 0.6, cosCut: 1, capture: 0.065,
                                                      radius: r)
        let cut = OpponentPlanner.windowEstimate(cueTravel: 0.6, objectTravel: 0.6, cosCut: 0.5.squareRoot(),
                                                 capture: 0.065, radius: r)
        XCTAssertGreaterThan(straight, cut)
        XCTAssertEqual(cut / straight, 0.5.squareRoot(), accuracy: 1e-9)
    }

    // MARK: Seeded noise

    func testNoiseIsAPureFunctionOfItsSeed() {
        let seed = OpponentNoise.seed(rackSeed: 12_345, shotCount: 7, seat: 1)
        XCTAssertEqual(seed, OpponentNoise.seed(rackSeed: 12_345, shotCount: 7, seat: 1))
        XCTAssertEqual(OpponentNoise.draw(level: .medium, seed: seed), OpponentNoise.draw(level: .medium, seed: seed),
                       "a saved match replays the same stroke")
        XCTAssertNotEqual(seed, OpponentNoise.seed(rackSeed: 12_345, shotCount: 8, seat: 1), "the next shot differs")
        XCTAssertNotEqual(seed, OpponentNoise.seed(rackSeed: 12_346, shotCount: 7, seat: 1), "another rack differs")
        XCTAssertNotEqual(seed, OpponentNoise.seed(rackSeed: 12_345, shotCount: 7, seat: 0), "another seat differs")
    }

    func testEachLevelSpreadsItsAimByItsOwnAmount() {
        for level in ComputerLevel.allCases {
            let draws = (0..<4000).map {
                OpponentNoise.draw(level: level, seed: OpponentNoise.seed(rackSeed: 99, shotCount: $0, seat: 1))
            }
            let aims = draws.map(\.aimDegrees)
            let mean = aims.reduce(0, +) / Double(aims.count)
            let sd = (aims.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(aims.count)).squareRoot()
            XCTAssertEqual(mean, 0, accuracy: 0.1 * level.aimNoiseDegrees, "\(level) aim is centred")
            XCTAssertEqual(sd, level.aimNoiseDegrees, accuracy: 0.1 * level.aimNoiseDegrees, "\(level) aim spread")
            // Clamped at three standard deviations.
            XCTAssertTrue(aims.allSatisfy { abs($0) <= 3 * level.aimNoiseDegrees + 1e-12 })
            XCTAssertTrue(draws.allSatisfy { abs($0.speedShare) <= 3 * level.speedNoiseShare + 1e-12 })
        }
        XCTAssertGreaterThan(ComputerLevel.easy.aimNoiseDegrees, ComputerLevel.medium.aimNoiseDegrees)
        XCTAssertGreaterThan(ComputerLevel.medium.aimNoiseDegrees, ComputerLevel.hard.aimNoiseDegrees)
    }

    func testNoiseKeepsTheStrokeInRange() {
        let stroke = OpponentStroke(aimDegrees: 10, speed: 12.9, tipUp: 0.018, tipSide: 0)
        let pushed = stroke.with(OpponentNoise(aimDegrees: 0.5, speedShare: 0.2, tipUp: 0.01, tipSide: 0.01),
                                 speeds: PlayerShotSpeed.ordinary, tipLimit: 0.02)
        XCTAssertEqual(pushed.aimDegrees, 10.5, accuracy: 1e-12)
        XCTAssertLessThanOrEqual(pushed.speed, PlayerShotSpeed.ordinary.upperBound)
        XCTAssertLessThanOrEqual((pushed.tipUp * pushed.tipUp + pushed.tipSide * pushed.tipSide).squareRoot(),
                                 0.02 + 1e-12)
        XCTAssertEqual(stroke.with(.none, speeds: PlayerShotSpeed.ordinary, tipLimit: 0.02), stroke)
    }

    // MARK: Safety

    func testTheSafetyLeavesTheSmallestWindow() {
        let s = OpponentStroke(aimDegrees: 0, speed: 1)
        var illegal = OpponentTrial(stroke: s); illegal.leftOpponent = 0
        var wide = OpponentTrial(stroke: OpponentStroke(aimDegrees: 1, speed: 1)); wide.safetyLegal = true; wide.leftOpponent = 2
        var tight = OpponentTrial(stroke: OpponentStroke(aimDegrees: 2, speed: 1)); tight.safetyLegal = true; tight.leftOpponent = 0.5
        var jam = OpponentTrial(stroke: OpponentStroke(aimDegrees: 3, speed: 1)); jam.safetyLegal = true; jam.jammed = true
        var tie = OpponentTrial(stroke: OpponentStroke(aimDegrees: 4, speed: 1)); tie.safetyLegal = true; tie.leftOpponent = 0.5
        XCTAssertEqual(OpponentPlanner.pickSafety([illegal, wide, tight, jam, tie])?.stroke.aimDegrees, 2,
                       "the smallest window, never an illegal or jammed stroke, the first of a tie")
        XCTAssertNil(OpponentPlanner.pickSafety([illegal]))
    }

    func testAHookedCueBallLeavesNoWindow() {
        // The cue ball in the middle of a ring of eight balls 2.7 radii away: neighbours 2.07 radii apart do not
        // touch, and every straight line out passes within a ball's width of one of them, so no pot is clear.
        let p = TestShots.parameters()
        let centre = Vec2(1.27, 0.635)
        var balls: [Int: Vec2] = [9: Vec2(2.2, 0.3)]
        for k in 0..<8 {
            let a = Double(k) * Double.pi / 4
            balls[k + 1] = centre + Vec2(cos(a), sin(a)) * (2.7 * r)
        }
        let hooked = layout(balls, cue: centre)
        XCTAssertEqual(OpponentPlanner.bestWindow(rest: hooked, cueBall: 0, targets: [9], parameters: p), 0)
        XCTAssertFalse(OpponentPlanner.hasClearPot(rest: hooked, cueBall: 0, targets: [9], parameters: p))
        // The same ball with nothing in the way leaves a window, and a cue ball in hand leaves the widest.
        let open = layout([9: Vec2(2.2, 0.3)], cue: centre)
        XCTAssertGreaterThan(OpponentPlanner.bestWindow(rest: open, cueBall: 0, targets: [9], parameters: p), 0)
        var inHand = open
        inHand[0] = NextShot.offTable
        XCTAssertEqual(OpponentPlanner.bestWindow(rest: inHand, cueBall: 0, targets: [9], parameters: p),
                       2 * EightBallJudge.aimLimit)
    }

    // MARK: A whole plan

    func testItPotsAHangingBallWithTheRightCall() {
        // The 1 sits 25 cm out of the foot-right corner (pocket 1) on its diagonal, the cue ball 60 cm behind it.
        let hole = PoolParameters().pocketCenters[1]
        let inward = Vec2(-1, 1).normalized
        let l = layout([1: hole + inward * 0.25, 8: Vec2(0.8, 1.0)], cue: hole + inward * 0.85)
        let snap = snapshot(l, eightBallState(left: [1, 8]))
        let plan = OpponentPlanner.plan(snap)
        XCTAssertEqual(plan.kind, .pot(ball: 1, pocket: 1, bankRail: nil))
        XCTAssertEqual(plan.call, .ball(1, pocket: .footRight))
        XCTAssertNil(plan.placement)
        XCTAssertGreaterThanOrEqual(plan.window ?? 0, OpponentPlanner.threshold(.medium))
        XCTAssertEqual(OpponentPlanner.plan(snap), plan, "the search is deterministic")
    }

    func testBallInHandPlacesTheCueBallLegally() {
        var s = eightBallState(left: [1, 8])
        s.ballInHand = .anywhere
        let l = layout([1: Vec2(1.9, 0.4), 8: Vec2(0.8, 1.0)], cue: Vec2(0.635, 0.635))
        let snap = snapshot(l, s)
        let spots = OpponentPlanner.placements(snap)
        XCTAssertFalse(spots.isEmpty)
        for spot in spots {
            XCTAssertEqual(NextShot.placement(of: spot.spot, cueBall: 0, among: l, behindHeadLine: false,
                                              parameters: snap.parameters), .legal)
            XCTAssertEqual(spot.ball, 1)
        }
        // Behind the head line: every spot is behind it.
        s.ballInHand = .behindHeadLine
        let behind = OpponentPlanner.placements(snapshot(l, s))
        let line = NextShot.headLineX(parameters: snap.parameters)
        XCTAssertTrue(behind.allSatisfy { $0.spot.x <= line })
    }

    func testChoices() {
        var s = eightBallState(left: Array(1...15))
        s.pendingChoice = PendingChoice(choice: .spotEightOrRerack, chooser: .second)
        XCTAssertEqual(OpponentPlanner.answer(snapshot([], s)), .spotEight)
        s.pendingChoice = PendingChoice(choice: .acceptTableOrRerack, chooser: .second)
        s.ballInHand = .anywhere
        XCTAssertEqual(OpponentPlanner.answer(snapshot([], s)), .acceptTable, "with ball in hand, take the table")
    }

    // MARK: Saving and the record

    func testTheComputerSeatSurvivesASave() throws {
        var s = eightBallState(left: [1, 8])
        s.players[1].computer = .hard
        let back = try JSONDecoder().decode(MatchState.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(back, s)
        XCTAssertEqual(back.players[1].computer, .hard)
        XCTAssertFalse(back.players[0].isComputer)
        // A player saved before the field existed decodes as a person.
        let old = Data(#"{"id":{"index":1},"name":"Sam"}"#.utf8)
        let player = try JSONDecoder().decode(Player.self, from: old)
        XCTAssertNil(player.computer)
        XCTAssertEqual(player.name, "Sam")
    }

    func testTheRecordCountsFinishedGames() throws {
        let suite = "MatchOpponentTests.record"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        var s = eightBallState(left: [])
        s.players[1].computer = .easy
        MatchRecord.noteFinished(s, in: defaults)   // no result: not counted
        s.result = MatchResult(winner: .first, reason: .eightBallPocketed)
        MatchRecord.noteFinished(s, in: defaults)
        s.result = MatchResult(winner: .second, reason: .eightEarly)
        MatchRecord.noteFinished(s, in: defaults)
        let rec = MatchRecord.load(from: defaults)
        XCTAssertEqual(rec.tally(.eightBall), MatchTally(played: 2, won: 1))
        XCTAssertEqual(rec.tally(.easy), MatchTally(played: 2, won: 1))
        XCTAssertEqual(rec.tally(.hard), MatchTally())
        XCTAssertEqual(rec.tally(.nineBall), MatchTally())
    }
}
