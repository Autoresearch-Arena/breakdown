// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          stream whatif item 3: the stub filled in. The API the other streams call is unchanged: isOpen, canOpen,
//          isShowing, canKeep, open(), close(), keep().)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif-review: Keep no longer vanishes while Play both runs or
//          after Where they part (canKeep does not read the clock; keep() puts the clock at the shot's end first, as
//          the retry needs); a solve that lands after a cached result is already showing does not show and announce it
//          twice; the click haptic counts clicks, not every change of the steps (a close is not a click); and the
//          clearing raise is worked out only on a sixteen-ball layout, the same guard the model's own raise has.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream what-if, bug 29 of plans/22-Nov-2026-phone-bug-hunt.md:
//          the what-if is not offered while ball in hand is owed or the cue ball is lifted.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 every-world: opening the what-if closes the every-surface fan,
//          so the two other futures never show together.)
// PURPOSE: The what-if replay's state (spec 4.3): one nudged copy of the player's own shot, solved beside the real one
//          on the same start, seed and stroke. The player moves one setting at a time in clicks (aim, power, follow or
//          draw, side, and the cue angle on a raised shot); each click builds the nudged input here on the main actor
//          (it reads the cue pick, the clearing angle and the tip's travel) and solves it on a background task, with
//          TimelineFork reading where the two futures part. The result is the other future as a ShotAttempt, the fork,
//          the retry comparison of the two attempts and, in a trick shot, whether it would have made the shot.
//          It never loads its recording onto the table and never touches the model's solving state, recording, clock
//          duration, layout or attempts; it never judges or marks anything. Keep turns the other future into the next
//          try through the mode's own Try again, then the model's keepFuture, so Shoot with nothing touched plays
//          exactly the future that was shown. The model owns one instance (ShowpieceModel.whatIf) and closes it on
//          every load. Read by WhatIfViews (the button and the card), WhatIfOverlay (the other future on the table),
//          GhostOverlay (the kept future's faint target) and ScrubBar (the parting diamond); layouts calls open and
//          close, and the Mac menu reads canOpen.
// SRP/DRY check: Pass - checked ShowpieceModel (shootNow builds the real strike; this nudges the delivered one through
//          the package's WhatIfInput and ShowpieceModel.solverCopy instead of building a second strike path),
//          ShotAttempt/RetryComparison (reused for the other future and the comparison), TrickShotJudge.passes (the
//          trick verdict), Reach.clearingElevation and CueProfile.choice (the raise and the cue pick, called, not
//          copied) and CueAngleMenu.angles (the elevation steps).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import Observation

/// The what-if replay (spec 4.3): one nudged copy of the player's shot, solved beside the real one. Owned by the model
/// (model.whatIf); never loads its recording onto the table, never touches isSolving, never judges or marks anything.
@MainActor @Observable final class WhatIfFork {
    /// Unowned because the model owns this fork and outlives it; a strong reference would be a retain cycle.
    @ObservationIgnored unowned let model: ShowpieceModel
    init(model: ShowpieceModel) { self.model = model }

    // MARK: Controls and steps

    /// One setting the what-if can move.
    enum Control: CaseIterable, Hashable {
        case aim, power, tipUp, tipSide, elevation

        /// The same setting in the retry comparison's terms.
        var comparison: RetryComparison.Control {
            switch self {
            case .aim: return .aim
            case .power: return .power
            case .tipUp: return .tipUp
            case .tipSide: return .tipSide
            case .elevation: return .elevation
            }
        }

        /// The same setting in a lesson's locks.
        var shotControl: ShotControls {
            switch self {
            case .aim: return .aim
            case .power: return .power
            case .tipUp: return .tipUp
            case .tipSide: return .tipSide
            case .elevation: return .elevation
            }
        }

        init(_ lesson: LessonControl) {
            switch lesson {
            case .aim: self = .aim
            case .power: self = .power
            case .tipUp: self = .tipUp
            case .tipSide: self = .tipSide
            case .elevation: self = .elevation
            }
        }
    }

    /// The card's segmented picker: follow or draw and side share the Spin section.
    enum Section: Hashable, CaseIterable {
        case aim, power, spin, cueAngle

