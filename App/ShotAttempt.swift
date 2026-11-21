// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// Edited: Claude Opus 5.5 High, 21-November-2026 (an honest retry, plan 14 section 2: an attempt now keeps the effective
//          shot input it was solved from (layout, aim, power, tip, cue elevation and the seed), the table, surface and
//          physics generation it was solved on, and which ball the cue struck. RetryComparison is the comparison as
//          facts (what each control changed, how far the cue ball's finish moved, what dropped each time, and one key
//          saying which single sentence fits); the words are a separate step (ShotComparison.describe), so a view can
//          write its own. "Same shot, same result" is only said when the inputs are identical AND the recorded motion
//          and events match, vertical travel included; a change too small to describe gets a modest sentence; several
//          changed controls are listed without naming one as the cause; a try that touched no ball says so.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream: an attempt keeps the stroke's delivery (StrokeDelivery:
//          the drift it put on the strike and the finger stroke it came from), and its `input` is the delivered,
//          drifted strike. The comparison gains one fact, `stroke`: whether the retry's stroke was straighter or
//          wandered more, judged from the two deliveries' aim drift, outside the controls so no setting is reported
//          as changed by it. The words add the stroke's sentence.)
// PURPOSE: Try again and compare. One player shot (or the player's own break) recorded as an attempt: where every ball
//          started, the exact settings used, and the recorded timeline it produced. Two attempts from the same start
//          are compared as facts (RetryComparison) and then in plain words (ShotComparison): what the player changed
//          (spin, side, power, aim, cue elevation) and what happened differently (which balls dropped, where the cue
//          ball finished). Also the ghost paths of an attempt (the cue ball and the first ball it struck), sampled once
//          from the recording, so the faint "last try" lines are a fixed picture that never depends on the playback
//          clock.
//          Everything here is read from recorded timelines and the settings the player chose; nothing is guessed.
//          Read by ShowpieceModel (which makes the attempts, decides when to compare, and keeps the result as
//          retryComparison and comparison), GhostOverlay (ghost paths, the card), TrickShotJudge and EightBallMode
//          (the attempt's settings and outcome).
// SRP/DRY check: Pass - checked ShowpieceModel (keeps the attempts and the flow), ShotPanel.tipWord/sideWord (reused
//          here for the spin words), CaptionEngine (wording for single events, not for comparisons), ShotFacts (the
//          package's one reading of a shot: first contact and scratch come from it, not from a second scan here). This
//          file only describes attempts; the model decides when they are made and the overlay draws them.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

struct ShotAttempt {
    /// True for the player's own break (Try again re-racks the identical rack).
    let isBreak: Bool
    /// The seed the break's rack was built from; unused for a shot.
    let breakSeed: UInt64
    /// Where every ball started; index 0 is the cue ball, (-1,-1) means off the table.
    let start: [Vec2]
    let timeline: Timeline
    /// Aim: degrees counter-clockwise on the table plan for a shot, metres off the apex ball for a break.
    let aim: Double
    /// Launch speed, metres per second, and the range the power control allowed (for "harder" or "softer").
    let power: Double
    let powerRange: ClosedRange<Double>
    /// Cue-tip contact point, metres: up is follow, down is draw, right and left are side spin.
    let tipUp: Double
    let tipSide: Double
    /// Sine of the cue's angle above the table (0 is a level cue). Kept so a retry restores a raised cue too.
    let elevation: Double
    /// The shot's seed: the solver's only source of physical variation (a seeded miscue at generation two). A retry
    /// strikes with this same seed; the model's display counter for the recording is a separate number.
    let seed: UInt64
    /// The effective input as it was handed to the solver, before the table's and surface's numbers were written in.
    let input: ShotInput
    /// What it was solved on. A retry on a different table, cloth or physics generation is not compared with it.
    let surface: PlaySurface
    let table: TableKind
    let generation: Int
    /// The drift the player's stroke put on the strike, and the stroke it came from; nil for a scripted strike or a
    /// demonstration. `input` above already holds the drifted strike (the effective input).
    var stroke: StrokeDelivery? = nil

    /// The ball the cue struck (0, the pool cue ball, except on tables where each player has their own).
    var cueBall: Int { input.strike.ballIndex }

