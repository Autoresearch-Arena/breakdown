// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: How far one ball travelled in a recorded shot, and how it travelled (0.7.7 "Same shot, every surface",
//          plans/23-Nov-2026-every-world-plan.md Build step 1). From a Timeline alone it reports, for one ball:
//            - distance: metres its centre moved across the table plan until it stopped or a pocket took it;
//            - skidding: the part of that distance covered in sliding segments (the ball slipping on the cloth);
//            - airborne: the part covered in the air (a jump);
//            - stopTime: when it last moved (the end of its last moving segment, or its pocket time if earlier);
//            - cushions: how many cushion contacts it made up to its pocket time.
//          Read by WorldContrast (WorldOutcome holds the struck ball's travel), which compares the same stroke on two
//          playing surfaces: "it skids almost all of its 2.1 m", "it travels 6.0 m; here it went 2.1 m", "it keeps
//          moving for 14.2 seconds". Pure and Sendable: built off the main actor by App/EveryWorldFan.swift right after
//          each surface's solve. Nothing here solves or changes a recording.
// SRP/DRY check: Pass - checked ShotFacts (first contact, drops, resting places; it measures no distance),
//          TimelineFork (compares two paths at sampled points; it does not integrate a path's length), ShotFacts.farthestX
//          (the largest x only) and the app's ShotAttempt.path(of:) (samples points to draw). Nothing in the code
//          measured how far a ball travelled or how much of that it skidded before this.
import BreakdownLensModel

public struct BallTravel: Sendable, Equatable {
    /// Metres the ball's centre moved on the table plan until it stopped or a pocket took it.
    public let distance: Double
    /// The part of `distance` covered while sliding (the contact point slipping on the cloth).
    public let skidding: Double
    /// The part of `distance` covered in the air.
    public let airborne: Double
    /// Seconds from the start of the recording to the end of the ball's last moving segment, or to its pocket time if
    /// that came first. Zero for a ball that never moved.
    public let stopTime: Double
    /// Cushion contacts the ball made (any cushion face, jaw, knuckle or post), up to its pocket time.
    public let cushions: Int

    /// The share of the distance covered skidding: 0 for a ball that rolled all the way (or never moved), 1 for one
    /// that slid all the way.
    public var skidShare: Double { distance > 0 ? skidding / distance : 0 }

    /// Slices of composite Simpson's rule per segment. Rolling segments, and sliding ones with no side spin, move in a
    /// straight line with a constant acceleration, so their plan-view speed is linear in time while it lasts, and
    /// Simpson's rule integrates a linear function exactly. A curving slide (side spin bends the path) has a smooth,
    /// slowly turning speed, for which 16 slices is well inside a millimetre on any shot the solver records.
    static let slices = 16

    /// The memberwise form, for hand-made outcomes in the tests.
    public init(distance: Double, skidding: Double, airborne: Double, stopTime: Double, cushions: Int) {
        self.distance = distance; self.skidding = skidding; self.airborne = airborne
        self.stopTime = stopTime; self.cushions = cushions
    }

    /// Reads ball `ball` from a recording. A ball index outside the recording gives all zeros.
    public init(timeline tl: Timeline, ball: Int) {
        guard ball >= 0, ball < tl.ballCount, tl.segments.indices.contains(ball) else {
            self.init(distance: 0, skidding: 0, airborne: 0, stopTime: 0, cushions: 0)
            return
        }
        // Everything stops counting at the pocket (or at the flight off the table, which also sets pocketTime). A ball
        // at rest has a final segment whose end is infinity, so the recording's own end bounds every segment too.
        let end = min(tl.pocketTime[ball] ?? tl.duration, tl.duration)
        var distance = 0.0, skidding = 0.0, airborne = 0.0, stop = 0.0
        for seg in tl.segments[ball] {
            switch seg.phase {
            case .stationary, .spinning:
                // Standing on one spot (spinning in place moves the centre nowhere).
                continue
            case .sliding, .rolling, .airborne:
                let from = seg.t0
                let to = min(seg.t1, end)
                guard to > from, to.isFinite else { continue }
                let length = BallTravel.pathLength(seg, from: from, to: to)
                distance += length
                if seg.phase == .sliding { skidding += length }
                if seg.phase == .airborne { airborne += length }
                stop = max(stop, to)
            }
        }
        var cushions = 0
        for e in tl.events where e.kind == .cushion && e.time <= end && e.balls.map(\.ball).contains(ball) {
            cushions += 1
        }
        self.init(distance: distance, skidding: skidding, airborne: airborne, stopTime: stop, cushions: cushions)
    }

    /// The length of a segment's plan-view path between two times: the integral of |velocity| by composite Simpson's
    /// rule (see `slices`). The airborne phase has a constant horizontal velocity, so it is exact there too.
    static func pathLength(_ seg: BallSegment, from a: Double, to b: Double) -> Double {
        let n = slices
        let h = (b - a) / Double(n)
        func speed(_ t: Double) -> Double { seg.kinematics(at: t).velocity.length }
        var sum = speed(a) + speed(b)
        for i in 1..<n {
            // Odd interior points weigh 4, even ones 2.
            sum += (i % 2 == 1 ? 4 : 2) * speed(a + Double(i) * h)
        }
        return sum * h / 3
    }
}
