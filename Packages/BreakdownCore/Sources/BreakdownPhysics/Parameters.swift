// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (pocket model version 2: knuckles, jaw faces and holes set back from the mouth, replacing the capture disk plus cushion gap).
// Edited: Claude Opus 5.5 High, 20-November-2026 (jump and masse: the slate's bounce and friction, the smallest hop
//          that leaves the cloth and the cushion nose height, and CueStrike gains the cue's elevation as a sine. The new
//          numbers join the parameter hash only when they differ from their defaults, so every recording made before
//          them keeps its hash; a level strike takes exactly the old code path.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (other tables: optional layout features, all empty on a pool table:
//          fixed round posts, standing pins that a ball knocks down, holes anywhere in the bed (bed hole j is pocket
//          6 + j), and pocketsEnabled (false removes the six edge pockets and their jaws, so the cushions run the full
//          length of every side). Like the jump numbers they join the hash only when set, behind their own marker, so the
//          default parameters, and every recording made before them, hash exactly as before.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the physics switch: modelGeneration, read by the solver, picks the
//          physics model. Generation one is today's solver exactly; generation two gathers the planned rails, cue
//          strike and pocket changes, whose numbers are declared here with their starting values and reasons. The
//          generation and every generation-two number join the hash only when the generation is not one, behind their
//          own marker, so the default parameters and every recording made before them hash exactly as before.
//          CueStrike gains ballIndex, the ball the cue strikes (default 0, the cue ball; not hashed, see its note).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (generation two built: the strike-model note below; derived, unhashed
//          helpers the solver and the app share: the rail's contact tilt (railContactSine, railContactCosine,
//          railContactDistance) and the miscue limit (miscueOffsetLimit). They are worked out from hashed numbers, so
//          they add nothing to the hash. The solver now strikes CueStrike.ballIndex.)
//
// THE STRIKE MODEL (plans/21-Nov-2026-cue-strike-plan.md). CueStrike.speed is the launch speed a CENTRE hit with the
// same stroke would give, so the power control and every authored shot mean the same thing at centre on every
// generation. At generation 1 every hit launches at exactly that speed, straight along the cue. At generation 2 an
// off-centre hit launches slower (the factor under cueMass), side spin pushes the ball off line (shaftEndMass) and an
// offset past the tip's grip miscues (tipGrip, miscueSpeedFraction, miscueMaxDeflection).
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4, the flip: generation two is the default, with
//          the cloth, roll, spin and rail numbers the real-table sweep chose (0.15, 0.015, 9.5, 0.95); each once-guessed
//          number now says which checks fixed it. PoolParameters.generationOne keeps the old numbers and generation.)
// PURPOSE: Every tunable number of the pool solver in one versioned value that is hashed into each recorded
//          shot. Values follow the spec section 3.4, tuned against the real-table checks (RealWorldTests, BreakProbe
//          sweep). modelGeneration picks the physics model (2, the default, is the tuned model; 1 is the solver as it
//          was before, reachable with its old numbers through PoolParameters.generationOne). Also the cue strike (CueStrike) and the shot
//          input (ShotInput) the solver takes. No Foundation import anywhere in this module (no libm).
// SRP/DRY check: Pass - the single source of physical constants and table geometry.
import BreakdownLensModel
import BreakdownTimeline

