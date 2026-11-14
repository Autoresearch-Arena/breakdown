// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// PURPOSE: One pure place that turns the recorded impacts crossed in a frame into "feel cues" (what kind of
//          thump or click, how strong, how long after the first). SoundBoard and Haptics both read these cues, so
//          sight, sound and touch are all driven by the same recorded number and can never disagree. The break
//          drops about thirty contacts at the same instant; this file collapses them into one sharp crack plus a
//          few quieter scatter clicks, instead of thirty overlapping sounds. No audio or haptic framework is
//          imported here, so the mapping is easy to log, reason about and test.
// SRP/DRY check: Pass - mapping only; SoundBoard makes noise and Haptics makes touch. Replaces the strength
//          formula that used to live inside SoundBoard.
import BreakdownLensModel
import Foundation

/// What a cue sounds and feels like.
enum FeelKind: String, Sendable {
    case crack      // the break: the rack bursting apart
    case click      // ball meets ball
    case tock       // the cue tip meeting the cue ball
    case cushion    // ball meets rail
    case pocket     // ball drops and rattles in the pocket
}

/// One thing to play: a kind, a strength from 0 to 1, and a small delay after the frame's first cue.
struct FeelCue: Equatable, Sendable {
    var kind: FeelKind
    var strength: Double
    var delay: Double
}

enum FeelMapping {
    /// Cues below this strength are inaudible and unfelt, so they are dropped.
    static let floor = 0.05
    /// A burst of at least this many ball contacts, led by a hard one, is the break.
    static let crackMinContacts = 3
    static let crackMinStrength = 0.8
    /// Most scatter clicks that follow a crack, and most rail thumps or ball clicks per frame.
    static let maxScatter = 3
    static let maxPerKind = 2

    /// Impulse (newton-seconds) to a 0...1 strength. The recorded impulses span about 0.002 to 2.2, so the
    /// curve is compressed (power 0.6) to keep light contacts audible and hard ones from all sounding the same.
    static func strength(impulse: Double) -> Double {
        pow(min(1, max(0, impulse) / 2.0), 0.6)
    }

    /// A ball dropping is recorded with no impulse, so its strength comes from the speed it arrived at.
    static func pocketStrength(_ e: LensEvent) -> Double {
        guard let b = e.balls.first else { return 0.6 }
        let speed = b.velocityBefore.lengthSquared.squareRoot()
        return min(1, max(0.35, speed / 3.0))
    }

    /// Collapse the events crossed in one frame into the cues to play. Events of any order are accepted.
    static func cues(for events: [LensEvent]) -> [FeelCue] {
        var out: [FeelCue] = []

        // Ball contacts, strongest first.
        let contacts = events.filter { $0.kind == .ballBall }
            .map { strength(impulse: $0.normalImpulse) }
            .sorted(by: >)
        if let lead = contacts.first, contacts.count >= crackMinContacts, lead >= crackMinStrength {
            out.append(FeelCue(kind: .crack, strength: lead, delay: 0))
            // The scattering balls: a few quieter clicks trailing the crack by a few hundredths of a second.
            for (i, s) in contacts.dropFirst().prefix(maxScatter).enumerated() where s * 0.6 >= floor {
                out.append(FeelCue(kind: .click, strength: s * 0.6, delay: 0.018 * Double(i + 1)))
            }
        } else {
            for (i, s) in contacts.prefix(maxPerKind).enumerated() where s >= floor {
                out.append(FeelCue(kind: .click, strength: s, delay: 0.012 * Double(i)))
            }
        }

        for (i, s) in events.filter({ $0.kind == .cushion })
            .map({ strength(impulse: $0.normalImpulse) }).sorted(by: >).prefix(maxPerKind).enumerated() where s >= floor {
            out.append(FeelCue(kind: .cushion, strength: s, delay: 0.015 * Double(i)))
        }
        if let cue = events.first(where: { $0.kind == .cueStrike }) {
            out.append(FeelCue(kind: .tock, strength: strength(impulse: cue.normalImpulse), delay: 0))
        }
        if let pocket = events.filter({ $0.kind == .pocket }).max(by: { pocketStrength($0) < pocketStrength($1) }) {
            out.append(FeelCue(kind: .pocket, strength: pocketStrength(pocket), delay: 0))
        }
        return out
    }
}
