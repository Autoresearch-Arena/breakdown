// Author: Claude Sonnet 5.5 High
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
// SRP/DRY check: Pass - playback state and flow only; drawing is TableScene, wording is CaptionEngine. The break/shot
//          split is hidden behind the active values here so the views never repeat the racked-or-not choice.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import Observation

enum Stage: Equatable {
    case lead, normalBreak, freeze, melt, rewind, slowReplay, explore
}

@MainActor
@Observable
final class ShowpieceModel {
    private(set) var timeline: Timeline
    /// Bumped whenever a new timeline is loaded so the scene knows to rebuild its Lens layer.
    private(set) var timelineVersion = 0
    private(set) var captions: [Caption] = []

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
    /// What the retry changed and what happened differently; shown once the retry has played out.
    private(set) var comparison: String?
    /// Set by tryAgain() so the next shot keeps the ghost and is compared with it.
    private var retryPending = false

    // Ride the shot (see ShotCamera).
    /// True when the player (or the trick-shot mode, through setRide) wants the Ride camera for replays.
    private(set) var rideOn = false
    /// The key moments the ride and its slow motion read: first contact, struck ball, rise. Worked out once per shot.
    private(set) var ridePlan = RidePlan.none

    private var stageTime = 0.0
    private let freezeTime: Double
    private let sound = SoundBoard()
    private let haptics = Haptics()

    init() {
        let tl = PoolSolver.simulate(Rack.showpieceBreak())
        timeline = tl
        freezeTime = min(2.2, tl.duration * 0.4)
        captions = CaptionEngine.make(from: tl)
        timelineVersion = 1
        ridePlan = RidePlan(tl)
        adoptLayout(after: tl)
        startRideDemoIfAsked()
        if ProcessInfo.processInfo.arguments.contains("-jumpDemo") { playJumpDemo() }
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
        load(PoolSolver.simulate(input))
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
    }

    // MARK: Menu

    /// Back to the main menu: pause whatever is on the table; Continue picks it up exactly where it was.
    func openMenu() {
        playing = false
        menuOpen = true
    }

    /// Continue: close the menu and leave the table as it was.
    func closeMenu() { menuOpen = false }

    /// Play: a fresh rack, ready for the player's own break. The view opens the aiming controls.
    func startGame() {
        shotElevation = 0      // free play is always a level cue
        menuOpen = false
        gameInProgress = true
        rerack()
        setLens(false)
    }

    /// Watch the break: the showpiece opening, with the slow-motion Physics Lens replay, from the start.
    func watchBreak() {
        menuOpen = false
        gameInProgress = true
        load(PoolSolver.simulate(Rack.showpieceBreak()))
        clearAttempts()
        startColdOpen()
        stage = .normalBreak
    }

    /// The player's own break: solve it, then run it through the same cold open.
    func breakNow() {
        var p = PoolParameters()
        p.version = 1
        breakSerial += 1
        let seed = UInt64(10 + breakSerial)
        let input = Rack.breakShot(parameters: p, seed: seed, aimOffset: aimOffset,
                                   speed: power, tipUp: tipHeight, tipSide: breakTipSide)
        // Recorded before load(), which re-aims the follow-up shot and would otherwise change nothing here, but the
        // attempt must hold exactly what was struck.
        let settings = (aim: aimOffset, power: power, up: tipHeight, side: breakTipSide, range: powerRange)
        load(PoolSolver.simulate(input))
        record(ShotAttempt(isBreak: true, breakSeed: seed, start: input.positions, timeline: timeline, aim: settings.aim,
                           power: settings.power, powerRange: settings.range, tipUp: settings.up, tipSide: settings.side))
        startColdOpen()
        stage = .normalBreak
    }

    /// Fresh rack, ready for a new break (the panel's break sliders drive it).
    func rerack() {
        // Same seed the next break will use, so the rack on screen is exactly the one that gets broken.
        let seed = UInt64(10 + breakSerial + 1)
        var p = PoolParameters()
        p.version = 1
        // A zero-speed strike records a table where nothing moves: the quickest way to put the rack on screen.
        load(PoolSolver.simulate(Rack.breakShot(parameters: p, seed: seed, aimOffset: 0, speed: 0)))
        layout = Rack.positions(parameters: p, seed: seed)
        racked = true
        clearAttempts()
        stage = .explore; time = 0; playing = false; chosenRate = nil
    }

