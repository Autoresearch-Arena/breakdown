// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part B: created.)
// PURPOSE: UI rethink package 3, "The component kit" part B (plans/26-Nov-2026-ui-rethink-plan.md, package 3;
//          plans/26-Nov-2026-design-language.md, "The figure face" and "The editable figure mark").
//          KitFigure is the one figure text view of the kit: a measured value's number in the figure face (system
//          monospaced, semibold, tabular digits) with its unit beside it on the same baseline at 55 percent of the
//          figure's size, medium weight, paper2, never under the caption size. Three sizes (Theme.FigureSize: lead,
//          control, inline), each following the reader's text size through @ScaledMetric seeded with the size's
//          baseSize and its own text style. The number is paper by default (a result), or a meaning colour the caller
//          passes when the figure describes a mark on the cloth. A figure the player can tap to type an exact value
//          carries the editable mark: a 1.5 point dotted cyan underline under the number (KitEditableMark), the only
//          meaning of that mark.
//          It takes a figure in any of the three shapes the app already has: a NumberStyle.Reading (the preferred one,
//          the design language's one precision per unit), the aiming panel's FigureText (App/Strike/StrikeWords.swift),
//          or an already-joined string ("3.4 m/s", "14.5°"), which it splits back into number and unit (split(_:)).
//          Read by FigureTile, Chip, ProgressChip, ListRow and Scoreboard (App/Kit), and by NumberTile through
//          FigureTile. Colours from Palette (App/Theme.swift); sizes from Theme.FigureSize, Theme.unit and Theme.Size.
// SRP/DRY check: Pass - checked FigureLine and Readout (App/Strike/Instrument.swift: the aiming panel's figure, sized by
//          a caller's CGFloat, coloured by FigureRole; kept for its callers, and a later package can move them onto
//          this), DottedUnderline (Instrument.swift: 2 points in the figure's own colour; the language's mark is 1.5
//          points and always cyan, so it is drawn here once), CaptionViews' private FigureTile (the Lens caption's
//          tile, owned by packages 6 and 9) and NumberStyle (formats; this only draws). No other view draws a number
//          with a grey unit from the three figure sizes.
import SwiftUI

/// One measured figure: the number in the figure face, the unit smaller and grey on the same baseline.
struct KitFigure: View {
    /// The number, already rounded and written in the app's number locale ("2.61"). May carry a leading "≈".
    let number: String
    /// The unit as shown ("m/s", "°", "turns/s"); empty for a quantity named in words (a coefficient, a count).
    let unit: String
    /// True when the unit sits straight against the number (degrees, percent), with no gap.
    let hugs: Bool
    /// Which of the three figure sizes.
    var size: Theme.FigureSize
    /// The number's colour; nil is paper (a result). Pass a meaning colour only when the figure describes a mark of
    /// that colour on the cloth.
    var color: Color?
    /// Draws the editable mark under the number: a tap types an exact value.
    var editable: Bool

    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    // The figure's point size, scaled with the reader's text size from the size's own text style.
    @ScaledMetric private var figurePoints: CGFloat
    // The caption's point size, scaled the same way: the floor under the unit, so it never falls under the caption.
    @ScaledMetric(relativeTo: .caption) private var captionPoints: CGFloat = Theme.captionBaseSize

    /// A figure from its number and its shown unit.
    init(number: String, unit: String, size: Theme.FigureSize = .control, color: Color? = nil, editable: Bool = false) {
        self.number = number
        self.unit = unit
        self.hugs = Self.unitHugs(unit)
        self.size = size
        self.color = color
        self.editable = editable
        _figurePoints = ScaledMetric(wrappedValue: size.baseSize, relativeTo: size.textStyle)
    }

    /// A figure from NumberStyle (the preferred shape: one precision per unit, the unit in the shown language).
    init(_ reading: NumberStyle.Reading, size: Theme.FigureSize = .control, color: Color? = nil, editable: Bool = false) {
        self.init(number: reading.number, unit: reading.unit, size: size, color: color, editable: editable)
    }

    /// A figure from the aiming panel's FigureText.
    init(_ figure: FigureText, size: Theme.FigureSize = .control, color: Color? = nil, editable: Bool = false) {
        self.init(number: figure.number, unit: figure.unit, size: size, color: color, editable: editable)
    }

