// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (learn from a retry, view side: the ghost also marks where the last
//          try's cue ball first touched a ball, a small hollow ring with a dot, so pausing the live replay at its own
//          contact (See the contact) shows both contacts side by side; the comparison card now words the model's
//          RetryComparison facts through RetryWords, offers See the contact, stays up while the replay is paused there,
//          keeps its dismissal to itself, and steps aside while a trick-shot, 8-ball or match card is the result card.)
// PURPOSE: The "last try" ghost. While the player retries a shot, the previous attempt's cue-ball path and the path of
//          the first ball it struck are drawn faintly over the table (and over the Physics Lens), with a hollow ring and
//          a small "Last try" label where the ghost cue ball stopped. The paths are sampled once per ghost from the
//          recording (ShotAttempt.ghostPaths), so the picture does not depend on the playback clock: scrubbing either
//          way leaves it exactly where it was. It is projected through the live camera each frame, so it follows the
//          swing into the Lens. It never takes touches.
//          Colours are deliberately secondary: paper white and a muted version of the struck ball's amber, thin and
//          dashed, so they read as a memory under the live trails rather than as part of the shot.
// SRP/DRY check: Pass - checked AimOverlay (same projector and Canvas pattern, but for the live aim) and LensLayer
//          (clock-driven live trails in 3D). This file only draws the previous attempt.
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

struct GhostOverlay: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Environment(\.palette) private var palette
    @State private var cameraBox = AimProjector.CameraBox()
    @State private var paths: (version: Int, cue: [Vec2], object: [Vec2], rest: Vec2?) = (-1, [], [], nil)
    /// Where the last try's cue ball was at its first touch of another ball; nil when it touched none.
    @State private var contact: Vec2?

    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { ctx, size in draw(&ctx, size: size) }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onChange(of: model.ghostVersion, initial: true) { _, version in
            // Sampled once per ghost; the per-frame work is only projecting the points.
            guard let g = model.ghost else { paths = (version, [], [], nil); contact = nil; return }
            let p = g.ghostPaths()
            paths = (version, p.cue, p.object, g.cueBallScratched ? nil : g.cueRest)
            // Read at that recording's own contact time (plan 14, section 3), from its first cue-ball collision.
            contact = g.timeline.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }
                .map { g.timeline.state(ball: 0, at: $0.time).position }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        guard model.ghost != nil, !paths.cue.isEmpty, let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return }
        let paper = palette.paper
        let radius = model.timeline.table.ballRadius
        // Lying on the cloth (height 0) rather than at ball height reads better as a mark left on the table.
        func line(_ pts: [Vec2]) -> Path? {
            var path = Path()
            for (i, p) in pts.enumerated() {
                guard let s = proj.screen(p, height: 0.001) else { return nil }
                if i == 0 { path.move(to: s) } else { path.addLine(to: s) }
            }
            return path
        }
        if let object = line(paths.object) {
            ctx.stroke(object, with: .color(palette.slide.opacity(0.35)),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [2, 5]))
        }
        if let cue = line(paths.cue) {
            ctx.stroke(cue, with: .color(.black.opacity(0.35)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            ctx.stroke(cue, with: .color(paper.opacity(0.6)),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [7, 5]))
        }
        // Where the last try's cue ball first touched a ball: a small dashed ring with a dot in it.
        if let at = contact {
            var mark = Path()
            for i in 0..<24 {
                let a = Double(i) / 24 * 2 * Double.pi
                guard let s = proj.screen(at + Vec2(cos(a), sin(a)) * radius * 0.6, height: 0.001) else { mark = Path(); break }
                if i == 0 { mark.move(to: s) } else { mark.addLine(to: s) }
            }
            mark.closeSubpath()
            ctx.stroke(mark, with: .color(paper.opacity(0.75)), style: StrokeStyle(lineWidth: 1.2, dash: [2, 2]))
            if let c = proj.screen(at, height: 0.001) {
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - 2, y: c.y - 2, width: 4, height: 4)), with: .color(paper.opacity(0.85)))
            }
        }
        guard let rest = paths.rest else { return }
        // The hollow ring where the ghost cue ball stopped, and its label.
        var ring = Path()
        for i in 0..<36 {
            let a = Double(i) / 36 * 2 * Double.pi
            guard let s = proj.screen(rest + Vec2(cos(a), sin(a)) * radius, height: 0.001) else { return }
            if i == 0 { ring.move(to: s) } else { ring.addLine(to: s) }
        }
        ring.closeSubpath()
        ctx.stroke(ring, with: .color(paper.opacity(0.75)), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
        if let at = proj.screen(rest + Vec2(0, 0), height: 0.001) {
            let label = ctx.resolve(Text("Last try").font(.caption2.weight(.semibold)).foregroundStyle(paper.opacity(0.85)))
            let m = label.measure(in: size)
            let box = CGRect(x: at.x - m.width / 2 - 6, y: at.y + 14, width: m.width + 12, height: m.height + 4)
            ctx.fill(Path(roundedRect: box, cornerRadius: box.height / 2), with: .color(.black.opacity(0.55)))
            ctx.draw(label, at: CGPoint(x: box.midX, y: box.midY))
        }
    }
}

/// The comparison after a retry, in one sentence from RetryWords, with See the contact beside it. Free play only: a
/// trick shot, a Behind the 8-Ball situation and a match each have their own result card, and only one result card is
/// ever up (plan 14, "one result card"); the trick-shot card carries this same sentence itself.
struct ComparisonCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    /// The recording whose comparison was put away. Kept here rather than in the model, so the card needs nothing
    /// from the model but the facts; a new recording (a new timelineVersion) brings the card back.
    @State private var dismissedVersion = -1
    /// The recording the player paused at its contact: the card stays up while the replay sits there.
    @State private var seekedVersion = -1

    private var visible: Bool {
        guard model.retryComparison != nil, dismissedVersion != model.timelineVersion,
              !model.trickMode.isActive, !model.eightBallMode.isActive, model.match == nil else { return false }
        // Only once the retry has played out, so it never talks over the shot; or while paused at the contact.
        return model.aimReady || seekedVersion == model.timelineVersion
    }

    var body: some View {
        if visible, let c = model.retryComparison {
            let text = RetryWords.sentence(c)
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.headline)
                    .foregroundStyle(palette.accent)
                    .accessibilityHidden(true)
                Text(text)
                    .font(Theme.body)
                    .foregroundStyle(palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Compared with your last try. \(text)")
                ContactButton(model: model) { seekedVersion = model.timelineVersion }
                Button { dismissedVersion = model.timelineVersion } label: {
                    Image(systemName: "xmark").frame(width: 30, height: 30)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Dismiss comparison")
            }
            .glassCard(cornerRadius: 20, padding: 12)
            .accessibilityElement(children: .contain)
            .transition(.opacity)
        }
    }
}
