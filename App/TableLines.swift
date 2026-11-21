// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Straight-line questions about a still layout of balls, shared by everything in the app that needs them:
//          - clear(from:to:past:in:radius:): no ball's centre comes within a ball's width of a segment (a clean
//            path for a ball of the same size). Moved here from EightBallJudge (its "shape" test), which now calls it.
//          - firstBall(from:direction:among:in:radius:): the first ball a ball rolling from a point along a direction
//            would touch, and how far it travels first. Moved here from EightBallJudge's safety test (its
//            "hasStraightLine" scan), which now calls it.
//          - potAim(ball:pocket:cueBall:in:table:): where the cue ball must be sent so the object ball goes into a
//            pocket by the ghost-ball rule (the cue ball's centre at contact sits two radii behind the object ball,
//            on the line from the pocket through the ball), with the cut it needs and whether both paths are clear.
//          - bestPot(...) and the pocket a moving ball is heading for (heading(from:direction:table:)).
//          Read by EightBallJudge (shape and safety), TableWords (the spoken layout and aim) and AimOverlay (tap a
//          pocket to aim the pot, the "Aim to pot in nearest pocket" action, the controller). Pure geometry on Vec2;
//          no model, no drawing, no words. A guide for the player: the solver still decides what really happens.
// SRP/DRY check: Pass - checked AimGeometry.firstContact (one ray from the cue ball over the whole layout, kept there
//          because the aim guide needs the ghost and both departure directions); this file answers the other
//          straight-line questions, and the judge's two private helpers were moved here rather than copied.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

enum TableLines {
    /// True when no ball in `balls` has its centre within a ball's width (two radii) of the segment from a to b.
    /// The test the judge's "shape" rule has always used: the path of a ball of radius `radius` is clear.
    static func clear(from a: Vec2, to b: Vec2, past balls: [Int], in rest: [Vec2], radius: Double) -> Bool {
        let seg = b - a
        let len2 = seg.lengthSquared
        for o in balls {
            let rel = rest[o] - a
            let t = len2 > 0 ? min(max(rel.dot(seg) / len2, 0), 1) : 0
            if (rest[o] - (a + seg * t)).length < 2 * radius { return false }
        }
        return true
    }

    /// The balls in `balls` whose centres come within a ball's width of the segment from a to b, nearest to `a`
    /// first: what is in the way.
    static func blockers(from a: Vec2, to b: Vec2, past balls: [Int], in rest: [Vec2], radius: Double) -> [Int] {
        let seg = b - a
        let len2 = seg.lengthSquared
        var hits: [(t: Double, ball: Int)] = []
        for o in balls {
            let rel = rest[o] - a
            let t = len2 > 0 ? min(max(rel.dot(seg) / len2, 0), 1) : 0
            if (rest[o] - (a + seg * t)).length < 2 * radius { hits.append((t, o)) }
        }
        return hits.sorted { $0.t < $1.t }.map(\.ball)
    }

    /// The first of `balls` that a ball of radius `radius` leaving `from` along the unit vector `direction` would
    /// touch, and how far its centre travels before it does. Nil when it touches none of them.
    /// (The judge's safety test: it scans directions all round the cue ball and asks which ball each one meets.)
    static func firstBall(from: Vec2, direction d: Vec2, among balls: [Int], in rest: [Vec2],
                          radius r: Double) -> (ball: Int, distance: Double)? {
        var nearest: (ball: Int, distance: Double)?
        for b in balls {
            let rel = rest[b] - from
            let along = rel.dot(d)
            guard along > 0 else { continue }
            // Sideways distance of the ball's centre from the line; two radii or more and the balls pass.
            let off = abs(rel.x * d.y - rel.y * d.x)
            guard off < 2 * r else { continue }
            // Back off from the closest approach to where the two balls first touch.
            let hit = along - (4 * r * r - off * off).squareRoot()
            if nearest == nil || hit < nearest!.distance { nearest = (b, hit) }
        }
        return nearest
    }

    // MARK: Aiming a pot

    /// What it takes to pot one ball in one pocket from where the cue ball sits.
    struct PotAim: Equatable {
        var ball: Int
        /// Solver pocket index (0 to 5 edge pockets).
        var pocket: Int
        /// Where the cue ball's centre must be at contact (the ghost ball).
        var ghost: Vec2
        /// Sine of the cut angle between the cue ball's path and the object ball's path: 0 straight in, 1 a graze.
        var cutSine: Double
        /// Both legs (cue ball to ghost, object ball to pocket) are free of other balls.
        var clear: Bool
        /// Cue ball to ghost plus object ball to pocket, metres.
        var distance: Double
    }

