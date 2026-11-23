// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (a chase view of the cue ball for the whole shot, as the Boss asked:
//          higher and further back, no hand-over to the struck ball, a crane up after the first contact).
// Edited: Claude Opus 5.5 High, 21-November-2026 (release stream: selfTest also returns what it measured as a RideCheck,
//          so the app's unit tests assert on the same check the -rideSelfTest flag logs; the check itself is unchanged).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 foundation: RidePlan takes the struck ball, cueBall, so the
//          ride can follow whichever ball the player strikes; the ride itself still reads ball 0 until stream camera).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream camera, plans/22-Nov-2026-phone-bug-hunt.md #18-#21:
//          the blend between the table camera and the ride turns the view by its heading and tilt instead of mixing
//          look directions, so it never passes through straight down and never flips (#18); every new shot and every
//          Replay eases into the ride, not only the first (#19); upright, the ride lens is about 64 degrees across and
//          the ridden ball sits in the lower third of the free space (#20); the plan, the headings and the pose follow
//          the struck ball (RidePlan.cueBall) instead of ball 0 (#21).)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream ride, plans/22-Nov-2026-ride-handover-plan.md: the
//          camera follows the ride's acts (RideCue, set by TableScene from the model). Mount: the overhead view turns
//          about the struck ball, the ball pinned on screen, into the chase view (mountPose, an orbit in heading, tilt
//          and distance eased separately, the shortest way round). Roll and hold: the chase view at full weight, the
//          crane now finishing as the clock reaches the first contact, so the held hit is seen from above both balls
//          and Continue plays on without the crane jumping. Dismount: the rise to the overhead view by the act's own
//          progress, the clock held. Landed: the overhead view. Reduce Motion: each act cuts. RidePlan.firstStruck
//          names the first ball hit (the rings and the map). selfTest also checks the mount and the dismount: no turn
//          faster than the ride's limit and the ball pinned during the orbit (RideCheck's new fields).)
// PURPOSE: Ride the shot: a chase view of the cue ball. When Ride is on, the camera sits behind and above the cue
//          ball, looks the way it is travelling and follows it for the whole shot (it never hands over to the ball it
//          hits). After the first contact it cranes up and back so the rack opening, or the struck ball's run to its
//          pocket, is in view; it keeps looking the way the cue ball came unless the cue ball travels on. Once the cue
//          ball and the ball it hit have finished their runs it rises to the normal overhead table. With
//          the Lens on, the same ride happens over the Lens, so the trails and the grid are seen from behind the cue ball.
//          Everything about the ride is a pure function of the playback clock and the recorded timeline: there is no
//          frame-to-frame camera state, so scrubbing either way shows the same camera for the same time. Direction is
//          read from a look-ahead along the recorded path, smoothed by a critically damped kernel over that path, so it
//          turns smoothly through a cushion bounce instead of snapping when the velocity flips. The crane after the
//          contact and the rise at the end are critically damped blends computed from event times.
//          The one piece of wall-clock state is `engage`: switching Ride on or off mid-shot eases in over half a
//          second instead of jumping (under Reduce Motion it cuts), and since 0.7.6 so does every new shot and every
//          Replay (engage goes back to 0 on load and when the clock jumps back to the start).
//          Reduce Motion: no ride. The camera holds one still low angle behind the cue ball where it starts, then cuts
//          to the overhead at the first contact.
//          Also here: the slow-motion curve Ride adds around the first contact (RidePlan.rateFactor, read by
//          ShowpieceModel; also a pure function of the clock), the -rideDemo straight pot (RideDemo), and the
//          -rideSelfTest scrub-exactness and smoothness check (ShotCamera.selfTest, run by TableScene).
//          Integration: TableScene owns one ShotCamera, loads it with each new timeline and sets `clock` and `active`
//          every frame; TableCamera.update calls `override(...)` with its normal overhead pose and uses what comes back
//          (position, look target, field of view, near plane). Trig and exp live here in the app; the physics package
//          is only read.
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 clips, plans/23-Nov-2026-clips-plan.md: the Ride engage's wall-clock read goes through SceneClock.now, so the clip's offscreen table eases on the clip's own clock; the live game is unchanged.)
// SRP/DRY check: Pass - the ride camera only. Checked TableCamera (overhead framing, push-in), CameraFraming (framing
//          maths), TableFrame (table-to-world conversion, reused here) and PacePlan (the guided replay's own
//          slow motion, left untouched); none of them follow a ball.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import CoreGraphics
import Foundation
import simd

// MARK: The plan: what to ride, worked out once per recorded shot

/// The key moments of one recorded shot, read once from its events and segments (never per frame).
struct RidePlan: Equatable {
    /// False when there is nothing worth riding (a still table, a shot shorter than the rise).
    var rideable = false
    /// Clock time the cue ball first touches an object ball; nil when it hits none.
    var contactTime: Double?
    /// The first ball the struck ball hits, whatever it does afterwards (the ride's rings and map); nil when it hits none.
    var firstStruck: Int?
    /// The struck ball the ride hands over to; nil when there is no hand-off (no contact, or the struck ball barely
    /// moves, as the apex ball of a break does: then the camera holds behind the cue ball and watches the rack open).
    var objectBall: Int?
    /// The clock span each ball is ridden over: the cue ball until contact (or until it stops), the struck ball from
    /// contact until it stops or drops. Samples outside these spans are clamped into them.
    var cueSpan: ClosedRange<Double> = 0...0
    /// The span the cue ball's heading is read over: all of cueSpan when the cue ball travels on after the contact,
    /// otherwise only up to the contact (see init).
    var headingSpan: ClosedRange<Double> = 0...0
    var objectSpan: ClosedRange<Double> = 0...0
    /// When the rise to the overhead view starts, and how long it takes (it always finishes by the end of the shot,
    /// so the balls the next shot starts from are seen from the normal camera).
    var riseStart = 0.0
    var riseLength = 1.0
    /// Where the cue ball starts and the way it is struck, for the still Reduce Motion view and as a last fallback.
    var cueStart = Vec2.zero
    var strikeDirection = Vec2(1, 0)

    static let none = RidePlan()

    init() {}

    /// The ball the player struck (ball 0 on the pool tables; another ball at bumper pool, bar billiards and five-pin's
    /// second seat). The ride follows this ball.
    var cueBall = 0

