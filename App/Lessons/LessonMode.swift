// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (review fix: a lesson plays on the standard cloth it was authored on and
//          puts the player's surface back when it ends.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 11 and 36: in try 3 and the pass shot of a lesson that
//          is not about power, the power is held at the lesson's stroke through the locks, so a pull-back plays the shot
//          without moving it; the bands handed to the controls are only the part each control can reach; the pass
//          shot's "Back to the lesson's stroke" (model.tryAgain(restoring:)); celebrationMoment says which made-it
//          sound the screen plays with the glow, the big one for the sixth lesson and the pass that completes the path.)
// PURPOSE: Lesson mode: walks the player through one lesson of the path (Lessons.swift) in the plan's beats
//          (plans/21-Nov-2026-first-minute-and-lessons-plan.md, package 3), shaped like TrickShotMode:
//            Ready      - the lesson's layout on the table, a card with what it teaches and Watch it.
//            Watch      - the reference shot plays at full speed (watching), then replays slowly in the Physics Lens
//                         (replaying) and pauses on the lesson's moment (keyMoment) while the card gives the idea.
//            Try 1      - aim, power, tip and cue angle set to the reference and locked: the player only shoots.
//            Try 2      - only the lesson's own control is open, starting from neutral, with its target band drawn.
//            Try 3      - every control open, starting from the player's own try-2 settings, the bands faint. In a
//                         lesson that is not about power, the power stays held at the lesson's stroke (see powerHeld).
//            Pass shot  - no bands, from the player's own settings, the power held as in try 3. Made: the lesson is
//                         marked passed (stored like trick-shot progress) and the card suggests the trick shot that uses
//                         the idea; the stop shot also offers its second exercise (plan 14, section 4). Missed: besides
//                         Try again, "Back to the lesson's stroke" puts the reference stroke back.
//          After every guided try the card says made or missed with the judge's one line, and offers Try again (same
//          start, same settings, the last try kept as a ghost for the retry comparison) or the next step. Nothing is
//          gated: the next step is offered whether the try was made or not, and every lesson can be opened any time.
//          It drives the table only through ShowpieceModel's own methods (enterLessonTable, the trick-shot loaders,
//          shootNow, replay, scrub, tryAgain, setLens) and learns that a shot finished from the model's aimReady and
//          timelineVersion, forwarded to update() by LessonTableLayer, which also forwards the clock to tick() so the
//          Lens replay can stop on the lesson's moment. Attempts are judged by TrickShotJudge (each lesson exposes
//          itself as a TrickShot) and only when they started from the step's own layout; a raised-cue lesson first
//          checks the cue angle, which the trick judge does not weigh.
//          openControls and zones are read by the model (which refuses changes to closed controls) and handed to the
//          shot controls (ShotPanel, AimGauges, AimOverlay).
//          Passed lessons are stored in UserDefaults under "lessonsDone" as a comma-separated list of ids.
// SRP/DRY check: Pass - flow only. Data is Lessons, judging is TrickShotJudge, views are LessonViews; the table is
//          driven through ShowpieceModel's existing methods (the same loaders TrickShotMode uses), not copies of them.
import BreakdownLensModel
import BreakdownPhysics
import Foundation
import Observation

@MainActor
@Observable
final class LessonMode {
    /// The player's steps after the Watch beat.
    enum Step: Int, Equatable {
        case try1 = 1, try2, try3, pass, exercise
    }

    enum Phase: Equatable {
        /// No lesson on the table.
        case off
        /// Set up at the start, waiting for Watch it.
        case ready
        /// The reference shot is playing at full speed.
        case watching
        /// It replays in the Physics Lens, slowly, toward the lesson's moment.
        case replaying
        /// The replay is paused on the moment; the card gives the idea.
        case keyMoment
        /// The player is lining up a step or their attempt is playing.
        case aiming(Step)
        /// The attempt is over: made or missed, with one line on what to change.
        case judged(Step, TrickVerdict)
        /// The player shot again from where the balls stopped; Try again puts them back.
        case offScript(Step)
    }

    /// The model this mode drives. The model owns the mode, so this does not keep the model alive.
    @ObservationIgnored unowned let model: ShowpieceModel

