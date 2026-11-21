// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The 3D cue and the mechanical bridge on the table, replacing the flat ones AimOverlay used to draw. Owns one
//          root entity (a child of the warm table group, so it fades out with the table as the Physics Lens melts in)
//          holding the cue and the bridge, loaded from the app bundle as Cue.usdz and Bridge.usdz. The models carry
//          geometry only; each part is dressed here with its own physically based material, found by the part's name
//          (CueTip, CueFerrule, CueShaft, CueJoint, CueForearm, CueRings, CueWrap, CueSleeve, CueBumper; BridgeHead,
//          BridgeFerrule, BridgeHandle, BridgeFeet). If a model fails to load, nothing is shown and nothing breaks.
//          Model frames (the shared contract with the Blender models): metres, +Y up. The cue's tip face centre is at
//          the origin and its axis runs along +Z to the butt at z = 1.47. The bridge stands on the cloth (y = 0) with
//          its head's front face on z = 0, the centre notch's cradle bottom at y = 0.0215, and its handle running back
//          along +Z (offset a little to +X so the cue never touches it).
//          Two poses, both decided every frame by update():
//            Aiming: the cue lies on the aim line behind the cue ball, its axis through the tip's contact point (the
//            ball centre moved by tipSide to the right and tipUp up), its tip short of that point by the same gap the
//            old flat cue used (1.7 ball radii plus the power's pull-back), pitched up by the elevation. For a bridge
//            shot the pitch instead makes the cue rest in the bridge's centre notch, and the bridge stands still on the
//            cloth 0.30 m behind the ball while the pull-back slides the cue over it.
//            Strike: for the first half second of a recorded shot, the follow-through: at clock 0 the tip touches the
//            ball where it was struck, then drives on 8 cm, holds, and fades. A pure function of the playback clock and
//            the recorded timeline, so scrubbing shows the same cue for the same time.
//          Hidden otherwise, and during the strike while the Ride camera flies (it sits on the cue's line).
//          Integration: TableScene owns one rig, parents it to the table group, and calls update() from apply() with
//          the aim preview (TableStage builds it, with the cue's gate in AimPreview.showsCue), the CueStroke of the
//          shot on screen, the clock, the timeline and whether Ride is on.
// Edited: Claude Opus 5.5 High, 21-November-2026 (look plan package 5: a soft shadow on the cloth under the cue, a long
//          soft see-through ellipse under the front of the cue, paler the higher the cue rides above the cloth (a raised
//          cue throws a weaker shadow); it comes and goes with the cue, so it shows while aiming and through the
//          follow-through. The material is TableBuilder.shadowMaterial, shared with the balls' contact shadows.)
// SRP/DRY check: Pass - checked AimOverlay (now only labels the bridge), TableBuilder (its pbr() helper is private to
//          the table; the small one here mirrors it with clearcoat added), ShotCamera (reads the same first segment of
//          the cue ball for its start) and StartupAssets (pictures only; the models load here, once, in the
//          background). This file only places and dresses the cue and the bridge.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import RealityKit
import simd

/// How the shot now on screen was struck, for the follow-through: the tip's contact offsets (metres; up is follow, right
/// is side spin as the player sees it), the sine of the cue's raise, and whether the cue rested on the bridge.
struct CueStroke {
    var tipUp: Double = 0
    var tipSide: Double = 0
    var elevation: Double = 0
    var usesBridge = false
}

@MainActor
final class CueRig {
    // MARK: Tunables

    /// How far behind the cue ball's centre the bridge head stands, metres (the old flat bridge used the same).
    static let bridgeSetback: Float = 0.30
    /// The least the cue's butt is raised, radians (about 4 degrees): enough to clear the rail behind a ball near it.
    static let restingPitch: Float = 0.07
    /// Height of the bottom of the bridge's centre notch above the cloth, metres (from the Bridge model's contract).
    static let notchBottom: Float = 0.0215
    /// The cue's radius where it rests in the notch, metres. The notch is 0.05 to 0.25 m from the tip depending on the
    /// pull-back; the shaft's pro taper keeps it close to the 6.5 mm tip radius over that stretch, and the modeler's
    /// figure at 0.30 m from the tip is about 6.8 mm, so one constant is used. Reconcile with the Cue model if it changes.
    static let cueRadiusAtBridge: Float = 0.00704
    /// Pull-back at full power, metres: the same 0.35 m the flat cue used. On the bridge it is shortened so the tip
    /// always stays in front of the head (1.7 radii + 0.20 m is about 0.25 m, inside the 0.30 m setback).
    static let pullReach: Float = 0.35
    static let bridgePullReach: Float = 0.20
    /// The follow-through: how far the tip drives on past the contact, over how long (clock seconds), and when the
    /// cue fades away.
    static let followDistance: Float = 0.08
    static let driveTime = 0.12
    static let fadeStart = 0.28
    static let fadeEnd = 0.45

