// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: Every tunable number of the pool solver in one versioned value that is hashed into each recorded
//          shot. Values follow the spec section 3.4; anything marked "calibrate" there is a first guess to
//          tune later against the validation suite. No Foundation import anywhere in this module (no libm).
// SRP/DRY check: Pass - the single source of physical constants and table geometry.
import BreakdownLensModel
import BreakdownTimeline

public struct PoolParameters: Sendable {
    public var version = 1
    public var ballRadius = 0.028575            // regulation, metres
    public var ballMass = 0.170                 // kilograms
    public var gravity = 9.81
    public var slidingFriction = 0.2            // cloth, calibrate (0.15 to 0.4)
    public var rollingResistance = 0.01         // constant centre deceleration of c_r * g, calibrate
    public var spinDecay = 9.0                  // rad/s squared for vertical spin, calibrate
    public var ballBallRestitution = 0.95
    /// Ball-ball friction is a fit of the form a + b * exp(-c * slip). The exponential is replaced by a fixed
    /// rational approximation (see `ballBallFriction`) so the solver needs no libm.
    public var ballBallFrictionFloor = 0.00995
    public var ballBallFrictionGain = 0.108
    public var ballBallFrictionDecay = 1.088
    public var cushionRestitution = 0.85        // flat-normal Level A model, calibrate
    public var cushionFriction = 0.17           // calibrate
    /// Playing surface between cushion nose lines (nine-foot table).
    public var tableLength = 2.54
    public var tableWidth = 1.27
    /// Pocket model: a capture disk per pocket, and a gap in the cushion line beside it.
    public var cornerCaptureRadius = 0.095
    public var cornerGap = 0.09
    public var sideCaptureRadius = 0.08
    public var sideGap = 0.075
    public var rackGap = 1e-6                   // one micrometre between rack neighbours
    public var rackJitter = 2e-7                // seeded jitter amplitude per axis, metres; stays under a quarter of the gap so no pair starts overlapping

    public init() {}

    public var inertia: Double { 0.4 * ballMass * ballRadius * ballRadius }

    /// Pocket centres, corners then sides: (0,0) (L,0) (0,W) (L,W) (L/2,0) (L/2,W).
    public var pocketCenters: [Vec2] {
        [Vec2(0, 0), Vec2(tableLength, 0), Vec2(0, tableWidth), Vec2(tableLength, tableWidth),
         Vec2(tableLength * 0.5, 0), Vec2(tableLength * 0.5, tableWidth)]
    }
    public var pocketCaptureRadii: [Double] {
        [cornerCaptureRadius, cornerCaptureRadius, cornerCaptureRadius, cornerCaptureRadius,
         sideCaptureRadius, sideCaptureRadius]
    }

    public var tableSpec: TableSpec {
        TableSpec(length: tableLength, width: tableWidth, ballRadius: ballRadius,
                  pockets: pocketCenters, pocketCaptureRadius: pocketCaptureRadii)
    }

    /// Ball-ball friction coefficient at a slip speed, using exp(-x) ~ 1 / (1 + x + x^2/2 + x^3/6 + x^4/24).
    /// Maximum error against the true curve is under 0.003 for slip speeds up to 5 m/s.
    public func ballBallFriction(slip s: Double) -> Double {
        let x = ballBallFrictionDecay * s
        let denom = 1 + x + x * x / 2 + x * x * x / 6 + x * x * x * x / 24
        return ballBallFrictionFloor + ballBallFrictionGain / denom
    }

    public var hash: UInt64 {
        var h = StableHasher()
        for d in [ballRadius, ballMass, gravity, slidingFriction, rollingResistance, spinDecay, ballBallRestitution,
                  ballBallFrictionFloor, ballBallFrictionGain, ballBallFrictionDecay, cushionRestitution,
                  cushionFriction, tableLength, tableWidth, cornerCaptureRadius, cornerGap, sideCaptureRadius,
                  sideGap, rackGap, rackJitter] { h.combine(d) }
        h.combine(version)
        return h.value
    }
}

/// How the cue hits the cue ball. Direction is a unit vector supplied by the caller (no trig in the solver).
/// `tipUp` and `tipSide` are the contact offsets from the ball centre in metres, up and to the right of the
/// aim direction. Speed is the cue ball's launch speed.
public struct CueStrike: Sendable {
    public var direction: Vec2
    public var speed: Double
    public var tipUp: Double
    public var tipSide: Double
    public init(direction: Vec2, speed: Double, tipUp: Double = 0, tipSide: Double = 0) {
        self.direction = direction.normalized; self.speed = speed; self.tipUp = tipUp; self.tipSide = tipSide
    }
}

public struct ShotInput: Sendable {
    public var parameters: PoolParameters
    /// Starting centre of every ball; index 0 is the cue ball. Balls placed at (-1,-1) are not on the table.
    public var positions: [Vec2]
    public var strike: CueStrike
    public var seed: UInt64
    public init(parameters: PoolParameters = PoolParameters(), positions: [Vec2], strike: CueStrike, seed: UInt64) {
        self.parameters = parameters; self.positions = positions; self.strike = strike; self.seed = seed
    }
}
