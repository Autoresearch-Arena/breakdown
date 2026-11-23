// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 make it again, plans/23-Nov-2026-make-it-again-plan.md F1:
//          HighlightCard's button row starts with Make it again / Play it now (MakeItAgainButton, OwnShotViews.swift).)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, Part 4 step 5: no change on screen. The rules the
//          upright phone's blurbs (FreePlayPhoneBlurbs.swift) share with these cards are lifted out so the two never
//          disagree: when each card shows (BallInHandCard.isVisible, PlaceBallsCard.isVisible,
//          TableClearedCard.isVisible), the ball-in-hand words, the VoiceOver moves and the put-down (CueBallPlacement),
//          and the cleared rack's shot count (TableClearedCard.shotsLine).)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream cards, plans/22-Nov-2026-phone-bug-hunt.md #33 and
//          #62: Ball in hand never shows on the computer's turn (its button could do nothing there); "Cleared in %lld
//          shots." is one catalog string with a count, so the catalog gives it real plural forms in every language.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 model-flow, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          stream model-flow item 10: the intro-end card's Practice racks the pool table and opens Your shot, and its
//          Trick shots opens that list alone (model.showList). Table cleared, the highlight card and the intro-end card
//          step aside while a what-if is showing (model.whatIf.isShowing; the what-if card has the slot). On a phone
//          held upright during a guided Lens replay (lensReplayCompact) Table cleared and the highlight card shrink to
//          their heading, so the table keeps its height.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 watch-invite, plans/22-Nov-2026-v074-glow-up-plan.md G3 and
//          G4: two new cards in PlayCards, so they sit in the card slot and never over the table. HighlightCard offers a
//          remarkable free-play shot (ShowpieceModel.highlightCard): its name and physics, Watch it in the Lens, Try the
//          trick shot when allowed, and Close; no sound, no haptic, no praise. IntroEndCard closes Watch the intro with
//          Trick shots and Practice. TableClearedCard gains Watch your best shot and stays up while that replay plays;
//          its made-it sound is played once per rack by the model.)
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
//            TableClearedCard - free play with only the cue ball left: how many shots it took, Rack again, Menu, and
//                              Watch your best shot when the rack had a remarkable shot (kept up while it replays).
//            HighlightCard    - free play after a remarkable shot, at rest: the shot named, its physics in a line,
//                              Watch it in the Lens, Try the trick shot (once per kind, never for a made one), Close.
//                              Gone for good at the first touch of aim, power, spin or cue angle.
//            IntroEndCard     - the end of Watch the intro: a line, Trick shots, Practice and Close.
//            MatchCard        - the match card (MatchViews.swift).
//          The drag that moves the lifted ball lives in AimOverlay (a small addition there); the red tint and the head
//          line are drawn by PlayTableLayer. Legality is asked of the package (NextShot.placement), the same check the
//          model uses when the ball is put down, so the card and the table never disagree with the model.
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 clips, plans/23-Nov-2026-clips-plan.md: ClipCard joins PlayCards,
//          the highlight card gains "Share clip" and the cleared-table card "Share your best shot"; App/Clips decides
//          when and makes the clip.)
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
            HighlightCard(model: model)
            IntroEndCard(model: model)
            ClipCard(model: model)  // 0.7.7 clips: making, ready or failed (App/Clips/ClipViews.swift)
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

    // MARK: Words and moves (shared by BallInHandCard and the upright phone's blurb)

    /// "Move the 5", "Move the cue ball" or "Ball in hand".
    static func heading(_ model: ShowpieceModel) -> String {
        if liftedObjectBall(model) { return String(localized: "Move the \(model.placingBall)") }
        return model.ballInHand == .none ? String(localized: "Move the cue ball") : String(localized: "Ball in hand")
    }

    /// What to do now: pick the ball up, or drag it to a free spot (behind the head line when the rules say so).
    static func instructions(_ model: ShowpieceModel) -> String {
        guard model.placingCueBall else { return String(localized: "Pick up the cue ball and put it anywhere free.") }
        if liftedObjectBall(model) { return String(localized: "Drag the \(model.placingBall) to a free spot, then let go.") }
        return model.ballInHand == .behindHeadLine
            ? String(localized: "Drag the cue ball to a free spot behind the head line, then let go.")
            : String(localized: "Drag the cue ball to a free spot, then let go.")
    }

    /// Put the ball down; if the spot is not legal it stays lifted and VoiceOver hears why.
    static func place(_ model: ShowpieceModel) {
        if !model.confirmCueBallPlacement() {
            let why = problem(legality(of: spot(model), model))
            ShotNarration.announce(why ?? String(localized: "Not a legal spot"))
        }
    }

    /// One VoiceOver step: one ball radius along a table direction (x toward the foot, y toward the left long
    /// cushion as seen from the head end). A radius is small enough to slip a ball past a neighbour and large enough
    /// that a third of the table's width is about fifteen steps.
    static func nudge(_ model: ShowpieceModel, _ direction: Vec2) {
        let r = model.timeline.table.ballRadius
        let verdict = model.moveCueBallCandidate(to: spot(model) + direction * r)
        ShotNarration.announce(spoken(model, at: spot(model), problem: problem(verdict)))
    }

    /// "38 centimetres from the head cushion and 20 centimetres from the left cushion. Touching the 5."
    static func spoken(_ model: ShowpieceModel, at p: Vec2, problem: String?) -> String {
        let t = model.timeline.table
        func length(_ m: Double) -> String {
            Measurement(value: (max(0, m) * 100).rounded(), unit: UnitLength.centimeters)
                .formatted(.measurement(width: .wide, usage: .asProvided).locale(AppLocale.numbers))
        }
        // The nearer long cushion is the one named: y = 0 is the right-hand cushion seen from the head end.
        let place = p.y > t.width / 2
            ? String(localized: "\(length(p.x)) from the head cushion and \(length(t.width - p.y)) from the left cushion")
            : String(localized: "\(length(p.x)) from the head cushion and \(length(p.y)) from the right cushion")
        return [place, problem ?? String(localized: "Free spot")].joined(separator: ". ")
    }
}

