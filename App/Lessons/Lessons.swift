// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The lesson path's data (plans/21-Nov-2026-first-minute-and-lessons-plan.md, package 3): six lessons in order,
//          stop shot, follow, draw, throw, massé, jump (the glossary's names, ShotNames.swift). A lesson is a trick
//          shot with stages, so each one holds what a trick shot holds (a layout with only the balls it uses, the
//          reference settings that make it, the goal the trick-shot judge checks, the measured skill window) plus what
//          the lesson flow needs: the one control the lesson is about (the one unlocked in guided try 2), the moment of the recording the Watch beat stops on, the
//          cue angles that work when the lesson raises the cue, and the trick shot that uses the idea, suggested once
//          the lesson is passed. Also the stop shot's second exercise (plans/21-Nov-2026-learn-from-a-retry-plan.md,
//          section 4): the same line with the cue ball further back, where copying the lesson's settings misses.
//          The small shared types the lesson flow hands to the controls live here too: ShotControls (which controls
//          are open this step; ShotPanel, AimGauges and AimOverlay read it, and ShowpieceModel refuses changes to a
//          closed one) and LessonZones (the target bands drawn on the tip picture, the power bar, the aim and the cue
//          angle menu).
//          Every number (layout, reference, goal, window, cue angles) is the package library's
//          (Packages/BreakdownCore/Sources/BreakdownAuthored/AuthoredLessons.swift), printed by the package's dev tool
//          ("BreakProbe lessons", LessonAuthoring.swift, and "BreakProbe tricks near", Reauthor.swift) and played by
//          "BreakProbe verify" before every upload, so a physics change that breaks one is caught; the runs are recorded
//          beside the numbers there. Windows are half-widths walked outward from the reference one small step at a time,
//          so a window is an unbroken band.
//          Coordinates are table metres on the solver's plan, pockets numbered as in TrickShots.swift.
//          Read by LessonMode (flow), LessonViews (words and drawing) and the judge through `trick`.
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: every lesson and the exercise checked on the
//          tuned generation-two physics; the stop shot, follow, draw, curve and the exercise re-authored with every tip
//          inside the miscue limit, every window measured again; layouts kept except the exercise's distance.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6: item 38, every number moved to the package's
//          authored library (BreakdownAuthored, AuthoredLessons), which the content check plays too, so no copy can
//          drift; item 10, every lesson re-laid on a line a standing player reaches (the reach ladder says a square
//          stance), so no lesson opens with a card about a rest it never uses: stop and draw straight across the table
//          into the top side pocket, follow into the top-right corner on a steep line from near the bottom rail, curve
//          and jump a fifth of a metre nearer the head rail; all re-authored on the 0.7.0 physics.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream cards, plans/22-Nov-2026-phone-bug-hunt.md #23: Cut and
//          throw names its pocket in table words ("the corner nearest it"), not "top-right", which was only right with
//          the phone sideways.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 11, one glossary of shot names: every lesson
//          names its technique (Lesson.technique) and takes its title from the glossary (ShotNames.swift), so a lesson,
//          its achievement and the trick shot built on it use one word: "Cut and throw" is now "Throw" and "Curve" is
//          now "Massé", whose praise says massé too; the massé lesson's goal says "bend round" as its idea does; the throw
//          lesson's hook names the throw it teaches.)
// SRP/DRY check: Pass - the app's types, words and lesson flow data; titles are the glossary's (ShotTechnique.name);
//          the numbers are read from the package library and converted by TrickShots' converters (TrickSettings(_:),
//          TrickGoal(_:), TrickWindow(_:)). The judge is
//          TrickShotJudge (each lesson exposes itself as a TrickShot for it, nothing is re-implemented); the search lives
//          in the package's dev tool.
import BreakdownAuthored
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
    /// The technique the lesson teaches (UI rethink package 11): its title is this technique's one name.
    let technique: ShotTechnique
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

enum Lessons {
    /// The path, in the order it is taught.
    static let all: [Lesson] = [stop, follow, draw, cut, curve, jump]

    static func lesson(id: String) -> Lesson? { all.first { $0.id == id } }

