// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: Turns solver events into the plain-language captions and equations the Physics Lens shows. Every
//          number in a caption is read from the recorded event (pillar one: nothing is drawn that the solver
//          did not compute). Captions are thinned to the most important event per quarter second so slow motion
//          stays readable.
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
        // Keep the strongest caption in each quarter-second window, but never drop the opening strike.
        var best: [Int: Caption] = [:]
        for c in all {
            let slot = Int(c.time / 0.25)
            if c.accent == .strike { best[-1] = c; continue }
            if let cur = best[slot], cur.importance >= c.importance { continue }
            best[slot] = c
        }
        return best.values.sorted { $0.time < $1.time }
    }

    private static func name(_ ball: Int) -> String { ball == 0 ? "the cue ball" : "the \(ball) ball" }
    private static func f(_ x: Double, _ digits: Int = 1) -> String { String(format: "%.\(digits)f", x) }

    private static func caption(for e: LensEvent, id: Int) -> Caption? {
        switch e.kind {
        case .cueStrike:
            let b = e.balls[0]
            let spin = b.omegaAfter.length
            let detail = spin > 20
                ? "The cue sends the ball off at \(f(b.velocityAfter.length)) metres per second. Hitting below centre adds backspin, which the ball carries with it."
                : "The cue sends the ball off at \(f(b.velocityAfter.length)) metres per second. Its momentum is mass times speed."
            return Caption(id: id, time: e.time, title: "The cue hands over its speed", detail: detail,
                           equation: "p = m · v", accent: .strike, importance: 1e9)
        case .ballBall:
            guard e.balls.count == 2 else { return nil }
            let a = e.balls[0], b = e.balls[1]
            let (mover, other) = a.velocityBefore.length >= b.velocityBefore.length ? (a, b) : (b, a)
            let before = a.energyBefore + b.energyBefore
            guard mover.velocityBefore.length > 0.8, before > 0 else { return nil }
            let share = (other.energyAfter / before) * 100
            let keep = (mover.energyAfter / before) * 100
            let detail = "\(name(mover.ball).capitalizedFirst) was moving at \(f(mover.velocityBefore.length)) m/s. "
                + "Energy handed off: \(f(share, 0)) percent goes to \(name(other.ball)), \(f(keep, 0)) percent stays, "
                + "and the rest is lost as heat and sound."
            return Caption(id: id, time: e.time, title: "Energy handed off", detail: detail,
                           equation: "J = (1 + e) · m · v⊥ / 2", accent: .impact, importance: e.normalImpulse)
        case .cushion:
            let b = e.balls[0]
            let vin = b.velocityBefore.length
            guard vin > 1.2 else { return nil }
            let kept = (b.velocityAfter.dot(e.normal) / max(1e-9, -b.velocityBefore.dot(e.normal))) * 100
            return Caption(id: id, time: e.time, title: "The cushion pushes back",
                           detail: "\(name(b.ball).capitalizedFirst) hits the rail at \(f(vin)) m/s and keeps \(f(kept, 0)) percent of its speed straight into the rail. Sideways speed is trimmed by friction.",
                           equation: "v⊥′ = −e · v⊥", accent: .cushion, importance: e.normalImpulse)
        case .phaseTransition:
            guard e.phaseFrom == .sliding, e.phaseTo == .rolling else { return nil }
            let b = e.balls[0]
            let v = b.velocityAfter.length
            guard v > 1.0 else { return nil }
            return Caption(id: id, time: e.time, title: "Skid turns into roll",
                           detail: "Friction with the cloth slowed \(name(b.ball)) and spun it up until the bottom of the ball stopped slipping. It now rolls at \(f(v)) m/s.",
                           equation: "v_roll = 5/7 · v (no spin)", accent: .friction, importance: v * 0.12)
        case .pocket:
            let b = e.balls[0]
            return Caption(id: id, time: e.time, title: "Pocketed",
                           detail: "\(name(b.ball).capitalizedFirst) drops in at \(f(b.velocityBefore.length)) m/s.",
                           equation: "ΔKE → 0", accent: .pocket, importance: 3)
        }
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
