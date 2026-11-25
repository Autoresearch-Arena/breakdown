// Author: Claude Opus 5.5 Medium
// Date: 24-November-2026
// Edited: Claude Opus 5.5 Medium, 25-November-2026 (0.7.9, plans/24-Nov-2026-jump-replay-plan.md "Next": the side view
//          tells the whole jump. FlightShape is now the jump's story, from the first take-off through every hop until
//          the ball stays on the cloth, and FlightFocus says which part of it the caption on screen is about (the raised
//          strike, a take-off, a landing). When a raised cue strike made the jump, the cue comes down onto the ball at
//          its real tilt (CaptionEngine.raisedCueAngle). At the push the caption is about, two arrows show it: down
//          into the slate and back up off it, on one scale for the whole story, so the slate's smaller give-back reads
//          as a shorter arrow. A landing draws the distance it flew along the cloth. The panel keeps one identity
//          (FlightStoryKey) for the whole story, so it stays up from the strike to the last hop. The drawing has two
//          styles, glass for the game and a dark card for Lens clips (glass cannot go into a video), and
//          FlightSketch.make builds a frame's sketch from any projection, the game's camera or a clip's. On the upright
//          phone the picture sits inside the jump's explanation blurb (inline style) instead of floating beside it:
//          there is no room on that screen for the action, a blurb and a separate panel.)
// PURPOSE: The side view of a jump (0.7.8, Part 3 of the jump replay plan; the whole story since 0.7.9). While a caption
//          about a jump is up in the Physics Lens, a small panel beside the flight shows it side on, at true scale: the
//          cloth as a line with the slate under it, the ball it jumps as a circle sitting on it, the flying ball's arc
//          through every hop, a marker from the cloth up to the ball at the top of the first flight (the height the
//          take-off card's title says), the cue coming down onto the ball when a raised strike made the jump, and at
//          the push the caption is about, arrows down into the slate and back up. The whole story shows faint while a
//          beat holds (what is about to happen), the flown part bright and a ball at the replay's own moment as it
//          plays on, so it follows the clock and needs no animation of its own (Reduce Motion included).
//          Parts: FlightShape (the jump's side profile in table metres, built once per caption from the same flight
//          lookups the captions' numbers come from, CaptionEngine.flightSegment, flightTop and raisedCueAngle, so
//          picture and words cannot disagree); FlightFocus (which part the caption is about); FlightSketch (the shape
//          with this frame's clock and the part's place on screen, made by FlightSketch.make from any projection);
//          FlightSideView (the drawing, in glass for the game or on a dark card for a clip) and FlightSideView.center
//          (where the panel goes: below, above, right or left of the part in focus, whichever first lies wholly on the
//          table, under the title row, clear of the card, the chip and the flight itself; failing those, the nearest
//          free place on the table; nowhere if nothing fits, so it never covers the balls or the words; on the open Duo
//          the table half only).
//          Decoration only: hidden from VoiceOver (the caption already speaks the numbers) and never takes touches. No
//          words are drawn in it, so it needs no translation.
// SRP/DRY check: Pass - checked Captions.swift (the flight and cue lookups are reused, not copied), CaptionLeader (the
//          chip's placement rules are followed in the same order, with the panel added as one more thing to keep clear
//          of), LensLayer (draws the flight from above in 3D; nothing drew it side on) and ClipOverlay (its note's dark
//          card is the film style here; the clip draws this same view, never its own copy).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

/// Which part of a jump the caption on screen is about.
enum FlightFocus: Hashable, Sendable {
    /// The raised cue strike that threw the ball up: the cause.
    case strike
    /// A hop's take-off (an index into FlightShape.hops).
    case takeOff(Int)
    /// A hop's landing (an index into FlightShape.hops).
    case landing(Int)
}

/// Names one jump: the ball and the clock of its first take-off. The panel keeps this identity, so it stays up rather
/// than fading out and back in when the caption moves from the strike to the take-off to a landing of the same jump.
struct FlightStoryKey: Hashable, Sendable {
    let ball: Int
    let t0: Double
}

