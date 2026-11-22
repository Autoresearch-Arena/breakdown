// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, items 4 and 45 of plans/21-Nov-2026-bugs-after-0-6-6-plan.md:
//          the result card shows whenever the stroke changed what happened, in either zone (StrokeEffect), and offers
//          the straight-stroke drill in free play; the drill card says it measures a finger stroke, names the turn of
//          every drifted stroke, and marks a shot played another way as left out of the record.)
// PURPOSE: The stroke on screen (plans/21-Nov-2026-stroke-and-power-plan.md), apart from the live groove:
//          - StrokeCards: the cards this stream adds, one hook line wherever the cards sit (the phone's bottom stack,
//            the side column, the notebook panel), so each works as a card of the notebook beside the table and
//            nothing covers the table:
//            - StrokeResultCard: when the stroke changed what happened (the first ball, a pot made or missed, the
//              cue ball lost or kept), the plain result line ("Your stroke turned the cue a little left. Played
//              straight, the pot would have dropped."), once the shot has played out, until the next shot; in free
//              play with a button to the straight-stroke drill, the one place the stroke is taught.
//            - StrokeDrillCard: the straight-stroke drill's goal, what it measures, the verdict, the turn, the
//              stroke's trace, the remembered progress, and Again.
//          - StrokeShape: a small drawing of a stroke's shape (the drill card's trace), sideways wander enlarged.
//          - StrokeTraceOverlay: the stroke's trace kept with the attempt, drawn faintly on the cloth behind the cue
//            ball while its replay plays, projected through the live camera like the ghost.
// SRP/DRY check: Pass - checked GhostOverlay (the same projector-and-Canvas pattern for the last try; this draws the
//          stroke, not the balls), ComparisonCard and TableClearedCard (the card look and button sizes are theirs) and
//          StrokeWords (every sentence comes from there).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

/// Every card the stroke adds, for one hook line in each place the cards sit.
struct StrokeCards: View {
    let model: ShowpieceModel

    var body: some View {
        StrokeDrillCard(model: model)
        StrokeResultCard(model: model)
    }
}

// MARK: Result line

struct StrokeResultCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette

    /// The line for the shot on screen, once it has played out. Not in the drill, whose card says it with its verdict.
    private var line: String? {
        guard model.aimReady, !model.strokeDrill.isActive else { return nil }
        return StrokeWords.resultLine(for: model.currentAttempt)
    }

    /// The drill is offered only in free play: starting it ends whatever is on the table, and a match, a lesson, a
    /// trick shot or a Behind the 8-Ball situation must not be thrown away by a tip.
    private var offersDrill: Bool {
        model.match == nil && !model.trickMode.isActive && !model.lessonMode.isActive && !model.eightBallMode.isActive
    }

    var body: some View {
        if let line {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "scribble")
                        .font(.headline)
                        .foregroundStyle(palette.slide)
                        .accessibilityHidden(true)
                    Text(line)
                        .font(Theme.body)
                        .foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                if offersDrill {
                    Button { model.strokeDrill.begin() } label: {
                        Label(String(localized: "Practise the straight stroke"), systemImage: "arrow.up.and.down")
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(minHeight: CallMetrics.buttonHeight)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.regular)
                    .accessibilityHint(String(localized: "Starts the straight-stroke drill: the cue ball alone, stroked up the table and back"))
                }
            }
            .glassCard(cornerRadius: 20, padding: 12)
            .tint(palette.accent)
            .accessibilityElement(children: .contain)
            .transition(.opacity)
        }
    }
}

// MARK: The drill's card

