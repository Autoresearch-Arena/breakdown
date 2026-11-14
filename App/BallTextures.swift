// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
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

    /// How far (metres) the Lens grid picture extends past the playing surface on every side. It fades to nothing
    /// before its edge, so the Lens reads as a lit table in a dark room, not a full-bleed background.
    static let gridMargin = 0.6

    /// Blueprint grid for the Lens: a faint ten-centimetre grid with heavier lines every half metre, a slightly
    /// lighter playing surface, a clear but quiet outline of the cushion line, a fainter outline where the rails
    /// end, and a ring at every pocket (its capture radius). Everything fades out past the rails.
    /// Package 2 of the glow-up plan (13-Nov-2026): quieter lines so the glowing trails are the brightest thing on
    /// screen, plus the pocket rings and the edge fade.
    /// The picture is symmetric left-right and top-bottom, so how it is mapped onto the plane does not matter.
    static func gridTexture(length: Double, width: Double, pockets: [(x: Double, y: Double, radius: Double)]) -> TextureResource? {
        let ppm = 300.0   // pixels per metre
        let m = gridMargin
        // Increase Contrast: stronger grid and outlines (read at launch).
        let boost = LensTextures.increaseContrast ? 2.2 : 1.0
        let w = Int((length + 2 * m) * ppm), h = Int((width + 2 * m) * ppm)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        // Everything is drawn at full strength on a transparent ground, then multiplied by the edge fade at the end.
        // Lines are anchored to the table corner (0,0), which sits `m` metres inside the image.
        let ox = m * ppm, oy = m * ppm
        let tableRect = CGRect(x: ox, y: oy, width: length * ppm, height: width * ppm)
        // The playing surface: a very slightly lighter pane so the table reads as an object.
        ctx.setFillColor(CGColor(red: 0.04, green: 0.16, blue: 0.24, alpha: 0.22))
        ctx.fill(tableRect)
        func line(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ lw: Double, _ alpha: Double) {
            ctx.setStrokeColor(CGColor(red: 0.20, green: 0.75, blue: 0.95, alpha: alpha))
            ctx.setLineWidth(lw)
            ctx.move(to: CGPoint(x: x0, y: y0)); ctx.addLine(to: CGPoint(x: x1, y: y1)); ctx.strokePath()
        }
        var k = -Int(m / 0.1)
        while Double(k) * 0.1 <= length + m {
            let x = ox + Double(k) * 0.1 * ppm
            let heavy = k % 5 == 0
            line(x, 0, x, Double(h), heavy ? 1.6 : 0.7, min(1, (heavy ? 0.16 : 0.06) * boost))
            k += 1
        }
        k = -Int(m / 0.1)
        while Double(k) * 0.1 <= width + m {
            let y = oy + Double(k) * 0.1 * ppm
            let heavy = k % 5 == 0
            line(0, y, Double(w), y, heavy ? 1.6 : 0.7, min(1, (heavy ? 0.16 : 0.06) * boost))
            k += 1
        }
        // Where the rails end (the outer edge of the table), faint and dashed.
        let rail = 0.20 * ppm
        ctx.setStrokeColor(CGColor(red: 0.45, green: 0.95, blue: 1.0, alpha: min(1, 0.22 * boost)))
        ctx.setLineWidth(2)
        ctx.setLineDash(phase: 0, lengths: [10, 8])
        ctx.stroke(tableRect.insetBy(dx: -rail, dy: -rail))
        ctx.setLineDash(phase: 0, lengths: [])
        // The cushion line: the edge of the playing surface, where balls bounce. Quiet but unmistakable.
        ctx.setStrokeColor(CGColor(red: 0.45, green: 0.95, blue: 1.0, alpha: min(1, 0.50 * boost)))
        ctx.setLineWidth(3)
        ctx.stroke(tableRect)
        // Pockets: a ring at the capture radius with a soft dark well inside, so the player sees where a ball drops.
        for p in pockets {
            let c = CGPoint(x: ox + p.x * ppm, y: oy + p.y * ppm)
            let r = p.radius * ppm
            ctx.setFillColor(CGColor(red: 0.0, green: 0.02, blue: 0.05, alpha: 0.85))
            ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
            ctx.setStrokeColor(CGColor(red: 1.0, green: 0.82, blue: 0.25, alpha: 0.55))
            ctx.setLineWidth(2.5)
            ctx.strokeEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
        }
        // Edge fade: full strength out to the rail outline, gone before the picture ends. Multiply every pixel's
        // premultiplied colour and alpha by the same factor, which is exactly how a premultiplied fade works.
        if let data = ctx.data {
            let px = data.bindMemory(to: UInt8.self, capacity: w * h * 4)
            let stride = ctx.bytesPerRow
            for y in 0..<h {
                for x in 0..<w {
                    let dx = max(0, max(ox - Double(x), Double(x) - (ox + length * ppm))) / ppm
                    let dy = max(0, max(oy - Double(y), Double(y) - (oy + width * ppm))) / ppm
                    let d = (dx * dx + dy * dy).squareRoot()      // metres outside the playing surface
                    let t = min(1, max(0, (d - 0.22) / (m - 0.22)))
                    let f = 1 - t * t * (3 - 2 * t)
                    if f < 1 {
                        let i = y * stride + x * 4
                        for c in 0..<4 { px[i + c] = UInt8(Double(px[i + c]) * f + 0.5) }
                    }
                }
            }
        }
        return make(ctx)
    }

    private static func make(_ ctx: CGContext) -> TextureResource? {
        guard let image = ctx.makeImage() else { return nil }
        return try? TextureResource(image: image, options: .init(semantic: .color))
    }
}
