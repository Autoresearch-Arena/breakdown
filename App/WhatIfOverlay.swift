// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          stream whatif item 5: the stub filled in.)
// PURPOSE: Draws the other future of a what-if over the table (and over the Physics Lens): for at most three balls
//          whose futures changed (the cue ball, the ball it struck first, the first ball whose drop changed) the
//          alternate path in the what-if violet, faint ahead of the clock and strong up to it, dotted so it reads
//          without colour; a hollow ghost ball rolling with the real ones (past the real shot's end it keeps rolling on
//          the what-if's own tail clock until the other future stops); rings where the other balls stop and a
//          "What if" pill at the other cue ball's rest (not in the notebook layouts, where the card sits beside the
//          table); and a diamond where the two futures part, with two short ticks along the real (paper) and the other
//          (violet) headings. The paths are sampled once per result; each frame only projects them through the live
//          camera, so the drawing follows the swing into the Lens. While a new solve runs the last result is drawn at
//          half strength. Never takes touches and is hidden from VoiceOver (the card speaks the result).
//          ShowpieceView mounts it only while model.whatIf.isShowing; the last-try ghost and the stroke trace step
//          aside meanwhile. It also tells the fork when the clock moves, which starts and ends the tail clock.
// SRP/DRY check: Pass - the GhostOverlay pattern (TimelineView, Canvas, AimProjector, TablePathStroke for the paths,
//          rings and pill), sampling through ShotAttempt.path(of:); no second path, ring or label drawing.
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

