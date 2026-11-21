// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (The Called Break, Throw It In, The Massé and Jump the Blocker authored with the capped search and playable; elevation is the sine the solver uses).
// Edited: Claude Haiku 5.5 High, 20-November-2026 (every player-facing line is wrapped in String(localized:) for translation)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the list is sorted easiest first, ties in authored order, and the
//          player sees each shot's place in that list (listNumber); the authored numbers below are unchanged)
// PURPOSE: The trick-shot library: data only. Ten shots, each with its id, title, a one-sentence hook, where the balls
//          start (only the balls it uses; every other ball is off the table), the authored answer (aim, power, cue-tip
//          height and side; cue elevation is reserved for the massé and the jump), the goal the app checks from the
//          recording (which balls must drop and in which pockets, which ball the cue ball must touch first, a ball that
//          must bank, where the cue ball must stop; the cue ball must never scratch), whether it needs the mechanical
//          bridge, the one physics idea it teaches in plain words with an optional equation, a difficulty, and the
//          skill window: how far each setting can stray from the answer and the shot still works.
//          Shots 1 to 8 were authored with the real solver by the search in the package's dev tool (run
//          "BreakProbe tricks"; Packages/BreakdownCore/Sources/BreakProbe/TrickAuthoring.swift). Every number below
//          was printed by that search; each shot's comment records the windows it measured, walked outward from the
//          answer one small step at a time, so a window is an unbroken band, never a lucky point. Shots 9 and 10 need
//          cue elevation and airborne balls, which the solver does not have yet; they are listed as pending and show
//          as "Coming next".
//          Coordinates are table metres on the solver's plan: x along the length (0 to 2.54), y across (0 to 1.27).
//          Pockets by index: 0 (0,0), 1 (2.54,0), 2 (0,1.27), 3 (2.54,1.27) corners; 4 (1.27,0), 5 (1.27,1.27) sides.
//          Read by TrickShotMode (flow), TrickShotJudge (goals and windows) and TrickShotViews (titles and words).
// SRP/DRY check: Pass - data and the small types that hold it. The search lives in the package's dev tool and
//          copies nothing from here (the package must not depend on app files); this file holds only its answers.
import BreakdownLensModel
import BreakdownPhysics

/// The settings of one strike. For a shot `aim` is degrees counter-clockwise from the long axis; for the break it is
/// metres off the head ball (positive is to the shooter's left), as everywhere else in the app.
struct TrickSettings: Equatable {
    var aim: Double
    var power: Double            // launch speed, metres per second
    var tipUp: Double            // metres above (+) or below (-) the cue ball's centre
    var tipSide: Double          // metres right (+) or left (-) of centre
    /// How steeply the cue is raised, as the sine of its angle above the table (0.5 is 30 degrees), the solver's own
    /// unit. Only the massé and the jump raise it; nil means a level cue.
    var elevation: Double? = nil
}

/// How far each setting can move from the answer, either way, and the shot still works (half-widths, measured).
/// Aim is degrees for a shot and metres for the break; tip values are metres. A zero tipSide means side is not judged.
struct TrickWindow: Equatable {
    var aim: Double
    var power: Double
    var tipUp: Double
    var tipSide: Double
}

struct TrickDrop: Equatable {
    let ball: Int
    /// The pocket it must drop in; nil for any pocket.
    let pocket: Int?
}

struct TrickZone: Equatable {
    let centre: Vec2
    let radius: Double
}

struct TrickGoal: Equatable {
    var drops: [TrickDrop]
    /// Where the cue ball must come to rest, if anywhere in particular.
    var cueZone: TrickZone? = nil
    /// The ball the cue ball must touch first, if it matters.
    var firstHit: Int? = nil
    /// A ball that must touch a cushion before it drops (a bank), if any.
    var bank: Int? = nil
}

enum TrickSetup: Equatable {
    /// Sixteen positions, index 0 the cue ball; off-table balls sit at NextShot.offTable.
    case layout([Vec2])
    /// The full rack built from this seed (Rack.positions), broken from the head spot.
    case rack(seed: UInt64)
}

