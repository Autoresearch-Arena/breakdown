// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// PURPOSE: The list of tables, opened from the main menu ("Tables"): the pool table, bumper pool, five-pin billiards
//          and bar billiards, each with its plain one-line description. Choosing one plays it as the game
//          (ShowpieceModel.playTable): any trick shot or Behind the 8-Ball situation ends, the table changes and its
//          start layout is on screen, ready to shoot. A table is a different game, not a different felt, so it lives
//          here, away from the Surface button (which now only picks what the bed is made of). On the folding phone's open
//          screen this is a page of the side panel, not a sheet over the table.
// SRP/DRY check: Pass - display and one model call. Titles, summaries and symbols come from TableKind.
import SwiftUI

struct TableList: View {
    let model: ShowpieceModel
    /// Called after a table is chosen (the menu opens the aiming controls, as Free play does).
    let onChosen: () -> Void
    let onClose: () -> Void
    @Environment(\.palette) private var palette

    /// The table on the screen right now, or nil while a mode that is always on the pool table is up.
    private var current: TableKind? {
        model.trickMode.isActive || model.eightBallMode.isActive ? nil : model.tableKind
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(TableKind.allCases) { kind in
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
        .frame(minWidth: 420, minHeight: 420)
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
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
