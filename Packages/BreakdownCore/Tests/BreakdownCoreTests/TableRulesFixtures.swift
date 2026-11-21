// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Hand-built shots for the other tables' rules tests (BumperPoolRulesTests, FivePinRulesTests,
//          BarBilliardsRulesTests). A shot is written as what happened — ball contacts, pins knocked down, drops into
//          bed holes, balls flying off, balls moving to a new resting place — and turned into a Timeline and the
//          ShotFacts the rules read, with no solver involved, so each expected ruling can be read straight off the
//          test. Also the three tables' TableSpecs, with the same sizes, holes, pins and start spots as the app's table
//          files (App/Tables), which the app cannot share with the package's tests.
// SRP/DRY check: Pass - checked ShotFactsTests (its recording helpers are private to it and check the reading of a
//          shot); this one shared fixture serves all three table-rules test files instead of a copy in each.
import BreakdownLensModel
import BreakdownTimeline

enum TableShot {
    /// What happened in a shot.
    enum Happening {
        /// Two balls touched (the first is the mover).
        case contact(Double, Int, Int)
        /// A ball knocked a pin down.
        case pin(Double, ball: Int, pin: Int)
        /// A ball dropped into bed hole `hole` (pocket 6 + hole).
        case hole(Double, ball: Int, hole: Int)
        /// A ball flew over a cushion and left the table.
        case offTable(Double, ball: Int)

        var time: Double {
            switch self {
            case .contact(let t, _, _), .pin(let t, _, _), .hole(let t, _, _), .offTable(let t, _): return t
            }
        }
    }

    /// A ball standing still at `p` from `t0` to `t1`.
    static func still(_ p: Vec2, radius: Double, from t0: Double = 0, to t1: Double = .infinity) -> BallSegment {
        BallSegment(t0: t0, t1: t1, phase: .stationary, position0: p, velocity0: .zero, acceleration: .zero,
                    omega0: .zero, alphaXY: .zero, spinDecay: 9, radius: radius, orientation0: .identity)
    }

    static func impact(_ b: Int) -> ImpactBall {
        ImpactBall(ball: b, velocityBefore: Vec2(1, 0), velocityAfter: Vec2(0.5, 0), omegaBefore: .zero,
                   omegaAfter: .zero, translationalBefore: 0.085, rotationalBefore: 0, translationalAfter: 0.02,
                   rotationalAfter: 0)
    }

    /// The recording of a shot on `table` from `start` (16 positions, the parking spot for a ball not on the table):
    /// balls named in `ends` are at that place from 0.3 s on (the facts only look up where a ball is), balls that drop
    /// or fly off are gone from their time on, and the shot lasts until a second after its last happening.
    static func timeline(table: TableSpec, start: [Vec2], ends: [Int: Vec2] = [:], _ happenings: [Happening]) -> Timeline {
        let r = table.ballRadius
        var pocketTime = [Double?](repeating: nil, count: start.count)
        var events: [LensEvent] = []
        for h in happenings.sorted(by: { $0.time < $1.time }) {
            switch h {
            case let .contact(t, a, b):
                events.append(LensEvent(time: t, kind: .ballBall, point: .zero, normal: Vec2(1, 0),
                                        balls: [impact(a), impact(b)]))
            case let .pin(t, ball, pin):
                let at = table.pins.indices.contains(pin) ? table.pins[pin].center : .zero
                events.append(LensEvent(time: t, kind: .pinDown, point: at, normal: Vec2(1, 0), balls: [impact(ball)],
                                        feature: pin))
            case let .hole(t, ball, hole):
                let at = table.bedHoles.indices.contains(hole) ? table.bedHoles[hole].center : .zero
                events.append(LensEvent(time: t, kind: .pocket, point: at, normal: Vec2(1, 0), balls: [impact(ball)],
                                        pocket: TableSpec.edgePocketCount + hole))
                pocketTime[ball] = t
            case let .offTable(t, ball):
                events.append(LensEvent(time: t, kind: .phaseTransition, point: .zero, normal: Vec2(0, -1),
                                        balls: [impact(ball)], phaseFrom: .airborne, phaseTo: .stationary,
                                        flight: .offTable))
                // The solver sets a pocket time for a ball that leaves the table too.
                pocketTime[ball] = t
            }
        }
        let segments: [[BallSegment]] = start.indices.map { b in
            if let end = ends[b] { return [still(start[b], radius: r, to: 0.3), still(end, radius: r, from: 0.3)] }
            return [still(start[b], radius: r)]
        }
        let duration = (happenings.map(\.time).max() ?? 0) + 1
        return Timeline(table: table, seed: 1, parameterHash: 1, segments: segments, events: events,
                        pocketTime: pocketTime, duration: duration)
    }

    /// The facts of that shot, read with `cueBall` as the struck ball.
    static func facts(table: TableSpec, start: [Vec2], cueBall: Int, ends: [Int: Vec2] = [:],
                      _ happenings: [Happening]) -> ShotFacts {
        ShotFacts(timeline: timeline(table: table, start: start, ends: ends, happenings), start: start, cueBall: cueBall)
    }

    static let off = ShotFacts.offTable
    static func empty() -> [Vec2] { [Vec2](repeating: off, count: 16) }