public struct PoolParameters: Sendable {
    public var version = 2
    public var ballRadius = 0.028575            // regulation, metres
    public var ballMass = 0.170                 // kilograms
    public var gravity = 9.81
    public var slidingFriction = 0.15           // cloth: fixed by the stop-shot and draw checks (real-table cases 2, 3)
    public var rollingResistance = 0.015        // centre deceleration c_r * g: fixed by the lag and lengths checks (1, 8)
    public var spinDecay = 9.5                  // rad/s squared, vertical spin: fixed by the spin-down check (case 9)
    public var ballBallRestitution = 0.95
    /// Ball-ball friction is a fit of the form a + b * exp(-c * slip). The exponential is replaced by a fixed
    /// rational approximation (see `ballBallFriction`) so the solver needs no libm.
    public var ballBallFrictionFloor = 0.00995
    public var ballBallFrictionGain = 0.108
    public var ballBallFrictionDecay = 1.088
    public var cushionRestitution = 0.95        // rail bounce at walking pace: fixed by the rail energy check (case 6)
    public var cushionFriction = 0.17           // rail grip: fixed by the rail angle check (case 7), the spec's middle
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
    /// Jump and masse (20-Nov-2026). A cue that is raised drives the ball down into the cloth; the slate bounces it
    /// back up with this restitution (measured cloth-on-slate values are about 0.5), and while the ball is pressed
    /// into the cloth, cloth friction (this coefficient, capped by the impulse that stops the slip) acts on the
    /// contact point. The same bounce applies every time a ball comes down from a jump.
    public var slateRestitution = 0.5
    public var slateFriction = 0.2
    /// The smallest hop that leaves the cloth: a bounce whose rise would be lower than this (metres) is absorbed by
    /// the cloth instead, so a jump ends after a few quickly shrinking bounces rather than an endless series.
    public var minimumHop = 0.001
    /// Height of the cushion nose above the cloth (regulation is 62.5 to 64.5 percent of a ball diameter). A ball in
    /// the air whose lowest point is below this meets the cushion like a ball on the cloth; one above it sails over
    /// the cushion and off the table.
    public var cushionNoseHeight = 0.0363
    /// Other tables (21-Nov-2026; see BreakdownTimeline/TableFeatures.swift). A pool table has none of these.
    /// pocketsEnabled false removes the six edge pockets, their jaws and knuckles: each cushion runs its full side.
    public var pocketsEnabled = true
    public var posts: [Post] = []
    public var pins: [Pin] = []
    /// Holes in the bed, captured like pockets. Bed hole j is pocket index 6 + j, with or without the edge pockets.
    public var bedHoles: [BedHole] = []
    public var rackGap = 1e-6                   // one micrometre between rack neighbours
    public var rackJitter = 2e-7                // seeded jitter amplitude per axis, metres; stays under a quarter of the gap so no pair starts overlapping

    // MARK: The physics switch (21-Nov-2026, plans/21-Nov-2026-physics-proof-plan.md package 1)

    /// Which physics model the solver runs. Unlike `version` (a label stamped on recordings), the solver READS this.
    /// Generation 1 is the solver as it was on 21 November 2026, bit for bit (reach it, with that day's numbers, through
    /// `PoolParameters.generationOne`). Generation 2 gathers the real rails, the real cue strike and pockets that can
    /// refuse a ball; each checks this number and takes the old path at generation 1 (the rule is written at the top of
    /// Simulation.swift). Generation 2 is the default since the proof plan's package 4 tuned it against the real-table
    /// checks and re-authored every trick shot, puzzle and lesson on it (21-Nov-2026).
    public var modelGeneration = 2
    /// The newest generation the solver knows (also the default).
    public static let newestGeneration = 2
    /// True when the generation-two changes are on.
    public var usesGenerationTwo: Bool { modelGeneration >= 2 }

    // Generation-two numbers. They do nothing at generation 1 and join the hash only above it. Each says where it came
    // from; the full real-table sweep (proof plan, package 4) kept every one of them at its starting value.