        var controls: [Control] {
            switch self {
            case .aim: return [.aim]
            case .power: return [.power]
            case .spin: return [.tipUp, .tipSide]
            case .cueAngle: return [.elevation]
            }
        }

        init(_ c: Control) {
            switch c {
            case .aim: self = .aim
            case .power: self = .power
            case .tipUp, .tipSide: self = .spin
            case .elevation: self = .cueAngle
            }
        }
    }

    /// How many clicks each setting is moved from the real shot, each within plus or minus maxSteps.
    struct Steps: Hashable {
        var aim = 0, power = 0, tipUp = 0, tipSide = 0, elevation = 0

        subscript(c: Control) -> Int {
            get {
                switch c {
                case .aim: return aim
                case .power: return power
                case .tipUp: return tipUp
                case .tipSide: return tipSide
                case .elevation: return elevation
                }
            }
            set {
                switch c {
                case .aim: aim = newValue
                case .power: power = newValue
                case .tipUp: tipUp = newValue
                case .tipSide: tipSide = newValue
                case .elevation: elevation = newValue
                }
            }
        }

        var isZero: Bool { self == Steps() }
        /// The settings moved, in Control order.
        var nudged: [Control] { Control.allCases.filter { self[$0] != 0 } }
    }

    /// The click sizes, chosen so a single click is always big enough for the retry card to name it
    /// (ShotComparison.isDescribable: aim above 0.15 degrees, power above 4% of its range, tip above 2 mm or a change of
    /// word, cue angle above 0.01 in sine; one step of the offered angles is at least 0.045). Degrees of aim.
    static let aimStep = 0.25
    /// A share of the attempt's power range.
    static let powerShare = 0.05
    /// Metres of tip.
    static let tipStep = 0.0025
    /// The furthest any setting moves, in clicks.
    static let maxSteps = 8
    /// The solver's event budget for the other future: PoolSolver's own limit, so any shot the game could record can be
    /// shown, and a storm the jam guard could not settle is refused rather than spun on.
    static let eventBudget = 10_000

    // MARK: State

    /// The card, the nudge controls and the other future are up.
    private(set) var isOpen = false
    /// The attempt the what-if was opened on, and the recording version it was opened on.
    private(set) var real: ShotAttempt?
    private(set) var openedOn = -1
    private(set) var steps = Steps()
    /// The card's section.
    var section: Section = .aim
    /// The other future for the steps now, once solved (nil before the first click, or when it ran too long).
    private(set) var result: Result?
    /// A solve is in flight; after a short wait the card shows a spinner, and the overlay draws the last result faint.
    private(set) var solving = false
    private(set) var showSpinner = false
    /// The last solve for these steps ran past the event budget: "This version runs too long to show."
    private(set) var tooLong = false
    /// Bumped whenever a result is shown, so the overlay samples it once.
    private(set) var resultVersion = 0
    /// Bumped by each click and by Reset: the card's selection haptic fires on this, so closing the card (which zeroes
    /// the steps) never ticks.
    private(set) var clicks = 0
    /// While Play both runs past the real shot's end, the wall-clock moment the real recording ended: the ghost balls
    /// keep rolling to the other future's own end from there. Cleared by any scrub back, a close or a new result.
    private(set) var tailStart: Date?
    /// A kept future's cue-ball path, drawn faintly as a target until the next try is played (GhostOverlay).
    private(set) var keptPaths: KeptPaths?
    /// The clock has moved since the what-if opened. Until it does, the clock sits at the real shot's end and the
    /// other future is shown at its own end (where its balls stopped); once it moves, the ghosts follow the clock.
    /// Read each frame by the overlay, which redraws every frame anyway, so it is not observed.
    @ObservationIgnored private(set) var clockHasMoved = false

    struct KeptPaths: Equatable {
        let cue: [Vec2]
        /// The ghost the kept retry was armed with; another ghost means another try, and the target goes.
        let ghostVersion: Int
    }

    struct Result {
        let steps: Steps
        let alternate: ShotAttempt
        let fork: TimelineFork
        /// The real attempt against the other future, as the retry card would compare them.
        let comparison: RetryComparison
        /// In a trick shot: whether the other future makes the shot, and whether the real one did.
        let passes: Bool?
        let realPasses: Bool?
        /// The ball the other future's cue had to rise to clear, when it rose for it and the real cue did not.
        let raisedOver: Int?
    }

