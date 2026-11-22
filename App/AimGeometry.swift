// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: The maths behind "aim by touching the table", with no drawing and no model writes. Two parts.
//          (1) AimGeometry: a plain ray cast over ball centres that answers "if the cue ball goes this way, what does
//          it hit first?". It finds the first object ball whose centre comes within two ball radii of the cue ball's
//          path (the "ghost ball" is the cue ball's centre at that instant), where the object ball will leave, and
//          where the cue ball veers off (the right-angle rule for a ball struck without spin). When nothing is hit
//          it finds where the path meets the cushion. This is a guide for the player, not the physics: the solver
//          in BreakdownPhysics still decides what really happens, and nothing here changes it.
//          (2) AimProjector: the camera maths that turns a touch on the screen into a spot on the table (and a spot on
//          the table back into a screen point for drawing). It reads the live camera entity out of the scene, so it is
//          always the camera the player is looking through, including mid-melt, in portrait and in landscape, with
//          no copy of the framing numbers to drift out of date. The ray goes from the camera through the touch and is
//          cut by the plane at ball-centre height.
//          Used by AimOverlay (gesture and drawing) and by nothing else.
//          (3) launchDirection: where the struck ball really goes once side spin has pushed it off the cue's line, read
//          from the solver's own launch function, so the drawn guide bends exactly as the physics will.
// Edited: Claude Opus 5.5 High, 21-November-2026 (launchDirection, so the guide line bends with side spin on the new
//          physics generation; the overlay draws from it instead of from the bare aim).
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens, other-tables plan package 1 step 4: on the small
//          tables the guide stops at the first thing it meets. firstContact now skips the striking ball by where it
//          sits, not by being ball 0, so on five-pin and bumper pool the other player's ball (often ball 0) is seen;
//          obstacleDistance finds the first bumper, standing pin or bed hole on the path, which the overlay stops at.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, gauges-pointer stream, items 24, 31 and 50 of
//          plans/21-Nov-2026-bugs-after-0-6-6-plan.md):
//          (4) guideLine / guideContact: the one answer for "what does the guide show the striking ball meeting first",
//          along the launch direction (side-spin push included) and stopped at the first cushion, bumper, pin or hole,
//          exactly as the overlay draws it. The target badge, the spoken aim and Aim to pot use it too (item 50), so a
//          sighted player and a VoiceOver player are told about the same ball. cueAim(forLaunch:) is its inverse: the
//          cue aim that sends the ball along a wanted line, so Aim to pot can allow for the push.
//          (5) fork / AimFork: when side spin turns the ball half a degree or more off the cue's line, the two lines
//          the overlay draws as a labelled fork, with their words (item 24).
//          (6) solvedImpact: at full assist, where the object ball really leaves (throw included) and where the cue
//          ball heads, read from a two-ball trial solve by the solver itself, remembered until the shot changes.
//          (7) AimProjector.turnSign: which way a counter-clockwise turn on the table looks on screen, shared by the
//          pointer's scroll (PointerAim) so it turns the line the way the arrow keys do (item 31).
// SRP/DRY check: Pass - checked TableStage and TableCamera, which project world points to the screen for the caption
//          ring; that goes one way only and lives in a closure inside the 3D view, so the other way (screen to table)
//          is done here from the camera entity itself. Table/world conversion stays in TableFrame. guideLine is the
//          overlay's own stop-and-contact rule moved here, not a second copy; the throw comes from PoolSolver itself
//          (its impact routine is internal to the package), not from re-deriving the friction maths in the app.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import CoreGraphics
import Foundation
import RealityKit
import simd

// MARK: Ray cast

/// What the cue ball meets first on its way along an aim direction.
struct AimContact {
    /// Where the cue ball's centre is at the moment it touches the object ball (the "ghost ball").
    var ghost: Vec2
    /// Ball number of the object ball, and where its centre is.
    var ball: Int
    var target: Vec2
    /// Unit direction the object ball leaves in (along the line of centres).
    var objectDirection: Vec2
    /// Unit direction the cue ball veers to afterwards, or nil for a head-on hit where it stops dead.
    var cueDirection: Vec2?
    /// 0 for head-on, 1 for a grazing cut: how much of the cue ball's speed carries on sideways.
    var cut: Double
}

