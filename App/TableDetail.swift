// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 21, 23 and 56: this file is now the one owner of which
//          picture each ball wears. It dresses the balls in the table's own ball set (TableBallSet: plain whites and a
//          red for bar billiards, white, yellow and red for five-pin, bumper pool's red and white sides with their
//          marked balls) and re-dresses them whenever TableScene says the table changed; and it switches each ball
//          between its normal and its small-on-screen picture by that ball's own size on screen, measured from its own
//          distance to the camera, instead of all sixteen at once from the size at the look point (which swapped the
//          whole set together as the Ride camera dropped and rose). It also holds the bridge mark's ring (BridgeRing).)
// PURPOSE: The per-frame parts of the warm table's look that depend on the camera or on where the balls are (look plan
//          packages 1, 2 and 3), kept out of TableScene so that file stays a thin coordinator:
//            - A soft contact shadow under every ball: a dark round patch on the cloth that is small and strong while
//              the ball sits on the cloth and spreads and fades as it rises in a jump, so it visibly tightens as the
//              ball lands. It is a function of the ball's recorded height alone, so scrubbing shows the same shadow.
//            - The lamp shade fades out as the camera rises toward it, so from the low Ride views it hangs over the
//              table, lit from inside, and from the normal views above it never blocks the table.
//            - The ball pictures: each ball wears its table's look (dress), and below a measured on-screen size it
//              wears that look's high-contrast picture (BallTextures, compact), above it the normal one, with a gap
//              between the two switch points so it never flickers. Per ball.
//            - The bridge mark's ring on the cloth (BridgeRing), which the 3D cue and bridge cover.
//          Pictures: the pool set's normal pictures are the ones TableBuilder.makeBall put on (drawn at launch by
//          StartupAssets) and its small ones come from StartupAssets' second pass; every other look (a plain or marked
//          ball) is drawn here in the background the first time a table needs it and kept for the rest of the run.
//          Until a picture arrives the ball keeps what it wears, so nothing ever waits.
//          Integration: TableScene owns one, adds `root` under the warm table group each time the table is built (so
//          the shadows and the ring fade with the table in the Lens) and calls attach, dress(_:) when the table kind
//          changes, ball(...) for each ball every frame, bridge(_:frame:), and view(...) after the camera has moved.
// SRP/DRY check: Pass - checked TableScene (ball placement stays there; this only reads the placed values),
//          TableBuilder (the shadow material and ball material are its; reused here), TableCamera (it measures, this
//          decides), BallTextures (draws the pictures; this only chooses and caches them) and TableBallSet (which ball
//          is which look). No camera or ball motion logic lives here.
import CoreGraphics
import Foundation
import RealityKit
import simd

@MainActor
final class TableDetail {
    /// Parent of the contact shadows and the bridge ring; TableScene adds it under the warm table group.
    let root = Entity()
    private var shadows: [ModelEntity] = []
    /// The bridge mark on the cloth.
    private let ring = BridgeRing()
    /// The lamp shade's holder (TableRoom names it), found again after every rebuild of the table.
    private weak var shade: Entity?
    private var shadeOpacity: Float = -1

    // MARK: Ball pictures

