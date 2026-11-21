// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The extra layout features other billiard tables have, as plain data shared by the solver (which collides
//          balls with them), the recorded Timeline (which carries them in its TableSpec so the app can draw them) and
//          the app's table files (which fill them in for bumper pool, five-pin and bar billiards):
//            Post    - a fixed round obstacle standing on the bed (a bumper-pool bumper, a bar-billiards mushroom base).
//                      A ball's centre may not come closer than ballRadius + radius to its centre; a ball flying higher
//                      than `height` passes over it.
//            Pin     - a light standing pin (five-pin skittles, a bar-billiards peg). The first ball to touch it knocks
//                      it down: the ball loses a little speed (a ball-ball style impulse with the pin's mass) and the pin
//                      is gone for the rest of the shot. PinFall records which pin fell, when, and to which ball.
//            BedHole - a capture hole anywhere in the bed (bar billiards' scoring holes, bumper pool's two cups). It works
//                      like a pocket: a ball whose centre comes within captureRadius while on the cloth drops in.
//          All positions are in the solver's table plan: metres, x along the length from 0 to L, y across from 0 to W.
// SRP/DRY check: Pass - data only, no behaviour; the contact maths is in BreakdownPhysics/Simulation.swift.
import BreakdownLensModel

/// A fixed round obstacle. `restitution` and `friction` replace the cushion numbers for its contacts; `height` is how
/// far its top stands above the cloth (a ball in the air whose lowest point is above it goes over).
public struct Post: Sendable, Equatable {
    public var center: Vec2
    public var radius: Double
    public var restitution: Double
    public var friction: Double
    public var height: Double
    public init(center: Vec2, radius: Double, restitution: Double = 0.75, friction: Double = 0.15, height: Double = 0.04) {
        self.center = center; self.radius = radius; self.restitution = restitution; self.friction = friction
        self.height = height
    }
}

/// A standing pin. `radius` is its contact radius at the height of a ball's centre, `mass` its mass in kilograms
/// (a real five-pin skittle is about a tenth of a ball), `restitution` the bounce of the knock, `height` its top above
/// the cloth (a ball in the air whose lowest point is higher passes over it).
public struct Pin: Sendable, Equatable {
    public var center: Vec2
    public var radius: Double
    public var mass: Double
    public var restitution: Double
    public var height: Double
    public init(center: Vec2, radius: Double, mass: Double = 0.017, restitution: Double = 0.8, height: Double = 0.025) {
        self.center = center; self.radius = radius; self.mass = mass; self.restitution = restitution; self.height = height
    }
}

/// A hole in the bed. `radius` is the drawn hole; a ball drops once its centre is within `captureRadius` of `center`
/// (smaller than `radius` for a ball that must be over the hole, not just touching its edge).
public struct BedHole: Sendable, Equatable {
    public var center: Vec2
    public var radius: Double
    public var captureRadius: Double
    public init(center: Vec2, radius: Double, captureRadius: Double) {
        self.center = center; self.radius = radius; self.captureRadius = captureRadius
    }
}

/// One pin knocked down during a shot: which pin (index into TableSpec.pins), the exact time, the ball that knocked it,
/// and the direction the ball pushed it (unit vector in the plan, from the ball's centre through the pin's), which the
/// app topples the pin along.
public struct PinFall: Sendable, Equatable {
    public var pin: Int
    public var time: Double
    public var ball: Int
    public var direction: Vec2
    public init(pin: Int, time: Double, ball: Int, direction: Vec2) {
        self.pin = pin; self.time = time; self.ball = ball; self.direction = direction
    }
}
