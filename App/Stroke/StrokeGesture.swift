// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (merge with the lessons: a locked power control is not moved by the
//          stroke's depth).
// PURPOSE: The stroke by hand (plans/21-Nov-2026-stroke-and-power-plan.md), the touch side. Added to the aiming layer
//          (AimOverlay) as one modifier beside its own drag, and drawn from its Canvas with one call:
//          - The stroke: a touch that starts on the cue ball (the overlay's grab radius) is followed by its own id, so
//            a second finger never disturbs it. Each move is a StrokeTracker sample; the power follows the tracker's
//            powerDepth (the pull-back exactly as before, held at the backswing during a quick push); the model keeps
//            the stroke so far as its pending stroke, so whichever route then fires (Shoot, Return, a pointer's
//            release, or this stroke's own push through the ball) plays this stroke. A quick push forward through the
//            cue ball plays the shot, with a firm click.
//          - The groove: a faint band on the cloth along the cue line through where the finger first touched, as wide
//            as a steady stroke's wander (StrokeModel.steadyWander), and the finger's thin trace over it. Drawn while
//            the stroke is on. The groove follows the cue whichever hand strokes; nothing is mirrored.
//          - Feel: a faint texture while the finger is on the groove, rougher as it strays (Haptics.strokeTexture),
//            honouring the Vibration option there.
//          - The bridge hand: a second finger resting on the cloth while stroking sets the bridge length, its distance
//            to the cue ball (clamped in StrokeModel), kept for that stroke once set; a stroke with no second finger
//            uses the automatic bridge.
//          - Apple Pencil on iPad: the Pencil's angle off the glass while it strokes sets the cue's angle where a
//            raised cue is allowed (free play and matches). Its azimuth does nothing new.
//          While a stroke is on, the table's pinch and two-finger pan hold still (TableZoom.strokeHold), so a resting
//          bridge finger is not read as a zoom.
// SRP/DRY check: Pass - checked AimOverlay (its drag keeps aiming and its own pull for scripted drags; while this
//          tracks a stroke the overlay's pull defers here, so power is set in one place), PointerAim (the same
//          SpatialEventGesture pattern; its release still fires for a pointer) and CueAngleMenu (the Pencil snaps to
//          its offered angles, so the menu always reads what the Pencil set).
import BreakdownLensModel
import BreakdownPhysics
import SwiftUI

/// The stroke in progress, shared by the gesture and the overlay's drawing. A class so the gesture (a value) and the
/// Canvas see the same state; not observed, because the Canvas redraws every frame anyway.
@MainActor
final class StrokeSession {
    var tracker: StrokeTracker?
    var strokeID: SpatialEventCollection.Event.ID?
    var bridgeID: SpatialEventCollection.Event.ID?
    /// Where the finger first touched, on screen, and the groove's unit directions there: back (away from the ball)
    /// and to the shooter's right.
    var origin = CGPoint.zero
    var back = CGVector(dx: 0, dy: 1)
    var right = CGVector(dx: 1, dy: 0)
    /// Screen points the finger has passed through, for the thin live trace.
    var screenTrace: [CGPoint] = []
    /// Screen length of a full pull (ShowpieceModel.pullReach) from the touch point, for the groove's length.
    var grooveLength: CGFloat = 200
    /// The bridge finger's table spot while it rests on the cloth.
    var bridgeSpot: Vec2?
    /// Groove travel since the last texture tick, points.
    var sinceTick: CGFloat = 0
    /// True once this stroke has played the shot: the rest of the touch is ignored (by the overlay's drag too).
    var spent = false

    var isTracking: Bool { tracker != nil }
}

extension View {
    /// The measured stroke for the aiming layer (see StrokeGestures).
    func strokeGestures(model: ShowpieceModel, bridge: SceneBridge, session: StrokeSession,
                        isOpen: Binding<Bool>) -> some View {
        modifier(StrokeGestures(model: model, bridge: bridge, session: session, isOpen: isOpen))
    }
}

struct StrokeGestures: ViewModifier {
    let model: ShowpieceModel
    let bridge: SceneBridge
    let session: StrokeSession
    @Binding var isOpen: Bool
    @AppStorage("aimHintSeen") private var hintSeen = false
    @State private var cameraBox = AimProjector.CameraBox()
    @State private var size = CGSize(width: 1, height: 1)

