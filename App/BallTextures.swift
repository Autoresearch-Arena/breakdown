// Author: Claude Sonnet 5.5 Medium
// Date: 11-November-2026
// PURPOSE: Draws the ball surfaces (solid colours, stripes, number discs) and the Lens grid with CoreGraphics,
//          so the same code makes textures on iPhone and Mac and no image assets have to be shipped.
// SRP/DRY check: Pass - texture drawing only.
import CoreGraphics
import CoreText
import Foundation
import RealityKit

@MainActor
enum BallTextures {
    /// Palette for balls 1 to 8 (stripes 9 to 15 reuse 1 to 7). Original colour set, tuned for the teal felt.
    private static let palette: [(Double, Double, Double)] = [
        (0.96, 0.78, 0.12), (0.10, 0.30, 0.78), (0.86, 0.16, 0.14), (0.42, 0.16, 0.62),
        (0.95, 0.46, 0.10), (0.06, 0.52, 0.28), (0.52, 0.10, 0.14), (0.05, 0.05, 0.06),
    ]

    static func ballTexture(number: Int) -> TextureResource? {
        let w = 512, h = 256
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let ivory = CGColor(red: 0.96, green: 0.94, blue: 0.88, alpha: 1)
        if number == 0 {
            ctx.setFillColor(ivory); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            return make(ctx)
        }
        let base = palette[number <= 8 ? number - 1 : number - 9]
        let color = CGColor(red: base.0, green: base.1, blue: base.2, alpha: 1)
        let stripe = number > 8
        ctx.setFillColor(stripe ? ivory : color); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        if stripe {
            ctx.setFillColor(color); ctx.fill(CGRect(x: 0, y: Double(h) * 0.27, width: Double(w), height: Double(h) * 0.46))
        }
        // Number discs on two opposite sides of the equator so spin is easy to read.
        for cx in [Double(w) * 0.25, Double(w) * 0.75] {
            ctx.setFillColor(ivory)
            ctx.fillEllipse(in: CGRect(x: cx - 46, y: Double(h) / 2 - 46, width: 92, height: 92))
            drawNumber("\(number)", at: CGPoint(x: cx, y: Double(h) / 2), in: ctx)
        }
        return make(ctx)
    }

    private static func drawNumber(_ text: String, at center: CGPoint, in ctx: CGContext) {
        // Apple's own bold system font, so the ball numbers match the rest of the app.
        let font = CTFontCreateUIFontForLanguage(.emphasizedSystem, 56, nil) ?? CTFontCreateWithName("Helvetica-Bold" as CFString, 56, nil)
        let attrs: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        ctx.saveGState()
        ctx.setFillColor(CGColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1))
        ctx.textPosition = CGPoint(x: center.x - bounds.midX, y: center.y - bounds.midY)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }

    /// Blueprint grid, one line every ten centimetres with heavier lines every half metre, on a transparent ground.
    static func gridTexture(length: Double, width: Double) -> TextureResource? {
        let ppm = 400.0   // pixels per metre
        let w = Int((length + 0.4) * ppm), h = Int((width + 0.4) * ppm)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.setFillColor(CGColor(red: 0.01, green: 0.04, blue: 0.09, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        // Lines are anchored to the table corner (0,0), which sits 0.2 m inside the image.
        let ox = 0.2 * ppm, oy = 0.2 * ppm
        func line(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ width: Double, _ alpha: Double) {
            ctx.setStrokeColor(CGColor(red: 0.20, green: 0.75, blue: 0.95, alpha: alpha))
            ctx.setLineWidth(width)
            ctx.move(to: CGPoint(x: x0, y: y0)); ctx.addLine(to: CGPoint(x: x1, y: y1)); ctx.strokePath()
        }
        var k = -2
        while Double(k) * 0.1 <= length + 0.2 {
            let x = ox + Double(k) * 0.1 * ppm
            let heavy = k % 5 == 0
            line(x, 0, x, Double(h), heavy ? 2.4 : 1.0, heavy ? 0.55 : 0.22)
            k += 1
        }
        k = -2
        while Double(k) * 0.1 <= width + 0.2 {
            let y = oy + Double(k) * 0.1 * ppm
            let heavy = k % 5 == 0
            line(0, y, Double(w), y, heavy ? 2.4 : 1.0, heavy ? 0.55 : 0.22)
            k += 1
        }
        // The playing surface outline.
        ctx.setStrokeColor(CGColor(red: 0.45, green: 0.95, blue: 1.0, alpha: 0.9))
        ctx.setLineWidth(3)
        ctx.stroke(CGRect(x: ox, y: oy, width: length * ppm, height: width * ppm))
        return make(ctx)
    }

    private static func make(_ ctx: CGContext) -> TextureResource? {
        guard let image = ctx.makeImage() else { return nil }
        return try? TextureResource(image: image, options: .init(semantic: .color))
    }
}
