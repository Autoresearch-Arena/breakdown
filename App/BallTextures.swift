// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (swatch(number:): a ball's main colour for the flat ball icons in the
//          match banner, read from the same palette the 3D balls use, so the two never disagree.)
// PURPOSE: Draws the ball surfaces (solid colours, stripes, number discs) and the Lens grid with CoreGraphics,
//          so the same code makes pictures on iPhone and Mac and no image assets have to be shipped.
//          13-Nov-2026 (glow-up package 1): ball pictures are twice as sharp, with larger number discs, bolder
//          numerals and a thin dark ring so the digit and the stripe still read when a ball is only a few dozen
//          pixels wide on a phone; every picture gets mipmaps so distant balls do not shimmer.
//          13-Nov-2026 (package 0.4.1, start-up speed): the drawing functions (ballImage, gridImage) now return plain
//          CGImages and touch nothing shared, so StartupAssets can draw all of them on background threads at launch.
//          Only gridTexture (a thin main-thread wrapper the Lens still calls) makes a RealityKit texture.
//          The cloth, wood and floor pictures live in SurfaceTextures.swift.
// Edited: Claude Opus 5.5 High, 21-November-2026 (look plan package 3: a second, high-contrast set of ball pictures for
//          when a ball is small on screen (ballImage(number:compact:)): a wider stripe, a larger number disc, a heavier
//          numeral, a darker ring and deeper colours, so stripes and numbers still read on a phone held upright;
//          TableDetail swaps to them below a measured on-screen size. Also colour(of:) for the aiming badge.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 21 and 35: the pool cue ball carries six flush oxblood
//          marks, copied from the other developer's spotted cue ball (art/equipment/spotted-cue-ball.blend), so the ball's
//          turning, which it already does with its recorded spin, shows draw, stun and follow in the ordinary view; and
//          each table's own balls (TableBallSet): ballImage(look:compact:) draws a plain white, red or yellow ball and
//          bumper pool's marked ball (one colour with a spot of the other side's colour at each end of one axis);
//          swatch(_ look:) gives a look's main colour for flat icons, the contract's call for the match views.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: the Lens grid draws every pocket and bed hole as a real hole,
//          an opaque near-black disc at its capture radius inside a clear light rim with a soft glow, on a slightly
//          lighter playing surface, so a glance at a lesson or the Lens shows the holes; the old faint well and thin gold
//          ring read as a bare rectangle. The rim follows Increase Contrast like the grid lines.)
// SRP/DRY check: Pass - ball and Lens-grid drawing only; table surfaces are in SurfaceTextures.swift and the
//          timing of it all is in StartupAssets.swift. Which ball wears which look is TableBallSet's; which picture a ball
//          wears on screen is TableDetail's.
import CoreGraphics
import CoreText
import Foundation
import RealityKit  // TextureResource, for the grid wrapper
import simd

enum BallTextures {
    /// Palette for balls 1 to 8 (stripes 9 to 15 reuse 1 to 7). Original colour set, tuned for the teal felt.
    private static let palette: [(Double, Double, Double)] = [
        (0.96, 0.78, 0.12), (0.10, 0.30, 0.78), (0.86, 0.16, 0.14), (0.42, 0.16, 0.62),
        (0.95, 0.46, 0.10), (0.06, 0.52, 0.28), (0.52, 0.10, 0.14), (0.05, 0.05, 0.06),
    ]

    /// A ball's main colour, red-green-blue from 0 to 1: the solid's colour, or the stripe's band (9 to 15 reuse 1 to
    /// 7, as the pictures do); ball 0 is the cue ball's ivory. For small flat icons outside the 3D scene.
    static func swatch(number: Int) -> (Double, Double, Double) {
        guard number > 0 else { return ivoryRGB }
        let i = number <= 8 ? number - 1 : number - 9
        return palette[max(0, min(i, palette.count - 1))]
    }

    /// The same colour under the name the aiming badge (TargetBallBadge) uses.
    static func colour(of number: Int) -> (Double, Double, Double) {
        swatch(number: number)
    }

    /// The colours of the other tables' balls. White is the pool cue ball's ivory and red and yellow are the pool
    /// palette's own (the 3 and the 1), so a table's balls sit in the same family as the pool set.
    static func colour(_ c: BallColour) -> (Double, Double, Double) {
        switch c {
        case .white: return ivoryRGB
        case .red: return palette[2]
        case .yellow: return palette[0]
        }
    }

