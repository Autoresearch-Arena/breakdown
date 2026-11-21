// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: What a first-time player sees around the opening, the view side of the model's OpeningStage.
//          OpeningLayer - laid over the whole table. While the opening plays (.playing) a tap anywhere skips it
//            (ShowpieceModel.skipOpening, which goes straight to the hand-over); VoiceOver reads the layer as one
//            "Skip the intro" button. At the hand-over (.handOver) it opens the aiming controls (the fresh rack in free
//            play, with the aiming tips showing) and draws the one glowing control: a soft halo round the cue ball,
//            where the pull-back starts. The halo breathes; with Reduce Motion it holds still at full strength, so the
//            still path reads the same. It never takes touches at the hand-over.
//          OpeningCard - the one line of the hand-over, "Your turn. Drag to aim, pull back, let go.", as a card with
//            the other mode cards (above the controls, in the side column, or in the folding phone's panel, so nothing
//            covers the table there). On the folding phone's open screen, where the table panel is the only thing the
//            tap-anywhere layer covers, the card also carries a Skip intro button while the opening plays.
//          Both read only the contract names from docs/award-batch-contracts.md section 2.1 (openingStage,
//          skipOpening); the model decides when each stage starts and ends.
// SRP/DRY check: Pass - checked AimOverlay (draws the pull handle itself; this only adds a glow round it, projected the
//          same way through AimProjector), TrickTableLayer and GhostOverlay (the same Canvas-over-the-table pattern),
//          and ShotPanel (owns the aiming tips, which this does not repeat). Card styling is the shared glassCard.
import BreakdownLensModel
import SwiftUI

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
                // A clear sheet that takes every touch on the table while the opening plays: one tap skips it.
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
                    Canvas { ctx, size in drawGlow(&ctx, size: size, at: context.date) }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: model.openingStage)
        // The hand-over is the player's own break on a fresh rack: open the aiming controls for it.
        .onChange(of: model.openingStage, initial: true) { _, stage in
            if stage == .handOver { shotPanelOpen = true }
        }
    }

    /// The halo round the cue ball. Projected each frame through the live camera, so it stays on the ball as the
    /// camera settles after the replay.
    private func drawGlow(_ ctx: inout GraphicsContext, size: CGSize, at date: Date) {
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

    var body: some View {
        switch model.openingStage {
        case .handOver:
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "hand.draw")
                    .font(.title2)
                    .foregroundStyle(palette.accent)
                    .accessibilityHidden(true)
                Text("Your turn. Drag to aim, pull back, let go.")
                    .font(Theme.heading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .transition(.opacity)
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
}
