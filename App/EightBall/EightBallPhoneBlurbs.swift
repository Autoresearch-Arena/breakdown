// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 6, the upright phone's thumb dock: these blurbs
//          are word sources of the dock now, so their words show in its word strip and its pull-up sheet, never over
//          the table. "On a real table" is the strip's one line that opens the sheet, where its rows show in full (the
//          table keeps its whole frame). The call's ball chips, pocket menu and Safety moved out of the words into the
//          dock's aiming section (EightBallPhoneCallRow), still each its own button. "Lens replay" is "Physics Lens
//          replay" (the one name; wave 2 note 44). The paper roles and the kit's type replace white, the system's
//          secondary grey and the old blurb fonts.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 coordinator: what steps aside for the what-if now also steps
//          aside for the every-surface fan, through model.otherFutureShowing.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.8.1 store: the "On a real table" blurb starts open in the
//          real-table store scene, so the upright phone's picture shows its rows.)
// PURPOSE: Behind the 8-Ball on the upright phone (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "Every phone state" and
//          Part 4 step 5): everything EightBallCard (EightBallViews.swift) shows on the other layouts, as small docked
//          blurbs instead of one glass card. The situation's name is the title row's (PhoneTitle); a tap on it opens
//          the idea, which is the situation's story (the ideaOpen binding ShowpieceView shares with the trick and
//          lesson blurbs). By phase:
//            looking  - the story with the try ("Try 1 of 3") and its note (cloth, bridge, style cap), folded to three
//                       lines; Same call and Watch a way out in the blurb; "Make your call" is the primary action.
//                       After a shot with no call, the one line saying so instead of the story.
//            calling  - what to tap, with Cancel; the ball chips, the pocket menu and Safety (the shared call
//                       controls of App/Match/CallControl.swift) are EightBallPhoneCallRow, in the dock's aiming
//                       section, so each stays its own button for VoiceOver (a blurb reads its words as one element).
//            watching - the hint's line and Skip.
//            aiming / playing / scoring - the call (and the bridge's rule while aiming, Change call and Watch a way out;
//                       "Scoring…" while the judge works).
//            scored   - the scorecard: the result with its total, the medal or the try, the sum, what went wrong; the
//                       notes a tap away; Lens replay and Try again (after a make) or Watch a way out (after a miss) in
//                       the blurb; Next or Try again as the primary action. "On a real table" is a second blurb folded
//                       to its one-line title, which a tap opens to the aim, cue, speed, tip, commonest miss and cloth.
//          While a guided Lens replay of the try plays, the scorecard keeps its title line only and the real-table
//          blurb steps aside, so the moment has the table. The whole set steps back while the Lens tips show and while
//          a what-if is open, as the card does.
//          Also PhonePrimaryAction.eightBall. Colour: the card's cyan and magenta accents are white and the secondary
//          colour here (Part 3: magenta and cyan mean only sliding and rolling).
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// SRP/DRY check: Pass - every word comes from EightBallWords and EightBallFormat (shared with the card), the call
//          controls are CallBallChips, CallPocketMenu and CallSafetyButton, and every action is the card's own
//          EightBallMode call (startCalling, aimWithCall, watch, cancelCalling, pick, callSafety, skipHint, lensReplay,
//          tryAgain, next). Blurb and BlurbButton are the foundation's (App/Phone/Blurb.swift).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import SwiftUI

struct EightBallPhoneBlurbs: View {
    let model: ShowpieceModel
    /// The idea (the situation's story) is open: the title row's tap, shared with the trick and lesson blurbs.
    @Binding var ideaOpen: Bool
    /// The scorecard's fold (true is folded): the notes are a tap away.
    @State private var scoreFolded = true
    /// The real-table blurb's fold: its one-line title, or every row.
    @State private var realTableFolded = true
    @Environment(\.palette) private var palette

    private var mode: EightBallMode { model.eightBallMode }

    /// The blurb's fold switch is "folded"; the title row's is "open". One mapped binding, so either side opens it.
    private var ideaFolded: Binding<Bool> {
        Binding(get: { !ideaOpen }, set: { ideaOpen = !$0 })
    }

