// Author: Claude Sonnet 5.5 High
// Edited: GPT 6.2 Astra High, 21-November-2026, shared higher player launch-speed limits.
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke-model hook, 0.7.0 items 3 and 5: strokeZones uses
//          StrokeModel.strikeZones, the delivery's own rule, and both pass isBreak: racked, so a break gets its own
//          calm zone and the power bar's calm mark is where the strike's calm zone ends.)
// Date: 13-November-2026
// Edited: Claude Haiku 5.5 High, 18-November-2026 (the opening now waits on the title screen until beginFromTitle is called; launch switches that open a specific screen skip it).
// Edited: Claude Opus 5.5 High, 20-November-2026 (Try again and compare: every player shot and break is kept as a
//          ShotAttempt; tryAgain() puts the balls back where it started with the same settings, keeps it as the ghost,
//          and the retry's comparison is worked out from the two recordings).
// Edited: Claude Opus 5.5 High, 20-November-2026 (main menu: the game opens on the menu and can go back to it at any
//          time; menuOpen freezes everything behind it; startGame() racks for the player's own break, watchBreak()
//          plays the showpiece opening; the one-way title hold is gone).
// Edited: Claude Opus 5.5 High, 20-November-2026 (cue elevation: shotElevation, the sine of the cue's angle above
//          the table, is passed into every follow-up shot (zero, a level cue, unless something sets it; there is no
//          control for it yet). Launch flag -jumpDemo plays a jump shot over a blocking ball in slow motion, no taps.)
// Edited: Claude Opus 5.5 High, 20-November-2026 (Ride the shot: rideOn and setRide(_:) switch the Ride replay camera;
//          rideActive tells the scene when it may take over; while riding, playback eases into slow motion around the
//          first contact (RidePlan.rateFactor, a function of the clock); launch flag -rideDemo plays a straight pot
//          with Ride on, -rideDemo lens the same over the Lens, -rideDemo break the showpiece opening).
// Edited: Claude Opus 5.5 High, 20-November-2026 (trick shots: a marked "Trick shots" section near the end holds the
//          trick-shot mode for this table and three small loaders it uses: an authored layout with given settings, an
//          authored rack with its own seed and settings, and a way onto the table from the menu without a fresh rack).
// Edited: Claude Opus 5.5 High, 20-November-2026 (guided pacing: the Lens replay is paced by events, not the clock.
//          PacePlan picks the beats; playback eases down into each one, HOLDS there (a separate state with its own
//          real-time counter, never a zero speed) until the caption has had time to be read, then moves on, quick through
//          quiet stretches. guided, holding and nextBeat() are what the views read and call; autoRate is gone. Picking a
//          fixed speed turns guided pacing off; Replay with the Lens is now guided instead of a flat quarter speed.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (playing surfaces: every shot is solved through solve(_:), which writes
//          the chosen PlaySurface's friction and bounce numbers into its parameters (cloth while a trick shot is on the
//          table) and keeps the shot's surface-free input; setSurface(_:) stores a new surface and re-solves and replays
//          the shot on screen from its same start. The cold open's freeze point now never lies past the end of a short
//          break, which a fast-stopping surface such as sand can produce.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (captions are made for the surface the shot was solved on: solve(_:)
//          records it as solvedSurface and load() hands it to CaptionEngine, so setSurface's re-solve re-makes the
//          captions with the new surface's numbers. Checked for long shots (the Moon runs about six times longer): the
//          freeze point, the cold open and guided pacing all work from the timeline's own duration and events.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (other tables: tableKind is the table the player chose (TableKind,
//          stored under "optionTable"), physicsTable the one the solver uses (the pool table while a trick shot is up), solvedTable the one the shot on screen was solved on, which the scene draws.
//          solve(_:) writes the table into the parameters before the surface. setTable(_:) stores a new table and puts
//          its start layout on the table, still, with its default shot ready (the pool table re-racks). On a table other
//          than the pool table, Play lays out the table's start instead of a rack, Watch the break plays the table's
//          default shot, and a scratched cue ball is re-spotted on that table's own head spot.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the chosen surface now applies in trick shots too, instead of
//          silently staying on cloth, which made the Surface menu look broken).
// Edited: Claude Opus 5.5 High, 21-November-2026 (Behind the 8-Ball: a marked section after the trick shots holds the
//          EightBallMode (made on first use, like the trick mode) and enterEightBallTable(); entering either mode ends
//          the other; physicsTable and setTable treat a situation on the table like a trick shot (the pool table);
//          showsBridge and strokeUsesBridge answer for both modes, for the 3D cue and the bridge label).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the -pauseAt test flag, for store screenshots.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (award batch, model stream; contract docs/award-batch-contracts.md 2.1.
//          Physics switch: launch with -newPhysics and free play and matches solve on the newest physics generation;
//          solve(_:) is the one place that sets it, and trick shots, puzzles and the opening break stay on generation
//          one. Solving off the main thread: in free play and matches, shootNow and breakNow solve on a background task
//          (isSolving is true meanwhile, the table holds still so the cue can follow through, and a result that lands
//          after the player has moved on is dropped); trick shots and puzzles still solve directly, because their modes
//          read the new recording the moment they strike. Free play finished: ball in hand after a scratch (the cue
//          ball is lifted for the player to place, never put back for them), "Move cue ball" at any time, the shot
//          count, the table-cleared state with Rack again, a raised cue allowed (the forced level cue is gone), the
//          rack choice (fifteen-ball triangle, nine-ball diamond, or no rack with every ball placed by hand) and a
//          one-step undo. Matches: startMatch, continueSavedMatch and endMatch run a MatchMode (App/Match), which is
//          added to the pool-table-only check. An honest retry: the attempt keeps the effective input including cue
//          elevation and the seed, a retry restores both, a change of table, cloth or physics generation starts a fresh
//          comparison, and the comparison is kept as facts (retryComparison) beside its sentence. firstContactTime and
//          seekToFirstContact for the Lens. The first launch plays the opening with the menu closed, hands over a
//          fresh rack, plays the player's first break and only then opens the menu (openingStage, hasSeenOpening).
//          The tip's travel and the miscue ring are now per mode (tipLimit, miscueLimit). Launch flag -retryCases runs
//          the plan's retry cases and logs each result.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (opponent stream: startMatch takes an optional computer level;
//          matchSolveParameters gives the computer's planner the very parameters a match shot is solved with;
//          playComputerStroke places the cue ball, sets the stroke and strikes for the computer (the person's own power,
//          tip and cue elevation are put back afterwards); a lifted cue ball on the computer's turn is the computer's
//          alone (canPlaceCueBall).)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens, two hooks: startMatch takes how many play, so bar
//          billiards can start alone; advance feeds the match's real-time game clock every live frame, tickClock.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons stream, hook edits: a marked "Lessons" section holds the
//          LessonMode (made on first use, like the trick mode), enterLessonTable() and openControls; a lesson counts as
//          an authored mode (generation one, the pool table, solved directly, no undo or ball in hand); entering a
//          trick shot, a situation, a match, a table, Play or the intro ends it; and aim(toward:), nudgeAim and the
//          active power and tip setters refuse a change to a control the lesson has locked for this step, so every
//          input route (touch, pointer, keys, controller, VoiceOver) respects the lock.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream, plans/21-Nov-2026-stroke-and-power-plan.md: power is
//          how hard the player swings; the launch speed goes through CueProfile.selected (the house cue returns the
//          power untouched, so every solve is as before). A shot or break the player fires (fire(), never a
//          demonstration or a scripted strike) gets its delivery drift (StrokeModel) applied to the strike before
//          solving: from the finger's stroke when one set this power (pendingStroke), otherwise the fixed drift of the
//          swing alone. The attempt keeps the delivery and its stroke; a retry restores the stroke so an untouched
//          retry repeats exactly. strokeBridge is the bridge finger's length for the power bar's calm zone. The
//          straight-stroke drill (StrokeDrill) is made on first use, holds the pool table while it is up, is told of
//          every attempt, and is ended by every other menu choice; the table-cleared card stays away during it.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4, the flip: every mode solves on the default
//          physics, generation two; the -newPhysics flag is gone and -oldPhysics plays free play and matches on
//          generation one with its old numbers for comparison (prepare and matchSolveParameters write those numbers in
//          before the table and surface); the opening is pinned to the default; tip travel and the miscue ring follow
//          the default's miscue limit in every mode.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (review fix: a surface change during a match applies from the next
//          shot, so the shot being ruled is never re-solved or dropped and the turn cannot stick.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (reach, in the stroke section: `stance` is where the player stands and
//          leans for the next strike (Reach, from the layout, the aim, the table and the hand bridge; the rest rung
//          whenever the shot shows the mechanical bridge). strokeBridgeLength is the rest's head when the stance needs
//          the rest; strokeZones takes the stance's swing factor outside the authored modes; the strike's delivery is
//          worked out with the stance, which the delivery keeps for the retry comparison.)
// PURPOSE: The showpiece's brain. Runs the cold open as a small state machine (normal break at full speed,
//          freeze, melt into the Lens, rewind, slow-motion replay) on top of the recorded timeline, then hands
//          control to the player: play, pause, scrub, speed, Lens on and off, a new break of their own, and then
//          shot after shot from wherever the balls came to rest (aim, power, cue-tip height and side).
//          The timeline is solved once; this only moves a playback clock over it, so replay, reverse and slow
//          motion are exact. Sound and haptics fire together as the live clock crosses recorded events.
//          Package 4 (13-Nov-2026) adds the values the touch-to-aim controls need: one "active" power, tip height and
//          tip side that read and write the break values while the balls are racked and the shot values afterwards,
//          one aim direction for both, aim from a table position or in small steps, a way to jump to the end of the
//          shot on screen, and one fire() for Break and Shoot. The old values are unchanged and still drive the
//          sliders, so the fine controls and the touch controls always agree.
//          Also the free-play practice table (ball in hand, rack choices, undo, table cleared), the hook for a match
//          (MatchMode drives turns and rulings; this model plays its shots and puts its tables on screen), the retry
//          facts, and the first-launch opening.
// SRP/DRY check: Pass - playback state and flow only; drawing is TableScene, wording is CaptionEngine and the views,
//          rules are BreakdownRules (through MatchMode), placement legality and spotting are NextShot. The break/shot
//          split is hidden behind the active values here so the views never repeat the racked-or-not choice.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation
import Observation

enum Stage: Equatable {
    case lead, normalBreak, freeze, melt, rewind, slowReplay, explore
}

/// What free play racks: the fifteen-ball triangle, the nine-ball diamond, or no rack (every ball laid out in a row
/// for the player to place by hand). Stored under GameSettings.freePlayRackKey.
enum FreePlayRack: String, CaseIterable, Codable {
    case fifteen, nineBall, placeBalls
}

/// The first-launch opening (plans/21-Nov-2026-first-minute-and-lessons-plan.md package 1): the showpiece break plays
/// with the menu closed, then the cue is handed over on a fresh rack, then the player's own first break plays through
/// the same opening, and only then does the menu appear. `.none` outside it.
enum OpeningStage: Equatable {
    case none, playing, handOver, firstBreak
}

@MainActor
@Observable
final class ShowpieceModel {
    private(set) var timeline: Timeline
    /// Bumped whenever a new timeline is loaded so the scene knows to rebuild its Lens layer.
    private(set) var timelineVersion = 0
    private(set) var captions: [Caption] = []
    /// The beats the guided Lens replay stops on, and its speed between them. Worked out once per shot.
    private(set) var pacePlan = PacePlan.none

    var time = 0.0
    var playing = true
    private(set) var stage: Stage = .lead
    /// True while the main menu is up. Everything behind it holds still: the clock, the cold open and the melt.
    /// Launch switches that open a specific screen skip the menu, so this starts false for them.
    private(set) var menuOpen = !TitleScreen.launchSkipsTitle
    /// True once the player has started anything from the menu, so the menu offers Continue.
    private(set) var gameInProgress = TitleScreen.launchSkipsTitle
    /// Lens blend: 0 is the warm table, 1 is the blueprint.
    private(set) var melt = 0.0
    private var meltTarget: Double?
    /// Rate chosen by the player; nil means "let the cold open pace itself".
    var chosenRate: Double?
    private(set) var displayRate = 1.0
    var viewSize = CGSize(width: 800, height: 600)

    // The player's own break.
    var aimOffset = 0.0          // metres at the apex ball
    var power = 11.0             // launch speed, m/s
    var tipHeight = -0.006       // metres above (+) or below (-) centre
    var breakTipSide = 0.0       // metres to the right (+) or left (-) of centre
    private(set) var breakSerial = 0