/// A jump seen side on, in table metres: `along` is the distance from the first take-off point toward the first
/// landing point, `up` the height of the ball's centre above the cloth.
struct FlightShape: Equatable {
    /// One flight between two touches of the cloth.
    struct Hop: Equatable {
        let t0: Double
        let t1: Double
        /// Take-off and landing points on the cloth, table metres.
        let from: Vec2
        let to: Vec2
        /// The same two points along the side view's line.
        let fromAlong: Double
        let toAlong: Double
    }

    /// A push at the cloth: where along the line, how fast the ball went down into the slate, and how fast the slate
    /// threw it back up (0 when it stayed on the cloth).
    struct Kick: Equatable {
        let along: Double
        let down: Double
        let up: Double
    }

    let ball: Int
    /// Clock times the story starts (the first take-off) and ends (the last landing).
    let t0: Double
    let t1: Double
    /// The flying ball's centre through every hop (along, up), in clock order, and the clock of each sample.
    let arc: [SIMD2<Double>]
    let times: [Double]
    let hops: [Hop]
    /// The push at the first take-off, and the push at each hop's landing (nil where no landing was recorded, as when
    /// the ball leaves the table).
    let launch: Kick?
    let landings: [Kick?]
    /// The jumped ball's centre (along, up), when the first flight passes over one.
    let blocker: SIMD2<Double>?
    /// The top of the FIRST flight, the one the take-off card's title is about (CaptionEngine.flightTop, the same
    /// exact peak): where it is along, and the height of the ball's lowest point there. Never the story's highest
    /// point, so the picture and the title always agree.
    let peakAlong: Double
    let peakGap: Double
    let radius: Double
    /// The cue's tilt below the horizontal (radians) when a raised cue strike made the jump, else nil.
    let cueAngle: Double?

    var key: FlightStoryKey { FlightStoryKey(ball: ball, t0: t0) }
    /// The first flight's take-off and landing points on the cloth (table metres).
    var from: Vec2 { hops[0].from }
    var to: Vec2 { hops[0].to }

    /// True when `caption` is a jump's take-off. Its lead figure (the flight height) is left off beside the ball: the
    /// caption's title already carries it and the side view draws it, and the Boss found it said too often (0.7.8).
    static func isTakeOff(_ caption: Caption, in timeline: Timeline) -> Bool {
        timeline.events.indices.contains(caption.id) && timeline.events[caption.id].flight == .takeOff
    }

    /// The jump a caption is about, or nil when it is about none (FlightShape.story without the focus).
    static func make(caption: Caption, timeline: Timeline) -> FlightShape? {
        story(for: caption, in: timeline)?.shape
    }

    /// The jump a caption is about and which part of it: a raised cue strike that threw the ball up, a take-off, or a
    /// landing. Nil for every other caption, and for a jump with no length across the cloth (straight up and down).
    static func story(for caption: Caption, in timeline: Timeline) -> (shape: FlightShape, focus: FlightFocus)? {
        guard timeline.events.indices.contains(caption.id) else { return nil }
        let e = timeline.events[caption.id]
        guard let ball = e.balls.first?.ball, timeline.segments.indices.contains(ball) else { return nil }
        let segments = timeline.segments[ball]
        func starting(_ t: Double) -> Int? { segments.firstIndex { $0.phase == .airborne && abs($0.t0 - t) < 1e-9 } }
        switch (e.kind, e.flight) {
        case (.cueStrike, _):
            // Only a strike that threw the ball up at its own instant (the raised strike the strike caption explains).
            guard e.miscue != true, let i = starting(e.time), let built = build(ball: ball, segment: i, in: timeline),
                  built.hopOf[i] == 0 else { return nil }
            return (built.shape, .strike)
        case (.phaseTransition, .takeOff):
            guard let i = starting(e.time), let built = build(ball: ball, segment: i, in: timeline),
                  let hop = built.hopOf[i] else { return nil }
            return (built.shape, .takeOff(hop))
        case (.phaseTransition, .landing):
            guard let i = segments.lastIndex(where: { $0.phase == .airborne && abs($0.t1 - e.time) < 1e-9 }),
                  let built = build(ball: ball, segment: i, in: timeline), let hop = built.hopOf[i] else { return nil }
            return (built.shape, .landing(hop))
        default:
            return nil
        }
    }

