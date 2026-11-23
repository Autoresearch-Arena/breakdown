// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 bullet time, plans/23-Nov-2026-bullet-time-plan.md: freeze,
//          the buzz as the clock stops on a hit, a firm tap and a short low hum; outside the feel-cue list.)
// Edited: Claude Opus 5.5 High, 20-November-2026 (honours the Vibration option).
// Edited: Claude Opus 5.5 High, 21-November-2026 (sound plan package 4: one shared engine (Haptics.shared), so a match
//          moment played through SoundBoard.play(_:) is felt too; a pattern for every new feel cue (pin, post, jump
//          landing, ball off the table, rim skip, miscue, balls settling, pocket knocks, foul, turn change, win); the
//          pocket's settling taps are now the separate knock cues timed from the entry speed, exactly as heard; cue
//          delays stretch in slow motion as the sound's do (SoundStage.stretch).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream: the stroke's own feel, strokeTexture while the finger
//          runs along the groove and strokeContact when a pushed stroke plays the shot; outside the feel-cue list
//          because they follow the finger, not the recording.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan item 36: the two made-it moments have no pattern here; the
//          screens that sound them already give the system's success haptic on the same change, explained below.)
// PURPOSE: Core Haptics for the break. Takes the same feel cues that drive sound (FeelMapping) and plays a
//          short pattern per cue: a sharp hit with a low rumble for the break crack, light taps for ball
//          contacts, a duller thump for the rail, a thud with a rattle for a pocket. Strength scales intensity.
//          Where the device has no haptics engine (Mac, simulator, some iPads) the engine is never created and
//          every call quietly returns, so nothing logs or fails. Reduce Motion is deliberately NOT used to
//          switch haptics off: it concerns on-screen movement, and the system already honours the player's
//          System Haptics switch inside Core Haptics.
//          Launch with -logFeel to print each cue as it fires (used to check events against the recording).
// SRP/DRY check: Pass - touch output only; cue selection lives in FeelMapping, timing in the playback loop.
import CoreHaptics
import Foundation

@MainActor
final class Haptics {
    /// The one haptics engine, shared by the shot playback and the match moments.
    static let shared = Haptics()

    private var engine: CHHapticEngine?
    /// False on hardware without a haptics engine; every play call checks it first.
    var isAvailable: Bool { engine != nil }

