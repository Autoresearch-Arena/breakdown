// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Did the stroke change what happened? (item 4 of plans/21-Nov-2026-bugs-after-0-6-6-plan.md). A finger stroke
//          that strays off the groove turns the cue a little before the shot is solved, and a long pot lined up exactly
//          on the guide can then miss with nothing on screen saying why. This file answers the question honestly: the
//          same shot is solved once more as aimed (the stroke's turn and tip slip taken back off the strike), and the
//          two outcomes are compared on what a player notices: the first ball hit, a pot made or missed, the cue ball
//          lost or kept. The result line (StrokeWords, StrokeResultCard, the spoken summary) shows only when they differ
//          or the stroke itself pushed the tip off the ball, in either zone of the power bar.
//          - StrokeEffect: the pure part. The strike as aimed (straightInput), the outcome a player reads off a
//            recording (Outcome, from the package's ShotFacts), and the comparison (change).
//          - StrokeEffects: the main-actor cache. One shared instance works each attempt out once on a background task
//            (a solve can take a while, as the model's own strike does) and keeps the last few answers, so the card,
//            the drill and VoiceOver read the same answer for the shot on screen.
//          A break is a scatter: the smallest change of line reshuffles which balls drop, so on a break only a changed
//          first ball (or a miscue) is put down to the stroke. Its pots are not.
// SRP/DRY check: Pass - checked ShowpieceModel.prepare (the table, cloth and physics generation are written in here in
//          the same order from what the attempt recorded, because the model's helper is private and bound to the
//          table on screen now, not the one the attempt was solved on), ShotAttempt.facts and ShotFacts (the package's
//          one reading of a shot: first contact, drops and scratch come from it), StrokeDelivery.apply (the turn is
//          undone by the same rotation the other way) and RetryComparison (it compares two tries the player made; this
//          compares one try with the same try played straight, which no player made).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import Observation

enum StrokeEffect {
    /// What the stroke changed, most noticeable first (the order change(actual:straight:isBreak:) checks them in).
    enum Change: Equatable, Sendable {
        /// The stroke carried the tip past its grip: a miscue the aimed stroke would not have made.
        case miscue
        /// Played straight, the cue ball would have hit a different ball first (or a ball, or none).
        case firstBall
        /// Played straight, a ball would have dropped that did not.
        case potMissed
        /// The cue ball was lost (pocketed or off the table); played straight it would have stayed.
        case scratched
        /// A ball dropped that would have stayed up played straight.
        case potMade
        /// The cue ball stayed; played straight it would have been lost.
        case scratchAvoided
    }

    /// What a player reads off a shot: the first ball the struck ball touched, the other balls that dropped, and
    /// whether the struck ball was lost.
    struct Outcome: Equatable, Sendable {
        var firstBall: Int?
        var pocketed: Set<Int>
        var scratched: Bool

        init(firstBall: Int?, pocketed: Set<Int>, scratched: Bool) {
            self.firstBall = firstBall
            self.pocketed = pocketed
            self.scratched = scratched
        }

        init(_ facts: ShotFacts) {
            self.init(firstBall: facts.firstContactBalls.first,
                      pocketed: Set(facts.pocketed.map(\.ball).filter { $0 != facts.cueBall }),
                      scratched: facts.cueBallScratched)
        }
    }

    /// The attempt's strike as the player aimed it, ready for the solver: the recorded (drifted) input with the turn
    /// rotated back off its direction and the tip put back where it was aimed, then the table, cloth and physics
    /// generation the attempt was solved on written in as ShowpieceModel.prepare writes them (generation one's own
    /// numbers first, then the table, then the cloth, then the generation last so nothing overwrites it). Nil when
    /// the stroke put no drift on the strike: the shot on screen is already the shot as aimed.
    static func straightInput(of attempt: ShotAttempt) -> ShotInput? {
        guard let d = attempt.stroke, !d.isZero else { return nil }
        var input = attempt.input
        if d.aimError != 0 {
            let c = cos(-d.aimError), s = sin(-d.aimError)
            let v = input.strike.direction
            input.strike.direction = Vec2(v.x * c - v.y * s, v.x * s + v.y * c)
        }
        // The attempt keeps the side the player chose (the break's or the shot's); the delivery only moved it.
        input.strike.tipSide = attempt.tipSide
        if attempt.generation == 1 { input.parameters.useGenerationOne() }
        attempt.table.apply(to: &input.parameters)
        attempt.surface.apply(to: &input.parameters)
        input.parameters.modelGeneration = attempt.generation
        return input
    }