    // MARK: Parts

    /// Parent of the cue and the bridge; TableScene adds it to the table group.
    let root = Entity()
    private let cueHolder = Entity()
    private let bridgeHolder = Entity()
    /// The cue's soft shadow on the cloth (a unit plane, scaled and turned under the cue each frame).
    private let shadow = ModelEntity(mesh: .generatePlane(width: 1, depth: 1), materials: [TableBuilder.shadowMaterial(opacity: 0.45)])
    /// Length of the shadow along the cue, metres: the front of the cue, the part close enough to the cloth to throw a
    /// visible soft shadow under an overhead lamp (further back the cue is high enough for its shadow to wash out).
    static let shadowLength: Float = 0.80
    /// The scene root that carries the lamp reflection (ImageBasedLightComponent); the loaded parts point at it.
    private weak var lightSource: Entity?

    init(lightSource: Entity) {
        self.lightSource = lightSource
        root.name = "CueRig"
        root.addChild(cueHolder)
        root.addChild(bridgeHolder)
        root.addChild(shadow)
        root.isEnabled = false
        // Load in the background of the main actor; the table shows at once and the cue appears when it is ready.
        Task { [weak self] in await self?.loadModels() }
    }

    private func loadModels() async {
        do {
            let cue = try await Entity(named: "Cue", in: Bundle.main)
            Self.dress(cue, Self.cueMaterials())
            cueHolder.addChild(cue)
        } catch { NSLog("CueRig: the cue model did not load: %@", String(describing: error)) }
        do {
            let bridge = try await Entity(named: "Bridge", in: Bundle.main)
            Self.dress(bridge, Self.bridgeMaterials())
            bridgeHolder.addChild(bridge)
        } catch { NSLog("CueRig: the bridge model did not load: %@", String(describing: error)) }
        // TableBuilder.installEnvironment walks the tree once; parts that arrive after it would miss the reflection.
        if let light = lightSource { Self.receiveLight(root, from: light) }
    }

    // MARK: Per frame

    /// Place, show or hide the cue and the bridge for this frame.
    /// - aim: the live aim while the shot panel is open; the cue shows for it only when `aim.showsCue`.
    /// - stroke: how the shot on screen was struck; shown as the follow-through for the first moments of the clock.
    /// - clock: the playback clock (after any test pinning), the same one the balls use.
    /// - ride: true while the Ride camera may fly; it sits behind the cue ball, so the follow-through is hidden then.
    func update(aim: AimPreview?, stroke: CueStroke?, clock t: Double, timeline: Timeline, frame: TableFrame, ride: Bool) {
        let R = frame.ballRadius
        if let aim, aim.showsCue {
            let reach = aim.usesBridge ? Self.bridgePullReach : Self.pullReach
            let gap = R * 1.7 + Float(min(max(aim.powerFraction, 0), 1)) * reach
            place(ball: aim.from, direction: aim.direction, tipUp: Float(aim.tipUp), tipSide: Float(aim.tipSide),
                  elevation: Float(aim.elevation), bridge: aim.usesBridge, tipDistance: gap, frame: frame)
            show(opacity: 1)
            return
        }
        guard let stroke, !ride, t >= 0, t < Self.fadeEnd, let start = Self.strikeStart(timeline) else {
            root.isEnabled = false
            return
        }
        let up = Float(stroke.tipUp), side = Float(stroke.tipSide)
        // At the contact the tip sits on the ball's surface. Its axis passes through the offset point (centre plus the
        // side and up offsets), and the surface is sqrt(R^2 - side^2 - up^2) back from that point along the axis.
        let onSurface = max(0, R * R - side * side - up * up).squareRoot()
        let k = Float(min(1, t / Self.driveTime))
        let drive = Self.followDistance * (1 - (1 - k) * (1 - k))          // ease-out
        place(ball: start.position, direction: start.direction, tipUp: up, tipSide: side, elevation: Float(stroke.elevation),
              bridge: stroke.usesBridge, tipDistance: onSurface - drive, frame: frame)
        let fade = t <= Self.fadeStart ? 1 : 1 - (t - Self.fadeStart) / (Self.fadeEnd - Self.fadeStart)
        show(opacity: Float(max(0, fade)))
    }

