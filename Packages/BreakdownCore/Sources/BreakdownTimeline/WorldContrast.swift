// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: The facts behind "Same shot, every surface" (0.7.7, plans/23-Nov-2026-every-world-plan.md Build step 2): the
//          same stroke solved on two playing surfaces, compared, so the game can say one plain, true sentence about
//          the most striking difference. WorldOutcome reads what one recording did with the struck ball (how far and
//          how it travelled, the ball it met first, whether it dropped) and which object balls dropped. WorldContrast
//          names the first difference that holds between the surface the shot was played on ("home") and another one,
//          in a fixed order (a ball that now drops, a struck ball that never settles into a roll, a first contact lost
//          or changed, a drop lost, the struck ball's own drop, a far longer or shorter travel, a far longer time
//          moving, or nothing worth saying), and `headline` picks the one surface the sentence about the whole fan is
//          about. The thresholds are named constants with their reasons below.
//          Pure and Sendable, no rules attached: built off the main actor by App/EveryWorldFan.swift right after each
//          surface's solve, and read by the fan's words (App/EveryWorldWords.swift), which turn a contrast into a
//          sentence. Foundation is used only for log (the "strongest within a key" measure).
// SRP/DRY check: Pass - checked ShotFacts (first contact, drops and the struck ball's pocket are read through it, not
//          scanned again), BallTravel (the distance, skid share and stop time), TimelineFork (where two futures of one
//          stroke part; it does not rank differences for a sentence) and the app's RetryComparison (compares two
//          tries' settings and results for the retry card, on one surface). Nothing else compares surfaces.
import BreakdownLensModel
import Foundation

/// What one recording of a shot did, as far as the surface comparison needs it.
public struct WorldOutcome: Sendable, Equatable {
    /// The ball the player struck.
    public let struckBall: Int
    /// How the struck ball travelled.
    public let travel: BallTravel
    /// The first ball the struck ball touched; nil when it touched none.
    public let firstContact: Int?
    /// Object balls that dropped, in the order they dropped (ball numbers, ShotFacts.objectBallsPocketed's balls).
    public let dropped: [Int]
    /// The struck ball dropped into a pocket or a hole in the bed (ShotFacts.cueBallPocketed: NOT cueBallScratched,
    /// which also counts a ball that flew off the table).
    public let struckPocketed: Bool

    /// The memberwise form, for hand-made outcomes in the tests.
    public init(struckBall: Int, travel: BallTravel, firstContact: Int?, dropped: [Int], struckPocketed: Bool) {
        self.struckBall = struckBall; self.travel = travel; self.firstContact = firstContact
        self.dropped = dropped; self.struckPocketed = struckPocketed
    }

    /// Reads a recording: `start` is the layout it began from, `cueBall` the ball the player struck.
    public init(timeline: Timeline, start: [Vec2], cueBall: Int) {
        let facts = ShotFacts(timeline: timeline, start: start, cueBall: cueBall)
        self.init(struckBall: cueBall, travel: BallTravel(timeline: timeline, ball: cueBall),
                  firstContact: facts.firstContact?.ball, dropped: facts.objectBallsPocketed.map(\.ball),
                  struckPocketed: facts.cueBallPocketed)
    }
}

/// The first difference that holds between the shot as played ("home") and the same stroke on another surface, in
/// the order the sentence checks them. Every value is read from the two recordings; nothing is guessed.
public enum WorldContrast: Sendable, Equatable {
    /// A ball drops on the other surface that stayed out at home (the first such ball).
    case gainsDrop(ball: Int)
    /// The struck ball never settles into a roll there: it skids almost all of `distance` metres.
    case neverRolls(distance: Double)
    /// The struck ball never reaches the ball it hit first at home.
    case neverReaches(ball: Int)
    /// The struck ball meets `ball` first there, not `insteadOf` (home's first ball).
    case meetsOther(ball: Int, insteadOf: Int)
    /// The struck ball reaches `ball` there, where at home it touched nothing.
    case reaches(ball: Int)
    /// A ball that dropped at home stays out there (the first such ball).
    case losesDrop(ball: Int)
    /// The struck ball drops into a pocket there and stayed up at home.
    case struckDrops
    /// The struck ball stays on the table there and dropped at home.
    case struckStaysUp
    /// The struck ball travels `world` metres there against `home` metres here (far longer or far shorter).
    case travel(world: Double, home: Double)
    /// The struck ball keeps moving for `world` seconds there against `home` seconds here (far longer).
    case lasts(world: Double, home: Double)
    /// Nothing above: the two play much the same.
    case alike

    /// The case's place in the order: the earliest rank is the most striking kind of difference. Cases that share a
    /// rank are the two sides of one question (which ball is met first; does the struck ball drop).
    public var rank: Int {
        switch self {
        case .gainsDrop: return 1
        case .neverRolls: return 2
        case .neverReaches: return 3
        case .meetsOther, .reaches: return 4
        case .losesDrop: return 5
        case .struckDrops, .struckStaysUp: return 6
        case .travel: return 7
        case .lasts: return 8
        case .alike: return 9
        }
    }

