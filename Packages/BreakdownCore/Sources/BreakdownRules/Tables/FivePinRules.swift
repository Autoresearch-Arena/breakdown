// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The rules of five-pin billiards as the rule sheet in plans/21-Nov-2026-other-tables-games-plan.md states
//          them (one simple, widely played version). Two players, each with their own ball (the first the white,
//          ball 0; the second the yellow, ball 1), a shared red ball (ball 3) and five pins (pin 0 the red centre
//          pin, 1 to 4 white). Turns alternate every shot. Your ball must hit the other player's ball first; then each
//          white pin down is 2 points, the red pin 4 (10 if it falls alone), and the other player's ball hitting the
//          red 3. A miss, hitting the red first, your own ball knocking a pin, or any ball off the table is a foul: the
//          shot's points go to the other player, never less than 2. Pins stand again after every shot; first to the
//          target score (60) wins.
//          Reads ShotFacts (first contact, every ball-to-ball contact, pins down with the ball that did it, balls off
//          the table) and the MatchState; writes a Ruling with per-seat points. The app's match flow builds the facts
//          with cueBall(for:in:) and calls nextLayout(after:table:spots:) for the next solve's layout.
//          Ball and pin numbers are the ones App/Tables/FivePinTable.swift lays out; that file reads them from here.
// SRP/DRY check: Pass - five-pin's rules only. The bookkeeping (adding points to the scores) is the protocol's shared
//          default; the free-place search is TableSpots; no other file scores a five-pin shot.
import BreakdownLensModel
import BreakdownTimeline

public struct FivePinRules: MatchRules {
    /// The ball each seat strikes: seat 0 the white (ball 0), seat 1 the yellow (ball 1).
    public static let playerBalls = [0, 1]
    /// The shared red object ball.
    public static let redBall = 3
    /// The red centre pin (TableSpec.pins index); the other four pins are white.
    public static let redPin = 0

    // Points of the common simple version (rule sheet, rule 3 and 4); no governing body's table is copied.
    /// Each white pin knocked down.
    public static let whitePinPoints = 2
    /// The red centre pin when other pins fall with it.
    public static let redPinPoints = 4
    /// The red centre pin when it is the only pin to fall: the hardest pin result, so it pays the most.
    public static let redPinAlonePoints = 10
    /// The other player's ball hitting the red ball.
    public static let redBallPoints = 3
    /// A foul never gives the other player less than one white pin, so a miss is never free.
    public static let foulMinimum = whitePinPoints
    /// The common target for a short game.
    public static let standardTarget = 60

    /// Points needed to win.
    public let targetScore: Int

    public init(targetScore: Int = FivePinRules.standardTarget) { self.targetScore = targetScore }

    public var kind: MatchKind { .fivePin }
    /// All three balls stay in play the whole game (a ball off the table comes back), so `ballsLeft` lists them all.
    public var rack: MatchRack { .tableLayout(objectBalls: (Self.playerBalls + [Self.redBall]).sorted()) }
    public func mayCall(_ ball: Int, in state: MatchState) -> Bool { false }
    /// Rule 5. Every fresh solve already starts with every pin standing (the solver's knocked-down flags begin false
    /// on each solve), so this is the declaration the app reads to draw them standing; the layout helper below only
    /// has to move balls off the pins' spots.
    public var resetsPinsBetweenShots: Bool { true }
    public var keepsRunningScore: Bool { true }

    public func cueBall(for player: PlayerID, in state: MatchState) -> Int {
        Self.playerBalls.indices.contains(player.index) ? Self.playerBalls[player.index] : Self.playerBalls[0]
    }

    /// The other player's ball: the one the shooter must hit first.
    public func targetBall(for player: PlayerID) -> Int {
        Self.playerBalls[(player.index + 1) % Self.playerBalls.count]
    }

    /// The points the pins knocked down this shot are worth (rule 3), whichever ball knocked them.
    public static func pinPoints(_ pins: Set<Int>) -> Int {
        if pins == [redPin] { return redPinAlonePoints }
        return pins.reduce(0) { $0 + ($1 == redPin ? redPinPoints : whitePinPoints) }
    }

