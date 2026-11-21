// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The room around the table (look plan package 1) and the moulded pockets (package 2), as an extension of
//          TableBuilder so everything the warm table group holds is still built by TableBuilder. Before this the low
//          Ride camera saw solid black above the far rail: there was no room, no lamp, no wall, and the floor faded to
//          nothing a few metres out. Now:
//            - Four walls a little over two metres out from the table, painted a dark green-grey, with dark wooden
//              wainscot panels up to a wooden waist rail, a dark ceiling, and the floor reaching every wall (its
//              picture is SurfaceTextures.roomFloorImage, sized here by roomFloorSide).
//            - The lamp: a long enamelled shade (LampShade.usdz, made by Tools/blender/make_room.py) hanging over the
//              table, its white reflector and three bulbs lit from inside with unlit materials, so the table's light
//              has a visible source. It casts no shadow (the real key light is the spot light in addLights).
//            - Three dim props: a cue rack on the far wall, a stool in a corner, a cube of chalk on a rail
//              (CueRack.usdz, Stool.usdz, Chalk.usdz). Geometry from Blender, materials dressed here by part name.
//            - The pocket liners: one moulded cup with a rolled lip (Pocket.usdz, Tools/blender/make_pocket.py) at
//              each edge pocket, scaled across to that pocket's drawn mouth, so the mouth still follows the solver's
//              jaws and capture circle (see the cut comment in makeTable). The old code-built wall and floor stay
//              under it as the fallback while it loads.
//          Everything here is a child of the warm table group, so it fades out as the Physics Lens melts in.
//          Coordinates: world metres, y up, cloth at y = 0, the floor at TableBuilder.floorHeight.
//          Room size: the table's outer half-size plus roomMargin on each side. The margin keeps a stool and a person's
//          worth of space round the table, and keeps the walls inside every camera: the Ride camera sits at most about
//          a metre outside the rail (ShotCamera.craneBack 0.95 m behind the cue ball), well inside two metres.
//          The models load in the background (the table shows at once); a model that fails to load is logged and
//          skipped, and the room still stands.
//          Read by: TableBuilder.makeTable (makeRoom, addPocketLiners), SurfaceTextures.roomFloorImage and
//          StartupAssets (roomHalfExtent, roomFloorSide), TableDetail (the shade, found by name, fades out when the
//          camera rises past it, so it never blocks the view of the table from above).
// SRP/DRY check: Pass - room geometry and its materials only. Reuses TableProps.dress and TableProps.receiveLight for
//          the loaded models (the same steps CueRig keeps privately), TableBuilder's wood material for the rails, and
//          the floor picture from SurfaceTextures. Per-frame behaviour (the shade's fade) is in TableDetail.
import BreakdownLensModel
import BreakdownTimeline
import Foundation
import RealityKit
import simd

extension TableBuilder {
    // MARK: Room size

    /// Metres from the table's outer edge to the walls, along the table's length and across it.
    nonisolated static let roomMargin = SIMD2<Float>(2.1, 2.15)
    /// Floor to ceiling, metres: a tall old hall. It keeps the ceiling (2.4 m above the cloth) above the key spot light,
    /// which addLights hangs 2.3 m above the cloth, so the light the table is lit by is inside the room it lights.
    nonisolated static let roomHeight: Float = 3.2
    /// Height of the waist rail's top above the floor, metres.
    nonisolated static let waistRailHeight: Float = 1.0
    /// Height of the lamp shade's bottom edge above the cloth, metres: the usual 32 to 36 inches (0.81 to 0.91 m).
    nonisolated static let shadeBottom: Float = 0.86
    /// Name of the entity holding the lamp shade (TableDetail fades it by camera height).
    nonisolated static let shadeName = "lamp-shade"
    /// The mouth radius Pocket.usdz is authored for (REF_R in make_pocket.py).
    nonisolated static let pocketModelRadius: Float = 0.075

    /// Half the room's length and width (wall to wall), from half the table's outer length and width.
    nonisolated static func roomHalfExtent(tableHalf: SIMD2<Float>) -> SIMD2<Float> { tableHalf + roomMargin }

    /// Side of the square floor plane: it covers the whole room (the part past the shorter walls is behind them).
    nonisolated static func roomFloorSide(tableHalf: SIMD2<Float>) -> Float {
        let h = roomHalfExtent(tableHalf: tableHalf)
        return 2 * max(h.x, h.y)
    }

    // MARK: Room

