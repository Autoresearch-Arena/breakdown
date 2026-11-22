// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (a chase view of the cue ball for the whole shot, as the Boss asked:
//          higher and further back, no hand-over to the struck ball, a crane up after the first contact).
// Edited: Claude Opus 5.5 High, 21-November-2026 (release stream: selfTest also returns what it measured as a RideCheck,
//          so the app's unit tests assert on the same check the -rideSelfTest flag logs; the check itself is unchanged).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 foundation: RidePlan takes the struck ball, cueBall, so the
//          ride can follow whichever ball the player strikes; the ride itself still reads ball 0 until stream camera).
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
//          second instead of jumping (under Reduce Motion it cuts).
//          Reduce Motion: no ride. The camera holds one still low angle behind the cue ball where it starts, then cuts
//          to the overhead at the first contact.
//          Also here: the slow-motion curve Ride adds around the first contact (RidePlan.rateFactor, read by
//          ShowpieceModel; also a pure function of the clock), the -rideDemo straight pot (RideDemo), and the
//          -rideSelfTest scrub-exactness and smoothness check (ShotCamera.selfTest, run by TableScene).
//          Integration: TableScene owns one ShotCamera, loads it with each new timeline and sets `clock` and `active`
//          every frame; TableCamera.update calls `override(...)` with its normal overhead pose and uses what comes back
//          (position, look target, field of view, near plane). Trig and exp live here in the app; the physics package
//          is only read.
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
        guard tl.ballCount > 0, tl.duration > 0.3 else { return }
        let duration = tl.duration
        cueStart = tl.state(ball: 0, at: 0).position
        let v0 = tl.state(ball: 0, at: 0).velocity
        if v0.length > 1e-6 { strikeDirection = v0.normalized }
        // Nothing to ride without a real strike (a re-rack records a still table).
        guard v0.length > 0.05 else { return }
        let cueStop = Self.travelEnd(tl, ball: 0)

        // First ball-ball event that involves the cue ball: the contact time and the struck ball.
        let first = tl.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }
        contactTime = first?.time
        let struck = first?.balls.first { $0.ball != 0 }?.ball
        // The camera stays with the cue ball the whole way (the Boss: "you want to be the cue ball"), so its place is
        // followed until it stops or drops.
        cueSpan = 0...max(Self.window, cueStop)
        // Its heading only follows the cue ball after the contact when the cue ball really goes somewhere afterwards.
        // A cue ball that stops dead or sits in the middle of a break keeps looking the way it came, at the balls it
        // sent off, instead of swinging round to stare at the rail behind it.
        if let c = contactTime {
            let after = (tl.state(ball: 0, at: cueStop).position - tl.state(ball: 0, at: c).position).length
            headingSpan = after > Self.followOn ? cueSpan : 0...max(Self.window, c)
        } else {
            headingSpan = cueSpan
        }

        // Stay low until the cue ball and the ball it hit have both finished their runs, so the camera watches the
        // struck ball roll away (and drop) from behind the cue ball. Never for more than a few seconds after contact.
        var rideEnd = tl.pocketTime[0] != nil ? cueStop + 0.35 : cueStop + 0.2
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
    /// 0 to 1: how far Ride is switched in, eased in wall time so a mid-shot toggle does not jump.
    private var engage = 0.0
    private var lastTick: TimeInterval?

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
    /// The point on the cloth the camera looks at, this far ahead of the cue ball.
    static let ahead: Float = 0.38
    /// Where the camera cranes to after the first contact, and how long that takes (clock seconds).
    static let craneHeight: Float = 0.85
    static let craneBack: Float = 0.95
    static let craneTime = 0.45

    func load(_ tl: Timeline, frame: TableFrame) {
        timeline = tl
        self.frame = frame
        plan = RidePlan(tl)
        tracks = plan.rideable ? RideTracks(tl, plan: plan) : nil
    }

    /// TableCamera's hook. Takes the normal overhead camera and returns the one to use this frame: unchanged when
    /// Ride is off (or fully risen), the ride pose when riding, and a blend while handing over.
    func override(position: SIMD3<Float>, target: SIMD3<Float>, fov: Float, free: FramingRect, size: CGSize,
                  reduceMotion: Bool) -> CameraShot {
        let overhead = CameraShot(position: position, target: target, fov: fov, near: Self.overheadNear)
        // Switching in and out: half a second of wall time, or a cut under Reduce Motion.
        let now = ProcessInfo.processInfo.systemUptime
        let dt = min(0.1, max(0, now - (lastTick ?? now)))
        lastTick = now
        let goal = active && plan.rideable ? 1.0 : 0.0
        if reduceMotion { engage = goal } else if engage < goal { engage = min(goal, engage + dt / 0.5) } else { engage = max(goal, engage - dt / 0.5) }
        guard engage > 0, let tl = timeline, let frame, let tracks, plan.rideable else { return overhead }
        let weight = RidePlan.smooth(engage) * (1 - Self.riseWeight(at: clock, plan: plan, reduceMotion: reduceMotion))
        guard weight > 1e-4 else { return overhead }
        let ride = Self.ridePose(at: clock, plan: plan, tracks: tracks, timeline: tl, frame: frame, free: free, size: size,
                                 reduceMotion: reduceMotion)
        return Self.mix(overhead, ride, Float(weight))
    }

    /// Blend two camera shots: the eye moves in a straight line, the look direction turns between the two.
    static func mix(_ a: CameraShot, _ b: CameraShot, _ w: Float) -> CameraShot {
        let fa = simd_normalize(a.target - a.position), fb = simd_normalize(b.target - b.position)
        let pos = a.position + (b.position - a.position) * w
        var f = fa + (fb - fa) * w
        if simd_length(f) < 1e-4 { f = fb }        // opposite directions never happen here, but never divide by zero
        f = simd_normalize(f)
        // The near plane follows whichever end is closer to the balls as soon as the ride has any say.
        return CameraShot(position: pos, target: pos + f, fov: a.fov + (b.fov - a.fov) * w,
                          near: w > 0.02 ? rideNear : a.near)
    }

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
    static func ridePose(at t: Double, plan: RidePlan, tracks: RideTracks, timeline tl: Timeline, frame: TableFrame,
                         free: FramingRect, size: CGSize, reduceMotion: Bool) -> CameraShot {
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
            let crane = Float(plan.contactTime.map { RidePlan.damped(t - $0, length: Self.craneTime) } ?? 0)
            shot = follow(centre: position(tl, ball: 0, at: t, span: plan.cueSpan), heading: tracks.cue.heading(at: t),
                          frame: frame, fov: fov,
                          height: eyeHeight + (craneHeight - eyeHeight) * crane, back: back + (craneBack - back) * crane)
        }
        return frameInFreeSpace(shot, free: free, size: size)
    }

    /// The camera a couple of ball widths behind a ball at `centre`, looking along `heading` at the cloth ahead.
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
        let look = frame.world(c + h * Double(ahead), height: 0)
        return CameraShot(position: eye, target: look, fov: fov, near: rideNear)
    }

    /// A wide lens for the ride: about 64 degrees across the narrow side of the screen where that fits, kept between
    /// 46 and 62 degrees tall. A phone held upright hits the 62-degree ceiling, which keeps less empty room above the
    /// far rail in view than a taller lens would.
    static func rideFov(_ size: CGSize) -> Float {
        let w = Float(max(1, size.width)), h = Float(max(1, size.height))
        let vertical = 2 * atan(tan(32 * Float.pi / 180) * h / w) * 180 / .pi
        return min(62, max(46, vertical))
    }

    /// Turn the ride's look direction so its centre lands in the middle of the free space (between the title, the
    /// caption slot and the controls) rather than the middle of the screen, and keep it pointing down at the cloth:
    /// the view ray never rises above a few degrees below the horizon, so it never looks over or through the table.
    static func frameInFreeSpace(_ s: CameraShot, free: FramingRect, size: CGSize) -> CameraShot {
        let w = Float(max(1, size.width)), h = Float(max(1, size.height))
        let kY = tan(s.fov * .pi / 360), kX = kY * w / h
        let nx = Float(free.centerX) / w * 2 - 1
        let ny = 1 - Float(free.centerY) / h * 2
        var f = simd_normalize(s.target - s.position)
        let right = simd_normalize(simd_cross(f, SIMD3(0, 1, 0)))
        let up = simd_cross(right, f)
        // To make the old centre appear at (nx, ny) on screen, look the opposite way by the matching angles.
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
    @discardableResult
    func selfTest(size: CGSize) -> RideCheck? {
        guard let tl = timeline, let frame else { return nil }
        let free = FramingRect(left: 0, top: 0, right: Double(size.width), bottom: Double(size.height))
        guard let tracks else {
            NSLog("RIDE-SELFTEST rideable=no (nothing to ride) -> PASS")
            return RideCheck(rideable: false, mismatches: 0, maxTurnPerStep: 0, maxTurnAt: 0, maxEyeStep: 0, minEye: 0,
                             upward: false, passed: true)
        }
        func pose(_ t: Double) -> CameraShot {
            Self.ridePose(at: t, plan: plan, tracks: tracks, timeline: tl, frame: frame, free: free, size: size,
                          reduceMotion: false)
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
        var prev = pose(0)
        var t = 1.0 / 240
        while t <= d {
            let p = pose(t)
            let fa = simd_normalize(prev.target - prev.position), fb = simd_normalize(p.target - p.position)
            let turn = acos(min(1, simd_dot(fa, fb))) * 180 / .pi
            if turn > maxTurn { maxTurn = turn; maxTurnAt = t }
            maxJump = max(maxJump, simd_length(p.position - prev.position))
            minEye = min(minEye, p.position.y)
            if fb.y > 0 { upward = true }
            prev = p
            t += 1.0 / 240
        }
        // A turn of more than 4 degrees in 1/240 s of clock (about 1000 degrees a second) would read as a snap.
        let pass = mismatches == 0 && !upward && minEye > 2 * frame.ballRadius && maxTurn < 4
        NSLog("RIDE-SELFTEST rideable=%@ contact=%@ object=%@ objectPocketed=%@ riseStart=%.2f duration=%.2f scrubMismatches=%d maxTurnPerStep=%.2fdeg(at %.3f) maxEyeStep=%.4fm minEye=%.3fm upward=%@ -> %@",
              plan.rideable ? "yes" : "no", plan.contactTime.map { String(format: "%.3f", $0) } ?? "none",
              plan.objectBall.map(String.init) ?? "none", plan.objectBall.flatMap { tl.pocketTime[$0] } != nil ? "yes" : "no",
              plan.riseStart, d, mismatches, maxTurn, maxTurnAt, maxJump, minEye,
              upward ? "YES" : "no", pass ? "PASS" : "FAIL")
        return RideCheck(rideable: plan.rideable, mismatches: mismatches, maxTurnPerStep: maxTurn, maxTurnAt: maxTurnAt,
                         maxEyeStep: maxJump, minEye: minEye, upward: upward, passed: pass)
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
}

// MARK: Heading tracks

/// The ridden balls' headings, sampled once per shot.
struct RideTracks {
    let cue: HeadingTrack

    init(_ tl: Timeline, plan: RidePlan) {
        cue = HeadingTrack(tl, ball: 0, span: plan.headingSpan, fallback: plan.strikeDirection)
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
        let x = min(max((t - start) / Self.step, 0), Double(angles.count - 1))
        let i = min(Int(x), angles.count - 2)
        let f = x - Double(i)
        let a = angles[i] + (angles[i + 1] - angles[i]) * f
        return Vec2(cos(a), sin(a))
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
