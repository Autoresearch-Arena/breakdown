// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, Part 4 step 5: no change on screen. The card's
//          words are lifted into EightBallWords (the try label, the call prompt and call line, the situation's note,
//          the result's title and what went wrong, the scorecard's notes, the sum's terms, the cloth sentence) so the
//          upright phone's blurbs (EightBallPhoneBlurbs.swift) say exactly the same; EightBallFormat is no longer
//          private to this file for the same reason.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream cards, plans/22-Nov-2026-phone-bug-hunt.md #41: the slim
//          card's heading shows the replayed try's number during the Lens replay of a scored try, not the next try's.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (sound-lessons hook, bug plan item 36: a medal plays the made-it sound
//          with its glow, the big one for gold.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the screens builder's pass: the full list with medals, best scores
//          and the running total, and a plain empty state; the card for every phase, the scorecard and the "On a real
//          table" card; the rings and the tap-to-call on the table; VoiceOver labels and a complete call from the card
//          alone).
// Edited: Claude Opus 5.5 High, 21-November-2026 (tapping a ball or pocket works: the tap area measures itself; the
//          scorecard says each result once and keeps its buttons on one row; the -eightPlay, -eightRide, -eightAim, -eightWatch
//          and -eightRealTable test flags; the -eightJudgeCheck launch flag writes the acceptance check to the log and
//          Documents.)
// Edited: Claude Opus 5.5 Medium, 21-November-2026 (the card's light "Scoring…" state while the judge works.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (imports BreakdownRules, where the eight-ball group, pocket, call,
//          foul and loss types now live; nothing else changed.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the call control and the cue-angle menu moved to shared files so the
//          match and free play reuse them: the ball chips, pocket menu and Safety button are CallBallChips,
//          CallPocketMenu and CallSafetyButton (App/Match/CallControl.swift), the cue angle is CueAngleMenu
//          (App/CueAngleControl.swift). This card drives them exactly as before.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (version 0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md: item 27,
//          the "On a real table" cloth row says what a ball rolling straight into a rail at a stated pace keeps
//          (RailKeep) instead of the raw "cushion bounce"; item 53, the card stands back while the Lens tips show
//          (model.holdForTips); item 36 by the contract (docs/v07-contracts.md 3.6), a medal plays the made-it sound
//          with the glow, the big one for gold, through SoundBoard, which also plays its haptic, so the card's own
//          success haptic is gone rather than doubled.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hook, 0.7.0 item 44: Next's arrow follows the reading direction.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: the interface's orange became magenta, so the bronze medal
//          no longer borrows Palette.slide (a magenta medal would read as a fourth prize); it gets its own muted bronze.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          items 8, 11 and 12: the card's cue-angle menu is gone, so the shot panel's is the one cue-angle control while
//          aiming; the card steps aside while a what-if is open and shows its slim form (the heading and the main
//          button) during a guided Lens replay on a phone held upright; the list's Mac minimum size applies only as a
//          sheet, not as a page of the notebook.)
// PURPOSE: Everything the player sees of Behind the 8-Ball, modelled on TrickShotViews:
//          EightBallList - the list of situations in a sheet from the menu: number (or the medal won), title, story,
//            best score, the hardest authored way out, the cloth when it is not the standard one, the bridge; the
//            running total and the scoring sentence. With no situations yet it says so plainly.
//          EightBallCard - the compact glass card at the bottom edge (top of the side column on iPad, Mac and
//            landscape), hosted beside TrickShotCard. Looking: the story, Make your call, Watch an escape (the hint,
//            which caps style at 2). Calling: the prompt, your callable balls and the six pockets as buttons (the
//            complete route for VoiceOver; tapping the table is the quick route), Safety, Back. Aiming: the call and
//            the bridge line (the cue angle for jumps and massés is the shot panel's CueAngleMenu). Scored: the
//            result, the sum (5 made + difficulty + style - retry = total) with each style point named, the medal,
//            then Physics Lens replay, Watch an escape, On a real table, Try again or Next. The "On a real table" card
//            replaces the score while it is open: where to aim, how to hold the cue, how hard, the commonest miss, with
//            the solver's numbers beside the words, and the cloth's numbers next to the standard cloth's when the
//            situation is set on another cloth.
//          EightBallTableLayer - laid over the 3D table, hosted beside TrickTableLayer: rings on the called ball and
//            pocket (faint rings on what can be tapped while calling), the success glow, the list sheet, the launch
//            flags (-eightList, -eight <id>). Only while calling does it take touches: a tap is projected onto the table
//            with AimProjector (as AimOverlay does) and picks the nearest ball or pocket. It forwards the model's
//            playback changes to EightBallMode.update() and opens or closes the shot panel when the mode asks.
//          Standard controls (Liquid Glass buttons, a List, Menus, SF Symbols), Dynamic Type (button rows fall back to
//          a column), VoiceOver labels, Reduce Motion (the glow only fades; the card changes without animation).
// SRP/DRY check: Pass - views only. Flow is EightBallMode, data EightBallSituations, the cloth numbers come from
//          RealTableNumbers and PlaySurface.parameters; projection is AimProjector; card styling is the shared
//          glassCard. The card's small pieces (header, line, button row, prominent style) follow TrickShotCard's so the
//          two cards look and behave the same; they are private there, so they are repeated here rather than shared.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import SwiftUI

// MARK: Shared small pieces

