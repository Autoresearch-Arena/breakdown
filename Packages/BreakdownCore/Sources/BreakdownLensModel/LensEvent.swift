// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (cushion events say whether they hit the rail, a pocket jaw or a knuckle).
// Edited: Claude Opus 5.5 High, 20-November-2026 (jump shots: a new motion phase, airborne, and a flight mark on
//          events. Take-off, landing and flying off the table are phase-transition events carrying a FlightMark and the
//          vertical speeds, rather than new event kinds, so every existing switch over LensEventKind keeps compiling and
//          keeps its meaning. Events without a flight carry .none and hash exactly as before.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (other tables: a cushion event can come off a fixed round post
//          (CushionEdge.post), and a new kind, pinDown, records a standing pin knocked over. Both name their post or pin
//          in the new `feature` field (-1 everywhere else). The new cases are appended, so no raw value moves and every
//          recording without posts or pins hashes exactly as before.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (shapes for the generation-two physics; the solver fills them in
//          later and only above generation 1. Two new kinds, appended so no raw value moves: rimSkip (a ball crossed a
//          hole too fast and carried on) and settledInContact (the jam guard brought a wedged group of balls to rest).
//          New optional fields, nil at generation 1: entry (speed and angle into a pocket, on pocket and rim-skip
//          events), miscue and deflectionSine (cue-strike events), bedImpulse (rail events: the push down into the
//          cloth from a rail nose above the ball's centre) and energyRemoved (settled-in-contact events).
//          Timeline.contentHash folds each one in only when it is set, so every recording without them hashes
//          exactly as before.)
// PURPOSE: The engine-agnostic event stream the Physics Lens reads. Each event names its producer so the
//          Lens knows how far to trust a number (pool solver numbers are exact; scanned-scene numbers
//          will be labelled estimates later). Also holds the stable 64-bit hasher used for replay equality.
// SRP/DRY check: Pass - data definitions only, no behaviour beyond hashing.

public enum MotionPhase: UInt8, Sendable {
    /// `airborne`: the ball is off the cloth (after a jump strike or a bounce), flying a parabola under gravity
    /// with its spin carried unchanged. Added last so the raw values of the older phases (hashed) never move.
    case sliding, rolling, spinning, stationary, airborne
}

/// What a phase-transition event means for a ball's flight. `takeOff`: the ball leaves the cloth (a jump strike, or
/// a hit from above that bounces it off the slate). `landing`: it comes down on the slate; `phaseTo` says whether it
/// bounces again (`airborne`) or stays down (sliding or rolling). `offTable`: it flew over a cushion and left the
/// table; like a pocketed ball it stops there and is taken off for the next shot.
public enum FlightMark: UInt8, Sendable {
    case none, takeOff, landing, offTable
}

/// `pinDown` (added last, so older raw values never move): a ball touched a standing pin and knocked it over; the
/// event's `feature` is the pin's index in TableSpec.pins and its first ball is the ball that hit it.
/// `rimSkip` (21-Nov-2026, generation two only): a ball crossed a hole too fast to fall in and carried on. `pocket` is
/// the hole (an edge pocket 0 to 5 or a bed hole 6 + j, as on a pocket event), `balls[0]` is the ball with its speed
/// before and after (it pays PoolParameters.rimSkipSpeedLoss), and `entry` holds the speed and angle it came in at.
/// `settledInContact` (21-Nov-2026, the jam guard): a group of wedged balls that were bouncing in a storm of tiny
/// impacts was brought to rest touching. `balls` lists EVERY ball in the group (two or more, each with its state
/// before and after), `energyRemoved` is the energy taken out, joules, so the energy ledger still closes.
public enum LensEventKind: UInt8, Sendable {
    case cueStrike, phaseTransition, ballBall, cushion, pocket, pinDown, rimSkip, settledInContact
}

/// How a ball came into a pocket or a bed hole (pocket and rim-skip events, generation two). `speed` is its speed
/// across the cloth, metres per second. The angle is between the ball's path and the pocket's centre line, given as a
/// sine and cosine (the solver has no trigonometry): the centre line points from the mouth into the pocket (for a
/// corner pocket along its diagonal, for a side pocket straight out across the rail; a bed hole has no mouth, so its
/// centre line runs from the point the ball entered the capture circle through the hole's centre). `cosine` 1 is
/// dead centre; `sine` is positive when the path is turned counter-clockwise from the centre line (table plan).
public struct PocketEntry: Sendable, Equatable {
    public var speed: Double
    public var sine: Double
    public var cosine: Double
    public init(speed: Double, sine: Double, cosine: Double) {
        self.speed = speed; self.sine = sine; self.cosine = cosine
    }
}

/// Which part of the cushion a cushion event hit: the long straight nose, a pocket jaw face, or the rounded knuckle
/// where the nose turns into the jaw. Jaw and knuckle hits carry the pocket index in `pocket`. `post`: a fixed round
/// post standing on the bed (another table's bumper); the event's `feature` is its index in TableSpec.posts.
public enum CushionEdge: UInt8, Sendable {
    case rail, jaw, knuckle, post
}

public enum LensProducer: String, Sendable {
    case poolSolver
}

/// What happened to one ball in an event: velocity and spin before and after, and the energy split.
public struct ImpactBall: Sendable, Equatable {
    public var ball: Int
    public var velocityBefore: Vec2
    public var velocityAfter: Vec2
    public var omegaBefore: Vec3
    public var omegaAfter: Vec3
    public var translationalBefore: Double
    public var rotationalBefore: Double
    public var translationalAfter: Double
    public var rotationalAfter: Double

