// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 12, Ride: the coming path stays on the cloth for
//          the whole ride instead of fading in the roll's first moments. It is drawn only AHEAD of the ridden ball
//          (the stretch it has already run is gone), so from the low chase camera it reads as "this is where you are
//          going"; after the first contact the struck ball's own coming path joins it, fainter. Marks follow the
//          design language: the "you" ring and the coming path are paper (cyan means a rolling ball, and the Lens draws
//          it), the first ball's ring is the contact colour, and lines are a little heavier on the phone so they read
//          at its size. As the view switches from the overhead table to riding, and back, VoiceOver announces it
//          (RideWords.mountAnnouncement, RideWords.dismountAnnouncement), once per switch.)
// PURPOSE: The Ride hand-over's marks on the table (plans/22-Nov-2026-ride-handover-plan.md, work package 3, 0.7.6
//          stream ride; plans/26-Nov-2026-ui-rethink-plan.md package 12). During the mount: a ring pulses on the ball
//          about to be struck, its coming path is drawn dotted, and the first ball it will hit gets its own ring, so the
//          player sees where the camera is about to go before it goes there. During the roll and the held beats: a thin
//          ring stays on the ridden ball, so the eye knows which ball is "you", and the dotted path runs on ahead of it
//          (and, after the hit, ahead of the struck ball too). During the dismount everything fades with the rise.
//          Also posts the spoken announcement as the view switches between the overhead table and the ride.
//          Reads the model (rideAct, rideActProgress, ridePlan, the clock, the recording) and the 3D camera through
//          AimProjector, the projector the last-try ghost and the aim line use; draws through TablePathStroke (the
//          shared cloth-path drawing). The paths are sampled once per recording with their clock times; each frame
//          only cuts them at the clock and projects them. Where the marks are is a function of the playback clock;
//          only the pulse follows wall time. Never takes touches.
//          Mounted in the table stage beside GhostOverlay (ShowpieceView, the coordinator's line).
// SRP/DRY check: Pass - checked GhostOverlay (TablePathStroke, AimProjector.CameraBox, the Canvas-over-the-table
//          pattern, all reused here), CaptionViews' LeaderState (projects one point for the caption's ring; it keeps
//          no path and is owned by the caption card, so the ride's marks project through the same AimProjector the
//          ghost uses instead), TrickTableLayer's rings (a trick shot's balls and pockets, not the ride's) and
//          KitDeviceReader (the phone-or-big-screen answer, reused for the line weights).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

