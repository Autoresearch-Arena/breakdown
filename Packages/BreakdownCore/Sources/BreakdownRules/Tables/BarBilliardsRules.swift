// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The rules of bar billiards as the rule sheet in plans/21-Nov-2026-other-tables-games-plan.md states them
//          (one simple, widely played version). One or two players against a clock. Every shot is played with a white
//          from the tray placed on the D spot; the played ball must hit another ball first; each ball that then drops
//          scores its hole (200, 100, 50, 50, then 30, 20, 10, 20, 30 along the far row), the red double. A break goes
//          on while every shot drops a ball. A white peg down ends the break and loses its points; the black peg down
//          ends it and loses the whole score. Dropped balls come back to the tray (the red back to its spot) until time
//          is up; then a bar drops, dropped balls stay down, and the game ends when no white is left to play.
//          The clock is injected: the rules only read MatchState.clockRemaining (set from turnClock at the start), the
//          app counts it down with ticking(_:by:) while balls are in play and pauses it during replays and the Lens,
//          and a test simply sets it, so nothing here ever waits. A shot is judged by the clock as it stands when the
//          shot is ruled: if time ran out while the balls were still rolling, the bar is already down for that shot.
//          Reads ShotFacts (first contact, bed-hole drops, pins down, resting places) and the MatchState; writes a
//          Ruling, keeps MatchState.breakPoints (the break in progress) through applying(_:facts:to:), and gives the
//          next solve's layout with nextLayout(after:in:table:dSpot:redSpot:).
//          Calling order matters: every one of those takes the state as it stood BEFORE the shot (the bar, the balls
//          still in the game and the break all come from it), so the app asks for the ruling and the next layout first
//          and only then applies the ruling. cueBall(for:in:) does not depend on the player: both seats play the
//          lowest-numbered white still in the game.
//          Hole values, ball numbers and the black peg's number are owned here; App/Tables/BarBilliardsTable.swift
//          reads them, so the table and the scoring cannot disagree.
// SRP/DRY check: Pass - bar billiards' rules only. The shared bookkeeping is the protocol's default, reached through a
//          small forwarding value rather than copied; the free-place search is TableSpots; the hole values moved here
//          from BarBilliardsTable.swift (which now reads them) rather than being copied.
import BreakdownLensModel
import BreakdownTimeline

public struct BarBilliardsRules: MatchRules {
    /// Points for each bed hole, in TableSpec.bedHoles order (BarBilliardsTable.bedHoles): the 200 nearest the
    /// player, the 100, the two 50s, then the far row 30, 20, 10, 20, 30.
    public static let holeValues = [200, 100, 50, 50, 30, 20, 10, 20, 30]
    /// The red ball (drawn solid red); it scores double.
    public static let redBall = 3
    /// How many times its hole's value the red scores.
    public static let redMultiplier = 2
    /// The seven whites, the one on the D first. Every other slot is never used on this table.
    public static let whiteBalls = [0, 1, 2, 4, 5, 6, 7]
    /// The black peg (TableSpec.pins index); pins 1 and 2 are the white pegs.
    public static let blackPeg = 0
    /// Fifteen minutes: about what one game on a pub table runs for.
    public static let standardClock: Double = 15 * 60

    /// The game's length in seconds.
    public let clockLength: Double

    public init(clockLength: Double = BarBilliardsRules.standardClock) { self.clockLength = clockLength }

    public var kind: MatchKind { .barBilliards }
    /// All eight balls are in the game; `ballsLeft` lists every ball still in it, on the table or waiting in the tray.
    /// Once the bar is down, a ball that drops leaves the list for good.
    public var rack: MatchRack { .tableLayout(objectBalls: (Self.whiteBalls + [Self.redBall]).sorted()) }
    public func mayCall(_ ball: Int, in state: MatchState) -> Bool { false }
    public var playerCount: ClosedRange<Int> { 1...2 }
    public var keepsRunningScore: Bool { true }
    public var turnClock: Double? { clockLength }

    /// The white played next: the lowest-numbered white still in the game. nextLayout puts exactly that ball on the
    /// D (whites are identical, so if it is resting on the table it trades places with one from the tray).
    public func cueBall(for player: PlayerID, in state: MatchState) -> Int { Self.striker(among: Set(state.ballsLeft)) }

    private static func striker(among inGame: Set<Int>) -> Int { whiteBalls.first { inGame.contains($0) } ?? whiteBalls[0] }

    public func initialState(playerNames: [String]) -> MatchState {
        var s = MatchState(kind: kind, playerNames: playerNames, ballsLeft: rack.objectBalls, ballInHand: startingBallInHand,
                           clock: turnClock)
        s.breakPoints = 0
        return s
    }

    // MARK: The clock

    /// True once time is up: the bar is down and dropped balls stay down.
    public func barIsDown(in state: MatchState) -> Bool { (state.clockRemaining ?? clockLength) <= 0 }

