// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The shot of the day's link to the Game Center boards (0.7.10 wave 2 wiring; plans/25-Nov-2026-shot-of-the-day-plan.md
//          stage 3 items 4 to 6). DailyMode reports a finished day to its result sink and shows a Board button when
//          it has a way to open the board; this file is both, connected once when the model makes its daily mode
//          (ShowpieceModel.dailyMode, through connect).
//          The handover rule, one place for the live make and for the launch (DailyHandover.plan, pure):
//          - a day is handed over only while it is still that day (DailyBank's day, which turns at midnight in
//            Coordinated Universal Time, as the daily board does). A make: its score to the daily board and the streak
//            to the streak board. Five misses: nothing to post. Either way the day is then marked sent in DailyRecord,
//            so it is never handed over twice;
//          - a day already past (made late at night and never handed over, or left unsent by an app closed at the wrong
//            moment) is dropped: marked sent, nothing posted, because the board it was for has closed;
//          - a day not yet finished waits for its own end; a day after today (a clock set back) is left alone.
//          Handing over means putting the score in GameCenter's own saved queue (GameCenterQueue), which sends it once
//          signed in, exactly once, and drops a daily score whose day ends first. So an offline make, or one before the
//          first sign-in, is posted later by the queue; the record's mark only stops the record handing it over again.
//          With "Hide the board" on (or under a test launch) nothing is handed over and nothing is marked, so a player
//          who shows the board again the same day still has that day's score posted at the next launch.
//          The launch handover runs a turn after the mode is made (never inside a view's update), for every unsent
//          day in the record (handOverUnsent).
//          Reads and writes nothing itself: the record through DailyMode (result, record, streak, markSent), the board
//          through DailyBoardPoster (GameCenter in the app, a stand-in in BreakdownTests/DailyBoardLinkTests.swift).
// SRP/DRY check: Pass - checked GameCenter (posting, the queue and sign-in stay there; GameCenter conforms to the small
//          protocol here with its own methods, unchanged), DailyMode (the sink and openBoard hooks it already had) and
//          DailyRecord (the sent flag it already had). No other code hands daily scores to the board.
import Foundation

/// What the shot of the day needs from the board. GameCenter is the app's; the tests use a stand-in.
@MainActor
protocol DailyBoardPoster: AnyObject {
    /// False with "Hide the board" on or under a test launch. Nothing is handed over then, and nothing marked sent.
    var boardAllowed: Bool { get }
    /// A day's score, for the board of the day `playedAt` falls in.
    func postDaily(score: Int, playedAt: Date)
    /// The player's current streak, for the all-time streak board.
    func postStreak(_ days: Int)
    /// Open today's board (signing in first, the first time).
    func showBoard()
}

extension GameCenter: DailyBoardPoster {}

/// The handover rule for one day of the record, pure (see the file header).
enum DailyHandover {
    struct Plan: Equatable {
        /// The score to post to the daily board; nil for none.
        var score: Int?
        /// The streak to post to the streak board; nil for none.
        var streak: Int?
        /// Mark the day sent in the record (handed over, or dropped after its day).
        var markSent: Bool

        static let nothing = Plan(score: nil, streak: nil, markSent: false)
    }

    /// What to do with `day`, given the streak as of that day and today's day number (DailyBank.day).
    static func plan(for day: DailyRecord.Day, streak: Int, today: Int) -> Plan {
        guard !day.sent, day.day <= today else { return .nothing }
        // Past its day: the board it was for has closed. Dropped, so it is never looked at again.
        guard day.day == today else { return Plan(score: nil, streak: nil, markSent: true) }
        // Still being played today: its own end hands it over.
        guard day.finished else { return .nothing }
        // Five misses: nothing to post (an empty line on a board says nothing), but the day is dealt with.
        guard day.made else { return Plan(score: nil, streak: nil, markSent: true) }
        return Plan(score: day.score > 0 ? day.score : nil, streak: streak > 0 ? streak : nil, markSent: true)
    }
}

/// The daily mode's result sink: hands each finished day to the board under DailyHandover's rule.
@MainActor
final class DailyBoardLink: DailyResultSink {
    /// The mode reported from. The model owns both the mode and this link, so neither keeps the other alive.
    unowned let mode: DailyMode
    let poster: any DailyBoardPoster

    init(mode: DailyMode, poster: any DailyBoardPoster) {
        self.mode = mode
        self.poster = poster
    }

    /// Connect a freshly made mode to the board: its finished days come here, its result card and phone blurb get a
    /// Board button, and a turn later any day left unsent is handed over (or dropped). The caller keeps the link: the
    /// mode holds its sink weakly.
    static func connect(_ mode: DailyMode, poster: any DailyBoardPoster = GameCenter.shared) -> DailyBoardLink {
        let link = DailyBoardLink(mode: mode, poster: poster)
        mode.resultSink = link
        mode.openBoard = { poster.showBoard() }
        // A turn later: the mode is usually made while a view reads the menu row, and marking a day sent changes the
        // record, which must not happen inside a view's update.
        Task { @MainActor [weak link] in link?.handOverUnsent() }
        return link
    }

    // MARK: DailyResultSink

    func dailyFinished(_ result: DailyResult) {
        // The record already holds the finished day (DailyMode saves before reporting); the rule reads it from there,
        // with the streak the mode worked out for that day.
        guard let day = mode.result(forDay: result.day) else { return }
        hand(day, streak: result.streak)
    }

    // MARK: At launch

    /// Every day the record holds as unsent: today's finished day is handed over, past days are dropped. Safe to call
    /// any number of times: a day handed over is marked sent and skipped after.
    func handOverUnsent() {
        // A copy of the days, so marking one sent while walking them is safe.
        for day in mode.record.days where !day.sent {
            hand(day, streak: mode.streak(asOf: day.day))
        }
    }

    private func hand(_ day: DailyRecord.Day, streak: Int) {
        guard poster.boardAllowed else { return }
        let plan = DailyHandover.plan(for: day, streak: streak, today: mode.today)
        // The mode's own clock: the moment falls inside today, so GameCenter files the score under the same day.
        if let score = plan.score { poster.postDaily(score: score, playedAt: mode.clock()) }
        if let streak = plan.streak { poster.postStreak(streak) }
        if plan.markSent { mode.markSent(day: day.day) }
    }
}