    private(set) var current: Lesson?
    /// The player's own surface from before the lessons, put back by end().
    @ObservationIgnored private var surfaceBefore: PlaySurface?
    private(set) var phase: Phase = .off
    /// The list (a sheet, or a page of the notebook); opened from the menu's Learn.
    var listOpen = false
    /// Bumped on every pass (and the stop shot's exercise made), so the views fire one haptic, one glow and one made-it
    /// sound per success.
    private(set) var celebrations = 0
    /// Which made-it sound goes with the latest celebration: the big one when the sixth lesson is passed or a pass
    /// completes the whole path. Set before celebrations is bumped, so the table layer reads it in the same change.
    private(set) var celebrationMoment: GameMoment = .madeIt
    /// What the shot panel should be: open while it is the player's turn. Bumped requests make the screen apply it.
    private(set) var wantsAiming = false
    private(set) var aimingRequests = 0
    private(set) var doneIDs: Set<String>
    /// When the reference recording's moment falls, found once the demonstration has been solved.
    private(set) var keyTime: Double?

    /// The player's own settings in this lesson, from their last judged attempt, so try 3 and the pass shot start from
    /// what they did rather than from the answer.
    @ObservationIgnored private var playerSettings: TrickSettings?
    /// The recording already judged, so each attempt is judged once.
    @ObservationIgnored private var judgedVersion = -1
    /// The recording the demonstration produced, so it is never judged as the player's.
    @ObservationIgnored private var demoVersion = -1

    static let doneKey = "lessonsDone"

    init(model: ShowpieceModel) {
        self.model = model
        let stored = UserDefaults.standard.string(forKey: Self.doneKey) ?? ""
        doneIDs = Set(stored.split(separator: ",").map(String.init))
    }

    var isActive: Bool { current != nil && phase != .off }
    func isDone(_ lesson: Lesson) -> Bool { doneIDs.contains(lesson.id) }
    /// Lessons passed, for the menu's mark.
    var passedCount: Int { Lessons.all.filter { isDone($0) }.count }

    /// The step being aimed, judged or retried; nil during the Watch beat and outside a lesson.
    var step: Step? {
        switch phase {
        case .aiming(let s), .judged(let s, _), .offScript(let s): return s
        default: return nil
        }
    }

    /// Which controls the player may change now. Everything outside a step (and outside a lesson).
    var openControls: ShotControls {
        guard let lesson = current, let step else { return .all }
        switch step {
        case .try1: return []
        case .try2: return lesson.control.controls
        // The power is closed while it is held (powerHeld): the model then refuses every change to it, so the touch
        // stroke's pull-back still plays the shot but no longer moves the power (StrokeGesture reads the same set).
        case .try3, .pass: return powerHeld ? ShotControls.all.subtracting(.power) : .all
        // The exercise checks what was learnt about tip height: aim and power stay at the lesson's own values.
        case .exercise: return .tipUp
        }
    }

    /// True in try 3 and the pass shot of a lesson that is not about power: the power stays at the lesson's own stroke.
    /// The reason (review of 0.6.6): the full pull spans the whole ordinary speed range, so a pull-back in those steps
    /// quietly moved the power out of a window a few tenths of a metre per second wide (follow: 1.70 to 2.00 m/s),
    /// Try again then brought the wrong power back, and the bar's plus and minus steps are wider than that window. A
    /// lesson about tip, side, aim or cue angle should not be lost on a power the lesson never asked about.
    var powerHeld: Bool {
        guard let lesson = current, lesson.control != .power, let step else { return false }
        return step == .try3 || step == .pass
    }

