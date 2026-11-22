// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 model-flow, header only: since 0.7.1 the first launch goes
//          straight to the hand-over, so the opening replay, its tap-to-skip (skipOpening) and the Skip intro button
//          are no longer reached on a first launch, and the first break's card hands straight back to play. The
//          PURPOSE below now says so; no code changed.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.1: the hand-over is now the first thing a new player sees, so its
//          line is just how to shoot, without "Your turn".)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 1, 3 and 6:
//          FirstInstruction, one instruction per input that matches what the code does, used by the hand-over card,
//          the shot panel's hint, How to play and the spoken first line; the hand-over draws the stroke's groove
//          faintly behind the cue ball until the player first changes the aim or the power; the first break ends with
//          one short card (what the break did, "Learn the shots", "Keep playing"); the skip layer is laid under the
//          title row and the controls by ShowpieceView, so only the table itself skips.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream aim, plans/22-Nov-2026-phone-bug-hunt.md #46: the
//          hand-over no longer draws its own groove. Its wide, tapering band sat on top of AimOverlay's groove hint (the
//          one shaped like the real groove), so two grooves showed and the first touch changed which. The hint is now
//          the one groove; the halo is unchanged, so the first minute is as calm as before.)
// PURPOSE: What a first-time player sees around the opening, the view side of the model's OpeningStage.
//          FirstInstruction - the one instruction for the input in use (PlayInput): on touch the cue ball is pulled
//            back and pushed through (letting go plays nothing, StrokeGesture), with a pointer it is pulled back and
//            let go (PointerAim), from the keyboard the arrows and Return (AimOverlay.handleKey), from a controller the
//            stick, triggers and A (ControllerInput). Read by the hand-over card, the shot panel's hint, How to play and
//            TableAccessLayer, so every place teaches the same thing.
//          OpeningLayer - laid over the table, under the title row and the controls (ShowpieceView), so Continue, Pause,
//            the scrub bar and Menu keep their own jobs. Since 0.7.1 a first launch starts at the hand-over, with no
//            opening replay, so the .playing stage (a tap on the table skipping to the hand-over through
//            ShowpieceModel.skipOpening, read by VoiceOver as one "Skip the intro" button) is kept but not reached on a
//            first launch. At the hand-over (.handOver) it opens the aiming controls (the fresh rack in free
//            play) and draws the one glowing control: a soft halo round the cue ball, where the pull-back starts. The
//            faint groove behind it is AimOverlay's groove hint, which the open controls lay. The halo breathes; with
//            Reduce Motion it holds still at full strength. It never takes touches at the hand-over.
//          OpeningCard - the hand-over's one line (the instruction for the input in use) and the first-break card: what
//            the break did, "Learn the shots" (prominent) and "Keep playing" (reopens Your shot). Since 0.7.1 the model
//            passes straight through .firstBreakCard into Keep playing, so the player carries on from the break and
//            that card is not seen on a first launch. Shown with the other mode cards (above the controls, in the side
//            column, or in the notebook), so nothing covers the table. Its Skip intro button (the notebook's version of
//            the phone's "Tap to skip") belongs to the .playing stage, which a first launch no longer reaches.
//          Reads only the contract names (docs/award-batch-contracts.md section 2.1, docs/v07-contracts.md sections 1.4
//          and 2.3); the model decides when each stage starts and ends.
// SRP/DRY check: Pass - checked AimOverlay (draws the pull handle itself; this only adds a glow round it, projected the
//          same way through AimProjector), StrokeDrawing in StrokeGesture (the live groove while a stroke is on, and
//          the hint before it, which AimOverlay draws at the hand-over; this layer draws no groove), TrickTableLayer and GhostOverlay (the same
//          Canvas-over-the-table pattern), ShotPanel (owns the aiming tips, which this does not repeat) and MatchWords
//          (the ball list words are reused). Card styling is the shared glassCard.
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

// MARK: The first instruction

/// The one instruction for each way of playing, matching what the code does with it (items 1 and 51).
enum FirstInstruction {
    static func line(for input: PlayInput) -> String {
        switch input {
        case .touch:
            // Letting go of a touch keeps the power and plays nothing (StrokeGesture); only a push through the ball plays.
            return String(localized: "Drag on the table to aim. Pull back from the white ball, then push through it.")
        case .pointer:
            // A pointer's release behind the ball plays (PointerAim); a release in front of it is a change of mind.
            return String(localized: "Click the table to aim. Pull back from the white ball and let go.")
        case .keyboard:
            return String(localized: "Arrow keys aim and set the power. Return plays the shot.")
        case .controller:
            return String(localized: "Left stick aims, the triggers set the power, A plays the shot.")
        }
    }

    /// The input a screen assumes before the player has used any: the pointer on the Mac, touch elsewhere (the same
    /// starting value the model gives inputInUse).
    static var platformDefault: PlayInput {
        #if os(macOS)
        return .pointer
        #else
        return .touch
        #endif
    }
}

// MARK: Over the table

