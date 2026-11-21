// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Every word a match says, in one place. The rules (package module BreakdownRules) speak only in codes:
//          MatchFoul, RulingReason, MatchEndReason, MatchChoice, BallInHand. This file turns them into plain sentences
//          a player reads after each shot ("Foul: the cue ball hit the 11 first. Ball in hand for Sam."), the game
//          names, the call line and the hand-over line. Everything goes through String(localized:) so the string
//          catalog collects it; numbers and names are passed in as finished strings or whole numbers so every
//          language can order the sentence its own way.
//          Read by MatchViews (the banner and the cards) and CallControl. It reads nothing itself: the caller hands
//          in the ruling, the state, the names and what the recording showed (balls pocketed, the first ball hit).
// SRP/DRY check: Pass - checked EightBallTypes.swift (EightBallGroup.title, EightBallPocket.title are reused here, not
//          repeated) and EightBallFoul.title (short labels for the puzzle's scorecard; a match needs whole sentences
//          naming the ball, so these are separate words for a different job).
import BreakdownRules
import Foundation

enum MatchWords {
    // MARK: Names

    static func title(_ kind: MatchKind) -> String {
        switch kind {
        case .eightBall: return String(localized: "Eight-ball")
        case .nineBall: return String(localized: "Nine-ball")
        case .bumperPool: return String(localized: "Bumper pool")
        case .fivePin: return String(localized: "Five-pin")
        case .barBilliards: return String(localized: "Bar billiards")
        }
    }

    /// The name a seat shows, falling back to "Player 2" for a seat the names list does not cover.
    static func name(_ player: PlayerID, in names: [String]) -> String {
        names.indices.contains(player.index) && !names[player.index].isEmpty
            ? names[player.index] : defaultName(player)
    }

    static func defaultName(_ player: PlayerID) -> String { String(localized: "Player \(player.index + 1)") }

    /// "the 3", "the 3 and the 11", in the player's language.
    static func balls(_ numbers: [Int]) -> String {
        numbers.map { String(localized: "the \($0)") }.formatted(.list(type: .and))
    }

    // MARK: The call

    static func callLine(_ call: EightBallCall) -> String {
        switch call {
        case .ball(let b, let p): return String(localized: "Called: the \(b), \(p.title).")
        case .safety: return String(localized: "Called: Safety.")
        }
    }

    // MARK: The banner

    static func toShoot(_ name: String, isBreak: Bool) -> String {
        isBreak ? String(localized: "\(name) to break") : String(localized: "\(name) to shoot")
    }

    /// Nine-ball: the lowest ball on the table is the one to hit first.
    static func hitFirst(_ ball: Int) -> String { String(localized: "Hit the \(ball) first") }

    static func groupLine(_ group: EightBallGroup?, left: Int, tableOpen: Bool) -> String {
        guard let group else { return tableOpen ? String(localized: "Table open") : "" }
        return left == 0 ? String(localized: "\(group.title): on the 8")
                         : String(localized: "\(group.title): \(left) left")
    }

    // MARK: Fouls

    /// One foul as the end of "Foul: ...". `firstBall` is the ball the cue ball touched first, when the recording
    /// has one, so a wrong-ball foul can name it.
    static func foul(_ f: MatchFoul, firstBall: Int?) -> String {
        switch f {
        case .scratch: return String(localized: "the cue ball went in a pocket or off the table")
        case .wrongBallFirst:
            if let b = firstBall { return String(localized: "the cue ball hit the \(b) first") }
            return String(localized: "the cue ball hit the wrong ball first")
        case .noBallHit: return String(localized: "the cue ball touched no ball")
        case .noRailAfterContact: return String(localized: "no ball reached a rail after the hit")
        case .objectBallOffTable: return String(localized: "a ball left the table")
        case .cueOrBridgeTouchedBall: return String(localized: "the cue or the bridge touched a ball")
        case .doubleHit: return String(localized: "the cue struck the cue ball twice")
        case .illegalJump: return String(localized: "the cue ball was scooped over a ball")
        case .wrongCup: return String(localized: "a ball dropped in the other player's cup")
        case .ownBallKnockedPins: return String(localized: "your own ball knocked pins down")
        // The table rules may append fouls; until this file names one, the card still says a foul happened.
        @unknown default: return String(localized: "a foul")
        }
    }

    // MARK: The ruling

    /// What the next shooter may do with the cue ball, with their name.
    static func ballInHand(_ kind: BallInHand, for name: String) -> String? {
        switch kind {
        case .none: return nil
        case .anywhere: return String(localized: "Ball in hand for \(name).")
        case .behindHeadLine: return String(localized: "Ball in hand behind the head line for \(name).")
        }
    }

