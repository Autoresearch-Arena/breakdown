// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: The pure maths of framing the table. Given the size of the view in points, the margins the system and the
//          app's own title and controls take away, and the angle the camera looks from, it answers two questions with
//          no RealityKit in sight: "which rectangle of the screen may the table use?" and "where must the camera sit so
//          the whole table (rails included) lands inside that rectangle, as large as it can be, and centred?".
//          Kept free of RealityKit and UIKit on purpose so a scratch harness can compile this one file with swiftc
//          and sweep hundreds of window shapes, angles and margins, projecting the table corners with a separate
//          matrix and asserting each lands inside the rectangle (see plans/13-Nov-2026-apple-showcase-glow-up-plan.md,
//          Open items, for where that harness lives and what it found).
//          Used by TableCamera.swift only. Does NOT belong here: reading the window (TableCamera), the Lens drawing.
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

enum CameraFraming {
    /// Size in points of the colour legend the Lens shows the first time trails appear (LensLayer draws it at this size).
    static let legendSize = CGSize(width: 196, height: 44)
    /// Gap in points kept between the legend, the title row and the table.
    static let legendGap: Double = 6
    /// Below this view height (a phone on its side) the legend sits in the empty side margin instead of above the table.
    static let compactHeight: Double = 520
    /// Height of the app's title row under the status bar: footnote text plus the 8 point padding the screen adds.
    static let titleRowHeight: Double = 40
    /// Breathing room kept between the table and any edge or control, in points.
    static let gutter: Double = 12

    /// Where the legend goes and what it costs the table.
    struct Layout {
        var tableRect: FramingRect
        /// Centre of the legend in points (view coordinates).
        var legendCenter: CGPoint
    }

    /// The rectangle the table may use, and the legend's spot, for a view of `size` points.
    /// - safe: the system's safe-area insets (status bar, Dynamic Island, home indicator, Mac title bar).
    /// - controlsHeight: points the bottom control strip covers, above the bottom safe inset.
    /// - extra: more margin the screen asks for (for example a caption column), added on top of everything else.
    static func layout(size: CGSize, safe: FramingInsets, controlsHeight: Double, extra: FramingInsets = FramingInsets()) -> Layout {
        let w = Double(size.width), h = Double(size.height)
        var left = safe.left + extra.left + gutter
        var right = w - safe.right - extra.right - gutter
        var top = safe.top + extra.top + titleRowHeight
        let bottom = h - safe.bottom - 12 - controlsHeight - extra.bottom - gutter
        let lw = Double(legendSize.width), lh = Double(legendSize.height)
        var legend = CGPoint(x: left + lw * 0.5, y: top + lh * 0.5)
        if h < compactHeight {
            // Phone on its side: no height to spare. The table is limited by height, so there is a wide empty
            // margin to its left; the legend lives there, vertically centred in the usable height.
            legend = CGPoint(x: safe.left + 4 + lw * 0.5, y: (top + bottom) * 0.5)
        } else {
            top += lh + legendGap
        }
        // Never hand back an inside-out rectangle on a tiny window: keep at least a sliver to frame into.
        if right - left < 40 { let c = (left + right) * 0.5; left = c - 20; right = c + 20 }
        let minBottom = top + 40
        return Layout(tableRect: FramingRect(left: left, top: top, right: right, bottom: max(bottom, minBottom)), legendCenter: legend)
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
    static func pose(size: CGSize, rect: FramingRect, yaw: Float, elevation: Float, halfX: Float, halfZ: Float,
                     rimHeight: Float, fovDegrees: Float) -> Pose {
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
        let position = r * a + u * b - f * s
        return Pose(position: position, target: position + f, distance: s)
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
