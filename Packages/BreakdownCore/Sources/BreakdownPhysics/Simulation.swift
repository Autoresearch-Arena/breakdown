// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (real pocket mouths: the straight cushions stop at the knuckles,
//          and two new contact kinds join the cushion rank: a jaw face (a straight segment, contact when the ball's
//          centre is one radius off it and inside the segment's length) and a knuckle (a point, contact when the centre
//          is one radius from it, an exact quartic root like every other event). Both reuse Impacts.cushion with
//          the face's own normal, so a ball that clips the mouth rebounds and can rattle between the jaws.)
// Edited: Claude Opus 5.5 High, 20-November-2026 (jump and masse. A raised cue (CueStrike.elevation) drives the ball
//          into the cloth and tilts its spin axis; the slate bounces it back up, and a bounce that rises at least
//          minimumHop leaves the cloth. In the air a ball flies a closed-form parabola (new phase airborne, spin carried,
//          no cloth friction) and lands with an exact time; each landing is another slate bounce, so the hops shrink
//          quickly and the ball then slides and rolls as usual. While airborne: ball-ball contact uses the 3D distance
//          between centres (still a quartic: a ball high enough clears one on the cloth); cushions, jaws, knuckles and
//          holes only count while the ball's lowest point is below the cushion nose; above it, crossing a cushion line
//          means it flew off the table (a pocket-like outcome, event flight offTable) or, over a hole, into the pocket.
//          A level strike (elevation zero) takes exactly the old code path, so old recordings are bit-for-bit equal.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (other tables. Posts: a fixed round obstacle is a point contact at
//          ballRadius + post radius, the knuckle test generalised, in the cushion rank after the knuckles, answered by
//          Impacts.cushion with the post's own restitution and friction and recorded as a cushion event with edge .post.
//          Pins: the same contact test against each standing pin (a new rank, pin, last in the tie-break so no older
//          ordering changes); the first touch knocks the pin down (a pinDown event), takes a ball-ball style impulse
//          with the pin's mass off the ball, and the pin plays no further part in the shot. A ball in the air higher
//          than a post's or pin's height passes over it. Bed holes join the capture list after the edge pockets and are
//          recorded as pocket 6 + j. With pocketsEnabled false the edge pockets, jaws and knuckles are gone and each
//          cushion runs its whole side. A pool table has none of these, so its events and their order are unchanged.)
// PURPOSE: The event-driven billiards solver. A shot is a list of closed-form segments per ball (sliding,
//          rolling, spinning, stationary) plus exact events. The loop repeatedly finds the earliest next
//          event among: a ball's phase ending, a pocket capture, a cushion hit and a ball-ball contact,
//          advances to it, applies it, and starts new segments for the balls it touched. Because motion is
//          polynomial between events, nothing can tunnel and every contact has an exact time for the Lens.
//          Event ordering key: time, kind rank, lowest ball, second ball (never dictionary order).
//          Double only; add, subtract, multiply, divide, square root; no Foundation import (no libm).
// SRP/DRY check: Pass - orchestration of events; impacts live in Impacts, roots in RootFinder.
import BreakdownLensModel
import BreakdownTimeline

/// Tie-break order for events at the same instant. offTable is last and new, so older orderings never change.
/// pin (21-Nov-2026) is newer still and comes after offTable for the same reason.
private enum EventRank: Int { case transition = 0, pocket = 1, cushion = 2, ballBall = 3, offTable = 4, pin = 5 }

private struct Candidate {
    var time: Double
    var rank: EventRank
    var a: Int
    var b: Int           // second ball, or wall / pocket index
    func precedes(_ o: Candidate) -> Bool {
        if time != o.time { return time < o.time }
        if rank.rawValue != o.rank.rawValue { return rank.rawValue < o.rank.rawValue }
        if a != o.a { return a < o.a }
        return b < o.b
    }
}

private struct Wall {
    var normal: Vec2          // inward
    var offset: Double        // inside when normal . p >= offset
    var alongX: Bool          // which coordinate runs along the cushion
    var ranges: [(Double, Double)]
}

/// A pocket jaw face as the solver sees it: a segment from the knuckle back into the pocket, and the unit normal
/// pointing to the side balls are on.
private struct Jaw {
    var start: Vec2
    var direction: Vec2       // unit, from the knuckle into the pocket
    var length: Double
    var normal: Vec2          // unit, toward the playing side
    var pocket: Int
}

private struct Body {
    var segment: BallSegment
    var closed: [BallSegment] = []
    var active = true
}

public enum PoolSolver {
    /// Largest number of events before the loop gives up (a guard, logged as a truncated timeline).
    static let maxEvents = 60_000
    static let maxTime = 90.0

    public static func simulate(_ input: ShotInput) -> Timeline {
        var sim = Simulation(input: input)
        sim.run()
        return sim.timeline()
    }
}

private struct Simulation {
    let P: PoolParameters
    let input: ShotInput
    var bodies: [Body] = []
    var events: [LensEvent] = []
    var pocketTime: [Double?]
    var now = 0.0
    let walls: [Wall]
    let jaws: [Jaw]
    /// The knuckles: the start point of every jaw, where the cushion nose turns into the pocket.
    let knuckles: [(point: Vec2, pocket: Int)]
    /// Every capture hole the solver checks, in this order: the six edge pockets (if the table has them), then the
    /// bed holes. `pocketIndex` turns a position in this list into the pocket number recorded on the event: 0 to 5 for
    /// the edge pockets, 6 + j for bed hole j, whether or not the edge pockets exist.
    let pockets: [Vec2]
    let captureRadii: [Double]
    let pocketIndex: [Int]
    /// Fixed round posts and standing pins (empty on a pool table). A pin that has been knocked down is out of play.
    let posts: [Post]
    let pins: [Pin]
    var pinDown: [Bool]

