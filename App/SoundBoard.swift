// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (honours the Sound option).
// Edited: Claude Opus 5.5 High, 21-November-2026 (sound plan packages 1 to 4. Voices are now recipes of ringing
//          partials and contact bursts (VoiceBook, at the top of this file), built at four strengths with seeded
//          variants on a background task (VoiceSynth); new voices for pins, posts, jump landings, a ball off the table,
//          rim skips, miscues, balls settling in contact, pocket settling knocks and the match moments; every table
//          hit is panned from where it happened (SoundStage) through a light shared room reverb and a peak limiter;
//          balls rolling are heard (RollingVoices) through follow(), called every frame; the rail and landing voices
//          follow the surface (SurfaceSound); the title music fades out at the first table sound and dips under the
//          match moments; one shared board, so match screens can call SoundBoard.play(.foul) and the like.)
// PURPOSE: All generated table audio, synthesised in code with Apple's audio framework (no sample files). Plays the
//          feel cues chosen by FeelMapping (the break crack, ball clicks, the cue tock, rail thuds, pocket drops and
//          their settling knocks, and the newer voices above) and the rolling hush of moving balls. One number drives
//          sight, sound and touch: each cue's recorded strength picks the voice's strength layer (harder is brighter)
//          and sets its volume, and Haptics plays the same cue at the same strength.
//          The audio session (iPhone and iPad) is the polite "ambient" category, so the silent switch is obeyed and
//          the player's own music keeps playing underneath; the Mac has no session.
//          Signal path: a pool of mono players and the rolling voices feed one mixer, then a light room reverb, then
//          a peak limiter (so a break never clips), then the output.
//          Hooks for the rest of the app: SoundBoard.shared.play(cues, at:) for the frame's cues (ShowpieceModel),
//          SoundBoard.shared.follow(...) once every frame for the rolling voices (ShowpieceModel.advance), and
//          SoundBoard.play(.foul / .turnChange / .win) for match screens (sound and haptic together).
//          Launching with -muteSound keeps the engine off and skips building the voices, so testing on a shared
//          machine is silent; launching with -logFeel prints every cue as it fires.
// SRP/DRY check: Pass - sound output only; FeelMapping decides what to play, the playback loop decides when,
//          VoiceSynth does the maths of each voice, RollingVoices the rolling, SoundStage the pan and pace.
import AVFoundation
import BreakdownPhysics
import BreakdownTimeline
import Foundation

// MARK: - The voice book: every recipe and level, to tune without touching the code below

/// The recipes. Each voice is a short table of partials (pitch in hertz, level, fade per second, how much it brightens
/// with strength, an optional downward glide and start time) and noise bursts (the contact itself). Pitches are chosen
/// for what is being struck: a phenolic ball rings at a few high, closely spaced pitches that die in hundredths of a
/// second; a rail is a low, dull, quickly damped thud; the bed under a jump is a hard knock with a low body. These are
/// starting points tuned by ear, to be adjusted when the Boss listens; none is a measurement.
enum VoiceBook {
    /// The four strength layers each voice is built at: the middles of four equal bands of the 0 to 1 strength, so a
    /// cue plays the layer whose band its strength falls in.
    static let strengths: [Double] = [0.125, 0.375, 0.625, 0.875]
    /// Seeds for building the variants and for the per-play choices. Any fixed numbers: they only have to be the same
    /// every launch so the sound is the same every launch.
    static let buildSeed: UInt64 = 0x5EED_B0A2_D0F0_0001
    static let playSeed: UInt64 = 0x5EED_B0A2_D0F0_0002
    /// Players in the pool: a busy frame (a pocket drop with five knocks, two clicks, two rails) needs about ten at
    /// once, and a delayed knock must not be cut off by the next frame's sounds, so twice that.
    static let playerCount = 24
    /// Per-play level change, plus or minus this share, so a run of equal hits never sounds like one sample.
    static let levelJitter = 0.08
    /// The shared room: a medium room preset mixed in at this percentage. Low on purpose: hits should sound like a
    /// room, not a hall.
    static let roomMix: Float = 10
    /// How fast the title music gets out of the way of the first table sound, seconds: shorter than the gap between
    /// a cue tock and the first ball click on a typical shot, so the two never overlap.
    static let musicOutFade = 0.15

