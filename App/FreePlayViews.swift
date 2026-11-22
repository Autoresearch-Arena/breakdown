// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md item 9: any ball
//          can be placed in free play, so the "No rack: place the balls" setup can be played. The card follows the
//          lifted ball (ShowpieceModel.placingBall), not only the cue ball: it names it ("Move the 5"), its legality is
//          checked for that ball, and Place it and Cancel put it down or back. On that setup, with nothing lifted, a
//          short card says how to pick a ball up. The touch and pointer lift live in AimOverlay and PointerAim, through
//          ShowpieceModel.liftableBall.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hook, 0.7.0 item 47: the placement and Table cleared announcements go
//          through the one speaker, ShotNarration.announce.)
// PURPOSE: The play cards that belong to free play and to matches, hosted together as PlayCards beside the trick-shot
//          and 8-ball cards (ShowpieceView above the controls or in the side column, DuoPanel in the notebook panel):
//            BallInHandCard  - while the cue ball is in hand (after a scratch in free play, after a foul in a match) or
//                              lifted with "Move cue ball": what to do, whether the spot under it is free in plain
//                              words ("Touching the 5"), Place it, and Cancel when moving it was the player's own
//                              idea. For VoiceOver it is the complete route: Move up, down, left and right actions
//                              (one ball radius a step, in table directions as seen from the head end) and the spot
//                              spoken as distances from the head cushion and the nearer long cushion.
//            TableClearedCard - free play with only the cue ball left: how many shots it took, Rack again, Menu.
//            MatchCard        - the match card (MatchViews.swift).
//          The drag that moves the lifted ball lives in AimOverlay (a small addition there); the red tint and the head
//          line are drawn by PlayTableLayer. Legality is asked of the package (NextShot.placement), the same check the
//          model uses when the ball is put down, so the card and the table never disagree with the model.
// SRP/DRY check: Pass - checked ShotPanel (Move cue ball, Undo and the rack choice live in its More menu, which calls
//          the same model methods), TrickShotCard and EightBallCard (the card pieces follow theirs), and the model
//          contract in docs/award-batch-contracts.md section 2.1 (every model name used here is from it).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import SwiftUI

/// Every free-play and match card, flattened into whatever stack hosts it (a Group, so the host's own spacing applies
/// and an absent card takes no room).
struct PlayCards: View {
    let model: ShowpieceModel

    var body: some View {
        Group {
            PlaceBallsCard(model: model)
            BallInHandCard(model: model)
            TableClearedCard(model: model)
            MatchCard(model: model)
        }
    }
}

// MARK: Ball in hand

/// Shared reading of the lifted cue ball, for the card and the table layer: where it is, which ball it is, and whether
/// that spot is legal.
@MainActor
enum CueBallPlacement {
    /// The ball being placed: while one is lifted, that ball (any ball in free play, item 9); otherwise the match's
    /// striking ball (another table may strike a different one), else the cue ball.
    static func cueIndex(_ model: ShowpieceModel) -> Int {
        model.placingCueBall ? model.placingBall : (model.match?.cueBallIndex ?? 0)
    }

    /// True while the lifted ball is an object ball rather than the ball the player strikes.
    static func liftedObjectBall(_ model: ShowpieceModel) -> Bool {
        model.placingCueBall && model.placingBall != (model.match?.cueBallIndex ?? 0)
    }

    /// Where the lifted ball is now: the candidate once it has moved, else where the ball sits, else the head spot
    /// (a quarter of the length from the head cushion, across the middle: where NextShot re-spots a scratch).
    static func spot(_ model: ShowpieceModel) -> Vec2 {
        if let c = model.cueBallCandidate { return c }
        let i = cueIndex(model)
        if model.layout.indices.contains(i), NextShot.isOnTable(model.layout[i]) { return model.layout[i] }
        let t = model.timeline.table
        return Vec2(t.length * 0.25, t.width * 0.5)
    }

    /// The package's verdict on a spot, with the table the shot on screen was solved on.
    static func legality(of point: Vec2, _ model: ShowpieceModel) -> CueBallSpot {
        NextShot.placement(of: point, cueBall: cueIndex(model), among: model.layout,
                           behindHeadLine: model.ballInHand == .behindHeadLine,
                           parameters: model.solvedTable.parameters)
    }

