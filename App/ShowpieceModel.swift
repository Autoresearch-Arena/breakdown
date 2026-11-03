// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: The showpiece's brain. Runs the cold open as a small state machine (normal break at full speed,
//          freeze, melt into the Lens, rewind, slow-motion replay) on top of the recorded timeline, then hands
//          control to the player: play, pause, scrub, speed, Lens on and off, a new break of their own.
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

    private var stageTime = 0.0
    private let freezeTime: Double
    private let sound = SoundBoard()

    init() {
        let tl = PoolSolver.simulate(Rack.showpieceBreak())
        timeline = tl
        freezeTime = min(2.2, tl.duration * 0.4)
        captions = CaptionEngine.make(from: tl)
        timelineVersion = 1
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

    private func load(_ tl: Timeline) {
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
