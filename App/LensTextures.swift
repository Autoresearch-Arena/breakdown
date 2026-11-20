// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// Edited: Claude Opus 5.5 High, 20-November-2026 (the legend is just the two colours now; its third phrase overflowed the card).
// Edited: Claude Opus 5.5 High, 20-November-2026 (the baked legend picture is gone: the legend is a SwiftUI glass chip in
//          the title row (LensLegendChip in CaptionViews), so it follows Dynamic Type and VoiceOver and costs no table room).
// PURPOSE: Draws the small generated pictures the Physics Lens glows with, in code, so no image assets ship:
//          1. the TRAIL picture: one strip per motion colour whose long axis is AGE (bright, white-hot at the head,
//             easing to a faint trace for old path) and whose short axis is the soft cross-section of a glowing line
//             (thin bright core, wider soft halo). The trail meshes carry the time of each vertex as a texture
//             coordinate and the Lens slides the picture along with the playback clock, so the fade with age is a pure
//             function of the clock (see LensLayer.trailBrightness) and scrubbing either way is exact.
//          2. the SOFT LINE picture: just the cross-section, tinted per use, for impact rings and velocity arrows.
//          Pixels are written straight into a byte buffer (no CoreGraphics compositing) so the brightness at each
//          texel is exactly the number the formulas say.
//          Package 4 (0.4.0): the trail picture now also narrows the line with age (older path is a hairline).
//          Does NOT belong here: where the pictures are used (LensLayer.swift), the grid (BallTextures.gridTexture).
// SRP/DRY check: Pass - Lens picture generation only; colours arrive from Theme through the caller.
import CoreGraphics
import Foundation
import RealityKit
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

@MainActor
enum LensTextures {
    /// System "Increase Contrast" setting (iOS: Darker System Colors). Read when the pictures are built (at launch), so a
    /// change needs a relaunch.
    static var increaseContrast: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isDarkerSystemColorsEnabled
        #else
        return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        #endif
    }

    /// Texels along the age axis of the trail picture.
    nonisolated static let trailWidth = 1024
    /// Texels across the trail (the soft cross-section).
    nonisolated static let trailHeight = 32
    /// Seconds of age the trail picture spans. Anything older reads the faint-trace end of the picture.
    nonisolated static let ageWindow: Double = 4.0
    /// Where "now" sits along the age axis (0 to 1). Everything to its right (the future) is transparent.
    nonisolated static let headX: Double = 0.985

    // MARK: Cross-section

    /// Brightness (0 to 1) across a glowing line: `d` is 0 at the middle and 1 at the edge.
    /// A thin bright core plus a wider soft halo; `haloGain` scales the halo (lower when a real bloom pass adds its own).
    static func crossSection(_ d: Double, haloGain: Double) -> (alpha: Double, whiten: Double) {
        func smooth(_ a: Double, _ b: Double, _ x: Double) -> Double {
            let t = min(1, max(0, (x - a) / (b - a)))
            return t * t * (3 - 2 * t)
        }
        let core = 1 - smooth(0.26, 0.42, d)
        let halo = haloGain * 0.62 * exp(-(d / 0.62) * (d / 0.62))
        let taper = 1 - smooth(0.80, 1.0, d)
        return (max(core, halo) * taper, core)
    }

    // MARK: Pixels to texture

    private static func texture(width: Int, height: Int, pixel: (Int, Int) -> (Double, Double, Double, Double)) -> TextureResource? {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let (r, g, b, a) = pixel(x, y)
                let i = (y * width + x) * 4
                bytes[i] = UInt8(max(0, min(255, r * 255 + 0.5)))
                bytes[i + 1] = UInt8(max(0, min(255, g * 255 + 0.5)))
                bytes[i + 2] = UInt8(max(0, min(255, b * 255 + 0.5)))
                bytes[i + 3] = UInt8(max(0, min(255, a * 255 + 0.5)))
            }
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider,
                                  decode: nil, shouldInterpolate: false, intent: .defaultIntent) else { return nil }
        // No mipmaps: the age axis must stay crisp so the head of a trail is a clean edge.
        return try? TextureResource(image: image, options: .init(semantic: .color, mipmapsMode: .none))
    }

    // MARK: Trail picture

    /// One picture per motion colour. `brightness` maps age in seconds to 0...1 (LensLayer.trailBrightness); `width` maps
    /// age to the share of the fresh width still drawn (LensLayer.trailWidth).
    static func trail(color: (Double, Double, Double), haloGain: Double, brightness: (Double) -> Double,
                      width: (Double) -> Double) -> TextureResource? {
        texture(width: trailWidth, height: trailHeight) { x, y in
            let xn = (Double(x) + 0.5) / Double(trailWidth)
            // Future (right of the head): transparent. The sampler clamps to this edge, so every vertex whose time
            // has not come yet draws nothing, with no per-piece switching.
            guard xn <= headX else { return (color.0, color.1, color.2, 0) }
            let age = (headX - xn) * ageWindow
            let v = (Double(y) + 0.5) / Double(trailHeight)
            // Older path is drawn thinner: dividing the distance by the width shrinks the whole cross-section (core and
            // halo) toward the middle, so a late-break frame shows fresh bold lines over old hairlines.
            let d = abs(v - 0.5) * 2 / max(0.05, width(age))
            let cs = crossSection(min(d, 1.0), haloGain: haloGain)
            // White-hot at the head, settling to the motion colour over the first quarter second; the core is
            // whiter than the halo so a bright line reads as light, not paint.
            let hot = exp(-age / 0.22) * 0.6 + cs.whiten * 0.42
            let r = color.0 + (1 - color.0) * hot, g = color.1 + (1 - color.1) * hot, b = color.2 + (1 - color.2) * hot
            return (r, g, b, cs.alpha * brightness(age))
        }
    }

    // MARK: Soft line picture (rings, arrows)

    /// A white glowing cross-section with its peak at `peak` (0.5 for a centred line, nearer 1 for a ring whose
    /// outer edge is its bright rim). Tinted per use by the material colour.
    static func softLine(peak: Double, haloGain: Double) -> TextureResource? {
        texture(width: 4, height: 64) { _, y in
            let v = (Double(y) + 0.5) / 64
            // Distance from the peak, scaled so the far side of the strip reaches 1 at the strip's own edge.
            let reach = max(peak, 1 - peak)
            let d = abs(v - peak) / reach
            let cs = crossSection(d, haloGain: haloGain)
            return (1, 1, 1, cs.alpha)
        }
    }
}
