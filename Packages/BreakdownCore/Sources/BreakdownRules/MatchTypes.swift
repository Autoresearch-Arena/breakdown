// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 foundation, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md F8:
//          MatchFoul.cueBallBehindHeadLine, the ball-in-hand-behind-the-line foul; the rules-lens stream calls it.)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-rules) - appended MatchState.breakPoints (optional, nil for
//          every game but bar billiards), the points of the break in progress, which a white peg down takes away.
//          Optional, so a match saved before it decodes unchanged.
// Edited: 21-November-2026 by Claude Opus 5.5 High (opponent) - appended ComputerLevel and Player.computer (optional,
//          nil for a person): the seat the computer plays and how well (App/Match/MatchOpponent.swift turns the level
//          into seeded aim, speed and tip noise). Optional with a default, so every Player(id:name:) call and every
//          match saved before it decode unchanged.
// PURPOSE: The data of a match, shared by every game's rules (this module), the app's match flow (App/Match/MatchMode,
//          which owns a MatchState, asks the rules for a Ruling after each shot and saves the state) and the match
//          screens (App/Match/MatchViews, which turn the codes below into words). Plain values, no rule logic, no
//          words: every reason is a code, so each language writes its own sentence for it.
//            MatchKind      - which game: eight-ball, nine-ball, bumper pool, five-pin, bar billiards.
//            PlayerID       - a player by seat (0 is the first player); Player adds the name shown.
//            BallInHand     - none, anywhere, or behind the head line.
//            MatchRack      - what the game starts from: the fifteen-ball triangle, the nine-ball diamond, or the
//                             table's own start layout (the other tables), with the object balls it holds.
//            MatchFoul      - every foul any game can call (the pool ones share raw values with EightBallFoul).
//            RulingReason   - why a ruling came out the way it did, as codes, in the order they apply.
//            MatchEndReason / MatchResult - how a game ended and who won.
//            MatchChoice / MatchChoiceAnswer / PendingChoice - a decision a player must make before the next shot
//                             (eight-ball: accept the table or re-rack after a bad break; spot the 8 or re-rack).
//            FoulRecord     - one entry in the foul history.
//            Ruling         - the verdict on one shot: fouls, reasons, next shooter, ball in hand, balls to spot,
//                             group assignment, points, a pending choice, a re-rack, the result.
//            MatchState     - the whole match between shots (Codable, so it survives quitting the app).
//          Everything here is Codable with string or integer raw values, so a saved match decodes after cases are
//          appended. Append new cases at the end; never rename or reorder a raw value.
// SRP/DRY check: Pass - checked App/EightBall (its types are reused through EightBallTypes.swift in this module, not
//          copied), plans/21-Nov-2026-rules-games-plan.md and plans/21-Nov-2026-other-tables-games-plan.md. Nothing
//          else in the repo describes a match.

// MARK: Which game, who plays

public enum MatchKind: String, CaseIterable, Codable, Sendable {
    case eightBall, nineBall, bumperPool, fivePin, barBilliards
}

/// A player by seat: 0 is the first player (who breaks the first rack), 1 the second.
public struct PlayerID: Hashable, Comparable, Codable, Sendable {
    public var index: Int
    public init(_ index: Int) { self.index = index }
    public static let first = PlayerID(0)
    public static let second = PlayerID(1)
    /// The next seat round the table among `count` players (a one-player game stays with seat 0).
    public func next(among count: Int) -> PlayerID { PlayerID(count > 0 ? (index + 1) % count : 0) }
    public static func < (a: PlayerID, b: PlayerID) -> Bool { a.index < b.index }
}

/// How well a computer player plays. The level is physical, not a handicap on its choices: every level searches for
/// the same shot, and the level only sets how much seeded noise is added to its aim, speed and tip before the strike
/// (App/Match/MatchOpponent.swift). Raw values are saved with a match; append new levels at the end.
public enum ComputerLevel: String, CaseIterable, Codable, Sendable {
    case easy, medium, hard
}