    /// The state with `seconds` more taken off the clock (never below zero; a finished game's clock stops).
    public func ticking(_ state: MatchState, by seconds: Double) -> MatchState {
        guard !state.isOver, seconds > 0, let left = state.clockRemaining else { return state }
        var s = state
        s.clockRemaining = max(0, left - seconds)
        return s
    }

    // MARK: One shot

    /// Everything a shot decides, worked out once and read by the ruling, the returning balls, the bookkeeping and
    /// the next layout, so the four can never disagree.
    private struct Outcome {
        var barDown: Bool
        /// The played ball touched another ball.
        var hit: Bool
        var blackPeg: Bool
        var whitePeg: Bool
        /// Balls in the game that dropped into a hole this shot.
        var dropped: [Int]
        /// What the drops are worth (zero on a miss: rule 4).
        var value: Int
        /// The same player plays again in the same break.
        var breakGoesOn: Bool
        /// Balls resting on the table that go back to the tray before the next shot.
        var lifted: [Int]
        /// The red goes back on its spot.
        var spotRed: Bool
        /// Every ball still in the game after the shot.
        var inGame: Set<Int>
        /// The bar is down and no white is left to play.
        var gameOver: Bool
    }

    private func outcome(_ f: ShotFacts, _ s: MatchState) -> Outcome {
        func onTable(_ b: Int) -> Bool { f.resting.indices.contains(b) && ShotFacts.isOnTable(f.resting[b]) }
        let barDown = barIsDown(in: s)
        let before = Set(s.ballsLeft)
        let hit = f.firstContact != nil
        let pegs = Set(f.pinsDown.map(\.pin))
        let blackPeg = pegs.contains(Self.blackPeg)
        let whitePeg = !pegs.subtracting([Self.blackPeg]).isEmpty
        let drops = f.holeDrops.filter { before.contains($0.ball) && Self.holeValues.indices.contains($0.hole) }
        let worth = drops.reduce(0, { sum, d in
            sum + Self.holeValues[d.hole] * (d.ball == Self.redBall ? Self.redMultiplier : 1)
        })
        let value = hit ? worth : 0
        // Rule 4 and 5: the break goes on only for a hit that dropped something and left both peg colours standing.
        let breakGoesOn = hit && !blackPeg && !whitePeg && !drops.isEmpty

        // Rule 7: with the bar down, a ball that drops is out of the game.
        var inGame = before
        if barDown { inGame.subtract(drops.map(\.ball)) }
        // Rule 6: the red goes back on its spot whenever it is still in the game but off the table (dropped while
        // the bar was up, or knocked off the table).
        let spotRed = inGame.contains(Self.redBall) && !onTable(Self.redBall)

        // Rule 4: a played ball that hit nothing goes back to the tray.
        var tableWhites = Self.whiteBalls.filter { inGame.contains($0) && onTable($0) }
        var lifted: [Int] = []
        if !hit, let k = tableWhites.firstIndex(of: f.cueBall) { lifted.append(tableWhites.remove(at: k)) }
        // Rule 6 and 7: no white left in the tray. While time remains they all come back; once the bar is down the
        // game is over.
        let tray = Self.whiteBalls.filter { inGame.contains($0) && !tableWhites.contains($0) }
        var gameOver = false
        if tray.isEmpty {
            if barDown {
                gameOver = true
            } else {
                lifted += tableWhites
            }
        }
        return Outcome(barDown: barDown, hit: hit, blackPeg: blackPeg, whitePeg: whitePeg, dropped: drops.map(\.ball),
                       value: value, breakGoesOn: breakGoesOn && !gameOver, lifted: lifted.sorted(), spotRed: spotRed,
                       inGame: inGame, gameOver: gameOver)
    }

    public func ruling(for facts: ShotFacts, call: EightBallCall?, in state: MatchState) -> Ruling {
        let o = outcome(facts, state)
        let shooter = state.turn
        let seat = shooter.index
        let count = max(state.players.count, 1)
        var points = [Int](repeating: 0, count: count)
        var fouls: [MatchFoul] = []
        var reasons: [RulingReason] = []
        if o.barDown { reasons.append(.timeUp) }

        // Rule 5 before rule 3: a peg down scores nothing for the shot, whatever dropped.
        if o.blackPeg {
            if points.indices.contains(seat), state.scores.indices.contains(seat) { points[seat] = -state.scores[seat] }
            reasons.append(.blackPegDown)
        } else if o.whitePeg {
            if points.indices.contains(seat) { points[seat] = -(state.breakPoints ?? 0) }
            reasons.append(.whitePegDown)
        } else if !o.hit {
            fouls = [.noBallHit]
            reasons.append(.foul)
        } else {
            if points.indices.contains(seat) { points[seat] = o.value }
            if o.value != 0 { reasons.append(.pointsScored) }
            reasons.append(o.breakGoesOn ? .legalPot : .noLegalPot)
        }

        let returnedWhites = o.dropped.filter { $0 != Self.redBall && o.inGame.contains($0) }
        if !returnedWhites.isEmpty || !o.lifted.isEmpty { reasons.append(.ballsReturned) }
        if o.spotRed { reasons.append(.ballSpotted) }

        var result: MatchResult?
        if o.gameOver {
            // Two players: the higher score wins, a tie has no winner. One player plays for a score.
            let final = state.scores.enumerated().map { $0.element + (points.indices.contains($0.offset) ? points[$0.offset] : 0) }
            var winner: PlayerID?
            if final.count >= 2, let best = final.max(), final.filter({ $0 == best }).count == 1,
               let k = final.firstIndex(of: best) {
                winner = PlayerID(k)
            }
            result = MatchResult(winner: winner, reason: .timeExpired)
            reasons.append(.gameOver)
        }

        return Ruling(shooter: shooter,
                      nextShooter: o.breakGoesOn || result != nil ? shooter : shooter.next(among: count),
                      fouls: fouls, reasons: reasons, ballsToSpot: o.spotRed ? [Self.redBall] : [],
                      points: points, result: result)
    }

