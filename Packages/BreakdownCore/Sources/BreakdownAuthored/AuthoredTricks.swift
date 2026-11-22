// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The trick shots' numbers, the one copy (bug plan after 0.6.6, item 38): where the balls start, the authored
//          answer, the goal the judges check, the measured skill windows, the bridge and the difficulty. The app's
//          TrickShots adds the titles and words and reads these; BreakProbe's "verify" plays them and "tricks near"
//          re-authors them. Every number was printed by the dev tool (Packages/BreakdownCore/Sources/BreakProbe:
//          TrickAuthoring for the first authoring, Reauthor for each re-authoring); each shot's comment records the runs
//          and the windows, walked outward from the answer one small step at a time, so a window is an unbroken band.
// SRP/DRY check: Pass - data only; the types are AuthoredTypes'. The words stay in the app, where the string catalog
//          collects them.
import BreakdownLensModel

public enum AuthoredTricks {
    /// Every shot in the order it was authored (the app sorts it easiest first).
    public static let all: [AuthoredTrick] = [
        calledBreak, stopDead, bridgeDraw, followTrain, twoRailKick, crossBank, comboChain, throwIt, masse, jumpOver,
        drawMasseCarom,
    ]

    public static func trick(id: String) -> AuthoredTrick? { all.first { $0.id == id } }

    // MARK: 1. The Called Break
    // First authored on the front three rows of a rack, half a millimetre apart (BreakProbe tricks called-break-short,
    // 20-Nov-2026: a full rack is chaotic at the scale a player can aim), re-authored near its old answer on the tuned
    // generation two. On the 0.7.0 physics (the coupled rail and the push rule) nothing near the old answer made it in a
    // band a player can repeat (tricks near: 26,355 strokes, 309 made it, none survived the sturdiness screen), and from 28
    // cue spots on the same rack the widest run was 0.08 degrees. So the three rows' balls now sit 5 mm apart (the break
    // is a chain of separate contacts, less sensitive to the aim) and the cue ball starts at (0.75, 0.30): "BreakProbe
    // tricks break", 432 rack gaps, spots, powers and tips, 151 aims each (21-Nov-2026). Windows: aim 14.84 to 15.04
    // degrees (half-width 0.10, the same as before the tuning: the hardest shot in the list), power 6.80 to 7.30 m/s, tip
    // height -6.0 to -3.0 mm; side is not judged.
    public static let calledBreak = AuthoredTrick(
        id: "called-break", number: 1,
        layout: authoredLayout([0: Vec2(0.7500, 0.3000), 1: Vec2(1.9050, 0.6350), 2: Vec2(1.9588, 0.6661),
                                3: Vec2(2.0126, 0.6972), 8: Vec2(2.0126, 0.6350), 9: Vec2(1.9588, 0.6039),
                                10: Vec2(2.0126, 0.5728)]),
        solution: AuthoredStrike(aim: 14.94, power: 7.05, tipUp: -0.0045, tipSide: 0),
        goal: AuthoredGoal(drops: [AuthoredDrop(3, 3)], firstHit: 1),
        window: AuthoredWindow(aim: 0.10, power: 0.25, tipUp: 0.0015, tipSide: 0),
        usesBridge: false, difficulty: 3)

    // MARK: 2. Stop Dead
    // BreakProbe tricks stop-dead (20-Nov-2026): the 0.40 m stun. Unchanged on the 0.7.0 physics (tricks near,
    // 21-Nov-2026); windows walked again from it: aim 41.45 to 42.89 degrees, power 1.50 to 2.05 m/s, tip height -14.0 to
    // -3.5 mm (the low edge is the miscue limit), side -5.0 to +5.0 mm.
    public static let stopDead = AuthoredTrick(
        id: "stop-dead", number: 2,
        layout: authoredLayout([0: Vec2(1.7233, 0.5318), 3: Vec2(2.0200, 0.8000)]),
        solution: AuthoredStrike(aim: 42.17, power: 1.75, tipUp: -0.008, tipSide: 0),
        goal: AuthoredGoal(drops: [AuthoredDrop(3, 3)], cueZone: AuthoredZone(Vec2(1.9776, 0.7617), 0.05), firstHit: 3),
        window: AuthoredWindow(aim: 0.72, power: 0.25, tipUp: 0.0045, tipSide: 0.0050),
        usesBridge: false, difficulty: 1)