    /// Rails (plans/21-Nov-2026-rails-plan.md). The rail's restitution falls with the ball's speed into the rail:
    /// e(v) = max(railRestitutionFloor, cushionRestitution - railRestitutionSlope * v), v the normal speed in m/s.
    /// Starting reasons: a floor of 0.6, whose energy share 0.6 squared = 0.36 is "proportionally less" than the
    /// just-under-half the proof plan's case 6 expects at medium speed, and a slope of 0.025 per m/s. With the tuned
    /// cushionRestitution (0.95) the floor is reached at (0.95 - 0.6) / 0.025 = 14 m/s, just past the hardest break
    /// (8 to 13 m/s of cue-ball speed, spec 3.4). Both fixed by the rail energy and rail angle checks (cases 6, 7).
    public var railRestitutionSlope = 0.025
    public var railRestitutionFloor = 0.6
    /// Cue strike (plans/21-Nov-2026-cue-strike-plan.md). The cue's mass, kilograms (spec 3.4: 0.54 kg). An off-centre
    /// hit launches the ball at the centre-hit speed times (M + m) / (M + m + 5/2 * M * offset^2 / R^2). Checked by the
    /// off-centre speed share of case 10 (and the draw, case 3).
    public var cueMass = 0.54
    /// Effective mass of the end of the shaft, kilograms: it sets how far side spin pushes the cue ball off line. The
    /// deflection obeys tan(angle) = 5/2 * x * sqrt(1 - x^2) / (1 + m / Me + 5/2 * x^2), x = side offset / R. The spec
    /// asks for 2 to 3 degrees at half-radius side offset. At x = 0.5 the numerator is 1.25 * 0.866025 = 1.082532 and
    /// 5/2 * x^2 = 0.625, so for 2.5 degrees (tan = 0.043661) the denominator must be 1.082532 / 0.043661 = 24.794,
    /// giving m / Me = 24.794 - 1.625 = 23.169 and Me = 0.170 / 23.169 = 0.00734 kg. Rounded to 0.0073 kg: m / Me =
    /// 23.288, denominator 24.913, tan = 0.043453, about 2.49 degrees (2 degrees would need 0.0058 kg, 3 degrees
    /// 0.0089 kg). A few grams is the right size for the end of a shaft against a 0.54 kg cue.
    public var shaftEndMass = 0.0073
    /// Tip grip, the tip-to-ball friction coefficient (spec 3.3: mu_tip about 0.58). A strike miscues when the offset
    /// from centre exceeds R * tipGrip / sqrt(1 + tipGrip^2) = R * 0.58 / 1.156028 = 0.5017 R, about half the radius.
    public var tipGrip = 0.58
    /// A miscue launches the ball at this share of the centre-hit speed. Reason: a tip that slips carries on past the
    /// ball, so the ball gets roughly the part of the impulse along the contact normal at the point the tip slid to;
    /// near the edge of the tip's travel that normal is about 60 degrees off the cue, and cos 60 degrees = 0.5.
    public var miscueSpeedFraction = 0.5
    /// A miscue's direction is turned by a seeded random amount up to this, as a tangent (sideways over forward; the
    /// solver has no trig). 0.0875 is tan 5 degrees: twice the 2.5-degree push of the largest legal side hit, so a
    /// miscue flies visibly off line while staying on the aimed side of the table.
    public var miscueMaxDeflection = 0.0875
    /// Pockets (plans/21-Nov-2026-pockets-and-jams-plan.md, part A). A ball crossing a hole is captured when it falls
    /// at least this share of its radius before its centre leaves the far side (the plan's starting value, one third).
    public var pocketCaptureFallFraction = 1.0 / 3.0
    /// A ball that skips over a hole loses this share of its speed. Reason: it may dip up to a third of its radius
    /// (0.0095 m) and must climb back out; that costs 2 * g * 0.0095 = 0.19 m^2/s^2 of speed squared, about 2.4
    /// percent of the speed at 2 m/s, and the knock on the far edge costs about as much again: 5 percent to start.
    public var rimSkipSpeedLoss = 0.05

    /// Every generation-two number, in hash order. Appending is safe; reordering would change generation-two hashes.
    private var generationTwoNumbers: [Double] {
        [railRestitutionSlope, railRestitutionFloor, cueMass, shaftEndMass, tipGrip, miscueSpeedFraction,
         miscueMaxDeflection, pocketCaptureFallFraction, rimSkipSpeedLoss]
    }

    public init() {}

    /// The parameters exactly as they were before the tuning of 21-Nov-2026: generation 1 with that day's cloth, roll,
    /// spin and rail numbers. Every recording made before the flip was solved on these, and the bit-for-bit guard tests
    /// pin them, so the old behaviour stays reachable (the app's -oldPhysics developer flag plays free play on them).
    public static var generationOne: PoolParameters {
        var p = PoolParameters()
        p.useGenerationOne()
        return p
    }

