// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 bank, stage 4 of the plan: the bank grown with "BreakProbe
//          daily" to fifteen weeks, ordered by the weekly rhythm from the first day, a Thursday; every entry writes its
//          mark and names its table (AuthoredTable); a position shot names the ball its mark leaves the cue ball on.)
// PURPOSE: The Shot of the day bank, the one copy (plans/25-Nov-2026-shot-of-the-day-plan.md, stages 1, 2 and 4):
//          one entry per daily shot, in play order. Day one plays the first entry, day two the second, and the list
//          starts again when it runs out (the app's DailyBank picks the entry from the date in Coordinated Universal
//          Time). Each entry holds a permanent id, the table and surface it is played on, where every ball starts, the
//          goal the app's TrickShotJudge checks, the mark the white ball should stop on, the authored answer, the
//          measured windows, the difficulty, the family (for the weekly rhythm), for a side-spin shot the strong-side
//          rule, and for a position shot the ball the mark leaves the cue ball lined up on.
//          Where the shots come from: stage 1 seeded the bank with what already existed and is checked, the thirteen
//          trick shots (their numbers read from AuthoredTricks, never retyped) and ten of the twelve Behind the 8-Ball
//          situations, one escape each (its table, stroke, bridge and surface read from AuthoredEscapes; left out: "No
//          Way to Make It", whose only escape is a safety, and "Massé for the Win", neither of whose escapes has a
//          measured tip-height window). An escape's goal is the called ball in the called pocket (a cushion before the
//          drop for the bank escape); its window is the narrower side of the ranges in its comment in AuthoredEscapes;
//          its difficulty from its rating (2 or less easy, 3 medium, 4 or 5 hard).
//          Stage 4 (0.7.10) added the shots written with made(...): found by "BreakProbe daily" (DailyAuthoring.swift),
//          each with its windows measured by walking out from the answer, its difficulty from its aim half-window (easy
//          0.6 degrees or more, medium 0.3 or more, hard 0.12 or more), and its mark where the answer leaves the white
//          ball. Each was looked at in the tool's picture before it went in; the ugly, trivial and near-duplicate ones
//          were thrown out. Monday's pots carry a leave: a next ball laid on the line from the mark into a pocket.
//          The order is the weekly rhythm (fits, below): day 0 is Thursday 26 November 2026, so the list runs Thursday
//          spin, Friday another table, Saturday a strange surface, Sunday a jump or massé, Monday an easy pot with
//          position, Tuesday a bank or kick, Wednesday a combination, carom or throw, and is a whole number of weeks
//          long so the rhythm holds when it wraps. No two neighbours share a family, the last and the first included.
//          The mark: every entry writes it (Stop Dead's is its finish circle's centre); "BreakProbe verify" prints how
//          far each answer's resting place is from it.
//          Read by the app (App/Daily: DailyBank, DailyShot) and by BreakProbe's content check (DailyVerify.swift),
//          which plays every entry's answer on its own table and surface before every upload and checks the rhythm.
// SRP/DRY check: Pass - data only; the trick and escape numbers are read from AuthoredTricks and AuthoredEscapes, the
//          tables' and surfaces' numbers are AuthoredTables' and TableSurfaces', the types are AuthoredTypes'. The words
//          stay in the app (DailyShot), where the string catalog collects them.
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
    // 0.7.10 bank: a shot found by "BreakProbe daily": its goal line is built from the goal itself (the balls, the
    // pockets or holes, the first and second ball, the bank, the leave), its idea from its family.
    case authored
}

/// One daily shot's numbers.
public struct AuthoredDailyShot: Sendable, Equatable {
    /// Permanent, lowercase with dashes: kept in the player's record and meant for the board. Never rename one.
    public let id: String
    public let source: AuthoredDailySource
    /// The cloth it is played on.
    public let surface: TableSurface
    // 0.7.10 bank: the table it is played on (Friday's shots are on bumper pool, five-pin or bar billiards).
    public let table: AuthoredTable
    /// Sixteen positions in table metres, index 0 the cue ball; off-table balls at NextShot.offTable.
    public let layout: [Vec2]
    public let answer: AuthoredStrike
    public let goal: AuthoredGoal
    /// Where the white ball should stop: the answer's own resting place, measured by BreakProbe (nil would make the
    /// app solve the answer for it; since 0.7.10 every entry writes it).
    public let mark: Vec2?
    public let window: AuthoredWindow
    public let usesBridge: Bool
    /// 1 easy, 2 medium, 3 hard (the app's TrickDifficulty raw values).
    public let difficulty: Int
    public let family: AuthoredFamily
    /// The strong-side rule (AuthoredTricks.strongSide, signed to the answer's side), for a side-spin shot; else nil.
    public let strongSide: Double?
    // 0.7.10 bank: for a position shot, the ball the mark leaves the cue ball lined up on (straight into a pocket);
    // the goal line names it. Nil for every other shot.
    public let leave: Int?
}