    // MARK: 3. The Long Bridge Draw
    // BreakProbe tricks bridge-draw (20-Nov-2026), re-authored near its old answer on the tuned generation two.
    // Unchanged on the 0.7.0 physics (tricks near, 21-Nov-2026); windows: aim -26.36 to -25.86 degrees, power 3.75 to
    // 8.00 m/s, tip height -14.0 to -7.0 mm, side -1.0 to +2.0 mm.
    public static let bridgeDraw = AuthoredTrick(
        id: "bridge-draw", number: 3,
        layout: authoredLayout([0: Vec2(1.5000, 0.5200), 2: Vec2(0.0901, 1.2184), 6: Vec2(1.6073, 0.4663)]),
        solution: AuthoredStrike(aim: -26.08, power: 5.80, tipUp: -0.0105, tipSide: 0),
        goal: AuthoredGoal(drops: [AuthoredDrop(6, 1), AuthoredDrop(2, 2)], firstHit: 6),
        window: AuthoredWindow(aim: 0.22, power: 2.05, tipUp: 0.0035, tipSide: 0.0010),
        usesBridge: true, difficulty: 3)

    // MARK: 4. Follow-Through Train
    // BreakProbe tricks follow-train (20-Nov-2026), re-authored near its old answer on the tuned generation two.
    // Unchanged on the 0.7.0 physics (tricks near, 21-Nov-2026); windows: aim 49.88 to 50.64 degrees, power 3.95 to
    // 5.15 m/s, tip height +5.5 to +14.0 mm (some follow is needed), side -1.0 to +1.5 mm.
    public static let followTrain = AuthoredTrick(
        id: "follow-train", number: 4,
        layout: authoredLayout([0: Vec2(1.6830, 0.5403), 1: Vec2(2.0500, 0.9500), 2: Vec2(1.9171, 1.0103)]),
        solution: AuthoredStrike(aim: 50.26, power: 4.65, tipUp: 0.009, tipSide: 0),
        goal: AuthoredGoal(drops: [AuthoredDrop(1, 3), AuthoredDrop(2, 5)], firstHit: 1),
        window: AuthoredWindow(aim: 0.38, power: 0.50, tipUp: 0.0035, tipSide: 0.0010),
        usesBridge: false, difficulty: 2)

    // MARK: 5. Two-Rail Kick
    // BreakProbe tricks two-rail-kick (20-Nov-2026), re-authored near its old answer on the tuned generation two. On the
    // 0.7.0 physics the old stroke left the 5 up (the coupled rail sends a kick off at a new angle); re-authored near it
    // (tricks near, 21-Nov-2026). Windows: aim 9.10 to 9.82 degrees, power 2.60 to 5.40 m/s, tip height +2.5 to +14.0 mm,
    // side -0.5 to +0.5 mm.
    public static let twoRailKick = AuthoredTrick(
        id: "two-rail-kick", number: 5,
        layout: authoredLayout([0: Vec2(0.7000, 0.4500), 5: Vec2(0.2015, 1.2182), 9: Vec2(0.4661, 0.7895),
                                10: Vec2(0.4053, 0.9356)]),
        solution: AuthoredStrike(aim: 9.46, power: 3.80, tipUp: 0.0085, tipSide: 0),
        goal: AuthoredGoal(drops: [AuthoredDrop(5, 2)], firstHit: 5),
        window: AuthoredWindow(aim: 0.36, power: 1.20, tipUp: 0.0055, tipSide: 0.0005),
        usesBridge: false, difficulty: 3)

    // MARK: 6. Cross-Side Bank
    // BreakProbe tricks cross-bank (20-Nov-2026), re-authored near its old answer on the tuned generation two.
    // Unchanged on the 0.7.0 physics (tricks near, 21-Nov-2026); windows: aim -95.40 to -94.52 degrees, power 2.15 to
    // 5.20 m/s, tip height -10.0 to +14.0 mm, side -0.5 to +1.5 mm.
    public static let crossBank = AuthoredTrick(
        id: "cross-bank", number: 6,
        layout: authoredLayout([0: Vec2(1.0663, 0.8296), 5: Vec2(1.0500, 0.4500)]),
        solution: AuthoredStrike(aim: -95.10, power: 2.65, tipUp: 0.0015, tipSide: 0),
        goal: AuthoredGoal(drops: [AuthoredDrop(5, 5)], firstHit: 5, bank: 5),
        window: AuthoredWindow(aim: 0.30, power: 0.50, tipUp: 0.0115, tipSide: 0.0005),
        usesBridge: false, difficulty: 2)

    // MARK: 7. Combination Chain
    // BreakProbe tricks combo-chain (20-Nov-2026). Unchanged on the 0.7.0 physics (tricks near, 21-Nov-2026); windows:
    // aim -16.80 to -15.48 degrees, power 1.20 to 5.55 m/s, tip height -10.5 to +14.0 mm, side -3.0 to +4.5 mm.
    public static let comboChain = AuthoredTrick(
        id: "combo-chain", number: 7,
        layout: authoredLayout([0: Vec2(1.4597, 0.5082), 3: Vec2(2.0396, 0.3542), 4: Vec2(2.1263, 0.3103),
                                7: Vec2(2.2040, 0.2520)]),
        solution: AuthoredStrike(aim: -16.10, power: 3.65, tipUp: 0.0045, tipSide: 0),
        goal: AuthoredGoal(drops: [AuthoredDrop(7, 1)], firstHit: 3),
        window: AuthoredWindow(aim: 0.62, power: 1.90, tipUp: 0.0095, tipSide: 0.0030),
        usesBridge: false, difficulty: 3)

