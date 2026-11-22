// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 rules-lens, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          item 1: three more readings for the "ball in hand behind the head line" rule, with no rule attached:
//          firstContactStarts (where each ball the cue ball touched first started), cueBallFarthestBeforeContact (the
//          farthest the cue ball got along the table's length before that first contact, worked out exactly from the
//          recorded segments) and tableLength (the recorded table's length, so the rules can place the head line
//          without the physics module). Additive only: no existing field changes.)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-rules) - appended ballContacts: every ball-to-ball contact
//          of the shot, in time order, and touched(_:_:), because five-pin scores the opponent's ball hitting the red,
//          which is not a contact of the cue ball. Additive only: no existing field changes.
// PURPOSE: One shared reading of a recorded shot: "what happened", with no rules attached, for every set of rules
//          (the Behind the 8-Ball judge, eight-ball, nine-ball and the other tables' games). Built from a Timeline and
//          the layout the shot started from; it never re-solves anything. It reports:
//            - the first ball the cue ball touched and when (with every ball touched within `sameInstant` of that, so
//              rules can break a tie their own way: firstContact(preferring:) counts a legal ball first);
//            - every ball pocketed, in order, with its pocket (0 to 5 edge pockets, 6 + j bed hole j) and time, and the
//              bed-hole drops separately with their hole number;
//            - whether the cue ball was pocketed, flew off the table, or either (a scratch);
//            - every object ball that flew off the table;
//            - whether, after the first contact, any ball reached a rail or dropped or left the table (the "rail after
//              contact" test of a legal pool shot), and which balls reached a rail, so rules can count object balls
//              driven to a rail on a break;
//            - where every ball came to rest (the off-table parking spot for a ball that is gone);
//            - pins knocked down, in order, with the ball that did it; posts touched; balls that skipped over a hole;
//            - where each first-touched ball started, how far along the table's length the cue ball got before it
//              touched anything, and the table's length (eight-ball's head-line foul reads these three).
//          "The cue ball" is a parameter (default ball 0), so tables where each player strikes their own ball work.
//          Read by App/EightBall/EightBallJudge.swift (its first-contact, rail-after-contact, scratch and off-table
//          checks) and by the match rules in the BreakdownRules module.
// SRP/DRY check: Pass - checked EightBallJudge.swift (whose private firstContact and railAfterContact this replaces,
//          number for number), TrickShotJudge.swift, Timeline.swift (pinFalls, flewOffTable, pocketTime are reused,
//          not recomputed) and NextShot.swift (its off-table parking spot (-1, -1) is mirrored here because this
//          module sits below the physics module and cannot import it).
import BreakdownLensModel

public struct ShotFacts: Sendable, Equatable {
    /// Two first contacts of the cue ball closer in time than this are "at the same instant" (the solver has exact
    /// times, so this stands in for "one step"). Moved here from the Behind the 8-Ball judge, same value.
    public static let sameInstant = 1e-5
    /// A rail contact counts as "reaching a rail" only if the ball has moved at least this far (metres) from where it
    /// started: a ball frozen on a rail that is pushed into it has not left the rail and come back. Same value as the
    /// judge always used.
    public static let railMoveMinimum = 0.002
    /// Where the solver parks a ball that is not on the table: the same spot as NextShot.offTable.
    public static let offTable = Vec2(-1, -1)
    /// True when a position is a real spot on the table rather than the parking spot (NextShot.isOnTable's test).
    public static func isOnTable(_ p: Vec2) -> Bool { p.x >= 0 }

    /// A ball and a time.
    public struct Contact: Sendable, Equatable {
        public var ball: Int
        public var time: Double
        public init(ball: Int, time: Double) { self.ball = ball; self.time = time }
    }

    /// A ball dropping into (or skipping over) a pocket or bed hole. `pocket` is the solver's index: 0 to 5 edge
    /// pockets, 6 + j bed hole j. `entry` is the speed and angle it came in at (generation two only, else nil).
    public struct Drop: Sendable, Equatable {
        public var ball: Int
        public var pocket: Int
        public var time: Double
        public var entry: PocketEntry?
        public init(ball: Int, pocket: Int, time: Double, entry: PocketEntry? = nil) {
            self.ball = ball; self.pocket = pocket; self.time = time; self.entry = entry
        }
        /// True for a hole in the bed rather than an edge pocket.
        public var isBedHole: Bool { pocket >= TableSpec.edgePocketCount }
    }