    init(_ tl: Timeline, cueBall: Int = 0) {
        self.cueBall = cueBall
        guard tl.ballCount > 0, cueBall >= 0, cueBall < tl.ballCount, tl.duration > 0.3 else { return }
        let duration = tl.duration
        // `cue` is the struck ball throughout (0.7.6 #21): ball 0 on the pool tables, another ball at bumper pool, bar
        // billiards and five-pin's second seat.
        let cue = cueBall
        cueStart = tl.state(ball: cue, at: 0).position
        let v0 = tl.state(ball: cue, at: 0).velocity
        if v0.length > 1e-6 { strikeDirection = v0.normalized }
        // Nothing to ride without a real strike (a re-rack records a still table).
        guard v0.length > 0.05 else { return }
        let cueStop = Self.travelEnd(tl, ball: cue)

        // First ball-ball event that involves the cue ball: the contact time and the struck ball.
        let first = tl.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == cue } }
        contactTime = first?.time
        let struck = first?.balls.first { $0.ball != cue }?.ball
        firstStruck = struck
        // The camera stays with the cue ball the whole way (the Boss: "you want to be the cue ball"), so its place is
        // followed until it stops or drops.
        cueSpan = 0...max(Self.window, cueStop)
        // Its heading only follows the cue ball after the contact when the cue ball really goes somewhere afterwards.
        // A cue ball that stops dead or sits in the middle of a break keeps looking the way it came, at the balls it
        // sent off, instead of swinging round to stare at the rail behind it.
        if let c = contactTime {
            let after = (tl.state(ball: cue, at: cueStop).position - tl.state(ball: cue, at: c).position).length
            headingSpan = after > Self.followOn ? cueSpan : 0...max(Self.window, c)
        } else {
            headingSpan = cueSpan
        }

        // Stay low until the cue ball and the ball it hit have both finished their runs, so the camera watches the
        // struck ball roll away (and drop) from behind the cue ball. Never for more than a few seconds after contact.
        var rideEnd = tl.pocketTime[cue] != nil ? cueStop + 0.35 : cueStop + 0.2
        if let c = contactTime {
            if let b = struck {
                let end = Self.travelEnd(tl, ball: b)
                let travel = (tl.state(ball: b, at: end).position - tl.state(ball: b, at: c).position).length
                if travel > 0.15, end - c > Self.window {
                    objectBall = b
                    objectSpan = c...end
                    rideEnd = max(rideEnd, tl.pocketTime[b] != nil ? end + 0.35 : end + 0.2)
                }
            }
            // A break: the apex ball barely moves but the whole rack opens; watch it spread for a moment.
            rideEnd = min(max(rideEnd, c + 1.2), c + Self.longestRide)
        } else {
            rideEnd = min(rideEnd, Self.longestRide)
        }
        riseLength = min(1.2, duration * 0.5)
        riseStart = min(max(0, rideEnd), duration - riseLength)
        rideable = true
    }

    /// Length of the short span of path each direction sample measures (seconds, centred on the sample).
    static let window = 0.08
    /// The longest the camera stays low after the contact (or after the strike when nothing is hit), in clock seconds.
    static let longestRide = 3.0
    /// How far (metres) the cue ball must travel after the contact before the camera turns to follow its new way.
    static let followOn = 0.3

    /// When a ball stops travelling across the cloth: its pocket time, or the start of the first segment after which
    /// it only spins in place or rests.
    private static func travelEnd(_ tl: Timeline, ball b: Int) -> Double {
        let segs = tl.segments[b]
        var end = 0.0
        for (i, s) in segs.enumerated() where s.phase == .sliding || s.phase == .rolling {
            end = i + 1 < segs.count ? segs[i + 1].t0 : min(s.t1, tl.duration)
        }
        if let p = tl.pocketTime[b] { end = min(end, p) }
        return min(end, tl.duration)
    }

    // MARK: Slow motion around the first contact

    /// Playback speed multiplier while Ride is on: eases down to about a fifth of the chosen speed just before the
    /// cue ball reaches its first ball, holds through the contact, and eases back over half a second. A pure function
    /// of the clock, so it never depends on how playback got there.
    func rateFactor(at t: Double) -> Double {
        guard rideable, let c = contactTime else { return 1 }
        let easeIn = Self.smooth((t - (c - 0.22)) / 0.19)
        let easeOut = 1 - Self.smooth((t - (c + 0.10)) / 0.45)
        let slow = min(easeIn, easeOut)
        return 1 - (1 - Self.slowest) * slow
    }

    /// The slowest Ride plays the contact, as a fraction of the chosen speed.
    static let slowest = 0.22

    static func smooth(_ x: Double) -> Double { let c = min(1, max(0, x)); return c * c * (3 - 2 * c) }

    /// A critically damped step that starts at τ = 0 with zero slope and is scaled to land exactly on 1 at τ = length
    /// (a true critically damped response only approaches 1; the last one per cent is folded in so the blend ends).
    static func damped(_ tau: Double, length: Double) -> Double {
        guard tau > 0 else { return 0 }
        guard tau < length else { return 1 }
        let w = 6 / length                         // six time constants: 98 per cent of the way there at `length`
        func cd(_ x: Double) -> Double { 1 - (1 + w * x) * exp(-w * x) }
        return min(1, cd(tau) / cd(length))
    }
}

// MARK: The camera

/// What TableCamera applies: where the camera is, a point it looks at, its vertical field of view and near plane.
struct CameraShot {
    var position: SIMD3<Float>
    var target: SIMD3<Float>
    var fov: Float
    var near: Float
}

@MainActor
final class ShotCamera {
    /// The plan for the loaded timeline (also handy for anything that wants the contact time).
    private(set) var plan = RidePlan.none
    /// Smoothed headings of the ridden balls, worked out once per shot from the recording.
    private var tracks: RideTracks?
    private var timeline: Timeline?
    private var frame: TableFrame?
    /// The playback clock for this frame, set by TableScene before the camera update.
    var clock = 0.0
    /// True when the model says Ride is on and playback is a replay the ride may take over.
    var active = false
    /// 0 to 1: how far Ride is switched in, eased in wall time so a mid-shot toggle does not jump. Back to 0 whenever a
    /// new shot is loaded or the clock jumps back to the start (a Replay), so every ride eases in (0.7.6 #19).
    private var engage = 0.0
    private var lastTick: TimeInterval?
    /// The clock the last override saw, to notice a jump back to the start.
    private var lastClock = 0.0
    /// True when the last override gave the ride pose any say over the view (not when Ride is merely on: between
    /// shots, while the player aims, the ride has risen and the view is the ordinary table). The hand zoom waits only
    /// while this is true (TableZoom.rideHold, bug #24).
    private(set) var flying = false