    /// The ruling card's sentences, in order: what happened, then what follows.
    /// - Parameters:
    ///   - pocketed: object balls that dropped on this shot (from the recording).
    ///   - firstBall: the ball the shooter's cue ball touched first, or nil.
    static func sentences(for r: Ruling, names: [String], pocketed: [Int], firstBall: Int?) -> [String] {
        let shooter = name(r.shooter, in: names)
        let next = name(r.nextShooter, in: names)
        var out: [String] = []
        if r.fouled {
            let what = r.fouls.map { foul($0, firstBall: firstBall) }.formatted(.list(type: .and))
            out.append(String(localized: "Foul: \(what)."))
        }
        for reason in r.reasons {
            switch reason {
            case .legalPot:
                if !pocketed.isEmpty { out.append(String(localized: "\(shooter) pocketed \(balls(pocketed)).")) }
            case .noLegalPot:
                out.append(pocketed.isEmpty ? String(localized: "Nothing went down.")
                                            : String(localized: "Went down without keeping the turn: \(balls(pocketed))."))
            case .calledBallMissed: out.append(String(localized: "The called ball did not go in the called pocket."))
            case .foul: break   // said above, with the fouls named
            case .tableOpen: out.append(String(localized: "The table is still open."))
            case .groupsAssigned:
                if let g = r.assignedGroup {
                    out.append(g == .solids ? String(localized: "\(shooter) has the solids.")
                                            : String(localized: "\(shooter) has the stripes."))
                }
            case .breakLegal: out.append(String(localized: "A legal break."))
            case .breakIllegal:
                out.append(String(localized: "The break pocketed nothing and drove too few balls to a rail."))
            case .scratchOnBreak: out.append(String(localized: "Scratch on the break."))
            case .eightOnBreak: out.append(String(localized: "The 8 went down on the break."))
            case .ballSpotted:
                if !r.ballsToSpot.isEmpty {
                    out.append(String(localized: "Back on the foot spot: \(balls(r.ballsToSpot))."))
                }
            case .foulWarning: out.append(String(localized: "\(shooter) has fouled twice in a row. A third foul loses the game."))
            case .pointsScored:
                for (seat, p) in r.points.enumerated() where p != 0 {
                    out.append(String(localized: "\(name(PlayerID(seat), in: names)) scores \(p)."))
                }
            case .pinsReset: out.append(String(localized: "The pins are stood up again."))
            case .ballsReturned: out.append(String(localized: "Balls come back to be played again."))
            case .whitePegDown: out.append(String(localized: "The white peg went down: this turn's points are lost."))
            case .blackPegDown: out.append(String(localized: "The black peg went down: the whole score is lost."))
            case .timeUp: out.append(String(localized: "Time is up."))
            case .choiceAnswered, .gameOver: break   // the choice and the result have their own lines
            case .rerack: out.append(String(localized: "The balls are racked again."))
            // Reasons appended later by the table rules say nothing here until they are given words.
            @unknown default: break
            }
        }
        // What follows, unless the game is over (the result card says that).
        if r.result == nil {
            if let hand = ballInHand(r.ballInHand, for: next) {
                out.append(hand)
            } else if r.turnPasses {
                out.append(String(localized: "\(next) to shoot."))
            } else if r.choice == nil {
                out.append(String(localized: "\(shooter) shoots again."))
            }
        }
        return out
    }

    // MARK: Choices

    static func choicePrompt(_ c: PendingChoice, names: [String]) -> String {
        let who = name(c.chooser, in: names)
        switch c.choice {
        case .acceptTableOrRerack: return String(localized: "\(who): take the table as it lies, or have it racked again?")
        case .spotEightOrRerack: return String(localized: "\(who): put the 8 back on its spot, or rack again?")
        }
    }

    static func answer(_ a: MatchChoiceAnswer) -> String {
        switch a {
        case .acceptTable: return String(localized: "Take the table")
        case .spotEight: return String(localized: "Spot the 8")
        case .rerack: return String(localized: "Rack again")
        }
    }

    // MARK: The end

    /// The result card's title: who won, or plain "Game over" when the game names no winner.
    static func resultTitle(_ r: MatchResult, names: [String]) -> String {
        guard let w = r.winner else { return String(localized: "Game over") }
        return String(localized: "\(name(w, in: names)) wins!")
    }

    /// Why the game ended. `shooter` is whoever took the last shot: for a loss on the 8 it is the player who lost.
    static func endReason(_ r: MatchResult, shooter: PlayerID?, names: [String]) -> String {
        let who = shooter.map { name($0, in: names) } ?? ""
        let winner = r.winner.map { name($0, in: names) } ?? ""
        switch r.reason {
        case .eightBallPocketed: return String(localized: "\(winner) pocketed the 8 in the called pocket.")
        case .eightOnFoul: return String(localized: "\(who) pocketed the 8 on a foul.")
        case .eightEarly: return String(localized: "\(who) pocketed the 8 before clearing their group.")
        case .eightWrongPocket: return String(localized: "\(who) sank the 8 in a pocket that was not called.")
        case .eightOffTable: return String(localized: "\(who) knocked the 8 off the table.")
        case .nineBallPocketed: return String(localized: "\(winner) pocketed the 9.")
        case .threeConsecutiveFouls: return String(localized: "\(who) fouled three times in a row.")
        case .allBallsSunk: return String(localized: "\(winner) sank every ball of their side.")
        case .targetScoreReached: return String(localized: "\(winner) reached the target score.")
        case .timeExpired: return String(localized: "Time ran out.")
        case .conceded: return String(localized: "The game was ended early.")
        @unknown default: return ""
        }
    }

    // MARK: Between turns

    static func handOver(to name: String) -> String { String(localized: "Pass the device to \(name).") }
}
