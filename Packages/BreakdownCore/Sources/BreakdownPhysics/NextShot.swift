// Author: Claude Sonnet 5.5 Medium
// Date: 11-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (shot() takes the cue elevation, as a sine, default level; a ball
//          that flew off the table is treated like a pocketed one: off the table, and the cue ball is re-spotted.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (ball in hand and spotting, for free play and the match games:
//          placement(of:...) says whether a spot is a legal place for a lifted cue ball (CueBallSpot), spot(_:...) puts
//          a ball back on the foot spot or the nearest free place straight behind it, and shot(from:...) takes the
//          index of the ball the cue strikes, appended with default 0 so every existing caller is unchanged.)
// PURPOSE: Turns a recorded shot into the starting layout of the next one, so the player can keep shooting from
//          wherever the balls came to rest. Pocketed balls go off the table (the solver's (-1,-1) parking
//          spot), a scratched cue ball is put back on the head spot (nudged clear of any ball sitting there),
//          and a helper builds a shot from the layout plus an aim angle given as a unit direction. No libm:
//          the caller supplies the direction, as everywhere else in this module.
//          Ball in hand: placement(of:cueBall:among:behindHeadLine:parameters:) is read by the app's placement drag
//          (ShowpieceModel.moveCueBallCandidate, the red tint) and spot(_:among:parameters:) by the match flow when a
//          ruling lists balls to spot (an eight on the break, a nine on a foul). This module cannot see the rules
//          module's BallInHand, so the head-line area arrives as a plain flag.
// SRP/DRY check: Pass - checked Rack.swift and Simulation.swift; this is the only place that carries a layout
//                from one shot to the next, and it reuses PoolParameters and ShotInput rather than copying them.
import BreakdownLensModel
import BreakdownTimeline

public enum NextShot {
    /// Where the solver parks a ball that is not on the table.
    public static let offTable = Vec2(-1, -1)

    /// True when a position is a real spot on the table rather than the parking spot.
    public static func isOnTable(_ p: Vec2) -> Bool { p.x >= 0 }

    /// Resting positions after `timeline` has finished. Index 0 is the cue ball.
    public static func layout(after timeline: Timeline, parameters p: PoolParameters = PoolParameters()) -> [Vec2] {
        var out = [Vec2](repeating: offTable, count: timeline.ballCount)
        for b in 0..<timeline.ballCount {
            let s = timeline.state(ball: b, at: timeline.duration)
            if !s.pocketed { out[b] = s.position }
        }
        if !isOnTable(out[0]) { out[0] = respotCueBall(among: out, parameters: p) }
        return out
    }

    /// The head spot, or the nearest clear spot behind it on the long axis if a ball is sitting there.
    /// Steps toward the head cushion in ball-diameter jumps until nothing overlaps.
    public static func respotCueBall(among positions: [Vec2], parameters p: PoolParameters) -> Vec2 {
        let step = 2 * p.ballRadius * 1.05
        var x = p.tableLength * 0.25
        let y = p.tableWidth * 0.5
        // Bounded loop: the table is short enough that a clear spot always exists within the head string.
        while x > p.ballRadius + step {
            let candidate = Vec2(x, y)
            let blocked = positions.dropFirst().contains { isOnTable($0) && ($0 - candidate).length < step }
            if !blocked { return candidate }
            x -= step
        }
        // Head of the table is completely crowded (practically impossible): fall back to the head spot itself.
        return Vec2(p.tableLength * 0.25, y)
    }

    /// Unit direction from the cue ball to the nearest ball still on the table; nil if only the cue ball is left.
    public static func directionToNearestObjectBall(in positions: [Vec2]) -> Vec2? {
        var best: (d: Double, dir: Vec2)?
        for i in 1..<positions.count where isOnTable(positions[i]) {
            let delta = positions[i] - positions[0]
            let d = delta.lengthSquared
            if best == nil || d < best!.d { best = (d, delta.normalized) }
        }
        return best?.dir
    }

    /// A shot from an arbitrary layout. `direction` need not be normalised; CueStrike normalises it.
    /// `elevation` is the sine of the cue's angle above horizontal (0, the default, is a level cue).
    public static func shot(from positions: [Vec2], direction: Vec2, speed: Double, tipUp: Double, tipSide: Double,
                            seed: UInt64, parameters p: PoolParameters = PoolParameters(),
                            elevation: Double = 0, ballIndex: Int = 0) -> ShotInput {
        ShotInput(parameters: p, positions: positions,
                  strike: CueStrike(direction: direction, speed: speed, tipUp: tipUp, tipSide: tipSide,
                                    elevation: elevation, ballIndex: ballIndex), seed: seed)
    }
}

// MARK: Ball in hand and spotting

/// Whether a spot is a legal place to put a lifted cue ball, and if not, the first reason it is not (the app tints
/// the ball red and may say why). Checked in a fixed order, see NextShot.placement.
public enum CueBallSpot: Equatable, Sendable {
    /// The ball may go here.
    case legal
    /// The ball would overlap this ball (the nearest one it overlaps).
    case overlapsBall(Int)
    /// Part of the ball would hang over a cushion, sit in a pocket's mouth or touch a pocket jaw.
    case offBed
    /// The ball would overlap a post, a standing pin or a hole in the bed.
    case onFeature
    /// Ball in hand behind the head line, and the spot is past it.
    case outsideHeadArea
}