enum TrickDifficulty: Int, Comparable {
    case easy = 1, medium, hard
    var label: String {
        switch self { case .easy: return String(localized: "Easy"); case .medium: return String(localized: "Medium"); case .hard: return String(localized: "Hard") }
    }
    static func < (a: TrickDifficulty, b: TrickDifficulty) -> Bool { a.rawValue < b.rawValue }
}

struct TrickShot: Identifiable, Equatable {
    let id: String
    let number: Int
    let title: String
    /// One sentence that sells the shot.
    let hook: String
    /// What has to happen, in a few words, for the card while aiming.
    let goalLine: String
    let setup: TrickSetup
    let solution: TrickSettings
    let goal: TrickGoal
    let usesBridge: Bool
    /// The one physics idea, a sentence for the card.
    let idea: String
    /// The equation behind it, shown behind Show the maths, and how VoiceOver should read it.
    let maths: String?
    let mathsSpoken: String?
    let difficulty: TrickDifficulty
    let window: TrickWindow
    /// What the card says when it is made.
    let praise: String
    /// True while the shot waits on physics the solver does not have yet.
    let pending: Bool

    var isBreak: Bool { if case .rack = setup { return true } else { return false } }
}

/// Sixteen positions with only the named balls on the table.
private func placed(_ balls: [Int: Vec2]) -> [Vec2] {
    var out = [Vec2](repeating: NextShot.offTable, count: 16)
    for (k, v) in balls { out[k] = v }
    return out
}

enum TrickShots {
    static func shot(id: String) -> TrickShot? { all.first { $0.id == id } }

    /// Every shot in the order it was authored; each keeps its authored `number` (its id in the authoring notes
    /// below and in BreakProbe's output).
    private static let authored: [TrickShot] = [
        calledBreak, stopDead, bridgeDraw, followTrain, twoRailKick, crossBank, comboChain, throwIt,
        masse, jumpOver,
    ]

    /// The list the player sees and the order Next shot walks: easiest first. Shots of the same difficulty keep their
    /// authored order (the tuple compares the authored number second), so the order is fixed and does not depend on
    /// how the sort treats ties.
    static let all: [TrickShot] = authored.sorted {
        ($0.difficulty.rawValue, $0.number) < ($1.difficulty.rawValue, $1.number)
    }

    /// The number the player sees: the shot's place in the easiest-first list, from 1. The authored `number` is left
    /// untouched; this is the one to show.
    static func listNumber(of shot: TrickShot) -> Int {
        (all.firstIndex { $0.id == shot.id } ?? 0) + 1
    }

    // MARK: 1. The Called Break
    // Search (BreakProbe tricks called-break-short, 20-Nov-2026, three threads, 24 minutes): a full fifteen-ball rack is
    // chaotic at the scale a player can aim (no ball dropped in the same pocket for three millimetre steps in a row), so
    // the called break uses the front three rows, half a millimetre apart, broken from beside the head spot. For every
    // rack size, cue position, strength and tip the aim was swept in 0.02 degree steps and the longest run in which one
    // ball dropped in one pocket was kept. Measured windows: aim 7.63 to 7.83 degrees (half-width 0.10), power 6.30 to
    // 6.65 m/s, tip height 0 to +0.5 mm. The hardest shot in the list, as a called break should be.
    static let calledBreak = TrickShot(
        id: "called-break", number: 1, title: String(localized: "The Called Break"),
        hook: String(localized: "Call it before you hit it: break the rack and send the 3 into the top-right corner."),
        goalLine: String(localized: "Break and drop the 3 in the top-right corner."),
        setup: .layout(placed([0: Vec2(0.6350, 0.4350), 1: Vec2(1.9050, 0.6350), 2: Vec2(1.9549, 0.6638),
                               3: Vec2(2.0049, 0.6927), 8: Vec2(2.0049, 0.6350), 9: Vec2(1.9549, 0.6062),
                               10: Vec2(2.0049, 0.5773)])),
        solution: TrickSettings(aim: 7.73, power: 6.45, tipUp: 0.0005, tipSide: 0),
        goal: TrickGoal(drops: [TrickDrop(ball: 3, pocket: 3)], firstHit: 1), usesBridge: false,
        idea: String(localized: "Where you strike the front ball decides which way the energy runs through the rack. Hit it a fraction off-centre and the push travels down one line of balls, out to the 3, and into the corner."),
        maths: String(localized: "each contact passes the push along the line of centres:  v′ = v · cos θ"),
        mathsSpoken: String(localized: "At each contact a ball passes on its speed times the cosine of the angle between its path and the line through the two centres."),
        difficulty: .hard, window: TrickWindow(aim: 0.10, power: 0.15, tipUp: 0.0005, tipSide: 0),
        praise: String(localized: "Called it, and it went. That is a trick break."), pending: false)

