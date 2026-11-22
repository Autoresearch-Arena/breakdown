// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Haiku 5.5 Medium, 18-November-2026 (added the section-title and running-text styles for the title screen).
// Edited: Claude Opus 5.5 High, 21-November-2026 (look plan package 5, a decision: the game is always dark. The room
//          is a dim pool hall with one lamp over the table, the 3D scene is lit for that, and BreakdownApp forces the
//          dark appearance on the whole window, so the light values the palette carried were never shown. They are
//          removed rather than kept half-supported: each colour now has its normal and Increase Contrast values only,
//          and the palette is resolved from the contrast setting alone.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: the sliding colour is magenta, no longer amber or orange.
//          amberRGB is renamed slideRGB and joined by slideHighRGB for Increase Contrast; Palette.slide and
//          Palette.friction take the same two magentas, so every sliding line, label, ring and gauge in the interface
//          and the Lens agrees. The room's own warm light, wood, balls and cloth are not interface and are unchanged.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 foundation: Palette.whatIf, the violet of the other future in
//          a what-if replay; frozen after the foundation commit.)
// PURPOSE: The one place for Breakdown's look. (1) The Palette: every colour the screen draws by hand, defined once
//          with a normal and a high-contrast value and resolved from the reader's Increase Contrast setting, then
//          handed down the view tree through the environment (see PaletteProvider). Always dark (see the note on
//          Palette). (2) The font
//          choices: all of them are system text styles, so everything scales with Dynamic Type and Bold Text; there
//          are no typed-in point sizes. (3) The raw colour triples the 3D scene reads (LensLayer), kept here so the
//          screen and the scene never drift apart. Text on glass uses the system's primary and secondary styles and is
//          not part of the palette on purpose: the system already adapts those to contrast and transparency settings.
// SRP/DRY check: Pass - checked ShowpieceView, LensLayer and TableBuilder; the colour copies that lived in the view
//          (caption accents, scrub tick colours, panel colours) now read from Palette. Raw triples keep their names.
import SwiftUI

enum Theme {
    // MARK: Raw colours (red, green, blue, 0 to 1), shared with the 3D scene

    /// Magenta: a ball sliding on the cloth. Chosen to sit far from the cyan of rolling and from every warm colour in
    /// the room (lamp, wood, balls), so a sliding line never reads as part of the table itself.
    static let slideRGB: (Double, Double, Double) = (1.0, 0.30, 0.70)
    /// The same magenta under Increase Contrast: lighter, so it stands further off the dark ground (Palette.slide's
    /// high tone). For the 3D parts that follow the contrast setting (BridgeRing).
    static let slideHighRGB: (Double, Double, Double) = (1.0, 0.52, 0.82)
    /// Cyan: a ball rolling cleanly (the Lens's colour).
    static let cyanRGB: (Double, Double, Double) = (0.30, 0.88, 1.0)
    /// Paper: main text on the dark ground.
    static let paperRGB: (Double, Double, Double) = (0.92, 0.96, 1.0)

    // MARK: Fonts (all system text styles: they scale with the reader's text size)

    /// The big title on the opening screen: New York serif.
    static var display: Font { .system(.largeTitle, design: .serif, weight: .semibold) }
    /// The tagline under the title.
    static var tagline: Font { .system(.title3, design: .serif).italic() }
    /// Section titles on the opening screen ("How it works"): New York serif, semibold.
    static var sectionTitle: Font { .system(.title2, design: .serif, weight: .semibold) }
    /// Running text on the opening screen: the standard body style, so it scales with the reader's text size.
    static var copy: Font { .body }
    /// Equations: New York serif, italic so the variables read as variables.
    static var equation: Font { .system(.title3, design: .serif, weight: .medium).italic() }
    /// Titles on cards.
    static var heading: Font { .headline }
    /// Body copy.
    static var body: Font { .subheadline }
    /// Small labels such as the status line and row names.
    static var label: Font { .caption.weight(.semibold) }
    /// Live numbers: monospaced digits so they do not jitter as they change.
    static var number: Font { .caption.monospaced().monospacedDigit() }
}

