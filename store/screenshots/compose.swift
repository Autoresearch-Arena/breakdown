// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 front door, plans/25-Nov-2026-front-door-and-table-view-plan.md
//          Stage 5: the frames lead with the unusual: the three other tables (bar billiards among them) and the jump
//          come first, then the rest in their old order; the frame names are unchanged, so the raw files, the caption
//          keys and SCENES= still match. Wave 2 adds the Lens on bumper pool, the strike panel and the daily result in
//          front of them. The iPad's table crop follows the upright iPad's new split: the notebook band under the
//          table now takes everything the table does not need (App/NotebookGeometry.swift belowPanel).)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 wiring: frames 11 to 13 (the Lens on bumper pool, the strike
//          panel, the Shot of the day result) at the front of the frame list, with their captions first in every
//          captions/<language>.json.)
// PURPOSE: Frame Breakdown's raw App Store screenshots for one device in any number of languages. Each frame gets a
//          near-black gradient background with a soft felt-green glow, a short cyan accent bar, a white heavy rounded
//          headline (from captions/<lang>.json, at most two lines, shrunk to fit, the same size on every frame of a
//          language) and the screenshot below it with rounded corners and a soft shadow. Frames 07 and 08 put two or
//          three shots side by side (on iPad they are cropped to the table and laid out large; see tableCrop and
//          featureLayout). Output is an opaque sRGB PNG at the exact App Store Connect size for the device.
//          Raw shots come from scripts/store-shots.sh. Text is drawn with AppKit, so Arabic is shaped right-to-left and
//          Japanese, Korean, Chinese and Cyrillic fall back to the right system fonts.
//          Usage: swift store/screenshots/compose.swift <device> <language> [<language>...]
//                   [--raw-root <dir>] [--out-root <dir>] [--captions <file.json or folder>]
//          Devices: iphone-6.9 (1320x2868), ipad-13 (2064x2752), mac (2880x1800), duo-outer (1398x2034, the iPhone Duo's
//          closed outer screen) and duo-inner (2853x2007, its open inner screen, landscape).
//          Defaults: raw and final folders under /Volumes/Team 4TB/breakdown-build/store-shots/, captions next to this
//          script. A --captions file is used for every language given; a folder is read as <folder>/<lang>.json.
// Edited: Claude Opus 5.5 High, 21-November-2026 (iPad frames 07 and 08: each raw shot cropped to its table area,
//          without the side column, status bar and bottom buttons; 07 as two large staggered tiles, 08 as one large
//          five-pin tile beside two stacked ones, mirrored for Arabic.)
// Edited: Claude Sonnet 5.5 Medium, 21-November-2026 (iPhone Duo sets: duo-inner is landscape, one shot per frame, and
//          frames 07 and 08 show each table cropped to its own panel, side by side; duo-outer is the small closed
//          screen, whose frames 07 and 08 show the tables cropped and stacked in a gentle zigzag, since three whole
//          portrait screens side by side would be tiny. Crops are per device now (tableCrops).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, bug plan item 40: the ten frames are the new scene list of
//          scripts/store-shots.sh, led by the Lens, with a match, a lesson, a ruling, the stroke drill, the three other
//          tables keeping score and a Ride view; the two plain list screens are gone. The iPad table crop follows the
//          notebook layout an upright iPad now has, the panel under the table instead of a column beside it.)
// SRP/DRY check: Pass - framing only. Capturing is scripts/store-shots.sh and store-shot.sh; the words are in
//          captions/<lang>.json. One row-layout routine serves single shots and the side-by-side composites on every
//          device.

import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

// MARK: - Settings

struct Device {
    let width: Int
    let height: Int
    let cornerFraction: CGFloat   // corner radius as a fraction of each shot's drawn width
    let sideMargin: CGFloat       // fraction of canvas width kept clear on each side of the headline
    let headlineTop: CGFloat      // fraction of canvas height above the accent bar
    let headlineZone: CGFloat     // fraction of canvas height reserved for the accent bar plus a two-line headline
    let maxFontSize: CGFloat      // headline size in pixels before shrinking
    let shotBottom: CGFloat       // fraction of canvas height kept clear under the shots
    let shotSide: CGFloat         // fraction of canvas width kept clear beside the shots
}

