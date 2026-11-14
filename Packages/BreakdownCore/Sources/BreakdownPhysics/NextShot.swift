// Author: Claude Sonnet 5.5 Medium
// Date: 11-November-2026
// PURPOSE: Turns a recorded shot into the starting layout of the next one, so the player can keep shooting from
//          wherever the balls came to rest. Pocketed balls go off the table (the solver's (-1,-1) parking
//          spot), a scratched cue ball is put back on the head spot (nudged clear of any ball sitting there),
//          and a helper builds a shot from the layout plus an aim angle given as a unit direction. No libm:
//          the caller supplies the direction, as everywhere else in this module.
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
    public static func shot(from positions: [Vec2], direction: Vec2, speed: Double, tipUp: Double, tipSide: Double,
                            seed: UInt64, parameters p: PoolParameters = PoolParameters()) -> ShotInput {
        ShotInput(parameters: p, positions: positions,
                  strike: CueStrike(direction: direction, speed: speed, tipUp: tipUp, tipSide: tipSide), seed: seed)
    }
}