    /// A look's main colour, red-green-blue from 0 to 1, for small flat icons (the match banner's ball icons, the
    /// aiming badge): the pool ball's colour, a plain ball's colour, or a marked ball's body colour.
    static func swatch(_ look: BallLook) -> (Double, Double, Double) {
        switch look {
        case .pool(let number): return swatch(number: number)
        case .plain(let c): return colour(c)
        case .spotted(let c, _): return colour(c)
        }
    }

    private static let ivoryRGB = (0.96, 0.94, 0.88)

    /// The cue ball's six marks, from the spotted cue ball the other developer modelled: oxblood (its material's
    /// linear 0.46, 0.011, 0.032 as screen colour), each 4.5 mm across the face on a 28.6 mm ball, so 0.158 rad as an
    /// angle round the ball. They sit on the six ends of three square axes turned 35 degrees about one of them (as in
    /// that model), so no mark rests dead on top or dead in front and a turn about any axis carries some of them round.
    private static let markColour = SIMD3<Float>(0.70, 0.12, 0.17)
    private static let markAngle: Float = 0.158
    private static let markAxes: [SIMD3<Float>] = {
        let a = Float(35) * .pi / 180
        let u = SIMD3<Float>(sin(a), cos(a), 0), v = SIMD3<Float>(cos(a), -sin(a), 0), w = SIMD3<Float>(0, 0, 1)
        return [u, -u, v, -v, w, -w]
    }()

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
    /// `scale` grows the numeral inside the disc (the compact pictures use a bigger, heavier one).
    private static func glyph(_ text: String, scale: CGFloat = 1) -> [UInt8] {
        let n = 256
        var pixels = [UInt8](repeating: 0, count: n * n)
        pixels.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(data: raw.baseAddress, width: n, height: n, bitsPerComponent: 8, bytesPerRow: n,
                                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return }
            // Two-digit numbers are squeezed a little so both digits fit inside the disc.
            let size: CGFloat = (text.count > 1 ? 150 : 190) * scale
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

    /// One ball's picture. The cue ball (0) is ivory with six flush oxblood marks (see markAxes). Solid balls are one colour; stripes are ivory with a coloured band round the middle. Both
    /// carry an ivory number disc at each end of the line through the band's middle, exactly as a real ball does,
    /// sized like the real one (a bit over half the ball's width). The disc is tilted toward the camera and turned a
    /// little differently for each ball, so in the resting rack most numbers face the viewer, as in a real rack.
    /// - compact: the high-contrast picture for a ball that is small on screen. Why each change: at about twenty
    ///   points across, the real proportions blur into a muddy ball. A stripe band of half-width 0.62 instead of 0.50
    ///   (as sin of the angle from the band's middle) still leaves clear ivory caps but reads as striped from any side;
    ///   a disc of 0.70 rad instead of 0.59 makes the numeral about a fifth larger; the numeral itself is drawn 8% larger
    ///   inside the disc, the ring round the disc is fully dark instead of half, and the colours are pushed about 15%
    ///   deeper (toward their own saturated hue) so yellow, orange and red separate from the ivory.
    static func ballImage(number: Int, compact: Bool = false) -> CGImage? {
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
            // The spotted cue ball. The small-on-screen picture grows each mark by the same fifth the number discs
            // grow (0.59 to 0.70 rad), so the marks still read on a ball twenty points across.
            let angle = compact ? markAngle * 1.2 : markAngle
            for i in 0..<(w * h) { put(i, ivory + (markColour - ivory) * marks(directionTable[i], angle: angle)) }
            return makeImage(raster: raster, w: w, h: h)
        }
        var base = rgb(palette[number <= 8 ? number - 1 : number - 9])
        if compact {
            // Deeper colour: pull each channel away from the colour's own grey level.
            let grey = (base.x + base.y + base.z) / 3
            base = simd_clamp(base + (base - SIMD3(repeating: grey)) * 0.15 - SIMD3(repeating: 0.03), .zero, SIMD3(repeating: 1))
        }
        let stripe = number > 8
        let text = glyph("\(number)", scale: compact ? 1.08 : 1)

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
        let discAngle: Float = compact ? 0.70 : 0.59   // disc radius as an angle round the ball (a real disc is 0.555 of the radius wide)
        let discSin = sin(discAngle)
        let bandHalf: Float = compact ? 0.62 : 0.50    // stripe half-width as sin(angle) from the band's middle
        let ringStrength: Float = compact ? 1.0 : 0.5  // how dark the thin ring round the disc is

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
                if ringMask > 0 { c = c + (ink - c) * (ringMask * ringStrength) }
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
        return makeImage(raster: raster, w: w, h: h)
    }