    /// How loud each kind plays at full strength, as a player volume. The break is the loudest thing in the game (1);
    /// nothing else reaches it, and a soft touch (strength near 0.1) plays at under a quarter of its kind's level.
    static func level(_ kind: FeelKind) -> Double {
        switch kind {
        case .crack: return 1.0
        case .click: return 0.75
        case .tock: return 0.5
        case .cushion: return 0.7
        case .pocket: return 0.75
        case .knock: return 0.45
        case .pin: return 0.6
        case .post: return 0.65
        case .landing: return 0.7
        case .offTable: return 0.55     // the floor is further from the listener than the table
        case .rimSkip: return 0.55
        case .miscue: return 0.6
        case .settle: return 0.3        // balls easing into each other: barely there
        case .foul: return 0.5
        case .turnChange: return 0.35
        case .win: return 0.6
        }
    }

    /// Variants per strength layer: three for the sounds that come in quick runs (clicks, rails, knocks, the tock,
    /// landings), two for the rest, which keeps the bank small.
    static func variants(_ v: Voice) -> Int {
        switch v {
        case .click, .rail, .knock, .tock, .landing: return 3
        default: return 2
        }
    }

    static func recipe(_ v: Voice) -> VoiceRecipe {
        switch v {
        case .crack:
            // The break: an almost instant snap of noise, bright rings, and a low body under it that sags as it rings.
            return VoiceRecipe(seconds: 0.45, partials: [
                Partial(3_100, 0.5, fade: 55, bright: 0.4),
                Partial(4_100, 0.35, fade: 60, bright: 0.6),
                Partial(5_400, 0.3, fade: 70, bright: 0.8),
                Partial(170, 0.7, fade: 20, glide: 120),
            ], bursts: [
                Burst(0.9, fade: 420, tone: 1.0, bright: 0.3),
                Burst(0.35, fade: 300, tone: 0.8, at: 0.012),    // the second row of the rack giving way
            ], pitchSpread: 0.02)
        case .click:
            // Ball on ball: a few high, close partials; the upper ones only come through on a hard hit.
            return VoiceRecipe(seconds: 0.09, partials: [
                Partial(2_900, 1.0, fade: 110, bright: 0.3),
                Partial(3_350, 0.6, fade: 140, bright: 0.6),
                Partial(5_200, 0.35, fade: 220, bright: 1.0),
                Partial(1_800, 0.4, fade: 90),
            ], bursts: [Burst(0.5, fade: 600, tone: 0.9)], pitchSpread: 0.03)
        case .tock:
            // Leather tip on the cue ball: a short wooden tock.
            return VoiceRecipe(seconds: 0.08, partials: [
                Partial(950, 0.7, fade: 110, bright: 0.2),
                Partial(1_900, 0.25, fade: 150, bright: 0.8),
                Partial(480, 0.2, fade: 80),
            ], bursts: [Burst(0.35, fade: 500, tone: 0.6)])
        case .rail(let tone):
            return rail(tone)
        case .pocketDrop:
            // The ball dropping over the edge: a dull drop that sags in pitch. The knocks that follow are their own
            // voice, timed from the entry speed (FeelMapping.pocketKnocks).
            return VoiceRecipe(seconds: 0.35, partials: [
                Partial(150, 0.9, fade: 18, glide: 220),
                Partial(310, 0.3, fade: 30, bright: 0.5),
            ], bursts: [Burst(0.3, fade: 60, tone: 0.2)])
        case .knock:
            // The ball knocking the pocket's back or bottom: small and woody.
            return VoiceRecipe(seconds: 0.06, partials: [
                Partial(1_300, 0.6, fade: 130, bright: 0.4),
                Partial(700, 0.5, fade: 90),
            ], bursts: [Burst(0.3, fade: 300, tone: 0.5)])
        case .pin:
            // A wooden pin: the clack of the hit, then the pin landing on the bed. A pin a few centimetres tall takes
            // about a tenth of a second to topple (of the order of sqrt(height / g), times a little for the rotation).
            return VoiceRecipe(seconds: 0.3, partials: [
                Partial(620, 0.7, fade: 45, bright: 0.2),
                Partial(1_480, 0.4, fade: 70, bright: 0.6),
                Partial(2_350, 0.25, fade: 110, bright: 0.9),
                Partial(380, 0.5, fade: 40, at: 0.11),
                Partial(900, 0.25, fade: 60, bright: 0.5, at: 0.11),
            ], bursts: [Burst(0.3, fade: 350, tone: 0.6), Burst(0.2, fade: 250, tone: 0.4, at: 0.11)])
        case .post:
            // A fixed round post: a rubber-ringed body over wood, duller than a rail, with a woody ring on top.
            return VoiceRecipe(seconds: 0.22, partials: [
                Partial(180, 0.7, fade: 35),
                Partial(420, 0.4, fade: 50, bright: 0.5),
                Partial(900, 0.15, fade: 80, bright: 0.9),
            ], bursts: [Burst(0.2, fade: 150, tone: 0.4)])
        case .landing(let tone):
            return landing(tone)
        case .offTable:
            return offTable()
        case .rimSkip:
            // A ball clipping the near and then the far edge of a hole as it rattles across: two clatters a few
            // hundredths of a second apart (a hole about 0.12 m across crossed at about 3 m/s).
            return VoiceRecipe(seconds: 0.12, partials: [
                Partial(1_100, 0.6, fade: 120, bright: 0.3),
                Partial(2_300, 0.4, fade: 160, bright: 0.8),
                Partial(1_150, 0.42, fade: 120, bright: 0.3, at: 0.035),
                Partial(2_250, 0.28, fade: 160, bright: 0.8, at: 0.035),
            ], bursts: [Burst(0.35, fade: 400, tone: 0.6), Burst(0.25, fade: 400, tone: 0.6, at: 0.035)])
        case .miscue:
            // The tip skidding off the ball: a scratchy smear of noise over a thin, weak click.
            return VoiceRecipe(seconds: 0.15, partials: [
                Partial(2_400, 0.4, fade: 150, bright: 0.6),
                Partial(950, 0.3, fade: 140),
            ], bursts: [Burst(0.6, fade: 45, tone: 0.9, bright: 0.3)])
        case .settle:
            // Wedged balls brought to rest touching: a soft, muffled clack.
            return VoiceRecipe(seconds: 0.1, partials: [
                Partial(1_600, 0.4, fade: 160, bright: 0.3),
                Partial(800, 0.4, fade: 120),
            ], bursts: [Burst(0.15, fade: 400, tone: 0.3)])
        case .foul:
            // Two soft falling notes a minor third apart (G then E flat): the usual musical "that went wrong", kept
            // gentle. Tiny pitch spread so the two notes stay in tune with each other.
            return VoiceRecipe(seconds: 0.7, partials: [
                Partial(392.0, 0.6, fade: 6),
                Partial(784.0, 0.18, fade: 9, bright: 0.5),
                Partial(311.1, 0.6, fade: 6, at: 0.18),
                Partial(622.3, 0.18, fade: 9, bright: 0.5, at: 0.18),
            ], bursts: [Burst(0.05, fade: 200, tone: 0.3), Burst(0.05, fade: 200, tone: 0.3, at: 0.18)],
            pitchSpread: 0.005)
        case .turnChange:
            // Two soft wooden ticks, the second a little lower: a counter slid along a wire, "your turn".
            return VoiceRecipe(seconds: 0.25, partials: [
                Partial(1_250, 0.5, fade: 60),
                Partial(2_600, 0.2, fade: 90, bright: 0.7),
                Partial(1_050, 0.45, fade: 60, at: 0.09),
                Partial(2_200, 0.18, fade: 90, bright: 0.7, at: 0.09),
            ], bursts: [Burst(0.15, fade: 500, tone: 0.5), Burst(0.12, fade: 500, tone: 0.5, at: 0.09)],
            pitchSpread: 0.01)
        case .win:
            // A rising major arpeggio (C, E, G, C), each note a struck bell with one off-key overtone at 2.76 times its
            // pitch, the first overtone of a ringing ball, so the win sounds like the table it was played on.
            let notes: [Double] = [523.25, 659.25, 783.99, 1_046.5]
            var partials: [Partial] = []
            for (i, f) in notes.enumerated() {
                let at = 0.1 * Double(i)
                partials.append(Partial(f, 0.55, fade: 4, at: at))
                partials.append(Partial(f * 2.76, 0.2, fade: 8, bright: 0.6, at: at))
            }
            return VoiceRecipe(seconds: 1.1, partials: partials, bursts: [], pitchSpread: 0.004)
        }
    }