let devices: [String: Device] = [
    "iphone-6.9": Device(width: 1320, height: 2868, cornerFraction: 0.06, sideMargin: 0.075, headlineTop: 0.050,
                         headlineZone: 0.165, maxFontSize: 112, shotBottom: 0.035, shotSide: 0.06),
    "ipad-13":    Device(width: 2064, height: 2752, cornerFraction: 0.035, sideMargin: 0.10, headlineTop: 0.050,
                         headlineZone: 0.150, maxFontSize: 130, shotBottom: 0.040, shotSide: 0.07),
    "mac":        Device(width: 2880, height: 1800, cornerFraction: 0.015, sideMargin: 0.12, headlineTop: 0.055,
                         headlineZone: 0.200, maxFontSize: 116, shotBottom: 0.055, shotSide: 0.07),
    // iPhone Duo, closed: the outer screen, portrait.
    "duo-outer":  Device(width: 1398, height: 2034, cornerFraction: 0.06, sideMargin: 0.075, headlineTop: 0.050,
                         headlineZone: 0.165, maxFontSize: 118, shotBottom: 0.035, shotSide: 0.06),
    // iPhone Duo, open: the inner screen, landscape (the table on one side, everything else on the other).
    "duo-inner":  Device(width: 2853, height: 2007, cornerFraction: 0.02, sideMargin: 0.12, headlineTop: 0.055,
                         headlineZone: 0.200, maxFontSize: 115, shotBottom: 0.055, shotSide: 0.07),
]

// Frame name -> raw scene files shown in it (left to right). The frame name is also the caption key.
// 0.7.10: in the store page's order (the same order as the keys of captions/<language>.json).
let frames: [(name: String, scenes: [String])] = [
    // 0.7.10 wiring: the three scenes that lead the page (scripts/store-shots.sh, 11 to 13).
    ("11-lens-bumper", ["11-lens-bumper"]),
    ("12-strike", ["12-strike"]),
    ("13-daily", ["13-daily"]),
    ("08-tables", ["08a-bumper", "08b-fivepin", "08c-bar"]),
    ("10-jump", ["10-jump"]),
    ("01-lens", ["01-lens"]),
    ("02-match", ["02-match"]),
    ("03-lesson", ["03-lesson"]),
    ("04-real-table", ["04-real-table"]),
    ("05-ruling", ["05-ruling"]),
    ("06-drill", ["06-drill"]),
    ("07-surfaces", ["07a-ice", "07b-moon"]),
    ("09-ride", ["09-ride"]),
]

// iPad composites show only the table area of each raw shot. The iPad set is shot upright, and since 0.6.6 an upright
// iPad shows the notebook layout: the table across the top and the notebook panel as a band under it
// (App/NotebookGeometry.swift). Since 0.7.10 that band takes every point the table lying across the width does not need
// (belowPanel): on the 13-inch iPad (1032 x 1376 points upright) the table needs (1032 - 16) x 0.5709 x 0.82 + 42 = 518
// points, so the table's space is the top 518 points: 518 / 1376 = 0.376 of the height (it was 856 points, 0.622,
// before). The table spans the whole width, so nothing is cut at the sides (and Arabic needs no mirroring). The top is
// the status bar only, 24 points (0.017): the table's half has no title row, and since 0.7.10 its rails reach to just
// under the status bar, so the old 0.060 would cut them. Re-measure both on the first 0.7.10 iPad set.
let tableCrop = (width: CGFloat(1.0), top: CGFloat(0.017), bottom: CGFloat(0.376))

// Per-device crops for the composite frames (07 and 08). Each is fractions of the raw shot: width (kept from the
// leading side, the trailing side for Arabic), top and bottom.
//  - ipad-13: see tableCrop above (the notebook band under the table is cut away).
//  - duo-inner: the table panel left of the fold (the fold is at 48% of the width; the panel stops just short of its
//    hairline), down to just above the home indicator. Nothing is drawn over the table on the Duo, so no buttons to cut.
//  - duo-outer: the closed screen without its status column (the right 17%), from the top of the table down to above the
//    aiming panel, which covers the lower edge of the bigger tables (frameCrops has the one exception).
let tableCrops: [String: (width: CGFloat, top: CGFloat, bottom: CGFloat)] = [
    "ipad-13": tableCrop,
    "duo-inner": (width: 0.476, top: 0.01, bottom: 0.955),
    "duo-outer": (width: 0.83, top: 0.0, bottom: 0.64),
]
// A frame's own crop where the device's default does not suit it: on the closed Duo the surface shots have their trick-shot
// card right under the table, which would show in a tile that went down as far as the bumper-pool and bar tables.
let frameCrops: [String: (width: CGFloat, top: CGFloat, bottom: CGFloat)] = [
    "duo-outer/07a-ice": (width: 0.83, top: 0.0, bottom: 0.435),
    "duo-outer/07b-moon": (width: 0.83, top: 0.0, bottom: 0.415),
]
// Devices whose composites stack vertically instead of standing side by side.
let stackedDevices: Set<String> = ["duo-outer"]