    /// The package's one reading of this shot (first contact, drops, scratch), with this attempt's cue ball.
    var facts: ShotFacts { ShotFacts(timeline: timeline, start: start, cueBall: cueBall) }

    /// Object balls (not the cue ball) that dropped during this attempt.
    var pocketedObjectBalls: [Int] {
        (0..<timeline.ballCount).filter { $0 != cueBall && timeline.pocketTime[$0] != nil && NextShot.isOnTable(start[$0]) }
    }
    var cueBallScratched: Bool { timeline.pocketTime[cueBall] != nil }
    /// Where the cue ball came to rest (or where it was taken by a pocket).
    var cueRest: Vec2 { timeline.state(ball: cueBall, at: timeline.duration).position }

    /// Fingerprint of the motion alone: every ball's segments (vertical travel included, so a jump that lands
    /// differently is not "the same") and every event, but not the shot's seed or serial (Timeline.contentHash includes
    /// them). Equal for a retry with identical settings.
    var motionHash: UInt64 {
        var h = StableHasher()
        for ball in timeline.segments {
            h.combine(ball.count)
            for s in ball {
                h.combine(s.t0); h.combine(s.t1); h.combine(Int(s.phase.rawValue))
                h.combine(s.position0); h.combine(s.velocity0); h.combine(s.omega0)
                h.combine(s.height0); h.combine(s.verticalVelocity0); h.combine(s.verticalAcceleration)
            }
        }
        for e in timeline.events {
            h.combine(e.time); h.combine(Int(e.kind.rawValue)); h.combine(e.point)
            h.combine(e.balls.count)
            for b in e.balls { h.combine(b.ball) }
            h.combine(e.pocket); h.combine(e.height)
            // A miscue is part of what happened at the strike; nil (generation one) and false hash differently on
            // purpose, but both attempts of one comparison share a generation (see sameConditions).
            h.combine(e.miscue == true ? 2 : (e.miscue == false ? 1 : 0))
        }
        return h.value
    }

    /// The first object ball the cue ball touched, if any.
    var firstStruck: Int? {
        for e in timeline.events where e.kind == .ballBall {
            let ids = e.balls.map(\.ball)
            if ids.contains(cueBall) { return ids.first { $0 != cueBall } }
        }
        return nil
    }

    /// The setting a control had for this attempt, in the units the comparison reports.
    func value(of control: RetryComparison.Control) -> Double {
        switch control {
        case .aim: return aim
        case .power: return power
        case .tipUp: return tipUp
        case .tipSide: return tipSide
        case .elevation: return elevation
        }
    }

    /// True when a retry of this attempt may be compared with `other`: same kind of stroke, same start, and solved on
    /// the same table, cloth and physics generation. Anything else is a fresh start, not a retry.
    func sameConditions(as other: ShotAttempt) -> Bool {
        isBreak == other.isBreak && start == other.start && table == other.table && surface == other.surface
            && generation == other.generation
    }

    /// The same attempt solved again on another surface (the model's surface change re-solves the shot on screen).
    func resolved(on newTimeline: Timeline, surface newSurface: PlaySurface) -> ShotAttempt {
        ShotAttempt(isBreak: isBreak, breakSeed: breakSeed, start: start, timeline: newTimeline, aim: aim, power: power,
                    powerRange: powerRange, tipUp: tipUp, tipSide: tipSide, elevation: elevation, seed: seed,
                    input: input, surface: newSurface, table: table, generation: generation, stroke: stroke)
    }

    // MARK: Ghost paths

    /// The cue ball's path and the first struck ball's path, as table points, sampled once. Sixty samples a second of
    /// recorded time is finer than any curve the cloth can bend a ball through; a ball stops being drawn where a
    /// pocket takes it.
    func ghostPaths() -> (cue: [Vec2], object: [Vec2]) {
        (path(of: cueBall), firstStruck.map { path(of: $0) } ?? [])
    }

    private func path(of ball: Int) -> [Vec2] {
        let end = timeline.pocketTime[ball] ?? timeline.duration
        let steps = max(2, Int(end * 60))
        var out: [Vec2] = []
        out.reserveCapacity(steps + 1)
        for i in 0...steps {
            let p = timeline.state(ball: ball, at: end * Double(i) / Double(steps)).position
            // Skip points that have not moved, so a ball waiting to be struck adds nothing.
            if let last = out.last, (p - last).lengthSquared < 1e-8 { continue }
            out.append(p)
        }
        return out
    }
}

