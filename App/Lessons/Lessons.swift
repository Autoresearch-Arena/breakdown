// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The lesson path's data (plans/21-Nov-2026-first-minute-and-lessons-plan.md, package 3): six lessons in order,
//          stop shot, follow, draw, cut and throw, curve, jump. A lesson is a trick shot with stages, so each one holds
//          what a trick shot holds (a layout with only the balls it uses, the reference settings that make it, the goal
//          the trick-shot judge checks, the measured skill window) plus what the lesson flow needs: the one control the
//          lesson is about (the one unlocked in guided try 2), the moment of the recording the Watch beat stops on, the
//          cue angles that work when the lesson raises the cue, and the trick shot that uses the idea, suggested once
//          the lesson is passed. Also the stop shot's second exercise (plans/21-Nov-2026-learn-from-a-retry-plan.md,
//          section 4): the same line with the cue ball further back, where copying the lesson's settings misses.
//          The small shared types the lesson flow hands to the controls live here too: ShotControls (which controls
//          are open this step; ShotPanel, AimGauges and AimOverlay read it, and ShowpieceModel refuses changes to a
//          closed one) and LessonZones (the target bands drawn on the tip picture, the power bar, the aim and the cue
//          angle menu).
//          Every number below was printed by the package's dev tool, "BreakProbe lessons" (Packages/BreakdownCore/
//          Sources/BreakProbe/LessonAuthoring.swift), on physics generation 1, seed 1, standard cloth, 21-Nov-2026; each
//          lesson's comment records the run. Windows are half-widths walked outward from the reference one small step
//          at a time, so a window is an unbroken band. "BreakProbe verify" plays every lesson and the exercise (copied
//          number for number into ContentVerify.swift; KEEP IN STEP) so a physics change that breaks one is caught.
//          Coordinates are table metres on the solver's plan, pockets numbered as in TrickShots.swift.
//          Read by LessonMode (flow), LessonViews (words and drawing) and the judge through `trick`.
// SRP/DRY check: Pass - data and the small types that carry it. The judge is TrickShotJudge (each lesson exposes itself
//          as a TrickShot for it, nothing is re-implemented); TrickSettings, TrickGoal and TrickWindow are reused as they
//          are; the search lives in the package's dev tool.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

// MARK: Controls and zones handed to the shot controls

/// Which shot controls the player may change right now. Everything is open outside a lesson; a lesson's guided tries
/// close some (try 1 closes all, try 2 opens only the lesson's own control).
struct ShotControls: OptionSet, Equatable {
    let rawValue: Int
    static let aim = ShotControls(rawValue: 1 << 0)
    static let power = ShotControls(rawValue: 1 << 1)
    static let tipUp = ShotControls(rawValue: 1 << 2)
    static let tipSide = ShotControls(rawValue: 1 << 3)
    static let elevation = ShotControls(rawValue: 1 << 4)
    static let all: ShotControls = [.aim, .power, .tipUp, .tipSide, .elevation]
}

/// The one control a lesson is about.
enum LessonControl: Equatable {
    case aim, power, tipUp, tipSide, elevation

    var controls: ShotControls {
        switch self {
        case .aim: return .aim
        case .power: return .power
        case .tipUp: return .tipUp
        case .tipSide: return .tipSide
        case .elevation: return .elevation
        }
    }
}

/// The target bands drawn on the controls during guided tries 2 and 3. Each range is where the shot works with every
/// other setting at the lesson's reference (the measured windows); nil means "not marked". `strength` is 1 for try 2's
/// one clear band and lower for try 3's faint marks.
struct LessonZones: Equatable {
    var tipUp: ClosedRange<Double>? = nil         // metres
    var tipSide: ClosedRange<Double>? = nil       // metres
    var power: ClosedRange<Double>? = nil         // metres per second
    var aim: ClosedRange<Double>? = nil           // degrees on the table plan
    var cueAngles: ClosedRange<Int>? = nil        // degrees above level, from CueAngleMenu.angles
    var strength: Double = 1
}

// MARK: The moment the Watch beat stops on

