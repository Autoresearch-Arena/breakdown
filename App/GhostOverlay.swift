// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (learn from a retry, view side: the ghost also marks where the last
//          try's cue ball first touched a ball, a small hollow ring with a dot, so pausing the live replay at its own
//          contact (See the contact) shows both contacts side by side; the comparison card now words the model's
//          RetryComparison facts through RetryWords, offers See the contact, stays up while the replay is paused there,
//          keeps its dismissal to itself, and steps aside while a trick-shot, 8-ball or match card is the result card.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons stream, one line: the comparison card also steps aside while a
//          lesson is up, because the lesson card is then the one result card and carries the sentence itself.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: the struck ball's ghost line takes the sliding magenta from the palette; one
//          comment updated.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 trick-shots stream: the path, rest-ring and label drawing moved
//          into TablePathStroke at the end of this file, unchanged in look, so the trick-shot layer draws the answer's
//          path with the same code.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif stream: the comparison card steps aside while a what-if
//          shows; the contact mark reads the attempt's own cue ball (ball 0 only on the pool table); and a what-if
//          future the player kept is drawn as a faint violet target of its cue-ball path under the last try, until the
//          kept try is played.)
// PURPOSE: The "last try" ghost. While the player retries a shot, the previous attempt's cue-ball path and the path of
//          the first ball it struck are drawn faintly over the table (and over the Physics Lens), with a hollow ring and
//          a small "Last try" label where the ghost cue ball stopped. The paths are sampled once per ghost from the
//          recording (ShotAttempt.ghostPaths), so the picture does not depend on the playback clock: scrubbing either
//          way leaves it exactly where it was. It is projected through the live camera each frame, so it follows the
//          swing into the Lens. It never takes touches.
//          Colours are deliberately secondary: paper white and a muted version of the sliding magenta for the struck ball, thin and
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
            // The attempt's own cue ball: on the other tables the struck ball is not ball 0.
            let cue = g.cueBall
            contact = g.timeline.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == cue } }
                .map { g.timeline.state(ball: cue, at: $0.time).position }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        guard model.ghost != nil, !paths.cue.isEmpty, let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return }
        // A kept what-if future (0.7.5): its cue-ball path, faint violet, as the target of the try about to be played.
        // Only for the retry it was kept for (the same ghost) and only until that try is struck (an attempt exists).
        if let kept = model.whatIf.keptPaths, kept.ghostVersion == model.ghostVersion, model.currentAttempt == nil {
            TablePathStroke(points: kept.cue, colour: palette.whatIf.opacity(0.4), lineWidth: 2, dash: [1.5, 4],
                            underlayWidth: 4).draw(in: &ctx, proj)
        }
        let paper = palette.paper
        let radius = model.timeline.table.ballRadius
        // The two paths through the shared cloth-path drawing (TablePathStroke), with the same colours and dashes as
        // before it was shared.
        TablePathStroke(points: paths.object, colour: palette.slide.opacity(0.35), lineWidth: 2, dash: [2, 5])
            .draw(in: &ctx, proj)
        TablePathStroke(points: paths.cue, colour: paper.opacity(0.6), lineWidth: 2, dash: [7, 5], underlayWidth: 4)
            .draw(in: &ctx, proj)
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
        guard let ring = TablePathStroke.ring(at: rest, radius: radius, proj) else { return }
        ctx.stroke(ring, with: .color(paper.opacity(0.75)), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
        TablePathStroke.label(Text("Last try"), at: rest, colour: paper.opacity(0.85), in: &ctx, size: size, proj)
    }
}

/// A path lying on the cloth, drawn through the live camera: the shared drawing behind the last try's ghost (above) and
/// a trick shot's answer path (TrickTableLayer, 0.7.4). Points are table metres, sampled once by the caller; each frame
/// only projects them, so the picture follows the camera into the Lens and never depends on the playback clock.
@MainActor
struct TablePathStroke {
    var points: [Vec2]
    var colour: Color
    var lineWidth: CGFloat
    var dash: [CGFloat]
    /// A dark line this wide under the colour (nil for none), so a pale path still reads on the bright cloth.
    var underlayWidth: CGFloat? = nil

    /// Strokes the path; draws nothing when it is empty or any point is behind the camera.
    func draw(in ctx: inout GraphicsContext, _ proj: AimProjector) {
        guard let path = Self.line(points, proj) else { return }
        if let w = underlayWidth {
            ctx.stroke(path, with: .color(.black.opacity(0.35)), style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
        }
        ctx.stroke(path, with: .color(colour), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, dash: dash))
    }

    /// The points as one screen path, lying on the cloth (height 0 reads better as a mark left on the table than ball
    /// height); nil when any point is behind the camera, or there are none.
    static func line(_ pts: [Vec2], _ proj: AimProjector) -> Path? {
        guard !pts.isEmpty else { return nil }
        var path = Path()
        for (i, p) in pts.enumerated() {
            guard let s = proj.screen(p, height: 0.001) else { return nil }
            if i == 0 { path.move(to: s) } else { path.addLine(to: s) }
        }
        return path
    }

    /// A closed ring on the cloth, one ball radius round a resting spot; nil when it is behind the camera.
    static func ring(at centre: Vec2, radius: Double, _ proj: AimProjector) -> Path? {
        var ring = Path()
        for i in 0..<36 {
            let a = Double(i) / 36 * 2 * Double.pi
            guard let s = proj.screen(centre + Vec2(cos(a), sin(a)) * radius, height: 0.001) else { return nil }
            if i == 0 { ring.move(to: s) } else { ring.addLine(to: s) }
        }
        ring.closeSubpath()
        return ring
    }

    /// A small dark pill with a word in it, just below a spot on the cloth (the "Last try" label's look).
    static func label(_ text: Text, at spot: Vec2, colour: Color, in ctx: inout GraphicsContext, size: CGSize,
                      _ proj: AimProjector) {
        guard let at = proj.screen(spot, height: 0.001) else { return }
        let label = ctx.resolve(text.font(.caption2.weight(.semibold)).foregroundStyle(colour))
        let m = label.measure(in: size)
        let box = CGRect(x: at.x - m.width / 2 - 6, y: at.y + 14, width: m.width + 12, height: m.height + 4)
        ctx.fill(Path(roundedRect: box, cornerRadius: box.height / 2), with: .color(.black.opacity(0.55)))
        ctx.draw(label, at: CGPoint(x: box.midX, y: box.midY))
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
              !model.trickMode.isActive, !model.eightBallMode.isActive, !model.lessonMode.isActive,
              model.match == nil, !model.whatIf.isShowing else { return false }
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
