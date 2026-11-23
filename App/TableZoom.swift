// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream camera, plans/22-Nov-2026-phone-bug-hunt.md #14 and #24:
//          the zoom scales and moves the camera about the cloth point under the middle of the free space (TableCamera
//          passes it in each frame as the pivot), keeping the look direction, and every offset is measured from that
//          point; a double-tapped ball now lands in the middle of the free space instead of high under the title row,
//          a pinch stays under the fingers, and the clamp keeps the real look point on the table. Pinch, pan, double
//          tap and the menu zoom do nothing while the Ride camera flies (rideHold). And a gesture made while the moment
//          framing (MomentFrame) is in takes over its view exactly where it is (momentLook), so nothing jumps.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 lens-drawing, plans/22-Nov-2026-v074-glow-up-plan.md feature
//          G2: closeUp(on:scale:) brings the view in on a point with the same clamping and spring as a double tap, for
//          the gentle close-up on a held signature beat (SignatureCloseUp), and atFittedView says whether the hand's goal
//          is still the fitted view, so that close-up never overrides a zoom the player chose.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream hook: strokeHold, set while a stroke is drawn on the cue
//          ball (StrokeGesture), keeps pinch and two-finger pan still, so a bridge finger resting on the cloth beside a
//          moving stroke finger is not read as a zoom or a pan.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 touch stream, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items
//          7 and 32: zoom from the keyboard and the menus. zoomStep(_:) zooms in or out a step about the middle of the
//          view (View menu Zoom In and Zoom Out), actualSize() returns to the fitted view (Actual Size), and
//          panStep(_:) moves the zoomed view the way an arrow key points on screen, a tenth of the camera's distance
//          to the cloth per press, using the camera's own screen directions recorded each frame. The double tap now
//          tells the aiming layer's touch arbiter it was recognised (onDoubleTap), so the aim from before its first tap
//          is put back and that tap does not aim. The menus and key bindings themselves are the menu stream's.)
// PURPOSE: Zooming into the table by hand (look plan package 3: on a phone held upright the camera fits the whole
//          table, so the balls are a few millimetres across). Two parts:
//          (1) TableZoom, the state: one more distance multiplier and a sideways offset of the camera's look point,
//              on top of the fitted framing (TableCamera applies it after CameraFraming, so it can never fight the
//              fit). The goal follows the fingers exactly while a gesture is on; otherwise the camera eases to the goal
//              with a short critically damped spring, and it springs back to the fitted view whenever a new shot is
//              loaded (TableScene.load calls springBack), so every shot is watched from the normal view. Clamped: the
//              view can come in to `closest` of the fitted distance (about three times larger) and never further out
//              than the fit, and the look point never leaves the playing surface, so the table can never leave the
//              screen. With Reduce Motion on the camera jumps to the goal instead of easing.
//          (2) TableZoomGestures, the hands: pinch to zoom about the point under the fingers, a two-finger drag to pan
//              (iPhone and iPad; on a Mac the pinch's anchor does the moving), and a double tap (double click) on a
//              ball to centre and zoom on it, again to come back. Screen points become table points through
//              AimProjector, the same camera maths the aiming layer uses. Applied to the 3D view (TableStage) and to
//              the aiming layer that covers it while "Your shot" is open (AimOverlay), each with one line.
//          Coordinates: world metres in plan (x along the table, z across), the same plane TableFrame maps to.
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 clips, plans/23-Nov-2026-clips-plan.md: the zoom's ease reads SceneClock.now (the double tap's real-gesture timing is left on the device clock), so the clip's offscreen table eases on the clip's own clock; the live game is unchanged.)
// SRP/DRY check: Pass - checked TableCamera (fitted framing, push-in and Ride stay there; this only adds the hand
//          zoom), AimGeometry (AimProjector is reused, not copied) and AimOverlay (its one-finger drag aims; this
//          file only takes pinches, two-finger drags and double taps).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import RealityKit
import SwiftUI
import simd
#if os(iOS)
import UIKit
#endif

