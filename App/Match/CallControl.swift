// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 5, the mode frame: the ball chips are the kit's
//          chips and wrap onto more lines instead of scrolling sideways; the six pockets are chips too (CallPocketChips),
//          the chosen one selected; Safety is a secondary button and "Call it" the call's one primary (the kit's cyan
//          capsule, also on the upright phone's call row); the pocket menu is a secondary button; the refusal's pulse
//          outline takes the kit's small corners.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 5's leftover note: CallChipWrap lays out
//          through the one shared WrappingRow (Surfaces.swift) from the leading edge instead of its own copy of the
//          wrapping code; the chips sit as before, and a chip wider than the line now fits inside it.)
// PURPOSE: Calling a ball and a pocket, shared by Behind the 8-Ball and the eight-ball match.
//          CallBallChips    - the callable balls as the kit's chips, wrapping, the picked one selected. The complete
//                             route for VoiceOver and the keyboard; tapping the table is only the quick route.
//          CallPocketChips  - the six pockets as chips, the chosen one selected (the match's call and the 8-ball card).
//          CallPocketMenu   - the six pockets by name in a menu (the upright phone's 8-ball blurb).
//          CallSafetyButton - "Safety": no ball, just a legal hit.
//          MatchCallControl - the match's whole call: it keeps the two-step pick (ball, then pocket) itself, because
//                             MatchMode only stores the finished call (setCall). It pre-selects the ball the cue is
//                             pointed at and the pocket nearest that ball's path, so one tap on "Call it" confirms an
//                             obvious shot (rules plan, package 3: "obvious shots still need the call").
//          The three small pieces take plain values and closures, so the 8-ball card drives them from EightBallMode
//          (pendingBall, pick, callSafety) and the match drives them from its own state: one control, two callers.
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 13 and 43: the suggestion moved to the match
//          (MatchMode.suggestedCall), so the model can play a stroke made with no call on the same suggestion this card
//          shows; when a stroke is refused for want of a call (no suggestion either), the card pulses and says "Call
//          your shot first" on the table and to VoiceOver (ShowpieceModel.lastRefusal and refusalSerial); the row of
//          Safety, the pocket and Call it uses the cards' row-or-column helper (CardButtonRow), so at the largest text
//          sizes it becomes a column instead of cutting off the pocket's name.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, plans/22-Nov-2026-phone-ui-plan.md "The aiming
//          panel": MatchCallRow, the upright phone's call row, which takes the aiming panel's second row while a call is
//          due: Safety, one menu holding the ball and the pocket (its label the call so far), and "Call it" as the
//          white capsule. The pick-and-suggestion rules moved into MatchCallChoice so MatchCallControl and the row read
//          the same ones; MatchCallControl looks and behaves exactly as before.)
// SRP/DRY check: Pass - moved out of EightBallViews.swift (its private ballChips and pocketMenu are now these views);
//          the suggestion is MatchMode's (the same ray cast the aim guide draws), the pocket words EightBallPocket.title,
//          the refusal sentence ShotRefusal's, the button row MatchViews' CardButtonRow. Nothing here decides
//          legality: the rules (mayCall) do.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import SwiftUI

// MARK: The small shared pieces

/// The glass button adds its own padding; this lands the buttons on 44 points or more on a touch screen (the same
/// number the trick-shot and 8-ball cards used). Still read by the cards outside the mode frame (ClipViews,
/// WhatIfViews), whose own packages move them onto the kit.
enum CallMetrics {
    #if os(iOS)
    static let buttonHeight: CGFloat = 30
    #else
    static let buttonHeight: CGFloat = 0
    #endif
}

/// The callable balls as the kit's chips, wrapping onto more lines when they do not fit (never a sideways scroll that
/// hides some of them); the picked ball is the selected chip (the cyan edge). Each chip is a button with a 44 point hit
/// area, named "Ball 3" for VoiceOver, with the selected trait on the picked one.
struct CallBallChips: View {
    let balls: [Int]
    let picked: Int?
    let pick: (Int) -> Void

