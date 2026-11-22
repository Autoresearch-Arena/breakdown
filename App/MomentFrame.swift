// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 coordinator: reads the pace plan's TableRect regions).
// PURPOSE: The moment framing of a guided Physics Lens replay (0.7.6, plans/22-Nov-2026-v076-phone-plan.md, stream
//          camera; it replaces the 0.7.4 signature close-up). As the replay slows into a beat, the view glides in on
//          what the beat is about so it fills the open space above the cards and sits in its middle; it stays close
//          through the hold and for a moment after Continue, so the balls are watched leaving; then it eases back out
//          to the whole table as speed returns. Beats close together blend their rectangles instead of going out and
//          in again.
//          Three parts:
//          (1) MomentFraming.shape: a pure function of the playback clock and the pace plan (its beats and, from stream
//              pacing, PacePlan.focusRegions, one rectangle of the table per beat in table metres). It gives a weight w
//              (0 whole table, 1 fully in) and a focus rectangle in world plan coordinates. w rises over
//              PacePlan.approach shot-seconds before a beat, is 1 at the beat and for `hold` after it, then eases out
//              over `release`. Scrubbing to a time always gives the same answer.
//          (2) MomentFraming.frame: the camera move, a multiplier on the fitted pose (never a new fit, so the framing
//              self-check is untouched). With Q the cloth point under the middle of the free space and P the focus
//              rectangle's centre, the camera keeps its orientation, its look point moves from Q toward P by w, and its
//              distance shrinks about that look point by 1 / m^w, where m (1 to 3.5) is what fits the rectangle in
//              about 70 per cent of the free space. At w = 1 that is the plan's "move across by P - Q, scale about P",
//              and P sits in the middle of the free space. Expressed exactly as the hand zoom's own scale and offset,
//              so a pinch made while it is in takes the view over without a jump (TableZoom.momentLook).
//          (3) MomentFrame, the one bit of wall-clock state: a gate that eases the whole thing in and out over 0.4 s when
//              it becomes allowed or stops being allowed (the Lens turned on or off mid-moment, Ride on), so those never
//              cut. It snaps to 0 when the hand zoom leaves the fitted view (the hand has adopted the view) and under
//              Reduce Motion, and restarts from 0 on a new shot and on a Replay from the start, which ease in rather
//              than cut. While allowed and steady the gate is 1 and the picture is a function of the clock alone.
//          When it runs (MomentFrame.allowed): a guided replay (model.guided) in the explore or slow-replay stage, not
//          behind the menu (the backdrop), not during the first launch's opening (which stays exactly as calm as
//          before), not while Ride flies; and in TableScene only with Reduce Motion off and the hand zoom at the fitted
//          view. Launch with -noMomentFrame to switch it off for screenshot comparisons; -noPushIn makes its gate snap.
// SRP/DRY check: Pass - checked TableCamera (fitted framing, push-in; applies this answer, does not compute it),
//          TableZoom (the hand's zoom; this hands it its view through momentLook and never sets its goal), ShotCamera
//          (Ride, which this steps aside for), PacePlan (owns the beats and the focus regions; read only) and the
//          retired SignatureCloseUp (its job is now this file's).
import BreakdownLensModel
import BreakdownTimeline
import CoreGraphics
import Foundation
import simd

/// The moment framing's answer for one frame: how far in (weight, 0 to 1, gate included) and the rectangle to show,
/// in world plan coordinates (x along the table, z across, metres; the zoom's coordinates).
struct MomentFocus: Equatable {
    var weight: Float
    var centre: SIMD2<Float>
    var half: SIMD2<Float>
}

/// What the screen asks of the moment framing this frame (TableStage builds it from the model).
struct MomentRequest {
    /// The model allows it now (MomentFrame.allowed).
    var allowed: Bool
    /// The beats and their focus rectangles.
    var plan: PacePlan
}

// MARK: The pure part

enum MomentFraming {
    /// Shot-seconds the view stays fully in after a beat, so the balls are watched leaving the moment close up.
    static let hold = 0.35
    /// Shot-seconds it then takes to ease back out to the whole table.
    static let release = 0.3
    /// The most the moment is magnified, and the share of the free space its rectangle may fill.
    static let maxMagnification: Float = 3.5
    static let fill: Float = 0.7

    static func smooth(_ x: Double) -> Double { let c = min(1, max(0, x)); return c * c * (3 - 2 * c) }

