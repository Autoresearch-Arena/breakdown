// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 3, the closing sweep: the old font aliases
//          (tagline, sectionTitle, copy, number, figure, figureUnit, figureLabel, figureChip, ledgerFigure,
//          groupCaption and its tracking, the blurb and phone fonts) are deleted; every caller now names the role it
//          aliased.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2, the rest of the design tokens: one text
//          scale by role (display, title, heading, body and bodyCompact, label, section, caption, the equation style),
//          the figure family (FigureSize lead, control, inline with their unit fonts, 55 percent, medium, never under
//          the caption size, and size-taking helpers), the spacing steps and per-device margins, paddings and gaps
//          (Space), the three corners (Corner), button and bar heights (Size) and the motion timings (Motion). The old
//          font names stay as aliases pointing at the roles until package 3 moves their callers; rounded design and
//          italics are retired except in the equation style. label and body now mean their roles, so they grow.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2, plans/26-Nov-2026-design-language.md: new
//          roles warning (fouls and misses, red-orange), paper2, paper3, panel, panelSunken and contact (strike and
//          impact merged); pocket and cushion take the language's values; the delta yellow is retired (delta is paper, the worded difference paper2);
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
//          Palette). (2) The type: the text scale by role and the figure family, all system text styles (or sizes
//          the caller scales with @ScaledMetric), so everything follows Dynamic Type and Bold Text. (3) The layout
//          tokens: spacing steps, page margins, card padding and gaps, corner radii, button and bar heights, motion.
//          Every value comes from plans/26-Nov-2026-design-language.md; when the two disagree, that page wins.
//          (4) The raw colour triples the 3D scene reads (LensLayer), kept here so the screen and the scene never
//          drift apart. Text on glass uses the system's primary and secondary styles and is
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

    // MARK: The text scale by role (design language, "Type": the text scale)
    //
    // Every role is a system text style, so it follows the reader's text size and Bold Text. No rounded design anywhere
    // and no italics except the equation style. Colour is not part of a font: titles, body and figures are paper,
    // section labels and captions paper2 (Palette), set by the view or the kit.

    /// display: the game's name and sheet titles on big screens. Large Title, serif (New York), semibold. The wordmark
    /// alone is set with `displayTracking`.
    static var display: Font { .system(.largeTitle, design: .serif, weight: .semibold) }
    /// The tracking of the wordmark (the game's name) only; other display text is untracked.
    static let displayTracking: CGFloat = 6
    /// title: page and sheet titles, the mode card's item name on big screens. Title 2, serif, semibold.
    static var title: Font { .system(.title2, design: .serif, weight: .semibold) }
    /// heading: card titles, list row titles, the phone's title row. Headline (sans, semibold).
    static var heading: Font { .headline }
    /// body: the plain sentence and paragraphs on big screens (iPad, Mac, the open folding phone's panel). Body.
    /// The upright phone uses `bodyCompact`; a single font cannot know the device, so the caller picks.
    /// (Up from Subheadline before UI rethink package 2: the old name now means the role.)
    static var body: Font { .body }
    /// body on the upright phone: Subheadline.
    static var bodyCompact: Font { .subheadline }
    /// label: control names ("Swing", "Cue angle") and button words. Subheadline, medium.
    /// (Up from caption semibold before UI rethink package 2: the old name now means the role.)
    static var label: Font { .subheadline.weight(.medium) }
    /// section: every section label everywhere ("WHAT THE BALL GETS", list headers in sheets). Caption, bold; the view
    /// upper-cases the words, sets `sectionTracking` and paints it paper2 (the kit's SectionLabel does all three).
    static var section: Font { .caption.weight(.bold) }
    /// The tracking every section label is set with.
    static let sectionTracking: CGFloat = 1.4
    /// caption: notes under figures, footers, the version line. Caption, regular, paper2.
    static var caption: Font { .caption }
    /// The equation style, the one place italics remain: worked equations only, serif italic so the variables read as
    /// variables. Big screens.
    static var equation: Font { .system(.title3, design: .serif, weight: .medium).italic() }
    /// The equation style at the upright phone's body size.
    static var equationCompact: Font { .system(.subheadline, design: .serif).italic() }

    // MARK: The figure family (design language, "The figure face")
    //
    // One face for every measured value: system monospaced, semibold, tabular digits, in three sizes. The unit sits on
    // the figure's baseline at 55 percent of the figure's size, medium weight, paper2, never under the caption size.
    // Words after a figure are the label role in paper2, not a figure font. Each size's unit font is the system text
    // style nearest 55 percent of the figure's style, floored at caption, so both still scale with the reader's text:
    // lead (Large Title) takes a Title 3 unit, control (Title) a Subheadline unit, inline (Subheadline) a Caption unit
    // (55 percent of it would fall under the caption floor).

    /// The three figure sizes, with what a layout needs to size a figure itself: the text style it scales with (for
    /// `@ScaledMetric(relativeTo:)`) and that style's size at the default text size on this platform.
    enum FigureSize: CaseIterable, Sendable {
        /// The four "what the ball gets" figures, the result figure on a result card. Built from Large Title.
        case lead
        /// A figure carried by a control (swing, tip, cue angle, bridge), scoreboard numbers, tile figures (daily,
        /// how forgiving, Lens summary). Built from Title.
        case control
        /// Figures inside a sentence, chips, the physics line, menu progress chips, the speed pill. Built from
        /// Subheadline.
        case inline

        /// The text style the figure is built from.
        var textStyle: Font.TextStyle {
            switch self {
            case .lead: return .largeTitle
            case .control: return .title
            case .inline: return .subheadline
            }
        }

        /// The text style its unit is built from (the nearest style to 55 percent, floored at caption).
        var unitTextStyle: Font.TextStyle {
            switch self {
            case .lead: return .title3
            case .control: return .subheadline
            case .inline: return .caption
            }
        }

        /// The figure's point size at the default text size, the seed for a caller's
        /// `@ScaledMetric(relativeTo: size.textStyle) var s = size.baseSize`. These are the system's own sizes for the
        /// styles above (they differ between the phone and tablet and the Mac), so a scaled figure matches the
        /// text-style one at every text size.
        var baseSize: CGFloat {
            #if os(macOS)
            switch self {
            case .lead: return 26
            case .control: return 22
            case .inline: return 11
            }
            #else
            switch self {
            case .lead: return 34
            case .control: return 28
            case .inline: return 15
            }
            #endif
        }

        /// The figure's font.
        var font: Font {
            .system(textStyle, design: .monospaced, weight: .semibold).monospacedDigit()
        }

        /// Its unit's font.
        var unitFont: Font {
            .system(unitTextStyle, design: .monospaced, weight: .medium)
        }
    }

    /// The caption style's size at the default text size on this platform: the floor under every unit. Seed a caller's
    /// `@ScaledMetric(relativeTo: .caption)` with it and pass the result to `unit(size:captionSize:)`.
    static var captionBaseSize: CGFloat {
        #if os(macOS)
        return 10
        #else
        return 12
        #endif
    }

    /// The share of a figure's size its unit takes.
    static let unitScale: CGFloat = 0.55

    /// lead figure: Large Title, monospaced semibold, tabular digits.
    static var leadFigure: Font { FigureSize.lead.font }
    /// The unit beside a lead figure (Title 3, monospaced medium).
    static var leadUnit: Font { FigureSize.lead.unitFont }
    /// control figure: Title, monospaced semibold, tabular digits.
    static var controlFigure: Font { FigureSize.control.font }
    /// The unit beside a control figure (Subheadline, monospaced medium).
    static var controlUnit: Font { FigureSize.control.unitFont }
    /// inline figure: Subheadline, monospaced semibold, tabular digits.
    static var inlineFigure: Font { FigureSize.inline.font }
    /// The unit beside an inline figure (Caption, monospaced medium: the floor).
    static var inlineUnit: Font { FigureSize.inline.unitFont }

    /// A figure at a size the layout picked, in the figure face. Callers pass a size from their own @ScaledMetric
    /// (seeded with `FigureSize.baseSize`), so the figure still follows the reader's text size.
    static func figure(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced).monospacedDigit()
    }
    /// The unit beside a figure of `size`: 55 percent of it, medium weight, never under 12 points (the caption size at
    /// the default text size). Returns a plain Font so callers can still change its weight.
    static func unit(size: CGFloat) -> Font {
        unit(size: size, captionSize: 12)
    }
    /// The unit beside a figure of `size`, floored at `captionSize`: pass the caller's own scaled caption size so the
    /// floor grows with the reader's text as the caption does (a fixed floor would let the unit fall under the caption
    /// at large text sizes).
    static func unit(size: CGFloat, captionSize: CGFloat) -> Font {
        .system(size: max(captionSize, size * unitScale), weight: .medium, design: .monospaced)
    }

    // MARK: Devices (which margins, paddings and heights apply)

    /// The three layouts the design language sizes for. The caller decides which one it is in (ScreenLayout and the
    /// fold reading in Surfaces.swift know the window); these tokens only say what each one gets.
    enum Device: CaseIterable, Sendable {
        /// The upright iPhone (and any phone layout without a side column).
        case phone
        /// The open folding phone's words panel.
        case foldPanel
        /// iPad, either way up, and the Mac.
        case big
    }

    // MARK: Spacing (design language, "Spacing and grid")

    /// The spacing steps. Base unit 4 points; no other gap in a view. Each name is a step, not a meaning, so the kit
    /// picks the step and the meanings below say which step a common gap takes.
    enum Space {
        /// 4: between a figure and its label below.
        static let xxs: CGFloat = 4
        /// 8: between a section label and its content.
        static let xs: CGFloat = 8
        /// 12: between cards on the phone; a figure tile's padding.
        static let sm: CGFloat = 12
        /// 16: the phone's page margin and card padding; between cards on big screens.
        static let md: CGFloat = 16
        /// 24: the big-screen page margin.
        static let lg: CGFloat = 24
        /// 32.
        static let xl: CGFloat = 32
        /// 48.
        static let xxl: CGFloat = 48
        /// Every step, smallest first (for the drift lint and tests).
        static let steps: [CGFloat] = [xxs, xs, sm, md, lg, xl, xxl]

        /// Between a section label and its content.
        static let sectionToContent: CGFloat = xs
        /// Between a figure and its label below.
        static let figureToLabel: CGFloat = xxs

        /// The page's side margin: 16 on the upright phone, 20 on the open folding phone's panel, 24 on iPad and Mac.
        /// (20 is the one value off the steps; the design language sets it for the fold's narrower half.)
        static func pageMargin(_ device: Device) -> CGFloat {
            switch device {
            case .phone: return md
            case .foldPanel: return 20
            case .big: return lg
            }
        }
        /// The padding inside a card: 16 on the phone, 20 on big screens (and the fold's panel, which uses the
        /// big-screen column).
        static func cardPadding(_ device: Device) -> CGFloat {
            device == .phone ? md : 20
        }
        /// The gap between cards: 12 on the phone, 16 on big screens.
        static func cardGap(_ device: Device) -> CGFloat {
            device == .phone ? sm : md
        }

        /// A figure tile's padding.
        static let tilePadding: CGFloat = sm
        /// A chip's padding: 6 top and bottom, 10 either side.
        static let chipVertical: CGFloat = 6
        static let chipHorizontal: CGFloat = 10
        /// The size of the meaning-colour dot leading an event chip.
        static let chipDot: CGFloat = 3

        /// Big-screen panels lay out on a 12 column grid with 16 point gutters inside the panel's own width.
        static let gridColumns = 12
        static let gridGutter: CGFloat = md
    }

    // MARK: Corners (design language, "Corners")

    /// The three corner radii. No bare corner number in a view.
    enum Corner {
        /// 8: chips, figure tiles, list thumbnails, the tip picture's frame.
        static let small: CGFloat = 8
        /// 16: cards, panels, sheets' groups, the playback bar.
        static let medium: CGFloat = 16
        /// The capsule's radius for a shape of `height`: half of it. Every button, pill and progress chip; prefer
        /// SwiftUI's Capsule() shape, this is for drawing code that needs the number.
        static func capsule(height: CGFloat) -> CGFloat { height / 2 }
        /// The radius of something nested inside a container of `outer` radius and `padding`: concentric (the outer
        /// radius minus the padding), never under `small`.
        static func nested(in outer: CGFloat, padding: CGFloat) -> CGFloat { max(small, outer - padding) }

        /// The card and panel shape (medium, continuous corners).
        static var cardShape: RoundedRectangle { RoundedRectangle(cornerRadius: medium, style: .continuous) }
        /// The chip and tile shape (small, continuous corners).
        static var tileShape: RoundedRectangle { RoundedRectangle(cornerRadius: small, style: .continuous) }
    }

    // MARK: Sizes (design language, "Components" and "Layout per device")

    enum Size {
        /// A primary or secondary button's height: 50 on the phone, 56 on big screens.
        static func button(_ device: Device) -> CGFloat { device == .phone ? buttonPhone : buttonBig }
        static let buttonPhone: CGFloat = 50
        static let buttonBig: CGFloat = 56
        /// Shoot and Break on big screens: the primary at the full action column's height, at least this tall.
        static let actionColumnMin: CGFloat = 112
        /// The smallest hit area of anything tappable, quiet buttons included.
        static let minHit: CGFloat = 44
        /// The upright phone's title row.
        static let titleRow: CGFloat = 44
        /// The playback bar ("shot reel"): 52 on big screens, 44 on the phone.
        static func playbackBar(_ device: Device) -> CGFloat { device == .phone ? 44 : 52 }
        /// The big-screen side column: 400 on iPad; on the Mac it follows the window between 380 and 440.
        static let sideColumn: CGFloat = 400
        static let sideColumnMacMin: CGFloat = 380
        static let sideColumnMacMax: CGFloat = 440
        /// The upright iPad gives the table this share of the height.
        static let uprightTableShare: CGFloat = 0.58
        /// Hairline dividers and panel edges.
        static let hairline: CGFloat = 1
        /// The dotted cyan underline of a figure the player can tap to type (its only meaning).
        static let editableUnderline: CGFloat = 1.5
        /// Two neighbouring scale labels are thinned when they sit closer than their own width plus this.
        static let tickLabelGap: CGFloat = 8
    }

    // MARK: Motion (design language, "Motion")

    enum Motion {
        /// The standard ease: 0.25 s, ease out (cards appearing, chips changing, a sheet's content).
        static var standard: Animation { .easeOut(duration: 0.25) }
        /// Only for something the finger drags.
        static var drag: Animation { .spring(response: 0.35, dampingFraction: 0.85) }
        /// One camera move per beat on the table: 0.6 to 0.9 s, ease in and out.
        static let cameraMin: Double = 0.6
        static let cameraMax: Double = 0.9
        static func camera(duration: Double) -> Animation {
            .easeInOut(duration: min(cameraMax, max(cameraMin, duration)))
        }
    }
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
    /// difference no hue of its own), so this is paper now (the delivered figure and its marks), kept under its old
    /// name for the views that still use it; the worded difference is paper2.
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
        // The delivered figure and its marks (the dot on the tip picture, the swing tick) read in paper, so they still
        // stand out from the paper2 text around them; the worded difference itself is paper2 (DeltaChip).
        delta = paper
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