    /// The room: floor, walls with wainscot and a waist rail, ceiling, the lamp shade and the three props.
    /// - tableHalf: half the table's outer length and width (floorHalfExtent).
    /// - wood: the table's wood material (rails, legs), reused for the waist rail and, darkened, the wainscot.
    /// - lightSource: the entity carrying the lamp reflection, for the models that load later; nil skips that step.
    static func makeRoom(frame: TableFrame, tableHalf: SIMD2<Float>, wood: PhysicallyBasedMaterial, lightSource: Entity?) -> Entity {
        let room = Entity()
        room.name = "room"
        let half = roomHalfExtent(tableHalf: tableHalf)
        let floorY = floorHeight
        let ceilingY = floorHeight + roomHeight

        // Floor: the painted picture, unlit (see SurfaceTextures.roomFloorImage), now opaque out to the walls.
        let side = roomFloorSide(tableHalf: tableHalf)
        var floorMat = UnlitMaterial(color: .white)
        if let t = StartupAssets.texture(StartupAssets.shared.roomFloorImage(tableHalf: tableHalf)) { floorMat.color = .init(tint: .white, texture: .init(t)) }
        let floor = ModelEntity(mesh: .generatePlane(width: side, depth: side), materials: [floorMat])
        floor.position = SIMD3(0, floorY, 0)
        floor.name = "floor"
        room.addChild(floor)

        // Walls: one inward-facing plane each (a plane is seen from its front only, so from outside the room, during
        // the launch pull-back, the near wall simply is not drawn). Dark painted plaster: a deep green-grey that keeps
        // the lamp's warm pool the brightest thing, with enough roughness to stay matte.
        var paint = PhysicallyBasedMaterial()
        paint.baseColor = .init(tint: rgba(0.075, 0.085, 0.078))
        paint.roughness = .init(floatLiteral: 0.9)
        let walls = Entity()
        walls.name = "walls"
        // (centre, rotation about y that turns the plane's front, +Z, into the room, wall length)
        let wallSpecs: [(SIMD3<Float>, Float, Float)] = [
            (SIMD3(0, 0, -half.y), 0, 2 * half.x),
            (SIMD3(0, 0, half.y), .pi, 2 * half.x),
            (SIMD3(-half.x, 0, 0), .pi / 2, 2 * half.y),
            (SIMD3(half.x, 0, 0), -.pi / 2, 2 * half.y),
        ]
        // Wainscot: the wood picture, darkened to about half so the panels read as old varnished boards in shadow.
        var wainscot = PhysicallyBasedMaterial()
        wainscot.baseColor = .init(tint: rgba(0.5, 0.46, 0.42), texture: wood.baseColor.texture)
        wainscot.roughness = .init(floatLiteral: 0.6)
        var ceiling = PhysicallyBasedMaterial()
        ceiling.baseColor = .init(tint: rgba(0.06, 0.055, 0.05))
        ceiling.roughness = .init(floatLiteral: 1)
        let panelDepth: Float = 0.015, railDepth: Float = 0.04, railHeight: Float = 0.07
        for (centre, yaw, length) in wallSpecs {
            let turn = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
            // Plaster above the waist rail.
            let upper = roomHeight - waistRailHeight
            let plaster = ModelEntity(mesh: .generatePlane(width: length, height: upper), materials: [paint])
            plaster.orientation = turn
            plaster.position = centre + SIMD3(0, floorY + waistRailHeight + upper * 0.5, 0)
            walls.addChild(plaster)
            // Wainscot below it, standing a little proud of the wall.
            let inward = turn.act(SIMD3<Float>(0, 0, 1))
            let panel = ModelEntity(mesh: .generateBox(size: SIMD3(length, waistRailHeight, panelDepth)), materials: [wainscot])
            panel.orientation = turn
            panel.position = centre + SIMD3(0, floorY + waistRailHeight * 0.5, 0) + inward * (panelDepth * 0.5)
            walls.addChild(panel)
            // The waist rail: a rounded wooden cap along the top of the wainscot.
            let rail = ModelEntity(mesh: .generateBox(size: SIMD3(length, railHeight, railDepth), cornerRadius: 0.01), materials: [wood])
            rail.orientation = turn
            rail.position = centre + SIMD3(0, floorY + waistRailHeight - railHeight * 0.3, 0) + inward * (railDepth * 0.5)
            walls.addChild(rail)
        }
        // The ceiling faces down (a horizontal plane faces up, so it is turned over about x); seen from above, as the
        // overhead camera may be, it is not drawn at all.
        let top = ModelEntity(mesh: .generatePlane(width: 2 * half.x, depth: 2 * half.y), materials: [ceiling])
        top.orientation = simd_quatf(angle: .pi, axis: SIMD3(1, 0, 0))
        top.position = SIMD3(0, ceilingY, 0)
        walls.addChild(top)
        // The room's own surfaces never need to cast a shadow from the lamp (nothing they could shadow is lit).
        noShadows(walls)
        noShadows(floor)
        room.addChild(walls)

        addLampShade(to: room, frame: frame, lightSource: lightSource)
        addProps(to: room, frame: frame, half: half, lightSource: lightSource)
        return room
    }

