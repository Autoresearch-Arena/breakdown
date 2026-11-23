// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Every word of 0.7.7's achievements (plans/23-Nov-2026-achievements-plan.md, new file 2), in the
//          HighlightWords pattern: each achievement's name, its one plain sentence about the physics, and the hint on how
//          to earn it; the formatted lines (the date it was earned in the game's own number locale, "4 of 6", the menu's
//          mark and its spoken form, the note's spoken line, the end note's sentence); and the page's fixed lines.
//          Names are generic physics and shot names only: no people, brands or sources. Shot achievements that are one of
//          the judge's remarkable moments reuse that moment's sentence from HighlightWords (already translated); lesson
//          and trick-shot achievements are named with the lesson's or trick's own title. Every line goes through
//          String(localized:), so it reaches the string catalog; the new ones are in
//          localization/pending/v077-achievements.json with all eleven translations.
//          Read by Achievement (name, sentence, hint), AchievementBook (spoken lines), AchievementViews and TitleScreen
//          (the menu row's mark).
// SRP/DRY check: Pass - checked HighlightWords (its sentences are reused, never restated), OpponentWords
//          (ComputerLevel.title is reused for the progress picture), TitleScreen's lessonMark and trickMark (the "%lld/%lld"
//          and "%lld of %lld" keys are reused as they build them) and NumberStyle (AppLocale.numbers, the game's number
//          locale, for the date). Strings only.
import BreakdownRules
import Foundation

enum AchievementWords {
    // MARK: Each achievement

    /// The achievement's name.
    static func name(_ a: Achievement) -> String {
        if let id = a.lessonID, let lesson = Lessons.lesson(id: id) { return lesson.title }
        if let id = a.trickID, let trick = TrickShots.shot(id: id) { return trick.title }
        switch a.id {
        case "dead-stop":
            return String(localized: "Dead stop", comment: "Achievement name: the cue ball stopped dead where it hit the object ball")
        case "draw-back":
            return String(localized: "Draw back", comment: "Achievement name: backspin pulled the cue ball back after the hit")
        case "masse-curve":
            return String(localized: "Massé curve", comment: "Achievement name: a raised cue made the cue ball's path bend")
        case "jump-clear":
            return String(localized: "Over the top", comment: "Achievement name: the cue ball jumped over another ball")
        case "thrown-in": return String(localized: "Thrown in")
        case "combination": return String(localized: "Combination")
        case "kick":
            return String(localized: "Kick shot", comment: "Achievement name. Kick shot: a pool shot where the cue ball hits a cushion before any ball")
        case "bank":
            return String(localized: "Bank shot", comment: "Achievement name. Bank shot: a pool shot where the object ball goes off a cushion into the pocket")
        case "carom": return String(localized: "Carom")
        case "two-at-once": return String(localized: "Two at once")
        case "jaw-in":
            return String(localized: "In off the jaw", comment: "Achievement name: a ball touched the side of the pocket's mouth and still fell in")
        case "rattle-out":
            return String(localized: "Rattled out", comment: "Achievement name. Rattled out: a ball bounced between the pocket's jaws and did not fall")
        case "too-fast":
            return String(localized: "Too fast to drop", comment: "Achievement name: a ball crossed a pocket too fast to fall in")
        case "big-break":
            return String(localized: "Big break", comment: "Achievement name: three or more balls went down on one break")
        case "run-rack":
            return String(localized: "Run the rack", comment: "Achievement name. Run the rack: clearing the whole table from the break without missing")
        case "bumper-cup": return String(localized: "Off a bumper")
        case "red-pin": return String(localized: "The red pin alone")
        case "beat-easy": return String(localized: "Beat the computer: Easy")
        case "beat-medium": return String(localized: "Beat the computer: Medium")
        case "beat-hard": return String(localized: "Beat the computer: Hard")
        case Achievements.everyTable:
            return String(localized: "Every table", comment: "Achievement name: a shot played on each kind of table")
        case Achievements.everySurface:
            return String(localized: "Every surface", comment: "Achievement name: a shot played on each playing surface")
        case Achievements.everyLesson: return String(localized: "Every lesson")
        case Achievements.everyTrick: return String(localized: "Every trick shot")
        case Achievements.everyEscape:
            return String(localized: "Every way out", comment: "Achievement name: a medal won on every situation in Behind the 8-Ball")
        // Only an id that is not in the catalogue lands here (a trick shot or lesson removed in a later version whose
        // record is still stored); the catalogue's own ids are all named above.
        default: return a.id
        }
    }

    /// The achievement's one plain sentence about what happened.
    static func sentence(_ a: Achievement) -> String {
        if a.lessonID != nil { return String(localized: "You passed this lesson.") }
        if a.trickID != nil { return String(localized: "You made this trick shot.") }
        if a.level != nil { return String(localized: "You won a game against the computer at this level.") }
        // The judge's own sentence for the moment this achievement is (already translated). "Over the top" is narrower
        // than any jump, so it has its own.
        if let kind = Achievements.highlightKind(forShot: a.id) { return HighlightWords.line(kind) }
        switch a.id {
        case "jump-clear": return String(localized: "The cue ball left the cloth and flew over a ball in its way.")
        case "carom": return String(localized: "The cue ball glanced off one ball into another, and that one dropped.")
        case "jaw-in": return String(localized: "The ball touched the pocket's jaw and still fell in.")
        case "rattle-out": return String(localized: "The ball bounced between the pocket's jaws and stayed on the table.")
        case "big-break": return String(localized: "Three or more balls went down from one break.")
        case "run-rack": return String(localized: "From your break to an empty table, every shot dropped a ball.")
        case Achievements.everyTable: return String(localized: "You played a shot on every table.")
        case Achievements.everySurface: return String(localized: "You played a shot on every surface, the Moon included.")
        case Achievements.everyLesson: return String(localized: "You passed every lesson.")
        case Achievements.everyTrick: return String(localized: "You made every trick shot.")
        case Achievements.everyEscape: return String(localized: "You won a medal on every spot.")
        default: return ""
        }
    }

