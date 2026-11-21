// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Every word the computer opponent and the match record say (plans/21-Nov-2026-rules-games-plan.md packages
//          5 and 6): the level names and their one-line descriptions, the computer's default name, "Thinking...", the
//          "Why that shot" lines (what it aimed for, straight in or off a cushion, how far its aim could have been off
//          and still made it, whether it played for its next shot or played safe, and what its hand actually did on
//          the stroke), and the record lines on the menu. Everything goes through String(localized:) so the string
//          catalog collects it; numbers arrive as finished strings formatted for the player's language, so every
//          language can order its own sentence.
//          Read by MatchViews (the match card) and TitleScreen (the Play list). Reads nothing itself: the caller hands
//          in the OpponentShot (App/Match/MatchOpponent.swift) or the MatchTally (App/Match/MatchRecord.swift).
// SRP/DRY check: Pass - checked MatchWords (the ruling, turn and call words stay there and are not repeated; pocket
//          names are EightBallPocket.title, reused) and TrickShotViews (its window words describe a player's own
//          settings, not a computer's choice).
import BreakdownRules
import Foundation

extension ComputerLevel {
    var title: String {
        switch self {
        case .easy: return String(localized: "Easy")
        case .medium: return String(localized: "Medium")
        case .hard: return String(localized: "Hard")
        }
    }

    /// One line on what playing this level is like.
    var line: String {
        switch self {
        case .easy: return String(localized: "A shaky cue: it often misses anything but the easy ones.")
        case .medium: return String(localized: "A steady club player who makes the open shots.")
        case .hard: return String(localized: "Rarely misses, and plays safe when it has nothing.")
        }
    }
}

enum OpponentWords {
    /// The computer's name in the turn banner; the level follows it so both players can see what they are up against.
    static func name(_ level: ComputerLevel) -> String { String(localized: "Computer (\(level.title))") }

    static var thinking: String { String(localized: "Thinking…") }
    static var whyThatShot: String { String(localized: "Why that shot") }

    /// A number of degrees for these lines: at most two decimals, in the player's language.
    private static func degrees(_ x: Double) -> String {
        abs(x).formatted(.number.precision(.fractionLength(0...2)))
    }

    /// "Why that shot": what the computer went for and why, in plain words, then what its hand did.
    static func why(_ shot: OpponentShot) -> [String] {
        var lines: [String] = []
        let plan = shot.plan
        switch plan.kind {
        case .breakShot:
            lines.append(String(localized: "The break: hard and straight at the front ball, to spread the rack."))
        case .pot(let ball, let pocket, let bankRail):
            if plan.placement != nil {
                lines.append(String(localized: "It placed the cue ball first, behind the easiest pot it could find."))
            }
            let place = EightBallPocket(rawValue: pocket)?.title ?? ""
            lines.append(String(localized: "It went for the \(ball): \(place)."))
            lines.append(bankRail == nil ? String(localized: "Straight in, no cushion.")
                                         : String(localized: "Off one cushion first, then into the pocket."))
            if let w = plan.window {
                lines.append(String(localized: "Its aim could have been off by \(degrees(w / 2)) degrees either way and still sunk it."))
            }
            if plan.leavesNextShot {
                lines.append(String(localized: "It also played for the cue ball to stop with a clear shot at its next ball."))
            }
        case .safety(let ball):
            if plan.placement != nil {
                lines.append(String(localized: "It placed the cue ball first."))
            }
            lines.append(String(localized: "No pot was wide enough for its aim, so it played safe."))
            if let ball {
                lines.append(String(localized: "It hit the \(ball) softly to hide the cue ball from your balls."))
            }
            if let left = plan.leftOpponent {
                lines.append(left <= 0 ? String(localized: "It meant to leave you no clear pot at all.")
                                       : String(localized: "It meant to leave you at most \(degrees(left / 2)) degrees of aim either way on your best pot."))
            }
        }
        let n = shot.noise
        let speed = (abs(n.speedShare) * 100).formatted(.number.precision(.fractionLength(0)))
        lines.append(String(localized: "On the stroke its aim drifted \(degrees(n.aimDegrees)) degrees and its speed \(speed) percent (\(shot.level.title) level)."))
        return lines
    }

    // MARK: The record

    /// The menu's short mark ("3/7") is shared with the other marks; this is what VoiceOver hears.
    static func recordSpoken(_ t: MatchTally) -> String {
        String(localized: "\(t.won) won of \(t.played) played")
    }

    /// The line under the level choice: this level's record against the computer.
    static func levelRecord(_ t: MatchTally, level: ComputerLevel) -> String {
        t.played == 0 ? String(localized: "No games against \(level.title) yet.")
                      : String(localized: "Against \(level.title): won \(t.won) of \(t.played).")
    }
}