    /// The lamp shade over the middle of the table, its bottom edge `shadeBottom` above the cloth, long side along
    /// the table. Scaled along its length with the table (a 1.30 m shade belongs over the 2.54 m bed).
    private static func addLampShade(to room: Entity, frame: TableFrame, lightSource: Entity?) {
        let holder = Entity()
        holder.name = shadeName
        holder.position = SIMD3(0, shadeBottom, 0)
        holder.scale = SIMD3(max(0.4, frame.length / 2.54), 1, 1)
        room.addChild(holder)
        let looks: [String: TablePartLook] = [
            // Green enamel outside, as the classic billiard shade; a little gloss so the room shows in it.
            "ShadeOuter": TablePartLook(color: (0.05, 0.16, 0.10), roughness: 0.35, metallic: 0.2, clearcoat: 0.6, clearcoatRoughness: 0.2),
            "ShadeTrim": TablePartLook(color: (0.78, 0.60, 0.32), roughness: 0.3, metallic: 1),
            "ShadeRods": TablePartLook(color: (0.10, 0.10, 0.10), roughness: 0.5, metallic: 1),
        ]
        loadDressed(named: "LampShade", looks: looks, into: holder, lightSource: lightSource) { model in
            // Lit from inside: the white reflector glows warm and the bulbs glow brighter. Unlit materials, so their
            // brightness is what the screen shows whatever the lights do, both faces drawn (the reflector is seen
            // from below, through the open bottom).
            var reflector = UnlitMaterial(color: rgba(1.0, 0.86, 0.64))
            reflector.faceCulling = .none
            let bulb = UnlitMaterial(color: rgba(1.0, 0.97, 0.90))
            setMaterial(model, part: "ShadeInner", reflector)
            setMaterial(model, part: "ShadeBulbs", bulb)
            doubleSided(model)
            // The shade must not throw its shadow over the table: the spot light above it stands in for its bulbs.
            noShadows(model)
        }
    }

    /// The cue rack on the far wall, a stool in the near corner and a cube of chalk on the far long rail. Kept dark
    /// so they sit in the background: the lit table stays the subject.
    private static func addProps(to room: Entity, frame: TableFrame, half: SIMD2<Float>, lightSource: Entity?) {
        let rack = Entity()
        rack.name = "cue-rack"
        // On the far wall (the overhead camera looks from +z), left of centre, its board 0.45 m off the floor.
        rack.position = SIMD3(-half.x * 0.35, floorHeight + 0.45, -half.y)
        room.addChild(rack)
        loadDressed(named: "CueRack", looks: [
            "RackBoard": TablePartLook(color: (0.16, 0.08, 0.04), roughness: 0.45, clearcoat: 0.5, clearcoatRoughness: 0.3),
            "RackRails": TablePartLook(color: (0.20, 0.10, 0.05), roughness: 0.45, clearcoat: 0.5, clearcoatRoughness: 0.3),
            "RackCues": TablePartLook(color: (0.55, 0.42, 0.28), roughness: 0.4, clearcoat: 0.6, clearcoatRoughness: 0.2),
        ], into: rack, lightSource: lightSource)

        let stool = Entity()
        stool.name = "stool"
        stool.position = SIMD3(half.x - 0.75, floorHeight, half.y - 0.85)
        stool.orientation = simd_quatf(angle: 0.4, axis: SIMD3(0, 1, 0))
        room.addChild(stool)
        loadDressed(named: "Stool", looks: [
            "StoolSeat": TablePartLook(color: (0.22, 0.05, 0.04), roughness: 0.5, clearcoat: 0.4, clearcoatRoughness: 0.35),
            "StoolFrame": TablePartLook(color: (0.06, 0.06, 0.065), roughness: 0.4, metallic: 1),
        ], into: stool, lightSource: lightSource)

        // Chalk on the far long rail, between the second and third diamonds from the foot end (diamonds stand at
        // eighths of the length; this is at 0.81 of the half-length, clear of both and of the corner pocket).
        let chalk = Entity()
        chalk.name = "chalk"
        let a = frame.length * 0.5, b = frame.width * 0.5
        chalk.position = SIMD3(a * 0.62, railTop, -(b + cushionDepth + railWidth * 0.5))
        chalk.orientation = simd_quatf(angle: 0.3, axis: SIMD3(0, 1, 0))
        room.addChild(chalk)
        loadDressed(named: "Chalk", looks: [
            "ChalkWrap": TablePartLook(color: (0.10, 0.24, 0.52), roughness: 0.7),
            "ChalkFace": TablePartLook(color: (0.20, 0.40, 0.70), roughness: 1),
        ], into: chalk, lightSource: lightSource)
    }