    /// The rail thud for each tone: a low knock with a sagging body. A bright rail (lively rubber, a hard bed) adds
    /// a high edge and rings a little longer; a dull one (dead rubber, a soft bed) loses its top and dies faster.
    static func rail(_ tone: BedTone) -> VoiceRecipe {
        let damp: Double
        switch tone {
        case .bright: damp = 0.8
        case .standard: damp = 1.0
        case .dull: damp = 1.6
        }
        var partials = [
            Partial(118, 0.8, fade: 38 * damp),
            Partial(255, 0.28, fade: 45 * damp, bright: 0.5),
            Partial(85, 0.5, fade: 22 * damp, bright: 0.7, glide: 40),
        ]
        if tone != .dull { partials.append(Partial(760, 0.1, fade: 120, bright: 0.8)) }
        if tone == .bright { partials.append(Partial(1_450, 0.18, fade: 95, bright: 0.9)) }
        let burstTone: Double = tone == .bright ? 0.45 : (tone == .dull ? 0.12 : 0.3)
        return VoiceRecipe(seconds: 0.32, partials: partials, bursts: [Burst(0.15, fade: 120, tone: burstTone)])
    }

    /// A jump landing on the bed: a hard knock with a low body. A hard bed (glass, ice) rings brighter and longer; a
    /// soft one (sand, cork, carpet, rubber) is a thud with no ring.
    static func landing(_ tone: BedTone) -> VoiceRecipe {
        let damp: Double
        switch tone {
        case .bright: damp = 0.8
        case .standard: damp = 1.0
        case .dull: damp = 1.6
        }
        var partials = [
            Partial(95, 0.8, fade: 30 * damp),
            Partial(240, 0.4, fade: 40 * damp, bright: 0.3),
        ]
        if tone != .dull { partials.append(Partial(2_200, 0.3, fade: 120 * damp, bright: 0.9)) }
        if tone == .bright { partials.append(Partial(3_400, 0.3, fade: 90, bright: 0.9)) }
        let burstTone: Double = tone == .bright ? 0.9 : (tone == .dull ? 0.2 : 0.7)
        return VoiceRecipe(seconds: 0.25, partials: partials, bursts: [Burst(0.5, fade: 500, tone: burstTone)])
    }

