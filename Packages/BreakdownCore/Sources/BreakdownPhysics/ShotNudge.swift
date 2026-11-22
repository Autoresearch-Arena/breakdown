// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: The what-if replay's one change to a shot (spec 4.3, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md stream
//          whatif item 1). ShotNudge says how a player's delivered shot is changed: the cue's direction turned by a unit
//          vector, the launch speed scaled, the tip moved up or across, the cue's angle set. WhatIfInput.alternate
//          applies it to the shot's effective input, the one the solver was handed for the real attempt (after the
//          stroke's drift), so the drift stays exactly as played: the drift is a rotation plus a side offset, and both
//          commute with the nudge. Seed, positions, parameters and the struck ball are never touched, so the other
//          future is solved with the same physics and the same seeded variation as the real one.
//          No trigonometry here (this module has no libm, see Parameters.swift): the app turns degrees into the
//          `turn` vector, as it does for every aim. A zero nudge returns the input bit for bit, so solving it gives
//          the real recording again (the what-if's first test).
//          Read by App/WhatIfFork.swift, which builds the nudge on the main actor and solves the result off it.
// SRP/DRY check: Pass - checked NextShot.shot (builds a fresh input from settings; this changes a delivered one) and
//          the app's StrokeDelivery.apply (the stroke's own drift; its side clamp of nine tenths of the radius is the
//          rule restated below, because the app type cannot be imported here). Nothing else alters a built input.
import BreakdownLensModel

/// One what-if change to a delivered shot. The defaults change nothing.
public struct ShotNudge: Sendable, Equatable {
    /// Unit vector the cue's direction is turned by (complex multiplication): (cos a, sin a) for a turn of a,
    /// anticlockwise on the table plan positive. (1, 0) is no turn.
    public var turn = Vec2(1, 0)
    /// The launch speed is multiplied by this. 1 is no change.
    public var speedScale = 1.0
    /// Metres added to the tip's height on the cue ball (up is follow) and to its side offset (right positive).
    public var tipUp = 0.0
    public var tipSide = 0.0
    /// The cue's angle above the table as a sine, written in place of the strike's own; nil leaves it as it was.
    public var elevation: Double?

    public init(turn: Vec2 = Vec2(1, 0), speedScale: Double = 1.0, tipUp: Double = 0.0, tipSide: Double = 0.0,
                elevation: Double? = nil) {
        self.turn = turn; self.speedScale = speedScale; self.tipUp = tipUp; self.tipSide = tipSide
        self.elevation = elevation
    }

    /// True when applying this changes nothing at all.
    public var isZero: Bool { self == ShotNudge() }
}

public enum WhatIfInput {
    /// The tip's side offset is kept within this share of the ball's radius after a nudge: the same rule the app's
    /// StrokeDelivery.apply uses for the stroke's own side drift (a tip cannot land further out on the ball's face than
    /// that; past the grip limit the solver's miscue rule takes over long before it).
    public static let sideLimitShare = 0.9

    /// The steepest cue the strike may take, as a sine: CueStrike's own cap (about 84 degrees).
    public static let maxElevation = 0.995

    /// `input` with nudge `n` applied. Each part is applied only when it changes something, and the strike's fields
    /// are written in place (never rebuilt through CueStrike's initializer, which would normalise the direction
    /// again), so a zero nudge, or any untouched part, stays bit for bit as it was.
    public static func alternate(of input: ShotInput, _ n: ShotNudge, ballRadius: Double) -> ShotInput {
        guard !n.isZero else { return input }
        var out = input
        if n.turn != Vec2(1, 0) {
            // Complex multiplication: (d.x + i d.y)(c + i s). A unit turn keeps a unit direction a unit direction.
            let d = out.strike.direction, c = n.turn.x, s = n.turn.y
            out.strike.direction = Vec2(d.x * c - d.y * s, d.x * s + d.y * c)
        }
        if n.speedScale != 1 { out.strike.speed *= n.speedScale }
        if n.tipUp != 0 { out.strike.tipUp += n.tipUp }
        if n.tipSide != 0 {
            let limit = sideLimitShare * ballRadius
            out.strike.tipSide = min(max(out.strike.tipSide + n.tipSide, -limit), limit)
        }
        if let e = n.elevation { out.strike.elevation = min(max(e, 0), maxElevation) }
        return out
    }
}