    public init(ball: Int, velocityBefore: Vec2, velocityAfter: Vec2, omegaBefore: Vec3, omegaAfter: Vec3,
                translationalBefore: Double, rotationalBefore: Double,
                translationalAfter: Double, rotationalAfter: Double) {
        self.ball = ball
        self.velocityBefore = velocityBefore; self.velocityAfter = velocityAfter
        self.omegaBefore = omegaBefore; self.omegaAfter = omegaAfter
        self.translationalBefore = translationalBefore; self.rotationalBefore = rotationalBefore
        self.translationalAfter = translationalAfter; self.rotationalAfter = rotationalAfter
    }

    public var energyBefore: Double { translationalBefore + rotationalBefore }
    public var energyAfter: Double { translationalAfter + rotationalAfter }
}

public struct LensEvent: Sendable, Equatable {
    public var time: Double
    public var kind: LensEventKind
    public var producer: LensProducer
    /// Where it happened on the table (metres, table frame).
    public var point: Vec2
    /// Contact normal pointing from the first body toward the second, or into the table for a cushion.
    public var normal: Vec2
    /// Impulse along the normal and along the friction direction, in newton-seconds.
    public var normalImpulse: Double
    public var frictionImpulse: Double
    /// Contact slip speed before the impact (metres per second); zero when not applicable.
    public var slipSpeed: Double
    /// Bodies involved, the first is the mover or the ball itself.
    public var balls: [ImpactBall]
    /// Phase change for phase-transition events.
    public var phaseFrom: MotionPhase?
    public var phaseTo: MotionPhase?
    /// Pocket index for pocket events and for jaw or knuckle hits, otherwise -1.
    public var pocket: Int
    /// For cushion events: which part of the cushion was hit.
    public var edge: CushionEdge
    /// For phase-transition events: take-off, landing or leaving the table; `.none` for everything else.
    public var flight: FlightMark
    /// Vertical speeds for flight events, metres per second, both positive: the speed coming down onto the slate just
    /// before a landing, and the speed going up just after a take-off or a bounce. Zero when they do not apply.
    public var verticalSpeedDown: Double
    public var verticalSpeedUp: Double
    /// Height of the ball's lowest point above the cloth when the event happened (metres); zero on the cloth.
    public var height: Double
    /// For a post hit (edge .post) the post's index, for a pinDown event the pin's index; -1 for everything else.
    public var feature: Int
    // Generation-two fields (21-Nov-2026). Every one is nil at generation 1 and on recordings made before them.
    /// Pocket and rim-skip events: the speed and angle the ball came in at.
    public var entry: PocketEntry?
    /// Cue-strike events: true when the tip slipped off the ball (the offset passed the tip-grip limit).
    public var miscue: Bool?
    /// Cue-strike events: the sine of the angle the cue ball's launch direction turned away from the aim (positive is
    /// counter-clockwise in the table plan); side spin pushes the ball off line, a miscue by a seeded random amount.
    public var deflectionSine: Double?
    /// Cushion events on a rail nose (edge .rail, .jaw or .knuckle): the impulse that pushed the ball down into the
    /// cloth, newton-seconds, because the nose touches the ball above its centre. Nil for flat (generation-1) rails.
    public var bedImpulse: Double?
    /// Settled-in-contact events: the energy the jam guard took out of the group, joules (before minus after).
    public var energyRemoved: Double?

    public init(time: Double, kind: LensEventKind, point: Vec2, normal: Vec2, normalImpulse: Double = 0,
                frictionImpulse: Double = 0, slipSpeed: Double = 0, balls: [ImpactBall],
                phaseFrom: MotionPhase? = nil, phaseTo: MotionPhase? = nil, pocket: Int = -1,
                edge: CushionEdge = .rail, flight: FlightMark = .none, verticalSpeedDown: Double = 0,
                verticalSpeedUp: Double = 0, height: Double = 0, feature: Int = -1,
                entry: PocketEntry? = nil, miscue: Bool? = nil, deflectionSine: Double? = nil,
                bedImpulse: Double? = nil, energyRemoved: Double? = nil,
                producer: LensProducer = .poolSolver) {
        self.time = time; self.kind = kind; self.producer = producer
        self.point = point; self.normal = normal
        self.normalImpulse = normalImpulse; self.frictionImpulse = frictionImpulse; self.slipSpeed = slipSpeed
        self.balls = balls; self.phaseFrom = phaseFrom; self.phaseTo = phaseTo; self.pocket = pocket
        self.edge = edge
        self.flight = flight; self.verticalSpeedDown = verticalSpeedDown; self.verticalSpeedUp = verticalSpeedUp
        self.height = height
        self.feature = feature
        self.entry = entry; self.miscue = miscue; self.deflectionSine = deflectionSine
        self.bedImpulse = bedImpulse; self.energyRemoved = energyRemoved
    }
}

/// FNV-1a over raw bit patterns. Same bits in, same hash out, on every machine.
public struct StableHasher: Sendable {
    public private(set) var value: UInt64 = 0xcbf2_9ce4_8422_2325
    public init() {}
    public mutating func combine(_ v: UInt64) {
        var shift: UInt64 = 0
        while shift < 64 {
            value ^= (v >> shift) & 0xff
            value = value &* 0x0000_0100_0000_01b3
            shift += 8
        }
    }
    public mutating func combine(_ d: Double) { combine(d.bitPattern) }
    public mutating func combine(_ i: Int) { combine(UInt64(bitPattern: Int64(i))) }
    public mutating func combine(_ v: Vec2) { combine(v.x); combine(v.y) }
    public mutating func combine(_ v: Vec3) { combine(v.x); combine(v.y); combine(v.z) }
}
