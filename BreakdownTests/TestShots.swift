// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Shared shots for the app's unit tests (the BreakdownTests target, hosted in the app). Every recording here is
//          solved the way the app solves it: the table's numbers, then the surface's, written into the parameters of a
//          NextShot or Rack input, then PoolSolver.simulate (EightBallJudge.solve is that same path for a layout and is
//          reused, not copied). Also builds a ShotAttempt the way ShowpieceModel records one, and hand-made recordings for
//          tests that need events no solver would produce on demand.
// SRP/DRY check: Pass - test helpers only. Solving reuses EightBallJudge.solve; the break reuses Rack.breakShot; the
//          straight pot reuses RideDemo.straightPot. Nothing here decides a test's verdict.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

enum TestShots {
    /// The standard table on a surface, as ShowpieceModel.solve builds the parameters (table first, then surface).
    static func parameters(on surface: PlaySurface = .cloth) -> PoolParameters {
        var p = PoolParameters()
        TableKind.standard.apply(to: &p)
        surface.apply(to: &p)
        return p
    }

    /// Solve any built input on a surface, exactly as ShowpieceModel.solve does.
    static func solve(_ input: ShotInput, on surface: PlaySurface = .cloth) -> Timeline {
        var onSurface = input
        TableKind.standard.apply(to: &onSurface.parameters)
        surface.apply(to: &onSurface.parameters)
        return PoolSolver.simulate(onSurface)
    }

    /// The player's break, as ShowpieceModel.breakNow builds it: seed 11 is the first break a new player makes
    /// (10 + the first break serial), struck straight at the apex at 10 m/s, the break panel's default power.
    static func breakInput(seed: UInt64 = 11, aimOffset: Double = 0, speed: Double = 10, tipUp: Double = 0,
                           tipSide: Double = 0) -> ShotInput {
        var p = PoolParameters()
        p.version = 1
        return Rack.breakShot(parameters: p, seed: seed, aimOffset: aimOffset, speed: speed, tipUp: tipUp,
                              tipSide: tipSide)
    }

    static func breakShot(on surface: PlaySurface = .cloth) -> Timeline { solve(breakInput(), on: surface) }

    /// The Ride demo's straight pot (cue ball, one object ball, the far corner), solved on a surface.
    static func straightPot(on surface: PlaySurface = .cloth) -> Timeline { solve(RideDemo.straightPot(), on: surface) }

    /// A shot from a layout with the trick-shot settings (aim in degrees, speed, tip, elevation as a sine).
    static func shot(from start: [Vec2], _ s: TrickSettings, on surface: PlaySurface = .cloth) -> Timeline {
        EightBallJudge.solve(start, s, on: surface)
    }

    /// The attempt ShowpieceModel.record would keep for this shot. The power range is the shot panel's (the same
    /// 0.5...8 m/s the eight-ball judge sweeps), used only for "harder" and "softer" in comparisons.
    static func attempt(start: [Vec2], timeline: Timeline, _ s: TrickSettings, isBreak: Bool = false,
                        breakSeed: UInt64 = 0) -> ShotAttempt {
        ShotAttempt(isBreak: isBreak, breakSeed: breakSeed, start: start, timeline: timeline, aim: s.aim, power: s.power,
                    powerRange: EightBallJudge.speedRange, tipUp: s.tipUp, tipSide: s.tipSide)
    }

    // MARK: Hand-made recordings

    static let ballRadius = PoolParameters().ballRadius

    /// A ball standing still at `p` for the whole recording.
    static func still(_ p: Vec2) -> BallSegment {
        BallSegment(t0: 0, t1: .infinity, phase: .stationary, position0: p, velocity0: .zero, acceleration: .zero,
                    omega0: .zero, alphaXY: .zero, spinDecay: 9, radius: ballRadius, orientation0: .identity)
    }

    /// One ball in an event, moving at `before` and then `after` (m/s along x), with the matching kinetic energy of a
    /// pool ball (one half m v squared, no spin), so every energy share a caption works out is well defined.
    static func ball(_ b: Int, before: Double, after: Double) -> ImpactBall {
        let m = PoolParameters().ballMass
        return ImpactBall(ball: b, velocityBefore: Vec2(before, 0), velocityAfter: Vec2(after, 0), omegaBefore: .zero,
                          omegaAfter: .zero, translationalBefore: 0.5 * m * before * before, rotationalBefore: 0,
                          translationalAfter: 0.5 * m * after * after, rotationalAfter: 0)
    }

    /// A recording on the standard table holding exactly these events (sorted by time) with `balls` balls standing
    /// still, plus any extra segments a test needs for ball 0 (replacing its still one).
    static func recording(_ events: [LensEvent], balls: Int = 3, cueSegments: [BallSegment]? = nil) -> Timeline {
        var segments = (0..<balls).map { [still(Vec2(0.4 + 0.3 * Double($0), 0.6))] }
        if let cueSegments { segments[0] = cueSegments }
        let sorted = events.sorted { $0.time < $1.time }
        return Timeline(table: PoolParameters().tableSpec, seed: 1, parameterHash: 1, segments: segments, events: sorted,
                        pocketTime: [Double?](repeating: nil, count: balls), duration: (sorted.last?.time ?? 0) + 1)
    }
}
