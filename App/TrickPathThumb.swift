// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: The trick-shot gallery's small drawings (plans/22-Nov-2026-v074-glow-up-plan.md, G5): beside each row of the
//          trick-shot list, the answer's real solved path, so the massé's curve and the jump's hop are seen before
//          anything is tapped. Three parts:
//          - TrickPath, pure data: one shot's answer solved exactly as BreakProbe verify proves it (PoolSolver.simulate
//            of NextShot.shot from the authored layout with the authored stroke, seed 1, the default PoolParameters),
//            sampled into the cue ball's path cut into stretches by kind of motion (sliding, rolling, in the air) and at
//            every contact, the other balls' paths, the start positions, and the table's size and pockets. Built by
//            TrickPath.answer(of:), a pure function (BreakdownTests/TrickPathThumbTests checks it).
//          - TrickPathCache, the shared store the list reads: it solves every answer once per run, off the main actor,
//            one after another, and only when the list first appears (never at launch). A shot whose solve fails (or
//            that is not a laid-out shot) is remembered as failed and its row shows as it did before 0.7.4.
//          - TrickPathThumb, the drawing: a Canvas at the table's own aspect with the cloth's outline, six pocket marks,
//            the cue-ball path magenta while sliding, cyan while rolling and white dashed while in the air (the Lens's
//            own colours, from the palette; never orange), the other balls' paths thin white, and the start balls on
//            top. Hidden from VoiceOver: the row's spoken label already says what the shot is.
//          Read by TrickShotList (TrickShotViews.swift).
// SRP/DRY check: Pass - checked ShotAttempt.ghostPaths (samples a recording into plain points for the ghost, with no
//          motion kinds, so it cannot colour by phase), LensLayer (draws live trails in 3D from the clock) and
//          TrickSearch.simulate in BreakProbe (the same solve, in the package's dev tool, which the app cannot import).
//          This file only turns one solved answer into a small 2D drawing.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Observation
import SwiftUI

// MARK: The data

/// One trick shot's answer as the gallery draws it. Table metres on the solver's plan (x along the length, y across).
struct TrickPath: Equatable, Sendable {
    /// How a stretch of the cue ball's path was moving: the Lens's three kinds of motion.
    enum Motion: Equatable, Sendable { case sliding, rolling, airborne }

    /// One unbroken run of one kind of motion between two contacts. Consecutive stretches share their joining point,
    /// so the drawing has no gaps.
    struct Stretch: Equatable, Sendable {
        let motion: Motion
        let points: [Vec2]
    }

    /// A ball on the table at the start, and where.
    struct StartBall: Equatable, Sendable {
        let ball: Int
        let position: Vec2
    }

    let length: Double
    let width: Double
    let ballRadius: Double
    let pockets: [Vec2]
    let balls: [StartBall]
    /// The cue ball's path, stretch by stretch, from its start to where it stopped or dropped.
    let cue: [Stretch]
    /// Every other ball that moved, one polyline per stretch.
    let objects: [[Vec2]]

    /// Samples per second of recorded time. 120 keeps a jump's short hop and a massé's bend smooth at thumbnail size,
    /// and a whole answer stays a few thousand points.
    static let samplesPerSecond = 120.0

    /// Solves a trick shot's authored answer and samples it. Nil for a shot that is not a laid-out shot (a rack) and
    /// for a solve that moves nothing. Pure and safe off the main actor.
    nonisolated static func answer(of shot: TrickShot) -> TrickPath? {
        guard case .layout(let start) = shot.setup, start.count == 16, NextShot.isOnTable(start[0]) else { return nil }
        let s = shot.solution
        // Trig lives in the app; the solver sees a unit vector (as ShowpieceModel.shootNow and BreakProbe build it).
        let a = s.aim * Double.pi / 180
        let input = NextShot.shot(from: start, direction: Vec2(cos(a), sin(a)), speed: s.power, tipUp: s.tipUp,
                                  tipSide: s.tipSide, seed: 1, parameters: PoolParameters(),
                                  elevation: s.elevation ?? 0)
        return traced(PoolSolver.simulate(input), start: start)
    }