    private enum Outcome {
        case solved(Result)
        case tooLong
    }

    /// The session: bumped by open and close, so a solve that lands after either is dropped.
    @ObservationIgnored private var token = 0
    /// Bumped by every solve started, so a spinner timer only ever shows for its own solve.
    @ObservationIgnored private var solveSerial = 0
    /// The last few solved steps, newest last, so stepping back to a setting shows it at once.
    @ObservationIgnored private var cache: [(steps: Steps, outcome: Outcome)] = []
    private static let cacheSize = 8

    // MARK: The fixed API

    /// The entry may be offered now (the button and the Mac menu item read it): the balls are at rest after the
    /// player's own shot, in free play or a judged try at a trick shot, lesson or Behind the 8-Ball situation. Never on
    /// a break, in a match, in the first minute, while solving, during Watch your best shot, in the stroke drill, with
    /// the menu open, or while ball in hand is owed or the cue ball is lifted (0.7.6, bug 29): opening the what-if
    /// closes Your shot, which carries the lifted ball's drag, so the ball could not be put down again, and the Ball in
    /// hand card would stack under the what-if card.
    var canOpen: Bool {
        guard let a = model.currentAttempt, model.playerShotOnScreen, !a.isBreak, model.match == nil, model.aimReady,
              model.stage == .explore, model.openingStage == .none, !model.replayingBest,
              !model.strokeDrill.isActive, !model.menuOpen,
              !model.placingCueBall, model.ballInHand == .none else { return false }
        // In a learn mode only the judged try: never while its answer plays (then the answer is the attempt on screen).
        if model.trickMode.isActive { guard case .judged = model.trickMode.phase else { return false } }
        if model.lessonMode.isActive { guard case .judged = model.lessonMode.phase else { return false } }
        if model.eightBallMode.isActive { guard case .scored = model.eightBallMode.phase else { return false } }
        return true
    }

    /// Open and still about the recording it was opened on. Every result card steps aside while this is true.
    var isShowing: Bool { isOpen && model.timelineVersion == openedOn }

    /// "Keep this one" may be offered: a solved other future for the steps now, and a mode that can retry from the
    /// real attempt's start with those settings. The clock is not read here (model.canTryAgain needs the shot played
    /// out): Play both and Where they part move it, and Keep must not drop out of the card while they do. keep() puts
    /// the clock back at the end before it retries.
    var canKeep: Bool {
        guard isShowing, let real, let r = result, r.steps == steps, !steps.isZero, model.currentAttempt != nil,
              model.match == nil, !model.isSolving, !model.menuOpen else { return false }
        if model.trickMode.isActive { return model.trickMode.startsAtTrick(real) }
        if model.lessonMode.isActive {
            // Never in try 1 (everything is locked to the lesson's stroke); afterwards only settings the step leaves
            // open, and never the power while the lesson holds it.
            guard let step = model.lessonMode.step, step != .try1 else { return false }
            let open = model.lessonMode.openControls
            if model.lessonMode.powerHeld && steps.power != 0 { return false }
            return steps.nudged.allSatisfy { open.contains($0.shotControl) }
        }
        if model.eightBallMode.isActive {
            guard let s = model.eightBallMode.current else { return false }
            return !real.isBreak && real.start == s.setup
        }
        return true
    }

    func open() {
        guard canOpen, let a = model.currentAttempt else { return }
        model.requestShotPanel(.close)
        // 0.7.7 every-world: the fan and the what-if share the card slot and the bottom bar's panel.
        model.everyWorldIfMade?.close()
        token += 1
        cache = []
        real = a
        openedOn = model.timelineVersion
        steps = Steps()
        result = nil; tooLong = false; solving = false; showSpinner = false; tailStart = nil; keptPaths = nil
        clockHasMoved = false
        // A lesson opens on its own setting; everything else on the aim.
        let lessonSection = model.lessonMode.current.map { Section(Control($0.control)) }
        section = lessonSection.flatMap { sections.contains($0) ? $0 : nil } ?? sections.first ?? .aim
        isOpen = true
    }