/// The guide along one direction from the striking ball (AimGeometry.guideLine).
struct GuideLine {
    /// Where the striking ball starts and the unit direction it travels (the launch direction for the model's shot).
    var origin: Vec2
    var direction: Vec2
    /// How far the ball's centre travels before a cushion, bumper, standing pin or hole stops the line, metres.
    var stop: Double
    /// The first ball met before that stop, if any.
    var contact: AimContact?
    /// Where the line ends, metres from the origin: at the ghost ball when a ball is met, else at the stop.
    var reach: Double { contact.map { ($0.ghost - origin).length } ?? stop }
}

/// The cue's line and the ball's line when side spin pushes the ball off the cue's line (item 24). Drawn by the aiming
/// layer as a fork from the cue ball, each prong labelled.
struct AimFork: Equatable, Sendable {
    /// Unit: where the cue points.
    let cueLine: Vec2
    /// Unit: where the ball leaves.
    let ballLine: Vec2
    /// Signed turn from the cue's line to the ball's, degrees, + counter-clockwise on the table plan (to the shooter's
    /// left).
    let turnDegrees: Double

    /// The words on the cue's prong.
    static var cueLabel: String { String(localized: "Cue aims here") }
    /// The words on the ball's prong.
    static var ballLabel: String { String(localized: "Ball goes here") }
    /// How far and which way side spin turns the ball, for beside the ball's prong ("2.4° left"), as the shooter sees it
    /// standing behind the cue.
    var turnWords: String {
        let degrees = abs(turnDegrees).formatted(.number.precision(.fractionLength(1)))
        return turnDegrees > 0 ? String(localized: "\(degrees)° left") : String(localized: "\(degrees)° right")
    }
}

/// What the solver says happens at the first impact of the next shot (AimGeometry.solvedImpact).
struct ImpactPreview: Equatable {
    /// Unit direction the object ball really leaves in: the line of centres turned by throw.
    let objectDirection: Vec2
    /// Unit direction the striking ball heads off in just after the impact; nil when it is left almost still.
    let cueDirection: Vec2?
    /// Unit line of centres at the solver's contact, from the striking ball to the object ball: where the object ball
    /// would go with no friction at the contact.
    let lineOfCentres: Vec2
    /// Signed degrees from the line of centres to the object ball's departure, + counter-clockwise: the throw.
    let throwDegrees: Double
}

/// The last two-ball trial solve and what it gave, so the overlay's every-frame drawing solves only when the shot changes.
@MainActor
private enum ImpactMemo {
    struct Key: Equatable {
        let positions: [Vec2]
        let direction: Vec2
        let speed: Double
        let tipUp: Double
        let tipSide: Double
        let elevation: Double
        let striker: Int
        let target: Int
        let table: TableKind
        let surface: PlaySurface
        let generation: Int
    }
    static var last: (key: Key, value: ImpactPreview?)?
}

enum AimGeometry {
    /// First object ball hit by a cue ball of radius `radius` that starts at `from` and travels along the unit
    /// vector `direction`. `layout` is the resting positions; the striking ball is the one sitting at `from` (ball 0
    /// on the pool table, a player's own ball on five-pin and bumper pool) and is skipped, as is a ball parked off the
    /// table. Nil when the path reaches a cushion first.
    static func firstContact(layout: [Vec2], from: Vec2, direction: Vec2, radius: Double) -> AimContact? {
        var best: (t: Double, ball: Int)?
        let touch = 2 * radius
        // Two balls can never rest closer than touching, so anything within a micrometre of `from` is the striker.
        for i in layout.indices where NextShot.isOnTable(layout[i]) && (layout[i] - from).lengthSquared > 1e-12 {
            let c = layout[i] - from
            let along = c.dot(direction)
            if along <= 0 { continue }                         // behind the cue ball
            let perpSquared = c.lengthSquared - along * along
            if perpSquared >= touch * touch { continue }       // passes wide of this ball
            // Back off from the closest approach to the point where the two circles first touch.
            let t = along - (touch * touch - perpSquared).squareRoot()
            if t < 0 { continue }                              // already overlapping: not a shot at this ball
            if best == nil || t < best!.t { best = (t, i) }
        }
        guard let hit = best else { return nil }
        let ghost = from + direction * hit.t
        let target = layout[hit.ball]
        let normal = (target - ghost).normalized
        // Right-angle rule: without spin the cue ball leaves at 90 degrees to the object ball's path.
        let side = direction - normal * direction.dot(normal)
        let cut = min(1, side.length)
        return AimContact(ghost: ghost, ball: hit.ball, target: target, objectDirection: normal,
                          cueDirection: cut > 0.04 ? side.normalized : nil, cut: cut)
    }