    // MARK: 8. Throw It In
    // BreakProbe tricks throw-it (20-Nov-2026), re-authored near its old answer on the tuned generation two, kept only if
    // the same strike misses with no side and with no friction between the balls. Unchanged on the 0.7.0 physics (tricks
    // near, 21-Nov-2026); windows: aim -135.96 to -133.50 degrees, power 1.10 to 8.00 m/s, tip height -7.5 to +7.5 mm,
    // side -14.0 to -5.0 mm.
    public static let throwIt = AuthoredTrick(
        id: "throw-it", number: 8,
        layout: authoredLayout([0: Vec2(0.8025, 0.5992), 2: Vec2(0.4356, 0.2595), 8: Vec2(0.3825, 0.2371)]),
        solution: AuthoredStrike(aim: -134.58, power: 5.10, tipUp: 0, tipSide: -0.012),
        goal: AuthoredGoal(drops: [AuthoredDrop(8, 0)], firstHit: 2),
        window: AuthoredWindow(aim: 1.08, power: 2.90, tipUp: 0.0075, tipSide: 0.0020),
        usesBridge: false, difficulty: 2)

    // MARK: 9. The Massé
    // BreakProbe tricks masse-curve (20-Nov-2026), re-authored near its old answer on the tuned generation two, kept only
    // if a level cue misses. Unchanged on the 0.7.0 physics (tricks near, 21-Nov-2026); windows: aim 51.55 to 56.13
    // degrees, power 1.20 to 2.25 m/s, tip height -4.5 to +3.5 mm, side +11.5 to +14.0 mm (the top is the miscue limit).
    public static let masse = AuthoredTrick(
        id: "masse-curve", number: 9,
        layout: authoredLayout([0: Vec2(1.9992, 0.9726), 4: Vec2(2.1745, 1.0690), 9: Vec2(2.4436, 1.2170)]),
        solution: AuthoredStrike(aim: 53.55, power: 1.60, tipUp: -0.0025, tipSide: 0.0135, elevation: 0.40),
        goal: AuthoredGoal(drops: [AuthoredDrop(9, 3)], firstHit: 9),
        window: AuthoredWindow(aim: 2.00, power: 0.40, tipUp: 0.0020, tipSide: 0.0005),
        usesBridge: false, difficulty: 3)

    // MARK: 10. Jump the Blocker
    // BreakProbe tricks jump-over (20-Nov-2026), kept only if a level cue misses. Unchanged on the 0.7.0 physics (tricks
    // near, 21-Nov-2026); windows: aim 26.64 to 27.34 degrees, power 4.10 to 5.45 m/s, tip height -8.5 to +7.0 mm, side
    // -0.5 to +0.5 mm.
    public static let jumpOver = AuthoredTrick(
        id: "jump-over", number: 10,
        layout: authoredLayout([0: Vec2(1.3708, 0.6854), 6: Vec2(1.6392, 0.8196), 11: Vec2(2.2270, 1.1135)]),
        solution: AuthoredStrike(aim: 27.02, power: 4.55, tipUp: -0.005, tipSide: 0, elevation: 0.55),
        goal: AuthoredGoal(drops: [AuthoredDrop(11, 3)], firstHit: 11),
        window: AuthoredWindow(aim: 0.32, power: 0.45, tipUp: 0.0035, tipSide: 0.0005),
        usesBridge: false, difficulty: 2)

    // MARK: 11. Draw-Massé Carom
    // A solver sweep (21-Nov-2026), kept only if levelling the cue, removing the draw and removing the side each miss;
    // re-authored near it on the tuned generation two. On the 0.7.0 physics it still made the carom but at the edge of its
    // windows, so it was re-centred (tricks near, 21-Nov-2026). Windows: aim 347.04 to 348.94 degrees, power 2.40 to
    // 2.95 m/s, tip height -10.5 to -9.5 mm, side +3.5 to +10.0 mm.
    public static let drawMasseCarom = AuthoredTrick(
        id: "draw-masse-carom", number: 11,
        layout: authoredLayout([0: Vec2(0.9, 0.61), 4: Vec2(1.06, 0.61), 9: Vec2(0.93, 0.219)]),
        solution: AuthoredStrike(aim: 347.88, power: 2.70, tipUp: -0.010, tipSide: 0.006, elevation: 0.45),
        goal: AuthoredGoal(drops: [], firstHit: 4, secondHit: 9),
        window: AuthoredWindow(aim: 0.84, power: 0.25, tipUp: 0.0005, tipSide: 0.0025),
        usesBridge: false, difficulty: 3)
}