struct BallInHandCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize

    /// Shown while the ball is lifted, and while ball in hand is owed but the player has not picked it up yet. Never
    /// while the ball in hand is the computer's (0.7.6, #33): the model copies the owed ball for its seat too, but the
    /// person may not pick it up, so the card's button would do nothing.
    private var visible: Bool { Self.isVisible(model) }

    /// The rule behind `visible`, shared with the upright phone's ball-in-hand blurb.
    static func isVisible(_ model: ShowpieceModel) -> Bool {
        model.placingCueBall
            || (model.ballInHand != .none && model.aimReady && !model.tableCleared && model.computerTurnStage == .none)
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
                        .accessibilityValue(CueBallPlacement.spoken(model, at: spot, problem: problem))
                        .accessibilityHint(String(localized: "Use the actions to move it. Up is toward the foot of the table, seen from the head end."))
                        .accessibilityAction(named: String(localized: "Move up")) { CueBallPlacement.nudge(model, Vec2(1, 0)) }
                        .accessibilityAction(named: String(localized: "Move down")) { CueBallPlacement.nudge(model, Vec2(-1, 0)) }
                        .accessibilityAction(named: String(localized: "Move left")) { CueBallPlacement.nudge(model, Vec2(0, 1)) }
                        .accessibilityAction(named: String(localized: "Move right")) { CueBallPlacement.nudge(model, Vec2(0, -1)) }
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

    private var heading: String { CueBallPlacement.heading(model) }

    private var instructions: String { CueBallPlacement.instructions(model) }

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
                Button { CueBallPlacement.place(model) } label: {
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
}

// MARK: Place the balls

/// Free play's "No rack: place the balls" with nothing lifted: one short card saying how to arrange the row of balls.
/// It steps aside while a ball is lifted (the ball-in-hand card above takes over) and once the first shot is played.
struct PlaceBallsCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette

    private var visible: Bool { Self.isVisible(model) }

    /// The rule behind `visible`, shared with the upright phone's blurb.
    static func isVisible(_ model: ShowpieceModel) -> Bool {
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
    /// A phone held upright while a guided Lens replay plays (ShowpieceView sets it): the heading only, no buttons.
    @Environment(\.lensReplayCompact) private var compact

    /// Free play only (a match ends with its own result card), once the last shot has played out; kept up while
    /// Watch your best shot replays (the other shot's balls are on the table meanwhile, so tableCleared is false).
    /// Steps aside while a what-if is showing (0.7.5): the what-if card has the slot, and comes back on its close.
    private var visible: Bool { Self.isVisible(model) }

    /// The rule behind `visible`, shared with the upright phone's blurb and its Rack again.
    static func isVisible(_ model: ShowpieceModel) -> Bool {
        model.match == nil && ((model.tableCleared && model.aimReady) || model.replayingBest) && !model.whatIf.isShowing
    }

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
            // Slim while the best shot replays in the Lens on an upright phone: the heading says what is on screen,
            // and the buttons come back when the replay has handed the cleared table back.
            if !compact { details }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22, padding: 12)
        .tint(palette.accent)
        .onAppear { ShotNarration.announce(String(localized: "Table cleared")) }
        .transition(.opacity)
    }

    /// The shot count and the buttons: everything under the heading.
    @ViewBuilder private var details: some View {
        Text(Self.shotsLine(model))
            .font(Theme.body)
            .foregroundStyle(palette.paper.opacity(0.9))
            .frame(maxWidth: .infinity, alignment: .leading)
        // The rack's best remarkable shot, replayed in the Lens; Menu and Rack again end that replay first.
        if model.canWatchBestShot {
            CardButtonRow {
                // 0.7.7 clips: the rack's best shot as a clip, beside watching it.
                if ClipOffer.bestShotAvailable(model) {
                    Button { ClipOffer.startBestShot(model) } label: {
                        Label(String(localized: "Share your best shot"), systemImage: "square.and.arrow.up")
                            .font(.headline).lineLimit(1).frame(minHeight: CallMetrics.buttonHeight)
                    }
                    .buttonStyle(.glass)
                    .accessibilityHint(ClipWords.hint)
                }
                Button { model.watchBestShot() } label: {
                    Label(HighlightWords.watchBest, systemImage: "eye").font(.headline).lineLimit(1)
                        .frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glass)
                .accessibilityHint(HighlightWords.watchHint)
            }
        }
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

    /// One catalog string with the count (0.7.6, #62): the catalog's plural forms choose the noun ("one shot" in
    /// English, the few and many forms in Russian, all six in Arabic) instead of a one-or-many branch here.
    static func shotsLine(_ model: ShowpieceModel) -> String {
        String(localized: "Cleared in \(model.shotsThisRack) shots.",
               comment: "Practice: the rack was cleared in this many shots. Needs plural forms; English one: Cleared in one shot.")
    }
}