    /// A figure from an already-joined string ("3.4 m/s", "14.5°", "12"), split back into number and unit.
    init(text: String, size: Theme.FigureSize = .control, color: Color? = nil, editable: Bool = false) {
        let parts = Self.split(text)
        self.init(number: parts.number, unit: parts.unit, size: size, color: color, editable: editable)
    }

    var body: some View {
        let numberColor = color ?? palette.paper
        HStack(alignment: .firstTextBaseline, spacing: hugs ? 0 : max(2, figurePoints * 0.14)) {
            Text(verbatim: number)
                .font(Theme.figure(size: figurePoints))
                .foregroundStyle(numberColor)
                .overlay(alignment: .bottom) {
                    if editable {
                        KitEditableMark()
                            .offset(y: max(3, figurePoints * 0.14))
                    }
                }
            if !unit.isEmpty {
                Text(verbatim: unit)
                    .font(Theme.unit(size: figurePoints, captionSize: captionPoints))
                    .foregroundStyle(palette.paper2)
            }
        }
        // One line at the ordinary sizes (a narrow column shrinks it a little); at the accessibility sizes nothing
        // shrinks, it wraps.
        .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
        .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.75)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: hugs || unit.isEmpty ? number + unit : number + " " + unit))
    }

    // MARK: Pure helpers (nonisolated so the tests can call them)

    /// Degrees and percent sit straight against their number; every other unit after a gap.
    nonisolated static func unitHugs(_ unit: String) -> Bool {
        unit == "°" || unit == "%"
    }

    /// Splits an already-joined figure into its number and unit. A trailing degree or percent sign is the unit; else the
    /// last space (ordinary or no-break) divides them when what follows it holds no digit ("3.4 m/s" -> "3.4", "m/s";
    /// "12" -> "12", ""; "1 of 3" stays whole, its tail is a digit).
    nonisolated static func split(_ text: String) -> (number: String, unit: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if let last = trimmed.last, last == "°" || last == "%" {
            return (String(trimmed.dropLast()), String(last))
        }
        guard let gap = trimmed.lastIndex(where: { $0 == " " || $0 == "\u{00A0}" || $0 == "\u{202F}" }) else {
            return (trimmed, "")
        }
        let head = String(trimmed[..<gap]).trimmingCharacters(in: .whitespaces)
        let tail = String(trimmed[trimmed.index(after: gap)...])
        if head.isEmpty || tail.isEmpty || tail.contains(where: \.isNumber) { return (trimmed, "") }
        return (head, tail)
    }
}

/// The editable figure mark: a 1.5 point dotted cyan underline, drawn under a figure the player can tap to type an
/// exact value. No read-only figure carries it; it has no other meaning.
struct KitEditableMark: View {
    @Environment(\.palette) private var palette

    var body: some View {
        Canvas { ctx, size in
            var line = Path()
            let y = size.height / 2
            line.move(to: CGPoint(x: 1, y: y))
            line.addLine(to: CGPoint(x: max(1, size.width - 1), y: y))
            // Round caps on near-zero dashes draw round dots one line-width wide, 4 points apart.
            ctx.stroke(line, with: .color(palette.accent),
                       style: StrokeStyle(lineWidth: Theme.Size.editableUnderline, lineCap: .round, dash: [0.1, 4]))
        }
        .frame(height: Theme.Size.editableUnderline * 2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview("Figure sizes and marks") {
    VStack(alignment: .leading, spacing: Theme.Space.md) {
        KitFigure(NumberStyle.speed(metresPerSecond: 2.74), size: .lead)
        KitFigure(NumberStyle.angle(degrees: 14.5), size: .lead)
        KitFigure(NumberStyle.spin(turnsPerSecond: 8.4), size: .control)
        KitFigure(NumberStyle.tipOffset(metres: 0.0063), size: .control, editable: true)
        KitFigure(text: "0.47 N·s", size: .inline)
        KitFigure(text: "12", size: .inline)
        KitFigure(NumberStyle.speed(metresPerSecond: 1.2), size: .inline, color: Palette(contrast: .standard).accent)
    }
    .padding(Theme.Space.lg)
    .background(Palette(contrast: .standard).ground)
}
