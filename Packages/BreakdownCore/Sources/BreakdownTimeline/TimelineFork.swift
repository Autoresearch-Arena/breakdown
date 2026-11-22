// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: Where two futures of one shot part (spec 4.3, the what-if replay; plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          stream whatif item 2). Given the real recording and the recording of a nudged copy of the same shot (same
//          start, same seed), TimelineFork.find reports, from the two recordings alone:
//            - story: the first moment the two stories differ, read ball by ball (each ball's own events in order, with
//              plain phase changes left out and events closer than ShotFacts.sameInstant compared as a set, so two rack
//              hits listed in swapped order are not a difference), the earliest such moment over all balls;
//            - parting: the first point where a ball's other path is more than partingGap (5 mm) from its real path,
//              measured ALONG THE PATHS and not at matching clock times, because a power change keeps the same line at
//              a different pace; found from samples sixty a second and pinned down by bisection on the clock;
//            - departure: at the cue ball's first contact, when both futures hit the same ball first, how the struck
//              ball and the cue ball leave it differently (direction in degrees, anticlockwise positive, and speed);
//            - the distance between the two cue balls at their own first contacts and at rest, the balls whose futures
//              changed (most changed first), and whether the recordings are identical.
//          Pure and Sendable: built off the main actor by App/WhatIfFork.swift right after the solve, and read by the
//          what-if words, the overlay's marker and the scrub bar's diamond. Nothing here solves or changes a recording.
//          Foundation is used only for atan2 (the angles in degrees); this module already links it (Quat.swift).
// SRP/DRY check: Pass - checked ShotFacts (first contact and drops are read through it, not scanned again here),
//          Timeline (state(ball:at:), pocketTime, flewOffTable reused) and the app's ShotAttempt.ghostPaths (samples a
//          single path to draw it; this compares two). No other code compares two recordings of one shot.
import BreakdownLensModel
import Foundation

public struct TimelineFork: Sendable, Equatable {
    /// The first moment the two stories differ. `time` and `point` are the alternate's event when it has one at that
    /// step, else the real one's; `ball` is the ball whose story differed first.
    public struct Moment: Sendable, Equatable {
        public var time: Double
        public var point: Vec2
        public var ball: Int
        public var realEvent: LensEvent?
        public var alternateEvent: LensEvent?
    }

    /// The first place a ball's other path leaves its real path by more than the parting gap.
    public struct Parting: Sendable, Equatable {
        public var ball: Int
        /// The alternate's clock at the parting, and where its ball is then.
        public var time: Double
        public var point: Vec2
        /// The nearest point of the real path, and the real clock there.
        public var realPoint: Vec2
        public var realTime: Double
        /// Unit headings there (zero for a ball at rest).
        public var realHeading: Vec2
        public var alternateHeading: Vec2
    }

    /// How the first contact plays out differently, when both futures hit the same ball first.
    public struct Departure: Sendable, Equatable {
        public var objectBall: Int
        public var strikingBall: Int
        /// The struck ball's outgoing direction, alternate against real, degrees, anticlockwise on the plan positive
        /// (to the shooter's left), and its outgoing speed, alternate minus real, metres per second.
        public var objectTurn: Double
        public var objectSpeedChange: Double
        /// The same for the striking ball.
        public var strikerTurn: Double
        public var strikerSpeedChange: Double
        /// How much further the striking ball is turned away from its own incoming line, alternate minus real, degrees:
        /// positive means it comes off wider.
        public var strikerSpreadChange: Double
    }

    /// Where to mark the parting on the table and the scrub bar, with the two headings for the marker's ticks.
    public struct Marker: Sendable, Equatable {
        public var time: Double
        public var point: Vec2
        public var ball: Int
        public var realHeading: Vec2
        public var alternateHeading: Vec2
    }