    /// Near plane while riding: the eye is about half a metre from the ball it chases, so two centimetres clears
    /// everything near it while keeping good depth precision on the cloth and rails.
    static let rideNear: Float = 0.02
    static let overheadNear: Float = 0.05
    /// The chase view: the eye sits well above the rail tops (7.5 cm) and about a dozen ball widths behind the cue ball,
    /// so the cue ball reads as a ball in the lower part of the screen with the balls it is heading for in view
    /// beyond it, and the camera can see over a whole rack as it opens. The first ride sat a ball width behind at
    /// rail height: the cue ball filled half the screen and the rack was a wall (the Boss found it "a weird view").
    static let eyeHeight: Float = 0.42
    static let back: Float = 0.62
    /// Where the camera cranes to after the first contact, and how long that takes (clock seconds).
    static let craneHeight: Float = 0.85
    static let craneBack: Float = 0.95
    static let craneTime = 0.45
    /// Where the ridden ball sits in the free space, as a share of its height from the top (0.7.6 #20): in the lower
    /// third, so the balls it is heading for have the room above it, but clear of the cards' edge below.
    static let ballPlace = 0.72

    /// - cueBall: the ball the player struck (the model's RidePlan.cueBall); the ride follows it (0.7.6 #21).
    func load(_ tl: Timeline, frame: TableFrame, cueBall: Int = 0) {
        timeline = tl
        self.frame = frame
        plan = RidePlan(tl, cueBall: cueBall)
        tracks = plan.rideable ? RideTracks(tl, plan: plan) : nil
        // Every new shot eases into the ride from the table view (0.7.6 #19): with Ride left on, engage sat at 1
        // between shots and the strike cut straight into the chase view.
        engage = 0
    }

    /// TableCamera's hook. Takes the normal overhead camera and returns the one to use this frame: unchanged when
    /// Ride is off (or fully risen), the ride pose when riding, and a blend while handing over.
    func override(position: SIMD3<Float>, target: SIMD3<Float>, fov: Float, free: FramingRect, size: CGSize,
                  reduceMotion: Bool) -> CameraShot {
        let overhead = CameraShot(position: position, target: target, fov: fov, near: Self.overheadNear)
        // A Replay (the clock jumped back to the start) eases in again too (0.7.6 #19). Kept out of ridePose, which
        // stays a pure function of the clock.
        if clock < 0.05, lastClock > 0.3 { engage = 0 }
        lastClock = clock
        // Switching in and out: half a second of wall time, or a cut under Reduce Motion.
        let now = SceneClock.now  // 0.7.7 clips: scene clock
        let dt = min(0.1, max(0, now - (lastTick ?? now)))
        lastTick = now
        let goal = active && plan.rideable ? 1.0 : 0.0
        // The mount is itself the way into the ride (0.7.6 stream ride): it starts from the overhead view, so the
        // wall-clock ease is not stacked on top of it. One owner for the start of a shot: the mount when the model
        // runs the acts, the half-second engage otherwise (Ride switched on mid-shot, the opening's slow replay).
        let act = cue?.act ?? .none
        let handOver = active && (cue?.handOver ?? false)
        if handOver, act == .mount { engage = goal }
        if reduceMotion { engage = goal } else if engage < goal { engage = min(goal, engage + dt / 0.5) } else { engage = max(goal, engage - dt / 0.5) }
        flying = false
        guard engage > 0, let tl = timeline, let frame, let tracks, plan.rideable else { return overhead }
        let ride = Self.ridePose(at: clock, plan: plan, tracks: tracks, timeline: tl, frame: frame, free: free, size: size,
                                 reduceMotion: reduceMotion, handOver: handOver)
        let weight: Double
        if handOver {
            switch act {
            case .mount:
                // The orbit from the overhead view down to the chase view, ball pinned (mountPose).
                let ball = frame.world(plan.cueStart, height: frame.ballRadius)
                let w = Self.mountWeight(cue?.progress ?? 0, reduceMotion: reduceMotion)
                flying = w > 0
                return Self.mountPose(w, overhead: overhead, chase: ride, ball: ball, size: size)
            case .dismount:
                // The rise, by the act's own progress while the clock is held where the rise begins.
                weight = RidePlan.smooth(engage) * (1 - Self.dismountRise(cue?.progress ?? 0, reduceMotion: reduceMotion))
            case .landed:
                weight = 0
            default:
                // Roll and hold: the chase at full weight until the rise; past it (a scrub lands there as landed, so
                // this is a safety net) the overhead. Reduce Motion keeps its cut at the first contact.
                let risen = reduceMotion ? Self.riseWeight(at: clock, plan: plan, reduceMotion: true)
                                         : (clock >= plan.riseStart ? 1.0 : 0.0)
                weight = RidePlan.smooth(engage) * (1 - risen)
            }
        } else {
            weight = RidePlan.smooth(engage) * (1 - Self.riseWeight(at: clock, plan: plan, reduceMotion: reduceMotion))
        }
        guard weight > 1e-4 else { return overhead }
        flying = true
        return Self.mix(overhead, ride, Float(weight), turn: Self.turn(from: overhead, to: ride, tracks: tracks, clock: clock))
    }

    /// The ride's act this frame (TableScene sets it from ShowpieceModel.rideCue); nil means no acts are running and
    /// the ride behaves as in 0.7.5 (the rise follows the clock alone).
    var cue: RideCue?

    // MARK: Mount and dismount (0.7.6 stream ride; pure functions of the act's progress)

    /// How far through the orbit the mount is, from its progress p (0 to 1 over the mount's real time): the overhead
    /// view holds for the first 30 per cent (the ring pulses, the path is read), the orbit takes the next 55, and the
    /// chase view holds still for the last 15 before the strike plays. Reduce Motion: one cut, at 60 per cent.
    static func mountWeight(_ p: Double, reduceMotion: Bool) -> Double {
        if reduceMotion { return p >= 0.6 ? 1 : 0 }
        return min(1, max(0, (p - mountHoldShare) / mountOrbitShare))
    }