    // The player's follow-up shots, taken from wherever the balls came to rest.
    /// Resting positions that the next shot starts from; index 0 is the cue ball, (-1,-1) means off the table.
    private(set) var layout: [Vec2] = []
    /// False once any shot has been played; true means the balls are still in the rack and the panel offers a break.
    private(set) var racked = false
    /// The seed of the rack on screen while racked: the break strikes with it (and Rack's helpers rebuild it from it).
    @ObservationIgnored private var rackSeed: UInt64 = 11
    var aimDegrees = 0.0         // direction of the cue, counter-clockwise from the long axis
    var shotPower = 3.0          // launch speed, m/s
    var shotTipUp = 0.0          // metres above (+) or below (-) centre: follow and draw
    var shotTipSide = 0.0        // metres to the right (+) or left (-) of centre: side spin
    /// Sine of the cue's angle above the table for the next shot: 0 is a level cue; raised, the ball can jump off the
    /// slate or curve (masse). The app does the trig; the solver only sees this sine.
    var shotElevation = 0.0
    private(set) var shotSerial = 0

    // Try again and compare.
    /// The player's shot or break now on screen; nil for the opening showpiece break and for a reset table.
    private(set) var currentAttempt: ShotAttempt?
    /// The attempt being retried: drawn faintly under the live shot so both outcomes show from the same start.
    private(set) var ghost: ShotAttempt?
    /// Bumped whenever the ghost changes, so the overlay rebuilds its sampled paths once, not every frame.
    private(set) var ghostVersion = 0
    /// What the retry changed and what happened differently, as facts (plan 14): nil until a retry of the same layout
    /// on the same table, cloth and physics generation has been played.
    private(set) var retryComparison: RetryComparison?
    /// The same comparison in a sentence or three (ShotComparison.describe); shown once the retry has played out.
    private(set) var comparison: String?
    /// Set by tryAgain() so the next shot keeps the ghost and is compared with it.
    private var retryPending = false
    /// The seed the retried attempt was struck with: the next shot strikes with it again, so a seeded miscue repeats.
    @ObservationIgnored private var retrySeed: UInt64?

    // Ride the shot (see ShotCamera).
    /// True when the player (or the trick-shot mode, through setRide) wants the Ride camera for replays.
    private(set) var rideOn = false
    /// The key moments the ride and its slow motion read: first contact, struck ball, rise. Worked out once per shot.
    private(set) var ridePlan = RidePlan.none

    // Guided pacing (see PacePlan). Only which beat is being held, and for how long, is stored; the next beat is always
    // found from the clock itself, so the many places that set `time` directly never leave a stale "next beat" behind.
    /// The beat (index into pacePlan.beats) the clock is stopped on for reading; nil when not holding.
    private var heldBeat: Int?
    /// Real seconds spent on the held beat so far, and how long it is to be held. Only counted while playing.
    /// Not observed: it changes every frame of a hold and no view reads it (views read `holding`).
    @ObservationIgnored private var holdElapsed = 0.0
    @ObservationIgnored private var holdDwell = 0.0
    /// The beat whose hold has just finished while the clock still sits exactly on it (so it is not held again, and a
    /// simultaneous beat after it is). Ignored as soon as the clock has moved off that time.
    private var passedBeat: Int?

    // Playing surface (see PlaySurface).
    /// The surface the player chose: every shot outside trick-shot mode is solved on it. Stored in UserDefaults.
    private(set) var surface: PlaySurface = PlaySurface.stored
    /// Bumped on every surface change, so the scene rebuilds the table's surface look.
    private(set) var surfaceVersion = 0
    /// The last shot handed to the solver, as built, BEFORE any surface numbers were written into it. Kept so a
    /// surface change can solve the very same shot again: re-applying a surface on top of another surface's numbers
    /// would leave the old ones wherever the new surface keeps the defaults (cloth changes nothing).
    @ObservationIgnored private var lastInput: ShotInput?
    /// True when the last solve was pinned to the default generation (the opening), so a surface re-solve keeps it there.
    @ObservationIgnored private var lastClassic = false
    /// The surface the timeline on screen was solved on, set by solve(_:) next to the solve itself, so the captions
    /// explain the numbers the solver actually used (a trick shot is solved on cloth whatever `surface` says).
    @ObservationIgnored private var solvedSurface: PlaySurface = PlaySurface.stored
    /// The physics generation the timeline on screen was solved on.
    @ObservationIgnored private var solvedGeneration = 1
    /// The table the player chose (see TableKind and setTable). Stored in UserDefaults.
    private(set) var tableKind: TableKind = .standard
    /// The table the timeline on screen was solved on: the scene draws this one, so the drawn table always matches the
    /// recording (a trick shot is on the pool table whatever `tableKind` says).
    private(set) var solvedTable: TableKind = .standard

    // Physics generation and background solving.
    /// Developer flag -oldPhysics: free play and matches play on physics generation one with its old numbers
    /// (PoolParameters.generationOne), for comparing against the tuned default. Generation two is simply the default
    /// since the proof plan's package 4 (21-Nov-2026) re-authored every trick shot, puzzle, lesson and the opening on
    /// it, so those always stay on the default. The old -newPhysics flag is gone: it would now change nothing.
    static let oldPhysicsRequested = ProcessInfo.processInfo.arguments.contains("-oldPhysics")
    /// True while a shot is being solved on a background task. The table on screen holds still meanwhile.
    private(set) var isSolving = false
    /// Bumped by every solve started and every cancel: a result that comes back with an older token is dropped.
    @ObservationIgnored private var solveToken = 0
    /// What the background solve will finish once its timeline lands.
    @ObservationIgnored private var pendingStrike: PendingStrike?
    /// The package's reading of the shot on screen (built in load()); its first contact feeds firstContactTime.
    @ObservationIgnored private var shotFacts: ShotFacts?
    /// When the cue ball first touched another ball in the recording on screen; nil when it touched nothing (and for a
    /// still table). The Lens's "go to contact" reads this.
    private(set) var firstContactTime: Double?

    // Ball in hand and placing balls.
    /// Where the player may put the cue ball: after a scratch in free play, after a foul in a match, and while
    /// "Move cue ball" is in use in free play. `.none` otherwise.
    private(set) var ballInHand: BallInHand = .none
    /// True while a ball is lifted for placing (the cue ball, or any ball in free play's place-balls setup).
    private(set) var placingCueBall = false
    /// Where the lifted ball is now (table metres); nil when nothing is lifted.
    private(set) var cueBallCandidate: Vec2?
    /// Which ball is lifted: the striking ball, or in free play any ball (beginPlacingBall).
    private(set) var placingBall = 0
    /// A scratch (free play) or a match's ball in hand waiting for the shot on screen to finish playing before the
    /// cue ball is lifted; advance() lifts it once the balls are at rest.
    @ObservationIgnored private var placementDue = false

    // Free play.
    /// Shots taken on this rack in free play (the table-cleared card counts them).
    private(set) var shotsThisRack = 0
    /// What free play racks. Stored under GameSettings.freePlayRackKey.
    private(set) var freePlayRack: FreePlayRack = FreePlayRack(rawValue:
        UserDefaults.standard.string(forKey: GameSettings.freePlayRackKey) ?? "") ?? .fifteen
    /// The table and settings from before the last free-play shot: one step of undo.
    private var undoStep: UndoStep?

    // Matches.
    /// The match being played; nil outside a match.
    private(set) var match: MatchMode?
    /// True when a match is saved on the device (Continue match on the menu).
    private(set) var savedMatchExists = MatchMode.saveExists

    // The opening for a first-time player.
    private(set) var openingStage: OpeningStage = .none
    private(set) var hasSeenOpening = UserDefaults.standard.bool(forKey: GameSettings.seenOpeningKey)

    private var stageTime = 0.0
    private let freezeTime: Double
    // The one shared sound board and haptics engine (sound stream, 21-Nov-2026), so match screens play through them too.
    private let sound = SoundBoard.shared
    private let haptics = Haptics.shared

    init() {
        // Not through solve(_:): self is not fully initialised yet. Same steps: the stored table, then the stored
        // surface, applied to a copy. The default generation: the opening is authored on it.
        let startTable = TableKind.stored
        let input = startTable.openingShot
        let startSurface = PlaySurface.stored      // read once: the solve and the captions must agree
        var onSurface = input
        startTable.apply(to: &onSurface.parameters)
        startSurface.apply(to: &onSurface.parameters)
        let tl = PoolSolver.simulate(onSurface)
        timeline = tl
        // The usual freeze point; freezeAt shortens it for a break that is over sooner (whatever shot is on screen).
        freezeTime = 2.2
        solvedSurface = startSurface
        tableKind = startTable
        solvedTable = startTable
        captions = CaptionEngine.make(from: tl, surface: startSurface)
        pacePlan = PacePlan(captions: captions, timeline: tl)
        timelineVersion = 1
        lastInput = input
        lastClassic = true
        ridePlan = RidePlan(tl)
        readShot(tl)
        adoptLayout(after: tl)
        startRideDemoIfAsked()
        if ProcessInfo.processInfo.arguments.contains("-jumpDemo") { playJumpDemo() }
        startOpeningIfFirstLaunch()
        runRetryCasesIfAsked()
    }

    /// Test hook (-jumpDemo): the cue ball jumps a ball sitting in its path, played in slow motion with the menu
    /// skipped, so it can be watched or screenshotted without a tap. A raised cue (sine 0.6, about 37 degrees) at
    /// 4 m/s clears the blocker 0.3 m ahead with room to spare (peak about 73 mm, first landing about 0.6 m out).
    func playJumpDemo() {
        menuOpen = false
        gameInProgress = true
        var start = [Vec2](repeating: NextShot.offTable, count: 16)
        start[0] = Vec2(0.6, 0.635)
        start[1] = Vec2(0.9, 0.635)
        start[2] = Vec2(1.75, 0.66)
        shotElevation = 0.6
        let input = NextShot.shot(from: start, direction: Vec2(1, 0), speed: 4.0, tipUp: 0, tipSide: 0,
                                  seed: 2026, elevation: shotElevation)
        load(solve(input))
        clearAttempts()
        stage = .explore; stageTime = 0; time = 0; playing = true
        chosenRate = 0.25; displayRate = 0.25
    }

    var duration: Double { timeline.duration }
    var lensOn: Bool { melt > 0.5 }
    var stageTitle: String {
        switch stage {
        case .lead: return ""
        case .normalBreak: return String(localized: "The break")
        case .freeze: return String(localized: "Hold on")
        case .melt: return String(localized: "Now look at what the table is doing")
        case .rewind: return String(localized: "Rewind")
        case .slowReplay: return String(localized: "Slow motion")
        case .explore: return lensOn ? String(localized: "Physics Lens") : String(localized: "Table")
        }
    }

    // MARK: Cold open

    func startColdOpen() {
        stage = .lead; stageTime = 0; time = 0; melt = 0; meltTarget = nil
        playing = true; chosenRate = nil
        resetPacing()
    }

    // MARK: Menu

    /// Back to the main menu: pause whatever is on the table; Continue picks it up exactly where it was. Opening the
    /// menu during the first-launch opening ends the opening (the player has found the menu; it is not shown again).
    func openMenu() {
        playing = false
        menuOpen = true
        if openingStage != .none { finishOpening(showMenu: false) }
    }

    /// Continue: close the menu and leave the table as it was.
    func closeMenu() { menuOpen = false }

    /// Play: a fresh rack, ready for the player's own break. The view opens the aiming controls. The cue keeps the
    /// elevation the player last set: free play allows a raised cue (rules-games plan package 2 step 4).
    func startGame() {
        lessonModeStorage?.end()
        strokeDrillStorage?.end()
        leaveMatch()
        menuOpen = false
        gameInProgress = true
        rerack()
        setLens(false)
    }

    /// Watch the break: the showpiece opening, with the slow-motion Physics Lens replay, from the start.
    func watchBreak() {
        strokeDrillStorage?.end()
        cancelPendingSolve()
        lessonModeStorage?.end()
        leaveMatch()
        endPlacement(); ballInHand = .none; undoStep = nil
        menuOpen = false
        gameInProgress = true
        // The showpiece break on the pool table; on another table, that table's default shot from its start layout.
        // Always the default generation (classic): the opening is authored on it.
        load(solve(physicsTable.openingShot, classic: true))
        clearAttempts()
        startColdOpen()
        stage = .normalBreak
    }

