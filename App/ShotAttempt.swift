// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// PURPOSE: Try again and compare. One player shot (or the player's own break) recorded as an attempt: where every ball
//          started, the exact settings used, and the recorded timeline it produced. Two attempts from the same start
//          are compared in plain words: what the player changed (spin, side, power, aim) and what happened differently
//          (which balls dropped, where the cue ball finished). Also the ghost paths of an attempt (the cue ball and the
//          first ball it struck), sampled once from the recording, so the faint "last try" lines are a fixed picture
//          that never depends on the playback clock.
//          Everything here is read from recorded timelines and the settings the player chose; nothing is guessed.
// SRP/DRY check: Pass - checked ShowpieceModel (keeps the attempts and the flow), ShotPanel.tipWord/sideWord (reused
//          here for the spin words), CaptionEngine (wording for single events, not for comparisons). This file only
//          describes attempts; the model decides when they are made and the overlay draws them.
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

    /// Object balls (not the cue ball) that dropped during this attempt.
    var pocketedObjectBalls: [Int] {
        (1..<timeline.ballCount).filter { timeline.pocketTime[$0] != nil && NextShot.isOnTable(start[$0]) }
    }
    var cueBallScratched: Bool { timeline.pocketTime[0] != nil }
    /// Where the cue ball came to rest (or where it was taken by a pocket).
    var cueRest: Vec2 { timeline.state(ball: 0, at: timeline.duration).position }

    /// Fingerprint of the motion alone: every ball's segments and every event, but not the shot's serial number
    /// (Timeline.contentHash includes it, and a retry gets a new one). Equal for a retry with identical settings.
    var motionHash: UInt64 {
        var h = StableHasher()
        for ball in timeline.segments {
            h.combine(ball.count)
            for s in ball {
                h.combine(s.t0); h.combine(s.t1); h.combine(Int(s.phase.rawValue))
                h.combine(s.position0); h.combine(s.velocity0); h.combine(s.omega0)
            }
        }
        for e in timeline.events { h.combine(e.time); h.combine(Int(e.kind.rawValue)); h.combine(e.point) }
        return h.value
    }

    /// The first object ball the cue ball touched, if any.
    var firstStruck: Int? {
        for e in timeline.events where e.kind == .ballBall {
            let ids = e.balls.map(\.ball)
            if ids.contains(0) { return ids.first { $0 != 0 } }
        }
        return nil
    }

    // MARK: Ghost paths

    /// The cue ball's path and the first struck ball's path, as table points, sampled once. Sixty samples a second of
    /// recorded time is finer than any curve the cloth can bend a ball through; a ball stops being drawn where a
    /// pocket takes it.
    func ghostPaths() -> (cue: [Vec2], object: [Vec2]) {
        (path(of: 0), firstStruck.map { path(of: $0) } ?? [])
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

// MARK: Comparison

/// The plain-words comparison of a retry with the attempt before it.
enum ShotComparison {
    /// Two sentences at most: what changed in the settings, then what changed on the table.
    static func describe(previous a: ShotAttempt, current b: ShotAttempt) -> String {
        let changed = settingsChange(a, b)
        let outcome = outcomeChange(a, b)
        if changed == nil && outcome == nil {
            return "Same shot, same result. The physics is exact, so nothing changes unless you do."
        }
        return [changed, outcome].compactMap { $0 }.joined(separator: " ")
    }

    private static func settingsChange(_ a: ShotAttempt, _ b: ShotAttempt) -> String? {
        var parts: [String] = []
        let up0 = ShotPanel.tipWord(a.tipUp), up1 = ShotPanel.tipWord(b.tipUp)
        if up0 != up1 {
            parts.append("changed the spin from \(spinName(up0)) to \(spinName(up1))")
        } else if abs(a.tipUp - b.tipUp) > 0.002 {
            parts.append(b.tipUp > a.tipUp ? "hit higher on the cue ball" : "hit lower on the cue ball")
        }
        let side0 = ShotPanel.sideWord(a.tipSide), side1 = ShotPanel.sideWord(b.tipSide)
        if side0 != side1 {
            parts.append(side1 == "centre" ? "took the side spin off" : "put \(side1) side spin on")
        }
        let span = a.powerRange.upperBound - a.powerRange.lowerBound
        if abs(b.power - a.power) > span * 0.04 {
            parts.append(b.power > a.power ? "hit it harder" : "hit it softer")
        }
        // A shot's aim is an angle; a break's aim is how far off the apex ball it is aimed. Counter-clockwise on the
        // table plan is to the shooter's left as they look down the cue.
        let aimStep = a.isBreak ? 0.002 : 0.15
        if abs(b.aim - a.aim) > aimStep {
            parts.append(b.aim > a.aim ? "aimed a little to the left" : "aimed a little to the right")
        }
        guard !parts.isEmpty else { return nil }
        return "You " + list(parts) + "."
    }

    private static func outcomeChange(_ a: ShotAttempt, _ b: ShotAttempt) -> String? {
        let before = Set(a.pocketedObjectBalls), after = Set(b.pocketedObjectBalls)
        let gained = after.subtracting(before).sorted(), lost = before.subtracting(after).sorted()
        if !gained.isEmpty || !lost.isEmpty {
            if !gained.isEmpty && lost.isEmpty { return "This time \(names(gained)) went in." }
            if gained.isEmpty { return "Last time \(names(lost)) went in; this time \(lost.count == 1 ? "it" : "they") stayed up." }
            return "This time \(names(gained)) went in instead of \(names(lost))."
        }
        if a.cueBallScratched != b.cueBallScratched {
            return b.cueBallScratched ? "This time the cue ball went in the pocket." : "This time the cue ball stayed out of the pocket."
        }
        let table = b.timeline.table
        let where0 = landmark(a.cueRest, table), where1 = landmark(b.cueRest, table)
        if where0 != where1 {
            return "Last time the cue ball stopped \(where0); this time it stopped \(where1)."
        }
        let moved = (b.cueRest - a.cueRest).length
        if moved > 0.05 {
            return "The cue ball finished about \(Int((moved * 100).rounded())) centimetres from where it stopped last time."
        }
        return nil
    }

    /// Where on the table a resting cue ball is, in words a player would use.
    static func landmark(_ p: Vec2, _ t: TableSpec) -> String {
        for (k, pocket) in t.pockets.enumerated() where (p - pocket).length < 0.25 {
            return k < 4 ? "near a corner pocket" : "near a side pocket"
        }
        let edge = t.ballRadius + 0.06
        if p.x < edge { return "on the head cushion" }
        if p.x > t.length - edge { return "on the foot cushion" }
        if p.y < edge || p.y > t.width - edge { return "on a long cushion" }
        if p.x < t.length / 3 { return "in the head end" }
        if p.x > t.length * 2 / 3 { return "in the foot end" }
        return "in the middle of the table"
    }

    private static func spinName(_ word: String) -> String { word == "centre" ? "none" : word }

    private static func names(_ balls: [Int]) -> String { list(balls.map { "the \($0)" }) }

    private static func list(_ items: [String]) -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0]
        default: return items.dropLast().joined(separator: ", ") + " and " + items.last!
        }
    }
}
