// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 1: projects through AimProjector.forLayer, so the
//          last try's paths stay on the table in a narrow Mac window.)
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
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream drawings, bug list #40 and #26: the last try's contact
//          mark is never under 7 points in radius on screen, its dot a third of that; TablePathStroke.ring keeps the
//          same 7-point floor for every ring it draws (the Last try, Answer and what-if rest rings, the trick shots'
//          ball, pocket and zone rings), measured through the projector; TablePathStroke.line skips a point behind the
//          camera and starts a new piece at the next one instead of dropping the whole path, so the what-if's violet
//          paths stay up through a Ride chase.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, plans/22-Nov-2026-phone-ui-plan.md Part 3: the
//          comparison card's close button is glass instead of bordered; when the card shows is one shared rule
//          (ComparisonCard.shows), which ComparisonPhoneBlurb, the upright phone's docked blurb of the same sentence with
//          See the contact and Close, also reads. The card is unchanged elsewhere.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 coordinator: what steps aside for the what-if now also steps
//          aside for the every-surface fan, through model.otherFutureShowing.)
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
    /// This layer's frame in StageSpace, for AimProjector.forLayer (UI rethink package 1).
    @State private var layerFrame: CGRect?

    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { ctx, size in draw(&ctx, size: size) }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { layerFrame = $0 }
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
              let proj = AimProjector.forLayer(camera: cameraBox.find(in: root), bridge: bridge, layerFrame: layerFrame,
                                               layerSize: size, frame: TableFrame(model.timeline.table))
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
        TablePathStroke(points: paths.object, colour: palette.paper.opacity(0.3), lineWidth: 2, dash: [2, 5])
            .draw(in: &ctx, proj)
        TablePathStroke(points: paths.cue, colour: paper.opacity(0.6), lineWidth: 2, dash: [7, 5], underlayWidth: 4)
            .draw(in: &ctx, proj)
        // Where the last try's cue ball first touched a ball: a small dashed ring with a dot in it. Since 0.7.6 (#40)
        // the ring is never under 7 points in radius on screen (on an upright phone its table size, 0.6 of a ball
        // radius, came out about 3 points, the same as the dot), and the dot is a third of the ring's radius, so the
        // two read as a ring round a dot.
        if let at = contact, let c = proj.screen(at, height: 0.001) {
            let natural = radius * 0.6
            let k = TablePathStroke.floorScale(at: at, radius: natural, minPoints: TablePathStroke.minRingPoints, proj)
            if let mark = TablePathStroke.ring(at: at, radius: natural * k, proj, minPoints: 0, segments: 24) {
                ctx.stroke(mark, with: .color(paper.opacity(0.75)), style: StrokeStyle(lineWidth: 1.2, dash: [2, 2]))
            }
            // The ring's radius on screen (measured, then floored) sets the dot's.
            let ringPoints = max(TablePathStroke.minRingPoints,
                                 (TablePathStroke.screenRadius(at: at, radius: natural, proj) ?? 0) * CGFloat(k))
            let dot = ringPoints / 3
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - dot, y: c.y - dot, width: 2 * dot, height: 2 * dot)),
                     with: .color(paper.opacity(0.85)))
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

    /// Strokes the path; draws nothing when it is empty or wholly behind the camera.
    func draw(in ctx: inout GraphicsContext, _ proj: AimProjector) {
        guard let path = Self.line(points, proj) else { return }
        if let w = underlayWidth {
            ctx.stroke(path, with: .color(.black.opacity(0.35)), style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
        }
        ctx.stroke(path, with: .color(colour), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, dash: dash))
    }

    /// The points as a screen path, lying on the cloth (height 0 reads better as a mark left on the table than ball
    /// height); nil when there are none or none of them projects. A point behind the camera is skipped and the path
    /// picks up again at the next point in front of it as a new piece (0.7.6, #26): the Ride camera sits low behind
    /// the cue ball, so the start of a path is behind it, and dropping the whole path for that point made the what-if's
    /// violet paths vanish for the whole chase.
    static func line(_ pts: [Vec2], _ proj: AimProjector) -> Path? {
        var path = Path()
        var drawing = false             // true while the current piece has a point on screen to continue from
        var any = false
        for p in pts {
            guard let s = proj.screen(p, height: 0.001) else { drawing = false; continue }
            if drawing { path.addLine(to: s) } else { path.move(to: s) }
            drawing = true
            any = true
        }
        return any ? path : nil
    }

    /// The smallest radius, screen points, a ring drawn by `ring` may have (0.7.6, #40): at whole-table framing on an
    /// upright phone a ball-radius ring is only a few points across and reads as a speck.
    nonisolated static let minRingPoints: CGFloat = 7

    /// How large `radius` metres round `centre` on the cloth looks on screen, points: the mean of its reach along the
    /// table's two axes (the camera's tilt squeezes one of them). Nil when the spot or either reach is behind the camera.
    static func screenRadius(at centre: Vec2, radius: Double, _ proj: AimProjector) -> CGFloat? {
        guard let c = proj.screen(centre, height: 0.001),
              let x = proj.screen(centre + Vec2(radius, 0), height: 0.001),
              let y = proj.screen(centre + Vec2(0, radius), height: 0.001) else { return nil }
        func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
        return (distance(c, x) + distance(c, y)) / 2
    }

    /// The factor `radius` metres round `centre` must grow by to be at least `minPoints` on screen: 1 when it already is,
    /// when the size cannot be measured, or when `minPoints` is zero.
    static func floorScale(at centre: Vec2, radius: Double, minPoints: CGFloat, _ proj: AimProjector) -> Double {
        guard minPoints > 0, radius > 0, let seen = screenRadius(at: centre, radius: radius, proj), seen > 0.01 else { return 1 }
        return max(1, Double(minPoints / seen))
    }

    /// A closed ring on the cloth, `radius` metres round a spot (a ball radius round a resting spot, as a rule), but never
    /// under `minPoints` in radius on screen (0.7.6, #40); nil when any of it is behind the camera.
    static func ring(at centre: Vec2, radius: Double, _ proj: AimProjector, minPoints: CGFloat = TablePathStroke.minRingPoints,
                     segments: Int = 36) -> Path? {
        let r = radius * floorScale(at: centre, radius: radius, minPoints: minPoints, proj)
        var ring = Path()
        for i in 0..<segments {
            let a = Double(i) / Double(segments) * 2 * Double.pi
            guard let s = proj.screen(centre + Vec2(cos(a), sin(a)) * r, height: 0.001) else { return nil }
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

    private var visible: Bool { Self.shows(model, dismissed: dismissedVersion, seeked: seekedVersion) }

    /// When the comparison shows: free play only, once the retry has played out (so it never talks over the shot) or
    /// while the replay is paused at its contact, until put away for this recording. Shared by this card and the
    /// upright phone's blurb (ComparisonPhoneBlurb), each keeping its own dismissed and seeked versions.
    static func shows(_ model: ShowpieceModel, dismissed: Int, seeked: Int) -> Bool {
        guard model.retryComparison != nil, dismissed != model.timelineVersion,
              !model.trickMode.isActive, !model.eightBallMode.isActive, !model.lessonMode.isActive,
              model.match == nil, !model.otherFutureShowing else { return false }
        return model.aimReady || seeked == model.timelineVersion
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
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Dismiss comparison")
            }
            .glassCard(cornerRadius: 20, padding: 12)
            .accessibilityElement(children: .contain)
            .transition(.opacity)
        }
    }
}

