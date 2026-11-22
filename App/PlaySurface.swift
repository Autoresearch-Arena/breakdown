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
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: with the tuned default rails (0.95) Tournament
//          cloth's cushions rise from 0.9 to 0.95 so they are no longer deader than the standard ones, and Dive-bar
//          felt's from 0.65 to 0.8 so its dead rails keep a believable share of the energy; checked with BreakProbe
//          surfaces, the results in plans/21-Nov-2026-physics-proof-plan.md.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6, items 27 and 38: the numbers moved to the
//          package (BreakdownAuthored's TableSurface), so the dev tool that authors and checks the Behind the 8-Ball
//          situations reads the very numbers played here instead of a copy; and the two real cloths were re-tuned either
//          side of the standard one so their words hold: tournament cloth slicker, faster and livelier, dive-bar felt
//          grabbier, slower and deader. This file keeps the names, the words, the symbols and the stored choice.)
// PURPOSE: The playing surfaces the same physics can be watched on: standard cloth, ice, glass, rubber, cork, carpet,
//          sand and the Moon. Each surface is only a set of numbers written into PoolParameters before a shot is solved
//          (the solver already takes every one of them from there; the numbers and their reasons are in the package,
//          TableSurface): friction and bounce numbers for most, gravity for the Moon. So a surface changes how far balls skid, how soon they roll, how long they roll and spin, and how a
//          jump lands, and nothing else. Cushions stay rubber rails on every surface. The chosen surface is kept in
//          UserDefaults under "optionSurface". ShowpieceModel applies it to every shot it solves (setSurface re-solves
//          the shot on screen); the look of each surface lives in PlaySurfaceLook.swift; CaptionEngine reads
//          `parameters` to explain, with the real numbers, what this surface does differently from cloth.
// SRP/DRY check: Pass - checked Parameters.swift, Simulation.swift and Impacts.swift; the numbers live once, in the
//          package's TableSurface, and this applies them; it never copies solver logic. Changing any number changes the
//          parameter hash, which is correct: a shot on ice is a different recording from the same shot on cloth.
import BreakdownAuthored
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

    /// The package's surface of the same name, whose numbers this one plays on.
    var tableSurface: TableSurface {
        switch self {
        case .cloth: return .cloth
        case .tournament: return .tournament
        case .diveBar: return .diveBar
        case .ice: return .ice
        case .glass: return .glass
        case .rubber: return .rubber
        case .cork: return .cork
        case .carpet: return .carpet
        case .sand: return .sand
        case .moon: return .moon
        }
    }

    /// The same surface from the package's name for it (the authored Behind the 8-Ball situations name theirs so).
    init(_ surface: TableSurface) {
        switch surface {
        case .cloth: self = .cloth
        case .tournament: self = .tournament
        case .diveBar: self = .diveBar
        case .ice: self = .ice
        case .glass: self = .glass
        case .rubber: self = .rubber
        case .cork: self = .cork
        case .carpet: self = .carpet
        case .sand: self = .sand
        case .moon: self = .moon
        }
    }

    /// Write this surface's numbers into the parameters (TableSurface.apply, where each number's reason is written).
    /// Cloth leaves the defaults untouched, so a cloth shot hashes exactly as it always did.
    func apply(to p: inout PoolParameters) {
        tableSurface.apply(to: &p)
    }

    /// True for the two other real cloths, whose cushions are covered in the same cloth as the bed (the standard cloth's
    /// cushions already are; every other surface keeps standard cloth on its rails).
    var coversCushions: Bool { tableSurface.coversCushions }

    static let storageKey = "optionSurface"

    /// The surface last chosen on this device; cloth when none has been chosen (or the stored value is unknown).
    static var stored: PlaySurface {
        UserDefaults.standard.string(forKey: storageKey).flatMap(PlaySurface.init(rawValue:)) ?? .cloth
    }
}