public struct Player: Hashable, Codable, Sendable {
    public var id: PlayerID
    /// The name shown in the turn banner; the app fills in a translated default ("Player 1") and lets it be edited.
    public var name: String
    /// Set when the computer plays this seat, at this level; nil for a person. Optional with a default, so a match
    /// saved before it existed decodes (synthesized decoding skips a missing optional key) as two people.
    public var computer: ComputerLevel? = nil
    public init(id: PlayerID, name: String, computer: ComputerLevel? = nil) {
        self.id = id; self.name = name; self.computer = computer
    }
    /// True when the computer plays this seat.
    public var isComputer: Bool { computer != nil }
}

/// Where the incoming player may put the cue ball before shooting.
public enum BallInHand: String, Codable, Sendable {
    /// The cue ball is played from where it stopped.
    case none
    /// Anywhere legal on the bed (after a foul).
    case anywhere
    /// Anywhere legal between the head rail and the head line, a quarter of the table's length from the head rail
    /// (the break, and a scratch on the break).
    case behindHeadLine
}

/// What a game starts from. The app turns it into positions (BreakdownPhysics/Rack.swift for the two pool racks, the
/// table's own file in App/Tables for the other tables), so this module needs no physics.
public enum MatchRack: Equatable, Sendable {
    case fifteenBallTriangle
    case nineBallDiamond
    /// The table's own start layout (bumper pool, five-pin, bar billiards). `objectBalls` are the balls that count as
    /// object balls in it (not any player's cue ball).
    case tableLayout(objectBalls: [Int])

    /// The object balls this rack puts on the table.
    public var objectBalls: [Int] {
        switch self {
        case .fifteenBallTriangle: return Array(1...15)
        case .nineBallDiamond: return Array(1...9)
        case .tableLayout(let balls): return balls
        }
    }
}

// MARK: What a ruling can say

/// Every foul any of the games can call. The pool fouls share their raw values with EightBallFoul (init(_:) maps one
/// to the other). The last two belong to the other tables.
public enum MatchFoul: String, CaseIterable, Codable, Sendable {
    case scratch, wrongBallFirst, noBallHit, noRailAfterContact, objectBallOffTable, cueOrBridgeTouchedBall, doubleHit,
         illegalJump
    /// Bumper pool: a ball sunk in the other player's cup.
    case wrongCup
    /// Five-pin: pins knocked down by the shooter's own cue ball.
    case ownBallKnockedPins
    /// Ball in hand behind the head line: the cue ball hit a ball that also started behind the line without crossing
    /// the line first.
    case cueBallBehindHeadLine

    public init(_ foul: EightBallFoul) {
        switch foul {
        case .scratch: self = .scratch
        case .wrongBallFirst: self = .wrongBallFirst
        case .noBallHit: self = .noBallHit
        case .noRailAfterContact: self = .noRailAfterContact
        case .objectBallOffTable: self = .objectBallOffTable
        case .cueOrBridgeTouchedBall: self = .cueOrBridgeTouchedBall
        case .doubleHit: self = .doubleHit
        case .illegalJump: self = .illegalJump
        }
    }
}

/// Why a ruling came out the way it did, in the order the reasons apply. The app writes one sentence per code.
public enum RulingReason: String, Codable, Sendable {
    /// The shooter pocketed a ball that keeps the turn.
    case legalPot
    /// Nothing that keeps the turn went down: the turn passes.
    case noLegalPot
    /// Eight-ball: a ball dropped, but not the called ball in the called pocket.
    case calledBallMissed
    /// One or more fouls (listed in Ruling.fouls).
    case foul
    /// The table is open: no groups yet.
    case tableOpen
    /// Groups were settled on this shot (Ruling.assignedGroup).
    case groupsAssigned
    /// A legal break.
    case breakLegal
    /// The break neither pocketed a ball nor drove enough object balls to a rail: the other player chooses.
    case breakIllegal
    /// The cue ball was pocketed or left the table on the break.
    case scratchOnBreak
    /// Eight-ball: the 8 dropped on the break; the breaker chooses to spot it or re-rack.
    case eightOnBreak
    /// One or more balls go back on the table (Ruling.ballsToSpot).
    case ballSpotted
    /// Nine-ball: the shooter has two fouls in a row; a third loses the game.
    case foulWarning
    /// Points were scored (Ruling.points).
    case pointsScored
    /// Five-pin: the pins are stood up again for the next shot.
    case pinsReset
    /// Bar billiards: balls come back to be played again.
    case ballsReturned
    /// Bar billiards: the white peg went down and the break's points are lost.
    case whitePegDown
    /// Bar billiards: the black peg went down and the whole score is lost.
    case blackPegDown
    /// Bar billiards: the clock ran out.
    case timeUp
    /// A pending choice was answered (MatchChoiceAnswer).
    case choiceAnswered
    /// The table is racked again.
    case rerack
    /// The game is over (Ruling.result).
    case gameOver
}

