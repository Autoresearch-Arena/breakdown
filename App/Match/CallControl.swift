// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Calling a ball and a pocket, shared by Behind the 8-Ball and the eight-ball match.
//          CallBallChips    - the callable balls as round buttons, the picked one highlighted. The complete route for
//                             VoiceOver and the keyboard; tapping the table is only the quick route.
//          CallPocketMenu   - the six pockets by name in a menu.
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
/// number the trick-shot and 8-ball cards use).
enum CallMetrics {
    #if os(iOS)
    static let buttonHeight: CGFloat = 30
    #else
    static let buttonHeight: CGFloat = 0
    #endif
}

struct CallBallChips: View {
    let balls: [Int]
    let picked: Int?
    let pick: (Int) -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        if !balls.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(balls, id: \.self) { b in
                        let isPicked = picked == b
                        chip(b, isPicked: isPicked)
                            .buttonBorderShape(.circle)
                            .accessibilityLabel(String(localized: "Ball \(b)"))
                            .accessibilityAddTraits(isPicked ? .isSelected : [])
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private func chip(_ b: Int, isPicked: Bool) -> some View {
        let button = Button { pick(b) } label: {
            Text("\(b)").font(.headline.monospacedDigit())
                .frame(minWidth: 30, minHeight: CallMetrics.buttonHeight)
        }
        if isPicked {
            // Dark text on the bright accent, as every prominent button in the app.
            button.buttonStyle(.glassProminent).foregroundStyle(palette.ground)
        } else {
            button.buttonStyle(.glass)
        }
    }
}

struct CallPocketMenu: View {
    /// The pocket already picked, shown on the button; nil shows the plain "Pocket" label.
    let picked: EightBallPocket?
    let pick: (EightBallPocket) -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        Menu {
            ForEach(EightBallPocket.allCases, id: \.self) { p in
                Button { pick(p) } label: {
                    if p == picked { Label(p.title, systemImage: "checkmark") } else { Text(p.title) }
                }
            }
        } label: {
            Label(picked?.title ?? String(localized: "Pocket"), systemImage: "circle.dashed").font(.headline).lineLimit(1)
                .frame(minHeight: CallMetrics.buttonHeight)
        }
        .buttonStyle(.glassProminent)
        .foregroundStyle(palette.ground)
        .accessibilityLabel(String(localized: "Pick the pocket"))
        .accessibilityValue(picked?.title ?? "")
    }
}

struct CallSafetyButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Safety", systemImage: "shield").font(.headline).lineLimit(1)
                .frame(minHeight: CallMetrics.buttonHeight)
        }
        .buttonStyle(.glass)
        .accessibilityHint(String(localized: "Calls a safety: no ball, just a legal hit that leaves your opponent hooked"))
    }
}

// MARK: The match's call

/// The call for one match shot. Shown by the turn banner while MatchMode.mustCall is true (eight-ball after the break;
/// never in nine-ball, whose rules use no calls).
struct MatchCallControl: View {
    let model: ShowpieceModel
    let match: MatchMode
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The ball picked and the pocket picked, before "Call it" hands the finished call to the match. Nil until the
    /// player touches a chip or the pocket menu; until then the suggestion from the aim stands in for them.
    @State private var ball: Int?
    @State private var pocket: EightBallPocket?
    /// True for the moments the card flashes after a stroke was refused for want of a call.
    @State private var pulsing = false

    /// Balls the rules allow the shooter to call now (their group, or the 8 once the group is gone, or any but the 8
    /// while the table is open).
    private var callable: [Int] { match.state.ballsLeft.filter { match.rules.mayCall($0, in: match.state) } }

    /// What the cue is pointed at now: MatchMode.suggestedCall, the very call the model plays when a stroke goes
    /// through with no call made, so what this card suggests is what the shot is held to.
    private var suggestion: (ball: Int, pocket: EightBallPocket)? {
        guard case .ball(let b, let p)? = match.suggestedCall else { return nil }
        return (b, p)
    }

    /// A stroke was refused because no call was made and nothing was suggested (the model clears this on the next
    /// accepted strike).
    private var refusedForCall: Bool { model.lastRefusal == .noCall && match.currentCall == nil }

    private var shownBall: Int? { ball ?? suggestion?.ball }
    private var shownPocket: EightBallPocket? {
        // A pocket picked by hand wins; otherwise the suggestion's pocket, but only while its ball is the one shown.
        if let pocket { return pocket }
        if let s = suggestion, s.ball == shownBall { return s.pocket }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(prompt)
                .font(refusedForCall ? Theme.heading : Theme.body)
                .foregroundStyle(refusedForCall ? palette.slide : palette.paper.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            CallBallChips(balls: callable, picked: shownBall) { b in
                ball = b
                if b != suggestion?.ball { pocket = nil }
            }
            // Safety, the pocket and Call it: one row, or a column at the largest text sizes, so the pocket's name is
            // never cut off (item 43).
            CardButtonRow {
                CallSafetyButton { match.setCall(.safety); ball = nil; pocket = nil }
                if shownBall != nil {
                    CallPocketMenu(picked: shownPocket) { pocket = $0 }
                }
                if let b = shownBall, let p = shownPocket {
                    Button { match.setCall(.ball(b, pocket: p)); ball = nil; pocket = nil } label: {
                        Label("Call it", systemImage: "checkmark").font(.headline).lineLimit(1)
                            .frame(minHeight: CallMetrics.buttonHeight)
                    }
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(palette.ground)
                    .accessibilityLabel(MatchWords.callLine(.ball(b, pocket: p)))
                    .accessibilityHint(String(localized: "Makes this your call for the shot"))
                }
            }
        }
        // The pulse: an outline in the warning colour that flashes twice (and, unless Reduce Motion is on, the card
        // swells a little), so the eye goes to the call the moment a stroke is refused for want of one.
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.slide, lineWidth: pulsing ? 3 : 0)
        }
        .scaleEffect(pulsing && !reduceMotion ? 1.03 : 1)
        .onChange(of: model.refusalSerial) { _, _ in
            guard model.lastRefusal == .noCall else { return }
            // The table's line and the screen reader say the same thing.
            AccessibilityNotification.Announcement(ShotRefusal.noCall.sentence).post()
            pulse()
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