    /// The target bands drawn on the controls: try 2 marks the lesson's own control clearly, try 3 marks every open
    /// control faintly, nothing else is marked. Read from the lesson's measured windows, never typed in and never
    /// widened (a wider band would mark settings that miss). Each band is cut to the part its control can actually
    /// reach: the tip dot's travel (model.tipLimit) and the ordinary power range. So every marked setting can be set,
    /// and the middle of a band, where the tip picture puts a dot released inside it, is always a reachable setting that
    /// makes the shot. Keeping the picture's snap-to-centre out of a band is the picture's own rule (AimGauges).
    var zones: LessonZones? {
        guard let lesson = current, let step else { return nil }
        let r = lesson.reference, w = lesson.window
        let tipReach = -model.tipLimit...model.tipLimit
        let tipUp = Self.reachable((r.tipUp - w.tipUp)...(r.tipUp + w.tipUp), within: tipReach)
        let tipSide = Self.reachable((r.tipSide - w.tipSide)...(r.tipSide + w.tipSide), within: tipReach)
        let power = Self.reachable((r.power - w.power)...(r.power + w.power), within: model.powerRange)
        let aim = (r.aim - w.aim)...(r.aim + w.aim)
        switch step {
        case .try2:
            switch lesson.control {
            case .tipUp: return LessonZones(tipUp: tipUp)
            case .tipSide: return LessonZones(tipSide: tipSide)
            case .power: return LessonZones(power: power)
            case .aim: return LessonZones(aim: aim)
            case .elevation: return LessonZones(cueAngles: lesson.cueAngles)
            }
        case .try3:
            // Faint: a third of try 2's strength, enough to find again, too little to read as an instruction. A held
            // power is not a target, so its band is left off.
            return LessonZones(tipUp: tipUp, tipSide: tipSide, power: powerHeld ? nil : power, aim: aim,
                               cueAngles: lesson.cueAngles, strength: 0.35)
        default:
            return nil
        }
    }

    /// Balls and pockets to ring on the table, and the cue ball's finish circle, while nothing is moving.
    var markers: (balls: [Int], pockets: [Int], zone: TrickZone?)? {
        guard let lesson = current else { return nil }
        switch phase {
        case .ready, .keyMoment, .aiming, .judged, .offScript: break
        default: return nil
        }
        let goal = step == .exercise ? Lessons.stopExercise.goal : lesson.goal
        var balls = goal.drops.map(\.ball)
        if let first = goal.firstHit, !balls.contains(first) { balls.append(first) }
        return (balls, goal.drops.compactMap(\.pocket), goal.cueZone)
    }

    // MARK: Flow

    /// Put a lesson on the table, ready to watch. Closes the menu and the list; ends any other mode.
    func begin(_ lesson: Lesson) {
        // Only on a fresh entry: moving from one lesson to the next must not record the lesson's cloth as the player's.
        if current == nil { surfaceBefore = model.surface }
        model.enterLessonTable()
        // Every lesson was authored on the standard cloth, and its targets only hold there (the stop shot finishes
        // 27 cm off centre on the Moon, against a 5 cm zone). Through the model's own surface change, as Behind the
        // 8-Ball does, so the Surface menu, the 3D cloth and the solver agree.
        model.setSurface(.cloth)
        current = lesson
        listOpen = false
        playerSettings = nil
        keyTime = nil
        load(lesson.layout, lesson.reference)
        model.setLens(false)
        phase = .ready
        requestAiming(false)
    }

    /// Watch it: the reference shot at full speed. update() moves on to the Lens replay when it has played.
    func watch() {
        guard let lesson = current else { return }
        load(lesson.layout, lesson.reference)
        model.setLens(false)
        requestAiming(false)
        phase = .watching
        // A lesson is an authored mode, so the model solves this directly and the new recording is on screen now.
        model.shootNow()
        demoVersion = model.timelineVersion
        keyTime = lesson.moment.time(in: model.timeline)
    }

    /// Your turn after the Watch beat: guided try 1.
    func yourTurn() { start(.try1) }

    /// The next step after a judged try (try 1 to try 2 to try 3 to the pass shot).
    func nextStep() {
        guard let step, let next = Step(rawValue: step.rawValue + 1), next != .exercise else { return }
        start(next)
    }

    /// The stop shot's second exercise, offered once the stop lesson is passed.
    func startExercise() {
        guard current?.id == Lessons.stop.id else { return }
        start(.exercise)
    }