    /// A ball dropping into a hole in the bed: `hole` is its index in TableSpec.bedHoles (pocket 6 + hole).
    public struct HoleDrop: Sendable, Equatable {
        public var ball: Int
        public var hole: Int
        public var time: Double
        public init(ball: Int, hole: Int, time: Double) { self.ball = ball; self.hole = hole; self.time = time }
    }

    /// A pin knocked down: which pin (index in TableSpec.pins), the ball that did it, when, and its place in the order
    /// the pins fell (0 is the first).
    public struct PinKnock: Sendable, Equatable {
        public var pin: Int
        public var ball: Int
        public var time: Double
        public var order: Int
        public init(pin: Int, ball: Int, time: Double, order: Int) {
            self.pin = pin; self.ball = ball; self.time = time; self.order = order
        }
    }

    /// Two balls touching: the first and second ball as the event lists them, and when.
    public struct BallPair: Sendable, Equatable {
        public var first: Int
        public var second: Int
        public var time: Double
        public init(first: Int, second: Int, time: Double) { self.first = first; self.second = second; self.time = time }
        /// True when this contact is between `a` and `b`, in either order.
        public func involves(_ a: Int, _ b: Int) -> Bool { (first == a && second == b) || (first == b && second == a) }
    }

    /// A ball touching a fixed post: which post (index in TableSpec.posts), which ball, when.
    public struct PostTouch: Sendable, Equatable {
        public var post: Int
        public var ball: Int
        public var time: Double
        public init(post: Int, ball: Int, time: Double) { self.post = post; self.ball = ball; self.time = time }
    }

    /// The ball the player struck (0 on a pool table).
    public let cueBall: Int
    /// How many balls the recording holds.
    public let ballCount: Int
    /// When the cue ball first touched another ball; nil when it touched none.
    public let firstContactTime: Double?
    /// Every ball the cue ball touched within `sameInstant` of its first contact, in event order. The first entry is
    /// the plain first contact; rules that must count a legal ball first in a tie use firstContact(preferring:).
    public let firstContactBalls: [Int]
    /// Every ball pocketed (edge pockets and bed holes), in the order they dropped.
    public let pocketed: [Drop]
    /// The bed-hole drops alone, with their hole numbers (bar billiards' scoring holes, bumper pool's cups).
    public let holeDrops: [HoleDrop]
    /// The cue ball dropped into a pocket or hole.
    public let cueBallPocketed: Bool
    /// The cue ball flew over a cushion and left the table.
    public let cueBallOffTable: Bool
    /// The cue ball is gone for the next shot: pocketed or off the table (the judge's scratch test, unchanged).
    public let cueBallScratched: Bool
    /// Object balls (every ball but the cue ball) that were on the table at the start and flew off it, ball order.
    public let objectBallsOffTable: [Int]
    /// After the first contact some ball reached a rail (having moved to get there), dropped, or left the table.
    /// This is the pool rule's "rail after contact" (a pocketed ball satisfies it). False when nothing was touched.
    public let railOrPocketAfterContact: Bool
    /// Every ball (the cue ball included) that reached a straight rail (edge .rail) after the first contact, having
    /// moved at least railMoveMinimum from its start, in the order each first got there. Pocket jaws, knuckles and
    /// posts are not rails here (a ball rattling in a jaw was not driven to a rail), although a jaw or knuckle does
    /// satisfy railOrPocketAfterContact.
    public let ballsReachingRail: [Int]
    /// Where each ball came to rest; the off-table parking spot for a ball pocketed, off the table, or never on it.
    /// The same places NextShot.layout(after:) gives, except that it re-spots a scratched cue ball and this does not.
    public let resting: [Vec2]
    /// Pins knocked down, in the order they fell.
    public let pinsDown: [PinKnock]
    /// Every contact with a fixed post, in time order.
    public let postsTouched: [PostTouch]
    /// Balls that crossed a hole too fast to drop (generation two only), in time order.
    public let rimSkips: [Drop]
    /// Every ball-to-ball contact of the shot (not only the cue ball's), in time order.
    public let ballContacts: [BallPair]
    /// Where each ball of firstContactBalls started, in the same order (the parking spot for a ball the start layout
    /// does not cover). Kept per ball, not only for the first, because a rule that breaks a tie its own way
    /// (firstContact(preferring:)) must look up the start of the ball it chose. Empty when nothing was touched.
    public let firstContactStarts: [Vec2]
    /// The largest x (metres along the table's length, from the head rail) the cue ball's centre reached from the
    /// strike up to its first contact with another ball; nil when it touched no ball. Exact, not sampled: each recorded
    /// segment moves with constant acceleration, so its largest x is at one of its ends or where its x speed is zero.
    /// The head-line rule reads it: a cue ball whose largest x never passed the line never crossed it.
    public let cueBallFarthestBeforeContact: Double?
    /// The recorded table's length (Timeline.table.length), metres. The rules module cannot import the physics module
    /// where the head line is defined, so it places the line on this.
    public let tableLength: Double