    /// The drawing's data for any recording from a given start. Nil when the cue ball never moved.
    nonisolated static func traced(_ tl: Timeline, start: [Vec2]) -> TrickPath? {
        let cue = stretches(of: 0, in: tl)
        guard !cue.isEmpty else { return nil }
        var objects: [[Vec2]] = []
        for b in 1..<min(start.count, tl.ballCount) where NextShot.isOnTable(start[b]) {
            objects += stretches(of: b, in: tl).map(\.points)
        }
        let balls = start.indices.filter { $0 < tl.ballCount && NextShot.isOnTable(start[$0]) }
            .map { StartBall(ball: $0, position: start[$0]) }
        return TrickPath(length: tl.table.length, width: tl.table.width, ballRadius: tl.table.ballRadius,
                         pockets: tl.table.pockets, balls: balls, cue: cue, objects: objects)
    }

    /// One ball's path as stretches of one kind of motion. Sampled on a fixed clock plus the exact time of each of its
    /// contacts (ball or cushion), and cut at every contact and every change of motion, so a stretch is one kind of
    /// motion between two hits (the massé's bend is its own stretch, ending at the first contact). Spinning in place
    /// and standing still draw nothing. Ends where the ball stopped or dropped.
    nonisolated static func stretches(of ball: Int, in tl: Timeline) -> [Stretch] {
        guard ball < tl.ballCount else { return [] }
        let end = tl.pocketTime[ball] ?? tl.duration
        guard end > 0 else { return [] }
        // This ball's contacts, as plain statements (one long filter expression is slow for the type checker).
        var hits: [Double] = []
        for e in tl.events where e.time > 0 && e.time < end {
            guard e.kind == .ballBall || e.kind == .cushion else { continue }
            if e.balls.contains(where: { $0.ball == ball }) { hits.append(e.time) }
        }
        let hitTimes = Set(hits)
        var times = Array(Swift.stride(from: 0.0, to: end, by: 1 / samplesPerSecond)) + hits
        times.append(end)
        times.sort()
        var out: [Stretch] = []
        var open: (motion: Motion, points: [Vec2])?
        var last = -1.0
        for t in times where t > last {
            last = t
            let state = tl.state(ball: ball, at: t)
            let motion = Self.motion(state.phase)
            let p = state.position
            if var run = open {
                // Same motion and no contact here: the stretch goes on.
                if motion == run.motion && !hitTimes.contains(t) {
                    run.points.append(p)
                    open = run
                    continue
                }
                // A contact or a change of motion ends the stretch at this point, where the next one starts.
                run.points.append(p)
                if run.points.count >= 2 { out.append(Stretch(motion: run.motion, points: run.points)) }
                open = motion.map { (motion: $0, points: [p]) }
            } else if let motion {
                open = (motion: motion, points: [p])
            }
        }
        if let run = open, run.points.count >= 2 { out.append(Stretch(motion: run.motion, points: run.points)) }
        // A stretch that never left its spot (a ball nudged a hair) draws nothing useful.
        return out.filter { s in
            guard let first = s.points.first else { return false }
            return s.points.contains { ($0 - first).length > 1e-3 }
        }
    }

    nonisolated private static func motion(_ phase: MotionPhase) -> Motion? {
        switch phase {
        case .sliding: return .sliding
        case .rolling: return .rolling
        case .airborne: return .airborne
        case .spinning, .stationary: return nil
        }
    }
}

// MARK: The shared store

/// Every answer's drawing, solved once per run when the trick-shot list first appears. Observable, so each row fills in
/// as its answer arrives.
@MainActor
@Observable
final class TrickPathCache {
    static let shared = TrickPathCache()

    /// The drawings by trick id.
    private(set) var paths: [String: TrickPath] = [:]
    /// The ids whose answer could not be drawn; their rows show as before.
    private(set) var failed: Set<String> = []
    @ObservationIgnored private var started = false