    public let story: Moment?
    public let parting: Parting?
    public let departure: Departure?
    /// Metres between the two cue balls, each at its own first contact; nil when either touched nothing.
    public let firstContactGap: Double?
    /// Metres between the two cue balls where they finished (or where a pocket took them).
    public let finishGap: Double
    /// Balls whose futures changed: their paths part, their pocket fate differs, or they rest more than the parting
    /// gap apart. A changed fate comes first, then the furthest apart at rest.
    public let changedBalls: [Int]
    /// The two recordings are the same motion and the same events.
    public let identical: Bool
    /// The story moment when there is one, else the parting point; nil when neither exists.
    public let marker: Marker?

    /// Samples a second along a path for the scan (the plan's rate: finer than any bend the cloth puts in a path).
    public static let scanRate = 60.0
    /// Samples a second of the real path the scan measures against, finer than the scan so the chords of a curving
    /// path lie well inside the gap (at 3 m/s and a half-metre bend, a quarter of a millimetre).
    public static let realPathRate = 240.0

    /// Read the two futures. `start` is the layout both began from, `cueBall` the ball the cue struck, `ballRadius` the
    /// table's ball radius (a ball that never leaves a hundredth of it round its start counts as still, so a rack's
    /// micrometre settling never reads as a change), `partingGap` the distance that counts as parted.
    public static func find(real: Timeline, alternate: Timeline, start: [Vec2], cueBall: Int, ballRadius: Double,
                            partingGap: Double = 0.005) -> TimelineFork {
        let balls = min(real.ballCount, alternate.ballCount)
        let identical = real.segments == alternate.segments && real.events == alternate.events
            && real.pocketTime == alternate.pocketTime
        let realFacts = ShotFacts(timeline: real, start: start, cueBall: cueBall)
        let altFacts = ShotFacts(timeline: alternate, start: start, cueBall: cueBall)
        let departure = Self.departure(real, alternate, realFacts, altFacts, cueBall: cueBall)

        var contactGap: Double?
        if cueBall < balls, let tr = realFacts.firstContactTime, let ta = altFacts.firstContactTime {
            contactGap = (real.state(ball: cueBall, at: tr).position - alternate.state(ball: cueBall, at: ta).position).length
        }
        let finishGap = cueBall < balls
            ? (real.state(ball: cueBall, at: real.duration).position
               - alternate.state(ball: cueBall, at: alternate.duration).position).length
            : 0

        if identical {
            return TimelineFork(story: nil, parting: nil, departure: departure, firstContactGap: contactGap,
                                finishGap: finishGap, changedBalls: [], identical: true, marker: nil)
        }

        let story = Self.story(real, alternate, balls: balls)
        var partings: [Int: Parting] = [:]
        for b in 0..<balls {
            if let p = Self.parting(real, alternate, ball: b, gap: partingGap, still: ballRadius * 0.01) { partings[b] = p }
        }
        let parting = partings.values.min { ($0.time, $0.ball) < ($1.time, $1.ball) }

        // Changed balls: a changed fate first (in or out of a pocket, or off the table), then the furthest apart at rest.
        var changed: [(ball: Int, fate: Bool, rest: Double)] = []
        for b in 0..<balls {
            let fate = realFacts.pocket(of: b) != altFacts.pocket(of: b)
                || (real.pocketTime[b] == nil) != (alternate.pocketTime[b] == nil)
                || real.flewOffTable(b) != alternate.flewOffTable(b)
            let rest = (real.state(ball: b, at: real.duration).position
                        - alternate.state(ball: b, at: alternate.duration).position).length
            if fate || rest > partingGap || partings[b] != nil { changed.append((b, fate, rest)) }
        }
        changed.sort { a, b in a.fate != b.fate ? a.fate : (a.rest != b.rest ? a.rest > b.rest : a.ball < b.ball) }

        var marker: Marker?
        if let s = story {
            marker = Marker(time: s.time, point: s.point, ball: s.ball,
                            realHeading: Self.heading(real, ball: s.ball, at: s.realEvent?.time ?? s.time),
                            alternateHeading: Self.heading(alternate, ball: s.ball, at: s.alternateEvent?.time ?? s.time))
        } else if let p = parting {
            marker = Marker(time: p.time, point: p.point, ball: p.ball, realHeading: p.realHeading,
                            alternateHeading: p.alternateHeading)
        }
        return TimelineFork(story: story, parting: parting, departure: departure, firstContactGap: contactGap,
                            finishGap: finishGap, changedBalls: changed.map(\.ball), identical: false, marker: marker)
    }

