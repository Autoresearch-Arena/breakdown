// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (legend size shrunk to the two-colour card).
// Edited: Claude Opus 5.5 High, 20-November-2026 (the table fills the screen: two-tier framing. The playing area
//          (cloth plus the pocket holes) must stay clear of the title row and the control strip, but the wooden rails
//          around it may tuck under that floating glass, so only the rail outline has to stay inside the safe area.
//          No caption slot and no legend band any more: captions float over the top edge and the legend lives in the
//          title row, so neither costs the table any height. Gutters and gaps are smaller. New: the warm view's angle
//          is chosen per screen shape so a tall phone is filled top to bottom, not just side to side.)
// PURPOSE: The pure maths of framing the table. Given the size of the 3D view, the real positions of the title row and
//          the control strip (measured from the laid-out SwiftUI views, never guessed), and the angle the camera looks
//          from, it answers: "which part of the view must the playing area stay inside, and which part must the whole
//          table (rails included) stay inside?" (framing), "where must the camera sit so the table is as large as it
//          can be, centred, with both of those true?" (pose), "how steep should the warm view be on this screen shape
//          so the table fills the height as well as the width?" (warmElevation), and "how much does the break's
//          push-in and settle move the camera, and when?". Kept free of RealityKit and UIKit on purpose so a scratch
//          harness can compile this one file with swiftc and sweep window shapes, angles and margins, projecting the
//          table corners with a separate matrix (project) and checking them.
//          THE INVARIANT a sweep should check (changed 20-Nov-2026): the playing-area corners land inside
//          Framing.inner and the rail-outline corners land inside Framing.outer, and at least one of them touches its
//          edge (as large as it can be). The rail outline is now ALLOWED to run under the title row and the controls.
//          Used by TableCamera.swift only. Does NOT belong here: reading the views or the window (TableStage measures,
//          TableCamera applies), the Lens drawing, any camera mode other than the table-framing one.
//          History: package 2 wrote the exact-fit pose; package 4 (0.4.0) replaced the guessed margins with measured ones,
//          added the caption slot, the legend-only-if-needed rule and the push-in curve; 20-Nov-2026 removed the caption
//          slot and legend band and added the two-tier fit and the warm angle.
// SRP/DRY check: Pass - framing maths only; replaces the older single-formula framing that lived in TableCamera.
import CoreGraphics
import Foundation
import simd

/// Margins in points, measured inward from each edge of the view.
struct FramingInsets: Equatable {
    var top: Double = 0
    var left: Double = 0
    var bottom: Double = 0
    var right: Double = 0
}

/// A rectangle of the view in points, origin top left, y down (the same way UIKit and SwiftUI count).
struct FramingRect: Equatable {
    var left: Double
    var top: Double
    var right: Double
    var bottom: Double
    var width: Double { right - left }
    var height: Double { bottom - top }
    var centerX: Double { (left + right) * 0.5 }
    var centerY: Double { (top + bottom) * 0.5 }

    /// Moves every edge a share `a` (0...1) of the way toward `to`; used to ease layout changes.
    func eased(to: FramingRect, by a: Double) -> FramingRect {
        func e(_ x: Double, _ y: Double) -> Double { x + (y - x) * a }
        return FramingRect(left: e(left, to.left), top: e(top, to.top), right: e(right, to.right), bottom: e(bottom, to.bottom))
    }
}

/// What the screen measured, in the 3D view's OWN coordinates (points, origin at the view's top-left corner; the view
/// fills the window so its edges are the window's edges and the safe-area insets are measured in from them).
struct FramingRequest: Equatable {
    var size: CGSize
    var safe: FramingInsets
    /// Bottom edge of the title row (back button, legend chip, status label).
    var headerBottom: Double
    /// Top edge of the control strip, or nil when the controls are somewhere else (the side column) and the table may
    /// run down to the bottom safe area.
    var controlsTop: Double?
}

/// The two rectangles the table is fitted to. `inner` holds the playing area, `outer` the whole table with its rails.
struct Framing: Equatable {
    var inner: FramingRect
    var outer: FramingRect