// MARK: Comparison facts

/// The comparison of a retry with the attempt before it, as facts only. The model supplies it (retryComparison); a
/// view picks its one sentence from `key` and may use the rest for detail. Contract: docs/award-batch-contracts.md 2.1.
struct RetryComparison: Equatable {
    enum Control: String, CaseIterable { case aim, power, tipUp, tipSide, elevation }
    struct InputChange: Equatable { let control: Control; let before: Double; let after: Double }
    /// Which one sentence the card shows.
    enum Key: Equatable {
        /// Same inputs AND the same recorded motion and events.
        case exactRepeat
        /// Changed too little to describe; the cue ball finished near the same spot and the same balls dropped.
        case sameSpot
        /// Exactly one control moved (enough to describe, or the only control that moved at all).
        case oneChange(Control)
        /// Report the differences, leave the cause open.
        case severalChanges
        /// This try touched no ball.
        case missedEverything
    }
    /// Every control whose value differs at all, in Control order.
    let inputChanges: [InputChange]
    /// Metres between the two finishes; nil if either cue ball was gone (pocketed or off the table).
    let cueBallFinishShift: Double?
    let pottedBefore: [Int]
    let pottedNow: [Int]
    let key: Key
    /// How the retry's stroke compared with the last try's (nil when either had no stroke drift, or the two were too
    /// close to tell apart). Not a control: it never appears in inputChanges, so no setting is reported as changed.
    var stroke: StrokeChange? = nil

    enum StrokeChange: Equatable { case straighter, wilder }
}

extension RetryComparison {
    /// Two finishes this close count as "near the same spot": 5 cm, a little under one ball's width (57 mm), which is
    /// also the distance below which the old wording stopped mentioning the finish at all.
    static let nearSameSpot = 0.05

    /// Work out the comparison of retry `b` with the attempt `a` before it. Both must share their conditions
    /// (ShotAttempt.sameConditions); the model checks that before asking.
    static func between(_ a: ShotAttempt, _ b: ShotAttempt) -> RetryComparison {
        var changes: [InputChange] = []
        for control in Control.allCases {
            let before = a.value(of: control), after = b.value(of: control)
            // Exact comparison on purpose: "the same input" means bit for bit, or the claim of an exact repeat is a lie.
            if before != after { changes.append(InputChange(control: control, before: before, after: after)) }
        }
        let factsA = a.facts, factsB = b.facts
        let shift: Double? = factsA.cueBallScratched || factsB.cueBallScratched ? nil : (b.cueRest - a.cueRest).length
        let pottedA = a.pocketedObjectBalls, pottedB = b.pocketedObjectBalls

        let key: Key
        if changes.isEmpty, a.start == b.start, a.seed == b.seed, a.motionHash == b.motionHash {
            key = .exactRepeat
        } else if factsB.firstContactTime == nil {
            key = .missedEverything
        } else {
            let described = changes.filter { ShotComparison.isDescribable($0, in: a) }
            if described.count == 1 {
                key = .oneChange(described[0].control)
            } else if described.count > 1 {
                key = .severalChanges
            } else if Set(pottedA) == Set(pottedB), let s = shift, s <= nearSameSpot {
                key = .sameSpot
            } else if changes.count == 1 {
                // Too small to put in words, yet the shot came out differently: that one control is still the only
                // thing that moved, so it is named (as "only slightly").
                key = .oneChange(changes[0].control)
            } else {
                key = .severalChanges
            }
        }
        return RetryComparison(inputChanges: changes, cueBallFinishShift: shift, pottedBefore: pottedA,
                               pottedNow: pottedB, key: key, stroke: strokeChange(a.stroke, b.stroke))
    }

    /// Two strokes' aim drifts this far apart are worth a sentence, radians: a third of the 0.15 degrees the aim's own
    /// "aimed a little to the left" needs (ShotComparison.isDescribable), because the drift is felt twice, in the aim
    /// and in the tip's side.
    static let strokeWorthSaying = 0.05 * Double.pi / 180

    /// Straighter or wilder, from the two deliveries' aim drift (the tip's drift moves with it, so one measure serves).
    static func strokeChange(_ a: StrokeDelivery?, _ b: StrokeDelivery?) -> StrokeChange? {
        guard let a, let b else { return nil }
        let before = abs(a.aimError), after = abs(b.aimError)
        if before - after >= strokeWorthSaying { return .straighter }
        if after - before >= strokeWorthSaying { return .wilder }
        return nil
    }
}

