// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: The pure maths of framing the table. Given the size of the 3D view, the real positions of the title row, the
//          caption slot and the control strip (measured from the laid-out SwiftUI views, never guessed), and the angle the
//          camera looks from, it answers three questions with no RealityKit in sight: "which rectangle of the view is
//          free for the table?", "where must the camera sit so the whole table (rails included) lands inside that
//          rectangle, as large as it can be, and centred?", and "how much does the break's push-in and settle move the
//          camera, and when?". Kept free of RealityKit and UIKit on purpose so a scratch harness can compile this one file
//          with swiftc and sweep hundreds of window shapes, angles and margins, projecting the table corners with a separate
//          matrix and asserting each lands inside the rectangle (see the glow-up plan, Open items).
//          Used by TableCamera.swift only. Does NOT belong here: reading the views or the window (TableStage measures,
//          TableCamera applies), the Lens drawing.
//          History: package 2 wrote the exact-fit pose; package 4 (0.4.0) replaced the guessed margins with measured ones,
//          added the caption slot, the legend-only-if-needed rule and the push-in curve.
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
}

/// What the screen measured, in the 3D view's OWN coordinates (points, origin at the view's top-left corner; the view
/// fills the window so its edges are the window's edges and the safe-area insets are measured in from them).
struct FramingRequest: Equatable {
    var size: CGSize
    var safe: FramingInsets
    /// Bottom edge of the title row (wordmark and status label).
    var headerBottom: Double
    /// Bottom edge of the caption slot on a phone held upright; equal to `headerBottom` where captions sit in a side column.
    var captionBottom: Double
    /// Top edge of the control strip, or nil when the controls are somewhere else (the side column) and the table may
    /// run down to the bottom safe area.
    var controlsTop: Double?
}

enum CameraFraming {
    /// Size in points of the colour legend the Lens shows the first time trails appear (LensLayer draws it at this size).
    static let legendSize = CGSize(width: 330, height: 26)
    /// Gap in points kept between the legend, the title row and the table.
    static let legendGap: Double = 6
    /// Breathing room kept between the table and the sides of the view, in points.
    static let gutter: Double = 10
    /// Breathing room between the table and the title row, caption slot or controls it sits between.
    static let chromeGap: Double = 8

    /// How the free rectangle is cut down for the current moment.
    /// - captionShare: 0 (warm table, no captions) to 1 (Lens, caption slot reserved in full).
    static func freeRect(_ q: FramingRequest, captionShare: Double) -> FramingRect {
        let h = Double(q.size.height)
        let withCaption = rect(q, captionShare: captionShare)
        // At the largest text sizes the controls and the caption slot together can eat the whole screen. A table
        // squeezed to a sliver is worse than a caption that overlaps it, so when less than 30% of the height is left
        // the caption slot stops reserving room (the card then floats over the table, as it did before the slot).
        if captionShare > 0, withCaption.height < 0.3 * h { return rect(q, captionShare: 0) }
        return withCaption
    }

    private static func rect(_ q: FramingRequest, captionShare: Double) -> FramingRect {
        let w = Double(q.size.width), h = Double(q.size.height)
        let share = min(1, max(0, captionShare))
        let topEdge = q.headerBottom + max(0, q.captionBottom - q.headerBottom) * share
        var left = q.safe.left + gutter
        var right = w - q.safe.right - gutter
        let top = max(q.safe.top, topEdge) + chromeGap
        let bottom = (q.controlsTop ?? (h - q.safe.bottom)) - (q.controlsTop == nil ? gutter : chromeGap)
        // Never hand back an inside-out rectangle on a tiny window: keep at least a sliver to frame into.
        if right - left < 40 { let c = (left + right) * 0.5; left = c - 20; right = c + 20 }
        return FramingRect(left: left, top: top, right: right, bottom: max(bottom, top + 40))
    }

    /// Where the legend goes: centred across the free rectangle, along its top edge.
    static func legendCenter(in free: FramingRect) -> CGPoint {
        CGPoint(x: free.centerX, y: free.top + Double(legendSize.height) * 0.5)
    }