    static let mountHoldShare = 0.3
    static let mountOrbitShare = 0.55

    /// How far the dismount has risen (0 riding, 1 overhead) from its progress. Reduce Motion: a cut halfway.
    static func dismountRise(_ p: Double, reduceMotion: Bool) -> Double {
        reduceMotion ? (p >= 0.5 ? 1 : 0) : RidePlan.damped(p, length: 1)
    }

    /// A camera described about one point (the ridden ball): the heading and tilt it looks along, its field of view,
    /// where the point sits on screen (-1 to 1 across and up, the way the lens sees it) and how far ahead of the eye
    /// along the look direction the point is. Any camera with world up as its up is exactly one of these, and back.
    struct Orbit {
        var yaw: Float
        var pitch: Float
        var fov: Float
        var nx: Float
        var ny: Float
        var depth: Float
    }

    /// The look direction for a heading and tilt, and the camera's right and up for it (world up as the up, as
    /// TableCamera's look(at:from:upVector:) uses). The tilt never reaches straight down (the fitted view stops at
    /// 89.5 degrees and the chase is far from it), so the right vector is always defined.
    static func basis(yaw: Float, pitch: Float) -> (f: SIMD3<Float>, right: SIMD3<Float>, up: SIMD3<Float>) {
        let f = SIMD3<Float>(cos(pitch) * cos(yaw), sin(pitch), cos(pitch) * sin(yaw))
        let right = simd_normalize(simd_cross(f, SIMD3(0, 1, 0)))
        return (f, right, simd_cross(right, f))
    }

    /// A camera shot described about `ball` (see Orbit); nil when the ball is not in front of it.
    static func orbit(of s: CameraShot, about ball: SIMD3<Float>, size: CGSize) -> Orbit? {
        let f0 = simd_normalize(s.target - s.position)
        guard let yaw = heading(f0) else { return nil }
        let pitch = asin(min(1, max(-1, f0.y)))
        let b = basis(yaw: yaw, pitch: pitch)
        let d = ball - s.position
        let depth = simd_dot(d, b.f)
        guard depth > 0.02 else { return nil }
        let kY = tan(s.fov * .pi / 360), kX = kY * Float(max(1, size.width)) / Float(max(1, size.height))
        return Orbit(yaw: yaw, pitch: pitch, fov: s.fov, nx: simd_dot(d, b.right) / (depth * kX),
                     ny: simd_dot(d, b.up) / (depth * kY), depth: depth)
    }

    /// The camera shot an Orbit about `ball` describes: the eye is put so the ball lands exactly at (nx, ny).
    static func shot(_ o: Orbit, about ball: SIMD3<Float>, size: CGSize, near: Float) -> CameraShot {
        let b = basis(yaw: o.yaw, pitch: o.pitch)
        let kY = tan(o.fov * .pi / 360), kX = kY * Float(max(1, size.width)) / Float(max(1, size.height))
        let eye = ball - b.right * (o.nx * kX * o.depth) - b.up * (o.ny * kY * o.depth) - b.f * o.depth
        return CameraShot(position: eye, target: eye + b.f, fov: o.fov, near: near)
    }

    /// The mount (plan work package 2): from the overhead view to the first chase view, turning about the ball so it
    /// stays pinned on screen while the table tips and turns round it. The turn (heading), the tilt and the distance
    /// ease separately: the turn on a plain smooth step, the tilt a little ahead of it (the table tips as it starts to
    /// turn), the distance a little behind (the camera comes down last); the ball glides in a straight line from
    /// where the overhead view shows it to its place in the chase view. The heading takes the shorter way round, cut a
    /// little off the exact half turn (turnBias) so a straight shot up an upright phone never wavers between sides.
    /// Exactly the overhead view at w = 0 and exactly the chase view at w = 1; a pure function of w, so the self-test
    /// can check it. If either end cannot see the ball (a hand zoom that put it behind the camera) it falls back to
    /// the ordinary blend.
    static func mountPose(_ w: Double, overhead a: CameraShot, chase b: CameraShot, ball: SIMD3<Float>,
                          size: CGSize) -> CameraShot {
        guard w > 0 else { return a }
        guard w < 1 else { return b }
        guard let oa = orbit(of: a, about: ball, size: size), let ob = orbit(of: b, about: ball, size: size) else {
            return mix(a, b, Float(RidePlan.smooth(w)))
        }
        let turnShare = Float(RidePlan.smooth(w))
        let tiltShare = Float(RidePlan.smooth(min(1, w / 0.85)))
        let comeDown = Float(RidePlan.smooth(max(0, (w - 0.15) / 0.85)))
        let turn = wrap(ob.yaw - oa.yaw - turnBias) + turnBias
        let o = Orbit(yaw: oa.yaw + turn * turnShare,
                      pitch: oa.pitch + (ob.pitch - oa.pitch) * tiltShare,
                      fov: oa.fov + (ob.fov - oa.fov) * turnShare,
                      nx: oa.nx + (ob.nx - oa.nx) * turnShare,
                      ny: oa.ny + (ob.ny - oa.ny) * turnShare,
                      // In proportion (log), so the long way down from the overhead does not rush at the end.
                      depth: exp(log(oa.depth) + (log(ob.depth) - log(oa.depth)) * comeDown))
        return shot(o, about: ball, size: size, near: w > 0.02 ? rideNear : a.near)
    }

    /// Blend two camera shots (0.7.6 #18): the eye moves in a straight line, and the view turns by its heading (round
    /// the vertical) and its tilt (up and down) separately, each a straight share of the way, always with world up as
    /// its up. The old blend mixed the two look directions; upright, the table camera and a ride down the table look
    /// opposite ways, so partway through the mix pointed straight down, where "up" is undefined, and the picture
    /// flipped. Turning heading and tilt instead never reaches straight down (the tilt stays between the two ends, and
    /// neither end looks straight down) and the picture turns round smoothly instead.
    /// - turn: the signed heading change from a to b (radians), when the caller knows which way round to go; nil
    ///   takes the shorter way. The ride passes it (see turn(from:to:tracks:clock:)) so a shot heading exactly the
    ///   opposite way to the table camera never wavers between turning left and turning right.
    static func mix(_ a: CameraShot, _ b: CameraShot, _ w: Float, turn: Float? = nil) -> CameraShot {
        let fa = simd_normalize(a.target - a.position), fb = simd_normalize(b.target - b.position)
        let pos = a.position + (b.position - a.position) * w
        let ya = heading(fa) ?? heading(fb) ?? 0, yb = heading(fb) ?? ya
        let pa = asin(min(1, max(-1, fa.y))), pb = asin(min(1, max(-1, fb.y)))
        let yaw = ya + (turn ?? wrap(yb - ya)) * w
        let pitch = pa + (pb - pa) * w
        let f = SIMD3<Float>(cos(pitch) * cos(yaw), sin(pitch), cos(pitch) * sin(yaw))
        // The near plane follows whichever end is closer to the balls as soon as the ride has any say.
        return CameraShot(position: pos, target: pos + f, fov: a.fov + (b.fov - a.fov) * w,
                          near: w > 0.02 ? rideNear : a.near)
    }