public enum AuthoredDaily {
    /// Every daily shot, in play order (day one first).
    public static let all: [AuthoredDailyShot] = [
        // Week 1, from Thursday (day 1).
        trick(AuthoredTricks.followTrain, .follow, mark: Vec2(2.2713, 0.6161)),
        made("bumper-1-165", .bank, table: .bumperPool,
             balls: [0: Vec2(0.4718, 0.6307), 9: Vec2(0.3505, 0.5285)],
             answer: AuthoredStrike(aim: -141.27, power: 1.10, tipUp: 0.0005, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(9, 6)], firstHit: 9),
             mark: Vec2(0.3147, 0.5351), window: AuthoredWindow(aim: 0.76, power: 0.45, tipUp: 0.0135, tipSide: 0.0000),
             difficulty: 1),
        made("pot-ice-31-0", .pot, surface: .ice,
             balls: [0: Vec2(1.4287, 0.3638), 6: Vec2(1.3114, 0.8313)],
             answer: AuthoredStrike(aim: 105.44, power: 1.95, tipUp: 0.0080, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(6, 5)], firstHit: 6),
             mark: Vec2(0.2616, 0.2652), window: AuthoredWindow(aim: 1.08, power: 1.40, tipUp: 0.0060, tipSide: 0.0000),
             difficulty: 1),
        trick(AuthoredTricks.jumpOver, .jump, mark: Vec2(2.3580, 1.0777)),
        trick(AuthoredTricks.stopDead, .pot, mark: Vec2(1.9767, 0.7619)),
        trick(AuthoredTricks.twoRailKick, .kick, mark: Vec2(0.0814, 0.9800)),
        trick(AuthoredTricks.comboChain, .combination, mark: Vec2(2.3958, 0.3659)),
        // Week 2, from Thursday (day 8).
        made("draw-1-0", .draw,
             balls: [0: Vec2(1.3332, 0.3639), 5: Vec2(0.4660, 0.3237), 9: Vec2(2.0833, 0.1507)],
             answer: AuthoredStrike(aim: -15.90, power: 4.60, tipUp: -0.0090, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(9, 1)], firstHit: 9),
             mark: Vec2(0.7124, 0.4948), window: AuthoredWindow(aim: 0.36, power: 3.15, tipUp: 0.0050, tipSide: 0.0000),
             difficulty: 2, leave: 5),
        made("fivepin-1-10", .carom, table: .fivePin,
             balls: [0: Vec2(0.3316, 0.2757), 1: Vec2(1.0579, 0.5853), 3: Vec2(1.5143, 1.1254)],
             answer: AuthoredStrike(aim: 23.94, power: 2.75, tipUp: 0.0085, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [], firstHit: 1, secondHit: 3),
             mark: Vec2(1.5648, 1.1921), window: AuthoredWindow(aim: 0.18, power: 1.05, tipUp: 0.0055, tipSide: 0.0000),
             difficulty: 3),
        made("bank-cork-32-11", .bank, surface: .cork,
             balls: [0: Vec2(1.8022, 1.1681), 10: Vec2(1.9234, 0.5891)],
             answer: AuthoredStrike(aim: -79.04, power: 6.40, tipUp: 0.0030, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(10, 3)], firstHit: 10, bank: 10),
             mark: Vec2(1.4824, 0.3452), window: AuthoredWindow(aim: 0.24, power: 1.60, tipUp: 0.0110, tipSide: 0.0000),
             difficulty: 3),
        made("masse-1-0", .masse,
             balls: [0: Vec2(0.5007, 0.3486), 9: Vec2(0.1142, 0.0795), 11: Vec2(0.3464, 0.2412)],
             answer: AuthoredStrike(aim: -116.44, power: 1.65, tipUp: -0.0015, tipSide: 0.0120, elevation: AuthoredLessons.sine(forAngle: 25)),
             goal: AuthoredGoal(drops: [AuthoredDrop(9, 0)], firstHit: 9),
             mark: Vec2(0.1275, 0.6397), window: AuthoredWindow(aim: 2.76, power: 0.55, tipUp: 0.0055, tipSide: 0.0015),
             difficulty: 3),
        made("pot-1-1", .pot,
             balls: [0: Vec2(2.0050, 0.5974), 5: Vec2(0.6812, 0.8392), 15: Vec2(1.4514, 1.0261)],
             answer: AuthoredStrike(aim: 143.73, power: 1.40, tipUp: 0.0020, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(15, 5)], firstHit: 15),
             mark: Vec2(0.8702, 1.0721), window: AuthoredWindow(aim: 0.82, power: 0.65, tipUp: 0.0120, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        made("bank-1-9", .bank,
             balls: [0: Vec2(1.8242, 0.7380), 5: Vec2(1.6462, 0.3018)],
             answer: AuthoredStrike(aim: -113.51, power: 3.15, tipUp: -0.0075, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(5, 5)], firstHit: 5, bank: 5),
             mark: Vec2(1.3770, 0.8659), window: AuthoredWindow(aim: 0.14, power: 0.55, tipUp: 0.0055, tipSide: 0.0000),
             difficulty: 3),
        made("carom-1-4", .carom,
             balls: [0: Vec2(1.4868, 0.6472), 5: Vec2(2.0378, 0.5798), 13: Vec2(2.1970, 0.8046)],
             answer: AuthoredStrike(aim: -3.19, power: 4.85, tipUp: -0.0050, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [], firstHit: 5, secondHit: 13),
             mark: Vec2(1.0921, 1.0126), window: AuthoredWindow(aim: 0.50, power: 1.65, tipUp: 0.0065, tipSide: 0.0000),
             difficulty: 2),
        // Week 3, from Thursday (day 15).
        trick(AuthoredTricks.squirt, .side, mark: Vec2(2.3870, 0.6823)),
        made("bar-1-16", .bank, table: .barBilliards,
             balls: [0: Vec2(0.2290, 0.4070), 3: Vec2(0.4673, 0.2602)],
             answer: AuthoredStrike(aim: -31.12, power: 1.55, tipUp: 0.0015, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(3, 10)], firstHit: 3),
             mark: Vec2(0.6810, 0.1866), window: AuthoredWindow(aim: 0.86, power: 0.35, tipUp: 0.0100, tipSide: 0.0000),
             difficulty: 1),
        made("pot-glass-31-0", .pot, surface: .glass,
             balls: [0: Vec2(0.7803, 0.9468), 3: Vec2(0.2580, 0.2683)],
             answer: AuthoredStrike(aim: -127.04, power: 4.25, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(3, 0)], firstHit: 3),
             mark: Vec2(0.9493, 0.8543), window: AuthoredWindow(aim: 0.54, power: 3.75, tipUp: 0.0040, tipSide: 0.0000),
             difficulty: 2),
        made("jump-1-0", .jump,
             balls: [0: Vec2(1.0396, 0.7245), 9: Vec2(0.3081, 0.2147), 11: Vec2(0.7504, 0.5230)],
             answer: AuthoredStrike(aim: -144.78, power: 4.70, tipUp: 0.0000, tipSide: 0.0000, elevation: AuthoredLessons.sine(forAngle: 30)),
             goal: AuthoredGoal(drops: [AuthoredDrop(9, 0)], firstHit: 9),
             mark: Vec2(0.2043, 0.4440), window: AuthoredWindow(aim: 0.26, power: 0.40, tipUp: 0.0065, tipSide: 0.0000),
             difficulty: 3),
        made("pot-1-2", .pot,
             balls: [0: Vec2(1.4162, 1.0606), 5: Vec2(1.1636, 0.9477), 13: Vec2(2.2051, 1.1940)],
             answer: AuthoredStrike(aim: 9.67, power: 4.55, tipUp: -0.0070, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(13, 3)], firstHit: 13),
             mark: Vec2(1.3963, 1.1372), window: AuthoredWindow(aim: 0.74, power: 3.40, tipUp: 0.0070, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        escape(AuthoredEscapes.frozen, "A", .kick, AuthoredWindow(aim: 0.12, power: 0.85, tipUp: 0.0065, tipSide: 0),
               mark: Vec2(2.4606, 0.0327)),
        made("combo-1-1", .combination,
             balls: [0: Vec2(1.4547, 0.4145), 5: Vec2(2.2023, 0.1487), 11: Vec2(1.9408, 0.2305)],
             answer: AuthoredStrike(aim: -21.37, power: 4.15, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(5, 1)], firstHit: 11),
             mark: Vec2(1.9818, 0.0643), window: AuthoredWindow(aim: 0.30, power: 3.10, tipUp: 0.0140, tipSide: 0.0000),
             difficulty: 3),
        // Week 4, from Thursday (day 22).
        made("follow-501-4", .follow,
             balls: [0: Vec2(1.6633, 0.1125), 5: Vec2(0.3448, 0.6067), 13: Vec2(1.4112, 0.7295)],
             answer: AuthoredStrike(aim: 113.05, power: 3.95, tipUp: 0.0070, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(13, 5)], firstHit: 13),
             mark: Vec2(0.0557, 0.6867), window: AuthoredWindow(aim: 0.52, power: 3.10, tipUp: 0.0070, tipSide: 0.0000),
             difficulty: 2, leave: 5),
        made("fivepin-1-19", .carom, table: .fivePin,
             balls: [0: Vec2(1.0981, 0.1657), 1: Vec2(1.2684, 1.0979), 3: Vec2(0.8388, 0.9519)],
             answer: AuthoredStrike(aim: 84.15, power: 5.70, tipUp: -0.0015, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [], firstHit: 1, secondHit: 3),
             mark: Vec2(0.7506, 0.9458), window: AuthoredWindow(aim: 0.32, power: 2.30, tipUp: 0.0065, tipSide: 0.0000),
             difficulty: 2),
        made("draw-carpet-33-7", .draw, surface: .carpet,
             balls: [0: Vec2(1.0003, 0.4289), 5: Vec2(0.3937, 0.4374), 9: Vec2(1.1386, 0.9688)],
             answer: AuthoredStrike(aim: 76.85, power: 4.50, tipUp: -0.0090, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(9, 5)], firstHit: 9),
             mark: Vec2(0.5944, 0.6603), window: AuthoredWindow(aim: 0.90, power: 2.70, tipUp: 0.0050, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        escape(AuthoredEscapes.fullTableSwerve, "B", .masse, AuthoredWindow(aim: 0.32, power: 0.15, tipUp: 0.0025, tipSide: 0),
               mark: Vec2(1.5288, 0.2561)),
        made("pot-1-4", .pot,
             balls: [0: Vec2(1.9788, 0.6932), 5: Vec2(1.8254, 0.7442), 11: Vec2(2.2684, 0.9936)],
             answer: AuthoredStrike(aim: 46.13, power: 4.35, tipUp: -0.0035, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(11, 3)], firstHit: 11),
             mark: Vec2(2.1032, 0.8574), window: AuthoredWindow(aim: 1.30, power: 3.50, tipUp: 0.0045, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        trick(AuthoredTricks.crossBank, .bank, mark: Vec2(0.1959, 0.1369)),
        trick(AuthoredTricks.throwIt, .throwIn, mark: Vec2(0.4735, 0.0335)),
        // Week 5, from Thursday (day 29).
        made("draw-1-3", .draw,
             balls: [0: Vec2(0.7652, 1.1864), 5: Vec2(0.1181, 0.6119), 15: Vec2(1.0403, 0.3827)],
             answer: AuthoredStrike(aim: -72.12, power: 4.25, tipUp: -0.0110, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(15, 4)], firstHit: 15),
             mark: Vec2(0.1749, 0.9064), window: AuthoredWindow(aim: 0.32, power: 1.10, tipUp: 0.0030, tipSide: 0.0000),
             difficulty: 2, leave: 5),
        made("bumper-1-186", .kick, table: .bumperPool,
             balls: [0: Vec2(0.6764, 0.0977), 9: Vec2(0.9506, 0.0877)],
             answer: AuthoredStrike(aim: -23.76, power: 1.80, tipUp: -0.0035, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(9, 7)], firstHit: 9),
             mark: Vec2(1.1076, 0.0885), window: AuthoredWindow(aim: 0.44, power: 0.45, tipUp: 0.0075, tipSide: 0.0000),
             difficulty: 2),
        made("pot-moon-31-0", .pot, surface: .moon,
             balls: [0: Vec2(1.1288, 0.6206), 10: Vec2(0.6111, 0.9714)],
             answer: AuthoredStrike(aim: 144.69, power: 3.65, tipUp: -0.0060, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(10, 2)], firstHit: 10),
             mark: Vec2(2.2005, 0.8343), window: AuthoredWindow(aim: 0.36, power: 0.95, tipUp: 0.0045, tipSide: 0.0000),
             difficulty: 2),
        made("jump-1-2", .jump,
             balls: [0: Vec2(0.8530, 0.5453), 11: Vec2(0.5788, 0.7782), 13: Vec2(0.2207, 1.0825)],
             answer: AuthoredStrike(aim: 140.02, power: 4.25, tipUp: 0.0015, tipSide: 0.0000, elevation: AuthoredLessons.sine(forAngle: 40)),
             goal: AuthoredGoal(drops: [AuthoredDrop(13, 2)], firstHit: 13),
             mark: Vec2(0.5933, 1.0409), window: AuthoredWindow(aim: 0.16, power: 0.55, tipUp: 0.0090, tipSide: 0.0000),
             difficulty: 3),
        made("pot-1-6", .pot,
             balls: [0: Vec2(0.8277, 0.6200), 5: Vec2(2.0764, 0.5358), 11: Vec2(1.1252, 0.2757)],
             answer: AuthoredStrike(aim: -47.07, power: 3.10, tipUp: -0.0030, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(11, 4)], firstHit: 11),
             mark: Vec2(1.8802, 0.7626), window: AuthoredWindow(aim: 1.08, power: 2.30, tipUp: 0.0070, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        escape(AuthoredEscapes.kickForTheGame, "A", .kick, AuthoredWindow(aim: 0.16, power: 0.30, tipUp: 0.0085, tipSide: 0),
               mark: Vec2(2.4775, 0.7031)),
        made("carom-1-7", .carom,
             balls: [0: Vec2(1.9266, 0.4960), 2: Vec2(1.4815, 0.3064), 6: Vec2(1.2997, 0.4916)],
             answer: AuthoredStrike(aim: -159.58, power: 3.80, tipUp: 0.0055, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [], firstHit: 2, secondHit: 6),
             mark: Vec2(0.6231, 0.6667), window: AuthoredWindow(aim: 0.56, power: 1.15, tipUp: 0.0085, tipSide: 0.0000),
             difficulty: 2),
        // Week 6, from Thursday (day 36).
        trick(AuthoredTricks.bridgeDraw, .draw, mark: Vec2(0.1395, 0.8423)),
        made("bar-1-1", .pot, table: .barBilliards,
             balls: [0: Vec2(0.1692, 0.3911), 1: Vec2(0.6601, 0.4819), 3: Vec2(0.7645, 0.6690)],
             answer: AuthoredStrike(aim: 27.65, power: 1.40, tipUp: 0.0025, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(3, 9)], firstHit: 3),
             mark: Vec2(0.9436, 0.6894), window: AuthoredWindow(aim: 0.44, power: 0.35, tipUp: 0.0115, tipSide: 0.0000),
             difficulty: 2),
        made("bank-ice-32-25", .bank, surface: .ice,
             balls: [0: Vec2(1.1149, 1.1132), 9: Vec2(0.6859, 0.5547)],
             answer: AuthoredStrike(aim: -129.56, power: 1.40, tipUp: 0.0105, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(9, 2)], firstHit: 9, bank: 9),
             mark: Vec2(1.4398, 0.1278), window: AuthoredWindow(aim: 0.12, power: 0.15, tipUp: 0.0035, tipSide: 0.0000),
             difficulty: 3),
        made("masse-1-2", .masse,
             balls: [0: Vec2(0.4277, 0.9066), 11: Vec2(0.2820, 1.0303), 13: Vec2(0.0877, 1.1955)],
             answer: AuthoredStrike(aim: 109.72, power: 1.65, tipUp: -0.0015, tipSide: -0.0120, elevation: AuthoredLessons.sine(forAngle: 30)),
             goal: AuthoredGoal(drops: [AuthoredDrop(13, 2)], firstHit: 13),
             mark: Vec2(0.1042, 0.7153), window: AuthoredWindow(aim: 3.04, power: 0.55, tipUp: 0.0045, tipSide: 0.0015),
             difficulty: 3),
        made("pot-1-8", .pot,
             balls: [0: Vec2(1.9163, 0.7514), 5: Vec2(0.7135, 0.2905), 10: Vec2(1.5447, 0.3784)],
             answer: AuthoredStrike(aim: -136.14, power: 2.50, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(10, 4)], firstHit: 10),
             mark: Vec2(0.9913, 0.4036), window: AuthoredWindow(aim: 0.64, power: 1.65, tipUp: 0.0140, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        made("bank-1-40", .bank,
             balls: [0: Vec2(0.3325, 0.4234), 13: Vec2(0.2579, 0.9128)],
             answer: AuthoredStrike(aim: 98.55, power: 4.95, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(13, 0)], firstHit: 13, bank: 13),
             mark: Vec2(0.2838, 0.9826), window: AuthoredWindow(aim: 0.32, power: 3.00, tipUp: 0.0140, tipSide: 0.0000),
             difficulty: 2),
        made("combo-1-5", .combination,
             balls: [0: Vec2(1.7468, 0.6665), 11: Vec2(2.3631, 1.1277), 14: Vec2(2.0235, 0.9033)],
             answer: AuthoredStrike(aim: 42.27, power: 4.10, tipUp: 0.0050, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(11, 3)], firstHit: 14),
             mark: Vec2(2.2061, 0.7248), window: AuthoredWindow(aim: 0.52, power: 3.25, tipUp: 0.0090, tipSide: 0.0000),
             difficulty: 2),
        // Week 7, from Thursday (day 43).
        made("follow-501-15", .follow,
             balls: [0: Vec2(0.8038, 0.3746), 5: Vec2(1.7931, 0.7186), 14: Vec2(1.0374, 0.7883)],
             answer: AuthoredStrike(aim: 59.98, power: 3.90, tipUp: 0.0070, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(14, 5)], firstHit: 14),
             mark: Vec2(2.0716, 0.8302), window: AuthoredWindow(aim: 0.52, power: 3.10, tipUp: 0.0070, tipSide: 0.0000),
             difficulty: 2, leave: 5),
        made("bumper-1-6", .bank, table: .bumperPool,
             balls: [0: Vec2(0.3255, 0.2958), 1: Vec2(0.8604, 0.4661), 9: Vec2(0.3911, 0.4710)],
             answer: AuthoredStrike(aim: 79.71, power: 1.95, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(9, 7)], firstHit: 9),
             mark: Vec2(0.0964, 0.4478), window: AuthoredWindow(aim: 0.48, power: 0.15, tipUp: 0.0055, tipSide: 0.0000),
             difficulty: 2),
        made("pot-rubber-31-9", .pot, surface: .rubber,
             balls: [0: Vec2(1.2734, 0.8405), 7: Vec2(1.7708, 0.8699)],
             answer: AuthoredStrike(aim: 0.20, power: 4.20, tipUp: 0.0060, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(7, 3)], firstHit: 7),
             mark: Vec2(1.6023, 0.3046), window: AuthoredWindow(aim: 0.44, power: 2.90, tipUp: 0.0080, tipSide: 0.0000),
             difficulty: 2),
        escape(AuthoredEscapes.tucked, "B", .jump, AuthoredWindow(aim: 0.26, power: 1.00, tipUp: 0.0055, tipSide: 0),
               mark: Vec2(2.0405, 1.1041)),
        made("pot-1-11", .pot,
             balls: [0: Vec2(1.7061, 0.6358), 5: Vec2(0.9668, 0.8156), 15: Vec2(1.4431, 0.3025)],
             answer: AuthoredStrike(aim: -129.84, power: 3.45, tipUp: -0.0060, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(15, 4)], firstHit: 15),
             mark: Vec2(1.1962, 1.0090), window: AuthoredWindow(aim: 1.10, power: 2.50, tipUp: 0.0080, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        escape(AuthoredEscapes.jumpDiamond, "A", .kick, AuthoredWindow(aim: 0.38, power: 0.30, tipUp: 0.0010, tipSide: 0),
               mark: Vec2(1.1232, 0.0772)),
        trick(AuthoredTricks.calledBreak, .combination, mark: Vec2(0.8050, 0.6676)),
        // Week 8, from Thursday (day 50).
        made("draw-1-4", .draw,
             balls: [0: Vec2(1.9776, 0.6943), 5: Vec2(1.7207, 0.6321), 11: Vec2(2.2684, 0.9936)],
             answer: AuthoredStrike(aim: 45.87, power: 3.05, tipUp: -0.0070, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(11, 3)], firstHit: 11),
             mark: Vec2(2.0023, 0.7355), window: AuthoredWindow(aim: 1.30, power: 1.75, tipUp: 0.0070, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        made("fivepin-1-36", .carom, table: .fivePin,
             balls: [0: Vec2(0.3224, 0.9898), 1: Vec2(1.2464, 0.9056), 3: Vec2(1.4365, 0.2950)],
             answer: AuthoredStrike(aim: -2.92, power: 3.45, tipUp: 0.0100, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [], firstHit: 1, secondHit: 3),
             mark: Vec2(1.3417, 0.3516), window: AuthoredWindow(aim: 0.16, power: 0.25, tipUp: 0.0040, tipSide: 0.0000),
             difficulty: 3),
        made("draw-cork-33-9", .draw, surface: .cork,
             balls: [0: Vec2(1.9717, 0.6689), 5: Vec2(2.2850, 0.2682), 6: Vec2(1.6153, 0.3562)],
             answer: AuthoredStrike(aim: -52.74, power: 4.55, tipUp: -0.0090, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(5, 1)], firstHit: 5),
             mark: Vec2(1.9083, 0.4208), window: AuthoredWindow(aim: 1.06, power: 2.80, tipUp: 0.0050, tipSide: 0.0000),
             difficulty: 1, leave: 6),
        made("masse-1-9", .masse,
             balls: [0: Vec2(2.1110, 0.9219), 1: Vec2(2.4620, 1.2067), 13: Vec2(2.2507, 1.0352)],
             answer: AuthoredStrike(aim: 63.84, power: 1.45, tipUp: -0.0035, tipSide: 0.0120, elevation: AuthoredLessons.sine(forAngle: 20)),
             goal: AuthoredGoal(drops: [AuthoredDrop(1, 3)], firstHit: 1),
             mark: Vec2(2.4285, 0.8044), window: AuthoredWindow(aim: 2.08, power: 0.45, tipUp: 0.0040, tipSide: 0.0015),
             difficulty: 3),
        made("pot-1-12", .pot,
             balls: [0: Vec2(0.8546, 0.5625), 5: Vec2(0.0910, 0.7209), 6: Vec2(0.2688, 0.2181)],
             answer: AuthoredStrike(aim: -150.33, power: 3.85, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(6, 0)], firstHit: 6),
             mark: Vec2(0.1400, 0.4249), window: AuthoredWindow(aim: 0.78, power: 3.05, tipUp: 0.0140, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        made("bank-1-53", .bank,
             balls: [0: Vec2(1.5638, 1.0879), 7: Vec2(1.3097, 0.6418)],
             answer: AuthoredStrike(aim: -118.67, power: 5.85, tipUp: -0.0010, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(7, 2)], firstHit: 7, bank: 7),
             mark: Vec2(2.1177, 0.0531), window: AuthoredWindow(aim: 0.16, power: 2.15, tipUp: 0.0075, tipSide: 0.0000),
             difficulty: 3),
        made("carom-1-12", .carom,
             balls: [0: Vec2(0.5383, 0.4201), 5: Vec2(1.2924, 0.3996), 9: Vec2(1.0922, 0.2482)],
             answer: AuthoredStrike(aim: -13.20, power: 2.95, tipUp: 0.0055, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [], firstHit: 9, secondHit: 5),
             mark: Vec2(2.2840, 0.7604), window: AuthoredWindow(aim: 0.34, power: 0.50, tipUp: 0.0085, tipSide: 0.0000),
             difficulty: 2),
        // Week 9, from Thursday (day 57).
        trick(AuthoredTricks.sideOffRail, .side, mark: Vec2(2.4282, 0.7679)),
        made("bar-1-6", .bank, table: .barBilliards,
             balls: [0: Vec2(0.1729, 0.3104), 3: Vec2(0.5814, 0.6037)],
             answer: AuthoredStrike(aim: 35.86, power: 1.50, tipUp: 0.0040, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(3, 14)], firstHit: 3),
             mark: Vec2(0.8363, 0.7682), window: AuthoredWindow(aim: 0.50, power: 0.30, tipUp: 0.0075, tipSide: 0.0000),
             difficulty: 2),
        made("pot-sand-31-7", .pot, surface: .sand,
             balls: [0: Vec2(1.6885, 1.0170), 14: Vec2(1.3495, 0.5560)],
             answer: AuthoredStrike(aim: -129.37, power: 5.35, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(14, 4)], firstHit: 14),
             mark: Vec2(0.1615, 0.5411), window: AuthoredWindow(aim: 0.44, power: 2.65, tipUp: 0.0140, tipSide: 0.0000),
             difficulty: 2),
        made("jump-1-3", .jump,
             balls: [0: Vec2(1.8176, 0.5238), 7: Vec2(2.0804, 0.7952), 15: Vec2(2.2938, 1.0157)],
             answer: AuthoredStrike(aim: 45.49, power: 4.10, tipUp: 0.0015, tipSide: 0.0000, elevation: AuthoredLessons.sine(forAngle: 40)),
             goal: AuthoredGoal(drops: [AuthoredDrop(15, 3)], firstHit: 15),
             mark: Vec2(2.2626, 1.1938), window: AuthoredWindow(aim: 0.26, power: 0.30, tipUp: 0.0075, tipSide: 0.0000),
             difficulty: 3),
        made("pot-1-13", .pot,
             balls: [0: Vec2(1.7787, 0.7965), 3: Vec2(1.4239, 0.2577), 5: Vec2(0.9461, 0.1483)],
             answer: AuthoredStrike(aim: -123.61, power: 4.30, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(3, 4)], firstHit: 3),
             mark: Vec2(1.2425, 0.1948), window: AuthoredWindow(aim: 0.84, power: 3.55, tipUp: 0.0140, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        escape(AuthoredEscapes.pointBlank, "A", .kick, AuthoredWindow(aim: 0.28, power: 1.15, tipUp: 0.0005, tipSide: 0),
               mark: Vec2(1.8003, 0.4002)),
        made("combo-1-7", .combination,
             balls: [0: Vec2(0.8676, 0.4443), 3: Vec2(0.5159, 0.3253), 14: Vec2(0.2996, 0.2306)],
             answer: AuthoredStrike(aim: -161.47, power: 4.50, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(14, 0)], firstHit: 3),
             mark: Vec2(0.4770, 0.3433), window: AuthoredWindow(aim: 0.46, power: 3.50, tipUp: 0.0140, tipSide: 0.0000),
             difficulty: 2),
        // Week 10, from Thursday (day 64).
        made("draw-1-6", .draw,
             balls: [0: Vec2(0.8599, 0.6467), 5: Vec2(0.8221, 0.9985), 11: Vec2(1.1252, 0.2757)],
             answer: AuthoredStrike(aim: -53.65, power: 4.15, tipUp: -0.0070, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(11, 4)], firstHit: 11),
             mark: Vec2(1.0127, 1.2301), window: AuthoredWindow(aim: 0.34, power: 3.15, tipUp: 0.0070, tipSide: 0.0000),
             difficulty: 2, leave: 5),
        made("bar-1-5", .pot, table: .barBilliards,
             balls: [0: Vec2(0.3212, 0.5959), 3: Vec2(0.7638, 0.4996)],
             answer: AuthoredStrike(aim: -11.61, power: 1.15, tipUp: 0.0035, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(3, 7)], firstHit: 3),
             mark: Vec2(0.9949, 0.5211), window: AuthoredWindow(aim: 0.44, power: 0.45, tipUp: 0.0105, tipSide: 0.0000),
             difficulty: 2),
        made("bank-sand-32-0", .bank, surface: .sand,
             balls: [0: Vec2(2.1082, 1.0477), 15: Vec2(2.1003, 0.4673)],
             answer: AuthoredStrike(aim: -92.61, power: 5.60, tipUp: 0.0005, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(15, 3)], firstHit: 15, bank: 15),
             mark: Vec2(1.4308, 0.0445), window: AuthoredWindow(aim: 0.16, power: 0.60, tipUp: 0.0075, tipSide: 0.0000),
             difficulty: 3),
        trick(AuthoredTricks.masse, .masse, mark: Vec2(2.2756, 0.5247)),
        made("pot-1-18", .pot,
             balls: [0: Vec2(0.7791, 0.7340), 5: Vec2(1.0619, 0.3662), 7: Vec2(1.1169, 1.0581)],
             answer: AuthoredStrike(aim: 42.27, power: 3.25, tipUp: -0.0055, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(7, 5)], firstHit: 7),
             mark: Vec2(1.3455, 0.4640), window: AuthoredWindow(aim: 1.18, power: 2.40, tipUp: 0.0085, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        escape(AuthoredEscapes.kickBankCrossSide, "B", .bank, AuthoredWindow(aim: 0.12, power: 0.45, tipUp: 0.0045, tipSide: 0),
               mark: Vec2(2.1218, 0.6094)),
        trick(AuthoredTricks.drawMasseCarom, .carom, mark: Vec2(0.9533, 0.1948)),
        // Week 11, from Thursday (day 71).
        made("follow-501-30", .follow,
             balls: [0: Vec2(2.0797, 1.1690), 5: Vec2(0.4648, 0.1973), 10: Vec2(1.5504, 0.5133)],
             answer: AuthoredStrike(aim: -129.75, power: 3.15, tipUp: 0.0090, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(10, 4)], firstHit: 10),
             mark: Vec2(0.1661, 0.2257), window: AuthoredWindow(aim: 0.32, power: 2.10, tipUp: 0.0050, tipSide: 0.0000),
             difficulty: 2, leave: 5),
        made("bumper-1-205", .kick, table: .bumperPool,
             balls: [0: Vec2(0.8121, 0.2855), 9: Vec2(0.2781, 0.1672), 10: Vec2(0.2299, 0.5379)],
             answer: AuthoredStrike(aim: -142.05, power: 2.50, tipUp: -0.0020, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(9, 6)], firstHit: 9),
             mark: Vec2(0.2326, 0.2746), window: AuthoredWindow(aim: 0.14, power: 0.25, tipUp: 0.0025, tipSide: 0.0000),
             difficulty: 3),
        made("pot-glass-31-14", .pot, surface: .glass,
             balls: [0: Vec2(0.5894, 0.9987), 15: Vec2(0.2983, 0.3020)],
             answer: AuthoredStrike(aim: -110.71, power: 2.00, tipUp: -0.0075, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(15, 0)], firstHit: 15),
             mark: Vec2(1.5082, 0.5377), window: AuthoredWindow(aim: 0.44, power: 1.40, tipUp: 0.0065, tipSide: 0.0000),
             difficulty: 2),
        made("jump-1-6", .jump,
             balls: [0: Vec2(1.2071, 0.3836), 12: Vec2(0.3531, 0.1122), 14: Vec2(0.8878, 0.2821)],
             answer: AuthoredStrike(aim: -161.92, power: 4.00, tipUp: 0.0015, tipSide: 0.0000, elevation: AuthoredLessons.sine(forAngle: 40)),
             goal: AuthoredGoal(drops: [AuthoredDrop(12, 0)], firstHit: 12),
             mark: Vec2(0.2496, 0.2429), window: AuthoredWindow(aim: 0.26, power: 0.40, tipUp: 0.0075, tipSide: 0.0000),
             difficulty: 3),
        made("pot-1-21", .pot,
             balls: [0: Vec2(0.8725, 0.7583), 4: Vec2(0.2289, 1.1035), 5: Vec2(0.1080, 0.5741)],
             answer: AuthoredStrike(aim: 152.50, power: 4.10, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(4, 2)], firstHit: 4),
             mark: Vec2(0.1635, 0.8689), window: AuthoredWindow(aim: 0.74, power: 3.30, tipUp: 0.0140, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        escape(AuthoredEscapes.bendAround, "C", .kick, AuthoredWindow(aim: 0.14, power: 0.15, tipUp: 0.0025, tipSide: 0),
               mark: Vec2(2.3396, 0.1484)),
        made("combo-1-8", .combination,
             balls: [0: Vec2(1.8917, 0.0738), 1: Vec2(1.4906, 0.6340), 13: Vec2(1.3563, 1.0328)],
             answer: AuthoredStrike(aim: 127.43, power: 1.50, tipUp: 0.0040, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(13, 5)], firstHit: 1),
             mark: Vec2(0.6461, 0.9426), window: AuthoredWindow(aim: 0.22, power: 0.40, tipUp: 0.0100, tipSide: 0.0000),
             difficulty: 3),
        // Week 12, from Thursday (day 78).
        made("draw-1-7", .draw,
             balls: [0: Vec2(1.7630, 0.4737), 5: Vec2(0.3305, 0.5488), 13: Vec2(2.1710, 0.9722)],
             answer: AuthoredStrike(aim: 52.06, power: 4.00, tipUp: -0.0110, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(13, 3)], firstHit: 13),
             mark: Vec2(0.4852, 0.8058), window: AuthoredWindow(aim: 0.46, power: 2.40, tipUp: 0.0030, tipSide: 0.0000),
             difficulty: 2, leave: 5),
        made("fivepin-1-11", .carom, table: .fivePin,
             balls: [0: Vec2(0.3550, 0.8790), 1: Vec2(0.9412, 0.8486), 3: Vec2(0.5537, 1.2543)],
             answer: AuthoredStrike(aim: -1.55, power: 4.50, tipUp: -0.0080, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [], firstHit: 1, secondHit: 3),
             mark: Vec2(0.5793, 1.2609), window: AuthoredWindow(aim: 0.14, power: 1.00, tipUp: 0.0010, tipSide: 0.0000),
             difficulty: 3),
        made("draw-ice-33-5", .draw, surface: .ice,
             balls: [0: Vec2(1.1431, 0.2089), 5: Vec2(1.6100, 0.1189), 9: Vec2(1.2413, 0.7571)],
             answer: AuthoredStrike(aim: 78.78, power: 1.70, tipUp: -0.0070, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(9, 5)], firstHit: 9),
             mark: Vec2(1.9092, 0.1410), window: AuthoredWindow(aim: 0.66, power: 1.15, tipUp: 0.0070, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        made("masse-1-20", .masse,
             balls: [0: Vec2(2.1708, 0.3650), 4: Vec2(2.4601, 0.0790), 13: Vec2(2.2912, 0.2460)],
             answer: AuthoredStrike(aim: -73.91, power: 1.60, tipUp: -0.0020, tipSide: -0.0120, elevation: AuthoredLessons.sine(forAngle: 25)),
             goal: AuthoredGoal(drops: [AuthoredDrop(4, 1)], firstHit: 4),
             mark: Vec2(2.4367, 0.5543), window: AuthoredWindow(aim: 2.18, power: 0.45, tipUp: 0.0045, tipSide: 0.0015),
             difficulty: 3),
        made("pot-1-23", .pot,
             balls: [0: Vec2(0.9870, 0.3822), 1: Vec2(0.5453, 0.2370), 5: Vec2(0.2678, 0.6326)],
             answer: AuthoredStrike(aim: -162.32, power: 4.00, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(1, 0)], firstHit: 1),
             mark: Vec2(0.3841, 0.3561), window: AuthoredWindow(aim: 0.66, power: 3.10, tipUp: 0.0140, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        made("bank-1-80", .bank,
             balls: [0: Vec2(0.9257, 1.1910), 2: Vec2(0.6912, 0.7332)],
             answer: AuthoredStrike(aim: -118.40, power: 5.65, tipUp: -0.0090, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(2, 2)], firstHit: 2, bank: 2),
             mark: Vec2(0.3084, 0.5450), window: AuthoredWindow(aim: 0.20, power: 2.35, tipUp: 0.0050, tipSide: 0.0000),
             difficulty: 3),
        made("carom-1-15", .carom,
             balls: [0: Vec2(1.5872, 0.8573), 10: Vec2(1.5827, 0.4532), 13: Vec2(1.8183, 0.3648)],
             answer: AuthoredStrike(aim: -86.67, power: 4.25, tipUp: 0.0050, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [], firstHit: 10, secondHit: 13),
             mark: Vec2(2.1805, 0.1249), window: AuthoredWindow(aim: 2.24, power: 1.65, tipUp: 0.0090, tipSide: 0.0000),
             difficulty: 1),
        // Week 13, from Thursday (day 85).
        made("draw-1-10", .draw,
             balls: [0: Vec2(1.9610, 0.9020), 5: Vec2(2.3007, 0.7591), 11: Vec2(1.5856, 0.4036)],
             answer: AuthoredStrike(aim: -126.82, power: 3.80, tipUp: -0.0090, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(11, 4)], firstHit: 11),
             mark: Vec2(2.2106, 1.0452), window: AuthoredWindow(aim: 0.44, power: 2.40, tipUp: 0.0050, tipSide: 0.0000),
             difficulty: 2, leave: 5),
        made("bumper-1-117", .bank, table: .bumperPool,
             balls: [0: Vec2(0.6396, 0.1475), 9: Vec2(0.4183, 0.1518)],
             answer: AuthoredStrike(aim: 190.83, power: 1.55, tipUp: 0.0055, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(9, 6)], firstHit: 9),
             mark: Vec2(0.3609, 0.3360), window: AuthoredWindow(aim: 0.16, power: 0.40, tipUp: 0.0080, tipSide: 0.0000),
             difficulty: 3),
        made("pot-rubber-31-12", .pot, surface: .rubber,
             balls: [0: Vec2(1.0557, 1.0749), 5: Vec2(1.8626, 0.9655)],
             answer: AuthoredStrike(aim: -10.08, power: 3.65, tipUp: 0.0005, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(5, 3)], firstHit: 5),
             mark: Vec2(1.7892, 0.3500), window: AuthoredWindow(aim: 0.28, power: 2.20, tipUp: 0.0135, tipSide: 0.0000),
             difficulty: 3),
        made("jump-1-10", .jump,
             balls: [0: Vec2(1.5040, 0.6227), 10: Vec2(1.6954, 0.7423), 14: Vec2(2.2988, 1.1193)],
             answer: AuthoredStrike(aim: 32.49, power: 3.80, tipUp: 0.0000, tipSide: 0.0000, elevation: AuthoredLessons.sine(forAngle: 40)),
             goal: AuthoredGoal(drops: [AuthoredDrop(14, 3)], firstHit: 14),
             mark: Vec2(2.4403, 0.9747), window: AuthoredWindow(aim: 0.34, power: 0.45, tipUp: 0.0075, tipSide: 0.0000),
             difficulty: 2),
        made("pot-1-25", .pot,
             balls: [0: Vec2(1.0575, 0.9149), 5: Vec2(1.8639, 0.1811), 6: Vec2(1.2727, 0.3289)],
             answer: AuthoredStrike(aim: -67.61, power: 1.85, tipUp: 0.0005, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(6, 4)], firstHit: 6),
             mark: Vec2(2.1625, 0.2101), window: AuthoredWindow(aim: 0.90, power: 1.05, tipUp: 0.0135, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        escape(AuthoredEscapes.zShot, "A", .kick, AuthoredWindow(aim: 0.14, power: 0.50, tipUp: 0.0025, tipSide: 0),
               mark: Vec2(0.6479, 0.5841)),
        made("combo-1-10", .combination,
             balls: [0: Vec2(1.5253, 0.8060), 9: Vec2(2.1327, 1.0743), 11: Vec2(1.8787, 0.9427)],
             answer: AuthoredStrike(aim: 19.49, power: 4.25, tipUp: 0.0025, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(9, 3)], firstHit: 11),
             mark: Vec2(2.2779, 0.4536), window: AuthoredWindow(aim: 0.30, power: 3.20, tipUp: 0.0115, tipSide: 0.0000),
             difficulty: 3),
        // Week 14, from Thursday (day 92).
        made("follow-501-32", .follow,
             balls: [0: Vec2(0.7685, 0.8732), 5: Vec2(1.0507, 0.4533), 6: Vec2(2.1264, 0.3544)],
             answer: AuthoredStrike(aim: -55.20, power: 4.05, tipUp: 0.0070, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(5, 4)], firstHit: 5),
             mark: Vec2(2.4224, 0.4037), window: AuthoredWindow(aim: 0.42, power: 3.25, tipUp: 0.0070, tipSide: 0.0000),
             difficulty: 2, leave: 6),
        made("fivepin-1-48", .carom, table: .fivePin,
             balls: [0: Vec2(0.3974, 0.5906), 1: Vec2(0.9355, 0.8781), 3: Vec2(2.2148, 0.1739)],
             answer: AuthoredStrike(aim: 32.62, power: 2.55, tipUp: 0.0095, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [], firstHit: 1, secondHit: 3),
             mark: Vec2(2.2452, 0.0795), window: AuthoredWindow(aim: 0.20, power: 0.60, tipUp: 0.0045, tipSide: 0.0000),
             difficulty: 3),
        made("bank-carpet-32-46", .bank, surface: .carpet,
             balls: [0: Vec2(1.3881, 0.3595), 12: Vec2(1.0463, 0.7323)],
             answer: AuthoredStrike(aim: 134.76, power: 4.45, tipUp: 0.0095, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(12, 0)], firstHit: 12, bank: 12),
             mark: Vec2(0.6242, 1.1625), window: AuthoredWindow(aim: 0.12, power: 0.40, tipUp: 0.0045, tipSide: 0.0000),
             difficulty: 3),
        made("masse-1-33", .masse,
             balls: [0: Vec2(0.3364, 0.8579), 3: Vec2(0.2378, 0.9787), 14: Vec2(0.0938, 1.1551)],
             answer: AuthoredStrike(aim: 162.04, power: 1.60, tipUp: -0.0030, tipSide: 0.0120, elevation: AuthoredLessons.sine(forAngle: 20)),
             goal: AuthoredGoal(drops: [AuthoredDrop(14, 2)], firstHit: 14),
             mark: Vec2(0.5902, 1.1701), window: AuthoredWindow(aim: 1.34, power: 0.25, tipUp: 0.0035, tipSide: 0.0010),
             difficulty: 3),
        made("pot-1-31", .pot,
             balls: [0: Vec2(1.2131, 0.5914), 5: Vec2(1.7236, 1.0662), 11: Vec2(1.2537, 1.0250)],
             answer: AuthoredStrike(aim: 83.40, power: 4.30, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(11, 5)], firstHit: 11),
             mark: Vec2(1.9787, 1.2240), window: AuthoredWindow(aim: 1.04, power: 3.65, tipUp: 0.0140, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        made("bank-1-82", .bank,
             balls: [0: Vec2(0.9977, 0.7881), 1: Vec2(1.3183, 0.3858)],
             answer: AuthoredStrike(aim: -51.37, power: 5.20, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(1, 3)], firstHit: 1, bank: 1),
             mark: Vec2(1.3806, 0.3496), window: AuthoredWindow(aim: 0.18, power: 2.30, tipUp: 0.0140, tipSide: 0.0000),
             difficulty: 3),
        made("carom-1-18", .carom,
             balls: [0: Vec2(0.4243, 0.5506), 10: Vec2(1.1719, 0.6571), 15: Vec2(0.9796, 0.8389)],
             answer: AuthoredStrike(aim: 25.69, power: 5.55, tipUp: 0.0075, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [], firstHit: 15, secondHit: 10),
             mark: Vec2(2.2707, 0.5430), window: AuthoredWindow(aim: 0.56, power: 1.35, tipUp: 0.0065, tipSide: 0.0000),
             difficulty: 2),
        // Week 15, from Thursday (day 99).
        made("draw-1-12", .draw,
             balls: [0: Vec2(0.8333, 0.5973), 5: Vec2(0.3526, 0.9731), 6: Vec2(0.2688, 0.2181)],
             answer: AuthoredStrike(aim: -146.53, power: 3.95, tipUp: -0.0070, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(6, 0)], firstHit: 6),
             mark: Vec2(0.5821, 0.7798), window: AuthoredWindow(aim: 0.84, power: 2.85, tipUp: 0.0050, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        made("bar-1-12", .bank, table: .barBilliards,
             balls: [0: Vec2(0.4308, 0.1804), 3: Vec2(0.5364, 0.4317)],
             answer: AuthoredStrike(aim: 69.37, power: 2.00, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(3, 9)], firstHit: 3),
             mark: Vec2(0.3447, 0.7019), window: AuthoredWindow(aim: 0.36, power: 0.10, tipUp: 0.0040, tipSide: 0.0000),
             difficulty: 2),
        made("pot-moon-31-1", .pot, surface: .moon,
             balls: [0: Vec2(1.2820, 0.1527), 5: Vec2(1.4165, 0.6465)],
             answer: AuthoredStrike(aim: 71.22, power: 3.10, tipUp: 0.0070, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(5, 5)], firstHit: 5),
             mark: Vec2(1.3354, 0.4050), window: AuthoredWindow(aim: 0.36, power: 1.15, tipUp: 0.0070, tipSide: 0.0000),
             difficulty: 2),
        made("jump-1-11", .jump,
             balls: [0: Vec2(1.2641, 1.0022), 12: Vec2(0.9571, 1.0672), 13: Vec2(0.3201, 1.2022)],
             answer: AuthoredStrike(aim: 167.52, power: 3.90, tipUp: 0.0010, tipSide: 0.0000, elevation: AuthoredLessons.sine(forAngle: 40)),
             goal: AuthoredGoal(drops: [AuthoredDrop(13, 2)], firstHit: 13),
             mark: Vec2(0.2269, 1.0490), window: AuthoredWindow(aim: 0.28, power: 0.30, tipUp: 0.0075, tipSide: 0.0000),
             difficulty: 3),
        made("pot-1-42", .pot,
             balls: [0: Vec2(1.5121, 1.2082), 1: Vec2(2.0225, 1.1797), 5: Vec2(2.1659, 0.5920)],
             answer: AuthoredStrike(aim: -4.79, power: 2.25, tipUp: 0.0000, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(1, 3)], firstHit: 1),
             mark: Vec2(2.4552, 0.6711), window: AuthoredWindow(aim: 0.80, power: 1.35, tipUp: 0.0140, tipSide: 0.0000),
             difficulty: 1, leave: 5),
        escape(AuthoredEscapes.jumpOffTheBridge, "A", .kick, AuthoredWindow(aim: 0.24, power: 0.95, tipUp: 0.0010, tipSide: 0),
               mark: Vec2(2.1215, 0.9927)),
        made("combo-1-11", .combination,
             balls: [0: Vec2(0.9036, 0.6818), 6: Vec2(0.5877, 0.4069), 10: Vec2(0.2547, 0.2066)],
             answer: AuthoredStrike(aim: -136.87, power: 4.50, tipUp: 0.0045, tipSide: 0.0000),
             goal: AuthoredGoal(drops: [AuthoredDrop(10, 0)], firstHit: 6),
             mark: Vec2(0.5980, 0.8739), window: AuthoredWindow(aim: 0.22, power: 3.50, tipUp: 0.0095, tipSide: 0.0000),
             difficulty: 3),
    ]

    public static func shot(id: String) -> AuthoredDailyShot? { all.first { $0.id == id } }

    // MARK: The week (0.7.10 bank)

    /// The bank's first day, 26 November 2026 (the app's DailyBank.startDate), is a Thursday. Day n of the bank falls
    /// on the weekday n days later, so the bank is a whole number of weeks long and the rhythm holds when it wraps.
    public static let firstWeekday = AuthoredWeekday.thursday

    /// The weekday a place in the list is played on.
    public static func weekday(ofIndex i: Int) -> AuthoredWeekday {
        let n = AuthoredWeekday.allCases.count
        return AuthoredWeekday.allCases[(((firstWeekday.rawValue - 1 + i) % n) + n) % n]
    }

    /// True for a surface far from a real cloth (ice, glass, rubber, cork, carpet, sand, the Moon): Saturday's.
    public static func isStrange(_ s: TableSurface) -> Bool {
        ![.cloth, .tournament, .diveBar].contains(s)
    }

    /// The plan's weekly rhythm: Monday an easy pot with position, Tuesday a bank or a kick, Wednesday a combination, a
    /// carom or a throw, Thursday spin (draw, follow or side), Friday another table, Saturday a strange surface, Sunday a
    /// jump or a massé. Monday to Thursday and Sunday are on the pool table on a real cloth.
    public static func fits(_ e: AuthoredDailyShot, on day: AuthoredWeekday) -> Bool {
        let pool = e.table == .standard && !isStrange(e.surface)
        switch day {
        case .monday: return pool && e.family == .pot
        case .tuesday: return pool && [.bank, .kick].contains(e.family)
        case .wednesday: return pool && [.combination, .carom, .throwIn].contains(e.family)
        case .thursday: return pool && [.draw, .follow, .side].contains(e.family)
        case .friday: return e.table != .standard
        case .saturday: return e.table == .standard && isStrange(e.surface)
        case .sunday: return pool && [.jump, .masse].contains(e.family)
        }
    }

    // MARK: Building an entry

    /// A trick shot as a daily entry: every number is the trick's own. Trick shots were authored on the standard cloth
    /// (BreakProbe's default parameters), so that is their surface. The mark is the trick's finish circle when it has
    /// one (Stop Dead), otherwise `mark`, the answer's own resting place as "BreakProbe verify" measured it.
    private static func trick(_ t: AuthoredTrick, _ family: AuthoredFamily, mark: Vec2) -> AuthoredDailyShot {
        let side: Double? = AuthoredTricks.strongSideIDs.contains(t.id)
            ? (t.solution.tipSide < 0 ? -AuthoredTricks.strongSide : AuthoredTricks.strongSide)
            : nil
        return AuthoredDailyShot(id: t.id, source: .trick(t.id), surface: .cloth, table: t.table, layout: t.layout,
                                 answer: t.solution, goal: t.goal, mark: t.goal.cueZone?.centre ?? mark,
                                 window: t.window, usesBridge: t.usesBridge, difficulty: t.difficulty, family: family,
                                 strongSide: side, leave: nil)
    }

    /// One escape of a Behind the 8-Ball situation as a daily entry: the situation's table and cloth, the escape's
    /// stroke and bridge, the called ball in the called pocket as the goal (a cushion before the drop for a bank), and
    /// the measured window passed in (read from the escape's comment in AuthoredEscapes). An escape with no called
    /// ball, or a missing escape id, is an authoring mistake, stopped here rather than played as something else.
    private static func escape(_ s: AuthoredSituation, _ escapeID: String, _ family: AuthoredFamily,
                               _ window: AuthoredWindow, mark: Vec2) -> AuthoredDailyShot {
        guard let e = s.escape(escapeID), let ball = e.call.ball, let pocket = e.call.pocket else {
            preconditionFailure("daily bank: \(s.id) escape \(escapeID) is missing or calls no ball")
        }
        let goal = AuthoredGoal(drops: [AuthoredDrop(ball, pocket.rawValue)], bank: e.check == .bank ? ball : nil)
        let difficulty = e.rating <= 2 ? 1 : (e.rating == 3 ? 2 : 3)
        return AuthoredDailyShot(id: "\(s.id)-\(escapeID.lowercased())", source: .escape(situation: s.id, escape: e.id),
                                 surface: s.surface, table: .standard, layout: s.layout, answer: e.strike, goal: goal,
                                 mark: mark, window: window, usesBridge: e.usesBridge, difficulty: difficulty,
                                 family: family, strongSide: nil, leave: nil)
    }

    /// A shot found by "BreakProbe daily" (DailyAuthoring.swift), written as the tool prints it: the balls on the
    /// table (every other ball off it), the answer, the goal, the mark (the answer's resting place), the measured
    /// half-windows (rounded down), the difficulty from the aim window and, for a position shot, the ball the mark
    /// leaves the cue ball lined up on.
    private static func made(_ id: String, _ family: AuthoredFamily, table: AuthoredTable = .standard,
                             surface: TableSurface = .cloth, balls: [Int: Vec2], answer: AuthoredStrike,
                             goal: AuthoredGoal, mark: Vec2, window: AuthoredWindow, difficulty: Int,
                             leave: Int? = nil) -> AuthoredDailyShot {
        AuthoredDailyShot(id: id, source: .authored, surface: surface, table: table, layout: authoredLayout(balls),
                          answer: answer, goal: goal, mark: mark, window: window, usesBridge: false,
                          difficulty: difficulty, family: family, strongSide: nil, leave: leave)
    }
}

/// The days of the week, Monday first (the plan's rhythm starts there); raw values 1 to 7.
public enum AuthoredWeekday: Int, CaseIterable, Sendable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday
}