    func close() {
        // Called by every load; nothing to do when nothing is up or in flight.
        guard isOpen || solving || real != nil else { return }
        token += 1
        isOpen = false
        real = nil
        openedOn = -1
        steps = Steps()
        result = nil; tooLong = false; solving = false; showSpinner = false; tailStart = nil
        cache = []
    }

    /// Keep the other future as the next try: through the mode's own Try again (so the ghost, the comparison and the
    /// mode's phase are exactly a retry's), then, only when that retry was armed from the real attempt, the future's
    /// settings and its exact strike (ShowpieceModel.keepFuture).
    func keep() {
        guard canKeep, let real, let alternate = result?.alternate else { return }
        close()
        // Every mode's retry needs the shot played out (model.aimReady); Play both or Where they part may have left the
        // clock part way. Nothing loads while the card is up, so the stage is still explore and nothing is solving.
        if model.time < model.duration - 1e-6 { model.scrub(to: model.duration) }
        if model.trickMode.isActive {
            model.trickMode.tryAgain()
        } else if model.lessonMode.isActive {
            model.lessonMode.tryAgain()
        } else if model.eightBallMode.isActive {
            model.eightBallMode.tryAgain()
        } else {
            model.tryAgain()
            model.requestShotPanel(.open)
        }
        // The ghost is the real attempt only when the mode really retried it (a mode may lay its start out afresh).
        guard model.ghost?.motionHash == real.motionHash else { return }
        model.keepFuture(TrickSettings(aim: alternate.aim, power: alternate.power, tipUp: alternate.tipUp,
                                       tipSide: alternate.tipSide,
                                       elevation: alternate.elevation > 0 ? alternate.elevation : nil),
                         input: alternate.input, delivery: alternate.stroke)
        keptPaths = KeptPaths(cue: alternate.ghostPaths().cue, ghostVersion: model.ghostVersion)
    }

    // MARK: Nudging

    /// The card's sections: in a lesson only the settings the step leaves open (try 1, where none is, shows the
    /// lesson's own setting with no Keep); otherwise aim, power, spin, and the cue angle on a raised shot.
    var sections: [Section] {
        guard let real else { return [] }
        if model.lessonMode.isActive, let lesson = model.lessonMode.current {
            let open = model.lessonMode.openControls
            var controls = Control.allCases.filter { open.contains($0.shotControl) }
            if controls.isEmpty { controls = [Control(lesson.control)] }
            if real.elevation <= 0 { controls.removeAll { $0 == .elevation } }
            var out: [Section] = []
            for c in controls where !out.contains(Section(c)) { out.append(Section(c)) }
            return out
        }
        return real.elevation > 0 ? [.aim, .power, .spin, .cueAngle] : [.aim, .power, .spin]
    }

    /// The settings a section's rows move (in a lesson, only the open ones of Spin's two).
    func controls(in section: Section) -> [Control] {
        guard model.lessonMode.isActive, let lesson = model.lessonMode.current else { return section.controls }
        let open = model.lessonMode.openControls
        let shown = section.controls.filter { open.contains($0.shotControl) }
        return shown.isEmpty ? section.controls.filter { $0 == Control(lesson.control) } : shown
    }

    /// Whether one click of `delta` on `control` may be taken: within the furthest click, a real change of the setting
    /// (the tip's travel and the power range clamp), and a change from the real shot big enough to name (or back to it).
    func canStep(_ control: Control, by delta: Int) -> Bool {
        guard isShowing, let real else { return false }
        var next = steps
        next[control] += delta
        guard abs(next[control]) <= Self.maxSteps else { return false }
        let now = Self.value(control, real: real, steps: steps, tipLimit: model.tipLimit)
        let then = Self.value(control, real: real, steps: next, tipLimit: model.tipLimit)
        guard now != then else { return false }
        if next[control] == 0 { return true }
        let change = RetryComparison.InputChange(control: control.comparison, before: real.value(of: control.comparison),
                                                 after: then)
        return ShotComparison.isDescribable(change, in: real)
    }