    /// A look direction's heading round the vertical (atan2 of its z over its x, radians), nil when it looks straight
    /// up or down and has none.
    static func heading(_ f: SIMD3<Float>) -> Float? {
        simd_length(SIMD2(f.x, f.z)) > 1e-6 ? atan2(f.z, f.x) : nil
    }

    /// An angle brought into (-pi, pi].
    static func wrap(_ a: Float) -> Float {
        var x = a.truncatingRemainder(dividingBy: 2 * .pi)
        if x > .pi { x -= 2 * .pi }
        if x <= -.pi { x += 2 * .pi }
        return x
    }

    /// Which way round, and how far, the view turns from the table camera to the ride (radians), chosen once per shot
    /// and then followed continuously, so it can never jump from turning one way to the other mid-blend.
    /// The ride's heading is read from the cue ball's heading track, whose angle is unwrapped along the whole shot
    /// (no jump at a half turn). Only one choice is made: how the strike's own heading relates to the table camera's.
    /// That choice is cut a little off the exact half turn (by `turnBias`), because a straight break up the table on
    /// an upright phone is exactly a half turn, and a cut there would let rounding pick a different side each frame.
    static func turn(from a: CameraShot, to b: CameraShot, tracks: RideTracks, clock: Double) -> Float? {
        guard let ya = heading(simd_normalize(a.target - a.position)),
              let yb = heading(simd_normalize(b.target - b.position)) else { return nil }
        // A table angle a points along world (cos a, 0, -sin a) (TableFrame flips the across-table axis), whose
        // heading is -a.
        let rideYaw = -Float(tracks.cue.angle(at: clock))
        let startYaw = -Float(tracks.cue.angle(at: tracks.cue.start))
        // How far the strike's heading is from the table camera's, in (-pi + bias, pi + bias].
        let fromStart = startYaw - ya
        let chosen = wrap(fromStart - turnBias) + turnBias
        // The ride's heading followed continuously from the strike, plus the small difference between the track and
        // the pose's real heading (the free-space framing turns the view a few degrees).
        return chosen + (rideYaw - startYaw) + wrap(yb - rideYaw)
    }

    /// How far off the exact half turn the turn-direction cut sits (radians, about six degrees).
    static let turnBias: Float = 0.1

    // MARK: Pure pose maths (functions of the clock only)

    /// 0 while riding, rising to 1 as the camera goes back to the overhead. Reduce Motion: a cut at the first contact.
    static func riseWeight(at t: Double, plan: RidePlan, reduceMotion: Bool) -> Double {
        if reduceMotion {
            let cut = plan.contactTime.map { $0 + 0.1 } ?? plan.riseStart
            return t >= cut ? 1 : 0
        }
        return RidePlan.damped(t - plan.riseStart, length: plan.riseLength)
    }

    /// The low ride pose for clock time t, before any blend with the overhead.
    /// - handOver: the ride's acts are running (RideCue.handOver). The crane then finishes as the clock reaches the
    ///   first contact instead of starting there, so the clock held on the hit shows the three-quarter view over both
    ///   balls and Continue plays on from it without the camera dropping back (plan work package 6: "the crane holds
    ///   still while the clock is held"). Still a pure function of the clock.
    static func ridePose(at t: Double, plan: RidePlan, tracks: RideTracks, timeline tl: Timeline, frame: TableFrame,
                         free: FramingRect, size: CGSize, reduceMotion: Bool, handOver: Bool = false) -> CameraShot {
        let fov = rideFov(size)
        var shot: CameraShot
        if reduceMotion {
            // One still view behind the cue ball where it starts, looking the way it is struck.
            shot = follow(centre: plan.cueStart, heading: plan.strikeDirection, frame: frame, fov: fov)
        } else {
            // Always the cue ball: a chase view from behind and above it, never handed over to the ball it hits.
            // After the contact the camera cranes up and back (critically damped, from the contact time, so still a
            // pure function of the clock): close behind the cue ball on the way in, then high enough to see the
            // whole rack open or the struck ball run to its pocket.
            let lead = handOver ? Self.craneTime : 0
            let crane = Float(plan.contactTime.map { RidePlan.damped(t - ($0 - lead), length: Self.craneTime) } ?? 0)
            shot = follow(centre: position(tl, ball: plan.cueBall, at: t, span: plan.cueSpan),
                          heading: tracks.cue.heading(at: t),
                          frame: frame, fov: fov,
                          height: eyeHeight + (craneHeight - eyeHeight) * crane, back: back + (craneBack - back) * crane)
        }
        return frameInFreeSpace(shot, free: free, size: size)
    }

    /// The camera a couple of ball widths behind a ball at `centre`, heading along `heading`. Its target is the ball
    /// itself (its centre): frameInFreeSpace then turns the view so the ball lands in the lower third of the free space
    /// (0.7.6 #20; before, a point 0.38 m ahead was centred and the ball itself sat at the cards' edge).
    static func follow(centre c: Vec2, heading h: Vec2, frame: TableFrame, fov: Float,
                       height: Float = eyeHeight, back: Float = back) -> CameraShot {
        let r = frame.ballRadius
        let eye2 = c - h * Double(back)
        // Rails: the eye is already above the rail tops, but when it backs out past the cushion line it climbs a
        // little more, so the rail never hides the ball it is following. Continuous in position, so in time too.
        let outside = max(0, -eye2.x, eye2.x - Double(frame.length), -eye2.y, eye2.y - Double(frame.width))
        let lift = Float(min(outside, 0.2)) * 0.6
        var eye = frame.world(eye2, height: height + lift)
        // Belt and braces: never lower than the ball tops plus the near plane, whatever the constants become.
        eye.y = max(eye.y, 2 * r + rideNear * 2)
        let ball = frame.world(c, height: r)
        return CameraShot(position: eye, target: ball, fov: fov, near: rideNear)
    }

