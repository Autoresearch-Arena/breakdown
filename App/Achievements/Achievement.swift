// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 daily, plans/25-Nov-2026-shot-of-the-day-plan.md stage 2
//          item 6: a sixth group, Shot of the day, with three achievements: a streak of seven days, a streak of thirty,
//          and a make on the first try. Their ids are permanent like every other.)
// PURPOSE: The achievements catalogue for 0.7.7 (plans/23-Nov-2026-achievements-plan.md, new file 1). Every achievement
//          the game can award, in the order the list shows them, in five groups: Shots (seventeen physically interesting
//          things a single stroke can do), Games (beating the computer at each level, a shot on every table and on every
//          surface), Lessons (one per lesson and one for all of them), Trick shots (one per playable trick shot and one
//          for all of them) and Behind the 8-Ball (a medal on every spot).
//          Each has a permanent id (lowercase with dashes; a later Game Center id would be "breakdown." plus it, so the
//          ids must never change once shipped), an SF Symbol and the kind of progress picture a collection draws. The
//          catalogue holds no words: the name, sentence and hint come from AchievementWords. Lesson and trick-shot ids
//          are built from the content's own ids ("lesson-" + lesson id, "trick-" + trick id), never from titles, so a
//          lesson or trick shot added later brings its own achievement and nothing counts them by hand.
//          Read by AchievementJudge (shot ids), AchievementProgress (collection ids), AchievementBook (counts) and the
//          views (AchievementViews.swift). Pure data: nonisolated, Sendable, safe in tests and background tasks.
// SRP/DRY check: Pass - checked HighlightKind (App/ShotHighlight.swift: the remarkable moments a shot can have; the
//          shot achievements map onto it here, in one table, rather than copying it), Lessons.all, TrickShots.all,
//          EightBallSituations.all, TableKind, PlaySurface and ComputerLevel (the content lists the collections are
//          built from, read, never restated). No other catalogue of achievements exists.
import BreakdownRules
import Foundation

/// The five sections of the achievements list, in the order they show.
enum AchievementGroup: String, CaseIterable, Sendable {
    // 0.7.10 daily: the shot of the day's group, after the trick shots.
    case shots, games, lessons, tricks, daily, escapes

    /// The section's heading. "Lessons", "Trick shots" and "Behind the 8-Ball" are the menu's own, already translated.
    var title: String {
        switch self {
        case .shots:
            return String(localized: "Shots",
                          comment: "Achievements list section: achievements earned by the physics of one pool shot")
        case .games:
            return String(localized: "Games",
                          comment: "Achievements list section: achievements for games against the computer, tables and playing surfaces")
        case .lessons: return String(localized: "Lessons")
        case .tricks: return String(localized: "Trick shots")
        // 0.7.10 daily: the menu row's own name, the same key.
        case .daily: return String(localized: "Shot of the day")
        case .escapes: return String(localized: "Behind the 8-Ball")
        }
    }
}

/// What a collection draws as its progress picture (a grid of its items, each ticked or empty). `none` for an
/// achievement that is one thing done once (every shot achievement, one lesson, one trick shot).
enum AchievementProgressKind: Sendable, Equatable {
    case none, lessons, tricks, escapes, levels, tables, surfaces
}

/// One achievement. Words are read from AchievementWords, so the catalogue itself never needs translating.
struct Achievement: Identifiable, Equatable, Sendable {
    /// Permanent: stored in the player's save and meant for a later Game Center id. Never rename one.
    let id: String
    let group: AchievementGroup
    /// SF Symbol name (not player text).
    let symbol: String
    let progress: AchievementProgressKind

    var name: String { AchievementWords.name(self) }
    var sentence: String { AchievementWords.sentence(self) }
    var hint: String { AchievementWords.hint(self) }

    /// The lesson this achievement is for (lesson-<id>), or nil.
    var lessonID: String? {
        id.hasPrefix(Achievements.lessonPrefix) ? String(id.dropFirst(Achievements.lessonPrefix.count)) : nil
    }

    /// The trick shot this achievement is for (trick-<id>), or nil.
    var trickID: String? {
        id.hasPrefix(Achievements.trickPrefix) ? String(id.dropFirst(Achievements.trickPrefix.count)) : nil
    }

    /// The computer's level this achievement is for (beat-<level>), or nil.
    var level: ComputerLevel? {
        id.hasPrefix(Achievements.levelPrefix)
            ? ComputerLevel(rawValue: String(id.dropFirst(Achievements.levelPrefix.count))) : nil
    }
}

/// The catalogue.
enum Achievements {
    // MARK: Ids

    /// The shot achievements, in the list's order (the plan's table). Each is read from the recording of a shot the
    /// player struck (AchievementJudge).
    static let shotIDs: [String] = [
        "dead-stop", "draw-back", "masse-curve", "jump-clear", "thrown-in", "combination", "kick", "bank", "carom",
        "two-at-once", "jaw-in", "rattle-out", "too-fast", "big-break", "run-rack", "bumper-cup", "red-pin",
    ]

    static let lessonPrefix = "lesson-"
    static let trickPrefix = "trick-"
    static let levelPrefix = "beat-"

    static let everyTable = "every-table"
    static let everySurface = "every-surface"
    static let everyLesson = "every-lesson"
    static let everyTrick = "every-trick"
    static let everyEscape = "every-escape"
    // 0.7.10 daily: the shot of the day's three (permanent ids, as all the others).
    static let dailyStreakWeek = "daily-streak-7"
    static let dailyStreakMonth = "daily-streak-30"
    static let dailyFirstTry = "daily-first-try"
    /// The streak lengths the two streak achievements ask for, in days.
    static let dailyWeekDays = 7
    static let dailyMonthDays = 30