    // MARK: The three tables (the same numbers as App/Tables)

    /// Bumper pool: 45.5 x 30 in, 2-1/8 in balls, the near cup (bed hole 0) and the far cup (bed hole 1) 140 mm from
    /// the end cushions, twelve 1 in bumpers.
    static var bumperPool: TableSpec {
        let inch = 0.0254, L = 45.5 * inch, W = 30.0 * inch, mid = Vec2(L / 2, W / 2)
        var posts: [Post] = []
        for x in [0.140 + 0.020, L - 0.140 - 0.020] {
            posts.append(Post(center: Vec2(x, mid.y - 0.075), radius: inch))
            posts.append(Post(center: Vec2(x, mid.y + 0.075), radius: inch))
        }
        for d in [0.082, 0.180] {
            posts += [Post(center: Vec2(mid.x - d, mid.y), radius: inch), Post(center: Vec2(mid.x + d, mid.y), radius: inch),
                      Post(center: Vec2(mid.x, mid.y - d), radius: inch), Post(center: Vec2(mid.x, mid.y + d), radius: inch)]
        }
        let holes = [0.140, L - 0.140].map { BedHole(center: Vec2($0, W / 2), radius: 2.488 * inch / 2, captureRadius: 0.018) }
        return TableSpec(length: L, width: W, ballRadius: 2.125 * inch / 2, pockets: [], pocketCaptureRadius: [],
                         pocketsEnabled: false, posts: posts, bedHoles: holes)
    }

    /// Bumper pool's start: each side's marked ball in front of its own cup, the other four either side of it.
    static var bumperPoolStart: [Vec2] {
        let t = bumperPool
        var l = empty()
        let near = [0, 1, 2, 3, 4], far = [9, 10, 11, 12, 13]
        l[near[0]] = Vec2(0.220, t.width / 2)
        l[far[0]] = Vec2(t.length - 0.220, t.width / 2)
        for (i, dy) in [-0.260, -0.170, 0.170, 0.260].enumerated() {
            l[near[1 + i]] = Vec2(0.140, t.width / 2 + dy)
            l[far[1 + i]] = Vec2(t.length - 0.140, t.width / 2 + dy)
        }
        return l
    }

    /// Five-pin: 2.84 x 1.42 m, 61.5 mm balls, the castle on the centre spot (pin 0 red in the middle, four white pins
    /// 66 mm away), contact radius 2.4 mm.
    static var fivePin: TableSpec {
        let c = Vec2(1.42, 0.71), s = 0.066
        let pins = [c, Vec2(c.x - s, c.y), Vec2(c.x + s, c.y), Vec2(c.x, c.y - s), Vec2(c.x, c.y + s)]
            .map { Pin(center: $0, radius: 0.0024, mass: 0.001) }
        return TableSpec(length: 2.84, width: 1.42, ballRadius: 0.03075, pockets: [], pocketCaptureRadius: [],
                         pocketsEnabled: false, pins: pins)
    }

    /// Five-pin's spots: the white's start, the yellow's spot 10 cm from the far cushion, the red's three quarters up.
    static let fivePinSpots: [Int: Vec2] = [0: Vec2(1.38, 0.20), 1: Vec2(2.74, 0.71), 3: Vec2(2.13, 0.71)]

    static var fivePinStart: [Vec2] {
        var l = empty()
        for (b, p) in fivePinSpots { l[b] = p }
        return l
    }

    /// Bar billiards: 1.42 x 0.80 m, 47.6 mm balls, nine holes (200, 100, 50, 50, then the far row), three skittles
    /// (0 black in front of the 200, 1 and 2 white level with the 100).
    static var barBilliards: TableSpec {
        let L = 1.42, W = 0.80
        func hole(_ d: Double, _ a: Double) -> BedHole {
            BedHole(center: Vec2(L - d, W / 2 + a), radius: 0.0275, captureRadius: 0.022)
        }
        let holes = [hole(0.700, 0), hole(0.330, 0), hole(0.520, -0.250), hole(0.520, 0.250), hole(0.090, -0.300),
                     hole(0.090, -0.150), hole(0.090, 0), hole(0.090, 0.150), hole(0.090, 0.300)]
        let pins = [Pin(center: Vec2(holes[0].center.x - 0.0275 - 0.006 - 0.0195, W / 2), radius: 0.009, mass: 0.025),
                    Pin(center: Vec2(holes[1].center.x, W / 2 - 0.178), radius: 0.009, mass: 0.025),
                    Pin(center: Vec2(holes[1].center.x, W / 2 + 0.178), radius: 0.009, mass: 0.025)]
        return TableSpec(length: L, width: W, ballRadius: 0.0238125, pockets: [], pocketCaptureRadius: [],
                         pocketsEnabled: false, pins: pins, bedHoles: holes)
    }

    static let dSpot = Vec2(0.300, 0.40)
    static let redSpot = Vec2(0.529, 0.40)

    /// Bar billiards' start: a white (ball 0) on the D, the red on its spot, the other whites in the tray.
    static var barBilliardsStart: [Vec2] {
        var l = empty()
        l[0] = dSpot
        l[3] = redSpot
        return l
    }
}
