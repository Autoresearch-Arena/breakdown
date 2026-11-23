// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Power in plain words. A new player cannot read "3.4 m/s", so every place that shows the strike's power puts
//          one word beside the number: soft, medium, firm, hard, or break while the balls are racked. The number stays
//          for those who want it. Shaped like ShotPanel's tipWord / shownWord pair: powerWord returns a fixed
//          identifier (for comparisons and tests), shownWord turns it into the translated word the player reads, and
//          readout builds the "word · number" text the gauges show. Used by PowerGauge (AimGauges.swift) and the
//          power slider in the fine controls (ShotPanel.swift).
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// SRP/DRY check: Pass - checked ShotPanel (tip and side words, same pattern, kept separate because they describe the
//          tip, not the speed), AimGauges (the gauge that shows the number) and ShotAttempt (the retry comparison says
//          "harder" or "softer", a change, not a level). The bands live here only.
import Foundation

enum PowerWords {
    /// Fixed identifiers, never shown; shownWord gives the words.
    enum Level: String, CaseIterable {
        case soft, medium, firm, hard, breakShot
    }

    /// Upper edges of the bands, launch speed in metres per second. Why these numbers:
    /// on our cloth a centre-struck cue ball comes out of its skid at 5/7 of its launch speed and then slows at
    /// rolling resistance times g (0.01 x 9.81 m/s^2), so alone it rolls about 2.6 v^2 metres. Below 1.5 m/s that is
    /// at most about two lengths of the table: the touch range, where the authored massé (0.95) and stop shot (1.75,
    /// on the edge) live. 1.5 to 3 m/s is an ordinary pot with position (the cross-side bank, 2.8). 3 to 5 m/s is a
    /// driven shot that runs the cue ball several lengths (follow, draw and throw shots, 3.65 to 4.55). From 5 m/s up
    /// to the free-play limit of 8 is a power shot. A racked table is always a break: the break's own range starts at
    /// 7 m/s, so the word is decided by what is being played, not by the speed.
    static let softBelow = 1.5
    static let mediumBelow = 3.0
    static let firmBelow = 5.0

    static func level(speed: Double, racked: Bool) -> Level {
        if racked { return .breakShot }
        if speed < softBelow { return .soft }
        if speed < mediumBelow { return .medium }
        if speed < firmBelow { return .firm }
        return .hard
    }

    /// The translated word for a level, lower case, as it sits beside the number.
    static func shownWord(_ level: Level) -> String {
        switch level {
        case .soft: return String(localized: "soft")
        case .medium: return String(localized: "medium")
        case .firm: return String(localized: "firm")
        case .hard: return String(localized: "hard")
        case .breakShot: return String(localized: "break")
        }
    }

    static func word(speed: Double, racked: Bool) -> String { shownWord(level(speed: speed, racked: racked)) }

    /// "firm · 3.4 m/s": the word first, the number for those who want it, formatted for the player's language.
    static func readout(speed: Double, racked: Bool) -> String {
        let number = String(format: "%.1f", locale: AppLocale.numbers, speed)
        return String(localized: "\(word(speed: speed, racked: racked)) · \(number) m/s")
    }

    /// What VoiceOver says: "firm, 3.4 metres per second".
    static func spoken(speed: Double, racked: Bool) -> String {
        let number = String(format: "%.1f", locale: AppLocale.numbers, speed)
        return String(localized: "\(word(speed: speed, racked: racked)), \(number) metres per second")
    }
}
