// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (two more surfaces: Cork, a soft grippy board, and Moon, cloth
//          friction under the Moon's gravity so gravity is the one thing that changes. Every surface now has a summary,
//          the one-line explanation shown under its name in the picker, and a parameters value the captions read their
//          numbers from.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (two real cloths either side of the standard one: Tournament cloth,
//          new clean worsted, and Dive-bar felt, old dirty napped felt with dead cushions. Their numbers are the ends of
//          the measured ranges: sliding friction 0.15 to 0.4,
//          rolling resistance 0.005 to 0.015, spin deceleration 5 to 15 rad/s squared, ball-rail restitution 0.6 to 0.9;
//          new clean cloth is slick and fast and old dirty
//          cloth is sticky, so draw wears off sooner, and plays slower. These two are the first surfaces that change the
//          cushions too, because worn bar tables have dead rails as well as slow cloth.)
// PURPOSE: The playing surfaces the same physics can be watched on: standard cloth, ice, glass, rubber, cork, carpet,
//          sand and the Moon. Each surface is only a set of numbers written into PoolParameters before a shot is solved
//          (the solver already takes every one of them from there): friction and bounce numbers for most, gravity for
//          the Moon. So a surface changes how far balls skid, how soon they roll, how long they roll and spin, and how a
//          jump lands, and nothing else. Cushions stay rubber rails on every surface. The chosen surface is kept in
//          UserDefaults under "optionSurface". ShowpieceModel applies it to every shot it solves (setSurface re-solves
//          the shot on screen); the look of each surface lives in PlaySurfaceLook.swift; CaptionEngine reads
//          `parameters` to explain, with the real numbers, what this surface does differently from cloth.
// SRP/DRY check: Pass - checked Parameters.swift, Simulation.swift and Impacts.swift; this only picks numbers, it
//          never copies solver logic. Changing any number changes the parameter hash, which is correct: a shot on ice is
//          a different recording from the same shot on cloth.
import BreakdownPhysics
import Foundation

enum PlaySurface: String, CaseIterable, Identifiable, Sendable {
    // Menu order: from slippery to grippy, then the Moon on its own (it changes gravity, not friction).
    // The real cloths come first, fastest to slowest (tournament, standard, dive bar), then the other materials.
    case cloth, tournament, diveBar, ice, glass, rubber, cork, carpet, sand, moon

    var id: String { rawValue }

    /// The surface's name for menus and labels.
    var title: String {
        switch self {
        case .cloth: return String(localized: "Cloth")
        case .tournament: return String(localized: "Tournament cloth")
        case .diveBar: return String(localized: "Dive-bar felt")
        case .ice: return String(localized: "Ice")
        case .glass: return String(localized: "Glass")
        case .sand: return String(localized: "Sand")
        case .carpet: return String(localized: "Carpet")
        case .rubber: return String(localized: "Rubber")
        case .cork: return String(localized: "Cork")
        case .moon: return String(localized: "Moon")
        }
    }

    /// One plain sentence, shown under the name in the picker: what this surface's numbers do to a shot, compared with
    /// cloth. Deliberately without figures (the Lens captions give the real numbers, read from `parameters`), so it
    /// stays true if a number below is tuned. The Moon's "one sixth" is the Moon's own gravity, not a tuning choice.
    var summary: String {
        switch self {
        case .cloth: return String(localized: "The standard table: a struck ball skids briefly, then rolls and slows steadily.")
        case .tournament: return String(localized: "New, clean worsted cloth as at a pro event: slick, so spin lasts and draw comes back far, fast, so balls roll a long way, and lively cushions.")
        case .diveBar: return String(localized: "Old, dirty, napped felt on a bar table: it grabs the ball, so draw dies early, it is slow, so you hit harder, and the cushions are dead.")
        case .ice: return String(localized: "Almost no grip: balls skid far before rolling, then roll for ages.")
        case .glass: return String(localized: "Smooth and hard: long skids, long rolls, and jumps bounce back up.")
        case .rubber: return String(localized: "Very grippy: a skid turns into a roll almost at once, and jumps bounce high.")
        case .cork: return String(localized: "Soft and grippy: skids end quickly, rolls die early, and jumps land with little bounce.")
        case .carpet: return String(localized: "Like a thick, slow cloth: shorter skids, and balls stop much sooner.")
        case .sand: return String(localized: "Balls plough a furrow: a roll dies within a second or two, and jumps sink in.")
        case .moon: return String(localized: "Cloth, but one sixth of Earth's gravity: everything slides and rolls six times farther, and jumps fly high.")
        }
    }

    /// SF Symbol for menus.
    var symbol: String {
        switch self {
        case .cloth: return "square.grid.3x3.fill"
        case .tournament: return "trophy.fill"
        case .diveBar: return "mug.fill"
        case .ice: return "snowflake"
        case .glass: return "sparkles"
        case .sand: return "aqi.medium"
        case .carpet: return "checkerboard.rectangle"
        case .rubber: return "circle.fill"
        case .cork: return "circle.grid.3x3.fill"     // the speckled grain of a cork board
        case .moon: return "moon.fill"
        }
    }

