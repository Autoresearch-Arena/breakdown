// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// PURPOSE: Generated audio for the break, all synthesised in code with AVFoundation (no sample files). It plays
//          the feel cues chosen by FeelMapping: a sharp crack for the break itself, soft or bright clicks for
//          ball contacts depending on how hard they were, a low weighted thump for the rail (heavier for harder
//          hits), a short tock for the cue tip, and a thud followed by a rattle for a pocket. Volume and which
//          sound variant is used both follow each impact's recorded strength, so one number drives sight, sound
//          and touch. Launching with the argument -muteSound keeps the engine off so testing on a shared
//          machine is silent; launching with -logFeel prints every cue as it fires.
// SRP/DRY check: Pass - sound output only; FeelMapping decides what to play, the playback loop decides when.
import AVFoundation
import Foundation

@MainActor
final class SoundBoard {
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var next = 0
    private var running = false
    private let logging = ProcessInfo.processInfo.arguments.contains("-logFeel")

    // Pre-built sounds. Several variants of the click so a run of contacts does not sound like one sample
    // repeated; soft ones are used for light touches and bright ones for hard contacts.
    private let crack: AVAudioPCMBuffer
    private let softClicks: [AVAudioPCMBuffer]
    private let hardClicks: [AVAudioPCMBuffer]
    private let tock: AVAudioPCMBuffer
    private let lightThump: AVAudioPCMBuffer
    private let heavyThump: AVAudioPCMBuffer
    private let pocket: AVAudioPCMBuffer
    private var variant = 0

    init() {
        let rate = 44_100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1)!
        // Fill a buffer from a function of time, then scale so the loudest sample sits at `peak` (keeps every
        // sound at a known level so several playing at once do not clip).
        func synth(_ seconds: Double, peak: Double = 0.9, _ gen: (Double) -> Double) -> AVAudioPCMBuffer {
            let n = AVAudioFrameCount(seconds * rate)
            let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: n)!
            buf.frameLength = n
            let p = buf.floatChannelData![0]
            var top = 1e-9
            for i in 0..<Int(n) {
                let v = gen(Double(i) / rate)
                p[i] = Float(v)
                top = max(top, abs(v))
            }
            let gain = Float(peak / top)
            for i in 0..<Int(n) { p[i] *= gain }
            return buf
        }
        // Small deterministic noise source so the sounds are identical on every launch.
        var seed: UInt64 = 0x1234_5678_9ABC_DEF1
        func noise() -> Double {
            seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17
            return Double(seed % 20_000) / 10_000 - 1
        }
        let tau = 2 * Double.pi

        // The break: an almost instant burst of noise (the snap), a bright ring, and a low body under it.
        crack = synth(0.45) { t in
            0.9 * exp(-t * 420) * noise()
                + 0.5 * exp(-t * 55) * (sin(tau * 3_100 * t) + 0.6 * sin(tau * 5_400 * t))
                + 0.7 * exp(-t * 20) * sin(tau * (170 - 60 * t) * t)
        }
        softClicks = [1_700.0, 2_000, 2_300].map { f in
            synth(0.07) { t in exp(-t * 140) * (0.7 * sin(tau * f * t) + 0.15 * noise()) }
        }
        hardClicks = [2_700.0, 3_000, 3_350].map { f in
            synth(0.09) { t in exp(-t * 95) * (0.55 * sin(tau * f * t) + 0.3 * sin(tau * f * 1.8 * t) + 0.3 * noise()) }
        }
        tock = synth(0.08) { t in exp(-t * 110) * (0.7 * sin(tau * 950 * t) + 0.35 * noise()) }
        // Rail: a rubbery low knock. The heavy one is lower and rings longer so a hard hit has weight.
        lightThump = synth(0.16) { t in exp(-t * 40) * (0.8 * sin(tau * 120 * t) + 0.2 * sin(tau * 260 * t)) + 0.1 * exp(-t * 120) * noise() }
        heavyThump = synth(0.3) { t in exp(-t * 20) * (0.9 * sin(tau * (85 - 20 * t) * t) + 0.3 * sin(tau * 190 * t)) + 0.2 * exp(-t * 90) * noise() }
        // Pocket: a dull drop, then the ball rattling in the pocket, each tick quieter and sooner than the last.
        let ticks: [(at: Double, amp: Double)] = [(0.09, 0.55), (0.18, 0.45), (0.26, 0.34), (0.32, 0.25), (0.37, 0.18), (0.41, 0.12)]
        pocket = synth(0.7) { t in
            var v = 0.9 * exp(-t * 18) * sin(tau * (150 - 110 * t) * t)
            for tick in ticks where t >= tick.at {
                let u = t - tick.at
                v += tick.amp * exp(-u * 130) * (sin(tau * 1_300 * u) + 0.2 * noise())
            }
            return v
        }

        for _ in 0..<12 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        // Silent testing switch: never start the audio engine when asked not to.
        if ProcessInfo.processInfo.arguments.contains("-muteSound") { running = false; return }
        do { try engine.start(); running = true } catch { running = false }
    }

    /// Play a frame's cues. The first cue sounds now; later ones follow by their small delays.
    func play(_ cues: [FeelCue], at time: Double = 0) {
        if logging {
            for c in cues {
                print(String(format: "FEEL t=%.3f %@ strength=%.2f delay=%.3f", time, c.kind.rawValue, c.strength, c.delay))
            }
        }
        guard running else { return }
        for cue in cues {
            if cue.delay <= 0 {
                fire(cue)
            } else {
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(cue.delay))
                    self?.fire(cue)
                }
            }
        }
    }

    private func fire(_ cue: FeelCue) {
        let s = cue.strength
        variant = (variant + 1) % 3
        let buffer: AVAudioPCMBuffer
        var level = 0.12 + 0.88 * s
        switch cue.kind {
        case .crack: buffer = crack; level = 1.0
        case .click: buffer = s >= 0.5 ? hardClicks[variant] : softClicks[variant]
        case .tock: buffer = tock; level = 0.3 + 0.5 * s
        case .cushion: buffer = s >= 0.6 ? heavyThump : lightThump
        case .pocket: buffer = pocket
        }
        let player = players[next]
        next = (next + 1) % players.count
        player.stop()
        player.volume = Float(level)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }
}