    /// Same as AimOverlay's: how close to the cue ball (points) a touch must start to grab it, and the movement below
    /// which a touch is a tap, not a pull.
    private static let grabRadius: CGFloat = 44
    private static let pullSlop: CGFloat = 10
    /// Points of groove travel between texture ticks: about a fingertip's width, so a slow stroke ticks gently and a
    /// quick one buzzes.
    private static let tickSpacing: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .simultaneousGesture(
                SpatialEventGesture()
                    .onChanged { events in track(events, ended: false) }
                    .onEnded { events in track(events, ended: true) }
            )
    }

    private func projector() -> AimProjector? {
        guard let root = bridge.table?.root else { return nil }
        return AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
    }

    // MARK: Events

    private func track(_ events: SpatialEventCollection, ended: Bool) {
        for event in events {
            let active = event.phase == .active && !ended
            if session.strokeID == nil {
                if active, !session.spent { begin(event) }
            } else if event.id == session.strokeID {
                if active { move(event) } else { finish(cancelled: event.phase == .cancelled) }
            } else if active, isFinger(event) {
                // Any other finger on the cloth while stroking is the bridge hand.
                session.bridgeID = event.id
                session.bridgeSpot = projector()?.table(at: event.location)
                noteBridge()
            } else if event.id == session.bridgeID, !active {
                // Lifted: the stroke keeps the bridge it was set on (its spot stays until the next stroke begins).
                session.bridgeID = nil
            }
        }
        // Every touch lifted: ready for the next stroke.
        if ended || events.allSatisfy({ $0.phase != .active }) {
            if session.isTracking { finish(cancelled: false) }
            session.spent = false
            session.bridgeID = nil
            session.bridgeSpot = nil
        }
    }

    private func isFinger(_ event: SpatialEventCollection.Event) -> Bool {
        #if os(iOS)
        return event.kind == .touch
        #else
        return false
        #endif
    }

    /// A touch on the cue ball, with the balls at rest and nothing lifted, starts a stroke.
    private func begin(_ event: SpatialEventCollection.Event) {
        guard model.aimReady, !model.placingCueBall, model.layout.count == 16, bridge.table?.zoom.isGesturing != true,
              let proj = projector(), let ball = proj.screen(model.aimOrigin),
              hypot(ball.x - event.location.x, ball.y - event.location.y) <= Self.grabRadius else { return }
        // The groove's directions on screen: back along the cue (away from the ball) and the shooter's right.
        let dir = model.aimDirection
        guard let behind = proj.screen(model.aimOrigin - dir * 0.3),
              let rightward = proj.screen(model.aimOrigin + Vec2(dir.y, -dir.x) * 0.3) else { return }
        let b = CGVector(dx: behind.x - ball.x, dy: behind.y - ball.y)
        let bl = hypot(b.dx, b.dy)
        guard bl > 1 else { return }
        let back = CGVector(dx: b.dx / bl, dy: b.dy / bl)
        // Right, made square to the groove on screen (the camera's perspective can skew the table's own right angle).
        var r = CGVector(dx: rightward.x - ball.x, dy: rightward.y - ball.y)
        let along = r.dx * back.dx + r.dy * back.dy
        r = CGVector(dx: r.dx - along * back.dx, dy: r.dy - along * back.dy)
        let rl = hypot(r.dx, r.dy)
        guard rl > 1e-3 else { return }
        session.strokeID = event.id
        session.tracker = StrokeTracker()
        // A new stroke starts on the automatic bridge until a second finger rests on the cloth.
        session.bridgeID = nil
        session.bridgeSpot = nil
        model.strokeBridge = nil
        session.origin = event.location
        session.back = back
        session.right = CGVector(dx: r.dx / rl, dy: r.dy / rl)
        session.screenTrace = [event.location]
        session.grooveLength = bl / 0.3 * CGFloat(ShowpieceModel.pullReach)
        session.sinceTick = 0
        bridge.table?.zoom.strokeHold = true
        move(event)
    }

    private func move(_ event: SpatialEventCollection.Event) {
        guard var tracker = session.tracker, let proj = projector() else { return }
        let p = event.location
        let dx = p.x - session.origin.x, dy = p.y - session.origin.y
        let along = Double(dx * session.back.dx + dy * session.back.dy)
        let across = Double(dx * session.right.dx + dy * session.right.dy)
        let spot = proj.table(at: p)
        // How far behind the cue ball the finger is, along the aim line, on the table: the pull-back's own measure.
        let depth = spot.map { (model.aimOrigin - $0).dot(model.aimDirection) } ?? (tracker.samples.last?.depth ?? 0)
        let before = tracker.samples.last
        tracker.add(.init(time: event.timestamp, depth: depth, along: along, across: across, spot: spot))
        session.tracker = tracker
        session.screenTrace.append(p)
        pencil(event)
        // Below the slop it is a tap on the ball and leaves the power as it was, as the overlay's pull always has.
        guard hypot(dx, dy) > Self.pullSlop else { return }
        // A lesson step with the power locked keeps its set power: the stroke is still measured (for its drift), but
        // the depth does not move the bar.
        if model.openControls.contains(.power) { model.powerFraction = tracker.powerDepth / ShowpieceModel.pullReach }
        model.pendingStroke = tracker.record(power: model.activePower, bridge: bridgeLength())
        feel(previous: before, tracker: tracker)
        if tracker.delivered { deliver() }
    }

    /// The stroke has gone through the cue ball: play it.
    private func deliver() {
        session.spent = true
        Haptics.shared.strokeContact()
        hintSeen = true
        let wasBreak = model.fire()
        endStroke()
        if wasBreak { isOpen = false }
    }

    /// The finger lifted (or the system took the touch): the stroke so far stays the pending one, power kept.
    private func finish(cancelled: Bool) {
        if cancelled { model.pendingStroke = nil }
        endStroke()
    }

    private func endStroke() {
        session.tracker = nil
        session.strokeID = nil
        session.screenTrace = []
        bridge.table?.zoom.strokeHold = false
    }

    // MARK: Bridge hand

    /// The bridge finger's distance to the cue ball, metres, clamped; nil with no second finger.
    private func bridgeLength() -> Double? {
        guard let spot = session.bridgeSpot else { return nil }
        return StrokeModel.bridgeLength(finger: (spot - model.aimOrigin).length, mechanical: false)
    }

    /// Tell the model the bridge now, so the power bar's calm zone moves while the finger rests.
    private func noteBridge() {
        model.strokeBridge = bridgeLength()
        if let tracker = session.tracker {
            model.pendingStroke = tracker.record(power: model.activePower, bridge: bridgeLength())
        }
    }

    // MARK: Feel

    /// A faint tick each fingertip's width of travel along the groove: soft and dull on the groove, crisper and
    /// stronger as the finger strays off it (roughness 1 at three groove half-widths off).
    private func feel(previous: StrokeTracker.Sample?, tracker: StrokeTracker) {
        guard let last = tracker.samples.last, let prev = previous else { return }
        session.sinceTick += CGFloat(abs(last.along - prev.along))
        guard session.sinceTick >= Self.tickSpacing else { return }
        session.sinceTick = 0
        let halfWidth = max(3, StrokeModel.steadyWander * max(tracker.strokeLength, StrokeTracker.shortestStroke))
        let roughness = min(1, max(0, (abs(last.across) - halfWidth) / (2 * halfWidth)))
        Haptics.shared.strokeTexture(roughness: roughness)
    }

    // MARK: Pencil

    /// The Pencil's altitude while stroking sets the cue's angle where the mode allows a raised cue. A writing grip
    /// holds the Pencil about 50 degrees off the glass; there or flatter the cue stays level, and standing it upright
    /// raises the cue to the steepest angle the cue-angle control offers (80 degrees): two degrees of cue per degree
    /// of Pencil past the grip. Snapped to the control's angles so its menu reads what the Pencil set.
    private func pencil(_ event: SpatialEventCollection.Event) {
        #if os(iOS)
        guard event.kind == .pencil, let pose = event.inputDevicePose, raisedCueOpen else { return }
        let raise = min(80, max(0, (pose.altitude.degrees - 50) * 2))
        let snapped = CueAngleMenu.angles.min { abs(Double($0) - raise) < abs(Double($1) - raise) } ?? 0
        let sine = CueAngleMenu.sine(forAngle: snapped)
        if model.shotElevation != sine { model.shotElevation = sine }
        #endif
    }

    /// Free play and matches: the shot (not the break) may take a raised cue; trick shots and situations set their
    /// own cue angle.
    private var raisedCueOpen: Bool {
        model.elevationAllowed && !model.racked && !model.trickMode.isActive && !model.eightBallMode.isActive
    }
}