    // MARK: 2. Stop Dead
    // Search (BreakProbe tricks stop-dead, 20-Nov-2026): 945 candidates (three distances, power 1.5 to 5 m/s, tip
    // height -20 to 0 mm, straight at the pocket), 116 passed, 20 survived the sturdiness screen. Kept: the 0.40 m
    // stun. Measured windows around the answer: aim 41.47 to 42.87 degrees (half-width 0.70), power 1.55 to 1.95 m/s,
    // tip height -9.5 to -6.0 mm, side -3.5 to +3.5 mm. The cue ball rests 1 mm from the contact spot.
    static let stopDead = TrickShot(
        id: "stop-dead", number: 2, title: String(localized: "Stop Dead"),
        hook: String(localized: "Pot the 3 and make the cue ball freeze on the very spot where it struck."),
        goalLine: String(localized: "Pot the 3. The cue ball must stop where it hit."),
        setup: .layout(placed([0: Vec2(1.7233, 0.5318), 3: Vec2(2.0200, 0.8000)])),
        solution: TrickSettings(aim: 42.17, power: 1.75, tipUp: -0.008, tipSide: 0),
        goal: TrickGoal(drops: [TrickDrop(ball: 3, pocket: 3)],
                        cueZone: TrickZone(centre: Vec2(1.9776, 0.7617), radius: 0.05), firstHit: 3),
        usesBridge: false,
        idea: String(localized: "Strike just below centre so the backspin has worn off exactly as the cue ball arrives. With no spin left, it hands all its speed to the 3 and stops dead."),
        maths: String(localized: "equal balls, head on, no spin:  v′cue = 0,  v′3 = v"),
        mathsSpoken: String(localized: "Equal balls meeting head on with no spin: the cue ball's speed afterwards is zero, and the 3 leaves with the cue ball's speed."),
        difficulty: .easy, window: TrickWindow(aim: 0.70, power: 0.20, tipUp: 0.0015, tipSide: 0.0035),
        praise: String(localized: "Stopped dead. All of its speed went into the 3."), pending: false)