    // MARK: The story

    /// What makes two events "the same step of the story": kind, the balls (sorted), the pocket, the cushion part or
    /// the post or pin, and the flight mark. Times, points and speeds are left out: those are what a nudge changes.
    struct StoryKey: Hashable {
        let kind: UInt8
        let balls: [Int]
        let pocket: Int
        let edge: Int
        let feature: Int
        let flight: UInt8

        init(_ e: LensEvent) {
            kind = e.kind.rawValue
            balls = e.balls.map(\.ball).sorted()
            pocket = e.pocket
            edge = e.kind == .cushion ? Int(e.edge.rawValue) : -1
            feature = e.feature
            flight = e.flight.rawValue
        }
    }

    /// One ball's story: its events in order, plain phase changes dropped (a flight mark is kept: leaving the cloth or
    /// the table is part of the story), grouped so events within sameInstant of a group's first are one step.
    static func storySteps(_ tl: Timeline, ball: Int) -> [[LensEvent]] {
        var steps: [[LensEvent]] = []
        for e in tl.events where e.balls.contains(where: { $0.ball == ball }) {
            if e.kind == .phaseTransition && e.flight == .none { continue }
            if let first = steps.last?.first, e.time - first.time < ShotFacts.sameInstant {
                steps[steps.count - 1].append(e)
            } else {
                steps.append([e])
            }
        }
        return steps
    }

    /// Two steps tell the same story when they hold the same keys the same number of times (order inside a step is
    /// not compared: the solver's order for two contacts at one instant is not a fact about the shot).
    static func sameStep(_ a: [LensEvent], _ b: [LensEvent]) -> Bool {
        guard a.count == b.count else { return false }
        var counts: [StoryKey: Int] = [:]
        for e in a { counts[StoryKey(e), default: 0] += 1 }
        for e in b {
            let k = StoryKey(e)
            guard let n = counts[k], n > 0 else { return false }
            counts[k] = n - 1
        }
        return true
    }

    /// The earliest first difference over all balls.
    static func story(_ real: Timeline, _ alternate: Timeline, balls: Int) -> Moment? {
        var best: Moment?
        for b in 0..<balls {
            let r = storySteps(real, ball: b), a = storySteps(alternate, ball: b)
            var i = 0
            while i < max(r.count, a.count) {
                let rs = i < r.count ? r[i] : [], al = i < a.count ? a[i] : []
                if !rs.isEmpty, !al.isEmpty, sameStep(rs, al) { i += 1; continue }
                // The differing event on each side: one whose key the other side's step does not hold, else its first.
                let realKeys = Set(rs.map(StoryKey.init)), altKeys = Set(al.map(StoryKey.init))
                let realEvent = rs.first { !altKeys.contains(StoryKey($0)) } ?? rs.first
                let altEvent = al.first { !realKeys.contains(StoryKey($0)) } ?? al.first
                guard let shown = altEvent ?? realEvent else { break }
                let m = Moment(time: shown.time, point: shown.point, ball: b, realEvent: realEvent,
                               alternateEvent: altEvent)
                if best == nil || m.time < best!.time { best = m }
                break
            }
        }
        return best
    }

    // MARK: The parting, along the paths