    /// Turn these parameters into generation one with that generation's cloth, roll, spin and rail numbers, leaving
    /// everything else (table size, pockets, features) as it is. A caller that then applies a table or a surface does
    /// so on top, exactly as on the default.
    public mutating func useGenerationOne() {
        modelGeneration = 1
        slidingFriction = 0.2
        rollingResistance = 0.01
        spinDecay = 9.0
        cushionRestitution = 0.85
    }

    // MARK: Derived generation-two geometry (not hashed: worked out from hashed numbers)

    /// Sine of the tilt of the rail's contact above the ball's centre: the nose touches the ball at cushionNoseHeight,
    /// which is cushionNoseHeight - R above the centre, so the sine is that over R (spec 3.3: about 0.27 for a pool
    /// table). Clamped to 0...0.9 so a nose set at or below the centre gives the flat rail and a very high nose cannot
    /// make the cosine vanish.
    public var railContactSine: Double {
        let s = (cushionNoseHeight - ballRadius) / ballRadius
        return s < 0 ? 0 : (s > 0.9 ? 0.9 : s)
    }
    /// Cosine of the same tilt, sqrt(1 - s^2) (no trigonometry in the solver).
    public var railContactCosine: Double { (1 - railContactSine * railContactSine).squareRoot() }
    /// How far the ball's centre is from a rail's nose line when they touch: R at generation 1 (the flat wall),
    /// R * cos(tilt) at generation 2 (spec 3.3: about 0.963 R), because the nose meets the ball above its centre.
    public var railContactDistance: Double { usesGenerationTwo ? ballRadius * railContactCosine : ballRadius }
    /// The tip offset (metres, measured across the cue) past which a generation-2 strike miscues:
    /// R * tipGrip / sqrt(1 + tipGrip^2) (spec 3.3; about half the radius). The app draws its miscue ring here.
    public var miscueOffsetLimit: Double { ballRadius * tipGrip / (1 + tipGrip * tipGrip).squareRoot() }

    public var inertia: Double { 0.4 * ballMass * ballRadius * ballRadius }

    /// Hole centres, corners then sides: (0,0) (L,0) (0,W) (L,W) (L/2,-s) (L/2,W+s), s the side setback.
    public var pocketCenters: [Vec2] {
        [Vec2(0, 0), Vec2(tableLength, 0), Vec2(0, tableWidth), Vec2(tableLength, tableWidth),
         Vec2(tableLength * 0.5, -sideHoleSetback), Vec2(tableLength * 0.5, tableWidth + sideHoleSetback)]
    }

    /// Distance from a corner along each cushion nose to its knuckle: the mouth is the diagonal between two knuckles.
    public var cornerKnuckleOffset: Double { cornerMouth * 0.7071067811865476 }