    // MARK: Pocket liners

    /// One moulded cup and rolled lip in each edge pocket, scaled across from the model's authored mouth to the
    /// pocket's drawn mouth (`cuts`, the same circles the cloth and rail are cut with, so they follow the solver's
    /// jaws and capture circles). The cup is dark leather and is drawn from both sides (it is seen from inside).
    static func addPocketLiners(cuts: [Outline.Cut], to group: Entity, lightSource: Entity?) {
        guard !cuts.isEmpty else { return }
        let holder = Entity()
        holder.name = "pocket-liners"
        group.addChild(holder)
        let looks: [String: TablePartLook] = [
            "PocketLiner": TablePartLook(color: (0.045, 0.032, 0.025), roughness: 0.75),
            "PocketLip": TablePartLook(color: (0.09, 0.06, 0.045), roughness: 0.55, clearcoat: 0.3, clearcoatRoughness: 0.4),
        ]
        loadDressed(named: "Pocket", looks: looks, into: holder, lightSource: lightSource) { model in
            doubleSided(model)
            // The model becomes the first pocket's liner; the others are clones of it.
            for (k, cut) in cuts.enumerated() {
                let liner = k == 0 ? model : model.clone(recursive: true)
                let s = cut.radius / pocketModelRadius
                liner.position = SIMD3(cut.center.x, 0, cut.center.y)
                liner.scale = SIMD3(s, 1, s)
                liner.name = "pocket-liner-\(k)"
                holder.addChild(liner)
            }
        }
    }

    // MARK: Loading helpers

    /// Load `<name>.usdz` in the background, dress its named parts, let `place` finish it, add it under `parent` (if
    /// `place` did not) and point it at the lamp reflection. The same steps as TableProps.loadModel, except that the
    /// light source is optional here (makeTable is also called before the scene has one).
    private static func loadDressed(named name: String, looks: [String: TablePartLook], into parent: Entity,
                                    lightSource: Entity?, place: @escaping @MainActor (Entity) -> Void = { _ in }) {
        Task { @MainActor in
            do {
                let model = try await Entity(named: name, in: Bundle.main)
                TableProps.dress(model, looks: looks)
                place(model)
                if model.parent == nil { parent.addChild(model) }
                if let lightSource { TableProps.receiveLight(parent, from: lightSource) }
            } catch {
                NSLog("TableRoom: the model %@ did not load: %@", name, String(describing: error))
            }
        }
    }

    /// Put one material on every model at or under the part named `part`.
    private static func setMaterial(_ model: Entity, part: String, _ material: some Material) {
        guard let entity = model.findEntity(named: part) else { return }
        func paint(_ e: Entity) {
            if var m = e.components[ModelComponent.self] {
                m.materials = [any Material](repeating: material, count: max(1, m.materials.count))
                e.components.set(m)
            }
            for child in e.children { paint(child) }
        }
        paint(entity)
    }

    /// Stop every model at or under `entity` casting a shadow from the lamp (set on each model, so it holds whether
    /// or not the component is inherited by children).
    private static func noShadows(_ entity: Entity) {
        if entity.components.has(ModelComponent.self) { entity.components.set(DynamicLightShadowComponent(castsShadow: false)) }
        for child in entity.children { noShadows(child) }
    }

    /// Draw both faces of every physically based material under `entity`: the shade and the pocket cup are open
    /// shells seen from inside and out, and Blender's normals on an open shell may face either way.
    private static func doubleSided(_ entity: Entity) {
        if var m = entity.components[ModelComponent.self] {
            m.materials = m.materials.map { material -> any Material in
                guard var pbr = material as? PhysicallyBasedMaterial else { return material }
                pbr.faceCulling = .none
                return pbr
            }
            entity.components.set(m)
        }
        for child in entity.children { doubleSided(child) }
    }
}