    /// The verdict in words; nil for a legal spot.
    static func problem(_ s: CueBallSpot) -> String? {
        switch s {
        case .legal: return nil
        case .overlapsBall(let b): return String(localized: "Touching the \(b)")
        case .offBed: return String(localized: "Off the cloth")
        case .onFeature: return String(localized: "On a hole, post or pin")
        case .outsideHeadArea: return String(localized: "Past the head line")
        @unknown default: return String(localized: "Not a legal spot")
        }
    }
}

struct BallInHandCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize

    /// Shown while the ball is lifted, and while ball in hand is owed but the player has not picked it up yet.
    private var visible: Bool {
        model.placingCueBall || (model.ballInHand != .none && model.aimReady && !model.tableCleared)
    }

    var body: some View {
        if visible {
            let spot = CueBallPlacement.spot(model)
            let problem = model.placingCueBall ? CueBallPlacement.problem(CueBallPlacement.legality(of: spot, model)) : nil
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill").foregroundStyle(palette.accent).accessibilityHidden(true)
                    Text(heading).font(Theme.heading)
                }
                .accessibilityAddTraits(.isHeader)
                Text(instructions)
                    .font(Theme.body)
                    .foregroundStyle(palette.paper.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if model.placingCueBall {
                    // The spot under the ball. Red words AND an icon, so it never depends on colour alone.
                    Label(problem ?? String(localized: "Free spot"),
                          systemImage: problem == nil ? "checkmark.circle" : "xmark.octagon")
                        .font(Theme.label)
                        .foregroundStyle(problem == nil ? palette.accent : Color.red)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(objectBall ? MatchWords.balls([model.placingBall]) : String(localized: "Cue ball"))
                        .accessibilityValue(spoken(spot, problem: problem))
                        .accessibilityHint(String(localized: "Use the actions to move it. Up is toward the foot of the table, seen from the head end."))
                        .accessibilityAction(named: String(localized: "Move up")) { nudge(Vec2(1, 0)) }
                        .accessibilityAction(named: String(localized: "Move down")) { nudge(Vec2(-1, 0)) }
                        .accessibilityAction(named: String(localized: "Move left")) { nudge(Vec2(0, 1)) }
                        .accessibilityAction(named: String(localized: "Move right")) { nudge(Vec2(0, -1)) }
                }
                buttons
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .tint(palette.accent)
            .transition(.opacity)
        }
    }

    /// True while the lifted ball is an object ball (free play's place-balls setup, or arranging a practice shot).
    private var objectBall: Bool { CueBallPlacement.liftedObjectBall(model) }

    private var heading: String {
        if objectBall { return String(localized: "Move the \(model.placingBall)") }
        return model.ballInHand == .none ? String(localized: "Move the cue ball") : String(localized: "Ball in hand")
    }

    private var instructions: String {
        guard model.placingCueBall else { return String(localized: "Pick up the cue ball and put it anywhere free.") }
        if objectBall { return String(localized: "Drag the \(model.placingBall) to a free spot, then let go.") }
        return model.ballInHand == .behindHeadLine
            ? String(localized: "Drag the cue ball to a free spot behind the head line, then let go.")
            : String(localized: "Drag the cue ball to a free spot, then let go.")
    }

    @ViewBuilder
    private var buttons: some View {
        let row = Group {
            if model.placingCueBall {
                // Cancel only when lifting it was the player's own choice; owed ball in hand must be placed.
                if model.ballInHand == .none {
                    Button { model.cancelPlacement() } label: {
                        Text("Cancel").font(.headline).lineLimit(1).frame(minHeight: CallMetrics.buttonHeight)
                    }
                    .buttonStyle(.glass)
                }
                Button { place() } label: {
                    Label(String(localized: "Place it"), systemImage: "checkmark").font(.headline).lineLimit(1)
                        .frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glassProminent)
                .foregroundStyle(palette.ground)
                .keyboardShortcut(.defaultAction)
            } else {
                Button { model.beginPlacingCueBall() } label: {
                    Label(String(localized: "Pick up the cue ball"), systemImage: "hand.raised").font(.headline)
                        .lineLimit(1).frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glassProminent)
                .foregroundStyle(palette.ground)
            }
        }
        if typeSize.isAccessibilitySize {
            VStack(alignment: .trailing, spacing: 8) { row }.frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            HStack(spacing: 8) { Spacer(minLength: 0); row }.controlSize(.regular)
        }
    }

    /// Put the ball down; if the spot is not legal it stays lifted and VoiceOver hears why.
    private func place() {
        if !model.confirmCueBallPlacement() {
            let why = CueBallPlacement.problem(CueBallPlacement.legality(of: CueBallPlacement.spot(model), model))
            ShotNarration.announce(why ?? String(localized: "Not a legal spot"))
        }
    }

    /// One VoiceOver step: one ball radius along a table direction (x toward the foot, y toward the left long
    /// cushion as seen from the head end). A radius is small enough to slip a ball past a neighbour and large enough
    /// that a third of the table's width is about fifteen steps.
    private func nudge(_ direction: Vec2) {
        let r = model.timeline.table.ballRadius
        let spot = model.moveCueBallCandidate(to: CueBallPlacement.spot(model) + direction * r)
        let at = CueBallPlacement.spot(model)
        ShotNarration.announce(spoken(at, problem: CueBallPlacement.problem(spot)))
    }

    /// "38 centimetres from the head cushion and 20 centimetres from the left cushion. Touching the 5."
    private func spoken(_ p: Vec2, problem: String?) -> String {
        let t = model.timeline.table
        func length(_ m: Double) -> String {
            Measurement(value: (max(0, m) * 100).rounded(), unit: UnitLength.centimeters)
                .formatted(.measurement(width: .wide, usage: .asProvided))
        }
        // The nearer long cushion is the one named: y = 0 is the right-hand cushion seen from the head end.
        let place = p.y > t.width / 2
            ? String(localized: "\(length(p.x)) from the head cushion and \(length(t.width - p.y)) from the left cushion")
            : String(localized: "\(length(p.x)) from the head cushion and \(length(p.y)) from the right cushion")
        return [place, problem ?? String(localized: "Free spot")].joined(separator: ". ")
    }
}

