// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Free places on one of the other tables (bumper pool, five-pin, bar billiards) for putting a ball back
//          before the next shot: a ball returned to its starting spot after a foul, a ball moved off a pin's spot so
//          the pins can stand again, the next bar-billiards white set on the D. Pure geometry on the recorded
//          TableSpec (Timeline.table), which carries the table's size, ball radius, posts, pins, bed holes and edge
//          pockets exactly as the solver used them, so this module needs no physics.
//          Read by BumperPoolRules, FivePinRules and BarBilliardsRules (their nextLayout helpers), which the app's
//          match flow calls to build the layout of the next solve.
// SRP/DRY check: Pass - checked NextShot.respotCueBall (BreakdownPhysics: the pool head spot only, on PoolParameters,
//          a module this one may not import) and the rules stream's NextShot.spot (pool foot spot, same module). This
//          is the one free-place search on a TableSpec with posts, pins and holes; the three tables share it.
import BreakdownLensModel
import BreakdownTimeline

public enum TableSpots {
    /// Balls are kept 5% further apart than touching, the same margin NextShot.respotCueBall uses on the pool table,
    /// so a ball put back never starts the next solve in contact with its neighbour.
    static let clearance = 1.05

    /// True when `ball` could rest at `p` before a fresh solve: inside the cushions, clear of every other ball on the
    /// table (by the clearance above), clear of every post and every pin (all pins stand at the start of a solve),
    /// and not overlapping any bed hole or edge pocket at all (a ball put back must not drop or teeter on a rim).
    public static func isFree(_ p: Vec2, for ball: Int, among positions: [Vec2], table: TableSpec) -> Bool {
        let r = table.ballRadius
        guard p.x >= r, p.x <= table.length - r, p.y >= r, p.y <= table.width - r else { return false }
        for (b, q) in positions.enumerated() where b != ball && ShotFacts.isOnTable(q) {
            if (q - p).length < 2 * r * clearance { return false }
        }
        // The solver's own contact distances: a ball touches a post or pin when its centre is r + radius away.
        for post in table.posts where (post.center - p).length < r + post.radius { return false }
        for pin in table.pins where (pin.center - p).length < r + pin.radius { return false }
        for hole in table.bedHoles where (hole.center - p).length < r + hole.radius { return false }
        if table.pocketsEnabled {
            for (k, c) in table.pockets.enumerated() {
                let capture = table.pocketCaptureRadius.indices.contains(k) ? table.pocketCaptureRadius[k] : 0
                if (c - p).length < r + capture { return false }
            }
        }
        return true
    }

    /// True when a ball resting at `p` stands where a pin must be stood up again (the solver's contact distance).
    public static func blocksAPin(_ p: Vec2, table: TableSpec) -> Bool {
        ShotFacts.isOnTable(p) && table.pins.contains { ($0.center - p).length < table.ballRadius + $0.radius }
    }

    /// `spot` if it is free, else the nearest free place found by stepping one ball width (with the clearance) at a
    /// time: first along `first` (a unit vector), then the opposite way, then across both ways, one step further out
    /// each round. Deterministic, so a replayed match puts balls back in the same places. Falls back to `spot` only if
    /// the whole table is full, which three to sixteen balls on these tables cannot do.
    public static func nearestFree(to spot: Vec2, for ball: Int, among positions: [Vec2], table: TableSpec,
                                   first: Vec2 = Vec2(-1, 0)) -> Vec2 {
        if isFree(spot, for: ball, among: positions, table: table) { return spot }
        let step = 2 * table.ballRadius * clearance
        let along = first.normalized == .zero ? Vec2(-1, 0) : first.normalized
        let across = along.perp
        // Enough rounds to reach every cushion from any spot.
        let rounds = Int((max(table.length, table.width) / step).rounded(.up)) + 1
        for k in 1...max(rounds, 1) {
            let d = Double(k) * step
            for candidate in [spot + along * d, spot - along * d, spot + across * d, spot - across * d]
                where isFree(candidate, for: ball, among: positions, table: table) {
                return candidate
            }
        }
        return spot
    }
}
