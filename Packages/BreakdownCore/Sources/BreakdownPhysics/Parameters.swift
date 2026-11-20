// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (pocket model version 2: knuckles, jaw faces and holes set back from the mouth, replacing the capture disk plus cushion gap).
// PURPOSE: Every tunable number of the pool solver in one versioned value that is hashed into each recorded
//          shot. Values follow the spec section 3.4; anything marked "calibrate" there is a first guess to
//          tune later against the validation suite. No Foundation import anywhere in this module (no libm).
// SRP/DRY check: Pass - the single source of physical constants and table geometry.
import BreakdownLensModel
import BreakdownTimeline

public struct PoolParameters: Sendable {
    public var version = 2
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
    /// Pocket model (version 2, 20-Nov-2026). Each pocket has a mouth between two knuckles on the cushion nose line,
    /// a straight jaw face from each knuckle back into the pocket, and a hole: a ball drops once its centre is within
    /// the capture radius of the hole centre. Balls that clip a knuckle or a jaw rebound off it with the cushion
    /// impact model, so near misses rattle and spit out instead of being swallowed.
    /// Mouths follow regulation nine-foot practice: corner 4.75 in (0.1207 m) between knuckles, side 5.25 in (0.1334 m).
    public var cornerMouth = 0.1207
    public var sideMouth = 0.1334
    /// Jaw directions, as unit vectors (the solver has no trig). The corner jaw is cut at 142 degrees to the cushion
    /// nose and the side jaw at 104 degrees, both leaning back toward the pocket so the throat is narrower than the
    /// mouth. Written for the knuckle on the bottom rail to the RIGHT of its pocket: (along the rail, out of the table).
    /// cos 142 = -0.78801, sin 142 = 0.61566; cos 104 = -0.24192, sin 104 = 0.97030.
    public var cornerJaw = Vec2(-0.788011, -0.615661)
    public var sideJaw = Vec2(-0.241922, -0.970296)
    /// How far each jaw face runs back from its knuckle, metres (it ends inside the hole's capture circle).
    public var jawLength = 0.06
    /// Holes. Every hole centre sits on the cushion nose lines (the corner where two meet, or the middle of a long
    /// rail), and a ball drops once its centre is within the capture radius. The side radius is smaller because the
    /// side hole is centred right on the mouth: a ball rolling along the rail still drops into it, but one that only
    /// clips a knuckle stays out. (The drawn table needs every hole centre on or inside its outline, so no setback.)
    public var cornerCaptureRadius = 0.065
    public var sideCaptureRadius = 0.052
    public var sideHoleSetback = 0.0
    public var rackGap = 1e-6                   // one micrometre between rack neighbours
    public var rackJitter = 2e-7                // seeded jitter amplitude per axis, metres; stays under a quarter of the gap so no pair starts overlapping

    public init() {}

    public var inertia: Double { 0.4 * ballMass * ballRadius * ballRadius }

    /// Hole centres, corners then sides: (0,0) (L,0) (0,W) (L,W) (L/2,-s) (L/2,W+s), s the side setback.
    public var pocketCenters: [Vec2] {
        [Vec2(0, 0), Vec2(tableLength, 0), Vec2(0, tableWidth), Vec2(tableLength, tableWidth),
         Vec2(tableLength * 0.5, -sideHoleSetback), Vec2(tableLength * 0.5, tableWidth + sideHoleSetback)]
    }

    /// Distance from a corner along each cushion nose to its knuckle: the mouth is the diagonal between two knuckles.
    public var cornerKnuckleOffset: Double { cornerMouth * 0.7071067811865476 }

    /// Two jaws per pocket, in pocket order, built from the mouth sizes and jaw directions by sign flips only.
    public var jaws: [JawSpec] {
        let L = tableLength, W = tableWidth, a = cornerKnuckleOffset, h = sideMouth * 0.5
        var out: [JawSpec] = []
        let corners = [Vec2(0, 0), Vec2(L, 0), Vec2(0, W), Vec2(L, W)]
        for (k, c) in corners.enumerated() {
            let sx: Double = c.x == 0 ? 1 : -1, sy: Double = c.y == 0 ? 1 : -1
            // Knuckle on the long (horizontal) rail, then the one on the short (vertical) rail. Mirroring the
            // reference jaw keeps both faces symmetric about the pocket's diagonal.
            let k1 = Vec2(c.x + sx * a, c.y), d1 = Vec2(sx * cornerJaw.x, sy * cornerJaw.y)
            let k2 = Vec2(c.x, c.y + sy * a), d2 = Vec2(sx * cornerJaw.y, sy * cornerJaw.x)
            out.append(JawSpec(pocket: k, start: k1, end: k1 + d1 * jawLength))
            out.append(JawSpec(pocket: k, start: k2, end: k2 + d2 * jawLength))
        }
        for (k, y) in [(4, 0.0), (5, W)] {
            let sy: Double = y == 0 ? 1 : -1
            let right = Vec2(L * 0.5 + h, y), left = Vec2(L * 0.5 - h, y)
            out.append(JawSpec(pocket: k, start: right, end: right + Vec2(sideJaw.x, sy * sideJaw.y) * jawLength))
            out.append(JawSpec(pocket: k, start: left, end: left + Vec2(-sideJaw.x, sy * sideJaw.y) * jawLength))
        }
        return out
    }
    public var pocketCaptureRadii: [Double] {
        [cornerCaptureRadius, cornerCaptureRadius, cornerCaptureRadius, cornerCaptureRadius,
         sideCaptureRadius, sideCaptureRadius]
    }

    public var tableSpec: TableSpec {
        TableSpec(length: tableLength, width: tableWidth, ballRadius: ballRadius,
                  pockets: pocketCenters, pocketCaptureRadius: pocketCaptureRadii, jaws: jaws)
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
                  cushionFriction, tableLength, tableWidth, cornerMouth, sideMouth, cornerJaw.x, cornerJaw.y,
                  sideJaw.x, sideJaw.y, jawLength, cornerCaptureRadius, sideCaptureRadius, sideHoleSetback,
                  rackGap, rackJitter] { h.combine(d) }
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
