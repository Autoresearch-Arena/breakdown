// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
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
    private(set) var shotSerial = 0

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
        adoptLayout(after: tl)
    }

    var duration: Double { timeline.duration }
    var lensOn: Bool { melt > 0.5 }
    var stageTitle: String {
        switch stage {
        case .lead: return ""
        case .normalBreak: return "The break"
        case .freeze: return "Hold on"
        case .melt: return "Now look at what the table is doing"
        case .rewind: return "Rewind"
        case .slowReplay: return "Slow motion"
        case .explore: return lensOn ? "Physics Lens" : "Table"
        }
    }

    // MARK: Cold open

    func startColdOpen() {
        stage = .lead; stageTime = 0; time = 0; melt = 0; meltTarget = nil
        playing = true; chosenRate = nil
    }

    /// The player's own break: solve it, then run it through the same cold open.
    func breakNow() {
        var p = PoolParameters()
        p.version = 1
        breakSerial += 1
        let input = Rack.breakShot(parameters: p, seed: UInt64(10 + breakSerial), aimOffset: aimOffset,
                                   speed: power, tipUp: tipHeight, tipSide: breakTipSide)
        load(PoolSolver.simulate(input))
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
                                  tipUp: shotTipUp, tipSide: shotTipSide, seed: UInt64(1000 + shotSerial))
        load(PoolSolver.simulate(input))
        stage = .explore; stageTime = 0; time = 0; playing = true
        chosenRate = 1; displayRate = 1
        meltTarget = melt > 0.5 ? 1 : nil
    }

    /// Where the cue would travel with the current aim, for the on-table guide line.
    var shotAimDirection: Vec2 {
        let a = aimDegrees * Double.pi / 180
        return Vec2(cos(a), sin(a))
    }

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
            displayRate = chosenRate ?? 1
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