extension NextShot {
    /// The head line's distance from the head rail: a quarter of the table's length, the same line the rack's head
    /// spot sits on (Rack.positions and respotCueBall use the same quarter). A ball whose centre is on the line is
    /// behind it.
    public static func headLineX(parameters p: PoolParameters) -> Double { p.tableLength * 0.25 }

    /// The foot spot: three quarters of the way down the table, on the centre line (the rack's apex sits there).
    public static func footSpot(parameters p: PoolParameters) -> Vec2 { Vec2(p.tableLength * 0.75, p.tableWidth * 0.5) }

    /// Whether `point` is a legal place for the ball `cueBall` (its own entry in `positions` is ignored, as is any
    /// ball off the table). Legal means wholly on the bed, clear of every pocket, jaw, post, pin, bed hole and ball,
    /// and behind the head line when `behindHeadLine` is set.
    ///
    /// The order the reasons are checked in is fixed, because the app shows the first one: the bed first (nothing
    /// else matters for a ball off the bed), then the head-line area (a rule about a whole region, fixed by moving
    /// back), then the table's fixed features, then the other balls (the reason that changes most as the ball moves).
    public static func placement(of point: Vec2, cueBall: Int = 0, among positions: [Vec2],
                                 behindHeadLine: Bool, parameters p: PoolParameters) -> CueBallSpot {
        let r = p.ballRadius
        // 1. On the bed: the centre at least a radius inside each cushion nose, so no part of the ball is over one.
        if point.x < r || point.x > p.tableLength - r || point.y < r || point.y > p.tableWidth - r { return .offBed }
        if p.pocketsEnabled {
            // Inside a pocket's capture circle the solver would drop the ball at once; touching a jaw face would
            // start the shot with the ball pressed into the jaw.
            for (k, c) in p.pocketCenters.enumerated() where (point - c).length < p.pocketCaptureRadii[k] {
                return .offBed
            }
            for jaw in p.jaws where distance(from: point, toSegment: jaw.start, jaw.end) < r { return .offBed }
        }
        // 2. Behind the head line when the ball in hand is restricted to the head area.
        if behindHeadLine, point.x > headLineX(parameters: p) { return .outsideHeadArea }
        // 3. Fixed features: posts and pins by contact distance; a bed hole whenever the ball's outline overlaps the
        //    drawn hole (a ball half over a hole is not a fair place to play from, even if its centre is on cloth).
        if p.posts.contains(where: { (point - $0.center).length < r + $0.radius }) { return .onFeature }
        if p.pins.contains(where: { (point - $0.center).length < r + $0.radius }) { return .onFeature }
        if p.bedHoles.contains(where: { (point - $0.center).length < r + $0.radius }) { return .onFeature }
        // 4. Other balls: report the nearest one overlapped (two centres closer than a diameter).
        var nearest: (ball: Int, d: Double)?
        for (b, q) in positions.enumerated() where b != cueBall && isOnTable(q) {
            let d = (point - q).length
            if d < 2 * r, nearest == nil || d < nearest!.d { nearest = (b, d) }
        }
        if let n = nearest { return .overlapsBall(n.ball) }
        return .legal
    }

    /// Where to put `ball` back on the table: the foot spot if it is free, otherwise the nearest free place straight
    /// behind it (along the long centre line toward the foot rail), otherwise, if the whole line behind is full, the
    /// nearest free place in front of it. "Free" is placement(of:...) == .legal with `ball` itself ignored.
    ///
    /// The candidates are worked out exactly rather than by stepping: along the centre line y = W/2, a ball at
    /// (xj, yj) blocks the open interval xj +- d with d = sqrt(c^2 - (yj - W/2)^2), where c is a diameter plus the
    /// rack's gap (PoolParameters.rackGap: the same one-micrometre clearance the rack leaves between neighbours, so a
    /// spotted ball sits frozen to the ball behind it without starting the shot overlapped). The nearest free place
    /// is therefore the foot spot or one of those interval ends. If nothing is free (a line of balls the length of the
    /// table, which cannot happen in a real game) the foot spot is returned.
    public static func spot(_ ball: Int, among positions: [Vec2], parameters p: PoolParameters) -> Vec2 {
        let foot = footSpot(parameters: p)
        func free(_ x: Double) -> Bool {
            placement(of: Vec2(x, foot.y), cueBall: ball, among: positions, behindHeadLine: false,
                      parameters: p) == .legal
        }
        if free(foot.x) { return foot }
        let clearance = 2 * p.ballRadius + p.rackGap
        var behind: [Double] = [], inFront: [Double] = []
        for (b, q) in positions.enumerated() where b != ball && isOnTable(q) {
            let dy = q.y - foot.y
            guard abs(dy) < clearance else { continue }
            let d = (clearance * clearance - dy * dy).squareRoot()
            if q.x + d >= foot.x { behind.append(q.x + d) }
            if q.x - d <= foot.x { inFront.append(q.x - d) }
        }
        // Nearest first in each direction; behind the spot is tried before in front of it.
        if let x = behind.sorted().first(where: free) { return Vec2(x, foot.y) }
        if let x = inFront.sorted(by: >).first(where: free) { return Vec2(x, foot.y) }
        return foot
    }

    /// Distance from `p` to the segment a-b (the nearest point clamped to the segment's ends).
    static func distance(from p: Vec2, toSegment a: Vec2, _ b: Vec2) -> Double {
        let ab = b - a
        let l2 = ab.lengthSquared
        guard l2 > 0 else { return (p - a).length }
        var t = (p - a).dot(ab) / l2
        t = t < 0 ? 0 : (t > 1 ? 1 : t)
        return (p - (a + ab * t)).length
    }
}
