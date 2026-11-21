// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream hook: strokeHold, set while a stroke is drawn on the cue
//          ball (StrokeGesture), keeps pinch and two-finger pan still, so a bridge finger resting on the cloth beside a
//          moving stroke finger is not read as a zoom or a pan.)
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
    private(set) var goalScale: Float = 1
    private(set) var goalOffset = SIMD2<Float>.zero
    /// Where the camera is now, eased toward the goal.
    private var scale: Float = 1
    private var offset = SIMD2<Float>.zero
    private var lastTick: TimeInterval?
    /// Half the playing surface (set by TableCamera each frame from the table), the bound for the look point.
    private var bound = SIMD2<Float>(1.27, 0.635)
    /// The ball a double tap last zoomed onto, so a second double tap on it comes back out.
    private(set) var focusedBall: Int?
    /// True while fingers are on a pinch or a two-finger drag: the aiming layer ignores its own drag meanwhile.
    var isGesturing = false
    /// True while the player strokes the cue ball (StrokeGesture): a second finger then is the bridge hand, so pinches
    /// and two-finger drags are ignored until the stroke ends.
    var strokeHold = false

    /// True when the hand has zoomed or moved the view away from the fitted one.
    var isZoomed: Bool { goalScale < 0.999 || simd_length(goalOffset) > 0.002 }

    // Gesture starting points.
    private var pinchStart: (scale: Float, offset: SIMD2<Float>)?
    private var panStart: SIMD2<Float>?

    private func setGoal(scale s: Float, offset o: SIMD2<Float>) {
        goalScale = min(1, max(Self.closest, s))
        goalOffset = simd_clamp(o, -bound, bound)
    }

    /// A pinch moved: `magnification` is relative to its start (above 1 spreads the fingers, zooming in). `anchor`, the
    /// table point under the fingers when the pinch began (world plan), stays under them as the view scales about it.
    func pinchChanged(magnification: CGFloat, anchor: SIMD2<Float>?) {
        guard !strokeHold else { return }
        isGesturing = true
        if pinchStart == nil { pinchStart = (goalScale, goalOffset) }
        guard let start = pinchStart else { return }
        let s = min(1, max(Self.closest, start.scale / Float(max(0.05, magnification))))
        var o = start.offset
        // Scaling about the anchor P: the look point T moves to P + (T - P) * (new / old). The fitted look point is
        // taken as the table's middle (the framing centres the table), so T is the offset itself.
        if let p = anchor { o = p + (start.offset - p) * (s / start.scale) }
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
        guard !strokeHold else { return }
        isGesturing = true
        if panStart == nil { panStart = goalOffset }
        guard let start = panStart else { return }
        // Dragging the table one way moves the look point the other way.
        setGoal(scale: goalScale, offset: start - delta)
        focusedBall = nil
    }

    func panEnded() {
        panStart = nil
        isGesturing = pinchStart != nil
    }

    /// Centre on a ball and zoom in on it (a double tap).
    func focus(on point: SIMD2<Float>, ball: Int) {
        setGoal(scale: Self.focusScale, offset: point)
        focusedBall = ball
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

    /// Applies the zoom to a camera pose. The pose's look point on the cloth (where its line of sight meets y = 0) is
    /// moved by the offset, and the camera is brought toward it by the scale. Called by TableCamera every frame.
    /// - tableHalf: half the playing surface, metres; the look point is kept inside it.
    func apply(position: SIMD3<Float>, target: SIMD3<Float>, tableHalf: SIMD2<Float>, reduceMotion: Bool) -> (position: SIMD3<Float>, target: SIMD3<Float>) {
        bound = tableHalf
        goalOffset = simd_clamp(goalOffset, -bound, bound)
        let now = ProcessInfo.processInfo.systemUptime
        let dt = min(0.1, max(0, now - (lastTick ?? now)))
        lastTick = now
        if isGesturing || reduceMotion {
            scale = goalScale; offset = goalOffset
        } else {
            // Exponential approach: the same "ease toward the target" TableCamera uses for its framing rectangles.
            let k = Float(1 - exp(-dt / Self.easeTime))
            scale += (goalScale - scale) * k
            offset += (goalOffset - offset) * k
        }
        if abs(scale - 1) < 1e-4, simd_length(offset) < 1e-5 { return (position, target) }
        // Where the line of sight meets the cloth; a view that does not look down at all is left alone.
        let dir = simd_normalize(target - position)
        guard dir.y < -1e-3 else { return (position, target) }
        let pivot = position + dir * (-position.y / dir.y)
        let newPivot = pivot + SIMD3(offset.x, 0, offset.y)
        return (newPivot + (position - pivot) * scale, newPivot)
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
            guard let zoom = zoom, zoom.takeDoubleTap(), let proj = projector() else { return }
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
