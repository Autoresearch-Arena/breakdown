// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (jaw and knuckle hits get their own caption: "Off the jaw" or "Clipped the point").
// Edited: Claude Haiku 5.5 High, 20-November-2026 (every sentence is a whole localized string, so translators can reorder it; numbers are formatted for the player's language).
// Edited: Claude Opus 5.5 High, 20-November-2026 (no more thinning to one caption per quarter second: every
//          captioned event is kept, so the rack explosion's dozen hits survive for PacePlan to choose beats from;
//          speed gates lowered so second-wave rack hits are captioned while dribbles still are not).
// PURPOSE: Turns solver events into the plain-language captions and equations the Physics Lens shows. Every
//          number in a caption is read from the recorded event (pillar one: nothing is drawn that the solver
//          did not compute). Every event that clears its speed gate gets a caption, sorted by time; choosing which
//          ones the replay stops on is PacePlan's job. Words the player reads go through String(localized:) so they
//          land in the string catalog.
// SRP/DRY check: Pass - caption selection and wording only; display lives in the view.
import BreakdownLensModel
import BreakdownTimeline
import Foundation

enum CaptionAccent { case strike, impact, cushion, friction, pocket }

struct Caption: Identifiable, Equatable {
    let id: Int
    let time: Double
    let title: String
    let detail: String
    let equation: String
    let accent: CaptionAccent
    let importance: Double
}

enum CaptionEngine {
    static func make(from timeline: Timeline) -> [Caption] {
        var all: [Caption] = []
        for (index, e) in timeline.events.enumerated() {
            if let c = caption(for: e, id: index) { all.append(c) }
        }
        // All of them, in clock order. Events arrive sorted already; the explicit sort with the event index as the
        // tie-break keeps simultaneous rack hits in one fixed order whatever the solver's ordering guarantees.
        // The id stays the event's index: the on-table marker finds its ball through it.
        return all.sorted { ($0.time, $0.id) < ($1.time, $1.id) }
    }

    /// A ball's name as a player would say it. Each form is a whole phrase, so a translator can reorder it.
    private static func name(_ ball: Int) -> String {
        ball == 0 ? String(localized: "the cue ball") : String(localized: "the \(ball) ball")
    }

    /// A number with the decimal places asked for, written the way the player's language writes numbers.
    private static func f(_ x: Double, _ digits: Int = 1) -> String {
        String(format: "%.\(digits)f", locale: Locale.current, x)
    }

    private static func caption(for e: LensEvent, id: Int) -> Caption? {
        switch e.kind {
        case .cueStrike:
            let b = e.balls[0]
            let spin = b.omegaAfter.length
            let speed = f(b.velocityAfter.length)
            let detail = spin > 20
                ? String(localized: "The cue sends the ball off at \(speed) metres per second. Hitting below centre adds backspin, which the ball carries with it.")
                : String(localized: "The cue sends the ball off at \(speed) metres per second. Its momentum is mass times speed.")
            return Caption(id: id, time: e.time, title: String(localized: "The cue hands over its speed"), detail: detail,
                           equation: "p = m · v", accent: .strike, importance: 1e9)
        case .ballBall:
            guard e.balls.count == 2 else { return nil }
            let a = e.balls[0], b = e.balls[1]
            let (mover, other) = a.velocityBefore.length >= b.velocityBefore.length ? (a, b) : (b, a)
            let before = a.energyBefore + b.energyBefore
            // 0.4 m/s keeps the second wave through the rack (balls already moving pass the energy on) while
            // two balls nudging each other at walking pace stay quiet.
            guard mover.velocityBefore.length > 0.4, before > 0 else { return nil }
            let share = (other.energyAfter / before) * 100
            let keep = (mover.energyAfter / before) * 100
            let detail = String(localized: "\(name(mover.ball).capitalizedFirst) was moving at \(f(mover.velocityBefore.length)) m/s. Energy handed off: \(f(share, 0)) percent goes to \(name(other.ball)), \(f(keep, 0)) percent stays, and the rest is lost as heat and sound.")
            return Caption(id: id, time: e.time, title: String(localized: "Energy handed off"), detail: detail,
                           equation: "J = (1 + e) · m · v⊥ / 2", accent: .impact, importance: e.normalImpulse)
        case .cushion where e.edge != .rail:
            // A pocket jaw or knuckle: the ball reached the mouth and was turned away (or rattled). Worth saying even
            // when slow, because it is the answer to "why didn't that go in?".
            let b = e.balls[0]
            let part = e.edge == .knuckle ? String(localized: "the point of the pocket") : String(localized: "the pocket's jaw")
            let title = e.edge == .knuckle ? String(localized: "Clipped the point") : String(localized: "Off the jaw")
            return Caption(id: id, time: e.time, title: title,
                           detail: String(localized: "\(name(b.ball).capitalizedFirst) catches \(part) at \(f(b.velocityBefore.length)) m/s and is turned away from the hole. A little more to the middle of the pocket and it drops."),
                           equation: "v⊥′ = −e · v⊥", accent: .cushion, importance: e.normalImpulse + 0.5)
        case .cushion:
            let b = e.balls[0]
            let vin = b.velocityBefore.length
            guard vin > 0.8 else { return nil }
            let kept = (b.velocityAfter.dot(e.normal) / max(1e-9, -b.velocityBefore.dot(e.normal))) * 100
            return Caption(id: id, time: e.time, title: String(localized: "The cushion pushes back"),
                           detail: String(localized: "\(name(b.ball).capitalizedFirst) hits the rail at \(f(vin)) m/s and keeps \(f(kept, 0)) percent of its speed straight into the rail. Sideways speed is trimmed by friction."),
                           equation: "v⊥′ = −e · v⊥", accent: .cushion, importance: e.normalImpulse)
        case .phaseTransition:
            guard e.phaseFrom == .sliding, e.phaseTo == .rolling else { return nil }
            let b = e.balls[0]
            let v = b.velocityAfter.length
            guard v > 0.7 else { return nil }
            let noSpin = String(localized: "(no spin)")
            return Caption(id: id, time: e.time, title: String(localized: "Skid turns into roll"),
                           detail: String(localized: "Friction with the cloth slowed \(name(b.ball)) and spun it up until the bottom of the ball stopped slipping. It now rolls at \(f(v)) m/s."),
                           equation: "v_roll = 5/7 · v \(noSpin)", accent: .friction, importance: v * 0.12)
        case .pocket:
            let b = e.balls[0]
            return Caption(id: id, time: e.time, title: String(localized: "Pocketed"),
                           detail: String(localized: "\(name(b.ball).capitalizedFirst) drops in at \(f(b.velocityBefore.length)) m/s."),
                           equation: "ΔKE → 0", accent: .pocket, importance: 3)
        }
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