    /// A wide lens for the ride: about 64 degrees across the narrow side of the screen, kept between 46 and 106
    /// degrees tall (the field of view is vertical). 0.7.6 #20: the ceiling was 62, so a phone held upright (402 by
    /// 874, which needs about 107 tall for 64 across) got only about 31 degrees across, a narrow view that lost the
    /// object ball off the side within a few tenths of a second. At 106 the upright phone is about 63 across.
    /// Sideways the 46-degree floor decides, as before (about 85 across).
    static func rideFov(_ size: CGSize) -> Float {
        let w = Float(max(1, size.width)), h = Float(max(1, size.height))
        let vertical = 2 * atan(tan(32 * Float.pi / 180) * h / w) * 180 / .pi
        return min(106, max(46, vertical))
    }

    /// Turn the ride's look direction so the shot's target (the ridden ball) lands across the middle of the free space
    /// (between the title row and the cards) and `ballPlace` of the way down it, in its lower third, rather than at the
    /// middle of the screen; and keep the view pointing down at the cloth: the view ray never rises above a few degrees
    /// below the horizon, so it never looks over or through the table.
    static func frameInFreeSpace(_ s: CameraShot, free: FramingRect, size: CGSize) -> CameraShot {
        let w = Float(max(1, size.width)), h = Float(max(1, size.height))
        let kY = tan(s.fov * .pi / 360), kX = kY * w / h
        let nx = Float(free.centerX) / w * 2 - 1
        let ny = 1 - Float(free.top + free.height * ballPlace) / h * 2
        var f = simd_normalize(s.target - s.position)
        let right = simd_normalize(simd_cross(f, SIMD3(0, 1, 0)))
        let up = simd_cross(right, f)
        // To make the target appear at (nx, ny) on screen, look the opposite way by the matching angles.
        let pitch = atan(ny * kY), yaw = atan(nx * kX)
        f = simd_normalize(f * cos(pitch) - up * sin(pitch))
        f = simd_normalize(f * cos(yaw) - right * sin(yaw))
        // Floor on the downward tilt of the view ray (3 degrees).
        let minDown = sin(3 * Float.pi / 180)
        if f.y > -minDown {
            let flat = simd_length(SIMD2(f.x, f.z))
            let scale = flat > 1e-5 ? sqrt(1 - minDown * minDown) / flat : 0
            f = SIMD3(f.x * scale, -minDown, f.z * scale)
        }
        return CameraShot(position: s.position, target: s.position + f, fov: s.fov, near: s.near)
    }

    /// A ball's recorded position, with the time clamped into the span the ride follows it over.
    nonisolated static func position(_ tl: Timeline, ball b: Int, at t: Double, span: ClosedRange<Double>) -> Vec2 {
        tl.state(ball: b, at: min(max(t, span.lowerBound), span.upperBound)).position
    }

    /// The raw way a ball is heading at clock time t, read from the recorded path, not from its velocity (which flips
    /// in an instant at a cushion). RideTracks samples this once per shot and smooths it further.
    /// Each sample is the ball's movement over a short window of path (RidePlan.window). Samples are taken from a
    /// little ahead of t (the look-ahead) back into the past and weighted by a critically damped kernel
    /// k(τ) = τ·e^(−ωτ), the response of a critically damped follower, computed here from the recording instead of
    /// being stepped frame to frame. Each sample's weight also fades in with how far the ball moved in it, so samples
    /// that run onto a stopped ball fade out smoothly. Windows are slid (not cut) to stay inside the span, so before
    /// the ride starts the heading is the first direction of travel and after the ball stops it is the last.
    nonisolated static func rawHeading(_ tl: Timeline, ball b: Int, at t: Double, span: ClosedRange<Double>) -> Vec2? {
        let half = RidePlan.window * 0.5
        let lo = span.lowerBound + half, hi = span.upperBound - half
        guard hi > lo else { return nil }
        let samples = 20, step = 0.03, omega = 7.0, lead = 0.25
        var sum = Vec2.zero
        for k in 0..<samples {
            let tau = (Double(k) + 0.5) * step
            let weight = tau * exp(-omega * tau)
            let u = min(max(t + lead - tau, lo), hi)
            let d = position(tl, ball: b, at: u + half, span: span) - position(tl, ball: b, at: u - half, span: span)
            // Divide by at least a centimetre: a full unit vector for real movement, fading to nothing as the ball stops.
            let len = d.length
            if len > 1e-9 { sum = sum + d * (weight / max(len, 0.01)) }
        }
        return sum.length > 1e-6 ? sum.normalized : nil
    }

    // MARK: Self-test (-rideSelfTest)

