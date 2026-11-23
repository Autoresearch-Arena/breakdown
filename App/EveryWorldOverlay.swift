// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Draws "Same shot, every surface" over the table (0.7.7, plans/23-Nov-2026-every-world-plan.md Build step 6,
//          "What is drawn"). With nothing picked (the fan): for each other surface, the struck ball's whole path in that
//          surface's colour, dotted over a dark underlay so it reads on any cloth, ending in a small round tag (a dark
//          disc with the surface's SF Symbol in its colour); the surface the sentence is about at full strength, the
//          others at 55 per cent; a hollow ghost ball per surface rolling on the clock. With a surface picked: its
//          paths at full strength for up to three balls (EveryWorldFan.ballsToDraw), their hollow ghosts and dashed
//          rings where they stop, every other surface's struck-ball path at 15 per cent. The home path is never drawn
//          again: the real balls are on the table. Ghosts follow the replay clock; before it moves they sit where they
//          stopped; past the real end the fan's tail clock carries them on to each surface's own end (WhatIfOverlay's
//          ghostTime rule). One small name pill at the end of the shown surface's path, only where no blurb is
//          anchored there (never in the notebook, never on the upright phone) and never during a ride. While a ride is
//          under way the camera is at ball height, where nine lines and tags would only blur the view, so only the
//          ghosts (and a picked surface's rest rings) are drawn. With Differentiate Without Colour the faint paths are
//          dashed long and the strong one solid; Increase Contrast brightens every colour. Paths are sampled once per
//          landing or pick; each frame only projects stored points through the live camera (AimProjector), so the
//          drawing follows the camera into the Lens and the Ride. Never takes touches, hidden from VoiceOver (the panel
//          or card is the feature in words), and silent: it calls no sound and no haptic. ShowpieceView mounts it only
//          while model.everyWorld.isShowing. It also tells the fan when the clock moves (the tail clock).
// SRP/DRY check: Pass - WhatIfOverlay's pattern (TimelineView, Canvas, AimProjector.CameraBox, TablePathStroke for the
//          lines, rings and pill, the ghost clock); paths come from EveryWorldFan (thinned once) and ShotAttempt.path(of:);
//          no second path, ring or label drawing.
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