    /// One click on a setting; the other future is solved again (or shown from the cache at once).
    func nudge(_ control: Control, by delta: Int) {
        guard canStep(control, by: delta) else { return }
        steps[control] += delta
        clicks += 1
        resolve()
    }

    /// Every setting back to the real shot.
    func reset() {
        guard isShowing, !steps.isZero else { return }
        steps = Steps()
        clicks += 1
        resolve()
    }

    /// The setting a control has in the other future now.
    func value(_ control: Control) -> Double? {
        guard let real else { return nil }
        return Self.value(control, real: real, steps: steps, tipLimit: model.tipLimit)
    }

    // MARK: Playback

    /// Play both: the real shot from the start, the other future's ghosts rolling beside it.
    func playBoth() {
        guard isShowing else { return }
        tailStart = nil
        model.scrub(to: 0)
        if !model.playing { model.togglePlay() }
    }

    /// Where they part: the replay stops at the marker.
    func jumpToParting() {
        guard isShowing, let m = result?.fork.marker else { return }
        tailStart = nil
        model.scrub(to: m.time)
    }

    /// Told by the overlay whenever the clock moves: a step back (a scrub or a replay) ends the tail; the real clock
    /// reaching its end starts it, so a longer other future rolls on to its own end (a shorter one is already there:
    /// the overlay caps the tail clock at the other future's duration).
    func clockMoved(from old: Double, to new: Double) {
        guard isShowing else { return }
        if !clockHasMoved { clockHasMoved = true }
        if new < old - 1e-9 { if tailStart != nil { tailStart = nil }; return }
        let end = model.duration - 1e-6
        if old < end, new >= end, result != nil, tailStart == nil { tailStart = Date() }
    }

    // MARK: Solving

    private func resolve() {
        tailStart = nil
        guard real != nil else { return }
        if steps.isZero { result = nil; tooLong = false; return }
        if let o = cached(steps) { show(o); return }
        // One solve in flight: the newest steps wait and are started when it lands.
        if solving { return }
        start(steps)
    }

