// Author: Claude Opus 5.5 High
// Edited: GPT 6.2 Sol, 21-November-2026 (draw-massé carom lesson).
// Date: 20-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (The Called Break, Throw It In, The Massé and Jump the Blocker authored with the capped search and playable; elevation is the sine the solver uses).
// Edited: Claude Haiku 5.5 High, 20-November-2026 (every player-facing line is wrapped in String(localized:) for translation)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the list is sorted easiest first, ties in authored order, and the
//          player sees each shot's place in that list (listNumber); the authored numbers below are unchanged)
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: every shot checked on the tuned generation-two
//          physics, now the default; the ones that missed or sat at a window's edge re-authored near their old answers,
//          every tip inside the miscue limit, and every window measured again; layouts and goals unchanged.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6, item 38: every number moved to the package's
//          authored library (BreakdownAuthored, AuthoredTricks), which the dev tool's content check plays too, so no copy
//          can drift; this file keeps the types, the words and the list order, and reads the numbers. Every shot was
//          re-checked or re-authored on the 0.7.0 physics; the runs are recorded beside the numbers in AuthoredTricks.)
// PURPOSE: The trick-shot library as the app shows it. Eleven shots, each with its id, title, a one-sentence hook, where
//          the balls start (only the balls it uses; every other ball is off the table), the authored answer (aim, power,
//          cue-tip height and side; cue elevation for the massé, the jump and the carom), the goal the app checks from
//          the recording (which balls must drop and in which pockets, which ball the cue ball must touch first and
//          second, a ball that must bank, where the cue ball must stop; the cue ball must never scratch), whether it
//          needs the mechanical bridge, the one physics idea it teaches in plain words with an optional equation, a
//          difficulty, and the skill window: how far each setting can stray from the answer and the shot still works.
//          The numbers (layout, answer, goal, window, bridge, difficulty) are the package library's
//          (Packages/BreakdownCore/Sources/BreakdownAuthored/AuthoredTricks.swift), authored with the real solver by the
//          package's dev tool and checked by "BreakProbe verify" before every upload; the words are here, where the
//          string catalog collects them.
//          Coordinates are table metres on the solver's plan: x along the length (0 to 2.54), y across (0 to 1.27).
//          Pockets by index: 0 (0,0), 1 (2.54,0), 2 (0,1.27), 3 (2.54,1.27) corners; 4 (1.27,0), 5 (1.27,1.27) sides.
//          Read by TrickShotMode (flow), TrickShotJudge (goals and windows) and TrickShotViews (titles and words).
// SRP/DRY check: Pass - the app's types and words; the numbers are read from the package library, never retyped. The
//          converters from the library's types (TrickSettings(_:), TrickGoal(_:), TrickWindow(_:)) live here beside
//          the types they build, and Lessons and EightBallSituations reuse them.
import BreakdownAuthored
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

extension TrickSettings {
    /// A stroke of the package library (a level cue there is elevation 0; here it is nil).
    init(_ s: AuthoredStrike) {
        self.init(aim: s.aim, power: s.power, tipUp: s.tipUp, tipSide: s.tipSide,
                  elevation: s.elevation > 0 ? s.elevation : nil)
    }
}

/// How far each setting can move from the answer, either way, and the shot still works (half-widths, measured).
/// Aim is degrees for a shot and metres for the break; tip values are metres. A zero tipSide means side is not judged.
struct TrickWindow: Equatable {
    var aim: Double
    var power: Double
    var tipUp: Double
    var tipSide: Double
}

extension TrickWindow {
    /// A window of the package library.
    init(_ w: AuthoredWindow) { self.init(aim: w.aim, power: w.power, tipUp: w.tipUp, tipSide: w.tipSide) }
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
    /// For a carom, the ball the cue ball must touch on its second contact.
    var secondHit: Int? = nil
    /// A ball that must touch a cushion before it drops (a bank), if any.
    var bank: Int? = nil
}

extension TrickGoal {
    /// A goal of the package library.
    init(_ g: AuthoredGoal) {
        self.init(drops: g.drops.map { TrickDrop(ball: $0.ball, pocket: $0.pocket) },
                  cueZone: g.cueZone.map { TrickZone(centre: $0.centre, radius: $0.radius) },
                  firstHit: g.firstHit, secondHit: g.secondHit, bank: g.bank)
    }
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


enum TrickShots {
    static func shot(id: String) -> TrickShot? { all.first { $0.id == id } }

