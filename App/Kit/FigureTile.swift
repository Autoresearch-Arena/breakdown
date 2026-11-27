// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part B: created.)
// PURPOSE: UI rethink package 3, "The component kit" part B (plans/26-Nov-2026-ui-rethink-plan.md, package 3;
//          plans/26-Nov-2026-design-language.md, "Figure tile" and "Sunken strip").
//          FigureTile is the kit's one figure tile: a sunken strip (panelSunken, no edge, small corners, 12 points of
//          padding) holding a label on top (caption, paper2), the figure below it (KitFigure, control size by default)
//          and an optional note under it (caption, paper2), 4 points apart. The editable variant puts the 1.5 point
//          dotted cyan underline under the figure (KitEditableMark), and nothing else: the mark is the whole signal.
//          FigureTileRow lays tiles out in a row that share one width and one height, and stacks them at the
//          accessibility text sizes so no figure has to shrink to fit.
//          VoiceOver: a tile is one element. Given a spoken value (the unit in words, from StrikeSpoken) it reads the
//          label, then that value; otherwise it reads its parts in order (label, figure, note).
//          Read by NumberTile (App/Strike/NumberTile.swift, now a thin wrapper over this, for NotebookNumbers in
//          App/NotebookInfo.swift) and by the later packages' cards (daily, how forgiving, the Lens summary).
// SRP/DRY check: Pass - folds NumberTile's drawing in here (NumberTile keeps its initialiser and draws this); checked
//          CaptionViews' private FigureTile (the Lens caption's coloured wash tile, owned by packages 6 and 9, which can
//          move onto this one), StrikePanel's lead band (built on FigureLine, package 4 moves it) and bandSurface
//          (the band's panel surface, not a sunken strip).
import SwiftUI

/// A sunken tile: label on top, a figure, an optional note under it.
struct FigureTile: View {
    /// What the figure is, a word or two ("Leaves at").
    let label: Text
    /// The figure.
    let figure: KitFigure
    /// A short note under the figure ("from a 2.40 m/s swing", "0.13 under").
    var note: Text? = nil
    /// The figure as VoiceOver says it, its unit in words; nil reads the parts as they are.
    var spoken: String? = nil
    /// The least height the tile takes (a caller filling a fixed room); nil is the tile's own height.
    var minHeight: CGFloat? = nil

    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    // Set by FigureTileRow: stretch to the row's tallest tile. Off elsewhere, so a lone tile never grows to fill a
    // container that offers it more height.
    @Environment(\.figureTileFillsRow) private var fillsRow

    /// The general form: a label and any figure.
    init(label: Text, figure: KitFigure, note: Text? = nil, spoken: String? = nil, minHeight: CGFloat? = nil) {
        self.label = label
        self.figure = figure
        self.note = note
        self.spoken = spoken
        self.minHeight = minHeight
    }

    /// A tile from NumberStyle (the preferred shape). `label` and `note` are already localised by the caller.
    init(label: String, reading: NumberStyle.Reading, note: String? = nil, size: Theme.FigureSize = .control,
         color: Color? = nil, editable: Bool = false, spoken: String? = nil, minHeight: CGFloat? = nil) {
        self.init(label: Text(verbatim: label),
                  figure: KitFigure(reading, size: size, color: color, editable: editable),
                  note: note.map { Text(verbatim: $0) }, spoken: spoken, minHeight: minHeight)
    }

    /// A tile from the aiming panel's FigureText.
    init(label: String, figure: FigureText, note: String? = nil, size: Theme.FigureSize = .control,
         color: Color? = nil, editable: Bool = false, spoken: String? = nil, minHeight: CGFloat? = nil) {
        self.init(label: Text(verbatim: label),
                  figure: KitFigure(figure, size: size, color: color, editable: editable),
                  note: note.map { Text(verbatim: $0) }, spoken: spoken, minHeight: minHeight)
    }

    /// A tile from an already-joined figure ("3.4 m/s", "12"): the notebook's shape, kept for NumberTile.
    init(label: Text, value: String, note: Text? = nil, size: Theme.FigureSize = .control, color: Color? = nil,
         editable: Bool = false, spoken: String? = nil, minHeight: CGFloat? = nil) {
        self.init(label: label, figure: KitFigure(text: value, size: size, color: color, editable: editable),
                  note: note, spoken: spoken, minHeight: minHeight)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.figureToLabel) {
            label
                .font(Theme.caption)
                .foregroundStyle(palette.paper2)
                .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)
            figure
                // Room for the editable mark under the number, so it never touches the note.
                .padding(.bottom, figure.editable ? Theme.Space.xxs : 0)
            if let note {
                note
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Space.tilePadding)
        // Fills the width (and, inside FigureTileRow, the height) it is given, so tiles in a row match.
        .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: fillsRow ? .infinity : nil, alignment: .topLeading)
        .background(palette.panelSunken, in: Theme.Corner.tileShape)
        .modifier(FigureTileSpeech(label: label, spoken: spoken))
    }
}

/// How a tile is read: with a spoken value, one element (label, then the value); otherwise its parts combined.
private struct FigureTileSpeech: ViewModifier {
    let label: Text
    let spoken: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let spoken {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .accessibilityValue(Text(verbatim: spoken))
        } else {
            content.accessibilityElement(children: .combine)
        }
    }
}

/// Tiles in a row: one width and one height each, the gap between them a spacing step. At the accessibility text sizes
/// the tiles stack instead, full width, so their figures keep their size.
struct FigureTileRow<Content: View>: View {
    var spacing: CGFloat = Theme.Space.sm
    @ViewBuilder var content: Content
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: spacing) { content }
        } else {
            // Every tile has an infinite maximum width, so the row shares its width equally; the fixed vertical size
            // makes the row as tall as its tallest tile and the others stretch to it (figureTileFillsRow gives them
            // an infinite maximum height here only).
            HStack(alignment: .top, spacing: spacing) { content }
                .environment(\.figureTileFillsRow, true)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension EnvironmentValues {
    /// True inside a FigureTileRow's row: each tile stretches to the tallest one.
    @Entry var figureTileFillsRow: Bool = false
}

#Preview("Figure tiles") {
    let palette = Palette(contrast: .standard)
    VStack(alignment: .leading, spacing: Theme.Space.md) {
        FigureTileRow {
            FigureTile(label: "Cut on the 1", reading: NumberStyle.angle(degrees: 14.5), note: "goes 1.2° left")
            FigureTile(label: "Leaves at", reading: NumberStyle.speed(metresPerSecond: 2.74),
                       note: "from a 2.40 m/s swing")
        }
        FigureTileRow {
            FigureTile(label: "Back spin", reading: NumberStyle.spin(turnsPerSecond: 8.4))
            FigureTile(label: "Right spin", reading: NumberStyle.spin(turnsPerSecond: 7.6))
        }
        FigureTileRow {
            FigureTile(label: "Tip", reading: NumberStyle.tipOffset(metres: 0.0063), note: "below", editable: true,
                       spoken: "6.3 millimetres below")
            FigureTile(label: Text(verbatim: "Ball hits"), value: "4", size: .inline)
            FigureTile(label: Text(verbatim: "Cue speed"), value: "3.4 m/s", size: .inline)
        }
    }
    .padding(Theme.Space.lg)
    .frame(width: 420)
    .background(palette.panel)
    .background(palette.ground)
}
