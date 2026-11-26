// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The shot of the day as a mode (plans/25-Nov-2026-shot-of-the-day-plan.md, stage 2 item 1). A daily shot is a
//          trick shot with a date and a score, so this mode does not lay out, strike, replay or judge anything itself:
//          it puts today's shot (DailyBank, DailyShot) on the table through TrickShotMode.begin, on the shot's own
//          surface, and TrickShotMode plays it exactly as it plays every trick shot (the table layer's hooks, the shot
//          panel, the markers, the bridge, the raised cue locked to the shot's own angle as in every trick shot). This
//          mode is TrickShotMode's gate (TrickShotGate, below), which TrickShotMode asks at the few points where a daily
//          shot differs:
//          - Watch it is refused until the day is finished (made, or five tries used); after that the answer plays and
//            is explained in the Lens like any trick shot's.
//          - Your turn and Try again are refused once the day is finished: five tries, then stop.
//          - The player starts from a plain stroke with the shot's own cue angle (startSettings), never the answer.
//          - Each judged try (TrickShotJudge.verdict, from the trick's own start only) is counted here: on a make the
//            white ball's resting place is measured against the mark, scored (DailyScore) and written (DailyRecord); a
//            miss shows the judge's one sentence of advice, as trick shots do.
//          - A daily make never joins the trick shots' own progress (keepsProgress), but still glows and sounds.
//          - Leaving the shot (any route that ends trick-shot mode, or another trick shot begun) puts the player's own
//            surface back, as Behind the 8-Ball does.
//          The day's record (tries, make, score, streak) lives in DailyRecord, so a second visit the same day, even
//          after a relaunch, shows the result and takes no more tries.
//          Wave 2 hooks: `resultSink` (DailyResultSink) is the one place a finished day is reported, for Game Center to
//          post the score and the streak; `openBoard`, when set, shows the result card's Board button (hidden until
//          then). Nothing here imports GameKit.
//          Owned by ShowpieceModel (dailyMode, made on first use); read by DailyViews, DailyMenuRow, DailyShare and,
//          through the static `showing`, by the trick card, the phone's blurbs and primary action, the notebook's
//          dossier and the table layer, which hand a daily shot over to the views here.
// SRP/DRY check: Pass - checked TrickShotMode (the flow is reused through its gate, never copied), TrickShotJudge (made
//          or missed is decided there only), EightBallMode (the surface is put on and given back the same way) and
//          AchievementBook (the daily achievements are earned by its own sweep, from AchievementProgress).
import BreakdownAuthored
import BreakdownLensModel
import BreakdownPhysics
import Foundation
import Observation

/// What TrickShotMode asks of the mode that put a shot on the table, at the points where that shot differs from an
/// ordinary trick shot. Every answer is for the shot passed in; for a shot the gate does not own it returns the
/// ordinary trick-shot answer (true, nil). Set by DailyMode; read by TrickShotMode (each use marked "0.7.10 daily").
@MainActor
protocol TrickShotGate: AnyObject {
    /// Watch it may play the answer now.
    func mayWatch(_ shot: TrickShot) -> Bool
    /// Your turn and Try again may set up another try.
    func mayTry(_ shot: TrickShot) -> Bool
    /// The settings a player starts from before trying anything; nil for TrickShotMode's own default.
    func startSettings(for shot: TrickShot) -> TrickSettings?
    /// A make counts toward the trick shots' own progress (doneIDs) and walks on with Next shot.
    func keepsProgress(_ shot: TrickShot) -> Bool
    /// One attempt from the shot's own start has been judged.
    func judged(_ shot: TrickShot, attempt: ShotAttempt, verdict: TrickVerdict)
    /// The shot is leaving the table (trick-shot mode ended, or another shot begun).
    func left(_ shot: TrickShot)
}