    /// Take the next shot from the resting layout. Skips the cold open: straight to the recorded replay,
    /// at real speed, with the Lens left as the player had it.
    func shootNow() {
        guard layout.count == 16, !racked else { return }
        shotSerial += 1
        // Trig lives here in the app; the solver only ever sees a unit vector.
        let a = aimDegrees * Double.pi / 180
        let input = NextShot.shot(from: layout, direction: Vec2(cos(a), sin(a)), speed: shotPower,
                                  tipUp: shotTipUp, tipSide: shotTipSide, seed: UInt64(1000 + shotSerial),
                                  elevation: shotElevation)
        let settings = (aim: aimDegrees, power: shotPower, up: shotTipUp, side: shotTipSide, range: powerRange)
        load(PoolSolver.simulate(input))
        record(ShotAttempt(isBreak: false, breakSeed: 0, start: input.positions, timeline: timeline, aim: settings.aim,
                           power: settings.power, powerRange: settings.range, tipUp: settings.up, tipSide: settings.side))
        stage = .explore; stageTime = 0; time = 0; playing = true
        chosenRate = 1; displayRate = 1
        meltTarget = melt > 0.5 ? 1 : nil
    }

    /// Where the cue would travel with the current aim, for the on-table guide line.
    var shotAimDirection: Vec2 {
        let a = aimDegrees * Double.pi / 180
        return Vec2(cos(a), sin(a))
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
        load(PoolSolver.simulate(RideDemo.straightPot()))
        stage = .explore; time = 0; playing = false; chosenRate = nil
        if option == "lens" { melt = 1 }
        // Start after a beat, once the dark launch cover has faded, so the strike is seen.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.6))
            self?.playing = true
        }
    }

    // MARK: Try again and compare

    /// Try again is offered once a shot the player took has played out (the balls on screen are its result).
    var canTryAgain: Bool { currentAttempt != nil && aimReady }

    /// The comparison card shows once the retry has finished playing, so it never talks over the shot.
    var comparisonReady: Bool { comparison != nil && stage == .explore && time >= duration - 1e-6 }

    /// Put every ball back where the last shot started, with the same aim, power and spin, and keep that shot as the
    /// ghost. Change one thing and shoot again to see the difference. For the break this re-racks the identical rack.
    func tryAgain() {
        guard let attempt = currentAttempt, aimReady else { return }
        if attempt.isBreak {
            // rerack() lays out the rack for seed 10 + breakSerial + 1, and breakNow() breaks seed 10 + breakSerial
            // after adding one: stepping the serial back one makes both the identical rack the attempt broke.
            breakSerial = Int(attempt.breakSeed) - 11
            rerack()
            aimOffset = attempt.aim; power = attempt.power; tipHeight = attempt.tipUp; breakTipSide = attempt.tipSide
        } else {
            // A zero-speed strike records a still table: the quickest way to put the starting layout on screen.
            load(PoolSolver.simulate(NextShot.shot(from: attempt.start, direction: Vec2(1, 0), speed: 0, tipUp: 0,
                                                   tipSide: 0, seed: 0)))
            layout = attempt.start
            racked = false
            clearAttempts()
            aimDegrees = attempt.aim; shotPower = attempt.power; shotTipUp = attempt.tipUp; shotTipSide = attempt.tipSide
            stage = .explore; time = 0; playing = false; chosenRate = nil
        }
        ghost = attempt
        ghostVersion += 1
        retryPending = true
    }

    /// Put the comparison card away; the ghost stays until the next fresh shot.
    func dismissComparison() { comparison = nil }

    /// A new player attempt is on screen. A retry is compared with the ghost; any other shot starts afresh.
    private func record(_ attempt: ShotAttempt) {
        if retryPending, let previous = ghost {
            comparison = ShotComparison.describe(previous: previous, current: attempt)
            // Same start, same settings: the recordings must match exactly. Logged for the -retryDemo check.
            if Self.logRetry {
                NSLog("RETRY compare: previous motion %llu, this motion %llu, same settings %@ -> %@",
                      previous.motionHash, attempt.motionHash,
                      Self.sameSettings(previous, attempt) ? "yes" : "no", comparison ?? "")
            }
        } else {
            if ghost != nil { ghostVersion += 1 }
            ghost = nil; comparison = nil
        }
        retryPending = false
        currentAttempt = attempt
    }

    private func clearAttempts() {
        currentAttempt = nil
        if ghost != nil { ghostVersion += 1 }
        ghost = nil; comparison = nil; retryPending = false
    }

    static func sameSettings(_ a: ShotAttempt, _ b: ShotAttempt) -> Bool {
        a.aim == b.aim && a.power == b.power && a.tipUp == b.tipUp && a.tipSide == b.tipSide && a.start == b.start
    }

    private static let logRetry = ProcessInfo.processInfo.arguments.contains("-retryDemo")

    // MARK: Aim by touch

    /// How far from the apex ball the break may be aimed, metres. Wide enough to choose the second row instead.
    static let breakAimLimit = 0.05
    /// How far from the middle of the cue ball the tip may land, metres (past this the cue slips off the ball).
    static let tipLimit = 0.02
    /// How far behind the cue ball a pull-back reaches full power, metres.
    static let pullReach = 0.5

    /// True when the balls on screen are the balls the next shot starts from: the shot on screen has played out.
    /// Aiming is only offered then, because the guide is drawn from where the cue ball ended up.
    var aimReady: Bool { stage == .explore && time >= duration - 1e-6 }

    /// Where the cue ball sits for the next shot (the head spot while racked).
    var aimOrigin: Vec2 { layout.first ?? .zero }

    /// The unit direction the next strike goes in: from the cue ball toward the apex ball (nudged by the aim offset)
    /// for the break, or the aim angle for a shot. One answer for the guide, the ghost preview and the strike.
    var aimDirection: Vec2 {
        guard layout.count == 16 else { return Vec2(1, 0) }
        if racked { return (layout[1] + Vec2(0, aimOffset) - layout[0]).normalized }
        return shotAimDirection
    }

    /// Launch speed for the next strike, metres per second, and the range it may take.
    var powerRange: ClosedRange<Double> { racked ? 7...13 : 0.5...8 }
    var activePower: Double {
        get { racked ? power : shotPower }
        set { let v = min(max(newValue, powerRange.lowerBound), powerRange.upperBound); if racked { power = v } else { shotPower = v } }
    }
    /// Power as 0 (softest) to 1 (hardest), for the gauge and the pull-back.
    var powerFraction: Double {
        get { (activePower - powerRange.lowerBound) / (powerRange.upperBound - powerRange.lowerBound) }
        set { activePower = powerRange.lowerBound + min(max(newValue, 0), 1) * (powerRange.upperBound - powerRange.lowerBound) }
    }

    /// Cue-tip contact point on the cue ball, metres: up is follow, down is draw, right and left are side spin.
    var activeTipUp: Double {
        get { racked ? tipHeight : shotTipUp }
        set { if racked { tipHeight = newValue } else { shotTipUp = newValue } }
    }
    var activeTipSide: Double {
        get { racked ? breakTipSide : shotTipSide }
        set { if racked { breakTipSide = newValue } else { shotTipSide = newValue } }
    }

    /// Aim so the cue travels through a spot on the table. For a shot that is any direction; for the break the
    /// strike is always at the rack, so the spot only chooses how far off the apex ball to hit.
    func aim(toward point: Vec2) {
        guard layout.count == 16 else { return }
        let from = layout[0]
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
    }

    /// Break or shoot, whichever is next. Returns true when it was the break (the cue ball's cold open takes over the
    /// screen, so the aiming controls close).
    @discardableResult
    func fire() -> Bool {
        if racked { breakNow(); return true }
        shootNow()
        return false
    }

    /// Point the cue at the nearest ball still on the table.
    func aimAtNearestBall() {
        guard layout.count == 16, let d = NextShot.directionToNearestObjectBall(in: layout) else { return }
        aimDegrees = atan2(d.y, d.x) * 180 / Double.pi
    }

    /// Record where everything stopped so the next shot starts from there.
    private func adoptLayout(after tl: Timeline) {
        layout = NextShot.layout(after: tl)
        racked = false
        aimAtNearestBall()
    }

    private func load(_ tl: Timeline) {
        adoptLayout(after: tl)
        timeline = tl
        captions = CaptionEngine.make(from: tl)
        ridePlan = RidePlan(tl)
        timelineVersion += 1
    }

    // MARK: Player controls

    func scrub(to t: Double) {
        finishColdOpen()
        playing = false
        time = min(max(0, t), duration)
    }

    func togglePlay() {
        finishColdOpen()
        if time >= duration - 1e-6 { time = 0 }
        playing.toggle()
    }

    func setRate(_ r: Double) {
        finishColdOpen()
        chosenRate = r
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
        chosenRate = withLens ? 0.25 : 1
    }

    /// Jump to the hand-over state: Lens on, clock where it is.
    private func finishColdOpen() {
        guard stage != .explore else { return }
        stage = .explore
        if melt < 1, meltTarget == nil { meltTarget = 1 }
    }

    // MARK: Per-frame step

    func advance(_ rawDt: Double) {
        let dt = min(rawDt, 1.0 / 20.0)
        // The menu freezes the table behind it, whatever stage it is in.
        if menuOpen { return }
        switch stage {
        case .lead:
            stageTime += dt
            if stageTime > 1.1 { stage = .normalBreak; stageTime = 0 }
        case .normalBreak:
            displayRate = 1
            step(dt)
            if time >= freezeTime { time = freezeTime; stage = .freeze; stageTime = 0 }
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
            time = freezeTime * (1 - x * x * (3 - 2 * x))
            if x >= 1 { time = 0; stage = .slowReplay; stageTime = 0 }
        case .slowReplay:
            displayRate = chosenRate ?? Self.autoRate(at: time)
            step(dt)
            if time >= duration { stage = .explore; playing = false; chosenRate = nil }
        case .explore:
            // With Ride on, playback eases into slow motion around the first contact and back out; the curve is a
            // function of the clock, so it plays the same however the clock got there. Any speed the player picked
            // still applies: the curve multiplies it.
            displayRate = (chosenRate ?? 1) * (rideActive ? ridePlan.rateFactor(at: time) : 1)
            if playing { step(dt) }
            if let target = meltTarget {
                let speed = 1.8
                if melt < target { melt = min(target, melt + dt * speed) } else { melt = max(target, melt - dt * speed) }
                if melt == target { meltTarget = nil }
            }
        }
    }

    /// Slow motion that breathes: very slow through the rack, easing back to real time.
    static func autoRate(at t: Double) -> Double {
        switch t {
        case ..<0.30: return 0.05
        case ..<0.80: return 0.12
        case ..<1.60: return 0.30
        default: return 0.8
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

    /// Onto the table from the menu for a trick shot: the menu closes and Continue will come back here.
    func enterTrickTable() {
        menuOpen = false
        gameInProgress = true
    }

    /// Put an authored layout on the table, still, with the given aim (degrees), power, tip height and side ready for
    /// the next shot. The same zero-speed trick tryAgain() uses; the settings are set after load(), which re-aims.
    /// `elevation` raises the cue (sine of its angle) for the massé and the jump; every other shot is level.
    func loadTrickLayout(_ positions: [Vec2], aim: Double, power: Double, tipUp: Double, tipSide: Double, elevation: Double = 0) {
        load(PoolSolver.simulate(NextShot.shot(from: positions, direction: Vec2(1, 0), speed: 0, tipUp: 0, tipSide: 0, seed: 0)))
        layout = positions
        racked = false
        clearAttempts()
        aimDegrees = aim; shotPower = power; shotTipUp = tipUp; shotTipSide = tipSide; shotElevation = elevation
        stage = .explore; stageTime = 0; time = 0; playing = false; chosenRate = nil
    }

    /// Put the rack built from `seed` on the table, ready for a break with the given settings. breakNow() breaks seed
    /// 10 + breakSerial after adding one, and rerack() lays out that same seed, so stepping the serial to seed - 11 makes
    /// both the authored rack (the same arithmetic tryAgain() uses for a break).
    func loadTrickRack(seed: UInt64, aimOffset: Double, power: Double, tipUp: Double, tipSide: Double) {
        breakSerial = Int(seed) - 11
        rerack()
        self.aimOffset = aimOffset; self.power = power; tipHeight = tipUp; breakTipSide = tipSide
    }

    // MARK: Captions

    func activeCaption() -> Caption? {
        let hold = playing || stage != .explore ? max(0.4, 3.4 * displayRate) : 3.0
        var found: Caption?
        for c in captions where c.time <= time {
            if time - c.time <= hold { found = c }
        }
        return found
    }
}