// MARK: - Palette

/// One colour on the dark ground: its normal value and what the reader gets when Increase Contrast is on (brighter,
/// and a little more saturated).
private struct Tone {
    struct RGBA { let r, g, b: Double; let a: Double
        init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) { self.r = r; self.g = g; self.b = b; self.a = a }
    }
    let normal: RGBA, high: RGBA

    func resolve(_ contrast: ColorSchemeContrast) -> Color {
        let v = contrast == .increased ? high : normal
        return Color(red: v.r, green: v.g, blue: v.b).opacity(v.a)
    }
}

/// Every hand-drawn colour in the app. Read it with `@Environment(\.palette)`.
/// The game is always dark, on purpose: it is played in a dim room under one lamp, the 3D table and the Lens are lit and
/// coloured for a dark surround, and BreakdownApp sets the dark appearance on the window whatever the system uses. So
/// there are no light-appearance colours here; a light appearance would need the scene relit as well, not just these.
struct Palette {
    /// Tint for controls and the playhead; the Lens's rolling colour.
    let accent: Color
    /// A ball sliding on the cloth (magenta, Theme.slideRGB).
    let slide: Color
    /// Wordmark and title text that sits directly on the scene (not on glass).
    let paper: Color
    /// The room behind everything.
    let ground: Color
    /// The empty part of the scrub rail.
    let track: Color
    /// Caption and scrub-tick colours, one per kind of event.
    let strike: Color, impact: Color, cushion: Color, friction: Color, pocket: Color
    /// The other future in a what-if: violet, clear of the cloth's green, the rolling cyan, the sliding magenta, the
    /// warm event colours and the cushion blue (never orange).
    let whatIf: Color

    func color(for accent: CaptionAccent) -> Color {
        switch accent {
        case .strike: return strike
        case .impact: return impact
        case .cushion: return cushion
        case .friction: return friction
        case .pocket: return pocket
        }
    }

    init(contrast: ColorSchemeContrast) {
        typealias C = Tone.RGBA
        func tone(_ n: C, _ h: C) -> Color { Tone(normal: n, high: h).resolve(contrast) }
        accent = tone(C(0.30, 0.88, 1.0), C(0.55, 0.95, 1.0))
        slide = tone(C(1.0, 0.30, 0.70), C(1.0, 0.52, 0.82))
        paper = tone(C(0.92, 0.96, 1.0), C(1, 1, 1))
        ground = tone(C(0.02, 0.03, 0.05), C(0, 0, 0))
        track = tone(C(1, 1, 1, 0.18), C(1, 1, 1, 0.38))
        strike = tone(C(1.0, 0.93, 0.55), C(1.0, 0.97, 0.75))
        impact = tone(C(1.0, 0.85, 0.55), C(1.0, 0.92, 0.72))
        cushion = tone(C(0.55, 0.72, 1.0), C(0.72, 0.84, 1.0))
        // Friction is what makes a ball slide and slow, so its captions wear the sliding magenta.
        friction = tone(C(1.0, 0.30, 0.70), C(1.0, 0.52, 0.82))
        pocket = tone(C(1.0, 0.82, 0.25), C(1.0, 0.90, 0.50))
        // Violet: the one hue left clear of the default cloth's green-teal sheen and every colour above.
        whatIf = tone(C(0.72, 0.48, 1.0), C(0.84, 0.70, 1.0))
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette(contrast: .standard)
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

/// Resolves the palette from the contrast setting and hands it down the environment. Apply once, at the root of the
/// window (always dark, see Palette). Controls take the accent where it means something (the playhead, a switched-on
/// toggle, sliders, the main action); everything else stays neutral glass.
struct PaletteProvider: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let palette = Palette(contrast: contrast)
        content.environment(\.palette, palette)
    }
}
