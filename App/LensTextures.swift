// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: Draws the small generated pictures the Physics Lens glows with, in code, so no image assets ship:
//          1. the TRAIL picture: one strip per motion colour whose long axis is AGE (bright, white-hot at the head,
//             easing to a faint trace for old path) and whose short axis is the soft cross-section of a glowing line
//             (thin bright core, wider soft halo). The trail meshes carry the time of each vertex as a texture
//             coordinate and the Lens slides the picture along with the playback clock, so the fade with age is a pure
//             function of the clock (see LensLayer.trailBrightness) and scrubbing either way is exact.
//          2. the SOFT LINE picture: just the cross-section, tinted per use, for impact rings and velocity arrows.
//          3. the LEGEND picture: the "what the colours mean" card shown the first time trails appear.
//          Pixels are written straight into a byte buffer (no CoreGraphics compositing) so the brightness at each
//          texel is exactly the number the formulas say. The legend is the only text and uses CoreText.
//          Does NOT belong here: where the pictures are used (LensLayer.swift), the grid (BallTextures.gridTexture).
// SRP/DRY check: Pass - Lens picture generation only; colours arrive from Theme through the caller.
import CoreGraphics
import CoreText
import Foundation
import RealityKit
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

@MainActor
enum LensTextures {
    /// System "Reduce Transparency" setting. Read when the pictures are built (at launch), so a change needs a relaunch.
    static var reduceTransparency: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isReduceTransparencyEnabled
        #else
        return NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        #endif
    }
    /// System "Increase Contrast" setting (iOS: Darker System Colors). Same read-at-launch rule.
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

    /// One picture per motion colour. `brightness` maps age in seconds to 0...1 (LensLayer.trailBrightness).
    static func trail(color: (Double, Double, Double), haloGain: Double, brightness: (Double) -> Double) -> TextureResource? {
        texture(width: trailWidth, height: trailHeight) { x, y in
            let xn = (Double(x) + 0.5) / Double(trailWidth)
            // Future (right of the head): transparent. The sampler clamps to this edge, so every vertex whose time
            // has not come yet draws nothing, with no per-piece switching.
            guard xn <= headX else { return (color.0, color.1, color.2, 0) }
            let age = (headX - xn) * ageWindow
            let v = (Double(y) + 0.5) / Double(trailHeight)
            let d = abs(v - 0.5) * 2
            let cs = crossSection(d, haloGain: haloGain)
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

    // MARK: Legend

    /// The legend card: two coloured line samples with names, and one quiet line saying what width and fade mean.
    /// Drawn at 4 pixels per point of `CameraFraming.legendSize`. Not scaled by Dynamic Type (it is a baked picture);
    /// the plan's Open items note that.
    static func legend(amber: (Double, Double, Double), cyan: (Double, Double, Double)) -> TextureResource? {
        let scale = 4.0
        let size = CameraFraming.legendSize
        let w = Int(Double(size.width) * scale), h = Int(Double(size.height) * scale)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.scaleBy(x: scale, y: scale)
        let pw = Double(size.width), ph = Double(size.height)
        // Dark rounded card so the text reads over the grid at any contrast.
        let card = CGPath(roundedRect: CGRect(x: 0, y: 0, width: pw, height: ph), cornerWidth: 10, cornerHeight: 10, transform: nil)
        ctx.addPath(card)
        // Reduce Transparency: a solid card. Increase Contrast: a brighter edge as well.
        ctx.setFillColor(CGColor(red: 0.03, green: 0.06, blue: 0.10, alpha: reduceTransparency ? 1.0 : 0.82))
        ctx.fillPath()
        ctx.addPath(card)
        ctx.setStrokeColor(CGColor(red: 0.30, green: 0.88, blue: 1.0, alpha: increaseContrast ? 0.95 : 0.30))
        ctx.setLineWidth(increaseContrast ? 1.5 : 1)
        ctx.strokePath()

        func sample(_ c: (Double, Double, Double), x: Double, y: Double) {
            // Soft halo under a bright core, like the trail itself.
            ctx.setLineCap(.round)
            ctx.setStrokeColor(CGColor(red: c.0, green: c.1, blue: c.2, alpha: 0.30)); ctx.setLineWidth(9)
            ctx.move(to: CGPoint(x: x, y: y)); ctx.addLine(to: CGPoint(x: x + 22, y: y)); ctx.strokePath()
            ctx.setStrokeColor(CGColor(red: c.0, green: c.1, blue: c.2, alpha: 1)); ctx.setLineWidth(3.5)
            ctx.move(to: CGPoint(x: x, y: y)); ctx.addLine(to: CGPoint(x: x + 22, y: y)); ctx.strokePath()
        }
        // Coordinates are y-up: the top row sits near ph.
        sample(amber, x: 12, y: ph - 14)
        sample(cyan, x: 112, y: ph - 14)
        text("Sliding", at: CGPoint(x: 40, y: ph - 14), size: 13, weight: .semibold, white: 1.0, in: ctx)
        text("Rolling", at: CGPoint(x: 140, y: ph - 14), size: 13, weight: .semibold, white: 1.0, in: ctx)
        text("Thicker = faster. Older path fades.", at: CGPoint(x: 12, y: 10), size: 10.5, weight: .regular, white: increaseContrast ? 1.0 : 0.78, in: ctx)
        guard let image = ctx.makeImage() else { return nil }
        return try? TextureResource(image: image, options: .init(semantic: .color))
    }

    private static func text(_ s: String, at p: CGPoint, size: CGFloat, weight: LegendWeight, white: Double, in ctx: CGContext) {
        // Apple's own system font, as everywhere else in the app.
        let type: CTFontUIFontType = weight == .semibold ? .emphasizedSystem : .system
        let font = CTFontCreateUIFontForLanguage(type, size, nil) ?? CTFontCreateWithName("Helvetica" as CFString, size, nil)
        let attrs: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(red: white, green: white, blue: white, alpha: 1),
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attrs))
        let b = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        ctx.saveGState()
        ctx.textPosition = CGPoint(x: p.x, y: p.y - b.midY)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }
}

/// Just enough weight vocabulary for the legend's two text styles.
private enum LegendWeight { case regular, semibold }
