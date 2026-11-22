// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The numbers of every playing surface the same physics can be watched on (standard cloth, tournament cloth,
//          dive-bar felt, ice, glass, rubber, cork, carpet, sand and the Moon), in one place both the app and the
//          package's dev tool read (bug plan after 0.6.6, item 38: the dev tool used to carry a hand copy of the app's
//          PlaySurface numbers, marked KEEP IN STEP). Each surface is only a set of numbers written into PoolParameters
//          before a shot is solved: friction and bounce numbers for most, gravity for the Moon, and the cushions on the
//          two real cloths. The app's PlaySurface keeps the names, words, symbols and the stored choice, and applies
//          these numbers; the authored Behind the 8-Ball situations name their surface with this type.
//          Item 27 re-tuned the two real cloths either side of the standard one so each surface's own words hold:
//          tournament cloth slicker (it skids farther), livelier (it rolls farther, its spin lasts, its cushions give
//          back more) than standard; dive-bar felt grabbier (a skid is over sooner), slower and deader than standard.
// SRP/DRY check: Pass - numbers only; how each acts is the solver's (Simulation.makeSegment, Impacts). Moved here from
//          App/PlaySurface.swift with their reasons; nothing else holds them.
import BreakdownPhysics

public enum TableSurface: String, CaseIterable, Sendable {
    case cloth, tournament, diveBar, ice, glass, rubber, cork, carpet, sand, moon

    /// The full parameter set a shot on this surface is solved with.
    public var parameters: PoolParameters {
        var p = PoolParameters()
        apply(to: &p)
        return p
    }

    /// Write this surface's numbers into the parameters. Cloth leaves the defaults untouched (so a cloth shot hashes
    /// exactly as it always did). Only the surface-contact numbers change, plus gravity on the Moon and the cushions on
    /// the two real cloths; ball-ball contact and table geometry are the same everywhere.
    ///
    /// How the numbers act in the solver (Simulation.makeSegment): a sliding ball slows at slidingFriction * g and turns
    /// to rolling after 2 * slip / (7 * slidingFriction * g) seconds; a rolling ball slows at rollingResistance * g and
    /// stops after speed / (rollingResistance * g); a ball spinning in place stops after spin / spinDecay. So the
    /// distance a ball skids goes as 1 / (slidingFriction * g) and the distance it rolls as 1 / (rollingResistance * g).
    /// None of these divides by zero for any value below, and the solver stops every shot at 90 seconds
    /// (PoolSolver.maxTime), so even ice and the Moon cannot run away.
    public func apply(to p: inout PoolParameters) {
        switch self {
        case .cloth:
            break   // the defaults (PoolParameters): sliding 0.15, rolling 0.015, spin decay 9.5, rails 0.96
        case .tournament:
            // New worsted cloth (a tight napless weave), clean and dry: slicker, faster and livelier than the standard
            // cloth in every number that makes it so (bug plan after 0.6.6, item 27: it used to share the standard
            // cloth's grip and cushions, so its caption read "skids about 1 times as far").
            // Sliding 0.10: a third less grip than the standard 0.15, so a ball skids one and a half times as far
            // before it rolls and draw comes back farther (below the spec's 0.15 to 0.4 for pool cloth, which the tuned
            // standard cloth already sits at the bottom of; new worsted is the slickest cloth there is).
            // Rolling 0.005: the fast end of the spec's range, so a ball rolls three times as far as on standard.
            // Spin 5 rad/s squared: side spin lives nearly twice as long.
            // Cushions 0.98 at walking pace against the standard 0.96 (both fall with pace the same way): fresh, lively
            // rubber under new cloth, the top of the rail sweep's 0.94 to 0.98.
            p.slidingFriction = 0.10
            p.rollingResistance = 0.005
            p.spinDecay = 5.0
            p.cushionRestitution = 0.98
        case .diveBar:
            // Old woollen felt, napped, chalky and dirty, in a humid room: grabbier, slower and deader than the standard
            // cloth (item 27: it used to roll exactly like standard).
            // Sliding 0.3: twice the standard grip, so a skid (and with it draw) is over in half the time.
            // Rolling 0.02: a third more drag than standard (the nap and dirt), past the spec's 0.015 top for good
            // cloth, so a ball rolls three quarters as far and you hit harder.
            // Spin 14: dies fast. Cushions 0.8 at walking pace instead of 0.96: old, hard rubber.
            // The dirty cloth on the nose grips the ball more, along the rail (0.22 against 0.15) and across the nose
            // (0.15 against 0.10, the same half again), so side and spin take harder off the rail.
            p.slidingFriction = 0.3
            p.rollingResistance = 0.02
            p.spinDecay = 14.0
            p.cushionRestitution = 0.8
            p.cushionFriction = 0.22
            p.railCrossGrip = 0.15
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
        case .rubber:
            // Very grabby: a skid turns to rolling almost at once (a quarter of the cloth's skid time), and the bed is
            // springy, so jumps bounce high.
            p.slidingFriction = 0.8
            p.rollingResistance = 0.02
            p.spinDecay = 12.0
            p.slateRestitution = 0.75
            p.slateFriction = 0.8
        case .cork:
            // A cork board: the grain grips (sliding 0.45, so a skid is over in under half the cloth's time) and the
            // soft bed gives under the ball, so rolling loses twice what cloth does (0.03) and spin is scrubbed off fast
            // (15). Cork is springy to the touch but dull to a hard ball: the dent soaks up the landing, so a jump comes
            // back at only 0.3 of its fall speed, and the grippy face (0.45) takes most of the skid out of it.
            p.slidingFriction = 0.45
            p.rollingResistance = 0.03
            p.spinDecay = 15.0
            p.slateRestitution = 0.3
            p.slateFriction = 0.45
        case .carpet:
            // Like a slow, thick cloth: more grip, more than twice the rolling loss, spin dies sooner.
            p.slidingFriction = 0.3
            p.rollingResistance = 0.035
            p.spinDecay = 14.0
        case .sand:
            // Balls plough a furrow: heavy rolling loss (a 2 m/s roll is over in under two seconds), a grabby skid,
            // spin scrubbed off fast, and a soft bed that swallows a jump.
            p.slidingFriction = 0.5
            p.rollingResistance = 0.13
            p.spinDecay = 25.0
            p.slateRestitution = 0.15
            p.slateFriction = 0.5
        case .moon:
            // Moon dust packed flat, with exactly the cloth's friction numbers, so gravity is the ONE thing that
            // changes. Friction force is the friction number times the ball's weight, and weight is mass times g, so
            // with g at 1.62 instead of 9.81 every friction deceleration is about six times weaker: a ball skids and
            // rolls about six times as far and for six times as long. Low g is safe in the solver: sliding and rolling
            // segment lengths divide by g (never zero here); a jump's flight time is (vz + sqrt(vz^2 + 2 g h)) / g, so
            // jumps fly about six times longer and higher; spin in place decays at spinDecay, which has no g in it.
            p.gravity = 1.62
        }
    }

    /// True for the two other real cloths, whose cushions are covered in the same cloth as the bed (the standard
    /// cloth's cushions already are; every other surface keeps standard cloth on its rails).
    public var coversCushions: Bool { self == .tournament || self == .diveBar }
}