    /// How much of the cue ball's mark covers direction `d`: 1 inside a mark, 0 outside, with a soft edge about half a
    /// pixel of the picture wide so the round marks stay round when the picture is shrunk.
    private static func marks(_ d: SIMD3<Float>, angle: Float) -> Float {
        let edge = cos(angle)
        var cover: Float = 0
        for a in markAxes {
            let c = simd_dot(d, a)
            if c > edge - 0.02 { cover = max(cover, smooth(edge - 0.006, edge + 0.006, c)) }
        }
        return cover
    }

    /// A picture for any ball look (TableBallSet): the numbered pool picture, a plain ball, or a marked ball.
    /// - compact: the high-contrast picture for a ball that is small on screen (see ballImage(number:compact:)).
    static func ballImage(look: BallLook, compact: Bool = false) -> CGImage? {
        switch look {
        case .pool(let number):
            return ballImage(number: max(0, min(15, number)), compact: compact)
        case .plain(let c):
            let body = bodyColour(c, compact: compact)
            var raster = [UInt8](repeating: 255, count: ballW * ballH * 4)
            for i in 0..<(ballW * ballH) { write(&raster, i, body) }
            return makeImage(raster: raster, w: ballW, h: ballH)
        case .spotted(let c, let spot):
            let body = bodyColour(c, compact: compact), mark = bodyColour(spot, compact: compact)
            // The spot axis: tilted toward the camera side like the pool balls' number discs (about 40 degrees from
            // straight up), so in the resting position one spot faces the viewer. A spot at each end, so it shows
            // whichever way the ball comes to rest. Its size: 0.45 rad round the ball (about 26 degrees), a little
            // over three quarters of a number disc, large enough to read at the size a ball is on a phone; the
            // small-on-screen picture grows it by the same fifth the number discs grow.
            let tilt: Float = 40 * .pi / 180
            let axis = SIMD3<Float>(sin(tilt), cos(tilt), 0)
            let edge = Float(cos(compact ? 0.54 : 0.45))
            var raster = [UInt8](repeating: 255, count: ballW * ballH * 4)
            for i in 0..<(ballW * ballH) {
                let k = smooth(edge - 0.008, edge + 0.008, abs(simd_dot(directionTable[i], axis)))
                write(&raster, i, body + (mark - body) * k)
            }
            return makeImage(raster: raster, w: ballW, h: ballH)
        }
    }

    /// A plain colour as the ball pictures draw it; the compact picture deepens it the way the pool colours are
    /// deepened (white stays ivory: deepening a near-grey colour would only darken it).
    private static func bodyColour(_ c: BallColour, compact: Bool) -> SIMD3<Float> {
        let rgb = colour(c)
        var base = SIMD3<Float>(Float(rgb.0), Float(rgb.1), Float(rgb.2))
        if compact, c != .white {
            let grey = (base.x + base.y + base.z) / 3
            base = simd_clamp(base + (base - SIMD3(repeating: grey)) * 0.15 - SIMD3(repeating: 0.03), .zero, SIMD3(repeating: 1))
        }
        return base
    }

    private static func write(_ raster: inout [UInt8], _ i: Int, _ c: SIMD3<Float>) {
        raster[i * 4] = UInt8(max(0, min(255, c.x * 255 + 0.5)))
        raster[i * 4 + 1] = UInt8(max(0, min(255, c.y * 255 + 0.5)))
        raster[i * 4 + 2] = UInt8(max(0, min(255, c.z * 255 + 0.5)))
    }

    /// How far (metres) the Lens grid picture extends past the playing surface on every side. It fades to nothing
    /// before its edge, so the Lens reads as a lit table in a dark room, not a full-bleed background.
    static let gridMargin = 0.6