    /// How to earn it, shown while it is not earned yet.
    static func hint(_ a: Achievement) -> String {
        if a.lessonID != nil { return String(localized: "Pass this lesson in Learn.") }
        if a.trickID != nil { return String(localized: "Make this trick shot in Trick shots.") }
        if let level = a.level {
            switch level {
            case .easy: return String(localized: "Win a game against the computer at Easy.")
            case .medium: return String(localized: "Win a game against the computer at Medium.")
            case .hard: return String(localized: "Win a game against the computer at Hard.")
            }
        }
        switch a.id {
        case "dead-stop": return String(localized: "Hit a ball full and firm so the cue ball stops on the spot and the ball drops.")
        case "draw-back": return String(localized: "Strike low on the cue ball so it spins back after the hit.")
        case "masse-curve": return String(localized: "Raise the cue steeply and hit off centre so the cue ball bends before it reaches a ball.")
        case "jump-clear": return String(localized: "Raise the cue and hit down on the cue ball to hop it over a ball.")
        case "thrown-in": return String(localized: "Cut a ball softly so friction at the contact turns it into the pocket.")
        case "combination": return String(localized: "Send one ball into another so the second one drops.")
        case "kick": return String(localized: "Send the cue ball off a cushion first, then into a ball.")
        case "bank": return String(localized: "Drop a ball off a cushion.")
        case "carom": return String(localized: "Glance the cue ball off one ball so it knocks a second ball in.")
        case "two-at-once": return String(localized: "Drop two balls with one stroke.")
        case "jaw-in": return String(localized: "Drop a ball that touches the side of the pocket on its way in.")
        case "rattle-out": return String(localized: "Hit the pocket's jaws hard enough that the ball bounces out.")
        case "too-fast": return String(localized: "Roll a ball over a hole faster than it can fall in.")
        case "big-break": return String(localized: "Break the rack hard and square.")
        case "run-rack": return String(localized: "In free play, break and then drop a ball with every shot until the table is clear, without losing the cue ball.")
        case "bumper-cup": return String(localized: "On the bumper pool table, play a ball off a bumper into a cup.")
        case "red-pin": return String(localized: "On the five-pin table, knock down only the red pin.")
        case Achievements.everyTable: return String(localized: "Play a shot on each table in Tables.")
        case Achievements.everySurface: return String(localized: "Play a shot on each surface in the Surface menu.")
        case Achievements.everyLesson: return String(localized: "Pass every lesson in Learn.")
        case Achievements.everyTrick: return String(localized: "Make every trick shot.")
        case Achievements.everyEscape: return String(localized: "Win a medal on each spot in Behind the 8-Ball.")
        default: return ""
        }
    }

    // MARK: Formatted lines

    /// "Earned 12 Nov 2026": the date in the game's own number locale (AppLocale.numbers), never the bare default,
    /// so a French game on an English phone writes a French date.
    static func earnedOn(_ date: Date) -> String {
        let day = date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(AppLocale.numbers))
        return String(localized: "Earned \(day)", comment: "Achievements: the date an achievement was earned, e.g. 'Earned 12 Nov 2026'")
    }

    /// "4 of 6" for a collection's progress (the existing "%lld of %lld" key).
    static func progress(done: Int, total: Int) -> String {
        String(localized: "\(done) of \(total)")
    }

    /// The menu row's short mark, "12/44" (the existing "%lld/%lld" key, as the trick-shot mark builds it).
    static func menuMark(earned: Int, total: Int) -> String {
        String(localized: "\(earned)/\(total)")
    }

    /// The menu row's mark for VoiceOver: "12 of 44 earned, 3 new", or without the new part when nothing is new.
    static func menuSpoken(earned: Int, total: Int, new: Int) -> String {
        new > 0 ? String(localized: "\(earned) of \(total) earned, \(new) new")
                : String(localized: "\(earned) of \(total) earned")
    }

    /// The menu row's mark symbol. MenuRow.Mark has a symbol, a short text and a spoken text only, so the eye sees the
    /// "new" state as the symbol changing (sparkles while something is new) and VoiceOver hears the count.
    static func menuSymbol(new: Int) -> String { new > 0 ? "sparkles" : "checkmark.circle.fill" }

    /// The note's caption.
    static var earnedCaption: String {
        String(localized: "Achievement earned", comment: "Small note shown when the player earns an achievement")
    }

    /// The note's line for VoiceOver, said once when it appears: "Achievement earned: Bank shot".
    static func toastSpoken(name: String) -> String {
        String(localized: "Achievement earned: \(name)")
    }

    /// The end note after an achievement's replay: "That was your Bank shot."
    static func replayEnded(name: String) -> String {
        String(localized: "That was your \(name).", comment: "Shown after replaying the shot that earned an achievement; the placeholder is the achievement's name")
    }

    /// The end note's button and the list's title (the menu row uses the same key as a literal).
    static var listTitle: String { String(localized: "Achievements") }

    /// A row that is not earned yet.
    static var notEarned: String { String(localized: "Not earned yet") }

    /// The list's footer.
    static var footer: String { String(localized: "Every shot you play is read for these, in any mode.") }

    /// An earned collection with no single shot of its own.
    static var noSingleShot: String { String(localized: "No single shot to replay for this one.") }

    /// Under "Watch it in the Lens" when the kept shot, solved again, no longer plays out as it was recorded.
    static var playedAgain: String {
        String(localized: "Played again with today's physics, so it may not end the same way.")
    }
}
