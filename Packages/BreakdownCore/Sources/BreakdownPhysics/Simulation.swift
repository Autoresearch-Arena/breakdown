// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (real pocket mouths: the straight cushions stop at the knuckles,
//          and two new contact kinds join the cushion rank: a jaw face (a straight segment, contact when the ball's
//          centre is one radius off it and inside the segment's length) and a knuckle (a point, contact when the centre
//          is one radius from it, an exact quartic root like every other event). Both reuse Impacts.cushion with
//          the face's own normal, so a ball that clips the mouth rebounds and can rattle between the jaws.)
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

private enum EventRank: Int { case transition = 0, pocket = 1, cushion = 2, ballBall = 3 }

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
    let pockets: [Vec2]
    let captureRadii: [Double]

    init(input: ShotInput) {
        self.input = input
        P = input.parameters
        pockets = P.pocketCenters
        captureRadii = P.pocketCaptureRadii
        pocketTime = [Double?](repeating: nil, count: input.positions.count)
        let r = P.ballRadius, L = P.tableLength, W = P.tableWidth
        // The straight cushion noses run between knuckles. Past a knuckle the ball meets the knuckle or the jaw.
        let a = P.cornerKnuckleOffset, h = P.sideMouth * 0.5
        walls = [
            Wall(normal: Vec2(1, 0), offset: r, alongX: false, ranges: [(a, W - a)]),
            Wall(normal: Vec2(-1, 0), offset: -(L - r), alongX: false, ranges: [(a, W - a)]),
            Wall(normal: Vec2(0, 1), offset: r, alongX: true, ranges: [(a, L * 0.5 - h), (L * 0.5 + h, L - a)]),
            Wall(normal: Vec2(0, -1), offset: -(W - r), alongX: true, ranges: [(a, L * 0.5 - h), (L * 0.5 + h, L - a)]),
        ]
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
    static func makeSegment(_ P: PoolParameters, t0: Double, position: Vec2, velocity: Vec2, omega: Vec3,
                            orientation: Quat) -> BallSegment {
        let R = P.ballRadius, mu = P.slidingFriction, g = P.gravity
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
        (0.5 * P.ballMass * k.velocity.lengthSquared, 0.5 * P.inertia * k.omega.lengthSquared)
    }

    private func impactBall(_ ball: Int, _ before: BodyState, _ after: BodyState) -> ImpactBall {
        let (tb, rb) = energy(before), (ta, ra) = energy(after)
        return ImpactBall(ball: ball, velocityBefore: before.velocity, velocityAfter: after.velocity,
                          omegaBefore: before.omega, omegaAfter: after.omega,
                          translationalBefore: tb, rotationalBefore: rb, translationalAfter: ta, rotationalAfter: ra)
    }

    private func bodyState(_ i: Int, at t: Double) -> BodyState {
        let k = bodies[i].segment.kinematics(at: t)
        return BodyState(position: k.position, velocity: k.velocity, omega: k.omega)
    }

    /// Close the ball's current segment at `t` and start a new one from `state`.
    private mutating func restart(_ i: Int, at t: Double, with state: BodyState) {
        var old = bodies[i].segment
        let q = old.orientation(at: t)
        old.t1 = t
        bodies[i].closed.append(old)
        bodies[i].segment = Self.makeSegment(P, t0: t, position: state.position, velocity: state.velocity,
                                             omega: state.omega, orientation: q)
    }

    // MARK: Cue strike

    private mutating func applyStrike() {
        let s = input.strike
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
            }
            count += 1
        }
    }

    private mutating func applyTransition(_ i: Int) {
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

    private mutating func applyPocket(_ i: Int, _ k: Int) {
        let st = bodyState(i, at: now)
        let (tb, rb) = energy(st)
        let ib = ImpactBall(ball: i, velocityBefore: st.velocity, velocityAfter: .zero, omegaBefore: st.omega,
                            omegaAfter: .zero, translationalBefore: tb, rotationalBefore: rb,
                            translationalAfter: 0, rotationalAfter: 0)
        events.append(LensEvent(time: now, kind: .pocket, point: st.position, normal: (pockets[k] - st.position).normalized,
                                balls: [ib], pocket: k))
        var old = bodies[i].segment
        old.t1 = now
        bodies[i].closed.append(old)
        bodies[i].active = false
        pocketTime[i] = now
        // Keep a final stationary segment at the capture point so lookups stay valid.
        bodies[i].segment = Self.makeSegment(P, t0: now, position: st.position, velocity: .zero, omega: .zero,
                                             orientation: old.orientation(at: now))
    }

    private mutating func applyCushion(_ i: Int, _ w: Int) {
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

    private mutating func applyBallBall(_ i: Int, _ j: Int) {
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

    // MARK: Output

    func timeline() -> Timeline {
        var segs: [[BallSegment]] = []
        for b in bodies { segs.append(b.closed + [b.segment]) }
        return Timeline(table: P.tableSpec, seed: input.seed, parameterHash: P.hash, segments: segs, events: events,
                        pocketTime: pocketTime, duration: events.last?.time ?? 0)
    }
}