    // MARK: 3. The Long Bridge Draw
    // Search (BreakProbe tricks bridge-draw, 20-Nov-2026): the cue ball on the long diagonal in the middle of the table,
    // the 6 12 to 25 cm in front of it (bent up to 2 degrees off the diagonal), aims across 1.2 degrees, power 5 to
    // 8 m/s, draw 14 to 20 mm; the 2 dropped onto the drawn-back path 7 to 16 cm from a pocket at the far end. Two
    // earlier runs (the 6 30 to 55 cm away, the 2 anywhere) found nothing a player could repeat: half-windows of 0.06
    // degrees at best. This run: 2,171 candidates, 871 passed, 137 survived the screen. Measured windows: aim -26.24 to
    // -25.50 degrees (half-width 0.30), power 2.00 to 5.45 m/s, tip height -19.5 to -7.5 mm, side -0.5 to +1.5 mm.
    static let bridgeDraw = TrickShot(
        id: "bridge-draw", number: 3, title: String(localized: "The Long Bridge Draw"),
        hook: String(localized: "Pot the 6, then screw the cue ball back the whole length of the table to sink the 2 at the far end."),
        goalLine: String(localized: "Pot the 6, then draw back to pot the 2."),
        setup: .layout(placed([0: Vec2(1.5000, 0.5200), 2: Vec2(0.0901, 1.2184), 6: Vec2(1.6073, 0.4663)])),
        solution: TrickSettings(aim: -25.94, power: 3.80, tipUp: -0.0135, tipSide: 0),
        goal: TrickGoal(drops: [TrickDrop(ball: 6, pocket: 1), TrickDrop(ball: 2, pocket: 2)], firstHit: 6),
        usesBridge: true,
        idea: String(localized: "Hitting low puts backspin on the cue ball. The 6 takes its forward speed, and the backspin, still spinning, grips the cloth and pulls it all the way back."),
        maths: String(localized: "backspin into speed:  v_back = (2/7) · R · ω"),
        mathsSpoken: String(localized: "The speed the cue ball comes back with is two sevenths of its radius times its spin rate."),
        difficulty: .hard, window: TrickWindow(aim: 0.30, power: 1.65, tipUp: 0.006, tipSide: 0.0005),
        praise: String(localized: "The whole length of the table, on backspin alone."), pending: false)

    // MARK: 4. Follow-Through Train
    // Search (BreakProbe tricks follow-train, 20-Nov-2026): the 1 placed at three spots, the cue ball at four cut
    // angles, follow 10 to 18 mm at three powers; the 2 dropped onto the cue ball's own recorded path at every
    // sixth sample, toward every pocket. 299,747 candidates, 5,912 passed, 13 survived the sturdiness screen.
    // Measured windows: aim 49.86 to 50.62 degrees (half-width 0.36), power 3.30 to 4.80 m/s, tip height +0.5 to
    // +19.5 mm (a stroke through the centre fails: some follow is needed), side -6.0 to +1.5 mm.
    static let followTrain = TrickShot(
        id: "follow-train", number: 4, title: String(localized: "Follow-Through Train"),
        hook: String(localized: "Pot the 1, and let topspin carry the cue ball on to sink the 2 as well."),
        goalLine: String(localized: "Pot the 1 in the corner, then the 2 in the side."),
        setup: .layout(placed([0: Vec2(1.6830, 0.5403), 1: Vec2(2.0500, 0.9500), 2: Vec2(1.9171, 1.0103)])),
        solution: TrickSettings(aim: 50.22, power: 4.05, tipUp: 0.010, tipSide: 0),
        goal: TrickGoal(drops: [TrickDrop(ball: 1, pocket: 3), TrickDrop(ball: 2, pocket: 5)], firstHit: 1),
        usesBridge: false,
        idea: String(localized: "Topspin keeps driving after the hit. The cue ball glances off the 1 sideways, then its forward spin grips the cloth and bends it on toward the 2."),
        maths: String(localized: "rolling cue ball, half-ball cut:  turns about 30° off its line"),
        mathsSpoken: String(localized: "A rolling cue ball that cuts half of the object ball ends up turned about 30 degrees off its original line."),
        difficulty: .medium, window: TrickWindow(aim: 0.36, power: 0.75, tipUp: 0.0095, tipSide: 0.0015),
        praise: String(localized: "Two balls, one stroke. The topspin did the second half."), pending: false)

