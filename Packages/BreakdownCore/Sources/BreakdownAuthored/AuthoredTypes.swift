// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The types of the authored answers library (bug plan after 0.6.6, item 38). Every authored trick shot, lesson
//          and Behind the 8-Ball escape is written once, in this package module, as plain numbers: where the balls
//          start, the stroke that makes it, what it must do, and how far each setting may stray. The app's TrickShots,
//          Lessons and EightBallSituations add the words a player reads and read every number from here; the dev tool
//          (BreakProbe) checks and re-authors the very same values. Before this, the dev tool held hand copies marked
//          KEEP IN STEP, so a re-authored shot whose copy was not updated shipped unchecked.
//          Units and conventions are the app's and the solver's: table metres on the solver's plan (x along the length
//          0 to 2.54, y across 0 to 1.27), aim in degrees counter-clockwise from the long axis, power the launch speed of
//          a centre hit in metres per second, tip offsets in metres (up is follow, right is right side), elevation the
//          sine of the cue's angle above level (0 for a level cue). Pockets by solver index: 0 (0,0), 1 (2.54,0),
//          2 (0,1.27), 3 (2.54,1.27) corners; 4 (1.27,0), 5 (1.27,1.27) sides.
// SRP/DRY check: Pass - types only; the data is in AuthoredTricks, AuthoredLessons and AuthoredEscapes, the surfaces in
//          TableSurfaces. The goal test lives where it always did (the app's judges, the dev tool's passes()); this
//          module holds no logic beyond building a layout.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules

/// One stroke.
public struct AuthoredStrike: Sendable, Equatable {
    public var aim: Double
    public var power: Double
    public var tipUp: Double
    public var tipSide: Double
    /// Sine of the cue's angle above level; 0 is a level cue.
    public var elevation: Double
    public init(aim: Double, power: Double, tipUp: Double, tipSide: Double, elevation: Double = 0) {
        self.aim = aim; self.power = power; self.tipUp = tipUp; self.tipSide = tipSide; self.elevation = elevation
    }
}

/// A ball that must drop, and the pocket it must drop in (nil: any pocket).
public struct AuthoredDrop: Sendable, Equatable {
    public let ball: Int
    public let pocket: Int?
    public init(_ ball: Int, _ pocket: Int?) { self.ball = ball; self.pocket = pocket }
}

/// Where the cue ball must come to rest.
public struct AuthoredZone: Sendable, Equatable {
    public let centre: Vec2
    public let radius: Double
    public init(_ centre: Vec2, _ radius: Double) { self.centre = centre; self.radius = radius }
}

/// What a trick shot or a lesson must do, read from its recording (the cue ball must never scratch).
public struct AuthoredGoal: Sendable, Equatable {
    public var drops: [AuthoredDrop]
    public var cueZone: AuthoredZone?
    /// The ball the cue ball must touch first.
    public var firstHit: Int?
    /// For a carom, the ball the cue ball must touch on its second ball contact.
    public var secondHit: Int?
    /// A ball that must touch a cushion before it drops (a bank).
    public var bank: Int?
    public init(drops: [AuthoredDrop], cueZone: AuthoredZone? = nil, firstHit: Int? = nil, secondHit: Int? = nil,
                bank: Int? = nil) {
        self.drops = drops; self.cueZone = cueZone; self.firstHit = firstHit; self.secondHit = secondHit; self.bank = bank
    }
}

/// How far each setting can move from the answer, either way, and the shot still works: half-widths measured by
/// walking outward from the answer one small step at a time. Aim in degrees; tip values in metres; a zero tipSide
/// means side is not judged.
public struct AuthoredWindow: Sendable, Equatable {
    public var aim: Double
    public var power: Double
    public var tipUp: Double
    public var tipSide: Double
    public init(aim: Double, power: Double, tipUp: Double, tipSide: Double) {
        self.aim = aim; self.power = power; self.tipUp = tipUp; self.tipSide = tipSide
    }
}

/// Sixteen positions with only the named balls on the table; every other ball is off it (NextShot.offTable).
public func authoredLayout(_ balls: [Int: Vec2]) -> [Vec2] {
    var out = [Vec2](repeating: NextShot.offTable, count: 16)
    for (k, v) in balls where k >= 0 && k < 16 { out[k] = v }
    return out
}

