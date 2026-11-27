// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 5, the mode frame: the list is the kit's sheet
//          page with the kit's list rows (number or medal, title and story, five dots from the hardest way out's rating,
//          best score, cloth and bridge, the start layout drawn small; "Rated up to" is said by the dots now, and by
//          VoiceOver); the card is the kit's mode card in every phase (the try in its status line; calling shows the
//          balls and then the pockets as wrapping chips under "Your call"; the ways out, Back and the list under More)
//          and the kit-style result card once scored (the medal or try on its right, the total with its sum behind
//          More, Next or Try again, the Lens replay and On a real table beside it). The medals' own colours are gone:
//          a medal is pocket gold, its metal in words. The numbers follow NumberStyle (two decimals for a speed under
//          10 m/s, a tip to a tenth of a millimetre, friction to two or three significant figures). No "How forgiving"
//          tiles: a situation has no measured window before a try (the judge measures the player's windows only after a
//          make). The glow follows the screen's own corners.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
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
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 coordinator: what steps aside for the what-if now also steps
//          aside for the every-surface fan, through model.otherFutureShowing.)
// PURPOSE: Everything the player sees of Behind the 8-Ball, modelled on TrickShotViews:
//          EightBallList - the list of situations in a sheet from the menu: number (or the medal won), title, story,
//            best score, the hardest authored way out, the cloth when it is not the standard one, the bridge; the
//            running total and the scoring sentence. With no situations yet it says so plainly.
//          EightBallCard - the kit's mode card at the bottom edge (top of the side column on iPad, Mac and
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
//          The kit's sheet page, list row, mode card, chips and buttons, Dynamic Type (button rows fall back to a
//          column), VoiceOver labels, Reduce Motion (the glow only fades; the card changes without animation).
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// SRP/DRY check: Pass - views only. Flow is EightBallMode, data EightBallSituations, the cloth numbers come from
//          RealTableNumbers and PlaySurface.parameters; projection is AimProjector; the card, rows, chips and sheet are
//          the kit's, the difficulty mapping, start drawing and result card ModeFrameKit's, shared with every mode.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import SwiftUI

// MARK: Numbers

/// Numbers for the cards, through NumberStyle's one rule per unit (UI rethink package 5: an angle one decimal, a speed
/// two decimals under 10 m/s, a tip offset in mm to one decimal). Also read by the upright phone's real-table blurb.
enum EightBallFormat {
    /// `x` with `places` decimals in the game's number language (NumberStyle.decimal).
    static func decimal(_ x: Double, _ places: Int) -> String { NumberStyle.decimal(x, places: places) }

    static func degrees(_ x: Double) -> String { NumberStyle.angle(degrees: x).text }
    static func speed(_ x: Double) -> String { NumberStyle.speed(metresPerSecond: x).text }

    /// The cue angle as words: level, or the angle above level (shared with the cue-angle menu).
    static func cueAngle(_ degrees: Double) -> String { CueAngleMenu.words(degrees: degrees) }

    /// Tip offsets in millimetres to one decimal (NumberStyle.tipOffset's precision), "centre" when both round to zero.
    static func tip(up: Double, side: Double) -> String {
        var parts: [String] = []
        let u = NumberStyle.decimal(abs(up) * 1000, places: 1), s = NumberStyle.decimal(abs(side) * 1000, places: 1)
        let zero = NumberStyle.decimal(0, places: 1)
        if u != zero { parts.append(up > 0 ? String(localized: "\(u) mm above") : String(localized: "\(u) mm below")) }
        if s != zero { parts.append(side > 0 ? String(localized: "\(s) mm right") : String(localized: "\(s) mm left")) }
        return parts.isEmpty ? String(localized: "Centre") : parts.formatted(.list(type: .and).locale(AppLocale.numbers))
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
        if v.fouled { return v.fouls.map(\.title).formatted(.list(type: .and).locale(AppLocale.numbers)) + "." }
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
            out.append(String(localized: "Style: \(v.style.map(\.title).formatted(.list(type: .and).locale(AppLocale.numbers)))."))
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
        // Friction and resistance by NumberStyle's coefficient rule (two or three significant figures), as the card.
        func c(_ x: Double) -> String { NumberStyle.coefficient(x).number }
        let pace = d(RailKeep.pace, 0)
        let keeps = RailKeep.percent(parameters: n.surface.parameters)
        let keepsStd = RailKeep.percent(parameters: std)
        return String(localized: "Cloth: \(n.surface.title). Sliding friction \(c(n.slidingFriction)), standard \(c(std.slidingFriction)). Rolling resistance \(c(n.rollingResistance)), standard \(c(std.rollingResistance)). A ball rolling straight into a rail at \(pace) metres per second keeps \(keeps) percent of its speed, standard \(keepsStd) percent.")
    }
}

