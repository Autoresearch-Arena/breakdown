// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (the nine-ball diamond and its break shot, for nine-ball matches and
//          free play's rack choice. The fifteen-ball triangle's code is untouched, so every old rack and break comes
//          out exactly as before; RackTests checks that against a copy of today's code.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: the showpiece break re-picked on generation two,
//          now the default; generationOneShowpieceBreak keeps the old one on the old physics for the bit-for-bit guard.)
// PURPOSE: Standard fifteen-ball triangle on the foot spot and the cue ball on the head spot, with a
//          one-micrometre gap between neighbours and optional seeded jitter so the break is a deterministic
//          cascade of binary collisions. Also the nine-ball diamond (the 1 at the front on the foot spot, the 9 in
//          the middle, the 2 to 8 seeded into the other places, the 10 to 15 parked off the table) with the same gap
//          and jitter, and the integer-only seeded random generator. Read by the app's free play and match flow
//          (ShowpieceModel) and by BreakProbe.
// SRP/DRY check: Pass - rack layouts and the seeded generator only. The diamond reuses the triangle's spacing numbers
//          (rowStep, side, the foot spot, the head spot) rather than inventing its own.
import BreakdownLensModel

/// xorshift64*: integer operations only, so identical on every machine.
public struct SeededGenerator: Sendable {
    private var state: UInt64
    public init(seed: UInt64) { state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed }
    public mutating func next() -> UInt64 {
        state ^= state >> 12; state ^= state << 25; state ^= state >> 27
        return state &* 0x2545_F491_4F6C_DD1D
    }
    /// Uniform in [-1, 1).
    public mutating func signedUnit() -> Double {
        Double(next() >> 11) / 4_503_599_627_370_496.0 - 1.0
    }
}

public enum Rack {
    /// Ball numbers by row from the apex; the eight sits in the middle of the third row.
    public static let layout: [[Int]] = [[1], [9, 2], [10, 8, 3], [11, 7, 14, 4], [5, 13, 15, 6, 12]]

    /// Sixteen centres indexed by ball number (0 is the cue ball on the head spot).
    public static func positions(parameters p: PoolParameters, seed: UInt64) -> [Vec2] {
        var rng = SeededGenerator(seed: seed)
        var out = [Vec2](repeating: .zero, count: 16)
        let r = p.ballRadius
        out[0] = Vec2(p.tableLength * 0.25, p.tableWidth * 0.5)
        let footX = p.tableLength * 0.75
        let rowStep = 3.0.squareRoot() * (r + p.rackGap * 0.5)
        let side = 2 * r + p.rackGap
        for (row, numbers) in layout.enumerated() {
            for (k, number) in numbers.enumerated() {
                let jx = rng.signedUnit() * p.rackJitter
                let jy = rng.signedUnit() * p.rackJitter
                let offset = (Double(k) - Double(row) * 0.5) * side
                out[number] = Vec2(footX + Double(row) * rowStep + jx, p.tableWidth * 0.5 + offset + jy)
            }
        }
        return out
    }

    /// The default break: the cue ball drives at the apex ball.
    public static func breakShot(parameters p: PoolParameters = PoolParameters(), seed: UInt64,
                                 aimOffset: Double, speed: Double, tipUp: Double = 0, tipSide: Double = 0) -> ShotInput {
        let positions = positions(parameters: p, seed: seed)
        let target = positions[1] + Vec2(0, aimOffset)
        let dir = (target - positions[0]).normalized
        return ShotInput(parameters: p, positions: positions,
                         strike: CueStrike(direction: dir, speed: speed, tipUp: tipUp, tipSide: tipSide), seed: seed)
    }
}

// MARK: The nine-ball diamond

extension Rack {
    /// Balls per row of the diamond, from the front (apex, on the foot spot) to the back.
    public static let nineBallRowSizes = [1, 2, 3, 2, 1]

