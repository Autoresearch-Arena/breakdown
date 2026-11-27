// Author: Claude Opus 5.5 Medium
// Date: 27-November-2026
// PURPOSE: The one glossary of shot names (UI rethink package 11, plans/26-Nov-2026-ui-rethink-plan.md): the six
//          techniques the game teaches, stop shot, follow, draw, throw, massé and jump, each with exactly one name. The
//          lessons take their titles from here, a trick shot's meta line names the techniques it uses from here
//          (TrickShot.techniques, TrickShots.swift), a technique achievement points here (Achievement.technique), and
//          the Physics Lens captions word their throw heading with it, so the player meets one word for one idea
//          wherever it shows. Two names are settled here on purpose:
//          - massé, not curve: the lesson "Curve", the achievement "Massé curve" and the trick shot "The massé" were
//            three names for one stroke (a raised cue struck off centre so the path bends while the ball slides). The
//            verb stays plain English ("bend round the 4"); the name of the stroke is massé.
//          - draw, not screw: one trick shot's hook said "screw the cue ball back"; draw is the name.
//          "Stun" in the captions is not a seventh name: it describes a ball leaving the cue with almost no spin (a
//          state of the ball), while a stop shot is the result at contact. The captions keep it.
//          Sentence case everywhere: a name at the start of a line is `name` ("Stop shot"), inside a sentence it is
//          `inSentence` ("stop shot", "massé"). Every name reuses the catalogue key the lessons and the eight-ball
//          escapes already use, so the translations already exist.
//          Pure data and words: nonisolated, Sendable, safe in tests and background tasks.
// SRP/DRY check: Pass - checked Lessons (titles now read from here), TrickShots (titles keep their playful words; the
//          technique list is read from here), AchievementWords (names still its own; a note asks it to read
//          Achievement.technique), EightBallEscapeKind.title (its "Jump" and "Massé" are the same keys, so the escapes
//          already agree) and Captions (the throw heading reads from here; the spin words "draw" and "follow" inside its
//          whole sentences are the same words). No other list of technique names exists.
import Foundation

/// One of the six techniques the game teaches, each with one name.
enum ShotTechnique: String, CaseIterable, Sendable {
    // Raw values are stable ids (not player text); "throw" is spelled out because throw is a Swift keyword.
    case stop, follow, draw, throwShot = "throw", masse, jump

    /// The name at the start of a line or as a title, sentence case ("Stop shot", "Massé"). The same keys as the
    /// lessons' and the eight-ball escapes' titles, already translated.
    var name: String {
        switch self {
        case .stop: return String(localized: "Stop shot")
        case .follow: return String(localized: "Follow")
        case .draw: return String(localized: "Draw")
        case .throwShot: return String(localized: "Throw")
        case .masse: return String(localized: "Massé")
        case .jump: return String(localized: "Jump")
        }
    }

    /// The name inside a sentence or after the first item of a list, lower case where the language lowers it
    /// ("draw and massé"). Its own keys, because some languages capitalise a noun mid-sentence and some do not.
    var inSentence: String {
        switch self {
        case .stop:
            return String(localized: "Shot name in a sentence: stop shot", defaultValue: "stop shot",
                          comment: "The stop shot's name inside a sentence or a list, lower case in English. The cue ball stops dead where it hits the object ball.")
        case .follow:
            return String(localized: "Shot name in a sentence: follow", defaultValue: "follow",
                          comment: "The follow shot's name inside a sentence or a list, lower case in English. Topspin carries the cue ball on after the hit.")
        case .draw:
            return String(localized: "Shot name in a sentence: draw", defaultValue: "draw",
                          comment: "The draw shot's name inside a sentence or a list, lower case in English. Backspin pulls the cue ball back after the hit.")
        case .throwShot:
            return String(localized: "Shot name in a sentence: throw", defaultValue: "throw",
                          comment: "Throw's name inside a sentence or a list, lower case in English. Friction between touching balls drags the struck ball off the line of centres.")
        case .masse:
            return String(localized: "Shot name in a sentence: massé", defaultValue: "massé",
                          comment: "The massé's name inside a sentence or a list, lower case in English. A raised cue struck off centre bends the cue ball's path.")
        case .jump:
            return String(localized: "Shot name in a sentence: jump", defaultValue: "jump",
                          comment: "The jump shot's name inside a sentence or a list, lower case in English. A raised cue makes the cue ball hop over a ball.")
        }
    }
}

enum ShotNames {
    /// The meta line naming the techniques a shot uses, sentence case: the first name as it starts a line, the rest as
    /// they read inside one, joined the way the game's language joins a list ("Draw and massé"). Nil when the shot
    /// uses none of the six (a bank, a kick, a combination, a break), so the line is simply left out.
    static func line(_ techniques: [ShotTechnique]) -> String? {
        guard let first = techniques.first else { return nil }
        let words = [first.name] + techniques.dropFirst().map(\.inSentence)
        return words.formatted(.list(type: .and).locale(AppLocale.numbers))
    }
}