    /// Starts solving, the first time only. The solves run one after another on a background task (each is a pure
    /// function of the shot), so the list never waits and launch never pays for them.
    func start() {
        guard !started else { return }
        started = true
        let shots = TrickShots.all.filter { !$0.pending }
        Task { [weak self] in
            for shot in shots {
                let path = await Task.detached(priority: .utility) { TrickPath.answer(of: shot) }.value
                guard let self else { return }
                if let path { self.paths[shot.id] = path } else { self.failed.insert(shot.id) }
            }
        }
    }

    /// True when the row should keep room for a drawing still being solved.
    func isPending(_ id: String) -> Bool { started && paths[id] == nil && !failed.contains(id) }
}

// MARK: The drawing

/// The small drawing of one answer (about 96 by 48 points in a list row; full width at accessibility text sizes).
struct TrickPathThumb: View {
    let path: TrickPath
    @Environment(\.palette) private var palette

    var body: some View {
        Canvas { ctx, size in draw(&ctx, size: size) }
            .aspectRatio(path.length / path.width, contentMode: .fit)
            .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        let inset: CGFloat = 3
        let length = CGFloat(path.length), width = CGFloat(path.width)
        let scale: CGFloat = min((size.width - 2 * inset) / length, (size.height - 2 * inset) / width)
        guard scale > 0 else { return }
        // Centred, with the plan's y pointing up the screen (pocket 0 is bottom-left, as the shots' words name them).
        let ox = (size.width - length * scale) / 2
        let oy = (size.height - width * scale) / 2
        func at(_ p: Vec2) -> CGPoint { CGPoint(x: ox + CGFloat(p.x) * scale, y: oy + (width - CGFloat(p.y)) * scale) }
        func line(_ pts: [Vec2]) -> Path {
            var out = Path()
            for (i, p) in pts.enumerated() { if i == 0 { out.move(to: at(p)) } else { out.addLine(to: at(p)) } }
            return out
        }
        let cloth = CGRect(x: ox, y: oy, width: length * scale, height: width * scale)
        ctx.fill(Path(roundedRect: cloth, cornerRadius: 3), with: .color(palette.paper.opacity(0.06)))
        ctx.stroke(Path(roundedRect: cloth, cornerRadius: 3), with: .color(palette.paper.opacity(0.35)), lineWidth: 1)
        // Pocket marks: a dark dot ringed faintly, big enough to read at this size whatever the real hole's size.
        for p in path.pockets {
            let c = at(p)
            let dot = Path(ellipseIn: CGRect(x: c.x - 2.4, y: c.y - 2.4, width: 4.8, height: 4.8))
            ctx.fill(dot, with: .color(.black.opacity(0.85)))
            ctx.stroke(dot, with: .color(palette.paper.opacity(0.4)), lineWidth: 0.6)
        }
        for pts in path.objects {
            ctx.stroke(line(pts), with: .color(palette.paper.opacity(0.55)),
                       style: StrokeStyle(lineWidth: 0.8, lineCap: .round, lineJoin: .round))
        }
        for s in path.cue {
            switch s.motion {
            case .sliding:
                ctx.stroke(line(s.points), with: .color(palette.slide), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            case .rolling:
                ctx.stroke(line(s.points), with: .color(palette.accent), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            case .airborne:
                ctx.stroke(line(s.points), with: .color(palette.paper),
                           style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round, dash: [2.5, 2]))
            }
        }
        // The start balls on top: real size when that is visible, never smaller than a readable dot. The cue ball is
        // solid; the others are hollow, so the two are told apart without colour.
        let r: CGFloat = max(2.2, CGFloat(path.ballRadius) * scale)
        for b in path.balls {
            let c = at(b.position)
            let disc = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
            if b.ball == 0 {
                ctx.fill(disc, with: .color(palette.paper))
            } else {
                ctx.fill(disc, with: .color(palette.ground.opacity(0.85)))
                ctx.stroke(disc, with: .color(palette.paper.opacity(0.9)), lineWidth: 0.9)
            }
        }
    }
}
