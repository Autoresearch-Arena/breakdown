// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: Maps the solver's table frame (x along the long side, y across, z up, metres, origin at a corner of
//          the playing surface) into RealityKit world space (y up, table centred on the origin). The mapping is a
//          proper rotation (z up becomes y up, y across becomes minus z), so orientations convert without a mirror.
// SRP/DRY check: Pass - the one place coordinates are converted; scene, Lens and camera all use it.
import BreakdownLensModel
import BreakdownTimeline
import RealityKit
import simd

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#else
import AppKit
typealias PlatformColor = NSColor
#endif

func rgba(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> PlatformColor {
    PlatformColor(red: r, green: g, blue: b, alpha: a)
}

struct TableFrame {
    let length: Float
    let width: Float
    let ballRadius: Float

    init(_ table: TableSpec) {
        length = Float(table.length); width = Float(table.width); ballRadius = Float(table.ballRadius)
    }

    func world(_ p: Vec2, height: Float = 0) -> SIMD3<Float> {
        SIMD3(Float(p.x) - length * 0.5, height, -(Float(p.y) - width * 0.5))
    }

    func direction(_ v: Vec2) -> SIMD3<Float> { SIMD3(Float(v.x), 0, -Float(v.y)) }

    func orientation(_ q: Quat) -> simd_quatf {
        simd_quatf(ix: Float(q.x), iy: Float(q.z), iz: Float(-q.y), r: Float(q.w))
    }
}
