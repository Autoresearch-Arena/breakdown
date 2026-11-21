// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The rules of nine-ball for two players on one device (plans/21-Nov-2026-rules-games-plan.md package 4), in
//          our own words:
//            - The balls 1 to 9 are racked in a diamond. The breaker places the cue ball behind the head line.
//            - Every shot must hit the lowest-numbered ball on the table first, and then pocket a ball or send some
//              ball to a rail. A shot that touches nothing, scratches, or sends an object ball off the table is a
//              foul too. On the break the rail test is the break's own: a ball pocketed, or at least four object
//              balls driven to a rail; a break that does neither is a foul.
//            - Any ball legally pocketed keeps the turn; nothing is called.
//            - The 9 legally pocketed at any time wins, on the break or in a combination.
//            - A foul gives the other player ball in hand anywhere. Balls pocketed on a foul stay down, except the 9,
//              which is spotted.
//            - Three fouls in a row by one player lose the game; the ruling on the second carries a warning.
//            - No push-out in this version.
//          Reads the shot through ShotFacts, never re-solves it, and returns a Ruling; MatchRules' shared applying(_:
//          facts:to:) folds it into the MatchState (including the foul count this file reads). The app's match flow
//          (App/Match/MatchMode.swift) holds a NineBallRules; the turn banner shows lowestBall(in:) as the ball to hit.
// SRP/DRY check: Pass - checked EightBallRules.swift (the shared parts are ShotFacts and MatchRules' bookkeeping,
//          which both use; the legal-first ball, the win and the spotting differ) and MatchRules.swift.
import BreakdownLensModel
import BreakdownTimeline

public struct NineBallRules: MatchRules {
    public init() {}

    public var kind: MatchKind { .nineBall }
    public var rack: MatchRack { .nineBallDiamond }
    /// The breaker places the cue ball anywhere behind the head line.
    public var startingBallInHand: BallInHand { .behindHeadLine }

    /// Fouls in a row that lose the game.
    public static let foulsToLose = 3
    /// How many object balls must reach a rail for a break that pockets nothing to be legal (the same count as
    /// eight-ball's break).
    public static let breakRailCount = EightBallRules.breakRailCount

    /// The ball that must be hit first: the lowest-numbered ball on the table (nil once the table is empty).
    public func lowestBall(in state: MatchState) -> Int? { state.ballsLeft.min() }

    /// Nine-ball has no calls.
    public func mayCall(_ ball: Int, in state: MatchState) -> Bool { false }

    public func ruling(for facts: ShotFacts, call: EightBallCall?, in state: MatchState) -> Ruling {
        let shooter = state.turn
        let opponent = shooter.next(among: max(state.players.count, 1))
        guard let lowest = lowestBall(in: state) else {
            // Nothing left to hit (the game ended with the 9); the turn simply passes.
            return Ruling(shooter: shooter, nextShooter: opponent, reasons: [.noLegalPot])
        }

        // The fouls, in MatchFoul's order. A tie for the first contact counts the lowest ball.
        var found = Set<MatchFoul>()
        if facts.cueBallScratched { found.insert(.scratch) }
        if let first = facts.firstContact(preferring: [lowest]) {
            if first.ball != lowest { found.insert(.wrongBallFirst) }
            if !state.isBreak, !facts.railOrPocketAfterContact { found.insert(.noRailAfterContact) }
        } else {
            found.insert(.noBallHit)
        }
        // The break's rail test: a pocketed object ball or enough object balls to a rail. A break that fails it is
        // recorded under the "no rail" foul (the nearest code: too few balls were driven to a rail), with the reason
        // breakIllegal so the app can say which.
        let breakIllegal = state.isBreak && facts.objectBallsPocketed.isEmpty
            && facts.objectBallsReachingRail.count < Self.breakRailCount
        if breakIllegal { found.insert(.noRailAfterContact) }
        if !facts.objectBallsOffTable.isEmpty { found.insert(.objectBallOffTable) }
        let fouls = MatchFoul.allCases.filter { found.contains($0) }

        let nineDown = facts.pocket(of: 9) != nil
        let nineOff = facts.objectBallsOffTable.contains(9)
        let breakReasons: [RulingReason] = state.isBreak ? (breakIllegal ? [.breakIllegal] : [.breakLegal]) : []

        if !fouls.isEmpty {
            // The state is read before this shot is applied, so this foul makes the run one longer than recorded.
            let seat = shooter.index
            let before = state.consecutiveFouls.indices.contains(seat) ? state.consecutiveFouls[seat] : 0
            let run = before + 1
            let scratchReason: [RulingReason] = state.isBreak && facts.cueBallScratched ? [.scratchOnBreak] : []
            if run >= Self.foulsToLose {
                return Ruling(shooter: shooter, nextShooter: opponent, fouls: fouls,
                              reasons: breakReasons + scratchReason + [.foul, .gameOver],
                              result: MatchResult(winner: opponent, reason: .threeConsecutiveFouls))
            }
            // The 9 dropped or flew off on a foul: it goes back on the foot spot.
            let spot = nineDown || nineOff ? [9] : []
            var reasons = breakReasons + scratchReason + [.foul]
            if !spot.isEmpty { reasons.append(.ballSpotted) }
            if run == Self.foulsToLose - 1 { reasons.append(.foulWarning) }
            return Ruling(shooter: shooter, nextShooter: opponent, fouls: fouls, reasons: reasons,
                          ballInHand: .anywhere, ballsToSpot: spot)
        }

        if nineDown {
            return Ruling(shooter: shooter, nextShooter: shooter, reasons: breakReasons + [.legalPot, .gameOver],
                          result: MatchResult(winner: shooter, reason: .nineBallPocketed))
        }
        if !facts.objectBallsPocketed.isEmpty {
            return Ruling(shooter: shooter, nextShooter: shooter, reasons: breakReasons + [.legalPot])
        }
        return Ruling(shooter: shooter, nextShooter: opponent, reasons: breakReasons + [.noLegalPot])
    }
}