    /// A ball hitting the floor after flying off the table, then bouncing. The floor thud itself is delayed by the
    /// fall (FeelMapping.offTableThud); inside the voice, each bounce comes after its flight 2 e v / g and is e times
    /// as strong, with v the landing speed sqrt(2 g h) from the bed height and e the floor bounce, the same numbers
    /// FeelMapping uses.
    static func offTable() -> VoiceRecipe {
        let g = PoolParameters().gravity
        let e = FeelMapping.floorBounce
        var v = (2 * g * FeelMapping.bedHeight).squareRoot()
        var at = 0.0
        var level = 1.0
        var partials: [Partial] = []
        var bursts: [Burst] = []
        // The landing and two bounces; a third would be under a tenth of the first, lost under anything else playing.
        for _ in 0..<3 {
            partials.append(Partial(110, 0.9 * level, fade: 22, at: at))
            partials.append(Partial(260, 0.4 * level, fade: 35, bright: 0.4, at: at))
            bursts.append(Burst(0.5 * level, fade: 250, tone: 0.5, at: at))
            v *= e
            at += 2 * v / g
            level *= e
        }
        return VoiceRecipe(seconds: at + 0.2, partials: partials, bursts: bursts)
    }

    /// The peak limiter at the end of the chain (Apple's own effect unit). Its standard settings (a few milliseconds
    /// to catch a peak, a few dozen to let go) are right for short percussive hits, so none is changed.
    static var limiterDescription: AudioComponentDescription {
        AudioComponentDescription(componentType: kAudioUnitType_Effect, componentSubType: kAudioUnitSubType_PeakLimiter,
                                  componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0,
                                  componentFlagsMask: 0)
    }
}

// MARK: - The board

@MainActor
final class SoundBoard {
    /// The one board: one engine, one limiter, one room, whoever plays through it (the shot playback and the match
    /// screens alike).
    static let shared = SoundBoard()

    /// Match screens: play a moment (foul, turn change, win), its sound and its haptic together, at the moment's own
    /// strength. Centred, not placed on the table.
    static func play(_ moment: GameMoment) {
        let cue = FeelCue(kind: moment.kind, strength: moment.strength, delay: 0)
        shared.play([cue], at: 0)
        Haptics.shared.play([cue])
    }