    init(input: ShotInput) {
        self.input = input
        P = input.parameters
        let edge = P.pocketsEnabled ? Array(P.pocketCenters.prefix(TableSpec.edgePocketCount)) : []
        let edgeRadii = P.pocketsEnabled ? Array(P.pocketCaptureRadii.prefix(TableSpec.edgePocketCount)) : []
        pockets = edge + P.bedHoles.map(\.center)
        captureRadii = edgeRadii + P.bedHoles.map(\.captureRadius)
        pocketIndex = Array(0..<edge.count) + P.bedHoles.indices.map { TableSpec.edgePocketCount + $0 }
        posts = P.posts
        pins = P.pins
        pinDown = [Bool](repeating: false, count: P.pins.count)
        pocketTime = [Double?](repeating: nil, count: input.positions.count)
        let r = P.ballRadius, L = P.tableLength, W = P.tableWidth
        // The straight cushion noses run between knuckles. Past a knuckle the ball meets the knuckle or the jaw.
        let a = P.cornerKnuckleOffset, h = P.sideMouth * 0.5
        if P.pocketsEnabled {
            walls = [
                Wall(normal: Vec2(1, 0), offset: r, alongX: false, ranges: [(a, W - a)]),
                Wall(normal: Vec2(-1, 0), offset: -(L - r), alongX: false, ranges: [(a, W - a)]),
                Wall(normal: Vec2(0, 1), offset: r, alongX: true, ranges: [(a, L * 0.5 - h), (L * 0.5 + h, L - a)]),
                Wall(normal: Vec2(0, -1), offset: -(W - r), alongX: true, ranges: [(a, L * 0.5 - h), (L * 0.5 + h, L - a)]),
            ]
        } else {
            // No pockets: every cushion runs its whole side, corner to corner (a ball reaching a corner meets the two
            // cushions one after the other, each an exact event).
            walls = [
                Wall(normal: Vec2(1, 0), offset: r, alongX: false, ranges: [(0, W)]),
                Wall(normal: Vec2(-1, 0), offset: -(L - r), alongX: false, ranges: [(0, W)]),
                Wall(normal: Vec2(0, 1), offset: r, alongX: true, ranges: [(0, L)]),
                Wall(normal: Vec2(0, -1), offset: -(W - r), alongX: true, ranges: [(0, L)]),
            ]
        }
        var jawList: [Jaw] = []
        for j in P.jaws {
            let d = j.end - j.start
            let len = d.length
            let dir = d * (1 / len)
            // Of the two perpendiculars, the playing side is the one facing the pocket's mouth centre, which lies
            // between this knuckle and its partner on the other side of the mouth.
            let partner = P.jaws.first { $0.pocket == j.pocket && $0.start != j.start }!.start
            let mid = (j.start + partner) * 0.5
            var n = dir.perp
            if n.dot(mid - j.start) < 0 { n = n * -1 }
            jawList.append(Jaw(start: j.start, direction: dir, length: len, normal: n, pocket: j.pocket))
        }
        jaws = jawList
        knuckles = P.jaws.map { ($0.start, $0.pocket) }
        for p in input.positions {
            bodies.append(Body(segment: Self.makeSegment(P, t0: 0, position: p, velocity: .zero, omega: .zero, orientation: .identity)))
        }
        applyStrike()
    }

    // MARK: Segments

    /// Builds the right segment for a ball state: sliding while the cloth contact point slips, then rolling,
    /// then spinning in place, then stationary.
    /// A ball above the cloth, or on it and moving up, gets an airborne segment that ends when it lands. Callers
    /// settle the vertical first (Impacts.slate), so a ball on the cloth here has vz zero or a real take-off speed.
    static func makeSegment(_ P: PoolParameters, t0: Double, position: Vec2, velocity: Vec2, omega: Vec3,
                            orientation: Quat, height: Double = 0, vz: Double = 0) -> BallSegment {
        let R = P.ballRadius, mu = P.slidingFriction, g = P.gravity
        if height > 0 || vz > 0 {
            // Landing time: the positive root of height + vz t - g t^2 / 2 = 0, in closed form.
            let disc = vz * vz + 2 * g * height
            let flight = (vz + disc.squareRoot()) / g
            return BallSegment(t0: t0, t1: t0 + flight, phase: .airborne, position0: position, velocity0: velocity,
                               acceleration: .zero, omega0: omega, alphaXY: .zero, spinDecay: P.spinDecay, radius: R,
                               orientation0: orientation, height0: height, verticalVelocity0: vz,
                               verticalAcceleration: -g)
        }
        let slip = Vec2(velocity.x - R * omega.y, velocity.y + R * omega.x)
        let slipMag = slip.length
        if slipMag > 1e-7 {
            let uhat = slip * (1 / slipMag)
            let a = uhat * (-mu * g)
            let alpha = Vec2(-uhat.y, uhat.x) * (5 * mu * g / (2 * R))
            return BallSegment(t0: t0, t1: t0 + 2 * slipMag / (7 * mu * g), phase: .sliding, position0: position,
                               velocity0: velocity, acceleration: a, omega0: omega, alphaXY: alpha,
                               spinDecay: P.spinDecay, radius: R, orientation0: orientation)
        }
        let speed = velocity.length
        if speed > 1e-6 {
            let a = velocity * (-P.rollingResistance * g / speed)
            let w = Vec3(-velocity.y / R, velocity.x / R, omega.z)
            return BallSegment(t0: t0, t1: t0 + speed / (P.rollingResistance * g), phase: .rolling, position0: position,
                               velocity0: velocity, acceleration: a, omega0: w, alphaXY: .zero,
                               spinDecay: P.spinDecay, radius: R, orientation0: orientation)
        }
        let wz = omega.z < 0 ? -omega.z : omega.z
        if wz > 1e-6 {
            return BallSegment(t0: t0, t1: t0 + wz / P.spinDecay, phase: .spinning, position0: position,
                               velocity0: .zero, acceleration: .zero, omega0: Vec3(0, 0, omega.z), alphaXY: .zero,
                               spinDecay: P.spinDecay, radius: R, orientation0: orientation)
        }
        return BallSegment(t0: t0, t1: .infinity, phase: .stationary, position0: position, velocity0: .zero,
                           acceleration: .zero, omega0: .zero, alphaXY: .zero, spinDecay: P.spinDecay,
                           radius: R, orientation0: orientation)
    }