    /// The parameters racks and breaks are built with. Version 1 is what every rack and break has always used, so the
    /// racks (and the trick shots authored on them) are unchanged.
    private var rackParameters: PoolParameters {
        var p = PoolParameters()
        p.version = 1
        return p
    }

    /// The player's own break: solve it, then run it through the same cold open. Breaks the rack on screen (its seed,
    /// and the cue ball wherever ball in hand put it); with no rack on screen, a fresh rack of the current choice.
    func breakNow() {
        guard !isSolving else { return }
        if placingCueBall, !confirmCueBallPlacement() { return }
        if let m = match, !m.readyToShoot { return }
        let undo = makeUndoStep(isBreak: true)
        let p = rackParameters
        let choice: FreePlayRack = rackChoice == .placeBalls ? .fifteen : rackChoice
        let seed: UInt64
        let start: [Vec2]
        if racked, layout.count == 16 {
            seed = rackSeed
            start = layout
        } else {
            seed = UInt64(10 + breakSerial + 1)
            start = choice == .nineBall ? Rack.nineBallPositions(parameters: p, seed: seed) : Rack.positions(parameters: p, seed: seed)
        }
        // rerack() lays out seed 10 + breakSerial + 1; keeping the serial in step keeps tryAgain's arithmetic.
        breakSerial = Int(seed) - 10
        // The untouched racks go through Rack's own helpers, exactly as every authored break was made; a rack whose
        // cue ball was placed by hand is the same strike from the layout (aim at the apex ball, nudged by aimOffset).
        // The ball's launch speed for this swing with the cue in hand (exactly `power` with the house cue).
        let launch = CueProfile.selected.launchSpeed(forPower: power)
        var input: ShotInput
        if choice == .nineBall, start == Rack.nineBallPositions(parameters: p, seed: seed) {
            input = Rack.nineBallBreakShot(parameters: p, seed: seed, aimOffset: aimOffset, speed: launch,
                                           tipUp: tipHeight, tipSide: breakTipSide)
        } else if choice == .fifteen, start == Rack.positions(parameters: p, seed: seed) {
            input = Rack.breakShot(parameters: p, seed: seed, aimOffset: aimOffset, speed: launch, tipUp: tipHeight,
                                   tipSide: breakTipSide)
        } else {
            let direction = (start[1] + Vec2(0, aimOffset) - start[0]).normalized
            input = ShotInput(parameters: p, positions: start,
                              strike: CueStrike(direction: direction, speed: launch, tipUp: tipHeight, tipSide: breakTipSide,
                                                ballIndex: strikeBall),
                              seed: seed)
        }
        // The player's stroke drifts the strike before it is solved (nothing for a scripted break or a calm keyboard one).
        let delivery = strokeDue ? strokeDelivery(chosenUp: tipHeight, chosenSide: breakTipSide) : nil
        delivery?.apply(to: &input.strike, ballRadius: p.ballRadius)
        if openingStage == .handOver { openingStage = .firstBreak }
        // Recorded as struck: the attempt must hold exactly what was used, whatever load() re-aims afterwards.
        let settings = StruckSettings(isBreak: true, breakSeed: seed, seed: seed, aim: aimOffset, power: power,
                                      range: powerRange, up: tipHeight, side: breakTipSide, elevation: 0,
                                      stroke: delivery)
        strike(input, settings, undo: undo)
    }

    /// Fresh rack, ready for a new break (the panel's break sliders drive it). In a match the match racks instead.
    func rerack() {
        guard match == nil else { return }
        cancelPendingSolve()
        endPlacement(); ballInHand = .none
        shotsThisRack = 0
        undoStep = nil
        // Another table has no rack: its own start layout goes on the table instead, ready to shoot.
        if physicsTable != .standard { loadTableStart(); return }
        // Same seed the next break will use, so the rack on screen is exactly the one that gets broken.
        layRack(rackChoice, seed: UInt64(10 + breakSerial + 1))
    }

    /// The rack free play lays out now: the triangle whenever an authored mode is up (every trick rack is one), the
    /// match's rack in a match, otherwise the player's choice.
    private var rackChoice: FreePlayRack {
        if authoredModeUp { return .fifteen }
        if let m = match {
            if case .nineBallDiamond = m.rules.rack { return .nineBall }
            return .fifteen
        }
        return freePlayRack
    }

    /// Put a rack of `choice` built from `seed` on the table, still.
    private func layRack(_ choice: FreePlayRack, seed: UInt64) {
        let p = rackParameters
        switch choice {
        case .fifteen:
            // A zero-speed strike records a table where nothing moves: the quickest way to put the rack on screen.
            load(solve(Rack.breakShot(parameters: p, seed: seed, aimOffset: 0, speed: 0)))
            layout = Rack.positions(parameters: p, seed: seed)
            racked = true
        case .nineBall:
            load(solve(Rack.nineBallBreakShot(parameters: p, seed: seed, aimOffset: 0, speed: 0)))
            layout = Rack.nineBallPositions(parameters: p, seed: seed)
            racked = true
        case .placeBalls:
            let positions = Self.placeBallsLayout(p)
            load(solve(NextShot.shot(from: positions, direction: Vec2(1, 0), speed: 0, tipUp: 0, tipSide: 0, seed: 0)))
            layout = positions
            racked = false
            aimAtNearestBall()
        }
        rackSeed = seed
        clearAttempts()
        stage = .explore; time = 0; playing = false; chosenRate = nil
    }

    /// "No rack, place balls": the cue ball on the head spot and the fifteen object balls side by side across the foot
    /// end, for the player to drag where they want them. Neighbours are 10% of a diameter apart so each can be picked
    /// up on its own; the row's centres sit one and a half diameters from the foot cushion line, so none starts
    /// touching the cushion; centred, the row spans 0.88 m of the 1.27 m bed and stays well clear of the corner pockets.
    static func placeBallsLayout(_ p: PoolParameters) -> [Vec2] {
        var out = [Vec2](repeating: NextShot.offTable, count: 16)
        out[0] = Vec2(p.tableLength * 0.25, p.tableWidth * 0.5)
        let step = 2 * p.ballRadius * 1.1
        let x = p.tableLength - 3 * p.ballRadius
        for k in 0..<15 {
            out[k + 1] = Vec2(x, p.tableWidth * 0.5 + (Double(k) - 7) * step)
        }
        return out
    }

    /// Take the next shot from the resting layout. Skips the cold open: straight to the recorded replay,
    /// at real speed, with the Lens left as the player had it.
    func shootNow() {
        guard layout.count == 16, !racked, !isSolving else { return }
        if placingCueBall, !confirmCueBallPlacement() { return }
        if let m = match, !m.readyToShoot { return }
        let undo = makeUndoStep(isBreak: false)
        // On a table without a rack the hand-over's first stroke is a shot, and it plays the part of the first break.
        if openingStage == .handOver { openingStage = .firstBreak }
        shotSerial += 1
        // A retry strikes with the retried attempt's seed (the solver's only source of variation); any other shot gets
        // the next serial's. The serial itself keeps counting either way.
        let seed = retrySeed ?? UInt64(1000 + shotSerial)
        retrySeed = nil
        // Trig lives here in the app; the solver only ever sees a unit vector.
        let a = aimDegrees * Double.pi / 180
        // The launch speed for this swing with the cue in hand: exactly shotPower with the house cue.
        var input = NextShot.shot(from: layout, direction: Vec2(cos(a), sin(a)),
                                  speed: CueProfile.selected.launchSpeed(forPower: shotPower),
                                  tipUp: shotTipUp, tipSide: shotTipSide, seed: seed,
                                  elevation: shotElevation, ballIndex: strikeBall)
        // The player's stroke drifts the strike before it is solved; a demonstration or scripted shot is struck clean.
        let delivery = strokeDue ? strokeDelivery(chosenUp: shotTipUp, chosenSide: shotTipSide) : nil
        delivery?.apply(to: &input.strike, ballRadius: physicsTable.parameters.ballRadius)
        let settings = StruckSettings(isBreak: false, breakSeed: 0, seed: seed, aim: aimDegrees, power: shotPower,
                                      range: powerRange, up: shotTipUp, side: shotTipSide, elevation: shotElevation,
                                      stroke: delivery)
        strike(input, settings, undo: undo)
    }

    /// Where the cue would travel with the current aim, for the on-table guide line.
    var shotAimDirection: Vec2 {
        let a = aimDegrees * Double.pi / 180
        return Vec2(cos(a), sin(a))
    }

    // MARK: Striking (direct or on a background task)

    /// The settings a stroke was played with, captured when it was struck.
    private struct StruckSettings {
        let isBreak: Bool
        let breakSeed: UInt64
        let seed: UInt64
        let aim: Double
        let power: Double
        let range: ClosedRange<Double>
        let up: Double
        let side: Double
        let elevation: Double
        /// The drift the player's stroke put on the strike (nil for a scripted strike or a demonstration).
        var stroke: StrokeDelivery? = nil
    }

    /// A shot ready for the solver: the input as built (kept for a surface re-solve and the attempt), the copy with the
    /// table, surface and generation written in, and what it is solved on.
    private struct Prepared {
        let input: ShotInput
        let solvable: ShotInput
        let surface: PlaySurface
        let table: TableKind
        let generation: Int
        let classic: Bool
    }

    private struct PendingStrike {
        let prepared: Prepared
        let settings: StruckSettings
        let undo: UndoStep?
    }

    /// The table and settings from before a free-play shot.
    private struct UndoStep {
        let layout: [Vec2]
        let racked: Bool
        let rackSeed: UInt64
        let breakSerial: Int
        let shots: Int
        let isBreak: Bool
        let aim: Double
        let power: Double
        let up: Double
        let side: Double
        let elevation: Double
    }

    /// True when the shot is solved on a background task: free play and matches. Trick shots and puzzles solve
    /// directly, because TrickShotMode and EightBallMode read the new recording's version the moment they strike.
    private var solvesInBackground: Bool { !authoredModeUp }

    /// Solve a struck shot and put it on screen as the player's attempt.
    private func strike(_ input: ShotInput, _ settings: StruckSettings, undo: UndoStep?) {
        // Ball in hand is used up by the stroke; the shot's outcome (a scratch, a match's ruling) sets it again.
        ballInHand = BallInHand.none
        // The stroke measured for this strike, and its bridge, are used up; the next one is measured afresh.
        pendingStroke = nil
        strokeBridge = nil
        match?.shotFired()
        let prepared = prepare(input)
        guard solvesInBackground else {
            commit(prepared)
            finishStrike(PoolSolver.simulate(prepared.solvable), prepared: prepared, settings: settings, undo: undo)
            return
        }
        solveToken += 1
        let token = solveToken
        isSolving = true
        pendingStrike = PendingStrike(prepared: prepared, settings: settings, undo: undo)
        let solvable = prepared.solvable
        // The solve is a pure function of the input, so it runs on a background task and the result comes back here
        // (EightBallMode's Scoring phase is the same pattern). A wedged shot can no longer freeze the screen.
        Task { [weak self] in
            let tl = await Task.detached(priority: .userInitiated) { PoolSolver.simulate(solvable) }.value
            self?.strikeSolved(tl, token: token)
        }
    }

    /// The background solve is back. Used only if nothing has moved the table on since it started (the token).
    private func strikeSolved(_ tl: Timeline, token: Int) {
        guard token == solveToken, let pending = pendingStrike else { return }
        pendingStrike = nil
        isSolving = false
        commit(pending.prepared)
        finishStrike(tl, prepared: pending.prepared, settings: pending.settings, undo: pending.undo)
    }

    /// Drop any solve in flight: its result will be ignored when it lands.
    private func cancelPendingSolve() {
        guard isSolving || pendingStrike != nil else { return }
        solveToken += 1
        isSolving = false
        pendingStrike = nil
        // The first break never happened: the opening goes back to waiting for it.
        if openingStage == .firstBreak { openingStage = .handOver }
        match?.shotCancelled()
    }

