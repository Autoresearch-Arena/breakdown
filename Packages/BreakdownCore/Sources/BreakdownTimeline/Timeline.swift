// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: The recorded shot. Holds every ball's segments, the Lens events, the table description, and a
//          content hash for replay equality. Playback, slow motion, scrubbing, the Lens and sound all read
//          this and never re-simulate. Doubles are hashed by bit pattern.
// SRP/DRY check: Pass - storage and lookup only; the solver produces it, nothing else mutates it.
import BreakdownLensModel

public struct TableSpec: Sendable, Equatable {
    public var length: Double
    public var width: Double
    public var ballRadius: Double
    public var pockets: [Vec2]
    public var pocketCaptureRadius: [Double]
    public init(length: Double, width: Double, ballRadius: Double, pockets: [Vec2], pocketCaptureRadius: [Double]) {
        self.length = length; self.width = width; self.ballRadius = ballRadius
        self.pockets = pockets; self.pocketCaptureRadius = pocketCaptureRadius
    }
}

public struct BallState: Sendable, Equatable {
    public var position: Vec2
    public var velocity: Vec2
    public var omega: Vec3
    public var orientation: Quat
    public var phase: MotionPhase
    /// True from the moment the ball is captured by a pocket.
    public var pocketed: Bool
}

public struct Timeline: Sendable {
    public let table: TableSpec
    public let seed: UInt64
    public let parameterHash: UInt64
    public let ballCount: Int
    /// Per ball, contiguous segments sorted by time.
    public let segments: [[BallSegment]]
    public let events: [LensEvent]
    /// Pocket capture time per ball, nil if never pocketed.
    public let pocketTime: [Double?]
    /// Time of the last event; after this nothing moves.
    public let duration: Double

    public init(table: TableSpec, seed: UInt64, parameterHash: UInt64, segments: [[BallSegment]],
                events: [LensEvent], pocketTime: [Double?], duration: Double) {
        self.table = table; self.seed = seed; self.parameterHash = parameterHash
        self.ballCount = segments.count
        self.segments = segments; self.events = events; self.pocketTime = pocketTime; self.duration = duration
    }

    public func segmentIndex(ball: Int, at t: Double) -> Int {
        let segs = segments[ball]
        var lo = 0, hi = segs.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if segs[mid].t0 <= t { lo = mid } else { hi = mid - 1 }
        }
        return lo
    }

    public func state(ball: Int, at time: Double) -> BallState {
        let t = time < 0 ? 0 : time
        let segs = segments[ball]
        let isPocketed = pocketTime[ball].map { t >= $0 } ?? false
        let seg = segs[segmentIndex(ball: ball, at: isPocketed ? pocketTime[ball]! : t)]
        let evalT = isPocketed ? pocketTime[ball]! : t
        let k = seg.kinematics(at: evalT)
        return BallState(position: k.position, velocity: isPocketed ? .zero : k.velocity, omega: k.omega,
                         orientation: seg.orientation(at: evalT), phase: seg.phase, pocketed: isPocketed)
    }

    /// Hash of everything that defines the shot's outcome.
    public var contentHash: UInt64 {
        var h = StableHasher()
        h.combine(parameterHash)
        h.combine(seed)
        for ball in segments {
            h.combine(ball.count)
            for s in ball {
                h.combine(s.t0); h.combine(s.t1)
                h.combine(Int(s.phase.rawValue))
                h.combine(s.position0); h.combine(s.velocity0); h.combine(s.acceleration)
                h.combine(s.omega0); h.combine(s.alphaXY); h.combine(s.spinDecay)
            }
        }
        for e in events {
            h.combine(e.time); h.combine(Int(e.kind.rawValue)); h.combine(e.point); h.combine(e.normalImpulse)
            h.combine(e.balls.count)
        }
        return h.value
    }
}
