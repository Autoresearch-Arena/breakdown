// Author: Claude Sonnet 5.5 High
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 bullet time, plans/23-Nov-2026-bullet-time-plan.md: owns
//          bulletTime; finishStrike arms it last, advance steps it every frame before the stage switch and lets it hold
//          and ease the plain explore step, step caps the clock at its contact, scrub cancels it, and a fresh rack
//          tells it.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 achievements hooks, plans/23-Nov-2026-achievements-plan.md:
//          the achievements book (made on first use), who struck each stroke, every shot the player struck read in any
//          mode, its per-frame step, and Watch it in the Lens for an achievement's kept shot; each marked
//          "// 0.7.7 achievements:".)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream ride, plans/22-Nov-2026-ride-handover-plan.md: a ride is
//          a scene in acts (RideAct, see RideStage.swift), run inside the ordinary table stage: the mount holds the
//          clock at the strike while the camera comes down to the ball, the roll plays the shot, the ride holds two
//          beats only (the first contact, with its explanation and Continue, and the struck ball's pocket or stop),
//          the dismount holds the clock while the camera rises, and after a trick shot's Watch it the slow Lens replay
//          is announced and rewound (replayInLensAfterRide) instead of starting in the same frame. rideStatus names
//          each act for the title row; rideCue tells the camera. holding, heldCaption, the caption on screen, the page
//          code and Continue also serve the ride's held beats. Scrubbing lands in the roll or the landed act, so the
//          camera stays a function of the clock there.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream pacing, plans/22-Nov-2026-v076-phone-plan.md, bug-hunt
//          entries 4, 6, 13, 56 and 58: a held beat's reading time counts the stroke sentence the card adds to the
//          strike; with the Lens on but not guided (a fixed speed, Ride on) the card shows only the latest beat's
//          caption, so it no longer flickers through every event of a break; playbackRowTop, the playback row's own top
//          edge for the third Lens tip; Watch the intro closes Your shot as it starts; the melt's status title is the
//          short "The Lens". The page code of the foundation is unchanged.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 foundation, plans/22-Nov-2026-v076-phone-plan.md: the held
//          caption can be split into pages (holdPage, setHoldPages, showHoldPage; Continue turns the page before it ends
//          the hold), the ride plan is built on the ball that was struck, and Ride only counts as active on a shot it can
//          ride.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 model-flow review: showList closes the other lists through
//          closeAllLists, so opening one list never makes the other two modes; setAutoRate does nothing behind the menu,
//          as setRate.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 model-flow, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          stream model-flow and M-A: Practice and Watch the intro always go back to the pool table; the three mode
//          lists open one at a time (showList) and every route into play closes them (closeAllLists); Continue match
//          is offered only for a save that loads; the computer's level is remembered across launches; tableOnScreen
//          names the free-play table the Tables list ticks; the intro's end card also follows a paused or scrubbed
//          intro; Continue on the menu resumes the opening, Continue on a paused held moment plays on; the speed
//          menu's Auto (setAutoRate); Ride is held off for a guided Lens replay and given back when it ends or is left
//          (holdRideForGuidedReplay); the stroke, play, speed and Try again do nothing behind the menu; opening the
//          menu ends a guided Lens replay and turns the Lens off, so it is not left drawn behind the menu.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 foundation, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md F6:
//          the what-if fork (whatIf, closed by every load), solverCopy pulled out of prepare unchanged, the kept strike
//          (keptStrike, keepFuture, writeRetrySettings split out of tryAgain(restoring:)), authoredModeUp and
//          ControlValues made internal, stubs model-flow fills (ModeList, showList, closeAllLists, tableOnScreen,
//          setAutoRate, holdRideForGuidedReplay), continueSavedMatch returns whether a match is up, leaveMatch stops
//          the computer's search, setSurface tells trick shots and lessons their recording was replaced, and load's
//          captions get the solved table and the striking ball.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (0.7.4 watch-invite review: a stroke, a break or Try again while
//          Watch your best shot replays first puts the cleared table back, so nothing is struck from the replayed
//          shot's resting balls; controls the player set during that replay are kept; a lifted ball is dropped. The
//          break's card waits for the session's second free-play break (G3 "from the second rack on"). Watch the
//          intro's end card is disarmed by any other recording going on screen. rerack resets the rack memory only
//          in free play.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 watch-invite, plans/22-Nov-2026-v074-glow-up-plan.md G3 and
//          G4: a marked "Worth watching" section. finishStrike, after everything it already did, judges a shot once
//          (ShotHighlightJudge) when the opening is over and no authored mode or drill is up; free play offers the
//          highlight through HighlightOffer's frequency rule (highlightCard, highlightOnOffer, watchHighlight,
//          tryHighlightTrick, dismissHighlight), and any touch of aim, power, spin or cue angle hides it for good; a
//          match keeps it for MatchMode, whose ruling offers it (offerLensReplay and watchShotInLens replace the break-only
//          offerLensReplayOfBreak and watchBreakInLens). The rack's best remarkable shot is kept and Table cleared can
//          replay it (watchBestShot), then puts the clearing shot back exactly; Table cleared sounds the bigger made-it
//          once per rack. Watch the intro ends on a small card (introEndOffered). The foundation's block now sits
//          before Guided pacing, so the doc comment of `holding` is next to it again.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 foundation: hooks for signature beats, the held Lens beat, the shared computer level and the highlight offer; plans/22-Nov-2026-v074-glow-up-plan.md)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.1, the Boss's first look at 0.7.0: every launch starts on the pool
//          table; the first launch goes straight to the table with the cue in hand, no opening replay; the first break
//          is followed by more play, not a lessons card; later launches open on the menu over a still table, without
//          the looping backdrop replay; a player's own break plays at real speed, no automatic slow Lens replay.)
// Edited: GPT 6.2 Astra High, 21-November-2026, shared higher player launch-speed limits.
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke-model hook, 0.7.0 items 3 and 5: strokeZones uses
//          StrokeModel.strikeZones, the delivery's own rule, and both pass isBreak: racked, so a break gets its own
//          calm zone and the power bar's calm mark is where the strike's calm zone ends.)
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 coordinator: in a match the cue first aims at the nearest ball
//          the rules allow, never at a ball that would foul).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 coordinator: hasSavedMatch(kind),
//          continueSavedMatch(kind:), endMatch removes only its own game's save).
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
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 model stream, plans/21-Nov-2026-bugs-after-0-6-6-plan.md and
//          docs/v07-contracts.md section 2. Every stroke route goes through fireStroke(), which says what happened and
//          why a stroke was refused (strokeRefusal before a stroke starts, lastRefusal after); in eight-ball a stroke
//          with no call plays the suggested call, and refuses only when there is none. The cue's angle has its lesson
//          lock (activeElevation), and the strike and the 3D cue use the least angle that clears every ball under the
//          whole cue (strikeElevation) outside the authored modes, with the cue the game picked (cueChoice,
//          cueInHand); the rest is drawn whenever the stance needs it (restInUse). A touch can be undone exactly
//          (aimSnapshot, restoreAim) and any ball can be lifted in free play (liftableBall). A match break plays at
//          real speed in the ordinary view, with the Lens replay offered on its ruling and See the ruling while a
//          match shot plays. The computer's turn is a stage the table shows (computerTurnStage): it thinks, then its
//          aim swings to its choice and its cue draws back for a beat before it strikes (stageComputerStroke); the
//          person's controls are not live meanwhile. The first launch holds three or four beats, and the opening's
//          headline beats show their equations (holdingHeadline); the first break ends on its own card
//          (firstBreakCard); after a break the shot panel reopens when the balls stop (shotPanelRequest). Later
//          launches play the opening's slow Lens replay silently behind the menu (menuBackdropPlaying), and the menu
//          names the next step (nextStep). A lesson's pass shot can go back to the lesson's stroke
//          (tryAgain(restoring:)). Launch flags put each store scene up (StoreScene).)
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
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 clips, plans/23-Nov-2026-clips-plan.md: three read-only
//          properties for the clip offer (highlightOnScreen, highlightControlsUntouched, bestShotForClip) at the end of
//          the rack's best shot section. No behaviour change.)
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
/// the same opening, then its short card is up (what the break did, Learn the shots, Keep playing), and only then does
/// the menu appear. `.none` outside it. `firstBreakCard` was appended in 0.7.0 (item 3).
enum OpeningStage: Equatable {
    case none, playing, handOver, firstBreak, firstBreakCard
}

/// What a fire attempt did (ShowpieceModel.fireStroke).
enum StrokeOutcome: Equatable {
    case breakStruck, shotStruck, refused(ShotRefusal)
}

/// The aim and power at one instant (a touch landing), so a touch that turns out to be a pinch, a pan or a double tap
/// can put them back exactly (ShowpieceModel.aimSnapshot and restoreAim; contract section 4).
struct AimSnapshot: Equatable {
    let racked: Bool
    let aimDegrees: Double
    let aimOffset: Double
    let power: Double
    let strokeBridge: Double?
}

/// The model asking the view to open, close or toggle "Your shot". The serial makes two requests for the same action
/// two different values, so a view watching with onChange sees each one.
struct ShotPanelRequest: Equatable {
    enum Action: Equatable { case open, close, toggle }
    let serial: Int
    let action: Action
}

/// The three mode lists the menu, the Mac menu bar and the notebook can open (ShowpieceModel.showList); at most one is
/// open at a time.
enum ModeList { case tricks, lessons, eightBall }

/// The next step on the path from stored progress, for the menu's highlighted entry (plan item 52).
enum NextStep: Equatable, Sendable {
    /// The first lesson not passed.
    case lesson(number: Int, title: String)
    /// That lesson's trick shot (Lesson.trickID), once the lesson is passed.
    case trickShot(title: String)
    /// Every lesson and its trick shot done, and no game finished against the easy computer yet.
    case gameAgainstEasyComputer

    /// The words on the menu's highlighted entry.
    var sentence: String {
        switch self {
        case .lesson(let number, let title): return String(localized: "Next: Lesson \(number), \(title)")
        case .trickShot(let title): return String(localized: "Next: the trick shot \(title)")
        case .gameAgainstEasyComputer: return String(localized: "Next: a game against the easy computer")
        }
    }
}

/// The computer's turn, as the table shows it (plan item 16).
enum ComputerTurnStage: Equatable, Sendable {
    /// Not the computer's turn.
    case none
    /// MatchOpponent is planning (from the moment its turn is known, the ruling card before it still up).
    case thinking
    /// The aim line swings to its choice and the cue draws back for a beat.
    case staging
    /// Its stroke is struck and playing.
    case striking
}

/// Launch flags for the store pictures and the preview video (plan item 40). Each skips the menu and the opening and
/// puts its scene up, still. ShowpieceModel plays the scene's way there (startStoreSceneIfAsked); views that must
/// open something for a scene (the match card's "Why that shot", the lesson card) read `requested`.
enum StoreScene: Equatable, Sendable {
    /// -storeMatch: eight-ball against the medium computer mid-game, after the computer's shot ("Why that shot").
    case match
    /// -storeRuling: a two-player eight-ball ruling card after a foul.
    case ruling
    /// -storeLesson <1...6>: that lesson held on its key moment in the Lens.
    case lesson(Int)
    /// -storeTableGame bumperPool|fivePin|barBilliards: a scored game a few shots in.
    case tableGame(MatchKind)
    /// -storeDrill: the straight-stroke drill with a measured stroke on its card.
    case drill
    /// -storeRide: a Ride replay held where the room and the lamp show.
    case ride

    /// The six flag names, for TitleScreen.launchSkipsTitle.
    static let flags = ["-storeMatch", "-storeRuling", "-storeLesson", "-storeTableGame", "-storeDrill", "-storeRide"]

    /// The scene the launch arguments ask for, parsed once; nil on an ordinary launch.
    static var requested: StoreScene? { parsed }

    private static let parsed: StoreScene? = parse(ProcessInfo.processInfo.arguments)

    /// The first store flag among the arguments, with its value. A missing or unknown value falls back to the first
    /// choice (lesson 1, bumper pool), so a typo still puts a scene up rather than the menu.
    static func parse(_ args: [String]) -> StoreScene? {
        func value(after flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        if args.contains("-storeMatch") { return .match }
        if args.contains("-storeRuling") { return .ruling }
        if args.contains("-storeLesson") {
            let n = value(after: "-storeLesson").flatMap { Int($0) } ?? 1
            return .lesson(min(max(n, 1), 6))
        }
        if args.contains("-storeTableGame") {
            let kind = value(after: "-storeTableGame").flatMap { MatchKind(rawValue: $0) }
            switch kind {
            case .fivePin?: return .tableGame(.fivePin)
            case .barBilliards?: return .tableGame(.barBilliards)
            default: return .tableGame(.bumperPool)
            }
        }
        if args.contains("-storeDrill") { return .drill }
        if args.contains("-storeRide") { return .ride }
        return nil
    }
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

    // The ride's acts (0.7.6 stream ride; RideStage.swift says what each one is).
    /// Where the ride is. Observed: it changes a handful of times per ride (the title row and the overlay read it).
    private(set) var rideAct: RideAct = .none
    /// 0 to 1 through the mount, the dismount or the rewind. Not observed: it changes every frame, and its readers
    /// (the camera, the rings) redraw every frame anyway.
    @ObservationIgnored private(set) var rideActProgress = 0.0
    @ObservationIgnored private var rideActElapsed = 0.0
    @ObservationIgnored private var rideActLength = 1.0
    /// The ride beat (index into rideBeats) the clock is held on; nil when not holding. The hold's real-time counter
    /// and length are the guided hold's own (holdElapsed, holdDwell), which a ride never uses at the same time.
    @ObservationIgnored private var rideHeldBeat: Int?
    /// Where the rewind before the slow Lens replay starts from (clock seconds).
    @ObservationIgnored private var rideRewindFrom = 0.0
    /// True for the first ride ever (RideTip): its mount is slower and its roll shows the tip once.
    private var rideTipThisRide = false
    /// The ride's two beats for the recording on screen, worked out once per recording (rideBeats).
    @ObservationIgnored private var rideBeatsMemo: (version: Int, beats: [RideBeat]) = (-1, [])

    // 0.7.7 bullet-time: the freeze on a rare hit (BulletTime.swift; plans/23-Nov-2026-bullet-time-plan.md).
    /// Bullet time's run: armed at the strike, stepped every frame, read by the scene and the status slots. A let of an
    /// observable class, so views reading bulletTime.statusWords are tracked through it.
    let bulletTime = BulletTime()

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
    /// Pages of the held caption (0.7.6). On a phone the explanation card has a fixed room; CaptionStrip splits a caption
    /// that does not fit into pages and tells the model how much reading each page holds (setHoldPages). The hold's
    /// reading time is shared out between the pages in that proportion, the page on screen follows the hold's own
    /// real-time counter, and Continue turns the page before it ends the hold. Observed, but it changes only when the
    /// page turns. A caption that fits is one page and nothing changes.
    private(set) var holdPage = 0
    /// Share of the hold each page gets (sums to 1), and the caption they belong to (pages for another caption are
    /// ignored, so a late report from the card cannot page the wrong moment).
    @ObservationIgnored private var holdPageShares: [Double] = [1]
    @ObservationIgnored private var holdPagesCaption: Int?

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
    /// Observed (it changes once per recording), so the first-break card's words follow shotFactsOnScreen.
    private var shotFacts: ShotFacts?
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
    /// True when a match is saved on the device (Continue match on the menu). Seeded from a save that really loads
    /// (savedSummary decodes it), not from the file merely existing: a file that cannot be read, is in an old format
    /// or holds a finished game must never offer a Continue that then does nothing (0.7.5).
    /// Read from the one summary below, so launch reads the saves once (0.7.5: there is one file per game now).
    var savedMatchExists: Bool { savedMatchSummary != nil }
    /// The saved match named for the menu's Continue row (which game, against whom, whose shot); nil when none is
    /// saved. Refreshed whenever a save changes (noteMatchSave).
    private(set) var savedMatchSummary: SavedMatchSummary? = MatchMode.savedSummary()

    // The opening for a first-time player.
    private(set) var openingStage: OpeningStage = .none
    private(set) var hasSeenOpening = UserDefaults.standard.bool(forKey: GameSettings.seenOpeningKey)

    // Input and refusals (contract 2.1).
    /// The input route in use; every route sets it on its first event. A pointer on the Mac, a finger elsewhere.
    var inputInUse: PlayInput = {
        #if os(macOS)
        return .pointer
        #else
        return .touch
        #endif
    }()
    /// The last refusal, for the shot card's line and the call card's pulse; cleared by the next accepted strike and by
    /// clearRefusal(). refusalSerial is bumped on every refusal, so the same reason twice still pulses the card.
    private(set) var lastRefusal: ShotRefusal?
    private(set) var refusalSerial = 0
    /// Bumped by every strike that reaches the solver, so fireStroke can tell a strike from a silent refusal.
    @ObservationIgnored private var strikeSerial = 0

    // The shot panel, the menu backdrop and the Lens tips (contract 2.3).
    /// The model's last request to open, close or toggle "Your shot"; ShowpieceView acts on each new one.
    private(set) var shotPanelRequest: ShotPanelRequest?
    /// A break the player struck closed the shot panel; it is asked to open again once the balls stop on the
    /// person's turn (plan item 8). Fires once, then clears.
    @ObservationIgnored private var panelAfterBreakDue = false
    /// Later launches: the opening's slow Lens replay plays behind the dimmed menu, silently (plan item 52).
    private(set) var menuBackdropPlaying = false
    /// True when the Lens replay on screen was started by the player (Replay with the Lens, Watch it in the Lens), not
    /// by the opening or by a lesson's own demonstration; the Lens tips wait for the first guided hold of such a replay.
    private(set) var lensReplayStartedByPlayer = false
    /// While true, a held beat's reading time does not run out (the Lens tips are showing over it).
    var holdForTips = false
    /// Top edge of the playback row itself (play, the scrub bar, Lens, Ride), in stage space (StageSpace.name), written
    /// by ShowpieceView when it measures that row under the table; nil when nothing measured it (0.7.6, entry 13). The
    /// third Lens tip points at the bar from just above this edge: the top of the whole bottom stack also holds the
    /// explanation card's room, which stands blank while the tips show, so the bubble floated over the table. Writers
    /// compare before writing (it is observed).
    var playbackRowTop: Double?
    /// True when the recording on screen is the showpiece opening (the cold open, Watch the intro, the menu backdrop),
    /// so its pace plan holds the opening's beats.
    @ObservationIgnored private var showpieceOnScreen = false
    /// The timelineVersion of the recording the current attempt was struck into (playerShotOnScreen compares it).
    private var attemptVersion = -1

    // Matches and the computer (contract 2.4).
    /// See the ruling was pressed while the match shot was still being solved: jump to its end as soon as it lands.
    @ObservationIgnored private var rulingWanted = false
    /// The computer's staged stroke in progress (its swing, draw-back and strike), advanced every frame. Not observed:
    /// it changes every frame; views read computerTurnStage, which reads stagingActive.
    @ObservationIgnored private var staging: ComputerStaging?
    private var stagingActive = false

    private var stageTime = 0.0
    private let freezeTime: Double
    // The one shared sound board and haptics engine (sound stream, 21-Nov-2026), so match screens play through them too.
    private let sound = SoundBoard.shared
    private let haptics = Haptics.shared

    init() {
        // Not through solve(_:): self is not fully initialised yet. Same steps: the stored table, then the stored
        // surface, applied to a copy. The default generation: the opening is authored on it.
        // Every launch starts on the pool table (0.7.1): the other tables have no pockets, and opening on the last one
        // chosen read as a pocketless, broken pool table. The choice is kept and the Tables list still offers it.
        let startTable = TableKind.standard
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
        // The table starts on the showpiece opening: its pace plan holds the opening's beats (refreshPacePlan picks
        // the first launch's shorter set once the opening is known to be starting).
        showpieceOnScreen = true
        pacePlan = PacePlan(captions: captions, timeline: tl, style: .opening)
        timelineVersion = 1
        lastInput = input
        lastClassic = true
        ridePlan = RidePlan(tl, cueBall: input.strike.ballIndex)
        readShot(tl)
        adoptLayout(after: tl)
        startRideDemoIfAsked()
        if ProcessInfo.processInfo.arguments.contains("-jumpDemo") { playJumpDemo() }
        startOpeningIfFirstLaunch()
        startStoreSceneIfAsked()
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
        // Short (0.7.6, entry 58): the Lens key appears beside it in the same title row halfway through the melt, and
        // the long sentence was cut to "..." on an upright phone, harder in German and Russian.
        case .melt: return String(localized: "The Lens", comment: "Short status title while the table turns into the Physics Lens during the intro; must fit beside the Lens key in the title row")
        case .rewind: return String(localized: "Rewind")
        case .slowReplay: return String(localized: "Slow motion")
        case .explore: return lensOn ? String(localized: "Physics Lens") : String(localized: "Table")
        }
    }

