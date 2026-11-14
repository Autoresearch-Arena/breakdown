// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: The one place for Breakdown's look. (1) The Palette: every colour the screen draws by hand, defined once
//          with light, dark and high-contrast values and resolved from the reader's appearance and Increase Contrast
//          settings, then handed down the view tree through the environment (see PaletteProvider). (2) The font
//          choices: all of them are system text styles, so everything scales with Dynamic Type and Bold Text; there
//          are no typed-in point sizes. (3) The raw colour triples the 3D scene reads (LensLayer), kept here so the
//          screen and the scene never drift apart. Text on glass uses the system's primary and secondary styles and is
//          not part of the palette on purpose: the system already adapts those to contrast and transparency settings.
// SRP/DRY check: Pass - checked ShowpieceView, LensLayer and TableBuilder; the colour copies that lived in the view
//          (caption accents, scrub tick colours, panel colours) now read from Palette. Raw triples keep their names.
import SwiftUI

enum Theme {
    // MARK: Raw colours (red, green, blue, 0 to 1), shared with the 3D scene

    /// Amber: a ball sliding on the cloth (the lamp's colour).
    static let amberRGB: (Double, Double, Double) = (1.0, 0.62, 0.20)
    /// Cyan: a ball rolling cleanly (the Lens's colour).
    static let cyanRGB: (Double, Double, Double) = (0.30, 0.88, 1.0)
    /// Paper: main text on the dark ground.
    static let paperRGB: (Double, Double, Double) = (0.92, 0.96, 1.0)

    // MARK: Fonts (all system text styles: they scale with the reader's text size)

    /// The big title on the opening screen: New York serif.
    static var display: Font { .system(.largeTitle, design: .serif, weight: .semibold) }
    /// The tagline under the title.
    static var tagline: Font { .system(.title3, design: .serif).italic() }
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

/// One colour in its four appearances. `dark` and `light` are the normal values; the `High` variants are what the
/// reader gets when Increase Contrast is on (brighter on dark, darker on light, and a little more saturated).
private struct Tone {
    struct RGBA { let r, g, b: Double; let a: Double
        init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) { self.r = r; self.g = g; self.b = b; self.a = a }
    }
    let dark: RGBA, darkHigh: RGBA, light: RGBA, lightHigh: RGBA

    func resolve(_ scheme: ColorScheme, _ contrast: ColorSchemeContrast) -> Color {
        let v: RGBA
        switch (scheme, contrast) {
        case (.dark, .increased): v = darkHigh
        case (.dark, _): v = dark
        case (_, .increased): v = lightHigh
        default: v = light
        }
        return Color(red: v.r, green: v.g, blue: v.b).opacity(v.a)
    }
}

/// Every hand-drawn colour in the app. Read it with `@Environment(\.palette)`.
struct Palette {
    /// Tint for controls and the playhead; the Lens's rolling colour.
    let accent: Color
    /// A ball sliding on the cloth.
    let slide: Color
    /// Wordmark and title text that sits directly on the scene (not on glass).
    let paper: Color
    /// The room behind everything.
    let ground: Color
    /// The empty part of the scrub rail.
    let track: Color
    /// Caption and scrub-tick colours, one per kind of event.
    let strike: Color, impact: Color, cushion: Color, friction: Color, pocket: Color

    func color(for accent: CaptionAccent) -> Color {
        switch accent {
        case .strike: return strike
        case .impact: return impact
        case .cushion: return cushion
        case .friction: return friction
        case .pocket: return pocket
        }
    }

    init(scheme: ColorScheme, contrast: ColorSchemeContrast) {
        typealias C = Tone.RGBA
        func tone(_ d: C, _ dh: C, _ l: C, _ lh: C) -> Color { Tone(dark: d, darkHigh: dh, light: l, lightHigh: lh).resolve(scheme, contrast) }
        accent = tone(C(0.30, 0.88, 1.0), C(0.55, 0.95, 1.0), C(0.0, 0.46, 0.60), C(0.0, 0.32, 0.45))
        slide = tone(C(1.0, 0.62, 0.20), C(1.0, 0.76, 0.42), C(0.78, 0.38, 0.0), C(0.58, 0.26, 0.0))
        paper = tone(C(0.92, 0.96, 1.0), C(1, 1, 1), C(0.05, 0.07, 0.10), C(0, 0, 0))
        ground = tone(C(0.02, 0.03, 0.05), C(0, 0, 0), C(0.95, 0.96, 0.98), C(1, 1, 1))
        track = tone(C(1, 1, 1, 0.18), C(1, 1, 1, 0.38), C(0, 0, 0, 0.14), C(0, 0, 0, 0.35))
        strike = tone(C(1.0, 0.93, 0.55), C(1.0, 0.97, 0.75), C(0.62, 0.50, 0.0), C(0.45, 0.36, 0.0))
        impact = tone(C(1.0, 0.85, 0.55), C(1.0, 0.92, 0.72), C(0.70, 0.42, 0.0), C(0.50, 0.30, 0.0))
        cushion = tone(C(0.55, 0.72, 1.0), C(0.72, 0.84, 1.0), C(0.10, 0.30, 0.80), C(0.05, 0.20, 0.62))
        friction = tone(C(1.0, 0.62, 0.25), C(1.0, 0.76, 0.45), C(0.78, 0.36, 0.0), C(0.58, 0.25, 0.0))
        pocket = tone(C(1.0, 0.82, 0.25), C(1.0, 0.90, 0.50), C(0.66, 0.48, 0.0), C(0.48, 0.34, 0.0))
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette(scheme: .dark, contrast: .standard)
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

/// Resolves the palette from the current appearance and contrast setting and hands it down the environment. Apply
/// once, at the root of the window. Controls take the accent where it means something (the playhead, a switched-on
/// toggle, sliders, the main action); everything else stays neutral glass.
struct PaletteProvider: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let palette = Palette(scheme: scheme, contrast: contrast)
        content.environment(\.palette, palette)
    }
}
