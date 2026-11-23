// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: The shot an achievement keeps, as a recipe (plans/23-Nov-2026-achievements-plan.md, new file 3). Recordings
//          are not Codable (Timeline, ShotInput, CueStrike and PoolParameters are not; only Vec2 is), so the shot that
//          earned an achievement is saved as everything needed to solve it again: where every ball started, the strike
//          exactly as it was handed to the solver (direction, speed, tip, cue elevation, the struck ball, the seed and
//          the parameters' version), the table, surface and physics generation it was solved on, the settings the player
//          struck with (for Try again), a fingerprint of the motion it produced (ShotAttempt.motionHash) and the events a
//          guided Lens replay holds on (its signature).
//          Solving it again goes through ShowpieceModel.solverCopy, the same pure step every stroke takes, so on the same
//          build the recording comes back identical; after a physics change it may not, which sameAsEarned reports.
//          Also TrickPath.traced(_:start:striker:), the trick list's small drawing for any striking ball (bumper pool,
//          bar billiards and five-pin's second seat strike balls other than 0); kept here so TrickPathThumb.swift is not
//          touched.
//          Read by AchievementRecord (saved inside it), AchievementBook (kept on a shot, solved again for the list's
//          drawings and the replay). Pure and nonisolated: the solves run on background tasks.
// SRP/DRY check: Pass - checked ShotAttempt (the in-memory attempt; this is its saved recipe and builds one back),
//          ShowpieceModel.solverCopy (reused, never restated), TrickPathCache (the same solve-then-trace idea for the
//          authored answers) and the 0.7.7 sibling plans' ClipShotRecord and OwnShot (built side by side in other
//          worktrees; folding the three recipes into one is a later tidy-up the coordinator can note).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

struct AchievementShot: Codable, Equatable, Sendable {
    // The stroke as the solver saw it (the attempt's effective input, before the table's and surface's numbers).
    var isBreak: Bool
    var breakSeed: UInt64
    var start: [Vec2]
    var direction: Vec2
    var speed: Double
    var tipUp: Double
    var tipSide: Double
    var elevation: Double
    var ballIndex: Int
    var seed: UInt64
    /// The input's own PoolParameters.version: 1 for racks and breaks, 2 for every other stroke. The rest of the input's
    /// parameters are the defaults (every player stroke and break is built on them; the motionHash check catches any
    /// that is not).
    var parametersVersion: Int
    // What it was solved on, as raw values (PlaySurface and TableKind are not Codable; an unknown value fails the solve).
    var surface: String
    var table: String
    var generation: Int
    // The settings as struck (ShotAttempt's own fields), so a replayed shot can be tried again from its start.
    var aim: Double
    var power: Double
    var powerLow: Double
    var powerHigh: Double
    var settingTipUp: Double
    var settingTipSide: Double
    var settingElevation: Double
    /// ShotAttempt.motionHash of the recording that earned it.
    var motionHash: UInt64
    /// Event indices a guided Lens replay holds on (each captioned when it was kept); may be empty.
    var signature: [Int]

    /// The recipe of a recorded attempt. Nil when the input has no balls.
    init?(attempt a: ShotAttempt, signature: [Int]) {
        let input = a.input
        guard !input.positions.isEmpty else { return nil }
        isBreak = a.isBreak
        breakSeed = a.breakSeed
        start = input.positions
        direction = input.strike.direction
        speed = input.strike.speed
        tipUp = input.strike.tipUp
        tipSide = input.strike.tipSide
        elevation = input.strike.elevation
        ballIndex = input.strike.ballIndex
        seed = input.seed
        parametersVersion = input.parameters.version
        surface = a.surface.rawValue
        table = a.table.rawValue
        generation = a.generation
        aim = a.aim
        power = a.power
        powerLow = a.powerRange.lowerBound
        powerHigh = a.powerRange.upperBound
        settingTipUp = a.tipUp
        settingTipSide = a.tipSide
        settingElevation = a.elevation
        motionHash = a.motionHash
        self.signature = signature
    }

