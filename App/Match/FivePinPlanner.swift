// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 table-opponent review: the aim window is measured on each
//          refined trial's points, not its value, so hard's leave term no longer hides a real scoring window.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 rules-lens, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          item 6: easy never plays a stroke it can see will
//          foul. Its plain full hit used to be played whatever lay on the line, so with the other ball straight beyond
//          the castle easy drove its own ball through the pins. Now every fallback line is checked by eye the way the
//          cut already was (its ball's path to the hit clear of the castle and of the red): the full hit first, then
//          thinner hits across the other ball, outward from the full one, then a one-cushion kick at the other ball's
//          mirror image in each cushion (both legs checked); only when every one is blocked is the full hit played.)
// PURPOSE: How the computer chooses its stroke at five-pin billiards (plans/22-Nov-2026-v074-glow-up-plan.md, feature
//          R, table-opponent brief item 5). OpponentPlanner.plan hands a five-pin snapshot here. The computer strikes
//          its own ball (the yellow, seat 1) onto the other player's, which should then knock pins down; a miss, the
//          red first, its own ball in the pins or a ball off the table gives the other player the points.
//          Medium and hard search (TableOpponentSearch) with this value for the shooter's seat s against seat o:
//            - a win +1000, a loss -1000;
//            - otherwise the shot's points for s less its points for o (FivePinRules.ruling: a foul gives o the
//              points, never fewer than 2);
//            - hard also subtracts 2 * max(0, 1 - d / 0.5 m) for its own ball coming to rest d from the castle's
//              centre (the red pin), so it does not leave its ball as the other player's easy target.
//          The fan: every half degree round the ball at 2.0, 3.0, 4.0 and 5.5 m/s, struck 7 mm below centre (the
//          reference draw, so the ball does not follow through into the pins), plus fine aims a tenth of a degree
//          apart across the other ball (every aim that can touch it: plus or minus asin(2R / d) about the line to its
//          centre), where the cut that sends it into the castle lives; the success mark is 2 points.
//          Easy plays by eye with no solves: the ghost-ball aim that sends the other ball at the castle's centre, at
//          the speed that rolls that distance times 1.4 (between 2 and 5.5 m/s); when that cut is thinner than 70
//          degrees or its ball's path to the ghost ball crosses the castle or the red ball, the first clear line of: a
//          plain full hit at 3 m/s, a thinner hit across the other ball, a one-cushion kick (see Edited above).
//          The plan's kind: .pins (expected points, clean points, whether its ball met a cushion first) when the
//          expected points are above zero, otherwise .concede; easy's is .pins with no figures.
// SRP/DRY check: Pass - the scoring is FivePinRules'; the solving, smoothing, refining and noise check are
//          TableOpponentSearch's; the clear-path test is TableLines.clear; the rolling-speed estimate is
//          OpponentPlanner.rollingLaunch; the castle is the solve parameters' red pin (PoolParameters.pins, written
//          from FivePinTable); no other file values a five-pin stroke.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation

enum FivePinPlanner {
    // MARK: The value's numbers

    static let winValue = 1000.0
    /// Hard's leave term: up to this many points off for its ball resting at the castle's centre, falling to none at
    /// leaveReach metres away.
    static let leaveWeight = 2.0
    static let leaveReach = 0.5

    // MARK: The fan

    static let speeds = [2.0, 3.0, 4.0, 5.5]
    static let step = 0.5
    /// The reference touch of draw, 7 mm below centre (EightBallJudge.referenceTipUp).
    static let tipUp = EightBallJudge.referenceTipUp
    static let extraStep = 0.1
    /// A white pin's worth (FivePinRules.whitePinPoints), struck perfectly: what the aim window is measured against,
    /// on the trial's points rather than its value (hard's leave term would otherwise pull a real score below it).
    static let successValue = Double(FivePinRules.whitePinPoints)

    // MARK: Easy, by eye

    static let easyPace = 1.4
    static let easySpeeds = 2.0...5.5
    static let easyFullHitSpeed = 3.0
    /// Cuts thinner than this, degrees, send the other ball off with too little of the speed to reach the castle.
    static let easyMaxCut = 70.0
    /// Easy's thinner hits when the full hit is blocked: aims this many degrees apart, out from the full-hit line on
    /// both sides, up to the edge of the other ball (asin(2R / d), the extraAims rule). Half the fan's step: by eye.
    static let easyFineStep = 0.25

    // MARK: Planning

