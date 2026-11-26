// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: Draws one Game Center picture per achievement (0.7.10, Shot of the day plan stage 3 item 2,
//          plans/25-Nov-2026-shot-of-the-day-plan.md): the achievement's own symbol (the one the game's achievements
//          list shows, from App/Achievements/Achievement.swift) in white, on the game's dark ground with a soft felt-green
//          glow and a thin cyan ring, the colours store/screenshots/compose.swift frames the store screenshots with.
//          Output is an opaque sRGB PNG of 1024 by 1024 pixels, the size App Store Connect takes for an achievement
//          image, named <achievement id>.png. No words are drawn, so one picture serves all twelve languages.
//          Input is the small list scripts/gamecenter-setup.py writes: a JSON array of {"id": ..., "symbol": ...}.
//          A symbol this Mac's system does not have is drawn as "star.circle" with a warning, never left blank.
//          Usage: swift store/gamecenter/achievement-art.swift <list.json> <output folder>
//          (scripts/gamecenter-setup.py runs it with --draw or --apply; the output folder is on the Team 4TB drive.)
// SRP/DRY check: Pass - drawing only. The colours are compose.swift's, copied as numbers (a script run on its own
//          cannot import another script); the list of achievements and their symbols comes from the setup script,
//          which reads the game's own catalogue.

import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Settings

let side = 1024
// compose.swift's colours: the dark ground's top and bottom, the felt glow and the cyan accent.
let bgTop = NSColor(srgbRed: 0.050, green: 0.066, blue: 0.078, alpha: 1)
let bgBottom = NSColor(srgbRed: 0.016, green: 0.024, blue: 0.031, alpha: 1)
let feltGlow = NSColor(srgbRed: 0.14, green: 0.46, blue: 0.30, alpha: 1)
let accentCyan = NSColor(srgbRed: 0x4A / 255.0, green: 0xDC / 255.0, blue: 0xF2 / 255.0, alpha: 1)
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

struct Item: Decodable {
    let id: String
    let symbol: String
}

// MARK: - Drawing

/// The symbol as a white image, or nil when the system has no symbol of that name.
func symbolImage(_ name: String) -> NSImage? {
    guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return nil }
    let config = NSImage.SymbolConfiguration(pointSize: 360, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    return base.withSymbolConfiguration(config)
}

/// One picture. CoreGraphics origin is bottom-left; everything here is centred, so it does not matter.
func render(symbol: NSImage) -> CGImage? {
    let s = CGFloat(side)
    guard let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
    ctx.interpolationQuality = .high

    // Ground: the deep vertical gradient.
    let ground = CGGradient(colorsSpace: sRGB, colors: [bgTop.cgColor, bgBottom.cgColor] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(ground, start: CGPoint(x: 0, y: s), end: .zero, options: [])

    // The felt glow behind the symbol, fading out before the edges.
    let centre = CGPoint(x: s / 2, y: s / 2)
    let glow = CGGradient(colorsSpace: sRGB, colors: [feltGlow.withAlphaComponent(0.55).cgColor,
                                                      feltGlow.withAlphaComponent(0).cgColor] as CFArray,
                          locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: centre, startRadius: 0, endCenter: centre, endRadius: s * 0.46, options: [])

    // The thin cyan ring.
    let ringRadius = s * 0.37
    ctx.setStrokeColor(accentCyan.cgColor)
    ctx.setLineWidth(s * 0.014)
    ctx.strokeEllipse(in: CGRect(x: centre.x - ringRadius, y: centre.y - ringRadius, width: ringRadius * 2,
                                 height: ringRadius * 2))

    // The symbol, fitted inside a square box well within the ring, keeping its own proportions.
    let box = s * 0.42
    let size = symbol.size
    let scale = min(box / max(size.width, 1), box / max(size.height, 1))
    let w = size.width * scale, h = size.height * scale
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    symbol.draw(in: NSRect(x: centre.x - w / 2, y: centre.y - h / 2, width: w, height: h))
    NSGraphicsContext.restoreGraphicsState()

    return ctx.makeImage()
}

func writePNG(_ image: CGImage, to url: URL) -> Bool {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        return false
    }
    CGImageDestinationAddImage(dest, image, nil)
    return CGImageDestinationFinalize(dest)
}

// MARK: - Main

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write(Data("usage: swift achievement-art.swift <list.json> <output folder>\n".utf8))
    exit(2)
}
let listURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2], isDirectory: true)
let items: [Item]
do {
    items = try JSONDecoder().decode([Item].self, from: Data(contentsOf: listURL))
    try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)
} catch {
    FileHandle.standardError.write(Data("could not read the list or make the folder: \(error)\n".utf8))
    exit(1)
}

var failed = 0
for item in items {
    var image = symbolImage(item.symbol)
    if image == nil {
        FileHandle.standardError.write(Data("warning: no symbol \(item.symbol) for \(item.id); drawn as star.circle\n".utf8))
        image = symbolImage("star.circle")
    }
    guard let symbol = image, let picture = render(symbol: symbol),
          writePNG(picture, to: outURL.appendingPathComponent("\(item.id).png")) else {
        FileHandle.standardError.write(Data("error: \(item.id) could not be drawn\n".utf8))
        failed += 1
        continue
    }
    print("drew \(item.id).png")
}
exit(failed == 0 ? 0 : 1)