// iPad frame 08 shows its featured shot (five-pin, whose small pins need the room) large, the other two stacked beside it.
let featuredScene = ["08-tables": "08b-fivepin"]

// The app's own colours: near-black table room, felt green, accent cyan.
let accentCyan = NSColor(srgbRed: 0x4A / 255.0, green: 0xDC / 255.0, blue: 0xF2 / 255.0, alpha: 1)
let bgTop = NSColor(srgbRed: 0.050, green: 0.066, blue: 0.078, alpha: 1)
let bgBottom = NSColor(srgbRed: 0.016, green: 0.024, blue: 0.031, alpha: 1)
let feltGlow = NSColor(srgbRed: 0.14, green: 0.46, blue: 0.30, alpha: 1)
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

// MARK: - Arguments

func fail(_ message: String) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(1)
}

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
var rawRoot = "/Volumes/Team 4TB/breakdown-build/store-shots/raw"
var outRoot = "/Volumes/Team 4TB/breakdown-build/store-shots/final"
var captionsPath = scriptDir.appendingPathComponent("captions").path
var positional: [String] = []
do {
    var args = Array(CommandLine.arguments.dropFirst())
    while !args.isEmpty {
        let a = args.removeFirst()
        switch a {
        case "--raw-root", "--out-root", "--captions":
            guard !args.isEmpty else { fail("\(a) needs a value") }
            let v = args.removeFirst()
            if a == "--raw-root" { rawRoot = v } else if a == "--out-root" { outRoot = v } else { captionsPath = v }
        default: positional.append(a)
        }
    }
}
guard positional.count >= 2, let device = devices[positional[0]] else {
    fail("Usage: swift compose.swift <iphone-6.9|ipad-13|mac|duo-outer|duo-inner> <language> [<language>...] [--raw-root dir] [--out-root dir] [--captions file|dir]")
}
let deviceName = positional[0]
let languages = Array(positional.dropFirst())
// Big files live on the Team 4TB drive only; never fall back to the internal drive.
for root in [rawRoot, outRoot] where root.hasPrefix("/Volumes/Team 4TB") {
    guard FileManager.default.fileExists(atPath: "/Volumes/Team 4TB") else { fail("The Team 4TB drive is not mounted.") }
}

// Fonts resolve reliably in a script only once the shared application exists.
_ = NSApplication.shared

// MARK: - Captions

func loadCaptions(_ lang: String) -> [String: String] {
    var isDir: ObjCBool = false
    FileManager.default.fileExists(atPath: captionsPath, isDirectory: &isDir)
    let path = isDir.boolValue ? (captionsPath as NSString).appendingPathComponent("\(lang).json") : captionsPath
    guard let data = FileManager.default.contents(atPath: path),
          let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
        fail("No readable captions at \(path)")
    }
    return dict
}

// MARK: - Headline text

func headlineFont(_ size: CGFloat) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: .heavy)
    if let rounded = base.fontDescriptor.withDesign(.rounded), let f = NSFont(descriptor: rounded, size: size) { return f }
    return base
}