// MARK: Comparison words

/// The plain-words comparison of a retry with the attempt before it, written from the facts.
enum ShotComparison {
    /// True when a change is big enough to put into words ("hit it harder"). Smaller ones are real but not worth a
    /// sentence of their own. The thresholds are the ones the wording has always used: a quarter step either side of
    /// the spin words' 2 mm boundary, 4% of the power range, 0.15 degrees of aim (2 mm at the apex ball for a break);
    /// elevation 0.01 in sine, about 0.6 degrees of cue angle, the same order as the aim step.
    static func isDescribable(_ c: RetryComparison.InputChange, in a: ShotAttempt) -> Bool {
        let d = abs(c.after - c.before)
        switch c.control {
        case .aim: return d > (a.isBreak ? 0.002 : 0.15)
        case .power: return d > (a.powerRange.upperBound - a.powerRange.lowerBound) * 0.04
        case .tipUp: return ShotPanel.tipWord(c.before) != ShotPanel.tipWord(c.after) || d > 0.002
        case .tipSide: return ShotPanel.sideWord(c.before) != ShotPanel.sideWord(c.after) || d > 0.002
        case .elevation: return d > 0.01
        }
    }

    /// One to three sentences chosen by the comparison's key: what changed in the settings, then what changed on the
    /// table. Never claims a cause the recordings do not support.
    static func describe(_ c: RetryComparison, previous a: ShotAttempt, current b: ShotAttempt) -> String {
        let near = c.cueBallFinishShift.map { $0 <= RetryComparison.nearSameSpot } ?? false
        let nearSentence = String(localized: "Both tries left the cue ball near the same spot.")
        switch c.key {
        case .exactRepeat:
            return String(localized: "Same shot, same result. The physics is exact, so nothing changes unless you do.")
        case .missedEverything:
            return join([settingsChange(c, a), StrokeWords.comparison(c.stroke),
                         String(localized: "This time the cue ball did not touch any ball.")])
        case .sameSpot:
            let slight = c.inputChanges.count == 1 ? slightly(c.inputChanges[0].control) : nil
            return join([slight, StrokeWords.comparison(c.stroke), nearSentence])
        case .oneChange(let control):
            let said = settingsChange(c, a) ?? slightly(control)
            return join([said, StrokeWords.comparison(c.stroke), outcomeChange(a, b) ?? (near ? nearSentence : nil)])
        case .severalChanges:
            if c.inputChanges.isEmpty {
                // Same settings, different motion: only the stroke can have changed it.
                return join([StrokeWords.comparison(c.stroke)
                                ?? String(localized: "The settings were the same, but the shot did not play out exactly the same."),
                             outcomeChange(a, b)])
            }
            return join([settingsChange(c, a), StrokeWords.comparison(c.stroke),
                         outcomeChange(a, b) ?? (near ? nearSentence : nil),
                         String(localized: "More than one thing changed, so the replay is the place to see which one mattered.")])
        }
    }

    private static func join(_ sentences: [String?]) -> String { sentences.compactMap { $0 }.joined(separator: " ") }

    /// "You hit it harder and raised the cue." for every change big enough to describe; nil when none is.
    private static func settingsChange(_ c: RetryComparison, _ a: ShotAttempt) -> String? {
        var parts: [String] = []
        for change in c.inputChanges where isDescribable(change, in: a) {
            let before = change.before, after = change.after
            switch change.control {
            case .tipUp:
                let up0 = ShotPanel.tipWord(before), up1 = ShotPanel.tipWord(after)
                if up0 != up1 {
                    parts.append(String(localized: "changed the spin from \(spinName(up0)) to \(spinName(up1))"))
                } else {
                    parts.append(after > before ? String(localized: "hit higher on the cue ball") : String(localized: "hit lower on the cue ball"))
                }
            case .tipSide:
                let side0 = ShotPanel.sideWord(before), side1 = ShotPanel.sideWord(after)
                if side0 != side1 {
                    parts.append(side1 == "centre"
                        ? String(localized: "took the side spin off")
                        : String(localized: "put \(ShotPanel.shownWord(side1)) side spin on"))
                } else {
                    parts.append(abs(after) > abs(before)
                        ? String(localized: "moved the tip further to the side")
                        : String(localized: "moved the tip back toward the centre"))
                }
            case .power:
                parts.append(after > before ? String(localized: "hit it harder") : String(localized: "hit it softer"))
            case .aim:
                // A shot's aim is an angle; a break's aim is how far off the apex ball it is aimed. Counter-clockwise on
                // the table plan is to the shooter's left as they look down the cue.
                parts.append(after > before ? String(localized: "aimed a little to the left") : String(localized: "aimed a little to the right"))
            case .elevation:
                parts.append(after > before ? String(localized: "raised the cue") : String(localized: "lowered the cue"))
            }
        }
        guard !parts.isEmpty else { return nil }
        return String(localized: "You \(list(parts)).")
    }

