// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: The state of "Same shot, every surface" (0.7.7, plans/23-Nov-2026-every-world-plan.md Build step 3). After
//          the player's own shot has come to rest, open() plays that exact stroke again on the nine other playing
//          surfaces at once: the attempt's own input (its start, seed and stroke drift), table and physics generation,
//          with only the surface changed (ShowpieceModel.solverCopy), each solved in its own child task of one task
//          group so the solves use every core. Each surface lands on the main actor as soon as it is solved (the fan
//          grows surface by surface); there it becomes a World: the attempt on that surface, where its futures part
//          from the real one (TimelineFork), what it did (WorldOutcome), the struck ball's thinned path for the overlay,
//          and in a trick shot whether it makes the shot. When all nine have landed the headline is worked out (the
//          trick line first when the real try missed and a surface makes it, then WorldContrast.headline) and spoken.
//          The player may pick one surface (its balls roll as ghosts), step through them (the controller), replay with
//          every ghost rolling (playAll, with the what-if's tail clock), and in free play switch the game to the picked
//          surface (switchToPicked, through ShowpieceModel.setSurface, which solves exactly the line that was drawn).
//          It never loads a recording, never touches the model's clock duration, layout, attempts or solving state,
//          never judges or marks anything, and makes no sound. The model owns one instance (ShowpieceModel.everyWorld)
//          and closes it (and drops its kept result) on every load. Read by EveryWorldOverlay (the paths on the table),
//          EveryWorldViews (the menu item, chips, card, panel and blurb), ControllerInput (the d-pad, A and B while it
//          shows) and the Mac's Playback menu.
// SRP/DRY check: Pass - mirrors WhatIfFork (its gate is read, not copied: canOpen is model.whatIf.canOpen; its event
//          budget, stale-drop token, 150 ms spinner and tail clock are the same rules) and reuses ShotAttempt.resolved
//          and path(of:), ShowpieceModel.solverCopy and setSurface, TimelineFork.find, TrickShotJudge.passes and the
//          package's WorldOutcome and WorldContrast. Nothing else solves one stroke on several surfaces.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import Observation

/// Same shot, every surface: one stroke solved on all ten playing surfaces. Owned by the model (model.everyWorld).
@MainActor @Observable final class EveryWorldFan {
    /// Unowned because the model owns this fan and outlives it; a strong reference would be a retain cycle.
    @ObservationIgnored unowned let model: ShowpieceModel
    init(model: ShowpieceModel) { self.model = model }

    // MARK: Types

    /// One other surface, solved.
    struct World {
        let surface: PlaySurface
        /// The real attempt with this surface's recording (ShotAttempt.resolved), so its paths and judge read as any
        /// attempt's do.
        let attempt: ShotAttempt
        /// Where this surface's future parts from the real one, and which balls' futures changed.
        let fork: TimelineFork
        /// What this recording did, for the sentence.
        let outcome: WorldOutcome
        /// The struck ball's path, sampled once and thinned (thin(_:)), so the overlay only projects it each frame.
        let cuePath: [Vec2]
        /// In a trick shot, whether this surface makes the shot; nil elsewhere.
        let trickPasses: Bool?
    }

    enum Slot {
        case solving
        case solved(World)
        /// Its solve ran past the event budget: the chip says so and the sentence leaves it out.
        case tooLong
    }

    /// What the fan's sentence says about its surface.
    enum Headline: Equatable {
        /// Trick shots only: the real try missed and this surface makes the shot.
        case trickMade
        case world(WorldContrast)
    }

    /// The surface the fan's sentence is about, and what it says (the plan's tuple, as an Equatable struct so the
    /// views can watch it).
    struct Lead: Equatable {
        let surface: PlaySurface
        let contrast: Headline
    }

    /// One surface's solve, handed back from its child task. Sendable values only: the attempt is built on the main
    /// actor in landed(_:session:).
    struct Landing: Sendable {
        let surface: PlaySurface
        /// Nil when the solve ran past the event budget.
        let timeline: Timeline?
        let fork: TimelineFork?
        let outcome: WorldOutcome?
    }

    // MARK: State