    /// Silent testing switch: never build the voices or start the engine when asked not to.
    private static let muted = ProcessInfo.processInfo.arguments.contains("-muteSound")

    private let engine: AVAudioEngine
    private let mono: AVAudioFormat
    private let players: [AVAudioPlayerNode]
    private let rolling: RollingVoices
    private var nextPlayer = 0
    /// False when muted; the engine is (re)started on demand while this is true.
    private var enabled = false
    private let logging = ProcessInfo.processInfo.arguments.contains("-logFeel")

    /// The built voices, per voice, per strength layer, per variant. Empty until the background build finishes; a
    /// cue that arrives before then is skipped (the first sound of the opening comes over a second after launch).
    private var voices: [Voice: [[AVAudioPCMBuffer]]] = [:]
    private var random = SoundRandom(seed: VoiceBook.playSeed)
    /// The variant each voice played last, so the next play of it picks another.
    private var lastVariant: [Voice: Int] = [:]
    /// The surface of the shot on screen (from follow), for the rail and landing tones.
    private var surface: PlaySurface?
    private var surfaceSound = SurfaceSound(.cloth)
    /// The clock at the last follow, to tell forward playback from a pause, a scrub or a jump.
    private var lastClock: Double?

    private init() {
        let engine = AVAudioEngine()
        let mono = AVAudioFormat(standardFormatWithSampleRate: VoiceSynth.sampleRate, channels: 1)!
        let stereo = AVAudioFormat(standardFormatWithSampleRate: VoiceSynth.sampleRate, channels: 2)!
        // The shared chain: everything into one mixer, then the room, then the limiter, then the output.
        let dry = AVAudioMixerNode()
        let room = AVAudioUnitReverb()
        let limiter = AVAudioUnitEffect(audioComponentDescription: VoiceBook.limiterDescription)
        engine.attach(dry)
        engine.attach(room)
        engine.attach(limiter)
        engine.connect(dry, to: room, format: stereo)
        engine.connect(room, to: limiter, format: stereo)
        engine.connect(limiter, to: engine.mainMixerNode, format: stereo)
        room.loadFactoryPreset(.mediumRoom)
        room.wetDryMix = VoiceBook.roomMix
        // Mono players straight into the mixer, so each one's pan places it left to right.
        var pool: [AVAudioPlayerNode] = []
        for _ in 0..<VoiceBook.playerCount {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: dry, format: mono)
            pool.append(player)
        }
        self.engine = engine
        self.mono = mono
        self.players = pool
        self.rolling = RollingVoices(engine: engine, output: dry, mono: mono, stereo: stereo)