    // MARK: 5. Two-Rail Kick
    // Search (BreakProbe tricks two-rail-kick, 20-Nov-2026): the cue ball alone struck from three spots at aims every
    // 2.5 degrees and three powers; the 5 dropped onto the path after exactly two cushions, toward every pocket; two
    // blockers (the 9 and the 10) put on the straight line from the cue ball to the 5, kept only where the kick's own
    // path clears them. 19,218 candidates, 3,407 passed, 215 survived the sturdiness screen. Measured windows: aim
    // 9.40 to 10.28 degrees (half-width 0.44), power 1.80 to 4.20 m/s, tip height -10.0 to +18.5 mm, side -1 to +1 mm.
    static let twoRailKick = TrickShot(
        id: "two-rail-kick", number: 5, title: String(localized: "Two-Rail Kick"),
        hook: String(localized: "The 5 is hidden behind two balls. Send the cue ball the long way round, off two cushions, and pot it anyway."),
        goalLine: String(localized: "Off two cushions, hit the 5 first and pot it."),
        setup: .layout(placed([0: Vec2(0.7000, 0.4500), 5: Vec2(0.2015, 1.2182), 9: Vec2(0.4661, 0.7895),
                               10: Vec2(0.4053, 0.9356)])),
        solution: TrickSettings(aim: 9.84, power: 2.95, tipUp: 0.0045, tipSide: 0),
        goal: TrickGoal(drops: [TrickDrop(ball: 5, pocket: 2)], firstHit: 5),
        usesBridge: false,
        idea: String(localized: "A cushion sends a ball off at about the angle it came in, so each cushion is a mirror. Aim at the 5's reflection, and side spin would bend that angle."),
        maths: String(localized: "angle in ≈ angle out  (cushion grip and spin bend it a few degrees)"),
        mathsSpoken: String(localized: "The angle in is about the angle out; the cushion's grip and any spin bend it a few degrees."),
        difficulty: .hard, window: TrickWindow(aim: 0.44, power: 1.15, tipUp: 0.014, tipSide: 0.001),
        praise: String(localized: "Round the houses and in. Two mirrors, one pocket."), pending: false)

    // MARK: 7. Combination Chain
    // Search (BreakProbe tricks combo-chain, 20-Nov-2026): the 7 placed 0.42 m from the bottom-right corner, the 4 and
    // the 3 laid behind it with bends of up to 10 degrees and gaps of 4 or 9 cm, the cue ball 0.6 m behind the 3;
    // aim swept 3 degrees either side in 0.04 degree steps at three powers. 40,770 candidates, 9,082 passed, 7,289
    // survived the sturdiness screen. Measured windows: aim -16.78 to -15.52 degrees (half-width 0.58), power 1.10 to
    // 6.05 m/s, tip height -11.0 to +19.5 mm, any side.
    static let comboChain = TrickShot(
        id: "combo-chain", number: 7, title: String(localized: "Combination Chain"),
        hook: String(localized: "Hit the 3, which hits the 4, which sinks the 7. One push down a line of balls."),
        goalLine: String(localized: "Hit the 3 first. The 7 must drop."),
        setup: .layout(placed([0: Vec2(1.4597, 0.5082), 3: Vec2(2.0396, 0.3542), 4: Vec2(2.1263, 0.3103),
                               7: Vec2(2.2040, 0.2520)])),
        solution: TrickSettings(aim: -16.10, power: 3.65, tipUp: 0.0045, tipSide: 0),
        goal: TrickGoal(drops: [TrickDrop(ball: 7, pocket: 1)], firstHit: 3),
        usesBridge: false,
        idea: String(localized: "Each ball can only push the next one along the line through their two centres, so the last contact, not your first, decides where the 7 goes."),
        maths: String(localized: "direction out = line of centres at contact  (+ a little throw)"),
        mathsSpoken: String(localized: "Each ball leaves along the line through the two centres at the moment of contact, plus a little throw."),
        difficulty: .hard, window: TrickWindow(aim: 0.58, power: 2.40, tipUp: 0.015, tipSide: 0.0195),
        praise: String(localized: "Three balls, one line, the 7 down."), pending: false)

