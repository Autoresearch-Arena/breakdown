// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 bank: a shot starts on its own table (TrickShot.table from
//          the entry), the answer's resting place is solved on that table and surface (answerTimeline), and the shots
//          BreakProbe daily found say their goal from the goal itself, in Make it again's words, plus the carom's second
//          ball and the position the mark asks for, with one idea line per family.)
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
//          answer once (answerRest) the way the model solves a stroke (ShowpieceModel.solverCopy: the entry's table, the
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
import Foundation

struct DailyShot: Equatable {
    /// Every daily TrickShot id starts with this.
    static let idPrefix = "daily-"

    /// DailyBank's day number (the player sees day + 1).
    let day: Int
    let entry: AuthoredDailyShot
    /// The shot as TrickShotMode plays it and TrickShotJudge judges it.
    let trick: TrickShot

    var surface: PlaySurface { PlaySurface(entry.surface) }
    // 0.7.10 bank: the table the shot is played on (Friday's are on bumper pool, five-pin or bar billiards).
    var table: TableKind { TableKind(entry.table) }
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
                          praise: words.praise, pending: false,
                          // 0.7.10 bank: the entry's own table; ShowpieceModel.physicsTable solves and draws it there.
                          table: TableKind(entry.table))
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

    /// Where the answer leaves the white ball, solved as the app solves a layout on the entry's table and surface; nil
    /// when the answer drops it (an authoring mistake BreakProbe verify would report). Pure.
    static func answerRest(of entry: AuthoredDailyShot) -> Vec2? {
        let tl = answerTimeline(of: entry)
        guard tl.pocketTime[0] == nil else { return nil }
        return tl.state(ball: 0, at: tl.duration).position
    }

    /// 0.7.10 bank: the answer's recording, solved exactly as the model solves a stroke (ShowpieceModel.solverCopy: the
    /// entry's table, then its surface, the default physics generation, seed 1).
    static func answerTimeline(of entry: AuthoredDailyShot) -> Timeline {
        let s = TrickSettings(entry.answer)
        let a = s.aim * Double.pi / 180
        let input = NextShot.shot(from: entry.layout, direction: Vec2(cos(a), sin(a)), speed: s.power, tipUp: s.tipUp,
                                  tipSide: s.tipSide, seed: 1, parameters: PoolParameters(), elevation: s.elevation ?? 0)
        let solvable = ShowpieceModel.solverCopy(input, table: TableKind(entry.table), surface: PlaySurface(entry.surface),
                                                 generation: PoolParameters().modelGeneration)
        return PoolSolver.simulate(solvable)
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
        case .authored:
            return authoredWords(entry)
        }
    }

    // MARK: Words for the shots BreakProbe daily found (0.7.10 bank)

    /// An authored shot's goal from the goal itself, in the words Make it again already uses for a saved shot (each
    /// ball and pocket or hole named the way its table names them), then the carom's second ball and the position the
    /// mark asks for; its idea is its family's one line. Nothing here gives the answer away: no aim, no spin, no power.
    private static func authoredWords(_ entry: AuthoredDailyShot) -> Words {
        let table = TableKind(entry.table)
        let drops = entry.goal.drops.compactMap { d in d.pocket.map { OwnDrop(ball: d.ball, pocket: $0) } }
        var sentences = [OwnShotWords.goalLine(drops: drops, firstHit: entry.goal.firstHit, bank: entry.goal.bank,
                                               table: table)]
        if let second = entry.goal.secondHit {
            sentences.append(String(localized: "Then the cue ball must touch \(OwnShotWords.ball(second, table: table)).",
                                    comment: "Shot of the day goal, a carom: %@ is a ball, e.g. \"the 5\" or \"the red\"."))
        }
        if let leave = entry.leave {
            sentences.append(String(localized: "Then stop the cue ball on the mark, lined up on \(OwnShotWords.ball(leave, table: table)).",
                                    comment: "Shot of the day goal, a position shot: %@ is the next ball, e.g. \"the 5\"."))
        }
        let goalLine = sentences.filter { !$0.isEmpty }.joined(separator: " ")
        return Words(goalLine: goalLine.isEmpty ? String(localized: "Make the shot.") : goalLine,
                     idea: familyIdea(entry.family), maths: nil, mathsSpoken: nil,
                     praise: String(localized: "In. That is today's shot."))
    }

    /// The one physics idea of a family, shown once the day is finished.
    static func familyIdea(_ family: AuthoredFamily) -> String {
        switch family {
        case .pot:
            return String(localized: "The object ball leaves along the line through both centres at contact. Aim so that line runs into the pocket.",
                          comment: "Shot of the day idea, a plain pot.")
        case .bank:
            return String(localized: "A ball leaves a cushion at about the angle it came in, so aim at the pocket's mirror image in that cushion.",
                          comment: "Shot of the day idea, a bank.")
        case .kick:
            return String(localized: "The cue ball comes off the cushion at about its mirror angle, so it can reach a ball it cannot see straight.",
                          comment: "Shot of the day idea, a kick.")
        case .combination:
            return String(localized: "Each ball sends the next along the line through their centres, so line up the last contact first.",
                          comment: "Shot of the day idea, a combination.")
        case .carom:
            return String(localized: "After a cut, a stunned cue ball leaves at right angles to the object ball's path. That sends it on to the second ball.",
                          comment: "Shot of the day idea, a carom.")
        case .throwIn:
            return String(localized: "Balls that grip as they touch drag each other sideways, so a ball can be thrown off its straight line.",
                          comment: "Shot of the day idea, a throw.")
        case .draw:
            return String(localized: "Backspin keeps working after the hit: it grips the cloth and pulls the cue ball back.",
                          comment: "Shot of the day idea, a draw.")
        case .follow:
            return String(localized: "Topspin keeps working after the hit: it grips the cloth and drives the cue ball on.",
                          comment: "Shot of the day idea, a follow.")
        case .side:
            return String(localized: "Side spin changes the angle the cue ball takes off a cushion.",
                          comment: "Shot of the day idea, side spin.")
        case .jump:
            return String(localized: "A raised cue drives the cue ball down into the bed, and it bounces up over the ball in the way.",
                          comment: "Shot of the day idea, a jump.")
        case .masse:
            return String(localized: "A steep cue with side spin makes the cue ball curve as the spin grips the cloth.",
                          comment: "Shot of the day idea, a massé.")
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