    /// The direction the struck ball will really leave in, so the guide line bends with side spin the way the ball will
    /// (cue-strike plan, step 6). It asks the solver's own function (PoolSolver.launchDirection), so guide and physics
    /// cannot disagree: on generation 1 it is the aim itself; on generation 2 side spin turns it away from the struck
    /// side by about two and a half degrees at a half-radius offset. A miscue's turn is random and unknowable before the
    /// shot, so past the grip limit the guide shows the cue's own line.
    static func launchDirection(aim: Vec2, tipUp: Double, tipSide: Double,
                                parameters: PoolParameters = PoolParameters()) -> Vec2 {
        PoolSolver.launchDirection(for: CueStrike(direction: aim, speed: 1, tipUp: tipUp, tipSide: tipSide),
                                   parameters: parameters)
    }

    /// The same for the model's next shot: its aim and tip, on the table it is played on (ball size and mass set how
    /// far side spin pushes the ball) and the physics generation the next solve will use.
    @MainActor
    static func launchDirection(for model: ShowpieceModel) -> Vec2 {
        launchDirection(aim: model.aimDirection, tipUp: model.activeTipUp, tipSide: model.activeTipSide,
                        parameters: launchParameters(for: model))
    }

    /// The parameters the launch is worked out with: the table's (ball size and mass) at the generation the next solve
    /// uses. The cloth does not change the push, so the surface is left out.
    @MainActor
    private static func launchParameters(for model: ShowpieceModel) -> PoolParameters {
        var p = model.physicsTable.parameters
        p.modelGeneration = model.activeModelGeneration
        return p
    }

    /// The cue aim that sends the struck ball along `launch`: the side-spin push undone. The push turns the ball by
    /// the same angle whatever the aim (it depends on the tip alone, PoolSolver.turned), so turning the wanted line back
    /// by that angle is exact. For Aim to pot (item 50): the ghost-ball line is where the ball must go, this is where
    /// the cue must point.
    static func cueAim(forLaunch launch: Vec2, tipUp: Double, tipSide: Double,
                       parameters: PoolParameters = PoolParameters()) -> Vec2 {
        let want = launch.normalized
        guard want.lengthSquared > 0.5 else { return launch }
        let bent = launchDirection(aim: want, tipUp: tipUp, tipSide: tipSide, parameters: parameters)
        // cos and sin of the push's turn (counter-clockwise positive), then the wanted line turned back by it.
        let c = want.dot(bent), s = want.x * bent.y - want.y * bent.x
        return Vec2(c * want.x + s * want.y, -s * want.x + c * want.y).normalized
    }

    /// The same for the model's next shot, with its tip and table.
    @MainActor
    static func cueAim(forLaunch launch: Vec2, for model: ShowpieceModel) -> Vec2 {
        cueAim(forLaunch: launch, tipUp: model.activeTipUp, tipSide: model.activeTipSide,
               parameters: launchParameters(for: model))
    }

    // MARK: What the guide shows (item 50)

    /// The guide along one direction from the striking ball: how far the line runs before the first cushion, bumper,
    /// standing pin or hole stops it, and the first ball it meets before that (nil when the stop comes first).
    static func guideLine(layout: [Vec2], origin: Vec2, direction: Vec2, table: TableSpec) -> GuideLine {
        // On the small tables a bumper, a standing pin or a hole can come first: the line stops there, and a ball behind
        // it is not the contact (other-tables plan package 1 step 4). On the pool table only the cushion can stop it.
        let stop = min(cushionDistance(from: origin, direction: direction, table: table),
                       obstacleDistance(from: origin, direction: direction, table: table) ?? .greatestFiniteMagnitude)
        let contact = firstContact(layout: layout, from: origin, direction: direction, radius: table.ballRadius)
            .flatMap { ($0.ghost - origin).length <= stop ? $0 : nil }
        return GuideLine(origin: origin, direction: direction, stop: stop, contact: contact)
    }

    /// The guide for the model's next shot: from the striking ball along the launch direction (the aim bent by side
    /// spin, launchDirection(for:)). Nil when there is no shot to guide (no full layout, the striking ball off the
    /// table). Independent of the Aim guide option on purpose: that option only hides drawing, and the spoken aim and
    /// the badge still need the answer.
    @MainActor
    static func guideLine(for model: ShowpieceModel) -> GuideLine? {
        guard model.layout.count == 16, NextShot.isOnTable(model.aimOrigin) else { return nil }
        let direction = launchDirection(for: model)
        guard direction.lengthSquared > 0.5 else { return nil }
        return guideLine(layout: model.layout, origin: model.aimOrigin, direction: direction, table: model.timeline.table)
    }

