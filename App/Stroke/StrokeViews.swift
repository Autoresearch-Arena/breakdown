// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 3, the closing sweep: Theme.blurbTitle is now
//         Theme.label.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, items 4 and 45 of plans/21-Nov-2026-bugs-after-0-6-6-plan.md:
//          the result card shows whenever the stroke changed what happened, in either zone (StrokeEffect), and offers
//          the straight-stroke drill in free play; the drill card says it measures a finger stroke, names the turn of
//          every drifted stroke, and marks a shot played another way as left out of the record.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream what-if, bug 29 of plans/22-Nov-2026-phone-bug-hunt.md:
//          the stroke result line steps aside while the what-if shows.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, plans/22-Nov-2026-phone-ui-plan.md Part 3: on the
//          upright phone the stroke's words are blurbs instead of glass cards. StrokePhoneBlurbs docks the drill's goal or
//          verdict (folded to its first lines, the rest behind a tap), the result line with "Practise the straight
//          stroke", and the stance notice (EquipmentRowList); PhonePrimaryAction.stroke offers "Again" in the drill. The
//          cards above are unchanged for the notebook and the sideways column.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 coordinator: what steps aside for the what-if now also steps
//          aside for the every-surface fan, through model.otherFutureShowing.)
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
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 3's leftover lint note: the card's corners and padding are Theme values (medium
//          corners, 12 point padding) instead of bare numbers.)
// SRP/DRY check: Pass - checked GhostOverlay (the same projector-and-Canvas pattern for the last try; this draws the
//          stroke, not the balls), ComparisonCard and TableClearedCard (the card look and button sizes are theirs) and
//          StrokeWords (every sentence comes from there).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

/// Every card the stroke adds, for one hook line in each place the cards sit (not the upright phone: StrokePhoneBlurbs).
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

    /// The line for the shot on screen, once it has played out. Not in the drill, whose card says it with its verdict,
    /// and not while the what-if shows (0.7.6, bug 29): every result card steps aside for it, and this one used to
    /// stay under it, vanish when Play both started and pop back when the replay ended, shifting the cards.
    /// Shared with the upright phone's result blurb (StrokePhoneBlurbs).
    static func line(_ model: ShowpieceModel) -> String? {
        guard model.aimReady, !model.strokeDrill.isActive, !model.otherFutureShowing else { return nil }
        return StrokeWords.resultLine(for: model.currentAttempt)
    }

    /// The drill is offered only in free play: starting it ends whatever is on the table, and a match, a lesson, a
    /// trick shot or a Behind the 8-Ball situation must not be thrown away by a tip. Shared with StrokePhoneBlurbs.
    static func offersDrill(_ model: ShowpieceModel) -> Bool {
        model.match == nil && !model.trickMode.isActive && !model.lessonMode.isActive && !model.eightBallMode.isActive
    }

    private var line: String? { Self.line(model) }
    private var offersDrill: Bool { Self.offersDrill(model) }

    var body: some View {
        if let line {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "scribble")
                        .font(.headline)
                        .foregroundStyle(palette.paper2)
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
            .glassCard(cornerRadius: Theme.Corner.medium, padding: Theme.Space.sm)
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
            .glassCard(cornerRadius: Theme.Corner.medium, padding: Theme.Space.sm)
            .tint(palette.accent)
            .accessibilityElement(children: .contain)
            .transition(.opacity)
        }
    }

    /// What the device remembers.
    private var progress: some View { StrokeDrillProgress(drill: model.strokeDrill) }
}

/// What the device remembers about the drill: the best stroke and the count of dead straight ones. Shared by the
/// drill's card and its blurb on the upright phone.
struct StrokeDrillProgress: View {
    let drill: StrokeDrill