    private(set) var isOpen = false
    /// The attempt the fan was opened on, and the recording version it was opened on.
    private(set) var real: ShotAttempt?
    private(set) var openedOn = -1
    /// The surface the shot was played on ("Played here"): its recording is the attempt's own, never solved again.
    private(set) var home: PlaySurface?
    /// What the shot as played did, for the sentences (read once per session).
    private(set) var homeOutcome: WorldOutcome?
    /// Every other surface's state.
    private(set) var slots: [PlaySurface: Slot] = [:]
    /// The surface drawn alone (nil: the whole fan).
    private(set) var picked: PlaySurface?
    /// The fan's sentence, once every surface has landed.
    private(set) var headline: Lead?
    /// In a trick shot, the real try missed (read once per session from the judge), so the trick line may be said of a
    /// surface that makes the shot.
    private(set) var realMissedTrick = false
    /// Shown only when nothing has landed after 150 ms, as the what-if's spinner.
    private(set) var showSpinner = false
    /// Bumped per landing (and when a kept result is shown): the overlay samples again on it.
    private(set) var landings = 0
    /// Bumped per pick: the views' selection haptic fires on it.
    private(set) var picks = 0
    /// While Watch them roll runs past the real shot's end, the wall-clock moment the real recording ended: the ghosts
    /// keep rolling to their own ends from there. Cleared by any scrub back, a close or a new session.
    private(set) var tailStart: Date?
    /// The clock has moved since the fan opened. Until it does, every ghost sits where its ball stopped. Read each
    /// frame by the overlay, which redraws every frame anyway, so it is not observed.
    @ObservationIgnored private(set) var clockHasMoved = false

    /// The session: bumped by every start and close, so a landing from an older session is dropped whole.
    @ObservationIgnored private var token = 0
    /// The running task group, cancelled on close (a solve already running still finishes and is discarded: the solver
    /// does not check for cancellation).
    @ObservationIgnored private var task: Task<Void, Never>?
    /// The last complete result and the recording it was made on: closing and reopening on the same shot is instant.
    @ObservationIgnored private var cache: Cache?

    private struct Cache {
        let version: Int
        let real: ShotAttempt
        let home: PlaySurface
        let homeOutcome: WorldOutcome
        let slots: [PlaySurface: Slot]
        let headline: Lead?
        let realMissedTrick: Bool
    }

    // MARK: Gate

    /// The fan may be offered now. The what-if's gate exactly, read rather than copied: both ask the same question
    /// ("is the player's own shot on screen, at rest, outside a break, a match, the first minute, a solve, Watch your
    /// best shot, the stroke drill, the menu, and ball in hand, and in a learn mode only its judged try?"), so one rule
    /// keeps the two entries offered together and a change to it reaches both.
    var canOpen: Bool { model.whatIf.canOpen }

    /// Open and still about the recording it was opened on.
    var isShowing: Bool { isOpen && model.timelineVersion == openedOn }

    /// Every surface but home, in the Surface menu's order.
    var others: [PlaySurface] { PlaySurface.allCases.filter { $0 != home } }

    /// Some surface is still being solved.
    var solving: Bool {
        slots.values.contains { if case .solving = $0 { return true } else { return false } }
    }

    /// A surface's World, when it is solved.
    func world(_ s: PlaySurface) -> World? {
        if case .solved(let w)? = slots[s] { return w }
        return nil
    }

    /// The surface the sentence and the blurb are about: the picked one, else the headline's.
    var shownSurface: PlaySurface? { picked ?? headline?.surface }

    // MARK: Open and close

    func open() {
        guard canOpen, let a = model.currentAttempt else { return }
        // Your shot and the what-if share the places the fan takes (the card slot, the bottom bar's panel).
        model.requestShotPanel(.close)
        model.whatIf.close()
        picked = nil
        tailStart = nil
        clockHasMoved = false
        // Set before any solve starts, so a landing always finds the version it belongs to.
        openedOn = model.timelineVersion
        isOpen = true
        if let c = cache, c.version == model.timelineVersion {
            // The same recording: the kept result at once. Any session still in flight is dropped.
            token += 1
            task?.cancel()
            real = c.real; home = c.home; homeOutcome = c.homeOutcome; slots = c.slots; headline = c.headline
            realMissedTrick = c.realMissedTrick
            showSpinner = false
            landings += 1
            if let line = fanSentence { ShotNarration.announce(line) }
        } else {
            start(a)
        }
    }

