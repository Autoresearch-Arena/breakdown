// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (the other playing beds for the Surface menu: ice with skate
//          scratches and frost at the cushions, dark smoked glass, sand with grains and ripples, a red-and-gold patterned
//          carpet, and stippled rubber; each the cloth's size and drawn only when that surface is chosen).
// Edited: Claude Opus 5.5 High, 21-November-2026 (Moon regolith with soft craters and pebbles, and a cork board; ice
//          retoned from near-white to a pale blue-grey so the lamp's light no longer washes it out).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the two real cloths: new tournament-blue worsted, and worn dive-bar felt
//          with a bald break lane and faint chalk smudges; worn, never damaged).
// Edited: Claude Opus 5.5 High, 21-November-2026 (look plan packages 1, 2 and 5: very faint chalk marks on the standard
//          cloth and more on the dive-bar felt; a fine nap-and-fibre normal map for the cloth that only shows up close
//          (clothDetailNormalImage); the floor now reaches the room's walls instead of fading to nothing; soft round
//          shadow picture (softSpotImage) for the balls' contact shadows, the cue's shadow and the strips where the
//          cushions meet the bed).
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan item 56: wallSpillImage, the room's plaster with the lamp's
//          light painted on, so the far wall in the low Ride view reads as a dim wall instead of a void.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7: the room floor is a cool dark carpet, not wooden boards; the
//          Boss found the room's wood fighting the table's rails.)
// PURPOSE: Draws the table's surface pictures in code so no image file ships: a woven billiard cloth with brushed
//          nap and faint wear, walnut wood grain with pores, the dark floor that runs to the room's walls, the
//          pocket-wall gradient that makes a well read as deep, and the other playing beds of the Surface menu.
//          Each function returns a plain CGImage (or nil if the system refuses), built from a byte array and safe to make
//          on any thread: StartupAssets runs them all in parallel in the background at launch, and TableBuilder turns the
//          finished pictures into textures. The same code runs on iPhone and Mac. Nothing here
//          runs per frame. Ball and Lens-grid pictures stay in BallTextures.swift.
//          Cost note: the cloth colour is kept at a size that builds in a fraction of a second even in a debug build,
//          and the weave is drawn into the colour. The close-up detail is a separate, larger normal map
//          (clothDetailNormalImage) that StartupAssets draws on its own background task AFTER the launch pictures, so it
//          never delays the first frame; the bed simply gains it a moment later.
// SRP/DRY check: Pass - pictures only. Checked BallTextures (ball faces and Lens grid, different content) and
//          TableBuilder (which only places the results); no overlap.
import CoreGraphics
import Foundation
import simd

enum SurfaceTextures {
    // MARK: Pixel plumbing

    /// A plain RGBA byte raster, made into a CGImage at the end.
    private struct Raster {
        let w: Int, h: Int
        var bytes: [UInt8]
        init(_ w: Int, _ h: Int) { self.w = w; self.h = h; bytes = [UInt8](repeating: 0, count: w * h * 4) }
        mutating func set(_ x: Int, _ y: Int, _ r: Float, _ g: Float, _ b: Float, _ a: Float = 1) {
            let i = (y * w + x) * 4
            // Premultiplied alpha, as the bitmap format below expects.
            func q(_ v: Float) -> UInt8 { UInt8(max(0, min(255, v * a * 255 + 0.5))) }
            bytes[i] = q(r); bytes[i + 1] = q(g); bytes[i + 2] = q(b); bytes[i + 3] = UInt8(max(0, min(255, a * 255 + 0.5)))
        }
        func image() -> CGImage? {
            let data = Data(bytes) as CFData
            guard let provider = CGDataProvider(data: data) else { return nil }
            return CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                           space: CGColorSpace(name: CGColorSpace.sRGB)!,
                           bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                           provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        }
    }


    // MARK: Noise

    /// A repeatable pseudo-random number in 0...1 for an integer lattice point.
    private static func hash(_ x: Int, _ y: Int, _ seed: Int) -> Float {
        var h = UInt32(truncatingIfNeeded: x &* 374_761_393 &+ y &* 668_265_263 &+ seed &* 1_274_126_177)
        h = (h ^ (h >> 13)) &* 1_103_515_245
        h ^= h >> 16
        return Float(h & 0xFFFFFF) / Float(0x1000000)
    }

