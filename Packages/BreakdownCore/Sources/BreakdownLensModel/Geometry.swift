// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: Tiny vector types shared by every module. Only add, subtract, multiply, divide and square root
//          are used, so the physics module can depend on this file without breaking the no-libm rule.
// SRP/DRY check: Pass - the one place 2D and 3D vector arithmetic lives.

public struct Vec2: Sendable, Equatable, Hashable {
    public var x: Double
    public var y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    public static let zero = Vec2(0, 0)

    public static func + (a: Vec2, b: Vec2) -> Vec2 { Vec2(a.x + b.x, a.y + b.y) }
    public static func - (a: Vec2, b: Vec2) -> Vec2 { Vec2(a.x - b.x, a.y - b.y) }
    public static func * (a: Vec2, s: Double) -> Vec2 { Vec2(a.x * s, a.y * s) }
    public static func * (s: Double, a: Vec2) -> Vec2 { Vec2(a.x * s, a.y * s) }
    public static prefix func - (a: Vec2) -> Vec2 { Vec2(-a.x, -a.y) }
    public func dot(_ b: Vec2) -> Double { x * b.x + y * b.y }
    public var lengthSquared: Double { x * x + y * y }
    public var length: Double { lengthSquared.squareRoot() }
    /// Unit vector, or zero when the vector is (almost) zero.
    public var normalized: Vec2 { let l = length; return l > 1e-300 ? Vec2(x / l, y / l) : .zero }
    /// Counter-clockwise perpendicular (z-axis cross this vector).
    public var perp: Vec2 { Vec2(-y, x) }
}

public struct Vec3: Sendable, Equatable, Hashable {
    public var x: Double
    public var y: Double
    public var z: Double
    public init(_ x: Double, _ y: Double, _ z: Double) { self.x = x; self.y = y; self.z = z }
    public static let zero = Vec3(0, 0, 0)

    public static func + (a: Vec3, b: Vec3) -> Vec3 { Vec3(a.x + b.x, a.y + b.y, a.z + b.z) }
    public static func - (a: Vec3, b: Vec3) -> Vec3 { Vec3(a.x - b.x, a.y - b.y, a.z - b.z) }
    public static func * (a: Vec3, s: Double) -> Vec3 { Vec3(a.x * s, a.y * s, a.z * s) }
    public func dot(_ b: Vec3) -> Double { x * b.x + y * b.y + z * b.z }
    public var lengthSquared: Double { dot(self) }
    public var length: Double { lengthSquared.squareRoot() }
}