    /// Scrub exactness and smoothness of the ride, written to the console. Visits a tour of clock times forward, then
    /// backward, then shuffled with unrelated jumps in between, and checks the ride pose is bit-identical each time.
    /// Then steps through the whole shot in 1/240 s steps and records the biggest turn of the look direction and the
    /// biggest jump of the eye per step, the lowest eye height, and whether the view ever pointed up.
    /// Returns what it measured (nil before any timeline is loaded), so the unit tests (BreakdownTests/RideCheckTests)
    /// assert on the same check the launch flag logs.
    /// 0.7.6 stream ride: the sweep runs for both cranes (the 0.7.5 one and the hand-over's, which finishes at the
    /// contact), and the mount and the dismount are stepped too (see checkActs).
    @discardableResult
    func selfTest(size: CGSize) -> RideCheck? {
        guard let tl = timeline, let frame else { return nil }
        let free = FramingRect(left: 0, top: 0, right: Double(size.width), bottom: Double(size.height))
        guard let tracks else {
            NSLog("RIDE-SELFTEST rideable=no (nothing to ride) -> PASS")
            return RideCheck(rideable: false, mismatches: 0, maxTurnPerStep: 0, maxTurnAt: 0, maxEyeStep: 0, minEye: 0,
                             upward: false, passed: true)
        }
        func pose(_ t: Double, handOver: Bool = false) -> CameraShot {
            Self.ridePose(at: t, plan: plan, tracks: tracks, timeline: tl, frame: frame, free: free, size: size,
                          reduceMotion: false, handOver: handOver)
        }
        let d = tl.duration
        let times = [0, 0.1, 0.4, 0.8, 1.3, 2.0, d * 0.5, d * 0.8, d].map { min($0, d) }
        let first: [SIMD3<Float>] = times.map { pose($0).target }
        var mismatches = 0
        for (i, t) in times.enumerated().reversed() where pose(t).target != first[i] { mismatches += 1 }
        for i in [5, 1, 8, 0, 6, 3, 2, 7, 4] {
            _ = pose(d * 0.37)
            if pose(times[i]).target != first[i] { mismatches += 1 }
        }
        var maxTurn: Float = 0, maxTurnAt = 0.0, maxJump: Float = 0, minEye: Float = 10, upward = false
        for handOver in [false, true] {
            var prev = pose(0, handOver: handOver)
            var t = 1.0 / 240
            while t <= d {
                let p = pose(t, handOver: handOver)
                let fa = simd_normalize(prev.target - prev.position), fb = simd_normalize(p.target - p.position)
                let turn = acos(min(1, simd_dot(fa, fb))) * 180 / .pi
                if turn > maxTurn { maxTurn = turn; maxTurnAt = t }
                maxJump = max(maxJump, simd_length(p.position - prev.position))
                minEye = min(minEye, p.position.y)
                if fb.y > 0 { upward = true }
                prev = p
                t += 1.0 / 240
            }
        }
        let acts = checkActs(size: size, free: free, tracks: tracks, timeline: tl, frame: frame)
        minEye = min(minEye, acts.minEye)
        if acts.upward { upward = true }
        // A turn of more than 4 degrees in 1/240 s of clock (about 1000 degrees a second) would read as a snap. The
        // mount and dismount are stepped in 1/240 s of real time against the same limit; the ball may drift no more
        // than one point from its straight glide during the orbit.
        let pass = mismatches == 0 && !upward && minEye > 2 * frame.ballRadius && maxTurn < 4
            && acts.mountTurn < 4 && acts.dismountTurn < 4 && acts.pinError < 1
        NSLog("RIDE-SELFTEST rideable=%@ contact=%@ object=%@ objectPocketed=%@ riseStart=%.2f duration=%.2f scrubMismatches=%d maxTurnPerStep=%.2fdeg(at %.3f) maxEyeStep=%.4fm minEye=%.3fm upward=%@ -> %@",
              plan.rideable ? "yes" : "no", plan.contactTime.map { String(format: "%.3f", $0) } ?? "none",
              plan.objectBall.map(String.init) ?? "none", plan.objectBall.flatMap { tl.pocketTime[$0] } != nil ? "yes" : "no",
              plan.riseStart, d, mismatches, maxTurn, maxTurnAt, maxJump, minEye,
              upward ? "YES" : "no", pass ? "PASS" : "FAIL")
        NSLog("RIDE-SELFTEST acts mountMaxTurnPerStep=%.2fdeg dismountMaxTurnPerStep=%.2fdeg mountPinError=%.2fpt",
              acts.mountTurn, acts.dismountTurn, acts.pinError)
        return RideCheck(rideable: plan.rideable, mismatches: mismatches, maxTurnPerStep: maxTurn, maxTurnAt: maxTurnAt,
                         maxEyeStep: maxJump, minEye: minEye, upward: upward, passed: pass,
                         mountMaxTurnPerStep: acts.mountTurn, dismountMaxTurnPerStep: acts.dismountTurn,
                         mountPinError: acts.pinError)
    }

    /// The mount and the dismount, stepped through their progress in 1/240 s of real time (the mount at its first-ride
    /// length, the longer one, and at its usual length; the dismount at its length), from an overhead view like the
    /// fitted one (the long side up an upright screen, about 80 degrees down, the whole table in view). Measures the
    /// biggest turn of the look direction per step, the lowest eye, whether the view ever looked up, and, during the
    /// orbit, how far the ball strays from its straight glide on screen (projected through CameraFraming.project, an
    /// independent matrix). Pure: it only calls the pose functions.
    private func checkActs(size: CGSize, free: FramingRect, tracks: RideTracks, timeline tl: Timeline,
                           frame: TableFrame) -> (mountTurn: Float, dismountTurn: Float, pinError: Float, minEye: Float,
                                                  upward: Bool) {
        let portrait = size.width < size.height
        let yaw: Float = portrait ? .pi / 2 : 0
        let toward = SIMD2<Float>(sin(yaw), cos(yaw))
        let elevation: Float = 80 * .pi / 180, reach: Float = 3.2
        let eye = SIMD3<Float>(toward.x * reach * cos(elevation), reach * sin(elevation), toward.y * reach * cos(elevation))
        let overhead = CameraShot(position: eye, target: .zero, fov: 45, near: Self.overheadNear)
        let ball = frame.world(plan.cueStart, height: frame.ballRadius)
        func chase(_ t: Double) -> CameraShot {
            Self.ridePose(at: t, plan: plan, tracks: tracks, timeline: tl, frame: frame, free: free, size: size,
                          reduceMotion: false, handOver: true)
        }
        func turn(_ a: CameraShot, _ b: CameraShot) -> Float {
            let fa = simd_normalize(a.target - a.position), fb = simd_normalize(b.target - b.position)
            return acos(min(1, simd_dot(fa, fb))) * 180 / .pi
        }
        func screen(_ s: CameraShot) -> CGPoint {
            CameraFraming.project(ball, position: s.position, target: s.target, size: size, fovDegrees: s.fov)
        }
        var mountTurn: Float = 0, dismountTurn: Float = 0, pinError: Float = 0, minEye: Float = 10, upward = false
        let start = chase(0)
        let from = screen(overhead), to = screen(start)
        for length in [RideTiming.mount, RideTiming.firstMount] {
            var prev = overhead
            var p = 0.0
            while p <= 1 {
                let w = Self.mountWeight(p, reduceMotion: false)
                let s = Self.mountPose(w, overhead: overhead, chase: start, ball: ball, size: size)
                mountTurn = max(mountTurn, turn(prev, s))
                minEye = min(minEye, s.position.y)
                if simd_normalize(s.target - s.position).y > 0 { upward = true }
                // The ball's straight glide: from where the overhead shows it to its place in the chase, on the turn's
                // own share (mountPose moves nx, ny with it).
                let share = CGFloat(RidePlan.smooth(w))
                let expected = CGPoint(x: from.x + (to.x - from.x) * share, y: from.y + (to.y - from.y) * share)
                let seen = screen(s)
                pinError = max(pinError, Float(hypot(seen.x - expected.x, seen.y - expected.y)))
                prev = s
                p += 1 / (240 * length)
            }
        }
        // The dismount: the clock held where the rise begins, the camera rising by the act's progress.
        let low = chase(plan.riseStart)
        var prev = low
        var p = 0.0
        while p <= 1 {
            let w = Float(1 - Self.dismountRise(p, reduceMotion: false))
            let s = Self.mix(overhead, low, w, turn: Self.turn(from: overhead, to: low, tracks: tracks, clock: plan.riseStart))
            dismountTurn = max(dismountTurn, turn(prev, s))
            minEye = min(minEye, s.position.y)
            if simd_normalize(s.target - s.position).y > 0 { upward = true }
            prev = s
            p += 1 / (240 * RideTiming.dismount)
        }
        return (mountTurn, dismountTurn, pinError, minEye, upward)
    }
}