    // MARK: Cold open

    func startColdOpen() {
        stage = .lead; stageTime = 0; time = 0; melt = 0; meltTarget = nil
        playing = true; chosenRate = nil
        lensReplayStartedByPlayer = false
        resetPacing()
    }

    // MARK: Menu

    /// Back to the main menu: pause whatever is on the table; Continue picks it up exactly where it was. Opening the
    /// menu during the first-launch opening ends the opening (the player has found the menu; it is not shown again).
    func openMenu() {
        // The best shot's replay hands the cleared table back first, so Continue returns to it (0.7.4).
        endBestReplay()
        // A guided Lens replay the player was watching ends here (0.7.5, plan 5b M-A). The table behind the menu is
        // frozen (advance returns early), so a Lens fading out through setLens alone would stay drawn behind the menu
        // and greet the player again on Continue. The Lens goes off the way its button turns it off, then the blend
        // is set straight to the table view, since the menu hides the fade anyway. Not during the intro's own slow
        // replay (stage is not explore; Continue picks it up), and not over a trick shot's or lesson's own
        // demonstration, which its card is still explaining.
        if stage == .explore, guided, !modeDemonstrationPlaying {
            setLens(false)
            melt = 0; meltTarget = nil
            resetPacing()
            restoreHeldRide()
        }
        playing = false
        menuOpen = true
        if openingStage != .none { finishOpening(showMenu: false) }
    }

    /// Continue: close the menu and leave the table as it was. The silent replay behind the menu stops being a
    /// backdrop: whatever it was doing carries on as the ordinary replay on the table.
    func closeMenu() {
        menuOpen = false
        menuBackdropPlaying = false
        // The intro paused by the menu plays on (0.7.5): openMenu stopped the clock, and the cold open has no Pause
        // state of its own, so leaving it stopped showed Play on a replay that looked paused and silenced the rolling
        // sound. Once on the ordinary table (explore) the replay stays as the player left it.
        if stage != .explore { playing = true }
    }

    /// Play: a fresh rack, ready for the player's own break. The view opens the aiming controls. The cue keeps the
    /// elevation the player last set: free play allows a raised cue (rules-games plan package 2 step 4).
    /// Always the pool table (0.7.5): Practice promises a rack and a break, so a table chosen earlier from the Tables
    /// list is put back to the pool table first; the Tables list is how another table is played.
    func startGame() {
        closeAllLists()
        endPoolTableModes()
        lessonModeStorage?.end()
        strokeDrillStorage?.end()
        leaveMatch()
        returnToPoolTable()
        menuOpen = false
        gameInProgress = true
        panelAfterBreakDue = false
        rerack()
        setLens(false)
    }

