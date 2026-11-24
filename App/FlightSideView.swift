// Author: Claude Opus 5.5 Medium
// Date: 24-November-2026
// PURPOSE: The side view of a jump (0.7.8, plans/24-Nov-2026-jump-replay-plan.md, Part 3). While a take-off caption is
//          up in the Physics Lens, a small glass panel beside the flight shows it side on, at true scale: the cloth as
//          a line, the ball it jumps as a circle sitting on it, the flying ball's arc from take-off to landing, and a
//          marker from the cloth up to the ball at the top of its flight. The overhead view can only show a jump as a
//          dashed line; this shows the height and the gap over the blocker as a picture. The whole arc shows while the
//          beat holds at the take-off (what is about to happen), the flown part bright and a ball at the replay's own
//          moment as it plays on, so it follows the clock and needs no animation of its own (Reduce Motion included).
//          Three parts: FlightShape (the flight's side profile in table metres, built once per caption from the same
//          flight lookups the caption's numbers come from, CaptionEngine.flightSegment and flightTop, so picture and words
//          cannot disagree); FlightSketch (that shape with this frame's progress and the flight's place on screen,
//          which LeaderState keeps); FlightSideView (the drawing) and FlightSideView.center (where the panel goes:
//          below, above, right or left of the flight on screen, whichever first lies wholly on the table, under the
//          title row, clear of the card, the chip and the flight itself; failing those, the nearest free place on the
//          table; nowhere if nothing fits, so it never covers
//          the balls or the words; on the open Duo the table half only).
//          Decoration only: hidden from VoiceOver (the caption already speaks the height) and never takes touches.
// SRP/DRY check: Pass - checked Captions.swift (the flight lookups are reused, not copied), CaptionLeader (the chip's
//          placement rules are followed in the same order, with the panel added as one more thing to keep clear of),
//          LensLayer (draws the flight from above in 3D; nothing drew it side on).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

/// A jump's flight seen side on, in table metres: `along` is the distance from the take-off point toward the landing
/// point, `up` the height of the ball's centre above the cloth.
struct FlightShape: Equatable {
    /// Clock times the flight starts and ends.
    let t0: Double
    let t1: Double
    /// The flying ball's centre through the flight, sampled evenly in time (along, up).
    let arc: [SIMD2<Double>]
    /// The jumped ball's centre (along, up), when the flight passes over one.
    let blocker: SIMD2<Double>?
    /// The top of the flight: where it is along, and the height of the ball's lowest point there.
    let peakAlong: Double
    let peakGap: Double
    let radius: Double
    /// Take-off and landing points on the cloth, table metres (for the panel's place on screen).
    let from: Vec2
    let to: Vec2

    /// True when `caption` is a jump's take-off. Its lead figure (the flight height) is left off beside the ball: the
    /// caption's title already carries it and the side view draws it, and the Boss found it said too often (0.7.8).
    static func isTakeOff(_ caption: Caption, in timeline: Timeline) -> Bool {
        timeline.events.indices.contains(caption.id) && timeline.events[caption.id].flight == .takeOff
    }

    /// The flight a take-off caption is about, or nil when the caption is not a take-off or the flight has no length.
    static func make(caption: Caption, timeline: Timeline) -> FlightShape? {
        guard timeline.events.indices.contains(caption.id) else { return nil }
        let e = timeline.events[caption.id]
        guard e.kind == .phaseTransition, e.flight == .takeOff, let ball = e.balls.first?.ball,
              let seg = CaptionEngine.flightSegment(ball: ball, startingAt: e.time, in: timeline), seg.t1.isFinite,
              seg.t1 > seg.t0 else { return nil }
        let R = timeline.table.ballRadius
        let from = seg.position0, to = seg.kinematics(at: seg.t1).position
        let line = (to - from).normalized
        guard (to - from).length > 1e-4 else { return nil }
        let steps = 48
        var arc: [SIMD2<Double>] = []
        var top = (along: 0.0, gap: -Double.infinity)
        for i in 0...steps {
            let k = seg.kinematics(at: seg.t0 + (seg.t1 - seg.t0) * Double(i) / Double(steps))
            let along = (k.position - from).dot(line)
            arc.append(SIMD2(along, k.height + R))
            if k.height > top.gap { top = (along, k.height) }
        }
        let over = CaptionEngine.flightTop(seg, ball: ball, in: timeline).over
        let blocker = over.map { o -> SIMD2<Double> in
            let s = timeline.state(ball: o.ball, at: seg.t0)
            return SIMD2((s.position - from).dot(line), s.height + R)
        }
        return FlightShape(t0: seg.t0, t1: seg.t1, arc: arc, blocker: blocker, peakAlong: top.along,
                           peakGap: max(0, top.gap), radius: R, from: from, to: to)
    }
}

