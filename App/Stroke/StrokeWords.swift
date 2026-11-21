// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The stroke in words (plans/21-Nov-2026-stroke-and-power-plan.md): the power readout as a swing with the ball
//          speed kept on hand, the result line after a hard shot whose drift mattered ("Full power: the tip landed
//          left of where you aimed."), the retry comparison's stroke sentence ("Your stroke was straighter this
//          time"), and the straight-stroke drill's verdicts and progress. Every sentence a player reads is here, for
//          the screen and VoiceOver alike.
// SRP/DRY check: Pass - checked PowerWords (the plain word, soft to hard, still comes from there and is decided by the
//          ball's speed, which its bands were written for), RetryWords (the comparison's outcome half is its own; this
//          file only adds the stroke half) and ShotComparison.isDescribable (its 0.15 degree aim threshold is reused
//          for "the drift mattered").
import Foundation

enum StrokeWords {
    // MARK: Power readout

    /// A metres-per-second number in the player's language, one decimal.
    private static func speed(_ v: Double) -> String { String(format: "%.1f", locale: Locale.current, v) }

    /// The power bar's readout: the word, then the swing. "firm · swing 2.6 m/s".
    static func readout(power: Double, racked: Bool) -> String {
        let word = PowerWords.word(speed: CueProfile.selected.launchSpeed(forPower: power), racked: racked)
        return String(localized: "\(word) · swing \(speed(CueProfile.swing(forPower: power))) m/s")
    }

    /// The ball's speed for those who want it, as the fine-controls slider shows it. "firm · ball 3.4 m/s".
    static func ballReadout(power: Double, racked: Bool) -> String {
        let ball = CueProfile.selected.launchSpeed(forPower: power)
        return String(localized: "\(PowerWords.word(speed: ball, racked: racked)) · ball \(speed(ball)) m/s")
    }

    /// What VoiceOver says for the power bar: the word, the swing, the ball's speed, and whether it is past the calm
    /// zone.
    static func spoken(power: Double, racked: Bool, warm: Bool) -> String {
        let ball = CueProfile.selected.launchSpeed(forPower: power)
        let word = PowerWords.word(speed: ball, racked: racked)
        let base = String(localized: "\(word), swing \(speed(CueProfile.swing(forPower: power))) metres per second, ball \(speed(ball)) metres per second")
        return warm ? base + ", " + String(localized: "past the calm zone") : base
    }

    // MARK: The result line

    /// Smallest aim drift worth a sentence, radians: the 0.15 degrees the retry comparison already uses for "aimed a
    /// little to the left" (ShotComparison.isDescribable).
    static let aimWorthSaying = 0.15 * Double.pi / 180
    /// Smallest tip drift worth a sentence, metres: half the 2 mm that separates the tip words (ShotPanel.sideWord).
    static let tipWorthSaying = 0.001

    /// True when a hard shot's drift mattered: past the calm zone, and the aim or the tip moved enough to say, or the
    /// drift made a miscue.
    static func mattered(_ d: StrokeDelivery) -> Bool {
        d.warm && (d.pushedPastGrip || abs(d.aimError) >= aimWorthSaying || abs(d.tipSideError) >= tipWorthSaying)
    }

    /// The result line for a delivered strike, or nil when the drift did not matter. The tip and the aim always drift
    /// the same way (the cue turns about the bridge), so one side is named.
    static func resultLine(_ d: StrokeDelivery?) -> String? {
        guard let d, mattered(d) else { return nil }
        let left = d.tipSideError < 0 || (d.tipSideError == 0 && d.aimError > 0)
        switch (d.fullPower, d.pushedPastGrip, left) {
        case (true, true, _): return String(localized: "Full power: the tip slid off the ball.")
        case (true, false, true): return String(localized: "Full power: the tip landed left of where you aimed.")
        case (true, false, false): return String(localized: "Full power: the tip landed right of where you aimed.")
        case (false, true, _): return String(localized: "Swinging hard: the tip slid off the ball.")
        case (false, false, true): return String(localized: "Swinging hard: the tip landed left of where you aimed.")
        case (false, false, false): return String(localized: "Swinging hard: the tip landed right of where you aimed.")
        }
    }

    // MARK: The retry comparison

    /// The stroke half of a comparison: a sentence when the stroke changed enough to say.
    static func comparison(_ change: RetryComparison.StrokeChange?) -> String? {
        switch change {
        case .straighter: return String(localized: "Your stroke was straighter this time.")
        case .wilder: return String(localized: "Your stroke wandered more this time.")
        case nil: return nil
        }
    }

    /// The whole sentence when nothing but the stroke changed, joined to what happened differently.
    static func strokeOnly(_ change: RetryComparison.StrokeChange?, outcome: String) -> String {
        switch change {
        case .straighter: return String(localized: "Your stroke was straighter this time, and \(outcome).")
        case .wilder: return String(localized: "Your stroke wandered more this time, and \(outcome).")
        case nil: return String(localized: "Same settings, but the stroke was not quite the same, and \(outcome).")
        }
    }

    // MARK: The drill

    /// A distance on the cloth in the player's language: millimetres below ten centimetres, centimetres above.
    static func distance(_ metres: Double) -> String {
        let m = abs(metres)
        if m < 0.1 {
            return Measurement(value: (m * 1000).rounded(), unit: UnitLength.millimeters)
                .formatted(.measurement(width: .abbreviated, usage: .asProvided))
        }
        return Measurement(value: (m * 100).rounded(), unit: UnitLength.centimeters)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided))
    }

    static func verdict(_ r: StrokeDrill.Result) -> String {
        switch r {
        case .back(let off, let grade):
            switch grade {
            case .deadStraight: return String(localized: "Back within \(distance(off)) of the cue line: dead straight.")
            case .straight: return String(localized: "Back within \(distance(off)) of the cue line: straight.")
            case .offLine: return String(localized: "It came back \(distance(off)) off the cue line.")
            }
        case .short(let off):
            return String(localized: "It stopped \(distance(off)) off the cue line before coming all the way back.")
        case .noRail:
            return String(localized: "Not hard enough to reach the far rail.")
        case .dropped:
            return String(localized: "The cue ball dropped in a pocket.")
        }
    }
}
