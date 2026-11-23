// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Every word of "Same shot, every surface" (0.7.7, plans/23-Nov-2026-every-world-plan.md Build step 4 and
//          "Words to translate"): the entry's name and hint, the card's fixed line, the working and too-long lines,
//          "Played here", the buttons and their hints, and one whole sentence per WorldContrast case ("On Ice the cue
//          ball travels 6.1 m; here it went 2.0 m."), plus the trick-shot line and the two "much the same" lines. Each
//          is a whole String(localized:comment:) sentence, so a translator can reorder it (the translator notes are in
//          each call's comment, because the pending translation file carries keys and translations only). Numbers are
//          formatted first in the game's own language (AppLocale.numbers, as WhatIfWords does) and passed in as text;
//          balls are named by TableWords.ballName with the attempt's table, so the other tables name their own balls;
//          the surface's name is PlaySurface.title, already translated. No names of people, brands or places.
//          Read by EveryWorldFan (the sentences, the spoken lines) and EveryWorldViews (the menu item, chips, card,
//          panel and blurb), and by GameControllerInput.mapping (the controller row, nonisolated).
// SRP/DRY check: Pass - checked WhatIfWords (the what-if's own sentences; its number formatting and ball naming are
//          mirrored, not shared, because they are private there and say other things), TableWords.ballName (reused),
//          PlaySurface.title and summary (reused, not copied). These sentences exist nowhere else.
import BreakdownTimeline
import Foundation

@MainActor
enum EveryWorldWords {
    // MARK: Fixed lines

    static var title: String {
        String(localized: "Every surface", comment: "Name of the feature that plays the player's shot again on every playing surface at once (ice, glass, sand, the Moon...); menu item and panel title")
    }
    /// The entry's SF Symbol (the menu items, the card's and panel's title).
    static let symbol = "square.3.layers.3d"
    static var menuHint: String {
        String(localized: "Shows your shot played on every surface at once", comment: "VoiceOver hint on the Every surface menu item")
    }
    static var fixedLine: String {
        String(localized: "Same stroke on every surface.", comment: "Fixed line under the Every surface card's title: the same stroke was played on each surface")
    }
    static var working: String {
        String(localized: "Working out every surface", comment: "Shown while the game is still solving the shot on the other surfaces")
    }
    static var tooLong: String {
        String(localized: "This surface runs too long to show.", comment: "A surface on which the shot took too many events to work out, so it is not drawn")
    }
    static var playedHere: String {
        String(localized: "Played here", comment: "Small caption under the surface the shot was actually played on, in the Every surface chips and rows")
    }
    static var watchRoll: String {
        String(localized: "Watch them roll", comment: "Button: replays the shot with ghost balls rolling on every other surface beside the real one")
    }
    static var watchRollHint: String {
        String(localized: "Plays your shot again with every surface's balls rolling beside it", comment: "VoiceOver hint on Watch them roll")
    }
    static var showThis: String {
        String(localized: "Show this one", comment: "Small button on the Every surface sentence: draws only the surface the sentence talks about")
    }
    static var showAll: String {
        String(localized: "Show all", comment: "Small button: goes back from one picked surface to every surface's path")
    }
    static var chipHint: String {
        String(localized: "Shows this surface's paths", comment: "VoiceOver hint on a surface chip or row in Every surface")
    }

    static func playOn(_ s: PlaySurface) -> String {
        let surface = s.title
        return String(localized: "Play on \(surface)", comment: "Button: switches the game to this playing surface and plays the shot again on it. %@ is a surface name from the Surface menu (Ice, Moon, Dive-bar felt)")
    }

    static func playOnHint(_ s: PlaySurface) -> String {
        let surface = s.title
        return String(localized: "Changes the playing surface to \(surface) and plays your shot again on it", comment: "VoiceOver hint on Play on. %@ is a surface name from the Surface menu")
    }

    // MARK: The controller row (How to play's Controls page; read by the nonisolated mapping)

    nonisolated static var controllerControl: String {
        String(localized: "D-pad, with Every surface open", comment: "Controller mapping row: the d-pad while the Every surface panel is open")
    }
    nonisolated static var controllerAction: String {
        String(localized: "Left and right pick a surface. In free play A plays your shot on it. Once the balls stop, B closes Every surface.", comment: "Controller mapping row: what the d-pad, A and B do while Every surface is open")
    }

    // MARK: Numbers and names

    /// Metres or seconds with one decimal, in the game's language ("6,1" in French and German).
    private static func number(_ x: Double) -> String {
        x.formatted(.number.locale(AppLocale.numbers).precision(.fractionLength(1)))
    }

    /// A ball inside a sentence, named the way the attempt's table names it.
    private static func name(_ ball: Int, _ a: ShotAttempt) -> String {
        TableWords.ballName(ball, cueBall: a.cueBall, table: a.table)
    }

    // MARK: Sentences

    /// The trick-shot line: the real try missed and this surface makes the shot.
    static func trickMade(_ s: PlaySurface) -> String {
        let surface = s.title
        return String(localized: "On \(surface) this trick shot would have worked.", comment: "Every surface, in a trick shot: the player's try missed but on this surface the same stroke makes the shot. %@ is a surface name from the Surface menu (Ice, Moon, Dive-bar felt)")
    }