/// One frame's side view: the shape, how far through the flight the replay is (0 to 1, in fortieths so a slow replay
/// redraws at most forty times), and where the flight lies on screen (StageSpace, whole points).
struct FlightSketch: Equatable {
    var captionID: Int
    var shape: FlightShape
    var progress: Double
    var screen: CGRect
    /// The flight runs right to left on screen: the panel is mirrored so it reads the same way as the table.
    var leftward: Bool
}

struct FlightSideView: View {
    let sketch: FlightSketch
    let accent: Color
    /// The panel's size, points (one of `sizes`, chosen by `center`).
    let size: CGSize
    @Environment(\.palette) private var palette

    /// The sizes tried, largest first: as wide as the table allows up to 330 points (a long flight at true scale keeps
    /// its balls large enough to read), then a compact one for a crowded screen.
    static func sizes(in bounds: CGRect, gap: CGFloat) -> [CGSize] {
        [CGSize(width: min(330, bounds.width - 2 * gap), height: 112), CGSize(width: 176, height: 80)]
            .filter { $0.width >= 176 }
    }

    var body: some View {
        Canvas { ctx, size in draw(in: &ctx, size: size) }
            .frame(width: size.width, height: size.height)
            .glassEffect(.regular.tint(accent.opacity(0.10)), in: .rect(cornerRadius: 14))
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    private func draw(in ctx: inout GraphicsContext, size: CGSize) {
        let s = sketch.shape
        let R = s.radius
        // What has to fit: every arc point and the blocker, a ball's radius round each, the cloth under them.
        var lo = s.arc.map(\.x).min() ?? 0, hi = s.arc.map(\.x).max() ?? 0
        var top = s.arc.map(\.y).max() ?? R
        if let b = s.blocker { lo = min(lo, b.x); hi = max(hi, b.x); top = max(top, b.y) }
        lo -= R; hi += R; top += R
        let marginX: CGFloat = 14, marginTop: CGFloat = 10, marginBottom: CGFloat = 14
        let scale = min((size.width - 2 * marginX) / CGFloat(max(hi - lo, 1e-3)),
                        (size.height - marginTop - marginBottom) / CGFloat(max(top, 1e-3)))
        let base = size.height - marginBottom
        let spare = size.width - 2 * marginX - CGFloat(hi - lo) * scale
        func point(_ p: SIMD2<Double>) -> CGPoint {
            var x = marginX + spare / 2 + CGFloat(p.x - lo) * scale
            if sketch.leftward { x = size.width - x }
            return CGPoint(x: x, y: base - CGFloat(p.y) * scale)
        }
        let r = CGFloat(R) * scale
        func ball(at c: CGPoint) -> CGRect { CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r) }

        // The cloth.
        var cloth = Path()
        cloth.move(to: CGPoint(x: marginX * 0.5, y: base)); cloth.addLine(to: CGPoint(x: size.width - marginX * 0.5, y: base))
        ctx.stroke(cloth, with: .color(palette.paper.opacity(0.55)), lineWidth: 1.5)

        // The jumped ball, sitting on the cloth.
        if let b = s.blocker {
            let rect = ball(at: point(b))
            ctx.fill(Path(ellipseIn: rect), with: .color(palette.paper.opacity(0.18)))
            ctx.stroke(Path(ellipseIn: rect), with: .color(palette.paper.opacity(0.7)), lineWidth: 1.2)
        }

        // The whole flight faint and dashed, the part already flown bright.
        var whole = Path()
        for (i, p) in s.arc.enumerated() { i == 0 ? whole.move(to: point(p)) : whole.addLine(to: point(p)) }
        ctx.stroke(whole, with: .color(accent.opacity(0.45)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
        let n = s.arc.count - 1
        let flown = max(0, min(n, Int((sketch.progress * Double(n)).rounded())))
        if flown > 0 {
            var done = Path()
            for i in 0...flown { i == 0 ? done.move(to: point(s.arc[i])) : done.addLine(to: point(s.arc[i])) }
            ctx.stroke(done, with: .color(accent), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        // The height marker: from the cloth up to the ball's underside at the top of the flight.
        let peakX = point(SIMD2(s.peakAlong, 0)).x
        let under = base - CGFloat(s.peakGap) * scale
        if base - under > 3 {
            var tick = Path()
            tick.move(to: CGPoint(x: peakX, y: base)); tick.addLine(to: CGPoint(x: peakX, y: under))
            for y in [base, under] {
                tick.move(to: CGPoint(x: peakX - 4, y: y)); tick.addLine(to: CGPoint(x: peakX + 4, y: y))
            }
            ctx.stroke(tick, with: .color(palette.paper.opacity(0.9)), lineWidth: 1.2)
            // The ball at the top, faint, so the marker visibly ends at its underside.
            if let peak = s.arc.min(by: { abs($0.x - s.peakAlong) < abs($1.x - s.peakAlong) }) {
                ctx.stroke(Path(ellipseIn: ball(at: point(peak))), with: .color(accent.opacity(0.5)), lineWidth: 1)
            }
        }

        // The flying ball where the replay is now (at the take-off while the beat holds).
        let now = point(s.arc[flown])
        ctx.fill(Path(ellipseIn: ball(at: now)), with: .color(palette.paper))
        ctx.stroke(Path(ellipseIn: ball(at: now)), with: .color(accent), lineWidth: 1.5)
    }

    /// Where the panel's centre goes: below, above, right or left of the flight on screen, whichever first lies wholly
    /// inside `bounds`, at or under `top`, above `bottom`, and clear of every rect in `avoid` (the card, the chip, the
    /// flight itself with a ring's margin). Nil when none fits: then the panel is not drawn.
    static func center(flight: CGRect, bounds: CGRect, top: CGFloat, bottom: CGFloat, avoid: [CGRect],
                       gap: CGFloat) -> (point: CGPoint, size: CGSize)? {
        for size in sizes(in: bounds, gap: gap) {
            if let c = center(flight: flight, size: size, bounds: bounds, top: top, bottom: bottom, avoid: avoid,
                              gap: gap) { return (c, size) }
        }
        return nil
    }

    private static func center(flight: CGRect, size: CGSize, bounds: CGRect, top: CGFloat, bottom: CGFloat,
                               avoid: [CGRect], gap: CGFloat) -> CGPoint? {
        let w = size.width, h = size.height
        let keep = flight.insetBy(dx: -CaptionLeader.ringRadius, dy: -CaptionLeader.ringRadius)
        let minX = bounds.minX + gap, maxX = bounds.maxX - gap
        func clampX(_ x: CGFloat) -> CGFloat { min(max(x, minX + w / 2), max(minX + w / 2, maxX - w / 2)) }
        func clampY(_ y: CGFloat) -> CGFloat { min(max(y, top + h / 2), max(top + h / 2, bottom - h / 2)) }
        let candidates = [
            CGPoint(x: clampX(keep.midX), y: keep.maxY + gap + h / 2),
            CGPoint(x: clampX(keep.midX), y: keep.minY - gap - h / 2),
            CGPoint(x: keep.maxX + gap + w / 2, y: clampY(keep.midY)),
            CGPoint(x: keep.minX - gap - w / 2, y: clampY(keep.midY)),
        ]
        func fits(_ c: CGPoint) -> Bool {
            let r = CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h)
            return r.minX >= minX - 0.5 && r.maxX <= maxX + 0.5 && r.minY >= top - 0.5 && r.maxY <= bottom + 0.5
                && !r.intersects(keep) && !avoid.contains(where: { !$0.isEmpty && $0.intersects(r) })
        }
        for c in candidates where fits(c) { return c }
        // None of the four sides has room (the upright phone, with its blurb under the moment): the free place nearest
        // the flight, searched on a 12-point grid over the table, so the panel still lands in the open space beside it.
        var best: (point: CGPoint, distance: CGFloat)?
        var y = top + h / 2
        while y <= bottom - h / 2 {
            var x = minX + w / 2
            while x <= maxX - w / 2 {
                let c = CGPoint(x: x, y: y)
                let d = hypot(c.x - keep.midX, c.y - keep.midY)
                if d < (best?.distance ?? .infinity), fits(c) { best = (c, d) }
                x += 12
            }
            y += 12
        }
        return best?.point
    }
}
