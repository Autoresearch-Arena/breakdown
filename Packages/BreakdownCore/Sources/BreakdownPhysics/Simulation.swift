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
// Edited: Claude Opus 5.5 Medium, 21-November-2026 (simulate(_:eventBudget:): the same solve with a smaller event
//          limit that returns nil when the limit is used up, for callers that solve many variations of a shot. The
//          normal solve is unchanged.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the physics switch: the generation rule below. No solver behaviour
//          changes in this edit.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (generation two built, and the jam guard at every generation.
//          JAM GUARD (pockets-and-jams plan part B, spec 3.5 "Zeno guards"): every impact gentler than stormSpeed is
//          counted per ball inside a one-millisecond window; a ball past stormImpacts in one window is in a storm of
//          tiny bounces, and it and every touching ball that took part are brought to rest touching, with one
//          settledInContact event carrying the energy removed. The hard event limit drops from 60,000 to 10,000, and
//          reaching it is logged and stops what is still moving instead of leaving a cut-off recording.
//          The strike now hits CueStrike.ballIndex (every generation; 0 is ball 0 exactly as before).
//          GENERATION TWO only: the cue strike (cueLaunch: slower off-centre hits, side-spin deflection, miscues;
//          launchDirection for the aim guide); the Level A rail (Impacts.rail) on rails, jaws and knuckles, at the
//          contact distance R * cos(tilt), posts keeping the flat model; pockets that can refuse a ball (the
//          fall-across-the-hole test, the back wall of edge pockets, rim-skip events, entry speed and angle on every
//          pocket event), and a ball resting over a hole drops.)
//
// THE GENERATION RULE (plans/21-Nov-2026-physics-proof-plan.md, package 1). PoolParameters.modelGeneration picks the
// physics model. Generation 1 is this solver exactly as it was on 21 November 2026, and every trick shot and Behind
// the 8-Ball puzzle was authored on it. So EVERY physics change (rails, cue strike, pockets, anything later) must:
//   1. check P.modelGeneration (or P.usesGenerationTwo) and take the old code path, line for line, at generation 1;
//   2. leave generation-1 events, segments and their order bit for bit as they were (the new LensEvent fields stay nil
//      or at their defaults at generation 1, because Timeline.contentHash folds them in whenever they are set);
//   3. keep JumpTests.testLevelStrikesAreBitForBitUnchanged and PhysicsSwitchTests passing unchanged.
// The only change allowed at every generation is the jam guard (pockets-and-jams plan, part B), because it only
// alters shots that today run into the event limit; its tests must show no normal shot changes.
//
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
/// pin (21-Nov-2026) is newer still and comes after offTable for the same reason. rimSkip (generation two: a ball
/// leaving a hole it crossed too fast to fall into) is newest and last, so no older ordering changes.
private enum EventRank: Int { case transition = 0, pocket = 1, cushion = 2, ballBall = 3, offTable = 4, pin = 5, rimSkip = 6 }

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

/// What a solve cost and whether a guard stepped in (BreakProbe's jam sweep reads it; the app does not need it).
public struct SolveReport: Sendable, Equatable {
    /// Events the loop applied (a hole crossing decided without a drop counts, though it records no event).
    public let events: Int
    /// How many storms the jam guard brought to rest (one settledInContact event each).
    public let jamsSettled: Int
    /// True when the solve reached PoolSolver.maxEvents: logged, and everything still moving was stopped where it was.
    public let hitEventLimit: Bool
}

public enum PoolSolver {
    /// Largest number of events before the loop gives up. With the jam guard in place no real shot comes near it:
    /// ordinary shots take tens of events and a full break a few hundred (EightBallJudge measured escapes at 10 to 60),
    /// and the jam guard settles a storm within a few hundred more (pockets-and-jams plan: every jam fixture under two
    /// thousand). Ten thousand is five times that two-thousand promise, so reaching it means something new is wrong;
    /// it is logged and the shot is stopped (see haltAtLimit) rather than spinning for seconds as 60,000 did. It also
    /// stays well above the eight-ball judge's 2,000-event sweep budget, which simulate(_:eventBudget:) clamps to it.
    static let maxEvents = 10_000
    static let maxTime = 90.0

    // The jam guard's numbers (spec 3.5 "cap events per ball per millisecond"; pockets-and-jams plan part B). They are
    // solver constants, not parameters: they decide nothing in a real shot, only when a storm is cut short, so they do
    // not belong in the hashed physics numbers.
    /// The window, seconds of game time: the spec's millisecond.
    static let stormWindow = 0.001
    /// Only impacts gentler than this count toward a storm, metres per second of approach (the normal speed into the
    /// other ball, the rubber or the slate). A ball at 5 mm/s moves 5 micrometres in the window, far below anything
    /// a player can see, while every impact that matters to a shot (a break, a kiss, a rail) is hundreds of times
    /// faster. This keeps the rack's micrometre-gap cascade, whose contacts run at metres per second, from ever
    /// counting, so the guard cannot touch a normal shot.
    static let stormSpeed = 0.005
    /// More gentle impacts than this on one ball inside one window is a storm. Normal shots take 10 to 60 events in
    /// TOTAL (EightBallJudge's measurement), so two hundred gentle impacts on one ball in a single millisecond cannot
    /// happen in one; a chatter, whose gaps shrink geometrically (each rebound keeps 0.95 of the approach speed), passes
    /// it within a few hundred events, which keeps every jam inside the plan's two-thousand-event promise.
    static let stormImpacts = 200

