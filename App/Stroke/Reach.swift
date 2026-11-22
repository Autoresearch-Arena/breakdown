// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The reach ladder: where the player must stand and how far they must lean for the next strike, worked out from
//          the layout, the aim, the table and the bridge length, with no body drawn (the Boss dropped drawn hands on
//          21-Nov-2026; reach is shown as a mark on the cloth and a small stance card instead). Pure numbers, no views,
//          nothing main-actor, so it is tested directly (BreakdownTests/ReachTests.swift).
//          The rungs, easiest first: a normal stance; a stretch with one foot off the floor; the cue taken behind the
//          back; sitting on the rail; and the rest (the cue ball is out of reach, or the shot already uses the
//          mechanical bridge). Apart from the rung, a ball sitting under the cue's path near the cue ball means the cue
//          has to be raised over it (the spider rest's job), which is reported with the stance.
//          How the stance is found (the walk-around choice):
//            1. The bridge hand rests on the cloth `bridge` metres behind the cue ball, on the cue line.
//            2. Standing behind the cue: the player walks round the table to where the cue line, carried on backward
//               from the bridge hand, crosses the outer edge of the rail, and stands there with the hip against it.
//               The reach is the bridge hand's distance in from that edge, along the line. The rung follows from the
//               reach: square, stretch or sitting on the rail, and past all three the rest.
//            3. Standing beside a rail: when the cue line runs close along a rail, the player may instead stand at that
//               rail beside the bridge hand, back to the rail, and take the cue behind the back. Possible only when the
//               line is within thirty degrees of the rail, the rear hand (the cue's grip) then sits near the rail's
//               outer edge where the back can carry it, and the bridge hand is within a sideways reach of that edge.
//            4. Of every way to stand that works, the easiest rung is taken (and, between two of one rung, the shorter
//               reach), so the player is always assumed to walk round to the best side.
//          Each rung has a swing factor (how much of the comfortable top swing is left) and a wobble factor (how much
//          more the rear hand wanders); StrokeModel takes them beside the bridge's own (zones, delivery). The raised cue
//          has its own pair, multiplied in. In trick shots, Behind the 8-Ball and lessons StrokeModel keeps the cost
//          inside authoredAimBound, so every authored shot stays makeable.
//          Read by: ShowpieceModel (stance, strokeBridgeLength, strokeZones and the strike's delivery), AimOverlay (the
//          bridge mark on the cloth), StanceViews (the stance card) and the retry comparison (ShotAttempt.swift).
// SRP/DRY check: Pass - checked StrokeModel (bridge lengths, the rear hand's distance and the mechanical bridge's setback
//          are read from there, not retyped), TableBuilder (its cushion depth and rail width are restated below as
//          Doubles because TableBuilder is a main-actor type; reconcile if those change), CueRig (the shaft's radius at
//          the bridge, restated for the same reason) and AimGeometry (ball contacts along a line; this asks a different
//          question, which balls lie under the cue behind the cue ball, so it does not reuse firstContact).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// The rail a player stands at: the head and foot ends (x = 0 and x = length on the table plan) and the two long rails
/// (y = 0 and y = width).
enum Rail: Equatable, Sendable, CaseIterable {
    case head, foot, longNear, longFar

    /// The rail's outward direction on the table plan.
    var outward: Vec2 {
        switch self {
        case .head: return Vec2(-1, 0)
        case .foot: return Vec2(1, 0)
        case .longNear: return Vec2(0, -1)
        case .longFar: return Vec2(0, 1)
        }
    }
}

/// Where the player stands and leans for one strike.
struct Stance: Equatable, Sendable {
    /// The reach ladder, easiest first.
    enum Rung: Int, CaseIterable, Comparable, Sendable {
        case normal, stretch, behindTheBack, sittingOnRail, rest

        static func < (a: Rung, b: Rung) -> Bool { a.rawValue < b.rawValue }

        /// Share of the cue's comfortable top swing this rung leaves. Stated assumptions (game design, not measured):
        /// a body balanced on one foot cannot drive the arm through as hard (0.85); an arm swinging across the back
        /// has a short, cramped path (0.75); sitting on the rail turns the hips and shortens it further (0.70); the
        /// mechanical rest carries the cue's front on a fixed head, and the arm, held out to the side at shoulder
        /// height to stay on the rest's line, swings well short of a square stance (0.55).
        var swingFactor: Double {
            switch self {
            case .normal: return 1
            case .stretch: return 0.85
            case .behindTheBack: return 0.75
            case .sittingOnRail: return 0.70
            case .rest: return 0.55
            }
        }

