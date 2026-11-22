// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream drawings, bug list #15, #16, #17, #65: LensMarkFloor at the
//          end of this file, the screen-size floors every Lens mark keeps on a phone (lines at least 2 points wide,
//          arrowheads at least 8 points, the contact lines reaching 40 points either side, throw lines long enough that
//          a one-degree throw opens 6 points at the far end). Pure maths on a points-per-metre figure, so the unit tests
//          can pin it; LensLayer reads the figure from the table camera.)
// PURPOSE: The geometry of one ball-to-ball hit, read from its recorded Lens event, for the Lens drawing of a held hit
//          (plans/22-Nov-2026-v074-glow-up-plan.md, feature G2, stream lens-drawing). Given a ball-to-ball event it
//          says where the balls touched, the line of centres (from the striking ball into the struck one) and the
//          tangent line across it, which ball struck which, and the three speeds of the momentum triangle: the striking
//          ball's velocity in, the struck ball's velocity out and the striking ball's velocity out. With equal masses and
//          the struck ball at rest, momentum makes the first the sum of the other two, so drawn head to tail they close
//          into a triangle, throw and restitution included (the solver's impulse is equal and opposite on the two balls).
//          It also says whether the two outgoing paths are square (within two degrees of a right angle), the textbook
//          stun hit. Note on that mark: the solver's balls are not perfectly elastic (restitution 0.95) and grip each
//          other a little (throw), so at the instant of contact the striking ball keeps a small part of its speed along
//          the line of centres; a half-ball stun cut comes out about 85 degrees, and only thinner cuts land inside two
//          degrees. The mark is therefore rare and always true, as the plan's "drawn by the true solver" asks.
//          Pure: no RealityKit, no model. Read by LensLayer each frame a hit is held (LensLayer.heldEvent) and by
//          BreakdownTests/LensContactGeometryTests.
//          LensMarkFloor (0.7.6) is the other pure half of the Lens marks' layout: how much larger than its table size a
//          mark must be drawn so it stays readable on screen.
// SRP/DRY check: Pass - checked CaptionEngine.throwFacts (the throw caption and the throw lines: it finds the ball at
//          rest the same way and its rest speed, CaptionEngine.restSpeed, is reused here so the words and the drawing
//          agree on what "at rest" means) and AimGeometry (the aim guide's predicted paths before a shot; this reads a
//          recorded hit after it). Nothing else derives the contact frame of a recorded event.
import BreakdownLensModel
import Foundation

/// One ball-to-ball contact laid out for drawing. Every vector is in the table plan (metres, or metres per second),
/// the same frame as the event.
struct ContactGeometry: Equatable {
    /// Where the two balls touched (the event's point: midway between the centres, which is the contact for equal balls).
    let point: Vec2
    /// Unit line of centres, pointing from the striking ball into the struck one.
    let normal: Vec2
    /// Unit tangent at the contact: the line of centres turned a quarter counter-clockwise.
    let tangent: Vec2
    /// The striking ball (the faster one before the hit) and the struck one.
    let striker: Int
    let object: Int
    /// The striking ball's velocity coming in, and both balls' velocities going out.
    let incoming: Vec2
    let strikerOut: Vec2
    let objectOut: Vec2
    /// True when the struck ball was already moving (at least CaptionEngine.restSpeed): then the momentum triangle
    /// does not close on the striking ball's speed alone, so only the two lines are drawn.
    let objectWasMoving: Bool
    /// True when the struck ball was at rest, both balls leave faster than `rightAngleMinSpeed` and their outgoing
    /// directions are within `rightAngleTolerance` degrees of square.
    let rightAngle: Bool

    /// How close to 90 degrees the two outgoing paths must be for the right-angle mark, degrees (the plan's two).
    static let rightAngleTolerance = 2.0
    /// Both balls must leave faster than this, m/s, for their angle to mean anything (a ball left almost still, as on
    /// a stop shot, has no direction worth squaring).
    static let rightAngleMinSpeed = 0.05

