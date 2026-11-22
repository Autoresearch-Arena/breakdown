// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (sound-lessons hook, bug plan item 36: the two made-it voices appended
//          to Voice and to the end of Voice.all, so every earlier voice keeps its seeded variants.)
// PURPOSE: The synthesiser behind every table sound (sound plan package 1). Turns a voice recipe (a small table of
//          ringing partials plus short noise bursts, written at the top of SoundBoard.swift in VoiceBook) into plain
//          sample arrays: four strength layers per voice, each in two or three variants with small seeded changes of
//          pitch and level, so no two hits in a row are the same sample. A harder layer is brighter, not only louder:
//          partials marked "bright" grow with strength and the contact burst gets shorter and crisper. Also makes the
//          two looping noises the rolling voices are shaped from.
//          Everything here is pure and free of any audio framework or actor, so SoundBoard can build the whole bank on
//          a background task at launch (it returns Sendable arrays; SoundBoard wraps them into audio buffers on the
//          main actor). Same seeds every launch: the sounds are identical from run to run.
// SRP/DRY check: Pass - synthesis only. What to build (the recipes and levels) lives in VoiceBook in SoundBoard.swift;
//          when and where to play lives in SoundBoard. Replaces the inline synth closure SoundBoard used to carry.
import Foundation

/// One ringing partial of a voice: a sine at `hz` starting at `start` seconds, fading at `fade` per second
/// (amplitude falls by e every 1/fade seconds), optionally gliding down `glide` hertz per second (a body that sags as
/// it rings). `bright` (0 to 1) is how much its level depends on strength: 0 is the same at every strength, 1 is
/// proportional to it, so marking the upper partials bright makes harder hits brighter.
struct Partial: Sendable {
    var hz: Double
    var level: Double
    var fade: Double
    var bright: Double
    var glide: Double
    var start: Double
    init(_ hz: Double, _ level: Double, fade: Double, bright: Double = 0, glide: Double = 0, at start: Double = 0) {
        self.hz = hz; self.level = level; self.fade = fade; self.bright = bright; self.glide = glide; self.start = start
    }
}

/// A short burst of filtered noise: the contact itself. `tone` (0 to 1) opens a simple low-pass (0 dark, 1 raw
/// hiss); `fade` is per second at the middle strength, and a harder hit fades faster (a crisper contact).
struct Burst: Sendable {
    var level: Double
    var fade: Double
    var tone: Double
    var bright: Double
    var start: Double
    init(_ level: Double, fade: Double, tone: Double, bright: Double = 0.5, at start: Double = 0) {
        self.level = level; self.fade = fade; self.tone = tone; self.bright = bright; self.start = start
    }
}

/// A whole voice: its length, its partials and bursts, and how far the seeded variants may stray in pitch.
struct VoiceRecipe: Sendable {
    var seconds: Double
    var partials: [Partial]
    var bursts: [Burst]
    /// Each variant's pitch is scaled by a seeded factor within 1 plus or minus this.
    var pitchSpread: Double = 0.025
}

/// Every sound SoundBoard can play. Rail and landing come in one voice per bed tone (SurfaceSound).
enum Voice: Hashable, Sendable {
    case crack, click, tock, rail(BedTone), pocketDrop, knock, pin, post, landing(BedTone), offTable, rimSkip, miscue,
         settle, foul, turnChange, win
    case madeIt, madeItBig   // the made-it moments (sound-lessons, 0.7.0 item 36); recipes in VoiceBook

    static var all: [Voice] {
        var v: [Voice] = [.crack, .click, .tock, .pocketDrop, .knock, .pin, .post, .offTable, .rimSkip, .miscue,
                          .settle, .foul, .turnChange, .win]
        for t in BedTone.allCases { v.append(.rail(t)); v.append(.landing(t)) }
        // Appended last, after the bed tones, so every earlier voice keeps its place and its seeded variants.
        v += [.madeIt, .madeItBig]
        return v
    }
}

/// A small deterministic random source (SplitMix64): seeded, so variants and per-play changes repeat run to run.
struct SoundRandom: Sendable {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    /// Uniform in 0..<1.
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
    /// Uniform in -1..<1.
    mutating func signed() -> Double { unit() * 2 - 1 }
}

/// The built sounds, as plain samples: per voice, per strength layer (soft to hard), per variant.
struct VoiceBank: Sendable {
    var voices: [Voice: [[[Float]]]]
    var rollSmooth: [Float]
    var rollGrit: [Float]
}

enum VoiceSynth {
    /// Every buffer is mono at this rate; the engine's mixer converts to the hardware rate.
    static let sampleRate = 44_100.0
    /// Each buffer is scaled so its loudest sample sits here, leaving headroom for several sounds at once (the limiter
    /// catches the rest).
    static let peak = 0.9

