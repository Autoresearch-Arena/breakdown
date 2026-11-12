// Author: Claude Sonnet 5.5 Medium
// Date: 11-November-2026
// PURPOSE: The one place for Breakdown's look: the lamp-and-ink colour set and the font choices. Fonts are Apple's
//          own (New York serif for titles and equations, the standard system font for labels, its monospaced cut for
//          live numbers) so text follows the reader's text-size setting on iPhone and Mac. The screen reads the
//          SwiftUI colours; the 3D scene reads the raw number triples so both stay in step.
// SRP/DRY check: Pass - checked ShowpieceView and TableScene, which each held their own copies of these colours; they now read from here.
import SwiftUI

enum Theme {
    // MARK: Raw colours (red, green, blue, 0 to 1), shared with the 3D scene

    /// Amber: a ball sliding on the cloth (the lamp's colour).
    static let amberRGB: (Double, Double, Double) = (1.0, 0.62, 0.20)
    /// Cyan: a ball rolling cleanly (the Lens's colour).
    static let cyanRGB: (Double, Double, Double) = (0.30, 0.88, 1.0)
    /// Paper: main text on the dark ground.
    static let paperRGB: (Double, Double, Double) = (0.92, 0.96, 1.0)

    // MARK: SwiftUI colours

    static let ink = Color(red: 0.02, green: 0.03, blue: 0.05)
    static let paper = Color(red: paperRGB.0, green: paperRGB.1, blue: paperRGB.2)
    static let cyan = Color(red: cyanRGB.0, green: cyanRGB.1, blue: cyanRGB.2)
    static let amber = Color(red: amberRGB.0, green: amberRGB.1, blue: amberRGB.2)
    /// Solid control strip: dark blue-grey with a thin cyan border, instead of frosted glass.
    static let panel = Color(red: 0.05, green: 0.08, blue: 0.11)
    static let hairline = Color(red: cyanRGB.0, green: cyanRGB.1, blue: cyanRGB.2).opacity(0.28)

    // MARK: Fonts (Apple's own, all scale with the reader's text size)

    /// Big title and the tagline: New York serif.
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .serif) }
    /// Equations: New York serif, italic so the variables read as variables.
    static var equation: Font { .system(.title3, design: .serif, weight: .medium).italic() }
    /// Titles on cards and buttons: the standard system font.
    static var heading: Font { .system(.headline, weight: .semibold) }
    /// Body copy and small labels.
    static var body: Font { .system(.subheadline) }
    static var label: Font { .system(.caption, weight: .semibold) }
    /// Live numbers: monospaced digits so they do not jitter as they change.
    static var number: Font { .system(.caption, design: .monospaced, weight: .medium).monospacedDigit() }
}