    /// One surface against the shot as played. `.alike` gives the short per-surface line; the fan's own "much the
    /// same" sentence is `fanAlike`.
    static func sentence(_ c: WorldContrast, surface s: PlaySurface, real: ShotAttempt) -> String {
        let surface = s.title
        let struck = name(real.cueBall, real)
        switch c {
        case let .gainsDrop(ball):
            let b = name(ball, real)
            return String(localized: "On \(surface) \(b) drops; here it stayed out.", comment: "Every surface: a ball drops on that surface that stayed on the table in the real shot. First %@ is a surface name from the Surface menu (Ice, Moon, Dive-bar felt); second %@ is a ball name (\"the 3 ball\", \"the cue ball\", or another table's ball such as \"the red\"). Translations may reorder with positional placeholders")
        case let .neverRolls(distance):
            let m = number(distance)
            return String(localized: "On \(surface) \(struck) never settles into a roll: it skids almost all of its \(m) m.", comment: "Every surface: on that surface the struck ball slides the whole way instead of rolling. First %@ is a surface name; second %@ is a ball name (\"the cue ball\"); third %@ is a distance already formatted (\"2.1\"); m is metres and follows the language's own symbol. Translations may reorder with positional placeholders")
        case let .neverReaches(ball):
            let b = name(ball, real)
            return String(localized: "On \(surface) \(struck) never reaches \(b).", comment: "Every surface: on that surface the struck ball stops before the ball it hit first in the real shot. First %@ is a surface name; second and third %@ are ball names (\"the cue ball\", \"the 3 ball\"). Translations may reorder with positional placeholders")
        case let .meetsOther(ball, insteadOf):
            let b = name(ball, real), was = name(insteadOf, real)
            return String(localized: "On \(surface) \(struck) meets \(b) first, not \(was).", comment: "Every surface: on that surface the struck ball touches a different ball first. First %@ is a surface name; the other three %@ are ball names (\"the cue ball\", \"the 3 ball\", \"the 5 ball\"). Translations may reorder with positional placeholders")
        case let .reaches(ball):
            let b = name(ball, real)
            return String(localized: "On \(surface) \(struck) reaches \(b); here it touched nothing.", comment: "Every surface: on that surface the struck ball reaches a ball, where in the real shot it touched none. First %@ is a surface name; second and third %@ are ball names. Translations may reorder with positional placeholders")
        case let .losesDrop(ball):
            let b = name(ball, real)
            return String(localized: "On \(surface) \(b) stays out; here it dropped.", comment: "Every surface: a ball that dropped in the real shot stays on the table on that surface. First %@ is a surface name; second %@ is a ball name. Translations may reorder with positional placeholders")
        case .struckDrops:
            return String(localized: "On \(surface) \(struck) drops into a pocket; here it stayed up.", comment: "Every surface: the struck ball falls into a pocket or hole on that surface but not in the real shot. First %@ is a surface name; second %@ is a ball name (\"the cue ball\"). Translations may reorder with positional placeholders")
        case .struckStaysUp:
            return String(localized: "On \(surface) \(struck) stays on the table; here it dropped.", comment: "Every surface: the struck ball fell into a pocket in the real shot but stays on the table on that surface. First %@ is a surface name; second %@ is a ball name. Translations may reorder with positional placeholders")
        case let .travel(world, home):
            let w = number(world), h = number(home)
            return String(localized: "On \(surface) \(struck) travels \(w) m; here it went \(h) m.", comment: "Every surface: how far the struck ball travels on that surface against the real shot. First %@ is a surface name; second %@ is a ball name; third and fourth %@ are distances already formatted (\"6.1\", \"2.0\"); m is metres and follows the language's own symbol. Translations may reorder with positional placeholders")
        case let .lasts(world, home):
            let w = number(world), h = number(home)
            return String(localized: "On \(surface) \(struck) keeps moving for \(w) seconds; here it stopped after \(h).", comment: "Every surface: how long the struck ball keeps moving on that surface against the real shot. First %@ is a surface name; second %@ is a ball name; third and fourth %@ are seconds already formatted (\"14.2\", \"3.1\"). Translations may reorder with positional placeholders")
        case .alike:
            return alike
        }
    }

    /// One surface that plays the shot much as it was played.
    static var alike: String {
        String(localized: "Much the same as here.", comment: "Every surface: this surface plays the shot about the same as the one it was played on")
    }

    /// The fan as a whole when every surface plays the shot much the same.
    static var fanAlike: String {
        String(localized: "Every surface plays this shot almost the same way: it is over before the surface makes much difference.", comment: "Every surface: the shot is so short that no surface changes it much")
    }

    /// A chip's or row's VoiceOver value: home's "Played here", the working line, the too-long line or its sentence.
    static func spoken(_ s: PlaySurface, fan: EveryWorldFan) -> String {
        s == fan.home ? playedHere : fan.sentence(for: s)
    }
}