    private func show(opacity: Float) {
        root.components.set(OpacityComponent(opacity: opacity))
        root.isEnabled = opacity > 0.001
    }

    /// Where the cue ball started and the way it was sent, from its first recorded segment; nil when the shot did not
    /// move it (the re-rack records a zero-speed strike so the rack shows) or it is not on the table.
    private static func strikeStart(_ timeline: Timeline) -> (position: Vec2, direction: Vec2)? {
        guard timeline.ballCount > 0, let first = timeline.segments[0].first else { return nil }
        let v = first.velocity0
        guard v.length > 1e-4, NextShot.isOnTable(first.position0) else { return nil }
        return (first.position0, v.normalized)
    }

    /// Put the cue (and the bridge, when used) in place for a ball at `ball` (table plan), struck along `direction`.
    /// - tipDistance: how far behind the contact offset point the tip sits, along the cue's axis (negative is past it).
    private func place(ball: Vec2, direction: Vec2, tipUp: Float, tipSide: Float, elevation: Float, bridge: Bool,
                       tipDistance: Float, frame: TableFrame) {
        let R = frame.ballRadius
        let worldUp = SIMD3<Float>(0, 1, 0)
        let centre = frame.world(ball, height: R)
        let along = simd_normalize(frame.direction(direction))
        // Right as the player sees it from behind the cue, the same right the solver uses for tipSide: (d.y, -d.x).
        let right = simd_normalize(frame.direction(Vec2(direction.y, -direction.x)))

        // The cue's pitch, butt up. Normally the shot's own elevation; on the bridge, whatever makes the axis pass
        // through the contact point and rest in the notch 0.30 m back (never below level, or the butt would dig into
        // the cloth on a follow shot; then the cue simply floats a hair over the notch).
        // A player always lifts the butt a little to clear the rail, so a level shot still shows a slight rise.
        var pitch = max(asin(min(max(elevation, 0), 0.995)), Self.restingPitch)
        if bridge {
            let contactHeight = R + tipUp
            let restHeight = Self.notchBottom + Self.cueRadiusAtBridge
            pitch = max(0, atan2(restHeight - contactHeight, Self.bridgeSetback))
        }
        // Forward is the way the cue drives (down toward the cloth when raised); back runs from the tip to the butt.
        let back = -(along * cos(pitch)) + worldUp * sin(pitch)
        // The tip's "up" leans with the cue, as in the solver's raised strike, so the contact point matches it.
        let cueUp = along * sin(pitch) + worldUp * cos(pitch)
        let contact = centre + right * tipSide + cueUp * tipUp

        cueHolder.position = contact + back * tipDistance
        cueHolder.orientation = Self.facing(back)
        placeShadow(tip: cueHolder.position, back: back, frame: frame)

        bridgeHolder.isEnabled = bridge
        if bridge {
            // Centred under the cue's line (the side offset moves the cue sideways), standing on the cloth.
            var head = centre - along * Self.bridgeSetback + right * tipSide
            head.y = 0
            bridgeHolder.position = head
            bridgeHolder.orientation = Self.facing(-along)
        }
    }

    /// Lay the soft shadow on the cloth under the front of the cue: centred under the middle of its first
    /// `shadowLength`, as wide as a cue near the tip plus the lamp's soft spread, and paler the higher that stretch of
    /// cue rides above the cloth (a raised cue throws a weaker, broader shadow).
    private func placeShadow(tip: SIMD3<Float>, back: SIMD3<Float>, frame: TableFrame) {
        var flat = SIMD3<Float>(back.x, 0, back.z)
        guard simd_length(flat) > 1e-4 else { shadow.isEnabled = false; return }
        flat = simd_normalize(flat)
        shadow.isEnabled = true
        let middle = tip + back * (Self.shadowLength * 0.5)
        shadow.position = SIMD3(middle.x, 0.0009, middle.z)
        shadow.orientation = Self.facing(flat)
        // 3.5 cm wide: the cue's 13 mm plus the soft spread either side under a broad lamp.
        shadow.scale = SIMD3(0.035, 1, Self.shadowLength)
        let height = max(0, middle.y)
        shadow.components.set(OpacityComponent(opacity: 1 / (1 + height / 0.06)))
    }