/// How a game ended.
public enum MatchEndReason: String, Codable, Sendable {
    /// Eight-ball: the 8 legally pocketed in the called pocket after the group was cleared.
    case eightBallPocketed
    /// Eight-ball losses, one per EightBallLoss case.
    case eightOnFoul, eightEarly, eightWrongPocket, eightOffTable
    /// Nine-ball: the 9 legally pocketed.
    case nineBallPocketed
    /// Nine-ball: three fouls in a row by one player.
    case threeConsecutiveFouls
    /// Bumper pool: every ball of one side sunk.
    case allBallsSunk
    /// Five-pin: a player reached the target score.
    case targetScoreReached
    /// Bar billiards: time ran out and the last ball is gone.
    case timeExpired
    /// A player ended the match.
    case conceded

    public init(_ loss: EightBallLoss) {
        switch loss {
        case .eightOnFoul: self = .eightOnFoul
        case .eightEarly: self = .eightEarly
        case .eightWrongPocket: self = .eightWrongPocket
        case .eightOffTable: self = .eightOffTable
        }
    }
}

public struct MatchResult: Equatable, Codable, Sendable {
    /// The winner; nil when the game has no winner (a one-player bar billiards game ends with a score).
    public var winner: PlayerID?
    public var reason: MatchEndReason
    public init(winner: PlayerID?, reason: MatchEndReason) { self.winner = winner; self.reason = reason }
}

/// A decision a player must make before the next shot.
public enum MatchChoice: String, Codable, Sendable {
    /// Eight-ball, after an illegal break: the incoming player takes the table as it lies, or asks for a re-rack.
    case acceptTableOrRerack
    /// Eight-ball, the 8 dropped on the break: the breaker has it spotted, or re-racks.
    case spotEightOrRerack

    /// The answers this choice offers, in the order the app shows them.
    public var answers: [MatchChoiceAnswer] {
        switch self {
        case .acceptTableOrRerack: return [.acceptTable, .rerack]
        case .spotEightOrRerack: return [.spotEight, .rerack]
        }
    }
}

public enum MatchChoiceAnswer: String, Codable, Sendable {
    case acceptTable, spotEight, rerack
}

/// A choice waiting on a player.
public struct PendingChoice: Equatable, Codable, Sendable {
    public var choice: MatchChoice
    public var chooser: PlayerID
    public init(choice: MatchChoice, chooser: PlayerID) { self.choice = choice; self.chooser = chooser }
}

/// One entry in the foul history: which shot of the match (1 is the first), who, which fouls.
public struct FoulRecord: Equatable, Codable, Sendable {
    public var shot: Int
    public var player: PlayerID
    public var fouls: [MatchFoul]
    public init(shot: Int, player: PlayerID, fouls: [MatchFoul]) { self.shot = shot; self.player = player; self.fouls = fouls }
}

// MARK: The ruling on one shot

public struct Ruling: Equatable, Codable, Sendable {
    /// Who took the shot (or answered the choice).
    public var shooter: PlayerID
    /// The fouls found, in the order of MatchFoul's cases. Empty for a legal shot.
    public var fouls: [MatchFoul]
    /// Why, as codes in the order they apply.
    public var reasons: [RulingReason]
    /// Who shoots next.
    public var nextShooter: PlayerID
    /// Where the next shooter may place the cue ball.
    public var ballInHand: BallInHand
    /// Object balls to put back on the table (on the foot spot, or the nearest free place behind it).
    public var ballsToSpot: [Int]
    /// The group given to the shooter on this shot (every other player takes the other group); nil when unchanged.
    public var assignedGroup: EightBallGroup?
    /// Points this shot earned, per player seat (negative for a penalty). Empty for games without a score.
    public var points: [Int]
    /// A decision the named player must make before anyone shoots.
    public var choice: PendingChoice?
    /// The table is racked again before the next shot (the next shooter breaks).
    public var rerack: Bool
    /// Set when this shot ended the game.
    public var result: MatchResult?