    func close() {
        // Called by every load; nothing to do when nothing is up or in flight.
        guard isOpen || real != nil || task != nil else { return }
        token += 1
        task?.cancel()
        task = nil
        isOpen = false
        real = nil
        openedOn = -1
        home = nil; homeOutcome = nil; realMissedTrick = false
        slots = [:]
        picked = nil; headline = nil; showSpinner = false; tailStart = nil
    }

    /// Forget the kept result (ShowpieceModel.load calls it with close): a new recording never shows an old fan.
    func dropCache() { cache = nil }

    // MARK: Solving

    private func start(_ a: ShotAttempt) {
        token += 1
        task?.cancel()
        let session = token
        real = a
        home = a.surface
        homeOutcome = WorldOutcome(timeline: a.timeline, start: a.start, cueBall: a.cueBall)
        if model.trickMode.isActive, let shot = model.trickMode.current {
            realMissedTrick = !TrickShotJudge.passes(shot.goal, a)
        } else {
            realMissedTrick = false
        }
        headline = nil
        showSpinner = false
        let jobs = others
        slots = Dictionary(uniqueKeysWithValues: jobs.map { ($0, Slot.solving) })
        // Captured as Sendable values: the child tasks never touch the fan or the model.
        let input = a.input, table = a.table, generation = a.generation, layout = a.start, cue = a.cueBall
        let homeTimeline = a.timeline, radius = a.timeline.table.ballRadius, budget = WhatIfFork.eventBudget
        // The outer task inherits the main actor, and so does the task group's body (withTaskGroup runs its body on
        // the caller's isolation), so each landing is handed straight to landed(_:session:) here. The child tasks'
        // closures capture no actor-isolated state, so they run concurrently off the main actor, one per surface.
        task = Task(priority: .userInitiated) { [weak self] in
            await withTaskGroup(of: Landing.self) { group in
                for s in jobs {
                    group.addTask(priority: .userInitiated) {
                        EveryWorldFan.solveOne(input: input, table: table, surface: s, generation: generation,
                                               start: layout, cueBall: cue, home: homeTimeline, radius: radius,
                                               budget: budget)
                    }
                }
                for await landing in group {
                    // Already on the main actor (see above); the await only keeps this compiling should a toolchain
                    // not carry the caller's isolation into the group's body, and costs nothing when it does.
                    await self?.landed(landing, session: session)
                }
            }
        }
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard let self, self.token == session, self.isOpen else { return }
            // Nothing has landed yet: every surface is still solving.
            if self.slots.values.allSatisfy({ if case .solving = $0 { return true } else { return false } }) {
                self.showSpinner = true
            }
        }
    }

    /// One surface's solve and its readings, pure (the tests call it): the attempt's input on its own table and
    /// generation with this surface's numbers, solved under the what-if's event budget, then where it parts from the
    /// real recording and what it did. Nil readings when the solve ran past the budget.
    nonisolated static func solveOne(input: ShotInput, table: TableKind, surface: PlaySurface, generation: Int,
                                     start: [Vec2], cueBall: Int, home: Timeline, radius: Double,
                                     budget: Int) -> Landing {
        let solvable = ShowpieceModel.solverCopy(input, table: table, surface: surface, generation: generation)
        guard let tl = PoolSolver.simulate(solvable, eventBudget: budget) else {
            return Landing(surface: surface, timeline: nil, fork: nil, outcome: nil)
        }
        let fork = TimelineFork.find(real: home, alternate: tl, start: start, cueBall: cueBall, ballRadius: radius)
        return Landing(surface: surface, timeline: tl, fork: fork,
                       outcome: WorldOutcome(timeline: tl, start: start, cueBall: cueBall))
    }

    private func landed(_ l: Landing, session: Int) {
        // A stale session (closed, or opened again on another attempt) is dropped whole.
        guard session == token, let real else { return }
        if let tl = l.timeline, let fork = l.fork, let outcome = l.outcome {
            let attempt = real.resolved(on: tl, surface: l.surface)
            var passes: Bool?
            if model.trickMode.isActive, let shot = model.trickMode.current {
                passes = TrickShotJudge.passes(shot.goal, attempt)
            }
            slots[l.surface] = .solved(World(surface: l.surface, attempt: attempt, fork: fork, outcome: outcome,
                                             cuePath: Self.thin(attempt.path(of: attempt.cueBall)),
                                             trickPasses: passes))
        } else {
            slots[l.surface] = .tooLong
        }
        landings += 1
        if !solving { finish(real) }
    }

    /// Every surface has landed: the headline, the kept result, and the one spoken line.
    private func finish(_ real: ShotAttempt) {
        showSpinner = false
        task = nil
        var lead: Lead?
        // Trick shots first: the real try missed and another surface makes it (the first in menu order).
        if realMissedTrick, let s = others.first(where: { world($0)?.trickPasses == true }) {
            lead = Lead(surface: s, contrast: .trickMade)
        }
        if lead == nil, let homeOutcome {
            let list = others
            if let h = WorldContrast.headline(home: homeOutcome, worlds: list.map { world($0)?.outcome }) {
                lead = Lead(surface: list[h.index], contrast: .world(h.contrast))
            }
        }
        headline = lead
        if let home, let homeOutcome {
            cache = Cache(version: openedOn, real: real, home: home, homeOutcome: homeOutcome, slots: slots,
                          headline: lead, realMissedTrick: realMissedTrick)
        }
        if let line = fanSentence { ShotNarration.announce(line) }
    }

    /// Keeps the first point, every point at least `minStep` metres (5 mm) from the last one kept, and always the last
    /// point. A Moon or ice path sampled sixty times a second can hold thousands of points, and nine of them are
    /// projected every frame; 5 mm is under a pixel at whole-table framing on any screen. Pure (tested).
    nonisolated static func thin(_ points: [Vec2], minStep: Double = 0.005) -> [Vec2] {
        guard points.count > 2 else { return points }
        let step2 = minStep * minStep
        var out: [Vec2] = [points[0]]
        out.reserveCapacity(points.count / 4 + 2)
        for p in points.dropFirst().dropLast() where (p - out[out.count - 1]).lengthSquared >= step2 {
            out.append(p)
        }
        out.append(points[points.count - 1])
        return out
    }

    // MARK: Picking

    /// Draw one surface alone, or (nil, or home) the whole fan again. A surface still solving or too long to show is
    /// ignored. Says the shown sentence.
    func pick(_ s: PlaySurface?) {
        guard isShowing else { return }
        var next: PlaySurface?
        if let s, s != home {
            guard world(s) != nil else { return }
            next = s
        }
        guard next != picked else { return }
        picked = next
        picks += 1
        ShotNarration.announce(shownSentence)
    }

    /// The controller's left and right: the previous or next solved surface, wrapping through "all".
    func step(by delta: Int) {
        guard isShowing else { return }
        let order: [PlaySurface?] = [nil] + others.filter { world($0) != nil }.map { Optional($0) }
        guard order.count > 1 else { return }
        let here = order.firstIndex { $0 == picked } ?? 0
        let n = order.count
        pick(order[((here + delta) % n + n) % n])
    }

    // MARK: Play on

    /// "Play on" may be offered: the fan shows, a solved surface other than home is picked, in free play only (the
    /// learn modes are set and judged on their own surface, and a switch would leave a verdict about another surface
    /// on screen; a match's shot belongs to the rules), nothing solving, the menu closed, and the switch would solve
    /// exactly what was drawn. setSurface solves the shot on screen through prepare, with the LIVE table and physics
    /// generation, and does nothing when the surface asked for is the stored choice; so the attempt's table and
    /// generation must still be the live ones and its surface the stored one, or "Play on" would play another line.
    var canSwitch: Bool {
        guard isShowing, let real, let p = picked, p != home, world(p) != nil,
              !model.trickMode.isActive, !model.lessonMode.isActive, !model.eightBallMode.isActive,
              model.match == nil, !model.isSolving, !model.menuOpen else { return false }
        return real.table == model.physicsTable && real.generation == model.activeModelGeneration
            && real.surface == model.surface
    }

    /// Switch the game to the picked surface and play the shot on it (setSurface's load closes the fan).
    func switchToPicked() {
        guard canSwitch, let p = picked else { return }
        model.setSurface(p)
    }

    // MARK: Playback

    /// Watch them roll: the real shot from the start, every shown surface's ghosts rolling beside it.
    func playAll() {
        guard isShowing else { return }
        tailStart = nil
        model.scrub(to: 0)
        if !model.playing { model.togglePlay() }
    }

    /// Told by the overlay whenever the clock moves: a step back (a scrub or a replay) ends the tail; the real clock
    /// reaching its end starts it, so a longer surface's ghosts roll on to their own ends (the overlay caps each
    /// ghost's clock at its own recording's end).
    func clockMoved(from old: Double, to new: Double) {
        guard isShowing else { return }
        if !clockHasMoved { clockHasMoved = true }
        if new < old - 1e-9 { if tailStart != nil { tailStart = nil }; return }
        let end = model.duration - 1e-6
        let anySolved = slots.values.contains { if case .solved = $0 { return true } else { return false } }
        if old < end, new >= end, anySolved, tailStart == nil { tailStart = Date() }
    }

    /// The balls drawn for a picked surface, the what-if overlay's rule: the struck ball, the first ball it hit (there,
    /// or at home), and the first ball whose drop differs from home, each only when its future changed; at most three.
    func ballsToDraw(_ w: World) -> [Int] {
        guard let real else { return [] }
        let changed = Set(w.fork.changedBalls)
        let homeTl = real.timeline, worldTl = w.attempt.timeline
        let dropChanged = w.fork.changedBalls.first { b in
            homeTl.pocketTime.indices.contains(b) && worldTl.pocketTime.indices.contains(b)
                && (homeTl.pocketTime[b] == nil) != (worldTl.pocketTime[b] == nil)
        }
        var balls: [Int] = []
        for b in [real.cueBall, w.attempt.firstStruck ?? real.firstStruck, dropChanged].compactMap({ $0 })
        where changed.contains(b) && !balls.contains(b) && balls.count < 3 {
            balls.append(b)
        }
        return balls
    }

    // MARK: Words

    /// One surface's own sentence: "Played here" for home, the working or too-long line, the trick line when the real
    /// try missed and it makes the shot, else its WorldContrast sentence ("Much the same as here." when alike).
    func sentence(for s: PlaySurface) -> String {
        guard let real, let homeOutcome else { return EveryWorldWords.working }
        if s == home { return EveryWorldWords.playedHere }
        guard let slot = slots[s] else { return EveryWorldWords.working }
        switch slot {
        case .solving: return EveryWorldWords.working
        case .tooLong: return EveryWorldWords.tooLong
        case .solved(let w):
            if w.trickPasses == true, realMissedTrick { return EveryWorldWords.trickMade(s) }
            return EveryWorldWords.sentence(WorldContrast.key(home: homeOutcome, world: w.outcome), surface: s,
                                            real: real)
        }
    }

    /// The sentence about the whole fan, once every surface has landed; nil before (or when none could be solved, the
    /// too-long line).
    var fanSentence: String? {
        guard let real else { return nil }
        guard let lead = headline else { return solving ? nil : EveryWorldWords.tooLong }
        switch lead.contrast {
        case .trickMade: return EveryWorldWords.trickMade(lead.surface)
        case .world(.alike): return EveryWorldWords.fanAlike
        case .world(let c): return EveryWorldWords.sentence(c, surface: lead.surface, real: real)
        }
    }

    /// The sentence shown now: the picked surface's, else the fan's (or the working line while it fills).
    var shownSentence: String {
        if let p = picked { return sentence(for: p) }
        return fanSentence ?? EveryWorldWords.working
    }

    /// The shown sentence's second sentence, the plain reason: the shown surface's own summary from the Surface menu.
    /// None for the fan's "much the same" line, which is about no one surface.
    var shownSummary: String? {
        if picked == nil, case .world(.alike)? = headline?.contrast { return nil }
        if picked == nil, headline == nil { return nil }
        return shownSurface?.summary
    }
}
