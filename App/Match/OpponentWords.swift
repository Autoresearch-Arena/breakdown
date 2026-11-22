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
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 16, 17 and 18: "Lining up..." while the computer
//          swings its aim and draws the cue back; "Why that shot" for each level's own way of choosing (easy goes for
//          the pot that looks easiest without planning the cue ball, and a plain hit when no pot is on is no longer
//          called a safety); the record as wins and losses against one level at one game.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 table-opponent stream: "Why that shot" for the computer at
//          bumper pool and five-pin. A cup shot says which of its balls it aimed for and its route (straight, off a
//          cushion, off a bumper, or both); a roll toward its cup says no cup shot was likely enough; a five-pin
//          stroke says the points it played for on an average stroke and struck perfectly, whether its ball went off
//          a cushion first, how far its aim could have been off and still scored, and (hard) that it kept its ball
//          away from the pins; easy's five-pin stroke says it aimed by eye; a stroke with nothing on says it gave away
//          as little as it could. None of them names a pocket. Counts are whole numbers (Int), so the catalog keys
//          carry %lld; degrees arrive as finished strings (%@), as before.)
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
    /// While the computer's aim swings to its choice and its cue draws back, before it strikes.
    static var liningUp: String { String(localized: "Lining up its shot…") }
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
            if shot.level == .easy {
                // Easy picks by eye and never plans the cue ball (MatchOpponent's level styles).
                lines.append(String(localized: "It picked the pot that looked easiest and did not plan where the cue ball would stop."))
            }
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
        case .hit(let ball):
            if plan.placement != nil {
                lines.append(String(localized: "It placed the cue ball first."))
            }
            if let ball {
                lines.append(String(localized: "No pot was on, so it simply hit the \(ball), the nearest ball it was allowed to hit."))
            } else {
                lines.append(String(localized: "No pot was on, so it simply hit the nearest ball it was allowed to hit."))
            }
        case .cup(_, let marked, let route):
            // Bumper pool (BumperPoolPlanner): its own ball into its own cup. Cups have no names, so none is said.
            lines.append(marked ? String(localized: "It aimed to sink its marked ball in its cup.")
                                : String(localized: "It aimed to sink one of its balls in its cup."))
            lines.append(cupRoute(route))
            if let w = plan.window {
                lines.append(String(localized: "Its aim could have been off by \(degrees(w / 2)) degrees either way and still sunk it."))
            }
        case .advance:
            lines.append(String(localized: "No cup shot was likely enough, so it rolled its ball nearer its cup."))
        case .pins(let expected, let clean, let kick):
            if shot.level == .easy {
                // Easy's five-pin stroke is a ghost-ball aim with no solves (FivePinPlanner.easyPlan): no figures.
                lines.append(String(localized: "It sent your ball at the pins by eye, without working out the points."))
            } else {
                // Whole points keep the key to %lld; no count sits right before a noun, so "1" reads as well as "6"
                // with no plural forms. A stroke only gets .pins when the expected points are above zero, so the
                // average is shown as at least 1.
                let about = max(1, Int(expected.rounded()))
                lines.append(String(localized: "It played for the pins. Points on an average stroke of its hand: about \(about). Struck perfectly: \(clean)."))
            }
            if kick {
                lines.append(String(localized: "It sent its ball off a cushion first to reach yours."))
            }
            if let w = plan.window {
                // Nothing is sunk at five-pin, so the pool line's "still sunk it" becomes "still scored".
                lines.append(String(localized: "Its aim could have been off by \(degrees(w / 2)) degrees either way and still scored."))
            }
            if plan.leavesNextShot {
                // Hard only (FivePinPlanner): its value kept its own ball away from the castle.
                lines.append(String(localized: "It also kept its ball away from the pins, so you have less to aim at."))
            }
        case .concede:
            lines.append(String(localized: "Nothing scored often enough, so it touched your ball softly to give away as little as possible."))
        }
        let n = shot.noise
        let speed = (abs(n.speedShare) * 100).formatted(.number.precision(.fractionLength(0)))
        // The closing line is the same on every table: what the computer's hand actually did on the stroke.
        lines.append(String(localized: "On the stroke its aim drifted \(degrees(n.aimDegrees)) degrees and its speed \(speed) percent (\(shot.level.title) level)."))
        return lines
    }

    /// Bumper pool: how the cup shot reached the cup. Straight in reuses the pool line, word for word.
    private static func cupRoute(_ route: OpponentPlan.CupRoute) -> String {
        switch route {
        case .straight: return String(localized: "Straight in, no cushion.")
        case .cushion: return String(localized: "Off a cushion on the way.")
        case .bumper: return String(localized: "Off a bumper on the way.")
        case .cushionAndBumper: return String(localized: "Off cushions and bumpers on the way.")
        }
    }

    // MARK: The record

    /// The menu's short mark ("3/7") is shared with the other marks; this is what VoiceOver hears.
    static func recordSpoken(_ t: MatchTally) -> String {
        String(localized: "\(t.won) won of \(t.played) played")
    }

    /// One game against one level, as wins and losses ("3 won, 2 lost"), for the menu beside that game.
    static func record(won: Int, lost: Int) -> String {
        String(localized: "\(won) won, \(lost) lost")
    }

    /// The line under the level choice: this level's record against the computer.
    static func levelRecord(_ t: MatchTally, level: ComputerLevel) -> String {
        t.played == 0 ? String(localized: "No games against \(level.title) yet.")
                      : String(localized: "Against \(level.title): won \(t.won) of \(t.played).")
    }
}