    /// The computer's stroke for the snapshot's turn.
    static func plan(_ s: OpponentSnapshot) -> OpponentPlan {
        if s.level == .easy { return easyPlan(s) }
        let seat = s.state.turn.index
        let other = s.state.turn.next(among: max(s.state.players.count, 1)).index
        let own = s.rules.cueBall(for: s.state.turn, in: s.state)
        let target = targetBall(s)
        let p = s.parameters
        let castle = castleCentre(p)
        var extras: [Double] = []
        if s.layout.indices.contains(own), s.layout.indices.contains(target),
           NextShot.isOnTable(s.layout[own]), NextShot.isOnTable(s.layout[target]) {
            extras = extraAims(cue: s.layout[own], target: s.layout[target], radius: p.ballRadius, step: extraStep)
        }
        let fan = TableFan(step: step, speeds: speeds, tips: TableSearchDepth.tips(s.level, base: tipUp),
                           extraAims: extras, extraStep: extraStep)
        let hard = s.level == .hard
        let spec = TableOpponentSearch.Spec(
            fan: fan, ownCup: nil,
            value: { ruling, facts in
                FivePinPlanner.value(ruling: ruling, facts: facts, seat: seat, other: other, ownBall: own,
                                     castle: castle, leave: hard)
            },
            // Scored at least a white pin's worth: TableTrial.points is the shooter's points less the other's, so a
            // foul (which gives the other player the points) never passes. Hard's leave term is left out on purpose.
            succeeds: { $0.points >= FivePinPlanner.successValue })
        guard let found = TableOpponentSearch.search(s, spec: spec, depth: TableSearchDepth.of(s.level)) else {
            return easyPlan(s)
        }
        let t = found.trial
        guard found.expectedPoints > 0 else {
            return OpponentPlan(kind: .concede, stroke: t.stroke, placement: nil, call: nil, window: nil)
        }
        // Hard's leave line ("kept its ball away from the pins") only when the stroke, struck perfectly, really
        // leaves its ball outside the leave term's reach.
        var clearOfCastle = false
        if hard, let rest = t.facts?.resting, rest.indices.contains(own), NextShot.isOnTable(rest[own]) {
            clearOfCastle = (rest[own] - castle).length >= leaveReach
        }
        // Clean points are the computer's own points on the perfect stroke (0 if even that fouls), not the net
        // figure the search averages, so the line never shows a negative or a foul's points as its own.
        let clean = t.ruling.map { $0.points.indices.contains(seat) ? $0.points[seat] : 0 } ?? 0
        return OpponentPlan(kind: .pins(expected: found.expectedPoints, clean: clean,
                                        kick: t.railsBeforeFirstContact > 0),
                            stroke: t.stroke, placement: nil, call: nil, window: found.window,
                            leavesNextShot: clearOfCastle)
    }

    /// The other player's ball, the one the shooter must hit first.
    static func targetBall(_ s: OpponentSnapshot) -> Int {
        if let r = s.rules as? FivePinRules { return r.targetBall(for: s.state.turn) }
        let balls = FivePinRules.playerBalls
        return balls[(s.state.turn.index + 1) % balls.count]
    }

    /// The castle's centre: the red pin's spot; the middle of the table if the parameters carry no pins.
    static func castleCentre(_ p: PoolParameters) -> Vec2 {
        p.pins.indices.contains(FivePinRules.redPin) ? p.pins[FivePinRules.redPin].center
                                                     : Vec2(p.tableLength / 2, p.tableWidth / 2)
    }

    /// Every aim, `step` degrees apart, from the ball at `cue` that can touch the ball at `target`: plus or minus
    /// asin(2R / d) about the line between their centres. The sine is clamped to 1 so two touching balls give the
    /// whole half-turn rather than no number at all.
    static func extraAims(cue: Vec2, target: Vec2, radius r: Double, step: Double) -> [Double] {
        let toTarget = target - cue
        let d = toTarget.length
        guard d > 1e-9, step > 0 else { return [] }
        let centre = atan2(toTarget.y, toTarget.x) * 180 / Double.pi
        let half = asin(min(1, 2 * r / d)) * 180 / Double.pi
        let count = Int((2 * half / step).rounded(.down)) + 1
        return (0..<count).map { centre - half + Double($0) * step }
    }

    // MARK: The value

    /// The value of one solved stroke for seat `seat` against seat `other` (see the header). With `leave`, hard's
    /// leave term for `ownBall` resting near `castle`.
    static func value(ruling: Ruling, facts: ShotFacts, seat: Int, other: Int, ownBall: Int, castle: Vec2,
                      leave: Bool) -> Double {
        if let r = ruling.result {
            return r.winner?.index == seat ? winValue : -winValue
        }
        let mine = ruling.points.indices.contains(seat) ? ruling.points[seat] : 0
        let theirs = other != seat && ruling.points.indices.contains(other) ? ruling.points[other] : 0
        var v = Double(mine - theirs)
        if leave, facts.resting.indices.contains(ownBall), NextShot.isOnTable(facts.resting[ownBall]) {
            let d = (facts.resting[ownBall] - castle).length
            v -= leaveWeight * max(0, 1 - d / leaveReach)
        }
        return v
    }

