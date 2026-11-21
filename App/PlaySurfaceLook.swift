// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (Moon and cork beds; ice and glass refinished so the lamp no longer
//          shows on them as a hard, blown-out white disc, see the note on bedFinish).
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

    /// Why ice used to show a big round white blob: the lamp over the table is a single bright spot light (a point
    /// source) and the room picture it reflects holds one glowing rectangle. On a near-mirror finish (a full clear
    /// coat at clear-coat roughness 0.08, and glass at 0.02) each of those is mirrored as a small, hard, very bright
    /// patch, so the spot light became a sharp round disc off-centre where the lamp's reflection lands. Ice also had a
    /// near-white picture, so the plain lit area around it was nearly white too and the two ran together. The fix is
    /// in the beds alone (the lamp and room picture are untouched, so cloth, rails and balls look exactly as before):
    /// ice has a pale blue-grey picture and a softer, half-strength clear coat with blurred reflections, so the lamp
    /// reads as a broad sheen; glass keeps its dark mirror look but with enough blur that the lamp is a soft glow.
    var bedFinish: BedFinish {
        switch self {
        case .cloth: BedFinish(roughness: 0.93, sheen: SIMD3(0.35, 0.75, 0.62))
        // Worsted cloth has a tighter, flatter face than the standard cloth: a little less rough, a cool blue sheen.
        case .tournament: BedFinish(roughness: 0.88, sheen: SIMD3(0.35, 0.55, 0.85))
        // Napped felt is fuzzy and dull: fully rough, with a weak, greyed sheen.
        case .diveBar: BedFinish(roughness: 0.97, specular: 0.3, sheen: SIMD3(0.30, 0.38, 0.28))
        case .ice: BedFinish(roughness: 0.32, clearcoat: 0.45, clearcoatRoughness: 0.38, specular: 0.25)
        // Glass: the lamp is one small, very bright spot light, so a near-mirror finish turned it into a blown-out disc
        // (seen in the simulator after the ice fix). A little more roughness and a softer, weaker coat spread it into a
        // broad sheen that still reads as polished dark glass.
        case .glass: BedFinish(roughness: 0.3, clearcoat: 0.4, clearcoatRoughness: 0.32, specular: 0.22)
        case .sand: BedFinish(roughness: 1.0, specular: 0.15)
        case .carpet: BedFinish(roughness: 0.95, specular: 0.2, sheen: SIMD3(0.55, 0.25, 0.20))
        case .rubber: BedFinish(roughness: 0.82, specular: 0.3)
        // Lunar dust scatters light every way and has no shine at all.
        case .moon: BedFinish(roughness: 1.0, specular: 0.08)
        // Cork board: matte, with only a faint waxy sheen on the granules.
        case .cork: BedFinish(roughness: 0.78, specular: 0.28)
        }
    }

    /// Draws this surface's bed picture (the cloth's size, mapped once over the bed). Slow-ish and safe on any
    /// thread, so StartupAssets calls it in the background and keeps the result; nothing should call it per frame.
    func makeBedImage() -> CGImage? {
        switch self {
        case .cloth: SurfaceTextures.clothImage()
        case .tournament: SurfaceTextures.tournamentClothImage()
        case .diveBar: SurfaceTextures.diveBarFeltImage()
        case .ice: SurfaceTextures.iceImage()
        case .glass: SurfaceTextures.glassImage()
        case .sand: SurfaceTextures.sandImage()
        case .carpet: SurfaceTextures.carpetImage()
        case .rubber: SurfaceTextures.rubberImage()
        case .moon: SurfaceTextures.moonImage()
        case .cork: SurfaceTextures.corkImage()
        }
    }
}