    /// The whole jump through `ball`'s airborne segment `j`: back to the first take-off and on to the last landing,
    /// following airborne segments that start where the one before ended (an instant between them is skipped). The
    /// hops are split where the ball comes down to the cloth; a split in mid-air (a touch with another ball) stays in
    /// one hop. `hopOf` maps each segment index of the jump to its hop.
    private static func build(ball: Int, segment j: Int, in timeline: Timeline) -> (shape: FlightShape, hopOf: [Int: Int])? {
        let segs = timeline.segments[ball]
        func flying(_ i: Int) -> Bool {
            segs.indices.contains(i) && segs[i].phase == .airborne && segs[i].t1.isFinite && segs[i].t1 > segs[i].t0
        }
        func instant(_ i: Int) -> Bool { segs.indices.contains(i) && segs[i].t1.isFinite && segs[i].t1 - segs[i].t0 < 1e-9 }
        guard flying(j) else { return nil }
        var run = [j]
        var i = j - 1
        while i >= 0 {
            if instant(i) { i -= 1; continue }
            guard flying(i), abs(segs[i].t1 - segs[run[0]].t0) < 1e-7 else { break }
            run.insert(i, at: 0)
            i -= 1
        }
        i = j + 1
        while i < segs.count, run.count < 24 {
            if instant(i) { i += 1; continue }
            guard let last = run.last, flying(i), abs(segs[i].t0 - segs[last].t1) < 1e-7 else { break }
            run.append(i)
            i += 1
        }

        // Hops: a new one starts after each segment that ends with the ball down on the cloth.
        var groups: [[Int]] = [[]]
        for k in run {
            groups[groups.count - 1].append(k)
            if k != run.last, segs[k].kinematics(at: segs[k].t1).height <= 5e-4 { groups.append([]) }
        }
        let R = timeline.table.ballRadius
        let start = segs[run[0]].position0
        let firstEnd = segs[groups[0][groups[0].count - 1]]
        let firstTo = firstEnd.kinematics(at: firstEnd.t1).position
        guard (firstTo - start).length > 1e-4 else { return nil }
        let line = (firstTo - start).normalized
        func along(_ p: Vec2) -> Double { (p - start).dot(line) }

        // The arc, 40 samples a segment, and the hops' ends.
        var arc: [SIMD2<Double>] = [], times: [Double] = [], hops: [Hop] = [], hopOf: [Int: Int] = [:]
        for (h, group) in groups.enumerated() {
            for k in group {
                hopOf[k] = h
                let s = segs[k]
                let steps = 40
                for n in (arc.isEmpty ? 0 : 1)...steps {
                    let t = s.t0 + (s.t1 - s.t0) * Double(n) / Double(steps)
                    let kin = s.kinematics(at: t)
                    arc.append(SIMD2(along(kin.position), kin.height + R))
                    times.append(t)
                }
            }
            let a = segs[group[0]], b = segs[group[group.count - 1]]
            let from = a.position0, to = b.kinematics(at: b.t1).position
            hops.append(Hop(t0: a.t0, t1: b.t1, from: from, to: to, fromAlong: along(from), toAlong: along(to)))
        }

        // The first flight's top, exactly as the take-off card's title has it (flightTop's peak time and height).
        let first = segs[run[0]]
        let top = CaptionEngine.flightTop(first, ball: ball, in: timeline)
        let g = -first.verticalAcceleration
        let tPeak = g > 0 && first.verticalVelocity0 > 0 ? min(first.t1 - first.t0, first.verticalVelocity0 / g) : 0
        let peakAlong = along(first.kinematics(at: first.t0 + tPeak).position)
        let blocker = top.over.map { o -> SIMD2<Double> in
            let s = timeline.state(ball: o.ball, at: first.t0)
            return SIMD2(along(s.position), s.height + R)
        }

        // The pushes: the take-off's and each landing's, from the events the captions read.
        func event(_ mark: FlightMark, at t: Double) -> LensEvent? {
            timeline.events.first {
                $0.kind == .phaseTransition && $0.flight == mark && abs($0.time - t) < 1e-9 && $0.balls.first?.ball == ball
            }
        }
        let takeOff = event(.takeOff, at: first.t0)
        let launch = takeOff.map { Kick(along: 0, down: $0.verticalSpeedDown, up: $0.verticalSpeedUp) }
        let landings = hops.map { hop in
            event(.landing, at: hop.t1).map {
                Kick(along: hop.toAlong, down: $0.verticalSpeedDown, up: $0.phaseTo == .airborne ? $0.verticalSpeedUp : 0)
            }
        }
        let shape = FlightShape(ball: ball, t0: first.t0, t1: hops[hops.count - 1].t1, arc: arc, times: times,
                                hops: hops, launch: launch, landings: landings, blocker: blocker, peakAlong: peakAlong,
                                peakGap: max(0, top.peak), radius: R,
                                cueAngle: takeOff.flatMap { CaptionEngine.raisedCueAngle($0, in: timeline) })
        return (shape, hopOf)
    }

