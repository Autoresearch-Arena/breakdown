// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: Standard fifteen-ball triangle on the foot spot and the cue ball on the head spot, with a
//          one-micrometre gap between neighbours and optional seeded jitter so the break is a deterministic
//          cascade of binary collisions. Also holds the integer-only seeded random generator.
// SRP/DRY check: Pass - rack layout and the seeded generator only.
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

public extension Rack {
    /// The cold-open break, picked from a parameter sweep (BreakProbe): straight at the apex ball, a touch of
    /// draw, drops two object balls and keeps the cue ball on the table. Regression-tested.
    static func showpieceBreak() -> ShotInput {
        breakShot(seed: 3, aimOffset: 0.0, speed: 11.0, tipUp: -0.006)
    }
}