    /// Try again: same start, same settings, the last try kept as a ghost (the model's own retry and comparison).
    func tryAgain() {
        guard let step else { return }
        if model.canTryAgain, let attempt = model.currentAttempt, starts(attempt, at: step) {
            model.tryAgain()
            phase = .aiming(step)
            requestAiming(true)
        } else {
            start(step)
        }
    }

    /// The pass shot's "Back to the lesson's stroke": same start, the last try kept as a ghost and compared as Try
    /// again does, but with the lesson's own reference stroke (aim, power, tip, cue angle) instead of the player's last
    /// settings, for a player whose own settings have wandered off. Only offered after a missed pass shot.
    func backToLessonStroke() {
        guard let lesson = current, let step, step == .pass else { return }
        let stroke = lesson.reference
        // The next plain Try again or fresh start of the step begins from here too, until the next judged attempt.
        playerSettings = stroke
        if model.canTryAgain, let attempt = model.currentAttempt, starts(attempt, at: step) {
            model.tryAgain(restoring: stroke)
        } else {
            // No attempt from this step's start to keep as the ghost: lay the step out afresh with the stroke.
            load(lesson.layout, stroke)
            model.setLens(false)
        }
        phase = .aiming(step)
        requestAiming(true)
    }

    /// The next lesson in the path, or the list after the last one.
    func nextLesson() {
        guard let lesson = current, let i = Lessons.all.firstIndex(of: lesson), i + 1 < Lessons.all.count else {
            listOpen = true
            return
        }
        begin(Lessons.all[i + 1])
    }

    /// The trick shot that uses this lesson's idea (it ends the lesson: entering a trick shot ends every other mode).
    var suggestedTrick: TrickShot? { current.flatMap { TrickShots.shot(id: $0.trickID) } }

    func playSuggestedTrick() {
        guard let shot = suggestedTrick else { return }
        model.trickMode.begin(shot)
    }

    /// Leave lesson mode (another mode or free play has been chosen).
    func end() {
        if let before = surfaceBefore { model.setSurface(before) }
        surfaceBefore = nil
        current = nil
        phase = .off
        wantsAiming = false
        keyTime = nil
    }

    /// Called by the table layer whenever the model's playback state changes: moves the Watch beat on, and judges the
    /// player's attempt once it has come to rest.
    func update() {
        guard let lesson = current, model.aimReady else { return }
        switch phase {
        case .watching:
            guard model.timelineVersion == demoVersion else { return }
            phase = .replaying
            model.replay(withLens: true)
        case .replaying:
            // The replay reached its end without stopping (a recording with no such moment): the idea still shows.
            guard model.timelineVersion == demoVersion else { return }
            phase = .keyMoment
        case .aiming(let step), .judged(let step, _), .offScript(let step):
            guard let attempt = model.currentAttempt, model.timelineVersion != judgedVersion,
                  model.timelineVersion != demoVersion else { return }
            judgedVersion = model.timelineVersion
            guard starts(attempt, at: step) else { phase = .offScript(step); return }
            playerSettings = TrickSettings(aim: attempt.aim, power: attempt.power, tipUp: attempt.tipUp,
                                           tipSide: attempt.tipSide, elevation: attempt.elevation)
            let verdict = judge(lesson, step, attempt)
            // The lesson card is the one result card: it carries the retry's one-sentence difference itself, and the
            // general comparison card steps aside while a lesson is up (ComparisonCard).
            phase = .judged(step, verdict)
            requestAiming(false)
            if verdict.made && step == .pass { markDone(lesson) }
            if verdict.made && step == .exercise {
                celebrationMoment = .madeIt
                celebrations += 1
            }
        default:
            break
        }
    }

    /// Called by the table layer as the clock moves: stops the Lens replay exactly on the lesson's moment.
    func tick() {
        guard phase == .replaying, model.timelineVersion == demoVersion, let t = keyTime, model.time >= t else { return }
        model.scrub(to: t)
        phase = .keyMoment
    }

    // MARK: Pieces

