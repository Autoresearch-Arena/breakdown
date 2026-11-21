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
// SRP/DRY check: Pass - moved out of EightBallViews.swift (its private ballChips and pocketMenu are now these views);
//          the aim's first ball comes from AimGeometry.firstContact, the same ray cast the aim guide draws, and the
//          pocket words from EightBallPocket.title. Nothing here decides legality: the rules (mayCall) do.
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
    /// The ball picked and the pocket picked, before "Call it" hands the finished call to the match. Nil until the
    /// player touches a chip or the pocket menu; until then the suggestion from the aim stands in for them.
    @State private var ball: Int?
    @State private var pocket: EightBallPocket?

    /// Balls the rules allow the shooter to call now (their group, or the 8 once the group is gone, or any but the 8
    /// while the table is open).
    private var callable: [Int] { match.state.ballsLeft.filter { match.rules.mayCall($0, in: match.state) } }

    /// What the cue is pointed at now: the first ball on the aim line, if it may be called, and the pocket nearest
    /// the line that ball would leave along (the same right-angle guide the aim line draws).
    private var suggestion: (ball: Int, pocket: EightBallPocket)? {
        guard model.layout.count == 16, NextShot.isOnTable(model.aimOrigin) else { return nil }
        let table = model.timeline.table
        guard let hit = AimGeometry.firstContact(layout: model.layout, from: model.aimOrigin,
                                                 direction: model.aimDirection, radius: table.ballRadius),
              callable.contains(hit.ball), let k = Self.nearestPocket(from: hit.target, along: hit.objectDirection,
                                                                     pockets: table.pockets),
              let named = EightBallPocket(rawValue: k) else { return nil }
        return (hit.ball, named)
    }

    /// The pocket whose centre lies closest to the line a ball leaves along, counting only pockets ahead of it. Nil
    /// when no pocket is ahead (the ball is heading straight for a cushion with no pocket on that side).
    static func nearestPocket(from start: Vec2, along direction: Vec2, pockets: [Vec2]) -> Int? {
        var best: (k: Int, miss: Double)?
        for (k, p) in pockets.enumerated() {
            let d = p - start
            let ahead = d.dot(direction)
            guard ahead > 0 else { continue }
            // Sideways distance from the line to the pocket's centre.
            let miss = (d.lengthSquared - ahead * ahead).squareRoot()
            if best == nil || miss < best!.miss { best = (k, miss) }
        }
        return best?.k
    }

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
                .font(Theme.body)
                .foregroundStyle(palette.paper.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            CallBallChips(balls: callable, picked: shownBall) { b in
                ball = b
                if b != suggestion?.ball { pocket = nil }
            }
            HStack(spacing: 8) {
                Spacer(minLength: 0)
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
            .controlSize(.regular)
        }
    }

    private var prompt: String {
        if let call = match.currentCall { return MatchWords.callLine(call) }
        if let b = shownBall, let p = shownPocket {
            return String(localized: "Suggested call: the \(b), \(p.title).")
        }
        return String(localized: "Call your shot: pick a ball, then a pocket. Or call Safety.")
    }
}