    /// True when the legend would sit on the table, so the table must give up its height. When the table is width-limited
    /// (a wide window, a phone on its side) there is empty room above it and the legend lives there for free.
    static func legendNeedsRoom(free: FramingRect, size: CGSize, yaw: Float, elevation: Float, halfX: Float, halfZ: Float,
                                rimHeight: Float, fovDegrees: Float) -> Bool {
        let p = pose(size: size, rect: free, yaw: yaw, elevation: elevation, halfX: halfX, halfZ: halfZ,
                     rimHeight: rimHeight, fovDegrees: fovDegrees)
        var minY = Double.infinity
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { for y in [Float(0), rimHeight] {
            let pt = project(SIMD3(sx * halfX, y, sz * halfZ), position: p.position, target: p.target, size: size, fovDegrees: fovDegrees)
            minY = min(minY, Double(pt.y))
        } } }
        return minY - free.top < Double(legendSize.height) + legendGap
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
    }

    /// The camera position that fits the whole table, as large as possible, centred in `rect`.
    /// - yaw: angle round the vertical axis the camera sits at (0 looks along the long side, pi/2 along the short).
    /// - elevation: radians above the table plane (pi/2 is straight down; clamped just short so "up" stays defined).
    /// - halfX, halfZ: half the outer size of the table (rails included) along world x and z, in metres.
    /// - rimHeight: height of the rail tops above the cloth, so the near rail's top edge is also kept in frame.
    /// - distanceScale: multiplies the fitted distance (see `distanceScale(push:intro:motionAllowed:)`); 1 is the exact fit.
    static func pose(size: CGSize, rect: FramingRect, yaw: Float, elevation: Float, halfX: Float, halfZ: Float,
                     rimHeight: Float, fovDegrees: Float, distanceScale: Float = 1) -> Pose {
        let w = Float(max(1, size.width)), h = Float(max(1, size.height))
        let kY = tan(fovDegrees * .pi / 360)
        let kX = kY * (w / h)
        // View rectangle in normalised device coordinates (x right, y up, both -1 to 1).
        let nx0 = Float(rect.left) / w * 2 - 1, nx1 = Float(rect.right) / w * 2 - 1
        let ny0 = 1 - Float(rect.bottom) / h * 2, ny1 = 1 - Float(rect.top) / h * 2

        let el = min(elevation, 89.5 * .pi / 180)
        let out = SIMD3<Float>(sin(yaw) * cos(el), sin(el), cos(yaw) * cos(el))   // table centre to camera
        let f = -out                                                              // camera looks this way
        let r = simd_normalize(simd_cross(f, SIMD3(0, 1, 0)))
        let u = simd_cross(r, f)

        // The outer table corners at cloth level and at rail height, in camera axes (X right, Y up, Z ahead).
        var pts: [SIMD3<Float>] = []
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { for y in [Float(0), rimHeight] {
            let p = SIMD3<Float>(sx * halfX, y, sz * halfZ)
            pts.append(SIMD3(simd_dot(p, r), simd_dot(p, u), simd_dot(p, f)))
        } } }

        // Slide the camera sideways by (a, b) in its own right/up axes and back by s. A corner then projects to
        //   x = (X - a) / ((Z + s) * kX),  y = (Y - b) / ((Z + s) * kY).
        // Keeping x within [nx0, nx1] gives an interval for a; likewise b. The intervals widen as s grows, so
        // bisect for the smallest s where both are non-empty: the closest camera that still fits everything.
        func interval(_ s: Float, axis: Int, lo: Float, hi: Float, k: Float) -> (Float, Float) {
            var a0 = -Float.infinity, a1 = Float.infinity
            for p in pts {
                let c = axis == 0 ? p.x : p.y
                let depth = p.z + s
                a0 = max(a0, c - hi * k * depth)
                a1 = min(a1, c - lo * k * depth)
            }
            return (a0, a1)
        }
        let minZ = pts.map(\.z).min() ?? 0
        var sLo = max(0.3, -minZ + 0.3), sHi: Float = 200
        for _ in 0..<60 {
            let s = (sLo + sHi) * 0.5
            let ix = interval(s, axis: 0, lo: nx0, hi: nx1, k: kX), iy = interval(s, axis: 1, lo: ny0, hi: ny1, k: kY)
            if ix.0 <= ix.1 && iy.0 <= iy.1 { sHi = s } else { sLo = s }
        }
        let s = sHi
        let ix = interval(s, axis: 0, lo: nx0, hi: nx1, k: kX), iy = interval(s, axis: 1, lo: ny0, hi: ny1, k: kY)
        let a = (ix.0 + ix.1) * 0.5, b = (iy.0 + iy.1) * 0.5
        // The push-in and the launch pull-back scale the fitted distance; 1 is the exact fit and never clips.
        let position = r * a + u * b - f * (s * distanceScale)
        return Pose(position: position, target: position + f, distance: s * distanceScale)
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
