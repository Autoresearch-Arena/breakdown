// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: Draws the ball surfaces (solid colours, stripes, number discs) and the Lens grid with CoreGraphics,
//          so the same code makes textures on iPhone and Mac and no image assets have to be shipped.
//          13-Nov-2026 (glow-up package 1): ball pictures are now twice as sharp, with larger number discs, bolder
//          numerals and a thin dark ring so the digit and the stripe still read when a ball is only a few dozen
//          pixels wide on a phone; every picture gets mipmaps so distant balls do not shimmer.
//          The cloth, wood and floor pictures live in SurfaceTextures.swift.
// SRP/DRY check: Pass - ball and Lens-grid drawing only; table surfaces are in SurfaceTextures.swift.
import CoreGraphics
import CoreText
import Foundation
import RealityKit
import simd

@MainActor
enum BallTextures {
    /// Palette for balls 1 to 8 (stripes 9 to 15 reuse 1 to 7). Original colour set, tuned for the teal felt.
    private static let palette: [(Double, Double, Double)] = [
        (0.96, 0.78, 0.12), (0.10, 0.30, 0.78), (0.86, 0.16, 0.14), (0.42, 0.16, 0.62),
        (0.95, 0.46, 0.10), (0.06, 0.52, 0.28), (0.52, 0.10, 0.14), (0.05, 0.05, 0.06),
    ]

    // MARK: Balls

    /// Size of each ball picture. Pixel-by-pixel evaluation (below) keeps the cost bounded: 16 balls at this size.
    private static let ballW = 512, ballH = 256