    /// The change between the shot as played and as aimed, or nil when a player would see no difference. On a break
    /// only the first ball counts (the file header says why).
    static func change(actual: Outcome, straight: Outcome, isBreak: Bool) -> Change? {
        if actual.firstBall != straight.firstBall { return .firstBall }
        if isBreak { return nil }
        if !straight.pocketed.subtracting(actual.pocketed).isEmpty { return .potMissed }
        if actual.scratched && !straight.scratched { return .scratched }
        if !actual.pocketed.subtracting(straight.pocketed).isEmpty { return .potMade }
        if !actual.scratched && straight.scratched { return .scratchAvoided }
        return nil
    }

    /// Solve the shot as aimed and compare: the heavy part, run off the main actor.
    static func change(solving straightInput: ShotInput, actual: Outcome, isBreak: Bool) -> Change? {
        let tl = PoolSolver.simulate(straightInput)
        let straight = Outcome(ShotFacts(timeline: tl, start: straightInput.positions,
                                         cueBall: straightInput.strike.ballIndex))
        return change(actual: actual, straight: straight, isBreak: isBreak)
    }
}

/// The answers for the shots on screen, worked out once each. Shared by every window: an answer is filed under
/// everything that decides it (Key), so two windows never mix theirs up.
@MainActor
@Observable
final class StrokeEffects {
    static let shared = StrokeEffects()

    /// Everything that decides an attempt's answer: the start, the settings, the seed, the table, cloth and physics
    /// generation, and the delivery. The solver is deterministic, so equal keys always have the same answer (a retry
    /// with the same settings and the same stroke shares it, rightly).
    struct Key: Equatable, Sendable {
        let isBreak: Bool
        let seed: UInt64
        let aim: Double
        let power: Double
        let tipUp: Double
        let tipSide: Double
        let elevation: Double
        let start: [Vec2]
        let table: TableKind
        let surface: PlaySurface
        let generation: Int
        let stroke: StrokeDelivery

        /// Nil for a strike with no stroke at all (a demonstration, a hint, a scripted shot).
        init?(_ a: ShotAttempt) {
            guard let stroke = a.stroke else { return nil }
            isBreak = a.isBreak; seed = a.seed; aim = a.aim; power = a.power; tipUp = a.tipUp; tipSide = a.tipSide
            elevation = a.elevation; start = a.start; table = a.table; surface = a.surface; generation = a.generation
            self.stroke = stroke
        }
    }

    struct Entry {
        let key: Key
        /// Nil: the stroke changed nothing a player would see.
        let change: StrokeEffect.Change?
    }

    /// How many answers are kept: the shot on screen and the few before it, with room for a second window.
    static let kept = 8

    /// The answers, oldest first.
    private(set) var entries: [Entry] = []
    /// Attempts being worked out now. Not observed: request(_:) may be called while a view reads its body, and only
    /// the finished answer (entries) should redraw anything.
    @ObservationIgnored private var working: [Key] = []

    /// Work an attempt's answer out if it is not known or under way. A stroke with no drift changed nothing and needs
    /// no answer; a stroke that pushed the tip past its grip made the miscue, which needs no solve to say.
    func request(_ attempt: ShotAttempt) {
        guard let key = Key(attempt), !key.stroke.isZero else { return }
        guard !entries.contains(where: { $0.key == key }), !working.contains(key) else { return }
        working.append(key)
        let isBreak = attempt.isBreak
        let input = key.stroke.pushedPastGrip ? nil : StrokeEffect.straightInput(of: attempt)
        let actual = StrokeEffect.Outcome(attempt.facts)
        Task { [weak self] in
            var change: StrokeEffect.Change? = .miscue
            if let input {
                change = await Task.detached(priority: .utility) {
                    StrokeEffect.change(solving: input, actual: actual, isBreak: isBreak)
                }.value
            }
            self?.store(key, change)
        }
    }

    /// The answer for an attempt, or nil while it is being worked out or when the stroke changed nothing. Asks for it
    /// when it is not known yet (only the unobserved working list changes here, so a view body may call it).
    func change(for attempt: ShotAttempt) -> StrokeEffect.Change? {
        guard let key = Key(attempt) else { return nil }
        if let entry = entries.last(where: { $0.key == key }) { return entry.change }
        request(attempt)
        return nil
    }

    /// The newest answer for a delivery, for callers that hold the shot's delivery rather than the attempt (the
    /// spoken summary). The shot on screen is always the newest attempt worked out.
    func change(for delivery: StrokeDelivery) -> StrokeEffect.Change? {
        entries.last(where: { $0.key.stroke == delivery })?.change
    }

    private func store(_ key: Key, _ change: StrokeEffect.Change?) {
        working.removeAll { $0 == key }
        guard !entries.contains(where: { $0.key == key }) else { return }
        entries.append(Entry(key: key, change: change))
        if entries.count > Self.kept { entries.removeFirst(entries.count - Self.kept) }
    }
}
