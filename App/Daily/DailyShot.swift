// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: One day's shot as the app plays it (plans/25-Nov-2026-shot-of-the-day-plan.md, stage 1 item 3): a bank entry
//          (AuthoredDaily) wrapped as a TrickShot, so TrickShotMode lays it out and plays it and TrickShotJudge judges
//          it exactly as it does every trick shot, plus the day number, the surface, the family and the mark.
//          The TrickShot's id is "daily-" plus the entry's id, so it never mixes with the trick shots' own progress,
//          saved settings or achievements (TrickShotMode asks DailyMode, its gate, about anything daily). Its title is
//          "Shot of the day" (the phone's title row shows it), never the trick's own name, and its goal line is the goal
//          alone: the trick's hook and idea say how it is done, so they wait until the day is finished.
//          Words: a trick-shot entry borrows the trick's own goal line, idea, maths and praise (already translated); an
//          escape entry says "Pot the 3 in the foot-left corner pocket." (or "Bank ..."), built from TableWords'
//          translated pocket phrases, and its idea is the situation's lesson.
//          The mark: the entry's written mark, or else where the answer leaves the white ball, found by solving the
//          answer once (answerRest) the way the app solves a layout (EightBallJudge.solve: the standard table, the
//          entry's surface, seed 1). The physics is exact, so that is the same spot for every player.
//          Read by DailyMode, DailyViews, DailyShare and TrickSignature (sourceTrickID, so the answer's slow replay holds
//          the trick's own moments).
// SRP/DRY check: Pass - checked TrickShots.make (private; this builds the TrickShot from the bank entry through the
//          same converters, TrickSettings(_:), TrickGoal(_:) and TrickWindow(_:), and copies none of its fields) and
//          EightBallSituations (titles and lessons read, never retyped).
import BreakdownAuthored
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline

struct DailyShot: Equatable {
    /// Every daily TrickShot id starts with this.
    static let idPrefix = "daily-"

    /// DailyBank's day number (the player sees day + 1).
    let day: Int
    let entry: AuthoredDailyShot
    /// The shot as TrickShotMode plays it and TrickShotJudge judges it.
    let trick: TrickShot

    var surface: PlaySurface { PlaySurface(entry.surface) }
    var family: AuthoredFamily { entry.family }
    /// The positions the shot starts from.
    var start: [Vec2] { entry.layout }
    /// The day as the player counts it, from 1.
    var dayLabel: Int { day + 1 }

    init(day: Int, entry: AuthoredDailyShot) {
        self.day = day
        self.entry = entry
        let words = Self.words(for: entry)
        var goal = TrickGoal(entry.goal)
        goal.side = entry.strongSide
        guard let difficulty = TrickDifficulty(rawValue: entry.difficulty) else {
            preconditionFailure("daily shot \(entry.id): difficulty \(entry.difficulty) is not 1, 2 or 3")
        }
        // No cueAngles: the daily shot sets its own cue angle (DailyMode.startSettings), so the judge's angle check,
        // which falls back to a few degrees round the answer's angle, never asks for a cue the player cannot move.
        trick = TrickShot(id: Self.idPrefix + entry.id, number: day + 1, title: Self.title, hook: words.goalLine,
                          goalLine: words.goalLine, setup: .layout(entry.layout), solution: TrickSettings(entry.answer),
                          goal: goal, usesBridge: entry.usesBridge, idea: words.idea, maths: words.maths,
                          mathsSpoken: words.mathsSpoken, difficulty: difficulty, window: TrickWindow(entry.window),
                          praise: words.praise, pending: false)
    }

    /// The shot for a day number.
    init(day: Int) {
        self.init(day: day, entry: DailyBank.entry(forDay: day))
    }

    // MARK: Ids

    /// The name the card, the phone's title row and the menu share.
    static var title: String { String(localized: "Shot of the day") }

    /// True for a daily shot's TrickShot id.
    static func isDailyID(_ id: String?) -> Bool { id?.hasPrefix(idPrefix) ?? false }

    /// The trick shot a daily id was built from, for the replay's held moments (TrickSignature); any other id is
    /// returned as it is.
    static func sourceTrickID(_ id: String) -> String {
        guard isDailyID(id), let entry = AuthoredDaily.shot(id: String(id.dropFirst(idPrefix.count))),
              case .trick(let trickID) = entry.source else { return id }
        return trickID
    }

    // MARK: The mark

    /// Where the white ball should stop: the entry's written mark, or the answer's own resting place. A solve when the
    /// entry has no written mark, so DailyMode calls it once per shot and keeps the answer.
    func findMark() -> Vec2? { entry.mark ?? Self.answerRest(of: entry) }

    /// Where the answer leaves the white ball, solved as the app solves a layout on the entry's surface; nil when the
    /// answer drops it (an authoring mistake BreakProbe verify would report). Pure.
    static func answerRest(of entry: AuthoredDailyShot) -> Vec2? {
        let tl = EightBallJudge.solve(entry.layout, TrickSettings(entry.answer), on: PlaySurface(entry.surface))
        guard tl.pocketTime[0] == nil else { return nil }
        return tl.state(ball: 0, at: tl.duration).position
    }

    // MARK: Words

    private struct Words {
        let goalLine: String
        let idea: String
        let maths: String?
        let mathsSpoken: String?
        let praise: String
    }

    /// The words for an entry: the trick's own, or the escape's goal built from the call and the situation's lesson.
    private static func words(for entry: AuthoredDailyShot) -> Words {
        switch entry.source {
        case .trick(let id):
            guard let t = TrickShots.shot(id: id) else { return escapeWords(entry, lesson: nil) }
            return Words(goalLine: t.goalLine, idea: t.idea, maths: t.maths, mathsSpoken: t.mathsSpoken, praise: t.praise)
        case .escape(let situation, _):
            return escapeWords(entry, lesson: EightBallSituations.situation(id: situation)?.lesson)
        }
    }

    /// An escape's goal in one line, from its drop: "Pot the 3 in the foot-left corner pocket." or, for a bank,
    /// "Bank the 13 into the left side pocket." The pocket phrase is TableWords', already translated.
    private static func escapeWords(_ entry: AuthoredDailyShot, lesson: String?) -> Words {
        let goalLine: String
        if let drop = entry.goal.drops.first {
            let ball = drop.ball
            let pocket = drop.pocket.map { TableWords.pocketPhrase($0) } ?? String(localized: "any pocket")
            goalLine = entry.goal.bank != nil ? String(localized: "Bank the \(ball) into \(pocket).")
                                              : String(localized: "Pot the \(ball) in \(pocket).")
        } else {
            goalLine = String(localized: "Make the shot.")
        }
        return Words(goalLine: goalLine, idea: lesson ?? goalLine, maths: nil, mathsSpoken: nil,
                     praise: String(localized: "In. That is today's shot."))
    }
}
