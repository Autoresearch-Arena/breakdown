// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2, plans/26-Nov-2026-design-language.md: new
//          roles warning (fouls and misses, red-orange), paper2, paper3, panel, panelSunken and contact (strike and
//          impact merged); pocket and cushion take the language's values; the delta yellow is retired (delta is paper2);
//          a unit's size never falls under the caption size.)
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
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream figures: the caption figure styles (figure, figureUnit,
//          figureLabel, figureChip: rounded, monospaced digits, all system text styles) and Palette.color(for:) for a
//          FigureMark, so a figure's number wears the colour of the Lens mark it belongs to.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, foundation: the upright phone's blurb and control
//          fonts, all system text styles.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (aiming panel redesign, plans/26-Nov-2026-aiming-panel-redesign-plan.md
//          step 1: Palette.delta, the warm yellow used only for planned-against-delivered (raw deltaRGB / deltaHighRGB),
//          the flat surface tokens band, ledger and rule, and the panel's figure fonts leadFigure, leadUnit,
//          controlFigure, ledgerFigure and groupCaption, plus figure(size:) and unit(size:) for figures whose size the
//          layout picks (always scaled with the text by the caller's @ScaledMetric).)
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
    /// Red-orange: a foul, a miss, a loss of turn (UI rethink package 2; Palette.warning). The old delta yellow for
    /// planned against delivered is retired: the difference has no hue of its own.
    static let warningRGB: (Double, Double, Double) = (1.0, 0.416, 0.239)

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
    /// A caption figure's number on its tile (0.7.6): large, rounded, with monospaced digits so a column of numbers
    /// lines up and a number does not change width as it is read off a different moment.
    static var figure: Font { .system(.title3, design: .rounded, weight: .bold).monospacedDigit() }
    /// The unit beside a figure's number ("m/s"): smaller, on the number's baseline.
    static var figureUnit: Font { .system(.caption, design: .rounded, weight: .semibold) }
    /// The few words under a figure's number ("Launch speed").
    static var figureLabel: Font { .caption2.weight(.medium) }
    /// The lead figure in the title chip on the table: the chip's size, in the tile's rounded digits.
    static var figureChip: Font { .system(.caption, design: .rounded, weight: .bold).monospacedDigit() }

    // MARK: The aiming panel (plans/26-Nov-2026-aiming-panel-redesign-plan.md)

    /// What the ball gets: the four lead figures, large, monospaced, digits that do not jitter.
    static var leadFigure: Font { .system(.largeTitle, design: .monospaced, weight: .semibold).monospacedDigit() }
    /// The unit on a lead figure's baseline, a little over half its size.
    static var leadUnit: Font { .system(.title3, design: .monospaced, weight: .medium) }
    /// A figure carried by a control (the swing, the tip's millimetres, the cue angle, the bridge).
    static var controlFigure: Font { .system(.title, design: .monospaced, weight: .semibold).monospacedDigit() }
    /// A figure on the physics line (push, force, energy): quiet.
    static var ledgerFigure: Font { .system(.callout, design: .monospaced).monospacedDigit() }
    /// A band's caption ("WHAT THE BALL GETS"): small, bold, upper case, tracked.
    static var groupCaption: Font { .caption.weight(.bold) }
    /// The tracking a group caption is set with.
    static let groupCaptionTracking: CGFloat = 1.4

    /// A figure at a size the layout picked, in the panel's monospaced semibold. Callers pass a size from their own
    /// @ScaledMetric, so the figure still follows the reader's text size.
    static func figure(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced).monospacedDigit()
    }
    /// The unit beside a figure of `size`: about 55 percent of it, medium weight (the plan's "smaller grey unit").
    /// UI rethink package 2: never under the caption size (12 points), up from a ten-point floor.
    static func unit(size: CGFloat) -> Font {
        .system(size: max(12, size * 0.55), weight: .medium, design: .monospaced)
    }

    // MARK: The upright phone's blurbs and controls (phone UI plan, Part 3)

    /// A blurb's title ("Throw"): subheadline semibold.
    static var blurbTitle: Font { .subheadline.weight(.semibold) }
    /// The lead figure after a blurb's title ("2.1°"): bold monospaced, so it reads as a measured number.
    static var blurbFigure: Font { .system(.subheadline, design: .monospaced, weight: .bold) }
    /// A figure chip's number: caption monospaced.
    static var blurbChip: Font { .system(.caption, design: .monospaced, weight: .semibold) }
    /// The few words after a chip's number: caption 2 (11 points at the default size, the smallest text on the phone).
    static var blurbChipLabel: Font { .caption2 }
    /// The worked equation in a blurb: italic caption.
    static var blurbEquation: Font { .caption.italic() }
    /// A blurb's small glass buttons.
    static var blurbButton: Font { .subheadline.weight(.semibold) }
    /// The upright phone's worded controls (Lens, Ride, the primary action, Skip): subheadline semibold, one weight
    /// whatever their state, so joined glass never jumps.
    static var phoneControl: Font { .subheadline.weight(.semibold) }
    /// The speed capsule: monospaced, so "Auto", "1×" and "⅒×" keep the rail's width steady.
    static var phoneSpeed: Font { .system(.subheadline, design: .monospaced, weight: .semibold) }
    /// The title row's title: plain headline.
    static var phoneTitle: Font { .headline }
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
    /// Planned against delivered. UI rethink package 2: the warm yellow is retired (the design language gives the
    /// difference no hue of its own), so this is paper2 now, kept under its old name for the views that still use it.
    let delta: Color
    /// UI rethink package 2 (plans/26-Nov-2026-design-language.md, "Colour: the roles"):
    /// a foul, a miss, a loss of turn, a refused stroke or a destructive action (red-orange, #FF6A3D). The sliding
    /// magenta now means sliding and friction only.
    let warning: Color
    /// Secondary text (paper at 64 percent) and tertiary text (paper at 40 percent).
    let paper2: Color, paper3: Color
    /// Every reading surface (the same flat surface as band) and a strip set into one (the same as ledger).
    let panel: Color, panelSunken: Color
    /// A strike or a ball-on-ball hit: one warm colour (strike and impact are merged into it).
    let contact: Color
    /// The aiming panel's flat band surface (#10151D) and the darker ledger line under it (#0C1016).
    let band: Color, ledger: Color
    /// A 1-point hairline between columns and around bands (#1F2833).
    let rule: Color

    func color(for accent: CaptionAccent) -> Color {
        switch accent {
        case .strike: return strike
        case .impact: return impact
        case .cushion: return cushion
        case .friction: return friction
        case .pocket: return pocket
        }
    }

    /// A caption figure's colour (0.7.6): the Lens trail colours for sliding (magenta) and rolling (cyan), the caption
    /// colours for the event kinds, so a number on the card matches the mark it describes on the table.
    func color(for mark: FigureMark) -> Color {
        switch mark {
        case .sliding: return slide
        case .rolling: return accent
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
        // UI rethink package 2: strike and impact are one contact colour (#FFD98C), kept pale so it stays apart in
        // lightness from the deep gold of a pocket.
        contact = tone(C(1.0, 0.851, 0.549), C(1.0, 0.922, 0.722))
        strike = contact
        impact = contact
        cushion = tone(C(0.549, 0.722, 1.0), C(0.722, 0.839, 1.0))
        // Friction is what makes a ball slide and slow, so its captions wear the sliding magenta.
        friction = tone(C(1.0, 0.30, 0.70), C(1.0, 0.52, 0.82))
        pocket = tone(C(1.0, 0.761, 0.102), C(1.0, 0.851, 0.40))
        // Violet: the one hue left clear of the default cloth's green-teal sheen and every colour above.
        whatIf = tone(C(0.72, 0.48, 1.0), C(0.84, 0.70, 1.0))
        paper2 = tone(C(0.92, 0.96, 1.0, 0.64), C(1, 1, 1, 0.72))
        paper3 = tone(C(0.92, 0.96, 1.0, 0.40), C(1, 1, 1, 0.50))
        delta = paper2
        warning = tone(C(1.0, 0.416, 0.239), C(1.0, 0.58, 0.44))
        // Flat, opaque surfaces: under Increase Contrast a touch lighter so the band's edge still shows on black.
        band = tone(C(0.063, 0.082, 0.114), C(0.09, 0.11, 0.15))
        ledger = tone(C(0.047, 0.063, 0.086), C(0.07, 0.09, 0.12))
        rule = tone(C(0.122, 0.157, 0.20), C(0.30, 0.36, 0.44))
        panel = band
        panelSunken = ledger
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
        // UI rethink package 2: the window tint is the cyan, so switches, links and icons never fall back to the
        // system's blue or green.
        content.environment(\.palette, palette).tint(palette.accent)
    }
}