func headlineString(_ text: String, size: CGFloat, rtl: Bool) -> NSAttributedString {
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineBreakMode = .byWordWrapping
    para.lineHeightMultiple = 0.98
    para.baseWritingDirection = rtl ? .rightToLeft : .leftToRight
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.55)
    shadow.shadowBlurRadius = size * 0.18
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.04)
    // A non-breaking hyphen keeps words like "five-pin" whole on one line.
    var text = text.replacingOccurrences(of: "-", with: "\u{2011}")
    // Japanese may break between any two characters, which splits a katakana word or the particle "など". A word joiner
    // between their characters stops that.
    if let runs = try? NSRegularExpression(pattern: "[\\u30A0-\\u30FF]{2,}|など") {
        let ns = text as NSString
        var out = ""
        var last = 0
        for m in runs.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            out += ns.substring(with: NSRange(location: last, length: m.range.location - last))
            out += ns.substring(with: m.range).map(String.init).joined(separator: "\u{2060}")
            last = m.range.location + m.range.length
        }
        out += ns.substring(from: last)
        text = out
    }
    return NSAttributedString(string: text, attributes: [
        .font: headlineFont(size), .foregroundColor: NSColor.white, .paragraphStyle: para,
        .kern: size * -0.005, .shadow: shadow,
    ])
}

/// Lines and height of the text laid out at a given width (CoreText, the same engine AppKit draws with).
func layout(_ s: NSAttributedString, width: CGFloat) -> (lines: Int, height: CGFloat, widest: CGFloat) {
    let setter = CTFramesetterCreateWithAttributedString(s)
    let path = CGPath(rect: CGRect(x: 0, y: 0, width: width, height: 100_000), transform: nil)
    let frame = CTFramesetterCreateFrame(setter, CFRange(location: 0, length: 0), path, nil)
    let lines = CTFrameGetLines(frame) as! [CTLine]
    let widest = lines.map { CGFloat(CTLineGetTypographicBounds($0, nil, nil, nil) - CTLineGetTrailingWhitespaceWidth($0)) }.max() ?? 0
    let size = CTFramesetterSuggestFrameSizeWithConstraints(setter, CFRange(location: 0, length: 0), nil,
                                                            CGSize(width: width, height: 100_000), nil)
    return (lines.count, ceil(size.height), widest)
}

/// True if any single word is wider than the line, which would force a break inside the word. Chinese and Japanese
/// are written without spaces and may break between any two characters, so runs containing them are not checked.
func wordTooWide(_ text: String, size: CGFloat, rtl: Bool, width: CGFloat) -> Bool {
    func breaksAnywhere(_ word: Substring) -> Bool {
        word.unicodeScalars.contains { (0x3040...0x30FF).contains($0.value) || (0x3400...0x9FFF).contains($0.value) }
    }
    return text.split(whereSeparator: { $0 == " " }).filter { !breaksAnywhere($0) }.contains { word in
        layout(headlineString(String(word), size: size, rtl: rtl), width: 100_000).widest > width
    }
}

/// Largest size (down from the device maximum) at which the headline fits in two lines without splitting a word.
func fittingSize(_ text: String, rtl: Bool, width: CGFloat, maxSize: CGFloat) -> CGFloat {
    var size = maxSize
    while size > 24 {
        if layout(headlineString(text, size: size, rtl: rtl), width: width).lines <= 2,
           !wordTooWide(text, size: size, rtl: rtl, width: width) { return size }
        size -= 2
    }
    print("warning: headline needs more than two lines even at the smallest size: \(text)")
    return size
}

/// The narrowest width that keeps the same line count, so two-line headlines are balanced instead of leaving one
/// short word alone on the second line.
func balancedWidth(_ s: NSAttributedString, maxWidth: CGFloat) -> CGFloat {
    let target = layout(s, width: maxWidth).lines
    guard target > 1 else { return maxWidth }
    var lo = maxWidth * 0.4, hi = maxWidth
    for _ in 0..<16 {
        let mid = (lo + hi) / 2
        if layout(s, width: mid).lines <= target { hi = mid } else { lo = mid }
    }
    return min(maxWidth, hi + 2)
}

// MARK: - Images

func loadImage(_ path: String) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

/// The table area of a raw shot (see tableCrops). Right-to-left layouts have the card column on the left.
func cropToTable(_ img: CGImage, rtl: Bool, crop: (width: CGFloat, top: CGFloat, bottom: CGFloat)) -> CGImage? {
    let w = CGFloat(img.width), h = CGFloat(img.height)
    let cw = (w * crop.width).rounded()
    // CGImage cropping uses a top-left origin.
    let r = CGRect(x: rtl ? w - cw : 0, y: (h * crop.top).rounded(), width: cw,
                   height: (h * (crop.bottom - crop.top)).rounded())
    return img.cropping(to: r)
}

