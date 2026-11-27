// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, Part 4 step 5: on the upright phone this layer also
//          hosts PhonePlayFeedback (FreePlayPhoneBlurbs.swift), the always-present observer that announces each match
//          phase and plays the clock's and the cleared rack's haptics there, because the phone's blurbs come and go
//          and MatchCard and TableClearedCard, which do it on the other layouts, are not on screen.)
// PURPOSE: Marks on the table for free play and matches, laid over the 3D table beside the trick-shot and 8-ball layers
//          and never taking touches:
//            - the lifted cue ball (ball in hand, Move cue ball): a disc where it would be put down, outlined in the
//              accent colour on a free spot and filled with a red tint on an illegal one (rules plan, package 2), and
//              the head line drawn dashed across the table while the ball must stay behind it;
//            - nine-ball: a double ring on the lowest ball, the one that must be hit first (rules plan, package 4),
//              turning red while the aim line meets a different ball first.
//          It also opens the shot panel when the ball is picked up, because the drag that moves it is part of the
//          aiming layer (AimOverlay), which is only on screen while the panel is open.
//          Projection is AimProjector, exactly as AimOverlay, GhostOverlay and the trick-shot layer use it.
//          Legality comes from CueBallPlacement (FreePlayViews.swift), which asks the package.
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 3's leftover lint note: an illegal cue-ball spot and an aim that meets another ball
//          first are drawn in Palette.warning, the one colour for a foul or a miss, instead of the system red.)
// SRP/DRY check: Pass - checked TrickTableLayer and EightBallTableLayer (same ring and projector pattern for their own
//          marks) and AimOverlay (draws the live aim; this layer adds only placement and the hit-first mark).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import SwiftUI

struct PlayTableLayer: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Binding var shotPanelOpen: Bool
    @Environment(\.palette) private var palette
    /// The phone held upright (ShowpieceView sets it on the stage): the match and free-play feedback lives here then.
    @Environment(\.phoneUpright) private var phoneUpright
    @State private var cameraBox = AimProjector.CameraBox()

    /// True when there is anything to draw, so the layer costs nothing in a trick shot or a puzzle.
    private var active: Bool { model.placingCueBall || hitFirstBall != nil }

    /// Nine-ball while the shooter is lining up: the lowest ball on the table.
    private var hitFirstBall: Int? {
        guard let match = model.match, match.state.kind == .nineBall, match.phase == .aiming else { return nil }
        return match.state.ballsLeft.min()
    }

    var body: some View {
        ZStack {
            if active {
                TimelineView(.animation) { _ in
                    Canvas { ctx, size in draw(&ctx, size: size) }
                }
            }
        }
        // Only on the upright phone: elsewhere MatchCard and TableClearedCard are on screen and do this themselves,
        // so hosting it there too would say every ruling twice.
        .background { if phoneUpright { PhonePlayFeedback(model: model) } }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)   // the ball-in-hand card and the turn banner say all of this in words
        .onChange(of: model.placingCueBall) { _, placing in if placing { shotPanelOpen = true } }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        guard model.layout.count == 16, let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return }
        let table = model.timeline.table
        func ring(_ centre: Vec2, _ radius: Double) -> Path? {
            var path = Path()
            for i in 0..<40 {
                let a = Double(i) / 40 * 2 * Double.pi
                guard let s = proj.screen(centre + Vec2(cos(a), sin(a)) * radius, height: 0.001) else { return nil }
                if i == 0 { path.move(to: s) } else { path.addLine(to: s) }
            }
            path.closeSubpath()
            return path
        }

        if model.placingCueBall {
            // The head line, a quarter of the length from the head cushion, while the ball must stay behind it.
            if model.ballInHand == .behindHeadLine,
               let a = proj.screen(Vec2(table.length * 0.25, 0), height: 0.001),
               let b = proj.screen(Vec2(table.length * 0.25, table.width), height: 0.001) {
                var line = Path(); line.move(to: a); line.addLine(to: b)
                ctx.stroke(line, with: .color(palette.paper.opacity(0.7)), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            }
            let spot = CueBallPlacement.spot(model)
            let legal = CueBallPlacement.problem(CueBallPlacement.legality(of: spot, model)) == nil
            if let disc = ring(spot, table.ballRadius) {
                if legal {
                    ctx.stroke(disc, with: .color(palette.accent), style: StrokeStyle(lineWidth: 2.5))
                } else {
                    // Red tint over the ball plus a dashed outline, so the shape also changes, not only the colour.
                    ctx.fill(disc, with: .color(palette.warning.opacity(0.45)))
                    ctx.stroke(disc, with: .color(palette.warning), style: StrokeStyle(lineWidth: 2.5, dash: [4, 3]))
                }
            }
        }

        if let low = hitFirstBall, model.aimReady, !model.placingCueBall, NextShot.isOnTable(model.layout[low]) {
            // Red while the aim line meets another ball first: the guide's own ray cast says which ball that is.
            let first = AimGeometry.firstContact(layout: model.layout, from: model.aimOrigin,
                                                 direction: model.aimDirection, radius: table.ballRadius)?.ball
            let colour = first == nil || first == low ? palette.accent : palette.warning
            for (scale, width) in [(1.45, 2.0), (1.75, 1.2)] {
                if let p = ring(model.layout[low], table.ballRadius * scale) {
                    ctx.stroke(p, with: .color(colour), style: StrokeStyle(lineWidth: width))
                }
            }
        }
    }
}
