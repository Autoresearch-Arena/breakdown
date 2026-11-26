// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The pictures "BreakProbe daily" draws so a person can look at every candidate shot of the day before it goes
//          in the bank (plans/25-Nov-2026-shot-of-the-day-plan.md, stage 4 item 3: "A person looks at every shot ...
//          Throw out anything ugly, trivial or too like the day before"). One contact sheet holds up to twelve
//          candidates, four across; each tile is the table seen from above at its own proportions (x to the right, y
//          up, pocket 0 at the bottom left as the tool's words name them), with the cushions, the pockets or holes, the
//          posts and pins, every ball at its start (the cue ball white with a ring, the goal's balls ringed, the ball
//          the mark leaves the cue ball on boxed), the answer's paths (the cue ball yellow, every other ball pale), the
//          mark as a red cross, and one line of text: the candidate's id, its difficulty and its windows.
//          Written as PNG with CoreGraphics and ImageIO (a macOS dev tool; never part of the app).
// SRP/DRY check: Pass - drawing only; the shots, their timelines and their windows come from DailyAuthoring. The app
//          has its own drawing (TrickPathThumb, SwiftUI); this is a plain CoreGraphics picture for the tool's output,
//          since the package cannot import the app.
#if canImport(CoreGraphics) && canImport(ImageIO) && canImport(CoreText)
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import CoreGraphics
import CoreText
import Foundation
import ImageIO

/// One tile's content.
struct DailyTile {
    let title: String
    let detail: String
    let parameters: PoolParameters
    let layout: [Vec2]
    let timeline: Timeline
    let goalBalls: [Int]
    let leave: Int?
    let mark: Vec2?
}

enum DailyPictures {
    static let tileWidth = 560.0
    static let across = 4

    /// Draw the tiles onto sheets of twelve and write them as `<stem>-<n>.png` in `folder`. Returns the files written.
    @discardableResult
    static func writeSheets(_ tiles: [DailyTile], folder: URL, stem: String) -> [URL] {
        var out: [URL] = []
        let perSheet = across * 3
        for start in Swift.stride(from: 0, to: tiles.count, by: perSheet) {
            let chunk = Array(tiles[start..<min(start + perSheet, tiles.count)])
            let url = folder.appendingPathComponent("\(stem)-\(start / perSheet + 1).png")
            if writeSheet(chunk, to: url) { out.append(url) }
        }
        return out
    }