    private func energy(_ k: BodyState) -> (Double, Double) {
        // Vertical motion only exists in the air; the branch keeps the flat sum exactly as it was for the cloth.
        let lin = k.vz == 0 ? k.velocity.lengthSquared : k.velocity.lengthSquared + k.vz * k.vz
        return (0.5 * P.ballMass * lin, 0.5 * P.inertia * k.omega.lengthSquared)
    }

    private func impactBall(_ ball: Int, _ before: BodyState, _ after: BodyState) -> ImpactBall {
        let (tb, rb) = energy(before), (ta, ra) = energy(after)
        return ImpactBall(ball: ball, velocityBefore: before.velocity, velocityAfter: after.velocity,
                          omegaBefore: before.omega, omegaAfter: after.omega,
                          translationalBefore: tb, rotationalBefore: rb, translationalAfter: ta, rotationalAfter: ra)
    }

    private func bodyState(_ i: Int, at t: Double) -> BodyState {
        let k = bodies[i].segment.kinematics(at: t)
        return BodyState(position: k.position, velocity: k.velocity, omega: k.omega, height: k.height,
                         vz: k.verticalVelocity)
    }

    private func isAirborne(_ i: Int) -> Bool { bodies[i].segment.phase == .airborne }

    /// Close the ball's current segment at `t` and start a new one from `state`.
    private mutating func restart(_ i: Int, at t: Double, with state: BodyState) {
        var old = bodies[i].segment
        let q = old.orientation(at: t)
        old.t1 = t
        bodies[i].closed.append(old)
        bodies[i].segment = Self.makeSegment(P, t0: t, position: state.position, velocity: state.velocity,
                                             omega: state.omega, orientation: q, height: state.height, vz: state.vz)
    }

    /// A ball at the cloth that is moving down bounces off the slate (and stays down if the rise would be under the
    /// minimum hop); a ball at the cloth moving up too slowly to hop stays down. Returns the settled state and the
    /// slate impact, if there was one.
    private func settleVertical(_ s: BodyState) -> (BodyState, ImpactResult?) {
        var st = s
        if st.height < 0 { st.height = 0 }
        if st.height > 0 { return (st, nil) }
        if st.vz < 0 {
            let res = Impacts.slate(st, P)
            return (res.states[0], res)
        }
        if st.vz > 0 && st.vz * st.vz < 2 * P.gravity * P.minimumHop { st.vz = 0 }
        return (st, nil)
    }

    // MARK: Cue strike

    private mutating func applyStrike() {
        let s = input.strike
        if s.elevation > 0 { applyRaisedStrike(); return }
        let d = s.direction
        let k = 2.5 * s.speed / (P.ballRadius * P.ballRadius)       // m * speed / I
        // Contact offsets: up (a) lifts spin about the axis perpendicular to d, side (b) spins about vertical.
        let omega = Vec3(-d.y * k * s.tipUp, d.x * k * s.tipUp, k * s.tipSide)
        let before = BodyState(position: input.positions[0], velocity: .zero, omega: .zero)
        let after = BodyState(position: input.positions[0], velocity: d * s.speed, omega: omega)
        bodies[0].segment = Self.makeSegment(P, t0: 0, position: after.position, velocity: after.velocity,
                                             omega: after.omega, orientation: .identity)
        events.append(LensEvent(time: 0, kind: .cueStrike, point: after.position, normal: d,
                                normalImpulse: P.ballMass * s.speed, balls: [impactBall(0, before, after)]))
    }

    /// A strike with the cue raised. The cue runs along c = (cos e * d, -sin e); the impulse m * speed acts along c
    /// through the tip's contact point, offset `tipSide` to the right (s) and `tipUp` along the cue's own up (u, which
    /// leans back with the cue). The spin is (r x c) * m * speed / I = k * (tipSide * u - tipUp * s): raising the cue
    /// tilts the side-spin axis toward the line of travel, which is what bends a masse. The downward part drives the
    /// ball into the slate at once, and the slate bounce (with friction) decides whether it leaves the cloth.
    private mutating func applyRaisedStrike() {
        let s = input.strike
        let d = s.direction
        let e = s.elevation
        let c = (1 - e * e).squareRoot()                             // cosine of the elevation
        let k = 2.5 * s.speed / (P.ballRadius * P.ballRadius)       // m * speed / I
        let right = Vec3(d.y, -d.x, 0)
        let up = Vec3(e * d.x, e * d.y, c)
        let omega = (up * s.tipSide - right * s.tipUp) * k
        let before = BodyState(position: input.positions[0], velocity: .zero, omega: .zero)
        let struck = BodyState(position: input.positions[0], velocity: d * (s.speed * c), omega: omega,
                               height: 0, vz: -s.speed * e)
        let (after, slate) = settleVertical(struck)
        bodies[0].segment = Self.makeSegment(P, t0: 0, position: after.position, velocity: after.velocity,
                                             omega: after.omega, orientation: .identity, height: after.height,
                                             vz: after.vz)
        events.append(LensEvent(time: 0, kind: .cueStrike, point: after.position, normal: d,
                                normalImpulse: P.ballMass * s.speed, balls: [impactBall(0, before, after)]))
        if let slate, after.vz > 0 {
            events.append(LensEvent(time: 0, kind: .phaseTransition, point: after.position, normal: .zero,
                                    normalImpulse: slate.normalImpulse, frictionImpulse: slate.frictionImpulse,
                                    slipSpeed: slate.slipSpeed, balls: [impactBall(0, struck, after)],
                                    phaseFrom: .sliding, phaseTo: .airborne, flight: .takeOff,
                                    verticalSpeedDown: -struck.vz, verticalSpeedUp: after.vz))
        }
    }

