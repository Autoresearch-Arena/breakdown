// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The reach ladder in words (App/Stroke/Reach.swift): the stance card's one plain line for each rung ("Stretch:
//          one foot off the floor"), the raised-cue line ("Cue raised over the 5"), the bridge's length as the fine
//          controls read it ("20 cm, automatic bridge"), and the retry comparison's sentences when the stance or the
//          bridge changed between tries. Every sentence a player reads or hears about reach is here, for the screen and
//          VoiceOver alike.
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 equipment, plan item 57: cueLine, the stance card's one-line
//          indicator naming the cue the game picked for the shot and why.)
// SRP/DRY check: Pass - checked StrokeWords (its distance() formats the bridge's length, reused, not copied),
//          TableGameWords.ball (names the ball the cue is raised over, so other tables' balls read as they do elsewhere)
//          and RetryWords / ShotComparison (they decide when a setup sentence is said; this file only words it).
import BreakdownRules
import Foundation

enum StanceWords {
    // MARK: The stance card

    /// The plain line for a rung of the ladder.
    static func rungLine(_ rung: Stance.Rung) -> String {
        switch rung {
        case .normal: return String(localized: "Normal stance")
        case .stretch: return String(localized: "Stretch: one foot off the floor")
        case .behindTheBack: return String(localized: "Behind the back")
        case .sittingOnRail: return String(localized: "Sitting on the rail")
        case .rest: return String(localized: "Rest: the cue ball is out of reach")
        }
    }

    /// The raised-cue line, naming the ball as the table's game names it ("Cue raised over the 5", "over the red").
    /// Free play, trick shots and lessons are pool balls, named by number.
    static func raisedLine(over ball: Int, kind: MatchKind?) -> String {
        String(localized: "Cue raised over \(TableGameWords.ball(ball, kind: kind ?? .eightBall))")
    }

    /// The stance card's indicator for the automatic cue pick (plan item 57): which cue the game picked and why, in
    /// one line, so a player never wonders why the cue in the picture changed. Nil for the house cue on an ordinary
    /// shot, which needs no word. The "same swing" wording is the physics the pick changes: power is swing speed, so
    /// a heavier cue sends the ball faster and a lighter one slower at the same pull.
    static func cueLine(_ choice: CueChoice) -> String? {
        switch choice.reason {
        case .standard: return nil
        case .breakShot: return String(localized: "Break cue picked: heavier, so the same swing hits harder")
        case .jump: return String(localized: "Jump cue picked: short and light, for a steep stab")
        case .steepMasse: return String(localized: "Massé cue picked: short and heavy, steady for a steep curve")
        }
    }

    /// Every line a stance has to say: its rung unless it is a square stance, then the raised cue if any. Empty for a
    /// square stance with a clear path (the card stays away).
    static func lines(_ s: Stance, kind: MatchKind?) -> [String] {
        var out: [String] = []
        if s.rung != .normal { out.append(rungLine(s.rung)) }
        if let ball = s.raisedOver { out.append(raisedLine(over: ball, kind: kind)) }
        return out
    }

    /// One line for a whole stance, the square one included ("Normal stance"), for the retry comparison.
    static func summary(_ s: Stance, kind: MatchKind?) -> String {
        let said = lines(s, kind: kind)
        return said.isEmpty ? rungLine(.normal) : said.joined(separator: " · ")
    }

    // MARK: The bridge's length

    /// Where the bridge's length comes from.
    enum BridgeSource { case automatic, finger, rest }

    /// The fine controls' bridge readout, also what VoiceOver says for it: "20 cm, automatic bridge".
    static func bridgeReadout(length: Double, source: BridgeSource) -> String {
        let distance = StrokeWords.distance(length)
        switch source {
        case .automatic: return String(localized: "\(distance), automatic bridge")
        case .finger: return String(localized: "\(distance), your bridge finger")
        case .rest: return String(localized: "\(distance), the rest")
        }
    }

    // MARK: The retry comparison

    /// The setup's changed parts, as names for a list ("your stance", "your bridge"): empty when nothing changed.
    static func changedNames(_ setup: RetryComparison.SetupChange?) -> [String] {
        guard let setup else { return [] }
        var names: [String] = []
        if setup.stanceChanged { names.append(String(localized: "your stance")) }
        if setup.bridgeChanged { names.append(String(localized: "your bridge")) }
        return names
    }

    /// The facts of the change, one sentence each, never saying what caused the outcome: which stance each try was
    /// played from, and which way the bridge hand moved.
    static func details(_ setup: RetryComparison.SetupChange?) -> [String] {
        guard let setup else { return [] }
        var out: [String] = []
        if setup.stanceChanged {
            out.append(String(localized: "Stance this time: \(summary(setup.stanceAfter, kind: nil)) (last time: \(summary(setup.stanceBefore, kind: nil)))."))
        }
        if setup.bridgeChanged {
            out.append(setup.bridgeAfter > setup.bridgeBefore
                       ? String(localized: "Your bridge hand was further from the cue ball this time.")
                       : String(localized: "Your bridge hand was closer to the cue ball this time."))
        }
        return out
    }

    /// The card's sentence when no setting moved but the setup did: "You changed your stance, and this time the 5 went
    /// in." With one change it is named beside the outcome, as a single changed setting is; with more than one (the
    /// stance and the bridge, or either with a different stroke) the comparison's own several-changes sentence says
    /// that this alone cannot tell which one did it. Nil when the setup did not change.
    static func setupOnly(_ setup: RetryComparison.SetupChange?, strokeChanged: Bool, outcome: String) -> String? {
        let names = changedNames(setup)
        guard !names.isEmpty else { return nil }
        if names.count == 1 && !strokeChanged {
            return String(localized: "You changed \(names[0]), and \(outcome).")
        }
        let all = (names + (strokeChanged ? [String(localized: "your stroke")] : [])).formatted(.list(type: .and))
        return String(localized: "You changed \(all), and \(outcome). With several changes at once, this alone can't say which one did it.")
    }
}