// MARK: Worth watching (0.7.4)

/// Free play after a remarkable shot (ShowpieceModel.highlightCard): one slim card in the card slot that names the
/// physics and offers the Lens replay and the trick shot that teaches it. Styled like TableClearedCard. It plays no
/// sound and no haptic and says no praise; it is spoken once to VoiceOver as it appears.
struct HighlightCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    /// A phone held upright while a guided Lens replay plays (ShowpieceView sets it): the title only.
    @Environment(\.lensReplayCompact) private var compact

    var body: some View {
        // Steps aside while a what-if is showing (0.7.5); it comes back on the what-if's close.
        if let offer = model.highlightCard, !model.whatIf.isShowing {
            let kind = offer.highlight.kind
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.circle.fill").foregroundStyle(palette.accent).accessibilityHidden(true)
                        Text(HighlightWords.title(kind)).font(Theme.heading).fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                    if !compact { closeButton }
                }
                if !compact { details(offer) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .tint(palette.accent)
            .onAppear { ShotNarration.announce(HighlightWords.title(kind)) }
            .transition(.opacity)
        }
    }

    /// The card's close button: gone until the next remarkable shot.
    private var closeButton: some View {
        Button { model.dismissHighlight() } label: {
            Image(systemName: "xmark").frame(width: 30, height: 30)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .accessibilityLabel(String(localized: "Close"))
    }

    /// The physics line and the buttons: everything under the title.
    @ViewBuilder private func details(_ offer: ShowpieceModel.HighlightCardOffer) -> some View {
        Text(HighlightWords.line(offer.highlight.kind))
            .font(Theme.body)
            .foregroundStyle(palette.paper.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        CardButtonRow {
            // 0.7.7 clips: a short film of this shot, ready to share.
            if ClipOffer.available(model) {
                Button { ClipOffer.start(model) } label: {
                    Label(ClipWords.shareClip, systemImage: "square.and.arrow.up").font(.headline)
                        .lineLimit(1).frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glass)
                .accessibilityHint(ClipWords.hint)
            }
            // 0.7.7 make-it-again: Make it again (or Play it now once saved), first in the row.
            MakeItAgainButton(model: model)
            if offer.canTryTrick {
                Button { model.tryHighlightTrick() } label: {
                    Label(String(localized: "Try the trick shot"), systemImage: "scope").font(.headline)
                        .lineLimit(1).frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glass)
            }
            if offer.canWatch {
                Button { model.watchHighlight() } label: {
                    Label(String(localized: "Watch it in the Lens"), systemImage: "eye").font(.headline)
                        .lineLimit(1).frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glassProminent)
                .foregroundStyle(palette.ground)
                .accessibilityHint(HighlightWords.watchHint)
            }
        }
    }
}

/// The end of Watch the intro (ShowpieceModel.introEndOffered): instead of a frozen last frame, one small card that
/// says every trick shot can be watched the same way and offers the trick shots or a fresh rack.
struct IntroEndCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette

    var body: some View {
        // Steps aside while a what-if is showing (0.7.5), like every result card.
        if model.introEndOffered, !model.whatIf.isShowing {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles").foregroundStyle(palette.accent).accessibilityHidden(true)
                    Text(HighlightWords.introEnd)
                        .font(Theme.body)
                        .foregroundStyle(palette.paper.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button { model.dismissIntroEnd() } label: {
                        Image(systemName: "xmark").frame(width: 30, height: 30)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel(String(localized: "Close"))
                }
                CardButtonRow {
                    // Practice: a fresh rack on the pool table and Your shot open, as the menu's Practice does
                    // (0.7.5; startGame racks the pool table whatever table was chosen before).
                    Button { model.startGame(); model.requestShotPanel(.open) } label: {
                        Label(String(localized: "Practice"), systemImage: "triangle").font(.headline).lineLimit(1)
                            .frame(minHeight: CallMetrics.buttonHeight)
                    }
                    .buttonStyle(.glass)
                    Button { model.showList(.tricks) } label: {
                        Label(String(localized: "Trick shots"), systemImage: "sparkles").font(.headline).lineLimit(1)
                            .frame(minHeight: CallMetrics.buttonHeight)
                    }
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(palette.ground)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .tint(palette.accent)
            .onAppear { ShotNarration.announce(HighlightWords.introEnd) }
            .transition(.opacity)
        }
    }
}