/// The retry comparison on the upright phone (plans/22-Nov-2026-phone-ui-plan.md, Part 3): the same sentence as
/// ComparisonCard, as a docked blurb sized to its words, with See the contact and Close as its two small buttons. Shows
/// exactly when the card would (ComparisonCard.shows) and adds no height to the dock when it does not.
struct ComparisonPhoneBlurb: View {
    let model: ShowpieceModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// As the card: the recording whose comparison was put away, and the one paused at its contact.
    @State private var dismissedVersion = -1
    @State private var seekedVersion = -1

    var body: some View {
        if ComparisonCard.shows(model, dismissed: dismissedVersion, seeked: seekedVersion),
           let c = model.retryComparison {
            let text = RetryWords.sentence(c)
            Blurb(sentence: String(localized: "Compared with your last try. \(text)"), buttons: buttons)
        }
    }

    private var buttons: [BlurbButton] {
        var list: [BlurbButton] = []
        if model.firstContactTime != nil {
            list.append(BlurbButton(String(localized: "See the contact"),
                                    hint: String(localized: "Pauses the replay where the cue ball first touched a ball")) {
                seeContact()
            })
        }
        list.append(BlurbButton(String(localized: "Close")) { dismissedVersion = model.timelineVersion })
        return list
    }

    /// What ContactButton (RetryWords.swift) does on a press, for the blurb's own button: Ride steps aside under Reduce
    /// Motion (no camera flight), the replay stops at the first contact, the arrival line is told which recording it
    /// stopped on, the blurb stays up while the replay sits there, and VoiceOver hears what to look at.
    private func seeContact() {
        if reduceMotion && model.rideOn { model.setRide(false) }
        model.seekToFirstContact()
        ContactArrival.shared.version = model.timelineVersion
        seekedVersion = model.timelineVersion
        ShotNarration.announce(ContactArrivalLine.words(ghost: model.ghost != nil))
    }
}
