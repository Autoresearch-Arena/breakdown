// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: Draws the table's surface pictures in code so no image file ships: a woven billiard cloth with brushed
//          nap and faint wear, walnut wood grain with pores, the dark floor that fades to nothing at its edge, the
//          pocket-wall gradient that makes a well read as deep, and the small soft blob used under the lamp pool.
//          Each function returns a TextureResource (or nil if the system refuses), built from a plain byte array
//          so the same code runs on iPhone and Mac. Called once at start-up by TableBuilder.makeTable; nothing here
//          runs per frame. Ball and Lens-grid pictures stay in BallTextures.swift.
//          Cost note: the cloth is the biggest picture. It is kept at a size that builds in a fraction of a second
//          even in a debug build, and the weave is drawn into the colour (a separate normal map would need a second
//          texture scale, which one material cannot give).
// SRP/DRY check: Pass - pictures only. Checked BallTextures (ball faces and Lens grid, different content) and
//          TableBuilder (which only places the results); no overlap.
import CoreGraphics
import Foundation
import RealityKit

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

    private static func texture(_ r: Raster) -> TextureResource? {
        guard let image = r.image() else { return nil }
        return try? TextureResource(image: image, options: .init(semantic: .color, mipmapsMode: .allocateAndGenerateAll))
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
    static func cloth(width w: Int = 768, height h: Int = 384) -> TextureResource? {
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
                r.set(x, y, (base.0 + pale * 0.10) * shade, (base.1 + pale * 0.06) * shade, (base.2 + pale * 0.05) * shade)
            }
        }
        return texture(r)
    }

    // MARK: Wood

    /// Walnut grain with the grain running along the picture's x direction. Tiles in x so one picture can serve a
    /// rail of any length. Warm dark brown with lighter streaks and tiny dark pores.
    static func wood(width w: Int = 1024, height h: Int = 256) -> TextureResource? {
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
        return texture(r)
    }

    // MARK: Floor

    /// The room floor, painted with its own light: a warm pool of lamplight under the table, a soft dark shadow of
    /// the table body in the middle of it, and a fade to fully transparent at the edge so no border shows against the
    /// dark. It is drawn as finished colour (and shown with an unlit material) so it looks the same however the scene
    /// lights change. `planeSize` is the square's side in metres; `tableHalf` is half the table's outer length and width.
    static func roomFloor(size s: Int = 512, planeSize: Float = 16, tableHalf: SIMD2<Float>) -> TextureResource? {
        var r = Raster(s, s)
        for y in 0..<s {
            for x in 0..<s {
                // World position of this pixel on the floor, in metres from the table's centre.
                let wx = ((Float(x) + 0.5) / Float(s) - 0.5) * planeSize, wz = ((Float(y) + 0.5) / Float(s) - 0.5) * planeSize
                let dist = (wx * wx + wz * wz).squareRoot()
                // Pool of light: bright near the middle, falling off smoothly.
                let pool = exp(-pow(dist / 2.6, 2))
                // Table shadow: distance outside the table's footprint, softened over about half a metre.
                let ox = max(0, abs(wx) - tableHalf.x + 0.1), oz = max(0, abs(wz) - tableHalf.y + 0.1)
                let outside = (ox * ox + oz * oz).squareRoot()
                let shadowMask = max(0, min(1, 1 - outside / 0.55))
                let shade = 1 - 0.9 * shadowMask * shadowMask * (3 - 2 * shadowMask)
                // Dark oiled boards: faint plank lines and grain, lit only where the pool reaches.
                let plank = (Int((wx + 20) / 0.19) % 2 == 0) ? 0.0 : -0.12
                let grain = (fbm(Float(x) / 60, Float(y) / 3, px: 16, py: 340, octaves: 3, seed: 41) - 0.5) * 0.35
                let tone = max(0, 1 + Float(plank) + grain)
                let v = 0.20 * pool * shade * tone
                let fall = max(0, min(1, (6.2 - dist) / 3.4))
                let alpha = fall * fall * (3 - 2 * fall)
                r.set(x, y, v * 1.00 + 0.004, v * 0.74 + 0.004, v * 0.52 + 0.005, alpha)
            }
        }
        return texture(r)
    }

    // MARK: Pocket wall

    /// Top-to-bottom gradient for the inside of a pocket: a dim brown-black lip fading to black, so the well reads
    /// as deep even though the wall is lit evenly. v = 0 is the top of the wall.
    static func pocketWall() -> TextureResource? {
        let w = 4, h = 64
        var r = Raster(w, h)
        for y in 0..<h {
            let t = Float(y) / Float(h - 1)
            let k = pow(1 - t, 1.8)
            for x in 0..<w { r.set(x, y, 0.40 * k + 0.004, 0.30 * k + 0.004, 0.24 * k + 0.004) }
        }
        return texture(r)
    }
}
