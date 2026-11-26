// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The strike in real units (plans/25-Nov-2026-strike-panel-and-controls-plan.md, stage 1). One value type,
//          StrikeFigures, holding what a strike does to the ball: the swing, the speed the ball leaves at, the push
//          (impulse), the force (an estimate, see tipContactTime), the energy, the spin split into top or back and
//          side, the tip offset, the cue angle, the side-spin push off the aim and the cut on the first ball in line.
//          Built by one function, make(strike:swing:parameters:layout:table:), from the very CueStrike the solver is
//          (or was) given, so every figure is worked out from the solver's own numbers:
//            - the launch speed mirrors PoolSolver.cueLaunch (Simulation.swift), which the package keeps internal: at
//              generation 2 an off-centre hit leaves at speed * (M + m) / (M + m + 5/2 M b^2 / R^2) (the factor
//              written beside cueMass in Parameters.swift), and an offset past miscueOffsetLimit slips, leaving at
//              miscueSpeedFraction of the speed with the offsets scaled back onto the grip limit; at generation 1
//              every hit leaves at the strike's speed. StrikeFiguresTests pins this mirror against the solver's own
//              recorded strike event, so the two cannot drift apart unnoticed;
//            - the direction comes from the public PoolSolver.launchDirection, the same call the aim guide makes;
//            - the push is the ball's mass times the launch speed, exactly the normalImpulse the solver writes on its
//              cue-strike event (both the level and the raised strike);
//            - the spin uses the solver's k = 5/2 * speed / R^2 (m * speed / I for a solid ball) for both the level and
//              the raised strike: raising the cue only tilts the spin axis, it never changes the two rates shown.
//          A second reading, StrikeComparison, holds the planned strike beside the delivered one (the attempt's own
//          CueStrike after StrokeModel.delivery added the stroke's aim and tip error) and says which figures differ.
//          Reads only BreakdownPhysics and AimGeometry (for the cut); writes nothing; no SwiftUI.
// SRP/DRY check: Pass - checked CueProfile (swing and launch speed per cue, reused), AimGeometry (launch direction, the
//          guide's first contact, reused for the cut), StrokeModel/StrokeDelivery (the drift, read, not repeated) and
//          NotebookNumbers (shows a recorded shot's cue speed after the fact; nothing showed the strike before it).
//          The only figure here the solver does not use is the tip's contact time, and it is named and explained.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// What one strike does to the ball, in real units. Speeds in metres per second, the push in newton-seconds, the force
/// in newtons, the energy in joules, spin in turns per second, offsets in metres, angles in degrees.
struct StrikeFigures: Equatable, Sendable {
    /// The cue tip's speed as it meets the ball, metres per second, in house-cue units (CueProfile.swing): the power.
    var swing: Double
    /// The speed a centre hit with this stroke and this cue would give (CueStrike.speed).
    var centreSpeed: Double
    /// The speed the ball really leaves at: slower off centre, and much slower for a miscue (generation 2).
    var leaves: Double
    /// The push the tip gives the ball, newton-seconds: mass times the speed it leaves at.
    var push: Double
    /// About how hard the tip pushes while it touches, newtons: the push over tipContactTime. An estimate.
    var force: Double
    /// Energy of motion plus energy of spin just after the strike, joules.
    var energy: Double
    /// Turns per second about the horizontal axis across the cue: positive is top spin (follow), negative back spin.
    var topSpin: Double
    /// Turns per second from the side offset: positive for a hit right of centre, negative for left.
    var sideSpin: Double
    /// Where the tip meets the ball, metres from the middle as aimed: up is positive, right is positive.
    var tipUp: Double
    var tipSide: Double
    /// The cue's angle above the table, degrees (0 is level).
    var cueAngle: Double
    /// The cue's own direction on the table plan, degrees counter-clockwise from the long axis.
    var aimDegrees: Double
    /// How far side spin (or a miscue) turns the ball off the cue's line, degrees, positive to the shooter's left.
    var turnDegrees: Double
    /// The cut on the first ball the launch line meets: 0 is full ball, 90 a hair's graze. Nil with no ball in line
    /// (or when no layout was given).
    var cut: Double?
    /// The ball that cut is measured on.
    var cutBall: Int?
    /// True when the tip strikes past the grip limit and slips (generation 2).
    var miscue: Bool

