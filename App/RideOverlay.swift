// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: The Ride hand-over's marks on the table (plans/22-Nov-2026-ride-handover-plan.md, work package 3, 0.7.6
//          stream ride). During the mount: a ring pulses on the ball about to be struck, its coming path is drawn
//          dotted up to the first ball it will hit, and that ball gets its own ring, so the player sees where the
//          camera is about to go before it goes there. During the roll and the held beats: a thin ring stays on the
//          ridden ball, so the eye knows which ball is "you". During the dismount the ring fades with the rise. The
//          dotted path fades over the roll's first moments.
//          Reads the model (rideAct, rideActProgress, ridePlan, the clock, the recording) and the 3D camera through
//          AimProjector, the projector the last-try ghost and the aim line use; draws through TablePathStroke (the
//          shared cloth-path drawing). The path is sampled once per recording; each frame only projects it. Where the
//          marks are is a function of the playback clock (the ridden ball's ring follows the recording at the clock);
//          only the pulse follows wall time. Never takes touches.
//          Mounted in the table stage beside GhostOverlay (ShowpieceView, the coordinator's line).
// SRP/DRY check: Pass - checked GhostOverlay (TablePathStroke, AimProjector.CameraBox, the Canvas-over-the-table
//          pattern, all reused here), CaptionViews' LeaderState (projects one point for the caption's ring; it keeps
//          no path and is owned by the caption card, so the ride's marks project through the same AimProjector the
//          ghost uses instead) and TrickTableLayer's rings (a trick shot's balls and pockets, not the ride's).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

struct RideOverlay: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Environment(\.palette) private var palette
    @State private var cameraBox = AimProjector.CameraBox()
    /// The struck ball's path from the strike to the first contact (or to where it stops when it hits nothing), and
    /// where the first ball it hits sits at that moment; sampled once per recording.
    @State private var sampled: (version: Int, path: [Vec2], target: Vec2?) = (-1, [], nil)

    var body: some View {
        // Only while a ride shows its guides: nothing is drawn, and nothing redraws per frame, at any other time.
        if model.rideShowsGuides {
            TimelineView(.animation) { context in
                Canvas { ctx, size in draw(&ctx, size: size, now: context.date.timeIntervalSinceReferenceDate) }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .accessibilityHidden(true)
            .onChange(of: model.timelineVersion, initial: true) { _, version in sampled = Self.sample(model, version) }
        }
    }

    /// The path to the first contact, every 1/60 s of clock, and the first struck ball's place at the contact.
    private static func sample(_ model: ShowpieceModel, _ version: Int) -> (version: Int, path: [Vec2], target: Vec2?) {
        let plan = model.ridePlan, tl = model.timeline
        guard plan.rideable else { return (version, [], nil) }
        let end = plan.contactTime ?? plan.cueSpan.upperBound
        var points: [Vec2] = []
        var t = 0.0
        while t < end {
            points.append(tl.state(ball: plan.cueBall, at: t).position)
            t += 1.0 / 60
        }
        points.append(tl.state(ball: plan.cueBall, at: end).position)
        let target = plan.firstStruck.flatMap { b in plan.contactTime.map { tl.state(ball: b, at: $0).position } }
        return (version, points, target)
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, now: TimeInterval) {
        let plan = model.ridePlan
        guard sampled.version == model.timelineVersion, plan.rideable, let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return }
        let radius = model.timeline.table.ballRadius
        let act = model.rideAct
        let clock = model.time
        // How strongly the guides show: whole through the mount, the roll and the holds, fading with the rise.
        let strength = act == .dismount ? 1 - RidePlan.smooth(model.rideActProgress) : 1
        // The dotted path and the target ring: whole during the mount, fading over the roll's first 0.4 s of clock
        // (a function of the clock, so a scrub shows the same).
        let pathStrength = act == .mount ? 1 : (1 - RidePlan.smooth(clock / 0.4)) * strength
        if pathStrength > 0.01 {
            TablePathStroke(points: sampled.path, colour: palette.paper.opacity(0.85 * pathStrength), lineWidth: 2,
                            dash: [2, 6], underlayWidth: 4).draw(in: &ctx, proj)
            if let target = sampled.target,
               let ring = TablePathStroke.ring(at: target, radius: radius * 1.5, proj) {
                ctx.stroke(ring, with: .color(palette.impact.opacity(0.9 * pathStrength)),
                           style: StrokeStyle(lineWidth: 2))
            }
        }
        // The ridden ball's ring at the clock (gone once the ball drops).
        let state = model.timeline.state(ball: plan.cueBall, at: clock)
        guard !state.pocketed, strength > 0.01 else { return }
        if act == .mount {
            // A slow pulse (about one and a half a second) so the ball about to be struck is found at a glance.
            let pulse = 0.5 + 0.5 * sin(now * 2 * .pi * 1.5)
            if let ring = TablePathStroke.ring(at: state.position, radius: radius * (1.6 + 0.35 * pulse), proj) {
                ctx.stroke(ring, with: .color(palette.accent.opacity(0.6 + 0.35 * pulse)), style: StrokeStyle(lineWidth: 2.5))
            }
        } else if let ring = TablePathStroke.ring(at: state.position, radius: radius * 1.35, proj) {
            // Thin, so it marks "you" without covering the ball or its trail.
            ctx.stroke(ring, with: .color(palette.accent.opacity(0.75 * strength)), style: StrokeStyle(lineWidth: 1.3))
        }
    }
}
