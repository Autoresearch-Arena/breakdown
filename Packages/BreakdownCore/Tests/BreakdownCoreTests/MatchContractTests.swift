// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Checks the match contract in BreakdownRules (no game's rules: those come with their own tests). A match
//          state survives a save and a load (JSON round trip) with every field set; a fresh state comes from the rack;
//          the protocol's defaults describe a plain two-player pool game; and the shared bookkeeping that folds a ruling
//          into the state counts shots and fouls, assigns groups, takes pocketed balls off and puts spotted ones back,
//          re-racks, and leaves the foul count alone when a choice (not a shot) is answered. The rules value used here
//          only hands back a fixed ruling, so the bookkeeping is all that is tested.
// SRP/DRY check: Pass - new; ShotFactsTests covers the reading of a shot, these cover the match types around it.
import BreakdownLensModel
import BreakdownRules
import BreakdownTimeline
import Foundation
import XCTest

/// Rules that return whatever ruling they are given: enough to exercise the protocol's defaults.
private struct FixedRuling: MatchRules {
    let kind = MatchKind.eightBall
    let rack = MatchRack.fifteenBallTriangle
    var next = Ruling(shooter: .first, nextShooter: .second)
    func ruling(for facts: ShotFacts, call: EightBallCall?, in state: MatchState) -> Ruling { next }
    func mayCall(_ ball: Int, in state: MatchState) -> Bool { true }
}

final class MatchContractTests: XCTestCase {
    private let rules = FixedRuling()

    /// Sixteen balls standing on the table, with the listed ones pocketed during the shot.
    private func facts(pocketed: [Int]) -> ShotFacts {
        var start: [Vec2] = []
        var segments: [[BallSegment]] = []
        for b in 0..<16 {
            let p = Vec2(0.2 + 0.13 * Double(b), 0.6)
            start.append(p)
            segments.append([BallSegment(t0: 0, t1: .infinity, phase: .stationary, position0: p, velocity0: .zero,
                                         acceleration: .zero, omega0: .zero, alphaXY: .zero, spinDecay: 9,
                                         radius: 0.028575, orientation0: .identity)])
        }
        var events: [LensEvent] = []
        var pocketTime = [Double?](repeating: nil, count: 16)
        for (k, b) in pocketed.enumerated() {
            let t = 1.0 + Double(k)
            let ib = ImpactBall(ball: b, velocityBefore: Vec2(1, 0), velocityAfter: .zero, omegaBefore: .zero,
                                omegaAfter: .zero, translationalBefore: 0.085, rotationalBefore: 0, translationalAfter: 0,
                                rotationalAfter: 0)
            events.append(LensEvent(time: t, kind: .pocket, point: start[b], normal: Vec2(1, 0), balls: [ib], pocket: 1))
            pocketTime[b] = t
        }
        let spec = TableSpec(length: 2.54, width: 1.27, ballRadius: 0.028575, pockets: [], pocketCaptureRadius: [])
        let tl = Timeline(table: spec, seed: 1, parameterHash: 1, segments: segments, events: events,
                          pocketTime: pocketTime, duration: events.last?.time ?? 0)
        return ShotFacts(timeline: tl, start: start)
    }

    func testStateSurvivesASaveAndALoad() throws {
        var s = rules.initialState(playerNames: ["Ada", "Ben"])
        s.groups = [.stripes, .solids]
        s.ballsLeft = [2, 8, 11]
        s.ballInHand = .behindHeadLine
        s.shotCount = 7
        s.isBreak = false
        s.consecutiveFouls = [2, 0]
        s.foulHistory = [FoulRecord(shot: 3, player: .first, fouls: [.scratch, .noRailAfterContact])]
        s.scores = [4, -1]
        s.pendingChoice = PendingChoice(choice: .spotEightOrRerack, chooser: .second)
        s.clockRemaining = 312.5
        s.result = MatchResult(winner: .second, reason: .eightWrongPocket)
        let data = try JSONEncoder().encode(s)
        XCTAssertEqual(try JSONDecoder().decode(MatchState.self, from: data), s)

        let calls: [EightBallCall] = [.ball(8, pocket: .footLeft), .safety]
        XCTAssertEqual(try JSONDecoder().decode([EightBallCall].self, from: JSONEncoder().encode(calls)), calls)
    }

    func testFreshStateComesFromTheRack() {
        let s = rules.initialState(playerNames: ["Ada", "Ben"])
        XCTAssertEqual(s.kind, .eightBall)
        XCTAssertEqual(s.players.map(\.name), ["Ada", "Ben"])
        XCTAssertEqual(s.players.map(\.id), [.first, .second])
        XCTAssertEqual(s.turn, .first)
        XCTAssertEqual(s.ballsLeft, Array(1...15))
        XCTAssertTrue(s.isBreak)
        XCTAssertTrue(s.tableOpen)
        XCTAssertEqual(s.scores, [0, 0])
        XCTAssertEqual(s.ballInHand, BallInHand.none)
        XCTAssertNil(s.result)
        XCTAssertEqual(MatchRack.nineBallDiamond.objectBalls, Array(1...9))
        XCTAssertEqual(MatchRack.tableLayout(objectBalls: [3, 4]).objectBalls, [3, 4])
    }

