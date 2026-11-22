// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (the table fills the screen: the playing area is framed between the
//          title row and the controls while the rails may tuck under that glass; no caption or legend room is reserved
//          any more, so toggling the Lens changes only the angle; on a tall screen the warm view tilts steeper, up to
//          74 degrees, until the table fills the height too; the HUD anchor for the old 3D legend is gone, since the
//          legend is now a glass chip in the title row; -frameDebug also measures the playing area).
// PURPOSE: The camera. Owns the rig and the perspective camera, frames the table as large as the screen allows: the
//          playing area (cloth and pocket holes) between the title row and the control strip, the rails anywhere inside
//          the safe area (both edges measured from the real laid-out views and handed over as a FramingRequest, so the
//          camera never guesses a margin), and swings from the warm three-quarter view to straight down as the Lens
//          melts in. The warm view's angle is chosen for the screen shape (CameraFraming.warmElevation).
//          Motion on top of the framing, all of it a multiplier on the fitted camera distance so it can never fight the
//          framing: a launch pull-back that eases in over the title moment, a push-in on the break and a slow settle as
//          the balls stop (a pure function of the playback clock, so scrubbing either way shows the same camera; it fades
//          out as the Lens melts in, where the diagram must hold still). With Reduce Motion on none of it runs and it
//          never swings: the view holds one near-overhead angle at one fixed framing and the opacity cross-fade carries
//          the melt. Launch with -noPushIn to switch the push, settle and pull-back off for exact screenshot comparisons.
//          The framing maths lives in CameraFraming.swift (pure, tested by a harness); this file applies the answer to
//          the entities. Anything about where the camera is, how it moves, field of view or framing margins belongs here
//          and only here. Does NOT belong here: table or Lens drawing, ball placement, measuring the screen (TableStage).
//          History: split out of TableScene.swift in package 0; framing rewritten in package 2 of the glow-up plan; package
//          4 (0.4.0) replaced the window read with measured chrome, added the legend-only-if-needed rule and the motion.
//          Edited: Claude Opus 5.5 High, 20-November-2026 (Ride the shot: update takes an optional ShotCamera, which may
//          replace the pose, field of view and near plane for a replay; the HUD anchor now uses the field of view in use).
// Edited: Claude Opus 5.5 High, 21-November-2026 (look plan package 3: update takes the hand zoom (TableZoom), applied
//          to the fitted pose as one more distance multiplier and a look-point offset, before Ride; after each update
//          the camera reports where its eye is and how large things look (see focal), which TableDetail reads to fade the
//          lamp shade and to pick the ball pictures for small balls).
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 34 and 56: the opening's lamp shot. When the showpiece
//          opening starts (the first launch and Watch the intro; TableStage says when, through cueIntro), the camera
//          opens low beside the table under the lit lamp, with the shade at the top of the frame and the cloth beyond,
//          holds there a moment, then rises into the normal view of the table; TableStage holds the playback clock until
//          it has risen, so the break is watched from the table view. Reduce Motion and -noPushIn skip it. And the
//          camera now reports its view direction and focal size instead of one size at the look point, so TableDetail
//          can size every ball by its own distance.)
// SRP/DRY check: Pass - camera placement only; framing maths is in CameraFraming, table size arrives as a TableFrame;
//          the ride camera's own logic is in ShotCamera, this file only applies its answer (and reuses ShotCamera.mix to
//          blend the lamp shot into the table view).
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
    private let camera = PerspectiveCamera()
    private static let fov: Float = 45
    /// Metres the rails and corner blocks reach past the playing surface (cushion 0.04 plus rail 0.16, with a hair spare).
    private static let railReach: Float = 0.21
    /// Rail top height above the cloth, so the near rail's top edge is framed too.
    private static let railHeight: Float = 0.075
    /// Metres the playing area reaches past the cloth's cushion line: the corner pocket holes (0.065 radius round the
    /// cloth corner) plus a little of their metal rim. This is what must never sit under the title row or the controls.
    private static let playReach: Float = 0.08
    /// The one overhead-ish angle Reduce Motion holds, in degrees. Near the Lens angle so the cross-fade lines up.
    private static let reducedMotionElevation: Float = 80

    init() {
        camera.camera.fieldOfViewInDegrees = Self.fov
        camera.camera.near = 0.05
        camera.camera.far = 40
        rig.addChild(camera)
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

    /// Where the camera's eye was put by the last update (world metres), for the lamp shade's fade (TableDetail).
    private(set) var eye = SIMD3<Float>(0, 3, 0)
    /// The unit direction the camera looked in at the last update.
    private(set) var forward = SIMD3<Float>(0, -1, 0)
    /// Screen points spanned by one metre seen square-on one metre in front of the camera at the last update: the view
    /// height over the field of view's height at one metre. Something r metres across at depth d along `forward` is
    /// r * focal / d points across on screen (TableDetail sizes each ball this way).
    private(set) var focal: Float = 100

    // MARK: The opening's lamp shot (bug plan item 34)

    /// Wall-clock start of the lamp shot, nil when none is running.
    private var lampStart: TimeInterval?
    /// The last value cueIntro was given, so a shot starts only when the opening starts (false to true).
    private var introCued = false
    /// How long the lamp shot holds under the lamp, then how long it takes to rise to the table (wall seconds): long
    /// enough to take in the lit shade and the room, then a rise slow enough to read as one deliberate move.
    static let lampHold: TimeInterval = 1.2
    static let lampRise: TimeInterval = 1.9
    /// The lamp shot's eye height above the cloth: under the 0.61 m below which TableDetail shows the shade in full,
    /// and low enough to look up into its lit opening.
    static let lampEyeHeight: Float = 0.34
    /// The shade's outer size (Tools/blender/make_room.py: a 1.30 by 0.36 m opening at the bottom, a 1.16 by 0.16 m
    /// top, 0.17 m tall; TableRoom stretches its length with the table).
    private static let shadeBottomHalf = SIMD2<Float>(0.65, 0.18)
    private static let shadeTopHalf = SIMD2<Float>(0.58, 0.08)
    private static let shadeHeight: Float = 0.17

    /// Tell the camera whether the showpiece opening is at its start (TableStage, every frame). The lamp shot begins
    /// when this turns true and stops at once if it turns false (the opening was skipped or left).
    func cueIntro(_ on: Bool) {
        if on, !introCued, !Self.reduceMotion, !Self.motionOff { lampStart = ProcessInfo.processInfo.systemUptime }
        if !on { lampStart = nil }
        introCued = on
    }

    /// True until the lamp shot has risen to the table: TableStage holds the playback clock meanwhile.
    var introHolding: Bool {
        guard let start = lampStart else { return false }
        return ProcessInfo.processInfo.systemUptime - start < Self.lampHold + Self.lampRise
    }

    /// The lamp shot: on the side the normal view looks from, a little outside the rail, low, looking toward the
    /// table's middle and tilted up just enough that the shade's top edge sits near the top of the frame. The eye
    /// backs off from the rail until the shade's top and the middle of the cloth both fit in the field of view.
    private static func lampShot(frame: TableFrame, yaw: Float) -> CameraShot {
        let h = lampEyeHeight
        let toward = SIMD2<Float>(sin(yaw), cos(yaw))                  // table centre to camera, in plan (x, z)
        let alongTable = abs(toward.x) > 0.5                           // looking along the table's length
        let stretch = max(0.4, frame.length / 2.54)
        let bottomHalf = alongTable ? shadeBottomHalf.x * stretch : shadeBottomHalf.y
        let topHalf = alongTable ? shadeTopHalf.x * stretch : shadeTopHalf.y
        let tableHalf = alongTable ? frame.length * 0.5 : frame.width * 0.5
        let shadeBottom = TableBuilder.shadeBottom, shadeTop = TableBuilder.shadeBottom + shadeHeight
        let fovRad = fov * .pi / 180, margin: Float = 2 * .pi / 180
        // Start a quarter metre outside the rail and step back 5 cm at a time (at most 1.5 m, well inside the room).
        var d = tableHalf + railReach + 0.25
        var up: Float = 0
        for _ in 0..<30 {
            let topAngle = max(atan((shadeTop - h) / max(0.05, d - topHalf)), atan((shadeBottom - h) / max(0.05, d - bottomHalf)))
            let middleAngle = atan(h / d)
            up = topAngle + margin
            if up + middleAngle + margin <= fovRad { break }
            d += 0.05
        }
        let pitch = up - fovRad * 0.5                                  // the view's centre, above the horizon
        let eye = SIMD3<Float>(toward.x * d, h, toward.y * d)
        let look = SIMD3<Float>(-toward.x * cos(pitch), sin(pitch), -toward.y * cos(pitch))
        return CameraShot(position: eye, target: eye + look, fov: fov, near: ShotCamera.overheadNear)
    }

    /// Wall-clock moment of the first camera update, for the launch pull-back.
    private var introStart: TimeInterval?
    /// The framing rectangles as last used, and when, for the easing in `update`.
    private var smoothFree: Framing?
    private var lastSize = CGSize.zero
    private var lastTick: TimeInterval = 0
    private static let motionOff = ProcessInfo.processInfo.arguments.contains("-noPushIn")

    private static func smooth(_ x: Double) -> Double { let c = min(1, max(0, x)); return c * c * (3 - 2 * c) }

    /// Frames the whole table and swings from a low three-quarter view to straight down as the Lens melts in.
    /// - melt: 0 warm table, 1 Lens.
    /// - clock, duration: the playback clock and the length of the recorded shot, for the push-in and settle.
    /// - request: the measured free space (see FramingRequest); in the view's own coordinates.
    /// - ride: the Ride camera (ShotCamera), which takes over during a replay when Ride is on; nil leaves the camera alone.
    /// - zoom: the hand zoom (pinch, pan, double tap); applied to the fitted pose, under Ride.
    func update(melt: Double, clock: Double, duration: Double, request q: FramingRequest, frame: TableFrame,
                ride: ShotCamera? = nil, zoom: TableZoom? = nil) {
        let size = q.size
        let reduce = Self.reduceMotion
        let m = Float(melt)
        let ease = m * m * (3 - 2 * m)
        // Portrait puts the long side up the screen: the camera moves round to the short edge.
        let portrait = size.width < size.height
        let yaw: Float = portrait ? .pi / 2 : 0
        let table = TableExtents(halfX: frame.length * 0.5 + Self.railReach, halfZ: frame.width * 0.5 + Self.railReach,
                                 rimHeight: Self.railHeight,
                                 playX: frame.length * 0.5 + Self.playReach, playZ: frame.width * 0.5 + Self.playReach)
        let lensElevation: Float = (reduce ? Self.reducedMotionElevation : 89) * .pi / 180

        // 1. The rectangles for this screen: the playing area between the title row and the controls, the rails anywhere
        //    inside the safe area. Nothing here depends on the Lens, so toggling it moves only the angle.
        var free = CameraFraming.framing(q)

        // 2. Layout can change in one frame (the shot panel opens, the comparison card arrives, a status label wraps), so
        //    the rectangles are eased toward their target instead of jumping, and snap when the view itself changes
        //    shape (rotation, window resize) or when motion is off.
        // The un-eased playing-area rectangle, for the Ride camera, which must depend on the clock alone.
        let freeNow = free.inner
        let now = ProcessInfo.processInfo.systemUptime
        if let old = smoothFree, !reduce, !Self.motionOff, lastSize == size {
            free = old.eased(to: free, by: 1 - exp(-min(0.1, max(0, now - lastTick)) / 0.12))
        }
        smoothFree = free; lastSize = size; lastTick = now

        // 3. Push-in, settle and launch pull-back: scale the fitted distance, never the fit itself.
        if introStart == nil { introStart = now }
        let intro = Float(max(0, 1 - (now - (introStart ?? now)) / CameraFraming.introSeconds))
        let motion = !reduce && !Self.motionOff
        let push = CameraFraming.push(clock: clock, duration: duration) * Float(1 - Self.smooth(melt / 0.6))
        let scale = CameraFraming.distanceScale(push: push, intro: intro, motionAllowed: motion)

        // 4. The angle: the warm view is as low as the screen shape allows while still filling it (steeper on a phone
        //    upright), swinging to straight down as the Lens melts in. Reduce Motion holds one angle throughout.
        let elevation: Float
        if reduce || ease >= 1 {
            // (With the Lens fully in, the warm angle plays no part, so the search for it is skipped.)
            elevation = lensElevation
        } else {
            let warm = CameraFraming.warmElevation(size: size, framing: free, yaw: yaw, table: table, fovDegrees: Self.fov)
            elevation = warm + (lensElevation - warm) * ease
        }
        let pose = CameraFraming.pose(size: size, framing: free, yaw: yaw, elevation: elevation, table: table,
                                      fovDegrees: Self.fov, distanceScale: scale)
        // The hand zoom (TableZoom): closer to, and moved across, the fitted view; the look point stays on the cloth.
        var position = pose.position, target = pose.target
        if let zoom {
            let zoomed = zoom.apply(position: position, target: target,
                                    tableHalf: SIMD2(frame.length * 0.5, frame.width * 0.5), reduceMotion: reduce)
            position = zoomed.position
            target = zoomed.target
        }
        // Ride the shot: ShotCamera returns this overhead pose untouched unless Ride is on for the replay.
        var shot = ride?.override(position: position, target: target, fov: Self.fov, free: freeNow, size: size,
                                  reduceMotion: reduce)
            ?? CameraShot(position: position, target: target, fov: Self.fov, near: ShotCamera.overheadNear)
        // The opening's lamp shot: held under the lamp, then blended into the table view as it rises.
        if let start = lampStart {
            let t = now - start
            if t >= Self.lampHold + Self.lampRise {
                lampStart = nil
            } else {
                let w = Float(Self.smooth((t - Self.lampHold) / Self.lampRise))
                shot = ShotCamera.mix(Self.lampShot(frame: frame, yaw: yaw), shot, w)
            }
        }
        if camera.camera.fieldOfViewInDegrees != shot.fov { camera.camera.fieldOfViewInDegrees = shot.fov }
        if camera.camera.near != shot.near { camera.camera.near = shot.near }
        camera.look(at: shot.target, from: shot.position, upVector: SIMD3(0, 1, 0), relativeTo: nil)
        eye = shot.position
        forward = simd_normalize(shot.target - shot.position)
        focal = Float(size.height) / (2 * tan(shot.fov * .pi / 360))
        // Sound stream hook (21-Nov-2026): tell the sound which way screen-right runs across the table, for panning.
        // Screen-right is the view direction crossed with world up (SoundStage normalises it).
        SoundStage.listen(frame: frame, cameraRight: simd_cross(shot.target - shot.position, SIMD3<Float>(0, 1, 0)))
        if Self.frameDebug { logOutline(pose: pose, size: size, safe: q.safe, table: table, melt: melt, elevation: elevation) }
    }

    // MARK: Measuring (launch with -frameDebug)

    private static let frameDebug = ProcessInfo.processInfo.arguments.contains("-frameDebug")
    private var lastOutlineLog = ""

    /// Test hook: prints how much of the view the table covers on screen, projected through the independent matrix
    /// in CameraFraming.project: the outer outline (rails included, at rail height and at cloth level) and the playing
    /// area (cloth and pocket holes). Reported as a share of the whole view height and of the height between the safe
    /// areas, so layout changes can be measured instead of judged by eye. Only logs when the rounded numbers change.
    private func logOutline(pose: CameraFraming.Pose, size: CGSize, safe: FramingInsets, table: TableExtents, melt: Double,
                            elevation: Float) {
        func extent(_ hx: Float, _ hz: Float, _ heights: [Float]) -> (minX: Double, maxX: Double, minY: Double, maxY: Double) {
            var e = (minX: Double.infinity, maxX: -Double.infinity, minY: Double.infinity, maxY: -Double.infinity)
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { for y in heights {
                let p = CameraFraming.project(SIMD3(sx * hx, y, sz * hz), position: pose.position, target: pose.target,
                                              size: size, fovDegrees: Self.fov)
                e = (min(e.minX, p.x), max(e.maxX, p.x), min(e.minY, p.y), max(e.maxY, p.y))
            } } }
            return e
        }
        let o = extent(table.halfX, table.halfZ, [0, table.rimHeight]), c = extent(table.playX, table.playZ, [0])
        let h = Double(size.height), usable = h - safe.top - safe.bottom
        let line = String(format: "OUTLINE melt=%.2f el=%.1f view=%.0fx%.0f rails top=%.0f bottom=%.0f left=%.0f right=%.0f height/usable=%.3f width/view=%.3f play top=%.0f bottom=%.0f height/usable=%.3f",
                          melt, Double(elevation) * 180 / .pi, size.width, size.height, o.minY, o.maxY, o.minX, o.maxX,
                          (o.maxY - o.minY) / usable, (o.maxX - o.minX) / Double(size.width), c.minY, c.maxY, (c.maxY - c.minY) / usable)
        if line != lastOutlineLog { lastOutlineLog = line; NSLog("%@", line) }
    }
}
