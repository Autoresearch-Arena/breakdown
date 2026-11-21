// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (EightBallGroup, EightBallPocket, EightBallCall, EightBallFoul and
//          EightBallLoss moved to the BreakdownRules package module, unchanged in name and raw value, so the match
//          rules share them; their player-facing titles stay here as extensions so the string catalog keeps them.)
// PURPOSE: The data types of Behind the 8-Ball (docs/2026-11-21-behind-the-eight-ball-design.md), shared by the
//          situations (EightBallSituations), the judge (EightBallJudge), the flow (EightBallMode) and the views
//          (EightBallViews). Data and small derived values only:
//          EightBallGroup, EightBallPocket, EightBallCall, EightBallFoul, EightBallLoss - defined in BreakdownRules
//            (Packages/BreakdownCore/Sources/BreakdownRules/EightBallTypes.swift); here only their titles.
//          EightBallTable - the authoring helper: diamonds (across 0-4, along 0-8) to the solver's metres, and a
//            16-ball layout from diamond positions. Situations are always STORED in metres.
//          EightBallEscape / EightBallEscapeKind - an authored way out: the technique, the stroke (TrickSettings,
//            elevation included), the call it makes, whether it needs the bridge, its authored rating 1-5, and its
//            "On a real table" card (RealTableCard, with RealTableNumbers built from the stroke and the surface).
//          EightBallSituation - one full eight-ball table in progress: id, number, title, story, the 16 positions,
//            your group, the surface it is set on, the escapes, the lesson and the trick shots that teach it.
//          EightBallStylePoint - the five named style points.
//          EightBallVerdict - the judge's result: made as called, fouls, loss of game, difficulty, style with reasons,
//            the retry penalty, and the total and medal worked out from those (never stored separately, so they
//            cannot disagree).
//          EightBallMedal - bronze (made), silver (10 or more), gold (13 or more).
// SRP/DRY check: Pass - types only. The stroke reuses TrickSettings (TrickShots.swift) rather than a copy; the cloth
//          numbers come from PlaySurface.parameters, the same values the solver is given; off-table balls use
//          NextShot.offTable as the trick shots do.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import Foundation

// MARK: Groups, pockets, the call
//
// The types themselves (EightBallGroup, EightBallPocket, EightBallCall, EightBallFoul, EightBallLoss) live in the
// BreakdownRules package module, shared with the match rules. Their names a player reads stay here, as extensions,
// because the app's string catalog only collects String(localized:) calls written in the app's own code.

extension EightBallGroup {
    var title: String {
        switch self {
        case .solids: return String(localized: "Solids")
        case .stripes: return String(localized: "Stripes")
        }
    }
}

extension EightBallPocket {
    var title: String {
        switch self {
        case .headLeft: return String(localized: "Head-left corner")
        case .headRight: return String(localized: "Head-right corner")
        case .leftSide: return String(localized: "Left side pocket")
        case .rightSide: return String(localized: "Right side pocket")
        case .footLeft: return String(localized: "Foot-left corner")
        case .footRight: return String(localized: "Foot-right corner")
        }
    }
}

// MARK: Authoring in diamonds

/// The design describes tables in diamonds; the solver works in metres. Use this when writing a situation, and store
/// the result (metres) in EightBallSituation.setup.
enum EightBallTable {
    /// One diamond: an eighth of the table's length (and a quarter of its width), in metres.
    static let diamond = 2.54 / 8

    /// Across 0 (left long rail) to 4 (right long rail), along 0 (head rail) to 8 (foot rail), to solver metres.
    static func point(across: Double, along: Double) -> Vec2 {
        Vec2(along * diamond, (4 - across) * diamond)
    }

    /// Sixteen positions (index 0 the cue ball, 8 the 8-ball) from diamond positions; every ball not named is off the
    /// table (pocketed).
    static func layout(cue: (Double, Double), eight: (Double, Double), balls: [Int: (Double, Double)]) -> [Vec2] {
        var out = [Vec2](repeating: NextShot.offTable, count: 16)
        out[0] = point(across: cue.0, along: cue.1)
        out[8] = point(across: eight.0, along: eight.1)
        for (k, v) in balls where k > 0 && k < 16 && k != 8 { out[k] = point(across: v.0, along: v.1) }
        return out
    }
}

// MARK: Escapes and the real-table card

enum EightBallEscapeKind: String, CaseIterable, Sendable {
    case kick, bank, jump, masse, swerve, bridge, combination, carom, safety

    var title: String {
        switch self {
        case .kick: return String(localized: "Kick")
        case .bank: return String(localized: "Bank")
        case .jump: return String(localized: "Jump")
        case .masse: return String(localized: "Massé")
        case .swerve: return String(localized: "Swerve")
        case .bridge: return String(localized: "Bridge shot")
        case .combination: return String(localized: "Combination")
        case .carom: return String(localized: "Carom")
        case .safety: return String(localized: "Safety")
        }
    }