    static func lessonAchievementID(_ lessonID: String) -> String { lessonPrefix + lessonID }
    static func trickAchievementID(_ trickID: String) -> String { trickPrefix + trickID }
    static func levelAchievementID(_ level: ComputerLevel) -> String { levelPrefix + level.rawValue }

    /// The trick shots that can be played (a pending one waits on physics the solver does not have yet, so it can
    /// neither be made nor count toward "every trick shot").
    static var playableTricks: [TrickShot] { TrickShots.all.filter { !$0.pending } }

    // MARK: Shot achievements and the judge's moments

    /// The shot achievements that are exactly one of ShotHighlightJudge's remarkable moments, so a shot is never
    /// "remarkable" in one place and not in the other. The jump is left out on purpose: "Over the top" also needs the
    /// cue ball to have passed over another ball (AchievementJudge.clearsBall), which is narrower than any jump. Carom,
    /// jaw-in, rattle-out, big-break and run-rack have no moment of their own.
    private static let fromHighlight: [(kind: HighlightKind, id: String)] = [
        (.stopDead, "dead-stop"), (.drawBack, "draw-back"), (.curve, "masse-curve"), (.throwIn, "thrown-in"),
        (.combination, "combination"), (.kick, "kick"), (.bank, "bank"), (.multiPot, "two-at-once"),
        (.rimSkip, "too-fast"), (.bumperCup, "bumper-cup"), (.redPinAlone, "red-pin"),
    ]

    /// The shot achievement a remarkable moment earns on its own, or nil (the break, and the jump, which needs more).
    static func shotID(for kind: HighlightKind) -> String? { fromHighlight.first { $0.kind == kind }?.id }

    /// The remarkable moment a shot achievement is, for reusing that moment's already translated sentence; nil for the
    /// shot achievements that have their own words.
    static func highlightKind(forShot id: String) -> HighlightKind? { fromHighlight.first { $0.id == id }?.kind }

    /// Symbols for the shot achievements (all present in SF Symbols on iOS 26 and macOS 26; if one draws blank, swap
    /// it for "star.circle" here: the id never changes).
    private static func shotSymbol(_ id: String) -> String {
        switch id {
        case "dead-stop": return "stop.circle"
        case "draw-back": return "arrow.uturn.backward.circle"
        case "masse-curve": return "point.topleft.down.curvedto.point.bottomright.up"
        case "jump-clear": return "arrow.up.and.down.circle"
        case "thrown-in": return "wind"
        case "combination": return "link.circle"
        case "kick": return "arrow.turn.up.right"
        case "bank": return "arrow.triangle.swap"
        case "carom": return "arrow.triangle.branch"
        case "two-at-once": return "circle.grid.2x1.fill"
        case "jaw-in": return "smallcircle.filled.circle"
        case "rattle-out": return "circle.dotted"
        case "too-fast": return "hare"
        case "big-break": return "burst"
        case "run-rack": return "checkmark.seal"
        case "bumper-cup": return "circle.circle"
        case "red-pin": return "pin"
        default: return "star.circle"
        }
    }

    // MARK: The whole list

    /// Every achievement, in group order and in each group's own order. Built once from the content lists.
    static let all: [Achievement] = build()

    private static func build() -> [Achievement] {
        var out: [Achievement] = []
        for id in shotIDs {
            out.append(Achievement(id: id, group: .shots, symbol: shotSymbol(id), progress: .none))
        }
        // Games: one per computer level (its picture is the three levels, ticked as beaten), then the two collections.
        for level in ComputerLevel.allCases {
            out.append(Achievement(id: levelAchievementID(level), group: .games, symbol: "person.2", progress: .levels))
        }
        out.append(Achievement(id: everyTable, group: .games, symbol: "square.grid.2x2", progress: .tables))
        out.append(Achievement(id: everySurface, group: .games, symbol: "square.stack.3d.up", progress: .surfaces))
        for lesson in Lessons.all {
            out.append(Achievement(id: lessonAchievementID(lesson.id), group: .lessons, symbol: "graduationcap",
                                   progress: .none))
        }
        out.append(Achievement(id: everyLesson, group: .lessons, symbol: "graduationcap", progress: .lessons))
        for trick in playableTricks {
            out.append(Achievement(id: trickAchievementID(trick.id), group: .tricks, symbol: "wand.and.sparkles",
                                   progress: .none))
        }
        out.append(Achievement(id: everyTrick, group: .tricks, symbol: "wand.and.sparkles", progress: .tricks))
        // 0.7.10 daily: one thing done once each, so no progress picture.
        out.append(Achievement(id: dailyStreakWeek, group: .daily, symbol: "flame", progress: .none))
        out.append(Achievement(id: dailyStreakMonth, group: .daily, symbol: "flame.fill", progress: .none))
        out.append(Achievement(id: dailyFirstTry, group: .daily, symbol: "1.circle", progress: .none))
        out.append(Achievement(id: everyEscape, group: .escapes, symbol: "8.circle.fill", progress: .escapes))
        return out
    }

    /// Lookup by id. A duplicate id would be a catalogue mistake; the first one wins rather than trapping at launch.
    private static let byID: [String: Achievement] = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

    static func achievement(id: String) -> Achievement? { byID[id] }

    /// One group's achievements, in order.
    static func inGroup(_ g: AchievementGroup) -> [Achievement] { all.filter { $0.group == g } }
}
