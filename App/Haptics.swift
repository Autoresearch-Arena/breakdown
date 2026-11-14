// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
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
    private var engine: CHHapticEngine?
    /// False on hardware without a haptics engine; every play call checks it first.
    var isAvailable: Bool { engine != nil }

    init() {
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
        guard let engine, !cues.isEmpty else { return }
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

    private static func tap(_ intensity: Double, _ sharpness: Double, at t: Double) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(min(1, max(0, intensity)))),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(min(1, max(0, sharpness)))),
        ], relativeTime: t)
    }

    /// Strength to touch: sharpness says how crisp (glass-like) or dull (rubber-like) the tap feels.
    static func events(for cue: FeelCue) -> [CHHapticEvent] {
        let s = cue.strength, d = cue.delay
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
            // The drop, then three little taps closer together each time, the ball settling in the pocket.
            return [
                tap(0.4 + 0.5 * s, 0.2, at: d),
                tap(0.3 * s + 0.15, 0.5, at: d + 0.09),
                tap(0.22 * s + 0.1, 0.5, at: d + 0.16),
                tap(0.15 * s + 0.08, 0.5, at: d + 0.21),
            ]
        }
    }
}