    public static func simulate(_ input: ShotInput) -> Timeline {
        simulateWithReport(input).timeline
    }

    /// The same solve plus what it cost. A solve that reaches maxEvents prints one line (the log the spec asks for)
    /// and stops every ball still moving where it is, so the recording still ends at rest.
    public static func simulateWithReport(_ input: ShotInput) -> (timeline: Timeline, report: SolveReport) {
        var sim = Simulation(input: input)
        let finished = sim.run()
        if !finished {
            sim.haltAtLimit()
            print("PoolSolver: event limit \(maxEvents) reached at t = \(sim.now) s (seed \(input.seed)); stopped the balls still moving")
        }
        return (sim.timeline(), SolveReport(events: sim.eventsUsed, jamsSettled: sim.jamsSettled, hitEventLimit: !finished))
    }

    /// The same solve with a smaller event budget, for callers that solve many variations of a shot and only need
    /// its outcome (the Behind the 8-Ball judge's window sweep). Nil when the budget ran out first. A solve that
    /// finishes within the budget is exactly the one simulate(_:) returns.
    public static func simulate(_ input: ShotInput, eventBudget: Int) -> Timeline? {
        var sim = Simulation(input: input)
        return sim.run(limit: min(eventBudget, maxEvents)) ? sim.timeline() : nil
    }

    // MARK: The cue strike, generation two (plans/21-Nov-2026-cue-strike-plan.md, spec 3.3)

    /// What the cue really gives the ball.
    struct CueLaunch: Equatable {
        /// Unit direction of travel in the table plane (the aim, turned by side spin or by a miscue).
        var direction: Vec2
        /// Launch speed along the cue's line (for a raised cue, before the slate takes its vertical part).
        var speed: Double
        /// The offsets the spin is made from: the struck ones, or for a miscue the point on the tip's grip limit where
        /// the tip slid off.
        var tipUp: Double
        var tipSide: Double
        var miscue: Bool
        /// Sine of the turn from the aim, counter-clockwise positive (LensEvent.deflectionSine).
        var deflectionSine: Double
    }

    /// The tangent of the side-spin deflection ("squirt") for a side offset `tipSide` (metres, right positive), as a
    /// signed sideways-over-forward ratio: positive turns the ball to the LEFT of the aim, which is what a hit on the
    /// right side does (the ball is pushed away from the struck side). Spec 3.3 and PoolParameters.shaftEndMass:
    /// tan = 5/2 x sqrt(1 - x^2) / (1 + m / Me + 5/2 x^2), x = tipSide / R. Top and bottom offsets do not deflect.
    static func squirtTangent(tipSide: Double, _ p: PoolParameters) -> Double {
        var x = tipSide / p.ballRadius
        if x > 1 { x = 1 }
        if x < -1 { x = -1 }
        return 2.5 * x * (1 - x * x).squareRoot() / (1 + p.ballMass / p.shaftEndMass + 2.5 * x * x)
    }

    /// The aim `d` turned by a sideways-over-forward ratio `t` (positive: counter-clockwise), renormalised with a square
    /// root, no trigonometry. Returns the new unit direction and the sine of the turn.
    static func turned(_ d: Vec2, by t: Double) -> (direction: Vec2, sine: Double) {
        let norm = (1 + t * t).squareRoot()
        return ((d + d.perp * t) * (1 / norm), t / norm)
    }

    /// The one place a CueStrike becomes a launch at generation 2 (both strike functions call it). With `seed` nil it
    /// gives the miscue no random turn, which is what the aim guide wants (it cannot know a slip's direction).
    /// - Speed: a centre hit launches at strike.speed; an off-centre one at
    ///   strike.speed * (M + m) / (M + m + 5/2 M b^2 / R^2), b^2 = tipUp^2 + tipSide^2 (spec 3.3's strike formula
    ///   divided by its centre-hit value, so "speed" keeps meaning the centre-hit launch speed).
    /// - Direction: turned away from the struck side by squirtTangent; only the side offset deflects.
    /// - Miscue: an offset past PoolParameters.miscueOffsetLimit slips. The ball leaves at miscueSpeedFraction of the
    ///   centre-hit speed, turned by a seeded random ratio within +-miscueMaxDeflection (the shot's own seed through the
    ///   seeded generator, mixed with a fixed word so it is not the rack's jitter stream), and the spin is what the tip
    ///   could still give at the grip limit it slid from: the offsets scaled back onto the limit, at the reduced speed.
    static func cueLaunch(_ strike: CueStrike, _ p: PoolParameters, seed: UInt64?) -> CueLaunch {
        let r2 = p.ballRadius * p.ballRadius
        let offset2 = strike.tipUp * strike.tipUp + strike.tipSide * strike.tipSide
        let limit = p.miscueOffsetLimit
        if offset2 > limit * limit {
            let back = (limit * limit / offset2).squareRoot()
            var t = 0.0
            if let seed {
                var rng = SeededGenerator(seed: seed ^ 0x4D49_5343_5545)     // "MISCUE"
                t = rng.signedUnit() * p.miscueMaxDeflection
            }
            let turn = turned(strike.direction, by: t)
            return CueLaunch(direction: turn.direction, speed: strike.speed * p.miscueSpeedFraction,
                             tipUp: strike.tipUp * back, tipSide: strike.tipSide * back, miscue: true,
                             deflectionSine: turn.sine)
        }
        let big = p.cueMass + p.ballMass
        let factor = big / (big + 2.5 * p.cueMass * offset2 / r2)
        let turn = turned(strike.direction, by: squirtTangent(tipSide: strike.tipSide, p))
        return CueLaunch(direction: turn.direction, speed: strike.speed * factor, tipUp: strike.tipUp,
                         tipSide: strike.tipSide, miscue: false, deflectionSine: turn.sine)
    }