    /// Jump, massé and swerve count as hard technique for style; a kick does only off two or more rails (see rails).
    var isHardTechnique: Bool { self == .jump || self == .masse || self == .swerve }
}

/// The real numbers behind a stroke, kept beside the plain words on the card (they are part of the appeal).
struct RealTableNumbers: Equatable {
    /// Aim, degrees counter-clockwise from the long axis (the solver's own convention).
    var aimDegrees: Double
    /// Launch speed of the cue ball, metres per second.
    var speed: Double
    /// Cue raised above level, degrees (0 for a level cue).
    var elevationDegrees: Double
    /// Tip offsets from the cue ball's centre, metres (up is follow, right is right side).
    var tipUp: Double
    var tipSide: Double
    /// The cloth the shot was set on, and its numbers as the solver used them.
    var surface: PlaySurface
    var slidingFriction: Double
    var rollingResistance: Double
    var cushionRestitution: Double

    init(settings s: TrickSettings, surface: PlaySurface) {
        aimDegrees = s.aim
        speed = s.power
        // elevation is the sine of the cue's angle (the solver's unit); the card shows degrees.
        elevationDegrees = asin(min(max(s.elevation ?? 0, 0), 1)) * 180 / .pi
        tipUp = s.tipUp
        tipSide = s.tipSide
        self.surface = surface
        let p = surface.parameters
        slidingFriction = p.slidingFriction
        rollingResistance = p.rollingResistance
        cushionRestitution = p.cushionRestitution
    }
}

/// "On a real table": how to play this escape standing at a real table. Short plain words, informal "you".
struct RealTableCard: Equatable {
    /// Where to aim in table terms: diamonds for kicks and banks, the ball's edge or the gap for jumps and massés.
    var aim: String
    /// How the cue is held: level, raised (with the angle), steep, or on the bridge.
    var cue: String
    /// How hard, as a felt comparison ("about a firm lag"); the m/s figure is in numbers.
    var speed: String
    /// The commonest miss for this escape.
    var commonMiss: String
    var numbers: RealTableNumbers
}

/// One authored way out of a situation.
struct EightBallEscape: Identifiable, Equatable {
    /// Unique within its situation ("A", "B", "C" as in the design).
    let id: String
    /// Short generic name ("One-rail kick", "Jump the 8").
    let title: String
    let kind: EightBallEscapeKind
    /// Further techniques stacked in the same shot (a kick then a bank, a jump then a carom); empty for one technique.
    let alsoUses: [EightBallEscapeKind]
    /// Rails the cue ball takes before its first contact (a two-rail kick is 2); 0 for none.
    let rails: Int
    /// The authored stroke (aim degrees, speed m/s, tip offsets, elevation as a sine; nil elevation is a level cue).
    let settings: TrickSettings
    /// What this escape calls: a ball in a pocket, or Safety.
    let call: EightBallCall
    /// Needs the mechanical bridge (reach, or reach and elevation together).
    let usesBridge: Bool
    /// The authored difficulty rating, 1 to 5, shown before the shot (the measured rating may move one from it).
    let rating: Int
    let card: RealTableCard
}

// MARK: Situations

/// One full eight-ball table in progress, both groups and the 8 on it, with the player hooked.
struct EightBallSituation: Identifiable, Equatable {
    let id: String
    let number: Int
    let title: String
    /// The one-line story ("You're on solids with two left...").
    let story: String
    /// Sixteen positions in solver METRES (index 0 the cue ball, 8 the 8); pocketed balls at NextShot.offTable.
    /// Write them with EightBallTable.layout(cue:eight:balls:) from the design's diamonds.
    let setup: [Vec2]
    /// The player's group.
    let group: EightBallGroup
    /// The cloth the situation is set on (most are .cloth; some are .tournament or .diveBar on purpose).
    let surface: PlaySurface
    let escapes: [EightBallEscape]
    /// The lesson, one or two sentences, for the card after the shot.
    let lesson: String
    /// Trick-shot ids (TrickShots.all) that teach the escapes.
    let taughtBy: [String]

    /// Your balls still on the table.
    var yourBallsLeft: [Int] { group.balls.filter { NextShot.isOnTable(setup[$0]) } }
    /// True when your group is cleared and the 8 is your legal ball.
    var onTheEight: Bool { yourBallsLeft.isEmpty }
    /// The balls you may legally hit first.
    var legalBalls: [Int] { onTheEight ? [8] : yourBallsLeft }
    /// The bridge appears when any authored escape needs it.
    var usesBridge: Bool { escapes.contains { $0.usesBridge } }
    /// The highest authored rating, the cap for a route nobody authored.
    var topRating: Int { escapes.map(\.rating).max() ?? 1 }
}

// MARK: What the judge finds