    /// How long a leather tip stays on the ball, seconds: about a thousandth of a second for a typical leather tip on a
    /// pool ball. It is the ONLY number on the strike panel the solver does not use (the solver strikes in an instant
    /// and only knows the push), so the force it gives is always labelled "about". It is deliberately not one of the
    /// solver's parameters: those are hashed into every recording, and every authored shot depends on that hash.
    static let tipContactTime = 0.001

    // MARK: Building

    /// The figures for one strike. `swing` is the tip speed (the caller knows it from the power or the stroke record);
    /// `parameters` are the table's at the generation the solve uses (ball size and mass, the cue's mass, the grip).
    /// With a `layout` and a `table`, the cut on the first ball in line is worked out along the launch direction from
    /// the struck ball (strike.ballIndex), the way the aim guide draws it.
    static func make(strike: CueStrike, swing: Double, parameters p: PoolParameters,
                     layout: [Vec2]? = nil, table: TableSpec? = nil) -> StrikeFigures {
        let launch = Self.launch(strike, p)
        let r2 = p.ballRadius * p.ballRadius
        // m * speed / I for a solid ball (I = 2/5 m R^2), the solver's k in both strike paths.
        let k = 2.5 * launch.speed / r2
        let topRate = k * launch.tipUp          // radians per second
        let sideRate = k * launch.tipSide
        let push = p.ballMass * launch.speed
        let energy = 0.5 * p.ballMass * launch.speed * launch.speed
            + 0.5 * p.inertia * (topRate * topRate + sideRate * sideRate)
        let launched = PoolSolver.launchDirection(for: strike, parameters: p)
        let cue = strike.direction
        let turn = atan2(cue.x * launched.y - cue.y * launched.x, cue.dot(launched)) * 180 / Double.pi
        var cut: Double?
        var cutBall: Int?
        if let layout, let table, layout.indices.contains(strike.ballIndex), NextShot.isOnTable(layout[strike.ballIndex]) {
            let guide = AimGeometry.guideLine(layout: layout, origin: layout[strike.ballIndex], direction: launched,
                                              table: table)
            if let contact = guide.contact {
                // AimContact.cut is the sine of the cut angle (the share of the speed that carries on sideways).
                cut = asin(min(max(contact.cut, 0), 1)) * 180 / Double.pi
                cutBall = contact.ball
            }
        }
        return StrikeFigures(swing: swing, centreSpeed: strike.speed, leaves: launch.speed, push: push,
                             force: push / tipContactTime, energy: energy,
                             topSpin: topRate / (2 * Double.pi), sideSpin: sideRate / (2 * Double.pi),
                             tipUp: strike.tipUp, tipSide: strike.tipSide,
                             cueAngle: asin(min(max(strike.elevation, 0), 1)) * 180 / Double.pi,
                             aimDegrees: atan2(cue.y, cue.x) * 180 / Double.pi, turnDegrees: turn,
                             cut: cut, cutBall: cutBall, miscue: launch.miscue)
    }

    /// The launch the solver gives this strike: speed, the offsets the spin is made from, and whether it miscues. A
    /// mirror of PoolSolver.cueLaunch (internal to the package), kept to its speed and offsets; the direction is read
    /// from the public launchDirection instead. Generation 1 strikes at full speed with the offsets as set.
    static func launch(_ s: CueStrike, _ p: PoolParameters) -> (speed: Double, tipUp: Double, tipSide: Double,
                                                                 miscue: Bool) {
        guard p.usesGenerationTwo else { return (s.speed, s.tipUp, s.tipSide, false) }
        let r2 = p.ballRadius * p.ballRadius
        let offset2 = s.tipUp * s.tipUp + s.tipSide * s.tipSide
        let limit = p.miscueOffsetLimit
        if offset2 > limit * limit {
            // The tip slid off: the ball gets a share of the speed, and the spin the tip could give at the grip limit.
            let back = (limit * limit / offset2).squareRoot()
            return (s.speed * p.miscueSpeedFraction, s.tipUp * back, s.tipSide * back, true)
        }
        let big = p.cueMass + p.ballMass
        let factor = big / (big + 2.5 * p.cueMass * offset2 / r2)
        return (s.speed * factor, s.tipUp, s.tipSide, false)
    }
}

