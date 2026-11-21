// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The app-side pieces that turn bumper pool, five-pin and bar billiards into games you play from the first
//          shot to a result card (plans/21-Nov-2026-other-tables-games-plan.md packages 2 to 5, screen side). No words
//          and no drawing here; the rules themselves are the package's (BreakdownRules/Tables). Four parts:
//            - TableKind.matchKind: the game each table plays, so the Tables list can start it.
//            - MatchClock: when the bar-billiards clock runs. It is a real-time clock (seconds the players spend at
//              the table), stopped whenever what is on screen is not live play: during a replay of a shot already
//              seen, while the Physics Lens is up, while a shot is being solved, while a ruling or hand-over card is
//              up, and (because ShowpieceModel.advance stops before it reaches the match) while the menu is open.
//              Pure functions over plain values, so the tests check every case without building a model.
//            - TablePoints: what a five-pin or bar-billiards shot scored, line by line, for the points-explained card
//              and VoiceOver. Every number is read from the rules' own constants (FivePinRules, BarBilliardsRules)
//              or from the ruling, never retyped, so the card cannot disagree with the score.
//            - BarBilliardsBest: the single-player high score, kept on the device in UserDefaults.
//          Read by MatchMode (clock, points, high score), MatchViews and TableGameWords (the points lines) and
//          TableList / TableGamePage (which game a table plays, the best score).
// SRP/DRY check: Pass - checked MatchMode (it owns the turn loop and calls these), BreakdownRules/Tables (all rule
//          decisions; the point values come from there), MatchWords/TableGameWords (the words). The clock rule lives
//          only here; MatchMode just feeds it the frame's facts.
import BreakdownLensModel
import BreakdownRules
import BreakdownTimeline
import Foundation

// MARK: Which game a table plays

extension TableKind {
    /// The game this table is played as in a match; nil for the pool table, which plays eight-ball or nine-ball from
    /// the Play menu instead.
    var matchKind: MatchKind? {
        switch self {
        case .standard: return nil
        case .bumperPool: return .bumperPool
        case .fivePin: return .fivePin
        case .barBilliards: return .barBilliards
        }
    }
}

extension MatchKind {
    /// True for the three games of the other tables (their own layouts, their own cue balls, no pool rack).
    var isTableGame: Bool {
        switch self {
        case .eightBall, .nineBall: return false
        case .bumperPool, .fivePin, .barBilliards: return true
        }
    }
}

// MARK: The game clock

enum MatchClock {
    /// Where the match's turn loop is, as far as the clock cares. Its own small enum, not MatchMode.Phase, so this
    /// rule stays a plain value that needs nothing from the main actor.
    enum Stage: Equatable {
        /// Lining up the next shot.
        case aiming
        /// A shot being solved or played.
        case shooting
        /// A ruling or hand-over card, or the game over.
        case betweenShots

        /// The clock's stage for a turn-loop phase (MatchMode calls this on the main actor, where its phase lives).
        @MainActor init(_ phase: MatchMode.Phase) {
            switch phase {
            case .aiming: self = .aiming
            case .shooting: self = .shooting
            case .ruling, .handOver, .over: self = .betweenShots
            }
        }
    }

    /// What the clock needs to know about one frame.
    struct Moment: Equatable {
        /// The game has a clock at all (bar billiards).
        var hasClock: Bool
        var isOver: Bool
        var stage: Stage
        /// The Physics Lens is up (ShowpieceModel.lensOn).
        var lensOn: Bool
        /// A shot is being solved on a background task; the computer's time is not the players'.
        var isSolving: Bool
        /// The balls on screen are the balls the next shot starts from (ShowpieceModel.aimReady). False while the
        /// player replays or scrubs the last shot during aiming.
        var tableAtRest: Bool
        /// While a shot plays: the replay clock moved past the furthest point already shown this frame, so this is
        /// the shot's first showing. Rewinding and watching again does not move it past that point.
        var playingNewGround: Bool
    }

    /// True when the clock counts down this frame.
    static func runs(_ m: Moment) -> Bool {
        guard m.hasClock, !m.isOver, !m.lensOn, !m.isSolving else { return false }
        switch m.stage {
        case .aiming: return m.tableAtRest
        case .shooting: return m.playingNewGround
        // A ruling or hand-over card is the app talking, and handing the device over is something a real table
        // never needs; neither is playing time.
        case .betweenShots: return false
        }
    }

