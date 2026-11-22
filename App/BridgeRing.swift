// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: an awkward stance's ring is magenta, Theme.slideRGB and
//          its Increase Contrast tone Theme.slideHighRGB, read from Theme instead of typed in, so it always matches
//          Palette.slide.)
// PURPOSE: The bridge mark as a flat ring lying on the cloth in the 3D scene (plans/21-Nov-2026-bugs-after-0-6-6-plan.md
//          item 23). Until 0.7.0 the mark was a flat drawing in AimOverlay's 2D layer, painted over the 3D picture, so it
//          sat on top of the cue's shaft and, on every bridge shot, right on the chrome bridge head. Here it is part of
//          the table: a soft chalk ring at the bridge hand's spot (model.strokeBridgeLength behind the cue ball along the
//          cue) with a faint line from it to the back of the cue ball, lying just above the cloth, so the 3D cue and
//          the bridge pass over it and cover it as real ones would. Paper white for a square stance with a clear path,
//          magenta when the stance is not (App/Stroke/Reach.swift); with Differentiate Without Colour an
//          awkward stance also gets an inner ring, so it never rests on colour alone. The ring is left out while the
//          mechanical rest is drawn (model.restInUse): the rest's head stands there itself.
//          Integration: TableStage builds a BridgeMark from the model each frame while the cue may show (nil
//          otherwise) and hands it through TableScene.apply to TableDetail, whose root (re-hung under every rebuilt
//          table group, so the ring fades out with the table as the Lens melts in) holds this ring's root.
//          Sizes: the ring's radius is the old flat mark's 3 cm (about a bridge hand's knuckles across); its core line
//          2 mm and its halo 10 mm wide, the old 1.5-point and 6-point strokes at the size a ball is on an iPad.
// SRP/DRY check: Pass - checked AimOverlay.drawBridgeMark (the flat mark this replaces; its colours and opacities are
//          carried over here), CueRig (the cue and rest themselves; it draws no mark) and TableDetail (the other
//          per-frame table detail; it owns this ring's place in the scene). The flat ring meshes come from MeshBuilder.
import BreakdownLensModel
import Foundation
import RealityKit
import simd

/// What the bridge mark shows this frame, in table plan coordinates (metres).
struct BridgeMark: Equatable {
    /// Where the bridge hand rests.
    var spot: Vec2
    /// The back of the cue ball along the cue, where the faint line ends.
    var ballBack: Vec2
    /// The stance is not square (a stretch, behind the back, on the rail, the rest, or a raised cue): magenta.
    var awkward: Bool
    /// Differentiate Without Colour is on: an awkward stance also gets an inner ring.
    var innerRing: Bool
}

@MainActor
final class BridgeRing {
    /// Parent of the ring's parts; TableDetail hangs it under its own root.
    let root = Entity()
    private let halo: ModelEntity
    private let core: ModelEntity
    private let inner: ModelEntity
    private let line: ModelEntity
    /// The colour last put on (nil before the first frame), so the materials change only when the stance does.
    private var shownAwkward: Bool?

    /// The ring's radius, metres (see the header), and the inner ring's.
    static let radius: Float = 0.03
    static let innerRadius: Float = 0.015
    /// Height above the cloth: over the balls' contact shadows (0.7 mm) and the cue's shadow (0.9 mm), well under a
    /// ball's lowest point, so nothing on the cloth flickers through it.
    static let lift: Float = 0.0012

    init() {
        root.name = "bridge-ring"
        halo = ModelEntity(mesh: Self.annulus(radius: Self.radius, width: 0.010), materials: [])
        core = ModelEntity(mesh: Self.annulus(radius: Self.radius, width: 0.002), materials: [])
        inner = ModelEntity(mesh: Self.annulus(radius: Self.innerRadius, width: 0.002), materials: [])
        line = ModelEntity(mesh: .generatePlane(width: 1, depth: 1), materials: [])
        for part in [halo, core, inner, line] {
            part.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(part)
        }
        root.isEnabled = false
        colour(awkward: false)
    }

    /// Show the mark for this frame, or hide it (nil).
    func update(_ mark: BridgeMark?, frame: TableFrame) {
        guard let mark else {
            if root.isEnabled { root.isEnabled = false }
            return
        }
        root.isEnabled = true
        if shownAwkward != mark.awkward { colour(awkward: mark.awkward) }
        let centre = frame.world(mark.spot, height: Self.lift)
        for ring in [halo, core, inner] { ring.position = centre }
        inner.isEnabled = mark.awkward && mark.innerRing
        // The faint line: from the ring's edge toward the cue ball to the ball's back edge, 1.5 mm wide.
        let along = mark.ballBack - mark.spot
        let length = Float(along.length) - Self.radius
        guard length > 0.005 else { line.isEnabled = false; return }
        line.isEnabled = true
        let dir = simd_normalize(frame.direction(along))
        let start = centre + dir * Self.radius
        line.position = start + dir * (length * 0.5)
        // A plane's depth runs along its own z: turn it about y so z lies along the line.
        line.orientation = simd_quatf(angle: atan2(dir.x, dir.z), axis: SIMD3(0, 1, 0))
        line.scale = SIMD3(0.0015, 1, length)
    }

    /// Paper or magenta, at the old flat mark's strengths (halo 0.16, ring 0.75, line 0.35); the brighter tones under
    /// Increase Contrast, as the palette resolves them (Theme's paper and slide).
    private func colour(awkward: Bool) {
        shownAwkward = awkward
        let high = LensTextures.increaseContrast
        let ink: (Double, Double, Double) = awkward ? (high ? Theme.slideHighRGB : Theme.slideRGB)
                                                   : (high ? (1.0, 1.0, 1.0) : (0.92, 0.96, 1.0))
        func material(_ opacity: Float) -> UnlitMaterial {
            var m = UnlitMaterial(color: rgba(ink.0, ink.1, ink.2))
            m.blending = .transparent(opacity: .init(floatLiteral: opacity))
            return m
        }
        halo.model?.materials = [material(0.16)]
        core.model?.materials = [material(0.75)]
        inner.model?.materials = [material(0.75)]
        line.model?.materials = [material(0.35)]
    }

    /// A flat ring lying in the plane y = 0 (normal up), centred on the origin.
    private static func annulus(radius: Float, width: Float) -> MeshResource {
        var b = MeshBuilder()
        let n = 48
        let up = SIMD3<Float>(0, 1, 0)
        let r0 = radius - width * 0.5, r1 = radius + width * 0.5
        for i in 0..<n {
            let a0 = Float(i) / Float(n) * 2 * .pi, a1 = Float(i + 1) / Float(n) * 2 * .pi
            let p = [SIMD3(r0 * cos(a0), 0, r0 * sin(a0)), SIMD3(r1 * cos(a0), 0, r1 * sin(a0)),
                     SIMD3(r1 * cos(a1), 0, r1 * sin(a1)), SIMD3(r0 * cos(a1), 0, r0 * sin(a1))]
            let v = p.map { b.vertex($0, up, .zero) }
            b.quad(v[0], v[1], v[2], v[3])
        }
        // A ring always has triangles, so resource() only fails if the system refuses the mesh; a tiny plane then
        // stands in rather than leaving the entity without a mesh.
        return b.resource() ?? .generatePlane(width: 0.001, depth: 0.001)
    }
}
