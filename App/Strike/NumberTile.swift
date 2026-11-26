// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: One number tile: a figure in the monospaced number font, in the accent colour, with a short label under it,
//          on a small glass rectangle. Lifted out of NotebookNumbers (App/NotebookInfo.swift) so the shot's figures
//          after it is played (NotebookNumbers) and the strike's figures before and after it (StrikePanel) are drawn by
//          the same tile, not two (plans/25-Nov-2026-strike-panel-and-controls-plan.md, stage 2 item 1).
//          The strike panel's extras, all off by default so NotebookNumbers draws exactly what it drew before:
//            - large: the figure a size up (the strike panel is read while aiming, at arm's length);
//            - planned: the planned figure, dimmed above the delivered one, when the stroke changed it;
//            - note: the error in plain units under the label ("0.4° left", "2 mm left");
//            - editable: a small pencil mark in the corner, saying a tap types an exact value.
//          On a big screen (notebookRoomy) the label follows the reader's text size; across the folding phone's hinge
//          the narrow tiles keep the fixed small size they were laid out for (unchanged from NotebookNumbers).
// SRP/DRY check: Pass - the one tile drawing in the app; NotebookNumbers and StrikePanel both use it. Formatting of the
//          figures stays with their callers (NotebookNumbers' speedText, StrikeWords).
import SwiftUI

struct NumberTile: View {
    /// The figure, already formatted ("3.4 m/s").
    let value: String
    /// What the figure is, a word or two.
    let label: Text
    /// The planned figure when the delivered one differs (strike panel only): drawn dimmed above the value.
    var planned: String? = nil
    /// The difference in plain units, under the label (strike panel only).
    var note: String? = nil
    /// A size up for the strike panel.
    var large = false
    /// Marks the tile as one a tap opens for typing an exact value.
    var editable = false
    @Environment(\.palette) private var palette
    @Environment(\.notebookRoomy) private var roomy

    var body: some View {
        VStack(spacing: 2) {
            if let planned {
                Text(verbatim: planned)
                    .font(figureFont.weight(.regular))
                    .foregroundStyle(.secondary)
                    .opacity(0.7)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Text(verbatim: value)
                .font(figureFont)
                .foregroundStyle(palette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            label
                // On a big screen the label follows the reader's text size (it is read from further away); across the
                // folding phone's hinge the narrow tiles keep the fixed small size they were laid out for.
                .font(roomy ? Theme.label : .system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            if let note {
                Text(verbatim: note)
                    .font(Theme.number)
                    .foregroundStyle(palette.slide)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, minHeight: large ? 64 : 52)
        .padding(.vertical, 6)
        .padding(.horizontal, large ? 4 : 1)
        .glassEffect(.regular, in: .rect(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if editable {
                Image(systemName: "pencil")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// The figure's font: the notebook's headline digits, or a size up in the monospaced number design for the strike.
    private var figureFont: Font {
        large ? .system(.title3, design: .monospaced).weight(.semibold) : .headline.monospacedDigit()
    }
}
