// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Bullet time's camera (plans/23-Nov-2026-bullet-time-plan.md, version 0.7.7). While the clock stands still on
//          a hit (BulletTime), the camera drops to just above the ball tops, about 15 degrees short of directly behind
//          the striking ball, swings 75 degrees round the contact while rising, and ends side-on to the line of centres
//          from the side the striking ball will not leave towards, about 25 degrees above the cloth, where the lines
//          drawn on the cloth plane read. Then it hands back to the table camera. In shares of the freeze (hold, 0 to
//          1): the first fifth blends in from wherever the table camera is, the next three-fifths swing, the last fifth
//          holds still; the let-go (release, 0 to 1) blends back out and ends exactly on the table camera's own pose.
//          The contact is kept in the middle of the measured free space, with the ride's wide lens.
//          Rails, posts and pins: the eye lifts over a cushion it would sit outside of, and over a post or pin it would
//          sit inside, continuously, so the contact is never seen through them.
//          If the freeze ends early (the Lens, Ride, a scrub, a Replay, a new shot, the option) the camera eases back
//          over 0.35 s of real time from where it was, never cuts. Under Reduce Motion it never moves at all.
//          The pieces the picture depends on (orbitPlan, weights, shot) are pure, so a clip could rebuild a freeze from
//          the recording alone.
//          Integration: TableScene owns one, calls set(cue:timeline:frame:) every frame before the camera moves and
//          passes it to TableCamera.update, which calls override(...) right after the ride's override and before the
//          lamp shot. `flying` holds off the hand zoom (TableZoom.rideHold), as the ride's does.
// SRP/DRY check: Pass - checked ShotCamera.swift (mix, frameInFreeSpace, rideFov and rideNear are reused; the ride
//          follows a ball along the clock, this circles one still contact in real time, so neither is the other),
//          TableCamera (the fitted pose and the lamp shot, untouched), LensContactGeometry (the contact frame is read
//          from ContactGeometry, not rederived) and TableFrame (table-to-world conversion).
import BreakdownLensModel
import BreakdownTimeline
import CoreGraphics
import Foundation
import simd

@MainActor
final class BulletTimeCamera {
    /// How far the swing turns round the contact, degrees.
    static let turnDegrees = 75.0
    /// How far the eye sits from the contact in plan, in ball radii.
    static let distanceRadii = 13.0
    /// The eye's height above the cloth over a cushion line, metres: the rail top's 0.075 plus a ball's width.
    static let railClear = 0.11
    /// How long an early end eases back, real seconds.
    static let earlyEndSeconds = 0.35

    /// The orbit for one moment, worked out once: the contact point, the start and end bearings (unit, table plan,
    /// from the contact towards the eye), the ball radius and the table for the clearances.
    private struct Orbit {
        let moment: BulletMoment
        let centre: Vec2
        let b0: Vec2
        let b1: Vec2
        let radius: Double
        let table: TableSpec
    }

    private var cue: BulletCue?
    private var orbit: Orbit?
    private var frame: TableFrame?
    /// The last orbit shot and its weight, so an early end can ease back from exactly where the view was.
    private var lastShot: CameraShot?
    private var lastWeight: Float = 0
    private var lastTick: TimeInterval?
    /// True while this camera has any say over the view (the hand zoom waits meanwhile).
    private(set) var flying = false

    /// Every frame, before the camera moves: the run's cue (nil when no freeze is holding or letting go), and the
    /// scene's recording and frame. The orbit is worked out once per moment, keyed by the moment itself (not the event
    /// index alone, which a later recording can share).
    func set(cue: BulletCue?, timeline: Timeline, frame: TableFrame) {
        self.cue = cue
        self.frame = frame
        guard let cue else { return }
        if let o = orbit, o.moment == cue.moment { return }
        orbit = Self.makeOrbit(cue.moment, timeline: timeline)
    }

    /// The orbit's bearings for a moment, or nil when the scene's recording does not hold that hit (the scene's
    /// recording can differ from the model's for a frame, as LensLayer's held event already allows for).
    private static func makeOrbit(_ m: BulletMoment, timeline: Timeline) -> Orbit? {
        guard timeline.events.indices.contains(m.event), let g = ContactGeometry.at(timeline.events[m.event]) else {
            return nil
        }
        let n = g.normal, t = g.tangent
        // The side the striking ball leaves along the tangent; when it barely moves across, the side it came in from;
        // when that is square too, an arbitrary but fixed side.
        var across = g.strikerOut.dot(t)
        if abs(across) < 0.05 { across = g.incoming.dot(t) }
        let side: Double = abs(across) < 0.05 ? 1 : (across > 0 ? 1 : -1)
        // End: side-on to the line of centres, on the side the striking ball does not head for.
        let b1 = t * -side
        // Start: b1 turned 75 degrees towards -n (behind the striking ball). -n is a right angle from b1, so this ends
        // 15 degrees short of directly behind; the turn direction is the one whose cross product with -n is positive.
        let back = -n
        let turn = (b1.x * back.y - b1.y * back.x) > 0 ? 1.0 : -1.0
        let b0 = rotate(b1, by: turn * turnDegrees * .pi / 180)
        return Orbit(moment: m, centre: g.point, b0: b0, b1: b1, radius: timeline.table.ballRadius,
                     table: timeline.table)
    }

