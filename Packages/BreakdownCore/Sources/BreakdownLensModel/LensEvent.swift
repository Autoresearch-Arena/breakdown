// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: The engine-agnostic event stream the Physics Lens reads. Each event names its producer so the
//          Lens knows how far to trust a number (pool solver numbers are exact; scanned-scene numbers
//          will be labelled estimates later). Also holds the stable 64-bit hasher used for replay equality.
// SRP/DRY check: Pass - data definitions only, no behaviour beyond hashing.

public enum MotionPhase: UInt8, Sendable {
    case sliding, rolling, spinning, stationary
}

public enum LensEventKind: UInt8, Sendable {
    case cueStrike, phaseTransition, ballBall, cushion, pocket
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
    /// Pocket index for pocket events, otherwise -1.
    public var pocket: Int

    public init(time: Double, kind: LensEventKind, point: Vec2, normal: Vec2, normalImpulse: Double = 0,
                frictionImpulse: Double = 0, slipSpeed: Double = 0, balls: [ImpactBall],
                phaseFrom: MotionPhase? = nil, phaseTo: MotionPhase? = nil, pocket: Int = -1,
                producer: LensProducer = .poolSolver) {
        self.time = time; self.kind = kind; self.producer = producer
        self.point = point; self.normal = normal
        self.normalImpulse = normalImpulse; self.frictionImpulse = frictionImpulse; self.slipSpeed = slipSpeed
        self.balls = balls; self.phaseFrom = phaseFrom; self.phaseTo = phaseTo; self.pocket = pocket
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
