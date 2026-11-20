// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (jump shots: a segment also carries the ball's height above the
//          cloth, its vertical speed and a constant vertical acceleration. On the cloth all three are zero, so every
//          existing segment evaluates exactly as before. In the airborne phase the centre flies a parabola (constant
//          horizontal velocity, height falling under gravity) and the spin is carried unchanged: no cloth friction.)
// PURPOSE: One closed-form piece of a ball's motion. Inside a segment the centre follows a parabola
//          (constant acceleration), angular velocity follows the phase rules, and the vertical spin decays
//          at a constant rate. The solver records segments; playback, slow motion, scrubbing and the Lens
//          evaluate them at any time with no re-simulation.
// SRP/DRY check: Pass - the single evaluator for ball state at time t (the solver builds segments with the
//          same formulas but never evaluates them differently).
import BreakdownLensModel

public struct BallKinematics: Sendable, Equatable {
    public var position: Vec2
    public var velocity: Vec2
    public var omega: Vec3
    /// Height of the ball's lowest point above the cloth (metres; the centre is one radius higher) and its upward
    /// speed. Both zero on the cloth.
    public var height: Double = 0
    public var verticalVelocity: Double = 0
}

public struct BallSegment: Sendable, Equatable {
    public var t0: Double
    /// End of this phase; infinity for a ball at rest.
    public var t1: Double
    public var phase: MotionPhase
    public var position0: Vec2
    public var velocity0: Vec2
    /// Constant acceleration of the ball centre during the segment.
    public var acceleration: Vec2
    public var omega0: Vec3
    /// Angular acceleration of the horizontal spin components (sliding only).
    public var alphaXY: Vec2
    /// Constant deceleration of the vertical spin (rad/s squared).
    public var spinDecay: Double
    public var radius: Double
    public var orientation0: Quat
    /// Height of the ball's lowest point above the cloth at t0, its upward speed at t0, and the constant vertical
    /// acceleration (minus gravity in the air, zero on the cloth). Only the airborne phase has non-zero values.
    public var height0: Double
    public var verticalVelocity0: Double
    public var verticalAcceleration: Double

    public init(t0: Double, t1: Double, phase: MotionPhase, position0: Vec2, velocity0: Vec2, acceleration: Vec2,
                omega0: Vec3, alphaXY: Vec2, spinDecay: Double, radius: Double, orientation0: Quat,
                height0: Double = 0, verticalVelocity0: Double = 0, verticalAcceleration: Double = 0) {
        self.t0 = t0; self.t1 = t1; self.phase = phase
        self.position0 = position0; self.velocity0 = velocity0; self.acceleration = acceleration
        self.omega0 = omega0; self.alphaXY = alphaXY; self.spinDecay = spinDecay
        self.radius = radius; self.orientation0 = orientation0
        self.height0 = height0; self.verticalVelocity0 = verticalVelocity0; self.verticalAcceleration = verticalAcceleration
    }

    public func kinematics(at t: Double) -> BallKinematics {
        let dt = t - t0
        let p = position0 + velocity0 * dt + acceleration * (0.5 * dt * dt)
        let v = velocity0 + acceleration * dt
        let wz = decayedSpin(dt)
        switch phase {
        case .sliding:
            let w = Vec3(omega0.x + alphaXY.x * dt, omega0.y + alphaXY.y * dt, wz)
            return BallKinematics(position: p, velocity: v, omega: w)
        case .rolling:
            // Rolling without slipping: spin follows velocity.
            return BallKinematics(position: p, velocity: v, omega: Vec3(-v.y / radius, v.x / radius, wz))
        case .spinning, .stationary:
            // A stationary segment may sit above the cloth: the parked segment of a ball that flew off the table
            // keeps the height it left at, so playback shows it where it went over the rail.
            return BallKinematics(position: position0, velocity: .zero, omega: Vec3(0, 0, wz), height: height0)
        case .airborne:
            // No cloth: horizontal velocity and every spin component stay constant; height is a falling parabola.
            let h = height0 + verticalVelocity0 * dt + verticalAcceleration * (0.5 * dt * dt)
            return BallKinematics(position: p, velocity: v, omega: omega0, height: h,
                                  verticalVelocity: verticalVelocity0 + verticalAcceleration * dt)
        }
    }

    private func decayedSpin(_ dt: Double) -> Double {
        let w0 = omega0.z
        let mag = w0 < 0 ? -w0 : w0
        let left = mag - spinDecay * dt
        if left <= 0 { return 0 }
        return w0 < 0 ? -left : left
    }

    /// Orientation by integrating angular velocity from the segment start with a fixed substep count.
    /// Deterministic, continuous across segments, rendering and Lens only.
    public func orientation(at t: Double) -> Quat {
        let steps = 6
        let total = t - t0
        if total <= 0 { return orientation0 }
        let h = total / Double(steps)
        var q = orientation0
        var k = 0
        while k < steps {
            let w = kinematics(at: t0 + (Double(k) + 0.5) * h).omega
            q = Quat.fromRotationVector(w * h).multiplied(by: q)
            k += 1
        }
        return q.normalized
    }
}