    /// The longest single frame the clock will count. ShowpieceModel.advance is called once a display frame (a 60th
    /// or 120th of a second); a gap longer than a quarter of a second means the app was held up or sent to the
    /// background, and that time was not spent at the table.
    static let longestFrame = 0.25

    /// The seconds one frame takes off the clock (never negative, never more than longestFrame).
    static func seconds(forFrame raw: Double) -> Double { min(max(raw, 0), longestFrame) }

    /// The clock after `seconds` more have run, never below zero.
    static func ticked(_ remaining: Double, by seconds: Double) -> Double { max(0, remaining - max(0, seconds)) }

    /// The whole seconds shown: counted up, so the clock reads 15:00 until a full second has gone and only reads
    /// 0:00 when time is really up.
    static func shownSeconds(_ remaining: Double) -> Int { Int(max(0, remaining).rounded(.up)) }
}

// MARK: What a shot scored

enum TablePoints {
    /// One line of the points-explained card. Points are whole numbers as the rules count them.
    enum Line: Equatable {
        /// Five-pin: white pins down (count) and what they scored together.
        case whitePins(count: Int, points: Int)
        /// Five-pin: the red pin down with other pins.
        case redPin(points: Int)
        /// Five-pin: the red pin the only pin down, which pays more.
        case redPinAlone(points: Int)
        /// Five-pin: the other player's ball touched the red ball.
        case redBallHit(points: Int)
        /// Five-pin: a foul gave the shot's points to `to`; `raisedToMinimum` when the shot made less than the
        /// minimum a foul gives.
        case foulPoints(to: PlayerID, points: Int, raisedToMinimum: Bool)
        /// Bar billiards: one ball dropped in a hole worth `holeValue`; `points` is what it scored (the red double).
        case drop(ball: Int, holeValue: Int, points: Int, isRed: Bool)
        /// Bar billiards: the played ball hit nothing, so nothing scores.
        case missedEverything
        /// Bar billiards: the white peg went down and the break's points (`points`) are lost.
        case breakLost(points: Int)
        /// Bar billiards: the black peg went down and the whole score (`points`) is lost.
        case scoreLost(points: Int)
        /// Bar billiards: the break goes on with this many points so far.
        case breakSoFar(points: Int)
        /// Bar billiards: the break is over, having made this many points.
        case breakEnded(points: Int)
        /// Nothing scored on this shot.
        case nothingScored
    }

    /// The lines for one five-pin shot, from what the recording showed: the pins down, whether the other player's
    /// ball touched the red, and the ruling (which says whether it was a foul and who got the points).
    static func fivePin(pinsDown pins: Set<Int>, targetHitRed: Bool, ruling r: Ruling) -> [Line] {
        var made: [Line] = []
        let whites = pins.subtracting([FivePinRules.redPin]).count
        if whites > 0 { made.append(.whitePins(count: whites, points: whites * FivePinRules.whitePinPoints)) }
        if pins.contains(FivePinRules.redPin) {
            made.append(pins.count == 1 ? .redPinAlone(points: FivePinRules.redPinAlonePoints)
                                        : .redPin(points: FivePinRules.redPinPoints))
        }
        if targetHitRed { made.append(.redBallHit(points: FivePinRules.redBallPoints)) }
        let total = FivePinRules.pinPoints(pins) + (targetHitRed ? FivePinRules.redBallPoints : 0)
        guard r.fouled else { return made.isEmpty ? [.nothingScored] : made }
        // A foul: the same lines (what the shot made), then who receives them. The receiver is whoever the ruling
        // paid; FivePinRules pays exactly one seat on a foul.
        let paid = r.points.enumerated().first { $0.element > 0 }
        guard let seat = paid?.offset, let awarded = paid?.element else { return made }
        return made + [.foulPoints(to: PlayerID(seat), points: awarded, raisedToMinimum: total < awarded)]
    }