    /// The weight and focus rectangle at clock time t, or nil when the view is whole (w = 0) or the plan carries no
    /// matching focus regions. A pure function of t and the plan.
    static func shape(at t: Double, plan: PacePlan, frame: TableFrame) -> MomentFocus? {
        let beats = plan.beats
        let regions = plan.focusRegions
        guard !beats.isEmpty, regions.count == beats.count else { return nil }
        // n: the first beat strictly after t; p: the last beat at or before t (-1 for none).
        var n = plan.firstBeat(atOrAfter: t)
        while n < beats.count, beats[n].time <= t { n += 1 }
        let p = n - 1
        let approach = PacePlan.approach

        // The weight: only the beats either side matter (an older beat's ease-out is always below the newer one's, a
        // later beat's ease-in below the nearer one's).
        var w = 0.0
        if p >= 0 {
            let since = t - beats[p].time
            w = since <= hold ? 1 : 1 - smooth((since - hold) / release)
        }
        if n < beats.count {
            w = max(w, smooth((t - (beats[n].time - approach)) / approach))
        }
        guard w > 1e-4 else { return nil }

        // The rectangle of beat i in world plan coordinates, joined with every beat at the same instant (two
        // captions on one moment show both), padded by a ball and a half so a ball at its edge is wholly inside.
        func box(_ i: Int) -> (lo: SIMD2<Float>, hi: SIMD2<Float>) {
            var lo = SIMD2<Float>(repeating: .infinity), hi = SIMD2<Float>(repeating: -.infinity)
            var j = i
            while j > 0, abs(beats[j - 1].time - beats[i].time) < 1e-6 { j -= 1 }
            while j < beats.count, abs(beats[j].time - beats[i].time) < 1e-6 {
                // TableFrame flips the across-table axis, so each corner is converted and the box re-sorted.
                for corner in [Vec2(regions[j].minX, regions[j].minY), Vec2(regions[j].maxX, regions[j].maxY)] {
                    let w3 = frame.world(corner)
                    let q = SIMD2<Float>(w3.x, w3.z)
                    lo = simd_min(lo, q); hi = simd_max(hi, q)
                }
                j += 1
            }
            let pad = SIMD2<Float>(repeating: frame.ballRadius * 1.5)
            return (lo - pad, hi + pad)
        }

        let rect: (lo: SIMD2<Float>, hi: SIMD2<Float>)
        if p < 0 {
            rect = box(n)
        } else if n >= beats.count {
            rect = box(p)
        } else {
            let bp = beats[p].time, bn = beats[n].time
            let a = box(p), b = box(n)
            let u: Float
            if bn - approach >= bp + hold + release {
                // Far apart: the view is whole in between, so the rectangle simply changes there (w is 0 at the cut).
                u = t < bp + hold + release ? 0 : 1
            } else {
                // Close together: the view stays in and glides from one rectangle to the next, starting once the
                // first beat's departure has been watched (or halfway, when the next one comes sooner).
                let s0 = bp + min(hold, (bn - bp) * 0.5)
                u = Float(smooth((t - s0) / (bn - s0)))
            }
            rect = (a.lo + (b.lo - a.lo) * u, a.hi + (b.hi - a.hi) * u)
        }
        return MomentFocus(weight: Float(w), centre: (rect.lo + rect.hi) * 0.5, half: (rect.hi - rect.lo) * 0.5)
    }

    /// The cloth point (world, y = 0) seen at view point `point` (points, origin top left) by a camera at `position`
    /// looking along the unit `forward` with world up and vertical field of view `fovDegrees`; the same camera maths
    /// as CameraFraming.project. Nil when that ray does not come down to the cloth.
    static func clothPoint(position: SIMD3<Float>, forward f: SIMD3<Float>, at point: CGPoint, size: CGSize,
                           fovDegrees: Float) -> SIMD3<Float>? {
        let w = Float(max(1, size.width)), h = Float(max(1, size.height))
        let kY = tan(fovDegrees * .pi / 360), kX = kY * w / h
        let side = simd_cross(f, SIMD3<Float>(0, 1, 0))
        guard simd_length(side) > 1e-6 else { return nil }
        let r = simd_normalize(side), u = simd_cross(r, f)
        let nx = Float(point.x) / w * 2 - 1, ny = 1 - Float(point.y) / h * 2
        let d = f + r * (nx * kX) + u * (ny * kY)
        guard d.y < -1e-4 else { return nil }
        return position + d * (-position.y / d.y)
    }