    // MARK: Candidates

    private func quarticCoefficients(_ A: Vec2, _ B: Vec2, _ C: Vec2, minus c0: Double) -> [Double] {
        // |A + B t + C t^2|^2 - c0
        [A.dot(A) - c0, 2 * A.dot(B), B.dot(B) + 2 * A.dot(C), 2 * B.dot(C), C.dot(C)]
    }

    private func nextEvent() -> Candidate? {
        var best: Candidate?
        func consider(_ c: Candidate) { if best == nil || c.precedes(best!) { best = c } }
        let n = bodies.count
        var states: [BodyState?] = []
        for i in 0..<n { states.append(bodies[i].active ? bodyState(i, at: now) : nil) }

        for i in 0..<n where bodies[i].active {
            let seg = bodies[i].segment
            let s = states[i]!
            if seg.t1.isFinite { consider(Candidate(time: seg.t1 < now ? now : seg.t1, rank: .transition, a: i, b: 0)) }
            if seg.phase == .stationary || seg.phase == .spinning { continue }
            if seg.phase == .airborne {
                for c in airborneCandidates(i, seg, s) { consider(c) }
                continue
            }
            let window = seg.t1 - now
            let a = seg.acceleration
            // Pockets
            for (k, c) in pockets.enumerated() {
                let r = captureRadii[k]
                let rel = s.position - c
                if rel.lengthSquared <= r * r { consider(Candidate(time: now, rank: .pocket, a: i, b: k)); continue }
                let poly = quarticCoefficients(rel, s.velocity, a * 0.5, minus: r * r)
                if let tau = RootFinder.firstDownCrossing(poly, limit: window) {
                    consider(Candidate(time: now + tau, rank: .pocket, a: i, b: k))
                }
            }
            // Cushions
            for (w, wall) in walls.enumerated() {
                let poly = [wall.normal.dot(s.position) - wall.offset, wall.normal.dot(s.velocity), 0.5 * wall.normal.dot(a)]
                var tau: Double?
                if poly[0] <= 0 {
                    if poly[1] < 0 { tau = 0 }
                } else {
                    tau = RootFinder.firstDownCrossing(poly, limit: window)
                }
                guard let tt = tau else { continue }
                let p = s.position + s.velocity * tt + a * (0.5 * tt * tt)
                let along = wall.alongX ? p.x : p.y
                if wall.ranges.contains(where: { along >= $0.0 && along <= $0.1 }) {
                    consider(Candidate(time: now + tt, rank: .cushion, a: i, b: w))
                }
            }
            // Jaw faces: the same distance-to-a-line test as a cushion, limited to the face's length. Indices follow
            // the walls, so the tie-break order stays fixed.
            for (k, jaw) in jaws.enumerated() {
                let rel = s.position - jaw.start
                let poly = [jaw.normal.dot(rel) - P.ballRadius, jaw.normal.dot(s.velocity), 0.5 * jaw.normal.dot(a)]
                var tau: Double?
                if poly[0] <= 0 {
                    // Already touching (or a hair inside after rounding): only an approaching ball counts, and only
                    // if it is really beside the face rather than behind the knuckle.
                    if poly[1] < 0 { tau = 0 }
                } else {
                    tau = RootFinder.firstDownCrossing(poly, limit: window)
                }
                guard let tt = tau else { continue }
                let p = s.position + s.velocity * tt + a * (0.5 * tt * tt)
                let along = (p - jaw.start).dot(jaw.direction)
                if along >= 0 && along <= jaw.length && (p - jaw.start).dot(jaw.normal) > -P.ballRadius {
                    consider(Candidate(time: now + tt, rank: .cushion, a: i, b: walls.count + k))
                }
            }
            // Knuckles: a ball's centre may not come closer than one radius to the point where nose meets jaw.
            for (k, knuckle) in knuckles.enumerated() {
                let rel = s.position - knuckle.point
                let r2 = P.ballRadius * P.ballRadius
                if rel.lengthSquared <= r2 {
                    if rel.dot(s.velocity) < 0 { consider(Candidate(time: now, rank: .cushion, a: i, b: walls.count + jaws.count + k)) }
                    continue
                }
                let poly = quarticCoefficients(rel, s.velocity, a * 0.5, minus: r2)
                if let tau = RootFinder.firstDownCrossing(poly, limit: window) {
                    consider(Candidate(time: now + tau, rank: .cushion, a: i, b: walls.count + jaws.count + k))
                }
            }
            // Posts and standing pins: the knuckle's point contact, at ballRadius plus their own radius. A ball on the
            // cloth meets anything that stands above the cloth.
            for c in roundCandidates(i, s, acceleration: a, window: window, airborne: false) { consider(c) }
        }
        // Ball against ball
        for i in 0..<n where bodies[i].active {
            for j in (i + 1)..<max(n, i + 1) where bodies[j].active {
                let si = bodies[i].segment, sj = bodies[j].segment
                let iStatic = si.phase == .stationary || si.phase == .spinning
                let jStatic = sj.phase == .stationary || sj.phase == .spinning
                if iStatic && jStatic { continue }
                let window = min(si.t1, sj.t1) - now
                if !(window > 0) && window != 0 { continue }
                let pi = states[i]!, pj = states[j]!
                if si.phase == .airborne || sj.phase == .airborne {
                    // 3D centre distance: the height difference is a quadratic in time, so its square keeps the
                    // contact test a quartic and the root exact. A ball high enough passes over one on the cloth.
                    let A = Vec3(pi.position.x - pj.position.x, pi.position.y - pj.position.y, pi.height - pj.height)
                    let B = Vec3(pi.velocity.x - pj.velocity.x, pi.velocity.y - pj.velocity.y, pi.vz - pj.vz)
                    let C = Vec3((si.acceleration.x - sj.acceleration.x) * 0.5, (si.acceleration.y - sj.acceleration.y) * 0.5,
                                 (si.verticalAcceleration - sj.verticalAcceleration) * 0.5)
                    let d2 = 4 * P.ballRadius * P.ballRadius
                    if A.dot(A) <= d2 {
                        if A.dot(B) < 0 { consider(Candidate(time: now, rank: .ballBall, a: i, b: j)) }
                        continue
                    }
                    let poly = [A.dot(A) - d2, 2 * A.dot(B), B.dot(B) + 2 * A.dot(C), 2 * B.dot(C), C.dot(C)]
                    if let tau = RootFinder.firstDownCrossing(poly, limit: window) {
                        consider(Candidate(time: now + tau, rank: .ballBall, a: i, b: j))
                    }
                    continue
                }
                let A = pi.position - pj.position
                let B = pi.velocity - pj.velocity
                let C = (si.acceleration - sj.acceleration) * 0.5
                let d2 = 4 * P.ballRadius * P.ballRadius
                if A.dot(A) <= d2 {
                    if A.dot(B) < 0 { consider(Candidate(time: now, rank: .ballBall, a: i, b: j)) }
                    continue
                }
                let poly = quarticCoefficients(A, B, C, minus: d2)
                if let tau = RootFinder.firstDownCrossing(poly, limit: window) {
                    consider(Candidate(time: now + tau, rank: .ballBall, a: i, b: j))
                }
            }
        }
        return best
    }

