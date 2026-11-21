// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Learn from a retry (plans/21-Nov-2026-learn-from-a-retry-plan.md, section 3), the view side.
//          RetryWords   - the one sentence a result card shows after a retry, written from the facts the model
//                         records (RetryComparison: which controls moved and which way, how far apart the two cue
//                         balls finished, which balls dropped each time, and a key saying which sentence fits). Five
//                         kinds, as the plan asks: an exact repeat; a change too small to describe ("both tries left
//                         the cue ball near the same spot"); one change, named with its direction; several changes,
//                         reported without claiming which one did it; and a literal sentence when the cue ball touched
//                         nothing. Only these claims are made, and each one is in the recording.
//          ContactButton - "See the contact": pauses the replay at the moment the cue ball first touched a ball
//                         (ShowpieceModel.seekToFirstContact), where the last try's faint trail and finish ring
//                         (GhostOverlay) sit beside the live balls. Shown only when the shot on screen touched a ball.
//                         With Reduce Motion it first turns the Ride camera off, so the jump is a cut and not a flight;
//                         VoiceOver hears where the replay stopped.
//          Used by the free-play comparison card (GhostOverlay.swift) and the trick-shot result card
//          (TrickShotViews.swift), which carries the sentence itself so only one result card is ever up.
// SRP/DRY check: Pass - checked ShotAttempt.swift (the model stream owns the facts and RetryComparison; this file only
//          words them) and ShotPanel.shownWord (spin words for the panel; these are whole sentences about a change).
import SwiftUI

enum RetryWords {
    /// Below this the two finishes count as the same spot: five centimetres, under one ball's width (5.7 cm), so a
    /// player looking at the table could not tell the two finishes apart.
    static let sameSpot = 0.05

    /// The card's one sentence.
    static func sentence(_ c: RetryComparison) -> String {
        switch c.key {
        case .exactRepeat:
            return String(localized: "Same shot, same result. The physics is exact, so nothing changes unless you do.")
        case .sameSpot:
            return String(localized: "Both tries left the cue ball near the same spot.")
        case .missedEverything:
            return String(localized: "This time the cue ball touched no ball.")
        case .oneChange(let control):
            let change = changeWords(control, c.inputChanges.first { $0.control == control })
            return String(localized: "You \(change), and \(outcome(c)).")
        case .severalChanges:
            let names = c.inputChanges.map { controlName($0.control) }.formatted(.list(type: .and))
            return String(localized: "You changed \(names), and \(outcome(c)). With several changes at once, this alone can't say which one did it.")
        }
    }

    /// What one control's change was, with its direction ("hit higher on the cue ball").
    private static func changeWords(_ control: RetryComparison.Control, _ change: RetryComparison.InputChange?) -> String {
        let up = (change.map { $0.after > $0.before }) ?? true
        switch control {
        // Aim is counter-clockwise on the table plan, which is to the shooter's left as they look down the cue.
        case .aim: return up ? String(localized: "aimed a little to the left") : String(localized: "aimed a little to the right")
        case .power: return up ? String(localized: "hit it harder") : String(localized: "hit it softer")
        case .tipUp: return up ? String(localized: "hit higher on the cue ball") : String(localized: "hit lower on the cue ball")
        case .tipSide: return up ? String(localized: "moved the tip to the right") : String(localized: "moved the tip to the left")
        case .elevation: return up ? String(localized: "raised the cue") : String(localized: "lowered the cue")
        }
    }

    private static func controlName(_ control: RetryComparison.Control) -> String {
        switch control {
        case .aim: return String(localized: "the aim")
        case .power: return String(localized: "the power")
        case .tipUp: return String(localized: "the tip height")
        case .tipSide: return String(localized: "the side spin")
        case .elevation: return String(localized: "the cue angle")
        }
    }

    /// What happened differently, as the second half of the sentence: the balls that dropped first, then the cue
    /// ball's finish.
    private static func outcome(_ c: RetryComparison) -> String {
        let before = Set(c.pottedBefore), now = Set(c.pottedNow)
        let gained = now.subtracting(before).sorted(), lost = before.subtracting(now).sorted()
        if !gained.isEmpty && lost.isEmpty { return String(localized: "this time \(MatchWords.balls(gained)) went in") }
        if !lost.isEmpty && gained.isEmpty { return String(localized: "this time \(MatchWords.balls(lost)) stayed up") }
        if !gained.isEmpty { return String(localized: "this time \(MatchWords.balls(gained)) went in instead of \(MatchWords.balls(lost))") }
        guard let shift = c.cueBallFinishShift else {
            return String(localized: "the cue ball went in a pocket on one of the tries")
        }
        if shift < sameSpot { return String(localized: "the cue ball finished near the same spot") }
        let distance = Measurement(value: (shift * 100).rounded(), unit: UnitLength.centimeters)
            .formatted(.measurement(width: .wide, usage: .asProvided))
        return String(localized: "the cue ball finished about \(distance) from where it stopped last time")
    }
}

/// "See the contact": pause the replay where the cue ball first touched a ball.
struct ContactButton: View {
    let model: ShowpieceModel
    /// Called after seeking, so a card can stay up while the replay sits at the contact.
    var onSeek: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if model.firstContactTime != nil {
            Button {
                // Reduce Motion: no camera flight to the moment; the Ride camera steps aside and the table view cuts.
                if reduceMotion && model.rideOn { model.setRide(false) }
                model.seekToFirstContact()
                onSeek()
                AccessibilityNotification.Announcement(
                    String(localized: "Paused where the cue ball first touched a ball. The faint line is your last try.")).post()
            } label: {
                Label(String(localized: "See the contact"), systemImage: "scope").labelStyle(.iconOnly)
                    .frame(minWidth: 30, minHeight: CallMetrics.buttonHeight)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(String(localized: "See the contact"))
            .accessibilityHint(String(localized: "Pauses the replay where the cue ball first touched a ball"))
        }
    }
}