// MARK: The state

@MainActor
final class TableZoom {
    /// The nearest the hand zoom comes, as a fraction of the fitted camera distance. At 0.3 a ball on an upright
    /// phone is a little over three times its fitted size, about the size of a fingertip: near enough to read every
    /// number, far enough that the cluster around it stays in view.
    static let closest: Float = 0.3
    /// Where a double tap on a ball zooms to (a little short of the closest, so the neighbours show).
    static let focusScale: Float = 0.4
    /// Time constant of the ease toward the goal, seconds: quick enough to feel attached, slow enough to read as a
    /// spring rather than a cut.
    static let easeTime: Double = 0.16

    /// Where the hand wants the camera: distance multiplier (1 is the fitted view) and look-point offset (metres).
    /// The offset is measured from `fitPivot`, the cloth point under the middle of the free space in the fitted view
    /// (0.7.6 #14): the look point the zoomed view puts at the middle of the free space is fitPivot + offset. Before,
    /// producers treated the offset as an absolute table point while apply() added it to the point under the screen's
    /// centre, so a double-tapped ball landed well above the free space's middle.
    private(set) var goalScale: Float = 1
    private(set) var goalOffset = SIMD2<Float>.zero
    /// Where the camera is now, eased toward the goal.
    private var scale: Float = 1
    private var offset = SIMD2<Float>.zero
    private var lastTick: TimeInterval?
    /// Half the playing surface (set by TableCamera each frame from the table), the bound for the look point.
    private var bound = SIMD2<Float>(1.27, 0.635)
    /// The cloth point (world plan x, z) under the middle of the free space in the fitted view, from the last frame
    /// (TableCamera, through apply). Offsets are measured from it. About the table's middle; zero until the first frame.
    private(set) var fitPivot = SIMD2<Float>.zero
    /// True while the Ride camera flies (TableScene sets it every frame): pinch, pan, double tap and the menu zoom do
    /// nothing then (0.7.6 #24), since the ride ignores the hand zoom and the view would land zoomed after it.
    var rideHold = false
    /// The moment framing's contribution this frame, in the zoom's own terms (TableCamera sets it every frame; nil
    /// while it is out). The first gesture made while it is in adopts it as the hand's own zoom, so the view stays
    /// exactly where it is and the player carries on from there; MomentFrame then steps out at once because the hand
    /// is no longer at the fitted view.
    var momentLook: (scale: Float, offset: SIMD2<Float>)?
    /// The ball a double tap last zoomed onto, so a second double tap on it comes back out.
    private(set) var focusedBall: Int?
    /// True while fingers are on a pinch or a two-finger drag: the aiming layer ignores its own drag meanwhile.
    var isGesturing = false
    /// True while the player strokes the cue ball (StrokeGesture): a second finger then is the bridge hand, so pinches
    /// and two-finger drags are ignored until the stroke ends.
    var strokeHold = false
    /// Called when a double tap is recognised, before it zooms: the aiming layer's touch arbiter (StrokeGestures) puts
    /// back the aim from before the double tap's first tap and drops that tap. Nil while the aiming layer is closed.
    var onDoubleTap: (@MainActor () -> Void)?

    /// One View-menu zoom step: the view comes a quarter closer (or goes a quarter further out), so five steps run
    /// from the fitted view to the closest one, few enough to reach quickly, fine enough to stop on any ball.
    static let keyZoomFactor: Float = 1.25
    /// One arrow-key pan, as a share of the camera's distance to the point it looks at on the cloth. At the usual
    /// lens (about 45 degrees) the view shows about four fifths of that distance top to bottom, so a press moves the
    /// table about an eighth of the screen: clearly a step, never a jump past what was in view.
    static let panStepShare: Float = 0.1
    /// The camera's screen-right and screen-up directions laid flat on the cloth (world plan x, z) and its distance to
    /// the cloth along its line of sight, from the last frame (apply). The camera looks with world up as its up
    /// vector (TableCamera), so screen up is the way its line of sight runs across the cloth.
    private var planRight = SIMD2<Float>(1, 0)
    private var planUp = SIMD2<Float>(0, -1)
    private var viewDistance: Float = 2