    /// The geometry of a ball-to-ball event, or nil for any other event, for one that does not name two balls, or for
    /// one where neither ball was moving (nothing struck anything).
    static func at(_ e: LensEvent) -> ContactGeometry? {
        guard e.kind == .ballBall, e.balls.count == 2 else { return nil }
        let a = e.balls[0], b = e.balls[1]
        // The striker is the faster ball before the hit. The recorded normal points from balls[0] to balls[1], so it is
        // turned round when the second ball is the striker (the same convention throwFacts reads).
        let aStrikes = a.velocityBefore.length >= b.velocityBefore.length
        let striker = aStrikes ? a : b
        let object = aStrikes ? b : a
        guard striker.velocityBefore.length > 1e-9 else { return nil }
        let n = (aStrikes ? e.normal : -e.normal).normalized
        guard n.length > 0.5 else { return nil }
        let moving = object.velocityBefore.length >= CaptionEngine.restSpeed
        let sOut = striker.velocityAfter, oOut = object.velocityAfter
        var square = false
        if !moving, sOut.length > rightAngleMinSpeed, oOut.length > rightAngleMinSpeed {
            // Angle between the two outgoing directions, from their normalised dot product (clamped against rounding).
            let c = max(-1, min(1, sOut.normalized.dot(oOut.normalized)))
            square = abs(acos(c) * 180 / .pi - 90) <= rightAngleTolerance
        }
        return ContactGeometry(point: e.point, normal: n, tangent: n.perp, striker: striker.ball, object: object.ball,
                               incoming: striker.velocityBefore, strikerOut: sOut, objectOut: oOut,
                               objectWasMoving: moving, rightAngle: square)
    }
}

/// Screen-size floors for the Lens marks (0.7.6 stream drawings; plans/22-Nov-2026-phone-bug-hunt.md #15, #16, #17, #65).
/// Every Lens mark is built in table metres, which reads well in a large window but comes out under a point wide on an
/// upright phone, where the whole table is about 150 points per metre. LensLayer asks the table camera how many screen
/// points one metre covers at the mark's place (TableCamera.pointsPerMetre) and these functions say how much larger the
/// mark must be drawn. They only ever grow a mark (a large window keeps its table sizes exactly), and with no figure
/// (nil: the scrub check and unit tests, which have no camera) they change nothing, so the clock-only fingerprint holds.
/// Pure: no RealityKit, no model.
enum LensMarkFloor {
    /// The thinnest any drawn line may be, screen points (the plan's 2).
    static let line: Float = 2
    /// The shortest any arrowhead may be, screen points (the plan's 8).
    static let head: Float = 8
    /// How far the contact drawing's line of centres and tangent reach either side of the contact, at least, in screen
    /// points: 40 either side clears the 20-point caption ring, so the lines are never lost inside it.
    static let contactReach: Float = 40
    /// Throw lines: at least this long on screen, points; and for a throw of a degree or more, long enough that the far
    /// ends of the two lines stand `throwGap` points apart, but never longer than `throwLongest` (a throw of exactly one
    /// degree needs about 344 points, so the cap only bites just under a degree, where nothing is promised).
    static let throwLength: Float = 90
    static let throwGap: Float = 6
    static let throwLongest: Float = 360
    /// The smallest throw, degrees, that the far-end gap is promised for.
    static let throwGapFrom = 1.0
    /// Jump mark: the ring on the ball's ground spot clears the drawn ball by at least this many points, plus up to
    /// `jumpGrowth` more as the ball climbs to two radii up, so its edge stays visible from straight above.
    static let jumpGap: Float = 4
    static let jumpGrowth: Float = 8
    /// The most a floor may enlarge a mark. A safety cap: on an upright phone the largest floor needed is about five
    /// times (the throw lines); only a point far from the camera in the Ride view could ask for more, and there a mark
    /// many times its size would read as something else.
    static let maxScale: Float = 6

    /// A usable points-per-metre figure, or nil (behind the camera, not a number, or none given).
    static func usable(_ pointsPerMetre: Float?) -> Float? {
        guard let ppm = pointsPerMetre, ppm.isFinite, ppm > 1e-3 else { return nil }
        return ppm
    }

    /// The factor a part `natural` metres across must be scaled by to be at least `points` on screen: 1 when it is
    /// already that large or when there is no figure, never more than `maxScale`.
    static func scale(natural: Float, points: Float, pointsPerMetre: Float?) -> Float {
        guard let ppm = usable(pointsPerMetre), natural > 0 else { return 1 }
        return min(maxScale, max(1, points / (natural * ppm)))
    }

    /// The length, metres, of the two throw lines (the dashed line of centres and the solid departure, drawn from the
    /// struck ball's centre `degrees` apart): never shorter than `natural`, at least `throwLength` points on screen,
    /// and for a throw of `throwGapFrom` degrees or more long enough that the far ends are `throwGap` points apart.
    /// Only the length changes, never the angle: the lines always part at the true throw.
    static func throwLineLength(natural: Float, degrees: Double, pointsPerMetre: Float?) -> Float {
        guard let ppm = usable(pointsPerMetre) else { return natural }
        var points = throwLength
        // The chord between the far ends of two lines L long, an angle a apart, is 2 L sin(a / 2).
        let halfAngle = Float(abs(degrees) * .pi / 360)
        if abs(degrees) >= throwGapFrom, sin(halfAngle) > 1e-6 {
            points = max(points, throwGap / (2 * sin(halfAngle)))
        }
        points = min(points, throwLongest)
        return min(natural * maxScale, max(natural, points / ppm))
    }
}