    /// Put a solved stroke on screen: the recording, the attempt, the replay, and what comes after it (a match's
    /// ruling, or free play's shot count, undo and ball in hand after a scratch).
    private func finishStrike(_ tl: Timeline, prepared: Prepared, settings s: StruckSettings, undo: UndoStep?) {
        load(tl)
        record(ShotAttempt(isBreak: s.isBreak, breakSeed: s.breakSeed, start: prepared.input.positions, timeline: tl,
                           aim: s.aim, power: s.power, powerRange: s.range, tipUp: s.up, tipSide: s.side,
                           elevation: s.elevation, seed: s.seed, input: prepared.input, surface: prepared.surface,
                           table: prepared.table, generation: prepared.generation, stroke: s.stroke))
        if s.isBreak {
            startColdOpen()
            stage = .normalBreak
        } else {
            stage = .explore; stageTime = 0; time = 0; playing = true
            chosenRate = 1; displayRate = 1
            meltTarget = melt > 0.5 ? 1 : nil
        }
        if let m = match {
            m.shotLoaded(version: timelineVersion, start: prepared.input.positions)
        } else if !authoredModeUp {
            shotsThisRack += 1
            undoStep = undo
            // A scratch: the cue ball is NOT put back for the player. layout[0] holds the head spot as a starting
            // place; once the shot has played out the ball is lifted for them to place anywhere legal.
            // Not when that shot cleared the table: there is nothing left to shoot at, and the table-cleared card
            // (Rack again) is the next thing the player sees, not a lifted cue ball.
            let objectBallsLeft = layout.indices.contains { $0 != strikeBall && NextShot.isOnTable(layout[$0]) }
            if shotFacts?.cueBallScratched == true, objectBallsLeft {
                ballInHand = .anywhere
                placementDue = true
            }
        }
    }

    /// The undo step for a free-play stroke about to be struck (nil outside free play).
    private func makeUndoStep(isBreak: Bool) -> UndoStep? {
        guard match == nil, !authoredModeUp else { return nil }
        return UndoStep(layout: layout, racked: racked, rackSeed: rackSeed, breakSerial: breakSerial,
                        shots: shotsThisRack, isBreak: isBreak,
                        aim: isBreak ? aimOffset : aimDegrees, power: isBreak ? power : shotPower,
                        up: isBreak ? tipHeight : shotTipUp, side: isBreak ? breakTipSide : shotTipSide,
                        elevation: shotElevation)
    }

    // MARK: Ride the shot

    /// True while the Ride camera may fly: Ride is on and a replay is playing (the player's shots, replays and the
    /// cold open's slow-motion replay; not the cold open's first run, freeze, melt or rewind).
    var rideActive: Bool { rideOn && (stage == .explore || stage == .slowReplay) }

    /// Switch the Ride camera on or off. The trick-shot mode calls this before playing a shot so it plays riding.
    /// Switching it on when the shot on screen has already finished plays that shot again from the start, so the
    /// ride is seen instead of nothing visibly happening.
    func setRide(_ on: Bool) {
        rideOn = on
        if on, stage == .explore, ridePlan.rideable, time >= duration - 1e-6 {
            time = 0
            playing = true
            resetPacing()
        }
    }

