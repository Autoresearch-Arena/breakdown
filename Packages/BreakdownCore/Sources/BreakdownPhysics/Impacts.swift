// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: The impact routines: ball against ball, ball against a cushion, ball against the slate. All use the same
//          Coulomb stick-or-slide rule (friction impulse is the smaller of mu times the normal impulse and the impulse
//          that would exactly cancel slip). Formulas follow spec section 3.3.
//          Which cushion model is which (this header used to say the nose tilt "comes with Level B"; it does not, the
//          spec puts it in Level A):
//          - cushion(): the FLAT wall, generation 1. Horizontal normal through the ball's centre, one fixed
//            restitution, the vertical part of the friction impulse dropped. Every trick shot and puzzle was authored
//            on it, and round posts on the other tables use it at every generation (a post is a rubber cylinder
//            standing on the bed, not a rail nose above the ball).
//          - rail(): the spec's LEVEL A rail, generation 2. The nose touches the ball above its centre, so the normal is
//            tilted down into the cloth; restitution falls with the speed into the rail; the impact is resolved in
//            three dimensions, and the cloth then stops the downward speed with no bounce (with its own friction).
//          - Level B (a step-by-step rubber-and-cloth model) is not built and not planned (rails plan).
// Edited: Claude Opus 5.5 High, 20-November-2026 (jump shots: a body state also has a height above the cloth and a
//          vertical speed (both zero on the cloth, so the flat routines above are untouched); two new routines: the
//          slate bounce (a ball driven down into the cloth by a raised cue, or landing from a jump, bounces with the
//          slate restitution while cloth friction works on its contact point) and a full three-dimensional ball-ball
//          contact, used only when a ball in the air is involved.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the Level A rail for generation 2, rail(), beside the untouched flat
//          cushion(); ImpactResult gains bedImpulse, the push the cloth took during a rail hit (zero everywhere else).
//          The header now says truthfully which model is which.)
// SRP/DRY check: Pass - impact maths only; the event loop decides when they run. rail() reuses slate() for its bed
//          impact rather than repeating the cloth friction.
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
    /// Rail hits at generation 2 only: the impulse the cloth took when the rail pushed the ball down into it
    /// (newton-seconds, the bed's no-bounce normal impulse). Zero for every other impact.
    var bedImpulse: Double = 0
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

    /// The Level A rail (generation 2; spec 3.3, plans/21-Nov-2026-rails-plan.md). `n` is the horizontal inward normal
    /// (pointing into the table), as for cushion(). Three stages, each commented below:
    /// 1. Geometry. The nose touches the ball above its centre by R * s (s = PoolParameters.railContactSine, about
    ///    0.27; c its cosine). The contact point from the centre is r_c = -R c n + R s z, and the normal on the ball is
    ///    N = c n - s z: into the table and down into the cloth.
    /// 2. The rail impact, in three dimensions. Restitution falls with the speed into the rail,
    ///    e(v) = max(railRestitutionFloor, cushionRestitution - railRestitutionSlope * v), and never rises above
    ///    cushionRestitution (so a surface with dead rubber keeps its dead rubber). The normal impulse is (1 + e) m v:
    ///    the rail is fixed and spin cannot move the contact point along N (r_c is parallel to N). Friction acts against
    ///    the slip of the contact point across N, Coulomb, capped by the fixed-surface stick impulse 2 m |u| / 7 (the
    ///    same rule as cushion() and slate()).
    /// 3. The bed. A ball on the cloth now has some downward speed; the slate stops it with no bounce. This is slate()
    ///    with restitution zero, so its friction part acts on the contact point under the ball: the second small
    ///    impact that changes how topspin and backspin come off a rail.
    /// Guards. Kinetic plus spin energy may not rise (rails plan step 3, spec test 5): each stage alone is dissipative,
    /// but if rounding ever made the sum rise by more than one part in 10^12, the rail's friction impulse is cut to a
    /// half, a quarter, then nothing, until it does not. A ball whose velocity does not approach along the tilted normal
    /// (only possible in the air, coming down steeply onto the nose) is met by the flat normal instead, so a rail contact
    /// always pushes back. And the ball always leaves the rail's line moving away from it horizontally (with any
    /// restitution above about 0.2 it already does; below that the inward part is removed), because a ball still moving
    /// into the rail would be met again at the same instant.
    static func rail(_ a: BodyState, normal n: Vec2, _ p: PoolParameters) -> ImpactResult {
        let m = p.ballMass, r = p.ballRadius, inertia = p.inertia
        var s = p.railContactSine, c = p.railContactCosine
        let v = Vec3(a.velocity.x, a.velocity.y, a.vz)
        var normal = Vec3(c * n.x, c * n.y, -s)
        if v.dot(normal) >= 0 {
            s = 0; c = 1
            normal = Vec3(n.x, n.y, 0)
        }
        let rc = Vec3(-r * c * n.x, -r * c * n.y, r * s)
        let toward = -v.dot(normal)
        let vIn = toward > 0 ? toward : 0
        var e = p.cushionRestitution - p.railRestitutionSlope * vIn
        if e < p.railRestitutionFloor { e = p.railRestitutionFloor }
        if e > p.cushionRestitution { e = p.cushionRestitution }
        let jn = (1 + e) * m * vIn
        // Slip of the contact point (v + omega x r_c), the part across the normal.
        let u = v + a.omega.cross(rc)
        let ut = u - normal * u.dot(normal)
        let slipMag = ut.length
        let energyBefore = Impacts.kineticEnergy(a, p)

        func resolve(_ frictionScale: Double) -> (state: BodyState, friction: Double, bed: Double) {
            var jf = 0.0
            var f = Vec3.zero
            if slipMag > 1e-12 && jn > 0 {
                let needed = 2 * m * slipMag / 7         // fixed surface: 1/m + R^2/I = 7/(2m) across any tangent
                let limit = p.cushionFriction * jn
                jf = (needed < limit ? needed : limit) * frictionScale
                f = ut * (-jf / slipMag)
            }
            let impulse = normal * jn + f
            let nv = v + impulse * (1 / m)
            var st = a
            st.velocity = Vec2(nv.x, nv.y)
            st.vz = nv.z
            st.omega = a.omega + rc.cross(impulse) * (1 / inertia)
            var bed = 0.0
            if a.height <= 0 {
                // On the cloth: the slate takes the downward speed with no bounce, and its friction works meanwhile.
                st.height = 0
                if st.vz < 0 {
                    var q = p
                    q.slateRestitution = 0
                    let hit = Impacts.slate(st, q)
                    st = hit.states[0]
                    bed = hit.normalImpulse
                }
            }
            let out = st.velocity.dot(n)
            if out < 0 { st.velocity = st.velocity - n * out }
            return (st, jf, bed)
        }

        var best = resolve(1)
        for scale in [0.5, 0.25, 0.0] {
            if Impacts.kineticEnergy(best.state, p) <= energyBefore * (1 + 1e-12) { break }
            best = resolve(scale)
        }
        return ImpactResult(states: [best.state], normalImpulse: jn, frictionImpulse: best.friction, slipSpeed: slipMag,
                            bedImpulse: best.bed)
    }

    /// Kinetic energy of translation (three dimensions) plus spin, joules: what the rail's energy guard compares.
    static func kineticEnergy(_ a: BodyState, _ p: PoolParameters) -> Double {
        0.5 * p.ballMass * (a.velocity.lengthSquared + a.vz * a.vz) + 0.5 * p.inertia * a.omega.lengthSquared
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
