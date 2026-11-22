// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, items 4 and 45 of plans/21-Nov-2026-bugs-after-0-6-6-plan.md:
//          the result line no longer waits for the warm zone. It shows whenever the stroke changed what happened (the
//          first ball, a pot made or missed, the cue ball lost or kept, worked out by StrokeEffect) in either zone, and
//          says it plainly: "Your stroke turned the cue a little left. Played straight, the pot would have dropped.",
//          with why when the swing was past the calm zone. The drill's own line names the turn on every drifted stroke,
//          and says when a shot stays out of the record because no finger stroke played it.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 gaps, item 57: the power readout, the ball readout and the
//          spoken power take the cue the game picked for the shot (callers pass model.cueInHand) instead of the default
//          CueProfile.selected, so the word and the ball's speed match what the strike will really launch.)
// PURPOSE: The stroke in words (plans/21-Nov-2026-stroke-and-power-plan.md): the power readout as a swing with the ball
//          speed kept on hand, the result line when the stroke changed what happened ("Your stroke turned the cue a
//          little left. Played straight, the pot would have dropped."), the retry comparison's stroke sentence ("Your
//          stroke was straighter this time"), and the straight-stroke drill's verdicts and progress. Every sentence a
//          player reads is here, for the screen and VoiceOver alike.
// SRP/DRY check: Pass - checked PowerWords (the plain word, soft to hard, still comes from there and is decided by the
//          ball's speed, which its bands were written for), RetryWords (the comparison's outcome half is its own; this
//          file only adds the stroke half), StrokeEffect (decides whether the stroke changed what happened; this file
//          only words its answer) and ShowpieceModel.nudgeAim (its quarter-degree aim step sets "a little").
import Foundation

enum StrokeWords {
    // MARK: Power readout

    /// A metres-per-second number in the player's language, one decimal.
    private static func speed(_ v: Double) -> String { String(format: "%.1f", locale: Locale.current, v) }

    // The three readouts take the cue in hand (the caller passes model.cueInHand, the cue the game picked for this
    // shot): power is the swing, so the ball's speed, and the soft-to-hard word decided by it, depend on the cue's
    // weight. The swing itself does not: CueProfile.swing is in house-cue units on purpose, the same for every cue.
    // The cue has no default, so a new caller cannot quietly fall back to the wrong one.

    /// The power bar's readout: the word, then the swing. "firm · swing 2.6 m/s".
    static func readout(power: Double, racked: Bool, cue: CueProfile) -> String {
        let word = PowerWords.word(speed: cue.launchSpeed(forPower: power), racked: racked)
        return String(localized: "\(word) · swing \(speed(CueProfile.swing(forPower: power))) m/s")
    }

    /// The ball's speed for those who want it, as the fine-controls slider shows it. "firm · ball 3.4 m/s".
    static func ballReadout(power: Double, racked: Bool, cue: CueProfile) -> String {
        let ball = cue.launchSpeed(forPower: power)
        return String(localized: "\(PowerWords.word(speed: ball, racked: racked)) · ball \(speed(ball)) m/s")
    }

    /// What VoiceOver says for the power bar: the word, the swing, the ball's speed, and whether it is past the calm
    /// zone.
    static func spoken(power: Double, racked: Bool, warm: Bool, cue: CueProfile) -> String {
        let ball = cue.launchSpeed(forPower: power)
        let word = PowerWords.word(speed: ball, racked: racked)
        let base = String(localized: "\(word), swing \(speed(CueProfile.swing(forPower: power))) metres per second, ball \(speed(ball)) metres per second")
        return warm ? base + ", " + String(localized: "past the calm zone") : base
    }

    // MARK: The result line

    /// Radians: a turn smaller than this is "a little". Two of the aim's quarter-degree steps (ShowpieceModel.nudgeAim):
    /// a turn a nudge or two of the aim would put back.
    static let bigTurn = 0.5 * Double.pi / 180