    /// What the guide shows the striking ball hitting first, along the launch direction (side-spin push included) and
    /// short of any cushion, bumper, pin or hole: one answer for the guide (AimOverlay), the target badge
    /// (TargetBallBadge), the spoken aim and Aim to pot (TableWords, AimOverlay's actions). Item 50.
    @MainActor
    static func guideContact(for model: ShowpieceModel) -> AimContact? {
        guideLine(for: model)?.contact
    }

    // MARK: The side-spin fork (item 24)

    /// The smallest turn, in degrees, that is drawn as a fork. The plan's figure (item 24): half a degree carried two
    /// metres up the table is about 17 mm, more than half a ball's radius, enough to turn a pot into a miss, while a
    /// smaller turn would draw two prongs too close together to tell apart on a phone.
    static let forkThresholdDegrees = 0.5

    /// The cue's line and the ball's line when side spin turns the ball half a degree or more off the cue's line
    /// (squirt), for the overlay to draw as a labelled fork; nil below that, on generation one (no push), and for a
    /// miscue (its turn cannot be known before the shot, so the ball's line is the cue's). From the solver's own launch
    /// function, so the prong is where the ball will really go.
    static func fork(aim: Vec2, tipUp: Double, tipSide: Double, elevation: Double,
                     parameters: PoolParameters) -> AimFork? {
        let cue = aim.normalized
        guard cue.lengthSquared > 0.5 else { return nil }
        let strike = CueStrike(direction: cue, speed: 1, tipUp: tipUp, tipSide: tipSide, elevation: elevation)
        let ball = PoolSolver.launchDirection(for: strike, parameters: parameters)
        // Signed angle from the cue's line to the ball's: positive counter-clockwise on the table plan.
        let turn = atan2(cue.x * ball.y - cue.y * ball.x, cue.dot(ball)) * 180 / Double.pi
        guard abs(turn) >= forkThresholdDegrees else { return nil }
        return AimFork(cueLine: cue, ballLine: ball, turnDegrees: turn)
    }

    /// The fork for the model's next shot: its aim, tip and cue angle (strikeElevation), on its table and generation.
    @MainActor
    static func fork(for model: ShowpieceModel) -> AimFork? {
        fork(aim: model.aimDirection, tipUp: model.activeTipUp, tipSide: model.activeTipSide,
             elevation: model.strikeElevation, parameters: launchParameters(for: model))
    }

    // MARK: The solver's own impact (item 24, full assist)

    /// Event budget for the two-ball trial solve. Only the first impact is read, but the public solve only returns a
    /// recording once every ball is at rest. Two balls on their own reach rest in a few dozen events (each cushion,
    /// each slide-to-roll change; an estimate from the event kinds, not a measurement), so this leaves room for a hard
    /// shot round the table several times; a solve that needs more is not worth spending a frame on, and the guide
    /// then falls back to the line of centres.
    private static let impactEventBudget = 400

    /// At full assist: where the object ball really leaves and where the striking ball heads, from the solver's own
    /// ball-to-ball impact, so the drawn object-ball line includes throw (the friction at contact drags a soft cut off
    /// the line of centres by up to about five degrees). The strike is the model's next one (aim, launch speed for the
    /// cue in hand, tip, cue angle), solved on the table, cloth and generation the real shot will use, with only the two
    /// balls on the table: the first impact is the same unless a third ball already touches the object ball. Nil for a
    /// break (the rack's frozen balls share the impact), for a miscue (its turn is random, as launchDirection says),
    /// when the solver's first impact is not with `contact.ball` (a swerving raised cue can bend onto another line), or
    /// when the trial runs past its budget. The answer is remembered until any input changes, because the overlay draws
    /// every frame.
    @MainActor
    static func solvedImpact(for model: ShowpieceModel, contact: AimContact) -> ImpactPreview? {
        guard !model.racked, model.layout.count == 16, model.layout.indices.contains(contact.ball) else { return nil }
        let striker = model.strikeBall
        guard striker != contact.ball, model.layout.indices.contains(striker) else { return nil }
        let p = model.matchSolveParameters
        let up = model.activeTipUp, side = model.activeTipSide
        if p.usesGenerationTwo, up * up + side * side > p.miscueOffsetLimit * p.miscueOffsetLimit { return nil }
        var positions = [Vec2](repeating: NextShot.offTable, count: model.layout.count)
        positions[striker] = model.layout[striker]
        positions[contact.ball] = model.layout[contact.ball]
        let strike = CueStrike(direction: model.aimDirection, speed: model.cueInHand.launchSpeed(forPower: model.activePower),
                               tipUp: up, tipSide: side, elevation: model.strikeElevation, ballIndex: striker)
        let key = ImpactMemo.Key(positions: positions, direction: strike.direction, speed: strike.speed, tipUp: up,
                                 tipSide: side, elevation: strike.elevation, striker: striker, target: contact.ball,
                                 table: model.physicsTable, surface: model.physicsSurface,
                                 generation: model.activeModelGeneration)
        if let memo = ImpactMemo.last, memo.key == key { return memo.value }
        let value = trialImpact(ShotInput(parameters: p, positions: positions, strike: strike, seed: 0),
                                striker: striker, target: contact.ball)
        ImpactMemo.last = (key, value)
        return value
    }