/// Which moment of the reference recording the lesson's Watch beat pauses on. Found in the recording by event kind,
/// never by a caption's words. Chosen from each reference recording's own events ("BreakProbe lessons" prints them).
enum LessonMoment: Equatable {
    /// The cue ball's first touch of another ball (stop shot, cut and throw: what happens at contact is the lesson).
    case contact
    /// The cue ball's first change from sliding to rolling after that first touch: the spin has finished carrying it
    /// forward (follow) or back (draw) and the cloth has caught up.
    case rollAfterContact
    /// The cue ball's first change from sliding to rolling at all: where a curve stops bending.
    case firstRoll
    /// The cue ball's first landing after leaving the cloth: it has cleared the ball in its way.
    case firstLanding

    /// The clock time of this moment in a recording, or nil when the recording has no such moment.
    func time(in tl: Timeline) -> Double? {
        let contact = tl.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }?.time
        func cueTransition(_ test: (LensEvent) -> Bool) -> Double? {
            tl.events.first { $0.kind == .phaseTransition && $0.balls.first?.ball == 0 && test($0) }?.time
        }
        switch self {
        case .contact:
            return contact
        case .rollAfterContact:
            guard let c = contact else { return nil }
            return cueTransition { $0.time > c && $0.phaseFrom == .sliding && $0.phaseTo == .rolling }
        case .firstRoll:
            return cueTransition { $0.phaseFrom == .sliding && $0.phaseTo == .rolling }
        case .firstLanding:
            return cueTransition { $0.flight == .landing }
        }
    }
}

// MARK: A lesson

struct Lesson: Identifiable, Equatable {
    let id: String
    /// Its place in the path, from 1.
    let number: Int
    let title: String
    /// One line for the list and the first card: what the lesson teaches.
    let hook: String
    /// What has to happen, in a few words, for the card while aiming.
    let goalLine: String
    /// The one idea, shown when the Watch beat pauses on its moment.
    let idea: String
    /// What the card says when the pass shot is made.
    let praise: String
    let control: LessonControl
    /// Sixteen positions, index 0 the cue ball; balls not used sit at NextShot.offTable.
    let layout: [Vec2]
    let reference: TrickSettings
    let goal: TrickGoal
    let window: TrickWindow
    /// For a lesson that raises the cue: the run of offered cue angles (CueAngleMenu.angles, degrees) in which the
    /// reference still works with everything else unchanged. Nil for a level-cue lesson.
    let cueAngles: ClosedRange<Int>?
    let moment: LessonMoment
    /// The trick shot (TrickShots) that uses this idea, suggested once the lesson is passed.
    let trickID: String

    /// The lesson as a trick shot, for TrickShotJudge: the same goal, answer and windows, so the judge's verdicts and
    /// advice need no second copy.
    var trick: TrickShot {
        TrickShot(id: id, number: number, title: title, hook: hook, goalLine: goalLine, setup: .layout(layout),
                  solution: reference, goal: goal, usesBridge: false, idea: idea, maths: nil, mathsSpoken: nil,
                  difficulty: .easy, window: window, praise: praise, pending: false)
    }
}

/// The stop shot's second exercise (plan 14, section 4). Aim and power stay at the lesson's own values and locked, so
/// only the tip height can change: a miss then shows what the player understood about tip height, not their aim.
struct LessonExercise: Equatable {
    let layout: [Vec2]
    let reference: TrickSettings
    let goal: TrickGoal
    let window: TrickWindow
    let praise: String

    var trick: TrickShot {
        TrickShot(id: "lesson-stop-exercise", number: 1, title: String(localized: "A new distance"),
                  hook: String(localized: "Same line, the cue ball further back."),
                  goalLine: String(localized: "Pot the 3. The cue ball must stop where it hit."), setup: .layout(layout),
                  solution: reference, goal: goal, usesBridge: false, idea: "", maths: nil, mathsSpoken: nil,
                  difficulty: .easy, window: window, praise: praise, pending: false)
    }
}

/// Sixteen positions with only the named balls on the table (as TrickShots does).
private func placed(_ balls: [Int: Vec2]) -> [Vec2] {
    var out = [Vec2](repeating: NextShot.offTable, count: 16)
    for (k, v) in balls { out[k] = v }
    return out
}

enum Lessons {
    /// The path, in the order it is taught.
    static let all: [Lesson] = [stop, follow, draw, cut, curve, jump]