    public func ruling(for facts: ShotFacts, call: EightBallCall?, in state: MatchState) -> Ruling {
        let shooter = state.turn
        let count = max(state.players.count, 1)
        let other = shooter.next(among: count)
        let own = cueBall(for: shooter, in: state)
        let target = targetBall(for: shooter)
        let inPlay = Set(state.ballsLeft)

        // Rule 4, in MatchFoul's order.
        var fouls: [MatchFoul] = []
        if facts.cueBallOffTable { fouls.append(.scratch) }
        if let first = facts.firstContact(preferring: [target]) {
            if first.ball != target { fouls.append(.wrongBallFirst) }
        } else {
            fouls.append(.noBallHit)
        }
        let othersOff = facts.objectBallsOffTable.filter { inPlay.contains($0) }
        if !othersOff.isEmpty { fouls.append(.objectBallOffTable) }
        if facts.pinsDown.contains(where: { $0.ball == own }) { fouls.append(.ownBallKnockedPins) }
        fouls = MatchFoul.allCases.filter { fouls.contains($0) }

        // Rule 3: what the shot made, counted the same whether it goes to the shooter or (on a foul) the other player.
        let pins = Set(facts.pinsDown.map(\.pin))
        let made = Self.pinPoints(pins) + (facts.touched(target, Self.redBall) ? Self.redBallPoints : 0)
        var points = [Int](repeating: 0, count: count)
        if fouls.isEmpty {
            if points.indices.contains(shooter.index) { points[shooter.index] = made }
        } else if points.indices.contains(other.index) {
            points[other.index] = max(made, Self.foulMinimum)
        }

        // Rule 6: the first to reach the target wins (only one player scores on any shot).
        let after = state.scores.enumerated().map { $0.element + (points.indices.contains($0.offset) ? points[$0.offset] : 0) }
        let winner = after.indices.first { after[$0] >= targetScore && points.indices.contains($0) && points[$0] > 0 }
        let result = winner.map { MatchResult(winner: PlayerID($0), reason: .targetScoreReached) }

        let toSpot = ((facts.cueBallOffTable ? [own] : []) + othersOff).sorted()
        var reasons: [RulingReason] = []
        if !fouls.isEmpty { reasons.append(.foul) }
        if points.contains(where: { $0 != 0 }) { reasons.append(.pointsScored) }
        if !pins.isEmpty { reasons.append(.pinsReset) }
        if !toSpot.isEmpty { reasons.append(.ballSpotted) }
        if result != nil { reasons.append(.gameOver) }

        // Rule 2: one shot each, so the turn always passes.
        return Ruling(shooter: shooter, nextShooter: result == nil ? other : shooter, fouls: fouls, reasons: reasons,
                      ballsToSpot: toSpot, points: points, result: result)
    }

    /// The layout for the next solve (rule 5). Every ball stays where it came to rest, except a ball that left the
    /// table or rests where a pin must stand again: it goes to its own spot, or the nearest free place. `spots` gives
    /// each ball's spot (the app passes FivePinTable's white start, the yellow's spot and the red's spot); `table` is
    /// the recorded TableSpec, whose pins are where they stand. Balls are placed in ball order, so the same shot always
    /// gives the same layout.
    public static func nextLayout(after resting: [Vec2], table: TableSpec, spots: [Int: Vec2]) -> [Vec2] {
        let moving = spots.keys.filter { b in
            resting.indices.contains(b) && (!ShotFacts.isOnTable(resting[b]) || TableSpots.blocksAPin(resting[b], table: table))
        }
        // Away from the castle toward the nearer short cushion: the spots lie on the long string.
        var out = resting
        for b in moving.sorted() {
            guard let spot = spots[b] else { continue }
            let outward = Vec2(spot.x < table.length / 2 ? -1 : 1, 0)
            out[b] = ShotFacts.offTable
            out[b] = TableSpots.nearestFree(to: spot, for: b, among: out, table: table, first: outward)
        }
        return out
    }
}
