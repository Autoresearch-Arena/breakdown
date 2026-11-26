// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The menu's "Shot of the day" row (plans/25-Nov-2026-shot-of-the-day-plan.md, stage 2 item 4): its name,
//          symbol, the one line that shows today's state (not played yet, tries left, made on which try and the score,
//          or missed), its mark (the streak, while there is one) and what it does (puts today's shot on the table).
//          TitleScreen's MenuRow draws it (that view is private to the menu's file, so TitleScreen builds the row from
//          these pieces in one marked line, above Play); the coordinator moves that line into the Today group of the
//          regrouped menu. No reminders and no pop-ups: this row is the only place the day's state is shown.
// SRP/DRY check: Pass - words come from DailyWords, the state from DailyMode and DailyRecord; the row's look is
//          TitleScreen's MenuRow, not copied.
import Foundation

@MainActor
enum DailyMenuRow {
    static var title: String { DailyWords.title }
    static let symbol = "calendar"

    /// Today's state in one line.
    static func line(_ model: ShowpieceModel) -> String {
        let daily = model.dailyMode
        guard let day = daily.result(forDay: daily.today) else { return DailyWords.menuNew }
        if let t = day.madeOnTry { return DailyWords.menuMade(onTry: t, score: day.score) }
        if day.finished { return DailyWords.menuMissed }
        return DailyWords.menuOpen(triesLeft: day.triesLeft)
    }

    /// The streak as of today, as the menu's mark (a flame, the number, and "Streak: 3" for VoiceOver); nil while there
    /// is no streak. Plain values, so TitleScreen turns them into its own MenuRow.Mark.
    static func mark(_ model: ShowpieceModel) -> (symbol: String, text: String, spoken: String)? {
        let daily = model.dailyMode
        let streak = daily.streak(asOf: daily.today)
        guard streak > 0 else { return nil }
        return ("flame.fill", DailyWords.number(streak), DailyWords.streakSpoken(streak))
    }

    /// The row's action: today's shot on the table (the menu closes as the trick table is entered).
    static func open(_ model: ShowpieceModel) {
        model.dailyMode.begin()
    }
}
