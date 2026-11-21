// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The contract every game's rules fulfil (plans/21-Nov-2026-rules-games-plan.md package 3 step 1, widened by
//          plans/21-Nov-2026-other-tables-games-plan.md package 1 step 2). A rules value is pure: given the match
//          state, the call and the ShotFacts of a recorded shot it returns a Ruling, and it never solves or re-solves a
//          shot. The app's match flow (App/Match/MatchMode.swift) holds one `any MatchRules`, builds the ShotFacts with
//          the striking player's cue ball (cueBall(for:in:)), asks for the ruling, then applies it with applying(_:
//          facts:to:) and saves the new state.
//          Three requirements every game must answer: its rack, the ruling for one shot, and whether a ball may be
//          called. The rest are optional, with defaults that describe a plain pool game, so eight-ball and nine-ball
//          need not mention them: which ball each player strikes, balls that come back to be played after a drop,
//          pins stood up between shots, a running score, a game clock, how a pending choice is answered, the fresh
//          state, and the mechanical bookkeeping of applying a ruling.
//          Rule implementations (EightBallRules, NineBallRules, and the other tables' rules in Tables/) live in their
//          own files in this module, written by the rules work; this file holds no rule of any game.
// SRP/DRY check: Pass - the protocol and its neutral defaults only. The bookkeeping default is the single place a
//          ruling is folded into a state, so the app and the tests cannot apply rulings two different ways.
import BreakdownLensModel
import BreakdownTimeline

public protocol MatchRules: Sendable {
    /// Which game these rules play.
    var kind: MatchKind { get }
    /// What the game starts from (and what a re-rack restores).
    var rack: MatchRack { get }
    /// The ruling on one recorded shot. `facts` was read with cueBall(for: state.turn, in: state) as the cue ball;
    /// `call` is the shooter's call when the game uses calls (nil otherwise, and nil on a break).
    func ruling(for facts: ShotFacts, call: EightBallCall?, in state: MatchState) -> Ruling
    /// Whether the shooter may call `ball` now (eight-ball: one of their group, or the 8 once the group is gone).
    func mayCall(_ ball: Int, in state: MatchState) -> Bool

    // MARK: Optional (defaults below)

    /// How many players the game takes (default exactly two; bar billiards also plays alone).
    var playerCount: ClosedRange<Int> { get }
    /// True when every shot after the break needs a call (default false; eight-ball says true).
    var usesCalls: Bool { get }
    /// Where the first breaker may place the cue ball (default .none: it starts where the rack puts it).
    var startingBallInHand: BallInHand { get }
    /// The ball `player` strikes (default 0). Five-pin and bumper pool give each player their own.
    func cueBall(for player: PlayerID, in state: MatchState) -> Int
    /// Balls that dropped on this shot and come back to be played again (default none; bar billiards).
    func ballsReturningToHand(after facts: ShotFacts, in state: MatchState) -> [Int]
    /// True when the pins are stood up again before every shot (default false; five-pin).
    var resetsPinsBetweenShots: Bool { get }
    /// True when the game keeps a running score per player (default false).
    var keepsRunningScore: Bool { get }
    /// The game clock in seconds, counted down while balls are in play and paused during replays (default nil).
    var turnClock: Double? { get }
    /// The ruling when the chooser answers a pending choice (default: nothing changes; only games that raise a
    /// choice are ever asked).
    func ruling(answering answer: MatchChoiceAnswer, in state: MatchState) -> Ruling
    /// A new match with these player names (default: the rack's object balls, the starting ball in hand, the clock).
    func initialState(playerNames: [String]) -> MatchState
    /// The state after `ruling`. `facts` is the shot's reading, or nil when the ruling answered a choice (no shot).
    func applying(_ ruling: Ruling, facts: ShotFacts?, to state: MatchState) -> MatchState
}

public extension MatchRules {
    var playerCount: ClosedRange<Int> { 2...2 }
    var usesCalls: Bool { false }
    var startingBallInHand: BallInHand { .none }
    func cueBall(for player: PlayerID, in state: MatchState) -> Int { 0 }
    func ballsReturningToHand(after facts: ShotFacts, in state: MatchState) -> [Int] { [] }
    var resetsPinsBetweenShots: Bool { false }
    var keepsRunningScore: Bool { false }
    var turnClock: Double? { nil }

    func ruling(answering answer: MatchChoiceAnswer, in state: MatchState) -> Ruling {
        Ruling(shooter: state.turn, nextShooter: state.turn, reasons: [.choiceAnswered], ballInHand: state.ballInHand)
    }

    func initialState(playerNames: [String]) -> MatchState {
        MatchState(kind: kind, playerNames: playerNames, ballsLeft: rack.objectBalls, ballInHand: startingBallInHand,
                   clock: turnClock)
    }

    /// The bookkeeping every game shares; no rule is decided here. In order: the shot count, whose turn, the ball in
    /// hand, the group assignment, the foul count and history (a shot with no foul resets the shooter's run), the
    /// scores, the balls left (or a fresh rack), the pending choice and the result.
    func applying(_ ruling: Ruling, facts: ShotFacts?, to state: MatchState) -> MatchState {
        var s = state
        let seat = ruling.shooter.index
        if facts != nil { s.shotCount += 1 }
        s.turn = ruling.nextShooter
        s.ballInHand = ruling.ballInHand
        if let g = ruling.assignedGroup {
            for p in s.groups.indices { s.groups[p] = p == seat ? g : g.other }
        }
        // Only a real shot can foul; answering a choice leaves the foul counts alone.
        if facts != nil, s.consecutiveFouls.indices.contains(seat) {
            if ruling.fouls.isEmpty {
                s.consecutiveFouls[seat] = 0
            } else {
                s.consecutiveFouls[seat] += 1
                s.foulHistory.append(FoulRecord(shot: s.shotCount, player: ruling.shooter, fouls: ruling.fouls))
            }
        }
        for (k, d) in ruling.points.enumerated() where s.scores.indices.contains(k) { s.scores[k] += d }
        if ruling.rerack {
            // A fresh rack: every object ball back, groups open again, the next shooter breaks.
            s.ballsLeft = rack.objectBalls.sorted()
            s.groups = [EightBallGroup?](repeating: nil, count: s.groups.count)
            s.isBreak = true
        } else if let f = facts {
            // The balls still on the table after the shot, plus any put back (spotted or returned to play).
            var left = state.ballsLeft.filter { b in f.resting.indices.contains(b) && ShotFacts.isOnTable(f.resting[b]) }
            for b in ruling.ballsToSpot + ballsReturningToHand(after: f, in: state) where !left.contains(b) {
                left.append(b)
            }
            s.ballsLeft = left.sorted()
            s.isBreak = false
        } else {
            // A choice answered with no shot: the table is as it was, plus any ball the answer spots.
            for b in ruling.ballsToSpot where !s.ballsLeft.contains(b) { s.ballsLeft.append(b) }
            s.ballsLeft.sort()
        }
        s.pendingChoice = ruling.choice
        s.result = ruling.result
        return s
    }
}
