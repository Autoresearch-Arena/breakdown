// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream: when only the stroke changed (no setting moved) the
//          sentence says so, "Your stroke was straighter this time, and ..."; when settings moved too, the stroke's
//          sentence follows the card's own (StrokeWords).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (reach: a changed stance or bridge (RetryComparison.setup) is named.
//          With no setting moved it is the sentence's change ("You changed your stance, and ..."), or one of several;
//          with settings moved it joins the several-changes list, which never says which one did it; the stance each try
//          was played from follows as a plain fact (StanceWords).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md item 53: See the
//          contact shows its words where the row has room and has a symbol of its own (the crosshair was shared with
//          Aim at nearest ball and the Aim guide option); on arrival a line on screen says what to look at, "Stopped at
//          the first hit.", with "The faint ball is your last try." only when a last try is on the table
//          (ContactArrivalLine, shown with the cards while the replay stays stopped there).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hook, 0.7.0 item 47: See the contact's announcement goes through the one
//          speaker, ShotNarration.announce.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, Part 4 step 5: See the contact's action is one
//          function, ContactButton.seek, used by the button and by the small blurb button the upright phone's result
//          blurbs carry (ContactButton.blurbButton); ContactArrivalLine's "still at the contact" test is one function,
//          ContactArrivalLine.isShowing, read by the line and by ContactArrivalPhoneBlurb, the line as a blurb on the
//          phone held upright.)
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
//                         Its words show where the row has room, the symbol alone where it has not. With Reduce Motion
//                         it first turns the Ride camera off, so the jump is a cut and not a flight; VoiceOver hears
//                         where the replay stopped.
//          ContactArrivalLine - the line on screen after See the contact, with the cards (ShowpieceView, NotebookPanel):
//                         what the stopped replay shows. It stays while the replay sits at the contact and goes as soon
//                         as the replay moves on.
//          ContactArrivalPhoneBlurb - the same words as a docked blurb on the phone held upright (ShowpieceView's dock),
//                         shown and hidden by the same test; the shared line keeps serving the other layouts.
//          Used by the free-play comparison card (GhostOverlay.swift) and the trick-shot result card
//          (TrickShotViews.swift), which carries the sentence itself so only one result card is ever up.
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 3's leftover lint note: the card's corners and padding are Theme values (medium
//          corners, 12 point padding) instead of bare numbers.)
// SRP/DRY check: Pass - checked ShotAttempt.swift (the model stream owns the facts and RetryComparison; this file only
//          words them) and ShotPanel.shownWord (spin words for the panel; these are whole sentences about a change).
import SwiftUI

enum RetryWords {
    /// Below this the two finishes count as the same spot: five centimetres, under one ball's width (5.7 cm), so a
    /// player looking at the table could not tell the two finishes apart.
    static let sameSpot = 0.05

    /// The card's one sentence.
    static func sentence(_ c: RetryComparison) -> String {
        let details = c.key == .exactRepeat ? [] : StanceWords.details(c.setup)
        // No setting moved, yet the shot played differently: the stance or bridge, when either changed, is named (with
        // the stroke when that changed too), otherwise the stroke is the only thing that changed.
        if c.inputChanges.isEmpty, c.key == .severalChanges || c.key == .sameSpot {
            if let setup = StanceWords.setupOnly(c.setup, strokeChanged: c.stroke != nil, outcome: outcome(c)) {
                return ([setup] + details).joined(separator: " ")
            }
            return StrokeWords.strokeOnly(c.stroke, outcome: outcome(c))
        }
        let stroke = c.key == .exactRepeat ? nil : StrokeWords.comparison(c.stroke)
        return ([mainSentence(c)] + details + [stroke].compactMap { $0 }).joined(separator: " ")
    }

    /// The card's sentence from the settings and the outcome (the stroke's sentence, if any, follows it).
    private static func mainSentence(_ c: RetryComparison) -> String {
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
            // A changed stance or bridge is listed with the settings: it is one of the several things that changed.
            let names = (c.inputChanges.map { controlName($0.control) } + StanceWords.changedNames(c.setup))
                .formatted(.list(type: .and).locale(AppLocale.numbers))
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
            .formatted(.measurement(width: .wide, usage: .asProvided).locale(AppLocale.numbers))
        return String(localized: "the cue ball finished about \(distance) from where it stopped last time")
    }
}

/// "See the contact": pause the replay where the cue ball first touched a ball.
struct ContactButton: View {
    let model: ShowpieceModel
    /// Called after seeking, so a card can stay up while the replay sits at the contact.
    var onSeek: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    /// The button's own symbol: a small ball inside a ring, the moment one ball meets another. The crosshair ("scope")
    /// it used to share means Aim at nearest ball and the Aim guide elsewhere in the app.
    static let symbol = "smallcircle.filled.circle"

    var body: some View {
        if model.firstContactTime != nil {
            Group {
                if typeSize.isAccessibilitySize {
                    // The largest text: the words would push the card's other buttons off the row; VoiceOver still
                    // reads the full name.
                    button(words: false)
                } else {
                    // Words where the row has room, the symbol alone where it has not.
                    ViewThatFits(in: .horizontal) {
                        button(words: true)
                        button(words: false)
                    }
                }
            }
            .accessibilityLabel(String(localized: "See the contact"))
            .accessibilityHint(String(localized: "Pauses the replay where the cue ball first touched a ball"))
        }
    }

    /// See the contact's whole action, shared by this button and the upright phone's blurb button: pause the replay
    /// at the first contact, remember which recording it stopped in (ContactArrivalLine reads it), and say where it
    /// stopped. Reduce Motion is handed in because a blurb button's action cannot read the environment.
    static func seek(_ model: ShowpieceModel, reduceMotion: Bool) {
        // Reduce Motion: no camera flight to the moment; the Ride camera steps aside and the table view cuts.
        if reduceMotion && model.rideOn { model.setRide(false) }
        model.seekToFirstContact()
        ContactArrival.shared.version = model.timelineVersion
        ShotNarration.announce(ContactArrivalLine.words(ghost: model.ghost != nil))
    }

    /// See the contact as a small blurb button (the upright phone's result blurbs), or nil when the shot on screen
    /// touched no ball, as this button hides itself then.
    static func blurbButton(model: ShowpieceModel, reduceMotion: Bool) -> BlurbButton? {
        guard model.firstContactTime != nil else { return nil }
        return BlurbButton(String(localized: "See the contact"),
                           hint: String(localized: "Pauses the replay where the cue ball first touched a ball")) {
            seek(model, reduceMotion: reduceMotion)
        }
    }

    private func button(words: Bool) -> some View {
        Button {
            Self.seek(model, reduceMotion: reduceMotion)
            onSeek()
        } label: {
            Group {
                if words {
                    Label(String(localized: "See the contact"), systemImage: Self.symbol)
                        .font(.headline)
                        .lineLimit(1)
                        .fixedSize()
                } else {
                    Label(String(localized: "See the contact"), systemImage: Self.symbol).labelStyle(.iconOnly)
                        .frame(minWidth: 30)
                }
            }
            .frame(minHeight: CallMetrics.buttonHeight)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(words ? .capsule : .circle)
    }
}

/// Which recording See the contact last stopped at, shared by the button (inside another stream's card) and the line
/// shown with the cards. One per process: the app has one game window on the Mac and on iPad.
@MainActor
@Observable
final class ContactArrival {
    static let shared = ContactArrival()
    /// The timeline version (ShowpieceModel.timelineVersion) the button stopped at; nil before any press.
    var version: Int?
    private init() {}
}

/// The line on screen once See the contact has stopped the replay: what to look at. Shown while the replay is still
/// stopped at the first contact of the same recording, and gone the moment it plays or is scrubbed elsewhere.
struct ContactArrivalLine: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette

    /// How close the clock must be to the contact to count as still there, seconds: the scrub puts it exactly on the
    /// contact, and a millisecond is far less than one frame of the slowest replay, so any play or scrub leaves it.
    private static let atContact = 1e-3

    /// "Stopped at the first hit." and, only when a last try is on the table, "The faint ball is your last try."
    static func words(ghost: Bool) -> String {
        let first = String(localized: "Stopped at the first hit.")
        return ghost ? first + " " + String(localized: "The faint ball is your last try.") : first
    }

    /// True while the replay is still stopped at the first contact of the recording See the contact stopped in.
    /// Shared with ContactArrivalPhoneBlurb, so the line and the blurb come and go together.
    static func isShowing(_ model: ShowpieceModel) -> Bool {
        guard let t = model.firstContactTime, ContactArrival.shared.version == model.timelineVersion else { return false }
        return !model.playing && abs(model.time - t) < atContact
    }

    var body: some View {
        if Self.isShowing(model) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: ContactButton.symbol).foregroundStyle(palette.accent).accessibilityHidden(true)
                Text(Self.words(ghost: model.ghost != nil))
                    .font(Theme.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .glassCard(cornerRadius: Theme.Corner.medium, padding: Theme.Space.sm)
            .accessibilityElement(children: .combine)
            .transition(.opacity)
        }
    }
}

/// The upright phone's form of ContactArrivalLine (phone UI plan, Part 4 step 5): the same words as a docked blurb at
/// the top of the table area instead of a full-width glass card, while the replay stays stopped at the contact.
/// VoiceOver already heard the words when See the contact was pressed (ContactButton.seek); the blurb reads them again
/// when it is reached.
struct ContactArrivalPhoneBlurb: View {
    let model: ShowpieceModel

    var body: some View {
        if ContactArrivalLine.isShowing(model) {
            Blurb(sentence: ContactArrivalLine.words(ghost: model.ghost != nil))
        }
    }
}
