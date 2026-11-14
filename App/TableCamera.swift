// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: The camera. Owns the rig and the perspective camera, frames the WHOLE table (rails included) inside the
//          rectangle the screen left free between the title row, the caption slot and the control strip (all measured
//          from the real laid-out views and handed over as a FramingRequest, so the camera never guesses a margin), and
//          swings from a low three-quarter view to straight down as the Lens melts in.
//          Motion on top of the framing, all of it a multiplier on the fitted camera distance so it can never fight the
//          framing: a launch pull-back that eases in over the title moment, a push-in on the break and a slow settle as
//          the balls stop (a pure function of the playback clock, so scrubbing either way shows the same camera; it fades
//          out as the Lens melts in, where the diagram must hold still). With Reduce Motion on none of it runs and it
//          never swings: the view holds one near-overhead angle at one fixed framing and the opacity cross-fade carries
//          the melt. Launch with -noPushIn to switch the push, settle and pull-back off for exact screenshot comparisons.
//          Also owns a small "HUD anchor" parented to the camera, scaled so one unit is one screen point, where the
//          Lens layer hangs its colour legend so it stays put on screen while the camera moves.
//          The framing maths lives in CameraFraming.swift (pure, tested by a harness); this file applies the answer to
//          the entities. Anything about where the camera is, how it moves, field of view or framing margins belongs here
//          and only here. Does NOT belong here: table or Lens drawing, ball placement, measuring the screen (TableStage).
//          History: split out of TableScene.swift in package 0; framing rewritten in package 2 of the glow-up plan; package
//          4 (0.4.0) replaced the window read with measured chrome, added the legend-only-if-needed rule and the motion.
// SRP/DRY check: Pass - camera placement only; framing maths is in CameraFraming, table size arrives as a TableFrame.
import CoreGraphics
import Foundation
import RealityKit
import simd
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

@MainActor
final class TableCamera {
    let rig = Entity()
    /// Child of the camera; one local unit equals one screen point. The Lens legend is parented here.
    let hud = Entity()
    private let camera = PerspectiveCamera()
    private static let fov: Float = 45
    /// How far in front of the camera the HUD plane floats. Anything nearer than the table is fine; nearer than 0.05 is clipped.
    private static let hudDistance: Float = 1.5
    /// Metres the rails and corner blocks reach past the playing surface (cushion 0.04 plus rail 0.16, with a hair spare).
    private static let railReach: Float = 0.21
    /// Rail top height above the cloth, so the near rail's top edge is framed too.
    private static let railHeight: Float = 0.075
    /// The one overhead-ish angle Reduce Motion holds, in degrees. Near the Lens angle so the cross-fade lines up.
    private static let reducedMotionElevation: Float = 80

    init() {
        camera.camera.fieldOfViewInDegrees = Self.fov
        camera.camera.near = 0.05
        camera.camera.far = 40
        rig.addChild(camera)
        camera.addChild(hud)
    }

    /// True when the person asked the system for less motion (or a test launch forced it with -forceReduceMotion).
    static var reduceMotion: Bool {
        if ProcessInfo.processInfo.arguments.contains("-forceReduceMotion") { return true }
        #if canImport(UIKit)
        return UIAccessibility.isReduceMotionEnabled
        #else
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #endif
    }

    /// Wall-clock moment of the first camera update, for the launch pull-back.
    private var introStart: TimeInterval?
    /// The free rectangle as last used, and when, for the easing in `update`.
    private var smoothFree: FramingRect?
    private var lastSize = CGSize.zero
    private var lastTick: TimeInterval = 0
    private static let motionOff = ProcessInfo.processInfo.arguments.contains("-noPushIn")

    private static func smooth(_ x: Double) -> Double { let c = min(1, max(0, x)); return c * c * (3 - 2 * c) }