    /// The full parameter set a shot on this surface is solved with, for reading its numbers (captions compare them
    /// with cloth's). Built the same way the solver's input is, so what is explained is exactly what was solved.
    var parameters: PoolParameters {
        var p = PoolParameters()
        apply(to: &p)
        return p
    }

    /// Write this surface's numbers into the parameters. Cloth leaves the defaults untouched (so a cloth shot hashes
    /// exactly as it always did). Only the surface-contact numbers change, plus gravity on the Moon and the cushions
    /// on the two real cloths (tournament and dive bar); ball-ball contact and table geometry are the same everywhere.
    ///
    /// How the numbers act in the solver (Simulation.makeSegment): a sliding ball slows at slidingFriction * g and turns
    /// to rolling after 2 * slip / (7 * slidingFriction * g) seconds; a rolling ball slows at rollingResistance * g and
    /// stops after speed / (rollingResistance * g); a ball spinning in place stops after spin / spinDecay (no g: the
    /// solver treats spin decay as its own constant). So the distance a ball skids goes as 1 / (slidingFriction * g)
    /// and the distance it rolls as 1 / (rollingResistance * g). None of these divides by zero for any value below, and
    /// the solver itself stops every shot at 90 seconds (PoolSolver.maxTime), so even ice and the Moon cannot run away.
    func apply(to p: inout PoolParameters) {
        switch self {
        case .cloth:
            break   // defaults: sliding 0.2, rolling 0.01, spin decay 9, slate bounce 0.5, slate friction 0.2, g 9.81
        case .tournament:
            // New worsted cloth (a tight napless weave), clean and dry: the slick, fast end of every measured range.
            // Sliding 0.15 means a skid lasts a third longer than on the standard cloth, so draw and follow "take" late
            // and come back far; rolling 0.005 means a ball rolls twice as far; spin 5 rad/s squared means side spin
            // lives nearly twice as long; fresh cushions return 0.9 of the speed into them.
            p.slidingFriction = 0.15
            p.rollingResistance = 0.005
            p.spinDecay = 5.0
            p.cushionRestitution = 0.9
        case .diveBar:
            // Old woollen felt, napped, chalky and dirty, in a humid room: the sticky, slow end of the ranges. Sliding
            // 0.3 grabs the ball, so a skid (and with it draw) is over in two thirds of the standard time; rolling 0.015
            // makes it half again as slow, so the same speed goes two thirds as far; spin dies fast (14). The rubber is
            // old and hard: 0.65 of the speed comes back off a rail instead of 0.85, and the dirty cloth on the nose
            // grips the ball more (cushion friction 0.22), so side spin takes harder off the rail.
            p.slidingFriction = 0.3
            p.rollingResistance = 0.015
            p.spinDecay = 14.0
            p.cushionRestitution = 0.65
            p.cushionFriction = 0.22
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
            // soft bed gives under the ball, so rolling loses three times what cloth does (0.03) and spin is scrubbed
            // off fast (15). Cork is springy to the touch but dull to a hard ball: the dent soaks up the landing, so a
            // jump comes back at only 0.3 of its fall speed, and the grippy face (0.45) takes most of the skid out of it.
            p.slidingFriction = 0.45
            p.rollingResistance = 0.03
            p.spinDecay = 15.0
            p.slateRestitution = 0.3
            p.slateFriction = 0.45
        case .carpet:
            // Like a slow, thick cloth: more grip, about three and a half times the rolling loss, spin dies sooner.
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
            // The teaching point: moon dust packed flat, with exactly the cloth's friction numbers, so gravity is the
            // ONE thing that changes. Friction force is the friction number times the ball's weight, and weight is mass
            // times g, so with g at 1.62 instead of 9.81 every friction deceleration is about six times weaker: a ball
            // skids and rolls about six times as far and for six times as long.
            // Checked in the solver (Simulation.swift, Impacts.swift) that a low g is safe: sliding and rolling segment
            // lengths divide by g (never zero here); a jump's flight time is (vz + sqrt(vz^2 + 2 g h)) / g, so jumps
            // fly about six times longer and higher; the minimum-hop test (rise vz^2 / 2g against minimumHop) lets
            // smaller bounces count as hops, which is right under weak gravity. Spin in place decays at spinDecay,
            // which has no g in it, so it dies as fast as on cloth. A cloth break of about 10 s runs about a minute
            // here; the solver's 90 s cap ends anything longer, and playback has no short-shot assumptions.
            p.gravity = 1.62
        }
    }

    /// True for the two other real cloths, whose cushions are covered in the same cloth as the bed (the standard cloth's
    /// cushions already are; every other surface keeps standard cloth on its rails).
    var coversCushions: Bool { self == .tournament || self == .diveBar }

    static let storageKey = "optionSurface"

    /// The surface last chosen on this device; cloth when none has been chosen (or the stored value is unknown).
    static var stored: PlaySurface {
        UserDefaults.standard.string(forKey: storageKey).flatMap(PlaySurface.init(rawValue:)) ?? .cloth
    }
}