func writePNG(_ image: CGImage, to path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return false }
    CGImageDestinationAddImage(dest, image, nil)
    return CGImageDestinationFinalize(dest)
}

// MARK: - Drawing

/// Renders one frame. The canvas is a CoreGraphics bitmap with no alpha channel (sRGB, alpha skipped), so the PNG
/// written from it is opaque. AppKit draws the text into the same bitmap through an NSGraphicsContext.
/// Coordinates: CoreGraphics origin is bottom-left; `top(y)` converts a distance from the top edge.
func render(shots: [CGImage], headline: String, fontSize: CGFloat, rtl: Bool, featured: Int? = nil, stacked: Bool = false) -> CGImage? {
    let W = CGFloat(device.width), H = CGFloat(device.height)
    guard let ctx = CGContext(data: nil, width: device.width, height: device.height, bitsPerComponent: 8, bytesPerRow: 0,
                              space: sRGB, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
    ctx.interpolationQuality = .high
    func top(_ y: CGFloat) -> CGFloat { H - y }

    // Background: deep vertical gradient.
    let grad = CGGradient(colorsSpace: sRGB, colors: [bgTop.cgColor, bgBottom.cgColor] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])

    // Shot row: every shot the same height, small gaps, scaled to fit the space under the headline, centred there.
    let zoneTop = H * (device.headlineTop + device.headlineZone)
    let zoneBottom = H * (1 - device.shotBottom)
    // Composites use narrower side margins and gaps so the shots stay as large as possible.
    let side = shots.count > 1 ? W * 0.035 : W * device.shotSide
    let availW = W - 2 * side, availH = zoneBottom - zoneTop
    let aspects = shots.map { CGFloat($0.width) / CGFloat($0.height) }
    let gap = shots.count > 1 ? W * 0.02 : 0
    var rowH = min(availH, (availW - gap * CGFloat(shots.count - 1)) / aspects.reduce(0, +))
    // When the row is width-bound (several tall shots on a portrait canvas) there is spare height; a gentle stagger
    // (alternate shots dropped) uses some of it so the frame does not look empty. Every shot stays fully visible.
    // Wide shots get a smaller drop, since a big step on short landscape shots reads as misalignment.
    let meanAspect = aspects.reduce(0, +) / CGFloat(aspects.count)
    let stagger = shots.count > 1 ? min((availH - rowH) * 0.6, rowH * 0.3 * min(1, 1 / meanAspect)) : 0
    rowH = min(rowH, availH - stagger)
    let rowW = aspects.reduce(0) { $0 + $1 * rowH } + gap * CGFloat(shots.count - 1)
    // Leftover height is split nearer the headline than the bottom, so the shots read as belonging to it.
    let rowTop = zoneTop + (availH - rowH - stagger) * (H > W ? 0.25 : 0.45)
    var x = (W - rowW) / 2
    var rects: [CGRect] = []
    for (i, a) in aspects.enumerated() {
        let drop = i % 2 == 1 ? stagger : 0
        rects.append(CGRect(x: x, y: top(rowTop + drop + rowH), width: a * rowH, height: rowH))
        x += a * rowH + gap
    }
    var glowTop = rowTop, glowW = rowW, glowH = rowH + stagger

    // Feature layout (iPad frame 08): the featured shot large on the leading side, the other two stacked beside it,
    // their column exactly as tall as the large shot. Solved for the largest size that fits both width and height.
    if let f = featured, shots.count == 3 {
        let others = aspects.indices.filter { $0 != f }
        let aBig = aspects[f], a1 = aspects[others[0]], a2 = aspects[others[1]]
        // Stacked column: widths equal (cw), heights cw/a1 and cw/a2 plus a gap; the big shot's height matches it.
        // Width bound: aBig * (cw/a1 + cw/a2 + gap) + gap + cw = availW.
        let k = aBig * (1 / a1 + 1 / a2) + 1
        var cw = (availW - gap - aBig * gap) / k
        // Height bound: cw/a1 + cw/a2 + gap = availH.
        cw = min(cw, (availH - gap) / (1 / a1 + 1 / a2))
        let bigH = cw / a1 + cw / a2 + gap, bigW = aBig * bigH
        let totalW = bigW + gap + cw
        let blockTop = zoneTop + (availH - bigH) * 0.25
        let left = (W - totalW) / 2
        // Leading side is the left, or the right for Arabic.
        let bigX = rtl ? left + cw + gap : left
        let colX = rtl ? left : left + bigW + gap
        rects = Array(repeating: .zero, count: 3)
        rects[f] = CGRect(x: bigX, y: top(blockTop + bigH), width: bigW, height: bigH)
        rects[others[0]] = CGRect(x: colX, y: top(blockTop + cw / a1), width: cw, height: cw / a1)
        rects[others[1]] = CGRect(x: colX, y: top(blockTop + bigH), width: cw, height: cw / a2)
        glowTop = blockTop; glowW = totalW; glowH = bigH
    }

    // Stacked layout (Duo outer screen, frames 07 and 08): the tiles one above the other, each as wide as the height
    // allows, alternately shifted left and right (the other way round for Arabic) so the frame uses its width.
    if stacked, shots.count == 3 {
        // Three tiles: one centred on top, two side by side beneath it, all one width. Much larger than three in a column.
        let g = W * 0.02
        let w = min((availW - g) / 2, (availH - g) / (aspects[0] > 0 ? (1 / aspects[0] + 1 / min(aspects[1], aspects[2])) : 2))
        let h0 = w / aspects[0], h1 = w / aspects[1], h2 = w / aspects[2]
        let blockH = h0 + g + max(h1, h2)
        let blockTop = zoneTop + (availH - blockH) * 0.25
        let x0 = (W - w) / 2
        let leftX = (W - 2 * w - g) / 2
        // Reading order: the second tile on the leading side (the right for Arabic).
        let (xa, xb) = rtl ? (leftX + w + g, leftX) : (leftX, leftX + w + g)
        rects = [CGRect(x: x0, y: top(blockTop + h0), width: w, height: h0),
                 CGRect(x: xa, y: top(blockTop + h0 + g + h1), width: w, height: h1),
                 CGRect(x: xb, y: top(blockTop + h0 + g + h2), width: w, height: h2)]
        glowTop = blockTop; glowW = 2 * w + g; glowH = blockH
    } else if stacked, shots.count > 1 {
        let vGap = H * 0.014
        let invSum = aspects.reduce(0) { $0 + 1 / $1 }
        let w = min(availW * 0.74, (availH - vGap * CGFloat(shots.count - 1)) / invSum)
        let totalH = invSum * w + vGap * CGFloat(shots.count - 1)
        let blockTop = zoneTop + (availH - totalH) * 0.25
        let shift = (availW - w) * 0.34
        var y = blockTop
        rects = []
        for (i, a) in aspects.enumerated() {
            let h = w / a
            let dir: CGFloat = (i % 2 == 0 ? -1 : 1) * (rtl ? -1 : 1)
            rects.append(CGRect(x: (W - w) / 2 + dir * shift, y: top(y + h), width: w, height: h))
            y += h + vGap
        }
        glowTop = blockTop; glowW = w + 2 * shift; glowH = totalH
    }

    // Soft felt-green glow behind the shots.
    let glowCenter = CGPoint(x: W / 2, y: top(glowTop + glowH * 0.45))
    let glowRadius = max(glowW, glowH) * 0.75
    let glow = CGGradient(colorsSpace: sRGB, colors: [feltGlow.withAlphaComponent(0.42).cgColor,
                                                      feltGlow.withAlphaComponent(0.12).cgColor,
                                                      feltGlow.withAlphaComponent(0).cgColor] as CFArray,
                          locations: [0, 0.45, 1])!
    ctx.saveGState()
    // Stretch the radial glow vertically on portrait canvases so it follows the tall shots.
    let stretch = max(1, glowH / glowW) * 0.8 + 0.2
    ctx.translateBy(x: glowCenter.x, y: glowCenter.y)
    ctx.scaleBy(x: 1, y: stretch)
    ctx.drawRadialGradient(glow, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: glowRadius / stretch * 1.1,
                           options: [])
    ctx.restoreGState()

    // Shots: shadow from a filled rounded shape first, then the image clipped to the same shape, then a hairline edge.
    for (img, r) in zip(shots, rects) {
        let radius = r.width * device.cornerFraction
        let path = CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -W * 0.012), blur: W * 0.045,
                      color: NSColor.black.withAlphaComponent(0.85).cgColor)
        ctx.addPath(path); ctx.setFillColor(NSColor.black.cgColor); ctx.fillPath()
        ctx.restoreGState()
        ctx.saveGState()
        ctx.addPath(path); ctx.clip()
        ctx.draw(img, in: r)
        ctx.restoreGState()
        ctx.saveGState()
        ctx.addPath(path); ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.14).cgColor)
        ctx.setLineWidth(max(2, W * 0.0015)); ctx.strokePath()
        ctx.restoreGState()
    }

    // Accent bar, then the headline centred in the space between the bar and the shots.
    let barW = W * 0.075, barH = max(6, H * 0.0028)
    let barTop = H * device.headlineTop
    let bar = CGRect(x: (W - barW) / 2, y: top(barTop + barH), width: barW, height: barH)
    ctx.addPath(CGPath(roundedRect: bar, cornerWidth: barH / 2, cornerHeight: barH / 2, transform: nil))
    ctx.setFillColor(accentCyan.cgColor); ctx.fillPath()

    let maxTextW = W * (1 - 2 * device.sideMargin)
    let text = headlineString(headline, size: fontSize, rtl: rtl)
    let textW = balancedWidth(text, maxWidth: maxTextW)
    let textH = layout(text, width: textW).height
    let textZoneTop = barTop + barH + H * 0.012
    // The headline sits in its own fixed band, so it lands in the same place on every frame of the set.
    let textZoneBottom = zoneTop - H * 0.012
    let textTop = textZoneTop + max(0, (textZoneBottom - textZoneTop - textH) / 2)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    text.draw(with: NSRect(x: (W - textW) / 2, y: top(textTop + textH), width: textW, height: textH),
              options: [.usesLineFragmentOrigin, .usesFontLeading])
    NSGraphicsContext.restoreGraphicsState()

    return ctx.makeImage()
}