struct StrokeDrillCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette

    var body: some View {
        let drill = model.strokeDrill
        if drill.isActive {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.and.down").foregroundStyle(palette.accent).accessibilityHidden(true)
                    Text(String(localized: "Straight stroke")).font(Theme.heading)
                }
                .accessibilityAddTraits(.isHeader)
                if model.aimReady, let result = drill.last {
                    Text(StrokeWords.verdict(result))
                        .font(Theme.body)
                        .foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                    if drill.lastWasBest {
                        Text(String(localized: "Your best yet."))
                            .font(Theme.label)
                            .foregroundStyle(palette.accent)
                    }
                    if !drill.lastCounted {
                        Text(StrokeWords.notCounted)
                            .font(Theme.label)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let line = StrokeWords.drillLine(drill.lastStroke) {
                        Text(line).font(Theme.body).foregroundStyle(palette.paper.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let shape = drill.lastStroke?.record?.shape, shape.count > 1 {
                        StrokeShape(shape: shape)
                            .frame(height: 44)
                        Text(String(localized: "Your stroke, with its sideways wander drawn four times larger."))
                            .font(Theme.label)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text(String(localized: "Stroke the cue ball up to the far rail. A straight stroke brings it back along the cue line."))
                        .font(Theme.body)
                        .foregroundStyle(palette.paper.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(StrokeWords.drillMeasuresFinger)
                        .font(Theme.label)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(String(localized: "Then try it hard: past the calm zone on the power bar, the line wanders more."))
                        .font(Theme.label)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 8) {
                    progress.frame(maxWidth: .infinity, alignment: .leading)
                    if model.aimReady, drill.last != nil {
                        Button { drill.again() } label: {
                            Label(String(localized: "Again"), systemImage: "arrow.counterclockwise").font(.headline)
                                .lineLimit(1)
                                .frame(minHeight: CallMetrics.buttonHeight)
                        }
                        .buttonStyle(.glassProminent)
                        .foregroundStyle(palette.ground)
                        .accessibilityHint(String(localized: "Puts the cue ball back on the head spot"))
                    }
                }
                .controlSize(.regular)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .tint(palette.accent)
            .accessibilityElement(children: .contain)
            .transition(.opacity)
        }
    }

    /// What the device remembers.
    @ViewBuilder private var progress: some View {
        let drill = model.strokeDrill
        VStack(alignment: .leading, spacing: 2) {
            if let best = drill.best {
                Text(String(localized: "Best: \(StrokeWords.distance(best)) off the line"))
            }
            Text(String(localized: "Dead straight strokes: \(drill.straightCount)"))
        }
        .font(Theme.label)
        .foregroundStyle(.secondary)
    }
}

/// A stroke's shape, drawn small: the groove as a faint centre line, the finger's path over it, its start at the left
/// and the furthest pull at the right, the sideways wander drawn four times larger so a few per cent can be seen.
struct StrokeShape: View {
    let shape: [Vec2]
    @Environment(\.palette) private var palette

    /// The sideways enlargement, as the caption under the drawing says.
    static let enlargement = 4.0

    var body: some View {
        Canvas { ctx, size in
            let xs = shape.map(\.x)
            let lo = min(0, xs.min() ?? 0), hi = max(1e-6, xs.max() ?? 1)
            func point(_ v: Vec2) -> CGPoint {
                let x = (v.x - lo) / (hi - lo)
                // Across is a share of the stroke's length; enlarged, then a full share is half the drawing's height.
                let y = 0.5 + v.y * Self.enlargement * 0.5
                return CGPoint(x: CGFloat(x) * size.width, y: CGFloat(min(1, max(0, y))) * size.height)
            }
            var centre = Path()
            centre.move(to: CGPoint(x: 0, y: size.height / 2))
            centre.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            ctx.stroke(centre, with: .color(palette.paper.opacity(0.25)), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
            var path = Path()
            path.addLines(shape.map(point))
            ctx.stroke(path, with: .color(palette.accent), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }
}

// MARK: The trace in the replay

/// The stroke that played the shot on screen, drawn faintly on the cloth while its replay plays. Never takes touches.
struct StrokeTraceOverlay: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Environment(\.palette) private var palette
    @State private var cameraBox = AimProjector.CameraBox()

    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { ctx, size in draw(&ctx, size: size) }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        // Only while the shot is replaying: once the balls are at rest the aiming layer has the cloth.
        guard !model.aimReady, model.stage == .explore, let trace = model.currentAttempt?.stroke?.trace,
              trace.count > 1, let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return }
        var path = Path()
        for (i, p) in trace.enumerated() {
            // Lying on the cloth, like the ghost's paths.
            guard let s = proj.screen(p, height: 0.001) else { return }
            if i == 0 { path.move(to: s) } else { path.addLine(to: s) }
        }
        ctx.stroke(path, with: .color(palette.paper.opacity(0.35)),
                   style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [3, 3]))
    }
}