    func testDefaultsDescribeAPlainTwoPlayerPoolGame() {
        let s = rules.initialState(playerNames: ["Ada", "Ben"])
        XCTAssertEqual(rules.playerCount, 2...2)
        XCTAssertFalse(rules.usesCalls)
        XCTAssertEqual(rules.cueBall(for: .second, in: s), 0)
        XCTAssertEqual(rules.ballsReturningToHand(after: facts(pocketed: [3]), in: s), [])
        XCTAssertFalse(rules.resetsPinsBetweenShots)
        XCTAssertFalse(rules.keepsRunningScore)
        XCTAssertNil(rules.turnClock)
        XCTAssertEqual(PlayerID.second.next(among: 2), .first)
        XCTAssertEqual(PlayerID.first.next(among: 1), .first)
    }

    func testApplyingAFoulPassesTheTurnAndCountsIt() {
        var r = FixedRuling()
        r.next = Ruling(shooter: .first, nextShooter: .second, fouls: [.scratch], reasons: [.foul], ballInHand: .anywhere,
                        ballsToSpot: [])
        let start = r.initialState(playerNames: ["Ada", "Ben"])
        let f = facts(pocketed: [0, 5])
        let after = r.applying(r.ruling(for: f, call: nil, in: start), facts: f, to: start)
        XCTAssertEqual(after.shotCount, 1)
        XCTAssertEqual(after.turn, .second)
        XCTAssertEqual(after.ballInHand, .anywhere)
        XCTAssertEqual(after.consecutiveFouls, [1, 0])
        XCTAssertEqual(after.foulHistory, [FoulRecord(shot: 1, player: .first, fouls: [.scratch])])
        XCTAssertEqual(after.ballsLeft, Array(1...15).filter { $0 != 5 })
        XCTAssertFalse(after.isBreak)

        // The same player's next legal shot clears their run of fouls.
        var legal = FixedRuling()
        legal.next = Ruling(shooter: .first, nextShooter: .first, reasons: [.legalPot])
        let again = legal.applying(legal.next, facts: facts(pocketed: []), to: after)
        XCTAssertEqual(again.consecutiveFouls, [0, 0])
        XCTAssertEqual(again.shotCount, 2)
    }

    func testGroupsSpottedBallsPointsAndAResult() {
        var r = FixedRuling()
        r.next = Ruling(shooter: .second, nextShooter: .second, reasons: [.legalPot, .groupsAssigned, .ballSpotted],
                        ballsToSpot: [8], assignedGroup: .stripes, points: [0, 2],
                        result: MatchResult(winner: .second, reason: .eightBallPocketed))
        var s = r.initialState(playerNames: ["Ada", "Ben"])
        s.turn = .second
        let after = r.applying(r.next, facts: facts(pocketed: [8, 12]), to: s)
        XCTAssertEqual(after.groups, [.solids, .stripes])
        XCTAssertEqual(after.group(of: .second), .stripes)
        XCTAssertFalse(after.tableOpen)
        XCTAssertTrue(after.ballsLeft.contains(8), "a spotted ball is back on the table")
        XCTAssertFalse(after.ballsLeft.contains(12))
        XCTAssertEqual(after.ballsRemaining(for: .second), [9, 10, 11, 13, 14, 15])
        XCTAssertEqual(after.scores, [0, 2])
        XCTAssertTrue(after.isOver)
    }

    func testRerackAndAnsweringAChoice() {
        var s = rules.initialState(playerNames: ["Ada", "Ben"])
        s.groups = [.solids, .stripes]
        s.ballsLeft = [3, 8]
        s.isBreak = false
        s.consecutiveFouls = [1, 0]
        s.pendingChoice = PendingChoice(choice: .acceptTableOrRerack, chooser: .second)
        // Answering a choice is not a shot: no shot counted, fouls untouched.
        let rerack = Ruling(shooter: .second, nextShooter: .second, reasons: [.choiceAnswered, .rerack],
                            ballInHand: .behindHeadLine, rerack: true)
        let after = rules.applying(rerack, facts: nil, to: s)
        XCTAssertEqual(after.shotCount, s.shotCount)
        XCTAssertEqual(after.consecutiveFouls, [1, 0])
        XCTAssertEqual(after.ballsLeft, Array(1...15))
        XCTAssertTrue(after.tableOpen)
        XCTAssertTrue(after.isBreak)
        XCTAssertNil(after.pendingChoice)
        XCTAssertEqual(after.ballInHand, .behindHeadLine)
        XCTAssertEqual(MatchChoice.acceptTableOrRerack.answers, [.acceptTable, .rerack])
        // The default answer (for games that never raise a choice) changes nothing but says it was answered.
        let plain = rules.ruling(answering: .acceptTable, in: s)
        XCTAssertEqual(plain.nextShooter, s.turn)
        XCTAssertEqual(plain.reasons, [.choiceAnswered])
    }

    func testFoulAndLossCodesMapFromTheEightBallOnes() {
        for f in EightBallFoul.allCases { XCTAssertEqual(MatchFoul(f).rawValue, f.rawValue) }
        XCTAssertEqual(MatchEndReason(.eightEarly), .eightEarly)
        XCTAssertEqual(MatchEndReason(.eightOffTable), .eightOffTable)
    }
}