        /// How much more the rear hand wanders than in a square stance. Stated assumptions (game design, not
        /// measured): one foot off the floor sways the whole body (1.4); a stroke behind the back is made without
        /// seeing the arm (1.8); sitting on the rail twists the trunk against the line (2.2). The rest is steady: its
        /// head stands on the cloth and does not move with the body, so the rear hand wanders no more than in a square
        /// stance (1). It is long (StrokeModel.mechanicalBridge), and the longer lever already moves the tip more.
        var wobbleFactor: Double {
            switch self {
            case .normal: return 1
            case .stretch: return 1.4
            case .behindTheBack: return 1.8
            case .sittingOnRail: return 2.2
            case .rest: return 1
            }
        }
    }

    /// The rung of the ladder.
    let rung: Rung
    /// The ball the cue has to be raised over, by its index in the layout (the nearest to the cue ball when there are
    /// several); nil when the cue's path behind the cue ball is clear.
    let raisedOver: Int?
    /// Metres from the outer edge of the rail, where the player stands, to the bridge hand: along the cue line when
    /// standing behind the cue, straight in from the rail when standing beside it. Zero when the bridge hand is over
    /// the rail or beyond it.
    let reach: Double
    /// The rail the player stands at, and where on its outer edge (table plan, metres).
    let rail: Rail
    let standing: Vec2

    /// True for a square stance with a clear path: nothing to say, so the stance card stays away.
    var isNormal: Bool { rung == .normal && raisedOver == nil }

    /// The raised cue's own cost, multiplied into the rung's. Stated assumption (game design, not measured): a cue
    /// raised over a ball rests on a high, closed bridge of the fingertips, a less steady support that also shortens the
    /// comfortable swing a little (0.9 of the swing, 1.25 times the wander).
    static let raisedSwingFactor = 0.9
    static let raisedWobbleFactor = 1.25

    /// The stance's whole cost, rung and raised cue together, for StrokeModel.
    var swingFactor: Double { rung.swingFactor * (raisedOver == nil ? 1 : Self.raisedSwingFactor) }
    var wobbleFactor: Double { rung.wobbleFactor * (raisedOver == nil ? 1 : Self.raisedWobbleFactor) }

    /// The bridge the strike is played off: the rest's head when the rung is the rest, otherwise the hand bridge (the
    /// finger's or the automatic one) the stance was worked out for.
    func bridge(hand: Double) -> Double { rung == .rest ? StrokeModel.mechanicalBridge : hand }
}

enum Reach {
    // MARK: The rail (restated from TableBuilder, a main-actor type)

    /// Metres from the playing edge (the cushion's nose) to the cushion's back: TableBuilder.cushionDepth.
    static let cushionDepth = 0.045
    /// Metres of wooden rail from the cushion's back to its outer edge: TableBuilder.railWidth.
    static let railWidth = 0.155
    /// Metres from the playing edge to the outer edge of the rail, where a standing player's hip meets the table.
    static var railOuter: Double { cushionDepth + railWidth }

    // MARK: The body (stated assumptions)

    // An ordinary adult of middling height leaning over a table of ordinary height (the rail about at the top of the
    // thigh). General figures for such a body, not measurements of anyone:
    //  - the trunk, folded forward at the hip over the rail, puts the shoulder about half a metre past the rail's edge;
    //  - the bridge arm, slightly bent as a bridge is made, adds about another half metre in front of the shoulder;
    //  - laid flat along the cue with one foot lifted off the floor as a counterweight, the trunk and a straight arm
    //    together reach about 1.35 m past the edge;
    //  - with one hip up on the rail, the body pivots further over the table, about 1.55 m;
    //  - turned side-on to the table with the cue behind the back, the bridge arm reaches across in front of the body,
    //    about 0.7 m in from the edge, and the rear hand, behind the hip, stays within about 0.3 m of the rail's edge.