    /// How much larger the focus rectangle can be shown (1 to maxMagnification): the largest m for which, with the
    /// camera moved so the rectangle's centre P sits where Q did and brought m times closer about P, every corner of
    /// the rectangle (on the cloth and at ball-top height) stays within `fill` of the free space around its middle.
    /// Found by halving, like the fit itself, so perspective is measured rather than assumed.
    static func magnification(_ focus: MomentFocus, position: SIMD3<Float>, forward f: SIMD3<Float>, pivot q: SIMD3<Float>,
                              free: FramingRect, size: CGSize, fovDegrees: Float, ballTop: Float) -> Float {
        let w = Float(max(1, size.width)), h = Float(max(1, size.height))
        let kY = tan(fovDegrees * .pi / 360), kX = kY * w / h
        let side = simd_cross(f, SIMD3<Float>(0, 1, 0))
        guard simd_length(side) > 1e-6 else { return 1 }
        let r = simd_normalize(side), u = simd_cross(r, f)
        // The free space's middle in normalised device coordinates, and the room either side of it in the same units.
        let cx = Float(free.centerX) / w * 2 - 1, cy = 1 - Float(free.centerY) / h * 2
        let roomX = Float(free.width) / w * fill, roomY = Float(free.height) / h * fill
        let p = SIMD3<Float>(focus.centre.x, 0, focus.centre.y)
        var corners: [SIMD3<Float>] = []
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { for y in [0, ballTop] {
            corners.append(SIMD3(p.x + sx * focus.half.x, y, p.z + sz * focus.half.y))
        } } }
        let away = position - q
        func fits(_ m: Float) -> Bool {
            let c = p + away / m
            for a in corners {
                let v = a - c
                let z = simd_dot(v, f)
                guard z > 0.02 else { return false }
                let x = simd_dot(v, r) / (z * kX), y = simd_dot(v, u) / (z * kY)
                if abs(x - cx) > roomX || abs(y - cy) > roomY { return false }
            }
            return true
        }
        if fits(maxMagnification) { return maxMagnification }
        if !fits(1) { return 1 }
        var lo: Float = 1, hi = maxMagnification
        // Sixteen halvings of a 2.5 span: far finer than anything visible.
        for _ in 0..<16 {
            let mid = (lo + hi) * 0.5
            if fits(mid) { lo = mid } else { hi = mid }
        }
        return lo
    }

    /// The moment applied to a fitted pose (see PURPOSE, part 2). Returns the new pose, and the same move in the hand
    /// zoom's terms (scale of the distance, offset of the look point from Q in world plan) so TableZoom can adopt it,
    /// and the full magnification m (for -frameDebug).
    static func frame(_ focus: MomentFocus, position: SIMD3<Float>, target: SIMD3<Float>, pivot q: SIMD3<Float>,
                      free: FramingRect, size: CGSize, fovDegrees: Float, ballTop: Float)
        -> (position: SIMD3<Float>, target: SIMD3<Float>, scale: Float, offset: SIMD2<Float>, magnification: Float) {
        let f = simd_normalize(target - position)
        let m = magnification(focus, position: position, forward: f, pivot: q, free: free, size: size,
                              fovDegrees: fovDegrees, ballTop: ballTop)
        let w = min(1, max(0, focus.weight))
        // Magnification blended on a log scale, so the glide in feels even rather than rushing at the start.
        let mw = pow(m, w)
        let p = SIMD3<Float>(focus.centre.x, 0, focus.centre.y)
        let look = q + (p - q) * w
        let newPosition = look + (position - q) / mw
        return (newPosition, newPosition + f, 1 / mw, SIMD2(look.x - q.x, look.z - q.z), m)
    }
}

// MARK: The gate (the one piece of wall-clock state)

@MainActor
final class MomentFrame {
    /// Wall seconds the gate takes to open or close.
    static let gateTime = 0.4
    /// -noMomentFrame switches the moment framing off (exact screenshot comparisons of the whole table).
    static let off = ProcessInfo.processInfo.arguments.contains("-noMomentFrame")
    /// -noPushIn (exact screenshot comparisons): the gate snaps instead of easing.
    private static let motionOff = ProcessInfo.processInfo.arguments.contains("-noPushIn")

    private var gate = 0.0
    private var lastTick: TimeInterval?
    private var lastClock = 0.0

    /// A new shot: the next moment eases in from the whole table.
    func reset() {
        gate = 0
        lastClock = 0
    }

    /// True when the model allows the moment framing now: a guided Lens replay (the player's, a trick's or a lesson's,
    /// or Watch the intro), in the explore or slow-replay stage, the menu closed (never the backdrop behind it), not
    /// during the first launch's opening (kept exactly as calm as before), and not while Ride flies.
    static func allowed(for model: ShowpieceModel) -> Bool {
        guard model.guided, !model.menuOpen, !model.menuBackdropPlaying, !model.rideActive,
              model.openingStage == .none else { return false }
        return model.stage == .explore || model.stage == .slowReplay
    }

    /// This frame's moment, or nil for the whole table. Called once per frame by TableScene before the camera moves.
    /// - handAtFit: the hand zoom's goal is the fitted view (TableZoom.atFittedView).
    func focus(clock: Double, request: MomentRequest?, handAtFit: Bool, frame: TableFrame,
               reduceMotion: Bool) -> MomentFocus? {
        let now = ProcessInfo.processInfo.systemUptime
        let dt = min(0.1, max(0, now - (lastTick ?? now)))
        lastTick = now
        // A Replay from the start eases in rather than cutting straight to the strike's close-up.
        if clock < 0.05, lastClock > 0.3 { gate = 0 }
        lastClock = clock
        let allowed = (request?.allowed ?? false) && !reduceMotion && !Self.off
        if !handAtFit || reduceMotion || Self.off {
            // The hand has the view (it adopted the moment's, so dropping this at once does not jump), or no glide.
            gate = 0
        } else if Self.motionOff {
            gate = allowed ? 1 : 0
        } else if allowed {
            gate = min(1, gate + dt / Self.gateTime)
        } else {
            gate = max(0, gate - dt / Self.gateTime)
        }
        guard gate > 0, let plan = request?.plan,
              var focus = MomentFraming.shape(at: clock, plan: plan, frame: frame) else { return nil }
        focus.weight *= Float(MomentFraming.smooth(gate))
        return focus.weight > 1e-4 ? focus : nil
    }
}
