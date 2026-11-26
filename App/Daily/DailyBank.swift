// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: Which shot of the day it is (plans/25-Nov-2026-shot-of-the-day-plan.md, stage 1 item 4). Two functions:
//          the day number for a moment (whole days since the bank's first day, both in Coordinated Universal Time, so
//          the shot and the board change at the same moment for every player in the world), and the bank entry for a
//          day number (the entry at that number, wrapping round when the list runs out). The clock is always a
//          parameter, so the tests can pass any date. The start is the release day of 0.7.10, the version that ships
//          stage 2: 26 November 2026, midnight UTC, day 0 (the player sees it as "Day 1").
//          Read by DailyShot (the shot for a day), DailyMode (today) and DailyViews (the time until the next shot).
// SRP/DRY check: Pass - date arithmetic only; the shots are the package library's (AuthoredDaily), the words and the
//          app's shot type are DailyShot's.
import BreakdownAuthored
import Foundation

enum DailyBank {
    /// The first day, 26 November 2026 at 00:00 in Coordinated Universal Time, as seconds since 1970 (a plain number,
    /// so no calendar or time zone can move it).
    static let startDate = Date(timeIntervalSince1970: 1_795_651_200)
    /// One day in seconds. Dates carry no leap seconds, so every UTC day is exactly this long.
    static let secondsPerDay = 86_400.0

    /// The day number of a moment: whole days since the start, counted down (floor), so the moment just before
    /// midnight is still the old day and a moment before the start gives a negative day.
    static func day(at moment: Date) -> Int {
        Int((moment.timeIntervalSince(startDate) / secondsPerDay).rounded(.down))
    }

    /// The bank entry for a day number: the entry at that number, wrapping round at the end of the list (a negative
    /// day wraps backwards, so every whole number has a shot). The bank is never empty (DailyBankTests checks it).
    static func entry(forDay day: Int, in bank: [AuthoredDailyShot] = AuthoredDaily.all) -> AuthoredDailyShot {
        let n = bank.count
        precondition(n > 0, "the shot of the day bank is empty")
        return bank[((day % n) + n) % n]
    }
}