    /// Reads a recorded shot.
    /// - timeline: the recording.
    /// - start: the layout the shot started from (index = ball number; the parking spot for a ball not on the table).
    /// - cueBall: the ball the player struck.
    /// - sameInstant, railMoveMinimum: the tie window and the rail-move threshold (defaults as above; the judge passes
    ///   its own, which are the same numbers).
    public init(timeline tl: Timeline, start: [Vec2], cueBall: Int = 0,
                sameInstant: Double = ShotFacts.sameInstant, railMoveMinimum: Double = ShotFacts.railMoveMinimum) {
        self.cueBall = cueBall
        ballCount = tl.ballCount
        let cueOnRecord = cueBall >= 0 && cueBall < tl.ballCount

        // First contact: the earliest ball-ball event that involves the cue ball, and every contact tied with it.
        let hits = tl.events
            .filter { e in e.kind == .ballBall && e.balls.contains { $0.ball == cueBall } }
            .sorted { $0.time < $1.time }
        let t0 = hits.first?.time
        firstContactTime = t0
        if let t0 {
            firstContactBalls = hits.prefix { $0.time <= t0 + sameInstant }
                .compactMap { e in e.balls.first { $0.ball != cueBall }?.ball }
        } else {
            firstContactBalls = []
        }
        firstContactStarts = firstContactBalls.map { b in start.indices.contains(b) ? start[b] : ShotFacts.offTable }
        tableLength = tl.table.length
        cueBallFarthestBeforeContact = t0.flatMap { ShotFacts.farthestX(of: cueBall, until: $0, in: tl) }

        // Drops, in event (time) order; bed holes listed again with their hole number.
        var drops: [Drop] = [], skips: [Drop] = [], posts: [PostTouch] = [], pairs: [BallPair] = []
        for e in tl.events {
            guard let b = e.balls.first?.ball else { continue }
            switch e.kind {
            case .ballBall where e.balls.count >= 2:
                pairs.append(BallPair(first: b, second: e.balls[1].ball, time: e.time))
            case .pocket: drops.append(Drop(ball: b, pocket: e.pocket, time: e.time, entry: e.entry))
            case .rimSkip: skips.append(Drop(ball: b, pocket: e.pocket, time: e.time, entry: e.entry))
            case .cushion where e.edge == .post: posts.append(PostTouch(post: e.feature, ball: b, time: e.time))
            default: continue
            }
        }
        pocketed = drops
        rimSkips = skips
        ballContacts = pairs
        postsTouched = posts
        holeDrops = drops.filter(\.isBedHole).map {
            HoleDrop(ball: $0.ball, hole: $0.pocket - TableSpec.edgePocketCount, time: $0.time)
        }
        pinsDown = tl.pinFalls.enumerated().map { f in
            PinKnock(pin: f.element.pin, ball: f.element.ball, time: f.element.time, order: f.offset)
        }

        // The cue ball: pocketed, off the table, or either. pocketTime is set both when a pocket takes a ball and when
        // it flies off the table, so the scratch test is exactly the one the judge always used.
        cueBallPocketed = drops.contains { $0.ball == cueBall }
        cueBallOffTable = cueOnRecord && tl.flewOffTable(cueBall)
        cueBallScratched = cueOnRecord && (tl.pocketTime[cueBall] != nil || tl.flewOffTable(cueBall))

        let known = min(start.count, tl.ballCount)
        objectBallsOffTable = (0..<known).filter { b in
            b != cueBall && ShotFacts.isOnTable(start[b]) && tl.flewOffTable(b)
        }

        // Rails after the first contact. A cushion event counts unless it is a post, names a ball the start layout
        // does not cover, or is a ball frozen on the rail that has not moved railMoveMinimum from its start. For the
        // pool rule, a pocketed ball or a ball off the table also satisfies "a rail after contact"; the list of balls
        // driven to a rail takes straight rails only.
        var railOrPocket = false
        var reached: [Int] = []
        if let t0 {
            for e in tl.events where e.time >= t0 - sameInstant {
                switch e.kind {
                case .pocket:
                    railOrPocket = true
                case .cushion:
                    guard e.edge != .post, let b = e.balls.first?.ball, b < start.count else { continue }
                    let at = tl.state(ball: b, at: e.time).position
                    if ShotFacts.isOnTable(start[b]), (at - start[b]).length < railMoveMinimum { continue }
                    // Any cushion face (rail, jaw or knuckle) satisfies the judge's "rail after contact", as it
                    // always has; only the straight rail counts as a ball driven TO a rail (the break rule).
                    railOrPocket = true
                    if e.edge == .rail, !reached.contains(b) { reached.append(b) }
                case .phaseTransition:
                    if e.flight == .offTable { railOrPocket = true }
                default:
                    continue
                }
            }
        }
        railOrPocketAfterContact = railOrPocket
        ballsReachingRail = reached

        // Resting places, as NextShot.layout reads them (without its re-spot of a scratched cue ball).
        resting = (0..<tl.ballCount).map { b in
            let s = tl.state(ball: b, at: tl.duration)
            return s.pocketed ? ShotFacts.offTable : s.position
        }
    }