    /// Launch flag -rideDemo: a straight pot with Ride on, no taps needed (-rideDemo lens: the same over the Lens;
    /// -rideDemo break: the showpiece opening, whose slow-motion replay then rides over the Lens).
    private func startRideDemoIfAsked() {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-rideDemo") else { return }
        rideOn = true
        let option = i + 1 < args.count ? args[i + 1] : ""
        guard option != "break" else { return }       // the cold open runs as usual and rides its slow replay
        load(solve(RideDemo.straightPot()))
        stage = .explore; time = 0; playing = false; chosenRate = nil
        if option == "lens" { melt = 1 }
        // Start after a beat, once the dark launch cover has faded, so the strike is seen.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.6))
            self?.playing = true
        }
    }

    // MARK: Try again and compare

    /// Try again is offered once a shot the player took has played out (the balls on screen are its result). Not in a
    /// match: a retry there would replay a turn.
    var canTryAgain: Bool { currentAttempt != nil && aimReady && match == nil }

    /// The comparison card shows once the retry has finished playing, so it never talks over the shot.
    var comparisonReady: Bool { comparison != nil && stage == .explore && time >= duration - 1e-6 }

    /// Put every ball back where the last shot started, with the same aim, power, spin, cue elevation and seed, and keep
    /// that shot as the ghost. Change one thing and shoot again to see the difference. For the break this re-racks the
    /// identical rack (with the cue ball where it was placed).
    func tryAgain() {
        guard let attempt = currentAttempt, aimReady, match == nil else { return }
        endPlacement(); ballInHand = .none
        undoStep = nil
        if attempt.isBreak {
            // breakNow() breaks the rack on screen with rackSeed; the serial is kept in step as rerack() expects.
            breakSerial = Int(attempt.breakSeed) - 11
            showStill(attempt.start, racked: true)
            rackSeed = attempt.breakSeed
            clearAttempts()
            aimOffset = attempt.aim; power = attempt.power; tipHeight = attempt.tipUp; breakTipSide = attempt.tipSide
        } else {
            showStill(attempt.start, racked: false)
            clearAttempts()
            aimDegrees = attempt.aim; shotPower = attempt.power; shotTipUp = attempt.tipUp; shotTipSide = attempt.tipSide
            shotElevation = attempt.elevation
            retrySeed = attempt.seed
        }
        // The stroke that played it comes back too, so Shoot with nothing touched repeats the shot exactly; a new
        // stroke on the cue ball replaces it.
        pendingStroke = attempt.stroke?.record
        ghost = attempt
        ghostVersion += 1
        retryPending = true
    }

    /// Put the comparison card away; the ghost stays until the next fresh shot.
    func dismissComparison() { comparison = nil; retryComparison = nil }

    /// A new player attempt is on screen. A retry is compared with the ghost when both were played from the same start
    /// on the same table, cloth and physics generation; any other shot starts afresh.
    private func record(_ attempt: ShotAttempt) {
        if retryPending, let previous = ghost, previous.sameConditions(as: attempt) {
            let facts = RetryComparison.between(previous, attempt)
            retryComparison = facts
            comparison = ShotComparison.describe(facts, previous: previous, current: attempt)
            // Same start, same settings: the recordings must match exactly. Logged for the -retryDemo check.
            if Self.logRetry {
                NSLog("RETRY compare: previous motion %llu, this motion %llu, same settings %@, key %@ -> %@",
                      previous.motionHash, attempt.motionHash,
                      Self.sameSettings(previous, attempt) ? "yes" : "no", String(describing: facts.key),
                      comparison ?? "")
            }
        } else {
            if ghost != nil { ghostVersion += 1 }
            ghost = nil; comparison = nil; retryComparison = nil
        }
        retryPending = false
        currentAttempt = attempt
        strokeDrillStorage?.attemptRecorded(attempt)
    }

    private func clearAttempts() {
        currentAttempt = nil
        if ghost != nil { ghostVersion += 1 }
        ghost = nil; comparison = nil; retryComparison = nil; retryPending = false; retrySeed = nil
    }

    static func sameSettings(_ a: ShotAttempt, _ b: ShotAttempt) -> Bool {
        a.aim == b.aim && a.power == b.power && a.tipUp == b.tipUp && a.tipSide == b.tipSide
            && a.elevation == b.elevation && a.seed == b.seed && a.start == b.start
    }

    private static let logRetry = ProcessInfo.processInfo.arguments.contains("-retryDemo")
        || ProcessInfo.processInfo.arguments.contains("-retryCases")

    /// Pause the replay at the moment the cue ball first touched another ball (the Lens's "go to contact").
    func seekToFirstContact() {
        guard let t = firstContactTime else { return }
        scrub(to: t)
    }

    // MARK: Aim by touch

    /// How far from the apex ball the break may be aimed, metres. Wide enough to choose the second row instead.
    static let breakAimLimit = 0.05
    /// The generation-one tip travel, metres (seventy percent of the pool ball's radius): only with -oldPhysics, where
    /// nothing miscues. The instance tipLimit below is what a mode actually allows.
    static let tipLimit = 0.02
    /// How far behind the cue ball a pull-back reaches full power, metres.
    static let pullReach = 0.5

    /// The radius of the ball the cue strikes on the table in play, metres: the tip picture (AimGauges) draws the ball
    /// to this scale, so its dot and miscue ring sit where the physics puts them.
    var cueBallRadius: Double { physicsTable.parameters.ballRadius }

    /// Where the miscue ring is drawn, metres from the middle of the cue ball: R * tipGrip / sqrt(1 + tipGrip^2), the
    /// offset past which the tip's grip cannot hold the ball (cue-strike plan). About half the radius.
    var miscueLimit: Double {
        let p = physicsTable.parameters
        return p.ballRadius * p.tipGrip / (1 + p.tipGrip * p.tipGrip).squareRoot()
    }

    /// How far from the middle the tip dot may travel in this mode. On generation two (every mode by default) it
    /// reaches a tenth of the ball's radius past the miscue ring, so a miscue can really be played while nearly all of
    /// the gauge stays in the useful range (everything past the ring miscues anyway). Every authored trick shot, puzzle
    /// escape and lesson keeps its tip inside the ring (re-authored on generation two, 21-Nov-2026), so the ring is
    /// also the edge of every authored window. Only -oldPhysics, outside the authored modes, gets the old travel.
    var tipLimit: Double {
        guard activeModelGeneration >= 2 else { return Self.tipLimit }
        return miscueLimit + 0.1 * physicsTable.parameters.ballRadius
    }

    /// True when the balls on screen are the balls the next shot starts from: the shot on screen has played out.
    /// Aiming is only offered then, because the guide is drawn from where the cue ball ended up. Never while a shot is
    /// being solved (the balls on screen are about to be replaced).
    var aimReady: Bool { stage == .explore && time >= duration - 1e-6 && !isSolving }

    /// The ball the next strike hits: the match's shooter's ball, otherwise the pool cue ball.
    var strikeBall: Int { match?.cueBallIndex ?? 0 }

    /// Where the cue ball sits for the next shot (the head spot while racked).
    var aimOrigin: Vec2 { layout.indices.contains(strikeBall) ? layout[strikeBall] : .zero }

    /// The unit direction the next strike goes in: from the cue ball toward the apex ball (nudged by the aim offset)
    /// for the break, or the aim angle for a shot. One answer for the guide, the ghost preview and the strike.
    var aimDirection: Vec2 {
        guard layout.count == 16 else { return Vec2(1, 0) }
        if racked { return (layout[1] + Vec2(0, aimOffset) - layout[0]).normalized }
        return shotAimDirection
    }

    /// The raised cue is open whenever the next stroke is a shot (free play, matches, and the authored modes that set
    /// it themselves); a break is always struck level.
    var elevationAllowed: Bool { !racked }

    /// Launch speed for the next strike, metres per second, and the range it may take.
    var powerRange: ClosedRange<Double> { racked ? PlayerShotSpeed.rackBreak : PlayerShotSpeed.ordinary }
    var activePower: Double {
        get { racked ? power : shotPower }
        set {
            guard openControls.contains(.power) else { return }
            let v = min(max(newValue, powerRange.lowerBound), powerRange.upperBound); if racked { power = v } else { shotPower = v }
        }
    }
    /// Power as 0 (softest) to 1 (hardest), for the gauge and the pull-back.
    var powerFraction: Double {
        get { (activePower - powerRange.lowerBound) / (powerRange.upperBound - powerRange.lowerBound) }
        set { activePower = powerRange.lowerBound + min(max(newValue, 0), 1) * (powerRange.upperBound - powerRange.lowerBound) }
    }

    /// Cue-tip contact point on the cue ball, metres: up is follow, down is draw, right and left are side spin.
    var activeTipUp: Double {
        get { racked ? tipHeight : shotTipUp }
        set { guard openControls.contains(.tipUp) else { return }; if racked { tipHeight = newValue } else { shotTipUp = newValue } }
    }
    var activeTipSide: Double {
        get { racked ? breakTipSide : shotTipSide }
        set { guard openControls.contains(.tipSide) else { return }; if racked { breakTipSide = newValue } else { shotTipSide = newValue } }
    }

    /// Aim so the cue travels through a spot on the table. For a shot that is any direction; for the break the
    /// strike is always at the rack, so the spot only chooses how far off the apex ball to hit.
    func aim(toward point: Vec2) {
        guard layout.count == 16, openControls.contains(.aim) else { return }
        let from = aimOrigin
        let d = (point - from).normalized
        if d.lengthSquared < 0.5 { return }       // finger on the cue ball itself: no direction to read
        if racked {
            let apex = layout[1]
            // Where the line from the cue ball through the finger crosses the apex ball's column.
            guard d.x > 0.05 else { aimOffset = d.y >= 0 ? Self.breakAimLimit : -Self.breakAimLimit; return }
            let y = from.y + d.y * ((apex.x - from.x) / d.x)
            aimOffset = min(max(y - apex.y, -Self.breakAimLimit), Self.breakAimLimit)
        } else {
            aimDegrees = atan2(d.y, d.x) * 180 / Double.pi
        }
    }

    /// Turn the aim by a small step: positive is counter-clockwise on the table plan. Steps are quarter degrees for a
    /// shot and a millimetre at the apex ball for the break.
    func nudgeAim(_ steps: Double) {
        guard openControls.contains(.aim) else { return }
        if racked {
            aimOffset = min(max(aimOffset + steps * 0.001, -Self.breakAimLimit), Self.breakAimLimit)
        } else {
            var a = aimDegrees + steps * 0.25
            if a > 180 { a -= 360 } else if a < -180 { a += 360 }
            aimDegrees = a
        }
    }

    /// Jump to the end of the shot on screen so the balls shown are the balls the next shot starts from.
    func skipToResult() {
        finishColdOpen()
        playing = false
        time = duration
        resetPacing()
    }

    /// Break or shoot, whichever is next. Returns true when it was the break (the cue ball's cold open takes over the
    /// screen, so the aiming controls close). A ball lifted for placing is put down first where it is, if that spot is
    /// legal; otherwise nothing is struck. In a match nothing is struck until the match is ready (a call made, any
    /// choice answered).
    @discardableResult
    func fire() -> Bool {
        guard !isSolving else { return false }
        if placingCueBall, !confirmCueBallPlacement() { return false }
        if let m = match, !m.readyToShoot { return false }
        // The player's own stroke: the strike it starts is delivered with the stroke's drift (StrokeModel).
        strokeDue = true
        defer { strokeDue = false }
        if racked { breakNow(); return true }
        shootNow()
        return false
    }

    /// Point the cue at the nearest ball still on the table.
    func aimAtNearestBall() {
        guard layout.count == 16 else { return }
        let from = strikeBall
        if from == 0 {
            guard let d = NextShot.directionToNearestObjectBall(in: layout) else { return }
            aimDegrees = atan2(d.y, d.x) * 180 / Double.pi
            return
        }
        // A table where the shooter strikes their own ball: the nearest other ball on the table from that one.
        var best: (d: Double, dir: Vec2)?
        for i in layout.indices where i != from && NextShot.isOnTable(layout[i]) {
            let delta = layout[i] - layout[from]
            if best == nil || delta.lengthSquared < best!.d { best = (delta.lengthSquared, delta.normalized) }
        }
        if let d = best?.dir { aimDegrees = atan2(d.y, d.x) * 180 / Double.pi }
    }

    /// Record where everything stopped so the next shot starts from there.
    private func adoptLayout(after tl: Timeline) {
        // A scratched cue ball goes back on the head spot of the table the shot was solved on (in free play and
        // matches only as the starting place of ball in hand; see finishStrike and MatchMode).
        layout = NextShot.layout(after: tl, parameters: solvedTable.parameters)
        racked = false
        aimAtNearestBall()
    }

    private func load(_ tl: Timeline) {
        adoptLayout(after: tl)
        timeline = tl
        captions = CaptionEngine.make(from: tl, surface: solvedSurface)
        pacePlan = PacePlan(captions: captions, timeline: tl)
        ridePlan = RidePlan(tl)
        readShot(tl)
        timelineVersion += 1
        resetPacing()
    }

    /// Read the recording on screen once with the package's one reading of a shot (ShotFacts): its first contact
    /// and its scratch. The start is the input the recording was solved from, which solve(_:) has just kept.
    private func readShot(_ tl: Timeline) {
        guard let input = lastInput, input.positions.count == tl.ballCount else {
            shotFacts = nil; firstContactTime = nil
            return
        }
        let facts = ShotFacts(timeline: tl, start: input.positions, cueBall: input.strike.ballIndex)
        shotFacts = facts
        firstContactTime = facts.firstContactTime
    }

    /// Put a layout on the table, still (the zero-speed strike: the quickest way to put positions on screen), ready to
    /// aim from. Keeps the attempts; the callers clear them when they should go.
    private func showStill(_ positions: [Vec2], racked keepRacked: Bool) {
        load(solve(NextShot.shot(from: positions, direction: Vec2(1, 0), speed: 0, tipUp: 0, tipSide: 0, seed: 0)))
        layout = positions
        racked = keepRacked
        if !keepRacked { aimAtNearestBall() }
        stage = .explore; stageTime = 0; time = 0; playing = false; chosenRate = nil
    }

    // MARK: Ball in hand and placing balls

    /// True when a ball may be lifted now: the balls are at rest and, in a match, the shooter has ball in hand; in free
    /// play at any time; never in a trick shot or puzzle (their layouts are authored).
    var canPlaceCueBall: Bool {
        guard aimReady, !menuOpen, layout.count == 16 else { return false }
        // On the computer's turn only the computer places its cue ball (MatchMode.personMayAct).
        if let m = match { return m.phase == .aiming && m.state.ballInHand != .none && m.personMayAct }
        return !authoredModeUp
    }

    /// Lift the cue ball (the striking ball) for placing: ball in hand, or "Move cue ball" in free play.
    func beginPlacingCueBall() { beginPlacing(ball: strikeBall) }

    /// Free play: lift any ball on the table to place it (the place-balls setup, or arranging a practice shot).
    func beginPlacingBall(_ ball: Int) {
        guard match == nil || ball == strikeBall else { return }
        beginPlacing(ball: ball)
    }

    private func beginPlacing(ball: Int) {
        guard canPlaceCueBall, layout.indices.contains(ball) else { return }
        // Free play's voluntary move: on a rack the cue ball stays behind the head line (it is a break); anywhere
        // otherwise. A match's ball in hand comes from the ruling and is not changed here.
        if let m = match {
            ballInHand = m.state.ballInHand
        } else if ball == strikeBall, ballInHand == .none {
            ballInHand = racked ? .behindHeadLine : .anywhere
        }
        placingBall = ball
        placingCueBall = true
        cueBallCandidate = NextShot.isOnTable(layout[ball])
            ? layout[ball]
            : NextShot.spot(ball, among: layout, parameters: physicsTable.parameters)
    }

    /// A match's turn begins (MatchMode.beginTurn): the model's ball in hand mirrors the state's, so the views and the
    /// placement check read one value, and with ball in hand the cue ball is lifted once the balls are at rest.
    func beginMatchTurn() {
        endPlacement()
        ballInHand = match?.state.ballInHand ?? BallInHand.none
        guard ballInHand != .none else { return }
        placementDue = true
        if aimReady { placementDue = false; beginPlacingCueBall() }
    }

    /// Move the lifted ball; returns whether that spot is legal (the view tints it red when not). The candidate follows
    /// the finger even when illegal, so the player sees where it is.
    @discardableResult
    func moveCueBallCandidate(to point: Vec2) -> CueBallSpot {
        if placingCueBall { cueBallCandidate = point }
        return placementSpot(point)
    }

    /// Put the lifted ball down where it is. False, and it stays lifted, if the spot is not legal.
    @discardableResult
    func confirmCueBallPlacement() -> Bool {
        guard placingCueBall, let c = cueBallCandidate, placementSpot(c) == .legal else { return false }
        var l = layout
        l[placingBall] = c
        let keepRacked = racked
        endPlacement()
        if match == nil { ballInHand = .none }
        showStill(l, racked: keepRacked)
        return true
    }

    /// Put the lifted ball back without moving it. A cue ball that was not on the table (a scratch) goes on its
    /// starting place, the head spot, so the table on screen matches the layout; in a match ball in hand stays, so it
    /// can be lifted again before the shot.
    func cancelPlacement() {
        guard placingCueBall else { return }
        let ball = placingBall
        endPlacement()
        if match == nil { ballInHand = .none }
        guard ball < timeline.ballCount, layout.indices.contains(ball) else { return }
        let recorded = timeline.state(ball: ball, at: timeline.duration)
        if recorded.pocketed || recorded.position != layout[ball] { showStill(layout, racked: racked) }
    }

    private func placementSpot(_ point: Vec2) -> CueBallSpot {
        NextShot.placement(of: point, cueBall: placingBall, among: layout,
                           behindHeadLine: placingBall == strikeBall && ballInHand == .behindHeadLine,
                           parameters: physicsTable.parameters)
    }

    /// Nothing lifted any more (ball in hand itself is the caller's to change).
    private func endPlacement() {
        placingCueBall = false
        cueBallCandidate = nil
        placingBall = strikeBall
        placementDue = false
    }

    // MARK: Free play: rack choice, table cleared, undo

    /// Choose what free play racks; on the pool table in free play the new rack goes on at once.
    func setFreePlayRack(_ r: FreePlayRack) {
        freePlayRack = r
        UserDefaults.standard.set(r.rawValue, forKey: GameSettings.freePlayRackKey)
        guard match == nil, !authoredModeUp, physicsTable == .standard else { return }
        rerack()
    }

    /// Free play with every object ball gone and the balls at rest: the table-cleared card shows.
    var tableCleared: Bool {
        guard match == nil, !authoredModeUp, !racked, shotsThisRack > 0, aimReady, layout.count == 16,
              strokeDrillStorage?.isActive != true else { return false }
        return layout.indices.allSatisfy { $0 == strikeBall || !NextShot.isOnTable(layout[$0]) }
    }

    /// The table-cleared card's "Rack again": a fresh rack (or table start) in free play.
    func rackAgain() {
        menuOpen = false
        rerack()
        setLens(false)
    }

    var canUndo: Bool { undoStep != nil && match == nil && !authoredModeUp && !isSolving }

    /// One step back: the table and the settings from before the last free-play shot (a break goes back to its rack).
    func undoLastShot() {
        guard canUndo, let u = undoStep else { return }
        endPlacement(); ballInHand = .none
        showStill(u.layout, racked: u.racked)
        rackSeed = u.rackSeed
        breakSerial = u.breakSerial
        clearAttempts()
        if u.isBreak {
            aimOffset = u.aim; power = u.power; tipHeight = u.up; breakTipSide = u.side
        } else {
            aimDegrees = u.aim; shotPower = u.power; shotTipUp = u.up; shotTipSide = u.side
        }
        shotElevation = u.elevation
        shotsThisRack = u.shots
        undoStep = nil
    }

    // MARK: Matches (MatchMode)

    /// Start a match of `kind` from the menu: any trick shot or situation ends, the menu closes, the rack goes on.
    /// `players` is how many play (bar billiards also plays alone); nil is two. With `computer` set, the second seat
    /// is the computer at that level.
    func startMatch(_ kind: MatchKind, players: Int? = nil, computer: ComputerLevel? = nil) {
        strokeDrillStorage?.end()
        cancelPendingSolve()
        lessonModeStorage?.end()
        trickMode.end()
        eightBallMode.end()
        menuOpen = false
        gameInProgress = true
        endPlacement(); ballInHand = .none; undoStep = nil
        let m = MatchMode(model: self, kind: kind, players: players, computer: computer)
        match = m
        m.start()
        setLens(false)
    }

    /// True when a match is saved on the device ("Continue match").
    var hasSavedMatch: Bool { savedMatchExists }

    /// Back to the match: the live one if there is one, otherwise the saved one from the device.
    func continueSavedMatch() {
        if match != nil { closeMenu(); return }
        guard let saved = MatchMode.loadSaved() else { savedMatchExists = false; return }
        strokeDrillStorage?.end()
        cancelPendingSolve()
        lessonModeStorage?.end()
        trickMode.end()
        eightBallMode.end()
        menuOpen = false
        gameInProgress = true
        endPlacement(); ballInHand = .none; undoStep = nil
        let m = MatchMode(model: self, restoring: saved)
        match = m
        m.resume()
        setLens(false)
    }

    /// End the match for good: its save is removed and free play's rack goes back on.
    func endMatch() {
        MatchMode.deleteSave()
        savedMatchExists = false
        leaveMatch()
        rerack()
    }

    /// Step out of a live match into something else, keeping its save so the menu can offer it again.
    private func leaveMatch() {
        guard match != nil else { return }
        cancelPendingSolve()
        match = nil
        endPlacement(); ballInHand = .none
    }

    /// MatchMode reports whether a save exists after each write or removal.
    func noteMatchSave(exists: Bool) { savedMatchExists = exists }

    /// The parameters a match shot is solved with right now, exactly as prepare(_:) builds them for a NextShot input
    /// (default parameters, then the table, then the surface, then the physics generation). The computer opponent
    /// plans on these, so its trial solves and the real stroke agree.
    var matchSolveParameters: PoolParameters {
        var p = PoolParameters()
        if activeModelGeneration == 1 { p.useGenerationOne() }
        physicsTable.apply(to: &p)
        physicsSurface.apply(to: &p)
        p.modelGeneration = activeModelGeneration
        return p
    }

    /// The computer's stroke (MatchOpponent): put the cue ball on `placement` first when it has ball in hand (if that
    /// spot is no longer legal the ball stays where it lies), then break or shoot with the given settings (a break
    /// takes `breakAimOffset`, metres off the apex ball; a shot takes `aimDegrees`). The person's own power, tip and
    /// cue elevation are put back once the stroke is struck, so their controls are as they left them. Returns whether
    /// the stroke was struck. Only while the match says the computer is acting.
    @discardableResult
    func playComputerStroke(placement: Vec2?, aimDegrees aim: Double, breakAimOffset: Double, power: Double,
                            tipUp: Double, tipSide: Double) -> Bool {
        guard let m = match, m.computerActing, aimReady, !isSolving, !menuOpen, layout.count == 16 else { return false }
        if let spot = placement {
            if !placingCueBall { beginPlacingCueBall() }
            if placingCueBall {
                moveCueBallCandidate(to: spot)
                if !confirmCueBallPlacement() { cancelPlacement() }
            }
        } else if placingCueBall {
            cancelPlacement()
        }
        if racked {
            let kept = (power: self.power, up: tipHeight, side: breakTipSide)
            aimOffset = min(max(breakAimOffset, -Self.breakAimLimit), Self.breakAimLimit)
            self.power = min(max(power, PlayerShotSpeed.rackBreak.lowerBound), PlayerShotSpeed.rackBreak.upperBound)
            tipHeight = tipUp; breakTipSide = tipSide
            breakNow()
            self.power = kept.power; tipHeight = kept.up; breakTipSide = kept.side
        } else {
            let kept = (power: shotPower, up: shotTipUp, side: shotTipSide, elevation: shotElevation)
            aimDegrees = aim
            shotPower = min(max(power, PlayerShotSpeed.ordinary.lowerBound), PlayerShotSpeed.ordinary.upperBound)
            shotTipUp = tipUp; shotTipSide = tipSide; shotElevation = 0
            shootNow()
            shotPower = kept.power; shotTipUp = kept.up; shotTipSide = kept.side; shotElevation = kept.elevation
        }
        return m.phase == .shooting
    }

    /// The table a match rack starts from (positions from Rack, or the table's own start layout).
    func matchSetup(for rack: MatchRack, seed: UInt64) -> MatchTableSetup {
        let p = rackParameters
        switch rack {
        case .fifteenBallTriangle:
            return MatchTableSetup(layout: Rack.positions(parameters: p, seed: seed), racked: true, rackSeed: seed)
        case .nineBallDiamond:
            return MatchTableSetup(layout: Rack.nineBallPositions(parameters: p, seed: seed), racked: true, rackSeed: seed)
        case .tableLayout:
            return MatchTableSetup(layout: physicsTable.startLayout ?? Self.placeBallsLayout(p), racked: false,
                                   rackSeed: seed)
        }
    }

    /// Put a match's table on screen, still, for the shooter to aim from.
    func showMatchTable(_ s: MatchTableSetup) {
        cancelPendingSolve()
        endPlacement()
        // Ball in hand in a match is the state's; mirrored here so the views and the placement check read one value.
        ballInHand = match?.state.ballInHand ?? BallInHand.none
        showStill(s.layout, racked: s.racked)
        rackSeed = s.rackSeed
        clearAttempts()
        if !s.racked, physicsTable != .standard {
            let shot = physicsTable.defaultShot
            shotPower = min(max(shot.power, 0.5), 8)
        }
    }

    // MARK: The opening for a first-time player

    /// First launch (nothing remembers the opening being seen, and no test switch asked for a specific screen): the
    /// menu stays closed and the same path Watch the break uses plays.
    private func startOpeningIfFirstLaunch() {
        let args = ProcessInfo.processInfo.arguments
        guard !hasSeenOpening, !TitleScreen.launchSkipsTitle, !args.contains("-retryCases") else { return }
        menuOpen = false
        gameInProgress = true
        openingStage = .playing
        startColdOpen()
    }

    /// Skip ahead: from the opening break to the hand-over; from the hand-over or the first break to the menu.
    func skipOpening() {
        switch openingStage {
        case .none:
            return
        case .playing:
            beginHandOver()
        case .handOver, .firstBreak:
            cancelPendingSolve()
            finishOpening(showMenu: true)
        }
    }

    /// The opening's replay has ended: a fresh free-play rack, cue in hand (the hand-over view says what to do).
    private func beginHandOver() {
        openingStage = .handOver
        rerack()
        setLens(false)
    }

    private func finishOpening(showMenu: Bool) {
        openingStage = .none
        hasSeenOpening = true
        UserDefaults.standard.set(true, forKey: GameSettings.seenOpeningKey)
        if showMenu { openMenu() }
    }

    /// Moves the opening on as the shots on screen play out (called every frame).
    private func updateOpening() {
        switch openingStage {
        case .playing where stage == .explore:
            beginHandOver()
        case .firstBreak where stage == .explore && !isSolving && currentAttempt != nil && time >= duration - 1e-6:
            finishOpening(showMenu: true)
        default:
            break
        }
    }

    // MARK: Retry cases (-retryCases)

    /// Launch flag -retryCases: runs plan 14's retry cases through the real free-play flow (strike, Try again,
    /// strike) and logs each comparison key and the sentence a player would read. No taps needed.
    private func runRetryCasesIfAsked() {
        guard ProcessInfo.processInfo.arguments.contains("-retryCases") else { return }
        menuOpen = false
        gameInProgress = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1))
            await self?.runRetryCases()
        }
    }

    private func runRetryCases() async {
        let rackBefore = freePlayRack
        freePlayRack = .fifteen            // not stored: the player's choice is put back below
        var results: [String] = []
        func report(_ name: String, _ pass: Bool) {
            let line = String(format: "RETRYCASE %@: %@ key %@ -> %@", name, pass ? "PASS" : "FAIL",
                              retryComparison.map { String(describing: $0.key) } ?? "none", comparison ?? "no comparison")
            NSLog("%@", line)
            results.append(pass ? "PASS" : "FAIL")
        }

        // 1. An untouched break, retried: identical inputs, identical recording.
        rerack()
        breakNow(); await settle()
        tryAgain(); breakNow(); await settle()
        report("untouched break", retryComparison?.key == .exactRepeat)

        // 2. A raised cue retried after moving the elevation: never "the same shot".
        aimAtNearestBall()
        shotPower = 3; shotTipUp = 0; shotTipSide = 0; shotElevation = 0.3
        shootNow(); await settle()
        tryAgain(); shotElevation = 0.35
        shootNow(); await settle()
        report("raised cue, elevation moved", retryComparison.map { c in
            c.key != .exactRepeat && c.inputChanges.contains { change in change.control == .elevation }
        } ?? false)

        // 3. A small power change (well under the 4% the words describe) that ends in the same area.
        shotElevation = 0
        aimAtNearestBall()
        shootNow(); await settle()
        tryAgain(); shotPower += 0.05
        shootNow(); await settle()
        report("small power change", retryComparison.map { c in
            c.key != .exactRepeat && c.inputChanges.contains { change in change.control == .power }
        } ?? false)

        // 4. Switching cloth between the attempts: the old comparison is gone and none is made.
        let surfaceBefore = surface
        aimAtNearestBall()
        shootNow(); await settle()
        tryAgain()
        if let other = PlaySurface.allCases.first(where: { $0 != surfaceBefore }) { setSurface(other) }
        shootNow(); await settle()
        report("cloth switched", retryComparison == nil && ghost == nil)
        setSurface(surfaceBefore)

        // 5. On the newest physics, a miscue repeated with identical inputs repeats exactly (the seed is restored).
        if activeModelGeneration >= 2 {
            aimAtNearestBall()
            shotTipUp = 0; shotTipSide = tipLimit
            shootNow(); await settle()
            let miscued = timeline.events.first { $0.kind == .cueStrike }?.miscue == true
            tryAgain(); shootNow(); await settle()
            report("miscue repeated (miscue \(miscued ? "yes" : "no"))", retryComparison?.key == .exactRepeat)
            shotTipSide = 0
        }

        freePlayRack = rackBefore
        NSLog("RETRYCASES done: %@", results.joined(separator: " "))
    }

    /// Wait for the stroke to be solved, then jump to its result (bounded, so a stuck run ends).
    private func settle() async {
        for _ in 0..<600 {
            if !isSolving {
                if placingCueBall { _ = confirmCueBallPlacement() }
                skipToResult()
                if aimReady { return }
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    // MARK: Player controls

    func scrub(to t: Double) {
        finishColdOpen()
        playing = false
        time = min(max(0, t), duration)
        resetPacing()
    }

    func togglePlay() {
        finishColdOpen()
        if time >= duration - 1e-6 { time = 0; resetPacing() }
        playing.toggle()
    }

    /// A fixed speed from the speed menu. A chosen speed turns guided pacing off (guided needs chosenRate == nil),
    /// and any hold in progress is let go so the clock moves at once.
    func setRate(_ r: Double) {
        finishColdOpen()
        chosenRate = r
        resetPacing()
        if !playing { playing = true }
    }

    func setLens(_ on: Bool) {
        finishColdOpen()
        meltTarget = on ? 1 : 0
    }

    func replay(withLens: Bool) {
        finishColdOpen()
        time = 0; playing = true
        meltTarget = withLens ? 1 : 0
        // With the Lens the replay is guided (no fixed speed: it stops on each beat to be read); without, real speed.
        chosenRate = withLens ? nil : 1
        resetPacing()
    }

    /// Jump to the hand-over state: Lens on, clock where it is.
    private func finishColdOpen() {
        guard stage != .explore else { return }
        stage = .explore
        if melt < 1, meltTarget == nil { meltTarget = 1 }
    }

    // MARK: Per-frame step

    /// Test hook (-pauseAt <seconds>): every shot played in explore stops itself at that moment on the clock, so a
    /// store screenshot of a ball in the air or a Lens beat comes out the same in every language. Read once.
    private static let pauseAt: Double? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-pauseAt"), i + 1 < args.count else { return nil }
        return Double(args[i + 1])
    }()

    func advance(_ rawDt: Double) {
        let dt = min(rawDt, 1.0 / 20.0)
        // Sound stream hook (21-Nov-2026): every frame, menu or not, the rolling voices follow the clock; they sound
        // only while it moves forward at playback pace, so a pause, a scrub, a rewind or the menu silences them.
        defer { sound.follow(timeline, clock: time, rate: displayRate, playing: playing && !menuOpen, surface: physicsSurface) }
        // The menu freezes the table behind it, whatever stage it is in.
        if menuOpen { return }
        defer {
            if let hold = Self.pauseAt, stage == .explore, playing, time >= hold { scrub(to: hold) }
        }
        switch stage {
        case .lead:
            stageTime += dt
            if stageTime > 1.1 { stage = .normalBreak; stageTime = 0 }
        case .normalBreak:
            displayRate = 1
            step(dt)
            if time >= freezeAt { time = freezeAt; stage = .freeze; stageTime = 0 }
        case .freeze:
            stageTime += dt
            if stageTime > 0.6 { stage = .melt; stageTime = 0 }
        case .melt:
            stageTime += dt
            let x = min(1, stageTime / 2.4)
            melt = x * x * (3 - 2 * x)
            if x >= 1 { melt = 1; stage = .rewind; stageTime = 0 }
        case .rewind:
            stageTime += dt
            let x = min(1, stageTime / 1.0)
            time = freezeAt * (1 - x * x * (3 - 2 * x))
            if x >= 1 { time = 0; stage = .slowReplay; stageTime = 0; resetPacing() }
        case .slowReplay:
            if guided {
                stepGuided(dt)
            } else {
                displayRate = chosenRate ?? 1
                step(dt)
            }
            // Not while a beat is being held: a beat stamped at the very end still gets its reading time.
            if time >= duration, !holding { stage = .explore; playing = false; chosenRate = nil }
        case .explore:
            if guided {
                // Paused, the hold's counter does not run: pausing on a beat keeps the full reading time.
                if playing { stepGuided(dt) }
            } else {
                // A hold left over from guided pacing (the Lens turned off, Ride turned on) is let go.
                if heldBeat != nil { resetPacing() }
                // With Ride on, playback eases into slow motion around the first contact and back out; the curve is a
                // function of the clock, so it plays the same however the clock got there. Any speed the player picked
                // still applies: the curve multiplies it.
                displayRate = (chosenRate ?? 1) * (rideActive ? ridePlan.rateFactor(at: time) : 1)
                if playing { step(dt) }
            }
            if let target = meltTarget {
                let speed = 1.8
                if melt < target { melt = min(target, melt + dt * speed) } else { melt = max(target, melt - dt * speed) }
                if melt == target { meltTarget = nil }
            }
        }
        // Hand-offs that wait for the shot on screen to play out: the opening's next stage, a match's ruling, and a
        // ball in hand that is lifted only once the balls are at rest.
        updateOpening()
        match?.update()
        // The bar-billiards clock counts real seconds (rawDt, not the step clamped for the physics replay); MatchMode
        // and MatchClock decide whether this frame counts. Never reached while the menu is open (returned above).
        match?.tickClock(realSeconds: rawDt)
        if placementDue, aimReady {
            placementDue = false
            beginPlacingCueBall()
        }
    }

    private func step(_ dt: Double) {
        let old = time
        time = min(duration, time + dt * displayRate)
        if time >= duration, stage == .explore { playing = false }
        fireSounds(from: old, to: time)
    }

    private func fireSounds(from a: Double, to b: Double) {
        guard b > a else { return }
        // Events are sorted by time, so scan only the span crossed this frame. Only live playback calls this
        // (scrubbing sets the time directly), so touch and sound never fire while dragging the scrubber. An event
        // stamped exactly zero (the cue tip strike) counts as crossed when playback starts from the very start.
        let crossed = timeline.events.filter { ($0.time > a || (a <= 0 && $0.time <= 0)) && $0.time <= b }
        guard !crossed.isEmpty else { return }
        let cues = FeelMapping.cues(for: crossed)
        sound.play(cues, at: b)
        haptics.play(cues)
    }

    // MARK: Playing surface (PlaySurface) - added by Claude Opus 5.5 High, 21-November-2026

    /// The surface the solver actually uses now: always the chosen one. Trick shots too: each answer was authored on
    /// the standard cloth, so on ice or worn felt it may well miss, and seeing why is the point (the Boss found the
    /// menu looked broken when trick shots silently stayed on cloth, 21-Nov-2026).
    var physicsSurface: PlaySurface { surface }

    /// The physics generation the next solve uses: the default (two) everywhere, and generation one in free play and
    /// matches only with the -oldPhysics developer flag. Trick shots, puzzles, lessons and the opening are authored on
    /// the default and always use it.
    var activeModelGeneration: Int {
        Self.oldPhysicsRequested && !authoredModeUp ? 1 : PoolParameters().modelGeneration
    }

    /// Where the cold open freezes: the usual point, but never past the end of the break. A surface that stops the
    /// balls quickly (sand) can make the whole break shorter than the usual freeze point, and a clock clamped to the
    /// end would then never reach it.
    private var freezeAt: Double { min(freezeTime, duration * 0.4) }

    /// Build the solver's copy of a shot: the table, then the surface, then the physics generation written into the
    /// parameters. The input as built is kept beside it, so a table or surface change can solve it again cleanly.
    /// `classic` pins the default generation, the one the opening is authored on, even under -oldPhysics. Generation
    /// one gets its own old cloth, roll, spin and rail numbers first, so the table and surface go on top of those.
    private func prepare(_ input: ShotInput, classic: Bool = false) -> Prepared {
        let s = physicsSurface, t = physicsTable
        let generation = classic ? PoolParameters().modelGeneration : activeModelGeneration
        var onSurface = input
        if generation == 1 { onSurface.parameters.useGenerationOne() }
        t.apply(to: &onSurface.parameters)
        s.apply(to: &onSurface.parameters)
        // Last, so nothing above can overwrite it.
        onSurface.parameters.modelGeneration = generation
        return Prepared(input: input, solvable: onSurface, surface: s, table: t, generation: generation, classic: classic)
    }

    /// The shot about to go on screen was solved from `p`: remember what it was solved on.
    private func commit(_ p: Prepared) {
        lastInput = p.input
        lastClassic = p.classic
        solvedSurface = p.surface
        solvedTable = p.table
        solvedGeneration = p.generation
    }

    /// Every shot goes through here (directly, or through strike's background task, which uses prepare and commit the
    /// same way): the one place the table, surface and physics generation are written in.
    private func solve(_ input: ShotInput, classic: Bool = false) -> Timeline {
        let p = prepare(input, classic: classic)
        commit(p)
        return PoolSolver.simulate(p.solvable)
    }

    /// Change the playing surface: store it, then solve the shot on screen again from its same start and settings on
    /// the new surface and play it from the beginning (the Lens and Ride stay as they are; the cold open starts over).
    /// The ghost and the retry comparison are dropped, since they were played on the old surface; the shot on screen
    /// stays the player's current attempt, now with the new recording, so Try again still works. A shot still being
    /// solved is dropped (it was struck on the old surface); the table stays where it was.
    func setSurface(_ s: PlaySurface) {
        guard s != surface else { return }
        // In a match the shot on screen belongs to the rules: it was struck on the old surface and the match is waiting
        // to rule on that very recording (MatchMode.update matches its version). Re-solving or dropping it would leave
        // the shot unscored and the turn stuck, so a match takes the new surface from its next shot only.
        if match != nil {
            surface = s
            UserDefaults.standard.set(s.rawValue, forKey: PlaySurface.storageKey)
            surfaceVersion += 1
            return
        }
        cancelPendingSolve()
        surface = s
        UserDefaults.standard.set(s.rawValue, forKey: PlaySurface.storageKey)
        surfaceVersion += 1
        if ghost != nil { ghostVersion += 1 }
        ghost = nil; comparison = nil; retryComparison = nil; retryPending = false; retrySeed = nil
        // A still table (a fresh rack, a retry's start, nothing struck yet) is the same on every surface: nothing to
        // solve again. Re-solving it would also undo the rack state (load re-reads the layout and clears `racked`).
        guard let input = lastInput, input.strike.speed > 0 else { return }
        let attempt = currentAttempt
        let inColdOpen = stage != .explore
        load(solve(input, classic: lastClassic))
        if let a = attempt { currentAttempt = a.resolved(on: timeline, surface: solvedSurface) }
        if inColdOpen {
            startColdOpen()
            stage = .normalBreak
        } else {
            stageTime = 0; time = 0; playing = true
        }
    }

    // MARK: Tables (TableKind) - added by Claude Opus 5.5 High, 21-November-2026

    /// The table the solver uses now: the pool table while a trick shot, a Behind the 8-Ball situation or a pool match
    /// is up (every one is played there), a match's own table in a table game, the player's chosen table otherwise.
    var physicsTable: TableKind {
        if onPoolTableOnly { return .standard }
        if let m = match { return m.table }
        return tableKind
    }

    /// True while a mode that was authored on the pool table is up: a trick shot or a Behind the 8-Ball situation.
    private var authoredModeUp: Bool {
        trickModeStorage?.current != nil || eightBallModeStorage?.current != nil || lessonModeStorage?.current != nil
    }

    /// True while something that only makes sense on the pool table is up: an authored mode, or an eight-ball or
    /// nine-ball match.
    private var onPoolTableOnly: Bool {
        authoredModeUp || match?.isPoolGame == true || strokeDrillStorage?.isActive == true
    }

    /// Change the table: store it, then put its start layout on the table, still, with its default shot ready (the
    /// pool table gets a fresh rack instead). The ghost, the comparison and the shot on screen belong to the old table,
    /// so they go. While a trick shot or a match is up nothing on screen changes (they keep their own table).
    func setTable(_ k: TableKind) {
        guard k != tableKind else { return }
        tableKind = k
        UserDefaults.standard.set(k.rawValue, forKey: TableKind.storageKey)
        guard !onPoolTableOnly, match == nil else { return }
        rerack()
    }

    /// Play a table as the game: leave any trick shot, Behind the 8-Ball situation or match (they are authored on the
    /// pool table, so while one is up a table change would be stored but never shown, which is why choosing bumper pool
    /// or bar billiards used to do nothing; a match stays saved), store the table, close the menu and put its start
    /// layout on screen, ready to shoot. Always re-racks, even for the table already chosen, because the table on screen
    /// may be the pool table of a mode. The cue keeps its elevation: free play allows a raised cue.
    func playTable(_ k: TableKind) {
        lessonModeStorage?.end()
        strokeDrillStorage?.end()
        trickMode.end()
        eightBallMode.end()
        leaveMatch()
        tableKind = k
        UserDefaults.standard.set(k.rawValue, forKey: TableKind.storageKey)
        menuOpen = false
        gameInProgress = true
        rerack()
        setLens(false)
    }

    /// The chosen table's start layout, still, with the aim and power of its default shot. The same zero-speed trick
    /// loadTrickLayout uses; the settings are set after load(), which re-aims.
    private func loadTableStart() {
        guard let start = physicsTable.startLayout else { return }
        load(solve(NextShot.shot(from: start, direction: Vec2(1, 0), speed: 0, tipUp: 0, tipSide: 0, seed: 0)))
        layout = start
        racked = false
        clearAttempts()
        let shot = physicsTable.defaultShot
        aimDegrees = shot.aimDegrees
        activePower = shot.power
        shotTipUp = 0; shotTipSide = 0
        stage = .explore; stageTime = 0; time = 0; playing = false; chosenRate = nil
    }

    // MARK: Trick shots (TrickShotMode) - added by Claude Opus 5.5 High, 20-November-2026

    /// The trick-shot mode for this table, made on first use. Kept out of observation: the mode is observable itself,
    /// and creating it lazily must not count as a change to the model.
    @ObservationIgnored private var trickModeStorage: TrickShotMode?
    var trickMode: TrickShotMode {
        if let m = trickModeStorage { return m }
        let m = TrickShotMode(model: self)
        trickModeStorage = m
        return m
    }

    /// Onto the table from the menu for a trick shot: the menu closes and Continue will come back here. A match in
    /// progress is left (it stays saved).
    func enterTrickTable() {
        strokeDrillStorage?.end()
        leaveMatch()
        cancelPendingSolve()
        endPlacement(); ballInHand = .none; undoStep = nil
        menuOpen = false
        gameInProgress = true
        eightBallModeStorage?.end()
        lessonModeStorage?.end()
    }

    /// The mechanical bridge is drawn while the player lines up a trick shot or a situation that needs it.
    var showsBridge: Bool { trickMode.showsBridge || eightBallMode.showsBridge }

    /// The shot on screen was struck off the bridge (for the cue's follow-through).
    var strokeUsesBridge: Bool {
        trickMode.current?.usesBridge == true || eightBallMode.current?.usesBridge == true
    }

    // MARK: Behind the 8-Ball (EightBallMode) - added by Claude Opus 5.5 High, 21-November-2026

    /// The Behind the 8-Ball mode, made on first use and kept out of observation, exactly as trickMode is.
    @ObservationIgnored private var eightBallModeStorage: EightBallMode?
    var eightBallMode: EightBallMode {
        if let m = eightBallModeStorage { return m }
        let m = EightBallMode(model: self)
        eightBallModeStorage = m
        return m
    }

    /// Onto the table from the menu for a situation: the menu closes, any trick shot ends, Continue comes back here. A
    /// match in progress is left (it stays saved).
    func enterEightBallTable() {
        strokeDrillStorage?.end()
        leaveMatch()
        cancelPendingSolve()
        endPlacement(); ballInHand = .none; undoStep = nil
        menuOpen = false
        gameInProgress = true
        trickModeStorage?.end()
        lessonModeStorage?.end()
    }

    /// Put an authored layout on the table, still, with the given aim (degrees), power, tip height and side ready for
    /// the next shot. The same zero-speed trick tryAgain() uses; the settings are set after load(), which re-aims.
    /// `elevation` raises the cue (sine of its angle) for the massé and the jump; every other shot is level.
    func loadTrickLayout(_ positions: [Vec2], aim: Double, power: Double, tipUp: Double, tipSide: Double, elevation: Double = 0) {
        cancelPendingSolve()
        endPlacement(); ballInHand = .none
        load(solve(NextShot.shot(from: positions, direction: Vec2(1, 0), speed: 0, tipUp: 0, tipSide: 0, seed: 0)))
        layout = positions
        racked = false
        clearAttempts()
        aimDegrees = aim; shotPower = power; shotTipUp = tipUp; shotTipSide = tipSide; shotElevation = elevation
        stage = .explore; stageTime = 0; time = 0; playing = false; chosenRate = nil
    }

    /// Put the rack built from `seed` on the table, ready for a break with the given settings. breakNow() breaks the
    /// rack on screen, and rerack() lays out seed 10 + breakSerial + 1, so stepping the serial to seed - 11 makes it the
    /// authored rack (the same arithmetic tryAgain() uses for a break).
    func loadTrickRack(seed: UInt64, aimOffset: Double, power: Double, tipUp: Double, tipSide: Double) {
        breakSerial = Int(seed) - 11
        rerack()
        self.aimOffset = aimOffset; self.power = power; tipHeight = tipUp; breakTipSide = tipSide
    }

    // MARK: Lessons (LessonMode) - added by Claude Opus 5.5 High, 21-November-2026

    /// The lesson mode, made on first use and kept out of observation, exactly as trickMode is.
    @ObservationIgnored private var lessonModeStorage: LessonMode?
    var lessonMode: LessonMode {
        if let m = lessonModeStorage { return m }
        let m = LessonMode(model: self)
        lessonModeStorage = m
        return m
    }

    /// Onto the table from the menu for a lesson: the menu closes, any trick shot or situation ends, Continue comes back
    /// here. A match in progress is left (it stays saved).
    func enterLessonTable() {
        leaveMatch()
        cancelPendingSolve()
        endPlacement(); ballInHand = .none; undoStep = nil
        menuOpen = false
        gameInProgress = true
        trickModeStorage?.end()
        eightBallModeStorage?.end()
        strokeDrillStorage?.end()
    }

    /// Which shot controls the player may change now: all of them, except in a lesson's guided tries (LessonMode).
    /// Read through lessonMode (not the optional storage) so a view that reads it is observing the mode from the start.
    var openControls: ShotControls { lessonMode.openControls }

    /// The target bands a lesson draws on the controls now, if any.
    var lessonZones: LessonZones? { lessonMode.zones }

    // MARK: The stroke (StrokeModel, StrokeGesture, StrokeDrill) - added by Claude Opus 5.5 High, 21-November-2026

    /// The finger's stroke for the next strike, kept up to date while it is drawn (StrokeGesture), so whichever route
    /// fires plays it. Used only if it set the power now in force; used up by every strike. Restored by tryAgain.
    @ObservationIgnored var pendingStroke: StrokeRecord?
    /// True only while fire() is striking: the player's own stroke, which drifts. Demonstrations, hints and scripted
    /// strikes call shootNow and breakNow directly and are struck clean.
    @ObservationIgnored private var strokeDue = false
    /// The bridge finger's length, metres, while it rests on the cloth (nil: the automatic bridge). Observed, so the
    /// power bar's calm zone moves with it.
    var strokeBridge: Double?

    /// The bridge the next strike is played off: the mechanical bridge when the shot needs it or the stance needs the
    /// rest (the cue ball out of reach), else the finger's or the automatic one.
    var strokeBridgeLength: Double {
        let hand = StrokeModel.bridgeLength(finger: strokeBridge, mechanical: false)
        return stance(handBridge: hand)?.bridge(hand: hand)
            ?? StrokeModel.bridgeLength(finger: strokeBridge, mechanical: showsBridge)
    }

    /// The calm and warm zones of the power bar now, for the cue in hand, the bridge and the stance. In a trick shot,
    /// situation or lesson the stance does not move the calm top (StrokeModel.delivery's rule, so the bar shows what the
    /// strike will use). A break has its own calm zone (stroke-model hook, 0.7.0 item 3: StrokeModel.strikeZones).
    var strokeZones: StrokeZones {
        StrokeModel.strikeZones(cue: CueProfile.selected, bridge: strokeBridgeLength, stance: stance,
                                authored: authoredModeUp, isBreak: racked)
    }

    /// Where the player stands and leans for the next strike, from the balls on the table, the aim and the hand bridge
    /// now (the finger's while it rests on the cloth, else the automatic one). Nil when there is no cue ball on the
    /// table to stand behind. Read by the stance card and the bridge mark on the cloth.
    var stance: Stance? { stance(handBridge: StrokeModel.bridgeLength(finger: strokeBridge, mechanical: false)) }

    /// The stance for a given hand bridge (Reach.stance). A shot that shows the mechanical bridge is the rest rung.
    private func stance(handBridge: Double) -> Stance? {
        guard layout.count == 16 else { return nil }
        return Reach.stance(layout: layout, cueBall: strikeBall, aim: aimDirection, table: timeline.table,
                            bridge: handBridge, mechanical: showsBridge)
    }

    /// The drift for the strike being fired. The finger's stroke counts only when it set the power now in force (a
    /// later change by the bar, a slider, the keys or a controller means the stroke is not the one being played), with
    /// its own bridge finger, else the current bridge. Without one, the fixed drift of the swing alone. Marks a drift
    /// that carried a tip inside the grip past it on the new physics (the stroke made the miscue).
    private func strokeDelivery(chosenUp: Double, chosenSide: Double) -> StrokeDelivery {
        let record = pendingStroke.flatMap { $0.power == activePower ? $0 : nil }
        // The stance is worked out for the hand bridge this stroke used; the rest rung plays off the rest's head.
        let hand = StrokeModel.bridgeLength(finger: record?.bridge ?? strokeBridge, mechanical: false)
        let struckStance = stance(handBridge: hand)
        let bridge = struckStance?.bridge(hand: hand)
            ?? StrokeModel.bridgeLength(finger: record?.bridge ?? strokeBridge, mechanical: showsBridge)
        var d = StrokeModel.delivery(power: activePower, fraction: powerFraction, record: record, bridge: bridge,
                                     cue: CueProfile.selected, authored: authoredModeUp, stance: struckStance,
                                     isBreak: racked)
        if activeModelGeneration >= 2 {
            let limit = physicsTable.parameters.miscueOffsetLimit
            let side = chosenSide + d.tipSideError
            let before = (chosenUp * chosenUp + chosenSide * chosenSide).squareRoot()
            let after = (chosenUp * chosenUp + side * side).squareRoot()
            d.pushedPastGrip = before <= limit && after > limit
        }
        return d
    }

    /// The straight-stroke drill, made on first use and kept out of observation, as the trick mode is.
    @ObservationIgnored private var strokeDrillStorage: StrokeDrill?
    var strokeDrill: StrokeDrill {
        if let d = strokeDrillStorage { return d }
        let d = StrokeDrill(model: self)
        strokeDrillStorage = d
        return d
    }

    /// Onto the table from the Play list for the drill: anything else on the table ends, the menu closes. The drill
    /// then puts its cue ball down (StrokeDrill.begin).
    func enterStrokeDrill() {
        trickModeStorage?.end()
        eightBallModeStorage?.end()
        lessonModeStorage?.end()
        leaveMatch()
        cancelPendingSolve()
        endPlacement(); ballInHand = .none; undoStep = nil
        menuOpen = false
        gameInProgress = true
    }

    // MARK: Guided pacing

    /// True while guided pacing drives the clock: the cold open's slow replay, or a Lens replay the player is watching
    /// (Lens on or turning on, no fixed speed picked, Ride off: Ride keeps its own slow-motion curve, and the two do
    /// not mix). A still table has no beats and is never guided. It stays true while paused, so the caption on a held
    /// beat does not change when the player pauses on it.
    var guided: Bool {
        guard chosenRate == nil, pacePlan.hasBeats else { return false }
        switch stage {
        case .slowReplay: return true
        case .explore: return (meltTarget ?? melt) > 0.5 && !rideActive
        default: return false
        }
    }

    /// True while the clock is stopped on a beat so its caption can be read. Worked out from stored state, so it is
    /// false at once if guided pacing ends or the clock is moved off the beat (a scrub, a replay).
    var holding: Bool {
        guard guided, let h = heldBeat, pacePlan.beats.indices.contains(h) else { return false }
        return abs(pacePlan.beats[h].time - time) <= Self.beatTolerance
    }

    /// Continue: end the current hold now; or, when not holding, jump straight to the next beat and hold there. The
    /// jump sets the clock directly, like a scrub, so the events skipped over make no sound. Does nothing unless guided.
    func nextBeat() {
        guard guided else { return }
        if holding, let h = heldBeat {
            finishHold(h)
            return
        }
        guard let i = upcomingBeat() else { return }
        time = pacePlan.beats[i].time
        beginHold(i)
    }

    /// Two clock times this close count as the same moment (a held beat, a clock sitting on it).
    private static let beatTolerance = 1e-9

    /// The next beat the clock will stop on: the first at or after the clock, skipping a beat already held at exactly
    /// this time (and any held before it at the same time). Nil when no beat is left.
    private func upcomingBeat() -> Int? {
        let beats = pacePlan.beats
        var i = pacePlan.firstBeat(atOrAfter: time - Self.beatTolerance)
        if let p = passedBeat, beats.indices.contains(p), abs(beats[p].time - time) <= Self.beatTolerance {
            i = max(i, p + 1)
        }
        return i < beats.count ? i : nil
    }

    private func beginHold(_ i: Int) {
        heldBeat = i
        holdElapsed = 0
        // With Explanations off there is nothing to read, so the stop is only a short pause that lets the hit land.
        // An option never set reads as on (its default), hence the object lookup rather than bool(forKey:).
        let explanations = UserDefaults.standard.object(forKey: GameSettings.explanationsKey) as? Bool ?? true
        holdDwell = explanations ? pacePlan.beats[i].dwell : 0.6
    }

    private func finishHold(_ i: Int) {
        heldBeat = nil
        holdElapsed = 0
        passedBeat = i
    }

    /// Forget any hold: called wherever the clock is set by hand or a new shot is loaded.
    private func resetPacing() {
        heldBeat = nil
        holdElapsed = 0
        passedBeat = nil
    }

    /// One frame of guided playback. Holding: count real time until the dwell is up (the clock stands still). Moving:
    /// step at the plan's speed for this clock time, and if that would carry the clock past the next beat, stop exactly
    /// on it and start holding. The speed has a floor above zero, so the clock always reaches the next beat; and the
    /// hold always ends because it counts real time, not clock time.
    private func stepGuided(_ dt: Double) {
        if heldBeat != nil {
            guard holding, let h = heldBeat else { resetPacing(); return }
            holdElapsed += dt
            if holdElapsed >= holdDwell { finishHold(h) }
            return
        }
        // Forget a finished beat once the clock has moved off it.
        if let p = passedBeat, !pacePlan.beats.indices.contains(p) || abs(pacePlan.beats[p].time - time) > Self.beatTolerance {
            passedBeat = nil
        }
        displayRate = pacePlan.rate(at: time)
        let old = time
        var target = min(duration, time + dt * displayRate)
        var hold: Int?
        if let i = upcomingBeat(), pacePlan.beats[i].time <= target {
            target = max(old, pacePlan.beats[i].time)
            hold = i
        }
        time = target
        if let hold { beginHold(hold) }
        if time >= duration, stage == .explore, hold == nil { playing = false }
        // Sound and touch for everything crossed on the way in, the beat's own event included, so the hit is heard
        // as the clock stops on it.
        fireSounds(from: old, to: time)
    }

    // MARK: Captions

    /// The caption on screen now. Guided: the caption of the beat being held, or of the most recent beat, kept up
    /// until the next beat replaces it (none once the shot has finished). Otherwise: the latest captioned event,
    /// shown for a short while after it that depends on the playback speed.
    func activeCaption() -> Caption? {
        let beats = pacePlan.beats
        if guided {
            if let h = heldBeat, holding { return beats[h].caption }
            guard time < duration - 1e-6 else { return nil }
            if let p = passedBeat, beats.indices.contains(p), abs(beats[p].time - time) <= Self.beatTolerance {
                return beats[p].caption
            }
            // The last beat at or before the clock.
            let after = pacePlan.firstBeat(atOrAfter: time + Self.beatTolerance)
            return after > 0 ? beats[after - 1].caption : nil
        }
        let hold = playing || stage != .explore ? max(0.4, 3.4 * displayRate) : 3.0
        // Captions are sorted by time, so the latest one at or before the clock is found by a binary search; it is the
        // closest, so if it has timed out every earlier one has too.
        var lo = 0, hi = captions.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if captions[mid].time <= time { lo = mid + 1 } else { hi = mid }
        }
        guard lo > 0 else { return nil }
        let c = captions[lo - 1]
        return time - c.time <= hold ? c : nil
    }
}