/// The other future's paths, ghosts and parting marker over the table.
struct WhatIfOverlay: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Environment(\.palette) private var palette
    @Environment(\.inlinePages) private var inlinePages
    @State private var cameraBox = AimProjector.CameraBox()
    /// The drawn balls' alternate paths, sampled once per result (the fork's resultVersion).
    @State private var sampled: Sampled = Sampled()

    struct Sampled {
        var version = -1
        var balls: [Int] = []
        var paths: [Int: [Vec2]] = [:]
    }

    /// Ball-height marks sit just above the cloth, as the last try's ghost does.
    private static let onCloth: Float = 0.001

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in draw(&ctx, size: size, now: context.date) }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onChange(of: model.whatIf.resultVersion, initial: true) { _, version in sample(version) }
        .onChange(of: model.time) { old, new in model.whatIf.clockMoved(from: old, to: new) }
    }

    /// Which balls to draw and their paths: the cue ball, the first ball it struck (in either future), and the first
    /// ball whose drop changed, each only when its future changed; at most three.
    private func sample(_ version: Int) {
        guard let r = model.whatIf.result, let real = model.whatIf.real else {
            sampled = Sampled(version: version)
            return
        }
        let alt = r.alternate
        let changed = Set(r.fork.changedBalls)
        let dropChanged = r.fork.changedBalls.first { b in
            (real.timeline.pocketTime[b] == nil) != (alt.timeline.pocketTime[b] == nil)
        }
        var balls: [Int] = []
        for b in [real.cueBall, alt.firstStruck ?? real.firstStruck, dropChanged].compactMap({ $0 })
        where changed.contains(b) && !balls.contains(b) && balls.count < 3 {
            balls.append(b)
        }
        var paths: [Int: [Vec2]] = [:]
        for b in balls { paths[b] = alt.path(of: b) }
        sampled = Sampled(version: version, balls: balls, paths: paths)
    }

    /// The clock the ghosts follow: the real clock, or past the real end the tail clock (wall time since the real
    /// recording ended, at the chosen speed), never past the other future's own end. Before the clock has moved at
    /// all (the what-if just opened on a finished shot) the other future is shown where it ended.
    private func ghostTime(_ alt: ShotAttempt, now: Date) -> Double {
        if let start = model.whatIf.tailStart {
            let rate = model.chosenRate ?? 1
            return min(model.duration + now.timeIntervalSince(start) * rate, alt.timeline.duration)
        }
        if !model.whatIf.clockHasMoved && model.time >= model.duration - 1e-6 { return alt.timeline.duration }
        return model.time
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, now: Date) {
        let fork = model.whatIf
        guard fork.isShowing, let r = fork.result, sampled.version == fork.resultVersion, let real = fork.real,
              let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return }
        let alt = r.alternate
        // A solve in flight for other settings: the last future stays, at half strength.
        let strength = fork.solving || r.steps != fork.steps ? 0.5 : 1.0
        let violet = palette.whatIf, paper = palette.paper
        let radius = alt.timeline.table.ballRadius
        let t = ghostTime(alt, now: now)

        for b in sampled.balls {
            guard let forecast = sampled.paths[b], !forecast.isEmpty else { continue }
            // The whole other path, faint: the forecast. Dotted, so it reads without its colour, over a dark line.
            TablePathStroke(points: forecast, colour: violet.opacity(0.25 * strength), lineWidth: 2, dash: [1.5, 4],
                            underlayWidth: 4).draw(in: &ctx, proj)
            // The stretch up to the clock, strong. Sampled each frame from the recording: at most three short paths.
            let travelled = Self.travelled(alt, ball: b, until: t)
            if travelled.count > 1 {
                TablePathStroke(points: travelled, colour: violet.opacity(0.9 * strength), lineWidth: 2,
                                dash: [1.5, 4]).draw(in: &ctx, proj)
            }
            // The hollow ghost ball, gone from the moment a pocket takes it.
            if alt.timeline.pocketTime[b].map({ t < $0 }) ?? true,
               let ring = TablePathStroke.ring(at: alt.timeline.state(ball: b, at: t).position, radius: radius, proj) {
                ctx.stroke(ring, with: .color(.black.opacity(0.45 * strength)), style: StrokeStyle(lineWidth: 3.5))
                ctx.stroke(ring, with: .color(violet.opacity(0.95 * strength)), style: StrokeStyle(lineWidth: 1.8))
            }
            // Where it comes to rest in the other future: a dashed ring, as the last try's.
            if alt.timeline.pocketTime[b] == nil,
               let rest = TablePathStroke.ring(at: alt.timeline.state(ball: b, at: alt.timeline.duration).position,
                                              radius: radius, proj) {
                ctx.stroke(rest, with: .color(violet.opacity(0.75 * strength)), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            }
        }

        // The pill at the other cue ball's rest, beside the table only (the notebook has the card next to it).
        if !inlinePages, sampled.balls.contains(real.cueBall), !alt.cueBallScratched {
            TablePathStroke.label(Text(WhatIfWords.title), at: alt.cueRest, colour: violet.opacity(strength),
                                  in: &ctx, size: size, proj)
        }

        // The parting marker: a small filled diamond with two ticks, paper along the real heading, violet along the
        // other.
        guard let m = r.fork.marker, let c = proj.screen(m.point, height: Self.onCloth) else { return }
        let d: CGFloat = 6
        var diamond = Path()
        diamond.move(to: CGPoint(x: c.x, y: c.y - d))
        diamond.addLine(to: CGPoint(x: c.x + d, y: c.y))
        diamond.addLine(to: CGPoint(x: c.x, y: c.y + d))
        diamond.addLine(to: CGPoint(x: c.x - d, y: c.y))
        diamond.closeSubpath()
        ctx.stroke(diamond, with: .color(.black.opacity(0.55 * strength)), style: StrokeStyle(lineWidth: 3, lineJoin: .round))
        ctx.fill(diamond, with: .color(violet.opacity(strength)))
        for (heading, colour) in [(m.realHeading, paper), (m.alternateHeading, violet)] {
            guard let tip = Self.tick(from: m.point, heading: heading, at: c, proj) else { continue }
            var line = Path()
            line.move(to: c)
            line.addLine(to: tip)
            ctx.stroke(line, with: .color(.black.opacity(0.5 * strength)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            ctx.stroke(line, with: .color(colour.opacity(strength)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
    }

    /// The end of an 8-point tick from the marker along a heading on the table, as the camera sees that heading.
    private static func tick(from point: Vec2, heading: Vec2, at c: CGPoint, _ proj: AimProjector) -> CGPoint? {
        guard heading.lengthSquared > 1e-12, let ahead = proj.screen(point + heading * 0.05, height: onCloth) else {
            return nil
        }
        let dx = ahead.x - c.x, dy = ahead.y - c.y
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 0.5 else { return nil }
        let length8: CGFloat = 8 + 6   // past the diamond's own half-width, so the tick shows beside it
        return CGPoint(x: c.x + dx / length * length8, y: c.y + dy / length * length8)
    }

    /// The other future's path of one ball from its start to clock `t` (or to its pocket), sixty samples a second.
    private static func travelled(_ alt: ShotAttempt, ball: Int, until t: Double) -> [Vec2] {
        let end = min(t, alt.timeline.pocketTime[ball] ?? alt.timeline.duration)
        guard end > 0 else { return [] }
        let steps = max(1, Int(end * 60))
        var out: [Vec2] = []
        out.reserveCapacity(steps + 1)
        for i in 0...steps {
            let p = alt.timeline.state(ball: ball, at: end * Double(i) / Double(steps)).position
            if let last = out.last, (p - last).lengthSquared < 1e-8 { continue }
            out.append(p)
        }
        return out
    }
}