/// A foul scores zero for the attempt (design 1.3). The type is in BreakdownRules; its words are here.
extension EightBallFoul {
    var title: String {
        switch self {
        case .scratch: return String(localized: "Scratch")
        case .wrongBallFirst: return String(localized: "Wrong ball first")
        case .noBallHit: return String(localized: "No ball hit")
        case .noRailAfterContact: return String(localized: "No rail after contact")
        case .objectBallOffTable: return String(localized: "Ball off the table")
        case .cueOrBridgeTouchedBall: return String(localized: "Cue or bridge touched a ball")
        case .doubleHit: return String(localized: "Double hit")
        case .illegalJump: return String(localized: "Scooped jump")
        }
    }
}

/// Loss of game on the 8: the challenge is failed and scores zero (design 1.4). The type is in BreakdownRules.
extension EightBallLoss {
    var title: String {
        switch self {
        case .eightOnFoul: return String(localized: "You pocketed the 8 on a foul")
        case .eightEarly: return String(localized: "You pocketed the 8 too early")
        case .eightWrongPocket: return String(localized: "The 8 went in the wrong pocket")
        case .eightOffTable: return String(localized: "The 8 left the table")
        }
    }
}

/// One point each, capped at 5 (design 2.4).
enum EightBallStylePoint: String, CaseIterable, Sendable {
    case hardTechnique, stacked, threaded, shape, forTheGame

    var title: String {
        switch self {
        case .hardTechnique: return String(localized: "Hard technique")
        case .stacked: return String(localized: "Two techniques in one")
        case .threaded: return String(localized: "Threaded the gap")
        case .shape: return String(localized: "Shape on your next ball")
        case .forTheGame: return String(localized: "For the game")
        }
    }
}

enum EightBallMedal: Int, CaseIterable, Comparable, Sendable {
    case bronze = 1, silver, gold

    static let silverAt = 10
    static let goldAt = 13

    var title: String {
        switch self {
        case .bronze: return String(localized: "Bronze")
        case .silver: return String(localized: "Silver")
        case .gold: return String(localized: "Gold")
        }
    }

    static func < (a: EightBallMedal, b: EightBallMedal) -> Bool { a.rawValue < b.rawValue }
}

/// The judge's result for one attempt. Total and medal are worked out from the parts.
struct EightBallVerdict: Equatable {
    static let madePoints = 5
    static let legalMissPoints = 1
    static let safetyPoints = 3
    static let maxDifficulty = 5
    static let maxStyle = 5
    static let maxTries = 3

    var call: EightBallCall
    /// The called ball dropped in the called pocket with no foul and no loss.
    var madeAsCalled = false
    var fouls: [EightBallFoul] = []
    var loss: EightBallLoss?
    /// 1 to 5 when made as called, otherwise 0.
    var difficulty = 0
    /// The named style points earned (the total counts at most 5).
    var style: [EightBallStylePoint] = []
    /// A declared safety that left the opponent with no direct shot (scores 3 instead of 1).
    var safetyLeftHooked = false
    /// The authored escape the shot matched, if any (EightBallEscape.id).
    var matchedEscape: String?
    /// The stroke sat in the outer quarter of a window: difficulty already lowered by one, style zeroed.
    var nearEdge = false
    /// The called ball dropped after a kiss no authored route uses: counts, but difficulty 1 and no style.
    var fluke = false
    /// 1 for the first try, 2 and 3 for retries (each costs a point); beyond maxTries the shot is practice.
    var tryNumber = 1
    /// One short sentence for the card.
    var line = ""

    var fouled: Bool { !fouls.isEmpty }
    var gameLost: Bool { loss != nil }
    var legal: Bool { !fouled && !gameLost }
    var isPractice: Bool { tryNumber > Self.maxTries }

    var stylePoints: Int { min(style.count, Self.maxStyle) }
    var retryPenalty: Int { max(0, min(tryNumber, Self.maxTries) - 1) }

    /// Before the retry penalty: 5 + difficulty + style for a make, 3 or 1 for a legal safety or miss, 0 otherwise.
    var basePoints: Int {
        guard legal else { return 0 }
        if madeAsCalled { return Self.madePoints + difficulty + stylePoints }
        if call == .safety && safetyLeftHooked { return Self.safetyPoints }
        return Self.legalMissPoints
    }

    var total: Int { max(0, basePoints - retryPenalty) }

    /// Bronze for making it, silver at 10, gold at 13. No medal for a miss, a safety or practice.
    var medal: EightBallMedal? {
        guard madeAsCalled, legal, !isPractice else { return nil }
        if total >= EightBallMedal.goldAt { return .gold }
        if total >= EightBallMedal.silverAt { return .silver }
        return .bronze
    }

    /// Watching the authored escape first caps that challenge's style (design decision 6).
    static let hintStyleCap = 2
    func cappingStyle(at cap: Int) -> EightBallVerdict {
        var v = self
        if v.style.count > cap { v.style = Array(v.style.prefix(cap)) }
        return v
    }

    /// A verdict that scores nothing and finds nothing: what the judge stub returns.
    static func neutral(call: EightBallCall, tryNumber: Int) -> EightBallVerdict {
        EightBallVerdict(call: call, tryNumber: tryNumber)
    }
}