    // MARK: Pure pieces

    /// Where the eye is at swing `s` (0 to 1), in table metres: the bearing turns from b0 to b1 the short way round,
    /// the eye sits 13 radii out along it, and climbs from 2.2 to 7 radii above the cloth. Then the clearances, each a
    /// continuous lift: over a cushion line once the eye's plan point is outside the cloth (railClear, fully at 5 cm
    /// out), and over any post or pin it would sit inside or near (its height plus a ball's width, fully once within
    /// it). A pool table has no posts or pins, so nothing changes there.
    static func orbitPlan(centre: Vec2, b0: Vec2, b1: Vec2, swing s: Double, radius R: Double,
                          table: TableSpec) -> (eye: Vec2, height: Double) {
        let a0 = b0.normalized, a1 = b1.normalized
        // The signed angle from a0 to a1 (short way round); for the orbit it is 75 degrees one way or the other.
        let total = atan2(a0.x * a1.y - a0.y * a1.x, a0.dot(a1))
        let x = min(1, max(0, s))
        let bearing = rotate(a0, by: total * x)
        let eye = centre + bearing * (distanceRadii * R)
        var height = R * (2.2 + 4.8 * smooth(x))
        // How far outside the cloth rectangle (0...length by 0...width) the eye stands, metres; 0 inside.
        let outside = max(0, -eye.x, eye.x - table.length, -eye.y, eye.y - table.width)
        height = max(height, railClear * smoothstep(0, 0.05, outside))
        for post in table.posts {
            let gap = (eye - post.center).length - post.radius
            height = max(height, (post.height + 2 * R) * (1 - smoothstep(0, 0.05, gap)))
        }
        for pin in table.pins {
            let gap = (eye - pin.center).length - pin.radius
            height = max(height, (pin.height + 2 * R) * (1 - smoothstep(0, 0.05, gap)))
        }
        return (eye, height)
    }

    /// The camera at an eye point, looking at the contact at the balls' centre height, with the ride's wide lens and
    /// near plane, turned so the contact sits in the middle of the free space.
    static func shot(eye: Vec2, height: Double, centre: Vec2, frame: TableFrame, free: FramingRect,
                     size: CGSize) -> CameraShot {
        let raw = CameraShot(position: frame.world(eye, height: Float(height)),
                             target: frame.world(centre, height: frame.ballRadius),
                             fov: ShotCamera.rideFov(size), near: ShotCamera.rideNear)
        return ShotCamera.frameInFreeSpace(raw, free: free, size: size, place: 0.5)
    }

    /// How much say the orbit has (blend) and how far round it is (swing), from the cue's hold and release. The blend
    /// is 0 at hold 0 and again at release 1, so the hand-back ends exactly on the table camera's pose.
    static func weights(hold: Double, release: Double) -> (blend: Double, swing: Double) {
        let blend = smooth(hold / 0.2) * (1 - smooth(release))
        let swing = smooth((hold - 0.2) / 0.6)
        return (blend, swing)
    }

    // MARK: The override

    /// TableCamera's hook, after the ride and before the lamp shot: the given shot blended toward the orbit while a
    /// cue is set; easing back from the last orbit shot after an early end; otherwise the shot untouched.
    func override(_ shot: CameraShot, free: FramingRect, size: CGSize, reduceMotion: Bool) -> CameraShot {
        let now = ProcessInfo.processInfo.systemUptime
        let dt = min(0.1, max(0, now - (lastTick ?? now)))
        lastTick = now
        // Reduce Motion (now, or when the freeze began): the camera does not move at all.
        if reduceMotion || cue?.reduceMotion == true {
            flying = false
            lastWeight = 0
            lastShot = nil
            return shot
        }
        if let cue, let o = orbit, let frame {
            let w = Self.weights(hold: cue.hold, release: cue.release)
            let p = Self.orbitPlan(centre: o.centre, b0: o.b0, b1: o.b1, swing: w.swing, radius: o.radius, table: o.table)
            let orbitShot = Self.shot(eye: p.eye, height: p.height, centre: o.centre, frame: frame, free: free, size: size)
            lastShot = orbitShot
            lastWeight = Float(w.blend)
            flying = w.blend > 0.001
            return ShotCamera.mix(shot, orbitShot, Float(w.blend))
        }
        // Ended early (or the recording changed under it): ease back from where the view was, never cut.
        if lastWeight > 0, let last = lastShot {
            lastWeight = max(0, lastWeight - Float(dt / Self.earlyEndSeconds))
            flying = lastWeight > 0
            if lastWeight > 0 { return ShotCamera.mix(shot, last, lastWeight) }
            lastShot = nil
            return shot
        }
        flying = false
        return shot
    }

    // MARK: Helpers

    /// A plan vector turned counter-clockwise by `a` radians.
    private static func rotate(_ v: Vec2, by a: Double) -> Vec2 {
        let c = cos(a), s = sin(a)
        return Vec2(v.x * c - v.y * s, v.x * s + v.y * c)
    }

    /// The 0-to-1 smoothstep, clamped.
    private static func smooth(_ x: Double) -> Double { let c = min(1, max(0, x)); return c * c * (3 - 2 * c) }

    /// The smoothstep from `a` to `b`: 0 at or below a, 1 at or above b, eased between.
    private static func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double { smooth((x - a) / (b - a)) }
}
