// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: The sound of a Lens clip (0.7.7, plans/23-Nov-2026-clips-plan.md, Step 7): the game's own contact sounds,
//          mixed offline into two channels, exactly as play would sound them.
//          plan(frames:timeline:surface:rights:variants:) walks the clip's frames and, on every frame that sounds and
//          moves the clock forward from a to b, takes the recorded events after a up to b (and one stamped exactly 0
//          when a is 0), which is ShowpieceModel.fireSounds' own rule; FeelMapping turns them into cues; each cue gets
//          the voice, strength layer, seeded variant (never the same twice in a row), volume with its seeded jitter and
//          stereo pan the live board would give it (the VoiceBook helpers and SoundStage's pure pan), and its small
//          delay stretched in slow motion as the game stretches it. Nothing is sounded while a ball travels, during
//          the lead, the pause, the melt, the rewind, a held moment or the end card: only contacts, as in play, and
//          the Moon sounds like everywhere else. The clip always carries these sounds whatever the Sound option says
//          (the option is about this device making noise; a clip is a film for someone else).
//          mix(_:bank:duration:) adds each sound's samples at its time, panned with equal power, then scales the whole
//          clip down once if its loudest sample passes 0.89 (one gain for the whole clip, so nothing pumps).
//          The voices come from the same pure build the live board runs (VoiceSynth.buildBank, same seeds, same
//          sounds), built once per launch on a background task the first time a clip needs them.
//          Pure and nonisolated: ClipMaker runs it off the main actor.
// SRP/DRY check: Pass - reuses FeelMapping.cues, VoiceBook's per-play helpers, SoundStage's pure pan and stretch and
//          VoiceSynth's bank; the only new thing is writing them into samples instead of playing them.
import BreakdownLensModel
import BreakdownTimeline
import Foundation
import simd

/// One sound in the clip.
struct ClipSound: Equatable, Sendable {
    /// When it starts, seconds of film.
    var time: Double
    var voice: Voice
    /// The strength layer and variant in the voice bank.
    var layer: Int
    var variant: Int
    var volume: Double
    /// -1 left to 1 right.
    var pan: Float

    static let sampleRate = VoiceSynth.sampleRate
    /// The loudest a sample may be after the mix (a little under full scale, as the live limiter keeps it).
    static let peak: Float = 0.89

    /// The clip's sounds, in time order.
    /// - rights: the camera's right-hand direction on each frame (ClipRenderer records it), for the pan.
    /// - variants: how many variants the bank holds for a voice at a layer (a closure, so the plan can be tested
    ///   without building the bank).
    static func plan(frames: [ClipFrame], timeline: Timeline, surface: PlaySurface, rights: [SIMD3<Float>],
                     variants: (Voice, Int) -> Int, layers: (Voice) -> Int = { _ in VoiceBook.strengths.count })
        -> [ClipSound] {
        let fps = ClipScript.fps
        let tableFrame = TableFrame(timeline.table)
        let surfaceSound = SurfaceSound(surface)
        var random = SoundRandom(seed: VoiceBook.playSeed)
        var lastVariant: [Voice: Int] = [:]
        var out: [ClipSound] = []
        var previous = 0.0
        for (i, f) in frames.enumerated() {
            let a = previous, b = f.clock
            previous = b
            guard f.sounds, b > a else { continue }
            let crossed = timeline.events.filter { ($0.time > a || (a <= 0 && $0.time <= 0)) && $0.time <= b }
            guard !crossed.isEmpty else { continue }
            let right = i < rights.count ? rights[i] : SIMD3<Float>(1, 0, 0)
            for cue in FeelMapping.cues(for: crossed) {
                let voice = VoiceBook.voice(for: cue.kind, surface: surfaceSound)
                let layer = VoiceBook.layerIndex(strength: cue.strength, count: max(1, layers(voice)))
                // Same order of random draws as SoundBoard.fire: the variant first, then the level jitter.
                let variant = VoiceBook.pickVariant(count: variants(voice, layer), last: lastVariant[voice],
                                                    random: &random)
                lastVariant[voice] = variant
                let jitter = 1 + VoiceBook.levelJitter * random.signed()
                let volume = VoiceBook.volume(cue.kind, strength: cue.strength, jitter: jitter)
                let pan = cue.point.map { SoundStage.pan($0, frame: tableFrame, right: right) } ?? 0
                let time = Double(i) / fps + SoundStage.stretch(cue.delay, rate: f.rate)
                out.append(ClipSound(time: time, voice: voice, layer: layer, variant: variant, volume: volume, pan: pan))
            }
        }
        return out.sorted { $0.time < $1.time }
    }

    /// The clip's two channels, `duration` seconds long: each sound's samples added at its start with an equal-power
    /// pan, then one gain for the whole clip if the loudest sample passes `peak`. Nothing past `duration`.
    static func mix(_ sounds: [ClipSound], bank: VoiceBank, duration: Double) -> (left: [Float], right: [Float]) {
        let count = max(0, Int((duration * sampleRate).rounded()))
        var left = [Float](repeating: 0, count: count)
        var right = [Float](repeating: 0, count: count)
        for s in sounds {
            guard let layers = bank.voices[s.voice], layers.indices.contains(s.layer),
                  layers[s.layer].indices.contains(s.variant) else { continue }
            let samples = layers[s.layer][s.variant]
            let start = Int((s.time * sampleRate).rounded())
            guard start < count, !samples.isEmpty else { continue }
            // Equal power: the two gains' squares add to one, so a sound keeps its loudness wherever it is panned.
            let angle = Double(s.pan + 1) * Double.pi / 4
            let gl = Float(cos(angle) * s.volume), gr = Float(sin(angle) * s.volume)
            let first = max(0, start)
            let last = min(count, start + samples.count)
            guard first < last else { continue }
            for n in first..<last {
                let v = samples[n - start]
                left[n] += v * gl
                right[n] += v * gr
            }
        }
        var loudest: Float = 0
        for n in 0..<count { loudest = max(loudest, abs(left[n]), abs(right[n])) }
        if loudest > peak {
            let g = peak / loudest
            for n in 0..<count { left[n] *= g; right[n] *= g }
        }
        return (left, right)
    }
}

/// The voice bank for clips: the same pure build as the live board's (same seeds, same sounds), made once per launch
/// on a background task the first time a clip needs it, then kept.
@MainActor
enum ClipVoiceBank {
    private static var building: Task<VoiceBank, Never>?

    static func bank() async -> VoiceBank {
        if let building { return await building.value }
        let task = Task.detached(priority: .userInitiated) { VoiceSynth.buildBank() }
        building = task
        return await task.value
    }
}