private extension EightBallMedal {
    var symbol: String { "medal.fill" }

    func tint(_ palette: Palette) -> Color {
        switch self {
        case .gold: return palette.pocket
        case .silver: return Color(white: 0.72)
        // Its own muted bronze, brown rather than orange: a medal's colour names the metal, so it does not follow the
        // sliding colour (Palette.slide, magenta) it borrowed before 0.7.2.
        case .bronze: return Color(red: 0.72, green: 0.53, blue: 0.38)
        }
    }
}

/// Numbers for the cards, in the player's own number format. Also read by the upright phone's real-table blurb.
enum EightBallFormat {
    static func decimal(_ x: Double, _ places: Int) -> String {
        String(format: "%.\(places)f", locale: Locale.current, x)
    }

    static func degrees(_ x: Double) -> String { String(localized: "\(decimal(x, 1))°") }
    static func speed(_ x: Double) -> String { String(localized: "\(decimal(x, 1)) m/s") }

    /// The cue angle as words: level, or the angle above level (shared with the cue-angle menu).
    static func cueAngle(_ degrees: Double) -> String { CueAngleMenu.words(degrees: degrees) }

    /// Tip offsets in millimetres, "centre" when both are zero.
    static func tip(up: Double, side: Double) -> String {
        var parts: [String] = []
        let u = (up * 1000).rounded(), s = (side * 1000).rounded()
        if u > 0 { parts.append(String(localized: "\(decimal(u, 0)) mm above")) }
        if u < 0 { parts.append(String(localized: "\(decimal(-u, 0)) mm below")) }
        if s > 0 { parts.append(String(localized: "\(decimal(s, 0)) mm right")) }
        if s < 0 { parts.append(String(localized: "\(decimal(-s, 0)) mm left")) }
        return parts.isEmpty ? String(localized: "Centre") : parts.formatted(.list(type: .and))
    }
}

// MARK: Words, shared

/// The card's words, shared with the upright phone's blurbs (EightBallPhoneBlurbs.swift) so the two layouts never say
/// different things. Reads EightBallMode and the verdict only.
@MainActor
enum EightBallWords {
    /// "Try 2 of 3", or "Practice" once the scored tries are used up.
    static func tryLabel(_ n: Int) -> String {
        n > EightBallVerdict.maxTries ? String(localized: "Practice")
                                      : String(localized: "Try \(n) of \(EightBallVerdict.maxTries)")
    }

    /// What to tap while calling.
    static func callPrompt(_ mode: EightBallMode, _ s: EightBallSituation) -> String {
        if let b = mode.pendingBall {
            return String(localized: "The \(b). Now tap the pocket you call.")
        }
        return s.onTheEight
            ? String(localized: "You're on the 8. Tap it, then the pocket you call. Or call Safety.")
            : String(localized: "Tap one of your balls (\(s.group.title)), then the pocket you call. Or call Safety.")
    }

    /// "You called the 3 in the foot-left corner." or "You called Safety."
    static func callLine(_ mode: EightBallMode) -> String {
        switch mode.call {
        case .ball(let b, let p)?: return String(localized: "You called the \(b): \(p.title).")
        case .safety?: return String(localized: "You called Safety: a legal hit that leaves them hooked.")
        case nil: return String(localized: "No call yet.")
        }
    }