    /// Contacts for a ball in the air (no horizontal acceleration, height h(t) = h + vz t - g t^2 / 2). Cushion,
    /// jaw, knuckle and hole contacts count only while the ball's lowest point is below the cushion nose. Above it,
    /// reaching a cushion's contact line means the ball sails over: into the pocket if it is over a hole, otherwise
    /// off the table. Times are exact roots, like every other event.
    private func airborneCandidates(_ i: Int, _ seg: BallSegment, _ s: BodyState) -> [Candidate] {
        var out: [Candidate] = []
        let window = seg.t1 - now
        let g = P.gravity, r = P.ballRadius
        func height(_ tau: Double) -> Double { s.height + s.vz * tau - 0.5 * g * tau * tau }
        func low(_ tau: Double) -> Bool { height(tau) < P.cushionNoseHeight }
        func at(_ tau: Double) -> Vec2 { s.position + s.velocity * tau }
        func overHole(_ p: Vec2) -> Int? {
            for (k, c) in pockets.enumerated() where (p - c).lengthSquared <= captureRadii[k] * captureRadii[k] { return k }
            return nil
        }
        // Holes: the ball drops in only while low enough to be inside the pocket.
        for (k, c) in pockets.enumerated() {
            let cr = captureRadii[k]
            let rel = s.position - c
            if rel.lengthSquared <= cr * cr {
                if low(0) { out.append(Candidate(time: now, rank: .pocket, a: i, b: k)) }
                continue
            }
            let poly = quarticCoefficients(rel, s.velocity, .zero, minus: cr * cr)
            if let tau = RootFinder.firstDownCrossing(poly, limit: window), low(tau) {
                out.append(Candidate(time: now + tau, rank: .pocket, a: i, b: k))
            }
        }
        // Cushion lines, over their full length: low and on a straight cushion is a rebound; low in a mouth is left
        // to the jaws and knuckles; high is over the cushion.
        for (w, wall) in walls.enumerated() {
            let poly = [wall.normal.dot(s.position) - wall.offset, wall.normal.dot(s.velocity)]
            var tau: Double?
            if poly[0] <= 0 {
                if poly[1] < 0 { tau = 0 }
            } else {
                tau = RootFinder.firstDownCrossing(poly, limit: window)
            }
            guard let tt = tau else { continue }
            let p = at(tt)
            if low(tt) {
                let along = wall.alongX ? p.x : p.y
                if wall.ranges.contains(where: { along >= $0.0 && along <= $0.1 }) {
                    out.append(Candidate(time: now + tt, rank: .cushion, a: i, b: w))
                }
            } else if let k = overHole(p) {
                out.append(Candidate(time: now + tt, rank: .pocket, a: i, b: k))
            } else {
                out.append(Candidate(time: now + tt, rank: .offTable, a: i, b: w))
            }
        }
        // Jaw faces and knuckles, as on the cloth, but only while the ball is below the nose.
        for (k, jaw) in jaws.enumerated() {
            let rel = s.position - jaw.start
            let poly = [jaw.normal.dot(rel) - r, jaw.normal.dot(s.velocity)]
            var tau: Double?
            if poly[0] <= 0 {
                if poly[1] < 0 { tau = 0 }
            } else {
                tau = RootFinder.firstDownCrossing(poly, limit: window)
            }
            guard let tt = tau, low(tt) else { continue }
            let p = at(tt)
            let along = (p - jaw.start).dot(jaw.direction)
            if along >= 0 && along <= jaw.length && (p - jaw.start).dot(jaw.normal) > -r {
                out.append(Candidate(time: now + tt, rank: .cushion, a: i, b: walls.count + k))
            }
        }
        for (k, knuckle) in knuckles.enumerated() {
            let rel = s.position - knuckle.point
            let r2 = r * r
            let index = walls.count + jaws.count + k
            if rel.lengthSquared <= r2 {
                if rel.dot(s.velocity) < 0 && low(0) { out.append(Candidate(time: now, rank: .cushion, a: i, b: index)) }
                continue
            }
            let poly = quarticCoefficients(rel, s.velocity, .zero, minus: r2)
            if let tau = RootFinder.firstDownCrossing(poly, limit: window), low(tau) {
                out.append(Candidate(time: now + tau, rank: .cushion, a: i, b: index))
            }
        }
        out += roundCandidates(i, s, acceleration: .zero, window: window, airborne: true)
        return out
    }