    /// Watch the break: the showpiece opening, with the slow-motion Physics Lens replay, from the start. Always the
    /// pool table's opening (0.7.5): it is the intro the menu names, whatever table was chosen before.
    func watchBreak() {
        closeAllLists()
        endPoolTableModes()
        strokeDrillStorage?.end()
        cancelPendingSolve()
        lessonModeStorage?.end()
        leaveMatch()
        // Before the load below: solve(_:) writes physicsTable's numbers into the parameters, so swapping only the
        // opening shot would play the pool table's break on another table's physics.
        returnToPoolTable()
        endPlacement(); ballInHand = .none; undoStep = nil
        menuOpen = false
        gameInProgress = true
        panelAfterBreakDue = false
        // Your shot closes as the intro starts (0.7.6, entry 56): left open from a game, it squeezed the table over a
        // break nothing can be aimed at, snapped shut at the slow replay and sprang open again over the intro's end card.
        requestShotPanel(.close)
        // 0.7.4: a mode start for the highlight memory, and Watch the intro's end gets its card (noteIntroEnded).
        startHighlightRack()
        introWatchArmed = true
        // The showpiece break, on the pool table since 0.7.5 (returnToPoolTable above; before that another chosen table
        // played its own default shot here). Always the default generation (classic): the opening is authored on it.
        load(solve(physicsTable.openingShot, classic: true), showpiece: true)
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
        // A stroke while Watch your best shot replays is played on the cleared table, not the replayed shot's (0.7.4).
        endBestReplay()
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
        // The ball's launch speed for this swing with the cue the game picked for the break (exactly `power` with the
        // house cue; power is the swing, so a heavier break cue sends the ball faster).
        let launch = cueInHand.launchSpeed(forPower: power)
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
        // A fresh rack: free play's highlight memory for the rack starts again (0.7.4). Below the guard: a match racks
        // itself and keeps its own memory (startMatch resets free play's).
        startHighlightRack()
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
        // A stroke while Watch your best shot replays is struck from the cleared table: `layout` meanwhile holds where
        // the replayed shot's balls stopped, and striking from it would carry that old table into this rack (0.7.4).
        endBestReplay()
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
        // The launch speed for this swing with the cue the game picked: exactly shotPower with the house cue. The cue
        // is struck at strikeElevation: the player's angle, raised to clear any ball under the cue outside the
        // authored modes (plan item 23), so a jacked-up stroke dips and swerves as it would on a real table.
        var input = NextShot.shot(from: layout, direction: Vec2(cos(a), sin(a)),
                                  speed: cueInHand.launchSpeed(forPower: shotPower),
                                  tipUp: shotTipUp, tipSide: shotTipSide, seed: seed,
                                  elevation: strikeElevation, ballIndex: strikeBall)
        // The player's stroke drifts the strike before it is solved; a demonstration or scripted shot is struck clean.
        var delivery = strokeDue ? strokeDelivery(chosenUp: shotTipUp, chosenSide: shotTipSide) : nil
        delivery?.apply(to: &input.strike, ballRadius: physicsTable.parameters.ballRadius)
        // A kept what-if future replaces the strike only when nothing was touched since Keep: the controls read exactly
        // as kept and no new finger stroke was measured. Then the exact input the what-if solved (and its stroke) is
        // struck, so the future plays as it was shown. Any touch, or any other shot, uses it up either way.
        if let k = keptStrike, k.controls == controlValues, pendingStroke == nil { input = k.input; delivery = k.delivery }
        keptStrike = nil
        // The attempt keeps the player's own angle (shotElevation) as its setting, while its `input` holds the raised
        // strike. A retry puts the player's angle back, and the same layout and aim raise it by the same clearing, so
        // an untouched retry repeats exactly; recording the raised angle instead would leave the cue-angle control
        // showing an angle the player never chose, and keep it raised after they aim along a clear line.
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
        // 0.7.7 achievements: whose stroke this is, captured here before the solve starts (the computer's computerActing
        // and a mode's .watching are still set now; a background solve lands after they are cleared).
        achievements.strikeStarted(byPerson: achievementStrikeIsPersons)
        // Ball in hand is used up by the stroke; the shot's outcome (a scratch, a match's ruling) sets it again.
        ballInHand = BallInHand.none
        // The stroke measured for this strike, and its bridge, are used up; the next one is measured afresh.
        pendingStroke = nil
        strokeBridge = nil
        // An accepted strike: any refusal line goes, and fireStroke can see that something was struck.
        strikeSerial += 1
        lastRefusal = nil
        rulingWanted = false
        // A break the player fired closes the shot panel (the cold open or the replay takes the screen); it is asked
        // to open again once the balls stop on their turn. The first break of the opening has its own card instead.
        if settings.isBreak, strokeDue, openingStage == .none { panelAfterBreakDue = true }
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
        rulingWanted = false
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
        // Every shot and every break the player strikes plays at real speed in the ordinary view, the Lens left as the
        // player had it (plan item 14 for matches; 0.7.1 for every break: the Boss found a player's own break turning
        // into the slow Lens replay with its long cards far too much). The Lens is one tap away; Watch the intro keeps
        // the full slowed-down opening.
        stage = .explore; stageTime = 0; time = 0; playing = true
        chosenRate = 1; displayRate = 1
        meltTarget = melt > 0.5 ? 1 : nil
        if let m = match {
            m.shotLoaded(version: timelineVersion, start: prepared.input.positions)
            // See the ruling was pressed while this shot was being solved: the ruling comes at once.
            if rulingWanted {
                rulingWanted = false
                skipToResult()
            }
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
        // 0.7.4: last, so everything above is exactly as before. Judged only once the opening is over, outside the
        // authored modes and the drill (judgeHighlight's own guard); the first break of a first launch never is.
        judgeHighlight(tl, isBreak: s.isBreak)
        // 0.7.7 bullet-time: after the judge (so freePlayBreaksStruck already counts this break). The turn is still the
        // shooter's here; load() has just built this shot's ridePlan, so rideActive is this shot's. Ride, the Lens
        // and the rest are checked here so a freeze that could never play does not use up the ration; frame() in
        // advance repeats them for anything that changes after the strike. freePlay is judgeHighlight's own test.
        // (Split into small terms so each line reads, and the type checker never has a long chain to solve.)
        let noMode: Bool = lessonModeStorage?.isActive != true && strokeDrillStorage?.isActive != true
        // Bar billiards' clock would pay for the slow-down. Written with map so the one optional level is plain.
        let noClock: Bool = match.map { $0.state.clockRemaining == nil } ?? true
        let noLensOrRide: Bool = !rideActive && melt < 0.02 && meltTarget == nil
        let bulletOpen: Bool = openingStage == .none && noMode && noClock && whatIfStorage?.isOpen != true && noLensOrRide
        let computerShot: Bool = match.map { $0.isComputer($0.state.turn) } ?? false
        let bulletFreePlay: Bool = match == nil && !authoredModeUp && strokeDrillStorage?.isActive != true
        bulletTime.arm(timeline: tl, facts: shotFacts, captions: captions, isBreak: s.isBreak, version: timelineVersion,
                       gate: BulletGate(open: bulletOpen, computerShot: computerShot, freePlay: bulletFreePlay,
                                        freePlayBreaks: freePlayBreaksStruck))
        // 0.7.7 achievements: the shot is read for achievements. Unlike judgeHighlight this runs in every mode (trick
        // shots, lessons, Behind the 8-Ball, matches, the drill, the opening); the book itself skips strokes the game
        // played for the player, and the opening earns quietly.
        if let attempt = currentAttempt, let facts = shotFacts {
            achievements.noteShot(AchievementShotContext(timeline: tl, facts: facts, captions: captions, table: solvedTable,
                                                         isBreak: s.isBreak, freePlay: achievementFreePlay,
                                                         attempt: attempt),
                                  version: timelineVersion, quiet: openingStage != .none)
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
    /// Ride is on and this shot can be ridden (a still table or an unstruck ball has nothing to follow).
    var rideActive: Bool { rideOn && ridePlan.rideable && (stage == .explore || stage == .slowReplay) }

    /// Switch the Ride camera on or off. The trick-shot mode calls this before playing a shot so it plays riding.
    /// Switching it on when the shot on screen has already finished plays that shot again from the start, so the
    /// ride is seen instead of nothing visibly happening.
    func setRide(_ on: Bool) {
        // An explicit choice (the player's button, a mode's own camera) replaces any Ride held off for a guided
        // replay: there is nothing left to give back (0.7.5).
        rideHeldForGuidedReplay = false
        rideOn = on
        // Any act in progress ends (a rewind already under way carries on: Watch it turns Ride off just before it).
        // Switched on mid-shot, advance() picks the act up from the clock (the roll, no mount).
        if rideAct != .rewind { resetRideActs() }
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

    // MARK: The ride's acts (0.7.6 stream ride, plans/22-Nov-2026-ride-handover-plan.md)
    //
    // How a ride runs, frame by frame (advance, the ordinary table stage, not guided):
    //  - The clock at the strike with Ride on: the mount starts and holds the clock (it waits while paused).
    //  - Ride switched on mid-shot, or the clock moved by hand: the roll (or landed, past the rise); no mount.
    //  - The roll steps the clock at the ride's slow-motion curve, deepened toward a stop on the hit; crossing one of
    //    the ride's two beats stops exactly on it and holds (its own reading time, Continue ends it); reaching the
    //    rise stops there and runs the dismount; then landed, and the shot plays out at the ordinary speed.
    //  - The pattern is the intro's freeze, melt and rewind: real-time counters while the clock stands still.

    /// What the camera reads each frame: the act and its progress (TableStage hands it to TableScene.rideCue).
    var rideCue: RideCue { RideCue(act: rideAct, progress: rideActProgress) }

    /// The ride's two beats for the recording on screen (RideBeats), worked out once per recording.
    var rideBeats: [RideBeat] {
        if rideBeatsMemo.version != timelineVersion {
            rideBeatsMemo = (timelineVersion, RideBeats.make(plan: ridePlan, timeline: timeline, captions: captions))
        }
        return rideBeatsMemo.beats
    }

    /// True while the title row shows the ride's map and the overlay its rings: from the mount to the end of the
    /// dismount.
    var rideShowsGuides: Bool {
        switch rideAct {
        case .mount, .roll, .hold, .dismount: return true
        case .none, .landed, .rewind: return false
        }
    }

    /// The ride's words for the title row's status slot, nil when the ride has nothing to say (plan work package 4).
    var rideStatus: String? {
        switch rideAct {
        case .none, .landed: return nil
        case .mount, .hold: return RideWords.riding(ball: ridePlan.cueBall, table: solvedTable)
        // The first ride ever says once how to leave it (work package 9).
        case .roll: return rideTipThisRide ? RideWords.tip : RideWords.riding(ball: ridePlan.cueBall, table: solvedTable)
        case .dismount: return RideWords.backToTable
        case .rewind: return RideWords.slowedDown
        }
    }

    /// True while the clock is held on one of the ride's beats.
    private var rideHolding: Bool { rideAct == .hold && rideHeldBeat != nil }

    /// The caption of the ride beat being held (nil when none is held, or the beat has nothing to read).
    private var rideHeldCaption: Caption? {
        guard rideAct == .hold, let i = rideHeldBeat, rideBeats.indices.contains(i) else { return nil }
        return rideBeats[i].caption
    }

    /// Back to no act: the next frame starts the ride again from the clock (a mount at the strike). Called when a new
    /// recording loads and wherever the clock is sent back to the start to play again.
    private func resetRideActs() {
        if rideAct != .none { rideAct = .none }
        rideActProgress = 0
        rideActElapsed = 0
        rideHeldBeat = nil
        if rideTipThisRide { rideTipThisRide = false }
    }

    /// The clock was moved by hand (a scrub, Skip to result): no mount and no hold, just the act that belongs to that
    /// clock, so the camera there is a function of the clock alone. A jump during the rewind skips the rest of it and
    /// leaves the slow Lens replay it was leading to, from where the clock now is (no fixed speed, the Lens up), so a
    /// trick shot's explanation is not lost to an impatient scrub.
    private func settleRideActsAfterJump() {
        if rideAct == .rewind {
            resetRideActs()
            chosenRate = nil
            meltTarget = 1
            return
        }
        guard rideActive else { resetRideActs(); return }
        rideHeldBeat = nil
        rideActProgress = 0
        rideActElapsed = 0
        let next: RideAct = time >= ridePlan.riseStart ? .landed : .roll
        if rideAct != next { rideAct = next }
    }

    /// Start an act that holds the clock (the mount, the dismount, the rewind), with its real-time length.
    private func beginRideAct(_ act: RideAct) {
        rideAct = act
        rideActElapsed = 0
        rideActProgress = 0
        switch act {
        case .mount:
            // The first ride ever: a slower mount, and the tip on its roll (RideTip, work package 9).
            let first = !RideTip.shown
            if rideTipThisRide != first { rideTipThisRide = first }
            rideActLength = first ? RideTiming.firstMount : RideTiming.mount
        case .dismount: rideActLength = RideTiming.dismount
        case .rewind: rideActLength = RideTiming.rewind
        case .none, .roll, .hold, .landed: rideActLength = 1
        }
    }

    /// One frame of a ride. Returns true when the ride drove (or held) the clock itself this frame, false when the
    /// ordinary step should run (no ride, or the ride has landed).
    private func advanceRide(_ dt: Double) -> Bool {
        guard rideActive else {
            // Ride went off (or this shot cannot be ridden): any act ends; the camera eases out on its own.
            if rideAct != .none { resetRideActs() }
            return false
        }
        if rideAct == .none {
            // A ride starts: at the strike with a mount, otherwise from wherever the clock is.
            if time <= 1e-9 { beginRideAct(.mount) } else { rideAct = time >= ridePlan.riseStart ? .landed : .roll }
        }
        switch rideAct {
        case .mount, .dismount:
            displayRate = 0
            // Paused, the move waits where it is.
            guard playing else { return true }
            rideActElapsed += dt
            rideActProgress = min(1, rideActElapsed / max(0.01, rideActLength))
            if rideActProgress >= 1 {
                if rideAct == .mount {
                    rideAct = .roll
                    // The tip is on screen from now: remembered, so it never shows again.
                    if rideTipThisRide { RideTip.shown = true }
                } else {
                    rideAct = .landed
                }
                rideActProgress = 0
                rideActElapsed = 0
            }
            return true
        case .hold:
            displayRate = 0
            guard playing else { return true }
            guard rideHeldBeat != nil else { rideAct = .roll; return true }
            holdElapsed += dt
            if let id = heldCaptionID, holdPagesApply(caption: id) { followHoldPage() }
            if holdElapsed >= holdDwell { finishRideHold() }
            return true
        case .roll:
            if playing { stepRide(dt) } else { displayRate = (chosenRate ?? 1) * ridePlan.rateFactor(at: time) }
            return true
        case .landed, .none, .rewind:
            return false
        }
    }

    /// The roll: the clock at the ride's slow-motion curve (times any speed the player picked), stopping exactly on a
    /// ride beat it reaches (and holding there) or on the start of the rise (and running the dismount).
    private func stepRide(_ dt: Double) {
        var rate = (chosenRate ?? 1) * ridePlan.rateFactor(at: time)
        // Slow motion deepens toward a stop on the hit (Act 3): over the last quarter second of clock before the
        // first contact the speed eases down to a quarter of the ride's slow motion, so the stop on it is gentle.
        // Never zero, so the clock always reaches it.
        if let c = ridePlan.contactTime, time < c {
            rate *= 0.25 + 0.75 * RidePlan.smooth((c - time) / 0.25)
        }
        displayRate = rate
        let old = time
        var target = min(duration, time + dt * rate)
        var hold: Int?
        // A ride beat crossed this frame (strictly after the clock: a beat the clock sits on has just been held).
        if let i = rideBeats.firstIndex(where: { $0.time > old + Self.beatTolerance && $0.time <= target }) {
            target = rideBeats[i].time
            hold = i
        }
        var dismount = false
        if hold == nil, old < ridePlan.riseStart, target >= ridePlan.riseStart {
            target = ridePlan.riseStart
            dismount = true
        }
        time = target
        // Sound and touch for everything crossed, the hit included, so it is heard as the clock stops on it.
        fireSounds(from: old, to: time)
        if let hold { beginRideHold(hold) } else if dismount { beginRideAct(.dismount) }
        if time >= duration, hold == nil, !dismount { playing = false }
    }

    /// Hold the clock on ride beat `i`: its reading time when the explanation card is up (the card shows with the
    /// Lens, and Explanations on), otherwise a short still beat. The guided hold's counter, length and pages are used
    /// (a ride is never guided at the same time).
    private func beginRideHold(_ i: Int) {
        rideHeldBeat = i
        rideAct = .hold
        holdElapsed = 0
        holdPage = 0
        let explanations = UserDefaults.standard.object(forKey: GameSettings.explanationsKey) as? Bool ?? true
        if explanations, lensOn, rideBeats.indices.contains(i), let c = rideBeats[i].caption {
            holdDwell = pacePlan.dwell(for: c.detail)
        } else {
            holdDwell = RideTiming.stillHold
        }
    }

    /// Let go of the ride's held beat: the roll plays on from it (both balls leaving slowly on the ride's curve).
    private func finishRideHold() {
        rideHeldBeat = nil
        holdElapsed = 0
        if rideAct == .hold { rideAct = .roll }
    }

    /// After a trick shot's Watch it (plan Act 4): the next scene is announced, "Now the same shot, slowed down",
    /// and the clock runs back to the start over the intro's rewind time while the Lens comes in; then the slow Lens
    /// replay starts (replay(withLens:)). Called instead of replay(withLens: true) right after the answer has played,
    /// so it never starts in the same frame. With nothing to rewind (the clock at the start, the menu up) it is the
    /// plain Lens replay.
    func replayInLensAfterRide() {
        guard stage == .explore, time > 0.05, !menuOpen else { replay(withLens: true); return }
        resetPacing()
        beginRideAct(.rewind)
        rideRewindFrom = time
        meltTarget = 1
        playing = true
    }

    /// One frame of the rewind: the clock eases back to the start (set directly, like a scrub, so nothing sounds),
    /// then the Lens replay starts from the strike.
    private func advanceRideRewind(_ dt: Double) {
        displayRate = 0
        guard playing else { return }
        rideActElapsed += dt
        let x = min(1, rideActElapsed / max(0.01, rideActLength))
        rideActProgress = x
        time = rideRewindFrom * (1 - RidePlan.smooth(x))
        if x >= 1 { replay(withLens: true) }
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
        // Behind the menu nothing moves (0.7.5): a key or controller button reaching here past the menu does nothing.
        guard !menuOpen else { return }
        // While Watch your best shot replays, the attempt on screen is the replayed one; the retry is of the shot that
        // cleared the table, so that goes back first (0.7.4).
        endBestReplay()
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

    /// The lesson pass shot's "Back to the lesson's stroke" (plan item 11): exactly as tryAgain() (the same start and
    /// seed, the last try kept as the ghost and compared with the next), but with `settings` (the lesson's reference)
    /// in place of the last try's own. The settings are written directly, so a lesson lock cannot half-apply them.
    /// The last try's finger stroke is not brought back: it belonged to the player's settings, not these. For a
    /// break, `settings.aim` is metres off the apex ball, as TrickSettings says.
    func tryAgain(restoring settings: TrickSettings) {
        // The menu check too, so the settings are never written over a retry tryAgain() refused (0.7.5).
        guard !menuOpen, let attempt = currentAttempt, aimReady, match == nil else { return }
        tryAgain()
        writeRetrySettings(settings, isBreak: attempt.isBreak)
        pendingStroke = nil
    }

    /// Write `settings` into the controls directly (not through the active setters, so a lesson lock cannot half-apply
    /// them): the break's controls when `isBreak`, the shot's otherwise. For a break, `settings.aim` is metres off the
    /// apex ball and is clamped to the break's aim limit. Shared by tryAgain(restoring:) and keepFuture.
    func writeRetrySettings(_ settings: TrickSettings, isBreak: Bool) {
        if isBreak {
            aimOffset = min(max(settings.aim, -Self.breakAimLimit), Self.breakAimLimit)
            power = settings.power; tipHeight = settings.tipUp; breakTipSide = settings.tipSide
        } else {
            aimDegrees = settings.aim; shotPower = settings.power
            shotTipUp = settings.tipUp; shotTipSide = settings.tipSide
            shotElevation = settings.elevation ?? 0
        }
    }

    /// Keep a what-if future, after a retry was armed from the attempt it forked (ghost is that attempt): the future's
    /// settings go in the controls and its exact strike is armed for the next Shoot.
    func keepFuture(_ settings: TrickSettings, input: ShotInput, delivery: StrokeDelivery?) {
        writeRetrySettings(settings, isBreak: false)
        pendingStroke = nil
        keptStrike = KeptStrike(input: input, delivery: delivery, controls: controlValues)
    }

    /// A what-if future the player kept: Shoot with the controls exactly as kept, and no new finger stroke, strikes this
    /// input, so the kept future plays exactly as it was shown. Used up by the next strike; cleared by clearAttempts.
    struct KeptStrike { let input: ShotInput; let delivery: StrokeDelivery?; let controls: ControlValues }
    @ObservationIgnored var keptStrike: KeptStrike?

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
        attemptVersion = timelineVersion
        strokeDrillStorage?.attemptRecorded(attempt)
    }

    private func clearAttempts() {
        currentAttempt = nil
        keptStrike = nil
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

    /// The steepest cue angle any route may set, as a sine: 0.995, about 84 degrees, where the cue rig stops pitching
    /// the cue (the same limit CueAngleMenu clamps to).
    static let maxElevation = 0.995

    /// The cue's angle for the next shot (sine), with the lesson lock applied like power, tip and aim (plan item 12):
    /// the setter does nothing unless the lesson leaves the cue angle open, a raised cue is allowed (not a break) and
    /// the person may act. Every player-facing writer uses it (the Pencil, the cue-angle control); the authored modes
    /// keep writing shotElevation directly. Reads 0 while racked: a break is struck level.
    var activeElevation: Double {
        get { racked ? 0 : shotElevation }
        set {
            guard openControls.contains(.elevation), elevationAllowed, personMayChangeControls else { return }
            shotElevation = min(max(newValue, 0), Self.maxElevation)
        }
    }

    /// False while the computer has the table (any stage of its turn): the person's aim, power, tip and cue angle
    /// refuse every change, from every input route, as a lesson lock does. The computer's own stroke writes the stored
    /// values directly (stageComputerStroke), so it is never refused here.
    private var personMayChangeControls: Bool { computerTurnStage == .none }

    /// Launch speed for the next strike, metres per second, and the range it may take.
    var powerRange: ClosedRange<Double> { racked ? PlayerShotSpeed.rackBreak : PlayerShotSpeed.ordinary }
    var activePower: Double {
        get { racked ? power : shotPower }
        set {
            guard openControls.contains(.power), personMayChangeControls else { return }
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
        set {
            guard openControls.contains(.tipUp), personMayChangeControls else { return }
            if racked { tipHeight = newValue } else { shotTipUp = newValue }
        }
    }
    var activeTipSide: Double {
        get { racked ? breakTipSide : shotTipSide }
        set {
            guard openControls.contains(.tipSide), personMayChangeControls else { return }
            if racked { breakTipSide = newValue } else { shotTipSide = newValue }
        }
    }

    /// Aim so the cue travels through a spot on the table. For a shot that is any direction; for the break the
    /// strike is always at the rack, so the spot only chooses how far off the apex ball to hit.
    func aim(toward point: Vec2) {
        guard layout.count == 16, openControls.contains(.aim), personMayChangeControls else { return }
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
        guard openControls.contains(.aim), personMayChangeControls else { return }
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
        settleRideActsAfterJump()
    }

    /// Break or shoot, whichever is next, reporting what happened (plan items 2 and 13). Every player route uses it:
    /// the stroke's push, Shoot, Return, the Mac menu, the controller, VoiceOver. A ball lifted for placing is put down
    /// first where it is, if that spot is legal. In eight-ball with no call made the suggested call is adopted and
    /// played (the ruling card says it was the suggestion); with no suggestion the stroke is refused with .noCall. On
    /// any refusal the reason is recorded (lastRefusal) and nothing is struck.
    @discardableResult
    func fireStroke() -> StrokeOutcome {
        // Behind the menu (0.7.5): a backstop for any route that reaches here while the menu is up (a key, the
        // controller, the Mac menu bar). Nothing is struck and no refusal is recorded, so no card pulses behind the
        // menu; the outcome only tells the caller nothing was struck (every caller checks for .breakStruck). Not part
        // of strokeRefusal on purpose: that drives the Shoot button's state and the spoken reasons.
        if menuOpen { return .refused(.replayPlaying) }
        if let reason = strokeRefusal { return refused(reason) }
        if let m = match, m.mustCall, m.currentCall == nil, !m.adoptSuggestedCall() { return refused(.noCall) }
        if placingCueBall, !confirmCueBallPlacement() { return refused(.ballInHandNotPlaced) }
        let wasBreak = racked
        let before = strikeSerial
        // The player's own stroke: the strike it starts is delivered with the stroke's drift (StrokeModel).
        strokeDue = true
        defer { strokeDue = false }
        if wasBreak { breakNow() } else { shootNow() }
        // breakNow and shootNow keep their own guards; one that turned the stroke away still gets a reason on the card.
        guard strikeSerial != before else { return refused(strokeRefusal ?? .replayPlaying) }
        return wasBreak ? .breakStruck : .shotStruck
    }

    /// Kept for existing callers: true when the stroke fired was the break (the cue ball's cold open, or a match
    /// break's replay, takes over the screen, so the aiming controls close).
    @discardableResult
    func fire() -> Bool { fireStroke() == .breakStruck }

    private func refused(_ reason: ShotRefusal) -> StrokeOutcome {
        refuse(reason)
        return .refused(reason)
    }

    /// Why a stroke would be refused if fired now, or nil when one may be struck. Asked BEFORE a stroke starts (touch
    /// at touch-down on the cue ball; the shot panel, the Mac menu and the controller to disable Shoot and say why).
    /// Every case except .backswingTooShort, which only the input sees. .noCall only when no suggestion exists, because
    /// fireStroke plays the suggestion otherwise.
    var strokeRefusal: ShotRefusal? {
        if isSolving { return .stillSolving }
        if let m = match {
            if m.state.isOver || m.phase == .over { return .gameOver }
            if !m.personMayAct || stagingActive { return .notYourTurn }
        }
        if !aimReady { return .replayPlaying }
        if let m = match {
            if m.phase != .aiming { return .rulingPending }
            if m.state.pendingChoice != nil { return .choicePending }
        }
        if placingCueBall {
            guard let c = cueBallCandidate, placementSpot(c) == .legal else { return .ballInHandNotPlaced }
        }
        if let m = match, m.mustCall, m.currentCall == nil, m.suggestedCall == nil { return .noCall }
        return nil
    }

    /// Input code reports a refusal it decided itself (the touch stroke's short backswing).
    func refuse(_ reason: ShotRefusal) {
        lastRefusal = reason
        refusalSerial += 1
    }

    func clearRefusal() { lastRefusal = nil }

    // MARK: Aim snapshot and lifting balls (contract 2.2, plan items 7 and 9)

    /// The aim and power now, taken when a touch lands, so a touch that turns out to be a pinch, a pan or a double tap
    /// can put them back exactly.
    func aimSnapshot() -> AimSnapshot {
        AimSnapshot(racked: racked, aimDegrees: aimDegrees, aimOffset: aimOffset, power: activePower,
                    strokeBridge: strokeBridge)
    }

    /// Put a snapshot back. Written directly, not through the locked setters, so a lesson lock cannot half-restore it
    /// (the snapshot only ever holds values the lock allowed). Ignored if the table changed meanwhile (a rack became a
    /// shot or the other way round), when the stored values would land on the wrong stroke.
    func restoreAim(_ snapshot: AimSnapshot) {
        guard snapshot.racked == racked else { return }
        aimDegrees = snapshot.aimDegrees
        aimOffset = snapshot.aimOffset
        if racked { power = snapshot.power } else { shotPower = snapshot.power }
        strokeBridge = snapshot.strokeBridge
    }

    /// The ball at a table point that may be lifted now, nearest first within `radius` metres; nil when none. In free
    /// play any ball on the table; in a match only the striking ball, and only with ball in hand (canPlaceCueBall says
    /// when lifting is allowed at all). A ball already lifted counts where it is held now. Touch and pointer use the
    /// same call, then beginPlacingBall(_:), moveCueBallCandidate(to:), confirmCueBallPlacement() and cancelPlacement().
    func liftableBall(near point: Vec2, within radius: Double) -> Int? {
        guard canPlaceCueBall, layout.count == 16 else { return nil }
        var best: (ball: Int, distance: Double)?
        func consider(_ ball: Int, at p: Vec2) {
            let d = (p - point).length
            guard d <= radius else { return }
            if best == nil || d < best!.distance { best = (ball, d) }
        }
        if placingCueBall, let held = cueBallCandidate { consider(placingBall, at: held) }
        let candidates = match == nil ? Array(layout.indices) : [strikeBall]
        for ball in candidates where !(placingCueBall && ball == placingBall) && NextShot.isOnTable(layout[ball]) {
            consider(ball, at: layout[ball])
        }
        return best?.ball
    }

    /// Point the cue at the nearest ball still on the table. In a match, at the nearest ball the rules let the shooter
    /// hit first (five-pin's other ball, eight-ball's group, nine-ball's lowest), so the opening aim never points
    /// straight at a foul (0.7.5 coordinator: five-pin opened aimed at the red).
    func aimAtNearestBall() {
        guard layout.count == 16 else { return }
        let from = strikeBall
        if let m = match {
            let legal = m.targetBall(for: m.state.turn).map { [$0] }
                ?? OpponentPlanner.legalTargets(rules: m.rules, state: m.state)
            let near = legal.filter { $0 != from && layout.indices.contains($0) && NextShot.isOnTable(layout[$0]) }
                .min { (layout[$0] - layout[from]).lengthSquared < (layout[$1] - layout[from]).lengthSquared }
            if let near, (layout[near] - layout[from]).lengthSquared > 0 {
                let d = (layout[near] - layout[from]).normalized
                aimDegrees = atan2(d.y, d.x) * 180 / Double.pi
                return
            }
        }
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

    /// Put a recording on screen. `showpiece` is true only for the showpiece opening (Watch the intro), whose replay
    /// holds the opening's beats. Anything loaded ends the menu's backdrop: a table is going on screen.
    private func load(_ tl: Timeline, showpiece: Bool = false) {
        // A new recording, a surface change, Try again, a menu choice: the what-if never outlives the recording it forked.
        whatIfStorage?.close()
        // A guided Lens replay that held Ride off is left the moment anything else goes on screen: Ride comes back.
        restoreHeldRide()
        // Anything else going on the table ends Watch your best shot's replay; the replay's own loads say so (0.7.4).
        if replayingBest, !loadingKeptRecording { abandonBestReplay() }
        // Anything but the showpiece going on screen means Watch the intro was left before its end (0.7.4).
        if !showpiece { introWatchArmed = false }
        menuBackdropPlaying = false
        lensReplayStartedByPlayer = false
        // A new recording has no signature until its owner (a trick shot, a highlight) sets one (0.7.4).
        paceSignature = []
        showpieceOnScreen = showpiece
        adoptLayout(after: tl)
        timeline = tl
        // The solved strike too (lens stream, 0.7.0): a raised strike that did not hop carries its angle nowhere else.
        // The solved table and the striking ball too (0.7.5), so captions can name balls the way that table does.
        captions = CaptionEngine.make(from: tl, surface: solvedSurface, strike: lastInput?.strike,
                                      table: solvedTable, striker: lastInput?.strike.ballIndex)
        pacePlan = PacePlan(captions: captions, timeline: tl, style: paceStyle, signature: paceSignature)
        // Ride follows the ball that was struck (bumper pool, bar billiards and five-pin's second seat strike others).
        ridePlan = RidePlan(tl, cueBall: lastInput?.strike.ballIndex ?? 0)
        readShot(tl)
        timelineVersion += 1
        resetPacing()
        // A new recording starts its own ride (the mount, if Ride is on) from its strike.
        resetRideActs()
    }

    /// Which beats the recording on screen holds: the first launch's few (the showpiece and the player's own first
    /// break, while the opening runs), the opening's with its headline moments (the showpiece watched again), or the
    /// usual ones (plan items 6 and 55).
    private var paceStyle: PacePlan.Style {
        if openingStage != .none { return .firstLaunch }
        return showpieceOnScreen ? .opening : .standard
    }

    /// Re-make the pace plan of the recording on screen after its style changed (the first launch starting).
    private func refreshPacePlan() {
        pacePlan = PacePlan(captions: captions, timeline: timeline, style: paceStyle, signature: paceSignature)
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
        // End the best shot's replay first (0.7.4); the rack below replaces the cleared table anyway.
        endBestReplay()
        menuOpen = false
        rerack()
        setLens(false)
    }

    var canUndo: Bool { undoStep != nil && match == nil && !authoredModeUp && !isSolving }

    /// One step back: the table and the settings from before the last free-play shot (a break goes back to its rack).
    func undoLastShot() {
        guard canUndo, let u = undoStep else { return }
        // Undo acts on the cleared table, so the best shot's replay hands it back first (0.7.4). A best shot played
        // after the table being undone to is dropped, and the rack may sound Table cleared again.
        endBestReplay()
        if let best = bestShot, best.rackShot > u.shots { bestShot = nil }
        clearedChimePlayed = false
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
        closeAllLists()
        strokeDrillStorage?.end()
        cancelPendingSolve()
        lessonModeStorage?.end()
        trickMode.end()
        eightBallMode.end()
        menuOpen = false
        gameInProgress = true
        panelAfterBreakDue = false
        endPlacement(); ballInHand = .none; undoStep = nil
        startHighlightRack()
        let m = MatchMode(model: self, kind: kind, players: players, computer: computer)
        match = m
        m.start()
        setLens(false)
    }

    /// True when a match is saved on the device ("Continue match").
    var hasSavedMatch: Bool { savedMatchExists }

    /// True when this game has a save of its own (0.7.5: one save per game). Read on a tap, not every frame: it reads
    /// the file. A new game of this kind replaces that save, so the menus ask first only then.
    func hasSavedMatch(_ kind: MatchKind) -> Bool { MatchMode.savedSummary(for: kind) != nil }

    /// Back to the match: the live one if there is one, otherwise the saved one from the device. Returns whether a
    /// match is up afterwards (false when no save could be loaded), so the menu stays open when Continue fails.
    /// A save that does not load also clears the Continue row (noteMatchSave), so it is not offered again.
    /// With a kind, that game's save (the live match when it is that game); without, the live match or the most
    /// recently saved game. A live match of another game is left first; its save stays for later.
    @discardableResult func continueSavedMatch(kind: MatchKind? = nil) -> Bool {
        closeAllLists()
        if let live = match, kind == nil || live.state.kind == kind { closeMenu(); return true }
        guard let saved = MatchMode.loadSaved(kind: kind) else { noteMatchSave(exists: false); return false }
        leaveMatch()
        panelAfterBreakDue = false
        strokeDrillStorage?.end()
        cancelPendingSolve()
        lessonModeStorage?.end()
        trickMode.end()
        eightBallMode.end()
        menuOpen = false
        gameInProgress = true
        endPlacement(); ballInHand = .none; undoStep = nil
        startHighlightRack()
        let m = MatchMode(model: self, restoring: saved)
        match = m
        m.resume()
        // A resumed game aims at a ball the rules allow, as a fresh turn does (0.7.5 coordinator: it came back aimed
        // wherever the last stroke left the cue).
        if !m.isComputer(m.state.turn) { aimAtNearestBall() }
        setLens(false)
        return match != nil
    }

    /// End the match for good: its save is removed and free play's rack goes back on.
    func endMatch() {
        if let kind = match?.state.kind { MatchMode.deleteSave(kind: kind) }
        noteMatchSave(exists: false)
        leaveMatch()
        rerack()
    }

    /// Step out of a live match into something else, keeping its save so the menu can offer it again.
    private func leaveMatch() {
        // Stop the computer's search first, so a think still running cannot come back to a match that is gone.
        match?.opponent?.cancel()
        guard match != nil else { return }
        abandonStaging()
        cancelPendingSolve()
        match = nil
        endPlacement(); ballInHand = .none
    }

    /// MatchMode reports whether a save exists after each write or removal; the Continue row's summary is read again.
    /// With one save per game (0.7.5) a removed save may leave another game's, so the row is read again either way;
    /// `exists` is kept for the callers and no longer decides.
    func noteMatchSave(exists: Bool) {
        savedMatchSummary = MatchMode.savedSummary()
    }

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

    /// The computer's stroke, as MatchOpponent asked for it before 0.7.0. It now stages the stroke like
    /// stageComputerStroke (the instant strike, with the cue jumping to its line and the balls already moving, was the
    /// freeze plan item 16 removes), so the computer lines up visibly whichever name its caller uses. Returns true when
    /// staging began; the strike follows on its own a beat later. Only while the match says the computer is acting.
    @discardableResult
    func playComputerStroke(placement: Vec2?, aimDegrees aim: Double, breakAimOffset: Double, power: Double,
                            tipUp: Double, tipSide: Double) -> Bool {
        guard let m = match, m.computerActing else { return false }
        return stageComputerStroke(placement: placement, aimDegrees: aim, breakAimOffset: breakAimOffset, power: power,
                                   tipUp: tipUp, tipSide: tipSide)
    }

    // MARK: The computer's turn, staged (plan item 16, contract 2.4)

    /// The computer's stroke between its plan and its strike: where the aim swings from and to, the stroke it will
    /// play, and the person's own settings to put back once it is struck.
    private struct ComputerStaging {
        let match: ObjectIdentifier
        let isBreak: Bool
        /// Degrees for a shot, metres off the apex ball for a break.
        let fromAim: Double
        let toAim: Double
        let power: Double
        let tipUp: Double
        let tipSide: Double
        /// The person's power, tip and cue angle (break values for a break), restored after the strike.
        let keptPower: Double
        let keptUp: Double
        let keptSide: Double
        let keptElevation: Double
        /// Real seconds since staging began; only counted while the table is live (advance stops behind the menu).
        var elapsed = 0.0
    }

    /// The beats of a staged computer stroke, real seconds. The swing is long enough for the eye to follow a line
    /// turning across the table (a quick glance takes about a fifth of a second; three of them is comfortable), the
    /// draw-back a little shorter, as a player's backswing is, and the stillness at full draw is the short pause a
    /// player makes before delivering. Together under two seconds, so the computer's turn never drags.
    static let computerSwingTime = 0.7
    static let computerDrawBackTime = 0.6
    static let computerSetTime = 0.25

    /// The computer's turn as the table shows it.
    var computerTurnStage: ComputerTurnStage {
        guard let m = match, m.hasComputer, !m.state.isOver else { return .none }
        if stagingActive { return .staging }
        switch m.phase {
        case .aiming:
            return m.computerSeatToAct != nil ? .thinking : .none
        case .ruling:
            // The ruling is in and the next decision is known while its card is still up: the computer may start
            // thinking now (MatchOpponent does), and the person's controls are not theirs.
            if let pending = m.state.pendingChoice { return m.isComputer(pending.chooser) ? .thinking : .none }
            return m.isComputer(m.state.turn) ? .thinking : .none
        case .shooting:
            // The turn moves on only when the shot is ruled, so the shooter is still the one whose turn it is.
            return m.isComputer(m.state.turn) ? .striking : .none
        case .handOver, .over:
            return .none
        }
    }

    /// False while the person may not act on the table: the computer's turn (any stage but .none) or a solve in
    /// flight. ShotPanel greys out, touch and pointer ignore the cloth, the controller and the Mac menu disable Shoot.
    var personControlsLive: Bool { computerTurnStage == .none && !isSolving }

    /// The computer's stroke, staged: places the cue ball (when it has ball in hand), then over the next beats swings
    /// the aim to `aimDegrees` (or the break's `breakAimOffset`), draws the cue back, and strikes, setting
    /// MatchMode.computerActing itself around the placement and the strike. Returns true when staging began; the strike
    /// follows on its own from advance(_:). The person's power, tip and cue angle are put back once it is struck, as
    /// playComputerStroke does. Replaces the instant playComputerStroke for MatchOpponent.
    @discardableResult
    func stageComputerStroke(placement: Vec2?, aimDegrees aim: Double, breakAimOffset: Double, power: Double,
                             tipUp: Double, tipSide: Double) -> Bool {
        guard let m = match, m.computerSeatToAct != nil, staging == nil, aimReady, !isSolving, !menuOpen,
              layout.count == 16 else { return false }
        let wasActing = m.computerActing
        m.computerActing = true
        if let spot = placement {
            if !placingCueBall { beginPlacingCueBall() }
            if placingCueBall {
                moveCueBallCandidate(to: spot)
                if !confirmCueBallPlacement() { cancelPlacement() }
            }
        } else if placingCueBall {
            cancelPlacement()
        }
        m.computerActing = wasActing
        let s: ComputerStaging
        if racked {
            s = ComputerStaging(match: ObjectIdentifier(m), isBreak: true, fromAim: aimOffset,
                                toAim: min(max(breakAimOffset, -Self.breakAimLimit), Self.breakAimLimit),
                                power: min(max(power, PlayerShotSpeed.rackBreak.lowerBound), PlayerShotSpeed.rackBreak.upperBound),
                                tipUp: tipUp, tipSide: tipSide,
                                keptPower: self.power, keptUp: tipHeight, keptSide: breakTipSide, keptElevation: shotElevation)
            tipHeight = tipUp; breakTipSide = tipSide
            self.power = PlayerShotSpeed.rackBreak.lowerBound
        } else {
            s = ComputerStaging(match: ObjectIdentifier(m), isBreak: false, fromAim: aimDegrees, toAim: aim,
                                power: min(max(power, PlayerShotSpeed.ordinary.lowerBound), PlayerShotSpeed.ordinary.upperBound),
                                tipUp: tipUp, tipSide: tipSide,
                                keptPower: shotPower, keptUp: shotTipUp, keptSide: shotTipSide, keptElevation: shotElevation)
            // The computer plays a level cue (its planner tries level strokes); the strike still clears any ball under
            // the cue (strikeElevation), as the person's would.
            shotTipUp = tipUp; shotTipSide = tipSide; shotElevation = 0
            // The cue starts close to the ball and draws back once the aim has swung (the 3D cue's pull-back follows
            // the power).
            shotPower = PlayerShotSpeed.ordinary.lowerBound
        }
        staging = s
        stagingActive = true
        return true
    }

    /// One frame of a staged computer stroke: the aim eases round to its choice, then the cue draws back to the
    /// stroke's power, then a short stillness, then the strike. Dropped (the person's settings put back) if anything
    /// moved the table on meanwhile: the match left, the turn changed, a solve or a replay started.
    private func advanceStaging(_ dt: Double) {
        guard var s = staging else { return }
        guard let m = match, ObjectIdentifier(m) == s.match, m.phase == .aiming, m.computerSeatToAct != nil,
              aimReady, !isSolving, layout.count == 16, racked == s.isBreak else {
            abandonStaging()
            return
        }
        s.elapsed += dt
        staging = s
        let swing = Self.smoothstep(s.elapsed / Self.computerSwingTime)
        if s.isBreak {
            aimOffset = s.fromAim + (s.toAim - s.fromAim) * swing
        } else {
            // The short way round: never a swing of more than half a turn.
            var delta = s.toAim - s.fromAim
            while delta > 180 { delta -= 360 }
            while delta < -180 { delta += 360 }
            var a = s.fromAim + delta * swing
            if a > 180 { a -= 360 } else if a < -180 { a += 360 }
            aimDegrees = a
        }
        let draw = Self.smoothstep((s.elapsed - Self.computerSwingTime) / Self.computerDrawBackTime)
        let low = s.isBreak ? PlayerShotSpeed.rackBreak.lowerBound : PlayerShotSpeed.ordinary.lowerBound
        let pulled = low + (s.power - low) * draw
        if s.isBreak { power = pulled } else { shotPower = pulled }
        if s.elapsed >= Self.computerSwingTime + Self.computerDrawBackTime + Self.computerSetTime { strikeStaged(s, m) }
    }

    /// The staged stroke's strike: exactly the planned aim and power, struck while the match knows the computer is
    /// acting, then the person's own settings back.
    private func strikeStaged(_ s: ComputerStaging, _ m: MatchMode) {
        staging = nil
        stagingActive = false
        if s.isBreak { aimOffset = s.toAim; power = s.power } else { aimDegrees = s.toAim; shotPower = s.power }
        let wasActing = m.computerActing
        m.computerActing = true
        if s.isBreak { breakNow() } else { shootNow() }
        m.computerActing = wasActing
        restoreKept(s)
        if m.phase != .shooting {
            // Not struck (the match refused it): MatchOpponent sees its turn still due and plans again.
            NSLog("ShowpieceModel: the computer's staged stroke was not struck; its turn is still due")
        }
    }

    /// Stop a staged stroke without striking and put the person's settings back.
    private func abandonStaging() {
        guard let s = staging else { stagingActive = false; return }
        staging = nil
        stagingActive = false
        restoreKept(s)
    }

    private func restoreKept(_ s: ComputerStaging) {
        if s.isBreak {
            power = s.keptPower; tipHeight = s.keptUp; breakTipSide = s.keptSide
        } else {
            shotPower = s.keptPower; shotTipUp = s.keptUp; shotTipSide = s.keptSide; shotElevation = s.keptElevation
        }
    }

    /// 0 at x <= 0, 1 at x >= 1, eased in and out between, so the swing and the draw-back never jolt.
    private static func smoothstep(_ x: Double) -> Double {
        let u = min(1, max(0, x))
        return u * u * (3 - 2 * u)
    }

    // MARK: A match shot on screen (plan item 14, contract 2.4)

    /// After a match shot has played out, its ruling card offers the Lens replay of it: always after a break (a match
    /// break plays at real speed in the ordinary view, so the slow Lens replay is the player's to ask for), and after
    /// any shot, by either seat, that MatchMode offered as remarkable (MatchMode.lensHighlight, for this recording).
    /// Was offerLensReplayOfBreak before 0.7.4.
    var offerLensReplay: Bool {
        guard let m = match, m.phase == .ruling || m.phase == .over, aimReady, playerShotOnScreen else { return false }
        if currentAttempt?.isBreak == true { return true }
        return m.lensHighlight != nil && m.lensHighlightVersion == timelineVersion
    }

    /// "Watch it in the Lens": the shot on screen replayed slowly in the Lens, as a replay the player started. A
    /// highlight's signature beats are held (Ride goes off first, as guided pacing and Ride do not mix). Was
    /// watchBreakInLens before 0.7.4.
    func watchShotInLens() {
        guard offerLensReplay else { return }
        // Every branch is a guided replay (0.7.5): a plain break's too, which Ride used to turn into an unguided
        // ride. Ride is held off and given back when the replay ends or is left.
        holdRideForGuidedReplay()
        if let m = match, let h = m.lensHighlight, m.lensHighlightVersion == timelineVersion {
            setPaceSignature(h.signatureEvents)
        }
        replay(withLens: true)
        lensReplayStartedByPlayer = true
    }

    /// A match shot is still being solved or replayed: the "See the ruling" button shows.
    var matchShotPlaying: Bool { match?.phase == .shooting }

    /// "See the ruling": jump to the end of the match shot on screen, so the ruling comes at once. Pressed while the
    /// shot is still being solved, the jump happens as soon as it lands.
    func seeRuling() {
        guard matchShotPlaying else { return }
        if isSolving {
            rulingWanted = true
            return
        }
        skipToResult()
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
        abandonStaging()
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
        guard !hasSeenOpening, !TitleScreen.launchSkipsTitle, StoreScene.requested == nil,
              !args.contains("-retryCases") else { return }
        menuOpen = false
        gameInProgress = true
        // 0.7.1: the first launch puts the player at the table straight away (a fresh rack, the cue in hand, one line
        // saying how to shoot) instead of playing the slow Lens opening first. The Boss found the opening too fast and
        // too busy as a first minute; it stays one tap away as Watch the intro.
        beginHandOver()
    }

    /// Skip ahead: from the opening break to the hand-over; from the hand-over, the first break or its card to the menu.
    func skipOpening() {
        switch openingStage {
        case .none:
            return
        case .playing:
            beginHandOver()
        case .handOver, .firstBreak, .firstBreakCard:
            cancelPendingSolve()
            finishOpening(showMenu: true)
        }
    }

    /// The first-break card's "Learn the shots": the opening ends and the menu opens with the lesson list open.
    func learnAfterFirstBreak() {
        guard openingStage == .firstBreakCard else { return }
        finishOpening(showMenu: true)
        showList(.lessons)
    }

    /// The first-break card's "Keep playing": the opening ends, the menu stays closed and Your shot is asked to open,
    /// so the player carries on from where their break left the balls.
    func keepPlayingAfterFirstBreak() {
        guard openingStage == .firstBreakCard else { return }
        finishOpening(showMenu: false)
        requestShotPanel(.open)
    }

    /// The package's reading of the shot on screen (what the break did: what dropped, a scratch), for the first-break
    /// card's words. Nil for a still table or a recording with no kept start.
    var shotFactsOnScreen: ShotFacts? { shotFacts }

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
            // The player's first break has played out: they keep playing from where it left the balls (0.7.1: no card
            // steering them into the lessons; the menu offers them).
            openingStage = .firstBreakCard
            keepPlayingAfterFirstBreak()
        default:
            break
        }
    }

    // MARK: The shot panel, the menu backdrop and the next step (plan items 8 and 52, contract 2.3)

    /// Ask the view to open, close or toggle "Your shot" (ShowpieceView acts on each new request).
    func requestShotPanel(_ action: ShotPanelRequest.Action) {
        shotPanelRequest = ShotPanelRequest(serial: (shotPanelRequest?.serial ?? 0) + 1, action: action)
    }

    /// True while one of the shots struck at this table (a player's shot or break, or the computer's) is the
    /// recording on screen: not a still table, not the showpiece opening. The slim playback row shows then.
    var playerShotOnScreen: Bool { currentAttempt != nil && attemptVersion == timelineVersion }

    /// After a break the player struck, Your shot opens again once the balls have stopped and it is the person's turn
    /// (in a match, once the ruling is settled and the computer is not to play). Called every frame; fires once.
    private func reopenPanelAfterBreakIfDue() {
        guard panelAfterBreakDue, openingStage == .none, aimReady else { return }
        // A trick shot's or a lesson's own card decides when the panel opens (their modes request it themselves).
        if authoredModeUp { panelAfterBreakDue = false; return }
        if let m = match {
            guard m.phase == .aiming, m.computerSeatToAct == nil, !m.state.isOver else { return }
        }
        panelAfterBreakDue = false
        requestShotPanel(.open)
    }

    /// Real seconds a beat is held behind the menu. Nobody reads a caption through the dimmed menu, so a beat is only
    /// a pause that lets the hit land: twice the 0.6 s pause used with Explanations off, because the backdrop is there
    /// to be glanced at, not followed.
    static let backdropDwell = 1.2
    /// The backdrop's speed when the showpiece has no beats to guide it (a table whose default shot is captionless):
    /// the slow end of the guided replay's quiet-stretch speed.
    static let backdropRate = 0.25

    /// Later launches (the opening has been seen, and no launch flag asks for a specific screen): the showpiece's slow
    /// Lens replay plays behind the dimmed menu, looping, with no table sounds and no haptics.
    private func startMenuBackdropIfLaterLaunch() {
        let args = ProcessInfo.processInfo.arguments
        guard hasSeenOpening, menuOpen, openingStage == .none, !TitleScreen.launchSkipsTitle,
              StoreScene.requested == nil, !args.contains("-retryCases") else { return }
        beginBackdrop()
    }

    /// Put the showpiece on its slow Lens replay as the menu's backdrop, from the start.
    private func beginBackdrop() {
        menuBackdropPlaying = true
        stage = .slowReplay; stageTime = 0; time = 0
        melt = 1; meltTarget = nil
        chosenRate = nil
        lensReplayStartedByPlayer = false
        resetPacing()
    }

    /// One frame of the backdrop. It runs on the table's clock only while the menu is up over the showpiece (nothing
    /// else is on the table at launch, and anything that puts a table on screen ends it), so it keeps no clock of its
    /// own to fall out of step with. Guided where the showpiece has beats; at the end it starts again.
    private func advanceBackdrop(_ dt: Double) {
        melt = 1; meltTarget = nil
        if stage != .slowReplay { stage = .slowReplay }
        if guided {
            stepGuided(dt)
        } else {
            displayRate = Self.backdropRate
            time = min(duration, time + dt * displayRate)
        }
        if time >= duration - 1e-6, !holding {
            time = 0
            resetPacing()
        }
    }

    /// The next step from stored progress, for the menu's highlighted entry: the first lesson not passed; once it is
    /// passed, that lesson's trick shot until it is made; then a game against the easy computer until one is finished.
    /// Nil once the whole path is done.
    var nextStep: NextStep? {
        for lesson in Lessons.all {
            if !lessonMode.isDone(lesson) { return .lesson(number: lesson.number, title: lesson.title) }
            if let shot = TrickShots.shot(id: lesson.trickID), !trickMode.isDone(shot) {
                return .trickShot(title: shot.title)
            }
        }
        // Reached only once every lesson and trick shot is done (the loop returns at the first step not done), so the
        // stored record is read only for a player who has finished the path; contains stops at the first game found.
        let playedEasy = MatchKind.allCases.contains { kind in
            let r = MatchRecord.record(kind: kind, level: .easy)
            return r.won + r.lost > 0
        }
        return playedEasy ? nil : .gameAgainstEasyComputer
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

    // MARK: Store scenes (plan item 40, contract 2.6)

    /// A store flag at launch: the menu and the opening are skipped and the scene is played to its still moment, no
    /// taps needed, through the same calls a player's taps make. Started after a second, as the other demos are, so the
    /// launch cover has faded and the first frames are drawn.
    private func startStoreSceneIfAsked() {
        guard let scene = StoreScene.requested else { return }
        menuOpen = false
        gameInProgress = true
        openingStage = .none
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1))
            await self?.playStoreScene(scene)
        }
    }

    private func playStoreScene(_ scene: StoreScene) async {
        switch scene {
        case .match: await storeMatchScene()
        case .ruling: await storeRulingScene()
        case .lesson(let n): await storeLessonScene(n)
        case .tableGame(let kind): await storeTableGameScene(kind)
        case .drill: await storeDrillScene()
        case .ride: storeRideScene()
        }
        NSLog("STORESCENE %@ ready", String(describing: scene))
    }

    /// The longest a store scene waits for one step (a solve, the computer's think, a replay), seconds. The
    /// computer's plan is the slowest step: a couple of hundred trial solves, several seconds on a simulator; a
    /// minute leaves a wide margin and still ends a stuck run.
    private static let storeStepLimit = 60.0

    /// Wait until `done` holds, checking every 50 ms, at most storeStepLimit seconds. While a shot plays on screen it
    /// jumps to the shot's end, so the scene does not wait out real-time replays.
    private func storeWait(_ done: () -> Bool) async {
        let steps = Int(Self.storeStepLimit / 0.05)
        for _ in 0..<steps {
            if done() { return }
            if !isSolving, !aimReady, staging == nil { skipToResult() }
            try? await Task.sleep(for: .milliseconds(50))
        }
        NSLog("STORESCENE: a step did not finish within %.0f seconds", Self.storeStepLimit)
    }

    /// The person's stroke in a scripted match: a break with the panel's own settings, or a firm shot at the nearest
    /// ball on its suggested call (a safety when there is none). Struck clean, as every scripted strike is.
    private func storePersonStroke(_ m: MatchMode) {
        if racked { breakNow(); return }
        aimAtNearestBall()
        if m.mustCall, m.currentCall == nil, !m.adoptSuggestedCall() { m.setCall(.safety) }
        if physicsTable != .standard { shotPower = min(max(physicsTable.defaultShot.power, 0.5), 8) } else { shotPower = 3 }
        shootNow()
    }

    /// -storeMatch: eight-ball against the medium computer, played until the computer has struck a shot and that shot
    /// is ruled, so its "Why that shot" has something to explain. The person's turns are played for them.
    private func storeMatchScene() async {
        startMatch(.eightBall, computer: .medium)
        // Each pass is one decision; a dozen covers a break, a few person's shots and the computer's turn.
        for _ in 0..<12 {
            await storeWait { !isSolving && aimReady && staging == nil && match?.phase != .shooting }
            guard let m = match, !m.state.isOver else { return }
            let computerShot = m.lastRuling.map { m.isComputer($0.shooter) } ?? false
            if computerShot, m.opponent?.lastShot != nil, m.phase != .aiming || m.computerSeatToAct == nil { return }
            switch m.phase {
            case .ruling, .handOver:
                m.acknowledgeRuling()
            case .aiming where m.computerSeatToAct != nil:
                // The computer thinks and plays on its own (MatchOpponent through stageComputerStroke).
                await storeWait { match?.phase != .aiming || match !== m }
            case .aiming:
                storePersonStroke(m)
            default:
                break
            }
        }
    }

    /// -storeRuling: two people at eight-ball, played until a foul is ruled; its card is the picture. After the break
    /// the shooter plays the softest stroke along the clearest line on the table, which touches no ball: a foul.
    private func storeRulingScene() async {
        startMatch(.eightBall)
        for _ in 0..<12 {
            await storeWait { !isSolving && aimReady && match?.phase != .shooting }
            guard let m = match, !m.state.isOver else { return }
            if m.phase == .ruling, m.lastRuling?.fouled == true { return }
            switch m.phase {
            case .ruling, .handOver:
                m.acknowledgeRuling()
            case .aiming:
                if racked { breakNow(); continue }
                if placingCueBall { _ = confirmCueBallPlacement() }
                if m.mustCall, m.currentCall == nil { m.setCall(.safety) }
                aimDegrees = clearestHeading()
                shotPower = PlayerShotSpeed.ordinary.lowerBound
                shootNow()
            default:
                break
            }
        }
    }

    /// The heading, degrees, along which the striking ball travels furthest before its path meets another ball (a
    /// sweep of every five degrees; any line that misses every ball counts as the length of the table).
    private func clearestHeading() -> Double {
        guard layout.indices.contains(strikeBall) else { return 0 }
        let from = layout[strikeBall]
        let clearance = 2 * physicsTable.parameters.ballRadius
        var best = (heading: 0.0, clear: -1.0)
        for step in 0..<72 {
            let heading = Double(step) * 5
            let d = Vec2(cos(heading * Double.pi / 180), sin(heading * Double.pi / 180))
            var clear = physicsTable.parameters.tableLength
            for i in layout.indices where i != strikeBall && NextShot.isOnTable(layout[i]) {
                let rel = layout[i] - from
                let along = rel.dot(d)
                guard along > 0, abs(rel.dot(d.perp)) < clearance else { continue }
                clear = min(clear, along)
            }
            if clear > best.clear { best = (heading, clear) }
        }
        return best.heading
    }

    /// -storeLesson n: the lesson's reference shot watched, then its Lens replay held on the lesson's moment, with the
    /// card giving the idea.
    private func storeLessonScene(_ number: Int) async {
        guard let lesson = Lessons.all.first(where: { $0.number == number }) ?? Lessons.all.first else { return }
        let mode = lessonMode
        mode.begin(lesson)
        mode.watch()
        // A lesson is solved directly, so the demonstration is on screen now; the table layer moves the mode on too,
        // but the scene does not wait on the view's timing.
        skipToResult()
        mode.update()
        guard let t = mode.keyTime else { return }
        scrub(to: t)
        mode.tick()
    }

    /// -storeTableGame kind: a few shots of a scored game, each struck at the nearest ball with the table's own
    /// default power, every ruling acknowledged, so the banner carries real scores. Bar billiards is played alone.
    private func storeTableGameScene(_ kind: MatchKind) async {
        startMatch(kind, players: kind == .barBilliards ? 1 : 2)
        // Four shots: enough for scores to show on the banner, few enough that the table still looks mid-game.
        var struck = 0
        for _ in 0..<12 where struck < 4 {
            await storeWait { !isSolving && aimReady && match?.phase != .shooting }
            guard let m = match, !m.state.isOver else { return }
            switch m.phase {
            case .ruling, .handOver:
                m.acknowledgeRuling()
            case .aiming:
                if placingCueBall { _ = confirmCueBallPlacement() }
                storePersonStroke(m)
                struck += 1
            default:
                break
            }
        }
        await storeWait { !isSolving && aimReady && match?.phase != .shooting }
        if let m = match, m.phase == .ruling || m.phase == .handOver { m.acknowledgeRuling() }
    }

    /// -storeDrill: one drill stroke with a measured finger stroke behind it, so the drill card shows a real reading.
    private func storeDrillScene() async {
        strokeDrill.begin()
        pendingStroke = Self.storeDrillStroke(power: shotPower)
        fire()
        await settle()
    }

    /// A finger stroke for the drill picture: a gentle wander of four percent of the stroke to the right over its last
    /// third (a steady but human stroke, inside the drill's "straight" grade), drawn back 12 cm behind the cue ball,
    /// after two practice strokes. Only the store scene builds one; every real stroke is measured by StrokeTracker.
    private static func storeDrillStroke(power: Double) -> StrokeRecord {
        let samples = 12
        let shape = (0...samples).map { k -> Vec2 in
            let x = Double(k) / Double(samples)
            return Vec2(x, 0.04 * x * x)
        }
        let start = Vec2(NextShot.headLineX(parameters: PoolParameters()), PoolParameters().tableWidth / 2)
        let trace = shape.map { Vec2(start.x - 0.12 * $0.x, start.y - 0.12 * $0.y) }
        return StrokeRecord(wander: 0.04, rhythm: 1, bridge: nil, power: power, trace: trace, shape: shape,
                            practiceStrokes: 2)
    }

    /// -storeRide: the -rideDemo straight pot with Ride on, held a little after the first contact, when the camera has
    /// begun its crane up and back and the far end of the room shows past the object ball's run (ShotCamera's ride).
    private func storeRideScene() {
        rideOn = true
        load(solve(RideDemo.straightPot()))
        clearAttempts()
        stage = .explore; stageTime = 0; chosenRate = nil
        // 0.4 s past the contact: the crane is under way but the rise to the overhead view has not started.
        let hold = ridePlan.contactTime.map { min($0 + 0.4, ridePlan.riseStart) } ?? duration * 0.5
        scrub(to: hold)
    }

    // MARK: Player controls

    func scrub(to t: Double) {
        // 0.7.7 bullet-time: a scrub of any size ends a freeze for this recording (a slow drag can move the clock by
        // less than the playback allowance, which frame() alone would not notice).
        bulletTime.cancel()
        finishColdOpen()
        playing = false
        time = min(max(0, t), duration)
        resetPacing()
        settleRideActsAfterJump()
    }

    func togglePlay() {
        // Behind the menu the table holds still (0.7.5): Space or a controller button reaching past it does nothing.
        guard !menuOpen else { return }
        finishColdOpen()
        // Played again from the start: a ride mounts again (0.7.6 stream ride).
        if time >= duration - 1e-6 { time = 0; resetPacing(); resetRideActs() }
        playing.toggle()
    }

    /// A fixed speed from the speed menu. A chosen speed turns guided pacing off (guided needs chosenRate == nil),
    /// and any hold in progress is let go so the clock moves at once. Nothing behind the menu (0.7.5).
    func setRate(_ r: Double) {
        guard !menuOpen else { return }
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
        // A plain replay leaves any guided Lens replay that held Ride off, so Ride comes back for it (0.7.5). A Lens
        // replay keeps it held: the guided callers hold Ride just before they call this.
        if !withLens { restoreHeldRide() }
        finishColdOpen()
        time = 0; playing = true
        // From the strike again: a plain replay with Ride on mounts again; a rewind that called this has ended.
        resetRideActs()
        meltTarget = withLens ? 1 : 0
        // With the Lens the replay is guided (no fixed speed: it stops on each beat to be read); without, real speed.
        chosenRate = withLens ? nil : 1
        // Who started it, for the Lens tips (contract 2.3). This one call serves the player's Replay with the Lens and
        // a lesson's own demonstration (LessonMode calls it as its Watch beat moves on to the replay); the
        // demonstration has the lesson's card over it, so it does not count as the player's. Nor does anything during
        // the first-launch opening, which has its own cards.
        lensReplayStartedByPlayer = withLens && !modeDemonstrationPlaying && openingStage == .none
        resetPacing()
    }

    /// True while a lesson's or a trick shot's own demonstration is on screen, with its card over it: a lesson's
    /// Watch beat and its replay, or a trick shot's answer and its explanation (0.7.4: TrickShotMode sets .explaining
    /// before it replays, so the Lens tips stay off over the answer's replay, as LensCallouts already says). Shared by
    /// replay(withLens:) and openMenu (0.7.5), which leaves such a replay running for its card.
    private var modeDemonstrationPlaying: Bool {
        let lessonDemonstration = lessonModeStorage.map {
            $0.current != nil && ($0.phase == .watching || $0.phase == .replaying)
        } ?? false
        let trickDemonstration = trickModeStorage.map {
            $0.current != nil && ($0.phase == .watching || $0.phase == .explaining)
        } ?? false
        return lessonDemonstration || trickDemonstration
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
        // The menu freezes the table behind it, whatever stage it is in; on a later launch the opening's slow Lens
        // replay plays behind it instead, silently (plan item 52).
        if menuOpen {
            if menuBackdropPlaying { advanceBackdrop(dt) }
            return
        }
        defer {
            if let hold = Self.pauseAt, stage == .explore, playing, time >= hold { scrub(to: hold) }
        }
        // 0.7.7 bullet-time: every frame the table runs, whatever the stage, so a freeze is ended by the next frame
        // when anything overtakes it (the Lens asked for, Ride, a guided replay, the what-if, the option, leaving the
        // table for the intro). Keep it unconditional and outside the switch. meltTarget is set the moment the Lens is
        // asked for, so the freeze ends on the tap; a meltTarget of 0 (the Lens leaving, a plain Replay) does not
        // count as the Lens coming. Behind the menu advance returned above, so the freeze simply pauses there.
        let bulletTable: Bool = stage == .explore && GameSettings.bulletTimeOn && whatIfStorage?.isOpen != true
        let bulletQuiet: Bool = !guided && !rideActive && rideAct == .none && melt < 0.02 && (meltTarget ?? 0) < 0.5
        let bulletHolds = bulletTime.frame(dt, clock: time, playing: playing, rate: chosenRate ?? 1,
                                           version: timelineVersion, allowed: bulletTable && bulletQuiet)
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
            if time >= duration, !holding {
                stage = .explore; playing = false; chosenRate = nil
                // Watch the intro has ended: its card offers the trick shots and practice (0.7.4).
                noteIntroEnded()
            }
        case .explore:
            if rideAct == .rewind {
                // The rewind before a trick shot's slow Lens replay drives the clock itself (0.7.6 stream ride).
                advanceRideRewind(dt)
            } else if guided {
                // Paused, the hold's counter does not run: pausing on a beat keeps the full reading time.
                if playing { stepGuided(dt) }
            } else {
                // A hold left over from guided pacing (the Lens turned off, Ride turned on) is let go.
                if heldBeat != nil { resetPacing() }
                // A ride's acts drive the clock themselves (0.7.6 stream ride); otherwise the ordinary step.
                if !advanceRide(dt) {
                    // With Ride on, playback eases into slow motion around the first contact and back out; the curve
                    // is a function of the clock, so it plays the same however the clock got there. Any speed the
                    // player picked still applies: the curve multiplies it.
                    // 0.7.7 bullet-time: a freeze holds the clock; around it, its own ease down and back up multiplies in.
                    if bulletHolds {
                        displayRate = 0
                    } else {
                        displayRate = (chosenRate ?? 1) * (rideActive ? ridePlan.rateFactor(at: time) : 1)
                            * bulletTime.rateFactor(at: time)
                        if playing { step(dt) }
                    }
                }
            }
            if let target = meltTarget {
                let speed = 1.8
                if melt < target { melt = min(target, melt + dt * speed) } else { melt = max(target, melt - dt * speed) }
                if melt == target { meltTarget = nil }
            }
        }
        // The computer's staged stroke moves on (its swing, draw-back and strike).
        advanceStaging(dt)
        // Hand-offs that wait for the shot on screen to play out: the opening's next stage, a match's ruling, the shot
        // panel after a break, and a ball in hand that is lifted only once the balls are at rest.
        updateOpening()
        match?.update()
        reopenPanelAfterBreakIfDue()
        // The bar-billiards clock counts real seconds (rawDt, not the step clamped for the physics replay); MatchMode
        // and MatchClock decide whether this frame counts. Never reached while the menu is open (returned above).
        match?.tickClock(realSeconds: rawDt)
        if placementDue, aimReady {
            placementDue = false
            beginPlacingCueBall()
        }
        // Worth watching (0.7.4): a touched control hides the highlight card for good, the best shot's replay hands
        // the cleared table back when it ends, and Table cleared sounds once per rack.
        latchHighlightTouch()
        finishBestReplayIfDone()
        // 0.7.5: Watch the intro's end card also follows an intro that was paused or scrubbed, which moves it to the
        // ordinary table (explore) without passing the slow replay's own end above. noteIntroEnded keeps its own
        // guards (armed by watchBreak only, the showpiece on screen), so this is a cheap check every frame.
        if aimReady && !holding { noteIntroEnded() }
        // A guided Lens replay that held Ride off has played to its end: Ride comes back (holdRideForGuidedReplay).
        if rideHeldForGuidedReplay, aimReady, !holding { restoreHeldRide() }
        chimeTableClearedIfDue()
        // 0.7.7 achievements: the progress sweep and the notes, on real seconds (not the clamped physics step). Never
        // behind the menu: advance has returned above.
        achievements.frame(rawDt)
    }

    private func step(_ dt: Double) {
        let old = time
        // 0.7.7 bullet-time: capped at an armed freeze's contact, so the frame that reaches it lands on it and
        // fireSounds crosses the contact exactly once.
        time = min(duration, time + dt * displayRate, bulletTime.cap(clock: old, version: timelineVersion))
        if time >= duration, stage == .explore { playing = false }
        fireSounds(from: old, to: time)
    }

    private func fireSounds(from a: Double, to b: Double) {
        // The replay behind the menu is silent and still in the hand: only the title music plays there.
        guard b > a, !menuBackdropPlaying else { return }
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
        let onSurface = Self.solverCopy(input, table: t, surface: s, generation: generation)
        return Prepared(input: input, solvable: onSurface, surface: s, table: t, generation: generation, classic: classic)
    }

    /// The solver's copy of `input` on `table`, `surface` and physics `generation`: generation one's own numbers first,
    /// then the table, then the surface, then the generation written last. Pure: it commits nothing, so the what-if
    /// can build a copy on an attempt's own table, surface and generation without touching what is on screen.
    nonisolated static func solverCopy(_ input: ShotInput, table: TableKind, surface: PlaySurface,
                                       generation: Int) -> ShotInput {
        var onSurface = input
        if generation == 1 { onSurface.parameters.useGenerationOne() }
        table.apply(to: &onSurface.parameters)
        surface.apply(to: &onSurface.parameters)
        // Last, so nothing above can overwrite it.
        onSurface.parameters.modelGeneration = generation
        return onSurface
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
        // A surface change while the best shot replays acts on the cleared table, put back first (0.7.4).
        endBestReplay()
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
        let attemptOnScreen = playerShotOnScreen
        let inColdOpen = stage != .explore
        let backdrop = menuBackdropPlaying
        let replaced = timelineVersion
        load(solve(input, classic: lastClassic), showpiece: showpieceOnScreen)
        // A trick shot or lesson keyed to the old recording's version follows it to the re-solved one (0.7.5).
        if timelineVersion != replaced {
            trickModeStorage?.recordingReplaced(old: replaced, new: timelineVersion)
            lessonModeStorage?.recordingReplaced(old: replaced, new: timelineVersion)
        }
        if let a = attempt {
            currentAttempt = a.resolved(on: timeline, surface: solvedSurface)
            // The re-solved attempt is the recording on screen only if the old one was.
            if attemptOnScreen { attemptVersion = timelineVersion }
        }
        // A surface chosen from the menu's options while the backdrop plays: the backdrop carries on, on the new cloth.
        if backdrop {
            beginBackdrop()
            return
        }
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
    var authoredModeUp: Bool {
        trickModeStorage?.current != nil || eightBallModeStorage?.current != nil || lessonModeStorage?.current != nil
    }

    // 0.7.7 achievements: three small readers for the achievements book, through the optional storage, so a strike or a
    // frame never creates a mode.
    /// True when the stroke being struck is the person's own: not the computer's, and not a trick's or lesson's Watch
    /// or a Behind the 8-Ball hint (each mode sets .watching before it strikes, and authored modes solve synchronously,
    /// so the phase is still set inside strike()).
    var achievementStrikeIsPersons: Bool {
        if match?.computerActing == true { return false }
        if trickModeStorage?.phase == .watching { return false }
        if lessonModeStorage?.phase == .watching { return false }
        if eightBallModeStorage?.phase == .watching { return false }
        return true
    }

    /// Free play for the achievements: no match, no authored mode, no drill.
    var achievementFreePlay: Bool {
        match == nil && !authoredModeUp && strokeDrillStorage?.isActive != true
    }

    /// A fingerprint of the progress the game keeps (lessons passed, trick shots made, medals, games finished this
    /// sitting); the book sweeps its collections when it moves. -1 for a mode not made yet.
    var achievementStamp: [Int] {
        [lessonModeStorage?.doneIDs.count ?? -1, trickModeStorage?.doneIDs.count ?? -1,
         eightBallModeStorage?.medals.count ?? -1, match?.sittingGames ?? -1]
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
        startHighlightRack()
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

    // MARK: What if (WhatIfFork) - 0.7.5 foundation, Claude Opus 5.5 High, 22-November-2026

    /// The what-if replay for this table, made on first use (the trickMode pattern): observable itself, and creating it
    /// lazily must not count as a change to the model.
    @ObservationIgnored private var whatIfStorage: WhatIfFork?
    var whatIf: WhatIfFork {
        if let w = whatIfStorage { return w }
        let w = WhatIfFork(model: self)
        whatIfStorage = w
        return w
    }

    // MARK: Lists, table on screen, Auto speed, Ride in guided replays - 0.7.5 model-flow, Claude Opus 5.5 High

    /// Open one mode list and close the other two, so the menu, the Mac menu bar and the notebook never stack two
    /// lists (each list is its own sheet or notebook page, and the notebook shows only the first one open).
    func showList(_ list: ModeList) {
        // The others close through closeAllLists (the optional storage), so opening one list never creates the other
        // two modes; only the list asked for is made if it is not yet.
        closeAllLists()
        switch list {
        case .tricks: trickMode.listOpen = true
        case .lessons: lessonMode.listOpen = true
        case .eightBall: eightBallMode.listOpen = true
        }
    }

    /// Close the trick, lesson and eight-ball lists. Every route into play calls it (Practice, Watch the intro,
    /// Continue match, a match, the stroke drill, and the start of a trick shot, situation or lesson), so a list
    /// left open never sits over, or comes back over, what was just started. Through the optional storage: a mode
    /// never used has no list open, and asking must not create it.
    func closeAllLists() {
        trickModeStorage?.listOpen = false
        lessonModeStorage?.listOpen = false
        eightBallModeStorage?.listOpen = false
    }

    /// The table the Tables list (and the Mac's Game > Tables) ticks: the free-play table on screen, or nil while a
    /// trick shot, lesson, Behind the 8-Ball situation, the stroke drill or a match is up, since then the table on
    /// screen belongs to that mode, not to the player's choice.
    var tableOnScreen: TableKind? {
        guard !authoredModeUp, match == nil, strokeDrillStorage?.isActive != true else { return nil }
        return physicsTable
    }

    /// The speed menu's Auto: no fixed speed, so a Lens replay is paced by its beats again (guided needs chosenRate
    /// nil) and an ordinary replay plays at real speed. Like setRate it ends the cold open, lets any hold go, plays if
    /// paused, and does nothing behind the menu.
    func setAutoRate() {
        // Nothing behind the menu, as setRate (0.7.5 review).
        guard !menuOpen else { return }
        finishColdOpen()
        chosenRate = nil
        resetPacing()
        if !playing { playing = true }
    }

    /// Ride the player had on before a guided Lens replay turned it off; given back by restoreHeldRide. Not observed:
    /// no view reads it (they read rideOn).
    @ObservationIgnored private var rideHeldForGuidedReplay = false

    /// Turns Ride off for a guided Lens replay and remembers it; restored when the replay ends or is left. Guided
    /// pacing and the Ride camera do not mix (the replay would not hold its beats), but Ride is the player's choice,
    /// so it must come back. Set rideOn directly, not through setRide, which would restart a finished shot and forget
    /// the hold. Called again while held, it keeps the remembered Ride. Given back (restoreHeldRide) when the replay
    /// plays to its end (advance), by a plain replay, by anything else going on screen (load), and when the menu ends
    /// the replay; an explicit setRide replaces it.
    func holdRideForGuidedReplay() {
        guard rideOn else { return }
        rideHeldForGuidedReplay = true
        rideOn = false
    }

    /// Give Ride back if a guided replay held it off. Assigned directly, so nothing restarts.
    private func restoreHeldRide() {
        guard rideHeldForGuidedReplay else { return }
        rideHeldForGuidedReplay = false
        rideOn = true
    }

    /// End a trick shot or a Behind the 8-Ball situation that is up, so Practice and Watch the intro need no caller to
    /// do it first (the menu did; the intro-end card and the Mac did not). Only one that is up: ending an idle trick
    /// mode would still switch Ride off through its camera, and an idle situation has no cloth to give back.
    private func endPoolTableModes() {
        if trickModeStorage?.current != nil { trickModeStorage?.end() }
        if eightBallModeStorage?.current != nil { eightBallModeStorage?.end() }
    }

    /// Free play back on the pool table, stored as the choice the way playTable stores one, with the rack memory
    /// started again as setTable does (0.7.5). Nothing goes on screen here: Practice racks and Watch the intro loads
    /// the opening right after.
    private func returnToPoolTable() {
        guard tableKind != .standard else { return }
        startHighlightRack()
        tableKind = .standard
        UserDefaults.standard.set(TableKind.standard.rawValue, forKey: TableKind.storageKey)
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

    // 0.7.7 achievements: the achievements book, made on first use and kept out of observation, exactly as trickMode.
    @ObservationIgnored private var achievementsStorage: AchievementBook?
    var achievements: AchievementBook {
        if let b = achievementsStorage { return b }
        let b = AchievementBook(model: self)
        achievementsStorage = b
        return b
    }

    /// Onto the table from the menu for a trick shot: the menu closes and Continue will come back here. A match in
    /// progress is left (it stays saved).
    func enterTrickTable() {
        closeAllLists()
        startHighlightRack()
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
        closeAllLists()
        startHighlightRack()
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
        closeAllLists()
        startHighlightRack()
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
        StrokeModel.strikeZones(cue: cueInHand, bridge: strokeBridgeLength, stance: stance,
                                authored: authoredModeUp, isBreak: racked)
    }

    // MARK: The strike's angle, the rest and the cue (plan items 23 and 57, contract 2.5)

    /// The cue's elevation the next strike and the 3D cue use (sine). A break is struck level. In free play, matches
    /// and the drill it is the larger of the player's angle and the least angle that clears every ball under the whole
    /// cue, tip to butt, resting on its bridge (Reach.clearingElevation), so "cue raised over the 5" is a real raised
    /// stroke that dips and swerves. A trick shot, a Behind the 8-Ball situation or a lesson keeps its authored angle:
    /// their answers were measured with exactly that input, and a clearing raise would change them.
    var strikeElevation: Double {
        guard !racked else { return 0 }
        guard !authoredModeUp else { return shotElevation }
        return max(activeElevation, clearingElevation)
    }

    /// The least cue angle (sine) that clears every ball under the cue for the aim now; 0 when a level cue clears or
    /// there is no striking ball on the table.
    private var clearingElevation: Double {
        guard layout.count == 16, layout.indices.contains(strikeBall), NextShot.isOnTable(layout[strikeBall]) else {
            return 0
        }
        return Reach.clearingElevation(layout: layout, cueBall: strikeBall, aim: aimDirection, table: timeline.table,
                                       support: strokeBridgeLength, cueLength: cueInHand.length)
    }

    /// The mechanical bridge (the swan-neck rest) is drawn and used: the mode shows the bridge, or the stance is the
    /// rest because the cue ball is out of reach, in every mode. TableStage passes it to the cue rig.
    var restInUse: Bool { showsBridge || stance?.rung == .rest }

    /// The cue the game picked for the next strike (CueProfile.choice): from the break, the player's angle and the
    /// tip. In a trick shot, situation or lesson it stays the house cue: power is the swing, so another cue would send
    /// the ball at another speed, and every authored answer was measured with the house cue's launch speeds.
    var cueChoice: CueChoice {
        guard !authoredModeUp else { return .standard }
        return CueProfile.choice(isBreak: racked, elevation: activeElevation, tipUp: activeTipUp, tipSide: activeTipSide)
    }

    /// That cue's profile: the launch speed, the power bar's zones, the drift and the readouts read it.
    var cueInHand: CueProfile { CueProfile.profile(for: cueChoice.kind) }

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
                                     cue: cueInHand, authored: authoredModeUp, stance: struckStance,
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
        closeAllLists()
        startHighlightRack()
        trickModeStorage?.end()
        eightBallModeStorage?.end()
        lessonModeStorage?.end()
        leaveMatch()
        cancelPendingSolve()
        endPlacement(); ballInHand = .none; undoStep = nil
        menuOpen = false
        gameInProgress = true
    }

    // MARK: 0.7.4 foundation (plans/22-Nov-2026-v074-glow-up-plan.md, F6)

    /// Event indices the guided replay must hold as headline beats (a trick shot's or a highlight's signature).
    /// Cleared by load(_:).
    private var paceSignature: [Int] = []

    /// Hold these events in the next guided replay of the recording on screen; rebuilds the pace plan at once.
    func setPaceSignature(_ events: [Int]) { paceSignature = events; refreshPacePlan() }

    /// The caption of the beat being held right now (nil when not holding).
    var heldCaption: Caption? {
        // The ride's held hit too (0.7.6 stream ride), so the Lens draws its held-hit marks as in a guided replay.
        if rideHolding { return rideHeldCaption }
        guard holding, let h = heldBeat, pacePlan.beats.indices.contains(h) else { return nil }
        return pacePlan.beats[h].caption
    }

    /// The event index of the held beat when it is one of the signature events, else nil.
    var heldSignatureEvent: Int? {
        guard let c = heldCaption, paceSignature.contains(c.id) else { return nil }
        return c.id
    }

    /// The level picked for a game against the computer, shared by the menu and the Tables pages. Remembered on the
    /// device (GameSettings.computerLevelKey, 0.7.5), so a later launch offers the level last chosen; Medium until one
    /// is chosen, or if the stored value is not a level. Written on every change; reading it never writes.
    var computerLevel: ComputerLevel {
        get { storedComputerLevel }
        set {
            storedComputerLevel = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: GameSettings.computerLevelKey)
        }
    }
    /// The observed value behind computerLevel (the views redraw from it), read from the device once.
    private var storedComputerLevel: ComputerLevel =
        ComputerLevel(rawValue: UserDefaults.standard.string(forKey: GameSettings.computerLevelKey) ?? "") ?? .medium

    // MARK: Worth watching (0.7.4, stream watch-invite; plan G3 and G4)
    //
    // One shot is judged once, in finishStrike, after everything finishStrike already did, and only when the opening
    // is over (openingStage == .none: the first break of a first launch is never judged), no trick shot, situation
    // or lesson is up and the stroke drill is not active. The result is stored with the timelineVersion it belongs
    // to, so every read below is a cheap comparison of stored state (views and the Mac menu read them every frame).
    // Free play offers it on one slim card in the card slot; a match hands it to MatchMode, which decides. Nothing
    // here plays by itself, makes a sound or praises: every replay starts from a tap.

    /// The aim, power, tip and cue angle, break and shot values both. Compared whole: any difference means the player
    /// touched a control. Also what Watch your best shot puts back, because loading another recording re-aims.
    struct ControlValues: Equatable {
        let aimDegrees: Double
        let aimOffset: Double
        let shotPower: Double
        let power: Double
        let shotTipUp: Double
        let shotTipSide: Double
        let tipHeight: Double
        let breakTipSide: Double
        let shotElevation: Double
    }

    var controlValues: ControlValues {
        ControlValues(aimDegrees: aimDegrees, aimOffset: aimOffset, shotPower: shotPower, power: power,
                      shotTipUp: shotTipUp, shotTipSide: shotTipSide, tipHeight: tipHeight, breakTipSide: breakTipSide,
                      shotElevation: shotElevation)
    }

    /// Written directly, not through the active setters: these are values the controls already held, and a lesson
    /// lock or the computer's turn must not half-apply them.
    private func restoreControlValues(_ c: ControlValues) {
        aimDegrees = c.aimDegrees; aimOffset = c.aimOffset
        shotPower = c.shotPower; power = c.power
        shotTipUp = c.shotTipUp; shotTipSide = c.shotTipSide
        tipHeight = c.tipHeight; breakTipSide = c.breakTipSide
        shotElevation = c.shotElevation
    }

    /// A highlight judged on a recording: which recording (timelineVersion), and the controls as they stood when the
    /// shot was put on screen (after load() re-aimed), so the card can tell the moment the player touches one.
    private struct JudgedHighlight {
        let highlight: ShotHighlight
        let version: Int
        let controls: ControlValues
    }

    /// The highlight of the last shot struck, while it is worth offering (free play: it passed HighlightOffer; a
    /// match: every judged one, MatchMode decides). Nil for an ordinary shot.
    private var judgedHighlight: JudgedHighlight?
    /// The card's close button was used, or a control was touched (latched every frame by latchHighlightTouch).
    private var highlightDismissed = false
    /// Watch it in the Lens was used on this highlight: the card comes back without that button.
    private var highlightWatched = false
    /// How often free play's card may appear, and which trick shots a card has sent the player to this session.
    private var highlightOffer = HighlightOffer()
    /// Free-play breaks struck while the app runs (the first launch's opening break included); the break's card
    /// waits for the second (plan G3: "from the second rack on").
    @ObservationIgnored private var freePlayBreaksStruck = 0

    /// What free play's highlight card shows now: the highlight, whether Watch it in the Lens is still offered, and
    /// whether Try the trick shot is.
    struct HighlightCardOffer: Equatable {
        let highlight: ShotHighlight
        let canWatch: Bool
        let canTryTrick: Bool
    }

    /// True while free play is on the table: no match, no trick shot, situation or lesson, no drill, no opening.
    private var freePlayUp: Bool {
        match == nil && !authoredModeUp && strokeDrillStorage?.isActive != true && openingStage == .none
    }

    /// Free play's highlight card, or nil: the highlight belongs to the recording on screen, the balls are at rest,
    /// it was not closed, the aim, power, tip and cue angle are exactly as the shot left them, nothing is being
    /// placed, the table is not cleared (that card has its own button), the menu is closed, nothing is solving and the
    /// best shot is not replaying. After a watch only "Try the trick shot" remains, and only when it is allowed.
    /// (A retry's comparison card is never joined by this one: judgeHighlight keeps no highlight for a compared retry.)
    var highlightCard: HighlightCardOffer? {
        guard freePlayUp, let j = judgedHighlight, j.version == timelineVersion, aimReady, !highlightDismissed,
              !menuOpen, !isSolving, !replayingBest, ballInHand == .none, !placingCueBall, !tableCleared,
              controlValues == j.controls else { return nil }
        let canTry = highlightOffer.mayLinkTrick(j.highlight.kind, done: trickMode.doneIDs)
        guard !highlightWatched || canTry else { return nil }
        return HighlightCardOffer(highlight: j.highlight, canWatch: !highlightWatched, canTryTrick: canTry)
    }

    /// The remarkable shot on offer for a Lens replay (free play's card while it still offers the watch). MacChrome's
    /// Playback menu enables "Watch It in the Lens" from this.
    var highlightOnOffer: ShotHighlight? {
        guard let card = highlightCard, card.canWatch else { return nil }
        return card.highlight
    }

    /// "Watch it in the Lens" on the card (or the Mac menu): the shot on screen replays slowly in the Lens, holding its
    /// signature beats. Ride goes off first: guided pacing and the Ride camera do not mix (the replay would not hold).
    func watchHighlight() {
        guard let h = highlightOnOffer else { return }
        // Held, not switched off (0.7.5): Ride comes back when the replay ends or is left.
        holdRideForGuidedReplay()
        setPaceSignature(h.signatureEvents)
        replay(withLens: true)
        lensReplayStartedByPlayer = true
        highlightWatched = true
    }

    /// "Try the trick shot" on the card: the authored trick shot that teaches this kind (offered once per kind).
    func tryHighlightTrick() {
        guard let card = highlightCard, card.canTryTrick, let id = card.highlight.kind.trickID else { return }
        highlightOffer.noteTrickLinked(card.highlight.kind)
        trickMode.begin(id: id)
    }

    /// The card's close button: gone until the next remarkable shot.
    func dismissHighlight() { highlightDismissed = true }

    /// The judged highlight of the match shot on screen, for MatchMode.rule(); nil outside a match, for an ordinary
    /// shot, and for any other recording.
    var matchShotHighlight: ShotHighlight? {
        guard match != nil, let j = judgedHighlight, j.version == timelineVersion else { return nil }
        return j.highlight
    }

    /// Judge the shot finishStrike has just put on screen (called last there, so nothing it did changes). The
    /// shot's facts and captions are the ones load() has just built for this very recording.
    private func judgeHighlight(_ tl: Timeline, isBreak: Bool) {
        judgedHighlight = nil
        highlightDismissed = false
        highlightWatched = false
        // Free play's breaks are counted before anything is judged, so the first launch's opening break counts too:
        // the break's card comes from the second rack of the session on (plan G3), never on the first break.
        if isBreak, match == nil, !authoredModeUp, strokeDrillStorage?.isActive != true { freePlayBreaksStruck += 1 }
        // Nothing is judged before the first break of a first launch has finished, nor in an authored mode or the drill.
        guard openingStage == .none, !authoredModeUp, strokeDrillStorage?.isActive != true, let facts = shotFacts else {
            return
        }
        let freePlay = match == nil
        if freePlay { highlightOffer.noteShot() }
        guard let h = ShotHighlightJudge.judge(timeline: tl, facts: facts, captions: captions, table: solvedTable,
                                               isBreak: isBreak) else { return }
        if freePlay {
            noteBestShot(h)
            if h.kind == .breakShot, freePlayBreaksStruck < 2 { return }
            // Ask the frequency rule only when the card can really show: a scratch puts the cue ball in hand, a shot
            // that cleared the table gets the Table cleared card (which offers the best shot) instead, and a retry's
            // comparison card already speaks for the shot. Asking would use up a common kind for a card nobody saw.
            let objectBallsLeft = layout.indices.contains { $0 != strikeBall && NextShot.isOnTable(layout[$0]) }
            guard ballInHand == .none, objectBallsLeft, retryComparison == nil,
                  highlightOffer.shouldOffer(h.kind) else { return }
        }
        judgedHighlight = JudgedHighlight(highlight: h, version: timelineVersion, controls: controlValues)
    }

    /// Every frame: a touch of aim, power, tip or cue angle hides free play's card for good (the values coming back
    /// exactly, as a keyboard step and its opposite would, does not bring it back).
    private func latchHighlightTouch() {
        guard match == nil, !highlightDismissed, let j = judgedHighlight, j.version == timelineVersion,
              controlValues != j.controls else { return }
        highlightDismissed = true
    }

    /// A fresh rack, a new table, a match or any mode starting: free play's per-rack memory goes (HighlightOffer's
    /// rack, the rack's best shot, the cleared chime).
    private func startHighlightRack() {
        highlightOffer.startRack()
        // 0.7.7 bullet-time: the rack's big cut is available again.
        bulletTime.startRack()
        bestShot = nil
        clearedChimePlayed = false
    }

    // MARK: Worth watching: the rack's best shot (Table cleared)

    /// The rack's best remarkable shot: the attempt exactly as it was struck and solved, its highlight, and the shot
    /// count when it was played (an undo past it drops it).
    private struct BestShot {
        let attempt: ShotAttempt
        let highlight: ShotHighlight
        let rackShot: Int
    }

    /// The best remarkable shot of this rack (not a break, not a ball too fast for the pocket); nil when none.
    private var bestShot: BestShot?

    /// Everything Watch your best shot changes, as it stood on the cleared table, so it can be put back exactly: the
    /// clearing attempt and what its recording was solved from, the controls (loading re-aims), the retry ghost and
    /// comparison (hidden while another shot replays), the Lens, the speed and Ride.
    private struct ClearedTable {
        let attempt: ShotAttempt
        let input: ShotInput?
        let classic: Bool
        let surface: PlaySurface
        let table: TableKind
        let generation: Int
        let controls: ControlValues
        let ghost: ShotAttempt?
        let comparison: String?
        let retryComparison: RetryComparison?
        let lensOn: Bool
        let chosenRate: Double?
        let rideOn: Bool
    }

    @ObservationIgnored private var clearedTable: ClearedTable?
    /// The controls right after the best shot went on screen: unchanged at the end of its replay, the cleared table's
    /// are put back; changed, the player set them (a power for the stroke they are striking now) and they stay.
    @ObservationIgnored private var bestReplayControls: ControlValues?
    /// True while Watch your best shot replays: the Table cleared card stays up (without that button).
    private(set) var replayingBest = false
    /// True only while this section loads a kept recording itself, so load() does not take it for the table moving on.
    @ObservationIgnored private var loadingKeptRecording = false
    /// Table cleared has sounded on this rack (once per rack; an undo lets it sound again).
    @ObservationIgnored private var clearedChimePlayed = false

    /// Keep the shot just struck as the rack's best if it beats the best so far (a higher rank; a tie keeps the
    /// earlier). Breaks and balls too fast for the pocket are not shots to show off.
    private func noteBestShot(_ h: ShotHighlight) {
        guard h.kind != .breakShot, h.kind != .rimSkip, let attempt = currentAttempt else { return }
        if let best = bestShot, best.highlight.kind.rank >= h.kind.rank { return }
        bestShot = BestShot(attempt: attempt, highlight: h, rackShot: shotsThisRack)
    }

    /// Table cleared offers "Watch your best shot" when the rack had a remarkable shot.
    var canWatchBestShot: Bool { bestShot != nil && !replayingBest && tableCleared }

    /// "Watch your best shot": remember the cleared table, put the best shot's recording on screen exactly as it was
    /// solved, hold its signature and replay it slowly in the Lens. finishBestReplayIfDone puts the cleared table
    /// back once it has played. Nothing is recorded or counted: no record(), no shot count, no undo step.
    func watchBestShot() {
        guard canWatchBestShot, let best = bestShot, let clearing = currentAttempt else { return }
        // Ride held off by an earlier guided replay comes back first, so the cleared table remembers the player's own
        // Ride and endBestReplay gives that back (0.7.5).
        restoreHeldRide()
        clearedTable = ClearedTable(attempt: clearing, input: lastInput, classic: lastClassic, surface: solvedSurface,
                                    table: solvedTable, generation: solvedGeneration, controls: controlValues,
                                    ghost: ghost, comparison: comparison, retryComparison: retryComparison,
                                    lensOn: (meltTarget ?? melt) > 0.5, chosenRate: chosenRate, rideOn: rideOn)
        // Set before the load, so the cleared card never blinks off while the other shot goes on screen.
        replayingBest = true
        // The retry ghost belongs to the clearing shot; drawn over another shot's replay it would mislead.
        if ghost != nil { ghostVersion += 1 }
        ghost = nil; comparison = nil; retryComparison = nil
        // A player's attempt is never the opening, so it was not pinned to the default generation (classic).
        showKeptRecording(best.attempt, input: best.attempt.input, classic: false, surface: best.attempt.surface,
                          table: best.attempt.table, generation: best.attempt.generation)
        // The controls as the load left them (it re-aims): endBestReplay keeps any the player has set since.
        bestReplayControls = controlValues
        if rideOn { rideOn = false }
        setPaceSignature(best.highlight.signatureEvents)
        replay(withLens: true)
        lensReplayStartedByPlayer = true
    }

    /// Put a kept attempt's recording on screen as it was solved: what it was solved from is written back first, so
    /// load() makes the very captions, facts and layout it made then. The attempt becomes the one on screen without
    /// going through record() (no retry comparison, nothing counted).
    private func showKeptRecording(_ a: ShotAttempt, input: ShotInput?, classic: Bool, surface: PlaySurface,
                                   table: TableKind, generation: Int) {
        lastInput = input
        lastClassic = classic
        solvedSurface = surface
        solvedTable = table
        solvedGeneration = generation
        loadingKeptRecording = true
        load(a.timeline)
        loadingKeptRecording = false
        currentAttempt = a
        attemptVersion = timelineVersion
    }

    /// Every frame: once the best shot's replay has reached its end (and is not holding a beat stamped there), the
    /// cleared table comes back.
    private func finishBestReplayIfDone() {
        guard replayingBest, aimReady, !holding else { return }
        endBestReplay()
    }

    /// Put the cleared table back exactly as it was before Watch your best shot: the clearing attempt's recording at
    /// its end, still, as the attempt on screen; the controls, the ghost and comparison, the Lens, the speed and Ride
    /// as they were. The shot count and the undo step were never touched. Menu, Rack again, a surface change and Undo
    /// call this first, so they act on the cleared table.
    private func endBestReplay() {
        guard replayingBest else { return }
        guard let c = clearedTable else { replayingBest = false; return }
        // Read before the load below, which may re-aim.
        let touched = bestReplayControls.map { $0 != controlValues } ?? false
        // A ball lifted near the end of the replay was lifted on the replayed shot's table, not this one.
        endPlacement()
        showKeptRecording(c.attempt, input: c.input, classic: c.classic, surface: c.surface, table: c.table,
                          generation: c.generation)
        stage = .explore; stageTime = 0
        time = duration; playing = false
        chosenRate = c.chosenRate
        meltTarget = c.lensOn ? 1 : 0
        rideOn = c.rideOn
        if !touched { restoreControlValues(c.controls) }
        bestReplayControls = nil
        if c.ghost != nil { ghostVersion += 1 }
        ghost = c.ghost; comparison = c.comparison; retryComparison = c.retryComparison
        clearedTable = nil
        replayingBest = false
    }

    /// Something else is going on the table (a new rack, a mode, a match): the best shot's replay simply ends; the
    /// cleared table is not put back, because the caller is replacing it.
    private func abandonBestReplay() {
        clearedTable = nil
        bestReplayControls = nil
        replayingBest = false
    }

    // MARK: Achievements: an achievement's shot in the Lens (0.7.7 achievements)

    // 0.7.7 achievements: the recording an achievement's replay put on screen, and which achievement it was. The book
    // shows the end note ("That was your Bank shot.") while that recording is on screen and the table is calm.
    private(set) var achievementReplayVersion: Int?
    private(set) var achievementReplayID: String?

    /// 0.7.7 achievements: "Watch it in the Lens" on an achievement's page. A route into play, like Watch the intro: the
    /// menu closes, any trick shot, lesson, situation or drill is left, a match is left saved (Continue match brings it
    /// back), the shot's table and surface become the chosen ones (stored, as the Tables list and the Surface menu store
    /// them), and the kept shot (already solved again by AchievementBook.replayShot) replays slowly in the Lens, holding
    /// its signature moments, with Ride held for the replay. Afterwards the table is ready to play on: a scratched cue
    /// ball is in hand, and a shot that cleared the table shows Table cleared with Rack again, silently. Nothing is
    /// recorded or counted (no record(), no undo step), as Watch your best shot; the kept attempt becomes the current
    /// attempt, so Try again retries the replayed shot from its start.
    func watchAchievementShot(_ attempt: ShotAttempt, signature: [Int], id: String) {
        closeAllLists()
        abandonBestReplay()
        endPoolTableModes()
        strokeDrillStorage?.end()
        // Puts back any lesson surface first, so the shot's own surface below is the one that stays.
        lessonModeStorage?.end()
        cancelPendingSolve()
        leaveMatch()
        endPlacement(); ballInHand = .none
        undoStep = nil
        startHighlightRack()
        // A replayed clearing shot shows Table cleared without its chime: the chime is for clearing a rack, not for
        // watching one.
        clearedChimePlayed = true
        if tableKind != attempt.table {
            tableKind = attempt.table
            UserDefaults.standard.set(attempt.table.rawValue, forKey: TableKind.storageKey)
        }
        if surface != attempt.surface {
            // As setSurface stores it, without its re-solve: the load below puts the shot on screen.
            surface = attempt.surface
            UserDefaults.standard.set(attempt.surface.rawValue, forKey: PlaySurface.storageKey)
            surfaceVersion += 1
        }
        menuOpen = false
        gameInProgress = true
        panelAfterBreakDue = false
        requestShotPanel(.close)
        // Drops the ghost, the comparison, the retry seed and a kept what-if strike.
        clearAttempts()
        // Counts a shot nobody struck here, on purpose: tableCleared needs a count above zero, so a replayed shot that
        // left no object ball gets the Table cleared card and its Rack again. undoStep is nil above, so Undo cannot act
        // on it.
        shotsThisRack = 1
        showKeptRecording(attempt, input: attempt.input, classic: false, surface: attempt.surface, table: attempt.table,
                          generation: attempt.generation)
        // A scratch with object balls left: ball in hand once the replay has played, as finishStrike does in free play.
        let objectBallsLeft = layout.indices.contains { $0 != strikeBall && NextShot.isOnTable(layout[$0]) }
        if shotFacts?.cueBallScratched == true, objectBallsLeft {
            ballInHand = .anywhere
            placementDue = true
        }
        achievementReplayVersion = timelineVersion
        achievementReplayID = id
        // After the load: load gives back any held Ride and clears the signature.
        holdRideForGuidedReplay()
        setPaceSignature(signature)
        replay(withLens: true)
        lensReplayStartedByPlayer = true
    }

    /// Every frame: Table cleared sounds the bigger made-it once per rack, as its card appears (Haptics gives the
    /// made-it moments no pattern, so the card's own success haptic is the only one felt).
    private func chimeTableClearedIfDue() {
        guard !clearedChimePlayed, tableCleared else { return }
        clearedChimePlayed = true
        SoundBoard.play(.madeItBig)
    }

    // 0.7.7 clips: Lens clips (0.7.7, plans/23-Nov-2026-clips-plan.md). Three read-only views of the private highlight
    // and best shot for ClipOffer (App/Clips/ClipSource.swift); nothing here changes the model.

    /// The remarkable shot whose recording is on screen, whatever its card is doing (offered, watched or closed): the
    /// best shot's while it replays, else the judged highlight of this very recording. Nil for an ordinary shot.
    var highlightOnScreen: ShotHighlight? {
        if replayingBest { return bestShot?.highlight }
        guard let j = judgedHighlight, j.version == timelineVersion else { return nil }
        return j.highlight
    }

    /// True while the aim, power, tip and cue angle are exactly as the judged shot left them (no control touched).
    var highlightControlsUntouched: Bool {
        guard let j = judgedHighlight, j.version == timelineVersion else { return false }
        return controlValues == j.controls
    }

    /// The rack's best remarkable shot, as struck and solved, with its highlight; nil when the rack had none.
    var bestShotForClip: (attempt: ShotAttempt, highlight: ShotHighlight)? {
        guard let best = bestShot else { return nil }
        return (best.attempt, best.highlight)
    }

    // MARK: Worth watching: the end of Watch the intro

    /// The recording on which Watch the intro ended (its slow replay reached the end), and whether its card was closed.
    private var introEndVersion: Int?
    private var introEndDismissed = false
    /// Set by watchBreak() only, so the card follows Watch the intro and nothing else that plays the showpiece.
    @ObservationIgnored private var introWatchArmed = false

    /// The intro's slow replay has just moved to explore: remember that recording for the card.
    private func noteIntroEnded() {
        guard introWatchArmed, showpieceOnScreen, openingStage == .none, !menuBackdropPlaying else { return }
        introWatchArmed = false
        introEndVersion = timelineVersion
        introEndDismissed = false
    }

    /// The card at the end of Watch the intro (Trick shots, Practice, close): while that recording is on screen, at
    /// rest, the menu closed and the card not closed.
    var introEndOffered: Bool {
        guard let v = introEndVersion, v == timelineVersion, stage == .explore, aimReady, !menuOpen,
              !introEndDismissed else { return false }
        return true
    }

    func dismissIntroEnd() { introEndDismissed = true }

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
        // A ride's held beat counts as a hold too (0.7.6 stream ride): the card's Continue, the notebook's and the
        // controller's all end it through nextBeat.
        if rideHolding { return true }
        guard guided, let h = heldBeat, pacePlan.beats.indices.contains(h) else { return false }
        return abs(pacePlan.beats[h].time - time) <= Self.beatTolerance
    }

    /// Continue: end the current hold now; or, when not holding, jump straight to the next beat and hold there. The
    /// jump sets the clock directly, like a scrub, so the events skipped over make no sound. Does nothing unless guided.
    func nextBeat() {
        // A ride's held beat (0.7.6 stream ride): the next page first, as below, then the ride plays on.
        if rideHolding {
            if let id = heldCaptionID, holdPagesApply(caption: id), holdPage + 1 < holdPageShares.count {
                showHoldPage(holdPage + 1)
            } else {
                finishRideHold()
            }
            playing = true
            return
        }
        guard guided else { return }
        if holding, let h = heldBeat {
            // A caption split into pages: Continue shows the next page first, and its share of the hold starts now.
            if holdPagesApply(to: h), holdPage + 1 < holdPageShares.count {
                showHoldPage(holdPage + 1)
                if stage == .explore { playing = true }
                return
            }
            finishHold(h)
            // Continue on a held moment the player had paused plays on (0.7.5): ending the hold alone left the clock
            // stopped, so Continue seemed to do nothing. Only on the ordinary table; the cold open runs its own clock.
            if stage == .explore { playing = true }
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
        holdPage = 0
        // With Explanations off there is nothing to read, so the stop is only a short pause that lets the hit land.
        // An option never set reads as on (its default), hence the object lookup rather than bool(forKey:).
        let explanations = UserDefaults.standard.object(forKey: GameSettings.explanationsKey) as? Bool ?? true
        holdDwell = menuBackdropPlaying ? Self.backdropDwell : (explanations ? pacePlan.beats[i].dwell : 0.6)
        holdDwellChecked = !explanations || menuBackdropPlaying
        checkHoldDwell(i)
    }

    /// The held beat's dwell has been compared with the words the card really shows (see checkHoldDwell).
    @ObservationIgnored private var holdDwellChecked = true

    /// The card can show more words than the beat's own caption: the strike's gains a sentence on the player's stroke
    /// (displayedCaption). The hold then lasts the reading time of what is actually shown (0.7.6, entry 4), worked out
    /// the plan's own way (capped on the first launch only). That sentence only shows once the Lens is up, and a Lens
    /// replay can stop on the strike at its first frame while the Lens is still fading in, so this runs once the Lens
    /// is up: from beginHold, or from the hold's own frames (stepGuided). Once per hold; it only ever lengthens it.
    private func checkHoldDwell(_ i: Int) {
        guard !holdDwellChecked, lensOn, pacePlan.beats.indices.contains(i) else { return }
        holdDwellChecked = true
        let beat = pacePlan.beats[i]
        if let shown = displayedCaption(), shown.id == beat.caption.id, shown.detail != beat.caption.detail {
            holdDwell = max(holdDwell, pacePlan.dwell(for: shown.detail))
        }
    }

    /// True while the clock holds a headline beat of the opening (the cue ball handing its speed to the rack, skid
    /// turning into roll): its equation shows with the event's own numbers even with Show the maths off (item 55).
    var holdingHeadline: Bool {
        guard holding, let h = heldBeat, pacePlan.beats.indices.contains(h) else { return false }
        return pacePlan.beats[h].headline
    }

    /// The card says how the caption with event index `id` is split: one weight per page (its reading length, any unit).
    /// Called by CaptionStrip whenever its layout of the caption changes; one page, or a caption not being held, simply
    /// resets to a single page.
    func setHoldPages(caption id: Int, weights: [Double]) {
        let total = weights.reduce(0, +)
        guard weights.count > 1, total > 0 else {
            holdPageShares = [1]; holdPagesCaption = nil
            if holdPage != 0 { holdPage = 0 }
            return
        }
        holdPageShares = weights.map { $0 / total }
        holdPagesCaption = id
        if holdPage >= weights.count { holdPage = weights.count - 1 }
    }

    /// Number of pages of the held caption (1 when it fits or nothing is held).
    var holdPageCount: Int {
        guard holding, let id = heldCaptionID, holdPagesApply(caption: id) else { return 1 }
        return holdPageShares.count
    }

    /// Show page `i` of the held caption (a tapped page dot, or Continue): the hold's counter jumps to the start of that
    /// page's share, so the page then gets its full reading time. Going back a page is allowed the same way.
    func showHoldPage(_ i: Int) {
        guard holding, let id = heldCaptionID, holdPagesApply(caption: id), holdPageShares.indices.contains(i) else { return }
        holdPage = i
        holdElapsed = holdPageShares.prefix(i).reduce(0, +) * holdDwell
    }

    /// True when the pages the card reported belong to beat `h`'s caption.
    private func holdPagesApply(to h: Int) -> Bool {
        guard pacePlan.beats.indices.contains(h) else { return false }
        return holdPagesApply(caption: pacePlan.beats[h].caption.id)
    }

    /// True when the pages the card reported belong to the caption with event index `id` (0.7.6 stream ride: shared
    /// by the guided hold and the ride's).
    private func holdPagesApply(caption id: Int) -> Bool {
        holdPageShares.count > 1 && holdPagesCaption == id
    }

    /// The event index of the caption being held now: the ride's held beat's, or the guided hold's; nil when nothing
    /// with words is held.
    private var heldCaptionID: Int? {
        if rideHolding { return rideHeldCaption?.id }
        guard holding, let h = heldBeat, pacePlan.beats.indices.contains(h) else { return nil }
        return pacePlan.beats[h].caption.id
    }

    /// Move the page on screen on to the one the hold's counter has reached (never back). Shared by the guided hold
    /// and the ride's (0.7.6 stream ride).
    private func followHoldPage() {
        var end = 0.0
        for (i, share) in holdPageShares.enumerated() {
            end += share * holdDwell
            if holdElapsed < end || i == holdPageShares.count - 1 {
                if i > holdPage { holdPage = i }
                break
            }
        }
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
            // The Lens tips are showing over this beat: it waits for them (never behind the menu, where no tip shows).
            if holdForTips, !menuBackdropPlaying { return }
            checkHoldDwell(h)
            holdElapsed += dt
            // The page follows the counter: each page gets its share of the reading time.
            if holdPagesApply(to: h) { followHoldPage() }
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
    /// shown for a short while after it that depends on the playback speed; with the Lens on the ordinary table only
    /// the beats count (0.7.6, entry 6), so a break at a fixed speed or under Ride shows a few steady cards instead of
    /// swapping its words many times a second.
    func activeCaption() -> Caption? {
        // The ride's held beat shows its own caption for as long as it is held (0.7.6 stream ride).
        if let c = rideHeldCaption { return c }
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
        // Lens on but not guided (a speed the player picked, Ride on, a shot struck with the Lens up): the latest beat
        // at or before the clock, for the same while. Only on the ordinary table, so the opening's own stages (the
        // first minute) show exactly what they did; a plan with no beats falls through to every caption.
        if stage == .explore, (meltTarget ?? melt) > 0.5, pacePlan.hasBeats {
            let after = pacePlan.firstBeat(atOrAfter: time + Self.beatTolerance)
            guard after > 0 else { return nil }
            let c = beats[after - 1].caption
            return time - c.time <= hold ? c : nil
        }
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