/// The other surfaces' paths, symbol tags and ghost balls over the table.
struct EveryWorldOverlay: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Environment(\.inlinePages) private var inlinePages
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate
    @Environment(\.colorSchemeContrast) private var contrast
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    @State private var cameraBox = AimProjector.CameraBox()
    /// A picked surface's drawn balls and their paths, sampled once per landing or pick.
    @State private var sampled = Sampled()

    /// What the samples were taken for: the fan's landings counter and the picked surface.
    struct SampleKey: Equatable {
        var landings: Int
        var picked: PlaySurface?
    }

    struct Sampled {
        var key = SampleKey(landings: -1, picked: nil)
        var balls: [Int] = []
        var paths: [Int: [Vec2]] = [:]
    }

    /// Marks on the cloth sit just above it, as the what-if's do.
    private static let onCloth: Float = 0.001
    /// The symbol tag's radius on screen, points.
    private static let tagRadius: CGFloat = 9

    private var fan: EveryWorldFan { model.everyWorld }

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in draw(&ctx, size: size, now: context.date) }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onChange(of: SampleKey(landings: fan.landings, picked: fan.picked), initial: true) { _, key in sample(key) }
        .onChange(of: model.time) { old, new in fan.clockMoved(from: old, to: new) }
    }

    /// The picked surface's balls and their whole paths (thinned as the fan's own paths are).
    private func sample(_ key: SampleKey) {
        guard let p = key.picked, let w = fan.world(p) else {
            sampled = Sampled(key: key)
            return
        }
        let balls = fan.ballsToDraw(w)
        var paths: [Int: [Vec2]] = [:]
        for b in balls { paths[b] = b == w.attempt.cueBall ? w.cuePath : EveryWorldFan.thin(w.attempt.path(of: b)) }
        sampled = Sampled(key: key, balls: balls, paths: paths)
    }

    /// The upright phone anchors the fan's blurb at the shown path's end, so the pill would say the same thing twice
    /// there (WhatIfCard's test for that layout: narrow and tall size classes, outside the notebook).
    private var blurbAnchored: Bool {
        if inlinePages { return true }
        #if os(iOS)
        return horizontalSizeClass == .compact && verticalSizeClass == .regular
        #else
        return false
        #endif
    }

    /// The clock a surface's ghosts follow, capped at that surface's own end: the real clock, or past the real end the
    /// tail clock (wall time since the real recording ended, at the chosen speed). Before the clock has moved at all
    /// (the fan just opened on a finished shot) every ghost is shown where its ball stopped.
    private func ghostTime(end: Double, now: Date) -> Double {
        if let start = fan.tailStart {
            let rate = model.chosenRate ?? 1
            return min(model.duration + now.timeIntervalSince(start) * rate, end)
        }
        if !fan.clockHasMoved && model.time >= model.duration - 1e-6 { return end }
        return min(model.time, end)
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, now: Date) {
        guard fan.isShowing, fan.real != nil, let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return }
        // A ride under way: ghosts (and a picked surface's rest rings) only.
        let riding = model.rideStatus != nil
        let picked = fan.picked
        let strong = fan.shownSurface

        // Every other surface's struck-ball path and tag: the fan, or faint behind a picked surface.
        for s in fan.others {
            guard let w = fan.world(s) else { continue }
            let colour = s.fanColour(contrast)
            let isStrong = s == strong
            let strength: Double = picked == nil ? (isStrong ? 1 : 0.55) : (s == picked ? 1 : 0.15)
            // The picked surface's own paths are drawn below with its other balls.
            if !riding && s != picked {
                TablePathStroke(points: w.cuePath, colour: colour.opacity(0.9 * strength), lineWidth: 2,
                                dash: dash(strong: isStrong), underlayWidth: 4).draw(in: &ctx, proj)
            }
            if !riding, let end = w.cuePath.last {
                // Tags stay readable behind a picked surface (a little stronger than its faint path), so identity
                // never rests on colour.
                drawTag(s, at: end, colour: colour, strength: max(strength, picked == nil ? 0 : 0.4), in: &ctx, proj)
            }
            // With nothing picked, every surface's struck-ball ghost rolls.
            if picked == nil {
                drawGhost(w, ball: w.attempt.cueBall, colour: colour, strength: max(strength, 0.7), now: now,
                          in: &ctx, proj)
            }
        }

        // The picked surface: up to three balls at full strength, their ghosts and their rest rings.
        if let p = picked, let w = fan.world(p), sampled.key.picked == p {
            let colour = p.fanColour(contrast)
            let radius = w.attempt.timeline.table.ballRadius
            for b in sampled.balls {
                if !riding, let path = sampled.paths[b], !path.isEmpty {
                    TablePathStroke(points: path, colour: colour.opacity(0.95), lineWidth: 2,
                                    dash: dash(strong: true), underlayWidth: 4).draw(in: &ctx, proj)
                }
                drawGhost(w, ball: b, colour: colour, strength: 1, now: now, in: &ctx, proj)
                // Where it comes to rest on that surface: a dashed ring, as the last try's.
                let tl = w.attempt.timeline
                if tl.pocketTime.indices.contains(b), tl.pocketTime[b] == nil,
                   let rest = TablePathStroke.ring(at: tl.state(ball: b, at: tl.duration).position, radius: radius,
                                                  proj) {
                    ctx.stroke(rest, with: .color(colour.opacity(0.8)), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                }
            }
            // The struck ball's own path, when its future did not change there (rare): still the surface's line.
            if !riding, !sampled.balls.contains(w.attempt.cueBall) {
                TablePathStroke(points: w.cuePath, colour: colour.opacity(0.95), lineWidth: 2, dash: dash(strong: true),
                                underlayWidth: 4).draw(in: &ctx, proj)
            }
        }

        // The one name pill, at the shown surface's path end, where no blurb is anchored and no ride is under way.
        if !riding, !blurbAnchored, let s = strong, let w = fan.world(s), let end = w.cuePath.last {
            TablePathStroke.label(Text(verbatim: s.title), at: end, colour: s.fanColour(contrast), in: &ctx, size: size,
                                  proj)
        }
    }

    /// Dotted, so a line reads without its colour; with Differentiate Without Colour the faint lines are dashed long
    /// and the strong one solid, so the strong one stands out by shape too.
    private func dash(strong: Bool) -> [CGFloat] {
        guard differentiate else { return [1.5, 4] }
        return strong ? [] : [8, 5]
    }

    /// A hollow ghost ball for `ball` of a surface's recording at that surface's ghost clock, gone from the moment a
    /// pocket takes it.
    private func drawGhost(_ w: EveryWorldFan.World, ball b: Int, colour: Color, strength: Double, now: Date,
                           in ctx: inout GraphicsContext, _ proj: AimProjector) {
        let tl = w.attempt.timeline
        guard tl.segments.indices.contains(b) else { return }
        let t = ghostTime(end: tl.duration, now: now)
        if let pocket = tl.pocketTime[b], t >= pocket { return }
        guard let ring = TablePathStroke.ring(at: tl.state(ball: b, at: t).position, radius: tl.table.ballRadius, proj)
        else { return }
        ctx.stroke(ring, with: .color(.black.opacity(0.45 * strength)), style: StrokeStyle(lineWidth: 3.5))
        ctx.stroke(ring, with: .color(colour.opacity(0.95 * strength)), style: StrokeStyle(lineWidth: 1.8))
    }

    /// The symbol tag at a path's end: a dark disc with a thin ring in the surface's colour and its SF Symbol.
    private func drawTag(_ s: PlaySurface, at point: Vec2, colour: Color, strength: Double,
                         in ctx: inout GraphicsContext, _ proj: AimProjector) {
        guard strength > 0, let c = proj.screen(point, height: Self.onCloth) else { return }
        let r = Self.tagRadius
        let disc = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
        ctx.fill(disc, with: .color(.black.opacity(0.75 * strength)))
        ctx.stroke(disc, with: .color(colour.opacity(strength)), style: StrokeStyle(lineWidth: 1))
        let symbol = ctx.resolve(Text(Image(systemName: s.symbol))
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(colour.opacity(strength)))
        ctx.draw(symbol, at: c)
    }
}