    // MARK: 6. Cross-Side Bank
    // Search (BreakProbe tricks cross-bank, 20-Nov-2026): the 5 placed at eighteen spots across the middle of the
    // table, aimed at the top side pocket's mirror image in the bottom cushion, the cue ball 0.38 m behind it at four
    // cut angles; aim swept 2 degrees either side at three powers; the 5 had to touch a cushion before dropping. 8,856
    // candidates, 1,108 passed, 282 survived the sturdiness screen. Measured windows: aim -95.21 to -94.41 degrees
    // (half-width 0.34), power 2.30 to 6.80 m/s, tip height -8.0 to +19.5 mm, side -6.5 to +1.0 mm.
    static let crossBank = TrickShot(
        id: "cross-bank", number: 6, title: String(localized: "Cross-Side Bank"),
        hook: String(localized: "Send the 5 away from the pocket, off the far cushion, and back across the table into the side."),
        goalLine: String(localized: "Bank the 5 off the far cushion into the marked side pocket."),
        setup: .layout(placed([0: Vec2(1.0663, 0.8296), 5: Vec2(1.0500, 0.4500)])),
        solution: TrickSettings(aim: -94.75, power: 2.80, tipUp: 0.006, tipSide: 0),
        goal: TrickGoal(drops: [TrickDrop(ball: 5, pocket: 5)], firstHit: 5, bank: 5),
        usesBridge: false,
        idea: String(localized: "Picture the pocket's reflection behind the far cushion and send the 5 at that. The cushion turns it back on the mirror line, into the real pocket."),
        maths: String(localized: "aim at the mirror pocket:  y′ = 2R − y_pocket"),
        mathsSpoken: String(localized: "Aim at the mirror image of the pocket: its distance behind the cushion equals the real pocket's distance in front."),
        difficulty: .medium, window: TrickWindow(aim: 0.34, power: 0.50, tipUp: 0.0135, tipSide: 0.001),
        praise: String(localized: "Off the far cushion and home. The mirror never lies."), pending: false)

    // MARK: 8. Throw It In
    // Search (BreakProbe tricks throw-it, 20-Nov-2026, three threads): the 2 and the 8 half a millimetre apart, their
    // line pointing 9 or 12 degrees past the bottom-left corner, the cue ball coming in from four angles; 8,448
    // candidates, 661 passed, 386 survived the screen. Kept only if the same strike misses with no side spin AND misses
    // with no friction between the balls, so the throw is really what makes it. Measured windows: aim -136.49 to
    // -135.87 degrees (half-width 0.30), power 0.60 to 7.65 m/s, tip height -5.0 to +19.5 mm, side -19.5 to -1.0 mm.
    static let throwIt = TrickShot(
        id: "throw-it", number: 8, title: String(localized: "Throw It In"),
        hook: String(localized: "The 2 and the 8 are touching, lined up to miss the pocket. Side spin drags the 8 in anyway."),
        goalLine: String(localized: "Hit the 2 and throw the 8 into the bottom-left corner."),
        setup: .layout(placed([0: Vec2(0.8025, 0.5992), 2: Vec2(0.4356, 0.2595), 8: Vec2(0.3825, 0.2371)])),
        solution: TrickSettings(aim: -136.19, power: 3.85, tipUp: 0.0075, tipSide: -0.012),
        goal: TrickGoal(drops: [TrickDrop(ball: 8, pocket: 0)], firstHit: 2), usesBridge: false,
        idea: String(localized: "Touching balls rub as they part. Left spin on the cue ball spins the 2, and the friction between the 2 and the 8 drags the 8 off its line and into the pocket."),
        maths: String(localized: "throw angle:  tan θ ≈ μ · v_slip / v_n"),
        mathsSpoken: String(localized: "The throw angle grows with the friction between the balls and how fast their surfaces slip past each other."),
        difficulty: .medium, window: TrickWindow(aim: 0.30, power: 3.25, tipUp: 0.012, tipSide: 0.0075),
        praise: String(localized: "Thrown in. Friction did what the angle could not."), pending: false)