/// One finished day, as reported to the board.
struct DailyResult: Equatable, Sendable {
    let day: Int
    let shotID: String
    let made: Bool
    /// 1 to 5; nil for five misses.
    let madeOnTry: Int?
    let tries: Int
    /// Metres from the mark on the try that made it; nil without a make or a mark.
    let distance: Double?
    let score: Int
    let streak: Int
    let bestStreak: Int
}

/// Where a finished day is reported. Wave 2 (stage 3) connects this to Game Center: post `score` to the daily board
/// and `streak` to the streak board, then DailyMode.markSent(day:) once posted. Called once per day, when the day
/// finishes (a make, or the fifth miss), on the main actor.
@MainActor
protocol DailyResultSink: AnyObject {
    func dailyFinished(_ result: DailyResult)
}

@MainActor
@Observable
final class DailyMode: TrickShotGate {
    /// The model this mode drives. The model owns the mode, so this does not keep the model alive.
    @ObservationIgnored unowned let model: ShowpieceModel
    /// Where the record is saved: .standard in the app, a throwaway suite in tests.
    @ObservationIgnored let defaults: UserDefaults
    /// The clock: the real one in the app, any date in tests.
    @ObservationIgnored let clock: () -> Date
    /// Wave 2: where a finished day is reported (Game Center). Nil until stage 3 connects it.
    @ObservationIgnored weak var resultSink: (any DailyResultSink)?
    /// Wave 2: opens the board. While nil the result card's Board button is hidden.
    @ObservationIgnored var openBoard: (@MainActor () -> Void)?

    /// The save, as loaded and as changed since.
    private(set) var record: DailyRecord
    /// Bumped on every change to the record, so the achievements' progress fingerprint (ShowpieceModel) sees it.
    private(set) var recordVersion = 0
    /// The shot on the table (or last put there), and its mark, solved once when the shot is begun.
    private(set) var shot: DailyShot?
    private(set) var mark: Vec2?
    /// The player's own surface from before the shot, put back when it leaves the table.
    @ObservationIgnored private var surfaceBefore: PlaySurface?

    init(model: ShowpieceModel, defaults: UserDefaults = .standard, clock: @escaping () -> Date = { Date() }) {
        self.model = model
        self.defaults = defaults
        self.clock = clock
        record = DailyRecord.load(from: defaults)
    }

    // MARK: Reading

    /// True while a daily shot is the trick shot on the table. Static, so the trick card and the other views can ask
    /// without making this mode.
    static func showing(_ model: ShowpieceModel) -> Bool {
        model.trickMode.isActive && DailyShot.isDailyID(model.trickMode.current?.id)
    }

    /// Today's day number, from the clock.
    var today: Int { DailyBank.day(at: clock()) }

    /// A day's play, or nil.
    func result(forDay day: Int) -> DailyRecord.Day? { record.day(day) }

    /// The play of the shot on the table (its own day, even past midnight), or nil before its first try.
    var current: DailyRecord.Day? { shot.flatMap { record.day($0.day) } }

    /// Tries used at the shot on the table.
    var triesUsed: Int { current?.tries ?? 0 }

    /// The shot on the table is finished: made, or five tries used.
    var finished: Bool { current?.finished ?? false }

    /// The streak as of the shot's day (today in the menu).
    func streak(asOf day: Int) -> Int { record.streak(asOf: day) }

    /// The white ball's distance from the mark for a resting place; nil without a mark.
    func distance(from rest: Vec2) -> Double? { mark.map { (rest - $0).length } }

    // MARK: Flow

