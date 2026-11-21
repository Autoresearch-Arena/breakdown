// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The sound of balls rolling (sound plan package 3): up to three voices of filtered noise, one per moving
//          ball, given to the three fastest balls on the table at the playback clock. Each voice is two looping noise
//          players (a smooth hush and a skid's crackle, both from VoiceSynth) panned to the ball's place on the table
//          (SoundStage) and mixed into one band-pass filter. Every frame SoundBoard.follow hands over the recording,
//          the clock, the playback rate and the surface, and this sets each voice from the ball's recorded state:
//          louder with speed, brighter with speed (the band centre rises), lower in slow motion (the band centre is
//          scaled by the playback rate, as slowing a recording lowers every frequency), and with the crackle added
//          only while the ball is sliding, so the moment a ball stops skidding can be heard. A ball in the air,
//          spinning on the spot, stopped or gone makes no rolling sound. silence() stops everything; SoundBoard calls
//          it whenever the clock is not moving forward at playback pace (paused, scrubbing, rewinding, the menu).
//          All of it runs on the main actor with ordinary player, mixer and equaliser nodes; nothing runs on the audio
//          thread but Apple's own units.
// SRP/DRY check: Pass - rolling only. Impact sounds are SoundBoard's, the noise is VoiceSynth's, the surface colours
//          are SurfaceSound's, the pan is SoundStage's; the ball states come from Timeline.state, never re-simulated.
import AVFoundation
import BreakdownLensModel
import BreakdownTimeline

@MainActor
final class RollingVoices {
    /// How many balls can be heard rolling at once: the three fastest. More would only thicken the hush, and each
    /// voice costs two players and a filter.
    static let count = 3
    /// Below this speed (m/s) a ball is treated as stopped: about a millimetre per frame at sixty frames a second.
    static let minimumSpeed = 0.06
    /// Width of each voice's band of noise, octaves: wide enough to sound like a hush rather than a whistle.
    static let bandwidth: Float = 1.3

    private struct Lane {
        let smooth = AVAudioPlayerNode()
        let grit = AVAudioPlayerNode()
        let mix = AVAudioMixerNode()
        let filter = AVAudioUnitEQ(numberOfBands: 1)
        /// The ball this voice follows, nil when idle.
        var ball: Int?
    }

    private var voices: [Lane] = []
    private var smoothBuffer: AVAudioPCMBuffer?
    private var gritBuffer: AVAudioPCMBuffer?
    /// True once the looping buffers are on the players. An engine restart (an interruption, a route change) clears
    /// every scheduled buffer, so SoundBoard calls restarted() and they are put back on the next update.
    private var scheduled = false
    private var sounding = false

    /// Attach and wire the nodes: each voice's two players into its own mixer (where the pan is applied, since a
    /// player's pan works at the mixer it feeds), through its band-pass, into `output`.
    init(engine: AVAudioEngine, output: AVAudioMixerNode, mono: AVAudioFormat, stereo: AVAudioFormat) {
        for _ in 0..<Self.count {
            let v = Lane()
            let band = v.filter.bands[0]
            band.filterType = .bandPass
            band.bandwidth = Self.bandwidth
            band.frequency = 900
            band.bypass = false
            for node in [v.smooth, v.grit, v.mix, v.filter] as [AVAudioNode] { engine.attach(node) }
            engine.connect(v.smooth, to: v.mix, format: mono)
            engine.connect(v.grit, to: v.mix, format: mono)
            engine.connect(v.mix, to: v.filter, format: stereo)
            engine.connect(v.filter, to: output, format: stereo)
            v.smooth.volume = 0
            v.grit.volume = 0
            voices.append(v)
        }
    }

    /// Hand over the built noises (from the background build). Nothing sounds until the first update after this.
    func install(smooth: AVAudioPCMBuffer, grit: AVAudioPCMBuffer) {
        smoothBuffer = smooth
        gritBuffer = grit
        scheduled = false
    }

