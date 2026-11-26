// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The Shot of the day bank, the one copy (plans/25-Nov-2026-shot-of-the-day-plan.md, stage 1 items 1 and 2):
//          one entry per daily shot, in play order. Day one plays the first entry, day two the second, and the list
//          starts again when it runs out (the app's DailyBank picks the entry from the date in Coordinated Universal
//          Time). Each entry holds a permanent id, the surface it is played on, where every ball starts, the goal the
//          app's TrickShotJudge checks, the mark the white ball should stop on (nil: the answer's own resting place,
//          worked out by the app from the answer), the authored answer, the measured windows, the difficulty, the
//          family (for the weekly rhythm) and, for a side-spin shot, the strong-side rule.
//          Stage 1 seeds the bank from what already exists and is checked: the thirteen trick shots (their numbers
//          read from AuthoredTricks, never retyped) and ten of the twelve Behind the 8-Ball situations, one escape each
//          (its table, stroke, bridge and surface read from AuthoredEscapes). Left out: "No Way to Make It", whose
//          only escape is a safety (nothing drops, so there is no make to score), and "Massé for the Win", neither of
//          whose escapes has a measured tip-height window (the judge's advice divides by it). Stage 4 grows the bank
//          with "BreakProbe daily".
//          How an escape becomes a daily goal: the called ball in the called pocket (EightBallPocket's raw value is the
//          solver's pocket index), and a cushion before the drop for the bank escape. The legality of the eight-ball
//          rules (your group first, the 8 kept up) is not part of a daily goal: the day asks for the pot, and any way
//          that makes it counts. Which escape: the one whose comment in AuthoredEscapes gives a measured window for aim,
//          power and tip height; each entry's window is the narrower side of those measured ranges, half-widths in the
//          units of AuthoredWindow. A difficulty from the escape's rating: 2 or less easy, 3 medium, 4 or 5 hard.
//          The order keeps two shots of the same family apart, the last and the first included (the list wraps).
//          The weekly rhythm of the plan (Monday a pot, Sunday a jump or massé) waits for stage 4, when the bank is
//          large enough to hold it; with eight kick escapes in twenty-three shots, keeping kicks apart comes first.
//          The mark: only Stop Dead has a finish circle, and its centre is its mark. Every other entry leaves the mark
//          nil, and the app solves the answer once to find where it leaves the white ball (DailyShot.answerRest), so the
//          answer scores full precision, as the plan intends. "BreakProbe verify" prints each answer's resting place so
//          the marks can be written in here later.
//          Read by the app (App/Daily: DailyBank, DailyShot) and by BreakProbe's content check (DailyVerify.swift),
//          which plays every entry's answer on its own surface before every upload.
// SRP/DRY check: Pass - data only; the trick and escape numbers are read from AuthoredTricks and AuthoredEscapes, the
//          types are AuthoredTypes'. The words stay in the app (DailyShot), where the string catalog collects them.
import BreakdownLensModel
import BreakdownRules

/// The kind of shot a daily entry is, for the weekly rhythm and the never-twice-in-a-row rule.
public enum AuthoredFamily: String, CaseIterable, Sendable {
    case pot, bank, kick, combination, carom, throwIn = "throw", draw, follow, side, jump, masse
}

/// Where a daily entry's words come from in the app: a trick shot (its goal line, idea and praise) or a Behind the
/// 8-Ball situation's escape (its lesson).
public enum AuthoredDailySource: Sendable, Equatable {
    case trick(String)
    case escape(situation: String, escape: String)
}

/// One daily shot's numbers.
public struct AuthoredDailyShot: Sendable, Equatable {
    /// Permanent, lowercase with dashes: kept in the player's record and meant for the board. Never rename one.
    public let id: String
    public let source: AuthoredDailySource
    /// The cloth it is played on. Every stage-1 entry is on the pool table.
    public let surface: TableSurface
    /// Sixteen positions in table metres, index 0 the cue ball; off-table balls at NextShot.offTable.
    public let layout: [Vec2]
    public let answer: AuthoredStrike
    public let goal: AuthoredGoal
    /// Where the white ball should stop; nil means the answer's own resting place (worked out by the app).
    public let mark: Vec2?
    public let window: AuthoredWindow
    public let usesBridge: Bool
    /// 1 easy, 2 medium, 3 hard (the app's TrickDifficulty raw values).
    public let difficulty: Int
    public let family: AuthoredFamily
    /// The strong-side rule (AuthoredTricks.strongSide, signed to the answer's side), for a side-spin shot; else nil.
    public let strongSide: Double?
}