// MARK: Place the balls

/// Free play's "No rack: place the balls" with nothing lifted: one short card saying how to arrange the row of balls.
/// It steps aside while a ball is lifted (the ball-in-hand card above takes over) and once the first shot is played.
struct PlaceBallsCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette

    private var visible: Bool {
        model.match == nil && model.freePlayRack == .placeBalls && model.shotsThisRack == 0 && model.aimReady
            && !model.placingCueBall && model.ballInHand == .none && !model.tableCleared
            && !model.trickMode.isActive && !model.eightBallMode.isActive && !model.lessonMode.isActive
    }

    var body: some View {
        if visible {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "hand.raised").foregroundStyle(palette.accent).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Place the balls")).font(Theme.heading)
                    Text(String(localized: "Touch or click any ball to pick it up, then drag it where you want it. Place it puts it down."))
                        .font(Theme.body)
                        .foregroundStyle(palette.paper.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .accessibilityElement(children: .combine)
            .transition(.opacity)
        }
    }
}

// MARK: Table cleared

struct TableClearedCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette

    /// Free play only (a match ends with its own result card), once the last shot has played out.
    private var visible: Bool { model.match == nil && model.tableCleared && model.aimReady }

    var body: some View {
        // The haptic sits on the always-present Group, so the change from hidden to shown is what fires it.
        Group { if visible { card } }
            .sensoryFeedback(trigger: visible) { _, now in now && GameSettings.hapticsOn ? .success : nil }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(palette.accent).accessibilityHidden(true)
                Text(String(localized: "Table cleared")).font(Theme.heading)
            }
            .accessibilityAddTraits(.isHeader)
            Text(shotsLine)
                .font(Theme.body)
                .foregroundStyle(palette.paper.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Button { model.openMenu() } label: {
                    Label("Menu", systemImage: "chevron.backward").font(.headline).lineLimit(1)
                        .frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glass)
                Button { model.rackAgain() } label: {
                    Label(String(localized: "Rack again"), systemImage: "triangle").font(.headline).lineLimit(1)
                        .frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glassProminent)
                .foregroundStyle(palette.ground)
                .keyboardShortcut(.defaultAction)
            }
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22, padding: 12)
        .tint(palette.accent)
        .onAppear { ShotNarration.announce(String(localized: "Table cleared")) }
        .transition(.opacity)
    }

    private var shotsLine: String {
        model.shotsThisRack == 1 ? String(localized: "Cleared in one shot.")
                                 : String(localized: "Cleared in \(model.shotsThisRack) shots.")
    }
}