    /// Two jaws per pocket, in pocket order, built from the mouth sizes and jaw directions by sign flips only.
    /// None when the table has no edge pockets.
    public var jaws: [JawSpec] {
        guard pocketsEnabled else { return [] }
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
                  pockets: pocketsEnabled ? pocketCenters : [], pocketCaptureRadius: pocketsEnabled ? pocketCaptureRadii : [],
                  jaws: jaws, pocketsEnabled: pocketsEnabled, posts: posts, pins: pins, bedHoles: bedHoles)
    }

    /// Ball-ball friction coefficient at a slip speed, using exp(-x) ~ 1 / (1 + x + x^2/2 + x^3/6 + x^4/24).
    /// Maximum error against the true curve is under 0.003 for slip speeds up to 5 m/s.
    public func ballBallFriction(slip s: Double) -> Double {
        let x = ballBallFrictionDecay * s
        let denom = 1 + x + x * x / 2 + x * x * x / 6 + x * x * x * x / 24
        return ballBallFrictionFloor + ballBallFrictionGain / denom
    }

    private static let defaultJump = [0.5, 0.2, 0.001, 0.0363]

    public var hash: UInt64 {
        var h = StableHasher()
        for d in [ballRadius, ballMass, gravity, slidingFriction, rollingResistance, spinDecay, ballBallRestitution,
                  ballBallFrictionFloor, ballBallFrictionGain, ballBallFrictionDecay, cushionRestitution,
                  cushionFriction, tableLength, tableWidth, cornerMouth, sideMouth, cornerJaw.x, cornerJaw.y,
                  sideJaw.x, sideJaw.y, jawLength, cornerCaptureRadius, sideCaptureRadius, sideHoleSetback,
                  rackGap, rackJitter] { h.combine(d) }
        h.combine(version)
        // The jump numbers came after recordings already existed. They are folded in only when changed from their
        // defaults (behind a marker), so the default parameters hash exactly as they did before them.
        let jump = [slateRestitution, slateFriction, minimumHop, cushionNoseHeight]
        if jump != PoolParameters.defaultJump {
            h.combine(UInt64(0x4A55_4D50))   // "JUMP"
            for d in jump { h.combine(d) }
        }
        // The other tables' features, likewise only when present (a pool table has none, so its hash is unchanged).
        if !pocketsEnabled || !posts.isEmpty || !pins.isEmpty || !bedHoles.isEmpty {
            h.combine(UInt64(0x5441_424C))   // "TABL"
            h.combine(pocketsEnabled ? 1 : 0)
            h.combine(posts.count)
            for p in posts { h.combine(p.center); h.combine(p.radius); h.combine(p.restitution); h.combine(p.friction); h.combine(p.height) }
            h.combine(pins.count)
            for p in pins { h.combine(p.center); h.combine(p.radius); h.combine(p.mass); h.combine(p.restitution); h.combine(p.height) }
            h.combine(bedHoles.count)
            for b in bedHoles { h.combine(b.center); h.combine(b.radius); h.combine(b.captureRadius) }
        }
        // The physics switch, likewise only when it is off its default, behind its own marker: generation 1 (today's
        // solver) hashes exactly as before it existed. The generation-two numbers do nothing at generation 1, so
        // they are hashed only above it.
        if modelGeneration != 1 {
            h.combine(UInt64(0x4745_4E52))   // "GENR"
            h.combine(modelGeneration)
            if modelGeneration > 1 { for d in generationTwoNumbers { h.combine(d) } }
        }
        return h.value
    }
}

/// How the cue hits the cue ball. Direction is a unit vector supplied by the caller (no trig in the solver).
/// `tipUp` and `tipSide` are the contact offsets from the ball centre in metres, up and to the right of the
/// aim direction, measured across the cue (for a raised cue "up" leans back toward the player with the cue).
/// Speed is the launch speed of a centre hit with this stroke (see THE STRIKE MODEL at the top of this file): at
/// generation 1 every hit launches at exactly this speed, at generation 2 an off-centre hit launches slower.
/// `elevation` is the sine of the cue's angle above horizontal (0 level, 1 straight down), clamped to 0...0.995;
/// the caller does the trig, as with the direction. A raised cue sends part of the speed down into the cloth (the
/// slate bounces it back up: a jump once the rise is at least PoolParameters.minimumHop) and tilts the side-spin axis,
/// which makes the path curve while the ball slides (masse: a left offset curves left, a right offset right).
/// `ballIndex` (21-Nov-2026) is the ball the cue strikes: 0, the default, is the pool cue ball; on tables where each
/// player has their own cue ball (five-pin, bumper pool) it is that player's ball. The solver strikes it at every
/// generation (the default 0 strikes ball 0 exactly as before). CueStrike is not part of any hash
/// and is not encoded anywhere (recordings hash their segments and events), so the default changes nothing recorded.
public struct CueStrike: Sendable {
    public var direction: Vec2
    public var speed: Double
    public var tipUp: Double
    public var tipSide: Double
    public var elevation: Double
    public var ballIndex: Int
    public init(direction: Vec2, speed: Double, tipUp: Double = 0, tipSide: Double = 0, elevation: Double = 0,
                ballIndex: Int = 0) {
        self.direction = direction.normalized; self.speed = speed; self.tipUp = tipUp; self.tipSide = tipSide
        self.elevation = elevation < 0 ? 0 : (elevation > 0.995 ? 0.995 : elevation)
        self.ballIndex = ballIndex
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