    /// Solve the two-ball trial and read its first ball-to-ball impact.
    private static func trialImpact(_ input: ShotInput, striker: Int, target: Int) -> ImpactPreview? {
        guard let timeline = PoolSolver.simulate(input, eventBudget: impactEventBudget),
              let hit = timeline.events.first(where: { $0.kind == .ballBall }),
              let objectBall = hit.balls.first(where: { $0.ball == target }),
              let cueBall = hit.balls.first(where: { $0.ball == striker }) else { return nil }
        let object = objectBall.velocityAfter.normalized
        guard object.lengthSquared > 0.5 else { return nil }
        // The event's normal points from its first ball to its second; the line of centres the object ball would take
        // without friction points from the striker to the target.
        let centres = hit.balls.first?.ball == striker ? hit.normal : hit.normal * -1
        let throwDegrees = atan2(centres.x * object.y - centres.y * object.x, centres.dot(object)) * 180 / Double.pi
        let cue = cueBall.velocityAfter
        // A striking ball left with almost no speed (a stop shot) has no direction worth drawing: a millimetre a second.
        let cueDirection = cue.length > 0.001 ? cue.normalized : nil
        return ImpactPreview(objectDirection: object, cueDirection: cueDirection, lineOfCentres: centres.normalized,
                             throwDegrees: throwDegrees)
    }

    /// Distance the striking ball's centre can travel from `from` along `direction` before it meets one of the small
    /// tables' fixed things: a bumper post or a standing pin (touching at the solver's contact distance, ball radius
    /// plus post or pin radius), or a bed hole or cup (its centre crossing the hole's capture radius, where the solver
    /// drops it). Nil when nothing is in the way; always nil on the pool table, which has none of these.
    static func obstacleDistance(from: Vec2, direction: Vec2, table: TableSpec) -> Double? {
        let r = table.ballRadius
        var best: Double?
        /// The distance along the path at which the centre first comes within `reach` of `c`, if it ever does ahead.
        func enters(_ c: Vec2, reach: Double) {
            let d = c - from
            let along = d.dot(direction)
            if along <= 0 { return }                                  // behind the ball
            let perpSquared = d.lengthSquared - along * along
            if perpSquared >= reach * reach { return }                // passes wide
            let t = along - (reach * reach - perpSquared).squareRoot()
            if t < 0 { return }                                       // already inside: the ball starts there
            if best == nil || t < best! { best = t }
        }
        for post in table.posts { enters(post.center, reach: r + post.radius) }
        for pin in table.pins { enters(pin.center, reach: r + pin.radius) }
        for hole in table.bedHoles { enters(hole.center, reach: hole.captureRadius) }
        return best
    }

    /// Distance the cue ball's centre can travel from `from` along `direction` before it reaches a cushion.
    static func cushionDistance(from: Vec2, direction: Vec2, table: TableSpec) -> Double {
        var best = Double.greatestFiniteMagnitude
        let r = table.ballRadius
        if direction.x > 1e-9 { best = min(best, (table.length - r - from.x) / direction.x) }
        if direction.x < -1e-9 { best = min(best, (r - from.x) / direction.x) }
        if direction.y > 1e-9 { best = min(best, (table.width - r - from.y) / direction.y) }
        if direction.y < -1e-9 { best = min(best, (r - from.y) / direction.y) }
        return max(0, best)
    }
}

// MARK: Camera projection