    public init(shooter: PlayerID, nextShooter: PlayerID, fouls: [MatchFoul] = [], reasons: [RulingReason] = [],
                ballInHand: BallInHand = .none, ballsToSpot: [Int] = [], assignedGroup: EightBallGroup? = nil,
                points: [Int] = [], choice: PendingChoice? = nil, rerack: Bool = false, result: MatchResult? = nil) {
        self.shooter = shooter; self.nextShooter = nextShooter; self.fouls = fouls; self.reasons = reasons
        self.ballInHand = ballInHand; self.ballsToSpot = ballsToSpot; self.assignedGroup = assignedGroup
        self.points = points; self.choice = choice; self.rerack = rerack; self.result = result
    }

    public var fouled: Bool { !fouls.isEmpty }
    /// True when someone else shoots next.
    public var turnPasses: Bool { nextShooter != shooter }
}

// MARK: The match between shots

public struct MatchState: Equatable, Codable, Sendable {
    public var kind: MatchKind
    public var players: [Player]
    /// Whose turn it is.
    public var turn: PlayerID
    /// Each player's group, by seat; all nil while the table is open (and always nil outside eight-ball).
    public var groups: [EightBallGroup?]
    /// Object balls still on the table, ascending.
    public var ballsLeft: [Int]
    public var ballInHand: BallInHand
    /// Shots taken so far in this match (a re-rack does not reset it).
    public var shotCount: Int
    /// True when the next shot is a break.
    public var isBreak: Bool
    /// Fouls in a row, by seat (a legal shot by that player resets theirs).
    public var consecutiveFouls: [Int]
    public var foulHistory: [FoulRecord]
    /// Running score, by seat (zero throughout for games without a score).
    public var scores: [Int]
    /// A decision that must be made before the next shot.
    public var pendingChoice: PendingChoice?
    /// Seconds left on the game clock (bar billiards); nil for games without one.
    public var clockRemaining: Double?
    /// Set when the game is over.
    public var result: MatchResult?
    /// Points scored so far in the break in progress (bar billiards, where a white peg down loses them); nil for games
    /// that do not track a break. Optional so older saved matches decode (synthesized decoding skips a missing key).
    public var breakPoints: Int? = nil

    /// A fresh match: everyone on zero, the first player to break.
    public init(kind: MatchKind, playerNames: [String], ballsLeft: [Int], ballInHand: BallInHand = .none,
                clock: Double? = nil, firstShooter: PlayerID = .first) {
        self.kind = kind
        players = playerNames.enumerated().map { Player(id: PlayerID($0.offset), name: $0.element) }
        turn = firstShooter
        groups = [EightBallGroup?](repeating: nil, count: playerNames.count)
        self.ballsLeft = ballsLeft.sorted()
        self.ballInHand = ballInHand
        shotCount = 0
        isBreak = true
        consecutiveFouls = [Int](repeating: 0, count: playerNames.count)
        foulHistory = []
        scores = [Int](repeating: 0, count: playerNames.count)
        pendingChoice = nil
        clockRemaining = clock
        result = nil
    }

    public var isOver: Bool { result != nil }
    /// True while no player has a group.
    public var tableOpen: Bool { groups.allSatisfy { $0 == nil } }
    public var currentPlayer: Player? { players.indices.contains(turn.index) ? players[turn.index] : nil }

    public func group(of player: PlayerID) -> EightBallGroup? {
        groups.indices.contains(player.index) ? groups[player.index] : nil
    }

    /// A player's balls still on the table in eight-ball (empty while the table is open or outside eight-ball).
    public func ballsRemaining(for player: PlayerID) -> [Int] {
        guard let g = group(of: player) else { return [] }
        return ballsLeft.filter { g.balls.contains($0) }
    }
}
