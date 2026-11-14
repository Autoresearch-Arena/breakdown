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
// SRP/DRY check: Pass - checked TableStage and TableCamera, which project world points to the screen for the caption
//          ring; that goes one way only and lives in a closure inside the 3D view, so the other way (screen to table)
//          is done here from the camera entity itself. Table/world conversion stays in TableFrame.
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

enum AimGeometry {
    /// First object ball hit by a cue ball of radius `radius` that starts at `from` and travels along the unit
    /// vector `direction`. `layout` is the resting positions with index 0 the cue ball; a ball parked off the table
    /// is skipped. Nil when the path reaches a cushion first.
    static func firstContact(layout: [Vec2], from: Vec2, direction: Vec2, radius: Double) -> AimContact? {
        var best: (t: Double, ball: Int)?
        let touch = 2 * radius
        for i in 1..<max(1, layout.count) where NextShot.isOnTable(layout[i]) {
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
}
