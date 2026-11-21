// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (TableSpec carries the pocket jaws, so the drawn table and the Lens use the solver's own geometry).
// Edited: Claude Opus 5.5 High, 20-November-2026 (jump shots: BallState carries the ball's height above the cloth;
//          contentHash folds in the height terms of airborne segments and the flight fields of flight events only, so
//          every recording without a jump hashes bit for bit as before; flewOffTable says which balls left the table.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (other tables: TableSpec also carries the posts, pins and bed holes
//          and whether the six edge pockets exist, so the app draws exactly what the solver used; edge pockets keep
//          indices 0 to 5 and bed hole j is pocket 6 + j whether or not the edge pockets exist (holeCenter(pocket:)
//          finds either). The Timeline lists the pins knocked down (pinFalls, pinDownTime) from the pinDown events, so
//          the app can topple them as a pure function of the clock. contentHash folds an event's feature index only
//          where one is set, so every recording without posts or pins hashes exactly as before.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (contentHash folds the new generation-two event fields (pocket entry,
//          miscue, deflection, bed impulse, energy removed) only where they are set, each behind its own marker, so
//          every recording without them hashes exactly as before.)
// PURPOSE: The recorded shot. Holds every ball's segments, the Lens events, the table description, and a
//          content hash for replay equality. Playback, slow motion, scrubbing, the Lens and sound all read
//          this and never re-simulate. Doubles are hashed by bit pattern.
// SRP/DRY check: Pass - storage and lookup only; the solver produces it, nothing else mutates it.
import BreakdownLensModel

/// One pocket jaw: the straight cushion face that runs from a knuckle (where the cushion nose turns into the pocket)
/// back into the pocket. `start` is the knuckle on the cushion nose line, `end` is where the face meets the pocket
/// hole. Table metres. The playing side of the face is the side the pocket's mouth is on.
public struct JawSpec: Sendable, Equatable {
    public var pocket: Int
    public var start: Vec2
    public var end: Vec2
    public init(pocket: Int, start: Vec2, end: Vec2) { self.pocket = pocket; self.start = start; self.end = end }
}

public struct TableSpec: Sendable, Equatable {
    /// How many edge pockets a pocketed table has (four corners, two sides). Bed hole j is pocket edgePocketCount + j.
    public static let edgePocketCount = 6

    public var length: Double
    public var width: Double
    public var ballRadius: Double
    /// Centre of each edge pocket's hole, corners then sides, and the radius a ball's centre must reach to drop.
    /// Empty when the table has no edge pockets (pocketsEnabled false).
    public var pockets: [Vec2]
    public var pocketCaptureRadius: [Double]
    /// Two jaws per pocket, in pocket order. Empty for tables recorded before pockets had jaws, and with no pockets.
    public var jaws: [JawSpec]
    /// False for a table with no edge pockets (five-pin): the cushions run the full length of every side.
    public var pocketsEnabled: Bool
    /// Fixed round posts, standing pins and holes in the bed (see TableFeatures.swift). Empty on a pool table.
    public var posts: [Post]
    public var pins: [Pin]
    public var bedHoles: [BedHole]
    public init(length: Double, width: Double, ballRadius: Double, pockets: [Vec2], pocketCaptureRadius: [Double],
                jaws: [JawSpec] = [], pocketsEnabled: Bool = true, posts: [Post] = [], pins: [Pin] = [],
                bedHoles: [BedHole] = []) {
        self.length = length; self.width = width; self.ballRadius = ballRadius
        self.pockets = pockets; self.pocketCaptureRadius = pocketCaptureRadius; self.jaws = jaws
        self.pocketsEnabled = pocketsEnabled; self.posts = posts; self.pins = pins; self.bedHoles = bedHoles
    }

    /// Centre of the hole a pocket event names: an edge pocket (0 to 5) or a bed hole (6 and up). Nil if no such hole.
    public func holeCenter(pocket k: Int) -> Vec2? {
        if k >= 0 && k < TableSpec.edgePocketCount { return pocketsEnabled && k < pockets.count ? pockets[k] : nil }
        let j = k - TableSpec.edgePocketCount
        return j >= 0 && j < bedHoles.count ? bedHoles[j].center : nil
    }
}

