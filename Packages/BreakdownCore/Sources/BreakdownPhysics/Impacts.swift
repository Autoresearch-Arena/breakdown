// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: The impact routines: ball against ball and ball against a flat cushion. Both use the same
//          Coulomb stick-or-slide rule (friction impulse is the smaller of mu times the normal impulse and
//          the impulse that would exactly cancel slip). Formulas follow spec section 3.3. Level A cushion:
//          flat horizontal normal (the nose tilt comes with Level B). Vertical impulses are dropped, so balls
//          stay on the table in this milestone.
// SRP/DRY check: Pass - impact maths only; the event loop decides when they run.
import BreakdownLensModel

struct BodyState {
    var position: Vec2
    var velocity: Vec2
    var omega: Vec3
}

struct ImpactResult {
    var states: [BodyState]
    var normalImpulse: Double
    var frictionImpulse: Double
    var slipSpeed: Double
}

enum Impacts {
    /// Ball `i` (first) hits ball `j` (second). Normal points from i to j. Caller guarantees they approach.
    static func ballBall(_ a: BodyState, _ b: BodyState, _ p: PoolParameters) -> ImpactResult {
        let m = p.ballMass, r = p.ballRadius, inertia = p.inertia
        let n = (b.position - a.position).normalized
        let t = n.perp
        let approach = (a.velocity - b.velocity).dot(n)
        // Equal masses: the normal impulse on each ball is (1 + e) m v_n / 2.
        let jn = (1 + p.ballBallRestitution) * m * approach * 0.5
        // Horizontal contact slip along t: relative sliding plus the spin of both surfaces.
        let slipT = (a.velocity - b.velocity).dot(t) + r * (a.omega.z + b.omega.z)
        let slipMag = slipT < 0 ? -slipT : slipT
        let needed = m * slipMag / 7                    // impulse that cancels the slip exactly
        let limit = p.ballBallFriction(slip: slipMag) * jn
        let jf = needed < limit ? needed : limit
        let signedF = slipT > 0 ? -jf : (slipT < 0 ? jf : 0)   // friction on ball a, along t
        var na = a, nb = b
        na.velocity = a.velocity + (n * (-jn) + t * signedF) * (1 / m)
        nb.velocity = b.velocity + (n * jn + t * (-signedF)) * (1 / m)
        let dOmegaZ = r * signedF / inertia
        na.omega = Vec3(a.omega.x, a.omega.y, a.omega.z + dOmegaZ)
        nb.omega = Vec3(b.omega.x, b.omega.y, b.omega.z + dOmegaZ)
        return ImpactResult(states: [na, nb], normalImpulse: jn, frictionImpulse: jf, slipSpeed: slipMag)
    }

    /// Ball hits a cushion whose inward normal is `n` (pointing into the table).
    static func cushion(_ a: BodyState, normal n: Vec2, _ p: PoolParameters) -> ImpactResult {
        let m = p.ballMass, r = p.ballRadius, inertia = p.inertia
        let t = n.perp
        let vn = a.velocity.dot(n)                       // negative: moving into the cushion
        let jn = (1 + p.cushionRestitution) * m * (vn < 0 ? -vn : vn)
        // Contact point is r = -R n. Slip has a horizontal part along t and a vertical part.
        let slipT = a.velocity.dot(t) - r * a.omega.z
        let slipZ = r * (a.omega.y * n.x - a.omega.x * n.y)
        let slipMag = (slipT * slipT + slipZ * slipZ).squareRoot()
        var ft = 0.0, fz = 0.0
        if slipMag > 1e-12 {
            let needed = 2 * m * slipMag / 7             // fixed surface: 1/m + R^2/I = 7/(2m)
            let limit = p.cushionFriction * jn
            let jf = needed < limit ? needed : limit
            ft = -jf * slipT / slipMag
            fz = -jf * slipZ / slipMag
        }
        var na = a
        // Vertical impulse is dropped (ball stays on the cloth); horizontal part changes velocity.
        na.velocity = a.velocity + (n * jn + t * ft) * (1 / m)
        // Change in spin is (r x J) / I with r = -R n.
        let dwz = -r * ft / inertia
        let dwt = r * fz / inertia                       // along the horizontal tangent t
        na.omega = Vec3(a.omega.x + t.x * dwt, a.omega.y + t.y * dwt, a.omega.z + dwz)
        let jfMag = (ft * ft + fz * fz).squareRoot()
        return ImpactResult(states: [na], normalImpulse: jn, frictionImpulse: jfMag, slipSpeed: slipMag)
    }
}