    /// Smooth value noise. `px`/`py` wrap the lattice so a texture built from it tiles without a seam.
    private static func vnoise(_ x: Float, _ y: Float, px: Int, py: Int, seed: Int) -> Float {
        let x0 = Int(floor(x)), y0 = Int(floor(y))
        let fx = x - Float(x0), fy = y - Float(y0)
        let sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy)
        func h(_ i: Int, _ j: Int) -> Float { hash(((i % px) + px) % px, ((j % py) + py) % py, seed) }
        let a = h(x0, y0), b = h(x0 + 1, y0), c = h(x0, y0 + 1), d = h(x0 + 1, y0 + 1)
        return (a + (b - a) * sx) + ((c + (d - c) * sx) - (a + (b - a) * sx)) * sy
    }

    /// Layered noise (large shapes plus finer detail), 0...1, wrapping every `px` by `py` lattice cells at the base layer.
    private static func fbm(_ x: Float, _ y: Float, px: Int, py: Int, octaves: Int, seed: Int) -> Float {
        var sum: Float = 0, amp: Float = 0.5, total: Float = 0
        var fx = x, fy = y, ppx = px, ppy = py
        for o in 0..<octaves {
            sum += amp * vnoise(fx, fy, px: ppx, py: ppy, seed: seed + o * 17)
            total += amp
            amp *= 0.5; fx *= 2; fy *= 2; ppx *= 2; ppy *= 2
        }
        return sum / total
    }

    // MARK: Cloth

    /// Billiard cloth across the whole playing surface (one picture, mapped once from corner to corner, 2:1).
    /// Woven threads, a brushed nap that runs along the table, and a few soft worn patches. The base colour is the
    /// tournament green-teal the rest of the scene is tuned for.
    static func clothImage(width w: Int = 768, height h: Int = 384) -> CGImage? {
        var r = Raster(w, h)
        let base: (Float, Float, Float) = (0.045, 0.40, 0.31)
        let pitch = 3   // pixels per thread
        for y in 0..<h {
            for x in 0..<w {
                let cx = x / pitch, cy = y / pitch
                let tx = Float(x % pitch) + 0.5, ty = Float(y % pitch) + 0.5
                // Plain weave: threads alternate over and under in a checkerboard, each one a rounded ridge.
                let over = ((cx + cy) & 1) == 0
                let ridge = over ? sin(.pi * ty / Float(pitch)) : sin(.pi * tx / Float(pitch))
                let thread = 0.5 + 0.5 * ridge
                let threadTone = hash(cx, cy, 3) - 0.5
                // Brushed nap: long streaks along x (the table's length), plus slow patches of wear.
                let nap = fbm(Float(x) / 120, Float(y) / 3.5, px: 9, py: 146, octaves: 3, seed: 11) - 0.5
                let wear = fbm(Float(x) / 260, Float(y) / 200, px: 4, py: 3, octaves: 3, seed: 29) - 0.5
                // The weave is kept faint and broken up by per-thread randomness: a strong regular grid beats against the
                // screen's pixel grid and shows as ripples (moire), which looked like a fingerprint on the cloth.
                let grain = hash(x, y, 7) - 0.5
                let shade = 1 + 0.035 * (thread - 0.6) + 0.05 * threadTone + 0.05 * grain + 0.22 * nap + 0.16 * wear
                // Worn patches shift slightly toward a paler, greyer green; fresh cloth is richer.
                let pale = max(0, wear) * 0.5
                var c: (Float, Float, Float) = ((base.0 + pale * 0.10) * shade, (base.1 + pale * 0.06) * shade, (base.2 + pale * 0.05) * shade)
                // Very faint chalk marks (look plan package 2): a cloth that has been played on carries a few blue
                // smudges where cues were chalked over it. Kept to a quarter of the dive-bar felt's strength so it
                // reads as "used", not "dirty", and only shows up close.
                c = chalkMarks(c, x, y, w, h, count: 5, strength: 0.09, seed: 211)
                r.set(x, y, c.0, c.1, c.2)
            }
        }
        return r.image()
    }

    /// Tournament cloth: new worsted cloth in the blue used at televised events. A finer, tighter weave than the standard
    /// cloth (two-pixel threads), a faint even brushing and no worn patches at all: it was stretched this week.
    static func tournamentClothImage(width w: Int = 768, height h: Int = 384) -> CGImage? {
        var r = Raster(w, h)
        let base: (Float, Float, Float) = (0.06, 0.26, 0.50)
        let pitch = 2
        for y in 0..<h {
            for x in 0..<w {
                let cx = x / pitch, cy = y / pitch
                let tx = Float(x % pitch) + 0.5, ty = Float(y % pitch) + 0.5
                let over = ((cx + cy) & 1) == 0
                let ridge = over ? sin(.pi * ty / Float(pitch)) : sin(.pi * tx / Float(pitch))
                // Kept faint for the same reason as the standard cloth: a strong regular weave shimmers on screen.
                let thread = 0.5 + 0.5 * ridge
                let brushing = fbm(Float(x) / 160, Float(y) / 3, px: 7, py: 160, octaves: 2, seed: 141) - 0.5
                let grain = hash(x, y, 143) - 0.5
                let shade = 1 + 0.025 * (thread - 0.6) + 0.03 * grain + 0.08 * brushing
                r.set(x, y, base.0 * shade, base.1 * shade, base.2 * shade)
            }
        }
        return r.image()
    }

    /// Dive-bar felt: cheap napped woollen felt that has been played on for years. A faded, greyed green with a heavy
    /// blotchy nap and pilling; a bald, paler lane down the middle where every break has gone; and faint blue chalk
    /// smudges. Nothing that would look like a bump the ball has to roll over (no burns or stains): worn, not damaged. Picture x runs along the table's length, y across it.
    static func diveBarFeltImage(width w: Int = 768, height h: Int = 384) -> CGImage? {
        var r = Raster(w, h)
        let base: (Float, Float, Float) = (0.10, 0.31, 0.22)
        let bald: (Float, Float, Float) = (0.30, 0.40, 0.31)
        let chalk: (Float, Float, Float) = (0.20, 0.38, 0.62)
        let fw = Float(w), fh = Float(h)
        // Chalk smudges (centre, radius in pixels), mostly around the head of the table where people break and lean.
        // Fourteen of them (look plan package 2: the dive bar gets more wear than the standard cloth).
        let smudges: [(x: Float, y: Float, r: Float)] = (0..<14).map { k in
            (40 + hash(k, 1, 151) * (fw * 0.5), 30 + hash(k, 2, 151) * (fh - 60), 6 + hash(k, 3, 151) * 14)
        }
        for y in 0..<h {
            for x in 0..<w {
                let fx = Float(x), fy = Float(y)
                // The nap: big soft blotches where the fibres lie different ways, plus fuzzy fine noise.
                let blotch = fbm(fx / 60, fy / 45, px: 13, py: 9, octaves: 4, seed: 153) - 0.5
                let fuzz = fbm(fx / 4, fy / 4, px: 192, py: 96, octaves: 2, seed: 155) - 0.5
                // The break lane: centred across the table, strongest between the head string and the foot spot.
                let across = (fy - fh * 0.5) / (fh * 0.16)
                let along = max(0, 1 - pow((fx - fw * 0.5) / (fw * 0.36), 4))
                let lane = exp(-across * across) * along * (0.55 + 0.3 * (fbm(fx / 30, fy / 30, px: 26, py: 13, octaves: 2, seed: 157)))
                var c = lerp3(base, bald, lane)
                for m in smudges {
                    let dx = fx - m.x, dy = fy - m.y
                    let d = (dx * dx + dy * dy).squareRoot() / m.r
                    if d < 1.5 { c = lerp3(c, chalk, max(0, 1 - d) * 0.35 * (0.6 + 0.4 * hash(x / 2, y / 2, 159))) }
                }
                // Pilling: small balls of fibre, slightly lighter.
                let pill: Float = hash(x / 2, y / 2, 161) > 0.985 ? 1.12 : 1
                let shade = (1 + 0.30 * blotch + 0.12 * fuzz + 0.06 * (hash(x, y, 163) - 0.5)) * pill
                r.set(x, y, c.0 * shade, c.1 * shade, c.2 * shade)
            }
        }
        return r.image()
    }

    // MARK: Other playing beds (chosen from the Surface menu; PlaySurfaceLook picks which one)
    //
    // Each is one picture mapped once over the playing bed, corner to corner, at the cloth's 2:1 size, so one pixel is
    // about three millimetres of table. They are drawn only when that surface is chosen and StartupAssets keeps the
    // result. The outermost few pixels tuck under the cushion noses, so nothing important is drawn right at the edge.

    /// 1 at the picture's edge, fading toward 0 about `reach` pixels in. Frost and the green of a glass edge gather
    /// where the bed meets the cushions.
    private static func edgeGlow(_ x: Int, _ y: Int, _ w: Int, _ h: Int, reach: Float) -> Float {
        let d = Float(min(min(x, w - 1 - x), min(y, h - 1 - y)))
        return exp(-d / reach)
    }

    /// Mixes one colour toward another by `t` (0 keeps `a`, 1 gives `b`).
    private static func lerp3(_ a: (Float, Float, Float), _ b: (Float, Float, Float), _ t: Float) -> (Float, Float, Float) {
        let k = max(0, min(1, t))
        return (a.0 + (b.0 - a.0) * k, a.1 + (b.1 - a.1) * k, a.2 + (b.2 - a.2) * k)
    }

    /// Blends faint blue chalk smudges into a cloth colour at pixel (x, y): `count` soft, broken blots spread over the
    /// picture (repeatable from `seed`), each mixed in at most `strength`. Used by the standard cloth; the dive-bar
    /// felt draws its own, heavier ones.
    private static func chalkMarks(_ c: (Float, Float, Float), _ x: Int, _ y: Int, _ w: Int, _ h: Int, count: Int,
                                   strength: Float, seed: Int) -> (Float, Float, Float) {
        let chalk: (Float, Float, Float) = (0.22, 0.40, 0.66)
        var out = c
        for k in 0..<count {
            let mx = 30 + hash(k, 1, seed) * Float(w - 60), my = 24 + hash(k, 2, seed) * Float(h - 48)
            let mr = 5 + hash(k, 3, seed) * 9
            let dx = Float(x) - mx, dy = Float(y) - my
            let d = (dx * dx + dy * dy).squareRoot() / mr
            guard d < 1.4 else { continue }
            // Broken up by pixel noise so a mark is a dusting, not a painted disc.
            let dust = 0.5 + 0.5 * hash(x, y, seed + 7)
            out = lerp3(out, chalk, max(0, 1 - d) * strength * dust)
        }
        return out
    }

    /// Ice: pale blue-grey with soft cloudy depth, long faint skate scratches, and frost built up along the cushions.
    /// The base is kept well below white on purpose: under the bright lamp a near-white bed (as it first was) washes
    /// out to plain white, and ice only reads as ice when its colour and the lamp's soft sheen on it can both be seen.
    static func iceImage(width w: Int = 768, height h: Int = 384) -> CGImage? {
        // Scratches go into their own brightness buffer first. Each is a stretch of a big circle (a skate blade
        // carves a shallow arc), walked half a pixel at a time, fading in and out along its length like a blade that
        // touches down and lifts. A big radius gives a nearly straight scratch.
        var scratch = [Float](repeating: 0, count: w * h)
        for k in 0..<70 {
            let sx = hash(k, 1, 51) * Float(w), sy = hash(k, 2, 51) * Float(h)
            let radius = 120 + hash(k, 3, 51) * 700
            let start = hash(k, 4, 51) * 2 * .pi
            let length = 40 + hash(k, 5, 51) * 260
            let strength = 0.10 + 0.25 * hash(k, 6, 51)
            // The circle's centre is one radius back from the start point, so angle `start` lands on (sx, sy).
            let ox = sx - radius * cos(start), oy = sy - radius * sin(start)
            let steps = Int(length * 2)
            for s in 0...steps {
                let angle = start + Float(s) * 0.5 / radius
                let x = Int(ox + radius * cos(angle)), y = Int(oy + radius * sin(angle))
                guard x >= 0, x < w, y >= 0, y < h else { continue }
                let fade = sin(.pi * Float(s) / Float(steps))
                scratch[y * w + x] = max(scratch[y * w + x], strength * fade)
            }
        }
        var r = Raster(w, h)
        let base: (Float, Float, Float) = (0.42, 0.52, 0.60)
        // Frost and scratches lighten toward this, a pale frosty blue, never all the way to white.
        let white: (Float, Float, Float) = (0.74, 0.80, 0.86)
        for y in 0..<h {
            for x in 0..<w {
                let cloud = fbm(Float(x) / 90, Float(y) / 90, px: 9, py: 5, octaves: 4, seed: 61) - 0.5
                let grain = hash(x, y, 63) - 0.5
                // Frost: thick at the cushions, broken up by fine noise so it reads as crystals, not a painted band.
                let crystals = fbm(Float(x) / 6, Float(y) / 6, px: 128, py: 64, octaves: 3, seed: 67)
                let frost = edgeGlow(x, y, w, h, reach: 14) * (0.4 + 0.9 * crystals)
                let shade = 1 + 0.10 * cloud + 0.02 * grain
                let c = lerp3((base.0 * shade, base.1 * shade, base.2 * shade), white, frost * 0.75 + scratch[y * w + x])
                r.set(x, y, c.0, c.1, c.2)
            }
        }
        return r.image()
    }

    /// Glass: dark smoked glass, nearly black, with faint smoky depth, two soft diagonal bands like a window's
    /// reflection lying in it, and the green tint glass shows at its edge. The real reflections come from the material
    /// (glossy, with a clear coat) catching the lamp picture; these bands only hint at them where the lamp is not.
    static func glassImage(width w: Int = 768, height h: Int = 384) -> CGImage? {
        var r = Raster(w, h)
        let base: (Float, Float, Float) = (0.030, 0.038, 0.042)
        for y in 0..<h {
            for x in 0..<w {
                let fx = Float(x) / Float(w), fy = Float(y) / Float(h)
                let smoke = fbm(Float(x) / 140, Float(y) / 140, px: 6, py: 3, octaves: 3, seed: 91) - 0.5
                let diag: Float = fx * 0.9 + fy * 0.45
                let wide: Float = exp(-pow((diag - 0.38) / 0.05, 2))
                let thin: Float = exp(-pow((diag - 0.52) / 0.02, 2))
                let band: Float = 0.6 * wide + 0.4 * thin
                let edge = edgeGlow(x, y, w, h, reach: 10)
                let k: Float = 1 + 0.3 * smoke
                let red: Float = base.0 * k + 0.050 * band
                let green: Float = base.1 * k + 0.055 * band + 0.06 * edge
                let blue: Float = base.2 * k + 0.060 * band + 0.045 * edge
                r.set(x, y, red, green, blue)
            }
        }
        return r.image()
    }

    /// Sand: warm tan with coarse grains, the odd dark or bright grain, slow dunes and wind ripples across the table.
    static func sandImage(width w: Int = 768, height h: Int = 384) -> CGImage? {
        var r = Raster(w, h)
        let base: (Float, Float, Float) = (0.74, 0.60, 0.40)
        for y in 0..<h {
            for x in 0..<w {
                let fx = Float(x), fy = Float(y)
                // Ripples run across the table, bent by slow noise so they wander like wind marks.
                let ripple = sin(fx * 0.11 + 9 * fbm(fx / 150, fy / 150, px: 6, py: 3, octaves: 2, seed: 75))
                let dune = fbm(fx / 200, fy / 200, px: 4, py: 2, octaves: 3, seed: 77) - 0.5
                let grain = hash(x, y, 71) - 0.5
                let speck = hash(x, y, 73)
                var shade = 1 + 0.06 * ripple + 0.18 * dune + 0.22 * grain
                if speck > 0.985 { shade *= 0.55 } else if speck < 0.012 { shade *= 1.25 }
                // Darker sand is also a little redder, as damp or iron-stained grains are.
                let red: Float = shade < 1 ? (1 - shade) * 0.04 : 0
                r.set(x, y, base.0 * shade + red, base.1 * shade, base.2 * shade - red)
            }
        }
        return r.image()
    }

    /// Carpet: a bold rug, deep red with a gold diamond lattice and navy centres in the field, and a navy border with
    /// gold stripes and a gold zigzag. Every line is drawn with a soft one-pixel edge (`line` below) so the pattern
    /// stays clean at a distance instead of crawling. The pile adds fine noise and some worn patches.
    static func carpetImage(width w: Int = 768, height h: Int = 384) -> CGImage? {
        var r = Raster(w, h)
        let red: (Float, Float, Float) = (0.42, 0.045, 0.06)
        let gold: (Float, Float, Float) = (0.78, 0.58, 0.20)
        let navy: (Float, Float, Float) = (0.05, 0.07, 0.20)
        let tile: Float = 48   // 768 and 384 are whole numbers of tiles, and the table's centre is a tile corner
        /// 1 within `half` pixels of the line, fading to 0 over the next pixel.
        func line(_ d: Float, _ half: Float) -> Float { max(0, min(1, half + 1 - abs(d))) }
        for y in 0..<h {
            for x in 0..<w {
                let e = Float(min(min(x, w - 1 - x), min(y, h - 1 - y)))   // pixels in from the nearest edge
                var c: (Float, Float, Float)
                if e < 34 {
                    // Border. `along` runs parallel to the nearest edge, so the zigzag follows it round the rug.
                    let along = min(y, h - 1 - y) < min(x, w - 1 - x) ? Float(x) : Float(y)
                    let zig = abs(along.truncatingRemainder(dividingBy: 16) - 8)   // 0...8 and back, every 16 pixels
                    c = lerp3(navy, gold, max(line(e - 8, 1.2), line(e - 30, 1.2), line(e - (15 + zig * 0.9), 0.8)))
                } else {
                    // Field: diamonds centred on each tile. m is 0 at a tile's centre and 48 at its corners.
                    let u = Float(x) + 0.5 - Float(w) / 2, v = Float(y) + 0.5 - Float(h) / 2
                    let lu = u - tile * (u / tile).rounded(), lv = v - tile * (v / tile).rounded()
                    let m = abs(lu) + abs(lv)
                    c = red
                    c = lerp3(c, navy, max(0, min(1, 7.5 - m)))          // small navy diamond in the middle
                    c = lerp3(c, gold, max(line(m - 17, 1.3), max(0, min(1, 2.5 - m)), max(0, min(1, m - 44))))
                }
                let pile = (hash(x, y, 101) - 0.5) * 0.10
                let wear = (fbm(Float(x) / 110, Float(y) / 110, px: 7, py: 4, octaves: 3, seed: 103) - 0.5) * 0.22
                let shade = 1 + pile + wear
                r.set(x, y, c.0 * shade, c.1 * shade, c.2 * shade)
            }
        }
        return r.image()
    }

    /// Rubber: dark charcoal with a fine raised stipple. Each dot is nudged off its grid point at random, because an
    /// exact grid shimmers on screen at a distance; mipmaps then blend the dots into a soft even texture far away.
    static func rubberImage(width w: Int = 768, height h: Int = 384) -> CGImage? {
        var r = Raster(w, h)
        let base: (Float, Float, Float) = (0.075, 0.075, 0.082)
        let pitch = 4
        for y in 0..<h {
            for x in 0..<w {
                let cx = x / pitch, cy = y / pitch
                let dx = Float(x) + 0.5 - (Float(cx * pitch) + 1 + 2 * hash(cx, cy, 81))
                let dy = Float(y) + 0.5 - (Float(cy * pitch) + 1 + 2 * hash(cx, cy, 82))
                let dot = exp(-(dx * dx + dy * dy) / 1.2)
                let mottle = fbm(Float(x) / 80, Float(y) / 80, px: 10, py: 5, octaves: 3, seed: 85) - 0.5
                let shade = 1 + 0.35 * dot + 0.08 * (hash(x, y, 83) - 0.5) + 0.10 * mottle
                r.set(x, y, base.0 * shade, base.1 * shade, base.2 * shade)
            }
        }
        return r.image()
    }

    /// Moon: a plain, even cool grey. No craters, pebbles or patches (they read as fake); the surface is the Moon only
    /// because of its gravity, and the bed just needs to look like flat grey felt-free dust. Fully matte; PlaySurfaceLook
    /// gives it no shine.
    static func moonImage(width w: Int = 768, height h: Int = 384) -> CGImage? {
        var r = Raster(w, h)
        for y in 0..<h {
            for x in 0..<w { r.set(x, y, 0.38, 0.40, 0.44) }
        }
        return r.image()
    }

    /// Cork board: warm tan granules of different shades packed together, with darker brown flecks between them.
    /// Each pixel takes the tone of the nearest granule centre (one jittered centre per 5-pixel cell), which gives the
    /// pressed-crumb look of cork; the fine noise on top keeps the granules from looking flat.
    static func corkImage(width w: Int = 768, height h: Int = 384) -> CGImage? {
        var r = Raster(w, h)
        let light: (Float, Float, Float) = (0.72, 0.53, 0.33)
        let dark: (Float, Float, Float) = (0.42, 0.26, 0.14)
        let cell = 5
        for y in 0..<h {
            for x in 0..<w {
                let cx = x / cell, cy = y / cell
                var nearest: Float = .greatestFiniteMagnitude, second: Float = .greatestFiniteMagnitude
                var tone: Float = 0
                // The nearest centre is always in this cell or one of its eight neighbours.
                for j in -1...1 {
                    for i in -1...1 {
                        let gx = cx + i, gy = cy + j
                        let px = Float(gx * cell) + Float(cell) * hash(gx, gy, 121)
                        let py = Float(gy * cell) + Float(cell) * hash(gx, gy, 122)
                        let dx = Float(x) + 0.5 - px, dy = Float(y) + 0.5 - py
                        let d = dx * dx + dy * dy
                        if d < nearest { second = nearest; nearest = d; tone = hash(gx, gy, 123) }
                        else if d < second { second = d }
                    }
                }
                // Near the border between two granules (the two nearest centres almost equally close) the cork
                // darkens a little: the small gaps between crumbs.
                let gap = max(0, 1 - (second.squareRoot() - nearest.squareRoot()) / 1.2)
                var c = lerp3(dark, light, 0.35 + 0.65 * tone)
                let fleck = hash(x, y, 125)
                if fleck > 0.985 { c = lerp3(c, (0.22, 0.12, 0.06), 0.7) }
                let mottle = fbm(Float(x) / 70, Float(y) / 70, px: 11, py: 5, octaves: 3, seed: 127) - 0.5
                let shade = (1 - 0.25 * gap) * (1 + 0.12 * mottle + 0.06 * (hash(x, y, 129) - 0.5))
                r.set(x, y, c.0 * shade, c.1 * shade, c.2 * shade)
            }
        }
        return r.image()
    }

    // MARK: Wood

    /// Walnut grain with the grain running along the picture's x direction. Tiles in x so one picture can serve a
    /// rail of any length. Warm dark brown with lighter streaks and tiny dark pores.
    static func woodImage(width w: Int = 1024, height h: Int = 256) -> CGImage? {
        var r = Raster(w, h)
        let dark: (Float, Float, Float) = (0.17, 0.075, 0.035)
        let light: (Float, Float, Float) = (0.46, 0.25, 0.12)
        for y in 0..<h {
            for x in 0..<w {
                let fx = Float(x), fy = Float(y)
                // Warp the growth rings with slow noise so the lines wander like real grain.
                let warp = fbm(fx / 128, fy / 40, px: 8, py: 64, octaves: 3, seed: 5)
                let rings = sin((fy * 0.55 + warp * 6) + 1.5 * fbm(fx / 512, fy / 90, px: 2, py: 64, octaves: 2, seed: 9))
                let streak = fbm(fx / 64, fy / 3, px: 16, py: 128, octaves: 3, seed: 21)
                var t = 0.5 + 0.28 * rings + 0.35 * (streak - 0.5)
                // Pores: short dark dashes along the grain.
                let pore = fbm(fx / 8, fy / 1.1, px: 128, py: 256, octaves: 1, seed: 33)
                if pore > 0.78 { t -= (pore - 0.78) * 1.6 }
                t = max(0, min(1, t))
                r.set(x, y, dark.0 + (light.0 - dark.0) * t, dark.1 + (light.1 - dark.1) * t, dark.2 + (light.2 - dark.2) * t)
            }
        }
        return r.image()
    }

    // MARK: Floor

    /// The room floor, painted with its own light: a warm pool of lamplight under the table, a soft dark shadow of
    /// the table body in the middle of it, and dark oiled boards that run all the way to the room's walls (look plan
    /// package 1: the old floor faded to nothing a few metres out, so a low camera saw it end in black). Away from the
    /// lamp the boards keep a low, even level, the light the walls and ceiling bounce back, and they darken a little
    /// right against the walls, where that bounce cannot reach. It is drawn as finished colour (and shown with an unlit
    /// material) so it looks the same however the scene lights change. `planeSize` is the square's side in metres (by
    /// default the room's floor, TableBuilder.roomFloorSide); `tableHalf` is half the table's outer length and width.
    static func roomFloorImage(size s: Int = 512, planeSize: Float? = nil, tableHalf: SIMD2<Float>) -> CGImage? {
        var r = Raster(s, s)
        let side = planeSize ?? TableBuilder.roomFloorSide(tableHalf: tableHalf)
        let room = TableBuilder.roomHalfExtent(tableHalf: tableHalf)
        for y in 0..<s {
            for x in 0..<s {
                // World position of this pixel on the floor, in metres from the table's centre.
                let wx = ((Float(x) + 0.5) / Float(s) - 0.5) * side, wz = ((Float(y) + 0.5) / Float(s) - 0.5) * side
                let dist = (wx * wx + wz * wz).squareRoot()
                // Pool of light: bright near the middle, falling off smoothly.
                let pool = exp(-pow(dist / 2.6, 2))
                // Table shadow: distance outside the table's footprint, softened over about half a metre.
                let ox = max(0, abs(wx) - tableHalf.x + 0.1), oz = max(0, abs(wz) - tableHalf.y + 0.1)
                let outside = (ox * ox + oz * oz).squareRoot()
                let shadowMask = max(0, min(1, 1 - outside / 0.55))
                let shade = 1 - 0.9 * shadowMask * shadowMask * (3 - 2 * shadowMask)
                // Dark wool carpet: a fine, even speckle and no lines at all. (Until 0.7.7 this was dark oiled boards;
                // seen from above, their brown planks ran beside the rails and read as more wood next to the table's
                // own, so the table's edge got lost. Only the table is wood now.)
                let speckle = (fbm(Float(x) / 3, Float(y) / 3, px: 170, py: 170, octaves: 2, seed: 41) - 0.5) * 0.16
                let tone = max(0, 1 + speckle)
                // Bounce light from the walls and ceiling: about a sixth of the pool's peak, so the boards stay
                // readable to the walls without competing with the lit table.
                let ambient: Float = 0.032
                // Within 0.6 m of a wall the floor darkens to a little over half (the corner where wall meets floor).
                let toWall = max(0, min(room.x - abs(wx), room.y - abs(wz)))
                let k = min(1, toWall / 0.6)
                let nearWall = 0.55 + 0.45 * k * k * (3 - 2 * k)
                let v = (0.20 * pool * shade + ambient * shade) * tone * nearWall
                // A cool slate grey, away from the rails' warm brown, so the table's edge stands clear of the floor.
                r.set(x, y, v * 0.60 + 0.004, v * 0.66 + 0.004, v * 0.72 + 0.005)
            }
        }
        return r.image()
    }

    // MARK: Walls

    /// The plaster of one wall above the waist rail, with the lamp's light falling on it, for an unlit material
    /// (TableRoom), `length` metres long; its bottom edge is the waist rail. The light: a bounce level everywhere (as the floor's: about a sixth of the lit pool), plus the lamp's
    /// spill, warm, strongest in the middle of the wall and falling off along it over the same 2.6 m as the floor's
    /// pool of light (roomFloorImage), so wall and floor meet in one pool. It also fades a little toward the ceiling
    /// (to seven tenths at the top): kept gentle on purpose, so the picture reads as plain plaster whichever way up the
    /// system lays it on the plane. Peak brightness is about a third of the lit cloth's, so the table stays the
    /// brightest thing in the room. Dark green-grey plaster, as the reflection picture's walls.
    static func wallSpillImage(length: Float, width w: Int = 256, height h: Int = 128) -> CGImage? {
        var r = Raster(w, h)
        let plaster: (Float, Float, Float) = (0.075, 0.085, 0.078)
        let lamp: (Float, Float, Float) = (1.0, 0.88, 0.72)
        for y in 0..<h {
            // Row 0 is the top of the wall: up is 1 at the ceiling, 0 at the rail.
            let up = 1 - (Float(y) + 0.5) / Float(h)
            let k = up * up * (3 - 2 * up)
            let vertical = 1 - 0.3 * k
            for x in 0..<w {
                let along = ((Float(x) + 0.5) / Float(w) - 0.5) * length
                let spill = exp(-pow(along / 2.6, 2)) * vertical
                // A faint mottle so a large flat wall does not read as a computer gradient.
                let mottle = 1 + (fbm(Float(x) / 18, Float(y) / 18, px: 15, py: 8, octaves: 3, seed: 61) - 0.5) * 0.12
                let bounce: Float = 0.45, light: Float = 1.1 * spill
                r.set(x, y, plaster.0 * (bounce + light * lamp.0) * mottle,
                      plaster.1 * (bounce + light * lamp.1) * mottle,
                      plaster.2 * (bounce + light * lamp.2) * mottle)
            }
        }
        return r.image()
    }

    // MARK: Close-up cloth detail

    /// A normal map of the cloth's fine surface for the playing bed and the cushions (look plan package 2). The colour
    /// picture is about three millimetres a pixel, which is a smooth green blur when the Ride camera drops to the
    /// cloth; this is about 1.2 mm a pixel and carries what a close look at real cloth shows: a fuzz of loose fibre,
    /// the nap brushed along the table's length, and a speckle of single fibres catching the lamp. From the normal
    /// overhead view mipmapping averages it back to a flat surface, so the cloth looks exactly as before there.
    /// Encoded the usual way (x and y of the tilt in red and green around one half, z in blue). Mapped once over the
    /// bed corner to corner, like the colour picture, so no second texture scale is needed.
    static func clothDetailNormalImage(width w: Int = 2048, height h: Int = 1024) -> CGImage? {
        // 1. A height field: fuzz + nap streaks (long along x) + single-fibre speckle.
        var height = [Float](repeating: 0, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                let fx = Float(x), fy = Float(y)
                let fuzz = vnoise(fx / 2.5, fy / 2.5, px: 820, py: 410, seed: 301)
                let nap = vnoise(fx / 22, fy / 1.6, px: 94, py: 640, seed: 303)
                let fibre = hash(x, y, 305)
                height[y * w + x] = 0.45 * fuzz + 0.40 * nap + 0.15 * fibre
            }
        }
        // 2. Normals from the slope. `bump` sets how far the surface tilts; kept low so the cloth gains texture up
        //    close without looking like a rough carpet.
        var r = Raster(w, h)
        let bump: Float = 1.6
        for y in 0..<h {
            for x in 0..<w {
                let xl = height[y * w + max(0, x - 1)], xr = height[y * w + min(w - 1, x + 1)]
                let yu = height[max(0, y - 1) * w + x], yd = height[min(h - 1, y + 1) * w + x]
                var n = SIMD3<Float>(-(xr - xl) * bump, -(yd - yu) * bump, 1)
                n = simd_normalize(n)
                r.set(x, y, n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5)
            }
        }
        return r.image()
    }

    // MARK: Soft shadows

    /// A soft round shadow: black, fully dark in the middle and fading to nothing at the picture's edge, with a
    /// squared fall-off so it has no visible rim. Shown with an unlit see-through material under each ball (its contact
    /// shadow), stretched long under the cue while aiming, and sampled from centre to edge for the soft strips along
    /// the cushions (where the cushion meets the bed, and where its top folds against the rail).
    static func softSpotImage(size n: Int = 64) -> CGImage? {
        var r = Raster(n, n)
        for y in 0..<n {
            for x in 0..<n {
                let dx = (Float(x) + 0.5) / Float(n) * 2 - 1, dy = (Float(y) + 0.5) / Float(n) * 2 - 1
                let d = min(1, (dx * dx + dy * dy).squareRoot())
                let a = (1 - d) * (1 - d)
                r.set(x, y, 0, 0, 0, a)
            }
        }
        return r.image()
    }

    // MARK: Pocket wall

    /// Top-to-bottom gradient for the inside of a pocket: a dim brown-black lip fading to black, so the well reads
    /// as deep even though the wall is lit evenly. v = 0 is the top of the wall.
    static func pocketWallImage() -> CGImage? {
        let w = 4, h = 64
        var r = Raster(w, h)
        for y in 0..<h {
            let t = Float(y) / Float(h - 1)
            let k = pow(1 - t, 1.8)
            for x in 0..<w { r.set(x, y, 0.40 * k + 0.004, 0.30 * k + 0.004, 0.24 * k + 0.004) }
        }
        return r.image()
    }
}