    /// The engine was restarted: every scheduled buffer is gone.
    func restarted() {
        scheduled = false
        sounding = false
    }

    /// Set every voice from the recording at `clock`. `rate` is the playback rate (1 real time, below 1 slow motion).
    func update(_ timeline: Timeline, clock: Double, rate: Double, surface: SurfaceSound) {
        guard let smoothBuffer, let gritBuffer else { return }
        if !scheduled {
            for v in voices {
                v.smooth.stop(); v.grit.stop()
                v.smooth.scheduleBuffer(smoothBuffer, at: nil, options: .loops, completionHandler: nil)
                v.grit.scheduleBuffer(gritBuffer, at: nil, options: .loops, completionHandler: nil)
            }
            scheduled = true
            sounding = false
        }

        // Every ball that is rolling or sliding on the cloth now, fastest first, the top three.
        var moving: [(ball: Int, speed: Double, state: BallState)] = []
        for b in 0..<timeline.ballCount {
            let s = timeline.state(ball: b, at: clock)
            guard !s.pocketed, s.height <= 0, s.phase == .rolling || s.phase == .sliding else { continue }
            let speed = s.velocity.length
            if speed >= Self.minimumSpeed { moving.append((b, speed, s)) }
        }
        moving.sort { $0.speed > $1.speed }
        let heard = Array(moving.prefix(Self.count))
        let heardBalls = Set(heard.map { $0.ball })

        // Keep a voice on the ball it already follows when that ball is still among the fastest, so a voice does not
        // jump across the table (its pan would leap) just because two balls swapped places in the ranking.
        for i in voices.indices where voices[i].ball.map({ !heardBalls.contains($0) }) ?? false { voices[i].ball = nil }
        for h in heard where !voices.contains(where: { $0.ball == h.ball }) {
            if let free = voices.firstIndex(where: { $0.ball == nil }) { voices[free].ball = h.ball }
        }

        // Slow motion lowers the band, as playing a recording slowly lowers every pitch in it; held between a quarter
        // and twice real time so it never sinks into a rumble or squeaks.
        let pace = min(2, max(0.25, rate))
        var any = false
        for v in voices {
            guard let ball = v.ball, let h = heard.first(where: { $0.ball == ball }) else {
                v.smooth.volume = 0; v.grit.volume = 0
                continue
            }
            any = true
            // Loudness in proportion to speed (the cloth fibres a ball crosses per second, and so the force ripple
            // that makes the hush, grow with speed), full at the same 2 m/s full scale the hits use.
            let level = surface.rollLevel * FeelMapping.strength(speed: h.speed)
            // The band centre slides from about half the surface's colour for a slow ball up to all of it at speed.
            let centre = surface.rollCutoff * (0.45 + 0.55 * FeelMapping.strength(speed: h.speed)) * pace
            v.filter.bands[0].frequency = Float(min(8_000, max(60, centre)))
            v.smooth.volume = Float(level)
            // The crackle only while the ball skids; thinned in slow motion (fewer fibres scraped per real second).
            v.grit.volume = h.state.phase == .sliding ? Float(level * surface.slideGrit * pace.squareRoot()) : 0
            let pan = SoundStage.pan(h.state.position)
            v.smooth.pan = pan
            v.grit.pan = pan
        }
        if any && !sounding {
            for v in voices { v.smooth.play(); v.grit.play() }
            sounding = true
        } else if !any && sounding {
            pause()
        }
    }

    /// Stop every rolling voice at once (paused, scrubbing, rewinding, the menu, Sound off).
    func silence() {
        for i in voices.indices {
            voices[i].ball = nil
            voices[i].smooth.volume = 0
            voices[i].grit.volume = 0
        }
        if sounding { pause() }
    }

    /// Pause the players (keeping their looping buffers), so an idle table costs nothing.
    private func pause() {
        for v in voices { v.smooth.pause(); v.grit.pause() }
        sounding = false
    }
}
