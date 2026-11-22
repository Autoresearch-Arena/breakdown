// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 model-flow, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          stream model-flow items 6 and 12: the ticked row is the table actually on screen (model.tableOnScreen), so
//          none is ticked while a trick shot, lesson, situation, the stroke drill or a match is up; the Mac minimum
//          size applies only in a sheet, not as a page of the notebook.)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens) - bumper pool, five-pin and bar billiards are games
//          now: each entry also names its game and opens that game's page (TableGamePage: a match for two, bar
//          billiards alone, practice on the table, and How to play). The pool table still plays at once, as before.
// PURPOSE: The list of tables, opened from the main menu ("Tables"): the pool table, bumper pool, five-pin billiards
//          and bar billiards, each with its plain one-line description. Choosing one plays it as the game
//          (ShowpieceModel.playTable): any trick shot or Behind the 8-Ball situation ends, the table changes and its
//          start layout is on screen, ready to shoot. A table is a different game, not a different felt, so it lives
//          here, away from the Surface button (which now only picks what the bed is made of). On the folding phone's open
//          screen this is a page of the side panel, not a sheet over the table.
// SRP/DRY check: Pass - display and one model call. Titles, summaries and symbols come from TableKind.
import BreakdownRules
import SwiftUI

struct TableList: View {
    let model: ShowpieceModel
    /// Called after a table is chosen (the menu opens the aiming controls, as Free play does).
    let onChosen: () -> Void
    let onClose: () -> Void
    @Environment(\.palette) private var palette
    /// True when shown as a page of the notebook rather than a sheet (NotebookPanel sets it).
    @Environment(\.inlinePages) private var inlinePages

    /// The table on the screen right now, or nil while a trick shot, lesson, situation, the stroke drill or a match is
    /// up (the model's one answer, which the Mac's Game > Tables reads too).
    private var current: TableKind? { model.tableOnScreen }

    var body: some View {
        NavigationStack {
            List {
                ForEach(TableKind.allCases) { kind in
                    if let game = kind.matchKind {
                        // A table with a game of its own: its page offers the match, practice and the rules.
                        NavigationLink {
                            TableGamePage(model: model, table: kind, game: game) {
                                onChosen()
                                onClose()
                            }
                        } label: { row(kind) }
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(kind == current ? .isSelected : [])
                    } else {
                        Button {
                            model.playTable(kind)
                            onChosen()
                            onClose()
                        } label: { row(kind) }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(kind == current ? .isSelected : [])
                    }
                }
            }
            .navigationTitle("Tables")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { onClose() } }
            }
        }
        .tint(palette.accent)
        #if os(macOS)
        // A sheet's minimum size only: as a notebook page a fixed minimum pushed the list past the panel (0.7.5).
        .frame(minWidth: inlinePages ? nil : 420, minHeight: inlinePages ? nil : 420)
        #endif
    }

    private func row(_ kind: TableKind) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Image(systemName: kind == current ? "checkmark.circle.fill" : kind.symbol)
                .font(.title3)
                .foregroundStyle(palette.accent)
                .frame(minWidth: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: kind.title).font(Theme.heading)
                Text(verbatim: kind.summary)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                // The game this table plays, for the tables that have one.
                if let game = kind.matchKind {
                    Text(TableGameWords.gameLine(game))
                        .font(Theme.body)
                        .foregroundStyle(palette.accent)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