    /// True when the hand has zoomed or moved the view away from the fitted one.
    var isZoomed: Bool { goalScale < 0.999 || simd_length(goalOffset) > 0.002 }

    // Gesture starting points.
    private var pinchStart: (scale: Float, offset: SIMD2<Float>)?
    private var panStart: SIMD2<Float>?

    private func setGoal(scale s: Float, offset o: SIMD2<Float>) {
        goalScale = min(1, max(Self.closest, s))
        goalOffset = clampOffset(o)
    }

    /// Keeps the real look point (fitPivot + offset) on the playing surface, so the table can never leave the screen.
    /// Written with min and max rather than simd_clamp, so a pivot that strays past the bound can never hand it an
    /// inside-out range.
    private func clampOffset(_ o: SIMD2<Float>) -> SIMD2<Float> {
        simd_min(simd_max(o, -bound - fitPivot), bound - fitPivot)
    }

    /// Before any hand gesture: if the moment framing has the view in on a moment and the hand is still at the fitted
    /// view, take that view over as the hand's own (the camera's current place and the goal alike, so nothing jumps;
    /// a moment nearer than `closest` eases out to it).
    private func adoptMoment() {
        guard let look = momentLook, atFittedView, !isGesturing else { return }
        momentLook = nil
        scale = look.scale; offset = look.offset
        setGoal(scale: look.scale, offset: look.offset)
    }

    /// A pinch moved: `magnification` is relative to its start (above 1 spreads the fingers, zooming in). `anchor`, the
    /// table point under the fingers when the pinch began (world plan), stays under them as the view scales about it.
    func pinchChanged(magnification: CGFloat, anchor: SIMD2<Float>?) {
        guard !strokeHold, !rideHold else { return }
        if pinchStart == nil { adoptMoment(); pinchStart = (goalScale, goalOffset) }
        isGesturing = true
        guard let start = pinchStart else { return }
        let s = min(1, max(Self.closest, start.scale / Float(max(0.05, magnification))))
        var o = start.offset
        // Scaling about the anchor P: the look point T moves to P + (T - P) * (new / old). Both are measured from
        // fitPivot (the anchor arrives as an absolute table point), so T is the offset itself and P the anchor less it.
        if let anchor { let p = anchor - fitPivot; o = p + (start.offset - p) * (s / start.scale) }
        setGoal(scale: s, offset: o)
        focusedBall = nil
    }

    func pinchEnded() {
        pinchStart = nil
        isGesturing = panStart != nil
        // A pinch let go close to the fitted view snaps back to it, so the player never sits a hair off the fit.
        if goalScale > 0.95 { setGoal(scale: 1, offset: .zero) }
    }

    /// A two-finger drag moved by `delta` (world plan metres, the way the table under the fingers moved).
    func panChanged(by delta: SIMD2<Float>) {
        guard !strokeHold, !rideHold else { return }
        if panStart == nil { adoptMoment(); panStart = goalOffset }
        isGesturing = true
        guard let start = panStart else { return }
        // Dragging the table one way moves the look point the other way.
        setGoal(scale: goalScale, offset: start - delta)
        focusedBall = nil
    }

    func panEnded() {
        panStart = nil
        isGesturing = pinchStart != nil
    }

    /// Centre on a ball and zoom in on it (a double tap). `point` is the ball's absolute world plan point; it lands in
    /// the middle of the free space.
    func focus(on point: SIMD2<Float>, ball: Int) {
        guard !rideHold else { return }
        adoptMoment()
        setGoal(scale: Self.focusScale, offset: point - fitPivot)
        focusedBall = ball
    }