    /// Index of the first post in the cushion rank's numbering (walls, then jaws, then knuckles, then posts).
    private var firstPost: Int { walls.count + jaws.count + knuckles.count }

    /// Contacts with the round posts and the pins still standing: the ball's centre reaching ballRadius + radius from
    /// the feature's centre, an exact quartic root as for a knuckle. A ball in the air only meets a post or pin whose
    /// top is above the ball's lowest point at that moment (for one on the cloth that is any feature with a height).
    private func roundCandidates(_ i: Int, _ s: BodyState, acceleration a: Vec2, window: Double, airborne: Bool) -> [Candidate] {
        if posts.isEmpty && pins.isEmpty { return [] }
        var out: [Candidate] = []
        let g = P.gravity
        func below(_ top: Double, _ tau: Double) -> Bool {
            if !airborne { return top > 0 }
            return s.height + s.vz * tau - 0.5 * g * tau * tau < top
        }
        func contact(_ c: Vec2, _ radius: Double, _ top: Double, rank: EventRank, index: Int) {
            let rel = s.position - c
            let reach = P.ballRadius + radius
            let r2 = reach * reach
            if rel.lengthSquared <= r2 {
                // Already touching (rounding after the last contact): only an approaching ball counts.
                if rel.dot(s.velocity) < 0 && below(top, 0) { out.append(Candidate(time: now, rank: rank, a: i, b: index)) }
                return
            }
            let poly = quarticCoefficients(rel, s.velocity, a * 0.5, minus: r2)
            if let tau = RootFinder.firstDownCrossing(poly, limit: window), below(top, tau) {
                out.append(Candidate(time: now + tau, rank: rank, a: i, b: index))
            }
        }
        for (k, post) in posts.enumerated() { contact(post.center, post.radius, post.height, rank: .cushion, index: firstPost + k) }
        for (k, pin) in pins.enumerated() where !pinDown[k] { contact(pin.center, pin.radius, pin.height, rank: .pin, index: k) }
        return out
    }

    // MARK: Loop

    mutating func run() {
        var count = 0
        while count < PoolSolver.maxEvents {
            guard let c = nextEvent(), c.time <= PoolSolver.maxTime else { break }
            now = c.time
            switch c.rank {
            case .transition: applyTransition(c.a)
            case .pocket: applyPocket(c.a, c.b)
            case .cushion: applyCushion(c.a, c.b)
            case .ballBall: applyBallBall(c.a, c.b)
            case .offTable: applyOffTable(c.a, c.b)
            case .pin: applyPin(c.a, c.b)
            }
            count += 1
        }
    }

    private mutating func applyTransition(_ i: Int) {
        if bodies[i].segment.phase == .airborne { applyLanding(i); return }
        let old = bodies[i].segment
        let st = bodyState(i, at: now)
        let from = old.phase
        restart(i, at: now, with: st)
        let to = bodies[i].segment.phase
        let (tb, rb) = energy(st)
        let ib = ImpactBall(ball: i, velocityBefore: st.velocity, velocityAfter: st.velocity, omegaBefore: st.omega,
                            omegaAfter: bodyState(i, at: now).omega, translationalBefore: tb, rotationalBefore: rb,
                            translationalAfter: tb, rotationalAfter: energy(bodyState(i, at: now)).1)
        events.append(LensEvent(time: now, kind: .phaseTransition, point: st.position, normal: .zero,
                                balls: [ib], phaseFrom: from, phaseTo: to))
    }

    /// A ball in the air comes down on the slate at the exact landing time: another slate bounce. It either hops
    /// again (lower each time, by the restitution squared) or stays down and slides or rolls on.
    private mutating func applyLanding(_ i: Int) {
        var before = bodyState(i, at: now)
        before.height = 0                                    // exactly on the cloth (the root, not a rounded value)
        let (after, slate) = settleVertical(before)
        restart(i, at: now, with: after)
        let to = bodies[i].segment.phase
        events.append(LensEvent(time: now, kind: .phaseTransition, point: before.position, normal: .zero,
                                normalImpulse: slate?.normalImpulse ?? 0, frictionImpulse: slate?.frictionImpulse ?? 0,
                                slipSpeed: slate?.slipSpeed ?? 0, balls: [impactBall(i, before, after)],
                                phaseFrom: .airborne, phaseTo: to, flight: .landing,
                                verticalSpeedDown: before.vz < 0 ? -before.vz : 0, verticalSpeedUp: after.vz))
    }

    /// The ball sailed over a cushion: it leaves the table at this point. Like a pocketed ball it stops here (a final
    /// still segment where it went over, at that height) and is off the table for the next shot.
    private mutating func applyOffTable(_ i: Int, _ w: Int) {
        let st = bodyState(i, at: now)
        let (tb, rb) = energy(st)
        let ib = ImpactBall(ball: i, velocityBefore: st.velocity, velocityAfter: .zero, omegaBefore: st.omega,
                            omegaAfter: .zero, translationalBefore: tb, rotationalBefore: rb,
                            translationalAfter: 0, rotationalAfter: 0)
        events.append(LensEvent(time: now, kind: .phaseTransition, point: st.position, normal: walls[w].normal * -1,
                                balls: [ib], phaseFrom: .airborne, phaseTo: .stationary, flight: .offTable,
                                height: st.height))
        var old = bodies[i].segment
        old.t1 = now
        bodies[i].closed.append(old)
        bodies[i].active = false
        pocketTime[i] = now
        bodies[i].segment = BallSegment(t0: now, t1: .infinity, phase: .stationary, position0: st.position,
                                        velocity0: .zero, acceleration: .zero, omega0: .zero, alphaXY: .zero,
                                        spinDecay: P.spinDecay, radius: P.ballRadius,
                                        orientation0: old.orientation(at: now), height0: st.height)
    }