    /// The push the focus is about: the launch for the strike and the first take-off, the landing before a later
    /// take-off, a landing's own.
    func kick(_ focus: FlightFocus) -> Kick? {
        switch focus {
        case .strike: return launch
        case .takeOff(let h): return h <= 0 ? launch : landings.indices.contains(h - 1) ? landings[h - 1] : nil
        case .landing(let h): return landings.indices.contains(h) ? landings[h] : nil
        }
    }

    /// The stretch of cloth the part in focus covers (for the panel's place on screen): a flight's take-off and
    /// landing points; for a landing, where it came down and where its next hop lands (the point alone when it stays).
    /// The first flight over a jumped ball stops a ball's width past that ball, as the camera's own frame of the
    /// take-off does (PacePlan.takeOff): with the camera that close the landing is often off screen or under the card,
    /// and keeping clear of it would leave the panel nowhere to go.
    func span(_ focus: FlightFocus) -> (Vec2, Vec2) {
        let last = hops.count - 1
        func first() -> (Vec2, Vec2) {
            let hop = hops[0]
            guard let b = blocker, hop.toAlong > 1e-6 else { return (hop.from, hop.to) }
            let reach = min(hop.toAlong, b.x + 2 * radius)
            return (hop.from, hop.from + (hop.to - hop.from).normalized * reach)
        }
        switch focus {
        case .strike: return first()
        case .takeOff(let h):
            if h <= 0 { return first() }
            let hop = hops[min(h, last)]
            return (hop.from, hop.to)
        case .landing(let h):
            let i = min(max(h, 0), last)
            return (hops[i].to, i < last ? hops[i + 1].to : hops[i].to)
        }
    }

    /// A clock inside the story in steps of a 160th of it, so even a slow replay redraws the panel at most 160 times.
    func step(_ clock: Double) -> Double {
        let d = max(t1 - t0, 1e-6)
        let c = min(t1, max(t0, clock))
        return t0 + ((c - t0) / d * 160).rounded() / 160 * d
    }

    /// Where the flying ball is at `clock` (held to the story): its point on the cloth under it, table metres, and the
    /// height of its centre. The panel keeps clear of it on screen as well as of the stretch in focus (0.7.9).
    func ball(at clock: Double) -> (cloth: Vec2, centre: Double) {
        let p = arc[min(arc.count - 1, sample(at: clock))]
        let way = (hops[0].to - hops[0].from).normalized
        return (hops[0].from + way * p.x, p.y)
    }

    /// The last arc sample at or before `clock`.
    func sample(at clock: Double) -> Int {
        guard let i = times.lastIndex(where: { $0 <= clock + 1e-9 }) else { return 0 }
        return i
    }
}