struct OpeningLayer: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Binding var shotPanelOpen: Bool
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cameraBox = AimProjector.CameraBox()

    var body: some View {
        ZStack {
            if model.openingStage == .playing {
                // A clear sheet over the table while the opening plays: one tap skips it. The title row and the controls
                // sit above this layer (ShowpieceView), so their buttons do their own jobs.
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { model.skipOpening() }
                    .accessibilityElement()
                    .accessibilityLabel("Skip the intro")
                    .accessibilityHint("Goes straight to your own break")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { model.skipOpening() }
            }
            if model.openingStage == .handOver {
                TimelineView(.animation(paused: reduceMotion)) { context in
                    Canvas { ctx, size in drawHandOver(&ctx, size: size, at: context.date) }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: model.openingStage)
        // The hand-over is the player's own break on a fresh rack: open the aiming controls for it. Opening them also
        // lays the stroke's groove hint behind the cue ball (AimOverlay.showsGrooveHint passes at the hand-over), the
        // one groove on screen (0.7.6 #46).
        .onChange(of: model.openingStage, initial: true) { _, stage in
            if stage == .handOver { shotPanelOpen = true }
        }
    }

    /// The halo round the cue ball, projected each frame through the live camera, so it stays on the ball as the
    /// camera settles. The groove behind the ball is not drawn here any more (0.7.6 #46): this layer's own wider,
    /// tapering band sat on top of AimOverlay's groove hint, which is the shape the real groove takes, so the player
    /// saw two grooves and the first touch changed which one showed. AimOverlay's hint is now the only one.
    private func drawHandOver(_ ctx: inout GraphicsContext, size: CGSize, at date: Date) {
        guard let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table)),
              let centre = proj.screen(model.aimOrigin)
        else { return }
        let radius = model.timeline.table.ballRadius
        // The ball's size on screen: the larger of its projected radius along and across the table.
        var r: CGFloat = 12
        if let a = proj.screen(model.aimOrigin + Vec2(radius, 0)), let b = proj.screen(model.aimOrigin + Vec2(0, radius)) {
            r = max(8, hypot(a.x - centre.x, a.y - centre.y), hypot(b.x - centre.x, b.y - centre.y))
        }
        // One slow breath every two seconds (calm, not a warning blink); Reduce Motion holds the brightest moment.
        let breath = reduceMotion ? 1.0 : 0.5 + 0.5 * sin(date.timeIntervalSinceReferenceDate * Double.pi)
        let accent = palette.accent
        // Three rings, widest and faintest outside: a glow without a blur filter, which a Canvas redrawn every frame
        // would pay for on every frame.
        for (scale, alpha) in [(3.4, 0.10), (2.7, 0.18), (2.1, 0.30)] {
            let rr = r * CGFloat(scale + 0.25 * breath)
            let ring = Path(ellipseIn: CGRect(x: centre.x - rr, y: centre.y - rr, width: rr * 2, height: rr * 2))
            ctx.stroke(ring, with: .color(accent.opacity(alpha * (0.6 + 0.4 * breath))), lineWidth: r * 0.55)
        }
    }
}

// MARK: With the cards

struct OpeningCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.inlinePages) private var inlinePages
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        switch model.openingStage {
        case .handOver:
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "hand.draw")
                    .font(.title2)
                    .foregroundStyle(palette.accent)
                    .accessibilityHidden(true)
                Text(FirstInstruction.line(for: model.inputInUse))
                    .font(Theme.heading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .transition(.opacity)
        case .firstBreakCard:
            firstBreakCard
        case .playing where inlinePages:
            Button { model.skipOpening() } label: {
                Label("Skip intro", systemImage: "forward.end.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 30)
            }
            .buttonStyle(.glass)
            .controlSize(.regular)
            .accessibilityHint("Goes straight to your own break")
            .transition(.opacity)
        default:
            EmptyView()
        }
    }

    // MARK: The first break's card

    /// One short card after the player's first break: what it did, then the lessons first and the table second.
    private var firstBreakCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").foregroundStyle(palette.accent).accessibilityHidden(true)
                Text(String(localized: "Your first break")).font(Theme.heading)
            }
            .accessibilityAddTraits(.isHeader)
            Text(breakLine)
                .font(Theme.body)
                .foregroundStyle(palette.paper.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            buttons
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22, padding: 12)
        .tint(palette.accent)
        .transition(.opacity)
        .onAppear { AccessibilityNotification.Announcement(breakLine).post() }
    }

    @ViewBuilder private var buttons: some View {
        let keep = Button { model.keepPlayingAfterFirstBreak() } label: {
            Label(String(localized: "Keep playing"), systemImage: "target").font(.headline).lineLimit(1)
                .frame(minHeight: CallMetrics.buttonHeight)
        }
        .buttonStyle(.glass)
        .accessibilityHint(String(localized: "Opens Your shot on this table"))
        let learn = Button { model.learnAfterFirstBreak() } label: {
            Label(String(localized: "Learn the shots"), systemImage: "graduationcap").font(.headline).lineLimit(1)
                .frame(minHeight: CallMetrics.buttonHeight)
        }
        .buttonStyle(.glassProminent)
        .foregroundStyle(palette.ground)
        .keyboardShortcut(.defaultAction)
        .accessibilityHint(String(localized: "Opens the six lessons"))
        if typeSize.isAccessibilitySize {
            VStack(alignment: .trailing, spacing: 8) { learn; keep }.frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            HStack(spacing: 8) { Spacer(minLength: 0); keep; learn }.controlSize(.regular)
        }
    }

    /// What the break did, from the package's reading of the shot on screen: the balls it sank (or that it spread the
    /// rack without sinking one), and whether the white ball went in too.
    private var breakLine: String {
        guard let facts = model.shotFactsOnScreen else {
            return String(localized: "Nothing dropped, but the rack is open.")
        }
        let sunk = facts.pocketed.map(\.ball).filter { $0 != facts.cueBall }
        var parts = [sunk.isEmpty ? String(localized: "Nothing dropped, but the rack is open.")
                                  : String(localized: "Your break sank \(MatchWords.balls(sunk)).")]
        if facts.cueBallScratched {
            parts.append(String(localized: "The white ball went in too, so you put it back by hand."))
        }
        return parts.joined(separator: " ")
    }
}