/// One trick shot's numbers.
public struct AuthoredTrick: Sendable, Equatable {
    public let id: String
    /// Its number in the authoring order (the app sorts the list easiest first and shows the place in that list).
    public let number: Int
    public let layout: [Vec2]
    public let solution: AuthoredStrike
    public let goal: AuthoredGoal
    public let window: AuthoredWindow
    public let usesBridge: Bool
    /// 1 easy, 2 medium, 3 hard (the app's TrickDifficulty raw values).
    public let difficulty: Int
}

/// One lesson's numbers. A lesson that raises the cue does it to one of the angles the cue-angle control offers
/// (`cueAngle`, degrees), so the player can set it exactly; its reference elevation is that angle's sine.
public struct AuthoredLesson: Sendable, Equatable {
    public let id: String
    public let number: Int
    public let layout: [Vec2]
    public let reference: AuthoredStrike
    /// The offered cue angle of the reference, degrees; nil for a level-cue lesson.
    public let cueAngle: Int?
    public let goal: AuthoredGoal
    public let window: AuthoredWindow
    /// The run of offered cue angles in which the reference still works with everything else unchanged.
    public let cueAngles: ClosedRange<Int>?
}

/// The stop shot's second exercise: the lesson's own line from further back.
public struct AuthoredExercise: Sendable, Equatable {
    public let layout: [Vec2]
    public let reference: AuthoredStrike
    public let goal: AuthoredGoal
    public let window: AuthoredWindow
}

/// A position on the table in diamonds, as the Behind the 8-Ball design writes it: across 0 (left long rail) to 4
/// (right long rail), along 0 (head rail) to 8 (foot rail).
public struct Diamond: Sendable, Equatable {
    public let across: Double
    public let along: Double
    public init(_ across: Double, _ along: Double) { self.across = across; self.along = along }
    /// One diamond, metres: an eighth of the table's length (and a quarter of its width).
    public static let size = 2.54 / 8
    /// Solver metres (the same as the app's EightBallTable.point).
    public var point: Vec2 { Vec2(along * Diamond.size, (4 - across) * Diamond.size) }
}

/// The techniques an escape can use; raw values are the app's EightBallEscapeKind's.
public enum AuthoredEscapeKind: String, CaseIterable, Sendable {
    case kick, bank, jump, masse, swerve, bridge, combination, carom, safety
}

/// The technique test an escape is checked with by the dev tool (EightBallAuthoring.ebPasses): rails before contact
/// for a kick, a cushion for the banked ball, a take-off for a jump, a curve a level cue cannot copy for a massé or a
/// swerve, a hooking safety, or a legal touch on a named ball with nothing dropping.
public enum EscapeCheck: String, Sendable {
    case kick, bank, jump, curve, safety, touch
}

/// One authored way out of a Behind the 8-Ball situation.
public struct AuthoredEscape: Sendable, Equatable {
    public let id: String
    public let kind: AuthoredEscapeKind
    public let alsoUses: [AuthoredEscapeKind]
    /// Cushions the card names (the cue ball's before its first ball, for a kick).
    public let rails: Int
    public let strike: AuthoredStrike
    public let call: EightBallCall
    public let usesBridge: Bool
    /// Authored rating 1 to 5.
    public let rating: Int
    /// How the dev tool checks it: the technique test, the cue ball's rails before contact it accepts, and for a touch
    /// safety the ball it must touch.
    public let check: EscapeCheck
    public let railCheck: ClosedRange<Int>
    public let touchBall: Int?
}

/// One Behind the 8-Ball situation's numbers: the table in diamonds, your group, the surface, the escapes.
public struct AuthoredSituation: Sendable, Equatable {
    public let id: String
    public let number: Int
    public let cue: Diamond
    public let eight: Diamond
    public let balls: [Int: Diamond]
    public let group: EightBallGroup
    public let surface: TableSurface
    public let escapes: [AuthoredEscape]

    /// Sixteen positions in metres, index 0 the cue ball, 8 the 8-ball; every ball not named is off the table.
    public var layout: [Vec2] {
        var out = [Vec2](repeating: NextShot.offTable, count: 16)
        out[0] = cue.point
        out[8] = eight.point
        for (k, v) in balls where k > 0 && k < 16 && k != 8 { out[k] = v.point }
        return out
    }

    public func escape(_ id: String) -> AuthoredEscape? { escapes.first { $0.id == id } }
}