    /// The same shot holding other events in its replay (each achievement a shot earns keeps its own signature).
    func with(signature s: [Int]) -> AchievementShot {
        var copy = self
        copy.signature = s
        return copy
    }

    /// The input as the model kept it (the base input, before the table's and surface's numbers are written in).
    func input() -> ShotInput {
        var p = PoolParameters()
        p.version = parametersVersion
        var strike = CueStrike(direction: direction, speed: speed, tipUp: tipUp, tipSide: tipSide, elevation: elevation,
                               ballIndex: ballIndex)
        // CueStrike's init normalises the direction, and normalising an already unit vector can move its last bit
        // (Vec2.normalized divides by a computed length): a different recording and a false "played again with
        // today's physics". The stored direction is written back exactly. Elevation needs no write-back: the init's
        // clamp leaves an in-range value unchanged.
        strike.direction = direction
        return ShotInput(parameters: p, positions: start, strike: strike, seed: seed)
    }

    var playSurface: PlaySurface? { PlaySurface(rawValue: surface) }
    var tableKind: TableKind? { TableKind(rawValue: table) }

    /// Solve the shot again exactly as it was solved (its table, surface and generation, through solverCopy). Nil when
    /// the stored surface or table is not one this version knows. Pure; safe on a background task.
    nonisolated func solvedTimeline() -> Timeline? {
        guard let s = playSurface, let t = tableKind else { return nil }
        return PoolSolver.simulate(ShowpieceModel.solverCopy(input(), table: t, surface: s, generation: generation))
    }

    /// The attempt the model would have recorded for `tl` (a recording of this shot): the stored settings, the base
    /// input, and no stroke delivery (the drift is already inside the stored strike). Nil for an unknown table or
    /// surface.
    nonisolated func attempt(with tl: Timeline) -> ShotAttempt? {
        guard let s = playSurface, let t = tableKind else { return nil }
        return ShotAttempt(isBreak: isBreak, breakSeed: breakSeed, start: start, timeline: tl, aim: aim, power: power,
                           powerRange: min(powerLow, powerHigh)...max(powerLow, powerHigh), tipUp: settingTipUp,
                           tipSide: settingTipSide, elevation: settingElevation, seed: seed, input: input(), surface: s,
                           table: t, generation: generation)
    }

    /// Solve again and say whether the motion matches what was recorded when it was earned. The book's background
    /// tasks call solvedTimeline() and attempt(with:) separately, so only a Timeline (Sendable) crosses back to the main
    /// actor; this one call is for the tests and anything already off the main actor.
    nonisolated func solve() -> (attempt: ShotAttempt, sameAsEarned: Bool)? {
        guard let tl = solvedTimeline(), let a = attempt(with: tl) else { return nil }
        return (a, a.motionHash == motionHash)
    }
}

// MARK: The drawing for any striking ball

extension TrickPath {
    /// TrickPath.traced(_:start:) for a recording whose struck ball is `striker`: the striker's path is the coloured
    /// one, and every other ball that started on the table (ball 0 included when it is not the striker) is drawn thin.
    /// With striker 0 it gives exactly what traced(_:start:) gives. Nil when the striker never moved.
    nonisolated static func traced(_ tl: Timeline, start: [Vec2], striker: Int) -> TrickPath? {
        let cue = stretches(of: striker, in: tl)
        guard !cue.isEmpty else { return nil }
        var objects: [[Vec2]] = []
        for b in 0..<min(start.count, tl.ballCount) where b != striker && NextShot.isOnTable(start[b]) {
            objects += stretches(of: b, in: tl).map(\.points)
        }
        let balls = start.indices.filter { $0 < tl.ballCount && NextShot.isOnTable(start[$0]) }
            .map { StartBall(ball: $0, position: start[$0]) }
        return TrickPath(length: tl.table.length, width: tl.table.width, ballRadius: tl.table.ballRadius,
                         pockets: tl.table.pockets, balls: balls, cue: cue, objects: objects)
    }
}