    /// Build every voice at every strength layer and variant, and the rolling noises. Pure and slow-ish (a few
    /// hundred thousand samples of sines): call it off the main thread.
    static func buildBank() -> VoiceBank {
        var voices: [Voice: [[[Float]]]] = [:]
        // One random stream per voice, from the book's seed and the voice's place in the list, so a voice added at the
        // end of the list leaves every other voice's variants exactly as they were.
        for (n, voice) in Voice.all.enumerated() {
            var rng = SoundRandom(seed: VoiceBook.buildSeed &+ UInt64(n) &* 0x1000_0001)
            let recipe = VoiceBook.recipe(voice)
            let count = VoiceBook.variants(voice)
            // The variants' pitch and level changes are drawn once per voice and shared by its strength layers, so a
            // variant is the same "ball" at every strength.
            let pitches = (0..<count).map { _ in 1 + recipe.pitchSpread * rng.signed() }
            let jitters = (0..<count).map { _ in recipe.partials.map { _ in 1 + 0.1 * rng.signed() } }
            let noiseSeeds = (0..<count).map { _ in rng.next() }
            voices[voice] = VoiceBook.strengths.map { s in
                (0..<count).map { v in
                    render(recipe, strength: s, pitch: pitches[v], levelJitter: jitters[v], noiseSeed: noiseSeeds[v])
                }
            }
        }
        return VoiceBank(voices: voices, rollSmooth: rollingNoise(), rollGrit: gritNoise())
    }

    /// One buffer of one voice at one strength.
    static func render(_ r: VoiceRecipe, strength s: Double, pitch: Double, levelJitter: [Double],
                       noiseSeed: UInt64) -> [Float] {
        let n = max(1, Int(r.seconds * sampleRate))
        var out = [Double](repeating: 0, count: n)
        // Strength relative to the hardest layer: the hardest layer plays every partial at its written level.
        let rel = s / (VoiceBook.strengths.last ?? 1)
        let tau = 2 * Double.pi

        for (k, p) in r.partials.enumerated() {
            let jitter = k < levelJitter.count ? levelJitter[k] : 1
            var amp = p.level * ((1 - p.bright) + p.bright * rel) * jitter
            guard amp > 0 else { continue }
            let first = Int(p.start * sampleRate)
            guard first < n else { continue }
            let decay = exp(-p.fade / sampleRate)
            let f0 = p.hz * pitch
            var phase = 0.0
            for i in first..<n {
                let t = Double(i - first) / sampleRate
                // Frequency now (a glide sags the pitch as it rings), never below the bottom of hearing.
                let f = max(20, f0 - p.glide * pitch * t)
                phase += tau * f / sampleRate
                out[i] += amp * sin(phase)
                amp *= decay
                // Stop once it is far below anything audible.
                if amp < 1e-5 { break }
            }
        }

        var rng = SoundRandom(seed: noiseSeed)
        for b in r.bursts {
            var amp = b.level * ((1 - b.bright) + b.bright * rel)
            guard amp > 0 else { continue }
            let first = Int(b.start * sampleRate)
            guard first < n else { continue }
            // Harder: shorter (fade up to 1.3 times faster) and brighter (the low-pass opens).
            let decay = exp(-b.fade * (0.7 + 0.6 * s) / sampleRate)
            let open = min(1, max(0.02, b.tone * (0.6 + 0.4 * rel)))
            var smooth = 0.0
            for i in first..<n {
                smooth += open * (rng.signed() - smooth)
                out[i] += amp * smooth
                amp *= decay
                if amp < 1e-5 { break }
            }
        }
        return normalised(out)
    }

    /// Scale so the loudest sample sits at `peak`, as Float samples.
    static func normalised(_ x: [Double]) -> [Float] {
        let top = x.reduce(1e-9) { max($0, abs($1)) }
        let gain = peak / top
        return x.map { Float($0 * gain) }
    }

    /// The rolling voices' base noise: a second and a half of lightly smoothed white noise, looped. The band-pass in
    /// each rolling voice gives it its colour; the loop is long enough that no repeat is heard in noise.
    static func rollingNoise() -> [Float] {
        var rng = SoundRandom(seed: VoiceBook.buildSeed ^ 0x524F_4C4C)   // "ROLL"
        let n = Int(1.5 * sampleRate)
        var y = 0.0
        var out = [Double](repeating: 0, count: n)
        for i in 0..<n {
            y += 0.5 * (rng.signed() - y)
            out[i] = y
        }
        return normalised(out)
    }

    /// The skid's crackle: sparse little ticks (about 440 a second, each dying in a few samples) over a faint hiss, the
    /// scratch of a ball sliding over the fibres instead of rolling across them. Looped like the rolling noise.
    static func gritNoise() -> [Float] {
        var rng = SoundRandom(seed: VoiceBook.buildSeed ^ 0x4752_4954)   // "GRIT"
        let n = Int(1.5 * sampleRate)
        var tick = 0.0
        var out = [Double](repeating: 0, count: n)
        for i in 0..<n {
            // One chance in a hundred per sample: about 441 ticks a second at 44.1 kHz.
            if rng.unit() < 0.01 { tick += (0.3 + 0.7 * rng.unit()) * (rng.unit() < 0.5 ? -1 : 1) }
            tick *= 0.85
            out[i] = tick + 0.1 * rng.signed()
        }
        return normalised(out)
    }
}