    func eased(to: Framing, by a: Double) -> Framing {
        Framing(inner: inner.eased(to: to.inner, by: a), outer: outer.eased(to: to.outer, by: a))
    }
}

/// The table's size for framing, in metres, as half extents along world x (long side) and z (short side).
struct TableExtents: Equatable {
    /// Outer outline: rails and corner blocks included.
    var halfX: Float
    var halfZ: Float
    /// Rail top height above the cloth, so the near rail's top edge is framed too.
    var rimHeight: Float
    /// Playing area: the cloth plus the pocket holes, which must never sit under the controls.
    var playX: Float
    var playZ: Float
}

enum CameraFraming {
    /// Breathing room between the table and the sides of the view, in points. Small: on a phone upright every point of
    /// width is table size.
    static let gutter: Double = 4
    /// Gap between the playing area and the title row or controls it sits between.
    static let chromeGap: Double = 4
    /// Gap between the rail outline and the safe-area edges (status bar, home indicator).
    static let outerGap: Double = 2

    /// The rectangles for this screen. Sides: the safe area less a gutter for both (nothing floats at the sides).
    /// Top and bottom: the playing area stays between the title row and the controls; the rails may run on under that
    /// glass as far as the safe area.
    static func framing(_ q: FramingRequest) -> Framing {
        let w = Double(q.size.width), h = Double(q.size.height)
        var left = q.safe.left + gutter
        var right = w - q.safe.right - gutter
        // Never hand back an inside-out rectangle on a tiny window: keep at least a sliver to frame into.
        if right - left < 40 { let c = (left + right) * 0.5; left = c - 20; right = c + 20 }

        let safeTop = q.safe.top + outerGap
        let safeBottom = h - q.safe.bottom - (q.controlsTop == nil ? gutter : outerGap)
        let innerTop = max(safeTop, q.headerBottom + chromeGap)
        var innerBottom = min(safeBottom, q.controlsTop.map { $0 - chromeGap } ?? safeBottom)
        // At the largest text sizes the title row and controls can meet; keep a sliver so the fit stays defined.
        innerBottom = max(innerBottom, innerTop + 40)
        let inner = FramingRect(left: left, top: innerTop, right: right, bottom: innerBottom)
        // The outer rectangle always contains the inner one, even when the sliver rule pushed the inner one past it.
        let outer = FramingRect(left: left, top: min(safeTop, innerTop), right: right, bottom: max(safeBottom, innerBottom))
        return Framing(inner: inner, outer: outer)
    }

    // MARK: Break push-in and settle

    /// How far in the camera pushes on the break, as a fraction of its distance (the closest it gets is 1 - this).
    static let pushDepth: Float = 0.03
    /// How much further back the camera starts at launch, easing in over `introSeconds` of wall time.
    static let introPull: Float = 0.07
    static let introSeconds: Double = 1.8

    /// Push-in strength 0...1 for the playback clock `t` of a shot lasting `duration` seconds. A pure function of the
    /// clock, so scrubbing either way shows the same camera: eases in over the first 1.1 s (the break), holds while the
    /// balls fly, then eases out over the last 3.5 s (the balls running out of speed), reaching zero exactly at the end.
    static func push(clock t: Double, duration d: Double) -> Float {
        func smooth(_ x: Double) -> Double { let c = min(1, max(0, x)); return c * c * (3 - 2 * c) }
        guard d > 0.5 else { return 0 }
        let rise = smooth(t / 1.1)
        let settleSpan = min(3.5, d * 0.6)
        let fall = 1 - smooth((t - (d - settleSpan)) / settleSpan)
        return Float(min(rise, fall))
    }

    /// Camera distance multiplier: above 1 is further back. `intro` is 0...1 of the launch ease-in (1 = just launched).
    static func distanceScale(push: Float, intro: Float, motionAllowed: Bool) -> Float {
        guard motionAllowed else { return 1 }
        let i = min(1, max(0, intro)), e = i * i * (3 - 2 * i)
        return 1 + introPull * e - pushDepth * min(1, max(0, push))
    }