    /// The ghost-ball aim for `ball` into edge pocket `pocket`. Nil when the pocket does not exist, the ball is off
    /// the table, or the cut would be 90 degrees or more (the cue ball would have to come from beyond the ball).
    static func potAim(ball: Int, pocket: Int, cueBall: Int = 0, in rest: [Vec2], table: TableSpec) -> PotAim? {
        guard table.pocketsEnabled, pocket >= 0, pocket < table.pockets.count,
              rest.indices.contains(ball), rest.indices.contains(cueBall),
              NextShot.isOnTable(rest[ball]), NextShot.isOnTable(rest[cueBall]) else { return nil }
        let r = table.ballRadius
        let obj = rest[ball], cue = rest[cueBall], hole = table.pockets[pocket]
        let toPocket = hole - obj
        guard toPocket.length > 1e-6 else { return nil }
        let line = toPocket.normalized
        // Ghost-ball rule: at contact the line of centres points at the pocket, so the cue ball's centre sits two
        // radii behind the object ball on that line.
        let ghost = obj - line * (2 * r)
        let toGhost = ghost - cue
        guard toGhost.length > 1e-6 else { return nil }
        let travel = toGhost.normalized
        let cosCut = travel.dot(line)
        guard cosCut > 0.02 else { return nil }   // a cut of 90 degrees or more cannot send the ball that way
        let sinCut = (1 - min(1, cosCut * cosCut)).squareRoot()
        let others = rest.indices.filter { $0 != ball && $0 != cueBall && NextShot.isOnTable(rest[$0]) }
        let free = clear(from: cue, to: ghost, past: others, in: rest, radius: r)
            && clear(from: obj, to: hole, past: others, in: rest, radius: r)
        return PotAim(ball: ball, pocket: pocket, ghost: ghost, cutSine: sinCut, clear: free,
                      distance: toGhost.length + toPocket.length)
    }

    /// The easiest pot for `ball`: among the edge pockets with both legs clear, the one with the smallest cut, then
    /// the shortest total distance. When no pocket is clear, the smallest cut of any (so an aim can still be given,
    /// and the caller can say it is blocked).
    static func bestPot(ball: Int, cueBall: Int = 0, in rest: [Vec2], table: TableSpec) -> PotAim? {
        let all = (0..<min(TableSpec.edgePocketCount, table.pockets.count)).compactMap {
            potAim(ball: ball, pocket: $0, cueBall: cueBall, in: rest, table: table)
        }
        func easier(_ a: PotAim, _ b: PotAim) -> Bool {
            // Cuts closer than about 3 degrees (sine 0.05) count as equal, so a shorter shot wins between them.
            if abs(a.cutSine - b.cutSine) > 0.05 { return a.cutSine < b.cutSine }
            return a.distance < b.distance
        }
        return all.filter(\.clear).min(by: easier) ?? all.min(by: easier)
    }

    // MARK: Where a ball is heading

    /// Where a ball leaving `from` along `direction` goes: into or past the nearest pocket ahead of it, or to a rail.
    enum Heading: Equatable {
        /// `miss` is how far (metres) the line passes from the pocket's centre; inside `capture` it drops.
        case pocket(Int, miss: Double, capture: Double)
        /// 0 head rail (x = 0), 1 foot rail (x = L), 2 right rail (y = 0), 3 left rail (y = W).
        case rail(Int)
    }

    /// The pocket the line from `from` along unit `direction` passes closest to, if it passes within `window`
    /// metres of its centre before reaching a rail; otherwise the rail it reaches. `window` defaults to three ball
    /// widths: farther off than that, "missing the pocket" is not a useful thing to say.
    static func heading(from: Vec2, direction d: Vec2, table: TableSpec, window: Double? = nil) -> Heading {
        let r = table.ballRadius
        let reach = window ?? 6 * r
        // How far the centre can go before it meets a cushion: the same box AimGeometry uses.
        let toRail = AimGeometry.cushionDistance(from: from, direction: d, table: table)
        var best: (k: Int, miss: Double)?
        if table.pocketsEnabled {
            for (k, hole) in table.pockets.enumerated() {
                let rel = hole - from
                let along = rel.dot(d)
                // Pockets sit just past the cushion box, so allow the line a little beyond it (a ball's width).
                guard along > 0, along <= toRail + 4 * r else { continue }
                let miss = abs(rel.x * d.y - rel.y * d.x)
                if miss <= reach, best == nil || miss < best!.miss { best = (k, miss) }
            }
        }
        if let best {
            let capture = best.k < table.pocketCaptureRadius.count ? table.pocketCaptureRadius[best.k] : r
            return .pocket(best.k, miss: best.miss, capture: capture)
        }
        let end = from + d * toRail
        // The rail whose line the end point lies on (within a millimetre of the cushion box).
        if end.x <= r + 1e-3 { return .rail(0) }
        if end.x >= table.length - r - 1e-3 { return .rail(1) }
        if end.y <= r + 1e-3 { return .rail(2) }
        return .rail(3)
    }
}