// MARK: Planned against delivered

/// The strike the player set beside the strike the solver was given after their stroke drifted it, and which figures
/// came out different. Built from a played attempt (StrikeReading.comparison) or directly in tests.
struct StrikeComparison: Equatable, Sendable {
    let planned: StrikeFigures
    let delivered: StrikeFigures

    /// The figures a tile shows, for asking which differ.
    enum Figure: CaseIterable, Sendable {
        case swing, leaves, push, force, energy, topSpin, sideSpin, tipUp, tipSide, cueAngle, cut, aim
    }

    /// How far apart two readings must be to count as different: half of the last digit each tile shows, so a tile
    /// never shows two figures that print the same.
    private static func threshold(_ f: Figure) -> Double {
        switch f {
        case .swing, .leaves: return 0.005          // two decimals of m/s
        case .push, .energy: return 0.005           // two decimals of N·s and J
        case .force: return 0.5                     // whole newtons
        case .topSpin, .sideSpin: return 0.05       // one decimal of turns/s
        case .tipUp, .tipSide: return 0.00005       // a tenth of a millimetre
        case .cueAngle, .cut, .aim: return 0.05     // a tenth of a degree
        }
    }

    /// The value of one figure (nil for a cut with no ball in line).
    static func value(_ f: Figure, of s: StrikeFigures) -> Double? {
        switch f {
        case .swing: return s.swing
        case .leaves: return s.leaves
        case .push: return s.push
        case .force: return s.force
        case .energy: return s.energy
        case .topSpin: return s.topSpin
        case .sideSpin: return s.sideSpin
        case .tipUp: return s.tipUp
        case .tipSide: return s.tipSide
        case .cueAngle: return s.cueAngle
        case .cut: return s.cut
        case .aim: return s.aimDegrees
        }
    }

    /// True when the planned and delivered readings of `f` differ by more than the tile can hide.
    func differs(_ f: Figure) -> Bool {
        let a = Self.value(f, of: planned), b = Self.value(f, of: delivered)
        switch (a, b) {
        case (nil, nil): return false
        case let (a?, b?):
            var d = b - a
            // The aim is an angle on a circle: -179.9 and 179.9 are 0.2 degrees apart, not 359.8.
            if f == .aim { d = (d + 540).truncatingRemainder(dividingBy: 360) - 180 }
            return abs(d) > Self.threshold(f)
        default: return true   // a ball in line on one and not the other
        }
    }

    /// True when any figure differs (or one of the two miscued and the other did not).
    var anyDiffers: Bool { planned.miscue != delivered.miscue || Figure.allCases.contains { differs($0) } }

    /// The aim's error, degrees, positive when the cue turned to the shooter's left (counter-clockwise).
    var aimError: Double {
        let d = delivered.aimDegrees - planned.aimDegrees
        return (d + 540).truncatingRemainder(dividingBy: 360) - 180
    }

    /// The tip's sideways error, metres, positive to the right.
    var tipSideError: Double { delivered.tipSide - planned.tipSide }

    /// The one error worth a line on a small screen: the larger of the aim's turn and the tip's slide, each measured
    /// against the smallest amount a player would notice on the table (StrokeWords.bigTurn's half degree for the aim, a
    /// millimetre for the tip). Nil when neither shows.
    enum LargestError: Equatable, Sendable {
        case aim(degrees: Double)
        case tip(metres: Double)
        case miscue
    }

    var largestError: LargestError? {
        if delivered.miscue && !planned.miscue { return .miscue }
        let aim = differs(.aim) ? aimError : 0
        let tip = differs(.tipSide) ? tipSideError : 0
        guard aim != 0 || tip != 0 else { return nil }
        let aimWeight = abs(aim) / 0.5
        let tipWeight = abs(tip) / 0.001
        return aimWeight >= tipWeight ? .aim(degrees: aim) : .tip(metres: tip)
    }
}