    /// Frames the whole table and swings from a low three-quarter view to straight down as the Lens melts in.
    /// - melt: 0 warm table, 1 Lens.
    /// - clock, duration: the playback clock and the length of the recorded shot, for the push-in and settle.
    /// - request: the measured free space (see FramingRequest); in the view's own coordinates.
    func update(melt: Double, clock: Double, duration: Double, request q: FramingRequest, frame: TableFrame) {
        let size = q.size
        let reduce = Self.reduceMotion
        let m = Float(melt)
        let ease = m * m * (3 - 2 * m)
        // Portrait puts the long side up the screen: the camera moves round to the short edge.
        let portrait = size.width < size.height
        let yaw: Float = portrait ? .pi / 2 : 0
        let halfX = frame.length * 0.5 + Self.railReach, halfZ = frame.width * 0.5 + Self.railReach
        let lensElevation: Float = (reduce ? Self.reducedMotionElevation : 89) * .pi / 180

        // 1. Where the legend lives, decided once for the Lens view so it does not hop about during the melt.
        let lensFree = CameraFraming.freeRect(q, captionShare: 1)
        let legendRoom = CameraFraming.legendNeedsRoom(free: lensFree, size: size, yaw: yaw, elevation: lensElevation,
                                                       halfX: halfX, halfZ: halfZ, rimHeight: Self.railHeight, fovDegrees: Self.fov)

        // 2. The free rectangle for this moment. Captions and the legend only take room as the Lens arrives (all at
        //    once under Reduce Motion, where nothing may move).
        let arrive = reduce ? 1 : Self.smooth(melt / 0.5)
        var free = CameraFraming.freeRect(q, captionShare: arrive)
        if legendRoom { free.top += (Double(CameraFraming.legendSize.height) + CameraFraming.legendGap) * arrive }

        // Layout can change in one frame (a longer status label wraps, the shot panel opens, a new shot loads captions), so
        // the free rectangle is eased toward its target instead of jumping, and snaps when the view itself changes
        // shape (rotation, window resize) or when motion is off.
        let now = ProcessInfo.processInfo.systemUptime
        if let old = smoothFree, !reduce, !Self.motionOff, lastSize == size {
            let a = 1 - exp(-min(0.1, max(0, now - lastTick)) / 0.12)
            func ease(_ from: Double, _ to: Double) -> Double { from + (to - from) * a }
            free = FramingRect(left: ease(old.left, free.left), top: ease(old.top, free.top),
                               right: ease(old.right, free.right), bottom: ease(old.bottom, free.bottom))
        }
        smoothFree = free; lastSize = size; lastTick = now

        // 3. Push-in, settle and launch pull-back: scale the fitted distance, never the fit itself.
        if introStart == nil { introStart = now }
        let intro = Float(max(0, 1 - (now - (introStart ?? now)) / CameraFraming.introSeconds))
        let motion = !reduce && !Self.motionOff
        let push = CameraFraming.push(clock: clock, duration: duration) * Float(1 - Self.smooth(melt / 0.6))
        let scale = CameraFraming.distanceScale(push: push, intro: intro, motionAllowed: motion)

        let elevation: Float = reduce ? lensElevation : (48 + 41 * ease) * .pi / 180
        let pose = CameraFraming.pose(size: size, rect: free, yaw: yaw, elevation: elevation, halfX: halfX, halfZ: halfZ,
                                      rimHeight: Self.railHeight, fovDegrees: Self.fov, distanceScale: scale)
        camera.look(at: pose.target, from: pose.position, upVector: SIMD3(0, 1, 0), relativeTo: nil)

        // HUD anchor: at the legend's spot, scaled so a local unit is one point on screen.
        let legend = CameraFraming.legendCenter(in: CameraFraming.freeRect(q, captionShare: 1))
        let kY = tan(Self.fov * .pi / 360), d = Self.hudDistance
        let h = Float(max(1, size.height)), w = Float(max(1, size.width))
        let perPoint = 2 * kY * d / h
        let nx = Float(legend.x) / w * 2 - 1, ny = 1 - Float(legend.y) / h * 2
        hud.position = SIMD3(nx * kY * (w / h) * d, ny * kY * d, -d)
        hud.scale = SIMD3(repeating: perPoint)
    }
}