/// One frame's side view: the jump, the part in focus, the replay's clock (in the shape's steps) and where the part in
/// focus lies on screen (whole points).
struct FlightSketch: Equatable {
    var captionID: Int
    var shape: FlightShape
    var focus: FlightFocus
    var now: Double
    var screen: CGRect
    /// The jump runs right to left on screen: the panel is mirrored so it reads the same way as the table.
    var leftward: Bool

    var key: FlightStoryKey { shape.key }

    /// This frame's sketch, from a projection of cloth points to the screen (the game's camera, or a clip's); nil when
    /// the part in focus is behind the camera. Which way the jump runs is read from its first flight, so the panel
    /// does not flip between parts of one story.
    static func make(captionID: Int, shape: FlightShape, focus: FlightFocus, clock: Double,
                     project: (Vec2) -> CGPoint?) -> FlightSketch? {
        let (a, b) = shape.span(focus)
        guard let pa = project(a), let pb = project(b) else { return nil }
        let rect = CGRect(x: min(pa.x, pb.x).rounded(), y: min(pa.y, pb.y).rounded(),
                          width: abs(pa.x - pb.x).rounded(), height: abs(pa.y - pb.y).rounded())
        let leftward: Bool
        if let f = project(shape.from), let t = project(shape.to) { leftward = t.x < f.x } else { leftward = pb.x < pa.x }
        return FlightSketch(captionID: captionID, shape: shape, focus: focus, now: shape.step(clock), screen: rect,
                            leftward: leftward)
    }
}

struct FlightSideView: View {
    /// Glass over the live table; a dark card in a Lens clip, where glass cannot be drawn (ClipOverlay's note); inline,
    /// no background of its own, inside the upright phone's explanation blurb (0.7.9, PhoneExplanation).
    enum Style { case glass, film, inline }

    let sketch: FlightSketch
    let accent: Color
    /// The panel's size, points (one of `sizes`, chosen by `center`).
    let size: CGSize
    var style: Style = .glass
    @Environment(\.palette) private var palette

    /// The sizes tried, largest first: as wide as the table allows up to 330 points (a long flight at true scale keeps
    /// its balls large enough to read), then a compact one for a crowded screen. Tall enough for the arrows down into
    /// the slate under the cloth and up off it.
    static func sizes(in bounds: CGRect, gap: CGFloat) -> [CGSize] {
        [CGSize(width: min(330, bounds.width - 2 * gap), height: 124), CGSize(width: 184, height: 92)]
            .filter { $0.width >= 184 }
    }