    var body: some View {
        if !balls.isEmpty {
            CallChipWrap(spacing: Theme.Space.xs, lineSpacing: Theme.Space.xxs) {
                ForEach(balls, id: \.self) { b in
                    let isPicked = picked == b
                    Button { pick(b) } label: {
                        Chip(value: b.formatted(.number.locale(AppLocale.numbers)), selected: isPicked)
                            .frame(minWidth: Theme.Size.minHit, minHeight: Theme.Size.minHit)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Ball \(b)"))
                    .accessibilityAddTraits(isPicked ? .isSelected : [])
                }
            }
        }
    }
}

/// The six pockets as word chips, wrapping like the balls; the chosen pocket is the selected chip (UI rethink package 5:
/// the chosen pocket shows as a chip, not as the label of a prominent menu).
struct CallPocketChips: View {
    let picked: EightBallPocket?
    let pick: (EightBallPocket) -> Void

    var body: some View {
        CallChipWrap(spacing: Theme.Space.xs, lineSpacing: Theme.Space.xxs) {
            ForEach(EightBallPocket.allCases, id: \.self) { p in
                let isPicked = picked == p
                Button { pick(p) } label: {
                    Chip(word: p.title, selected: isPicked)
                        .frame(minHeight: Theme.Size.minHit)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(p.title)
                .accessibilityAddTraits(isPicked ? .isSelected : [])
            }
        }
    }
}

/// The six pockets by name in a menu (the upright phone's 8-ball blurb). A secondary button now: "Call it" is the one
/// primary of the call.
struct CallPocketMenu: View {
    /// The pocket already picked, shown on the button; nil shows the plain "Pocket" label.
    let picked: EightBallPocket?
    let pick: (EightBallPocket) -> Void

    var body: some View {
        Menu {
            ForEach(EightBallPocket.allCases, id: \.self) { p in
                Button { pick(p) } label: {
                    if p == picked { Label(p.title, systemImage: "checkmark") } else { Text(p.title) }
                }
            }
        } label: {
            KitButtonLabel(picked?.title ?? String(localized: "Pocket"), systemImage: "circle.dashed")
        }
        .menuStyle(.button)
        .buttonStyle(.kitSecondary)
        .accessibilityLabel(String(localized: "Pick the pocket"))
        .accessibilityValue(picked?.title ?? "")
    }
}

struct CallSafetyButton: View {
    let action: () -> Void

    var body: some View {
        SecondaryButton(String(localized: "Safety"), systemImage: "shield") { action() }
            .accessibilityHint(String(localized: "Calls a safety: no ball, just a legal hit that leaves your opponent hooked"))
    }
}

/// The chips' layout: left to right from the leading edge, onto a new line when the next chip would not fit. The one
/// wrapping layout (WrappingRow, Surfaces.swift) laid out from the leading edge; this name stays for its callers here
/// and in NotebookInfo.swift. A chip wider than the line is offered the line's width.
struct CallChipWrap: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    private var row: WrappingRow { WrappingRow(alignment: .leading, spacing: spacing, lineSpacing: lineSpacing) }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        row.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        row.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }
}

// MARK: The match's call

/// The call for one match shot. Shown by the match card while MatchMode.mustCall is true (eight-ball after the break;
/// never in nine-ball, whose rules use no calls). The prompt, the callable balls as wrapping chips, the six pockets as
/// chips once a ball is shown (the chosen one selected), then Safety beside "Call it", the one primary.
struct MatchCallControl: View {
    let model: ShowpieceModel
    let match: MatchMode
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var deviceReader = KitDeviceReader()
    /// The ball picked and the pocket picked, before "Call it" hands the finished call to the match. Nil until the
    /// player touches a chip; until then the suggestion from the aim stands in for them.
    @State private var ball: Int?
    @State private var pocket: EightBallPocket?
    /// True for the moments the card flashes after a stroke was refused for want of a call.
    @State private var pulsing = false

    init(model: ShowpieceModel, match: MatchMode) {
        self.model = model
        self.match = match
    }

    private var choice: MatchCallChoice { MatchCallChoice(match: match, ball: ball, pocket: pocket) }
    private var callable: [Int] { choice.callable }
    private var suggestion: (ball: Int, pocket: EightBallPocket)? { choice.suggestion }

    /// A stroke was refused because no call was made and nothing was suggested (the model clears this on the next
    /// accepted strike).
    private var refusedForCall: Bool { model.lastRefusal == .noCall && match.currentCall == nil }