    /// A ball's path sampled `rate` times a second, from the start to where it stopped or a pocket took it.
    static func samples(_ tl: Timeline, ball: Int, rate: Double) -> (points: [Vec2], times: [Double]) {
        let end = tl.pocketTime[ball] ?? tl.duration
        let n = max(1, Int((end * rate).rounded(.up)))
        var pts: [Vec2] = [], times: [Double] = []
        pts.reserveCapacity(n + 1); times.reserveCapacity(n + 1)
        for i in 0...n {
            let t = end * Double(i) / Double(n)
            pts.append(tl.state(ball: ball, at: t).position)
            times.append(t)
        }
        return (pts, times)
    }

    /// The nearest point of polyline `pts` to `p`: the distance, the segment index and how far along it (0 to 1).
    static func nearest(_ p: Vec2, _ pts: [Vec2]) -> (distance: Double, index: Int, fraction: Double) {
        guard pts.count > 1 else { return ((p - (pts.first ?? p)).length, 0, 0) }
        var best = (distance: Double.infinity, index: 0, fraction: 0.0)
        for i in 0..<(pts.count - 1) {
            let (d, f) = segmentDistance(p, pts[i], pts[i + 1])
            if d < best.distance { best = (d, i, f) }
        }
        return best
    }

    /// Distance from `p` to the segment a-b, and how far along it the nearest point is (0 to 1).
    static func segmentDistance(_ p: Vec2, _ a: Vec2, _ b: Vec2) -> (Double, Double) {
        let ab = b - a
        let len2 = ab.lengthSquared
        let f = len2 > 1e-24 ? min(1, max(0, (p - a).dot(ab) / len2)) : 0
        return ((p - (a + ab * f)).length, f)
    }

    /// True when `p` lies within `gap` of the polyline. Searched outward from `hint` (the segment last found near), so a
    /// path that follows the real one costs a few segments per sample; `hint` moves to the segment found.
    static func within(_ p: Vec2, _ pts: [Vec2], gap: Double, hint: inout Int) -> Bool {
        guard pts.count > 1 else { return (p - (pts.first ?? p)).length <= gap }
        let last = pts.count - 2
        let h = min(max(hint, 0), last)
        var k = 0
        while h - k >= 0 || h + k <= last {
            for i in (k == 0 ? [h] : [h + k, h - k]) where i >= 0 && i <= last {
                if segmentDistance(p, pts[i], pts[i + 1]).0 <= gap { hint = i; return true }
            }
            k += 1
        }
        return false
    }

    /// True when the ball's path never leaves a circle of radius `still` round its start.
    static func isStill(_ pts: [Vec2], still: Double) -> Bool {
        guard let first = pts.first else { return true }
        return pts.allSatisfy { ($0 - first).length <= still }
    }

    /// The first point of ball `b`'s alternate path more than `gap` from its real path, or nil when it never leaves it.
    static func parting(_ real: Timeline, _ alternate: Timeline, ball b: Int, gap: Double, still: Double) -> Parting? {
        let r = samples(real, ball: b, rate: realPathRate)
        let a = samples(alternate, ball: b, rate: scanRate)
        if isStill(r.points, still: still) && isStill(a.points, still: still) { return nil }
        var hint = 0
        for j in a.points.indices where !within(a.points[j], r.points, gap: gap, hint: &hint) {
            // Pinned down by bisection on the alternate's clock between the last sample on the path and this one. The
            // distance is continuous in time, so the end it settles on sits at the gap to well under a micrometre.
            var lo = j > 0 ? a.times[j - 1] : 0, hi = a.times[j]
            for _ in 0..<48 {
                let mid = 0.5 * (lo + hi)
                if nearest(alternate.state(ball: b, at: mid).position, r.points).distance > gap { hi = mid } else { lo = mid }
            }
            let point = alternate.state(ball: b, at: hi).position
            let n = nearest(point, r.points)
            let i = n.index, i1 = min(i + 1, r.points.count - 1)
            let realPoint = r.points[i] + (r.points[i1] - r.points[i]) * n.fraction
            let realTime = r.times[i] + (r.times[i1] - r.times[i]) * n.fraction
            var altHeading = alternate.state(ball: b, at: hi).velocity.normalized
            if altHeading == .zero, j > 0 { altHeading = (point - a.points[j - 1]).normalized }
            return Parting(ball: b, time: hi, point: point, realPoint: realPoint, realTime: realTime,
                           realHeading: pathHeading(r.points, at: i), alternateHeading: altHeading)
        }
        return nil
    }