    /// Which way and how far the stroke turned the cue, or nil for no turn. The tip and the aim always drift the same
    /// way (the cue turns about the bridge), so one side is named; a positive aim error is counter-clockwise on the
    /// table plan, the shooter's left.
    static func turnLine(_ d: StrokeDelivery) -> String? {
        guard !d.isZero else { return nil }
        let left = d.aimError > 0 || (d.aimError == 0 && d.tipSideError < 0)
        let little = abs(d.aimError) < bigTurn
        switch (left, little) {
        case (true, true): return String(localized: "Your stroke turned the cue a little left.")
        case (false, true): return String(localized: "Your stroke turned the cue a little right.")
        case (true, false): return String(localized: "Your stroke turned the cue left.")
        case (false, false): return String(localized: "Your stroke turned the cue right.")
        }
    }

    /// What the turn changed, said as the shot that was aimed. Nil for the miscue, which has its own whole line.
    static func consequence(_ change: StrokeEffect.Change) -> String? {
        switch change {
        case .miscue: return nil
        case .firstBall: return String(localized: "Played straight, it would have hit a different ball first.")
        case .potMissed: return String(localized: "Played straight, the pot would have dropped.")
        case .scratched: return String(localized: "Played straight, the cue ball would have stayed on the table.")
        case .potMade: return String(localized: "Played straight, that ball would have stayed up.")
        case .scratchAvoided: return String(localized: "Played straight, the cue ball would have gone in.")
        }
    }

    /// Why the stroke wandered as much as it did, when the swing was past the calm zone; nil inside it.
    static func warmReason(_ d: StrokeDelivery) -> String? {
        if d.fullPower && d.warm { return String(localized: "At full power every stroke wanders most.") }
        if d.warm { return String(localized: "Past the calm zone every stroke wanders more.") }
        return nil
    }

    /// The miscue the stroke made, said for the zone it was made in.
    private static func miscueLine(_ d: StrokeDelivery) -> String {
        if d.fullPower && d.warm { return String(localized: "Full power: the tip slid off the ball.") }
        if d.warm { return String(localized: "Swinging hard: the tip slid off the ball.") }
        return String(localized: "Your stroke slid the tip off the ball.")
    }

    /// The whole line for a stroke that changed what happened: the turn, what the aimed shot would have done, and why
    /// when the swing was hard. Sentences are whole and joined, so each translates on its own.
    static func resultLine(_ d: StrokeDelivery, change: StrokeEffect.Change) -> String {
        if change == .miscue { return miscueLine(d) }
        return [turnLine(d), consequence(change), warmReason(d)].compactMap { $0 }.joined(separator: " ")
    }

    /// The result line for an attempt on screen, or nil when its stroke changed nothing a player would see (or that is
    /// still being worked out). Asks StrokeEffects for the answer when it is not known yet.
    @MainActor
    static func resultLine(for attempt: ShotAttempt?) -> String? {
        guard let attempt, let d = attempt.stroke, let change = StrokeEffects.shared.change(for: attempt) else {
            return nil
        }
        return resultLine(d, change: change)
    }

    /// The result line for the shot whose delivery this is (the spoken summary holds the delivery, not the attempt):
    /// the same words the card shows, once the answer is known.
    @MainActor
    static func resultLine(_ d: StrokeDelivery?) -> String? {
        guard let d, let change = StrokeEffects.shared.change(for: d) else { return nil }
        return resultLine(d, change: change)
    }

    /// The drill's own line under its verdict: the drill is about the turn itself, so every drifted stroke names it
    /// (and why, past the calm zone), whatever it changed. Nil for a stroke that did not turn the cue.
    static func drillLine(_ d: StrokeDelivery?) -> String? {
        guard let d, !d.isZero else { return nil }
        if d.pushedPastGrip { return miscueLine(d) }
        return [turnLine(d), warmReason(d)].compactMap { $0 }.joined(separator: " ")
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

    /// The drill measures a finger stroke; said on its card before the first stroke.
    static var drillMeasuresFinger: String {
        String(localized: "It measures a finger stroke on the screen. A shot played another way shows where the ball went but stays out of your record.")
    }

    /// Under the verdict of a drill shot played with no finger stroke (Shoot, a key, a controller, VoiceOver).
    static var notCounted: String {
        String(localized: "Played without a finger stroke, so this one stays out of your record.")
    }
}
