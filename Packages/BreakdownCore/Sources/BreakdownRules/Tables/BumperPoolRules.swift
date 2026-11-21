// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The rules of bumper pool as the rule sheet in plans/21-Nov-2026-other-tables-games-plan.md states them
//          (one simple, widely played version). Two players, five balls each; the first player's five start round the
//          near cup (bed hole 0) and go into the far cup (bed hole 1), the second player's the other way round. You
//          strike your marked ball while it is on the table, then your other balls lowest number first; sinking one of
//          your own in your cup shoots again; a ball in the wrong cup or off the table is a foul, comes back to its
//          starting spot and passes the turn; the first side with all five down wins.
//          Reads ShotFacts (bed-hole drops with their hole number, balls off the table) and the MatchState; writes a
//          Ruling. The app's match flow (App/Match/MatchMode.swift) builds the facts with cueBall(for:in:) as the
//          struck ball and calls nextLayout(after:ruling:start:table:) for the next solve's layout.
//          Ball numbers and cups are the ones App/Tables/BumperPoolTable.swift lays out; that file reads `sides` from
//          here, so the two cannot drift apart.
// SRP/DRY check: Pass - bumper pool's rules only. The bookkeeping is the protocol's shared default (MatchRules.swift);
//          putting balls back uses TableSpots; no other file decides a bumper-pool shot.
import BreakdownLensModel
import BreakdownTimeline

public struct BumperPoolRules: MatchRules {
    /// Each seat's five balls, the marked ball first: seat 0's start round the near cup, seat 1's round the far cup.
    public static let sides: [[Int]] = [[0, 1, 2, 3, 4], [9, 10, 11, 12, 13]]
    /// The bed hole each seat's balls must go into: the cup at the far end from where they started (bed hole 0 is the
    /// near cup at plan x = 0, bed hole 1 the far cup, BumperPoolTable.bedHoles).
    public static let targetHole = [1, 0]

    public init() {}

    public var kind: MatchKind { .bumperPool }
    /// Every ball counts here: there is no shared cue ball, and the marked balls must be sunk too, so `ballsLeft`
    /// lists all ten balls still on the table.
    public var rack: MatchRack { .tableLayout(objectBalls: Self.sides.flatMap { $0 }) }
    /// Bumper pool has no calls.
    public func mayCall(_ ball: Int, in state: MatchState) -> Bool { false }

    /// The seat a ball belongs to, nil for a ball that is not in the game.
    public static func seat(of ball: Int) -> Int? { sides.firstIndex { $0.contains(ball) } }

    /// The balls `player` still has on the table, in playing order.
    public func ballsLeft(for player: PlayerID, in state: MatchState) -> [Int] {
        guard Self.sides.indices.contains(player.index) else { return [] }
        return Self.sides[player.index].filter { state.ballsLeft.contains($0) }
    }

    /// The marked ball while it is on the table, then the player's other balls lowest number first (rule 3: real
    /// tables let you choose; one fixed order keeps the controls to a single striking ball).
    public func cueBall(for player: PlayerID, in state: MatchState) -> Int {
        guard Self.sides.indices.contains(player.index) else { return 0 }
        return ballsLeft(for: player, in: state).first ?? Self.sides[player.index][0]
    }

    public func ruling(for facts: ShotFacts, call: EightBallCall?, in state: MatchState) -> Ruling {
        let shooter = state.turn
        let seat = shooter.index
        let inPlay = Set(state.ballsLeft)
        var fouls: Set<MatchFoul> = []
        var toSpot: [Int] = []
        var sunk: Set<Int> = []
        var sunkOwn = false

        // Rules 4 to 6: each drop is either a ball in its own side's cup (it stays down) or a ball in the wrong cup.
        for d in facts.holeDrops where inPlay.contains(d.ball) {
            guard let side = Self.seat(of: d.ball) else { continue }
            if d.hole == Self.targetHole[side] {
                sunk.insert(d.ball)
                if side == seat { sunkOwn = true }
            } else {
                fouls.insert(.wrongCup)
                toSpot.append(d.ball)
            }
        }
        // Rule 6: any ball off the table. The struck ball leaving is the scratch; any other ball, an object ball off.
        if facts.cueBallOffTable, inPlay.contains(facts.cueBall) {
            fouls.insert(.scratch)
            toSpot.append(facts.cueBall)
        }
        for b in facts.objectBallsOffTable where inPlay.contains(b) {
            fouls.insert(.objectBallOffTable)
            toSpot.append(b)
        }

        // Rule 7: the first side with nothing left wins, the shooter's side checked first (whoever sank the last one).
        let left = inPlay.subtracting(sunk)
        let order = [seat] + Self.sides.indices.filter { $0 != seat }
        let winner = order.first { s in
            Self.sides.indices.contains(s) && !Self.sides[s].contains(where: { left.contains($0) })
        }
        let result = winner.map { MatchResult(winner: PlayerID($0), reason: .allBallsSunk) }

        let keepsTurn = fouls.isEmpty && sunkOwn && result == nil
        var reasons: [RulingReason] = []
        if !fouls.isEmpty { reasons.append(.foul) }
        if result == nil { reasons.append(keepsTurn ? .legalPot : .noLegalPot) }
        if !toSpot.isEmpty { reasons.append(.ballSpotted) }
        if result != nil { reasons.append(.gameOver) }

        return Ruling(shooter: shooter,
                      nextShooter: keepsTurn || result != nil ? shooter : shooter.next(among: max(state.players.count, 1)),
                      fouls: MatchFoul.allCases.filter { fouls.contains($0) },
                      reasons: reasons,
                      ballsToSpot: toSpot.sorted(),
                      result: result)
    }

    /// The layout for the next solve: every ball where it came to rest, and each ball the ruling puts back on its
    /// starting spot from `start` (the table's start layout, BumperPoolTable.startLayout) or the nearest free place.
    /// `table` is the recorded TableSpec (Timeline.table), so the cups and bumpers are kept clear.
    public static func nextLayout(after facts: ShotFacts, ruling: Ruling, start: [Vec2], table: TableSpec) -> [Vec2] {
        var out = facts.resting
        for b in ruling.ballsToSpot.sorted() where out.indices.contains(b) && start.indices.contains(b) {
            let spot = start[b]
            guard ShotFacts.isOnTable(spot) else { continue }
            // The start spots sit near the end cushions, so step toward the middle of the table first.
            let towardMiddle = Vec2(spot.x < table.length / 2 ? 1 : -1, 0)
            out[b] = ShotFacts.offTable
            out[b] = TableSpots.nearestFree(to: spot, for: b, among: out, table: table, first: towardMiddle)
        }
        return out
    }
}
