// Author: Claude Sonnet 5.5 Medium
// Date: 11-November-2026
// PURPOSE: The showpiece's brain. Runs the cold open as a small state machine (normal break at full speed,
//          freeze, melt into the Lens, rewind, slow-motion replay) on top of the recorded timeline, then hands
//          control to the player: play, pause, scrub, speed, Lens on and off, a new break of their own, and then
//          shot after shot from wherever the balls came to rest (aim, power, cue-tip height and side).
//          The timeline is solved once; this only moves a playback clock over it, so replay, reverse and slow
//          motion are exact. Sound fires as the clock crosses recorded events.
// SRP/DRY check: Pass - playback state and flow only; drawing is TableScene, wording is CaptionEngine.
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
                                   speed: power, tipUp: tipHeight)
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
        // Events are sorted by time, so scan only the span crossed this frame.
        var fired = 0
        for e in timeline.events where e.time > a && e.time <= b {
            sound.play(e)
            fired += 1
            if fired >= 6 { break }
        }
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