/// Converts between screen points (in the 3D view's own space) and table positions, using the camera the scene is
/// really rendered with. Built fresh for every use, because the camera moves with the melt.
@MainActor
struct AimProjector {
    private let toWorld: simd_float4x4
    private let toCamera: simd_float4x4
    private let size: CGSize
    private let tanHalf: Float
    private let frame: TableFrame

    /// The camera entity in a scene, found once and kept. Looking for it walks the whole scene, which is wasted work
    /// every frame, so the overlay keeps one of these.
    @MainActor
    final class CameraBox {
        var camera: PerspectiveCamera?
        func find(in root: Entity) -> PerspectiveCamera? {
            if let camera { return camera }
            camera = Self.search(root)
            return camera
        }
        private static func search(_ e: Entity) -> PerspectiveCamera? {
            if let c = e as? PerspectiveCamera { return c }
            for child in e.children { if let c = search(child) { return c } }
            return nil
        }
    }

    /// Nil before the scene exists or while the view has no size.
    init?(camera: PerspectiveCamera?, size: CGSize, frame: TableFrame) {
        guard let camera, size.width > 1, size.height > 1 else { return nil }
        toWorld = camera.transformMatrix(relativeTo: nil)
        toCamera = toWorld.inverse
        // The camera's field of view is vertical (RealityKit's default), which is also what the HUD maths in
        // TableCamera assumes.
        tanHalf = tan(camera.camera.fieldOfViewInDegrees * .pi / 360)
        self.size = size
        self.frame = frame
    }

    private var aspect: Float { Float(size.width / size.height) }

    /// Where a table position (at `height` metres above the cloth) lands on the screen; nil if behind the camera.
    func screen(_ p: Vec2, height: Float? = nil) -> CGPoint? {
        let world = frame.world(p, height: height ?? frame.ballRadius)
        let c = toCamera * SIMD4<Float>(world, 1)
        let depth = -c.z
        guard depth > 0.01 else { return nil }
        let nx = c.x / depth / (tanHalf * aspect)
        let ny = c.y / depth / tanHalf
        return CGPoint(x: CGFloat((nx + 1) / 2) * size.width, y: CGFloat((1 - ny) / 2) * size.height)
    }

    /// The table position under a screen point, on the plane through the balls' centres; nil if the touch is above
    /// the horizon or otherwise misses the plane.
    func table(at point: CGPoint) -> Vec2? {
        let nx = Float(point.x / size.width) * 2 - 1
        let ny = 1 - Float(point.y / size.height) * 2
        let dirCamera = SIMD4<Float>(nx * tanHalf * aspect, ny * tanHalf, -1, 0)
        let d4 = toWorld * dirCamera
        let dir = SIMD3<Float>(d4.x, d4.y, d4.z)
        let origin = SIMD3<Float>(toWorld.columns.3.x, toWorld.columns.3.y, toWorld.columns.3.z)
        guard dir.y < -1e-5 else { return nil }
        let t = (frame.ballRadius - origin.y) / dir.y
        guard t > 0 else { return nil }
        let hit = origin + dir * t
        // The inverse of TableFrame.world: x runs along the table, the solver's y is minus the world z.
        return Vec2(Double(hit.x + frame.length * 0.5), Double(frame.width * 0.5 - hit.z))
    }

    /// +1 when turning the aim counter-clockwise on the table plan also turns the line counter-clockwise on the screen,
    /// -1 when the camera views the table the other way round (portrait swings it a quarter turn, and a low camera can
    /// look from the far end). Multiply a "turn anticlockwise as the player sees it" step by this before handing it to
    /// ShowpieceModel.nudgeAim, as the arrow keys do. Worked out from a short turn of the line at `origin`: half a metre
    /// out and two degrees round, big enough to land on different screen points from any camera that shows the table.
    /// +1 when the line cannot be projected (behind the camera), the table plan's own sense.
    func turnSign(origin: Vec2, direction: Vec2) -> Double {
        let d = direction.normalized
        guard d.lengthSquared > 0.5 else { return 1 }
        let a = 2.0 * Double.pi / 180
        let turned = Vec2(cos(a) * d.x - sin(a) * d.y, sin(a) * d.x + cos(a) * d.y)
        guard let s0 = screen(origin), let s1 = screen(origin + d * 0.5), let s2 = screen(origin + turned * 0.5) else {
            return 1
        }
        // Screen y points down, so a negative cross product is a counter-clockwise turn as seen.
        let cross = (s1.x - s0.x) * (s2.y - s0.y) - (s1.y - s0.y) * (s2.x - s0.x)
        return cross < 0 ? 1 : -1
    }
}
