// Author: Claude Sonnet 5.5 Medium
// Date: 11-November-2026
// PURPOSE: Minimal generated audio for milestone 1a: ball click, rail thud and pocket drop, all synthesised in
//          code (no sample files) and scaled by the impact's recorded impulse so one number drives sight and sound.
//          Launching with the argument -muteSound keeps the engine off so testing on a shared machine is silent.
// SRP/DRY check: Pass - sound output only; playback decides when to call it.
import AVFoundation
import BreakdownLensModel
import Foundation

@MainActor
final class SoundBoard {
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var next = 0
    private let click: AVAudioPCMBuffer
    private let thud: AVAudioPCMBuffer
    private let drop: AVAudioPCMBuffer
    private var running = false

    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        func synth(_ seconds: Double, _ gen: (Double) -> Double) -> AVAudioPCMBuffer {
            let n = AVAudioFrameCount(seconds * format.sampleRate)
            let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: n)!
            buf.frameLength = n
            let p = buf.floatChannelData![0]
            for i in 0..<Int(n) { p[i] = Float(gen(Double(i) / format.sampleRate)) }
            return buf
        }
        var seed: UInt64 = 0x1234_5678_9ABC_DEF1
        func noise() -> Double {
            seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17
            return Double(seed % 20_000) / 10_000 - 1
        }
        click = synth(0.09) { t in
            let env = exp(-t * 90)
            return env * (0.55 * sin(2 * .pi * 2_900 * t) + 0.3 * sin(2 * .pi * 5_200 * t) + 0.25 * noise())
        }
        thud = synth(0.16) { t in exp(-t * 38) * (0.8 * sin(2 * .pi * 130 * t) + 0.2 * noise()) }
        drop = synth(0.3) { t in exp(-t * 14) * sin(2 * .pi * (420 - 520 * t) * t) * 0.8 }
        for _ in 0..<10 {
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

    /// Play the sound for an event; louder for bigger impulses.
    func play(_ e: LensEvent) {
        guard running else { return }
        let strength = min(1.0, e.normalImpulse / 0.9)
        let buffer: AVAudioPCMBuffer
        switch e.kind {
        case .ballBall: buffer = click
        case .cushion: buffer = thud
        case .pocket: buffer = drop
        case .cueStrike: buffer = click
        case .phaseTransition: return
        }
        guard strength > 0.02 || e.kind == .pocket else { return }
        let player = players[next]
        next = (next + 1) % players.count
        player.stop()
        player.volume = Float(0.15 + 0.85 * strength)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }
}