    // MARK: Thresholds

    /// "Never settles into a roll" needs the struck ball to skid at least this share of its travel there: a ball that
    /// rolls for a tenth of its path has, to the eye, slid the whole way.
    public static let neverRollsShare = 0.9
    /// ... and at most this share at home, so the sentence describes a real change: on cloth a stun shot into a ball
    /// also skids nearly all the way, and saying it of both surfaces would not be a difference.
    public static let homeRollsShare = 0.6
    /// Distances shorter than this (metres) are too small to talk about: under a foot of travel, a skid or a change of
    /// length is hard to see at the table's scale.
    public static let minTravel = 0.3
    /// "Travels much farther" or "much shorter" needs at least this ratio either way: under double, two paths of a
    /// fan look about the same length.
    public static let travelRatio = 2.0
    /// "Keeps moving much longer" needs at least this many seconds more (and double the time): a ball that rolls a
    /// second longer is not something a player notices on a replay.
    public static let minLonger = 2.0

    // MARK: Reading

    /// The first case that holds between home and another surface (see the case order above).
    public static func key(home: WorldOutcome, world: WorldOutcome) -> WorldContrast {
        // 1. A ball drops there that stayed out here.
        if let b = world.dropped.first(where: { !home.dropped.contains($0) }) { return .gainsDrop(ball: b) }
        // 2. The struck ball never settles into a roll there, where it did here.
        if world.travel.distance >= minTravel, world.travel.skidShare >= neverRollsShare,
           home.travel.skidShare <= homeRollsShare {
            return .neverRolls(distance: world.travel.distance)
        }
        // 3 and 4. The first ball met.
        switch (home.firstContact, world.firstContact) {
        case let (h?, nil): return .neverReaches(ball: h)
        case let (h?, w?) where h != w: return .meetsOther(ball: w, insteadOf: h)
        case let (nil, w?): return .reaches(ball: w)
        default: break
        }
        // 5. A ball that dropped here stays out there.
        if let b = home.dropped.first(where: { !world.dropped.contains($0) }) { return .losesDrop(ball: b) }
        // 6. The struck ball's own drop (a pocket or a hole, never a flight off the table).
        if world.struckPocketed != home.struckPocketed { return world.struckPocketed ? .struckDrops : .struckStaysUp }
        // 7. Far longer or far shorter travel, by a visible amount.
        let w = world.travel.distance, h = home.travel.distance
        if abs(w - h) >= minTravel, w >= travelRatio * h || w * travelRatio <= h {
            return .travel(world: w, home: h)
        }
        // 8. Moving far longer.
        let ws = world.travel.stopTime, hs = home.travel.stopTime
        if ws >= 2 * hs, ws - hs >= minLonger { return .lasts(world: ws, home: hs) }
        return .alike
    }

    /// Within one key, how strong the difference is, for picking the surface the fan's sentence is about: the skid
    /// share for neverRolls, the size of the ratio (|log|) for travel and lasts, 0 otherwise.
    public static func strength(of c: WorldContrast, home: WorldOutcome, world: WorldOutcome) -> Double {
        switch c {
        case .neverRolls: return world.travel.skidShare
        case let .travel(w, h): return logRatio(w, h)
        case let .lasts(w, h): return logRatio(w, h)
        case .gainsDrop, .neverReaches, .meetsOther, .reaches, .losesDrop, .struckDrops, .struckStaysUp, .alike:
            return 0
        }
    }

    /// |log(a / b)|, with both floored at a micrometre (or a microsecond) so a ball that never moved at home gives a
    /// large finite number instead of infinity.
    private static func logRatio(_ a: Double, _ b: Double) -> Double {
        abs(log(max(a, 1e-6) / max(b, 1e-6)))
    }

    /// The surface the sentence about the whole fan is about: over the solved surfaces (nil is a surface that ran too
    /// long), the earliest rank, then the strongest, then the lowest index. The caller passes the surfaces in the
    /// Surface menu's order with home left out, so a tie goes to the surface listed first. Nil when none solved; the
    /// first solved surface with `.alike` when every surface plays much the same.
    public static func headline(home: WorldOutcome, worlds: [WorldOutcome?]) -> (index: Int, contrast: WorldContrast)? {
        var best: (index: Int, contrast: WorldContrast, strength: Double)?
        for (i, world) in worlds.enumerated() {
            guard let world else { continue }
            let c = key(home: home, world: world)
            let s = strength(of: c, home: home, world: world)
            if let b = best {
                // Strictly better only: an equal rank and strength keeps the earlier index.
                if c.rank < b.contrast.rank || (c.rank == b.contrast.rank && s > b.strength) { best = (i, c, s) }
            } else {
                best = (i, c, s)
            }
        }
        return best.map { ($0.index, $0.contrast) }
    }
}
