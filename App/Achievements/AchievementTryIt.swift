// Author: Claude Opus 5.5 Medium
// Date: 27-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 10, "Achievements and sharing": new file.)
// PURPOSE: "Try it" on an achievement not yet earned: where it can be earned, and taking the player there.
//            AchievementTryIt.place - the lesson, trick shot, situation or table for it: the lesson or trick itself;
//                                     a game against the computer at its level (only when no eight-ball game is saved,
//                                     so a saved game is never overwritten from here: the menu's own card asks first);
//                                     for a collection, the first item not done yet (a table, a surface on the pool
//                                     table, a lesson, a trick shot, a Behind the 8-Ball spot); the shot of the day for
//                                     its three; bumper pool for the bumper cup, five-pin for the red pin, and free play on
//                                     the pool table (a fresh rack, ready to break) for every other shot achievement.
//            AchievementTryIt.start - goes there through the routes the menu and the lists already use. The caller
//                                     closes the achievements list first (AchievementDetail's onClose), as "Watch it" does.
//          Nothing is pushed: it runs only when the player taps "Try it".
// SRP/DRY check: Pass - checked TrickShotMode.begin(id:), LessonMode.begin, EightBallMode.begin(id:), DailyMode.begin,
//          ShowpieceModel.playTable and setSurface, and MatchStartRequest.start (the menu's own match start, reused, so
//          a game starts exactly as it does from the menu). AchievementProgress (the stored progress) picks a
//          collection's next item; nothing here is stored.
import BreakdownRules
import Foundation

@MainActor
enum AchievementTryIt {
    /// Where an achievement can be earned.
    enum Place: Equatable {
        case lesson(String)
        case trick(String)
        case game(ComputerLevel)
        case table(TableKind)
        case surface(PlaySurface)
        case situation(String)
        case daily
    }

    /// Where `a` can be earned, or nil when there is nowhere to send the player (a collection already complete, or a
    /// game against the computer while an eight-ball game is saved).
    static func place(_ a: Achievement, progress: AchievementProgress, model: ShowpieceModel) -> Place? {
        if let id = a.lessonID { return .lesson(id) }
        if let id = a.trickID { return .trick(id) }
        if let level = a.level { return model.hasSavedMatch(.eightBall) ? nil : .game(level) }
        switch a.id {
        case "bumper-cup": return .table(.bumperPool)
        case "red-pin": return .table(.fivePin)
        case Achievements.everyTable:
            return TableKind.allCases.first { !progress.tablesPlayed.contains($0.rawValue) }.map { .table($0) }
        case Achievements.everySurface:
            return PlaySurface.allCases.first { !progress.surfacesPlayed.contains($0.rawValue) }.map { .surface($0) }
        case Achievements.everyLesson:
            return Lessons.all.first { !progress.lessonsDone.contains($0.id) }.map { .lesson($0.id) }
        case Achievements.everyTrick:
            return Achievements.playableTricks.first { !progress.tricksDone.contains($0.id) }.map { .trick($0.id) }
        case Achievements.everyEscape:
            return EightBallSituations.all.first { !progress.escapesWon.contains($0.id) }.map { .situation($0.id) }
        case Achievements.dailyStreakWeek, Achievements.dailyStreakMonth, Achievements.dailyFirstTry:
            return .daily
        default:
            // Every other shot achievement is read from any shot: free play on the pool table, a fresh rack.
            return Achievements.shotIDs.contains(a.id) ? .table(.standard) : nil
        }
    }

    /// Go there. The achievements list must already be closed (the caller's onClose), so nothing sits over the table.
    static func start(_ place: Place, model: ShowpieceModel) {
        switch place {
        case .lesson(let id):
            if let lesson = Lessons.lesson(id: id) { model.lessonMode.begin(lesson) }
        case .trick(let id):
            model.trickMode.begin(id: id)
        case .game(let level):
            MatchStartRequest(kind: .eightBall, computer: level).start(on: model)
        case .table(let kind):
            model.playTable(kind)
        case .surface(let surface):
            // Free play on the pool table, on the surface not played yet.
            model.playTable(.standard)
            model.setSurface(surface)
        case .situation(let id):
            model.eightBallMode.begin(id: id)
        case .daily:
            model.dailyMode.begin()
        }
    }
}