    private init() {
        // Silent testing switch shared with sound, so a shared machine never buzzes.
        if ProcessInfo.processInfo.arguments.contains("-muteSound") { return }
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let e = try CHHapticEngine()
            // Let the system power the engine down when idle; start() before each play wakes it again.
            e.isAutoShutdownEnabled = true
            // If the system resets the engine (audio interruption, backgrounding) the next play() calls
            // start() again, so no handlers are needed and nothing runs off the main actor.
            engine = e
        } catch {
            engine = nil
        }
    }

    /// Play every cue of a frame. Cheap no-op when there is no engine.
    func play(_ cues: [FeelCue]) {
        // The Vibration option is read at play time, so switching it in Options takes effect at once.
        guard let engine, !cues.isEmpty, GameSettings.hapticsOn else { return }
        var events: [CHHapticEvent] = []
        for cue in cues { events += Self.events(for: cue) }
        guard !events.isEmpty else { return }
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Haptics are a flourish; a failure must never reach the player.
        }
    }

    // MARK: The stroke (plans/21-Nov-2026-stroke-and-power-plan.md)

    /// One tick of the groove's texture as the finger strokes along it. `roughness` 0 is on the groove: a faint, dull
    /// tick, like a cue sliding through a smooth bridge. Toward 1, off the groove: stronger and crisper, a cue grating
    /// on a rough bridge, so the player feels the stroke wander before seeing it.
    func strokeTexture(roughness: Double) {
        let r = min(1, max(0, roughness))
        playEvents([Self.tap(0.08 + 0.32 * r, 0.15 + 0.7 * r, at: 0)])
    }

    /// The tip meeting the ball when a pushed stroke plays the shot: one firm, crisp click.
    func strokeContact() {
        playEvents([Self.tap(0.85, 0.8, at: 0)])
    }

    // 0.7.7 bullet-time: the freeze's own buzz, an entry point beside the stroke's (not a new feel cue, which would
    // open the exhaustive switches here and in SoundBoard for a moment that has no sound of its own).
    /// The clock stopping on a hit (BulletTime): a firm tap, harder for a faster hit (`strength` 0 to 1), then a short
    /// low hum under the held moment.
    func freeze(strength: Double) {
        let s = min(1, max(0, strength))
        playEvents([
            Self.tap(0.7 + 0.3 * s, 0.6, at: 0),
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
            ], relativeTime: 0.02, duration: 0.3),
        ])
    }

    /// Play prepared events, honouring the Vibration option as every cue does. Cheap no-op without an engine.
    private func playEvents(_ events: [CHHapticEvent]) {
        guard let engine, !events.isEmpty, GameSettings.hapticsOn else { return }
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Haptics are a flourish; a failure must never reach the player.
        }
    }

    private static func tap(_ intensity: Double, _ sharpness: Double, at t: Double) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(min(1, max(0, intensity)))),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(min(1, max(0, sharpness)))),
        ], relativeTime: t)
    }

    /// Strength to touch: sharpness says how crisp (glass-like) or dull (rubber-like) the tap feels. Intensity
    /// comes from the cue's strength, the same number that sets the sound's layer and volume; the delay is stretched
    /// in slow motion exactly as the sound's is, so a tap lands with its sound.
    static func events(for cue: FeelCue) -> [CHHapticEvent] {
        let s = cue.strength, d = SoundStage.stretch(cue.delay)
        switch cue.kind {
        case .crack:
            // A hard, crisp hit, then a short low rumble that fades, like the rack bursting.
            return [
                tap(1.0, 0.9, at: d),
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.35 + 0.4 * s)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15),
                ], relativeTime: d + 0.02, duration: 0.22),
            ]
        case .click:
            return [tap(0.15 + 0.6 * s, 0.75, at: d)]
        case .tock:
            return [tap(0.3 + 0.5 * s, 0.55, at: d)]
        case .cushion:
            return [tap(0.2 + 0.7 * s, 0.25, at: d)]
        case .pocket:
            // The drop itself: a dull thud. The settling taps come as their own knock cues, timed from the entry speed.
            return [tap(0.4 + 0.5 * s, 0.2, at: d)]
        case .knock:
            return [tap(0.1 + 0.5 * s, 0.5, at: d)]
        case .pin:
            // The clack of the pin, then a softer tap as it lands on the bed (the voice's second hit, a tenth later).
            return [tap(0.2 + 0.6 * s, 0.6, at: d), tap(0.1 + 0.3 * s, 0.35, at: d + SoundStage.stretch(0.11))]
        case .post:
            // Firmer and crisper than a rail: the post does not give.
            return [tap(0.25 + 0.6 * s, 0.45, at: d)]
        case .landing:
            return [tap(0.3 + 0.7 * s, 0.3, at: d)]
        case .offTable:
            // The floor thud (the delay already holds the fall), dull and heavy.
            return [tap(0.3 + 0.6 * s, 0.15, at: d)]
        case .rimSkip:
            // Two quick crisp taps: the near edge and the far edge of the hole (the voice's two clatters).
            return [tap(0.2 + 0.5 * s, 0.7, at: d), tap(0.15 + 0.35 * s, 0.7, at: d + SoundStage.stretch(0.035))]
        case .miscue:
            // A crisp slip and a thin scrape after it.
            return [
                tap(0.25 + 0.5 * s, 0.95, at: d),
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.15 + 0.25 * s)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9),
                ], relativeTime: d + 0.01, duration: 0.06),
            ]
        case .settle:
            return [tap(0.1 + 0.3 * s, 0.3, at: d)]
        case .foul:
            // Two dull taps, the second softer, in step with the two falling notes.
            return [tap(0.3 + 0.4 * s, 0.2, at: d), tap(0.2 + 0.3 * s, 0.15, at: d + 0.18)]
        case .turnChange:
            return [tap(0.15 + 0.35 * s, 0.4, at: d), tap(0.1 + 0.3 * s, 0.4, at: d + 0.09)]
        case .win:
            // Four rising taps, one per note of the arpeggio, each a little crisper.
            return (0..<4).map { i in tap(0.3 + 0.5 * s, 0.4 + 0.15 * Double(i), at: d + 0.1 * Double(i)) }
        case .madeIt, .madeItBig:
            // Felt already: the lesson, trick-shot and Behind the 8-Ball cards give the system's success haptic
            // (sensoryFeedback) on the same celebration change that starts the glow and this sound. A pattern here
            // would buzz a second time on top of it.
            return []
        }
    }
}