    /// For every pixel of a ball picture, the direction on the sphere it covers (y is the pole axis). Built once and
    /// shared by all sixteen balls.
    private static let directionTable: [SIMD3<Float>] = {
        var t = [SIMD3<Float>]()
        t.reserveCapacity(ballW * ballH)
        for y in 0..<ballH {
            let lat = (0.5 - (Float(y) + 0.5) / Float(ballH)) * .pi
            for x in 0..<ballW {
                let lon = (Float(x) + 0.5) / Float(ballW) * 2 * .pi
                t.append(SIMD3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon)))
            }
        }
        return t
    }()

    /// The number as a 256 by 256 coverage picture (255 = ink), drawn in Apple's bold system font and centred.
    private static func glyph(_ text: String) -> [UInt8] {
        let n = 256
        var pixels = [UInt8](repeating: 0, count: n * n)
        pixels.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(data: raw.baseAddress, width: n, height: n, bitsPerComponent: 8, bytesPerRow: n,
                                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return }
            // Two-digit numbers are squeezed a little so both digits fit inside the disc.
            let size: CGFloat = text.count > 1 ? 150 : 190
            let font = CTFontCreateUIFontForLanguage(.emphasizedSystem, size, nil) ?? CTFontCreateWithName("Helvetica-Bold" as CFString, size, nil)
            let attrs: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key(kCTFontAttributeName as String): font,
                NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
            ]
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
            let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
            ctx.setFillColor(gray: 1, alpha: 1)
            ctx.textPosition = CGPoint(x: CGFloat(n) / 2 - bounds.midX, y: CGFloat(n) / 2 - bounds.midY)
            CTLineDraw(line, ctx)
        }
        return pixels
    }

    private static func smooth(_ e0: Float, _ e1: Float, _ x: Float) -> Float {
        let t = max(0, min(1, (x - e0) / (e1 - e0)))
        return t * t * (3 - 2 * t)
    }

    /// One ball's picture. Solid balls are one colour; stripes are ivory with a coloured band round the middle. Both
    /// carry an ivory number disc at each end of the line through the band's middle, exactly as a real ball does,
    /// sized like the real one (a bit over half the ball's width). The disc is tilted toward the camera and turned a
    /// little differently for each ball, so in the resting rack most numbers face the viewer, as in a real rack.
    static func ballTexture(number: Int) -> TextureResource? {
        let w = ballW, h = ballH
        var raster = [UInt8](repeating: 255, count: w * h * 4)
        func rgb(_ c: (Double, Double, Double)) -> SIMD3<Float> { SIMD3(Float(c.0), Float(c.1), Float(c.2)) }
        let ivory = SIMD3<Float>(0.96, 0.94, 0.88)
        let ink = SIMD3<Float>(0.05, 0.05, 0.06)
        func put(_ i: Int, _ c: SIMD3<Float>) {
            raster[i * 4] = UInt8(max(0, min(255, c.x * 255 + 0.5)))
            raster[i * 4 + 1] = UInt8(max(0, min(255, c.y * 255 + 0.5)))
            raster[i * 4 + 2] = UInt8(max(0, min(255, c.z * 255 + 0.5)))
        }
        if number == 0 {
            for i in 0..<(w * h) { put(i, ivory) }
            return make(raster: raster, w: w, h: h)
        }
        let base = rgb(palette[number <= 8 ? number - 1 : number - 9])
        let stripe = number > 8
        let text = glyph("\(number)")

        // Disc axis B: tilted from straight up toward the camera side (about 40 degrees), then turned by a per-ball angle.
        let seed = Float(number)
        let tilt = (36 + 10 * sin(seed * 2.3)) * .pi / 180
        let turn = (14 * sin(seed * 1.7)) * .pi / 180
        let B = SIMD3<Float>(sin(tilt) * cos(turn), cos(tilt), sin(tilt) * sin(turn))
        // Band axis A and the disc's own up direction T2 live in the plane across B; a per-ball roll sets which way.
        // Turn so the digits' up direction points away from the camera (up the screen) give or take about 25 degrees,
        // which keeps every number readable instead of upside down.
        let roll = Float.pi + 0.45 * sin(seed * 1.9)
        let ref = simd_normalize(simd_cross(B, SIMD3(0, 0, 1)))
        let ref2 = simd_cross(B, ref)
        let A = ref * cos(roll) + ref2 * sin(roll)
        let T1 = simd_cross(A, B)          // sideways on the disc
        let T2 = A                         // along the band's axis: digits read upright along the line of the band
        let discAngle: Float = 0.59        // disc radius as an angle round the ball (a real disc is 0.555 of the radius wide)
        let discSin = sin(discAngle)
        let bandHalf: Float = 0.50         // stripe half-width as sin(angle) from the band's middle

        for i in 0..<(w * h) {
            let d = directionTable[i]
            // Body colour: solid colour, or ivory with a coloured band.
            var c: SIMD3<Float>
            if stripe {
                let inBand = 1 - smooth(bandHalf - 0.015, bandHalf + 0.015, abs(simd_dot(d, A)))
                c = ivory + (base - ivory) * inBand
            } else {
                c = base
            }
            // Number discs on both ends of B.
            let db = simd_dot(d, B)
            let sgn: Float = db >= 0 ? 1 : -1
            let along = abs(db)
            // Angle from the disc centre via sin, cheap and smooth enough for an edge.
            let off = (max(0, 1 - along * along)).squareRoot()
            // Thin dark ring just outside the disc, then the ivory disc.
            let ring = 1 - smooth(discSin + 0.006, discSin + 0.03, off)
            if along > 0 {
                let discMask = 1 - smooth(discSin - 0.012, discSin + 0.008, off)
                let ringMask = ring - discMask
                if ringMask > 0 { c = c + (ink - c) * (ringMask * 0.5) }
                if discMask > 0 {
                    // Coordinates in the disc, -1 to 1 across it; the far-side disc is seen from the other direction.
                    let s = -simd_dot(d, T1) * sgn / discSin, t = simd_dot(d, T2) / discSin
                    var cover: Float = 0
                    let gx = Int((s * 0.5 + 0.5) * 255), gy = Int((0.5 - t * 0.5) * 255)
                    if gx >= 0 && gx < 256 && gy >= 0 && gy < 256 { cover = Float(text[gy * 256 + gx]) / 255 }
                    let disc = ivory + (ink - ivory) * cover
                    c = c + (disc - c) * discMask
                }
            }
            put(i, c)
        }
        return make(raster: raster, w: w, h: h)
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

    /// Turns a finished RGBA byte raster (opaque) into a texture with mipmaps.
    private static func make(raster: [UInt8], w: Int, h: Int) -> TextureResource? {
        guard let provider = CGDataProvider(data: Data(raster) as CFData),
              let image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return nil }
        return try? TextureResource(image: image, options: .init(semantic: .color, mipmapsMode: .allocateAndGenerateAll))
    }

    private static func make(_ ctx: CGContext) -> TextureResource? {
        guard let image = ctx.makeImage() else { return nil }
        return try? TextureResource(image: image, options: .init(semantic: .color, mipmapsMode: .allocateAndGenerateAll))
    }
}