public enum AuthoredDaily {
    /// Every daily shot, in play order (day one first).
    public static let all: [AuthoredDailyShot] = [
        trick(AuthoredTricks.squirt, .side),
        escape(AuthoredEscapes.frozen, "A", .kick,
               AuthoredWindow(aim: 0.12, power: 0.85, tipUp: 0.0065, tipSide: 0)),
        escape(AuthoredEscapes.fullTableSwerve, "B", .masse,
               AuthoredWindow(aim: 0.32, power: 0.15, tipUp: 0.0025, tipSide: 0)),
        trick(AuthoredTricks.twoRailKick, .kick),
        trick(AuthoredTricks.stopDead, .pot),
        escape(AuthoredEscapes.kickForTheGame, "A", .kick,
               AuthoredWindow(aim: 0.16, power: 0.30, tipUp: 0.0085, tipSide: 0)),
        trick(AuthoredTricks.comboChain, .combination),
        escape(AuthoredEscapes.jumpDiamond, "A", .kick,
               AuthoredWindow(aim: 0.38, power: 0.30, tipUp: 0.0010, tipSide: 0)),
        trick(AuthoredTricks.bridgeDraw, .draw),
        escape(AuthoredEscapes.pointBlank, "A", .kick,
               AuthoredWindow(aim: 0.28, power: 1.15, tipUp: 0.0005, tipSide: 0)),
        trick(AuthoredTricks.jumpOver, .jump),
        escape(AuthoredEscapes.bendAround, "C", .kick,
               AuthoredWindow(aim: 0.14, power: 0.15, tipUp: 0.0025, tipSide: 0)),
        trick(AuthoredTricks.crossBank, .bank),
        escape(AuthoredEscapes.zShot, "A", .kick,
               AuthoredWindow(aim: 0.14, power: 0.50, tipUp: 0.0025, tipSide: 0)),
        trick(AuthoredTricks.throwIt, .throwIn),
        escape(AuthoredEscapes.jumpOffTheBridge, "A", .kick,
               AuthoredWindow(aim: 0.24, power: 0.95, tipUp: 0.0010, tipSide: 0)),
        trick(AuthoredTricks.followTrain, .follow),
        escape(AuthoredEscapes.tucked, "B", .jump,
               AuthoredWindow(aim: 0.26, power: 1.00, tipUp: 0.0055, tipSide: 0)),
        escape(AuthoredEscapes.kickBankCrossSide, "B", .bank,
               AuthoredWindow(aim: 0.12, power: 0.45, tipUp: 0.0045, tipSide: 0)),
        trick(AuthoredTricks.masse, .masse),
        trick(AuthoredTricks.calledBreak, .combination),
        trick(AuthoredTricks.sideOffRail, .side),
        trick(AuthoredTricks.drawMasseCarom, .carom),
    ]

    public static func shot(id: String) -> AuthoredDailyShot? { all.first { $0.id == id } }

    // MARK: Building an entry

    /// A trick shot as a daily entry: every number is the trick's own. Trick shots were authored on the standard cloth
    /// (BreakProbe's default parameters), so that is their surface. The mark is the trick's finish circle when it has
    /// one (Stop Dead), otherwise the answer's own resting place.
    private static func trick(_ t: AuthoredTrick, _ family: AuthoredFamily) -> AuthoredDailyShot {
        let side: Double? = AuthoredTricks.strongSideIDs.contains(t.id)
            ? (t.solution.tipSide < 0 ? -AuthoredTricks.strongSide : AuthoredTricks.strongSide)
            : nil
        return AuthoredDailyShot(id: t.id, source: .trick(t.id), surface: .cloth, layout: t.layout, answer: t.solution,
                                 goal: t.goal, mark: t.goal.cueZone?.centre, window: t.window, usesBridge: t.usesBridge,
                                 difficulty: t.difficulty, family: family, strongSide: side)
    }

    /// One escape of a Behind the 8-Ball situation as a daily entry: the situation's table and cloth, the escape's
    /// stroke and bridge, the called ball in the called pocket as the goal (a cushion before the drop for a bank), and
    /// the measured window passed in (read from the escape's comment in AuthoredEscapes). An escape with no called
    /// ball, or a missing escape id, is an authoring mistake, stopped here rather than played as something else.
    private static func escape(_ s: AuthoredSituation, _ escapeID: String, _ family: AuthoredFamily,
                               _ window: AuthoredWindow) -> AuthoredDailyShot {
        guard let e = s.escape(escapeID), let ball = e.call.ball, let pocket = e.call.pocket else {
            preconditionFailure("daily bank: \(s.id) escape \(escapeID) is missing or calls no ball")
        }
        let goal = AuthoredGoal(drops: [AuthoredDrop(ball, pocket.rawValue)], bank: e.check == .bank ? ball : nil)
        let difficulty = e.rating <= 2 ? 1 : (e.rating == 3 ? 2 : 3)
        return AuthoredDailyShot(id: "\(s.id)-\(escapeID.lowercased())", source: .escape(situation: s.id, escape: e.id),
                                 surface: s.surface, layout: s.layout, answer: e.strike, goal: goal, mark: nil,
                                 window: window, usesBridge: e.usesBridge, difficulty: difficulty, family: family,
                                 strongSide: nil)
    }
}
