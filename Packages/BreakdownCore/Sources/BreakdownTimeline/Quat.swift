// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: Unit quaternion used only for ball orientation (what the renderer draws and the Lens spin ring
//          shows). Orientation never feeds back into the solver, so it may use Foundation trigonometry.
// SRP/DRY check: Pass - orientation math only.
import BreakdownLensModel
import Foundation

public struct Quat: Sendable, Equatable {
    public var w: Double, x: Double, y: Double, z: Double
    public init(w: Double, x: Double, y: Double, z: Double) { self.w = w; self.x = x; self.y = y; self.z = z }
    public static let identity = Quat(w: 1, x: 0, y: 0, z: 0)

    /// Rotation by `rotation` (a vector whose direction is the axis and whose length is the angle in radians).
    public static func fromRotationVector(_ r: Vec3) -> Quat {
        let angle = r.length
        if angle < 1e-12 { return Quat(w: 1, x: r.x * 0.5, y: r.y * 0.5, z: r.z * 0.5).normalized }
        let s = sin(angle * 0.5) / angle
        return Quat(w: cos(angle * 0.5), x: r.x * s, y: r.y * s, z: r.z * s)
    }

    /// self applied after `rhs` (Hamilton product self * rhs).
    public func multiplied(by q: Quat) -> Quat {
        Quat(w: w * q.w - x * q.x - y * q.y - z * q.z,
             x: w * q.x + x * q.w + y * q.z - z * q.y,
             y: w * q.y - x * q.z + y * q.w + z * q.x,
             z: w * q.z + x * q.y - y * q.x + z * q.w)
    }

    public var normalized: Quat {
        let l = (w * w + x * x + y * y + z * z).squareRoot()
        return l > 0 ? Quat(w: w / l, x: x / l, y: y / l, z: z / l) : .identity
    }
}