    /// The cloth and the bridge, when they matter: one small line under the story.
    static func situationNote(_ mode: EightBallMode, _ s: EightBallSituation) -> String? {
        var parts: [String] = []
        if s.surface != .cloth { parts.append(String(localized: "Set on \(s.surface.title).")) }
        if s.usesBridge { parts.append(String(localized: "The bridge is legal here.")) }
        if mode.hintTaken { parts.append(String(localized: "Style capped at 2.")) }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    static func resultTitle(_ v: EightBallVerdict) -> String {
        if v.gameLost { return String(localized: "Game lost") }
        if v.fouled { return String(localized: "Foul") }
        if v.madeAsCalled { return String(localized: "Made it as called!") }
        if v.call == .safety { return v.safetyLeftHooked ? String(localized: "Safe! They're hooked.")
                                                          : String(localized: "Legal safety") }
        return String(localized: "Missed, but legal")
    }

    static func whatWentWrong(_ v: EightBallVerdict) -> String? {
        if let loss = v.loss { return loss.title + "." }
        if v.fouled { return v.fouls.map(\.title).formatted(.list(type: .and)) + "." }
        return nil
    }

    /// The one line under the result's title, never the same news twice: what went wrong, or else the judge's
    /// sentence when it adds something to the title (a plain "Made as called." does not).
    static func resultLine(_ v: EightBallVerdict) -> String? {
        if let why = whatWentWrong(v) { return why }
        if !v.line.isEmpty, v.line != String(localized: "Made as called.") { return v.line }
        return nil
    }

    /// The scorecard's small notes under the sum, in order.
    static func scoreNotes(_ mode: EightBallMode, _ v: EightBallVerdict) -> [String] {
        var out: [String] = []
        if v.madeAsCalled && !v.style.isEmpty {
            out.append(String(localized: "Style: \(v.style.map(\.title).formatted(.list(type: .and)))."))
        }
        if v.nearEdge { out.append(String(localized: "Close to the edge of what works: one off difficulty, and no style.")) }
        if v.fluke { out.append(String(localized: "An unplanned kiss: it counts, but scores no difficulty or style.")) }
        if mode.hintTaken && v.madeAsCalled { out.append(String(localized: "You watched a way out first, so style is capped at 2.")) }
        if v.isPractice { out.append(String(localized: "Practice: three scored tries are used up, so this one isn't kept.")) }
        return out
    }

    /// The sum's terms, in order, the total last: made 5 + difficulty + style − retry = total (or escape 1, safety 3,
    /// foul 0).
    static func sumTerms(_ v: EightBallVerdict) -> [(value: String, label: String)] {
        var terms: [(value: String, label: String)] = []
        if !v.legal {
            terms.append(("0", v.gameLost ? String(localized: "game lost") : String(localized: "foul")))
        } else if v.madeAsCalled {
            terms.append(("\(EightBallVerdict.madePoints)", String(localized: "made")))
            terms.append(("+\(v.difficulty)", String(localized: "difficulty")))
            terms.append(("+\(v.stylePoints)", String(localized: "style")))
        } else if v.call == .safety && v.safetyLeftHooked {
            terms.append(("\(EightBallVerdict.safetyPoints)", String(localized: "safety")))
        } else {
            terms.append(("\(EightBallVerdict.legalMissPoints)", String(localized: "escape")))
        }
        if v.retryPenalty > 0 && v.legal { terms.append(("−\(v.retryPenalty)", String(localized: "retry"))) }
        terms.append(("= \(v.total)", String(localized: "total")))
        return terms
    }

    /// The sum as VoiceOver reads it: "Score: made 5, difficulty +3, ..., total = 10".
    static func spokenSum(_ v: EightBallVerdict) -> String {
        let spoken = sumTerms(v).map { "\($0.label) \($0.value)" }.joined(separator: ", ")
        return String(localized: "Score: \(spoken)")
    }

    /// This cloth's numbers next to the standard cloth's, in one sentence (the card's VoiceOver label for its cloth
    /// grid; the phone's real-table blurb shows it as its last line).
    static func clothSentence(_ n: RealTableNumbers) -> String {
        let std = PlaySurface.cloth.parameters
        let d = EightBallFormat.decimal
        let pace = d(RailKeep.pace, 0)
        let keeps = RailKeep.percent(parameters: n.surface.parameters)
        let keepsStd = RailKeep.percent(parameters: std)
        return String(localized: "Cloth: \(n.surface.title). Sliding friction \(d(n.slidingFriction, 2)), standard \(d(std.slidingFriction, 2)). Rolling resistance \(d(n.rollingResistance, 3)), standard \(d(std.rollingResistance, 3)). A ball rolling straight into a rail at \(pace) metres per second keeps \(keeps) percent of its speed, standard \(keepsStd) percent.")
    }
}

// MARK: The list

struct EightBallList: View {
    let mode: EightBallMode
    @Environment(\.palette) private var palette
    /// True when the list is a page of the notebook (iPad, Mac, the open Duo) rather than a sheet of its own.
    @Environment(\.inlinePages) private var inlinePages

    var body: some View {
        NavigationStack {
            Group {
                if EightBallSituations.all.isEmpty {
                    ContentUnavailableView {
                        Label("No situations yet", systemImage: "8.circle")
                    } description: {
                        Text(String(localized: "The tables are still being set up. They will show here when they're ready."))
                    }
                } else {
                    list
                }
            }
            .navigationTitle(String(localized: "Behind the 8-Ball"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { mode.listOpen = false } }
            }
        }
        .tint(palette.accent)
        #if os(macOS)
        // A sheet's own minimum size; as a page of the Mac notebook it takes the panel's size (0.7.5: the minimum
        // pushed the list past the panel's edge). Nil sizes rather than an if, so the view keeps its identity.
        .frame(minWidth: inlinePages ? nil : 460, minHeight: inlinePages ? nil : 560)
        #endif
    }

    private var list: some View {
        List {
            Section {
                ForEach(EightBallSituations.all) { s in
                    Button { mode.begin(s) } label: { row(s) }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(spoken(s))
                        .accessibilityHint(String(localized: "Sets the table up"))
                }
            } header: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "You're hooked. Call your ball and pocket, then get out."))
                        .textCase(nil)
                    Text(String(localized: "Your total: \(mode.runningTotal)"))
                        .font(Theme.label)
                        .foregroundStyle(palette.accent)
                        .textCase(nil)
                }
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "Make it as called for 5, plus up to 5 for difficulty and up to 5 for style. A legal miss earns 1. A foul earns nothing. Each retry costs 1."))
                    Text(String(localized: "Bronze for a make, silver at 10, gold at 13."))
                    Text(String(localized: "Why the name? In eight-ball, hitting the 8 first is a foul. In an older pool game, sitting behind the 8 was bad luck."))
                }
            }
        }
    }

    private func row(_ s: EightBallSituation) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            ZStack {
                if let m = mode.medal(s) {
                    Image(systemName: m.symbol).foregroundStyle(m.tint(palette))
                } else {
                    Text("\(s.number)").font(Theme.equation).foregroundStyle(palette.accent)
                }
            }
            .font(.title3)
            .frame(minWidth: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(s.title).font(Theme.heading).foregroundStyle(.primary)
                Text(s.story)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(details(s))
                    .font(Theme.label)
                    .foregroundStyle(palette.slide)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    /// "Best 9 · Up to 5 · Tournament cloth · Bridge"
    private func details(_ s: EightBallSituation) -> String {
        var parts: [String] = []
        if let b = mode.best(s) { parts.append(String(localized: "Best \(b)")) }
        parts.append(String(localized: "Rated up to \(s.topRating)"))
        if s.surface != .cloth { parts.append(s.surface.title) }
        if s.usesBridge { parts.append(String(localized: "Bridge")) }
        return parts.joined(separator: " · ")
    }

    private func spoken(_ s: EightBallSituation) -> String {
        var text = String(localized: "Situation \(s.number), \(s.title).")
        if let m = mode.medal(s) { text += " " + String(localized: "\(m.title) medal.") }
        if let b = mode.best(s) { text += " " + String(localized: "Best score \(b).") }
        text += " " + String(localized: "Rated up to \(s.topRating).")
        if s.surface != .cloth { text += " " + String(localized: "Set on \(s.surface.title).") }
        if s.usesBridge { text += " " + String(localized: "Needs the bridge.") }
        return text + " " + s.story
    }
}