    private func start(_ s: Steps) {
        guard let real else { return }
        let built = Self.build(real: real, steps: s, authored: model.authoredModeUp, tipLimit: model.tipLimit)
        // On the attempt's own table, cloth and physics generation, never the live ones, and nothing is committed.
        let solvable = ShowpieceModel.solverCopy(built.input, table: real.table, surface: real.surface,
                                                 generation: real.generation)
        let realTimeline = real.timeline, layout = real.start, cue = real.cueBall
        let radius = real.timeline.table.ballRadius
        let session = token, budget = Self.eventBudget
        solveSerial += 1
        let serial = solveSerial
        solving = true
        showSpinner = false
        // Only the solve and the fork leave the main actor; both are pure functions of Sendable values.
        Task { [weak self] in
            let out = await Task.detached(priority: .userInitiated) {
                PoolSolver.simulate(solvable, eventBudget: budget).map {
                    ($0, TimelineFork.find(real: realTimeline, alternate: $0, start: layout, cueBall: cue,
                                           ballRadius: radius))
                }
            }.value
            self?.landed(out, session: session, steps: s, built: built)
        }
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard let self, self.solving, self.solveSerial == serial, self.token == session else { return }
            self.showSpinner = true
        }
    }

    private func landed(_ out: (Timeline, TimelineFork)?, session: Int, steps s: Steps, built: Built) {
        // A stale session (closed, or opened on another attempt) is dropped whole.
        guard session == token, let real else { return }
        solving = false
        showSpinner = false
        let outcome: Outcome
        if case let (tl, fork)? = out {
            let alternate = Self.alternateAttempt(real: real, built: built, timeline: tl)
            var passes: Bool?, realPasses: Bool?
            if model.trickMode.isActive, let shot = model.trickMode.current {
                passes = TrickShotJudge.passes(shot.goal, alternate)
                realPasses = TrickShotJudge.passes(shot.goal, real)
            }
            outcome = .solved(Result(steps: s, alternate: alternate, fork: fork,
                                     comparison: RetryComparison.between(real, alternate), passes: passes,
                                     realPasses: realPasses, raisedOver: built.raisedOver))
        } else {
            outcome = .tooLong
        }
        remember(outcome, for: s)
        if s == steps {
            show(outcome)
        } else if steps.isZero {
            result = nil; tooLong = false
        } else if cached(steps) != nil {
            // Nothing to do: with one solve in flight, steps that are cached now were cached when the player moved to
            // them, so resolve() showed (and announced) that result already; showing it again would say it twice.
        } else {
            start(steps)
        }
    }

    private func show(_ o: Outcome) {
        tailStart = nil
        switch o {
        case .solved(let r):
            result = r
            tooLong = false
            resultVersion += 1
            if let real { ShotNarration.announce(WhatIfWords.outcome(r, real: real)) }
        case .tooLong:
            result = nil
            tooLong = true
            resultVersion += 1
            ShotNarration.announce(WhatIfWords.tooLong)
        }
    }

    private func cached(_ s: Steps) -> Outcome? { cache.last { $0.steps == s }?.outcome }

    private func remember(_ o: Outcome, for s: Steps) {
        cache.removeAll { $0.steps == s }
        cache.append((s, o))
        if cache.count > Self.cacheSize { cache.removeFirst(cache.count - Self.cacheSize) }
    }

    // MARK: Building the other future's input (pure, so the tests call it directly)

    /// The nudged settings (aim in degrees, power, tips, the chosen cue angle as a sine), the effective input the
    /// solver gets (the real delivered input with the nudge applied), and the ball the cue had to rise to clear.
    struct Built {
        let settings: TrickSettings
        let input: ShotInput
        let raisedOver: Int?
    }

    /// A setting's value after `steps` clicks: exactly the real one at zero clicks (never re-derived, so a zero nudge
    /// is bit for bit the real shot). Power stays in the attempt's range, the tips in the tip's travel, and the cue
    /// angle moves one offered angle per click from the real angle's nearest.
    static func value(_ c: Control, real: ShotAttempt, steps: Steps, tipLimit: Double) -> Double {
        let n = steps[c]
        guard n != 0 else { return real.value(of: c.comparison) }
        switch c {
        case .aim:
            return real.aim + Double(n) * aimStep
        case .power:
            let range = real.powerRange
            let p = real.power + Double(n) * powerShare * (range.upperBound - range.lowerBound)
            return min(max(p, range.lowerBound), range.upperBound)
        case .tipUp:
            return min(max(real.tipUp + Double(n) * tipStep, -tipLimit), tipLimit)
        case .tipSide:
            return min(max(real.tipSide + Double(n) * tipStep, -tipLimit), tipLimit)
        case .elevation:
            let angles = CueAngleMenu.angles
            let here = angles.firstIndex(of: CueAngleMenu.nearestAngle(toSine: real.elevation)) ?? 0
            let i = min(max(here + n, 0), angles.count - 1)
            return CueAngleMenu.sine(forAngle: angles[i])
        }
    }

    /// The other future's input. The cue for the real and the nudged settings comes from the same rule the model
    /// uses (the house cue in the authored modes), and the speed is scaled by the ratio of their launch speeds, so a
    /// power click or a change of cue moves the launch exactly as the controls would. Outside the authored modes the
    /// cue angle is the chosen angle raised to clear any ball under the cue, as the model raises the real strike; it
    /// is only worked out again when the aim, the angle or the cue changed, so every other nudge keeps the real
    /// strike's angle bit for bit.
    static func build(real: ShotAttempt, steps s: Steps, authored: Bool, tipLimit: Double) -> Built {
        let aim = value(.aim, real: real, steps: s, tipLimit: tipLimit)
        let power = value(.power, real: real, steps: s, tipLimit: tipLimit)
        let up = value(.tipUp, real: real, steps: s, tipLimit: tipLimit)
        let side = value(.tipSide, real: real, steps: s, tipLimit: tipLimit)
        let angle = value(.elevation, real: real, steps: s, tipLimit: tipLimit)
        let settings = TrickSettings(aim: aim, power: power, tipUp: up, tipSide: side, elevation: angle > 0 ? angle : nil)
        guard !s.isZero else { return Built(settings: settings, input: real.input, raisedOver: nil) }

        // Trig lives here in the app: the package turns the delivered direction by this unit vector.
        let turnRadians = Double(s.aim) * aimStep * Double.pi / 180
        let turn = s.aim == 0 ? Vec2(1, 0) : Vec2(cos(turnRadians), sin(turnRadians))

        let oldCue = authored ? CueChoice.standard
            : CueProfile.choice(isBreak: false, elevation: real.elevation, tipUp: real.tipUp, tipSide: real.tipSide)
        let newCue = authored ? CueChoice.standard
            : CueProfile.choice(isBreak: false, elevation: angle, tipUp: up, tipSide: side)
        let oldProfile = CueProfile.profile(for: oldCue.kind), newProfile = CueProfile.profile(for: newCue.kind)
        var scale = 1.0
        if s.power != 0 || oldCue.kind != newCue.kind {
            let before = oldProfile.launchSpeed(forPower: real.power)
            if before > 0 { scale = newProfile.launchSpeed(forPower: power) / before }
        }

        var elevation: Double?
        var raisedOver: Int?
        if authored {
            if s.elevation != 0 { elevation = angle }
        } else if s.aim != 0 || s.elevation != 0 || oldCue.kind != newCue.kind {
            let a = aim * Double.pi / 180
            let direction = Vec2(cos(a), sin(a))
            let support = real.stroke?.bridge ?? StrokeModel.automaticBridge
            // The model raises the cue only on a sixteen-ball layout with the struck ball on the table
            // (ShowpieceModel.clearingElevation); the other tables' layouts are struck at the chosen angle, and so is
            // their other future.
            let raisable = real.start.count == 16 && real.start.indices.contains(real.cueBall)
                && NextShot.isOnTable(real.start[real.cueBall])
            let clearing = raisable
                ? Reach.clearingElevation(layout: real.start, cueBall: real.cueBall, aim: direction,
                                          table: real.timeline.table, support: support, cueLength: newProfile.length)
                : 0
            elevation = max(angle, clearing)
            // Named only when the raise is new to this version: the cue rose above the chosen angle, and above what
            // the real strike was struck at by a clear margin (the comparison's own 0.01 in sine).
            if clearing > angle, clearing > real.input.strike.elevation + 0.01 {
                raisedOver = blocker(real: real, aim: direction, support: support, cueLength: newProfile.length)
            }
        }

        let nudge = ShotNudge(turn: turn, speedScale: scale, tipUp: up - real.tipUp, tipSide: side - real.tipSide,
                              elevation: elevation)
        let input = WhatIfInput.alternate(of: real.input, nudge, ballRadius: real.timeline.table.ballRadius)
        return Built(settings: settings, input: input, raisedOver: raisedOver)
    }

    /// The other future as an attempt: the real one's start, seed, surface, table, generation and stroke, with the
    /// nudged settings, the nudged input and the other recording.
    static func alternateAttempt(real: ShotAttempt, built: Built, timeline tl: Timeline) -> ShotAttempt {
        ShotAttempt(isBreak: false, breakSeed: real.breakSeed, start: real.start, timeline: tl,
                    aim: built.settings.aim, power: built.settings.power, powerRange: real.powerRange,
                    tipUp: built.settings.tipUp, tipSide: built.settings.tipSide,
                    elevation: built.settings.elevation ?? 0, seed: real.seed, input: built.input,
                    surface: real.surface, table: real.table, generation: real.generation, stroke: real.stroke)
    }

    /// The ball that sets the clearing angle: each ball is asked alone (every other ball lifted off), through the same
    /// Reach.clearingElevation, and the one needing the steepest cue is the one the cue rose to clear.
    static func blocker(real: ShotAttempt, aim: Vec2, support: Double, cueLength: Double) -> Int? {
        var best: (ball: Int, sine: Double)?
        for b in real.start.indices where b != real.cueBall && NextShot.isOnTable(real.start[b]) {
            var alone = [Vec2](repeating: NextShot.offTable, count: real.start.count)
            alone[real.cueBall] = real.start[real.cueBall]
            alone[b] = real.start[b]
            let sine = Reach.clearingElevation(layout: alone, cueBall: real.cueBall, aim: aim,
                                               table: real.timeline.table, support: support, cueLength: cueLength)
            if sine > 0, sine > (best?.sine ?? 0) { best = (b, sine) }
        }
        return best?.ball
    }
}
