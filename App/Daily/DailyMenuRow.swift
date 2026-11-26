// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 wiring: the row is now drawn like every other menu row, from
//          MenuGuide.daily (its name, symbol and one general sentence, also listed on How to play's menu page), so
//          today's state moved from the sentence into the row's mark: a ring of today's state with the tries used out
//          of five once played, the streak's flame before today's first try, and the whole state in words for
//          VoiceOver. The name and symbol now come from MenuGuide, one place.)
// PURPOSE: The menu's "Shot of the day" row (plans/25-Nov-2026-shot-of-the-day-plan.md, stage 2 item 4): its name,
//          symbol, the one line that shows today's state (not played yet, tries left, made on which try and the score,
//          or missed), its mark and what it does (puts today's shot on the table). The mark shows today's state at a
//          glance: nothing tried yet, the streak (a flame and the number) while there is one, else no mark; tries used,
//          a half ring and "2/5"; made, a tick and the try that made it ("2/5"); missed, a cross and "5/5". VoiceOver
//          reads the state's whole sentence and the streak. TitleScreen's MenuRow draws it (that view is private to the
//          menu's file, so TitleScreen turns the mark's plain values into its own MenuRow.Mark), first in the Today
//          group. No reminders and no pop-ups: this row is the only place the day's state is shown.
// SRP/DRY check: Pass - words come from DailyWords, the state from DailyMode and DailyRecord, the name and symbol from
//          MenuGuide.daily; the row's look is TitleScreen's MenuRow, not copied.
import Foundation

@MainActor
enum DailyMenuRow {
    static var title: String { MenuGuide.daily.title }
    static var symbol: String { MenuGuide.daily.symbol }

    /// Today's state in one line.
    static func line(_ model: ShowpieceModel) -> String {
        let daily = model.dailyMode
        guard let day = daily.result(forDay: daily.today) else { return DailyWords.menuNew }
        if let t = day.madeOnTry { return DailyWords.menuMade(onTry: t, score: day.score) }
        if day.finished { return DailyWords.menuMissed }
        return DailyWords.menuOpen(triesLeft: day.triesLeft)
    }

    /// Today's state as the menu's mark (see the file header); nil before today's first try with no streak. Plain
    /// values, so TitleScreen turns them into its own MenuRow.Mark.
    static func mark(_ model: ShowpieceModel) -> (symbol: String, text: String, spoken: String)? {
        let daily = model.dailyMode
        let streak = daily.streak(asOf: daily.today)
        let streakWords = streak > 0 ? " " + DailyWords.streakSpoken(streak) : ""
        guard let day = daily.result(forDay: daily.today), day.tries > 0 else {
            guard streak > 0 else { return nil }
            return ("flame.fill", DailyWords.number(streak), DailyWords.streakSpoken(streak))
        }
        let symbol = day.made ? "checkmark.circle.fill" : day.finished ? "xmark.circle" : "circle.lefthalf.filled"
        // The same "3/10" form the other rows' marks use; the try that made it, or the tries used.
        let used = day.madeOnTry ?? day.tries
        let text = String(localized: "\(used)/\(DailyRecord.maxTries)")
        return (symbol, text, line(model) + streakWords)
    }

    /// The row's action: today's shot on the table (the menu closes as the trick table is entered).
    static func open(_ model: ShowpieceModel) {
        model.dailyMode.begin()
    }
}