    /// The rotation that turns a model's +Z to `back` while keeping its +Y as close to world up as possible. Built from
    /// a basis rather than simd_quatf(from:to:), which is undefined when `back` is exactly opposite +Z (a real aim).
    private static func facing(_ back: SIMD3<Float>) -> simd_quatf {
        let z = simd_normalize(back)
        var x = simd_cross(SIMD3<Float>(0, 1, 0), z)
        if simd_length_squared(x) < 1e-8 { x = SIMD3(1, 0, 0) }        // straight up or down: never for a cue
        x = simd_normalize(x)
        let y = simd_cross(z, x)
        return simd_quatf(simd_float3x3(columns: (x, y, z)))
    }

    // MARK: Materials

    /// A physically based material in the table's style (see TableBuilder.pbr), with an optional clear lacquer coat.
    private static func pbr(_ c: PlatformColor, rough: Float, metal: Float = 0, coat: Float = 0, coatRough: Float = 0.1) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: c)
        m.roughness = .init(floatLiteral: rough)
        m.metallic = .init(floatLiteral: metal)
        if coat > 0 {
            m.clearcoat = .init(floatLiteral: coat)
            m.clearcoatRoughness = .init(floatLiteral: coatRough)
        }
        return m
    }

    private static var brass: PhysicallyBasedMaterial { pbr(rgba(0.86, 0.68, 0.36), rough: 0.26, metal: 1) }
    private static var rubber: PhysicallyBasedMaterial { pbr(rgba(0.035, 0.035, 0.04), rough: 0.85) }

    private static func cueMaterials() -> [String: PhysicallyBasedMaterial] {
        [
            "CueTip": pbr(rgba(0.17, 0.33, 0.62), rough: 0.96),                                     // chalked blue leather
            "CueFerrule": pbr(rgba(0.95, 0.93, 0.86), rough: 0.30, coat: 0.4, coatRough: 0.2),      // ivory white
            "CueShaft": pbr(rgba(0.93, 0.84, 0.66), rough: 0.38, coat: 0.6, coatRough: 0.16),       // pale maple
            "CueJoint": pbr(rgba(0.78, 0.78, 0.80), rough: 0.32, metal: 1),                         // brushed steel
            "CueForearm": pbr(rgba(0.10, 0.06, 0.045), rough: 0.30, coat: 1, coatRough: 0.07),      // ebony
            "CueRings": brass,
            "CueWrap": pbr(rgba(0.10, 0.10, 0.11), rough: 0.92),                                    // black linen
            "CueSleeve": pbr(rgba(0.30, 0.11, 0.06), rough: 0.30, coat: 1, coatRough: 0.07),        // rosewood
            "CueBumper": rubber,
        ]
    }

    private static func bridgeMaterials() -> [String: PhysicallyBasedMaterial] {
        [
            "BridgeHead": pbr(rgba(0.90, 0.91, 0.94), rough: 0.30, metal: 0.75),                     // satin chrome: a mirror finish only reflects the dark room
            "BridgeFerrule": brass,
            "BridgeHandle": pbr(rgba(0.80, 0.62, 0.40), rough: 0.40, coat: 0.7, coatRough: 0.15),   // varnished wood
            "BridgeFeet": rubber,
        ]
    }

    /// Give every named part its material. The name may sit on the mesh itself or on a parent transform with the mesh
    /// below it, so the material goes to every model at or under the named entity (stopping at another named part).
    private static func dress(_ model: Entity, _ materials: [String: PhysicallyBasedMaterial]) {
        let names = Set(materials.keys)
        for (name, material) in materials {
            guard let part = model.findEntity(named: name) else { continue }
            paint(part, material, skipping: names.subtracting([name]))
        }
    }

    private static func paint(_ entity: Entity, _ material: PhysicallyBasedMaterial, skipping others: Set<String>) {
        if var model = entity.components[ModelComponent.self] {
            // One copy per material slot, so a part exported with several sub-meshes keeps them all.
            model.materials = [any Material](repeating: material, count: max(1, model.materials.count))
            entity.components.set(model)
        }
        for child in entity.children where !others.contains(child.name) {
            paint(child, material, skipping: others)
        }
    }

    /// Point every model under `entity` at the scene's lamp reflection, as TableBuilder.installEnvironment does.
    private static func receiveLight(_ entity: Entity, from light: Entity) {
        if entity.components.has(ModelComponent.self) {
            entity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: light))
        }
        for child in entity.children { receiveLight(child, from: light) }
    }
}