    /// The largest x a ball's centre reaches from the start of the recording up to time `end`; nil when the ball is
    /// not in the recording. Every segment is position0 + v0 t + a t^2 / 2 along x (the stationary and spinning ones
    /// stand still at position0), so on [t0, min(t1, end)] the largest x is at an end of that span or at the turning
    /// point t = -v0x / ax when it lies inside. A ball that drops before `end` stops counting at its drop.
    static func farthestX(of ball: Int, until end: Double, in tl: Timeline) -> Double? {
        guard ball >= 0, ball < tl.ballCount, tl.segments.indices.contains(ball) else { return nil }
        let stop = min(end, tl.pocketTime[ball] ?? end)
        var best: Double?
        for seg in tl.segments[ball] where seg.t0 <= stop {
            let to = min(seg.t1, stop)
            var times = [seg.t0, to]
            switch seg.phase {
            case .sliding, .rolling, .airborne:
                if seg.acceleration.x != 0 {
                    let turn = seg.t0 - seg.velocity0.x / seg.acceleration.x
                    if turn > seg.t0, turn < to { times.append(turn) }
                }
            case .stationary, .spinning:
                times = [seg.t0]
            }
            for t in times {
                let x = seg.kinematics(at: t).position.x
                if best == nil || x > best! { best = x }
            }
        }
        return best
    }

    /// The first ball the cue ball touched, and when; nil when it touched none.
    public var firstContact: Contact? {
        guard let t = firstContactTime, let b = firstContactBalls.first else { return nil }
        return Contact(ball: b, time: t)
    }

    /// The first contact, with a tie inside sameInstant counted in favour of a ball in `legal` (the rules' answer when
    /// the order cannot be told). Nil when the cue ball touched nothing.
    public func firstContact(preferring legal: Set<Int>) -> Contact? {
        guard let t = firstContactTime,
              let b = firstContactBalls.first(where: { legal.contains($0) }) ?? firstContactBalls.first else { return nil }
        return Contact(ball: b, time: t)
    }

    /// Object balls that reached a rail after the first contact (the break rule counts these).
    public var objectBallsReachingRail: [Int] { ballsReachingRail.filter { $0 != cueBall } }

    /// Object balls pocketed, in order (the cue ball left out).
    public var objectBallsPocketed: [Drop] { pocketed.filter { $0.ball != cueBall } }

    /// True when balls `a` and `b` touched each other at any time in the shot.
    public func touched(_ a: Int, _ b: Int) -> Bool { ballContacts.contains { $0.involves(a, b) } }

    /// Where `ball` started, if it was one of the balls the cue ball touched first; nil otherwise.
    public func firstContactStart(of ball: Int) -> Vec2? {
        firstContactBalls.firstIndex(of: ball).map { firstContactStarts[$0] }
    }

    /// Where `ball` dropped, if it did (its first drop; a ball drops at most once in a shot).
    public func pocket(of ball: Int) -> Int? { pocketed.first { $0.ball == ball }?.pocket }
}