    /// The bridge hand's furthest reach, metres in from the rail's outer edge along the cue line, in a square stance
    /// with both feet on the floor.
    static let squareReach = 0.95
    /// The same with one foot off the floor and the body laid along the cue.
    static let stretchReach = 1.35
    /// The same sitting with one hip on the rail.
    static let sittingReach = 1.55
    /// Behind the back: how far in from the rail's outer edge the bridge hand can rest, reaching sideways.
    static let behindBackReach = 0.70
    /// Behind the back: how far from the rail's outer edge (either side) the rear hand may be, held behind the hip.
    static let behindBackRearDepth = 0.30
    /// Behind the back: the cue line runs within thirty degrees of the rail. Stored as the sine of that angle, the
    /// largest share of the line's direction that may point straight out through the rail.
    static let behindBackLineSine = 0.5

    // MARK: Under the cue (stated assumptions)

    /// The shaft's radius between the cue ball and the bridge, metres (CueRig.cueRadiusAtBridge, restated).
    static let shaftRadius = 0.00704
    /// The bridge hand on the cloth: about nine centimetres across and ten along the cue, so a ball whose edge comes
    /// within these half-sizes of the bridge's spot is under the hand.
    static let handHalfWidth = 0.045
    static let handHalfLength = 0.05

    // MARK: The stance

    /// Where the player stands and leans for a strike of the ball at `cueBall` in direction `aim` (the cue's own
    /// direction, unit or not), with the hand bridge `bridge` metres behind it (the finger's or the automatic one,
    /// StrokeModel.bridgeLength). `mechanical` is true when the shot uses the mechanical bridge: that is the rest rung
    /// whatever the reach. Nil when there is no cue ball on the table or no direction to stand behind.
    static func stance(layout: [Vec2], cueBall: Int, aim: Vec2, table: TableSpec, bridge: Double,
                       mechanical: Bool) -> Stance? {
        guard layout.indices.contains(cueBall), NextShot.isOnTable(layout[cueBall]), aim.lengthSquared > 1e-12
        else { return nil }
        let ball = layout[cueBall]
        let back = -aim.normalized
        let hand = ball + back * bridge
        // Every way to stand that works, then the easiest: the lowest rung, then the shortest reach. Standing behind
        // the cue always works (as the rest, when nothing else reaches), so there is always a choice.
        let options = [behindTheCue(hand: hand, back: back, table: table)]
            + Rail.allCases.compactMap { besideRail($0, ball: ball, hand: hand, back: back, table: table) }
        let best = options.min { ($0.rung, $0.reach) < ($1.rung, $1.reach) } ?? options[0]
        let rung: Stance.Rung = mechanical ? .rest : best.rung
        // The rest's head stands further back than a hand bridge: the cue's path to it is what must be clear.
        let support = rung == .rest ? StrokeModel.mechanicalBridge : bridge
        let over = raisedOver(layout: layout, cueBall: cueBall, back: back, bridge: support, radius: table.ballRadius)
        return Stance(rung: rung, raisedOver: over, reach: best.reach, rail: best.rail, standing: best.standing)
    }

    /// One way to stand: its rung, the reach, and where on which rail.
    struct Option: Equatable, Sendable {
        let rung: Stance.Rung
        let reach: Double
        let rail: Rail
        let standing: Vec2
    }

    /// Standing behind the cue: where the cue line, carried on backward from the bridge hand, crosses the rail's outer
    /// edge, and the rung that the reach from there needs.
    static func behindTheCue(hand: Vec2, back: Vec2, table: TableSpec) -> Option {
        let (distance, point, rail) = exit(from: hand, along: back, table: table)
        return Option(rung: rung(forReach: distance), reach: distance, rail: rail, standing: point)
    }

    /// The rung a reach along the cue line needs.
    static func rung(forReach reach: Double) -> Stance.Rung {
        if reach <= squareReach { return .normal }
        if reach <= stretchReach { return .stretch }
        if reach <= sittingReach { return .sittingOnRail }
        return .rest
    }