    private mutating func applyPocket(_ i: Int, _ k: Int) {
        let st = bodyState(i, at: now)
        let (tb, rb) = energy(st)
        let ib = ImpactBall(ball: i, velocityBefore: st.velocity, velocityAfter: .zero, omegaBefore: st.omega,
                            omegaAfter: .zero, translationalBefore: tb, rotationalBefore: rb,
                            translationalAfter: 0, rotationalAfter: 0)
        events.append(LensEvent(time: now, kind: .pocket, point: st.position, normal: (pockets[k] - st.position).normalized,
                                balls: [ib], pocket: pocketIndex[k]))
        var old = bodies[i].segment
        old.t1 = now
        bodies[i].closed.append(old)
        bodies[i].active = false
        pocketTime[i] = now
        // Keep a final stationary segment at the capture point so lookups stay valid. A ball taken in the air keeps
        // its height there, so playback does not snap it down to the cloth.
        if st.height > 0 {
            bodies[i].segment = BallSegment(t0: now, t1: .infinity, phase: .stationary, position0: st.position,
                                            velocity0: .zero, acceleration: .zero, omega0: .zero, alphaXY: .zero,
                                            spinDecay: P.spinDecay, radius: P.ballRadius,
                                            orientation0: old.orientation(at: now), height0: st.height)
        } else {
            bodies[i].segment = Self.makeSegment(P, t0: now, position: st.position, velocity: .zero, omega: .zero,
                                                 orientation: old.orientation(at: now))
        }
    }

    private mutating func applyCushion(_ i: Int, _ w: Int) {
        if w >= firstPost { applyPost(i, w - firstPost); return }
        if w >= walls.count + jaws.count { applyKnuckle(i, w - walls.count - jaws.count); return }
        if w >= walls.count { applyJaw(i, w - walls.count); return }
        let wall = walls[w]
        let before = bodyState(i, at: now)
        var res = Impacts.cushion(before, normal: wall.normal, P)
        // Put the ball exactly on its contact line so rounding cannot leave it inside the cushion.
        let pen = wall.offset - wall.normal.dot(res.states[0].position)
        if pen > 0 { res.states[0].position = res.states[0].position + wall.normal * pen }
        restart(i, at: now, with: res.states[0])
        events.append(LensEvent(time: now, kind: .cushion, point: before.position - wall.normal * P.ballRadius,
                                normal: wall.normal, normalImpulse: res.normalImpulse,
                                frictionImpulse: res.frictionImpulse, slipSpeed: res.slipSpeed,
                                balls: [impactBall(i, before, res.states[0])]))
    }

    private mutating func applyJaw(_ i: Int, _ k: Int) {
        let jaw = jaws[k]
        let before = bodyState(i, at: now)
        var res = Impacts.cushion(before, normal: jaw.normal, P)
        // Put the ball exactly one radius off the face so rounding cannot leave it inside the rubber.
        let pen = P.ballRadius - jaw.normal.dot(res.states[0].position - jaw.start)
        if pen > 0 { res.states[0].position = res.states[0].position + jaw.normal * pen }
        restart(i, at: now, with: res.states[0])
        events.append(LensEvent(time: now, kind: .cushion, point: before.position - jaw.normal * P.ballRadius,
                                normal: jaw.normal, normalImpulse: res.normalImpulse,
                                frictionImpulse: res.frictionImpulse, slipSpeed: res.slipSpeed,
                                balls: [impactBall(i, before, res.states[0])], pocket: jaw.pocket, edge: .jaw))
    }

    private mutating func applyKnuckle(_ i: Int, _ k: Int) {
        let knuckle = knuckles[k]
        let before = bodyState(i, at: now)
        // The knuckle pushes straight out from its point: the normal is the line from the point to the ball's centre.
        let n = (before.position - knuckle.point).normalized
        var res = Impacts.cushion(before, normal: n, P)
        let dist = (res.states[0].position - knuckle.point).length
        if dist < P.ballRadius { res.states[0].position = knuckle.point + n * P.ballRadius }
        restart(i, at: now, with: res.states[0])
        events.append(LensEvent(time: now, kind: .cushion, point: knuckle.point, normal: n,
                                normalImpulse: res.normalImpulse, frictionImpulse: res.frictionImpulse,
                                slipSpeed: res.slipSpeed, balls: [impactBall(i, before, res.states[0])],
                                pocket: knuckle.pocket, edge: .knuckle))
    }

    /// A fixed round post: the knuckle's response (the normal runs from the post's centre to the ball's), but with the
    /// post's own restitution and friction in place of the cushion's.
    private mutating func applyPost(_ i: Int, _ k: Int) {
        let post = posts[k]
        let before = bodyState(i, at: now)
        let n = (before.position - post.center).normalized
        var q = P
        q.cushionRestitution = post.restitution
        q.cushionFriction = post.friction
        var res = Impacts.cushion(before, normal: n, q)
        let reach = P.ballRadius + post.radius
        if (res.states[0].position - post.center).length < reach { res.states[0].position = post.center + n * reach }
        restart(i, at: now, with: res.states[0])
        events.append(LensEvent(time: now, kind: .cushion, point: post.center + n * post.radius, normal: n,
                                normalImpulse: res.normalImpulse, frictionImpulse: res.frictionImpulse,
                                slipSpeed: res.slipSpeed, balls: [impactBall(i, before, res.states[0])],
                                edge: .post, feature: k))
    }