    /// The direction of a polyline at segment `i`, looking forward then back past any segment of zero length.
    static func pathHeading(_ pts: [Vec2], at i: Int) -> Vec2 {
        guard pts.count > 1 else { return .zero }
        for k in i..<(pts.count - 1) {
            let d = pts[k + 1] - pts[k]
            if d.lengthSquared > 1e-18 { return d.normalized }
        }
        for k in stride(from: min(i, pts.count - 2), through: 0, by: -1) {
            let d = pts[k + 1] - pts[k]
            if d.lengthSquared > 1e-18 { return d.normalized }
        }
        return .zero
    }

    /// A ball's heading just after `t` (the segment starting at an event is the one after it), or just before when it
    /// is at rest after.
    static func heading(_ tl: Timeline, ball: Int, at t: Double) -> Vec2 {
        guard ball < tl.ballCount else { return .zero }
        let after = tl.state(ball: ball, at: t).velocity
        if after.lengthSquared > 1e-12 { return after.normalized }
        return tl.state(ball: ball, at: max(0, t - 1e-3)).velocity.normalized
    }

    // MARK: The departure at the first contact

    /// Signed angle from `a` to `b`, degrees, anticlockwise positive; 0 when either is (nearly) zero.
    static func turn(from a: Vec2, to b: Vec2) -> Double {
        guard a.lengthSquared > 1e-12, b.lengthSquared > 1e-12 else { return 0 }
        let cross = a.x * b.y - a.y * b.x
        return atan2(cross, a.dot(b)) * 180 / Double.pi
    }

    static func departure(_ real: Timeline, _ alternate: Timeline, _ rf: ShotFacts, _ af: ShotFacts,
                          cueBall: Int) -> Departure? {
        guard let rc = rf.firstContact, let ac = af.firstContact, rc.ball == ac.ball,
              let re = contactEvent(real, at: rc.time, cueBall, rc.ball),
              let ae = contactEvent(alternate, at: ac.time, cueBall, ac.ball),
              let rObj = re.balls.first(where: { $0.ball == rc.ball }), let aObj = ae.balls.first(where: { $0.ball == rc.ball }),
              let rCue = re.balls.first(where: { $0.ball == cueBall }), let aCue = ae.balls.first(where: { $0.ball == cueBall })
        else { return nil }
        let realSpread = abs(turn(from: rCue.velocityBefore, to: rCue.velocityAfter))
        let altSpread = abs(turn(from: aCue.velocityBefore, to: aCue.velocityAfter))
        return Departure(objectBall: rc.ball, strikingBall: cueBall,
                         objectTurn: turn(from: rObj.velocityAfter, to: aObj.velocityAfter),
                         objectSpeedChange: aObj.velocityAfter.length - rObj.velocityAfter.length,
                         strikerTurn: turn(from: rCue.velocityAfter, to: aCue.velocityAfter),
                         strikerSpeedChange: aCue.velocityAfter.length - rCue.velocityAfter.length,
                         strikerSpreadChange: altSpread - realSpread)
    }

    /// The ball-to-ball event at the cue ball's first contact with `object`.
    static func contactEvent(_ tl: Timeline, at t: Double, _ cueBall: Int, _ object: Int) -> LensEvent? {
        tl.events.first { e in
            e.kind == .ballBall && abs(e.time - t) <= ShotFacts.sameInstant
                && e.balls.contains { $0.ball == cueBall } && e.balls.contains { $0.ball == object }
        }
    }
}