    /// True while the hand's goal is the fitted view: nothing pinched, panned, double-tapped or stepped in. The
    /// moment framing (MomentFrame) only moves the view from here, so it never takes over a player's zoom.
    var atFittedView: Bool { !isZoomed }

    /// Ease in on a table point (world plan, metres, absolute): `scale` is how much larger the table looks, so 1.8
    /// brings the camera to 1 / 1.8 of the fitted distance. Goes through the same clamping as every other goal (never
    /// nearer than `closest`, the look point kept on the playing surface) and the same spring in apply(). Not tied to a
    /// ball, so a double tap afterwards behaves as from any other zoom. (Its 0.7.4 caller, the signature close-up, was
    /// retired in 0.7.6 for MomentFrame; kept for the tests and any later caller.)
    func closeUp(on point: SIMD2<Float>, scale: Float) {
        setGoal(scale: 1 / max(1, scale), offset: point - fitPivot)
        focusedBall = nil
    }

    // MARK: Keys and menus

    /// Zoom by whole steps about the middle of the view: positive comes in, negative goes out (View menu Zoom In and
    /// Zoom Out). Coming out to near the fitted view snaps to it, as a pinch let go there does.
    func zoomStep(_ steps: Int) {
        guard steps != 0, !rideHold else { return }
        adoptMoment()
        let s = goalScale / pow(Self.keyZoomFactor, Float(steps))
        if s > 0.95 { setGoal(scale: 1, offset: .zero) } else { setGoal(scale: s, offset: goalOffset) }
        focusedBall = nil
    }

    /// The fitted view (View menu Actual Size).
    func actualSize() { springBack() }

    /// Arrow keys while zoomed: move the view the way the arrow points on screen (x right, y up; -1, 0 or 1 each), so
    /// what lies that way comes into view. Nothing in the fitted view, which already shows the whole table.
    func panStep(_ direction: SIMD2<Float>) {
        guard !rideHold else { return }
        adoptMoment()
        guard goalScale < 0.999, simd_length(direction) > 1e-4 else { return }
        let step = Self.panStepShare * viewDistance
        let move = (planRight * direction.x + planUp * direction.y) * step
        setGoal(scale: goalScale, offset: goalOffset + move)
        focusedBall = nil
    }

    /// Back to the fitted view: a double tap off a ball or on the focused one, and every new shot.
    func springBack() {
        setGoal(scale: 1, offset: .zero)
        focusedBall = nil
        pinchStart = nil; panStart = nil; isGesturing = false
    }

