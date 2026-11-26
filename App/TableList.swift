// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 front door, plans/25-Nov-2026-front-door-and-table-view-plan.md
//          Stage 1 step 4: tables are shown, not listed. The page is four pictures of the tables side by side (two by
//          two on a phone), each the real table drawn by the table builder (TablePortraits), with its name under it and
//          a tick on the one on screen. The one-line description and the game's line are each picture's VoiceOver hint.
//          What a tap does is unchanged: the pool table plays at once, the others open their game's page.)
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

    /// Two pictures across an upright phone, all four side by side wherever there is room.
    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(TableKind.allCases) { kind in
                        if let game = kind.matchKind {
                            // A table with a game of its own: its page offers the match, practice and the rules.
                            NavigationLink {
                                TableGamePage(model: model, table: kind, game: game) {
                                    onChosen()
                                    onClose()
                                }
                            } label: { tile(kind) }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(kind == current ? .isSelected : [])
                        } else {
                            Button {
                                model.playTable(kind)
                                onChosen()
                                onClose()
                            } label: { tile(kind) }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(kind == current ? .isSelected : [])
                        }
                    }
                }
                .padding(16)
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

    /// 0.7.10 frontdoor: one table as a picture with its name under it; a tick marks the table on screen. VoiceOver
    /// hears the name, then the description and the game as the hint.
    private func tile(_ kind: TableKind) -> some View {
        VStack(spacing: 8) {
            TablePortrait(kind: kind)
                .overlay(alignment: .topTrailing) {
                    if kind == current {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(palette.accent)
                            .padding(6)
                            .accessibilityHidden(true)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(kind == current ? palette.accent : palette.track, lineWidth: kind == current ? 2 : 1)
                }
            Text(verbatim: kind.title)
                .font(Theme.heading)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: kind.title))
        .accessibilityHint(Text(verbatim: hint(kind)))
    }

    /// The table's one-line description, then the game it plays, for VoiceOver (what the old list showed under each name).
    private func hint(_ kind: TableKind) -> String {
        guard let game = kind.matchKind else { return kind.summary }
        return [kind.summary, TableGameWords.gameLine(game)].joined(separator: " ")
    }
}