    private static func writeSheet(_ tiles: [DailyTile], to url: URL) -> Bool {
        guard !tiles.isEmpty else { return false }
        // Every tile the same size: the tallest table's proportions set the row height.
        let aspect = tiles.map { $0.parameters.tableWidth / $0.parameters.tableLength }.max() ?? 0.5
        let tileHeight = tileWidth * aspect + 56
        let rows = (tiles.count + across - 1) / across
        let w = Int(tileWidth) * across, h = Int(tileHeight) * rows
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        ctx.setFillColor(CGColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        for (i, tile) in tiles.enumerated() {
            let col = i % across, row = i / across
            // CoreGraphics puts y = 0 at the bottom: row 0 at the top of the sheet.
            let origin = CGPoint(x: Double(col) * tileWidth, y: Double(h) - Double(row + 1) * tileHeight)
            draw(tile, in: ctx, at: origin, height: tileHeight)
        }
        guard let image = ctx.makeImage(),
              let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { return false }
        CGImageDestinationAddImage(dest, image, nil)
        return CGImageDestinationFinalize(dest)
    }

    private static func draw(_ tile: DailyTile, in ctx: CGContext, at origin: CGPoint, height: Double) {
        let p = tile.parameters
        let margin = 22.0
        let scale = (tileWidth - 2 * margin) / p.tableLength
        let bedOrigin = CGPoint(x: origin.x + margin, y: origin.y + 44)
        func at(_ v: Vec2) -> CGPoint { CGPoint(x: bedOrigin.x + v.x * scale, y: bedOrigin.y + v.y * scale) }
        let bed = CGRect(x: bedOrigin.x, y: bedOrigin.y, width: p.tableLength * scale, height: p.tableWidth * scale)
        // Rail and bed.
        ctx.setFillColor(CGColor(red: 0.28, green: 0.17, blue: 0.09, alpha: 1))
        ctx.fill(bed.insetBy(dx: -10, dy: -10))
        ctx.setFillColor(CGColor(red: 0.05, green: 0.36, blue: 0.27, alpha: 1))
        ctx.fill(bed)
        // Pockets and holes.
        ctx.setFillColor(CGColor(gray: 0, alpha: 1))
        if p.pocketsEnabled {
            for c in p.pocketCenters { circle(ctx, at(c), 2.3 * p.ballRadius * scale, fill: true) }
        }
        for hole in p.bedHoles { circle(ctx, at(hole.center), hole.radius * scale, fill: true) }
        // Posts and pins.
        ctx.setFillColor(CGColor(gray: 0.75, alpha: 1))
        for post in p.posts { circle(ctx, at(post.center), post.radius * scale, fill: true) }
        ctx.setFillColor(CGColor(red: 1, green: 0.95, blue: 0.85, alpha: 1))
        for pin in p.pins { circle(ctx, at(pin.center), max(2.5, 0.005 * scale), fill: true) }
        // Paths: every other ball pale, then the cue ball yellow on top.
        let tl = tile.timeline
        for b in 1..<min(16, tl.ballCount) where NextShot.isOnTable(tile.layout[b]) {
            path(ctx, ball: b, tl, colour: CGColor(gray: 1, alpha: 0.45), width: 1.5, at: at)
        }
        path(ctx, ball: 0, tl, colour: CGColor(red: 1, green: 0.85, blue: 0.1, alpha: 1), width: 2.2, at: at)
        // Balls at the start.
        let r = max(3.0, p.ballRadius * scale)
        for (b, v) in tile.layout.enumerated() where NextShot.isOnTable(v) {
            ctx.setFillColor(colour(of: b))
            circle(ctx, at(v), r, fill: true)
            if b == 0 || tile.goalBalls.contains(b) {
                ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.9))
                ctx.setLineWidth(1.5)
                circle(ctx, at(v), r + 3, fill: false)
            }
            if b == tile.leave {
                ctx.setStrokeColor(CGColor(red: 0.4, green: 0.8, blue: 1, alpha: 1))
                ctx.setLineWidth(1.5)
                ctx.stroke(CGRect(x: at(v).x - r - 4, y: at(v).y - r - 4, width: 2 * r + 8, height: 2 * r + 8))
            }
            if b != 0 { text(ctx, "\(b)", at: CGPoint(x: at(v).x + r + 2, y: at(v).y + r), size: 11) }
        }
        // The mark.
        if let m = tile.mark {
            let c = at(m)
            ctx.setStrokeColor(CGColor(red: 1, green: 0.25, blue: 0.25, alpha: 1))
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: c.x - 7, y: c.y - 7)); ctx.addLine(to: CGPoint(x: c.x + 7, y: c.y + 7))
            ctx.move(to: CGPoint(x: c.x - 7, y: c.y + 7)); ctx.addLine(to: CGPoint(x: c.x + 7, y: c.y - 7))
            ctx.strokePath()
        }
        text(ctx, tile.title, at: CGPoint(x: origin.x + margin, y: origin.y + 22), size: 14)
        text(ctx, tile.detail, at: CGPoint(x: origin.x + margin, y: origin.y + 6), size: 11)
    }

    /// A ball's colour: the cue ball white, the pool palette's colours for the rest (close enough to tell them apart).
    private static func colour(of b: Int) -> CGColor {
        let palette: [(Double, Double, Double)] = [
            (0.96, 0.95, 0.90), (0.95, 0.80, 0.10), (0.10, 0.25, 0.80), (0.85, 0.12, 0.10), (0.45, 0.15, 0.60),
            (0.95, 0.45, 0.10), (0.05, 0.50, 0.20), (0.55, 0.10, 0.10), (0.05, 0.05, 0.05),
        ]
        let c = palette[b <= 8 ? b : b - 8]
        return CGColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
    }

    private static func circle(_ ctx: CGContext, _ c: CGPoint, _ r: Double, fill: Bool) {
        let rect = CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)
        if fill { ctx.fillEllipse(in: rect) } else { ctx.strokeEllipse(in: rect) }
    }

    /// A ball's recorded path, sampled every 10 ms until it stops or drops.
    private static func path(_ ctx: CGContext, ball b: Int, _ tl: Timeline, colour: CGColor, width: Double,
                             at: (Vec2) -> CGPoint) {
        let end = tl.pocketTime[b] ?? tl.duration
        var t = 0.0
        var first = true
        var last = tl.state(ball: b, at: 0).position
        while t <= end {
            let q = tl.state(ball: b, at: t).position
            if first { ctx.move(to: at(q)); first = false } else if (q - last).length > 1e-4 { ctx.addLine(to: at(q)) }
            last = q
            t += 0.01
        }
        ctx.setStrokeColor(colour)
        ctx.setLineWidth(width)
        ctx.strokePath()
    }

    private static func text(_ ctx: CGContext, _ s: String, at p: CGPoint, size: Double) {
        let font = CTFontCreateWithName("Helvetica" as CFString, size, nil)
        let attrs: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0.95, alpha: 1),
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attrs))
        ctx.textPosition = p
        CTLineDraw(line, ctx)
    }
}
#endif