    /// The ball bodies whose pictures this file chooses.
    private let bodies: [ModelEntity]
    /// The pool set's pictures: the normal ones TableBuilder.makeBall put on, and the small-on-screen ones once
    /// StartupAssets' second pass has drawn them.
    private let poolStandard: [PhysicallyBasedMaterial?]
    private var poolCompact: [PhysicallyBasedMaterial?]
    /// The ball set the balls are dressed in, and per ball the look it wears in that set.
    private var ballSet: TableBallSet = .pool
    private var looks: [BallLook]
    /// Per ball: true while it wears its small-on-screen picture (the hysteresis state), and what was last put on
    /// (look and size), so a material is only set when it changes.
    private var small: [Bool]
    private var applied: [(look: BallLook, small: Bool)?]
    /// Per ball this frame: where its centre is drawn and its drawn radius (metres), from ball(...).
    private var centres: [SIMD3<Float>]
    private var drawnRadii: [Float]
    /// Pictures of the other tables' looks, drawn once per run and shared by every table scene (keyed by the look's
    /// description, since BallLook is only Equatable).
    private static var lookMaterials: [String: (standard: PhysicallyBasedMaterial, compact: PhysicallyBasedMaterial)] = [:]
    /// Looks being drawn now, so two quick table changes do not draw the same look twice.
    private static var drawing: Set<String> = []

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
        poolStandard = bodies.map { $0.model?.materials.first as? PhysicallyBasedMaterial }
        poolCompact = [PhysicallyBasedMaterial?](repeating: nil, count: bodies.count)
        looks = bodies.indices.map { BallLook.pool(number: $0) }
        small = [Bool](repeating: false, count: bodies.count)
        applied = bodies.indices.map { (look: BallLook.pool(number: $0), small: false) }
        centres = [SIMD3<Float>](repeating: .zero, count: bodies.count)
        drawnRadii = [Float](repeating: 0, count: bodies.count)
        root.name = "table-detail"
        let material = TableBuilder.shadowMaterial(opacity: Self.restDarkness)
        for _ in bodies {
            let s = ModelEntity(mesh: .generatePlane(width: 1, depth: 1), materials: [material])
            s.isEnabled = false
            root.addChild(s)
            shadows.append(s)
        }
        root.addChild(ring.root)
        // The pool set's high-contrast pictures come from StartupAssets' second pass; until then a small pool ball
        // keeps its normal picture.
        Task { [weak self] in
            let images = await StartupAssets.shared.compactBallImages()
            guard let self else { return }
            self.poolCompact = images.map { TableBuilder.ballMaterial(image: $0) }
            self.resetApplied()   // put the new pictures on at the next view(...)
        }
    }

    /// Hang the shadows and the ring under the freshly built table group and find its lamp shade.
    func attach(to group: Entity) {
        root.removeFromParent()
        group.addChild(root)
        shade = group.findEntity(named: TableBuilder.shadeName)
        shadeOpacity = -1
    }

    /// Dress the balls in a table's ball set. Cheap when the set is unchanged; a look not drawn yet is drawn in the
    /// background and put on when it arrives (the ball keeps its old picture meanwhile).
    func dress(_ set: TableBallSet) {
        guard set != ballSet else { return }
        ballSet = set
        looks = bodies.indices.map { set.look(of: $0) }
        resetApplied()
        var wanted: [BallLook] = []
        for look in looks where !Self.isPoolOwn(look) {
            let key = Self.key(look)
            if Self.lookMaterials[key] == nil, !Self.drawing.contains(key), !wanted.contains(look) { wanted.append(look) }
        }
        guard !wanted.isEmpty else { return }
        for look in wanted { Self.drawing.insert(Self.key(look)) }
        Task { [weak self] in
            // Drawing is pure CoreGraphics on a background thread; the textures are made back on the main actor.
            let drawn = await Task.detached(priority: .userInitiated) {
                wanted.map { look in (look, BallTextures.ballImage(look: look), BallTextures.ballImage(look: look, compact: true)) }
            }.value
            for (look, standard, compact) in drawn {
                let key = Self.key(look)
                Self.drawing.remove(key)
                Self.lookMaterials[key] = (TableBuilder.ballMaterial(image: standard), TableBuilder.ballMaterial(image: compact))
            }
            self?.resetApplied()
        }
    }

    /// Forget what each ball wears, so the next view(...) puts the right picture on every ball.
    private func resetApplied() {
        applied = [(look: BallLook, small: Bool)?](repeating: nil, count: bodies.count)
    }

    /// True for a pool look on its own slot's number: the picture TableBuilder.makeBall already put on that ball.
    private static func isPoolOwn(_ look: BallLook) -> Bool {
        if case .pool = look { return true }
        return false
    }

    private static func key(_ look: BallLook) -> String { String(describing: look) }

    /// The material ball `b` should wear now, or nil when that picture is not ready (the ball keeps what it has).
    private func material(ball b: Int, small wantSmall: Bool) -> PhysicallyBasedMaterial? {
        switch looks[b] {
        case .pool(let number):
            // A slot wearing another slot's pool picture never happens (TableBallSet keeps each slot's own number);
            // fall back to the slot's own picture if it ever did.
            let n = number >= 0 && number < bodies.count ? number : b
            return wantSmall ? (poolCompact[n] ?? poolStandard[n]) : poolStandard[n]
        default:
            guard let m = Self.lookMaterials[Self.key(looks[b])] else { return nil }
            return wantSmall ? m.compact : m.standard
        }
    }

    // MARK: Per frame

    /// Place ball `b`'s contact shadow and note where it is drawn. `centre` is where the ball's centre is drawn
    /// (world), `lift` how far its lowest point is above the cloth, `radius` the table's ball radius (the shadow's
    /// scale), `drawn` the radius it is drawn at now (another table's size and the Lens's enlargement included, for its
    /// size on screen); `onCloth` is false when it has dropped, flown off or is hidden, which hides the shadow.
    func ball(_ b: Int, centre: SIMD3<Float>, lift: Float, radius: Float, drawn: Float, onCloth: Bool, tableHalf: SIMD2<Float>) {
        guard b < shadows.count else { return }
        centres[b] = centre
        drawnRadii[b] = drawn
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

    /// The bridge mark for this frame (nil hides it).
    func bridge(_ mark: BridgeMark?, frame: TableFrame) {
        ring.update(mark, frame: frame)
    }

    /// After the camera has moved: fade the lamp shade by the camera's height and pick each ball's picture by its own
    /// size on screen.
    /// - eye: the camera's position (world). - forward: its unit view direction.
    /// - focal: screen points spanned by one metre seen square-on one metre in front of the camera (the view height
    ///   over the field of view's height at one metre); a ball's diameter on screen is 2 r focal / depth.
    func view(eye: SIMD3<Float>, forward: SIMD3<Float>, focal: Float) {
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
        for b in bodies.indices {
            // Depth along the view direction (what perspective divides by), never below the near plane's reach.
            let depth = max(0.05, simd_dot(centres[b] - eye, forward))
            let diameter = 2 * drawnRadii[b] * focal / depth
            small[b] = small[b] ? diameter < Self.compactOff : diameter < Self.compactOn
            if let last = applied[b], last.look == looks[b], last.small == small[b] { continue }
            guard let m = material(ball: b, small: small[b]) else { continue }
            bodies[b].model?.materials = [m]
            applied[b] = (looks[b], small[b])
        }
    }
}