    var body: some View {
        // Steps back while the Lens tips are up (they are the one thing to read) and while a what-if is open on the
        // try (its own blurb and panel have the screen), exactly as EightBallCard.
        if let s = mode.current, mode.isActive, !model.holdForTips, !model.otherFutureShowing {
            switch mode.phase {
            case .looking:
                looking(s)
            case .calling:
                calling(s)
            case .watching:
                idea(s)
                Blurb(sentence: String(localized: "Watching a way out. Your style here is now capped at 2."),
                      buttons: [BlurbButton(String(localized: "Skip"),
                                            hint: String(localized: "Jumps to the end of the escape")) {
                          mode.skipHint()
                      }])
            case .aiming:
                idea(s)
                Blurb(sentence: aimingText(s), startsFolded: false, buttons: aimingButtons(s))
            case .playing:
                idea(s)
                Blurb(sentence: EightBallWords.callLine(mode))
            case .scoring:
                // The judge works on a background task; the table stays live and the blurb says so.
                Blurb {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: EightBallWords.callLine(mode))
                            .font(Theme.bodyCompact)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small).accessibilityHidden(true)
                            Text(String(localized: "Scoring…")).font(Theme.label).foregroundStyle(palette.paper2)
                        }
                    }
                }
            case .scored(let v):
                scored(s, v)
            case .off:
                EmptyView()
            }
        }
    }

    // MARK: Looking

    @ViewBuilder
    private func looking(_ s: EightBallSituation) -> some View {
        if mode.isAtStart {
            // The story is the instruction here: shown folded to three lines, the rest a tap (or the title) away.
            storyBlurb(s, buttons: lookingButtons(s))
        } else {
            idea(s)
            Blurb(sentence: String(localized: "That shot had no call, so it doesn't count. Make your call first."),
                  buttons: lookingButtons(s))
        }
    }

    /// Same call (when there is one) and Watch a way out; "Make your call" is the primary action.
    private func lookingButtons(_ s: EightBallSituation) -> [BlurbButton] {
        var out: [BlurbButton] = []
        if mode.call != nil {
            out.append(BlurbButton(String(localized: "Same call"),
                                   hint: String(localized: "Opens the aiming controls with the call you made")) {
                mode.aimWithCall()
            })
        }
        if let watch = watchButton(s) { out.append(watch) }
        return out
    }

    /// The idea outside the looking phase: only while the title row has opened it.
    @ViewBuilder
    private func idea(_ s: EightBallSituation) -> some View {
        if ideaOpen { storyBlurb(s, buttons: []) }
    }

    /// The situation's story with the try label as its title and the note (cloth, bridge, style cap) after it.
    private func storyBlurb(_ s: EightBallSituation, buttons: [BlurbButton]) -> some View {
        let words = [s.story, EightBallWords.situationNote(mode, s)].compactMap { $0 }.joined(separator: " ")
        return Blurb(title: EightBallWords.tryLabel(mode.nextTry), sentence: words, folded: ideaFolded,
                     buttons: buttons)
    }

    // MARK: Calling

    /// What to tap, then the call controls themselves. The controls sit outside the blurb, as glass straight over the
    /// table, so VoiceOver keeps every ball and pocket as its own button (the complete route; tapping the table is the
    /// quick one, EightBallTableLayer).
    private func calling(_ s: EightBallSituation) -> some View {
        let words = [EightBallWords.callPrompt(mode, s), mode.callNote].compactMap { $0 }.joined(separator: " ")
        // The controls themselves are EightBallPhoneCallRow, in the dock's aiming section (package 6).
        return Blurb(sentence: words, startsFolded: false,
                     buttons: [BlurbButton(String(localized: "Cancel")) { mode.cancelCalling() }])
    }

    // MARK: Aiming

    private func aimingText(_ s: EightBallSituation) -> String {
        var parts = [EightBallWords.callLine(mode)]
        if s.usesBridge {
            parts.append(String(localized: "Too far to reach: the bridge is legal, and touching a ball with it is a foul."))
        }
        return parts.joined(separator: " ")
    }

    private func aimingButtons(_ s: EightBallSituation) -> [BlurbButton] {
        var out = [BlurbButton(String(localized: "Change call")) { mode.startCalling() }]
        if let watch = watchButton(s) { out.append(watch) }
        return out
    }

    // MARK: Scored

    @ViewBuilder
    private func scored(_ s: EightBallSituation, _ v: EightBallVerdict) -> some View {
        let replaying = PlayPhoneBlurbs.replaying(model)
        let notes = EightBallWords.scoreNotes(mode, v)
        Group {
            if notes.isEmpty || replaying {
                Blurb(buttons: replaying ? [] : scoredButtons(s, v)) { scoreContent(v, open: false, replaying: replaying) }
            } else {
                Blurb(folded: $scoreFolded, buttons: scoredButtons(s, v)) { open in
                    scoreContent(v, open: open, replaying: false)
                }
            }
        }
        // Each scored try starts folded.
        .onAppear { scoreFolded = true }
        if !replaying, let e = mode.escapeForCard(v) { realTable(e) }
    }

    /// "Made it as called! · 12", the medal or the try, the sum, what went wrong; the notes once opened. While the try
    /// replays in the Lens, the title line alone.
    @ViewBuilder
    private func scoreContent(_ v: EightBallVerdict, open: Bool, replaying: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: EightBallWords.resultTitle(v)).font(Theme.label).lineLimit(2)
                Text(verbatim: "·").font(Theme.label).foregroundStyle(palette.paper2)
                Text(verbatim: v.total.formatted(.number.locale(AppLocale.numbers))).font(Theme.inlineFigure).foregroundStyle(palette.paper)
                    .lineLimit(1).fixedSize()
            }
            if !replaying {
                Text(verbatim: v.medal.map { String(localized: "\($0.title) medal") }
                     ?? EightBallWords.tryLabel(v.tryNumber))
                    .font(Theme.label)
                    .foregroundStyle(palette.paper2)
                // The sum, the total left out (it is the title's figure): "5 made  +3 difficulty  +2 style".
                Text(verbatim: EightBallWords.sumTerms(v).dropLast().map { "\($0.value) \($0.label)" }
                        .joined(separator: "   "))
                    .font(Theme.inlineFigure)
                    .foregroundStyle(palette.paper2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(Text(verbatim: EightBallWords.spokenSum(v)))
                if let line = EightBallWords.resultLine(v) {
                    Text(verbatim: line).font(Theme.bodyCompact).fixedSize(horizontal: false, vertical: true)
                }
                if open {
                    ForEach(Array(EightBallWords.scoreNotes(mode, v).enumerated()), id: \.offset) { _, n in
                        Text(verbatim: n).font(Theme.label).foregroundStyle(palette.paper2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    /// Lens replay, then Try again after a make (Next is the primary action) or Watch a way out after a miss (Try
    /// again is the primary action).
    private func scoredButtons(_ s: EightBallSituation, _ v: EightBallVerdict) -> [BlurbButton] {
        var out = [BlurbButton(String(localized: "Physics Lens replay"),
                               hint: String(localized: "Replays your shot slowly and explains it")) {
            mode.lensReplay()
        }]
        if v.madeAsCalled {
            out.append(BlurbButton(String(localized: "Try again"),
                                   hint: String(localized: "Puts the balls back, with the same call and your last settings")) {
                mode.tryAgain()
            })
        } else if let watch = watchButton(s) {
            out.append(watch)
        }
        return out
    }

    // MARK: On a real table

    /// The way out as it is played on a real table, folded to its title; a tap opens the rows (the card's real-table
    /// view, as words and the solver's numbers).
    private func realTable(_ e: EightBallEscape) -> some View {
        let c = e.card, n = c.numbers
        return Blurb(folded: $realTableFolded) { open in
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(verbatim: String(localized: "On a real table: \(e.title)")).font(Theme.label)
                        .lineLimit(open ? nil : 1)
                    Text(verbatim: "·").font(Theme.label).foregroundStyle(palette.paper2)
                    Text(verbatim: String(localized: "Rated \(e.rating)")).font(Theme.label)
                        .foregroundStyle(palette.paper2).lineLimit(1).fixedSize()
                }
                if open {
                    row(String(localized: "Aim"), c.aim, EightBallFormat.degrees(n.aimDegrees))
                    row(String(localized: "Cue"), c.cue, EightBallFormat.cueAngle(n.elevationDegrees))
                    row(String(localized: "Speed"), c.speed, EightBallFormat.speed(n.speed))
                    row(String(localized: "Tip"), nil, EightBallFormat.tip(up: n.tipUp, side: n.tipSide))
                    row(String(localized: "Common miss"), c.commonMiss, nil)
                    if n.surface != .cloth {
                        Text(verbatim: EightBallWords.clothSentence(n))
                            .font(Theme.label)
                            .foregroundStyle(palette.paper2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        // Each time it comes back (a new scored try, or the end of the try's Lens replay) it starts folded.
        // 0.8.1 store: the real-table store scene (-eightRealTable) shows it open, so the picture carries its rows.
        .onAppear { realTableFolded = !ProcessInfo.processInfo.arguments.contains("-eightRealTable") }
    }

    /// One row: a small label with the solver's number after it, then the plain words.
    private func row(_ label: String, _ words: String?, _ number: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: label).font(Theme.label).foregroundStyle(palette.paper2)
                if let number {
                    Text(verbatim: number).font(Theme.inlineFigure).foregroundStyle(palette.paper)
                }
            }
            if let words {
                Text(verbatim: words).font(Theme.bodyCompact).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Pieces

    /// Watch a way out: the hint, which caps style at 2. The card offers every authored way out in a menu; a blurb
    /// holds plain buttons only, so this plays the first one the situation lists (its authored lead way out). Nil
    /// when the situation has none.
    private func watchButton(_ s: EightBallSituation) -> BlurbButton? {
        guard let first = s.escapes.first else { return nil }
        return BlurbButton(String(localized: "Watch a way out"),
                           hint: String(localized: "Plays an escape. Your style here is then capped at 2.")) {
            mode.watch(first)
        }
    }
}

// MARK: The primary action

// MARK: The call, in the dock

/// The call's own controls while a Behind the 8-ball call is being made (package 6): the ball chips, then the pocket
/// menu once a ball is picked, and Safety, in the dock's aiming section under the word strip (whose words say what to
/// tap, with Cancel). Each its own button for VoiceOver. Nothing outside the calling phase.
struct EightBallPhoneCallRow: View {
    let model: ShowpieceModel
    private var mode: EightBallMode { model.eightBallMode }

    var body: some View {
        if mode.isActive, mode.current != nil, mode.phase == .calling, !model.holdForTips, !model.otherFutureShowing {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                CallBallChips(balls: mode.callableBalls, picked: mode.pendingBall) { mode.pick(ball: $0) }
                HStack(spacing: Theme.Space.xs) {
                    if mode.pendingBall != nil { CallPocketMenu(picked: nil) { mode.pick(pocket: $0) } }
                    CallSafetyButton { mode.callSafety() }
                }
                .controlSize(.regular)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity)
        }
    }
}

extension PhonePrimaryAction {
    /// Behind the 8-Ball's primary action: "Make your call" while looking, then after a scored try Next when it went
    /// as called and Try again otherwise (the card's prominent buttons). Nil in every other phase, while the Lens tips
    /// show and while a what-if is open (the card steps back then too).
    static func eightBall(_ model: ShowpieceModel) -> PhonePrimaryAction? {
        let mode = model.eightBallMode
        guard mode.isActive, mode.current != nil, !model.holdForTips, !model.otherFutureShowing else { return nil }
        switch mode.phase {
        case .looking:
            return PhonePrimaryAction(title: String(localized: "Make your call"),
                                      hint: String(localized: "Pick a ball, then a pocket, or call Safety")) {
                mode.startCalling()
            }
        case .scored(let v):
            if v.madeAsCalled {
                return PhonePrimaryAction(title: String(localized: "Next")) { mode.next() }
            }
            return PhonePrimaryAction(title: String(localized: "Try again"),
                                      hint: String(localized: "Puts the balls back, with the same call and your last settings")) {
                mode.tryAgain()
            }
        default:
            return nil
        }
    }
}
