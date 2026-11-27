// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: a tile's note is paper2, not the sliding magenta.)
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
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone, plans/25-Nov-2026-everyone-can-play-plan.md
//          Parts A5 and D3-D4: after a shot the planned and delivered figures each carry a one-word label ("Planned",
//          "Delivered"), so dim against bright is not the only difference; `spoken` makes the tile one VoiceOver
//          element reading its label, then the figure with its unit in words (StrikeSpoken); at the accessibility text
//          sizes nothing shrinks to fit: no minimum scale, no line limit, and the hinge's fixed 10-point label follows
//          the text size too.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (aiming panel redesign, plans/26-Nov-2026-aiming-panel-redesign-plan.md
//          step 3: the strike panel no longer draws tiles (its lead band and physics line are StrikeLeadBand and
//          StrikePhysicsLine, built on the instrument kit); the tile stays for NotebookNumbers. A tile given a planned
//          figure no longer stacks four lines (Planned, the figure, Delivered, the figure): it shows the delivered
//          figure with a DeltaChip under it ("+0.02 vs 2.40 planned"), the same worded chip the strike panel uses.)
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
    // 0.7.10 everyone: the tile's value as VoiceOver says it (the unit in words). Nil keeps the children combined,
    // as NotebookNumbers has always read.
    var spoken: String? = nil
    // 0.8.1: the height the strike panel gives each tile so its even rows fill the notebook's room (nil: the tile's
    // own minimum). A tall tile draws its figure a size up.
    var fillHeight: CGFloat? = nil
    @Environment(\.palette) private var palette
    @Environment(\.notebookRoomy) private var roomy
    // 0.7.10 everyone: at the accessibility sizes the text grows and wraps instead of shrinking to fit.
    @Environment(\.dynamicTypeSize) private var typeSize

    /// The smallest a line may shrink to: `normal` at the ordinary sizes, never at the accessibility sizes.
    private func shrink(_ normal: CGFloat) -> CGFloat { typeSize.isAccessibilitySize ? 1 : normal }
    /// One line at the ordinary sizes; as many as the text needs at the accessibility sizes.
    private func lines(_ normal: Int) -> Int? { typeSize.isAccessibilitySize ? nil : normal }

    var body: some View {
        VStack(spacing: 2) {
            Text(verbatim: value)
                .font(figureFont)
                .foregroundStyle(palette.accent)
                .lineLimit(lines(1))
                .minimumScaleFactor(shrink(0.6))
            label
                // On a big screen the label follows the reader's text size (it is read from further away); across the
                // folding phone's hinge the narrow tiles keep the fixed small size they were laid out for, except at
                // the accessibility sizes (0.7.10 everyone), where every label follows the reader's size.
                .font(roomy || typeSize.isAccessibilitySize ? Theme.label : .system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(lines(2))
                .minimumScaleFactor(shrink(0.85))
            if let planned {
                // Aiming panel redesign: the delivered figure above, the change and the plan in one worded chip.
                DeltaChip(text: StrikeWords.deltaChip(note ?? "", planned: planned))
            } else if let note {
                Text(verbatim: note)
                    .font(Theme.number)
                    .foregroundStyle(palette.paper2)
                    .lineLimit(lines(1))
                    .minimumScaleFactor(shrink(0.7))
            }
        }
        .frame(maxWidth: .infinity, minHeight: fillHeight ?? (large ? 64 : 52))
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
        .modifier(TileSpeech(label: label, spoken: spoken))
    }

    /// The figure's font: the notebook's headline digits, or a size up in the monospaced number design for the strike.
    private var figureFont: Font {
        if large, let fillHeight, fillHeight >= 96 { return .system(.title, design: .monospaced).weight(.semibold) }
        return large ? .system(.title3, design: .monospaced).weight(.semibold) : .headline.monospacedDigit()
    }
}

/// 0.7.10 everyone: how a tile is read. With a spoken value the tile is one element, its label then the figure with its
/// unit in words; without one its children are combined, as NotebookNumbers' tiles have always read.
private struct TileSpeech: ViewModifier {
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
