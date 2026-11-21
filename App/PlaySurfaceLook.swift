// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: How each playing surface LOOKS on the warm table: which generated picture its playing bed wears and the
//          finish of that bed (how rough or glossy it is, whether it has a clear coat, a fabric sheen, how strong its
//          highlights are). The physics of each surface (friction, bounce) lives with the enum itself in
//          PlaySurface.swift; this file is only the renderer's side of it.
//          Read by: StartupAssets (which picture to draw and cache, off the main thread) and TableBuilder.bedMaterial
//          (which turns picture plus finish into the bed's material). Only the playing bed changes with the surface:
//          the cushions are the rail's rubber wrapped in cloth, so they keep the cloth whatever the bed is made of.
//          Glass is drawn opaque on purpose: the bed is one flat sheet with the pocket wells right under it, and a
//          see-through bed would show the inside of the table and sort badly against the wells.
// SRP/DRY check: Pass - looks only. The pictures themselves are drawn in SurfaceTextures (next to the cloth); the
//          material is assembled in TableBuilder; nothing here touches the physics numbers.
import CoreGraphics
import Foundation
import simd

extension PlaySurface {
    /// The playing bed's finish on this surface. TableBuilder.bedMaterial turns it into a material.
    struct BedFinish: Sendable {
        /// 0 is a mirror, 1 is fully matte.
        var roughness: Float
        /// A clear lacquer layer on top (ice and glass), and how blurred its reflections are.
        var clearcoat: Float = 0
        var clearcoatRoughness: Float = 0.3
        /// Strength of highlights; nil leaves the material's default (the cloth was tuned with the default).
        var specular: Float? = nil
        /// A soft glow at grazing angles, as fabric has (cloth and carpet only); linear red, green, blue.
        var sheen: SIMD3<Float>? = nil
    }

    var bedFinish: BedFinish {
        switch self {
        case .cloth: BedFinish(roughness: 0.93, sheen: SIMD3(0.35, 0.75, 0.62))
        case .ice: BedFinish(roughness: 0.22, clearcoat: 1, clearcoatRoughness: 0.08, specular: 0.6)
        case .glass: BedFinish(roughness: 0.05, clearcoat: 1, clearcoatRoughness: 0.02, specular: 0.9)
        case .sand: BedFinish(roughness: 1.0, specular: 0.15)
        case .carpet: BedFinish(roughness: 0.95, specular: 0.2, sheen: SIMD3(0.55, 0.25, 0.20))
        case .rubber: BedFinish(roughness: 0.82, specular: 0.3)
        }
    }

    /// Draws this surface's bed picture (the cloth's size, mapped once over the bed). Slow-ish and safe on any
    /// thread, so StartupAssets calls it in the background and keeps the result; nothing should call it per frame.
    func makeBedImage() -> CGImage? {
        switch self {
        case .cloth: SurfaceTextures.clothImage()
        case .ice: SurfaceTextures.iceImage()
        case .glass: SurfaceTextures.glassImage()
        case .sand: SurfaceTextures.sandImage()
        case .carpet: SurfaceTextures.carpetImage()
        case .rubber: SurfaceTextures.rubberImage()
        }
    }
}