    /// Sixteen centres indexed by ball number, like positions(parameters:seed:): the cue ball on the head spot, the 1
    /// at the front of the diamond on the foot spot, the 9 in the middle of the widest row, the 2 to 8 shuffled into
    /// the other seven places by the seed, and the 10 to 15 at the off-table parking spot.
    ///
    /// The places use the triangle's exact spacing (neighbours a diameter plus rackGap apart, rows sqrt(3) times half
    /// that apart) and jitter, so the diamond packs like the front of the triangle. The seeded generator is drawn in a
    /// fixed order, which must not change or every seeded nine-ball rack moves: first the shuffle (six draws, a
    /// Fisher-Yates shuffle of the 2 to 8 from the back), then the jitter, two draws (x then y) per place, places taken
    /// front row first and left to right within a row, as the triangle does.
    public static func nineBallPositions(parameters p: PoolParameters, seed: UInt64) -> [Vec2] {
        var rng = SeededGenerator(seed: seed)
        var out = [Vec2](repeating: NextShot.offTable, count: 16)
        let r = p.ballRadius
        out[0] = Vec2(p.tableLength * 0.25, p.tableWidth * 0.5)
        let footX = p.tableLength * 0.75
        let rowStep = 3.0.squareRoot() * (r + p.rackGap * 0.5)
        let side = 2 * r + p.rackGap

        // The seven free places get the 2 to 8 in a seeded order. The modulo's bias is at most 7 / 2^64: nothing.
        var others = Array(2...8)
        for i in stride(from: others.count - 1, to: 0, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            others.swapAt(i, j)
        }

        // Fill the places front to back. The apex (place 0) is the 1; the middle of the widest row (place 4: one in
        // row 0, two in row 1, then the second of row 2's three) is the 9.
        var place = 0
        var rest = others.makeIterator()
        for (row, count) in nineBallRowSizes.enumerated() {
            for k in 0..<count {
                let number: Int
                switch place {
                case 0: number = 1
                case 4: number = 9
                default: number = rest.next() ?? 2   // never nil: exactly seven other places for seven balls
                }
                let jx = rng.signedUnit() * p.rackJitter
                let jy = rng.signedUnit() * p.rackJitter
                // Centred across the table: a row of n balls spans offsets -(n-1)/2 to (n-1)/2 diameters.
                let offset = (Double(k) - Double(count - 1) * 0.5) * side
                out[number] = Vec2(footX + Double(row) * rowStep + jx, p.tableWidth * 0.5 + offset + jy)
                place += 1
            }
        }
        return out
    }

    /// A nine-ball break: the cue ball from the head spot drives at the 1, `aimOffset` metres across the table from
    /// its centre, exactly as breakShot does for the triangle.
    public static func nineBallBreakShot(parameters p: PoolParameters = PoolParameters(), seed: UInt64,
                                         aimOffset: Double, speed: Double, tipUp: Double = 0,
                                         tipSide: Double = 0) -> ShotInput {
        let positions = nineBallPositions(parameters: p, seed: seed)
        let target = positions[1] + Vec2(0, aimOffset)
        let dir = (target - positions[0]).normalized
        return ShotInput(parameters: p, positions: positions,
                         strike: CueStrike(direction: dir, speed: speed, tipUp: tipUp, tipSide: tipSide), seed: seed)
    }
}

public extension Rack {
    /// The cold-open break, picked from a parameter sweep (BreakProbe with no argument): a touch of draw, drops object
    /// balls and keeps the cue ball on the table. Regression-tested. Re-picked on the tuned generation-two physics
    /// (21-Nov-2026), where the old stroke (straight at the apex at 11 m/s) dropped fewer than two: of the sweep's
    /// strokes that drop two or more and keep the cue ball, the one nearest the old one, 10 m/s with the same draw and
    /// aimed 2 mm off the apex ball's centre, which drops three (the 4, the 5 and the 12).
    static func showpieceBreak(parameters p: PoolParameters = PoolParameters()) -> ShotInput {
        breakShot(parameters: p, seed: 3, aimOffset: 0.002, speed: 10.0, tipUp: -0.006)
    }

    /// The cold-open break as it was before the flip to generation two: generation one with that day's numbers.
    /// The bit-for-bit guard tests pin its recording, so the old solver path stays watched.
    static func generationOneShowpieceBreak() -> ShotInput {
        breakShot(parameters: .generationOne, seed: 3, aimOffset: 0.0, speed: 11.0, tipUp: -0.006)
    }
}