    /// Blueprint grid for the Lens: a faint ten-centimetre grid with heavier lines every half metre, a slightly
    /// lighter playing surface, a clear but quiet outline of the cushion line, a fainter outline where the rails
    /// end, and a hole at every pocket and bed hole (its capture radius). Everything fades out past the rails.
    /// Package 2 of the glow-up plan (13-Nov-2026): quieter lines so the glowing trails are the brightest thing on
    /// screen, plus the edge fade. 0.7.2: the pockets are drawn as holes (see gridImage).
    /// A pool table's picture is symmetric left-right and top-bottom; bed holes (bar billiards) are symmetric across
    /// the width only, and are placed along the length in the same direction as the plane's x.
    @MainActor
    static func gridTexture(length: Double, width: Double, pockets: [(x: Double, y: Double, radius: Double)]) -> TextureResource? {
        // Usually already drawn in the background at launch (StartupAssets); drawn here only for a different table.
        let boost = LensTextures.increaseContrast ? 2.2 : 1.0
        return StartupAssets.texture(StartupAssets.shared.gridImage(length: length, width: width, pockets: pockets, boost: boost))
    }

    /// The grid picture itself. The boost argument is the Increase Contrast multiplier (read by the caller, since the setting
    /// has to be asked on the main thread); this function touches nothing shared, so it can run on any thread.
    static func gridImage(length: Double, width: Double, pockets: [(x: Double, y: Double, radius: Double)], boost: Double) -> CGImage? {
        let ppm = 300.0   // pixels per metre
        let m = gridMargin
        let w = Int((length + 2 * m) * ppm), h = Int((width + 2 * m) * ppm)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        // Everything is drawn at full strength on a transparent ground, then multiplied by the edge fade at the end.
        // Lines are anchored to the table corner (0,0), which sits `m` metres inside the image.
        let ox = m * ppm, oy = m * ppm
        let tableRect = CGRect(x: ox, y: oy, width: length * ppm, height: width * ppm)
        // The playing surface: a slightly lighter pane so the table reads as an object, and so the holes cut into it
        // read as darker than the bed around them (at the old 0.22 the bed was barely lighter than the dark room, and a
        // black hole on it could not be seen).
        ctx.setFillColor(CGColor(red: 0.05, green: 0.19, blue: 0.28, alpha: 0.34))
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
        // Pockets and bed holes as real holes, each at its own capture radius (corner, side and bed holes differ):
        // 1. a soft light glow just outside the rim, so the hole stands off the bed even where grid lines cross it;
        // 2. an opaque near-black disc, drawn over the grid and the cushion line, so no line runs through a hole and
        //    the table's outline is visibly broken where a pocket opens;
        // 3. a clear light rim (the Lens's paper colour) on the capture circle itself, the edge a ball's centre must
        //    cross to drop.
        // Widths are in metres on the table (times ppm), so they are the same share of the hole on every table.
        let glowWidth = 0.024 * ppm, rimWidth = 0.009 * ppm
        for p in pockets {
            let c = CGPoint(x: ox + p.x * ppm, y: oy + p.y * ppm)
            let r = p.radius * ppm
            let circle = CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)
            ctx.setStrokeColor(CGColor(red: 0.92, green: 0.96, blue: 1.0, alpha: min(1, 0.16 * boost)))
            ctx.setLineWidth(glowWidth)
            ctx.strokeEllipse(in: circle)
            ctx.setFillColor(CGColor(red: 0.0, green: 0.006, blue: 0.014, alpha: 1.0))
            ctx.fillEllipse(in: circle)
            ctx.setStrokeColor(CGColor(red: 0.92, green: 0.96, blue: 1.0, alpha: min(1, 0.82 * boost)))
            ctx.setLineWidth(rimWidth)
            ctx.strokeEllipse(in: circle)
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
        return ctx.makeImage()
    }

    /// Turns a finished RGBA byte raster (opaque) into a picture. Pure CoreGraphics, so it is safe on any thread.
    private static func makeImage(raster: [UInt8], w: Int, h: Int) -> CGImage? {
        guard let provider = CGDataProvider(data: Data(raster) as CFData) else { return nil }
        return CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                       space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}