    static func lesson(id: String) -> Lesson? { all.first { $0.id == id } }

    // Every straight pot below runs along the top-right corner's diagonal (about 26.6 degrees, the line from the middle
    // of the table into that corner), so the pot itself is the one a player meets most often.

    // MARK: 1. Stop shot
    // BreakProbe lessons stop (21-Nov-2026): object ball 0.35 m from the corner, cue ball 0.25 m behind it; power 1.0 to
    // 3.0 m/s and tip -20 to 0 mm swept over six layouts, 1,134 candidates, 206 passed, 72 survived the screen. Windows
    // around the reference: aim 24.75 to 28.37 degrees, power 1.15 to 1.65 m/s, tip height -9.5 to -4.0 mm, any side.
    // The Watch beat stops at contact (the cue ball arrives at 1.10 m/s and hands over all but 0.03 m/s).
    static let stop = Lesson(
        id: "lesson-stop", number: 1, title: String(localized: "Stop shot"),
        hook: String(localized: "Pot the ball and make the cue ball stop dead where it hits."),
        goalLine: String(localized: "Pot the 3. The cue ball must stop where it hit."),
        idea: String(localized: "Struck a little below centre, the cue ball arrives with its spin just worn off. With no spin left, it hands all its speed to the 3 and stops."),
        praise: String(localized: "It stopped dead. All of its speed went into the 3."),
        control: .tipUp,
        layout: placed([0: Vec2(2.0033, 1.0017), 3: Vec2(2.2270, 1.1135)]),
        reference: TrickSettings(aim: 26.57, power: 1.40, tipUp: -0.007, tipSide: 0),
        goal: TrickGoal(drops: [TrickDrop(ball: 3, pocket: 3)], cueZone: TrickZone(centre: Vec2(2.1758, 1.0879), radius: 0.05),
                        firstHit: 3),
        window: TrickWindow(aim: 1.80, power: 0.25, tipUp: 0.0025, tipSide: 0.0195),
        cueAngles: nil, moment: .contact, trickID: "stop-dead")

    // MARK: 2. Follow
    // BreakProbe lessons follow: object ball 1.0 m out, cue ball 0.25 m behind it, finish zone 0.70 m past contact with
    // a 0.15 m radius; kept only if a centre-ball hit misses. A 0.08 m zone first chose a centre hit with a half-
    // millimetre tip window, and "lessons scan" showed each millimetre of tip moves the finish 0.1 to 0.2 m at 2 m/s
    // but about 3 cm at 1.2 m/s, so the search moved to soft strokes. 1,088 candidates, 328 passed, 26 survived.
    // Windows: aim 25.53 to 27.85 degrees, power 1.20 to 1.40 m/s, tip height +4.5 to +12.0 mm, side -4 to +4 mm.
    // The Watch beat stops where the cue ball, stopped for an instant at contact, has been driven on and starts to roll.
    static let follow = Lesson(
        id: "lesson-follow", number: 2, title: String(localized: "Follow"),
        hook: String(localized: "Strike above centre and the cue ball rolls on after the ball it pots."),
        goalLine: String(localized: "Pot the 3 and roll on into the marked circle."),
        idea: String(localized: "At the hit the cue ball stops for an instant, but its topspin is still turning. The spin grips the cloth and drives it forward until it rolls."),
        praise: String(localized: "Rolled on. The topspin carried it through."),
        control: .tipUp,
        layout: placed([0: Vec2(1.4220, 0.7110), 3: Vec2(1.6456, 0.8228)]),
        reference: TrickSettings(aim: 26.69, power: 1.30, tipUp: 0.0085, tipSide: 0),
        goal: TrickGoal(drops: [TrickDrop(ball: 3, pocket: 3)], cueZone: TrickZone(centre: Vec2(2.2206, 1.1103), radius: 0.15),
                        firstHit: 3),
        window: TrickWindow(aim: 1.16, power: 0.10, tipUp: 0.0035, tipSide: 0.0040),
        cueAngles: nil, moment: .rollAfterContact, trickID: "follow-train")