    struct Pose {
        var position: SIMD3<Float>
        /// A point straight ahead of the camera (any distance), to look at.
        var target: SIMD3<Float>
        /// Distance from the table centre along the view direction; handy for tests.
        var distance: Float
        /// True when the sides decided the size (there is spare height); false when the top and bottom did.
        var widthLimited: Bool
    }

    /// The camera position that fits the table as large as possible, centred, with the playing area inside
    /// `framing.inner` and the rail outline inside `framing.outer`.
    /// - yaw: angle round the vertical axis the camera sits at (0 looks along the long side, pi/2 along the short).
    /// - elevation: radians above the table plane (pi/2 is straight down; clamped just short so "up" stays defined).
    /// - distanceScale: multiplies the fitted distance (see `distanceScale(push:intro:motionAllowed:)`); 1 is the exact fit.
    static func pose(size: CGSize, framing: Framing, yaw: Float, elevation: Float, table: TableExtents,
                     fovDegrees: Float, distanceScale: Float = 1) -> Pose {
        let w = Float(max(1, size.width)), h = Float(max(1, size.height))
        let kY = tan(fovDegrees * .pi / 360)
        let kX = kY * (w / h)
        // A rectangle of the view in normalised device coordinates (x right, y up, both -1 to 1).
        struct Box { var x0, x1, y0, y1: Float }
        func ndc(_ r: FramingRect) -> Box {
            Box(x0: Float(r.left) / w * 2 - 1, x1: Float(r.right) / w * 2 - 1,
                y0: 1 - Float(r.bottom) / h * 2, y1: 1 - Float(r.top) / h * 2)
        }
        let inner = ndc(framing.inner), outer = ndc(framing.outer)

        let el = min(elevation, 89.5 * .pi / 180)
        let out = SIMD3<Float>(sin(yaw) * cos(el), sin(el), cos(yaw) * cos(el))   // table centre to camera
        let f = -out                                                              // camera looks this way
        let r = simd_normalize(simd_cross(f, SIMD3(0, 1, 0)))
        let u = simd_cross(r, f)

        // Every corner that must be kept in view, in camera axes (X right, Y up, Z ahead), with the box it must stay
        // in: the rail outline at cloth level and at rail height inside the outer box, the playing area's corners at
        // cloth level inside the inner box.
        var bounds: [(p: SIMD3<Float>, box: Box)] = []
        func add(_ p: SIMD3<Float>, _ box: Box) { bounds.append((SIMD3(simd_dot(p, r), simd_dot(p, u), simd_dot(p, f)), box)) }
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            add(SIMD3(sx * table.halfX, 0, sz * table.halfZ), outer)
            add(SIMD3(sx * table.halfX, table.rimHeight, sz * table.halfZ), outer)
            add(SIMD3(sx * table.playX, 0, sz * table.playZ), inner)
        } }

        // Slide the camera sideways by (a, b) in its own right/up axes and back by s. A corner then projects to
        //   x = (X - a) / ((Z + s) * kX),  y = (Y - b) / ((Z + s) * kY).
        // Keeping x within its box gives an interval for a; likewise b. The intervals widen as s grows, so bisect
        // for the smallest s where both are non-empty: the closest camera that still fits everything. Each corner
        // brings its own box, which is how the rails can run under the chrome while the cloth cannot.
        func interval(_ s: Float, vertical: Bool) -> (Float, Float) {
            var a0 = -Float.infinity, a1 = Float.infinity
            for (p, box) in bounds {
                let c = vertical ? p.y : p.x, k = vertical ? kY : kX
                let lo = vertical ? box.y0 : box.x0, hi = vertical ? box.y1 : box.x1
                let depth = p.z + s
                a0 = max(a0, c - hi * k * depth)
                a1 = min(a1, c - lo * k * depth)
            }
            return (a0, a1)
        }
        let minZ = bounds.map(\.p.z).min() ?? 0
        var sLo = max(0.3, -minZ + 0.3), sHi: Float = 200
        for _ in 0..<60 {
            let s = (sLo + sHi) * 0.5
            let ix = interval(s, vertical: false), iy = interval(s, vertical: true)
            if ix.0 <= ix.1 && iy.0 <= iy.1 { sHi = s } else { sLo = s }
        }
        let s = sHi
        let ix = interval(s, vertical: false), iy = interval(s, vertical: true)
        let a = (ix.0 + ix.1) * 0.5, b = (iy.0 + iy.1) * 0.5
        // Which pair of edges decided the size: the one with no slack left. Slack is compared in screen units
        // (divided by the focal factor) so a tall and a wide view are judged alike.
        let widthLimited = (ix.1 - ix.0) / kX <= (iy.1 - iy.0) / kY
        // The push-in and the launch pull-back scale the fitted distance; 1 is the exact fit and never clips.
        let position = r * a + u * b - f * (s * distanceScale)
        return Pose(position: position, target: position + f, distance: s * distanceScale, widthLimited: widthLimited)
    }

    // MARK: Warm view angle

    /// The warm view's usual angle above the table, and the steepest it may go to fill a tall screen, in degrees.
    static let warmElevationBase: Float = 48
    static let warmElevationMax: Float = 74

    /// The warm view's angle for this screen shape. A low three-quarter view foreshortens the table's depth, so on a
    /// tall screen (a phone upright) the table fills the width and leaves empty height above and below it. Tilting the
    /// camera steeper makes the table taller on screen without making it narrower, so this finds the lowest angle
    /// (from 48 up to 74 degrees) at which the height is used up too. On a wide screen the height already decides the
    /// size at 48 degrees, so the angle stays 48. Continuous in the layout, so an eased layout change eases the angle.
    static func warmElevation(size: CGSize, framing: Framing, yaw: Float, table: TableExtents, fovDegrees: Float) -> Float {
        let lo0 = warmElevationBase * .pi / 180, hi0 = warmElevationMax * .pi / 180
        func spareHeight(_ el: Float) -> Bool {
            pose(size: size, framing: framing, yaw: yaw, elevation: el, table: table, fovDegrees: fovDegrees).widthLimited
        }
        guard spareHeight(lo0) else { return lo0 }
        guard !spareHeight(hi0) else { return hi0 }
        var lo = lo0, hi = hi0
        // Fourteen halvings of a 26-degree span is under a five-hundredth of a degree: far below anything visible.
        for _ in 0..<14 {
            let mid = (lo + hi) * 0.5
            if spareHeight(mid) { lo = mid } else { hi = mid }
        }
        return (lo + hi) * 0.5
    }

    /// Projects a world point to view points (origin top left) for a camera at `position` looking toward `target`
    /// with world up (0,1,0). Built from a look-at matrix and a perspective matrix, deliberately NOT from the same
    /// formulas as `pose`, so the harness that sweeps shapes is an independent check.
    static func project(_ p: SIMD3<Float>, position: SIMD3<Float>, target: SIMD3<Float>, size: CGSize, fovDegrees: Float) -> CGPoint {
        let f = simd_normalize(target - position)
        let r = simd_normalize(simd_cross(f, SIMD3(0, 1, 0)))
        let u = simd_cross(r, f)
        let view = simd_float4x4(columns: (SIMD4(r.x, u.x, -f.x, 0), SIMD4(r.y, u.y, -f.y, 0), SIMD4(r.z, u.z, -f.z, 0),
                                           SIMD4(-simd_dot(r, position), -simd_dot(u, position), simd_dot(f, position), 1)))
        let aspect = Float(size.width / size.height)
        let t = 1 / tan(fovDegrees * .pi / 360)
        let near: Float = 0.05, far: Float = 40
        let proj = simd_float4x4(columns: (SIMD4(t / aspect, 0, 0, 0), SIMD4(0, t, 0, 0),
                                           SIMD4(0, 0, -(far + near) / (far - near), -1), SIMD4(0, 0, -2 * far * near / (far - near), 0)))
        let c = proj * view * SIMD4(p, 1)
        let ndc = SIMD2(c.x / c.w, c.y / c.w)
        return CGPoint(x: Double((ndc.x + 1) * 0.5) * Double(size.width), y: Double((1 - ndc.y) * 0.5) * Double(size.height))
    }
}