// MARK: The list

struct EightBallList: View {
    let mode: EightBallMode
    @Environment(\.palette) private var palette
    /// True when the list is a page of the notebook (iPad, Mac, the open Duo) rather than a sheet of its own.
    @Environment(\.inlinePages) private var inlinePages

    var body: some View {
        // UI rethink package 5: the kit's sheet page and list rows, as the trick shots and lessons lists. Done closes
        // the list, as Close did.
        SheetPage(title: String(localized: "Behind the 8-Ball"), onDone: { mode.listOpen = false }) {
            if EightBallSituations.all.isEmpty {
                ContentUnavailableView {
                    Label("No situations yet", systemImage: "8.circle")
                } description: {
                    Text(String(localized: "The tables are still being set up. They will show here when they're ready."))
                }
            } else {
                list
            }
        } footer: {
            if !EightBallSituations.all.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text(String(localized: "Make it as called for 5, plus up to 5 for difficulty and up to 5 for style. A legal miss earns 1. A foul earns nothing. Each retry costs 1."))
                    Text(String(localized: "Bronze for a make, silver at 10, gold at 13."))
                    Text(String(localized: "Why the name? In eight-ball, hitting the 8 first is a foul. In an older pool game, sitting behind the 8 was bad luck."))
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        #if os(macOS)
        // A sheet's own minimum size; as a page of the Mac notebook it takes the panel's size (0.7.5: the minimum
        // pushed the list past the panel's edge). Nil sizes rather than an if, so the view keeps its identity.
        .frame(minWidth: inlinePages ? nil : 460, minHeight: inlinePages ? nil : 560)
        #endif
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            // The one sentence, then the running total in paper (a counter is paper, never a physics colour).
            Text(String(localized: "You're hooked. Call your ball and pocket, then get out."))
                .font(Theme.body)
                .foregroundStyle(palette.paper2)
                .fixedSize(horizontal: false, vertical: true)
            Text(String(localized: "Your total: \(mode.runningTotal)"))
                .font(Theme.label.monospacedDigit())
                .foregroundStyle(palette.paper)
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                ForEach(EightBallSituations.all) { s in
                    Button { mode.begin(s) } label: { row(s) }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(spoken(s))
                        .accessibilityHint(String(localized: "Sets the table up"))
                }
            }
        }
    }

    /// The kit's list row: the number (or the medal, in pocket gold), the title and story, the five dots of its hardest
    /// way out with the best score, the cloth and the bridge, and the start layout drawn small.
    private func row(_ s: EightBallSituation) -> some View {
        let leading: ListRow<DifficultyDots, ModeStartThumb>.Leading = mode.medal(s) != nil ? .medal : .number(s.number)
        return ListRow(leading: leading, title: s.title, line: s.story, best: details(s),
                       difficulty: { DifficultyDots(level: ModeDifficulty.dots(rating: s.topRating)) },
                       picture: { ModeStartThumb(layout: s.setup) })
    }

    /// "Best 9 · Tournament cloth · Bridge" (the difficulty is the dots), or nil when there is nothing to add.
    private func details(_ s: EightBallSituation) -> String? {
        var parts: [String] = []
        if let b = mode.best(s) { parts.append(String(localized: "Best \(b)")) }
        if s.surface != .cloth { parts.append(s.surface.title) }
        if s.usesBridge { parts.append(String(localized: "Bridge")) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
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
    /// On a phone held upright while a guided Lens replay plays (set by ShowpieceView, App/LayoutFlags.swift): the slim
    /// card, heading and main button only, so the table keeps its height. The kit's ModeCard slims itself on the same
    /// flag; this card picks the one action it keeps.
    @Environment(\.lensReplayCompact) private var compact

    private var mode: EightBallMode { model.eightBallMode }

    var body: some View {
        // While the Lens tips are up (the player's own Lens replay of this try) the card stands back, so the tips are
        // the one thing to read; it returns as soon as they are done. While a what-if is open on the try (0.7.5,
        // WhatIfFork.isShowing) its card is the one result card: this one steps aside and comes back when it closes.
        if let s = mode.current, mode.isActive, !model.holdForTips, !model.otherFutureShowing {
            Group {
                if compact { slim(s) } else { content(s) }
            }
            .animation(reduceMotion ? nil : Theme.Motion.standard, value: mode.phase)
            .animation(reduceMotion ? nil : Theme.Motion.standard, value: mode.showingRealTable)
            // The medal's sound and its buzz are played together by SoundBoard (EightBallTableLayer, beside the glow),
            // so the card adds no haptic of its own on top.
            .transition(.opacity)
        }
    }

    /// The situation's name: "3. Hooked behind the 8".
    private func name(_ s: EightBallSituation) -> String { String(localized: "\(s.number). \(s.title)") }

    /// The try in the status line ("Try 2 of 3", or "Practice"): the next try's by default.
    private func status(_ tryNumber: Int? = nil) -> [KitStatusItem] {
        [KitStatusItem(EightBallWords.tryLabel(tryNumber ?? mode.nextTry), figure: "")]
    }

    @ViewBuilder
    private func content(_ s: EightBallSituation) -> some View {
        let dots = ModeDifficulty.dots(rating: s.topRating)
        switch mode.phase {
        case .looking:
            let goal = mode.isAtStart
                ? ([s.story] + (EightBallWords.situationNote(mode, s).map { [$0] } ?? [])).joined(separator: " ")
                : String(localized: "That shot had no call, so it doesn't count. Make your call first.")
            let same = mode.call == nil ? nil
                : KitAction(String(localized: "Same call"), systemImage: "target") { mode.aimWithCall() }
            ModeCard(name: name(s), difficulty: dots, goal: goal, status: status(),
                     primary: callAction, secondary: same, more: watchActions(s) + [listAction])
                .modeShortcut(callAction, .defaultAction)
        case .calling:
            // Your call: the balls you may call as chips, then the six pockets once a ball is picked (picking the
            // pocket makes the call); Safety beside it, Back under More. The table's taps are the quick route.
            ModeCard(name: name(s), difficulty: dots, goal: EightBallWords.callPrompt(mode, s), status: status(),
                     tilesTitle: String(localized: "Your call", comment: "Section label over the ball and pocket chips while calling a shot."),
                     primary: nil,
                     secondary: KitAction(String(localized: "Safety"), systemImage: "shield") { mode.callSafety() },
                     more: [KitAction(String(localized: "Back"), systemImage: "xmark") { mode.cancelCalling() }]) {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    if let n = mode.callNote {
                        Text(verbatim: n)
                            .font(Theme.label)
                            .foregroundStyle(palette.warning)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    CallBallChips(balls: mode.callableBalls, picked: mode.pendingBall) { mode.pick(ball: $0) }
                    if mode.pendingBall != nil {
                        CallPocketChips(picked: nil) { mode.pick(pocket: $0) }
                    }
                }
            }
        case .watching:
            ModeCard(name: name(s), difficulty: dots,
                     goal: String(localized: "Watching a way out. Your style here is now capped at 2."),
                     status: status(),
                     primary: nil,
                     secondary: KitAction(String(localized: "Skip"), systemImage: "forward.end") { mode.skipHint() })
        case .aiming:
            // Lining up: the aiming panel's Shoot is the screen's one primary. No cue-angle menu here (0.7.5): the
            // shot panel's own is the one control.
            ModeCard(name: name(s), difficulty: dots, goal: aimingLine(s), status: status(), primary: nil,
                     secondary: KitAction(String(localized: "Change call"), systemImage: "hand.tap") { mode.startCalling() },
                     more: watchActions(s))
        case .playing:
            ModeCard(name: name(s), difficulty: dots, goal: EightBallWords.callLine(mode), status: status(), primary: nil)
        case .scoring:
            // The judge is working on a background task; the table stays live and the card says so.
            ModeCard(name: name(s), difficulty: dots, goal: EightBallWords.callLine(mode), status: status(),
                     tilesTitle: String(localized: "Scoring…"), primary: nil) {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(String(localized: "Scoring…"))
            }
        case .scored(let v):
            if mode.showingRealTable, let e = mode.escapeForCard(v) {
                realTable(s, e, v)
            } else {
                scorecard(s, v)
            }
        case .off:
            EmptyView()
        }
    }

    /// The call, and the bridge's rule when the ball is out of reach.
    private func aimingLine(_ s: EightBallSituation) -> String {
        var line = EightBallWords.callLine(mode)
        if s.usesBridge {
            line += " " + String(localized: "Too far to reach: the bridge is legal, and touching a ball with it is a foul.")
        }
        return line
    }

    /// The slim card (0.7.5, lensReplayCompact): the situation's name and the one action that moves it on, so the
    /// player's Lens replay on a phone held upright keeps the table its height. After a scored try, Next when it went
    /// as called and Try again otherwise; the name alone in any other phase. A scored try's replay is named with that
    /// try's number (0.7.6, #41), not the next try's: the slim card drops the status line, so the number joins the name.
    @ViewBuilder
    private func slim(_ s: EightBallSituation) -> some View {
        let dots = ModeDifficulty.dots(rating: s.topRating)
        if case .scored(let v) = mode.phase {
            ModeCard(name: name(s) + " · " + EightBallWords.tryLabel(v.tryNumber), difficulty: dots,
                     goal: EightBallWords.resultTitle(v), primary: v.madeAsCalled ? nextAction : tryAgainAction)
        } else {
            ModeCard(name: name(s), difficulty: dots, goal: s.story, primary: nil)
        }
    }

    // MARK: Scored

    /// The result card: the result in its colour (a foul or a lost game in warning, a make in pocket gold), the medal
    /// or the try on its right, one line on what went wrong (or the judge's sentence when it adds to the title), the
    /// scorecard's notes, the total with its sum behind More, then Next (after a make) or Try again, with the Physics
    /// Lens replay, On a real table and the ways out under More.
    private func scorecard(_ s: EightBallSituation, _ v: EightBallVerdict) -> some View {
        let tone: ResultTone = !v.legal || v.fouled ? .foul : (v.madeAsCalled ? .pocketed : .plain)
        let corner = v.medal.map { String(localized: "\($0.title) medal") } ?? EightBallWords.tryLabel(v.tryNumber)
        let lines = (EightBallWords.resultLine(v).map { [$0] } ?? []) + EightBallWords.scoreNotes(mode, v)
        // The sum's terms but the total, each with its name ("difficulty +3"); the total is the score itself.
        let terms = EightBallWords.sumTerms(v).dropLast().map { KitStatusItem($0.label, figure: $0.value) }
        let realTable = mode.escapeForCard(v) == nil ? nil
            : KitAction(String(localized: "On a real table"), systemImage: "book.closed") { mode.showingRealTable = true }
        let more = [realTable].compactMap { $0 } + watchActions(s)
        return Group {
            if v.madeAsCalled {
                ModeResultCard(verdict: EightBallWords.resultTitle(v), tone: tone, corner: corner, lines: lines,
                               score: "\(v.total)", scoreBreakdown: Array(terms),
                               tryAgain: tryAgainAction, next: nextAction, more: [lensAction] + more)
                    .modeShortcut(nextAction, .defaultAction)
            } else {
                ModeResultCard(verdict: EightBallWords.resultTitle(v), tone: tone, corner: corner, lines: lines,
                               score: "\(v.total)", scoreBreakdown: Array(terms),
                               tryAgain: lensAction, next: tryAgainAction, more: more)
                    .modeShortcut(tryAgainAction, .defaultAction)
            }
        }
        .accessibilityHint(EightBallWords.spokenSum(v))
    }

    // MARK: On a real table

    /// "On a real table" in place of the score: where to aim, how to hold the cue, how hard, the tip, the commonest
    /// miss, each in plain words with the solver's figure beside it, and the cloth's numbers next to the standard
    /// cloth's when the situation is set on another cloth. Your score turns the card back.
    private func realTable(_ s: EightBallSituation, _ e: EightBallEscape, _ v: EightBallVerdict) -> some View {
        let c = e.card, n = c.numbers
        let back = KitAction(String(localized: "Your score"), systemImage: "list.number") { mode.showingRealTable = false }
        return ModeResultCard(verdict: String(localized: "On a real table: \(e.title)"), tone: .plain,
                              corner: String(localized: "Rated \(e.rating)"),
                              tryAgain: back, next: v.madeAsCalled ? nextAction : tryAgainAction) {
            VStack(alignment: .leading, spacing: Theme.Space.sm) {
                realRow(String(localized: "Aim"), c.aim, EightBallFormat.degrees(n.aimDegrees))
                realRow(String(localized: "Cue"), c.cue, EightBallFormat.cueAngle(n.elevationDegrees))
                realRow(String(localized: "Speed"), c.speed, EightBallFormat.speed(n.speed))
                realRow(String(localized: "Tip"), nil, EightBallFormat.tip(up: n.tipUp, side: n.tipSide))
                realRow(String(localized: "Common miss"), c.commonMiss, nil)
                if n.surface != .cloth { clothRow(n) }
            }
        }
    }

    /// One row: a section-style label, the plain words, and the solver's figure beside the label (paper, its unit
    /// grey).
    private func realRow(_ label: String, _ words: String?, _ number: String?) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.figureToLabel) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: label).font(Theme.label).foregroundStyle(palette.paper2)
                Spacer(minLength: Theme.Space.xs)
                if let number, words != nil {
                    KitFigure(text: number, size: .inline)
                }
            }
            if let words {
                Text(verbatim: words).font(Theme.body).foregroundStyle(palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let number {
                Text(verbatim: number).font(Theme.body).foregroundStyle(palette.paper)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// This cloth's numbers next to the standard cloth's, so the player sees why their table plays differently. The
    /// rails are said as what a ball rolling straight in at a stated pace keeps (RailKeep, the solver's rail rules),
    /// not as the raw restitution, which the tuned rail no longer makes equal to what a ball gets back.
    private func clothRow(_ n: RealTableNumbers) -> some View {
        let std = PlaySurface.cloth.parameters
        let pace = EightBallFormat.decimal(RailKeep.pace, 0)
        let keeps = RailKeep.percent(parameters: n.surface.parameters)
        let keepsStd = RailKeep.percent(parameters: std)
        func percent(_ p: Int) -> String {
            // The player's own percent style (the sign's place and spacing differ by language).
            (Double(p) / 100).formatted(.percent.locale(AppLocale.numbers).precision(.fractionLength(0)))
        }
        return VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Text(String(localized: "Cloth: \(n.surface.title)")).font(Theme.label).foregroundStyle(palette.paper2)
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: Theme.Space.sm, verticalSpacing: Theme.Space.xxs) {
                GridRow {
                    Text(verbatim: "")
                    Text(verbatim: n.surface.title).font(Theme.caption).foregroundStyle(palette.paper2)
                    Text(String(localized: "Standard")).font(Theme.caption).foregroundStyle(palette.paper2)
                }
                GridRow {
                    Text(String(localized: "Sliding friction")).font(Theme.caption).foregroundStyle(palette.paper)
                    KitFigure(NumberStyle.coefficient(n.slidingFriction), size: .inline)
                    KitFigure(NumberStyle.coefficient(std.slidingFriction), size: .inline, color: palette.paper2)
                }
                GridRow {
                    Text(String(localized: "Rolling resistance")).font(Theme.caption).foregroundStyle(palette.paper)
                    KitFigure(NumberStyle.coefficient(n.rollingResistance), size: .inline)
                    KitFigure(NumberStyle.coefficient(std.rollingResistance), size: .inline, color: palette.paper2)
                }
                GridRow {
                    Text(String(localized: "Rail keeps at \(pace) m/s")).font(Theme.caption).foregroundStyle(palette.paper)
                    KitFigure(text: percent(keeps), size: .inline)
                    KitFigure(text: percent(keepsStd), size: .inline, color: palette.paper2)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(EightBallWords.clothSentence(n))
    }

    // MARK: Actions

    private var callAction: KitAction {
        KitAction(String(localized: "Make your call"), systemImage: "hand.tap") { mode.startCalling() }
    }

    private var tryAgainAction: KitAction {
        KitAction(String(localized: "Try again"), systemImage: "arrow.uturn.backward") { mode.tryAgain() }
    }

    private var nextAction: KitAction {
        KitAction(String(localized: "Next"), systemImage: "arrow.forward") { mode.next() }
    }

    private var lensAction: KitAction {
        KitAction(String(localized: "Physics Lens replay"), systemImage: "eye") { mode.lensReplay() }
    }

    private var listAction: KitAction {
        KitAction(String(localized: "All situations"), systemImage: "list.bullet") { mode.listOpen = true }
    }

    /// The hint: watch one of the authored ways out, each named with its rating. Before a make it caps style at 2,
    /// which the card says once watching starts.
    private func watchActions(_ s: EightBallSituation) -> [KitAction] {
        s.escapes.map { e in
            KitAction(String(localized: "\(e.title), rated \(e.rating)"), systemImage: "play", id: "watch-" + e.id) {
                mode.watch(e)
            }
        }
    }
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
            // The screen's own corners (ContainerRelativeShape), not a card's: no corner number of its own.
            ContainerRelativeShape()
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