    private var shownBall: Int? { choice.shownBall }
    private var shownPocket: EightBallPocket? { choice.shownPocket }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(verbatim: prompt)
                .font(refusedForCall ? Theme.heading : (deviceReader.current == .phone ? Theme.bodyCompact : Theme.body))
                .foregroundStyle(refusedForCall ? palette.warning : palette.paper)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            SectionLabel(String(localized: "Ball"))
            CallBallChips(balls: callable, picked: shownBall) { b in
                ball = b
                if b != suggestion?.ball { pocket = nil }
            }
            if shownBall != nil {
                SectionLabel(String(localized: "Pocket"))
                CallPocketChips(picked: shownPocket) { pocket = $0 }
            }
            // Safety beside Call it: one row, or a column at the largest text sizes, so nothing is cut off (item 43).
            KitButtonRow(primary: callItAction, secondary: KitAction(String(localized: "Safety"), systemImage: "shield") {
                match.setCall(.safety); ball = nil; pocket = nil
            })
            .modeShortcut(callItAction, .defaultAction)
        }
        // The pulse: an outline in the warning colour that flashes twice (and, unless Reduce Motion is on, the call
        // swells a little), so the eye goes to the call the moment a stroke is refused for want of one.
        .padding(Theme.Space.xxs)
        .background {
            Theme.Corner.tileShape
                .stroke(palette.warning, lineWidth: pulsing ? 3 : 0)
        }
        .scaleEffect(pulsing && !reduceMotion ? 1.03 : 1)
        .onChange(of: model.refusalSerial) { _, _ in
            guard model.lastRefusal == .noCall else { return }
            // The table's line and the screen reader say the same thing.
            AccessibilityNotification.Announcement(ShotRefusal.noCall.sentence).post()
            pulse()
        }
    }

    /// "Call it", once a ball and a pocket are shown (picked or suggested); nil until then.
    private var callItAction: KitAction? {
        guard let b = shownBall, let p = shownPocket else { return nil }
        return KitAction(String(localized: "Call it"), systemImage: "checkmark") {
            match.setCall(.ball(b, pocket: p)); ball = nil; pocket = nil
        }
    }

    /// Two quick flashes of the outline (on the main actor, where the view and its state live).
    @MainActor
    private func pulse() {
        Task { @MainActor in
            for _ in 0..<2 {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) { pulsing = true }
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(reduceMotion ? nil : .easeIn(duration: 0.2)) { pulsing = false }
                try? await Task.sleep(for: .milliseconds(220))
            }
        }
    }

    private var prompt: String {
        if let call = match.currentCall { return MatchWords.callLine(call) }
        // Refused with nothing to suggest: the refusal's own sentence, in the warning colour above.
        if refusedForCall, shownBall == nil { return ShotRefusal.noCall.sentence }
        if let b = shownBall, let p = shownPocket {
            return String(localized: "Suggested call: the \(b), \(p.title).")
        }
        return String(localized: "Call your shot: pick a ball, then a pocket. Or call Safety.")
    }
}

// MARK: The pick, shared

/// The call being put together: the ball and pocket the player has touched (nil until they do) over the suggestion from
/// the aim. Read by MatchCallControl (the card) and MatchCallRow (the upright phone's aiming panel), which each keep
/// their own touched ball and pocket.
@MainActor
struct MatchCallChoice {
    let match: MatchMode
    /// Picked by hand; nil until the player touches a ball or a pocket.
    let ball: Int?
    let pocket: EightBallPocket?

    /// Balls the rules allow the shooter to call now (their group, or the 8 once the group is gone, or any but the 8
    /// while the table is open).
    var callable: [Int] { match.state.ballsLeft.filter { match.rules.mayCall($0, in: match.state) } }

    /// What the cue is pointed at now: MatchMode.suggestedCall, the very call the model plays when a stroke goes
    /// through with no call made, so what is suggested is what the shot is held to.
    var suggestion: (ball: Int, pocket: EightBallPocket)? {
        guard case .ball(let b, let p)? = match.suggestedCall else { return nil }
        return (b, p)
    }

    var shownBall: Int? { ball ?? suggestion?.ball }
    var shownPocket: EightBallPocket? {
        // A pocket picked by hand wins; otherwise the suggestion's pocket, but only while its ball is the one shown.
        if let pocket { return pocket }
        if let s = suggestion, s.ball == shownBall { return s.pocket }
        return nil
    }
}

// MARK: The upright phone's call row

