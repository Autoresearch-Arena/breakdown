// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: The impact routines: ball against ball and ball against a flat cushion. Both use the same
//          Coulomb stick-or-slide rule (friction impulse is the smaller of mu times the normal impulse and
//          the impulse that would exactly cancel slip). Formulas follow spec section 3.3. Level A cushion:
//          flat horizontal normal (the nose tilt comes with Level B). Vertical impulses are dropped, so balls
//          stay on the table in this milestone.
// Edited: Claude Opus 5.5 High, 20-November-2026 (jump shots: a body state also has a height above the cloth and a
//          vertical speed (both zero on the cloth, so the flat routines above are untouched); two new routines: the
//          slate bounce (a ball driven down into the cloth by a raised cue, or landing from a jump, bounces with the
//          slate restitution while cloth friction works on its contact point) and a full three-dimensional ball-ball
//          contact, used only when a ball in the air is involved.)
// SRP/DRY check: Pass - impact maths only; the event loop decides when they run.
import BreakdownLensModel

struct BodyState {
    var position: Vec2
    var velocity: Vec2
    var omega: Vec3
    /// Height of the ball's lowest point above the cloth and its upward speed; zero for a ball on the cloth.
    var height: Double = 0
    var vz: Double = 0
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

    /// The slate bounce. The ball is on the cloth moving down at `-a.vz`; the slate sends it back up with restitution,
    /// and during the same short press cloth friction acts on the contact point (Coulomb: the smaller of mu times the
    /// normal impulse and the impulse that exactly stops the slip, as for a cushion). If the rise that results would be
    /// lower than `minimumHop`, the cloth absorbs it and the ball stays down (vz becomes exactly zero).
    static func slate(_ a: BodyState, _ p: PoolParameters) -> ImpactResult {
        let m = p.ballMass, r = p.ballRadius, inertia = p.inertia
        let down = a.vz < 0 ? -a.vz : 0
        let jn = (1 + p.slateRestitution) * m * down
        // Contact point is straight below the centre, r = (0, 0, -R): its velocity is v + omega x r.
        let slip = Vec2(a.velocity.x - r * a.omega.y, a.velocity.y + r * a.omega.x)
        let slipMag = slip.length
        var na = a
        var jf = 0.0
        if slipMag > 1e-12 && jn > 0 {
            let needed = 2 * m * slipMag / 7             // fixed surface: 1/m + R^2/I = 7/(2m)
            let limit = p.slateFriction * jn
            jf = needed < limit ? needed : limit
            let f = slip * (-jf / slipMag)               // horizontal friction impulse on the ball
            na.velocity = a.velocity + f * (1 / m)
            // (r x f) / I with r = (0, 0, -R): (R f.y, -R f.x, 0) / I.
            na.omega = Vec3(a.omega.x + r * f.y / inertia, a.omega.y - r * f.x / inertia, a.omega.z)
        }
        var up = p.slateRestitution * down
        // Rise height is up^2 / 2g; compared without a square root.
        if up * up < 2 * p.gravity * p.minimumHop { up = 0 }
        na.height = 0
        na.vz = up
        return ImpactResult(states: [na], normalImpulse: jn, frictionImpulse: jf, slipSpeed: slipMag)
    }

    /// Ball against ball in three dimensions, for contacts where at least one ball is in the air. Centres are at
    /// (x, y, R + height); the normal runs from a to b. Same restitution and Coulomb friction as the flat routine, but
    /// the contact slip includes every spin component: v_rel + R (omega_a + omega_b) x n, its part across the normal.
    static func ballBall3D(_ a: BodyState, _ b: BodyState, _ p: PoolParameters) -> ImpactResult {
        let m = p.ballMass, r = p.ballRadius, inertia = p.inertia
        let d = Vec3(b.position.x - a.position.x, b.position.y - a.position.y, b.height - a.height)
        let dl = d.length
        let n = dl > 1e-300 ? d * (1 / dl) : Vec3(1, 0, 0)
        let va = Vec3(a.velocity.x, a.velocity.y, a.vz), vb = Vec3(b.velocity.x, b.velocity.y, b.vz)
        let approach = (va - vb).dot(n)
        let jn = (1 + p.ballBallRestitution) * m * (approach > 0 ? approach : 0) * 0.5
        let u = (va - vb) + (a.omega + b.omega).cross(n) * r
        let ut = u - n * u.dot(n)
        let slipMag = ut.length
        var f = Vec3.zero                                // friction impulse on ball a
        var jf = 0.0
        if slipMag > 1e-12 {
            let needed = m * slipMag / 7                 // both balls free: 2/m + 2 R^2/I = 7/m
            let limit = p.ballBallFriction(slip: slipMag) * jn
            jf = needed < limit ? needed : limit
            f = ut * (-jf / slipMag)
        }
        let impulseA = n * (-jn) + f
        let nva = va + impulseA * (1 / m)
        let nvb = vb - impulseA * (1 / m)
        // Both balls turn the same way: (R n x f) / I for a, ((-R n) x (-f)) / I for b.
        let dw = n.cross(f) * (r / inertia)
        var na = a, nb = b
        na.velocity = Vec2(nva.x, nva.y); na.vz = nva.z; na.omega = a.omega + dw
        nb.velocity = Vec2(nvb.x, nvb.y); nb.vz = nvb.z; nb.omega = b.omega + dw
        return ImpactResult(states: [na, nb], normalImpulse: jn, frictionImpulse: jf, slipSpeed: slipMag)
    }
}