    /// A ball touches a standing pin and knocks it down. The pin is a free body at rest with its own (small) mass:
    /// along the line of centres the ball loses (1 + e) * v_n * m_pin / (m + m_pin), the ball-ball impulse for unequal
    /// masses; nothing else about the ball changes (no friction with a falling pin). The pin is then out of play.
    private mutating func applyPin(_ i: Int, _ k: Int) {
        let pin = pins[k]
        let before = bodyState(i, at: now)
        let n = (pin.center - before.position).normalized
        let vn = before.velocity.dot(n)
        let m = P.ballMass, mp = pin.mass
        let jn = vn > 0 ? (1 + pin.restitution) * vn * m * mp / (m + mp) : 0
        var after = before
        after.velocity = before.velocity - n * (jn / m)
        pinDown[k] = true
        restart(i, at: now, with: after)
        events.append(LensEvent(time: now, kind: .pinDown, point: pin.center, normal: n, normalImpulse: jn,
                                balls: [impactBall(i, before, after)], height: before.height, feature: k))
    }

    private mutating func applyBallBall(_ i: Int, _ j: Int) {
        if isAirborne(i) || isAirborne(j) { applyBallBall3D(i, j); return }
        let a = bodyState(i, at: now), b = bodyState(j, at: now)
        var res = Impacts.ballBall(a, b, P)
        // Nudge apart by a tiny fixed amount if rounding left them closer than two radii.
        let n = (b.position - a.position).normalized
        let dist = (b.position - a.position).length
        let gap = 2 * P.ballRadius * (1 + 1e-12) - dist
        if gap > 0 {
            res.states[0].position = res.states[0].position - n * (gap * 0.5)
            res.states[1].position = res.states[1].position + n * (gap * 0.5)
        }
        restart(i, at: now, with: res.states[0])
        restart(j, at: now, with: res.states[1])
        let mid = (a.position + b.position) * 0.5
        events.append(LensEvent(time: now, kind: .ballBall, point: mid, normal: n, normalImpulse: res.normalImpulse,
                                frictionImpulse: res.frictionImpulse, slipSpeed: res.slipSpeed,
                                balls: [impactBall(i, a, res.states[0]), impactBall(j, b, res.states[1])]))
    }

    /// Ball against ball with at least one in the air: the 3D impact, then each ball's vertical is settled (a ball on
    /// the cloth pushed down bounces off the slate and may hop; one in the air keeps flying). A ball that leaves the
    /// cloth here gets its own take-off event after the contact.
    private mutating func applyBallBall3D(_ i: Int, _ j: Int) {
        let a = bodyState(i, at: now), b = bodyState(j, at: now)
        let wasAir = [isAirborne(i), isAirborne(j)]
        let oldPhase = [bodies[i].segment.phase, bodies[j].segment.phase]
        var res = Impacts.ballBall3D(a, b, P)
        let d = Vec3(b.position.x - a.position.x, b.position.y - a.position.y, b.height - a.height)
        let dist = d.length
        let n = dist > 1e-300 ? d * (1 / dist) : Vec3(1, 0, 0)
        // Nudge apart by a tiny fixed amount if rounding left them closer than two radii. Heights never go below the
        // cloth; a ball on the cloth only moves sideways.
        let gap = 2 * P.ballRadius * (1 + 1e-12) - dist
        if gap > 0 {
            for (k, sign) in [(0, -1.0), (1, 1.0)] {
                let push = n * (sign * gap * 0.5)
                res.states[k].position = res.states[k].position + Vec2(push.x, push.y)
                let h = res.states[k].height + push.z
                res.states[k].height = h > 0 ? h : 0
            }
        }
        var settled: [BodyState] = []
        var slates: [ImpactResult?] = []
        for k in 0..<2 {
            let (st, slate) = settleVertical(res.states[k])
            settled.append(st); slates.append(slate)
        }
        restart(i, at: now, with: settled[0])
        restart(j, at: now, with: settled[1])
        let mid = (a.position + b.position) * 0.5
        let flat = Vec2(n.x, n.y).normalized
        events.append(LensEvent(time: now, kind: .ballBall, point: mid, normal: flat, normalImpulse: res.normalImpulse,
                                frictionImpulse: res.frictionImpulse, slipSpeed: res.slipSpeed,
                                balls: [impactBall(i, a, settled[0]), impactBall(j, b, settled[1])],
                                height: a.height > b.height ? a.height : b.height))
        for (k, ball) in [i, j].enumerated() where !wasAir[k] && isAirborne(ball) {
            let st = settled[k]
            events.append(LensEvent(time: now, kind: .phaseTransition, point: st.position, normal: .zero,
                                    normalImpulse: slates[k]?.normalImpulse ?? 0,
                                    frictionImpulse: slates[k]?.frictionImpulse ?? 0,
                                    balls: [impactBall(ball, res.states[k], st)], phaseFrom: oldPhase[k], phaseTo: .airborne,
                                    flight: .takeOff, verticalSpeedDown: res.states[k].vz < 0 ? -res.states[k].vz : 0,
                                    verticalSpeedUp: st.vz))
        }
    }

    // MARK: Output

    func timeline() -> Timeline {
        var segs: [[BallSegment]] = []
        for b in bodies { segs.append(b.closed + [b.segment]) }
        return Timeline(table: P.tableSpec, seed: input.seed, parameterHash: P.hash, segments: segs, events: events,
                        pocketTime: pocketTime, duration: events.last?.time ?? 0)
    }
}
