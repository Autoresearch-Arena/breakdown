// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The per-frame parts of the warm table's look that depend on the camera or on where the balls are (look plan
//          packages 1, 2 and 3), kept out of TableScene so that file stays a thin coordinator:
//            - A soft contact shadow under every ball: a dark round patch on the cloth that is small and strong while
//              the ball sits on the cloth and spreads and fades as it rises in a jump, so it visibly tightens as the
//              ball lands. It is a function of the ball's recorded height alone, so scrubbing shows the same shadow.
//            - The lamp shade fades out as the camera rises toward it, so from the low Ride views it hangs over the
//              table, lit from inside, and from the normal views above it never blocks the table.
//            - The ball pictures: below a measured on-screen size every ball wears its high-contrast picture
//              (BallTextures, compact), above it the normal one; the size is the camera's points-per-metre at its
//              look point times the ball's diameter, with a gap between the two switch points so it never flickers.
//          Integration: TableScene owns one, adds `root` under the warm table group each time the table is built (so
//          the shadows fade with the table in the Lens) and calls attach, ball(...) for each ball every frame, and
//          view(...) after the camera has moved.
// SRP/DRY check: Pass - checked TableScene (ball placement stays there; this only reads the placed values),
//          TableBuilder (the shadow material and ball material are its; reused here) and TableCamera (it measures,
//          this decides). No camera or ball motion logic lives here.
import Foundation
import RealityKit
import simd

@MainActor
final class TableDetail {
    /// Parent of the contact shadows; TableScene adds it under the warm table group.
    let root = Entity()
    private var shadows: [ModelEntity] = []
    /// The lamp shade's holder (TableRoom names it), found again after every rebuild of the table.
    private weak var shade: Entity?
    private var shadeOpacity: Float = -1

    /// The ball bodies and the two sets of materials they can wear.
    private let bodies: [ModelEntity]
    private let standard: [[any Material]]
    private var compact: [PhysicallyBasedMaterial]?
    private var wearingCompact = false

    /// A ball smaller than this on screen (diameter, points) switches to the high-contrast picture, and one larger than
    /// `compactOff` switches back. Why 26: the number disc is a little over half the ball's width and the numeral about
    /// two thirds of the disc, so at 26 points the numeral is about 9 points tall, the size below which plain digits
    /// stop being readable at arm's length; the high-contrast picture's larger disc keeps it near 11.
    static let compactOn: Float = 26
    static let compactOff: Float = 32

    /// Contact shadow, at rest: a patch 4 ball radii across, at most this dark in its middle. The soft spot picture
    /// fades as (1 - d) squared from its centre, so with the patch twice the ball's width the ball's own edge falls at
    /// half way out, where the shadow is still about a fifth dark: a soft dark ring round the ball's foot.
    static let restSpread: Float = 4.0
    static let restDarkness: Float = 0.75

    init(bodies: [ModelEntity]) {
        self.bodies = bodies
        standard = bodies.map { $0.model?.materials ?? [] }
        root.name = "table-detail"
        let material = TableBuilder.shadowMaterial(opacity: Self.restDarkness)
        for _ in bodies {
            let s = ModelEntity(mesh: .generatePlane(width: 1, depth: 1), materials: [material])
            s.isEnabled = false
            root.addChild(s)
            shadows.append(s)
        }
        // The high-contrast pictures come from StartupAssets' second pass; until then every ball keeps its normal one.
        Task { [weak self] in
            let images = await StartupAssets.shared.compactBallImages()
            self?.compact = images.map { TableBuilder.ballMaterial(image: $0) }
        }
    }

    /// Hang the shadows under the freshly built table group and find its lamp shade.
    func attach(to group: Entity) {
        root.removeFromParent()
        group.addChild(root)
        shade = group.findEntity(named: TableBuilder.shadeName)
        shadeOpacity = -1
    }

    /// Place ball `b`'s contact shadow. `centre` is where the ball's centre is drawn (world), `lift` how far its lowest
    /// point is above the cloth, `radius` its drawn radius; `onCloth` is false when it has dropped, flown off or is
    /// hidden, which hides the shadow.
    func ball(_ b: Int, centre: SIMD3<Float>, lift: Float, radius: Float, onCloth: Bool, tableHalf: SIMD2<Float>) {
        guard b < shadows.count else { return }
        let s = shadows[b]
        // Only over the bed: a ball sailing past the cushion has no cloth under it.
        let over = abs(centre.x) <= tableHalf.x && abs(centre.z) <= tableHalf.y
        guard onCloth, over else {
            if s.isEnabled { s.isEnabled = false }
            return
        }
        // Rising h above the cloth spreads the patch (the lamp is a broad source, so the penumbra grows with height)
        // and spreads the same darkness over a larger area, so it fades as 1 / (1 + 2h/R).
        let h = max(0, lift) / max(1e-4, radius)
        let spread = radius * (Self.restSpread + 1.6 * h)
        s.isEnabled = true
        s.position = SIMD3(centre.x, 0.0007, centre.z)
        s.scale = SIMD3(spread, 1, spread)
        s.components.set(OpacityComponent(opacity: 1 / (1 + 2 * h)))
    }

    /// After the camera has moved: fade the lamp shade by the camera's height and pick the ball pictures by size.
    /// - eye: the camera's position (world). - ballDiameter: a ball's on-screen diameter now, in points.
    func view(eye: SIMD3<Float>, ballDiameter: Float) {
        if let shade {
            // Fully shown while the camera is at least 25 cm below the shade's bottom edge, gone by 5 cm below it.
            let bottom = TableBuilder.shadeBottom
            let t = min(1, max(0, (eye.y - (bottom - 0.25)) / 0.20))
            let o = 1 - t * t * (3 - 2 * t)
            if abs(o - shadeOpacity) > 0.002 {
                shadeOpacity = o
                shade.components.set(OpacityComponent(opacity: o))
                shade.isEnabled = o > 0.01
            }
        }
        guard let compact else { return }
        let want = wearingCompact ? ballDiameter < Self.compactOff : ballDiameter < Self.compactOn
        guard want != wearingCompact else { return }
        wearingCompact = want
        for (b, body) in bodies.enumerated() where b < compact.count && b < standard.count {
            let materials: [any Material] = want ? [compact[b]] : standard[b]
            body.model?.materials = materials
        }
    }
}
