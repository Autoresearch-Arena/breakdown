// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Small shared helpers for the table files in App/Tables/ when they build their props: a material from a
//          TablePartLook, dressing a loaded model's named parts, loading a Blender-made USDZ from the app bundle in the
//          background (dressed, lit by the scene's lamp reflection, then added to a parent), and plain code-built posts
//          and pins that already follow the naming and origin rules TableScene relies on ("post-<k>", "pin-<k>", origin
//          at the base centre on the cloth). Table files use these; they never edit this file.
//          Naming contract used by TableScene: an entity named "pin-<k>" (k the index in TableSpec.pins) is toppled when
//          that pin is knocked down; its origin must be the pin's base centre on the cloth and its axis must be +Y.
// SRP/DRY check: Pass - checked CueRig.swift (the same dress, paint and receive-light steps, kept private there); these
//          are the shared versions for the table props, so the three table files do not each copy them.
import BreakdownLensModel
import BreakdownTimeline
import Foundation
import RealityKit

@MainActor
enum TableProps {
    /// A physically based material for a part look.
    static func material(_ look: TablePartLook) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: rgba(look.color.r, look.color.g, look.color.b))
        m.roughness = .init(floatLiteral: look.roughness)
        m.metallic = .init(floatLiteral: look.metallic)
        if look.clearcoat > 0 {
            m.clearcoat = .init(floatLiteral: look.clearcoat)
            m.clearcoatRoughness = .init(floatLiteral: look.clearcoatRoughness)
        }
        return m
    }

    /// Give every named part under `model` its material. The name may sit on the mesh or on a parent transform with the
    /// mesh below it; the material goes to every model at or under the named entity, stopping at another named part.
    static func dress(_ model: Entity, looks: [String: TablePartLook]) {
        let names = Set(looks.keys)
        for (name, look) in looks {
            guard let part = model.findEntity(named: name) else { continue }
            paint(part, material(look), skipping: names.subtracting([name]))
        }
    }

    private static func paint(_ entity: Entity, _ material: PhysicallyBasedMaterial, skipping others: Set<String>) {
        if var model = entity.components[ModelComponent.self] {
            model.materials = [any Material](repeating: material, count: max(1, model.materials.count))
            entity.components.set(model)
        }
        for child in entity.children where !others.contains(child.name) {
            paint(child, material, skipping: others)
        }
    }

    /// Point every model under `entity` at the scene's lamp reflection (as TableBuilder.installEnvironment does for
    /// the parts that exist when it runs).
    static func receiveLight(_ entity: Entity, from light: Entity) {
        if entity.components.has(ModelComponent.self) {
            entity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: light))
        }
        for child in entity.children { receiveLight(child, from: light) }
    }

    /// Load `<name>.usdz` from the app bundle in the background, dress its parts, light it, let `place` position it
    /// (or clone parts out of it) and add it under `parent`. The table shows at once; the model appears when ready.
    /// A model that fails to load is logged and skipped, so the table still works.
    static func loadModel(named name: String, looks: [String: TablePartLook], into parent: Entity, lightSource: Entity,
                          place: @escaping @MainActor (Entity) -> Void = { _ in }) {
        Task { @MainActor in
            do {
                let model = try await Entity(named: name, in: Bundle.main)
                dress(model, looks: looks)
                place(model)
                if model.parent == nil { parent.addChild(model) }
                receiveLight(parent, from: lightSource)
            } catch {
                NSLog("TableProps: the model %@ did not load: %@", name, String(describing: error))
            }
        }
    }

    /// A plain upright cylinder for post `index`, named "post-<index>", standing on the cloth from y = 0 to its height.
    static func plainPost(index: Int, _ post: Post, frame: TableFrame, look: TablePartLook) -> ModelEntity {
        let h = Float(max(post.height, 0.005))
        let e = ModelEntity(mesh: .generateCylinder(height: h, radius: Float(post.radius)), materials: [material(look)])
        e.name = "post-\(index)"
        e.position = frame.world(post.center, height: h * 0.5)
        return e
    }

    /// A plain pin for pin `index`: an entity named "pin-<index>" whose origin is the pin's base centre on the cloth,
    /// holding a cylinder of the pin's radius and height above it (so TableScene can topple it about its base).
    static func plainPin(index: Int, _ pin: Pin, frame: TableFrame, look: TablePartLook) -> Entity {
        let holder = Entity()
        holder.name = "pin-\(index)"
        holder.position = frame.world(pin.center)
        let h = Float(max(pin.height, 0.005))
        let body = ModelEntity(mesh: .generateCylinder(height: h, radius: Float(pin.radius)), materials: [material(look)])
        body.position = SIMD3(0, h * 0.5, 0)
        holder.addChild(body)
        return holder
    }
}