/// The call on the upright phone (plans/22-Nov-2026-phone-ui-plan.md, "The aiming panel"): in the aiming panel's second
/// row while a call is due (PhoneAimPanel shows it in place of the row that holds Shoot, and Shoot comes back once the
/// call is made). Safety; one menu holding the callable balls and, once a ball is chosen, the six pockets, its label
/// the call so far ("3 · Head-left corner"); and "Call it", the white capsule. Drawn as content on the panel's glass
/// (PhonePanelControl), never glass on glass. The prompt and the refusal's words are the panel's status line and the
/// match's own blurb, not this row. The table's taps still pick a ball, through the match, as before.
struct MatchCallRow: View {
    let match: MatchMode
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var ball: Int?
    @State private var pocket: EightBallPocket?

    private var choice: MatchCallChoice { MatchCallChoice(match: match, ball: ball, pocket: pocket) }

    var body: some View {
        let shownBall = choice.shownBall
        let shownPocket = choice.shownPocket
        // One row, Call it at the right; a column when the row does not fit (a long pocket name, the largest text).
        let row = HStack(spacing: Theme.Space.xs) {
            safety
            callMenu(shownBall, shownPocket)
            Spacer(minLength: 0)
            callIt(shownBall, shownPocket)
        }
        let column = VStack(alignment: .leading, spacing: Theme.Space.xs) {
            safety
            callMenu(shownBall, shownPocket)
            callIt(shownBall, shownPocket)
        }
        Group {
            if typeSize.isAccessibilitySize {
                column
            } else {
                ViewThatFits(in: .horizontal) { row; column }
            }
        }
    }

    private var safety: some View {
        Button { match.setCall(.safety); ball = nil; pocket = nil } label: {
            Text("Safety")
                .font(Theme.label)
                .lineLimit(1)
                .padding(.horizontal, Theme.Space.md)
                .frame(minHeight: Theme.Size.minHit)
                .modifier(PhonePanelControl(shape: .capsule))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint(String(localized: "Calls a safety: no ball, just a legal hit that leaves your opponent hooked"))
    }

    /// "Call it": only once a ball and a pocket are shown (picked or suggested).
    @ViewBuilder
    private func callIt(_ shownBall: Int?, _ shownPocket: EightBallPocket?) -> some View {
        if let b = shownBall, let p = shownPocket {
            // The kit's primary capsule (cyan, ground words), the call's one primary, at the phone's 50 points.
            Button { match.setCall(.ball(b, pocket: p)); ball = nil; pocket = nil } label: {
                KitButtonLabel(String(localized: "Call it"))
                    .lineLimit(1)
                    .fixedSize()
            }
            .buttonStyle(.kitPrimary)
            .accessibilityLabel(MatchWords.callLine(.ball(b, pocket: p)))
            .accessibilityHint(String(localized: "Makes this your call for the shot"))
        }
    }

    /// The ball and the pocket in one menu. Its label is the call so far: the ball and pocket, the ball alone, or
    /// "Pocket" before anything is chosen or suggested.
    private func callMenu(_ shownBall: Int?, _ shownPocket: EightBallPocket?) -> some View {
        Menu {
            Section(String(localized: "Ball")) {
                ForEach(choice.callable, id: \.self) { b in
                    Button {
                        ball = b
                        if b != choice.suggestion?.ball { pocket = nil }
                    } label: {
                        if b == shownBall { Label(String(localized: "Ball \(b)"), systemImage: "checkmark") }
                        else { Text(String(localized: "Ball \(b)")) }
                    }
                }
            }
            if shownBall != nil {
                Section(String(localized: "Pocket")) {
                    ForEach(EightBallPocket.allCases, id: \.self) { p in
                        Button { pocket = p } label: {
                            if p == shownPocket { Label(p.title, systemImage: "checkmark") } else { Text(p.title) }
                        }
                    }
                }
            }
        } label: {
            Text(verbatim: menuTitle(shownBall, shownPocket))
                .font(Theme.label)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, Theme.Space.md)
                .frame(minHeight: Theme.Size.minHit)
                .modifier(PhonePanelControl(shape: .capsule))
                .contentShape(Capsule())
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Pick the pocket"))
        .accessibilityValue(menuTitle(shownBall, shownPocket))
    }

    private func menuTitle(_ shownBall: Int?, _ shownPocket: EightBallPocket?) -> String {
        switch (shownBall, shownPocket) {
        case let (b?, p?): return String(localized: "\(b) · \(p.title)")
        case let (b?, nil): return String(localized: "Ball \(b)")
        default: return String(localized: "Pocket")
        }
    }
}