public struct BallState: Sendable, Equatable {
    public var position: Vec2
    public var velocity: Vec2
    public var omega: Vec3
    public var orientation: Quat
    public var phase: MotionPhase
    /// True from the moment the ball is captured by a pocket (or flies off the table: see flewOffTable).
    public var pocketed: Bool
    /// Height of the ball's lowest point above the cloth, metres (the centre is one radius above that). Zero on the
    /// cloth; positive during a jump.
    public var height: Double = 0
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
    /// Every pin knocked down in this shot, in time order (from the pinDown events). Empty without pins.
    public let pinFalls: [PinFall]
    /// Per pin in table.pins: when it was knocked down, nil if it stood all shot.
    public let pinDownTime: [Double?]

    public init(table: TableSpec, seed: UInt64, parameterHash: UInt64, segments: [[BallSegment]],
                events: [LensEvent], pocketTime: [Double?], duration: Double) {
        self.table = table; self.seed = seed; self.parameterHash = parameterHash
        self.ballCount = segments.count
        self.segments = segments; self.events = events; self.pocketTime = pocketTime; self.duration = duration
        var falls: [PinFall] = []
        var down = [Double?](repeating: nil, count: table.pins.count)
        for e in events where e.kind == .pinDown {
            guard let b = e.balls.first else { continue }
            falls.append(PinFall(pin: e.feature, time: e.time, ball: b.ball, direction: e.normal))
            if down.indices.contains(e.feature), down[e.feature] == nil { down[e.feature] = e.time }
        }
        pinFalls = falls
        pinDownTime = down
    }

    /// True once pin `pin` has been knocked down at clock time `t` (from its exact recorded time on).
    public func pinIsDown(_ pin: Int, at t: Double) -> Bool {
        guard pinDownTime.indices.contains(pin), let d = pinDownTime[pin] else { return false }
        return t >= d
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
                         orientation: seg.orientation(at: evalT), phase: seg.phase, pocketed: isPocketed,
                         height: k.height)
    }

    /// True when the ball left the table by flying over a cushion (it then counts as off the table, like a pocketed
    /// ball, but no pocket took it).
    public func flewOffTable(_ ball: Int) -> Bool {
        events.contains { $0.flight == .offTable && $0.balls.first?.ball == ball }
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
                // Height terms only where they can be non-zero, so a recording with no jump hashes exactly as before.
                if s.phase == .airborne || s.height0 != 0 {
                    h.combine(s.height0); h.combine(s.verticalVelocity0); h.combine(s.verticalAcceleration)
                }
            }
        }
        for e in events {
            h.combine(e.time); h.combine(Int(e.kind.rawValue)); h.combine(e.point); h.combine(e.normalImpulse)
            h.combine(e.balls.count)
            // Post and pin indices only where set (-1 elsewhere), so older recordings hash bit for bit as before.
            if e.feature >= 0 { h.combine(e.feature) }
            if e.flight != .none {
                h.combine(Int(e.flight.rawValue)); h.combine(e.verticalSpeedDown); h.combine(e.verticalSpeedUp)
                h.combine(e.height)
            }
            // Generation-two fields, each only where set and behind its own marker (all nil at generation 1 and on
            // older recordings, which therefore hash exactly as before).
            if let en = e.entry {
                h.combine(UInt64(0x454E_5452))   // "ENTR"
                h.combine(en.speed); h.combine(en.sine); h.combine(en.cosine)
            }
            if let m = e.miscue { h.combine(UInt64(0x4D49_5343)); h.combine(m ? 1 : 0) }        // "MISC"
            if let s = e.deflectionSine { h.combine(UInt64(0x4445_464C)); h.combine(s) }      // "DEFL"
            if let b = e.bedImpulse { h.combine(UInt64(0x4245_4449)); h.combine(b) }          // "BEDI"
            if let x = e.energyRemoved { h.combine(UInt64(0x4A41_4D53)); h.combine(x) }       // "JAMS"
        }
        return h.value
    }
}
