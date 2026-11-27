// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: a tile's note is paper2, not the sliding magenta.)
// PURPOSE: The notebook's number tile (NotebookNumbers in App/NotebookInfo.swift): one shot figure with its label, an
//          optional note and the editable mark. Since UI rethink package 3 it draws the kit's FigureTile
//          (App/Kit/FigureTile.swift): a sunken strip with small corners, the label on top in caption paper2, the figure
//          in paper with its unit smaller and grey, the note in caption under it, and the dotted cyan underline when a tap
//          types an exact value. This file keeps the tile's old stored properties and initialiser so its callers compile
//          unchanged, and only maps them onto FigureTile:
//            - large: the control figure even across the folding phone's hinge;
//            - planned: the note names the plan ("+0.02 vs 2.40 planned");
//            - note: the difference in plain units under the figure ("0.4° left", "2 mm left");
//            - editable: the dotted cyan underline;
//            - spoken: VoiceOver reads the label, then the figure with its unit in words (StrikeSpoken);
//            - fillHeight: the least height, so the notebook's even rows fill their room.
//          History of the earlier glass tile follows in the Edited lines.
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
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit: NumberTile is folded into
//          the kit's FigureTile (App/Kit/FigureTile.swift) and is now a thin wrapper over it, so its callers
//          (NotebookNumbers) keep compiling unchanged. What that changes on screen, per the design language: a sunken
//          strip with small corners instead of glass; the label on top in caption paper2, the figure under it in paper
//          (a result, not the cyan accent) with its unit smaller and grey; the planned-against-delivered difference is
//          a worded caption note ("+0.02 vs 2.40 planned") instead of a chip; the editable pencil becomes the dotted cyan
//          underline. The figure is the control size on a big screen or a large tile, the inline size across the
//          folding phone's hinge, where the notebook's tiles are narrow.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3 review: the PURPOSE now describes the tile
//          as it is drawn today, a wrapper over the kit's FigureTile; no behaviour change.)
// SRP/DRY check: Pass - the drawing lives once, in FigureTile; this file only maps the old parameters onto it.
//          Formatting of the figures stays with their callers (NotebookNumbers' speedText, StrikeWords).
import SwiftUI

struct NumberTile: View {
    /// The figure, already formatted ("3.4 m/s").
    let value: String
    /// What the figure is, a word or two.
    let label: Text
    /// The planned figure when the delivered one differs: the note then names the plan ("+0.02 vs 2.40 planned").
    var planned: String? = nil
    /// The difference in plain units, under the figure.
    var note: String? = nil
    /// A size up (the control figure even across the hinge).
    var large = false
    /// Marks the tile as one a tap opens for typing an exact value (the dotted cyan underline).
    var editable = false
    // 0.7.10 everyone: the tile's value as VoiceOver says it (the unit in words). Nil keeps the children combined,
    // as NotebookNumbers has always read.
    var spoken: String? = nil
    // 0.8.1: the height the caller gives the tile so its even rows fill the room (nil: the tile's own height).
    var fillHeight: CGFloat? = nil
    @Environment(\.notebookRoomy) private var roomy

    var body: some View {
        FigureTile(label: label,
                   value: value,
                   note: noteText,
                   // UI rethink package 3: tile figures are the control size; across the folding phone's hinge the
                   // notebook's four narrow tiles keep the inline size so their figures are not squeezed.
                   size: roomy || large ? .control : .inline,
                   editable: editable,
                   spoken: spoken,
                   minHeight: fillHeight)
    }

    /// The note under the figure: with a plan, the difference worded against it; else the plain difference.
    private var noteText: Text? {
        if let planned { return Text(verbatim: StrikeWords.deltaChip(note ?? "", planned: planned)) }
        return note.map { Text(verbatim: $0) }
    }
}