    var body: some View {
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

// MARK: The upright phone

/// The stroke's blurbs on the upright phone (plans/22-Nov-2026-phone-ui-plan.md, Part 3), docked at the top of the
/// table area by ShowpieceView, in this order: the drill (its goal, or its verdict), the result line, the stance notice.
/// Each is drawn only when it has something to say, so a silent one adds no height to the dock (the camera frames the
/// table from the dock's bottom). The drill's "Again" is the screen's primary action (PhonePrimaryAction.stroke), not
/// a button here.
struct StrokePhoneBlurbs: View {
    let model: ShowpieceModel
    /// The drill blurb is folded to its first lines; a tap opens the rest (the turn, the trace, the progress).
    @State private var drillFolded = true
    @Environment(\.palette) private var palette

    var body: some View {
        drillBlurb
        resultBlurb
        stanceBlurb
    }

    // MARK: The drill

    @ViewBuilder private var drillBlurb: some View {
        let drill = model.strokeDrill
        if drill.isActive {
            // "Again" on the blurb itself once a stroke is judged: the aiming panel stays open through a drill, and with it open
            // the strip shows no white button, so the drill's own reset would otherwise be out of reach (22-Nov-2026).
            Blurb(folded: $drillFolded, accessibilityText: drillSpoken,
                  buttons: model.aimReady && drill.last != nil
                      ? [BlurbButton(String(localized: "Again"),
                                     hint: String(localized: "Puts the cue ball back on the head spot")) { drill.again() }]
                      : []) { open in
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Straight stroke")).font(Theme.label)
                    if model.aimReady, let result = drill.last {
                        Text(StrokeWords.verdict(result)).font(Theme.body)
                            .lineLimit(open ? nil : 2)
                            .fixedSize(horizontal: false, vertical: true)
                        if drill.lastWasBest {
                            Text(String(localized: "Your best yet.")).font(Theme.label).foregroundStyle(.secondary)
                        }
                        if open {
                            if !drill.lastCounted {
                                Text(StrokeWords.notCounted).font(Theme.label).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if let line = StrokeWords.drillLine(drill.lastStroke) {
                                Text(line).font(Theme.body).fixedSize(horizontal: false, vertical: true)
                            }
                            if let shape = drill.lastStroke?.record?.shape, shape.count > 1 {
                                // The trace stays a drawing, never cut (the Boss: never shortchange the graphics).
                                StrokeShape(shape: shape).frame(height: 44)
                                Text(String(localized: "Your stroke, with its sideways wander drawn four times larger."))
                                    .font(Theme.label).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            StrokeDrillProgress(drill: drill)
                        }
                    } else {
                        Text(String(localized: "Stroke the cue ball up to the far rail. A straight stroke brings it back along the cue line."))
                            .font(Theme.body)
                            .lineLimit(open ? nil : 2)
                            .fixedSize(horizontal: false, vertical: true)
                        if open {
                            Text(StrokeWords.drillMeasuresFinger).font(Theme.label).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(String(localized: "Then try it hard: past the calm zone on the power bar, the line wanders more."))
                                .font(Theme.label).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            StrokeDrillProgress(drill: drill)
                        }
                    }
                }
            }
        }
    }

    /// Everything the drill blurb says, folded or not, for VoiceOver.
    private var drillSpoken: String {
        let drill = model.strokeDrill
        var parts = [String(localized: "Straight stroke")]
        if model.aimReady, let result = drill.last {
            parts.append(StrokeWords.verdict(result))
            if drill.lastWasBest { parts.append(String(localized: "Your best yet.")) }
            if !drill.lastCounted { parts.append(StrokeWords.notCounted) }
            if let line = StrokeWords.drillLine(drill.lastStroke) { parts.append(line) }
        } else {
            parts.append(String(localized: "Stroke the cue ball up to the far rail. A straight stroke brings it back along the cue line."))
            parts.append(StrokeWords.drillMeasuresFinger)
        }
        if let best = drill.best { parts.append(String(localized: "Best: \(StrokeWords.distance(best)) off the line")) }
        parts.append(String(localized: "Dead straight strokes: \(drill.straightCount)"))
        return parts.joined(separator: " ")
    }

    // MARK: The result line

    @ViewBuilder private var resultBlurb: some View {
        if let line = StrokeResultCard.line(model) {
            let buttons: [BlurbButton] = StrokeResultCard.offersDrill(model)
                ? [BlurbButton(String(localized: "Practise the straight stroke"),
                               hint: String(localized: "Starts the straight-stroke drill: the cue ball alone, stroked up the table and back")) {
                       model.strokeDrill.begin()
                   }]
                : []
            Blurb(sentence: line, buttons: buttons)
        }
    }

    // MARK: The stance

    /// The stance notice (a stretch, a raised cue, the cue the game picked), while lining up a shot. Not during the
    /// first minute's hand-over, which shows one instruction only, nor on the computer's turn. No room is kept when it
    /// has nothing to say: the dock's height is where the camera's table area starts, so an empty kept room would cost
    /// the table height through every aim.
    @ViewBuilder private var stanceBlurb: some View {
        let aiming = model.aimReady && model.openingStage != .handOver && model.personControlsLive
        let rows = aiming ? EquipmentRows.current(model) : []
        if !rows.isEmpty {
            Blurb(accessibilityText: rows.map(\.line).joined(separator: ". ")) {
                EquipmentRowList(rows: rows)
            }
        }
    }
}

extension PhonePrimaryAction {
    /// The stroke drill's primary action: "Again" once a drill stroke has played out, putting the cue ball back on the
    /// head spot. Nil whenever the drill is not on the table, so the other providers and "Your shot" are untouched.
    static func stroke(_ model: ShowpieceModel) -> PhonePrimaryAction? {
        let drill = model.strokeDrill
        guard drill.isActive, model.aimReady, drill.last != nil else { return nil }
        return PhonePrimaryAction(title: String(localized: "Again"),
                                  hint: String(localized: "Puts the cue ball back on the head spot")) {
            drill.again()
        }
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