    var body: some View {
        let canvas = Canvas { ctx, size in draw(in: &ctx, size: size) }
            .frame(width: size.width, height: size.height)
        Group {
            switch style {
            case .glass:
                canvas.glassEffect(.regular.tint(accent.opacity(0.10)), in: .rect(cornerRadius: 14))
            case .inline:
                canvas
            case .film:
                canvas.background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.black.opacity(0.62))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.12)))
                }
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func draw(in ctx: inout GraphicsContext, size: CGSize) {
        let s = sketch.shape
        let R = s.radius
        let focus = sketch.focus
        let paper = palette.paper
        let cueColor = palette.color(for: CaptionAccent.strike)
        ctx.clip(to: Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 14))

        // The arrows' lengths, table metres, on one scale for every push of the story, so a slower push is a shorter
        // arrow: the longest is two ball radii, the shortest drawn three fifths of one.
        let pushes = ([s.launch] + s.landings).compactMap { $0 }
        let fastest = pushes.flatMap { [$0.down, $0.up] }.max() ?? 0
        func length(_ speed: Double) -> Double {
            fastest > 1e-6 && speed > 0.02 ? R * (0.6 + 1.4 * speed / fastest) : 0
        }

        // What has to fit: every arc point and the jumped ball with a radius round each, the arrows under the cloth and
        // over a ball on it, and the first two radii of the cue (the rest of it runs on out of the panel).
        var lo = (s.arc.map(\.x).min() ?? 0) - R, hi = (s.arc.map(\.x).max() ?? 0) + R
        var top = (s.arc.map(\.y).max() ?? R) + R
        if let b = s.blocker { lo = min(lo, b.x - R); hi = max(hi, b.x + R); top = max(top, b.y + R) }
        let under = pushes.map { length($0.down) }.max() ?? 0
        top = max(top, 2 * R + (pushes.map { length($0.up) }.max() ?? 0) + 0.4 * R)
        let below = under > 0 ? under + 0.4 * R : 0.3 * R
        let cueLine = s.cueAngle.map { a -> (tip: SIMD2<Double>, d: SIMD2<Double>) in
            // The cue's line runs forward and down through the ball's centre; its tip rests just off the ball.
            let d = SIMD2(cos(a), -sin(a))
            return (SIMD2(s.hops[0].fromAlong, R) - d * (1.12 * R), d)
        }
        if let c = cueLine {
            let near = c.tip - c.d * (2 * R)
            lo = min(lo, near.x); top = max(top, near.y)
        }

        let marginX: CGFloat = 12, marginTop: CGFloat = 8, marginBottom: CGFloat = 6
        let scale = min((size.width - 2 * marginX) / CGFloat(max(hi - lo, 1e-3)),
                        (size.height - marginTop - marginBottom) / CGFloat(max(top + below, 1e-3)))
        let base = size.height - marginBottom - CGFloat(below) * scale
        let spare = size.width - 2 * marginX - CGFloat(hi - lo) * scale
        func point(_ p: SIMD2<Double>) -> CGPoint {
            var x = marginX + spare / 2 + CGFloat(p.x - lo) * scale
            if sketch.leftward { x = size.width - x }
            return CGPoint(x: x, y: base - CGFloat(p.y) * scale)
        }
        let r = CGFloat(R) * scale
        func ball(at c: CGPoint) -> CGRect { CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r) }
        func arrow(from a: CGPoint, to b: CGPoint) -> Path {
            var p = Path()
            p.move(to: a); p.addLine(to: b)
            let head = max(4, min(8, r * 0.55))
            let dx = b.x - a.x, dy = b.y - a.y, n = max(hypot(dx, dy), 1e-3)
            let ux = dx / n, uy = dy / n
            p.move(to: CGPoint(x: b.x - head * ux + head * 0.6 * uy, y: b.y - head * uy - head * 0.6 * ux))
            p.addLine(to: b)
            p.addLine(to: CGPoint(x: b.x - head * ux - head * 0.6 * uy, y: b.y - head * uy + head * 0.6 * ux))
            return p
        }

        // The slate under the cloth, faint, and the cloth's line.
        ctx.fill(Path(CGRect(x: 0, y: base, width: size.width, height: size.height - base)),
                 with: .color(paper.opacity(0.06)))
        var cloth = Path()
        cloth.move(to: CGPoint(x: marginX * 0.5, y: base)); cloth.addLine(to: CGPoint(x: size.width - marginX * 0.5, y: base))
        ctx.stroke(cloth, with: .color(paper.opacity(0.55)), lineWidth: 1.5)

        // A landing: how far that flight carried, along the cloth, with a tick at each end.
        if case .landing(let h) = focus, s.hops.indices.contains(h) {
            let a = point(SIMD2(s.hops[h].fromAlong, 0)), b = point(SIMD2(s.hops[h].toAlong, 0))
            var span = Path()
            span.move(to: a); span.addLine(to: b)
            for x in [a.x, b.x] { span.move(to: CGPoint(x: x, y: base - 5)); span.addLine(to: CGPoint(x: x, y: base + 5)) }
            ctx.stroke(span, with: .color(accent), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }

        // The jumped ball, sitting on the cloth.
        if let b = s.blocker {
            let rect = ball(at: point(b))
            ctx.fill(Path(ellipseIn: rect), with: .color(paper.opacity(0.18)))
            ctx.stroke(Path(ellipseIn: rect), with: .color(paper.opacity(0.7)), lineWidth: 1.2)
        }

        // The whole story faint and dashed, the part already flown bright.
        var whole = Path()
        for (i, p) in s.arc.enumerated() { i == 0 ? whole.move(to: point(p)) : whole.addLine(to: point(p)) }
        ctx.stroke(whole, with: .color(accent.opacity(0.45)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
        let flown = min(s.arc.count - 1, s.sample(at: sketch.now))
        if flown > 0 {
            var done = Path()
            for i in 0...flown { i == 0 ? done.move(to: point(s.arc[i])) : done.addLine(to: point(s.arc[i])) }
            ctx.stroke(done, with: .color(accent), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        // The height marker of the first flight, from the take-off on: from the cloth up to the ball's underside at the
        // top, bright while the first take-off is the caption, faint after.
        if focus != .strike {
            let peakX = point(SIMD2(s.peakAlong, 0)).x
            let underside = base - CGFloat(s.peakGap) * scale
            if base - underside > 3 {
                let strength = focus == .takeOff(0) ? 0.9 : 0.4
                var tick = Path()
                tick.move(to: CGPoint(x: peakX, y: base)); tick.addLine(to: CGPoint(x: peakX, y: underside))
                for y in [base, underside] {
                    tick.move(to: CGPoint(x: peakX - 4, y: y)); tick.addLine(to: CGPoint(x: peakX + 4, y: y))
                }
                ctx.stroke(tick, with: .color(paper.opacity(strength)), lineWidth: 1.2)
                // The ball at the top, faint, so the marker visibly ends at its underside.
                if let peak = s.arc.prefix(through: max(0, min(s.arc.count - 1, s.sample(at: s.hops[0].t1))))
                    .min(by: { abs($0.x - s.peakAlong) < abs($1.x - s.peakAlong) }) {
                    ctx.stroke(Path(ellipseIn: ball(at: point(peak))), with: .color(accent.opacity(strength * 0.55)),
                               lineWidth: 1)
                }
            }
        }

        // The push the caption is about: the ball on the cloth where it happened, an arrow down into the slate under
        // it and an arrow up off the cloth over it, each as long as its speed.
        if let k = s.kick(focus) {
            ctx.stroke(Path(ellipseIn: ball(at: point(SIMD2(k.along, R)))), with: .color(accent.opacity(0.55)),
                       lineWidth: 1)
            let down = length(k.down), up = length(k.up)
            if down > 0 {
                ctx.stroke(arrow(from: point(SIMD2(k.along, 0)), to: point(SIMD2(k.along, -down))),
                           with: .color(accent), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            if up > 0 {
                ctx.stroke(arrow(from: point(SIMD2(k.along, 2 * R)), to: point(SIMD2(k.along, 2 * R + up))),
                           with: .color(accent), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }

        // The cue, when a raised strike made the jump: bright while the strike is the caption, faint after. It runs
        // from its tip at the ball back up its own line and out of the panel.
        if let c = cueLine {
            let strength = focus == .strike ? 1.0 : focus == .takeOff(0) ? 0.45 : 0.25
            let width = max(2.5, r * 0.34)
            var shaft = Path()
            shaft.move(to: point(c.tip - c.d * (0.45 * R))); shaft.addLine(to: point(c.tip - c.d * (14 * R)))
            ctx.stroke(shaft, with: .color(cueColor.opacity(strength)), style: StrokeStyle(lineWidth: width, lineCap: .round))
            var ferrule = Path()
            ferrule.move(to: point(c.tip)); ferrule.addLine(to: point(c.tip - c.d * (0.45 * R)))
            ctx.stroke(ferrule, with: .color(paper.opacity(strength)), style: StrokeStyle(lineWidth: width, lineCap: .butt))
        }

        // The flying ball where the replay is now (at the take-off while the strike or the take-off holds).
        let now = point(s.arc[flown])
        ctx.fill(Path(ellipseIn: ball(at: now)), with: .color(paper))
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