    // MARK: Easy

    /// The aim, degrees, that sends the ball at `object` toward `toward` when struck from `cue`: at the ghost ball, two
    /// radii behind the object ball on the line from `toward` through it. Pure geometry, no solve.
    static func ghostAim(cue: Vec2, object: Vec2, toward: Vec2, radius r: Double) -> Double {
        let g = ghost(object: object, toward: toward, radius: r) - cue
        return atan2(g.y, g.x) * 180 / Double.pi
    }

    /// The ghost ball's centre for sending `object` toward `toward`.
    private static func ghost(object: Vec2, toward: Vec2, radius r: Double) -> Vec2 {
        let line = toward - object
        guard line.length > 1e-9 else { return object }
        return object - line.normalized * (2 * r)
    }

    /// The distance from `point` to the segment from `a` to `b`.
    private static func distance(from point: Vec2, toSegment a: Vec2, _ b: Vec2) -> Double {
        let seg = b - a
        let len2 = seg.lengthSquared
        let t = len2 > 0 ? min(max((point - a).dot(seg) / len2, 0), 1) : 0
        return (point - (a + seg * t)).length
    }

    /// Easy's stroke, by eye (see the header). No solves.
    static func easyPlan(_ s: OpponentSnapshot) -> OpponentPlan {
        let own = s.rules.cueBall(for: s.state.turn, in: s.state)
        let target = targetBall(s)
        let p = s.parameters, r = p.ballRadius
        let kind = OpponentPlan.Kind.pins(expected: 0, clean: 0, kick: false)
        guard s.layout.indices.contains(own), s.layout.indices.contains(target),
              NextShot.isOnTable(s.layout[own]), NextShot.isOnTable(s.layout[target]) else {
            return OpponentPlan(kind: kind, stroke: OpponentStroke(aimDegrees: 0, speed: easyFullHitSpeed, tipUp: tipUp),
                                placement: nil, call: nil, window: nil)
        }
        let cue = s.layout[own], obj = s.layout[target]
        let castle = castleCentre(p)
        let g = ghost(object: obj, toward: castle, radius: r)
        let toGhost = g - cue, toCastle = castle - obj
        // The cut: the angle between the struck ball's path to the ghost ball and the other ball's path onward.
        var cut = 180.0
        if toGhost.length > 1e-9, toCastle.length > 1e-9 {
            cut = acos(min(max(toGhost.normalized.dot(toCastle.normalized), -1), 1)) * 180 / Double.pi
        }
        // The castle's reach: its farthest pin plus that pin's contact radius plus a ball.
        let castleReach = (p.pins.map { ($0.center - castle).length + $0.radius }.max() ?? 0) + r
        let crossesCastle = distance(from: castle, toSegment: cue, g) < castleReach
        let red = FivePinRules.redBall
        let redInWay = s.layout.indices.contains(red) && NextShot.isOnTable(s.layout[red])
            && !TableLines.clear(from: cue, to: g, past: [red], in: s.layout, radius: r)
        if cut > easyMaxCut || crossesCastle || redInWay {
            let line = easyFallbackLine(s, cue: cue, object: obj, castle: castle, castleReach: castleReach)
            return OpponentPlan(kind: kind,
                                stroke: OpponentStroke(aimDegrees: line.aim, speed: line.speed, tipUp: tipUp),
                                placement: nil, call: nil, window: nil)
        }
        let roll = OpponentPlanner.rollingLaunch(distance: toGhost.length + toCastle.length, parameters: p)
        let speed = min(max(roll * easyPace, easySpeeds.lowerBound), easySpeeds.upperBound)
        return OpponentPlan(kind: kind,
                            stroke: OpponentStroke(aimDegrees: ghostAim(cue: cue, object: obj, toward: castle, radius: r),
                                                   speed: speed, tipUp: tipUp),
                            placement: nil, call: nil, window: nil)
    }

    /// True when a ball rolling straight from `a` to `b` stays clear of the castle (its centre never within
    /// `castleReach` of the castle's centre, the same test the cut uses) and of the red ball.
    private static func lineIsClear(_ s: OpponentSnapshot, from a: Vec2, to b: Vec2, castle: Vec2,
                                    castleReach: Double) -> Bool {
        guard distance(from: castle, toSegment: a, b) >= castleReach else { return false }
        let red = FivePinRules.redBall
        guard s.layout.indices.contains(red), NextShot.isOnTable(s.layout[red]) else { return true }
        return TableLines.clear(from: a, to: b, past: [red], in: s.layout, radius: s.parameters.ballRadius)
    }