/// What the ride self-test measured (ShotCamera.selfTest): scrub mismatches (must be 0), the biggest turn of the look
/// direction per 1/240 s step in degrees (must stay under 4), the biggest eye move per step and the lowest eye height
/// in metres (must stay above two ball radii), whether the view ever pointed up (must not), and the verdict.
struct RideCheck: Equatable {
    var rideable: Bool
    var mismatches: Int
    var maxTurnPerStep: Float
    var maxTurnAt: Double
    var maxEyeStep: Float
    var minEye: Float
    var upward: Bool
    var passed: Bool
    /// 0.7.6 stream ride: the mount's and the dismount's biggest turn per 1/240 s of real time (degrees, under 4 each)
    /// and how far the ball strayed from its straight glide on screen during the mount's orbit (points, under 1).
    /// Defaulted so the checks written before them still build.
    var mountMaxTurnPerStep: Float = 0
    var dismountMaxTurnPerStep: Float = 0
    var mountPinError: Float = 0
}

// MARK: Heading tracks

/// The ridden balls' headings, sampled once per shot.
struct RideTracks {
    let cue: HeadingTrack

    init(_ tl: Timeline, plan: RidePlan) {
        cue = HeadingTrack(tl, ball: plan.cueBall, span: plan.headingSpan, fallback: plan.strikeDirection)
    }
}

/// A ball's heading as an angle on the table, sampled at 120 a second over the span the ride follows it (plus the
/// stretch either side where the look-ahead still changes it), then smoothed with a critically damped follower run
/// forward and then backward over the samples. Running it both ways cancels its lag, so the camera turns exactly
/// as early as the look-ahead says, and a ball that bounces straight back off a cushion (where the raw heading
/// swings half a turn almost at once) makes the camera swing round over a few tenths of a second instead.
/// Built once per shot from the recording, read by interpolation: a pure function of the clock.
struct HeadingTrack {
    let start: Double
    static let step = 1.0 / 120
    let angles: [Double]

    init(_ tl: Timeline, ball b: Int, span: ClosedRange<Double>, fallback: Vec2) {
        // Outside this range the raw heading cannot change (its samples are all slid to one end of the span).
        // The extra second at the end lets the forward pass settle before the backward pass starts from it.
        start = span.lowerBound - 0.6
        let end = span.upperBound + 1.0
        let n = max(2, Int(((end - start) / Self.step).rounded(.up)) + 1)
        // 1. Raw angles, unwrapped so a turn through ±180 degrees is continuous. Where the raw heading is undefined
        //    (the ball never really moved) the previous angle carries on.
        var raw = [Double](repeating: atan2(fallback.y, fallback.x), count: n)
        var previous: Double?
        for i in 0..<n {
            let t = start + Double(i) * Self.step
            var a = previous ?? raw[i]
            if let h = ShotCamera.rawHeading(tl, ball: b, at: t, span: span) {
                a = atan2(h.y, h.x)
                if let p = previous {
                    while a - p > .pi { a -= 2 * .pi }
                    while a - p < -.pi { a += 2 * .pi }
                }
            }
            raw[i] = a
            previous = a
        }
        // 2. Critically damped follower, forward then backward (zero lag). x'' = ω²(target − x) − 2ω x'.
        func follow(_ input: [Double]) -> [Double] {
            let omega = 7.0, dt = Self.step
            var x = input[0], v = 0.0
            var out = input
            for i in 0..<input.count {
                let a = omega * omega * (input[i] - x) - 2 * omega * v
                v += a * dt
                x += v * dt
                out[i] = x
            }
            return out
        }
        angles = Array(follow(Array(follow(raw).reversed())).reversed())
    }

    func heading(at t: Double) -> Vec2 {
        let a = angle(at: t)
        return Vec2(cos(a), sin(a))
    }

    /// The heading as a table angle (radians), unwrapped along the whole shot: it never jumps by a full turn, so the
    /// ride blend can follow it continuously (ShotCamera.turn).
    func angle(at t: Double) -> Double {
        let x = min(max((t - start) / Self.step, 0), Double(angles.count - 1))
        let i = min(Int(x), angles.count - 2)
        let f = x - Double(i)
        return angles[i] + (angles[i + 1] - angles[i]) * f
    }
}

// MARK: Demo shot (-rideDemo)

enum RideDemo {
    /// A plain straight pot for showing the ride: the cue ball, one object ball and the far corner pocket in a line,
    /// struck firmly with a touch of draw so the cue ball stays out. Everything else is off the table.
    static func straightPot() -> ShotInput {
        let p = PoolParameters()
        var positions = [Vec2](repeating: NextShot.offTable, count: 16)
        // The corner pocket furthest from the head spot.
        let pocket = p.pocketCenters.max { ($0.x + $0.y) < ($1.x + $1.y) } ?? Vec2(p.tableLength, p.tableWidth)
        let cue = Vec2(p.tableLength * 0.3, p.tableWidth * 0.35)
        let line = (pocket - cue).normalized
        positions[0] = cue
        positions[1] = pocket - line * 0.75
        return NextShot.shot(from: positions, direction: line, speed: 2.6, tipUp: -0.008, tipSide: 0, seed: 7, parameters: p)
    }
}