    /// Standing beside `rail` with the cue behind the back, when that works (see the file header, step 3); nil when it
    /// does not.
    static func besideRail(_ rail: Rail, ball: Vec2, hand: Vec2, back: Vec2, table: TableSpec) -> Option? {
        // The line must run along the rail: little of its direction points straight through it.
        guard abs(back.dot(rail.outward)) <= behindBackLineSine else { return nil }
        // The rear hand holds the cue StrokeModel.tipToRearHand behind the tip, which sits at the cue ball.
        let rear = ball + back * StrokeModel.tipToRearHand
        let handDepth = depth(hand, inside: rail, table: table)
        guard handDepth <= behindBackReach, abs(depth(rear, inside: rail, table: table)) <= behindBackRearDepth
        else { return nil }
        // The player stands at the rail's outer edge level with the rear hand (the hip it is held behind), which must
        // be alongside that rail, corners included.
        let standing = onOuterEdge(rear, of: rail, table: table)
        guard alongsideRail(standing, rail, table: table) else { return nil }
        return Option(rung: .behindTheBack, reach: max(0, handDepth), rail: rail, standing: standing)
    }

    // MARK: Geometry

    /// How far a point is inside the outer edge of a rail, metres (negative: outside it, over the floor).
    static func depth(_ p: Vec2, inside rail: Rail, table: TableSpec) -> Double {
        switch rail {
        case .head: return p.x + railOuter
        case .foot: return table.length + railOuter - p.x
        case .longNear: return p.y + railOuter
        case .longFar: return table.width + railOuter - p.y
        }
    }

    /// A point moved straight out (or in) to the outer edge of a rail.
    static func onOuterEdge(_ p: Vec2, of rail: Rail, table: TableSpec) -> Vec2 {
        p + rail.outward * depth(p, inside: rail, table: table)
    }

    /// True when a point on a rail's outer edge line lies along that rail, between its two outer corners.
    static func alongsideRail(_ p: Vec2, _ rail: Rail, table: TableSpec) -> Bool {
        switch rail {
        case .head, .foot: return p.y >= -railOuter && p.y <= table.width + railOuter
        case .longNear, .longFar: return p.x >= -railOuter && p.x <= table.length + railOuter
        }
    }

    /// Where a ray from `p` along `d` leaves the rectangle of the rails' outer edges: the distance (zero when `p` is
    /// already over the rail's edge or beyond it), the point, and the rail it crosses.
    static func exit(from p: Vec2, along d: Vec2, table: TableSpec) -> (distance: Double, point: Vec2, rail: Rail) {
        let low = -railOuter, highX = table.length + railOuter, highY = table.width + railOuter
        var best = (t: Double.infinity, rail: Rail.head)
        // Each axis the ray moves along has one edge it heads for; the nearer crossing is where it leaves.
        if d.x > 1e-12 { best = nearer(best, (highX - p.x) / d.x, .foot) }
        if d.x < -1e-12 { best = nearer(best, (low - p.x) / d.x, .head) }
        if d.y > 1e-12 { best = nearer(best, (highY - p.y) / d.y, .longFar) }
        if d.y < -1e-12 { best = nearer(best, (low - p.y) / d.y, .longNear) }
        let t = max(0, best.t)
        return (t, p + d * t, best.rail)
    }

    private static func nearer(_ a: (t: Double, rail: Rail), _ t: Double, _ rail: Rail) -> (t: Double, rail: Rail) {
        t < a.t ? (t, rail) : a
    }

    /// The nearest ball (to the cue ball) lying under the cue between the cue ball and its support, or under the
    /// bridge hand itself: a level cue at the cue ball's height would run into it, so the cue must be raised. `back`
    /// is the unit direction from the cue ball back along the cue, `bridge` the support's distance behind the cue ball.
    static func raisedOver(layout: [Vec2], cueBall: Int, back: Vec2, bridge: Double, radius: Double) -> Int? {
        let ball = layout[cueBall]
        var best: (along: Double, index: Int)?
        for (i, p) in layout.enumerated() where i != cueBall && NextShot.isOnTable(p) {
            let d = p - ball
            let along = d.dot(back)
            let across = abs(d.dot(back.perp))
            // Under the shaft: behind the cue ball, short of the support, and close enough to the line that the shaft
            // would touch it.
            let underShaft = along > 0 && along <= bridge && across < radius + shaftRadius
            // Under the bridge hand: the ball's edge within the hand's half-sizes of the bridge's spot.
            let underHand = abs(along - bridge) <= handHalfLength + radius && across < handHalfWidth + radius
            guard underShaft || underHand else { continue }
            if best == nil || along < best!.along { best = (along, i) }
        }
        return best?.index
    }
}