    /// Every white still in the game that is not on the table after the shot (dropped while the bar was up, never
    /// played yet, or lifted back by rule 4 or 6): the tray. The shared bookkeeping keeps them in `ballsLeft`.
    public func ballsReturningToHand(after facts: ShotFacts, in state: MatchState) -> [Int] {
        let o = outcome(facts, state)
        return Self.whiteBalls.filter { b in
            o.inGame.contains(b) && (o.lifted.contains(b) || !(facts.resting.indices.contains(b) && ShotFacts.isOnTable(facts.resting[b])))
        }
    }

    /// The shared bookkeeping, plus the break in progress: a break that goes on adds this shot's points to it, a
    /// break that ends starts the next one from zero.
    public func applying(_ ruling: Ruling, facts: ShotFacts?, to state: MatchState) -> MatchState {
        var s = SharedBookkeeping(rules: self).applying(ruling, facts: facts, to: state)
        if let facts {
            let o = outcome(facts, state)
            s.breakPoints = o.breakGoesOn ? (state.breakPoints ?? 0) + o.value : 0
        }
        return s
    }

    /// The layout for the next solve: balls where they came to rest, lifted whites back in the tray (off the table),
    /// the red on its spot when it comes back, and the next white (cueBall(for:in:) of the state after the shot) on
    /// the D spot, or the nearest free place behind it. `table` is the recorded TableSpec (holes and pegs kept clear);
    /// `dSpot` and `redSpot` are BarBilliardsTable's spots. When the game is over nothing is set on the D.
    public func nextLayout(after facts: ShotFacts, in state: MatchState, table: TableSpec, dSpot: Vec2,
                           redSpot: Vec2) -> [Vec2] {
        let o = outcome(facts, state)
        var out = facts.resting
        for b in o.lifted where out.indices.contains(b) { out[b] = ShotFacts.offTable }
        if o.spotRed, out.indices.contains(Self.redBall) {
            out[Self.redBall] = ShotFacts.offTable
            // Toward the far cushion first: behind the red spot is the D, where the next white goes.
            out[Self.redBall] = TableSpots.nearestFree(to: redSpot, for: Self.redBall, among: out, table: table,
                                                       first: Vec2(1, 0))
        }
        if o.gameOver { return out }
        let next = Self.striker(among: o.inGame)
        guard out.indices.contains(next) else { return out }
        // Already resting on the D (within one ball of it): it simply stays to be played again.
        let atD = (out[next] - dSpot).length < 2 * table.ballRadius * TableSpots.clearance
        if ShotFacts.isOnTable(out[next]), !atD {
            // The next white is resting elsewhere on the table: a white from the tray takes its place there (they look
            // alike), so the striking ball is always the one cueBall(for:in:) names.
            if let spare = Self.whiteBalls.first(where: { b in
                b != next && o.inGame.contains(b) && out.indices.contains(b) && !ShotFacts.isOnTable(out[b])
            }) {
                out[spare] = out[next]
            }
        }
        out[next] = ShotFacts.offTable
        out[next] = TableSpots.nearestFree(to: dSpot, for: next, among: out, table: table, first: Vec2(-1, 0))
        return out
    }
}

/// Forwards everything to the bar-billiards rules except `applying`, so calling `applying` on it runs the protocol's
/// shared default bookkeeping (a type that implements `applying` itself cannot call the default directly).
private struct SharedBookkeeping: MatchRules {
    let rules: BarBilliardsRules
    var kind: MatchKind { rules.kind }
    var rack: MatchRack { rules.rack }
    func ruling(for facts: ShotFacts, call: EightBallCall?, in state: MatchState) -> Ruling {
        rules.ruling(for: facts, call: call, in: state)
    }
    func mayCall(_ ball: Int, in state: MatchState) -> Bool { rules.mayCall(ball, in: state) }
    func ballsReturningToHand(after facts: ShotFacts, in state: MatchState) -> [Int] {
        rules.ballsReturningToHand(after: facts, in: state)
    }
}