    /// When the last double tap was taken (system uptime, seconds).
    private var lastTap: TimeInterval = -1
    /// True for a double tap that should act. The gestures are attached both to the table and to the aiming layer over
    /// it, so one double tap could reach two handlers; a second one within a fifth of a second (shorter than any two
    /// real double taps can follow each other) is the same tap and is ignored, so it cannot undo the zoom it just made.
    func takeDoubleTap() -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        defer { lastTap = now }
        return now - lastTap > 0.2
    }

    /// Applies the zoom to a camera pose, keeping its look direction (0.7.6 #14): the camera is moved across by the
    /// offset and brought toward the pivot by the scale, newPosition = pivot + offset + (position - pivot) * scale, so
    /// the point pivot + offset sits where the pivot did (the middle of the free space) and the view is larger about
    /// it. Called by TableCamera every frame.
    /// - pivot: the cloth point (world, y = 0) under the middle of the free space for this pose; nil falls back to
    ///   where the line of sight meets the cloth.
    /// - fitPivot: the same point for the fitted view (world plan x, z), which offsets are measured from.
    /// - tableHalf: half the playing surface, metres; the look point is kept inside it.
    func apply(position: SIMD3<Float>, target: SIMD3<Float>, pivot: SIMD3<Float>? = nil, fitPivot: SIMD2<Float>? = nil,
               tableHalf: SIMD2<Float>, reduceMotion: Bool) -> (position: SIMD3<Float>, target: SIMD3<Float>) {
        bound = tableHalf
        if let fitPivot { self.fitPivot = fitPivot }
        goalOffset = clampOffset(goalOffset)
        let now = SceneClock.now  // 0.7.7 clips: scene clock
        let dt = min(0.1, max(0, now - (lastTick ?? now)))
        lastTick = now
        recordScreenDirections(position: position, target: target)
        if isGesturing || reduceMotion {
            scale = goalScale; offset = goalOffset
        } else {
            // Exponential approach: the same "ease toward the target" TableCamera uses for its framing rectangles.
            let k = Float(1 - exp(-dt / Self.easeTime))
            scale += (goalScale - scale) * k
            offset += (goalOffset - offset) * k
        }
        if abs(scale - 1) < 1e-4, simd_length(offset) < 1e-5 { return (position, target) }
        // The pivot: the point under the free space's middle, or where the line of sight meets the cloth; a view that
        // does not look down at all is left alone.
        let dir = simd_normalize(target - position)
        let centre: SIMD3<Float>
        if let pivot {
            centre = pivot
        } else {
            guard dir.y < -1e-3 else { return (position, target) }
            centre = position + dir * (-position.y / dir.y)
        }
        let newPivot = centre + SIMD3(offset.x, 0, offset.y)
        let newPosition = newPivot + (position - centre) * scale
        viewDistance = simd_length(newPosition - newPivot)
        // The look direction is kept (the old code looked at the moved pivot, which turned the camera a little).
        return (newPosition, newPosition + dir)
    }

    /// Keeps the camera's screen directions on the cloth for panStep (see planRight). With world up as the camera's up
    /// vector, screen right is the line of sight crossed with up, and screen up is the line of sight's own run across
    /// the cloth. A camera looking straight down has neither; the last good directions are kept then.
    private func recordScreenDirections(position: SIMD3<Float>, target: SIMD3<Float>) {
        let sight = target - position
        let run = SIMD2<Float>(sight.x, sight.z)
        guard simd_length(run) > 1e-4 else { return }
        planUp = simd_normalize(run)
        // (sight x up) = (-sight.z, 0, sight.x): on the plan, the run turned a quarter clockwise as seen from above.
        planRight = SIMD2<Float>(-planUp.y, planUp.x)
        if !(abs(scale - 1) < 1e-4 && simd_length(offset) < 1e-5) { return }
        // Fitted view: the distance from the camera to where its line of sight meets the cloth.
        let dir = simd_normalize(sight)
        if dir.y < -1e-3 { viewDistance = -position.y / dir.y }
    }
}

// MARK: The hands

/// Pinch, two-finger drag and double tap on the table. Attach to the view that receives the touches; the camera
/// maths is read from the live scene through `bridge`.
struct TableZoomGestures: ViewModifier {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @State private var cameraBox = AimProjector.CameraBox()

    private var zoom: TableZoom? { bridge.table?.zoom }

    /// The camera as it is now, turning 3D-view points into table points (nil before the scene exists).
    private func projector() -> AimProjector? {
        guard let root = bridge.table?.root else { return nil }
        return AimProjector(camera: cameraBox.find(in: root), size: bridge.viewSize, frame: TableFrame(model.timeline.table))
    }