    /// Lay out a step's start: the lesson's layout (the exercise's for the exercise) with that step's settings.
    private func start(_ step: Step) {
        guard let lesson = current else { return }
        let exercise = Lessons.stopExercise
        switch step {
        case .try1:
            load(lesson.layout, lesson.reference)
        case .try2:
            // Everything at the reference but the lesson's own control, which starts from neutral so the player has to
            // move it into the band themselves.
            var s = lesson.reference
            switch lesson.control {
            case .tipUp: s.tipUp = 0
            case .tipSide: s.tipSide = 0
            case .power: s.power = 3
            case .elevation: s.elevation = 0
            case .aim: break
            }
            load(lesson.layout, s)
            // A neutral aim is straight at the ball: a full hit, which the cut has to be turned away from.
            if lesson.control == .aim { model.aimAtNearestBall() }
        case .try3, .pass:
            var s = playerSettings ?? lesson.reference
            // A held power is the lesson's own, whatever the last try left. Read from the lesson, not from powerHeld:
            // while start() runs, phase still names the step before.
            if lesson.control != .power { s.power = lesson.reference.power }
            load(lesson.layout, s)
        case .exercise:
            // The lesson's own stroke, copied: aim, power and tip as they were. Only the tip can change.
            load(exercise.layout, TrickSettings(aim: exercise.reference.aim, power: lesson.reference.power,
                                                tipUp: lesson.reference.tipUp, tipSide: 0))
        }
        model.setLens(false)
        phase = .aiming(step)
        requestAiming(true)
    }

    private func load(_ layout: [Vec2], _ s: TrickSettings) {
        model.loadTrickLayout(layout, aim: s.aim, power: s.power, tipUp: s.tipUp, tipSide: s.tipSide,
                              elevation: s.elevation ?? 0)
    }

    /// True when an attempt started from this step's own layout (not from wherever the last shot left the balls).
    private func starts(_ attempt: ShotAttempt, at step: Step) -> Bool {
        guard let lesson = current, !attempt.isBreak else { return false }
        return attempt.start == (step == .exercise ? Lessons.stopExercise.layout : lesson.layout)
    }

    /// Made it, or the one thing to change. A lesson that raises the cue is judged on the cue angle first, because
    /// the trick judge weighs only aim, power and tip: a level stroke at a jump would otherwise be told to aim better.
    private func judge(_ lesson: Lesson, _ step: Step, _ attempt: ShotAttempt) -> TrickVerdict {
        if step == .exercise { return TrickShotJudge.verdict(for: Lessons.stopExercise.trick, attempt: attempt) }
        let verdict = TrickShotJudge.verdict(for: lesson.trick, attempt: attempt)
        guard !verdict.made, let angles = lesson.cueAngles else { return verdict }
        let degrees = asin(min(max(attempt.elevation, 0), 0.995)) * 180 / Double.pi
        if degrees < Double(angles.lowerBound) - 0.5 {
            return TrickVerdict(made: false, line: String(localized: "Raise the cue more. A level cue cannot do this one."))
        }
        if degrees > Double(angles.upperBound) + 0.5 {
            return TrickVerdict(made: false, line: String(localized: "The cue is too steep. Lower it a little."))
        }
        return verdict
    }

    private func markDone(_ lesson: Lesson) {
        let firstPass = !doneIDs.contains(lesson.id)
        if firstPass {
            doneIDs.insert(lesson.id)
            UserDefaults.standard.set(doneIDs.sorted().joined(separator: ","), forKey: Self.doneKey)
        }
        // The big made-it for the sixth lesson, the end of the path, and for the pass that completes all six in
        // whatever order they were taken; the ordinary one for every other pass.
        let completesPath = firstPass && Lessons.all.allSatisfy { doneIDs.contains($0.id) }
        celebrationMoment = (lesson.id == Lessons.all.last?.id || completesPath) ? .madeItBig : .madeIt
        celebrations += 1
    }

    /// The part of a band a control can reach, or nil when none of it can be (then nothing is marked).
    private static func reachable(_ band: ClosedRange<Double>,
                                  within reach: ClosedRange<Double>) -> ClosedRange<Double>? {
        let low = max(band.lowerBound, reach.lowerBound), high = min(band.upperBound, reach.upperBound)
        return low <= high ? low...high : nil
    }

    private func requestAiming(_ open: Bool) {
        wantsAiming = open
        aimingRequests += 1
    }
}
