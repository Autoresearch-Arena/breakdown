// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The eight-ball words every rules engine shares, moved here from App/EightBall/EightBallTypes.swift so the
//          Behind the 8-Ball judge (in the app) and the eight-ball match rules (in this module) use one set of types:
//            EightBallGroup  - solids or stripes, and the balls in each.
//            EightBallPocket - the six pockets by the names the design uses; raw value = the solver's pocket index.
//            EightBallCall   - one ball in one pocket, or Safety.
//            EightBallFoul   - what the judge (and a match) can find wrong with a shot.
//            EightBallLoss   - the four ways to lose the game on the 8.
//          Names and raw values are unchanged from the app's originals. They are Codable so a saved match can store
//          them. The words a player reads (each type's `title`) stay in the app (App/EightBall/EightBallTypes.swift),
//          as extensions, because the app's string catalog only finds String(localized:) calls in the app's own code.
// SRP/DRY check: Pass - moved, not copied: the app no longer defines these. No rule logic here.

// MARK: Groups, pockets, the call

public enum EightBallGroup: String, CaseIterable, Codable, Sendable {
    case solids, stripes

    /// The object balls in this group (the 8 is in neither).
    public var balls: [Int] {
        switch self {
        case .solids: return Array(1...7)
        case .stripes: return Array(9...15)
        }
    }

    public var other: EightBallGroup { self == .solids ? .stripes : .solids }

    public static func of(ball: Int) -> EightBallGroup? {
        switch ball {
        case 1...7: return .solids
        case 9...15: return .stripes
        default: return nil
        }
    }
}

/// The six pockets by the design's names. The player stands at the head end (solver x = 0) looking toward the foot
/// (x = 2.54). Counter-clockwise on the solver's plan is the shooter's left (the same convention as TrickShotJudge),
/// so the LEFT long rail is y = 1.27 and the RIGHT long rail is y = 0. The raw value is the solver's pocket index:
/// 0 (0,0), 1 (2.54,0), 2 (0,1.27), 3 (2.54,1.27) corners; 4 (1.27,0), 5 (1.27,1.27) sides (TrickShots.swift header).
public enum EightBallPocket: Int, CaseIterable, Codable, Sendable {
    case headRight = 0, footRight = 1, headLeft = 2, footLeft = 3, rightSide = 4, leftSide = 5
}

/// One call per shot, no hedging: a ball and a pocket, or Safety. Rails, kisses and the route are never called.
public enum EightBallCall: Equatable, Hashable, Codable, Sendable {
    case ball(Int, pocket: EightBallPocket)
    case safety

    public var ball: Int? { if case .ball(let b, _) = self { return b } else { return nil } }
    public var pocket: EightBallPocket? { if case .ball(_, let p) = self { return p } else { return nil } }
}

// MARK: What can go wrong

/// A foul (design 1.3). The first five are read from the recording (ShotFacts); the last three are worked out by the
/// Behind the 8-Ball judge from the stroke and the start, because the solver draws no cue.
public enum EightBallFoul: String, CaseIterable, Codable, Sendable {
    case scratch, wrongBallFirst, noBallHit, noRailAfterContact, objectBallOffTable, cueOrBridgeTouchedBall, doubleHit,
         illegalJump
}

/// Loss of game on the 8 (design 1.4).
public enum EightBallLoss: String, CaseIterable, Codable, Sendable {
    case eightOnFoul, eightEarly, eightWrongPocket, eightOffTable
}