struct RideOverlay: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Environment(\.palette) private var palette
    @State private var cameraBox = AimProjector.CameraBox()
    /// The paths sampled once per recording (see Sampled).
    @State private var sampled = Sampled.empty
    private var device = KitDeviceReader()

    /// A ball's recorded run as clock times and table points, every 1/60 s of clock.
    struct Run {
        var times: [Double] = []
        var points: [Vec2] = []

        /// The part of the run still ahead at clock t: from where the ball is now to the run's end.
        func ahead(of t: Double, now: Vec2) -> [Vec2] {
            guard let i = times.firstIndex(where: { $0 > t }) else { return [] }
            return [now] + points[i...]
        }
    }

    /// The ridden ball's run for the whole ride, the first struck ball's run from the contact to its stop or pocket
    /// (empty when the ride does not follow it), and where that ball sits at the contact.
    struct Sampled {
        var version: Int
        var ridden: Run
        var struck: Run
        var target: Vec2?

        static let empty = Sampled(version: -1, ridden: Run(), struck: Run(), target: nil)
    }

    var body: some View {
        ZStack {
            // Only while a ride shows its guides: nothing is drawn, and nothing redraws per frame, at any other time.
            if model.rideShowsGuides {
                TimelineView(.animation) { context in
                    Canvas { ctx, size in draw(&ctx, size: size, now: context.date.timeIntervalSinceReferenceDate) }
                }
                .onChange(of: model.timelineVersion, initial: true) { _, version in sampled = Self.sample(model, version) }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
        // The switch between the overhead table and the ride, said out loud once each way (the title row's words say
        // it on screen). Kept on the always-present stack so it hears the change even as the guides appear.
        .onChange(of: model.rideAct) { old, new in announce(from: old, to: new) }
    }

    private func announce(from old: RideAct, to new: RideAct) {
        let words: String
        switch new {
        case .mount where old != .mount:
            words = RideWords.mountAnnouncement(ball: model.ridePlan.cueBall, table: model.solvedTable)
        case .dismount where old != .dismount:
            words = RideWords.dismountAnnouncement
        default:
            return
        }
        AccessibilityNotification.Announcement(words).post()
    }

    /// The ridden ball's run up to where it stops (or drops), and the first struck ball's run from the contact when the
    /// ride follows it, every 1/60 s of clock.
    private static func sample(_ model: ShowpieceModel, _ version: Int) -> Sampled {
        let plan = model.ridePlan, tl = model.timeline
        guard plan.rideable else { return Sampled(version: version, ridden: Run(), struck: Run(), target: nil) }
        func run(_ ball: Int, over span: ClosedRange<Double>) -> Run {
            var r = Run()
            var t = span.lowerBound
            while t < span.upperBound {
                r.times.append(t)
                r.points.append(tl.state(ball: ball, at: t).position)
                t += 1.0 / 60
            }
            r.times.append(span.upperBound)
            r.points.append(tl.state(ball: ball, at: span.upperBound).position)
            return r
        }
        let ridden = run(plan.cueBall, over: 0...plan.cueSpan.upperBound)
        let struck = plan.objectBall.map { run($0, over: plan.objectSpan) } ?? Run()
        let target = plan.firstStruck.flatMap { b in plan.contactTime.map { tl.state(ball: b, at: $0).position } }
        return Sampled(version: version, ridden: ridden, struck: struck, target: target)
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, now: TimeInterval) {
        let plan = model.ridePlan
        guard sampled.version == model.timelineVersion, plan.rideable, let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return }
        let tl = model.timeline
        let radius = tl.table.ballRadius
        let act = model.rideAct
        let clock = model.time
        // The phone never skimps on the pictures: its marks are a touch heavier so they read at its size.
        let phone = device.current == .phone
        let pathWidth: CGFloat = phone ? 3 : 2.5
        let dash: [CGFloat] = phone ? [3, 7] : [2.5, 6.5]
        // How strongly the guides show: whole through the mount, the roll and the holds, fading with the rise.
        let strength = act == .dismount ? 1 - RidePlan.smooth(model.rideActProgress) : 1
        guard strength > 0.01 else { return }
        let state = tl.state(ball: plan.cueBall, at: clock)

        // The ridden ball's coming path, ahead of it only (none once it has dropped).
        if !state.pocketed {
            let ahead = sampled.ridden.ahead(of: clock, now: state.position)
            if ahead.count > 1 {
                TablePathStroke(points: ahead, colour: palette.paper.opacity(0.85 * strength), lineWidth: pathWidth,
                                dash: dash, underlayWidth: pathWidth + 2).draw(in: &ctx, proj)
            }
        }
        // Before the hit: the first ball it will hit, ringed where it is struck, in the contact colour.
        if let target = sampled.target, let contact = plan.contactTime, clock < contact,
           let ring = TablePathStroke.ring(at: target, radius: radius * 1.5, proj) {
            ctx.stroke(ring, with: .color(palette.contact.opacity(0.9 * strength)), style: StrokeStyle(lineWidth: pathWidth))
        }
        // After the hit: the struck ball's own coming path, fainter, so the ride shows where the hit sends it.
        if let b = plan.objectBall, clock >= plan.objectSpan.lowerBound {
            let struckState = tl.state(ball: b, at: clock)
            let ahead = sampled.struck.ahead(of: clock, now: struckState.position)
            if !struckState.pocketed, ahead.count > 1 {
                TablePathStroke(points: ahead, colour: palette.paper.opacity(0.55 * strength), lineWidth: pathWidth - 0.5,
                                dash: dash, underlayWidth: pathWidth + 1.5).draw(in: &ctx, proj)
            }
        }

        // The ridden ball's ring at the clock (gone once the ball drops): paper, the "you" mark.
        guard !state.pocketed else { return }
        if act == .mount {
            // A slow pulse (about one and a half a second) so the ball about to be struck is found at a glance.
            let pulse = 0.5 + 0.5 * sin(now * 2 * .pi * 1.5)
            if let ring = TablePathStroke.ring(at: state.position, radius: radius * (1.6 + 0.35 * pulse), proj) {
                ctx.stroke(ring, with: .color(palette.paper.opacity(0.6 + 0.35 * pulse)),
                           style: StrokeStyle(lineWidth: pathWidth))
            }
        } else if let ring = TablePathStroke.ring(at: state.position, radius: radius * 1.35, proj) {
            // Thin, so it marks "you" without covering the ball (now large in the low chase view) or its trail.
            ctx.stroke(ring, with: .color(palette.paper.opacity(0.75 * strength)),
                       style: StrokeStyle(lineWidth: phone ? 1.8 : 1.5))
        }
    }
}