// MARK: Drawing

@MainActor
enum StrokeDrawing {
    /// The groove and the finger's trace, while a stroke is on. Called from the aiming layer's Canvas.
    static func draw(_ ctx: inout GraphicsContext, session: StrokeSession, paper: Color, accent: Color) {
        guard let tracker = session.tracker else { return }
        let o = session.origin, b = session.back, r = session.right
        // From a little ahead of the touch (toward the ball, the forward stroke's path) to a full pull behind it.
        let ahead: CGFloat = 40
        let length = session.grooveLength
        let half = max(3, CGFloat(StrokeModel.steadyWander * max(tracker.strokeLength, StrokeTracker.shortestStroke)))
        func at(_ s: CGFloat, _ t: CGFloat) -> CGPoint {
            CGPoint(x: o.x + b.dx * s + r.dx * t, y: o.y + b.dy * s + r.dy * t)
        }
        var band = Path()
        band.move(to: at(-ahead, -half))
        band.addLine(to: at(length, -half))
        band.addLine(to: at(length, half))
        band.addLine(to: at(-ahead, half))
        band.closeSubpath()
        ctx.fill(band, with: .color(paper.opacity(0.10)))
        var centre = Path()
        centre.move(to: at(-ahead, 0)); centre.addLine(to: at(length, 0))
        ctx.stroke(centre, with: .color(paper.opacity(0.22)), style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
        guard session.screenTrace.count > 1 else { return }
        var trace = Path()
        trace.addLines(session.screenTrace)
        ctx.stroke(trace, with: .color(accent.opacity(0.7)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
    }
}