    /// The direction the struck ball really leaves in, for the aim guide (so the drawn line bends with side spin the
    /// way the ball will). At generation 1 it is the aim itself. At generation 2 it is the aim turned by side spin; a
    /// miscue's random turn cannot be known before the shot, so for an offset past the grip limit it is the aim.
    /// Pure: the same function the solver uses, with no randomness.
    public static func launchDirection(for strike: CueStrike, parameters p: PoolParameters) -> Vec2 {
        guard p.usesGenerationTwo else { return strike.direction }
        return cueLaunch(strike, p, seed: nil).direction
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
    /// How far a ball's centre is from a rail nose, jaw face or knuckle when they touch: R at generation 1, R * cos(tilt)
    /// at generation 2 (PoolParameters.railContactDistance). Posts keep R + their radius at every generation.
    let railContact: Double
    /// Generation two, edge pockets only (indexed like `pockets`; nil for a bed hole): the middle of the mouth (between
    /// the pocket's two knuckles) and the unit normal of the mouth line pointing into the table. The pocket's centre
    /// line runs the other way, into the pocket; a ball whose path across the hole ends beyond the mouth line meets
    /// the pocket's back and always drops.
    let mouths: [(mid: Vec2, inward: Vec2)?]
    /// Generation two: a ball crossing a hole it is too fast to fall into. `exited` false while it is still over the
    /// hole (its rim-skip event comes when it leaves), true after; the hole is then ignored for that ball until an event
    /// finds it outside the hole's circle. Always nil at generation 1.
    struct HoleSkip { var hole: Int; var exited: Bool }
    var skip: [HoleSkip?]
    /// How the crossing ball came in, recorded on its rim-skip event.
    var skipEntry: [PocketEntry?]
    /// The jam guard (every generation): per ball, the start of its current one-millisecond window and how many gentle
    /// impacts it has taken in it; a ball that passed PoolSolver.stormImpacts waits here to be settled.
    var stormStart: [Double]
    var stormCount: [Int]
    var stormBall: Int?
    var jamsSettled = 0
    var eventsUsed = 0

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
        let count = input.positions.count
        skip = [HoleSkip?](repeating: nil, count: count)
        skipEntry = [PocketEntry?](repeating: nil, count: count)
        stormStart = [Double](repeating: -1, count: count)
        stormCount = [Int](repeating: 0, count: count)
        railContact = P.railContactDistance
        // The mouth of each edge pocket, from its two knuckles (the start of its two jaws).
        var mouthList: [(mid: Vec2, inward: Vec2)?] = []
        let middle = Vec2(P.tableLength * 0.5, P.tableWidth * 0.5)
        for k in 0..<pockets.count {
            let knuckleStarts = P.jaws.filter { $0.pocket == k }.map(\.start)
            guard k < edge.count, knuckleStarts.count == 2 else { mouthList.append(nil); continue }
            let mid = (knuckleStarts[0] + knuckleStarts[1]) * 0.5
            var inward = (knuckleStarts[1] - knuckleStarts[0]).normalized.perp
            if inward.dot(middle - mid) < 0 { inward = inward * -1 }
            mouthList.append((mid, inward))
        }
        mouths = mouthList
        let r = railContact, L = P.tableLength, W = P.tableWidth
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

    /// Close the ball's current segment at `t` and start a new one from `state`. Generation 2: a ball that skipped a
    /// hole is free to meet that hole again once an event finds it outside the hole's circle.
    private mutating func restart(_ i: Int, at t: Double, with state: BodyState) {
        if let mark = skip[i], mark.exited {
            let rel = state.position - pockets[mark.hole]
            if rel.lengthSquared > captureRadii[mark.hole] * captureRadii[mark.hole] { skip[i] = nil }
        }
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

    /// The ball the cue strikes: CueStrike.ballIndex, or ball 0 if that names no ball in this shot (a caller's slip
    /// should not crash a solve). With the default 0 every line below is the old one.
    private var struckBall: Int {
        let b = input.strike.ballIndex
        return b >= 0 && b < bodies.count ? b : 0
    }

    private mutating func applyStrike() {
        let s = input.strike
        if s.elevation > 0 { applyRaisedStrike(); return }
        let ball = struckBall
        let d = s.direction
        // Generation 1: the old lines exactly (full speed, straight along the cue, no flags on the event). Generation 2:
        // the same spin formula, but with the launch the cue really gives (PoolSolver.cueLaunch): slower off centre,
        // turned by side spin, or a miscue. The spin is made in the cue's frame (d), the velocity goes along the launch.
        let launch: PoolSolver.CueLaunch? = P.usesGenerationTwo ? PoolSolver.cueLaunch(s, P, seed: input.seed) : nil
        let speed = launch?.speed ?? s.speed
        let tipUp = launch?.tipUp ?? s.tipUp, tipSide = launch?.tipSide ?? s.tipSide
        let k = 2.5 * speed / (P.ballRadius * P.ballRadius)         // m * speed / I
        // Contact offsets: up (a) lifts spin about the axis perpendicular to d, side (b) spins about vertical.
        let omega = Vec3(-d.y * k * tipUp, d.x * k * tipUp, k * tipSide)
        let before = BodyState(position: input.positions[ball], velocity: .zero, omega: .zero)
        let after = BodyState(position: input.positions[ball], velocity: (launch?.direction ?? d) * speed, omega: omega)
        bodies[ball].segment = Self.makeSegment(P, t0: 0, position: after.position, velocity: after.velocity,
                                                omega: after.omega, orientation: .identity)
        events.append(LensEvent(time: 0, kind: .cueStrike, point: after.position, normal: d,
                                normalImpulse: P.ballMass * speed, balls: [impactBall(ball, before, after)],
                                miscue: launch?.miscue, deflectionSine: launch?.deflectionSine))
    }

    /// A strike with the cue raised. The cue runs along c = (cos e * d, -sin e); the impulse m * speed acts along c
    /// through the tip's contact point, offset `tipSide` to the right (s) and `tipUp` along the cue's own up (u, which
    /// leans back with the cue). The spin is (r x c) * m * speed / I = k * (tipSide * u - tipUp * s): raising the cue
    /// tilts the side-spin axis toward the line of travel, which is what bends a masse. The downward part drives the
    /// ball into the slate at once, and the slate bounce (with friction) decides whether it leaves the cloth.
    /// At generation 2 the same launch as a level hit (PoolSolver.cueLaunch: the offsets are measured across the cue,
    /// so the speed factor and the miscue rule are the same), its turn applied in the table plane only: the horizontal
    /// part of the launch goes along the turned direction, the vertical part is unchanged, and the spin is made in the
    /// cue's own frame.
    private mutating func applyRaisedStrike() {
        let s = input.strike
        let ball = struckBall
        let d = s.direction
        let e = s.elevation
        let launch: PoolSolver.CueLaunch? = P.usesGenerationTwo ? PoolSolver.cueLaunch(s, P, seed: input.seed) : nil
        let speed = launch?.speed ?? s.speed
        let tipUp = launch?.tipUp ?? s.tipUp, tipSide = launch?.tipSide ?? s.tipSide
        let c = (1 - e * e).squareRoot()                             // cosine of the elevation
        let k = 2.5 * speed / (P.ballRadius * P.ballRadius)         // m * speed / I
        let right = Vec3(d.y, -d.x, 0)
        let up = Vec3(e * d.x, e * d.y, c)
        let omega = (up * tipSide - right * tipUp) * k
        let before = BodyState(position: input.positions[ball], velocity: .zero, omega: .zero)
        let struck = BodyState(position: input.positions[ball], velocity: (launch?.direction ?? d) * (speed * c),
                               omega: omega, height: 0, vz: -speed * e)
        let (after, slate) = settleVertical(struck)
        bodies[ball].segment = Self.makeSegment(P, t0: 0, position: after.position, velocity: after.velocity,
                                                omega: after.omega, orientation: .identity, height: after.height,
                                                vz: after.vz)
        events.append(LensEvent(time: 0, kind: .cueStrike, point: after.position, normal: d,
                                normalImpulse: P.ballMass * speed, balls: [impactBall(ball, before, after)],
                                miscue: launch?.miscue, deflectionSine: launch?.deflectionSine))
        if let slate, after.vz > 0 {
            events.append(LensEvent(time: 0, kind: .phaseTransition, point: after.position, normal: .zero,
                                    normalImpulse: slate.normalImpulse, frictionImpulse: slate.frictionImpulse,
                                    slipSpeed: slate.slipSpeed, balls: [impactBall(ball, struck, after)],
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
            if seg.phase == .stationary || seg.phase == .spinning {
                // Generation 2: a ball that comes to rest over a hole (it was crossing and something stopped it there,
                // or the jam guard settled it there) falls in. At generation 1 a moving ball never reaches a hole
                // without dropping, so the old rule (a still ball is never tested) is kept exactly.
                if P.usesGenerationTwo {
                    for (k, c) in pockets.enumerated() where skip[i].map({ !($0.hole == k && $0.exited) }) ?? true {
                        if (s.position - c).lengthSquared <= captureRadii[k] * captureRadii[k] {
                            consider(Candidate(time: now, rank: .pocket, a: i, b: k))
                            break
                        }
                    }
                }
                continue
            }
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
                if let mark = skip[i], mark.hole == k {
                    // Generation 2 only (the marker is never set at generation 1). After the rim skip the hole is
                    // ignored until the ball is seen outside it. While it is still crossing, the event is the moment
                    // its centre leaves the circle: an up-crossing of |rel|^2 - r^2, so the root finder is given the
                    // negated polynomial. Right at the entry the value is zero (or a rounding hair either side), so the
                    // factor t is divided out and the exit is where the rest of the polynomial turns positive.
                    if mark.exited { continue }
                    let poly = quarticCoefficients(rel, s.velocity, a * 0.5, minus: r * r)
                    var tau: Double?
                    if poly[0] < 0 {
                        tau = RootFinder.firstDownCrossing(poly.map { -$0 }, limit: window)
                    } else if poly[1] < 0 {
                        tau = RootFinder.firstDownCrossing(poly.dropFirst().map { -$0 }, limit: window)
                    } else {
                        tau = 0                                  // on the rim and already moving out
                    }
                    if let tau { consider(Candidate(time: now + tau, rank: .rimSkip, a: i, b: k)) }
                    continue
                }
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
                let poly = [jaw.normal.dot(rel) - railContact, jaw.normal.dot(s.velocity), 0.5 * jaw.normal.dot(a)]
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
            // Knuckles: a ball's centre may not come closer than one radius (generation 2: the rail contact distance,
            // the knuckle being the end of the same nose) to the point where nose meets jaw.
            for (k, knuckle) in knuckles.enumerated() {
                let rel = s.position - knuckle.point
                let r2 = railContact * railContact
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
            let poly = [jaw.normal.dot(rel) - railContact, jaw.normal.dot(s.velocity)]
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
            let r2 = railContact * railContact
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

    /// Runs the event loop. Returns false when it stopped because `limit` events were used up (a cut-off shot),
    /// true when the shot settled or reached maxTime.
    @discardableResult
    mutating func run(limit: Int = PoolSolver.maxEvents) -> Bool {
        while eventsUsed < limit {
            guard let c = nextEvent(), c.time <= PoolSolver.maxTime else { return true }
            now = c.time
            switch c.rank {
            case .transition: applyTransition(c.a)
            case .pocket: applyPocket(c.a, c.b)
            case .cushion: applyCushion(c.a, c.b)
            case .ballBall: applyBallBall(c.a, c.b)
            case .offTable: applyOffTable(c.a, c.b)
            case .pin: applyPin(c.a, c.b)
            case .rimSkip: applyRimSkip(c.a, c.b)
            }
            eventsUsed += 1
            // The jam guard: an impact just pushed a ball past the storm count, so settle its group now (one more event).
            if let storm = stormBall {
                stormBall = nil
                settleJam(around: storm)
                eventsUsed += 1
            }
        }
        return false
    }

    // MARK: The jam guard (every generation; pockets-and-jams plan part B, spec 3.5)

    /// Count an impact on ball `i` whose approach speed was `approach` (m/s). Only gentle ones count (stormSpeed); a ball
    /// past stormImpacts of them inside one stormWindow is flagged for settleJam. Counting changes nothing in the shot,
    /// so a shot that never storms records exactly what it did before the guard existed.
    private mutating func noteImpact(_ i: Int, approach: Double) {
        if approach >= PoolSolver.stormSpeed { return }
        if stormCount[i] == 0 || now - stormStart[i] > PoolSolver.stormWindow {
            stormStart[i] = now
            stormCount[i] = 0
        }
        stormCount[i] += 1
        if stormCount[i] > PoolSolver.stormImpacts { stormBall = i }
    }

    /// True when ball `j` took a gentle impact inside its current window (so it is part of whatever storm it touches).
    private func inStorm(_ j: Int) -> Bool {
        stormCount[j] > 0 && now - stormStart[j] <= PoolSolver.stormWindow
    }

    /// Bring a storm to rest. The group is the storm ball plus every ball touching it (centres within 2R plus ten
    /// micrometres: chattering balls sit nanometres to micrometres apart, while resting rack neighbours, a micrometre
    /// apart, only join if they are chattering too) that is itself in the storm, and so on through the touching chain.
    /// Every ball in the group stops: no velocity, no vertical motion, spin about the vertical axis kept (it moves
    /// nothing and fades on its own). Positions are then fixed up so no ball overlaps another or sits in rubber, one
    /// settledInContact event records every ball before and after and the energy taken out (before minus after, never
    /// negative because only motion is removed), and a ball that came to rest over a hole drops into it.
    private mutating func settleJam(around storm: Int) {
        let reach = 2 * P.ballRadius + 1e-5
        var group = [storm]
        var k = 0
        while k < group.count {
            let g = group[k]
            let pg = bodyState(g, at: now).position
            for j in 0..<bodies.count where bodies[j].active && !group.contains(j) && inStorm(j) {
                if (bodyState(j, at: now).position - pg).lengthSquared <= reach * reach { group.append(j) }
            }
            k += 1
        }
        group.sort()
        var before: [Int: BodyState] = [:]
        var after: [Int: BodyState] = [:]
        for g in group {
            let b = bodyState(g, at: now)
            before[g] = b
            after[g] = BodyState(position: b.position, velocity: .zero, omega: Vec3(0, 0, b.omega.z), height: 0, vz: 0)
        }
        separate(group, &after)
        var removed = 0.0
        var balls: [ImpactBall] = []
        var centre = Vec2.zero
        for g in group {
            let b = before[g]!, a = after[g]!
            restart(g, at: now, with: a)
            let ib = impactBall(g, b, a)
            removed += ib.energyBefore - ib.energyAfter
            balls.append(ib)
            centre = centre + a.position * (1 / Double(group.count))
            stormCount[g] = 0
        }
        events.append(LensEvent(time: now, kind: .settledInContact, point: centre, normal: .zero, balls: balls,
                                energyRemoved: removed > 0 ? removed : 0))
        jamsSettled += 1
        for g in group {
            let p = after[g]!.position
            if let k = pockets.indices.first(where: { (p - pockets[$0]).lengthSquared <= captureRadii[$0] * captureRadii[$0] }) {
                applyPocket(g, k)
            }
        }
    }

    /// Push the settled balls apart and out of the rubber, a few passes at most. A settled ball moves away from any ball
    /// it overlaps (half each when both are settling; all of it when the other ball is not part of the jam), then out of
    /// any rail, jaw, knuckle or post it sits inside, using the same contact distances the solver tests. The overlaps
    /// being undone are rounding-sized, so one or two passes do it; the cap of 32 only bounds the loop.
    private func separate(_ group: [Int], _ after: inout [Int: BodyState]) {
        let touch = 2 * P.ballRadius * (1 + 1e-9)
        for _ in 0..<32 {
            var moved = false
            for g in group {
                for j in 0..<bodies.count where j != g && bodies[j].active {
                    let pj = after[j]?.position ?? bodyState(j, at: now).position
                    let pg = after[g]!.position
                    let d = pg - pj
                    let dist = d.length
                    if dist >= touch { continue }
                    let dir = dist > 1e-15 ? d * (1 / dist) : Vec2(1, 0)
                    if after[j] != nil {
                        after[g]!.position = pg + dir * ((touch - dist) * 0.5)
                        after[j]!.position = pj - dir * ((touch - dist) * 0.5)
                    } else {
                        after[g]!.position = pg + dir * (touch - dist)
                    }
                    moved = true
                }
                let fixed = outOfRubber(after[g]!.position)
                if fixed != after[g]!.position { after[g]!.position = fixed; moved = true }
            }
            if !moved { return }
        }
    }

    /// The nearest place to `p` that is not inside a rail, jaw, knuckle or post, by the solver's own contact rules.
    private func outOfRubber(_ p0: Vec2) -> Vec2 {
        var p = p0
        for wall in walls {
            let along = wall.alongX ? p.x : p.y
            let depth = wall.offset - wall.normal.dot(p)
            if depth > 0 && wall.ranges.contains(where: { along >= $0.0 && along <= $0.1 }) { p = p + wall.normal * depth }
        }
        for jaw in jaws {
            let rel = p - jaw.start
            let along = rel.dot(jaw.direction), off = rel.dot(jaw.normal)
            if along >= 0 && along <= jaw.length && off > -P.ballRadius && off < railContact {
                p = p + jaw.normal * (railContact - off)
            }
        }
        for knuckle in knuckles {
            let d = p - knuckle.point
            let dist = d.length
            if dist < railContact && dist > 1e-15 { p = knuckle.point + d * (railContact / dist) }
        }
        for post in posts {
            let d = p - post.center
            let dist = d.length, reach = P.ballRadius + post.radius
            if dist < reach && dist > 1e-15 { p = post.center + d * (reach / dist) }
        }
        return p
    }

    /// The hard event limit was reached (logged by the caller). Every ball still moving stops where it is (spin about
    /// the vertical axis kept), each with a phase-transition event, so the recording ends at rest instead of being cut
    /// off with balls in mid-flight. A spinning-in-place ball is left to finish on its own.
    mutating func haltAtLimit() {
        for i in 0..<bodies.count where bodies[i].active {
            let from = bodies[i].segment.phase
            guard from == .sliding || from == .rolling || from == .airborne else { continue }
            let b = bodyState(i, at: now)
            let a = BodyState(position: b.position, velocity: .zero, omega: Vec3(0, 0, b.omega.z), height: 0, vz: 0)
            restart(i, at: now, with: a)
            events.append(LensEvent(time: now, kind: .phaseTransition, point: b.position, normal: .zero,
                                    balls: [impactBall(i, b, a)], phaseFrom: from, phaseTo: bodies[i].segment.phase))
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
        noteImpact(i, approach: before.vz < 0 ? -before.vz : 0)
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

    // MARK: Holes, generation two (pockets-and-jams plan part A)

    /// The pocket's centre line at this ball (a unit vector into the hole): for an edge pocket straight in through the
    /// middle of its mouth (a corner along its diagonal, a side straight out across the rail); for a bed hole, which has
    /// no mouth, from where the ball is through the hole's centre (LensEvent's PocketEntry note).
    private func centreLine(_ k: Int, at p: Vec2, moving v: Vec2) -> Vec2 {
        if let mouth = mouths[k] { return mouth.inward * -1 }
        let toCentre = (pockets[k] - p).normalized
        return toCentre == .zero ? v.normalized : toCentre
    }

    /// How a ball comes into hole k: its speed across the cloth and the angle between its path and the centre line,
    /// as a sine (counter-clockwise from the centre line is positive) and a cosine (1 is dead centre).
    private func entry(_ k: Int, _ st: BodyState) -> PocketEntry {
        let speed = st.velocity.length
        guard speed > 1e-12 else { return PocketEntry(speed: 0, sine: 0, cosine: 1) }
        let along = st.velocity * (1 / speed)
        let line = centreLine(k, at: st.position, moving: st.velocity)
        return PocketEntry(speed: speed, sine: line.x * along.y - line.y * along.x, cosine: line.dot(along))
    }

    /// The fall-across-the-hole test. A ball over a hole starts to fall; it is caught if, before its centre leaves the
    /// far side of the capture circle, it has dropped at least pocketCaptureFallFraction of its radius. In closed form:
    /// the rest of its path across the circle is a chord of length d (the far root of |p + u s - c| = r along the unit
    /// direction u, one square root), it crosses in T = d / v (friction ignored for this instant), and falls g T^2 / 2;
    /// so it is caught when g d^2 >= 2 f R v^2, squares only. An edge pocket has a back wall: if the far end of the
    /// chord lies beyond the mouth line (inside the pocket), the ball meets the back and drops whatever its speed, so
    /// only a ball whose path leaves the circle on the table side (a fast ball across the mouth) can skip. A bed hole
    /// has no back: the test applies fully. A ball at rest over a hole drops.
    private func captures(_ k: Int, _ st: BodyState) -> Bool {
        let v2 = st.velocity.lengthSquared
        guard v2 > 1e-24 else { return true }
        let speed = v2.squareRoot()
        let rel = st.position - pockets[k]
        let along = rel.dot(st.velocity) / speed                     // negative while heading in
        let rr = captureRadii[k] * captureRadii[k]
        var disc = along * along + rr - rel.lengthSquared
        if disc < 0 { disc = 0 }
        var chord = -along + disc.squareRoot()                       // distance to the far side of the circle
        if chord < 0 { chord = 0 }
        if let mouth = mouths[k] {
            let exit = st.position + st.velocity * (chord / speed)
            if (exit - mouth.mid).dot(mouth.inward) <= 0 { return true }
        }
        return P.gravity * chord * chord >= 2 * P.pocketCaptureFallFraction * P.ballRadius * v2
    }

    /// The crossing ball leaves the hole's circle: the rim skip. It pays rimSkipSpeedLoss of its speed (its velocity and
    /// its rolling spin both scale down, so a rolling ball stays rolling; spin about the vertical is kept) and carries
    /// on. The event records how it came in. The hole is then ignored for this ball until it is seen outside it.
    private mutating func applyRimSkip(_ i: Int, _ k: Int) {
        let before = bodyState(i, at: now)
        let keep = 1 - P.rimSkipSpeedLoss
        var after = before
        after.velocity = before.velocity * keep
        after.omega = Vec3(before.omega.x * keep, before.omega.y * keep, before.omega.z)
        restart(i, at: now, with: after)
        skip[i] = HoleSkip(hole: k, exited: true)
        events.append(LensEvent(time: now, kind: .rimSkip, point: before.position,
                                normal: centreLine(k, at: before.position, moving: before.velocity),
                                balls: [impactBall(i, before, after)], pocket: pocketIndex[k],
                                entry: skipEntry[i] ?? entry(k, before)))
        skipEntry[i] = nil
    }

    private mutating func applyPocket(_ i: Int, _ k: Int) {
        let st = bodyState(i, at: now)
        // Generation 2: every pocket event says how the ball came in, and a ball on the cloth that is too fast to fall
        // into the hole starts a crossing instead (no event yet: its rim skip is recorded when it leaves the circle).
        // A ball in the air is caught as before: it is already falling.
        var how: PocketEntry?
        if P.usesGenerationTwo {
            let e = entry(k, st)
            if st.height <= 0 && !captures(k, st) {
                skip[i] = HoleSkip(hole: k, exited: false)
                skipEntry[i] = e
                return
            }
            how = e
        }
        let (tb, rb) = energy(st)
        let ib = ImpactBall(ball: i, velocityBefore: st.velocity, velocityAfter: .zero, omegaBefore: st.omega,
                            omegaAfter: .zero, translationalBefore: tb, rotationalBefore: rb,
                            translationalAfter: 0, rotationalAfter: 0)
        events.append(LensEvent(time: now, kind: .pocket, point: st.position, normal: (pockets[k] - st.position).normalized,
                                balls: [ib], pocket: pocketIndex[k], entry: how))
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

    /// The impact with a rail nose (a straight rail, a jaw face or a knuckle) whose horizontal inward normal is `n`:
    /// the flat cushion at generation 1, exactly as before; the Level A rail at generation 2 (Impacts.rail), whose
    /// result carries the push into the cloth. Also counts the hit for the jam guard.
    private mutating func noseImpact(_ i: Int, _ before: BodyState, normal n: Vec2) -> ImpactResult {
        let into = before.velocity.dot(n)
        noteImpact(i, approach: into < 0 ? -into : 0)
        return P.usesGenerationTwo ? Impacts.rail(before, normal: n, P) : Impacts.cushion(before, normal: n, P)
    }

    /// Generation 2: after a rail hit a ball on the cloth has no vertical speed (the bed took it) unless the rail's
    /// friction lifted it; settle that like any other (a lift under the minimum hop is absorbed) and, if the ball really
    /// leaves the cloth, record its take-off right after the rail event, as a hit from above does. Generation 1: the
    /// flat cushion never changes the vertical, so this is never called.
    private mutating func railTakeOff(_ i: Int, _ state: BodyState, from phase: MotionPhase) -> BodyState {
        guard state.height <= 0, state.vz > 0 else { return state }
        let (settled, _) = settleVertical(state)
        if settled.vz > 0 {
            events.append(LensEvent(time: now, kind: .phaseTransition, point: settled.position, normal: .zero,
                                    balls: [impactBall(i, state, settled)], phaseFrom: phase, phaseTo: .airborne,
                                    flight: .takeOff, verticalSpeedUp: settled.vz))
        }
        return settled
    }

    private mutating func applyCushion(_ i: Int, _ w: Int) {
        if w >= firstPost { applyPost(i, w - firstPost); return }
        if w >= walls.count + jaws.count { applyKnuckle(i, w - walls.count - jaws.count); return }
        if w >= walls.count { applyJaw(i, w - walls.count); return }
        let wall = walls[w]
        let before = bodyState(i, at: now)
        let phase = bodies[i].segment.phase
        var res = noseImpact(i, before, normal: wall.normal)
        // Put the ball exactly on its contact line so rounding cannot leave it inside the cushion. The line is the
        // wall's offset, which is the rail contact distance at either generation.
        let pen = wall.offset - wall.normal.dot(res.states[0].position)
        if pen > 0 { res.states[0].position = res.states[0].position + wall.normal * pen }
        let gen2 = P.usesGenerationTwo
        events.append(LensEvent(time: now, kind: .cushion, point: before.position - wall.normal * railContact,
                                normal: wall.normal, normalImpulse: res.normalImpulse,
                                frictionImpulse: res.frictionImpulse, slipSpeed: res.slipSpeed,
                                balls: [impactBall(i, before, res.states[0])],
                                bedImpulse: gen2 ? res.bedImpulse : nil))
        let final = gen2 ? railTakeOff(i, res.states[0], from: phase) : res.states[0]
        restart(i, at: now, with: final)
    }

    private mutating func applyJaw(_ i: Int, _ k: Int) {
        let jaw = jaws[k]
        let before = bodyState(i, at: now)
        let phase = bodies[i].segment.phase
        var res = noseImpact(i, before, normal: jaw.normal)
        // Put the ball exactly its contact distance off the face so rounding cannot leave it inside the rubber.
        let pen = railContact - jaw.normal.dot(res.states[0].position - jaw.start)
        if pen > 0 { res.states[0].position = res.states[0].position + jaw.normal * pen }
        let gen2 = P.usesGenerationTwo
        events.append(LensEvent(time: now, kind: .cushion, point: before.position - jaw.normal * railContact,
                                normal: jaw.normal, normalImpulse: res.normalImpulse,
                                frictionImpulse: res.frictionImpulse, slipSpeed: res.slipSpeed,
                                balls: [impactBall(i, before, res.states[0])], pocket: jaw.pocket, edge: .jaw,
                                bedImpulse: gen2 ? res.bedImpulse : nil))
        let final = gen2 ? railTakeOff(i, res.states[0], from: phase) : res.states[0]
        restart(i, at: now, with: final)
    }

    private mutating func applyKnuckle(_ i: Int, _ k: Int) {
        let knuckle = knuckles[k]
        let before = bodyState(i, at: now)
        let phase = bodies[i].segment.phase
        // The knuckle pushes straight out from its point: the normal is the line from the point to the ball's centre.
        let n = (before.position - knuckle.point).normalized
        var res = noseImpact(i, before, normal: n)
        let dist = (res.states[0].position - knuckle.point).length
        if dist < railContact { res.states[0].position = knuckle.point + n * railContact }
        let gen2 = P.usesGenerationTwo
        events.append(LensEvent(time: now, kind: .cushion, point: knuckle.point, normal: n,
                                normalImpulse: res.normalImpulse, frictionImpulse: res.frictionImpulse,
                                slipSpeed: res.slipSpeed, balls: [impactBall(i, before, res.states[0])],
                                pocket: knuckle.pocket, edge: .knuckle, bedImpulse: gen2 ? res.bedImpulse : nil))
        let final = gen2 ? railTakeOff(i, res.states[0], from: phase) : res.states[0]
        restart(i, at: now, with: final)
    }

    /// A fixed round post: the knuckle's response (the normal runs from the post's centre to the ball's), but with the
    /// post's own restitution and friction in place of the cushion's.
    private mutating func applyPost(_ i: Int, _ k: Int) {
        let post = posts[k]
        let before = bodyState(i, at: now)
        let n = (before.position - post.center).normalized
        let into = before.velocity.dot(n)
        noteImpact(i, approach: into < 0 ? -into : 0)
        // Posts keep the flat model at every generation: a post is a rubber cylinder standing on the bed, so it meets
        // the ball at the height of its centre and pushes straight out, with no nose above the ball to drive it down.
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
        let approach = (a.velocity - b.velocity).dot(n)
        noteImpact(i, approach: approach > 0 ? approach : 0)
        noteImpact(j, approach: approach > 0 ? approach : 0)
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
        let approach = Vec3(a.velocity.x - b.velocity.x, a.velocity.y - b.velocity.y, a.vz - b.vz).dot(n)
        noteImpact(i, approach: approach > 0 ? approach : 0)
        noteImpact(j, approach: approach > 0 ? approach : 0)
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