    /// A table position (solver plan) as a world plan point (x, z).
    private func worldPlan(_ p: Vec2) -> SIMD2<Float> {
        let w = TableFrame(model.timeline.table).world(p)
        return SIMD2(w.x, w.z)
    }

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(pinch)
            .simultaneousGesture(doubleTap)
            #if os(iOS)
            .gesture(TwoFingerPan(onChange: pan, onEnd: { zoom?.panEnded() }))
            #endif
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                // The anchor is found once, at the start, with the camera as it was then.
                let anchor = projector()?.table(at: value.startLocation).map(worldPlan)
                zoom?.pinchChanged(magnification: value.magnification, anchor: anchor)
            }
            .onEnded { _ in zoom?.pinchEnded() }
    }

    /// Double tap a ball: centre and zoom on it. Double tap it again, or anywhere off a ball, to come back.
    private var doubleTap: some Gesture {
        SpatialTapGesture(count: 2).onEnded { value in
            // Nothing while the Ride camera flies (0.7.6 #24): the ride ignores the hand zoom.
            guard let zoom = zoom, !zoom.rideHold, zoom.takeDoubleTap(), let proj = projector() else { return }
            // The aiming layer puts back the aim from before the first tap and drops that tap (item 7).
            zoom.onDoubleTap?()
            let timeline = model.timeline
            let radius = timeline.table.ballRadius
            var best: (ball: Int, distance: CGFloat, at: Vec2)?
            for b in 0..<timeline.ballCount {
                let s = timeline.state(ball: b, at: model.time)
                guard !s.pocketed, NextShot.isOnTable(s.position), let p = proj.screen(s.position) else { continue }
                // A touch counts as on a ball within its on-screen radius plus a fingertip's slack (22 points).
                let edge = proj.screen(s.position + Vec2(radius, 0)).map { hypot($0.x - p.x, $0.y - p.y) } ?? 0
                let d = hypot(p.x - value.location.x, p.y - value.location.y)
                if d <= edge + 22, best == nil || d < best!.distance { best = (b, d, s.position) }
            }
            if let hit = best, !(zoom.isZoomed && zoom.focusedBall == hit.ball) {
                zoom.focus(on: worldPlan(hit.at), ball: hit.ball)
            } else if zoom.isZoomed {
                zoom.springBack()
            }
        }
    }

    #if os(iOS)
    /// A two-finger drag: the table point under the drag's start and under its current place, both read with the
    /// camera captured when the drag began (so the moving camera does not feed back into the drag).
    private func pan(start: CGPoint, now: CGPoint, began: Bool) {
        guard let zoom = zoom else { return }
        if began { panProjector = projector() }
        guard let proj = panProjector, let a = proj.table(at: start), let b = proj.table(at: now) else { return }
        zoom.panChanged(by: worldPlan(b) - worldPlan(a))
    }
    #endif

    /// The camera captured when a two-finger drag began (a reference box, since the modifier is a value).
    @State private var panBox = ProjectorBox()
    private var panProjector: AimProjector? {
        get { panBox.projector }
        nonmutating set { panBox.projector = newValue }
    }
}

/// Holds one AimProjector across the frames of a drag.
@MainActor
private final class ProjectorBox {
    var projector: AimProjector?
}

#if os(iOS)
/// UIKit's pan recognizer limited to exactly two fingers (SwiftUI has no two-finger drag), recognising alongside
/// SwiftUI's own gestures so a pinch and a pan can run together. Reports the drag's start and current points in the
/// SwiftUI view's own space.
private struct TwoFingerPan: UIGestureRecognizerRepresentable {
    let onChange: (_ start: CGPoint, _ now: CGPoint, _ began: Bool) -> Void
    let onEnd: () -> Void

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var start = CGPoint.zero
        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let r = UIPanGestureRecognizer()
        r.minimumNumberOfTouches = 2
        r.maximumNumberOfTouches = 2
        r.delegate = context.coordinator
        return r
    }

    func handleUIGestureRecognizerAction(_ r: UIPanGestureRecognizer, context: Context) {
        // Points in the SwiftUI view's own (local) space, the space AimProjector works in.
        switch r.state {
        case .began:
            context.coordinator.start = context.converter.localLocation
            onChange(context.coordinator.start, context.coordinator.start, true)
        case .changed:
            let t = context.converter.localTranslation ?? .zero
            let s = context.coordinator.start
            onChange(s, CGPoint(x: s.x + t.x, y: s.y + t.y), false)
        default:
            onEnd()
        }
    }
}
#endif
