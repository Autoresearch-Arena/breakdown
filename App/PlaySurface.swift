// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The playing surfaces the same physics can be watched on: standard cloth, ice, glass, sand, carpet and
//          rubber. Each surface is only a set of friction and bounce numbers written into PoolParameters before a shot
//          is solved (the solver already takes every one of them from there), so a surface changes how far balls skid,
//          how soon they roll, how long they roll and spin, and how a jump lands, and nothing else. Cushions stay
//          rubber rails on every surface. The chosen surface is kept in UserDefaults under "optionSurface".
//          ShowpieceModel applies it to every shot it solves (setSurface re-solves the shot on screen); the look of each
//          surface lives in PlaySurfaceLook.swift.
// SRP/DRY check: Pass - checked Parameters.swift and Simulation.swift; this only picks numbers, it never copies solver
//          logic. Changing any number changes the parameter hash, which is correct: a shot on ice is a different
//          recording from the same shot on cloth.
import BreakdownPhysics
import Foundation

enum PlaySurface: String, CaseIterable, Identifiable, Sendable {
    case cloth, ice, glass, sand, carpet, rubber

    var id: String { rawValue }

    /// The surface's name for menus and labels.
    var title: String {
        switch self {
        case .cloth: return String(localized: "Cloth")
        case .ice: return String(localized: "Ice")
        case .glass: return String(localized: "Glass")
        case .sand: return String(localized: "Sand")
        case .carpet: return String(localized: "Carpet")
        case .rubber: return String(localized: "Rubber")
        }
    }

    /// SF Symbol for menus.
    var symbol: String {
        switch self {
        case .cloth: return "square.grid.3x3.fill"
        case .ice: return "snowflake"
        case .glass: return "sparkles"
        case .sand: return "aqi.medium"
        case .carpet: return "checkerboard.rectangle"
        case .rubber: return "circle.fill"
        }
    }

    /// Write this surface's friction and bounce numbers into the parameters. Cloth leaves the defaults untouched (so a
    /// cloth shot hashes exactly as it always did). Only the surface-contact numbers change: the cushions, ball-ball
    /// contact, gravity and table geometry are the same everywhere.
    ///
    /// How the numbers act in the solver (Simulation.makeSegment): a sliding ball slows at slidingFriction * g and turns
    /// to rolling after 2 * slip / (7 * slidingFriction * g) seconds; a rolling ball slows at rollingResistance * g and
    /// stops after speed / (rollingResistance * g); a ball spinning in place stops after spin / spinDecay. None of these
    /// divides by zero for any value below, and the solver itself stops every shot at 90 seconds (PoolSolver.maxTime),
    /// so even ice cannot run away.
    func apply(to p: inout PoolParameters) {
        switch self {
        case .cloth:
            break   // defaults: sliding 0.2, rolling 0.01, spin decay 9, slate bounce 0.5, slate friction 0.2
        case .ice:
            // A phenolic ball on smooth ice: almost no grip, so a struck ball skids a long way before it rolls.
            // Rolling resistance 0.002 is the top of the plausible range on purpose: a ball still rolling at 0.5 m/s
            // after the cushions have taken their share stops in about 25 s (0.5 / (0.002 * 9.81)); anything smaller
            // would leave the longest shots trailing on for most of the solver's 90 s cap.
            // Spin decay 2: spin barely dies (a break's leftover 20 rad/s of side spin lasts about 10 s).
            p.slidingFriction = 0.025
            p.rollingResistance = 0.002
            p.spinDecay = 2.0
            p.slateFriction = 0.03      // a landing jump barely grips the ice
        case .glass:
            // Hard and smooth: little grip and little rolling loss, and a hard bed that throws a jumping ball back up.
            p.slidingFriction = 0.09
            p.rollingResistance = 0.0025
            p.spinDecay = 3.0
            p.slateRestitution = 0.7
            p.slateFriction = 0.1
        case .sand:
            // Balls plough a furrow: heavy rolling loss (a 2 m/s roll is over in under two seconds), a grabby skid,
            // spin scrubbed off fast, and a soft bed that swallows a jump.
            p.slidingFriction = 0.5
            p.rollingResistance = 0.13
            p.spinDecay = 25.0
            p.slateRestitution = 0.15
            p.slateFriction = 0.5
        case .carpet:
            // Like a slow, thick cloth: more grip, about three and a half times the rolling loss, spin dies sooner.
            p.slidingFriction = 0.3
            p.rollingResistance = 0.035
            p.spinDecay = 14.0
        case .rubber:
            // Very grabby: a skid turns to rolling almost at once (a quarter of the cloth's skid time), and the bed is
            // springy, so jumps bounce high.
            p.slidingFriction = 0.8
            p.rollingResistance = 0.02
            p.spinDecay = 12.0
            p.slateRestitution = 0.75
            p.slateFriction = 0.8
        }
    }

    static let storageKey = "optionSurface"

    /// The surface last chosen on this device; cloth when none has been chosen (or the stored value is unknown).
    static var stored: PlaySurface {
        UserDefaults.standard.string(forKey: storageKey).flatMap(PlaySurface.init(rawValue:)) ?? .cloth
    }
}