    /// One lesson: the package library's numbers with this file's words, its control, its Watch moment and its trick.
    /// A raised-cue lesson's reference elevation is the library's sine of its offered cue angle, the same formula as
    /// CueAngleMenu.sine(forAngle:), so the control can set it exactly (LessonTests checks).
    /// UI rethink package 11: the title is the technique's glossary name, never typed here, so it cannot drift.
    private static func make(_ a: AuthoredLesson, technique: ShotTechnique, hook: String, goalLine: String,
                             idea: String, praise: String, control: LessonControl, moment: LessonMoment,
                             trickID: String) -> Lesson {
        Lesson(id: a.id, number: a.number, technique: technique, title: technique.name, hook: hook, goalLine: goalLine,
               idea: idea, praise: praise, control: control, layout: a.layout, reference: TrickSettings(a.reference),
               goal: TrickGoal(a.goal),
               window: TrickWindow(a.window), cueAngles: a.cueAngles, moment: moment, trickID: trickID)
    }

    // MARK: 1. Stop shot
    static let stop = make(
        AuthoredLessons.stop, technique: .stop,
        hook: String(localized: "Pot the ball and make the cue ball stop dead where it hits."),
        goalLine: String(localized: "Pot the 3. The cue ball must stop where it hit."),
        idea: String(localized: "Struck a little below centre, the cue ball arrives with its spin just worn off. With no spin left, it hands all its speed to the 3 and stops."),
        praise: String(localized: "It stopped dead. All of its speed went into the 3."),
        control: .tipUp, moment: .contact, trickID: "stop-dead")

    // MARK: 2. Follow
    static let follow = make(
        AuthoredLessons.follow, technique: .follow,
        hook: String(localized: "Strike above centre and the cue ball rolls on after the ball it pots."),
        goalLine: String(localized: "Pot the 3 and roll on into the marked circle."),
        idea: String(localized: "At the hit the cue ball stops for an instant, but its topspin is still turning. The spin grips the cloth and drives it forward until it rolls."),
        praise: String(localized: "Rolled on. The topspin carried it through."),
        control: .tipUp, moment: .rollAfterContact, trickID: "follow-train")

    // MARK: 3. Draw
    static let draw = make(
        AuthoredLessons.draw, technique: .draw,
        hook: String(localized: "Strike below centre and the cue ball comes back toward you after the pot."),
        goalLine: String(localized: "Pot the 3 and bring the cue ball back into the marked circle."),
        idea: String(localized: "Struck low, the cue ball still carries backspin when it hits. It stops for an instant, then the backspin grips the cloth and pulls it back until it rolls."),
        praise: String(localized: "Drawn back. The backspin did the pulling."),
        control: .tipUp, moment: .rollAfterContact, trickID: "bridge-draw")

    // MARK: 4. Throw (a cut allowing for throw)
    static let cut = make(
        AuthoredLessons.cut, technique: .throwShot,
        hook: String(localized: "Cut the ball in at an angle, and allow for the throw that drags it along."),
        goalLine: String(localized: "Cut the 3 into the corner nearest it."),
        idea: String(localized: "The 3 leaves along the line through the two centres at contact. Friction there drags it a little along the cue ball's path, so cut a touch thinner than the line says."),
        praise: String(localized: "Cut in. You allowed for the throw."),
        control: .aim, moment: .contact, trickID: "throw-it")

    // MARK: 5. Massé
    static let curve = make(
        AuthoredLessons.curve, technique: .masse,
        hook: String(localized: "Raise the cue and hit to one side: the cue ball bends round a ball in its way."),
        goalLine: String(localized: "Bend round the 4 and touch the 9 first."),
        idea: String(localized: "A raised cue struck right of centre spins the cue ball on a tilted axis. While it slides, the cloth pushes sideways on that spin and the path bends. Once it rolls, it runs straight."),
        praise: String(localized: "Bent round the 4. That is a massé."),
        control: .tipSide, moment: .firstRoll, trickID: "masse-curve")

    // MARK: 6. Jump
    static let jump = make(
        AuthoredLessons.jump, technique: .jump,
        hook: String(localized: "Raise the cue steeply and the cue ball hops over a ball in its way."),
        goalLine: String(localized: "Jump the 6 and touch the 11 first."),
        idea: String(localized: "A raised cue drives the cue ball down into the slate, and the slate throws it up. It flies over the 6 and lands beyond it."),
        praise: String(localized: "Clean over the top."),
        control: .elevation, moment: .firstLanding, trickID: "jump-over")

    // MARK: The stop shot's second exercise
    static let stopExercise = LessonExercise(
        layout: AuthoredLessons.stopExercise.layout,
        reference: TrickSettings(AuthoredLessons.stopExercise.reference),
        goal: TrickGoal(AuthoredLessons.stopExercise.goal),
        window: TrickWindow(AuthoredLessons.stopExercise.window),
        praise: String(localized: "Stopped dead from further back. You changed the tip height instead of copying the lesson."))
}