    /// Every shot in the order it was authored; each keeps its authored `number` (its id in the authoring notes
    /// below and in BreakProbe's output).
    private static let authored: [TrickShot] = [
        calledBreak, stopDead, bridgeDraw, followTrain, twoRailKick, crossBank, comboChain, throwIt,
        masse, jumpOver, drawMasseCarom,
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

    /// One shot: the package library's numbers with this file's words. A library difficulty outside 1 to 3 is an
    /// authoring mistake, stopped here rather than shown as some other difficulty.
    private static func make(_ a: AuthoredTrick, title: String, hook: String, goalLine: String, idea: String,
                             maths: String?, mathsSpoken: String?, praise: String) -> TrickShot {
        guard let difficulty = TrickDifficulty(rawValue: a.difficulty) else {
            preconditionFailure("trick shot \(a.id): difficulty \(a.difficulty) is not 1, 2 or 3")
        }
        return TrickShot(id: a.id, number: a.number, title: title, hook: hook, goalLine: goalLine, setup: .layout(a.layout),
                         solution: TrickSettings(a.solution), goal: TrickGoal(a.goal), usesBridge: a.usesBridge,
                         idea: idea, maths: maths, mathsSpoken: mathsSpoken, difficulty: difficulty,
                         window: TrickWindow(a.window), praise: praise, pending: false)
    }

    // MARK: 1. The Called Break
    static let calledBreak = make(
        AuthoredTricks.calledBreak, title: String(localized: "The Called Break"),
        hook: String(localized: "Call it before you hit it: break the rack and send the 3 into the top-right corner."),
        goalLine: String(localized: "Break and drop the 3 in the top-right corner."),
        idea: String(localized: "Where you strike the front ball decides which way the energy runs through the rack. Hit it a fraction off-centre and the push travels down one line of balls, out to the 3, and into the corner."),
        maths: String(localized: "each contact passes the push along the line of centres:  v′ = v · cos θ"),
        mathsSpoken: String(localized: "At each contact a ball passes on its speed times the cosine of the angle between its path and the line through the two centres."),
        praise: String(localized: "Called it, and it went. That is a trick break."))

    // MARK: 2. Stop Dead
    static let stopDead = make(
        AuthoredTricks.stopDead, title: String(localized: "Stop Dead"),
        hook: String(localized: "Pot the 3 and make the cue ball freeze on the very spot where it struck."),
        goalLine: String(localized: "Pot the 3. The cue ball must stop where it hit."),
        idea: String(localized: "Strike just below centre so the backspin has worn off exactly as the cue ball arrives. With no spin left, it hands all its speed to the 3 and stops dead."),
        maths: String(localized: "equal balls, head on, no spin:  v′cue = 0,  v′3 = v"),
        mathsSpoken: String(localized: "Equal balls meeting head on with no spin: the cue ball's speed afterwards is zero, and the 3 leaves with the cue ball's speed."),
        praise: String(localized: "Stopped dead. All of its speed went into the 3."))

    // MARK: 3. The Long Bridge Draw
    static let bridgeDraw = make(
        AuthoredTricks.bridgeDraw, title: String(localized: "The Long Bridge Draw"),
        hook: String(localized: "Pot the 6, then screw the cue ball back the whole length of the table to sink the 2 at the far end."),
        goalLine: String(localized: "Pot the 6, then draw back to pot the 2."),
        idea: String(localized: "Hitting low puts backspin on the cue ball. The 6 takes its forward speed, and the backspin, still spinning, grips the cloth and pulls it all the way back."),
        maths: String(localized: "backspin into speed:  v_back = (2/7) · R · ω"),
        mathsSpoken: String(localized: "The speed the cue ball comes back with is two sevenths of its radius times its spin rate."),
        praise: String(localized: "The whole length of the table, on backspin alone."))

    // MARK: 4. Follow-Through Train
    static let followTrain = make(
        AuthoredTricks.followTrain, title: String(localized: "Follow-Through Train"),
        hook: String(localized: "Pot the 1, and let topspin carry the cue ball on to sink the 2 as well."),
        goalLine: String(localized: "Pot the 1 in the corner, then the 2 in the side."),
        idea: String(localized: "Topspin keeps driving after the hit. The cue ball glances off the 1 sideways, then its forward spin grips the cloth and bends it on toward the 2."),
        maths: String(localized: "rolling cue ball, half-ball cut:  turns about 30° off its line"),
        mathsSpoken: String(localized: "A rolling cue ball that cuts half of the object ball ends up turned about 30 degrees off its original line."),
        praise: String(localized: "Two balls, one stroke. The topspin did the second half."))

    // MARK: 5. Two-Rail Kick
    static let twoRailKick = make(
        AuthoredTricks.twoRailKick, title: String(localized: "Two-Rail Kick"),
        hook: String(localized: "The 5 is hidden behind two balls. Send the cue ball the long way round, off two cushions, and pot it anyway."),
        goalLine: String(localized: "Off two cushions, hit the 5 first and pot it."),
        idea: String(localized: "A cushion sends a ball off at about the angle it came in, so each cushion is a mirror. Aim at the 5's reflection, and side spin would bend that angle."),
        maths: String(localized: "angle in ≈ angle out  (cushion grip and spin bend it a few degrees)"),
        mathsSpoken: String(localized: "The angle in is about the angle out; the cushion's grip and any spin bend it a few degrees."),
        praise: String(localized: "Round the houses and in. Two mirrors, one pocket."))

    // MARK: 7. Combination Chain
    static let comboChain = make(
        AuthoredTricks.comboChain, title: String(localized: "Combination Chain"),
        hook: String(localized: "Hit the 3, which hits the 4, which sinks the 7. One push down a line of balls."),
        goalLine: String(localized: "Hit the 3 first. The 7 must drop."),
        idea: String(localized: "Each ball can only push the next one along the line through their two centres, so the last contact, not your first, decides where the 7 goes."),
        maths: String(localized: "direction out = line of centres at contact  (+ a little throw)"),
        mathsSpoken: String(localized: "Each ball leaves along the line through the two centres at the moment of contact, plus a little throw."),
        praise: String(localized: "Three balls, one line, the 7 down."))

    // MARK: 6. Cross-Side Bank
    static let crossBank = make(
        AuthoredTricks.crossBank, title: String(localized: "Cross-Side Bank"),
        hook: String(localized: "Send the 5 away from the pocket, off the far cushion, and back across the table into the side."),
        goalLine: String(localized: "Bank the 5 off the far cushion into the marked side pocket."),
        idea: String(localized: "Picture the pocket's reflection behind the far cushion and send the 5 at that. The cushion turns it back on the mirror line, into the real pocket."),
        maths: String(localized: "aim at the mirror pocket:  y′ = 2R − y_pocket"),
        mathsSpoken: String(localized: "Aim at the mirror image of the pocket: its distance behind the cushion equals the real pocket's distance in front."),
        praise: String(localized: "Off the far cushion and home. The mirror never lies."))

    // MARK: 8. Throw It In
    static let throwIt = make(
        AuthoredTricks.throwIt, title: String(localized: "Throw It In"),
        hook: String(localized: "The 2 and the 8 are touching, lined up to miss the pocket. Side spin drags the 8 in anyway."),
        goalLine: String(localized: "Hit the 2 and throw the 8 into the bottom-left corner."),
        idea: String(localized: "Touching balls rub as they part. Left spin on the cue ball spins the 2, and the friction between the 2 and the 8 drags the 8 off its line and into the pocket."),
        maths: String(localized: "throw angle:  tan θ ≈ μ · v_slip / v_n"),
        mathsSpoken: String(localized: "The throw angle grows with the friction between the balls and how fast their surfaces slip past each other."),
        praise: String(localized: "Thrown in. Friction did what the angle could not."))

    // MARK: 9. The Massé
    static let masse = make(
        AuthoredTricks.masse, title: String(localized: "The Massé"),
        hook: String(localized: "The 4 blocks the way to the 9. Raise the cue, hit the side of the cue ball, and it bends round."),
        goalLine: String(localized: "Curve round the 4 and pot the 9 in the top-right corner."),
        idea: String(localized: "A raised cue struck off-centre spins the cue ball about a tilted axis. As it slides, the cloth's friction pushes sideways on that spin and the path curves."),
        maths: String(localized: "sideways push:  F = μ m g, along the slip of the spinning contact point"),
        mathsSpoken: String(localized: "The cloth pushes with the ball's weight times the friction, in the direction its spinning contact point slips."),
        praise: String(localized: "Bent it round. That is a massé."))

    // MARK: 10. Jump the Blocker
    static let jumpOver = make(
        AuthoredTricks.jumpOver, title: String(localized: "Jump the Blocker"),
        hook: String(localized: "The 6 sits right in the way. Hit down on the cue ball and it hops clean over to sink the 11."),
        goalLine: String(localized: "Jump the 6 and pot the 11 in the top-right corner."),
        idea: String(localized: "A raised cue drives the cue ball down into the slate. The slate pushes back, the ball leaves the cloth, flies over the 6, bounces and rolls on into the 11."),
        maths: String(localized: "flight:  h = v_up² / 2g,  range = 2 · v_up · v_along / g"),
        mathsSpoken: String(localized: "The height is the upward speed squared over twice gravity, and the hop's length is twice the upward speed times the forward speed over gravity."),
        praise: String(localized: "Clean over the top."))

    // MARK: 11. Draw-Massé Carom
    static let drawMasseCarom = make(
        AuthoredTricks.drawMasseCarom, title: String(localized: "Draw-Massé Carom"),
        hook: String(localized: "Hit the 4 first, then bring the cue ball back around to the 9."),
        goalLine: String(localized: "Hit the 4 first, then bring the cue ball back around to the 9."),
        idea: String(localized: "Raise the cue and strike low and to the side. Backspin brings the cue ball back, and the tilted spin bends its path toward the 9."),
        maths: nil,
        mathsSpoken: nil,
        praise: String(localized: "You brought it back around to the 9."))
}