    /// The modest sentence for a change too small to describe in the usual words.
    private static func slightly(_ control: RetryComparison.Control) -> String {
        switch control {
        case .aim: return String(localized: "You moved the aim only slightly.")
        case .power: return String(localized: "You changed the power only slightly.")
        case .tipUp: return String(localized: "You moved the tip only slightly up or down.")
        case .tipSide: return String(localized: "You moved the tip only slightly to the side.")
        case .elevation: return String(localized: "You changed the cue's angle only slightly.")
        }
    }

    private static func outcomeChange(_ a: ShotAttempt, _ b: ShotAttempt) -> String? {
        let before = Set(a.pocketedObjectBalls), after = Set(b.pocketedObjectBalls)
        let gained = after.subtracting(before).sorted(), lost = before.subtracting(after).sorted()
        if !gained.isEmpty || !lost.isEmpty {
            if !gained.isEmpty && lost.isEmpty { return String(localized: "This time \(names(gained)) went in.") }
            if gained.isEmpty {
                let subject = lost.count == 1 ? String(localized: "it") : String(localized: "they")
                return String(localized: "Last time \(names(lost)) went in; this time \(subject) stayed up.")
            }
            return String(localized: "This time \(names(gained)) went in instead of \(names(lost)).")
        }
        if a.cueBallScratched != b.cueBallScratched {
            return b.cueBallScratched
                ? String(localized: "This time the cue ball went in the pocket.")
                : String(localized: "This time the cue ball stayed out of the pocket.")
        }
        let table = b.timeline.table
        let where0 = landmark(a.cueRest, table), where1 = landmark(b.cueRest, table)
        if where0 != where1 {
            return String(localized: "Last time the cue ball stopped \(where0); this time it stopped \(where1).")
        }
        let moved = (b.cueRest - a.cueRest).length
        if moved > RetryComparison.nearSameSpot {
            return String(localized: "The cue ball finished about \(Int((moved * 100).rounded())) centimetres from where it stopped last time.")
        }
        return nil
    }

    /// Where on the table a resting cue ball is, in words a player would use.
    static func landmark(_ p: Vec2, _ t: TableSpec) -> String {
        for (k, pocket) in t.pockets.enumerated() where (p - pocket).length < 0.25 {
            return k < 4 ? String(localized: "near a corner pocket") : String(localized: "near a side pocket")
        }
        let edge = t.ballRadius + 0.06
        if p.x < edge { return String(localized: "on the head cushion") }
        if p.x > t.length - edge { return String(localized: "on the foot cushion") }
        if p.y < edge || p.y > t.width - edge { return String(localized: "on a long cushion") }
        if p.x < t.length / 3 { return String(localized: "in the head end") }
        if p.x > t.length * 2 / 3 { return String(localized: "in the foot end") }
        return String(localized: "in the middle of the table")
    }

    /// The spin word the player sees: "none" for no spin, otherwise the translated tip word.
    private static func spinName(_ word: String) -> String {
        word == "centre" ? String(localized: "none") : ShotPanel.shownWord(word)
    }

    private static func names(_ balls: [Int]) -> String { list(balls.map { String(localized: "the \($0)") }) }

    /// Joins phrases into a list in the player's language. Two items read "A and B"; three or more read "A, B and C".
    private static func list(_ items: [String]) -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0]
        default:
            let head = items.dropLast().joined(separator: ", ")
            return String(localized: "\(head) and \(items.last!)")
        }
    }
}