    // MARK: 9. The Massé
    // Search (BreakProbe tricks masse-curve, 20-Nov-2026, three threads): the 4 dead in the way between the cue ball
    // and the 9, which hangs near the top-right corner; cue raised to sine 0.4 or 0.5 (about 24 to 30 degrees), side
    // offsets of 0.6 to 0.75 of a radius, 0.6 to 1.2 m/s, aims 40 degrees either side of straight; 5,184 candidates,
    // 82 passed. Kept only if the same strike with a level cue misses. Measured windows: aim 62.99 to 68.19 degrees
    // (half-width 1.62), power 0.80 to 1.45 m/s, tip height -7.5 to +0.5 mm, side +14.6 to +19.1 mm.
    static let masse = TrickShot(
        id: "masse-curve", number: 9, title: String(localized: "The Massé"),
        hook: String(localized: "The 4 blocks the way to the 9. Raise the cue, hit the side of the cue ball, and it bends round."),
        goalLine: String(localized: "Curve round the 4 and pot the 9 in the top-right corner."),
        setup: .layout(placed([0: Vec2(1.9992, 0.9726), 4: Vec2(2.1745, 1.0690), 9: Vec2(2.4436, 1.2170)])),
        solution: TrickSettings(aim: 64.61, power: 0.95, tipUp: -0.0035, tipSide: 0.0171, elevation: 0.5),
        goal: TrickGoal(drops: [TrickDrop(ball: 9, pocket: 3)], firstHit: 9), usesBridge: false,
        idea: String(localized: "A raised cue struck off-centre spins the cue ball about a tilted axis. As it slides, the cloth's friction pushes sideways on that spin and the path curves."),
        maths: String(localized: "sideways push:  F = μ m g, along the slip of the spinning contact point"),
        mathsSpoken: String(localized: "The cloth pushes with the ball's weight times the friction, in the direction its spinning contact point slips."),
        difficulty: .hard, window: TrickWindow(aim: 1.62, power: 0.15, tipUp: 0.004, tipSide: 0.002),
        praise: String(localized: "Bent it round. That is a massé."), pending: false)

    // MARK: 10. Jump the Blocker
    // Search (BreakProbe tricks jump-over, 20-Nov-2026, three threads): the 6 in the way 0.3 or 0.35 m ahead of the cue
    // ball, the 11 near the top-right corner beyond it; cue raised to sine 0.5 to 0.65, 3 to 5.5 m/s, aims 1.5 degrees
    // either side of straight; 2,728 candidates, 273 passed, 88 survived the screen. Kept only if the same strike with
    // a level cue misses. Measured windows: aim 26.70 to 27.34 degrees (half-width 0.32), power 3.90 to 5.15 m/s, tip
    // height -19.5 to +10.0 mm.
    static let jumpOver = TrickShot(
        id: "jump-over", number: 10, title: String(localized: "Jump the Blocker"),
        hook: String(localized: "The 6 sits right in the way. Hit down on the cue ball and it hops clean over to sink the 11."),
        goalLine: String(localized: "Jump the 6 and pot the 11 in the top-right corner."),
        setup: .layout(placed([0: Vec2(1.3708, 0.6854), 6: Vec2(1.6392, 0.8196), 11: Vec2(2.2270, 1.1135)])),
        solution: TrickSettings(aim: 27.02, power: 4.55, tipUp: -0.005, tipSide: 0, elevation: 0.55),
        goal: TrickGoal(drops: [TrickDrop(ball: 11, pocket: 3)], firstHit: 11), usesBridge: false,
        idea: String(localized: "A raised cue drives the cue ball down into the slate. The slate pushes back, the ball leaves the cloth, flies over the 6, bounces and rolls on into the 11."),
        maths: String(localized: "flight:  h = v_up² / 2g,  range = 2 · v_up · v_along / g"),
        mathsSpoken: String(localized: "The height is the upward speed squared over twice gravity, and the hop's length is twice the upward speed times the forward speed over gravity."),
        difficulty: .medium, window: TrickWindow(aim: 0.32, power: 0.60, tipUp: 0.0145, tipSide: 0),
        praise: String(localized: "Clean over the top."), pending: false)
}
