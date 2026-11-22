// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 33, 34 and 56. Pockets: the generic cup is replaced by
//          the other developer's hero corner pocket and the side pocket made from it (CornerPocket.usdz and
//          SidePocket.usdz, Tools/blender/make_pockets.py): the liner round the back flush with the rail, the slate's
//          cut edge and the funnel, each turned to face its pocket's back and fitted to the hole TableBuilder.pocketCuts
//          draws from the solver's jaws and capture circle; once a model is in place it switches off the code-built
//          stand-in. Walls: the plaster is now painted with the lamp's light falling on it (SurfaceTextures.
//          wallSpillImage), unlit like the floor, so the far wall reads as a wall in the low Ride view instead of a
//          near-black void, and the wainscot carries a faint glow of the same light; the overhead views and the Lens,
//          which never see the walls, are unchanged.)
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
//            - The pockets: the corner model at each corner and the side model at each side (see the Edited line
//              above), placed on the holes TableBuilder.pocketCuts draws, turned so their liner faces the rail.
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
    /// One pocket model's contract with Tools/blender/make_pockets.py (its report prints these numbers): the hole
    /// radius it is built round, the radius of its liner's lip (where the rail is cut), and how far round from the
    /// pocket's back its liner reaches either side.
    struct PocketModel: Sendable {
        let file: String
        let holeRadius: Float
        let railRadius: Float
        let linerHalfArc: Float
    }
    /// The hero corner pocket: built round the solver's 0.065 m corner capture circle, its lip 0.091 m out, its liner
    /// 79 degrees either side of the back (measured from the hero model by make_pockets.py).
    nonisolated static let cornerPocket = PocketModel(file: "CornerPocket", holeRadius: 0.065, railRadius: 0.091,
                                                      linerHalfArc: 79 * .pi / 180)
    /// The side pocket made from it: round the side hole pocketCuts draws on the standard table (0.06807 m), the same
    /// 26 mm of lip, its liner as far round as its foot stays behind the cushion (58.5 degrees).
    nonisolated static let sidePocket = PocketModel(file: "SidePocket", holeRadius: 0.06807, railRadius: 0.09407,
                                                    linerHalfArc: 58.5 * .pi / 180)

    /// The model for edge pocket k (corners first, then sides, as TableSpec lists them).
    nonisolated static func pocketModel(_ k: Int) -> PocketModel { isCornerPocket(k) ? cornerPocket : sidePocket }

    /// The way out of the table from a pocket's hole, in plan (world x, z): a corner's diagonal or a side's straight
    /// out across the rail. Read from where the hole is: the table is centred on the origin, corner holes sit off both
    /// axes and side holes on the middle of a long side.
    nonisolated static func pocketBack(_ cut: Outline.Cut) -> SIMD2<Float> {
        let sx: Float = abs(cut.center.x) < 1e-3 ? 0 : (cut.center.x < 0 ? -1 : 1)
        let sz: Float = cut.center.y < 0 ? -1 : 1
        return simd_normalize(SIMD2(sx, sz))
    }

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
        // the launch pull-back, the near wall simply is not drawn). Dark green-grey plaster with the lamp's light
        // painted on (SurfaceTextures.wallSpillImage), unlit as the floor is. When the plaster was lit by the scene's
        // lights it caught only the spot's fading cone edge and the weak fill, and the far wall read as a void above
        // the rail in the low Ride view; painted, it holds the same quiet brightness from every angle and costs nothing
        // per frame. The 256 by 128 picture is drawn here, once per wall per table build, in a few milliseconds.
        let upper = roomHeight - waistRailHeight
        func plaster(length: Float) -> UnlitMaterial {
            var m = UnlitMaterial(color: rgba(0.075, 0.085, 0.078))
            if let t = StartupAssets.texture(SurfaceTextures.wallSpillImage(length: length)) {
                m.color = .init(tint: .white, texture: .init(t))
            }
            return m
        }
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
        // A faint glow of the lamp's spill on the boards (the same light the plaster above is painted with), so the
        // wainscot reads as varnished wood in shadow rather than a black band: its own picture at about a tenth.
        wainscot.emissiveColor = .init(color: rgba(0.10, 0.085, 0.065), texture: wood.baseColor.texture)
        wainscot.emissiveIntensity = 1
        var ceiling = PhysicallyBasedMaterial()
        ceiling.baseColor = .init(tint: rgba(0.06, 0.055, 0.05))
        ceiling.roughness = .init(floatLiteral: 1)
        let panelDepth: Float = 0.015, railDepth: Float = 0.04, railHeight: Float = 0.07
        for (centre, yaw, length) in wallSpecs {
            let turn = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
            // Plaster above the waist rail.
            let wall = ModelEntity(mesh: .generatePlane(width: length, height: upper), materials: [plaster(length: length)])
            wall.orientation = turn
            wall.position = centre + SIMD3(0, floorY + waistRailHeight + upper * 0.5, 0)
            walls.addChild(wall)
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

    /// The pocket models: CornerPocket.usdz in each corner and SidePocket.usdz in each side (Tools/blender/
    /// make_pockets.py), each copy on its pocket's drawn hole (`cuts`, from the solver's jaws and capture circles),
    /// turned about the vertical so its liner faces that pocket's back, and scaled across (x and z) by the drawn hole
    /// over the hole the model is built round (exactly 1 on the standard table). The liner, funnel and slate are dark
    /// and drawn from both sides (they are open shells seen from inside).
    /// - standIns: the code-built stand-in for the corners and for the sides (TableBuilder.makeTable); each model
    ///   switches its own off once its copies are in place, so a model that fails to load leaves the stand-in up.
    static func addPocketLiners(cuts: [Outline.Cut], to group: Entity, standIns: [Entity?], lightSource: Entity?) {
        guard !cuts.isEmpty else { return }
        let holder = Entity()
        holder.name = "pocket-liners"
        group.addChild(holder)
        // The hero file's own finishes, as screen colours: "Black pocket liner" (linear 0.019, 0.014, 0.012, rough
        // 0.56) for the liner and the funnel, "Side of slate" (linear 0.035, 0.041, 0.042, rough 0.83) for the slate.
        let liner = TablePartLook(color: (0.15, 0.12, 0.11), roughness: 0.56)
        let looks: [String: TablePartLook] = [
            "PocketLiner": liner,
            "PocketFunnel": liner,
            "PocketSlate": TablePartLook(color: (0.20, 0.22, 0.22), roughness: 0.83),
        ]
        for (which, model) in [cornerPocket, sidePocket].enumerated() {
            let pockets = cuts.indices.filter { pocketModel($0).file == model.file }
            guard !pockets.isEmpty else { continue }
            let standIn: Entity? = which < standIns.count ? standIns[which] : nil
            loadDressed(named: model.file, looks: looks, into: holder, lightSource: lightSource) { [weak standIn] loaded in
                doubleSided(loaded)
                // The loaded model becomes the first of its pockets; the others are clones of it.
                for (n, k) in pockets.enumerated() {
                    let cut = cuts[k]
                    let copy = n == 0 ? loaded : loaded.clone(recursive: true)
                    let back = pocketBack(cut)
                    let s = cut.radius / model.holeRadius
                    copy.position = SIMD3(cut.center.x, 0, cut.center.y)
                    // A turn about +Y by angle t carries the model's back (+Z) to (sin t, 0, cos t).
                    copy.orientation = simd_quatf(angle: atan2(back.x, back.y), axis: SIMD3(0, 1, 0))
                    copy.scale = SIMD3(s, 1, s)
                    copy.name = "pocket-\(k)"
                    holder.addChild(copy)
                }
                standIn?.isEnabled = false
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