    // MARK: 3. Draw
    // BreakProbe lessons draw: object ball 0.40 m out, cue ball 0.20 m behind it, finish zone 0.45 m behind contact with
    // a 0.25 m radius ("come back between 0.2 and 0.7 m"); kept only if a centre-ball hit misses. 1,496 candidates, 330
    // passed, 94 survived. Windows: aim 23.72 to 29.88 degrees, power 1.30 to 1.70 m/s, tip height -14.0 to -10.0 mm,
    // any side. The Watch beat stops where the drawn-back cue ball starts to roll.
    static let draw = Lesson(
        id: "lesson-draw", number: 3, title: String(localized: "Draw"),
        hook: String(localized: "Strike below centre and the cue ball comes back toward you after the pot."),
        goalLine: String(localized: "Pot the 3 and bring the cue ball back into the marked circle."),
        idea: String(localized: "Struck low, the cue ball still carries backspin when it hits. It stops for an instant, then the backspin grips the cloth and pulls it back until it rolls."),
        praise: String(localized: "Drawn back. The backspin did the pulling."),
        control: .tipUp,
        layout: placed([0: Vec2(2.0033, 1.0017), 3: Vec2(2.1822, 1.0911)]),
        reference: TrickSettings(aim: 26.80, power: 1.50, tipUp: -0.012, tipSide: 0),
        goal: TrickGoal(drops: [TrickDrop(ball: 3, pocket: 3)], cueZone: TrickZone(centre: Vec2(1.7286, 0.8643), radius: 0.25),
                        firstHit: 3),
        window: TrickWindow(aim: 3.08, power: 0.20, tipUp: 0.0020, tipSide: 0.0195),
        cueAngles: nil, moment: .rollAfterContact, trickID: "bridge-draw")

    // MARK: 4. Cut and throw
    // BreakProbe lessons cut: a 30 degree cut, object ball 0.35 m from the corner, cue ball 0.45 m from the ghost-ball
    // spot. 2,592 candidates, 912 passed, 528 survived. The reference aim, 57.13 degrees, is 0.57 degrees THINNER than
    // the geometric ghost ball (56.565): friction at contact drags the 3 a little along the cue ball's path (throw), so
    // the cut is overdone to allow for it. Windows: aim 56.37 to 57.89 degrees, power 0.70 to 3.65 m/s, any tip.
    // The Watch beat stops at contact.
    static let cut = Lesson(
        id: "lesson-cut", number: 4, title: String(localized: "Cut and throw"),
        hook: String(localized: "Hit the ball off-centre to send it off at an angle into the pocket."),
        goalLine: String(localized: "Cut the 3 into the top-right corner."),
        idea: String(localized: "The 3 leaves along the line through the two centres at contact. Friction there drags it a little along the cue ball's path, so cut a touch thinner than the line says."),
        praise: String(localized: "Cut in. You allowed for the throw."),
        control: .aim,
        layout: placed([0: Vec2(1.9279, 0.7124), 3: Vec2(2.2270, 1.1135)]),
        reference: TrickSettings(aim: 57.13, power: 2.15, tipUp: 0, tipSide: 0),
        goal: TrickGoal(drops: [TrickDrop(ball: 3, pocket: 3)], firstHit: 3),
        window: TrickWindow(aim: 0.76, power: 1.45, tipUp: 0.0195, tipSide: 0.0195),
        cueAngles: nil, moment: .contact, trickID: "throw-it")