    /// Put today's shot on the table: the menu closes (TrickShotMode.begin enters the trick table), the shot is laid
    /// out ready (Your turn, or the result if the day is already finished), and its surface goes on. Opening it again
    /// the same day shows the same day's record, so no try is given back.
    func begin() {
        let day = today
        let s = (shot?.day == day ? shot : nil) ?? DailyShot(day: day)
        if shot?.day != day || mark == nil { mark = s.findMark() }
        shot = s
        // Re-opened over the same shot: keep the surface recorded on the first entry (the table already wears this
        // shot's surface). Otherwise the player's own surface is read after begin, by which time leaving any earlier
        // shot or situation has already put theirs back.
        let sameShot = Self.showing(model) && model.trickMode.current?.id == s.trick.id
        model.trickMode.gate = self
        model.trickMode.begin(s.trick)
        if !sameShot { surfaceBefore = model.surface }
        // Through the model's own surface change, so the Surface menu, the 3D cloth and the solver agree. Nothing is
        // re-solved: the table is still (loadTrickLayout solves a zero-speed shot).
        model.setSurface(s.surface)
    }

    /// Your turn on the shot on the table (the card's Take your shot).
    func takeShot() { model.trickMode.yourTurn() }

    /// Try again (the card, after a miss).
    func tryAgain() { model.trickMode.tryAgain() }

    /// Watch the answer: only once the day is finished (the gate refuses it before).
    func watchAnswer() { model.trickMode.watch() }

    /// Count one try. Called by judged(...) for each attempt TrickShotJudge judged from the shot's own start; internal
    /// so the tests can drive the count without striking. `rest` is where the white ball stopped (nil when it dropped).
    /// Ignored once the day is finished.
    func noteTry(made: Bool, rest: Vec2?) {
        guard let s = shot, !finished else { return }
        let gap = made ? rest.flatMap { distance(from: $0) } : nil
        guard let day = record.noteTry(day: s.day, shotID: s.entry.id, made: made, distance: gap) else { return }
        record.save(to: defaults)
        recordVersion += 1
        if day.finished {
            let streak = record.streak(asOf: s.day)
            resultSink?.dailyFinished(DailyResult(day: s.day, shotID: s.entry.id, made: day.made, madeOnTry: day.madeOnTry,
                                                  tries: day.tries, distance: day.distance, score: day.score,
                                                  streak: streak, bestStreak: record.bestStreak))
        }
    }

    /// Wave 2: a day's score has reached the board. Saved at once.
    func markSent(day: Int) {
        guard record.markSent(day: day) else { return }
        record.save(to: defaults)
        recordVersion += 1
    }

    // MARK: TrickShotGate

    func mayWatch(_ shot: TrickShot) -> Bool {
        guard DailyShot.isDailyID(shot.id) else { return true }
        return owns(shot) && finished
    }

    func mayTry(_ shot: TrickShot) -> Bool {
        guard DailyShot.isDailyID(shot.id) else { return true }
        return owns(shot) && !finished
    }

    func startSettings(for shot: TrickShot) -> TrickSettings? {
        guard DailyShot.isDailyID(shot.id) else { return nil }
        // A medium stroke through the middle of the cue ball (TrickShotMode's own default; it then aims at the nearest
        // ball), with the shot's own cue angle: the daily shot sets it, as trick shots and Behind the 8-Ball do.
        return TrickSettings(aim: 0, power: 3, tipUp: 0, tipSide: 0, elevation: shot.solution.elevation)
    }

    func keepsProgress(_ shot: TrickShot) -> Bool { !DailyShot.isDailyID(shot.id) }

    func judged(_ shot: TrickShot, attempt: ShotAttempt, verdict: TrickVerdict) {
        guard DailyShot.isDailyID(shot.id), owns(shot) else { return }
        noteTry(made: verdict.made, rest: attempt.cueBallScratched ? nil : attempt.cueRest)
    }

    func left(_ shot: TrickShot) {
        guard DailyShot.isDailyID(shot.id) else { return }
        if let before = surfaceBefore { model.setSurface(before) }
        surfaceBefore = nil
    }

    /// The TrickShot is this mode's shot on the table (a daily id from another day is not counted here).
    private func owns(_ shot: TrickShot) -> Bool { self.shot?.trick.id == shot.id }
}