        #if os(iOS)
        // Ambient: obeys the silent switch and mixes with the player's own music instead of stopping it.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        if Self.muted { return }
        enabled = true
        _ = ensureRunning()
        // Build the voices off the main thread (a few hundred thousand samples of sines; slow in a debug build), then
        // wrap them into buffers here. Launch does not wait for it.
        Task { [weak self] in
            let bank = await Task.detached(priority: .userInitiated) { VoiceSynth.buildBank() }.value
            self?.install(bank)
        }
    }

    private func install(_ bank: VoiceBank) {
        voices = bank.voices.mapValues { layers in layers.map { variants in variants.compactMap { buffer($0) } } }
        if let smooth = buffer(bank.rollSmooth), let grit = buffer(bank.rollGrit) {
            rolling.install(smooth: smooth, grit: grit)
        }
    }

    private func buffer(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard !samples.isEmpty,
              let b = AVAudioPCMBuffer(pcmFormat: mono, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = b.floatChannelData?[0] else { return nil }
        b.frameLength = AVAudioFrameCount(samples.count)
        for i in 0..<samples.count { channel[i] = samples[i] }
        return b
    }

    /// Start the engine if it is not running (first use, or after the system stopped it for an interruption or a
    /// route change). A restart drops every scheduled buffer, so the rolling voices are told to reschedule.
    private func ensureRunning() -> Bool {
        guard enabled else { return false }
        if engine.isRunning { return true }
        do {
            try engine.start()
            rolling.restarted()
            return true
        } catch {
            // No output device or a refused start: stay quiet and try again at the next sound.
            return false
        }
    }

    /// Play a frame's cues. The first cue sounds now; later ones follow by their small delays, stretched in slow
    /// motion (SoundStage.stretch) and scheduled on the audio clock so a rattle keeps its rhythm.
    func play(_ cues: [FeelCue], at time: Double = 0) {
        if logging {
            for c in cues {
                let pan = c.point.map { SoundStage.pan($0) } ?? 0
                print(String(format: "FEEL t=%.3f %@ strength=%.2f delay=%.3f pan=%.2f", time, c.kind.rawValue,
                             c.strength, c.delay, pan))
            }
        }
        // The Sound option is read at play time, so switching it in Options takes effect at once.
        guard GameSettings.soundOn, ensureRunning() else { return }
        for cue in cues { fire(cue) }
    }

    /// Every frame, from the playback loop: keep the rolling voices on the recording. `playing` is false while paused
    /// or behind the menu. The rolling sound only runs while the clock moves forward at playback pace; a pause, a
    /// scrub, the cold open's rewind, a hold on a guided beat or a jump to another moment silences it at once
    /// (silence is acceptable there; a wrong sound is not).
    func follow(_ timeline: Timeline, clock: Double, rate: Double, playing: Bool, surface s: PlaySurface) {
        if s != surface {
            surface = s
            surfaceSound = SurfaceSound(s)
        }
        SoundStage.rate = rate
        let step = lastClock.map { clock - $0 } ?? 0
        lastClock = clock
        // The playback loop never advances more than a twentieth of a second of real time per frame, so a forward
        // step larger than that (times the rate, with half again for a rate that changed within the frame) is a jump.
        let forward = playing && step > 0 && step <= max(0, rate) * (1.0 / 20.0) * 1.5 + 1e-4
        guard forward, GameSettings.soundOn, ensureRunning() else {
            rolling.silence()
            return
        }
        rolling.update(timeline, clock: clock, rate: rate, surface: surfaceSound)
    }

    private func voice(for kind: FeelKind) -> Voice {
        switch kind {
        case .crack: return .crack
        case .click: return .click
        case .tock: return .tock
        case .cushion: return .rail(surfaceSound.rail)
        case .pocket: return .pocketDrop
        case .knock: return .knock
        case .pin: return .pin
        case .post: return .post
        case .landing: return .landing(surfaceSound.bed)
        case .offTable: return .offTable
        case .rimSkip: return .rimSkip
        case .miscue: return .miscue
        case .settle: return .settle
        case .foul: return .foul
        case .turnChange: return .turnChange
        case .win: return .win
        }
    }

    private func fire(_ cue: FeelCue) {
        let chosen = voice(for: cue.kind)
        guard let layers = voices[chosen], !layers.isEmpty else { return }
        // The title music never plays over the table: the first table sound sends it out fast. A match moment only
        // dips it, in case a moment ever sounds while the menu's music is still up.
        if cue.kind.isTableSound {
            TitleMusic.shared.stop(fadeSeconds: VoiceBook.musicOutFade)
        } else {
            TitleMusic.shared.duck()
        }
        let s = min(1, max(0, cue.strength))
        let layer = layers[min(layers.count - 1, Int(s * Double(layers.count)))]
        guard !layer.isEmpty else { return }
        // A seeded pick among the variants, never the one this voice played last.
        var pick = Int(random.next() % UInt64(layer.count))
        if layer.count > 1, pick == lastVariant[chosen] { pick = (pick + 1) % layer.count }
        lastVariant[chosen] = pick

        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.stop()
        // Loudness: the kind's level, scaled from a soft floor (0.15) up by strength, with a little seeded jitter.
        let jitter = 1 + VoiceBook.levelJitter * random.signed()
        player.volume = Float(VoiceBook.level(cue.kind) * (0.15 + 0.85 * s) * jitter)
        player.pan = cue.point.map { SoundStage.pan($0) } ?? 0
        let delay = SoundStage.stretch(cue.delay)
        // A later cue is scheduled on the audio clock (host time), not with a timer, so its timing is exact.
        let when: AVAudioTime? = delay > 0
            ? AVAudioTime(hostTime: mach_absolute_time() + AVAudioTime.hostTime(forSeconds: delay))
            : nil
        player.scheduleBuffer(layer[pick], at: when, options: [], completionHandler: nil)
        player.play()
    }
}