// MARK: - Main

var written = 0
for lang in languages {
    let captions = loadCaptions(lang)
    let rtl = lang == "ar"
    let rawDir = "\(rawRoot)/\(deviceName)/\(lang)"
    let outDir = "\(outRoot)/\(deviceName)/\(lang)"
    let maxTextW = CGFloat(device.width) * (1 - 2 * device.sideMargin)

    // One headline size for the whole language: the largest that fits every caption, so the set reads as one family.
    let fontSize = frames.compactMap { captions[$0.name] }
        .map { fittingSize($0, rtl: rtl, width: maxTextW, maxSize: device.maxFontSize) }
        .min() ?? device.maxFontSize

    for frame in frames {
        guard let headline = captions[frame.name] else { print("warning: no caption \(frame.name) for \(lang); skipped"); continue }
        let paths = frame.scenes.map { "\(rawDir)/\($0).png" }
        var images = paths.compactMap(loadImage)
        guard images.count == paths.count else {
            let missing = paths.filter { !FileManager.default.fileExists(atPath: $0) }
            print("warning: \(deviceName)/\(lang)/\(frame.name) skipped, missing raw: \(missing.map { ($0 as NSString).lastPathComponent }.joined(separator: ", "))")
            continue
        }
        // Composites: table area only, so the tables are drawn large (see tableCrops). Only the iPad uses the
        // big-tile-plus-two layout.
        var featured: Int? = nil
        if let crop = tableCrops[deviceName], images.count > 1 {
            // Each scene may have its own crop (the moon's trick-shot card starts higher than the ice's).
            images = zip(frame.scenes, images).compactMap { scene, image in
                cropToTable(image, rtl: rtl, crop: frameCrops["\(deviceName)/\(scene)"] ?? crop)
            }
            if deviceName == "ipad-13" { featured = featuredScene[frame.name].flatMap { frame.scenes.firstIndex(of: $0) } }
        }
        guard let out = render(shots: images, headline: headline, fontSize: fontSize, rtl: rtl, featured: featured,
                               stacked: stackedDevices.contains(deviceName) && images.count > 1) else { fail("Could not draw \(frame.name)") }
        let path = "\(outDir)/\(frame.name).png"
        guard writePNG(out, to: path) else { fail("Could not write \(path)") }
        print(path)
        written += 1
    }
}
print("\(written) frame(s) written for \(deviceName).")