// MARK: The card

struct EightBallCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    /// On a phone held upright while a guided Lens replay plays (set by ShowpieceView, App/LayoutFlags.swift): the slim
    /// card, heading and main button only, so the table keeps its height.
    @Environment(\.lensReplayCompact) private var compact

    private var mode: EightBallMode { model.eightBallMode }

    var body: some View {
        // While the Lens tips are up (the player's own Lens replay of this try) the card stands back, so the tips are
        // the one thing to read; it returns as soon as they are done. While a what-if is open on the try (0.7.5,
        // WhatIfFork.isShowing) its card is the one result card: this one steps aside and comes back when it closes.
        if let s = mode.current, mode.isActive, !model.holdForTips, !model.whatIf.isShowing {
            VStack(alignment: .leading, spacing: 8) {
                if compact { slim(s) } else { content(s) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .tint(palette.accent)
            .animation(reduceMotion ? nil : .snappy, value: mode.phase)
            .animation(reduceMotion ? nil : .snappy, value: mode.showingRealTable)
            // The medal's sound and its buzz are played together by SoundBoard (EightBallTableLayer, beside the glow),
            // so the card no longer adds a haptic of its own on top.
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func content(_ s: EightBallSituation) -> some View {
        switch mode.phase {
        case .looking:
            header(s)
            if mode.isAtStart {
                line(s.story)
                if let extra = situationNote(s) { note(extra) }
            } else {
                line(String(localized: "That shot had no call, so it doesn't count. Make your call first."))
            }
            buttons {
                watchMenu(s)
                if mode.call != nil {
                    styled(Button { mode.aimWithCall() } label: {
                        Label("Same call", systemImage: "target").font(.headline).lineLimit(1)
                            .frame(minHeight: Self.buttonHeight)
                    }, prominent: false)
                    .accessibilityHint(String(localized: "Opens the aiming controls with the call you made"))
                }
                callButton(prominent: true)
                listButton
            }
        case .calling:
            header(s)
            line(EightBallWords.callPrompt(mode, s))
            if let n = mode.callNote { note(n, warning: true) }
            CallBallChips(balls: mode.callableBalls, picked: mode.pendingBall) { mode.pick(ball: $0) }
            buttons {
                if mode.pendingBall != nil { CallPocketMenu(picked: nil) { mode.pick(pocket: $0) } }
                CallSafetyButton { mode.callSafety() }
                Button { mode.cancelCalling() } label: {
                    Label("Back", systemImage: "xmark").labelStyle(.iconOnly)
                        .frame(minWidth: 30, minHeight: Self.buttonHeight)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel(String(localized: "Back"))
            }
        case .watching:
            header(s)
            line(String(localized: "Watching a way out. Your style here is now capped at 2."))
            buttons {
                styled(Button { mode.skipHint() } label: {
                    Label("Skip", systemImage: "forward.end.fill").font(.headline).lineLimit(1)
                        .frame(minHeight: Self.buttonHeight)
                }, prominent: false)
                .accessibilityHint(String(localized: "Jumps to the end of the escape"))
            }
        case .aiming:
            header(s)
            line(callLine)
            if s.usesBridge {
                note(String(localized: "Too far to reach: the bridge is legal, and touching a ball with it is a foul."))
            }
            // No cue-angle menu here (0.7.5): the shot panel's own (CueAngleMenu, ShotPanel) is the one control, so the
            // card no longer shows a second copy of it beside the panel.
            buttons {
                styled(Button { mode.startCalling() } label: {
                    Label("Change call", systemImage: "hand.tap").font(.headline).lineLimit(1)
                        .frame(minHeight: Self.buttonHeight)
                }, prominent: false)
                watchMenu(s)
            }
        case .playing:
            header(s)
            line(callLine)
        case .scoring:
            // The judge is working on a background task; the table stays live and the card says so.
            header(s)
            line(callLine)
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Scoring…").font(.subheadline).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        case .scored(let v):
            if mode.showingRealTable {
                realTable(s, verdict: v)
            } else {
                scorecard(s, v)
            }
            scoredButtons(s, v)
        case .off:
            EmptyView()
        }
    }

    /// The slim card (0.7.5, lensReplayCompact): the situation's heading and the one button that moves it on, so the
    /// player's Lens replay on a phone held upright keeps the table its height. After a scored try, Next when it went
    /// as called and Try again otherwise; the heading alone in any other phase.
    @ViewBuilder
    private func slim(_ s: EightBallSituation) -> some View {
        // A scored try's replay is headed by that try's number, as the scorecard it replaces was (0.7.6, #41), not the
        // next try's.
        if case .scored(let v) = mode.phase { header(s, tryNumber: v.tryNumber) } else { header(s) }
        if case .scored(let v) = mode.phase {
            buttons {
                if v.madeAsCalled { nextButton } else { tryAgainButton(prominent: true) }
            }
        }
    }

    // MARK: Calling

    /// "You called the 3 in the foot-left corner." or "You called Safety."
    private var callLine: String { EightBallWords.callLine(mode) }

    // MARK: Scored

    @ViewBuilder
    private func scorecard(_ s: EightBallSituation, _ v: EightBallVerdict) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: resultSymbol(v))
                .foregroundStyle(v.medal?.tint(palette) ?? (v.legal ? palette.accent : palette.slide))
                .accessibilityHidden(true)
            Text(resultTitle(v)).font(Theme.heading).lineLimit(2)
            Spacer(minLength: 0)
            if let m = v.medal {
                Text(String(localized: "\(m.title) medal")).font(Theme.label).foregroundStyle(m.tint(palette))
            } else {
                Text(tryLabel(v.tryNumber)).font(Theme.label).foregroundStyle(palette.slide)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        // One line under the title, never the same news twice: what went wrong, or else the judge's sentence when it
        // adds something to the title (a plain "Made as called." does not).
        if let words = EightBallWords.resultLine(v) { line(words) }
        sum(v)
        ForEach(Array(EightBallWords.scoreNotes(mode, v).enumerated()), id: \.offset) { _, n in note(n) }
    }

    private func resultSymbol(_ v: EightBallVerdict) -> String {
        if v.gameLost { return "xmark.octagon.fill" }
        if v.fouled { return "exclamationmark.triangle.fill" }
        if v.madeAsCalled { return v.medal?.symbol ?? "checkmark.seal.fill" }
        if v.call == .safety && v.safetyLeftHooked { return "shield.fill" }
        return "arrow.uturn.backward.circle"
    }

    private func resultTitle(_ v: EightBallVerdict) -> String { EightBallWords.resultTitle(v) }

    private func tryLabel(_ n: Int) -> String { EightBallWords.tryLabel(n) }

    /// The sum in one row: made 5 + difficulty + style − retry = total (or escape 1, safety 3, foul 0).
    private func sum(_ v: EightBallVerdict) -> some View {
        let all = EightBallWords.sumTerms(v)
        let last = all.count - 1
        let totalFont = Font.title3.monospacedDigit().weight(.bold)
        let termFont = Font.headline.monospacedDigit()
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            ForEach(Array(all.enumerated()), id: \.offset) { i, t in
                VStack(spacing: 0) {
                    Text(t.value)
                        .font(i == last ? totalFont : termFont)
                        .foregroundStyle(i == last ? palette.accent : palette.paper)
                    Text(t.label).font(.caption2).foregroundStyle(.secondary)
                }
                .fixedSize()
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(EightBallWords.spokenSum(v))
    }

    private func scoredButtons(_ s: EightBallSituation, _ v: EightBallVerdict) -> some View {
        buttons {
            Button { mode.lensReplay() } label: {
                Label("Physics Lens replay", systemImage: "eye").labelStyle(.iconOnly)
                    .frame(minWidth: 30, minHeight: Self.buttonHeight)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(String(localized: "Physics Lens replay"))
            .accessibilityHint(String(localized: "Replays your shot slowly and explains it"))
            if mode.escapeForCard(v) != nil {
                Button { mode.showingRealTable.toggle() } label: {
                    Label(mode.showingRealTable ? "Your score" : "On a real table",
                          systemImage: mode.showingRealTable ? "list.number" : "book.closed")
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 30, minHeight: Self.buttonHeight)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel(mode.showingRealTable ? String(localized: "Your score")
                                                          : String(localized: "On a real table"))
                .accessibilityHint(String(localized: "How to play this way out on a real table"))
            }
            watchMenu(s)
            if v.madeAsCalled {
                // An icon here, so the five buttons stay on one row and Next stays on screen.
                Button { mode.tryAgain() } label: {
                    Label("Try again", systemImage: "arrow.uturn.backward").labelStyle(.iconOnly)
                        .frame(minWidth: 30, minHeight: Self.buttonHeight)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel(String(localized: "Try again"))
                .accessibilityHint(String(localized: "Puts the balls back, with the same call and your last settings"))
                nextButton
            } else {
                tryAgainButton(prominent: true)
            }
        }
    }

    private var nextButton: some View {
        styled(Button { mode.next() } label: {
            Label("Next", systemImage: "arrow.forward").font(.headline).lineLimit(1)
                .frame(minHeight: Self.buttonHeight)
        }, prominent: true)
        .keyboardShortcut(.defaultAction)
    }

    // MARK: On a real table

    @ViewBuilder
    private func realTable(_ s: EightBallSituation, verdict v: EightBallVerdict) -> some View {
        if let e = mode.escapeForCard(v) {
            let c = e.card, n = c.numbers
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "book.closed").foregroundStyle(palette.accent).accessibilityHidden(true)
                Text(String(localized: "On a real table: \(e.title)")).font(Theme.heading).lineLimit(2)
                Spacer(minLength: 0)
                Text(String(localized: "Rated \(e.rating)")).font(Theme.label).foregroundStyle(palette.slide)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            realRow(String(localized: "Aim"), c.aim, EightBallFormat.degrees(n.aimDegrees))
            realRow(String(localized: "Cue"), c.cue, EightBallFormat.cueAngle(n.elevationDegrees))
            realRow(String(localized: "Speed"), c.speed, EightBallFormat.speed(n.speed))
            realRow(String(localized: "Tip"), nil, EightBallFormat.tip(up: n.tipUp, side: n.tipSide))
            realRow(String(localized: "Common miss"), c.commonMiss, nil)
            if n.surface != .cloth { clothRow(n) }
        }
    }

    /// One row: a small label, the plain words, and the solver's number beside them.
    private func realRow(_ label: String, _ words: String?, _ number: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).font(Theme.label).foregroundStyle(palette.slide)
                Spacer(minLength: 8)
                if let number, words != nil {
                    Text(number).font(Theme.number).foregroundStyle(palette.accent)
                }
            }
            if let words {
                Text(words).font(Theme.body).foregroundStyle(palette.paper.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            } else if let number {
                Text(number).font(Theme.body).foregroundStyle(palette.paper.opacity(0.9))
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// This cloth's numbers next to the standard cloth's, so the player sees why their table plays differently. The
    /// rails are said as what a ball rolling straight in at a stated pace keeps (RailKeep, the solver's rail rules),
    /// not as the raw restitution, which the tuned rail no longer makes equal to what a ball gets back.
    private func clothRow(_ n: RealTableNumbers) -> some View {
        let std = PlaySurface.cloth.parameters
        let d = EightBallFormat.decimal
        let pace = d(RailKeep.pace, 0)
        let keeps = RailKeep.percent(parameters: n.surface.parameters)
        let keepsStd = RailKeep.percent(parameters: std)
        return VStack(alignment: .leading, spacing: 2) {
            Text(String(localized: "Cloth: \(n.surface.title)")).font(Theme.label).foregroundStyle(palette.slide)
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 2) {
                GridRow {
                    Text("")
                    Text(n.surface.title).font(.caption2).foregroundStyle(.secondary)
                    Text(String(localized: "Standard")).font(.caption2).foregroundStyle(.secondary)
                }
                GridRow {
                    Text(String(localized: "Sliding friction")).font(.caption)
                    Text(d(n.slidingFriction, 2)).font(Theme.number)
                    Text(d(std.slidingFriction, 2)).font(Theme.number).foregroundStyle(.secondary)
                }
                GridRow {
                    Text(String(localized: "Rolling resistance")).font(.caption)
                    Text(d(n.rollingResistance, 3)).font(Theme.number)
                    Text(d(std.rollingResistance, 3)).font(Theme.number).foregroundStyle(.secondary)
                }
                GridRow {
                    Text(String(localized: "Rail keeps at \(pace) m/s")).font(.caption)
                    // The player's own percent style (the sign's place and spacing differ by language).
                    Text(verbatim: (Double(keeps) / 100).formatted(.percent.precision(.fractionLength(0))))
                        .font(Theme.number)
                    Text(verbatim: (Double(keepsStd) / 100).formatted(.percent.precision(.fractionLength(0))))
                        .font(Theme.number).foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(EightBallWords.clothSentence(n))
    }

    // MARK: Pieces

    /// The situation's heading with a try label: the next try's by default, or a given try's (the scored try being
    /// replayed in the slim card).
    private func header(_ s: EightBallSituation, tryNumber: Int? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(String(localized: "\(s.number). \(s.title)")).font(Theme.heading).lineLimit(2)
            Spacer(minLength: 0)
            Text(tryLabel(tryNumber ?? mode.nextTry)).font(Theme.label).foregroundStyle(palette.slide)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// The cloth and the bridge, when they matter: one small line under the story.
    private func situationNote(_ s: EightBallSituation) -> String? { EightBallWords.situationNote(mode, s) }

    private func line(_ text: String) -> some View {
        Text(text)
            .font(Theme.body)
            .foregroundStyle(palette.paper.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func note(_ text: String, warning: Bool = false) -> some View {
        Text(text)
            .font(Theme.label)
            .foregroundStyle(warning ? palette.slide : palette.paper.opacity(0.75))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One row of buttons, right-aligned; a column when the text is too large for one row.
    private func buttons<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let row = content()
        return Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .trailing, spacing: 8) { row }.frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { Spacer(minLength: 0); row }
                    WrappingRow { row }.frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .controlSize(.regular)
    }

    private func callButton(prominent: Bool) -> some View {
        styled(Button { mode.startCalling() } label: {
            Label("Make your call", systemImage: "hand.tap").font(.headline).lineLimit(1)
                .frame(minHeight: Self.buttonHeight)
        }, prominent: prominent)
        .accessibilityHint(String(localized: "Pick a ball, then a pocket, or call Safety"))
    }

    private func tryAgainButton(prominent: Bool) -> some View {
        styled(Button { mode.tryAgain() } label: {
            Label("Try again", systemImage: "arrow.uturn.backward").font(.headline).lineLimit(1)
                .frame(minHeight: Self.buttonHeight)
        }, prominent: prominent)
        .accessibilityHint(String(localized: "Puts the balls back, with the same call and your last settings"))
    }

    /// The hint: watch one of the authored ways out. Before a make it caps style at 2, and the menu says so.
    @ViewBuilder
    private func watchMenu(_ s: EightBallSituation) -> some View {
        if !s.escapes.isEmpty {
            Menu {
                Section {
                    ForEach(s.escapes) { e in
                        Button(String(localized: "\(e.title), rated \(e.rating)")) { mode.watch(e) }
                    }
                } header: {
                    Text(String(localized: "Watching caps your style here at 2."))
                }
            } label: {
                Label("Watch a way out", systemImage: "play.fill").labelStyle(.iconOnly)
                    .frame(minWidth: 30, minHeight: Self.buttonHeight)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(String(localized: "Watch a way out"))
            .accessibilityHint(String(localized: "Plays an escape. Your style here is then capped at 2."))
        }
    }

    private var listButton: some View {
        Button { mode.listOpen = true } label: {
            Label("All situations", systemImage: "list.bullet").labelStyle(.iconOnly)
                .frame(minWidth: 30, minHeight: Self.buttonHeight)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(String(localized: "All situations"))
    }

    @ViewBuilder
    private func styled(_ button: some View, prominent: Bool) -> some View {
        if prominent {
            // Dark text on the bright accent: white on cyan is too faint (as the Shoot button).
            button.buttonStyle(.glassProminent).foregroundStyle(palette.ground)
        } else {
            button.buttonStyle(.glass)
        }
    }

    /// The glass button adds its own padding; this lands the buttons on 44 points or more on a touch screen.
    #if os(iOS)
    private static let buttonHeight: CGFloat = 30
    #else
    private static let buttonHeight: CGFloat = 0
    #endif
}

// MARK: Over the table

struct EightBallTableLayer: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Binding var shotPanelOpen: Bool
    @Environment(\.inlinePages) private var inlinePages
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cameraBox = AimProjector.CameraBox()
    @State private var glow = 0.0

    private var mode: EightBallMode { model.eightBallMode }
    @MainActor private static var launchHandled = false

    var body: some View {
        @Bindable var mode = mode
        ZStack {
            if mode.marks != nil {
                TimelineView(.animation) { _ in
                    Canvas { ctx, size in drawMarks(&ctx, size: size) }
                }
                .allowsHitTesting(false)
            }
            // Calling: a tap on the table picks the nearest ball or pocket. Only now does this layer take touches;
            // the card's buttons are the full route for VoiceOver, so this catcher is hidden from it.
            if mode.phase == .calling {
                // Measured here, not from the layer: the layer's own measured size leaves out the safe areas, which
                // put every ball about a ball's width away from where the tap landed.
                GeometryReader { geo in
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(count: 1, coordinateSpace: .local) { point in tap(at: point, in: geo.size) }
                }
            }
            // A medal: a short glow around the edge of the screen. It only fades, so it is the same with Reduce Motion.
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .strokeBorder(palette.accent, lineWidth: 6)
                .blur(radius: 10)
                .opacity(glow)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        // On a folding phone the list is a page of the side panel (inlinePages), so the table is never covered.
        .sheet(isPresented: Binding(get: { mode.listOpen && !inlinePages }, set: { if !inlinePages { mode.listOpen = $0 } })) { EightBallList(mode: mode) }
        .onAppear(perform: handleLaunchFlags)
        // The mode learns that a shot finished from these two; it ignores anything that is not its business.
        .onChange(of: model.aimReady) { _, _ in mode.update() }
        .onChange(of: model.timelineVersion) { _, _ in mode.update() }
        .onChange(of: mode.aimingRequests) { _, _ in shotPanelOpen = mode.wantsAiming }
        .onChange(of: mode.celebrations) { _, _ in
            glow = 1
            withAnimation(.easeOut(duration: reduceMotion ? 0.8 : 1.4)) { glow = 0 }
            // Made-it sound with the glow, the big one for gold (sound-lessons hook, 0.7.0 item 36). lastVerdict is set
            // before the medal bumps celebrations (EightBallMode.finishJudging), so it is this medal's verdict.
            SoundBoard.play(GameMoment.medal(mode.lastVerdict?.medal))
        }
    }

    /// -eightList opens the list over the menu; -eight <id> sets a situation up. Once per launch.
    private func handleLaunchFlags() {
        // Once per launch: the layer is rebuilt when the screen switches between its narrow and wide layouts.
        guard !Self.launchHandled else { return }
        Self.launchHandled = true
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-eight"), i + 1 < args.count { mode.begin(id: args[i + 1]) }
        // After begin, which closes the list, so -eight <id> -eightList shows the list over that situation's table.
        // A moment late, for the same reason as -trickList: on a folding phone the layout changes a beat after launch.
        if args.contains("-eightList") {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.2))
                mode.listOpen = true
            }
        }
        // Store-screenshot routes, after -eight: -eightAim lines an escape up with its call made; -eightWatch plays it as
        // the hint, with the ride camera.
        for flag in ["-eightAim", "-eightWatch"] {
            if let i = args.firstIndex(of: flag), i + 1 < args.count, let s = mode.current,
               let escape = s.escapes.first(where: { $0.id == args[i + 1] }) {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.5))
                    if flag == "-eightAim" { mode.playAsTry(escape, shoot: false) } else { mode.watch(escape) }
                }
            }
        }
        // -eightPlay <escape id>, after -eight: shoot that escape as a judged try, a moment after the table settles.
        if let i = args.firstIndex(of: "-eightPlay"), i + 1 < args.count, let s = mode.current,
           let escape = s.escapes.first(where: { $0.id == args[i + 1] }) {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                // -eightRide: watch the try from the ride camera (the store's opening shot).
                if args.contains("-eightRide") { model.setRide(true) }
                mode.playAsTry(escape)
                // -eightRealTable: once the try is scored, turn the card over to "On a real table".
                guard args.contains("-eightRealTable") else { return }
                for _ in 0..<120 {
                    try? await Task.sleep(for: .seconds(0.25))
                    if case .scored = mode.phase { mode.showingRealTable = true; return }
                }
            }
        }
        // -eightJudgeCheck: the acceptance check. Every authored escape is solved and judged off the main thread
        // and each line goes to the log, so a change to the judge or a layout shows up as a FAIL line.
        if args.contains("-eightJudgeCheck") {
            // The lines also go to EightBallCheck.txt in the app's Documents folder, which survives a quiet log.
            Task.detached {
                let lines = EightBallJudge.selfCheck() + EightBallJudge.checkAuthoredEscapes() + ["done"]
                for line in lines { NSLog("EightBallCheck: %@", line) }
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("EightBallCheck.txt")
                try? lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func projector(size: CGSize) -> AimProjector? {
        guard let root = bridge.table?.root else { return nil }
        return AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
    }

    /// A tap while calling: the nearest ball or pocket on screen within a finger's reach. After a ball is picked a
    /// pocket wins when it is nearer than any ball, so a ball sitting in the jaws can still be re-picked by tapping it.
    private func tap(at point: CGPoint, in size: CGSize) {
        guard model.aimReady, model.layout.count == 16, let proj = projector(size: size) else { return }
        let table = model.timeline.table
        func distance(_ p: Vec2, height: Float? = nil) -> CGFloat? {
            proj.screen(p, height: height).map { hypot($0.x - point.x, $0.y - point.y) }
        }
        // A ball's size on screen sets how far from it a tap still counts (never under a fingertip's 30 points).
        var ballReach: CGFloat = 30
        if let c = proj.screen(model.layout[0]), let e = proj.screen(model.layout[0] + Vec2(table.ballRadius, 0)) {
            ballReach = max(30, hypot(c.x - e.x, c.y - e.y) * 2.4)
        }
        var ball: (number: Int, distance: CGFloat)?
        for b in 1..<16 where NextShot.isOnTable(model.layout[b]) {
            if let d = distance(model.layout[b]), d <= ballReach, d < (ball?.distance ?? .infinity) { ball = (b, d) }
        }
        var pocket: (index: Int, distance: CGFloat)?
        if mode.pendingBall != nil {
            for k in table.pockets.indices {
                if let d = distance(table.pockets[k], height: 0.001), d <= max(44, ballReach * 1.6),
                   d < (pocket?.distance ?? .infinity) { pocket = (k, d) }
            }
        }
        if let p = pocket, p.distance < (ball?.distance ?? .infinity), let named = EightBallPocket(rawValue: p.index) {
            mode.pick(pocket: named)
        } else if let b = ball {
            mode.pick(ball: b.number)
        }
    }

    /// Strong rings on the called (or picked) ball and pocket; faint ones on what can be tapped next.
    private func drawMarks(_ ctx: inout GraphicsContext, size: CGSize) {
        guard let marks = mode.marks, model.aimReady, model.layout.count == 16, let proj = projector(size: size)
        else { return }
        let table = model.timeline.table
        let accent = palette.accent
        func ring(_ centre: Vec2, _ radius: Double) -> Path? {
            var path = Path()
            for i in 0..<40 {
                let a = Double(i) / 40 * 2 * Double.pi
                guard let s = proj.screen(centre + Vec2(cos(a), sin(a)) * radius, height: 0.001) else { return nil }
                if i == 0 { path.move(to: s) } else { path.addLine(to: s) }
            }
            path.closeSubpath()
            return path
        }
        for k in marks.faintPockets where k < table.pockets.count {
            if let p = ring(table.pockets[k], table.pocketCaptureRadius[k] + 0.012) {
                ctx.stroke(p, with: .color(accent.opacity(0.55)), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
        }
        for k in marks.pockets where k < table.pockets.count {
            if let p = ring(table.pockets[k], table.pocketCaptureRadius[k] + 0.012) {
                ctx.stroke(p, with: .color(accent.opacity(0.35)), style: StrokeStyle(lineWidth: 7))
                ctx.stroke(p, with: .color(accent), style: StrokeStyle(lineWidth: 2))
            }
        }
        for b in marks.faintBalls where b < 16 && NextShot.isOnTable(model.layout[b]) {
            if let p = ring(model.layout[b], table.ballRadius * 1.45) {
                ctx.stroke(p, with: .color(accent.opacity(0.6)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
        }
        for b in marks.balls where b < 16 && NextShot.isOnTable(model.layout[b]) {
            if let p = ring(model.layout[b], table.ballRadius * 1.5) {
                ctx.stroke(p, with: .color(accent.opacity(0.35)), style: StrokeStyle(lineWidth: 6))
                ctx.stroke(p, with: .color(accent), style: StrokeStyle(lineWidth: 2))
            }
        }
    }
}