    // MARK: 5. Curve
    // BreakProbe lessons curve: the 9 0.55 m straight ahead, the 4 0.20 m ahead and 0.034 m (1.2 radii) to the right of
    // the line, so it half-blocks it. Departure from the plan's picture of a ball dead in the way, on evidence: "lessons
    // curvescan" shows a raised cue with right side bends the cue ball only 10 to 25 degrees on generation one, too
    // little to pass a ball on the line and come back to it in half a metre (three runs with the blocker on the line
    // never reached the target; the massé trick takes its extra turn from a cushion). 14,880 candidates, 187 passed, 28
    // survived; kept only if the same strike with a level cue misses. Windows: aim 19.28 to 27.28 degrees, power 1.15 to
    // 1.80 m/s, tip height -17.0 to -6.5 mm, side +12.1 to +19.6 mm; cue angles 25 to 30 degrees. The Watch beat stops
    // where the cue ball starts to roll, which is where the bend ends.
    static let curve = Lesson(
        id: "lesson-curve", number: 5, title: String(localized: "Curve"),
        hook: String(localized: "Raise the cue and hit to one side: the cue ball bends round a ball in its way."),
        goalLine: String(localized: "Curve round the 4 and touch the 9 first."),
        idea: String(localized: "A raised cue struck right of centre spins the cue ball on a tilted axis. While it slides, the cloth pushes sideways on that spin and the path bends. Once it rolls, it runs straight."),
        praise: String(localized: "Bent round the 4. That is a curve."),
        control: .tipSide,
        layout: placed([0: Vec2(1.0000, 0.6350), 4: Vec2(1.2000, 0.6007), 9: Vec2(1.5500, 0.6350)]),
        reference: TrickSettings(aim: 23.28, power: 1.45, tipUp: -0.012, tipSide: 0.0171,
                                 elevation: CueAngleMenu.sine(forAngle: 30)),
        goal: TrickGoal(drops: [], firstHit: 9),
        window: TrickWindow(aim: 4.00, power: 0.30, tipUp: 0.0050, tipSide: 0.0025),
        cueAngles: 25...30, moment: .firstRoll, trickID: "masse-curve")

    // MARK: 6. Jump
    // BreakProbe lessons jump: the 6 0.25 m straight ahead, the 11 1.0 m ahead; cue angles 20 to 40 degrees, power 3 to
    // 5.5 m/s; kept only if a level cue misses AND at least two neighbouring cue angles work (a first run chose a strike
    // only 40 degrees made). 1,584 candidates, 468 passed, 258 survived. Windows: aim -2.26 to -0.10 degrees, power 3.35
    // to 5.00 m/s, tip height -6.5 to +9.0 mm, side -2.5 to +1.0 mm; cue angles 40 to 70 degrees. The Watch beat stops
    // at the first landing, past the 6.
    static let jump = Lesson(
        id: "lesson-jump", number: 6, title: String(localized: "Jump"),
        hook: String(localized: "Raise the cue steeply and the cue ball hops over a ball in its way."),
        goalLine: String(localized: "Jump the 6 and touch the 11 first."),
        idea: String(localized: "A raised cue drives the cue ball down into the slate, and the slate throws it up. It flies over the 6 and lands beyond it."),
        praise: String(localized: "Clean over the top."),
        control: .elevation,
        layout: placed([0: Vec2(1.0000, 0.6350), 6: Vec2(1.2500, 0.6350), 11: Vec2(2.0000, 0.6350)]),
        reference: TrickSettings(aim: -1.18, power: 4.20, tipUp: 0.0015, tipSide: 0,
                                 elevation: CueAngleMenu.sine(forAngle: 40)),
        goal: TrickGoal(drops: [], firstHit: 11),
        window: TrickWindow(aim: 1.08, power: 0.80, tipUp: 0.0075, tipSide: 0.0010),
        cueAngles: 40...70, moment: .firstLanding, trickID: "jump-over")

    // MARK: The stop shot's second exercise
    // BreakProbe lessons stop-exercise: on the stop lesson's line, the cue ball 0.10 to 0.50 m behind the 3. Kept: the
    // distance whose working tip band (at least 4 mm wide, with the lesson's own aim and power) is furthest from the
    // lesson's -7 mm, so copying the lesson misses clearly. At 0.45 m copying misses (the cue ball rolls on) and tip
    // heights -18.0 to -13.0 mm stop it. Windows: aim 1.50 degrees, power 0.05 m/s, tip height 2.5 mm, any side.
    static let stopExercise = LessonExercise(
        layout: placed([0: Vec2(1.8245, 0.9123), 3: Vec2(2.2270, 1.1135)]),
        reference: TrickSettings(aim: 26.57, power: 1.40, tipUp: -0.0155, tipSide: 0),
        goal: TrickGoal(drops: [TrickDrop(ball: 3, pocket: 3)], cueZone: TrickZone(centre: Vec2(2.1759, 1.0880), radius: 0.05),
                        firstHit: 3),
        window: TrickWindow(aim: 1.50, power: 0.05, tipUp: 0.0025, tipSide: 0.0195),
        praise: String(localized: "Stopped dead from further back. You changed the tip height instead of copying the lesson."))
}