    /// Easy's stroke when the cut is not on: the first line, by eye, along which its own ball reaches the other ball
    /// without passing through the castle or the red (lineIsClear), so it never plays a foul it can see.
    ///   1. The plain full hit at easyFullHitSpeed.
    ///   2. Thinner hits across the other ball, easyFineStep apart, nearest the full hit first (left before right at
    ///      the same offset, so the choice is the same on every run), out to where the line would miss it. The leg
    ///      checked is the one to where the two balls touch: along the aim, `along - sqrt((2R)^2 - off^2)`.
    ///   3. A one-cushion kick: the other ball mirrored in each cushion line (a radius in from the nose; five-pin has
    ///      no pockets, so no jaw to keep clear of), checked on both legs, the shortest clear path first, struck to
    ///      roll that path easyPace times over (within easySpeeds).
    ///   4. Everything blocked: the full hit after all (it may foul, but some stroke must be played).
    /// Returns the aim (degrees) and the speed (m/s).
    static func easyFallbackLine(_ s: OpponentSnapshot, cue: Vec2, object obj: Vec2, castle: Vec2,
                                 castleReach: Double) -> (aim: Double, speed: Double) {
        let p = s.parameters, r = p.ballRadius
        let full = obj - cue
        let d = full.length
        let fullAim = atan2(full.y, full.x) * 180 / Double.pi
        // 1. The full hit: the ball's centre runs to two radii short of the other ball's.
        if d > 2 * r, lineIsClear(s, from: cue, to: obj - full.normalized * (2 * r), castle: castle,
                                  castleReach: castleReach) {
            return (fullAim, easyFullHitSpeed)
        }
        // 2. Thinner hits. An aim `off` degrees from the full hit passes the other ball's centre at d sin(off); the
        //    balls touch while that is under 2R, after the ball has run d cos(off) - sqrt((2R)^2 - (d sin off)^2).
        if d > 2 * r {
            let edge = asin(min(1, 2 * r / d)) * 180 / Double.pi
            var off = easyFineStep
            while off < edge {
                for signed in [off, -off] {
                    let a = (fullAim + signed) * Double.pi / 180
                    let dir = Vec2(cos(a), sin(a))
                    let rad = signed * Double.pi / 180
                    let side = d * sin(abs(rad))
                    guard side < 2 * r else { continue }
                    let run = d * cos(rad) - (4 * r * r - side * side).squareRoot()
                    if run > 0, lineIsClear(s, from: cue, to: cue + dir * run, castle: castle, castleReach: castleReach) {
                        return (fullAim + signed, easyFullHitSpeed)
                    }
                }
                off += easyFineStep
            }
        }
        // 3. One-cushion kicks, the shortest unfolded path first.
        let L = p.tableLength, W = p.tableWidth
        let rails: [(alongX: Bool, line: Double)] = [(true, r), (true, L - r), (false, r), (false, W - r)]
        var kicks: [(aim: Double, path: Double)] = []
        for rail in rails {
            let image = rail.alongX ? Vec2(2 * rail.line - obj.x, obj.y) : Vec2(obj.x, 2 * rail.line - obj.y)
            let toImage = image - cue
            let across = rail.alongX ? toImage.x : toImage.y
            guard abs(across) > 1e-9 else { continue }
            // Where along the line to the image the ball's centre meets the cushion line.
            let t = (rail.alongX ? rail.line - cue.x : rail.line - cue.y) / across
            guard t > 0, t < 1 else { continue }
            let bounce = cue + toImage * t
            guard bounce.x >= r, bounce.x <= L - r, bounce.y >= r, bounce.y <= W - r else { continue }
            // The second leg ends where the balls touch, two radii short of the other ball.
            let back = obj - bounce
            guard back.length > 2 * r else { continue }
            let touch = obj - back.normalized * (2 * r)
            guard lineIsClear(s, from: cue, to: bounce, castle: castle, castleReach: castleReach),
                  lineIsClear(s, from: bounce, to: touch, castle: castle, castleReach: castleReach) else { continue }
            kicks.append((aim: atan2(toImage.y, toImage.x) * 180 / Double.pi, path: toImage.length))
        }
        if let k = kicks.min(by: { $0.path < $1.path }) {
            let roll = OpponentPlanner.rollingLaunch(distance: k.path, parameters: p)
            return (k.aim, min(max(roll * easyPace, easySpeeds.lowerBound), easySpeeds.upperBound))
        }
        // 4. Every line is blocked: the full hit.
        return (fullAim, easyFullHitSpeed)
    }
}