    /// The lines for one bar-billiards shot. `drops` are the balls that dropped this shot with their hole (bed hole
    /// index, the order of BarBilliardsRules.holeValues), already limited to balls that were in the game; `hit` is
    /// whether the played ball touched another ball; `breakBefore` and `breakAfter` are MatchState.breakPoints before
    /// the shot and after the ruling was applied (BarBilliardsRules.applying sets it to zero when the break ends).
    static func barBilliards(drops: [(ball: Int, hole: Int)], hit: Bool, ruling r: Ruling, breakBefore: Int,
                             breakAfter: Int?) -> [Line] {
        let seat = r.shooter.index
        let change = r.points.indices.contains(seat) ? r.points[seat] : 0
        // The pegs first: a peg down scores nothing for the shot, whatever dropped (rule 5 before rule 3). The ruling
        // already holds the loss as a negative change, so the line shows it as a positive number lost.
        if r.reasons.contains(.blackPegDown) { return [.scoreLost(points: max(0, -change))] }
        if r.reasons.contains(.whitePegDown) { return [.breakLost(points: max(0, -change))] }
        var out: [Line] = []
        if !hit {
            out.append(.missedEverything)
        } else {
            for d in drops where BarBilliardsRules.holeValues.indices.contains(d.hole) {
                let value = BarBilliardsRules.holeValues[d.hole]
                let isRed = d.ball == BarBilliardsRules.redBall
                out.append(.drop(ball: d.ball, holeValue: value,
                                 points: isRed ? value * BarBilliardsRules.redMultiplier : value, isRed: isRed))
            }
            if out.isEmpty { out.append(.nothingScored) }
        }
        // Every hole is worth at least ten, so a break that goes on always holds points: a positive breakAfter means it
        // goes on, zero (or none) means it ended, with what it held before plus this shot.
        if let b = breakAfter, b > 0 {
            out.append(.breakSoFar(points: b))
        } else {
            out.append(.breakEnded(points: breakBefore + max(0, change)))
        }
        return out
    }

    /// The lines for a shot of any game: five-pin and bar billiards explain their points, every other game has none.
    /// `before` is the state the shot was played in, `after` the state once the ruling was applied.
    static func lines(for facts: ShotFacts, ruling: Ruling, before: MatchState, after: MatchState,
                      rules: any MatchRules) -> [Line] {
        switch rules {
        case let five as FivePinRules:
            let target = five.targetBall(for: ruling.shooter)
            return fivePin(pinsDown: Set(facts.pinsDown.map(\.pin)), targetHitRed: facts.touched(target, FivePinRules.redBall),
                           ruling: ruling)
        case is BarBilliardsRules:
            let inGame = Set(before.ballsLeft)
            let drops = facts.holeDrops.filter { inGame.contains($0.ball) }.map { (ball: $0.ball, hole: $0.hole) }
            return barBilliards(drops: drops, hit: facts.firstContact != nil, ruling: ruling,
                                breakBefore: before.breakPoints ?? 0, breakAfter: after.breakPoints)
        default:
            return []
        }
    }
}

// MARK: The single-player best score

/// Bar billiards played alone keeps the best final score on this device.
enum BarBilliardsBest {
    /// UserDefaults key for the best final score of a one-player bar-billiards game.
    static let storageKey = "barBilliardsBestScore"

    /// What a finished one-player game did to the best score.
    enum Outcome: Equatable {
        /// No game had been finished before: this score is the first best.
        case first(score: Int)
        /// A new best, beating `previous`.
        case newBest(score: Int, previous: Int)
        /// Not a new best; `best` still stands.
        case notBest(score: Int, best: Int)
    }

    /// The best score so far, nil before any one-player game has been finished.
    static func best(in defaults: UserDefaults = .standard) -> Int? {
        defaults.object(forKey: storageKey) == nil ? nil : defaults.integer(forKey: storageKey)
    }

    /// Record a finished one-player game's score and say what it did. A tie with the best is not a new best.
    @discardableResult
    static func record(_ score: Int, in defaults: UserDefaults = .standard) -> Outcome {
        guard let previous = best(in: defaults) else {
            defaults.set(score, forKey: storageKey)
            return .first(score: score)
        }
        guard score > previous else { return .notBest(score: score, best: previous) }
        defaults.set(score, forKey: storageKey)
        return .newBest(score: score, previous: previous)
    }
}
